MODULE minihdlc;
  CONST MAX_FRAME_LENGTH = 64;
    OUT_OF_FRAME = 0; IN_FRAME = 1;

    (* HDLC Asynchronous framing *)
    FRAME_BOUNDARY_OCTET = 7EH; (*The frame boundary octet is 01111110, (7E in hexadecimal notation)*)
    CONTROL_ESCAPE_OCTET= 7DH; (*A "control escape octet", has the bit sequence '01111101', (7D hexadecimal)*)

    (*If either of these two octets appears in the transmitted data, an escape octet is sent,
     * followed by the original data octet with bit 5 inverted*)
    INVERT_OCTET = 20H;

  TYPE Instance* = POINTER TO InstanceDesc;
    SendcharProc* = PROCEDURE(me: Instance; data: BYTE);
    FrameHandlerProc* = PROCEDURE(me: Instance; frame_buffer: ARRAY OF BYTE; frame_langth: INTEGER);
    InstanceDesc* = RECORD
      sendchar_function: SendcharProc; frame_handler: FrameHandlerProc;
      escape_character: BOOLEAN; frame_position: INTEGER;
      receive_frame_buffer, frame_buffer*: ARRAY MAX_FRAME_LENGTH + 1 OF BYTE;
      frame_buffer_size*, state, context: INTEGER;
    END;

  PROCEDURE init*(me: Instance*; sendchar_function: SendcharProc*; frame_hander_function: FrameHandlerProc*; ctx: INTEGER*);
  BEGIN me.sendchar_function := sendchar_function; me.frame_handler := frame_hander_function; me.frame_position := 0;
    me.escape_character := FALSE; me.state := OUT_OF_FRAME; me.context := ctx
  END init;

  PROCEDURE char_receiver*(me: Instance; data: BYTE);
  (* Function to find valid HDLC frame from incoming data *)
  BEGIN
    IF data = FRAME_BOUNDARY_OCTET THEN (*FRAME FLAG*)
      IF me.escape_character THEN (*According to the protocol, this should never happen. We drop the data and reset the instance*)
        me.escape_character := FALSE; me.frame_position := 0; me.state := OUT_OF_FRAME
      ELSIF (me.state = IN_FRAME) & (me.frame_position > 0) THEN (*a valid end of frame is detected*)
        me.frame_handler(me, me.receive_frame_buffer, me.frame_position); (*Call the user defined function and pass frame to it *)
      END;
      me.frame_position := 0; me.state := IN_FRAME
    ELSIF data = CONTROL_ESCAPE_OCTET THEN me.escape_character := TRUE
    ELSE IF me.escape_character THEN me.escape_character := FALSE; XOR(data, INVERT_OCTET) END;
      me.receive_frame_buffer[me.frame_position] := data; INC(me.frame_position);
      IF me.frame_position = MAX_FRAME_LENGTH THEN me.frame_position := 0 END
    END
  END char_receiver;

  PROCEDURE open_frame*(me: Instance);
  BEGIN me.sendchar_function(me, FRAME_BOUNDARY_OCTET)
  END open_frame;

  PROCEDURE close_frame*(me: Instance);
  BEGIN me.sendchar_function(me, FRAME_BOUNDARY_OCTET)
  END close_frame;

  PROCEDURE write_byte_to_frame*(me: Instance; data: BYTE);
  BEGIN
    IF (data = CONTROL_ESCAPE_OCTET) OR (data = FRAME_BOUNDARY_OCTET) THEN
      me.sendchar_function(me, CONTROL_ESCAPE_OCTET); XOR(data, INVERT_OCTET)
    END;
    me.sendchar_function(me, data)
  END write_byte_to_frame;

  PROCEDURE write_buffer_to_frame*(me: Instance; buffer: ARRAY OF BYTE; length: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE i < length DO write_byte_to_frame(me, buffer[i]); INC(i) END
  END write_buffer_to_frame;

  PROCEDURE write_string_to_frame*(me: Instance; str: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := -1; REPEAT INC(i); write_byte_to_frame(me, ORD(str[i])) UNTIL str[i] = 0X
  END write_string_to_frame;

  PROCEDURE send_frame*(me: Instance; frame_buffer: ARRAY OF BYTE; frame_length: INTEGER);
    (*Wrap given data in HDLC frame and send it out byte at a time*)
  BEGIN open_frame(me); write_buffer_to_frame(me, frame_buffer, frame_length); close_frame(me)
  END send_frame;

  PROCEDURE buffer_push(me: Instance; data: BYTE);
  BEGIN
    IF me.frame_buffer_size < MAX_FRAME_LENGTH THEN
      me.frame_buffer[me.frame_buffer_size] := data; INC(me.frame_buffer_size)
    END
  END buffer_push;

  PROCEDURE init_frame_to_buffer*(me: Instance*);
  BEGIN me.sendchar_function := buffer_push; me.frame_buffer_size := 0
  END init_frame_to_buffer;

  PROCEDURE send_frame_to_buffer*(me: Instance; frame_buffer: ARRAY OF BYTE; frame_length: INTEGER);
  BEGIN init_frame_to_buffer(me); send_frame(me, frame_buffer, frame_length)
  END send_frame_to_buffer;

END minihdlc.

OMSPP.Compile minihdlc.Mod~
OMSPTool.DecObj minihdlc.mpc
decode minihdlc.mpc
minihdlc E0DECBE8 Flash   588
imports:
type descriptors
 0092 FFFF FFFF FFFF
data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0242 k 0000 c 0000 c 001A c 00F2 c 010A c 0122 c 0166 c 0192 c 01C0 c 0216 c 0222
fixup procedures in code space chains
 01C6     0	 00F2
 01E6     0	 010A
 01AC     0	 0122
 01DC     0	 0166
 023C     0	 01C0
 0218     0	 01EC
 0228     0	 0216
fixup handlers in vector space chains
fixup data in code space chains
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0242
code   580
 0000	     4584	MOV R5,0(R4)
 0002	     0000
 0004	     4684	MOV R6,2(R4)
 0006	     0002
 0008	     4384	MOV #0,6(R4)
 000A	     0006
 000C	     43C4	MOV.B #0,4(R4)
 000E	     0004
 0010	     4384	MOV #0,142(R4)
 0012	     008E
 0014	     4784	MOV R7,144(R4)
 0016	     0090
 0018	     4130	RET
 001A	     90F1	CMP.B #126,2(SP)
 001C	     007E
 001E	     0002
 0020	     203A	JNE $+118, goes to  0096
 0022	     411F	MOV 4(SP),R15
 0024	     0004
 0026	     93CF	CMP.B #0,4(R15)
 0028	     0004
 002A	     240D	JEQ $+28, goes to  0046
 002C	     411F	MOV 4(SP),R15
 002E	     0004
 0030	     43CF	MOV.B #0,4(R15)
 0032	     0004
 0034	     411F	MOV 4(SP),R15
 0036	     0004
 0038	     438F	MOV #0,6(R15)
 003A	     0006
 003C	     411F	MOV 4(SP),R15
 003E	     0004
 0040	     438F	MOV #0,142(R15)
 0042	     008E
 0044	     3C1F	JMP $+64, goes to  0084
 0046	     411F	MOV 4(SP),R15
 0048	     0004
 004A	     939F	CMP #1,142(R15)
 004C	     008E
 004E	     201A	JNE $+54, goes to  0084
 0050	     411F	MOV 4(SP),R15
 0052	     0004
 0054	     430E	MOV #0,R14
 0056	     9F1E	CMP 6(R15),R14
 0058	     0006
 005A	     3414	JGE $+42, goes to  0084
 005C	     411F	MOV 4(SP),R15
 005E	     0004
 0060	     121F	PUSH 2(R15)
 0062	     0002
 0064	     1211	PUSH 8(SP)
 0066	     0008
 0068	     411F	MOV 8(SP),R15
 006A	     0008
 006C	     1230	PUSH #65
 006E	     0041
 0070	     523F	ADD #8,R15
 0072	     120F	PUSH R15
 0074	     411F	MOV 12(SP),R15
 0076	     000C
 0078	     121F	PUSH 6(R15)
 007A	     0006
 007C	     1291	CALL 10(SP)
 007E	     000A
 0080	     5031	ADD #10,SP
 0082	     000A
 0084	     411F	MOV 4(SP),R15
 0086	     0004
 0088	     438F	MOV #0,6(R15)
 008A	     0006
 008C	     411F	MOV 4(SP),R15
 008E	     0004
 0090	     439F	MOV #1,142(R15)
 0092	     008E
 0094	     3C2D	JMP $+92, goes to  00F0
 0096	     90F1	CMP.B #125,2(SP)
 0098	     007D
 009A	     0002
 009C	     2005	JNE $+12, goes to  00A8
 009E	     411F	MOV 4(SP),R15
 00A0	     0004
 00A2	     43DF	MOV.B #1,4(R15)
 00A4	     0004
 00A6	     3C24	JMP $+74, goes to  00F0
 00A8	     411F	MOV 4(SP),R15
 00AA	     0004
 00AC	     93CF	CMP.B #0,4(R15)
 00AE	     0004
 00B0	     2407	JEQ $+16, goes to  00C0
 00B2	     411F	MOV 4(SP),R15
 00B4	     0004
 00B6	     43CF	MOV.B #0,4(R15)
 00B8	     0004
 00BA	     E0F1	XOR.B #32,2(SP)
 00BC	     0020
 00BE	     0002
 00C0	     411F	MOV 4(SP),R15
 00C2	     0004
 00C4	     411E	MOV 4(SP),R14
 00C6	     0004
 00C8	     4E1E	MOV 6(R14),R14
 00CA	     0006
 00CC	     5F0E	ADD R15,R14
 00CE	     41DE	MOV.B 2(SP),8(R14)
 00D0	     0002
 00D2	     0008
 00D4	     411F	MOV 4(SP),R15
 00D6	     0004
 00D8	     539F	ADD #1,6(R15)
 00DA	     0006
 00DC	     411F	MOV 4(SP),R15
 00DE	     0004
 00E0	     90BF	CMP #64,6(R15)
 00E2	     0040
 00E4	     0006
 00E6	     2004	JNE $+10, goes to  00F0
 00E8	     411F	MOV 4(SP),R15
 00EA	     0004
 00EC	     438F	MOV #0,6(R15)
 00EE	     0006
 00F0	     4130	RET
 00F2	     411F	MOV 2(SP),R15
 00F4	     0002
 00F6	     122F	PUSH @R15
 00F8	     1211	PUSH 6(SP)
 00FA	     0006
 00FC	     1230	PUSH #126
 00FE	     007E
 0100	     1291	CALL 6(SP)
 0102	     0006
 0104	     5031	ADD #6,SP
 0106	     0006
 0108	     4130	RET
 010A	     411F	MOV 2(SP),R15
 010C	     0002
 010E	     122F	PUSH @R15
 0110	     1211	PUSH 6(SP)
 0112	     0006
 0114	     1230	PUSH #126
 0116	     007E
 0118	     1291	CALL 6(SP)
 011A	     0006
 011C	     5031	ADD #6,SP
 011E	     0006
 0120	     4130	RET
 0122	     90F1	CMP.B #125,2(SP)
 0124	     007D
 0126	     0002
 0128	     2404	JEQ $+10, goes to  0132
 012A	     90F1	CMP.B #126,2(SP)
 012C	     007E
 012E	     0002
 0130	     200E	JNE $+30, goes to  014E
 0132	     411F	MOV 4(SP),R15
 0134	     0004
 0136	     122F	PUSH @R15
 0138	     1211	PUSH 8(SP)
 013A	     0008
 013C	     1230	PUSH #125
 013E	     007D
 0140	     1291	CALL 6(SP)
 0142	     0006
 0144	     5031	ADD #6,SP
 0146	     0006
 0148	     E0F1	XOR.B #32,2(SP)
 014A	     0020
 014C	     0002
 014E	     411F	MOV 4(SP),R15
 0150	     0004
 0152	     122F	PUSH @R15
 0154	     1211	PUSH 8(SP)
 0156	     0008
 0158	     1251	PUSH.B 8(SP)
 015A	     0008
 015C	     1291	CALL 6(SP)
 015E	     0006
 0160	     5031	ADD #6,SP
 0162	     0006
 0164	     4130	RET
 0166	     8321	SUB #2,SP
 0168	     4381	MOV #0,0(SP)
 016A	     0000
 016C	     9191	CMP 4(SP),0(SP)
 016E	     0004
 0170	     0000
 0172	     340D	JGE $+28, goes to  018E
 0174	     1211	PUSH 12(SP)
 0176	     000C
 0178	     411F	MOV 2(SP),R15
 017A	     0002
 017C	     511F	ADD 8(SP),R15
 017E	     0008
 0180	     126F	PUSH.B @R15
 0182	     12B0	CALL #0
 0184	     0000
 0186	     5221	ADD #4,SP
 0188	     5391	ADD #1,0(SP)
 018A	     0000
 018C	     3FEF	JMP $-32, goes to  016C
 018E	     5321	ADD #2,SP
 0190	     4130	RET
 0192	     8321	SUB #2,SP
 0194	     43B1	MOV #-1,0(SP)
 0196	     0000
 0198	     5391	ADD #1,0(SP)
 019A	     0000
 019C	     1211	PUSH 10(SP)
 019E	     000A
 01A0	     411F	MOV 2(SP),R15
 01A2	     0002
 01A4	     511F	ADD 6(SP),R15
 01A6	     0006
 01A8	     126F	PUSH.B @R15
 01AA	     12B0	CALL #388
 01AC	     0184
 01AE	     5221	ADD #4,SP
 01B0	     412F	MOV @SP,R15
 01B2	     511F	ADD 4(SP),R15
 01B4	     0004
 01B6	     93CF	CMP.B #0,0(R15)
 01B8	     0000
 01BA	     23EE	JNE $-34, goes to  0198
 01BC	     5321	ADD #2,SP
 01BE	     4130	RET
 01C0	     1211	PUSH 10(SP)
 01C2	     000A
 01C4	     12B0	CALL #0
 01C6	     0000
 01C8	     5321	ADD #2,SP
 01CA	     1211	PUSH 10(SP)
 01CC	     000A
 01CE	     1211	PUSH 10(SP)
 01D0	     000A
 01D2	     1211	PUSH 10(SP)
 01D4	     000A
 01D6	     1211	PUSH 10(SP)
 01D8	     000A
 01DA	     12B0	CALL #0
 01DC	     0000
 01DE	     5231	ADD #8,SP
 01E0	     1211	PUSH 10(SP)
 01E2	     000A
 01E4	     12B0	CALL #0
 01E6	     0000
 01E8	     5321	ADD #2,SP
 01EA	     4130	RET
 01EC	     411F	MOV 4(SP),R15
 01EE	     0004
 01F0	     90BF	CMP #64,140(R15)
 01F2	     0040
 01F4	     008C
 01F6	     340E	JGE $+30, goes to  0214
 01F8	     411F	MOV 4(SP),R15
 01FA	     0004
 01FC	     411E	MOV 4(SP),R14
 01FE	     0004
 0200	     4E1E	MOV 140(R14),R14
 0202	     008C
 0204	     5F0E	ADD R15,R14
 0206	     41DE	MOV.B 2(SP),74(R14)
 0208	     0002
 020A	     004A
 020C	     411F	MOV 4(SP),R15
 020E	     0004
 0210	     539F	ADD #1,140(R15)
 0212	     008C
 0214	     4130	RET
 0216	     40B4	MOV #0,0(R4)
 0218	     0000
 021A	     0000
 021C	     4384	MOV #0,140(R4)
 021E	     008C
 0220	     4130	RET
 0222	     4114	MOV 8(SP),R4
 0224	     0008
 0226	     12B0	CALL #0
 0228	     0000
 022A	     1211	PUSH 10(SP)
 022C	     000A
 022E	     1211	PUSH 10(SP)
 0230	     000A
 0232	     1211	PUSH 10(SP)
 0234	     000A
 0236	     1211	PUSH 10(SP)
 0238	     000A
 023A	     12B0	CALL #0
 023C	     0000
 023E	     5231	ADD #8,SP
 0240	     4130	RET
 0242	     4130	RET
