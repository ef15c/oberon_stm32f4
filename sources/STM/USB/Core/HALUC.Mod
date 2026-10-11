MODULE HALUC; (*The USB Core driver*)
  IMPORT BSP, Kernel, Def := USBDef, ll := LLUSB;

  CONST
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
    END;

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
  BEGIN BSP.ledsOnOff({3}, {});
    IF core # NIL THEN flags := ll.ReadInterrupts(core.Instance);
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

END HALUC.

