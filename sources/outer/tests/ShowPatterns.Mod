MODULE ShowPatterns;

(*Pattern is a sequence of bytes
  pattern = width height line {line}

  example
  Display.arrow = 0F0F 0060 0070 0038 001C 000E 0007 8003 C101 E300 7700 3F00 1F00 3F00 7F00 FF00
  width = 15
  height = 15
  
  line = 6000H '             ** '
  line = 7000H '            *** '
  line = 3800H '           ***  '
  line = 1C00H '          ***   '
  line = 0E00H '         ***    '
  line = 0700H '        ***     '
  line = 0380H '       ***      '
  line = 01C1H '*     ***       '
  line = 00E3H '**   ***        '
  line = 0077H '*** ***         '
  line = 003FH '******          '
  line = 001FH '*****           '
  line = 003FH '******          '
  line = 007FH '*******         '
  line = 00FFH '********        '

*)

  IMPORT SYSTEM, Display, Fonts, Texts, Oberon, TextsEx, GraphicFrames;

  CONST Span = (Display.Width*8 DIV Display.NofBPP+63) DIV 64*64;

  VAR W: Texts.Writer;
  
  PROCEDURE Show*;
    VAR w, h, pbt: BYTE;
      patadr, r, c, line: INTEGER;
      pix: SET;
  BEGIN
    patadr := GraphicFrames.tack;
    SYSTEM.GET(patadr, w); SYSTEM.GET(patadr+1, h); INC(patadr, 2);
    Texts.WriteString(W, "w="); Texts.WriteInt(W, w, 1);
    Texts.WriteString(W, ", h="); Texts.WriteInt(W, h, 1); Texts.WriteLn(W);
    FOR r := 1 TO h DO
      (*build pattern line; w <= 32*)
      SYSTEM.GET(patadr, pbt); INC(patadr); line := pbt;
      IF w > 8 THEN SYSTEM.GET(patadr, pbt); INC(patadr); line := pbt*100H + line;
        IF w > 16 THEN SYSTEM.GET(patadr, pbt); INC(patadr); line := pbt*10000H + line;
          IF w > 24 THEN SYSTEM.GET(patadr, pbt); INC(patadr); line := pbt*1000000H + line END
        END
      END ;
      pix := SYSTEM.VAL(SET, line);
      FOR c := 0 TO w-1 DO
        IF c IN pix THEN Texts.Write(W, "*") ELSE Texts.Write(W, " ") END
      END;
      Texts.WriteLn(W)
    END;
    
    Texts.Append(Oberon.Log, W.buf)
  END Show;

  PROCEDURE Convert*(patadr: LONGINT; name: ARRAY OF CHAR; special: BOOLEAN);
    VAR w, h, pbt: BYTE;
      r, c, line: INTEGER;
      pix: SET;
  BEGIN
    Texts.WriteString(W, "  "); Texts.WriteString(W, name);
    Texts.WriteString(W, " := SYSTEM.ADR($");
    SYSTEM.GET(patadr, w); SYSTEM.GET(patadr+1, h); INC(patadr, 2);
    IF special THEN
      TextsEx.WriteHexVLen(W, w, 2, FALSE); TextsEx.WriteHexVLen(W, h, 2, FALSE);
      Texts.WriteString(W, " 0000"); Texts.WriteLn(W); INC(patadr, 2)
     ELSE
      TextsEx.WriteHexVLen(W, w, 2, FALSE); Texts.WriteString(W, "00 "); 
  
    TextsEx.WriteHexVLen(W, h, 2, FALSE); Texts.WriteString(W, "00 "); Texts.WriteLn(W)
    END;
    Texts.WriteString(W, "    "); 
    FOR r := 1 TO h DO
      (*build pattern line; w <= 32*)
      SYSTEM.GET(patadr, pbt); INC(patadr); line := pbt;
      IF w > 8 THEN SYSTEM.GET(patadr, pbt); INC(patadr); line := pbt*100H + line;
        IF w > 16 THEN SYSTEM.GET(patadr, pbt); INC(patadr); line := pbt*10000H + line;
          IF w > 24 THEN SYSTEM.GET(patadr, pbt); INC(patadr); line := pbt*1000000H + line END
        END
      END ;
      c := 0;
      WHILE c <= w-1 DO
        IF ODD(line) THEN TextsEx.WriteHexVLen(W, 0FFH, 2, FALSE)
        ELSE TextsEx.WriteHexVLen(W, 0, 2, FALSE)
        END; line := line DIV 2; INC(c)
      END;
      WHILE c MOD 4 # 0 DO TextsEx.WriteHexVLen(W, 0, 2, FALSE); INC(c) END;
      IF r # h THEN Texts.WriteLn(W); Texts.WriteString(W, "    ") END
    END;
    Texts.WriteString(W, "$);"); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END Convert;

  PROCEDURE ConvertAll*;
    VAR pat: INTEGER;
  BEGIN (* Convert(Display.arrow, "arrow");
    Convert(Display.star, "star");
    Convert(Display.hook, "hook");
    Convert(Display.updown, "updown");
    Convert(Display.block, "block");
    Convert(Display.cross, "cross");
    Convert(Display.grey, "grey")*)
    Convert(GraphicFrames.tack, "tack", FALSE);
    pat := SYSTEM.ADR($2004 0000 1111 1111 0000 0000 0000 0000 0000 0000$);
    Convert(pat, "dotted
", TRUE);
    pat := SYSTEM.ADR($2004 0000 1111 1111 0000 0000 4444 4444 0000 0000$);
    Convert(pat, "dotted
1", TRUE);
  END ConvertAll;

  PROCEDURE ReplPattern*(col, patadr, x, y, w, h, mode: INTEGER);
  (* pattern width = 4, fixed; pattern starts at patadr+4, for mode = invert only *)
    VAR al, ar, a0, a1, i: INTEGER;
      pta0, pta1: INTEGER;  (*pattern addresses*)
      ph: BYTE;
      left, right, mid, pix, pixl, pixr, ptw: SET;
  BEGIN al := Display.Base + (Display.Height-1-y)*Span; SYSTEM.GET(patadr+1, ph);
    pta0 := patadr+4; pta1 := ph*4 + pta0;
    ar := ((x+w-1) DIV Display.NofPixperWord)*4 + al; al := (x DIV Display.NofPixperWord)*4 + al;
    IF ar = al THEN
      mid := {x MOD Display.NofPixperWord*Display.NofBPP .. (x+w-1) MOD Display.NofPixperWord*Display.NofBPP+Display.NofBPP-1};
      a1 := al;
      FOR i := 1 TO h DO
        SYSTEM.GET(a1, pix); SYSTEM.GET(pta0, ptw); SYSTEM.PUT(a1, (pix - mid) + (pix/ptw * mid)); INC(pta0, 4);
        IF pta0 = pta1 THEN pta0 := patadr+4 END;
        DEC(a1, Span);
      END
    ELSIF ar > al THEN
      left := {x MOD Display.NofPixperWord*Display.NofBPP .. 31}; right := {0 .. (x+w-1) MOD Display.NofPixperWord*Display.NofBPP+Display.NofBPP-1};
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

  PROCEDURE dotted*;
  BEGIN
    (*Display.ReplPattern(Display.white, GraphicFrames.dotted, 100, 100, 1, 30, Display.invert);
    Display.ReplPattern(Display.white, GraphicFrames.dotted, 101, 100, 50, 1, Display.invert);
    Display.ReplPattern(Display.white, GraphicFrames.dotted, 200, 100, 50, 30, Display.invert);

    Display.ReplPattern(Display.white, GraphicFrames.dotted1, 100, 200, 1, 30, Display.invert);
    Display.ReplPattern(Display.white, GraphicFrames.dotted1, 101, 200, 50, 1, Display.invert);
    Display.ReplPattern(Display.white, GraphicFrames.dotted1, 200, 200, 50, 30, Display.invert);

    Display.ReplPattern(255, -803172648, 336, 384, 160, 1, 0);*)
    Display.ReplPattern(255, -803172648, 200, 200, 50, 30, 0);
  END dotted;

  PROCEDURE Elektra*;
    VAR fnt!: Fonts.Font;
      i, dx, x, y, w, h, patadr, paMax: INTEGER;
  BEGIN
    Fonts.GetPat(Fonts.Default, 0X, dx, x, y, w, h, patadr);
    Texts.WriteString(W, "Adresse Default: "); Texts.WriteHex(W, patadr);
    paMax := patadr;
    FOR i := 1 TO 127 DO Fonts.GetPat(Fonts.Default, CHR(i), dx, x, y, w, h, patadr);
      IF patadr > paMax THEN paMax := patadr END
    END;
    Texts.WriteString(W, " .. "); Texts.WriteHex(W, paMax); 
    Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf);
 
    fnt := Fonts.This("Elektra.Scn.Fnt");
    IF fnt # NIL THEN
      Fonts.GetPat(fnt, 0X, dx, x, y, w, h, patadr);
      Texts.WriteString(W, "Adresse Elektra: "); Texts.WriteHex(W, patadr);
      paMax := patadr;
      FOR i := 1 TO 127 DO Fonts.GetPat(fnt, CHR(i), dx, x, y, w, h, patadr);
        IF patadr > paMax THEN paMax := patadr END
      END;
      Texts.WriteString(W, " .. "); Texts.WriteHex(W, paMax); 
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf)
    END
  END Elektra;


BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Show patterns 23/12/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END ShowPatterns.
