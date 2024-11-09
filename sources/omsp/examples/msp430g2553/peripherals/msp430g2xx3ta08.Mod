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
//  MSP430G2xx3 Demo - Timer_A, Toggle P1.0-2, Cont. Mode ISR, 32kHz ACLK
//
//  Description: Use Timer_A CCRx units and overflow to generate four
//  independent timing intervals. For demonstration, CCR0 and CCR1 output
//  units are optionally selected with port pins P1.1 and P1.2 in toggle
//  mode. As such, these pins will toggle when respective CCRx registers match
//  the TAR counter. Interrupts are also enabled with all CCRx units,
//  software loads offset to next interval only - as long as the interval offset
//  is aded to CCRx, toggle rate is generated in hardware. Timer_A overflow ISR
//  is used to toggle P1.0 with software. Proper use of TA0IV interrupt vector
//  generator is demonstrated.
//  ACLK = TACLK = 32kHz, MCLK = SMCLK = Default DCO
//  As coded and with TACLK = 32768Hz, toggle rates are:
//  P1.1 = CCR0 = 32768/(2*4) = 4096Hz
//  P1.2 = CCR1 = 32768/(2*16) = 1024Hz
//  P1.0 = overflow = 32768/(2*65536) = 0.25Hz
//  //* External watch crystal on XIN XOUT is required for ACLK *//	
//
//              MSP430G2xx3
//            ---------------
//        /|\|            XIN|-
//         | |               | 32kHz
//         --|RST        XOUT|-
//           |               |
//           |       P1.1/TA0|--> CCR0
//           |       P1.2/TA1|--> CCR1
//           |           P1.0|--> Overflow/software
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 28.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3ta08;
  IMPORT SYSTEM, M := msp430g2553;

  (* Timer A0 interrupt service routine *)
  PROCEDURE* (M.TIMER0_A0_VECTOR) Timer_A0;
  BEGIN INC(M.TA0CCR0^, 4) (* Add Offset to CCR0 *)
  END Timer_A0;

  (* Timer_A2 Interrupt Vector (TA0IV) handler *)
  PROCEDURE* (M.TIMER0_A1_VECTOR) {4} Timer_A1;
    VAR taiv: INTEGER*;
  BEGIN taiv := M.TA0IV^;
    IF taiv = 2 THEN INC(M.TA0CCR1^, 16) (* Add Offset to CCR1 *)
    ELSIF taiv = 10 THEN XOR(M.P1OUT^, {0}) (* Timer_A overflow *)
    END
  END Timer_A1;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  M.BCSCTL3^ := M.XCAP_2; (* 10 pF xtal capacitor *)
  BIS(M.P1SEL^, {1, 2}); (* P1.1 - P1.2 option select *)
  BIS(M.P1DIR^, {0..2}); (* P1.0 - P1.2 outputs *)
  M.TA0CCTL0^ := M.OUTMOD_4 + M.CCIE; (* CCR0 toggle, interrupt enabled *)
  M.TA0CCTL1^ := M.OUTMOD_4 + M.CCIE; (* CCR1 toggle, interrupt enabled *)
  M.TA0CTL^ := M.TASSEL_1 + M.MC_2 + M.TAIE; (* ACLK, contmode, interrupt enabled *)

  SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* Enter LPM3 w/interrupt *)
END msp430g2xx3ta08.
