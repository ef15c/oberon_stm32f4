MODULE USBDMTPOberon;
  IMPORT SYSTEM, BSP, Kernel, FileSystem, FileDir, Files, Log := USBLog, Def := USBDef, USBDMTPDesc, O := USBDMTPOpt, M := USBDMTP;

  CONST STORAGE_ID = 00010001H;
    GROUP_NONE = 0;
    GROUP_FILE = 1;
    GROUP_BMP = 2;

    NOF_RESERVED_SECTORS = (Kernel.BootReservedSize + FileSystem.SectorSize - 1) DIV FileSystem.SectorSize + 2;
    MAX_SECTORS = FileSystem.NofSectors - NOF_RESERVED_SECTORS;
    MAX_CAPACITY = MAX_SECTORS* FileSystem.SectorSize;

  TYPE
    HandleList = POINTER TO HandleListDesc;
    HandleListDesc = RECORD
      next: HandleList; (*points to next handle array in the list*)
      nofh: INTEGER; (*number of handles in this array*)
      handles: ARRAY 1024 OF INTEGER
   END;

  VAR fops*: Def.UserData; Descriptors*: Def.DescriptorGetters; CLASS*: Def.Class;
    count: INTEGER; oPc, opGc, nbo: INTEGER; (*working variables for Get Object Prop List procedures*)
    ohl: HandleList; (*the list of the address of all files in the Oberon filesystem*)
    lohl: HandleList; idx: INTEGER; (*working variables for the file addresses list procedure*)
    F: Files.File; R: Files.Rider; (*for retrieving or storing object content*)

  PROCEDURE PutNextDataNone(dev: Def.Handle; d: Def.Buffer);
  BEGIN d.length := 0
  END PutNextDataNone;

  PROCEDURE WritePair(VAR d: ARRAY OF CHAR; VAR p: INTEGER; x: INTEGER);
  BEGIN d[p] := CHR(x DIV 10 + ORD("0")); INC(p);
    d[p] := CHR(x MOD 10 + ORD("0")); INC(p)
  END WritePair;

  (*convert an Oberon date to an ISO 8601 date in the format "YYYYMMDDThhmmss"*)
  PROCEDURE DateToString*(od: INTEGER; VAR iso: ARRAY OF CHAR);
    VAR l: INTEGER;
  BEGIN l := 0;
    iso[l] := "2"; INC(l); iso[l] := "0"; INC(l);
    WritePair(iso, l, od DIV 4000000H MOD 40H);   (*year*)
    WritePair(iso, l, od DIV 400000H MOD 10H); (*month*)
    WritePair(iso, l, od DIV 20000H MOD 20H);   (*day*)
    iso[l] := "T"; INC(l);
    WritePair(iso, l, od DIV 1000H MOD 20H);   (*hour*)
    WritePair(iso, l, od DIV 40H MOD 40H);  (*min*)
    WritePair(iso, l, od MOD 40H);  (*sec*)
    iso[l] := 0X
  END DateToString;

