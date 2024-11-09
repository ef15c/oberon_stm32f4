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
//   MSP430G2xx3 Demo - USCI_A0, Ultra-Low Pwr UART 9600 RX/TX, 32kHz ACLK
//
//   Description: This program demonstrates a full-duplex 9600-baud UART using
//   USCI_A0 and a 32kHz crystal.  The program will wait in LPM3, and receive
//   a string1 into RAM, and echo back the complete string.
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
//
//   D. Dang
//   Texas Instruments Inc.
//   February 2011
//   C. Schoffit 09.10.24, built with Oberon MSP compiler
//******************************************************************************)

MODULE msp430g2xx3uscia0u79600;
  IMPORT SYSTEM, M := msp430g2553;

  VAR string1: ARRAY 8 OF CHAR;
    i, j: BYTE;

  (* USCI A0/B0 Transmit ISR *)
  PROCEDURE* (M.USCIAB0TX_VECTOR) ^1 USCI0TX_ISR;
  BEGIN M.UCA0TXBUF^ := ORD(string1[i]); INC(i); (* TX next character *)
    IF i = LEN(string1) THEN (* TX over? *) BIC(M.IE2^, M.UCA0TXIE) (* Disable USCI_A0 TX interrupt *) END
  END USCI0TX_ISR;

  (* USCI A0/B0 Receive ISR *)
  PROCEDURE* (M.USCIAB0RX_VECTOR) ^2 USCI0RX_ISR;
  BEGIN string1[j] := CHR(M.UCA0RXBUF^); INC(j);
    IF j > LEN(string1) - 1 THEN i := 0; j := 0;
      BIS(M.IE2^, M.UCA0TXIE); (* Enable USCI_A0 TX interrupt *)
      M.UCA0TXBUF^ := ORD(string1[i]); INC(i)
    END
  END USCI0RX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  j := 0;
  M.P1DIR^ := {0..7}; (* All P1.x outputs *)
  M.P1OUT^ := {}; (* All P1.x reset *)
  M.P2DIR^ := {0..7}; (* All P2.x outputs *)
  M.P2OUT^ := {}; (* All P2.x reset *)
  M.P1SEL^ := {1, 2}; (* P1.1 = RXD, P1.2 = TXD *)
  M.P1SEL2^ := {1, 2}; (* P1.1 = RXD, P1.2 = TXD *)
  M.P3DIR^ := {0..7}; (* All P3.x outputs *)
  M.P3OUT^ := {}; (* All P3.x reset *)
  
  BIS(M.UCA0CTL1^, M.UCSSEL_1); (* CLK = ACLK *)
  M.UCA0BR0^ := 3; (* 32kHz/9600 = 3.41 *)
  M.UCA0BR1^ := 0;
  M.UCA0MCTL^ := M.UCBRS1 + M.UCBRS0; (* Modulation UCBRSx = 3 *)
  BIC(M.UCA0CTL1^, M.UCSWRST); (* **Initialize USCI state machine** *)
  BIS(M.IE2^, M.UCA0RXIE); (* Enable USCI_A0 RX interrupt *)

  SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* Enter LPM3, interrupts enabled *)
END msp430g2xx3uscia0u79600.

OMSPTool.DecObj msp430g2xx3uscia0u79600.mpc
decode msp430g2xx3uscia0u79600.mpc
msp430g2xx3uscia0u79600 7BEED13D Flash   182
imports:
	msp430g2553 F10488DC
type descriptors

data    10
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0064
fixup procedures chains
fixup handlers chains
 0116     0	 0000
 0117     0	 0020
fixup data chains
 005C     0	 0008
 0054     0	 0000
 006C     0	 0009
fixup constants chains
fixup types chains
entry =  0064
code   182
 0000	     120F	PUSH R15
 0002	     425F	MOV.B &0,R15
 0004	     0000
 0006	     503F	ADD #0,R15
 0008	     0000
 000A	     4FE2	MOV.B @R15,&103
 000C	     0067
 000E	     53D2	ADD.B #1,&4
 0010	     0004
 0012	     92F2	CMP.B #8,&16
 0014	     0010
 0016	     2002	JNE $+6, goes to  001C
 0018	     C3E2	BIC.B #2,&1
 001A	     0001
 001C	     413F	POP R15
 001E	     1300	RETI
 0020	     120F	PUSH R15
 0022	     120E	PUSH R14
 0024	     425F	MOV.B &0,R15
 0026	     0000
 0028	     503F	ADD #8,R15
 002A	     0008
 002C	     42DF	MOV.B &102,0(R15)
 002E	     0066
 0030	     0000
 0032	     53D2	ADD.B #1,&38
 0034	     0026
 0036	     425F	MOV.B &52,R15
 0038	     0034
 003A	     403E	MOV #7,R14
 003C	     0007
 003E	     9F0E	CMP R15,R14
 0040	     340E	JGE $+30, goes to  005E
 0042	     43C2	MOV.B #0,&20
 0044	     0014
 0046	     43C2	MOV.B #0,&56
 0048	     0038
 004A	     D3E2	BIS.B #2,&1
 004C	     0001
 004E	     425F	MOV.B &68,R15
 0050	     0044
 0052	     503F	ADD #42,R15
 0054	     002A
 0056	     4FE2	MOV.B @R15,&103
 0058	     0067
 005A	     53D2	ADD.B #1,&80
 005C	     0050
 005E	     413E	POP R14
 0060	     413F	POP R15
 0062	     1300	RETI
 0064	     40B2	MOV #23168,&288
 0066	     5A80
 0068	     0120
 006A	     43C2	MOV.B #0,&72
 006C	     0048
 006E	     43F2	MOV.B #-1,&34
 0070	     0022
 0072	     43C2	MOV.B #0,&33
 0074	     0021
 0076	     43F2	MOV.B #-1,&42
 0078	     002A
 007A	     43C2	MOV.B #0,&41
 007C	     0029
 007E	     40F2	MOV.B #6,&38
 0080	     0006
 0082	     0026
 0084	     40F2	MOV.B #6,&65
 0086	     0006
 0088	     0041
 008A	     43F2	MOV.B #-1,&26
 008C	     001A
 008E	     43C2	MOV.B #0,&25
 0090	     0019
 0092	     D0F2	BIS.B #64,&97
 0094	     0040
 0096	     0061
 0098	     40F2	MOV.B #3,&98
 009A	     0003
 009C	     0062
 009E	     43C2	MOV.B #0,&99
 00A0	     0063
 00A2	     40F2	MOV.B #6,&100
 00A4	     0006
 00A6	     0064
 00A8	     C3D2	BIC.B #1,&97
 00AA	     0061
 00AC	     D3D2	BIS.B #1,&1
 00AE	     0001
 00B0	     D032	BIS #216,SR
 00B2	     00D8
 00B4	     4130	RET
