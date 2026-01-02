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

OMSPL.Link 32 4000H 200H testFrame ~
  linking testFrame
    flash   56, data    0, stack  512 bytes

OMSPTool.DecObj testFrame.mpc
decode testFrame.mpc
testFrame 80E9A6F9
imports:

section     0	c    2	p
 0000	     4130	RET
fixups:

section     1	c   34	q
 0000	     8031	SUB #14,SP
 0002	     000E
 0004	     1230	PUSH #5
 0006	     0005
 0008	     410F	MOV SP,R15
 000A	     532F	ADD #2,R15
 000C	     120F	PUSH R15
 000E	     1211	PUSH 16(SP)
 0010	     0010
 0012	     1211	PUSH 20(SP)
 0014	     0014
 0016	     12B0	CALL #0
 0018	     0000
 001A	     5231	ADD #8,SP
 001C	     5031	ADD #14,SP
 001E	     000E
 0020	     4130	RET
fixups:
 0019	s0.0

section     2	c    6	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4130	RET
fixups:
 0003	s0.1

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2
