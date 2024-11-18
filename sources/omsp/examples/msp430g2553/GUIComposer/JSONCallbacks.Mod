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
//         callbacks_JSON.c
//
// Application level callbacks using JSON
// Texas Instruments, Inc.*)

MODULE JSONCallbacks;
  IMPORT A := Arith;

  VAR bEnableSwitch*: BOOLEAN; (* Switch enables updating QMath *)
    qIncrement*: INTEGER;

  PROCEDURE getBoolFromString(string: ARRAY OF CHAR*; pos: INTEGER*): BOOLEAN;
    CONST true = "true";
    VAR res: BOOLEAN*; i: INTEGER*;
  BEGIN res := TRUE; i := 0;
    WHILE res & (true[i] # 0X) DO IF true[i] # string[pos + i] THEN res := FALSE END; INC(i) END

    RETURN res
  END getBoolFromString;

  (* ***** Application Callback Functions to Process data ***** *)

  PROCEDURE Callback_boolEnable*(string: ARRAY OF CHAR; pos: INTEGER);
  BEGIN (* Example to receive a boolean *)
    bEnableSwitch :=  getBoolFromString(string, pos)
  END Callback_boolEnable;

  PROCEDURE Callback_QMathData*(string: ARRAY OF CHAR; pos: INTEGER);
  BEGIN qIncrement := A.atoiP(string, pos)
  END Callback_QMathData;

BEGIN bEnableSwitch := TRUE; qIncrement := 0080H; (* Q.atoQ("0.5")*)
END JSONCallbacks.
