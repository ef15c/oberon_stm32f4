(* --COPYRIGHT--,BSD_EX
 * Copyright (c) 2012, Texas Instruments Incorporated
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *******************************************************************************
 * 
 *                       MSP430 CODE EXAMPLE DISCLAIMER
 *
 * MSP430 code examples are self-contained low-level programs that typically
 * demonstrate a single peripheral function or device feature in a highly
 * concise manner. For this the code may rely on the device's power-on default
 * register values and settings such as the clock configuration and care must
 * be taken when combining code from several examples to avoid potential side
 * effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
 * for an API functional library-approach to peripheral configuration.
 *
 * --/COPYRIGHT--*/
//******************************************************************************
//   MSP430G2xx3 Demo - USCI_A0, UART 9600 Full-Duplex Transceiver, 32kHz ACLK
//
//   Description: USCI_A0 communicates continously as fast as possible full-
//   duplex with another device. Normal mode is LPM3, with activity only during
//   RX and TX ISR's. The TX ISR indicates the USCI_A0 is ready to send another
//   character. The RX ISR indicates the USCI_A0 has received a character. At
//   9600 baud, a full character is tranceived ~1ms.
//   The levels on P1.3/P1.4 are TX'ed. RX'ed value is displayed on P1.6/0.  
//   ACLK = BRCLK = LFXT1 = 32768Hz, MCLK = SMCLK = DCO ~1.2MHz
//   Baud rate divider with 32768Hz XTAL @9600 = 32768Hz/9600 = 3.41
//* An external watch crystal is required on XIN XOUT for ACLK *//
//
//                 MSP430G2xx3                  MSP430G2xx3
//              -----------------            -----------------
//             |              XIN|-      /|\|              XIN|-
//             |                 | 32kHz  | |                 | 32kHz
//             |             XOUT|-       --|RST          XOUT|-
//             |                 | /|\      |                 |
//             |              RST|---       |                 |
//             |                 |          |                 |
//           ->|P1.3             |          |             P1.0|-> LED
//           ->|P1.4             |          |             P1.6|-> LED
//       LED <-|P1.0             |          |             P1.3|<-
//       LED <-|P1.6             |          |             P1.4|<-
//             |     UCA0TXD/P1.2|--------->|P1.1             |
//             |                 |   9600   |                 |
//             |     UCA0RXD/P1.1|<---------|P1.2             |
//
//
//   D. Dang
//   Texas Instruments Inc.
//   February 2011
//   C. Schoffit 09.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscia0u89600;
  IMPORT SYSTEM, M := msp430g2553;

  (* USCI A0/B0 Transmit ISR *)
  PROCEDURE* (M.USCIAB0TX_VECTOR) {4} USCI0TX_ISR;
    VAR TxByte: BYTE*;
  BEGIN TxByte := 0;
    IF BIT(M.P1IN^, {3}) THEN BIS(TxByte, {6}) END;
    IF BIT(M.P1IN^, {4}) THEN BIS(TxByte, {0}) END;
    M.UCA0TXBUF^ := TxByte (* Read, justify, and transmit *)
  END USCI0TX_ISR;

  (* USCI A0/B0 Receive ISR *)
  PROCEDURE* (M.USCIAB0RX_VECTOR) USCI0RX_ISR;
  BEGIN M.P1OUT^ := SYSTEM.VAL(BYTESET, M.UCA0RXBUF^) (* Display RX'ed charater *)
  END USCI0RX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  M.P1OUT^ := {}; (* P1.0/6 setup for LED output *)
  M.P1DIR^ := {0, 6};
  M.P1SEL^ := {1, 2}; (* P1.1 = RXD, P1.2=TXD *)
  M.P1SEL2^ := {1, 2};
  BIS(M.UCA0CTL1^, M.UCSSEL_1); (* CLK = ACLK *)
  M.UCA0BR0^ := 3; (* 32kHz/9600 = 3.41 *)
  M.UCA0BR1^ := 0;
  M.UCA0MCTL^ := M.UCBRS1 + M.UCBRS0; (* Modulation UCBRSx = 3 *)
  BIC(M.UCA0CTL1^, M.UCSWRST); (* **Initialize USCI state machine** *)
  BIS(M.IE2^, M.UCA0RXIE + M.UCA0TXIE); (* Enable USCI_A0 TX/RX interrupt *)

  SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* Enter LPM3 w/ interrupts enabled *)
END msp430g2xx3uscia0u89600.

OMSPTool.DecObj msp430g2xx3uscia0u89600.mpc
decode msp430g2xx3uscia0u89600.mpc
msp430g2xx3uscia0u89600 4D0812AC Flash   106
imports:
	msp430g2553 F10488DC
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0028
fixup procedures chains
fixup handlers chains
 0116     0	 0000
 0117     0	 0020
fixup data chains
fixup constants chains
fixup types chains
entry =  0028
code   106
 0000	     1204	PUSH R4
 0002	     4344	MOV.B #0,R4
 0004	     B2F2	BIT.B #8,&32
 0006	     0020
 0008	     2402	JEQ $+6, goes to  000E
 000A	     D074	BIS.B #64,R4
 000C	     0040
 000E	     B0F2	BIT.B #16,&32
 0010	     0010
 0012	     0020
 0014	     2401	JEQ $+4, goes to  0018
 0016	     D354	BIS.B #1,R4
 0018	     44C2	MOV.B R4,&103
 001A	     0067
 001C	     4134	POP R4
 001E	     1300	RETI
 0020	     42D2	MOV.B &102,&33
 0022	     0066
 0024	     0021
 0026	     1300	RETI
 0028	     40B2	MOV #23168,&288
 002A	     5A80
 002C	     0120
 002E	     43C2	MOV.B #0,&33
 0030	     0021
 0032	     40F2	MOV.B #65,&34
 0034	     0041
 0036	     0022
 0038	     40F2	MOV.B #6,&38
 003A	     0006
 003C	     0026
 003E	     40F2	MOV.B #6,&65
 0040	     0006
 0042	     0041
 0044	     D0F2	BIS.B #64,&97
 0046	     0040
 0048	     0061
 004A	     40F2	MOV.B #3,&98
 004C	     0003
 004E	     0062
 0050	     43C2	MOV.B #0,&99
 0052	     0063
 0054	     40F2	MOV.B #6,&100
 0056	     0006
 0058	     0064
 005A	     C3D2	BIC.B #1,&97
 005C	     0061
 005E	     D0F2	BIS.B #3,&1
 0060	     0003
 0062	     0001
 0064	     D032	BIS #216,SR
 0066	     00D8
 0068	     4130	RET
