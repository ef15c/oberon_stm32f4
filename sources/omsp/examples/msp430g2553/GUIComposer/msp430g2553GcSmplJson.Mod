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
  IMPORT SYSTEM, M := msp430g2553, MP := MultiPrecisionArith, HALSYSmsp430g255x, I := HALIOmsp430g255x,
    T := HALTIMmsp430g255x, GUIJson, JGC := JSONGUIComm, JC := JSONCallbacks;

  (* Q8 is used in this demo because the variable qCounter ranges 0.0-100.0 *)

  VAR
    (* Global variables used to track the of state of GUI and counter values *)
    bUpdateGUI: BOOLEAN;
    u8Counter: BYTE; (* Counter8 will be updated on SW1 press in increments of 50 *)
    u16Counter: INTEGER; (* Counter16 will be updated on button press in increments of 5000 *)
    u32Counterl, u32Counterh*: INTEGER; (* Counter32 will be updated on timer in increments of 10000 *)
    qCounter: INTEGER; (* QMath counter updated on timer based on boolean in increments of qIncrement *)

  (*! \brief Function called by HAL when there is a periodic timer interrupt
     !
     ! \return none*)
  PROCEDURE {4..6, 15} TimerCallback;
  BEGIN
    (* Update 32-bit counter *)
    MP.AddLongInt(u32Counterh, u32Counterl, 10000);
    bUpdateGUI := TRUE;
    IF JC.bEnableSwitch THEN
        INC(qCounter, JC.qIncrement);
        IF qCounter > 6400H (*Q.atoQ("100.0")*) THEN qCounter := 0 END
    END
  END TimerCallback;

  (*! \brief Function called by HAL when SW1 is pressed
     !
     ! \return none*)
  PROCEDURE ButtonCallbackSW1;
  BEGIN INC(u8Counter, 50)
  END ButtonCallbackSW1;

  (*! \brief Function called by HAL when SW2 is pressed
     !
     ! \return none*)
  PROCEDURE ButtonCallbackSW2;
  BEGIN INC(u16Counter, 5000)
  END ButtonCallbackSW2;

BEGIN
  bUpdateGUI := FALSE;
  u8Counter := 50; u16Counter := 5000; u32Counterl := 10000; u32Counterh := 0;
  qCounter := 0080H; (*Q.atoQ("0.5")*)

  T.SetCallback(TimerCallback); I.SetCallback(ButtonCallbackSW1, ButtonCallbackSW2);

  (* Configure SW1 and SW2 for interrupts (pins set as input with pull-up during GPIO initialization) *)
   I.InitButtons;

   (* Send default value of variables *)
   JGC.sendUInt8("c1", u8Counter);
   JGC.sendUInt16("c2", u16Counter);
   JGC.sendInt32("c3", u32Counterh, u32Counterl);
   JGC.sendInt16("c4", qCounter);
   JGC.sendInt16("u16Data", JC.qIncrement);
   JGC.sendBool("bEnable", JC.bEnableSwitch);

  SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3 w/interrupt *)

  REPEAT
    WHILE bUpdateGUI DO
      JGC.sendUInt8("c1", u8Counter);
      JGC.sendUInt16("c2", u16Counter);
      JGC.sendInt32("c3", u32Counterh, u32Counterl);
      IF JC.bEnableSwitch THEN JGC.sendInt16("c4", qCounter) END;
      bUpdateGUI := FALSE
    END;

    SYSTEM.BIC_SR(M.GIE);
    IF ~bUpdateGUI THEN
      SYSTEM.BIS_SR(M.LPM0_bits + M.GIE); (* Enter LPM0 w/interrupt *)
      NOP (* For debug *)
    END
  UNTIL FALSE
END msp430g2553GcSmplJson.

gc_simple_json example

OMSPP.Compile msp430g2553.Mod MultiPrecisionArith.Mod HALSYSmsp430g255x.Mod HALIOmsp430g255x.Mod HALTIMmsp430g255x.Mod jsmn.Mod Arith.Mod
 JSONCallbacks.Mod HALGUImsp430g255x.Mod GUIJson.Mod JSONGUIComm.Mod msp430g2553GcSmplJson.Mod ~

OMSPL.Link 32 4000H 200H msp430g2553GcSmplJson ~
  linking msp430g2553 MultiPrecisionArith HALSYSmsp430g255x HALIOmsp430g255x HALTIMmsp430g255x jsmn Arith JSONCallbacks HALGUImsp430g255x
  GUIJson JSONGUIComm msp430g2553GcSmplJson, flash 4698, data  196, stack  316 bytes
