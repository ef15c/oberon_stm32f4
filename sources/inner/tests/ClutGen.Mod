MODULE ClutGen;
  IMPORT Texts, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE generate*;
    VAR i, luv: INTEGER;
      r, g, b: BYTE;
  BEGIN FOR i := 0 TO 255 DO r := LSR(i, 5) MOD 8; g := LSR(i, 2) MOD 8; b := i MOD 4;
      luv := LSL(i, 24) + LSL(r*255 DIV 7, 16) + LSL(g*255 DIV 7, 8) + b*255 DIV 3;
      IF i MOD 8 = 0 THEN Texts.WriteLn(W) END;
      Texts.WriteHex(W, luv)
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END generate;

BEGIN Texts.OpenWriter(W);
  Texts.WriteString(W, "CLUT table generator"); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf)
END ClutGen.
