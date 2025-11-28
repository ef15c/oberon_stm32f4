MODULE msp430delay; (*C. Schoffit 06.10.24*)
  IMPORT SYSTEM;

  PROCEDURE CyclesX3*(c: INTEGER*);
  BEGIN REPEAT DEC(c) UNTIL SYSTEM.COND(1)
  END CyclesX3;

END msp430delay.

OMSPTool.DecObj msp430delay.mpc
decode msp430delay.mpc
msp430delay 6768A5E3
imports:

section     0	c    6	CyclesX3
 0000	     8314	SUB #1,R4
 0002	     23FE	JNE $-2, goes to  0000
 0004	     4130	RET
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

OMSPTool.DecSym msp430delay.sms
decode msp430delay.sms
msp430delay 6768A5E3  2
   9 CyclesX3 [0  form = 10 [^9] leaf UR 0010( class = 2 R4 [^4])]     1
