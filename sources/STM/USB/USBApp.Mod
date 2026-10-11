MODULE USBApp; (*device USB example. CS 14.08.26*)
  IMPORT Log := USBLog, USB, MO := USBDMTPOberon;

  PROCEDURE devUsrCbk(usbid, reason: BYTE);
  BEGIN
    IF reason = USB.USER_ASSIGN_DESCRIPTORS THEN USB.RegisterDescriptors(usbid, MO.Descriptors)
    ELSIF reason = USB.USER_REGISTER_DETAILS THEN USB.RegisterClass(usbid, MO.CLASS);
      USB.RegisterInterface(usbid, MO.fops); (*assign oberon filesystem interface*)
    END
  END devUsrCbk;

  PROCEDURE Run*;
  BEGIN
    IF ~USB.IsRegistered(0) THEN USB.Init(devUsrCbk, 0) END (* Initialize USB controller *)
  END Run;

  PROCEDURE Stop*;
  BEGIN USB.DeInit(0)
  END Stop;

  PROCEDURE mode*;
  BEGIN
    IF USB.IsRegistered(0) THEN
      IF USB.IsHost(0) THEN Log.User("In host mode") ELSE Log.User("In device mode") END;
      Log.Flush
    END
  END mode;

BEGIN
  Log.SetDebugCbks(Log.DefaultDebug, Log.DefaultString, Log.DefaultInt, Log.DefaultHexVLen,
  Log.DefaultSet, Log.DefaultBuf, Log.DefaultLn);
END USBApp.

System.DeleteFiles USBApp.sm4 USB.sm4 USBH.sm4 USBHCtlReq.sm4 USBHIoReq.sm4 USBHHal.sm4 HALHCD.sm4 USBHCore.sm4 USBHPipes.sm4 USBHDef.sm4
 USBHConf.sm4 USBHal.sm4 HALUC.sm4 Queue.sm4 LLUSB.sm4 USBDef.sm4 USBLog.sm4~

Oberon.Batch
  OM4P.Compile USBLog.Mod USBConf.Mod/s USBDef.Mod/s LLUSB.Mod/s Queue.Mod/s HALUC.Mod/s USBHal.Mod/s USBHConf.Mod/s USBHDef.Mod/s~
  OM4P.Compile USBHPipes.Mod/s USBHCore.Mod/s HALHCD.Mod/s USBHHal.Mod/s USBHIoReq.Mod/s USBHCtlReq.Mod/s USBH.Mod/s~
  OM4P.Compile USBHHIDClass.Mod/s USBHHIDParser.Mod USBHHIDKeybd.Mod/s USBHHIDMouse.Mod/s USBHHID.Mod/s USBHHIDApp.Mod/s~
  OM4P.Compile USBDConf.Mod/s USBDDef.Mod/s USBDIoReq.Mod/s USBDCtlReq.Mod/s USBDCore.Mod/s HALPCD.Mod/s USBDHal.Mod/s~
  OM4P.Compile USBD.Mod/s USB.Mod/s USBDMTPDesc.Mod/s USBDMTPOpt.Mod/s USBDMTPStorage.Mod/s USBDMTP.Mod/s USBDMTPOberon.Mod/s~
  OM4P.Compile  USBApp.Mod/s~
~

Net.SendFiles CS USBLog.Mod USBConf.Mod USBDef.Mod LLUSB.Mod Queue.Mod HALUC.Mod USBHal.Mod USBHConf.Mod USBHDef.Mod~
Net.SendFiles CS USBHPipes.Mod USBHCore.Mod HALHCD.Mod USBHHal.Mod USBHIoReq.Mod USBHCtlReq.Mod USBH.Mod~
Net.SendFiles CS USBHHIDClass.Mod USBHHIDParser.Mod USBHHIDKeybd.Mod USBHHIDMouse.Mod USBHHID.Mod USBHHIDApp.Mod~
Net.SendFiles CS USBDConf.Mod USBDDef.Mod USBDIoReq.Mod USBDCtlReq.Mod USBDCore.Mod HALPCD.Mod USBDHal.Mod~
Net.SendFiles CS USBD.Mod USB.Mod USBDMTPDesc.Mod USBDMTPOpt.Mod USBDMTPOberon.Mod USBDMTPStorage.Mod USBDMTP.Mod USBApp.Mod~


System.Free USBApp USBDMTPOberon USB USBHHID USBHHIDMouse USBHHIDKeybd USBHHIDParser USBHHIDClass USBH USBHCtlReq USBHIoReq USBHHal
 USBHCore USBHPipes HALHCD USBHal USBHDef USBHConf HALUC Queue LLUSB USBDef USBLog~


USBApp.Run USBApp.Stop
USBApp.mode
HALUC.debug

OM4Tool.DecObj USBApp.m4c

DEBUG: Core version:  4F54281A
DEBUG: Core  D073F208 registered
DEBUG: Initialize Peripheral controller
DEBUG: Id 0 updated to  D0722D08
DEBUG: Connect
DEBUG: Suspend
DEBUG: Reset
DEBUG: Get Descriptor device, length 64
DEBUG: Reset
DEBUG: Set Address 17
DEBUG: Get Descriptor device, length 18
DEBUG: Get Descriptor device qualifier, length 10
DEBUG: Get Descriptor device qualifier, length 10
DEBUG: Get Descriptor device qualifier, length 10
DEBUG: Get Descriptor configuration 0, length 9
DEBUG: Get Descriptor configuration 0, length 39
DEBUG: Get Descriptor string, 0 language 0, length 255
DEBUG: Get Descriptor string, 2 language 1033, length 255
DEBUG: Get Descriptor string, 1 language 1033, length 255
DEBUG: Get Descriptor string, 3 language 1033, length 255
DEBUG: Set Configuration 1
DEBUG: Get Descriptor string, 4 language 1033, length 255
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: Get Descriptor string, 0 language 0, length 4
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: Get Descriptor string, 0 language 0, length 4
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: Get Descriptor string, 0 language 0, length 4
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: DataOutStage
DEBUG: Open session
DEBUG: DataInStage
DEBUG: DataOutStage
  TRAP   5 in USBDMTPOpt at 000007F3
DEBUG: DataInStage
DEBUG: DataInStage
DEBUG: DataOutStage
DEBUG: Core  D0722D08 unregistered
DEBUG: USB system stopped.

  pos 26562 in USBDMTPOpt at  D0214643
  pos 29649 in USBDMTPOpt at  D0214956
  pos 32108 in USBDMTPOpt at  D0214B62
  pos  8318 in USBDMTPStorage at  D0215704
  pos 10045 in USBDMTPStorage at  D0215816
  pos 10466 in USBDMTP at  D0215FEE
  pos  7340 in USBDCore at  D0212126
  pos  1731 in USBDHal at  D0212660
  pos 10321 in USBDHal at  D0212C76
  pos   512 in USBD at  D0212F60
