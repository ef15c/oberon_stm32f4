MODULE testVarParam;

  PROCEDURE p(a: ARRAY OF INTEGER);
  END p;

  PROCEDURE p0(a: ARRAY OF INTEGER*);
  END p0;

  PROCEDURE q*(a: ARRAY OF INTEGER);
  BEGIN p(a); p0(a)
  END q;

END testVarParam.

OMSPTool.DecObj testVarParam.mpc
decode testVarParam.mpc
testVarParam 3BDACA65
imports:

section     0	c    2	p
 0000	     4130	RET
fixups:

section     1	c    2	p0
 0000	     4130	RET
fixups:

section     2	c   28	q
 0000	     1211	PUSH 6(SP)
 0002	     0006
 0004	     1211	PUSH 6(SP)
 0006	     0006
 0008	     12B0	CALL #0
 000A	     0000
 000C	     5221	ADD #4,SP
 000E	     4114	MOV 2(SP),R4
 0010	     0002
 0012	     4115	MOV 4(SP),R5
 0014	     0004
 0016	     12B0	CALL #0
 0018	     0000
 001A	     4130	RET
fixups:
 0019	s0.1
 000B	s0.0

section     3	c    2	module body
 0000	     4130	RET
fixups:

section     4	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    3    2
