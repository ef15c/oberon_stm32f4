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
entry =       36


OM4Tool.DecObj testExport.m4c ~

decode testExport.m4c
testExport 633B402B   1   196
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data    24
strings

code
commands:
	p    0
entries
    24     0    20    24    28    32     0
pointer refs

fixP =        0
fixD =       90
fixT =        0
entry =       24
 00000000	 F1BD0D0C	SUBS SP SP #12
 00000004	     B500	PUSH LR
 00000006	     9802	LDR R0 [SP + 8]
 00000008	     9003	STR R0 [SP + 12]
 0000000A	     9803	LDR R0 [SP + 12]
 0000000C	     9001	STR R0 [SP + 4]
 0000000E	 F85DEB04	LDR LR [ SP ] + 4
 00000012	 F11D0D0C	ADDS SP SP #12
 00000016	     4770	BX LR
 00000018	     B500	PUSH LR
 0000001A	 F7FFFFF1	BL #-30, goes to  00000000
 0000001E	 F000F800	BL #0, goes to  00000022
 00000022	 F1BE0021	SUBS R0 LR #33
 00000026	 10000013	MOV R1 lower 16-bits base(0)
 0000002A	 00000018	MOVT R1 higher 16-bits base + 24
 0000002E	     6008	STR R0 [ R1 + 0]
 00000030	 00000005	MOV R0 lower 16-bits base(0)
 00000034	 00000018	MOVT R0 higher 16-bits base + 24
 00000038	     6800	LDR R0 [ R0 + 0]
 0000003A	     4780	BLX R0
 0000003C	 00000006	MOV R0 lower 16-bits base(0)
 00000040	 00000020	MOVT R0 higher 16-bits base + 32
 00000044	     6800	LDR R0 [ R0 + 0]
 00000046	 10000005	MOV R1 lower 16-bits base(0)
 0000004A	 00000028	MOVT R1 higher 16-bits base + 40
 0000004E	     6008	STR R0 [ R1 + 0]
 00000050	 00000005	MOV R0 lower 16-bits base(0)
 00000054	 00000028	MOVT R0 higher 16-bits base + 40
 00000058	     6800	LDR R0 [ R0 + 0]
 0000005A	 10000005	MOV R1 lower 16-bits base(0)
 0000005E	 00000024	MOVT R1 higher 16-bits base + 36
 00000062	     6008	STR R0 [ R1 + 0]
 00000064	 F85DEB04	LDR LR [ SP ] + 4
 00000068	     4770	BX LR

*)
