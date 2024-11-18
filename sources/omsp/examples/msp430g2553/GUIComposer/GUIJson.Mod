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
//         GUI Interface
//
// API to send and receive data from GUI using GUI Composer
// Texas Instruments, Inc.
// ******************************************************************************)

MODULE GUIJson;
  IMPORT jsmn, JC := JSONCallbacks;

  CONST (*//! \brief Maximum string for RX*)
    MAX_STR_LEN* =  64;
    CMD_NAME_SIZE* = 16;

  TYPE 
    (*//! \brief Callback for RX Commands (called when command is received from GUI)*)
    RxCmdCallback* = PROCEDURE(cmd, param: ARRAY OF CHAR);

  VAR rxCmdCB: RxCmdCallback;
    txString: ARRAY MAX_STR_LEN OF CHAR;  (* String to transmit or receive data *)
    p: jsmn.Parser; (* parses JSON data *)
    t: ARRAY 10 OF jsmn.Tok; (* We expect no more than 10 tokens *)

  PROCEDURE Init*(rxcmdcb: RxCmdCallback);
  BEGIN rxCmdCB := rxcmdcb
  END Init;


  (*! \brief Compare JSON keys
     !
     ! \param[in] json is the JSON string.
     ! \param[in] tok is the JSON token.
     ! \param[in] s is the string to check for equality.
     !
     ! \return 0 if string found. -1 if not.*)
  PROCEDURE jsoneq(json: ARRAY OF CHAR*; tok: jsmn.Tok*; s: ARRAY OF CHAR*): BOOLEAN;
    VAR eq: BOOLEAN*; i, nbc: INTEGER*;
  BEGIN eq := FALSE;
    IF tok.type = jsmn.STRING THEN i := 0; nbc := tok.end - tok.start;
      WHILE (s[i] # 0X) & (i < nbc) & (s[i] = json[tok.start + i]) DO INC(i) END;
      IF (i = nbc) & (s[i] = 0X) THEN eq := TRUE END
    END;

    RETURN eq
  END jsoneq;

  (*! \brief Parses a string looking for JSON objects
     !
     ! \return true to wake-up MCU when a command is received, false to stay in LPM *)
  PROCEDURE ParseString*(rxString: ARRAY OF CHAR): BOOLEAN;
    VAR i, r: INTEGER; ret: BOOLEAN;
  BEGIN ret := TRUE;
    jsmn.init(p);

    r := jsmn.parse(p, rxString, t, FALSE);

    (* Loop over keys of JSON object *)
    i := 1;
    WHILE i < r DO
      IF jsoneq(rxString, t[i], "bEnable") THEN INC(i); JC.Callback_boolEnable(rxString, t[i].start)
      ELSIF jsoneq(rxString, t[i], "u16Data") THEN INC(i);JC.Callback_QMathData(rxString, t[i].start)
      ELSE ret := FALSE
      END; INC(i)
    END

    RETURN ret
  END ParseString;

END GUIJson.
