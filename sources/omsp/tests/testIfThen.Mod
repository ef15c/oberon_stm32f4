MODULE testIfThen;
  VAR i: INTEGER;
BEGIN
  IF i = 0 THEN i := 1 ELSE i := 0 END
END testIfThen.

OMSPP.Compile testIfThen.Mod~
OMSPTool.DecObj testIfThen.mpc
decode testIfThen.mpc
testIfThen 2DEE3392
imports:

section     0	r    2	i
fixups:

section     1	c   18	module body
 0000	     9382	CMP #0,&0
 0002	     0000
 0004	     2003	JNE $+8, goes to  000C
 0006	     4392	MOV #1,&3
 0008	     0003
 000A	     3C02	JMP $+6, goes to  0010
 000C	     4382	MOV #0,&9
 000E	     0009
 0010	     4130	RET
fixups:
 000F	s0.0

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1
