MODULE USBHHIDClass; (*HID class process structures*)
  IMPORT Def := USBHDef, Log := USBLog;

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
      bcdHID*: HALFWORD;               (* HID class specification release *)
      bCountryCode*,        (* country code of the localized hardware *)
      bNumDescriptors*,     (* number of class descriptors (always at least one i.e. Report descriptor *)
      bReportDescriptorType*: BYTE;    (* type of the report class descriptor *)
      wItemLength*: HALFWORD;          (* total size of the report descriptors *)
    END;

    ReportData* = POINTER TO ReportDataDesc;
    ReportDataDesc = RECORD(Def.BufferDesc) buf*: ARRAY REPORT_SIZE OF BYTE END;

  (* Structure for HID process *)
    Handle* = POINTER TO HandleDesc;
    HandleDesc* = RECORD(Def.ClassHandleDesc)
      OutPipe*, InPipe*, state*, OutEp*, InEp*, ctl_state*: BYTE;
      fifo*: FIFODesc;
      Data*: ReportData;
      length*: HALFWORD;
      ep_addr*: BYTE;
      poll*: HALFWORD;
      timer*: INTEGER;
      DataReady*: BOOLEAN;
      HID_Desc*: DescriptorDesc;
      ReportDesc*: Def.RawDescriptor;
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

  (**
  * @brief  USBH_HID_FifoRead
  *         Read from FIFO.
  * @param  f: Fifo address
  * @param  buf: read buffer
  * @param  nbytes: number of item to read
  * @retval number of read items
  *)
  PROCEDURE FifoRead*(VAR f: FIFODesc; VAR buf: ARRAY OF BYTE; nbytes: HALFWORD): HALFWORD;
    VAR i: HALFWORD;
  BEGIN
    IF ~f.lock THEN f.lock := TRUE; i := 0;
      WHILE (i < nbytes) & (f.tail # f.head) DO buf[i] := f.buf[f.tail];
        INC(f.tail); IF f.tail = LEN(f.buf) THEN f.tail := 0 END;
        INC(i)
      END
    END;
    f.lock := FALSE

    RETURN i
  END FifoRead;

  (**
  * @brief  USBH_HID_FifoWrite
  *         Write To FIFO.
  * @param  f: Fifo address
  * @param  buf: read buffer
  * @param  nbytes: number of item to write
  * @retval number of written items
  *)
  PROCEDURE FifoWrite*(VAR f: FIFODesc; buf: ARRAY OF BYTE; nbytes: HALFWORD): HALFWORD;
    VAR i: HALFWORD;
  BEGIN
    Log.Debug("FIFO write "); Log.DebugInt(nbytes, 1); Log.DebugString(" bytes"); Log.DebugLn;
    IF ~f.lock THEN f.lock := TRUE; i := 0;
      WHILE (i < nbytes) & (f.head + 1 # f.tail) & ((f.head + 1 # LEN(f.buf)) OR (f.tail # 0)) DO
        f.buf[f.head] := buf[i]; INC(f.head);
        IF f.head = LEN(f.buf) THEN f.head := 0 END;
        INC(i)
      END
    END;
    f.lock := FALSE

    RETURN i
  END FifoWrite;

END USBHHIDClass.

OM4Tool.DecSym USBHHIDClass.sm4