(*
  PROCEDURE GetExt(name: FileDir.FileName; VAR ext: FileDir.FileName);
    VAR i, l, dp: INTEGER;
  BEGIN l := 0;
    WHILE (l < LEN(name)) & (name[l] # 0X) DO
      IF name[l] = "." THEN dp := l + 1 END;
      INC(l)
    END; DEC(l);
    (*dp holds the position of the first character after the last dot
      l holds the position of the last character of the file name*)
    i := dp; WHILE i <= l DO ext[i - dp] := name[i]; INC(i) END;
    ext[i - dp] := 0X;
  END GetExt;

  PROCEDURE OFByExt(ext: FileDir.FileName): HALFWORD;
    VAR ofc: HALFWORD;
  BEGIN
(*
    IF ext = "m4c" THEN ofc := O.OBJ_FORMAT_EXECUTABLE
    ELSIF ext = "txt" THEN ofc := O.OBJ_FORMAT_TEXT
    ELSIF ext = "bmp" THEN ofc := O.OBJ_FORMAT_BMP
    ELSE *) ofc := O.OBJ_FORMAT_UNDEFINED
(*
    END
*)
    RETURN ofc
  END OFByExt;
*)

  (**
  * @brief  USBD_MTP_Itf_Init
  *         Initialize the file system Layer
  * @param  None
  *)
  PROCEDURE Init;
  END Init;

  (**
  * @brief  USBD_MTP_Itf_DeInit
  *         Uninitialize the file system Layer
  * @param  None
  *)
  PROCEDURE DeInit;
  BEGIN ohl := NIL; F := NIL; Files.Set(R, NIL, 0)
  END DeInit;

  (**
  * @brief  USBD_MTP_Itf_Cancel
  *         Close opened folder/file while cancelling transaction
  * @param  MTP_ResponsePhase: MTP current state
  * @retval None
  *)
  PROCEDURE Cancel(Phase: INTEGER);
  BEGIN F := NIL; Files.Set(R, NIL, 0) (* release file *)
  END Cancel;

  PROCEDURE Put0W1p(d: Def.Buffer; p1: INTEGER); (*generic procedure when putting 0W is required*)
  BEGIN Def.PutHalfword(d, 0)
  END Put0W1p;

  PROCEDURE Put0I1p(d: Def.Buffer; p1: INTEGER); (*generic procedure when putting 0 is required*)
  BEGIN Def.PutInteger(d, 0)
  END Put0I1p;

  PROCEDURE Put0S1p(d: Def.Buffer; p1: INTEGER); (*generic procedure when putting 0S is required*)
  BEGIN Def.PutByte(d, 0)
  END Put0S1p;

  PROCEDURE PutVendorExtension(d: Def.Buffer);
  BEGIN O.PutString(d, "microsoft.com: 1.0; ")
  END PutVendorExtension;

  PROCEDURE PutDeviceOpsSupported(d: Def.Buffer);
    VAR w: INTEGER;
  BEGIN
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.OP_GET_DEVICE_INFO); Def.PutHalfword(d, O.OP_OPEN_SESSION);
    Def.PutHalfword(d, O.OP_CLOSE_SESSION); Def.PutHalfword(d, O.OP_GET_STORAGE_IDS);
    Def.PutHalfword(d, O.OP_GET_STORAGE_INFO); Def.PutHalfword(d, O.OP_GET_NUM_OBJECTS);
    Def.PutHalfword(d, O.OP_GET_OBJECT_HANDLES); Def.PutHalfword(d, O.OP_GET_OBJECT_INFO);
    Def.PutHalfword(d, O.OP_GET_OBJECT); Def.PutHalfword(d, O.OP_DELETE_OBJECT);
    Def.PutHalfword(d, O.OP_SEND_OBJECT_INFO); Def.PutHalfword(d, O.OP_SEND_OBJECT);
    Def.PutHalfword(d, O.OP_GET_DEVICE_PROP_DESC); Def.PutHalfword(d, O.OP_GET_DEVICE_PROP_VALUE);
    Def.PutHalfword(d, O.OP_SET_OBJECT_PROP_VALUE); Def.PutHalfword(d, O.OP_GET_OBJECT_PROP_VALUE);
    Def.PutHalfword(d, O.OP_GET_OBJECT_PROPS_SUPPORTED);
    Def.PutHalfword(d, O.OP_GET_OBJECT_PROP_DESC);
    Def.PutHalfword(d, O.OP_GET_OBJECT_PROPLIST);
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutDeviceOpsSupported;

  PROCEDURE PutImageInfo(d: Def.Buffer; oh: INTEGER);
  BEGIN Def.PutInteger(d, 0); Def.PutInteger(d, 0); Def.PutInteger(d, 0)
  END PutImageInfo;

  PROCEDURE PutDeviceEventsSupported(d: Def.Buffer);
    VAR w: INTEGER;
  BEGIN
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.EVENT_OBJECTADDED);
    Def.PutHalfword(d, O.EVENT_OBJECTREMOVED);
    Def.PutHalfword(d, O.EVENT_OBJECTINFOCHANGED);
    Def.PutHalfword(d, O.EVENT_OBJECTPROPCHANGED);
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutDeviceEventsSupported;

  PROCEDURE PutDevicePropsSupported(d: Def.Buffer);
    VAR w: INTEGER;
  BEGIN
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.DEV_PROP_DEVICE_FRIENDLY_NAME);
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutDevicePropsSupported;

  PROCEDURE PutDeviceFormatsSupported(d: Def.Buffer);
    VAR w: INTEGER;
  BEGIN
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED);
(*
    Def.PutHalfword(d, O.OBJ_FORMAT_EXECUTABLE);
    Def.PutHalfword(d, O.OBJ_FORMAT_TEXT);
    Def.PutHalfword(d, O.OBJ_FORMAT_BMP);
*)
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutDeviceFormatsSupported;

  PROCEDURE PutManufacturer(d: Def.Buffer);
  BEGIN O.PutString(d, "Christian Schoffit")
  END PutManufacturer;

  PROCEDURE PutModel(d: Def.Buffer);
  BEGIN O.PutString(d, "Oberon Station STM32F4")
  END PutModel;

  PROCEDURE PutDeviceVersion(d: Def.Buffer);
  BEGIN O.PutString(d, "1.0")
  END PutDeviceVersion;

  PROCEDURE PutSerialNumber(d: Def.Buffer);
    VAR t: INTEGER;
  BEGIN Def.PutByte(d, 33); (*must be excatly 32 hexadecimal characters for legacy compatibility reasons*)
    O.PutHexInteger(d, 0);
    SYSTEM.GET(BSP.UID_BASE + 8, t); O.PutHexInteger(d, t);
    SYSTEM.GET(BSP.UID_BASE + 4, t); O.PutHexInteger(d, t);
    SYSTEM.GET(BSP.UID_BASE, t); O.PutHexInteger(d, t);
    Def.PutHalfword(d, 0); (*string null terminator*)
  END PutSerialNumber;

  PROCEDURE PutStorageIDs(d: Def.Buffer);
  BEGIN Def.PutInteger(d, 1); (*one storage: the Oberon filesystem*)
    Def.PutInteger(d, STORAGE_ID); (*physical storage 1, logical storage 1*)
  END PutStorageIDs;

  PROCEDURE PutStorageType(d: Def.Buffer);
  BEGIN Def.PutHalfword(d, O.STORAGE_FIXED_RAM)
  END PutStorageType;

  PROCEDURE PutFilesystemType(d: Def.Buffer);
  BEGIN Def.PutHalfword(d, O.FILESYSTEM_GENERIC_FLAT)
  END PutFilesystemType;

  PROCEDURE PutAccessCapability(d: Def.Buffer);
  BEGIN Def.PutHalfword(d, O.ACCESS_CAP_RW)
  END PutAccessCapability;

  PROCEDURE PutMaxCapacity(d: Def.Buffer);
  BEGIN Def.PutInteger(d, MAX_CAPACITY); Def.PutInteger(d, 0)
  END PutMaxCapacity;

  PROCEDURE PutFreeSpaceInBytes(d: Def.Buffer);
  BEGIN Def.PutInteger(d, (MAX_SECTORS - Files.fshd.NofSectors)*FileSystem.SectorSize); Def.PutInteger(d, 0)
  END PutFreeSpaceInBytes;

  PROCEDURE PutFreeSpaceInObjects(d: Def.Buffer);
  BEGIN Def.PutInteger(d, 0FFFFFFFFH)
  END PutFreeSpaceInObjects;

  PROCEDURE PutStorageDescription(d: Def.Buffer);
  BEGIN O.PutString(d, "Oberon Station")
  END PutStorageDescription;

  PROCEDURE PutVolumeIdentifier(d: Def.Buffer);
  BEGIN O.PutString(d, "OFS2 at block 100000H")
  END PutVolumeIdentifier;

  PROCEDURE PutObjectPropsSupported(d: Def.Buffer; ofc: INTEGER);
    VAR w: INTEGER;
  BEGIN
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.OB_PROP_STORAGE_ID); Def.PutHalfword(d, O.OB_PROP_OBJECT_FORMAT);
    Def.PutHalfword(d, O.OB_PROP_OBJECT_SIZE); Def.PutHalfword(d, O.OB_PROP_OBJ_FILE_NAME);
    Def.PutHalfword(d, O.OB_PROP_DATE_MODIFIED);
