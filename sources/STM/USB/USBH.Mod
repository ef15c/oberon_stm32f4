MODULE USBH;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   USB host library
  ******************************************************************************
  *)

  IMPORT SYSTEM, Kernel, Conf := USBHConf, Log:= USBLog, Def := USBHDef, UH := USBHHal,
    Pipes := USBHPipes, IoReq := USBHIoReq, CtlReq := USBHCtlReq;

  CONST
    USER_SELECT_CONFIGURATION* = 1;
    USER_CLASS_ACTIVE* = 2;
    USER_CLASS_SELECTED* = 3;
    USER_CONNECTION* = 4;
    USER_DISCONNECTION* = 5;
    USER_UNRECOVERED_ERROR* = 6;

  (**
  * @brief  DeInitStateMachine
  *         De-Initialize the Host state machine.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE DeInitStateMachine(phost: Def.Handle);
    VAR i: INTEGER; zeroDev!: Def.DevDescriptor; zeroCfg!: Def.CfgDescriptor;
  BEGIN  zeroDev := SYSTEM.VAL(Def.DevDescriptor,SYSTEM.ADR(Def.ZERO));
    zeroCfg := SYSTEM.VAL(Def.CfgDescriptor, SYSTEM.ADR(Def.ZERO));
    FOR i := 0 TO Def.MAX_PIPES_NBR - 1 DO phost.Pipes[i] := {} END; (* Clear Pipes flags*)

    phost.gState := Def.IDLE;
    phost.EnumState := Def.IDLE;
    phost.RequestState := Def.CMD_SEND;
    phost.Timer := 0;

    phost.Control.state := Def.CTRL_SETUP;
    phost.Control.pipe_size := Def.MPS_DEFAULT;
    phost.Control.errorcount := 0;

    phost.device.address := Def.ADDRESS_DEFAULT;
    phost.device.speed := Def.SPEED_FULL;
    phost.device.RstCnt := 0;
    phost.device.EnumCnt := 0;

    (* Reset the device record *)
    FOR i := 0 TO Conf.MAX_SIZE_CONFIGURATION - 1 DO phost.device.CfgDesc_Raw[i] :=  0 END;
    phost.device.DevDesc := zeroDev^;
    phost.device.CfgDesc := zeroCfg^;
  END DeInitStateMachine;


  (**
  * @brief  USBH_Init
  *         Initialize the HOST Core.
  * @param  phost: Host Handle
  * @param  pUsrFunc: User Callback
  * @retval USBH Status
  *)
  PROCEDURE Init*(phost: Def.Handle; pUsrFunc: Def.UserCallback; id: BYTE): BYTE;
    VAR status: BYTE;
  BEGIN
    IF phost = NIL THEN Log.Error("Invalid Host Handle"); status := Def.FAIL
    ELSE phost.id := id; (* Set DRiver ID *)
      phost.pActiveClass := NIL; (* Unlink class*)
      phost.ClassNumber := 0;
      DeInitStateMachine(phost); (* Restore default states and prepare EP0 *)
      (* Restore default Device connection states *)
      phost.device.PortEnabled := FALSE;
      phost.device.is_connected := FALSE;
      phost.device.is_disconnected := FALSE;
      phost.device.is_ReEnumerated := FALSE;
      IF pUsrFunc # NIL THEN phost.pUser := pUsrFunc END; (* Assign User process *)
      status := UH.Init(phost) (* Initialize low level driver *)
    END;
    Log.Flush

    RETURN status
  END Init;

  (**
  * @brief  HCD_DeInit
  *         De-Initialize the Host portion of the driver.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE DeInit*(phost: Def.Handle);
  BEGIN DeInitStateMachine(phost);
    (* Restore default Device connection states *)
    phost.device.PortEnabled := FALSE;
    phost.device.is_connected := FALSE;
    phost.device.is_disconnected := FALSE;
    phost.device.is_ReEnumerated := FALSE;
    phost.device.RstCnt := 0;
    phost.device.EnumCnt := 0;
    IF phost.phcd # NIL THEN UH.Stop(phost) END;
    Log.Flush
  END DeInit;

  (**
  * @brief  USBH_RegisterClass
  *         Link class driver to Host Core.
  * @param  phost : Host Handle
  * @param  pclass: Class handle
  * @retval USBH Status
  *)
  PROCEDURE RegisterClass*(phost: Def.Handle; pclass: Def.Class): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.OK;
    IF pclass # NIL THEN
      IF phost.ClassNumber < Conf.MAX_NUM_SUPPORTED_CLASS THEN
        phost.pClass[phost.ClassNumber] := pclass; INC(phost.ClassNumber) (* link the class to the USB Host handle *)
      ELSE Log.Error("Max Class Number reached"); status := Def.FAIL
      END
    ELSE Log.Error("Invalid Class handle"); status := Def.FAIL
    END;
    Log.Flush

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
  PROCEDURE FindInterface*(phost: Def.Handle; Class, SubClass, Protocol: BYTE): BYTE;
    VAR if_ix: BYTE;
  BEGIN if_ix := 0;
    WHILE (if_ix < Conf.MAX_NUM_INTERFACES) &
      ~(((phost.device.CfgDesc.Itf_Desc[if_ix].bInterfaceClass = Class) OR (Class = 0FFH)) &
        ((phost.device.CfgDesc.Itf_Desc[if_ix].bInterfaceSubClass = SubClass) OR (SubClass = 0FFH)) &
        ((phost.device.CfgDesc.Itf_Desc[if_ix].bInterfaceProtocol = Protocol) OR (Protocol = 0FFH)))
    DO INC(if_ix);
    END;
    IF if_ix >= Conf.MAX_NUM_INTERFACES THEN if_ix := 0FFH END

    RETURN  if_ix
  END FindInterface;

  (**
  * @brief  USBH_SelectInterface
  *         Select current interface.
  * @param  phost: Host Handle
  * @param  interface: Interface number
  * @retval USBH Status
  *)
  PROCEDURE SelectInterface*(phost: Def.Handle; interface: BYTE): BYTE;
    VAR status: BYTE;
  BEGIN status := Def.OK;
    IF interface < phost.device.CfgDesc.bNumInterfaces THEN
      phost.device.current_interface := interface;
      Log.UserString("Switching to Interface (#"); Log.UserInt(interface, 1); Log.User(")");
      Log.UserString("Class    : "); Log.UserHexVLen(phost.device.CfgDesc.Itf_Desc[interface].bInterfaceClass, 2, FALSE); Log.User("h");
      Log.UserString("SubClass : "); Log.UserHexVLen(phost.device.CfgDesc.Itf_Desc[interface].bInterfaceSubClass, 2, FALSE); Log.User("h");
      Log.UserString("Protocol : "); Log.UserHexVLen(phost.device.CfgDesc.Itf_Desc[interface].bInterfaceProtocol, 2, FALSE); Log.User("h");
    ELSE Log.Error("Cannot Select This Interface.");
      status := Def.FAIL
    END;
    Log.Flush

    RETURN status
  END SelectInterface;

  (**
  * @brief  USBH_Start
  *         Start the USB Host Core.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE Start*(phost: Def.Handle);
  BEGIN UH.Start(phost); (* Start the low level driver  *)
    UH.DriverVBUS(phost, TRUE); (* Activate VBUS on the port *)
    Log.Flush
  END Start;

  (**
  * @brief  USBH_Stop
  *         Stop the USB Host Core.
  * @param  phost: Host Handle
  * @retval USBH Status
  *)
  PROCEDURE Stop*(phost: Def.Handle);
  BEGIN
    (* DeActivate VBUS on the port *)
    UH.DriverVBUS(phost, FALSE);
    (* Stop and cleanup the low level driver  *)
    UH.Stop(phost);
    (* Free Control Pipes *)
    Pipes.Free(phost, phost.Control.pipe_in);
    Pipes.Free(phost, phost.Control.pipe_out);
    Log.Flush
  END Stop;

  (**
  * @brief  USBH_HandleEnum
  *         This function includes the complete enumeration process
  * @param  phost: Host Handle
  * @retval USBH_Status
  *)
  PROCEDURE HandleEnum(phost: Def.Handle): BYTE;
    VAR Status, ReqStatus: BYTE; str: ARRAY 0FFH OF CHAR;
  BEGIN Status := Def.BUSY; ReqStatus := Def.BUSY;
    IF phost.EnumState = Def.IDLE THEN
      (* Get Device Desc for only 1st 8 bytes : To get EP0 MaxPacketSize *)
      ReqStatus := CtlReq.Get_DevDesc(phost, 8);
      IF ReqStatus = Def.OK THEN
        phost.Control.pipe_size := phost.device.DevDesc.bMaxPacketSize;
        phost.EnumState := Def.ENUM_GET_FULL_DEV_DESC;
        (* modify control channels configuration for MaxPacket size *)
        Pipes.Open(phost, phost.Control.pipe_in, 80H, phost.device.address,
          phost.device.speed, IoReq.EP_CONTROL, phost.Control.pipe_size);
        (* Open Control pipes *)
        Pipes.Open(phost, phost.Control.pipe_out, 0, phost.device.address,
          phost.device.speed, IoReq.EP_CONTROL, phost.Control.pipe_size);
      ELSIF ReqStatus = Def.NOT_SUPPORTED THEN Log.Error("Control error: Get Device Descriptor request failed");
        INC(phost.device.EnumCnt);
        IF phost.device.EnumCnt > 3 THEN (* Buggy Device can't complete get device desc request *)
          Log.User("Control error, Device not Responding Please unplug the Device.");
          phost.gState := Def.HOST_ABORT_STATE
        ELSE (* free control pipes *)
          Pipes.Free(phost, phost.Control.pipe_out); Pipes.Free(phost, phost.Control.pipe_in);
          phost.gState := Def.IDLE (* Reset the USB Device *)
        END
      END
    ELSIF phost.EnumState = Def.ENUM_GET_FULL_DEV_DESC THEN
      (* Get FULL Device Desc  *)
      ReqStatus := CtlReq.Get_DevDesc(phost, Def.DEVICE_DESC_SIZE);
      IF ReqStatus = Def.OK THEN
        Log.UserString("PID: "); Log.UserHexVLen(phost.device.DevDesc.idProduct, 4, FALSE); Log.User("h");
        Log.UserString("VID: "); Log.UserHexVLen(phost.device.DevDesc.idVendor, 4, FALSE); Log.User("h");
        phost.EnumState := Def.ENUM_SET_ADDR
      ELSIF ReqStatus = Def.NOT_SUPPORTED THEN
        Log.Error("Control error: Get Full Device Descriptor request failed");
        INC(phost.device.EnumCnt);
        IF phost.device.EnumCnt > 3 THEN (* Buggy Device can't complete get device desc request *)
          Log.User("Control error, Device not Responding Please unplug the Device.");
          phost.gState := Def.HOST_ABORT_STATE
        ELSE (* Free control pipes *)
          Pipes.Free(phost, phost.Control.pipe_out); Pipes.Free(phost, phost.Control.pipe_in);
          phost.EnumState := Def.IDLE; phost.gState := Def.IDLE (* Reset the USB Device *)
        END
      END
    ELSIF phost.EnumState = Def.ENUM_SET_ADDR THEN
      (* set address *)
      ReqStatus := CtlReq.SetAddress(phost, Def.DEVICE_ADDRESS);
      IF ReqStatus = Def.OK THEN
        Kernel.Delayms(2); phost.device.address := Def.DEVICE_ADDRESS;
        (* user callback for device address assigned *)
        Log.UserString("Address (#"); Log.UserInt(phost.device.address, 1); Log.User(") assigned.");
        phost.EnumState := Def.ENUM_GET_CFG_DESC;
        (* modify control channels to update device address *)
        Pipes.Open(phost, phost.Control.pipe_in, 80H, phost.device.address,
          phost.device.speed, IoReq.EP_CONTROL, phost.Control.pipe_size);
        (* Open Control pipes *)
        Pipes.Open(phost, phost.Control.pipe_out, 0, phost.device.address,
          phost.device.speed, IoReq.EP_CONTROL, phost.Control.pipe_size)
      ELSIF ReqStatus = Def.NOT_SUPPORTED THEN
        Log.Error("Control error: Device Set Address request failed");
        (* Buggy Device can't complete get device desc request *)
        Log.User("Control error, Device not Responding Please unplug the Device.");
        phost.gState := Def.HOST_ABORT_STATE; phost.EnumState := Def.IDLE;
      END
    ELSIF phost.EnumState = Def.ENUM_GET_CFG_DESC THEN
      (* get standard configuration descriptor *)
      ReqStatus := CtlReq.Get_CfgDesc(phost, Def.CONFIGURATION_DESC_SIZE);
      IF ReqStatus = Def.OK THEN phost.EnumState := Def.ENUM_GET_FULL_CFG_DESC
      ELSIF ReqStatus = Def.NOT_SUPPORTED THEN
        Log.Error("Control error: Get Device configuration descriptor request failed");
        INC(phost.device.EnumCnt);
        IF phost.device.EnumCnt > 3 THEN
          (* Buggy Device can't complete get device desc request *)
          Log.User("Control error, Device not Responding Please unplug the Device.");
          phost.gState := Def.HOST_ABORT_STATE
        ELSE (* Free control pipes *)
          Pipes.Free(phost, phost.Control.pipe_out); Pipes.Free(phost, phost.Control.pipe_in);
          phost.EnumState := Def.IDLE; phost.gState := Def.IDLE; (* Reset the USB Device *)
        END
      END
    ELSIF phost.EnumState = Def.ENUM_GET_FULL_CFG_DESC THEN
      (* get FULL config descriptor (config, interface, endpoints) *)
      ReqStatus := CtlReq.Get_CfgDesc(phost, phost.device.CfgDesc.wTotalLength);
      IF ReqStatus = Def.OK THEN phost.EnumState := Def.ENUM_GET_MFC_STRING_DESC
      ELSIF ReqStatus = Def.NOT_SUPPORTED THEN
        Log.Error("Control error: Get Device configuration descriptor request failed");
        INC(phost.device.EnumCnt);
        IF phost.device.EnumCnt > 3 THEN (* Buggy Device can't complete get device desc request *)
          Log.User("Control error, Device not Responding Please unplug the Device.");
          phost.gState := Def.HOST_ABORT_STATE
        ELSE (* Free control pipes *)
          Pipes.Free(phost, phost.Control.pipe_out); Pipes.Free(phost, phost.Control.pipe_in);
          phost.EnumState := Def.IDLE; phost.gState := Def.IDLE (* Reset the USB Device *)
        END
      END
    ELSIF phost.EnumState = Def.ENUM_GET_MFC_STRING_DESC THEN
      IF phost.device.DevDesc.iManufacturer # 0 THEN
        (* Check that Manufacturer String is available *)
        ReqStatus := CtlReq.Get_StringDesc(phost, phost.device.DevDesc.iManufacturer, str, LEN(str));
        IF ReqStatus = Def.OK THEN (* User callback for Manufacturing string *)
          Log.UserString("Manufacturer : "); Log.User(str);
          phost.EnumState := Def.ENUM_GET_PRODUCT_STRING_DESC
        ELSIF ReqStatus = Def.NOT_SUPPORTED THEN
          Log.User("Manufacturer : N/A"); phost.EnumState := Def.ENUM_GET_PRODUCT_STRING_DESC
        END
      ELSE Log.User("Manufacturer : N/A"); phost.EnumState := Def.ENUM_GET_PRODUCT_STRING_DESC
      END
    ELSIF phost.EnumState = Def.ENUM_GET_PRODUCT_STRING_DESC THEN
      IF phost.device.DevDesc.iProduct # 0 THEN
        (* Check that Product string is available *)
        ReqStatus := CtlReq.Get_StringDesc(phost, phost.device.DevDesc.iProduct, str, LEN(str));
        IF ReqStatus = Def.OK THEN (* User callback for Product string *)
          Log.UserString("Product : "); Log.User(str);
          phost.EnumState := Def.ENUM_GET_SERIALNUM_STRING_DESC;
        ELSIF ReqStatus = Def.NOT_SUPPORTED THEN
          Log.User("Product : N/A"); phost.EnumState := Def.ENUM_GET_SERIALNUM_STRING_DESC
        END
      ELSE Log.User("Product : N/A"); phost.EnumState := Def.ENUM_GET_SERIALNUM_STRING_DESC
      END
    ELSIF phost.EnumState = Def.ENUM_GET_SERIALNUM_STRING_DESC THEN
      IF phost.device.DevDesc.iSerialNumber # 0 THEN
        (* Check that Serial number string is available *)
        ReqStatus := CtlReq.Get_StringDesc(phost, phost.device.DevDesc.iSerialNumber, str, LEN(str));
        IF ReqStatus = Def.OK THEN (* User callback for Serial number string *)
          Log.UserString("Serial Number : "); Log.User(str); Status := Def.OK
        ELSIF ReqStatus = Def.NOT_SUPPORTED THEN
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
  PROCEDURE Process*(phost: Def.Handle);
    VAR status, idx: BYTE;
  BEGIN status := Def.FAIL;
    (* check for Host pending port disconnect event *)
    IF phost.device.is_disconnected THEN phost.gState := Def.HOST_DEV_DISCONNECTED END;
    IF phost.gState = Def.IDLE THEN
      IF phost.device.is_connected THEN Log.User("USB Device Connected");
        (* Wait for 200 ms after connection *)
        phost.gState := Def.HOST_DEV_WAIT_FOR_ATTACHMENT;
        Kernel.Delayms(200); UH.ResetPort(phost);
        (* Make sure to start with Default address *)
        phost.device.address := Def.ADDRESS_DEFAULT; phost.Timeout := 0;
      END
    ELSIF phost.gState = Def.HOST_DEV_WAIT_FOR_ATTACHMENT THEN (* Wait for Port Enabled *)
      IF phost.device.PortEnabled THEN Log.User("USB Device Reset Completed");
        phost.device.RstCnt := 0; phost.gState := Def.HOST_DEV_ATTACHED
      ELSIF phost.Timeout > Def.DEV_RESET_TIMEOUT THEN INC(phost.device.RstCnt);
        IF phost.device.RstCnt > 3 THEN (* Buggy Device can't complete reset *)
          Log.User("USB Reset Failed, Please unplug the Device.");
          phost.gState := Def.HOST_ABORT_STATE
        ELSE phost.gState := Def.IDLE
        END
      ELSE INC(phost.Timeout, 10); Kernel.Delayms(10)
      END
    ELSIF phost.gState = Def.HOST_DEV_ATTACHED THEN
      IF phost.pUser # NIL THEN phost.pUser(phost, USER_CONNECTION) END;
      Kernel.Delayms(100); (* Wait for 100 ms after Reset *)
      phost.device.speed := UH.GetSpeed(phost);
(*
#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
      phost->NakTimeout = USBH_NAK_SOF_COUNT;
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */
*)
      phost.gState := Def.HOST_ENUMERATION;
      phost.Control.pipe_out := Pipes.Alloc(phost, 0);
      phost.Control.pipe_in  := Pipes.Alloc(phost, 80H);
      (* Open Control pipes *)
      Pipes.Open(phost, phost.Control.pipe_in, 80H, phost.device.address, phost.device.speed,
        IoReq.EP_CONTROL, phost.Control.pipe_size);
      Pipes.Open(phost, phost.Control.pipe_out, 0, phost.device.address, phost.device.speed,
        IoReq.EP_CONTROL, phost.Control.pipe_size);
    ELSIF phost.gState = Def.HOST_ENUMERATION THEN
      (* Check for enumeration status *)
      status := HandleEnum(phost);
      IF status = Def.OK THEN
        (* The function shall return USBH_OK when full enumeration is complete *)
        Log.User("Enumeration done."); phost.device.current_interface := 0;
        IF phost.device.DevDesc.bNumConfigurations = 1 THEN
          Log.User("This device has only 1 configuration."); phost.gState := Def.HOST_SET_CONFIGURATION
        ELSE phost.gState := Def.HOST_INPUT
        END
      END
    ELSIF phost.gState = Def.HOST_INPUT THEN
      (* user callback for end of device basic enumeration *)
      IF phost.pUser # NIL THEN
        phost.pUser(phost, Def.USER_SELECT_CONFIGURATION);
        phost.gState := Def. HOST_SET_CONFIGURATION
      END
    ELSIF phost.gState = Def.HOST_SET_CONFIGURATION THEN
      (* set configuration *)
      IF CtlReq.SetCfg(phost, phost.device.CfgDesc.bConfigurationValue) = Def.OK THEN
        phost.gState := Def.HOST_SET_WAKEUP_FEATURE;
        Log.User("Default configuration set.");
      END
    ELSIF phost.gState = Def.HOST_SET_WAKEUP_FEATURE THEN
      IF Def.REMOTE_WAKEUP IN phost.device.CfgDesc.bmAttributes THEN
        status := CtlReq.SetFeature(phost, CtlReq.FEATURE_SELECTOR_REMOTEWAKEUP);
        IF status = Def.OK THEN Log.User("Device remote wakeup enabled");
          phost.gState := Def.HOST_CHECK_CLASS;
        ELSIF status = Def.NOT_SUPPORTED THEN Log.User("Remote wakeup not supported by the device");
          phost.gState := Def.HOST_CHECK_CLASS;
        END
      ELSE phost.gState := Def.HOST_CHECK_CLASS
      END
    ELSIF phost.gState = Def.HOST_CHECK_CLASS THEN
      IF phost.ClassNumber = 0 THEN Log.User("No Class has been registered.")
      ELSE phost.pActiveClass := NIL; idx := 0;
        WHILE (phost.pActiveClass = NIL) & (idx < Conf.MAX_NUM_SUPPORTED_CLASS) DO
          IF phost.pClass[idx].ClassCode = phost.device.CfgDesc.Itf_Desc[0].bInterfaceClass THEN
            phost.pActiveClass := phost.pClass[idx];
          END;
          INC(idx)
        END;
        IF phost.pActiveClass # NIL THEN
          IF phost.pActiveClass.Init(phost) = Def.OK THEN
            phost.gState := Def.HOST_CLASS_REQUEST;
            Log.UserString(phost.pActiveClass.Name); Log.User(" class started.");
            (* Inform user that a class has been activated *)
            phost.pUser(phost, Def.USER_CLASS_SELECTED)
          ELSE phost.gState := Def.HOST_ABORT_STATE;
            Log.UserString("Device not supporting "); Log.UserString(phost.pActiveClass.Name); Log.User(" class.");
          END
        ELSE phost.gState := Def.HOST_ABORT_STATE;
          Log.User("No registered class for this device.")
        END
      END
    ELSIF phost.gState = Def.HOST_CLASS_REQUEST THEN
      (* process class standard control requests state machine *)
      IF phost.pActiveClass # NIL THEN status := phost.pActiveClass.Requests(phost);
        IF status = Def.OK THEN phost.gState := Def.HOST_CLASS;
        ELSIF status = Def.FAIL THEN phost.gState := Def.HOST_ABORT_STATE;
          Log.Error("Device not responding Please Unplug.")
        END
      ELSE phost.gState := Def.HOST_ABORT_STATE; Log.Error("Invalid Class Driver.")
      END
    ELSIF phost.gState = Def.HOST_CLASS THEN
      (* process class state machine *)
      IF phost.pActiveClass # NIL THEN status := phost.pActiveClass.BgndProcess(phost) END
    ELSIF phost.gState = Def.HOST_DEV_DISCONNECTED THEN
      phost.device.is_disconnected := FALSE; DeInitStateMachine(phost);
      (* Re-Initilaize Host for new Enumeration *)
      IF phost.pActiveClass # NIL THEN status := phost.pActiveClass.DeInit(phost); phost.pActiveClass := NIL END;
      IF phost.pUser # NIL THEN phost.pUser(phost, Def.USER_DISCONNECTION) END;
      Log.User("USB Device disconnected");
      IF phost.device.is_ReEnumerated THEN phost.device.is_ReEnumerated := FALSE;
        Start(phost) (* Start the host and re-enable Vbus *)
      ELSE UH.Start(phost) (* Device Disconnection Completed, start USB Driver *)
      END
    END;
    Log.Flush
  END Process;

END USBH.
