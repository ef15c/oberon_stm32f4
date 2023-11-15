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

testImport E515BF2D   1    64
imports:
	testExport E24BD52E
type descriptors

data     4
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80100002	LDR  R0  R1       2
   3	 80000001	LDR  R0  R0       1
   4	 81000002	LDR  R1  R0       2
   5	 A0100000	STR   R0  R1       0
   6	 F7102006	BL    8198
   7	 8FE00000	LDR LNK SP       0
   8	 4EE80004	ADD SP SP      4
   9	 C700000F	B LNK
commands:
entries
     0     0
pointer refs

fixP =        6
fixD =        4
fixT =        0
entry =        0

OM4Tool.DecObj testImport.m4c ~

decode testImport.m4c
testImport E515BF2D   1    62
imports:
	testExport E24BD52E
type descriptors

data     4
strings

code
commands:
entries
     0     0
pointer refs

fixP =       24
fixD =       16
fixT =        0
entry =        0
   0	 F1BD0D04	SUB SP SP # 04H
   4	 F8CDE000	STR LR [ SP + 00H]
   8	 01000004	LDR  R0 [ MT + Base(  1)]
  12	 00000001	LDR  R0 [  R0 + Var(   1)]
  16	 10000004	LDR  R1 [ MT + Base(  0)]
  20	 F8C10000	STR  R0 [  R1 + 00H]
  24	 1020000C	BL Mod(  1) proc(   2)
  28	 F8DDE000	LDR LR [ SP + 00H]
  32	 F11D0D04	ADD SP SP # 04H
  36	     4770	BX LR

*)

