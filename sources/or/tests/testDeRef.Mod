MODULE testDeRef;
  TYPE prec = POINTER TO rec;
    rec = RECORD
      x, y: INTEGER
    END;
  VAR r: prec;
BEGIN 
  NEW(r);
  r.x := r.y
END testDeRef.

(*
ORTool.DecObj testDeRef.rsc ~

decode testDeRef.rsc
testDeRef D9C6CB1E   1   112
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
   6	 D700840C	BL MT
   7	 80000003	LDR  R0  R0       3
   8	 80000014	LDR  R0  R0      20
   9	 D1008B4C	BLEQ  MT
  10	 81000003	LDR  R1  R0       3
  11	 81100014	LDR  R1  R1      20
  12	 D100924C	BLEQ  MT
  13	 81100004	LDR  R1  R1       4
  14	 A1000000	STR   R1  R0       0
  15	 8FE00000	LDR LNK SP       0
  16	 4EE80004	ADD SP SP      4
  17	 C700000F	B LNK
commands:
entries
     0
pointer refs
    20
fixP =        0
fixD =       10
fixT =        0
entry =        0


OM4Tool.DecObj testDeRef.m4c ~

decode testDeRef.m4c
testDeRef D9C6CB1E   1   102
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
fixD =       32
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 00000001	LDR R0 [ MT + Base(0) ]
   6	     3014	ADDS R0 #20
   8	 10000003	LDR R1 [ MT + Base(0) ]
  12	 EC001040	Trap 0 at pos 132
  16	 00000004	LDR R0 [ MT + Base(0) ]
  20	 F8D00014	LDR R0 [ R0 + 20 ]
  24	     2800	CMP R0 #0
  26	     BF08	IT EQ
  28	 EC0010B4	TrapEQ 4 at pos 139
  32	 10000008	LDR R1 [ MT + Base(0) ]
  36	 F8D11014	LDR R1 [ R1 + 20 ]
  40	     2900	CMP R1 #0
  42	     BF08	IT EQ
  44	 EC001124	TrapEQ 4 at pos 146
  48	 F8D11004	LDR R1 [ R1 + 4 ]
  52	 F8C01000	STR R1 [ R0 + 0 ]
  56	 F85DEB04	LDR LR [ SP ] + 4
  60	     4770	BX LR

*)

