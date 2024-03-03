/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file    stm32f4xx_it.c
  * @brief   Interrupt Service Routines.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2023 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "stm32f4xx_it.h"
/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "raster.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN TD */

/* USER CODE END TD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
 #define __STATIC_FORCEINLINE                   __attribute__((always_inline)) static inline
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/* USER CODE BEGIN PV */
static const GPIO_TypeDef *LEDS_PORT[] = {
    LED1_GPIO_Port, LED2_GPIO_Port, LED3_GPIO_Port, LED4_GPIO_Port,
    LED5_GPIO_Port, LED6_GPIO_Port, LED7_GPIO_Port, };
static const uint16_t LEDS_PIN[] = {
    LED1_Pin, LED2_Pin, LED3_Pin, LED4_Pin, LED5_Pin, LED6_Pin, LED7_Pin, };
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
/* USER CODE BEGIN PFP */
__STATIC_FORCEINLINE uint32_t __get_LR(void);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/* External variables --------------------------------------------------------*/
extern DMA_HandleTypeDef hdma_memtomem_dma2_stream0;
extern DMA_HandleTypeDef hdma_sdio_rx;
extern DMA_HandleTypeDef hdma_sdio_tx;
extern SD_HandleTypeDef hsd;
/* USER CODE BEGIN EV */
extern MSKBData mskbBlock;
/* USER CODE END EV */

/******************************************************************************/
/*           Cortex-M4 Processor Interruption and Exception Handlers          */
/******************************************************************************/
/**
  * @brief This function handles Non maskable interrupt.
  */
void NMI_Handler(void)
{
  /* USER CODE BEGIN NonMaskableInt_IRQn 0 */

  /* USER CODE END NonMaskableInt_IRQn 0 */
  /* USER CODE BEGIN NonMaskableInt_IRQn 1 */
  while (1)
  {
  }
  /* USER CODE END NonMaskableInt_IRQn 1 */
}

/**
  * @brief This function handles Hard fault interrupt.
  */
void HardFault_Handler(void)
{
  /* USER CODE BEGIN HardFault_IRQn 0 */

  /* USER CODE END HardFault_IRQn 0 */
  while (1)
  {
    /* USER CODE BEGIN W1_HardFault_IRQn 0 */
    /* USER CODE END W1_HardFault_IRQn 0 */
  }
}

/**
  * @brief This function handles Memory management fault.
  */
void MemManage_Handler(void)
{
  /* USER CODE BEGIN MemoryManagement_IRQn 0 */

  /* USER CODE END MemoryManagement_IRQn 0 */
  while (1)
  {
    /* USER CODE BEGIN W1_MemoryManagement_IRQn 0 */
    /* USER CODE END W1_MemoryManagement_IRQn 0 */
  }
}

/**
  * @brief This function handles Pre-fetch fault, memory access fault.
  */
void BusFault_Handler(void)
{
  /* USER CODE BEGIN BusFault_IRQn 0 */

  if (SCB->CFSR & SCB_CFSR_STKERR_Msk) {
    /* Stack overflow */
    SCB->CFSR |= SCB_CFSR_STKERR_Msk;

    /* Trigger pendSV interrupt for abort processing */
    SCB->ICSR |= SCB_ICSR_PENDSVSET_Msk;
    __ISB();
    return;
  }

  /* USER CODE END BusFault_IRQn 0 */
  while (1)
  {
    /* USER CODE BEGIN W1_BusFault_IRQn 0 */
    /* USER CODE END W1_BusFault_IRQn 0 */
  }
}

/**
  * @brief This function handles Debug monitor.
  */
void DebugMon_Handler(void)
{
  /* USER CODE BEGIN DebugMonitor_IRQn 0 */

  /* USER CODE END DebugMonitor_IRQn 0 */
  /* USER CODE BEGIN DebugMonitor_IRQn 1 */

  /* USER CODE END DebugMonitor_IRQn 1 */
}

/**
  * @brief This function handles Pendable request for system service.
  */
