MODULE testInEx;
  PROCEDURE p;
    VAR s: SET;
      p: INTEGER;
  BEGIN
    INCL(s, 3); INCL(s, p);
    EXCL(s, 5); EXCL(s, p);
  END p;
  
END testInEx.


(*
ORTool.DecObj testInEx.rsc ~

decode testInEx.rsc
testInEx ECB8D4BD   1   140
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 40E80004	ADD  R0 SP      4
   3	 81000000	LDR  R1  R0       0
   4	 41160008	IOR  R1  R1      8
   5	 A1000000	STR   R1  R0       0
   6	 40E80004	ADD  R0 SP      4
   7	 81000000	LDR  R1  R0       0
   8	 82E00008	LDR  R2 SP       8
   9	 43000001	MOV  R3  R0      1
  10	 02310002	LSL  R2  R3  R2
  11	 01160002	IOR  R1  R1  R2
  12	 A1000000	STR   R1  R0       0
  13	 40E80004	ADD  R0 SP      4
  14	 81000000	LDR  R1  R0       0
  15	 41150020	ANN  R1  R1     32
  16	 A1000000	STR   R1  R0       0
  17	 40E80004	ADD  R0 SP      4
  18	 81000000	LDR  R1  R0       0
  19	 82E00008	LDR  R2 SP       8
  20	 43000001	MOV  R3  R0      1
  21	 02310002	LSL  R2  R3  R2
  22	 01150002	ANN  R1  R1  R2
  23	 A1000000	STR   R1  R0       0
  24	 8FE00000	LDR LNK SP       0
  25	 4EE8000C	ADD SP SP     12
  26	 C700000F	B LNK
  27	 4EE90004	SUB SP SP      4
  28	 AFE00000	STR  LNK SP       0
  29	 8FE00000	LDR LNK SP       0
  30	 4EE80004	ADD SP SP      4
  31	 C700000F	B LNK
commands:
entries
   108
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      108


OM4Tool.DecObj testInEx.m4c ~

decode testInEx.m4c
testInEx ECB8D4BD   1    96
imports:
type descriptors

data     0
strings

code
commands:
entries
    76
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       76
   0	 F1BD0D08	SUBS SP SP #8
   4	     B500	PUSH LR
   6	 F11D0004	ADDS R0 SP #4
  10	     6801	LDR R1 [ R0 + 0]
  12	 F0510108	ORRS R1 R1 #8
  16	     6001	STR R1 [ R0 + 0]
  18	 F11D0004	ADDS R0 SP #4
  22	     6801	LDR R1 [ R0 + 0]
  24	     9A02	LDR R2 [SP + 8]
  26	     2301	MOVS R3 #1
  28	 FA13F202	LSLS R2 R3 R2
  32	     4311	ORRS R1 R2
  34	     6001	STR R1 [ R0 + 0]
  36	 F11D0004	ADDS R0 SP #4
  40	     6801	LDR R1 [ R0 + 0]
  42	 F0310120	BICS R1 R1 #32
  46	     6001	STR R1 [ R0 + 0]
  48	 F11D0004	ADDS R0 SP #4
  52	     6801	LDR R1 [ R0 + 0]
  54	     9A02	LDR R2 [SP + 8]
  56	     2301	MOVS R3 #1
  58	 FA13F202	LSLS R2 R3 R2
  62	     4391	BICS R1 R2
  64	     6001	STR R1 [ R0 + 0]
  66	 F85DEB04	LDR LR [ SP ] + 4
  70	 F11D0D08	ADDS SP SP #8
  74	     4770	BX LR
  76	     B500	PUSH LR
  78	 F85DEB04	LDR LR [ SP ] + 4
  82	     4770	BX LR


*)
