MODULE MSPFlashTypes;
  TYPE flashBlockType* = PROCEDURE(source, dest: PINTEGER*; length: INTEGER*);
END MSPFlashTypes.

OMSPP.Compile MSPFlashTypes.Mod/s~
OMSPTool.DecSym MSPFlashTypes.sms
decode MSPFlashTypes.sms
MSPFlashTypes 1E42D179  3
   5 flashBlockType [19  form = 7 [0  form = 10 [^9] leaf UR 0000( class = 2 R6 [^4] class = 2 R5 [^7] class = 2 R4 [^7])]]()

OMSPTool.DecObj MSPFlashTypes.mpc
decode MSPFlashTypes.mpc
MSPFlashTypes 1E42D179
imports:

section     0	c    2	module body
 0000	     4130	RET
fixups:

section     1	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    0