void PendSV_Handler(void)
{
  /* USER CODE BEGIN PendSV_IRQn 0 */
    /* Abort current command by resetting stack
       and reentering the main loop */
    sContextStateFrame *f;
    uint32_t *abortAdr = (uint32_t *) 0xD0201000;
    uint32_t lr = __get_LR();
    size_t sz = (lr & 0x10)?0x20:0x68;

    /* Do nothing if the exception will not return to
       thread mode with process stack */
    if ((lr & 0xF) != 0xD) {
        return;
    }

    /* Build exception frame */
    f = (void *) 0x10010000 - sz;
    f->r0 = 0;
    f->r1 = 0;
    f->r2 = 0;
    f->r3 = 0;
    f->r12 = 0;
    f->lr = 0xFFFFFFFF;
    /* mettre ici l'adresse de la procédure ABORT qui est disponible à l'adress 0xD0201000 */
    f->return_address = *abortAdr;
    f->xpsr = 0x01000000; /* Bit 24 as 1 to indicate thumb mode */

    /* Reinit process stack pointer */
    __set_PSP((uint32_t) f);
  __ISB();
  /* USER CODE END PendSV_IRQn 0 */
  /* USER CODE BEGIN PendSV_IRQn 1 */

  /* USER CODE END PendSV_IRQn 1 */
}

/**
  * @brief This function handles System tick timer.
  */
void SysTick_Handler(void)
{
  /* USER CODE BEGIN SysTick_IRQn 0 */

  /* USER CODE END SysTick_IRQn 0 */
  HAL_IncTick();
  /* USER CODE BEGIN SysTick_IRQn 1 */

  /* USER CODE END SysTick_IRQn 1 */
}

/******************************************************************************/
/* STM32F4xx Peripheral Interrupt Handlers                                    */
/* Add here the Interrupt Handlers for the used peripherals.                  */
/* For the available peripheral interrupt handler names,                      */
/* please refer to the startup file (startup_stm32f4xx.s).                    */
/******************************************************************************/

/**
  * @brief This function handles EXTI line2 interrupt.
  */
void EXTI2_IRQHandler(void)
{
  /* USER CODE BEGIN EXTI2_IRQn 0 */

  /* USER CODE END EXTI2_IRQn 0 */
  HAL_GPIO_EXTI_IRQHandler(PS2_CLOCK_1_Pin);
  /* USER CODE BEGIN EXTI2_IRQn 1 */

  /* USER CODE END EXTI2_IRQn 1 */
}

/**
  * @brief This function handles EXTI line4 interrupt.
  */
void EXTI4_IRQHandler(void)
{
  /* USER CODE BEGIN EXTI4_IRQn 0 */

  /* USER CODE END EXTI4_IRQn 0 */
  HAL_GPIO_EXTI_IRQHandler(PS2_CLOCK_2_Pin);
  /* USER CODE BEGIN EXTI4_IRQn 1 */

  /* USER CODE END EXTI4_IRQn 1 */
}

/**
  * @brief This function handles EXTI line[9:5] interrupts.
  */
void EXTI9_5_IRQHandler(void)
{
  /* USER CODE BEGIN EXTI9_5_IRQn 0 */

  /* USER CODE END EXTI9_5_IRQn 0 */
  HAL_GPIO_EXTI_IRQHandler(NRF24L01P_IRQ_Pin);
  /* USER CODE BEGIN EXTI9_5_IRQn 1 */

  /* USER CODE END EXTI9_5_IRQn 1 */
}

/**
  * @brief This function handles EXTI line[15:10] interrupts.
  */
void EXTI15_10_IRQHandler(void)
{
  /* USER CODE BEGIN EXTI15_10_IRQn 0 */

  /* USER CODE END EXTI15_10_IRQn 0 */
  HAL_GPIO_EXTI_IRQHandler(PB1_Pin);
  /* USER CODE BEGIN EXTI15_10_IRQn 1 */

  /* USER CODE END EXTI15_10_IRQn 1 */
}

/**
  * @brief This function handles SDIO global interrupt.
  */
