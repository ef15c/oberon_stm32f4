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
 * --/COPYRIGHT--
//******************************************************************************
//  MSP430G2xx3 Demo - Timer_A, Toggle P1.0, CCR0 Cont. Mode ISR, DCO SMCLK
//
//  Description: Toggle P1.0 using software and TA_0 ISR. Toggles every
//  50000 SMCLK cycles. SMCLK provides clock source for TACLK.
//  During the TA_0 ISR, P1.0 is toggled and 50000 clock cycles are added to
//  CCR0. TA_0 ISR is triggered every 50000 cycles. CPU is normally off and
//  used only during TA_ISR.
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
//  Ported to Oberon by C. Schoffit 23.08.2024
//******************************************************************************)

MODULE msp430g2xx3ta01;
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE*(M.TIMER0_A0_VECTOR) Timer_A;
  BEGIN
    XOR(M.P1OUT^, {0}); (* Toggle P1.0 *)
    INC(M.TA0CCR0^, 50000); (* Add Offset to CCR0 *)
  END Timer_A;
 
BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIS(M.P1DIR^, {0}); (* P1.0 output *)
  M.TA0CCTL0^ := M.CCIE; (* CCR0 interrupt enabled *)
  M.TA0CCR0^ := 50000;
  M.TA0CTL^ := M.TASSEL_2 + M. MC_2; (* SMCLK, contmode *)

  SYSTEM.BIS_SR(M.LPM0_bits + M.GIE); (* Enter LPM0 w/ interrupt *)
END msp430g2xx3ta01.

OMSPTool.DecObj msp430g2xx3ta01.mpc
decode msp430g2xx3ta01.mpc
msp430g2xx3ta01 D9064DB7 Flash    46
imports:
	msp430g2553 F10488DC
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 000C
fixup procedures chains
fixup handlers chains
 0119     0	 0000
fixup data chains
fixup constants chains
fixup types chains
entry =  000C
code    46
 0000	     E3D2	XOR.B #1,&33
 0002	     0021
 0004	     50B2	ADD #-15536,&370
 0006	     C350
 0008	     0172
 000A	     1300	RETI
 000C	     40B2	MOV #23168,&288
 000E	     5A80
 0010	     0120
 0012	     D3D2	BIS.B #1,&34
 0014	     0022
 0016	     40B2	MOV #16,&354
 0018	     0010
 001A	     0162
 001C	     40B2	MOV #-15536,&370
 001E	     C350
 0020	     0172
 0022	     40B2	MOV #544,&352
 0024	     0220
 0026	     0160
 0028	     D032	BIS #24,SR
 002A	     0018
 002C	     4130	RET
