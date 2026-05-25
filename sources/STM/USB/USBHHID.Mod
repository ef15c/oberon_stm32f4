MODULE USBHHID;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   This file is the HID Layer Handlers for USB Host HID class.
  *
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
  * @verbatim
  *
  *          ===================================================================
  *                                HID Class  Description
  *          ===================================================================
  *           This module manages the HID class V1.11 following the "Device Class Definition
  *           for Human Interface Devices (HID) Version 1.11 Jun 27, 2001".
  *           This driver implements the following aspects of the specification:
  *             - The Boot Interface Subclass
  *             - The Mouse and Keyboard protocols
  *
  *  @endverbatim
  *
  ******************************************************************************
  *)
  IMPORT SYSTEM, Conf := USBHConf, Def := USBHDef, IoReq := USBHIoReq, Pipes := USBHPipes, HCl := USBHHIDClass,
    Keybd := USBHHIDKeybd, Mouse := USBHHIDMouse, CtlReq := USBHCtlReq, USBH, Log := USBLog;

  VAR CLASS*: Def.Class;

  (**
  * @brief  USBH_ParseHIDDesc
  *         This function Parse the HID descriptor
  * @param  desc: HID Descriptor
  * @param  buf: Buffer where the source descriptor is available
  * @retval None
  *)
  PROCEDURE ParseHIDDesc(VAR desc: HCl.DescriptorDesc; buf: ARRAY OF BYTE);
    VAR phead!: Def.DescHeader; phiddesc!: HCl.Descriptor; CfgDescLen, ptr: HALFWORD; done: BOOLEAN;
  BEGIN phead := SYSTEM.VAL(Def.DescHeader, SYSTEM.ADR(buf));
    CfgDescLen := Def.LE16(buf, 2);
    IF CfgDescLen > Def.CONFIGURATION_DESC_SIZE THEN
      ptr := Def.LEN_CFG_DESC; done := FALSE;
      WHILE ~done & (ptr < CfgDescLen) DO phead := CtlReq.GetNextDesc(phead, ptr);
        IF phead.bDescriptorType = Def.DESC_TYPE_HID THEN phiddesc := SYSTEM.VAL(HCl.Descriptor, phead);
          desc := phiddesc^; done := TRUE
        END
      END
    END
  END ParseHIDDesc;

  (**
  * @brief  USBH_Get_HID_ReportDescriptor
  *         Issue report Descriptor command to the device. Once the response
  *         received, parse the report descriptor and update the status.
  * @param  phost: Host handle
  * @param  Length : HID Report Descriptor Length
  * @retval USBH Status
  *)
  PROCEDURE GetHIDReportDescriptor(phost: Def.Handle; length: HALFWORD): BYTE;
    VAR status: BYTE;
  BEGIN
    IF length > LEN(phost.device.Data.buf) THEN Log.Error("Control error: Get HID Report Descriptor failed, data buffer size issue");
      status := Def.NOT_SUPPORTED
    ELSE status := CtlReq.GetDescriptor(phost, Def.REQ_RECIPIENT_INTERFACE + Def.REQ_TYPE_STANDARD,
                              Def.DESC_HID_REPORT, phost.device.Data.buf, length)
    END
    (* HID report descriptor is available in phost->device.Data.
    In case of USB Boot Mode devices for In report handling ,
    HID report descriptor parsing is not required.
    In case, for supporting Non-Boot Protocol devices and output reports,
    user may parse the report descriptor*)

    RETURN status
  END  GetHIDReportDescriptor;

  (**
  * @brief  USBH_Set_Idle
  *         Set Idle State.
  * @param  phost: Host handle
  * @param  duration: Duration for HID Idle request
  * @param  reportId : Targeted report ID for Set Idle request
  * @retval USBH Status
  *)
  PROCEDURE SetIdle*(phost: Def.Handle; duration, reportId: BYTE): BYTE;
    VAR dummy: ARRAY 0 OF BYTE;
  BEGIN phost.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_INTERFACE + Def.REQ_TYPE_CLASS;
    phost.Control.setup.bRequest := HCl.SET_IDLE;
    phost.Control.setup.wValue := duration*100H + reportId;
    phost.Control.setup.wIndex := 0; phost.Control.setup.wLength := 0

    RETURN CtlReq.CtlReq(phost, dummy, 0)

  END SetIdle;

  (**
  * @brief  USBH_Set_Protocol
  *         Set protocol State.
  * @param  phost: Host handle
  * @param  protocol : Set Protocol for HID : boot/report protocol
  * @retval USBH Status
  *)
  PROCEDURE SetProtocol*(phost: Def.Handle; protocol: BYTE): BYTE;
    VAR dummy: ARRAY 0 OF BYTE;
  BEGIN phost.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_INTERFACE + Def.REQ_TYPE_CLASS;
    phost.Control.setup.bRequest := HCl.SET_PROTOCOL;
    IF protocol # 0 THEN phost.Control.setup.wValue := 0 ELSE phost.Control.setup.wValue := 1 END;
    phost.Control.setup.wIndex := 0; phost.Control.setup.wLength := 0

    RETURN CtlReq.CtlReq(phost, dummy, 0)
  END SetProtocol;

  (**
  * @brief  USBH_HID_GetReport
  *         retrieve Set Report
  * @param  phost: Host handle
  * @param  reportType  : Report type to be sent
  * @param  reportId    : Targeted report ID for Set Report request
  * @param  reportBuff  : Report Buffer
  * @param  reportLen   : Length of data report to be send
  * @retval USBH Status
  *)
  PROCEDURE GetReport(phost: Def.Handle; reportType, reportId: BYTE; VAR reportBuff: ARRAY OF BYTE; reportLen: BYTE): BYTE;
  BEGIN phost.Control.setup.bmRequestType := Def.D2H + Def.REQ_RECIPIENT_INTERFACE + Def.REQ_TYPE_CLASS;
    phost.Control.setup.bRequest := HCl.GET_REPORT;
    phost.Control.setup.wValue := reportType*100H + reportId;
    phost.Control.setup.wIndex := 0; phost.Control.setup.wLength := reportLen

    RETURN CtlReq.CtlReq(phost, reportBuff, reportLen)
  END GetReport;

  (**
  * @brief  USBH_HID_FifoWrite
  *         Write To FIFO.
  * @param  f: Fifo address
  * @param  buf: read buffer
  * @param  nbytes: number of item to write
  * @retval number of written items
  *)
  PROCEDURE FifoWrite*(VAR f: HCl.FIFODesc; buf: ARRAY OF BYTE; nbytes: HALFWORD): HALFWORD;
    VAR i: HALFWORD;
  BEGIN
    IF ~f.lock THEN f.lock := TRUE; i := 0;
      WHILE (i < nbytes) & (f.head + 1 # f.tail) & ((f.head + 1 # f.size) OR (f.tail # 0)) DO
        f.buf.buf[f.head] := buf[i]; INC(f.head);
        IF f.head = f.size THEN f.head := 0 END;
        INC(i)
      END
    END;
    f.lock := FALSE

    RETURN i
  END FifoWrite;

  (**
  * @brief  USBH_HID_InterfaceInit
  *         The function init the HID class.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE InterfaceInit(phost: Def.Handle): BYTE;
    VAR interface, status: BYTE; hidh!: HCl.Handle;
      max_ep, num: BYTE; ep_mps: HALFWORD;
  BEGIN status := Def.OK;
    interface := USBH.FindInterface(phost, phost.pActiveClass.ClassCode, HCl.BOOT_CODE, 0FFH);
    IF interface = 0FFH THEN (* No Valid Interface *)
      Log.DebugString("Cannot Find the interface for "); Log.DebugString(phost.pActiveClass.Name);
      Log.Debug(" class.");
      status := Def.FAIL
    END;
    IF status # Def.FAIL THEN status := USBH.SelectInterface(phost, interface); END;
    IF status # Def.FAIL THEN NEW(hidh); phost.pActiveClass.pData := hidh;
      IF hidh = NIL THEN Log.Debug("Cannot allocate memory for HID Handle");
        status := Def.FAIL
      END
    END;
    IF status # Def.FAIL THEN hidh.state := HCl.ERROR;
      (*Decode Bootclass Protocol: Mouse or Keyboard*)
      IF phost.device.CfgDesc.Itf_Desc[interface].bInterfaceProtocol = HCl.KEYBRD_BOOT_CODE THEN
        Log.User("KeyBoard device found!"); hidh.Init := Keybd.Init
      ELSIF phost.device.CfgDesc.Itf_Desc[interface].bInterfaceProtocol  = HCl.MOUSE_BOOT_CODE THEN
        Log.User("Mouse device found!"); hidh.Init := Mouse.Init
      ELSE Log.User("Protocol not supported."); status := Def.FAIL
      END
    END;
    IF status # Def.FAIL THEN
      hidh.state := HCl.INIT;
      hidh.ctl_state := HCl.REQ_INIT;
      hidh.ep_addr := phost.device.CfgDesc.Itf_Desc[interface].Ep_Desc[0].bEndpointAddress;
      hidh.length := phost.device.CfgDesc.Itf_Desc[interface].Ep_Desc[0].wMaxPacketSize;
      hidh.poll := phost.device.CfgDesc.Itf_Desc[interface].Ep_Desc[0].bInterval;
      IF hidh.poll < HCl.MIN_POLL THEN hidh.poll := HCl.MIN_POLL END;
      (* Check of available number of endpoints *)
      (* Find the number of EPs in the Interface Descriptor *)
      (* Choose the lower number in order not to overrun the buffer allocated *)
      IF phost.device.CfgDesc.Itf_Desc[interface].bNumEndpoints < Conf.MAX_NUM_ENDPOINTS THEN
        max_ep := phost.device.CfgDesc.Itf_Desc[interface].bNumEndpoints
      ELSE max_ep := Conf.MAX_NUM_ENDPOINTS
      END;
      (* Decode endpoint IN and OUT address from interface descriptor *)
      FOR num := 0 TO max_ep - 1 DO
        IF 7 IN TOSET(phost.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].bEndpointAddress) THEN
          hidh.InEp := phost.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].bEndpointAddress;
          hidh.InPipe := Pipes.Alloc(phost, hidh.InEp);
          ep_mps := phost.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].wMaxPacketSize;
          (* Open pipe for IN endpoint *)
          Pipes.Open(phost, hidh.InPipe, hidh.InEp, phost.device.address, phost.device.speed,
            Def.EP_TYPE_INTR, ep_mps);
          phost.SetToggle(phost, hidh.InPipe, FALSE)
        ELSE
          hidh.OutEp := phost.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].bEndpointAddress;
          hidh.OutPipe := Pipes.Alloc(phost, hidh.OutEp);
          ep_mps := phost.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].wMaxPacketSize;
          (* Open pipe for OUT endpoint *)
          Pipes.Open(phost, hidh.OutPipe, hidh.OutEp, phost.device.address, phost.device.speed,
            Def.EP_TYPE_INTR, ep_mps);
            phost.SetToggle(phost, hidh.OutPipe, FALSE)
        END
      END
    END

    RETURN status
  END InterfaceInit;

  (**
  * @brief  USBH_HID_InterfaceDeInit
  *         The function DeInit the Pipes used for the HID class.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE InterfaceDeInit(phost: Def.Handle): BYTE;
    VAR hidh!: HCl.Handle; res: BYTE;
  BEGIN hidh := phost.pActiveClass.pData(HCl.Handle);
    IF hidh.InPipe # 0 THEN Pipes.Close(phost, hidh.InPipe); Pipes.Free(phost, hidh.InPipe);
      hidh.InPipe := 0 (* Reset the pipe as Free *)
    END;
    IF hidh.OutPipe # 0 THEN Pipes.Close(phost, hidh.OutPipe); Pipes.Free(phost, hidh.OutPipe);
      hidh.OutPipe := 0; (* Reset the pipe as Free *)
    END;
    IF phost.pActiveClass.pData # NIL THEN phost.pActiveClass.pData := NIL END;
    res := Def.OK;

    RETURN res
  END InterfaceDeInit;

  (**
  * @brief  USBH_HID_ClassRequest
  *         The function is responsible for handling Standard requests
  *         for HID class.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE ClassRequest(phost: Def.Handle): BYTE;
    VAR status, classReqStatus: BYTE; hidh!: HCl.Handle;
  BEGIN status := Def.BUSY; classReqStatus := Def.BUSY;
    hidh := phost.pActiveClass.pData(HCl.Handle);
    (* Switch HID state machine *)
    IF hidh.ctl_state IN {HCl.REQ_INIT, HCl.REQ_GET_HID_DESC} THEN
      ParseHIDDesc(hidh.HID_Desc, phost.device.CfgDesc_Raw);
      hidh.ctl_state := HCl.REQ_GET_REPORT_DESC;
    ELSIF hidh.ctl_state = HCl.REQ_GET_REPORT_DESC THEN
      (* Get Report Desc *)
      classReqStatus := GetHIDReportDescriptor(phost, hidh.HID_Desc.wItemLength);
      IF classReqStatus = Def.OK THEN (* The descriptor is available in phost.device.Data *)
        hidh.ctl_state := HCl.REQ_SET_IDLE;
      ELSIF classReqStatus = Def.NOT_SUPPORTED THEN
        Log.Error("Control error: HID: Device Get Report Descriptor request failed");
        status := Def.FAIL
      END
    ELSIF hidh.ctl_state = HCl.REQ_SET_IDLE THEN
      classReqStatus := SetIdle(phost, 0, 0); (* set Idle *)
      IF classReqStatus IN {Def.OK, Def.NOT_SUPPORTED} THEN hidh.ctl_state := HCl.REQ_SET_PROTOCOL END
    ELSIF hidh.ctl_state = HCl.REQ_SET_PROTOCOL THEN
      classReqStatus := SetProtocol(phost, 0); (* set protocol *)
      IF classReqStatus = Def.OK THEN hidh.ctl_state := HCl.REQ_IDLE;
        phost.pUser(phost, USBH.USER_CLASS_ACTIVE); (* all requests performed *)
        status := Def.OK;
      ELSIF classReqStatus = Def.NOT_SUPPORTED THEN
        Log.Error("Control error: HID: Device Set protocol request failed");
        status := Def.FAIL
      END
    END

    RETURN status
  END ClassRequest;

  (**
  * @brief  USBH_HID_Process
  *         The function is for managing state machine for HID data transfers
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Process(phost: Def.Handle): BYTE;
    VAR status: BYTE; hidh!: HCl.Handle; XferSize, fcnt: INTEGER;
  BEGIN status := Def.OK;
    hidh := phost.pActiveClass.pData(HCl.Handle);
    IF hidh.state = HCl.INIT THEN status := hidh.Init(phost);
      IF status = Def.OK THEN hidh.state := HCl.IDLE
      ELSE Log.Error("HID Class Init failed");
        hidh.state := HCl.ERROR; status := Def.FAIL
      END
    ELSIF hidh.state = HCl.IDLE THEN status := GetReport(phost, 1, 0, hidh.pData, hidh.length);
      IF status = Def.OK THEN hidh.state := HCl.SYNC
      ELSIF status = Def.BUSY THEN hidh.state := HCl.IDLE; status := Def.OK
      ELSIF status = Def.NOT_SUPPORTED THEN hidh.state := HCl.SYNC; status := Def.OK
      ELSE hidh.state := HCl.ERROR; status := Def.FAIL
      END
    ELSIF hidh.state = HCl.SYNC THEN
      (* Sync with start of Even Frame *)
      IF ODD(phost.Timer) THEN hidh.state := HCl.GET_DATA END
    ELSIF hidh.state = HCl.GET_DATA THEN IoReq.InterruptReceiveData(phost, SYSTEM.ADR(hidh.pData), hidh.length, hidh.InPipe);
      hidh.state := HCl.POLL; hidh.timer := phost.Timer; hidh.DataReady := TRUE;
    ELSIF hidh.state = HCl.POLL THEN
      IF phost.GetURBState(phost, hidh.InPipe) = Def.URB_DONE THEN
        XferSize := phost.GetLastXferSize(phost, hidh.InPipe);
        IF ~hidh.DataReady & (XferSize # 0) & (hidh.fifo.buf # NIL) THEN
          fcnt := FifoWrite(hidh.fifo, hidh.pData, hidh.length);
          hidh.DataReady := TRUE;
          IF hidh.EventCallback # NIL THEN hidh.EventCallback(phost) END;
        END
      ELSIF phost.GetURBState(phost, hidh.InPipe) = Def.URB_STALL THEN (* IN Endpoint Stalled *)
        (* Issue Clear Feature on interrupt IN endpoint *)
        IF CtlReq.ClrFeature(phost, hidh.ep_addr) = Def.OK THEN hidh.state := HCl.GET_DATA END (* Change state to issue next IN token *)
      END
    END

    RETURN status
  END Process;

  (**
  * @brief  USBH_HID_SOFProcess
  *         The function is for managing the SOF Process
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE SOFProcess(phost: Def.Handle): BYTE;
    VAR status: BYTE; hidh!: HCl.Handle;
  BEGIN hidh := phost.pActiveClass.pData(HCl.Handle);
    IF (hidh.state = HCl.POLL) & (phost.Timer - hidh.timer >= hidh.poll) THEN hidh.state := HCl.GET_DATA END;
    status := Def.OK

    RETURN status
  END SOFProcess;

BEGIN NEW(CLASS);
  CLASS.Name := "HID";
  CLASS.ClassCode := HCl.CLASS;
  CLASS.Init := InterfaceInit;
  CLASS.DeInit := InterfaceDeInit;
  CLASS.Requests := ClassRequest;
  CLASS.BgndProcess := Process;
  CLASS.SOFProcess := SOFProcess
END USBHHID.
