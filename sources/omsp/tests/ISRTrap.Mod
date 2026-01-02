MODULE ISRTrap;
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE trap*;
  BEGIN REPEAT SYSTEM.BIS_SR(M.LPM0_bits) UNTIL FALSE
  END trap;

END ISRTrap.

OMSPTool.DecObj ISRTrap.mpc
decode ISRTrap.mpc
ISRTrap B9595D97
imports:
	msp430g2553 BBD31A01

section     0	c    8	trap
 0000	     D032	BIS #16,SR
 0002	     0010
 0004	     3FFD	JMP $-4, goes to  0000
 0006	     4130	RET
fixups:

section     1	c    2	module body
 0000	     4130	RET
fixups:

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1    0
