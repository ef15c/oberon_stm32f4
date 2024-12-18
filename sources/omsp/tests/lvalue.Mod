MODULE lvalue;
  IMPORT SYSTEM;

  VAR i: INTEGER;

BEGIN SYSTEM.VAL(PINTEGER, i)^ := 0;
  i := 0
END lvalue.

OMSPTool.DecObj lvalue.mpc
decode lvalue.mpc
lvalue F0CB60AA Flash    14
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
 000A     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    14
 0000	     421F	MOV &0,R15
 0002	     0000
 0004	     438F	MOV #0,0(R15)
 0006	     0000
 0008	     4382	MOV #0,&2
 000A	     0002
 000C	     4130	RET
