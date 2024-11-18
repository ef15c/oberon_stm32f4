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
//      HAL functions to initialize the system
//
// Texas Instruments, Inc.
// ******************************************************************************)

MODULE HALSYSmsp430g255x;
  IMPORT M := msp430g2553;

  (**** Local Functions *********************************************************/
  ! \brief Initializes the system clock
  !
  ! \return none*)
  PROCEDURE HAL_System_Clock_Init;
  BEGIN REPEAT UNTIL M.CALBC1_8MHZ^ # {0..7}; (* If calibration constant erased do not load, trap CPU!! *)
    M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
    M.BCSCTL1^ := M.CALBC1_8MHZ^; (* Set range *)
    M.DCOCTL^ := M.CALDCO_8MHZ^; (* Set DCO step + modulation *)
    BIS(M.BCSCTL3^, M.LFXT1S_2); (* LFXT1 = VLO *)
    BIC(M.IFG1^, M.OFIFG) (* Clear OSCFault flag *)
  END HAL_System_Clock_Init;

(* ********************* System ************************************************
! \brief Initializes I/Os used by the system.
!           Initialization is done to achieve lowest power consumption.
!*)
BEGIN
   M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* stop watchdog timer *)
  HAL_System_Clock_Init
END HALSYSmsp430g255x.
