MODULE testPS2;
  IMPORT BSP, PS2;

  VAR ps2_1, ps2_2: PS2.DeviceDesc;

  PROCEDURE switch*;
  BEGIN
      ps2_1.connectedDevice := PS2.MOUSE;
      ps2_1.clockPin := BSP.PS2CLOCK1Pin; ps2_1.dataPin := BSP.PS2DATA1Pin;
      ps2_1.clockIdr := BSP.PS2CLOCK1Port + BSP.IDR; ps2_1.dataIdr := BSP.PS2DATA1Port + BSP.IDR;
      ps2_1.clockPinOut := BSP.PS2CLOCK1Out; ps2_1.dataPinOut := BSP.PS2DATA1Out;  ps2_1.ActivityLedOut := BSP.LD4Out;
      PS2.resetForTest(ps2_1)
  END switch;

END testPS2.
