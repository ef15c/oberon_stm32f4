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

BEGIN p; q
END testIntRelat.

OMSPP.Compile testIntRelat.Mod~
OMSPTool.DecObj testIntRelat.mpc
decode testIntRelat.mpc
testIntRelat DE5D326C
imports:

section     0	c  318	p
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     431F	MOV #1,R15
 0006	     912F	CMP @SP,R15
 0008	     3402	JGE $+6, goes to  000E
 000A	     431F	MOV #1,R15
 000C	     3C01	JMP $+4, goes to  0010
 000E	     430F	MOV #0,R15
 0010	     4FC1	MOV.B R15,4(SP)
 0012	     0004
 0014	     93A1	CMP #2,0(SP)
 0016	     0000
 0018	     3802	JL $+6, goes to  001E
 001A	     431F	MOV #1,R15
 001C	     3C01	JMP $+4, goes to  0020
 001E	     430F	MOV #0,R15
 0020	     4FC1	MOV.B R15,4(SP)
 0022	     0004
 0024	     90B1	CMP #3,0(SP)
 0026	     0003
 0028	     0000
 002A	     2002	JNE $+6, goes to  0030
 002C	     431F	MOV #1,R15
 002E	     3C01	JMP $+4, goes to  0032
 0030	     430F	MOV #0,R15
 0032	     4FC1	MOV.B R15,4(SP)
 0034	     0004
 0036	     93B1	CMP #-1,0(SP)
 0038	     0000
 003A	     3402	JGE $+6, goes to  0040
 003C	     431F	MOV #1,R15
 003E	     3C01	JMP $+4, goes to  0042
 0040	     430F	MOV #0,R15
 0042	     4FC1	MOV.B R15,4(SP)
 0044	     0004
 0046	     403F	MOV #-2,R15
 0048	     FFFE
 004A	     912F	CMP @SP,R15
 004C	     3802	JL $+6, goes to  0052
 004E	     431F	MOV #1,R15
 0050	     3C01	JMP $+4, goes to  0054
 0052	     430F	MOV #0,R15
 0054	     4FC1	MOV.B R15,4(SP)
 0056	     0004
 0058	     90B1	CMP #-3,0(SP)
 005A	     FFFD
 005C	     0000
 005E	     2402	JEQ $+6, goes to  0064
 0060	     431F	MOV #1,R15
 0062	     3C01	JMP $+4, goes to  0066
 0064	     430F	MOV #0,R15
 0066	     4FC1	MOV.B R15,4(SP)
 0068	     0004
 006A	     9391	CMP #1,0(SP)
 006C	     0000
 006E	     3402	JGE $+6, goes to  0074
 0070	     431F	MOV #1,R15
 0072	     3C01	JMP $+4, goes to  0076
 0074	     430F	MOV #0,R15
 0076	     4FC1	MOV.B R15,4(SP)
 0078	     0004
 007A	     432F	MOV #2,R15
 007C	     912F	CMP @SP,R15
 007E	     3802	JL $+6, goes to  0084
 0080	     431F	MOV #1,R15
 0082	     3C01	JMP $+4, goes to  0086
 0084	     430F	MOV #0,R15
 0086	     4FC1	MOV.B R15,4(SP)
 0088	     0004
 008A	     403F	MOV #3,R15
 008C	     0003
 008E	     912F	CMP @SP,R15
 0090	     2002	JNE $+6, goes to  0096
 0092	     431F	MOV #1,R15
 0094	     3C01	JMP $+4, goes to  0098
 0096	     430F	MOV #0,R15
 0098	     4FC1	MOV.B R15,4(SP)
 009A	     0004
 009C	     433F	MOV #-1,R15
 009E	     912F	CMP @SP,R15
 00A0	     3402	JGE $+6, goes to  00A6
 00A2	     431F	MOV #1,R15
 00A4	     3C01	JMP $+4, goes to  00A8
 00A6	     430F	MOV #0,R15
 00A8	     4FC1	MOV.B R15,4(SP)
 00AA	     0004
 00AC	     90B1	CMP #-2,0(SP)
 00AE	     FFFE
 00B0	     0000
 00B2	     3802	JL $+6, goes to  00B8
 00B4	     431F	MOV #1,R15
 00B6	     3C01	JMP $+4, goes to  00BA
 00B8	     430F	MOV #0,R15
 00BA	     4FC1	MOV.B R15,4(SP)
 00BC	     0004
 00BE	     403F	MOV #-3,R15
 00C0	     FFFD
 00C2	     912F	CMP @SP,R15
 00C4	     2402	JEQ $+6, goes to  00CA
 00C6	     431F	MOV #1,R15
 00C8	     3C01	JMP $+4, goes to  00CC
 00CA	     430F	MOV #0,R15
 00CC	     4FC1	MOV.B R15,4(SP)
 00CE	     0004
 00D0	     91A1	CMP @SP,2(SP)
 00D2	     0002
 00D4	     3402	JGE $+6, goes to  00DA
 00D6	     431F	MOV #1,R15
 00D8	     3C01	JMP $+4, goes to  00DC
 00DA	     430F	MOV #0,R15
 00DC	     4FC1	MOV.B R15,4(SP)
 00DE	     0004
 00E0	     9191	CMP 2(SP),0(SP)
 00E2	     0002
 00E4	     0000
 00E6	     3802	JL $+6, goes to  00EC
 00E8	     431F	MOV #1,R15
 00EA	     3C01	JMP $+4, goes to  00EE
 00EC	     430F	MOV #0,R15
 00EE	     4FC1	MOV.B R15,4(SP)
 00F0	     0004
 00F2	     9191	CMP 2(SP),0(SP)
 00F4	     0002
 00F6	     0000
 00F8	     2002	JNE $+6, goes to  00FE
 00FA	     431F	MOV #1,R15
 00FC	     3C01	JMP $+4, goes to  0100
 00FE	     430F	MOV #0,R15
 0100	     4FC1	MOV.B R15,4(SP)
 0102	     0004
 0104	     9191	CMP 2(SP),0(SP)
 0106	     0002
 0108	     0000
 010A	     3402	JGE $+6, goes to  0110
 010C	     431F	MOV #1,R15
 010E	     3C01	JMP $+4, goes to  0112
 0110	     430F	MOV #0,R15
 0112	     4FC1	MOV.B R15,4(SP)
 0114	     0004
 0116	     91A1	CMP @SP,2(SP)
 0118	     0002
 011A	     3802	JL $+6, goes to  0120
 011C	     431F	MOV #1,R15
 011E	     3C01	JMP $+4, goes to  0122
 0120	     430F	MOV #0,R15
 0122	     4FC1	MOV.B R15,4(SP)
 0124	     0004
 0126	     9191	CMP 2(SP),0(SP)
 0128	     0002
 012A	     0000
 012C	     2402	JEQ $+6, goes to  0132
 012E	     431F	MOV #1,R15
 0130	     3C01	JMP $+4, goes to  0134
 0132	     430F	MOV #0,R15
 0134	     4FC1	MOV.B R15,4(SP)
 0136	     0004
 0138	     5031	ADD #6,SP
 013A	     0006
 013C	     4130	RET
