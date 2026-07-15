MODULE USBHHIDApp;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   USB host HID Mouse and Keyboard demo main file
  ******************************************************************************
  *)

  IMPORT Display, Texts, Viewers, MenuViewers, Oberon, TextFrames,
    Def := USBDef, USB, USBH, Log := USBLog, HID := USBHHID, M := USBHHIDMouse, K := USBHHIDKeybd;

  CONST
    APPLICATION_DISCONNECT = 1;
    APPLICATION_START = 2;
    APPLICATION_READY = 3;
    APPLICATION_RUNNING = 4;

    HID_DEMO_WAIT =  1;
    HID_DEMO_MOUSE = 3;
    HID_DEMO_KEYBOARD = 4;

    HID_MOUSE_WAIT = 1;
    HID_MOUSE_START = 2;

    HID_KEYBOARD_WAIT = 1;
    HID_KEYBOARD_START = 2;

  TYPE
    DemoStateMachine = RECORD
      state, mouse_state, keyboard_state: BYTE;   
      select: BYTESET;
      lock: BYTE
    END;

  (* Private variables ---------------------------------------------------------*)
  VAR Appli_state: BYTE;
    menutxt, content: Texts.Text; end: INTEGER; buf: Texts.Buffer; MW, CW: Texts.Writer;
    hid_demo: DemoStateMachine; prev_select: BYTESET;
    processTask: Oberon.Task;

  (**
  * @brief  User Process
  * @param  phost: Host Handle
  * @param  id: Host Library user message ID
  * @retval None
  *)
  PROCEDURE UserProcess(usbid, reason: BYTE);
  BEGIN
    Log.Debug("UserProcessId: "); Log.DebugInt(reason, 1); Log.DebugLn; Log.Flush;
    IF reason = Def.USER_DISCONNECTION THEN
      Appli_state := APPLICATION_DISCONNECT
    ELSIF reason = Def.USER_CLASS_ACTIVE THEN
      Appli_state := APPLICATION_READY
    ELSIF reason =  Def.USER_CONNECTION THEN
      Appli_state := APPLICATION_START
    ELSIF reason =  Def.USER_USB_RESET THEN
      Appli_state := APPLICATION_DISCONNECT
    END
  END UserProcess;

  PROCEDURE WriteMenu(t: ARRAY OF CHAR);
  BEGIN Texts.WriteString(MW, " USBHHIDApp."); Texts.WriteString(MW, t)
  END WriteMenu;

  (**
  * @brief  Manages the menu on the screen.
  * @param  menu: Menu table
  * @param  item: Selected item to be highlighted
  * @retval None
  *)
  PROCEDURE SelectItem(l1, l2: ARRAY OF CHAR);
  BEGIN Texts.Delete(menutxt, end, menutxt.len, buf);
    WriteMenu(l1); WriteMenu(l2);
    Texts.Append(menutxt, MW.buf)
  END SelectItem;

  (**
  * @brief  Init Mouse window.    
  * @param  None
  * @retval None
  *)
  PROCEDURE USR_MOUSE_Init;
  BEGIN Texts.WriteString(CW, "USB HID Host Mouse Demo..."); Texts.WriteLn(CW);
    Texts.Append(content, CW.buf)
  END USR_MOUSE_Init;

  (**
  * @brief  Manages Mouse Menu Process.  
  * @param  None
  * @retval None
  *)
  PROCEDURE MouseMenuProcess;
  BEGIN
    IF hid_demo.mouse_state = Def.IDLE THEN hid_demo.mouse_state := HID_MOUSE_START;
      SelectItem("StartMouse", "Return");
      hid_demo.select := {}; prev_select := {};
    ELSIF hid_demo.mouse_state = HID_MOUSE_WAIT THEN
      IF hid_demo.select # prev_select THEN
        prev_select := hid_demo.select;
        (* Handle select item *)
        IF 7 IN hid_demo.select THEN
          EXCL(hid_demo.select, 7);
          IF ORD(hid_demo.select) = 0 THEN
            hid_demo.mouse_state := HID_MOUSE_START
          ELSIF ORD(hid_demo.select) = 1 THEN (* Return *)
            hid_demo.state := HID_DEMO_WAIT;
            hid_demo.select := {}
          END
        END
      END
    ELSIF hid_demo.mouse_state = HID_MOUSE_START THEN
      USR_MOUSE_Init;   
      hid_demo.mouse_state := HID_MOUSE_WAIT
    END
  END MouseMenuProcess;

  PROCEDURE WriteButtonState(m_pinfo: M.Info; i: INTEGER);
  BEGIN Texts.WriteString(CW, ", Button "); Texts.WriteInt(CW, i + 1, 1);
    IF m_pinfo.buttons[i] THEN Texts.WriteString(CW, "pressed")
    ELSE Texts.WriteString(CW, " released")
    END
  END WriteButtonState;

  (**
  * @brief  Main routine for Mouse application
  * @param  phost: Host handle
  * @retval None
  *)
  PROCEDURE MouseDemo;
    VAR m_pinfo!: M.Info;
  BEGIN m_pinfo := M.GetInfo(0);
    IF m_pinfo # NIL THEN (* Handle Mouse data position *)
      Texts.WriteString(CW, "X="); Texts.WriteInt(CW, m_pinfo.x, 1);
      Texts.WriteString(CW, ", Y="); Texts.WriteInt(CW, m_pinfo.y, 1);
      WriteButtonState(m_pinfo, 0); WriteButtonState(m_pinfo, 1); WriteButtonState(m_pinfo, 2);
      Texts.WriteLn(CW);
      Texts.Append(content, CW.buf)
    END
  END MouseDemo;

  (**
  * @brief  Init Keyboard window.     
  * @param  None
  * @retval None
  *)
  PROCEDURE USR_KEYBRD_Init;
  BEGIN Texts.WriteString(CW, "Use Keyboard to type characters:"); Texts.WriteLn(CW);
    Texts.Append(content, CW.buf)
  END USR_KEYBRD_Init;

  (**
  * @brief  Manages Keyboard Menu Process.  
  * @param  None
  * @retval None
  *)
  PROCEDURE KeyboardMenuProcess;
  BEGIN
    IF hid_demo.keyboard_state = Def.IDLE THEN
      hid_demo.keyboard_state := HID_KEYBOARD_START;
      SelectItem("StartKeyboard", "Return");   
      hid_demo.select := {}; prev_select := {}
    ELSIF hid_demo.keyboard_state = HID_KEYBOARD_WAIT THEN
      IF hid_demo.select # prev_select THEN
      prev_select := hid_demo.select;
      (* Handle select item *)
      IF 7 IN hid_demo.select THEN
        EXCL(hid_demo.select, 7);
          IF ORD(hid_demo.select) = 0 THEN 
            hid_demo.keyboard_state := HID_KEYBOARD_START
          ELSIF ORD(hid_demo.select) = 1 THEN (* Return *)
            hid_demo.state := HID_DEMO_WAIT;
            hid_demo.select := {}
         END
        END
      END
    ELSIF hid_demo.keyboard_state = HID_KEYBOARD_START THEN
      USR_KEYBRD_Init;
      hid_demo.keyboard_state := HID_KEYBOARD_WAIT
    END
  END KeyboardMenuProcess;

  (**
  * @brief  Main routine for Keyboard application
  * @param  phost: Host handle
  * @retval None
  *)
  PROCEDURE KeybdDemo;
    VAR k_pinfo!: K.Info; c: CHAR;
  BEGIN k_pinfo := K.GetInfo(0);
    IF k_pinfo # NIL THEN c := K.GetChar(k_pinfo);
      IF c # 0X THEN 
        IF (c = 0AX) OR (c = 0DX) THEN Texts.WriteLn(CW) ELSE Texts.Write(CW, c) END;
        Texts.Append(content, CW.buf)
      END
    END
  END KeybdDemo;

  (**
  * @brief  Manages HID Menu Process.
  * @param  None
  * @retval None
  *)
  PROCEDURE MenuProcess;
  BEGIN
    IF hid_demo.state = Def.IDLE THEN SelectItem("StartHID", "ReEnumerate");
      hid_demo.state := HID_DEMO_WAIT;
      hid_demo.select := {}
    ELSIF hid_demo.state = HID_DEMO_MOUSE THEN
      IF Appli_state = APPLICATION_READY THEN
        MouseMenuProcess; MouseDemo
      END
    ELSIF hid_demo.state = HID_DEMO_KEYBOARD THEN
      IF Appli_state = APPLICATION_READY THEN
        KeyboardMenuProcess; KeybdDemo
      END
    END;
    IF Appli_state = APPLICATION_DISCONNECT THEN
      Appli_state := Def.IDLE; Log.Error("HID device disconnected!"); Log.ErrorLn; Log.ErrorLn;
      hid_demo.state := Def.IDLE; hid_demo.select := {}
    END
  END MenuProcess;

  PROCEDURE StartHID*;
  BEGIN
    IF hid_demo.state = HID_DEMO_WAIT THEN
      IF Appli_state = APPLICATION_READY THEN
        IF HID.GetDeviceType(0) = HID.KEYBOARD THEN
          hid_demo.keyboard_state := Def.IDLE; hid_demo.state := HID_DEMO_KEYBOARD
        ELSIF HID.GetDeviceType(0) = HID.MOUSE THEN
          hid_demo.mouse_state := Def.IDLE; hid_demo.state := HID_DEMO_MOUSE
        END
      ELSE Log.Error("No supported HID device!"); Log.ErrorLn; Log.ErrorLn;
      END
    END
  END StartHID;

  PROCEDURE ReEnumerate*;
  BEGIN
    IF Appli_state = APPLICATION_READY THEN USBH.ReEnumerate(0) (* Force HID Device to re-enumerate *)
    END
  END ReEnumerate;

  PROCEDURE Return*;
  BEGIN hid_demo.state := Def.IDLE;
  END Return;

  (* USB Host Background task *)
  PROCEDURE Process;
  BEGIN MenuProcess; (* HID Menu Process *)
  END Process;

  (**
  * @brief  Demo state machine.
  * @param  None
  * @retval None
  *)
  PROCEDURE MenuInit;
  BEGIN (* Start HID Interface *)
    Log.User("Starting HID Demo");
    hid_demo.state := Def.IDLE;
    MenuProcess;
  END MenuInit;

  PROCEDURE InitApplication;
    VAR V!: Viewers.Viewer; X, Y: INTEGER; M!: TextFrames.Frame;
  BEGIN Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    M := TextFrames.NewMenu("OTG FS HID Host", "System.Close System.Clear USBHHIDApp.Run USBHHIDApp.Stop");
    content := TextFrames.Text("");
    V := MenuViewers.New(M, TextFrames.NewText(content, 0), TextFrames.menuH, X, Y);
    menutxt := M.text; end := menutxt.len;
    MenuInit;
    Log.Flush
  END InitApplication;

  PROCEDURE Run*;
    VAR res: BYTE;
  BEGIN
    (* Init USB Library *)
    IF Def.usbCores[0] = NIL THEN USB.Init(UserProcess, 0) END;
    IF (Def.usbCores[0] # NIL) & USB.IsHost(0) THEN
      Log.Debug("USBH lib started."); Log.DebugLn;
      (* Run Application (Non blocking mode) *)
      IF processTask = NIL THEN processTask := Oberon.NewTask(Process, 10); Oberon.Install(processTask) END
    ELSE Log.Error("USBH lib failed to start");
    END;
    Log.Flush
  END Run;

  PROCEDURE Stop*;
  BEGIN
    IF processTask # NIL THEN Oberon.Remove(processTask); processTask := NIL END;
    USB.DeInit(0);
    Log.Debug("USB controller stopped."); Log.DebugLn;
    Log.Flush;
  END Stop;

  PROCEDURE Open*;
  BEGIN (* Init HID Application *)
    InitApplication; Run  
  END Open;

BEGIN
(*
  Log.SetDebugCbks(Log.DefaultDebug, Log.DefaultString, Log.DefaultInt, Log.DefaultHexVLen,
  Log.DefaultSet, Log.DefaultBuf, Log.DefaultLn);
*)
  NEW(buf); Texts.OpenBuf(buf); Texts.OpenWriter(MW); MW.col := Display.green;
  Texts.OpenWriter(CW); CW.col := Display.white
END USBHHIDApp.

OM4P.Compile USBHHIDApp.Mod/s ~
System.Free USBHHIDApp~

USBHHIDApp.Open
USBHHIDApp.Stop
