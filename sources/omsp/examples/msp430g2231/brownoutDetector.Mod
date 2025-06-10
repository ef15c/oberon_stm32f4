MODULE brownoutDetector;
  IMPORT SYSTEM, M := msp430g2231, Delay := msp430delay;

(* This hardware module sample the supply voltage of an Helios4 NAS.
  The data is available via an I2C interface.

  It does not use the smbus protocol, although it has the interesting capability
  to allow diynamic addresses (ARP), for two reasons :
    it is quite heavy to implement and the only over devices present on the card
    is a sh1106 diwplay module, which doesn't support the smbus protocol
 
  So we need an I2C address. We could choose an adress reserved for prototyping,
  but the final chois is to use an unused one on the Helios4.
  
  Adresse selected : 15H
*)

(* Divisor bridge:
  12.6v --[R1]--x--[R2]-- 0v
  with R1 = 22 kOhms and R2 = 4.7 kOhms
  to bring the measured voltage under 3.3 V
*)

  CONST MY_ADDRESS = 15H;
    MES_BEAT = 1; AUX = 3; (* The LEDs assignments *)
    RECOVERY = 2; (* The push button assignment *)

    MAX_INACTIVITY_DURATION = 60; (* The maximum of inactivity duration before triggering a bus recovery *)
    NB_REGISTERS = 4; (* The total number of registers *)

  (* The I2C state machine *)
    IDLE = 0;
    GET_ADDRESS = 1;
    WAIT_FOR_REGISTER_ADDRESS = 2;
    GET_REGISTER_ADDRESS = 3;
    NO_MORE_DATA_ALLOWED = 4;
    READ_REGISTER = 5;
    WAIT_FOR_MASTER_ACKNOWLEDGE = 6;
    GET_MASTER_ACKNOWLEDGE = 7;

  VAR buffer: ARRAY 8 OF INTEGER;
    adc10ConversionDone: BOOLEAN; recoverMaster: BYTE;
    inactivityDuration, r, i: INTEGER;
    registers: ARRAY NB_REGISTERS OF INTEGER;
    i2c_state: INTEGER; (* The I2C state machine state *)
    regAddr: INTEGER;
    localCopyOfRegisters: ARRAY NB_REGISTERS*2 OF BYTE;

  PROCEDURE USI_graceInit;
  (*
   *  ======== USI_graceInit ========
   *  Initialize Universal Serial Interface
   *)
  BEGIN
    BIS(M.USICTL0^, M.USISWRST); (* Disable USI *)

    (* 
     * USI Control Register 0
     * 
     * USIPE7 -- USI function enabled
     * USIPE6 -- USI function enabled
     * ~USIPE5 -- USI function disabled
     * ~USILSB -- MSB first
     * ~USIMST -- Slave mode
     * ~USIGE -- Output latch enable depends on shift clock
     * ~USIOE -- Output disabled
     * USISWRST -- USI logic held in reset state
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     *)
    M.USICTL0^ := M.USIPE7 + M.USIPE6 + M.USISWRST;

    (* 
     * USI Control Register 1
     * 
     * ~USICKPH -- Data is changed on the first SCLK edge and captured on the following edge
     * USII2C -- I2C mode enabled
     * USISTTIE -- Interrupt on START condition enabled
     * USIIE -- Interrupt enabled
     * ~USIAL -- No arbitration lost condition
     * ~USISTP -- No STOP condition received
     * ~USISTTIFG -- No START condition received. No interrupt pending
     * USIIFG -- Interrupt pending
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     *)
    M.USICTL1^ := M.USII2C + M.USISTTIE + M.USIIE + M.USIIFG;

    (* 
     * USI Clock Control Register
     * 
     * USIDIV_0 -- Divide by 1
     * USISSEL_2 -- SMCLK
     * USICKPL -- Inactive state is high
     * ~USISWCLK -- Input clock is low
     * 
     * Note: ~USISWCLK indicates that USISWCLK has value zero
     *)
    M.USICKCTL^ := M.USIDIV_0 + M.USISSEL_2 + M.USICKPL;

    (* 
     * USI Bit Counter Register
     * 
     * ~USISCLREL -- SCL line is held low if USIIFG is set
     * ~USI16B -- 8-bit shift register mode. Low byte register USISRL is used
     * USIIFGCC -- USIIFG is not cleared automatically
     * ~USICNT4 -- USI bit count
     * ~USICNT3 -- USI bit count
     * ~USICNT2 -- USI bit count
     * ~USICNT1 -- USI bit count
     * ~USICNT0 -- USI bit count
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     *)
    M.USICNT^ := M.USIIFGCC;
    i2c_state := IDLE;

    BIC(M.USICTL0^, M.USISWRST); (* Enable USI *)
  END USI_graceInit;

  PROCEDURE master_recovery;
  BEGIN (* Generate nine pulses in order to perform bus recovery *)
    SYSTEM.BIC_SR(M.GIE); (*  __disable_interrupt();*)
    BIS(M.P1OUT^, {AUX}); (* Turn AUX led on *)

    M.USICTL1^ := M.USII2C; (* I2C mode with no interrupts *)
    BIS(M.USICTL0^, M.USISWRST); (* Disable USI *)
    M.USICTL0^ := M.USIPE7 + M.USIPE6 + M.USIMST + M.USISWRST; (* Switch to master mode, in order send 9 clock pulses *)
    M.USICKCTL^ := M.USIDIV_2 + M.USISSEL_2 + M.USICKPL; (* Use SMCLK divided by 4 *)
    M.USICNT^ := M.USI16B; (* 16bit mode *)
    BIC(M.USICTL0^, M.USISWRST); (* Enable USI *)
    BIS(M.USICNT^, 9); (* Send 9 pulses *)

    REPEAT UNTIL BIT(M.USICTL1^, M.USIIFG); (* wait for end of transmission *)

    BIS(M.USICTL0^, M.USISWRST); (* Disable USI *)

    USI_graceInit; (* reinit USI in operational slave mode *)

    BIC(M.P1OUT^, {AUX}); (* Turn AUX led off *)
    SYSTEM.BIS_SR(M.GIE); (*__enable_interrupt();*)
  END master_recovery;

