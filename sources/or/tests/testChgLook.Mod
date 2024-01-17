MODULE testChgLook;
IMPORT Fonts, Texts;

PROCEDURE test;
VAR T: Texts.Text; beg, end: LONGINT;
BEGIN
  Texts.ChangeLooks(T, beg, end, {0}, Fonts.This("Oberon10.Scn.Fnt"), 0, 0)
END test;

END testChgLook.

(*
ORTool.DecObj testChgLook.rsc ~

ORTool 18.2.2013
decode testChgLook.rsc
testChgLook C1463D27   1   172
imports:
	Fonts F4C9F557
	Texts ECBD67B7
	Files 73F5D686
type descriptors

data     0
strings
Oberon10.Scn.Fnt||||
code
   0	 4EE90010	SUB SP SP     16
   1	 AFE00000	STR  LNK SP       0
   2	 80E00004	LDR  R0 SP       4
   3	 81E00008	LDR  R1 SP       8
   4	 82E0000C	LDR  R2 SP      12
   5	 43000001	MOV  R3  R0      1
   6	 4EE90010	SUB SP SP     16
   7	 A0E0000C	STR   R0 SP      12
   8	 A1E00008	STR   R1 SP       8
   9	 A2E00004	STR   R2 SP       4
  10	 A3E00000	STR   R3 SP       0
  11	 8000000B	LDR  R0  R0      11
  12	 40080000	ADD  R0  R0      0
  13	 41000011	MOV  R1  R0     17
  14	 F710500E	BL   20494
  15	 04000000	MOV  R4  R0  R0
  16	 83E00000	LDR  R3 SP       0
  17	 82E00004	LDR  R2 SP       4
  18	 81E00008	LDR  R1 SP       8
  19	 80E0000C	LDR  R0 SP      12
  20	 4EE80010	ADD SP SP     16
  21	 45000000	MOV  R5  R0      0
  22	 46000000	MOV  R6  R0      0
  23	 F7210009	BL   65545
  24	 8FE00000	LDR LNK SP       0
  25	 4EE80010	ADD SP SP     16
  26	 C700000F	B LNK
  27	 4EE90004	SUB SP SP      4
  28	 AFE00000	STR  LNK SP       0
  29	 8FE00000	LDR LNK SP       0
  30	 4EE80004	ADD SP SP      4
  31	 C700000F	B LNK
commands:
entries
   108
pointer refs

fixP =       23
fixD =       11
fixT =        0
entry =      108



OM4Tool.DecObj testChgLook.m4c ~
OM4Tool 12.11.2023
decode testChgLook.m4c
testChgLook C1463D27   1   120
imports:
	Fonts 78B93908
	Texts 767BBA3E
	Files 73F5D686
type descriptors

data     0
strings
Oberon10.Scn.Fnt||||
code
commands:
entries
    52
pointer refs

fixP =       38
fixD =       16
fixT =        0
entry =       52
 00000000	 F1BD0D0C	SUBS SP SP #12
 00000004	     B500	PUSH LR
 00000006	     9801	LDR R0 [SP + 4]
 00000008	     9902	LDR R1 [SP + 8]
 0000000A	     9A03	LDR R2 [SP + 12]
 0000000C	     2301	MOVS R3 #1
 0000000E	     B40F	PUSH R0 R1 R2 R3
 00000010	 00000008	MOV R0 lower 16-bits base(0)
 00000014	 00000000	MOVT R0 higher 16-bits base + 0
 00000018	     2111	MOVS R1 #17
 0000001A	 1060000D	BL Mod(  1) proc(6)
 0000001E	     4681	MOV R9 R0
 00000020	     BC0F	POP R0 R1 R2 R3
 00000022	     2500	MOVS R5 #0
 00000024	     2600	MOVS R6 #0
 00000026	 21000006	BL Mod(  2) proc(16)
 0000002A	 F85DEB04	LDR LR [ SP ] + 4
 0000002E	 F11D0D0C	ADDS SP SP #12
 00000032	     4770	BX LR
 00000034	     B500	PUSH LR
 00000036	 F85DEB04	LDR LR [ SP ] + 4
 0000003A	     4770	BX LR



*)
