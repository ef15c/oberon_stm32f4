MODULE testScan;
  IMPORT Texts, TextsEx := TextsEx2, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE scan*;
    VAR S!: TextsEx.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    TextsEx.Scan(S);
    IF S.class = Texts.Real THEN Texts.WriteString(W, "Real class: S.x="); Texts.WriteReal(W, S.x, 11)
    ELSIF S.class = Texts.Int THEN Texts.WriteString(W, "Integer class: S.i="); Texts.WriteInt(W, S.i, 1)
    ELSIF S.class = TextsEx.LongInt THEN Texts.WriteString(W, "Long integer class: S.l="); TextsEx.WriteLongInt(W, S.l, 1)
    ELSE Texts.WriteString(W, "other class: "); Texts.WriteInt(W, S.class, 1)
    END; Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END scan;

BEGIN Texts.OpenWriter(W)
END testScan.

OM4P2.Compile testScan.Mod ~ System.Free testScan testRWNum TextsEx2 ~
testScan.scan -1000L ~
testScan.scan 1000000000000
testScan.scan 100000000H
testScan.scan 80000000H
testScan.scan 2147483648
testScan.scan 2147483647
