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
//  MSP430G2x33/G2x53 Demo - ADC10, Sample A7, 1.5V, TA1 Trig, Ultra-Low Pwr
//
//  Description: A7 is sampled 1024/second (32xACLK)with reference to 1.5V. All
//  activity is interrupt driven with proper usage of MSP430 low-power modes,
//  ADC10 and Vref demonstrated. Timer_A with both TA1/TA0 used in upmode to
//  drive ADC10 conversion (continuous mode can also be used). Inside
//  of TA0_ISR software will enable ADC10 and internal reference and
//  allow > 30us delay for Vref to stabilize prior to sample start. Sample
//  start is automatically triggered by TA1 every 32 ACLK cycles. ADC10_ISR
//  will disable ADC10 and Vref and compare ADC10 conversion code. Internal
//  oscillator times sample (16x) and conversion (13x). If A7 > 0.2Vcc,
//  P1.0 is set, else reset. Normal Mode is LPM3.
//  //* An external watch crystal on XIN XOUT is required for ACLK *//
//
//                    +-----(0.9766us)---------\\------------------>+
//    TA0_ISR        TA1      ADC10_ISR             TA0_ISR        TA1
//  -----+------------+------------+-----------\\------+------------+----->
//   Enable ADC    Trigger ADC  Disable ADC
//   and Vref                   Compare
//       +-( >30us--->+
//
//
//               MSP430G2x33/G2x53
//            -----------------
//        /|\|              XIN|-
//         | |                 | 32kHz
//         --|RST          XOUT|-
//           |                 |
//       >---|P1.7/A7     P1.0 |--> LED
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x33adc1012;
  IMPORT SYSTEM, M := msp430g2553;

  (* ADC10 interrupt service routine *)
  PROCEDURE* (M.ADC10_VECTOR)  ADC10_ISR;
  BEGIN
    BIC(M.ADC10CTL0^, M.ENC); (* ADC10 disabled *)
    M.ADC10CTL0^ := {}; (* ADC10, Vref disabled completely *)
    IF  M.ADC10MEM^ < 88H (* ADC10MEM = A7 > 0.2V? *) THEN BIC(M.P1OUT^, {0}); (* Clear P1.0 LED off *)
    ELSE BIS(M.P1OUT^, {0}); (* Set P1.0 LED on *)
    END
  END ADC10_ISR;

  (* Timer A0 interrupt service routine *)
  PROCEDURE* (M.TIMER0_A0_VECTOR) Timer_A;
  BEGIN
    M.ADC10CTL0^ := M.SREF_1 + M.ADC10SHT_2 + M.REFON + M.ADC10ON + M.ADC10IE;
    BIS(M.ADC10CTL0^, M.ENC) (* ADC10 enable set *)
  END Timer_A;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)

  M.ADC10CTL1^ := M.INCH_7 + M.SHS_1; (* P1.7, TA1 trigger sample start *)
  M.ADC10AE0^ := {7}; (* P1.7 ADC10 option select *)
  BIS(M.P1DIR^, {0}); (* Set P1.0 to output direction *)
  M.TA0CCTL0^ := M.CCIE; (* Enable interrupt *)
  M.TA0CCR0^ := 32-1; (* PWM Period *)
  M.TA0CCTL1^ := M.OUTMOD_3; (* TACCR1 set/reset *)
  M.TA0CCR1^ := 2; (* TACCR1 PWM Duty Cycle *)
  M.TA0CTL^ := M.TASSEL_1 + M.MC_1; (* ACLK, up mode *)
  SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3, enable interrupts *)
END msp430g2x33adc1012.
