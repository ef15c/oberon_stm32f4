MODULE USBHHal;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   The HAL part of USB Host configuration file.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2017 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  *)

  IMPORT SYSTEM, BSP, Kernel, Log := USBLog, Def := USBHDef, Core := USBHCore, ll := LLUSB, HCD := HALHCD;

  CONST
    (*TODO: relocate in BSP Module*)
    OTGHSEN* = 29;
    othsEn* = BSP.PeriphBBAlias + (BSP.RCC_BASE + BSP.AHB1ENR - BSP.PeriphBase + OTGHSEN DIV 8)*32 + OTGHSEN MOD 8*4;
    OTGHS_IRQNum* = 16+77;

    (*private constants*)
    POWERSW_PORT = BSP.GPIOC;
    POWERSW_VBUS = 4;

  VAR hhcd: HCD.Handle;

  (**
  * @brief  This function handles USB-On-The-Go FS/HS global interrupt request.
  * @param  None
  * @retval None
  *)
  PROCEDURE^5 OTG_HS_IRQHandler;
  BEGIN HCD.IRQHandler(hhcd); LED({4})
  END OTG_HS_IRQHandler;

  PROCEDURE MspInit(hhcd: HCD.Handle);
    VAR en: BYTE; irqNum: INTEGER;
  BEGIN
    (* On STM32F429I-DISCO, USB OTG HS Core will operate in Full speed mode.
        GPIOB and GPIOC are already clocked in BSP *)
    (* EMBEDDED Physical interface and  VBUS Pin *)
    BSP.configureGPIO(BSP.GPIOB, {13, 14, 15}, LSL(BSP.MASK2, 13*2) + LSL(BSP.MASK2, 14*2) + LSL(BSP.MASK2, 15*2), {},
      LSL(BSP.MASK4, 13 MOD 8*4) + LSL(BSP.MASK4, 14 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4),
      LSL(BSP.INPUT_MODE, 13*2) + LSL(BSP.AF_MODE, 14*2) + LSL(BSP.AF_MODE, 15*2), (*PB13 as input and PB14, PB15 as AF*)
      LSL(BSP.VERY_HIGH_SPEED, 14*2) + LSL(BSP.VERY_HIGH_SPEED, 15*2), (*PB14 and PB15 very high speed*)
      {} (*push pull*), {} (*no pull up nor pul down*), {},
      LSL(TOSET(12), 14 MOD 8*4) + LSL(TOSET(12), 15 MOD 8*4) (* PB14 and PB15 ad alternate function OTG HS *)
    );
    SYSTEM.PUT(othsEn, TRUE); SYSTEM.GET(othsEn, en) (*delay*); (* Enable USB HS Clocks *)
    (* Configure Power Switch Vbus Pin *)
    SYSTEM.PUT(POWERSW_PORT + BSP.BSRR, {POWERSW_VBUS});
    BSP.configureGPIO(POWERSW_PORT, {POWERSW_VBUS}, LSL(BSP.MASK2, POWERSW_VBUS*2), {}, {},
      LSL(BSP.OUTPUT_MODE, POWERSW_VBUS*2), {}, {}, {}, {}, {});
    Kernel.Delayms(200); (* Delay is need for stabilising the Vbus Low *)
    SYSTEM.PUT(BSP.NVIC_IPR + OTGHS_IRQNum - 16, CHR(LSL(11, 4))); (* Set USBHS Interrupt priority lower than SysTick *)
    (* Enable USBFS Interrupt *)
    Kernel.Install(SYSTEM.ADR(OTG_HS_IRQHandler), BSP.VecTabBase + OTGHS_IRQNum*4);
    irqNum := OTGHS_IRQNum - 16;
    SYSTEM.PUT(BSP.NVIC_ISER + irqNum DIV 32*4, {irqNum MOD 32})
  END MspInit;

  (**
  * @brief  DeInitializes the HCD MSP.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE MspDeInit(hhcd: HCD.Handle);
  BEGIN SYSTEM.PUT(othsEn, FALSE) (* Disable USB HS Clocks *)
  END MspDeInit;

  (*******************************************************************************
                       LL Driver Callbacks (HCD -> USB Host Library)
  *******************************************************************************)

  (**
  * @brief  SOF callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE SOF_Callback(hhcd: HCD.Handle);
    VAR phost!: Def.Handle;
  BEGIN phost := SYSTEM.VAL(Def.Handle, hhcd.pData);
    Core.IncTimer(phost)
  END SOF_Callback;

  (**
  * @brief  Connect callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE Connect_Callback(hhcd: HCD.Handle);
    VAR phost!: Def.Handle;
  BEGIN phost := SYSTEM.VAL(Def.Handle, hhcd.pData);
    Core.Connect(phost)
  END Connect_Callback;

  (**
  * @brief  Disconnect callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE Disconnect_Callback(hhcd: HCD.Handle);
    VAR phost!: Def.Handle;
  BEGIN phost := SYSTEM.VAL(Def.Handle, hhcd.pData);
    Core.Disconnect(phost)
  END Disconnect_Callback;

  (**
  * @brief  Port Port Enabled callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE PortEnabled_Callback(hhcd: HCD.Handle);
    VAR phost!: Def.Handle;
  BEGIN phost := SYSTEM.VAL(Def.Handle, hhcd.pData);
    Core.PortEnabled(phost)
  END PortEnabled_Callback;

  (**
  * @brief  Port Port Disabled callback.
  * @param  hhcd: HCD handle
  * @retval None
  *)
  PROCEDURE PortDisabled_Callback(hhcd: HCD.Handle);
    VAR phost!: Def.Handle;
  BEGIN phost := SYSTEM.VAL(Def.Handle, hhcd.pData);
    Core.PortDisabled(phost)
  END PortDisabled_Callback;

  (**
  * @brief  Notify URB state change callback.
  * @param  hhcd: HCD handle
  * @param  chnum:
  * @param  urb_state:
  * @retval None
  *)
  PROCEDURE HC_NotifyURBChange_Callback(hhcd: HCD.Handle; chnum, urb_state: BYTE);
  BEGIN (* To be used with OS to sync URB state with the global state machine *)
  END HC_NotifyURBChange_Callback;

  (**
  * @brief  Gets a URB state from the low level driver.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  *          This parameter can be a value from 1 to 15
  * @retval URB state
  *          This parameter can be one of these values:
  *            @arg URB_IDLE
  *            @arg URB_DONE
  *            @arg URB_NOTREADY
  *            @arg URB_NYET
  *            @arg URB_ERROR
  *            @arg URB_STALL
  *)
  PROCEDURE GetURBState(phost: Def.Handle; pipe: BYTE): BYTE;
    RETURN HCD.HC_GetURBState(SYSTEM.VAL(HCD.Handle, phost.pData), pipe)
  END GetURBState;

  (**
  * @brief  Drives VBUS.
  * @param  phost: Host handle
  * @param  state: VBUS state
  *          This parameter can be one of these values:
  *           0: VBUS Active
  *           1: VBUS Inactive
  * @retval USBH Status
  *)
  PROCEDURE DriverVBUS*(phost: Def.Handle; state: BOOLEAN);
  BEGIN
    (*
     * On-chip 5 V VBUS generation is not supported. For this reason, a charge
     * pump or, if 5 V are available on the application board, a basic power
     * switch, must be added externally to drive the 5 V VBUS line. The external
     * charge pump can be driven by any GPIO output. When the application
     * decides to power on VBUS using the chosen GPIO, it must also set the port
     * power bit in the host port control and status register (PPWR bit in
     * OTG_FS_HPRT).
     *
     * Bit 12 PPWR: Port power The application uses this field to control power
     * to this port, and the core clears this bit on an overcurrent condition. *)
    IF ~state THEN (* DISABLE is needed on output of the Power Switch *)
      SYSTEM.PUT(POWERSW_PORT + BSP.BSRR, {POWERSW_VBUS})
    ELSE (* ENABLE the Power Switch by driving the Enable LOW *)
      SYSTEM.PUT(POWERSW_PORT + BSP.BSRR, LSL({POWERSW_VBUS}, 16))
    END
  END DriverVBUS;

  (**
  * @brief  Resets the Host Port of the Low Level Driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE ResetPort*(phost: Def.Handle);
  BEGIN HCD.ResetPort(SYSTEM.VAL(HCD.Handle, phost.pData))
  END ResetPort;

  (**
  * @brief  Returns the last transferred packet size.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  * @retval Packet Size
  *)
  PROCEDURE GetLastXferSize(phost:Def.Handle; pipe: BYTE): INTEGER;
    RETURN HCD.HC_GetXferCount(SYSTEM.VAL(HCD.Handle, phost.pData), pipe)
  END GetLastXferSize;

  (**
  * @brief  Opens a pipe of the Low Level Driver.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  * @param  epnum: Endpoint Number
  * @param  dev_address: Device USB address
  * @param  speed: Device Speed
  * @param  ep_type: Endpoint Type
  * @param  mps: Endpoint Max Packet Size
  * @retval USBH Status
  *)
  PROCEDURE OpenPipe(phost: Def.Handle; pipe, epnum, dev_address, speed, ep_type: BYTE; mps: HALFWORD);
    VAR res: BYTE;
  BEGIN res := HCD.HC_Init(SYSTEM.VAL(HCD.Handle, phost.pData), pipe, epnum, dev_address, speed, ep_type, mps)
  END OpenPipe;

  (**
  * @brief  Sets toggle for a pipe.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  * @param  toggle: toggle (0/1)
  * @retval USBH Status
  *)
  PROCEDURE SetToggle(phost: Def.Handle; pipe: BYTE; toggle: BOOLEAN);
    VAR hcd!: HCD.Handle;
  BEGIN hcd := SYSTEM.VAL(HCD.Handle, phost.pData);
    IF hcd.hc[pipe].ep_is_in THEN hcd.hc[pipe].toggle_in := toggle
    ELSE hcd.hc[pipe].toggle_out := toggle;
    END
  END SetToggle;

  (**
  * @brief  Closes a pipe of the Low Level Driver.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  * @retval USBH Status
  *)
  PROCEDURE ClosePipe(phost: Def.Handle; pipe: BYTE);
  BEGIN HCD.HC_Halt(SYSTEM.VAL(HCD.Handle, phost.pData), pipe)
  END ClosePipe;

  (**
  * @brief  Submits a new URB to the low level driver.
  * @param  phost: Host handle
  * @param  pipe: Pipe index
  *          This parameter can be a value from 1 to 15
  * @param  direction: Channel number
  *          This parameter can be one of these values:
  *           0: Output
  *           1: Input
  * @param  ep_type: Endpoint Type
  *          This parameter can be one of these values:
  *            @arg EP_TYPE_CTRL: Control type
  *            @arg EP_TYPE_ISOC: Isochronous type
  *            @arg EP_TYPE_BULK: Bulk type
  *            @arg EP_TYPE_INTR: Interrupt type
  * @param  token: Endpoint Type
  *          This parameter can be one of these values:
  *            @arg 0: PID_SETUP
  *            @arg 1: PID_DATA
  * @param  pbuff: pointer to URB data
  * @param  length: length of URB data
  * @param  do_ping: activate do ping protocol (for high speed only)
  *          This parameter can be one of these values:
  *           0: do ping inactive
  *           1: do ping active
  * @retval USBH Status
  *)
  PROCEDURE SubmitURB(phost: Def.Handle; pipe: BYTE; direction: BOOLEAN; ep_type, token: BYTE;
  	pbuff: INTEGER; length: HALFWORD; do_ping: BOOLEAN);
  BEGIN
    HCD.HC_SubmitRequest(SYSTEM.VAL(HCD.Handle, phost.pData), pipe,
      direction, ep_type, token, pbuff, length, do_ping)
  END SubmitURB;

(*******************************************************************************
                       LL Driver Interface (USB Host Library --> HCD)
*******************************************************************************)
  (**
  * @brief  Stops the Low Level portion of the Host driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Stop*(phost: Def.Handle);
  BEGIN HCD.Stop(SYSTEM.VAL(HCD.Handle, phost.pData));
  END Stop;

  (**
  * @brief  Starts the Low Level portion of the Host driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Start*(phost: Def.Handle);
  BEGIN HCD.Start(SYSTEM.VAL(HCD.Handle, phost.pData))
  END Start;

  (**
  * @brief  Initializes the Low Level portion of the Host driver.
  * @param  phost: Host handle
  * @retval USBH Status
  *)
  PROCEDURE Init*(phost: Def.Handle): BYTE;
    VAR res: BYTE;
  BEGIN (* Set LL Driver parameters *)
    hhcd.Instance := SYSTEM.VAL(ll.OTGCore, ll.HS_PERIPH_BASE);
    hhcd.Init.Host_channels := 11;
    hhcd.Init.dma_enable := FALSE;
    hhcd.Init.low_power_enable := FALSE;
    hhcd.Init.phy_itface := ll.EMBEDDED_PHY;
    hhcd.Init.Sof_enable := FALSE;
    hhcd.Init.speed := HCD.SPEED_HIGH;
    hhcd.Init.use_external_vbus := FALSE;
    (* Link The driver to the stack *)
    hhcd.pData := ORD(phost);
    phost.pData := ORD(hhcd);
    (* Initialize LL Driver *)
    IF HCD.Init(hhcd) # ll.HAL_OK THEN res := Def.FAIL
    ELSE Core.SetTimer(phost, HCD.GetCurrentFrame(hhcd)); res := Def.OK;
      Log.UserString("Core version: "); Log.UserHexVLen(ORD(hhcd.Instance.GSNPSID), 8, FALSE); Log.UserLn
    END;
    (*Oberon specific callbacks*)
    phost.Stop := Stop;
    phost.OpenPipe := OpenPipe;
    phost.SetToggle := SetToggle;
    phost.ClosePipe := ClosePipe;
    phost.SubmitURB := SubmitURB;
    phost.GetURBState := GetURBState;
    phost.GetLastXferSize := GetLastXferSize

    RETURN res
  END Init;

  (**
  * @brief  Returns the USB Host Speed from the Low Level Driver.
  * @param  phost: Host handle
  * @retval USBH Speeds
  *)
  PROCEDURE GetSpeed*(phost: Def.Handle): BYTE;
    VAR cs: BYTE;
  BEGIN cs := HCD.GetCurrentSpeed(SYSTEM.VAL(HCD.Handle, phost.pData));
    IF cs = 3 THEN cs := Def.SPEED_HIGH END

    RETURN cs
  END GetSpeed;

BEGIN NEW(hhcd);
  hhcd.MspInitCallback := MspInit;
  hhcd.MspDeInitCallback := MspDeInit;
  hhcd.SOFCallback := SOF_Callback;
  hhcd.ConnectCallback := Connect_Callback;
  hhcd.DisconnectCallback := Disconnect_Callback;
  hhcd.PortEnabledCallback :=  PortEnabled_Callback;
  hhcd.PortDisabledCallback := PortDisabled_Callback;
  hhcd.HC_NotifyURBChangeCallback := HC_NotifyURBChange_Callback;
END USBHHal.

OM4Tool.DecSym USBHHal.sm4
