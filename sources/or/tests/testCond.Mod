MODULE testCond;

PROCEDURE p(v: INTEGER);
  VAR b: BOOLEAN;
BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
END p;

BEGIN p(40)
END testCond.

(*
ORTool.DecObj testCond.rsc ~
decode testCond.rsc
testCond D8E1D5B7   1   128
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 80E00004	LDR  R0 SP       4
   4	 5009FFFF	SUB  R0  R0     -1
   5	 E6000003	BLE        3
   6	 80E00004	LDR  R0 SP       4
   7	 40090001	SUB  R0  R0      1
   8	 E5000006	BLT        6
   9	 80E00004	LDR  R0 SP       4
  10	 40090009	SUB  R0  R0      9
  11	 E6000005	BLE        5
  12	 80E00004	LDR  R0 SP       4
  13	 4009000B	SUB  R0  R0     11
  14	 ED000002	BGE        2
  15	 40000001	MOV  R0  R0      1
  16	 E7000001	B       1
  17	 40000000	MOV  R0  R0      0
  18	 B0E00008	STR   R0 SP       8
  19	 8FE00000	LDR LNK SP       0
  20	 4EE8000C	ADD SP SP     12
  21	 C700000F	B LNK
  22	 4EE90004	SUB SP SP      4
  23	 AFE00000	STR  LNK SP       0
  24	 40000028	MOV  R0  R0     40
  25	 F7FFFFE6	BL     -26
  26	 8FE00000	LDR LNK SP       0
  27	 4EE80004	ADD SP SP      4
  28	 C700000F	B LNK
commands:
entries
    88
pointer refs

fixP =        0
fixD =        0
fixT =        0


OM4Tool.DecObj testCond.m4c ~

decode testCond.m4c
testCond D8E1D5B7   1    92
imports:
type descriptors

data     0
strings

code
commands:
entries
    66
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       66
   0	 F1BD0D04	SUBS SP SP #4
   4	     B401	PUSH R0
   6	     B500	PUSH LR
   8	     9801	LDR R0 [SP + 4]
  10	 F1B03FFF	CMP R0 #-1
  14	     BFD8	IT LE
  16	 F000B805	BLE #10
  20	     9801	LDR R0 [SP + 4]
  22	     2801	CMP R0 #1
  24	     BFB8	IT LT
  26	 F000B808	BLT #16
  30	     9801	LDR R0 [SP + 4]
  32	     2809	CMP R0 #9
  34	     BFD8	IT LE
  36	 F000B805	BLE #10
  40	     9801	LDR R0 [SP + 4]
  42	     280B	CMP R0 #11
  44	     DA01	BGE #2
  46	     2001	MOVS R0 #1
  48	     E000	B #0
  50	     2000	MOVS R0 #0
  52	 F88D0008	STRB R0 [ SP + 8 ]
  56	 F85DEB04	LDR LR [ SP ] + 4
  60	 F11D0D08	ADDS SP SP #8
  64	     4770	BX LR
  66	     B500	PUSH LR
  68	     2028	MOVS R0 #40
  70	 F7FFFFDB	BL #-74
  74	 F85DEB04	LDR LR [ SP ] + 4
  78	     4770	BX LR


*)

