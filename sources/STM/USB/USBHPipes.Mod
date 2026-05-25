MODULE USBHPipes;
  IMPORT Def := USBHDef;
  (** ported to Oberon from:
  * @author  MCD Application Team
  * @brief   This file implements functions for opening and closing Pipes
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

  (** @defgroup USBH_PIPES_Private_Functions
  * @{
  *)

  (**
  * @brief  USBH_GetFreePipe
  * @param  phost: Host Handle
  *         Get a free Pipe number for allocation to a device endpoint
  * @retval idx: Free Pipe number
  *)
  PROCEDURE GetFreePipe(phost: Def.Handle): HALFWORD;
    VAR idx: BYTE; res: HALFWORD;
  BEGIN res := 0FFFFH; idx := 0;
    WHILE (res = 0FFFFH) & (idx < Def.MAX_PIPES_NBR) DO
      IF ~(15 IN phost.Pipes[idx]) THEN res :=  idx END;
      INC(idx)
    END

    RETURN res
  END GetFreePipe;

  (**
  * @}
  *)

  (**
  * @brief  USBH_Open_Pipe
  *         Open a  pipe
  * @param  phost: Host Handle
  * @param  pipe_num: Pipe Number
  * @param  dev_address: USB Device address allocated to attached device
  * @param  speed : USB device speed (Full/Low)
  * @param  ep_type: end point type (Bulk/int/ctl)
  * @param  mps: max pkt size
  * @retval USBH Status
  *)
  PROCEDURE Open*(phost: Def.Handle; pipe_num, epnum, dev_address, speed, ep_type: BYTE; mps: HALFWORD);
  BEGIN phost.OpenPipe(phost, pipe_num, epnum, dev_address, speed, ep_type, mps)
  END Open;

  (**
  * @brief  USBH_ClosePipe
  *         Close a  pipe
  * @param  phost: Host Handle
  * @param  pipe_num: Pipe Number
  * @retval USBH Status
  *)
  PROCEDURE Close*(phost: Def.Handle; pipe_num: BYTE);
  BEGIN phost.ClosePipe(phost, pipe_num)
  END Close;

  (**
  * @brief  USBH_Alloc_Pipe
  *         Allocate a new Pipe
  * @param  phost: Host Handle
  * @param  ep_addr: End point for which the Pipe to be allocated
  * @retval Pipe number
  *)
  PROCEDURE Alloc*(phost: Def.Handle; ep_addr: BYTE): BYTE;
    VAR pipe: HALFWORD; res: BYTE;
  BEGIN   pipe :=  GetFreePipe(phost);
    IF pipe # 0FFFFH THEN phost.Pipes[pipe MOD 10H] := {15} + TOSET(ep_addr) END;
    res := pipe

    RETURN res
  END Alloc;

  (**
  * @brief  USBH_Free_Pipe
  *         Free the USB Pipe
  * @param  phost: Host Handle
  * @param  idx: Pipe number to be freed
  * @retval USBH Status
  *)
  PROCEDURE Free*(phost: Def.Handle; idx: BYTE);
  BEGIN IF idx < Def.MAX_PIPES_NBR THEN EXCL(phost.Pipes[idx], 31) END
  END Free;

END USBHPipes.
