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
//  MSP430G2xx3 Demo - Timer_A, Toggle P1.0-2, Cont. Mode ISR, DCO SMCLK
//
//  Description: Use Timer_A CCRx units and overflow to generate three
//  independent timing intervals. For demonstration, CCR0 and CCR1 output
//  units are optionally selected with port pins P1.1 and P1.2 in toggle
//  mode. As such, these pins will toggle when respective CCRx registers match
//  the TAR counter. Interrupts are also enabled with all CCRx units,
//  software loads offset to next interval only - as long as the interval offset
//  is aded to CCRx, toggle rate is generated in hardware. Timer_A overflow ISR
//  is used to toggle P1.0 with software. Proper use of the TA0IV interrupt
//  vector generator is demonstrated.
//  ACLK = n/a, MCLK = SMCLK = TACLK = default DCO ~1MHz
//  As coded and assuming ~1MHz DCO, toggle rates are:
//  P1.1 = CCR0 ~ 1MHz/(2*200) ~2500Hz
//  P1.2 = CCR1 ~ 1MHz/(2*1000) ~500Hz
//  P1.0 = overflow ~ 1MHz/(2*65536) ~8Hz
//
//               MSP430G2xx3
//            -----------------
//        /|\|              XIN|-
//         | |                 |
//         --|RST          XOUT|-
//           |                 |
//           |         P1.1/TA0|--> CCR0
//           |         P1.2/TA1|--> CCR1
//           |             P1.0|--> Overflow/software
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 28.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3ta07;
  IMPORT SYSTEM, M := msp430g2553;

  (* Timer A0 interrupt service routine *)
  PROCEDURE* (M.TIMER0_A0_VECTOR) Timer_A0;
  BEGIN INC(M.TA0CCR0^, 200); (* Add Offset to CCR0 *)
  END Timer_A0;

  (* Timer_A2 Interrupt Vector (TA0IV) handler *)
  PROCEDURE* (M.TIMER0_A1_VECTOR) {4} Timer_A1;
    VAR taiv: INTEGER*;
  BEGIN taiv := M.TA0IV^;
    IF taiv = 2 THEN INC(M.TA0CCR1^, 1000); (* Add Offset to CCR1 *)
    ELSIF taiv = 10 THEN XOR(M.P1OUT^, {0}); (* Timer_A3 overflow *)
    END
  END Timer_A1;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIS(M.P1SEL^, {1, 2}); (* P1.1 - P1.2 option select *)
  BIS(M.P1DIR^, {0..2}); (* P1.0 - P1.2 outputs *)
  M.TA0CCTL0^ := M.OUTMOD_4 + M.CCIE; (* CCR0 toggle, interrupt enabled *)
  M.TA0CCTL1^ := M.OUTMOD_4 + M.CCIE; (* CCR1 toggle, interrupt enabled *)
  M.TA0CTL^ := M.TASSEL_2 +  M.MC_2 + M.TAIE; (* SMCLK, Contmode, int enabled *)

  SYSTEM.BIS_SR(M.LPM0_bits + M.GIE) (* Enter LPM0 w/ interrupt *)
END msp430g2xx3ta07.

OMSPTool.DecObj msp430g2xx3ta07.mpc
decode msp430g2xx3ta07.mpc
msp430g2xx3ta07 7E342066 Flash    82
imports:
	msp430g2553 F10488DC
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0028
fixup procedures chains
fixup handlers chains
 0119     0	 0000
 0118     0	 0008
fixup data chains
fixup constants chains
fixup types chains
entry =  0028
code    82
 0000	     50B2	ADD #200,&370
 0002	     00C8
 0004	     0172
 0006	     1300	RETI
 0008	     1204	PUSH R4
 000A	     4214	MOV &302,R4
 000C	     012E
 000E	     9324	CMP #2,R4
 0010	     2004	JNE $+10, goes to  001A
 0012	     50B2	ADD #1000,&372
 0014	     03E8
 0016	     0174
 0018	     3C05	JMP $+12, goes to  0024
 001A	     9034	CMP #10,R4
 001C	     000A
 001E	     2002	JNE $+6, goes to  0024
 0020	     E3D2	XOR.B #1,&33
 0022	     0021
 0024	     4134	POP R4
 0026	     1300	RETI
 0028	     40B2	MOV #23168,&288
 002A	     5A80
 002C	     0120
 002E	     D0F2	BIS.B #6,&38
 0030	     0006
 0032	     0026
 0034	     D0F2	BIS.B #7,&34
 0036	     0007
 0038	     0022
 003A	     40B2	MOV #144,&354
 003C	     0090
 003E	     0162
 0040	     40B2	MOV #144,&356
 0042	     0090
 0044	     0164
 0046	     40B2	MOV #546,&352
 0048	     0222
 004A	     0160
 004C	     D032	BIS #24,SR
 004E	     0018
 0050	     4130	RET
