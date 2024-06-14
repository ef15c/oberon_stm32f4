MODULE Traps; (*runtime module implementing the trap handlers*)
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE AssertionViolated*;
   BEGIN
    SYSTEM.BIS(M.P1OUT, {0}); (*turn LED on*)
    REPEAT UNTIL FALSE
  END AssertionViolated;

END Traps.

OMSPTool.DecObj Traps.mpc

decode Traps.mpc
Traps D8CD5C84    30
imports:
	msp430g2553 60723399
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
	Assert 0000
entries
 0008 0000
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0008
code    10
 00000000	     D3D2	BIS.B #1,&33
 00000002	     0021
 00000004	     3FFF	JMP #-1, goes to  00000004
 00000006	     4130	RET
 00000008	     4130	RET
