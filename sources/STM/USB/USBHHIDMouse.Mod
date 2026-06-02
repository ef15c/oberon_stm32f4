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

  IMPORT SYSTEM, Def := USBHDef, HCl := USBHHIDClass;

  CONST MOUSE_REPORT_SIZE* = 8;

  TYPE
    Info* = POINTER TO InfoDesc;
    InfoDesc* = RECORD
      x*, y*: BYTE;
      buttons*: ARRAY 3 OF BYTE
    END;

  VAR info: InfoDesc;
    mouse_report_data: ARRAY MOUSE_REPORT_SIZE OF BYTE;

  (**
  * @brief  USBH_HID_MouseInit
  *         The function init the HID mouse.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Init*(phost: Def.Handle): BYTE;
    VAR i: INTEGER; hidh!: HCl.Handle; res: BYTE;
  BEGIN hidh := phost.pActiveClass.pData(HCl.Handle); CLEAR(info);
    FOR i := 0 TO LEN(mouse_report_data) - 1 DO
      mouse_report_data[i] := 0; hidh.pData[i] := 0
    END;
    IF hidh.length > LEN(mouse_report_data) THEN hidh.length := LEN(mouse_report_data) END;
    IF HCl.QUEUE_SIZE * LEN(mouse_report_data) > LEN(hidh.fifo.buf) THEN res := Def.FAIL
    ELSE HCl.FifoInit(hidh.fifo);
      res := Def.OK
    END

    RETURN res
  END Init;

END USBHHIDMouse.
