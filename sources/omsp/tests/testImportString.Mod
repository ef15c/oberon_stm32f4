MODULE testImportString;
  IMPORT testString;

  VAR s: ARRAY 10 OF CHAR;


BEGIN s := testString.st
END testImportString.

System.Free OMSPL OMSPP OMSPG~
OMSPP.Compile testImportString.Mod~
OMSPL.Link 32 4000H 200H testImportString~

OMSPTool.DecObj testImportString.mpc
decode testImportString.mpc
testImportString 1FAD3538 Flash    22
imports:
	testString 14B437F3
type descriptors

data    10
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 0002     0	 0000
fixup constants chains
 0006     1	 0001
fixup types chains
entry =  0000
code    22
 0000	     403F	MOV #0,R15
 0002	     0000
 0004	     403E	MOV #0,R14
 0006	     0000
 0008	     4EBF	MOV @R14+,0(R15)
 000A	     0000
 000C	     532F	ADD #2,R15
 000E	     93CE	CMP.B #0,-1(R14)
 0010	     FFFF
 0012	     23FA	JNE $-10, goes to  0008
 0014	     4130	RET
