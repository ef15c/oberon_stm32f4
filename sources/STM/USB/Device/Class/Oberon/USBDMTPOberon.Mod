MODULE USBDMTPOberon;
  IMPORT SYSTEM, BSP, Kernel, FileDir, Log := USBLog, Def := USBDef, USBDMTPDesc, O := USBDMTPOpt, USBDMTP;

  VAR fops*: Def.UserData; Descriptors*: Def.DescriptorGetters; CLASS*: Def.Class;
    dest: Def.Buffer;

  PROCEDURE UpdateNumElements(d: Def.Buffer; elementSize: INTEGER);
    VAR length: HALFWORD; count: INTEGER;
  BEGIN length := d.length; d.length := 0; count := (length  - 4) DIV elementSize;
    Def.PutInteger(d, count); d.length := length;
    Log.DebugInt(count, 7); Log.DebugString(" elements returned"); Log.DebugLn
  END UpdateNumElements;

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

  PROCEDURE PutVendorExtension(d: Def.Buffer);
  BEGIN O.PutString(d, "microsoft.com: 1.0; ")
  END PutVendorExtension;

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
    Def.PutInteger(d, 00010001H); (*physical storage 1, logical storage 1*)
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
  BEGIN O.PutString(d, "Oberon 64Mb storage")
  END PutStorageDescription;

  PROCEDURE PutVolumeIdentifier(d: Def.Buffer);
  BEGIN O.PutString(d, "")
  END PutVolumeIdentifier;

  PROCEDURE PutObjectPropsSupported(d: Def.Buffer; ofc: INTEGER);
  BEGIN Log.Debug("GetObjectPropsSupp("); Log.DebugHexVLen(ofc, 4, FALSE);
    Log.DebugString(")");
    Def.PutInteger(d, 0);
    Def.PutInteger(d, O.OB_PROP_STORAGE_ID); Def.PutInteger(d, O.OB_PROP_OBJECT_FORMAT);
    Def.PutInteger(d, O.OB_PROP_OBJECT_SIZE); Def.PutInteger(d, O.OB_PROP_OBJ_FILE_NAME);
    Def.PutInteger(d, O.OB_PROP_PARENT_OBJECT); Def.PutInteger(d, O.OB_PROP_NAME);
    Def.PutInteger(d, O.OB_PROP_PERS_UNIQ_OBJ_IDEN);Def.PutInteger(d, O.OB_PROP_PROTECTION_STATUS);
    UpdateNumElements(d, 4)
  END PutObjectPropsSupported;

  PROCEDURE PutObjectPropDefValue(d: Def.Buffer; opc, of, dt: INTEGER);
  BEGIN
    IF dt = O.DATATYPE_UINT16 THEN Def.PutHalfword(d, 0)
    ELSIF dt = O.DATATYPE_UINT32 THEN Def.PutInteger(d, 0)
    ELSIF dt = O.DATATYPE_UINT64 THEN Def.PutInteger(d, 0); Def.PutInteger(d, 0) (*64bits*)
    ELSIF dt = O.DATATYPE_STR THEN Def.PutByte(d, 0)
    ELSE Def.PutByte(d, 0);
      Log.Error("PutObjectPropDefValue opc: "); Log.ErrorHexVLen(opc, 8, FALSE);
      Log.ErrorString(", of: "); Log.ErrorHexVLen(of, 8, FALSE);
      Log.ErrorString(", dt: "); Log.ErrorHexVLen(dt, 8, FALSE);
      Log.ErrorString(" not handled"); Log.ErrorLn; Log.Flush
    END
  END PutObjectPropDefValue;

  PROCEDURE PutObjectPropGroupCode(d: Def.Buffer; opc, of, dt: INTEGER);
  BEGIN Def.PutInteger(d, 0)
  END PutObjectPropGroupCode;

  PROCEDURE PutObjectPropFormFlag(d: Def.Buffer; opc, of, dt: INTEGER);
  BEGIN
    IF opc = O.OB_PROP_OBJECT_SIZE THEN Def.PutByte(d, 1); (*range form*)
      Def.PutInteger(d, 0); Def.PutInteger(d, 0); (*minimum value = 0*)
      Def.PutInteger(d, 3210912); Def.PutInteger(d, 0); (*maximum value = 3210912*)
      Def.PutInteger(d, 1); Def.PutInteger(d, 0); (*step size = 1*)
    ELSE Def.PutByte(d, 0)
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
    VAR ret: HALFWORD; length: HALFWORD;
  BEGIN ret := O.RESPONSE_OK;
    Log.Debug("GetObjectHandle");
    IF (sid # 00010001H) & (sid # 0FFFFFFFFH) THEN ret := O.RESPONSE_STORE_NOT_AVAILABLE
    ELSIF (ofh # 0) & (ofh # 0FFFFFFFFH) THEN ret := O.RESPONSE_INVALID_OBJECT_HANDLE
    ELSE  (*return all files handles*)
      IF ofc # 0 THEN Log.Error("PutObjectHandles: ObjectFormatCode not handled"); Log.ErrorLn; Log.Flush END;
      Def.PutInteger(d, 0); (*place holder for number of object handles*)
      dest := d; FileDir.Enumerate("", putFileHandle); UpdateNumElements(d, 4); dest := NIL
    END;
    RETURN ret
  END PutObjectHandles;

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
    u.PutObjectStorageId := NIL;
    u.PutObjectFormat := NIL;
    u.PutProtectionStatus := NIL;
    u.PutObjectCompressedSize := NIL;
    u.PutThumbFormat := NIL;
    u.PutThumbCompressedSize := NIL;
    u.PutThumbPixWidth := NIL;
    u.PutThumbPixHeight := NIL;
    u.PutImagePixWidth := NIL;
    u.PutImagePixHeight := NIL;
    u.PutImageBitDepth := NIL;
    u.PutParentObject := NIL;
    u.PutAssociationType := NIL;
    u.PutAssociationDesc := NIL;
    u.PutSequenceNumber := NIL;
    u.PutFilename := NIL;
    u.PutDateCreated := NIL;
    u.PutDateModified := NIL;
    u.PutKeywords := NIL;
    u.PutObjectPropsSupported := PutObjectPropsSupported;
    u.PutObjectPropDefValue := PutObjectPropDefValue;
    u.PutObjectPropGroupCode := PutObjectPropGroupCode;
    u.PutObjectPropFormFlag := PutObjectPropFormFlag;
    u.PutObjectPropGetSet := PutObjectPropGetSet;
    u.PutObjectReferences := NIL;
    u.PutObjectPropList := NIL;
    u.PutObjectPropValue := NIL;
    u.PutDeviceFriendlyName := NIL;
    u.PutDevicePropValue := PutDevicePropValue;

    RETURN u
  END initFops;

BEGIN fops := initFops(); Descriptors := USBDMTPDesc.Descriptors; CLASS := USBDMTP.CLASS
END USBDMTPOberon.

OM4Tool.DecSym USBDMTPOberon.sm4
