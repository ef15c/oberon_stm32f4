MODULE testVarParam;

  PROCEDURE p(a: ARRAY OF INTEGER);
  END p;

  PROCEDURE p0(a: ARRAY OF INTEGER*);
  END p0;

  PROCEDURE q(a: ARRAY OF INTEGER);
  BEGIN p(a); p0(a)
  END q;

END testVarParam.

OMSPTool.DecObj testVarParam.mpc
decode testVarParam.mpc
testVarParam 50756D5E Flash    34
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0020
fixup procedures chains
 000E     0	 0000
 001C     0	 0002
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0020
code    34
 0000	     4130	RET
 0002	     4130	RET
 0004	     1211	PUSH 6(SP)
 0006	     0006
 0008	     1211	PUSH 6(SP)
 000A	     0006
 000C	     12B0	CALL #0
 000E	     0000
 0010	     5221	ADD #4,SP
 0012	     4114	MOV 2(SP),R4
 0014	     0002
 0016	     4115	MOV 4(SP),R5
 0018	     0004
 001A	     12B0	CALL #0
 001C	     0000
 001E	     4130	RET
 0020	     4130	RET
