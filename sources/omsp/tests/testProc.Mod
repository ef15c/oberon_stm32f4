MODULE testProc;

  PROCEDURE p;
    PROCEDURE q;
    BEGIN
    END q;
  BEGIN
  END p;
  
END testProc.


OMSPTool.DecObj testProc.mpc

decode testProc.mpc
testProc D7E2D8C4    12
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0006
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0006
code     8
 0000	     3C01	JMP #1, goes to  0004
 0002	     4130	RET
 0004	     4130	RET
 0006	     4130	RET

OM4Tool.DecObj testProc.m4c

decode testProc.m4c
testProc D7E2D8C4   1    40
imports:
type descriptors

data     0
strings

code
commands:
entries
    20
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       20
 00000000	 F000B804	B #8, goes to  0000000C
 00000004	     B500	PUSH LR
 00000006	 F85DEB04	LDR LR [ SP ] + 4
 0000000A	     4770	BX LR
 0000000C	     B500	PUSH LR
 0000000E	 F85DEB04	LDR LR [ SP ] + 4
 00000012	     4770	BX LR
 00000014	     B500	PUSH LR
 00000016	 F85DEB04	LDR LR [ SP ] + 4
 0000001A	     4770	BX LR
