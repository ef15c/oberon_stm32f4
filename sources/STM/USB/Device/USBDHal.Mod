MODULE USBDHal; (*The BSP part of USB Device Controller configuration, C. Schoffit*)
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   The HAL part of USB Host configuration file.
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
  IMPORT Def := USBDef, ll := LLUSB, UC := HALUC, PCD := HALPCD, DCore := USBDCore;

  VAR OldHandler: UC.IRQHandlerProc;

  (*******************************************************************************
                       LL Driver Callbacks (PCD -> USB Device Library)
  *******************************************************************************)

  (**
  * @brief  SetupStage callback.
  * @param  hpcd: PCD handle
  * @retval None
  *)
  PROCEDURE SetupStageCallback(hpcd: PCD.Handle);
  BEGIN DCore.SetupStage(hpcd, hpcd.Setup)
  END SetupStageCallback;

 (**
  * @brief  DataOut Stage callback.
  * @param  hpcd: PCD handle
  * @param  epnum: Endpoint Number
  * @retval None
  *)
  PROCEDURE DataOutStageCallback(hpcd: PCD.Handle; epnum: BYTE);
  BEGIN DCore.DataOutStage(hpcd, epnum)
  END DataOutStageCallback;

  (**
  * @brief  DataIn Stage callback.
  * @param  hpcd: PCD handle
  * @param  epnum: Endpoint Number
  * @retval None
  *)
  PROCEDURE DataInStageCallback(hpcd: PCD.Handle; epnum: BYTE);
  BEGIN DCore.DataInStage(hpcd, epnum)
  END DataInStageCallback;

  (**
  * @brief  SOF callback.
  * @param  hpcd: PCD handle
  * @retval None
  *)
  PROCEDURE SOFCallback(hpcd: PCD.Handle);
  BEGIN DCore.SOF(hpcd)
  END SOFCallback;

  (**
  * @brief  Reset callback.
  * @param  hpcd: PCD handle
  * @retval None
  *)
  PROCEDURE ResetCallback(hpcd: PCD.Handle);
    VAR speed: BYTE;
  BEGIN
    (* Set USB Current Speed *)
    IF hpcd.Init.speed = PCD.SPEED_HIGH THEN speed := Def.SPEED_HIGH
    ELSIF hpcd.Init.speed = PCD.SPEED_FULL THEN speed := Def.SPEED_FULL
    ELSE speed := Def.SPEED_FULL
    END;
    (* Reset Device *)
    DCore.Reset(hpcd); DCore.SetSpeed(hpcd, speed)
  END ResetCallback;

  (**
  * @brief  Suspend callback.
  * @param  hpcd: PCD handle
  * @retval None
  *)
  PROCEDURE SuspendCallback(hpcd: PCD.Handle);
  BEGIN DCore.Suspend(hpcd)
  END SuspendCallback;

  (**
  * @brief  Resume callback.
  * @param  hpcd: PCD handle
  * @retval None
  *)
  PROCEDURE ResumeCallback(hpcd: PCD.Handle);
  BEGIN DCore.Resume(hpcd)
  END ResumeCallback;

  (**
  * @brief  ISOOUTIncomplete callback.
  * @param  hpcd: PCD handle 
  * @param  epnum: Endpoint Number
  * @retval None
  *)
  PROCEDURE ISOOUTIncompleteCallback(hpcd: PCD.Handle; epnum: BYTE);
  BEGIN DCore.IsoOUTIncomplete(hpcd, epnum)
  END ISOOUTIncompleteCallback;

  (**
  * @brief  ISOINIncomplete callback.
  * @param  hpcd: PCD handle 
  * @param  epnum: Endpoint Number
  * @retval None
  *)
  PROCEDURE ISOINIncompleteCallback(hpcd: PCD.Handle; epnum: BYTE);
  BEGIN DCore.IsoINIncomplete(hpcd, epnum)
  END ISOINIncompleteCallback;

  (**
  * @brief  ConnectCallback callback.
  * @param  hpcd: PCD handle
  * @retval None
  *)
  PROCEDURE ConnectCallback(hpcd: PCD.Handle);
  BEGIN DCore.DevConnected(hpcd)
  END ConnectCallback;

  (**
  * @brief  Disconnect callback.
  * @param  hpcd: PCD handle
  * @retval None
  *)
  PROCEDURE DisconnectCallback(hpcd: PCD.Handle);
  BEGIN DCore.DevDisconnected(hpcd)
  END DisconnectCallback;

