MODULE testRealArith;
    
PROCEDURE p;
    VAR a, b, c: REAL;
BEGIN
  a := b + c;
  a := b - c;
  a := b * c;
  a := b / c
END p;

END testRealArith.

(*
ORTool.DecObj testRealArith.rsc ~


decode testRealArith.rsc
testRealArith 553F3D6F   1   116
imports:
type descriptors

data     0
strings

code
   0	 4EE90010	SUB SP SP     16
   1	 AFE00000	STR  LNK SP       0
   2	 80E00008	LDR  R0 SP       8
   3	 81E0000C	LDR  R1 SP      12
   4	 000C0001	FAD  R0  R0  R1
   5	 A0E00004	STR   R0 SP       4
   6	 80E00008	LDR  R0 SP       8
   7	 81E0000C	LDR  R1 SP      12
   8	 000D0001	FSB  R0  R0  R1
   9	 A0E00004	STR   R0 SP       4
  10	 80E00008	LDR  R0 SP       8
  11	 81E0000C	LDR  R1 SP      12
  12	 000E0001	FML  R0  R0  R1
  13	 A0E00004	STR   R0 SP       4
  14	 80E00008	LDR  R0 SP       8
  15	 81E0000C	LDR  R1 SP      12
  16	 000F0001	FDV  R0  R0  R1
  17	 A0E00004	STR   R0 SP       4
  18	 8FE00000	LDR LNK SP       0
  19	 4EE80010	ADD SP SP     16
  20	 C700000F	B LNK
  21	 4EE90004	SUB SP SP      4
  22	 AFE00000	STR  LNK SP       0
  23	 8FE00000	LDR LNK SP       0
  24	 4EE80004	ADD SP SP      4
  25	 C700000F	B LNK
commands:
entries
    84
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       84

OM4Tool.DecObj testRealArith.m4c ~

decode testRealArith.m4c
testRealArith 553F3D6F   1   100
imports:
type descriptors

data     0
strings

code
commands:
entries
    80
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       80
   0	 F1BD0D0C	SUBS SP SP #12
   4	     B500	PUSH LR
   6	 ED9D0A02	VLDR S0 [ SP + 8 ]
  10	 EDDD0A03	VLDR S1 [ SP + 12 ]
  14	 EE300A20	VADD S0 S0 S1
  18	 ED8D0A01	VSTR S0 [ SP + 4 ]
  22	 ED9D0A02	VLDR S0 [ SP + 8 ]
  26	 EDDD0A03	VLDR S1 [ SP + 12 ]
  30	 EE300A60	VSUB S0 S0 S1
  34	 ED8D0A01	VSTR S0 [ SP + 4 ]
  38	 ED9D0A02	VLDR S0 [ SP + 8 ]
  42	 EDDD0A03	VLDR S1 [ SP + 12 ]
  46	 EE200A20	VMUL S0 S0 S1
  50	 ED8D0A01	VSTR S0 [ SP + 4 ]
  54	 ED9D0A02	VLDR S0 [ SP + 8 ]
  58	 EDDD0A03	VLDR S1 [ SP + 12 ]
  62	 EE800A20	VDIV S0 S0 S1
  66	 ED8D0A01	VSTR S0 [ SP + 4 ]
  70	 F85DEB04	LDR LR [ SP ] + 4
  74	 F11D0D0C	ADDS SP SP #12
  78	     4770	BX LR
  80	     B500	PUSH LR
  82	 F85DEB04	LDR LR [ SP ] + 4
  86	     4770	BX LR


*)

