MODULE USBHHIDClass; (*HID class process structures*)
  IMPORT Def := USBHDef;

 CONST
    (* HID Class Codes *)
    CLASS* = 3;

  (* Interface Descriptor field values for HID Boot Protocol *)
    BOOT_CODE* = 1;
    KEYBRD_BOOT_CODE* = 1;
    MOUSE_BOOT_CODE* = 2;

  (* States for HID State Machine *)
    INIT* = 0;
    IDLE* = 1;
    SEND_DATA* = 2;
    BUSY* = 3;
    GET_DATA* = 4;
    SYNC* = 5;
    POLL* = 6;
    ERROR* = 7;

    REQ_INIT* =  0;
    REQ_IDLE* = 1;
    REQ_GET_REPORT_DESC* = 2;
    REQ_GET_HID_DESC* = 3;
    REQ_SET_IDLE* = 4;
    REQ_SET_PROTOCOL* = 5;
    REQ_SET_REPORT* = 6;

  (** @defgroup USBH_HID_CORE_Exported_Defines
  * @{
  *)

    GET_REPORT* = 1;
    GET_IDLE* = 2;
    GET_PROTOCOL* = 3;
    SET_REPORT* = 9;
    SET_IDLE* = 0AH;
    SET_PROTOCOL* = 0BH;

    MIN_POLL* = 10;
    REPORT_SIZE* = 16;
    MAX_USAGE* = 10;
    MAX_NBR_REPORT_FMT* = 10;
    QUEUE_SIZE* = 10;

  TYPE
    FIFODesc* = RECORD
      buf*: Def.DataBuffer;
      head*, tail*: HALFWORD;
      lock*: BOOLEAN
    END;

    Descriptor* = POINTER TO DescriptorDesc;
    DescriptorDesc* = RECORD
      bLength*, bDescriptorType*: BYTE;
      bcdHID*: HALFWORD;               (* indicates what endpoint this descriptor is describing *)
      bCountryCode*,        (* specifies the transfer type. *)
      bNumDescriptors*,     (* specifies the transfer type. *)
      bReportDescriptorType*: BYTE;    (* Maximum Packet Size this endpoint is capable of sending or receiving *)
      wItemLength*: HALFWORD;          (* is used to specify the polling interval of certain transfers. *)
    END;

  (* Structure for HID process *)
    Handle* = POINTER TO HandleDesc;
    HandleDesc* = RECORD(Def.ClassHandleDesc)
      OutPipe*, InPipe*, state*, OutEp*, InEp*, ctl_state*: BYTE;
      fifo*: FIFODesc;
      pData*: ARRAY REPORT_SIZE OF BYTE;
      length*: HALFWORD;
      ep_addr*: BYTE;
      poll*: HALFWORD;
      timer*: INTEGER;
      DataReady*: BOOLEAN;
      HID_Desc*: DescriptorDesc;
      Init*: Def.Callback;
      EventCallback*: PROCEDURE(phost: Def.Handle)
    END;

  (**
  * @brief  USBH_HID_FifoInit
  *         Initialize FIFO.
  * @param  f: Fifo address
  * @param  buf: Fifo buffer
  * @param  size: Fifo Size
  * @retval none
  *)
  PROCEDURE FifoInit*(VAR f: FIFODesc);
  BEGIN f.head := 0; f.tail := 0;  f.lock := FALSE
  END FifoInit;

END USBHHIDClass.

OM4Tool.DecSym USBHHIDClass.sm4
