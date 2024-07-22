MODULE Traps; (*runtime module implementing the trap handlers*)

(*----------------------------------------------------------------*)
(*--- W A R N I N G : never change interfaces of the functions in this module ---*)
(*however, you can comment an unused function here to free some program space*)
(*----------------------------------------------------------------*)

  IMPORT M := msp430g2553;

  PROCEDURE ArrayOutOfRange*;
   BEGIN
    BIC(M.P1OUT, {0..7}); BIS(M.P1OUT, {2}); (*turn all LEDs off except LED 2*)
    REPEAT UNTIL FALSE
  END ArrayOutOfRange;

  PROCEDURE TypeGuardFailure*;
   BEGIN
    BIS(M.P1OUT, {1}); (*turn LED 1 on*)
    REPEAT UNTIL FALSE
  END TypeGuardFailure;

  PROCEDURE AssertionViolated*;
   BEGIN
    BIS(M.P1OUT, {0}); (*turn LED 0 on*)
    REPEAT UNTIL FALSE
  END AssertionViolated;

END Traps.

OMSPTool.DecObj Traps.mpc

decode Traps.mpc
Traps 45642D7E   102
imports:
	msp430g2553 60723399
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
	ArrayOutOfRange 0000
	TypeGuardFailure 000C
	AssertionViolated 0014
entries
 001C 0000 000C 0014
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  001C
code    30
 0000	     C3F2	BIC.B #-1,&33
 0002	     0021
 0004	     D2E2	BIS.B #4,&33
 0006	     0021
 0008	     3FFF	JMP #-1, goes to  0008
 000A	     4130	RET
 000C	     D3E2	BIS.B #2,&33
 000E	     0021
 0010	     3FFF	JMP #-1, goes to  0010
 0012	     4130	RET
 0014	     D3D2	BIS.B #1,&33
 0016	     0021
 0018	     3FFF	JMP #-1, goes to  0018
 001A	     4130	RET
 001C	     4130	RET
