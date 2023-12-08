MODULE testLGPC;
  IMPORT SYSTEM;
  PROCEDURE p;
    VAR a, v: LONGINT;
  BEGIN
    LED(127);
    SYSTEM.GET(a, v);
    SYSTEM.PUT(a, v);
    SYSTEM.COPY(0, 256, 64);
    SYSTEM.COPY(0, 256, v);
  END p;
BEGIN
END testLGPC.


(*
ORTool.DecObj testLGPC.rsc ~

decode testLGPC.rsc
testLGPC B7C3ADC0   1   168
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
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
  11	 40000000	MOV  R0  R0      0
  12	 41000100	MOV  R1  R0    256
  13	 42000040	MOV  R2  R0     64
  14	 83000000	LDR  R3  R0       0
  15	 40080004	ADD  R0  R0      4
  16	 A3100000	STR   R3  R1       0
  17	 41180004	ADD  R1  R1      4
  18	 42290001	SUB  R2  R2      1
  19	 E9FFFFFA	BNE       -6
  20	 40000000	MOV  R0  R0      0
  21	 41000100	MOV  R1  R0    256
  22	 82E00008	LDR  R2 SP       8
  23	 D500CB3C	BLLT  MT
  24	 E1000006	BEQ        6
  25	 83000000	LDR  R3  R0       0
  26	 40080004	ADD  R0  R0      4
  27	 A3100000	STR   R3  R1       0
  28	 41180004	ADD  R1  R1      4
  29	 42290001	SUB  R2  R2      1
  30	 E9FFFFFA	BNE       -6
  31	 8FE00000	LDR LNK SP       0
  32	 4EE8000C	ADD SP SP     12
  33	 C700000F	B LNK
  34	 4EE90004	SUB SP SP      4
  35	 AFE00000	STR  LNK SP       0
  36	 8FE00000	LDR LNK SP       0
  37	 4EE80004	ADD SP SP      4
  38	 C700000F	B LNK
commands:
entries
   136
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =      136


OM4Tool.DecObj testLGPC.m4c ~

decode testLGPC.m4c
testLGPC B7C3ADC0   1   102
imports:
type descriptors

data     0
strings

code
commands:
entries
    82
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       82
   0	 F1BD0D08	SUBS SP SP #8
   4	     B500	PUSH LR
   6	     207F	MOVS R0 #127
   8	     DF01	SVC #1
  10	     9801	LDR R0 [SP + 4]
  12	     6800	LDR R0 [ R0 + 0]
  14	     9002	STR R0 [SP + 8]
  16	     9801	LDR R0 [SP + 4]
  18	     9902	LDR R1 [SP + 8]
  20	     6001	STR R1 [ R0 + 0]
  22	     2000	MOVS R0 #0
  24	 F2401100	MOV R1 #256
  28	     2240	MOVS R2 #64
  30	 F8503B04	LDR R3 [ R0 ] + 4
  34	 F8413B04	STR R3 [ R1 ] + 4
  38	     1E52	SUBS R2 R2 #1
  40	     D1F9	BNE #-14, goes to 30
  42	     2000	MOVS R0 #0
  44	 F2401100	MOV R1 #256
  48	     9A02	LDR R2 [SP + 8]
  50	     2A00	CMP R2 #0
  52	     BFB8	IT LT
  54	 EC0014B3	TrapLT 3 at pos 203
  58	     D005	BEQ #10, goes to 72
  60	 F8503B04	LDR R3 [ R0 ] + 4
  64	 F8413B04	STR R3 [ R1 ] + 4
  68	     1E52	SUBS R2 R2 #1
  70	     D1F9	BNE #-14, goes to 60
  72	 F85DEB04	LDR LR [ SP ] + 4
  76	 F11D0D08	ADDS SP SP #8
  80	     4770	BX LR
  82	     B500	PUSH LR
  84	 F85DEB04	LDR LR [ SP ] + 4
  88	     4770	BX LR

*)
