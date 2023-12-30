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

  IMPORT SYSTEM, Display, Texts, Oberon, OM4D;

  VAR W: Texts.Writer;
  
  PROCEDURE Show*;
    VAR w, h, pbt: BYTE;
      patadr, r, c, line: INTEGER;
      pix: SET;
  BEGIN
    patadr := Display.arrow;
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

  PROCEDURE Convert*(patadr: LONGINT; name: ARRAY OF CHAR);
    VAR w, h, pbt: BYTE;
      r, c, line: INTEGER;
      pix: SET;
  BEGIN
    Texts.WriteString(W, "  "); Texts.WriteString(W, name);
    Texts.WriteString(W, " := SYSTEM.ADR($");
    SYSTEM.GET(patadr, w); SYSTEM.GET(patadr+1, h); INC(patadr, 2);
    OM4D.WriteHexVLen(W, w, 2, FALSE); Texts.WriteString(W, "00 "); 
    OM4D.WriteHexVLen(W, h, 2, FALSE); Texts.WriteString(W, "00 "); Texts.WriteLn(W);
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
        IF ODD(line) THEN OM4D.WriteHexVLen(W, 0FFH, 2, FALSE)
        ELSE OM4D.WriteHexVLen(W, 0, 2, FALSE)
        END; line := line DIV 2; INC(c)
      END;
      WHILE c MOD 4 # 0 DO OM4D.WriteHexVLen(W, 0, 2, FALSE); INC(c) END;
      IF r # h THEN Texts.WriteLn(W); Texts.WriteString(W, "    ") END
    END;
    Texts.WriteString(W, "$);"); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END Convert;

  PROCEDURE ConvertAll*;
  BEGIN Convert(Display.arrow, "arrow");
    Convert(Display.star, "star");
    Convert(Display.hook, "hook");
    Convert(Display.updown, "updown");
    Convert(Display.block, "block");
    Convert(Display.cross, "cross");
    Convert(Display.grey, "grey")
  END ConvertAll;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Show patterns 23/12/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END ShowPatterns.
