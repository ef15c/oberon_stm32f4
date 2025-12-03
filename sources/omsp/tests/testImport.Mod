MODULE testImport;
  IMPORT testExport;

  TYPE locrec* = RECORD(testExport.rec) z: INTEGER END;

  VAR v1: INTEGER;
    p1: PROCEDURE;

  PROCEDURE q(r: testExport.rec);
  END q;
  
BEGIN v1 := testExport.l;
  testExport.p;
  p1 := testExport.p;
  p1;
  v1 := testExport.v.x;
  v1 := testExport.v.y;
  q(testExport.v)
END testImport.

OMSPTool.DecObj testImport.mpc
decode testImport.mpc
testImport EAFBD69F
imports:
	testExport 1ADE4F94

section     0	d    8	locrec
 06 00 00 00 FF FF FF FF
fixups:
 0003	s1.1

section     1	r    2	v1
fixups:

section     2	r    2	p1
fixups:

section     3	c    2	q
 0000	     4130	RET
fixups:

section     4	c   48	module body
 0000	     4292	MOV &0,&0
 0002	     0000
 0004	     0000
 0006	     12B0	CALL #0
 0008	     0000
 000A	     40B2	MOV #9,&0
 000C	     0009
 000E	     0000
 0010	     1292	CALL &15
 0012	     000F
 0014	     4292	MOV &0,&5
 0016	     0000
 0018	     0005
 001A	     4292	MOV &0,&25
 001C	     0000
 001E	     0019
 0020	     1230	PUSH #0
 0022	     0000
 0024	     1230	PUSH #23
 0026	     0017
 0028	     12B0	CALL #0
 002A	     0000
 002C	     5221	ADD #4,SP
 002E	     4130	RET
fixups:
 002B	s0.3
 0023	s1.1
 001D	s1.4+2
 0027	s1.4
 0013	s0.2
 000D	s1.5
 001F	s0.1
 0003	s1.2

section     5	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    4    0
