MODULE testFrame;

  PROCEDURE p(i: ARRAY OF INTEGER; j, k: INTEGER);
  BEGIN
  END p;

  PROCEDURE q;
    VAR a: ARRAY 5 OF INTEGER; b, c: INTEGER;
  BEGIN p(a, b, c)
  END q;

BEGIN q
END testFrame.

OMSPTool.DecObj testFrame.mpc
decode testFrame.mpc
testFrame 8358FFF7 Flash    42
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0024
fixup procedures chains
 001A     0	 0000
 0026     0	 0002
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0024
code    42
 0000	     4130	RET
 0002	     8031	SUB #14,SP
 0004	     000E
 0006	     1230	PUSH #5
 0008	     0005
 000A	     410F	MOV SP,R15
 000C	     532F	ADD #2,R15
 000E	     120F	PUSH R15
 0010	     1211	PUSH 16(SP)
 0012	     0010
 0014	     1211	PUSH 20(SP)
 0016	     0014
 0018	     12B0	CALL #0
 001A	     0000
 001C	     5231	ADD #8,SP
 001E	     5031	ADD #14,SP
 0020	     000E
 0022	     4130	RET
 0024	     12B0	CALL #0
 0026	     0000
 0028	     4130	RET
