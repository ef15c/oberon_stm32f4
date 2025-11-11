MODULE testPS2;
  IMPORT SYSTEM, PS2, Texts, Oberon, TextsEx;

  VAR leds: BYTE; keyboard: PS2.Device;

    W: Texts.Writer;

(*
  PROCEDURE show*(dev: PS2.DeviceDesc);
    VAR lb: BYTE;
      idx: INTEGER;
  BEGIN
    IF dev.dest # NIL THEN
      Texts.WriteString(W, "head "); Texts.WriteInt(W, dev.dest.head, 1);
      Texts.WriteString(W, ", tail "); Texts.WriteInt(W, dev.dest.tail, 1);
      idx := dev.dest.head; DEC(idx); IF idx < 0 THEN idx := 15 END;
      Texts.WriteString(W, ", last byte read "); TextsEx.WriteHexVLen(W, dev.dest.buffer[idx], 1, FALSE);
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf)
    END;

    Texts.WriteString(W, "direction "); TextsEx.WriteHexVLen(W, dev.direction, 1, FALSE);
    Texts.WriteString(W, ", statusIn "); TextsEx.WriteHexVLen(W, dev.statusIn, 1, FALSE);
    Texts.WriteString(W, ", statusOut "); TextsEx.WriteHexVLen(W, dev.statusOut, 1, FALSE);
    Texts.WriteString(W, ", nofBitsToBeRead "); Texts.WriteInt(W, dev.nofBitsToBeRead, 1);
    Texts.WriteLn(W);
    SYSTEM.GET(dev.clock_Out, idx); Texts.WriteString(W, "clock out "); Texts.WriteInt(W, idx, 1);
    SYSTEM.GET(dev.data_Out, idx); Texts.WriteString(W, ", data out "); Texts.WriteInt(W, idx, 1);
    SYSTEM.GET(dev.clock_In, idx); Texts.WriteString(W, ", clock in "); Texts.WriteInt(W, idx, 1);
    SYSTEM.GET(dev.data_In, idx); Texts.WriteString(W, ", data in "); Texts.WriteInt(W, idx, 1);
    Texts.WriteLn(W);
    Texts.WriteString(W, "bad edges "); Texts.WriteInt(W, dev.badEdge,1);
    Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf);
  END show;

  PROCEDURE showKB*;
    (*VAR dev!: PS2.DeviceDesc;*)
  BEGIN show(keyboard^)
  END showKB;

  PROCEDURE showMouse*;
  BEGIN show(Oberon.ps2[1])
  END showMouse;
*)

  PROCEDURE nextKBLeds*;
    VAR rc: BYTE;
  BEGIN INC(leds); leds := leds MOD 8;
    Texts.WriteString(W, "leds "); Texts.WriteInt(W, leds,1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
    PS2.SendByteAsync(keyboard^, 0EDH);
    rc := PS2.WaitForAnswer(keyboard^, 35);
    IF rc = 0FAH THEN
      PS2.SendByteAsync(keyboard^, leds);
      rc := PS2.WaitForAnswer(keyboard^, 35)
    END
  END nextKBLeds;

  PROCEDURE resetKB*;
    VAR rc: BYTE;
  BEGIN PS2.SendByteAsync(keyboard^, 0FFH)
  END resetKB;

  PROCEDURE CommandKB*;
    VAR S!: Texts.Scanner; rc: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    rc := 0FAH;
    WHILE (S.class = Texts.Int) & (rc = 0FAH) DO PS2.SendByteAsync(keyboard^, S.i);
      rc := PS2.WaitForAnswer(keyboard^, 35); Texts.Scan(S)
    END
  END CommandKB;

  PROCEDURE CapsLockLedOn*;
  BEGIN PS2.SetCapsLock(TRUE);
  END CapsLockLedOn;

  PROCEDURE CapsLockLedOff*;
  BEGIN PS2.SetCapsLock(FALSE);
  END CapsLockLedOff;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test PS/2 driver CS 21.03.24"); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf); keyboard := PS2.keyboard
END testPS2.

OM4P.Compile testPS2.Mod~
System.Free testPS2~
OM4Tool.DecObj testPS2.m4c

testPS2
testPS2.showKB
testPS2.showMouse
testPS2.nextKBLeds
testPS2.resetKB
testPS2.CommandKB 0F4H
testPS2.CommandKB 0F5H
testPS2.CapsLockLedOn
testPS2.CapsLockLedOff
