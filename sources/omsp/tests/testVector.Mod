MODULE testVector;
  IMPORT M := msp430g2553;

PROCEDURE*(M.TRAPINT_VECTOR, M.PORT1_VECTOR, M.PORT2_VECTOR) {} dummy;
END dummy;

END testVector.

OMSPTool.DecObj testVector.mpc
decode testVector.mpc
testVector 8C26D391 Flash     4
imports:
	msp430g2553 F10488DC
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 0112 FFFF 0113 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0002
fixup procedures chains
fixup handlers chains
 0110     0	 0000
fixup data chains
fixup constants chains
fixup types chains
entry =  0002
code     4
 0000	     1300	RETI
 0002	     4130	RET
