MODULE testCond;
  VAR v: LONGINT;
    b: BOOLEAN;
  
BEGIN b := v=-1;
END testCond.

(*
ORTool.DecObj testCond.rsc ~
decode testCond.rsc
testCond D8E1D5B7   1    76
imports:
type descriptors

data     8
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80000002	LDR  R0  R0       2
   3	 80000000	LDR  R0  R0       0
   4	 5009FFFF	SUB  R0  R0     -1
   5	 E9000002	BNE        2
   6	 40000001	MOV  R0  R0      1
   7	 E7000001	B       1
   8	 40000000	MOV  R0  R0      0
   9	 81000007	LDR  R1  R0       7
  10	 B0100004	STR   R0  R1       4
  11	 8FE00000	LDR LNK SP       0
  12	 4EE80004	ADD SP SP      4
  13	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =        9
fixT =        0
entry =        0


OM4Tool.DecObj testCond.m4c ~
decode testCond.m4c
testCond D8E1D5B7   1    64
imports:
type descriptors

data     8
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =       26
fixT =        0
entry =        0
  0	 F1BD0D04	SUBS SP SP #4
   4	 F8CDE000	STR LR [ SP + 0 ]
   8	 00000004	LDR R0 [ MT + Base(0) ]
  12	 F8D00000	LDR R0 [ R0 + 0 ]
  16	 F1B03FFF	CMP R0 #-1
  20	     BF0C	ITE EQ
  22	     2001	MOVEQ R0 #  1
  24	     2000	MOVNE R0 #  0
  26	 10000009	LDR R1 [ MT + Base(0) ]
  30	 F8810004	STRB R0 [ R1 + 4 ]
  34	 F8DDE000	LDR LR [ SP + 0 ]
  38	 F11D0D04	ADDS SP SP #4
  42	     4770	BX LR

*)

