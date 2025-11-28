MODULE Traps; (*runtime module implementing the trap handlers*)

(*----------------------------------------------------------------*)
(*--- W A R N I N G : never change interfaces of the functions in this module ---*)
(*however, you can comment an unused function here to free some program space*)
(*----------------------------------------------------------------*)

  IMPORT M := msp430g2553;

  PROCEDURE ArrayOutOfRange*;
   BEGIN M.P1OUT^ := {2}; (*turn all LEDs off except LED 2*)
    REPEAT UNTIL FALSE
  END ArrayOutOfRange;

  PROCEDURE TypeGuardFailure*;
   BEGIN
    BIS(M.P1OUT^, {1}); (*turn LED 1 on*)
    REPEAT UNTIL FALSE
  END TypeGuardFailure;

  PROCEDURE AssertionViolated*;
   BEGIN
    BIS(M.P1OUT^, {0}); (*turn LED 0 on*)
    REPEAT UNTIL FALSE
  END AssertionViolated;

END Traps.

OMSPTool.DecObj Traps.mpc
decode Traps.mpc
Traps 3714F611
imports:
	msp430g2553 1CD85DB4

section     0	c    8	ArrayOutOfRange
 0000	     42E2	MOV.B #4,&33
 0002	     0021
 0004	     3FFF	JMP $, goes to  0004
 0006	     4130	RET
fixups:

section     1	c    8	TypeGuardFailure
 0000	     D3E2	BIS.B #2,&33
 0002	     0021
 0004	     3FFF	JMP $, goes to  0004
 0006	     4130	RET
fixups:

section     2	c    8	AssertionViolated
 0000	     D3D2	BIS.B #1,&33
 0002	     0021
 0004	     3FFF	JMP $, goes to  0004
 0006	     4130	RET
fixups:

section     3	c    2	module body
 0000	     4130	RET
fixups:

section     4	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    3    0    1    2

OMSPTool.DecSym Traps.sms
decode Traps.sms
Traps 3714F611  2
   9 ArrayOutOfRange [0  form = 10 [^9] UR 0000()]     1
   9 TypeGuardFailure [0  form = 10 [^9] UR 0000()]     2
   9 AssertionViolated [0  form = 10 [^9] UR 0000()]     3
