MODULE USBHal; (*The BSP part of USB Core configuration, C. Schoffit 01.07.26*)
  IMPORT SYSTEM, Kernel, BSP, Log := USBLog, Def := USBDef, ll := LLUSB, Q := Queue, UC := HALUC;

  CONST
    (*TODO: relocate in BSP Module*)
    OTGHSEN* = 29;
    othsEn* = BSP.PeriphBBAlias + (BSP.RCC_BASE + BSP.AHB1ENR - BSP.PeriphBase + OTGHSEN DIV 8)*32 + OTGHSEN MOD 8*4;
    OTGHS_IRQNum* = 16+77;

    (*private constants*)
    POWERSW_PORT = BSP.GPIOC;
    POWERSW_VBUS = 4;

  VAR hsid: BYTE; OldHandler: INTEGER;

  (**
  * @brief  This function handles USB-On-The-Go FS/HS global interrupt request.
  * @param  None
  * @retval None
  *)
  PROCEDURE^5 OTG_HS_IRQHandler;
  BEGIN UC.IRQHandler(Def.usbCores[hsid](UC.Handle))
  END OTG_HS_IRQHandler;

  (**
  * @brief  Initializes the CD MSP.
  * @retval None
  *)
  PROCEDURE MspInit;
    VAR en: BYTE; irqNum: INTEGER;
  BEGIN
    (* On STM32F429I-DISCO, USB OTG HS Core will operate in Full speed mode.
        GPIOB and GPIOC are already clocked in BSP *)
    (* EMBEDDED Physical interface and  VBUS Pin *)
    BSP.configureGPIO(BSP.GPIOB, {12, 13, 14, 15},
      LSL(BSP.MASK2, 12*2) + LSL(BSP.MASK2, 13*2) + LSL(BSP.MASK2, 14*2) + LSL(BSP.MASK2, 15*2),
      {}, LSL(BSP.MASK4, 12 MOD 8*4) + LSL(BSP.MASK4, 13 MOD 8*4) + LSL(BSP.MASK4, 14 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4),
      LSL(BSP.AF_MODE, 12*2) +LSL(BSP.INPUT_MODE, 13*2) + LSL(BSP.AF_MODE, 14*2) + LSL(BSP.AF_MODE, 15*2), (*PB13 as input and PB12, PB14, PB15 as AF*)
      LSL(BSP.VERY_HIGH_SPEED, 14*2) + LSL(BSP.VERY_HIGH_SPEED, 15*2), (*PB14 and PB15 very high speed*)
      {} (*push pull*), {} (*no pull up nor pul down*), {},
      LSL(TOSET(12), 12 MOD 8*4) + LSL(TOSET(12), 14 MOD 8*4) + LSL(TOSET(12), 15 MOD 8*4) (* PB12, PB14 and PB15 ad alternate function OTG HS *)
    );
    SYSTEM.PUT(othsEn, TRUE); SYSTEM.GET(othsEn, en) (*delay*); (* Enable USB HS Clocks *)
    (* Configure Power Switch Vbus Pin *)
    SYSTEM.PUT(POWERSW_PORT + BSP.BSRR, {POWERSW_VBUS});
    BSP.configureGPIO(POWERSW_PORT, {POWERSW_VBUS}, LSL(BSP.MASK2, POWERSW_VBUS*2), {}, {},
      LSL(BSP.OUTPUT_MODE, POWERSW_VBUS*2), {}, {}, {}, {}, {});
    Kernel.Delayms(200); (* Delay is need for stabilising the Vbus Low *)
    SYSTEM.PUT(BSP.NVIC_IPR + OTGHS_IRQNum - 16, CHR(LSL(11, 4))); (* Set USBHS Interrupt priority lower than SysTick *)
    (* Enable OTGHS Interrupt *)
    SYSTEM.GET(BSP.VecTabBase + OTGHS_IRQNum*4, OldHandler);
    Kernel.Install(SYSTEM.ADR(OTG_HS_IRQHandler), BSP.VecTabBase + OTGHS_IRQNum*4);
    irqNum := OTGHS_IRQNum - 16;
    SYSTEM.PUT(BSP.NVIC_ISER + irqNum DIV 32*4, {irqNum MOD 32})
  END MspInit;

  (**
  * @brief  DeInitializes the USB Core.
  * @retval None
  *)
  PROCEDURE MspDeInit;
  BEGIN SYSTEM.PUT(othsEn, FALSE); (* Disable USB HS Clocks *)
    Kernel.Install(SYSTEM.ADR(OldHandler), BSP.VecTabBase + OTGHS_IRQNum*4);
  END MspDeInit;

  (**
  * @brief  Initializes the USB Core.
  * @retval Core Driver handle
  *)
  PROCEDURE Init*(UserFunc: Def.UserCallback; id: BYTE): UC.Handle;
    VAR core!: UC.Handle;
  BEGIN ASSERT(id < Def.NB_OTG_CORES);
    IF Def.usbCores[id] = NIL THEN NEW(core); UC.InitPools(core);
    ELSE core := Def.usbCores[id](UC.Handle)
    END;
    IF hsid = 0FFH THEN MspInit END; (* Init the low level hardware : GPIO, CLOCK, NVIC... *)
    (* Set LL Driver parameters *)
    core.Instance := SYSTEM.VAL(ll.OTGCore, ll.HS_PERIPH_BASE);
    core.Init.dma_enable := FALSE;
    core.Init.phy_itface := ll.EMBEDDED_PHY;
    core.Init.speed := Def.SPEED_HIGH;
    core.id := id;
    core.User := UserFunc;
    IF UC.Init(core) = ll.HAL_OK THEN (* Initialize LL Driver *)
      hsid := id;
      Log.Debug("Core version: "); Log.DebugHexVLen(ORD(core.Instance.GSNPSID), 8, FALSE); Log.DebugLn;
      Log.Flush
    ELSE core := NIL; hsid := 0FFH
    END

    RETURN core
  END Init;

  (**
  * @brief  DeInitializes the USB Core.
  * @retval Core Driver handle
  *)
  PROCEDURE DeInit*(core: UC.Handle);
  BEGIN ASSERT(core.Instance = Def.usbCores[hsid](UC.Handle).Instance);
    IF core # NIL THEN
      UC.DeInit(core); MspDeInit; hsid := 0FFH
    END
  END DeInit;

  (**
  * @brief  Drives VBUS.
  * @param  phost: Host handle
  * @param  state: VBUS state
  *          This parameter can be one of these values:
  *           0: VBUS Active
  *           1: VBUS Inactive
  * @retval USBH Status
  *)
  PROCEDURE DriverVBUS*(core: UC.Handle; state: BOOLEAN);
  BEGIN ASSERT(core.Instance = Def.usbCores[hsid](UC.Handle).Instance);
    (*
     * On-chip 5 V VBUS generation is not supported. For this reason, a charge
     * pump or, if 5 V are available on the application board, a basic power
     * switch, must be added externally to drive the 5 V VBUS line. The external
     * charge pump can be driven by any GPIO output. When the application
     * decides to power on VBUS using the chosen GPIO, it must also set the port
     * power bit in the host port control and status register (PPWR bit in
     * OTG_HS_HPRT).
     *
     * Bit 12 PPWR: Port power The application uses this field to control power
     * to this port, and the core clears this bit on an overcurrent condition. *)
    IF ~state THEN (* DISABLE is needed on output of the Power Switch *)
      SYSTEM.PUT(POWERSW_PORT + BSP.BSRR, {POWERSW_VBUS})
    ELSE (* ENABLE the Power Switch by driving the Enable LOW *)
      SYSTEM.PUT(POWERSW_PORT + BSP.BSRR, LSL({POWERSW_VBUS}, 16))
    END;
    Kernel.Delayms(1000)
  END DriverVBUS;

  PROCEDURE IsHost*(core: UC.Handle): BOOLEAN;

    RETURN ll.IsHost(core.Instance)
  END IsHost;

  PROCEDURE IRQLog(msg: UC.DebugMsg);
  BEGIN Log.Debug("["); Log.DebugInt(msg.time, 10); Log.DebugString("] IRQ ");
    Log.DebugString(", gintsts: ");  Log.DebugSet(msg.gintsts);
    Log.DebugLn
  END IRQLog;

  (**
  * @brief  Do the work offloaded by IRQs in the process loop.
  *)
  PROCEDURE ProcessMsg(msg: Q.Msg; core: UC.Handle);
  BEGIN
  END ProcessMsg;

  (**
  * @brief  Retrieve and process IRQ messages.
  *)
  PROCEDURE ProcessDeferredIRQWork*(core: UC.Handle);
    VAR msg!: Q.Msg;
  BEGIN
    msg := UC.TakeMsg(core);
    WHILE msg # NIL DO
      CASE msg OF
(*       UC.InitControllerMsg: InitController(pusb)
      |*)  UC.DebugMsg: IRQLog(msg)
      | Q.Msg: ASSERT(FALSE) (*unknown message type*)
      END; UC.GiveMsg(core, msg);
      msg := UC.TakeMsg(core)
    END
  END ProcessDeferredIRQWork;

BEGIN hsid := 0FFH
END USBHal.
