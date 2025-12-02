MODULE LongInt;
  IMPORT SYSTEM, LongDiv, Texts,  Oberon;

  TYPE DivParam = RECORD  D, S: LONGINT END;

  VAR W: Texts.Writer;

  PROCEDURE WriteL(l: LONGINT);
    VAR low: INTEGER;
  BEGIN low := l; l := LSR(l, 32);
    Texts.WriteHex(W, l); Texts.WriteHex(W, low); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END WriteL;

  PROCEDURE Write(h, l: INTEGER);
    VAR low: INTEGER;
  BEGIN Texts.WriteHex(W, h); Texts.WriteHex(W, l); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END Write;

  PROCEDURE run*;
    VAR l: LongDiv.DivParam; t: LONGINT;
  BEGIN l.D := 12345678901234567; l.S := 10;
    LongDiv.DivL(l);
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, l.D, 1); Texts.WriteLn(W);
    Texts.WriteInt(W, l.S, 1); Texts.WriteLn(W);

    l.D := 12345678901234567; l.S := 10;
    t := l.D MOD l.S;
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, t, 1); Texts.WriteLn(W);
    t := l.D DIV l.S;
    Texts.WriteInt(W, t, 1); Texts.WriteLn(W);
 
    l.D := 12345678901234567; l.S := 10;
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, l.D MOD l.S, 1); Texts.WriteLn(W);
    Texts.WriteInt(W, l.D DIV l.S, 1); Texts.WriteLn(W);

    Texts.WriteInt(W, LSL(1L, 63), 1); Texts.WriteLn(W);

    Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W)
END LongInt.

OM4P.Compile LongInt.Mod/s ~ System.Free LongInt testLongInt ~ LongInt.run

OM4Tool.DecObj LongInt.m4c
