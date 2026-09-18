MODULE USBDCore;
  (** ported to Oberon from:
  ******************************************************************************
  * @file    usbd_core.c
  * @author  MCD Application Team
  * @brief   This file provides all the USBD core functions.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2015 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  *)
  IMPORT Def := USBDef, DDef := USBDDef, IoReq := USBDIoReq, CtlReq := USBDCtlReq;

  (**
  * @brief  USBD_RunTestMode
  *         Launch test mode process
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE RunTestMode(dev: DDef.Handle);
  BEGIN
(*
#ifdef USBD_HS_TESTMODE_ENABLE
  USBD_StatusTypeDef ret;

  /* Run USB HS test mode */
  ret = USBD_LL_SetTestMode(pdev, pdev->dev_test_mode);

  return ret;
#endif /* USBD_HS_TESTMODE_ENABLE */
*)
  END RunTestMode;

  (**
  * @brief  USBD_LL_SetupStage
  *         Handle the setup stage
  * @param  pdev: device instance
  * @param  psetup: setup packet buffer pointer
  * @retval status
  *)
  PROCEDURE SetupStage*(dev: DDef.Handle; setup: ARRAY OF BYTE);
    VAR ret: BYTE; recipient: SET;
  BEGIN  CtlReq.ParseSetupRequest(dev.request, setup);
    dev.ep0_state := DDef.EP0_SETUP; dev.ep0_data_len := dev.request.wLength;
    recipient := dev.request.bmRequestType*Def.REQ_RECIPIENT_MASK;
    IF recipient = Def.REQ_RECIPIENT_DEVICE THEN ret := CtlReq.StdDevReq(dev, dev.request)
    ELSIF recipient = Def.REQ_RECIPIENT_INTERFACE THEN ret := CtlReq.StdItfReq(dev, dev.request)
    ELSIF recipient = Def.REQ_RECIPIENT_ENDPOINT THEN ret := CtlReq.StdEPReq(dev, dev.request)
    ELSE dev.StallEP(dev, ORD(dev.request.bmRequestType*{7}))
    END
  END SetupStage;

  (**
  * @brief  USBD_LL_DataOutStage
  *         Handle data OUT stage
  * @param  pdev: device instance
  * @param  epnum: endpoint index
  * @retval status
  *)
  PROCEDURE DataOutStage*(dev: DDef.Handle; epnum: BYTE);
    VAR recipient: SET; idx: BYTE;
    PROCEDURE dosEP0(dev: DDef.Handle; VAR pep: DDef.Endpoint);
    BEGIN
      IF pep.rem_length > pep.maxpacket THEN
        DEC(pep.rem_length, pep.maxpacket); INC(pep.buffer.pktidx, pep.maxpacket);
        pep.buffer.pktlen := Def.MAX(pep.rem_length, pep.maxpacket); IoReq.CtlContinueRx(dev, pep.buffer)
      END
    END dosEP0;
  BEGIN
    IF epnum = 0 THEN
      IF dev.ep0_state = DDef.EP0_DATA_OUT THEN dosEP0(dev, dev.ep_out[0])
      ELSE (* Find the class ID relative to the current request *)
        recipient := dev.request.bmRequestType*Def.REQ_RECIPIENT_MASK;
        IF recipient = Def.REQ_RECIPIENT_DEVICE THEN
          (* Device requests must be managed by the first instantiated class
             (or duplicated by all classes for simplicity) *)
          idx := 0
        ELSIF recipient = Def.REQ_RECIPIENT_INTERFACE THEN
          idx := dev.CoreFindIF(dev, dev.request.wIndex MOD 100H)
        ELSIF recipient = Def.REQ_RECIPIENT_ENDPOINT THEN
          idx := dev.CoreFindEP(dev, dev.request.wIndex MOD 100H)
        ELSE (* Back to the first class in case of doubt *)
          idx := 0
        END;
        IF idx < DDef.MAX_SUPPORTED_CLASS THEN
          (* Setup the class ID and route the request to the relative class function *)
          IF dev.state = DDef.STATE_CONFIGURED THEN
            IF dev.Class[idx].EP0_RxReady # NIL THEN
              dev.classId := idx;  dev.Class[idx].EP0_RxReady(dev)
            END
          END
        END;
        IoReq.CtlSendStatus(dev)
      END
    ELSE (* Get the class index relative to this interface *)
      idx := dev.CoreFindEP(dev, epnum MOD 80H);
      IF (idx # 0FFH) & (idx < DDef.MAX_SUPPORTED_CLASS) THEN
        (* Call the class data out function to manage the request *)
        IF dev.state = DDef.STATE_CONFIGURED THEN
          IF dev.Class[idx].DataOut # NIL THEN
            dev.classId := idx; dev.Class[idx].DataOut(dev, epnum)
          END
        END;
      END
    END
  END DataOutStage;

  (**
  * @brief  USBD_LL_DataInStage
  *         Handle data in stage
  * @param  pdev: device instance
  * @param  epnum: endpoint index
  * @retval status
  *)
  PROCEDURE DataInStage*(dev: DDef.Handle; epnum: BYTE);
    VAR idx: BYTE;
    PROCEDURE disEP0(dev: DDef.Handle; VAR pep: DDef.Endpoint);
      VAR  ret: BYTE;
    BEGIN
      IF pep.rem_length > pep.maxpacket THEN
        DEC(pep.rem_length, pep.maxpacket); INC(pep.buffer.pktidx, pep.maxpacket);
        IoReq.CtlContinueSendData(dev, pep.buffer);
        (* Prepare endpoint for premature end of transfer *)
        dev.PrepareReceive(dev, 0, NIL)
      ELSE (* last packet is MPS multiple, so send ZLP packet *)
        IF (pep.maxpacket = pep.rem_length) &
            (pep.buffer.length >= pep.maxpacket) &
            (pep.buffer.length < dev.ep0_data_len) THEN
          IoReq.CtlContinueSendData(dev, NIL); dev.ep0_data_len := 0;
          (* Prepare endpoint for premature end of transfer *)
          dev.PrepareReceive(dev, 0, NIL)
        ELSE
          IF dev.state = DDef.STATE_CONFIGURED THEN
            IF dev.Class[0].EP0_TxSent # NIL THEN dev.classId := 0; dev.Class[0].EP0_TxSent(dev) END
          END;
          dev.StallEP(dev, 80H); IoReq.CtlReceiveStatus(dev)
        END
      END
    END disEP0;
  BEGIN
    IF epnum = 0 THEN
      IF dev.ep0_state = DDef.EP0_DATA_IN THEN disEP0(dev, dev.ep_in[0]) END;
      IF dev.test_mode # 0 THEN RunTestMode(dev); dev.test_mode := 0 END
    ELSE
      (* Get the class index relative to this interface *)
      idx := dev.CoreFindEP(dev, ORD(TOSET(epnum)+Def.D2H));
      IF (idx # 0FFH) & (idx < DDef.MAX_SUPPORTED_CLASS) THEN
        (* Call the class data out function to manage the request *)
        IF dev.state = DDef.STATE_CONFIGURED THEN
          IF dev.Class[idx].DataIn # NIL THEN dev.classId := idx; dev.Class[idx].DataIn(dev, epnum) END
        END
      END
    END
  END DataInStage;

  (**
  * @brief  USBD_LL_SOF
  *         Handle SOF event
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE SOF*(dev: DDef.Handle);
    VAR ret: BYTE;
  BEGIN
    (* The SOF event can be distributed for all classes that support it *)
    IF dev.state = DDef.STATE_CONFIGURED THEN
(*
#ifdef USE_USBD_COMPOSITE
    /* Parse the table of classes in use */
    for (uint32_t i = 0; i < USBD_MAX_SUPPORTED_CLASS; i++)
    {
      /* Check if current class is in use */
      if ((pdev->tclasslist[i].Active) == 1U)
      {
        if (pdev->pClass[i] != NULL)
        {
          if (pdev->pClass[i]->SOF != NULL)
          {
            pdev->classId = i;
            (void)pdev->pClass[i]->SOF(pdev);
          }
        }
      }
    }
#else
*)
      IF dev.Class[0] # NIL THEN
        IF dev.Class[0].SOF # NIL THEN ret := dev.Class[0].SOF(dev) END
      END
(*
#endif /* USE_USBD_COMPOSITE */
*)
    END
  END SOF;

  (**
  * @brief  USBD_LL_Reset
  *         Handle Reset event
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE Reset*(dev: DDef.Handle);
    VAR ret: BYTE;
  BEGIN ret := Def.OK;
    (* Upon Reset call user call back *)
    dev.state := DDef.STATE_DEFAULT;
    dev.ep0_state := Def.IDLE;
    dev.config := 0;
    dev.remote_wakeup := FALSE;
    dev.test_mode := 0;
(*
#ifdef USE_USBD_COMPOSITE
  /* Parse the table of classes in use */
  for (uint32_t i = 0U; i < USBD_MAX_SUPPORTED_CLASS; i++)
  {
    /* Check if current class is in use */
    if ((pdev->tclasslist[i].Active) == 1U)
    {
      if (pdev->pClass[i] != NULL)
      {
        pdev->classId = i;
        /* Clear configuration  and De-initialize the Class process*/

        if (pdev->pClass[i]->DeInit != NULL)
        {
          if (pdev->pClass[i]->DeInit(pdev, (uint8_t)pdev->dev_config) != USBD_OK)
          {
            ret = USBD_FAIL;
          }
        }
      }
    }
  }
#else
*)
    IF dev.Class[0] # NIL THEN
      IF dev.Class[0].DeInit # NIL THEN dev.Class[0].DeInit(dev, dev.config) END
    END;
(*
#endif /* USE_USBD_COMPOSITE */
*)
    (* Open EP0 OUT *)
    dev.OpenEP(dev, 0, Def.EP_TYPE_CTRL, Def.MAX_EP0_SIZE);
    dev.ep_out[0].is_used := TRUE; dev.ep_out[0].maxpacket := Def.MAX_EP0_SIZE;
    (* Open EP0 IN *)
    dev.OpenEP(dev, 80H, Def.EP_TYPE_CTRL, Def.MAX_EP0_SIZE);
    dev.ep_in[0].is_used := TRUE; dev.ep_in[0].maxpacket := Def.MAX_EP0_SIZE;
  END Reset;

  (**
  * @brief  USBD_LL_Suspend
  *         Handle Suspend event
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE Suspend*(dev: DDef.Handle);
  BEGIN
    IF dev.state # DDef.STATE_SUSPENDED THEN
      dev.old_state := dev.state; dev.state := DDef.STATE_SUSPENDED
    END
  END Suspend;

  (**
  * @brief  USBD_LL_Resume
  *         Handle Resume event
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE Resume*(dev: DDef.Handle);
  BEGIN
    IF dev.state = DDef.STATE_SUSPENDED THEN dev.state := dev.old_state END
  END Resume;

  (**
  * @brief  USBD_LL_IsoINIncomplete
  *         Handle iso in incomplete event
  * @param  pdev: device instance
  * @param  epnum: Endpoint number
  * @retval status
  *)
  PROCEDURE IsoINIncomplete*(dev: DDef.Handle; epnum: BYTE);
  BEGIN
    IF dev.Class[dev.classId] # NIL THEN
      IF dev.state = DDef.STATE_CONFIGURED THEN
        IF dev.Class[dev.classId].IsoINIncomplete # NIL THEN dev.Class[dev.classId].IsoINIncomplete(dev, epnum) END
      END
    END
  END IsoINIncomplete;

  (**
  * @brief  USBD_LL_IsoOUTIncomplete
  *         Handle iso out incomplete event
  * @param  pdev: device instance
  * @param  epnum: Endpoint number
  * @retval status
  *)
  PROCEDURE IsoOUTIncomplete*(dev: DDef.Handle; epnum: BYTE);
  BEGIN
    IF dev.Class[dev.classId] # NIL THEN
      IF dev.state = DDef.STATE_CONFIGURED THEN
        IF dev.Class[dev.classId].IsoOUTIncomplete # NIL THEN dev.Class[dev.classId].IsoOUTIncomplete(dev, epnum) END
      END
    END
  END IsoOUTIncomplete;

  (**
  * @brief  USBD_LL_DevConnected
  *         Handle device connection event
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE DevConnected*(dev: DDef.Handle);
  BEGIN
  END DevConnected;

  (**
  * @brief  USBD_LL_DevDisconnected
  *         Handle device disconnection event
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE DevDisconnected*(dev: DDef.Handle);
  BEGIN
    (* Free Class Resources *)
    dev.state := DDef.STATE_DEFAULT;
(*
#ifdef USE_USBD_COMPOSITE
  /* Parse the table of classes in use */
  for (uint32_t i = 0; i < USBD_MAX_SUPPORTED_CLASS; i++)
  {
    /* Check if current class is in use */
    if ((pdev->tclasslist[i].Active) == 1U)
    {
      if (pdev->pClass[i] != NULL)
      {
        pdev->classId = i;
        /* Clear configuration  and De-initialize the Class process*/
        if (pdev->pClass[i]->DeInit(pdev, (uint8_t)pdev->dev_config) != 0U)
        {
          ret = USBD_FAIL;
        }
      }
    }
  }
#else
*)
    IF dev.Class[0] # NIL THEN dev.Class[0].DeInit(dev, dev.config) END
(*
#endif /* USE_USBD_COMPOSITE */
*)
  END DevDisconnected;

  (**
  * @brief  USBD_LL_SetSpeed
  *         Handle Reset event
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE SetSpeed*(dev: DDef.Handle; speed: BYTE);
  BEGIN dev.speed := speed
  END SetSpeed;

END USBDCore.
