MODULE USBDDef;
  (** USB device definitions, ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   USB host library common definitions
  ******************************************************************************
  *)
  IMPORT Conf := USBDConf, Def := USBDef, UC := HALUC;

  CONST
(*
#ifdef USE_USBD_COMPOSITE
    MAX_SUPPORTED_CLASS* = 4;
#else
*)
    MAX_SUPPORTED_CLASS* = 1;
(*
#endif /* USE_USBD_COMPOSITE */
*)

    MAX_POWER* = 50; (* 100 mA *)

  (*  Device Status *)
    STATE_DEFAULT* = 1;
    STATE_ADDRESSED* = 2;
    STATE_CONFIGURED* = 3;
    STATE_SUSPENDED* = 4;

  (*  EP0 State *)
    EP0_SETUP* = 1;
    EP0_DATA_IN* = 2;
    EP0_DATA_OUT* = 3;
    EP0_STATUS_IN* = 4;
    EP0_STATUS_OUT* = 5;
    EP0_STALL* = 6;

    IDX_LANGID_STR* = 0;
    IDX_MFC_STR* = 1;
    IDX_PRODUCT_STR* = 2;
    IDX_SERIAL_STR* = 3;
    IDX_CONFIG_STR* = 4;
    IDX_INTERFACE_STR* = 5;

  TYPE
  (* USB Device handle structure *)
    Endpoint* = RECORD
      rem_length*,
      maxpacket*: HALFWORD;
      bInterval*: INTEGER;
      status*: BYTE;
      is_used*: BOOLEAN;
      buffer*: Def.Buffer
    END;

  (* USB Device descriptors structure *)
    DescriptorGetters* = POINTER TO DescriptorGettersDesc;
    DescriptorGettersDesc* = RECORD(Def.DescriptorGettersDesc)
      GetDeviceDescriptor*, GetLangIDStrDescriptor*, GetManufacturerStrDescriptor*,
      GetProductStrDescriptor*, GetSerialStrDescriptor*, GetConfigurationStrDescriptor*,
      GetInterfaceStrDescriptor*: PROCEDURE(speed: BYTE): Def.Buffer
(*#if (USBD_CLASS_USER_STRING_DESC == 1)
  uint8_t *( *GetUserStrDescriptor)(USBD_SpeedTypeDef speed, uint8_t idx, uint16_t *length);
#endif /* USBD_CLASS_USER_STRING_DESC */*)
(*#if ((USBD_LPM_ENABLED == 1U) || (USBD_CLASS_BOS_ENABLED == 1))
  uint8_t *( *GetBOSDescriptor)(USBD_SpeedTypeDef speed, uint16_t *length);
#endif /* (USBD_LPM_ENABLED == 1U) || (USBD_CLASS_BOS_ENABLED == 1) */*)
    END;

    Handle* = POINTER TO HandleDesc;

    Class* = POINTER TO ClassDesc;
    ClassDesc* = RECORD(Def.ClassDesc)
      Init*: PROCEDURE(dev: Handle; cfgidx: BYTE): BYTE;
      DeInit*: PROCEDURE(dev: Handle; cfgidx: BYTE);
      (* Control Endpoints*)
      Setup*: PROCEDURE(dev: Handle; req: Def.Setup): BYTE;
      EP0_TxSent*, EP0_RxReady*: PROCEDURE(dev: Handle);
      (* Class Specific Endpoints*)
      DataIn*, DataOut*: PROCEDURE(dev: Handle; epnum: BYTE);
      SOF*: PROCEDURE(dev: Handle): BYTE;
      IsoINIncomplete*, IsoOUTIncomplete*: PROCEDURE(dev: Handle; epnum: BYTE);
      GetHSConfigDescriptor*, GetFSConfigDescriptor*, GetOtherSpeedConfigDescriptor*,
      GetDeviceQualifierDescriptor*: PROCEDURE(): Def.Buffer;
      GetUsrStrDescriptor*: PROCEDURE(dev: Handle; index: BYTE): Def.Buffer
    END;

    UserData* = POINTER TO UserDataDesc;
    UserDataDesc* = RECORD END;

    HandleDesc* = RECORD(UC.HandleDesc)
      config*, default_config*: BYTE;
      config_status*: HALFSET;
      speed*: BYTE;
      useUsbHS*: BOOLEAN; (*tells whether HS or FS device descriptor must be presented*)
      ep_in*,
      ep_out*: ARRAY 16 OF Endpoint;
      ep0_state*,
      ep0_data_len*: INTEGER;
      state*,
      old_state*,
      address*,
      connection_status*,
      test_mode*: BYTE;
      remote_wakeup*: BOOLEAN;
      ConfIdx*: BYTE;
      request*: Def.Setup;
      Desc*: DescriptorGetters;
      Class*: ARRAY MAX_SUPPORTED_CLASS OF Class;
      ClassData*: Def.ClassHandle;
      ClassDataCmsit*: ARRAY MAX_SUPPORTED_CLASS OF Def.ClassHandle;
      UserData*: ARRAY MAX_SUPPORTED_CLASS OF UserData;
(*  void                    *pBosDesc;*)
      ConfDesc*: Def.Buffer;
      classId*, NumClasses*: INTEGER;
(*#ifdef USE_USBD_COMPOSITE
  USBD_CompositeElementTypeDef tclasslist[USBD_MAX_SUPPORTED_CLASS];
#endif /* USE_USBD_COMPOSITE */*)
      StateCallback*: PROCEDURE(dev_state, cfgidx: BYTE); (*!< User Notification callback      *)
      (*Oberon specific callbacks*)
      StallEP*, ClearStallEP*,
      SetUSBAddress*: PROCEDURE(dev: Handle; address: BYTE);
      IsStallEP*: PROCEDURE(dev: Handle; address: BYTE): BOOLEAN;
      Transmit*: PROCEDURE(dev: Handle; address: BYTE; buf: Def.Buffer);
      SetClassConfig*: PROCEDURE(dev: Handle; config: BYTE): BYTE;
      ClrClassConfig*: PROCEDURE(dev: Handle; config: BYTE);
      CoreFindIF*: PROCEDURE(dev: Handle; itfidx: BYTE): BYTE;
      CoreFindEP*: PROCEDURE(dev: Handle; ep_addr: BYTE): BYTE;
      PrepareReceive*: PROCEDURE(dev: Handle; ep_addr: BYTE; buf: Def.Buffer);
      OpenEP*: PROCEDURE(dev: Handle; ep_addr, ep_type: BYTE; ep_mps: HALFWORD);
      GetRxDataSize*: PROCEDURE(dev: Handle; ep_addr: BYTE): INTEGER
    END;

END USBDDef.
