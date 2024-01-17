#ifndef STM32_USEC_H_INCLUDED
#define STM32_USEC_H_INCLUDED

#include "stm32f4xx_hal.h"

// This Function Provides Delay In Microseconds Using DWT
__STATIC_INLINE void DWT_Delay_us(volatile uint32_t au32_microseconds)
{
  uint32_t au32_initial_ticks = DWT->CYCCNT;
  uint32_t au32_ticks = (HAL_RCC_GetHCLKFreq() / 1000000);
  au32_microseconds *= au32_ticks;
  while ((DWT->CYCCNT - au32_initial_ticks) < au32_microseconds-au32_ticks);
}


#endif /* STM32_USEC_H_INCLUDED */
