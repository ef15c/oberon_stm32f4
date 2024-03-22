MODULE testPS2;
  IMPORT SYSTEM, BSP, Kernel, PS2, Texts, Oberon, TextsEx;

  CONST EXTI_PR = BSP.EXTI_BASE + BSP.EXTI_PR;

  VAR ps2_1, ps2_2: PS2.DeviceDesc;
    OldPS2_2IrqHandler: PROCEDURE;
    leds: BYTE;

    W: Texts.Writer;

  PROCEDURE ps2_1IrqHandler;
    VAR pr: SET;
  BEGIN SYSTEM.GET(EXTI_PR, pr);
    IF ps2_1.clockPin IN pr THEN
      pr := {ps2_1.clockPin}; SYSTEM.PUT(EXTI_PR, pr); (*clear pending IRQ*)
      PS2.ProcessData(ps2_1)
    END
  END ps2_1IrqHandler;

  PROCEDURE ps2_2IrqHandler;
    VAR pr: SET;
  BEGIN
    SYSTEM.GET(EXTI_PR, pr);
    IF ps2_2.clockPin IN pr THEN
      pr := {ps2_2.clockPin}; SYSTEM.PUT(EXTI_PR, pr); (*clear pending IRQ*)
      PS2.ProcessData(ps2_2)
    END
  END ps2_2IrqHandler;

  PROCEDURE switchKBDriver*;
  BEGIN
(*      ps2_1.connectedDevice := PS2.MOUSE;
    ps2_1.clockPin := BSP.PS2CLOCK1Pin; ps2_1.dataPin := BSP.PS2DATA1Pin;
    ps2_1.clockIdr := BSP.PS2CLOCK1Port + BSP.IDR; ps2_1.dataIdr := BSP.PS2DATA1Port + BSP.IDR;
    ps2_1.clockPinOut := BSP.PS2CLOCK1Out; ps2_1.dataPinOut := BSP.PS2DATA1Out;
    ps2_1.keyboardLED := BSP.LD3Out; ps2_1.mouseLED := BSP.LD4Out;
    PS2.resetForTest(ps2_1);
*)
    IF OldPS2_2IrqHandler = NIL THEN
      ps2_2.connectedDevice := PS2.KEYBOARD;
      ps2_2.clockPin := BSP.PS2CLOCK2Pin;
      ps2_2.clock_In := BSP.PS2CLOCK2In; ps2_2.clock_Out := BSP.PS2CLOCK2Out;
      ps2_2.data_In := BSP.PS2DATA2In; ps2_2.data_Out := BSP.PS2DATA2Out;
      ps2_2.keyboardLED := BSP.LD3Out; ps2_2.mouseLED := BSP.LD4Out;
      PS2.resetForTest(ps2_2);

      SYSTEM.GET(BSP.VecTabBase + BSP.PS2CLOCK2ExtiIrqNum*4, OldPS2_2IrqHandler); (*keep track of original driver*)
      Kernel.Install(SYSTEM.ADR(ps2_2IrqHandler), BSP.VecTabBase + BSP.PS2CLOCK2ExtiIrqNum*4)
    END
  END switchKBDriver;

  PROCEDURE restoreKBDriver*;
  BEGIN IF OldPS2_2IrqHandler # NIL THEN 
      Kernel.Install(SYSTEM.VAL(INTEGER, OldPS2_2IrqHandler), BSP.VecTabBase + BSP.PS2CLOCK2ExtiIrqNum*4);
      OldPS2_2IrqHandler := NIL
    END
  END restoreKBDriver;

  PROCEDURE show*(VAR dev: PS2.DeviceDesc);
    VAR lb: BYTE;
      idx: INTEGER;
  BEGIN
    Texts.WriteString(W, "Old IRQ Handler "); Texts.WriteHex(W, SYSTEM.VAL(INTEGER, OldPS2_2IrqHandler));
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
    IF dev.answerBlock # NIL THEN
      Texts.WriteString(W, "MW "); Texts.WriteInt(W, dev.answerBlock.MW, 1);
      Texts.WriteString(W, ",head "); Texts.WriteInt(W, dev.answerBlock.head, 1);
      Texts.WriteString(W, ", tail "); Texts.WriteInt(W, dev.answerBlock.tail, 1);
      idx := dev.answerBlock.head; DEC(idx); IF idx < 0 THEN idx := 15 END;
      Texts.WriteString(W, ", last byte read "); TextsEx.WriteHexVLen(W, dev.answerBlock.kbdBuf[idx], 1, FALSE);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END;

    Texts.WriteString(W, "statusIn "); Texts.WriteInt(W, dev.statusIn,1);
    Texts.WriteString(W, ", bad edges "); Texts.WriteInt(W, dev.badEdge,1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);

    Texts.WriteString(W, "statusOut "); Texts.WriteInt(W, dev.statusOut,1);
    Texts.WriteString(W, ", leds "); Texts.WriteInt(W, leds,1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END show;


  PROCEDURE showKB*;
  BEGIN show(ps2_2);
  END showKB;

  PROCEDURE nextKBLeds*;
    VAR rc: BYTE;
  BEGIN INC(leds); leds := leds MOD 8;
    PS2.SendByteAsync(ps2_2, 0EDH);
    rc := PS2.WaitForAnswer(ps2_2, 35);
    IF rc = 0FAH THEN
      PS2.SendByteAsync(ps2_2, leds);
      rc := PS2.WaitForAnswer(ps2_2, 35)
    END
  END nextKBLeds;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test PS/2 driver CS 21.03.24"); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf)
END testPS2.

OM4Tool.DecObj testPS2.m4c
