MODULE testPRU;

  PROCEDURE p;
    VAR a: INTEGER*;
  BEGIN INC(a)
  END p;

  PROCEDURE*(10) {} testRU0;
  BEGIN p
  END testRU0;

  PROCEDURE q*;
  BEGIN p
  END q;

END testPRU.

OMSPTool.DecObj testPRU.mpc
decode testPRU.mpc
testPRU 3C8A0A2D
imports:

section     0	c    4	p
 0000	     5314	ADD #1,R4
 0002	     4130	RET
fixups:

section     1	c   10	testRU0
 0000	     1204	PUSH R4
 0002	     12B0	CALL #0
 0004	     0000
 0006	     4134	POP R4
 0008	     1300	RETI
fixups:
 0005	s0.0

section     2	c    6	q
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4130	RET
fixups:
 0003	s0.0

section     3	c    2	module body
 0000	     4130	RET
fixups:

section     4	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:
 0015	s0.0

entries:
    3    2

OMSPTool.DecSym testPRU.sms
decode testPRU.sms
testPRU 3C8A0A2D  3
   9 q [0  form = 10 [^9] UR 0010()]     1
