MODULE USBDMTPStorage;
  (** ported to Oberon from:
  ******************************************************************************
  * @file    usbd_mtp_storage.c
  * @author  MCD Application Team
  * @brief   This file provides all the transfer command functions for MTP
  ******************************************************************************
  *
  ******************************************************************************
  *)
  IMPORT SYSTEM, Log := USBLog, Def := USBDef, DDef := USBDDef, IoReq := USBDIoReq, DH := USBDHal,
    O := USBDMTPOpt;

  CONST
    IN_EP* = 81H; (* EP1 for data IN *)
    OUT_EP* = 1; (* EP1 for data OUT *)
    CMD_EP* = 82H; (* EP2 for MTP commands *)

(*
    READ_DATA* = 2;
    RECEIVE_DATA* = 3;

    READ_FIRST_DATA = 0;
    READ_REST_OF_DATA = 1;

    DATA_TYPE* = 0;
    REP_TYPE* = 1;
*)

  TYPE RawContainer = ARRAY SYSTEM.SIZE(O.ParamContainer) OF BYTE;

  VAR InEpAdd*, OutEpAdd*, CmdEpAdd*: BYTE;

  (**
  * @brief  USBD_MTP_STORAGE_SendData
  *         Send the data on bulk-in EP
  * @param  pdev: device instance
  * @param  buf: pointer to data buffer
  * @param  len: Data Length
  * @retval status value
  *)
  PROCEDURE SendData(dev: DDef.Handle; buf: Def.BufferDesc);
  BEGIN
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this class instance */
  MTPInEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_IN, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    DH.Transmit(dev, InEpAdd, buf, buf.length)
  END SendData;

  (**
  * @brief  SendEvent
  *         Send the event on interrupt EP
  * @param  pdev: device instance
  * @param  buf: pointer to data buffer
  *)
  PROCEDURE SendEvent*(dev: DDef.Handle);

    PROCEDURE Send(dev: DDef.Handle; buf: Def.BufferDesc);
    BEGIN DH.Transmit(dev, CmdEpAdd, buf, buf.length)
    END Send;

  BEGIN
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this class instance */
  MTPInEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_CMD, USBD_EP_TYPE_INTERRUPT, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    Send(dev, dev(DDef.Handle).ClassDataCmsit[dev.classId](O.Handle).Events.ev)
  END SendEvent;


  (**
  * @brief  USBD_MTP_STORAGE_ReceiveContainer
  *         Receive the Data from USB BulkOut Buffer to a param container
  * @param  pdev: device instance
  * @param  pDst: destination to copy the buffer
  * @retval status value
  *)
  PROCEDURE ReceiveContainer(dev: DDef.Handle; VAR Dst: O.ParamContainer);
    VAR hmtp!: O.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle);
    SYSTEM.COPY(ORD(hmtp.rx_buff), SYSTEM.ADR(Dst), SYSTEM.SIZE(O.ParamContainer) DIV 4)
  END ReceiveContainer;

 (**
  * @brief  USBD_MTP_STORAGE_Cancel
  *         Reinitialize all states and cancel transfer through Bulk transfer
  * @param  pdev: device instance
  * @param  MTP_ResponsePhase: MTP current state
  * @retval None
  *)
  PROCEDURE Cancel*(dev: DDef.Handle; ResponsePhase: BYTE);
    VAR hmtp!: O.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle);
    hmtp.TransactionPhase := O.PHASE_IDLE;
    IF ResponsePhase = O.DATA_IN_PHASE THEN dev.UserData[dev.classId](O.UserIf).Cancel(1)
    ELSE dev.UserData[dev.classId](O.UserIf).Cancel(0)
    END
  END Cancel;

  (**
  * @brief  USBD_MTP_STORAGE_Init
  *         Initialize the MTP USB Layer
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE Init*(dev: DDef.Handle);
    VAR hmtp!: O.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle);
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this class instance */
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    (* Initialize the HW layyer of the file system *)
    dev.UserData[dev.classId](O.UserIf).Init;
    (* Prepare EP to Receive First Operation *)
    hmtp.rx_buff.length := hmtp.rx_buff.size; dev.PrepareReceive(dev, OutEpAdd, hmtp.rx_buff^)
  END Init;

  (**
  * @brief  USBD_MTP_STORAGE_DeInit
  *         Uninitialize the MTP Machine
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE DeInit*(dev: DDef.Handle);
    VAR hmtp!: O.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle);
    (* DeInit  physical Interface components *)
    hmtp.SessionState := O.SESSION_NOT_OPEN;
    (* Stop low layer file system operations if any *)
    Cancel(dev, O.PHASE_IDLE);
    (* Free low layer file system resources *)
    dev.UserData[dev.classId](O.UserIf).DeInit
  END DeInit;

  (**
  * @brief  USBD_MTP_STORAGE_ReadData
  *         Read data from device objects and send it to the host
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE ReadData*(dev: DDef.Handle);
    VAR data_buff!: Def.Buffer; hmtp!: O.Handle; uif!: O.UserIf;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle);
    uif := dev.UserData[dev.classId](O.UserIf);
    uif.PutNextData(dev, hmtp.tx_buff);
    IF hmtp.tx_buff.length = 0 THEN (*DATA phase complete*)
      hmtp.TransactionPhase := O.RESPONSE_PHASE
    END
  END ReadData;

  PROCEDURE DebugContainer(prefix: ARRAY OF CHAR; c: RawContainer; len: INTEGER);
  BEGIN Log.Debug(prefix); Log.DebugBuf(c, len, SYSTEM.SIZE(Def.BufferDesc)); Log.DebugLn
  END DebugContainer;

  (**
  * @brief  USBD_MTP_STORAGE_SendContainer
  *         Send generic container to the host
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE SendContainer*(dev: DDef.Handle);
    VAR hmtp!: O.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle);
    IF hmtp.TransactionPhase = O.RESPONSE_PHASE THEN (*build response container*)
      hmtp.TransactionPhase := O.PHASE_IDLE;
      hmtp.Response.length := hmtp.Response.CLen; SendData(dev, hmtp.Response);
