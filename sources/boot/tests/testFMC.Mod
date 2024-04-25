MODULE testFMC;
  IMPORT SYSTEM, BSP;

 PROCEDURE configureGPIO(port: INTEGER; m1b, m2b, m4bl, m4bh, m, os, ot, pup, afrl, afrh: SET);
    VAR reg: SET;
  BEGIN
    SYSTEM.GET(port + BSP.OSPEEDR, reg); SYSTEM.PUT(port + BSP.OSPEEDR, reg - m2b + os);
    SYSTEM.GET(port + BSP.OTYPER, reg); SYSTEM.PUT(port + BSP.OTYPER, reg - m1b + ot);
    SYSTEM.GET(port + BSP.PUPDR, reg); SYSTEM.PUT(port + BSP.PUPDR, reg - m2b + pup);
    SYSTEM.GET(port + BSP.AFRL, reg); SYSTEM.PUT(port + BSP.AFRL, reg - m4bl + afrl);
    SYSTEM.GET(port + BSP.AFRH, reg); SYSTEM.PUT(port + BSP.AFRH, reg - m4bh + afrh);
    SYSTEM.GET(port + BSP.MODER, reg); SYSTEM.PUT(port + BSP.MODER, reg - m2b + m)
  END configureGPIO;

  PROCEDURE init*;
