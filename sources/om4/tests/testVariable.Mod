MODULE testVariable;
  PROCEDURE p;
    VAR i: INTEGER;
      r: REAL;
  BEGIN
    i := i+10;
    r := r+3.14
  END p;
END testVariable.


(*
ORTool.DecObj testVariable.rsc ~

decode testVariable.rsc
testVariable 43522A2B   1    84
imports:
type descriptors

data     0
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 80E00004	LDR  R0 SP       4
   3	 4008000A	ADD  R0  R0     10
   4	 A0E00004	STR   R0 SP       4
   5	 80E00008	LDR  R0 SP       8
   6	 61004048	MOV'  R1  R0  16456
   7	 4116F5C3	IOR  R1  R1  -2621
   8	 000C0001	FAD  R0  R0  R1
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


OM4Tool.DecObj testVariable.m4c ~

decode testVariable.m4c
testVariable 43522A2B   1    82
imports:
type descriptors

data     0
strings

code
commands:
entries
    52
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       52
   0	 F1BD0D0C	SUBS SP SP # 0CH
   4	 F8CDE000	STR LR [ SP + 0H]
   8	 F8DD0004	LDR  R0 [ SP + 4H]
  12	     300A	ADDS  R0 # 10
  14	 F8CD0004	STR  R0 [ SP + 4H]
  18	 ED9D0A02	VLDR S0 [ SP + 8H]
  22	 F24F50C3	MOV  R0 # 62915
  26	 F2C40048	MOVT  R0 # 16456
  30	 EE000A90	VMOV S1   R0
  34	 EE300A20	VADD S0 S0 S1
  38	 ED8D0A02	VSTR S0 [ SP + 8H]
  42	 F8DDE000	LDR LR [ SP + 0H]
  46	 F11D0D0C	ADDS SP SP # 0CH
  50	     4770	BX LR
  52	 F1BD0D04	SUBS SP SP # 4H
  56	 F8CDE000	STR LR [ SP + 0H]
  60	 F8DDE000	LDR LR [ SP + 0H]
  64	 F11D0D04	ADDS SP SP # 4H
  68	     4770	BX LR


*)
