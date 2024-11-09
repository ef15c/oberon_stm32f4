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
//  MSP430G2xx3 Demo - Timer_A, Ultra-Low Pwr UART 2400 Echo, 32kHz ACLK
//
//  Description: Use Timer_A CCR0 hardware output modes and SCCI data latch
//  to implement UART function @ 2400 baud. Software does not directly read and
//  write to RX and TX pins, instead proper use of output modes and SCCI data
//  latch are demonstrated. Use of these hardware features eliminates ISR
//  latency effects as hardware insures that output and input bit latching and
//  timing are perfectly synchronised with Timer_A regardless of other
//  software activity. In the Mainloop the UART function readies the UART to
//  receive one character and waits in LPM3 with all activity interrupt driven.
//  After a character has been received, the UART receive function forces exit
//  from LPM3 in the Mainloop which echo's back the received character.
//  ACLK = TACLK = LFXT1 = 32768Hz, MCLK = SMCLK = default DCO
//  //* An external watch crystal is required on XIN XOUT for ACLK *//	
//
//               MSP430G2xx3
//            -----------------
//        /|\|              XIN|-
//         | |                 | 32kHz
//         --|RST          XOUT|-
//           |                 |
//           |   CCI0B/TXD/P1.5|-------->
//           |                 | 2400 8N1
//           |   CCI0A/RXD/P1.1|<--------
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 02.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3tauart2400;
  IMPORT SYSTEM, M := msp430g2553;

  CONST RXD = {1} (* RXD on P1.1 *); TXD = {5} (* TXD on P1.5 *);

    (* Conditions for 2400 Baud SW UART, ACLK = 32768 *)
    Bitime_5 = 06H; (* ~ 0.5 bit length + small adjustment *)
    Bitime = 0EH; (* 427us bit length ~ 2341 baud *)

  VAR RXTXData: INTEGER; BitCnt: BYTE;

  (* Transmits Character from RXTXData Buffer *)
  PROCEDURE TX_Byte;
    BEGIN BitCnt := 10; (* Load Bit counter, 8data + ST/SP *)
    REPEAT M.TA0CCR0^ := M.TA0R^ UNTIL M.TA0CCR0^ = M.TA0R^; (* Prevent async capture *)
    INC(M.TA0CCR0^, Bitime); (* Some time till first bit *)
    INC(RXTXData, 100H); (* Add mark stop bit to RXTXData *)
    RLA(RXTXData, 1); (* Add space start bit *)
    M.TA0CCTL0^ :=  M.CCIS0 + M.OUTMOD0 + M.CCIE; (* TXD = mark = idle *)
    REPEAT UNTIL ~BIT(M.TA0CCTL0^, M.CCIE); (* Wait for TX completion *)
  END TX_Byte;

  (* UART to Receive Character into RXTXData Buffer *)
  PROCEDURE RX_Ready;
  BEGIN BitCnt := 8; (* Load Bit counter *)
    M.TA0CCTL0^ := M.SCS + M.OUTMOD0 + M.CM1 + M.CAP + M.CCIE; (* Sync, Neg Edge, Cap *)
  END RX_Ready;

  (* Timer A0 interrupt service routine *)
  PROCEDURE* (M.TIMER0_A0_VECTOR) Timer_A;
  BEGIN INC(M.TA0CCR0^, Bitime); (* Add Offset to CCR0 *)
    IF BIT(M.TA0CCTL0^, M.CCIS0) (* TX on CCI0B? *) THEN (* TX *)
      IF BitCnt = 0 THEN BIC(M.TA0CCTL0^, M.CCIE) (* All bits TXed, disable interrupt *)
      ELSE BIS(M.TA0CCTL0^, M.OUTMOD2); (* TX Space *)
        IF BIT(RXTXData, {0}) THEN BIC(M.TA0CCTL0^, M.OUTMOD2) END; (* TX Mark *)
        CLRC; RRC(RXTXData); DEC(BitCnt)
      END
    ELSE (* RX *)
      IF BIT(M.TA0CCTL0^, M.CAP) THEN (* Capture mode = start bit edge *)
        BIC(M.TA0CCTL0^, M.CAP); (* Switch from capture to compare mode *)
        INC(M.TA0CCR0^, Bitime_5)
      ELSE RRA(RXTXData, 1);
        IF BIT(M.TA0CCTL0^, M.SCCI) THEN BIS(RXTXData, {7}) END; (* Get bit waiting in receive latch *)
        DEC(BitCnt);
        IF BitCnt = 0 THEN (* All bits RXed? *)
  (*>>>>>>>>>> Decode of Received Byte Here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*)
          BIC(M.TA0CCTL0^, M.CCIE); (* All bits RXed, disable interrupt *)
          SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Clear LPM3 bits from 0(SP) *)
        END
  (*>>>>>>>>>> Decode of Received Byte Here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*)
      END
    END
  END Timer_A;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  M.BCSCTL3^ := M.XCAP_2;
  M.TA0CCTL0^ := M.OUT; (* TXD Idle as Mark *)
  M.TA0CTL^ := M.TASSEL_1 + M.MC_2; (* ACLK, continuous mode *)
  M.P1SEL^ := TXD + RXD;
  M.P1DIR^ := TXD;

  (* Mainloop *)
  REPEAT RX_Ready; (* UART ready to RX one Byte *)
    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3 w/ interr until char RXed *)
    TX_Byte (* TX Back RXed Byte Received *)
  UNTIL FALSE
END msp430g2xx3tauart2400.


