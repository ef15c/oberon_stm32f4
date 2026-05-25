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
  IMPORT Conf := USBHConf, Def := USBHDef, Pipes := USBHPipes;

  (**
  * @brief  USBH_LL_SetTimer
  *         Set the initial Host Timer tick
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE SetTimer*(phost: Def.Handle; time: INTEGER);
  BEGIN phost.Timer := time
  END SetTimer;

  (**
  * @brief  USBH_HandleSof
  *         Call SOF process
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE HandleSof(phost: Def.Handle);
    VAR res: BYTE;
  BEGIN
    IF (phost.gState = Def.HOST_CLASS) & (phost.pActiveClass # NIL) THEN
     res := phost.pActiveClass.SOFProcess(phost)
    END
  END HandleSof;

  (**
  * @brief  USBH_LL_IncTimer
  *         Increment Host Timer tick
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE IncTimer*(phost: Def.Handle);
  BEGIN INC(phost.Timer); HandleSof(phost)
  END IncTimer;

  (**
  * @brief  USBH_LL_Connect
  *         Handle USB Host connection event
  * @param  phost: Host Handle
  * @retval USBH_Status
  *)
  PROCEDURE Connect*(phost: Def.Handle);
  BEGIN phost.device.is_connected := TRUE;
    phost.device.is_disconnected := FALSE;
    phost.device.is_ReEnumerated := FALSE;
  END Connect;

  (**
  * @brief  USBH_LL_Disconnect
  *         Handle USB Host disconnection event
  * @param  phost: Host Handle
  * @retval USBH_Status
  *)
  PROCEDURE Disconnect*(phost: Def.Handle);
    VAR res: BYTE;
  BEGIN (* update device connection states *)
    phost.device.is_disconnected := TRUE;
    phost.device.is_connected := FALSE;
    phost.device.PortEnabled := FALSE;
    res := phost.Stop(phost); (* Stop Host *)
    (* Free Control Pipes *)
    Pipes.Free(phost, phost.Control.pipe_in);
    Pipes.Free(phost, phost.Control.pipe_out);
  END Disconnect;

  (**
  * @brief  USBH_PortEnabled
  *         Port Enabled
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE PortEnabled*(phost: Def.Handle);
  BEGIN phost.device.PortEnabled := FALSE
  END PortEnabled;

  (**
  * @brief  USBH_LL_PortDisabled
  *         Port Disabled
  * @param  phost: Host Handle
  * @retval None
  *)
  PROCEDURE PortDisabled*(phost: Def.Handle);
  BEGIN phost.device.PortEnabled := FALSE;
    phost.device.is_disconnected := TRUE;
  END PortDisabled;

END USBHCore.
