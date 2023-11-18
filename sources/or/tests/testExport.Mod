MODULE testExport;
  VAR v*: LONGINT;
    p1*: PROCEDURE;
    r*: REAL;
  
  PROCEDURE p*;
  BEGIN
  END p;

BEGIN p;
  p1 := p;
  p1
END testExport.

(*
ORTool.DecObj testExport.rsc ~

decode testExport.rsc
testExport 0F5D31AF   1   124
imports:
type descriptors

data    12
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
   8	 F7000000	BL       0
   9	 40F90024	SUB  R0 LNK     36
  10	 8100000A	LDR  R1  R0      10
  11	 A0100004	STR   R0  R1       4
  12	 80000002	LDR  R0  R0       2
  13	 80000004	LDR  R0  R0       4
  14	 D100955C	BLEQ  MT
  15	 D7000000	BL  R0
  16	 8FE00000	LDR LNK SP       0
  17	 4EE80004	ADD SP SP      4
  18	 C700000F	B LNK
commands:
	p    0
entries
    20     0     4     8     0
pointer refs

fixP =        0
fixD =       12
fixT =        0
entry =       20


OM4Tool.DecObj testExport.m4c ~

decode testExport.m4c
testExport 0F5D31AF   1   122
imports:
type descriptors

data    12
strings

code
commands:
	p    0
entries
    18     0     4     8     0
pointer refs

fixP =        0
fixD =       46
fixT =        0
entry =       18
   0	 F1BD0D04	SUBS SP SP # 4H
   4	 F8CDE000	STR LR [ SP + 0H]
   8	 F8DDE000	LDR LR [ SP + 0H]
  12	 F11D0D04	ADDS SP SP # 4H
  16	     4770	BX LR
  18	 F1BD0D04	SUBS SP SP # 4H
  22	 F8CDE000	STR LR [ SP + 0H]
  26	 F7FFFFF1	BL #       -30
  30	 F000F800	BL #         0
  34	 F1BE0022	SUBS  R0 LR # 22H
  38	 10000013	LDR  R1 [ MT + Base(  0)]
  42	 F8C10004	STR  R0 [  R1 + 4H]
  46	 00000004	LDR  R0 [ MT + Base(  0)]
  50	 F8D00004	LDR  R0 [  R0 + 4H]
  54	     2800	CMP  R0 #  0
  56	     BF08	IT EQ
  58	 EC001155	TrapEQ  5 at pos     149
  62	     4780	BLX  R0
  64	 F8DDE000	LDR LR [ SP + 0H]
  68	 F11D0D04	ADDS SP SP # 4H
  72	     4770	BX LR

*)
