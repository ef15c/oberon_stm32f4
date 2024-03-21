MODULE testPS2;
  IMPORT SYSTEM, BSP, Kernel, PS2, Texts, Oberon;

  CONST EXTI_PR = BSP.EXTI_BASE + BSP.EXTI_PR;

  VAR ps2_1, ps2_2: PS2.DeviceDesc;
    OldPS2_2IrqHandler: PROCEDURE;

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
      ps2_2.clockPin := BSP.PS2CLOCK2Pin; ps2_2.dataPin := BSP.PS2DATA2Pin;
      ps2_2.clockIdr := BSP.PS2CLOCK2Port + BSP.IDR; ps2_2.dataIdr := BSP.PS2DATA2Port + BSP.IDR;
      ps2_2.clockPinOut := BSP.PS2CLOCK2Out; ps2_2.dataPinOut := BSP.PS2DATA2Out;
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
    VAR gpio: LONGINT;
  BEGIN Texts.WriteString(W, "@dataIdr "); Texts.WriteHex(W, dev.dataIdr);
    Texts.WriteString(W, ", dataPin "); Texts.WriteInt(W, dev.dataPin,1);
    SYSTEM.GET(dev.dataIdr, gpio); Texts.WriteString(W, ", dataIdr "); Texts.WriteHex(W, gpio);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
    IF dev.answerBlock # NIL THEN
      Texts.WriteString(W, "MW "); Texts.WriteInt(W, dev.answerBlock.MW, 1);
      Texts.WriteString(W, ",head "); Texts.WriteInt(W, dev.answerBlock.head, 1);
      Texts.WriteString(W, ", tail "); Texts.WriteInt(W, dev.answerBlock.tail, 1);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END;

    Texts.WriteString(W, "statusIn "); Texts.WriteInt(W, dev.statusIn,1);
    Texts.WriteString(W, ", nofBitsToBeRead "); Texts.WriteInt(W, dev.nofBitsToBeRead,1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END show;


  PROCEDURE showKB*;
  BEGIN show(ps2_2);
  END showKB;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Test PS/2 driver CS 21.03.24"); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf)
END testPS2.

OM4Tool.DecObj testPS2.m4c
