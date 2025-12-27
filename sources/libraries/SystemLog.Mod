MODULE SystemLog;
  IMPORT Texts, Oberon, Math;

  VAR W: Texts.Writer;

  PROCEDURE DebugHex*(msg: ARRAY OF CHAR; v: INTEGER);
  BEGIN
   Texts.WriteString(W, msg); Texts.WriteString(W, " = "); Texts.WriteHex(W, v);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugHex;

  PROCEDURE DebugInt*(msg: ARRAY OF CHAR; v: LONGINT; l: INTEGER);
  BEGIN
   Texts.WriteString(W, msg); Texts.WriteString(W, " = "); Texts.WriteInt(W, v, l);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugInt;

  PROCEDURE DebugString*(msg, v: ARRAY OF CHAR);
  BEGIN
   Texts.WriteString(W, msg); Texts.WriteString(W, " = "); Texts.WriteString(W, v);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugString;

  PROCEDURE DebugChar*(msg: ARRAY OF CHAR; v: CHAR);
  BEGIN
   Texts.WriteString(W, msg); Texts.WriteString(W, " = "); Texts.Write(W, v);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugChar;

  PROCEDURE DebugRat*(msg: ARRAY OF CHAR; v: Math.RATIONAL; l: INTEGER);
    VAR s: ARRAY 32 OF CHAR;
  BEGIN
    Math.RtoS(s, v, l); DebugString(msg, s)
  END DebugRat;

  PROCEDURE DebugBool*(msg: ARRAY OF CHAR; b: BOOLEAN);
  BEGIN
    Texts.WriteString(W, msg); Texts.WriteString(W, " = ");
    IF b THEN Texts.WriteString(W, "TRUE") ELSE Texts.WriteString(W, "FALSE") END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END DebugBool;

BEGIN Texts.OpenWriter(W)
END SystemLog.
