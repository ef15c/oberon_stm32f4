MODULE LTDC;
  IMPORT SYSTEM, BSP, Input, Display, L := SystemLog;

  CONST Width = BSP.Display_Width; Height = BSP.Display_Height;

  TYPE
    Pattern* = POINTER TO PatternDesc;
    PatternDesc* = RECORD w*, ox*, h*, oy*: BYTE END;
  VAR arrowL2, updownL2: INTEGER;
    ms*: Pattern; (*mouse shape*)

  PROCEDURE L2Init*;
    VAR reg: SET;
  BEGIN
    (*Layer 2*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2PFCR, 5); (*pixel format L8*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CKCR, 0); (*transparent color*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2DCCR, 0); (*Default color transparent black*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CACR, 255); (*constant alpha value 1*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2BFCR, LSL(6, 8) + 7); (*blending factors 1 and 2 Pixel Alpha x Constant Alpha*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CFBLNR, 15);
  END L2Init;

  PROCEDURE L2DeInit*;
  BEGIN SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CR, {});
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CFBAR, 0);
    SYSTEM.PUT(BSP.imr, TRUE) (*reload shadow registers immediately*)
  END L2DeInit;

  PROCEDURE SetWindow(xc, yc: HALFWORD);
    VAR xl, xr, yt, yb, x0, y0, w, h: INTEGER;
  BEGIN
    IF ms # NIL THEN yc := Height - 1 - yc; (*convert Oberon y-coordinate in LTDC coordinate*)
      xl := xc - ms.ox; xr := xc + ms.w - 1 - ms.ox;
      yt := yc - ms.oy; yb := yc + ms.h - 1 - ms.oy;
      (*clipping*) x0 := xl; y0 := yt; w := ms.w; h := ms.h;
      IF xl < 0 THEN x0 := 0; INC(w, xl) END;
      IF xr >= Width THEN INC(w, Width - 1 - xr) END;
      IF yt < 0 THEN y0 := 0; INC(h, yt) END;
      IF yb >= Height THEN INC(h, Height - 1 - yb) END;
      SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CFBAR, ORD(ms) + 4 + (x0 - xl) + ms.w*(y0 - yt));
      SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CFBLR,
        LSL(0 + ms.w*BSP.Display_BPP DIV 8, 16) + (w + 3)*BSP.Display_BPP DIV 8);
      SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2WHPCR, LSL(356+1 + x0 + w-1, 16) + 356+1 + x0);
      SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2WVPCR, LSL(27+1 + y0 + h-1, 16) + 27+1 + y0);
      SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CR, {BSP.COLKEN, BSP.LEn}); (*enable layer 2 with transparent color*)
      SYSTEM.PUT(BSP.vbr, TRUE) (*reload shadow registers immediately*)
    END
  END SetWindow;

  PROCEDURE MoveL2*;
    VAR keys: SET; x, y, z: INTEGER;
  BEGIN Input.Mouse(keys, x, y, z); SetWindow(x, y)
  END MoveL2;

  PROCEDURE ShowPatternL2*(pattern, x, y: INTEGER);
  BEGIN ms := SYSTEM.VAL(Pattern, pattern); SetWindow(x, y)
  END ShowPatternL2;

  PROCEDURE ShowArrowL2*(x, y: INTEGER);
  BEGIN ShowPatternL2(arrowL2, x, y)
  END ShowArrowL2;

  PROCEDURE Arrow*;
    VAR keys: SET; x, y, z: INTEGER;
  BEGIN Input.Mouse(keys, x, y, z); ShowArrowL2(x, y)
  END Arrow;

  PROCEDURE ShowUpdownL2*(x, y: INTEGER);
  BEGIN ShowPatternL2(updownL2, x, y)
  END ShowUpdownL2;

  PROCEDURE Updown*;
    VAR keys: SET; x, y, z: INTEGER;
  BEGIN Input.Mouse(keys, x, y, z); ShowUpdownL2(x, y)
  END Updown;

  PROCEDURE BotLef*;
  BEGIN SetWindow(1, 1)
  END BotLef;

  PROCEDURE UpRight*;
  BEGIN SetWindow(Width - 2, Height - 2)
  END UpRight;

  PROCEDURE addrBusy*;
  BEGIN L.DebugHex("busy pattern", Display.busy)
  END addrBusy;

  PROCEDURE ReinitDisplayOld*;
    VAR reg: SET;
      i: INTEGER; r, g, b: BYTE;
  BEGIN
    SYSTEM.PUT(BSP.gcr_ltdcEn, FALSE);
    (*LTDC*) SYSTEM.PUT(BSP.rcc_ltdcEn, FALSE); SYSTEM.GET(BSP.rcc_ltdcEn, reg); (*delay*)
    (*PLLSAI*) SYSTEM.PUT(BSP.pllsaiEn, FALSE); REPEAT UNTIL ~SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.PLLSAIRDY);
    SYSTEM.PUT(BSP.RCC_BASE + BSP.PLLSAICFGR, LSL(4, 24) + LSL(160, 6) + LSL(2, 28)); (*PLLSAIQ = 4, PLLSAIN = 160, PLLSAIR = 2*)
    SYSTEM.GET(BSP.RCC_BASE + BSP.DCKCFGR, reg); SYSTEM.PUT(BSP.RCC_BASE + BSP.DCKCFGR, reg - BSP.PLLSAIDIVRm); (*PLLSADIVR = 2*)
    SYSTEM.PUT(BSP.pllsaiEn, TRUE); REPEAT UNTIL SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.PLLSAIRDY);

    (*LTDC*) SYSTEM.PUT(BSP.rcc_ltdcEn, TRUE); SYSTEM.GET(BSP.rcc_ltdcEn, reg); (*delay*)
    SYSTEM.GET(BSP.LTDC_BASE + BSP.GCR, reg); SYSTEM.PUT(BSP.LTDC_BASE + BSP.GCR, reg - (BSP.DEPOLm + BSP.PCPOLm) + (BSP.HSPOLm + BSP.VSPOLm)); (*HS and VS polarity high*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.SSCR, LSL(143, 16) + 3); (*HSW 143, VSH 3*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.BPCR, LSL(356, 16) + 27); (*AHBP 356, AVBP 27*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.ACWR, LSL(1722, 16) + 795); (*AAW 1722, AAH 795*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.TWCR, LSL(1792, 16) + 798); (*Total Width 1792, height 798*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.BCCR, 0); (*Background red, green and blue 0*)
    SYSTEM.PUT(BSP.gcr_ltdcEn, TRUE);

    (*Layer 1*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1WHPCR, LSL(1722, 16) + 356+1); (*first visible pixel 357, last 1722*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1WVPCR, LSL(795, 16) + 27+1); (*first visible line 28, last 795*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1PFCR, 5); (*pixel format L8*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1DCCR, 0); (*Default color transparent black*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CACR, 255); (*constant alpha value 1*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1BFCR, LSL(6, 8) + 7); (*blending factors 1 and 2 Pixel Alpha x Constant Alpha*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBAR, BSP.Display_FBA);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBLR, LSL(BSP.Display_Pitch, 16) + (BSP.Display_Width + 3)*BSP.Display_BPP DIV 8);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBLNR, BSP.Display_Height);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CR, {}); (*disable layer 1 for CLUT update*)
    SYSTEM.PUT(BSP.imr, TRUE); (*reload shadow registers immediately*)
    FOR i := 0 TO 255 DO r := LSR(i, 5) MOD 8; g := LSR(i, 2) MOD 8; b := i MOD 4;
      SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CLUTWR, LSL(i, 24) + LSL(r*255 DIV 7, 16) + LSL(g*255 DIV 7, 8) + b*255 DIV 3)
    END;
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CR, BSP.CLUTENm + BSP.LENm); (*finally (re)enable layer 1 and color lookup table*)
    SYSTEM.PUT(BSP.vbr, TRUE); (*reload shadow registers during vertical blanking*)

    (*Layer 2*)
    Display.L2Init
  END ReinitDisplayOld;

  PROCEDURE ReinitDisplayDMTID56h*;
    VAR reg: SET;
      i: INTEGER; r, g, b: BYTE;
  BEGIN
    SYSTEM.PUT(BSP.gcr_ltdcEn, FALSE);
    (*LTDC*) SYSTEM.PUT(BSP.rcc_ltdcEn, FALSE); SYSTEM.GET(BSP.rcc_ltdcEn, reg); (*delay*)
    (*PLLSAI*) SYSTEM.PUT(BSP.pllsaiEn, FALSE); REPEAT UNTIL ~SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.PLLSAIRDY);
    SYSTEM.PUT(BSP.RCC_BASE + BSP.PLLSAICFGR, LSL(4, 24) + LSL(144, 6) + LSL(2, 28)); (*LCD-TFT = 72MHz. PLLSAIQ = 4, PLLSAIN = 144, PLLSAIR = 2*)
    SYSTEM.GET(BSP.RCC_BASE + BSP.DCKCFGR, reg); SYSTEM.PUT(BSP.RCC_BASE + BSP.DCKCFGR, reg - BSP.PLLSAIDIVRm); (*PLLSADIVR = 2*)
    SYSTEM.PUT(BSP.pllsaiEn, TRUE); REPEAT UNTIL SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.PLLSAIRDY);

    (*LTDC*) SYSTEM.PUT(BSP.rcc_ltdcEn, TRUE); SYSTEM.GET(BSP.rcc_ltdcEn, reg); (*delay*)
    SYSTEM.GET(BSP.LTDC_BASE + BSP.GCR, reg); SYSTEM.PUT(BSP.LTDC_BASE + BSP.GCR, reg - (BSP.DEPOLm + BSP.PCPOLm) + (BSP.HSPOLm + BSP.VSPOLm)); (*HS and VS polarity high*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.SSCR, LSL(55, 16) + 2); (*HSW 55, VSH 2*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.BPCR, LSL(119, 16) + 30); (*AHBP 119, AVBP 30*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.ACWR, LSL(1485, 16) + 798); (*AAW 1485, AAH 798*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.TWCR, LSL(1499, 16) + 799); (*Total Width 1499, height 799*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.BCCR, 0); (*Background red, green and blue 0*)
    SYSTEM.PUT(BSP.gcr_ltdcEn, TRUE);

    (*Layer 1*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1WHPCR, LSL(1485, 16) + 119+1); (*first visible pixel 120, last 1485*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1WVPCR, LSL(798, 16) + 30+1); (*first visible line 31, last 798*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1PFCR, 5); (*pixel format L8*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1DCCR, 0); (*Default color transparent black*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CACR, 255); (*constant alpha value 1*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1BFCR, LSL(6, 8) + 7); (*blending factors 1 and 2 Pixel Alpha x Constant Alpha*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBAR, BSP.Display_FBA);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBLR, LSL(BSP.Display_Pitch, 16) + (BSP.Display_Width + 3)*BSP.Display_BPP DIV 8);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBLNR, BSP.Display_Height);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CR, {}); (*disable layer 1 for CLUT update*)
    SYSTEM.PUT(BSP.imr, TRUE); (*reload shadow registers immediately*)
    FOR i := 0 TO 255 DO r := LSR(i, 5) MOD 8; g := LSR(i, 2) MOD 8; b := i MOD 4;
      SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CLUTWR, LSL(i, 24) + LSL(r*255 DIV 7, 16) + LSL(g*255 DIV 7, 8) + b*255 DIV 3)
    END;
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CR, BSP.CLUTENm + BSP.LENm); (*finally (re)enable layer 1 and color lookup table*)
    SYSTEM.PUT(BSP.vbr, TRUE); (*reload shadow registers during vertical blanking*)

    (*Layer 2*)
    Display.L2Init
  END ReinitDisplayDMTID56h;

  PROCEDURE ReinitDisplayDMTID51h*;
    VAR reg: SET;
      i: INTEGER; r, g, b: BYTE;
  BEGIN
    SYSTEM.PUT(BSP.gcr_ltdcEn, FALSE);
    (*LTDC*) SYSTEM.PUT(BSP.rcc_ltdcEn, FALSE); SYSTEM.GET(BSP.rcc_ltdcEn, reg); (*delay*)
    (*PLLSAI*) SYSTEM.PUT(BSP.pllsaiEn, FALSE); REPEAT UNTIL ~SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.PLLSAIRDY);
    SYSTEM.PUT(BSP.RCC_BASE + BSP.PLLSAICFGR, LSL(4, 24) + LSL(171, 6) + LSL(2, 28)); (*LCD-TFT = 85.5MHz. PLLSAIQ = 4, PLLSAIN = 171, PLLSAIR = 2*)
    SYSTEM.GET(BSP.RCC_BASE + BSP.DCKCFGR, reg); SYSTEM.PUT(BSP.RCC_BASE + BSP.DCKCFGR, reg - BSP.PLLSAIDIVRm); (*PLLSADIVR = 2*)
    SYSTEM.PUT(BSP.pllsaiEn, TRUE); REPEAT UNTIL SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.PLLSAIRDY);

    (*LTDC*) SYSTEM.PUT(BSP.rcc_ltdcEn, TRUE); SYSTEM.GET(BSP.rcc_ltdcEn, reg); (*delay*)
    SYSTEM.GET(BSP.LTDC_BASE + BSP.GCR, reg); SYSTEM.PUT(BSP.LTDC_BASE + BSP.GCR, reg - (BSP.DEPOLm + BSP.PCPOLm) + (BSP.HSPOLm + BSP.VSPOLm)); (*HS and VS polarity high*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.SSCR, LSL(142, 16) + 2); (*HSW 142, VSH 2*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.BPCR, LSL(355, 16) + 26); (*AHBP 355, AVBP 26*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.ACWR, LSL(1721, 16) + 794); (*AAW 1721, AAH 794*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.TWCR, LSL(1791, 16) + 797); (*Total Width 1791, height 797*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.BCCR, 0); (*Background red, green and blue 0*)
    SYSTEM.PUT(BSP.gcr_ltdcEn, TRUE);

    (*Layer 1*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1WHPCR, LSL(1721, 16) + 355+1); (*first visible pixel 356, last 1721*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1WVPCR, LSL(794, 16) + 26+1); (*first visible line 26, last 794*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1PFCR, 5); (*pixel format L8*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1DCCR, 0); (*Default color transparent black*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CACR, 255); (*constant alpha value 1*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1BFCR, LSL(6, 8) + 7); (*blending factors 1 and 2 Pixel Alpha x Constant Alpha*)
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBAR, BSP.Display_FBA);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBLR, LSL(BSP.Display_Pitch, 16) + (BSP.Display_Width + 3)*BSP.Display_BPP DIV 8);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CFBLNR, BSP.Display_Height);
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CR, {}); (*disable layer 1 for CLUT update*)
    SYSTEM.PUT(BSP.imr, TRUE); (*reload shadow registers immediately*)
    FOR i := 0 TO 255 DO r := LSR(i, 5) MOD 8; g := LSR(i, 2) MOD 8; b := i MOD 4;
      SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CLUTWR, LSL(i, 24) + LSL(r*255 DIV 7, 16) + LSL(g*255 DIV 7, 8) + b*255 DIV 3)
    END;
    SYSTEM.PUT(BSP.LTDC_BASE + BSP.L1CR, BSP.CLUTENm + BSP.LENm); (*finally (re)enable layer 1 and color lookup table*)
    SYSTEM.PUT(BSP.vbr, TRUE); (*reload shadow registers during vertical blanking*)

    (*Layer 2*)
    Display.L2Init
  END ReinitDisplayDMTID51h;

