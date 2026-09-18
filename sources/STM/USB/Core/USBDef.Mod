MODULE USBDef; (*USB OTG common definitions. C.S 29.06.26*)
  IMPORT SYSTEM, Oberon, Log := USBLog, Conf := USBConf;

  CONST NB_OTG_CORES* = 2;
    (* Following common states *)
    IDLE* = 0;

    (*Controller states*)
    STATE_READY* = 1;
    STATE_ERROR* = 2;
    STATE_BUSY* = 3;
    STATE_RESET* = 4;
    STATE_STARTED* = 5;

  (* Following USB common status *)
    OK* = 0;
    BUSY* = 1;
    FAIL* = 2;
    EMEM* = 3;

    SPEED_HIGH* = 0;
    SPEED_FULL* = 1;
    SPEED_LOW* = 2;

    EP_TYPE_CTRL* = 0;
    EP_TYPE_ISOC* = 1;
    EP_TYPE_BULK* = 2;
    EP_TYPE_INTR* = 3;
    EP_TYPE_MSK* = {0..1};

    MAX_EP0_SIZE* = 64;

  (* bmRequestType :D7 Data Phase Transfer Direction  *)
    REQ_DIR_MASK* = {7};
    D2H* = {7};
    H2D* = {};

  (* bmRequestType D6..5 Type *)
    REQ_TYPE_MASK* = {5..6};
    REQ_TYPE_STANDARD* = {};
    REQ_TYPE_CLASS* = {5};
    REQ_TYPE_VENDOR* = {6};
    REQ_TYPE_RESERVED* = {5..6};

  (* bmRequestType D4..0 Recipient *)
    REQ_RECIPIENT_MASK* = {0..4};
    REQ_RECIPIENT_DEVICE* = TOSET(0);
    REQ_RECIPIENT_INTERFACE* = TOSET(1);
    REQ_RECIPIENT_ENDPOINT* = TOSET(2);
    REQ_RECIPIENT_OTHER* = TOSET(3);

  (* Table 9-4. Standard Request Codes  *)
  (* bRequest , Value *)
    REQ_GET_STATUS* = 0;
    REQ_CLEAR_FEATURE* = 1;
    REQ_SET_FEATURE* = 3;
    REQ_SET_ADDRESS* = 5;
    REQ_GET_DESCRIPTOR* = 6;
    REQ_SET_DESCRIPTOR* = 7;
    REQ_GET_CONFIGURATION* = 8;
    REQ_SET_CONFIGURATION* = 9;
    REQ_GET_INTERFACE* = 0AH;
    REQ_SET_INTERFACE* = 0BH;
    REQ_SYNCH_FRAME* = 0CH;

  (* Table 9-5. Descriptor Types of USB Specifications *)
    DESC_TYPE_DEVICE* = 1;
    DESC_TYPE_CONFIGURATION* = 2;
    DESC_TYPE_STRING* = 3;
    DESC_TYPE_INTERFACE* = 4;
    DESC_TYPE_ENDPOINT* = 5;
    DESC_TYPE_DEVICE_QUALIFIER* = 6;
    DESC_TYPE_OTHER_SPEED_CONFIGURATION* = 7;
    DESC_TYPE_INTERFACE_POWER* = 8;
    DESC_TYPE_HID* = 21H;
    DESC_TYPE_HID_REPORT* = 22H;

  (* Descriptor Type and Descriptor Index  *)
  (* Use the following values when calling the function USBH.GetDescriptor  *)
    DESC_DEVICE* = TOSET(LSL(DESC_TYPE_DEVICE,  8));
    DESC_CONFIGURATION* = TOSET(LSL(DESC_TYPE_CONFIGURATION,  8));
    DESC_STRING* = TOSET(LSL(DESC_TYPE_STRING,  8));
    DESC_INTERFACE* = TOSET(LSL(DESC_TYPE_INTERFACE,  8));
    DESC_ENDPOINT* = TOSET(LSL(DESC_TYPE_INTERFACE,  8));
    DESC_DEVICE_QUALIFIER* = TOSET(LSL(DESC_TYPE_DEVICE_QUALIFIER,  8));
    DESC_OTHER_SPEED_CONFIGURATION* = TOSET(LSL(DESC_TYPE_OTHER_SPEED_CONFIGURATION,  8));
    DESC_INTERFACE_POWER* = TOSET(LSL(DESC_TYPE_INTERFACE_POWER,  8));
    DESC_HID_REPORT* = TOSET(LSL(DESC_TYPE_HID_REPORT,  8));
    DESC_HID* = TOSET(LSL(DESC_TYPE_HID,  8));

  (*Device status*)
    CONFIG_REMOTE_WAKEUP* = 1;
    CONFIG_SELF_POWERED* = 0;

  (*Features selectors*)
    (*Endpoint*)
    FEATURE_EP_HALT* = 0;
    (*Device*)
    FEATURE_REMOTE_WAKEUP* = 1;
    FEATURE_TEST_MODE* = 2;

  (* standard descriptor lengthes*)
    LEN_DESC_HDR* =  2;
    LEN_DEV_DESC* = 12H;
    LEN_CFG_DESC* = 9;
    LEN_IF_DESC* = 9;
    LEN_EP_DESC* = 7;
    LEN_DQ_DESC* = 10;
    LEN_OTG_DESC* = 3;
    LEN_HID_DESC* = 9;
    LEN_LANGID_STR_DESC* = 4;
    LEN_SETUP_PKT* = 8;

  (* User callback reason codes *)
    (*Host reasons*)
    USER_SELECT_CONFIGURATION* = 1;
    USER_CLASS_ACTIVE* = 2;
    USER_CLASS_SELECTED* = 3;
    USER_CONNECTION* = 4;
    USER_DISCONNECTION* = 5;
    USER_UNRECOVERED_ERROR* = 6;
    (*Core reasons*)
    USER_USB_RESET* = 7;
    (*Peripheral reasons*)
    USER_ASSIGN_DESCRIPTORS* = 8;
    USER_REGISTER_DETAILS* = 9;

  TYPE
    Task* = POINTER TO TaskDesc;
    TaskDesc = RECORD task: Oberon.Task END;

    Buffer* = POINTER TO BufferDesc;
    BufferDesc* = RECORD size*, length*, index*,
      pktidx*, pktlen*: HALFWORD; (*beginning and size of a transmitted packet*)
      ReadByte*: PROCEDURE(b: Buffer): BYTE;
      WriteByte*: PROCEDURE(b: Buffer; v: BYTE)
    END;

    Setup* = RECORD(BufferDesc)
      bmRequestType*: BYTESET; bRequest*: BYTE;
      wValue*, wIndex*, wLength*: HALFWORD
    END;

    IntegerBuffer* = POINTER TO IntegerBufferDesc;
    IntegerBufferDesc* = RECORD(BufferDesc) val*: INTEGER END;

    ByteBuffer* = POINTER TO ByteBufferDesc;
    ByteBufferDesc* = RECORD(BufferDesc) val*: BYTE END;

    DescriptorGetters* = POINTER TO DescriptorGettersDesc;
    DescriptorGettersDesc* = RECORD END;

    RawDescriptorData* = RECORD(BufferDesc)
      buf*: ARRAY Conf.MAX_DESCRIPTOR_SIZE OF BYTE
    END;

    RawDescriptor* = POINTER TO RawDescriptorDesc;
    RawDescriptorDesc* = RECORD(RawDescriptorData)
      headeridx: HALFWORD
    END;

    Class* = POINTER TO ClassDesc;
    ClassDesc* = RECORD END;

    ClassHandle* = POINTER TO ClassHandleDesc;
    ClassHandleDesc* = RECORD END;

    Handle* = POINTER TO HandleDesc;
    Callback* = PROCEDURE^5(usb: Handle): BYTE;
    UserCallback* = PROCEDURE(usbid, reason: BYTE);

    HandleDesc* = RECORD
      id*: BYTE;
      User*: UserCallback;
    END;

  VAR usbCores*: ARRAY NB_OTG_CORES OF Handle; nofRegisteredCores*: BYTE;

 (* ------- utility procedures ------- *)

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

  PROCEDURE MAX*(a, b: INTEGER): INTEGER;
    VAR res: INTEGER;
  BEGIN IF a > b THEN res := a ELSE res := b END

    RETURN res
  END MAX;

 (* ------- buffer handling procedures ------- *)

  PROCEDURE PutByte*(b: Buffer; v: BYTE);
  BEGIN b.WriteByte(b, v); INC(b.length)
  END PutByte;

  PROCEDURE PutByteSet*(b: Buffer; v: BYTESET);
  BEGIN PutByte(b, ORD(v))
  END PutByteSet;

  PROCEDURE PutHalfword*(b: Buffer; v: HALFWORD);
  BEGIN PutByte(b, v MOD 100H); PutByte(b, v DIV 100H)
  END PutHalfword;

  PROCEDURE PutInteger*(b: Buffer; v: INTEGER);
  BEGIN PutByte(b, v MOD 100H); PutByte(b, v DIV 100H MOD 100H);
    PutByte(b, v DIV 10000H MOD 100H); PutByte(b, v DIV 1000000H)
  END PutInteger;

  PROCEDURE GetByte*(b: Buffer): BYTE;

    RETURN b.ReadByte(b)
  END GetByte;

  PROCEDURE GetHalfword*(b: Buffer): HALFWORD;

    RETURN 0M+ GetByte(b) + 100H*GetByte(b)
  END GetHalfword;

  PROCEDURE GetInteger*(b: Buffer): INTEGER;

    RETURN 0 + GetByte(b) + 100H*GetByte(b) + 10000H*GetByte(b) + 1000000H*GetByte(b)
  END GetInteger;

  (* ------- raw descriptor decoding procedures ------- *)

 PROCEDURE Reset*(VAR rd: RawDescriptorDesc);
  BEGIN rd.index := 0; rd.headeridx := 0
  END Reset;

  PROCEDURE NextHeaderIdx(rd: RawDescriptorDesc): HALFWORD;

    RETURN rd.headeridx + rd.buf[rd.headeridx]
  END NextHeaderIdx;

  PROCEDURE HeaderType*(rd: RawDescriptorDesc): BYTE;

    RETURN rd.buf[rd.headeridx + 1]
  END HeaderType;

  PROCEDURE HeaderSize*(rd: RawDescriptorDesc): BYTE;

    RETURN rd.buf[rd.headeridx]
  END HeaderSize;

  PROCEDURE HasMoreHeaders*(rd: RawDescriptorDesc): BOOLEAN;

    RETURN (rd.index < LE16(rd.buf, 2)) & (NextHeaderIdx(rd) < LE16(rd.buf, 2))
  END HasMoreHeaders;

  PROCEDURE GoNextHeader*(VAR buf: RawDescriptorDesc);
  BEGIN buf.headeridx := NextHeaderIdx(buf); buf.index := buf.headeridx
  END GoNextHeader;

  PROCEDURE ReadByte*(VAR rd: RawDescriptorDesc): BYTE;
    VAR res: BYTE;
  BEGIN
    IF rd.index < NextHeaderIdx(rd) THEN res := rd.buf[rd.index]; INC(rd.index)
    ELSE res := 0 END

    RETURN res
  END ReadByte;

  PROCEDURE ReadHalfword*(VAR rd: RawDescriptorDesc): HALFWORD;
    VAR res: HALFWORD;
  BEGIN
    IF rd.index < NextHeaderIdx(rd) - 1 THEN res := LE16(rd.buf, rd.index); INC(rd.index, 2)
    ELSE res := 0 END

    RETURN res
  END ReadHalfword;

  PROCEDURE DescriptorByteAt*(rd: RawDescriptorDesc; ofs: INTEGER): BYTE;

    RETURN rd.buf[rd.headeridx + ofs]
  END DescriptorByteAt;

  PROCEDURE PutByteInDescriptorAt*(VAR rd: RawDescriptorDesc; ofs: INTEGER; v: BYTE);
  BEGIN rd.buf[rd.headeridx + ofs] := v
  END PutByteInDescriptorAt;

  PROCEDURE PutHalfwordInDescriptorAt*(VAR rd: RawDescriptorDesc; ofs: INTEGER; v: HALFWORD);
  BEGIN PutByteInDescriptorAt(rd, ofs, v MOD 100H); PutByteInDescriptorAt(rd, ofs + 1, v DIV 100H)
  END PutHalfwordInDescriptorAt;

 (* ------- raw descriptor creator ------- *)

  PROCEDURE NewRawDescriptor*(): RawDescriptor;
    VAR rd!: RawDescriptor;
  BEGIN NEW(rd); rd.size := SYSTEM.SIZE(RawDescriptorData) - SYSTEM.SIZE(BufferDesc)

    RETURN rd
  END NewRawDescriptor;

  (* ------- configuration raw descriptor search procedures ------- *)

  (**
  * @brief  GetEpDesc
  *         This function set the raw descriptor index to the Endpoint descriptor
  * @param  ConfDesc:  the configuration raw descriptor
  * @param  EpAddr:  endpoint address
  * @retval TRUE if the specified endpoint has been found
  *)
  PROCEDURE GetEpDesc*(VAR cd: RawDescriptorDesc; EpAddr: BYTE): BOOLEAN;
    VAR found: BOOLEAN;
  BEGIN found := FALSE; Reset(cd);
    WHILE ~found & HasMoreHeaders(cd) DO GoNextHeader(cd);
      IF (HeaderType(cd) = DESC_TYPE_ENDPOINT) & (DescriptorByteAt(cd, 2) = EpAddr) THEN found := TRUE END
    END

    RETURN found
  END GetEpDesc;

  (* ------- task management procedures ------- *)

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

END USBDef.

OM4Tool.DecSym USBDef.sm4
