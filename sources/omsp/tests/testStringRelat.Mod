MODULE testStringRelat;

  PROCEDURE p*;
    VAR a, b: ARRAY 10 OF CHAR;
      t: BOOLEAN;
  BEGIN
    t := a>"1.";
    t := a>="2.";
    t := a="3.";
    t := a<"-1.";
    t := a<="-2.";
    t := a#"-3.";
    t := "1.">a;
    t := "2.">=a;
    t := "3."=a;
    t := "-1."<a;
    t := "-2."<=a;
    t := "-3."#a;
    t := a>b;
    t := a>=b;
    t := a=b;
    t := a<b;
    t := a<=b;
    t := a#b
  END p;

END testStringRelat.

OMSPP.Compile testStringRelat.Mod/s~
OMSPTool.DecObj testStringRelat.mpc
decode testStringRelat.mpc
testStringRelat DF7853C0
imports:

section     0	c  526	p
 0000	     8031	SUB #22,SP
 0002	     0016
 0004	     410F	MOV SP,R15
 0006	     403E	MOV #0,R14
 0008	     0000
 000A	     4E7D	MOV.B @R14+,R13
 000C	     9F7D	CMP.B @R15+,R13
 000E	     2002	JNE $+6, goes to  0014
 0010	     934D	CMP.B #0,R13
 0012	     23FB	JNE $-8, goes to  000A
 0014	     2C02	JC $+6, goes to  001A
 0016	     431F	MOV #1,R15
 0018	     3C01	JMP $+4, goes to  001C
 001A	     430F	MOV #0,R15
 001C	     4FC1	MOV.B R15,20(SP)
 001E	     0014
 0020	     410F	MOV SP,R15
 0022	     403E	MOV #0,R14
 0024	     0000
 0026	     4F7D	MOV.B @R15+,R13
 0028	     9E7D	CMP.B @R14+,R13
 002A	     2002	JNE $+6, goes to  0030
 002C	     934D	CMP.B #0,R13
 002E	     23FB	JNE $-8, goes to  0026
 0030	     2802	JNC $+6, goes to  0036
 0032	     431F	MOV #1,R15
 0034	     3C01	JMP $+4, goes to  0038
 0036	     430F	MOV #0,R15
 0038	     4FC1	MOV.B R15,20(SP)
 003A	     0014
 003C	     410F	MOV SP,R15
 003E	     403E	MOV #0,R14
 0040	     0000
 0042	     4F7D	MOV.B @R15+,R13
 0044	     9E7D	CMP.B @R14+,R13
 0046	     2002	JNE $+6, goes to  004C
 0048	     934D	CMP.B #0,R13
 004A	     23FB	JNE $-8, goes to  0042
 004C	     2002	JNE $+6, goes to  0052
 004E	     431F	MOV #1,R15
 0050	     3C01	JMP $+4, goes to  0054
 0052	     430F	MOV #0,R15
 0054	     4FC1	MOV.B R15,20(SP)
 0056	     0014
 0058	     410F	MOV SP,R15
 005A	     403E	MOV #0,R14
 005C	     0000
 005E	     4F7D	MOV.B @R15+,R13
 0060	     9E7D	CMP.B @R14+,R13
 0062	     2002	JNE $+6, goes to  0068
 0064	     934D	CMP.B #0,R13
 0066	     23FB	JNE $-8, goes to  005E
 0068	     2C02	JC $+6, goes to  006E
 006A	     431F	MOV #1,R15
 006C	     3C01	JMP $+4, goes to  0070
 006E	     430F	MOV #0,R15
 0070	     4FC1	MOV.B R15,20(SP)
 0072	     0014
 0074	     410F	MOV SP,R15
 0076	     403E	MOV #0,R14
 0078	     0000
 007A	     4E7D	MOV.B @R14+,R13
 007C	     9F7D	CMP.B @R15+,R13
 007E	     2002	JNE $+6, goes to  0084
 0080	     934D	CMP.B #0,R13
 0082	     23FB	JNE $-8, goes to  007A
 0084	     2802	JNC $+6, goes to  008A
 0086	     431F	MOV #1,R15
 0088	     3C01	JMP $+4, goes to  008C
 008A	     430F	MOV #0,R15
 008C	     4FC1	MOV.B R15,20(SP)
 008E	     0014
 0090	     410F	MOV SP,R15
 0092	     403E	MOV #0,R14
 0094	     0000
 0096	     4F7D	MOV.B @R15+,R13
 0098	     9E7D	CMP.B @R14+,R13
 009A	     2002	JNE $+6, goes to  00A0
 009C	     934D	CMP.B #0,R13
 009E	     23FB	JNE $-8, goes to  0096
 00A0	     2402	JEQ $+6, goes to  00A6
 00A2	     431F	MOV #1,R15
 00A4	     3C01	JMP $+4, goes to  00A8
 00A6	     430F	MOV #0,R15
 00A8	     4FC1	MOV.B R15,20(SP)
 00AA	     0014
 00AC	     403F	MOV #9,R15
 00AE	     0009
 00B0	     410E	MOV SP,R14
 00B2	     4E7D	MOV.B @R14+,R13
 00B4	     9F7D	CMP.B @R15+,R13
 00B6	     2002	JNE $+6, goes to  00BC
 00B8	     934D	CMP.B #0,R13
 00BA	     23FB	JNE $-8, goes to  00B2
 00BC	     2C02	JC $+6, goes to  00C2
 00BE	     431F	MOV #1,R15
 00C0	     3C01	JMP $+4, goes to  00C4
 00C2	     430F	MOV #0,R15
 00C4	     4FC1	MOV.B R15,20(SP)
 00C6	     0014
 00C8	     403F	MOV #37,R15
 00CA	     0025
 00CC	     410E	MOV SP,R14
 00CE	     4F7D	MOV.B @R15+,R13
 00D0	     9E7D	CMP.B @R14+,R13
 00D2	     2002	JNE $+6, goes to  00D8
 00D4	     934D	CMP.B #0,R13
 00D6	     23FB	JNE $-8, goes to  00CE
 00D8	     2802	JNC $+6, goes to  00DE
 00DA	     431F	MOV #1,R15
 00DC	     3C01	JMP $+4, goes to  00E0
 00DE	     430F	MOV #0,R15
 00E0	     4FC1	MOV.B R15,20(SP)
 00E2	     0014
 00E4	     403F	MOV #65,R15
 00E6	     0041
 00E8	     410E	MOV SP,R14
 00EA	     4F7D	MOV.B @R15+,R13
 00EC	     9E7D	CMP.B @R14+,R13
 00EE	     2002	JNE $+6, goes to  00F4
 00F0	     934D	CMP.B #0,R13
 00F2	     23FB	JNE $-8, goes to  00EA
 00F4	     2002	JNE $+6, goes to  00FA
 00F6	     431F	MOV #1,R15
 00F8	     3C01	JMP $+4, goes to  00FC
 00FA	     430F	MOV #0,R15
 00FC	     4FC1	MOV.B R15,20(SP)
 00FE	     0014
 0100	     403F	MOV #93,R15
 0102	     005D
 0104	     410E	MOV SP,R14
 0106	     4F7D	MOV.B @R15+,R13
 0108	     9E7D	CMP.B @R14+,R13
 010A	     2002	JNE $+6, goes to  0110
 010C	     934D	CMP.B #0,R13
 010E	     23FB	JNE $-8, goes to  0106
 0110	     2C02	JC $+6, goes to  0116
 0112	     431F	MOV #1,R15
 0114	     3C01	JMP $+4, goes to  0118
 0116	     430F	MOV #0,R15
 0118	     4FC1	MOV.B R15,20(SP)
 011A	     0014
 011C	     403F	MOV #121,R15
 011E	     0079
 0120	     410E	MOV SP,R14
 0122	     4E7D	MOV.B @R14+,R13
 0124	     9F7D	CMP.B @R15+,R13
 0126	     2002	JNE $+6, goes to  012C
 0128	     934D	CMP.B #0,R13
 012A	     23FB	JNE $-8, goes to  0122
 012C	     2802	JNC $+6, goes to  0132
 012E	     431F	MOV #1,R15
 0130	     3C01	JMP $+4, goes to  0134
 0132	     430F	MOV #0,R15
 0134	     4FC1	MOV.B R15,20(SP)
 0136	     0014
 0138	     403F	MOV #149,R15
 013A	     0095
 013C	     410E	MOV SP,R14
 013E	     4F7D	MOV.B @R15+,R13
 0140	     9E7D	CMP.B @R14+,R13
 0142	     2002	JNE $+6, goes to  0148
 0144	     934D	CMP.B #0,R13
 0146	     23FB	JNE $-8, goes to  013E
 0148	     2402	JEQ $+6, goes to  014E
 014A	     431F	MOV #1,R15
 014C	     3C01	JMP $+4, goes to  0150
 014E	     430F	MOV #0,R15
 0150	     4FC1	MOV.B R15,20(SP)
 0152	     0014
 0154	     410F	MOV SP,R15
 0156	     410E	MOV SP,R14
 0158	     503E	ADD #10,R14
 015A	     000A
 015C	     4E7D	MOV.B @R14+,R13
 015E	     9F7D	CMP.B @R15+,R13
 0160	     2002	JNE $+6, goes to  0166
 0162	     934D	CMP.B #0,R13
 0164	     23FB	JNE $-8, goes to  015C
 0166	     2C02	JC $+6, goes to  016C
 0168	     431F	MOV #1,R15
 016A	     3C01	JMP $+4, goes to  016E
 016C	     430F	MOV #0,R15
 016E	     4FC1	MOV.B R15,20(SP)
 0170	     0014
 0172	     410F	MOV SP,R15
 0174	     410E	MOV SP,R14
 0176	     503E	ADD #10,R14
 0178	     000A
 017A	     4F7D	MOV.B @R15+,R13
 017C	     9E7D	CMP.B @R14+,R13
 017E	     2002	JNE $+6, goes to  0184
 0180	     934D	CMP.B #0,R13
 0182	     23FB	JNE $-8, goes to  017A
 0184	     2802	JNC $+6, goes to  018A
 0186	     431F	MOV #1,R15
 0188	     3C01	JMP $+4, goes to  018C
 018A	     430F	MOV #0,R15
 018C	     4FC1	MOV.B R15,20(SP)
 018E	     0014
 0190	     410F	MOV SP,R15
 0192	     410E	MOV SP,R14
 0194	     503E	ADD #10,R14
 0196	     000A
 0198	     4F7D	MOV.B @R15+,R13
 019A	     9E7D	CMP.B @R14+,R13
 019C	     2002	JNE $+6, goes to  01A2
 019E	     934D	CMP.B #0,R13
 01A0	     23FB	JNE $-8, goes to  0198
 01A2	     2002	JNE $+6, goes to  01A8
 01A4	     431F	MOV #1,R15
 01A6	     3C01	JMP $+4, goes to  01AA
 01A8	     430F	MOV #0,R15
 01AA	     4FC1	MOV.B R15,20(SP)
 01AC	     0014
 01AE	     410F	MOV SP,R15
 01B0	     410E	MOV SP,R14
 01B2	     503E	ADD #10,R14
 01B4	     000A
 01B6	     4F7D	MOV.B @R15+,R13
 01B8	     9E7D	CMP.B @R14+,R13
 01BA	     2002	JNE $+6, goes to  01C0
 01BC	     934D	CMP.B #0,R13
 01BE	     23FB	JNE $-8, goes to  01B6
 01C0	     2C02	JC $+6, goes to  01C6
 01C2	     431F	MOV #1,R15
 01C4	     3C01	JMP $+4, goes to  01C8
 01C6	     430F	MOV #0,R15
 01C8	     4FC1	MOV.B R15,20(SP)
 01CA	     0014
 01CC	     410F	MOV SP,R15
 01CE	     410E	MOV SP,R14
 01D0	     503E	ADD #10,R14
 01D2	     000A
 01D4	     4E7D	MOV.B @R14+,R13
 01D6	     9F7D	CMP.B @R15+,R13
 01D8	     2002	JNE $+6, goes to  01DE
 01DA	     934D	CMP.B #0,R13
 01DC	     23FB	JNE $-8, goes to  01D4
 01DE	     2802	JNC $+6, goes to  01E4
 01E0	     431F	MOV #1,R15
 01E2	     3C01	JMP $+4, goes to  01E6
 01E4	     430F	MOV #0,R15
 01E6	     4FC1	MOV.B R15,20(SP)
 01E8	     0014
 01EA	     410F	MOV SP,R15
 01EC	     410E	MOV SP,R14
 01EE	     503E	ADD #10,R14
 01F0	     000A
 01F2	     4F7D	MOV.B @R15+,R13
 01F4	     9E7D	CMP.B @R14+,R13
 01F6	     2002	JNE $+6, goes to  01FC
 01F8	     934D	CMP.B #0,R13
 01FA	     23FB	JNE $-8, goes to  01F2
 01FC	     2402	JEQ $+6, goes to  0202
 01FE	     431F	MOV #1,R15
 0200	     3C01	JMP $+4, goes to  0204
 0202	     430F	MOV #0,R15
 0204	     4FC1	MOV.B R15,20(SP)
 0206	     0014
 0208	     5031	ADD #22,SP
 020A	     0016
 020C	     4130	RET
fixups:
 013B	s0.6
 011F	s0.5
 0103	s0.4
 00E7	s0.3
 00CB	s0.2
 00AF	s0.1

section     1	s    4	
1.||
fixups:

section     2	s    4	
2.||
fixups:

section     3	s    4	
3.||
fixups:

section     4	s    4	
-1.|
fixups:

section     5	s    4	
-2.|
fixups:

section     6	s    4	
-3.|
fixups:

section     7	c    2	module body
 0000	     4130	RET
fixups:

section     8	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    7    0
