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
  linking msp430g2231 Conv msp430delay nrf24l01pThermo MultiPrecisionArith Thermometre, flash 1390, data   40, stack   88 bytes

OMSPTool.DecObj Thermometre.mpc
decode Thermometre.mpc
Thermometre 355049A4 Flash   844
imports:
	msp430g2231 5D5FCA6E
	Conv B4CBC65B
	msp430delay EE6A4099
	nrf24l01pThermo B74D2B31
	MultiPrecisionArith B561C064
type descriptors

data    38
strings
 3SCHO||
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF 0000 FFFF FFFF 0000 FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF

entries
 c 00A6
fixup procedures chains
 0304     2	 0001
 025A     3	 0001
 0064     4	 0006
 033A     4	 0003
 0336     4	 0002
 02DC     5	 0008
 02CC     5	 0006
 02BC     5	 0003
 02AC     5	 0002
fixup handlers chains
 0112     0	 0000
 0115     0	 0072
 011A     0	 009E
fixup data chains
 0268     0	 0014
 0292     0	 0000
 0330     0	 0016
 023C     0	 0017
 02A8     0	 001E
 0320     0	 0020
 02D0     0	 0024
 0318     0	 0022
 02E6     0	 001A
 031C     0	 001C
 02E0     4	 0001
fixup constants chains
 01E2     0	 0000
