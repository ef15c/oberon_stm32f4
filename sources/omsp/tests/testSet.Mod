MODULE testSet;
  IMPORT Arith;

  PROCEDURE p;
    VAR a, b, c: SET;
      m, n: INTEGER;
      t: BOOLEAN;
  BEGIN
    c := {2..5};
    c := {m..5};
    c := {2..n};
    c := {m..n};
    t := 10 IN a;
    t := m IN a;
    c := a*b;
    c := a+b;
    c := a-b;
    c := a/b
  END p;

END testSet.


OMSPTool.DecObj testSet.mpc
decode testSet.mpc
testSet 74E7CAC8 Flash   162
imports:
	Arith 80DF081C
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 00A0
fixup procedures chains
 0032     1	 0003
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  00A0
code   162
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     40B1	MOV #60,6(SP)
 0006	     003C
 0008	     0006
 000A	     4115	MOV 4(SP),R5
 000C	     0004
 000E	     4036	MOV #5,R6
 0010	     0005
 0012	     12B0	CALL #0
 0014	     0000
 0016	     4481	MOV R4,6(SP)
 0018	     0006
 001A	     4325	MOV #2,R5
 001C	     4116	MOV 2(SP),R6
 001E	     0002
 0020	     12B0	CALL #20
 0022	     0014
 0024	     4481	MOV R4,6(SP)
 0026	     0006
 0028	     4115	MOV 4(SP),R5
 002A	     0004
 002C	     4116	MOV 2(SP),R6
 002E	     0002
 0030	     12B0	CALL #34
 0032	     0022
 0034	     4481	MOV R4,6(SP)
 0036	     0006
 0038	     B0B1	BIT #1024,10(SP)
 003A	     0400
 003C	     000A
 003E	     2402	JEQ #2, goes to  0044
 0040	     431F	MOV #1,R15
 0042	     3C01	JMP #1, goes to  0046
 0044	     430F	MOV #0,R15
 0046	     4FC1	MOV.B R15,1(SP)
 0048	     0001
 004A	     411F	MOV 4(SP),R15
 004C	     0004
 004E	     411E	MOV 10(SP),R14
 0050	     000A
 0052	     531F	ADD #1,R15
 0054	     831F	SUB #1,R15
 0056	     2402	JEQ #2, goes to  005C
 0058	     100E	RRC R14
 005A	     3FFC	JMP #-4, goes to  0054
 005C	     B31E	BIT #1,R14
 005E	     2402	JEQ #2, goes to  0064
 0060	     431F	MOV #1,R15
 0062	     3C01	JMP #1, goes to  0066
 0064	     430F	MOV #0,R15
 0066	     4FC1	MOV.B R15,1(SP)
 0068	     0001
 006A	     411F	MOV 10(SP),R15
 006C	     000A
 006E	     F11F	AND 8(SP),R15
 0070	     0008
 0072	     4F81	MOV R15,6(SP)
 0074	     0006
 0076	     411F	MOV 10(SP),R15
 0078	     000A
 007A	     D11F	BIS 8(SP),R15
 007C	     0008
 007E	     4F81	MOV R15,6(SP)
 0080	     0006
 0082	     411F	MOV 10(SP),R15
 0084	     000A
 0086	     C11F	BIC 8(SP),R15
 0088	     0008
 008A	     4F81	MOV R15,6(SP)
 008C	     0006
 008E	     411F	MOV 10(SP),R15
 0090	     000A
 0092	     E11F	XOR 8(SP),R15
 0094	     0008
 0096	     4F81	MOV R15,6(SP)
 0098	     0006
 009A	     5031	ADD #12,SP
 009C	     000C
 009E	     4130	RET
 00A0	     4130	RET
