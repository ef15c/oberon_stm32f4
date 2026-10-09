MODULE USBDMTPDesc;
  (** USB device descriptors, ported to Oberon from:
  * @author  MCD Application Team
  * @brief   This file provides the USBD descriptors and string formatting method.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2017 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  *)
  IMPORT SYSTEM, Conf := USBDConf, Def := USBDef, DDef := USBDDef, CtlReq := USBDCtlReq;

  CONST VID = 0483H; PID = 0105H;
    LANGID_STRING = 409H;
    MANUFACTURER_STRING = "STMicroelectronics";
    PRODUCT_HS_STRING = "Oberon MTP in HS Mode";
    PRODUCT_FS_STRING = "Oberon MTP in FS Mode";
    CONFIGURATION_HS_STRING = "MTP Config";
    INTERFACE_HS_STRING = "MTP Interface";
    CONFIGURATION_FS_STRING = "MTP Config";
    INTERFACE_FS_STRING = "MTP Interface";

  VAR Descriptors*: Def.DescriptorGetters;
    DevDsc, LangIDDesc: Def.RawDescriptor;

  (**
  * @brief  Returns the device descriptor. 
  * @param  speed: Current device speed
  * @retval Pointer to descriptor buffer
  *)
  PROCEDURE DeviceDescriptor(speed: BYTE): Def.Buffer;
 
    RETURN DevDsc
  END DeviceDescriptor;

  (**
  * @brief  Returns the LangID string descriptor.        
  * @param  speed: Current device speed
  * @retval Pointer to descriptor buffer
  *)
  PROCEDURE LangIDStrDescriptor(speed: BYTE): Def.Buffer;

    RETURN LangIDDesc
  END LangIDStrDescriptor;

  PROCEDURE GetString(desc: ARRAY OF CHAR): Def.RawDescriptor;
    VAR u!: Def.RawDescriptor;
  BEGIN u := Def.NewRawDescriptor(); CtlReq.GetString(desc, u.buf, u.length)    

    RETURN u
  END GetString;

  (**
  * @brief  Returns the product string descriptor. 
  * @param  speed: Current device speed
  * @retval Pointer to descriptor buffer
  *)
  PROCEDURE ProductStrDescriptor(speed: BYTE): Def.Buffer;
    VAR StrDesc!: Def.RawDescriptor;
  BEGIN 
    IF speed = Def.SPEED_HIGH THEN StrDesc := GetString(PRODUCT_HS_STRING)
    ELSE StrDesc := GetString(PRODUCT_FS_STRING)
    END    

    RETURN StrDesc
  END ProductStrDescriptor;

  (**
  * @brief  Returns the manufacturer string descriptor. 
  * @param  speed: Current device speed
  * @retval Pointer to descriptor buffer
  *)
  PROCEDURE ManufacturerStrDescriptor(speed: BYTE): Def.Buffer;
  BEGIN

    RETURN GetString(MANUFACTURER_STRING)
  END ManufacturerStrDescriptor;

  (**
  * @brief  Returns the serial number string descriptor.        
  * @param  speed: Current device speed
  * @retval Pointer to descriptor buffer
  *)
  PROCEDURE SerialStrDescriptor(speed: BYTE): Def.Buffer;
  (*TODO: Use UId*)

    RETURN GetString("Ob001")
  END SerialStrDescriptor;

  (**
  * @brief  Returns the configuration string descriptor.    
  * @param  speed: Current device speed
  * @retval Pointer to descriptor buffer
  *)
  PROCEDURE ConfigStrDescriptor(speed: BYTE): Def.Buffer;
    VAR StrDesc!: Def.RawDescriptor;
  BEGIN 
    IF speed = Def.SPEED_HIGH THEN StrDesc := GetString(CONFIGURATION_HS_STRING)
    ELSE StrDesc := GetString(CONFIGURATION_FS_STRING)
    END    

    RETURN StrDesc
  END ConfigStrDescriptor;

  (**
  * @brief  Returns the interface string descriptor.        
  * @param  speed: Current device speed
  * @retval Pointer to descriptor buffer
  *)
  PROCEDURE InterfaceStrDescriptor(speed: BYTE): Def.Buffer;
    VAR StrDesc!: Def.RawDescriptor;
  BEGIN 
    IF speed = Def.SPEED_HIGH THEN StrDesc := GetString(INTERFACE_HS_STRING)
    ELSE StrDesc := GetString(INTERFACE_FS_STRING)
    END    

    RETURN StrDesc
  END InterfaceStrDescriptor;

  PROCEDURE Init;
    VAR d!: DDef.DescriptorGetters;
  BEGIN NEW(d);
    d.GetDeviceDescriptor := DeviceDescriptor;
    d.GetLangIDStrDescriptor := LangIDStrDescriptor;
    d.GetManufacturerStrDescriptor := ManufacturerStrDescriptor;
    d.GetProductStrDescriptor := ProductStrDescriptor;
    d.GetSerialStrDescriptor := SerialStrDescriptor;
    d.GetConfigurationStrDescriptor := ConfigStrDescriptor;
    d.GetInterfaceStrDescriptor := InterfaceStrDescriptor;
    Descriptors := d
  END Init;

BEGIN Init;
  DevDsc := Def.NewRawDescriptor();
  Def.PutByte(DevDsc, 12H); (* bLength *)
  Def.PutByte(DevDsc, Def.DESC_TYPE_DEVICE); (* bDescriptorType *)
  Def.PutHalfword(DevDsc, 200H); (* bcdUSB *)
  Def.PutByte(DevDsc, 0); (* bDeviceClass *)
  Def.PutByte(DevDsc, 0); (* bDeviceSubClass *)
  Def.PutByte(DevDsc, 0); (* bDeviceProtocol *)
  Def.PutByte(DevDsc, Def.MAX_EP0_SIZE); (* bMaxPacketSize *)
  Def.PutHalfword(DevDsc, VID); (* idVendor *)
  Def.PutHalfword(DevDsc, PID); (* idProduct *)
  Def.PutHalfword(DevDsc, 100H); (* bcdDevice rel. 1.00 *)
  Def.PutByte(DevDsc, DDef.IDX_MFC_STR); (* Index of manufacturer string *)
  Def.PutByte(DevDsc, DDef.IDX_PRODUCT_STR); (* Index of product string *)
  Def.PutByte(DevDsc, DDef.IDX_SERIAL_STR); (* Index of serial number string *)
  Def.PutByte(DevDsc, Conf.MAX_NUM_CONFIGURATION); (* bNumConfigurations *)

  LangIDDesc := Def.NewRawDescriptor();
  Def.PutByte(LangIDDesc, Def.LEN_LANGID_STR_DESC);
  Def.PutByte(LangIDDesc, Def.DESC_TYPE_STRING);
  Def.PutHalfword(LangIDDesc, LANGID_STRING)
END USBDMTPDesc.
