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
  IMPORT SYSTEM, Def := USBDef, Log := USBLog, ll := LLUSB, Q := Queue, UC := HALUC, DDef := USBDDef, PCD := HALPCD, DCore := USBDCore;

  VAR OldHandler: UC.IRQHandlerProc;

  (*******************************************************************************
                       LL Driver Callbacks (PCD -> USB Device Library)
  *******************************************************************************)

  (**
  * @brief  SetupStage callback.
  * @param  hpcd: PCD handle
  * @retval None
  *)
  PROCEDURE SetupStageCallback(hpcd: DDef.Handle);
  BEGIN
    CASE hpcd OF
      PCD.Handle:
        DCore.SetupStage(hpcd, hpcd.Setup);
        PCD.Post_OutSetupPacket_int(hpcd)
    | DDef.Handle: ASSERT(FALSE)
    END
  END SetupStageCallback;

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
  BEGIN (* Set USB Current Speed *)
    IF hpcd.Init.speed = PCD.SPEED_HIGH THEN speed := Def.SPEED_HIGH
    ELSIF hpcd.Init.speed = PCD.SPEED_FULL THEN speed := Def.SPEED_FULL
    ELSE speed := Def.SPEED_FULL
    END;
    (* Reset Device *)
    DCore.Reset(hpcd); DCore.SetSpeed(hpcd, speed)
  END ResetCallback;

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
  * @brief  Starts the Low Level portion of the Device driver. 
  * @param  pdev: Device handle
  * @retval USBD Status
  *)
  PROCEDURE Start*(dev: Def.Handle);
  BEGIN PCD.Start(dev(PCD.Handle))
  END Start;

  (**
  * @brief  Stops the Low Level portion of the Device driver.
  * @param  pdev: Device handle
  * @retval USBD Status
  *)
  PROCEDURE Stop*(dev: Def.Handle);
  BEGIN PCD.Stop(dev(PCD.Handle))
  END Stop;

  (**
  * @brief  Opens an endpoint of the Low Level Driver.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @param  ep_type: Endpoint Type
  * @param  ep_mps: Endpoint Max Packet Size
  * @retval USBD Status
  *)
  PROCEDURE OpenEP*(dev: DDef.Handle; ep_addr, ep_type: BYTE; ep_mps: HALFWORD);
  BEGIN PCD.EP_Open(dev(PCD.Handle), ep_addr, ep_mps, ep_type)
  END OpenEP;  

  (**
  * @brief  Enables or disables the automatic ZLP insertion feature.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @param  autoZLP: TRUE for enabling, FLASE for disabling
  *)
  PROCEDURE SetEPAutoZLP*(dev: DDef.Handle; ep_addr: BYTE; autoZLP: BOOLEAN);
  BEGIN PCD.EP_SetAutoZLP(dev(PCD.Handle), ep_addr, autoZLP)
  END SetEPAutoZLP;  

  (**
  * @brief  Closes an endpoint of the Low Level Driver.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @retval USBD Status
  *)
  PROCEDURE CloseEP*(dev: DDef.Handle; ep_addr: BYTE);
  BEGIN PCD.EP_Close(dev(PCD.Handle), ep_addr)
  END CloseEP;

  (**
  * @brief  Sets a Stall condition on an endpoint of the Low Level Driver.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @retval USBD Status
  *)
  PROCEDURE StallEP(dev: DDef.Handle; ep_addr: BYTE);
    VAR ret: BYTE;
  BEGIN ret := PCD.EP_SetStall(dev(PCD.Handle), ep_addr)
  END StallEP;

  (**
  * @brief  Assigns a USB address to the device.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @retval USBD Status
  *)
  PROCEDURE SetUSBAddress(dev: DDef.Handle; dev_addr: BYTE);
  BEGIN PCD.SetAddress(dev(PCD.Handle), dev_addr)
  END SetUSBAddress;

  (**
  * @brief  Returns Stall condition.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @retval TRUE: EP stalled, FALSE: EP not stalled
  *)
  PROCEDURE IsStallEP(hpcd: DDef.Handle; ep_addr: BYTE): BOOLEAN;
    VAR ret: BOOLEAN;
  BEGIN
    CASE hpcd OF
      PCD.Handle:
        IF 7 IN TOSET(ep_addr) THEN  ret := hpcd.IN_ep[ep_addr MOD 10H].is_stall
        ELSE ret := hpcd.OUT_ep[ep_addr MOD 10].is_stall
        END
      | DDef.Handle: ASSERT(FALSE)
    END
    RETURN ret
  END IsStallEP;

  (**
  * @brief  Transmits data over an endpoint.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @param  pbuf: Pointer to data to be sent
  * @param  len: number of bytes to be sent
  * @retval USBD Status
  *)
  PROCEDURE Transmit*(dev: DDef.Handle; ep_addr: BYTE; buf: Def.BufferDesc; len: HALFWORD);
  BEGIN PCD.EP_Transmit(dev(PCD.Handle), ep_addr, buf, len)
  END Transmit;

  (**
  * @brief  Prepares an endpoint for reception.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @param  pbuf: Pointer to data to be received
  * @retval USBD Status
  *)
  PROCEDURE PrepareReceive(dev: DDef.Handle; ep_addr: BYTE; buf: Def.BufferDesc);
  BEGIN PCD.EP_Receive(dev(PCD.Handle), ep_addr, buf)
  END PrepareReceive;

  (**
  * @brief  Returns the last transferred packet size.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @retval Received Data Size
  *)
  PROCEDURE GetRxDataSize*(dev: DDef.Handle; ep_addr: BYTE): INTEGER;
    RETURN PCD.EP_GetRxCount(dev(PCD.Handle), ep_addr)
  END GetRxDataSize;

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
    dev.StallEP := StallEP;
