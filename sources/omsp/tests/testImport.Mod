MODULE testImport;
  IMPORT testExport;

  TYPE locrec = RECORD(testExport.rec) z: INTEGER END;

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
testImport CF624B57 Flash    64
imports:
	testExport 266A3416
type descriptors
 0006 0000 FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 000A
fixup procedures chains
 0032( 003A)     0	 0008
 000E( 0016)     1	 0005
fixup handlers chains
fixup data chains
 0026( 002E)     0	 0000
 0014( 001C)     0	 0002
 002E( 0036)     1	 0004
 0004( 000C)     1	 0002
fixup constants chains
 002A( 0032)     1	 0001
fixup types chains
 0002     1	 0001
entry =  000A
code    56
 0000( 0008)	     4130	RET
 0002( 000A)	     4292	MOV &0,&0
 0004( 000C)	     0000
 0006( 000E)	     0000
 0008( 0010)	     12B0	CALL #0
 000A( 0012)	     0000
 000C( 0014)	     40B2	MOV #10,&0
 000E( 0016)	     000A
 0010( 0018)	     0000
 0012( 001A)	     1292	CALL &16
 0014( 001C)	     0010
 0016( 001E)	     403F	MOV #0,R15
 0018( 0020)	     0000
 001A( 0022)	     4FA2	MOV @R15,&6
 001C( 0024)	     0006
 001E( 0026)	     403F	MOV #24,R15
 0020( 0028)	     0018
 0022( 002A)	     4F92	MOV 2(R15),&28
 0024( 002C)	     0002
 0026( 002E)	     001C
 0028( 0030)	     1230	PUSH #0
 002A( 0032)	     0000
 002C( 0034)	     1230	PUSH #32
 002E( 0036)	     0020
 0030( 0038)	     12B0	CALL #0
 0032( 003A)	     0000
 0034( 003C)	     5221	ADD #4,SP
 0036( 003E)	     4130	RET
