MODULE testImport;
  IMPORT testExport;
  VAR v1: INTEGER;
    p1: PROCEDURE;
  
BEGIN v1 := testExport.l;
  testExport.p;
  p1 := testExport.p;
  p1;
  v1 := testExport.v.x;
  v1 := testExport.v.y
END testImport.

OMSPTool.DecObj testImport.mpc
decode testImport.mpc
testImport E4E4472F Flash    40
imports:
	testExport F14EC58E
type descriptors

data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
 000C     1	 0005
fixup handlers chains
fixup data chains
 0024     0	 0000
 0012     0	 0002
 001E     1	 0004
 0002     1	 0002
fixup constants chains
fixup types chains
entry =  0000
code    40
 0000	     4292	MOV &0,&0
 0002	     0000
 0004	     0000
 0006	     12B0	CALL #0
 0008	     0000
 000A	     40B2	MOV #8,&0
 000C	     0008
 000E	     0000
 0010	     1292	CALL &14
 0012	     000E
 0014	     403F	MOV #0,R15
 0016	     0000
 0018	     4FA2	MOV @R15,&4
 001A	     0004
 001C	     403F	MOV #22,R15
 001E	     0016
 0020	     4F92	MOV 2(R15),&26
 0022	     0002
 0024	     001A
 0026	     4130	RET
