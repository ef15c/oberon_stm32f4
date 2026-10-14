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

USBApp.Run USBApp.Stop USBApp.mode

OM4Tool.DecObj USBApp.m4c

DEBUG: Core version:  4F54281A
DEBUG: Core  D0778A88 registered
DEBUG: Initialize Peripheral controller
DEBUG: Id 0 updated to  D07758C8
DEBUG: Connect
DEBUG: Suspend
DEBUG: Reset
DEBUG: Get Descriptor device, length 64
DEBUG: Reset
DEBUG: Set Address 85
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
DEBUG: Open session
DEBUG: GetDeviceInfo
DEBUG: DeviceOpsSupported     19 elements added
DEBUG: DeviceEventsSupported      1 elements added
DEBUG: DevicePropsSupported      1 elements added
DEBUG: DeviceFormatsSupported      4 elements added
DEBUG: DeviceFormatsSupported      4 elements added
DEBUG: GetStorageIDs
DEBUG: GetStorageInfo
DEBUG: Get Descriptor string, 0 language 0, length 4
DEBUG: Get Descriptor string, 5 language 1033, length 255
DEBUG: GetObjectPropsSupp( 3000)      7 elements added
DEBUG: GetObjectPropsSupp( 3003)      7 elements added
DEBUG: GetObjectPropsSupp( 3004)      7 elements added
DEBUG: GetObjectPropsSupp( 3804)     10 elements added
DEBUG: GetDevicePropValue
DEBUG: GetObjectHandles   2215 elements added
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2017Day10.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2017Day10.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2017Day10.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2017Day10.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2017Day10.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2017Day10.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2017Day10.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2017Day10.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2017Day10.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2017Day10.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2017Day10.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2017Day10.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day11.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day11.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day11.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day11.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day11.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day11.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day11.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day11.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day11.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day11.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day11.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day11.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day13.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day13.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day13.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day13.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day13.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day13.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day13.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day13.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day13.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day13.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day17.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day17.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day17.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day17.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day17.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day17.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day17.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day17.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day17.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day17.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day19.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day19.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day19.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day19.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day19.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day19.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day19.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day19.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day19.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day19.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day1Ex.dist
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day1Ex.dist
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day1Real.dist
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day1Real.dist
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day20.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day20.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day20.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day20.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day20.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day20.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day20.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day20.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day20.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day20.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day21.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day21.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day21.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day21.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day21.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day21.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day21.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day21.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day21.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day21.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day22.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day22.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day22.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day22.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day22.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day22.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day22.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day22.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day22.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day22.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day7.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day7.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day7.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day7.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day7.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day7.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day7.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day7.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day7.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day7.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day9.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day9.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day9.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day9.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day9.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day9.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day9.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day9.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2024Day9.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2024Day9.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day1.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day1.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day1.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day1.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day1.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day1.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day1.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day1.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day1.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day1.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day10.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day10.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day10.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day10.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day10.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day10.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day10.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day10.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day10.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day10.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day11.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day11.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day11.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day11.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day11.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day11.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day11.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day11.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day11.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day11.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day12.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day12.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day12.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day12.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day12.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day12.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day12.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day12.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day12.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day12.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day2.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day2.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day2.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day2.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day2.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day2.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day2.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day3.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day3.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day3.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day3.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day3.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day3.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day3.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day3.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day3.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day3.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day4.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day4.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day4.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day4.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day4.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day4.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day4.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day4.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day5.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day5.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day5.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day5.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day5.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day5.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day5.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day5.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day5.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day5.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day5.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day5.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day6.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day6.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day6.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day6.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day6.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day6.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day6.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day6.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day6.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day6.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day7.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day7.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day7.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day7.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day7.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day7.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day7.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day7.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day7.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day7.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day8.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day8.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day8.efb
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day8.efb
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day8.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day8.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day8.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day8.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day8.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day8.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day8.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day8.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day9.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day9.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day9.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day9.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day9.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day9.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day9.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day9.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day9.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day9.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOC2025Day9.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOC2025Day9.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOCUtils.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOCUtils.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOCUtils.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOCUtils.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOCUtils.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOCUtils.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOCUtils.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOCUtils.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: AOCUtils.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: AOCUtils.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Arith.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Arith.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Arith.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Arith.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: Arith.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Arith.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: BMP.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BMP.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: BMP.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BMP.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: BMP.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BMP.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: BMP.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BMP.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: BMP.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BMP.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: BSP.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BSP.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: BSP.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BSP.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: BSP.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BSP.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: BSP.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BSP.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: BSP.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BSP.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: BSP.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BSP.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Blink.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Blink.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Blink.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Blink.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Blink.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Blink.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Blink.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Blink.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Blink.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Blink.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: BootLoad.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BootLoad.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: BootLoad.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BootLoad.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: BootLoad.bin
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BootLoad.bin
DEBUG: GetObjectInfo
DEBUG: PutFilename: BootLoad.hex
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BootLoad.hex
DEBUG: GetObjectInfo
DEBUG: PutFilename: BootLoad.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BootLoad.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: BootLoad.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BootLoad.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: BootLoad.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BootLoad.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: BootLoad1M.hex
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BootLoad1M.hex
DEBUG: GetObjectInfo
DEBUG: PutFilename: BugsCompile.Tool
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BugsCompile.Tool
DEBUG: GetObjectInfo
DEBUG: PutFilename: BuildM4.Tool
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BuildM4.Tool
DEBUG: GetObjectInfo
DEBUG: PutFilename: BuildM4.Tool.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BuildM4.Tool.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: BuildMSP.Tool
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: BuildMSP.Tool
DEBUG: GetObjectInfo
DEBUG: PutFilename: CConv.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CConv.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: CConv.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CConv.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: CConv.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CConv.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: CConv.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CConv.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: CConv.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CConv.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: CConv.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CConv.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: CRC32.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CRC32.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: CRC32.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CRC32.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: CRC32.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CRC32.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: CRC32.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CRC32.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: CRC32.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: CRC32.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Characters.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Characters.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Characters.Text
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Characters.Text
DEBUG: GetObjectInfo
DEBUG: PutFilename: Characters.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Characters.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Characters.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Characters.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Checkers.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Checkers.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Checkers.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Checkers.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Checkers.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Checkers.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Checkers.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Checkers.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Checkers.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Checkers.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Checkers.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Checkers.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Clipboard.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Clipboard.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: ClutGen.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ClutGen.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: ClutGen.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ClutGen.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: ClutGen.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ClutGen.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Conv.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Conv.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Conv.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Conv.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: Conv.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Conv.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: Curves.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Curves.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Curves.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Curves.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Curves.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Curves.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Curves.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Curves.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Curves.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Curves.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA2D.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA2D.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA2D.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA2D.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA2D.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA2D.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA2D.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA2D.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA2D.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA2D.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: DMA2D.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DMA2D.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone2.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone2.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone2.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone2.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone2.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone2.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone2.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone2.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Dhrystone2.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Dhrystone2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Display.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Display.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Display.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Display.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Display.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Display.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Display.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Display.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Display.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Display.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Display.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Display.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Draw.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Draw.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Draw.Tool
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Draw.Tool
DEBUG: GetObjectInfo
DEBUG: PutFilename: Draw.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Draw.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Draw.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Draw.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Draw.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Draw.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Draw.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Draw.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: DynMenu.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DynMenu.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: DynMenu.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DynMenu.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: DynMenu.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DynMenu.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: DynMenu.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DynMenu.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: DynMenu.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DynMenu.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: DynMenu.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: DynMenu.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: EBNF.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: EBNF.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Edit.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Edit.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Edit.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Edit.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Edit.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Edit.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Edit.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Edit.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Edit.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Edit.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Edit.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Edit.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Elektra.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Elektra.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Empty.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Empty.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Empty.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Empty.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Empty.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Empty.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: Empty.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Empty.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Empty.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Empty.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Empty.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Empty.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Empty.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Empty.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: FLASH.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FLASH.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: FLASH.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FLASH.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: FLASH.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FLASH.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: FLASH.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FLASH.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: FLASH.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FLASH.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: FLASH.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FLASH.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: Facto.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Facto.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fermat.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fermat.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: FileDir.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FileDir.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: FileDir.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FileDir.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: FileDir.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FileDir.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: FileDir.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FileDir.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: FileDir.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FileDir.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: FileDir.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FileDir.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Files.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Files.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Files.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Files.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Files.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Files.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Files.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Files.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Files.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Files.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx0.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx0.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx0.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx0.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx0.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx0.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx0.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx0.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: FilesEx0.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FilesEx0.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: FontUtils.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FontUtils.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: FontUtils.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FontUtils.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: FontUtils.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FontUtils.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: FontUtils.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FontUtils.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: FontUtils.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: FontUtils.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fonts.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fonts.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fonts.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fonts.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fonts.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fonts.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fonts.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fonts.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fonts.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fonts.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fractions.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fractions.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fractions.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fractions.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Fractions.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Fractions.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: GUIJson.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GUIJson.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: GUIJson.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GUIJson.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: GUIJson.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GUIJson.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: GUIMpack.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GUIMpack.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: GUIMpack.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GUIMpack.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: GUIMpack.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GUIMpack.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphTool.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphTool.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphTool.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphTool.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphTool.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphTool.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphTool.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphTool.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphTool.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphTool.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphicFrames.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphicFrames.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphicFrames.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphicFrames.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphicFrames.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphicFrames.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphicFrames.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphicFrames.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphicFrames.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphicFrames.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: GraphicFrames.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: GraphicFrames.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Graphics.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Graphics.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Graphics.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Graphics.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Graphics.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Graphics.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Graphics.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Graphics.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Graphics.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Graphics.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALGUImsp430g255x.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALGUImsp430g255x.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALGUImsp430g255x.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALGUImsp430g255x.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALGUImsp430g255x.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALGUImsp430g255x.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALHCD.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALHCD.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALHCD.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALHCD.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALHCD.Mod.Bak.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALHCD.Mod.Bak.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALHCD.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALHCD.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALHCD.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALHCD.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALHCD.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALHCD.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALHCD.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALHCD.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALIOmsp430g255x.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALIOmsp430g255x.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALIOmsp430g255x.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALIOmsp430g255x.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALIOmsp430g255x.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALIOmsp430g255x.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALPCD.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALPCD.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALPCD.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALPCD.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALPCD.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALPCD.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALPCD.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALPCD.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALPCD.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALPCD.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALPCD.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALPCD.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALSYSmsp430g255x.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALSYSmsp430g255x.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALSYSmsp430g255x.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALSYSmsp430g255x.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALSYSmsp430g255x.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALSYSmsp430g255x.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALTIMmsp430g255x.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALTIMmsp430g255x.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALTIMmsp430g255x.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALTIMmsp430g255x.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALTIMmsp430g255x.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALTIMmsp430g255x.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALUC.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALUC.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALUC.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALUC.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALUC.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALUC.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALUC.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALUC.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALUC.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALUC.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: HALUC.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HALUC.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Harmonic.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Harmonic.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Harmonic.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Harmonic.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Harmonic.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Harmonic.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: HeapTool.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HeapTool.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: HeapTool.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HeapTool.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: HeapTool.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HeapTool.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: HeapTool.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HeapTool.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: HeapTool.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: HeapTool.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Hilbert.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Hilbert.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Hilbert.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Hilbert.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Hilbert.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Hilbert.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Hilbert.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Hilbert.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Hilbert.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Hilbert.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Hilbert.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Hilbert.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: ISRTrap.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ISRTrap.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: ISRTrap.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ISRTrap.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: ISRTrap.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ISRTrap.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: Image.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Image.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Image.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Image.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Image.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Image.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Image.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Image.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Image.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Image.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Image.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Image.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Input.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Input.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Input.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Input.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Input.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Input.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Input.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Input.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: InputAzerty.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: InputAzerty.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: InputAzerty.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: InputAzerty.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: InputQwerty.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: InputQwerty.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: JDraw.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JDraw.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: JDraw.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JDraw.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: JDraw.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JDraw.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: JDraw.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JDraw.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: JDraw.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JDraw.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: JDraw.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JDraw.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: JSONCallbacks.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JSONCallbacks.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: JSONCallbacks.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JSONCallbacks.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: JSONCallbacks.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JSONCallbacks.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: JSONGUIComm.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JSONGUIComm.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: JSONGUIComm.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JSONGUIComm.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: JSONGUIComm.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: JSONGUIComm.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: Kernel.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Kernel.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Kernel.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Kernel.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Kernel.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Kernel.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Kernel.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Kernel.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Kernel.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Kernel.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Kernel.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Kernel.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Kernel.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Kernel.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: LLUSB.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LLUSB.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: LLUSB.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LLUSB.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: LLUSB.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LLUSB.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: LLUSB.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LLUSB.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: LLUSB.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LLUSB.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: LLUSB.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LLUSB.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: LTDC.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LTDC.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: LTDC.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LTDC.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: LTDC.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LTDC.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: LTDC.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LTDC.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: LTDC.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LTDC.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: LTDC.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LTDC.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Led.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Led.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Led.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Led.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Led.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Led.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Led.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Led.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Led.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Led.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongDiv.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongDiv.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongDiv.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongDiv.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongDiv.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongDiv.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongDiv.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongDiv.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongDiv.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongDiv.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongDiv.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongDiv.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongInt.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongInt.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongInt.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongInt.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongInt.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongInt.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongInt.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongInt.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: LongInt.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: LongInt.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPEXP430G2Launchpad.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPEXP430G2Launchpad.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPEXP430G2Launchpad.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPEXP430G2Launchpad.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPEXP430G2Launchpad.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPEXP430G2Launchpad.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPEXP430G2Launchpad.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPEXP430G2Launchpad.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPFlash.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPFlash.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPFlash.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPFlash.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPFlash.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPFlash.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPFlashTypes.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPFlashTypes.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPFlashTypes.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPFlashTypes.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: MSPFlashTypes.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MSPFlashTypes.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: MacroTool.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MacroTool.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: MacroTool.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MacroTool.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: MacroTool.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MacroTool.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: MacroTool.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MacroTool.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: MacroTool.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MacroTool.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: MagicSquares.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MagicSquares.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: MagicSquares.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MagicSquares.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: MagicSquares.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MagicSquares.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Math.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Math.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Math.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Math.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Math.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Math.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Math.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Math.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Math.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Math.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: MenuViewers.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MenuViewers.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: MenuViewers.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MenuViewers.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: MenuViewers.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MenuViewers.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: MenuViewers.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MenuViewers.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: MenuViewers.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MenuViewers.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: MenuViewers.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MenuViewers.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Mira.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Mira.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Mira.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Mira.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Mira.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Mira.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Mira.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Mira.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Mira.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Mira.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Mira.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Mira.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Modules.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Modules.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Modules.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Modules.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Modules.bin
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Modules.bin
DEBUG: GetObjectInfo
DEBUG: PutFilename: Modules.efb
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Modules.efb
DEBUG: GetObjectInfo
DEBUG: PutFilename: Modules.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Modules.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Modules.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Modules.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Modules.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Modules.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Modules.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Modules.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Mono10.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Mono10.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Mono10.Scn.bdf
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Mono10.Scn.bdf
DEBUG: GetObjectInfo
DEBUG: PutFilename: MpackCallbacks.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MpackCallbacks.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: MpackCallbacks.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MpackCallbacks.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: MpackCallbacks.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MpackCallbacks.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: MpackGUIComm.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MpackGUIComm.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: MpackGUIComm.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MpackGUIComm.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: MpackGUIComm.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MpackGUIComm.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: MultiPrecisionArith.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MultiPrecisionArith.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: MultiPrecisionArith.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MultiPrecisionArith.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: MultiPrecisionArith.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MultiPrecisionArith.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: MultiPrecisionArith.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MultiPrecisionArith.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: MultiPrecisionArith.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MultiPrecisionArith.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: MultiPrecisionArith.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MultiPrecisionArith.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: MultiPrecisionArith.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: MultiPrecisionArith.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: Net.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Net.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Net.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Net.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Net.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Net.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Net.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Net.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Net.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Net.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Net.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Net.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A0.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A0.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A0.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A0.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A0.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A0.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A0.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A0.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A0.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A0.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A1.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A1.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A1.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A1.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A1.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A1.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A1.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A1.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4A1.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4A1.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B0.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B0.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B0.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B0.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B0.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B0.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B0.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B0.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4B0.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4B0.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4D.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4D.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4D.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4D.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4D.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4D.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4D.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4D.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4D.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4D.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4D.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4D.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G0.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G0.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G0.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G0.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G0.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G0.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G0.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G0.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G0.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G0.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G1.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G1.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G1.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G1.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G1.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G1.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G1.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G1.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4G1.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4G1.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4L.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4L.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4L.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4L.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4L.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4L.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4L.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4L.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4L.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4L.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4L.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4L.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P.efb
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P.efb
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P.efb.ref
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P.efb.ref
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P0.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P0.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P0.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P0.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P0.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P0.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P0.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P0.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P0.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P0.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P1.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P1.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P1.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P1.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P1.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P1.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P1.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P1.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4P1.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4P1.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S0.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S0.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S0.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S0.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S0.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S0.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S0.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S0.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4S0.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4S0.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4Tool.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4Tool.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4Tool.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4Tool.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4Tool.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4Tool.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4Tool.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4Tool.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4Tool.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4Tool.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4Tool.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4Tool.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4X.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4X.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4X.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4X.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4X.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4X.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4X.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4X.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OM4X.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OM4X.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPA.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPA.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPA.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPA.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPA.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPA.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPA.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPA.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPA.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPA.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPA.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPA.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPB.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPB.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPB.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPB.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPB.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPB.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPB.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPB.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPB.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPB.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPB.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPB.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPD.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPD.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPD.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPD.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPD.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPD.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPD.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPD.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPD.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPD.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPD.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPD.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPG.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPG.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPG.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPG.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPG.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPG.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPG.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPG.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPG.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPG.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPG.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPG.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPL.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPL.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPL.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPL.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPL.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPL.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPL.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPL.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPL.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPL.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPL.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPL.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPP.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPP.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPP.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPP.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPP.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPP.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPP.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPP.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPP.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPP.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPP.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPP.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPS.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPS.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPS.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPS.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPS.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPS.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPS.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPS.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPS.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPS.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPTool.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPTool.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPTool.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPTool.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPTool.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPTool.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPTool.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPTool.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OMSPTool.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OMSPTool.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon.bin
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon.bin
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon10.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon10.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon10.Scn.bdf
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon10.Scn.bdf
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon10.Scn.cp1252.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon10.Scn.cp1252.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon10.Scn.cp1252.bdf
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon10.Scn.cp1252.bdf
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon10b.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon10b.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon10i.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon10i.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon12.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon12.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon12b.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon12b.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon12i.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon12i.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon16.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon16.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon8.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon8.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Oberon8i.Scn.Fnt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Oberon8i.Scn.Fnt
DEBUG: GetObjectInfo
DEBUG: PutFilename: OberonLogoInverse.bmp
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OberonLogoInverse.bmp
DEBUG: GetObjectInfo
DEBUG: PutFilename: OberonSyntax.Text
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OberonSyntax.Text
DEBUG: GetObjectInfo
DEBUG: PutFilename: OnStartup.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OnStartup.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: OnStartup.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OnStartup.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: OnStartup.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OnStartup.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: OnStartup.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OnStartup.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: OnStartup.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: OnStartup.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Out.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Out.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Out.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Out.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Out.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Out.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Out.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Out.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Out.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Out.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: PCLink1.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PCLink1.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: PIO.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PIO.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: PS2.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PS2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: PS2.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PS2.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: PS2.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PS2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: PS2.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PS2.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: PS2.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PS2.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: PS2.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PS2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Patch.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Patch.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Patch.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Patch.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Patch.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Patch.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Patch.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Patch.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Patch.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Patch.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Permutations.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Permutations.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Permutations.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Permutations.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Permutations.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Permutations.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: PosixTime.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PosixTime.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: PosixTime.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PosixTime.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: PosixTime.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PosixTime.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: PosixTime.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PosixTime.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: Powers.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Powers.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Powers.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Powers.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Powers.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Powers.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: PrimeNumbers.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PrimeNumbers.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: PrimeNumbers.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PrimeNumbers.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: PrimeNumbers.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: PrimeNumbers.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8M4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8M4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8M4.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8M4.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8M4.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8M4.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8M4.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8M4.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: QMath8M4.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QMath8M4.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Queue.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Queue.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Queue.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Queue.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Queue.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Queue.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Queue.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Queue.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Queue.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Queue.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Queue.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Queue.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: QuickSort.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QuickSort.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: QuickSort.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QuickSort.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: QuickSort.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QuickSort.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: QuickSort.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QuickSort.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: QuickSort.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: QuickSort.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: RS232.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: RS232.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: RS232.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: RS232.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: RS232.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: RS232.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: RS232.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: RS232.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: RS232.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: RS232.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Rectangles.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Rectangles.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Rectangles.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Rectangles.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Rectangles.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Rectangles.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Rectangles.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Rectangles.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Rectangles.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Rectangles.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: SCC.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SCC.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: SCC.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SCC.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: SCC.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SCC.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: SCC.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SCC.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: SCC.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SCC.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: SCC.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SCC.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: SDCard.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SDCard.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: SDCard.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SDCard.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: SDCard.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SDCard.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: SDCard.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SDCard.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: SDCard.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SDCard.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: SDCard2.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SDCard2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: SDCard2.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SDCard2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: SDCard2.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SDCard2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowDebugP.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowDebugP.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowDebugP.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowDebugP.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowDebugP.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowDebugP.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowDebugP.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowDebugP.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowDebugP.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowDebugP.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowDebugP.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowDebugP.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowPatterns.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowPatterns.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowPatterns.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowPatterns.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowPatterns.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowPatterns.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowPatterns.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowPatterns.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: ShowPatterns.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: ShowPatterns.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Sierpinski.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Sierpinski.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Sierpinski.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Sierpinski.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Sierpinski.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Sierpinski.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Sierpinski.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Sierpinski.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Sierpinski.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Sierpinski.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: SmallPrograms.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SmallPrograms.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: StackTrace.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: StackTrace.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: StackTrace.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: StackTrace.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: StackTrace.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: StackTrace.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: StackTrace.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: StackTrace.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: StackTrace.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: StackTrace.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: StackTrace.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: StackTrace.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Stars.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Stars.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Stars.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Stars.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Stars.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Stars.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Stars.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Stars.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Stars.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Stars.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: String.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: String.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: String.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: String.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: String.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: String.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: StructureSysteme.Text
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: StructureSysteme.Text
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.Log
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.Log
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.Log.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.Log.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.ShowModules
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.ShowModules
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.ShowModules.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.ShowModules.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.Tool
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.Tool
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.Tool.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.Tool.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.efb
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.efb
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: System.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: System.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: SystemLog.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SystemLog.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: SystemLog.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SystemLog.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: SystemLog.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SystemLog.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: SystemLog.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SystemLog.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: SystemLog.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: SystemLog.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: TFOld.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TFOld.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: TTL0.Lib
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TTL0.Lib
DEBUG: GetObjectInfo
DEBUG: PutFilename: TTL1.Lib
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TTL1.Lib
DEBUG: GetObjectInfo
DEBUG: PutFilename: TestDragon.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TestDragon.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: TestDragon.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TestDragon.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: TestDragon.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TestDragon.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: TestDragon.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TestDragon.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: TestDragon.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TestDragon.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextFrames.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextFrames.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextFrames.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextFrames.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextFrames.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextFrames.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextFrames.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextFrames.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextFrames.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextFrames.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextFrames.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextFrames.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextTools.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextTools.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextTools.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextTools.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextTools.Mod.raw
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextTools.Mod.raw
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextTools.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextTools.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextTools.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextTools.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextTools.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextTools.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextTools.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextTools.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Texts.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Texts.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Texts.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Texts.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Texts.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Texts.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Texts.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Texts.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Texts.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Texts.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Texts.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Texts.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextsEx0.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextsEx0.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextsEx0.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextsEx0.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextsEx0.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextsEx0.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextsEx0.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextsEx0.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: TextsEx0.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TextsEx0.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Thermometre.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Thermometre.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Thermometre.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Thermometre.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: Thermometre.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Thermometre.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: Thermometre.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Thermometre.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: Timer.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Timer.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Timer.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Timer.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Timer.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Timer.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Timer.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Timer.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Timer.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Timer.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Timer.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Timer.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Tools.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Tools.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Tools.Mod.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Tools.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Tools.Text
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Tools.Text
DEBUG: GetObjectInfo
DEBUG: PutFilename: Tools.Text.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Tools.Text.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Tools.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Tools.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Tools.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Tools.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Tools.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Tools.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Tools.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Tools.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: TraceBug.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TraceBug.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: TraceBug.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TraceBug.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: TraceBug.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TraceBug.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: TraceBug.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TraceBug.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: TraceBug.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: TraceBug.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Traps.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Traps.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Traps.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Traps.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: Traps.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Traps.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: Types.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Types.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Types.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Types.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Types.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Types.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: Types.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Types.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Types.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Types.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Types.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Types.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Types.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Types.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: USB.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USB.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USB.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USB.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USB.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USB.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USB.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USB.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USB.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USB.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USB.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USB.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBApp.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBApp.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBApp.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBApp.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBApp.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBApp.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBApp.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBApp.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBApp.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBApp.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBApp.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBApp.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBConf.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBConf.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBConf.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBConf.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBConf.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBConf.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBConf.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBConf.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBConf.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBConf.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBConf.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBConf.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBD.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBD.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBD.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBD.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBD.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBD.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBD.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBD.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBD.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBD.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBD.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBD.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDConf.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDConf.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDConf.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDConf.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDConf.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDConf.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDConf.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDConf.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDConf.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDConf.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDConf.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDConf.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCore.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCore.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCore.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCore.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCore.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCore.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCore.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCore.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCore.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCore.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCore.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCore.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCtlReq.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCtlReq.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCtlReq.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCtlReq.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCtlReq.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCtlReq.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCtlReq.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCtlReq.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCtlReq.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCtlReq.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDCtlReq.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDCtlReq.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDDef.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDDef.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDDef.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDDef.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDDef.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDDef.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDDef.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDDef.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDDef.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDDef.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDDef.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDDef.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDHal.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDHal.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDHal.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDHal.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDHal.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDHal.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDHal.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDHal.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDHal.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDHal.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDHal.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDHal.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDIoReq.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDIoReq.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDIoReq.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDIoReq.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDIoReq.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDIoReq.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDIoReq.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDIoReq.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDIoReq.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDIoReq.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDIoReq.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDIoReq.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTP.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTP.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTP.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTP.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTP.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTP.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTP.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTP.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTP.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTP.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTP.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTP.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPDesc.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPDesc.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPDesc.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPDesc.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPDesc.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPDesc.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPDesc.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPDesc.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPDesc.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPDesc.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPDesc.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPDesc.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOberon.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOberon.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOberon.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOberon.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOberon.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOberon.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOberon.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOberon.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOberon.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOberon.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOberon.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOberon.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOpt.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOpt.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOpt.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOpt.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOpt.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOpt.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOpt.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOpt.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOpt.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOpt.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPOpt.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPOpt.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPStorage.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPStorage.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPStorage.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPStorage.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPStorage.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPStorage.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPStorage.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPStorage.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPStorage.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPStorage.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDMTPStorage.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDMTPStorage.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDef.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDef.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDef.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDef.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDef.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDef.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDef.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDef.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDef.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDef.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBDef.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBDef.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBH.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBH.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBH.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBH.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBH.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBH.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBH.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBH.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBH.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBH.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBH.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBH.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHConf.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHConf.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHConf.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHConf.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHConf.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHConf.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHConf.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHConf.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHConf.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHConf.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHConf.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHConf.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCore.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCore.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCore.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCore.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCore.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCore.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCore.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCore.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCore.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCore.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCore.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCore.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCtlReq.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCtlReq.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCtlReq.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCtlReq.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCtlReq.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCtlReq.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCtlReq.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCtlReq.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCtlReq.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCtlReq.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHCtlReq.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHCtlReq.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHDef.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHDef.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHDef.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHDef.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHDef.bin
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHDef.bin
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHDef.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHDef.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHDef.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHDef.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHDef.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHDef.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHDef.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHDef.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHID.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHID.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHID.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHID.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHID.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHID.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHID.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHID.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHID.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHID.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHID.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHID.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDApp.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDApp.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDApp.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDApp.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDApp.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDApp.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDApp.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDApp.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDApp.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDApp.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDApp.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDApp.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDClass.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDClass.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDClass.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDClass.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDClass.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDClass.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDClass.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDClass.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDClass.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDClass.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDClass.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDClass.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDKeybd.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDKeybd.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDKeybd.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDKeybd.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDKeybd.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDKeybd.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDKeybd.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDKeybd.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDKeybd.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDKeybd.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDKeybd.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDKeybd.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDMouse.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDMouse.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDMouse.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDMouse.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDMouse.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDMouse.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDMouse.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDMouse.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDMouse.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDMouse.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDMouse.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDMouse.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDParser.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDParser.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDParser.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDParser.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDParser.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDParser.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDParser.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDParser.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDParser.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDParser.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHIDParser.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHIDParser.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHal.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHal.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHal.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHal.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHal.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHal.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHal.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHal.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHal.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHal.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHHal.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHHal.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHIoReq.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHIoReq.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHIoReq.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHIoReq.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHIoReq.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHIoReq.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHIoReq.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHIoReq.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHIoReq.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHIoReq.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHIoReq.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHIoReq.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHPipes.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHPipes.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHPipes.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHPipes.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHPipes.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHPipes.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHPipes.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHPipes.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHPipes.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHPipes.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHPipes.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHPipes.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHal.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHal.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHal.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHal.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHal.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHal.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHal.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHal.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHal.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHal.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBHal.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBHal.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBLog.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBLog.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBLog.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBLog.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBLog.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBLog.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBLog.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBLog.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBLog.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBLog.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: USBLog.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: USBLog.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: UTHash.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: UTHash.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: UTHash.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: UTHash.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: UTHash.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: UTHash.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: UTHash.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: UTHash.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: UTHash.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: UTHash.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: Viewers.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Viewers.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: Viewers.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Viewers.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: Viewers.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Viewers.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: Viewers.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Viewers.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: Viewers.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Viewers.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: Viewers.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: Viewers.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: bootloader.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bootloader.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: bootloader.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bootloader.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: bootloader.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bootloader.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: bootloader.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bootloader.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: bootloader.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bootloader.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: boottest.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: boottest.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: boottest.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: boottest.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: boottest.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: boottest.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: boottest.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: boottest.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: brownoutDetector.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: brownoutDetector.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: brownoutDetector.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: brownoutDetector.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: brownoutDetector.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: brownoutDetector.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: brownoutDetector.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: brownoutDetector.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOM4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOM4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOM4.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOM4.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOM4.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOM4.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOM4.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOM4.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOM4.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOM4.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOM4.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOM4.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: bugOMSP.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: bugOMSP.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: checkOM4B.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: checkOM4B.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: checkOM4B.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: checkOM4B.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: checkOM4B.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: checkOM4B.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: checkOM4B.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: checkOM4B.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: checkOM4B.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: checkOM4B.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: checkOM4B.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: checkOM4B.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: cleanBoot.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: cleanBoot.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: cleanBoot.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: cleanBoot.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: cleanBoot.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: cleanBoot.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: cleanBoot.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: cleanBoot.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: cleanBoot.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: cleanBoot.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: dhrystone.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: dhrystone.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: dhrystone.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: dhrystone.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: dhrystone.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: dhrystone.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: dhrystone.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: dhrystone.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: dhrystone2.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: dhrystone2.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: dhrystone2.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: dhrystone2.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: halhcd.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halhcd.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: halhcd.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halhcd.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: halhcd.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halhcd.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: halpcd.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halpcd.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: halpcd.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halpcd.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: halpcd.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halpcd.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: halpcd.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halpcd.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: halpcdex.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halpcdex.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: halpcdex.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: halpcdex.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: jsmn.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: jsmn.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: jsmn.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: jsmn.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: jsmn.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: jsmn.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: jsmnM4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: jsmnM4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: jsmnM4.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: jsmnM4.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: jsmnM4.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: jsmnM4.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: jsmnM4.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: jsmnM4.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: jsmnM4.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: jsmnM4.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: keyboard.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: keyboard.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: keyboard.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: keyboard.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: llusb.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: llusb.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: llusb.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: llusb.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: llusb.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: llusb.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: llusb.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: llusb.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: lvalue.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: lvalue.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: lvalue.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: lvalue.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: lvalue.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: lvalue.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: main.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: main.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: main.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: main.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: main.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: main.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: menu.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: menu.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: menu.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: menu.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: minihdlc.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: minihdlc.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: minihdlc.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: minihdlc.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: minihdlc.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: minihdlc.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: mouse.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: mouse.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: mouse.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: mouse.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: mpack.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: mpack.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: mpack.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: mpack.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: mpack.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: mpack.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430delay.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430delay.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430delay.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430delay.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430delay.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430delay.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2231.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2231.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2231.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2231.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2231.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2231.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553GcSmplJson.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553GcSmplJson.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553GcSmplJson.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553GcSmplJson.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553GcSmplJson.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553GcSmplJson.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553GcSmplJson.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553GcSmplJson.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553GcSmplMpack.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553GcSmplMpack.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553GcSmplMpack.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553GcSmplMpack.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553GcSmplMpack.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553GcSmplMpack.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2553GcSmplMpack.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2553GcSmplMpack.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca01.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca01.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca01.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca01.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca01.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca01.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca01.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca01.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca01.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca01.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca02.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca02.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca02.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca02.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca02.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca02.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca02.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca02.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca02.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca02.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca03.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca03.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca03.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca03.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca03.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca03.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca03.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca03.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x13ca03.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x13ca03.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1001.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1001.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1001.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1001.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1001.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1001.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1001.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1001.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1001.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1001.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1002.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1002.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1002.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1002.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1002.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1002.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1002.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1002.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1002.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1002.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1003.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1003.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1003.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1003.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1003.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1003.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1003.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1003.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1003.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1003.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1004.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1004.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1004.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1004.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1004.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1004.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1004.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1004.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1004.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1004.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1005.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1005.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1005.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1005.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1005.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1005.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1005.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1005.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1005.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1005.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1006.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1006.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1006.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1006.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1006.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1006.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1006.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1006.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1006.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1006.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1007.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1007.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1007.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1007.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1007.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1007.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1007.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1007.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1007.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1007.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1008.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1008.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1008.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1008.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1008.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1008.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1008.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1008.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1008.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1008.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1009.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1009.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1009.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1009.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1009.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1009.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1009.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1009.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1009.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1009.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1010.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1010.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1010.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1010.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1010.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1010.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1010.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1010.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1010.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1010.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1011.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1011.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1011.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1011.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1011.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1011.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1011.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1011.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1011.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1011.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1012.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1012.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1012.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1012.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1012.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1012.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1012.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1012.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1012.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1012.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1013.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1013.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1013.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1013.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1013.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1013.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1013.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1013.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1013.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1013.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1014.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1014.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1014.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1014.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1014.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1014.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1014.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1014.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1014.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1014.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1016.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1016.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1016.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1016.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1016.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1016.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1016.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1016.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc1016.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc1016.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc10temp.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc10temp.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc10temp.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc10temp.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc10temp.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc10temp.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc10temp.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc10temp.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2x33adc10temp.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2x33adc10temp.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31vlo.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31vlo.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31vlo.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31vlo.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31vlo.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31vlo.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31vlo.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31vlo.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx31vlo.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx31vlo.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3LFxtalnmi.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3LFxtalnmi.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3LFxtalnmi.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3LFxtalnmi.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3LFxtalnmi.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3LFxtalnmi.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3LFxtalnmi.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3LFxtalnmi.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3LFxtalnmi.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3LFxtalnmi.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P101.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P101.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P101.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P101.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P101.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P101.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P101.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P101.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P101.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P101.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P102.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P102.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P102.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P102.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P102.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P102.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P102.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P102.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P102.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P102.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P103.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P103.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P103.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P103.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P103.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P103.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P103.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P103.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P103.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P103.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P104.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P104.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P104.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P104.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P104.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P104.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P104.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P104.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3P104.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3P104.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3clks.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3clks.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3clks.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3clks.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3clks.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3clks.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3clks.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3clks.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3clks.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3clks.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcocalib.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcocalib.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcocalib.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcocalib.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcocalib.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcocalib.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcocalib.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcocalib.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcocalib.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcocalib.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcoflashcal.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcoflashcal.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcoflashcal.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcoflashcal.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcoflashcal.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcoflashcal.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcoflashcal.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcoflashcal.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3dcoflashcal.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3dcoflashcal.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3flashwrite01.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3flashwrite01.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3flashwrite01.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3flashwrite01.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3flashwrite01.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3flashwrite01.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3flashwrite01.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3flashwrite01.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3flashwrite01.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3flashwrite01.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3vlo.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3vlo.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3vlo.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3vlo.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3vlo.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3vlo.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3vlo.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3vlo.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3lpm3vlo.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3lpm3vlo.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3nmi.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3nmi.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3nmi.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3nmi.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3nmi.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3nmi.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3nmi.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3nmi.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3nmi.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3nmi.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta01.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta01.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta01.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta01.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta01.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta01.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta01.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta01.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta01.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta01.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta02.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta02.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta02.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta02.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta02.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta02.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta02.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta02.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta02.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta02.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta03.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta03.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta03.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta03.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta03.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta03.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta03.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta03.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta03.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta03.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta04.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta04.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta04.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta04.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta04.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta04.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta04.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta04.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta04.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta04.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta05.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta05.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta05.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta05.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta05.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta05.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta05.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta05.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta05.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta05.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta06.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta06.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta06.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta06.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta06.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta06.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta06.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta06.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta06.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta06.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta07.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta07.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta07.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta07.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta07.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta07.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta07.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta07.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta07.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta07.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta08.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta08.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta08.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta08.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta08.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta08.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta08.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta08.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta08.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta08.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta10.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta10.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta10.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta10.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta10.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta10.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta10.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta10.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta10.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta10.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta11.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta11.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta11.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta11.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta11.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta11.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta11.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta11.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta11.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta11.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta13.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta13.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta13.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta13.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta13.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta13.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta13.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta13.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta13.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta13.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta14.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta14.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta14.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta14.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta14.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta14.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta14.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta14.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta14.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta14.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta16.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta16.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta16.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta16.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta16.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta16.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta16.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta16.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta16.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta16.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta17.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta17.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta17.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta17.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta17.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta17.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta17.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta17.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta17.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta17.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta19.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta19.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta19.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta19.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta19.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta19.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta19.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta19.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta19.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta19.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta20.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta20.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta20.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta20.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta20.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta20.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta20.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta20.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta20.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta20.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta21.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta21.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta21.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta21.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta21.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta21.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta21.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta21.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3ta21.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3ta21.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart2400.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart2400.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart2400.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart2400.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart2400.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart2400.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart2400.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart2400.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart2400.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart2400.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart9600.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart9600.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart9600.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart9600.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart9600.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart9600.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart9600.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart9600.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3tauart9600.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3tauart9600.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0irda01.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0irda01.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0irda01.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0irda01.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0irda01.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0irda01.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0irda01.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0irda01.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0irda01.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0irda01.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi09.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi09.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi09.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi09.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi09.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi09.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi09.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi09.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi09.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi09.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi10.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi10.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi10.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi10.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi10.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi10.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi10.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi10.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0spi10.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0spi10.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115k.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115k.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115k.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115k.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115k.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115k.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115k.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115k.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115k.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115k.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115kl.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115kl.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115kl.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115kl.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115kl.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115kl.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115kl.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115kl.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u115kl.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u115kl.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u19200.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u19200.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u19200.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u19200.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u19200.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u19200.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u19200.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u19200.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u19200.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u19200.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u59600.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u59600.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u59600.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u59600.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u59600.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u59600.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u59600.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u59600.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u59600.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u59600.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u69600.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u69600.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u69600.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u69600.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u69600.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u69600.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u69600.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u69600.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u69600.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u69600.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u79600.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u79600.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u79600.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u79600.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u79600.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u79600.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u79600.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u79600.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u79600.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u79600.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u89600.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u89600.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u89600.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u89600.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u89600.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u89600.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u89600.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u89600.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u89600.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u89600.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u9600.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u9600.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u9600.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u9600.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u9600.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u9600.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u9600.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u9600.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscia0u9600.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscia0u9600.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c01.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c01.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c01.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c01.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c01.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c01.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c01.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c01.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c01.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c01.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c02.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c02.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c02.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c02.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c02.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c02.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c02.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c02.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c02.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c02.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c03.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c03.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c03.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c03.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c03.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c03.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c03.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c03.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c03.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c03.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c04.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c04.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c04.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c04.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c04.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c04.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c04.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c04.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c04.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c04.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c05.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c05.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c05.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c05.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c05.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c05.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c05.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c05.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c05.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c05.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c06.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c06.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c06.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c06.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c06.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c06.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c06.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c06.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c06.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c06.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c07.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c07.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c07.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c07.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c07.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c07.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c07.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c07.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c07.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c07.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c08.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c08.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c08.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c08.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c08.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c08.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c08.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c08.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c08.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c08.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c09.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c09.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c09.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c09.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c09.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c09.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c09.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c09.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c09.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c09.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c10.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c10.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c10.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c10.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c10.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c10.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c10.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c10.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c10.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c10.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c11.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c11.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c11.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c11.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c11.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c11.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c11.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c11.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c11.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c11.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c12.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c12.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c12.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c12.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c12.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c12.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c12.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c12.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c12.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c12.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c13.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c13.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c13.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c13.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c13.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c13.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c13.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c13.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2c13.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2c13.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2csm.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2csm.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2csm.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2csm.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2csm.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2csm.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2csm.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2csm.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2csm.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2csm.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2css.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2css.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2css.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2css.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2css.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2css.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2css.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2css.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3uscib0i2css.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3uscib0i2css.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3usciuarttrcv.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3usciuarttrcv.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3usciuarttrcv.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3usciuarttrcv.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3usciuarttrcv.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3usciuarttrcv.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3usciuarttrcv.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3usciuarttrcv.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3usciuarttrcv.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3usciuarttrcv.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt01.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt01.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt01.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt01.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt01.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt01.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt01.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt01.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt01.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt01.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt02.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt02.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt02.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt02.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt02.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt02.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt02.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt02.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt02.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt02.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt04.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt04.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt04.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt04.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt04.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt04.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt04.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt04.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt04.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt04.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt05.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt05.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt05.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt05.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt05.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt05.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt05.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt05.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt05.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt05.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt06.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt06.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt06.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt06.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt06.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt06.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt06.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt06.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: msp430g2xx3wdt06.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: msp430g2xx3wdt06.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24l01p.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24l01p.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24l01p.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24l01p.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24l01p.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24l01p.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24l01pThermo.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24l01pThermo.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24l01pThermo.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24l01pThermo.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24l01pThermo.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24l01pThermo.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24pRelay.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24pRelay.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24pRelay.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24pRelay.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24pRelay.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24pRelay.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24pRelay.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24pRelay.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24pRelay.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24pRelay.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24pRelayTypes.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24pRelayTypes.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24pRelayTypes.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24pRelayTypes.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: nrf24pRelayTypes.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: nrf24pRelayTypes.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: objectformatv3.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: objectformatv3.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: objformat.txt
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: objformat.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: old.Modules.bin
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: old.Modules.bin
DEBUG: GetObjectInfo
DEBUG: PutFilename: pcd8544.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: pcd8544.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: pcd8544.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: pcd8544.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: pcd8544.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: pcd8544.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: pcd8544fonts.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: pcd8544fonts.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: preserveMSPFlash.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: preserveMSPFlash.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: preserveMSPFlash.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: preserveMSPFlash.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: preserveMSPFlash.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: preserveMSPFlash.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiary.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiary.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiary.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiary.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiary.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiary.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiary.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiary.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiary.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiary.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiary.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiary.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiaryTypes.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiaryTypes.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiaryTypes.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiaryTypes.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: sDiaryTypes.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: sDiaryTypes.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: screenshot59D922A6.bmp
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: screenshot59D922A6.bmp
DEBUG: GetObjectInfo
DEBUG: PutFilename: screenshotC0EE8696.bmp
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: screenshotC0EE8696.bmp
DEBUG: GetObjectInfo
DEBUG: PutFilename: stm32f429xx.h
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: stm32f429xx.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: stm32f429xx.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: stm32f429xx.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: stm32f4xxhaldma2d.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: stm32f4xxhaldma2d.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: tailSVC.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: tailSVC.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: tailSVC.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: tailSVC.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: tailSVC.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: tailSVC.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testASSERT.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testASSERT.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testASSERT.bin
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testASSERT.bin
DEBUG: GetObjectInfo
DEBUG: PutFilename: testASSERT.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testASSERT.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testASSERT.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testASSERT.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testASSERT.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testASSERT.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testASSERT.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testASSERT.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testArray.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testArray.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testArray.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testArray.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testArray.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testArray.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testArray.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testArray.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testArray.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testArray.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testArray.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testArray.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testArray.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testArray.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testAssert.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testAssert.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testAssert.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testAssert.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testAssert.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testAssert.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testAssert.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testAssert.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testAssert.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testAssert.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testAssert.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testAssert.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testAssert.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testAssert.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBIT.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBIT.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBIT.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBIT.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBIT.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBIT.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBIT.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBIT.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBIT.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBIT.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBSP.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBSP.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBSP.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBSP.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBSP.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBSP.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBSP.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBSP.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBSP.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBSP.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBigLocals.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBigLocals.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBigLocals.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBigLocals.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBigLocals.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBigLocals.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBootLoad.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBootLoad.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBootLoad.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBootLoad.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBootLoad.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBootLoad.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug2.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug3.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug3.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug3.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug3.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug3.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug3.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug4.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug4.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug4.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug4.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug5.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug5.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug5.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug5.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug5.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug5.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug5.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug5.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug5.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug5.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug5.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug5.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug5.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug5.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug6.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug6.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug6.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug6.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug6.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug6.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug6.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug6.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug6.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug6.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug6.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug6.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug6.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug6.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug6.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug6.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug7.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug7.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug7.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug7.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug7.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug7.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug7.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug7.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug7.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug7.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug7.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug7.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug7.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug7.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug8.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug8.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug8.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug8.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBug8.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBug8.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugByteToInt.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugByteToInt.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugByteToInt.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugByteToInt.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugByteToInt.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugByteToInt.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugByteToInt.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugByteToInt.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugByteToInt.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugByteToInt.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugByteToInt.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugByteToInt.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugByteToInt.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugByteToInt.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugExtArray.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugExtArray.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugExtArray.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugExtArray.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugExtArray.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugExtArray.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugIfFalse.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugIfFalse.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugIfFalse.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugIfFalse.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testBugIfFalse.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testBugIfFalse.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCRC32.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCRC32.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCRC32.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCRC32.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCRC32.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCRC32.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCRC32.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCRC32.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCRC32.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCRC32.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCond.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCond.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCond.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCond.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCond.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCond.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCond.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCond.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCond.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCond.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCond.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCond.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testCond.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testCond.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testD.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testD.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testD.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testD.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testD.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testD.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDMA.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDMA.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDMA.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDMA.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDMA.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDMA.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDMA.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDMA.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDMA.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDMA.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDMA.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDMA.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDeRef.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDeRef.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDeRef.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDeRef.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDeRef.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDeRef.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDeRef.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDeRef.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDeRef.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDeRef.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDeRef.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDeRef.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDeRef.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDeRef.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDelay.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDelay.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDelay.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDelay.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDelay.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDelay.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDelay.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDelay.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDelay.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDelay.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testDelay.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testDelay.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExcFrame.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExcFrame.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExcFrame.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExcFrame.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExcFrame.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExcFrame.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExcFrame.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExcFrame.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExport.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExport.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExport.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExport.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExport.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExport.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExport.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExport.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExport.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExport.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExport.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExport.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testExport.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testExport.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFLASH.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFLASH.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFLASH.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFLASH.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFLASH.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFLASH.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFLASH.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFLASH.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFLASH.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFLASH.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFMC.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFMC.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFMC.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFMC.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFMC.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFMC.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFor.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFor.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFor.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFor.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFor.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFor.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFor.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFor.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFor.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFor.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFor.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFor.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFor.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFor.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testForever.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testForever.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testForever.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testForever.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testForever.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testForever.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testForever.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testForever.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testForever.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testForever.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFrame.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFrame.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFrame.map
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFrame.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFrame.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFrame.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFrame.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFrame.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFrame.txt
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFrame.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.map
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testFunc2.txt
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testFunc2.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIN.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIN.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIN.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIN.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIN.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIN.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIN.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIN.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIN.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIN.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIRQ.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIRQ.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIRQ.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIRQ.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIRQ.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIRQ.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIfThen.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIfThen.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIfThen.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIfThen.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIfThen.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIfThen.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImport.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImport.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImport.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImport.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImport.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImport.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImport.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImport.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImport.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImport.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImport.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImport.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImport.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImport.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportString.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportString.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportStringM4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportStringM4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportStringM4.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportStringM4.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportStringM4.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportStringM4.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportStringM4.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportStringM4.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testImportStringM4.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testImportStringM4.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInEx.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInEx.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInEx.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInEx.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInEx.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInEx.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInEx.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInEx.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInEx.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInEx.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInEx.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInEx.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInEx.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInEx.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInc.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInc.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInc.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInc.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInc.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInc.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInc.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInc.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInc.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInc.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInc.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInc.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInc.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInc.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInit.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInit.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInit.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInit.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInit.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInit.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInitImp.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInitImp.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInitImp.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInitImp.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInitImp.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInitImp.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInitImp.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInitImp.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testInitImp.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testInitImp.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIntArith.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIntArith.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIntArith.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIntArith.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIntArith.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIntArith.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIntRelat.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIntRelat.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIntRelat.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIntRelat.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testIntRelat.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testIntRelat.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testItrfDef.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testItrfDef.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testItrfDef.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testItrfDef.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testItrfDef.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testItrfDef.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testItrfUse.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testItrfUse.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testItrfUse.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testItrfUse.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testItrfUse.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testItrfUse.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testJGC.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testJGC.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testJGC.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testJGC.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testJGC.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testJGC.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testJGC.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testJGC.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLdMod.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLdMod.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLdMod.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLdMod.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLdMod.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLdMod.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLdMod.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLdMod.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLdMod.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLdMod.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoad2.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoad2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoad2.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoad2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoad2.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoad2.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoad2.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoad2.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoad2.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoad2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoadAdr.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoadAdr.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoadAdr.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoadAdr.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoadAdr.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoadAdr.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoadAdr.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoadAdr.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoadAdr.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoadAdr.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoadAdr.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoadAdr.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLoadAdr.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLoadAdr.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongConst.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongConst.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongConst.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongConst.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongConst.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongConst.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongConst.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongConst.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongConst.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongConst.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongInt.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongInt.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongInt.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongInt.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongInt.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongInt.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongInt.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongInt.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testLongInt.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testLongInt.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMPU.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMPU.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMPU.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMPU.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMPU.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMPU.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMPU.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMPU.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMPU.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMPU.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMSR.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMSR.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMod.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMod.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMod.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMod.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMod.bin
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMod.bin
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMod.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMod.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMod.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMod.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMod.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMod.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMod.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMod.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMpack.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMpack.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMpack.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMpack.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testMpack.txt
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testMpack.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNbArgs.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNbArgs.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNbArgs.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNbArgs.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNbArgs.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNbArgs.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNeg.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNeg.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNeg.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNeg.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNeg.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNeg.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNeg.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNeg.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNeg.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNeg.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNeg.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNeg.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNeg.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNeg.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNew.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNew.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNew.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNew.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testNew.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testNew.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testOFSConfig.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testOFSConfig.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testOFSConfig.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testOFSConfig.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testOFSConfig.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testOFSConfig.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testObjv2.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testObjv2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testObjv2.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testObjv2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testObjv2.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testObjv2.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testObjv2.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testObjv2.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testObjv2.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testObjv2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPRU.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPRU.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPRU.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPRU.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPRU.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPRU.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPRU.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPRU.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPRU.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPRU.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPRU.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPRU.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPRU.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPRU.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPS2.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPS2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPS2.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPS2.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPS2.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPS2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPS2.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPS2.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPS2.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPS2.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPS2.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPS2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParam.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParam.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParam.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParam.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParam.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParam.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParam.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParam.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParam.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParam.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParam.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParam.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParam.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParam.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParamOM4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParamOM4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParamOM4.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParamOM4.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParamOM4.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParamOM4.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParamOM4.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParamOM4.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParamOM4.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParamOM4.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testParamOM4.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testParamOM4.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPendSV.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPendSV.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPendSV.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPendSV.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPendSV.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPendSV.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPointer.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPointer.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPointer.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPointer.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPointer.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPointer.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPointer.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPointer.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testPointer.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testPointer.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProc.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProc.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProc.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProc.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProc.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProc.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProc.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProc.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProc.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProc.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProc.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProc.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProc.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProc.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProcAdr.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProcAdr.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProcAdr.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProcAdr.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProcAdr.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProcAdr.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProcAdr.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProcAdr.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testProcAdr.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testProcAdr.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8M4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8M4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8M4.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8M4.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8M4.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8M4.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8M4.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8M4.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQMath8M4.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQMath8M4.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQuickSort.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQuickSort.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQuickSort.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQuickSort.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQuickSort.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQuickSort.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQuickSort.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQuickSort.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testQuickSort.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testQuickSort.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRAMcode.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRAMcode.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRAMcode.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRAMcode.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRAMcode.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRAMcode.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRAMcode.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRAMcode.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRAMcode.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRAMcode.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRBIT.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRBIT.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRBIT.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRBIT.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRBIT.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRBIT.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRS232.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRS232.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRS232.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRS232.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRS232.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRS232.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRS232.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRS232.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRS232.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRS232.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRWNum.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRWNum.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRWNum.data
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRWNum.data
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRWNum.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRWNum.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRWNum.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRWNum.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRWNum.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRWNum.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRWNum.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRWNum.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testReal.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testReal.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testReal.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testReal.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testReal.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testReal.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testReal.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testReal.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testReal.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testReal.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecStr.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecStr.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecStr.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecStr.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecStr.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecStr.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecord.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecord.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecord.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecord.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecord.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecord.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecord.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecord.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecord.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecord.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecord.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecord.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRecord.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRecord.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRegProtection.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRegProtection.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRegProtection.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRegProtection.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRegProtection.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRegProtection.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRegProtection.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRegProtection.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRegProtection.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRegProtection.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRegProtection.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRegProtection.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRepeat.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRepeat.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRepeat.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRepeat.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testRepeat.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testRepeat.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSDCard.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSDCard.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSDCard.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSDCard.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSDCard.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSDCard.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs2.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs2.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs2.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs2.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs2.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs3.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs3.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs3.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs3.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSFuncs3.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSFuncs3.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSProcs2.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSProcs2.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSQRT.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSQRT.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSQRT.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSQRT.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSW1.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSW1.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSW1.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSW1.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSW1.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSW1.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSW1.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSW1.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSW1.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSW1.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testScan.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testScan.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testScan.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testScan.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testScan.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testScan.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testScan.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testScan.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testScan.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testScan.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSelector.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSelector.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSelector.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSelector.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSelector.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSelector.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSelector.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSelector.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSelector.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSelector.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSelector.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSelector.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSelector.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSelector.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSet.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSet.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSet.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSet.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSet.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSet.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSqrt.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSqrt.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStore.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStore.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStore.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStore.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStore.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStore.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStore.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStore.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStore.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStore.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStore.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStore.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStore.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStore.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testString.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testString.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStringRelat.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStringRelat.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStringRelat.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStringRelat.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStringRelat.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStringRelat.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStringRelat.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStringRelat.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStringRelat.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStringRelat.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStringRelat.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStringRelat.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testStringRelat.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testStringRelat.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSyntax.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSyntax.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSyntax.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSyntax.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSyntax.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSyntax.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSyntax.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSyntax.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testSyntax.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testSyntax.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap.Mod.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap.Mod.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap1.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap1.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap1.mpc
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap1.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap1.sms
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap1.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTrap1.txt
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTrap1.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testTypTag.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testTypTag.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testULDiv.Mod
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testULDiv.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testULDiv.m4c
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testULDiv.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testULDiv.osm
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testULDiv.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testULDiv.rao
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testULDiv.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testULDiv.sm4
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testULDiv.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testUSB.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testUSB.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testUSB.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testUSB.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testUSB.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testUSB.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testUSB.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testUSB.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testUSB.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testUSB.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVar.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVar.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVar.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVar.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVar.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVar.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVar.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVar.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVar.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVar.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVarParam.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVarParam.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVarParam.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVarParam.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVarParam.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVarParam.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVector.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVector.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVector.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVector.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVector.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVector.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVector.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVector.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testVector.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testVector.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testhalc.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testhalc.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testhalc.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testhalc.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testhalc.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testhalc.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testhalc.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testhalc.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmn.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmn.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmn.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmn.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmn.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmn.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmn.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmn.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmnM4.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmnM4.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmnM4.m4c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmnM4.m4c
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmnM4.osm
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmnM4.osm
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmnM4.rao
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmnM4.rao
DEBUG: GetObjectInfo
DEBUG: PutFilename: testjsmnM4.sm4
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testjsmnM4.sm4
DEBUG: GetObjectInfo
DEBUG: PutFilename: testpcd8544.Mod
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testpcd8544.Mod
DEBUG: GetObjectInfo
DEBUG: PutFilename: testpcd8544.map
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testpcd8544.map
DEBUG: GetObjectInfo
DEBUG: PutFilename: testpcd8544.mpc
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testpcd8544.mpc
DEBUG: GetObjectInfo
DEBUG: PutFilename: testpcd8544.sms
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testpcd8544.sms
DEBUG: GetObjectInfo
DEBUG: PutFilename: testpcd8544.txt
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: testpcd8544.txt
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdconf.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdconf.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdconf.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdconf.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdconf.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdconf.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdcore.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdcore.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdcore.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdcore.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdctlreq.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdctlreq.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdctlreq.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdctlreq.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbddef.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbddef.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbddef.h.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbddef.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbddesc.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbddesc.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbddesc.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbddesc.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdioreq.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdioreq.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdioreq.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdioreq.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtp.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtp.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtp.c.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtp.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtp.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtp.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtp.h.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtp.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtpiftemplate.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtpiftemplate.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtpiftemplate.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtpiftemplate.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtpopt.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtpopt.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtpopt.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtpopt.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtpopt.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtpopt.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtpopt.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtpopt.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtpstorage.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtpstorage.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbdmtpstorage.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbdmtpstorage.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhconf.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhconf.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhconf.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhconf.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhconf.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhconf.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhcore.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhcore.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhcore.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhcore.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhcore.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhcore.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhcore.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhcore.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhctlreq.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhctlreq.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhctlreq.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhctlreq.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhdef.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhdef.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhdef.h.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhdef.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhid.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhid.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhid.c.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhid.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhid.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhid.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhid.h.Bak
DEBUG: buf lentgth is multiple of 64
DEBUG: DataInStage: Zero Length Packet is needed
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhid.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidkeybd.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidkeybd.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidkeybd.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidkeybd.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidkeybd.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidkeybd.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidkeybd.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidkeybd.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidmouse.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidmouse.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidmouse.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidmouse.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidmouse.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidmouse.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidparser.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidparser.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidparser.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidparser.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidparser.h
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidparser.h
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhhidparser.h.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhhidparser.h.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhioreq.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhioreq.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhioreq.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhioreq.c.Bak
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhpipes.c
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhpipes.c
DEBUG: GetObjectInfo
DEBUG: PutFilename: usbhpipes.c.Bak
DEBUG: GetObjectPropsList
DEBUG: PutOPL: file name: usbhpipes.c.Bak
DEBUG: Close session
DEBUG: Core  D07758C8 unregistered
DEBUG: USB system stopped.
