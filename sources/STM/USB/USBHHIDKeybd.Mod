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

  IMPORT SYSTEM, Def := USBHDef, HCl := USBHHIDClass;

  CONST KEYBD_REPORT_SIZE* = 8;

  TYPE
    Info* = POINTER TO InfoDesc;
    InfoDesc* = RECORD
      state*, lctrl*, lshift*, lalt*, lgui*, rctrl*, rshift*, ralt*, rgui*: BYTE;
      keys*: ARRAY 6 OF BYTE;
    END;

  VAR info: InfoDesc;
    keybd_report_data: ARRAY KEYBD_REPORT_SIZE OF BYTE;

  (**
  * @brief  USBH_HID_KeybdInit
  *         The function init the HID keyboard.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Init*(phost: Def.Handle): BYTE;
    VAR res: BYTE;
      hidh!: HCl.Handle; zero!: Info;
      x: INTEGER;
  BEGIN hidh := phost.pActiveClass.pData(HCl.Handle);
    zero := SYSTEM.VAL(Info, SYSTEM.ADR(Def.ZERO));
    info := zero^;
    FOR x := 0 TO LEN(keybd_report_data) - 1 DO
      keybd_report_data[x] := 0; hidh.pData[x] := 0
    END;
    IF hidh.length > LEN(keybd_report_data) THEN hidh.length := LEN(keybd_report_data) END;
    IF HCl.QUEUE_SIZE * LEN(keybd_report_data) > LEN(phost.device.Data.buf) THEN res := Def.FAIL
    ELSE  HCl.FifoInit(hidh.fifo, SYSTEM.VAL(Def.DataBuffer, SYSTEM.ADR(phost.device.Data)), HCl.QUEUE_SIZE * LEN(keybd_report_data));
      res := Def.OK
    END

    RETURN res
  END Init;

END USBHHIDKeybd.
