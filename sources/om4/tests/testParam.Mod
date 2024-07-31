MODULE testParam;

  TYPE ti = ARRAY 10 OF INTEGER;

  PROCEDURE p(i: INTEGER; r: REAL; VAR s: ARRAY OF INTEGER);
  BEGIN
    i := i+10;
    r := r+3.14
  END p;
  
  PROCEDURE q(VAR t: ti; VAR u: ARRAY OF INTEGER);
  BEGIN
    p(1, 1.0, t);
    p(1, 1.0, u);
  END q;

END testParam.


(*
ORTool.DecObj testParam.rsc ~
decode testParam.rsc
testParam D5E6C731   1   172
imports:
type descriptors

data     0
strings

code
   0	 4EE90014	SUB SP SP     20
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 A1E00008	STR   R1 SP       8
   4	 A2E0000C	STR   R2 SP      12
   5	 A3E00010	STR   R3 SP      16
   6	 80E00004	LDR  R0 SP       4
   7	 4008000A	ADD  R0  R0     10
   8	 A0E00004	STR   R0 SP       4
   9	 80E00008	LDR  R0 SP       8
  10	 61004048	MOV'  R1  R0  16456
  11	 4116F5C3	IOR  R1  R1  -2621
  12	 000C0001	FAD  R0  R0  R1
  13	 A0E00008	STR   R0 SP       8
  14	 8FE00000	LDR LNK SP       0
  15	 4EE80014	ADD SP SP     20
  16	 C700000F	B LNK
  17	 4EE90010	SUB SP SP     16
  18	 AFE00000	STR  LNK SP       0
  19	 A0E00004	STR   R0 SP       4
  20	 A1E00008	STR   R1 SP       8
  21	 A2E0000C	STR   R2 SP      12
  22	 40000001	MOV  R0  R0      1
  23	 61003F80	MOV'  R1  R0  16256
  24	 82E00004	LDR  R2 SP       4
  25	 4300000A	MOV  R3  R0     10
  26	 F7FFFFE5	BL     -27
  27	 40000001	MOV  R0  R0      1
  28	 61003F80	MOV'  R1  R0  16256
  29	 82E00008	LDR  R2 SP       8
  30	 83E0000C	LDR  R3 SP      12
  31	 F7FFFFE0	BL     -32
  32	 8FE00000	LDR LNK SP       0
  33	 4EE80010	ADD SP SP     16
  34	 C700000F	B LNK
  35	 4EE90004	SUB SP SP      4
  36	 AFE00000	STR  LNK SP       0
  37	 8FE00000	LDR LNK SP       0
  38	 4EE80004	ADD SP SP      4
  39	 C700000F	B LNK
commands:
entries
   140
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      140



OM4Tool.DecObj testParam.m4c ~

decode testParam.m4c
testParam D5E6C731   1   110
imports:
type descriptors

data     0
strings

code
commands:
entries
    90
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       90
   0	     B40F	PUSH R0 R1 R2 R3
   2	     B500	PUSH LR
   4	     9801	LDR R0 [SP + 4]
   6	     300A	ADDS R0 #10
   8	     9001	STR R0 [SP + 4]
  10	 ED9D0A02	VLDR S0 [ SP + 8 ]
  14	 F24F50C3	MOV R0 # 62915
  18	 F2C40048	MOVT R0 # 16456
  22	 EE000A90	VMOV S1 R0
  26	 EE300A20	VADD S0 S0 S1
  30	 ED8D0A02	VSTR S0 [ SP + 8 ]
  34	 F85DEB04	LDR LR [ SP ] + 4
  38	 F11D0D10	ADDS SP SP #16
  42	     4770	BX LR
  44	     B407	PUSH R0 R1 R2
  46	     B500	PUSH LR
  48	     2001	MOVS R0 #1
  50	     2100	MOVS R1 #0
  52	 F6C37180	MOVT R1 # 16256
  56	     9A01	LDR R2 [SP + 4]
  58	     230A	MOVS R3 #10
  60	 F7FFFFE0	BL #-64, goes to 0
  64	     2001	MOVS R0 #1
  66	     2100	MOVS R1 #0
  68	 F6C37180	MOVT R1 # 16256
  72	     9A02	LDR R2 [SP + 8]
  74	     9B03	LDR R3 [SP + 12]
  76	 F7FFFFD8	BL #-80, goes to 0
  80	 F85DEB04	LDR LR [ SP ] + 4
  84	 F11D0D0C	ADDS SP SP #12
  88	     4770	BX LR
  90	     B500	PUSH LR
  92	 F85DEB04	LDR LR [ SP ] + 4
  96	     4770	BX LR


*)