(*******************************************************************************
                       LL Driver Interface (USB Device Library --> PCD)
*******************************************************************************)

  (**
  * @brief  Initializes the Low Level portion of the Device driver.
  * @param  core: Core handle
  * @retval Device handle
  *)
  PROCEDURE Init*(core: Def.Handle; id: BYTE): PCD.Handle;
    VAR dev!: PCD.Handle; tmp!: UC.Handle;
  BEGIN
    CASE core OF
      PCD.Handle: dev := core
    | UC.Handle: dev := PCD.New(); PCD.InitPools(dev); tmp := dev; tmp^ := core^; Def.Update(dev, id)
    | Def.Handle: ASSERT(FALSE)
    END;
    dev.SOFCallback := SOFCallback;
    dev.SetupStageCallback := SetupStageCallback;
    dev.ResetCallback := ResetCallback;
    dev.SuspendCallback := SuspendCallback;
    dev.ResumeCallback := ResumeCallback;
    dev.ConnectCallback := ConnectCallback;
    dev.DisconnectCallback := DisconnectCallback;
    dev.DataOutStageCallback := DataOutStageCallback;
    dev.DataInStageCallback := DataInStageCallback;
    dev.ISOOUTIncompleteCallback := ISOOUTIncompleteCallback;
    dev.ISOINIncompleteCallback := ISOINIncompleteCallback;
    dev.LPMCallback := NIL;
    dev.BCDCallback := NIL;
    dev.useUsbHS := FALSE;
    (* Set LL Driver parameters *)
    dev.Init.dev_endpoints := 4;
    dev.Init.use_dedicated_ep1 := FALSE;
    dev.Init.Sof_enable := FALSE;
    dev.Init.speed := PCD.SPEED_FULL;
    dev.Init.vbus_sensing_enable := TRUE;
    dev.Init.lpm_enable := FALSE;
    OldHandler := dev.ControllerIRQHandler; dev.ControllerIRQHandler := PCD.IRQHandler;
    (*Oberon specific callbacks*)
    (* Initialize LL Driver *)
    IF PCD.Init(dev) # ll.HAL_OK THEN dev := NIL
    ELSE PCD.SetRxFiFo(dev, 0A0H); PCD.SetTxFiFo(dev, 0, 0A0H)
    END

    RETURN dev
  END Init;

  (**
  * @brief  Starts the Low Level portion of the Device driver. 
  * @param  pdev: Device handle
  * @retval USBD Status
  *)
  PROCEDURE Start*(dev: Def.Handle);
  BEGIN PCD.Start(dev(PCD.Handle))
  END Start;

  (**
  * @brief  Opens an endpoint of the Low Level Driver.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @param  ep_type: Endpoint Type
  * @param  ep_mps: Endpoint Max Packet Size
  * @retval USBD Status
  *)
  PROCEDURE OpenEP*(dev: Def.Handle; ep_addr, ep_type: BYTE; ep_mps: HALFWORD);
  BEGIN PCD.EP_Open(dev(PCD.Handle), ep_addr, ep_mps, ep_type)
  END OpenEP;  

  (**
  * @brief  Closes an endpoint of the Low Level Driver.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @retval USBD Status
  *)
  PROCEDURE CloseEP*(dev: Def.Handle; ep_addr: BYTE);
  BEGIN PCD.EP_Close(dev(PCD.Handle), ep_addr)
  END CloseEP;

  (**
  * @brief  Transmits data over an endpoint.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @param  pbuf: Pointer to data to be sent
  * @retval USBD Status
  *)
  PROCEDURE Transmit*(dev: Def.Handle; ep_addr: BYTE; buf: Def.Buffer);
  BEGIN PCD.EP_Transmit(dev(PCD.Handle), ep_addr, buf)
  END Transmit;

END USBDHal.
