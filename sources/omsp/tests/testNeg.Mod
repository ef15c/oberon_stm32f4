MODULE testNeg;

  PROCEDURE p;
    VAR a: INTEGER;
  BEGIN a := -a;
  END p;

  PROCEDURE q;
    VAR a: INTEGER*;
  BEGIN a := -a;
  END q;

BEGIN p; q
END testNeg.

OMSPP.Compile testNeg.Mod~
OMSPTool.DecObj testNeg.mpc
decode testNeg.mpc
testNeg 2898F8BB Flash    36
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 001A
fixup procedures in code space chains
 001C     0	 0000
 0020     0	 0010
fixup handlers in vector space chains
fixup data in code space chains
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
entry =  001A
code    36
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
 001A	     12B0	CALL #0
 001C	     0000
 001E	     12B0	CALL #0
 0020	     0000
 0022	     4130	RET
