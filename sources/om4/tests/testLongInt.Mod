MODULE testLongInt;

  TYPE R = RECORD l: LONGINT; i: INTEGER END;
    PR = POINTER TO R;

  VAR s: LONGINT;

  PROCEDURE run*(VAR x: LONGINT);
    VAR pr!: PR; r: R;n: INTEGER; a: ARRAY 5 OF LONGINT;
      b: ARRAY 5 OF INTEGER; y: LONGINT;
  BEGIN INC(s, x); INC(x, LSL(y, n)); INC(pr.l, n); INC(pr.i, n)
  END run;

BEGIN
END testLongInt.

System.Free OM4P2 OM4G2 OM4A2 OM4B2 OM4S2 ~ System.Free OM4Tool OM4D ~
OM4P2.Compile testLongInt.Mod/s ~ System.Free testLongInt ~ testLongInt.run testLongInt.trap testLongInt.run2

OM4Tool.DecObj testLongInt.m4c

 00000000	     B096	SUB SP SP #88
 00000002	     B401	PUSH R0
 00000004	     B500	PUSH LR
 00000006	 00000003	MOV R0 lower 16-bits base(0)
 0000000A	 00000014	MOVT R0 higher 16-bits base + 20
 0000000E	 E9D02300	LDRD R2 R3 [ R0 + 0 ]
 00000012	     9B01	LDR R3 [ SP + 4 ]
 00000014	 E9D33400	LDRD R3 R4 [ R3 + 0 ]
 00000018	     18D2	ADDS R2 R2 R3
 0000001A	     4163	ADCS R3 R3 R4
 0000001C	 E9C02300	STRD R2 R3 [ R0 + 0 ]

decode testLongInt.m4c
testLongInt 1D710F9F   1    112
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
commands:
	run    0
entries
 0000003C 00000000
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       60
 00000000	     B094	SUB SP SP #80
 00000002	     B500	PUSH LR
 00000004	     9801	LDR R0 [ SP + 4 ]
 00000006	     2800	CMP R0 #0
 00000008	     BF08	IT EQ
 0000000A	 EC001534	TrapEQ 4 at pos 211
 0000000E	     9A05	LDR R2 [ SP + 20 ]
 00000010	 F34273C0	SBFX R3 R2 #31 #1
 00000014	 E9D04500	LDRD R4 R5 [ R0 + 0 ]
 00000018	     18A4	ADDS R4 R4 R2
 0000001A	     415D	ADCS R5 R5 R3
 0000001C	 E9C04500	STRD R4 R5 [ R0 + 0 ]
 00000020	     9801	LDR R0 [ SP + 4 ]
 00000022	     2800	CMP R0 #0
 00000024	     BF08	IT EQ
 00000026	 EC001614	TrapEQ 4 at pos 225
 0000002A	     3008	ADDS R0 R0 #8 ; Optimisation possible avec suppression de cette instruction
 0000002C	     6801	LDR R1 [ R0 + 0 ]; et remplacement de celle ci par LDR R1 [ R0 + 8 ]
 0000002E	     9A05	LDR R2 [ SP + 20 ]
 00000030	     1889	ADDS R1 R1 R2
 00000032	     6001	STR R1 [  R0 + 0 ] et celle ci par STR R1 [  R0 + 8 ]
 00000034	 F85DEB04	LDR LR [ SP ] + 4
 00000038	     B014	ADD SP SP #80
 0000003A	     4770	BX LR
 0000003C	     B500	PUSH LR
 0000003E	 F85DEB04	LDR LR [ SP ] + 4
 00000042	     4770	BX LR
