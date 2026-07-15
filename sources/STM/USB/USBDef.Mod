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
      Log.Debug("Core "); Log.DebugHexVLen(ORD(core), 8, FALSE); Log.DebugString(" registered"); Log.ErrorLn
    ELSE Log.Error("Id "); Log.ErrorInt(id, 1); Log.ErrorString(" already registered"); Log.ErrorLn
    END
  END Register;

  PROCEDURE UnRegister*(core: Handle);
    VAR i: BYTE;
  BEGIN i := 0; WHILE (i < NB_OTG_CORES) & ((core = NIL) OR (usbCores[i] # core)) DO INC(i) END;
    IF i < NB_OTG_CORES THEN usbCores[i] := NIL; DEC(nofRegisteredCores);
      Log.Debug("Core "); Log.DebugHexVLen(ORD(core), 8, FALSE); Log.DebugString(" unregistered"); Log.ErrorLn
    ELSE Log.Error("Core "); Log.ErrorHexVLen(ORD(core), 8, FALSE); Log.ErrorString(" not registered"); Log.ErrorLn
    END
  END UnRegister;

  PROCEDURE Update*(core: Handle; id: BYTE);
  BEGIN
    IF (core # NIL) & (usbCores[id] # NIL) THEN usbCores[id] := core;
      Log.Debug("Id "); Log.DebugInt(id, 1); Log.DebugString(" updated to ");
      Log.DebugHexVLen(ORD(core), 8, FALSE); Log.ErrorLn
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
decode USBDef.sm4
USBDef 4A48B0C6  2
   1 NB_OTG_CORES [^4]       2
   1 IDLE [^4]       0
   1 OK [^4]       0
   1 BUSY [^4]       1
   1 FAIL [^4]       2
   1 SPEED_HIGH [^4]       0
   1 SPEED_FULL [^4]       1
   1 SPEED_LOW [^4]       2
   1 EP_TYPE_CTRL [^4]       0
   1 EP_TYPE_ISOC [^4]       1
   1 EP_TYPE_BULK [^4]       2
   1 EP_TYPE_INTR [^4]       3
   1 EP_TYPE_MSK [^6]       3
   1 REQ_DIR_MASK [^6]     128
   1 D2H [^6]     128
   1 H2D [^6]       0
   1 REQ_TYPE_STANDARD [^6]       0
   1 REQ_TYPE_CLASS [^6]      32
   1 REQ_TYPE_VENDOR [^6]      64
   1 REQ_TYPE_RESERVED [^6]      96
   1 REQ_RECIPIENT_DEVICE [^6]       0
   1 REQ_RECIPIENT_INTERFACE [^6]       1
   1 REQ_RECIPIENT_ENDPOINT [^6]       2
   1 REQ_RECIPIENT_OTHER [^6]       3
   5 Task [18  form = 7 [19  form = 13 [^9]  exno = 1  extlev = 0  size = 4 { --   0}]]()
   5 Buffer [20  form = 13 [^9]  exno = 2  extlev = 0  size = 4 { size [^4]   0}]()
   5 Handle [21  form = 7 [22  form = 13 [^9]  exno = 3  extlev = 0  size = 0 {}]]()
   5 HandleDesc [^22]( ->  21)
   2 usbCores [0  form = 12 [^21]  len = 2  size = 8]     4
   2 nofRegisteredCores [^1]     5
   1 NewTask [0  form = 10 [^18] ur = 4 ( class = 2 [^4] class = 2 [0  form = 10 [^9] ur = 13 ()])]       6
   1 Install [0  form = 10 [^9] ur = 4 ( class = 2 [^18])]       7
   1 Remove [0  form = 10 [^9] ur = 4 ( class = 2 [^18])]       8
   1 Register [0  form = 10 [^9] ur = 5 ( class = 2 [^1] class = 2 [^21])]       9
   1 UnRegister [0  form = 10 [^9] ur = 5 ( class = 2 [^21])]      10
   1 Update [0  form = 10 [^9] ur = 5 ( class = 2 [^1] class = 2 [^21])]      11
   1 LE16 [0  form = 10 [^15] ur = 4 ( class = 2 [^4] class = 3# [0  form = 12 [^1]  len = -1  size = 8])]      12
   1 MIN [0  form = 10 [^4] ur = 4 ( class = 2 [^4] class = 2 [^4])]      13

