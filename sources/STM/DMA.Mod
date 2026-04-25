MODULE DMA;
  IMPORT SYSTEM, BSP;

  CONST 
    STREAM7_BASE = BSP.DMA2_BASE + BSP.STREAM_PARAM_SIZE*7;
      s7En = BSP.PeriphBBAlias + (STREAM7_BASE + BSP.SxCR - BSP.PeriphBase + BSP.SxCR_EN DIV 8)*32 + BSP.SxCR_EN MOD 8*4;

  VAR word: INTEGER;

  PROCEDURE Copy*(s, d, len: INTEGER; size: BYTE);
    VAR msize: SET; en, nb: INTEGER;
  BEGIN ASSERT(s MOD size = 0); ASSERT(d MOD size = 0);
    IF size = 1 THEN msize := {} ELSIF size = 2 THEN msize := {0} ELSIF size = 4 THEN msize := {1} END;
    REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0; (*Wait until previous transfer is complete*)

    SYSTEM.PUT(STREAM7_BASE + BSP.SxCR, LSL(SYSTEM.VAL(SET, 1), BSP.CHSEL) + LSL(BSP.INCR4, BSP.MBURST) +
      LSL(BSP.INCR4, BSP.PBURST) + LSL(msize, BSP.MSIZE) + LSL(msize, BSP.PSIZE) + BSP.MINCm + BSP.PINCm +
      BSP.MEMORY_TO_MEMORY);

    SYSTEM.PUT(STREAM7_BASE + BSP.SxFCR, BSP.DMDISm + BSP.FULL_FIFO);

    REPEAT IF len >= 10000H THEN nb := 0FFFFH ELSE nb := len END;
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.HIFCR, LSL(BSP.STREAM_FLAGSm, BSP.HI_OFS7)); (*Clear all DMA2 stream 7 interrupt flags*)
      SYSTEM.PUT(STREAM7_BASE + BSP.SxPAR, s);
      SYSTEM.PUT(STREAM7_BASE + BSP.SxM0AR, d);
      SYSTEM.PUT(STREAM7_BASE + BSP.SxNDTR, nb);
      SYSTEM.PUT(s7En, 1); (*don't use TRUE because this register must be accessed by words (32 bits)*)
      DEC(len, nb); INC(s, nb*size); INC(d, nb*size);
      REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0 (*Wait until previous transfer is complete*)
    UNTIL len = 0;
  END Copy;

  PROCEDURE Set*(w, d, len: INTEGER; size: BYTE);
    VAR msize: SET; en, nb: INTEGER;
  BEGIN ASSERT(d MOD size = 0); word := w;
    IF size = 1 THEN msize := {} ELSIF size = 2 THEN msize := {0} ELSIF size = 4 THEN msize := {1} END;
    REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0; (*Wait until previous transfer is complete*)

    SYSTEM.PUT(STREAM7_BASE + BSP.SxCR, LSL(SYSTEM.VAL(SET, 1), BSP.CHSEL) + LSL(BSP.INCR4, BSP.MBURST) +
      LSL(BSP.INCR4, BSP.PBURST) + LSL(msize, BSP.MSIZE) + LSL(msize, BSP.PSIZE) + BSP.MINCm +
      BSP.MEMORY_TO_MEMORY);
    SYSTEM.PUT(STREAM7_BASE + BSP.SxFCR, BSP.DMDISm + BSP.FULL_FIFO);

    REPEAT IF len >= 10000H THEN nb := 0FFFFH ELSE nb := len END;
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.HIFCR, LSL(BSP.STREAM_FLAGSm, BSP.HI_OFS7)); (*Clear all DMA2 stream 7 interrupt flags*)
      SYSTEM.PUT(STREAM7_BASE + BSP.SxPAR, SYSTEM.ADR(word));
      SYSTEM.PUT(STREAM7_BASE + BSP.SxM0AR, d);
      SYSTEM.PUT(STREAM7_BASE + BSP.SxNDTR, nb);
      SYSTEM.PUT(s7En, 1); (*don't use TRUE because this register must be accessed by words (32 bits)*)
      DEC(len, nb); INC(d, nb*size);
      REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0 (*Wait until previous transfer is complete*)
    UNTIL len = 0;
  END Set;
END DMA.

OM4P.Compile DMA.Mod/s~
