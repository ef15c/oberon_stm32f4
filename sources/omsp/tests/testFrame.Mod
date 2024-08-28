MODULE testFrame;

  PROCEDURE p(i: ARRAY OF INTEGER; j, k: INTEGER);
  BEGIN
  END p;

  PROCEDURE q;
    VAR a: ARRAY 5 OF INTEGER; b, c: INTEGER;
  BEGIN p(a, b, c)
  END q;

END testFrame.

OMSPTool.DecObj testFrame.mpc
decode testFrame.mpc
testFrame E1D5D81F Flash    40
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0026
fixup procedures chains
 001C     0	 0000
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0026
code    40
 0000	     4130	RET
 0002	     8031	SUB #14,SP
 0004	     000E
 0006	     1230	PUSH #5
 0008	     0005
 000A	     410F	MOV SP,R15
 000C	     503F	ADD #6,R15
 000E	     0006
 0010	     120F	PUSH R15
 0012	     1211	PUSH 8(SP)
 0014	     0008
 0016	     1211	PUSH 8(SP)
 0018	     0008
 001A	     12B0	CALL #0
 001C	     0000
 001E	     5231	ADD #8,SP
 0020	     5031	ADD #14,SP
 0022	     000E
 0024	     4130	RET
 0026	     4130	RET
