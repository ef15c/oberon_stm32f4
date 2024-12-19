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
  BEGIN IF val < 0 THEN valh := 0FFFFH ELSE valh := 0 END; sendUInt(cmd, valh, val)
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
decode MpackGUIComm.mpc
MpackGUIComm 3ACE6C11 Flash   426
imports:
	mpack 4B28E872
	GUIMpack 61C01626
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 01A2 c 0000 c 0048 c 0094 c 00E0 c 00F8 c 0130 c 0146 c 0172 c 018A
fixup procedures chains
 0184     0	 0048
 019C     0	 0094
 00CC     1	 0015
 0080     1	 0014
 00DA     1	 0013
 0034     1	 0011
 00B6     1	 0010
 00A0     1	 000F
fixup handlers chains
fixup data chains
 01A6     0	 0000
 01A4     2	 0001
fixup constants chains
 00D4     1	 0002
fixup types chains
entry =  01A2
code   426
 0000	     4214	MOV &0,R4
 0002	     0000
 0004	     4035	MOV #0,R5
 0006	     0000
 0008	     4316	MOV #1,R6
 000A	     12B0	CALL #0
 000C	     0000
 000E	     421F	MOV &2,R15
 0010	     0002
 0012	     1230	PUSH #6
 0014	     0006
 0016	     120F	PUSH R15
 0018	     1211	PUSH 12(SP)
 001A	     000C
 001C	     1211	PUSH 12(SP)
 001E	     000C
 0020	     12B0	CALL #0
 0022	     0000
 0024	     5231	ADD #8,SP
 0026	     4214	MOV &16,R4
 0028	     0010
 002A	     4035	MOV #20,R5
 002C	     0014
 002E	     4156	MOV.B 2(SP),R6
 0030	     0002
 0032	     12B0	CALL #0
 0034	     0000
 0036	     421F	MOV &40,R15
 0038	     0028
 003A	     1230	PUSH #44
 003C	     002C
 003E	     120F	PUSH R15
 0040	     12B0	CALL #0
 0042	     0000
 0044	     5221	ADD #4,SP
 0046	     4130	RET
 0048	     4214	MOV &56,R4
 004A	     0038
 004C	     4035	MOV #60,R5
 004E	     003C
 0050	     4316	MOV #1,R6
 0052	     12B0	CALL #12
 0054	     000C
 0056	     421F	MOV &74,R15
 0058	     004A
 005A	     1230	PUSH #78
 005C	     004E
 005E	     120F	PUSH R15
 0060	     1211	PUSH 14(SP)
 0062	     000E
 0064	     1211	PUSH 14(SP)
 0066	     000E
 0068	     12B0	CALL #34
 006A	     0022
 006C	     5231	ADD #8,SP
 006E	     4214	MOV &88,R4
 0070	     0058
 0072	     4035	MOV #92,R5
 0074	     005C
 0076	     4116	MOV 4(SP),R6
 0078	     0004
 007A	     4117	MOV 2(SP),R7
 007C	     0002
 007E	     12B0	CALL #0
 0080	     0000
 0082	     421F	MOV &112,R15
 0084	     0070
 0086	     1230	PUSH #116
 0088	     0074
 008A	     120F	PUSH R15
 008C	     12B0	CALL #66
 008E	     0042
 0090	     5221	ADD #4,SP
 0092	     4130	RET
 0094	     4214	MOV &132,R4
 0096	     0084
 0098	     4035	MOV #136,R5
 009A	     0088
 009C	     4316	MOV #1,R6
 009E	     12B0	CALL #84
 00A0	     0054
 00A2	     421F	MOV &150,R15
 00A4	     0096
 00A6	     1230	PUSH #154
 00A8	     009A
 00AA	     120F	PUSH R15
 00AC	     1211	PUSH 14(SP)
 00AE	     000E
 00B0	     1211	PUSH 14(SP)
 00B2	     000E
 00B4	     12B0	CALL #106
 00B6	     006A
 00B8	     5231	ADD #8,SP
 00BA	     4214	MOV &164,R4
 00BC	     00A4
 00BE	     4035	MOV #168,R5
 00C0	     00A8
 00C2	     4116	MOV 4(SP),R6
 00C4	     0004
 00C6	     4117	MOV 2(SP),R7
 00C8	     0002
 00CA	     12B0	CALL #0
 00CC	     0000
 00CE	     421F	MOV &188,R15
 00D0	     00BC
 00D2	     1230	PUSH #192
 00D4	     00C0
 00D6	     120F	PUSH R15
 00D8	     12B0	CALL #142
 00DA	     008E
 00DC	     5221	ADD #4,SP
 00DE	     4130	RET
 00E0	     1211	PUSH 8(SP)
 00E2	     0008
 00E4	     1211	PUSH 8(SP)
 00E6	     0008
 00E8	     1203	PUSH #0
 00EA	     415E	MOV.B 8(SP),R14
 00EC	     0008
 00EE	     120E	PUSH R14
 00F0	     12B0	CALL #0
 00F2	     0000
 00F4	     5231	ADD #8,SP
 00F6	     4130	RET
 00F8	     8321	SUB #2,SP
 00FA	     9381	CMP #0,4(SP)
 00FC	     0004
 00FE	     3406	JGE $+14, goes to  010C
 0100	     D0B1	BIS #-256,4(SP)
 0102	     FF00
 0104	     0004
 0106	     43B1	MOV #-1,0(SP)
 0108	     0000
 010A	     3C05	JMP $+12, goes to  0116
 010C	     F0B1	AND #255,4(SP)
 010E	     00FF
 0110	     0004
 0112	     4381	MOV #0,0(SP)
 0114	     0000
 0116	     1211	PUSH 10(SP)
 0118	     000A
 011A	     1211	PUSH 10(SP)
 011C	     000A
 011E	     1211	PUSH 6(SP)
 0120	     0006
 0122	     1211	PUSH 12(SP)
 0124	     000C
 0126	     12B0	CALL #0
 0128	     0000
 012A	     5231	ADD #8,SP
 012C	     5321	ADD #2,SP
 012E	     4130	RET
 0130	     1211	PUSH 8(SP)
 0132	     0008
 0134	     1211	PUSH 8(SP)
 0136	     0008
 0138	     1203	PUSH #0
 013A	     1211	PUSH 10(SP)
 013C	     000A
 013E	     12B0	CALL #242
 0140	     00F2
 0142	     5231	ADD #8,SP
 0144	     4130	RET
 0146	     8321	SUB #2,SP
 0148	     9381	CMP #0,4(SP)
 014A	     0004
 014C	     3403	JGE $+8, goes to  0154
 014E	     43B1	MOV #-1,0(SP)
 0150	     0000
 0152	     3C02	JMP $+6, goes to  0158
 0154	     4381	MOV #0,0(SP)
 0156	     0000
 0158	     1211	PUSH 10(SP)
 015A	     000A
 015C	     1211	PUSH 10(SP)
 015E	     000A
 0160	     1211	PUSH 6(SP)
 0162	     0006
 0164	     1211	PUSH 12(SP)
 0166	     000C
 0168	     12B0	CALL #320
 016A	     0140
 016C	     5231	ADD #8,SP
 016E	     5321	ADD #2,SP
 0170	     4130	RET
 0172	     1211	PUSH 10(SP)
 0174	     000A
 0176	     1211	PUSH 10(SP)
 0178	     000A
 017A	     1211	PUSH 10(SP)
 017C	     000A
 017E	     1211	PUSH 10(SP)
 0180	     000A
 0182	     12B0	CALL #362
 0184	     016A
 0186	     5231	ADD #8,SP
 0188	     4130	RET
 018A	     1211	PUSH 10(SP)
 018C	     000A
 018E	     1211	PUSH 10(SP)
 0190	     000A
 0192	     1211	PUSH 10(SP)
 0194	     000A
 0196	     1211	PUSH 10(SP)
 0198	     000A
 019A	     12B0	CALL #296
 019C	     0128
 019E	     5231	ADD #8,SP
 01A0	     4130	RET
 01A2	     40B2	MOV #0,&208
 01A4	     0000
 01A6	     00D0
 01A8	     4130	RET
