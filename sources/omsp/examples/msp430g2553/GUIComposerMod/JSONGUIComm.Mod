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
//         GUI Communication Layer
//
// API to communicate with GUI using JSON protocol
// Texas Instruments, Inc.**)

MODULE JSONGUIComm;
  IMPORT MP := MultiPrecisionArith, HG := HALGUImsp430g255x;

  CONST cmdTemplate = "{" + 22X + 22X + ":}" + 0AX;
    (*These values are used to concatenate the command and data to the command template
       when using the GUIComm_send functions*)
    CMD_INDEX = 1;
    DATA_INDEX = 3;
     CMD_TEMPLATE_LENGTH = 6;
    BASE = 10;

  VAR cATXString: ARRAY 20 OF CHAR;

  (*! \brief Converts a number into a string
     !
     ! \return none*)
  PROCEDURE itoa(valueh, valuel: INTEGER; VAR result: ARRAY OF CHAR);
    VAR b, e, tmp_valuel, tmp_valueh, tmp_rmdl, tmp_rmdh: INTEGER; tmp_char: CHAR;
  BEGIN b := 0; e := 0;
    tmp_valueh := valueh; tmp_valuel := valuel; MP.AbsLong(tmp_valueh, tmp_valuel);
    REPEAT tmp_rmdh := 0; tmp_rmdl := BASE; MP.DivLongLong(tmp_valueh, tmp_valuel, tmp_rmdh, tmp_rmdl);
      result[e] := CHR(ORD("0") + tmp_rmdl); INC(e);
    UNTIL (tmp_valueh = 0) & (tmp_valuel = 0);

    (* Apply negative sign *)
    IF valueh < 0 THEN  result[e] := "-"; INC(e) END;
    result[e] := 0X; DEC(e);
    WHILE b < e DO
      tmp_char := result[e];
      result[e] := result[b]; DEC(e);
      result[b] := tmp_char; INC(b)
    END
  END itoa;

  PROCEDURE sendInt*(cmd: ARRAY OF CHAR; valh, vall: INTEGER);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO CMD_TEMPLATE_LENGTH - 1 DO
      HG.TransmitCharBlocking(cmdTemplate[i]);
      IF i = CMD_INDEX THEN HG.TransmitStringBlocking(cmd)
      ELSIF i = DATA_INDEX THEN itoa(valh, vall, cATXString); HG.TransmitStringBlocking(cATXString)
      END
    END
  END sendInt;

  PROCEDURE sendUInt8*(cmd: ARRAY OF CHAR; val: BYTE);
    VAR vall, valh: INTEGER;
  BEGIN valh := 0; vall := val;
    sendInt(cmd, valh, vall)
  END sendUInt8;

  PROCEDURE sendInt16*(cmd: ARRAY OF CHAR; val: INTEGER);
    VAR vall, valh: INTEGER;
  BEGIN MP.SetLongInt(valh, vall, val);
    sendInt(cmd, valh, vall)
  END sendInt16;

  PROCEDURE sendInt8*(cmd: ARRAY OF CHAR; val: INTEGER);
  BEGIN IF val >= 80H THEN DEC(val, 100H) END;
    sendInt16(cmd, val)
  END sendInt8;

  PROCEDURE sendUInt16*(cmd: ARRAY OF CHAR; val: INTEGER);
    VAR vall, valh: INTEGER;
  BEGIN valh := 0; vall := val; sendInt(cmd, valh, vall)
  END sendUInt16;

  PROCEDURE sendInt32*(cmd: ARRAY OF CHAR; valh, vall: INTEGER);
  BEGIN sendInt(cmd, valh, vall)
  END sendInt32;

  PROCEDURE sendBool*(cmd: ARRAY OF CHAR; val: BOOLEAN);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(cmdTemplate) - 1 DO
      HG.TransmitCharBlocking(cmdTemplate[i]);
      IF i = CMD_INDEX THEN HG.TransmitStringBlocking(cmd)
      ELSIF i = DATA_INDEX THEN
        IF val THEN HG.TransmitStringBlocking("true") ELSE HG.TransmitStringBlocking("false") END
      END
    END
  END sendBool;

END JSONGUIComm.
