MODULE testSFuncs3;
  IMPORT SYSTEM;
  TYPE rt = RECORD
      a, b, c: INTEGER
    END;
    at = ARRAY 3 OF INTEGER;
  PROCEDURE p;
    VAR v: LONGINT;
      p: BYTE;
      b: BOOLEAN;
      r: rt;
      a: at;
  BEGIN
    b := SYSTEM.BIT(v, 12);
    b := SYSTEM.BIT(v+1, p);
    v := SYSTEM.ADR(r);
    v := SYSTEM.ADR(a);
    b := SYSTEM.COND(1)
  END p;
BEGIN
END testSFuncs3.


(*
ORTool.DecObj testSFuncs3.rsc ~

decode testSFuncs3.rsc
testSFuncs3 E31C1F2B   1   184
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
   0	 4EE90024	SUB SP SP     36
   1	 AFE00000	STR  LNK SP       0
   2	 80E00004	LDR  R0 SP       4
   3	 80000000	LDR  R0  R0       0
   4	 4003000D	ROR  R0  R0     13
   5	 E8000002	BPL       2
   6	 40000001	MOV  R0  R0      1
   7	 E7000001	B       1
   8	 40000000	MOV  R0  R0      0
   9	 B0E00009	STR   R0 SP       9
  10	 80E00004	LDR  R0 SP       4
  11	 40080001	ADD  R0  R0      1
  12	 80000000	LDR  R0  R0       0
  13	 91E00008	LDR  R1 SP       8
  14	 41180001	ADD  R1  R1      1
  15	 00030001	ROR  R0  R0  R1
  16	 E8000002	BPL       2
  17	 40000001	MOV  R0  R0      1
  18	 E7000001	B       1
  19	 40000000	MOV  R0  R0      0
  20	 B0E00009	STR   R0 SP       9
  21	 40E8000C	ADD  R0 SP     12
  22	 A0E00004	STR   R0 SP       4
  23	 40E80018	ADD  R0 SP     24
  24	 A0E00004	STR   R0 SP       4
  25	 E9000002	BNE        2
  26	 40000001	MOV  R0  R0      1
  27	 E7000001	B       1
  28	 40000000	MOV  R0  R0      0
  29	 B0E00009	STR   R0 SP       9
  30	 8FE00000	LDR LNK SP       0
  31	 4EE80024	ADD SP SP     36
  32	 C700000F	B LNK
  33	 4EE90004	SUB SP SP      4
  34	 AFE00000	STR  LNK SP       0
  35	 8FE00000	LDR LNK SP       0
  36	 4EE80004	ADD SP SP      4
  37	 C700000F	B LNK
commands:
entries
   132
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      132


OM4Tool.DecObj testSFuncs3.m4c ~

decode testSFuncs3.m4c
testSFuncs3 E31C1F2B   1   120
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
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
   0	 F1BD0D20	SUBS SP SP #32
   4	     B500	PUSH LR
   6	     9801	LDR R0 [SP + 4]
   8	     6800	LDR R0 [ R0 + 0]
  10	 EA5F3070	RORS R0 R0 #13
  14	     BF4C	ITE MI
  16	     2001	MOVMI R0 #1
  18	     2000	MOVPL R0 #0
  20	 F88D0009	STRB R0 [ SP + 9 ]
  24	     9801	LDR R0 [SP + 4]
  26	     1C40	ADDS R0 R0 #1
  28	     6800	LDR R0 [ R0 + 0]
  30	 F89D1008	LDRB R1 [ SP + 8 ]
  34	     1C49	ADDS R1 R1 #1
  36	     41C8	RORS R0 R1
  38	     BF4C	ITE MI
  40	     2001	MOVMI R0 #1
  42	     2000	MOVPL R0 #0
  44	 F88D0009	STRB R0 [ SP + 9 ]
  48	 F11D000C	ADDS R0 SP #12
  52	     9001	STR R0 [SP + 4]
  54	 F11D0018	ADDS R0 SP #24
  58	     9001	STR R0 [SP + 4]
  60	     BF14	ITE NE
  62	     2001	MOVNE R0 #1
  64	     2000	MOVEQ R0 #0
  66	 F88D0009	STRB R0 [ SP + 9 ]
  70	 F85DEB04	LDR LR [ SP ] + 4
  74	 F11D0D20	ADDS SP SP #32
  78	     4770	BX LR
  80	     B500	PUSH LR
  82	 F85DEB04	LDR LR [ SP ] + 4
  86	     4770	BX LR


*)
