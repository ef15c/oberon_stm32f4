MODULE testIntRelat;
    
PROCEDURE p;
    VAR a, b: INTEGER;
      t: BOOLEAN;
BEGIN
  t := a>1;
  t := a>=2;
  t := a=3;
  t := a<-1;
  t := a<=-2;
  t := a#-3;
  t := 1>a;
  t := 2>=a;
  t := 3=a;
  t := -1<a;
  t := -2<=a;
  t := -3#a;
  t := a>b;
  t := a>=b;
  t := a=b;
  t := a<b;
  t := a<=b;
  t := a#b
END p;

PROCEDURE q;
    VAR a, b: INTEGER*;
      t: BOOLEAN*;
BEGIN
  t := a>1;
  t := a>=2;
  t := a=3;
  t := a<-1;
  t := a<=-2;
  t := a#-3;
  t := 1>a;
  t := 2>=a;
  t := 3=a;
  t := -1<a;
  t := -2<=a;
  t := -3#a;
  t := a>b;
  t := a>=b;
  t := a=b;
  t := a<b;
  t := a<=b;
  t := a#b
END q;
END testIntRelat.

OMSPTool.DecObj testIntRelat.mpc
decode testIntRelat.mpc
testIntRelat ACB66DBF Flash   562
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0230
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0230
code   562
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     431F	MOV #1,R15
 0006	     912F	CMP @SP,R15
 0008	     3402	JGE #2, goes to  000E
 000A	     431F	MOV #1,R15
 000C	     3C01	JMP #1, goes to  0010
 000E	     430F	MOV #0,R15
 0010	     4FC1	MOV.B R15,4(SP)
 0012	     0004
 0014	     93A1	CMP #2,0(SP)
 0016	     0000
 0018	     3802	JL #2, goes to  001E
 001A	     431F	MOV #1,R15
 001C	     3C01	JMP #1, goes to  0020
 001E	     430F	MOV #0,R15
 0020	     4FC1	MOV.B R15,4(SP)
 0022	     0004
 0024	     90B1	CMP #3,0(SP)
 0026	     0003
 0028	     0000
 002A	     2002	JNE #2, goes to  0030
 002C	     431F	MOV #1,R15
 002E	     3C01	JMP #1, goes to  0032
 0030	     430F	MOV #0,R15
 0032	     4FC1	MOV.B R15,4(SP)
 0034	     0004
 0036	     93B1	CMP #-1,0(SP)
 0038	     0000
 003A	     3402	JGE #2, goes to  0040
 003C	     431F	MOV #1,R15
 003E	     3C01	JMP #1, goes to  0042
 0040	     430F	MOV #0,R15
 0042	     4FC1	MOV.B R15,4(SP)
 0044	     0004
 0046	     403F	MOV #-2,R15
 0048	     FFFE
 004A	     912F	CMP @SP,R15
 004C	     3802	JL #2, goes to  0052
 004E	     431F	MOV #1,R15
 0050	     3C01	JMP #1, goes to  0054
 0052	     430F	MOV #0,R15
 0054	     4FC1	MOV.B R15,4(SP)
 0056	     0004
 0058	     90B1	CMP #-3,0(SP)
 005A	     FFFD
 005C	     0000
 005E	     2402	JEQ #2, goes to  0064
 0060	     431F	MOV #1,R15
 0062	     3C01	JMP #1, goes to  0066
 0064	     430F	MOV #0,R15
 0066	     4FC1	MOV.B R15,4(SP)
 0068	     0004
 006A	     9391	CMP #1,0(SP)
 006C	     0000
 006E	     3402	JGE #2, goes to  0074
 0070	     431F	MOV #1,R15
 0072	     3C01	JMP #1, goes to  0076
 0074	     430F	MOV #0,R15
 0076	     4FC1	MOV.B R15,4(SP)
 0078	     0004
 007A	     432F	MOV #2,R15
 007C	     912F	CMP @SP,R15
 007E	     3802	JL #2, goes to  0084
 0080	     431F	MOV #1,R15
 0082	     3C01	JMP #1, goes to  0086
 0084	     430F	MOV #0,R15
 0086	     4FC1	MOV.B R15,4(SP)
 0088	     0004
 008A	     403F	MOV #3,R15
 008C	     0003
 008E	     912F	CMP @SP,R15
 0090	     2002	JNE #2, goes to  0096
 0092	     431F	MOV #1,R15
 0094	     3C01	JMP #1, goes to  0098
 0096	     430F	MOV #0,R15
 0098	     4FC1	MOV.B R15,4(SP)
 009A	     0004
 009C	     433F	MOV #-1,R15
 009E	     912F	CMP @SP,R15
 00A0	     3402	JGE #2, goes to  00A6
 00A2	     431F	MOV #1,R15
 00A4	     3C01	JMP #1, goes to  00A8
 00A6	     430F	MOV #0,R15
 00A8	     4FC1	MOV.B R15,4(SP)
 00AA	     0004
 00AC	     90B1	CMP #-2,0(SP)
 00AE	     FFFE
 00B0	     0000
 00B2	     3802	JL #2, goes to  00B8
 00B4	     431F	MOV #1,R15
 00B6	     3C01	JMP #1, goes to  00BA
 00B8	     430F	MOV #0,R15
 00BA	     4FC1	MOV.B R15,4(SP)
 00BC	     0004
 00BE	     403F	MOV #-3,R15
 00C0	     FFFD
 00C2	     912F	CMP @SP,R15
 00C4	     2402	JEQ #2, goes to  00CA
 00C6	     431F	MOV #1,R15
 00C8	     3C01	JMP #1, goes to  00CC
 00CA	     430F	MOV #0,R15
 00CC	     4FC1	MOV.B R15,4(SP)
 00CE	     0004
 00D0	     91A1	CMP @SP,2(SP)
 00D2	     0002
 00D4	     3402	JGE #2, goes to  00DA
 00D6	     431F	MOV #1,R15
 00D8	     3C01	JMP #1, goes to  00DC
 00DA	     430F	MOV #0,R15
 00DC	     4FC1	MOV.B R15,4(SP)
 00DE	     0004
 00E0	     9191	CMP 2(SP),0(SP)
 00E2	     0002
 00E4	     0000
 00E6	     3802	JL #2, goes to  00EC
 00E8	     431F	MOV #1,R15
 00EA	     3C01	JMP #1, goes to  00EE
 00EC	     430F	MOV #0,R15
 00EE	     4FC1	MOV.B R15,4(SP)
 00F0	     0004
 00F2	     9191	CMP 2(SP),0(SP)
 00F4	     0002
 00F6	     0000
 00F8	     2002	JNE #2, goes to  00FE
 00FA	     431F	MOV #1,R15
 00FC	     3C01	JMP #1, goes to  0100
 00FE	     430F	MOV #0,R15
 0100	     4FC1	MOV.B R15,4(SP)
 0102	     0004
 0104	     9191	CMP 2(SP),0(SP)
 0106	     0002
 0108	     0000
 010A	     3402	JGE #2, goes to  0110
 010C	     431F	MOV #1,R15
 010E	     3C01	JMP #1, goes to  0112
 0110	     430F	MOV #0,R15
 0112	     4FC1	MOV.B R15,4(SP)
 0114	     0004
 0116	     91A1	CMP @SP,2(SP)
 0118	     0002
 011A	     3802	JL #2, goes to  0120
 011C	     431F	MOV #1,R15
 011E	     3C01	JMP #1, goes to  0122
 0120	     430F	MOV #0,R15
 0122	     4FC1	MOV.B R15,4(SP)
 0124	     0004
 0126	     9191	CMP 2(SP),0(SP)
 0128	     0002
 012A	     0000
 012C	     2402	JEQ #2, goes to  0132
 012E	     431F	MOV #1,R15
 0130	     3C01	JMP #1, goes to  0134
 0132	     430F	MOV #0,R15
 0134	     4FC1	MOV.B R15,4(SP)
 0136	     0004
 0138	     5031	ADD #6,SP
 013A	     0006
 013C	     4130	RET
 013E	     4317	MOV #1,R7
 0140	     9407	CMP R4,R7
 0142	     3402	JGE #2, goes to  0148
 0144	     4317	MOV #1,R7
 0146	     3C01	JMP #1, goes to  014A
 0148	     4307	MOV #0,R7
 014A	     4746	MOV.B R7,R6
 014C	     9324	CMP #2,R4
 014E	     3802	JL #2, goes to  0154
 0150	     4317	MOV #1,R7
 0152	     3C01	JMP #1, goes to  0156
 0154	     4307	MOV #0,R7
 0156	     4746	MOV.B R7,R6
 0158	     9034	CMP #3,R4
 015A	     0003
 015C	     2002	JNE #2, goes to  0162
 015E	     4317	MOV #1,R7
 0160	     3C01	JMP #1, goes to  0164
 0162	     4307	MOV #0,R7
 0164	     4746	MOV.B R7,R6
 0166	     9334	CMP #-1,R4
 0168	     3402	JGE #2, goes to  016E
 016A	     4317	MOV #1,R7
 016C	     3C01	JMP #1, goes to  0170
 016E	     4307	MOV #0,R7
 0170	     4746	MOV.B R7,R6
 0172	     4037	MOV #-2,R7
 0174	     FFFE
 0176	     9407	CMP R4,R7
 0178	     3802	JL #2, goes to  017E
 017A	     4317	MOV #1,R7
 017C	     3C01	JMP #1, goes to  0180
 017E	     4307	MOV #0,R7
 0180	     4746	MOV.B R7,R6
 0182	     9034	CMP #-3,R4
 0184	     FFFD
 0186	     2402	JEQ #2, goes to  018C
 0188	     4317	MOV #1,R7
 018A	     3C01	JMP #1, goes to  018E
 018C	     4307	MOV #0,R7
 018E	     4746	MOV.B R7,R6
 0190	     9314	CMP #1,R4
 0192	     3402	JGE #2, goes to  0198
 0194	     4317	MOV #1,R7
 0196	     3C01	JMP #1, goes to  019A
 0198	     4307	MOV #0,R7
 019A	     4746	MOV.B R7,R6
 019C	     4327	MOV #2,R7
 019E	     9407	CMP R4,R7
 01A0	     3802	JL #2, goes to  01A6
 01A2	     4317	MOV #1,R7
 01A4	     3C01	JMP #1, goes to  01A8
 01A6	     4307	MOV #0,R7
 01A8	     4746	MOV.B R7,R6
 01AA	     4037	MOV #3,R7
 01AC	     0003
 01AE	     9407	CMP R4,R7
 01B0	     2002	JNE #2, goes to  01B6
 01B2	     4317	MOV #1,R7
 01B4	     3C01	JMP #1, goes to  01B8
 01B6	     4307	MOV #0,R7
 01B8	     4746	MOV.B R7,R6
 01BA	     4337	MOV #-1,R7
 01BC	     9407	CMP R4,R7
 01BE	     3402	JGE #2, goes to  01C4
 01C0	     4317	MOV #1,R7
 01C2	     3C01	JMP #1, goes to  01C6
 01C4	     4307	MOV #0,R7
 01C6	     4746	MOV.B R7,R6
 01C8	     9034	CMP #-2,R4
 01CA	     FFFE
 01CC	     3802	JL #2, goes to  01D2
 01CE	     4317	MOV #1,R7
 01D0	     3C01	JMP #1, goes to  01D4
 01D2	     4307	MOV #0,R7
 01D4	     4746	MOV.B R7,R6
 01D6	     4037	MOV #-3,R7
 01D8	     FFFD
 01DA	     9407	CMP R4,R7
 01DC	     2402	JEQ #2, goes to  01E2
 01DE	     4317	MOV #1,R7
 01E0	     3C01	JMP #1, goes to  01E4
 01E2	     4307	MOV #0,R7
 01E4	     4746	MOV.B R7,R6
 01E6	     9405	CMP R4,R5
 01E8	     3402	JGE #2, goes to  01EE
 01EA	     4317	MOV #1,R7
 01EC	     3C01	JMP #1, goes to  01F0
 01EE	     4307	MOV #0,R7
 01F0	     4746	MOV.B R7,R6
 01F2	     9504	CMP R5,R4
 01F4	     3802	JL #2, goes to  01FA
 01F6	     4317	MOV #1,R7
 01F8	     3C01	JMP #1, goes to  01FC
 01FA	     4307	MOV #0,R7
 01FC	     4746	MOV.B R7,R6
 01FE	     9504	CMP R5,R4
 0200	     2002	JNE #2, goes to  0206
 0202	     4317	MOV #1,R7
 0204	     3C01	JMP #1, goes to  0208
 0206	     4307	MOV #0,R7
 0208	     4746	MOV.B R7,R6
 020A	     9504	CMP R5,R4
 020C	     3402	JGE #2, goes to  0212
 020E	     4317	MOV #1,R7
 0210	     3C01	JMP #1, goes to  0214
 0212	     4307	MOV #0,R7
 0214	     4746	MOV.B R7,R6
 0216	     9405	CMP R4,R5
 0218	     3802	JL #2, goes to  021E
 021A	     4317	MOV #1,R7
 021C	     3C01	JMP #1, goes to  0220
 021E	     4307	MOV #0,R7
 0220	     4746	MOV.B R7,R6
 0222	     9504	CMP R5,R4
 0224	     2402	JEQ #2, goes to  022A
 0226	     4317	MOV #1,R7
 0228	     3C01	JMP #1, goes to  022C
 022A	     4307	MOV #0,R7
 022C	     4746	MOV.B R7,R6
 022E	     4130	RET
 0230	     4130	RET
