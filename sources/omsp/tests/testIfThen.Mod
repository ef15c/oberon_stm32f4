MODULE testIfThen;
  VAR i: INTEGER;
BEGIN
  IF i = 0 THEN i := 1 ELSE i := 0 END
END testIfThen.

OMSPTool.DecObj testIfThen.mpc
decode testIfThen.mpc
testIfThen C10C56CC Flash    18
imports:
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 000E     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    18
 0000	     9382	CMP #0,&0
 0002	     0000
 0004	     2003	JNE $+8, goes to  000C
 0006	     4392	MOV #1,&2
 0008	     0002
 000A	     3C02	JMP $+6, goes to  0010
 000C	     4382	MOV #0,&8
 000E	     0008
 0010	     4130	RET
