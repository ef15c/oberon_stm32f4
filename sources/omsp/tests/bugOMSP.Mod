MODULE* bugOMSP;

  TYPE
     R = RECORD v, w, z: PINTEGER END; (* Flag that indicates if the device is ready to send data *)

  VAR r*: R-; i*, j: INTEGER;

  PROCEDURE p*; END p;
BEGIN r.v := PTR(PINTEGER, i); r.w := PTR(PINTEGER, j); r.z := PTR(PINTEGER, i);
  p
END bugOMSP.

OMSPP.Compile bugOMSP.Mod/s~
OMSPL.Link 32 4000H 200H bugOMSP~
  linking MSPFlashTypes preserveMSPFlash bugOMSP
    flash   32, data  100, stack  412 bytes

bugOMSP.txt

OMSPTool.DecSym bugOMSP.sms
bugOMSP 49238FA0  3
   9 r [19  form = 13 [^9]{  exno = 0  extlev = 0  size = 6 { --   4 --   2 --   0}]     1
   2 i [^4]     2
   9 p [0  form = 10 [^9] UR 0000()]     3

OMSPTool.DecObj bugOMSP.mpc
decode bugOMSP.mpc
bugOMSP 49238FA0
code executed from RAM
imports:

section     0	d    8	R
 06 00 FF FF FF FF FF FF
fixups:

section     1	d    6	r
 00 00 00 00 01 00
fixups:
 0003	s0.3
 0005	s0.2

section     2	r    2	i
fixups:

section     3	r    2	j
fixups:

section     4	c    2	p
 0000	     4130	RET
fixups:

section     5	c    6	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4130	RET
fixups:
 0003	s0.4

section     6	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    5    1    2    4
