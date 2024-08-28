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
testExport F14DC58E Flash    56
imports:
type descriptors
 0004 FFFF FFFF FFFF
data    10
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0014 0000 0000 0002 0004 0000
fixup procedures chains
 001A     0	 0000
fixup handlers chains
fixup data chains
 0020     0	 0002
 0024     0	 0004
 002A     0	 0008
 002C     0	 0006
fixup constants chains
fixup types chains
entry =  0014
code    48
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     4191	MOV 4(SP),0(SP)
 0006	     0004
 0008	     0000
 000A	     41A1	MOV @SP,2(SP)
 000C	     0002
 000E	     5031	ADD #6,SP
 0010	     0006
 0012	     4130	RET
 0014	     12B0	CALL #0
 0016	     0000
 0018	     40B2	MOV #22,&0
 001A	     0016
 001C	     0000
 001E	     1292	CALL &28
 0020	     001C
 0022	     4292	MOV &0,&0
 0024	     0000
 0026	     0000
 0028	     4292	MOV &38,&0
 002A	     0026
 002C	     0000
 002E	     4130	RET

OMSPTool.DecSym testExport.sms
decode testExport.sms
testExport F14DC58E  1
   5 rec [16  form = 13  size = 4 [^9]{  exno = 1  extlev = 0 { y [^4]   2 x [^4]   0}]()
   2 l [^4]     2
   2 p1 [0  form = 10  size = 2 [^9] UR FFFF()]     3
   2 v [^16]     4
   1 p [0  form = 10  size = 2 [^9] UR 0000()]       5
