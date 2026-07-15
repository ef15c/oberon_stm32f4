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
  IMPORT SYSTEM, BSP, Conf := USBHConf, Def := USBDef, HDef := USBHDef, IoReq := USBHIoReq,
    Pipes := USBHPipes, HCl := USBHHIDClass, Keybd := USBHHIDKeybd, Mouse := USBHHIDMouse,
    CtlReq := USBHCtlReq, USBH, Log := USBLog;

  CONST
    MOUSE* = 1;
    KEYBOARD* = 2;
    UNKNOWN* = 0FFH;

  VAR CLASS*: Def.Class;

  (**
  * @brief  USBH_ParseHIDDesc
  *         This function Parse the HID descriptor
  * @param  desc: HID Descriptor
  * @param  buf: Buffer where the source descriptor is available
  * @retval None
  *)
  PROCEDURE ParseHIDDesc(VAR desc: HCl.DescriptorDesc; VAR rd: HDef.RawDescriptor);
    VAR done: BOOLEAN;
  BEGIN HDef.Reset(rd); done := FALSE;
(* Keyboard:
DEBUG: configuration descriptor: (59)
  09  02  3B  00  02  01  00  A0  32 Configuration descriptor: length 59 bytes, 2 interfaces, config 1, string index 0, bus powered and remote wakeup, 100 mA
  09  04  00  00  01  03  01  01  00 Interface descriptor: inteface 0, alt setting 0, 1 endpoint, class 3, subclass 1, protocol 1, string index 0
  09  21  11  01  00  01  22  36  00 HID descriptor: release 1.11, country 0, 1 HID class descriptor to follow, report descriptor type 22h, desc length 54 bytes
  07  05  81  03  08  00  0A         Endpoint descriptor: endpoint IN address 1, interrupt, max packet size 8 bytes, polling interval 10 frames
  09  04  01  00  01  03  00  00  00 Interface descriptor: interface 1, alt setting 0, 1 endpoint, class 3, subclass 0, protocol 0, string index 0
  09  21  11  01  00  01  22  34  00 HID descriptor: release 1.11, country 0, 1 HID class descriptor to follow, report descriptor type 22h, desc length 52 bytes
  07  05  82  03  03  00  0A         Endpoint descriptor: endpoint IN address 2, interrupt, max packet size 3 bytes, polling interval 10 frames

    Mouse
DEBUG: configuration descriptor: (34)
  09  02  22  00  01  01  00  A0  19  Configuration descriptor: length 34 bytes, 1 interface, config 1, index 0, bus powered and remote wakeup, 50 mA
  09  04  00  00  01  03  01  02  00  Interface descriptor: interface 0, alt setting 0, 1 endpoint, class 3, subclass 1, protocol 2, string index 0
  09  21  10  01  00  01  22  44  00  HID descriptor: release 1.10, country 0, 1 HID class descriptor to follow, report descriptor type 22h, desc length 68 bytes
  07  05  81  03  04  00  0A         Endpoint descriptor: endpoint IN address 1, interrupt, max packet size 4 bytes, polling interval 10 frames
*)
    Log.Debug("configuration descriptor: "); Log.DebugBuf(rd.buf, rd.length); Log.DebugLn; Log.Flush;
    WHILE ~done & HDef.HasMoreHeaders(rd) DO HDef.GoNextHeader(rd);
      IF HDef.HeaderType(rd) = HDef.DESC_TYPE_HID THEN
        desc.bLength := HDef.ReadByte(rd); desc.bDescriptorType := HDef.ReadByte(rd);
        desc.bcdHID := HDef.ReadHalfword(rd); desc.bCountryCode := HDef.ReadByte(rd);
        desc.bNumDescriptors := HDef.ReadByte(rd); desc.bReportDescriptorType := HDef.ReadByte(rd);
        desc.wItemLength := HDef.ReadHalfword(rd);
        done := TRUE
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
  PROCEDURE GetHIDReportDescriptor(host: HDef.Handle; VAR rd: HDef.RawDescriptor): BYTE;
    VAR status: BYTE;
  BEGIN
    IF rd.length > rd.size THEN Log.Error("Control error: Get HID Report Descriptor failed, data buffer size issue"); Log.ErrorLn;
      status := HDef.NOT_SUPPORTED
    ELSE status := CtlReq.GetDescriptor(host, Def.REQ_RECIPIENT_INTERFACE + Def.REQ_TYPE_STANDARD,
                              HDef.DESC_HID_REPORT, rd)
    END
    (* HID report descriptor is available in rd.buf.
    In case of USB Boot Mode devices for In report handling ,
    HID report descriptor parsing is not required.
    In case, for supporting Non-Boot Protocol devices and output reports,
    user may parse the report descriptor*)

    RETURN status
  END  GetHIDReportDescriptor;

  (**
  * @brief  USBH_HID_GetDeviceType
  *         Return Device function.
  * @param  id: the USB core id
  * @retval HID function: HID_MOUSE / HID_KEYBOARD
  *)
  PROCEDURE GetDeviceType*(id: BYTE): BYTE;
    VAR type, InterfaceProtocol: BYTE; host!: HDef.Handle;
  BEGIN type := UNKNOWN; host := Def.usbCores[id](HDef.Handle);
    IF host.gState = HDef.HOST_CLASS THEN
      InterfaceProtocol := host.device.CfgDesc.Itf_Desc[host.device.current_interface].bInterfaceProtocol;
      IF InterfaceProtocol = HCl.KEYBRD_BOOT_CODE THEN type := KEYBOARD
      ELSIF InterfaceProtocol = HCl.MOUSE_BOOT_CODE THEN type := MOUSE
      END
    END

    RETURN type
  END GetDeviceType;


  (**
  * @brief  USBH_Set_Idle
  *         Set Idle State.
  * @param  phost: Host handle
  * @param  duration: Duration for HID Idle request
  * @param  reportId : Targeted report ID for Set Idle request
  * @retval USBH Status
  *)
  PROCEDURE SetIdle*(host: Def.Handle; duration, reportId: BYTE): BYTE;
    VAR dummy: Def.Buffer;
  BEGIN dummy.size := 0;
    CASE host OF
      HDef.Handle:
        host.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_INTERFACE + Def.REQ_TYPE_CLASS;
        host.Control.setup.bRequest := HCl.SET_IDLE;
        host.Control.setup.wValue := duration*100H + reportId;
        host.Control.setup.wIndex := 0; host.Control.setup.wLength := 0
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN CtlReq.CtlReq(host(HDef.Handle), dummy)
  END SetIdle;

  (**
  * @brief  USBH_Set_Protocol
  *         Set protocol State.
  * @param  phost: Host handle
  * @param  protocol : Set Protocol for HID : boot/report protocol
  * @retval USBH Status
  *)
  PROCEDURE SetProtocol*(host: Def.Handle; protocol: BYTE): BYTE;
    VAR dummy: Def.Buffer;
  BEGIN dummy.size := 0;
    CASE host OF
      HDef.Handle:
        host.Control.setup.bmRequestType := Def.H2D + Def.REQ_RECIPIENT_INTERFACE + Def.REQ_TYPE_CLASS;
        host.Control.setup.bRequest := HCl.SET_PROTOCOL;
        IF protocol # 0 THEN host.Control.setup.wValue := 0 ELSE host.Control.setup.wValue := 1 END;
        host.Control.setup.wIndex := 0; host.Control.setup.wLength := 0
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN CtlReq.CtlReq(host(HDef.Handle), dummy)
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
  PROCEDURE GetReport(host: HDef.Handle; reportType, reportId: BYTE; VAR reportBuff: Def.Buffer; reportLen: BYTE): BYTE;
  BEGIN host.Control.setup.bmRequestType := Def.D2H + Def.REQ_RECIPIENT_INTERFACE + Def.REQ_TYPE_CLASS;
    host.Control.setup.bRequest := HCl.GET_REPORT;
    host.Control.setup.wValue := reportType*100H + reportId;
    host.Control.setup.wIndex := 0; host.Control.setup.wLength := reportLen

    RETURN CtlReq.CtlReq(host, reportBuff)
  END GetReport;

  (**
  * @brief  USBH_HID_InterfaceInit
  *         The function init the HID class.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE InterfaceInit(host: Def.Handle): BYTE;
    VAR interface, status: BYTE; hidh!: HCl.Handle;
      max_ep, num: BYTE; ep_mps: HALFWORD;
  BEGIN status := Def.OK;
    CASE host OF
      HDef.Handle:
        interface := USBH.FindInterface(host, host.ActiveClass.ClassCode, HCl.BOOT_CODE, 0FFH);
        IF interface = 0FFH THEN (* No Valid Interface *)
          Log.Debug("Cannot Find the interface for "); Log.DebugString(host.ActiveClass.Name);
          Log.DebugString(" class."); Log.DebugLn;
          status := Def.FAIL
        END;
        IF status # Def.FAIL THEN status := USBH.SelectInterface(host, interface); END;
        IF status # Def.FAIL THEN hidh := HCl.New(); host.ActiveClass.clsh := hidh;
          IF hidh = NIL THEN Log.Debug("Cannot allocate memory for HID Handle"); Log.DebugLn;
            status := Def.FAIL
          END
        END;
        IF status # Def.FAIL THEN hidh.state := HCl.ERROR;
          (*Decode Bootclass Protocol: Mouse or Keyboard*)
          IF host.device.CfgDesc.Itf_Desc[interface].bInterfaceProtocol = HCl.KEYBRD_BOOT_CODE THEN
            Log.User("KeyBoard device found!"); hidh.Init := Keybd.Init
          ELSIF host.device.CfgDesc.Itf_Desc[interface].bInterfaceProtocol  = HCl.MOUSE_BOOT_CODE THEN
            Log.User("Mouse device found!"); hidh.Init := Mouse.Init
          ELSE Log.User("Protocol not supported."); status := Def.FAIL
          END
        END;
        IF status # Def.FAIL THEN
          hidh.state := HCl.INIT;
          hidh.ctl_state := HCl.REQ_INIT;
          hidh.ep_addr := host.device.CfgDesc.Itf_Desc[interface].Ep_Desc[0].bEndpointAddress;
          hidh.length := host.device.CfgDesc.Itf_Desc[interface].Ep_Desc[0].wMaxPacketSize;
          hidh.poll := host.device.CfgDesc.Itf_Desc[interface].Ep_Desc[0].bInterval;
          IF hidh.poll < HCl.MIN_POLL THEN hidh.poll := HCl.MIN_POLL END;
          (* Check of available number of endpoints *)
          (* Find the number of EPs in the Interface Descriptor *)
          (* Choose the lower number in order not to overrun the buffer allocated *)
          IF host.device.CfgDesc.Itf_Desc[interface].bNumEndpoints < Conf.MAX_NUM_ENDPOINTS THEN
            max_ep := host.device.CfgDesc.Itf_Desc[interface].bNumEndpoints
          ELSE max_ep := Conf.MAX_NUM_ENDPOINTS
          END;
          (* Decode endpoint IN and OUT address from interface descriptor *)
          FOR num := 0 TO max_ep - 1 DO
            IF 7 IN TOSET(host.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].bEndpointAddress) THEN
              hidh.InEp := host.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].bEndpointAddress;
              hidh.InPipe := Pipes.Alloc(host, hidh.InEp);
              ep_mps := host.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].wMaxPacketSize;
              (* Open pipe for IN endpoint *)
              Pipes.Open(host, hidh.InPipe, hidh.InEp, host.device.address, host.device.speed,
                Def.EP_TYPE_INTR, ep_mps);
              host.SetToggle(host, hidh.InPipe, FALSE)
            ELSE
              hidh.OutEp := host.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].bEndpointAddress;
              hidh.OutPipe := Pipes.Alloc(host, hidh.OutEp);
              ep_mps := host.device.CfgDesc.Itf_Desc[interface].Ep_Desc[num].wMaxPacketSize;
              (* Open pipe for OUT endpoint *)
              Pipes.Open(host, hidh.OutPipe, hidh.OutEp, host.device.address, host.device.speed,
                Def.EP_TYPE_INTR, ep_mps);
                host.SetToggle(host, hidh.OutPipe, FALSE)
            END
          END
        END
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN status
  END InterfaceInit;

  (**
  * @brief  USBH_HID_InterfaceDeInit
  *         The function DeInit the Pipes used for the HID class.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE InterfaceDeInit(host: Def.Handle): BYTE;
    VAR hidh!: HCl.Handle; res: BYTE;
  BEGIN
    CASE host OF
      HDef.Handle:
        hidh := host.ActiveClass.clsh(HCl.Handle);
        IF hidh.InPipe # 0 THEN Pipes.Close(host, hidh.InPipe); Pipes.Free(host, hidh.InPipe);
          hidh.InPipe := 0 (* Reset the pipe as Free *)
        END;
        IF hidh.OutPipe # 0 THEN Pipes.Close(host, hidh.OutPipe); Pipes.Free(host, hidh.OutPipe);
          hidh.OutPipe := 0; (* Reset the pipe as Free *)
        END;
        IF host.ActiveClass.clsh # NIL THEN host.ActiveClass.clsh := NIL END;
        res := Def.OK
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN res
  END InterfaceDeInit;

  (**
  * @brief  USBH_HID_ClassRequest
  *         The function is responsible for handling Standard requests
  *         for HID class.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE ClassRequest(host: Def.Handle): BYTE;
    VAR status, classReqStatus: BYTE; hidh!: HCl.Handle;
  BEGIN status := Def.BUSY; classReqStatus := Def.BUSY;
    CASE host OF
      HDef.Handle:
        hidh := host.ActiveClass.clsh(HCl.Handle);
        (* Switch HID state machine *)
        IF hidh.ctl_state IN {HCl.REQ_INIT, HCl.REQ_GET_HID_DESC} THEN
          ParseHIDDesc(hidh.HID_Desc, host.device.CfgRaw);
          hidh.ctl_state := HCl.REQ_GET_REPORT_DESC;
        ELSIF hidh.ctl_state = HCl.REQ_GET_REPORT_DESC THEN
          (* Get Report Desc *)
          hidh.ReportDesc.length := hidh.HID_Desc.wItemLength;
          classReqStatus := GetHIDReportDescriptor(host, hidh.ReportDesc);
          IF classReqStatus = Def.OK THEN (* The descriptor is available in phost.pActiveClass.pData.ReportDesc *)
            hidh.ctl_state := HCl.REQ_SET_IDLE;
          ELSIF classReqStatus = HDef.NOT_SUPPORTED THEN
            Log.Error("Control error: HID: Device Get Report Descriptor request failed"); Log.ErrorLn;
            status := Def.FAIL
          END
        ELSIF hidh.ctl_state = HCl.REQ_SET_IDLE THEN
          classReqStatus := SetIdle(host, 0, 0); (* set Idle *)
          IF classReqStatus IN {Def.OK, HDef.NOT_SUPPORTED} THEN hidh.ctl_state := HCl.REQ_SET_PROTOCOL END
        ELSIF hidh.ctl_state = HCl.REQ_SET_PROTOCOL THEN
          classReqStatus := SetProtocol(host, 0); (* set protocol *)
          IF classReqStatus = Def.OK THEN hidh.ctl_state := HCl.REQ_IDLE;
            IF host.User # NIL THEN host.User(host.id, USBH.USER_CLASS_ACTIVE) END; (* all requests performed *)
            status := Def.OK;
            Log.Debug("Class active"); Log.DebugLn
          ELSIF classReqStatus = HDef.NOT_SUPPORTED THEN
            Log.Error("Control error: HID: Device Set protocol request failed"); Log.ErrorLn;
            status := Def.FAIL
          END
        END
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN status
  END ClassRequest;

  (**
  * @brief  USBH_HID_Process
  *         The function is for managing state machine for HID data transfers
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Process(host: Def.Handle): BYTE;
    VAR status: BYTE; hidh!: HCl.Handle; XferSize, fcnt: INTEGER;
  BEGIN status := Def.OK;
    CASE host OF
      HDef.Handle:
        hidh := host.ActiveClass.clsh(HCl.Handle);
        IF hidh.state = HCl.INIT THEN status := hidh.Init(host);
          IF status = Def.OK THEN hidh.state := HCl.IDLE
          ELSE Log.Error("HID Class Init failed"); Log.ErrorLn;
            hidh.state := HCl.ERROR; status := Def.FAIL
          END
        ELSIF hidh.state = HCl.IDLE THEN status := GetReport(host, 1, 0, hidh.Data, hidh.length);
          IF status = Def.OK THEN hidh.state := HCl.SYNC; Log.Debug("GetReport successful"); Log.DebugLn
          ELSIF status = Def.BUSY THEN hidh.state := HCl.IDLE; status := Def.OK
          ELSIF status = HDef.NOT_SUPPORTED THEN hidh.state := HCl.SYNC; status := Def.OK
          ELSE hidh.state := HCl.ERROR; status := Def.FAIL
          END
        ELSIF hidh.state = HCl.SYNC THEN
          (* Sync with start of Even Frame *)
          IF ODD(host.Timer) THEN hidh.state := HCl.GET_DATA; Log.Debug("in odd frame"); Log.DebugLn END
        ELSIF hidh.state = HCl.GET_DATA THEN IoReq.InterruptReceiveData(host, hidh.Data, hidh.length, hidh.InPipe);
          hidh.state := HCl.POLL; hidh.timer := host.Timer; hidh.DataReady := FALSE
        ELSIF hidh.state = HCl.POLL THEN
          IF host.GetURBState(host, hidh.InPipe) = HDef.URB_DONE THEN
            XferSize := host.GetLastXferSize(host, hidh.InPipe);
            IF ~hidh.DataReady & (XferSize # 0) THEN
              fcnt := HCl.FifoWrite(hidh.fifo, hidh.Data.buf, hidh.length);
              hidh.DataReady := TRUE;
              IF hidh.EventCallback # NIL THEN hidh.EventCallback(host) END;
            END
          ELSIF host.GetURBState(host, hidh.InPipe) = HDef.URB_STALL THEN (* IN Endpoint Stalled *)
            (* Issue Clear Feature on interrupt IN endpoint *)
            IF CtlReq.ClrFeature(host, hidh.ep_addr) = Def.OK THEN hidh.state := HCl.GET_DATA END (* Change state to issue next IN token *)
          END
        END
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN status
  END Process;

  (**
  * @brief  USBH_HID_SOFProcess
  *         The function is for managing the SOF Process
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE SOFProcess(host: Def.Handle): BYTE;
    VAR status: BYTE; hidh!: HCl.Handle;
  BEGIN 
    CASE host OF
      HDef.Handle: hidh := host.ActiveClass.clsh(HCl.Handle);
        IF (hidh.state = HCl.POLL) & (host.Timer - hidh.timer >= hidh.poll) THEN
          hidh.state := HCl.GET_DATA
        END;
        status := Def.OK
      | Def.Handle: ASSERT(FALSE)
    END

    RETURN status
  END SOFProcess;

  PROCEDURE init(): Def.Class;
    VAR c!: HDef.Class;
  BEGIN NEW(c);
    c.Name := "HID";
    c.ClassCode := HCl.CLASS;
    c.Init := InterfaceInit;
    c.DeInit := InterfaceDeInit;
    c.Requests := ClassRequest;
    c.BgndProcess := Process;
    c.SOFProcess := SOFProcess

    RETURN c
  END init;

BEGIN CLASS := init()
END USBHHID.

OM4Tool.DecSym USBHHID.sm4
