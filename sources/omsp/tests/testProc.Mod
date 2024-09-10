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
testProc 074761C7 Flash     8
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
fixup constants chains
fixup types chains
entry =  0006
code     8
 0000	     3C01	JMP #1, goes to  0004
 0002	     4130	RET
 0004	     4130	RET
 0006	     4130	RET
