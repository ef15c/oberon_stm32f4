(*bug present in Project Oberon 2013:
  error in code of access to exported string constant*)
MODULE testString;
  CONST st* = "salut";
END testString.

MODULE testImportString;
  IMPORT Texts, Oberon, testString;

  VAR W: Texts.Writer;

  PROCEDURE run*;
  BEGIN Texts.WriteString(W, "---"); Texts.WriteString(W, testString.st); Texts.WriteString(W, "+++");
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "testImportString 04.08.24"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END testImportString.