void SDIO_IRQHandler(void)
{
  /* USER CODE BEGIN SDIO_IRQn 0 */

  /* USER CODE END SDIO_IRQn 0 */
  HAL_SD_IRQHandler(&hsd);
  /* USER CODE BEGIN SDIO_IRQn 1 */

  /* USER CODE END SDIO_IRQn 1 */
}

/**
  * @brief This function handles DMA2 stream0 global interrupt.
  */
void DMA2_Stream0_IRQHandler(void)
{
  /* USER CODE BEGIN DMA2_Stream0_IRQn 0 */

  /* USER CODE END DMA2_Stream0_IRQn 0 */
  HAL_DMA_IRQHandler(&hdma_memtomem_dma2_stream0);
  /* USER CODE BEGIN DMA2_Stream0_IRQn 1 */

  /* USER CODE END DMA2_Stream0_IRQn 1 */
}

/**
  * @brief This function handles DMA2 stream3 global interrupt.
  */
void DMA2_Stream3_IRQHandler(void)
{
  /* USER CODE BEGIN DMA2_Stream3_IRQn 0 */

  /* USER CODE END DMA2_Stream3_IRQn 0 */
  HAL_DMA_IRQHandler(&hdma_sdio_rx);
  /* USER CODE BEGIN DMA2_Stream3_IRQn 1 */

  /* USER CODE END DMA2_Stream3_IRQn 1 */
}

/**
  * @brief This function handles DMA2 stream6 global interrupt.
  */
void DMA2_Stream6_IRQHandler(void)
{
  /* USER CODE BEGIN DMA2_Stream6_IRQn 0 */

  /* USER CODE END DMA2_Stream6_IRQn 0 */
  HAL_DMA_IRQHandler(&hdma_sdio_tx);
  /* USER CODE BEGIN DMA2_Stream6_IRQn 1 */
  /* USER CODE END DMA2_Stream6_IRQn 1 */
}

/* USER CODE BEGIN 1 */
/**
\brief Get Link Register
\details Returns the current value of the Link Register (LR).
\return LR Register value
*/
__STATIC_FORCEINLINE uint32_t __get_LR(void)
{
  uint32_t result;

  __ASM volatile ("MOV %0, LR\n" : "=r" (result) );
  return(result);
}

/**
  * @brief This function handles SVC calls.
  */
