MODULE USBHDef;
  (** USB host definitions, ported to Oberon from:
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

    ADDRESS_DEFAULT* = 0;
    ADDRESS_ASSIGNED* = 1;
    MPS_DEFAULT* = 40H;

    REMOTE_WAKEUP* = 5;
    SELF_POWERED* = 6;

  TYPE
    (* Control request structure *)
    Ctrl* = RECORD
      pipe_in*, pipe_out*, pipe_size*: BYTE;
      length*, timer*: INTEGER;
      setup*: Def.Setup;
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

    (* Attached device structure *)
    Device* = RECORD
      CfgRaw*, tmprd*: Def.RawDescriptorDesc;
      address*, speed*, EnumCnt*, RstCnt*: BYTE;
      is_connected*, is_disconnected*, is_ReEnumerated*, PortEnabled*: BOOLEAN;
      current_interface*: BYTE;
      DevDesc*: DevDescriptor;
      CfgDesc*: CfgDescriptor
    END;

    Handle* = POINTER TO HandleDesc;

    (* USB Host Class structure *)
    Class* = POINTER TO ClassDesc;
    ClassDesc* = RECORD(Def.ClassDesc)
      Name*: ARRAY 8 OF CHAR;
      ClassCode*: BYTE;
      Init*, DeInit*, Requests*, BgndProcess*: PROCEDURE(host: Def.Handle): BYTE;
      SOFProcess*: Def.Callback;
      clsh*: Def.ClassHandle
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
      Stop*: PROCEDURE^5(phost: Def.Handle);
      OpenPipe*: PROCEDURE(phost: Handle; pipe_num, epnum, dev_address, speed, ep_type: BYTE; mps: HALFWORD);
      SetToggle*: PROCEDURE(phost: Handle; pipe: BYTE; toggle: BOOLEAN);
      ClosePipe*: PROCEDURE(phost: Handle; pipe_num: BYTE);
      SubmitURB*: PROCEDURE(phost: Handle; pipe: BYTE; direction: BOOLEAN; ep_type, token: BYTE;
        buff: Def.BufferDesc; do_ping: BOOLEAN);
      GetURBState*:  PROCEDURE(phost: Handle; pipe: BYTE): BYTE;
      GetLastXferSize*: PROCEDURE(phost: Handle; pipe: BYTE): INTEGER
    END;

 END USBHDef.

OM4Tool.DecSym USBHDef.sm4