(*
    IF ofc = O.OBJ_FORMAT_BMP THEN
      Def.PutHalfword(d, O.OB_PROP_WIDTH); Def.PutHalfword(d, O.OB_PROP_HEIGHT);
      Def.PutHalfword(d, O.OB_PROP_IMAGE_BIT_DEPTH);
    END;
*)
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutObjectPropsSupported;

  PROCEDURE PutObjectPropDefValue(d: Def.Buffer; opc, of, dt: INTEGER);
  BEGIN
    IF opc = O.OB_PROP_OBJ_FILE_NAME THEN O.PutString(d, "NewFile")
    ELSE
      IF dt = O.DATATYPE_UINT16 THEN Def.PutHalfword(d, 0)
      ELSIF dt = O.DATATYPE_UINT32 THEN Def.PutInteger(d, 0)
      ELSIF dt = O.DATATYPE_UINT64 THEN Def.PutInteger(d, 0); Def.PutInteger(d, 0) (*64bits*)
      ELSIF dt = O.DATATYPE_UINT128 THEN
        Def.PutInteger(d, 0); Def.PutInteger(d, 0); Def.PutInteger(d, 0); Def.PutInteger(d, 0) (*128bits*)
      ELSIF dt = O.DATATYPE_STR THEN Def.PutByte(d, 0)
      ELSE
        Log.Error("PutObjectPropDefValue opc: "); Log.ErrorHexVLen(opc, 4, FALSE);
        Log.ErrorString(", of: "); Log.ErrorHexVLen(of, 4, FALSE);
        Log.ErrorString(", dt: "); Log.ErrorHexVLen(dt, 4, FALSE);
        Log.ErrorString(" not handled"); Log.ErrorLn; Log.Flush
      END
    END
  END PutObjectPropDefValue;

  PROCEDURE PutObjectPropGroupCode(d: Def.Buffer; opc, of, dt: INTEGER);
  BEGIN 
    IF (opc = O.OB_PROP_STORAGE_ID) OR (opc = O.OB_PROP_OBJECT_FORMAT) OR
      (opc = O.OB_PROP_OBJ_FILE_NAME) OR (opc = O.OB_PROP_DATE_MODIFIED) OR
      (opc = O.OB_PROP_OBJECT_SIZE) THEN Def.PutInteger(d, GROUP_FILE)
    ELSE Def.PutInteger(d, GROUP_NONE)
    END
  END PutObjectPropGroupCode;

  PROCEDURE PutObjectPropFormFlag(d: Def.Buffer; opc, of, dt: INTEGER);
  BEGIN
    IF opc = O.OB_PROP_OBJECT_SIZE THEN Def.PutByte(d, O.FORM_RANGE); (*range form*)
      Def.PutInteger(d, 0); Def.PutInteger(d, 0); (*minimum value = 0*)
      Def.PutInteger(d, 3210912); Def.PutInteger(d, 0); (*maximum value = 3210912*)
      Def.PutInteger(d, 1); Def.PutInteger(d, 0); (*step size = 1*)
    ELSIF opc = O.OB_PROP_WIDTH THEN Def.PutByte(d, O.FORM_RANGE); (*range form*)
      Def.PutInteger(d, 0); (*minimum value*); Def.PutInteger(d, 1366); (*maximum value*)
      Def.PutInteger(d, 1); (*step size = 1*)
    ELSIF opc = O.OB_PROP_HEIGHT THEN Def.PutByte(d, O.FORM_RANGE); (*range form*)
      Def.PutInteger(d, 0); (*minimum value*); Def.PutInteger(d, 768); (*maximum value*)
      Def.PutInteger(d, 1); (*step size = 1*)
    ELSIF opc = O.OB_PROP_IMAGE_BIT_DEPTH THEN Def.PutByte(d, O.FORM_RANGE); (*range form*)
      Def.PutInteger(d, 8); (*minimum value*); Def.PutInteger(d, 8); (*maximum value*)
      Def.PutInteger(d, 1); (*step size = 1*)
    ELSIF opc = O.OB_PROP_OBJ_FILE_NAME THEN Def.PutByte(d, O.FORM_REGULAR_EXPRESSION);
      O.PutString(d, "[a-zA-Z][_0-9a-zA-Z\.]{0,29}")
    ELSIF opc = O.OB_PROP_DATE_MODIFIED THEN Def.PutByte(d, O.FORM_DATETIME);
    ELSE Def.PutByte(d, O.FORM_NONE)
    END
  END PutObjectPropFormFlag;

  PROCEDURE PutObjectPropGetSet(d: Def.Buffer; opc, of, dt: INTEGER);
  BEGIN
    IF opc = O.OB_PROP_OBJ_FILE_NAME THEN Def.PutByte(d, O.PROP_GET_SET)
    ELSE Def.PutByte(d, O.PROP_GET)
    END
  END PutObjectPropGetSet;

  PROCEDURE PutDevicePropValue(d: Def.Buffer; dpc: INTEGER);
  BEGIN
    IF dpc = O.DEV_PROP_DEVICE_FRIENDLY_NAME THEN
      O.PutString(d, "The fabulous Oberon Station powered by the STM32F429I-DISCx board")
    ELSE Def.PutByte(d, 0);
      Log.Error("PutDevicePropValue dpc: "); Log.ErrorHexVLen(dpc, 8, FALSE);
      Log.ErrorString(" not handled"); Log.ErrorLn; Log.Flush
    END
  END PutDevicePropValue;

  PROCEDURE getNext(VAR adr: INTEGER): BOOLEAN;
    VAR cont: BOOLEAN;
  BEGIN
    IF lohl = NIL THEN cont := FALSE
    ELSE IF idx = lohl.nofh THEN
        lohl := lohl.next; idx := 0
      END;
      IF lohl = NIL THEN cont := FALSE
      ELSE cont := TRUE; adr := lohl.handles[idx]; INC(idx)
      END
    END
    RETURN cont
  END getNext;

  PROCEDURE PutNextOHData(dev: Def.Handle; d: Def.Buffer);
    VAR adr: INTEGER; addvalid: BOOLEAN;
  BEGIN O.SwitchBuffer(d);
    REPEAT addvalid :=  getNext(adr); IF addvalid THEN Def.PutInteger(d, adr) END;
    UNTIL O.Overflow(d) OR ~addvalid; (*the buffer is now filled with wlen bytes*)
    O.PrepareBuffer(d); (*prepare the buffer for next send*)
    IF d.length = 0 THEN (*this is the last call*)
      M.ExitCircularMode(dev, d); fops(O.UserIf).PutNextData := PutNextDataNone
    END
  END PutNextOHData;

  PROCEDURE storeFileHandle(name: FileDir.FileName; adr, date, size: INTEGER; VAR cont: BOOLEAN);
  BEGIN
    IF lohl.nofh = LEN(lohl.handles) THEN (*current array is full, allocate a new one*)
      NEW(lohl.next); lohl := lohl.next
    END;
    lohl.handles[lohl.nofh] := adr; INC(lohl.nofh)
  END storeFileHandle;

  PROCEDURE PutObjectHandles(dev: Def.Handle; d: Def.Buffer; sid, ofc, ofh: INTEGER): HALFWORD;
    VAR ret: HALFWORD; nbf: INTEGER;
  BEGIN ret := O.RESPONSE_OK;
    IF (sid # 00010001H) & (sid # 0FFFFFFFFH) THEN ret := O.RESPONSE_STORE_NOT_AVAILABLE
    ELSIF (ofh # 0) & (ofh # 0FFFFFFFFH) THEN ret := O.RESPONSE_INVALID_OBJECT_HANDLE
    ELSIF ofc # 0 THEN ret := O.RESPONSE_SPECIFICATION_BY_FORMAT_NOT_SUPPORTED
    ELSE
      NEW(ohl); lohl := ohl;
      FileDir.Enumerate(Files.fshd, "", storeFileHandle); (*enumerate all files addresses and store them in oh*)
      lohl := ohl; nbf := 0; REPEAT INC(nbf, lohl.nofh); lohl := lohl.next UNTIL lohl = NIL;
      O.UpdateContainerLength(d, O.CONT_HEADER_SIZE + (nbf+1)*4); (*fix container size*)
      Def.PutInteger(d, nbf); (*array len*)
      lohl := ohl; idx := 0; M.EnterCircularMode(dev, d);
      fops(O.UserIf).PutNextData := PutNextOHData; PutNextOHData(dev, d)
    END
    RETURN ret
  END PutObjectHandles;

  PROCEDURE PutObjectStorageId(d: Def.Buffer; oh: INTEGER);
  BEGIN Def.PutInteger(d, STORAGE_ID)
  END PutObjectStorageId;

  PROCEDURE PutObjectFormat(d: Def.Buffer; oh: INTEGER);
    VAR ext: FileDir.FileName; fh: FileDir.FileHeader;
  BEGIN FileSystem.GetSector(Files.fshd, oh, fh); Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED)
  END PutObjectFormat;

  PROCEDURE FileSize(fh: FileDir.FileHeader): INTEGER;
    RETURN fh.aleng*FileDir.SectorSize + fh.bleng - FileDir.HeaderSize
  END FileSize;

  PROCEDURE PutObjectCompressedSize(d: Def.Buffer; oh: INTEGER);
    VAR fh: FileDir.FileHeader;
  BEGIN FileSystem.GetSector(Files.fshd, oh, fh);
    Def.PutInteger(d, FileSize(fh))
  END PutObjectCompressedSize;

  PROCEDURE PutThumbFormat(d: Def.Buffer; oh: INTEGER);
  BEGIN Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED)
  END PutThumbFormat;

  PROCEDURE PutFilename(d: Def.Buffer; oh: INTEGER);
    VAR fh: FileDir.FileHeader;
  BEGIN FileSystem.GetSector(Files.fshd, oh, fh); O.PutString(d, fh.name)
  END PutFilename;

  PROCEDURE PutDateModified(d: Def.Buffer; oh: INTEGER);
    VAR fh: FileDir.FileHeader; iso: ARRAY 16 OF CHAR;
  BEGIN FileSystem.GetSector(Files.fshd, oh, fh); DateToString(fh.date, iso); O.PutString(d, iso)
  END PutDateModified;

  PROCEDURE PutFilePropListFirst3Elts(d: Def.Buffer; oh: INTEGER; opc: HALFWORD);
  BEGIN INC(count);
    Def.PutInteger(d, oh); Def.PutHalfword(d, opc);
    Def.PutHalfword(d, O.Get_ObjectPropDatatype(opc))
  END PutFilePropListFirst3Elts;

  PROCEDURE PutOPL(d: Def.Buffer; adr: INTEGER);
    VAR iso: ARRAY 16 OF CHAR;  fh: FileDir.FileHeader;
  BEGIN FileSystem.GetSector(Files.fshd, adr, fh);
    IF oPc = 0FFFFFFFFH THEN (*all properties except those with group code = 0FFFFFFFFH*)
      PutFilePropListFirst3Elts(d, adr, O.OB_PROP_STORAGE_ID); Def.PutInteger(d, STORAGE_ID);
      PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJECT_FORMAT); Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED);
      PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJECT_SIZE); Def.PutInteger(d, FileSize(fh)); Def.PutInteger(d, 0);
      PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJ_FILE_NAME); O.PutString(d, fh.name);
      PutFilePropListFirst3Elts(d, adr, O.OB_PROP_DATE_MODIFIED); DateToString(fh.date, iso); O.PutString(d, iso)
    ELSIF oPc = 0 THEN (*filter properties by group code*)
      IF opGc = GROUP_FILE THEN (*file group*)
        PutFilePropListFirst3Elts(d, adr, O.OB_PROP_STORAGE_ID); Def.PutInteger(d, STORAGE_ID);
        PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJECT_FORMAT); Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED);
        PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJECT_SIZE); Def.PutInteger(d, FileSize(fh)); Def.PutInteger(d, 0);
        PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJ_FILE_NAME); O.PutString(d, fh.name);
        PutFilePropListFirst3Elts(d, adr, O.OB_PROP_DATE_MODIFIED); DateToString(fh.date, iso); O.PutString(d, iso)
      END
    ELSIF oPc = O.OB_PROP_STORAGE_ID THEN PutFilePropListFirst3Elts(d, adr, O.OB_PROP_STORAGE_ID);
      Def.PutInteger(d, STORAGE_ID)
    ELSIF oPc = O.OB_PROP_OBJECT_FORMAT THEN PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJECT_FORMAT);
      Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED)
    ELSIF oPc = O.OB_PROP_OBJECT_SIZE THEN PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJECT_SIZE);
      Def.PutInteger(d, FileSize(fh)); Def.PutInteger(d, 0)
    ELSIF oPc = O.OB_PROP_OBJ_FILE_NAME THEN PutFilePropListFirst3Elts(d, adr, O.OB_PROP_OBJ_FILE_NAME);
      O.PutString(d, fh.name)
    ELSIF oPc = O.OB_PROP_DATE_MODIFIED THEN PutFilePropListFirst3Elts(d, adr, O.OB_PROP_DATE_MODIFIED);
      DateToString(fh.date, iso); O.PutString(d, iso)
    END
  END PutOPL;

  PROCEDURE PutNextPLData(dev: Def.Handle; d: Def.Buffer);
    VAR adr, len: INTEGER; addvalid: BOOLEAN;
  BEGIN O.SwitchBuffer(d);
    REPEAT addvalid :=  getNext(adr);
      IF addvalid THEN PutOPL(d, adr);
        IF nbo # 0 THEN (*fix array size*) len := d.length; d.length := O.CONT_HEADER_SIZE;
          Def.PutInteger(d, nbo*count); d.length := len; nbo := 0
        END
      END
    UNTIL O.Overflow(d) OR ~addvalid; (*the buffer is now filled with wlen bytes*)
    O.PrepareBuffer(d); (*prepare the buffer for next send*)
    IF d.length = 0 THEN (*this is the last call*)
      M.ExitCircularMode(dev, d); fops(O.UserIf).PutNextData := PutNextDataNone
    END
  END PutNextPLData;

  PROCEDURE PutObjectPropList(dev: Def.Handle; d: Def.Buffer; oh, ofc, opc, opgc, depth: INTEGER): HALFWORD;
    VAR ret: HALFWORD; len, lenpos, nbf: INTEGER;
  BEGIN ret := O.RESPONSE_OK; lenpos := d.length; count := 0; Def.PutInteger(d, 0); (*placeholder*)
    IF (opc = 0) & (opgc = 0) THEN ret := O.RESPONSE_PARAMETER_NOT_SUPPORTED
    ELSIF ofc # 0 THEN ret := O.RESPONSE_SPECIFICATION_BY_FORMAT_NOT_SUPPORTED
    ELSIF (oh = 0) & (depth = 0) THEN Def.PutInteger(d, 0) (*return empty set*)
    ELSE oPc := opc; opGc := opgc;
      IF (oh = 0) OR (oh = 0FFFFFFFFH) THEN
        O.UpdateContainerLength(d, 0FFFFFFFFH); (*the container size is unknown until the process is complete*)
        IF ohl = NIL THEN NEW(ohl); lohl := ohl; FileDir.Enumerate(Files.fshd, "", storeFileHandle) END;
        nbf := 0; lohl := ohl; REPEAT INC(nbf, lohl.nofh); lohl := lohl.next UNTIL lohl = NIL; (*count files*)
        nbo := nbf; (*working information used by PutNextPLData to compute actual length of the array*)
        lohl := ohl; idx := 0; M.EnterCircularMode(dev, d);
        fops(O.UserIf).PutNextData := PutNextPLData; PutNextPLData(dev, d)
      ELSE  PutOPL(d, oh);
        len := d.length; d.length := lenpos; Def.PutInteger(d, count); d.length := len
      END; d := NIL
    END
    RETURN ret
  END PutObjectPropList;

  PROCEDURE PutNextObjectData(dev: Def.Handle; d: Def.Buffer);
    VAR b: BYTE;
  BEGIN O.SwitchBuffer(d);
    REPEAT Files.ReadByte(R, b); IF ~R.eof THEN Def.PutByte(d, b) END
    UNTIL O.Overflow(d) OR R.eof; (*the buffer is now filled with wlen bytes*)
    O.PrepareBuffer(d); (*prepare the buffer for next send*)
    IF d.length = 0 THEN (*this is the last call*)
      M.ExitCircularMode(dev, d); fops(O.UserIf).PutNextData := PutNextDataNone
    END
  END PutNextObjectData;

  PROCEDURE PutObject(dev: Def.Handle; d: Def.Buffer; oh: INTEGER): HALFWORD;
    VAR ret: HALFWORD;
  BEGIN ret := O.RESPONSE_OK; F := Files.OldByAdr(oh);
    IF F = NIL THEN ret := O.RESPONSE_INVALID_OBJECT_HANDLE
    ELSE O.UpdateContainerLength(d, O.CONT_HEADER_SIZE + Files.Length(F));
      Files.Set(R, F, 0); M.EnterCircularMode(dev, d);
      fops(O.UserIf).PutNextData := PutNextObjectData; PutNextObjectData(dev, d)
    END
    RETURN ret
  END PutObject;

  PROCEDURE PutObjectPropValue(d: Def.Buffer; oh, opc: INTEGER);
    VAR fh: FileDir.FileHeader; ext: FileDir.FileName; date: ARRAY 16 OF CHAR;
  BEGIN
    IF opc = O.OB_PROP_STORAGE_ID THEN Def.PutInteger(d, STORAGE_ID)
    ELSE FileSystem.GetSector(Files.fshd, oh, fh);
      IF opc = O.OB_PROP_OBJECT_FORMAT THEN Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED)
      ELSIF opc = O.OB_PROP_OBJECT_SIZE THEN Def.PutInteger(d, FileSize(fh)); Def.PutInteger(d, 0)
    ELSIF opc = O.OB_PROP_OBJ_FILE_NAME THEN O.PutString(d, fh.name)
      ELSIF opc = O.OB_PROP_DATE_MODIFIED THEN DateToString(fh.date, date); O.PutString(d, date)
      END
    END
  END PutObjectPropValue;

  PROCEDURE initFops(): Def.UserData;
    VAR u!: O.UserIf;
  BEGIN NEW(u);
    (*todo: develop fops.* procedures*)
    u.Init := Init;
    u.DeInit := DeInit;
    u.Create_NewObject := NIL;
    u.GetIdx := NIL;
    u.GetParentObject := NIL;
    u.GetObjectFormat := NIL;
    u.GetObjectName_len := NIL;
    u.GetObjectName := NIL;
    u.GetObjectSize := NIL;
    u.GetMaxCapability := NIL;
    u.GetFreeSpaceInBytes := NIL;
    u.GetNewIndex := NIL;
