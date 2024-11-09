(******************************************************************************
//   MSP430G2xx3 Demo - USCI_A0, UART Echo received character
//                     (ACLK 9600/SMCLK 9600/SMCLK 115200)
//
//   Description: The device will wait in LPM0/LPM3 (based on clock source)
//   until a UART character is received.
//   Then the device will echo the received character.
//   The UART can operate using ACLK at 9600, SMCLK at 115200 or SMCLK at 9600.
//   To configure the UART mode, uncomment the desired configuration code in initUART
//
//   UART RX ISR is used to handle communication.
//   ACLK = 32.768kHz, MCLK = SMCLK = DCO 16MHz.
//
//
//                   MSP430G2553
//                 -----------------
//            /|\ |             P2.6|--- XIN
//             |  |                 |   |
//             ---|RST              |   32kHz
//                |                 |   |
//                |             P2.7|--- XOUT
//                |             P1.1|<------- Receive Data (UCA0RXD)
//                |             P1.2|-------> Transmit Data (UCA0TXD)
//                |                 |
//                |                 |
//
//   Nima Eskandari
//   Texas Instruments Inc.
//   April 2017
//   Chrstian Schoffit 02.11.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3usciuarttrcv;
  IMPORT SYSTEM, M := msp430g2553;

  (******************************************************************************
   UART Initialization *********************************************************
  ******************************************************************************)

  PROCEDURE SendUCA0Data(data: BYTE*);
  BEGIN REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (* USCI_A0 TX buffer ready? *)
    M.UCA0TXBUF^ := data
  END SendUCA0Data;

  PROCEDURE initUART;
  BEGIN
    (* UART_MODE: SMCLK, 115200 bps *)
    BIS(M.UCA0CTL1^, M.UCSSEL_2); (* SMCLK *)
    M.UCA0BR0^ := 138; (* 16MHz 115200 *)
    M.UCA0BR1^ := 0; (* 16MHz 115200 *)
    M.UCA0MCTL^ := M.UCBRS_7; (* Modulation UCBRSx = 7 *)
    BIC(M.UCA0CTL1^, M.UCSWRST); (* **Initialize USCI state machine** *)
    BIC(M.IFG2^, M.UCA0RXIFG);
    BIS(M.IE2^, M.UCA0RXIE); (* Enable USCI_A0 RX interrupt *)
(* UART_MODE: SMCLK, 115200 bps choosen
    (* UART_MODE:  SMCLK, 9600 bps *)
    BIS(M.UCA0CTL1^, M.UCSSEL_2); (* SMCLK *)
    M.UCA0BR0^ := 104; (* 16MHz 9600 *)
    M.UCA0BR1^ := 0; (* 16MHz 9600 *)
    M.UCA0MCTL^ := M.UCBRS_0 + M.UCOS16 + M.UCBRF_3; (* Modulation UCBRSx = 0 *)
    BIC(M.UCA0CTL1^, M.UCSWRST); (* **Initialize USCI state machine** *)
    BIC(M.IFG2^, M.UCA0RXIFG);
    BIS(M.IE2^, M.UCA0RXIE); (* Enable USCI_A0 RX interrupt *)
    (* UART_MODE:  ACLK, 9600 bps *)
    BIS(M.UCA0CTL1^, M.UCSSEL_1); (* ACLK *)
    M.UCA0BR0^ := 3; (* 32768Hz 9600 *)
    M.UCA0BR1^ := 0; (* 32768Hz 9600 *)
    M.UCA0MCTL^ := M.UCBRS_3; (* Modulation UCBRSx = 3 *)
    BIC(M.UCA0CTL1^, M.UCSWRST); (* **Initialize USCI state machine** *)
    BIC(M.IFG2^, M.UCA0RXIFG);
    BIS(M.IE2^, M.UCA0RXIE) (* Enable USCI_A0 RX interrupt *)
*)
  END initUART;

  (*******************************************************************************
  // Device Initialization *******************************************************
  //******************************************************************************)

  PROCEDURE initClockTo16MHz;
  BEGIN REPEAT UNTIL M.CALBC1_16MHZ^ # {0..7}; (* If calibration constant erased do not load, trap CPU!! *)
    M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
    M.BCSCTL1^ := M.CALBC1_16MHZ^; (* Set DCO *)
    M.DCOCTL^ := M.CALDCO_16MHZ^;
  END initClockTo16MHz;

  PROCEDURE initGPIO;
  BEGIN
    M.P1SEL^ := {1, 2}; (* P1.1 = RXD, P1.2=TXD *)
    M.P1SEL2^ := {1, 2}
  END initGPIO;

  (*******************************************************************************
   UART RX Interrupt ***********************************************************
  ******************************************************************************)

  PROCEDURE* (M.USCIAB0RX_VECTOR) {4} USCI0RX_ISR;
  BEGIN
    IF BIT(M.IFG2^, M.UCA0RXIFG) THEN
      SendUCA0Data(M.UCA0RXBUF^) (* Must read UCxxRXBUF to clear the flag *) 
    END
  END USCI0RX_ISR;

(*******************************************************************************
   Main ************************************************************************
   Enters LPM4 if SMCLK is used and waits for UART interrupts. If ACLK is used *
   then the device will enter LPM3 mode instead. The UART RX interrupt handles *
   the received character and echoes it.                                       *
  ******************************************************************************)

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  initClockTo16MHz();
  initGPIO();
  initUART();
  
  (* UART MODE: SMCLK *)
  SYSTEM.BIS_SR(M.LPM4_bits + M.GIE); (* Since SMCLK is source and is fast to start, enter LPM4, interrupts enabled *)

(*
  (* UART MODE: ACLK, 9600 bps *)
  SYSTEM.BIS_SR(M.LPM3_bits +M. GIE); (* Since ACLK is source and takes a long time to start, enter LPM3, interrupts enabled *)
*)
END msp430g2xx3usciuarttrcv.

OMSPTool.DecObj msp430g2xx3usciuarttrcv.mpc
decode msp430g2xx3usciuarttrcv.mpc
msp430g2xx3usciuarttrcv 3F5AAE56 Flash   130
imports:
	msp430g2553 F10488DC
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 006A
fixup procedures chains
 0064     0	 0000
 007A     0	 000C
 0072     0	 0030
 0076     0	 0048
fixup handlers chains
 0117     0	 0056
fixup data chains
fixup constants chains
fixup types chains
entry =  006A
code   130
 0000	     B3E2	BIT.B #2,&3
 0002	     0003
 0004	     27FD	JEQ $-4, goes to  0000
 0006	     44C2	MOV.B R4,&103
 0008	     0067
 000A	     4130	RET
 000C	     D0F2	BIS.B #128,&97
 000E	     0080
 0010	     0061
 0012	     40F2	MOV.B #138,&98
 0014	     008A
 0016	     0062
 0018	     43C2	MOV.B #0,&99
 001A	     0063
 001C	     40F2	MOV.B #14,&100
 001E	     000E
 0020	     0064
 0022	     C3D2	BIC.B #1,&97
 0024	     0061
 0026	     C3D2	BIC.B #1,&3
 0028	     0003
 002A	     D3D2	BIS.B #1,&1
 002C	     0001
 002E	     4130	RET
 0030	     93F2	CMP.B #-1,&4345
 0032	     10F9
 0034	     27FD	JEQ $-4, goes to  0030
 0036	     43C2	MOV.B #0,&86
 0038	     0056
 003A	     42D2	MOV.B &4345,&87
 003C	     10F9
 003E	     0057
 0040	     42D2	MOV.B &4344,&86
 0042	     10F8
 0044	     0056
 0046	     4130	RET
 0048	     40F2	MOV.B #6,&38
 004A	     0006
 004C	     0026
 004E	     40F2	MOV.B #6,&65
 0050	     0006
 0052	     0041
 0054	     4130	RET
 0056	     1204	PUSH R4
 0058	     B3D2	BIT.B #1,&3
 005A	     0003
 005C	     2404	JEQ $+10, goes to  0066
 005E	     4254	MOV.B &102,R4
 0060	     0066
 0062	     12B0	CALL #0
 0064	     0000
 0066	     4134	POP R4
 0068	     1300	RETI
 006A	     40B2	MOV #23168,&288
 006C	     5A80
 006E	     0120
 0070	     12B0	CALL #0
 0072	     0000
 0074	     12B0	CALL #0
 0076	     0000
 0078	     12B0	CALL #0
 007A	     0000
 007C	     D032	BIS #248,SR
 007E	     00F8
 0080	     4130	RET
