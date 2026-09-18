MODULE USBHCore;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   This file implements the functions for the core state machine process
  *          the enumeration and the control transfer process
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
  IMPORT Conf := USBHConf, HDef := USBHDef, Pipes := USBHPipes;

  (**
  * @brief  USBH_LL_SetTimer
  *         Set the initial Host Timer tick
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE SetTimer*(host: HDef.Handle; time: INTEGER);
  BEGIN host.Timer := time
  END SetTimer;

  (**
  * @brief  USBH_HandleSof
  *         Call SOF process
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE HandleSof(host: HDef.Handle);
    VAR res: BYTE;
  BEGIN
    IF (host.gState = HDef.HOST_CLASS) & (host.ActiveClass # NIL) THEN
     res := host.ActiveClass.SOFProcess(host)
    END
  END HandleSof;

  (**
  * @brief  USBH_LL_IncTimer
  *         Increment Host Timer tick
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE IncTimer*(host: HDef.Handle);
  BEGIN INC(host.Timer); HandleSof(host)
  END IncTimer;

  (**
  * @brief  USBH_LL_Connect
  *         Handle USB Host connection event
  * @param  phost: Host Handle
  * @retval USBH_Status
  *)
  PROCEDURE Connect*(host: HDef.Handle);
  BEGIN host.device.is_connected := TRUE;
    host.device.is_disconnected := FALSE;
    host.device.is_ReEnumerated := FALSE;
  END Connect;

  (**
  * @brief  USBH_LL_Disconnect
  *         Handle USB Host disconnection event
  * @param  phost: Host Handle
  * @retval USBH_Status
  *)
  PROCEDURE Disconnect*(host: HDef.Handle);
  BEGIN (* update device connection states *)
    host.device.is_disconnected := TRUE;
    host.device.is_connected := FALSE;
    host.device.PortEnabled := FALSE;
(*    host.Stop(host); (* Stop Host *)*)
    (* Free Control Pipes *)
    Pipes.Free(host, host.Control.pipe_in);
    Pipes.Free(host, host.Control.pipe_out);
  END Disconnect;

  (**
  * @brief  USBH_PortEnabled
  *         Port Enabled
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE PortEnabled*(host: HDef.Handle);
  BEGIN host.device.PortEnabled := TRUE
  END PortEnabled;

  (**
  * @brief  USBH_LL_PortDisabled
  *         Port Disabled
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE PortDisabled*(host: HDef.Handle);
  BEGIN host.device.PortEnabled := FALSE;
    host.device.is_disconnected := TRUE;
  END PortDisabled;

END USBHCore.
