MODULE Display;  (*NW 5.11.2013 / 17.1.2019*)
(*CS 23/12/2023*)

  IMPORT SYSTEM, BSP;

  CONST black* = 0; white* = 255;  (*black = background*) midgrey* = 49H; (*010 010 01*)
    red* = 0E0H; green* = 1CH; blue* = 3H; yellow* = 0FCH; magenta* = 0E3H; cyan* = 1FH;
    replace* = 0; paint* = 1; invert* = 2;  (*modes*)
    Base* = BSP.Display_FBA; Width* = BSP.Display_Width; Height* = BSP.Display_Height; NofBPP* = BSP.Display_BPP;
    Span = BSP.Display_Pitch;
    NofPixperWord* = 32 DIV NofBPP;

    STREAM7_BASE = BSP.DMA2_BASE + BSP.STREAM_PARAM_SIZE*7;
    s7En = BSP.PeriphBBAlias + (STREAM7_BASE + BSP.SxCR - BSP.PeriphBase + BSP.SxCR_EN DIV 8)*32 + BSP.SxCR_EN MOD 8*4;

  TYPE Frame* = POINTER TO FrameDesc;
    FrameMsg* = RECORD END ;
    Handler* = PROCEDURE (F: Frame; VAR M: FrameMsg);
    FrameDesc* = RECORD next*, dsc*: Frame;
        X*, Y*, W*, H*: INTEGER;
        handle*: Handler
      END ;
    Line* = ARRAY (Width + 3) DIV 4*4 OF BYTE;
    Pattern = POINTER TO PatternDesc;
    PatternDesc = RECORD w, ox, h, oy: BYTE END;

  VAR
    (*a pattern is an array of bytes; the first is its width (< 32), the second its height, the rest the raster*)
    arrowL2*, star*, hook*, updownL2*, block*, cross*, grey*, busy*: INTEGER;
    pattern: SET; (*cannot be in Core Coupled Memory to be accessible from DMA*)
    ms: Pattern;

  PROCEDURE Handle*(F: Frame; VAR M: FrameMsg);
  BEGIN
    IF (F # NIL) & (F.handle # NIL) THEN F.handle(F, M) END
  END Handle;

  (* raster ops *)
  PROCEDURE Dot*(col, x, y, mode: INTEGER);
    VAR a, pp: INTEGER; u, s: SET;
  BEGIN a := Base + x DIV NofPixperWord*4 + (Height-1-y)*Span; pp := x MOD NofPixperWord*NofBPP;
    pattern := SYSTEM.VAL(SET, 0+col + 256*(col + 256*(col + 256*col)));
    s := {pp .. pp+NofBPP-1}; SYSTEM.GET(a, u);
    IF mode = paint THEN SYSTEM.PUT(a, u + s*pattern)
    ELSIF mode = invert THEN SYSTEM.PUT(a, u / (s*pattern))
    ELSE (*mode = replace*) SYSTEM.PUT(a, u - s + s*pattern)
    END
  END Dot;

  PROCEDURE ReplConst*(col, x, y, w, h, mode: INTEGER);
    VAR al, ar, a0, a1, i, ppl, ppr: INTEGER; left, right, mid, pix, pixl, pixr: SET;
      en: INTEGER;
  BEGIN al := Base + (Height-1-y)*Span;
    ar := (x+w-1) DIV NofPixperWord*4 + al; al := x DIV NofPixperWord*4 + al;
    ppl := x MOD NofPixperWord*NofBPP; ppr := (x+w-1) MOD NofPixperWord*NofBPP;
    pattern := SYSTEM.VAL(SET, 0+col + 256*(col + 256*(col + 256*col)));
    IF ar = al THEN
      mid := {ppl .. ppr+NofBPP-1};
      a1 := al;
      FOR i := 1 TO h DO
        SYSTEM.GET(a1, pix);
        IF mode = invert THEN SYSTEM.PUT(a1, pix / (mid*pattern))
        ELSIF mode = replace THEN SYSTEM.PUT(a1, pix - mid + mid*pattern)
        ELSE (*mode = paint*) SYSTEM.PUT(a1, pix + mid*pattern)
        END;
        DEC(a1, Span)
      END
    ELSIF ar > al THEN
      left := {ppl .. 31}; right := {0 .. ppr+NofBPP-1};
      a0 := al;
      IF  mode = replace THEN ASSERT((ar - a0 - 4) DIV 4 < 10000H);
        REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0; (*Wait until previous transfer is complete*)
        SYSTEM.PUT(STREAM7_BASE + BSP.SxCR, LSL(SYSTEM.VAL(SET, 1), BSP.CHSEL) +
          LSL(BSP.INCR4, BSP.PBURST) + LSL({1}, BSP.MSIZE) + LSL({1}, BSP.PSIZE) + BSP.MINCm +
          BSP.MEMORY_TO_MEMORY);
        SYSTEM.PUT(STREAM7_BASE + BSP.SxFCR, BSP.DMDISm + BSP.FULL_FIFO);
      END;
      FOR i := 1 TO h DO
        SYSTEM.GET(a0, pixl); SYSTEM.GET(ar, pixr);
        IF mode = invert THEN
          SYSTEM.PUT(a0, pixl / (left*pattern));
          FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.GET(a1, pix); SYSTEM.PUT(a1, pix / pattern) END ;
          SYSTEM.PUT(ar, pixr / (right*pattern))
        ELSIF mode = replace THEN
          SYSTEM.PUT(a0, pixl - left + left*pattern);
          (*FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.PUT(a1, pattern) END ;*)
          (*use DMA*)
          IF a0+4 < ar THEN
            REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0; (*Wait until previous transfer is complete*)
            SYSTEM.PUT(BSP.DMA2_BASE + BSP.HIFCR, LSL(BSP.STREAM_FLAGSm, BSP.HI_OFS7)); (*Clear all DMA2 stream 7 interrupt flags*)
            SYSTEM.PUT(STREAM7_BASE + BSP.SxPAR, SYSTEM.ADR(pattern));
            SYSTEM.PUT(STREAM7_BASE + BSP.SxM0AR, a0 + 4);
            SYSTEM.PUT(STREAM7_BASE + BSP.SxNDTR, (ar - a0 - 4) DIV 4);
            SYSTEM.PUT(s7En, 1); (*don't use TRUE because this register must be accessed by words (32 bits)*)
          END;
          SYSTEM.PUT(ar, pixr - right + right*pattern)
        ELSE (*mode = paint *)
          SYSTEM.PUT(a0, pixl + left*pattern);
          FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.GET(a1, pix); SYSTEM.PUT(a1, pix + pattern) END ;
          SYSTEM.PUT(ar, pixr + right*pattern)
        END ;
        DEC(ar, Span); DEC(a0, Span)
      END;
      IF  mode = replace THEN
        REPEAT SYSTEM.GET(s7En, en) UNTIL en = 0; (*Wait until previous transfer is complete*)
      END
    END
  END ReplConst;

  PROCEDURE CopyPattern*(col, patadr, x, y, mode: INTEGER);  (*only for modes = paint, invert*)
    VAR a0, i, j, pixAdr: INTEGER; pix, col4: SET;
      w, h: BYTE; ps, psn, last, middle: INTEGER;
  BEGIN col4 := SYSTEM.VAL(SET, col + 256*(col + 256*(col + 256*col)));
    SYSTEM.GET(patadr, i); w := i MOD 100H; h := i DIV 10000H MOD 100H; INC(patadr, 4);
    a0 := Base + x DIV NofPixperWord*4 + (Height-1-y)*Span; x := x MOD NofPixperWord;
    last :=  (w+x+3) DIV 4 - 1; middle := (w+3) DIV 4;
    FOR i := 1 TO h DO
      (*build frame buffer line w<32*)
      IF x = 0 THEN (*pattern and frame buffer are aligned*)
        FOR j := 0 TO last DO pixAdr := a0 + 4*j;
          SYSTEM.GET(patadr, ps); INC(patadr, 4); SYSTEM.GET(pixAdr, pix);
          IF mode = invert THEN SYSTEM.PUT(pixAdr, pix / SYSTEM.VAL(SET, ps)*col4)
          ELSE SYSTEM.PUT(pixAdr, pix + SYSTEM.VAL(SET, ps)*col4) END
        END
      ELSE(*pattern must be right shifted by x pixels. Because of little endianness of
                 STMF429 processor, words have to be left shifted by x*NofBPP*)
        SYSTEM.GET(patadr, ps); INC(patadr, 4); SYSTEM.GET(a0, pix);
        IF mode = invert THEN SYSTEM.PUT(a0, pix / SYSTEM.VAL(SET, LSL(ps, x*NofBPP))*col4)
        ELSE SYSTEM.PUT(a0, pix + SYSTEM.VAL(SET, LSL(ps, x*NofBPP))*col4) END;
        (*process frame buffer words except the last one*)
        j := 1;
        WHILE j < middle DO pixAdr := a0 + 4*j;
          SYSTEM.GET(patadr, psn); INC(patadr, 4); SYSTEM.GET(pixAdr, pix);
          ps := LSR(ps, (NofPixperWord - x)*NofBPP) + LSL(psn, x*NofBPP);
          IF mode = invert THEN SYSTEM.PUT(pixAdr, pix / SYSTEM.VAL(SET, ps)*col4)
          ELSE SYSTEM.PUT(pixAdr, pix + SYSTEM.VAL(SET, ps)*col4) END;
          ps := psn; INC(j)
        END;
        IF j <= last THEN pixAdr := a0 + 4*j; SYSTEM.GET(pixAdr, pix);
          (*process last word*)
          ps := LSR(ps, (NofPixperWord - x)*NofBPP);
          IF mode = invert THEN SYSTEM.PUT(pixAdr, pix / SYSTEM.VAL(SET, ps)*col4)
          ELSE SYSTEM.PUT(pixAdr, pix + SYSTEM.VAL(SET, ps)*col4) END
        END
      END;
      DEC(a0, Span)
    END
  END CopyPattern;

  PROCEDURE CopyBlock*(sx, sy, w, h, dx, dy, mode: INTEGER); (*only for mode = replace*)
    VAR sa, da, sa0, sa1, d, len: INTEGER;
      u0, u1, u2, v0, v1, v3, n: INTEGER;
      end, step: INTEGER;
      src, dst, spill: SET;
      m0, m1, m2, m3: SET;
  BEGIN
    u0 := sx DIV NofPixperWord; u1 := sx MOD NofPixperWord; u2 := (sx+w) DIV NofPixperWord;
    v0 := dx DIV NofPixperWord; v1 := dx MOD NofPixperWord; v3 := (dx+w) MOD NofPixperWord;
    sa := Base + u0*4 + (Height-1-sy)*Span; da := Base + v0*4 + (Height-1-dy)*Span;
    d := da - sa; n := u1 - v1;   (*displacement in words and pixels*)
    len := (u2 - u0) * 4;
    m0 := {v1*NofBPP .. 31}; m2 := {v3*NofBPP .. 31}; m3 := m0 / m2;
    IF d >= 0 THEN (*copy down, scan up*) sa0 := sa; end := sa - h*Span; step := -Span
    ELSE (*copy up, scan down*) sa0 := sa - (h-1)*Span; end := sa + Span; step := Span
    END ;
    WHILE sa0 # end DO
      IF n >= 0 THEN (*shift right*) m1 := {n*NofBPP .. 31};
        IF v1 + w >= NofPixperWord THEN
          SYSTEM.GET(sa0+len, src); src := ROR(src, n*NofBPP);
          SYSTEM.GET(sa0+len+d, dst);
          SYSTEM.PUT(sa0+len+d, (dst * m2) + (src * m1 - m2));
          spill := src - m1;
          FOR sa1 := sa0 + len-4 TO sa0+4  BY -4 DO
            SYSTEM.GET(sa1, src); src := ROR(src, n*NofBPP);
            SYSTEM.PUT(sa1+d, spill + (src * m1));
            spill := src - m1
          END ;
          SYSTEM.GET(sa0, src); src := ROR(src, n*NofBPP);
          SYSTEM.GET(sa0+d, dst);
          SYSTEM.PUT(sa0+d, ((spill + (src * m1)) * m0) + (dst - m0))
        ELSE SYSTEM.GET(sa0, src); src := ROR(src, n*NofBPP);
          SYSTEM.GET(sa0+d, dst);
          SYSTEM.PUT(sa0+d, (src * m3) + (dst - m3))
        END
      ELSE (*shift left*) m1 := {-n*NofBPP .. 31};
        SYSTEM.GET(sa0, src); src := ROR(src, 32+n*NofBPP);
        SYSTEM.GET(sa0+d, dst);
        IF v1 + w < NofPixperWord THEN
          SYSTEM.PUT(sa0+d, (dst - m3) + (src * m3))
        ELSE SYSTEM.PUT(sa0+d, (dst - m0) + (src * m0));
          spill := src - m1;
          FOR sa1 := sa0+4 TO sa0 + len BY 4 DO
            SYSTEM.GET(sa1, src); src := ROR(src, 32+n*NofBPP);
            SYSTEM.PUT(sa1+d, spill + (src * m1));
            spill := src - m1
          END ;
          IF len+v1 > w THEN
            SYSTEM.GET(sa0+len+4+d, dst);
            SYSTEM.PUT(sa0+len+4+d, (spill - m2) + (dst * m2))
          END
        END
      END ;
      INC(sa0, step)
    END
  END CopyBlock;

  PROCEDURE ReplPattern*(col, patadr, x, y, w, h, mode: INTEGER);
  (* pattern width = 4, fixed; pattern starts at patadr+4, for mode = invert only *)
    VAR al, ar, a0, a1, i: INTEGER;
      pta0, pta1: INTEGER;  (*pattern addresses*)
      ph: BYTE;
      left, right, mid, pix, pixl, pixr, ptw: SET;
  BEGIN al := Base + (Height-1-y)*Span; SYSTEM.GET(patadr+1, ph);
    pta0 := patadr+4; pta1 := ph*4 + pta0;
    ar := ((x+w-1) DIV NofPixperWord)*4 + al; al := (x DIV NofPixperWord)*4 + al;
    IF ar = al THEN
      mid := {x MOD NofPixperWord*NofBPP .. (x+w-1) MOD NofPixperWord*NofBPP+NofBPP-1};
      a1 := al;
      FOR i := 1 TO h DO
        SYSTEM.GET(a1, pix); SYSTEM.GET(pta0, ptw); SYSTEM.PUT(a1, (pix - mid) + (pix/ptw * mid)); INC(pta0, 4);
        IF pta0 = pta1 THEN pta0 := patadr+4 END;
        DEC(a1, Span);
      END
    ELSIF ar > al THEN
      left := {x MOD NofPixperWord*NofBPP .. 31}; right := {0 .. (x+w-1) MOD NofPixperWord*NofBPP+NofBPP-1};
      a0 := al;
      FOR i := 1 TO h DO
        SYSTEM.GET(a0, pixl); SYSTEM.GET(pta0, ptw); SYSTEM.PUT(a0, (pixl - left) + (pixl/ptw * left));
        FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.GET(a1, pix); SYSTEM.PUT(a1, pix/ptw) END ;
        SYSTEM.GET(ar, pixr); SYSTEM.PUT(ar, (pixr - right) + (pixr/ptw * right));
        INC(pta0, 4); DEC(ar, Span);
        IF pta0 = pta1 THEN pta0 := patadr+4 END;
        DEC(a0, Span)
      END
    END
  END ReplPattern;

  PROCEDURE GetLine*(y: INTEGER; l: Line);
    VAR a: INTEGER;
  BEGIN a := Base + (Height-1-y)*Span; SYSTEM.COPY(a, SYSTEM.ADR(l), SYSTEM.SIZE(Line) DIV 4)
  END GetLine;

  PROCEDURE MovePattern*(xc, yc: INTEGER);
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
  END MovePattern;

  PROCEDURE SetMousePattern*(pat, x, y: INTEGER);
    VAR pms!: Pattern;
  BEGIN pms := ms; ms := SYSTEM.VAL(Pattern, pat);
    IF pms # ms THEN MovePattern(x, y) END
  END SetMousePattern;

  PROCEDURE ShowPatternL2*(pat, x, y: INTEGER);
  BEGIN ms := SYSTEM.VAL(Pattern, pat); MovePattern(x, y);
  END ShowPatternL2;

  PROCEDURE DisableL2*;
  BEGIN SYSTEM.PUT(BSP.LTDC_BASE + BSP.L2CR, {});
    SYSTEM.PUT(BSP.imr, TRUE) (*reload shadow registers immediately*)
  END DisableL2;

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

BEGIN
  arrowL2 := SYSTEM.ADR($ 0F 00 0F 00
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

  star := SYSTEM.ADR($ 0F00  0F00 
     00 00 00 00 00 00 00 FF 00 00 00 00 00 00 00 00
     00 FF 00 00 00 00 00 FF 00 00 00 00 00 FF 00 00
     00 00 FF 00 00 00 00 FF 00 00 00 00 FF 00 00 00
     00 00 00 FF 00 00 00 FF 00 00 00 FF 00 00 00 00
     00 00 00 00 FF 00 00 FF 00 00 FF 00 00 00 00 00
     00 00 00 00 00 FF 00 FF 00 FF 00 00 00 00 00 00
     00 00 00 00 00 00 FF FF FF 00 00 00 00 00 00 00
     FF FF FF FF FF FF FF 00 FF FF FF FF FF FF FF 00
     00 00 00 00 00 00 FF FF FF 00 00 00 00 00 00 00
     00 00 00 00 00 FF 00 FF 00 FF 00 00 00 00 00 00
     00 00 00 00 FF 00 00 FF 00 00 FF 00 00 00 00 00
     00 00 00 FF 00 00 00 FF 00 00 00 FF 00 00 00 00
     00 00 FF 00 00 00 00 FF 00 00 00 00 FF 00 00 00
     00 FF 00 00 00 00 00 FF 00 00 00 00 00 FF 00 00
     00 00 00 00 00 00 00 FF 00 00 00 00 00 00 00 00$);

  hook := SYSTEM.ADR($ 0C00  0C00 
     FF FF FF 00 00 00 00 00 FF FF FF FF
     FF FF FF 00 00 00 00 FF FF FF FF 00
     FF FF FF 00 00 00 FF FF FF FF 00 00
     FF FF FF 00 00 FF FF FF FF 00 00 00
     FF FF FF 00 FF FF FF FF 00 00 00 00
     FF FF FF FF FF FF FF 00 00 00 00 00
     FF FF FF FF FF FF 00 00 00 00 00 00
     FF FF FF FF FF 00 00 00 00 00 00 00
     FF FF FF FF 00 00 00 00 00 00 00 00
     FF FF FF 00 00 00 00 00 00 00 00 00
     FF FF 00 00 00 00 00 00 00 00 00 00
     FF 00 00 00 00 00 00 00 00 00 00 00$);

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

  block := SYSTEM.ADR($ 0800  0800 
     FF FF FF FF FF FF FF FF
     FF FF FF FF FF FF FF FF
     FF FF 00 00 00 00 FF FF
     FF FF 00 00 00 00 FF FF
     FF FF 00 00 00 00 FF FF
     FF FF 00 00 00 00 FF FF
     FF FF FF FF FF FF FF FF
     FF FF FF FF FF FF FF FF$);

  cross := SYSTEM.ADR($ 0F00  0F00 
     FF 00 00 00 00 00 00 00 00 00 00 00 00 00 FF 00
     00 FF 00 00 00 00 00 00 00 00 00 00 00 FF 00 00
     00 00 FF 00 00 00 00 00 00 00 00 00 FF 00 00 00
     00 00 00 FF 00 00 00 00 00 00 00 FF 00 00 00 00
     00 00 00 00 FF 00 00 00 00 00 FF 00 00 00 00 00
     00 00 00 00 00 FF 00 00 00 FF 00 00 00 00 00 00
     00 00 00 00 00 00 FF 00 FF 00 00 00 00 00 00 00
     00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
     00 00 00 00 00 00 FF 00 FF 00 00 00 00 00 00 00
     00 00 00 00 00 FF 00 00 00 FF 00 00 00 00 00 00
     00 00 00 00 FF 00 00 00 00 00 FF 00 00 00 00 00
     00 00 00 FF 00 00 00 00 00 00 00 FF 00 00 00 00
     00 00 FF 00 00 00 00 00 00 00 00 00 FF 00 00 00
     00 FF 00 00 00 00 00 00 00 00 00 00 00 FF 00 00
     FF 00 00 00 00 00 00 00 00 00 00 00 00 00 FF 00$);

  grey := SYSTEM.ADR($ 0400 0200 
     FF 00 FF 00
     00 FF 00 FF$);

  busy := SYSTEM.ADR($ 08 04  0E07 
     FF FF FF FF FF FF FF FF
     FF 01 01 01 01 01 01 FF
     00 FF 01 01 01 01 FF 00
     00 FF 01 01 01 01 FF 00
     00 00 FF FF FF FF 00 00
     00 00 FF FF FF FF 00 00
     00 00 00 FF FF 00 00 00
     00 00 00 FF FF 00 00 00
     00 00 FF 01 01 FF 00 00
     00 00 FF 01 01 FF 00 00
     00 FF FF FF FF FF FF 00
     00 FF FF FF FF FF FF 00
     FF FF FF FF FF FF FF FF
     FF FF FF FF FF FF FF FF$);

  L2Init
END Display.
