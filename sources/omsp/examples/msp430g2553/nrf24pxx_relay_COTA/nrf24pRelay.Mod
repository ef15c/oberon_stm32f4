MODULE nrf24pRelay;
  IMPORT SYSTEM, M := msp430g2553, Delay := msp430delay, N := nrf24l01p, T := nrf24pRelayTypes, MH := minihdlc, LCD := pcd8544;

  CONST MESSAGE_VERSION = 2;

    BUFREPSZ = 33;
    NOT_CONFIGURED = 0; ASK_FOR_NEXT_CHUNK = 1; (* must immediately precede WAIT_FOR_CONFIGURATION *)
    WAIT_FOR_CONFIGURATION = 2; WAIT_FOR_NEXT_CHUNK = 3; WAIT_FOR_NEXT_CHUNK_2 = 4;
    ABORT = 5; ABORTED = 6; MESSAGE_ERROR = 7; WAIT_FOR_HOST_NOTIFICATION = 8;
    WAIT_FOR_NO_CHANGE_HOST_NOTIFICATION = 9; HOST_NOTIFIED = 10; CONFIGURED = 11;

    config = SYSTEM.VAL(T.Config, 1080H); (*INFO B*)
    ko = "KO"; (*Config KO, triggers a request for full configuration sending by host*)
    next = "NC"; (*Asks host for sending next configuration data chunk*)
    ok = "OK"; (*Notifys host that the configuration is good and applied*)
    radioResetMsg = "Radio relay reset" + 0AX; (*Log message*)

  VAR confEmitter: N.RadioSetup-; recepteur, emetteur: N.Instance-;
    emetteurReady, pushButtonEnablementPending, wdtReset: BOOLEAN;
    nbCycles, pos: INTEGER;
    cmd_emi, rep_emi, cmdrep_rec: ARRAY BUFREPSZ OF BYTESET;
    nbOKl, nbOKh, nbKOl, nbKOh, nbRecusl, nbRecush: INTEGER;
    radio_state: INTEGER; control: MH.InstanceDesc;
    confChunkNumber, ownerPipe, i: INTEGER;

  PROCEDURE service_emi;
    VAR cmd, rep: ARRAY 2 OF BYTESET;
     eob, i: INTEGER;
   BEGIN
    IF ~BIT(emetteur.irq.reg^, emetteur.irq.bit) THEN (*something happened to NRF24L01+ breakout*)
      cmd[0] := N.W_REGISTER + N.STATUS; cmd[1] := N.MAX_RT + N.TX_DS + N.RX_DR;
      N.talk(emetteur, 2, PTR(PBYTESET, cmd[0]), PTR(PBYTESET, rep[0])); (*CLear interrupts flags and read status*)
      IF BIT(rep[0], N.MAX_RT) THEN (*Transmission failed*)
        cmd[0] := N.FLUSH_TX; N.talk(emetteur, 1, PTR(PBYTESET, cmd[0]), PTR(PBYTESET, rep[0])); (*Flush TX FIFO*)
        INC(nbKOl); ADC(nbKOh, 0)
      ELSIF BIT(rep[0], N.TX_DS) THEN
        INC(nbOKl); ADC(nbOKh, 0);
        (*Read answer form infrastructure if any*)
        IF BIT(rep[0], N.RX_DR) THEN
          REPEAT (*The answer pipe has a Dynamic Payload Length*)
            cmd[0] := N.R_RX_PL_WID; N.talk(emetteur, 2, PTR(PBYTESET, cmd[0]), PTR(PBYTESET, rep[0]));
            eob := ORD(rep[1]) + 1;
            IF eob > 33 THEN (*The packet is orrupted and must be discarded*)
              cmd[0] := N.FLUSH_RX; N. talk(emetteur, 1, PTR(PBYTESET, cmd[0]), NIL);
            ELSE (*Valid payload*)
              rep_emi[0] := N.R_RX_PAYLOAD; N.talk(emetteur, eob, PTR(PBYTESET, rep_emi[0]), PTR(PBYTESET, rep_emi[0])); (*Read RX FIFO *)
              IF ORD(rep_emi[1]) = confChunkNumber THEN
                FOR i := 2 TO eob - 1 DO MH.char_receiver(PTR(MH.Instance, control), ORD(rep_emi[i])) END; (*Process answer*)
              ELSIF (radio_state # WAIT_FOR_HOST_NOTIFICATION) &
                (radio_state # WAIT_FOR_NO_CHANGE_HOST_NOTIFICATION) THEN
                DEC(confChunkNumber) (*Request for resent of the current chunk*)
              END;
              (*MH.char_receiver can alter radio_stata, so it must be rechecked after that call *)
              IF (radio_state # WAIT_FOR_HOST_NOTIFICATION) &
                (radio_state # WAIT_FOR_NO_CHANGE_HOST_NOTIFICATION) THEN
                radio_state := ASK_FOR_NEXT_CHUNK;
              END
            END;
            cmd[0] := N.R_REGISTER + N.FIFO_STATUS; N.talk(emetteur, 2, PTR(PBYTESET, cmd[0]), PTR(PBYTESET, rep[0])); (* Read FIFO STATUS and STATUS *)
          UNTIL BIT(rep[1], N.RX_EMPTY)
        END
      END;
      emetteurReady := TRUE; (*The device is now ready*)
    END
  END service_emi;

  PROCEDURE flushData;
  BEGIN (*Wait for the device readiness *)
    WHILE ~emetteurReady DO (*The emitter is not ready*)
      (*Disable interrupt to be sure to not be interrupted
       * between event test and sleep mode entering*)
      SYSTEM.BIC_SR(M.GIE); NOP; (*To be sure that interrupts are effectively disabled*)
      IF BIT(emetteur.irq.reg^, emetteur.irq.bit) THEN SYSTEM.BIS_SR(M.LPM3_bits+M.GIE) END; (*Entering low power mode 3*)
      (* __bis_SR_register(GIE);*)
      service_emi;
    END;
    cmd_emi[0] := N.W_TX_PAYLOAD; N.talk(emetteur, pos, PTR(PBYTESET, cmd_emi[0]), NIL); (*Write payload to nRF24l01+ module *)
    N.pulseCE(emetteur); (* Start transmission *)
    pos := 1
  END flushData;

  PROCEDURE transmitInt(data: INTEGER);
  BEGIN cmd_emi[pos] := TOSET(data); INC(pos);
    IF pos >= BUFREPSZ THEN flushData END
  END transmitInt;

  PROCEDURE service_rec;
    VAR i, noPipe, eob: INTEGER;
  BEGIN
    (*process events coming from receiver*)
    IF ~BIT(recepteur.irq.reg^, recepteur.irq.bit) THEN (*something happened to receiver*)
      cmdrep_rec[0] := N.NOP; N.talk(recepteur, 1, PTR(PBYTESET, cmdrep_rec[0]), PTR(PBYTESET, cmdrep_rec[0])); (*reading of status register*)
      IF BIT(cmdrep_rec[0], N.RX_DR) THEN
        N.resetCE(recepteur); (* Exit receiving mode*)
        REPEAT
          (* 1) read payload through SPI *)
          noPipe := ORD(cmdrep_rec[0]*{1..3}); RRA(noPipe, 1); (*get receive pipe number*)
          IF noPipe < config.confReceiver.pipes_count THEN
            eob := config.confReceiver.pipes[noPipe].payload_length + 1;
            IF eob = 1 THEN (*This pipe has dynamic payload*)
              cmdrep_rec[0] := N.R_RX_PL_WID; N.talk(recepteur, 2, PTR(PBYTESET, cmdrep_rec[0]), PTR(PBYTESET, cmdrep_rec[0]));
              eob := ORD(cmdrep_rec[1]) + 1;
              IF eob > 33 THEN (*This packet is corrupted, discard it*)
                cmdrep_rec[0] := N.FLUSH_RX; N.talk(recepteur, 1, PTR(PBYTESET, cmdrep_rec[0]), NIL); eob := 0
              END
            END;
            IF eob # 0 THEN (*valid payload*) INC(nbRecusl); ADC(nbRecush, 0);
              nbCycles := 3; (*Reset nbCycle counter periodically (feed the dog)*)
              transmitInt(ORD("p")); transmitInt(noPipe + ORD("0")); (*tell host what is the source pipe*)
              cmdrep_rec[0] := N.R_RX_PAYLOAD; N.talk(recepteur, eob, PTR(PBYTESET, cmdrep_rec[0]), PTR(PBYTESET, cmdrep_rec[0])); (*Read RX FIFO*)
              FOR i:= 1 TO eob - 1 DO (*Characters "\" and "p" must be escaped by a preceding back slash*)
                IF (CHR(ORD(cmdrep_rec[i])) = "\") OR (CHR(ORD(cmdrep_rec[i])) = "p") THEN  transmitInt(ORD("\")) END;
                transmitInt(ORD(cmdrep_rec[i]))
              END; flushData
            END
          ELSE (*The receiver is not configurated. Discard the packet*)
            cmdrep_rec[0] := N.FLUSH_RX; N.talk(recepteur, 1, PTR(PBYTESET, cmdrep_rec[0]), NIL)
          END;
          (* 2) clear RX_DR IRQ *)
          cmdrep_rec[0] := N.W_REGISTER + N.STATUS; cmdrep_rec[1] := N.RX_DR;
          N.talk(recepteur, 2, PTR(PBYTESET, cmdrep_rec[0]), NIL); (* CLear RX_DR interrupt flag and read status *)
          (* 3) read FIFO_STATUS to check if there are more payloads available in RX FIFO *)
          cmdrep_rec[0] := N.R_REGISTER + N.FIFO_STATUS; N.talk(recepteur, 2, PTR(PBYTESET, cmdrep_rec[0]), PTR(PBYTESET, cmdrep_rec[0]))
        UNTIL BIT(cmdrep_rec[1], N.RX_EMPTY)
      END;
      cmdrep_rec[0] := N.W_REGISTER + N.STATUS; cmdrep_rec[1] := N. RX_DR + N.TX_DS + N.MAX_RT;
      N.talk(recepteur, 2, PTR(PBYTESET, cmdrep_rec[0]), NIL); (* CLear interrupts flags and read status *)
      N.setCE(recepteur); (* Enters receive mode *)
    END;
  END service_rec;

  PROCEDURE transmitIntOnPipe(data, noPipe: INTEGER);
  BEGIN
    IF ownerPipe # noPipe THEN transmitInt(ORD("p")); transmitInt(noPipe + ORD("0"));
      ownerPipe := noPipe
    END;
    transmitInt(data);
  END transmitIntOnPipe;

  PROCEDURE transmitEscapedCharforPipe(data, noPipe: INTEGER);
  BEGIN
    IF (data = ORD("p")) OR (data = ORD("\")) THEN transmitIntOnPipe(ORD("\"), noPipe) END;
    transmitIntOnPipe(data, noPipe)
  END transmitEscapedCharforPipe;

  PROCEDURE transmitString(data: ARRAY OF CHAR; noPipe: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE data[i] # 0X DO transmitEscapedCharforPipe(ORD(data[i]), noPipe); INC(i) END
  END transmitString;

  PROCEDURE transmitBuffer(data: ARRAY OF BYTE; length, noPipe: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE length > 0 DO transmitEscapedCharforPipe(data[i], noPipe);INC(i); DEC(length) END
  END transmitBuffer;

  PROCEDURE enablePushButton;
  BEGIN (*configure the pin connected to button and LCD breakout*)
    BIC(M.P2DIR^, {6}); (*P2.6 input*)
    BIS(M.P2OUT^, {6}); BIS(M.P2REN^, {6}); (*Pullup resistor enabled*)
    REPEAT UNTIL BIT(M.P2IN^, {6});
    IF ~pushButtonEnablementPending THEN (*we can re-enable the button now*)
      BIC(M.P2IFG^, {6}); (*clear pending interrupt*)
      BIS(M.P2IES^, {6}); BIS(M.P2IE^, {6}) (*Enables falling edge interrupts*)
    END
  END enablePushButton;

  PROCEDURE disablePushButton;
  BEGIN (*configure the pin connected to button and LCD breakout*)
    BIC(M.P2IE^, {6}); BIS(M.P2DIR^, {6}); (*Sortie*) BIS(M.P2OUT^, {6}); BIC(M.P2REN^, {6})
  END disablePushButton;

  PROCEDURE applyRadioConfig;
  BEGIN N.resetCE(recepteur); (*Leave receive mode*)
    N.init(recepteur); N.powerUp(recepteur); N.setCE(recepteur); (*Enter receive mode*)
    confChunkNumber := 1; (*Synchronisation for radio reconfiguration*)
  END applyRadioConfig;

  PROCEDURE config_frame_handler(me: MH.Instance; frame_buffer: ARRAY OF BYTE; frame_length: INTEGER);
  (*------------------------------------------------------*
   * Process the configuration message received from host *
   *------------------------------------------------------*)
    VAR config_message!: T.Config; isDifferent: BOOLEAN; i: INTEGER; old_config!, new_config!: PINTEGER;
  BEGIN  config_message := SYSTEM.VAL(T.Config, SYSTEM.ADR(frame_buffer));
    IF config_message.version # MESSAGE_VERSION THEN (*Version mismatch*) radio_state := ABORT
    ELSIF (config_message.confReceiver.pipes_count > 6) OR
      (SYSTEM.SIZE(T.ConfigDesc) - 6*SYSTEM.SIZE(N.RadioPipe) +
       config_message.confReceiver.pipes_count*SYSTEM.SIZE(N.RadioPipe) # frame_length) THEN
      (*Basic tests of message consistency failed*) radio_state := MESSAGE_ERROR
    ELSE isDifferent := FALSE;
      old_config := SYSTEM.VAL(PINTEGER, config); new_config := SYSTEM.VAL(PINTEGER, config_message);
      i := frame_length;
      WHILE ~isDifferent & (i > 0) DO DEC(i, 2);
        IF new_config^ # old_config^ THEN isDifferent := TRUE END;
        INC(ORD(new_config), 2); INC(ORD(old_config), 2)
      END;
      IF isDifferent THEN
        old_config := SYSTEM.VAL(PINTEGER, config); new_config := SYSTEM.VAL(PINTEGER, config_message);
        (*Save the new configuration in flash memory*)
        (* First Erase the flash segment before writing *)
        M.FCTL3^ := M.FWKEY; (*Clear Lock bit to enable erase access*)
        M.FCTL1^ := M.FWKEY + M.ERASE; (*ERASE bit = 1; segment erase mode selected*)
        old_config^ := 0; (*Dummy write to erase Flash segment *)
        (*Write to the flash segment *)
        M.FCTL1^ := M.FWKEY + M.WRT; (*Set WRT bit for byte/word write operation*)
        i := frame_length;
        WHILE i > 0 DO DEC(i, 2); old_config^ := new_config^; (*write to flash location using 16bits word*)
          INC(ORD(new_config), 2); INC(ORD(old_config), 2)
        END;
        M.FCTL1^ := M.FWKEY; (*Clear WRT bit*)
        M.FCTL3^ := M.FWKEY + M.LOCK; (*Set LOCK bit to lock flash memory*)
        applyRadioConfig;
        LCD.SetVop(config.lcd_vop); (*set VOP for LCD device; VOP is set to a+lcd_vop x b [V]*)
        radio_state := WAIT_FOR_HOST_NOTIFICATION
      ELSE radio_state := WAIT_FOR_NO_CHANGE_HOST_NOTIFICATION
      END
    END
  END config_frame_handler;

  PROCEDURE requestConfChunk(msg: ARRAY OF CHAR; chunkNumber: INTEGER);
    (*******************************************************
     * Asks for a configration chunk of the radio receiver *
     *******************************************************)
  BEGIN MH.init_frame_to_buffer(PTR(MH.Instance, control)); MH.open_frame(PTR(MH.Instance, control));
    MH.write_byte_to_frame(PTR(MH.Instance, control), chunkNumber); MH.write_string_to_frame(PTR(MH.Instance, control), msg);
    MH.close_frame(PTR(MH.Instance, control));
    transmitBuffer(control.frame_buffer, control.frame_buffer_size, 7); (*The configuration pipe is number 7*)
    flushData
  END requestConfChunk;

  PROCEDURE initConfCom;
  BEGIN confChunkNumber := 1; requestConfChunk(ko, confChunkNumber);
    radio_state := WAIT_FOR_CONFIGURATION
  END initConfCom;

  PROCEDURE displayStatusText(text: ARRAY OF CHAR);
  BEGIN LCD.SetAddr(0, 5); LCD.WriteString(text)
  END displayStatusText;

  (*
   *  ======== PORT1 Interrupt Service Routine ========
   *
   * Here are several important notes on using PORTx interrupt Handler:
   *
   * 1. User must explicitly clear the port interrupt flag before exiting
   *
   *    BIC(M.PxIFG^, {y});
   *
   * 2. User could also exit from low power mode and continue with main
   *    program execution by using the following instruction before exiting
   *    this interrupt handler.
   *
   *   SYSTEM.BIC_SR_ON_EXIT(M.LPMx_bits);
   *
   *)
  PROCEDURE* (M.PORT1_VECTOR) PORT1_ISR_HOOK;
  BEGIN IF BIT(M.P1IFG^, N.p1InterruptMask) THEN BIC(M.P1IFG^, N.p1InterruptMask) END;
    SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits); (*triggers event processing in main loop*)
  END PORT1_ISR_HOOK;

  (*
   *  ======== PORT2 Interrupt Service Routine ========
   *
   * Here are several important notes on using PORTx interrupt Handler:
   *
   * 1. User must explicitly clear the port interrupt flag before exiting
   *
   *    BIC(M.PxIFG^, {y});
   *
   * 2. User could also exit from low power mode and continue with main
   *    program execution by using the following instruction before exiting
   *    this interrupt handler.
   *
   *    SYSTEM.BIC_SR_ON_EXIT(M.LPMx_bits);
   *
   *)
  PROCEDURE* (M.PORT2_VECTOR) PORT2_ISR_HOOK;
  BEGIN IF BIT(M.P2IFG^, N.p2InterruptMask) THEN BIC(M.P2IFG^, N.p2InterruptMask) END;
    IF BIT(M.P2IE^, {6}) & BIT(M.P2IFG^, {6}) THEN (*push button pressed*)
      XOR(M.P1OUT^, {0}); (*invert LCD back light state*)
      BIC(M.P2IFG^, {6}); (*for debouning, we suspend button press checking for 100ms*)
      BIC(M.P2IE^, {6}); M.TA0CTL^ := M.TACLR; M.TA0CTL^ := M.TASSEL_1 + M.ID_0 + M.MC_1; (*Start 100 ms timer*)
      pushButtonEnablementPending := TRUE; (*remember that the button is waitong for reactivation*)
    END;
    SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits); (*triggers event processing in main loop*)
  END PORT2_ISR_HOOK;

  (*
   *  ======== Timer0_A3 Interrupt Service Routine ======== 
   *)
  PROCEDURE* (M.TIMER0_A0_VECTOR) TIMER0_A0_ISR_HOOK;
  BEGIN
    (* We have reached the end of the button invaliation period. 
     * We stop the timer.
     * If the button pin is in input mode, we enable the interrupt immediately.
     * Otherwise, the pin is currentmy used by the LCD breakout. The activation
     * enablement will happen as soos as the communication with LDC breakout
     * is done. *)
    M.TA0CTL^ := M.MC_0; (* Stop debounce ms timer *)
    pushButtonEnablementPending := FALSE;
    IF ~BIT(M.P2DIR^, {6}) THEN (* The pin is in input mode: enable interrupt now *)
      BIC(M.P2IFG^, {6}); BIS(M.P2IE^, {6})
    END
  END TIMER0_A0_ISR_HOOK;

  (*
   *  ======== Watchdog Timer Interval Interrupt Handler Generation ========
   *)
  PROCEDURE* (M.WDT_VECTOR) WDT_ISR_HOOK;
  BEGIN DEC(nbCycles); IF nbCycles = 0 THEN M.WDTCTL^ := {} END; (* Triggers a system reset *)
    SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits); (*wake up main loop*)
  END WDT_ISR_HOOK;

BEGIN M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (*stop watchdog timer*)
  (*Emitter configuration definition*)
  confEmitter.direction := N.EMIT; confEmitter.channel := 110; confEmitter.rf_setup := N.LOW_POWER;
  confEmitter.features := N.EN_ACK_PAY; confEmitter.pipes_count := 1;
  confEmitter.pipes[0].payload_length := 0; confEmitter.pipes[0].address := "RSCHO";

  (* The recepteur nRF24lp01+ instance uses USCIB mapped to pin P1.5, P1.6 and P1.7
   * P1.5: Clock
   * P1.6: SOMI
   * P1.7: SIMO
   * P2.1: CE
   * P2.4: CSN
   * P2.0: IRQ
   *)
  recepteur.ce.reg := M.P2OUT; recepteur.ce.bit := {1}; recepteur.csn.reg := M.P2OUT; recepteur.csn.bit := {4};
  recepteur.irq.reg := M.P2IN; recepteur.irq.bit := {0};
  recepteur.txifg.reg := M.IFG2; recepteur.txifg.bit := M.UCB0TXIFG; (* SPI TX Interrupt flag *)
  recepteur.ucbusy.reg := M.UCB0STAT; recepteur.ucbusy.bit := M.UCBUSY;
  recepteur.txbuf := M.UCB0TXBUF;   recepteur.rxbuf := M.UCB0RXBUF;
  recepteur.ready := NIL; (*does not apply to a receiver*)
  recepteur.radio := PTR(N.Radio, config.confReceiver); (*type safe equivalent of recepteur.radio := SYSTEM.VAL(N.Radio, SYSTEM.ADR(config.confReceiver));*)

  (* The emetteur nRF24lp01+ instance uses USCIA mapped to pin P1.4, P1.1 and P1.2
   * P1.4: Clock
   * P1.1: SOMI
   * P1.2: SIMO
   * P2.3: CE
   * P2.2: CSN
   * P1.3: IRQ
   *)
  emetteur.ce.reg := M.P2OUT; emetteur.ce.bit := {3}; emetteur.csn.reg := M.P2OUT; emetteur.csn.bit := {2};
  emetteur.irq.reg := M.P1IN; emetteur.irq.bit := {3};
  emetteur.txifg.reg := M.IFG2; emetteur.txifg.bit := M.UCA0TXIFG; (* SPI TX Interrupt flag *)
  emetteur.ucbusy.reg := M.UCA0STAT; emetteur.ucbusy.bit := M.UCBUSY;
  emetteur.txbuf := M.UCA0TXBUF;   emetteur.rxbuf := M.UCA0RXBUF;
  emetteur.ready := SYSTEM.VAL(PBYTE, SYSTEM.ADR(emetteurReady));
  emetteur.radio := SYSTEM.VAL(N.Radio, SYSTEM.ADR(confEmitter));

  emetteurReady := TRUE; pushButtonEnablementPending := FALSE; wdtReset := BIT(M.IFG1^, M.WDTIFG);
  nbOKl := 0; nbOKh := 0; nbKOl := 0; nbKOh := 0; nbRecusl := 0; nbRecush := 0;
  radio_state := NOT_CONFIGURED; pos := 1; 
  ownerPipe := -1; nbCycles := 3;

  (*
   *  ======== Flash_2xx_graceInit ========
   *  Initialize MSP430F2xx Family Flash Module
   *)
  (* 
   * Flash Memory Control Register 2
   * 
   * FSSEL_1 -- MCLK
   * FN5 -- Flash controller clock divider bit 5
   * ~FN4 -- Flash controller clock divider bit 4
   * FN3 -- Flash controller clock divider bit 3
   * ~FN2 -- Flash controller clock divider bit 2
   * FN1 -- Flash controller clock divider bit 1
   * FN0 -- Flash controller clock divider bit 0
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
  *)
   M.FCTL2^ := M.FWKEY + M.FSSEL_1 + M.FN5 + M.FN3 + M.FN1 + M.FN0;

  (*  ======== GPIO_graceInit ========
   *  Initialize MSP430 General Purpose Input Output Ports
   *
   *  The GPIO registers should be set in a specific order:
   *     PxOUT
   *     PxSEL or PxSELx
   *     PxDIR
   *     PxREN
   *     PxIES
   *     PxIFG
   *     PxIE
   *
   *     This will ensure that:
   *         - IFG doesn't get set by manipulating the pin function, edge
   *           select, and pull-up/down resistor functionalities (see
   *           Section 8.2.6 of the MSP430 User's manual)
   *         - Glitch-free setup (configuring the OUT register _before_
   *           setting the pin direction)
   *         - Pull-up/pull-down resistor enable with the correct direction
   *           (.up. vs. .down.)
   *)
  (*
    * I/O in use:
    *
    * P1.0: LCD NLIGHT
    * P1.1: nRF24lp01+ emitter SOMI
    * P1.2: nRF24lp01+ emitter SIMO + LCD DIN
    * P1.3: nRF24lp01+ emitter IRQ
    * P1.4: nRF24lp01+ emitter Clock + LCD CLK
    * P1.5: nRF24lp01+ receiver Clock
    * P1.6: nRF24lp01+ receiver SOMI
    * P1.7: nRF24lp01+ receiver SIMO
    *
    * P2.0: nRF24lp01+ receiver IRQ
    * P2.1: nRF24lp01+ receiver CE
    * P2.2: nRF24lp01+ emitter CSN
    * P2.3: nRF24lp01+ emiter CE
    * P2.4: nRF24lp01+ receiver CSN
    * P2.5: LCD NCE
    * P2.6: LCD DC (+ push button input)
    * P2.7: LCD NRST
    *
    * So, there is no available input pin to connect the push button...
    * To solve the lack of pin, the push button will be multiplexed with the LCD D/C
    * output, wich will be set as input when communication with LCD breakout is done.
    *)

  M.P1SEL2^ := {1, 2, 4..7}; (* Port 1 Port Select 2 Register *)
  M.P1REN^ := {}; (* Port 1 Resistor Enable Register *)
  M.P1OUT^ := {0}; (* Port 1 Output Register *)
  M.P1SEL^ := {1, 2, 4..7}; (* Port 1 Port Select Register *)
  M.P1DIR^ := {0}; (** Port 1 Direction Register *)
  M.P1IES^ := {}; (* Port 1 Interrupt Edge Select Register *)
  M.P1IFG^ := {}; (* Port 1 Interrupt Flag Register *)

  M.P2SEL2^ := {}; (* Port 2 Port Select 2 Register *)
  M.P2SEL^ := {}; (* Port 2 Port Select Register *)
  M.P2REN^ := {}; (* Port 1 Resistor Enable Register *)
  M.P2OUT^ := {2, 4, 5}; (* Port 2 Output Register *)
  M.P2DIR^ := {1..7}; (* Port 2 Direction Register *)
  M.P2IES^ := {}; (* Port 2 Interrupt Edge Select Register *)
  M.P2IFG^ := {}; (* Port 2 Interrupt Flag Register *)

  M.P3OUT^ := {}; (* Port 3 Output Register *)
  M.P3DIR^ := {}; (* Port 3 Direction Register *)
  M.P3REN^ := {0..7}; (* Port 3 Resistor Enable Register *)

  (*
   *  ======== BCSplus_graceInit ========
   *  Initialize MSP430 Basic Clock System
   *)
  (* 
   * Basic Clock System Control 2
   * 
   * SELM_0 -- DCOCLK
   * DIVM_0 -- Divide by 1
   * ~SELS -- DCOCLK
   * DIVS_0 -- Divide by 1
   * ~DCOR -- DCO uses internal resistor
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.BCSCTL2^ := M.SELM_0 + M.DIVM_0 + M.DIVS_0;
  IF M.CALBC1_16MHZ^ # {0..7} THEN Delay.CyclesX3(100000 DIV 3); (* Adjust this accordingly to your VCC rise time *)
    (* Follow recommended flow. First, clear all DCOx and MODx bits. Then
     * apply new RSELx values. Finally, apply new DCOx and MODx bit values.
     *)
    M.DCOCTL^ := {}; M.BCSCTL1^ := M.CALBC1_16MHZ^; (* Set DCO to 16MHz *) M.DCOCTL^ := M.CALDCO_16MHZ^
  END;
  (* 
   * Basic Clock System Control 1
   * 
   * XT2OFF -- Disable XT2CLK
   * ~XTS -- Low Frequency
   * DIVA_3 -- Divide by 8
   * 
   * Note: ~XTS indicates that XTS has value zero
   *)
  BIS(M.BCSCTL1^, M.XT2OFF + M.DIVA_3);
  (* 
   * Basic Clock System Control 3
   * 
   * XT2S_0 -- 0.4 - 1 MHz
   * LFXT1S_2 -- If XTS = 0, XT1 = VLOCLK ; If XTS = 1, XT1 = 3 - 16-MHz crystal or resonator
   * XCAP_1 -- ~6 pF
   *)
  M.BCSCTL3^ := M.XT2S_0 + M.LFXT1S_2 + M.XCAP_1;

  (*
   *  ======== USCI_A0_graceInit ========
   *  Initialize Universal Serial Communication Interface A0 SPI 2xx
   *)
  BIS(M.UCA0CTL1^, M.UCSWRST); (* Disable USCI *)
  (* 
   * Control Register 0
   * 
   * UCCKPH -- Data is captured on the first UCLK edge and changed on the following edge
   * ~UCCKPL -- Inactive state is low
   * UCMSB -- MSB first
   * ~UC7BIT -- 8-bit
   * UCMST -- Master mode
   * UCMODE_0 -- 3-Pin SPI
   * UCSYNC -- Synchronous Mode
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.UCA0CTL0^ := M.UCCKPH + M.UCMSB + M.UCMST + M.UCMODE_0 + M.UCSYNC;
  (* 
   * Control Register 1
   * 
   * UCSSEL_2 -- SMCLK
   * UCSWRST -- Enabled. USCI logic held in reset state
   *)
  M.UCA0CTL1^ := M.UCSSEL_2 + M.UCSWRST;
  M.UCA0BR0^ := 8; (* Bit Rate Control Register 0 *)
  BIC(M.UCA0CTL1^, M.UCSWRST); (* Enable USCI *)

  (*
   *  ======== USCI_B0_graceInit ========
   *  Initialize Universal Serial Communication Interface B0 SPI 2xx
   *)
  BIS(M.UCB0CTL1^, M.UCSWRST); (* Disable USCI *)
  (* 
   * Control Register 0
   * 
   * UCCKPH -- Data is captured on the first UCLK edge and changed on the following edge
   * ~UCCKPL -- Inactive state is low
   * UCMSB -- MSB first
   * ~UC7BIT -- 8-bit
   * UCMST -- Master mode
   * UCMODE_0 -- 3-Pin SPI
   * UCSYNC -- Synchronous Mode
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.UCB0CTL0^ := M.UCCKPH + M.UCMSB + M.UCMST + M.UCMODE_0 + M.UCSYNC;
  (* 
   * Control Register 1
   * 
   * UCSSEL_2 -- SMCLK
   * UCSWRST -- Enabled. USCI logic held in reset state
   *)
  M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST;
  M.UCB0BR0^ := 8; (* Bit Rate Control Register 0 *)
  BIC(M.UCB0CTL1^, M.UCSWRST);  (* Enable USCI *)

  (*
   *  ======== System_graceInit ========
   *  Initialize MSP430 Status Register
   *)
  (* Clear oscillator fault flag with software delay *)
  REPEAT BIC(M.IFG1^, M.OFIFG); (*Clear OSC fault flag*)
    Delay.CyclesX3(800 DIV 3) (* 50us delay*)
  UNTIL ~BIT(M.IFG1^, M.OFIFG);
  BIC(M.IFG1^, M.WDTIFG); (*Clear WDT interrupt flag*)
  (* 
   * IE1, Interrupt Enable Register 1
   * 
   * ~ACCVIE -- Interrupt not enabled
   * ~NMIIE -- Interrupt not enabled
   * ~OFIE -- Interrupt not enabled
   * WDTIE -- Interrupt enabled
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  BIS(M.IE1^, M.WDTIE);
  (* 
   * SR, Status Register
   * 
   * ~SCG1 -- Disable System clock generator 1
   * ~SCG0 -- Disable System clock generator 0
   * ~OSCOFF -- Oscillator On
   * ~CPUOFF -- CPU On
   * GIE -- General interrupt enable
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  SYSTEM.BIS_SR(M.GIE);

  (*
   *  ======== Timer0_A3_graceInit ========
   *  Initialize MSP430 Timer0_A3 timer
   *)
  (* 
   * TA0CCTL0, Capture/Compare Control Register 0
   * 
   * CM_0 -- No Capture
   * CCIS_0 -- CCIxA
   * ~SCS -- Asynchronous Capture
   * ~SCCI -- Latched capture signal (read)
   * ~CAP -- Compare mode
   * OUTMOD_0 -- PWM output mode: 0 - OUT bit value
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.TA0CCTL0^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_0 + M.CCIE;
  M.TA0CCR0^ := 299; (** TA0CCR0, Timer_A Capture/Compare Register 0 *)
  M.TA0CTL^ := M.MC_0; (*Timer stopped*)

  (*
   *  ======== WDTplus_graceInit ========
   *  Initialize MSP430 Watchdog Timer+
   *)
  (* 
   * WDTCTL, Watchdog Timer+ Register
   * 
   * WDTPW -- Watchdog password
   * ~WDTHOLD -- Watchdog timer+ is not stopped
   * ~WDTNMIES -- NMI on rising edge
   * ~WDTNMI -- Reset function
   * WDTTMSEL -- Interval timer mode
   * ~WDTCNTCL -- No action
   * WDTSSEL -- ACLK
   * ~WDTIS0 -- Watchdog clock source bit0 disabled
   * ~WDTIS1 -- Watchdog clock source bit1 disabled
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.WDTCTL^ := M.WDTPW + M.WDTTMSEL + M.WDTSSEL;

  (*reset LCD with a low pulse during at least 100 ns*)

  N.registerIrq(recepteur);
  N.registerIrq(emetteur);

  BIS(LCD.PO_NRST^, LCD.NRST); (*~RESET going HIGH => Start LCD module*)
  LCD.Init; LCD.Clear; IF config.lcd_vop # 0FFH THEN LCD.SetVop(config.lcd_vop) END;
  BIC(LCD.PO_NLIGHT^, LCD.NLIGHT); (*turn backlight on*)
  LCD.WriteString("nRF24L01+relay");
  IF wdtReset THEN LCD.WriteString("--Wdt reset---") ELSE LCD.WriteString("--------------") END;
  LCD.WriteString("r             ");
  LCD.WriteString("eOK           ");
  LCD.WriteString("eKO           ");

  N.init(emetteur); N.powerUp(emetteur);
  MH.init(PTR(MH.Instance, control), NIL, config_frame_handler, 0);

  REPEAT LCD.WriteLongint(0, nbCycles, 11, 1, 3, "-");
    service_emi(); (*Process pending interrupt coming from the emitter*)
    IF radio_state = NOT_CONFIGURED THEN (*Init receiver nRF24l01+ breakout*)
      IF wdtReset OR (recepteur.radio.pipes_count = 0FFH) THEN initConfCom
        (*we don't have locally a working configuration, ask one from host*)
      ELSE applyRadioConfig; radio_state := CONFIGURED; displayStatusText("Conf applied  ")
      END
    ELSIF radio_state = ASK_FOR_NEXT_CHUNK THEN (*ask for next chunk*)
      INC(confChunkNumber); requestConfChunk(next, confChunkNumber); radio_state := WAIT_FOR_NEXT_CHUNK
    ELSIF (radio_state = WAIT_FOR_NEXT_CHUNK) OR (radio_state = WAIT_FOR_NEXT_CHUNK_2)
      OR (radio_state = WAIT_FOR_CONFIGURATION) THEN INC(radio_state);
      requestConfChunk(next, confChunkNumber); (*ask host again for the current chunk*)
    ELSIF radio_state = ABORT THEN displayStatusText("Conf aborted  "); confChunkNumber := 1; radio_state := ABORTED
    ELSIF radio_state = MESSAGE_ERROR THEN displayStatusText("Conf msg error"); initConfCom
    ELSIF (radio_state = WAIT_FOR_HOST_NOTIFICATION) OR (radio_state = WAIT_FOR_NO_CHANGE_HOST_NOTIFICATION) THEN
      MH.init_frame_to_buffer(PTR(MH.Instance, control));
      MH.open_frame(PTR(MH.Instance, control));
      MH.write_byte_to_frame(PTR(MH.Instance, control), confChunkNumber);
      MH.write_string_to_frame(PTR(MH.Instance, control), ok);
      MH.close_frame(PTR(MH.Instance, control));
      ownerPipe := -1; (*To force the identification of the pipe for the host*)
      transmitBuffer(control.frame_buffer, control.frame_buffer_size, 7); flushData;
      transmitString(radioResetMsg, 6); transmitString("Services: ", 6);
      FOR i := 0 TO config.confReceiver.pipes_count - 1 DO
        transmitIntOnPipe(i + ORD("0"), 6); transmitIntOnPipe(ORD("/"), 6);
        transmitString(config.confReceiver.pipes[i].address, 6); transmitIntOnPipe(ORD(" "), 6)
      END; transmitIntOnPipe(0AH, 6); flushData;
      IF radio_state = WAIT_FOR_HOST_NOTIFICATION THEN displayStatusText("Conf OK,->host")
      ELSE displayStatusText("Nchg OK,->host")
      END; radio_state := HOST_NOTIFIED
    END;
    LCD.WriteLongint(nbRecush, nbRecusl, 4, 2, 10, " "); (*display receiving stats*)
    LCD.WriteLongint(nbOKh, nbOKl, 4, 3, 10, " ");
    LCD.WriteLongint(nbKOh, nbKOl, 4, 4, 10, " "); (*display transmiting stats*)
    service_rec;
    (* Entering in low power mode *)
    enablePushButton;
    IF BIT(emetteur.irq.reg^, emetteur.irq.bit) & BIT(recepteur.irq.reg^, recepteur.irq.bit) THEN
      (* Nothing happened to radio breakouts, sleeping is allowed*)
      SYSTEM.BIS_SR(M.LPM3_bits  + M.GIE)
    END; disablePushButton
  UNTIL FALSE
END nrf24pRelay.

System.Free StackTrace OMSPP OMSPL OMSPTool OMSPD OMSPG OMSPA OMSPB OMSPS~
OMSPP.Compile nrf24l01p.Mod/s nrf24pRelayTypes.Mod/s minihdlc.Mod/s pcd8544.Mod/s nrf24pRelay.Mod/s ~
OMSPL.Link 32 4000H 200H nrf24pRelay~
  linking msp430g2553 msp430delay nrf24l01p nrf24pRelayTypes minihdlc MultiPrecisionArith pcd8544 nrf24pRelay
    flash 6774, data  282, stack  230 bytes

OMSPTool.DecObj nrf24pRelay.mpc
