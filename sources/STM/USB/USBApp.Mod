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
	USBLog 948A45D8
	USBDef 9FC6C4AD
	USB D58CB743
	USBMTPOberon 505C10BD

DEBUG: Core version:  4F54281A
DEBUG: Core  D053B888 registered
DEBUG: Initialize Peripheral controller
DEBUG: Id 0 updated to  D051AC08
DEBUG: Connect
DEBUG: [        8192  1378672996] IRQ gintsts: {30}
DEBUG: Suspend
DEBUG: [        8200  1380049790] IRQ gintsts: {11}
DEBUG: [        8506  1431562867] IRQ gintsts: {12}
DEBUG: Reset
DEBUG: [        8517  1433409892] IRQ gintsts: {13}
DEBUG: [        8579  1443792747] IRQ gintsts: {4}
DEBUG: [        8579  1443801518] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 1, length 64
DEBUG: [        8579  1443814272] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8588  1445347345] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [        8589  1445359544] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8595  1446390353] IRQ gintsts: {4}
DEBUG: [        8595  1446398942] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [        8595  1446412164] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [        8595  1446431212] IRQ gintsts: {12}
DEBUG: Reset
DEBUG: [        8606  1448278576] IRQ gintsts: {13}
DEBUG: [        8667  1458574987] IRQ gintsts: {4}
DEBUG: [        8667  1458583278] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: SetAddress
DEBUG: [        8667  1458596440] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: DataInStage
DEBUG: [        8672  1459439542] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8685  1461594119] IRQ gintsts: {4}
DEBUG: [        8685  1461602920] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 1, length 18
DEBUG: [        8685  1461615634] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8688  1462015327] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [        8688  1462027120] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8693  1462996367] IRQ gintsts: {4}
DEBUG: [        8694  1463005412] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [        8694  1463018908] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [        8694  1463029060] IRQ gintsts: {4}
DEBUG: [        8694  1463038160] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 6, length 10
DEBUG: [        8694  1463052476] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8699  1463939273] IRQ gintsts: {4}
DEBUG: [        8699  1463947372] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 6, length 10
DEBUG: [        8699  1463960554] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8702  1464483151] IRQ gintsts: {4}
DEBUG: [        8702  1464491792] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 6, length 10
DEBUG: [        8702  1464504624] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8705  1465008251] IRQ gintsts: {4}
DEBUG: [        8706  1465017310] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 2, length 9
DEBUG: [        8706  1465029882] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8712  1466098083] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [        8712  1466105390] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8714  1466416525] IRQ gintsts: {4}
DEBUG: [        8714  1466425032] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [        8714  1466438992] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [        8714  1466448800] IRQ gintsts: {4}
DEBUG: [        8714  1466458176] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 2, length 39
DEBUG: [        8714  1466472576] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8720  1467412415] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [        8720  1467424096] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8722  1467778765] IRQ gintsts: {4}
DEBUG: [        8722  1467787248] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [        8722  1467801212] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [        8722  1467811256] IRQ gintsts: {4}
DEBUG: [        8722  1467820498] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 3, length 255
DEBUG: string descriptor idx: 768
DEBUG: [        8722  1467834744] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8731  1469343003] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [        8731  1469355120] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8733  1469709415] IRQ gintsts: {4}
DEBUG: [        8733  1469718118] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [        8734  1469731810] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [        8734  1469746404] IRQ gintsts: {4}
DEBUG: [        8734  1469755334] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 3, length 255
DEBUG: string descriptor idx: 770
DEBUG: [        8734  1469769636] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8744  1471447093] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [        8744  1471461506] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8746  1471816421] IRQ gintsts: {4}
DEBUG: [        8746  1471825336] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [        8746  1471838966] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [        8746  1471849024] IRQ gintsts: {4}
DEBUG: [        8746  1471858486] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 3, length 255
DEBUG: string descriptor idx: 769
DEBUG: [        8746  1471872826] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8752  1472798463] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [        8752  1472810188] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8754  1473165375] IRQ gintsts: {4}
DEBUG: [        8754  1473173406] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [        8754  1473187484] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [        8754  1473204708] IRQ gintsts: {4}
DEBUG: [        8754  1473213674] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor: descriptor type 3, length 255
DEBUG: string descriptor idx: 771
DEBUG: [        8754  1473227916] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [        8764  1474812137] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [        8764  1474824832] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [        8766  1475107563] IRQ gintsts: {4}
DEBUG: [        8766  1475115608] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [        8766  1475129682] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [        8766  1475199557] IRQ gintsts: {4}
DEBUG: [        8766  1475208398] IRQ gintsts: {4}
DEBUG: SetupStage
  TRAP   5 in USBDCtlReq at 00000683
DEBUG: SetConfig
DEBUG: Core  D051AC08 unregistered
DEBUG: USB system stopped.
