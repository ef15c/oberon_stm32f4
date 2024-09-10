MODULE ISRTrap;
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE trap;
  BEGIN REPEAT SYSTEM.BIS_SR(M.LPM0_bits) UNTIL FALSE
  END trap;

END ISRTrap.

OMSPTool.DecObj ISRTrap.mpc
decode ISRTrap.mpc
ISRTrap 03D019F4 Flash    10
imports:
	msp430g2553 8250CA0E
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0008
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0008
code    10
 0000	     D032	BIS #16,SR
 0002	     0010
 0004	     3FFD	JMP #-3, goes to  0000
 0006	     4130	RET
 0008	     4130	RET
