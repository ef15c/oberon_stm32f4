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
//  MSP430G2xx3 Demo - Timer_A, Toggle P1.0, Overflow ISR, DCO SMCLK
//
//  Description: Toggle P1.0 using software and Timer_A overflow ISR.
//  In this example an ISR triggers when TA overflows. Inside the TA
//  overflow ISR P1.0 is toggled. Toggle rate is approximatlely 12Hz.
//  Proper use of TA0IV interrupt vector generator is demonstrated.
//  ACLK = n/a, MCLK = SMCLK = TACLK = default DCO
//
//           MSP430G2xx3
//         ---------------
//     /|\|            XIN|-
//      | |               |
//      --|RST        XOUT|-
//        |               |
//        |           P1.0|-->LED
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 27.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3ta03;
  IMPORT SYSTEM, M := msp430g2553;

  (* Timer_A3 Interrupt Vector (TA0IV) handler *)
  PROCEDURE* (M.TIMER0_A1_VECTOR) Timer_A;
  BEGIN (* CCR1, CCR2 not used *)
    IF M.TA0IV^ = 10 THEN XOR(M.P1OUT^,  {0}) (* overflow *) END
  END Timer_A;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIS(M.P1DIR^, {0}); (* P1.0 output *)
  M.TA0CTL^ := M.TASSEL_2 + M.MC_2 + M.TAIE; (* SMCLK, contmode, interrupt *)

  SYSTEM.BIS_SR(M.LPM0_bits + M.GIE) (* Enter LPM0 w/ interrupt *)
END msp430g2xx3ta03.

OMSPTool.DecObj msp430g2xx3ta03.mpc
decode msp430g2xx3ta03.mpc
msp430g2xx3ta03 47A89D95 Flash    36
imports:
	msp430g2553 F10488DC
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 000E
fixup procedures chains
fixup handlers chains
 0118     0	 0000
fixup data chains
fixup constants chains
fixup types chains
entry =  000E
code    36
 0000	     90B2	CMP #10,&302
 0002	     000A
 0004	     012E
 0006	     2002	JNE $+6, goes to  000C
 0008	     E3D2	XOR.B #1,&33
 000A	     0021
 000C	     1300	RETI
 000E	     40B2	MOV #23168,&288
 0010	     5A80
 0012	     0120
 0014	     D3D2	BIS.B #1,&34
 0016	     0022
 0018	     40B2	MOV #546,&352
 001A	     0222
 001C	     0160
 001E	     D032	BIS #24,SR
 0020	     0018
 0022	     4130	RET
