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
testPRU 61E9F61B Flash    22
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0014 c 000E
fixup procedures chains
 0010     0	 0000
fixup handlers chains
 010A     0	 0004
fixup data chains
fixup constants chains
fixup types chains
entry =  0014
code    22
 0000	     5314	ADD #1,R4
 0002	     4130	RET
 0004	     1204	PUSH R4
 0006	     12B0	CALL #0
 0008	     0000
 000A	     4134	POP R4
 000C	     1300	RETI
 000E	     12B0	CALL #8
 0010	     0008
 0012	     4130	RET
 0014	     4130	RET

OMSPTool.DecSym testPRU.sms
decode testPRU.sms
testPRU 61E9F61B  1
   1 q [0  form = 10  size = 2 [^9] UR 0010()]       1
