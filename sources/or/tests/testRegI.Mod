MODULE testRegI;
  IMPORT SYSTEM;
  VAR v: LONGINT;
  
BEGIN SYSTEM.GET(0, v);
  SYSTEM.GET(0D0201000H, v);
END testRegI.

(*
ORTool.DecObj testRegI.rsc ~

decode testRegI.rsc
testRegI BDDACBC6   1    72
imports:
type descriptors

data     4
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 40000000	MOV  R0  R0      0
   3	 80000000	LDR  R0  R0       0
   4	 81000004	LDR  R1  R0       4
   5	 A0100000	STR   R0  R1       0
   6	 6000D020	MOV'  R0  R0 -12256
   7	 40061000	IOR  R0  R0   4096
   8	 80000000	LDR  R0  R0       0
   9	 81000005	LDR  R1  R0       5
  10	 A0100000	STR   R0  R1       0
  11	 8FE00000	LDR LNK SP       0
  12	 4EE80004	ADD SP SP      4
  13	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =        9
fixT =        0

OM4Tool.DecObj testRegI.m4c ~

decode testRegI.m4c
testRegI BDDACBC6   1    68
imports:
type descriptors

data     4
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =       34
fixT =        0
entry =        0
   0	 F1BD0D04	SUBS SP SP # 4H
   4	 F8CDE000	STR LR [ SP + 0H]
   8	     2000	MOVS  R0 #  0
  10	 F8D00000	LDR  R0 [  R0 + 0H]
  14	 10000007	LDR  R1 [ MT + Base(  0)]
  18	 F8C10000	STR  R0 [  R1 + 0H]
  22	 F2410000	MOV  R0 #  4096
  26	 F2CD0020	MOVT  R0 # 53280
  30	 F8D00000	LDR  R0 [  R0 + 0H]
  34	 1000000A	LDR  R1 [ MT + Base(  0)]
  38	 F8C10000	STR  R0 [  R1 + 0H]
  42	 F8DDE000	LDR LR [ SP + 0H]
  46	 F11D0D04	ADDS SP SP # 4H
  50	     4770	BX LR

*)

