MODULE bugOM4;
  IMPORT SYSTEM;

  PROCEDURE p;
    VAR i: INTEGER; n: LONGINT;
  BEGIN i := SYSTEM.ADR(n);
  END p;

END bugOM4.

OM4P.Compile bugOM4.Mod/s~
System.Free bugOM4~
bugOM4.p

OM4Tool.DecObj bugOM4.m4c
decode bugOM4.m4c
bugOM4 64868F7D   2     36
imports:
type descriptors

strings

data     0
code
commands:
entries
 00000010
pointer refs

fixP =  00000000
fixV =  00000000
fixC =  00000000
fixT =  00000000
entry =  00000010
 00000000	     B083	SUB SP SP #12
 00000002	     B500	PUSH LR
 00000004	     A802	ADD R0 SP #8
 00000006	     9001	STR R0 [ SP + 4 ]
 00000008	 F85DEB04	LDR LR [ SP ] + 4
 0000000C	     B003	ADD SP SP #12
 0000000E	     4770	BX LR
 00000010	     B500	PUSH LR
 00000012	 F85DEB04	LDR LR [ SP ] + 4
 00000016	     4770	BX LR