(*      DebugContainer("Send response: ", hmtp.Response, hmtp.Response.length)*)
    ELSE SendData(dev, hmtp.tx_buff^);
    END;
  END SendContainer;

(**
  * @brief  USBD_MTP_STORAGE_DecodeOperations
  *         Parse the operations and Process operations,
   *        then set the transaction phase according to the requested operation
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE DecodeOperations(dev: DDef.Handle);
    VAR hmtp!: O.Handle; op: INTEGER;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle);
    op := hmtp.ReqOp.code;
(*    Log.Debug("decode op: "); Log.DebugHexVLen(op, 4, FALSE); Log.DebugLn;*)
    hmtp.Response.CLen := O.CONT_HEADER_SIZE; hmtp.Response.trans_id := hmtp.ReqOp.trans_id;
    hmtp.TransactionPhase := O.RESPONSE_PHASE;
    IF op = O.OP_GET_DEVICE_INFO THEN O.GetDeviceInfo(dev)
    ELSIF op = O.OP_OPEN_SESSION THEN O.OpenSession(dev)
    ELSIF op = O.OP_CLOSE_SESSION THEN O.CloseSession(dev)
    ELSIF op = O.OP_GET_NUM_OBJECTS THEN O.GetNumObjects(dev)
    ELSIF op = O.OP_SEND_OBJECT_INFO THEN O.SendObjectInfo(dev); hmtp.TransactionPhase := O.DATA_OUT_PHASE
    ELSIF op = O.OP_SEND_OBJECT THEN O.SendObject(dev); hmtp.TransactionPhase := O.DATA_OUT_PHASE
    ELSIF op = O.OP_DELETE_OBJECT THEN O.DeleteObject(dev)
    ELSE O.ProcessOp(dev)
    END
  END DecodeOperations;

  (**
  * @brief  USBD_MTP_STORAGE_ReceiveOpt
  *         Data length Packet Received from host
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE ReceiveOpt*(dev: DDef.Handle);
    VAR hmtp!: O.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle); ASSERT(hmtp.TransactionPhase = O.OPERATION_REQUEST_PHASE);
    hmtp.ReqOp.length := IoReq.GetRxCount(dev, OutEpAdd);
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this class instance */
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    (* Fill hmtp->OperationsContainer Data Buffer from USB Buffer *)
    ReceiveContainer(dev, hmtp.ReqOp);
    DecodeOperations(dev)
  END ReceiveOpt;

  (**
  * @brief  USBD_MTP_STORAGE_ReceiveData
  *         Receive objects or object info from host
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE ReceiveData*(dev: DDef.Handle);
    VAR hmtp!: O.Handle; uif!: O.UserIf;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](O.Handle);
    hmtp.rx_buff.length := IoReq.GetRxCount(dev, OutEpAdd);
    uif := dev.UserData[dev.classId](O.UserIf);
    (*hmtp.rx_buff contains the fresh packet of data sent by the host*)
    uif.ReceiveNextData(hmtp.rx_buff, hmtp.ReqOp.trans_id, hmtp.Response);
    IF hmtp.rx_buff.length < hmtp.rx_buff.size THEN (*DATA phase complete*)
      hmtp.TransactionPhase := O.RESPONSE_PHASE
    END
  END ReceiveData;

BEGIN InEpAdd := IN_EP; OutEpAdd := OUT_EP; CmdEpAdd := CMD_EP
END USBDMTPStorage.
