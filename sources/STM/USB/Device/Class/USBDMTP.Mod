MODULE USBDMTP;
  (** ported to Oberon from:
  ******************************************************************************
  * @file    usbd_mtp.c
  * @author  MCD Application Team
  * @brief   This file provides the high layer firmware functions to manage the
  *          following functionalities of the USB MTP Class:
  *           - Initialization and Configuration of high and low layer
  *           - Enumeration as MTP Device (and enumeration for each implemented memory interface)
  *           - OUT/IN data transfer
  *           - Command IN transfer (class requests management)
  *           - Error management
  *
  ******************************************************************************)
  IMPORT SYSTEM, Def := USBDef, DConf := USBDConf, DDef := USBDDef, IoReq := USBDIoReq, CtlReq := USBDCtlReq,
    DH := USBDHal, Opt := USBDMTPOpt, MTPS := USBDMTPStorage;

  CONST
    INTERFACE_CLASS = 6;
    INTERFACE_SUB_CLASS = 1;
    INTERFACE_PROTOCOL = 1;

    CMD_ITF_NBR = 0; (* Command Interface Number 0 *)
    COM_ITF_NBR = 1; (* Communication Interface Number 1 *)

    HS_BINTERVAL = 5;
    FS_BINTERVAL = 10;

    CMD_PACKET_SIZE =  8; (* Control Endpoint Packet size *)

    DATA_MAX_HS_PACKET_SIZE = 512;
    DATA_MAX_FS_PACKET_SIZE = 64; (* Endpoint IN & OUT Packet size *)

  (* MTP class requests *)
    REQ_CANCEL = 64H;
    REQ_GET_EXT_EVENT_DATA = 65H;
    REQ_RESET = 66H;
    REQ_GET_DEVICE_STATUS = 67H;

  (* MTP response code *)
    RESPONSE_OK = 2001H;
    RESPONSE_GENERAL_ERROR = 2002H;
    RESPONSE_PARAMETER_NOT_SUPPORTED = 2006H;
    RESPONSE_INCOMPLETE_TRANSFER = 2007H;
    RESPONSE_INVALID_STORAGE_ID = 2008H;
    RESPONSE_INVALID_OBJECT_HANDLE = 2009H;
    RESPONSE_DEVICEPROP_NOT_SUPPORTED = 200AH;
    RESPONSE_STORE_FULL = 200CH;
    RESPONSE_ACCESS_DENIED = 200FH;
    RESPONSE_STORE_NOT_AVAILABLE = 2013H;
    RESPONSE_SPECIFICATION_BY_FORMAT_NOT_SUPPORTED = 2014H;
    RESPONSE_NO_VALID_OBJECT_INFO = 2015H;
    RESPONSE_DEVICE_BUSY = 2019H;
    RESPONSE_INVALID_PARENT_OBJECT = 201AH;
    RESPONSE_INVALID_PARAMETER = 201DH;
    RESPONSE_SESSION_ALREADY_OPEN = 201EH;
    RESPONSE_TRANSACTION_CANCELLED = 201FH;
    RESPONSE_INVALID_OBJECT_PROP_CODE = 0A801H;
    RESPONSE_SPECIFICATION_BY_GROUP_UNSUPPORTED = 0A807H;
    RESPONSE_OBJECT_PROP_NOT_SUPPORTED = 0A80AH;

  VAR CLASS*: Def.Class;
    CfgDesc, DQDesc: Def.RawDescriptor;

  (**
  * @brief  USBD_MTP_Init
  *         Initialize the MTP interface
  * @param  pdev: device instance
  * @param  cfgidx: Configuration index
  * @retval status
  *)
  PROCEDURE Init(dev: DDef.Handle; cfgidx: BYTE): BYTE;
    VAR ret: BYTE; hmtp!: Opt.Handle;
  BEGIN hmtp := Opt.NewHandle();
    IF hmtp = NIL THEN dev.ClassDataCmsit[dev.classId] := NIL;
      ret := Def.EMEM;
    ELSE (* Setup the pClassData pointer *)
      dev.ClassDataCmsit[dev.classId] := hmtp;
      dev.ClassData := hmtp;
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this class instance */
  MTPInEpAdd  = USBD_CoreGetEPAdd(pdev, USBD_EP_IN, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
  MTPCmdEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_IN, USBD_EP_TYPE_INTR, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
      (* Setup the max packet size according to selected speed *)
      IF dev.speed = Def.SPEED_HIGH THEN
        ASSERT(Opt.GetRxBuffSize() >= DATA_MAX_HS_PACKET_SIZE); hmtp.rx_buff.size := DATA_MAX_HS_PACKET_SIZE
      ELSE 
        ASSERT(Opt.GetRxBuffSize() >= DATA_MAX_FS_PACKET_SIZE); hmtp.rx_buff.size := DATA_MAX_FS_PACKET_SIZE
      END;
      (* Open EP IN *)
      DH.OpenEP(dev, MTPS.InEpAdd, Def.EP_TYPE_BULK, hmtp.rx_buff.size);
      dev.ep_in[MTPS.InEpAdd MOD 10H].is_used := TRUE;
      (* Open EP OUT *)
      DH.OpenEP(dev, MTPS.OutEpAdd, Def.EP_TYPE_BULK, hmtp.rx_buff.size);
      dev.ep_out[MTPS.OutEpAdd MOD 10H].is_used := TRUE;
      (* Open INTR EP IN *)
      DH.OpenEP(dev, MTPS.CmdEpAdd, Def.EP_TYPE_INTR, CMD_PACKET_SIZE);
      dev.ep_in[MTPS.CmdEpAdd MOD 10H].is_used := TRUE;
      (* Init the MTP  layer *)
       MTPS.Init(dev);
      ret := Def.OK
    END

    RETURN ret
  END Init;

  (**
  * @brief  USBD_MTP_DeInit
  *         DeInitialize the MTP layer
  * @param  pdev: device instance
  * @param  cfgidx: Configuration index
  * @retval status
  *)
  PROCEDURE DeInit*(dev: DDef.Handle; cfgidx: BYTE);
  BEGIN
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this MTP class instance */
  MTPInEpAdd  = USBD_CoreGetEPAdd(pdev, USBD_EP_IN, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
  MTPCmdEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_IN, USBD_EP_TYPE_INTR, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    (* Close EP IN *)
    DH.CloseEP(dev, MTPS.InEpAdd);
    dev.ep_in[MTPS.InEpAdd MOD 10H].is_used := FALSE;
    (* Close EP OUT *)
    DH.CloseEP(dev, MTPS.OutEpAdd);
    dev.ep_out[MTPS.OutEpAdd MOD 10H].is_used := FALSE;
    (* Close EP Command *)
    DH.CloseEP(dev,MTPS.CmdEpAdd);
    dev.ep_in[MTPS.CmdEpAdd MOD 10H].is_used := FALSE;
    (* Free MTP Class Resources *)
    IF dev.ClassDataCmsit[dev.classId] # NIL THEN
      (* De-Init the MTP layer *)
      MTPS.DeInit(dev);
      dev.ClassDataCmsit[dev.classId] := NIL;
      dev.ClassData := NIL
    END
  END DeInit;

  (**
  * @brief  USBD_MTP_Setup
  *         Handle the MTP specific requests
  * @param  pdev: instance
  * @param  req: usb requests
  * @retval status
  *)
  PROCEDURE Setup(dev: DDef.Handle; req: Def.Setup): BYTE;
    VAR  ret: BYTE; hmtp!: Opt.Handle; type: SET;
  BEGIN  ret := Def.OK;
    hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this MTP class instance */
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    IF hmtp = NIL THEN ret := Def.FAIL
    ELSE type := req.bmRequestType*Def.REQ_TYPE_MASK;
      IF type = Def.REQ_TYPE_CLASS THEN (* Class request *)
        IF req.bRequest = REQ_CANCEL THEN
          hmtp.rx_buff.length := Def.MIN(hmtp.rx_buff.size, req.wLength);
          IoReq.CtlPrepareRx(dev, hmtp.rx_buff)
        ELSIF req.bRequest = REQ_GET_EXT_EVENT_DATA THEN (*do nothing*)
        ELSIF req.bRequest = REQ_RESET THEN
          (* Stop low layer file system operations if any *)
          MTPS.Cancel(dev, MTPS.PHASE_IDLE);
          hmtp.rx_buff.length := hmtp.rx_buff.size; dev.PrepareReceive(dev, MTPS.OutEpAdd, hmtp.rx_buff)
        ELSIF req.bRequest = REQ_GET_DEVICE_STATUS THEN hmtp.dev_status.length := 0;
          IF hmtp.ResponsePhase = MTPS.READ_DATA THEN
            hmtp.dev_status.length := 4; hmtp.dev_status.val := LSL(RESPONSE_DEVICE_BUSY, 16) + 4
          ELSIF hmtp.ResponsePhase = MTPS.RECEIVE_DATA THEN
            hmtp.dev_status.length := 4; hmtp.dev_status.val := LSL(RESPONSE_TRANSACTION_CANCELLED, 16) + 4
          ELSIF hmtp.ResponsePhase = MTPS.PHASE_IDLE THEN
            hmtp.dev_status.length := 4; hmtp.dev_status.val := LSL(RESPONSE_OK, 16) + 4
          END;
          IoReq.CtlSendData(dev, hmtp.dev_status, hmtp.dev_status.length)
        ELSE CtlReq.CtlError(dev, req); ret := Def.FAIL
        END
      ELSIF type = Def.REQ_TYPE_STANDARD THEN (* Interface & Endpoint request *)
        IF req.bRequest = Def.REQ_GET_INTERFACE THEN
          IF dev.state = DDef.STATE_CONFIGURED THEN
            hmtp.alt_setting.length := 1; hmtp.alt_setting.val := 0; IoReq.CtlSendData(dev, hmtp.alt_setting, hmtp.alt_setting.length)
          END
        ELSIF req.bRequest = Def.REQ_SET_INTERFACE THEN
          IF dev.state # DDef.STATE_CONFIGURED THEN CtlReq.CtlError(dev, req); ret := Def.FAIL END
        ELSIF req.bRequest = Def.REQ_CLEAR_FEATURE THEN (* Re-activate the EP *)
          DH.CloseEP(dev, req.wIndex);
          IF 7 IN TOSET(req.wIndex) THEN DH.OpenEP(dev, req.wIndex, Def.EP_TYPE_BULK, hmtp.rx_buff.size)
          ELSE DH.OpenEP(dev, req.wIndex, Def.EP_TYPE_BULK, hmtp.rx_buff.size)
          END
        END
      END
    END

    RETURN ret
  END Setup;

  (**
  * @brief  USBD_MTP_DataIn
  *         Data sent on non-control IN endpoint
  * @param  pdev: device instance
  * @param  epnum: endpoint number
  * @retval status
  *)
  PROCEDURE DataIn(dev: DDef.Handle; epnum: BYTE);
    VAR hmtp!: Opt.Handle; type: SET;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this MTP class instance */
  MTPInEpAdd  = USBD_CoreGetEPAdd(pdev, USBD_EP_IN, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    IF epnum = MTPS.InEpAdd MOD 80H THEN
      IF hmtp.ResponsePhase = MTPS.RESPONSE_PHASE THEN
        MTPS.SendContainer(dev, MTPS.REP_TYPE);
        (* prepare to receive next operation *)
        hmtp.rx_buff.length := Def.MIN(hmtp.rx_buff.size, dev.request.wLength);
        dev.PrepareReceive(dev, MTPS.OutEpAdd, hmtp.rx_buff);
        hmtp.ResponsePhase := MTPS.PHASE_IDLE
      ELSIF hmtp.ResponsePhase = MTPS.READ_DATA THEN
        MTPS.ReadData(dev);
        (* prepare to receive next operation *)
        hmtp.rx_buff.length := Def.MIN(hmtp.rx_buff.size, dev.request.wLength);
        dev.PrepareReceive(dev, MTPS.InEpAdd, hmtp.rx_buff)
      ELSIF hmtp.ResponsePhase = MTPS.PHASE_IDLE THEN
        (* prepare to receive next operation *)
        hmtp.rx_buff.length := Def.MIN(hmtp.rx_buff.size, dev.request.wLength);
        dev.PrepareReceive(dev, MTPS.OutEpAdd, hmtp.rx_buff)
      END
    END
  END DataIn;

  (**
  * @brief  USBD_MTP_DataOut
  *         Data received on non-control Out endpoint
  * @param  pdev: device instance
  * @param  epnum: endpoint number
  * @retval status
  *)
  PROCEDURE DataOut(dev: DDef.Handle; epnum: BYTE);
    VAR hmtp!: Opt.Handle; type: SET;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this MTP class instance */
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    MTPS.ReceiveOpt(dev);
    IF hmtp.ResponsePhase = MTPS.RESPONSE_PHASE THEN
      IF hmtp.GenericContainer.CLen = Opt.CONT_HEADER_SIZE THEN MTPS.SendContainer(dev, MTPS.REP_TYPE);
        hmtp.ResponsePhase := MTPS.PHASE_IDLE
      ELSE MTPS.SendContainer(dev, MTPS.DATA_TYPE)
      END
    ELSIF hmtp.ResponsePhase = MTPS.READ_DATA THEN MTPS.ReadData(dev)
    ELSIF hmtp.ResponsePhase = MTPS.RECEIVE_DATA THEN MTPS.ReceiveData(dev);
      (* prepare endpoint to receive operations *)
      hmtp.rx_buff.length := dev.request.wLength; dev.PrepareReceive(dev, MTPS.OutEpAdd, hmtp.rx_buff)
    ELSIF hmtp.ResponsePhase = MTPS.PHASE_IDLE THEN
      (* prepare to receive next operation *)
      hmtp.rx_buff.length := dev.request.wLength; dev.PrepareReceive(dev, MTPS.OutEpAdd, hmtp.rx_buff)
    END
  END DataOut;

(*
#ifndef USE_USBD_COMPOSITE
*)
  (**
  * @brief  USBD_MTP_GetHSCfgDesc
  *         Return configuration descriptor
  * @param  speed : current device speed
  * @param  length : pointer data length
  * @retval pointer to descriptor buffer
  *)
  PROCEDURE GetHSCfgDesc(): Def.Buffer;
  BEGIN 
    IF Def.GetEpDesc(CfgDesc^, MTPS.IN_EP) THEN
      Def.PutHalfwordInDescriptorAt(CfgDesc^, 4, DATA_MAX_HS_PACKET_SIZE)
    END;
    IF Def.GetEpDesc(CfgDesc^, MTPS.OUT_EP) THEN
      Def.PutHalfwordInDescriptorAt(CfgDesc^, 4, DATA_MAX_HS_PACKET_SIZE)
    END;
    IF Def.GetEpDesc(CfgDesc^, MTPS.CMD_EP) THEN
      Def.PutByteInDescriptorAt(CfgDesc^, 6, HS_BINTERVAL)
    END;
    Def.Reset(CfgDesc^)

    RETURN CfgDesc
  END GetHSCfgDesc;

  (**
  * @brief  USBD_MTP_GetFSCfgDesc
  *         Return configuration descriptor
  * @param  speed : current device speed
  * @param  length : pointer data length
  * @retval pointer to descriptor buffer
  *)
  PROCEDURE GetFSCfgDesc(): Def.Buffer;
  BEGIN
    IF Def.GetEpDesc(CfgDesc^, MTPS.IN_EP) THEN
      Def.PutHalfwordInDescriptorAt(CfgDesc^, 4, DATA_MAX_FS_PACKET_SIZE)
    END;
    IF Def.GetEpDesc(CfgDesc^, MTPS.OUT_EP) THEN
      Def.PutHalfwordInDescriptorAt(CfgDesc^, 4, DATA_MAX_FS_PACKET_SIZE)
    END;
    IF Def.GetEpDesc(CfgDesc^, MTPS.CMD_EP) THEN
      Def.PutByteInDescriptorAt(CfgDesc^, 6, FS_BINTERVAL)
    END;
    Def.Reset(CfgDesc^)

    RETURN CfgDesc
  END GetFSCfgDesc;

  (**
  * @brief  USBD_MTP_GetDeviceQualifierDescriptor
  *         return Device Qualifier descriptor
  * @param  length : pointer data length
  * @retval pointer to descriptor buffer
  *)
  PROCEDURE GetDeviceQualifierDescriptor(): Def.Buffer;

    RETURN DQDesc
  END GetDeviceQualifierDescriptor;
(*
#endif /* USE_USBD_COMPOSITE  */
*)

  PROCEDURE initCLASS;
    VAR c!: DDef.Class;
  BEGIN NEW(c);
    c.Init := Init;
    c.DeInit := DeInit;
    c.Setup := Setup;
    c.DataIn := DataIn;
    c.DataOut := DataOut;
    c.GetHSConfigDescriptor := GetHSCfgDesc;
    c.GetFSConfigDescriptor := GetFSCfgDesc;
    c.GetOtherSpeedConfigDescriptor := GetFSCfgDesc;
    c.GetDeviceQualifierDescriptor := GetDeviceQualifierDescriptor;
    CLASS := c
  END initCLASS;

BEGIN initCLASS;
(*
#ifndef USE_USBD_COMPOSITE
*)
(* USB MTP device Configuration Descriptor *)
  CfgDesc := Def.NewRawDescriptor();
(*    CONFIG_DESC_SIZ = 39;*)
  Def.PutByte(CfgDesc, Def.LEN_CFG_DESC); (* bLength: Configuration Descriptor size *)
  Def.PutByte(CfgDesc, Def.DESC_TYPE_CONFIGURATION); (* bDescriptorType: Configuration *)
  Def.PutHalfword(CfgDesc, 0); (* wTotalLength: Total size of the Config descriptor computed below*)
  Def.PutByte(CfgDesc, 1); (* bNumInterfaces: 1 interface *)
  Def.PutByte(CfgDesc, 1); (* bConfigurationValue: Configuration value *)
  Def.PutByte(CfgDesc, 0); (* iConfiguration: Index of string descriptor describing the configuration *)
  IF DConf.SELF_POWERED THEN Def.PutByteSet(CfgDesc, {6, 7}) (* bmAttributes: Self Powered according to user configuration *)
  ELSE Def.PutByteSet(CfgDesc, {7}) (* bmAttributes: Bus Powered according to user configuration *)
  END;
  Def.PutByte(CfgDesc, DDef.MAX_POWER); (* MaxPower (mA) *)
  (********************  MTP **** interface ********************)
  Def.PutByte(CfgDesc, Def.LEN_IF_DESC); (* bLength: Interface Descriptor size *)
  Def.PutByte(CfgDesc, Def.DESC_TYPE_INTERFACE); (* bDescriptorType: Interface descriptor type *)
  Def.PutByte(CfgDesc, CMD_ITF_NBR); (* bInterfaceNumber: Number of Interface *)
  Def.PutByte(CfgDesc, 0); (* bAlternateSetting: Alternate setting *)
  Def.PutByte(CfgDesc, 3); (* bNumEndpoints:  *)
  Def.PutByte(CfgDesc, INTERFACE_CLASS); (* bInterfaceClass: bInterfaceClass: MTP uses Still Imaging class*)
  Def.PutByte(CfgDesc, INTERFACE_SUB_CLASS); (* bInterfaceSubClass: still image *)
  Def.PutByte(CfgDesc, INTERFACE_PROTOCOL); (* bInterfaceProtocol: PTP over USB *)
  Def.PutByte(CfgDesc, 0); (* iInterface: no string descriptor*)
  (********************  MTP   Endpoints ********************)
    (*in data*)
  Def.PutByte(CfgDesc, Def.LEN_EP_DESC); (* Endpoint descriptor length = 7 *)
  Def.PutByte(CfgDesc, Def.DESC_TYPE_ENDPOINT); (* Endpoint descriptor type *)
  Def.PutByte(CfgDesc, MTPS.IN_EP); (* Endpoint address (IN, address 1) *)
  Def.PutByte(CfgDesc, Def.EP_TYPE_BULK); (* Bulk endpoint type *)
  Def.PutHalfword(CfgDesc, DATA_MAX_FS_PACKET_SIZE); (*maximum packet size*)
  Def.PutByte(CfgDesc, 0); (* Polling interval in milliseconds *)
    (*out data*)
  Def.PutByte(CfgDesc, Def.LEN_EP_DESC); (* Endpoint descriptor length = 7 *)
  Def.PutByte(CfgDesc, Def.DESC_TYPE_ENDPOINT); (* Endpoint descriptor type *)
  Def.PutByte(CfgDesc, MTPS.OUT_EP); (* Endpoint address (OUT, address 1) *)
  Def.PutByte(CfgDesc, Def.EP_TYPE_BULK); (* Bulk endpoint type *)
  Def.PutHalfword(CfgDesc, DATA_MAX_FS_PACKET_SIZE); (*maximum packet size*)
  Def.PutByte(CfgDesc, 0); (* Polling interval in milliseconds *)
    (*events*)
  Def.PutByte(CfgDesc, Def.LEN_EP_DESC); (* Endpoint descriptor length = 7 *)
  Def.PutByte(CfgDesc, Def.DESC_TYPE_ENDPOINT); (* Endpoint descriptor type *)
  Def.PutByte(CfgDesc, MTPS.CMD_EP); (* bEndpointAddress: Endpoint Address *)
  Def.PutByte(CfgDesc, Def.EP_TYPE_INTR); (* bmAttributes: Interrupt endpoint *)
  Def.PutHalfword(CfgDesc, CMD_PACKET_SIZE);
  Def.PutByte(CfgDesc, FS_BINTERVAL); (* Polling interval in milliseconds *)
    (*put total size in wTotalLength*)
  Def.Reset(CfgDesc^); Def.PutHalfwordInDescriptorAt(CfgDesc^, 2, CfgDesc.length);
  Def.CheckCfgDescriptor(CfgDesc^);

(* USB Standard Device Descriptor *)
  DQDesc := Def.NewRawDescriptor();
  Def.PutByte(DQDesc, Def.LEN_DQ_DESC);
  Def.PutByte(DQDesc, Def.DESC_TYPE_DEVICE_QUALIFIER);
  Def.PutHalfword(DQDesc, 200H);
  Def.PutByte(DQDesc, 0);
  Def.PutByte(DQDesc, 0);
  Def.PutByte(DQDesc, 0);
  Def.PutByte(DQDesc, 64);
  Def.PutByte(DQDesc, 1);
  Def.PutByte(DQDesc, 0)
(*
#endif /* USE_USBD_COMPOSITE  */
*)

END USBDMTP.

OM4Tool.DecObj USBDMTP.m4c
