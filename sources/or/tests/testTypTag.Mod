MODULE testTypTag;
  TYPE tr = RECORD a: INTEGER; END;
    tr1 = RECORD(tr) b: BYTE END;

  VAR r: tr1;
    
PROCEDURE p(VAR v: tr);
  VAR b: BYTE;
BEGIN b := v(tr1).b
END p;

BEGIN r.b := 0; p(r)
END testTypTag.

(*
ORTool.DecObj testTypTag.rsc ~
decode testTypTag.rsc
testTypTag C9E44629   1   176
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000020 00014006 FFFFFFFF FFFFFFFF FFFFFFFF
data     8
strings

code
   0	 4EE90010	SUB SP SP     16
   1	 AFE00000	STR  LNK SP       0
   2	 A0E00004	STR   R0 SP       4
   3	 A1E00008	STR   R1 SP       8
   4	 80E00008	LDR  R0 SP       8
   5	 80000004	LDR  R0  R0       4
   6	 81000006	LDR  R1  R0       6
   7	 41180014	ADD  R1  R1     20
   8	 01190000	SUB  R1  R1  R0
   9	 D900AD2C	BLNE  MT
  10	 80E00004	LDR  R0 SP       4
  11	 90000004	LDR  R0  R0       4
  12	 B0E0000C	STR   R0 SP      12
  13	 8FE00000	LDR LNK SP       0
  14	 4EE80010	ADD SP SP     16
  15	 C700000F	B LNK
  16	 4EE90004	SUB SP SP      4
  17	 AFE00000	STR  LNK SP       0
  18	 40000000	MOV  R0  R0      0
  19	 8100000D	LDR  R1  R0      13
  20	 B010002C	STR   R0  R1      44
  21	 80000002	LDR  R0  R0       2
  22	 40080028	ADD  R0  R0     40
  23	 81000002	LDR  R1  R0       2
  24	 41180014	ADD  R1  R1     20
  25	 F7FFFFE6	BL     -26
  26	 8FE00000	LDR LNK SP       0
  27	 4EE80004	ADD SP SP      4
  28	 C700000F	B LNK
commands:
entries
    64
pointer refs

fixP =        0
fixD =       23
entry =       64
fixT =        6


OM4Tool.DecObj testTypTag.m4c ~
OM4Tool 12.11.2023
decode testTypTag.m4c
testTypTag C9E44629   1   146
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000020 00014006 FFFFFFFF FFFFFFFF FFFFFFFF
data     8
strings

code
commands:
entries
    46
pointer refs

fixP =        0
fixD =       68
fixT =        6
entry =       46
   0	 F1BD0D04	SUBS SP SP #4
   4	     B403	PUSH R0 R1
   6	     B500	PUSH LR
   8	     9802	LDR R0 [SP + 8]
  10	     6840	LDR R0 [ R0 + 4]
  12	 10000006	MOV R1 lower 16-bits base(0)
  16	 0000D334	MOVT R1 higher 16-bits var(20)
  20	     4281	CMP R1 R0
  22	     BF18	IT NE
  24	 EC0012D2	TrapNE 2 at pos 173
  28	     9801	LDR R0 [SP + 4]
  30	     7840	LDR R0 [ R0 + 4]
  32	 F88D000C	STRB R0 [ SP + 12 ]
  36	 F85DEB04	LDR LR [ SP ] + 4
  40	 F11D0D0C	ADDS SP SP #12
  44	     4770	BX LR
  46	     B500	PUSH LR
  48	     2000	MOVS R0 #0
  50	 10000013	MOV R1 lower 16-bits base(0)
  54	 0000D334	MOVT R1 higher 16-bits var(44)
  58	     7008	STRB R0 [ R1 + 0]
  60	 00000005	MOV R0 lower 16-bits base(0)
  64	 0000D334	MOVT R0 higher 16-bits var(40)
  68	 10000004	MOV R1 lower 16-bits base(0)
  72	 0000D334	MOVT R1 higher 16-bits var(20)
  76	 F7FFFFD8	BL #-80
  80	 F85DEB04	LDR LR [ SP ] + 4
  84	     4770	BX LR


*)

