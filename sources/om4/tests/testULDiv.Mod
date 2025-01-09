MODULE testULDiv;
  VAR a, b: LONGINT;

BEGIN
  (*a := b DIV 10;*)
  (*a := 10 DIV b;*)
  (*a := 10L DIV b;*)
  (*a := a DIV b;*)
  (*a := b MOD 10;*)
  (*a := b MOD 1024;*)
  (*a := 10 MOD b;*)
  (*a := 10L MOD b;*)
  a := a MOD b;
END testULDiv.

OM4Tool.DecObj testULDiv.m4c
decode testULDiv.m4c
testULDiv 13D5EAA9   1    80
imports:
type descriptors

data    16
strings

code
commands:
entries
 00000000
pointer refs

fixP =        0
fixD =       32
fixT =        0
entry =        0
 00000000	     B500	PUSH LR
 00000002	     200A	MOVS R0 #10
 00000004	     2100	MOVS R1 #0
 00000006	 20000003	MOV R2 lower 16-bits base(0)
 0000000A	 00000008	MOVT R2 higher 16-bits base + 8
 0000000E	 E9D22300	LDRD R2 R3 [ R2+ 0 ]
 00000012	     2A01	CMP R2 #1
 00000014	 F1730400	SBCS R4 R3 #0
 00000018	     BFB8	IT LT
 0000001A	 EC001546	TrapLT 6 at pos 212
 0000001E	     DF02	SVC #2
 00000020	 2000000D	MOV R2 lower 16-bits base(0)
 00000024	 00000000	MOVT R2 higher 16-bits base + 0
 00000028	 E9C20100	STRD R0 R1 [ R2+ 0 ]
 0000002C	 F85DEB04	LDR LR [ SP ] + 4
 00000030	     4770	BX LR
