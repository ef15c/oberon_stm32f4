MODULE SystemLog;
  IMPORT Texts, TE := TextsEx2, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE DebugHex*(msg: ARRAY OF CHAR; v: INTEGER);
  BEGIN
   Texts.WriteString(W, msg); Texts.WriteString(W, " = "); Texts.WriteHex(W, v);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugHex;

  PROCEDURE DebugInt*(msg: ARRAY OF CHAR; v, l: INTEGER);
  BEGIN
   Texts.WriteString(W, msg); Texts.WriteString(W, " = "); Texts.WriteInt(W, v, l);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugInt;

  PROCEDURE DebugLongInt*(msg: ARRAY OF CHAR; v: LONGINT; l: INTEGER);
  BEGIN
   Texts.WriteString(W, msg); Texts.WriteString(W, " = "); TE.WriteLongInt(W, v, l);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugLongInt;

BEGIN Texts.OpenWriter(W)
END SystemLog.
