MODULE testIfThen;
  VAR i: INTEGER;
BEGIN
  IF i = 0 THEN i := 1 ELSE i := 0 END
END testIfThen.

(*
ORTool.DecObj testIfThen.rsc ~
decode testIfThen.rsc
testIfThen DDC83A22   1    76
imports:
type descriptors

data     4
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80000002	LDR  R0  R0       2
   3	 80000000	LDR  R0  R0       0
   4	 E9000004	BNE        4
   5	 40000001	MOV  R0  R0      1
   6	 81000004	LDR  R1  R0       4
   7	 A0100000	STR   R0  R1       0
   8	 E7000003	B       3
   9	 40000000	MOV  R0  R0      0
  10	 81000004	LDR  R1  R0       4
  11	 A0100000	STR   R0  R1       0
  12	 8FE00000	LDR LNK SP       0
  13	 4EE80004	ADD SP SP      4
  14	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =       10
fixT =        0
entry =        0



OM4Tool.DecObj testIfThen.m4c ~
decode testIfThen.m4c
testIfThen DDC83A22   1    64
imports:
type descriptors

data     4
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =       34
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 00000001	LDR R0 [ MT + Base(0) ]
   6	 F8D00000	LDR R0 [ R0 + 0 ]
  10	     2800	CMP R0 #0
  12	     BF18	IT NE
  14	 F000B807	BNE #14
  18	     2001	MOVS R0 #1
  20	 10000009	LDR R1 [ MT + Base(0) ]
  24	 F8C10000	STR R0 [ R1 + 0 ]
  28	 F000B805	B #10
  32	     2000	MOVS R0 #0
  34	 10000007	LDR R1 [ MT + Base(0) ]
  38	 F8C10000	STR R0 [ R1 + 0 ]
  42	 F85DEB04	LDR LR [ SP ] + 4
  46	     4770	BX LR

*)

