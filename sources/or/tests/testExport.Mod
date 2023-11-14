MODULE testExport;
  VAR v*: LONGINT;
  
  PROCEDURE p*;
  BEGIN
  END p;

BEGIN p
END testExport.

(*
ORTool.DecObj testExport.rsc ~

decode testExport.rsc
testExport E24BD52E   1    76
imports:
type descriptors

data     4
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 8FE00000	LDR LNK SP       0
   3	 4EE80004	ADD SP SP      4
   4	 C700000F	B LNK
   5	 4EE90004	SUB SP SP      4
   6	 AFE00000	STR  LNK SP       0
   7	 F7FFFFF8	BL      -8
   8	 8FE00000	LDR LNK SP       0
   9	 4EE80004	ADD SP SP      4
  10	 C700000F	B LNK
commands:
	p    0
entries
    20     0     0
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       20

OM4Tool.DecObj testExport.m4c ~

decode testExport.m4c
testExport E24BD52E   1    72
imports:
type descriptors

data     4
strings

code
commands:
	p    0
entries
    18     0     0
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       18
   0	 F1BD0D04	SUB SP SP # 04H
   4	 F8CDE000	STR LR [ SP + 00H]
   8	 F8DDE000	LDR LR [ SP + 00H]
  12	 F11D0D04	ADD SP SP # 04H
  16	     4770	BX LR
  18	 F1BD0D04	SUB SP SP # 04H
  22	 F8CDE000	STR LR [ SP + 00H]
  26	 F7FFFFF1	BL #       -30
  30	 F8DDE000	LDR LR [ SP + 00H]
  34	 F11D0D04	ADD SP SP # 04H
  38	     4770	BX LR

*)
