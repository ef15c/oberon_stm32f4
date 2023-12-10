#include <stdint.h>

#if 1
__attribute__ ((long_call, section (".SDRamFunc")))
#endif
void codeInRam(void)
{
  volatile int i;

  volatile float a, b, c;
  a = 1.;
  b = 2.;
  c = a+b;
  a = c;

  for (i=0; i<100000; i++);
}

extern uint32_t _sitext2;
extern uint32_t _stext2;
extern uint32_t _etext2;

void copyFunction(void)
{
    uint32_t *init_code = &_sitext2;
    uint32_t *sdram = &_stext2;
    uint32_t *sdram_end= &_etext2;

    while (sdram < sdram_end) {
        *sdram++ = *init_code++;
    }
}
