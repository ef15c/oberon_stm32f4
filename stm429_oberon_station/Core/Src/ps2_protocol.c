/**
  Copyrignt 2021 Christian Schoffit

  This file is part of ps2_to usb.

    ps2_to usb is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ps2_to usb is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with ps2_to usb.  If not, see <https://www.gnu.org/licenses/>.
*/

#include "stm32_usec.h"
#include "ps2_protocol.h"

static void PS2_ProbeDevice(PS2_HandleTypeDef *dev);

/**
  * @brief Tell the PS/2 device to stop sending data and prepare to receive a
           command from host

  * @param  dev PS2 handle.
  * @retval None
  */

static void request_to_send(PS2_HandleTypeDef *dev)
{
    if (dev->ActivityLedPort) {
        /* Turn activity LED on */
        HAL_GPIO_WritePin(dev->ActivityLedPort, dev->ActivityLedPin, GPIO_PIN_SET);
    }
    HAL_GPIO_WritePin(dev->clockPort, dev->clockPin, GPIO_PIN_RESET);
    DWT_Delay_us(150); /* Should wait for at least 100 microseconds */
    HAL_GPIO_WritePin(dev->dataPort, dev->dataPin, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(dev->clockPort, dev->clockPin, GPIO_PIN_SET);
}

void PS2_SendByteAsync(PS2_HandleTypeDef *dev, uint8_t byte)
{
    int i, parity = 1;
//    uint32_t currentTick = HAL_GetTick();
//
//    while (dev->direction != PS2_DEVICE_TO_HOST) {
//        /* Wait until the PS/2 device is ready for the command */
//        if ((HAL_GetTick()-currentTick)>1) {
//            return;
//        }
//    }

    dev->direction = PS2_HOST_TO_DEVICE;

    dev->dataOut = (byte | 0x200) << 1;

    /* Parity computation */
    for (i=0; i<8; i++) {
        if (byte & 1) {
            parity++;
        }
        byte >>= 1;
    }

    dev->dataOut |= (parity & 1) << 9;

    dev->statusOut = PS2_IN_PROGRESS;
    request_to_send(dev);
}


PS2_ResultCodeTypedef PS2_SendByte(PS2_HandleTypeDef *dev, uint8_t byte)
{
    PS2_SendByteAsync(dev, byte);
    while (dev->statusIn == PS2_IN_PROGRESS) {
    /* Wait answer */
    }

    return dev->statusIn;
}

void PS2_initHandle(PS2_HandleTypeDef *dev)
{
    dev->connectedDevice = PS2_NO_DEVICE;
    dev->direction = PS2_NONE;
    dev->answerBlock->head = 0;
    dev->answerBlock->tail = 0;

    dev->ActivityLedPort = 0;
    /* Synchronize clock */
    HAL_GPIO_WritePin(dev->clockPort, dev->clockPin, GPIO_PIN_RESET);
    HAL_Delay(1); /* Should wait for 100 microseconds, so 1 ms is OK */
    HAL_GPIO_WritePin(dev->clockPort, dev->clockPin, GPIO_PIN_SET);

    dev->numberOfBitsRemainingToBeRead = 11;
    dev->statusIn = PS2_NO_ANSWER;
    dev->statusOut = PS2_NO_ANSWER;
    dev->parityEnabled = 1;

    PS2_ProbeDevice(dev);
}


/**
  * @brief  Process a data bit from/to a PS/2 port.
  * @param  dev: the PS/2 port handle
  * @retval None
  */
void PS2_ProcessData(PS2_HandleTypeDef *dev)
{ /* Warning : this function is call via a GPIO interrupt : keep it as fast as possible */
    GPIO_PinState dataBit;

    switch (dev->direction) {
    case PS2_NONE:
        if (HAL_GPIO_ReadPin(dev->clockPort, dev->clockPin) == GPIO_PIN_SET) {
            dev->direction = PS2_DEVICE_TO_HOST;
            if (dev->ActivityLedPort) {
                /* Turn activity LED off */
                HAL_GPIO_WritePin(dev->ActivityLedPort, dev->ActivityLedPin, GPIO_PIN_RESET);
            }
        }
        break;
    case PS2_DEVICE_TO_HOST:
        if (HAL_GPIO_ReadPin(dev->clockPort, dev->clockPin) == GPIO_PIN_RESET) {
            /* Rising edge of clock */
            dataBit = HAL_GPIO_ReadPin(dev->dataPort, dev->dataPin);
            if (dev->numberOfBitsRemainingToBeRead == 11) {
                if (dev->ActivityLedPort) {
                    /* Turn activity LED on */
                    HAL_GPIO_WritePin(dev->ActivityLedPort, dev->ActivityLedPin, GPIO_PIN_SET);
                }
                dev->statusIn = (dataBit == GPIO_PIN_RESET)?PS2_IN_PROGRESS:PS2_FRAME_ERROR;
                dev->dataIn = 0;
                dev->parity = 1;
            } else if (dev->statusIn == PS2_IN_PROGRESS) {
                if (dev->numberOfBitsRemainingToBeRead>2) {
                    dev->dataIn >>= 1;
                    dev->dataIn |= ((dataBit ==  GPIO_PIN_RESET)?0:1) << 7;
                    if (dataBit == GPIO_PIN_SET) {
                        dev->parity++;
                    }
                } else if (dev->numberOfBitsRemainingToBeRead == 2 && dev->parityEnabled) {
                    if (dataBit == GPIO_PIN_RESET) {
                        dev->statusIn = (dev->parity & 1)?PS2_PARITY_ERROR:PS2_IN_PROGRESS;
                    } else {
                        dev->statusIn = (dev->parity & 1)?PS2_IN_PROGRESS:PS2_PARITY_ERROR;
                    }
                    if (dev->statusIn == PS2_PARITY_ERROR) {
                        /* In case of error, ask device to resend information */
                        PS2_SendByteAsync(dev, 0xFE);
                    }
                } else {
                    dev->statusIn = (dataBit == GPIO_PIN_SET)?PS2_SUCCESS:PS2_FRAME_ERROR;
                }
            }

            dev->numberOfBitsRemainingToBeRead--;
            if (dev->numberOfBitsRemainingToBeRead == 0) {
                dev->numberOfBitsRemainingToBeRead = 11;
                if (dev->statusIn == PS2_SUCCESS || !dev->parityEnabled) {
                    PS2_PutByteInFIFOBuffer(dev, dev->dataIn);
                } else { /* In case of error, ask device to resend information */
                    PS2_SendByteAsync(dev, 0xFE);
                }
                if (dev->ActivityLedPort) {
                    /* Turn activity LED off */
                    HAL_GPIO_WritePin(dev->ActivityLedPort, dev->ActivityLedPin, GPIO_PIN_RESET);
                }
            }
        }

        break;
    case PS2_HOST_TO_DEVICE:
            if (HAL_GPIO_ReadPin(dev->clockPort, dev->clockPin) == GPIO_PIN_RESET) {
                if (dev->dataOut) {
                    /* Send data to device */
                        HAL_GPIO_WritePin(dev->dataPort, dev->dataPin, (dev->dataOut & 1)?GPIO_PIN_SET:GPIO_PIN_RESET);
                        dev->dataOut >>= 1;
                } else {
                    /* Check ACK from device */
                        dev->statusOut = (HAL_GPIO_ReadPin(dev->dataPort, dev->dataPin) == GPIO_PIN_RESET)?PS2_SUCCESS:PS2_NAK;
                        dev->direction = PS2_NONE;
                        dev->numberOfBitsRemainingToBeRead = 11;
                }
            }
        break;
    }
}


void PS2_PutByteInFIFOBuffer(PS2_HandleTypeDef *dev, uint8_t byte)
{
    MSKBData *bk = dev->answerBlock;

    if (dev->connectedDevice == PS2_MOUSE) {
        /* Mouse */
        uint32_t curTick = HAL_GetTick();
        int32_t x, y, dx, dy;

        if ((curTick-dev->tickLastReport) > 5) {
            /* The mouse didn't send report for a while. Start to begin of frame */
            dev->mouseIndex = 0;
            dev->tickLastReport = curTick;
        }
        dev->mouseBuffer[dev->mouseIndex++] = byte;
        if (dev->mouseIndex >= dev->mouseReportSize) {
            dev->mouseIndex = 0;
            /* Process Report */
            if (!(dev->mouseBuffer[0] & 0xC0)) { /* No overflow*/
                x = bk->mouseData & 0xFFF; y = (bk->mouseData >> 12) & 0xFFF;
                dx = dev->mouseBuffer[1];
                if (dev->mouseBuffer[0] & 0x10) {
                    /* dx is negative*/
                    dx -= 0x100;
                }
                x += dx; if (x < 0)  x = 0; else if (x >= bk->maxX) x = bk->maxX-1;

                dy = dev->mouseBuffer[2];
                if (dev->mouseBuffer[0] & 0x20) {
                    /* dy is negative*/
                    dy -= 0x100;
                }
                y += dy; if (y < 0)  y = 0; else if (y >= bk->maxY) y = bk->maxY-1;

                bk->mouseData = ((dev->mouseBuffer[0] & 6) << 23) + ((dev->mouseBuffer[0] & 1) << 26)
                	+ (x & 0xFFF) + ((y & 0xFFF) << 12);
            }
        }
    } else {
        uint32_t next = (bk->head+1) & PS2_BUFFER_SIZE_BIT_MASK;
        if (next != bk->tail) {
            /* The buffer is not full */
            bk->keyboardBuffer[bk->head] = byte;
            bk->head = next;
        }
    }
}


int16_t PS2_DrawByteFormFIFOBuffer(PS2_HandleTypeDef *dev)
{
    if (dev->answerBlock->tail != dev->answerBlock->head) {
        /* The buffer is not empty */
        int16_t res = dev->answerBlock->keyboardBuffer[dev->answerBlock->tail];
        dev->answerBlock->tail = (dev->answerBlock->tail+1) & PS2_BUFFER_SIZE_BIT_MASK;
        return res;
    } else {
        return -1;
    }
}


uint8_t PS2_FIFOBuffer_IsEmpty(PS2_HandleTypeDef *dev)
{
    return dev->answerBlock->tail != dev->answerBlock->head;
}


void PS2_FIFOBuffer_Flush(PS2_HandleTypeDef *dev)
{
    dev->answerBlock->tail = dev->answerBlock->head;
}


int16_t PS2_WaitForAnswer(PS2_HandleTypeDef *dev, uint16_t timemout)
{
    int16_t answer;

    answer = PS2_DrawByteFormFIFOBuffer(dev);
    while (answer == -1 && timemout--) { /* Wait until buffer is not empty */
        HAL_Delay(1);
        answer = PS2_DrawByteFormFIFOBuffer(dev);
    }

    return answer;
}

static void PS2_ParseReadIdAnswer(PS2_HandleTypeDef *dev)
{
    uint8_t id1 = PS2_WaitForAnswer(dev, 20);

    if (id1 == 0xab &&
        PS2_WaitForAnswer(dev, 20) == 0x83) {
        /* Map the activity LED for a keyboard device */
        dev->ActivityLedPort = dev->KBLedPort;
        dev->ActivityLedPin = dev->KBLedPin;
        dev->connectedDevice = PS2_KEYBOARD;
    } else if (id1 == 0x00 || id1 == 0x03) {
        /* Disable parity in case of Aten KVM switch */
        dev->parityEnabled = 0;

        /* Map the device type and activity LED for a keyboard device */
        dev->ActivityLedPort = dev->MouseLedPort;
        dev->ActivityLedPin = dev->MouseLedPin;

        /* Initialize mouse state */
        dev->haveWheel = 0;
        dev->mouseReportSize = 3;

#ifdef WANT_WHEEL
        if (id1 == 0x03) {
            /* This is a wheel mouse */
            dev->haveWheel = 1;
            dev->mouseReportSize = 4;
        } else {
            /* Try to activate wheel mode */
            PS2_SendByteAsync(dev, 0xF3);
            if (PS2_WaitForAnswer(dev, 20) != 0xfa) {
                return;
            }
            PS2_SendByteAsync(dev, 200);
            if (PS2_WaitForAnswer(dev, 20) != 0xfa) {
                return;
            }

            PS2_SendByteAsync(dev, 0xF3);
            if (PS2_WaitForAnswer(dev, 20) != 0xfa) {
                return;
            }
            PS2_SendByteAsync(dev, 100);
            if (PS2_WaitForAnswer(dev, 20) != 0xfa) {
                return;
            }

            PS2_SendByteAsync(dev, 0xF3);
            if (PS2_WaitForAnswer(dev, 20) != 0xfa) {
                return;
            }
            PS2_SendByteAsync(dev, 80);
            if (PS2_WaitForAnswer(dev, 20) != 0xfa) {
                return;
            }

            /* Reread device type */
            PS2_SendByteAsync(dev, 0xF2);
            if (PS2_WaitForAnswer(dev, 20) != 0xfa) {
                return;
            }
            id1 = PS2_WaitForAnswer(dev, 20);
            if (id1 == 0x03) {
                dev->haveWheel = 1;
                dev->mouseReportSize = 4;
            }
        }
#endif
        /* Enable data reporting */
        dev->tickLastReport = HAL_GetTick();
        dev->mouseIndex = 0;
        dev->answerBlock->maxX = 1366;
        dev->answerBlock->maxY = 768;
        PS2_SendByteAsync(dev, 0xF4);
        id1 = PS2_WaitForAnswer(dev, 20);
        dev->connectedDevice = PS2_MOUSE;
    } else {
        /* No known device connected */
        dev->connectedDevice = PS2_NO_DEVICE;
    }
}


static void PS2_ReadId(PS2_HandleTypeDef *dev) {
    int nbTries = 3;
    /* Send read ID command */
    do {
        HAL_Delay(10);
        PS2_SendByteAsync(dev, 0xF2);
        HAL_Delay(1);
    } while (--nbTries && PS2_WaitForAnswer(dev, 20) != 0xfa);
}


#if 0
static void PS2_Reset(PS2_HandleTypeDef *dev) {
    /* Send reset command */
    int nbTries = 3;
    /* Send read ID command */
    do {
        PS2_SendByteAsync(dev, 0xFF);
        HAL_Delay(500); /*Wait for BAT to be completed*/
    } while (--nbTries && PS2_WaitForAnswer(dev, 20) != 0xfa);
}
#endif

/**
  * @brief  Check if a device is connected on a PS/2 port.
  *         If true, try to determine its type: keyboard or mouse
  * @param  dev: the PS/2 port handle
  * @retval none
  */
static void PS2_ProbeDevice(PS2_HandleTypeDef *dev) {
    /* Send read id command */
    PS2_ReadId(dev);
    PS2_ParseReadIdAnswer(dev);
}

