MODULE USBH;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   USB host library
  ******************************************************************************
  *)

  IMPORT SYSTEM, Kernel, Conf := USBHConf, Log:= USBLog, Def := USBDef, UC := HALUC, H := USBHal,
    HDef := USBHDef,  HCD := HALHCD, HH := USBHHal, Pipes := USBHPipes, IoReq := USBHIoReq, CtlReq := USBHCtlReq;

  CONST
    USER_SELECT_CONFIGURATION* = 1;
    USER_CLASS_ACTIVE* = 2;
    USER_CLASS_SELECTED* = 3;
    USER_CONNECTION* = 4;
    USER_DISCONNECTION* = 5;
    USER_UNRECOVERED_ERROR* = 6;

  VAR processTask: Def.Task;

  (**
  * @brief  DeInitStateMachine
  *         De-Initialize the Host state machine.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE DeInitStateMachine(host: HDef.Handle);
  BEGIN
    CLEAR(host.Pipes); (* Clear Pipes flags*)

    host.gState := Def.IDLE;
    host.EnumState := Def.IDLE;
    host.RequestState := HDef.CMD_SEND;
    host.Timer := 0;

    host.Control.state := HDef.CTRL_SETUP;
    host.Control.pipe_size := HDef.MPS_DEFAULT;
    host.Control.errorcount := 0;

    host.device.address := HDef.ADDRESS_DEFAULT;
    host.device.speed := Def.SPEED_FULL;
    host.device.RstCnt := 0;
    host.device.EnumCnt := 0;

    (* Reset the device record *)
    CLEAR(host.device.CfgRaw.buf);
    CLEAR(host.device.tmprd.buf);
    CLEAR(host.device.DevDesc);
    CLEAR(host.device.CfgDesc);
  END DeInitStateMachine;

  (**
  * @brief  USBH_RegisterClass
  *         Link class driver to Host Core.
  * @param  phost : Host Handle
  * @param  pclass: Class handle
  * @retval USBH Status
  *)
  PROCEDURE RegisterClass*(host: Def.Handle; class: Def.Class): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.OK;
    CASE host OF
      HDef.Handle:
        IF class # NIL THEN
          IF host.ClassNumber < Conf.MAX_NUM_SUPPORTED_CLASS THEN
            host.Class[host.ClassNumber] := class(HDef.Class); INC(host.ClassNumber) (* link the class to the USB Host handle *)
          ELSE Log.Error("Max Class Number reached"); Log.ErrorLn; status := Def.FAIL
          END
        ELSE Log.Error("Invalid Class handle"); Log.ErrorLn; status := Def.FAIL
        END;
        Log.Flush
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN status
  END RegisterClass;

  (**
  * @brief  USBH_FindInterface
  *         Find the interface index for a specific class.
  * @param  phost: Host Handle
  * @param  Class: Class code
  * @param  SubClass: SubClass code
  * @param  Protocol: Protocol code
  * @retval interface index in the configuration structure
  * @note : (1)interface index 0xFF means interface index not found
  *)
  PROCEDURE FindInterface*(host: Def.Handle; Class, SubClass, Protocol: BYTE): BYTE;
    VAR if_ix: BYTE;
  BEGIN if_ix := 0;
    CASE host OF
      HDef.Handle:
        WHILE (if_ix < Conf.MAX_NUM_INTERFACES) &
          ~(((host.device.CfgDesc.Itf_Desc[if_ix].bInterfaceClass = Class) OR (Class = 0FFH)) &
            ((host.device.CfgDesc.Itf_Desc[if_ix].bInterfaceSubClass = SubClass) OR (SubClass = 0FFH)) &
            ((host.device.CfgDesc.Itf_Desc[if_ix].bInterfaceProtocol = Protocol) OR (Protocol = 0FFH)))
        DO INC(if_ix);
        END;
        IF if_ix >= Conf.MAX_NUM_INTERFACES THEN if_ix := 0FFH END
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN  if_ix
  END FindInterface;

  (**
  * @brief  USBH_SelectInterface
  *         Select current interface.
  * @param  phost: Host Handle
  * @param  interface: Interface number
  * @retval USBH Status
  *)
  PROCEDURE SelectInterface*(host: Def.Handle; interface: BYTE): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.OK;
    CASE host OF
      HDef.Handle:
        IF interface < host.device.CfgDesc.bNumInterfaces THEN
          host.device.current_interface := interface;
          Log.Debug("Switching to Interface (#"); Log.DebugInt(interface, 1); Log.DebugString(")"); Log.DebugLn;
          Log.UserString("Class    : "); Log.UserHexVLen(host.device.CfgDesc.Itf_Desc[interface].bInterfaceClass, 2, FALSE); Log.User("h");
          Log.UserString("SubClass : "); Log.UserHexVLen(host.device.CfgDesc.Itf_Desc[interface].bInterfaceSubClass, 2, FALSE); Log.User("h");
          Log.UserString("Protocol : "); Log.UserHexVLen(host.device.CfgDesc.Itf_Desc[interface].bInterfaceProtocol, 2, FALSE); Log.User("h");
        ELSE Log.Error("Cannot Select This Interface."); Log.ErrorLn;
          status := Def.FAIL
        END;
        Log.Flush
    | Def.Handle: ASSERT(FALSE)
    END

    RETURN status
  END SelectInterface;

  (**
  * @brief  USBH_Start
  *         Start the USB Host Core.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE Start*(host: Def.Handle);
  BEGIN
    CASE host OF
      HDef.Handle:
        HH.Start(host); (* Start the low level driver  *)
        H.DriverVBUS(host, TRUE); (* Activate VBUS on the port *)
        Log.Flush
    | Def.Handle: ASSERT(FALSE)
    END
  END Start;

  PROCEDURE VBUSOff*(host: Def.Handle);
  BEGIN
    (* DeActivate VBUS on the port *)
    H.DriverVBUS(host(HDef.Handle), FALSE)
  END VBUSOff;
  
  (**
  * @brief  USBH_Stop
  *         Stop the USB Host Core.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE Stop*(host: Def.Handle);
  BEGIN
    CASE host OF
      HDef.Handle:
        (* DeActivate VBUS on the port *)
        H.DriverVBUS(host, FALSE);
        (* Stop and cleanup the low level driver *)
        HH.Stop(host);
        (* Free Control Pipes *)
        Pipes.Free(host, host.Control.pipe_in);
        Pipes.Free(host, host.Control.pipe_out);
        Log.Flush
    | Def.Handle: ASSERT(FALSE)
    END
  END Stop;

  (**
  * @brief  HCD_IsPortEnabled
  *         Is Port Enabled
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE IsPortEnabled*(host: Def.Handle): BOOLEAN;

    RETURN host(HDef.Handle).device.PortEnabled
  END IsPortEnabled;

  (**
  * @brief  HCD_ReEnumerate
  *         Perform a new Enumeration phase.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE ReEnumerate*(id: BYTE);
    VAR host!: HDef.Handle;
  BEGIN host := Def.usbCores[id](HDef.Handle);
    IF IsPortEnabled(host) THEN host.device.is_ReEnumerated := TRUE;
      Stop(host); host.device.is_disconnected := TRUE
    END
  END ReEnumerate;

  (**
  * @brief  USBH_HandleEnum
  *         This function includes the complete enumeration process
  * @param  phost: Host Handle
  * @retval USBH_Status
  *)
  PROCEDURE HandleEnum(host: HDef.Handle): BYTE;
    VAR Status, ReqStatus: BYTE; str: ARRAY 0FFH OF CHAR;
  BEGIN Status := Def.BUSY; ReqStatus := Def.BUSY;
    IF host.EnumState = Def.IDLE THEN
      (* Get Device Desc for only 1st 8 bytes : To get EP0 MaxPacketSize *)
      ReqStatus := CtlReq.Get_DevDesc(host, 8);
      IF ReqStatus = Def.OK THEN
        host.Control.pipe_size := host.device.DevDesc.bMaxPacketSize;
        host.EnumState := HDef.ENUM_GET_FULL_DEV_DESC;
        (* modify control channels configuration for MaxPacket size *)
        Pipes.Open(host, host.Control.pipe_in, 80H, host.device.address,
          host.device.speed, IoReq.EP_CONTROL, host.Control.pipe_size);
        (* Open Control pipes *)
        Pipes.Open(host, host.Control.pipe_out, 0, host.device.address,
          host.device.speed, IoReq.EP_CONTROL, host.Control.pipe_size);
      ELSIF ReqStatus = HDef.NOT_SUPPORTED THEN Log.Error("Control error: Get Device Descriptor request failed"); Log.ErrorLn;
        INC(host.device.EnumCnt);
        IF host.device.EnumCnt > 3 THEN (* Buggy Device can't complete get device desc request *)
          Log.User("Control error, Device not Responding Please unplug the Device.");
          host.gState := HDef.HOST_ABORT_STATE
        ELSE (* free control pipes *)
          Pipes.Free(host, host.Control.pipe_out); Pipes.Free(host, host.Control.pipe_in);
          host.gState := Def.IDLE (* Reset the USB Device *)
        END
      END
    ELSIF host.EnumState = HDef.ENUM_GET_FULL_DEV_DESC THEN
      (* Get FULL Device Desc  *)
      ReqStatus := CtlReq.Get_DevDesc(host, HDef.DEVICE_DESC_SIZE);
      IF ReqStatus = Def.OK THEN
        Log.UserString("PID: "); Log.UserHexVLen(host.device.DevDesc.idProduct, 4, FALSE); Log.User("h");
        Log.UserString("VID: "); Log.UserHexVLen(host.device.DevDesc.idVendor, 4, FALSE); Log.User("h");
        host.EnumState := HDef.ENUM_SET_ADDR
      ELSIF ReqStatus = HDef.NOT_SUPPORTED THEN
        Log.Error("Control error: Get Full Device Descriptor request failed"); Log.ErrorLn;
        INC(host.device.EnumCnt);
        IF host.device.EnumCnt > 3 THEN (* Buggy Device can't complete get device desc request *)
          Log.User("Control error, Device not Responding Please unplug the Device.");
          host.gState := HDef.HOST_ABORT_STATE
        ELSE (* Free control pipes *)
          Pipes.Free(host, host.Control.pipe_out); Pipes.Free(host, host.Control.pipe_in);
          host.EnumState := Def.IDLE; host.gState := Def.IDLE (* Reset the attached USB device *)
        END
      END
    ELSIF host.EnumState = HDef.ENUM_SET_ADDR THEN
      (* set address *)
      ReqStatus := CtlReq.SetAddress(host, HDef.DEVICE_ADDRESS);
      IF ReqStatus = Def.OK THEN
        Kernel.Delayms(2); host.device.address := HDef.DEVICE_ADDRESS;
        (* user callback for device address assigned *)
        Log.Debug("Address (#"); Log.DebugInt(host.device.address, 1); Log.DebugString(") assigned."); Log.DebugLn;
        host.EnumState := HDef.ENUM_GET_CFG_DESC;
        (* modify control channels to update device address *)
        Pipes.Open(host, host.Control.pipe_in, 80H, host.device.address,
          host.device.speed, IoReq.EP_CONTROL, host.Control.pipe_size);
        (* Open Control pipes *)
        Pipes.Open(host, host.Control.pipe_out, 0, host.device.address,
          host.device.speed, IoReq.EP_CONTROL, host.Control.pipe_size)
      ELSIF ReqStatus = HDef.NOT_SUPPORTED THEN
        Log.Error("Control error: Device Set Address request failed"); Log.ErrorLn;
        (* Buggy Device can't complete get device desc request *)
        Log.User("Control error, Device not Responding Please unplug the Device.");
        host.gState := HDef.HOST_ABORT_STATE; host.EnumState := Def.IDLE;
      END
    ELSIF host.EnumState = HDef.ENUM_GET_CFG_DESC THEN
      (* get standard configuration descriptor *)
      ReqStatus := CtlReq.Get_CfgDesc(host, HDef.CONFIGURATION_DESC_SIZE);
      IF ReqStatus = Def.OK THEN host.EnumState := HDef.ENUM_GET_FULL_CFG_DESC;
        Log.Debug("wTotalLength: "); Log.DebugInt(host.device.CfgDesc.wTotalLength, 1); Log.DebugLn
      ELSIF ReqStatus = HDef.NOT_SUPPORTED THEN
        Log.Error("Control error: Get Device configuration descriptor request failed"); Log.ErrorLn;
        INC(host.device.EnumCnt);
        IF host.device.EnumCnt > 3 THEN
          (* Buggy Device can't complete get device desc request *)
          Log.User("Control error, Device not Responding Please unplug the Device.");
          host.gState := HDef.HOST_ABORT_STATE
        ELSE (* Free control pipes *)
          Pipes.Free(host, host.Control.pipe_out); Pipes.Free(host, host.Control.pipe_in);
          host.EnumState := Def.IDLE; host.gState := Def.IDLE; (* Reset the USB Device *)
        END
      END
    ELSIF host.EnumState = HDef.ENUM_GET_FULL_CFG_DESC THEN
      (* get FULL config descriptor (config, interface, endpoints) *)
      ReqStatus := CtlReq.Get_CfgDesc(host, host.device.CfgDesc.wTotalLength);
      IF ReqStatus = Def.OK THEN host.EnumState := HDef.ENUM_GET_MFC_STRING_DESC
      ELSIF ReqStatus = HDef.NOT_SUPPORTED THEN
        Log.Error("Control error: Get Device full configuration descriptor request failed");
        INC(host.device.EnumCnt);
        IF host.device.EnumCnt > 3 THEN (* Buggy Device can't complete get device desc request *)
          Log.User("Control error, Device not Responding Please unplug the Device.");
          host.gState := HDef.HOST_ABORT_STATE
        ELSE (* Free control pipes *)
          Pipes.Free(host, host.Control.pipe_out); Pipes.Free(host, host.Control.pipe_in);
          host.EnumState := Def.IDLE; host.gState := Def.IDLE (* Reset the USB Device *)
        END
      END
    ELSIF host.EnumState = HDef.ENUM_GET_MFC_STRING_DESC THEN
      IF host.device.DevDesc.iManufacturer # 0 THEN
        (* Check that Manufacturer String is available *)
        ReqStatus := CtlReq.Get_StringDesc(host, host.device.DevDesc.iManufacturer, str, LEN(str));
        IF ReqStatus = Def.OK THEN (* User callback for Manufacturing string *)
          Log.UserString("Manufacturer : "); Log.User(str);
          host.EnumState := HDef.ENUM_GET_PRODUCT_STRING_DESC
        ELSIF ReqStatus = HDef.NOT_SUPPORTED THEN
          Log.User("Manufacturer : N/A"); host.EnumState := HDef.ENUM_GET_PRODUCT_STRING_DESC
        END
      ELSE Log.User("Manufacturer : N/A"); host.EnumState := HDef.ENUM_GET_PRODUCT_STRING_DESC
      END
    ELSIF host.EnumState = HDef.ENUM_GET_PRODUCT_STRING_DESC THEN
      IF host.device.DevDesc.iProduct # 0 THEN
        (* Check that Product string is available *)
        ReqStatus := CtlReq.Get_StringDesc(host, host.device.DevDesc.iProduct, str, LEN(str));
        IF ReqStatus = Def.OK THEN (* User callback for Product string *)
          Log.UserString("Product : "); Log.User(str);
          host.EnumState := HDef.ENUM_GET_SERIALNUM_STRING_DESC;
        ELSIF ReqStatus = HDef.NOT_SUPPORTED THEN
          Log.User("Product : N/A"); host.EnumState := HDef.ENUM_GET_SERIALNUM_STRING_DESC
        END
      ELSE Log.User("Product : N/A"); host.EnumState := HDef.ENUM_GET_SERIALNUM_STRING_DESC
      END
    ELSIF host.EnumState = HDef.ENUM_GET_SERIALNUM_STRING_DESC THEN
      IF host.device.DevDesc.iSerialNumber # 0 THEN
        (* Check that Serial number string is available *)
        ReqStatus := CtlReq.Get_StringDesc(host, host.device.DevDesc.iSerialNumber, str, LEN(str));
        IF ReqStatus = Def.OK THEN (* User callback for Serial number string *)
          Log.UserString("Serial Number : "); Log.User(str); Status := Def.OK
        ELSIF ReqStatus = HDef.NOT_SUPPORTED THEN
          Log.User("Serial Number : N/A"); Status := Def.OK
        END
      ELSE Log.User("Serial Number : N/A"); Status := Def.OK
      END
    END

    RETURN Status
  END HandleEnum;

  (**
  * @brief  USBH_Process
  *         Background process of the USB Core.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE ProcessHost(host: Def.Handle);
    VAR status, idx: BYTE;
  BEGIN
    CASE host OF HDef.Handle:
      HH.ProcessDeferredIRQWork(host); (*do the deferred job triggered by interrupts*)
      status := Def.FAIL;
      (* check for Host pending port disconnect event *)
      IF host.device.is_disconnected THEN host.gState := HDef.HOST_DEV_DISCONNECTED END;
      IF host.gState = Def.IDLE THEN
        IF host.device.is_connected THEN Log.User("USB Device Connected");
          (* Wait for 200 ms after connection *)
          host.gState := HDef.HOST_DEV_WAIT_FOR_ATTACHMENT;
          Kernel.Delayms(200); HH.ResetPort(host);
          (* Make sure to start with Default address *)
          host.device.address := HDef.ADDRESS_DEFAULT; host.Timeout := 0;
        END
      ELSIF host.gState = HDef.HOST_DEV_WAIT_FOR_ATTACHMENT THEN (* Wait for Port Enabled *)
        IF host.device.PortEnabled THEN Log.Debug("USB Device Reset Completed"); Log.DebugLn;
          host.device.RstCnt := 0; host.gState := HDef.HOST_DEV_ATTACHED
        ELSIF host.Timeout > HDef.DEV_RESET_TIMEOUT THEN INC(host.device.RstCnt);
          IF host.device.RstCnt > 3 THEN (* Buggy Device can't complete reset *)
            Log.User("USB Reset Failed, Please unplug the Device.");
            host.gState := HDef.HOST_ABORT_STATE
          ELSE host.gState := Def.IDLE
          END
        ELSE INC(host.Timeout, 10); Kernel.Delayms(10)
        END
      ELSIF host.gState = HDef.HOST_DEV_ATTACHED THEN
        IF host.User # NIL THEN host.User(host.id, USER_CONNECTION) END;
        Kernel.Delayms(100); (* Wait for 100 ms after Reset *)
        host.device.speed := HH.GetSpeed(host);
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      phost->NakTimeout = USBH_NAK_SOF_COUNT;
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
        host.gState := HDef.HOST_ENUMERATION;
        host.Control.pipe_out := Pipes.Alloc(host, 0);
        host.Control.pipe_in  := Pipes.Alloc(host, 80H);
        (* Open Control pipes *)
        Pipes.Open(host, host.Control.pipe_in, 80H, host.device.address, host.device.speed,
          IoReq.EP_CONTROL, host.Control.pipe_size);
        Pipes.Open(host, host.Control.pipe_out, 0, host.device.address, host.device.speed,
          IoReq.EP_CONTROL, host.Control.pipe_size);
      ELSIF host.gState = HDef.HOST_ENUMERATION THEN
        (* Check for enumeration status *)
        status := HandleEnum(host);
        IF status = Def.OK THEN
          (* The function shall return USBH_OK when full enumeration is complete *)
          Log.Debug("Enumeration done."); Log.DebugLn; host.device.current_interface := 0;
          IF host.device.DevDesc.bNumConfigurations = 1 THEN
            Log.Debug("This device has only 1 configuration."); Log.DebugLn; host.gState := HDef.HOST_SET_CONFIGURATION
          ELSE host.gState := HDef.HOST_INPUT
          END
        END
      ELSIF host.gState = HDef.HOST_INPUT THEN
        (* user callback for end of device basic enumeration *)
        IF host.User # NIL THEN
          host.User(host.id, Def.USER_SELECT_CONFIGURATION);
          host.gState := HDef. HOST_SET_CONFIGURATION
        END
      ELSIF host.gState = HDef.HOST_SET_CONFIGURATION THEN
        (* set configuration *)
        IF CtlReq.SetCfg(host, host.device.CfgDesc.bConfigurationValue) = Def.OK THEN
          host.gState := HDef.HOST_SET_WAKEUP_FEATURE;
          Log.Debug("Configuration set."); Log.DebugLn;
        END
      ELSIF host.gState = HDef.HOST_SET_WAKEUP_FEATURE THEN
        IF HDef.REMOTE_WAKEUP IN host.device.CfgDesc.bmAttributes THEN
          status := CtlReq.SetFeature(host, CtlReq.FEATURE_SELECTOR_REMOTEWAKEUP);
          IF status = Def.OK THEN Log.Debug("Device remote wakeup enabled"); Log.DebugLn;
            host.gState := HDef.HOST_CHECK_CLASS;
          ELSIF status = HDef.NOT_SUPPORTED THEN Log.User("Remote wakeup not supported by the device");
            host.gState := HDef.HOST_CHECK_CLASS;
          END
        ELSE host.gState := HDef.HOST_CHECK_CLASS
        END
      ELSIF host.gState = HDef.HOST_CHECK_CLASS THEN
        IF host.ClassNumber = 0 THEN Log.User("No Class has been registered.")
        ELSE host.ActiveClass := NIL; idx := 0;
          WHILE (host.ActiveClass = NIL) & (idx < Conf.MAX_NUM_SUPPORTED_CLASS) DO
            IF host.Class[idx].ClassCode = host.device.CfgDesc.Itf_Desc[0].bInterfaceClass THEN
              host.ActiveClass := host.Class[idx];
            END;
            INC(idx)
          END;
          IF host.ActiveClass # NIL THEN
            IF host.ActiveClass.Init(host) = Def.OK THEN
              host.gState := HDef.HOST_CLASS_REQUEST;
              Log.Debug(host.ActiveClass.Name); Log.DebugString(" class started."); Log.DebugLn;
              (* Inform user that a class has been activated *)
              IF host.User # NIL THEN host.User(host.id, Def.USER_CLASS_SELECTED) END
            ELSE host.gState := HDef.HOST_ABORT_STATE;
              Log.UserString("Device not supporting "); Log.UserString(host.ActiveClass.Name); Log.User(" class.");
            END
          ELSE host.gState := HDef.HOST_ABORT_STATE;
            Log.User("No registered class for this device.")
          END
        END
      ELSIF host.gState = HDef.HOST_CLASS_REQUEST THEN
        (* process class standard control requests state machine *)
        IF host.ActiveClass # NIL THEN status := host.ActiveClass.Requests(host);
          IF status = Def.OK THEN host.gState := HDef.HOST_CLASS;
            Log.Debug("Class request successful"); Log.DebugLn;
          ELSIF status = Def.FAIL THEN host.gState := HDef.HOST_ABORT_STATE;
            Log.Error("Device not responding Please Unplug.")
          END
        ELSE host.gState := HDef.HOST_ABORT_STATE; Log.Error("Invalid Class Driver.")
        END
      ELSIF host.gState = HDef.HOST_CLASS THEN
        (* process class state machine *)
        IF host.ActiveClass # NIL THEN status := host.ActiveClass.BgndProcess(host) END
      ELSIF host.gState = HDef.HOST_DEV_DISCONNECTED THEN
        host.device.is_disconnected := FALSE; DeInitStateMachine(host);
        (* Re-Initilaize Host for new Enumeration *)
        IF host.ActiveClass # NIL THEN status := host.ActiveClass.DeInit(host); host.ActiveClass := NIL END;
        IF host.User # NIL THEN host.User(host.id, Def.USER_DISCONNECTION) END;
        Log.User("USB Device disconnected");
        IF host.device.is_ReEnumerated THEN host.device.is_ReEnumerated := FALSE;
          Start(host) (* Start the host and re-enable Vbus *)
        ELSE HH.Start(host) (* Device Disconnection Completed, start USB Driver *)
        END
      END;
      Log.Flush
    END
  END ProcessHost;

  PROCEDURE Process;
    VAR i: BYTE;
  BEGIN
    FOR i := 0 TO Def.NB_OTG_CORES - 1 DO
      IF Def.usbCores[i] # NIL THEN ProcessHost(Def.usbCores[i]) END
    END
  END Process;

  (**
  * @brief  USBH_Init
  *         Initialize the HOST Core.
  * @param  pcd: Contoller Driver Handle
  * @param  pUsrFunc: User Callback
  * @retval USBH Status
  *)
  PROCEDURE Init*(core: Def.Handle; id: BYTE): Def.Handle;
    VAR host!: HDef.Handle;
  BEGIN host := HH.Init(core, id);
    Log.Debug("Controller IRQ Handler: "); Log.DebugHexVLen(ORD(host.ControllerIRQHandler), 8, FALSE);
    Log.DebugLn; Log.Flush;
    IF host # NIL THEN
      host.ActiveClass := NIL; (* Unlink class*)
      host.ClassNumber := 0;
      DeInitStateMachine(host); (* Restore default states and prepare EP0 *)
      (* Restore default Device connection states *)
      host.device.PortEnabled := FALSE;
      host.device.is_connected := FALSE;
      host.device.is_disconnected := FALSE;
      host.device.is_ReEnumerated := FALSE;
      IF processTask = NIL THEN (*install USB core process task*)
        processTask := Def.NewTask(Process, 5); Def.Install(processTask)
      END
    END

    RETURN host
  END Init;

  (**
  * @brief  HCD_DeInit
  *         De-Initialize the Host portion of the driver.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE DeInit*(host: Def.Handle);
  BEGIN
    CASE host OF
      HDef.Handle:
        IF host # NIL THEN
          DeInitStateMachine(host);
          (* Restore default Device connection states *)
          host.device.PortEnabled := FALSE;
          host.device.is_connected := FALSE;
          host.device.is_disconnected := FALSE;
          host.device.is_ReEnumerated := FALSE;
          host.device.RstCnt := 0;
          host.device.EnumCnt := 0;
          IF HCD.GetState(host(HCD.Handle)) = HCD.STATE_STARTED THEN HH.Stop(host) END;
          HH.DeInit(host);
          IF processTask # NIL THEN Def.Remove(processTask); processTask := NIL END;
          Log.Flush
        END
    | Def.Handle: ASSERT(FALSE)
    END
  END DeInit;

END USBH.
 
OM4Tool.DecObj USBH.m4c

OM4Tool.DecSym USBH.sm4
