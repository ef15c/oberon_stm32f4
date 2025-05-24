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

(*
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
*)

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
  i2c_state := IDLE;
  
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
    END
  UNTIL FALSE
END brownoutDetector.

OMSPP.Compile brownoutDetector.Mod~
OMSPL.Link 32 800H 80H brownoutDetector~
  linking msp430g2231 msp430delay brownoutDetector
    flash  906, data   44, stack   84 bytes

OMSPTool.DecObj brownoutDetector.mpc
decode brownoutDetector.mpc
brownoutDetector 7CA09DC1 Flash   886
imports:
	msp430g2231 5D5FCA6E
	msp430delay EE6A4099
type descriptors

data    44
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF 0000 FFFF 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 020C
fixup procedures in code space chains
 028E     0	 0000
 02E8     0	 0022
 02C4     2	 0001
fixup handlers in vector space chains
 0112     0	 0064
 0115     0	 0080
 0114     0	 008C
fixup data in code space chains
 0338     0	 0014
 0326     0	 0016
 0344     0	 0000
 0366     0	 001C
 0224     0	 001A
 01C6     0	 0024
 033A     0	 0018
 01D8     0	 0022
 036C     0	 0012
 022C     0	 0020
 0302     0	 0010
 035E     0	 0011
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
entry =  020C
code   886
 0000	     D3D2	BIS.B #1,&120
 0002	     0078
 0004	     40F2	MOV.B #193,&120
 0006	     00C1
 0008	     0078
 000A	     40F2	MOV.B #113,&121
 000C	     0071
 000E	     0079
 0010	     40F2	MOV.B #10,&122
 0012	     000A
 0014	     007A
 0016	     40F2	MOV.B #32,&123
 0018	     0020
 001A	     007B
 001C	     C3D2	BIC.B #1,&120
 001E	     0078
 0020	     4130	RET
 0022	     C232	BIC #8,SR
 0024	     D2F2	BIS.B #8,&33
 0026	     0021
 0028	     40F2	MOV.B #64,&121
 002A	     0040
 002C	     0079
 002E	     D3D2	BIS.B #1,&120
 0030	     0078
 0032	     40F2	MOV.B #201,&120
 0034	     00C9
 0036	     0078
 0038	     40F2	MOV.B #74,&122
 003A	     004A
 003C	     007A
 003E	     40F2	MOV.B #64,&123
 0040	     0040
 0042	     007B
 0044	     C3D2	BIC.B #1,&120
 0046	     0078
 0048	     D0F2	BIS.B #9,&123
 004A	     0009
 004C	     007B
 004E	     B3D2	BIT.B #1,&121
 0050	     0079
 0052	     27FD	JEQ $-4, goes to  004E
 0054	     D3D2	BIS.B #1,&120
 0056	     0078
 0058	     12B0	CALL #0
 005A	     0000
 005C	     C2F2	BIC.B #8,&33
 005E	     0021
 0060	     D232	BIS #8,SR
 0062	     4130	RET
 0064	     B2E2	BIT.B #4,&35
 0066	     0023
 0068	     240A	JEQ $+22, goes to  007E
 006A	     93C2	CMP.B #0,&0
 006C	     0000
 006E	     2002	JNE $+6, goes to  0074
 0070	     43D2	MOV.B #1,&108
 0072	     006C
 0074	     C2E2	BIC.B #4,&35
 0076	     0023
 0078	     C0B1	BIC #208,0(SP)
 007A	     00D0
 007C	     0000
 007E	     1300	RETI
 0080	     43D2	MOV.B #1,&0
 0082	     0000
 0084	     C0B1	BIC #208,0(SP)
 0086	     00D0
 0088	     0000
 008A	     1300	RETI
 008C	     120F	PUSH R15
 008E	     120E	PUSH R14
 0090	     1204	PUSH R4
 0092	     B3E2	BIT.B #2,&121
 0094	     0079
 0096	     240A	JEQ $+22, goes to  00AC
 0098	     40F2	MOV.B #40,&123
 009A	     0028
 009C	     007B
 009E	     C3E2	BIC.B #2,&121
 00A0	     0079
 00A2	     4392	MOV #1,&0
 00A4	     0000
 00A6	     4382	MOV #0,&0
 00A8	     0000
 00AA	     3CAC	JMP $+346, goes to  0204
 00AC	     B3D2	BIT.B #1,&121
 00AE	     0079
 00B0	     24A9	JEQ $+340, goes to  0204
 00B2	     9382	CMP #0,&164
 00B4	     00A4
 00B6	     2001	JNE $+4, goes to  00BA
 00B8	     3CA3	JMP $+328, goes to  0200
 00BA	     9392	CMP #1,&180
 00BC	     00B4
 00BE	     2035	JNE $+108, goes to  012A
 00C0	     425E	MOV.B &124,R14
 00C2	     007C
 00C4	     4E04	MOV R14,R4
 00C6	     1104	RRA R4
 00C8	     9034	CMP #21,R4
 00CA	     0015
 00CC	     2028	JNE $+82, goes to  011E
 00CE	     D2F2	BIS.B #8,&33
 00D0	     0021
 00D2	     B3D2	BIT.B #1,&124
 00D4	     007C
 00D6	     2404	JEQ $+10, goes to  00E0
 00D8	     40B2	MOV #5,&188
 00DA	     0005
 00DC	     00BC
 00DE	     3C02	JMP $+6, goes to  00E4
 00E0	     43A2	MOV #2,&220
 00E2	     00DC
 00E4	     D3E2	BIS.B #2,&120
 00E6	     0078
 00E8	     43C2	MOV.B #0,&124
 00EA	     007C
 00EC	     40F2	MOV.B #33,&123
 00EE	     0021
 00F0	     007B
 00F2	     9292	CMP &368,&372
 00F4	     0170
 00F6	     0174
 00F8	     2404	JEQ $+10, goes to  0102
 00FA	     4292	MOV &368,&372
 00FC	     0170
 00FE	     0174
 0100	     3FF8	JMP $-14, goes to  00F2
 0102	     50B2	ADD #1200,&372
 0104	     04B0
 0106	     0174
 0108	     9292	CMP &370,&372
 010A	     0172
 010C	     0174
 010E	     3803	JL $+8, goes to  0116
 0110	     8292	SUB &370,&372
 0112	     0172
 0114	     0174
 0116	     40B2	MOV #16,&356
 0118	     0010
 011A	     0164
 011C	     3C05	JMP $+12, goes to  0128
 011E	     40F2	MOV.B #160,&123
 0120	     00A0
 0122	     007B
 0124	     4382	MOV #0,&226
 0126	     00E2
 0128	     3C6B	JMP $+216, goes to  0200
 012A	     93A2	CMP #2,&294
 012C	     0126
 012E	     2009	JNE $+20, goes to  0142
 0130	     C3E2	BIC.B #2,&120
 0132	     0078
 0134	     40F2	MOV.B #40,&123
 0136	     0028
 0138	     007B
 013A	     40B2	MOV #3,&300
 013C	     0003
 013E	     012C
 0140	     3C5F	JMP $+192, goes to  0200
 0142	     90B2	CMP #3,&318
 0144	     0003
 0146	     013E
 0148	     2017	JNE $+48, goes to  0178
 014A	     421E	MOV &124,R14
 014C	     007C
 014E	     F03E	AND #7,R14
 0150	     0007
 0152	     4E82	MOV R14,&0
 0154	     0000
 0156	     422E	MOV #4,R14
 0158	     403F	MOV #0,R15
 015A	     0000
 015C	     4FBF	MOV @R15+,10(R15)
 015E	     000A
 0160	     831E	SUB #1,R14
 0162	     23FC	JNE $-6, goes to  015C
 0164	     D3E2	BIS.B #2,&120
 0166	     0078
 0168	     43C2	MOV.B #0,&124
 016A	     007C
 016C	     40F2	MOV.B #33,&123
 016E	     0021
 0170	     007B
 0172	     42A2	MOV #4,&326
 0174	     0146
 0176	     3C44	JMP $+138, goes to  0200
 0178	     92A2	CMP #4,&372
 017A	     0174
 017C	     2009	JNE $+20, goes to  0190
 017E	     C3E2	BIC.B #2,&120
 0180	     0078
 0182	     4382	MOV #0,&378
 0184	     017A
 0186	     C2F2	BIC.B #8,&33
 0188	     0021
 018A	     4382	MOV #0,&356
 018C	     0164
 018E	     3C38	JMP $+114, goes to  0200
 0190	     90B2	CMP #7,&388
 0192	     0007
 0194	     0184
 0196	     200A	JNE $+22, goes to  01AC
 0198	     B3D2	BIT.B #1,&124
 019A	     007C
 019C	     2407	JEQ $+16, goes to  01AC
 019E	     4382	MOV #0,&404
 01A0	     0194
 01A2	     C2F2	BIC.B #8,&33
 01A4	     0021
 01A6	     4382	MOV #0,&356
 01A8	     0164
 01AA	     3C2A	JMP $+86, goes to  0200
 01AC	     90B2	CMP #7,&416
 01AE	     0007
 01B0	     01A0
 01B2	     2404	JEQ $+10, goes to  01BC
 01B4	     90B2	CMP #5,&432
 01B6	     0005
 01B8	     01B0
 01BA	     2016	JNE $+46, goes to  01E8
 01BC	     D3E2	BIS.B #2,&120
 01BE	     0078
 01C0	     421E	MOV &340,R14
 01C2	     0154
 01C4	     4ED2	MOV.B 0(R14),&124
 01C6	     0000
 01C8	     007C
 01CA	     5392	ADD #1,&450
 01CC	     01C2
 01CE	     421E	MOV &460,R14
 01D0	     01CC
 01D2	     F03E	AND #7,R14
 01D4	     0007
 01D6	     4E82	MOV R14,&464
 01D8	     01D0
 01DA	     40F2	MOV.B #40,&123
 01DC	     0028
 01DE	     007B
 01E0	     40B2	MOV #6,&440
 01E2	     0006
 01E4	     01B8
 01E6	     3C0C	JMP $+26, goes to  0200
 01E8	     90B2	CMP #6,&484
 01EA	     0006
 01EC	     01E4
 01EE	     2008	JNE $+18, goes to  0200
 01F0	     C3E2	BIC.B #2,&120
 01F2	     0078
 01F4	     40F2	MOV.B #33,&123
 01F6	     0021
 01F8	     007B
 01FA	     40B2	MOV #7,&492
 01FC	     0007
 01FE	     01EC
 0200	     C3D2	BIC.B #1,&121
 0202	     0079
 0204	     4134	POP R4
 0206	     413E	POP R14
 0208	     413F	POP R15
 020A	     1300	RETI
 020C	     40B2	MOV #23168,&288
 020E	     5A80
 0210	     0120
 0212	     43C2	MOV.B #0,&130
 0214	     0082
 0216	     43C2	MOV.B #0,&114
 0218	     0072
 021A	     4382	MOV #0,&168
 021C	     00A8
 021E	     4382	MOV #0,&346
 0220	     015A
 0222	     4382	MOV #0,&0
 0224	     0000
 0226	     4382	MOV #0,&0
 0228	     0000
 022A	     4382	MOV #0,&510
 022C	     01FE
 022E	     42E2	MOV.B #4,&33
 0230	     0021
 0232	     40F2	MOV.B #10,&34
 0234	     000A
 0236	     0022
 0238	     40F2	MOV.B #52,&39
 023A	     0034
 023C	     0027
 023E	     42E2	MOV.B #4,&36
 0240	     0024
 0242	     43C2	MOV.B #0,&35
 0244	     0023
 0246	     42E2	MOV.B #4,&37
 0248	     0025
 024A	     43C2	MOV.B #0,&41
 024C	     0029
 024E	     C0F2	BIC.B #192,&46
 0250	     00C0
 0252	     002E
 0254	     43C2	MOV.B #0,&42
 0256	     002A
 0258	     40F2	MOV.B #192,&47
 025A	     00C0
 025C	     002F
 025E	     43C2	MOV.B #0,&44
 0260	     002C
 0262	     43C2	MOV.B #0,&43
 0264	     002B
 0266	     43C2	MOV.B #0,&88
 0268	     0058
 026A	     93F2	CMP.B #-1,&4351
 026C	     10FF
 026E	     2408	JEQ $+18, goes to  0280
 0270	     43C2	MOV.B #0,&86
 0272	     0056
 0274	     42D2	MOV.B &4351,&87
 0276	     10FF
 0278	     0057
 027A	     42D2	MOV.B &4350,&86
 027C	     10FE
 027E	     0056
 0280	     D0F2	BIS.B #128,&87
 0282	     0080
 0284	     0057
 0286	     40F2	MOV.B #36,&83
 0288	     0024
 028A	     0053
 028C	     12B0	CALL #90
 028E	     005A
 0290	     C3A2	BIC #2,&432
 0292	     01B0
 0294	     40B2	MOV #14840,&432
 0296	     39F8
 0298	     01B0
 029A	     40B2	MOV #2052,&434
 029C	     0804
 029E	     01B2
 02A0	     43D2	MOV.B #1,&74
 02A2	     004A
 02A4	     42F2	MOV.B #8,&73
 02A6	     0049
 02A8	     40B2	MOV #0,&444
 02AA	     0000
 02AC	     01BC
 02AE	     4034	MOV #10000,R4
 02B0	     2710
 02B2	     12B0	CALL #0
 02B4	     0000
 02B6	     D3A2	BIS #2,&432
 02B8	     01B0
 02BA	     C3E2	BIC.B #2,&2
 02BC	     0002
 02BE	     4034	MOV #17,R4
 02C0	     0011
 02C2	     12B0	CALL #692
 02C4	     02B4
 02C6	     B3E2	BIT.B #2,&2
 02C8	     0002
 02CA	     23F7	JNE $-16, goes to  02BA
 02CC	     D232	BIS #8,SR
 02CE	     40B2	MOV #128,&354
 02D0	     0080
 02D2	     0162
 02D4	     40B2	MOV #5999,&370
 02D6	     176F
 02D8	     0172
 02DA	     40B2	MOV #272,&352
 02DC	     0110
 02DE	     0160
 02E0	     93D2	CMP.B #1,&536
 02E2	     0218
 02E4	     2005	JNE $+12, goes to  02F0
 02E6	     12B0	CALL #0
 02E8	     0000
 02EA	     43E2	MOV.B #2,&738
 02EC	     02E2
 02EE	     3C05	JMP $+12, goes to  02FA
 02F0	     93E2	CMP.B #2,&748
 02F2	     02EC
 02F4	     2002	JNE $+6, goes to  02FA
 02F6	     43C2	MOV.B #0,&754
 02F8	     02F2
 02FA	     93C2	CMP.B #0,&532
 02FC	     0214
 02FE	     2426	JEQ $+78, goes to  034C
 0300	     43C2	MOV.B #0,&764
 0302	     02FC
 0304	     C3A2	BIC #2,&432
 0306	     01B0
 0308	     E3E2	XOR.B #2,&33
 030A	     0021
 030C	     42B2	MOV #8,&0
 030E	     0000
 0310	     4382	MOV #0,&0
 0312	     0000
 0314	     8392	SUB #1,&782
 0316	     030E
 0318	     421F	MOV &790,R15
 031A	     0316
 031C	     5F0F	ADD R15,R15
 031E	     5F92	ADD 682(R15),&786
 0320	     02AA
 0322	     0312
 0324	     9382	CMP #0,&794
 0326	     031A
 0328	     23F5	JNE $-20, goes to  0314
 032A	     1112	RRA &802
 032C	     0322
 032E	     1112	RRA &812
 0330	     032C
 0332	     1112	RRA &816
 0334	     0330
 0336	     4292	MOV &820,&544
 0338	     0334
 033A	     0220
 033C	     B392	BIT #1,&434
 033E	     01B2
 0340	     23FD	JNE $-4, goes to  033C
 0342	     40B2	MOV #800,&444
 0344	     0320
 0346	     01BC
 0348	     D3A2	BIS #2,&432
 034A	     01B0
 034C	     403F	MOV #60,R15
 034E	     003C
 0350	     921F	CMP &540,R15
 0352	     021C
 0354	     340A	JGE $+22, goes to  036A
 0356	     93C2	CMP.B #0,&760
 0358	     02F8
 035A	     2007	JNE $+16, goes to  036A
 035C	     43D2	MOV.B #1,&856
 035E	     0358
 0360	     4382	MOV #0,&850
 0362	     0352
 0364	     5392	ADD #1,&552
 0366	     0228
 0368	     3C04	JMP $+10, goes to  0372
 036A	     5392	ADD #1,&866
 036C	     0362
 036E	     D032	BIS #216,SR
 0370	     00D8
 0372	     3FB6	JMP $-146, goes to  02E0
 0374	     4130	RET
