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
extern LTDC_HandleTypeDef hltdc;
extern DMA_HandleTypeDef hdma_sdio_rx;
extern DMA_HandleTypeDef hdma_sdio_tx;
extern TIM_HandleTypeDef htim6;

/* USER CODE BEGIN EV */
extern SD_HandleTypeDef hsd;

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
    f->return_address = (uint32_t) mainLoop;
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
  * @brief This function handles TIM6 global interrupt, DAC1 and DAC2 underrun error interrupts.
  */
void TIM6_DAC_IRQHandler(void)
{
  /* USER CODE BEGIN TIM6_DAC_IRQn 0 */

  /* USER CODE END TIM6_DAC_IRQn 0 */
  HAL_TIM_IRQHandler(&htim6);
  /* USER CODE BEGIN TIM6_DAC_IRQn 1 */

  /* USER CODE END TIM6_DAC_IRQn 1 */
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

/**
  * @brief This function handles LTDC global interrupt.
  */
void LTDC_IRQHandler(void)
{
  /* USER CODE BEGIN LTDC_IRQn 0 */

  /* USER CODE END LTDC_IRQn 0 */
  HAL_LTDC_IRQHandler(&hltdc);
  /* USER CODE BEGIN LTDC_IRQn 1 */

  /* USER CODE END LTDC_IRQn 1 */
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
  * @brief This function handles Undefined instruction or illegal state.
  */
void Oberon_UsageFault_Handler(sContextStateFrame *frame)
{
  uint32_t *instr;

  UNUSED(instr);
  if (SCB->CFSR & ~SCB_CFSR_NOCP_Msk) {
    while (1)
    {
    }
  }
  instr = (uint32_t *) frame->return_address;
  frame->return_address += 4;
  __ISB();
}


/**
  * @brief This function handles SVC calls.
  */
void Oberon_SVC_Handler(sContextStateFrame *frame)
{
    uint8_t param = *((uint8_t *)(frame->return_address)-2);
    uint32_t x;
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
        /* Process SD card block read */
        frame->r0 = HAL_SD_ReadBlocks_DMA(&hsd, (uint8_t *)frame->r1, frame->r0, frame->r2);
        if (frame->r0 == HAL_OK) {
            frame->r0 = 300;
            while (frame->r0-- && HAL_SD_GetCardState(&hsd) != HAL_SD_CARD_TRANSFER) {
                HAL_Delay(100);
            }
            if (frame->r0) {
                frame->r0 = HAL_OK;
            }
        }
        break;
    }
}
/* USER CODE END 1 */
