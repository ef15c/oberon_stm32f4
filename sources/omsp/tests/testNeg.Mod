MODULE testNeg;

  PROCEDURE p;
    VAR a: INTEGER;
  BEGIN a := -a;
  END p;

  PROCEDURE q;
    VAR a: INTEGER*;
  BEGIN a := -a;
  END q;

END testNeg.

OMSPTool.DecObj testNeg.mpc
decode testNeg.mpc
testNeg 2898F8BB Flash    28
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 001A
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  001A
code    28
 0000	     8321	SUB #2,SP
 0002	     412F	MOV @SP,R15
 0004	     E33F	XOR #-1,R15
 0006	     531F	ADD #1,R15
 0008	     4F81	MOV R15,0(SP)
 000A	     0000
 000C	     5321	ADD #2,SP
 000E	     4130	RET
 0010	     4405	MOV R4,R5
 0012	     E335	XOR #-1,R5
 0014	     5315	ADD #1,R5
 0016	     4504	MOV R5,R4
 0018	     4130	RET
 001A	     4130	RET
