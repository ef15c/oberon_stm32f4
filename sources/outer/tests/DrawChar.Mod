MODULE DrawChar;

  IMPORT SYSTEM, Display, Fonts, Texts, Oberon;
  
  VAR W: Texts.Writer;
  
  PROCEDURE Draw*;
    VAR dx, x, y, w, h, patadr: INTEGER;
  BEGIN
    Fonts.GetPat(Fonts.Default, "a", dx, x, y, w, h, patadr);
    Display.CopyPattern(Display.white, patadr, 100, 100, Display.paint)
  END Draw;

  PROCEDURE Show*;
    VAR w, h, pbt: BYTE;
      dx, x, y, w1, h1, patadr: INTEGER;
      r, c, line: INTEGER;
      pix: SET;
  BEGIN
    Fonts.GetPat(Fonts.Default, "a", dx, x, y, w1, h1, patadr);
    Texts.WriteString(W, "w1="); Texts.WriteInt(W, w1, 1);
    Texts.WriteString(W, ", h1="); Texts.WriteInt(W, h1, 1); Texts.WriteLn(W);
    SYSTEM.GET(patadr, w); SYSTEM.GET(patadr+1, h); INC(patadr, 2);
    Texts.WriteString(W, "w="); Texts.WriteInt(W, w, 1);
    Texts.WriteString(W, ", h="); Texts.WriteInt(W, h, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf);
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

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Show patterns 23/12/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END DrawChar.
