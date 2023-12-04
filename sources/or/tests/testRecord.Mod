MODULE testRecord;

  TYPE rec = RECORD
    a, b: INTEGER;
    c, d: ARRAY 2000 OF INTEGER;
	e: INTEGER
  END;

  PROCEDURE p(VAR r: rec);
  BEGIN
    r.a := 1;
    r.b := 2;
    r.c := r.d;
    r.e := 3
  END p;
  
END testRecord.


(*
ORTool.DecObj testRecord.rsc ~
decode testRecord.rsc
testRecord E4D72F38   1   160
imports:
type descriptors
 00003F00 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 A1E00008	STR   R1 SP       8
   4	 40000001	MOV  R0  R0      1
   5	 81E00004	LDR  R1 SP       4
   6	 A0100000	STR   R0  R1       0
   7	 40000002	MOV  R0  R0      2
   8	 81E00004	LDR  R1 SP       4
   9	 A0100004	STR   R0  R1       4
  10	 80E00004	LDR  R0 SP       4
  11	 40080008	ADD  R0  R0      8
  12	 81E00004	LDR  R1 SP       4
  13	 41181F48	ADD  R1  R1   8008
  14	 420007D0	MOV  R2  R0   2000
  15	 83100000	LDR  R3  R1       0
  16	 41180004	ADD  R1  R1      4
  17	 A3000000	STR   R3  R0       0
  18	 40080004	ADD  R0  R0      4
  19	 42290001	SUB  R2  R2      1
  20	 E9FFFFFA	BNE       -6
  21	 40000003	MOV  R0  R0      3
  22	 81E00004	LDR  R1 SP       4
  23	 A0103E88	STR   R0  R1   16008
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



OM4Tool.DecObj testRecord.m4c ~
decode testRecord.m4c
testRecord E4D72F38   1   108
imports:
type descriptors
 00003F00 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
commands:
entries
    68
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       68
   0	     B403	PUSH R0 R1
   2	     B500	PUSH LR
   4	     2001	MOVS R0 #1
   6	     9901	LDR R1 [SP + 4]
   8	     6008	STR R0 [ R1 + 0]
  10	     2002	MOVS R0 #2
  12	     9901	LDR R1 [SP + 4]
  14	     6048	STR R0 [ R1 + 4]
  16	     9801	LDR R0 [SP + 4]
  18	     3008	ADDS R0 #8
  20	     9901	LDR R1 [SP + 4]
  22	 F6417248	MOV R2 #  8008
  26	     1889	ADDS R1 R1 R2
  28	 F24072D0	MOV R2 #  2000
  32	 F8513B04	LDR R3 [ R1 ] + 4
  36	 F8403B04	STR R3 [ R0 ] + 4
  40	     1E52	SUBS R2 R2 #1
  42	     D1F9	BNE #-14, goes to 32
  44	     2003	MOVS R0 #3
  46	     9901	LDR R1 [SP + 4]
  48	 F2430200	MOV R2 # 12288
  52	     188A	ADDS R2 R1 R2
  54	 F8C20E88	STR R0 [ R2 + 3720 ]
  58	 F85DEB04	LDR LR [ SP ] + 4
  62	 F11D0D08	ADDS SP SP #8
  66	     4770	BX LR
  68	     B500	PUSH LR
  70	 F85DEB04	LDR LR [ SP ] + 4
  74	     4770	BX LR



*)
