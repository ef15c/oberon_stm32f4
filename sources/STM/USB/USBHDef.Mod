MODULE USBHDef;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   USB host library common definitions
  ******************************************************************************
  *)
  IMPORT SYSTEM, Conf := USBHConf, Def := USBDef, UC := HALUC, Log := USBLog;

  CONST
    DEV_RESET_TIMEOUT* = 1000;

    (* Following states are used for gState *)
    IDLE* = 0;
    HOST_DEV_WAIT_FOR_ATTACHMENT* = 1;
    HOST_DEV_ATTACHED* = 2;
    HOST_DEV_DISCONNECTED* = 3;
    HOST_DETECT_DEVICE_SPEED* = 4;
    HOST_ENUMERATION* = 5;
    HOST_CLASS_REQUEST* = 6;
    HOST_INPUT* = 7;
    HOST_SET_CONFIGURATION* = 8;
    HOST_SET_WAKEUP_FEATURE* = 9;
    HOST_CHECK_CLASS* = 10;
    HOST_CLASS* = 11;
    HOST_SUSPENDED* = 12;
    HOST_ABORT_STATE* = 13;

  (* Following states are used for EnumerationState *)
    ENUM_GET_FULL_DEV_DESC* = 1;
    ENUM_SET_ADDR* = 2;
    ENUM_GET_CFG_DESC* = 3;
    ENUM_GET_FULL_CFG_DESC* = 4;
    ENUM_GET_MFC_STRING_DESC* = 5;
    ENUM_GET_PRODUCT_STRING_DESC* = 6;
    ENUM_GET_SERIALNUM_STRING_DESC* = 7;

  (* Following states are used for CtrlXferStateMachine *)
    CTRL_SETUP* = 1;
    CTRL_SETUP_WAIT* = 2;
    CTRL_DATA_IN* = 3;
    CTRL_DATA_IN_WAIT* = 4;
    CTRL_DATA_OUT* = 5;
    CTRL_DATA_OUT_WAIT* = 6;
    CTRL_STATUS_IN* = 7;
    CTRL_STATUS_IN_WAIT* = 8;
    CTRL_STATUS_OUT* = 9;
    CTRL_STATUS_OUT_WAIT* = 10;
    CTRL_ERROR* = 11;
    CTRL_STALLED* = 12;
    CTRL_COMPLETE* =13 ;

  (* Following states are used for RequestState *)
    CMD_SEND* = 1;
    CMD_WAIT* = 2;

    URB_DONE* = 1;
    URB_NOTREADY* = 2;
    URB_NYET* = 3;
    URB_ERROR* = 4;
    URB_STALL* = 5;
    URB_NAK_WAIT* = 6;

  (* Following USB Host status *)
    NOT_SUPPORTED* = 3;
    UNRECOVERED_ERROR* = 4;
    ERROR_SPEED_UNKNOWN* = 5;

    MAX_PIPES_NBR* = 16;

    DEVICE_ADDRESS_DEFAULT* = 0;
    DEVICE_ADDRESS* = 1;

    MAX_ERROR_COUNT* = 2;

    MAX_EP_PACKET_SIZE* = 400H;
    MAX_DATA_BUFFER* = 400H;

    LEN_DESC_HDR* =  2;
    LEN_DEV_DESC* = 12H;
    LEN_CFG_DESC* = 9;
    LEN_IF_DESC* = 9;
    LEN_EP_DESC* = 7;
    LEN_OTG_DESC* = 3;
    LEN_SETUP_PKT* = 8;

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

    DEVICE_DESC_SIZE* = 12H;
    CONFIGURATION_DESC_SIZE* = 9;
    HID_DESC_SIZE* = 9;
    INTERFACE_DESC_SIZE* = 9;
    ENDPOINT_DESC_SIZE* = 7;

  (* Descriptor Type and Descriptor Index  *)
  (* Use the following values when calling the function USBH_GetDescriptor  *)
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

    ADDRESS_DEFAULT* = 0;
    ADDRESS_ASSIGNED* = 1;
    MPS_DEFAULT* = 40H;

    REMOTE_WAKEUP* = 5;
    SELF_POWERED* = 6;

  TYPE
    DataBuffer* = ARRAY Conf.MAX_DATA_BUFFER OF BYTE;

    Setup* = RECORD(Def.Buffer)
      bmRequestType*: BYTESET; bRequest*: BYTE;
      wValue*, wIndex*, wLength*: HALFWORD
    END;

    (* Control request structure *)
    Ctrl* = RECORD
      pipe_in*, pipe_out*, pipe_size*: BYTE;
      length*, timer*: INTEGER;
      setup*: Setup;
      state*: BYTE;
      errorcount*: BYTE
    END;

    DevDescriptor* = RECORD
      bLength*,
      bDescriptorType*: BYTE;
      bcdUSB*: HALFWORD; (* USB Specification Number which device complies too *)
      bDeviceClass*, (* If equal to Zero, each interface specifies its own class
        code if equal to 0xFF, the class code is vendor specified.
        Otherwise field is valid Class Code.*)
      bDeviceSubClass*,
      bDeviceProtocol*,
      bMaxPacketSize*: BYTE;
      idVendor*, (* Vendor ID (Assigned by USB Org) *)
      idProduct*, (* Product ID (Assigned by Manufacturer) *)
      bcdDevice*: HALFWORD; (* Device Release Number *)
      iManufacturer*, (* Index of Manufacturer String Descriptor *)
      iProduct*, (* Index of Product String Descriptor *)
      iSerialNumber*, (* Index of Serial Number String Descriptor *)
      bNumConfigurations*: BYTE (* Number of Possible Configurations *)
    END;

    EpDescriptor* = RECORD
      bLength*, bDescriptorType*,
      bEndpointAddress*: BYTE; (* indicates what endpoint this descriptor is describing *)
      bmAttributes*: BYTESET; (* specifies the transfer type. *)
      wMaxPacketSize*: HALFWORD; (* Maximum Packet Size this endpoint is capable of sending or receiving *)
      bInterval*: BYTE (* is used to specify the polling interval of certain transfers. *)
    END;

    InterfaceDescriptor* = RECORD
      bLength*, bDescriptorType*, bInterfaceNumber*,
      bAlternateSetting*, (* Value used to select alternative setting *)
      bNumEndpoints*, (* Number of Endpoints used for this interface *)
      bInterfaceClass*, (* Class Code (Assigned by USB Org) *)
      bInterfaceSubClass*, (* Subclass Code (Assigned by USB Org) *)
      bInterfaceProtocol*, (* Protocol Code *)
      iInterface*: BYTE; (* Index of String Descriptor Describing this interface *)
      Ep_Desc*: ARRAY Conf.MAX_NUM_ENDPOINTS OF EpDescriptor
    END;

    CfgDescriptor* = RECORD
      bLength*, bDescriptorType*: BYTE;
      wTotalLength*: HALFWORD; (* Total Length of Data Returned *)
      bNumInterfaces*, (* Number of Interfaces *)
      bConfigurationValue*, (* Value to use as an argument to select this configuration*)
      iConfiguration*: BYTE; (* Index of String Descriptor Describing this configuration *)
      bmAttributes*: BYTESET; (* D7 Bus Powered , D6 Self Powered, D5 Remote Wakeup , D4..0 Reserved (0)*)
      bMaxPower*: BYTE; (* Maximum Power Consumption *)
      Itf_Desc*: ARRAY Conf.MAX_NUM_INTERFACES OF InterfaceDescriptor
    END;

    RawDescriptorData* = RECORD(Def.Buffer) buf*: ARRAY Conf.MAX_SIZE_CONFIGURATION OF BYTE END;

    RawDescriptor* = RECORD(RawDescriptorData)
      length*, index, headeridx: HALFWORD
    END;

    (* Attached device structure *)
    Device* = RECORD
      CfgRaw*, tmprd*: RawDescriptor;
      address*, speed*, EnumCnt*, RstCnt*: BYTE;
      is_connected*, is_disconnected*, is_ReEnumerated*, PortEnabled*: BOOLEAN;
      current_interface*: BYTE;
      DevDesc*: DevDescriptor;
      CfgDesc*: CfgDescriptor
    END;

    Handle* = POINTER TO HandleDesc;

    ClassHandle* = POINTER TO ClassHandleDesc;
    ClassHandleDesc* = RECORD END;

    (* USB Host Class structure *)
    Class* = POINTER TO ClassDesc;
    ClassDesc* = RECORD(Def.ClassDesc)
      Name*: ARRAY 8 OF CHAR;
      ClassCode*: BYTE;
      Init*, DeInit*, Requests*, BgndProcess*: PROCEDURE(host: Def.Handle): BYTE;
      SOFProcess*: Def.Callback;
      clsh*: ClassHandle
    END;

    (* USB Host handle structure *)
    HandleDesc* = RECORD(UC.HandleDesc)
      gState*: BYTE; (*  Host State Machine Value *)
      EnumState*: BYTE; (** Enumeration state Machine *)
      RequestState*: BYTE;
      Control*: Ctrl;
      device*: Device;
      Class*: ARRAY Conf.MAX_NUM_SUPPORTED_CLASS OF Class;
      ActiveClass*: Class;
      ClassNumber*: INTEGER;
      Pipes*: ARRAY MAX_PIPES_NBR OF SET;
