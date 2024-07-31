MODULE testPackUnpack;
  PROCEDURE p;
    VAR x: REAL;
      e: INTEGER;
  BEGIN
    PACK(x, e);
    UNPK(x, e);
  END p;
BEGIN
END testPackUnpack.


(*
ORTool.DecObj testPackUnpack.rsc ~

decode testPackUnpack.rsc
testPackUnpack 4247A07C   1   100
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 80E00004	LDR  R0 SP       4
   3	 81E00008	LDR  R1 SP       8
   4	 41110017	LSL  R1  R1     23
   5	 00080001	ADD  R0  R0  R1
   6	 A0E00004	STR   R0 SP       4
   7	 80E00004	LDR  R0 SP       4
   8	 41020017	ASR  R1  R0     23
   9	 4119007F	SUB  R1  R1    127
  10	 A1E00008	STR   R1 SP       8
  11	 41110017	LSL  R1  R1     23
  12	 00090001	SUB  R0  R0  R1
  13	 A0E00004	STR   R0 SP       4
  14	 8FE00000	LDR LNK SP       0
  15	 4EE8000C	ADD SP SP     12
  16	 C700000F	B LNK
  17	 4EE90004	SUB SP SP      4
  18	 AFE00000	STR  LNK SP       0
  19	 8FE00000	LDR LNK SP       0
  20	 4EE80004	ADD SP SP      4
  21	 C700000F	B LNK
commands:
entries
    68
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       68


OM4Tool.DecObj testPackUnpack.m4c ~

decode testPackUnpack.m4c
testPackUnpack 4247A07C   1    60
imports:
type descriptors

data     0
strings

code
commands:
entries
    40
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       40
   0	 F1BD0D08	SUBS SP SP #8
   4	     B500	PUSH LR
   6	     9801	LDR R0 [SP + 4]
   8	     9902	LDR R1 [SP + 8]
  10	 EB1050C1	ADDS R0 R0 R1 LSL #23
  14	     9001	STR R0 [SP + 4]
  16	     9801	LDR R0 [SP + 4]
  18	     15C1	ASRS R1 R0 #23
  20	     397F	SUBS R1 #127
  22	     9102	STR R1 [SP + 8]
  24	 EBB050C1	SUBS R0 R0 R1 LSL #23
  28	     9001	STR R0 [SP + 4]
  30	 F85DEB04	LDR LR [ SP ] + 4
  34	 F11D0D08	ADDS SP SP #8
  38	     4770	BX LR
  40	     B500	PUSH LR
  42	 F85DEB04	LDR LR [ SP ] + 4
  46	     4770	BX LR


*)
