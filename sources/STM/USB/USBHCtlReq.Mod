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
  IMPORT SYSTEM, Def := USBDef, HDef := USBHDef, Conf := USBHConf, IoReq := USBHIoReq,
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
  PROCEDURE HandleControl(host: HDef.Handle; VAR buff: Def.Buffer): BYTE;
    VAR status, URB_Status: BYTE; dummy: Def.Buffer;
  BEGIN status := Def.BUSY; URB_Status := Def.IDLE; dummy.size := 0;
    IF host.Control.state = HDef.CTRL_SETUP THEN
      (* send a SETUP packet *)
      IoReq.CtlSendSetup(host, host.Control.setup, host.Control.pipe_out);
      host.Control.state := HDef.CTRL_SETUP_WAIT
    ELSIF host.Control.state = HDef.CTRL_SETUP_WAIT THEN
      URB_Status := host.GetURBState(host, host.Control.pipe_out);
      IF URB_Status = HDef.URB_DONE THEN (* case SETUP packet sent successfully *)
        (* check if there is a data stage *)
        IF host.Control.setup.wLength # 0 THEN
          IF 7 IN host.Control.setup.bmRequestType THEN host.Control.state := HDef.CTRL_DATA_IN; (* Data Direction is IN *)
          ELSE host.Control.state := HDef.CTRL_DATA_OUT (* Data Direction is OUT *)
          END
        ELSE (* No DATA stage *)
          IF 7 IN host.Control.setup.bmRequestType THEN host.Control.state := HDef.CTRL_STATUS_OUT (* Data Direction is IN *)
          ELSE host.Control.state := HDef.CTRL_STATUS_IN (* Data Direction is OUT *)
          END
        END
      ELSIF URB_Status IN {HDef.URB_ERROR, HDef.URB_NOTREADY} THEN host.Control.state := HDef.CTRL_ERROR
      END
    ELSIF host.Control.state = HDef.CTRL_DATA_IN THEN
      (* Issue an IN token *)
      host.Control.timer := host.Timer;
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      host->NakTimer = host->Timer;
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      IoReq.CtlReceiveData(host, buff, host.Control.length, host.Control.pipe_in);
      host.Control.state := HDef.CTRL_DATA_IN_WAIT;
    ELSIF host.Control.state = HDef.CTRL_DATA_IN_WAIT THEN
      URB_Status := host.GetURBState(host, host.Control.pipe_in);
      (* check is DATA packet transferred successfully *)
      IF URB_Status = HDef.URB_DONE THEN host.Control.state := HDef.CTRL_STATUS_OUT
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      else if (URB_Status == USBH_URB_NAK_WAIT)
      {
        host->Control.state = CTRL_DATA_IN_WAIT;

        if ((host->Timer - host->NakTimer) > phost->NakTimeout)
        {
          host->NakTimer = host->Timer;
          USBH_ActivatePipe(host, host->Control.pipe_in);
        }

      }
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      (* manage error cases *)
      ELSIF URB_Status = HDef.URB_STALL THEN status := HDef.NOT_SUPPORTED; (* In stall case, return to previous machine state*)
      ELSIF URB_Status = HDef.URB_ERROR THEN host.Control.state := HDef.CTRL_ERROR; (* Device error *)
      END
    ELSIF host.Control.state = HDef.CTRL_DATA_OUT THEN
      IoReq.CtlSendData(host, buff, host.Control.length, host.Control.pipe_out, TRUE);
      host.Control.timer := host.Timer;
      host.Control.state := HDef.CTRL_DATA_OUT_WAIT;
    ELSIF host.Control.state = HDef.CTRL_DATA_OUT_WAIT THEN
      URB_Status := host.GetURBState(host, host.Control.pipe_out);
      IF URB_Status = HDef.URB_DONE THEN host.Control.state := HDef.CTRL_STATUS_IN (* If the Setup Pkt is sent successful, then change the state *)
      (* handle error cases *)
      ELSIF URB_Status = HDef.URB_STALL THEN (* In stall case, return to previous machine state*)
        host.Control.state := HDef.CTRL_STALLED; status := HDef.NOT_SUPPORTED
      ELSIF URB_Status = HDef.URB_NOTREADY THEN host.Control.state := HDef.CTRL_DATA_OUT (* Nack received from device *)
      ELSIF URB_Status = HDef.URB_ERROR THEN (* device error *)
        host.Control.state := HDef.CTRL_ERROR; status := Def.FAIL
      END
    ELSIF host.Control.state = HDef.CTRL_STATUS_IN THEN
      IoReq.CtlReceiveData(host, dummy, 0, host.Control.pipe_in); (* Send 0 bytes out packet *)
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      host->NakTimer = host->Timer;
#endif  /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      host.Control.timer := host.Timer; host.Control.state := HDef.CTRL_STATUS_IN_WAIT
    ELSIF host.Control.state = HDef.CTRL_STATUS_IN_WAIT THEN
      URB_Status := host.GetURBState(host, host.Control.pipe_in);
      IF URB_Status = HDef.URB_DONE THEN host.Control.state := HDef.CTRL_COMPLETE; (* Control transfers completed, Exit the State Machine *)
        status := Def.OK
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      else if (URB_Status == USBH_URB_NAK_WAIT)
      {
        host->Control.state = CTRL_STATUS_IN_WAIT;

        if ((host->Timer - host->NakTimer) > host->NakTimeout)
        {
          host->NakTimer = host->Timer;
          USBH_ActivatePipe(host, host->Control.pipe_in);
        }

      }
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      ELSIF URB_Status = HDef.URB_ERROR THEN host.Control.state := HDef.CTRL_ERROR
      ELSIF URB_Status = HDef.URB_STALL THEN status := HDef.NOT_SUPPORTED (* Control transfers completed, Exit the State Machine *)
      END
    ELSIF host.Control.state = HDef.CTRL_STATUS_OUT THEN IoReq.CtlSendData(host, dummy, 0, host.Control.pipe_out, TRUE);
      host.Control.timer := host.Timer; host.Control.state := HDef.CTRL_STATUS_OUT_WAIT
    ELSIF host.Control.state = HDef.CTRL_STATUS_OUT_WAIT THEN
      URB_Status := host.GetURBState(host, host.Control.pipe_out);
      IF URB_Status = HDef.URB_DONE THEN status := Def.OK; host.Control.state := HDef.CTRL_COMPLETE
      ELSIF URB_Status = HDef.URB_NOTREADY THEN host.Control.state := HDef.CTRL_STATUS_OUT
      ELSIF URB_Status = HDef.URB_ERROR THEN host.Control.state := HDef.CTRL_ERROR
      END
    ELSIF host.Control.state = HDef.CTRL_ERROR THEN
      (*
      After a halt condition is encountered or an error is detected by the
      host, a control endpoint is allowed to recover by accepting the next Setup
      PID; i.e., recovery actions via some other pipe are not required for control
      endpoints. For the Default Control Pipe, a device reset will ultimately be
      required to clear the halt or error condition if the next Setup PID is not
      accepted.
      *)
      INC(host.Control.errorcount);
      IF host.Control.errorcount <= HDef.MAX_ERROR_COUNT THEN
        (* Do the transmission again, starting from SETUP Packet *)
        host.Control.state := HDef.CTRL_SETUP; host.RequestState := HDef.CMD_SEND
      ELSE IF host.User # NIL THEN host.User(host.id, Def.USER_UNRECOVERED_ERROR) END;
        host.Control.errorcount := 0;
        Log.Error("Control error: Device not responding"); Log.ErrorLn;
        (* Free control pipes *)
        Pipes.Free(host, host.Control.pipe_out);
        Pipes.Free(host, host.Control.pipe_in);
        host.gState := Def.IDLE; status := Def.FAIL
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
  PROCEDURE CtlReq*(host: HDef.Handle; VAR buff: Def.Buffer): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.BUSY;
    IF host.RequestState = HDef.CMD_SEND THEN
      (* Start a SETUP transfer *)
      host.Control.length := host.Control.setup.wLength;
      host.Control.state := HDef.CTRL_SETUP;
      host.RequestState := HDef.CMD_WAIT;
    ELSIF host.RequestState = HDef.CMD_WAIT THEN
      status := HandleControl(host, buff);
      IF status IN {Def.OK, HDef.NOT_SUPPORTED} THEN
        (* Transaction completed, move control state to idle *)
        host.RequestState := HDef.CMD_SEND;
        host.Control.state := Def.IDLE;
      ELSIF status = Def.FAIL THEN host.RequestState := HDef.CMD_SEND (* Failure Mode *)
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
  PROCEDURE ClrFeature*(host: HDef.Handle; ep_num: BYTE): BYTE;
    VAR dummy: Def.Buffer;
  BEGIN dummy.size := 0;
    IF host.RequestState = HDef.CMD_SEND THEN
      host.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_ENDPOINT + Def.REQ_TYPE_STANDARD;
      host.Control.setup.bRequest := HDef.REQ_CLEAR_FEATURE;
      host.Control.setup.wValue := FEATURE_SELECTOR_ENDPOINT;
      host.Control.setup.wIndex := ep_num;
      host.Control.setup.wLength := 0
    END

    RETURN CtlReq(host, dummy)
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
  PROCEDURE ParseDevDesc(host: HDef.Handle; VAR dev_desc: HDef.DevDescriptor; VAR buf: HDef.RawDescriptor): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.OK; HDef.Reset(buf);
    dev_desc.bLength := HDef.ReadByte(buf); dev_desc.bDescriptorType := HDef.ReadByte(buf);
    dev_desc.bcdUSB := HDef.ReadHalfword(buf);
    dev_desc.bDeviceClass := HDef.ReadByte(buf); dev_desc.bDeviceSubClass := HDef.ReadByte(buf);
    dev_desc.bDeviceProtocol := HDef.ReadByte(buf); dev_desc.bMaxPacketSize := HDef.ReadByte(buf);
    IF host.device.speed IN {Def.SPEED_HIGH, Def.SPEED_FULL} THEN
      (* Make sure that the max packet size is either 8, 16, 32, 64 or force it to minimum allowed value *)
      IF (dev_desc.bMaxPacketSize # 8) &
        (dev_desc.bMaxPacketSize # 16) &
        (dev_desc.bMaxPacketSize # 32) &
        (dev_desc.bMaxPacketSize # 64) THEN
          (* set the size to min allowed value in case the device has answered with incorrect size *)
          dev_desc.bMaxPacketSize := 8
      END
    ELSIF host.device.speed = Def.SPEED_LOW THEN dev_desc.bMaxPacketSize := 8 (* set the size to 8 for low speed devices *)
    ELSE status := HDef.NOT_SUPPORTED
    END;
    IF (status = Def.OK) & (buf.length > 8) THEN
      (* For 1st time after device connection, Host may issue only 8 bytes for
          Device Descriptor Length  *)
      dev_desc.idVendor := HDef.ReadHalfword(buf); dev_desc.idProduct := HDef.ReadHalfword(buf);
      dev_desc.bcdDevice := HDef.ReadHalfword(buf); dev_desc.iManufacturer := HDef.ReadByte(buf);
      dev_desc.iProduct := HDef.ReadByte(buf); dev_desc.iSerialNumber := HDef.ReadByte(buf);
      dev_desc.bNumConfigurations := HDef.ReadByte(buf);
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
  PROCEDURE ParseEPDesc(host: HDef.Handle; VAR ep_descriptor: HDef.EpDescriptor;
    VAR buf: HDef.RawDescriptor): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.OK;
    ep_descriptor.bLength := HDef.ReadByte(buf);
    ep_descriptor.bDescriptorType := HDef.ReadByte(buf);
    ep_descriptor.bEndpointAddress := HDef.ReadByte(buf);
    ep_descriptor.bmAttributes := TOSET(HDef.ReadByte(buf));
    ep_descriptor.wMaxPacketSize := HDef.ReadHalfword(buf);
    ep_descriptor.bInterval := HDef.ReadByte(buf);
    (* Make sure that wMaxPacketSize is different from 0 *)
    IF (ep_descriptor.wMaxPacketSize = 0) OR
      (ep_descriptor.wMaxPacketSize > HDef.MAX_EP_PACKET_SIZE) OR
      (ep_descriptor.wMaxPacketSize > HDef.MAX_DATA_BUFFER) THEN status := HDef.NOT_SUPPORTED
    END;
    IF host.device.speed = Def.SPEED_HIGH THEN
      IF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_BULK THEN
        IF ep_descriptor.wMaxPacketSize > 512 THEN status := HDef.NOT_SUPPORTED END
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_CTRL THEN
        IF ep_descriptor.wMaxPacketSize > 64 THEN status := HDef.NOT_SUPPORTED END
      (* For high-speed interrupt/isochronous endpoints, bInterval can vary from 1 to 16 *)
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) IN {Def.EP_TYPE_ISOC, Def.EP_TYPE_INTR} THEN
        IF (ep_descriptor.bInterval = 0) OR (ep_descriptor.bInterval > 10H) THEN status := HDef.NOT_SUPPORTED END
      ELSE status := HDef.NOT_SUPPORTED
      END
    ELSIF host.device.speed = Def.SPEED_FULL THEN
      IF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) IN {Def.EP_TYPE_BULK, Def.EP_TYPE_CTRL} THEN
        IF ep_descriptor.wMaxPacketSize > 64 THEN status := HDef.NOT_SUPPORTED END
      (* For full-speed isochronous endpoints, the value of bInterval must be in the range from 1 to 16.*)
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_ISOC THEN
        IF (ep_descriptor.bInterval = 0) OR (ep_descriptor.bInterval > 10H) OR (ep_descriptor.wMaxPacketSize > 64) THEN
          status := HDef.NOT_SUPPORTED
        END
      (* For full-speed interrupt endpoints, the value of bInterval may be from 1 to 255.*)
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_INTR THEN
        IF (ep_descriptor.bInterval = 0) OR (ep_descriptor.wMaxPacketSize > 1023) THEN status := HDef.NOT_SUPPORTED END
      ELSE status := HDef.NOT_SUPPORTED;
      END
    ELSIF host.device.speed = Def.SPEED_LOW THEN
      IF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_CTRL THEN
        IF ep_descriptor.wMaxPacketSize # 8 THEN status := HDef.NOT_SUPPORTED END
      (* For low-speed interrupt endpoints, the value of bInterval may be from 1 to 255.*)
      ELSIF ORD(ep_descriptor.bmAttributes*Def.EP_TYPE_MSK) = Def.EP_TYPE_INTR THEN
        IF (ep_descriptor.bInterval = 0) OR (ep_descriptor.wMaxPacketSize > 8) THEN status := HDef.NOT_SUPPORTED END
      ELSE status := HDef.NOT_SUPPORTED
      END
    ELSE status := HDef.NOT_SUPPORTED;
    END

    RETURN status
  END ParseEPDesc;

  PROCEDURE ParseInterface(host: HDef.Handle; cfg_desc: HDef.CfgDescriptor; VAR if_descriptor: HDef.InterfaceDescriptor;
    VAR buf: HDef.RawDescriptor): BYTE;
    (*feed interface descriptor from buf[index..index+8]*)
    VAR status, ep_ix: BYTE;
  BEGIN status := Def.OK;
    if_descriptor.bLength := HDef.ReadByte(buf);
    (* Make sure that the interface descriptor's bLength is equal to USB_INTERFACE_DESC_SIZE *)
    if_descriptor.bLength := HDef.INTERFACE_DESC_SIZE;
    if_descriptor.bDescriptorType := HDef.ReadByte(buf);
    if_descriptor.bInterfaceNumber := HDef.ReadByte(buf);
    if_descriptor.bAlternateSetting := HDef.ReadByte(buf);
    if_descriptor.bNumEndpoints := HDef.ReadByte(buf);
    if_descriptor.bInterfaceClass := HDef.ReadByte(buf);
    if_descriptor.bInterfaceSubClass := HDef.ReadByte(buf);
    if_descriptor.bInterfaceProtocol := HDef.ReadByte(buf);
    if_descriptor.iInterface := HDef.ReadByte(buf);
    ep_ix := 0;
    WHILE (status = Def.OK) & (ep_ix < Conf.MAX_NUM_ENDPOINTS) &
      (ep_ix < if_descriptor.bNumEndpoints) & HDef.HasMoreHeaders(buf) DO
      HDef.GoNextHeader(buf); (*next descriptor*)
      IF HDef.HeaderType(buf) = HDef.DESC_TYPE_ENDPOINT THEN
        status := ParseEPDesc(host, if_descriptor.Ep_Desc[ep_ix], buf);
        (* Check if the endpoint is appartening to an audio streaming interface *)
        IF (if_descriptor.bInterfaceClass = 1) & (if_descriptor.bInterfaceSubClass IN {2, 3}) THEN
          (* Check if it is supporting the USB AUDIO 01 class specification *)
          IF (if_descriptor.bInterfaceProtocol = 0) THEN if_descriptor.Ep_Desc[ep_ix].bLength := 9 END
        ELSE (* Make sure that the endpoint descriptor's bLength is equal to
           USB_ENDPOINT_DESC_SIZE for all other endpoints types *)
          if_descriptor.Ep_Desc[ep_ix].bLength := HDef.ENDPOINT_DESC_SIZE
        END;
        INC(ep_ix)
      END
    END;
    (* Check if the required endpoint(s) data are parsed *)
    IF ep_ix < if_descriptor.bNumEndpoints THEN status := HDef.NOT_SUPPORTED END

    RETURN status
  END ParseInterface;

  (**
  * @brief  ParseConfig
  *         This procedure parses the configuration descriptor
  * @param  cfg_desc: the destination descriptor record
  * @param  buf: the raw descriptor given by the device
  * @retval None
  *)
  PROCEDURE ParseConfig(VAR cfg_desc: HDef.CfgDescriptor; VAR buf: HDef.RawDescriptor);
  BEGIN
    cfg_desc.bLength := HDef.ReadByte(buf); cfg_desc.bDescriptorType := HDef.ReadByte(buf);
    cfg_desc.wTotalLength := Def.MIN(HDef.ReadHalfword(buf), Conf.MAX_SIZE_CONFIGURATION);
    cfg_desc.bNumInterfaces := HDef.ReadByte(buf); cfg_desc.bConfigurationValue := HDef.ReadByte(buf);
    cfg_desc.iConfiguration := HDef.ReadByte(buf); cfg_desc.bmAttributes := TOSET(HDef.ReadByte(buf));
    cfg_desc.bMaxPower := HDef.ReadByte(buf)
  END ParseConfig;

  (**
  * @brief  USBH_ParseStringDesc
  *         This function Parses the string descriptor
  * @param  psrc: Source pointer containing the descriptor data
  * @param  pdest: Destination address pointer
  * @retval None
  *)
  PROCEDURE ParseStringDesc(psrc: HDef.RawDescriptor; VAR pdest: ARRAY OF CHAR);
    VAR strlength, idx, idd: HALFWORD;
  BEGIN
    (* The UNICODE string descriptor is not NULL-terminated. The string length is
    computed by subtracting two from the value of the first byte of the descriptor.
    *)
    (* Check which is lower size, the Size of string or the length of bytes read
    from the device *)

    IF HDef.HeaderType(psrc) = HDef.DESC_TYPE_STRING THEN
      (* Make sure the Descriptor is String Type *)
      (* psrc[0] contains Size of Descriptor, subtract 2 to get the length of string *)
      IF HDef.HeaderSize(psrc) - 2 <= psrc.length THEN strlength := HDef.HeaderSize(psrc) - 2 ELSE strlength := psrc.length END;
      idd := 0;
      FOR idx := 2 TO strlength BY 2 DO
        (* Copy Only the string and ignore the UNICODE ID, hence add the src *)
        pdest[idd] :=  CHR(psrc.buf[idx]);
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
  PROCEDURE ParseCfgDesc(host: HDef.Handle; VAR buf: HDef.RawDescriptor): BYTE;
    VAR status, if_ix: BYTE;

  BEGIN status := Def.OK; if_ix := 0; HDef.Reset(buf);
    (* Make sure that the Configuration descriptor's bLength is equal to USB_CONFIGURATION_DESC_SIZE *)
    IF HDef.HeaderSize(buf) # HDef.CONFIGURATION_DESC_SIZE THEN
      Log.Error("buggy device: bad configuration length"); Log.ErrorLn; status := HDef.NOT_SUPPORTED
    ELSE ParseConfig(host.device.CfgDesc, buf);
      IF buf.length > HDef.CONFIGURATION_DESC_SIZE THEN
        WHILE (status = Def.OK) & (if_ix < Conf.MAX_NUM_INTERFACES) & HDef.HasMoreHeaders(buf) DO
          HDef.GoNextHeader(buf);
          IF HDef.HeaderType(buf) = HDef.DESC_TYPE_INTERFACE THEN
            status := ParseInterface(host, host.device.CfgDesc, host.device.CfgDesc.Itf_Desc[if_ix], buf);
            INC(if_ix)
          END
        END;
        (* Check if the required interface(s) data are parsed *)
        IF if_ix < Def.MIN(host.device.CfgDesc.bNumInterfaces, Conf.MAX_NUM_INTERFACES) THEN status := HDef.NOT_SUPPORTED END
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
  PROCEDURE GetDescriptor*(host: HDef.Handle; req_type: BYTESET; value_idx: HALFSET; VAR rd: HDef.RawDescriptor): BYTE;
  BEGIN
    IF host.RequestState = HDef.CMD_SEND THEN
      host.Control.setup.bmRequestType := Def.D2H + req_type;
      host.Control.setup.bRequest := HDef.REQ_GET_DESCRIPTOR;
      host.Control.setup.wValue := ORD(value_idx);
      IF value_idx*{8..15} = HDef.DESC_STRING THEN host.Control.setup.wIndex := 0409H (*English/USA language ID*)
      ELSE host.Control.setup.wIndex := 0
      END;
      host.Control.setup.wLength := rd.length;
    END

    RETURN CtlReq(host, rd)
  END GetDescriptor;

  (**
  * @brief  USBH_SetAddress
  *         This command sets the address to the connected device
  * @param  phost: Host Handle
  * @param  DeviceAddress: Device address to assign
  * @retval USBH Status
  *)
  PROCEDURE SetAddress*(host: HDef.Handle; DeviceAddress: BYTE): BYTE;
    VAR dummy: Def.Buffer;
  BEGIN dummy.size := 0;
    IF host.RequestState = HDef.CMD_SEND THEN
      host.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD;
      host.Control.setup.bRequest := HDef.REQ_SET_ADDRESS;
      host.Control.setup.wValue := DeviceAddress;
      host.Control.setup.wIndex := 0;
      host.Control.setup.wLength := 0
    END

    RETURN CtlReq(host, dummy)
  END SetAddress;

  (**
  * @brief  USBH_SetCfg
  *         The command sets the configuration value to the connected device
  * @param  phost: Host Handle
  * @param  cfg_idx: Configuration value
  * @retval USBH Status
  *)
  PROCEDURE SetCfg*(host: HDef.Handle;  cfg_idx: HALFWORD): BYTE;
    VAR dummy: Def.Buffer;
  BEGIN dummy.size := 0;
    IF host.RequestState = HDef.CMD_SEND THEN
      host.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD;
      host.Control.setup.bRequest := HDef.REQ_SET_CONFIGURATION;
      host.Control.setup.wValue := cfg_idx;
      host.Control.setup.wIndex := 0;
      host.Control.setup.wLength := 0
    END

    RETURN CtlReq(host, dummy)
  END SetCfg;

  (**
  * @brief  USBH_SetFeature
  *         The command sets the device features (remote wakeup feature,..)
  * @param  pdev: Selected device
  * @param  itf_idx
  * @retval Status
  *)
  PROCEDURE SetFeature*(host: HDef.Handle; wValue: HALFWORD): BYTE;
    VAR dummy: Def.Buffer;
  BEGIN dummy.size := 0;
    IF host.RequestState = HDef.CMD_SEND THEN
      host.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD;
      host.Control.setup.bRequest := HDef.REQ_SET_FEATURE;
      host.Control.setup.wValue := wValue;
      host.Control.setup.wIndex := 0;
      host.Control.setup.wLength := 0
    END

    RETURN CtlReq(host, dummy)
  END SetFeature;

  (**
  * @brief  USBH_Get_DevDesc
  *         Issue Get Device Descriptor command to the device. Once the response
  *         received, it parses the device descriptor and updates the status.
  * @param  phost: Host Handle
  * @param  length: Length of the descriptor
  * @retval USBH Status
  *)
  PROCEDURE Get_DevDesc*(host: HDef.Handle; length: HALFWORD): BYTE;
    VAR status: BYTE;
  BEGIN
    IF length > host.device.tmprd.size THEN
      Log.Error("Control error: Get Device Descriptor failed, data buffer size issue"); Log.ErrorLn;
      status := HDef.NOT_SUPPORTED
    ELSE host.device.tmprd.length := length;
      status := GetDescriptor(host, Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD,
                      HDef.DESC_DEVICE, host.device.tmprd);
      IF status = Def.OK THEN (* Commands successfully sent and Response Received *)
        status := ParseDevDesc(host, host.device.DevDesc, host.device.tmprd)
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
  PROCEDURE Get_CfgDesc*(host: HDef.Handle; length: HALFWORD): BYTE;
    VAR status: BYTE;
  BEGIN
    IF length > host.device.CfgRaw.size THEN
      Log.Error("Control error: Get configuration Descriptor failed, data buffer size issue"); Log.ErrorLn;
      status := HDef.NOT_SUPPORTED;
    ELSE host.device.CfgRaw.length := length;
      status := GetDescriptor(host, Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD,
                      HDef.DESC_CONFIGURATION, host.device.CfgRaw);
      IF status = Def.OK THEN (* Commands successfully sent and Response Received  *)
        status := ParseCfgDesc(host, host.device.CfgRaw)
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
  PROCEDURE Get_StringDesc*(host: HDef.Handle; string_index: BYTE; VAR buff: ARRAY OF CHAR; length: HALFWORD): BYTE;
    VAR status: BYTE;
  BEGIN
    IF length > host.device.tmprd.size THEN
      Log.Error("Control error: Get String Descriptor failed, data buffer size issue"); Log.ErrorLn;
      status := HDef.NOT_SUPPORTED
    ELSE host.device.tmprd.length := length;
      status := GetDescriptor(host, Def.REQ_RECIPIENT_DEVICE + Def.REQ_TYPE_STANDARD,
                            HDef.DESC_STRING + TOSET(string_index), host.device.tmprd);
      IF status = Def.OK THEN (* Commands successfully sent and Response Received *)
        ParseStringDesc(host.device.tmprd, buff);
      END
    END

    RETURN status
  END Get_StringDesc;

END USBHCtlReq.

OM4Tool.DecObj USBHCtlReq.m4c