(*    u.WriteData := NIL;*)
    u.DeleteObject := NIL;
    u.Cancel := Cancel;
    u.PutVendorExtension := PutVendorExtension;
    u.PutDeviceOpsSupported := PutDeviceOpsSupported;
    u.PutDeviceEventsSupported := PutDeviceEventsSupported;
    u.PutDevicePropsSupported := PutDevicePropsSupported;
    u.PutDeviceCaptureFormatsSupported := PutDeviceFormatsSupported;
    u.PutDevicePlaybackFormatsSupported := PutDeviceFormatsSupported;
    u.PutManufacturer := PutManufacturer;
    u.PutModel := PutModel;
    u.PutDeviceVersion := PutDeviceVersion;
    u.PutSerialNumber := PutSerialNumber;
    u.PutStorageIDs := PutStorageIDs;
    u.PutStorageType := PutStorageType;
    u.PutFilesystemType := PutFilesystemType;
    u.PutAccessCapability := PutAccessCapability;
    u.PutMaxCapacity := PutMaxCapacity;
    u.PutFreeSpaceInBytes := PutFreeSpaceInBytes;
    u.PutFreeSpaceInObjects := PutFreeSpaceInObjects;
    u.PutStorageDescription := PutStorageDescription;
    u.PutVolumeIdentifier := PutVolumeIdentifier;
    u.PutObjectHandles := PutObjectHandles;
    u.PutObjectStorageId := PutObjectStorageId;
    u.PutObjectFormat := PutObjectFormat;
    u.PutProtectionStatus := Put0W1p;
    u.PutObjectCompressedSize := PutObjectCompressedSize;
    u.PutThumbFormat := PutThumbFormat;
    u.PutThumbCompressedSize := Put0I1p;
    u.PutThumbPixWidth := Put0I1p;
    u.PutThumbPixHeight := Put0I1p;
    u.PutImageInfo := PutImageInfo;
    u.PutParentObject := Put0I1p;
    u.PutAssociationType := Put0W1p;
    u.PutAssociationDesc := Put0I1p;
    u.PutSequenceNumber := Put0I1p;
    u.PutFilename := PutFilename;
    u.PutDateCreated := Put0S1p;
    u.PutDateModified := PutDateModified;
    u.PutKeywords := Put0S1p;
    u.PutObjectPropsSupported := PutObjectPropsSupported;
    u.PutObjectPropDefValue := PutObjectPropDefValue;
    u.PutObjectPropGroupCode := PutObjectPropGroupCode;
    u.PutObjectPropFormFlag := PutObjectPropFormFlag;
    u.PutObjectPropGetSet := PutObjectPropGetSet;
    u.PutObjectPropList := PutObjectPropList;
    u.PutObjectPropValue := PutObjectPropValue;
    u.PutObject := PutObject;
    u.PutDeviceFriendlyName := NIL;
    u.PutDevicePropValue := PutDevicePropValue;
    u.PutNextData := PutNextDataNone;

    RETURN u
  END initFops;

BEGIN fops := initFops(); Descriptors := USBDMTPDesc.Descriptors; CLASS := M.CLASS
END USBDMTPOberon.

OM4Tool.DecSym USBDMTPOberon.sm4
