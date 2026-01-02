MODULE testVector;
  IMPORT M := msp430g2553;

PROCEDURE*(M.TRAPINT_VECTOR, M.PORT1_VECTOR, M.PORT2_VECTOR) {} dummy;
END dummy;

BEGIN REPEAT UNTIL FALSE
END testVector.

OMSPL.Link 32 4000H 200H testVector ~
  linking msp430g2553 testVector
    flash   20, data    0, stack  512 bytes

OMSPTool.DecObj testVector.mpc
decode testVector.mpc
testVector 3B656A05
imports:
	msp430g2553 BBD31A01

section     0	c    2	dummy
 0000	     1300	RETI
fixups:

section     1	c    4	module body
 0000	     3FFF	JMP $, goes to  0000
 0002	     4130	RET
fixups:

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 0025 FFFF 0027 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:
 0021	s0.0

entries:
    1
