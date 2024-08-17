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
testSProcs E4E6292A Flash   458
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 01C8
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  01C8
code   458
 0000	     8221	SUB #4,SP
 0002	     5391	ADD #1,2(SP)
 0004	     0002
 0006	     53D1	ADD.B #1,1(SP)
 0008	     0001
 000A	     C1D1	BIC.B 1(SP),2(SP)
 000C	     0001
 000E	     0002
 0010	     C1D1	BIC.B 2(SP),1(SP)
 0012	     0002
 0014	     0001
 0016	     C191	BIC 2(SP),2(SP)
 0018	     0002
 001A	     0002
 001C	     C1D1	BIC.B 1(SP),1(SP)
 001E	     0001
 0020	     0001
 0022	     C0B1	BIC #1056,2(SP)
 0024	     0420
 0026	     0002
 0028	     C0F1	BIC.B #1056,1(SP)
 002A	     0420
 002C	     0001
 002E	     D1D1	BIS.B 1(SP),2(SP)
 0030	     0001
 0032	     0002
 0034	     D1D1	BIS.B 2(SP),1(SP)
 0036	     0002
 0038	     0001
 003A	     D191	BIS 2(SP),2(SP)
 003C	     0002
 003E	     0002
 0040	     D1D1	BIS.B 1(SP),1(SP)
 0042	     0001
 0044	     0001
 0046	     D0B1	BIS #1056,2(SP)
 0048	     0420
 004A	     0002
 004C	     D0F1	BIS.B #1056,1(SP)
 004E	     0420
 0050	     0001
 0052	     E1D1	XOR.B 1(SP),2(SP)
 0054	     0001
 0056	     0002
 0058	     E1D1	XOR.B 2(SP),1(SP)
 005A	     0002
 005C	     0001
 005E	     E191	XOR 2(SP),2(SP)
 0060	     0002
 0062	     0002
 0064	     E1D1	XOR.B 1(SP),1(SP)
 0066	     0001
 0068	     0001
 006A	     E0B1	XOR #1056,2(SP)
 006C	     0420
 006E	     0002
 0070	     E0F1	XOR.B #1056,1(SP)
 0072	     0420
 0074	     0001
 0076	     F1D1	AND.B 1(SP),2(SP)
 0078	     0001
 007A	     0002
 007C	     F1D1	AND.B 2(SP),1(SP)
 007E	     0002
 0080	     0001
 0082	     F191	AND 2(SP),2(SP)
 0084	     0002
 0086	     0002
 0088	     F1D1	AND.B 1(SP),1(SP)
 008A	     0001
 008C	     0001
 008E	     F0B1	AND #1056,2(SP)
 0090	     0420
 0092	     0002
 0094	     F0F1	AND.B #1056,1(SP)
 0096	     0420
 0098	     0001
 009A	     C312	BIC #1,SR
 009C	     61D1	ADDC.B 1(SP),2(SP)
 009E	     0001
 00A0	     0002
 00A2	     61D1	ADDC.B 2(SP),1(SP)
 00A4	     0002
 00A6	     0001
 00A8	     6191	ADDC 2(SP),2(SP)
 00AA	     0002
 00AC	     0002
 00AE	     61D1	ADDC.B 1(SP),1(SP)
 00B0	     0001
 00B2	     0001
 00B4	     60B1	ADDC #1056,2(SP)
 00B6	     0420
 00B8	     0002
 00BA	     60F1	ADDC.B #1056,1(SP)
 00BC	     0420
 00BE	     0001
 00C0	     71D1	SUBC.B 1(SP),2(SP)
 00C2	     0001
 00C4	     0002
 00C6	     71D1	SUBC.B 2(SP),1(SP)
 00C8	     0002
 00CA	     0001
 00CC	     7191	SUBC 2(SP),2(SP)
 00CE	     0002
 00D0	     0002
 00D2	     71D1	SUBC.B 1(SP),1(SP)
 00D4	     0001
 00D6	     0001
 00D8	     70B1	SUBC #1056,2(SP)
 00DA	     0420
 00DC	     0002
 00DE	     70F1	SUBC.B #1056,1(SP)
 00E0	     0420
 00E2	     0001
 00E4	     415F	MOV.B 1(SP),R15
 00E6	     0001
 00E8	     535F	ADD.B #1,R15
 00EA	     835F	SUB.B #1,R15
 00EC	     2404	JEQ #4, goes to  00F6
 00EE	     5191	ADD 2(SP),2(SP)
 00F0	     0002
 00F2	     0002
 00F4	     3FFA	JMP #-6, goes to  00EA
 00F6	     411F	MOV 2(SP),R15
 00F8	     0002
 00FA	     531F	ADD #1,R15
 00FC	     831F	SUB #1,R15
 00FE	     2404	JEQ #4, goes to  0108
 0100	     51D1	ADD.B 1(SP),1(SP)
 0102	     0001
 0104	     0001
 0106	     3FFA	JMP #-6, goes to  00FC
 0108	     411F	MOV 2(SP),R15
 010A	     0002
 010C	     531F	ADD #1,R15
 010E	     831F	SUB #1,R15
 0110	     2404	JEQ #4, goes to  011A
 0112	     5191	ADD 2(SP),2(SP)
 0114	     0002
 0116	     0002
 0118	     3FFA	JMP #-6, goes to  010E
 011A	     415F	MOV.B 1(SP),R15
 011C	     0001
 011E	     535F	ADD.B #1,R15
 0120	     835F	SUB.B #1,R15
 0122	     2404	JEQ #4, goes to  012C
 0124	     51D1	ADD.B 1(SP),1(SP)
 0126	     0001
 0128	     0001
 012A	     3FFA	JMP #-6, goes to  0120
 012C	     403F	MOV #10,R15
 012E	     000A
 0130	     531F	ADD #1,R15
 0132	     831F	SUB #1,R15
 0134	     2404	JEQ #4, goes to  013E
 0136	     5191	ADD 2(SP),2(SP)
 0138	     0002
 013A	     0002
 013C	     3FFA	JMP #-6, goes to  0132
 013E	     403F	MOV #5,R15
 0140	     0005
 0142	     531F	ADD #1,R15
 0144	     831F	SUB #1,R15
 0146	     2404	JEQ #4, goes to  0150
 0148	     51D1	ADD.B 1(SP),1(SP)
 014A	     0001
 014C	     0001
 014E	     3FFA	JMP #-6, goes to  0144
 0150	     6191	ADDC 2(SP),2(SP)
 0152	     0002
 0154	     0002
 0156	     61D1	ADDC.B 1(SP),1(SP)
 0158	     0001
 015A	     0001
 015C	     415F	MOV.B 1(SP),R15
 015E	     0001
 0160	     535F	ADD.B #1,R15
 0162	     835F	SUB.B #1,R15
 0164	     2403	JEQ #3, goes to  016C
 0166	     1111	RRA 2(SP)
 0168	     0002
 016A	     3FFB	JMP #-5, goes to  0162
 016C	     411F	MOV 2(SP),R15
 016E	     0002
 0170	     531F	ADD #1,R15
 0172	     831F	SUB #1,R15
 0174	     2403	JEQ #3, goes to  017C
 0176	     1151	RRA 1(SP)
 0178	     0001
 017A	     3FFB	JMP #-5, goes to  0172
 017C	     411F	MOV 2(SP),R15
 017E	     0002
 0180	     531F	ADD #1,R15
 0182	     831F	SUB #1,R15
 0184	     2403	JEQ #3, goes to  018C
 0186	     1111	RRA 2(SP)
 0188	     0002
 018A	     3FFB	JMP #-5, goes to  0182
 018C	     415F	MOV.B 1(SP),R15
 018E	     0001
 0190	     535F	ADD.B #1,R15
 0192	     835F	SUB.B #1,R15
 0194	     2403	JEQ #3, goes to  019C
 0196	     1151	RRA 1(SP)
 0198	     0001
 019A	     3FFB	JMP #-5, goes to  0192
 019C	     403F	MOV #10,R15
 019E	     000A
 01A0	     531F	ADD #1,R15
 01A2	     831F	SUB #1,R15
 01A4	     2403	JEQ #3, goes to  01AC
 01A6	     1111	RRA 2(SP)
 01A8	     0002
 01AA	     3FFB	JMP #-5, goes to  01A2
 01AC	     403F	MOV #5,R15
 01AE	     0005
 01B0	     531F	ADD #1,R15
 01B2	     831F	SUB #1,R15
 01B4	     2403	JEQ #3, goes to  01BC
 01B6	     1151	RRA 1(SP)
 01B8	     0001
 01BA	     3FFB	JMP #-5, goes to  01B2
 01BC	     1011	RRC 2(SP)
 01BE	     0002
 01C0	     1051	RRC.B 1(SP)
 01C2	     0001
 01C4	     5221	ADD #4,SP
 01C6	     4130	RET
 01C8	     4130	RET
