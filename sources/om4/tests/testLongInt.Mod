MODULE testLongInt;
  IMPORT Texts, Oberon;

  VAR W: Texts.Writer;
    q: PROCEDURE;

  PROCEDURE p;
    VAR i: INTEGER;
  BEGIN i := 1 - i
  END p;

  PROCEDURE run*;
    VAR x: SET; y: INTEGER;
  BEGIN y := 0; x := {y..23};
    Texts.WriteString(W, "x="); Texts.WriteHex(W, ORD(x)); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END run;

  PROCEDURE run2*;
  BEGIN q
  END run2;

BEGIN q := run; Texts.OpenWriter(W)
END testLongInt.

System.Free OM4P2 OM4G2 OM4A2 OM4B2 OM4S2 ~ System.Free OM4Tool OM4D ~
OM4P2.Compile testLongInt.Mod/s ~ System.Free testLongInt ~ testLongInt.run testLongInt.trap testLongInt.run2

OM4Tool.DecObj testLongInt.m4c
decode testLongInt.m4c
testLongInt 37DE64EE   1    384
imports:
	Texts B8CAF4C4
	Fonts AA480AE7
	Files 1482C9F6
	Oberon B56151A2
	Display 15E666AA
	Viewers E54B088A
	PS2 FA464427
type descriptors

data    44
strings
x=||
code
commands:
	run   20
	run2  150
entries
 000000AA 00000014 00000096
pointer refs
    36    24     4     0
fixP =      202
fixD =      194
fixT =        0
entry =      170
 00000000	     B081	SUB SP SP #4
 00000002	     B500	PUSH LR
 00000004	     9801	LDR R0 [ SP + 4 ]
 00000006	 F1D00001	RSBS R0 R0 #1
 0000000A	     9001	STR R0 [ SP + 4 ]
 0000000C	 F85DEB04	LDR LR [ SP ] + 4
 00000010	     B001	ADD SP SP #4
 00000012	     4770	BX LR
 00000014	     B082	SUB SP SP #8
 00000016	     B500	PUSH LR
 00000018	     2000	MOVS R0 #0
 0000001A	     9002	STR R0 [ SP + 8 ]
 0000001C	     9802	LDR R0 [ SP + 8 ]
 0000001E	 F05F31FF	MOVS R1 #-1
 00000022	 FA11F000	LSLS R0 R1 R0
 00000026	 F05F417F	MOVS R1 #-16777216
 0000002A	     4388	BICS R0 R0 R1
 0000002C	     9001	STR R0 [ SP + 4 ]
 0000002E	 00000017	MOV R0 lower 16-bits base(0)
 00000032	 00000000	MOVT R0 higher 16-bits base + 0
 00000036	 11000004	MOV R1 lower 16-bits base(1)
 0000003A	 00000005	MOVT R1 higher 16-bits var(5)
 0000003E	 20000004	MOV R2 lower 16-bits base(0)
 00000042	 0000002C	MOVT R2 higher 16-bits base + 44
 00000046	     2303	MOVS R3 #3
 00000048	 11E00024	BL Mod(  1) proc(30)
 0000004C	 00000007	MOV R0 lower 16-bits base(0)
 00000050	 00000000	MOVT R0 higher 16-bits base + 0
 00000054	 11000004	MOV R1 lower 16-bits base(1)
 00000058	 00000005	MOVT R1 higher 16-bits var(5)
 0000005C	     9A01	LDR R2 [ SP + 4 ]
 0000005E	 1200000B	BL Mod(  1) proc(32)
 00000062	 00000007	MOV R0 lower 16-bits base(0)
 00000066	 00000000	MOVT R0 higher 16-bits base + 0
 0000006A	 11000004	MOV R1 lower 16-bits base(1)
 0000006E	 00000005	MOVT R1 higher 16-bits var(5)
 00000072	 11D0000A	BL Mod(  1) proc(29)
 00000076	 04000006	MOV R0 lower 16-bits base(4)
 0000007A	 0000000D	MOVT R0 higher 16-bits var(13)
 0000007E	     6800	LDR R0 [ R0 + 0 ]
 00000080	 10000005	MOV R1 lower 16-bits base(0)
 00000084	 00000000	MOVT R1 higher 16-bits base + 0
 00000088	     6809	LDR R1 [ R1 + 0 ]
 0000008A	 10E0000C	BL Mod(  1) proc(14)
 0000008E	 F85DEB04	LDR LR [ SP ] + 4
 00000092	     B002	ADD SP SP #8
 00000094	     4770	BX LR
 00000096	     B500	PUSH LR
 00000098	 0000000C	MOV R0 lower 16-bits base(0)
 0000009C	 00000028	MOVT R0 higher 16-bits base + 40
 000000A0	     6800	LDR R0 [ R0 + 0 ]
 000000A2	     4780	BLX R0
 000000A4	 F85DEB04	LDR LR [ SP ] + 4
 000000A8	     4770	BX LR
 000000AA	     B500	PUSH LR
 000000AC	 F1AF009B	SUB R0 PC #155
 000000B0	 1000000C	MOV R1 lower 16-bits base(0)
 000000B4	 00000028	MOVT R1 higher 16-bits base + 40
 000000B8	     6008	STR R0 [  R1 + 0 ]
 000000BA	 00000005	MOV R0 lower 16-bits base(0)
 000000BE	 00000000	MOVT R0 higher 16-bits base + 0
 000000C2	 11000004	MOV R1 lower 16-bits base(1)
 000000C6	 00000005	MOVT R1 higher 16-bits var(5)
 000000CA	 11800020	BL Mod(  1) proc(24)
 000000CE	 F85DEB04	LDR LR [ SP ] + 4
 000000D2	     4770	BX LR
