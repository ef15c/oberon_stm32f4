MODULE USBHHIDKeybd;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   This file is the application layer for USB Host HID Keyboard handling
  *          QWERTY and AZERTY Keyboard are supported as per the selection in
  *          usbh_hid_keybd.h
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2015 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  *)

  IMPORT SYSTEM, Def := USBHDef, HCl := USBHHIDClass, P := USBHHIDParser;

  CONST KEYBD_REPORT_SIZE* = 8;

  TYPE
    Info* = POINTER TO InfoDesc;
    InfoDesc* = RECORD
      state*, lctrl*, lshift*, lalt*, lgui*, rctrl*, rshift*, ralt*, rgui*: BOOLEAN;
      keys*: ARRAY 6 OF BYTE;
    END;

  VAR info: Info;
    keybd_report_data: ARRAY KEYBD_REPORT_SIZE OF BYTE;
    imp_0_lctrl, imp_0_lshift, imp_0_lalt, imp_0_lgui,
    imp_0_rctrl, imp_0_rshift, imp_0_ralt, imp_0_rgui,
    imp_0_key_array: P.ReportItem;
    Codes, Key, ShiftKey: INTEGER; (*array addresses*)

  (**
  * @brief  USBH_HID_KeybdInit
  *         The function init the HID keyboard.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Init*(phost: Def.Handle): BYTE;
    VAR res: BYTE;
      hidh!: HCl.Handle;
      x: INTEGER;
  BEGIN hidh := phost.pActiveClass.pclsh(HCl.Handle);
    CLEAR(info^);
    FOR x := 0 TO LEN(keybd_report_data) - 1 DO
      keybd_report_data[x] := 0; hidh.pData[x] := 0
    END;
    IF hidh.length > LEN(keybd_report_data) THEN hidh.length := LEN(keybd_report_data) END;
    IF HCl.QUEUE_SIZE * LEN(keybd_report_data) > LEN(hidh.fifo.buf) THEN res := Def.FAIL
    ELSE  HCl.FifoInit(hidh.fifo);
      res := Def.OK
    END

    RETURN res
  END Init;

  (**
  * @brief  USBH_HID_KeybdDecode
  *         The function decode keyboard data.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE KeybdDecode(phost: Def.Handle): BYTE;
    VAR HID_Handle!: HCl.Handle; res: BYTE; x: INTEGER;
  BEGIN HID_Handle := phost.pActiveClass.pclsh(HCl.Handle); res := Def.FAIL;
    IF (HID_Handle.length # 0) &
      (HCl.FifoRead(HID_Handle.fifo, keybd_report_data, HID_Handle.length) =  HID_Handle.length) THEN
      (*Fill report *)
      info.lctrl :=  SYSTEM.VAL(BOOLEAN, P.ReadItem(keybd_report_data, imp_0_lctrl, 0));
      info.lshift := SYSTEM.VAL(BOOLEAN, P.ReadItem(keybd_report_data, imp_0_lshift, 0));
      info.lalt := SYSTEM.VAL(BOOLEAN, P.ReadItem(keybd_report_data, imp_0_lalt, 0));
      info.lgui := SYSTEM.VAL(BOOLEAN, P.ReadItem(keybd_report_data, imp_0_lgui, 0));
      info.rctrl := SYSTEM.VAL(BOOLEAN, P.ReadItem(keybd_report_data, imp_0_rctrl, 0));
      info.rshift := SYSTEM.VAL(BOOLEAN, P.ReadItem(keybd_report_data, imp_0_rshift, 0));
      info.ralt := SYSTEM.VAL(BOOLEAN, P.ReadItem(keybd_report_data, imp_0_ralt, 0));
      info.rgui := SYSTEM.VAL(BOOLEAN, P.ReadItem(keybd_report_data, imp_0_rgui, 0));
      FOR x := 0 TO LEN(info.keys) - 1 DO info.keys[x] := P.ReadItem(keybd_report_data, imp_0_key_array, x) END;
      res := Def.OK;
    END

    RETURN res
  END KeybdDecode;

  (**
  * @brief  USBH_HID_GetKeybdInfo
  *         The function return keyboard information.
  * @param  phost: Host handle
  * @retval keyboard information
  *)
  PROCEDURE GetInfo*(phost: Def.Handle): Info;
    VAR res!: Info;
  BEGIN res := NIL;
    IF KeybdDecode(phost) = Def.OK THEN res := info END

    RETURN res
  END GetInfo;

  (**
  * @brief  USBH_HID_GetASCIICode
  *         The function decode keyboard data into ASCII characters.
  * @param  phost: Host handle
  * @param  info: Keyboard information
  * @retval ASCII code
  *)
  PROCEDURE GetChar*(info: Info): CHAR;
    VAR output: CHAR; c: BYTE;
  BEGIN SYSTEM.GET(Codes + info.keys[0], c);
    IF info.lshift OR info.rshift THEN SYSTEM.GET(ShiftKey + c, c)
    ELSE SYSTEM.GET(Key + c, c)
    END;
    output := CHR(c)

    RETURN output
  END GetChar;

BEGIN NEW(info);
  imp_0_lctrl.offset := 0; imp_0_lctrl.size := 1; imp_0_lctrl.shift := 0; imp_0_lctrl.logical_max := 1; imp_0_lctrl.resolution := 1;
  imp_0_lshift.offset := 0; imp_0_lshift.size := 1; imp_0_lshift.shift := 1; imp_0_lshift.logical_max := 1; imp_0_lshift.resolution := 1;
  imp_0_lalt.offset := 0; imp_0_lalt.size := 1; imp_0_lalt.shift := 2; imp_0_lalt.logical_max := 1; imp_0_lalt.resolution := 1;
  imp_0_lgui.offset := 0; imp_0_lgui.size := 1; imp_0_lgui.shift := 3; imp_0_lgui.logical_max := 1; imp_0_lgui.resolution := 1;
  imp_0_rctrl.offset := 0; imp_0_rctrl.size := 1; imp_0_rctrl.shift := 4; imp_0_rctrl.logical_max := 1; imp_0_rctrl.resolution := 1;
  imp_0_rshift.offset := 0; imp_0_rshift.size := 1; imp_0_rshift.shift := 5; imp_0_rshift.logical_max := 1; imp_0_rshift.resolution := 1;
  imp_0_ralt.offset := 0; imp_0_ralt.size := 1; imp_0_ralt.shift := 6; imp_0_ralt.logical_max := 1; imp_0_ralt.resolution := 1;
  imp_0_rgui.offset := 0; imp_0_rgui.size := 1; imp_0_rgui.shift := 7; imp_0_rgui.logical_max := 1; imp_0_rgui.resolution := 1;
  imp_0_key_array.offset := 2; imp_0_key_array.size := 8; imp_0_key_array.shift := 0; imp_0_key_array.count := 6; 
    imp_0_key_array.shift := 0; imp_0_key_array.logical_max := 101; imp_0_key_array.resolution := 1;
  Codes := SYSTEM.ADR($
  00  00  00  00  1F  32  30  21  13  22  23  24  18  25  26  27
  34  33  19  1A  11  14  20  15  17  31  12  2F  16  2E  02  03
  04  05  06  07  08  09  0A  0B  2B  6E  0F  10  3D  0C  0D  1B
  1C  1D  2A  28  29  01  35  36  37  1E  70  71  72  73  74  75
  76  77  78  79  7A  7B  7C  7D  7E  4B  50  55  4C  51  56  59
  4F  54  53  5A  5F  64  69  6A  6C  5D  62  67  5C  61  66  5B
  60  65  63  68  2D  81  00  00  00  00  00  00  00  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00  00  00  6B  00  38  00  00  00  00  00  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  3A  2C  3C  7F  40  39  3E  80$
  );
  Key := SYSTEM.ADR($
  00  B2  26  E9  22  27  28  2D  E8  5F  E7  E0  29  3D  00  08
  09  61  7A  65  72  74  79  75  69  6F  70  5E  24  5C  00  71
  73  64  66  67  68  6A  6B  6C  6D  F9  2A  0A  00  3C  77  78
  63  76  62  6E  2C  3B  3A  21  00  00  00  00  00  20  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  37  34  31  00  2F
  38  35  32  30  2A  39  36  33  2E  2D  2B  00  0A  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00$
);
  ShiftKey := SYSTEM.ADR($
  00  00  31  32  33  34  35  36  37  38  39  30  B0  2B  00  08
  09  41  5A  45  52  54  59  55  49  4F  50  A8  A3  B5  00  51
  53  44  46  47  48  4A  4B  4C  4D  25  B5  0A  00  3E  57  58
  43  56  42  4E  3F  2E  2F  A7  00  00  00  00  00  20  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  37  00  00  00  2F
  00  00  00  00  2A  00  00  00  00  2D  2B  00  0A  00  00  00
  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00  00
  00  00  00$
);
END USBHHIDKeybd.
