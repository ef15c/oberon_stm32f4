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

OMSPP.Compile testDeRef.Mod~
OMSPTool.DecObj testDeRef.mpc
decode testDeRef.mpc
testDeRef C0BB9E85 Flash    30
imports:
type descriptors
 0004 FFFF FFFF FFFF
data     6
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures in code space chains
fixup handlers in vector space chains
fixup data in code space chains
 000C     0	 0000
 0002     0	 0002
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
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
