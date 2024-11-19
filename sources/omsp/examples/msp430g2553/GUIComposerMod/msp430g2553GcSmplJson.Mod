(* --COPYRIGHT--,BSD
 * Copyright (c) 2020, Texas Instruments Incorporated
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
//         GUI Composer Simple JSON Demo using MSP430
//
// Texas Instruments, Inc.
Oberon version by C. Schoffit 04.11.24
// ******************************************************************************)

MODULE msp430g2553GcSmplJson;
  IMPORT SYSTEM, M := msp430g2553, HALSYSmsp430g255x, HC := HALCallbacks, HI := HALIOmsp430g255x, HALTIMmsp430g255x, GUI := GUIJson,
    JGC := JSONGUIComm, JC := JSONCallbacks;

  (* Q8 is used in this demo because the variable qCounter ranges 0.0-100.0 *)

BEGIN
  (* Configure SW1 and SW2 for interrupts (pins set as input with pull-up during GPIO initialization) *)
   HI.InitButtons;

   (* Send default value of variables *)
   JGC.sendUInt8("c1", HC.u8Counter);
   JGC.sendUInt16("c2", HC.u16Counter);
   JGC.sendInt32("c3", HC.u32Counterh, HC.u32Counterl);
   JGC.sendInt16("c4", HC.qCounter);
   JGC.sendInt16("u16Data", JC.qIncrement);
   JGC.sendBool("bEnable", JC.bEnableSwitch);

  SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3 w/interrupt *)

  REPEAT
    WHILE HC.bUpdateGUI DO
      JGC.sendUInt8("c1", HC.u8Counter);
      JGC.sendUInt16("c2", HC.u16Counter);
      JGC.sendInt32("c3", HC.u32Counterh, HC.u32Counterl);
      IF JC.bEnableSwitch THEN JGC.sendInt16("c4", HC.qCounter) END;
      HC.GUIUpdated
    END;

    SYSTEM.BIC_SR(M.GIE);
    IF ~HC.bUpdateGUI THEN
      SYSTEM.BIS_SR(M.LPM0_bits + M.GIE); (* Enter LPM0 w/interrupt *)
      NOP (* For debug *)
    END
  UNTIL FALSE
END msp430g2553GcSmplJson.