(*      Timer*: INTEGER; (*seems to act as a frame counter*)*)
(*#if defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U)
  uint32_t              NakTimer;
  uint32_t              NakTimeout;
#endif /* defined (USBH_IN_NAK_PROCESS) && (USBH_IN_NAK_PROCESS == 1U) */*)
      Timeout*: INTEGER;
      Stop*: PROCEDURE^5(phost: Handle);
      OpenPipe*: PROCEDURE(phost: Handle; pipe_num, epnum, dev_address, speed, ep_type: BYTE; mps: HALFWORD);
      SetToggle*: PROCEDURE(phost: Handle; pipe: BYTE; toggle: BOOLEAN);
      ClosePipe*: PROCEDURE(phost: Handle; pipe_num: BYTE);
      SubmitURB*: PROCEDURE(phost: Handle; pipe: BYTE; direction: BOOLEAN; ep_type, token: BYTE;
        buff: Def.Buffer; length: HALFWORD; do_ping: BOOLEAN);
      GetURBState*:  PROCEDURE(phost: Handle; pipe: BYTE): BYTE;
      GetLastXferSize*: PROCEDURE(phost: Handle; pipe: BYTE): INTEGER
    END;

  PROCEDURE Reset*(VAR rd: RawDescriptor);
  BEGIN rd.index := 0; rd.headeridx := 0
  END Reset;

  PROCEDURE NextHeaderIdx(rd: RawDescriptor): HALFWORD;

    RETURN rd.headeridx + rd.buf[rd.headeridx]
  END NextHeaderIdx;

  PROCEDURE HeaderType*(rd: RawDescriptor): BYTE;

    RETURN rd.buf[rd.headeridx + 1]
  END HeaderType;

  PROCEDURE HeaderSize*(rd: RawDescriptor): BYTE;

    RETURN rd.buf[rd.headeridx]
  END HeaderSize;

  PROCEDURE HasMoreHeaders*(rd: RawDescriptor): BOOLEAN;

    RETURN (rd.index < Def.LE16(rd.buf, 2)) & (NextHeaderIdx(rd) < Def.LE16(rd.buf, 2))
  END HasMoreHeaders;

  PROCEDURE GoNextHeader*(VAR buf: RawDescriptor);
  BEGIN buf.headeridx := NextHeaderIdx(buf); buf.index := buf.headeridx
  END GoNextHeader;

  PROCEDURE ReadByte*(VAR rd: RawDescriptor): BYTE;
    VAR res: BYTE;
  BEGIN
    IF rd.index < NextHeaderIdx(rd) THEN res := rd.buf[rd.index]; INC(rd.index)
    ELSE res := 0 END

    RETURN res
  END ReadByte;

  PROCEDURE ReadHalfword*(VAR rd: RawDescriptor): HALFWORD;
    VAR res: HALFWORD;
  BEGIN
    IF rd.index < NextHeaderIdx(rd) - 1 THEN res := Def.LE16(rd.buf, rd.index); INC(rd.index, 2)
    ELSE res := 0 END

    RETURN res
  END ReadHalfword;

  PROCEDURE GetIndex*(buf: RawDescriptor): HALFWORD;

    RETURN buf.index
  END GetIndex;

END USBHDef.

OM4Tool.DecSym USBHDef.sm4
