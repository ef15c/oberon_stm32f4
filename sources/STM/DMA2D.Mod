MODULE DMA2D;
  IMPORT SYSTEM, BSP, Kernel;

  CONST
    (*copy engine states*)
    IDLE* = 0;
    START* = 1;
    IN_PROGRESS* = 2;

    DMA2D_CR_MODEm* = {16..17}; R2M* = {16..17};

  VAR dma2d: BSP.DMA2D; state*: BYTE;

  PROCEDURE Init*;
    VAR en: BYTE;
  BEGIN
    SYSTEM.PUT(BSP.dma2dEn, TRUE); SYSTEM.GET(BSP.dma2dEn, en)
  END Init;

  PROCEDURE WaitForCompletion*;
  BEGIN REPEAT UNTIL state = IDLE
  END WaitForCompletion;

  PROCEDURE Copy*;
    CONST x = 200; y = 200; w = 500; h = 500; dx = -100; dy = -100;
  BEGIN REPEAT UNTIL state = IDLE;
    dma2d.CR := {}; (*memory to memory*)
    dma2d.FGPFCCR := BSP.L8;
    dma2d.IFCR := {0..5}; (*clear interrupts*)
    dma2d.FGMAR := BSP.Display_FBA + x + y*BSP.Display_Pitch; (*address of first pixel of the rectangle to move*)
    dma2d.FGOR := BSP.Display_Pitch - w; (*offset to the first pixel of the next line*)
    dma2d.OMAR := BSP.Display_FBA + x+dx + (y+dy)*BSP.Display_Pitch;
    dma2d.OOR := BSP.Display_Pitch - w;
    dma2d.NLR := h + LSL(w, 16);
    state := START; SYSTEM.PUT(BSP.LTDC_BASE + BSP.LTDC_IER, {BSP.LIE, BSP.RRIE}) (*start DMA2D copy during next vertical blanking*)
  END Copy;

  PROCEDURE FillRect*(col, x, y, w, h: INTEGER);
  BEGIN REPEAT UNTIL state = IDLE;
    dma2d.CR := R2M; (*register to memory*)
    dma2d.OPFCCR := {}; (*ARGB8888*)
    dma2d.IFCR := {0..5}; (*clear interrupts*)
    dma2d.OCOLR := col + 100H*col + 10000H*col + 1000000H*col; (*set the color for 4 consecutive pixels*)
    dma2d.OMAR := BSP.Display_FBA + x + (BSP.Display_Height - y - h)*BSP.Display_Pitch;
    dma2d.OOR := (BSP.Display_Pitch - w) DIV 4;
    dma2d.NLR := h + LSL(w DIV 4, 16);
    state := START; SYSTEM.PUT(BSP.LTDC_BASE + BSP.LTDC_IER, {BSP.LIE, BSP.RRIE}) (*start DMA2D copy during next vertical blanking*)
  END FillRect;

  PROCEDURE^4 LTDC_GlobalInterrupt;
    VAR isr: SET; started: BOOLEAN;
  BEGIN SYSTEM.GET(BSP.LTDC_BASE + BSP.LTDC_ISR, isr);
    IF BSP.LIF IN isr THEN SYSTEM.PUT(BSP.LTDC_BASE + BSP.LTDC_ICR, {BSP.CLIF});
      SYSTEM.GET(BSP.dma2dStart, started);
      IF started THEN SYSTEM.PUT(BSP.dma2dSusp, TRUE) (*suspend copy*)
      ELSIF state = IN_PROGRESS THEN state := IDLE; SYSTEM.PUT(BSP.LTDC_BASE + BSP.LTDC_IER, {}) (*disable LTDC interrupts*)
      END;
      SYSTEM.PUT(BSP.vbr, TRUE) (*force reload during vertical blanking*)
    END;
    IF BSP.RRIF IN isr THEN SYSTEM.PUT(BSP.LTDC_BASE + BSP.LTDC_ICR, {BSP.CRRIF});
      IF state = START THEN SYSTEM.PUT(BSP.dma2dStart, TRUE); state := IN_PROGRESS
      ELSE SYSTEM.PUT(BSP.dma2dSusp, FALSE) (*resume copy*)
      END
    END
  END LTDC_GlobalInterrupt;

  PROCEDURE LTDC_Init;
    VAR bpcr: INTEGER; irqNum: INTEGER;
  BEGIN Kernel.Install(SYSTEM.ADR(LTDC_GlobalInterrupt), BSP.VecTabBase + BSP.LTDC_IRQNum*4);
    irqNum := BSP.LTDC_IRQNum - 16; SYSTEM.PUT(BSP.NVIC_ISER + irqNum DIV 32*4, {irqNum MOD 32});
    SYSTEM.GET(BSP.LTDC_BASE + BSP.BPCR, bpcr);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.LIPCR, bpcr MOD 1024 - 2);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.LTDC_ICR, {BSP.CLIF, BSP.CRRIF})
  END LTDC_Init;

  PROCEDURE EnableLTDCIinterrupts*;
  BEGIN SYSTEM.PUT(BSP.LTDC_BASE + BSP.LTDC_IER, {BSP.LIE, BSP.RRIE})
  END EnableLTDCIinterrupts;

  PROCEDURE DisableLTDCIinterrupts*;
  BEGIN SYSTEM.PUT(BSP.LTDC_BASE + BSP.LTDC_IER, {})
  END DisableLTDCIinterrupts;

  PROCEDURE Fill*;
  BEGIN FillRect(0FCH, 4, 4, 1364-4, 100)
  END Fill;

BEGIN dma2d := SYSTEM.VAL(BSP.DMA2D, BSP.DMA2D_BASE);
  Init;
  LTDC_Init
END DMA2D.

OM4P.Compile DMA2D.Mod/s~
System.Free DMA2D~
DMA2D.Copy
DMA2D.Fill
DMA2D.EnableLTDCIinterrupts
DMA2D.DisableLTDCIinterrupts
