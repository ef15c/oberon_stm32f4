MODULE testSProcs;
(*For ASSERT tests, see testAssert.Mod,
   For INCL and EXCL tests, see testInEx.Mod*)

  PROCEDURE p*;
    VAR i: INTEGER; b: BYTE;
  BEGIN INC(i); INC(b);
    BIC(i, b); BIC(b, i); BIC(i, i); BIC(b, b); BIC(i, {5, 10}); BIC(b, {5, 10});
    BIS(i, b); BIS(b, i); BIS(i, i); BIS(b, b); BIS(i, {5, 10}); BIS(b, {5, 10});
    XOR(i, b); XOR(b, i); XOR(i, i); XOR(b, b); XOR(i, {5, 10}); XOR(b, {5, 10});
    AND(i, b); AND(b, i); AND(i, i); AND(b, b); AND(i, {5, 10}); AND(b, {5, 10});
    CLRC;
    ADC(i, b); ADC(b, i); ADC(i, i); ADC(b, b); ADC(i, {5, 10}); ADC(b, {5, 10});
    SBC(i, b); SBC(b, i); SBC(i, i); SBC(b, b); SBC(i, {5, 10}); SBC(b, {5, 10});
    RLA(i, b); RLA(b, i); RLA(i, i); RLA(b, b); RLA(i, 10); RLA(b, 5);
    RLC(i); RLC(b);
    RRA(i, b); RRA(b, i); RRA(i, i); RRA(b, b); RRA(i, 10); RRA(b, 5);
    RRC(i); RRC(b);
  END p;

END testSProcs.

OMSPTool.DecObj testSProcs.mpc
decode testSProcs.mpc
testSProcs 4B454405
imports:

