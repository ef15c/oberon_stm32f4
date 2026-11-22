MODULE HALUC; (*The USB Core driver*)
  IMPORT SYSTEM, BSP, Kernel, LFQ, Log := USBLog, Def := USBDef, ll := LLUSB;

  CONST
    (*Message types*)
    DEBUG* = 1;

  (** @defgroup HCD_Exported_Types_Group1 HCD State Structure definition
  * @{
  *)
    STATE_INITIALIZED* = 1;
    STATE_CMOD_STABLE* = 2;
    STATE_READY* = 3;
    STATE_ERROR* = 4;

  TYPE
    Handle* = POINTER TO HandleDesc;
    IRQHandlerProc* = PROCEDURE^5(core: Handle);
    HandleDesc* = RECORD(Def.HandleDesc)
      Instance*: ll.OTGCore;  (*!< Register base address    *)
      Init*: ll.CfgDesc;            (*!< CD required parameters  *)
      cState*: BYTE;                (*!< CD initialization state  *)
      Timer*: INTEGER;         (*!< CD timer for OTG mode stabilization*)
      ControllerIRQHandler*: IRQHandlerProc;
      MsgQ: LFQ.Queue (*the deferred work message queue*)
    END;

    Msg* = POINTER TO MsgDesc;
    MsgDesc* = RECORD(LFQ.MsgDesc) gintsts*: SET
    END;

  VAR
    (*the message pools cannot be dynamically allocated because the garbage collector
      data can be corrupted if dynamic allocated objects are modified in an ISR while the
      Kernel.Mark procedure is running.
      Since it is not acceptable to disable interrupt during Kernel.Mark process, we must
      switch to static allocation of the message objects
      *)

    MP: ARRAY 10+1 OF MsgDesc;    (*!< HALUC message pool*)

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
    VAR flags: SET; USBx!: ll.OTGCore;
      dbm!: MsgDesc;
  BEGIN CLEAR(dbm); BSP.ledsOnOff({3}, {}); USBx := core.Instance;
    IF core # NIL THEN flags := ll.ReadInterrupts(USBx);
(*
      IF flags # {ll.GINTSTS_SOF} THEN dbm.gintsts := flags END;
*)
      IF ll.GINTSTS_MMIS IN flags THEN (* Mode mismatch, acknowledge the interrupt *)
        USBx.GINTSTS := {ll.GINTSTS_MMIS}
      END;
      IF ll.GINTSTS_CIDSCHG IN flags THEN (* Connector ID status change, acknowledge the interrupt *)
        USBx.GINTSTS := {ll.GINTSTS_CIDSCHG};
        core.cState := Def.IDLE; core.Timer := Kernel.Time()
      END;
(*todo: implement host negociation and session request
      IF ll.GINTSTS_OTGINT IN flags THEN (* OTG interrupt *)
        OTG_IRQHandler(cdh, dbm)
      END;
*)
      IF (ll.ReadInterrupts(USBx) # {}) & (core.ControllerIRQHandler # NIL) THEN
        core.ControllerIRQHandler(core)
      END
    END;
    BSP.ledsOnOff({}, {3});
    IF dbm.type # 0 THEN LFQ.Offer(core.MsgQ, dbm, DEBUG) END
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

    RETURN res
  END Init;

  (**
  * @brief  DeInitialize the USB Core driver.
  * @param  cdh CD handle
  * @retval HAL status
  *)
  PROCEDURE DeInit*(core: Handle);
  BEGIN ll.DisableGlobalInt(core.Instance)
  END DeInit;

  (**
  * @brief  Initialize the pool of messages for each type of deferred work.
  * @param  hhcd HCD handle
  *)
  PROCEDURE InitQueue*(core: Handle);
  BEGIN LFQ.InitQueue(core.MsgQ, SYSTEM.ADR(MP), LEN(MP), SYSTEM.SIZE(MsgDesc))
  END InitQueue;

  PROCEDURE TakeMsg*(core: Handle): Msg;
    VAR msg!: LFQ.Msg; cmsg!: Msg;
  BEGIN 
    IF LFQ.ExhaustedQueue(core.MsgQ) THEN Log.Error("HALUC Interrupt queue too small") END;
    msg := LFQ.Poll(core.MsgQ); cmsg :=SYSTEM.VAL(Msg, msg)
    RETURN cmsg
  END TakeMsg;

END HALUC.

