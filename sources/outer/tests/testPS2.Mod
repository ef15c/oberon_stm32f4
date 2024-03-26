MODULE testPS2;
  IMPORT SYSTEM, PS2, Texts, Oberon, TextsEx;

  VAR leds: BYTE;

    W: Texts.Writer;

  PROCEDURE show*(dev: PS2.DeviceDesc);
    VAR lb: BYTE;
      idx: INTEGER;
  BEGIN
    IF dev.dest # NIL THEN
      Texts.WriteString(W, "head "); Texts.WriteInt(W, dev.dest.head, 1);
      Texts.WriteString(W, ", tail "); Texts.WriteInt(W, dev.dest.tail, 1);
      idx := dev.dest.head; DEC(idx); IF idx < 0 THEN idx := 15 END;
      Texts.WriteString(W, ", last byte read "); TextsEx.WriteHexVLen(W, dev.dest.buffer[idx], 1, FALSE);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END;

    Texts.WriteString(W, "statusIn "); Texts.WriteInt(W, dev.statusIn,1);
    Texts.WriteString(W, ", statusOut "); Texts.WriteInt(W, dev.statusOut,1);
    Texts.WriteString(W, ", bad edges "); Texts.WriteInt(W, dev.badEdge,1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
  END show;

  PROCEDURE showKB*;
    VAR dev!: PS2.DeviceDesc;
  BEGIN (*Workaround of a compiler bug wihch computes wrongly the address of Oberon.ps2[1] *)
    SYSTEM.COPY(SYSTEM.ADR(Oberon.ps2) + SYSTEM.SIZE(PS2.DeviceDesc), SYSTEM.ADR(dev), SYSTEM.SIZE(PS2.DeviceDesc) DIV 4);
    show(dev)
  END showKB;

  PROCEDURE showMouse*;
  BEGIN show(Oberon.ps2[0])
  END showMouse;

  PROCEDURE nextKBLeds*;
    VAR rc: BYTE;
  BEGIN INC(leds); leds := leds MOD 8;
    Texts.WriteString(W, "leds "); Texts.WriteInt(W, leds,1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
    Oberon.SendByteAsync(1, 0EDH);
    rc := Oberon.WaitForAnswer(1, 35);
    IF rc = 0FAH THEN
      Oberon.SendByteAsync(1, leds);
      rc := Oberon.WaitForAnswer(1, 35)
    END
  END nextKBLeds;

  PROCEDURE resetKB*;
    VAR rc: BYTE;
  BEGIN
    Oberon.SendByteAsync(1, 0FFH)
  END resetKB;

  PROCEDURE Command*;
    VAR S!: Texts.Scanner;
      idx, rc: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Int) & (S.i >= 0) & (S.i < 2) THEN
      idx := S.i; Texts.Scan(S); rc := 0FAH;
      WHILE (S.class = Texts.Int) & (rc = 0FAH) DO Oberon.SendByteAsync(idx, S.i);
        rc := Oberon.WaitForAnswer(idx, 35); Texts.Scan(S)
      END
    END
  END Command;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test PS/2 driver CS 21.03.24"); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf)
END testPS2.

OM4Tool.DecObj testPS2.m4c
