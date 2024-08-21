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
testIntRelat 3B494122 Flash   578
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0240
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0240
code   578
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     431F	MOV #1,R15
 0006	     911F	CMP 4(SP),R15
 0008	     0004
 000A	     3402	JGE #2, goes to  0010
 000C	     431F	MOV #1,R15
 000E	     3C01	JMP #1, goes to  0012
 0010	     430F	MOV #0,R15
 0012	     4FC1	MOV.B R15,1(SP)
 0014	     0001
 0016	     93A1	CMP #2,4(SP)
 0018	     0004
 001A	     3802	JL #2, goes to  0020
 001C	     431F	MOV #1,R15
 001E	     3C01	JMP #1, goes to  0022
 0020	     430F	MOV #0,R15
 0022	     4FC1	MOV.B R15,1(SP)
 0024	     0001
 0026	     90B1	CMP #3,4(SP)
 0028	     0003
 002A	     0004
 002C	     2002	JNE #2, goes to  0032
 002E	     431F	MOV #1,R15
 0030	     3C01	JMP #1, goes to  0034
 0032	     430F	MOV #0,R15
 0034	     4FC1	MOV.B R15,1(SP)
 0036	     0001
 0038	     93B1	CMP #-1,4(SP)
 003A	     0004
 003C	     3402	JGE #2, goes to  0042
 003E	     431F	MOV #1,R15
 0040	     3C01	JMP #1, goes to  0044
 0042	     430F	MOV #0,R15
 0044	     4FC1	MOV.B R15,1(SP)
 0046	     0001
 0048	     403F	MOV #-2,R15
 004A	     FFFE
 004C	     911F	CMP 4(SP),R15
 004E	     0004
 0050	     3802	JL #2, goes to  0056
 0052	     431F	MOV #1,R15
 0054	     3C01	JMP #1, goes to  0058
 0056	     430F	MOV #0,R15
 0058	     4FC1	MOV.B R15,1(SP)
 005A	     0001
 005C	     90B1	CMP #-3,4(SP)
 005E	     FFFD
 0060	     0004
 0062	     2402	JEQ #2, goes to  0068
 0064	     431F	MOV #1,R15
 0066	     3C01	JMP #1, goes to  006A
 0068	     430F	MOV #0,R15
 006A	     4FC1	MOV.B R15,1(SP)
 006C	     0001
 006E	     9391	CMP #1,4(SP)
 0070	     0004
 0072	     3402	JGE #2, goes to  0078
 0074	     431F	MOV #1,R15
 0076	     3C01	JMP #1, goes to  007A
 0078	     430F	MOV #0,R15
 007A	     4FC1	MOV.B R15,1(SP)
 007C	     0001
 007E	     432F	MOV #2,R15
 0080	     911F	CMP 4(SP),R15
 0082	     0004
 0084	     3802	JL #2, goes to  008A
 0086	     431F	MOV #1,R15
 0088	     3C01	JMP #1, goes to  008C
 008A	     430F	MOV #0,R15
 008C	     4FC1	MOV.B R15,1(SP)
 008E	     0001
 0090	     403F	MOV #3,R15
 0092	     0003
 0094	     911F	CMP 4(SP),R15
 0096	     0004
 0098	     2002	JNE #2, goes to  009E
 009A	     431F	MOV #1,R15
 009C	     3C01	JMP #1, goes to  00A0
 009E	     430F	MOV #0,R15
 00A0	     4FC1	MOV.B R15,1(SP)
 00A2	     0001
 00A4	     433F	MOV #-1,R15
 00A6	     911F	CMP 4(SP),R15
 00A8	     0004
 00AA	     3402	JGE #2, goes to  00B0
 00AC	     431F	MOV #1,R15
 00AE	     3C01	JMP #1, goes to  00B2
 00B0	     430F	MOV #0,R15
 00B2	     4FC1	MOV.B R15,1(SP)
 00B4	     0001
 00B6	     90B1	CMP #-2,4(SP)
 00B8	     FFFE
 00BA	     0004
 00BC	     3802	JL #2, goes to  00C2
 00BE	     431F	MOV #1,R15
 00C0	     3C01	JMP #1, goes to  00C4
 00C2	     430F	MOV #0,R15
 00C4	     4FC1	MOV.B R15,1(SP)
 00C6	     0001
 00C8	     403F	MOV #-3,R15
 00CA	     FFFD
 00CC	     911F	CMP 4(SP),R15
 00CE	     0004
 00D0	     2402	JEQ #2, goes to  00D6
 00D2	     431F	MOV #1,R15
 00D4	     3C01	JMP #1, goes to  00D8
 00D6	     430F	MOV #0,R15
 00D8	     4FC1	MOV.B R15,1(SP)
 00DA	     0001
 00DC	     9191	CMP 4(SP),2(SP)
 00DE	     0004
 00E0	     0002
 00E2	     3402	JGE #2, goes to  00E8
 00E4	     431F	MOV #1,R15
 00E6	     3C01	JMP #1, goes to  00EA
 00E8	     430F	MOV #0,R15
 00EA	     4FC1	MOV.B R15,1(SP)
 00EC	     0001
 00EE	     9191	CMP 2(SP),4(SP)
 00F0	     0002
 00F2	     0004
 00F4	     3802	JL #2, goes to  00FA
 00F6	     431F	MOV #1,R15
 00F8	     3C01	JMP #1, goes to  00FC
 00FA	     430F	MOV #0,R15
 00FC	     4FC1	MOV.B R15,1(SP)
 00FE	     0001
 0100	     9191	CMP 2(SP),4(SP)
 0102	     0002
 0104	     0004
 0106	     2002	JNE #2, goes to  010C
 0108	     431F	MOV #1,R15
 010A	     3C01	JMP #1, goes to  010E
 010C	     430F	MOV #0,R15
 010E	     4FC1	MOV.B R15,1(SP)
 0110	     0001
 0112	     9191	CMP 2(SP),4(SP)
 0114	     0002
 0116	     0004
 0118	     3402	JGE #2, goes to  011E
 011A	     431F	MOV #1,R15
 011C	     3C01	JMP #1, goes to  0120
 011E	     430F	MOV #0,R15
 0120	     4FC1	MOV.B R15,1(SP)
 0122	     0001
 0124	     9191	CMP 4(SP),2(SP)
 0126	     0004
 0128	     0002
 012A	     3802	JL #2, goes to  0130
 012C	     431F	MOV #1,R15
 012E	     3C01	JMP #1, goes to  0132
 0130	     430F	MOV #0,R15
 0132	     4FC1	MOV.B R15,1(SP)
 0134	     0001
 0136	     9191	CMP 2(SP),4(SP)
 0138	     0002
 013A	     0004
 013C	     2402	JEQ #2, goes to  0142
 013E	     431F	MOV #1,R15
 0140	     3C01	JMP #1, goes to  0144
 0142	     430F	MOV #0,R15
 0144	     4FC1	MOV.B R15,1(SP)
 0146	     0001
 0148	     5031	ADD #6,SP
 014A	     0006
 014C	     4130	RET
 014E	     4317	MOV #1,R7
 0150	     9407	CMP R4,R7
 0152	     3402	JGE #2, goes to  0158
 0154	     4317	MOV #1,R7
 0156	     3C01	JMP #1, goes to  015A
 0158	     4307	MOV #0,R7
 015A	     4746	MOV.B R7,R6
 015C	     9324	CMP #2,R4
 015E	     3802	JL #2, goes to  0164
 0160	     4317	MOV #1,R7
 0162	     3C01	JMP #1, goes to  0166
 0164	     4307	MOV #0,R7
 0166	     4746	MOV.B R7,R6
 0168	     9034	CMP #3,R4
 016A	     0003
 016C	     2002	JNE #2, goes to  0172
 016E	     4317	MOV #1,R7
 0170	     3C01	JMP #1, goes to  0174
 0172	     4307	MOV #0,R7
 0174	     4746	MOV.B R7,R6
 0176	     9334	CMP #-1,R4
 0178	     3402	JGE #2, goes to  017E
 017A	     4317	MOV #1,R7
 017C	     3C01	JMP #1, goes to  0180
 017E	     4307	MOV #0,R7
 0180	     4746	MOV.B R7,R6
 0182	     4037	MOV #-2,R7
 0184	     FFFE
 0186	     9407	CMP R4,R7
 0188	     3802	JL #2, goes to  018E
 018A	     4317	MOV #1,R7
 018C	     3C01	JMP #1, goes to  0190
 018E	     4307	MOV #0,R7
 0190	     4746	MOV.B R7,R6
 0192	     9034	CMP #-3,R4
 0194	     FFFD
 0196	     2402	JEQ #2, goes to  019C
 0198	     4317	MOV #1,R7
 019A	     3C01	JMP #1, goes to  019E
 019C	     4307	MOV #0,R7
 019E	     4746	MOV.B R7,R6
 01A0	     9314	CMP #1,R4
 01A2	     3402	JGE #2, goes to  01A8
 01A4	     4317	MOV #1,R7
 01A6	     3C01	JMP #1, goes to  01AA
 01A8	     4307	MOV #0,R7
 01AA	     4746	MOV.B R7,R6
 01AC	     4327	MOV #2,R7
 01AE	     9407	CMP R4,R7
 01B0	     3802	JL #2, goes to  01B6
 01B2	     4317	MOV #1,R7
 01B4	     3C01	JMP #1, goes to  01B8
 01B6	     4307	MOV #0,R7
 01B8	     4746	MOV.B R7,R6
 01BA	     4037	MOV #3,R7
 01BC	     0003
 01BE	     9407	CMP R4,R7
 01C0	     2002	JNE #2, goes to  01C6
 01C2	     4317	MOV #1,R7
 01C4	     3C01	JMP #1, goes to  01C8
 01C6	     4307	MOV #0,R7
 01C8	     4746	MOV.B R7,R6
 01CA	     4337	MOV #-1,R7
 01CC	     9407	CMP R4,R7
 01CE	     3402	JGE #2, goes to  01D4
 01D0	     4317	MOV #1,R7
 01D2	     3C01	JMP #1, goes to  01D6
 01D4	     4307	MOV #0,R7
 01D6	     4746	MOV.B R7,R6
 01D8	     9034	CMP #-2,R4
 01DA	     FFFE
 01DC	     3802	JL #2, goes to  01E2
 01DE	     4317	MOV #1,R7
 01E0	     3C01	JMP #1, goes to  01E4
 01E2	     4307	MOV #0,R7
 01E4	     4746	MOV.B R7,R6
 01E6	     4037	MOV #-3,R7
 01E8	     FFFD
 01EA	     9407	CMP R4,R7
 01EC	     2402	JEQ #2, goes to  01F2
 01EE	     4317	MOV #1,R7
 01F0	     3C01	JMP #1, goes to  01F4
 01F2	     4307	MOV #0,R7
 01F4	     4746	MOV.B R7,R6
 01F6	     9405	CMP R4,R5
 01F8	     3402	JGE #2, goes to  01FE
 01FA	     4317	MOV #1,R7
 01FC	     3C01	JMP #1, goes to  0200
 01FE	     4307	MOV #0,R7
 0200	     4746	MOV.B R7,R6
 0202	     9504	CMP R5,R4
 0204	     3802	JL #2, goes to  020A
 0206	     4317	MOV #1,R7
 0208	     3C01	JMP #1, goes to  020C
 020A	     4307	MOV #0,R7
 020C	     4746	MOV.B R7,R6
 020E	     9504	CMP R5,R4
 0210	     2002	JNE #2, goes to  0216
 0212	     4317	MOV #1,R7
 0214	     3C01	JMP #1, goes to  0218
 0216	     4307	MOV #0,R7
 0218	     4746	MOV.B R7,R6
 021A	     9504	CMP R5,R4
 021C	     3402	JGE #2, goes to  0222
 021E	     4317	MOV #1,R7
 0220	     3C01	JMP #1, goes to  0224
 0222	     4307	MOV #0,R7
 0224	     4746	MOV.B R7,R6
 0226	     9405	CMP R4,R5
 0228	     3802	JL #2, goes to  022E
 022A	     4317	MOV #1,R7
 022C	     3C01	JMP #1, goes to  0230
 022E	     4307	MOV #0,R7
 0230	     4746	MOV.B R7,R6
 0232	     9504	CMP R5,R4
 0234	     2402	JEQ #2, goes to  023A
 0236	     4317	MOV #1,R7
 0238	     3C01	JMP #1, goes to  023C
 023A	     4307	MOV #0,R7
 023C	     4746	MOV.B R7,R6
 023E	     4130	RET
 0240	     4130	RET
