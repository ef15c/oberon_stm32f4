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
DEBUG: Core  D054F1C8 registered
DEBUG: Initialize Peripheral controller
DEBUG: Id 0 updated to  D051AD08
DEBUG: Connect
DEBUG: [       24324  -206125160] IRQ gintsts: {30}
DEBUG: Suspend
DEBUG: [       24332  -204754944] IRQ gintsts: {11}
DEBUG: [       24645  -152104633] IRQ gintsts: {12}
DEBUG: Reset
DEBUG: [       24656  -150257670] IRQ gintsts: {13}
DEBUG: [       24718  -139856913] IRQ gintsts: {4}
DEBUG: [       24718  -139848060] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24718  -139835432] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24725  -138724177] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24725  -138711612] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24731  -137646601] IRQ gintsts: {4}
DEBUG: [       24731  -137637922] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24731  -137624068] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24731  -137608690] IRQ gintsts: {12}
DEBUG: Reset
DEBUG: [       24742  -135761782] IRQ gintsts: {13}
DEBUG: [       24794  -127080567] IRQ gintsts: {4}
DEBUG: [       24794  -127071564] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: SetAddress
DEBUG: [       24794  -127058252] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: DataInStage
DEBUG: [       24798  -126354002] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24811  -124222677] IRQ gintsts: {4}
DEBUG: [       24811  -124214382] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24811  -124201202] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24813  -123833905] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24813  -123821866] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24816  -123467873] IRQ gintsts: {4}
DEBUG: [       24816  -123459072] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24816  -123445490] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24816  -123423180] IRQ gintsts: {4}
DEBUG: [       24816  -123414190] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24816  -123399930] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24825  -121880077] IRQ gintsts: {4}
DEBUG: [       24825  -121871858] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24825  -121858724] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24828  -121449673] IRQ gintsts: {4}
DEBUG: [       24828  -121440864] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24828  -121428232] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24830  -120992381] IRQ gintsts: {4}
DEBUG: [       24830  -120983962] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24830  -120971180] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24837  -119936623] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24837  -119923992] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24839  -119571403] IRQ gintsts: {4}
DEBUG: [       24839  -119562950] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24839  -119548930] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24839  -119511134] IRQ gintsts: {4}
DEBUG: [       24839  -119501512] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24839  -119487558] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24844  -118696503] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24844  -118681386] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24846  -118321917] IRQ gintsts: {4}
DEBUG: [       24846  -118313200] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24846  -118299698] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24846  -118278364] IRQ gintsts: {4}
DEBUG: [       24846  -118269412] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24847  -118254890] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24855  -116802653] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24855  -116790624] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24857  -116438145] IRQ gintsts: {4}
DEBUG: [       24857  -116429126] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24858  -116415376] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24858  -116383950] IRQ gintsts: {4}
DEBUG: [       24858  -116375234] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24858  -116361394] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24863  -115571217] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24863  -115556912] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24865  -115202987] IRQ gintsts: {4}
DEBUG: [       24865  -115194358] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24865  -115180686] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24865  -115149614] IRQ gintsts: {4}
DEBUG: [       24865  -115140154] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24865  -115126156] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24874  -113659839] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24874  -113641268] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24876  -113295169] IRQ gintsts: {4}
DEBUG: [       24876  -113286286] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24876  -113272628] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24876  -113237462] IRQ gintsts: {4}
DEBUG: [       24876  -113228580] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24877  -113214170] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24881  -112441063] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24881  -112428984] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24887  -111464762] IRQ gintsts: {4}
DEBUG: [       24887  -111456408] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24887  -111442508] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24888  -111337651] IRQ gintsts: {4}
DEBUG: [       24888  -111328320] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: SetConfig
DEBUG: [       24888  -111314132] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: DataInStage
DEBUG: [       24893  -110523252] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24893  -110502314] IRQ gintsts: {4}
DEBUG: [       24893  -110493914] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24893  -110480336] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24896  -109898845] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24896  -109886214] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24898  -109535789] IRQ gintsts: {4}
DEBUG: [       24899  -109526866] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24899  -109513490] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       24900  -109268847] IRQ gintsts: {4}
DEBUG: [       24900  -109260296] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       24900  -109246472] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       24908  -107998471] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       24908  -107986310] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       24910  -107631533] IRQ gintsts: {4}
DEBUG: [       24910  -107623346] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       24910  -107609292] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       30974   911096749] IRQ gintsts: {4}
DEBUG: [       30974   911105380] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       30974   911118024] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       30981   912353871] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       30981   912366028] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       30986   913255022] IRQ gintsts: {4}
DEBUG: [       30987   913264156] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       30987   913277852] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       30987   913319090] IRQ gintsts: {4}
DEBUG: [       30987   913327528] IRQ gintsts: {4}
DEBUG: SetupStage
DEBUG: GetDescriptor
DEBUG: [       30987   913341652] IRQ gintsts: {19}, ep   0, doepint: {3}
DEBUG: [       31005   916345081] IRQ gintsts: {18}, ep   0, diepint: {7}
DEBUG: DataInStage
DEBUG: [       31005   916357486] IRQ gintsts: {18}, ep   0, diepint: {0}
DEBUG: [       31007   916711595] IRQ gintsts: {4}
DEBUG: [       31007   916719936] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: [       31007   916733814] IRQ gintsts: {19}, ep   0, doepint: {0}
DEBUG: [       31012   917604909] IRQ gintsts: {12}
  TRAP   5 in USBDMTPStorage at 0000015B
DEBUG: Reset
DEBUG: Core  D051AD08 unregistered
DEBUG: USB system stopped.
Stack trace utility CS 16.05.24
  pos  2689 in USBDMTPStorage at  D0213F67
  pos  3920 in USBDMTPStorage at  D0214062
  pos  5385 in USBDMTP at  D021486E
  pos  9309 in USBDCore at  D0211452
  pos  2600 in USBDHal at  D021181A
  pos  9517 in USBDHal at  D0211DFA
  pos   512 in USBD at  D0211F7C
  pos   766 in USBD at  D0211FD8
  pos 12766 in Oberon at  08011DA8
  pos 15785 in Oberon at  08012242
