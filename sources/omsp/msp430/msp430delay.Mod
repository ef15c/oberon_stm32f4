MODULE msp430delay; (*C. Schoffit 06.10.24*)
  IMPORT SYSTEM;

  PROCEDURE CyclesX3*(c: INTEGER*);
  BEGIN REPEAT DEC(c) UNTIL SYSTEM.COND(1)
  END CyclesX3;

END msp430delay.

OMSPTool.DecObj msp430delay.mpc
decode msp430delay.mpc
msp430delay EE6A4099 Flash     8
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0006 c 0000
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0006
code     8
 0000	     8314	SUB #1,R4
 0002	     23FE	JNE $-2, goes to  0000
 0004	     4130	RET
 0006	     4130	RET

OMSPTool.DecSym msp430delay.sms
decode msp430delay.sms
msp430delay EE6A4099  1
   1 CyclesX3 [0  form = 10  size = 2 [^9] leaf UR 0010( class = 2 R4 [^4])]       1
