MODULE USBDMTPOberon;
  IMPORT Def := USBDef, USBDMTPDesc, O := USBDMTPOpt, USBDMTP;

  VAR fops*: Def.UserData; Descriptors*: Def.DescriptorGetters; CLASS*: Def.Class;

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
    u.PutVendorExtension := NIL;
    u.PutManufacturer := NIL;
    u.PutModel := NIL;
    u.PutDeviceVersion := NIL;
    u.PutSerialNumber := NIL;
    u.PutStorageIDs := NIL;
    u.PutStorageType := NIL;
    u.PutFilesystemType := NIL;
    u.PutAccessCapability := NIL;
    u.PutMaxCapacity := NIL;
    u.PutFreeSpaceInBytes := NIL;
    u.PutFreeSpaceInObjects := NIL;
    u.PutStorageDescription := NIL;
    u.PutVolumeIdentifier := NIL;
    u.PutObjectHandles := NIL;
    u.PutObjecStorageId := NIL;
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
    u.PutObjectPropsSupported := NIL;
    u.PutObjectPropDefValue := NIL;
    u.PutObjectPropGroupCode := NIL;
    u.PutObjectPropFormFlag := NIL;
    u.PutObjectPropGetSet := NIL;
    u.PutObjectReferences := NIL;
    u.PutObjectPropList := NIL;
    u.PutObjectPropValue := NIL;
    u.PutDeviceFriendlyName := NIL;

    RETURN u
  END initFops;

BEGIN fops := initFops(); Descriptors := USBDMTPDesc.Descriptors; CLASS := USBDMTP.CLASS
END USBDMTPOberon.

OM4Tool.DecSym USBDMTPOberon.sm4
