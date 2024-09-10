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
testSet B4D15A40 Flash   152
imports:
	Arith BDF2CFB8
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0096
fixup procedures chains
 0032     1	 0003
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0096
code   152
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     40B1	MOV #60,4(SP)
 0006	     003C
 0008	     0004
 000A	     4115	MOV 6(SP),R5
 000C	     0006
 000E	     4036	MOV #5,R6
 0010	     0005
 0012	     12B0	CALL #0
 0014	     0000
 0016	     4481	MOV R4,4(SP)
 0018	     0004
 001A	     4325	MOV #2,R5
 001C	     4116	MOV 8(SP),R6
 001E	     0008
 0020	     12B0	CALL #20
 0022	     0014
 0024	     4481	MOV R4,4(SP)
 0026	     0004
 0028	     4115	MOV 6(SP),R5
 002A	     0006
 002C	     4116	MOV 8(SP),R6
 002E	     0008
 0030	     12B0	CALL #34
 0032	     0022
 0034	     4481	MOV R4,4(SP)
 0036	     0004
 0038	     B0B1	BIT #1024,0(SP)
 003A	     0400
 003C	     0000
 003E	     2402	JEQ #2, goes to  0044
 0040	     431F	MOV #1,R15
 0042	     3C01	JMP #1, goes to  0046
 0044	     430F	MOV #0,R15
 0046	     4FC1	MOV.B R15,10(SP)
 0048	     000A
 004A	     411F	MOV 6(SP),R15
 004C	     0006
 004E	     412E	MOV @SP,R14
 0050	     531F	ADD #1,R15
 0052	     831F	SUB #1,R15
 0054	     2402	JEQ #2, goes to  005A
 0056	     100E	RRC R14
 0058	     3FFC	JMP #-4, goes to  0052
 005A	     B31E	BIT #1,R14
 005C	     2402	JEQ #2, goes to  0062
 005E	     431F	MOV #1,R15
 0060	     3C01	JMP #1, goes to  0064
 0062	     430F	MOV #0,R15
 0064	     4FC1	MOV.B R15,10(SP)
 0066	     000A
 0068	     412F	MOV @SP,R15
 006A	     F11F	AND 2(SP),R15
 006C	     0002
 006E	     4F81	MOV R15,4(SP)
 0070	     0004
 0072	     412F	MOV @SP,R15
 0074	     D11F	BIS 2(SP),R15
 0076	     0002
 0078	     4F81	MOV R15,4(SP)
 007A	     0004
 007C	     412F	MOV @SP,R15
 007E	     C11F	BIC 2(SP),R15
 0080	     0002
 0082	     4F81	MOV R15,4(SP)
 0084	     0004
 0086	     412F	MOV @SP,R15
 0088	     E11F	XOR 2(SP),R15
 008A	     0002
 008C	     4F81	MOV R15,4(SP)
 008E	     0004
 0090	     5031	ADD #12,SP
 0092	     000C
 0094	     4130	RET
 0096	     4130	RET