fixup types chains
entry =  00A6
code   836
 0000	     8221	SUB #4,SP
 0002	     1207	PUSH R7
 0004	     1206	PUSH R6
 0006	     1205	PUSH R5
 0008	     1204	PUSH R4
 000A	     B2F2	BIT.B #8,&35
 000C	     0023
 000E	     242B	JEQ $+88, goes to  0066
 0010	     40F1	MOV.B #39,8(SP)
 0012	     0027
 0014	     0008
 0016	     40F1	MOV.B #112,9(SP)
 0018	     0070
 001A	     0009
 001C	     4324	MOV #2,R4
 001E	     4105	MOV SP,R5
 0020	     5235	ADD #8,R5
 0022	     4106	MOV SP,R6
 0024	     5036	ADD #10,R6
 0026	     000A
 0028	     12B0	CALL #0
 002A	     0000
 002C	     B0F1	BIT.B #16,10(SP)
 002E	     0010
 0030	     000A
 0032	     2415	JEQ $+44, goes to  005E
 0034	     40F1	MOV.B #225,8(SP)
 0036	     00E1
 0038	     0008
 003A	     4314	MOV #1,R4
 003C	     4105	MOV SP,R5
 003E	     5235	ADD #8,R5
 0040	     4106	MOV SP,R6
 0042	     5036	ADD #10,R6
 0044	     000A
 0046	     12B0	CALL #42
 0048	     002A
 004A	     42F1	MOV.B #8,8(SP)
 004C	     0008
 004E	     4324	MOV #2,R4
 0050	     4105	MOV SP,R5
 0052	     5235	ADD #8,R5
 0054	     4106	MOV SP,R6
 0056	     5036	ADD #10,R6
 0058	     000A
 005A	     12B0	CALL #72
 005C	     0048
 005E	     C2F2	BIC.B #8,&35
 0060	     0023
 0062	     12B0	CALL #0
 0064	     0000
 0066	     4134	POP R4
 0068	     4135	POP R5
 006A	     4136	POP R6
 006C	     4137	POP R7
 006E	     5221	ADD #4,SP
 0070	     1300	RETI
 0072	     120F	PUSH R15
 0074	     C2A2	BIC #4,&432
 0076	     01B0
 0078	     90B2	CMP #10,&0
 007A	     000A
 007C	     0000
 007E	     340A	JGE $+22, goes to  0094
 0080	     421F	MOV &124,R15
 0082	     007C
 0084	     5F0F	ADD R15,R15
 0086	     503F	ADD #0,R15
 0088	     0000
 008A	     429F	MOV &436,0(R15)
 008C	     01B4
 008E	     0000
 0090	     5392	ADD #1,&130
 0092	     0082
 0094	     C0B1	BIC #240,2(SP)
 0096	     00F0
 0098	     0002
 009A	     413F	POP R15
 009C	     1300	RETI
 009E	     C0B1	BIC #240,0(SP)
 00A0	     00F0
 00A2	     0000
 00A4	     1300	RETI
 00A6	     40B2	MOV #23168,&288
 00A8	     5A80
 00AA	     0120
 00AC	     43D2	MOV.B #1,&33
 00AE	     0021
 00B0	     40F2	MOV.B #17,&34
 00B2	     0011
 00B4	     0022
 00B6	     40F2	MOV.B #6,&39
 00B8	     0006
 00BA	     0027
 00BC	     42F2	MOV.B #8,&36
 00BE	     0024
 00C0	     43C2	MOV.B #0,&35
 00C2	     0023
 00C4	     42F2	MOV.B #8,&37
 00C6	     0025
 00C8	     43C2	MOV.B #0,&41
 00CA	     0029
 00CC	     C0F2	BIC.B #192,&46
 00CE	     00C0
 00D0	     002E
 00D2	     43C2	MOV.B #0,&42
 00D4	     002A
 00D6	     40F2	MOV.B #192,&47
 00D8	     00C0
 00DA	     002F
 00DC	     43C2	MOV.B #0,&44
 00DE	     002C
 00E0	     43C2	MOV.B #0,&43
 00E2	     002B
 00E4	     43C2	MOV.B #0,&88
 00E6	     0058
 00E8	     93F2	CMP.B #-1,&4351
 00EA	     10FF
 00EC	     2408	JEQ $+18, goes to  00FE
 00EE	     43C2	MOV.B #0,&86
 00F0	     0056
 00F2	     42D2	MOV.B &4351,&87
 00F4	     10FF
 00F6	     0057
 00F8	     42D2	MOV.B &4350,&86
 00FA	     10FE
 00FC	     0056
 00FE	     D0F2	BIS.B #176,&87
 0100	     00B0
 0102	     0057
 0104	     40F2	MOV.B #36,&83
 0106	     0024
 0108	     0053
 010A	     C3A2	BIC #2,&432
 010C	     01B0
 010E	     40B2	MOV #14456,&432
 0110	     3878
 0112	     01B0
 0114	     40B2	MOV #-24480,&434
 0116	     A060
 0118	     01B2
 011A	     4034	MOV #10000,R4
 011C	     2710
 011E	     12B0	CALL #0
 0120	     0000
 0122	     D3A2	BIS #2,&432
 0124	     01B0
 0126	     D3D2	BIS.B #1,&120
 0128	     0078
 012A	     40F2	MOV.B #235,&120
 012C	     00EB
 012E	     0078
 0130	     40F2	MOV.B #129,&121
 0132	     0081
 0134	     0079
 0136	     40F2	MOV.B #72,&122
 0138	     0048
 013A	     007A
 013C	     C3D2	BIC.B #1,&120
 013E	     0078
 0140	     C3E2	BIC.B #2,&2
 0142	     0002
 0144	     4034	MOV #17,R4
 0146	     0011
 0148	     12B0	CALL #288
 014A	     0120
 014C	     B3E2	BIT.B #2,&2
 014E	     0002
 0150	     23F7	JNE $-16, goes to  0140
 0152	     C3D2	BIC.B #1,&2
 0154	     0002
 0156	     D3D2	BIS.B #1,&0
 0158	     0000
 015A	     D232	BIS #8,SR
 015C	     40B2	MOV #23060,&288
 015E	     5A14
 0160	     0120
 0162	     43F2	MOV.B #-1,&124
 0164	     007C
 0166	     40F2	MOV.B #7,&123
 0168	     0007
 016A	     007B
 016C	     B3D2	BIT.B #1,&121
 016E	     0079
 0170	     27FD	JEQ $-4, goes to  016C
 0172	     4034	MOV #3333,R4
 0174	     0D05
 0176	     12B0	CALL #330
 0178	     014A
 017A	     40F2	MOV.B #32,&0
 017C	     0020
 017E	     0000
 0180	     40F2	MOV.B #14,&0
 0182	     000E
 0184	     0000
 0186	     4324	MOV #2,R4
 0188	     4035	MOV #382,R5
 018A	     017E
 018C	     4306	MOV #0,R6
 018E	     12B0	CALL #92
 0190	     005C
 0192	     4034	MOV #3333,R4
 0194	     0D05
 0196	     12B0	CALL #376
 0198	     0178
 019A	     40F2	MOV.B #225,&394
 019C	     00E1
 019E	     018A
 01A0	     4314	MOV #1,R4
 01A2	     4035	MOV #414,R5
 01A4	     019E
 01A6	     4306	MOV #0,R6
 01A8	     12B0	CALL #400
 01AA	     0190
 01AC	     40F2	MOV.B #39,&420
 01AE	     0027
 01B0	     01A4
 01B2	     40F2	MOV.B #112,&388
 01B4	     0070
 01B6	     0184
 01B8	     4324	MOV #2,R4
 01BA	     4035	MOV #432,R5
 01BC	     01B0
 01BE	     4306	MOV #0,R6
 01C0	     12B0	CALL #426
 01C2	     01AA
 01C4	     40F2	MOV.B #37,&444
 01C6	     0025
 01C8	     01BC
 01CA	     40F2	MOV.B #110,&438
 01CC	     006E
 01CE	     01B6
 01D0	     4324	MOV #2,R4
 01D2	     4035	MOV #456,R5
 01D4	     01C8
 01D6	     4306	MOV #0,R6
 01D8	     12B0	CALL #450
 01DA	     01C2
 01DC	     403F	MOV #3,R15
 01DE	     0003
 01E0	     403E	MOV #0,R14
 01E2	     0000
 01E4	     403D	MOV #468,R13
 01E6	     01D4
 01E8	     4EBD	MOV @R14+,0(R13)
 01EA	     0000
 01EC	     532D	ADD #2,R13
 01EE	     831F	SUB #1,R15
 01F0	     23FB	JNE $-8, goes to  01E8
 01F2	     40F2	MOV.B #48,&486
 01F4	     0030
 01F6	     01E6
 01F8	     4034	MOV #6,R4
 01FA	     0006
 01FC	     4035	MOV #502,R5
 01FE	     01F6
 0200	     4306	MOV #0,R6
 0202	     12B0	CALL #474
 0204	     01DA
 0206	     40F2	MOV.B #42,&510
 0208	     002A
 020A	     01FE
 020C	     4034	MOV #6,R4
 020E	     0006
 0210	     4035	MOV #522,R5
 0212	     020A
 0214	     4306	MOV #0,R6
 0216	     12B0	CALL #516
 0218	     0204
 021A	     40F2	MOV.B #38,&530
 021C	     0026
 021E	     0212
 0220	     40F2	MOV.B #34,&462
 0222	     0022
 0224	     01CE
 0226	     4324	MOV #2,R4
 0228	     4035	MOV #542,R5
 022A	     021E
 022C	     4306	MOV #0,R6
 022E	     12B0	CALL #536
 0230	     0218
 0232	     40F2	MOV.B #36,&554
 0234	     0024
 0236	     022A
 0238	     40F2	MOV.B #49,&548
 023A	     0031
 023C	     0224
 023E	     4324	MOV #2,R4
 0240	     4035	MOV #566,R5
 0242	     0236
 0244	     4306	MOV #0,R6
 0246	     12B0	CALL #560
 0248	     0230
 024A	     4382	MOV #0,&0
 024C	     0000
 024E	     D0B2	BIS #48,&432
 0250	     0030
 0252	     01B0
 0254	     4034	MOV #17,R4
 0256	     0011
 0258	     12B0	CALL #408
 025A	     0198
 025C	     4382	MOV #0,&146
 025E	     0092
 0260	     D3A2	BIS #2,&432
 0262	     01B0
 0264	     90B2	CMP #10,&606
 0266	     000A
 0268	     025E
 026A	     3405	JGE $+12, goes to  0276
 026C	     D392	BIS #1,&432
 026E	     01B0
 0270	     D032	BIS #80,SR
 0272	     0050
 0274	     3FF7	JMP $-16, goes to  0264
 0276	     C3A2	BIC #2,&432
 0278	     01B0
 027A	     C0B2	BIC #48,&432
 027C	     0030
 027E	     01B0
 0280	     42B2	MOV #8,&0
 0282	     0000
 0284	     9392	CMP #1,&642
 0286	     0282
 0288	     380A	JL $+22, goes to  029E
 028A	     421F	MOV &646,R15
 028C	     0286
 028E	     5F0F	ADD R15,R15
 0290	     503F	ADD #136,R15
 0292	     0088
 0294	     5FA2	ADD @R15,&588
 0296	     024C
 0298	     53B2	ADD #-1,&652
 029A	     028C
 029C	     3FF3	JMP $-24, goes to  0284
 029E	     4034	MOV #0,R4
 02A0	     0000
 02A2	     4035	MOV #0,R5
 02A4	     0000
 02A6	     4216	MOV &662,R6
 02A8	     0296
 02AA	     12B0	CALL #0
 02AC	     0000
 02AE	     4034	MOV #672,R4
 02B0	     02A0
 02B2	     4035	MOV #676,R5
 02B4	     02A4
 02B6	     4036	MOV #3094,R6
 02B8	     0C16
 02BA	     12B0	CALL #0
 02BC	     0000
 02BE	     4034	MOV #688,R4
 02C0	     02B0
 02C2	     4035	MOV #692,R5
 02C4	     02B4
 02C6	     4036	MOV #596,R6
 02C8	     0254
 02CA	     12B0	CALL #0
 02CC	     0000
 02CE	     4034	MOV #704,R4
 02D0	     02C0
 02D2	     4035	MOV #708,R5
 02D4	     02C4
 02D6	     4036	MOV #10,R6
 02D8	     000A
 02DA	     12B0	CALL #0
 02DC	     0000
 02DE	     93C2	CMP.B #0,&0
 02E0	     0000
 02E2	     242C	JEQ $+90, goes to  033C
 02E4	     40B2	MOV #0,&0
 02E6	     0000
 02E8	     0000
 02EA	     40B2	MOV #16,&666
 02EC	     0010
 02EE	     029A
 02F0	     82A2	SUB #4,&750
 02F2	     02EE
 02F4	     421F	MOV &744,R15
 02F6	     02E8
 02F8	     4214	MOV &724,R4
 02FA	     02D4
 02FC	     F034	AND #15,R4
 02FE	     000F
 0300	     4405	MOV R4,R5
 0302	     12B0	CALL #0
 0304	     0000
 0306	     44CF	MOV.B R4,0(R15)
 0308	     0000
 030A	     1112	RRA &762
 030C	     02FA
 030E	     1112	RRA &780
 0310	     030C
 0312	     1112	RRA &784
 0314	     0310
 0316	     1112	RRA &788
 0318	     0314
 031A	     8392	SUB #1,&758
 031C	     02F6
 031E	     9382	CMP #0,&754
 0320	     02F2
 0322	     23E6	JNE $-50, goes to  02F0
 0324	     40F2	MOV.B #160,&578
 0326	     00A0
 0328	     0242
 032A	     4034	MOV #5,R4
 032C	     0005
 032E	     4035	MOV #808,R5
 0330	     0328
 0332	     4306	MOV #0,R6
 0334	     12B0	CALL #584
 0336	     0248
 0338	     12B0	CALL #0
 033A	     0000
 033C	     D032	BIS #80,SR
 033E	     0050
 0340	     3F84	JMP $-246, goes to  024A
 0342	     4130	RET
