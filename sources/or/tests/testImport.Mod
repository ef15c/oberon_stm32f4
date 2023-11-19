MODULE testImport;
  IMPORT testExport;
  VAR v1: LONGINT;
    p1: PROCEDURE;
    r1: REAL;
  
BEGIN v1 := testExport.l;
  testExport.p;
  p1 := testExport.p;
  p1;
  r1 := testExport.r;
  v1 := testExport.v.x;
  v1 := testExport.v.y
END testImport.

(*
ORTool.DecObj testImport.rsc ~


decode testImport.rsc
testImport E4E4472F   1   156
imports:
	testExport 633B402B
type descriptors

data    12
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80100002	LDR  R0  R1       2
   3	 80000002	LDR  R0  R0       2
   4	 81000002	LDR  R1  R0       2
   5	 A0100000	STR   R0  R1       0
   6	 F7106006	BL   24582
   7	 80100003	LDR  R0  R1       3
   8	 40080106	ADD  R0  R0    262
   9	 81000002	LDR  R1  R0       2
  10	 A0100004	STR   R0  R1       4
  11	 80000002	LDR  R0  R0       2
  12	 80000004	LDR  R0  R0       4
  13	 D100AD5C	BLEQ  MT
  14	 D7000000	BL  R0
  15	 80100004	LDR  R0  R1       4
  16	 80000004	LDR  R0  R0       4
  17	 81000002	LDR  R1  R0       2
  18	 A0100008	STR   R0  R1       8
  19	 80100002	LDR  R0  R1       2
  20	 40080005	ADD  R0  R0      5
  21	 80000000	LDR  R0  R0       0
  22	 81000003	LDR  R1  R0       3
  23	 A0100000	STR   R0  R1       0
  24	 80100002	LDR  R0  R1       2
  25	 40080005	ADD  R0  R0      5
  26	 80000004	LDR  R0  R0       4
  27	 81000003	LDR  R1  R0       3
  28	 A0100000	STR   R0  R1       0
  29	 8FE00000	LDR LNK SP       0
  30	 4EE80004	ADD SP SP      4
  31	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        6
fixD =       27
fixT =        0

OM4Tool.DecObj testImport.m4c ~


decode testImport.m4c
testImport E4E4472F   1   164
imports:
	testExport 633B402B
type descriptors

data    12
strings

code
commands:
entries
     0
pointer refs

fixP =       24
fixD =      110
fixT =        0
entry =        0
   0	 F1BD0D04	SUBS SP SP #4
   4	 F8CDE000	STR LR [ SP + 0 ]
   8	 01000004	LDR R0 [ MT + Base(1) ]
  12	 00000002	LDR R0 [ R0 + Var(2) ]
  16	 10000004	LDR R1 [ MT + Base(0) ]
  20	 F8C10000	STR R0 [ R1 + 0 ]
  24	 1060000C	BL Mod(  1) proc(6)
  28	 01000006	LDR R0 [ MT + Base(1) ]
  32	 40000106	ADD R0 [ R0 + Var(6) ] Prog based
  36	 10000004	LDR R1 [ MT + Base(0) ]
  40	 F8C10004	STR R0 [ R1 + 4 ]
  44	 00000004	LDR R0 [ MT + Base(0) ]
  48	 F8D00004	LDR R0 [ R0 + 4 ]
  52	     2800	CMP R0 #  0
  54	     BF08	IT EQ
  56	 EC0012D5	TrapEQ  5 at pos     173
  60	     4780	BLX R0
  62	 01000009	LDR R0 [ MT + Base(1) ]
  66	 60000004	VLDR S0 [ R0 + Var(4) ]
  70	 00000004	LDR R0 [ MT + Base(0) ]
  74	 ED800A02	VSTR S0 [ R0 + 8 ]
  78	 01000004	LDR R0 [ MT + Base(1) ]
  82	 40000005	ADD R0 [ R0 + Var(5) ]
  86	 F8D00000	LDR R0 [ R0 + 0 ]
  90	 10000006	LDR R1 [ MT + Base(0) ]
  94	 F8C10000	STR R0 [ R1 + 0 ]
  98	 01000004	LDR R0 [ MT + Base(1) ]
 102	 40000005	ADD R0 [ R0 + Var(5) ]
 106	 F8D00004	LDR R0 [ R0 + 4 ]
 110	 10000006	LDR R1 [ MT + Base(0) ]
 114	 F8C10000	STR R0 [ R1 + 0 ]
 118	 F8DDE000	LDR LR [ SP + 0 ]
 122	 F11D0D04	ADDS SP SP #4

*)

