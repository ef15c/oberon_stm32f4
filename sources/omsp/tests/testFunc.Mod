MODULE testFunc;

  VAR i: INTEGER;

  PROCEDURE SumI(a, b: INTEGER): INTEGER;
  BEGIN
    RETURN a + b
  END SumI;

BEGIN
  i := i + SumI(1, 2)
END testFunc.

OMSPTool.DecObj testFunc.mpc

not leaf:
decode testFunc.mpc
testFunc D7E1DBBA Flash    32
imports:
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 000A
fixup procedures chains
 0010     0	 0000
fixup handlers chains
fixup data chains
 001C     0	 0000
fixup constants chains
fixup types chains
entry =  000A
code    32
 0000	     411F	MOV 4(SP),R15
 0002	     0004
 0004	     511F	ADD 2(SP),R15
 0006	     0002
 0008	     4130	RET
 000A	     1213	PUSH #1
 000C	     1223	PUSH #2
 000E	     12B0	CALL #0
 0010	     0000
 0012	     5221	ADD #4,SP
 0014	     421E	MOV &0,R14
 0016	     0000
 0018	     5F0E	ADD R15,R14
 001A	     4E82	MOV R14,&22
 001C	     0016
 001E	     4130	RET

leaf:
decode testFunc.mpc
testFunc D7E1DBBA Flash    26
imports:
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0006
fixup procedures chains
 000C     0	 0000
fixup handlers chains
fixup data chains
 0016     0	 0000
fixup constants chains
fixup types chains
entry =  0006
code    26
 0000	     4504	MOV R5,R4
 0002	     5604	ADD R6,R4
 0004	     4130	RET
 0006	     4315	MOV #1,R5
 0008	     4326	MOV #2,R6
 000A	     12B0	CALL #0
 000C	     0000
 000E	     421F	MOV &0,R15
 0010	     0000
 0012	     540F	ADD R4,R15
 0014	     4F82	MOV R15,&16
 0016	     0010
 0018	     4130	RET
