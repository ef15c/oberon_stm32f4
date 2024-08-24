MODULE testVector;
  IMPORT M := msp430g2553;

PROCEDURE*(M.TRAPINT_VECTOR, M.PORT1_VECTOR, M.PORT2_VECTOR)^0 dummy*;
END dummy;

END testVector.

OMSPTool.DecObj testVector.mpc
decode testVector.mpc
testVector 574D1CB6 Flash     4
imports:
	msp430g2553 B7A7F8F7
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 0012 FFFF 0013 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0002 0000
fixup procedures chains
fixup handlers chains
 0010     0	 0000
fixup data chains
fixup constants chains
fixup types chains
entry =  0002
code     4
 0000	     1300	RETI
 0002	     4130	RET
