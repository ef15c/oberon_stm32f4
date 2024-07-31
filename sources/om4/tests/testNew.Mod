MODULE testNew;
  TYPE pr = POINTER TO r;
    r = RECORD
      a: INTEGER;
    END;

  VAR x: pr;
BEGIN
  NEW(x);
  x.a := 1
END testNew.


(*
ORTool.DecObj testNew.rsc ~

decode testNew.rsc
testNew 74EACAC3   1   100
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     4
strings

code
   0	 4EE90004	SUB SP SP      4
   1	 AFE00000	STR  LNK SP       0
   2	 80000002	LDR  R0  R0       2
   3	 40080014	ADD  R0  R0     20
   4	 81000002	LDR  R1  R0       2
   5	 41180000	ADD  R1  R1      0
   6	 D700790C	BL MT
   7	 80000003	LDR  R0  R0       3
   8	 80000014	LDR  R0  R0      20
   9	 D100804C	BLEQ  MT
  10	 41000001	MOV  R1  R0      1
  11	 A1000000	STR   R1  R0       0
  12	 8FE00000	LDR LNK SP       0
  13	 4EE80004	ADD SP SP      4
  14	 C700000F	B LNK
commands:
entries
     0
pointer refs
    20
fixP =        0
fixD =        7
fixT =        0
entry =        0


OM4Tool.DecObj testNew.m4c ~

decode testNew.m4c
testNew 74EACAC3   1    90
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     4
strings

code
commands:
entries
     0
pointer refs
    20
fixP =        0
fixD =       22
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 00000001	MOV R0 lower 16-bits base(0)
   6	 0000D414	MOVT R0 higher 16-bits var(20)
  10	 10000004	MOV R1 lower 16-bits base(0)
  14	 0000D414	MOVT R1 higher 16-bits var(0)
  18	 EC000790	Trap 0 at pos 121
  22	 00000006	MOV R0 lower 16-bits base(0)
  26	 0000D414	MOVT R0 higher 16-bits var(20)
  30	     6800	LDR R0 [ R0 + 0]
  32	     2800	CMP R0 #0
  34	     BF08	IT EQ
  36	 EC001004	TrapEQ 4 at pos 128
  40	     2101	MOVS R1 #1
  42	     6001	STR R1 [ R0 + 0]
  44	 F85DEB04	LDR LR [ SP ] + 4
  48	     4770	BX LR


*)
