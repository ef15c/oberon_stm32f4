MODULE testInit;
  IMPORT M := msp430g2553;

  PROCEDURE toggleP10*;
  BEGIN XOR(M.P1OUT^, {0})
  END toggleP10;

BEGIN BIS(M.P1DIR^, {0})
END testInit.

OMSPTool.DecObj testInit.mpc
decode testInit.mpc
testInit BBBED741 Flash    12
imports:
	msp430g2553 8250CA0E
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0006 0000
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0006
code    12
 0000	     E3D2	XOR.B #1,&33
 0002	     0021
 0004	     4130	RET
 0006	     D3D2	BIS.B #1,&34
 0008	     0022
 000A	     4130	RET

OMSPTool.DecSym testInit.sms
decode testInit.sms
testInit BBBED741  1
   1 toggleP10 [0  form = 10  size = 2 [^9] UR 0000()]       1
