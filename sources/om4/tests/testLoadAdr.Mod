MODULE testLoadAdr;
  TYPE rec = RECORD
    x, y: INTEGER;
	END;

  VAR r1: rec;

  PROCEDURE p(VAR r: rec);
  BEGIN
    r.x := 1; r.y := 2
  END p;
BEGIN
  p(r1)
END testLoadAdr.

(*
ORTool.DecObj testLoadAdr.rsc ~

decode testLoadAdr.rsc
testLoadAdr D9473902   1   132
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     8
strings

code
   0	 4EE9000C	SUB SP SP     12
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 A1E00008	STR   R1 SP       8
   4	 40000001	MOV  R0  R0      1
   5	 81E00004	LDR  R1 SP       4
   6	 A0100000	STR   R0  R1       0
   7	 40000002	MOV  R0  R0      2
   8	 81E00004	LDR  R1 SP       4
   9	 A0100004	STR   R0  R1       4
  10	 8FE00000	LDR LNK SP       0
  11	 4EE8000C	ADD SP SP     12
  12	 C700000F	B LNK
  13	 4EE90004	SUB SP SP      4
  14	 AFE00000	STR  LNK SP       0
  15	 8000000F	LDR  R0  R0      15
  16	 40080014	ADD  R0  R0     20
  17	 81000002	LDR  R1  R0       2
  18	 41180000	ADD  R1  R1      0
  19	 F7FFFFEC	BL     -20
  20	 8FE00000	LDR LNK SP       0
  21	 4EE80004	ADD SP SP      4
  22	 C700000F	B LNK
commands:
entries
    52
pointer refs

fixP =        0
fixD =       17
fixT =        0
entry =       52


OM4Tool.DecObj testLoadAdr.m4c ~

decode testLoadAdr.m4c
testLoadAdr D9473902   1   106
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     8
strings

code
commands:
entries
    34
pointer refs

fixP =        0
fixD =       48
fixT =        0
entry =       34
   0	     B403	PUSH R0 R1
   2	     B500	PUSH LR
   4	     2001	MOVS R0 #1
   6	 F8DD1004	LDR R1 [ SP + 4 ]
  10	 F8C10000	STR R0 [ R1 + 0 ]
  14	     2002	MOVS R0 #2
  16	 F8DD1004	LDR R1 [ SP + 4 ]
  20	 F8C10004	STR R0 [ R1 + 4 ]
  24	 F8DDE000	LDR LR [ SP + 0 ]
  28	 F11D0D0C	ADDS SP SP #12
  32	     4770	BX LR
  34	 F1BD0D04	SUBS SP SP #4
  38	 F8CDE000	STR LR [ SP + 0 ]
  42	 00000015	LDR R0 [ MT + Base(0) ]
  46	     3014	ADDS R0 #20
  48	 10000003	LDR R1 [ MT + Base(0) ]
  52	 F7FFFFE4	BL #       -56
  56	 F8DDE000	LDR LR [ SP + 0 ]
  60	 F11D0D04	ADDS SP SP #4
  64	     4770	BX LR

*)

