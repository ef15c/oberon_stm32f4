MODULE Empty;  

BEGIN
END Empty.

(*

ORTool.DecObj Empty.rsc ~

Empty 74716DBE   1    32
imports:
type descriptors

data     0
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 8FE00000	LDR LNK SP       0
   3	 4EE80004	ADD SP SP      4
   4	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =        0

OM4Tool.DecObj Empty.m4c ~

decode Empty.m4c
Empty 74716DBE   1    20
imports:
type descriptors

data     0
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 F85DEB04	LDR LR [ SP ] + 4
   6	     4770	BX LR

 *)
