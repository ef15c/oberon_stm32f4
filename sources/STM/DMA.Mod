MODULE DMA;
  IMPORT SYSTEM, BSP;

  CONST STA = BSP.SDIO_BASE + BSP.STA;
    STREAM7_BASE = BSP.DMA2_BASE + BSP.STREAM_PARAM_SIZE*7;
      s7En = BSP.PeriphBBAlias + (STREAM7_BASE + BSP.SxCR - BSP.PeriphBase + BSP.SxCR_EN DIV 8)*32 + BSP.SxCR_EN MOD 8*4;

  PROCEDURE Copy*(s, d, len: INTEGER; size: BYTE);
    VAR reg, hisr, sta, msize: SET; en, nb: INTEGER;
  BEGIN ASSERT(s MOD size = 0); ASSERT(d MOD size = 0);
    IF size = 1 THEN msize := {} ELSIF size = 2 THEN msize := {0} ELSIF size = 4 THEN msize := {1} END;
    REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0; (*Wait until previous transfer is complete*)

    SYSTEM.PUT(STREAM7_BASE + BSP.SxCR, LSL(SYSTEM.VAL(SET, 1), BSP.CHSEL) + LSL(BSP.INCR4, BSP.MBURST) +
      LSL(BSP.INCR4, BSP.PBURST) + LSL(msize, BSP.MSIZE) + LSL(msize, BSP.PSIZE) + BSP.MINCm + {BSP.PINC} +
      BSP.MEMORY_TO_MEMORY);
    SYSTEM.PUT(STREAM7_BASE + BSP.SxFCR, BSP.DMDISm + BSP.FULL_FIFO);
    SYSTEM.PUT(BSP.DMA2_BASE + BSP.HIFCR, LSL(BSP.STREAM_FLAGSm, BSP.HI_OFS7)); (*Clear all DMA2 stream 7 interrupt flags*)

    REPEAT IF len >= 10000H THEN nb := 0FFFFH ELSE nb := len END;
      REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0;
      SYSTEM.PUT(STREAM7_BASE + BSP.SxPAR, s);
      SYSTEM.PUT(STREAM7_BASE + BSP.SxM0AR, d);
      SYSTEM.PUT(STREAM7_BASE + BSP.SxNDTR, nb);

      SYSTEM.GET(STREAM7_BASE + BSP.SxCR, reg);
      SYSTEM.PUT(STREAM7_BASE + BSP.SxCR, reg - (BSP.HTIEm + BSP.DMEIEm + BSP.SxCR_TCIEm + BSP.TEIEm)); (*disable all interrupts*)
      SYSTEM.GET(STREAM7_BASE + BSP.SxFCR, reg);
      SYSTEM.PUT(STREAM7_BASE + BSP.SxFCR, reg - BSP.FEIEm); (*disable fifo interrupt*)
      SYSTEM.PUT(s7En, 1); (*don't use TRUE because this register must be accessed by words (32 bits)*)
      DEC(len, nb); INC(s, nb*size); INC(d, nb*size)
    UNTIL len = 0;
  END Copy;

END DMA.

OM4P.Compile DMA.Mod/s~
