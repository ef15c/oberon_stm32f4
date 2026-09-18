MODULE USBDIoReq;
  (** ported to Oberon from:
  ******************************************************************************
  * @file    usbd_ioreq.c
  * @author  MCD Application Team
  * @brief   This file provides the IO requests APIs for control endpoints.
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
  IMPORT Def := USBDef, DDef := USBDDef;

  (**
  * @brief  USBD_CtlSendData
  *         send data on the ctl pipe
  * @param  pdev: device instance
  * @param  buff: pointer to data buffer
  * @retval status
  *)
  PROCEDURE CtlSendData*(dev: DDef.Handle; buf: Def.Buffer);
  BEGIN
    dev.ep0_state := DDef.EP0_DATA_IN; (* Set EP0 State *)
    buf.pktidx := 0; (*reset index to beginning of buffer*)
    buf.pktlen := buf.length; (*to be confirmed*)
    dev.ep_in[0].buffer := buf;
(*
#ifdef USBD_AVOID_PACKET_SPLIT_MPS
  pdev->ep_in[0].rem_length = 0U;
#else
*)
    dev.ep_in[0].rem_length := buf.length;
(*
#endif /* USBD_AVOID_PACKET_SPLIT_MPS */
*)
    dev.Transmit(dev, 0, buf); (* Start the transfer *)
  END CtlSendData;

  (**
  * @brief  USBD_CtlContinueSendData
  *         continue sending data on the ctl pipe
  * @param  pdev: device instance
  * @param  buff: pointer to data buffer
  * @retval status
  *)
  PROCEDURE CtlContinueSendData*(dev: DDef.Handle; buf: Def.Buffer);
  BEGIN dev.Transmit(dev, 0, buf) (* Start the next transfer *)
  END CtlContinueSendData;

  (**
  * @brief  USBD_CtlPrepareRx
  *         receive data on the ctl pipe
  * @param  pdev: device instance
  * @param  buff: pointer to data buffer
  * @retval status
  *)
  PROCEDURE CtlPrepareRx*(dev: DDef.Handle; buf: Def.Buffer);
  BEGIN
    dev.ep0_state := DDef.EP0_DATA_OUT; (* Set EP0 State *)
    buf.pktidx := 0; (*reset index to beginning of buffer*)
    buf.pktlen := buf.length; (*to be confirmed*)
    dev.ep_out[0].buffer := buf;
(*
#ifdef USBD_AVOID_PACKET_SPLIT_MPS
  pdev->ep_out[0].rem_length = 0U;
#else
*)
    dev.ep_out[0].rem_length := buf.length;
(*
#endif /* USBD_AVOID_PACKET_SPLIT_MPS */
*)
    dev.PrepareReceive(dev, 0, buf); (* Start the transfer *)
  END CtlPrepareRx;

  (**
  * @brief  USBD_CtlContinueRx
  *         continue receive data on the ctl pipe
  * @param  pdev: device instance
  * @param  buff: pointer to data buffer
  * @retval status
  *)
  PROCEDURE CtlContinueRx*(dev: DDef.Handle; buf: Def.Buffer);
  BEGIN dev.PrepareReceive(dev, 0, buf)
  END CtlContinueRx;

  (**
  * @brief  USBD_CtlSendStatus
  *         send zero lzngth packet on the ctl pipe
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE CtlSendStatus*(dev: DDef.Handle);
  BEGIN
    dev.ep0_state := DDef.EP0_STATUS_IN; (* Set EP0 State *)
    dev.Transmit(dev, 0, NIL); (* Start the transfer *)
  END CtlSendStatus;

  (**
  * @brief  USBD_CtlReceiveStatus
  *         receive zero length packet on the ctl pipe
  * @param  pdev: device instance
  * @retval status
  *)
  PROCEDURE CtlReceiveStatus*(dev: DDef.Handle);
  BEGIN dev.ep0_state := DDef.EP0_STATUS_OUT; (* Set EP0 State *)
    dev.PrepareReceive(dev, 0, NIL) (* Start the transfer *)
  END CtlReceiveStatus;

  (**
  * @brief  USBD_GetRxCount
  *         returns the received data length
  * @param  pdev: device instance
  * @param  ep_addr: endpoint address
  * @retval Rx Data blength
  *)
  PROCEDURE GetRxCount*(dev: DDef.Handle; ep_addr: BYTE): INTEGER;
  
    RETURN dev.GetRxDataSize(dev, ep_addr)
  END GetRxCount;

END USBDIoReq.
