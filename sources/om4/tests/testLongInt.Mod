MODULE testLongInt;
  IMPORT Texts, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE run*;
    VAR x: SET; y: INTEGER;
  BEGIN y := 0; x := {y..23};
    Texts.WriteString(W, "x="); Texts.WriteHex(W, ORD(x)); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W) 
END testLongInt.

System.Free OM4P2 OM4G2 OM4A2 OM4B2 OM4S2 ~ System.Free OM4Tool OM4D ~
OM4P2.Compile testLongInt.Mod/s ~ System.Free testLongInt ~ testLongInt.run

OM4Tool.DecObj testLongInt.m4c
decode testLongInt.m4c
testLongInt 1D710F9F   1    312
imports:
	Texts B8CAF4C4
	Fonts AA480AE7
	Files 1482C9F6
	Oberon B56151A2
	Display 15E666AA
	Viewers E54B088A
	PS2 FA464427
type descriptors

data    40
strings
x=||
code
commands:
	run    0
entries
 00000082 00000000
pointer refs
    36    24     4     0
fixP =      148
fixD =      140
fixT =        0
entry =      130
 00000000	     B082	SUB SP SP #8
 00000002	     B500	PUSH LR
 00000004	     2000	MOVS R0 #0
 00000006	     9002	STR R0 [ SP + 8 ]
 00000008	     9802	LDR R0 [ SP + 8 ]
 0000000A	 F05F31FF	MOVS R1 #-1
 0000000E	 FA11F000	LSLS R0 R1 R0
 00000012	 F05F417F	MOVS R1 #-16777216
 00000016	     4388	BICS R0 R0 R1
 00000018	     9001	STR R0 [ SP + 4 ]
 0000001A	 0000000D	MOV R0 lower 16-bits base(0)
 0000001E	 00000000	MOVT R0 higher 16-bits base + 0
 00000022	 11000004	MOV R1 lower 16-bits base(1)
 00000026	 00000005	MOVT R1 higher 16-bits var(5)
 0000002A	 20000004	MOV R2 lower 16-bits base(0)
 0000002E	 00000028	MOVT R2 higher 16-bits base + 40
 00000032	     2303	MOVS R3 #3
 00000034	 11E0001A	BL Mod(  1) proc(30)
 00000038	 00000007	MOV R0 lower 16-bits base(0)
 0000003C	 00000000	MOVT R0 higher 16-bits base + 0
 00000040	 11000004	MOV R1 lower 16-bits base(1)
 00000044	 00000005	MOVT R1 higher 16-bits var(5)
 00000048	     9A01	LDR R2 [ SP + 4 ]
 0000004A	 1200000B	BL Mod(  1) proc(32)
 0000004E	 00000007	MOV R0 lower 16-bits base(0)
 00000052	 00000000	MOVT R0 higher 16-bits base + 0
 00000056	 11000004	MOV R1 lower 16-bits base(1)
 0000005A	 00000005	MOVT R1 higher 16-bits var(5)
 0000005E	 11D0000A	BL Mod(  1) proc(29)
 00000062	 04000006	MOV R0 lower 16-bits base(4)
 00000066	 0000000D	MOVT R0 higher 16-bits var(13)
 0000006A	     6800	LDR R0 [ R0 + 0 ]
 0000006C	 10000005	MOV R1 lower 16-bits base(0)
 00000070	 00000000	MOVT R1 higher 16-bits base + 0
 00000074	     6809	LDR R1 [ R1 + 0 ]
 00000076	 10E0000C	BL Mod(  1) proc(14)
 0000007A	 F85DEB04	LDR LR [ SP ] + 4
 0000007E	     B002	ADD SP SP #8
 00000080	     4770	BX LR
 00000082	     B500	PUSH LR
 00000084	 0000000C	MOV R0 lower 16-bits base(0)
 00000088	 00000000	MOVT R0 higher 16-bits base + 0
 0000008C	 11000004	MOV R1 lower 16-bits base(1)
 00000090	 00000005	MOVT R1 higher 16-bits var(5)
 00000094	 1180000F	BL Mod(  1) proc(24)
 00000098	 F85DEB04	LDR LR [ SP ] + 4
 0000009C	     4770	BX LR
