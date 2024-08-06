(*bug present in Project Oberon 2013:
  error in generated code*)
MODULE testSet;

  PROCEDURE set;
    VAR pp: INTEGER;
      s: SET;
  BEGIN
    s := {pp .. pp+7}
  END set;

END testSet.

(*
ORTool.DecObj testSet.rsc ~
decode testSet.rsc
testSet 74DADAB7   1    88
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 80E00004	LDR  R0 SP       4
   3	 40080007	ADD  R0  R0      7
   4	 81E00004	LDR  R1 SP       4
   5	 5200FFFF	MOV  R2  R0     -1
   6	 01210001	LSL  R1  R2  R1
   7	 5200FFFE	MOV  R2  R0     -2
   8	 00210000	LSL  R0  R2  R0
   9	 01150000	ANN  R1  R1  R0
  10	 A1E00008	STR   R1 SP       8
  11	 8FE00000	LDR LNK SP       0
  12	 4EE8000C	ADD SP SP     12
  13	 C700000F	B LNK
  14	 4EE90004	SUB SP SP      4
  15	 AFE00000	STR  LNK SP       0
  16	 8FE00000	LDR LNK SP       0
  17	 4EE80004	ADD SP SP      4
  18	 C700000F	B LNK
commands:
entries
    56
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       56

OM4Tool.DecObj testSet.m4c ~

decode testSet.m4c
testSet 74DADAB7   1    64
imports:
type descriptors

data     0
strings

code
commands:
entries
    42
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       42
 00000000	 F1BD0D08	SUBS SP SP #8
 00000004	     B500	PUSH LR
 00000006	     9801	LDR R0 [SP + 4]
 00000008	     1DC0	ADDS R0 R0 #7
 0000000A	     9901	LDR R1 [SP + 4]
 0000000C	 F05F32FF	MOVS R2 #-1
 00000010	 FA12F101	LSLS R1 R2 R1
 00000014	 F07F0201	MVNS R2 #1
 00000018	 FA12F000	LSLS R0 R2 R0
 0000001C	     4381	BICS R1 R0
 0000001E	     9102	STR R1 [SP + 8]
 00000020	 F85DEB04	LDR LR [ SP ] + 4
 00000024	 F11D0D08	ADDS SP SP #8
 00000028	     4770	BX LR
 0000002A	     B500	PUSH LR
 0000002C	 F85DEB04	LDR LR [ SP ] + 4
 00000030	     4770	BX LR

*)
