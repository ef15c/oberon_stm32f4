MODULE testExport;
  TYPE rec* = RECORD
    x*, y*: INTEGER;
  END;

  VAR l*: INTEGER;
    p1*: PROCEDURE;
    v*: rec;
    w: INTEGER;

  PROCEDURE p*;
    VAR z: rec;
      a: INTEGER;
  BEGIN
    a := z.y; z.x := a
  END p;

BEGIN p; p1 := p; p1;
  w := v.x; v.y := w
END testExport.


OMSPTool.DecObj testExport.mpc
decode testExport.mpc
testExport 1ADE4F94
imports:

section     0	d    8	rec
 04 00 FF FF FF FF FF FF
fixups:

section     1	r    2	l
fixups:

section     2	r    2	p1
fixups:

section     3	r    4	v
fixups:

section     4	r    2	w
fixups:

section     5	c   22	p
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     4191	MOV 2(SP),4(SP)
 0006	     0002
 0008	     0004
 000A	     4191	MOV 4(SP),0(SP)
 000C	     0004
 000E	     0000
 0010	     5031	ADD #6,SP
 0012	     0006
 0014	     4130	RET
fixups:

section     6	c   28	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4292	MOV &3,&0
 0006	     0003
 0008	     0000
 000A	     1292	CALL &9
 000C	     0009
 000E	     4292	MOV &0,&0
 0010	     0000
 0012	     0000
 0014	     4292	MOV &19,&0
 0016	     0013
 0018	     0000
 001A	     4130	RET
fixups:
 0019	s0.3+2
 0017	s0.4
 0011	s0.3
 000D	s0.2
 0007	s0.5

section     7	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    6    0    1    2    3    5

OMSPTool.DecSym testExport.sms
decode testExport.sms
testExport 1ADE4F94  3
   5 rec [19  form = 13 [^9]{  exno = 1  extlev = 0  size = 4 { y [^4]   2 x [^4]   0}]()
   2 l [^4]     2
   2 p1 [0  form = 10 [^9] UR FFF0()]     3
   2 v [^19]     4
   9 p [0  form = 10 [^9] UR 0000()]     5

