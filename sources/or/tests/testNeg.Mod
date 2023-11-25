MODULE testNeg;
    
PROCEDURE p;
    VAR a: INTEGER;
      b: REAL;
BEGIN a := -a;
  b := -b
END p;

END testNeg.

(*
ORTool.DecObj testNeg.rsc ~

decode testNeg.rsc
testNeg 74DACAC3   1    84
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 80E00004	LDR  R0 SP       4
   3	 41000000	MOV  R1  R0      0
   4	 00190000	SUB  R0  R1  R0
   5	 A0E00004	STR   R0 SP       4
   6	 80E00008	LDR  R0 SP       8
   7	 41000000	MOV  R1  R0      0
   8	 001D0000	FSB  R0  R1  R0
   9	 A0E00008	STR   R0 SP       8
  10	 8FE00000	LDR LNK SP       0
  11	 4EE8000C	ADD SP SP     12
  12	 C700000F	B LNK
  13	 4EE90004	SUB SP SP      4
  14	 AFE00000	STR  LNK SP       0
  15	 8FE00000	LDR LNK SP       0
  16	 4EE80004	ADD SP SP      4
  17	 C700000F	B LNK
commands:
entries
    52
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       52


OM4Tool.DecObj testNeg.m4c ~

decode testNeg.m4c
testNeg 74DACAC3   1    54
imports:
type descriptors

data     0
strings

code
commands:
entries
    34
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       34
entry =       34
   0	 F1BD0D08	SUBS SP SP #8
   4	     B500	PUSH LR
   6	     9801	LDR R0 [SP + 4]
   8	     4240	RSBS R0 R0 #0
  10	     9001	STR R0 [SP + 4]
  12	 ED9D0A02	VLDR S0 [ SP + 8 ]
  16	 EEB10A40	VNEG S0 S0
  20	 ED8D0A02	VSTR S0 [ SP + 8 ]
  24	 F85DEB04	LDR LR [ SP ] + 4
  28	 F11D0D08	ADDS SP SP #8
  32	     4770	BX LR
  34	     B500	PUSH LR
  36	 F85DEB04	LDR LR [ SP ] + 4
  40	     4770	BX LR

*)

