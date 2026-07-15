MODULE USBHHal;
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

  IMPORT SYSTEM, BSP, Kernel, Log := USBLog, Def := USBDef, ll := LLUSB, Q := Queue, UC := HALUC, HDef := USBHDef,
    HCore := USBHCore, HCD := HALHCD;

  VAR OldHandler: UC.IRQHandlerProc;

  (*******************************************************************************
                       LL Driver Callbacks (HCD -> USB Host Library)
  *******************************************************************************)

  (**
  * @brief  SOF callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE SOF_Callback(hhcd: HCD.Handle);
  BEGIN HCore.IncTimer(hhcd)
  END SOF_Callback;

  (**
  * @brief  Connect callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE Connect_Callback(hhcd: HCD.Handle);
  BEGIN HCore.Connect(hhcd)
  END Connect_Callback;

  (**
  * @brief  Disconnect callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE Disconnect_Callback(hhcd: HCD.Handle);
  BEGIN HCore.Disconnect(hhcd)
  END Disconnect_Callback;

  (**
  * @brief  Port Port Enabled callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE PortEnabled_Callback(hhcd: HCD.Handle);
  BEGIN HCore.PortEnabled(hhcd)
  END PortEnabled_Callback;

  (**
  * @brief  Port Port Disabled callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE PortDisabled_Callback(hhcd: HCD.Handle);
  BEGIN HCore.PortDisabled(hhcd)
  END PortDisabled_Callback;

  (**
  * @brief  Notify URB state change callback.
  * @param  hhcd: HCD handle
  * @param  chnum:
  * @param  urb_state:
  * @retval None
  *)
  PROCEDURE HC_NotifyURBChange_Callback(hcdh: HCD.Handle; chnum, urb_state: BYTE);
  BEGIN (* To be used with OS to sync URB state with the global state machine *)
  END HC_NotifyURBChange_Callback;

  (**
  * @brief  Gets a URB state from the low level driver.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  *          This parameter can be a value from 1 to 15
  * @retval URB state
  *          This parameter can be one of these values:
  *            @arg URB_IDLE
  *            @arg URB_DONE
  *            @arg URB_NOTREADY
  *            @arg URB_NYET
  *            @arg URB_ERROR
  *            @arg URB_STALL
  *)
  PROCEDURE GetURBState(host: HDef.Handle; pipe: BYTE): BYTE;
    RETURN HCD.HC_GetURBState(host(HCD.Handle), pipe)
  END GetURBState;

  (**
  * @brief  Resets the Host Port of the Low Level Driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE ResetPort*(host: Def.Handle);
  BEGIN HCD.ResetPort(host(HCD.Handle))
  END ResetPort;

  (**
  * @brief  Returns the last transferred packet size.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  * @retval Packet Size
  *)
  PROCEDURE GetLastXferSize(host: HDef.Handle; pipe: BYTE): INTEGER;
    RETURN HCD.HC_GetXferCount(host(HCD.Handle), pipe)
  END GetLastXferSize;

  (**
  * @brief  Opens a pipe of the Low Level Driver.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  * @param  epnum: Endpoint Number
  * @param  dev_address: Device USB address
  * @param  speed: Device Speed
  * @param  ep_type: Endpoint Type
  * @param  mps: Endpoint Max Packet Size
  * @retval USBH Status
  *)
  PROCEDURE OpenPipe(host: HDef.Handle; pipe, epnum, dev_address, speed, ep_type: BYTE; mps: HALFWORD);
    VAR res: BYTE;
  BEGIN res := HCD.HC_Init(host(HCD.Handle), pipe, epnum, dev_address, speed, ep_type, mps)
  END OpenPipe;

  (**
  * @brief  Sets toggle for a pipe.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  * @param  toggle: toggle (0/1)
  * @retval USBH Status
  *)
  PROCEDURE SetToggle(host: HDef.Handle; pipe: BYTE; toggle: BOOLEAN);
  BEGIN
    CASE host OF
      HCD.Handle:
        IF host.hc[pipe].ep_is_in THEN host.hc[pipe].toggle_in := toggle
        ELSE host.hc[pipe].toggle_out := toggle
        END
    | HDef.Handle: ASSERT(FALSE)
    END
  END SetToggle;

  (**
  * @brief  Closes a pipe of the Low Level Driver.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  * @retval USBH Status
  *)
  PROCEDURE ClosePipe(host: HDef.Handle; pipe: BYTE);
  BEGIN HCD.HC_Halt(host(HCD.Handle), pipe)
  END ClosePipe;

  (**
  * @brief  Submits a new URB to the low level driver.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  *          This parameter can be a value from 1 to 15
  * @param  direction: Channel number
  *          This parameter can be one of these values:
  *           0: Output
  *           1: Input
  * @param  ep_type: Endpoint Type
  *          This parameter can be one of these values:
  *            @arg EP_TYPE_CTRL: Control type
  *            @arg EP_TYPE_ISOC: Isochronous type
  *            @arg EP_TYPE_BULK: Bulk type
  *            @arg EP_TYPE_INTR: Interrupt type
  * @param  token: Endpoint Type
  *          This parameter can be one of these values:
  *            @arg 0: PID_SETUP
  *            @arg 1: PID_DATA
  * @param  pbuff: pointer to URB data
  * @param  length: length of URB data
  * @param  do_ping: activate do ping protocol (for high speed only)
  *          This parameter can be one of these values:
  *           0: do ping inactive
  *           1: do ping active
  * @retval USBH Status
  *)
  PROCEDURE SubmitURB(host: HDef.Handle; pipe: BYTE; direction: BOOLEAN; ep_type, token: BYTE;
    buff: Def.Buffer; length: HALFWORD; do_ping: BOOLEAN);
  BEGIN
    HCD.HC_SubmitRequest(host(HCD.Handle), pipe,
      direction, ep_type, token, buff, length, do_ping)
  END SubmitURB;

(*******************************************************************************
                       LL Driver Interface (USB Host Library --> HCD)
*******************************************************************************)
  (**
  * @brief  Stops the Low Level portion of the Host driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Stop*(host: HDef.Handle);
  BEGIN HCD.Stop(host(HCD.Handle));
  END Stop;

  (**
  * @brief  Starts the Low Level portion of the Host driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Start*(host: Def.Handle);
  BEGIN HCD.Start(host(HCD.Handle))
  END Start;

  (**
  * @brief  Initializes the Low Level portion of the Host driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Init*(core: Def.Handle; id: BYTE): HCD.Handle;
    VAR host!: HCD.Handle; tmp!: UC.Handle;
  BEGIN
    CASE core OF
      HCD.Handle: host := core
    | UC.Handle: host := HCD.New(); HCD.InitPools(host); tmp := host; tmp^ := core^; Def.Update(host, id)
    | Def.Handle: ASSERT(FALSE)
    END;

    host.SOFCallback := SOF_Callback;
    (* Set LL Driver parameters *)
    host.Init.Host_channels := 11;
    host.Init.Sof_enable := FALSE;
    OldHandler := host.ControllerIRQHandler; host.ControllerIRQHandler := HCD.IRQHandler;
    (*Oberon specific callbacks*)
    host.Stop := Stop;
    host.OpenPipe := OpenPipe;
    host.SetToggle := SetToggle;
    host.ClosePipe := ClosePipe;
    host.SubmitURB := SubmitURB;
    host.GetURBState := GetURBState;
    host.GetLastXferSize := GetLastXferSize;
    (* Initialize LL Driver *)
    IF HCD.Init(host) # ll.HAL_OK THEN host := NIL
    ELSE HCore.SetTimer(host, HCD.GetCurrentFrame(host))
    END

    RETURN host
  END Init;

  (**
  * @brief  De-Initializes the Low Level portion of the Host driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE DeInit*(host: Def.Handle);
  BEGIN
    CASE host OF HCD.Handle: HCD.DeInit(host);
      host.ControllerIRQHandler := OldHandler; OldHandler := NIL
    END
  END DeInit;

  (**
  * @brief  Returns the USB Host Speed from the Low Level Driver.
  * @param  phost: Host handle
  * @retval USBH Speeds
  *)
  PROCEDURE GetSpeed*(host: Def.Handle): BYTE;
    VAR cs: BYTE;
  BEGIN cs := HCD.GetCurrentSpeed(host(HCD.Handle));
    IF cs = 3 THEN cs := Def.SPEED_HIGH END

    RETURN cs
  END GetSpeed;

  PROCEDURE IRQLog(msg: HCD.DebugMsg);
  BEGIN Log.Debug("IRQ ");
    IF msg.chnum # 0FFH THEN
      Log.DebugString("chn: "); Log.DebugInt(msg.chnum, 1);
      IF msg.is_in THEN Log.DebugString(" IN") ELSE Log.DebugString(" OUT") END;
      Log.DebugString(", hcint: ");  Log.DebugSet(msg.hcint)
    END;
    Log.DebugString(", hprt: ");  Log.DebugSet(msg.hprt);
    Log.DebugString(", gintsts: ");  Log.DebugSet(msg.gintsts);
    Log.DebugString(", grxstsp: ");  Log.DebugSet(msg.grxstsp);
    Log.DebugLn
  END IRQLog;

  (**
  * @brief  Do the work offloaded by IRQs in the process loop.
  *)
 PROCEDURE ProcessDeferredIRQWork*(host: Def.Handle);
    VAR msg!: Q.Msg;
  BEGIN
    CASE host OF
      HCD.Handle:
        msg := HCD.TakeMsg(host);
        WHILE msg # NIL DO (*Process the message*)
          CASE msg OF
            HCD.ConnectMsg: Connect_Callback(host)
          | HCD.DisconnectMsg: Disconnect_Callback(host)
          | HCD.PortEnabledMsg: PortEnabled_Callback(host)
          | HCD.PortDisabledMsg: PortDisabled_Callback(host)
          | HCD.URBChangeMsg: HC_NotifyURBChange_Callback(host, msg.chnum, msg.urb_state)
          | HCD.DebugMsg: IRQLog(msg)
          | Q.Msg: ASSERT(FALSE) (*unknown message*)
          END; HCD.GiveMsg(host, msg);
          msg := HCD.TakeMsg(host)
        END
      | Def.Handle: ASSERT(FALSE)
    END
  END ProcessDeferredIRQWork;

END USBHHal.

OM4Tool.DecSym USBHHal.sm4
