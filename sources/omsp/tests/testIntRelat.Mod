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

END testIntRelat.

OMSPTool.DecObj testIntRelat.mpc

not leaf:
decode testIntRelat.mpc
testIntRelat 3B494122 Flash   336
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 014E
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  014E
code   336
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
 014E	     4130	RET

leaf:
decode testIntRelat.mpc
testIntRelat 3B494122 Flash   244
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 00F2
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  00F2
code   244
 0000	     4317	MOV #1,R7
 0002	     9407	CMP R4,R7
 0004	     3402	JGE #2, goes to  000A
 0006	     4317	MOV #1,R7
 0008	     3C01	JMP #1, goes to  000C
 000A	     4307	MOV #0,R7
 000C	     4746	MOV.B R7,R6
 000E	     9324	CMP #2,R4
 0010	     3802	JL #2, goes to  0016
 0012	     4317	MOV #1,R7
 0014	     3C01	JMP #1, goes to  0018
 0016	     4307	MOV #0,R7
 0018	     4746	MOV.B R7,R6
 001A	     9034	CMP #3,R4
 001C	     0003
 001E	     2002	JNE #2, goes to  0024
 0020	     4317	MOV #1,R7
 0022	     3C01	JMP #1, goes to  0026
 0024	     4307	MOV #0,R7
 0026	     4746	MOV.B R7,R6
 0028	     9334	CMP #-1,R4
 002A	     3402	JGE #2, goes to  0030
 002C	     4317	MOV #1,R7
 002E	     3C01	JMP #1, goes to  0032
 0030	     4307	MOV #0,R7
 0032	     4746	MOV.B R7,R6
 0034	     4037	MOV #-2,R7
 0036	     FFFE
 0038	     9407	CMP R4,R7
 003A	     3802	JL #2, goes to  0040
 003C	     4317	MOV #1,R7
 003E	     3C01	JMP #1, goes to  0042
 0040	     4307	MOV #0,R7
 0042	     4746	MOV.B R7,R6
 0044	     9034	CMP #-3,R4
 0046	     FFFD
 0048	     2402	JEQ #2, goes to  004E
 004A	     4317	MOV #1,R7
 004C	     3C01	JMP #1, goes to  0050
 004E	     4307	MOV #0,R7
 0050	     4746	MOV.B R7,R6
 0052	     9314	CMP #1,R4
 0054	     3402	JGE #2, goes to  005A
 0056	     4317	MOV #1,R7
 0058	     3C01	JMP #1, goes to  005C
 005A	     4307	MOV #0,R7
 005C	     4746	MOV.B R7,R6
 005E	     4327	MOV #2,R7
 0060	     9407	CMP R4,R7
 0062	     3802	JL #2, goes to  0068
 0064	     4317	MOV #1,R7
 0066	     3C01	JMP #1, goes to  006A
 0068	     4307	MOV #0,R7
 006A	     4746	MOV.B R7,R6
 006C	     4037	MOV #3,R7
 006E	     0003
 0070	     9407	CMP R4,R7
 0072	     2002	JNE #2, goes to  0078
 0074	     4317	MOV #1,R7
 0076	     3C01	JMP #1, goes to  007A
 0078	     4307	MOV #0,R7
 007A	     4746	MOV.B R7,R6
 007C	     4337	MOV #-1,R7
 007E	     9407	CMP R4,R7
 0080	     3402	JGE #2, goes to  0086
 0082	     4317	MOV #1,R7
 0084	     3C01	JMP #1, goes to  0088
 0086	     4307	MOV #0,R7
 0088	     4746	MOV.B R7,R6
 008A	     9034	CMP #-2,R4
 008C	     FFFE
 008E	     3802	JL #2, goes to  0094
 0090	     4317	MOV #1,R7
 0092	     3C01	JMP #1, goes to  0096
 0094	     4307	MOV #0,R7
 0096	     4746	MOV.B R7,R6
 0098	     4037	MOV #-3,R7
 009A	     FFFD
 009C	     9407	CMP R4,R7
 009E	     2402	JEQ #2, goes to  00A4
 00A0	     4317	MOV #1,R7
 00A2	     3C01	JMP #1, goes to  00A6
 00A4	     4307	MOV #0,R7
 00A6	     4746	MOV.B R7,R6
 00A8	     9405	CMP R4,R5
 00AA	     3402	JGE #2, goes to  00B0
 00AC	     4317	MOV #1,R7
 00AE	     3C01	JMP #1, goes to  00B2
 00B0	     4307	MOV #0,R7
 00B2	     4746	MOV.B R7,R6
 00B4	     9504	CMP R5,R4
 00B6	     3802	JL #2, goes to  00BC
 00B8	     4317	MOV #1,R7
 00BA	     3C01	JMP #1, goes to  00BE
 00BC	     4307	MOV #0,R7
 00BE	     4746	MOV.B R7,R6
 00C0	     9504	CMP R5,R4
 00C2	     2002	JNE #2, goes to  00C8
 00C4	     4317	MOV #1,R7
 00C6	     3C01	JMP #1, goes to  00CA
 00C8	     4307	MOV #0,R7
 00CA	     4746	MOV.B R7,R6
 00CC	     9504	CMP R5,R4
 00CE	     3402	JGE #2, goes to  00D4
 00D0	     4317	MOV #1,R7
 00D2	     3C01	JMP #1, goes to  00D6
 00D4	     4307	MOV #0,R7
 00D6	     4746	MOV.B R7,R6
 00D8	     9405	CMP R4,R5
 00DA	     3802	JL #2, goes to  00E0
 00DC	     4317	MOV #1,R7
 00DE	     3C01	JMP #1, goes to  00E2
 00E0	     4307	MOV #0,R7
 00E2	     4746	MOV.B R7,R6
 00E4	     9504	CMP R5,R4
 00E6	     2402	JEQ #2, goes to  00EC
 00E8	     4317	MOV #1,R7
 00EA	     3C01	JMP #1, goes to  00EE
 00EC	     4307	MOV #0,R7
 00EE	     4746	MOV.B R7,R6
 00F0	     4130	RET
 00F2	     4130	RET
