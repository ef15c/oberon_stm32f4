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
//  MSP430G2xx3 Demo - Timer_A0, Normal Timer Mode Input Period and Dutycycle
//                     measurement
//  Description: This code example implements input capture in single capture
//  mode using TimerA in normal timer mode. TA1.1 is configured to output PWM
//  of 25% dutycycle, that is used as capture input at TA0.1. TA0.1 is
//  configured as timer input capture that is triggered by both the rising and
//  the falling edges. An external connection between TA1.1 and TA0.1 is
//  required in this example. Rising and Falling edges are captured and the
//  dutycycle is computed. If the measured dutycycle is != 25%, then LED on
//  P1.0 is set.
//
//  ACLK = LFXT1 = 32kHz crystal ; SMCLK = MCLK = 8 MHz;
//
//                 MSP430FG2xx3
//             -----------------
//         /|\|              XIN|-
//          | |                 | 32kHz
//          --|RST          XOUT|-
//            |                 |
//            |       P1.2/TA0.1|<-- CCI1A <-|
//            |       P2.1/TA1.1|--> CCR1 -->|
//            |                 |
//            |             P1.0|--> LED "ON" when dutycycle != 25%
//            |                 |

//
//  W. Goh
//  Texas Instruments Inc.
//  March 2012
//  C. Schoffit 30.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3ta21;
  IMPORT SYSTEM, M := msp430g2553, m := MultiPrecisionArith;

  VAR First_REdge, First_Time: BOOLEAN;
    REdge1, REdge2, FEdge: INTEGER;

    Period, ON_Period: INTEGER;
    DutyCyclel, DutyCycleh, Pl, Ph: INTEGER;

    Count: BYTE;

  (* TA0_A1 Interrupt vector *)
  PROCEDURE* (M.TIMER0_A1_VECTOR) TIMER0_A1_ISR;
  BEGIN
    IF M.TA0IV^ = M.TA0IV_TACCR1 THEN (* Vector  2:  TACCR1 CCIFG *)
      IF BIT(M.TA0CCTL1^, M.CCI) (* Capture Input Pin Status *) THEN
        (* Rising Edge was captured *)
        IF First_REdge THEN REdge1 := M.TA0CCR1^
        ELSE REdge2 := M.TA0CCR1^; SYSTEM.BIC_SR_ON_EXIT(M.LPM0_bits + M.GIE) (* Exit LPM0 on return to main *)
        END; XOR(First_REdge, TRUE);
        IF First_Time THEN First_Time := FALSE END
      ELSE (* Falling Edge was captured *)
        IF ~First_Time THEN FEdge := M.TA0CCR1^ END
      END
    END
  END TIMER0_A1_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  M.BCSCTL3^ := M.XCAP_2;

  BIS(M.P1DIR^, {0, 1}); (* P1.0-P1.1/LEDs Output *)
  BIC(M.P1OUT^, {0, 1}); (* LEDs off *)
  REPEAT UNTIL M.CALBC1_8MHZ^ # {0..7}; (* If calibration constant erased do not load, trap CPU!! *)
  M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
  M.BCSCTL1^ := M.CALBC1_8MHZ^; (* Set DCO to 8MHz *)
  M.DCOCTL^ := M.CALDCO_8MHZ^;

  (* Configure Port Pins *)
  BIS(M.P2DIR^, {1}); (* P2.1/TA1.1 Output *)
  BIS(M.P2SEL^, {1}); (* TA1.1 Option select *)
  BIC(M.P1DIR^, {2}); (* P1.1/TA0.1 Input Capture *)
  BIS(M.P1SEL^, {2}); (* TA0.1 option select *)

  (* Configure TA1.1 to output PWM signal. Period = 82/32khz = 2.5ms ~ 400Hz Freq *)
  M.TA1CCR0^ := 82-1; (* Period Register *)
  M.TA1CCR1^ := 21; (* TA1.1 25% dutycycle *)
  BIS(M.TA1CCTL1^, M.OUTMOD_7); (* TA1CCR1, Reset/Set *)
  M.TA1CTL^ := M.TASSEL_1 + M.MC_1 + M.TACLR; (* ACLK, upmode, clear TAR *)

  (* Configure the TA0CCR1 to do input capture *)
  M.TA0CCTL1^ := M.CAP + M.CM_3 + M.CCIE + M.SCS + M.CCIS_0; (* TA0CCR1 Capture mode; CCI1A; Both Rising and Falling Edge; interrupt enable *)
  BIS(M.TA0CTL^, M.TASSEL_2 + M.MC_2 + M.TACLR); (* SMCLK, Cont Mode; start timer *)

  (* Variable Initialization *)
  First_REdge := TRUE;
  First_Time := TRUE;
  Count := 0;

  REPEAT
    SYSTEM.BIS_SR(M.LPM0_bits + M.GIE); (* Enter LPM0 *)
    NOP; (* For debugger *)
    (* On exiting LPM0 *)
    IF Count = 0 THEN XOR(M.P1OUT^, {1}); (* toggle P1.1 LED for hearbeat *) END; INC(Count);
    IF  BIT(M.TA0CCTL1^, M.COV) (* Check for Capture Overflow *) THEN REPEAT UNTIL FALSE END; (* Loop Forever *)
    Period := REdge2 - REdge1; (* Calculate Period *)
    ON_Period := FEdge - REdge1; (* On period *)
    (* DutyCycle = ((unsigned long)ON_Period*100/Period); *)
    m.SetLongInt(DutyCycleh, DutyCyclel, ON_Period); m.MulLongInt(DutyCycleh, DutyCyclel, 100);
    m.SetLongInt(Ph, Pl, Period); m.DivLongLong(DutyCycleh, DutyCyclel, Ph, Pl);
    IF (DutyCycleh # 0) OR (DutyCyclel # 25) THEN BIS(M.P1OUT^, {0}) ELSE BIC(M.P1OUT^, {0}) END
  UNTIL FALSE
END msp430g2xx3ta21.
