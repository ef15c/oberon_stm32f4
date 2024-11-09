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
//  MSP430G2xx3 Demo - USCI_A0 IrDA External Loopback Test, 8MHz SMCLK
//
//  Description: This example transmits bytes through the USCI module
//  configured for IrDA mode, and receives them using an external loopback
//  connection. The transfered sequence is 00h, 01h, 02h, ..., ffh. The
//  received bytes are also stored in memory starting at address RxData.
//  In the case of an RX error the LED is lighted and program execution stops.
//  An external loopback connection has been used as it allows for the
//  connection of a scope to monitor the communication, which is not possible
//  when using the internal loopback.
//  ACLK = n/a, MCLK = SMCLK = BRCLK = CALxxx_8MHZ = 8MHz
//
//              MSP430G2xx3
//            -----------------
//        /|\|              XIN|-
//         | |                 |
//         --|RST          XOUT|-
//           |                 |
//           |     P1.1/UCA0RXD|--+   external
//           |     P1.2/UCA0TXD|--+   loopback connection
//           |                 |
//           |                 |
//           |             P1.0|--->  LED
//           |                 |
//
//  D. Dang
//  Texas Instruments Inc.
//  February 2011
//  C. Schoffit 05.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscia0irda01;
  IMPORT SYSTEM, M := msp430g2553;

  VAR RxByte, TxByte: BYTE;
    RxData: ARRAY 256 OF BYTE;
    i: INTEGER;

  PROCEDURE* (M.USCIAB0RX_VECTOR) USCIAB0RX_ISR;
  BEGIN RxByte := M.UCA0RXBUF^; (* Get RXed character *)
    BIC(M.IE2^, M.UCA0RXIE); (* Disable RX int *)
    SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF);(* Exit LPM0 *)
  END USCIAB0RX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  REPEAT UNTIL M.CALBC1_8MHZ^ # {0..7}; (* If calibration constant erased do not load, trap CPU!! *)
  M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
  M.BCSCTL1^ := M.CALBC1_8MHZ^;
  M.DCOCTL^ := M.CALDCO_8MHZ^; (* Load 8MHz constants *)
  BIC(M.P1OUT^, {0}); (* Clear P1.0 *)
  BIS(M.P1DIR^, {0}); (* P1.0 output *)
  BIS(M.P1SEL^, {1, 2}); (* Use P1.1/P1.2 for USCI_A0 *)
  BIS(M.P1SEL2^, {1, 2}); (* Both P1SEL & P1SEL2 bits must be set for UCA functions *)
  BIS(M.UCA0CTL1^, M.UCSWRST); (* Set SW Reset *)
  M.UCA0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
  M.UCA0BR0^ := 52; (* 8MHz/52=153.8KHz *)
  M.UCA0BR1^ := 0;
  M.UCA0MCTL^ := M.UCBRF_1 + M.UCOS16; (* Set 1st stage modulator to 1, 16-times oversampling mode *)
  M.UCA0IRTCTL^ := M.UCIRTXPL2 + M.UCIRTXPL0 + M.UCIRTXCLK + M.UCIREN; (* Pulse length = 6 half clock cyc, enable BITCLK16, IrDA enc/dec *)
  BIC(M.UCA0CTL1^, M.UCSWRST);(* Resume operation *)

  TxByte := 0; (* TX data and index, 8-bit *)

  REPEAT i := 1000; REPEAT DEC(i) UNTIL i = 0; (* Small delay *)
    REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (* USCI_A0 TX buffer ready? *)
    M.UCA0TXBUF^ := TxByte; (* TX character *)

    SYSTEM.BIC_SR(M.GIE);
    BIS(M.IE2^, M.UCA0RXIE); (* Enable RX int *)
    SYSTEM.BIS_SR(M.CPUOFF +M. GIE);(* Enter LPM0 w/ interrupts *)

    RxData[TxByte] := RxByte; (* Store RXed character in RAM *)
    IF TxByte # RxByte THEN (* RX KO? *)
      BIS(M.P1OUT^, {0}); (* LED P1.0 on *)
      REPEAT UNTIL FALSE; (* Trap PC here *)
    END;
    INC(TxByte); (* Next character to TX *)
  UNTIL FALSE
END msp430g2xx3uscia0irda01.
