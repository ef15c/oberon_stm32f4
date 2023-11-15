MODULE testImport;
  IMPORT testExport;
  VAR v1*: LONGINT;
    p1*: PROCEDURE;
  
BEGIN v1 := testExport.v;
  testExport.p;
  p1 := testExport.p;
  p1
END testImport.

(*
ORTool.DecObj testImport.rsc ~

decode testImport.rsc
testImport 6117C055   1   104
imports:
	testExport 1760CB95
type descriptors

data     8
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80100002	LDR  R0  R1       2
   3	 80000001	LDR  R0  R0       1
   4	 81000002	LDR  R1  R0       2
   5	 A0100000	STR   R0  R1       0
   6	 F7103006	BL   12294
   7	 80100003	LDR  R0  R1       3
   8	 40080103	ADD  R0  R0    259
   9	 81000002	LDR  R1  R0       2
  10	 A0100004	STR   R0  R1       4
  11	 80000002	LDR  R0  R0       2
  12	 80000004	LDR  R0  R0       4
  13	 D100A45C	BLEQ  MT
  14	 D7000000	BL  R0
  15	 8FE00000	LDR LNK SP       0
  16	 4EE80004	ADD SP SP      4
  17	 C700000F	B LNK
commands:
entries
     0     0     4
pointer refs

fixP =        6
fixD =       11
fixT =        0
entry =        0

OM4Tool.DecObj testImport.m4c ~

decode testImport.m4c
testImport 6117C055   1   112
imports:
	testExport 1760CB95
type descriptors

data     8
strings

code
commands:
entries
     0     0     4
pointer refs

fixP =       24
fixD =       44
fixT =        0
entry =        0
   0	 F1BD0D04	SUB SP SP # 04H
   4	 F8CDE000	STR LR [ SP + 00H]
   8	 01000004	LDR  R0 [ MT + Base(  1)]
  12	 00000001	LDR  R0 [  R0 + Var(   1)]
  16	 10000004	LDR  R1 [ MT + Base(  0)]
  20	 F8C10000	STR  R0 [  R1 + 00H]
  24	 1030000C	BL Mod(  1) proc(   3)
  28	 01000006	LDR  R0 [ MT + Base(  1)]
  32	 40000103	ADD  R0 [  R0 + Var(   3)] Prog based
  36	 10000004	LDR  R1 [ MT + Base(  0)]
  40	 F8C10004	STR  R0 [  R1 + 04H]
  44	 00000004	LDR  R0 [ MT + Base(  0)]
  48	 F8D00004	LDR  R0 [  R0 + 04H]
  52	     2800	CMP  R0 #  0
  54	     BF08	IT EQ
  56	 EC001245	Trap  5 at pos     164
  60	     4780	BLX  R0
  62	 F8DDE000	LDR LR [ SP + 00H]
  66	 F11D0D04	ADD SP SP # 04H
  70	     4770	BX LR

*)