(* Interrupt handlers *)

  PROCEDURE* (M.PORT1_VECTOR)  PORT1_ISR_HOOK;
    (*
     *  ======== PORT1 Interrupt Service Routine ========
     *
     * Here are several important notes on using PORTx interrupt Handler:
     *
     * 1. User must explicitly clear the port interrupt flag before exiting
     *
     *    PxIFG &= ~(BITy);
     *
     * 2. User could also exit from low power mode and continue with main
     *    program execution by using the following instruction before exiting
     *    this interrupt handler.
     *
     *    __bic_SR_register_on_exit(LPMx_bits);
     *
    *)
  BEGIN
    IF BIT(M.P1IFG^, {RECOVERY}) THEN IF recoverMaster = 0 THEN recoverMaster := 1 END;
      BIC(M.P1IFG^, {RECOVERY}); SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits)
    END
  END PORT1_ISR_HOOK;

  PROCEDURE* (M.ADC10_VECTOR) ADC10_ISR_HOOK;
    (*
     *  ======== ADC10 Interrupt Service Routine ========
     *)
  BEGIN adc10ConversionDone := TRUE; SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Process conversion in main loop *)
  END ADC10_ISR_HOOK;

  PROCEDURE* (M.TIMERA1_VECTOR) TIMERA1_ISR_HOOK;
    (*
     *  ======== Timer_A2 Interrupt Service Routine ======== 
     *)
  BEGIN
    IF M.TAIV^ = M.TAIV_TACCR1 THEN
      (* TIMEOUT -> cancel the current I2C transaction *)
      BIC(M.USICTL0^, M.USIOE); (* SDA = input *)
      M.USICNT^ := M.USIIFGCC + M.USISCLREL; (* Release clock until next START condition *)
      BIC(M.P1OUT^, {AUX}); (* Turn AUX led off *)
      i2c_state := IDLE;
      M.TACCTL1^ := {}; (* Disable TACCR1 interrupt *)
      INC( registers[1]) (* Increment transaction timeout count *)
    END
  END TIMERA1_ISR_HOOK;

  PROCEDURE* (M.USI_VECTOR) {4, 14, 15} USI_ISR_HOOK;
    (* For now, only value 0x00 to 0x07 are implemented *)
    CONST REGISTER_INDEX_MASK = TOSET(7);
  VAR adr: INTEGER*;
  BEGIN
    IF BIT(M.USICTL1^, M.USISTTIFG) THEN
      M.USICNT^ := M.USIIFGCC + TOSET(8); (* Bit counter = 8, RX address*)
      BIC(M.USICTL1^, M.USISTTIFG); (* Clear start flag *)
      i2c_state := GET_ADDRESS; inactivityDuration := 0
    ELSIF BIT(M.USICTL1^, M.USIIFG) THEN
      IF i2c_state = IDLE THEN (* No current or complete transaction : ignore the data *)
      ELSIF i2c_state = GET_ADDRESS THEN (* Check if this is our address *) adr := M.USISRL^; RRA(adr, 1);
        IF adr = MY_ADDRESS THEN
          BIS(M.P1OUT^, {AUX}); (* Turn AUX led on *)
            (* Acknowledge address *)
            IF ODD(M.USISRL^) THEN i2c_state := READ_REGISTER ELSE i2c_state := WAIT_FOR_REGISTER_ADDRESS END;
            BIS(M.USICTL0^, M.USIOE); (* SDA = output*)
            M.USISRL^ := 0; M.USICNT^ := M.USIIFGCC + TOSET(1); (* Bit counter = 1, send Ack bit *)
            (* Launch a timer to cancel the transaction if it takes too long *)
            WHILE M.TACCR1^ # M.TAR^ DO M.TACCR1^ := M.TAR^ END; (* Prevent async capture *)
            INC(M.TACCR1^, 1200); (* Wait for 0.1s *)
            IF M.TACCR1^ >= M.TACCR0^ THEN DEC(M.TACCR1^, M.TACCR0^) (* Put TACCR1 in TCCCR0 range *) END;
            M.TACCTL1^ := M.CCIE; (* Enable TACCR1 interrupt *)
        ELSE (* This transaction is for somebody else *)
          M.USICNT^ := M.USIIFGCC + M.USISCLREL; (* Release clock until next START condition *)
          i2c_state := IDLE
        END
      ELSIF i2c_state = WAIT_FOR_REGISTER_ADDRESS THEN
        BIC(M.USICTL0^, M.USIOE); (* SDA = input *)
        M.USICNT^ := M.USIIFGCC + TOSET(8); (* Bit counter = 8, RX data *)
        i2c_state := GET_REGISTER_ADDRESS (* Go to next state: Test REGISTER_ADDRESS and (N)Ack *)
      ELSIF i2c_state =  GET_REGISTER_ADDRESS THEN (* Read register address *)
