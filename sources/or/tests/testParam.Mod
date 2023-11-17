MODULE testParam;
  PROCEDURE p(i: INTEGER; r: REAL);
  BEGIN
    i := i+10;
    r := r+3.14
  END p;
END testParam.


(*
ORTool.DecObj testParam.rsc ~
decode testParam.rsc
testParam D5E6C731   1    92
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 A1E00008	STR   R1 SP       8
   4	 80E00004	LDR  R0 SP       4
   5	 4008000A	ADD  R0  R0     10
   6	 A0E00004	STR   R0 SP       4
   7	 80E00008	LDR  R0 SP       8
   8	 61004048	MOV'  R1  R0  16456
   9	 4116F5C3	IOR  R1  R1  -2621
  10	 000C0001	FAD  R0  R0  R1
  11	 A0E00008	STR   R0 SP       8
  12	 8FE00000	LDR LNK SP       0
  13	 4EE8000C	ADD SP SP     12
  14	 C700000F	B LNK
  15	 4EE90004	SUB SP SP      4
  16	 AFE00000	STR  LNK SP       0
  17	 8FE00000	LDR LNK SP       0
  18	 4EE80004	ADD SP SP      4
  19	 C700000F	B LNK
commands:
entries
    60
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       60



OM4Tool.DecObj testParam.m4c ~
decode testParam.m4c
testParam D5E6C731   1    84
imports:
type descriptors

data     0
strings

code
commands:
entries
    54
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       54
   0	 F1BD0D04	SUBS SP SP # 4H
   4	 F8CDE000	STR LR [ SP + 0H]
   8	     0B403	PUSH  R0  R1
  10	 F8DD0004	LDR  R0 [ SP + 4H]
  14	     300A	ADDS  R0 # 10
  16	 F8CD0004	STR  R0 [ SP + 4H]
  20	 ED9D0A02	VLDR S0 [ SP + 8H]
  24	 F24F50C3	MOV  R0 # 62915
  28	 F2C40048	MOVT  R0 # 16456
  32	 EE000A90	VMOV S1   R0
  36	 EE300A20	VADD S0 S0 S1
  40	 ED8D0A02	VSTR S0 [ SP + 8H]
  44	 F8DDE000	LDR LR [ SP + 0H]
  48	 F11D0D0C	ADDS SP SP # 0CH
  52	     4770	BX LR
  54	 F1BD0D04	SUBS SP SP # 4H
  58	 F8CDE000	STR LR [ SP + 0H]
  62	 F8DDE000	LDR LR [ SP + 0H]
  66	 F11D0D04	ADDS SP SP # 4H
  70	     4770	BX LR
 

*)
