MODULE testProc;

  PROCEDURE p;
    PROCEDURE q;
    BEGIN
    END q;
  BEGIN
  END p;
  
END testProc.


(*
ORTool.DecObj testProc.rsc ~

decode testProc.rsc
testProc D7E2D8C4   1    76
imports:
type descriptors

data     0
strings

code
   0	 E7000005	B       5
   1	 4EE90004	SUB SP SP      4
   2	 AFE00000	STR  LNK SP       0
   3	 8FE00000	LDR LNK SP       0
   4	 4EE80004	ADD SP SP      4
   5	 C700000F	B LNK
   6	 4EE90004	SUB SP SP      4
   7	 AFE00000	STR  LNK SP       0
   8	 8FE00000	LDR LNK SP       0
   9	 4EE80004	ADD SP SP      4
  10	 C700000F	B LNK
  11	 4EE90004	SUB SP SP      4
  12	 AFE00000	STR  LNK SP       0
  13	 8FE00000	LDR LNK SP       0
  14	 4EE80004	ADD SP SP      4
  15	 C700000F	B LNK
commands:
entries
    44
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       44


OM4Tool.DecObj testProc.m4c ~

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
   0	 F000B804	B #8, goes to 12
   4	     B500	PUSH LR
   6	 F85DEB04	LDR LR [ SP ] + 4
  10	     4770	BX LR
  12	     B500	PUSH LR
  14	 F85DEB04	LDR LR [ SP ] + 4
  18	     4770	BX LR
  20	     B500	PUSH LR
  22	 F85DEB04	LDR LR [ SP ] + 4
  26	     4770	BX LR


*)
