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
//  MSP430G2x13/G2x53 Demo - Comp_A, Output Reference Voltages on P1.1
//
//  Description: Output Comparator_A reference levels on P1.1. Program will
//  cycle through the on-chip comparator_A reference voltages with output on
//  P1.1. Normal mode is LPM0, TA0_ISR will interrupt LPM0.
//  ACLK = n/a, MCLK = SMCLK = default DCO
//
//		  MSP430G2x13/G2x53
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//            |         P1.1/CA1|--> Vref
//            |                 |			
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//   C.Schoffit 06.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x13ca01;
  IMPORT SYSTEM, M := msp430g2553;

  (* Timer A0 interrupt service routine *)
  PROCEDURE* (M.TIMER0_A0_VECTOR) {} Timer_A;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM0_bits) (* Clear LPM0 bits from 0(SP) *)
  END Timer_A;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  M.CACTL2^ := M.P2CA4; (* CA1/P1.1 = +comp *)
  M.TA0CCTL0^ := M.CCIE; (* CCR0 interrupt enabled *)
  M.TA0CTL^ := M.TASSEL_2 + M.ID_3 + M.MC_2; (* SMCLK/8, cont-mode *)
  SYSTEM.BIS_SR(M.GIE); (* enable interrupts *)

  REPEAT (* Loop *)
    M.CACTL1^ := {}; (*No reference voltage *)
    SYSTEM.BIS_SR(M.LPM0_bits); (* Enter LPM0 *)
    M.CACTL1^ := M.CAREF0 + M.CAON; (* 0.25*Vcc, Comp. on *)
    SYSTEM.BIS_SR(M.LPM0_bits); (* Enter LPM0 *)
    M.CACTL1^ := M.CAREF1 + M.CAON; (* 0.5*Vcc, Comp. on *)
    SYSTEM.BIS_SR(M.LPM0_bits); (* Enter LPM0 *)
    M.CACTL1^ := M.CAREF1 + M.CAREF0 + M.CAON; (* 0.55V, Comp. on *)
    SYSTEM.BIS_SR(M.LPM0_bits); (* Enter LPM0 *)
  UNTIL FALSE
END  msp430g2x13ca01.

