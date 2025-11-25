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
testNeg 25DBDE62
imports:

section     0	c   16	p
 0000	     8321	SUB #2,SP
 0002	     412F	MOV @SP,R15
 0004	     E33F	XOR #-1,R15
 0006	     531F	ADD #1,R15
 0008	     4F81	MOV R15,0(SP)
 000A	     0000
 000C	     5321	ADD #2,SP
 000E	     4130	RET
fixups:

section     1	c   10	q
 0000	     4405	MOV R4,R5
 0002	     E335	XOR #-1,R5
 0004	     5315	ADD #1,R5
 0006	     4504	MOV R5,R4
 0008	     4130	RET
fixups:

section     2	c   10	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     4130	RET
fixups:
 0007	s0.1
 0003	s0.0

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2
