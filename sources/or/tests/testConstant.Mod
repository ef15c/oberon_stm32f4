MODULE testConstant;
  VAR i: INTEGER;
    r: REAL;
BEGIN
  i := 10;
  r := 3.14
END testConstant.


(*
ORTool.DecObj testConstant.rsc ~

decode testConstant.rsc
testConstant 5C50372B   1    68
imports:
type descriptors

data     8
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 4000000A	MOV  R0  R0     10
   3	 81000003	LDR  R1  R0       3
   4	 A0100000	STR   R0  R1       0
   5	 60004048	MOV'  R0  R0  16456
   6	 4006F5C3	IOR  R0  R0  -2621
   7	 81000004	LDR  R1  R0       4
   8	 A0100004	STR   R0  R1       4
   9	 8FE00000	LDR LNK SP       0
  10	 4EE80004	ADD SP SP      4
  11	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =        7
fixT =        0
entry =        0

OM4Tool.DecObj testConstant.m4c ~

decode testConstant.m4c
testConstant 5C50372B   1    68
imports:
type descriptors

data     8
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =       30
fixT =        0
entry =        0
   0	 F1BD0D04	SUBS SP SP # 4H
   4	 F8CDE000	STR LR [ SP + 0H]
   8	     200A	MOVS  R0 # 10
  10	 10000005	LDR  R1 [ MT + Base(  0)]
  14	 F8C10000	STR  R0 [  R1 + 0H]
  18	 F24F50C3	MOV  R0 # 62915
  22	 F2C40048	MOVT  R0 # 16456
  26	 EE000A10	VMOV S0   R0
  30	 0000000A	LDR  R0 [ MT + Base(  0)]
  34	 ED800A01	VSTR S0 [  R0 + 4H]
  38	 F8DDE000	LDR LR [ SP + 0H]
  42	 F11D0D04	ADDS SP SP # 4H
  46	     4770	BX LR

*)
