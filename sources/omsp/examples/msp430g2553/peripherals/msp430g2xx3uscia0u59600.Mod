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
//   MSP430G2xx3 Demo - USCI_A0, Ultra-Low Pwr UART 9600 Echo ISR, 32kHz ACLK
//
//   Description: Echo a received character, RX ISR used. Normal mode is LPM3,
//   USCI_A0 RX interrupt triggers TX Echo.
//   ACLK = BRCLK = LFXT1 = 32768Hz, MCLK = SMCLK = DCO ~1.2MHz
//   Baud rate divider with 32768Hz XTAL @9600 = 32768Hz/9600 = 3.41
//* An external watch crystal is required on XIN XOUT for ACLK *//
//
//                MSP430G2xx3
//             -----------------
//         /|\|              XIN|-
//          | |                 | 32kHz
//          --|RST          XOUT|-
//            |                 |
//            |     P1.2/UCA0TXD|------------>
//            |                 | 9600 - 8N1
//            |     P1.1/UCA0RXD|<------------
//
//   D. Dang
//   Texas Instruments Inc.
//   February 2011
//   C. Schoffit 08.10.24, built Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscia0u59600;
  IMPORT SYSTEM, M := msp430g2553;

  (* Echo back RXed character, confirm TX buffer is ready first *)
  PROCEDURE* (M.USCIAB0RX_VECTOR) USCI0RX_ISR;
  BEGIN REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (* USCI_A0 TX buffer ready? *)
    M.UCA0TXBUF^ := M.UCA0RXBUF^ (* TX -> RXed character *)
  END USCI0RX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  M.P1DIR^ := {0..7}; (* All P1.x outputs *)
  M.P1OUT^ := {}; (* All P1.x reset *)
  M.P2DIR^ := {0..7}; (* All P2.x outputs *)
  M.P2OUT^ := {}; (* All P2.x reset *)
  M.P1SEL^ := {1, 2}; (* P1.1 = RXD, P1.2=TXD *)
  M.P1SEL2^ := {1, 2}; (* P1.1 = RXD, P1.2=TXD *)
  M.P3DIR^ := {0..7}; (* All P3.x outputs *)
  M.P3OUT^ := {}; (* All P3.x reset *)
  BIS(M.UCA0CTL1^, M.UCSSEL_1); (* CLK = ACLK *)
  M.UCA0BR0^ := 3; (* 32kHz/9600 = 3.41 *)
  M.UCA0BR1^ := 0;
  M.UCA0MCTL^ := M.UCBRS1 + M.UCBRS0; (* Modulation UCBRSx = 3 *)
  BIC(M.UCA0CTL1^, M.UCSWRST); (* **Initialize USCI state machine** *)
  BIS(M.IE2^, M.UCA0RXIE); (* Enable USCI_A0 RX interrupt *)

  SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3, interrupts enabled *)
END msp430g2xx3uscia0u59600.
