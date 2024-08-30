MODULE testSProcs;
(*For ASSERT tests, see testAssert.Mod,
   For INCL and EXCL tests, see testInEx.Mod*)

  PROCEDURE p;
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
testSProcs E4E6292A Flash   410
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0198
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0198
code   410
 0000	     8221	SUB #4,SP
 0002	     5391	ADD #1,0(SP)
 0004	     0000
 0006	     53D1	ADD.B #1,2(SP)
 0008	     0002
 000A	     C1D1	BIC.B 2(SP),0(SP)
 000C	     0002
 000E	     0000
 0010	     C1E1	BIC.B @SP,2(SP)
 0012	     0002
 0014	     C1A1	BIC @SP,0(SP)
 0016	     0000
 0018	     C1D1	BIC.B 2(SP),2(SP)
 001A	     0002
 001C	     0002
 001E	     C0B1	BIC #1056,0(SP)
 0020	     0420
 0022	     0000
 0024	     C0F1	BIC.B #1056,2(SP)
 0026	     0420
 0028	     0002
 002A	     D1D1	BIS.B 2(SP),0(SP)
 002C	     0002
 002E	     0000
 0030	     D1E1	BIS.B @SP,2(SP)
 0032	     0002
 0034	     D1A1	BIS @SP,0(SP)
 0036	     0000
 0038	     D1D1	BIS.B 2(SP),2(SP)
 003A	     0002
 003C	     0002
 003E	     D0B1	BIS #1056,0(SP)
 0040	     0420
 0042	     0000
 0044	     D0F1	BIS.B #1056,2(SP)
 0046	     0420
 0048	     0002
 004A	     E1D1	XOR.B 2(SP),0(SP)
 004C	     0002
 004E	     0000
 0050	     E1E1	XOR.B @SP,2(SP)
 0052	     0002
 0054	     E1A1	XOR @SP,0(SP)
 0056	     0000
 0058	     E1D1	XOR.B 2(SP),2(SP)
 005A	     0002
 005C	     0002
 005E	     E0B1	XOR #1056,0(SP)
 0060	     0420
 0062	     0000
 0064	     E0F1	XOR.B #1056,2(SP)
 0066	     0420
 0068	     0002
 006A	     F1D1	AND.B 2(SP),0(SP)
 006C	     0002
 006E	     0000
 0070	     F1E1	AND.B @SP,2(SP)
 0072	     0002
 0074	     F1A1	AND @SP,0(SP)
 0076	     0000
 0078	     F1D1	AND.B 2(SP),2(SP)
 007A	     0002
 007C	     0002
 007E	     F0B1	AND #1056,0(SP)
 0080	     0420
 0082	     0000
 0084	     F0F1	AND.B #1056,2(SP)
 0086	     0420
 0088	     0002
 008A	     C312	BIC #1,SR
 008C	     61D1	ADDC.B 2(SP),0(SP)
 008E	     0002
 0090	     0000
 0092	     61E1	ADDC.B @SP,2(SP)
 0094	     0002
 0096	     61A1	ADDC @SP,0(SP)
 0098	     0000
 009A	     61D1	ADDC.B 2(SP),2(SP)
 009C	     0002
 009E	     0002
 00A0	     60B1	ADDC #1056,0(SP)
 00A2	     0420
 00A4	     0000
 00A6	     60F1	ADDC.B #1056,2(SP)
 00A8	     0420
 00AA	     0002
 00AC	     71D1	SUBC.B 2(SP),0(SP)
 00AE	     0002
 00B0	     0000
 00B2	     71E1	SUBC.B @SP,2(SP)
 00B4	     0002
 00B6	     71A1	SUBC @SP,0(SP)
 00B8	     0000
 00BA	     71D1	SUBC.B 2(SP),2(SP)
 00BC	     0002
 00BE	     0002
 00C0	     70B1	SUBC #1056,0(SP)
 00C2	     0420
 00C4	     0000
 00C6	     70F1	SUBC.B #1056,2(SP)
 00C8	     0420
 00CA	     0002
 00CC	     415F	MOV.B 2(SP),R15
 00CE	     0002
 00D0	     535F	ADD.B #1,R15
 00D2	     835F	SUB.B #1,R15
 00D4	     2403	JEQ #3, goes to  00DC
 00D6	     51A1	ADD @SP,0(SP)
 00D8	     0000
 00DA	     3FFB	JMP #-5, goes to  00D2
 00DC	     412F	MOV @SP,R15
 00DE	     531F	ADD #1,R15
 00E0	     831F	SUB #1,R15
 00E2	     2404	JEQ #4, goes to  00EC
 00E4	     51D1	ADD.B 2(SP),2(SP)
 00E6	     0002
 00E8	     0002
 00EA	     3FFA	JMP #-6, goes to  00E0
 00EC	     412F	MOV @SP,R15
 00EE	     531F	ADD #1,R15
 00F0	     831F	SUB #1,R15
 00F2	     2403	JEQ #3, goes to  00FA
 00F4	     51A1	ADD @SP,0(SP)
 00F6	     0000
 00F8	     3FFB	JMP #-5, goes to  00F0
 00FA	     415F	MOV.B 2(SP),R15
 00FC	     0002
 00FE	     535F	ADD.B #1,R15
 0100	     835F	SUB.B #1,R15
 0102	     2404	JEQ #4, goes to  010C
 0104	     51D1	ADD.B 2(SP),2(SP)
 0106	     0002
 0108	     0002
 010A	     3FFA	JMP #-6, goes to  0100
 010C	     403F	MOV #10,R15
 010E	     000A
 0110	     531F	ADD #1,R15
 0112	     831F	SUB #1,R15
 0114	     2403	JEQ #3, goes to  011C
 0116	     51A1	ADD @SP,0(SP)
 0118	     0000
 011A	     3FFB	JMP #-5, goes to  0112
 011C	     403F	MOV #5,R15
 011E	     0005
 0120	     531F	ADD #1,R15
 0122	     831F	SUB #1,R15
 0124	     2404	JEQ #4, goes to  012E
 0126	     51D1	ADD.B 2(SP),2(SP)
 0128	     0002
 012A	     0002
 012C	     3FFA	JMP #-6, goes to  0122
 012E	     61A1	ADDC @SP,0(SP)
 0130	     0000
 0132	     61D1	ADDC.B 2(SP),2(SP)
 0134	     0002
 0136	     0002
 0138	     415F	MOV.B 2(SP),R15
 013A	     0002
 013C	     535F	ADD.B #1,R15
 013E	     835F	SUB.B #1,R15
 0140	     2402	JEQ #2, goes to  0146
 0142	     1121	RRA @SP
 0144	     3FFC	JMP #-4, goes to  013E
 0146	     412F	MOV @SP,R15
 0148	     531F	ADD #1,R15
 014A	     831F	SUB #1,R15
 014C	     2403	JEQ #3, goes to  0154
 014E	     1151	RRA.B 2(SP)
 0150	     0002
 0152	     3FFB	JMP #-5, goes to  014A
 0154	     412F	MOV @SP,R15
 0156	     531F	ADD #1,R15
 0158	     831F	SUB #1,R15
 015A	     2402	JEQ #2, goes to  0160
 015C	     1121	RRA @SP
 015E	     3FFC	JMP #-4, goes to  0158
 0160	     415F	MOV.B 2(SP),R15
 0162	     0002
 0164	     535F	ADD.B #1,R15
 0166	     835F	SUB.B #1,R15
 0168	     2403	JEQ #3, goes to  0170
 016A	     1151	RRA.B 2(SP)
 016C	     0002
 016E	     3FFB	JMP #-5, goes to  0166
 0170	     403F	MOV #10,R15
 0172	     000A
 0174	     531F	ADD #1,R15
 0176	     831F	SUB #1,R15
 0178	     2402	JEQ #2, goes to  017E
 017A	     1121	RRA @SP
 017C	     3FFC	JMP #-4, goes to  0176
 017E	     403F	MOV #5,R15
 0180	     0005
 0182	     531F	ADD #1,R15
 0184	     831F	SUB #1,R15
 0186	     2403	JEQ #3, goes to  018E
 0188	     1151	RRA.B 2(SP)
 018A	     0002
 018C	     3FFB	JMP #-5, goes to  0184
 018E	     1021	RRC @SP
 0190	     1051	RRC.B 2(SP)
 0192	     0002
 0194	     5221	ADD #4,SP
 0196	     4130	RET
 0198	     4130	RET
