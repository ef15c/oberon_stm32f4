MODULE testMSR;
	IMPORT SYSTEM;
	CONST PSP=16+9;

	PROCEDURE test;
	BEGIN
		SYSTEM.LDREG(PSP, 10000000H);
	END test;

END testMSR.

OM4Tool.DecObj testMSR.m4c

decode testMSR.m4c
testMSR 74C5B8C2   1    36
imports:
type descriptors

data     0
strings

code
commands:
entries
    16
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       16
 00000000	     B500	PUSH LR
 00000002	 F05F5080	MOVS R0 #268435456
 00000006	 F3808809	MSR PSP R0
 0000000A	 F85DEB04	LDR LR [ SP ] + 4
 0000000E	     4770	BX LR
 00000010	     B500	PUSH LR
 00000012	 F85DEB04	LDR LR [ SP ] + 4
 00000016	     4770	BX LR
