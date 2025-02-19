MODULE testFLASH;
  IMPORT SYSTEM, Texts, Oberon, FLASH;

  VAR W: Texts.Writer;

  PROCEDURE test*;
    VAR buf: ARRAY 10 OF INTEGER;
      i: INTEGER;
  BEGIN FLASH.Open;
    FOR i := 0 TO LEN(buf) - 1 DO buf[i] := i + 1 END;
    FLASH.Write(08000010H, buf, LEN(buf));
    FLASH.Close
  END test;

BEGIN Texts.OpenWriter(W);
  Texts.WriteString(W, "@FLASH.buffer = "); Texts.WriteHex(W, SYSTEM.ADR(FLASH.buffer));
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END  testFLASH.

OM4P.Compile testFLASH.Mod ~
System.Free testFLASH FLASH ~
testFLASH.test

