MODULE HALUC; (*The USB Core driver*)
  IMPORT BSP, Kernel, Def := USBDef, Log := USBLog, ll := LLUSB, Q := Queue;

  CONST
  (** @defgroup HCD_Exported_Types_Group1 HCD State Structure definition
  * @{
  *)
    STATE_INITIALIZED* = 1;
    STATE_CMOD_STABLE* = 2;
    STATE_READY* = 3;
    STATE_ERROR* = 4;

  TYPE
    (*!< USB debug message *)
    DebugMsg* = POINTER TO DebugMsgDesc;
    DebugMsgDesc* = RECORD(Q.MsgDesc) gintsts*: SET END;
(*    InitControllerMsg* = POINTER TO InitControllerMsgDesc;
    InitControllerMsgDesc = RECORD(Q.MsgDesc) END;*)

    Handle* = POINTER TO HandleDesc;
    IRQHandlerProc* = PROCEDURE^5(core: Handle);
    HandleDesc* = RECORD(Def.HandleDesc)
      Instance*: ll.OTGCore;  (*!< Register base address    *)
      Init*: ll.CfgDesc;            (*!< CD required parameters  *)
      cState*: BYTE;                (*!< CD initialization state  *)
      Timer*: INTEGER;         (*!< CD timer for OTG mode stabilization*)
      ControllerIRQHandler*: IRQHandlerProc;
      (*InitControllerMP, *)DebugMP: Q.Msg; (*the pools of available IRQ messages*)
      MsgPendQ: Q.Msg (*the deferred work message queue*)
    END;

(*    PROCEDURE newInitControllerMsg(): Q.Msg; (*create a initialization controller message object*)
      VAR item!: InitControllerMsg;
    BEGIN NEW(item)

      RETURN item
    END newInitControllerMsg;*)

    PROCEDURE newDebugMsg(): Q.Msg; (*create a debug message object*)
      VAR item!: DebugMsg;
    BEGIN NEW(item)

      RETURN item
    END newDebugMsg;

(*todo: implement host negociation and session request
  (**
  * @brief  Handle OTG interrupt request.
  * @param core handle
  * @param dbm Debug message
  * @retval None
  *)
  PROCEDURE OTG_IRQHandler*(core: Handle; dbm: DebugMP);
    VAR flags: SET;
  BEGIN flags := ll.ReadOtgInterrupts;
  END OTG_IRQHandler;
*)

  (**
  * @brief  Handle CD interrupt request.
  * @param core handle
  * @retval None
  *)
  PROCEDURE IRQHandler*(core: Handle);
    VAR flags: SET;
      msg!: Q.Msg; dbm!: DebugMsg;
  BEGIN BSP.ledsOnOff({3}, {});
    IF core # NIL THEN flags := ll.ReadInterrupts(core.Instance);
      dbm := NIL;
(*
      IF flags # {ll.GINTSTS_SOF} THEN msg := Q.Get(core.DebugMP);
        IF msg # NIL THEN dbm := msg(DebugMsg); CLEAR(dbm^);
          dbm.gintsts := core.Instance.GINTSTS; Q.Post(core.MsgPendQ, dbm)
        END
      END;
*)
      IF ll.GINTSTS_MMIS IN flags THEN (* Mode mismatch, acknowledge the interrupt *)
        core.Instance.GINTSTS := {ll.GINTSTS_MMIS}
      END;
      IF ll.GINTSTS_CIDSCHG IN flags THEN (* Connector ID status change, acknowledge the interrupt *)
        core.Instance.GINTSTS := {ll.GINTSTS_CIDSCHG};
        core.cState := Def.IDLE; core.Timer := Kernel.Time()
      END;
(*todo: implement host negociation and session request
      IF ll.GINTSTS_OTGINT IN flags THEN (* OTG interrupt *)
        OTG_IRQHandler(cdh, dbm)
      END;
*)
      IF (ll.ReadInterrupts(core.Instance) # {}) & (core.ControllerIRQHandler # NIL) THEN
        core.ControllerIRQHandler(core)
      END
    END;
    BSP.ledsOnOff({}, {3});
  END  IRQHandler;

  (**
  * @brief  Initialize the USB Core driver.
  * @param core handle
  * @retval HAL status
  *)
  PROCEDURE Init*(core: Handle): BYTE;
    VAR res: BYTE;
  BEGIN
    (* Check the parameters *)
    ASSERT((ORD(core.Instance) = ll.HS_PERIPH_BASE) OR (ORD(core.Instance) = ll.FS_PERIPH_BASE));
    (* Disable DMA mode for FS instance *)
    IF ORD(core.Instance) = ll.FS_PERIPH_BASE THEN core.Init.dma_enable := FALSE END;
    ll.DisableGlobalInt(core.Instance);  (* Disable the Interrupts *)
    (* Init the USB Core *)
    res := ll.CoreInit(core.Instance, core.Init); core.Timer := Kernel.Time();
    ll.EnableGlobalInt(core.Instance)
(*    IF ll.CoreInit(instance, init) # ll.HAL_OK THEN res := ll.HAL_ERROR
    ELSE
        (* Force Host Mode *)
        IF ll.SetCurrentMode(hhcd.Instance, ll.USB_HOST_MODE) # ll.HAL_OK THEN
          hhcd.State := STATE_ERROR; res := ll.HAL_ERROR
        ELSE
          (* Init Host *)
          IF ll.HostInit(hhcd.Instance, hhcd.Init) # ll.HAL_OK THEN
            hhcd.State := STATE_ERROR; res := ll.HAL_ERROR;
          ELSE hhcd.State := STATE_READY; res := ll.HAL_OK
          END
        END
    END
*)

    RETURN res
  END Init;

  (**
  * @brief  DeInitialize the USB Core driver.
  * @param  cdh CD handle
  * @retval HAL status
  *)
  PROCEDURE DeInit*(pcd: Handle);
  BEGIN ll.DisableGlobalInt(pcd.Instance)
  END DeInit;

  (**
  * @brief  Initialize the pool of messages for each type of deferred work.
  * @param core handle
  *)
  PROCEDURE InitPools*(core: Handle);
  BEGIN
(*    cdh.InitControllerMP := Q.CreatePool(1, newInitControllerMsg);*)
    Log.Debug("create 100 debug message objects"); Log.DebugLn;
    core.DebugMP := Q.CreatePool(100, newDebugMsg)
  END InitPools;

  PROCEDURE TakeMsg*(core: Handle): Q.Msg;
    VAR msg!: Q.Msg;
  BEGIN msg := NIL;
    IF Q.IsExhausted() THEN Log.Error("Interrupt queue too small"); Log.ErrorLn;
      Log.Flush; ASSERT(FALSE)
    END;
    IF core.MsgPendQ # NIL THEN
      ll.DisableGlobalInt(core.Instance); msg := Q.Get(core.MsgPendQ); ll.EnableGlobalInt(core.Instance)
    END

    RETURN msg
  END TakeMsg;

  PROCEDURE GiveMsg*(core: Handle; msg: Q.Msg); (*return message object to the appropriate pool*)
  BEGIN ll.DisableGlobalInt(core.Instance);
    CASE msg OF
(*      InitControllerMsg: Q.PostFirst(core.InitControllerMP, msg)
    |*)  DebugMsg: Q.PostFirst(core.DebugMP, msg)
    | Q.Msg: ASSERT(FALSE) (*unknown message type*)
    END;
    ll.EnableGlobalInt(core.Instance)
  END GiveMsg;

  PROCEDURE debug*;
    VAR core!: Def.Handle;
  BEGIN core := Def.usbCores[0];
    IF core # NIL THEN
      CASE core OF Handle:
        Log.Debug("GAHBCFG: "); Log.DebugSet(core.Instance.GAHBCFG); Log.DebugLn;
        Log.Debug("GINTSTS: "); Log.DebugSet(core.Instance.GINTSTS); Log.DebugLn;
        Log.Debug("GINTMSK: "); Log.DebugSet(core.Instance.GINTMSK); Log.DebugLn
      END
    END
  END debug;

END HALUC.