(*TODO*)
    dev.ClearStallEP := NIL;
    dev.SetUSBAddress := SetUSBAddress;
    dev.IsStallEP := IsStallEP;
    dev.Transmit := Transmit;
    dev.SetClassConfig := DCore.SetClassConfig;
    dev.ClrClassConfig := NIL;
    dev.CoreFindIF := DCore.CoreFindIF;
    dev.CoreFindEP := DCore.CoreFindEP;
    dev.PrepareReceive := PrepareReceive;
    dev.OpenEP := OpenEP;
    dev.GetRxDataSize := GetRxDataSize;

    (* Initialize LL Driver *)
    IF PCD.Init(dev) # ll.HAL_OK THEN dev := NIL
    ELSE PCD.SetRxFiFo(dev, 80H); PCD.SetTxFiFo(dev, 0, 40H);
      PCD.SetTxFiFo(dev, 1, 80H); PCD.SetTxFiFo(dev, 2, 40H)
    END

    RETURN dev
  END Init;

  (**
  * @brief  De-Initializes the Low Level portion of the Device driver.
  * @param  pdev: Device handle
  * @retval USBD Status
  *)
  PROCEDURE DeInit*(dev: DDef.Handle);
  BEGIN PCD.DeInit(dev(PCD.Handle))
  END DeInit;

  PROCEDURE IRQLog(msg: PCD.Msg);
  BEGIN
    IF msg.epnum # 0 THEN (*discard EP0 messages since EP0 seems working well now*)
      Log.Debug("["); Log.DebugInt(msg.time, 12); Log.DebugInt(msg.ts, 12); Log.DebugString("] ");
      Log.DebugString("IRQ gintsts: ");  Log.DebugSet(msg.gintsts);
      IF msg.epnum # 255 THEN Log.DebugString(", ep "); Log.DebugInt(msg.epnum, 3);
        IF msg.is_in THEN Log.DebugString(", diepint: ") ELSE Log.DebugString(", doepint: ") END;
        Log.DebugSet(msg.dxepint)
      END;
      Log.DebugLn
    END
  END IRQLog;

  (**
  * @brief  Do the work offloaded by IRQs in the process loop.
  *)
 PROCEDURE ProcessDeferredIRQWork*(dev: Def.Handle);
    VAR msg!: Q.Msg; hmsg!: PCD.Msg;
  BEGIN
    CASE dev OF
      PCD.Handle:
        msg := PCD.TakeMsg(dev);
        WHILE msg # NIL DO (*Process the message*)
          hmsg := SYSTEM.VAL(PCD.Msg, msg);
          IF hmsg.type = 1 THEN DCore.DataOutStage(dev, hmsg.epnum)
          ELSIF hmsg.type = 2 THEN DCore.DataInStage(dev, hmsg.epnum, hmsg.zlpRequired)
          ELSIF hmsg.type = 3 THEN SetupStageCallback(dev)
          ELSIF hmsg.type = 4 THEN ASSERT(FALSE)
          ELSIF hmsg.type = 5 THEN ASSERT(FALSE)
          ELSIF hmsg.type = 6 THEN ASSERT(FALSE)
          ELSIF hmsg.type = 7 THEN Log.Debug("Resume"); Log.DebugLn; DCore.Resume(dev)
          ELSIF hmsg.type = 8 THEN Log.Debug("Suspend"); Log.DebugLn; DCore.Suspend(dev)
          ELSIF hmsg.type = 9 THEN Log.Debug("Reset"); Log.DebugLn; ResetCallback(dev)
          ELSIF hmsg.type = 10 THEN Log.Debug("Connect"); Log.DebugLn; DCore.DevConnected(dev)
          ELSIF hmsg.type = 11 THEN ASSERT(FALSE)
          ELSIF hmsg.type = 12 THEN IRQLog(hmsg)
          ELSE ASSERT(FALSE) (*unknown message*)
          END; 
          PCD.GiveMsg(dev, msg);
          msg := PCD.TakeMsg(dev)
        END
      | Def.Handle: ASSERT(FALSE)
    END
  END ProcessDeferredIRQWork;

END USBDHal.
