MODULE USBHCtlReq;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   This file implements the control requests for device enumeration
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
  IMPORT SYSTEM, Def := USBHDef, Conf := USBHConf, IoReq := USBHIoReq,
    Pipes := USBHPipes, Log := USBLog;

  CONST
    FEATURE_SELECTOR_ENDPOINT* = 0;
    FEATURE_SELECTOR_DEVICE* = 1;
    FEATURE_SELECTOR_REMOTEWAKEUP* = 1;

  (**
  * @brief  USBH_HandleControl
  *         Handles the USB control transfer state machine
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE HandleControl(phost: Def.Handle): BYTE;
    VAR status, URB_Status: BYTE; direction: SET;
  BEGIN status := Def.BUSY; URB_Status := Def.IDLE;
    IF phost.Control.state = Def.CTRL_SETUP THEN
      (* send a SETUP packet *)
      IoReq.CtlSendSetup(phost, SYSTEM.ADR(phost.Control.setup), phost.Control.pipe_out);
      phost.Control.state := Def.CTRL_SETUP_WAIT
    ELSIF phost.Control.state = Def.CTRL_SETUP_WAIT THEN
      URB_Status := phost.GetURBState(phost, phost.Control.pipe_out);
      IF URB_Status = Def.URB_DONE THEN (* case SETUP packet sent successfully *)
        direction := phost.Control.setup.bmRequestType*Def.REQ_DIR_MASK;
        (* check if there is a data stage *)
        IF phost.Control.setup.wLength # 0 THEN
          IF direction = Def.D2H THEN phost.Control.state := Def.CTRL_DATA_IN (* Data Direction is IN *)
          ELSE phost.Control.state := Def.CTRL_DATA_OUT (* Data Direction is OUT *)
          END
        ELSE (* No DATA stage *)
          IF direction = Def.D2H THEN phost.Control.state := Def.CTRL_STATUS_OUT (* Data Direction is IN *)
          ELSE phost.Control.state := Def.CTRL_STATUS_IN (* Data Direction is OUT *)
          END
        END
      ELSIF URB_Status IN {Def.URB_ERROR, Def.URB_NOTREADY} THEN phost.Control.state := Def.CTRL_ERROR
      END
    ELSIF phost.Control.state = Def.CTRL_DATA_IN THEN
      (* Issue an IN token *)
      phost.Control.timer := phost.Timer;
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      phost->NakTimer = phost->Timer;
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      IoReq.CtlReceiveData(phost, phost.Control.buff, phost.Control.length, phost.Control.pipe_in);
      phost.Control.state := Def.CTRL_DATA_IN_WAIT;
    ELSIF phost.Control.state = Def.CTRL_DATA_IN_WAIT THEN
      URB_Status := phost.GetURBState(phost, phost.Control.pipe_in);
      (* check is DATA packet transferred successfully *)
      IF URB_Status = Def.URB_DONE THEN phost.Control.state := Def.CTRL_STATUS_OUT
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      else if (URB_Status == USBH_URB_NAK_WAIT)
      {
        phost->Control.state = CTRL_DATA_IN_WAIT;

        if ((phost->Timer - phost->NakTimer) > phost->NakTimeout)
        {
          phost->NakTimer = phost->Timer;
          USBH_ActivatePipe(phost, phost->Control.pipe_in);
        }

      }
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      (* manage error cases *)
      ELSIF URB_Status = Def.URB_STALL THEN status := Def.NOT_SUPPORTED; (* In stall case, return to previous machine state*)
      ELSIF URB_Status = Def.URB_ERROR THEN phost.Control.state := Def.CTRL_ERROR; (* Device error *)
      END
    ELSIF phost.Control.state = Def.CTRL_DATA_OUT THEN
      IoReq.CtlSendData(phost, phost.Control.buff, phost.Control.length, phost.Control.pipe_out, TRUE);
      phost.Control.timer := phost.Timer;
      phost.Control.state := Def.CTRL_DATA_OUT_WAIT;
    ELSIF phost.Control.state = Def.CTRL_DATA_OUT_WAIT THEN
      URB_Status := phost.GetURBState(phost, phost.Control.pipe_out);
      IF URB_Status = Def.URB_DONE THEN phost.Control.state := Def.CTRL_STATUS_IN (* If the Setup Pkt is sent successful, then change the state *)
      (* handle error cases *)
      ELSIF URB_Status = Def.URB_STALL THEN (* In stall case, return to previous machine state*)
        phost.Control.state := Def.CTRL_STALLED; status := Def.NOT_SUPPORTED
      ELSIF URB_Status = Def.URB_NOTREADY THEN phost.Control.state := Def.CTRL_DATA_OUT (* Nack received from device *)
      ELSIF URB_Status = Def.URB_ERROR THEN (* device error *)
        phost.Control.state := Def.CTRL_ERROR; status := Def.FAIL
      END
    ELSIF phost.Control.state = Def.CTRL_STATUS_IN THEN
      IoReq.CtlReceiveData(phost, 0, 0, phost.Control.pipe_in); (* Send 0 bytes out packet *)
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      phost->NakTimer = phost->Timer;
#endif  /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      phost.Control.timer := phost.Timer; phost.Control.state := Def.CTRL_STATUS_IN_WAIT
    ELSIF phost.Control.state = Def.CTRL_STATUS_IN_WAIT THEN
      URB_Status := phost.GetURBState(phost, phost.Control.pipe_in);
      IF URB_Status = Def.URB_DONE THEN phost.Control.state := Def.CTRL_COMPLETE; (* Control transfers completed, Exit the State Machine *)
        status := Def.OK
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      else if (URB_Status == USBH_URB_NAK_WAIT)
      {
        phost->Control.state = CTRL_STATUS_IN_WAIT;

        if ((phost->Timer - phost->NakTimer) > phost->NakTimeout)
        {
          phost->NakTimer = phost->Timer;
          USBH_ActivatePipe(phost, phost->Control.pipe_in);
        }

      }
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      ELSIF URB_Status = Def.URB_ERROR THEN phost.Control.state := Def.CTRL_ERROR
      ELSIF URB_Status = Def.URB_STALL THEN status := Def.NOT_SUPPORTED (* Control transfers completed, Exit the State Machine *)
      END
    ELSIF phost.Control.state = Def.CTRL_STATUS_OUT THEN IoReq.CtlSendData(phost, 0, 0, phost.Control.pipe_out, TRUE);
      phost.Control.timer := phost.Timer; phost.Control.state := Def.CTRL_STATUS_OUT_WAIT
    ELSIF phost.Control.state = Def.CTRL_STATUS_OUT_WAIT THEN
      URB_Status := phost.GetURBState(phost, phost.Control.pipe_out);
      IF URB_Status = Def.URB_DONE THEN status := Def.OK; phost.Control.state := Def.CTRL_COMPLETE
      ELSIF URB_Status = Def.URB_NOTREADY THEN phost.Control.state := Def.CTRL_STATUS_OUT
      ELSIF URB_Status = Def.URB_ERROR THEN phost.Control.state := Def.CTRL_ERROR
      END
    ELSIF phost.Control.state = Def.CTRL_ERROR THEN
      (*
      After a halt condition is encountered or an error is detected by the
      host, a control endpoint is allowed to recover by accepting the next Setup
      PID; i.e., recovery actions via some other pipe are not required for control
      endpoints. For the Default Control Pipe, a device reset will ultimately be
      required to clear the halt or error condition if the next Setup PID is not
      accepted.
      *)
      INC(phost.Control.errorcount);
      IF phost.Control.errorcount <= Def.MAX_ERROR_COUNT THEN
        (* Do the transmission again, starting from SETUP Packet *)
        phost.Control.state := Def.CTRL_SETUP; phost.RequestState := Def.CMD_SEND
      ELSE phost.pUser(phost, Def.USER_UNRECOVERED_ERROR); phost.Control.errorcount := 0;
        Log.Error("Control error: Device not responding");
        (* Free control pipes *)
        Pipes.Free(phost, phost.Control.pipe_out);
        Pipes.Free(phost, phost.Control.pipe_in);
        phost.gState := Def.IDLE; status := Def.FAIL
      END
    END

    RETURN status
  END HandleControl;

  (**
  * @brief  USBH_CtlReq
  *         USBH_CtlReq sends a control request and provide the status after
  *            completion of the request
  * @param  phost: Host Handle
  * @param  req: Setup Request Structure
  * @param  buff: data buffer address to store the response
  * @param  length: length of the response
  * @retval USBH Status
  *)
  PROCEDURE CtlReq*(phost: Def.Handle; VAR buff: ARRAY OF BYTE): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.BUSY;
    IF phost.RequestState = Def.CMD_SEND THEN
      (* Start a SETUP transfer *)
      phost.Control.buff := SYSTEM.ADR(buff);
      phost.Control.length := phost.Control.setup.wLength;
      phost.Control.state := Def.CTRL_SETUP;
      phost.RequestState := Def.CMD_WAIT;
    ELSIF phost.RequestState = Def.CMD_WAIT THEN
      status := HandleControl(phost);
      IF status IN {Def.OK, Def.NOT_SUPPORTED} THEN
        (* Transaction completed, move control state to idle *)
        phost.RequestState := Def.CMD_SEND;
        phost.Control.state := Def.IDLE;
      ELSIF status = Def.FAIL THEN phost.RequestState := Def.CMD_SEND (* Failure Mode *)
      END
    END

    RETURN status
  END CtlReq;

  (**
  * @brief  USBH_ClrFeature
  *         This request is used to clear or disable a specific feature.
  * @param  phost: Host Handle
  * @param  ep_num: endpoint number
  * @param  hc_num: Host channel number
  * @retval USBH Status
  *)
  PROCEDURE ClrFeature*(phost: Def.Handle; ep_num: BYTE): BYTE;
    VAR dummy: ARRAY 0 OF BYTE;
  BEGIN
    IF phost.RequestState = Def.CMD_SEND THEN
      phost.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_ENDPOINT + Def.REQ_TYPE_STANDARD;
      phost.Control.setup.bRequest := Def.REQ_CLEAR_FEATURE;
      phost.Control.setup.wValue := FEATURE_SELECTOR_ENDPOINT;
      phost.Control.setup.wIndex := ep_num;
      phost.Control.setup.wLength := 0
    END

    RETURN CtlReq(phost, dummy)
  END ClrFeature;

  (**
  * @brief  USBH_ParseDevDesc
  *         This function Parses the device descriptor
  * @param  phost: Host Handle
  * @param  dev_desc: device_descriptor destination address
  * @param  buf: Buffer where the source descriptor is available
  * @param  length: Length of the descriptor
  * @retval USBH status
  *)
  PROCEDURE ParseDevDesc(phost: Def.Handle; VAR dev_desc: Def.DevDescriptor; VAR buf: Def.RawDescriptor): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.OK; Def.Reset(buf);
    dev_desc.bLength := Def.ReadByte(buf); dev_desc.bDescriptorType := Def.ReadByte(buf);
    dev_desc.bcdUSB := Def.ReadHalfword(buf);
    dev_desc.bDeviceClass := Def.ReadByte(buf); dev_desc.bDeviceSubClass := Def.ReadByte(buf);
    dev_desc.bDeviceProtocol := Def.ReadByte(buf); dev_desc.bMaxPacketSize := Def.ReadByte(buf);
    IF phost.device.speed IN {Def.SPEED_HIGH, Def.SPEED_FULL} THEN
      (* Make sure that the max packet size is either 8, 16, 32, 64 or force it to minimum allowed value *)
      IF (dev_desc.bMaxPacketSize # 8) &
        (dev_desc.bMaxPacketSize # 16) &
        (dev_desc.bMaxPacketSize # 32) &
        (dev_desc.bMaxPacketSize # 64) THEN
          (* set the size to min allowed value in case the device has answered with incorrect size *)
          dev_desc.bMaxPacketSize := 8
      END
    ELSIF phost.device.speed = Def.SPEED_LOW THEN dev_desc.bMaxPacketSize := 8 (* set the size to 8 for low speed devices *)
    ELSE status := Def.NOT_SUPPORTED
    END;
    IF (status = Def.OK) & (buf.length > 8) THEN
      (* For 1st time after device connection, Host may issue only 8 bytes for
          Device Descriptor Length  *)
      dev_desc.idVendor := Def.ReadHalfword(buf); dev_desc.idProduct := Def.ReadHalfword(buf);
      dev_desc.bcdDevice := Def.ReadHalfword(buf); dev_desc.iManufacturer := Def.ReadByte(buf);
      dev_desc.iProduct := Def.ReadByte(buf); dev_desc.iSerialNumber := Def.ReadByte(buf);
      dev_desc.bNumConfigurations := Def.ReadByte(buf);
    END

    RETURN status
  END ParseDevDesc;

  (**
  * @brief  USBH_ParseEPDesc
  *         This function Parses the endpoint descriptor
  * @param  phost: USB Host handler
  * @param  ep_descriptor: Endpoint descriptor destination address
  * @param  buf: Buffer where the parsed descriptor stored
  * @retval USBH Status
  *)
  PROCEDURE ParseEPDesc(phost: Def.Handle; VAR ep_descriptor: Def.EpDescriptor;
    VAR buf: Def.RawDescriptor): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.OK;
      ep_descriptor.bLength := Def.ReadByte(buf);
      ep_descriptor.bDescriptorType := Def.ReadByte(buf);
      ep_descriptor.bEndpointAddress := Def.ReadByte(buf);
      ep_descriptor.bmAttributes := TOSET(Def.ReadByte(buf));
      ep_descriptor.wMaxPacketSize := Def.ReadHalfword(buf);
      ep_descriptor.bInterval := Def.ReadByte(buf);
    (* Make sure that wMaxPacketSize is different from 0 *)
    IF (ep_descriptor.wMaxPacketSize = 0) OR
      (ep_descriptor.wMaxPacketSize > Def.MAX_EP_PACKET_SIZE) OR
      (ep_descriptor.wMaxPacketSize > Def.MAX_DATA_BUFFER) THEN status := Def.NOT_SUPPORTED
    END;
    IF phost.device.speed = Def.SPEED_HIGH THEN
      IF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_BULK THEN
        IF ep_descriptor.wMaxPacketSize > 512 THEN status := Def.NOT_SUPPORTED END
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_CTRL THEN
        IF ep_descriptor.wMaxPacketSize > 64 THEN status := Def.NOT_SUPPORTED END
      (* For high-speed interrupt/isochronous endpoints, bInterval can vary from 1 to 16 *)
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) IN {Def.EP_TYPE_ISOC, Def.EP_TYPE_INTR} THEN
        IF (ep_descriptor.bInterval = 0) OR (ep_descriptor.bInterval > 10H) THEN status := Def.NOT_SUPPORTED END
      ELSE status := Def.NOT_SUPPORTED
      END
    ELSIF phost.device.speed = Def.SPEED_FULL THEN
      IF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) IN {Def.EP_TYPE_BULK, Def.EP_TYPE_CTRL} THEN
        IF ep_descriptor.wMaxPacketSize > 64 THEN status := Def.NOT_SUPPORTED END
      (* For full-speed isochronous endpoints, the value of bInterval must be in the range from 1 to 16.*)
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_ISOC THEN
        IF (ep_descriptor.bInterval = 0) OR (ep_descriptor.bInterval > 10H) OR (ep_descriptor.wMaxPacketSize > 64) THEN
          status := Def.NOT_SUPPORTED
        END
      (* For full-speed interrupt endpoints, the value of bInterval may be from 1 to 255.*)
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_INTR THEN
        IF (ep_descriptor.bInterval = 0) OR (ep_descriptor.wMaxPacketSize > 1023) THEN status := Def.NOT_SUPPORTED END
      ELSE status := Def.NOT_SUPPORTED;
      END
    ELSIF phost.device.speed = Def.SPEED_LOW THEN
      IF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_CTRL THEN
        IF ep_descriptor.wMaxPacketSize # 8 THEN status := Def.NOT_SUPPORTED END
      (* For low-speed interrupt endpoints, the value of bInterval may be from 1 to 255.*)
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_INTR THEN
        IF (ep_descriptor.bInterval = 0) OR (ep_descriptor.wMaxPacketSize > 8) THEN status := Def.NOT_SUPPORTED END
      ELSE status := Def.NOT_SUPPORTED
      END
    ELSE status := Def.NOT_SUPPORTED;
    END

    RETURN status
  END ParseEPDesc;

  PROCEDURE ParseInterface(phost: Def.Handle; cfg_desc: Def.CfgDescriptor; VAR if_descriptor: Def.InterfaceDescriptor;
    VAR buf: Def.RawDescriptor): BYTE;
    (*feed interface descriptor from buf[index..index+8]*)
    VAR status, ep_ix: BYTE;
  BEGIN
    if_descriptor.bLength := Def.ReadByte(buf);
    (* Make sure that the interface descriptor's bLength is equal to USB_INTERFACE_DESC_SIZE *)
    if_descriptor.bLength := Def.INTERFACE_DESC_SIZE;
    if_descriptor.bDescriptorType := Def.ReadByte(buf);
    if_descriptor.bInterfaceNumber := Def.ReadByte(buf);
    if_descriptor.bAlternateSetting := Def.ReadByte(buf);
    if_descriptor.bNumEndpoints := Def.ReadByte(buf);
    if_descriptor.bInterfaceClass := Def.ReadByte(buf);
    if_descriptor.bInterfaceSubClass := Def.ReadByte(buf);
    if_descriptor.bInterfaceProtocol := Def.ReadByte(buf);
    if_descriptor.iInterface := Def.ReadByte(buf);
    ep_ix := 0;
    WHILE (status = Def.OK) & (ep_ix < Conf.MAX_NUM_ENDPOINTS) &
      (ep_ix < if_descriptor.bNumEndpoints) & Def.HasMoreHeaders(buf) DO
      Def.GoNextHeader(buf); (*next descriptor*)
      IF Def.HeaderType(buf) = Def.DESC_TYPE_ENDPOINT THEN
        status := ParseEPDesc(phost, if_descriptor.Ep_Desc[ep_ix], buf);
        (* Check if the endpoint is appartening to an audio streaming interface *)
        IF (if_descriptor.bInterfaceClass = 1) & (if_descriptor.bInterfaceSubClass IN {2, 3}) THEN
          (* Check if it is supporting the USB AUDIO 01 class specification *)
          IF (if_descriptor.bInterfaceProtocol = 0) THEN if_descriptor.Ep_Desc[ep_ix].bLength := 9 END
        ELSE (* Make sure that the endpoint descriptor's bLength is equal to
           USB_ENDPOINT_DESC_SIZE for all other endpoints types *)
          if_descriptor.Ep_Desc[ep_ix].bLength := Def.ENDPOINT_DESC_SIZE
        END;
        INC(ep_ix)
      END
    END;
    (* Check if the required endpoint(s) data are parsed *)
    IF ep_ix < if_descriptor.bNumEndpoints THEN status := Def.NOT_SUPPORTED END

    RETURN status
  END ParseInterface;

  (**
  * @brief  ParseConfig
  *         This procedure parses the configuration descriptor
  * @param  cfg_desc: the destination descriptor record
  * @param  buf: the raw descriptor given by the device
  * @retval None
  *)
  PROCEDURE ParseConfig(VAR cfg_desc: Def.CfgDescriptor; VAR buf: Def.RawDescriptor);
  BEGIN
    cfg_desc.bLength := Def.ReadByte(buf); cfg_desc.bDescriptorType := Def.ReadByte(buf);
    cfg_desc.wTotalLength := Def.MIN(Def.ReadHalfword(buf), Conf.MAX_SIZE_CONFIGURATION);
    cfg_desc.bNumInterfaces := Def.ReadByte(buf); cfg_desc.bConfigurationValue := Def.ReadByte(buf);
    cfg_desc.iConfiguration := Def.ReadByte(buf); cfg_desc.bmAttributes := TOSET(Def.ReadByte(buf));
    cfg_desc.bMaxPower := Def.ReadByte(buf)
  END ParseConfig;

  (**
  * @brief  USBH_ParseStringDesc
  *         This function Parses the string descriptor
  * @param  psrc: Source pointer containing the descriptor data
  * @param  pdest: Destination address pointer
  * @retval None
  *)
  PROCEDURE ParseStringDesc(psrc: Def.RawDescriptor; VAR pdest: ARRAY OF CHAR);
    VAR strlength, idx, idd: HALFWORD;
  BEGIN
    (* The UNICODE string descriptor is not NULL-terminated. The string length is
    computed by subtracting two from the value of the first byte of the descriptor.
    *)
    (* Check which is lower size, the Size of string or the length of bytes read
    from the device *)

    IF Def.HeaderType(psrc) = Def.DESC_TYPE_STRING THEN
      (* Make sure the Descriptor is String Type *)
      (* psrc[0] contains Size of Descriptor, subtract 2 to get the length of string *)
      IF Def.HeaderSize(psrc) - 2 <= psrc.length THEN strlength := Def.HeaderSize(psrc) - 2 ELSE strlength := psrc.length END;
      idd := 0;
      FOR idx := 2 TO strlength BY 2 DO
        (* Copy Only the string and ignore the UNICODE ID, hence add the src *)
        pdest[idd] :=  CHR(psrc.data[idx]);
        INC(idd);
      END;
      pdest[idd] := 0X; (* mark end of string *)
    END
  END ParseStringDesc;

  (**
  * @brief  USBH_ParseCfgDesc
  *         This function Parses the configuration descriptor
  * @param  phost: USB Host handler
  * @param  buf: Buffer where the source descriptor is available
  * @param  length: Length of the descriptor
  * @retval USBH status
  *)
  PROCEDURE ParseCfgDesc(phost: Def.Handle; VAR buf: Def.RawDescriptor): BYTE;
    VAR status, if_ix: BYTE;

  BEGIN status := Def.OK; if_ix := 0; Def.Reset(buf);
    (* Make sure that the Configuration descriptor's bLength is equal to USB_CONFIGURATION_DESC_SIZE *)
    IF Def.HeaderSize(buf) # Def.CONFIGURATION_DESC_SIZE THEN
      Log.Error("buggy device: bad configuration length"); status := Def.NOT_SUPPORTED
    ELSE ParseConfig(phost.device.CfgDesc, buf);
      IF buf.length > Def.CONFIGURATION_DESC_SIZE THEN
        WHILE (status = Def.OK) & (if_ix < Conf.MAX_NUM_INTERFACES) & Def.HasMoreHeaders(buf) DO
          Def.GoNextHeader(buf);
          IF Def.HeaderType(buf) = Def.DESC_TYPE_INTERFACE THEN
            status := ParseInterface(phost, phost.device.CfgDesc, phost.device.CfgDesc.Itf_Desc[if_ix], buf);
            INC(if_ix)
          END;
          Def.GoNextHeader(buf)
        END;
        (* Check if the required interface(s) data are parsed *)
        IF if_ix < Def.MIN(phost.device.CfgDesc.bNumInterfaces, Conf.MAX_NUM_INTERFACES) THEN status := Def.NOT_SUPPORTED END
      END
    END

    RETURN status
  END ParseCfgDesc;

  (**
  * @brief  USBH_GetDescriptor
  *         Issues Descriptor command to the device. Once the response received,
  *         it parses the descriptor and updates the status.
  * @param  phost: Host Handle
  * @param  req_type: Descriptor type
  * @param  value_idx: Value for the GetDescriptor request
  * @param  buff: Buffer to store the descriptor
  * @param  length: Length of the descriptor
  * @retval USBH Status
  *)
  PROCEDURE GetDescriptor*(phost: Def.Handle; req_type: BYTESET; value_idx: HALFSET; VAR rd: Def.RawDescriptor): BYTE;
  BEGIN
    IF phost.RequestState = Def.CMD_SEND THEN
      phost.Control.setup.bmRequestType := Def.D2H + req_type;
      phost.Control.setup.bRequest := Def.REQ_GET_DESCRIPTOR;
      phost.Control.setup.wValue := ORD(value_idx);
      IF value_idx*{8..15} = Def.DESC_STRING THEN phost.Control.setup.wIndex := 0409H (*English/USA language ID*)
      ELSE phost.Control.setup.wIndex := 0
      END;
      phost.Control.setup.wLength := rd.length;
    END

    RETURN CtlReq(phost, rd.data)
  END GetDescriptor;

  (**
  * @brief  USBH_SetAddress
  *         This command sets the address to the connected device
  * @param  phost: Host Handle
  * @param  DeviceAddress: Device address to assign
  * @retval USBH Status
  *)
  PROCEDURE SetAddress*(phost: Def.Handle; DeviceAddress: BYTE): BYTE;
    VAR dummy: ARRAY 0 OF BYTE;
  BEGIN
    IF phost.RequestState = Def.CMD_SEND THEN
      phost.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_DEVICE +
        Def.REQ_TYPE_STANDARD;
      phost.Control.setup.bRequest := Def.REQ_SET_ADDRESS;
      phost.Control.setup.wValue := DeviceAddress;
      phost.Control.setup.wIndex := 0;
      phost.Control.setup.wLength := 0
    END
    RETURN CtlReq(phost, dummy)
  END SetAddress;

  (**
  * @brief  USBH_SetCfg
  *         The command sets the configuration value to the connected device
  * @param  phost: Host Handle
  * @param  cfg_idx: Configuration value
  * @retval USBH Status
  *)
  PROCEDURE SetCfg*(phost: Def.Handle;  cfg_idx: HALFWORD): BYTE;
    VAR dummy: ARRAY 0 OF BYTE;
  BEGIN
    IF phost.RequestState = Def.CMD_SEND THEN
      phost.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD;
      phost.Control.setup.bRequest := Def.REQ_SET_CONFIGURATION;
      phost.Control.setup.wValue := cfg_idx;
      phost.Control.setup.wIndex := 0;
      phost.Control.setup.wLength := 0
    END

    RETURN CtlReq(phost, dummy)
  END SetCfg;

  (**
  * @brief  USBH_SetFeature
  *         The command sets the device features (remote wakeup feature,..)
  * @param  pdev: Selected device
  * @param  itf_idx
  * @retval Status
  *)
  PROCEDURE SetFeature*(phost: Def.Handle; wValue: HALFWORD): BYTE;
    VAR dummy: ARRAY 0 OF BYTE;
  BEGIN
    IF phost.RequestState = Def.CMD_SEND THEN
      phost.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD;
      phost.Control.setup.bRequest := Def.REQ_SET_FEATURE;
      phost.Control.setup.wValue := wValue;
      phost.Control.setup.wIndex := 0;
      phost.Control.setup.wLength := 0
    END

    RETURN CtlReq(phost, dummy)
  END SetFeature;

  (**
  * @brief  USBH_Get_DevDesc
  *         Issue Get Device Descriptor command to the device. Once the response
  *         received, it parses the device descriptor and updates the status.
  * @param  phost: Host Handle
  * @param  length: Length of the descriptor
  * @retval USBH Status
  *)
  PROCEDURE Get_DevDesc*(phost: Def.Handle; length: HALFWORD): BYTE;
    VAR status: BYTE; buf: Def.RawDescriptor;
  BEGIN
    IF length > LEN(buf.data) THEN
      Log.Error("Control error: Get Device Descriptor failed, data buffer size issue");
      status := Def.NOT_SUPPORTED
    ELSE buf.length := length; status := GetDescriptor(phost, Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD,
                             Def.DESC_DEVICE, buf);
      IF status = Def.OK THEN (* Commands successfully sent and Response Received *)
        status := ParseDevDesc(phost, phost.device.DevDesc, buf)
      END
    END

    RETURN status
  END Get_DevDesc;

  (**
  * @brief  USBH_Get_CfgDesc
  *         Issues Configuration Descriptor to the device. Once the response
  *         received, it parses the configuration descriptor and updates the
  *         status.
  * @param  phost: Host Handle
  * @param  length: Length of the descriptor
  * @retval USBH Status
  *)
  PROCEDURE Get_CfgDesc*(phost: Def.Handle; length: HALFWORD): BYTE;
    VAR status: BYTE;
  BEGIN
    IF length > LEN(phost.device.CfgDesc_Raw.data) THEN
      Log.Error("Control error: Get configuration Descriptor failed, data buffer size issue");
      status := Def.NOT_SUPPORTED;
    ELSE phost.device.CfgDesc_Raw.length := length;
      status := GetDescriptor(phost, Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD,
                      Def.DESC_CONFIGURATION, phost.device.CfgDesc_Raw);
      IF status = Def.OK THEN (* Commands successfully sent and Response Received  *)
        status := ParseCfgDesc(phost, phost.device.CfgDesc_Raw)
      END
    END

    RETURN status
  END Get_CfgDesc;

  (**
  * @brief  USBH_Get_StringDesc
  *         Issues string Descriptor command to the device. Once the response
  *         received, it parses the string descriptor and updates the status.
  * @param  phost: Host Handle
  * @param  string_index: String index for the descriptor
  * @param  buff: Buffer address for the descriptor
  * @retval USBH Status
  *)
  PROCEDURE Get_StringDesc*(phost: Def.Handle; string_index: BYTE; VAR buff: ARRAY OF CHAR; length: HALFWORD): BYTE;
    VAR status: BYTE; buf: Def.RawDescriptor;
  BEGIN
    IF length > LEN(buf.data) THEN
      Log.Error("Control error: Get String Descriptor failed, data buffer size issue");
      status := Def.NOT_SUPPORTED
    ELSE buf.length := length;
      status := GetDescriptor(phost, Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD,
                            Def.DESC_STRING + TOSET(string_index), buf);
      IF status = Def.OK THEN (* Commands successfully sent and Response Received *)
        ParseStringDesc(buf, buff);
      END
    END

    RETURN status
  END Get_StringDesc;

END USBHCtlReq.

OM4Tool.DecObj USBHCtlReq.m4c
