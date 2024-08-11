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
testDeRef D9C6CB1E Flash    32
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
 000E     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    24
 0000	     403F	MOV #0,R15
 0002	     0000
 0004	     4F82	MOV R15,&0
 0006	     0000
 0008	     421F	MOV &6,R15
 000A	     0006
 000C	     421E	MOV &10,R14
 000E	     000A
 0010	     4E9F	MOV 2(R14),0(R15)
 0012	     0002
 0014	     0000
 0016	     4130	RET
