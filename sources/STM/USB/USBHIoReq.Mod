MODULE USBHIoReq;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   This file handles the issuing of the USB transactions
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2015 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  *)
  IMPORT Def := USBDef, HDef := USBHDef;

  CONST
    PID_SETUP* = 0;
    PID_DATA* = 1;

    EP_CONTROL* = 0;
    EP_ISO* = 1;
    EP_BULK* = 2;
    EP_INTERRUPT* = 3;

    SETUP_PKT_SIZE* = 8;

  (**
  * @brief  USBH_CtlSendSetup
  *         Sends the Setup Packet to the Device
  * @param  phost: Host Handle
  * @param  buff: Buffer pointer from which the Data will be send to Device
  * @param  pipe_num: Pipe Number
  * @retval USBH Status
  *)
  PROCEDURE CtlSendSetup*(host: HDef.Handle; buff: HDef.Setup; pipe_num: BYTE);
  BEGIN
    host.SubmitURB(host, (* Driver handle    *)
      pipe_num, (* Pipe index       *)
      FALSE, (* Direction : OUT  *)
      EP_CONTROL, (* EP type          *)
      PID_SETUP, (* Type setup       *)
      buff, (* data buffer      *)
      SETUP_PKT_SIZE, (* data length      *)
      FALSE)
  END CtlSendSetup;

  (**
  * @brief  USBH_CtlSendData
  *         Sends a data Packet to the Device
  * @param  phost: Host Handle
  * @param  buff: Buffer pointer from which the Data will be sent to Device
  * @param  length: Length of the data to be sent
  * @param  pipe_num: Pipe Number
  * @retval USBH Status
  *)
  PROCEDURE CtlSendData*(host: HDef.Handle; buff: Def.Buffer; length: HALFWORD; pipe_num: BYTE; do_ping: BOOLEAN);
  BEGIN IF host.device.speed # Def.SPEED_HIGH THEN do_ping := FALSE END;
    host.SubmitURB(host, (* Driver handle    *)
                          pipe_num, (* Pipe index       *)
                          FALSE, (* Direction : OUT  *)
                          EP_CONTROL, (* EP type          *)
                          PID_DATA, (* Type Data        *)
                          buff, (* data buffer      *)
                          length, (* data length      *)
                          do_ping) (* do ping (HS Only)*)
  END CtlSendData;

  (**
  * @brief  USBH_CtlReceiveData
  *         Receives the Device Response to the Setup Packet
  * @param  phost: Host Handle
  * @param  buff: Buffer pointer in which the response needs to be copied
  * @param  length: Length of the data to be received
  * @param  pipe_num: Pipe Number
  * @retval USBH Status.
  *)
  PROCEDURE CtlReceiveData*(host: HDef.Handle; VAR buff: Def.Buffer; length: HALFWORD; pipe_num: BYTE);
  BEGIN
    host.SubmitURB(host, (* Driver handle    *)
      pipe_num, (* Pipe index       *)
      TRUE, (* Direction : IN   *)
      EP_CONTROL, (* EP type          *)
      PID_DATA, (* Type Data        *)
      buff, (* data buffer      *)
      length, (* data length      *)
      FALSE)
  END CtlReceiveData;

  (**
  * @brief  USBH_InterruptReceiveData
  *         Receives the Device Response to the Interrupt IN token
  * @param  phost: Host Handle
  * @param  buff: Buffer pointer in which the response needs to be copied
  * @param  length: Length of the data to be received
  * @param  pipe_num: Pipe Number
  * @retval USBH Status.
  *)
  PROCEDURE InterruptReceiveData*(host: HDef.Handle; VAR buff: Def.Buffer; length, pipe_num: BYTE);
  BEGIN
    host.SubmitURB(host, (* Driver handle    *)
                          pipe_num, (* Pipe index       *)
                          TRUE, (* Direction : IN   *)
                          EP_INTERRUPT, (* EP type          *)
                          PID_DATA, (* Type Data        *)
                          buff, (* data buffer      *)
                          length, (* data length      *)
                          FALSE)
  END InterruptReceiveData;

END USBHIoReq.
