MODULE USBDef; (*USB OTG common definitions. C.S 29.06.26*)
  IMPORT Oberon, Log := USBLog;

  CONST NB_OTG_CORES* = 2;
    (* Following common states *)
    IDLE* = 0;

  (* Following USB common status *)
    OK* = 0;
    BUSY* = 1;
    FAIL* = 2;

    SPEED_HIGH* = 0;
    SPEED_FULL* = 1;
    SPEED_LOW* = 2;

    EP_TYPE_CTRL* = 0;
    EP_TYPE_ISOC* = 1;
    EP_TYPE_BULK* = 2;
    EP_TYPE_INTR* = 3;
    EP_TYPE_MSK* = {0..1};

  (* bmRequestType :D7 Data Phase Transfer Direction  *)
    REQ_DIR_MASK* = {7};
    D2H* = {7};
    H2D* = {};

  (* bmRequestType D6..5 Type *)
    REQ_TYPE_STANDARD* = {};
    REQ_TYPE_CLASS* = {5};
    REQ_TYPE_VENDOR* = {6};
    REQ_TYPE_RESERVED* = {5..6};

  (* bmRequestType D4..0 Recipient *)
    REQ_RECIPIENT_DEVICE* = TOSET(0);
    REQ_RECIPIENT_INTERFACE* = TOSET(1);
    REQ_RECIPIENT_ENDPOINT* = TOSET(2);
    REQ_RECIPIENT_OTHER* = TOSET(3);

  (* User callback reason codes *)
    USER_SELECT_CONFIGURATION* = 1;
    USER_CLASS_ACTIVE* = 2;
    USER_CLASS_SELECTED* = 3;
    USER_CONNECTION* = 4;
    USER_DISCONNECTION* = 5;
    USER_UNRECOVERED_ERROR* = 6;
    USER_USB_RESET* = 7;

  TYPE
    Task* = POINTER TO TaskDesc;
    TaskDesc = RECORD task: Oberon.Task END;

    Buffer* = RECORD size*: INTEGER END;

    Class* = POINTER TO ClassDesc;
    ClassDesc* = RECORD END;

    Handle* = POINTER TO HandleDesc;
    Callback* = PROCEDURE^5(usb: Handle): BYTE;
    UserCallback* = PROCEDURE(usbid, reason: BYTE);

    HandleDesc* = RECORD
      id*: BYTE;
      User*: UserCallback;
    END;

  VAR usbCores*: ARRAY NB_OTG_CORES OF Handle; nofRegisteredCores*: BYTE;

  PROCEDURE NewTask*(h: PROCEDURE; period: INTEGER): Task;
    VAR t!: Task;
  BEGIN NEW(t); t.task := Oberon.NewTask(h, period)

    RETURN t
  END NewTask;

  PROCEDURE Install*(T: Task);
  BEGIN Oberon.Install(T.task)
  END Install;

  PROCEDURE Remove* (T: Task);
  BEGIN Oberon.Remove(T.task)
  END Remove;

  PROCEDURE Register*(core: Handle; id: BYTE);
  BEGIN
    IF (core # NIL) & (usbCores[id] = NIL) THEN usbCores[id] := core; INC(nofRegisteredCores);
      Log.Debug("Core "); Log.DebugHexVLen(ORD(core), 8, FALSE); Log.DebugString(" registered"); Log.DebugLn
    ELSE Log.Error("Id "); Log.ErrorInt(id, 1); Log.ErrorString(" already registered"); Log.ErrorLn
    END
  END Register;

  PROCEDURE UnRegister*(core: Handle);
    VAR i: BYTE;
  BEGIN i := 0; WHILE (i < NB_OTG_CORES) & ((core = NIL) OR (usbCores[i] # core)) DO INC(i) END;
    IF i < NB_OTG_CORES THEN usbCores[i] := NIL; DEC(nofRegisteredCores);
      Log.Debug("Core "); Log.DebugHexVLen(ORD(core), 8, FALSE); Log.DebugString(" unregistered"); Log.DebugLn
    ELSE Log.Error("Core "); Log.ErrorHexVLen(ORD(core), 8, FALSE); Log.ErrorString(" not registered"); Log.ErrorLn
    END
  END UnRegister;

  PROCEDURE Update*(core: Handle; id: BYTE);
  BEGIN
    IF (core # NIL) & (usbCores[id] # NIL) THEN usbCores[id] := core;
      Log.Debug("Id "); Log.DebugInt(id, 1); Log.DebugString(" updated to ");
      Log.DebugHexVLen(ORD(core), 8, FALSE); Log.DebugLn
    END
  END Update;

  PROCEDURE LE16*(buf: ARRAY OF BYTE; ofs: INTEGER): HALFWORD;
    VAR res: HALFWORD;
  BEGIN res :=  buf[ofs] + buf[ofs + 1]*100H

    RETURN res
  END LE16;

  PROCEDURE MIN*(a, b: INTEGER): INTEGER;
    VAR res: INTEGER;
  BEGIN IF a < b THEN res := a ELSE res := b END

    RETURN res
  END MIN;

END USBDef.

OM4Tool.DecSym USBDef.sm4
