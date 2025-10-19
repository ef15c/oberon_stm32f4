MODULE testDMA;
  IMPORT SYSTEM, DMA, Texts, Oberon;

  TYPE String = ARRAY 512*1048 OF CHAR;
  VAR W: Texts.Writer;
    s1, s2: String;

  PROCEDURE print*;
  BEGIN
    Texts.WriteString(W, s1); Texts.WriteLn(W);
    Texts.WriteString(W, s2); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END print;

  PROCEDURE test*;
  BEGIN s1 := "Sylvie"; s2 := "---"; print;
    DMA.Copy(SYSTEM.ADR(s1), SYSTEM.ADR(s2), SYSTEM.SIZE(String) DIV 4, 4); print;
    Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END test;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test DMA  C. Schoffit 17.10.25");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END testDMA.

OM4P.Compile DMA.Mod/s testDMA.Mod/s~
System.Free testDMA DMA~

testDMA.print testDMA.test
