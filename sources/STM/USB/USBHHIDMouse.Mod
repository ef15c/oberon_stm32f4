MODULE USBHHIDMouse;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   This file is the application layer for USB Host HID Mouse Handling.
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

  CONST MOUSE_REPORT_SIZE* = 8;

  TYPE
    Info* = POINTER TO InfoDesc;
    InfoDesc* = RECORD
      x*, y*: BYTE;
      buttons*: ARRAY 3 OF BOOLEAN
    END;

  VAR info: Info;
    mouse_report_data: ARRAY MOUSE_REPORT_SIZE OF BYTE;
    prop_x, prop_y, prop_b1, prop_b2, prop_b3: P.ReportItem;
  (**
  * @brief  USBH_HID_MouseInit
  *         The function init the HID mouse.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Init*(phost: Def.Handle): BYTE;
    VAR i: INTEGER; hidh!: HCl.Handle; res: BYTE;
  BEGIN hidh := phost.pActiveClass.pclsh(HCl.Handle); CLEAR(info^); CLEAR(mouse_report_data); CLEAR(hidh.Data.buf);
(*
    FOR i := 0 TO LEN(mouse_report_data) - 1 DO
      mouse_report_data[i] := 0; hidh.Data.buf[i] := 0
    END;
*)
    IF hidh.length > LEN(mouse_report_data) THEN hidh.length := LEN(mouse_report_data) END;
    IF HCl.QUEUE_SIZE * LEN(mouse_report_data) > LEN(hidh.fifo.buf) THEN res := Def.FAIL
    ELSE HCl.FifoInit(hidh.fifo);
      res := Def.OK
    END

    RETURN res
  END Init;

  (**
  * @brief  USBH_HID_MouseDecode
  *         The function decode mouse data.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE MouseDecode(phost: Def.Handle): BYTE;
    VAR HID_Handle!: HCl.Handle; res: BYTE;
  BEGIN HID_Handle := phost.pActiveClass.pclsh(HCl.Handle); res :=  Def.FAIL;
    IF (HID_Handle.length # 0) &
      (HCl.FifoRead(HID_Handle.fifo, mouse_report_data, HID_Handle.length) = HID_Handle.length) THEN
      (*Decode report *)
      info.x := P.ReadItem(mouse_report_data, prop_x, 0);
      info.y := P.ReadItem(mouse_report_data, prop_y, 0);
      info.buttons[0] := SYSTEM.VAL(BOOLEAN, P.ReadItem(mouse_report_data, prop_b1, 0));
      info.buttons[1] := SYSTEM.VAL(BOOLEAN, P.ReadItem(mouse_report_data, prop_b2, 0));
      info.buttons[2] := SYSTEM.VAL(BOOLEAN, P.ReadItem(mouse_report_data, prop_b3, 0));
      res := Def.OK
    END

    RETURN res
  END MouseDecode;

  (**
  * @brief  USBH_HID_GetMouseInfo
  *         The function return mouse information.
  * @param  phost: Host handle
  * @retval mouse information
  *)
  PROCEDURE GetInfo*(phost: Def.Handle): Info;
    VAR res!: Info;
  BEGIN res := NIL;
    IF MouseDecode(phost) = Def.OK THEN res := info END

    RETURN res
  END GetInfo;

BEGIN NEW(info);
  prop_x.offset := 1; prop_x.size := 8; prop_x.sign := TRUE; prop_x.logical_max := 0FFFFH; prop_x.resolution := 1;
  prop_y.offset := 2; prop_y.size := 8; prop_y.sign := TRUE; prop_y.logical_max := 0FFFFH; prop_y.resolution := 1;
  prop_b1.offset := 0; prop_b1.size := 1; prop_b1.shift := 0; prop_b1.logical_max := 1; prop_b1.resolution := 1;
  prop_b2.offset := 0; prop_b2.size := 1; prop_b2.shift := 1; prop_b2.logical_max := 1; prop_b2.resolution := 1;
  prop_b3.offset := 0; prop_b3.size := 1; prop_b3.shift := 2; prop_b3.logical_max := 1; prop_b3.resolution := 1
END USBHHIDMouse.
