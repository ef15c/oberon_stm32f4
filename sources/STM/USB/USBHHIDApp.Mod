MODULE USBHHIDApp;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   USB host HID Mouse and Keyboard demo main file
  ******************************************************************************
  *)

  IMPORT Oberon, Def := USBHDef, USBH, Log := USBLog, HID := USBHHID;

  CONST
    APPLICATION_IDLE = 0;
    APPLICATION_DISCONNECT = 1;
    APPLICATION_START = 2;
    APPLICATION_READY = 3;
    APPLICATION_RUNNING = 4;

  (* Private variables ---------------------------------------------------------*)
  VAR hUSBHost: Def.Handle; Appli_state: BYTE;
    processTask: Oberon.Task;

  PROCEDURE InitApplication;
  BEGIN
    Log.User("OTG FS HID Host");
    Log.User("USBH lib started.");
    Log.User("");
    Log.Flush
  END InitApplication;

  (**
  * @brief  User Process
  * @param  phost: Host Handle
  * @param  id: Host Library user message ID
  * @retval None
  *)
  PROCEDURE UserProcess(phost: Def.Handle; id: BYTE);
  BEGIN
    IF id = Def.USER_DISCONNECTION THEN
      Appli_state := APPLICATION_DISCONNECT
    ELSIF id = Def.USER_CLASS_ACTIVE THEN
      Appli_state := APPLICATION_READY
    ELSIF id =  Def.USER_CONNECTION THEN
      Appli_state := APPLICATION_START
    END
  END UserProcess;

  PROCEDURE Process; (* USB Host Background task *)
  BEGIN USBH.Process(hUSBHost); 
(* TODO
    /* HID Menu Process */
    HID_MenuProcess();

    /* HID Joystick */
    HID_Joysticky();
*)
  END Process;

  PROCEDURE Run*;
    VAR res: BYTE;
  BEGIN
    (* Init HID Application *)
    InitApplication;
  
    (* Init Host Library *)
    res := USBH.Init(hUSBHost, UserProcess, 0);
    IF res = Def.OK THEN res := USBH.RegisterClass(hUSBHost, HID.CLASS); (* Add Supported Class *)
      USBH.Start(hUSBHost); (* Start Host Process *)
      (* Run Application (Non blocking mode) *)
      processTask := Oberon.NewTask(Process, 10); Oberon.Install(processTask)
    END
  END Run;

  PROCEDURE Stop*;
  BEGIN USBH.Stop(hUSBHost); USBH.DeInit(hUSBHost);
    Log.User("USBH lib stopped.");
    Oberon.Remove(processTask);
    Log.Flush
  END Stop;

BEGIN (*Appli_state := APPLICATION_IDLE *)
  NEW(hUSBHost)
END USBHHIDApp.

OM4P.Compile USBLog.Mod/s USBHConf.Mod/s USBHDef.Mod/s USBHPipes.Mod/s USBHIoReq.Mod/s
 USBHCtlReq.Mod/s LLUSB.Mod/s USBHCore.Mod/s HALHCD.Mod/s USBHHal.Mod/s USBH.Mod/s
 USBHHIDClass.Mod/s USBHHIDMouse.Mod/s USBHHIDKeybd.Mod/s USBHHID.Mod/s USBHHIDApp.Mod/s ~

Net.SendFiles CS LLUSB.Mod USBHConf.Mod USBHDef.Mod USBHPipes.Mod USBLog.Mod USBHCore.Mod
 HALHCD.Mod USBHHal.Mod USBH.Mod USBHIoReq.Mod USBHCtlReq.Mod USBHHIDClass.Mod
 USBHHIDMouse.Mod USBHHIDKeybd.Mod USBHHID.Mod USBHHIDApp.Mod ~

System.DeleteFiles LLUSB.sm4 USBH.sm4 USBHConf.sm4 USBHCore.sm4 USBHCtlReq.sm4 USBHDef.sm4
 USBHHID.sm4 USBHHIDApp.sm4 USBHHIDClass.sm4 USBHHIDKeybd.sm4 USBHHIDMouse.sm4
 USBHHal.sm4 USBHIoReq.sm4 USBHPipes.sm4 USBLog.sm4 HALHCD.sm4~

System.Free USBHHIDApp USBHHID USBHHIDKeybd USBHHIDMouse USBHHIDClass USBH USBHHal HALHCD
 USBHCore LLUSB USBHCtlReq USBHIoReq USBHPipes USBHDef USBHConf USBLog~

USBHHIDApp.Run
USBHHIDApp.Stop
