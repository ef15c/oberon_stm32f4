MODULE testString;
  VAR s: ARRAY 10 OF CHAR;

  PROCEDURE p(m: ARRAY OF CHAR);
  BEGIN
  END p;
BEGIN
  s := "bonjour";
  p(s)
END testString.

(*
ORTool.DecObj testString.rsc ~

decode testString.rsc
testString DEE64135   1   136
imports:
type descriptors

data    12
strings
bonjour
code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 A1E00008	STR   R1 SP       8
   4	 8FE00000	LDR LNK SP       0
   5	 4EE8000C	ADD SP SP     12
   6	 C700000F	B LNK
   7	 4EE90004	SUB SP SP      4
   8	 AFE00000	STR  LNK SP       0
   9	 80000009	LDR  R0  R0       9
  10	 40080000	ADD  R0  R0      0
  11	 81000002	LDR  R1  R0       2
  12	 4118000C	ADD  R1  R1     12
  13	 82100000	LDR  R2  R1       0
  14	 41180004	ADD  R1  R1      4
  15	 A2000000	STR   R2  R0       0
  16	 40080004	ADD  R0  R0      4
  17	 42220018	ASR  R2  R2     24
  18	 E9FFFFFA	BNE       -6
  19	 80000008	LDR  R0  R0       8
  20	 40080000	ADD  R0  R0      0
  21	 4100000A	MOV  R1  R0     10
  22	 F7FFFFE9	BL     -23
  23	 8FE00000	LDR LNK SP       0
  24	 4EE80004	ADD SP SP      4
  25	 C700000F	B LNK
commands:
entries
    28
pointer refs

fixP =        0
fixD =       19
fixT =        0


OM4Tool.DecObj testString.m4c ~
decode testString.m4c
testString DEE64135   1    96
imports:
type descriptors

data    12
strings
bonjour
code
commands:
entries
    14
pointer refs

fixP =        0
fixD =       44
fixT =        0
entry =       14
   0	     B403	PUSH R0 R1
   2	     B500	PUSH LR
   4	 F8DDE000	LDR LR [ SP + 0 ]
   8	 F11D0D0C	ADDS SP SP #12
  12	     4770	BX LR
  14	 F1BD0D04	SUBS SP SP #4
  18	 F8CDE000	STR LR [ SP + 0 ]
  22	 0000000B	LDR R0 [ MT + Base(0) ]
  26	 10000002	LDR R1 [ MT + Base(0) ]
  30	     310C	ADDS R1 #12
  32	 F8512B04	LDR R2 [ R1 ] + 4
  36	 F8402B04	STR R2 [ R0 ] + 4
  40	     1612	ASRS R2 R2 #24
  42	     D1F9	B NE #-14
  44	 00000009	LDR R0 [ MT + Base(0) ]
  48	     210A	MOVS R1 #10
  50	 F7FFFFE5	BL #-54
  54	 F8DDE000	LDR LR [ SP + 0 ]
  58	 F11D0D04	ADDS SP SP


*)

