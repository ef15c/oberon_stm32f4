MODULE HALPCD;
  (** The microcontroller specific part of the Peripheral controller driver, ported to Oberon from:
  ******************************************************************************
  * @file    stm32f4xx_hal_hcd.h
  * @author  MCD Application Team
  * @brief   HCD HAL module.
  ******************************************************************************
  *)
  IMPORT SYSTEM, BSP, Log := USBLog, Def := USBDef, Q := Queue, ll := LLUSB, UC := HALUC, UH := USBHal, DDef := USBDDef;

  CONST
    SPEED_HIGH* = ll.USBD_HS_SPEED;
    SPEED_HIGH_IN_FULL* = ll.USBD_HSINFS_SPEED;
    SPEED_FULL* = ll.USBD_FS_SPEED;

  (* Device LPM suspend state *)
    LPM_L0* = 0; (* on *)
    LPM_L1* = 1; (* LPM L1 sleep *)
    LPM_L2* = 2; (* suspend *)
    LPM_L3* = 3; (* off *)

    LPM_L0_ACTIVE* = 0; (* on *)
    LPM_L1_ACTIVE* = 1; (* LPM L1 sleep *)

  TYPE
  (**
  * @brief  PCD Handle Structure definition
  *)
    Handle* = POINTER TO HandleDesc;
    IRQCallback* = PROCEDURE^5(pcd: Handle);
    HandleDesc* = RECORD(DDef.HandleDesc)
      Address*: BYTE; (*!< USB Address                       *)
      IN_ep*, (*!< IN endpoint parameters            *)
      OUT_ep* (* /*!< OUT endpoint parameters           *) : ARRAY 16 OF ll.EPDesc;
      State: BYTE;       (*!< PCD communication state           *)
      ErrorCode: INTEGER;   (*!< PCD Error code                    *)
      Setup*: ARRAY 12*4 OF BYTE;   (*!< Setup packet buffer               *)
      LPM_State: BYTE;   (*!< LPM State                         *)
      BESL, FrameNumber: INTEGER; (*!< Store Current Frame number        *)
      lpm_active,               (*!< Enable or disable the Link Power Management .
                                       This parameter can be set to ENABLE or DISABLE        *)
      battery_charging_active: BOOLEAN;    (*!< Enable or disable Battery charging.
                                       This parameter can be set to ENABLE or DISABLE        *)
      SOFCallback*: IRQCallback;
      DataOutStageMP*, DataInStageMP*, SetupStageMP*,
      ISOOUTIncompleteMP*, ISOINIncompleteMP*,
      LPMMP*, ResumeMP*, SuspendMP*, ResetMP*,
      ConnectMP*, DisconnectMP*, (*the pools of available IRQ messages*)
      DebugMP*, (*the interrupt trace message pool*)
      MsgPendQ: Q.Msg (*the deferred work message queue*)
    END;

    Msg* = POINTER TO MsgDesc;
    MsgDesc* = RECORD(Q.MsgDesc) epnum*, msg*: BYTE; zlpRequired*: BOOLEAN;
      is_in*: BOOLEAN; gintsts*, dxepint*: SET
    END;
 
  VAR
    (*the message pools cannot be dynamically allocated because the garbage collector
      data can be corrupted if dynamic allocated objects are modified in an ISR while the
      Kernel.Mark procedure is running.
      Since it is not acceptable to disable interrupt during Kernel.Mark process, we must
      switch to static allocation of the messgage objects
      *)

    DOS: ARRAY 2+1 OF MsgDesc;    (*!< USB OTG PCD Data Out stage message*)
    DIS: ARRAY 2+1 OF MsgDesc;    (*!< USB OTG PCD Data In stage message*)
    SS: ARRAY 2+1 OF MsgDesc;    (*!< USB OTG PCD Setup stage message*)
    IOUTI: ARRAY 2+1 OF MsgDesc;    (*!< USB OTG PCD Isochronous Out incomplete message*)
    IINI: ARRAY 2+1 OF MsgDesc;    (*!< USB OTG PCD Isochronous In incomplete message*)
    LPM: ARRAY 1+1 OF MsgDesc;    (*!< USB OTG LPM change message*)
    RSM: ARRAY 1+1 OF MsgDesc;    (*!< USB OTG Resume message*)
    S: ARRAY 1+1 OF MsgDesc;    (*!< USB OTG Suspend message*)
    RST: ARRAY 1+1 OF MsgDesc;    (*!< USB OTG Reset message*)
    C: ARRAY 1+1 OF MsgDesc;    (*!< USB OTG Connect message*)
    D: ARRAY 1+1 OF MsgDesc;    (*!< USB OTG Disconnect message*)
    DBG: ARRAY 100+1 OF MsgDesc;    (*!< USB debug message *)

  (**
  * @brief  process EP OUT transfer complete interrupt.
  * @param  hpcd PCD handle
  * @param  epnum endpoint number
  * @retval HAL status
  *)
  PROCEDURE OutXfrComplete_int(hpcd: Handle; epnum: BYTE);
    VAR DoepintReg: SET; USBx!: ll.OTGCore; msg!: Q.Msg; hmsg!: Msg;
    PROCEDURE HandlePacketReceived(hpcd: Handle; VAR ep: ll.EPDesc; epnum: BYTE);
      VAR msg!: Q.Msg; hmsg!: Msg;
    BEGIN (* out data packet received over EP *)
      ep.xfer_count := ep.xfer_size - ORD(hpcd.Instance.OUTEP[epnum].DOEPTSIZ*ll.DOEPTSIZ_XFRSIZ_Msk);
      IF epnum = 0 THEN
        IF ep.xfer_len = 0 THEN (* this is ZLP, so prepare EP0 for next setup *)
            ll.EP0_OutStart(hpcd.Instance, TRUE, SYSTEM.ADR(hpcd.Setup));
        ELSE INC(ep.xfer_buff, ep.xfer_count)
        END
      END;
      msg := Q.Get(hpcd.DataOutStageMP); hmsg := SYSTEM.VAL(Msg, msg);
      IF hmsg # NIL THEN hmsg.epnum := epnum; Q.Post(hpcd.MsgPendQ, hmsg) END
    END HandlePacketReceived;

  BEGIN USBx := hpcd.Instance;
    DoepintReg := USBx.OUTEP[epnum].DOEPINT;
    IF hpcd.Init.dma_enable THEN
      IF ll.DOEPINT_STUP IN DoepintReg THEN (* Class C *)
        IF (ORD(USBx.GSNPSID*ll.GSNPSID_CORE_REV_Msk) > 300AH) & (ll.DOEPINT_STPKTRX IN DoepintReg) THEN
          ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_STPKTRX})
        END
      ELSIF ll.DOEPINT_OTEPSPR IN DoepintReg THEN (* Class E *)
        ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_OTEPSPR})
      ELSE (* StupPktRcvd = 1 this is a setup packet *)
        IF (ORD(USBx.GSNPSID*ll.GSNPSID_CORE_REV_Msk) > 300AH) & (ll.DOEPINT_STPKTRX IN DoepintReg) THEN
          ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_STPKTRX})
        ELSE HandlePacketReceived(hpcd, hpcd.OUT_ep[epnum], epnum)
        END
      END
   ELSE
      IF ORD(USBx.GSNPSID*ll.GSNPSID_CORE_REV_Msk) = 310AH THEN
        (* StupPktRcvd = 1 this is a setup packet *)
        IF ll.DOEPINT_STPKTRX IN DoepintReg THEN ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_STPKTRX})
        ELSE IF ll.DOEPINT_OTEPSPR IN DoepintReg THEN ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_OTEPSPR}) END;
          msg := Q.Get(hpcd.DataOutStageMP); hmsg := SYSTEM.VAL(Msg, msg);
          IF hmsg # NIL THEN hmsg.epnum := epnum; Q.Post(hpcd.MsgPendQ, hmsg) END
        END
      ELSE
        IF (epnum = 0) & (hpcd.OUT_ep[epnum].xfer_len = 0) THEN
          (* this is ZLP, so prepare EP0 for next setup *)
          ll.EP0_OutStart(USBx, FALSE, SYSTEM.ADR(hpcd.Setup))
        END;
        msg := Q.Get(hpcd.DataOutStageMP); hmsg := SYSTEM.VAL(Msg, msg);
        IF hmsg # NIL THEN hmsg.epnum := epnum; Q.Post(hpcd.MsgPendQ, hmsg) END
      END
    END
  END OutXfrComplete_int;

  PROCEDURE Post_OutSetupPacket_int*(hpcd: Handle);
  BEGIN
    IF (ORD(hpcd.Instance.GSNPSID*ll.GSNPSID_CORE_REV_Msk) > 300AH) & (hpcd.Init.dma_enable) THEN
      ll.EP0_OutStart(hpcd.Instance, TRUE, SYSTEM.ADR(hpcd.Setup))
    END;
    ll.EnableEPInt(hpcd.Instance, 0, TRUE); (*resume IN 0 interrupts handling*)
  END Post_OutSetupPacket_int;

  (**
  * @brief  process EP OUT setup packet received interrupt.
  * @param  hpcd PCD handle
  * @param  epnum endpoint number
  * @retval HAL status
  *)
  PROCEDURE EP_OutSetupPacket_int(hpcd: Handle; epnum: BYTE);
    VAR DoepintReg: SET; USBx!: ll.OTGCore; msg!: Q.Msg;
  BEGIN USBx := hpcd.Instance; ASSERT(epnum = 0);
    DoepintReg := USBx.OUTEP[epnum].DOEPINT;
    IF (ORD(USBx.GSNPSID*ll.GSNPSID_CORE_REV_Msk) > 300AH) & (ll.DOEPINT_STPKTRX IN DoepintReg) THEN
      ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_STPKTRX})
    END;
    ll.DisableEPInt(hpcd.Instance, 0, TRUE); (*delay IN 0 interrupts handling*)
    msg := Q.Get(hpcd.SetupStageMP); (* Inform the upper layer that a setup packet is available *)
    IF msg # NIL THEN Q.Post(hpcd.MsgPendQ, msg) END
  END EP_OutSetupPacket_int;

  (**
  * @brief  Check FIFO for the next packet to be loaded.
  * @param  hpcd PCD handle
  * @param  epnum endpoint number
  * @retval HAL status
  *)
  PROCEDURE WriteEmptyTxFifo(hpcd: Handle; epnum: BYTE);
 
    PROCEDURE wetxfifo(VAR ep: ll.EPDesc; hpcd: Handle; epnum: BYTE);
      VAR len, len32b: INTEGER;
    BEGIN
      IF ep.xfer_count <=  ep.xfer_len THEN
        len := ep.xfer_len - ep.xfer_count;
        IF len > ep.maxpacket THEN len := ep.maxpacket END;
        len32b := (len + 3) DIV 4;
        WHILE (ORD(LSR(hpcd.Instance.INEP[epnum].DTXFSTS*ll.DTXFSTS_INEPTFSAV_Msk, ll.DTXFSTS_INEPTFSAV_Pos)) >= len32b) &
          (ep.xfer_count < ep.xfer_len) & (ep.xfer_len # 0) DO
          (* Write the FIFO *)
          len := ep.xfer_len - ep.xfer_count;
          IF len > ep.maxpacket THEN len := ep.maxpacket END;
          len32b := (len + 3) DIV 4;
          ll.WritePacket(hpcd.Instance, ep.xfer_buff, epnum, len, hpcd.Init.dma_enable);
          INC(ep.xfer_buff, len); INC(ep.xfer_count, len)
        END;
        IF ep.xfer_len <= ep.xfer_count THEN EXCL(hpcd.Instance.DIEPEMPMSK, epnum MOD 10H) END
      END
    END wetxfifo;

  BEGIN wetxfifo(hpcd.IN_ep[epnum], hpcd, epnum);
  END WriteEmptyTxFifo;

  (**
   * @brief  Abort an USB EP transaction.
   * @param  hpcd PCD handle
   * @param  ep_addr endpoint address
   * @retval HAL status
   *)
  PROCEDURE EP_Abort(hpcd: Handle;  ep_addr: BYTE): BYTE;
    VAR ret: BYTE;
  BEGIN
    (* Stop Xfer *)
    IF 7 IN TOSET(ep_addr) THEN ret := ll.EPStopXfer(hpcd.Instance, hpcd.IN_ep[ep_addr MOD 10H])
    ELSE ret := ll.EPStopXfer(hpcd.Instance, hpcd.OUT_ep[ep_addr MOD 10H])
    END

    RETURN ret
  END EP_Abort;

  (**
  * @brief  Handle PCD interrupt request.
  * @param  pcd HCD handle
  * @retval None
  *)
  PROCEDURE IRQHandler*(hpcd: UC.Handle);
    VAR flags, RegVal, ep_intr, epint: SET; USBx!: ll.OTGCore;
      epnum: BYTE; msg!: Q.Msg; ret: BYTE; i: INTEGER;
      dbm!, hmsg!: Msg;

    PROCEDURE HandleRXFLVL(RegVal: SET; VAR ep: ll.EPDesc; hpcd: Handle);
      VAR bytecnt: INTEGER;
    BEGIN bytecnt := LSR(ORD(RegVal*ll.GRXSTS_BCNT_Msk), ll.GRXSTS_BCNT_Pos);
      IF RegVal*ll.GRXSTS_PKTSTS_Msk = ll.GRXSTS_PKTSTS_PKTRCV THEN
        IF bytecnt # 0 THEN ll.ReadPacket(hpcd.Instance, ep.xfer_buff, bytecnt);
          INC(ep.xfer_buff, bytecnt); INC(ep.xfer_count, bytecnt)
        END
      ELSIF RegVal*ll.GRXSTS_PKTSTS_Msk = ll.GRXSTS_PKTSTS_SETUPRCV THEN
        ll.ReadPacket(hpcd.Instance, SYSTEM.ADR(hpcd.Setup), 8); INC(ep.xfer_count, bytecnt)
      END
    END HandleRXFLVL;

  BEGIN dbm := NIL; BSP.ledsOnOff({2}, {}); USBx := hpcd.Instance;
    CASE hpcd OF
      Handle:
        flags := ll.ReadInterrupts(USBx);
(*
        IF flags # {ll.GINTSTS_SOF} THEN msg := Q.Get(hpcd.DebugMP);
          IF msg # NIL THEN dbm := msg(DebugMsg); CLEAR(dbm^); dbm.epnum := 0FFH; dbm.gintsts := flags
          END
        END;
*)
        IF ~ll.IsHost(USBx) & (flags # {}) THEN (* ensure that we are in device mode and avoid spurious interrupt *)
          hpcd.FrameNumber := LSR(ORD(USBx.DSTS*ll.DSTS_FNSOF_Msk), ll.DSTS_FNSOF_Pos); (* store current frame number *)
          (* Handle RxQLevel Interrupt *)
          IF ll.GINTSTS_RXFLVL IN flags THEN EXCL(USBx.GINTMSK, ll.GINTSTS_RXFLVL);
            (*USBx.GRXSTSP must be read only once per interrupt, because reading it pops one item from input FIFO*)
            RegVal := USBx.GRXSTSP;
            HandleRXFLVL(RegVal, hpcd.OUT_ep[ORD(RegVal*ll.GRXSTS_EPNUM_Msk)], hpcd);
            INCL(USBx.GINTMSK, ll.GINTSTS_RXFLVL)
          END;
          IF ll.GINTSTS_OEPINT IN flags THEN epnum := 0;
            ep_intr := ll.ReadDevAllOutEpInterrupts(USBx); (* Read in the device interrupt bits *)
            WHILE ep_intr # {} DO
              IF epnum IN ep_intr THEN
                epint := ll.ReadDevOutEPInterrupts(USBx, epnum);
                IF dbm # NIL THEN dbm.is_in := FALSE; dbm.epnum := epnum; dbm.dxepint := epint END;
                IF ll.DOEPINT_XFRC IN epint THEN
                  ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_XFRC});
                  OutXfrComplete_int(hpcd, epnum)
                END;
                IF ll.DOEPINT_STUP IN epint THEN
                  ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_STUP});
                  (* Class B setup phase done for previous decoded setup *)
                  EP_OutSetupPacket_int(hpcd, epnum)
                END;
                IF ll.DOEPINT_OTEPDIS IN epint THEN
                  ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_OTEPDIS})
                END;
                (* Clear OUT Endpoint disable interrupt *)
                IF ll.DOEPINT_EPDISD IN epint THEN
                  IF ll.GINTSTS_GOUTNAKEFF IN USBx.GINTSTS THEN INCL(USBx.DCTL, ll.DCTL_CGONAK) END;
                  IF hpcd.OUT_ep[epnum].is_iso_incomplete THEN
                    hpcd.OUT_ep[epnum].is_iso_incomplete := FALSE;
                    msg := Q.Get(hpcd.ISOOUTIncompleteMP); hmsg := SYSTEM.VAL(Msg, msg);
                    IF hmsg # NIL THEN hmsg.epnum := epnum; Q.Post(hpcd.MsgPendQ, hmsg) END;
                  END;
                  ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_EPDISD})
                END;
                (* Clear Status Phase Received interrupt *)
                IF ll.DOEPINT_OTEPSPR IN epint THEN ll.ClearOutEPInterrupts(USBx, epnum, {ll.DOEPINT_OTEPSPR}) END;
                (* Clear OUT NAK interrupt *)
                IF ll.DOEPINT_NAK IN epint THEN ll.ClearOutEPInterrupts(USBx,epnum, {ll.DOEPINT_NAK}) END;
                EXCL(ep_intr, epnum)
              END;
              INC(epnum)
            END
          END;
          IF ll.GINTSTS_IEPINT IN flags THEN epnum := 0;
            ep_intr := ll.ReadDevAllInEpInterrupts(USBx); (* Read in the device interrupt bits *)
            WHILE ep_intr # {} DO
              IF epnum IN ep_intr THEN (* In ITR *)
                epint := ll.ReadDevInEPInterrupts(USBx, epnum);
                IF dbm # NIL THEN dbm.is_in := TRUE; dbm.epnum := epnum; dbm.dxepint := epint END;
                IF ll.DIEPINT_XFRC IN epint THEN EXCL(USBx.DIEPEMPMSK, epnum MOD 10H);
                  ll.ClearInEPInterrupts(USBx, epnum, {ll.DIEPINT_XFRC});
                  IF hpcd.Init.dma_enable THEN INC(hpcd.IN_ep[epnum].xfer_buff, hpcd.IN_ep[epnum].maxpacket);
                    IF (epnum = 0) & (hpcd.IN_ep[epnum].xfer_len = 0) THEN (* this is ZLP, so prepare EP0 for next setup *)
                      ll.EP0_OutStart(USBx, TRUE, SYSTEM.ADR(hpcd.Setup)) (* prepare to rx more setup packets *)
                    END
                  END;
                  IF hpcd.IN_ep[epnum].xfer_len # 0 THEN msg := Q.Get(hpcd.DataInStageMP); hmsg := SYSTEM.VAL(Msg, msg);
                    IF hmsg # NIL THEN hmsg.epnum := epnum;
                      hmsg.zlpRequired := hpcd.IN_ep[epnum].autoZLP &
                        (hpcd.IN_ep[epnum].xfer_len MOD hpcd.IN_ep[epnum].maxpacket = 0);
                      Q.Post(hpcd.MsgPendQ, hmsg)
                    END
                  END
                END;
                IF ll.DIEPINT_TOC IN epint THEN ll.ClearInEPInterrupts(USBx, epnum, {ll.DIEPINT_TOC}) END;
                IF ll.DIEPINT_ITTXFE IN epint THEN ll.ClearInEPInterrupts(USBx, epnum, {ll.DIEPINT_ITTXFE}) END;
                IF ll.DIEPINT_INEPNE IN epint THEN ll.ClearInEPInterrupts(USBx, epnum, {ll.DIEPINT_INEPNE}) END;
                IF ll.DIEPINT_EPDISD IN epint THEN ret := ll.FlushTxFifo(USBx, epnum);
                  IF hpcd.IN_ep[epnum].is_iso_incomplete THEN hpcd.IN_ep[epnum].is_iso_incomplete := FALSE;
                    msg := Q.Get(hpcd.ISOINIncompleteMP); hmsg := SYSTEM.VAL(Msg, msg);
                    IF hmsg # NIL THEN hmsg.epnum := epnum; Q.Post(hpcd.MsgPendQ, hmsg) END;
                  END;
                  ll.ClearInEPInterrupts(USBx, epnum, {ll.DIEPINT_EPDISD})
                END;
                IF ll.DIEPINT_TXFE IN epint THEN WriteEmptyTxFifo(hpcd, epnum) END;
                EXCL(ep_intr, epnum)
              END;
              INC(epnum)
            END
          END;
          (* Handle Resume Interrupt *)
          IF ll.GINTSTS_WKUINT IN flags THEN
            EXCL(USBx.DCTL, ll.DCTL_RWUSIG); (* Clear the Remote Wake-up Signaling *)
            IF hpcd.LPM_State = LPM_L1 THEN
              hpcd.LPM_State := LPM_L0;
              msg := Q.Get(hpcd.LPMMP); hmsg := SYSTEM.VAL(Msg, msg);
              IF hmsg # NIL THEN hmsg.msg := LPM_L0_ACTIVE; Q.Post(hpcd.MsgPendQ, hmsg) END;
            ELSE
              msg := Q.Get(hpcd.ResumeMP);
              IF msg # NIL THEN Q.Post(hpcd.MsgPendQ, msg) END
            END;
            USBx.GINTSTS := {ll.GINTSTS_WKUINT}
          END;
          (* Handle Suspend Interrupt *)
          IF ll.GINTSTS_USBSUSP IN flags THEN
            IF ll.DSTS_SUSPSTS IN USBx.DSTS THEN
              msg := Q.Get(hpcd.SuspendMP);
              IF msg # NIL THEN Q.Post(hpcd.MsgPendQ, msg) END
            END;
            USBx.GINTSTS := {ll.GINTSTS_USBSUSP}
          END;
          (* Handle Reset Interrupt *)
          IF ll.GINTSTS_USBRST IN flags THEN
            IF ~(ll.DCTL_SDIS IN USBx.DCTL) (*avoid spurious USBRST triggered by DCTL_SDIS*) THEN
              EXCL(USBx.DCTL, ll.DCTL_RWUSIG);
              ret := ll.FlushTxFifo(USBx, ll.ALL_FIFOs);
              FOR i := 0 TO hpcd.Init.dev_endpoints - 1 DO
                USBx.INEP[i].DIEPINT := ll.DIEPINT_Reset;
                EXCL(USBx.INEP[i].DIEPCTL, ll.DIEPCTL_STALL);
                USBx.OUTEP[i].DOEPINT := ll.DOEPINT_Reset;
                EXCL(USBx.OUTEP[i].DOEPCTL, ll.DOEPCTL_STALL);
                INCL(USBx.OUTEP[i].DOEPCTL, ll.DOEPCTL_SNAK)
              END;
              USBx.DAINTMSK := {0, 16}; (*unmask OUT interrupts*)
              IF hpcd.Init.use_dedicated_ep1 THEN
                USBx.DOUTEP1MSK :=  USBx.DOUTEP1MSK + 
                  {ll.DOEPMSK_STUPM, ll.DOEPMSK_XFRCM, ll.DOEPMSK_EPDM};
                USBx.DINEP1MSK := USBx.DINEP1MSK +
                  {ll.DIEPMSK_TOM, ll.DIEPMSK_XFRCM, ll.DIEPMSK_EPDM}
              ELSE
                USBx.DOEPMSK := USBx.DOEPMSK +
                  {ll.DOEPMSK_STUPM, ll.DOEPMSK_XFRCM, ll.DOEPMSK_EPDM + ll.DOEPMSK_OTEPSPRM + ll.DOEPMSK_NAKM};
                USBx.DIEPMSK := USBx.DIEPMSK +
                  {ll.DIEPMSK_TOM, ll.DIEPMSK_XFRCM, ll.DIEPMSK_EPDM}
              END;
              (* Set Default Address to 0 *)
              USBx.DCFG := USBx.DCFG - ll.DCFG_DAD_Msk;
              (* setup EP0 to receive SETUP packets *)
              ll.EP0_OutStart(USBx, hpcd.Init.dma_enable, SYSTEM.ADR(hpcd.Setup))
            END;
            USBx.GINTSTS := {ll.GINTSTS_USBRST}
          END;
          (* Handle Enumeration done Interrupt *)
          IF ll.GINTSTS_ENUMDNE IN flags THEN
            IF ~(ll.DCTL_SDIS IN USBx.DCTL) (*avoid spurious ENUMDNE triggered by DCTL_SDIS*) THEN
              ll.ActivateSetup(USBx); hpcd.Init.speed := ll.GetDevSpeed(USBx);
              ll.SetTurnaroundTime(USBx, BSP.HCLKFreq*1000000, hpcd.Init.speed);
              msg := Q.Get(hpcd.ResetMP);
              IF msg # NIL THEN Q.Post(hpcd.MsgPendQ, msg) END
            END;
            USBx.GINTSTS := {ll.GINTSTS_ENUMDNE}
          END;
          (* Handle SOF Interrupt *)
          IF ll.GINTSTS_SOF IN flags THEN hpcd.SOFCallback(hpcd); USBx.GINTSTS := {ll.GINTSTS_SOF} END;
          (* Handle Global OUT NAK effective Interrupt *)
          IF ll.GINTSTS_GOUTNAKEFF IN flags THEN EXCL(USBx.GINTMSK, ll.GINTMSK_GONAKEFFM);
            FOR epnum := 1 TO hpcd.Init.dev_endpoints - 1 DO
              IF hpcd.OUT_ep[epnum].is_iso_incomplete THEN
                ret := EP_Abort(hpcd, epnum) (* Abort current transaction and disable the EP *)
              END
            END
          END;
          (* Handle Incomplete ISO IN Interrupt *)
          IF ll.GINTSTS_IISOIXFR IN flags THEN
            FOR epnum := 1 TO hpcd.Init.dev_endpoints - 1 DO
              RegVal := USBx.INEP[epnum].DIEPCTL;
              IF (hpcd.IN_ep[epnum].type = Def.EP_TYPE_ISOC) & (ll.DIEPCTL_EPENA IN RegVal) THEN
                hpcd.IN_ep[epnum].is_iso_incomplete := TRUE;
                ret := EP_Abort(hpcd, ORD(TOSET(epnum) + {7})) (* Abort current transaction and disable the EP *)
              END
            END;
            USBx.GINTSTS := {ll.GINTSTS_IISOIXFR}
          END;
          (* Handle Incomplete ISO OUT Interrupt *)
          IF ll.GINTSTS_PXFR_INCOMPISOOUT IN flags THEN
            epnum := 1;
            WHILE epnum < hpcd.Init.dev_endpoints DO
              RegVal := USBx.OUTEP[epnum].DOEPCTL;
              IF (hpcd.OUT_ep[epnum].type = Def.EP_TYPE_ISOC) & (ll.DOEPCTL_EPENA IN RegVal) &
                (LSR(RegVal*ll.DIEPCTL_EONUM_DPID_Msk, ll.DIEPCTL_EONUM_DPID) = TOSET(hpcd.FrameNumber)*{0}) THEN
                hpcd.OUT_ep[epnum].is_iso_incomplete := TRUE; INCL(USBx.GINTMSK, ll.GINTMSK_GONAKEFFM);
                IF  ~(ll.GINTSTS_GOUTNAKEFF IN USBx.GINTSTS) THEN INCL(USBx.DCTL, ll.DCTL_SGONAK);
                  epnum := hpcd.Init.dev_endpoints; (*exit FOR*)
                END
              END;
              INC(epnum)
            END;
            USBx.GINTSTS := {ll.GINTSTS_PXFR_INCOMPISOOUT}
          END;
          (* Handle Connection event Interrupt *)
          IF ll.GINTSTS_SRQINT IN flags THEN
            msg := Q.Get(hpcd.ConnectMP);
            IF msg # NIL THEN Q.Post(hpcd.MsgPendQ, msg) END;
            USBx.GINTSTS := {ll.GINTSTS_SRQINT}
          END;
          (* Handle Disconnection event Interrupt *)
          IF ll.GINTSTS_OTGINT IN flags THEN
            RegVal := USBx.GOTGINT;
            IF ll.GOTGINT_SEDET IN RegVal THEN
              msg := Q.Get(hpcd.DisconnectMP);
              IF msg # NIL THEN Q.Post(hpcd.MsgPendQ, msg) END;
            END;
            USBx.GOTGINT := RegVal (*warning: clear all GOTGINT flags!*)
          END
        END;
        IF dbm # NIL THEN Q.Post(hpcd.MsgPendQ, dbm) END
    | UC.Handle: ASSERT(FALSE)
    END;
    BSP.ledsOnOff({}, {2});
  END IRQHandler;

  (**
  * @brief  Initializes the PCD according to the specified
  *         parameters in the PCD_InitTypeDef and initialize the associated handle.
  * @param  pcd PCD handle
  * @retval HAL status
  *)
  PROCEDURE Init*(pcd: Handle): BYTE;
    VAR res: BYTE; i: INTEGER;
  BEGIN
    (* Check the PCD handle allocation *)
    IF pcd = NIL THEN res := ll.HAL_ERROR
    ELSE
      pcd.State := Def.STATE_BUSY;
      (* Init endpoints structures *)
      FOR i := 0 TO pcd.Init.dev_endpoints - 1 DO
        (* Init ep structure *)
        pcd.IN_ep[i].is_in := TRUE;
        pcd.IN_ep[i].num := i;
        (* Control until ep is activated *)
        pcd.IN_ep[i].type := Def.EP_TYPE_CTRL;
        pcd.IN_ep[i].maxpacket := 0;
        pcd.IN_ep[i].xfer_buff := 0;
        pcd.IN_ep[i].xfer_len := 0
      END;
      FOR i := 0 TO pcd.Init.dev_endpoints -1 DO
        pcd.OUT_ep[i].is_in := FALSE;
        pcd.OUT_ep[i].num := i;
        (* Control until ep is activated **)
        pcd.OUT_ep[i].type := Def.EP_TYPE_CTRL;
        pcd.OUT_ep[i].maxpacket := 0;
        pcd.OUT_ep[i].xfer_buff := 0;
        pcd.OUT_ep[i].xfer_len := 0;
      END;

      (* Init Peripheral *) ASSERT(pcd.ControllerIRQHandler # NIL);
      IF ll.DevInit(pcd.Instance, pcd.Init) # ll.HAL_OK THEN
        pcd.State := Def.STATE_ERROR; res := ll.HAL_ERROR
      ELSE pcd.Address := 0; pcd.State := Def.STATE_READY;
        ll.DevDisconnect(pcd.Instance);
        res := ll.HAL_OK
      END
    END

    RETURN res
  END Init;

  (**
  * @brief  DeInitializes the PCD peripheral.
  * @param  hpcd PCD handle
  * @retval HAL status
  *)
  PROCEDURE DeInit*(hpcd: Handle);
    VAR ret: BYTE;
  BEGIN
    IF (hpcd # NIL) & (ll.StopDevice(hpcd.Instance) = Def.OK) THEN
      hpcd.State := Def.STATE_RESET;
    END
  END DeInit;

  (**
  * @brief  Start the USB device
  * @param  hpcd PCD handle
  * @retval HAL status
  *)
  PROCEDURE Start*(hpcd: Handle);
    VAR USBx!: ll.OTGCore;
  BEGIN USBx := hpcd.Instance;
    IF (ll.GUSBCFG_PHYSEL IN USBx.GUSBCFG) & (hpcd.Init.battery_charging_enable) THEN
      INCL(USBx.GCCFG, ll.GCCFG_PWRDWN) (* Enable USB Transceiver *)
    END;
    ll.DevConnect(USBx)
  END Start;

  (**
  * @brief  Stop the USB device.
  * @param  hpcd PCD handle
  * @retval HAL status
  *)
  PROCEDURE Stop*(hpcd: Handle);
    VAR res: BYTE; USBx!: ll.OTGCore;
  BEGIN USBx := hpcd.Instance;
    ll.DevDisconnect(USBx);
    res := ll.FlushTxFifo(USBx, ll.ALL_FIFOs);
    IF (ll.GUSBCFG_PHYSEL IN USBx.GUSBCFG) & (hpcd.Init.battery_charging_enable) THEN
      EXCL(USBx.GCCFG, ll.GCCFG_PWRDWN) (* Disable USB Transceiver *)
    END
  END Stop;

  (**
  * @brief  Set the USB Device address.
  * @param  hpcd PCD handle
  * @param  address new device address
  * @retval HAL status
  *)
  PROCEDURE SetAddress*(hpcd: Handle; address: BYTE);
  BEGIN hpcd.Address := address;
    ll.SetDevAddress(hpcd.Instance, address)
  END SetAddress;

  (**
  * @brief  Open and configure an endpoint.
  * @param  hpcd PCD handle
  * @param  ep_addr endpoint address
  * @param  ep_mps endpoint max packet size
  * @param  ep_type endpoint type
  * @retval HAL status
  *)
  PROCEDURE EP_Open*(hpcd: Handle; ep_addr: BYTE; ep_mps: HALFWORD; ep_type: BYTE);
    PROCEDURE OpenEP(hpcd: Handle; VAR ep: ll.EPDesc; isIn: BOOLEAN; ep_addr: BYTE; ep_mps: HALFWORD; ep_type: BYTE);
    BEGIN ep.is_in := isIn;
      ep.num := ep_addr MOD 10H; ep.maxpacket := ep_mps MOD 800H;
      ep.type := ep_type;
      IF ep_type = Def.EP_TYPE_BULK THEN ep.data_pid_start := 0 (* Set initial data PID. *) END;
      ll.ActivateEndpoint(hpcd.Instance, ep)
    END OpenEP;
  BEGIN 
    IF 7 IN TOSET(ep_addr) THEN OpenEP(hpcd, hpcd.IN_ep[ep_addr MOD 10H], TRUE, ep_addr, ep_mps, ep_type)
    ELSE OpenEP(hpcd, hpcd.OUT_ep[ep_addr MOD 10H], FALSE, ep_addr, ep_mps, ep_type)
    END;
  END EP_Open;

  (**
  * @brief  Enables or disables the automatic ZLP insertion feature.
  * @param  pdev: Device handle
  * @param  ep_addr: Endpoint Number
  * @param  autoZLP: TRUE for enabling, FLASE for disabling
  *)
  PROCEDURE EP_SetAutoZLP*(hpcd: Handle; ep_addr: BYTE; autoZLP: BOOLEAN);
  BEGIN ASSERT (7 IN TOSET(ep_addr));
    hpcd.IN_ep[ep_addr MOD 10H].autoZLP := autoZLP
  END EP_SetAutoZLP;

  (**
  * @brief  Deactivate an endpoint.
  * @param  hpcd PCD handle
  * @param  ep_addr endpoint address
  * @retval HAL status
  *)
  PROCEDURE EP_Close*(hpcd: Handle; ep_addr: BYTE);

    PROCEDURE CloseEP(hpcd: Handle; VAR ep: ll.EPDesc; isIn: BOOLEAN; ep_addr: BYTE);
    BEGIN ep.is_in := isIn;
      ep.num := ep_addr MOD 10H;
      ll.DeactivateEndpoint(hpcd.Instance, ep);
    END CloseEP;

  BEGIN
    IF 7 IN TOSET(ep_addr) THEN CloseEP(hpcd, hpcd.IN_ep[ep_addr MOD 10H], TRUE, ep_addr)
    ELSE CloseEP(hpcd, hpcd.OUT_ep[ep_addr MOD 10H], FALSE, ep_addr)
    END
  END EP_Close;

  (**
  * @brief  Receive an amount of data.
  * @param  hpcd PCD handle
  * @param  ep_addr endpoint address
  * @param  pBuf pointer to the reception buffer
  * @retval HAL status
  *)
  PROCEDURE EP_Receive*(hpcd: Handle; ep_addr: BYTE; buf: Def.BufferDesc);

    PROCEDURE ReceiveEP(hpcd: Handle; VAR ep: ll.EPDesc; buf: Def.BufferDesc; ep_num: BYTE);
    BEGIN (*setup and start the Xfer *)
      ep.xfer_buff := SYSTEM.ADR(buf) + SYSTEM.SIZE(Def.BufferDesc) + buf.offset;
      ep.xfer_len := buf.size; ep.xfer_count := 0; ep.is_in := FALSE;
      ep.num := ep_num;
      IF hpcd.Init.dma_enable THEN ep.dma_addr := ep.xfer_buff END;
      ll.EPStartXfer(hpcd.Instance, ep, hpcd.Init.dma_enable);
    END ReceiveEP;

  BEGIN ReceiveEP(hpcd, hpcd.OUT_ep[ep_addr MOD 10H], buf, ep_addr MOD 10H)
  END EP_Receive;

  (**
  * @brief  Get Received Data Size
  * @param  hpcd PCD handle
  * @param  ep_addr endpoint address
  * @retval Data Size
  *)
  PROCEDURE EP_GetRxCount*(hpcd: Handle; ep_addr: BYTE): INTEGER;
    RETURN hpcd.OUT_ep[ep_addr MOD 10H].xfer_count
  END EP_GetRxCount;

  (**
  * @brief  Send an amount of data
  * @param  hpcd PCD handle
  * @param  ep_addr endpoint address
  * @param  pBuf pointer to the transmission buffer
  * @param  len amount of data to be sent
  * @retval HAL status
  *)
  PROCEDURE EP_Transmit*(hpcd: Handle; ep_addr: BYTE; buf: Def.BufferDesc; len: HALFWORD);

    PROCEDURE TransmitEP(hpcd: Handle; VAR ep: ll.EPDesc; ep_addr: BYTE; buf: Def.BufferDesc; len: HALFWORD);
    BEGIN (*setup and start the Xfer *)
      ep.xfer_buff := SYSTEM.ADR(buf) + SYSTEM.SIZE(Def.BufferDesc) + buf.offset; ep.xfer_len := len;
      ep.xfer_count := 0; ep.is_in := TRUE; ep.num := ep_addr MOD 10H;
      IF hpcd.Init.dma_enable THEN ep.dma_addr := ep.xfer_buff END;
      ll.EPStartXfer(hpcd.Instance, ep, hpcd.Init.dma_enable);
    END TransmitEP;

  BEGIN TransmitEP(hpcd, hpcd.IN_ep[ep_addr MOD 10H], ep_addr, buf, len)
  END EP_Transmit;

  (**
  * @brief  Set a STALL condition over an endpoint
  * @param  hpcd PCD handle
  * @param  ep_addr endpoint address
  * @retval HAL status
  *)
  PROCEDURE EP_SetStall*(hpcd: Handle; ep_addr: BYTE): BYTE;
    VAR ret: BYTE;
    PROCEDURE SetStallEP(hpcd: Handle; VAR ep: ll.EPDesc; ep_addr: BYTE; isIn: BOOLEAN);
    BEGIN ep.is_in := isIn; ep.is_stall := TRUE; ep.num := ep_addr MOD 10H;
      ll.EPSetStall(hpcd.Instance, ep);
      IF ep_addr MOD 10H = 0 THEN ll.EP0_OutStart(hpcd.Instance, hpcd.Init.dma_enable, SYSTEM.ADR(hpcd.Setup)) END
    END SetStallEP;
  BEGIN
    IF ep_addr MOD 10H > hpcd.Init.dev_endpoints THEN ret := ll.HAL_ERROR
    ELSE ret := ll.HAL_OK;
      IF 7 IN TOSET(ep_addr) THEN SetStallEP(hpcd, hpcd.IN_ep[ep_addr MOD 10H], ep_addr, TRUE)
      ELSE SetStallEP(hpcd, hpcd.OUT_ep[ep_addr MOD 10H], ep_addr, FALSE)
      END
    END

    RETURN ret
  END EP_SetStall;

(* @author  MCD Application Team
 * @brief   PCD Extended HAL module driver.*)

  (**
  * @brief  Set Tx FIFO
  * @param  hpcd PCD handle
  * @param  fifo The number of Tx fifo
  * @param  size Fifo size
  * @retval HAL status
  *)
  PROCEDURE SetTxFiFo*(pcd: Handle; fifo: BYTE; size: HALFWORD);
    VAR  Tx_Offset: INTEGER; i: BYTE;
  BEGIN
    (*  TXn min size = 16 words. (n  : Transmit FIFO index)
      When a TxFIFO is not used, the Configuration should be as follows:
          case 1 :  n > m    and Txn is not used    (n,m  : Transmit FIFO indexes)
         --> Txm can use the space allocated for Txn.
         case2  :  n < m    and Txn is not used    (n,m  : Transmit FIFO indexes)
         --> Txn should be configured with the minimum space of 16 words
     The FIFO is used optimally when used TxFIFOs are allocated in the top
         of the FIFO.Ex: use EP1 and EP2 as IN instead of EP1 and EP3 as IN ones.
     When DMA is used 3n * FIFO locations should be reserved for internal DMA registers *)
    Tx_Offset := pcd.Instance.GRXFSIZ;
    IF fifo = 0 THEN pcd.Instance.DIEPTXF0_HNPTXFSIZ := LSL(size, 16) + Tx_Offset
    ELSE INC(Tx_Offset, LSR(pcd.Instance.DIEPTXF0_HNPTXFSIZ, 16));
      FOR i := 0 TO fifo - 2 DO INC(Tx_Offset, LSR(pcd.Instance.DIEPTXF[i], 16)) END;
      (* Multiply Tx_Size by 2 to get higher performance *)
      pcd.Instance.DIEPTXF[fifo - 1] := LSL(size, 16) + Tx_Offset
    END
  END SetTxFiFo;

  (**
  * @brief  Set Rx FIFO
  * @param  hpcd PCD handle
  * @param  size Size of Rx fifo
  * @retval HAL status
  *)
  PROCEDURE SetRxFiFo*(pcd: Handle; size: HALFWORD);
  BEGIN pcd.Instance.GRXFSIZ := size
  END SetRxFiFo;

  (**
  * @brief  Initialize the pool of messages for each type of deferred work.
  * @param  hhcd HCD handle
  *)
  PROCEDURE InitPools*(hpcd: Handle);
  BEGIN
    hpcd.DataOutStageMP := Q.CreateSPool(1, SYSTEM.ADR(DOS), LEN(DOS), SYSTEM.SIZE(MsgDesc));
    hpcd.DataInStageMP := Q.CreateSPool(2, SYSTEM.ADR(DIS), LEN(DIS), SYSTEM.SIZE(MsgDesc));
    hpcd.SetupStageMP := Q.CreateSPool(3, SYSTEM.ADR(SS), LEN(SS), SYSTEM.SIZE(MsgDesc));
    hpcd.ISOOUTIncompleteMP := Q.CreateSPool(4, SYSTEM.ADR(IOUTI), LEN(IOUTI), SYSTEM.SIZE(MsgDesc));
    hpcd.ISOINIncompleteMP := Q.CreateSPool(5, SYSTEM.ADR(IINI), LEN(IINI), SYSTEM.SIZE(MsgDesc));
    hpcd.LPMMP := Q.CreateSPool(6, SYSTEM.ADR(LPM), LEN(LPM), SYSTEM.SIZE(MsgDesc));
    hpcd.ResumeMP := Q.CreateSPool(7, SYSTEM.ADR(RSM), LEN(RSM), SYSTEM.SIZE(MsgDesc));
    hpcd.SuspendMP := Q.CreateSPool(8, SYSTEM.ADR(S), LEN(S), SYSTEM.SIZE(MsgDesc));
    hpcd.ResetMP := Q.CreateSPool(9, SYSTEM.ADR(RST), LEN(RST), SYSTEM.SIZE(MsgDesc));
    hpcd.ConnectMP := Q.CreateSPool(10, SYSTEM.ADR(C), LEN(C), SYSTEM.SIZE(MsgDesc));
    hpcd.DisconnectMP := Q.CreateSPool(11, SYSTEM.ADR(D), LEN(D), SYSTEM.SIZE(MsgDesc));
    hpcd.DebugMP := Q.CreateSPool(12, SYSTEM.ADR(DBG), LEN(DBG), SYSTEM.SIZE(MsgDesc));
  END InitPools;

  PROCEDURE TakeMsg*(hpcd: Handle): Q.Msg;
    VAR msg!: Q.Msg;
  BEGIN msg := Q.ExhaustedPool();
    IF msg # NIL THEN Log.Error("Interrupt queue too small:");
      IF msg.type = 1 THEN Log.ErrorString(" DataOutStage")
      ELSIF  msg.type = 2 THEN Log.ErrorString(" DataInStage")
      ELSIF  msg.type = 3 THEN Log.ErrorString(" SetupStage")
      ELSIF  msg.type = 4 THEN Log.ErrorString(" ISOOUTIncomplete")
      ELSIF  msg.type = 5 THEN Log.ErrorString(" ISOINIncomplete")
      ELSIF  msg.type = 6 THEN Log.ErrorString(" LPM")
      ELSIF  msg.type = 7 THEN Log.ErrorString(" Resume")
      ELSIF  msg.type = 8 THEN Log.ErrorString(" Suspend")
      ELSIF  msg.type = 9 THEN Log.ErrorString(" Reset")
      ELSIF  msg.type = 10 THEN Log.ErrorString(" Connect")
      ELSIF  msg.type = 11 THEN Log.ErrorString(" Disconnect")
      ELSIF  msg.type = 22 THEN Log.ErrorString(" Debug")
      ELSE Log.ErrorString(" unknown message type")
      END; Log.ErrorLn; Log.Flush
    END;
    UH.DisableGlobalInt;
    IF hpcd.MsgPendQ # NIL THEN msg := Q.Get(hpcd.MsgPendQ) ELSE msg := NIL END;
    UH.EnableGlobalInt

    RETURN msg
  END TakeMsg;

  PROCEDURE GiveMsg*(hpcd: Handle; msg: Q.Msg);
  BEGIN UH.DisableGlobalInt;
    (*return item to pool*)
    IF msg.type = 1 THEN Q.PostFirst(hpcd.DataOutStageMP, msg)
    ELSIF msg.type = 2 THEN Q.PostFirst(hpcd.DataInStageMP, msg)
    ELSIF msg.type = 3 THEN Q.PostFirst(hpcd.SetupStageMP, msg)
    ELSIF msg.type = 4 THEN Q.PostFirst(hpcd.ISOOUTIncompleteMP, msg)
    ELSIF msg.type = 5 THEN Q.PostFirst(hpcd.ISOINIncompleteMP, msg)
    ELSIF msg.type = 6 THEN Q.PostFirst(hpcd.LPMMP, msg)
    ELSIF msg.type = 7 THEN Q.PostFirst(hpcd.ResumeMP, msg)
    ELSIF msg.type = 8 THEN Q.PostFirst(hpcd.SuspendMP, msg)
    ELSIF msg.type = 9 THEN Q.PostFirst(hpcd.ResetMP, msg)
    ELSIF msg.type = 10 THEN Q.PostFirst(hpcd.ConnectMP, msg)
    ELSIF msg.type = 11 THEN Q.PostFirst(hpcd.DisconnectMP, msg)
    ELSIF msg.type = 12 THEN Q.PostFirst(hpcd.DebugMP, msg)
    ELSE ASSERT(FALSE) (*unsupported message type*)
    END;
    UH.EnableGlobalInt
  END GiveMsg;

  PROCEDURE New*(): Handle;
    VAR h!: Handle;
  BEGIN NEW(h)

    RETURN h
  END New;

END HALPCD.
