MODULE testFunc;

  VAR i: INTEGER;
    x: REAL;
    
  PROCEDURE SumI(a, b: INTEGER): INTEGER;
  BEGIN
    RETURN a + b
  END SumI;

  PROCEDURE SumR(a, b: REAL): REAL;
  BEGIN
    RETURN a + b
  END SumR;

BEGIN
  i := i + SumI(1, 2);
  x := SumR(1.,2.)
END testFunc.

(*
ORTool.DecObj testFunc.rsc ~

decode testFunc.rsc
testFunc D7E1DBBA   1   172
imports:
type descriptors

data     8
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 A1E00008	STR   R1 SP       8
   4	 80E00004	LDR  R0 SP       4
   5	 81E00008	LDR  R1 SP       8
   6	 00080001	ADD  R0  R0  R1
   7	 8FE00000	LDR LNK SP       0
   8	 4EE8000C	ADD SP SP     12
   9	 C700000F	B LNK
  10	 4EE9000C	SUB SP SP     12
  11	 AFE00000	STR  LNK SP       0
  12	 A0E00004	STR   R0 SP       4
  13	 A1E00008	STR   R1 SP       8
  14	 80E00004	LDR  R0 SP       4
  15	 81E00008	LDR  R1 SP       8
  16	 000C0001	FAD  R0  R0  R1
  17	 8FE00000	LDR LNK SP       0
  18	 4EE8000C	ADD SP SP     12
  19	 C700000F	B LNK
  20	 4EE90004	SUB SP SP      4
  21	 AFE00000	STR  LNK SP       0
  22	 40000001	MOV  R0  R0      1
  23	 41000002	MOV  R1  R0      2
  24	 F7FFFFE7	BL     -25
  25	 81000019	LDR  R1  R0      25
  26	 81100000	LDR  R1  R1       0
  27	 00180000	ADD  R0  R1  R0
  28	 81000003	LDR  R1  R0       3
  29	 A0100000	STR   R0  R1       0
  30	 60003F80	MOV'  R0  R0  16256
  31	 61004000	MOV'  R1  R0  16384
  32	 F7FFFFE9	BL     -23
  33	 81000005	LDR  R1  R0       5
  34	 A0100004	STR   R0  R1       4
  35	 8FE00000	LDR LNK SP       0
  36	 4EE80004	ADD SP SP      4
  37	 C700000F	B LNK
commands:
entries
    80
pointer refs

fixP =        0
fixD =       33
fixT =        0
entry =       80

OM4Tool.DecObj testFunc.m4c ~

decode testFunc.m4c
testFunc D7E1DBBA   1   128
imports:
type descriptors

data     8
strings

code
commands:
entries
    50
pointer refs

fixP =        0
fixD =       94
fixT =        0
entry =       50
   0	     B403	PUSH R0 R1
   2	     B500	PUSH LR
   4	 F8DD0004	LDR R0 [ SP + 4 ]
   8	 F8DD1008	LDR R1 [ SP + 8 ]
  12	     1840	ADDS R0 R0 R1
  14	 F85DEB04	LDR LR [ SP ] + 4
  18	 F11D0D08	ADDS SP SP #8
  22	     4770	BX LR
  24	     B403	PUSH R0 R1
  26	     B500	PUSH LR
  28	 ED9D0A01	VLDR S0 [ SP + 4 ]
  32	 EDDD0A02	VLDR S1 [ SP + 8 ]
  36	 EE300A20	VADD S0 S0 S1
  40	 F85DEB04	LDR LR [ SP ] + 4
  44	 F11D0D08	ADDS SP SP #8
  48	     4770	BX LR
  50	     B500	PUSH LR
  52	     2001	MOVS R0 #1
  54	     2102	MOVS R1 #2
  56	 F7FFFFE2	BL #-60
  60	 1000001E	LDR R1 [ MT + Base(0) ]
  64	 F8D11000	LDR R1 [ R1 + 0 ]
  68	     1808	ADDS R0 R1 R0
  70	 10000005	LDR R1 [ MT + Base(0) ]
  74	 F8C10000	STR R0 [ R1 + 0 ]
  78	     2000	MOVS R0 #0
  80	 F6C37080	MOVT R0 # 16256
  84	     2100	MOVS R1 #0
  86	 F2C40100	MOVT R1 # 16384
  90	 F7FFFFDD	BL #-70
  94	 0000000C	LDR R0 [ MT + Base(0) ]
  98	 ED800A01	VSTR S0 [ R0 + 4 ]
 102	 F85DEB04	LDR LR [ SP ] + 4
 106	     4770	BX LR


*)

