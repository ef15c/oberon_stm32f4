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
//  MSP430G2x33/G2x53 Demo - ADC10, DTC Sample A0 -> TA1, AVcc, DCO
//
//  Description: Use DTC to sample A0 with reference to AVcc and directly
//  transfer code to TACCR1. Timer_A has been configured for 10-bit PWM mode.
//  TACCR1 duty cycle is automatically proportional to ADC10 A0. WDT_ISR used
//  as a period wakeup timer approximately 45ms based on default ~1.2MHz
//  DCO/SMCLK clock source used in this example for the WDT clock source.
//  Timer_A also uses default DCO.
//
//                MSP430G2x33/G2x53
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//        >---|P1.0/A0      P1.2|--> TACCR1 - 0-1024 PWM
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 15.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x33adc1016;
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE* (M.WDT_VECTOR) WDT_ISR;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM0_bits) (* Exit LPM0 *)
  END WDT_ISR;

BEGIN
  M.WDTCTL^ := M.WDT_MDLY_32; (* WDT ~45ms interval timer *)
  BIS(M.IE1^, M.WDTIE); (* Enable WDT interrupt *)
  M.ADC10CTL0^ := M.ADC10SHT_2 + M.ADC10ON;
  BIS(M.ADC10AE0^, {0}); (* P1.0 ADC option select *)
  M.ADC10DTC1^ :=1; (* 1 conversion *)
  BIS(M.P1DIR^, {2}); (* P1.2 = output *)
  BIS(M.P1SEL^, {2}); (* P1.2 = TA1 output *)
  M.TA0CCR0^ := 1024 - 1; (* PWM Period *)
  M.TA0CCTL1^ := M.OUTMOD_7; (* TACCR1 reset/set *)
  M.TA0CCR1^ := 512; (* TACCR1 PWM Duty Cycle *)
  M.TA0CTL^ := M.TASSEL_2 + M.MC_1; (* SMCLK, upmode *)

  REPEAT
    SYSTEM.BIS_SR(M.LPM0_bits + M.GIE); (* LPM0, WDT_ISR will force exit *)
    M.ADC10SA^ := SYSTEM.VAL(INTEGER, M.TA0CCR1); (* Data transfer location *)
    BIS(M.ADC10CTL0^, M.ENC + M.ADC10SC); (* Start sampling *)
  UNTIL FALSE
END msp430g2x33adc1016.
