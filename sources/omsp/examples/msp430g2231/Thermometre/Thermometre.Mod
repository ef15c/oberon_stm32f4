MODULE Thermometre; (*C. Schoffit 19.03.25 *)
  IMPORT SYSTEM, M := msp430g2231, Conv, Delay := msp430delay, N := nrf24l01pThermo, MP := MultiPrecisionArith;

  CONST BUFSZ = 6;
    MAX_SAMPLES = 10;
    ADDRESS = " 3SCHO";

  VAR tempData: ARRAY MAX_SAMPLES OF INTEGER;
    nbSamples: INTEGER;
    cmdT: ARRAY BUFSZ OF BYTE; (*Buffers de communication avec le module nrf24l01*)

    pCmdrep: PBYTE; temp, i: INTEGER; tcell, tcelh: INTEGER; (*32b integer*)

  (*
   *  ======== PORT1 Interrupt Service Routine ========
   *
   * Here are several important notes on using PORTx interrupt Handler:
   *
   * 1. User must explicitly clear the port interrupt flag before exiting
   *
   *    BIC(PxIFG, {y});
   *
   * 2. User could also exit from low power mode and continue with main
   *    program execution by using the following instruction before exiting
   *    this interrupt handler.
   *
   *   SYSTEM.BIC_SR_ON_EXIT(LPMx_bits);
   *
   *)
  PROCEDURE* (M.PORT1_VECTOR) {4..7} PORT1_ISR_HOOK;
    VAR cmdI, repI: ARRAY 2 OF BYTESET;
  BEGIN
    IF BIT(N.PF_IRQ^, N.IRQ) THEN
      (* Quelque chose s'est produit dans le module nRF24l01+ *)
      (* On lit le registre de status *)
      cmdI[0] := TOSET(N.W_REGISTER + N.STATUS);
      cmdI[1] := {4..6}; (* CLear interrupts flags and read status *)
      N.talk(2, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdI)), SYSTEM.VAL(PBYTE, SYSTEM.ADR(repI)));
      IF BIT(repI[0], N.MAX_RT) THEN (* Transmission failed *)
        cmdI[0] := TOSET(N.FLUSH_TX); (* Flush TX FIFO *)
        N.talk(1, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdI)), SYSTEM.VAL(PBYTE, SYSTEM.ADR(repI)));
        cmdI[0] := TOSET(N.R_REGISTER + N.OBSERVE_TX); (* Observe TX *)
        N.talk(2, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdI)), SYSTEM.VAL(PBYTE, SYSTEM.ADR(repI)))
      END;
      BIC(N.PF_IRQ^, N.IRQ); (* clear interrupt flag *)
      N.setReady; (* The device is now ready *)
    END
  END PORT1_ISR_HOOK;

  (*
   *  ======== ADC10 Interrupt Service Routine ========
   *)
  PROCEDURE* (M.ADC10_VECTOR) {15} ADC10_ISR_HOOK;
  BEGIN BIC(M.ADC10CTL0^, M.ADC10IFG); (* clear flag *)
    IF nbSamples < MAX_SAMPLES THEN tempData[nbSamples] := M.ADC10MEM^; INC(nbSamples) END;
    SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits) (* Reprise du traitement dans la boucle principale *)
  END ADC10_ISR_HOOK;
  
  (*
   *  ======== Watchdog Timer Interval Interrupt Handler Generation ========
   *)
  PROCEDURE* (M.WDT_VECTOR) WDT_ISR_HOOK;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits) (* Reprise traitement dans la boucle principale *)
  END WDT_ISR_HOOK;

