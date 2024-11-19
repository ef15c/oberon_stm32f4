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
//   HAL IO functions
//
// Texas Instruments, Inc.
// *****************************************************************************)

MODULE HALIOmsp430g255x;
  IMPORT SYSTEM, M := msp430g2553, C := HALCallbacks;

  TYPE ButtonCallback* = PROCEDURE;

  (*! \brief Initializes inputs used for push-buttons
     !           Pins are initialized with pull-ups and interrupts are enabled.
     !
     !
     ! \return none*)
  PROCEDURE InitButtons*;
  BEGIN (* Configure SW1 and SW2 for interrupts (pins set as input-pullup during GPIO initialization) *)
    M.P1IES^ := {3}; (* Hi/Low edge *)
    M.P1IFG^ := {}; (* Clear flags *)
    M.P1IE^ := {3} (* interrupt enabled *)
  END InitButtons;

  (* Port interrupt service routine *)
  PROCEDURE* (M.PORT1_VECTOR) Port_1;
  BEGIN  
    IF BIT(M.P1IFG^, {3}) THEN
      C.ButtonCallbackSW1; (* Only has 1 SW, updates both variables *)
      C.ButtonCallbackSW2;
      BIC(M.P1IFG^, {3}) (* Clear IFG *)
    END;
    SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Exit LPM3 *)
  END Port_1;

(********************* I/O ***************************************************
  ! \brief Initializes I/Os used by the system.
  !           Initialization is done to achieve lowest power consumption.
  !
  !
  ! \return none*)

BEGIN
  (* Port output low to save power consumption
    P1.0 = LED1, Output Low
    P1.1 = UART RX
    P1.2 = UART TX
    P1.3 = SW1, Input pull-up
    P1.4 = Unused, Output Low
    P1.5 = Unused, Output Low
    P1.6 = LED6, Output Low
    P1.7 = Unused, Output Low*)
    M.P1OUT^ := {3};
    M.P1DIR^ := {0, 4..7};
    BIS(M.P1REN^, {3});
    BIS(M.P1SEL^, {1, 2});
    BIS(M.P1SEL2^, {1, 2});
    
  (* P2.0 = Unused, Output Low
      P2.1 = Unused, Output Low
      P2.2 = Unused, Output Low
      P2.3 = Unused, Output Low
      P2.4 = Unused, Output Low
      P2.5 = Unused, Output Low
      P2.6 = Unused, Output Low
      P2.7 = Unused, Output Low*)
    M.P2SEL^ := {};
    M.P2OUT^ := {};
    M.P2DIR^ := {0..7};
    
  (* P3.0 = Unused, Output Low
      P3.1 = Unused, Output Low
      P3.2 = Unused, Output Low
      P3.3 = Unused, Output Low
      P3.4 = Unused, Output Low
      P3.5 = Unused, Output Low
      P3.6 = Unused, Output Low
      P3.7 = Unused, Output Low*)
  M.P3OUT^ := {};
  M.P3DIR^ := {0..7}
END HALIOmsp430g255x.
