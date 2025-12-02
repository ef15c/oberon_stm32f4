MODULE testScan;
  IMPORT Texts, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE scan*;
    VAR S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    IF S.class = Texts.Real THEN Texts.WriteString(W, "Real class: S.x="); Texts.WriteReal(W, S.x, 11)
    ELSIF S.class = Texts.Int THEN Texts.WriteString(W, "Integer class: S.i="); Texts.WriteInt(W, S.i, 1)
    ELSE Texts.WriteString(W, "other class: "); Texts.WriteInt(W, S.class, 1)
    END; Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END scan;

BEGIN Texts.OpenWriter(W)
END testScan.

OM4P.Compile testScan.Mod ~ System.Free testScan testRWNum ~
testScan.scan -1000L ~
testScan.scan 1000000000000
testScan.scan 100000000H
testScan.scan 80000000H
testScan.scan 2147483648
testScan.scan 2147483647
testScan.scan 3.14159E2
