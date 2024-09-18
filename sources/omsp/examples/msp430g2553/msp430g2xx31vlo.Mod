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
//  MSP430G2xx3 Demo - Software Toggle P1.0, MCLK = VLO/8
//
//  Description; Pulse P1.0 with a 1/100 active duty cycle using software.
//  Ultra-low frequency ~ 1.5kHz, ultra-low power active mode demonstrated.
//  ACLK = VL0, MCLK = VLO/8 ~1.5kHz, SMCLK = n/a
//
//                MSP430G2xx3
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//            |             P1.0|-->LED
//
//  D. Dang
//  Texas Instruments, Inc
//  December 2010
//  C. Schoffit 17.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx31vlo;
  IMPORT SYSTEM, M := msp430g2553;

  VAR i: INTEGER;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  BIS(M.BCSCTL3^, M.LFXT1S_2); (* LFXT1 = VLO *)
  BIC(M.IFG1^, M.OFIFG); (* Clear OSCFault flag *)
  SYSTEM.BIS_SR(M.SCG1 + M.SCG0); (* Stop DCO *)
  BIS(M.BCSCTL2^, M.SELM_3 + M.DIVM_3); (* MCLK = LFXT1/8 *)
  M.P1DIR^ := {0..7}; (* All P1.x outputs *)
  M.P1OUT^ := {}; (* All P1.x reset *)
  M.P2DIR^ := {0..7}; (* All P2.x outputs *)
  M.P2OUT^ := {}; (* All P2.x reset *)

  REPEAT
    BIS(M.P1OUT^, {0}); (* P1.0 set *)
    i := 10; REPEAT DEC(i) UNTIL i = 0; (* Delay 1x *)
    BIC(M.P1OUT^, {0}); (* P1.0 reset *)
    i := 1000; REPEAT DEC(i) UNTIL i = 0 (* Delay 100x *)
  UNTIL FALSE
END msp430g2xx31vlo.
