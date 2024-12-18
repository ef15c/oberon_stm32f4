(* --COPYRIGHT--,BSD
 * Copyright (c) 2019, Texas Instruments Incorporated
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
 * --/COPYRIGHT--*/
//*****************************************************************************
//        MSP430 HAL
//
// Hardware Abstraction Layer for MSP430
//
// Texas Instruments, Inc.*)

MODULE HALGUImsp430g255x;
  IMPORT SYSTEM, HALSYSmsp430g255x, HALIOmsp430g255x, M := msp430g2553;

  TYPE Callback* = PROCEDURE {4..15} (data: CHAR): BOOLEAN;

  VAR cbk: Callback;

  (*! \brief Transmits a character to the GUI in blocking mode.
  !
  ! \param[in] character is the character being transmitted to GUI.
  !
  ! \return none*)
  PROCEDURE TransmitCharBlocking*(character: CHAR*);
  BEGIN
    (* Transmit Character *)
    REPEAT UNTIL ~BIT(M.UCA0STAT^, M.UCBUSY);
    REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG);
    M.UCA0TXBUF^ := ORD(character);
    REPEAT UNTIL ~BIT(M.UCA0STAT^, M.UCBUSY)
  END TransmitCharBlocking;

  (*! \brief Transmits a string to GUI.
  !
  ! \param[in] str is the string to be sent.
  !
  ! \return none*)
  PROCEDURE TransmitStringBlocking*(str: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE str[i] # 0X DO TransmitCharBlocking(str[i]); INC(i) END
  END TransmitStringBlocking;


  (*! \brief Transmits a buffer to GUI.
  !
  ! \param[in] str is the string to be sent.
  !
  ! \return none*)
  PROCEDURE TransmitBufferBlocking*(str: ARRAY OF CHAR; count: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE i < count DO TransmitCharBlocking(str[i]); INC(i) END
  END TransmitBufferBlocking;


  (* USCI interrupt service routine *)
  PROCEDURE* (M.USCIAB0RX_VECTOR) {15} USCI_A0_ISR;
  BEGIN IF cbk(CHR(M.UCA0RXBUF^)) THEN SYSTEM.BIC_SR_ON_EXIT(M.LPM4_bits) (* Exit LPM *) END
  END USCI_A0_ISR;

  PROCEDURE SetCallback*(c: Callback*);
  BEGIN cbk := c
  END SetCallback;


(* ********************* GUI Communication *************************************
! \brief Initializes the communication interface for GUI.
!
!
! \return none*)
BEGIN
  (* Configure UART for MSP430G255x *)
  BIS(M.UCA0CTL1^, M.UCSWRST);
  BIS(M.UCA0CTL1^, M.UCSSEL1);

  (* Baud Rate calculation
     8E6/(16*9600) = 52.0833
     Fractional portion = 0.33
     User's Guide Table 17-4: UCBRSx = 0
     UCBRFx = 1 *)
  M.UCA0BR0^ := 52;
  M.UCA0BR1^ := 0;
  M.UCA0MCTL^ := M.UCOS16 + M.UCBRF_1;

  BIC(M.UCA0CTL1^, M.UCSWRST); (* Initialize USCI *)
  BIS(M.IE2^, M.UCA0RXIE)
END HALGUImsp430g255x.
