MODULE HALPCD;
  (** The microcontroller specific part of the Peripheral controller driver, ported to Oberon from:
  ******************************************************************************
  * @file    stm32f4xx_hal_hcd.h
  * @author  MCD Application Team
  * @brief   HCD HAL module.
  ******************************************************************************
  *)
  IMPORT SYSTEM, Def := USBDef, ll := LLUSB, UC := HALUC, DDef := USBDDef;

  CONST
    SPEED_HIGH* = ll.USBD_HS_SPEED;
    SPEED_HIGH_IN_FULL* = ll.USBD_HSINFS_SPEED;
    SPEED_FULL* = ll.USBD_FS_SPEED;

  TYPE
  (**
  * @brief  PCD Handle Structure definition
  *)
    Handle* = POINTER TO HandleDesc;
    Callback* = PROCEDURE(pcd: Handle);
    EPCallback* = PROCEDURE(pcd: Handle; epnum: BYTE);
    MsgCallback* = PROCEDURE(pcd: Handle; msg: BYTE);
    HandleDesc* = RECORD(DDef.HandleDesc)
      Address*: BYTE; (*!< USB Address                       *)
      IN_ep*, (*!< IN endpoint parameters            *)
      OUT_ep* (* /*!< OUT endpoint parameters           *) : ARRAY 16 OF ll.EPDesc;
      State: BYTE;       (*!< PCD communication state           *)
      ErrorCode: INTEGER;   (*!< PCD Error code                    *)
      Setup*: ARRAY 12*4 OF BYTE;   (*!< Setup packet buffer               *)
      LPM_State: BYTE;   (*!< LPM State                         *)
      BESL,
      FrameNumber: INTEGER; (*!< Store Current Frame number        *)
      lpm_active,               (*!< Enable or disable the Link Power Management .
                                       This parameter can be set to ENABLE or DISABLE        *)
      battery_charging_active: BOOLEAN;    (*!< Enable or disable Battery charging.
                                       This parameter can be set to ENABLE or DISABLE        *)
     SOFCallback*,
     SetupStageCallback*,
     ResetCallback*,
     SuspendCallback*,
     ResumeCallback*,
     ConnectCallback*,
     DisconnectCallback*: Callback;
     DataOutStageCallback*,
     DataInStageCallback*,
     ISOOUTIncompleteCallback*,
     ISOINIncompleteCallback*: EPCallback;
     BCDCallback*,
     LPMCallback*: MsgCallback
  END;

  (**
  * @brief  Handle PCD interrupt request.
  * @param  pcd HCD handle
  * @retval None
  *)
  PROCEDURE IRQHandler*(pcd: UC.Handle);
(*TODO*)  END IRQHandler;

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
        pcd.IN_ep[i].tx_fifo_num := i;
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
  * @brief  Start the USB device
  * @param  hpcd PCD handle
  * @retval HAL status
  *)
  PROCEDURE Start*(hpcd: Handle);
  BEGIN
    IF (ll.GUSBCFG_PHYSEL IN hpcd.Instance.GUSBCFG) & (hpcd.Init.battery_charging_enable) THEN
      INCL(hpcd.Instance.GCCFG, ll.GCCFG_PWRDWN) (* Enable USB Transceiver *)
    END;
(*  __HAL_PCD_ENABLE(hpcd); enable global usb interrupt*)
    ll.DevConnect(hpcd.Instance)
  END Start;

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
      IF isIn THEN ep.tx_fifo_num := ep.num (* Assign a Tx FIFO *) END;
      IF ep_type = Def.EP_TYPE_BULK THEN ep.data_pid_start := 0 (* Set initial data PID. *) END;
(*  __HAL_LOCK(hpcd);*)
     ll.ActivateEndpoint(hpcd.Instance, ep)
(*  __HAL_UNLOCK(hpcd);*)
    END OpenEP;
  BEGIN 
    IF 7 IN TOSET(ep_addr) THEN OpenEP(hpcd, hpcd.IN_ep[ep_addr MOD 10H], TRUE, ep_addr, ep_mps, ep_type)
    ELSE OpenEP(hpcd, hpcd.OUT_ep[ep_addr MOD 10H], FALSE, ep_addr, ep_mps, ep_type)
    END;
  END EP_Open;

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
  * @brief  Send an amount of data
  * @param  hpcd PCD handle
  * @param  ep_addr endpoint address
  * @param  pBuf pointer to the transmission buffer
  * @param  len amount of data to be sent
  * @retval HAL status
  *)
  PROCEDURE EP_Transmit*(hpcd: Handle; ep_addr: BYTE; Buf: Def.Buffer);
    PROCEDURE TransmitEP(hpcd: Handle; VAR ep: ll.EPDesc; ep_addr: BYTE; Buf: Def.Buffer);
    BEGIN (*setup and start the Xfer *)
      ep.xfer_buff := SYSTEM.ADR(Buf) + SYSTEM.SIZE(Def.Buffer); ep.xfer_len := Buf.length;
      ep.xfer_count := 0; ep.is_in := TRUE; ep.num := ep_addr MOD 10H;
      IF hpcd.Init.dma_enable THEN ep.dma_addr := ep.xfer_buff END;
      ll.EPStartXfer(hpcd.Instance, ep, hpcd.Init.dma_enable)
    END TransmitEP;
  BEGIN TransmitEP(hpcd, hpcd.IN_ep[ep_addr MOD 10H], ep_addr, Buf)
  END EP_Transmit;

  (**
  * @brief  Initialize the pool of messages for each type of deferred work.
  * @param  hhcd HCD handle
  *)
  PROCEDURE InitPools*(pcd: Handle);
  BEGIN (*TODO*)
  END InitPools;

  PROCEDURE New*(): Handle;
    VAR h!: Handle;
  BEGIN NEW(h);

    RETURN h
  END New;

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

END HALPCD.
