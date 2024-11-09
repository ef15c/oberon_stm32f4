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
//  MSP430G2xx3 Demo - Basic Clock, LPM3 Using WDT ISR, 32kHz ACLK
//
//  Description: This program operates MSP430 normally in LPM3, pulsing P1.0
//  at 4 second intervals. WDT ISR used to wake-up system. All I/O configured
//  as low outputs to eliminate floating inputs. Current consumption does
//  increase when LED is powered on P1.0. Demo for measuring LPM3 current.
//  ACLK = LFXT1/4 = 32768/4, MCLK = SMCLK = default DCO ~ 800kHz
//  //* External watch crystal installed on XIN XOUT is required for ACLK *//	
//
//
//           MSP430G2xx3
//         ---------------
//     /|\|            XIN|-
//      | |               | 32kHz
//      --|RST        XOUT|-
//        |               |
//        |           P1.0|-->LED
//
//  Eason Zhou
//  Texas Instruments Inc.
//  January 2020
//  C. Schoffit 25.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3lpm3;
  IMPORT SYSTEM, M := msp430g2553;

  VAR i: INTEGER;

  PROCEDURE* (M.WDT_VECTOR) watchdog_timer;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Clear LPM3 bits from 0(SP) *)
  END watchdog_timer;

BEGIN
  BIS(M.BCSCTL1^, M.DIVA_2); (* ACLK/4 *)
  M.WDTCTL^ := M.WDT_ADLY_1000; (* WDT 1s/4 interval timer *)
  BIS(M.IE1^, M.WDTIE); (* Enable WDT interrupt *)
  M.P1DIR^ := {0..7}; (* All P1.x outputs *)
  M.P1OUT^ := {}; (* All P1.x reset *)
  M.P2DIR^ := {0..7}; (* All P2.x outputs *)
  M.P2OUT^ := {}; (* All P2.x reset *)
  M.P3DIR^ := {0..7}; (* All P3.x outputs *)
  M.P3OUT^ := {}; (* All P3.x reset *)
  
  REPEAT
    BIS(M.P1OUT^, {0}); (* Set P1.0 LED on *)
    i := 5000;REPEAT DEC(i) UNTIL i = 0; (* Delay *)
    BIC(M.P1OUT^, {0}); (* Reset P1.0 LED off *)
    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* Enter LPM3 *)
  UNTIL FALSE
END msp430g2xx3lpm3.
