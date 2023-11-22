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
testRegI BDDACBC6   1    58
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
fixD =       26
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	     2000	MOVS R0 #0
   4	     6800	LDR R0 [ R0 + 0]
   6	 10000003	MOV R1 lower 16-bits base(0)
  10	 0000D334	MOVT R1 higher 16-bits var(0)
  14	     6008	STR R0 [ R1 + 0]
  16	 F2410000	MOV R0 #  4096
  20	 F2CD0020	MOVT R0 # 53280
  24	     6800	LDR R0 [ R0 + 0]
  26	 1000000A	MOV R1 lower 16-bits base(0)
  30	 0000D334	MOVT R1 higher 16-bits var(0)
  34	     6008	STR R0 [ R1 + 0]
  36	 F85DEB04	LDR LR [ SP ] + 4

*)

