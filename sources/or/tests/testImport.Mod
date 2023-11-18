MODULE testImport;
  IMPORT testExport;
  VAR v1: LONGINT;
    p1: PROCEDURE;
    r1: REAL;
  
BEGIN v1 := testExport.v;
  testExport.p;
  p1 := testExport.p;
  p1;
  r1 := testExport.r
END testImport.

(*
ORTool.DecObj testImport.rsc ~

decode testImport.rsc
testImport E4E4472F   1   116
imports:
	testExport 0F5D31AF
type descriptors

data    12
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80100002	LDR  R0  R1       2
   3	 80000001	LDR  R0  R0       1
   4	 81000002	LDR  R1  R0       2
   5	 A0100000	STR   R0  R1       0
   6	 F7104006	BL   16390
   7	 80100003	LDR  R0  R1       3
   8	 40080104	ADD  R0  R0    260
   9	 81000002	LDR  R1  R0       2
  10	 A0100004	STR   R0  R1       4
  11	 80000002	LDR  R0  R0       2
  12	 80000004	LDR  R0  R0       4
  13	 D100AD5C	BLEQ  MT
  14	 D7000000	BL  R0
  15	 80100004	LDR  R0  R1       4
  16	 80000003	LDR  R0  R0       3
  17	 81000002	LDR  R1  R0       2
  18	 A0100008	STR   R0  R1       8
  19	 8FE00000	LDR LNK SP       0
  20	 4EE80004	ADD SP SP      4
  21	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        6
fixD =       17
fixT =        0

OM4Tool.DecObj testImport.m4c ~

decode testImport.m4c
testImport E4E4472F   1   124
imports:
	testExport 0F5D31AF
type descriptors

data    12
strings

code
commands:
entries
     0
pointer refs

fixP =       24
fixD =       70
fixT =        0
entry =        0
   0	 F1BD0D04	SUBS SP SP # 4H
   4	 F8CDE000	STR LR [ SP + 0H]
   8	 01000004	LDR  R0 [ MT + Base(  1)]
  12	 00000001	LDR  R0 [  R0 + Var(   1)]
  16	 10000004	LDR  R1 [ MT + Base(  0)]
  20	 F8C10000	STR  R0 [  R1 + 0H]
  24	 1040000C	BL Mod(  1) proc(   4)
  28	 01000006	LDR  R0 [ MT + Base(  1)]
  32	 40000104	ADD  R0 [  R0 + Var(   4)] Prog based
  36	 10000004	LDR  R1 [ MT + Base(  0)]
  40	 F8C10004	STR  R0 [  R1 + 4H]
  44	 00000004	LDR  R0 [ MT + Base(  0)]
  48	 F8D00004	LDR  R0 [  R0 + 4H]
  52	     2800	CMP  R0 #  0
  54	     0BF08	IT EQ
  56	 EC0012D5	TrapEQ  5 at pos     173
  60	     4780	BLX  R0
  62	 01000009	LDR  R0 [ MT + Base(  1)]
  66	 60000003	VLDR S0 [  R0 + Var(   3)]
  70	 00000004	LDR  R0 [ MT + Base(  0)]
  74	 ED800A02	VSTR S0 [  R0 + 8H]
  78	 F8DDE000	LDR LR [ SP + 0H]
  82	 F11D0D04	ADDS SP SP # 4H
  86	     4770	BX LR

*)

