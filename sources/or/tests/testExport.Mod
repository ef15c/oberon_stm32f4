MODULE testExport;
  TYPE rec* = RECORD
    x*, y*: INTEGER;
  END;

  VAR l*: LONGINT;
    p1*: PROCEDURE;
    r*: REAL;
    v*: rec;
    w: INTEGER;
  
  PROCEDURE p*;
    VAR z: rec;
      a: INTEGER;
  BEGIN
    a := z.y; z.x := a
  END p;

BEGIN p; p1 := p; p1;
  w := v.x; v.y := w
END testExport.

(*
ORTool.DecObj testExport.rsc ~


decode testExport.rsc
testExport 215E94C7   1   208
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data    24
strings

code
   0	 4EE90010	SUB SP SP     16
   1	 AFE00000	STR  LNK SP       0
   2	 80E00008	LDR  R0 SP       8
   3	 A0E0000C	STR   R0 SP      12
   4	 80E0000C	LDR  R0 SP      12
   5	 A0E00004	STR   R0 SP       4
   6	 8FE00000	LDR LNK SP       0
   7	 4EE80010	ADD SP SP     16
   8	 C700000F	B LNK
   9	 4EE90004	SUB SP SP      4
  10	 AFE00000	STR  LNK SP       0
  11	 F7FFFFF4	BL     -12
  12	 F7000000	BL       0
  13	 40F90034	SUB  R0 LNK     52
  14	 8100000E	LDR  R1  R0      14
  15	 A0100018	STR   R0  R1      24
  16	 80000002	LDR  R0  R0       2
  17	 80000018	LDR  R0  R0      24
  18	 D101195C	BLEQ  MT
  19	 D7000000	BL  R0
  20	 80000004	LDR  R0  R0       4
  21	 80000020	LDR  R0  R0      32
  22	 81000002	LDR  R1  R0       2
  23	 A0100028	STR   R0  R1      40
  24	 80000002	LDR  R0  R0       2
  25	 80000028	LDR  R0  R0      40
  26	 81000002	LDR  R1  R0       2
  27	 A0100024	STR   R0  R1      36
  28	 8FE00000	LDR LNK SP       0
  29	 4EE80004	ADD SP SP      4
  30	 C700000F	B LNK
commands:
	p    0
entries
    36    20    24    28    32     0
pointer refs

fixP =        0
fixD =       26
fixT =        0


OM4Tool.DecObj testExport.m4c ~

decode testExport.m4c
testExport 215E94C7   1   206
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data    24
strings

code
commands:
	p    0
entries
    34    20    24    28    32     0
pointer refs

fixP =        0
fixD =      104
fixT =        0
entry =       34
   0	 F1BD0D10	SUBS SP SP #16
   4	 F8CDE000	STR LR [ SP + 0 ]
   8	 F8DD0008	LDR R0 [ SP + 8 ]
  12	 F8CD000C	STR R0 [ SP + 12 ]
  16	 F8DD000C	LDR R0 [ SP + 12 ]
  20	 F8CD0004	STR R0 [ SP + 4 ]
  24	 F8DDE000	LDR LR [ SP + 0 ]
  28	 F11D0D10	ADDS SP SP #16
  32	     4770	BX LR
  34	 F1BD0D04	SUBS SP SP #4
  38	 F8CDE000	STR LR [ SP + 0 ]
  42	 F7FFFFE9	BL #       -46
  46	 F000F800	BL #         0
  50	 F1BE0032	SUBS R0 LR #50
  54	 1000001B	LDR R1 [ MT + Base(0) ]
  58	 F8C10018	STR R0 [ R1 + 24 ]
  62	 00000004	LDR R0 [ MT + Base(0) ]
  66	 F8D00018	LDR R0 [ R0 + 24 ]
  70	     2800	CMP R0 #  0
  72	     BF08	IT EQ
  74	 EC002195	TrapEQ  5 at pos     281
  78	     4780	BLX R0
  80	 00000009	LDR R0 [ MT + Base(0) ]
  84	 F8D00020	LDR R0 [ R0 + 32 ]
  88	 10000004	LDR R1 [ MT + Base(0) ]
  92	 F8C10028	STR R0 [ R1 + 40 ]
  96	 00000004	LDR R0 [ MT + Base(0) ]
 100	 F8D00028	LDR R0 [ R0 + 40 ]
 104	 10000004	LDR R1 [ MT + Base(0) ]
 108	 F8C10024	STR R0 [ R1 + 36 ]
 112	 F8DDE000	LDR LR [ SP + 0 ]
 116	 F11D0D04	ADDS SP SP #4
 120	     4770	BX LR

*)
