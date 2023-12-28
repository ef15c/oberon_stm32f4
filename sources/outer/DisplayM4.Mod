MODULE Display;  (*NW 5.11.2013 / 17.1.2019*)
(*CS 23/12/2023*)

  IMPORT SYSTEM;

  CONST black* = 0; white* = 255;  (*black = background*)
    replace* = 0; paint* = 1; invert* = 2;  (*modes*)
    Base* = 0D0000000H; Width* = 1366; Height* = 768; NofBPP = 8;
    NofPixperWord = 32 DIV NofBPP; Span = Width*8 DIV NofBPP;

  TYPE Frame* = POINTER TO FrameDesc;
    FrameMsg* = RECORD END ;
    Handler* = PROCEDURE (F: Frame; VAR M: FrameMsg);
    FrameDesc* = RECORD next*, dsc*: Frame;
        X*, Y*, W*, H*: INTEGER;
        handle*: Handler
      END ;

  VAR arrow*, star*, hook*, updown*, block*, cross*, grey*: INTEGER;
    (*a pattern is an array of bytes; the first is its width (< 32), the second its height, the rest the raster*)
    
  PROCEDURE Handle*(F: Frame; VAR M: FrameMsg);
  BEGIN
    IF (F # NIL) & (F.handle # NIL) THEN F.handle(F, M) END
  END Handle;

  (* raster ops *)
  PROCEDURE Dot*(col, x, y, mode: INTEGER);
    VAR a, pp: INTEGER; u, s: SET;
  BEGIN a := Base + x DIV NofPixperWord*4 + (Height-1-y)*Span; pp := x MOD NofPixperWord*NofBPP;
    s := {pp .. pp+NofBPP-1}; SYSTEM.GET(a, u);
    IF mode = paint THEN SYSTEM.PUT(a, u + s)
    ELSIF mode = invert THEN SYSTEM.PUT(a, u / s)
    ELSE (*mode = replace*)
      IF col # black THEN SYSTEM.PUT(a, u + s) ELSE SYSTEM.PUT(a, u - s) END
    END
  END Dot;

  PROCEDURE ReplConst*(col, x, y, w, h, mode: INTEGER);
    VAR al, ar, a0, a1, i, ppl, ppr: INTEGER; left, right, mid, pix, pixl, pixr: SET;
  BEGIN al := Base + (Height-1-y)*Span;
    ar := (x+w-1) DIV NofPixperWord*4 + al; al := x DIV NofPixperWord*4 + al;
    ppl := x MOD NofPixperWord*NofBPP; ppr := (x+w-1) MOD NofPixperWord*NofBPP;
    IF ar = al THEN
      mid := {ppl .. ppr+NofBPP-1};
      a1 := al;
      FOR i := 1 TO h DO
        SYSTEM.GET(a1, pix);
        IF mode = invert THEN SYSTEM.PUT(a1, pix / mid)
        ELSIF (mode = replace) & (col = black) THEN (*erase*) SYSTEM.PUT(a1, pix - mid)
        ELSE (* (mode = paint) OR (mode = replace) & (col # black) *) SYSTEM.PUT(a1, pix + mid)
        END;
        DEC(a1, Span)
      END
    ELSIF ar > al THEN
      left := {ppl .. 31}; right := {0 .. ppr+NofBPP-1};
      a0 := al;
      FOR i := 1 TO h DO
        SYSTEM.GET(a0, pixl); SYSTEM.GET(ar, pixr);
        IF mode = invert THEN
          SYSTEM.PUT(a0, pixl / left);
          FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.GET(a1, pix); SYSTEM.PUT(a1, -pix) END ;
          SYSTEM.PUT(ar, pixr / right)
        ELSIF (mode = replace) & (col = black) THEN (*erase*)
          SYSTEM.PUT(a0, pixl - left);
          FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.PUT(a1, {}) END ;
          SYSTEM.PUT(ar, pixr - right)
        ELSE (* (mode = paint) OR (mode = replace) & (col # black) *)
          SYSTEM.PUT(a0, pixl + left);
          FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.PUT(a1, {0 .. 31}) END ;
          SYSTEM.PUT(ar, pixr + right)
        END ;
        DEC(ar, Span); DEC(a0, Span)
      END
    END
  END ReplConst;

(*
  PROCEDURE CopyPattern*(col, patadr, x, y, mode: INTEGER);  (*only for modes = paint, invert*)
    VAR a0, i, j: INTEGER; line: ARRAY 32 DIV NofPixperWord + 1 OF SET;
      w, h: BYTE; ps, psn, last: INTEGER;
  BEGIN SYSTEM.GET(patadr, i); w := i MOD 100H; h := i DIV 10000H MOD 100H; INC(patadr, 4);
    a0 := Base + x DIV NofPixperWord*4 + (Height-1-y)*Span; x := x MOD NofPixperWord;
    FOR i := 1 TO h DO
      (*build frame buffer line w<32*)
      last := (w+x+3) DIV 4 - 1;
      FOR j := 0 TO last DO SYSTEM.GET(a0+j*4, line[j]) END;
      IF x = 0 THEN (*pattern and frame buffer are aligned*)
        FOR j := 0 TO last DO
          SYSTEM.GET(patadr, ps); INC(patadr, 4);
          IF mode = invert THEN line[j] := line[j] / SYSTEM.VAL(SET, ps)
          ELSE line[j] := line[j] + SYSTEM.VAL(SET, ps) END
        END
      ELSE(*pattern must be right shifted by x pixels. Because of little endianness of
            STMF429 processor, words have to be left shifted by x*NofBPP*)
        SYSTEM.GET(patadr, ps); INC(patadr, 4);
        IF mode = invert THEN line[0] := line[0] / SYSTEM.VAL(SET, LSL(ps, x*NofBPP))
        ELSE line[0] := line[0] + SYSTEM.VAL(SET, LSL(ps, x*NofBPP)) END;
        (*process frame buffer words except the last one*)
        j := 1;
        WHILE j < (w+3) DIV 4 DO
          SYSTEM.GET(patadr, psn); INC(patadr, 4);
          ps := LSR(ps, (NofPixperWord - x)*NofBPP) + LSL(psn, x*NofBPP);
          IF mode = invert THEN line[j] := line[j] / SYSTEM.VAL(SET, ps)
          ELSE line[j] := line[j] + SYSTEM.VAL(SET, ps) END;
          ps := psn; INC(j)
        END;
        IF j <= last THEN
          (*process last word*)
          ps := LSR(ps, (NofPixperWord - x)*NofBPP);
          IF mode = invert THEN line[j] := line[j] / SYSTEM.VAL(SET, ps)
          ELSE line[j] := line[j] + SYSTEM.VAL(SET, ps) END
        END
      END;
      (*update frame buffer for this line*)
      FOR j := 0 TO last DO SYSTEM.PUT(a0+j*4, line[j]) END;      
      DEC(a0, Span)
    END
  END CopyPattern;
*)
  PROCEDURE CopyPattern*(col, patadr, x, y, mode: INTEGER);  (*only for modes = paint, invert*)
  BEGIN
    SYSTEM.LDREG(0, col); SYSTEM.LDREG(1, patadr);
    SYSTEM.LDREG(2, x*10000H+y); SYSTEM.LDREG(3, mode);
    col := SYSTEM.SVC(6)
  END CopyPattern;

  PROCEDURE CopyBlock*(sx, sy, w, h, dx, dy, mode: INTEGER); (*only for mode = replace*)
    VAR sa, da, sa0, sa1, d, len: INTEGER;
      u0, u1, u2, u3, v0, v1, v2, v3, n: INTEGER;
      end, step: INTEGER;
      src, dst, spill: SET;
      m0, m1, m2, m3: SET;
  BEGIN
    ASSERT((w >= 0) & (h >= 0));
    ASSERT((sx >= 0) & (sx+w < Width));
    ASSERT((sy >= 0) & (sy+h < Height));
    ASSERT((dx >= 0) & (dx+w < Width));
    ASSERT((dy >= 0) & (dy+h < Height));
    
    u0 := sx DIV NofPixperWord; u1 := sx MOD NofPixperWord; u2 := (sx+w) DIV NofPixperWord; u3 := (sx+w) MOD NofPixperWord;
    v0 := dx DIV NofPixperWord; v1 := dx MOD NofPixperWord; v2 := (dx+w) DIV NofPixperWord; v3 := (dx+w) MOD NofPixperWord;
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
          SYSTEM.PUT(sa0+len+d, (dst * m2) + (src - m2));
          spill := src - m1;
          FOR sa1 := sa0 + len-4 TO sa0+4  BY -4 DO
            SYSTEM.GET(sa1, src); src := ROR(src, n*NofBPP);
            SYSTEM.PUT(sa1+d, spill + (src * m1));
            spill := src - m1
          END ;
          SYSTEM.GET(sa0, src); src := ROR(src, n*NofBPP);
          SYSTEM.GET(sa0+d, dst);
          SYSTEM.PUT(sa0+d, (src * m0) + (dst - m0))
        ELSE SYSTEM.GET(sa0, src); src := ROR(src, n*NofBPP);
          SYSTEM.GET(sa0+d, dst);
          SYSTEM.PUT(sa0+d, (src * m3) + (dst - m3))
        END
      ELSE (*shift left*) m1 := {-n*NofBPP .. 31};
        SYSTEM.GET(sa0, src); src := ROR(src, 32-n*NofBPP);
        SYSTEM.GET(sa0+d, dst);
        IF v1 + w < NofPixperWord THEN
          SYSTEM.PUT(sa0+d, (dst - m3) + (src * m3))
        ELSE SYSTEM.PUT(sa0+d, (dst - m0) + (src * m0));
          spill := src - m1;
          FOR sa1 := sa0+4 TO sa0 + len BY 4 DO
            SYSTEM.GET(sa1, src); src := ROR(src, 32-n*NofBPP);
            SYSTEM.PUT(sa1+d, spill + (src * m1));
            spill := src - m1
          END ;
          IF len+v1 > w THEN
            SYSTEM.GET(sa0+len+d, dst);
            SYSTEM.PUT(sa0+len+d, (spill - m2) + (dst * m2))
          END
        END
      END ;
      INC(sa0, step)
    END
  END CopyBlock;
(******TODO j'en suis la*******)

  PROCEDURE ReplPattern*(col, patadr, x, y, w, h, mode: INTEGER);
  (* pattern width = 32, fixed; pattern starts at patadr+4, for mode = invert only *)
    VAR al, ar, a0, a1, i: INTEGER;
      pta0, pta1: INTEGER;  (*pattern addresses*)
      ph: BYTE;
      left, right, mid, pix, pixl, pixr, ptw: SET;
  BEGIN al := Base + y*Span; SYSTEM.GET(patadr+1, ph);
    pta0 := patadr+4; pta1 := ph*4 + pta0;
    ar := ((x+w-1) DIV NofPixperWord)*4 + al; al := (x DIV NofPixperWord)*4 + al;
    IF ar = al THEN
      mid := {(x MOD NofPixperWord) .. ((x+w-1) MOD NofPixperWord)};
      a1 := al;
      FOR i := 1 TO h DO
        SYSTEM.GET(a1, pix); SYSTEM.GET(pta0, ptw); SYSTEM.PUT(a1, (pix - mid) + (pix/ptw * mid)); INC(pta0, 4);
        IF pta0 = pta1 THEN pta0 := patadr+4 END;
        INC(a1, Span);
      END
    ELSIF ar > al THEN
      left := {(x MOD NofPixperWord) .. 31}; right := {0 .. ((x+w-1) MOD NofPixperWord)};
      a0 := al;
      FOR i := 1 TO h DO
        SYSTEM.GET(a0, pixl); SYSTEM.GET(pta0, ptw); SYSTEM.PUT(a0, (pixl - left) + (pixl/ptw * left));
        FOR a1 := a0+4 TO ar-4 BY 4 DO SYSTEM.GET(a1, pix); SYSTEM.PUT(a1, pix/ptw) END ;
        SYSTEM.GET(ar, pixr); SYSTEM.PUT(ar, (pixr - right) + (pixr/ptw * right));
        INC(pta0, 4); INC(ar, Span);
        IF pta0 = pta1 THEN pta0 := patadr+4 END;
        INC(a0, Span)
      END
    END
  END ReplPattern;

  PROCEDURE test1;
    VAR x, y: INTEGER;
  BEGIN
    CopyPattern(white, arrow, 0, 0, paint);
    CopyPattern(white, arrow, 1, 20, paint);
    CopyPattern(white, arrow, 2, 40, paint);
    CopyPattern(white, arrow, 3, 60, paint)
  END test1;
  
  PROCEDURE test2;
    VAR x, y: INTEGER;
  BEGIN
    FOR y := 0 TO Height-1 - 15 DO
      FOR x := 0 TO Width-1 - 15 DO     
        CopyPattern(white, arrow, x, y, invert);
        CopyPattern(white, arrow, x, y, invert)
      END
    END
  END test2;
  
  PROCEDURE test3;
    VAR x, y: INTEGER;
  BEGIN
    Dot(white, 0, 0, paint);
    Dot(white, 1, 20, paint);
    Dot(white, 2, 40, paint);
    Dot(white, 3, 60, paint)
  END test3;
  
  PROCEDURE test4;
    VAR x, y: INTEGER;
  BEGIN
    ReplConst(white, 100, 100, 200, 200, invert);
    ReplConst(white, 350, 350, 200, 200, invert);
    ReplConst(white, 2, 400, 1, 20, paint);
  END test4;
  
  PROCEDURE test5;
    VAR x, y: INTEGER;
  BEGIN
    CopyBlock(400, 400, 100, 200, 600, 550, replace);
    CopyBlock(0, 0, 18, 75, 19, 76, replace);
    CopyBlock(19, 76, 18, 75, 37, 151, replace);
  END test5;
  
BEGIN 
  arrow := SYSTEM.ADR($ 0F00 0F00
     00 00 00 00 00 00 00 00 00 00 00 00 00 FF FF 00
     00 00 00 00 00 00 00 00 00 00 00 00 FF FF FF 00
     00 00 00 00 00 00 00 00 00 00 00 FF FF FF 00 00
     00 00 00 00 00 00 00 00 00 00 FF FF FF 00 00 00
     00 00 00 00 00 00 00 00 00 FF FF FF 00 00 00 00
     00 00 00 00 00 00 00 00 FF FF FF 00 00 00 00 00
     00 00 00 00 00 00 00 FF FF FF 00 00 00 00 00 00
     FF 00 00 00 00 00 FF FF FF 00 00 00 00 00 00 00
     FF FF 00 00 00 FF FF FF 00 00 00 00 00 00 00 00
     FF FF FF 00 FF FF FF 00 00 00 00 00 00 00 00 00
     FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00
     FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00
     FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00 00
     FF FF FF FF FF FF FF 00 00 00 00 00 00 00 00 00
     FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00 00$);
  (*Pour test uniquement*)
  test1; test3; test4; test5;
(*TODO: à reprendre pour passer de 1 bpp à 8 bpp*)
  star := SYSTEM.ADR($0F0F 8000 8220 8410 8808 9004 A002 C001 7F7F C001 A002 9004 8808 8410 8220 8000$);
  hook := SYSTEM.ADR($0C0C 070F 8707 C703 E701 F700 7F00 3F00 1F00 0F00 0700 0300 01$);
  updown := SYSTEM.ADR($080E 183C 7EFF 1818 1818 1818 FF7E3C18$);
  block := SYSTEM.ADR($0808 FFFF C3C3 C3C3 FFFF$);
  cross := SYSTEM.ADR($0F0F 0140 0220 0410 0808 1004 2002 4001 0000 4001 2002 1004 0808 0410 0220 0140$);
  grey := SYSTEM.ADR($2002 0000 5555 5555 AAAA AAAA$)
END Display.
