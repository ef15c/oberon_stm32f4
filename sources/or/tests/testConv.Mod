MODULE testConv;
  PROCEDURE p;
    VAR v: LONGINT;
      r: REAL;
  BEGIN
    r := 3.14159;
    v := FLOOR(r+1.1)+1;
    r := FLT(v+2)+0.5;
  END p;
BEGIN
END testConv.


(*
ORTool.DecObj testConv.rsc ~

decode testConv.rsc
testConv EAE1D5B7   1   124
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 60004049	MOV'  R0  R0  16457
   3	 40060FD0	IOR  R0  R0   4048
   4	 A0E00008	STR   R0 SP       8
   5	 80E00008	LDR  R0 SP       8
   6	 61003F8C	MOV'  R1  R0  16268
   7	 4116CCCD	IOR  R1  R1 -13107
   8	 000C0001	FAD  R0  R0  R1
   9	 61004B00	MOV'  R1  R0  19200
  10	 100C0001	FAD  R0  R0  R1
  11	 40080001	ADD  R0  R0      1
  12	 A0E00004	STR   R0 SP       4
  13	 80E00004	LDR  R0 SP       4
  14	 40080002	ADD  R0  R0      2
  15	 61004B00	MOV'  R1  R0  19200
  16	 200C0001	FAD'  R0  R0  R1
  17	 61003F00	MOV'  R1  R0  16128
  18	 000C0001	FAD  R0  R0  R1
  19	 A0E00008	STR   R0 SP       8
  20	 8FE00000	LDR LNK SP       0
  21	 4EE8000C	ADD SP SP     12
  22	 C700000F	B LNK
  23	 4EE90004	SUB SP SP      4
  24	 AFE00000	STR  LNK SP       0
  25	 8FE00000	LDR LNK SP       0
  26	 4EE80004	ADD SP SP      4
  27	 C700000F	B LNK
commands:
entries
    92
pointer refs

fixP =        0
fixD =        0
fixT =        0


OM4Tool.DecObj testConv.m4c ~

decode testConv.m4c
testConv EAE1D5B7   1   114
imports:
type descriptors

data     0
strings

code
commands:
entries
    94
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       94
   0	 F1BD0D08	SUBS SP SP #8
   4	     B500	PUSH LR
   6	 F64070D0	MOV R0 #4048
  10	 F2C40049	MOVT R0 #16457
  14	 EE000A10	VMOV S0 R0
  18	 ED8D0A02	VSTR S0 [ SP + 8 ]
  22	 ED9D0A02	VLDR S0 [ SP + 8 ]
  26	 F64C40CD	MOV R0 #52429
  30	 F6C3708C	MOVT R0 #16268
  34	 EE000A90	VMOV S1 R0
  38	 EE300A20	VADD S0 S0 S1
  42	 EEBD0A40	VCVTR.S32.F32 S0 S0
  46	 EE100A10	VMOV R0 S0
  50	     1C40	ADDS R0 R0 #1
  52	     9001	STR R0 [SP + 4]
  54	     9801	LDR R0 [SP + 4]
  56	     1C80	ADDS R0 R0 #2
  58	 EE000A10	VMOV S0 R0
  62	 EEB80AC0	VCVT.F32.S32. S0 S0
  66	     2000	MOVS R0 #0
  68	 F6C37000	MOVT R0 #16128
  72	 EE000A90	VMOV S1 R0
  76	 EE300A20	VADD S0 S0 S1
  80	 ED8D0A02	VSTR S0 [ SP + 8 ]
  84	 F85DEB04	LDR LR [ SP ] + 4
  88	 F11D0D08	ADDS SP SP #8
  92	     4770	BX LR
  94	     B500	PUSH LR
  96	 F85DEB04	LDR LR [ SP ] + 4
 100	     4770	BX LR


*)
