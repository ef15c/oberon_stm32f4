MODULE testSet;
    
PROCEDURE p;
    VAR a, b, c: SET;
      m, n: LONGINT;
BEGIN
  c := {2..5};
  c := {m..5};
  c := {2..n};
  c := {m..20};
  c := {21..n};
  c := {m..n};
  c := a*b;
  c := a+b;
  c := a-b;
  c := a/b
END p;

END testSet.

(*
ORTool.DecObj testSet.rsc ~

decode testSet.rsc
testSet 74E7CAC8   1   268
imports:
type descriptors

data     0
strings

code
   0	 4EE90018	SUB SP SP     24
   1	 AFE00000	STR  LNK SP       0
   2	 4000003C	MOV  R0  R0     60
   3	 A0E0000C	STR   R0 SP      12
   4	 80E00010	LDR  R0 SP      16
   5	 5100FFFF	MOV  R1  R0     -1
   6	 00110000	LSL  R0  R1  R0
   7	 5100FFC0	MOV  R1  R0    -64
   8	 00050001	ANN  R0  R0  R1
   9	 A0E0000C	STR   R0 SP      12
  10	 80E00014	LDR  R0 SP      20
  11	 5100FFFE	MOV  R1  R0     -2
  12	 00110000	LSL  R0  R1  R0
  13	 5007FFFF	XOR  R0  R0     -1
  14	 5004FFFC	AND  R0  R0     -4
  15	 A0E0000C	STR   R0 SP      12
  16	 80E00010	LDR  R0 SP      16
  17	 5100FFFF	MOV  R1  R0     -1
  18	 00110000	LSL  R0  R1  R0
  19	 41000014	MOV  R1  R0     20
  20	 5200FFFE	MOV  R2  R0     -2
  21	 01210001	LSL  R1  R2  R1
  22	 00050001	ANN  R0  R0  R1
  23	 A0E0000C	STR   R0 SP      12
  24	 40000015	MOV  R0  R0     21
  25	 5100FFFF	MOV  R1  R0     -1
  26	 00110000	LSL  R0  R1  R0
  27	 81E00014	LDR  R1 SP      20
  28	 5200FFFE	MOV  R2  R0     -2
  29	 01210001	LSL  R1  R2  R1
  30	 00050001	ANN  R0  R0  R1
  31	 A0E0000C	STR   R0 SP      12
  32	 80E00010	LDR  R0 SP      16
  33	 5100FFFF	MOV  R1  R0     -1
  34	 00110000	LSL  R0  R1  R0
  35	 81E00014	LDR  R1 SP      20
  36	 5200FFFE	MOV  R2  R0     -2
  37	 01210001	LSL  R1  R2  R1
  38	 00050001	ANN  R0  R0  R1
  39	 A0E0000C	STR   R0 SP      12
  40	 80E00004	LDR  R0 SP       4
  41	 81E00008	LDR  R1 SP       8
  42	 00040001	AND  R0  R0  R1
  43	 A0E0000C	STR   R0 SP      12
  44	 80E00004	LDR  R0 SP       4
  45	 81E00008	LDR  R1 SP       8
  46	 00060001	IOR  R0  R0  R1
  47	 A0E0000C	STR   R0 SP      12
  48	 80E00004	LDR  R0 SP       4
  49	 81E00008	LDR  R1 SP       8
  50	 00050001	ANN  R0  R0  R1
  51	 A0E0000C	STR   R0 SP      12
  52	 80E00004	LDR  R0 SP       4
  53	 81E00008	LDR  R1 SP       8
  54	 00070001	XOR  R0  R0  R1
  55	 A0E0000C	STR   R0 SP      12
  56	 8FE00000	LDR LNK SP       0
  57	 4EE80018	ADD SP SP     24
  58	 C700000F	B LNK
  59	 4EE90004	SUB SP SP      4
  60	 AFE00000	STR  LNK SP       0
  61	 8FE00000	LDR LNK SP       0
  62	 4EE80004	ADD SP SP      4
  63	 C700000F	B LNK
commands:
entries
   236
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      236



OM4Tool.DecObj testSet.m4c ~

decode testSet.m4c
testSet 74E7CAC8   1   186
imports:
type descriptors

data     0
strings

code
commands:
entries
   166
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      166
   0	 F1BD0D14	SUBS SP SP #20
   4	     B500	PUSH LR
   6	     203C	MOVS R0 #60
   8	     9003	STR R0 [SP + 12]
  10	     9804	LDR R0 [SP + 16]
  12	 F05F31FF	MOVS R1 #-1
  16	 FA11F000	LSLS R0 R1 R0
  20	 F07F013F	MVNS R1 #63
  24	     4388	BICS R0 R1
  26	     9003	STR R0 [SP + 12]
  28	     9805	LDR R0 [SP + 20]
  30	 F07F0101	MVNS R1 #1
  34	 FA11F000	LSLS R0 R1 R0
  38	 F09030FF	EORS R0 R0 #-1
  42	 F07F0103	MVNS R1 #3
  46	 EA100001	ANDS R0 R0 R1 LSL #0
  50	     9003	STR R0 [SP + 12]
  52	     9804	LDR R0 [SP + 16]
  54	 F05F31FF	MOVS R1 #-1
  58	 FA11F000	LSLS R0 R1 R0
  62	     2114	MOVS R1 #20
  64	 F07F0201	MVNS R2 #1
  68	 FA12F101	LSLS R1 R2 R1
  72	     4388	BICS R0 R1
  74	     9003	STR R0 [SP + 12]
  76	     2015	MOVS R0 #21
  78	 F05F31FF	MOVS R1 #-1
  82	 FA11F000	LSLS R0 R1 R0
  86	     9905	LDR R1 [SP + 20]
  88	 F07F0201	MVNS R2 #1
  92	 FA12F101	LSLS R1 R2 R1
  96	     4388	BICS R0 R1
  98	     9003	STR R0 [SP + 12]
 100	     9804	LDR R0 [SP + 16]
 102	 F05F31FF	MOVS R1 #-1
 106	 FA11F000	LSLS R0 R1 R0
 110	     9905	LDR R1 [SP + 20]
 112	 F07F0201	MVNS R2 #1
 116	 FA12F101	LSLS R1 R2 R1
 120	     4388	BICS R0 R1
 122	     9003	STR R0 [SP + 12]
 124	     9801	LDR R0 [SP + 4]
 126	     9902	LDR R1 [SP + 8]
 128	     4008	ANDS R0 R1
 130	     9003	STR R0 [SP + 12]
 132	     9801	LDR R0 [SP + 4]
 134	     9902	LDR R1 [SP + 8]
 136	     4308	ORRS R0 R1
 138	     9003	STR R0 [SP + 12]
 140	     9801	LDR R0 [SP + 4]
 142	     9902	LDR R1 [SP + 8]
 144	     4388	BICS R0 R1
 146	     9003	STR R0 [SP + 12]
 148	     9801	LDR R0 [SP + 4]
 150	     9902	LDR R1 [SP + 8]
 152	     4048	EORS R0 R1
 154	     9003	STR R0 [SP + 12]
 156	 F85DEB04	LDR LR [ SP ] + 4
 160	 F11D0D14	ADDS SP SP #20
 164	     4770	BX LR
 166	     B500	PUSH LR
 168	 F85DEB04	LDR LR [ SP ] + 4
 172	     4770	BX LR



*)

