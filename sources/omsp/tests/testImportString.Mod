MODULE testImportString;
  IMPORT testString;

  VAR s: ARRAY 10 OF CHAR;


BEGIN s := testString.st
END testImportString.

System.Free OMSPL OMSPP OMSPG~
OMSPP.Compile testImportString.Mod~
OMSPL.Link 32 4000H 200H testImportString~
  linking testString testImportString
    flash  144, data   22, stack  490 bytes

OMSPTool.DecObj testImportString.mpc
decode testImportString.mpc
testImportString BF5FAB37
imports:
	testString 4C4AD16E

section     0	r   10	s
fixups:

section     1	c   22	module body
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
fixups:
 0007	s1.1
 0003	s0.0

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1
