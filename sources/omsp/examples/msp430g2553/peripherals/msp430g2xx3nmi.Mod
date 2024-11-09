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
//  MSP430G2xx3 Demo - Basic Clock, Configure RST/NMI as NMI
//
//  Description: Configure RST/NMI as NMI, hi/lo edge. Flash P1.0  inside of
//  NMI_ISR if NMI occurs. General enable interrupt in status register does
//  not need to be set for NMI. NMIIE does need to be reset, as NMI_ISR
//  automatically clears NMI enable to prevent unintentional stack overflow
//  that could result from, bounce or uncontrolled NMI's.
//  ACLK = n/a, MCLK = SMCLK = DCO ~ 800k
//
//               MSP430G2xx3
//            -----------------
//        /|\|              XIN|-
//         | |                 |
//         --|RST          XOUT|-
//           |                 |
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 25.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3nmi;
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE* (M.NMI_VECTOR) nmi_;
    VAR i: INTEGER;
  BEGIN
    BIS(M.P1OUT^, {0}); (* Set P1.0 LED on *)
    i := 20000; REPEAT DEC(i) UNTIL i = 0; (* Delay *)
    BIC(M.P1OUT^, {0}); (* Clear P1.0 LED off *)
    BIC(M.IFG1^, M.NMIIFG); (* Reclear NMI flag in case bounce *)
    BIS(M.IE1^, M.NMIIE); (* Enable NMI *)
  END nmi_;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD + M.WDTNMI + M.WDTNMIES; (* WDT off NMI hi/lo *)
  BIS(M.P1DIR^, {0}); (* Set P1.0 to output direction *)
  BIC(M.P1OUT^, {0}); (* Clear P1.0 LED off *)
  BIS(M.IE1^, M.NMIIE); (* Enable NMI *)

  SYSTEM.BIS_SR(M.LPM0_bits) (* Enter LPM0 *)
END msp430g2xx3nmi.
