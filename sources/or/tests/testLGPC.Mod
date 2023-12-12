MODULE testLGPC;
  IMPORT SYSTEM;
  PROCEDURE p;
    VAR a, v: LONGINT;
      b: BYTE;
  BEGIN
    LED(127);
    SYSTEM.GET(a, v);
    SYSTEM.PUT(a, v);
    SYSTEM.GET(a, b);
    SYSTEM.PUT(a, b);
    SYSTEM.COPY(0, 256, 64);
    SYSTEM.COPY(0, 256, v);
  END p;
BEGIN
END testLGPC.


(*
ORTool.DecObj testLGPC.rsc ~

decode testLGPC.rsc
testLGPC B7C3ADC0   1   192
imports:
type descriptors

data     0
strings

code
   0	 4EE90010	SUB SP SP     16
   1	 AFE00000	STR  LNK SP       0
   2	 4000007F	MOV  R0  R0    127
   3	 5100FFC4	MOV  R1  R0    -60
   4	 A0100000	STR   R0  R1       0
   5	 80E00004	LDR  R0 SP       4
   6	 80000000	LDR  R0  R0       0
   7	 A0E00008	STR   R0 SP       8
   8	 80E00004	LDR  R0 SP       4
   9	 81E00008	LDR  R1 SP       8
  10	 A1000000	STR   R1  R0       0
  11	 80E00004	LDR  R0 SP       4
  12	 90000000	LDR  R0  R0       0
  13	 B0E0000C	STR   R0 SP      12
  14	 80E00004	LDR  R0 SP       4
  15	 91E0000C	LDR  R1 SP      12
  16	 B1000000	STR   R1  R0       0
  17	 40000000	MOV  R0  R0      0
  18	 41000100	MOV  R1  R0    256
  19	 42000040	MOV  R2  R0     64
  20	 83000000	LDR  R3  R0       0
  21	 40080004	ADD  R0  R0      4
  22	 A3100000	STR   R3  R1       0
  23	 41180004	ADD  R1  R1      4
  24	 42290001	SUB  R2  R2      1
  25	 E9FFFFFA	BNE       -6
  26	 40000000	MOV  R0  R0      0
  27	 41000100	MOV  R1  R0    256
  28	 82E00008	LDR  R2 SP       8
  29	 D501093C	BLLT  MT
  30	 E1000006	BEQ        6
  31	 83000000	LDR  R3  R0       0
  32	 40080004	ADD  R0  R0      4
  33	 A3100000	STR   R3  R1       0
  34	 41180004	ADD  R1  R1      4
  35	 42290001	SUB  R2  R2      1
  36	 E9FFFFFA	BNE       -6
  37	 8FE00000	LDR LNK SP       0
  38	 4EE80010	ADD SP SP     16
  39	 C700000F	B LNK
  40	 4EE90004	SUB SP SP      4
  41	 AFE00000	STR  LNK SP       0
  42	 8FE00000	LDR LNK SP       0
  43	 4EE80004	ADD SP SP      4
  44	 C700000F	B LNK
commands:
entries
   160
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      160


OM4Tool.DecObj testLGPC.m4c ~

decode testLGPC.m4c
testLGPC B7C3ADC0   1   118
imports:
type descriptors

data     0
strings

code
commands:
entries
    98
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       98
   0	 F1BD0D0C	SUBS SP SP #12
   4	     B500	PUSH LR
   6	     207F	MOVS R0 #127
   8	     DF01	SVC #1
  10	     9801	LDR R0 [SP + 4]
  12	     6800	LDR R0 [ R0 + 0]
  14	     9002	STR R0 [SP + 8]
  16	     9801	LDR R0 [SP + 4]
  18	     9902	LDR R1 [SP + 8]
  20	     6001	STR R1 [ R0 + 0]
  22	     9801	LDR R0 [SP + 4]
  24	     7800	LDRB R0 [ R0 + 0]
  26	 F88D000C	STRB R0 [ SP + 12 ]
  30	     9801	LDR R0 [SP + 4]
  32	 F89D100C	LDRB R1 [ SP + 12 ]
  36	     7001	STRB R1 [ R0 + 0]
  38	     2000	MOVS R0 #0
  40	 F2401100	MOV R1 #256
  44	     2240	MOVS R2 #64
  46	 F8503B04	LDR R3 [ R0 ] + 4
  50	 F8413B04	STR R3 [ R1 ] + 4
  54	     1E52	SUBS R2 R2 #1
  56	     D1F9	BNE #-14, goes to 46
  58	     2000	MOVS R0 #0
  60	 F2401100	MOV R1 #256
  64	     9A02	LDR R2 [SP + 8]
  66	     2A00	CMP R2 #0
  68	     BFB8	IT LT
  70	 EC002093	TrapLT 3 at pos 265
  74	     D005	BEQ #10, goes to 88
  76	 F8503B04	LDR R3 [ R0 ] + 4
  80	 F8413B04	STR R3 [ R1 ] + 4
  84	     1E52	SUBS R2 R2 #1
  86	     D1F9	BNE #-14, goes to 76
  88	 F85DEB04	LDR LR [ SP ] + 4
  92	 F11D0D0C	ADDS SP SP #12
  96	     4770	BX LR
  98	     B500	PUSH LR
 100	 F85DEB04	LDR LR [ SP ] + 4
 104	     4770	BX LR

*)