fixups:

section     1	c  242	q
 0000	     4317	MOV #1,R7
 0002	     9407	CMP R4,R7
 0004	     3402	JGE $+6, goes to  000A
 0006	     4317	MOV #1,R7
 0008	     3C01	JMP $+4, goes to  000C
 000A	     4307	MOV #0,R7
 000C	     4746	MOV.B R7,R6
 000E	     9324	CMP #2,R4
 0010	     3802	JL $+6, goes to  0016
 0012	     4317	MOV #1,R7
 0014	     3C01	JMP $+4, goes to  0018
 0016	     4307	MOV #0,R7
 0018	     4746	MOV.B R7,R6
 001A	     9034	CMP #3,R4
 001C	     0003
 001E	     2002	JNE $+6, goes to  0024
 0020	     4317	MOV #1,R7
 0022	     3C01	JMP $+4, goes to  0026
 0024	     4307	MOV #0,R7
 0026	     4746	MOV.B R7,R6
 0028	     9334	CMP #-1,R4
 002A	     3402	JGE $+6, goes to  0030
 002C	     4317	MOV #1,R7
 002E	     3C01	JMP $+4, goes to  0032
 0030	     4307	MOV #0,R7
 0032	     4746	MOV.B R7,R6
 0034	     4037	MOV #-2,R7
 0036	     FFFE
 0038	     9407	CMP R4,R7
 003A	     3802	JL $+6, goes to  0040
 003C	     4317	MOV #1,R7
 003E	     3C01	JMP $+4, goes to  0042
 0040	     4307	MOV #0,R7
 0042	     4746	MOV.B R7,R6
 0044	     9034	CMP #-3,R4
 0046	     FFFD
 0048	     2402	JEQ $+6, goes to  004E
 004A	     4317	MOV #1,R7
 004C	     3C01	JMP $+4, goes to  0050
 004E	     4307	MOV #0,R7
 0050	     4746	MOV.B R7,R6
 0052	     9314	CMP #1,R4
 0054	     3402	JGE $+6, goes to  005A
 0056	     4317	MOV #1,R7
 0058	     3C01	JMP $+4, goes to  005C
 005A	     4307	MOV #0,R7
 005C	     4746	MOV.B R7,R6
 005E	     4327	MOV #2,R7
 0060	     9407	CMP R4,R7
 0062	     3802	JL $+6, goes to  0068
 0064	     4317	MOV #1,R7
 0066	     3C01	JMP $+4, goes to  006A
 0068	     4307	MOV #0,R7
 006A	     4746	MOV.B R7,R6
 006C	     4037	MOV #3,R7
 006E	     0003
 0070	     9407	CMP R4,R7
 0072	     2002	JNE $+6, goes to  0078
 0074	     4317	MOV #1,R7
 0076	     3C01	JMP $+4, goes to  007A
 0078	     4307	MOV #0,R7
 007A	     4746	MOV.B R7,R6
 007C	     4337	MOV #-1,R7
 007E	     9407	CMP R4,R7
 0080	     3402	JGE $+6, goes to  0086
 0082	     4317	MOV #1,R7
 0084	     3C01	JMP $+4, goes to  0088
 0086	     4307	MOV #0,R7
 0088	     4746	MOV.B R7,R6
 008A	     9034	CMP #-2,R4
 008C	     FFFE
 008E	     3802	JL $+6, goes to  0094
 0090	     4317	MOV #1,R7
 0092	     3C01	JMP $+4, goes to  0096
 0094	     4307	MOV #0,R7
 0096	     4746	MOV.B R7,R6
 0098	     4037	MOV #-3,R7
 009A	     FFFD
 009C	     9407	CMP R4,R7
 009E	     2402	JEQ $+6, goes to  00A4
 00A0	     4317	MOV #1,R7
 00A2	     3C01	JMP $+4, goes to  00A6
 00A4	     4307	MOV #0,R7
 00A6	     4746	MOV.B R7,R6
 00A8	     9405	CMP R4,R5
 00AA	     3402	JGE $+6, goes to  00B0
 00AC	     4317	MOV #1,R7
 00AE	     3C01	JMP $+4, goes to  00B2
 00B0	     4307	MOV #0,R7
 00B2	     4746	MOV.B R7,R6
 00B4	     9504	CMP R5,R4
 00B6	     3802	JL $+6, goes to  00BC
 00B8	     4317	MOV #1,R7
 00BA	     3C01	JMP $+4, goes to  00BE
 00BC	     4307	MOV #0,R7
 00BE	     4746	MOV.B R7,R6
 00C0	     9504	CMP R5,R4
 00C2	     2002	JNE $+6, goes to  00C8
 00C4	     4317	MOV #1,R7
 00C6	     3C01	JMP $+4, goes to  00CA
 00C8	     4307	MOV #0,R7
 00CA	     4746	MOV.B R7,R6
 00CC	     9504	CMP R5,R4
 00CE	     3402	JGE $+6, goes to  00D4
 00D0	     4317	MOV #1,R7
 00D2	     3C01	JMP $+4, goes to  00D6
 00D4	     4307	MOV #0,R7
 00D6	     4746	MOV.B R7,R6
 00D8	     9405	CMP R4,R5
 00DA	     3802	JL $+6, goes to  00E0
 00DC	     4317	MOV #1,R7
 00DE	     3C01	JMP $+4, goes to  00E2
 00E0	     4307	MOV #0,R7
 00E2	     4746	MOV.B R7,R6
 00E4	     9504	CMP R5,R4
 00E6	     2402	JEQ $+6, goes to  00EC
 00E8	     4317	MOV #1,R7
 00EA	     3C01	JMP $+4, goes to  00EE
 00EC	     4307	MOV #0,R7
 00EE	     4746	MOV.B R7,R6
 00F0	     4130	RET
fixups:

section     2	c   10	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     4130	RET
fixups:
 0007	s0.1
 0003	s0.0

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2
