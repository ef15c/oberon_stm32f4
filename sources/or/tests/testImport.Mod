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
testImport E4E4472F   1   166
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

fixP =       22
fixD =      114
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 01000001	MOV R0 lower 16-bits base(1)
   6	 0000D334	MOVT R0 higher 16-bits var(2)
  10	     6800	LDR R0 [ R0 + 0]
  12	 10000005	MOV R1 lower 16-bits base(0)
  16	 0000D334	MOVT R1 higher 16-bits var(0)
  20	     6008	STR R0 [ R1 + 0]
  22	 1060000B	BL Mod(  1) proc(6)
  26	 01000007	MOV R0 lower 16-bits base(1)
  30	 0000D334	MOVT R0 higher 16-bits var(6) Prog based
  34	 10000004	MOV R1 lower 16-bits base(0)
  38	 0000D334	MOVT R1 higher 16-bits var(4)
  42	     6008	STR R0 [ R1 + 0]
  44	 00000005	MOV R0 lower 16-bits base(0)
  48	 0000D334	MOVT R0 higher 16-bits var(4)
  52	     6800	LDR R0 [ R0 + 0]
  54	     2800	CMP R0 #0
  56	     BF08	IT EQ
  58	 EC0012D5	TrapEQ 5 at pos 173
  62	     4780	BLX R0
  64	 0100000A	MOV R0 lower 16-bits base(1)
  68	 0000D334	MOVT R0 higher 16-bits var(4)
  72	     6800	LDR R0 [ R0 + 0]
  74	 10000005	MOV R1 lower 16-bits base(0)
  78	 0000D334	MOVT R1 higher 16-bits var(8)
  82	     6008	STR R0 [ R1 + 0]
  84	 01000005	MOV R0 lower 16-bits base(1)
  88	 0000D334	MOVT R0 higher 16-bits var(5)
  92	     6800	LDR R0 [ R0 + 0]
  94	 10000005	MOV R1 lower 16-bits base(0)
  98	 0000D334	MOVT R1 higher 16-bits var(0)
 102	     6008	STR R0 [ R1 + 0]
 104	 01000005	MOV R0 lower 16-bits base(1)
 108	 0000D334	MOVT R0 higher 16-bits var(5)
 112	     6840	LDR R0 [ R0 + 1]
 114	 10000005	MOV R1 lower 16-bits base(0)
 118	 0000D334	MOVT R1 higher 16-bits var(0)
 122	     6008	STR R0 [ R1 + 0]
 124	 F85DEB04	LDR LR [ SP ] + 4
 128	     4770	BX LR


*)

