MODULE LTDC;
  IMPORT SYSTEM, BSP, Input;

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
