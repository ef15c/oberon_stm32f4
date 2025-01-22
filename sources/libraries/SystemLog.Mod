MODULE SystemLog;
  IMPORT Texts, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE DebugHex*(msg: ARRAY OF CHAR; v: INTEGER);
  BEGIN
   Texts.WriteString(W, msg); Texts.WriteString(W, " = "); Texts.WriteHex(W, v);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugHex;

BEGIN Texts.OpenWriter(W)
END SystemLog.