section     0	c  420	p
 0000	     8221	SUB #4,SP
 0002	     5391	ADD #1,0(SP)
 0004	     0000
 0006	     53D1	ADD.B #1,2(SP)
 0008	     0002
 000A	     415F	MOV.B 2(SP),R15
 000C	     0002
 000E	     CF81	BIC R15,0(SP)
 0010	     0000
 0012	     C1E1	BIC.B @SP,2(SP)
 0014	     0002
 0016	     C1A1	BIC @SP,0(SP)
 0018	     0000
 001A	     C1D1	BIC.B 2(SP),2(SP)
 001C	     0002
 001E	     0002
 0020	     C0B1	BIC #1056,0(SP)
 0022	     0420
 0024	     0000
 0026	     C0F1	BIC.B #1056,2(SP)
 0028	     0420
 002A	     0002
 002C	     415F	MOV.B 2(SP),R15
 002E	     0002
 0030	     DF81	BIS R15,0(SP)
 0032	     0000
 0034	     D1E1	BIS.B @SP,2(SP)
 0036	     0002
 0038	     D1A1	BIS @SP,0(SP)
 003A	     0000
 003C	     D1D1	BIS.B 2(SP),2(SP)
 003E	     0002
 0040	     0002
 0042	     D0B1	BIS #1056,0(SP)
 0044	     0420
 0046	     0000
 0048	     D0F1	BIS.B #1056,2(SP)
 004A	     0420
 004C	     0002
 004E	     415F	MOV.B 2(SP),R15
 0050	     0002
 0052	     EF81	XOR R15,0(SP)
 0054	     0000
 0056	     E1E1	XOR.B @SP,2(SP)
 0058	     0002
 005A	     E1A1	XOR @SP,0(SP)
 005C	     0000
 005E	     E1D1	XOR.B 2(SP),2(SP)
 0060	     0002
 0062	     0002
 0064	     E0B1	XOR #1056,0(SP)
 0066	     0420
 0068	     0000
 006A	     E0F1	XOR.B #1056,2(SP)
 006C	     0420
 006E	     0002
 0070	     415F	MOV.B 2(SP),R15
 0072	     0002
 0074	     FF81	AND R15,0(SP)
 0076	     0000
 0078	     F1E1	AND.B @SP,2(SP)
 007A	     0002
 007C	     F1A1	AND @SP,0(SP)
 007E	     0000
 0080	     F1D1	AND.B 2(SP),2(SP)
 0082	     0002
 0084	     0002
 0086	     F0B1	AND #1056,0(SP)
 0088	     0420
 008A	     0000
 008C	     F0F1	AND.B #1056,2(SP)
 008E	     0420
 0090	     0002
 0092	     C312	BIC #1,SR
 0094	     415F	MOV.B 2(SP),R15
 0096	     0002
 0098	     6F81	ADDC R15,0(SP)
 009A	     0000
 009C	     61E1	ADDC.B @SP,2(SP)
 009E	     0002
 00A0	     61A1	ADDC @SP,0(SP)
 00A2	     0000
 00A4	     61D1	ADDC.B 2(SP),2(SP)
 00A6	     0002
 00A8	     0002
 00AA	     60B1	ADDC #1056,0(SP)
 00AC	     0420
 00AE	     0000
 00B0	     60F1	ADDC.B #1056,2(SP)
 00B2	     0420
 00B4	     0002
 00B6	     415F	MOV.B 2(SP),R15
 00B8	     0002
 00BA	     7F81	SUBC R15,0(SP)
 00BC	     0000
 00BE	     71E1	SUBC.B @SP,2(SP)
 00C0	     0002
 00C2	     71A1	SUBC @SP,0(SP)
 00C4	     0000
 00C6	     71D1	SUBC.B 2(SP),2(SP)
 00C8	     0002
 00CA	     0002
 00CC	     70B1	SUBC #1056,0(SP)
 00CE	     0420
 00D0	     0000
 00D2	     70F1	SUBC.B #1056,2(SP)
 00D4	     0420
 00D6	     0002
 00D8	     415F	MOV.B 2(SP),R15
 00DA	     0002
 00DC	     535F	ADD.B #1,R15
 00DE	     835F	SUB.B #1,R15
 00E0	     2403	JEQ $+8, goes to  00E8
 00E2	     51A1	ADD @SP,0(SP)
 00E4	     0000
 00E6	     3FFB	JMP $-8, goes to  00DE
 00E8	     412F	MOV @SP,R15
 00EA	     531F	ADD #1,R15
 00EC	     831F	SUB #1,R15
 00EE	     2404	JEQ $+10, goes to  00F8
 00F0	     51D1	ADD.B 2(SP),2(SP)
 00F2	     0002
 00F4	     0002
 00F6	     3FFA	JMP $-10, goes to  00EC
 00F8	     412F	MOV @SP,R15
 00FA	     531F	ADD #1,R15
 00FC	     831F	SUB #1,R15
 00FE	     2403	JEQ $+8, goes to  0106
 0100	     51A1	ADD @SP,0(SP)
 0102	     0000
 0104	     3FFB	JMP $-8, goes to  00FC
 0106	     415F	MOV.B 2(SP),R15
 0108	     0002
 010A	     535F	ADD.B #1,R15
 010C	     835F	SUB.B #1,R15
 010E	     2404	JEQ $+10, goes to  0118
 0110	     51D1	ADD.B 2(SP),2(SP)
 0112	     0002
 0114	     0002
 0116	     3FFA	JMP $-10, goes to  010C
 0118	     403F	MOV #10,R15
 011A	     000A
 011C	     531F	ADD #1,R15
 011E	     831F	SUB #1,R15
 0120	     2403	JEQ $+8, goes to  0128
 0122	     51A1	ADD @SP,0(SP)
 0124	     0000
 0126	     3FFB	JMP $-8, goes to  011E
 0128	     403F	MOV #5,R15
 012A	     0005
 012C	     531F	ADD #1,R15
 012E	     831F	SUB #1,R15
 0130	     2404	JEQ $+10, goes to  013A
 0132	     51D1	ADD.B 2(SP),2(SP)
 0134	     0002
 0136	     0002
 0138	     3FFA	JMP $-10, goes to  012E
 013A	     61A1	ADDC @SP,0(SP)
 013C	     0000
 013E	     61D1	ADDC.B 2(SP),2(SP)
 0140	     0002
 0142	     0002
 0144	     415F	MOV.B 2(SP),R15
 0146	     0002
 0148	     535F	ADD.B #1,R15
 014A	     835F	SUB.B #1,R15
 014C	     2402	JEQ $+6, goes to  0152
 014E	     1121	RRA @SP
 0150	     3FFC	JMP $-6, goes to  014A
 0152	     412F	MOV @SP,R15
 0154	     531F	ADD #1,R15
 0156	     831F	SUB #1,R15
 0158	     2403	JEQ $+8, goes to  0160
 015A	     1151	RRA.B 2(SP)
 015C	     0002
 015E	     3FFB	JMP $-8, goes to  0156
 0160	     412F	MOV @SP,R15
 0162	     531F	ADD #1,R15
 0164	     831F	SUB #1,R15
 0166	     2402	JEQ $+6, goes to  016C
 0168	     1121	RRA @SP
 016A	     3FFC	JMP $-6, goes to  0164
 016C	     415F	MOV.B 2(SP),R15
 016E	     0002
 0170	     535F	ADD.B #1,R15
 0172	     835F	SUB.B #1,R15
 0174	     2403	JEQ $+8, goes to  017C
 0176	     1151	RRA.B 2(SP)
 0178	     0002
 017A	     3FFB	JMP $-8, goes to  0172
 017C	     403F	MOV #10,R15
 017E	     000A
 0180	     531F	ADD #1,R15
 0182	     831F	SUB #1,R15
 0184	     2402	JEQ $+6, goes to  018A
 0186	     1121	RRA @SP
 0188	     3FFC	JMP $-6, goes to  0182
 018A	     403F	MOV #5,R15
 018C	     0005
 018E	     531F	ADD #1,R15
 0190	     831F	SUB #1,R15
 0192	     2403	JEQ $+8, goes to  019A
 0194	     1151	RRA.B 2(SP)
 0196	     0002
 0198	     3FFB	JMP $-8, goes to  0190
 019A	     1021	RRC @SP
 019C	     1051	RRC.B 2(SP)
 019E	     0002
 01A0	     5221	ADD #4,SP
 01A2	     4130	RET
fixups:

section     1	c    2	module body
 0000	     4130	RET
fixups:

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1    0
