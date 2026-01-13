MODULE testpcd8544;
  IMPORT M := msp430g2553, Delay := msp430delay, LCD := pcd8544, PT := PosixTime;

  CONST
    NCE = {1}; (*P2*) DC = {0}; (*P2*) NRST = {2}; (*P2*) NLIGHT = {0}; (*P1*)

  TYPE DAY_OF_WEEK = ARRAY 7, 4 OF CHAR;

  VAR old_day: PT.TimeDesc;
    dayOfWeek: DAY_OF_WEEK-;

  PROCEDURE select;
  BEGIN BIC(M.P2OUT^, NCE)
  END select;

  PROCEDURE deselect;
  BEGIN BIS(M.P2OUT^, NCE)
  END deselect;

  PROCEDURE setData;
  BEGIN BIS(M.P2OUT^, DC)
  END setData;

  PROCEDURE setCommand;
  BEGIN BIC(M.P2OUT^, DC)
  END setCommand;

  PROCEDURE send(d: BYTE* );
  BEGIN
    REPEAT UNTIL BIT(M.IFG2^, M.UCB0TXIFG); (*Wait for USCI availability*)
    M.UCB0TXBUF^ := ORD(d); (*USCI B is ready, send character*)
    REPEAT UNTIL ~BIT(M.UCB0STAT^, M.UCBUSY); (*Wait for end of transmission*)
  END send;

  (*
    * I/O in use:
    *
    * P1.0: LCD NLIGHT
    * P1.7: LCD DIN
    * P1.5: LCD CLK
    * P2.1: LCD NCE
    * P2.0: LCD DC
    * P2.2: LCD NRST
    *)

  PROCEDURE displayT(t: PT.Time; x, y: INTEGER);
    VAR msg: ARRAY 12 OF CHAR;
  BEGIN PT.TimeToString(t, 1, 1, msg);
    LCD.SetAddr(x, y); LCD.WriteString(msg)
  END displayT;

  PROCEDURE displayTime;
    VAR x, y: BYTE; ltime: PT.TimeDesc; tm: PT.TmDesc;
  BEGIN (*conversion du temps*)
    ltime := PT.systemTime; PT.inc(PTR(PT.Time, ltime), PTR(PT.Time, PT.timeOffset));
    PT.gmhms(PTR(PT.Time, ltime), PTR(PT.Tm, tm));
    displayT(PTR(PT.Time, ltime), 0, 3);
    LCD.GetAddr(x, y);
    LCD.WriteLongint(0, tm.hour, 3, 0, 1, 2); LCD.WriteChar(":");
    LCD.WriteLongint(0, tm.min, 6, 0, 2, 2); LCD.WriteChar(":");
    LCD.WriteLongint(0, tm.sec, 9, 0, 2, 2);
    IF PT.cmp(PTR(PT.Time, old_day), PTR(PT.Time, ltime)) # 0 THEN
      (*do the following only if day has changed, to save few micro amps.*)
      old_day := ltime; PT.localtime(PTR(PT.Time, PT.systemTime), PTR(PT.Tm, tm)); LCD.SetAddr(0, 1);
      LCD.WriteString(dayOfWeek[tm.wday]);
      LCD.WriteLongint(0, tm.mday, 4, 1, 1, 2); LCD.WriteChar("/");
      LCD.WriteLongint(0, tm.mon+1, 7, 1, 2, 2); LCD.WriteChar("/");
      LCD.WriteLongint(0, tm.year+1900, 10, 1, 1, 4)
	END;
    LCD.SetAddr(x, y)
  END displayTime;


BEGIN dayOfWeek[0] := "Dim"; dayOfWeek[1] :="Lun"; dayOfWeek[2] := "Mar"; dayOfWeek[3] := "Mer";
  dayOfWeek[4] := "Jeu"; dayOfWeek[5] := "Ven"; dayOfWeek[6] :=  "Sam";

  M.WDTCTL^ := M.WDTPW + M.WDTHOLD;
  LCD.setCallbacks(select, deselect, setData, setCommand, send); (*register pcd8544 callbacks*)

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

  M.P1SEL2^ := {5, 7}; (* Port 1 Port Select 2 Register *)
  M.P1OUT^ := {0}; (** Port 1 Output Register *)
  M.P1SEL^ := {5, 7}; (* Port 1 Port Select Register *)
  M.P1DIR^ := {0}; (* Port 1 Direction Register *)
  M.P1REN^ := {1..4, 6}; (* Port 1 Resistor Enable Register *)
  M.P1IES^ := {}; (* Port 1 Interrupt Edge Select Register *)
  M.P1IFG^ := {}; (* Port 1 Interrupt Flag Register *)
  M.P1IE^ := {}; (* Port 1 Interrupt Enable Register *)

  M.P2OUT^ := {1}; (* Port 2 Output Register *)
  M.P2DIR^ := {0..2}; (* Port 2 Direction Register *)
  M.P2REN^ := {3..5}; (* Port 2 Resistor Enable Register *)
  M.P2IES^ := {}; (* Port 2 Interrupt Edge Select Register *)
  M.P2IFG^ := {};    (* Port 2 Interrupt Flag Register *)

  M.P3OUT^ := {}; (* Port 3 Output Register *)
  M.P3DIR^ := {}; (* Port 3 Direction Register *)


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
   * LFXT1S_0 -- If XTS = 0, XT1 = 32768kHz Crystal ; If XTS = 1, XT1 = 0.4 - 1-MHz crystal or resonator
   * XCAP_1 -- ~6 pF
   *)
  M.BCSCTL3^ := M.XT2S_0 + M.LFXT1S_0 + M.XCAP_1;

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

  M.UCB0BR0^ := 2; (* Bit Rate Control Register 0 *)
  BIC(M.UCB0CTL1^, M.UCSWRST); (* Enable USCI *)

  BIC(M.P1OUT^, NLIGHT);
  BIS(M.P2OUT^, NRST); Delay.CyclesX3(1); (*release reset*)
  LCD.Init; LCD.Clear;   PT.setMax(PTR(PT.Time, old_day)); PT.tick;
  LCD.SetAddr(0, 2); LCD.WriteString("Test PCD8544");
  displayTime;
END testpcd8544.

OMSPP.Compile PosixTime.Mod/s pcd8544.Mod/s testpcd8544.Mod/s ~
OMSPL.Link 32 4000H 200H testpcd8544 ~
  linking msp430g2553 msp430delay MultiPrecisionArith String pcd8544 Arith PosixTime testpcd8544
    flash 4310, data   28, stack  484 bytes

OMSPTool.DecObj testpcd8544.mpc
