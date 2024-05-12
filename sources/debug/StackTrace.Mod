MODULE StackTrace;
  IMPORT Texts, Oberon, System;

  VAR W: Texts.Writer;

  PROCEDURE showDump*;
  BEGIN 
   Texts.WriteString(W, "cause: "); Texts.WriteInt(W, System.stack.cause, 1); Texts.WriteLn(W);
   Texts.WriteString(W, "PC : "); Texts.WriteHex(W, System.stack.PC); Texts.WriteLn(W);
   Texts.WriteString(W, "LR : "); Texts.WriteHex(W, System.stack.LR); Texts.WriteLn(W);
   Texts.WriteString(W, "stack size: "); Texts.WriteInt(W, System.stack.len, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END showDump;

BEGIN Texts.OpenWriter(W)
END StackTrace.
