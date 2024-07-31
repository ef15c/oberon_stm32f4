MODULE testRepeat;

  PROCEDURE p;
    VAR i, j: INTEGER;
  BEGIN
    i := 10; REPEAT i := i-1 UNTIL (i = 0) & (i = i);
    i := 10; REPEAT i := i-1 UNTIL (i = 0) OR (i = i)
  END p;
  
END testRepeat.


(*
ORTool.DecObj testRepeat.rsc ~

decode testRepeat.rsc
testRepeat DAE43F27   1   140
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 4000000A	MOV  R0  R0     10
   3	 A0E00004	STR   R0 SP       4
   4	 80E00004	LDR  R0 SP       4
   5	 40090001	SUB  R0  R0      1
   6	 A0E00004	STR   R0 SP       4
   7	 80E00004	LDR  R0 SP       4
   8	 E9FFFFFB	BNE       -5
   9	 80E00004	LDR  R0 SP       4
  10	 81E00004	LDR  R1 SP       4
  11	 00090001	SUB  R0  R0  R1
  12	 E9FFFFF7	BNE       -9
  13	 4000000A	MOV  R0  R0     10
  14	 A0E00004	STR   R0 SP       4
  15	 80E00004	LDR  R0 SP       4
  16	 40090001	SUB  R0  R0      1
  17	 A0E00004	STR   R0 SP       4
  18	 80E00004	LDR  R0 SP       4
  19	 E1000004	BEQ        4
  20	 80E00004	LDR  R0 SP       4
  21	 81E00004	LDR  R1 SP       4
  22	 00090001	SUB  R0  R0  R1
  23	 E9FFFFF7	BNE       -9
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


OM4Tool.DecObj testRepeat.m4c ~

decode testRepeat.m4c
testRepeat DAE43F27   1    88
imports:
type descriptors

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
 00000000	 F1BD0D08	SUBS SP SP #8
 00000004	     B500	PUSH LR
 00000006	     200A	MOVS R0 #10
 00000008	     9001	STR R0 [SP + 4]
 0000000A	     9801	LDR R0 [SP + 4]
 0000000C	     1E40	SUBS R0 R0 #1
 0000000E	     9001	STR R0 [SP + 4]
 00000010	     9801	LDR R0 [SP + 4]
 00000012	     2800	CMP R0 #0
 00000014	 F47FAFF9	BNE #-14, goes to  0000000A
 00000018	     9801	LDR R0 [SP + 4]
 0000001A	     9901	LDR R1 [SP + 4]
 0000001C	     4288	CMP R0 R1
 0000001E	     D1F4	BNE #-24, goes to  0000000A
 00000020	     200A	MOVS R0 #10
 00000022	     9001	STR R0 [SP + 4]
 00000024	     9801	LDR R0 [SP + 4]
 00000026	     1E40	SUBS R0 R0 #1
 00000028	     9001	STR R0 [SP + 4]
 0000002A	     9801	LDR R0 [SP + 4]
 0000002C	     2800	CMP R0 #0
 0000002E	 F0008004	BEQ #8, goes to  0000003A
 00000032	     9801	LDR R0 [SP + 4]
 00000034	     9901	LDR R1 [SP + 4]
 00000036	     4288	CMP R0 R1
 00000038	     D1F4	BNE #-24, goes to  00000024
 0000003A	 F85DEB04	LDR LR [ SP ] + 4
 0000003E	 F11D0D08	ADDS SP SP #8
 00000042	     4770	BX LR
 00000044	     B500	PUSH LR
 00000046	 F85DEB04	LDR LR [ SP ] + 4
 0000004A	     4770	BX LR


*)
