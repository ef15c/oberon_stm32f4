MODULE testPS2;
  IMPORT SYSTEM, BSP, Kernel, PS2, Texts, Oberon, TextsEx;

  CONST EXTI_PR = BSP.EXTI_BASE + BSP.EXTI_PR;

  VAR ps2: ARRAY 2 OF PS2.DeviceDesc;
    OldPS2IrqHandler: ARRAY 2 OF PROCEDURE;
    leds: BYTE;

    W: Texts.Writer;

  PROCEDURE^3 ps2_1IrqHandler;
    VAR pr: SET;
  BEGIN SYSTEM.GET(EXTI_PR, pr);
    IF ps2[0].clockPin IN pr THEN
      pr := {ps2[0].clockPin}; SYSTEM.PUT(EXTI_PR, pr); (*clear pending IRQ*)
      PS2.ProcessData(ps2[0])
    END
  END ps2_1IrqHandler;

  PROCEDURE^3 ps2_2IrqHandler;
    VAR pr: SET;
  BEGIN
    SYSTEM.GET(EXTI_PR, pr);
    IF ps2[1].clockPin IN pr THEN
      pr := {ps2[1].clockPin}; SYSTEM.PUT(EXTI_PR, pr); (*clear pending IRQ*)
      PS2.ProcessData(ps2[1])
    END
  END ps2_2IrqHandler;

  PROCEDURE switchMouseDriver*;
  BEGIN
    IF OldPS2IrqHandler[0] = NIL THEN
      ps2[0].connectedDevice := PS2.MOUSE;
      ps2[0].clockPin := BSP.PS2CLOCK1Pin;
      ps2[0].clock_In := BSP.PS2CLOCK1In; ps2[0].clock_Out := BSP.PS2CLOCK1Out;
      ps2[0].data_In := BSP.PS2DATA1In; ps2[0].data_Out := BSP.PS2DATA1Out;
      ps2[0].keyboardLED := BSP.LD3Out; ps2[0].mouseLED := BSP.LD4Out;
      PS2.resetForTest(ps2[0]);

      SYSTEM.GET(BSP.VecTabBase + BSP.PS2CLOCK1ExtiIrqNum*4, OldPS2IrqHandler[0]); (*keep track of original driver*)
      Kernel.Install(SYSTEM.ADR(ps2_1IrqHandler), BSP.VecTabBase + BSP.PS2CLOCK1ExtiIrqNum*4)
    END;
  END switchMouseDriver;

  PROCEDURE switchKBDriver*;
  BEGIN
    IF OldPS2IrqHandler[1] = NIL THEN
      ps2[1].connectedDevice := PS2.KEYBOARD;
      ps2[1].clockPin := BSP.PS2CLOCK2Pin;
      ps2[1].clock_In := BSP.PS2CLOCK2In; ps2[1].clock_Out := BSP.PS2CLOCK2Out;
      ps2[1].data_In := BSP.PS2DATA2In; ps2[1].data_Out := BSP.PS2DATA2Out;
      ps2[1].keyboardLED := BSP.LD3Out; ps2[1].mouseLED := BSP.LD4Out;
      PS2.resetForTest(ps2[1]);

      SYSTEM.GET(BSP.VecTabBase + BSP.PS2CLOCK2ExtiIrqNum*4, OldPS2IrqHandler[1]); (*keep track of original driver*)
      Kernel.Install(SYSTEM.ADR(ps2_2IrqHandler), BSP.VecTabBase + BSP.PS2CLOCK2ExtiIrqNum*4)
    END
  END switchKBDriver;

  PROCEDURE restoreMouseDriver*;
  BEGIN IF OldPS2IrqHandler[0] # NIL THEN 
      Kernel.Install(SYSTEM.VAL(INTEGER, OldPS2IrqHandler[0]), BSP.VecTabBase + BSP.PS2CLOCK1ExtiIrqNum*4);
      OldPS2IrqHandler[0] := NIL
    END
  END restoreMouseDriver;

  PROCEDURE restoreKBDriver*;
  BEGIN IF OldPS2IrqHandler[1] # NIL THEN 
      Kernel.Install(SYSTEM.VAL(INTEGER, OldPS2IrqHandler[1]), BSP.VecTabBase + BSP.PS2CLOCK2ExtiIrqNum*4);
      OldPS2IrqHandler[1] := NIL
    END
  END restoreKBDriver;

  PROCEDURE show*(VAR dev: PS2.DeviceDesc);
    VAR lb: BYTE;
      idx: INTEGER;
  BEGIN
    Texts.WriteString(W, "Old IRQ Handler 1"); Texts.WriteHex(W, SYSTEM.VAL(INTEGER, OldPS2IrqHandler[0]));
    Texts.WriteString(W, ", old IRQ Handler 2"); Texts.WriteHex(W, SYSTEM.VAL(INTEGER, OldPS2IrqHandler[1]));
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
    IF dev.answerBlock # NIL THEN
      Texts.WriteString(W, "head "); Texts.WriteInt(W, dev.answerBlock.head, 1);
      Texts.WriteString(W, ", tail "); Texts.WriteInt(W, dev.answerBlock.tail, 1);
      idx := dev.answerBlock.head; DEC(idx); IF idx < 0 THEN idx := 15 END;
      Texts.WriteString(W, ", last byte read "); TextsEx.WriteHexVLen(W, dev.answerBlock.kbdBuf[idx], 1, FALSE);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END;

    Texts.WriteString(W, "statusIn "); Texts.WriteInt(W, dev.statusIn,1);
    Texts.WriteString(W, ", bad edges "); Texts.WriteInt(W, dev.badEdge,1);
    Texts.WriteString(W, ", clock.In "); Texts.WriteHex(W, dev.clock_In);
    Texts.WriteString(W, ", data.In "); Texts.WriteHex(W, dev.data_In);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);

    Texts.WriteString(W, "statusOut "); Texts.WriteInt(W, dev.statusOut,1);
    Texts.WriteString(W, ", leds "); Texts.WriteInt(W, leds,1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END show;


  PROCEDURE showKB*;
  BEGIN show(ps2[1]);
  END showKB;

  PROCEDURE showMouse*;
  BEGIN show(ps2[0]);
  END showMouse;

  PROCEDURE nextKBLeds*;
    VAR rc: BYTE;
  BEGIN INC(leds); leds := leds MOD 8;
    PS2.SendByteAsync(ps2[1], 0EDH);
    rc := PS2.WaitForAnswer(ps2[1], 35);
    IF rc = 0FAH THEN
      PS2.SendByteAsync(ps2[1], leds);
      rc := PS2.WaitForAnswer(ps2[1], 35)
    END
  END nextKBLeds;

  PROCEDURE resetKB*;
    VAR rc: BYTE;
  BEGIN
    rc := PS2.SendByte(ps2[1], 0FFH)
  END resetKB;

  PROCEDURE Command*;
    VAR S!: Texts.Scanner;
      idx, rc: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Int) & (S.i >= 0) & (S.i < 2) THEN
      idx := S.i; Texts.Scan(S); rc := 0FAH;
      WHILE (S.class = Texts.Int) & (rc = 0FAH) DO PS2.SendByteAsync(ps2[idx], S.i);
        rc := PS2.WaitForAnswer(ps2[idx], 35); Texts.Scan(S)
      END
    END
  END Command;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test PS/2 driver CS 21.03.24"); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf)
END testPS2.

OM4Tool.DecObj testPS2.m4c
