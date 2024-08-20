MODULE testDeRef;
  IMPORT SYSTEM;
  TYPE prec = POINTER TO rec;
    rec = RECORD
      x, y: INTEGER
    END;
  VAR r: prec; a: rec;
BEGIN r := SYSTEM.VAL(prec, SYSTEM.ADR(a));
  r.x := r.y
END testDeRef.

OMSPTool.DecObj testDeRef.mpc
decode testDeRef.mpc
testDeRef D9C6CB1E Flash    30
imports:
type descriptors
 0004 FFFF FFFF FFFF
data     6
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 0002     0	 0002
 000C     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    22
 0000	     40B2	MOV #0,&0
 0002	     0000
 0004	     0000
 0006	     421F	MOV &4,R15
 0008	     0004
 000A	     421E	MOV &8,R14
 000C	     0008
 000E	     4E9F	MOV 2(R14),0(R15)
 0010	     0002
 0012	     0000
 0014	     4130	RET
