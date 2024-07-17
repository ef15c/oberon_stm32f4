MODULE Traps; (*runtime module implementing the trap handlers*)

(*----------------------------------------------------------------*)
(*--- W A R N I N G : never change interfaces of the functions in this module ---*)
(*however, you can comment an unused function here to free some program space*)
(*----------------------------------------------------------------*)

  IMPORT M := msp430g2553;

  PROCEDURE AssertionViolated*;
   BEGIN
    BIS(M.P1OUT, {0}); (*turn LED on*)
    REPEAT UNTIL FALSE
  END AssertionViolated;

  PROCEDURE TypeGuardFailure*;
   BEGIN
    BIS(M.P1OUT, {1}); (*turn LED on*)
    REPEAT UNTIL FALSE
  END TypeGuardFailure;

END Traps.

OMSPTool.DecObj Traps.mpc

decode Traps.mpc
Traps 8AC7BA63    70
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
	TypeGuardFailure 0008
entries
 0010 0000 0008
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0010
code    18
 0000	     D3D2	BIS.B #1,&33
 0002	     0021
 0004	     3FFF	JMP #-1, goes to  0004
 0006	     4130	RET
 0008	     D3E2	BIS.B #2,&33
 000A	     0021
 000C	     3FFF	JMP #-1, goes to  000C
 000E	     4130	RET
 0010	     4130	RET