void Oberon_SVC_Handler(sContextStateFrame *frame)
{
    uint8_t param = *((uint8_t *)(frame->return_address)-2);
    int32_t x, y, w, h, dx, dy;
    uint8_t buf[16*512], *pbuf;
    uint32_t *wsrc, *wdst;
    int i;

    switch (param) {
    case 1:
        /* Process LED update */
        x = frame->r0;
        for (i=0; i<7; i++) {
            if (x & 1) {
                HAL_GPIO_WritePin((GPIO_TypeDef *) LEDS_PORT[i], LEDS_PIN[i], GPIO_PIN_SET);
            } else {
                HAL_GPIO_WritePin((GPIO_TypeDef *) LEDS_PORT[i], LEDS_PIN[i], GPIO_PIN_RESET);
            }
            x >>= 1;
        }
        break;
    case 2:
        /* Process SD card multi blocks read */
    	HAL_GPIO_WritePin((GPIO_TypeDef *) LED1_GPIO_Port, LED1_Pin, GPIO_PIN_SET);
    	if (frame->r1 >= 0x20000000) { /*Memory region accessible to DMA*/
    		pbuf =  (uint8_t *)frame->r1;
    	} else {
    		if (frame->r2 > 16) {
    	    	HAL_GPIO_WritePin((GPIO_TypeDef *) LED2_GPIO_Port, LED2_Pin, GPIO_PIN_SET);
    	    	HAL_GPIO_WritePin((GPIO_TypeDef *) LED1_GPIO_Port, LED1_Pin, GPIO_PIN_RESET);
    			frame->r0 = HAL_ERROR;
    			return ;
    		}
    		pbuf = buf;
    	}

    	SD_ErrorOcurred = false;
		frame->r0 = HAL_SD_ReadBlocks_DMA(&hsd, pbuf, frame->r0, frame->r2);
		if (frame->r0 == HAL_OK) {
			frame->r0 = 300;
			while (frame->r0-- && HAL_SD_GetCardState(&hsd) != HAL_SD_CARD_TRANSFER) {
				HAL_Delay(1);
			}
			frame->r0 = (frame->r0 != 0 && !SD_ErrorOcurred)?HAL_OK:HAL_ERROR;
		}

		if (frame->r0 == HAL_OK) {
	    	if (frame->r1 < 0x20000000) {
	    		wsrc = (uint32_t *) buf; wdst = (uint32_t *) frame->r1;
	    		for (i = 0; i < frame->r2*512/4; i++) {
	    			*wdst++ = *wsrc++;
	    		}
	    	}
		} else {
	    	HAL_GPIO_WritePin((GPIO_TypeDef *) LED2_GPIO_Port, LED2_Pin, GPIO_PIN_SET);
		}
    	HAL_GPIO_WritePin((GPIO_TypeDef *) LED1_GPIO_Port, LED1_Pin, GPIO_PIN_RESET);
        break;
    case 3:
        /* Process SD card multi blocks write */
        HAL_GPIO_WritePin((GPIO_TypeDef *) LED1_GPIO_Port, LED1_Pin, GPIO_PIN_SET);

    	if (frame->r1 >= 0x20000000) { /*Memory region accessible to DMA*/
    		pbuf =  (uint8_t *)frame->r1;
    	} else {
    		if (frame->r2 > 16) {
    	    	HAL_GPIO_WritePin((GPIO_TypeDef *) LED2_GPIO_Port, LED2_Pin, GPIO_PIN_SET);
    	    	HAL_GPIO_WritePin((GPIO_TypeDef *) LED1_GPIO_Port, LED1_Pin, GPIO_PIN_RESET);
    			frame->r0 = HAL_ERROR;
    			return ;
    		}
    		wdst = (uint32_t *) buf; wsrc = (uint32_t *) frame->r1;
    		for (i = 0; i < frame->r2*512/4; i++) {
    			*wdst++ = *wsrc++;
    		}

    		pbuf = buf;
    	}

    	SD_ErrorOcurred = false;
		frame->r0 = HAL_SD_WriteBlocks_DMA(&hsd, pbuf, frame->r0, frame->r2);
		if (frame->r0 == HAL_OK) {
			frame->r0 = 300;
			while (frame->r0-- && HAL_SD_GetCardState(&hsd) != HAL_SD_CARD_TRANSFER) {
				HAL_Delay(1);
			}
			frame->r0 = (frame->r0 != 0 && !SD_ErrorOcurred)?HAL_OK:HAL_ERROR;
		}
		if (frame->r0 != HAL_OK) {
			HAL_GPIO_WritePin((GPIO_TypeDef *) LED2_GPIO_Port, LED2_Pin, GPIO_PIN_SET);
		}
    	HAL_GPIO_WritePin((GPIO_TypeDef *) LED1_GPIO_Port, LED1_Pin, GPIO_PIN_RESET);
        break;
    case 4:
        /* Return millisecond counter */
        frame->r0 = HAL_GetTick();
        break;
    case 5:
        /* Return mouse and keyboard data block address */
        frame->r0 = (uint32_t) &mskbBlock;
        break;
    case 6:
        /* Draw pattern on screen */
        x = frame->r2 >> 16;
        y = frame->r2 & 0xFFFF;
        CopyPattern(frame->r0, (uint32_t *) frame->r1, x, y, frame->r3);
        break;
    case 7:
        /* Copy block on screen */
        x = frame->r0 >> 16;
        y = frame->r0 & 0xFFFF;
        w = frame->r1 >> 16;
        h = frame->r1 & 0xFFFF;
        dx = frame->r2 >> 16;
        dy = frame->r2 & 0xFFFF;
        CopyBlock(x, y, w, h, dx, dy, frame->r3);
        break;
    }
}
/* USER CODE END 1 */
