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
Traps 37B3757C Flash    26
imports:
	msp430g2553 8250CA0E
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0018 0000 0008 0010
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0018
code    26
 0000	     42E2	MOV.B #4,&33
 0002	     0021
 0004	     3FFF	JMP #-1, goes to  0004
 0006	     4130	RET
 0008	     D3E2	BIS.B #2,&33
 000A	     0021
 000C	     3FFF	JMP #-1, goes to  000C
 000E	     4130	RET
 0010	     D3D2	BIS.B #1,&33
 0012	     0021
 0014	     3FFF	JMP #-1, goes to  0014
 0016	     4130	RET
 0018	     4130	RET

OMSPTool.DecSym Traps.sms
decode Traps.sms
Traps 37B3757C  1
   1 ArrayOutOfRange [0  form = 10  size = 2 [^9] UR 0000()]       1
   1 TypeGuardFailure [0  form = 10  size = 2 [^9] UR 0000()]       2
   1 AssertionViolated [0  form = 10  size = 2 [^9] UR 0000()]       3
