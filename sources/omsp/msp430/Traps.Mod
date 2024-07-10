MODULE Traps; (*runtime module implementing the trap handlers*)
  IMPORT M := msp430g2553;

  PROCEDURE AssertionViolated*;
   BEGIN
    BIS(M.P1OUT, {0}); (*turn LED on*)
    REPEAT UNTIL FALSE
  END AssertionViolated;

END Traps.

OMSPTool.DecObj Traps.mpc

decode Traps.mpc
Traps 251F09BA    40
imports:
	msp430g2553 60723399
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
	AssertionViolated 0000
entries
 0008 0000
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0008
code    10
 0000	     D3D2	BIS.B #1,&33
 0002	     0021
 0004	     3FFF	JMP #-1, goes to  0004
 0006	     4130	RET
 0008	     4130	RET
