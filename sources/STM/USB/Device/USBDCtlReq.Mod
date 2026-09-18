MODULE USBDCtlReq;
  (** ported to Oberon from:
  ******************************************************************************
  * @file    usbd_req.c
  * @author  MCD Application Team
  * @brief   This file provides the standard USB requests following chapter 9.
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
  IMPORT Conf := USBConf, DConf := USBDConf, Def := USBDef, DDef := USBDDef, IoReq := USBDIoReq;

  TYPE
    ResByte = POINTER TO ResByteDesc;
    ResByteDesc = RECORD(Def.BufferDesc) value: BYTE END;

    ResHW = POINTER TO ResHWDesc;
    ResHWDesc = RECORD(Def.BufferDesc) value: HALFSET END;

  (**
  * @brief  USBD_CtlError
  *         Handle USB low level Error
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval None
  *)
  PROCEDURE CtlError*(dev: DDef.Handle; req: Def.Setup);
  BEGIN dev.StallEP(dev, 80H); dev.StallEP(dev, 0)
  END CtlError;

  (**
  * @brief  USBD_GetLen
  *         return the string length
   * @param  buf : pointer to the ascii string buffer
  * @retval string length
  *)
  PROCEDURE GetLen(buf: ARRAY OF CHAR): HALFWORD;
    VAR len: HALFWORD;
  BEGIN len := 0;
    WHILE buf[len] # 0X DO INC(len) END

    RETURN len
  END GetLen;

  (**
  * @brief  USBD_GetString
  *         Convert Ascii string into unicode one
  * @param  desc : descriptor buffer
  * @param  unicode : Formatted string buffer (unicode)
  * @param  len : descriptor length
  * @retval None
  *)
  PROCEDURE GetString*(desc: ARRAY OF CHAR; VAR unicode: ARRAY OF BYTE; VAR len: HALFWORD);
    VAR idxd, idxu: HALFWORD;
  BEGIN idxd := 0; idxu := 0;
    len := Def.MIN(Conf.MAX_DESCRIPTOR_SIZE, GetLen(desc)*2 + 2);
    unicode[idxu] := len; INC(idxu);
    unicode[idxu] := Def.DESC_TYPE_STRING; INC(idxu);
    WHILE desc[idxd] # 0X DO unicode[idxu] := ORD(desc[idxd]); INC(idxu); INC(idxd);
      unicode[idxu] := 0; INC(idxu)
    END
  END GetString;

  (**
  * @brief  USBD_GetDescriptor
  *         Handle Get Descriptor requests
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval None
  *)
  PROCEDURE GetDescriptor(dev: DDef.Handle; req: Def.Setup);
    VAR value: INTEGER;
      buf!: Def.Buffer; err: BYTE;
      idx: INTEGER;
  BEGIN buf := NIL; err := 0; value := LSR(req.wValue, 8);
    IF value = 
(*
#if ((USBD_LPM_ENABLED == 1U) || (USBD_CLASS_BOS_ENABLED == 1U))
    case USB_DESC_TYPE_BOS:
      if (pdev->pDesc->GetBOSDescriptor != NULL)
      {
        pbuf = pdev->pDesc->GetBOSDescriptor(pdev->dev_speed, &len);
      }
      else
      {
        USBD_CtlError(pdev, req);
        err++;
      }
      break;
#endif /* (USBD_LPM_ENABLED == 1U) || (USBD_CLASS_BOS_ENABLED == 1U) */
*)
      Def.DESC_TYPE_DEVICE THEN buf := dev.Desc.GetDeviceDescriptor(dev.speed);
    ELSIF value = Def.DESC_TYPE_CONFIGURATION THEN
      IF dev.speed = Def.SPEED_HIGH THEN
(*
#ifdef USE_USBD_COMPOSITE
        if ((uint8_t)(pdev->NumClasses) > 0U)
        {
          pbuf = (uint8_t * )USBD_CMPSIT.GetHSConfigDescriptor(&len);
        }
        else
#endif /* USE_USBD_COMPOSITE */
*)
        buf := dev.Class[0].GetHSConfigDescriptor()
(*        buf[1] := Def.DESC_TYPE_CONFIGURATION;*)
      ELSE
(*
#ifdef USE_USBD_COMPOSITE
        if ((uint8_t)(pdev->NumClasses) > 0U)
        {
          pbuf = (uint8_t * )USBD_CMPSIT.GetFSConfigDescriptor(&len);
        }
        else
#endif /* USE_USBD_COMPOSITE */
*)
        buf := dev.Class[0].GetFSConfigDescriptor()
(*        pbuf[1] = USB_DESC_TYPE_CONFIGURATION;*)
      END
    ELSIF value = Def.DESC_TYPE_STRING THEN
      IF req.wValue = DDef.IDX_LANGID_STR THEN
        IF dev.Desc.GetLangIDStrDescriptor # NIL THEN buf := dev.Desc.GetLangIDStrDescriptor(dev.speed)
        ELSE CtlError(dev, req); INC(err)
        END
      ELSIF req.wValue = DDef.IDX_MFC_STR THEN
        IF dev.Desc.GetManufacturerStrDescriptor # NIL THEN buf := dev.Desc.GetManufacturerStrDescriptor(dev.speed)
        ELSE CtlError(dev, req); INC(err)
        END
      ELSIF req.wValue = DDef.IDX_PRODUCT_STR THEN
        IF dev.Desc.GetProductStrDescriptor # NIL THEN buf := dev.Desc.GetProductStrDescriptor(dev.speed)
        ELSE CtlError(dev, req); INC(err)
        END
      ELSIF req.wValue = DDef.IDX_SERIAL_STR THEN
        IF dev.Desc.GetSerialStrDescriptor # NIL THEN buf := dev.Desc.GetSerialStrDescriptor(dev.speed)
        ELSE CtlError(dev, req); INC(err)
        END
      ELSIF req.wValue = DDef.IDX_CONFIG_STR THEN
        IF dev.Desc.GetConfigurationStrDescriptor # NIL THEN buf := dev.Desc.GetConfigurationStrDescriptor(dev.speed)
        ELSE CtlError(dev, req); INC(err)
        END
      ELSIF req.wValue = DDef.IDX_INTERFACE_STR THEN
        IF dev.Desc.GetInterfaceStrDescriptor # NIL THEN buf := dev.Desc.GetInterfaceStrDescriptor(dev.speed)
        ELSE CtlError(dev, req); INC(err)
        END
      ELSE buf := NIL; idx := 0;
        WHILE (buf = NIL) & (idx < dev.NumClasses) DO
          IF dev.Class[idx].GetUsrStrDescriptor # NIL THEN
            dev.classId := idx;
            buf := dev.Class[idx].GetUsrStrDescriptor(dev, req.wValue MOD 100H);
          END;
          INC(idx)
        END
(*
#if (USBD_CLASS_USER_STRING_DESC == 1U)
          if (pdev->pDesc->GetUserStrDescriptor != NULL)
          {
            pbuf = pdev->pDesc->GetUserStrDescriptor(pdev->dev_speed, LOBYTE(req->wValue), &len);
          }
          else
          {
            USBD_CtlError(pdev, req);
            err++;
          }
#endif /* USBD_SUPPORT_USER_STRING_DESC  */

#if ((USBD_CLASS_USER_STRING_DESC == 0U) && (USBD_SUPPORT_USER_STRING_DESC == 0U))
          USBD_CtlError(pdev, req);
          err++;
#endif /* (USBD_CLASS_USER_STRING_DESC == 0U) && (USBD_SUPPORT_USER_STRING_DESC == 0U) */
*)
      END
    ELSIF value = Def.DESC_TYPE_DEVICE_QUALIFIER THEN
      IF dev.speed = Def.SPEED_HIGH THEN
(*
#ifdef USE_USBD_COMPOSITE
        if ((uint8_t)(pdev->NumClasses) > 0U)
        {
          pbuf = (uint8_t * )USBD_CMPSIT.GetDeviceQualifierDescriptor(&len);
        }
        else
#endif /* USE_USBD_COMPOSITE */
*)
        buf := dev.Class[0].GetDeviceQualifierDescriptor()
      ELSE CtlError(dev, req); INC(err)
      END
    ELSIF value = Def.DESC_TYPE_OTHER_SPEED_CONFIGURATION THEN
      IF dev.speed = Def.SPEED_HIGH THEN
(*
#ifdef USE_USBD_COMPOSITE
        if ((uint8_t)(pdev->NumClasses) > 0U)
        {
          pbuf = (uint8_t * )USBD_CMPSIT.GetOtherSpeedConfigDescriptor(&len);
        }
        else
#endif /* USE_USBD_COMPOSITE */
*)
        buf := dev.Class[0].GetOtherSpeedConfigDescriptor()
(*        pbuf[1] = USB_DESC_TYPE_OTHER_SPEED_CONFIGURATION;*)
      ELSE CtlError(dev, req); INC(err)
      END
    ELSE CtlError(dev, req); INC(err)
    END;

    IF err = 0 THEN
      IF req.wLength # 0 THEN
        IF buf.length # 0 THEN buf.length := Def.MIN(buf.length, req.wLength); IoReq.CtlSendData(dev, buf)
        ELSE CtlError(dev, req)
        END
      ELSE IoReq.CtlSendStatus(dev)
      END
    END
  END GetDescriptor;

  (**
  * @brief  USBD_SetAddress
  *         Set device address
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval None
  *)
  PROCEDURE SetAddress(dev: DDef.Handle; req: Def.Setup);
  BEGIN
    IF (req.wIndex = 0) & (req.wLength = 0) & (req.wValue < 128) THEN
      IF dev.state = DDef.STATE_CONFIGURED THEN CtlError(dev, req)
      ELSE dev.address := req.wValue; dev.SetUSBAddress(dev, req.wValue); IoReq.CtlSendStatus(dev);
        IF req.wValue # 0 THEN dev.state := DDef.STATE_ADDRESSED
        ELSE dev.state := DDef.STATE_DEFAULT
        END
      END
    ELSE CtlError(dev, req)
    END
  END SetAddress;

  (**
  * @brief  USBD_SetConfig
  *         Handle Set device configuration request
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval status
  *)
  PROCEDURE SetConfig(dev: DDef.Handle; req: Def.Setup);
    VAR ret: BYTE; cfgidx: BYTE;
  BEGIN cfgidx := req.wValue;
    IF cfgidx > DConf.MAX_NUM_CONFIGURATION THEN CtlError(dev, req)
    ELSIF dev.state = DDef.STATE_ADDRESSED THEN
      IF cfgidx # 0 THEN dev.config := cfgidx;
        ret := dev.SetClassConfig(dev, cfgidx);
        IF ret # Def.OK THEN CtlError(dev, req); dev.state := DDef.STATE_ADDRESSED
        ELSE IoReq.CtlSendStatus(dev); dev.state := DDef.STATE_CONFIGURED;
          IF dev.StateCallback # NIL THEN dev.StateCallback(DDef.STATE_CONFIGURED, cfgidx) END
        END
      ELSE IoReq.CtlSendStatus(dev)
      END
    ELSIF dev.state = DDef.STATE_CONFIGURED THEN
      IF cfgidx = 0 THEN dev.state := DDef.STATE_ADDRESSED;
        dev.ClrClassConfig(dev, dev.config); dev.config := 0; IoReq.CtlSendStatus(dev)
      ELSIF cfgidx # dev.config THEN
        dev.ClrClassConfig(dev, dev.config); (* Clear old configuration *)
        dev.config := cfgidx; (* set new configuration *)
        ret := dev.SetClassConfig(dev, cfgidx);
        IF ret # Def.OK THEN CtlError(dev, req); dev.ClrClassConfig(dev, dev.config);
          dev.state := DDef.STATE_ADDRESSED
        ELSE IoReq.CtlSendStatus(dev)
        END
      ELSE IoReq.CtlSendStatus(dev)
      END
    ELSE CtlError(dev, req); dev.ClrClassConfig(dev, cfgidx)
    END
  END SetConfig;

  (**
  * @brief  USBD_GetConfig
  *         Handle Get device configuration request
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval None
  *)
  PROCEDURE GetConfig(dev: DDef.Handle; req: Def.Setup);
    VAR res!: ResByte;
  BEGIN NEW(res); res.size := 1; res.length := 1;
    IF req.wLength # 1 THEN CtlError(dev, req)
    ELSIF dev.state IN {DDef.STATE_DEFAULT, DDef.STATE_ADDRESSED} THEN
      dev.default_config := 0;
      res.value := 0; IoReq.CtlSendData(dev, res)
    ELSIF dev.state = DDef.STATE_CONFIGURED THEN
      res.value := dev.config; IoReq.CtlSendData(dev, res)
    ELSE CtlError(dev, req)
    END
  END GetConfig;

  (**
  * @brief  USBD_GetStatus
  *         Handle Get Status request
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval None
  *)
  PROCEDURE GetStatus(dev: DDef.Handle; req: Def.Setup);
    VAR res!: ResHW;
  BEGIN NEW(res); res.size := 2; res.length := 2;
    IF dev.state IN {DDef.STATE_DEFAULT, DDef.STATE_ADDRESSED, DDef.STATE_CONFIGURED} THEN
      IF req.wLength # 2 THEN CtlError(dev, req)
      ELSE
        IF DConf.SELF_POWERED THEN dev.config_status := {Def.CONFIG_SELF_POWERED} ELSE dev.config_status := {} END;
        IF dev.remote_wakeup THEN INCL(dev.config_status, Def.CONFIG_REMOTE_WAKEUP) END;
        res.value := dev.config_status; IoReq.CtlSendData(dev, res)
      END
    ELSE CtlError(dev, req)
    END
  END GetStatus;

  (**
  * @brief  USBD_SetFeature
  *         Handle Set device feature request
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval None
  *)
  PROCEDURE SetFeature(dev: DDef.Handle; req: Def.Setup);
  BEGIN
    IF req.wValue = Def.FEATURE_REMOTE_WAKEUP THEN
      dev.remote_wakeup := TRUE; IoReq.CtlSendStatus(dev)
    ELSIF req.wValue = Def.FEATURE_TEST_MODE THEN
      dev.test_mode := LSR(req.wIndex, 8); IoReq.CtlSendStatus(dev)
    ELSE CtlError(dev, req)
    END
  END SetFeature;

  (**
  * @brief  USBD_ClrFeature
  *         Handle clear device feature request
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval None
  *)
  PROCEDURE ClrFeature(dev: DDef.Handle; req: Def.Setup);
  BEGIN
    IF dev.state IN {DDef.STATE_DEFAULT, DDef.STATE_ADDRESSED, DDef.STATE_CONFIGURED} THEN
      IF req.wValue = Def.FEATURE_REMOTE_WAKEUP THEN
        dev.remote_wakeup := FALSE; IoReq.CtlSendStatus(dev)
      END
    ELSE CtlError(dev, req)
    END
  END ClrFeature;

  (**
  * @brief  USBD_StdDevReq
  *         Handle standard usb device requests
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval status
  *)
  PROCEDURE StdDevReq*(dev: DDef.Handle; req: Def.Setup): BYTE;
    VAR ret: BYTE; type: SET;
  BEGIN ret := Def.OK; type := req.bmRequestType*Def.REQ_TYPE_MASK;
    IF (type = Def.REQ_TYPE_CLASS) OR (type = Def.REQ_TYPE_VENDOR) THEN
      ret := dev.Class[dev.classId].Setup(dev, req)
    ELSIF type = Def.REQ_TYPE_STANDARD THEN
      IF req.bRequest = Def.REQ_GET_DESCRIPTOR THEN GetDescriptor(dev, req)
      ELSIF req.bRequest = Def.REQ_SET_ADDRESS THEN SetAddress(dev, req)
      ELSIF req.bRequest = Def.REQ_SET_CONFIGURATION THEN SetConfig(dev, req)
      ELSIF req.bRequest = Def.REQ_GET_CONFIGURATION THEN GetConfig(dev, req)
      ELSIF req.bRequest = Def.REQ_GET_STATUS THEN GetStatus(dev, req)
      ELSIF req.bRequest = Def.REQ_SET_FEATURE THEN SetFeature(dev, req)
      ELSIF req.bRequest = Def.REQ_CLEAR_FEATURE THEN ClrFeature(dev, req)
      ELSE CtlError(dev, req)
      END
    ELSE CtlError(dev, req)
    END

    RETURN ret
  END StdDevReq;

  (**
  * @brief  USBD_StdItfReq
  *         Handle standard usb interface requests
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval status
  *)
  PROCEDURE StdItfReq*(dev: DDef.Handle; req: Def.Setup): BYTE;
    VAR ret, idx, itfidx: BYTE; type: SET;
  BEGIN ret := Def.OK; type := req.bmRequestType*Def.REQ_TYPE_MASK; itfidx := req.wIndex;
    IF (type = Def.REQ_TYPE_CLASS) OR (type = Def.REQ_TYPE_VENDOR) OR (type = Def.REQ_TYPE_STANDARD) THEN
      IF dev.state IN {DDef.STATE_DEFAULT, DDef.STATE_ADDRESSED, DDef.STATE_CONFIGURED} THEN
        IF itfidx <= DConf.MAX_NUM_INTERFACES THEN
          idx := dev.CoreFindIF(dev, itfidx); (* Get the class index relative to this interface *)
          IF (idx # 0FFH) & (idx < DDef.MAX_SUPPORTED_CLASS) THEN
            (* Call the class data out function to manage the request *)
            IF dev.Class[idx].Setup # NIL THEN dev.classId := idx; ret := dev.Class[idx].Setup(dev, req)
            ELSE (* should never reach this condition *) ret := Def.FAIL
            END
          ELSE (* No relative interface found *) ret := Def.FAIL
          END;
          IF (req.wLength = 0) & (ret = Def.OK) THEN IoReq.CtlSendStatus(dev) END
        ELSE CtlError(dev, req)
        END
      ELSE CtlError(dev, req)
      END
    ELSE CtlError(dev, req)
    END

    RETURN ret
  END StdItfReq;

  (**
  * @brief  USBD_StdEPReq
  *         Handle standard usb endpoint requests
  * @param  pdev: device instance
  * @param  req: usb request
  * @retval status
  *)
  PROCEDURE StdEPReq*(dev: DDef.Handle; req: Def.Setup): BYTE;
    VAR ret, ep_addr, idx: BYTE; type: SET; res!: ResByte;

    PROCEDURE SetStatus(dev: DDef.Handle; ep_addr: BYTE; VAR ep: DDef.Endpoint; VAR res: ResByte);
    BEGIN
      IF (ep_addr = 0) OR (ep_addr = 80H) THEN ep.status := 0
      ELSIF dev.IsStallEP(dev, ep_addr) THEN ep.status := 1
      ELSE ep.status := 0
      END;
      res.value := ep.status
    END SetStatus;

  BEGIN NEW(res); res.size := 1; res.length := 1;
    ret := Def.OK; type := req.bmRequestType*Def.REQ_TYPE_MASK; ep_addr := req.wIndex; 
    IF (type = Def.REQ_TYPE_CLASS) OR (type = Def.REQ_TYPE_VENDOR) THEN
      idx := dev.CoreFindEP(dev, ep_addr); (* Get the class index relative to this endpoint *)
      IF (idx # 0FFH) & (idx < DDef.MAX_SUPPORTED_CLASS) THEN dev.classId := idx;
        (* Call the class data out function to manage the request *)
        IF dev.Class[idx].Setup # NIL THEN ret := dev.Class[idx].Setup(dev, req) END
      END
    ELSIF type = Def.REQ_TYPE_STANDARD THEN
      IF req.bRequest = Def.REQ_SET_FEATURE THEN
        IF dev.state = DDef.STATE_ADDRESSED THEN
          IF (ep_addr # 0) & (ep_addr # 80H) THEN dev.StallEP(dev, ep_addr); dev.StallEP(dev, 80H)
          ELSE CtlError(dev, req)
          END
        ELSIF dev.state = DDef.STATE_CONFIGURED THEN
          IF req.wValue = Def.FEATURE_EP_HALT THEN
            IF (ep_addr # 0) & (ep_addr # 80H) & (req.wLength = 0) THEN dev.StallEP(dev, ep_addr) END
          END;
          IoReq.CtlSendStatus(dev)
        ELSE CtlError(dev, req)
        END
      ELSIF req.bRequest = Def.REQ_CLEAR_FEATURE THEN
        IF dev.state = DDef.STATE_ADDRESSED THEN
          IF (ep_addr # 0) & (ep_addr # 80H) THEN dev.StallEP(dev, ep_addr); dev.StallEP(dev, 80H)
          ELSE CtlError(dev, req)
          END
        ELSIF dev.state = DDef.STATE_CONFIGURED THEN
          IF req.wValue = Def.FEATURE_EP_HALT THEN
            IF ep_addr MOD 80H # 0 THEN dev.ClearStallEP(dev, ep_addr) END;
            IoReq.CtlSendStatus(dev);
            (* Get the class index relative to this interface *)
            idx := dev.CoreFindEP(dev, ep_addr);
            IF (idx # 0FFH) & (idx < DDef.MAX_SUPPORTED_CLASS) THEN dev.classId := idx;
              (* Call the class data out function to manage the request *)
              IF dev.Class[idx].Setup # NIL THEN ret := dev.Class[idx].Setup(dev, req) END
            END
          END
        ELSE CtlError(dev, req)
        END
      ELSIF req.bRequest = Def.REQ_GET_STATUS THEN
        IF dev.state = DDef.STATE_ADDRESSED THEN
          IF (ep_addr # 0) & (ep_addr # 80H) THEN CtlError(dev, req)
          ELSE res.value := 0;
            IF 7 IN TOSET(ep_addr) THEN dev.ep_in[ep_addr MOD 80H].status := 0
            ELSE dev.ep_out[ep_addr MOD 80H].status := 0
            END;
            IoReq.CtlSendData(dev, res);
          END
        ELSIF dev.state = DDef.STATE_CONFIGURED THEN
          IF  7 IN TOSET(ep_addr) THEN IF ~dev.ep_in[ep_addr MOD 10H].is_used THEN CtlError(dev, req); ret := Def.FAIL END
          ELSE IF~ dev.ep_out[ep_addr MOD 10H].is_used THEN CtlError(dev, req); ret := Def.FAIL END
          END;
          IF ret = Def.OK THEN
            IF 7 IN TOSET(ep_addr) THEN SetStatus(dev, ep_addr, dev.ep_in[ep_addr MOD 80H], res)
            ELSE SetStatus(dev, ep_addr, dev.ep_out[ep_addr MOD 80H], res)
            END;
            IoReq.CtlSendData(dev, res)
          END
        ELSE CtlError(dev, req)
        END
      ELSE CtlError(dev, req)
      END
    ELSE CtlError(dev, req)
    END

    RETURN ret
  END StdEPReq;

  (**
  * @brief  USBD_ParseSetupRequest
  *         Copy buffer into setup structure
  * @param  req: usb request
  * @param  pdata: setup data pointer
  * @retval None
  *)
  PROCEDURE ParseSetupRequest*(VAR req: Def.Setup; data: ARRAY OF BYTE);
  BEGIN req.bmRequestType := TOSET(data[0]); req.bRequest := data[1];
    req.wValue := Def.LE16(data, 2); req.wIndex := Def.LE16(data, 4);
    req.wLength := Def.LE16(data, 6)
  END ParseSetupRequest;


END USBDCtlReq.
