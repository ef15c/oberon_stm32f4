MODULE testIntArith;
    
PROCEDURE p;
    VAR a, b, c: INTEGER;
BEGIN
  a := b + c;
  a := b - c;
  a := b * c;
  a := b DIV c;
  a := b MOD c;
END p;

END testIntArith.

(*
ORTool.DecObj testIntArith.rsc ~

decode testIntArith.rsc
testIntArith 1E5C3E2F   1   144
imports:
type descriptors

data     0
strings

code
   0	 4EE90010	SUB SP SP     16
   1	 AFE00000	STR  LNK SP       0
   2	 80E00008	LDR  R0 SP       8
   3	 81E0000C	LDR  R1 SP      12
   4	 00080001	ADD  R0  R0  R1
   5	 A0E00004	STR   R0 SP       4
   6	 80E00008	LDR  R0 SP       8
   7	 81E0000C	LDR  R1 SP      12
   8	 00090001	SUB  R0  R0  R1
   9	 A0E00004	STR   R0 SP       4
  10	 80E00008	LDR  R0 SP       8
  11	 81E0000C	LDR  R1 SP      12
  12	 000A0001	MUL  R0  R0  R1
  13	 A0E00004	STR   R0 SP       4
  14	 80E0000C	LDR  R0 SP      12
  15	 D600886C	BLLE  MT
  16	 81E00008	LDR  R1 SP       8
  17	 001B0000	DIV  R0  R1  R0
  18	 A0E00004	STR   R0 SP       4
  19	 80E0000C	LDR  R0 SP      12
  20	 D600996C	BLLE  MT
  21	 81E00008	LDR  R1 SP       8
  22	 001B0000	DIV  R0  R1  R0
  23	 20000000	MOV'  R0  R0  R0
  24	 A0E00004	STR   R0 SP       4
  25	 8FE00000	LDR LNK SP       0
  26	 4EE80010	ADD SP SP     16
  27	 C700000F	B LNK
  28	 4EE90004	SUB SP SP      4
  29	 AFE00000	STR  LNK SP       0
  30	 8FE00000	LDR LNK SP       0
  31	 4EE80004	ADD SP SP      4
  32	 C700000F	B LNK
commands:
entriespointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      112

   112


OM4Tool.DecObj testIntArith.m4c ~

decode testIntArith.m4c
testIntArith 1E5C3E2F   1   100
imports:
type descriptors

data     0
strings

code
commands:
entries
    80
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       80
entry =       80
   0	 F1BD0D0C	SUBS SP SP #12
   4	     B500	PUSH LR
   6	     9802	LDR R0 [SP + 8]
   8	     9903	LDR R1 [SP + 12]
  10	     1840	ADDS R0 R0 R1
  12	     9001	STR R0 [SP + 4]
  14	     9802	LDR R0 [SP + 8]
  16	     9903	LDR R1 [SP + 12]
  18	     1A40	SUBS R0 R0 R1
  20	     9001	STR R0 [SP + 4]
  22	     9802	LDR R0 [SP + 8]
  24	     9903	LDR R1 [SP + 12]
  26	     4348	MULS R0 R1 R0
  28	     9001	STR R0 [SP + 4]
  30	     9803	LDR R0 [SP + 12]
  32	     2800	CMP R0 #0
  34	     BFD8	IT LE
  36	 EC001086	TrapLE 6 at pos 136
  40	     9902	LDR R1 [SP + 8]
  42	 FBB1F0F0	UDIV R0 R1 R0
  46	     9001	STR R0 [SP + 4]
  48	     9803	LDR R0 [SP + 12]
  50	     2800	CMP R0 #0
  52	     BFD8	IT LE
  54	 EC001196	TrapLE 6 at pos 153
  58	     9902	LDR R1 [SP + 8]
  60	 FBB1F2F0	UDIV R2 R1 R0
  64	     4342	MULS R2 R0 R2
  66	     1A88	SUBS R0 R1 R2
  68	     9001	STR R0 [SP + 4]
  70	 F85DEB04	LDR LR [ SP ] + 4
  74	 F11D0D0C	ADDS SP SP #12
  78	     4770	BX LR
  80	     B500	PUSH LR
  82	 F85DEB04	LDR LR [ SP ] + 4
  86	     4770	BX LR


*)