(* FMC GPIO Configuration
  PB5   ------> FMC_SDCKE1
  PB6   ------> FMC_SDNE1
  PC0   ------> FMC_SDNWE
  PD0   ------> FMC_D2
  PD1   ------> FMC_D3
  PD8   ------> FMC_D13
  PD9   ------> FMC_D14
  PD10   ------> FMC_D15
  PD14   ------> FMC_D0
  PD15   ------> FMC_D1
  PE0   ------> FMC_NBL0
  PE1   ------> FMC_NBL1
  PE7   ------> FMC_D4
  PE8   ------> FMC_D5
  PE9   ------> FMC_D6
  PE10   ------> FMC_D7
  PE11   ------> FMC_D8
  PE12   ------> FMC_D9
  PE13   ------> FMC_D10
  PE14   ------> FMC_D11
  PE15   ------> FMC_D12
  PF0   ------> FMC_A0
  PF1   ------> FMC_A1
  PF2   ------> FMC_A2
  PF3   ------> FMC_A3
  PF4   ------> FMC_A4
  PF5   ------> FMC_A5
  PF11   ------> FMC_SDNRAS
  PF12   ------> FMC_A6
  PF13   ------> FMC_A7
  PF14   ------> FMC_A8
  PF15   ------> FMC_A9
  PG0   ------> FMC_A10
  PG1   ------> FMC_A11
  PG4   ------> FMC_BA0
  PG5   ------> FMC_BA1
  PG8   ------> FMC_SDCLK
  PG15   ------> FMC_SDNCAS
*)
    CONST
      maskB_1b = {5, 6};
      maskB_2b = LSL(BSP.MASK2, 5*2) + LSL(BSP.MASK2, 6*2);
      maskB_4bl = LSL(BSP.MASK4, 5*4) + LSL(BSP.MASK4, 6*4);
      maskD_1b = {0, 1, 8, 9, 10, 14, 15};
      maskD_2b = LSL(BSP.MASK2, 0*2) + LSL(BSP.MASK2, 1*2) + 
        LSL(BSP.MASK2, 8*2) + LSL(BSP.MASK2, 9*2) + LSL(BSP.MASK2, 10*2) + LSL(BSP.MASK2, 14*2) + LSL(BSP.MASK2, 15*2);
      maskD_4bl = LSL(BSP.MASK4, 0*4) + LSL(BSP.MASK4, 1*4);
      maskD_4bh = LSL(BSP.MASK4, 8 MOD 8*4) + LSL(BSP.MASK4, 9 MOD 8*4) + LSL(BSP.MASK4, 10 MOD 8*4) +
        LSL(BSP.MASK4, 14 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4);
      maskE_1b = {0, 1, 7, 8, 9, 10, 11, 12, 13, 14, 15};
      maskE_2b = LSL(BSP.MASK2, 0*2) + LSL(BSP.MASK2, 1*2) + LSL(BSP.MASK2, 7*2) +
        LSL(BSP.MASK2, 8*2) + LSL(BSP.MASK2, 9*2) + LSL(BSP.MASK2, 10*2) + LSL(BSP.MASK2, 11*2) + LSL(BSP.MASK2, 12*2) +
        LSL(BSP.MASK2, 13*2) + LSL(BSP.MASK2, 14*2) + LSL(BSP.MASK2, 15*2);
      maskE_4bl = LSL(BSP.MASK4, 0*4) + LSL(BSP.MASK4, 1*4) + LSL(BSP.MASK4, 7*4);
      maskE_4bh = LSL(BSP.MASK4, 8 MOD 8*4) + LSL(BSP.MASK4, 9 MOD 8*4) + LSL(BSP.MASK4, 10 MOD 8*4) +
        LSL(BSP.MASK4, 11 MOD 8*4) + LSL(BSP.MASK4, 12 MOD 8*4) + LSL(BSP.MASK4, 13 MOD 8*4) +
        LSL(BSP.MASK4, 14 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4);
      maskF_1b = {0, 1, 2, 3, 4, 5, 11, 12, 13, 14, 15};
      maskF_2b = LSL(BSP.MASK2, 0*2) + LSL(BSP.MASK2, 1*2) + LSL(BSP.MASK2, 2*2) + LSL(BSP.MASK2, 3*2) + LSL(BSP.MASK2, 4*2) + LSL(BSP.MASK2, 5*2) +
        LSL(BSP.MASK2, 11*2) + LSL(BSP.MASK2, 12*2) + LSL(BSP.MASK2, 13*2) + LSL(BSP.MASK2, 14*2) + LSL(BSP.MASK2, 15*2);
      maskF_4bl = LSL(BSP.MASK4, 0*4) + LSL(BSP.MASK4, 1*4) + LSL(BSP.MASK4, 2*4) + LSL(BSP.MASK4, 3*4) + LSL(BSP.MASK4, 4*4) + LSL(BSP.MASK4, 5*4);
      maskF_4bh = LSL(BSP.MASK4, 11 MOD 8*4) + LSL(BSP.MASK4, 12 MOD 8*4) + LSL(BSP.MASK4, 13 MOD 8*4) +
        LSL(BSP.MASK4, 14 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4);
      maskG_1b = {0, 1, 4, 5, 8, 15};
      maskG_2b = LSL(BSP.MASK2, 0*2) + LSL(BSP.MASK2, 1*2) + LSL(BSP.MASK2, 4*2) + LSL(BSP.MASK2, 5*2) +
        LSL(BSP.MASK2, 8*2) + LSL(BSP.MASK2, 15*2);
      maskG_4bl = LSL(BSP.MASK4, 0*4) + LSL(BSP.MASK4, 1*4) + LSL(BSP.MASK4, 4*4) + LSL(BSP.MASK4, 5*4);
      maskG_4bh = LSL(BSP.MASK4, 8 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4);
    VAR reg: SET;
  BEGIN SYSTEM.GET(BSP.RCC_BASE + BSP.AHB1ENR, reg);
    SYSTEM.PUT(BSP.RCC_BASE + BSP.AHB1ENR, reg + {BSP.GPIOBEN, BSP.GPIOCEN, BSP.GPIODEN, BSP.GPIODEN, BSP.GPIOFEN, BSP.GPIOGEN});
    SYSTEM.PUT(BSP.RCC_BASE + BSP.AHB3ENR, {BSP.FMCEN});
    
    configureGPIO(BSP.GPIOB, maskB_1b, maskB_2b, maskB_4bl, {},
      LSL(BSP.AF_MODE, 5*2) + LSL(BSP.AF_MODE, 6*2), LSL(BSP.VERY_HIGH_SPEED, 5*2) + LSL(BSP.VERY_HIGH_SPEED, 6*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 5*4) + LSL(SYSTEM.VAL(SET, 12), 6*4), {});
    configureGPIO(BSP.GPIOC, {0}, {0*2}, {0*4}, {}, LSL(BSP.AF_MODE, 0*2), LSL(BSP.VERY_HIGH_SPEED, 0*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4), {});
    configureGPIO(BSP.GPIOD, maskD_1b, maskD_2b, maskD_4bl, maskD_4bh,
      LSL(BSP.AF_MODE, 0*2) + LSL(BSP.AF_MODE, 1*2) + 
        LSL(BSP.AF_MODE, 8*2) + LSL(BSP.AF_MODE, 9*2) + LSL(BSP.AF_MODE, 10*2) + LSL(BSP.AF_MODE, 14*2) + LSL(BSP.AF_MODE, 15*2),
      LSL(BSP.VERY_HIGH_SPEED, 0*2) + LSL(BSP.VERY_HIGH_SPEED, 1*2) + 
        LSL(BSP.VERY_HIGH_SPEED, 8*2) + LSL(BSP.VERY_HIGH_SPEED, 9*2) + LSL(BSP.VERY_HIGH_SPEED, 10*2) + LSL(BSP.VERY_HIGH_SPEED, 14*2) +
        LSL(BSP.VERY_HIGH_SPEED, 15*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4) + LSL(SYSTEM.VAL(SET, 12), 1*4),
      LSL(SYSTEM.VAL(SET, 12), 8 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 9 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 10 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 14 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 15 MOD 8*4));
    configureGPIO(BSP.GPIOE, maskE_1b, maskE_2b, maskE_4bl, maskE_4bh,
      LSL(BSP.AF_MODE, 0*2) + LSL(BSP.AF_MODE, 1*2) + LSL(BSP.AF_MODE, 7*2) +
        LSL(BSP.AF_MODE, 8*2) + LSL(BSP.AF_MODE, 9*2) + LSL(BSP.AF_MODE, 10*2) + LSL(BSP.AF_MODE, 11*2) + LSL(BSP.AF_MODE, 12*2) + 
        LSL(BSP.AF_MODE, 13*2) + LSL(BSP.AF_MODE, 14*2) + LSL(BSP.AF_MODE, 15*2),
      LSL(BSP.VERY_HIGH_SPEED, 0*2) + LSL(BSP.VERY_HIGH_SPEED, 1*2) +  LSL(BSP.VERY_HIGH_SPEED, 7*2) +
        LSL(BSP.VERY_HIGH_SPEED, 8*2) + LSL(BSP.VERY_HIGH_SPEED, 9*2) + LSL(BSP.VERY_HIGH_SPEED, 10*2) + LSL(BSP.VERY_HIGH_SPEED, 11*2) +
        LSL(BSP.VERY_HIGH_SPEED, 12*2) + LSL(BSP.VERY_HIGH_SPEED, 13*2) + LSL(BSP.VERY_HIGH_SPEED, 14*2) + LSL(BSP.VERY_HIGH_SPEED, 15*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4) + LSL(SYSTEM.VAL(SET, 12), 1*4) + LSL(SYSTEM.VAL(SET, 12), 7*4),
      LSL(SYSTEM.VAL(SET, 12), 8 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 9 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 10 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 11 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 12 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 13 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 14 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 15 MOD 8*4));
    configureGPIO(BSP.GPIOF, maskF_1b, maskF_2b, maskF_4bl, maskF_4bh,
      LSL(BSP.AF_MODE, 0*2) + LSL(BSP.AF_MODE, 1*2) + LSL(BSP.AF_MODE, 2*2) + LSL(BSP.AF_MODE, 3*2) + LSL(BSP.AF_MODE, 4*2) + LSL(BSP.AF_MODE, 5*2) +
        LSL(BSP.AF_MODE, 11*2) + LSL(BSP.AF_MODE, 12*2) + LSL(BSP.AF_MODE, 13*2) + LSL(BSP.AF_MODE, 14*2) + LSL(BSP.AF_MODE, 15*2),
      LSL(BSP.VERY_HIGH_SPEED, 0*2) + LSL(BSP.VERY_HIGH_SPEED, 1*2) +  LSL(BSP.VERY_HIGH_SPEED, 2*2) + LSL(BSP.VERY_HIGH_SPEED, 3*2) +
        LSL(BSP.VERY_HIGH_SPEED, 4*2) + LSL(BSP.VERY_HIGH_SPEED, 5*2) + LSL(BSP.VERY_HIGH_SPEED, 11*2) +
        LSL(BSP.VERY_HIGH_SPEED, 12*2) + LSL(BSP.VERY_HIGH_SPEED, 13*2) + LSL(BSP.VERY_HIGH_SPEED, 14*2) + LSL(BSP.VERY_HIGH_SPEED, 15*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4) + LSL(SYSTEM.VAL(SET, 12), 1*4) + LSL(SYSTEM.VAL(SET, 12), 2*4) + LSL(SYSTEM.VAL(SET, 12), 3*4) +
        LSL(SYSTEM.VAL(SET, 12), 4*4) + LSL(SYSTEM.VAL(SET, 12), 5*4),
      LSL(SYSTEM.VAL(SET, 12), 11 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 12 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 13 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 14 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 15 MOD 8*4));
    configureGPIO(BSP.GPIOG, maskG_1b, maskG_2b, maskG_4bl, maskG_4bh,
      LSL(BSP.AF_MODE, 0*2) + LSL(BSP.AF_MODE, 1*2) + LSL(BSP.AF_MODE, 4*2) + LSL(BSP.AF_MODE, 5*2) +
        LSL(BSP.AF_MODE, 8*2) + LSL(BSP.AF_MODE, 15*2),
      LSL(BSP.VERY_HIGH_SPEED, 0*2) + LSL(BSP.VERY_HIGH_SPEED, 1*2) + LSL(BSP.VERY_HIGH_SPEED, 4*2) + LSL(BSP.VERY_HIGH_SPEED, 5*2) +
        LSL(BSP.VERY_HIGH_SPEED, 8*2) + LSL(BSP.VERY_HIGH_SPEED, 15*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4) + LSL(SYSTEM.VAL(SET, 12), 1*4) + LSL(SYSTEM.VAL(SET, 12), 4*4) + LSL(SYSTEM.VAL(SET, 12), 5*4),
      LSL(SYSTEM.VAL(SET, 12), 8 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 15 MOD 8*4));

    (*FMC SDRAM Init*)
    (*bank 2, 8_bits column address, 12-bits row address, 16-bits data bus width, 4 internal banks, 3 clocks CAS latency,
      write protection disabled, clock period equals to 2 HCLK periods, read burst enable, read  pipe delay equals to one clock cycle*)
    SYSTEM.GET(BSP.FMC_Bank5_6_R_Base + BSP.SDCR1, reg);
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDCR1, reg - (BSP.RPIPEm + {BSP.RBURST} + BSP.SDCLKm) +
      (BSP.RPIPE_DELAY_1 + {BSP.RBURST} + BSP.CLOCK_PERIOD_2));
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDCR2, BSP.COLUMN_BITS_NUM_8 + BSP.ROW_BITS_NUM_12 + BSP.MEM_BUS_WIDTH_16 +
      {BSP.NB} + BSP.CAS_LATENCY_3);
    (*TMRD 2, TXSR 7, TRAS 4, TRC 7, TWR 3, TRP 2 and TRCD 2*)
    SYSTEM.GET(BSP.FMC_Bank5_6_R_Base + BSP.SDTR1, reg);
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDTR1, reg - (BSP.TRCm + BSP.TRPm) + (LSL(SYSTEM.VAL(SET, 7-1), BSP.TRC) + LSL(SYSTEM.VAL(SET, 2-1), BSP.TRP)));
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDTR2, LSL(SYSTEM.VAL(SET, 2-1), BSP.TMRD) + LSL(SYSTEM.VAL(SET, 7-1), BSP.TXSR) +
    LSL(SYSTEM.VAL(SET, 4-1), BSP.TRAS) +  LSL(SYSTEM.VAL(SET, 3-1), BSP.TWR) + LSL(SYSTEM.VAL(SET, 2-1), BSP.TRCD));
(*todo*)
 
END init;

END testFMC.
