MODULE testAssert;
  PROCEDURE p;
    VAR a,b: INTEGER;
  BEGIN
    ASSERT(a # 0);
    ASSERT((a # 0) & (b # 0));
    ASSERT((a # 0) OR (b # 0));
    ASSERT((a # 0) & (b # 0) OR (a = 1) & (b = 1));
  END p;
  
END testAssert.


(*
ORTool.DecObj testAssert.rsc ~

decode testAssert.rsc
testAssert DAE74D27   1   140
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 80E00004	LDR  R0 SP       4
   3	 D100567C	BLEQ  MT
   4	 80E00004	LDR  R0 SP       4
   5	 E1000002	BEQ        2
   6	 80E00008	LDR  R0 SP       8
   7	 E9000001	BNE        1
   8	 D700767C	BL MT
   9	 80E00004	LDR  R0 SP       4
  10	 E9000002	BNE        2
  11	 80E00008	LDR  R0 SP       8
  12	 D100977C	BLEQ  MT
  13	 80E00004	LDR  R0 SP       4
  14	 E1000002	BEQ        2
  15	 80E00008	LDR  R0 SP       8
  16	 E9000007	BNE        7
  17	 80E00004	LDR  R0 SP       4
  18	 40090001	SUB  R0  R0      1
  19	 E9000003	BNE        3
  20	 80E00008	LDR  R0 SP       8
  21	 40090001	SUB  R0  R0      1
  22	 E1000001	BEQ        1
  23	 D700CC7C	BL MT
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


OM4Tool.DecObj testAssert.m4c ~

decode testAssert.m4c
testAssert DAE74D27   1   116
imports:
type descriptors

data     0
strings

code
commands:
entries
    96
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       96
   0	 F1BD0D08	SUBS SP SP #8
   4	     B500	PUSH LR
   6	     9801	LDR R0 [SP + 4]
   8	     2800	CMP R0 #0
  10	     BF08	IT EQ
  12	 EC000567	TrapEQ 7 at pos 86
  16	     9801	LDR R0 [SP + 4]
  18	     2800	CMP R0 #0
  20	 F0008003	BEQ #6, goes to 30
  24	     9802	LDR R0 [SP + 8]
  26	     2800	CMP R0 #0
  28	     D101	BNE #2, goes to 34
  30	 EC000767	Trap 7 at pos 118
  34	     9801	LDR R0 [SP + 4]
  36	     2800	CMP R0 #0
  38	 F0408005	BNE #10, goes to 52
  42	     9802	LDR R0 [SP + 8]
  44	     2800	CMP R0 #0
  46	     BF08	IT EQ
  48	 EC001177	TrapEQ 7 at pos 151
  52	     9801	LDR R0 [SP + 4]
  54	     2800	CMP R0 #0
  56	 F0008004	BEQ #8, goes to 68
  60	     9802	LDR R0 [SP + 8]
  62	     2800	CMP R0 #0
  64	 F0408009	BNE #18, goes to 86
  68	     9801	LDR R0 [SP + 4]
  70	     2801	CMP R0 #1
  72	 F0408003	BNE #6, goes to 82
  76	     9802	LDR R0 [SP + 8]
  78	     2801	CMP R0 #1
  80	     D001	BEQ #2, goes to 86
  82	 EC0014C7	Trap 7 at pos 204
  86	 F85DEB04	LDR LR [ SP ] + 4
  90	 F11D0D08	ADDS SP SP #8
  94	     4770	BX LR
  96	     B500	PUSH LR
  98	 F85DEB04	LDR LR [ SP ] + 4
 102	     4770	BX LR


*)
