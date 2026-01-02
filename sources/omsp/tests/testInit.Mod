MODULE testInit;
  IMPORT M := msp430g2553;

  PROCEDURE toggleP10*;
  BEGIN XOR(M.P1OUT^, {0})
  END toggleP10;

BEGIN BIS(M.P1DIR^, {0})
END testInit.

OMSPTool.DecObj testInit.mpc
decode testInit.mpc
testInit 1B108661
imports:
	msp430g2553 BBD31A01

section     0	c    6	toggleP10
 0000	     E3D2	XOR.B #1,&33
 0002	     0021
 0004	     4130	RET
fixups:

section     1	c    6	module body
 0000	     D3D2	BIS.B #1,&34
 0002	     0022
 0004	     4130	RET
fixups:

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1    0

OMSPTool.DecSym testInit.sms
decode testInit.sms
testInit 1B108661  3
   9 toggleP10 [0  form = 10 [^9] UR 0000()]     1