BEGIN
  arrowL2 := SYSTEM.ADR($  0F 00 0F 00
     FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00
     FF FF FF FF FF FF FF 00 00 00 00 00 00 00 00
     FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00
     FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00
     FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00
     FF FF FF 40 FF FF FF 00 00 00 00 00 00 00 00
     FF FF 40 20 40 FF FF FF 00 00 00 00 00 00 00
     FF 40 20 00 20 40 FF FF FF 00 00 00 00 00 00
     40 20 00 00 00 20 40 FF FF FF 00 00 00 00 00
     20 00 00 00 00 00 20 40 FF FF FF 00 00 00 00
     00 00 00 00 00 00 00 20 40 FF FF FF 00 00 00
     00 00 00 00 00 00 00 00 20 40 FF FF FF 00 00
     00 00 00 00 00 00 00 00 00 20 40 FF FF FF 00
     00 00 00 00 00 00 00 00 00 00 20 40 FF FF FF
     00 00 00 00 00 00 00 00 00 00 00 20 40 FF FF$);

  updownL2 := SYSTEM.ADR($ 08 04  0E 07 
     00 00 00 FF FF 00 00 00
     00 00 FF FF FF FF 00 00
     00 FF FF FF FF FF FF 00
     FF FF FF FF FF FF FF FF
     00 00 00 FF FF 00 00 00
     00 00 00 FF FF 00 00 00
     00 00 00 FF FF 00 00 00
     00 00 00 FF FF 00 00 00
     00 00 00 FF FF 00 00 00
     00 00 00 FF FF 00 00 00
     FF FF FF FF FF FF FF FF
     00 FF FF FF FF FF FF 00
     00 00 FF FF FF FF 00 00
     00 00 00 FF FF 00 00 00$);

   L2Init
END LTDC.

OM4P.Compile LTDC.Mod/s~
System.Free LTDC~
LTDC.L2Init
LTDC.L2DeInit
LTDC.MoveL2
LTDC.Updown
LTDC.Arrow
LTDC.BotLef
LTDC.UpRight
LTDC.addrBusy
LTDC.ReinitDisplayOld;
LTDC.ReinitDisplayDMTID56h
LTDC.ReinitDisplayDMTID51h
