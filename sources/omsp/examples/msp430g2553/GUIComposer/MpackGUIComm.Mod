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
 * --/COPYRIGHT--*)
(*****************************************************************************
//         Generic GUI Demo using MSP430
//
// Texas Instruments, Inc.
// *******************************************************************************)

MODULE MpackGUIComm;
  IMPORT SYSTEM, MP := mpack, G := GUIMpack;

  VAR writer: MP.Writer;

  PROCEDURE sendBool*(cmd: ARRAY OF CHAR; val: BOOLEAN);
  BEGIN MP.start_map(writer^, 1); MP.write_str(writer^, cmd); MP.write_bool(writer^, val);
    MP.writer_flush_message(writer^)
  END sendBool;

  PROCEDURE sendUInt*(cmd: ARRAY OF CHAR; valh, vall: INTEGER);
  BEGIN MP.start_map(writer^, 1); MP.write_str(writer^, cmd); MP.write_uint(writer^, valh, vall);
    MP.writer_flush_message(writer^)
  END sendUInt;

  PROCEDURE sendInt*(cmd: ARRAY OF CHAR; valh, vall: INTEGER);
  BEGIN MP.start_map(writer^, 1); MP.write_str(writer^, cmd); MP.write_int(writer^, valh, vall);
    MP.writer_flush_message(writer^)
  END sendInt;

  PROCEDURE sendUInt8*(cmd: ARRAY OF CHAR; val: BYTE);
  BEGIN sendUInt(cmd, 0, val)
  END sendUInt8;

  PROCEDURE sendInt8*(cmd: ARRAY OF CHAR; val: INTEGER);
    VAR valh: INTEGER;
  BEGIN 
    IF val < 0 THEN BIS(TOSET(val), 0FF00H); valh := 0FFFFH
    ELSE AND(TOSET(val), 0FFH); valh := 0
    END; sendInt(cmd, valh, val)
  END sendInt8;

  PROCEDURE sendUInt16*(cmd: ARRAY OF CHAR; val: INTEGER);
  BEGIN sendUInt(cmd, 0, val)
  END sendUInt16;

  PROCEDURE sendInt16*(cmd: ARRAY OF CHAR; val: INTEGER);
    VAR valh: INTEGER;
  BEGIN IF val < 0 THEN valh := 0FFFFH ELSE valh := 0 END; sendInt(cmd, valh, val)
  END sendInt16;

  PROCEDURE sendUInt32*(cmd: ARRAY OF CHAR; valh, vall: INTEGER);
  BEGIN sendUInt(cmd, valh, vall)
  END sendUInt32;

  PROCEDURE sendInt32*(cmd: ARRAY OF CHAR; valh, vall: INTEGER);
  BEGIN sendInt(cmd, valh, vall)
  END sendInt32;

BEGIN writer := SYSTEM.VAL(MP.Writer, SYSTEM.ADR(G.writer))
END MpackGUIComm.

OMSPTool.DecObj MpackGUIComm.mpc
