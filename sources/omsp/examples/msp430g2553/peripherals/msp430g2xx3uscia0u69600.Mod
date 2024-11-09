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
//   MSP430G2xx3 Demo - USCI_A0, Ultra-Low Pwr UART 9600 String, 32kHz ACLK
//
//   Description: This program demonstrates a full-duplex 9600-baud UART using
//   USCI_A0 and a 32kHz crystal.  The program will wait in LPM3, and will
//   respond to a received 'u' character using 8N1 protocol. The response will
//   be the string 'Hello World'.
//   ACLK = BRCLK = LFXT1 = 32768Hz, MCLK = SMCLK = DCO ~1.2MHz
//   Baud rate divider with 32768Hz XTAL @9600 = 32768Hz/9600 = 3.41
//* An external watch crystal is required on XIN XOUT for ACLK *//
//
//                MSP430G2xx3
//             -----------------
//         /|\|              XIN|-
//          | |                 | 32kHz
//          --|RST          XOUT|-
//            |                 |
//            |     P1.2/UCA0TXD|------------>
//            |                 | 9600 - 8N1
//            |     P1.1/UCA0RXD|<------------
//
//   D. Dang
//   Texas Instruments Inc.
//   February 2011
//   C. Schoffit 08.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscia0u69600;
  IMPORT SYSTEM, M := msp430g2553;

  CONST string1 = "Hello World" + 0DX + 0AX;

  VAR i: INTEGER;

  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCI0TX_ISR;
  BEGIN  M.UCA0TXBUF^ := ORD(string1[i]); INC(i); (* TX next character *)
    IF i = LEN(string1) - 1 THEN (* TX over ? *) BIC(M.IE2^, M.UCA0TXIE) END (* Disable USCI_A0 TX interrupt *)
  END USCI0TX_ISR;

  PROCEDURE* (M.USCIAB0RX_VECTOR) {15} USCI0RX_ISR;
  BEGIN
    IF M.UCA0RXBUF^ = ORD("u") THEN (* 'u' received? *)
      i := 0;
      BIS(M.IE2^, M.UCA0TXIE); (* Enable USCI_A0 TX interrupt *)
      M.UCA0TXBUF^ := ORD(string1[i]); INC(i)
    END
  END USCI0RX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  M.P1DIR^ := {0..7}; (* All P1.x outputs *)
  M.P1OUT^ := {}; (* All P1.x reset *)
  M.P1SEL^ := {1, 2}; (* P1.1 = RXD, P1.2=TXD *)
  M.P1SEL2^ := {1, 2}; (* P1.1 = RXD, P1.2=TXD *)
  M.P2DIR^ := {0..7}; (* All P2.x outputs *)
  M.P2OUT^ := {}; (* All P2.x reset *)
  M.P3DIR^ := {0..7}; (* All P3.x outputs *)
  M.P3OUT^ := {}; (* All P3.x reset *)
  BIS(M.UCA0CTL1^, M.UCSSEL_1); (* CLK = ACLK *)
  M.UCA0BR0^ := 3; (* 32kHz/9600 = 3.41 *)
  M.UCA0BR1^ := 0;
  M.UCA0MCTL^ := M.UCBRS1 + M.UCBRS0; (* Modulation UCBRSx = 3 *)
  BIC(M.UCA0CTL1^, M.UCSWRST); (* **Initialize USCI state machine** *)
  BIS(M.IE2^, M.UCA0RXIE); (* Enable USCI_A0 RX interrupt *)

  SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* Enter LPM3 w/ int until Byte RXed *)
END msp430g2xx3uscia0u69600.

OMSPTool.DecObj msp430g2xx3uscia0u69600.mpc
decode msp430g2xx3uscia0u69600.mpc
msp430g2xx3uscia0u69600 824256D3 Flash   164
imports:
	msp430g2553 F10488DC
type descriptors

data     2
strings
Hello World
|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0048
fixup procedures chains
fixup handlers chains
 0116     0	 0000
 0117     0	 0022
fixup data chains
 0042     0	 0000
fixup constants chains
 003A     0	 0000
fixup types chains
entry =  0048
code   150
 0000	     120F	PUSH R15
 0002	     421F	MOV &0,R15
 0004	     0000
 0006	     503F	ADD #0,R15
 0008	     0000
 000A	     4FE2	MOV.B @R15,&103
 000C	     0067
 000E	     5392	ADD #1,&4
 0010	     0004
 0012	     90B2	CMP #13,&16
 0014	     000D
 0016	     0010
 0018	     2002	JNE $+6, goes to  001E
 001A	     C3E2	BIC.B #2,&1
 001C	     0001
 001E	     413F	POP R15
 0020	     1300	RETI
 0022	     120F	PUSH R15
 0024	     90F2	CMP.B #117,&102
 0026	     0075
 0028	     0066
 002A	     200C	JNE $+26, goes to  0044
 002C	     4382	MOV #0,&22
 002E	     0016
 0030	     D3E2	BIS.B #2,&1
 0032	     0001
 0034	     421F	MOV &46,R15
 0036	     002E
 0038	     503F	ADD #8,R15
 003A	     0008
 003C	     4FE2	MOV.B @R15,&103
 003E	     0067
 0040	     5392	ADD #1,&54
 0042	     0036
 0044	     413F	POP R15
 0046	     1300	RETI
 0048	     40B2	MOV #23168,&288
 004A	     5A80
 004C	     0120
 004E	     43F2	MOV.B #-1,&34
 0050	     0022
 0052	     43C2	MOV.B #0,&33
 0054	     0021
 0056	     40F2	MOV.B #6,&38
 0058	     0006
 005A	     0026
 005C	     40F2	MOV.B #6,&65
 005E	     0006
 0060	     0041
 0062	     43F2	MOV.B #-1,&42
 0064	     002A
 0066	     43C2	MOV.B #0,&41
 0068	     0029
 006A	     43F2	MOV.B #-1,&26
 006C	     001A
 006E	     43C2	MOV.B #0,&25
 0070	     0019
 0072	     D0F2	BIS.B #64,&97
 0074	     0040
 0076	     0061
 0078	     40F2	MOV.B #3,&98
 007A	     0003
 007C	     0062
 007E	     43C2	MOV.B #0,&99
 0080	     0063
 0082	     40F2	MOV.B #6,&100
 0084	     0006
 0086	     0064
 0088	     C3D2	BIC.B #1,&97
 008A	     0061
 008C	     D3D2	BIS.B #1,&1
 008E	     0001
 0090	     D032	BIS #216,SR
 0092	     00D8
 0094	     4130	RET
