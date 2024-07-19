MODULE testNeg;

  PROCEDURE p;
    VAR a: INTEGER*;
  BEGIN a := -a;
  END p;

END testNeg.

OMSPTool.DecObj testNeg.mpc

not leaf:
decode testNeg.mpc
testNeg 74DACAC3    24
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0010
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0010
code    18
 0000	     8321	SUB #2,SP
 0002	     412F	MOV @SP,R15
 0004	     E33F	XOR #-1,R15
 0006	     531F	ADD #1,R15
 0008	     4F81	MOV R15,0(SP)
 000A	     0000
 000C	     5321	ADD #2,SP
 000E	     4130	RET
 0010	     4130	RET

leaf:
decode testNeg.mpc
testNeg 74DACAC3    18
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 000A
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  000A
code    12
 0000	     4405	MOV R4,R5
 0002	     E335	XOR #-1,R5
 0004	     5315	ADD #1,R5
 0006	     4504	MOV R5,R4
 0008	     4130	RET
 000A	     4130	RET
