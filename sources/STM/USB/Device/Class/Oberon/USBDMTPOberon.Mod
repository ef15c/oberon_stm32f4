MODULE USBDMTPOberon;
  IMPORT SYSTEM, BSP, Kernel, FileDir, Files, BMP, Log := USBLog, Def := USBDef, USBDMTPDesc, O := USBDMTPOpt, USBDMTP;

  CONST STORAGE_ID = 00010001H;
    GROUP_NONE = 0;
    GROUP_FILE = 1;
    GROUP_BMP = 2;

  VAR fops*: Def.UserData; Descriptors*: Def.DescriptorGetters; CLASS*: Def.Class;
    dest: Def.Buffer; count: INTEGER; oFc, oPc, opGc: INTEGER;

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
    IF ext = "m4c" THEN ofc := O.OBJ_FORMAT_EXECUTABLE
    ELSIF ext = "txt" THEN ofc := O.OBJ_FORMAT_TEXT
    ELSIF ext = "bmp" THEN ofc := O.OBJ_FORMAT_BMP
    ELSE ofc := O.OBJ_FORMAT_UNDEFINED
    END
    RETURN ofc
  END OFByExt;

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
  END DeInit;

  (**
  * @brief  USBD_MTP_Itf_Cancel
  *         Close opened folder/file while cancelling transaction
  * @param  MTP_ResponsePhase: MTP current state
  * @retval None
  *)
  PROCEDURE Cancel(Phase: INTEGER);
  BEGIN
    (* Make sure to close open file while canceling transaction *)
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
  BEGIN Log.Debug("DeviceOpsSupported");
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.OP_GET_DEVICE_INFO); Def.PutHalfword(d, O.OP_OPEN_SESSION);
    Def.PutHalfword(d, O.OP_CLOSE_SESSION); Def.PutHalfword(d, O.OP_GET_STORAGE_IDS);
    Def.PutHalfword(d, O.OP_GET_STORAGE_INFO); Def.PutHalfword(d, O.OP_GET_NUM_OBJECTS);
    Def.PutHalfword(d, O.OP_GET_OBJECT_HANDLES); Def.PutHalfword(d, O.OP_GET_OBJECT_INFO);
    Def.PutHalfword(d, O.OP_GET_OBJECT); Def.PutHalfword(d, O.OP_DELETE_OBJECT);
    Def.PutHalfword(d, O.OP_SEND_OBJECT_INFO); Def.PutHalfword(d, O.OP_SEND_OBJECT);
    Def.PutHalfword(d, O.OP_GET_DEVICE_PROP_DESC); Def.PutHalfword(d, O.OP_GET_DEVICE_PROP_VALUE);
    Def.PutHalfword(d, O.OP_SET_OBJECT_PROP_VALUE); Def.PutHalfword(d, O.OP_GET_OBJECT_PROP_VALUE);
    Def.PutHalfword(d, O.OP_GET_OBJECT_PROPS_SUPPORTED); Def.PutHalfword(d, O.OP_GET_OBJECT_PROPLIST);
    Def.PutHalfword(d, O.OP_GET_OBJECT_PROP_DESC);
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutDeviceOpsSupported;

  PROCEDURE PutDeviceEventsSupported(d: Def.Buffer);
    VAR w: INTEGER;
  BEGIN Log.Debug("DeviceEventsSupported");
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.EVENT_OBJECTADDED);
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutDeviceEventsSupported;

  PROCEDURE PutDevicePropsSupported(d: Def.Buffer);
    VAR w: INTEGER;
  BEGIN Log.Debug("DevicePropsSupported");
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.DEV_PROP_DEVICE_FRIENDLY_NAME);
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutDevicePropsSupported;

  PROCEDURE PutDeviceFormatsSupported(d: Def.Buffer);
    VAR w: INTEGER;
  BEGIN Log.Debug("DeviceFormatsSupported");
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED); Def.PutHalfword(d, O.OBJ_FORMAT_EXECUTABLE);
    Def.PutHalfword(d, O.OBJ_FORMAT_TEXT); Def.PutHalfword(d, O.OBJ_FORMAT_BMP);
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
  BEGIN Def.PutInteger(d, (10000H - 64)*1024); Def.PutInteger(d, 0)
  END PutMaxCapacity;

  PROCEDURE PutFreeSpaceInBytes(d: Def.Buffer);
  BEGIN Def.PutInteger(d, (10000H - 64 - Kernel.NofSectors)*1024); Def.PutInteger(d, 0)
  END PutFreeSpaceInBytes;

  PROCEDURE PutFreeSpaceInObjects(d: Def.Buffer);
  BEGIN Def.PutInteger(d, 0FFFFFFFFH)
  END PutFreeSpaceInObjects;

  PROCEDURE PutStorageDescription(d: Def.Buffer);
  BEGIN O.PutString(d, "Oberon 64MB storage")
  END PutStorageDescription;

  PROCEDURE PutVolumeIdentifier(d: Def.Buffer);
  BEGIN O.PutString(d, "")
  END PutVolumeIdentifier;

  PROCEDURE PutObjectPropsSupported(d: Def.Buffer; ofc: INTEGER);
    VAR w: INTEGER;
  BEGIN Log.Debug("GetObjectPropsSupp("); Log.DebugHexVLen(ofc, 4, FALSE);
    Log.DebugString(")");
    O.BeginArray(d, w);
    Def.PutHalfword(d, O.OB_PROP_STORAGE_ID); Def.PutHalfword(d, O.OB_PROP_OBJECT_FORMAT);
    Def.PutHalfword(d, O.OB_PROP_OBJECT_SIZE); Def.PutHalfword(d, O.OB_PROP_OBJ_FILE_NAME);
    Def.PutHalfword(d, O.OB_PROP_DATE_MODIFIED); Def.PutHalfword(d, O.OB_PROP_NAME);
    Def.PutHalfword(d, O.OB_PROP_PERS_UNIQ_OBJ_IDEN);
    IF ofc = O.OBJ_FORMAT_BMP THEN
      Def.PutHalfword(d, O.OB_PROP_WIDTH); Def.PutHalfword(d, O.OB_PROP_HEIGHT);
      Def.PutHalfword(d, O.OB_PROP_IMAGE_BIT_DEPTH);
    END;
    O.EndArray(d, w, SYSTEM.SIZE(HALFWORD))
  END PutObjectPropsSupported;

  PROCEDURE PutObjectPropDefValue(d: Def.Buffer; opc, of, dt: INTEGER);
  BEGIN
    IF (opc = O.OB_PROP_OBJ_FILE_NAME) OR (opc = O.OB_PROP_NAME) THEN O.PutString(d, "NewFile")
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
      (opc = O.OB_PROP_OBJECT_SIZE) OR (opc = O.OB_PROP_OBJ_FILE_NAME) OR
      (opc = O.OB_PROP_DATE_MODIFIED) OR (opc = O.OB_PROP_NAME) OR
      (opc = O.OB_PROP_PERS_UNIQ_OBJ_IDEN) THEN Def.PutInteger(d, GROUP_FILE)
    ELSIF (opc = O.OB_PROP_WIDTH) OR (opc = O.OB_PROP_HEIGHT)
      OR (opc = O.OB_PROP_IMAGE_BIT_DEPTH) THEN Def.PutInteger(d, GROUP_BMP)
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

  PROCEDURE putFileHandle(name: FileDir.FileName; adr: INTEGER; VAR cont: BOOLEAN);
  BEGIN Def.PutInteger(dest, adr)
  END putFileHandle;

  PROCEDURE PutObjectHandles(d: Def.Buffer; sid, ofc, ofh: INTEGER): HALFWORD;
    VAR ret: HALFWORD; w: INTEGER;
  BEGIN ret := O.RESPONSE_OK;
    Log.Debug("GetObjectHandles");
    IF (sid # 00010001H) & (sid # 0FFFFFFFFH) THEN ret := O.RESPONSE_STORE_NOT_AVAILABLE
    ELSIF (ofh # 0) & (ofh # 0FFFFFFFFH) THEN ret := O.RESPONSE_INVALID_OBJECT_HANDLE
    ELSE  (*return all files handles*)
      IF ofc # 0 THEN Log.Error("PutObjectHandles: ObjectFormatCode not handled"); Log.ErrorLn; Log.Flush END;
      dest := d; O.BeginArray(d, w); FileDir.Enumerate("", putFileHandle); O.EndArray(d, w, SYSTEM.SIZE(INTEGER)); dest := NIL
    END;
    RETURN ret
  END PutObjectHandles;

  PROCEDURE PutObjectStorageId(d: Def.Buffer; oh: INTEGER);
  BEGIN Def.PutInteger(d, STORAGE_ID)
  END PutObjectStorageId;

  PROCEDURE PutObjectFormat(d: Def.Buffer; oh: INTEGER);
    VAR ext: FileDir.FileName; fh: FileDir.FileHeader;
  BEGIN Kernel.GetSector(oh, fh); GetExt(fh.name, ext);
    Def.PutHalfword(d, OFByExt(ext))
  END PutObjectFormat;

  PROCEDURE FileSize(fh: FileDir.FileHeader): INTEGER;
    RETURN fh.aleng*FileDir.SectorSize + fh.bleng - FileDir.HeaderSize
  END FileSize;

  PROCEDURE PutObjectCompressedSize(d: Def.Buffer; oh: INTEGER);
    VAR fh: FileDir.FileHeader;
  BEGIN Kernel.GetSector(oh, fh);
    Def.PutInteger(d, FileSize(fh))
  END PutObjectCompressedSize;

  PROCEDURE PutThumbFormat(d: Def.Buffer; oh: INTEGER);
  BEGIN Def.PutHalfword(d, O.OBJ_FORMAT_UNDEFINED)
  END PutThumbFormat;

  PROCEDURE GetBMPHeaders(name: FileDir.FileName; VAR dh: BMP.DIBHeader);
    VAR F!: Files.File; R!: Files.Rider; h: BMP.Header;
  BEGIN dh.width := 0; dh.height := 0; dh.bitcount := 0; F := Files.Old(name);
    IF F # NIL THEN Files.Set(R, F, 0); BMP.ReadHeader(R, h);
      IF h.signature[0] # 0X THEN BMP.ReadDIBHeader(R, dh) END
    END
  END GetBMPHeaders;

  PROCEDURE PutImageInfo(d: Def.Buffer; oh: INTEGER);
    VAR fh: FileDir.FileHeader; dh: BMP.DIBHeader;
  BEGIN Kernel.GetSector(oh, fh); GetBMPHeaders(fh.name, dh);
    Def.PutInteger(d, dh.width); Def.PutInteger(d, dh.height); Def.PutInteger(d, dh.bitcount)
  END PutImageInfo;

  PROCEDURE PutFilename(d: Def.Buffer; oh: INTEGER);
    VAR fh: FileDir.FileHeader;
  BEGIN Kernel.GetSector(oh, fh); O.PutString(d, fh.name);
    Log.Debug("PutFilename: "); Log.DebugString(fh.name); Log.DebugLn;
  END PutFilename;

  PROCEDURE PutDateModified(d: Def.Buffer; oh: INTEGER);
    VAR fh: FileDir.FileHeader; dt: ARRAY 16 OF CHAR;
  BEGIN Kernel.GetSector(oh, fh); DateToString(fh.date, dt); O.PutString(d, dt)
  END PutDateModified;

  PROCEDURE PutFilePropListElement(oh: INTEGER; fh: FileDir.FileHeader; opc, val: HALFWORD);
    VAR date: ARRAY 16 OF CHAR;
  BEGIN Def.PutInteger(dest, oh); Def.PutHalfword(dest, opc);
    Def.PutHalfword(dest, O.Get_ObjectPropDatatype(opc));
    IF opc = O.OB_PROP_STORAGE_ID THEN Def.PutInteger(dest, STORAGE_ID)
    ELSIF opc = O.OB_PROP_OBJECT_FORMAT THEN Def.PutInteger(dest, val)
    ELSIF opc = O.OB_PROP_OBJECT_SIZE THEN Def.PutInteger(dest, FileSize(fh))
    ELSIF opc = O.OB_PROP_OBJ_FILE_NAME THEN O.PutString(dest, fh.name)
    ELSIF opc = O.OB_PROP_DATE_MODIFIED THEN DateToString(fh.date, date); O.PutString(dest, date)
    ELSIF opc = O.OB_PROP_NAME THEN O.PutString(dest, fh.name)
    ELSIF opc = O.OB_PROP_PERS_UNIQ_OBJ_IDEN THEN 
      Def.PutInteger(dest, oh); Def.PutInteger(dest, 0); Def.PutInteger(dest, 0); Def.PutInteger(dest, 0)
    END; INC(count)
  END PutFilePropListElement;

  PROCEDURE PutBMPPropListElement(oh: INTEGER; dh: BMP.DIBHeader; opc: HALFWORD);
  BEGIN Def.PutInteger(dest, oh); Def.PutHalfword(dest, opc);
    Def.PutHalfword(dest, O.Get_ObjectPropDatatype(opc));
    IF opc = O.OB_PROP_WIDTH THEN Def.PutInteger(dest, dh.width)
    ELSIF opc = O.OB_PROP_HEIGHT THEN Def.PutInteger(dest, dh.height)
    ELSIF opc = O.OB_PROP_IMAGE_BIT_DEPTH THEN Def.PutInteger(dest, dh.bitcount)
    END; INC(count)
  END PutBMPPropListElement;

  PROCEDURE PutOPL(adr: INTEGER; ofc: HALFWORD);
    VAR fh: FileDir.FileHeader; dh: BMP.DIBHeader;
  BEGIN Kernel.GetSector(adr, fh);
    Log.Debug("PutOPL: file name: "); Log.DebugString(fh.name); Log.DebugLn;
    IF oPc = 0FFFFFFFFH THEN (*all properties except those with group code = 0FFFFFFFFH*)
      PutFilePropListElement(adr, fh, O.OB_PROP_STORAGE_ID, 0); PutFilePropListElement(adr, fh, O.OB_PROP_OBJECT_FORMAT, ofc);
      PutFilePropListElement(adr, fh, O.OB_PROP_OBJECT_SIZE, 0); PutFilePropListElement(adr, fh, O.OB_PROP_OBJ_FILE_NAME, 0);
      PutFilePropListElement(adr, fh, O.OB_PROP_DATE_MODIFIED, 0); PutFilePropListElement(adr, fh, O.OB_PROP_NAME, 0);
      PutFilePropListElement(adr, fh, O.OB_PROP_PERS_UNIQ_OBJ_IDEN, 0);
      IF oFc = O.OBJ_FORMAT_BMP THEN GetBMPHeaders(fh.name, dh);
        PutBMPPropListElement(adr, dh, O.OB_PROP_WIDTH); PutBMPPropListElement(adr, dh, O.OB_PROP_HEIGHT);
        PutBMPPropListElement(adr, dh, O.OB_PROP_IMAGE_BIT_DEPTH)
      END
    ELSIF oPc = 0 THEN (*filter properties by group code*)
      IF opGc = GROUP_FILE THEN (*file group*)
        PutFilePropListElement(adr, fh, O.OB_PROP_STORAGE_ID, 0); PutFilePropListElement(adr, fh, O.OB_PROP_OBJECT_FORMAT, ofc);
        PutFilePropListElement(adr, fh, O.OB_PROP_OBJECT_SIZE, 0); PutFilePropListElement(adr, fh, O.OB_PROP_OBJ_FILE_NAME, 0);
        PutFilePropListElement(adr, fh, O.OB_PROP_DATE_MODIFIED, 0); PutFilePropListElement(adr, fh, O.OB_PROP_NAME, 0);
        PutFilePropListElement(adr, fh, O.OB_PROP_PERS_UNIQ_OBJ_IDEN, 0);
      ELSIF (opGc = GROUP_BMP) & (ofc =  O.OBJ_FORMAT_BMP) THEN (*bmp group*) GetBMPHeaders(fh.name, dh);
        PutBMPPropListElement(adr, dh, O.OB_PROP_WIDTH); PutBMPPropListElement(adr, dh, O.OB_PROP_HEIGHT);
        PutBMPPropListElement(adr, dh, O.OB_PROP_IMAGE_BIT_DEPTH)
      END
    ELSIF (ofc =  O.OBJ_FORMAT_BMP) & 
      ((oPc = O.OB_PROP_WIDTH) OR (oPc = O.OB_PROP_HEIGHT) OR (oPc = O.OB_PROP_HEIGHT)) THEN
       GetBMPHeaders(fh.name, dh); PutBMPPropListElement(adr, dh, oPc)
    ELSE PutFilePropListElement(adr, fh, oPc, ofc)
    END
  END PutOPL;

  PROCEDURE putFileProps(name: FileDir.FileName; adr: INTEGER; VAR cont: BOOLEAN);
    VAR ext: FileDir.FileName; ofc: HALFWORD;
  BEGIN GetExt(name, ext); ofc := OFByExt(ext);
    IF (oFc = 0) OR (ofc = oFc) THEN (*format matches*) PutOPL(adr, ofc) END
  END putFileProps;

  PROCEDURE PutObjectPropList(d: Def.Buffer; oh, ofc, opc, opgc, depth: INTEGER): HALFWORD;
    VAR ret: HALFWORD; len: INTEGER;
  BEGIN ret := O.RESPONSE_OK; count := 0; Def.PutInteger(d, 0); (*placeholder*)
    IF (opc = 0) & (opgc = 0) THEN ret := O.RESPONSE_PARAMETER_NOT_SUPPORTED
    ELSIF (oh # 0) OR (depth # 0) THEN (*if (oh = 0) & (depth = 0) return empty set*)
      dest := d; oFc := ofc; oPc := opc; opGc := opgc;
      IF (oh = 0) OR (oh = 0FFFFFFFFH) THEN FileDir.Enumerate("", putFileProps)
      ELSE PutOPL(oh, ofc)
      END; dest := NIL
    END;
    len := d.length; d.length := 0; Def.PutInteger(d, count); d.length := len
    RETURN ret
  END PutObjectPropList;

  PROCEDURE initFops(): Def.UserData;
    VAR u!: O.UserIf;
  BEGIN NEW(u);
    (*todo: develop fops.* procedures*)
    u.Init := Init;
    u.DeInit := DeInit;
    u.ReadData := NIL;
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
    u.WriteData := NIL;
    u.GetContainerLength := NIL;
    u.DeleteObject := NIL;
    u.Cancel := Cancel;
    u.CopyBuffer := NIL;
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
    u.PutObjectPropValue := NIL;
    u.PutDeviceFriendlyName := NIL;
    u.PutDevicePropValue := PutDevicePropValue;

    RETURN u
  END initFops;

BEGIN fops := initFops(); Descriptors := USBDMTPDesc.Descriptors; CLASS := USBDMTP.CLASS
END USBDMTPOberon.

OM4Tool.DecSym USBDMTPOberon.sm4
