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
testExport F14DC58E Flash    58
imports:
type descriptors
 0004 FFFF FFFF FFFF
data    10
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0016 0000 0000 0002 0004 0000
fixup procedures chains
 001C     0	 0000
fixup handlers chains
fixup data chains
 0022     0	 0002
 0026     0	 0004
 002C     0	 0008
 002E     0	 0006
fixup constants chains
fixup types chains
entry =  0016
code    50
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
 0016	     12B0	CALL #0
 0018	     0000
 001A	     40B2	MOV #24,&0
 001C	     0018
 001E	     0000
 0020	     1292	CALL &30
 0022	     001E
 0024	     4292	MOV &0,&0
 0026	     0000
 0028	     0000
 002A	     4292	MOV &40,&0
 002C	     0028
 002E	     0000
 0030	     4130	RET

OMSPTool.DecSym testExport.sms
decode testExport.sms
testExport F14DC58E  1
   5 rec [16  form = 13  size = 4 [^9]{  exno = 1  extlev = 0 { y [^4]   2 x [^4]   0}]()
   2 l [^4]     2
   2 p1 [0  form = 10  size = 2 [^9] UR FFFF()]     3
   2 v [^16]     4
   1 p [0  form = 10  size = 2 [^9] UR 0000()]       5
