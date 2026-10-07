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
  IMPORT SYSTEM, Def := USBDef, DDef := USBDDef, IoReq := USBDIoReq, DH := USBDHal,
    Opt := USBDMTPOpt;

  CONST
    IN_EP* = 81H; (* EP1 for data IN *)
    OUT_EP* = 1; (* EP1 for data OUT *)
    CMD_EP* = 82H; (* EP2 for MTP commands *)

  (* MTP response phases    *)
    PHASE_IDLE* = 0;
    RESPONSE_PHASE* = 1;
    READ_DATA* = 2;
    RECEIVE_DATA* = 3;

    READ_FIRST_DATA = 0;
    READ_REST_OF_DATA = 1;

    DATA_TYPE* = 0;
    REP_TYPE* = 1;

  VAR InEpAdd*, OutEpAdd*, CmdEpAdd*: BYTE;

  (**
  * @brief  USBD_MTP_STORAGE_SendData
  *         Send the data on bulk-in EP
  * @param  pdev: device instance
  * @param  buf: pointer to data buffer
  * @param  len: Data Length
  * @retval status value
  *)
  PROCEDURE SendData(dev: DDef.Handle; buf: Def.Buffer);
  BEGIN
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this class instance */
  MTPInEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_IN, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    DH.Transmit(dev, InEpAdd, buf^, buf.length)
  END SendData;

  (**
  * @brief  USBD_MTP_STORAGE_ReceiveContainer
  *         Receive the Data from USB BulkOut Buffer to Pointer
  * @param  pdev: device instance
  * @param  pDst: destination address to copy the buffer
  * @param  len: length of data to copy
  * @retval status value
  *)
  PROCEDURE ReceiveContainer(dev: DDef.Handle; Dst: Opt.Container);
    VAR hmtp!: Opt.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
    IF Dst # NIL THEN Dst^ := hmtp.rx_buff^ END
  END ReceiveContainer;

 (**
  * @brief  USBD_MTP_STORAGE_Cancel
  *         Reinitialize all states and cancel transfer through Bulk transfer
  * @param  pdev: device instance
  * @param  MTP_ResponsePhase: MTP current state
  * @retval None
  *)
  PROCEDURE Cancel*(dev: DDef.Handle; ResponsePhase: BYTE);
    VAR hmtp!: Opt.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
    hmtp.ResponsePhase := PHASE_IDLE;
    hmtp.ReadDataStatus := READ_FIRST_DATA;
    hmtp.RECEIVE_DATA_STATUS := Opt.RECEIVE_IDLE_STATE;
    IF ResponsePhase = RECEIVE_DATA THEN dev.UserData[dev.classId](Opt.UserIf).Cancel(1)
    ELSE dev.UserData[dev.classId](Opt.UserIf).Cancel(0)
    END
  END Cancel;

  (**
  * @brief  USBD_MTP_STORAGE_Init
  *         Initialize the MTP USB Layer
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE Init*(dev: DDef.Handle);
    VAR hmtp!: Opt.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this class instance */
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    (* Initialize the HW layyer of the file system *)
    dev.UserData[dev.classId](Opt.UserIf).Init;
    (* Prepare EP to Receive First Operation *)
    hmtp.rx_buff.length := hmtp.rx_buff.size; dev.PrepareReceive(dev, OutEpAdd, hmtp.rx_buff)
  END Init;

  (**
  * @brief  USBD_MTP_STORAGE_DeInit
  *         Uninitialize the MTP Machine
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE DeInit*(dev: DDef.Handle);
    VAR hmtp!: Opt.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
    (* DeInit  physical Interface components *)
    hmtp.SessionState := Opt.SESSION_NOT_OPENED;
    (* Stop low layer file system operations if any *)
    Cancel(dev, PHASE_IDLE);
    (* Free low layer file system resources *)
    dev.UserData[dev.classId](Opt.UserIf).DeInit
  END DeInit;

  (**
  * @brief  USBD_MTP_STORAGE_ReadData
  *         Read data from device objects and send it to the host
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE ReadData*(dev: DDef.Handle);
    VAR data_buff!: Def.Buffer; hmtp!: Opt.Handle; ops!: Opt.UserIf;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
    (* Get the data buffer pointer from the low layer interface *)
    ops := dev.UserData[dev.classId](Opt.UserIf); data_buff := ops.ScratchBuff;
    IF (data_buff # NIL) & (data_buff.size >= Opt.CONT_HEADER_SIZE) THEN
      IF hmtp.ReadDataStatus = READ_FIRST_DATA THEN
        ops.CopyBuffer(hmtp.GenericContainer, data_buff, 0); (* Add the container header to the data buffer *)
        hmtp.cur_len := Opt.CONT_HEADER_SIZE; (* Set the data length *)
        (* Perform the low layer read operation on the scratch buffer
         * first packet expected data length: MPS - CONT_HEADER_SIZE *)
        ops.ReadData(hmtp.OperationsContainer.Param1, data_buff, hmtp);
        (* Start USB data transmission to the host *)
        data_buff.length := hmtp.readbytes + Opt.CONT_HEADER_SIZE; SendData(dev, data_buff);
        (* Check if this will be the last packet to send ? *)
(*      if (MTP_DataLength.readbytes < ((uint32_t)hmtp->MaxPcktLen - MTP_CONT_HEADER_SIZE))*)
        IF hmtp.cur_len >= hmtp.GenericContainer.CLen THEN hmtp.ResponsePhase := RESPONSE_PHASE
        ELSE hmtp.ReadDataStatus := READ_REST_OF_DATA (* Continue to the next packets sending *)
        END
      ELSIF hmtp.ReadDataStatus = READ_REST_OF_DATA THEN
        (* Perform the low layer read operation on the scratch buffer *)
        ops.ReadData(hmtp.OperationsContainer.Param1, data_buff, hmtp);
        (* Check if more data need to be sent *)
        IF hmtp.cur_len >= hmtp.GenericContainer.CLen THEN
          (* Start USB data transmission to the host *)
          data_buff.length := hmtp.readbytes; SendData(dev, data_buff);
          hmtp.ResponsePhase := RESPONSE_PHASE;
          hmtp.ReadDataStatus := READ_FIRST_DATA (* Reset the state machine *)
        ELSE
          (* Start USB data transmission to the host *)
          data_buff.length := hmtp.readbytes; SendData(dev, data_buff)
          (* Keep the state machine into sending next packet of data *)
        END
      END
    END
  END ReadData;

  (**
  * @brief  USBD_MTP_STORAGE_SendContainer
  *         Send generic container to the host
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE SendContainer*(dev: DDef.Handle; CONT_TYPE: BYTE);
    VAR hmtp!: Opt.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
    IF CONT_TYPE = DATA_TYPE THEN (* send header + data : hmtp->ResponseLength = header size + data size *)
      SendData(dev, hmtp.GenericContainer);
    ELSIF CONT_TYPE = REP_TYPE THEN (* send header without data *)
      hmtp.GenericContainer.code := hmtp.ResponseCode;
      hmtp.GenericContainer.length := Opt.CONT_HEADER_SIZE;
      hmtp.GenericContainer.CLen := hmtp.GenericContainer.length;
      hmtp.GenericContainer.type := Opt.CONT_TYPE_RESPONSE;
      SendData(dev, hmtp.GenericContainer)
    END
  END SendContainer;

(**
  * @brief  USBD_MTP_STORAGE_DecodeOperations
  *         Parse the operations and Process operations
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE DecodeOperations(dev: DDef.Handle);
    VAR hmtp!: Opt.Handle; op: INTEGER;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
    op := hmtp.OperationsContainer.code;
    IF op = Opt.OP_GET_DEVICE_INFO THEN
      Opt.GetDeviceInfo(dev); hmtp.ResponsePhase := RESPONSE_PHASE
    ELSIF op = Opt.OP_OPEN_SESSION THEN
      Opt.CreateObjectHandle(dev); hmtp.ResponsePhase := RESPONSE_PHASE
    ELSIF (op = Opt.OP_GET_STORAGE_IDS) OR (op = Opt.OP_GET_STORAGE_INFO) OR
      (op = Opt.OP_GET_OBJECT_HANDLES) OR (op = Opt.OP_GET_OBJECT_INFO) OR
      (op = Opt.OP_GET_OBJECT_REFERENCES) OR (op = Opt.OP_GET_OBJECT_PROPS_SUPPORTED) OR 
      (op = Opt.OP_GET_OBJECT_PROP_DESC) OR (op = Opt.OP_GET_OBJECT_PROPLIST) OR
      (op = Opt.OP_GET_OBJECT_PROP_VALUE) OR (op = Opt.OP_GET_DEVICE_PROP_DESC) THEN
        Opt.ProcessOp(dev); hmtp.ResponsePhase := RESPONSE_PHASE
    ELSIF op = Opt.OP_GET_OBJECT THEN
      Opt.GetObject(dev); hmtp.ResponsePhase := READ_DATA
    ELSIF op = Opt.OP_SEND_OBJECT_INFO THEN
      Opt.SendObjectInfo(dev, hmtp.rx_buff); hmtp.ResponsePhase := RECEIVE_DATA
    ELSIF op = Opt.OP_SEND_OBJECT THEN
      Opt.SendObject(dev, hmtp.rx_buff); hmtp.ResponsePhase := RECEIVE_DATA
    ELSIF op = Opt.OP_DELETE_OBJECT THEN
      Opt.DeleteObject(dev); hmtp.ResponsePhase := RESPONSE_PHASE
    END
  END DecodeOperations;

  (**
  * @brief  USBD_MTP_STORAGE_ReceiveOpt
  *         Data length Packet Received from host
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE ReceiveOpt*(dev: DDef.Handle);
    VAR hmtp!: Opt.Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
(*
#ifdef USE_USBD_COMPOSITE
  /* Get the Endpoints addresses allocated for this class instance */
  MTPOutEpAdd = USBD_CoreGetEPAdd(pdev, USBD_EP_OUT, USBD_EP_TYPE_BULK, (uint8_t)pdev->classId);
#endif /* USE_USBD_COMPOSITE */
*)
    hmtp.OperationsContainer.length := IoReq.GetRxCount(dev, OutEpAdd); (*is it necessary?*)
    IF hmtp.RECEIVE_DATA_STATUS = Opt.RECEIVE_REST_OF_DATA THEN
      (* we don't need to do anything here because we receive only data without container header*)
    ELSIF hmtp.RECEIVE_DATA_STATUS = Opt.RECEIVE_FIRST_DATA THEN (* Expected Data Length Packet Received *)
      (* Fill hmtp->OperationsContainer Data Buffer from USB Buffer *)
      ReceiveContainer(dev, hmtp.OperationsContainer)
    ELSE (* Expected operation container *)
      (* Fill hmtp->OperationsContainer Data Buffer from USB Buffer *)
      ReceiveContainer(dev, hmtp.OperationsContainer);
      DecodeOperations(dev)
    END
  END ReceiveOpt;

  (**
  * @brief  USBD_MTP_STORAGE_ReceiveData
  *         Receive objects or object info from host
  * @param  pdev: device instance
  * @retval status value
  *)
  PROCEDURE ReceiveData*(dev: DDef.Handle);
    VAR hmtp!: Opt.Handle;
    PROCEDURE nextReceive(dev: DDef.Handle; hmtp: Opt.Handle);
    BEGIN DecodeOperations(dev);
      IF hmtp.cur_len >= hmtp.rx_buff.CLen - Opt.CONT_HEADER_SIZE THEN
        (* we received all data, we don't need to go to next state *)
        hmtp.RECEIVE_DATA_STATUS := Opt.SEND_RESPONSE; DecodeOperations(dev);
        (* send response header after receiving all data successfully *)
        SendContainer(dev, DATA_TYPE) (*Confirm DATA_TYPE or REP_TYPE?*)
      END
    END nextReceive;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Opt.Handle);
    IF hmtp.RECEIVE_DATA_STATUS = Opt.RECEIVE_COMMAND_DATA THEN
      IF hmtp.OperationsContainer.type = Opt.CONT_TYPE_COMMAND THEN DecodeOperations(dev) END
    ELSIF hmtp.RECEIVE_DATA_STATUS = Opt.RECEIVE_FIRST_DATA THEN
      IF hmtp.OperationsContainer.type = Opt.CONT_TYPE_DATA THEN nextReceive(dev, hmtp) END
    ELSIF hmtp.RECEIVE_DATA_STATUS = Opt.RECEIVE_REST_OF_DATA THEN nextReceive(dev, hmtp)
    END
  END ReceiveData;

BEGIN InEpAdd := IN_EP; OutEpAdd := OUT_EP; CmdEpAdd := CMD_EP
END USBDMTPStorage.
