MODULE HALHCD;
  (** The microcontroller specific part of the Host controller driver, ported to Oberon from:
  ******************************************************************************
  * @file    stm32f4xx_hal_hcd.h
  * @author  MCD Application Team
  * @brief   HCD HAL module.
  ******************************************************************************
  *)
  IMPORT SYSTEM, BSP, ll := LLUSB, Def := USBDef, Q := Queue, UC := HALUC, HDef := USBHDef, Log := USBLog;

  CONST
    STATE_READY* = 1;
    STATE_ERROR* = 2;
    STATE_BUSY* = 3;
    STATE_RESET* = 4;
    STATE_STARTED* = 5;

  TYPE
    Handle* = POINTER TO HandleDesc;
    Callback* = PROCEDURE^5(cdd: Handle);
    InitCallback* = PROCEDURE(hhcd: Handle);
    HandleDesc* = RECORD(HDef.HandleDesc)
      hc*: ARRAY 16 OF ll.HCDesc;     (*!< Host channels parameters *)
      State*: BYTE; (*!< HCD communication state *)
      ErrorCode*: INTEGER;  (*!< HCD Error code           *)
      SOFCallback*: Callback; (*!< USB OTG HCD SOF callback                *)
      ConnectMP, DisconnectMP, PortEnabledMP, PortDisabledMP,
      URBChangeMP, DebugMP*: Q.Msg; (*the pools of available IRQ messages*)
      MsgPendQ: Q.Msg (*the deferred work message queue*)
    END;

    (*!< USB OTG HCD Connect message *)
    ConnectMsg* = POINTER TO ConnectMsgDesc;
    ConnectMsgDesc* = RECORD(Q.MsgDesc) END;

    (*!< USB OTG HCD Disonnect message *)
    DisconnectMsg* = POINTER TO DisconnectMsgDesc;
    DisconnectMsgDesc* = RECORD(Q.MsgDesc) END;

    (*!< USB OTG HCD Port Enable message *)
    PortEnabledMsg* = POINTER TO PortEnabledMsgDesc;
    PortEnabledMsgDesc* = RECORD(Q.MsgDesc) END;

    (*!< USB OTG HCD Port Disable message *)
    PortDisabledMsg* = POINTER TO PortDisabledMsgDesc;
    PortDisabledMsgDesc* = RECORD(Q.MsgDesc) END;

    (*!< USB OTG HCD Host Channel Notify URB Change message *)
    URBChangeMsg* = POINTER TO URBChangeMsgDesc;
    URBChangeMsgDesc = RECORD(Q.MsgDesc) chnum*, urb_state*: BYTE END;

    (*!< USB debug message *)
    DebugMsg* = POINTER TO DebugMsgDesc;
    DebugMsgDesc* = RECORD(Q.MsgDesc)
      chnum*: BYTE; is_in*: BOOLEAN; gintsts*, grxstsp*, hcint*, hprt*: SET
    END;

    PROCEDURE newConnectMsg(): Q.Msg;
      VAR item!: ConnectMsg;
    BEGIN NEW(item)

      RETURN item
    END newConnectMsg;

    PROCEDURE newDisconnectMsg(): Q.Msg;
      VAR item!: DisconnectMsg;
    BEGIN NEW(item)

      RETURN item
    END newDisconnectMsg;

    PROCEDURE newPortEnabledMsg(): Q.Msg;
      VAR item!: PortEnabledMsg;
    BEGIN NEW(item)

      RETURN item
    END newPortEnabledMsg;

    PROCEDURE newPortDisabledMsg(): Q.Msg;
      VAR item!: PortDisabledMsg;
    BEGIN NEW(item)

      RETURN item
    END newPortDisabledMsg;

    PROCEDURE newURBChangeMsg(): Q.Msg;
      VAR item!: URBChangeMsg;
    BEGIN NEW(item)

      RETURN item
    END newURBChangeMsg;

    PROCEDURE newDebugMsg(): Q.Msg; (*create a debug message object*)
      VAR item!: DebugMsg;
    BEGIN NEW(item)

      RETURN item
    END newDebugMsg;

  (** @defgroup HCD_Exported_Functions_Group2 Input and Output operation functions
  *  @brief   HCD IO operation functions
  *
  @verbatim
   ===============================================================================
                      ##### IO operation functions #####
   ===============================================================================
   [..] This subsection provides a set of functions allowing to manage the USB Host Data
      Transfer

  @endverbatim
  * @{
  *)
  (**
  * @brief  Submit a new URB for processing.
  * @param  hhcd HCD handle
  * @param  ch_num Channel number.
  *         This parameter can be a value from 1 to 15
  * @param  direction Channel number.
  *          This parameter can be one of these values:
  *           0 : Output / 1 : Input
  * @param  ep_type Endpoint Type.
  *          This parameter can be one of these values:
  *            EP_TYPE_CTRL: Control type/
  *            EP_TYPE_ISOC: Isochronous type/
  *            EP_TYPE_BULK: Bulk type/
  *            EP_TYPE_INTR: Interrupt type/
  * @param  token Endpoint Type.
  *          This parameter can be one of these values:
  *            0: HC_PID_SETUP / 1: HC_PID_DATA1
  * @param  pbuff pointer to URB data
  * @param  length Length of URB data
  * @param  do_ping activate do ping protocol (for high speed only).
  *          This parameter can be one of these values:
  *           0 : do ping inactive / 1 : do ping active
  * @retval HAL status
  *)
  PROCEDURE HC_SubmitRequest*(hhcd: Handle; ch_num: BYTE; direction: BOOLEAN;
    ep_type, token: BYTE; buff: Def.Buffer; length: HALFWORD; do_ping: BOOLEAN);
  BEGIN hhcd.hc[ch_num].ep_is_in := direction; hhcd.hc[ch_num].ep_type := ep_type;
    IF token = 0 THEN hhcd.hc[ch_num].data_pid := ll.HC_PID_SETUP;
      hhcd.hc[ch_num].do_ping := do_ping
    ELSE hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA1
    END;
    (* Manage Data Toggle *)
    IF ep_type = Def.EP_TYPE_CTRL THEN
      IF token = 1 THEN (* send data *)
        IF ~direction THEN
          IF length = 0 THEN (* For Status OUT stage, Length == 0U, Status Out PID = 1 *)
            hhcd.hc[ch_num].toggle_out := TRUE;
          END;
          (* Set the Data Toggle bit as per the Flag *)
          IF ~hhcd.hc[ch_num].toggle_out THEN hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA0 (* Put the PID 0 *)
          ELSE hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA1 (* Put the PID 1 *)
          END
        ELSIF hhcd.hc[ch_num].do_ssplit THEN
          IF ~hhcd.hc[ch_num].toggle_in THEN hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA0
          ELSE hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA1
          END
        END
      END
    ELSIF ep_type = Def.EP_TYPE_BULK THEN
      IF ~direction THEN (* Set the Data Toggle bit as per the Flag *)
        IF ~hhcd.hc[ch_num].toggle_out THEN hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA0 (* Put the PID 0 *)
        ELSE hhcd.hc[ch_num].data_pid := ll. HC_PID_DATA1 (* Put the PID 1 *)
        END
      ELSIF ~hhcd.hc[ch_num].toggle_in THEN hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA0
      ELSE hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA1
      END
    ELSIF ep_type = Def.EP_TYPE_INTR THEN
      IF ~direction THEN (* Set the Data Toggle bit as per the Flag *)
        IF ~hhcd.hc[ch_num].toggle_out THEN hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA0 (* Put the PID 0 *)
        ELSE hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA1 (* Put the PID 1 *)
        END
      ELSIF ~hhcd.hc[ch_num].toggle_in THEN hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA0
      ELSE hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA1
      END
    ELSIF ep_type = Def.EP_TYPE_ISOC THEN hhcd.hc[ch_num].data_pid := ll.HC_PID_DATA0
    END;
    IF ~(length <= buff.size) THEN
      Log.Error("length: "); Log.ErrorInt(length, 1); Log.ErrorString(", buff.size: "); Log.ErrorInt(buff.size, 1);
      Log.ErrorLn; Log.Flush
    END;
    ASSERT(length <= buff.size);
    hhcd.hc[ch_num].xfer_buff := SYSTEM.ADR(buff) + SYSTEM.SIZE(Def.Buffer);
    hhcd.hc[ch_num].xfer_len := length;
    hhcd.hc[ch_num].urb_state := Def.IDLE; hhcd.hc[ch_num].xfer_count := 0;
    hhcd.hc[ch_num].ch_num := ch_num; hhcd.hc[ch_num].state := Def.IDLE;
    ll.HC_StartXfer(hhcd.Instance, hhcd.hc[ch_num], hhcd.Init.dma_enable)
  END HC_SubmitRequest;

  (**
  * @brief  Handle Host Port interrupt requests.
  * @param  hhcd HCD handle
  * @retval None
  *)
  PROCEDURE Port_IRQHandler(hhcd: Handle; dbm: DebugMsg);
  VAR res: BYTE; hprt0, hprt0_dup, fslspcs: SET; USBx_HOST!: ll.OTGHostMode;
    msg!: Q.Msg;
  BEGIN USBx_HOST := SYSTEM.VAL(ll.OTGHostMode, ORD(hhcd.Instance) + ll.HOST_BASE);
    (* Handle Host Port Interrupts *)
    SYSTEM.GET(ORD(hhcd.Instance) + ll.HOST_PORT_BASE, hprt0);
    IF dbm # NIL THEN dbm.hprt := hprt0 END;
    hprt0_dup := hprt0 - {ll.HPRT_PENA, ll.HPRT_PCDET, ll.HPRT_PENCHNG, ll.HPRT_POCCHNG};
    (* Check whether Port Connect detected *)
    IF ll.HPRT_PCDET IN hprt0 THEN
      IF ll.HPRT_PCSTS IN hprt0 THEN msg := Q.Get(hhcd.ConnectMP); (*post message for deferred processing*)
        IF msg # NIL THEN Q.Post(hhcd.MsgPendQ, msg) END
      END;
      INCL(hprt0_dup, ll.HPRT_PCDET)
    END;
    (* Check whether Port Enable Changed *)
    IF ll.HPRT_PENCHNG IN hprt0 THEN
      INCL(hprt0_dup, ll.HPRT_PENCHNG);
      IF ll.HPRT_PENA IN hprt0 THEN
        IF hhcd.Init.phy_itface = ll.EMBEDDED_PHY THEN
          IF hprt0*ll.HPRT_PSPD_Msk = ll.HPRT_PSPD_LOW_SPEED THEN
            fslspcs := ll.HCFG_6_MHZ
          ELSE fslspcs := ll.HCFG_48_MHZ
          END;
          res := ll.InitFSLSPClkSel(hhcd.Instance, fslspcs)
        ELSIF hhcd.Init.speed = Def.SPEED_FULL THEN USBx_HOST.HFIR := ll.HFIR_60_MHZ
        END;
        ll.SetXFSIZ(hhcd.Instance); (*workaround channel hang with CHDIS and CHENA set*)
        msg := Q.Get(hhcd.PortEnabledMP); IF msg # NIL THEN Q.Post(hhcd.MsgPendQ, msg) END
      ELSE msg := Q.Get(hhcd.PortDisabledMP); IF msg # NIL THEN Q.Post(hhcd.MsgPendQ, msg) END
      END
    END;
    (* Check for an overcurrent *)
    IF ll.HPRT_POCCHNG IN hprt0 THEN INCL(hprt0_dup, ll.HPRT_POCCHNG) END;
    SYSTEM.PUT(ORD(hhcd.Instance) + ll.HOST_PORT_BASE, hprt0_dup) (* Clear Port Interrupts *)
  END Port_IRQHandler;

  (**
  * @brief  Handle Host Channel IN interrupt requests.
  * @param  hhcd HCD handle
  * @param  chnum Channel number.
  *         This parameter can be a value from 1 to 15
  * @retval none
  *)
  PROCEDURE HC_IN_IRQHandler(hhcd: Handle; chnum: BYTE; dbm: DebugMsg);
    VAR USBx_HCi!: ll.OTGHostChannel; flags: SET;
      msg!: Q.Msg;
  BEGIN USBx_HCi := SYSTEM.VAL(ll.OTGHostChannel, ORD(hhcd.Instance) + ll.HOST_CHANNEL_BASE + chnum*ll.HOST_CHANNEL_SIZE);
    flags := ll.ReadChInterrupts(hhcd.Instance, chnum);
    IF dbm # NIL THEN dbm.hcint := flags; dbm.chnum := chnum; dbm.is_in := TRUE END;
    IF ll.HCINT_AHBERR IN flags THEN USBx_HCi.HCINT := {ll.HCINT_AHBERR};
      hhcd.hc[chnum].state := ll.HC_XACTERR; ll.HC_Halt(hhcd.Instance, chnum)
    ELSIF ll.HCINT_BBERR IN flags THEN USBx_HCi.HCINT := {ll. HCINT_BBERR};
      hhcd.hc[chnum].state := ll.HC_BBLERR; ll.HC_Halt(hhcd.Instance, chnum)
    ELSIF ll.HCINT_STALL IN flags THEN USBx_HCi.HCINT := {ll.HCINT_STALL};
      hhcd.hc[chnum].state := ll.HC_STALL; ll.HC_Halt(hhcd.Instance, chnum)
    ELSIF ll.HCINT_DTERR IN flags THEN USBx_HCi.HCINT := {ll.HCINT_DTERR};
      hhcd.hc[chnum].state := ll.HC_DATATGLERR; ll.HC_Halt(hhcd.Instance, chnum)
    ELSIF ll.HCINT_TXERR IN flags THEN USBx_HCi.HCINT := {ll.HCINT_TXERR};
      hhcd.hc[chnum].state := ll.HC_XACTERR; ll.HC_Halt(hhcd.Instance, chnum)
    END;
    IF ll. HCINT_FRMOR IN flags THEN  ll.HC_Halt(hhcd.Instance, chnum);
      USBx_HCi.HCINT := {ll.HCINT_FRMOR};
    ELSIF ll.HCINT_XFRC IN flags THEN
      USBx_HCi.HCINT := {ll.HCINT_ACK}; (* Clear any pending ACK IT *)
      IF hhcd.hc[chnum].do_csplit THEN hhcd.hc[chnum].do_csplit := FALSE;
        EXCL(USBx_HCi.HCSPLT, ll.HCSPLT_SPLITEN)
      END;
      IF hhcd.Init.dma_enable THEN
        hhcd.hc[chnum].xfer_count := hhcd.hc[chnum].XferSize - ORD(USBx_HCi.HCTSIZ*ll.HCTSIZ_XFRSIZ_Msk)
      END;
      hhcd.hc[chnum].state := ll.HC_XFRC; hhcd.hc[chnum].ErrCnt := 0;
      USBx_HCi.HCINT := {ll.HCINT_XFRC};
      IF hhcd.hc[chnum].ep_type IN {Def.EP_TYPE_CTRL, Def.EP_TYPE_BULK} THEN ll.HC_Halt(hhcd.Instance, chnum);
        USBx_HCi.HCINT := {ll.HCINT_NAK}
      ELSIF hhcd.hc[chnum].ep_type IN {Def.EP_TYPE_INTR, Def.EP_TYPE_ISOC} THEN
        INCL(USBx_HCi.HCCHAR, ll.HCCHAR_ODDFRM);
        hhcd.hc[chnum].urb_state := ll.URB_DONE;
        msg := Q.Get(hhcd.URBChangeMP);
        IF msg # NIL THEN
          CASE msg OF URBChangeMsg: msg.chnum := chnum; msg.urb_state := hhcd.hc[chnum].urb_state END;
          Q.Post(hhcd.MsgPendQ, msg)
        END
      END;
      IF hhcd.Init.dma_enable THEN
        IF ODD((hhcd.hc[chnum].xfer_count + hhcd.hc[chnum].max_packet - 1) DIV hhcd.hc[chnum].max_packet) THEN
          hhcd.hc[chnum].toggle_in := ~hhcd.hc[chnum].toggle_in
        END
      ELSE hhcd.hc[chnum].toggle_in := ~hhcd.hc[chnum].toggle_in
      END
    ELSIF ll.HCINT_ACK IN flags THEN USBx_HCi.HCINT := {ll.HCINT_ACK};
      IF hhcd.hc[chnum].do_ssplit THEN hhcd.hc[chnum].do_csplit := TRUE;
        hhcd.hc[chnum].state := ll.HC_ACK; ll.HC_Halt(hhcd.Instance, chnum)
      END
    ELSIF ll.HCINT_CHH IN flags THEN USBx_HCi.HCINT := {ll.HCINT_CHH};
      IF hhcd.hc[chnum].state = ll.HC_XFRC THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        hhcd.hc[chnum].urb_state := ll.URB_DONE
      ELSIF hhcd.hc[chnum].state = ll.HC_STALL THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        hhcd.hc[chnum].urb_state := ll.URB_STALL
      ELSIF hhcd.hc[chnum].state IN {ll.HC_XACTERR, ll.HC_DATATGLERR} THEN
        hhcd.hc[chnum].state := ll.HC_HALTED;
        INC(hhcd.hc[chnum].ErrCnt);
        IF hhcd.hc[chnum].ErrCnt > 2 THEN hhcd.hc[chnum].ErrCnt := 0;
          IF hhcd.hc[chnum].do_ssplit THEN hhcd.hc[chnum].do_csplit := FALSE;
            hhcd.hc[chnum].ep_ss_schedule := FALSE; EXCL(USBx_HCi.HCSPLT, ll.HCSPLT_COMPLSPLT)
          END;
          hhcd.hc[chnum].urb_state := ll.URB_ERROR
        ELSE hhcd.hc[chnum].urb_state := ll.URB_NOTREADY;
          IF hhcd.hc[chnum].ep_type IN {Def.EP_TYPE_CTRL, Def.EP_TYPE_BULK} THEN
            USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - {ll.HCCHAR_CHDIS} + {ll.HCCHAR_CHENA} (* re-activate the channel *)
          END
        END
      ELSIF hhcd.hc[chnum].state = ll.HC_NYET THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        IF hhcd.hc[chnum].do_csplit THEN
          IF hhcd.hc[chnum].ep_type = Def.EP_TYPE_INTR THEN INC(hhcd.hc[chnum].NyetErrCnt);
            IF hhcd.hc[chnum].NyetErrCnt > 2 THEN hhcd.hc[chnum].NyetErrCnt := 0;
              hhcd.hc[chnum].do_csplit := FALSE;
              IF hhcd.hc[chnum].ErrCnt < 3 THEN hhcd.hc[chnum].ep_ss_schedule := TRUE END;
              EXCL(USBx_HCi.HCSPLT, ll.HCSPLT_COMPLSPLT);
              hhcd.hc[chnum].urb_state := ll.URB_ERROR
            ELSE hhcd.hc[chnum].urb_state := ll.URB_NOTREADY
            END
          ELSE hhcd.hc[chnum].urb_state := ll.URB_NOTREADY
          END;
          IF hhcd.hc[chnum].ep_type IN {Def.EP_TYPE_CTRL, Def.EP_TYPE_BULK} THEN
            USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - {ll.HCCHAR_CHDIS} + {ll.HCCHAR_CHENA} (* re-activate the channel *)
          END
        END
      ELSIF hhcd.hc[chnum].state = ll.HC_ACK THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        IF hhcd.hc[chnum].do_csplit THEN hhcd.hc[chnum].urb_state := ll.URB_NOTREADY;
          (* Set Complete split and re-activate the channel *)
          INCL(USBx_HCi.HCSPLT, ll.HCSPLT_COMPLSPLT);
          INCL(USBx_HCi.HCINTMSK, ll.HCINTMSK_NYET);
          EXCL(USBx_HCi.HCINTMSK, ll.HCINT_ACK);
          IF hhcd.hc[chnum].ep_type IN {Def.EP_TYPE_CTRL, Def.EP_TYPE_BULK} THEN
            USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - {ll.HCCHAR_CHDIS} + {ll.HCCHAR_CHENA} (* re-activate the channel *)
          END
        END
      ELSIF hhcd.hc[chnum].state = ll.HC_NAK THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        hhcd.hc[chnum].urb_state := ll.URB_NOTREADY;
        IF hhcd.hc[chnum].ep_type IN {Def.EP_TYPE_CTRL, Def.EP_TYPE_BULK} THEN
          USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - {ll.HCCHAR_CHDIS} + {ll.HCCHAR_CHENA} (* re-activate the channel *)
        END
      ELSIF hhcd.hc[chnum].state = ll.HC_BBLERR THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        INC(hhcd.hc[chnum].ErrCnt); hhcd.hc[chnum].urb_state := ll.URB_ERROR
      ELSIF hhcd.hc[chnum].state # ll.HC_HALTED THEN
        msg := Q.Get(hhcd.URBChangeMP);
        IF msg # NIL THEN
          CASE msg OF URBChangeMsg: msg.chnum := chnum; msg.urb_state := hhcd.hc[chnum].urb_state END;
          Q.Post(hhcd.MsgPendQ, msg)
        END
      END
    ELSIF ll.HCINT_NYET IN flags THEN USBx_HCi.HCINT := {ll.HCINT_NYET};
      hhcd.hc[chnum].state := ll.HC_NYET;
      IF ~hhcd.hc[chnum].do_ssplit THEN hhcd.hc[chnum].ErrCnt := 0 END;
      ll.HC_Halt(hhcd.Instance, chnum)
    ELSIF ll.HCINT_NAK IN flags THEN
      IF hhcd.hc[chnum].ep_type = Def.EP_TYPE_INTR THEN
        hhcd.hc[chnum].ErrCnt := 0; hhcd.hc[chnum].state := ll.HC_NAK;
        ll.HC_Halt(hhcd.Instance, chnum)
      ELSIF hhcd.hc[chnum].ep_type IN {Def.EP_TYPE_CTRL, Def.EP_TYPE_BULK} THEN
        hhcd.hc[chnum].ErrCnt := 0;
        IF ~ hhcd.Init.dma_enable OR hhcd.hc[chnum].do_csplit THEN hhcd.hc[chnum].state := ll.HC_NAK;
          ll.HC_Halt(hhcd.Instance, chnum)
        END
      END;
      IF hhcd.hc[chnum].do_csplit THEN hhcd.hc[chnum].do_csplit := FALSE;
        EXCL(USBx_HCi.HCSPLT, ll.HCSPLT_COMPLSPLT); INCL(USBx_HCi.HCINTMSK, ll.HCINTMSK_ACKM);
      END;
      USBx_HCi.HCINT := {ll.HCINT_NAK};
    END
  END HC_IN_IRQHandler;

  (**
  * @brief  Handle Host Channel OUT interrupt requests.
  * @param  hhcd HCD handle
  * @param  chnum Channel number.
  *         This parameter can be a value from 1 to 15
  * @retval none
  *)
  PROCEDURE HC_OUT_IRQHandler(hhcd: Handle; chnum: BYTE; dbm: DebugMsg);
    VAR USBx_HCi!: ll.OTGHostChannel; flags: SET; num_packets: INTEGER; purbs: BYTE;
      msg!: Q.Msg;
  BEGIN USBx_HCi := SYSTEM.VAL(ll.OTGHostChannel, ORD(hhcd.Instance) + ll.HOST_CHANNEL_BASE + chnum*ll.HOST_CHANNEL_SIZE);
    flags := ll.ReadChInterrupts(hhcd.Instance, chnum);
    IF dbm # NIL THEN dbm.hcint := flags; dbm.chnum := chnum END;
    IF ll.HCINT_AHBERR IN flags THEN USBx_HCi.HCINT := {ll.HCINT_AHBERR};
      hhcd.hc[chnum].state := ll.HC_XACTERR; ll.HC_Halt(hhcd.Instance, chnum)
    ELSIF ll.HCINT_ACK IN flags THEN USBx_HCi.HCINT := {ll.HCINT_ACK};
      IF hhcd.hc[chnum].do_ping THEN hhcd.hc[chnum].do_ping := FALSE;
        hhcd.hc[chnum].urb_state := ll.URB_NOTREADY; hhcd.hc[chnum].state := ll.HC_ACK;
        ll.HC_Halt(hhcd.Instance, chnum)
      END;
      IF hhcd.hc[chnum].do_ssplit & ~hhcd.hc[chnum].do_csplit THEN
        IF hhcd.hc[chnum].ep_type # Def.EP_TYPE_ISOC THEN hhcd.hc[chnum].do_csplit := TRUE END;
        hhcd.hc[chnum].state := ll.HC_ACK; ll.HC_Halt(hhcd.Instance, chnum);
        hhcd.hc[chnum].ErrCnt := 0; (* reset error_count *)
      END
    ELSIF ll.HCINT_FRMOR IN flags THEN USBx_HCi.HCINT := {ll.HCINT_FRMOR};
      ll.HC_Halt(hhcd.Instance, chnum)
    ELSIF ll.HCINT_XFRC IN flags THEN hhcd.hc[chnum].ErrCnt := 0;
      (* transaction completed with NYET state, update do ping state *)
      IF ll.HCINT_NYET IN flags THEN hhcd.hc[chnum].do_ping := TRUE;
        USBx_HCi.HCINT := {ll.HCINT_NYET}
      END;
      IF hhcd.hc[chnum].do_csplit THEN hhcd.hc[chnum].do_csplit := FALSE;
        EXCL(USBx_HCi.HCSPLT, ll.HCSPLT_COMPLSPLT)
      END;
      USBx_HCi.HCINT := {ll.HCINT_XFRC}; hhcd.hc[chnum].state := ll.HC_XFRC;
      ll.HC_Halt(hhcd.Instance, chnum);
    ELSIF ll.HCINT_NYET IN flags THEN hhcd.hc[chnum].state := ll.HC_NYET;
      IF ~hhcd.hc[chnum].do_ssplit THEN hhcd.hc[chnum].do_ping := TRUE END;
      hhcd.hc[chnum].ErrCnt := 0; ll.HC_Halt(hhcd.Instance, chnum);
      USBx_HCi.HCINT := {ll.HCINT_NYET}
    ELSIF ll.HCINT_STALL IN flags THEN USBx_HCi.HCINT := {ll.HCINT_STALL};
      hhcd.hc[chnum].state := ll.HC_STALL; ll.HC_Halt(hhcd.Instance, chnum);
    ELSIF ll.HCINT_NAK IN flags THEN hhcd.hc[chnum].ErrCnt := 0;
      hhcd.hc[chnum].state := ll.HC_NAK;
      IF ~hhcd.hc[chnum].do_ping & (hhcd.hc[chnum].speed = Def.SPEED_HIGH) THEN
        hhcd.hc[chnum].do_ping := TRUE
      END;
      ll.HC_Halt(hhcd.Instance, chnum); USBx_HCi.HCINT := {ll.HCINT_NAK};
    ELSIF ll.HCINT_TXERR IN flags THEN
      IF ~hhcd.Init.dma_enable THEN hhcd.hc[chnum].state := ll.HC_XACTERR;
        ll.HC_Halt(hhcd.Instance, chnum)
      ELSE INC(hhcd.hc[chnum].ErrCnt);
        IF hhcd.hc[chnum].ErrCnt > 2 THEN hhcd.hc[chnum].ErrCnt := 0;
          hhcd.hc[chnum].urb_state := ll.URB_ERROR;
          msg := Q.Get(hhcd.URBChangeMP);
          IF msg # NIL THEN
            CASE msg OF URBChangeMsg: msg.chnum := chnum; msg.urb_state := hhcd.hc[chnum].urb_state END;
            Q.Post(hhcd.MsgPendQ, msg)
          END
        ELSE
          hhcd.hc[chnum].urb_state := ll.URB_NOTREADY;
          USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - {ll.HCCHAR_CHDIS} + {ll.HCCHAR_CHENA} (* re-activate the channel *)
        END
      END;
      USBx_HCi.HCINT := {ll.HCINT_TXERR}
    ELSIF ll.HCINT_DTERR IN flags THEN hhcd.hc[chnum].state := ll.HC_DATATGLERR;
      ll.HC_Halt(hhcd.Instance, chnum); USBx_HCi.HCINT := {ll.HCINT_DTERR}
    ELSIF ll.HCINT_CHH IN flags THEN  USBx_HCi.HCINT := {ll.HCINT_CHH};
      purbs := hhcd.hc[chnum].urb_state;
      IF hhcd.hc[chnum].state = ll.HC_XFRC THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        hhcd.hc[chnum].urb_state := ll.URB_DONE;
        IF hhcd.hc[chnum].ep_type IN {Def.EP_TYPE_BULK, Def.EP_TYPE_INTR} THEN
          IF ~hhcd.Init.dma_enable THEN hhcd.hc[chnum].toggle_out := ~hhcd.hc[chnum].toggle_out END;
          IF hhcd.Init.dma_enable & (hhcd.hc[chnum].xfer_len > 0) THEN
            num_packets := (hhcd.hc[chnum].xfer_len + hhcd.hc[chnum].max_packet - 1) DIV hhcd.hc[chnum].max_packet;
            IF ODD(num_packets) THEN hhcd.hc[chnum].toggle_out := ~hhcd.hc[chnum].toggle_out END
          END
        END
      ELSIF hhcd.hc[chnum].state = ll.HC_ACK THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        IF hhcd.hc[chnum].do_csplit THEN hhcd.hc[chnum].urb_state := ll.URB_NOTREADY END;
      ELSIF hhcd.hc[chnum].state = ll.HC_NAK THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        hhcd.hc[chnum].urb_state := ll.URB_NOTREADY;
        IF hhcd.hc[chnum].do_csplit THEN hhcd.hc[chnum].do_csplit := FALSE;
          EXCL(USBx_HCi.HCSPLT, ll.HCSPLT_COMPLSPLT)
        END
      ELSIF hhcd.hc[chnum].state = ll.HC_NYET THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        hhcd.hc[chnum].urb_state  := ll.URB_NOTREADY
      ELSIF hhcd.hc[chnum].state = ll.HC_STALL THEN hhcd.hc[chnum].state := ll.HC_HALTED;
        hhcd.hc[chnum].urb_state := ll.URB_STALL
      ELSIF hhcd.hc[chnum].state IN {ll.HC_XACTERR, ll.HC_DATATGLERR} THEN
        hhcd.hc[chnum].state := ll.HC_HALTED; INC(hhcd.hc[chnum].ErrCnt);
        IF hhcd.hc[chnum].ErrCnt > 2 THEN hhcd.hc[chnum].ErrCnt := 0;
          hhcd.hc[chnum].urb_state := ll.URB_ERROR
        ELSE hhcd.hc[chnum].urb_state := ll.URB_NOTREADY;
          USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - {ll.HCCHAR_CHDIS} + {ll.HCCHAR_CHENA} (* re-activate the channel *)
        END
      END;
      (*in STM original code, hhcd.HC_NotifyURBChangeCallback in called only if one of the previous cases match*)
      IF hhcd.hc[chnum].urb_state # purbs THEN
        msg := Q.Get(hhcd.URBChangeMP);
        IF msg # NIL THEN
          CASE msg OF URBChangeMsg: msg.chnum := chnum; msg.urb_state := hhcd.hc[chnum].urb_state END;
          Q.Post(hhcd.MsgPendQ, msg)
        END
      END
    END;
  END HC_OUT_IRQHandler;

  (**
  * @brief  Handle Rx Queue Level interrupt requests.
  * @param  hhcd HCD handle
  * @retval none
  *)
  PROCEDURE RXQLVL_IRQHandler(hhcd: Handle; dbm: DebugMsg);
    VAR USBx_HCi!: ll.OTGHostChannel;
      GrxstspReg, pktsts: SET; bytecnt, xferSizePktCnt, res: INTEGER; chnum: BYTE;
  BEGIN (*WARNING: GRXSTSP must be read only once, because reading it pops one item from input FIFO*)
    GrxstspReg := hhcd.Instance.GRXSTSP;
    IF dbm # NIL THEN dbm.grxstsp := GrxstspReg END;
    chnum := ORD(GrxstspReg*ll.GRXSTSP_EPNUM_Msk);
    pktsts := GrxstspReg*ll.GRXSTSP_PKTSTS_Msk;
    bytecnt := LSR(ORD(GrxstspReg*ll.GRXSTSP_BCNT_Msk), 4);
    USBx_HCi := SYSTEM.VAL(ll.OTGHostChannel, ORD(hhcd.Instance) + ll.HOST_CHANNEL_BASE + chnum*ll.HOST_CHANNEL_SIZE);
    IF pktsts = ll.GRXSTS_PKTSTS_IN THEN
      (* Read the data into the host buffer. *)
      IF (bytecnt > 0) & (hhcd.hc[chnum].xfer_buff # 0) THEN
        IF hhcd.hc[chnum].xfer_count + bytecnt <= hhcd.hc[chnum].xfer_len THEN
          res := ll.ReadPacket(hhcd.Instance, hhcd.hc[chnum].xfer_buff, bytecnt);
          (* manage multiple Xfer *)
          INC(hhcd.hc[chnum].xfer_buff, bytecnt); INC(hhcd.hc[chnum].xfer_count, bytecnt);
          (* get transfer size packet count *)
          xferSizePktCnt := LSR(ORD(USBx_HCi.HCTSIZ*ll.HCTSIZ_PKTCNT_Msk), 19);
          IF (hhcd.hc[chnum].max_packet = bytecnt) & (xferSizePktCnt > 0) THEN
            (* re-activate the channel when more packets are expected *)
            USBx_HCi.HCCHAR := USBx_HCi.HCCHAR - {ll.HCCHAR_CHDIS} + {ll.HCCHAR_CHENA};
            hhcd.hc[chnum].toggle_in := ~hhcd.hc[chnum].toggle_in;
          END
        ELSE hhcd.hc[chnum].urb_state := ll.URB_ERROR
        END
      END
    END
  END RXQLVL_IRQHandler;

  (**
  * @brief  Handle HCD interrupt request.
  * @param  hhcd HCD handle
  * @retval None
  *)
  PROCEDURE IRQHandler*(hhcd: UC.Handle);
    VAR i: INTEGER; interrupt, flags, reg: SET; res: BYTE;
      msg!: Q.Msg; dbm!: DebugMsg;
  BEGIN BSP.ledsOnOff({4}, {});
    CASE hhcd OF
      Handle:
        flags := ll.ReadInterrupts(hhcd.Instance); dbm := NIL;
(*
        IF flags # {ll.GINTSTS_SOF} THEN msg := Q.Get(hhcd.DebugMP);
          IF msg # NIL THEN dbm := msg(DebugMsg); CLEAR(dbm^); dbm.chnum := 0FFH;
            dbm.gintsts := flags
          END
        END;
*)
        (* Ensure that we are in host mode *)
        IF ll.IsHost(hhcd.Instance) & (flags # {}) (* Avoid spurious interrupt *) THEN
          IF ll.GINTSTS_PXFR_INCOMPISOOUT IN flags THEN (* Incomplete periodic transfer, acknowledge the interrupt *)
            hhcd.Instance.GINTSTS := {ll.GINTSTS_PXFR_INCOMPISOOUT}
          END;
          IF ll.GINTSTS_IISOIXFR IN flags THEN (* Incomplete isochronous IN transfer acknowledge the interrupt *)
            hhcd.Instance.GINTSTS := {ll.GINTSTS_IISOIXFR}
          END;
          IF ll.GINTSTS_PTXFE IN flags THEN (* Periodic TxFIFO empty, acknowledge the interrupt *)
            hhcd.Instance.GINTSTS := {ll.GINTSTS_PTXFE}
          END;
          (* Handle Host Disconnect Interrupts *)
          IF ll.GINTSTS_DISCINT IN flags THEN
            hhcd.Instance.GINTSTS := {ll.GINTSTS_DISCINT};
            SYSTEM.GET(ORD(hhcd.Instance) + ll.HOST_PORT_BASE, reg);
            IF ~(ll.HPRT_PCSTS IN reg) THEN
              res := ll.FlushTxFifo(hhcd.Instance, 10H); res := ll.FlushRxFifo(hhcd.Instance); (* Flush USB Fifo *)
              IF hhcd.Init.phy_itface = ll.EMBEDDED_PHY THEN
                res := ll.InitFSLSPClkSel(hhcd.Instance, ll.HCFG_48_MHZ) (* Restore FS Clock *)
              END;
              msg := Q.Get(hhcd.DisconnectMP); (* Handle Host Port Disconnect Interrupt *)
              IF msg # NIL THEN Q.Post(hhcd.MsgPendQ, msg) END
            END
          END;
          IF ll.GINTSTS_HPRTINT IN flags THEN Port_IRQHandler(hhcd, dbm) END; (* Handle Host Port Interrupts *)
          (* Handle Host SOF Interrupt *)
          IF ll.GINTSTS_SOF IN flags THEN hhcd.SOFCallback(hhcd); hhcd.Instance.GINTSTS := {ll.GINTSTS_SOF} END;
          (* Handle Host channel Interrupt *)
          IF ll.GINTSTS_HCINT IN flags THEN interrupt := ll.HC_ReadInterrupt(hhcd.Instance);
            ASSERT(hhcd.Init.Host_channels <= 12);
            FOR i := 0 TO hhcd.Init.Host_channels - 1 DO
              IF i MOD 10H IN interrupt THEN
                SYSTEM.GET(ORD(hhcd.Instance) + ll.HOST_CHANNEL_BASE + i*ll.HOST_CHANNEL_SIZE, reg);
                IF ll.HCCHAR_EPDIR IN reg THEN HC_IN_IRQHandler(hhcd, i, dbm) ELSE HC_OUT_IRQHandler(hhcd, i, dbm) END
              END
            END;
            hhcd.Instance.GINTSTS := {ll.GINTSTS_HCINT};
          END;
          (* Handle Rx Queue Level Interrupts *)
          IF ll.GINTSTS_RXFLVL IN flags THEN EXCL(hhcd.Instance.GINTMSK, ll.GINTSTS_RXFLVL);
            RXQLVL_IRQHandler(hhcd, dbm); INCL(hhcd.Instance.GINTMSK, ll.GINTSTS_RXFLVL)
          END
        END;
        IF dbm # NIL THEN Q.Post(hhcd.MsgPendQ, dbm) END
    | UC.Handle: ASSERT(FALSE)
    END;
    BSP.ledsOnOff({}, {4});
  END IRQHandler;

  (**
  * @brief  Initialize the host driver.
  * @param  hhcd HCD handle
  * @retval HAL status
  *)
  PROCEDURE Init*(hhcd: Handle): BYTE;
    VAR res: BYTE;
  BEGIN
    (* Check the HCD handle allocation *)
    IF hhcd = NIL THEN res := ll.HAL_ERROR
    ELSE
      hhcd.State := STATE_BUSY;
      (* Init Host *) ASSERT(hhcd.ControllerIRQHandler # NIL);
      IF ll.HostInit(hhcd.Instance, hhcd.Init) # ll.HAL_OK THEN
        hhcd.State := STATE_ERROR; res := ll.HAL_ERROR
      ELSE hhcd.State := STATE_READY; res := ll.HAL_OK
      END
    END

    RETURN res
  END Init;

(**
  * @brief  Clear host channel hub information.
  * @param  hhcd HCD handle
  * @param  ch_num Channel number.
  *         This parameter can be a value from 1 to 15
  * @retval HAL status
  *)
  PROCEDURE HC_ClearHubInfo*(hhcd: Handle; ch_num: BYTE);
  BEGIN hhcd.hc[ch_num].do_ssplit := FALSE; hhcd.hc[ch_num].do_csplit := FALSE;
    hhcd.hc[ch_num].hub_addr := 0; hhcd.hc[ch_num].hub_port_nbr := 0
  END HC_ClearHubInfo;

  (**
  * @brief  Initialize a host channel.
  * @param  hhcd HCD handle
  * @param  ch_num Channel number.
  *         This parameter can be a value from 1 to 15
  * @param  epnum Endpoint number.
  *          This parameter can be a value from 1 to 15
  * @param  dev_address Current device address
  *          This parameter can be a value from 0 to 255
  * @param  speed Current device speed.
  *          This parameter can be one of these values:
  *            HCD_DEVICE_SPEED_HIGH: High speed mode,
  *            HCD_DEVICE_SPEED_FULL: Full speed mode,
  *            HCD_DEVICE_SPEED_LOW: Low speed mode
  * @param  ep_type Endpoint Type.
  *          This parameter can be one of these values:
  *            EP_TYPE_CTRL: Control type,
  *            EP_TYPE_ISOC: Isochronous type,
  *            EP_TYPE_BULK: Bulk type,
  *            EP_TYPE_INTR: Interrupt type
  * @param  mps Max Packet Size.
  *          This parameter can be a value from 0 to32K
  * @retval HAL status
  *)
  PROCEDURE HC_Init*(hhcd: Handle; ch_num, epnum, dev_address, speed, ep_type: BYTE; mps: HALFWORD): BYTE;
    VAR HostCoreSpeed: SET; HCcharMps: HALFWORD;
(*
  HAL_StatusTypeDef status;
*)
  BEGIN HCcharMps := mps;
(*  __HAL_LOCK(hhcd);*)
    hhcd.hc[ch_num].do_ping := FALSE; hhcd.hc[ch_num].dev_addr := dev_address;
    hhcd.hc[ch_num].ch_num := ch_num; hhcd.hc[ch_num].ep_type := ep_type;
    hhcd.hc[ch_num].ep_num := epnum MOD 80H;
    HC_ClearHubInfo(hhcd, ch_num);
    IF 7 IN TOSET(epnum) THEN hhcd.hc[ch_num].ep_is_in := TRUE ELSE hhcd.hc[ch_num].ep_is_in := FALSE END;
    HostCoreSpeed := ll.GetHostSpeed(hhcd.Instance);
    IF (ep_type = Def.EP_TYPE_ISOC) &
      (speed = Def.SPEED_FULL) & (HostCoreSpeed = ll.HPRT_PSPD_HIGH_SPEED) & (* FS device plugged to HS HUB *)
      (HCcharMps > ll.ISO_SPLT_MPS) THEN (* ISO Max Packet Size for Split mode *) HCcharMps := ll.ISO_SPLT_MPS
    END;
    hhcd.hc[ch_num].speed := speed;
    hhcd.hc[ch_num].max_packet := HCcharMps;
  
    RETURN ll.HC_Init(hhcd.Instance, ch_num, epnum, dev_address, speed, ep_type, HCcharMps)
(*  __HAL_UNLOCK(hhcd);*)
  END  HC_Init;

  (**
  * @brief  Halt a host channel.
  * @param  hhcd HCD handle
  * @param  ch_num Channel number.
  *         This parameter can be a value from 1 to 15
  * @retval HAL status
  *)
  PROCEDURE HC_Halt*(hhcd: Handle; ch_num: BYTE);
  BEGIN
(*  __HAL_LOCK(hhcd);*)
    ll.HC_Halt(hhcd.Instance, ch_num)
(*  __HAL_UNLOCK(hhcd);*)
  END HC_Halt;

  (**
  * @brief  DeInitialize the host driver.
  * @param  hhcd HCD handle
  * @retval HAL status
  *)
  PROCEDURE DeInit*(hhcd: Handle);
  BEGIN hhcd.State := STATE_RESET
  END DeInit;

  (**
  * @brief  Return the current Host frame number.
  * @param  hhcd HCD handle
  * @retval Current Host frame number
  *)
  PROCEDURE GetCurrentFrame*(hhcd: Handle): INTEGER;
    RETURN ll.GetCurrentFrame(hhcd.Instance)
  END GetCurrentFrame;

  (**
  * @brief  Return the Host enumeration speed.
  * @param  hhcd HCD handle
  * @retval Enumeration speed
  *)
  PROCEDURE GetCurrentSpeed*(hhcd: Handle): INTEGER;
    RETURN ORD(LSR(ll.GetHostSpeed(hhcd.Instance), ll.HPRT_PSPD_Pos))
  END GetCurrentSpeed;

  (**
  * @brief  Start the host driver.
  * @param  hhcd HCD handle
  * @retval HAL status
  *)
  PROCEDURE Start*(hhcd: Handle);
  BEGIN
(*  __HAL_LOCK(hhcd);*)
    hhcd.State := STATE_STARTED;
    ll.DriveVbus(hhcd.Instance, TRUE); (* Enable port power *)
(*  __HAL_UNLOCK(hhcd);*)
  END Start;

  (**
  * @brief  Stop the host driver.
  * @param  hhcd HCD handle
  * @retval HAL status
  *)
  PROCEDURE Stop*(hhcd: Handle);
    VAR res: BYTE;
  BEGIN
    res := ll.StopHost(hhcd.Instance); hhcd.State := STATE_RESET
  END Stop;

  (**
  * @brief  Reset the host port.
  * @param  hhcd HCD handle
  * @retval HAL status
  *)
  PROCEDURE ResetPort*(hhcd: Handle);
  BEGIN ll.ResetPort(hhcd.Instance)
  END ResetPort;

  (** @defgroup HCD_Exported_Functions_Group4 Peripheral State functions
  *  @brief   Peripheral State functions
  *
  @verbatim
   ===============================================================================
                      ##### Peripheral State functions #####
   ===============================================================================
    [..]
    This subsection permits to get in run-time the status of the peripheral
    and the data flow.

  @endverbatim
  * @{
  *)
  (**
  * @brief  Return the HCD handle state.
  * @param  hhcd HCD handle
  * @retval HAL state
  *)
  PROCEDURE GetState*(hhcd: Handle): BYTE;
    RETURN hhcd.State
  END GetState;

  (**
  * @brief  Return  URB state for a channel.
  * @param  hhcd HCD handle
  * @param  chnum Channel number.
  *         This parameter can be a value from 1 to 15
  * @retval URB state.
  *          This parameter can be one of these values:
  *            URB_IDLE/
  *            URB_DONE/
  *            URB_NOTREADY/
  *            URB_NYET/
  *            URB_ERROR/
  *            URB_STALL
  *)
  PROCEDURE HC_GetURBState*(hhcd: Handle; chnum: BYTE): BYTE;
    RETURN hhcd.hc[chnum].urb_state
  END HC_GetURBState;

  (**
  * @brief  Return the last host transfer size.
  * @param  hhcd HCD handle
  * @param  chnum Channel number.
  *         This parameter can be a value from 1 to 15
  * @retval last transfer size in byte
  *)
  PROCEDURE HC_GetXferCount*(hhcd: Handle; chnum: BYTE): INTEGER;
    RETURN hhcd.hc[chnum].xfer_count
  END HC_GetXferCount;

  (**
  * @brief  Initialize the pool of messages for each type of deferred work.
  * @param  hhcd HCD handle
  *)
  PROCEDURE InitPools*(hcdh: Handle);
  BEGIN
    hcdh.ConnectMP := Q.CreatePool(1, newConnectMsg);
    hcdh.DisconnectMP := Q.CreatePool(1, newDisconnectMsg);
    hcdh.PortEnabledMP := Q.CreatePool(1, newPortEnabledMsg);
    hcdh.PortDisabledMP := Q.CreatePool(1, newPortDisabledMsg);
    hcdh.URBChangeMP := Q.CreatePool(3, newURBChangeMsg);
    hcdh.DebugMP := Q.CreatePool(100, newDebugMsg)
  END InitPools;

  PROCEDURE TakeMsg*(hcdh: Handle): Q.Msg;
    VAR msg!: Q.Msg;
  BEGIN msg := NIL;
    IF Q.IsExhausted() THEN Log.Error("Interrupt queue too small"); Log.ErrorLn;
      Log.Flush; ASSERT(FALSE)
    END;
    IF hcdh.MsgPendQ # NIL THEN
      ll.DisableGlobalInt(hcdh.Instance); msg := Q.Get(hcdh.MsgPendQ); ll.EnableGlobalInt(hcdh.Instance)
    END

    RETURN msg
  END TakeMsg;

  PROCEDURE GiveMsg*(hcdh: Handle; msg: Q.Msg);
  BEGIN ll.DisableGlobalInt(hcdh.Instance);
    CASE msg OF
      ConnectMsg: Q.PostFirst(hcdh.ConnectMP, msg) (*return item to pool*)
    | DisconnectMsg: Q.PostFirst(hcdh.DisconnectMP, msg)
    | PortEnabledMsg: Q.PostFirst(hcdh.PortEnabledMP, msg)
    | PortDisabledMsg: Q.PostFirst(hcdh.PortDisabledMP, msg)
    | URBChangeMsg: Q.PostFirst(hcdh.URBChangeMP, msg)
    | DebugMsg: Q.PostFirst(hcdh.DebugMP, msg)
    | Q.Msg: UC.GiveMsg(hcdh, msg) (*see if HALCD can handle the message*)
    END;
    ll.EnableGlobalInt(hcdh.Instance)
  END GiveMsg;

  PROCEDURE New*(): Handle;
    VAR h!: Handle;
  BEGIN NEW(h);
    h.Control.setup.size := SYSTEM.SIZE(HDef.Setup) - SYSTEM.SIZE(Def.Buffer);
    Log.Debug("setup size: "); Log.DebugInt(h.Control.setup.size, 1); Log.DebugLn;
    h.device.CfgRaw.size := SYSTEM.SIZE(HDef.RawDescriptorData) - SYSTEM.SIZE(Def.Buffer);
    h.device.tmprd.size := SYSTEM.SIZE(HDef.RawDescriptorData) - SYSTEM.SIZE(Def.Buffer);

    RETURN h
  END New;

END HALHCD.

OM4Tool.DecSym HALHCD.sm4
OM4Tool.DecObj HALHCD.m4c
