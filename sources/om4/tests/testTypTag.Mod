MODULE testTypTag;
  TYPE tr = RECORD a: INTEGER; END;
    tr1 = RECORD(tr) b: BYTE END;
    tpr = POINTER TO tr;
    tpr1 = POINTER TO tr1;
    
PROCEDURE p(VAR v: tr);
    VAR b: BYTE;
BEGIN b := v(tr1).b
END p;

PROCEDURE p2(v: tpr);
    VAR b: BYTE;
BEGIN b := v(tpr1).b
END p2;

PROCEDURE q;
  VAR r: tr1;
    pr: tpr1;
  
BEGIN p(r); p2(pr);
  r.b := 1
END q;

BEGIN q
END testTypTag.

(*
ORTool.DecObj testTypTag.rsc ~
decode testTypTag.rsc
testTypTag C9E44629   1   256
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000020 00014006 FFFFFFFF FFFFFFFF FFFFFFFF
data     0
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
   9	 D900D42C	BLNE  MT
  10	 80E00004	LDR  R0 SP       4
  11	 90000004	LDR  R0  R0       4
  12	 B0E0000C	STR   R0 SP      12
  13	 8FE00000	LDR LNK SP       0
  14	 4EE80010	ADD SP SP     16
  15	 C700000F	B LNK
  16	 4EE9000C	SUB SP SP     12
  17	 AFE00000	STR  LNK SP       0
  18	 A0E00004	STR   R0 SP       4
  19	 80E00004	LDR  R0 SP       4
  20	 E1000005	BEQ        5
  21	 810FFFF8	LDR  R1  R0      -8
  22	 81100004	LDR  R1  R1       4
  23	 82000011	LDR  R2  R0      17
  24	 42280014	ADD  R2  R2     20
  25	 02290001	SUB  R2  R2  R1
  26	 D9011D2C	BLNE  MT
  27	 90000004	LDR  R0  R0       4
  28	 B0E00008	STR   R0 SP       8
  29	 8FE00000	LDR LNK SP       0
  30	 4EE8000C	ADD SP SP     12
  31	 C700000F	B LNK
  32	 4EE90010	SUB SP SP     16
  33	 AFE00000	STR  LNK SP       0
  34	 40E80004	ADD  R0 SP      4
  35	 8100000C	LDR  R1  R0      12
  36	 41180014	ADD  R1  R1     20
  37	 F7FFFFDA	BL     -38
  38	 80E0000C	LDR  R0 SP      12
  39	 F7FFFFE8	BL     -24
  40	 40000001	MOV  R0  R0      1
  41	 B0E00008	STR   R0 SP       8
  42	 8FE00000	LDR LNK SP       0
  43	 4EE80010	ADD SP SP     16
  44	 C700000F	B LNK
  45	 4EE90004	SUB SP SP      4
  46	 AFE00000	STR  LNK SP       0
  47	 F7FFFFF0	BL     -16
  48	 8FE00000	LDR LNK SP       0
  49	 4EE80004	ADD SP SP      4
  50	 C700000F	B LNK
commands:
entries
   180
pointer refs

fixP =        0
fixD =       35
fixT =        6
entry =      180



OM4Tool.DecObj testTypTag.m4c ~

decode testTypTag.m4c
testTypTag C9E44629   1   204
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000020 00014006 FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
commands:
entries
   140
pointer refs

fixP =        0
fixD =      106
fixT =        6
entry =      140
   0	 F1BD0D04	SUBS SP SP #4
   4	     B403	PUSH R0 R1
   6	     B500	PUSH LR
   8	     9802	LDR R0 [SP + 8]
  10	     6840	LDR R0 [ R0 + 4]
  12	 10000006	MOV R1 lower 16-bits base(0)
  16	 0000D334	MOVT R1 higher 16-bits var(20)
  20	     4281	CMP R1 R0
  22	     BF18	IT NE
  24	 EC001542	TrapNE 2 at pos 212
  28	     9801	LDR R0 [SP + 4]
  30	     7840	LDR R0 [ R0 + 4]
  32	 F88D000C	STRB R0 [ SP + 12 ]
  36	 F85DEB04	LDR LR [ SP ] + 4
  40	 F11D0D0C	ADDS SP SP #12
  44	     4770	BX LR
  46	 F1BD0D04	SUBS SP SP #4
  50	     B401	PUSH R0
  52	     B500	PUSH LR
  54	     9801	LDR R0 [SP + 4]
  56	     D007	BEQ #14, goes to 74
  58	 F8501C08	LDR R1 [ R0- 8 ]
  62	     6849	LDR R1 [ R1 + 4]
  64	 2000001A	MOV R2 lower 16-bits base(0)
  68	 0000D334	MOVT R2 higher 16-bits var(20)
  72	     428A	CMP R2 R1
  74	     BF18	IT NE
  76	 EC0021D2	TrapNE 2 at pos 285
  80	     7840	LDR R0 [ R0 + 4]
  82	 F88D0008	STRB R0 [ SP + 8 ]
  86	 F85DEB04	LDR LR [ SP ] + 4
  90	 F11D0D08	ADDS SP SP #8
  94	     4770	BX LR
  96	 F1BD0D0C	SUBS SP SP #12
 100	     B500	PUSH LR
 102	 F11D0004	ADDS R0 SP #4
 106	 10000015	MOV R1 lower 16-bits base(0)
 110	 0000D334	MOVT R1 higher 16-bits var(20)
 114	 F7FFFFC5	BL #-118, goes to 0
 118	     9803	LDR R0 [SP + 12]
 120	 F7FFFFD9	BL #-78, goes to 46
 124	     2001	MOVS R0 #1
 126	 F88D0008	STRB R0 [ SP + 8 ]
 130	 F85DEB04	LDR LR [ SP ] + 4
 134	 F11D0D0C	ADDS SP SP #12
 138	     4770	BX LR
 140	     B500	PUSH LR
 142	 F7FFFFE7	BL #-50, goes to 96
 146	 F85DEB04	LDR LR [ SP ] + 4
 150	     4770	BX LR

*)

