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
testImport E4E4472F Flash    64
imports:
	testExport F14DC58E
type descriptors
 0006 0000 FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0002
fixup procedures chains
 0032     0	 0000
 000E     1	 0005
fixup handlers chains
fixup data chains
 0026     0	 0000
 0014     0	 0002
 002E     1	 0004
 0004     1	 0002
fixup constants chains
 002A     1	 0001
fixup types chains
 0002     1	 0001
entry =  0002
code    56
 0000	     4130	RET
 0002	     4292	MOV &0,&0
 0004	     0000
 0006	     0000
 0008	     12B0	CALL #0
 000A	     0000
 000C	     40B2	MOV #10,&0
 000E	     000A
 0010	     0000
 0012	     1292	CALL &16
 0014	     0010
 0016	     403F	MOV #0,R15
 0018	     0000
 001A	     4FA2	MOV @R15,&6
 001C	     0006
 001E	     403F	MOV #24,R15
 0020	     0018
 0022	     4F92	MOV 2(R15),&28
 0024	     0002
 0026	     001C
 0028	     1230	PUSH #0
 002A	     0000
 002C	     1230	PUSH #32
 002E	     0020
 0030	     12B0	CALL #0
 0032	     0000
 0034	     5221	ADD #4,SP
 0036	     4130	RET
