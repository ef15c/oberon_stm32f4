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
 0008
fixup procedures chains
fixup handlers chains
fixup data chains
 0002( 000A)     0	 0002
 000C( 0014)     0	 0000
fixup constants chains
fixup types chains
entry =  0008
code    22
 0000( 0008)	     40B2	MOV #0,&0
 0002( 000A)	     0000
 0004( 000C)	     0000
 0006( 000E)	     421F	MOV &4,R15
 0008( 0010)	     0004
 000A( 0012)	     421E	MOV &8,R14
 000C( 0014)	     0008
 000E( 0016)	     4E9F	MOV 2(R14),0(R15)
 0010( 0018)	     0002
 0012( 001A)	     0000
 0014( 001C)	     4130	RET
