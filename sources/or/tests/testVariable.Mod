MODULE testVariable;
  PROCEDURE p;
    VAR i: INTEGER;
      r: REAL;
  BEGIN
    i := 10;
    r := 3.14
  END p;
END testVariable.


(*
ORTool.DecObj testVariable.rsc ~

decode testVariable.rsc
testVariable 43522A2B   1    72
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 4000000A	MOV  R0  R0     10
   3	 A0E00004	STR   R0 SP       4
   4	 60004048	MOV'  R0  R0  16456
   5	 4006F5C3	IOR  R0  R0  -2621
   6	 A0E00008	STR   R0 SP       8
   7	 8FE00000	LDR LNK SP       0
   8	 4EE8000C	ADD SP SP     12
   9	 C700000F	B LNK
  10	 4EE90004	SUB SP SP      4
  11	 AFE00000	STR  LNK SP       0
  12	 8FE00000	LDR LNK SP       0
  13	 4EE80004	ADD SP SP      4
  14	 C700000F	B LNK
commands:
entries
    40
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       40


OM4Tool.DecObj testVariable.m4c ~

decode testVariable.m4c
testVariable 43522A2B   1    70
imports:
type descriptors

data     0
strings

code
commands:
entries
    40
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       40
   0	 F1BD0D0C	SUBS SP SP # 0CH
   4	 F8CDE000	STR LR [ SP + 0H]
   8	     200A	MOVS  R0 # 10
  10	 F8CD0004	STR  R0 [ SP + 4H]
  14	 F24F50C3	MOV  R0 # 62915
  18	 F2C40048	MOVT  R0 # 16456
  22	 EE000A10	VMOV S0   R0
  26	 EDCD0A02	VSTR S0 [ SP + 8H]
  30	 F8DDE000	LDR LR [ SP + 0H]
  34	 F11D0D0C	ADDS SP SP # 0CH
  38	     4770	BX LR
  40	 F1BD0D04	SUBS SP SP # 4H
  44	 F8CDE000	STR LR [ SP + 0H]
  48	 F8DDE000	LDR LR [ SP + 0H]
  52	 F11D0D04	ADDS SP SP # 4H
  56	     4770	BX LR

*)
