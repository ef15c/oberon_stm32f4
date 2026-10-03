MODULE USBDMTPOberon;
  IMPORT Def := USBDef, DDef := USBDDef, USBDMTPDesc, O := USBDMTPOpt, USBDMTP;

  VAR fops*: Def.UserData; Descriptors*: Def.DescriptorGetters; CLASS*: Def.Class;

  PROCEDURE init(): Def.UserData;
    VAR u!: DDef.UserData;
  BEGIN NEW(u);
    (*todo: develop fops.* procedures*)
    RETURN u
  END init;

BEGIN fops := init(); Descriptors := USBDMTPDesc.Descriptors; CLASS := USBDMTP.CLASS
END USBDMTPOberon.

OM4Tool.DecSym USBDMTPOberon.sm4
