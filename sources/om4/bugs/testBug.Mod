MODULE testBug;
  IMPORT SYSTEM, TextsEx, Modules;

 VAR y: Modules.Module; S: TextsEx.Scanner;

BEGIN SYSTEM.GET(S.l, y)
END testBug.

OM4Tool.DecObj testBug.m4c
decode testBug.m4c
testBug FFC4B609   2    204
imports:
	TextsEx 133E09A6
	Fonts AA480AE7
	Texts 854A4CE2
	Modules E75F0FA2
type descriptors

strings

data   124
code
commands:
entries
 00000000
pointer refs
     0    52    40    20     8
fixP =  00000000
fixV =  00000010
fixC =  00000000
fixT =  00000000
entry =  00000000
 00000000	     B500	PUSH LR
 00000002	 00000001	MOV R0 lower 16-bits base(0), next at  00000000
 00000006	 00000074	MOVT R0 higher 16-bits var + 116
 0000000A	 E9D00100	LDRD R0 R1 [ R0 + 0 ]
 0000000E	     6800	LDR R0 [ R0 + 0 ]
 00000010	 10000007	MOV R1 lower 16-bits base(0), next at  00000002
 00000014	 00000000	MOVT R1 higher 16-bits var + 0
 00000018	     6008	STR R0 [  R1 + 0 ]
 0000001A	 F85DEB04	LDR LR [ SP ] + 4
 0000001E	     4770	BX LR
