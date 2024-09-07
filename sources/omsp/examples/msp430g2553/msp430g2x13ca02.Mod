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
//   MSP430G2x13/G2x53 Demo - Comp_A, Detect Threshold, Set P1.0 if P1.1 > 0.25*Vcc
//
//   Description: Use Comparator_A to detect a voltage threshold.
//   Using an external potentiometer, an unknown voltage is applied to P1.1.
//   Comparator_A compares the unknown voltage to an internal reference
//   voltage, in this example 0.25*VCC. If the unknown voltage is higher
//   than 0.25*VCC, P1.0 is set, if not, P1.0 is reset.
//   ACLK = n/a, MCLK = SMCLK = default DCO
//
//          MSP430G2x13/G2x53
//       -----------------
//   /|\ |            XIN|-
//    |  |               |
//    ---|RST        XOUT|-
//    |  |               |
//    R<-|P1.1/CA1   P1.0|-->LED
//    |  |               |
//    ---|VSS
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//   C. Schoffit 06.09.24,built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x13ca02;
  IMPORT M := msp430g2553;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIS(M.P1DIR^, {0}); (* P1.0 output *)
  M.CACTL1^ := M.CARSEL + M.CAREF0 + M.CAON; (* 0.25 Vcc = -comp, on *)
  M.CACTL2^ := M.P2CA4; (* P1.1/CA1 = +comp *)

  REPEAT (* Test comparator_A output *)
    IF BIT(M.CACTL2^, M.CAOUT) THEN
      BIS(M.P1OUT^, {0}) (* if CAOUT set, set P1.0 *)
    ELSE BIC(M.P1OUT^, {0}) (* else reset *)
    END
  UNTIL FALSE
END msp430g2x13ca02.

OMSPTool.DecObj msp430g2x13ca02.mpc
decode msp430g2x13ca02.mpc
msp430g2x13ca02 CA3D057A Flash    42
imports:
	msp430g2553 D739B001
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0000
code    42
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     D3D2	BIS.B #1,&34
 0008	     0022
 000A	     40F2	MOV.B #88,&89
 000C	     0058
 000E	     0059
 0010	     40F2	MOV.B #64,&90
 0012	     0040
 0014	     005A
 0016	     B3D2	BIT.B #1,&90
 0018	     005A
 001A	     2403	JEQ #3, goes to  0022
 001C	     D3D2	BIS.B #1,&33
 001E	     0021
 0020	     3C02	JMP #2, goes to  0026
 0022	     C3D2	BIC.B #1,&33
 0024	     0021
 0026	     3FF7	JMP #-9, goes to  0016
 0028	     4130	RET
