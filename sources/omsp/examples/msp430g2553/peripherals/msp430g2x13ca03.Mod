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
//  MSP430G2x13/G2x53 Demo - Comp_A, Simple 2.2V Low Battery Detect
//
//  Description: Two comparator_A reference generators 0.25*Vcc and ~0.55V
//  are compared for a simple battery check of 2.2V. In the subroutine
//   Batt_Check, a small capacitor between P2.3 and Vss is first charged
//  to 0.25*Vcc and then compared to ~0.55V. If 0.25*Vcc,
//  is above ~0.55V, P1.0 is toggled, else set. Batt_Check is called
//  constantly in an endless loop - in an actual application, Batt_Check
//  should be called infrequently to save power.
//  ACLK = n/a, MCLK = SMCLK = default DCO
//
//  There is a tolerance of the Comp_A reference generator and in the
//  device specific datasheet. In most applications, the tolerence of the
//  reference generator is more than adequate to detect Low Battery.
//
//		 MSP430G2x13/G2x53
//            -----------------
//       /|\ |              XIN|-
//        |  |                 |
//        ---|RST          XOUT|-
//           |                 |
//     +-----|P1.1/CA1     P1.0|-->LED
//     |     |                 |
//    ===.1uf|                 |
//     |     |                 |			
//     +-----|Vss
//
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//   C. Schoffit 07.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x13ca03;
  IMPORT M := msp430g2553;

  VAR i: INTEGER;

  PROCEDURE Batt_Check;
  BEGIN
    M.CACTL1^ := M.CAREF_1 + M.CAON; (* 0.25*Vcc on P1.1, Comp. on *)
    i := 16384; (* delay *)
    WHILE i > 0 DO DEC(i) END;
    M.CACTL1^ := M.CARSEL + M.CAREF_2 + M.CAREF_1 + M.CAON; (* 0.55V on -, Comp. on *)
    IF BIT(M.CACTL2^, M.CAOUT) THEN
      XOR(M.P1OUT^, {0}); (* P1.0 toggle *)
    ELSE BIS(M.P1OUT^, {0}); (* P1.0 set *)
    END;
    M.CACTL1^ := {} (* Disable Comp_A, save power *)
  END Batt_Check;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIS(M.P1DIR^, {0}); (* P1.0 output *)
  M.CACTL2^ := M.P2CA4; (* P1.1 = CA1 *)
  REPEAT Batt_Check UNTIL FALSE
END msp430g2x13ca03.
