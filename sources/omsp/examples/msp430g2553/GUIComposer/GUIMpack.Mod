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
//
// Texas Instruments, Inc.*)

MODULE GUIMpack;
  IMPORT SYSTEM, MP := mpack, MC := MpackCallbacks, HG := HALGUImsp430g255x;

  CONST MAX_STR_LEN = 64; (*! \Brief Maximum string for RX*)

  TYPE
    (*! \brief Callback for RX Commands (called when command is received from GUI) *)
    RxCmdCallback* = PROCEDURE(tag: MP.Tag; reader: MP.Reader);

  VAR data: ARRAY 50 OF CHAR;
    writer*: MP.WriterDesc;

    rxInProgress: BOOLEAN;
    charCnt: INTEGER;
    rxString: ARRAY MAX_STR_LEN OF CHAR;  (* String to receive data *)

  PROCEDURE strncmp(l, r: ARRAY OF CHAR*; len: INTEGER*): INTEGER;
    VAR i: INTEGER*;
  BEGIN i := 0; DEC(len);
    WHILE (i < len) & (i < LEN(l)) & (i < LEN(r)) & (l[i] = r[i]) DO INC(i) END

    RETURN 0+ORD(l[i]) - ORD(r[i])
  END strncmp;

  (*! \brief Parses a string looking for command
     !
     ! \return true to wake-up MCU when a command is received, false to stay in LPM*)
  PROCEDURE ParseString(): BOOLEAN;
    VAR reader!: MP.ReaderDesc; tag: MP.Tag;
    i, l, containerSize: INTEGER; buffer: ARRAY 8 OF CHAR;
  BEGIN MP.reader_init_data(reader, rxString);
    MP.read_tag(reader, tag); (* read the map tag *)

    IF MP.tag_type(tag) = MP.type_map THEN
      (* Map tag count specifies the number of key:value pairs, so to read all
          members, we must double the count *)
      containerSize := MP.tag_map_count(tag) * 2;
      FOR i := 0 TO containerSize - 1 DO
        MP.read_tag(reader, tag); (* read the key. should be type string *)
        IF MP.tag_type(tag) = MP.type_str THEN (* read the actual string value *)
          l := MP.tag_str_length(tag); MP.read_bytes(reader, SYSTEM.VAL(PBYTE, SYSTEM.ADR(buffer)), l);
          MP.read_tag(reader, tag);
         (* check if it is a valid command *)
          IF strncmp(buffer, "bEnable", l) = 0 THEN MC.Callback_boolEnable(tag, reader)
          ELSIF strncmp(buffer, "u16Data", l) = 0 THEN MC.Callback_QMathData(tag, reader)
          END
        END
      END
    END

    RETURN MP.reader_destroy(reader) = MP.ok
  END ParseString;

  PROCEDURE flush_callback(VAR writer: MP.Writer; buffer: PBYTE; count: INTEGER);
  BEGIN data[count] := 0AX; (* Set the delimiter at the end *)
     HG.TransmitBufferBlocking(data, count + 1);
  END flush_callback;

  (*! \brief Callback function for GUI HAL. Called when byte is received.
   *!
   *! \param[in] data is the byte received from GUI Comm interface.
   *!
   *! \return true to wake-up MCU, false to stay in LPM*)
  PROCEDURE {4..14} RxByteCallback(data: CHAR): BOOLEAN;
    VAR ret: BOOLEAN;
  BEGIN ret := FALSE;
    IF ~rxInProgress THEN
      IF data # 0AX THEN rxInProgress := TRUE; charCnt := 0; rxString[charCnt] := data END
    ELSE (* in progress *)
      INC(charCnt);
      IF data # 0AX THEN
        IF charCnt >= MAX_STR_LEN THEN rxInProgress := FALSE ELSE rxString[charCnt] := data END
      ELSE (* String receive complete *) rxInProgress := FALSE; rxString[charCnt] := 0X;
        IF ParseString() THEN ret := TRUE; (* wake-up MCU *) END
      END
    END

    RETURN ret
  END RxByteCallback;

BEGIN rxString := ""; rxInProgress := FALSE; charCnt := 0;
  HG.SetCallback(RxByteCallback);
  MP.writer_init(writer, data);
  MP.writer_set_flush(writer, flush_callback);
END GUIMpack.
