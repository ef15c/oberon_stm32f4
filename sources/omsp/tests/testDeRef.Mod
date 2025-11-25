MODULE testDeRef;
  TYPE prec = POINTER TO rec;
    rec = RECORD
      x, y: INTEGER
    END;
  VAR r: prec; a: rec;
BEGIN r := PTR(prec, a);
  r.x := r.y
END testDeRef.

OMSPP.Compile testDeRef.Mod~
OMSPTool.DecObj testDeRef.mpc
decode testDeRef.mpc
testDeRef C2D26B0C
imports:

section     0	d    8	rec
 04 00 FF FF FF FF FF FF
fixups:

section     1	r    2	r
fixups:

section     2	r    4	a
fixups:

section     3	c   22	module body
 0000	     40B2	MOV #0,&0
 0002	     0000
 0004	     0000
 0006	     421F	MOV &5,R15
 0008	     0005
 000A	     421E	MOV &9,R14
 000C	     0009
 000E	     4E9F	MOV 2(R14),0(R15)
 0010	     0002
 0012	     0000
 0014	     4130	RET
fixups:
 000D	s0.1
 0003	s0.2

section     4	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    3
