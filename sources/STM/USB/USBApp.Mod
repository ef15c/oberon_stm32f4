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
DEBUG: Core  D051FE88 registered
DEBUG: Initialize Peripheral controller
DEBUG: Id 0 updated to  D0520708
DEBUG: Connect
DEBUG: [       14528 -1851689126] IRQ gintsts: {30}
DEBUG: Suspend
DEBUG: [       14537 -1850319942] IRQ gintsts: {11}
DEBUG: [       14648 -1831534539] IRQ gintsts: {12}
DEBUG: Reset
DEBUG: [       14659 -1829687854] IRQ gintsts: {13}
DEBUG: [       14722 -1819154543] IRQ gintsts: {4}
DEBUG: [       14722 -1819145818] IRQ gintsts: {4}
DEBUG: Get Descriptor device, length 64
DEBUG: [       14728 -1818239092] IRQ gintsts: {4}
DEBUG: [       14728 -1818230920] IRQ gintsts: {4}
DEBUG: [       14728 -1818204702] IRQ gintsts: {12}
DEBUG: Reset
DEBUG: [       14739 -1816363752] IRQ gintsts: {13}
DEBUG: [       14800 -1806035269] IRQ gintsts: {4}
DEBUG: [       14800 -1806027152] IRQ gintsts: {4}
DEBUG: Set Address 45
DEBUG: [       14817 -1803183727] IRQ gintsts: {4}
DEBUG: [       14817 -1803175206] IRQ gintsts: {4}
DEBUG: Get Descriptor device, length 18
DEBUG: [       14820 -1802783574] IRQ gintsts: {4}
DEBUG: [       14820 -1802774898] IRQ gintsts: {4}
DEBUG: [       14820 -1802732162] IRQ gintsts: {4}
DEBUG: [       14820 -1802723292] IRQ gintsts: {4}
DEBUG: Get Descriptor device qualifier, length 10
DEBUG: [       14823 -1802133615] IRQ gintsts: {4}
DEBUG: [       14824 -1802125078] IRQ gintsts: {4}
DEBUG: Get Descriptor device qualifier, length 10
DEBUG: [       14830 -1801097237] IRQ gintsts: {4}
DEBUG: [       14830 -1801089214] IRQ gintsts: {4}
DEBUG: Get Descriptor device qualifier, length 10
DEBUG: [       14834 -1800341245] IRQ gintsts: {4}
DEBUG: [       14834 -1800333114] IRQ gintsts: {4}
DEBUG: Get Descriptor configuration 0, length 9
DEBUG: [       14843 -1798771008] IRQ gintsts: {4}
DEBUG: [       14844 -1798762058] IRQ gintsts: {4}
DEBUG: [       14844 -1798735904] IRQ gintsts: {4}
DEBUG: [       14844 -1798726794] IRQ gintsts: {4}
DEBUG: Get Descriptor configuration 0, length 39
DEBUG: [       14848 -1798076296] IRQ gintsts: {4}
DEBUG: [       14848 -1798067870] IRQ gintsts: {4}
DEBUG: [       14848 -1798039614] IRQ gintsts: {4}
DEBUG: [       14848 -1798030836] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 0 language 0, length 255
DEBUG: [       14851 -1797492238] IRQ gintsts: {4}
DEBUG: [       14851 -1797483916] IRQ gintsts: {4}
DEBUG: [       14851 -1797459892] IRQ gintsts: {4}
DEBUG: [       14851 -1797450844] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 2 language 1033, length 255
DEBUG: [       14855 -1796775044] IRQ gintsts: {4}
DEBUG: [       14855 -1796764945] IRQ gintsts: {4}
DEBUG: [       14856 -1796741368] IRQ gintsts: {4}
DEBUG: [       14856 -1796731838] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 1 language 1033, length 255
DEBUG: [       14863 -1795467638] IRQ gintsts: {4}
DEBUG: [       14863 -1795458992] IRQ gintsts: {4}
DEBUG: [       14863 -1795435446] IRQ gintsts: {4}
DEBUG: [       14863 -1795426092] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 3 language 1033, length 255
DEBUG: [       14867 -1794768030] IRQ gintsts: {4}
DEBUG: [       14867 -1794759738] IRQ gintsts: {4}
DEBUG: [       14868 -1794679209] IRQ gintsts: {4}
DEBUG: [       14868 -1794673868] IRQ gintsts: {4}
DEBUG: Set Configuration 1
DEBUG: GINTMSK: {1..2, 4, 11..13, 18..21, 28, 30..31}, DIEPMSK: {0..1, 3}, DOEPMSK: {0, 3}
DEBUG: DAINTMSK: {1..2, 16..17}, DIEPEMPMSK: {}, DIEPCTL1: {6, 15, 19, 22}
DEBUG: DIEPCTL2: {3, 15, 18..19, 23}, DOEPCTL1: {6, 15, 19, 31}, DOEPTSIZ1: {6, 19}
DEBUG: [       14874 -1793621903] IRQ gintsts: {4}
DEBUG: [       14874 -1793613586] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 4 language 1033, length 255
DEBUG: [       14881 -1792477804] IRQ gintsts: {4}
DEBUG: [       14881 -1792469196] IRQ gintsts: {4}
DEBUG: [       14881 -1792420972] IRQ gintsts: {4}
DEBUG: [       14881 -1792411948] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: [       14889 -1791181914] IRQ gintsts: {4}
DEBUG: [       14889 -1791173006] IRQ gintsts: {4}
DEBUG: [       14976 -1776559317] IRQ gintsts: {4}
DEBUG: [       14976 -1776550634] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 0 language 0, length 4
DEBUG: [       14982 -1775545474] IRQ gintsts: {4}
DEBUG: [       14982 -1775536730] IRQ gintsts: {4}
DEBUG: [       14982 -1775485990] IRQ gintsts: {4}
DEBUG: [       14982 -1775477358] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: [       14986 -1774849224] IRQ gintsts: {4}
DEBUG: [       14986 -1774840464] IRQ gintsts: {4}
DEBUG: [       15157 -1746077323] IRQ gintsts: {4}
DEBUG: [       15157 -1746069164] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 0 language 0, length 4
DEBUG: [       15173 -1743444622] IRQ gintsts: {4}
DEBUG: [       15173 -1743436456] IRQ gintsts: {4}
DEBUG: [       15173 -1743411422] IRQ gintsts: {4}
DEBUG: [       15173 -1743396114] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: [       15181 -1742140852] IRQ gintsts: {4}
DEBUG: [       15181 -1742131960] IRQ gintsts: {4}
  TRAP   5 in USBDCore at 0000021F
DEBUG: [       79840   530772753] IRQ gintsts: {4}
DEBUG: [       79840   530781038] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 0 language 0, length 4
DEBUG: [       79843   531178646] IRQ gintsts: {4}
DEBUG: [       79843   531187280] IRQ gintsts: {4}
DEBUG: [       79843   531217544] IRQ gintsts: {4}
DEBUG: [       79843   531226100] IRQ gintsts: {4}
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: [       79847   531824088] IRQ gintsts: {4}
DEBUG: [       79847   531829270] IRQ gintsts: {4}
DEBUG: [       79848   531996037] IRQ gintsts: {4}
DEBUG: [       79848   532004436] IRQ gintsts: {4}
DEBUG: DataOutStage
DEBUG: Core  D0520708 unregistered
DEBUG: USB system stopped.
Stack trace utility CS 16.05.24
  pos  4972 in USBDCore at  D021144B
  pos  1731 in USBDHal at  D02119F4
  pos 10132 in USBDHal at  D0211FE2
  pos   512 in USBD at  D02122C8
  pos   766 in USBD at  D0212324
  pos 12766 in Oberon at  08011DA8
  pos 15785 in Oberon at  08012242
  unknown PC:  08034C76
