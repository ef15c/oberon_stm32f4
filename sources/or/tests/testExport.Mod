MODULE testExport;
  TYPE rec* = RECORD
    x*, y*: INTEGER;
  END;

  VAR l*: LONGINT;
    p1*: PROCEDURE;
    r*: REAL;
(*    filler: ARRAY 1500 OF INTEGER;*)
    v*: rec;
    w: INTEGER;

(*
  
  PROCEDURE q;
    VAR
      a: INTEGER;
  BEGIN
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;
    a := a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a+a;

   END q;
*)

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
testExport 633B402B   1   218
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data    24
strings

code
commands:
	p    0
entries
    28     0    20    24    28    32     0
pointer refs

fixP =        0
fixD =      112
fixT =        0
entry =       28
   0	     B500	PUSH LR
   2	 F8DD0008	LDR R0 [ SP + 8 ]
   6	 F8CD000C	STR R0 [ SP + 12 ]
  10	 F8DD000C	LDR R0 [ SP + 12 ]
  14	 F8CD0004	STR R0 [ SP + 4 ]
  18	 F85DEB04	LDR LR [ SP ] + 4
  22	 F11D0D0C	ADDS SP SP #12
  26	     4770	BX LR
  28	     B500	PUSH LR
  30	 F7FFFFEF	BL #-34
  34	 F000F800	BL #0
  38	 F1BE0026	SUBS R0 LR #38
  42	 10000015	MOV R4 lower 16-bits base(0)
  46	 0000D334	MOVT R1 higher 16-bits var(24)
  50	 F8C10000	STR R0 [ R1 + 0 ]
  54	 00000006	MOV R4 lower 16-bits base(0)
  58	 0000D334	MOVT R0 higher 16-bits var(24)
  62	 F8D00000	LDR R0 [ R0 + 0 ]
  66	     2800	CMP R0 #0
  68	     BF08	IT EQ
  70	 EC011475	TrapEQ 5 at pos 2247
  74	     4780	BLX R0
  76	 0000000B	MOV R4 lower 16-bits base(0)
  80	 0000D334	MOVT R0 higher 16-bits var(32)
  84	 F8D00000	LDR R0 [ R0 + 0 ]
  88	 10000006	MOV R4 lower 16-bits base(0)
  92	 0000D334	MOVT R1 higher 16-bits var(40)
  96	 F8C10000	STR R0 [ R1 + 0 ]
 100	 00000006	MOV R4 lower 16-bits base(0)
 104	 0000D334	MOVT R0 higher 16-bits var(40)
 108	 F8D00000	LDR R0 [ R0 + 0 ]
 112	 10000006	MOV R4 lower 16-bits base(0)
 116	 0000D334	MOVT R1 higher 16-bits var(36)
 120	 F8C10000	STR R0 [ R1 + 0 ]
 124	 F85DEB04	LDR LR [ SP ] + 4

*)