(*
 *  ======== main ========
 *)

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD;

  (*
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

  (*Pour cette applications, les E/S sont les suivantes:
     E: P1.3: IRQ24 (interruption sur front descendant), P1.7: SDI
     S: P1.0: CSN24, P1.4: CE24, P1.5: SCLK, P1.6: SDO *)

  M.P1OUT^ := {0}; (* Port 1 Output Register *)
  M.P1DIR^ := {0, 4}; (* Port 1 Direction Register *)
  M.P1REN^ := {1..2}; (* Port 1 Resistor Enable Register *)
  M.P1IES^ := {3}; (* Port 1 Interrupt Edge Select Register *)
  M.P1IFG^ := {}; (* Port 1 Interrupt Flag Register *)
  M.P1IE^ := {3}; (* Port 1 Interrupt Enable Register *)
  M.P2OUT^ := {}; (* Port 2 Output Register *)
  BIC(M.P2SEL^, {6, 7}); (* Port 2 Port Select Register *)
  M.P2DIR^ := {}; (* Port 2 Direction Register *)
  M.P2REN^ := {6, 7}; (* Port 2 Resistor Enable Register *)
  M.P2IES^ := {}; (* Port 2 Interrupt Edge Select Register *)
  M.P2IFG^ := {}; (* Port 2 Interrupt Flag Register *)

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
    * ~MSC -- Disable multiple sample and conversion
    * ~REFBURST -- Reference buffer on continuously
    * ~REFOUT -- Reference output off
    * ~ADC10SR -- Reference buffer supports up to ~200 ksps
    * ADC10SHT_3 -- 64 x ADC10CLKs
    * SREF_1 -- VR+ = VREF+ and VR- = VSS
    * 
    * Note: ~<BIT> indicates that <BIT> has value zero
    *)
  M.ADC10CTL0^ := M.ADC10IE + M.ADC10ON + M.REFON + M.REF2_5V + M.ADC10SHT_3 + M.SREF_1;

  (* 
    * Control Register 1
    * 
    * ~ADC10BUSY -- No operation is active
    * CONSEQ_0 -- Single channel single conversion
    * ADC10SSEL_0 -- ADC10OSC
    * ADC10DIV_3 -- Divide by 4
    * ~ISSH -- Input signal not inverted
    * ~ADC10DF -- ADC10 Data Format as binary
    * SHS_0 -- ADC10SC
    * INCH_10 -- Temperature Sensor
    * 
    * Note: ~<BIT> indicates that <BIT> has value zero
    *)
  M.ADC10CTL1^ := M.CONSEQ_0 + M.ADC10SSEL_0 + M.ADC10DIV_3 + M.SHS_0 + M.INCH_10;
  Delay.CyclesX3(10000); (* Software delay for REFON to settle *)
  BIS( M.ADC10CTL0^, M.ENC); (* enable ADC10 *)

  (*
   *  ======== USI_graceInit ========
   *  Initialize Universal Serial Interface
   *)
  BIS(M.USICTL0^, M.USISWRST); (* Disable USI *)

  (* 
    * USI Control Register 0
    * 
    * USIPE7 -- USI function enabled
    * USIPE6 -- USI function enabled
    * USIPE5 -- USI function enabled
    * ~USILSB -- MSB first
    * USIMST -- Master mode
    * ~USIGE -- Output latch enable depends on shift clock
    * USIOE -- Output enabled
    * USISWRST -- USI logic held in reset state
    * 
    * Note: ~<BIT> indicates that <BIT> has value zero
    *)
  M.USICTL0^ := M.USIPE7 + M.USIPE6 + M.USIPE5 + M.USIMST + M.USIOE + M.USISWRST;

  (* 
    * USI Control Register 1
    * 
    * USICKPH -- Data is captured on the first SCLK edge and changed on the following edge
    * ~USII2C -- I2C mode disabled
    * ~USISTTIE -- Interrupt on START condition disabled
    * ~USIIE -- Interrupt disabled
    * ~USIAL -- No arbitration lost condition
    * ~USISTP -- No STOP condition received
    * ~USISTTIFG -- No START condition received. No interrupt pending
    * USIIFG -- Interrupt pending
    * 
    * Note: ~<BIT> indicates that <BIT> has value zero
    *)
  M.USICTL1^ := M.USICKPH + M.USIIFG;

  (* 
    * USI Clock Control Register
    * 
    * USIDIV_2 -- Divide by 4
    * USISSEL_2 -- SMCLK
    * ~USICKPL -- Inactive state is low
    * ~USISWCLK -- Input clock is low
    * 
    * Note: ~<BIT> indicates that <BIT> has value zero
    *)
  M.USICKCTL^ := M.USIDIV_2 + M.USISSEL_2;
  BIC(M.USICTL0^, M.USISWRST); (* Enable USI *)

  (*
   *  ======= System_graceInit =======
   * Initialize MSP430 Status Register 
   *)
  (* CLear oscillator fault flag with software delay *)
  REPEAT BIC(M.IFG1^, M.OFIFG); Delay.CyclesX3(17) UNTIL ~BIT(M.IFG1^, M.OFIFG); 

  (* 
    * IFG1, Interrupt Flag Register 1
    * 
    * ~ACCVIFG -- No interrupt pending
    * ~NMIIFG -- No interrupt pending
    * ~OFIFG -- No interrupt pending
    * WDTIFG -- Interrupt pending
    * 
    * Note: ~<BIT> indicates that <BIT> has value zero
    *)
  BIC(M.IFG1^, M.WDTIFG);

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

  (* Workaround for errata USI5 "SPI master generates one additional clock after module reset"
    * Load USICNTx with a count of N-1 bits (where N is the required number of bits) for the
    * first transfer only.
    *)
  M.USISRL^ := 0FFH; M.USICNT^ := TOSET(7); REPEAT UNTIL BIT(M.USICTL1^, M.USIIFG);

  (* Start of effective operations *)
  Delay.CyclesX3(10000 DIV 3);
  (* Power up nRF24l01+ module, enable CRC, 2 crc bytes, TX *)
  cmdT[0] := N.W_REGISTER+N.CONFIG;
  cmdT[1] := 0EH;
  N.talk(2, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);
  Delay.CyclesX3(10000 DIV 3);

  cmdT[0] := N.FLUSH_TX; (* Flush TX FIFO *)
  N.talk(1, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);

  cmdT[0] := N.W_REGISTER + N.STATUS; (* Reset nrf24l01p interrupt *)
  cmdT[1] := 70H; (* CLear interrupts flags *)
  N.talk(2, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);

  cmdT[0] := N.W_REGISTER + N.RF_CH;
  cmdT[1] := 110; (* Canal 110 => 2510 MHz *)
  N.talk(2, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);

  SYSTEM.COPY(SYSTEM.ADR(ADDRESS), SYSTEM.ADR(cmdT), 3);
  cmdT[0] := N.W_REGISTER + N.TX_ADDR;    (* Adresse de transmission *)
  N.talk(6, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);
  (* adresse de reception du pipe 0 identique, pour l'auto acquitement *)
  cmdT[0] := N.W_REGISTER + N.RX_ADDR_P0;
  N.talk(6, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);

  cmdT[0] := N.W_REGISTER + N.RF_SETUP;  (* 250 kbs *)
  cmdT[1] := 22H; (* 0010 0010  250kbps, -12dBm *)
  N.talk(2, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);

  (* Retransmission automatique apres 1000 us.
   * ATTENTION : a augmenter si le module de reception doit renvoyer des donnees *)
  cmdT[0] := N.W_REGISTER + N.SETUP_RETR;
  cmdT[1] := 31H;
  N.talk(2, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);

  REPEAT
    (* Mesure de la temperature *)
    temp := 0;
    (* ADC Start Conversion - Software trigger *)
    BIS(M.ADC10CTL0^, M.ADC10ON + M.REFON); (* Turn ADC reference ON *)
    Delay.CyclesX3(51 DIV 3); (* Wait for stabilization of ADC reference *)
    nbSamples := 0;
    BIS(M.ADC10CTL0^, M.ENC); (* Start conversion *)
    WHILE nbSamples < MAX_SAMPLES DO BIS(M.ADC10CTL0^, M.ADC10SC);
      SYSTEM.BIS_SR(M.LPM1_bits);
    END;
    BIC(M.ADC10CTL0^, M.ENC); (* Stop conversion *)
    BIC(M.ADC10CTL0^, M.ADC10ON + M.REFON); (* ADC Off, Turn ADC reference OFF *)
    FOR i := 8 TO 1 BY -1 DO INC(temp, tempData[i]) END;

    MP.SetLongInt(tcelh, tcell, temp);
    MP.SubLongInt(tcelh, tcell, 3094); MP.MulLongInt(tcelh, tcell, 596); MP.ASRLongInt(tcelh, tcell, 10);

    IF N.ready THEN
      (* On transmet le resultat par radio *)
      pCmdrep := SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)+4);
      i := 16;
      REPEAT DEC(i, 4); pCmdrep^ := ORD(Conv.toHexa(ORD(TOSET(tcell)*{0..3}))); RRA(tcell, 4); DEC(ORD(pCmdrep)) UNTIL i = 0;
      (* Write payload to nRF24l01+ module *)
      cmdT[0] := N.W_TX_PAYLOAD;
      N.talk(5, SYSTEM.VAL(PBYTE, SYSTEM.ADR(cmdT)), NIL);
      N.pulseCE; (* Start transmission *)
    END;
    SYSTEM.BIS_SR(M.LPM1_bits);
  UNTIL FALSE
END Thermometre.

OMSPP.Compile Conv.Mod nrf24l01pThermo.Mod/s Thermometre.Mod ~
OMSPL.Link 32 800H 80H Thermometre ~
  linking msp430g2231 Conv msp430delay nrf24l01pThermo MultiPrecisionArith Thermometre
    flash 1378, data   40, stack   88 bytes

OMSPTool.DecObj Thermometre.mpc
