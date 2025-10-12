MODULE testProc;

  PROCEDURE p;
    PROCEDURE q;
    BEGIN
    END q;
  BEGIN
  END p;

BEGIN p
END testProc.

OMSPP.Compile testProc.Mod~
OMSPTool.DecObj testProc.mpc
decode testProc.mpc
testProc 074761C7 Flash    12
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0006
fixup procedures in code space chains
 0008     0	 0004
fixup handlers in vector space chains
fixup data in code space chains
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0006
code    12
 0000	     3C01	JMP $+4, goes to  0004
 0002	     4130	RET
 0004	     4130	RET
 0006	     12B0	CALL #0
 0008	     0000
 000A	     4130	RET
