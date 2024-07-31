MODULE testSFuncs2;
  VAR t: ARRAY 10 OF INTEGER;
    v1: INTEGER;
  PROCEDURE p(t: ARRAY OF INTEGER; s: ARRAY OF CHAR);
    VAR v: LONGINT;
      u: ARRAY 5 OF INTEGER;
  BEGIN
    v := LEN(t);
    v := LEN(s);
    v := LEN(u);
    v := LSL(v, 3);
    v := ROR(v, v1);
    v := ASR(v, 9);
    v := ADC(v, 3);
    v := SBC(v, v1);
    v := UML(v, 9)
  END p;
BEGIN
  v1 := LEN(t);
  p(t, "bonjour")
END testSFuncs2.


(*
ORTool.DecObj testSFuncs2.rsc ~

decode testSFuncs2.rsc
testSFuncs2 E31B1F2B   1   280
imports:
type descriptors

data    44
strings
bonjour|
code
   0	 4EE9002C	SUB SP SP     44
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 A1E00008	STR   R1 SP       8
   4	 A2E0000C	STR   R2 SP      12
   5	 A3E00010	STR   R3 SP      16
   6	 80E00008	LDR  R0 SP       8
   7	 A0E00014	STR   R0 SP      20
   8	 80E00010	LDR  R0 SP      16
   9	 A0E00014	STR   R0 SP      20
  10	 40000005	MOV  R0  R0      5
  11	 A0E00014	STR   R0 SP      20
  12	 80E00014	LDR  R0 SP      20
  13	 40010003	LSL  R0  R0      3
  14	 A0E00014	STR   R0 SP      20
  15	 80E00014	LDR  R0 SP      20
  16	 81000010	LDR  R1  R0      16
  17	 81100028	LDR  R1  R1      40
  18	 00030001	ROR  R0  R0  R1
  19	 A0E00014	STR   R0 SP      20
  20	 80E00014	LDR  R0 SP      20
  21	 40020009	ASR  R0  R0      9
  22	 A0E00014	STR   R0 SP      20
  23	 80E00014	LDR  R0 SP      20
  24	 41000003	MOV  R1  R0      3
  25	 20080001	ADD'  R0  R0  R1
  26	 A0E00014	STR   R0 SP      20
  27	 80E00014	LDR  R0 SP      20
  28	 8100000C	LDR  R1  R0      12
  29	 81100028	LDR  R1  R1      40
  30	 20090001	SUB'  R0  R0  R1
  31	 A0E00014	STR   R0 SP      20
  32	 80E00014	LDR  R0 SP      20
  33	 41000009	MOV  R1  R0      9
  34	 200A0001	MUL'  R0  R0  R1
  35	 A0E00014	STR   R0 SP      20
  36	 8FE00000	LDR LNK SP       0
  37	 4EE8002C	ADD SP SP     44
  38	 C700000F	B LNK
  39	 4EE90004	SUB SP SP      4
  40	 AFE00000	STR  LNK SP       0
  41	 4000000A	MOV  R0  R0     10
  42	 8100000E	LDR  R1  R0      14
  43	 A0100028	STR   R0  R1      40
  44	 80000002	LDR  R0  R0       2
  45	 40080000	ADD  R0  R0      0
  46	 4100000A	MOV  R1  R0     10
  47	 82000003	LDR  R2  R0       3
  48	 4228002C	ADD  R2  R2     44
  49	 43000008	MOV  R3  R0      8
  50	 F7FFFFCD	BL     -51
  51	 8FE00000	LDR LNK SP       0
  52	 4EE80004	ADD SP SP      4
  53	 C700000F	B LNK
commands:
entries
   156
pointer refs

fixP =        0
fixD =       47
fixT =        0
entry =      156


OM4Tool.DecObj testSFuncs2.m4c ~

decode testSFuncs2.m4c
testSFuncs2 E31B1F2B   1   200
imports:
type descriptors

data    44
strings
bonjour|
code
commands:
entries
    92
pointer refs

fixP =        0
fixD =      116
fixT =        0
entry =       92
   0	 F1BD0D18	SUBS SP SP #24
   4	     B40F	PUSH R0 R1 R2 R3
   6	     B500	PUSH LR
   8	     9802	LDR R0 [SP + 8]
  10	     9005	STR R0 [SP + 20]
  12	     9804	LDR R0 [SP + 16]
  14	     9005	STR R0 [SP + 20]
  16	     2005	MOVS R0 #5
  18	     9005	STR R0 [SP + 20]
  20	     9805	LDR R0 [SP + 20]
  22	     00C0	LSLS R0 R0 #3
  24	     9005	STR R0 [SP + 20]
  26	     9805	LDR R0 [SP + 20]
  28	 1000000E	MOV R1 lower 16-bits base(0)
  32	 0000D414	MOVT R1 higher 16-bits var(40)
  36	     6809	LDR R1 [ R1 + 0]
  38	     41C8	RORS R0 R1
  40	     9005	STR R0 [SP + 20]
  42	     9805	LDR R0 [SP + 20]
  44	     1240	ASRS R0 R0 #9
  46	     9005	STR R0 [SP + 20]
  48	     9805	LDR R0 [SP + 20]
  50	     2103	MOVS R1 #3
  52	     4148	ADCS R0 R1
  54	     9005	STR R0 [SP + 20]
  56	     9805	LDR R0 [SP + 20]
  58	 1000000F	MOV R1 lower 16-bits base(0)
  62	 0000D414	MOVT R1 higher 16-bits var(40)
  66	     6809	LDR R1 [ R1 + 0]
  68	     4188	SBCS R0 R1
  70	     9005	STR R0 [SP + 20]
  72	     9805	LDR R0 [SP + 20]
  74	     2109	MOVS R1 #9
  76	 FBA00101	UMULL R0 R1 R0 R1
  80	     9005	STR R0 [SP + 20]
  82	 F85DEB04	LDR LR [ SP ] + 4
  86	 F11D0D28	ADDS SP SP #40
  90	     4770	BX LR
  92	     B500	PUSH LR
  94	     200A	MOVS R0 #10
  96	 10000013	MOV R1 lower 16-bits base(0)
 100	 0000D414	MOVT R1 higher 16-bits var(40)
 104	     6008	STR R0 [ R1 + 0]
 106	 00000005	MOV R0 lower 16-bits base(0)
 110	 0000D414	MOVT R0 higher 16-bits var(0)
 114	     210A	MOVS R1 #10
 116	 20000005	MOV R2 lower 16-bits base(0)
 120	 0000D414	MOVT R2 higher 16-bits var(44)
 124	     2308	MOVS R3 #8
 126	 F7FFFFBF	BL #-130, goes to 0
 130	 F85DEB04	LDR LR [ SP ] + 4
 134	     4770	BX LR



*)
