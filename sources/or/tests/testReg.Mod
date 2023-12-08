MODULE testReg;
  IMPORT SYSTEM;
  PROCEDURE p;
    VAR a, v: LONGINT;
  BEGIN
    SYSTEM.LDREG(5, 10);
    SYSTEM.LDREG(1, a);
    v := SYSTEM.REG(5);
  END p;
BEGIN
END testReg.


(*
ORTool.DecObj testReg.rsc ~

decode testReg.rsc
testReg 74DACAC7   1    72
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 4500000A	MOV  R5  R0     10
   3	 80E00004	LDR  R0 SP       4
   4	 01000000	MOV  R1  R0  R0
   5	 00000005	MOV  R0  R0  R5
   6	 A0E00008	STR   R0 SP       8
   7	 8FE00000	LDR LNK SP       0
   8	 4EE8000C	ADD SP SP     12
   9	 C700000F	B LNK
  10	 4EE90004	SUB SP SP      4
  11	 AFE00000	STR  LNK SP       0
  12	 8FE00000	LDR LNK SP       0
  13	 4EE80004	ADD SP SP      4
  14	 C700000F	B LNK
commands:
entries
    40
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       40


OM4Tool.DecObj testReg.m4c ~

decode testReg.m4c
testReg 74DACAC7   1    46
imports:
type descriptors

data     0
strings

code
commands:
entries
    26
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       26
   0	 F1BD0D08	SUBS SP SP #8
   4	     B500	PUSH LR
   6	     250A	MOVS R5 #10
   8	     9801	LDR R0 [SP + 4]
  10	     4601	MOV R1 R0
  12	     4628	MOV R0 R5
  14	     9002	STR R0 [SP + 8]
  16	 F85DEB04	LDR LR [ SP ] + 4
  20	 F11D0D08	ADDS SP SP #8
  24	     4770	BX LR
  26	     B500	PUSH LR
  28	 F85DEB04	LDR LR [ SP ] + 4
  32	     4770	BX LR

*)
