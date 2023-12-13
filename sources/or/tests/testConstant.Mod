MODULE testConstant;
  VAR i: INTEGER;
    r: REAL;
BEGIN
  i := 10;
  r := 3.14
END testConstant.


(*
ORTool.DecObj testConstant.rsc ~

decode testConstant.rsc
testConstant 5C50372B   1    68
imports:
type descriptors

data     8
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 4000000A	MOV  R0  R0     10
   3	 81000003	LDR  R1  R0       3
   4	 A0100000	STR   R0  R1       0
   5	 60004048	MOV'  R0  R0  16456
   6	 4006F5C3	IOR  R0  R0  -2621
   7	 81000004	LDR  R1  R0       4
   8	 A0100004	STR   R0  R1       4
   9	 8FE00000	LDR LNK SP       0
  10	 4EE80004	ADD SP SP      4
  11	 C700000F	B LNK
commands:
entries
     0
pointer refs

fixP =        0
fixD =        7
fixT =        0
entry =        0

OM4Tool.DecObj testConstant.m4c ~

decode testConstant.m4c
testConstant 5C50372B   1    64
imports:
type descriptors

data     8
strings

code
commands:
entries
     0
pointer refs

fixP =        0
fixD =       26
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	     200A	MOVS R0 #10
   4	 10000002	MOV R1 lower 16-bits base(0)
   8	 0000D414	MOVT R1 higher 16-bits var(0)
  12	     6008	STR R0 [ R1 + 0]
  14	 F24F50C3	MOV R0 #62915
  18	 F2C40048	MOVT R0 #16456
  22	 EE000A10	VMOV S0 R0
  26	 0000000B	MOV R0 lower 16-bits base(0)
  30	 0000D414	MOVT R0 higher 16-bits var(4)
  34	 ED800A00	VSTR S0 [ R0 + 0 ]
  38	 F85DEB04	LDR LR [ SP ] + 4
  42	     4770	BX LR

*)