(*        regAddr := M.USISRL^ MOD (2*NB_REGISTERS);*)
        regAddr := ORD(TOSET(M.USISRL^)*REGISTER_INDEX_MASK);
        SYSTEM.COPY(SYSTEM.ADR(registers), SYSTEM.ADR(localCopyOfRegisters), NB_REGISTERS); (* Make a local copy of the registers *)
        (* Acknowledge register address *)
        BIS(M.USICTL0^, M.USIOE); (* SDA = output *)
        M.USISRL^ := 0;
        M. USICNT^ := M.USIIFGCC + TOSET(1); (* Bit counter = 1, send Ack bit *)
        i2c_state := NO_MORE_DATA_ALLOWED
      ELSIF i2c_state =  NO_MORE_DATA_ALLOWED THEN
        BIC(M.USICTL0^, M.USIOE); (* SDA = input *)
        i2c_state := IDLE; (* Wait for restart *)
        BIC(M.P1OUT^, {AUX}); (* Turn AUX led off *)
        M.TACCTL1^ := {} (* Disable TACCR1 interrupt *)
      ELSIF (i2c_state =  GET_MASTER_ACKNOWLEDGE) & ODD(M.USISRL^) THEN (* Masterdidn't acknowledge the data *)
        (* stop sending registers data *)
        i2c_state := IDLE; (* Send no more data *)
        BIC(M.P1OUT^, {AUX}); (* Turn AUX led off *)
        M.TACCTL1^ := {} (* Disable TACCR1 interrupt *)
      ELSIF (i2c_state =  GET_MASTER_ACKNOWLEDGE) OR (i2c_state = READ_REGISTER) THEN
        (* Send byte in register at address regAddr *)
        BIS(M.USICTL0^, M.USIOE); (* SDA = output *)
        M.USISRL^ := localCopyOfRegisters[regAddr];
        INC(regAddr); regAddr := ORD(TOSET(regAddr)*REGISTER_INDEX_MASK);
        M.USICNT^ := M.USIIFGCC + TOSET(8); (* Bit counter = 8, send data *)
        i2c_state := WAIT_FOR_MASTER_ACKNOWLEDGE
      ELSIF i2c_state =  WAIT_FOR_MASTER_ACKNOWLEDGE THEN
        BIC(M.USICTL0^, M.USIOE); (* SDA = input *)
        M.USICNT^ := M.USIIFGCC + TOSET(1); (* Bit counter = 1, Wait for master acknowledge *)
        i2c_state := GET_MASTER_ACKNOWLEDGE (* Process master acknowledgment *)
      END;
      BIC(M.USICTL1^, M.USIIFG); (* Clear pending flags *)
    END
  END USI_ISR_HOOK;

BEGIN M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (*stop watchdog during initial start-up*)
  adc10ConversionDone := FALSE; recoverMaster := 0;
  inactivityDuration := 0; registers[0] := 0; registers[1] := 0; registers[2] := 0;
  IF BIT(M.IFG1^, M.WDTIFG) THEN INC(registers[3]); (*count PUC triggered by the watchdog*)
    BIC(M.IFG1^, M.WDTIFG);
  ELSE registers[3] := 0
  END;
  
  (*
   *  ======== GPIO_graceInit ========
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
    M.P1OUT^ := {RECOVERY}; (* Port 1 Output Register *)
    M.P1DIR^ := {MES_BEAT, AUX}; (* Port 1 Direction Register *)
    M.P1REN^ := {RECOVERY, 4, 5}; (* Port 1 Resistor Enable Register *)
    M.P1IES^ := {RECOVERY}; (* Port 1 Interrupt Edge Select Register *)
    M.P1IFG^ := {}; (* Port 1 Interrupt Flag Register *)
    M.P1IE^ := {RECOVERY}; (* Port 1 Interrupt Enable Register *)

    M.P2OUT^ := {}; (* Port 2 Output Register *)
    BIC(M.P2SEL^, {6, 7}); (* Port 2 Port Select Register *)
    M.P2DIR^ := {};    (* Port 2 Direction Register *)
    M.P2REN^ := {6, 7}; (* Port 2 Resistor Enable Register *)
    M.P2IES^ := {}; (* Port 2 Interrupt Edge Select Register *)
    M.P2IFG^ := {}; (* Port 2 Interrupt Flag Register *)

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
  IF M.CALBC1_1MHZ^ # {0..7} THEN
    (* Follow recommended flow. First, clear all DCOx and MODx bits. Then
     * apply new RSELx values. Finally, apply new DCOx and MODx bit values.
     *)
    M.DCOCTL^ := {};
    M.BCSCTL1^ := M.CALBC1_1MHZ^; (* Set DCO to 1MHz *)
    M.DCOCTL^ := M.CALDCO_1MHZ^
  END;

  (* 
   * Basic Clock System Control 1
   * 
   * XT2OFF -- Disable XT2CLK
   * ~XTS -- Low Frequency
   * DIVA_0 -- Divide by 1
   * 
   * Note: ~XTS indicates that XTS has value zero
   *)
  BIS(M.BCSCTL1^, M.XT2OFF + M.DIVA_0);

  (* 
   * Basic Clock System Control 3
   * 
   * XT2S_0 -- 0.4 - 1 MHz
   * LFXT1S_2 -- If XTS = 0, XT1 = VLOCLK ; If XTS = 1, XT1 = 3 - 16-MHz crystal or resonator
   * XCAP_1 -- ~6 pF
   *)
  M.BCSCTL3^ := M.XT2S_0 + M.LFXT1S_2 + M.XCAP_1;

  USI_graceInit; (*initialize config for the MSP430 USI*)

  (*
   *  ======== ADC10_graceInit ========
   *  Initialize MSP430 10-bit Analog to Digital Converter
   *)
  BIC(M.ADC10CTL0^, M.ENC); (* disable ADC10 during initialization *)

  (* 
   * Control Register 0
   * 
   * ~ADC10SC -- No conversion
   * ~ENC -- Disable ADC
   * ~ADC10IFG -- Clear ADC interrupt flag
   * ADC10IE -- Enable ADC interrupt
   * ADC10ON -- Switch On ADC10
   * REFON -- Enable ADC reference generator
   * REF2_5V -- Set reference voltage generator = 2.5V
   * MSC -- Enable multiple sample and conversion
   * REFBURST -- Reference buffer on only during sample-and-conversion
   * ~REFOUT -- Reference output off
   * ~ADC10SR -- Reference buffer supports up to ~200 ksps
   * ADC10SHT_3 -- 64 x ADC10CLKs
   * SREF_1 -- VR+ = VREF+ and VR- = VSS
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.ADC10CTL0^ := M.ADC10IE + M.ADC10ON + M.REFON + M.REF2_5V + M.MSC + M.REFBURST + M.ADC10SHT_3 + M.SREF_1;

  (* 
   * Control Register 1
   * 
   * ~ADC10BUSY -- No operation is active
   * CONSEQ_2 -- Repeat single channel
   * ADC10SSEL_0 -- ADC10OSC
   * ADC10DIV_0 -- Divide by 1
   * ~ISSH -- Input signal not inverted
   * ~ADC10DF -- ADC10 Data Format as binary
   * SHS_2 -- Timer_A OUT0
   * INCH_0 -- ADC Channel 0
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.ADC10CTL1^ := M.CONSEQ_2 + M.ADC10SSEL_0 + M.ADC10DIV_0 + M.SHS_2 + M.INCH_0;

  M.ADC10AE0^ := {0}; (* Analog (Input) Enable Control Register 0 *)
  M.ADC10DTC1^ := 8; (* Data Transfer Control Register 1 *)
  M.ADC10SA^ := SYSTEM.ADR(buffer); (* Data Transfer Start Address *)
  Delay.CyclesX3(10000); (* Software delay for REFON to settle *)
  BIS(M.ADC10CTL0^, M.ENC); (* enable ADC10 *)

  (*
   *  ======== System_graceInit ========
   *  Initialize MSP430 Status Register
   *)
  (* Clear oscillator fault flag with software delay *)
  REPEAT BIC(M.IFG1^, M.OFIFG); (* Clear OSC fault flag *)
    Delay.CyclesX3(51 DIV 3); (* 50us delay *)
  UNTIL ~BIT(M.IFG1^, M.OFIFG);

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
   *  ======== Timer_A2_graceInit ========
   *  Initialize MSP430 Timer_A2 timer
   *)
  (* 
   * TACCTL0, Capture/Compare Control Register 0
   * 
   * CM_0 -- No Capture
   * CCIS_0 -- CCIxA
   * ~SCS -- Asynchronous Capture
   * ~SCCI -- Latched capture signal (read)
   * ~CAP -- Compare mode
   * OUTMOD_4 -- PWM output mode: 4 - Toggle
   * 
   * Note: ~<BIT> indicates that <BIT> has value zero
   *)
  M.TACCTL0^ := M.CM_0 + M.CCIS_0 + M.OUTMOD_4;

  M.TACCR0^ := 5999; (* TACCR0, Timer_A Capture/Compare Register 0 *)

  (* 
   * TACTL, Timer_A2 Control Register
   * 
   * TASSEL_1 -- ACLK
   * ID_0 -- Divider - /1
   * MC_1 -- Up Mode
   *)
  M.TACTL^ := M.TASSEL_1 + M.ID_0 + M.MC_1;

  (*configure watchdog timer in watchdog mode on ACLK*)
  M.WDTCTL^ := M.WDTPW + M.WDTCNTCL + M.WDTSSEL;

  REPEAT
    IF recoverMaster = 1 THEN master_recovery; recoverMaster := 2
    ELSIF recoverMaster = 2 THEN recoverMaster := 0
    END;
    IF adc10ConversionDone THEN adc10ConversionDone := FALSE;
      BIC(M.ADC10CTL0^, M.ENC); XOR(M.P1OUT^, {MES_BEAT}); (* Toggle MES_BEAT led *)
      i := 8; r := 0; REPEAT DEC(i); INC(r, buffer[i]) UNTIL i = 0; RRA(r, 3); (* Compute meam value des 8 mesures *)
      registers[0] := r; (* To avoid race condition, do an atomic copy of r into result *)

      REPEAT UNTIL ~BIT(M.ADC10CTL1^, M.ADC10BUSY); (* Wait until ADC10 core is not active *)
      M.ADC10SA^ := SYSTEM.ADR(buffer); (* Data buffer start *)
      BIS(M.ADC10CTL0^, M.ENC); (* Sampling and conversion ready *)
    END;
    IF (inactivityDuration > MAX_INACTIVITY_DURATION) & (recoverMaster = 0) THEN
      recoverMaster := 1; inactivityDuration := 0; INC(registers[2]) (* Increment inactivity timeout count *)
    ELSE INC(inactivityDuration); SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3, enable interrupts *)
      M.WDTCTL^ := M.WDTPW + M.WDTCNTCL + M.WDTSSEL (*feed the dog*)
    END;
  UNTIL FALSE
END brownoutDetector.

OMSPP.Compile brownoutDetector.Mod~
OMSPL.Link 32 800H 80H brownoutDetector~
  linking msp430g2231 msp430delay brownoutDetector
    flash  972, data   44, stack   84 bytes

OMSPTool.DecObj brownoutDetector.mpc
