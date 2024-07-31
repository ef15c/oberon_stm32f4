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

fixP =       22
fixD =      110
fixT =        0
entry =        0
 00000000	     B500	PUSH LR
 00000002	 01000001	MOV R0 lower 16-bits base(1)
 00000006	 00000002	MOVT R0 higher 16-bits var(2)
 0000000A	     6800	LDR R0 [ R0 + 0]
 0000000C	 10000005	MOV R1 lower 16-bits base(0)
 00000010	 00000000	MOVT R1 higher 16-bits base + 0
 00000014	     6008	STR R0 [ R1 + 0]
 00000016	 1060000B	BL Mod(  1) proc(6)
 0000001A	 01000007	MOV R0 lower 16-bits base(1)
 0000001E	 00000106	MOVT R0 higher 16-bits var(6) Prog based
 00000022	 10000004	MOV R1 lower 16-bits base(0)
 00000026	 00000004	MOVT R1 higher 16-bits base + 4
 0000002A	     6008	STR R0 [ R1 + 0]
 0000002C	 00000005	MOV R0 lower 16-bits base(0)
 00000030	 00000004	MOVT R0 higher 16-bits base + 4
 00000034	     6800	LDR R0 [ R0 + 0]
 00000036	     4780	BLX R0
 00000038	 01000006	MOV R0 lower 16-bits base(1)
 0000003C	 00000004	MOVT R0 higher 16-bits var(4)
 00000040	 ED900A00	VLDR S0 [ R0 + 0 ]
 00000044	 00000006	MOV R0 lower 16-bits base(0)
 00000048	 00000008	MOVT R0 higher 16-bits base + 8
 0000004C	 ED800A00	VSTR S0 [ R0 + 0 ]
 00000050	 01000006	MOV R0 lower 16-bits base(1)
 00000054	 00000005	MOVT R0 higher 16-bits var(5)
 00000058	     6800	LDR R0 [ R0 + 0]
 0000005A	 10000005	MOV R1 lower 16-bits base(0)
 0000005E	 00000000	MOVT R1 higher 16-bits base + 0
 00000062	     6008	STR R0 [ R1 + 0]
 00000064	 01000005	MOV R0 lower 16-bits base(1)
 00000068	 00000005	MOVT R0 higher 16-bits var(5)
 0000006C	     6840	LDR R0 [ R0 + 4]
 0000006E	 10000005	MOV R1 lower 16-bits base(0)
 00000072	 00000000	MOVT R1 higher 16-bits base + 0
 00000076	     6008	STR R0 [ R1 + 0]
 00000078	 F85DEB04	LDR LR [ SP ] + 4
 0000007C	     4770	BX LR


*)

