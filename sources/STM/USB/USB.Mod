MODULE USB; (*USB OTG library. C. Schoffit 29.06.26*)
  IMPORT Kernel, Log := USBLog, Def := USBDef, UC := HALUC, HDef := USBHDef, H := USBHal, USBH, HID := USBHHID;

  CONST MODE_STABILIZATION_TIME = 500;

  VAR processTask: Def.Task;

  PROCEDURE InitController(usb: UC.Handle; id: BYTE): Def.Handle;
    VAR ctrl!: Def.Handle; status: BYTE;
  BEGIN ctrl := usb; usb.cState := UC.STATE_ERROR;
    CASE ctrl OF HDef.Handle: USBH.VBUSOff(ctrl) END;
    IF H.IsHost(usb) THEN Log.Debug("initialize Host controller"); Log.DebugLn;
      ctrl := USBH.Init(usb, id);
      IF ctrl # NIL THEN
        CASE ctrl OF
          HDef.Handle: status := USBH.RegisterClass(ctrl, HID.CLASS); (* Add Supported Class *)
            USBH.Start(ctrl); ctrl.cState := UC.STATE_READY
          | Def.Handle: ASSERT(FALSE)
        END
      ELSE Log.Error("Host mode initialization failed"); Log.ErrorLn
      END
    ELSE Log.Error("Device mode not implemented"); Log.ErrorLn
    END

    RETURN ctrl
  END InitController;

  (* USB Host Background task *)
  PROCEDURE ProcessCore(core: Def.Handle; id: BYTE);
    VAR ctrl!: Def.Handle;
  BEGIN ctrl := core;
    CASE core OF
      UC.Handle:
        H.ProcessDeferredIRQWork(core); (*do the deferred job triggered by interrupts*);
        IF (core.cState = Def.IDLE) & (Kernel.Time() - core.Timer > MODE_STABILIZATION_TIME) THEN core.cState := UC.STATE_CMOD_STABLE
        ELSIF core.cState = UC.STATE_CMOD_STABLE THEN (*Initialize the host or device controller*)
          ctrl := InitController(core, id)
        END;
        Log.Flush
      | Def.Handle: ASSERT(FALSE)
    END
  END ProcessCore;

  PROCEDURE Process;
    VAR i: BYTE;
  BEGIN
    FOR i := 0 TO Def.NB_OTG_CORES - 1 DO
      IF Def.usbCores[i] # NIL THEN ProcessCore(Def.usbCores[i], i) END
    END
  END Process;

  PROCEDURE Init*(UserFunc: Def.UserCallback; id: BYTE); (*initialize the USB system and return a handle on it*)
    VAR usb!: UC.Handle;
  BEGIN usb := H.Init(UserFunc, id);
    IF usb # NIL THEN Def.Register(usb, id);
      IF processTask = NIL THEN (*install USB core process task*)
        processTask := Def.NewTask(Process, 100); Def.Install(processTask)
      END
    END
  END Init;

  PROCEDURE DeInit*(id: BYTE);
    VAR core!: Def.Handle;
  BEGIN core := Def.usbCores[id];
    IF core # NIL THEN
      CASE core OF
        HDef.Handle: USBH.Stop(core); USBH.DeInit(core)
      END;
      H.DeInit(core(UC.Handle)); Def.UnRegister(core);
      IF (processTask # NIL) & (Def.nofRegisteredCores = 0) THEN Def.Remove(processTask); processTask := NIL END;
      IF core.User # NIL THEN core.User(id, Def.USER_USB_RESET) END;
      Log.Debug("USB system stopped."); Log.DebugLn;
      Log.Flush
    END
  END DeInit;

  PROCEDURE IsHost*(id: BYTE): BOOLEAN;

    RETURN H.IsHost(Def.usbCores[id](UC.Handle))
  END IsHost;

END USB.

OM4Tool.DecSym USB.sm4
