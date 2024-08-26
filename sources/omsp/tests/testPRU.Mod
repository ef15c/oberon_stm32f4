MODULE testPRU;

  PROCEDURE p;
    VAR a: INTEGER*;
  BEGIN INC(a)
  END p;

  PROCEDURE*(10)^0 testRU0*;
  BEGIN p
  END testRU0;

END testPRU.

OMSPTool.DecObj testPRU.mpc
decode testPRU.mpc
testPRU 3E932D6A Flash    16
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 000E 0004
fixup procedures chains
 0008     0	 0000
fixup handlers chains
 000A     0	 0004
fixup data chains
fixup constants chains
fixup types chains
entry =  000E
code    16
 0000	     5314	ADD #1,R4
 0002	     4130	RET
 0004	     1204	PUSH R4
 0006	     12B0	CALL #0
 0008	     0000
 000A	     4134	POP R4
 000C	     1300	RETI
 000E	     4130	RET

OMSPTool.DecSym testPRU.sms
decode testPRU.sms
testPRU 3E932D6A  1
   1 testRU0 [0  form = 15  size = 2]       4
