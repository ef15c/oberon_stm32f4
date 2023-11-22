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
testCond D8E1D5B7   1    58
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
fixD =       22
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 00000001	MOV R0 lower 16-bits base(0)
   6	 0000D334	MOVT R0 higher 16-bits var(0)
  10	     6800	LDR R0 [ R0 + 0]
  12	 F1B03FFF	CMP R0 #-1
  16	     BF0C	ITE EQ
  18	     2001	MOVEQ R0 #1
  20	     2000	MOVNE R0 #0
  22	 1000000A	MOV R1 lower 16-bits base(0)
  26	 0000D334	MOVT R1 higher 16-bits var(4)
  30	     7008	STRB R0 [ R1 + 0]
  32	 F85DEB04	LDR LR [ SP ] + 4
  36	     4770	BX LR


*)

