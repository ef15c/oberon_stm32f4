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
//  MSP430G2xx3 Demo - LFXT1 Oscillator Fault Detection
//
//  Description: System runs normally in LPM3 with WDT timer clocked by
//  32kHz ACLK with a 1x4 second interrupt. P1.0 is normally pulsed every
//  second inside WDT interrupt. If an LFXT1 oscillator fault occurs,
//  NMI is requested forcing exit from LPM3. P1.0 is toggled rapidly by software
//  as long as LFXT1 oscillator fault is present. Assumed only LFXT1 as NMI
//  source - code does not check for other NMI sources.
//  ACLK = LFXT1 = 32768, MCLK = SMCLK = Default DCO
//
//  //*External watch crystal on XIN XOUT is required for ACLK*//	
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
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 25.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3LFxtalnmi;
  IMPORT SYSTEM, M := msp430g2553;

  VAR i: INTEGER;

  PROCEDURE* (M.WDT_VECTOR) watchdog_timer;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Clear LPM3 bits from 0(SP) *)
  END watchdog_timer;

  PROCEDURE* (M.NMI_VECTOR) nmi_;
  BEGIN
    REPEAT BIC(M.IFG1^, M.OFIFG); (* Clear OSCFault flag *)
      FOR i := 0FFFH TO 1 BY -1 DO END; (* Time for flag to set *)
      XOR(M.P1OUT^, {0}) (* Toggle P1.0 using exclusive-OR *)
    UNTIL ~BIT(M.IFG1^, M.OFIFG); (* OSCFault flag still set? *)
    BIS(M.IE1^, M.OFIE); (* Enable Osc Fault *)
  END nmi_;

BEGIN
  M.WDTCTL^ := M.WDT_ADLY_1000; (* WDT 1s interval timer *)
  M.BCSCTL3^ := M.XCAP_2;
  BIS(M.IE1^, M.WDTIE); (* Enable WDT interrupt *)
  M.P1DIR^ := {0..7}; (* All P1.x outputs *)
  M.P1OUT^ := {}; (* All P1.x reset *)
  M.P2DIR^ := {0..7}; (* All P2.x outputs *)
  M.P2OUT^ := {}; (* All P2.x reset *)
  (* An immedate Osc Fault will occur next *)
  BIS(M.IE1^, M.OFIE); (* Enable Osc Fault *)

  REPEAT XOR(M.P1OUT^, {0}); (* Toggle P1.0 using exclusive-OR *)
    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3 w/interrupt *)
  UNTIL FALSE
END msp430g2xx3LFxtalnmi.
