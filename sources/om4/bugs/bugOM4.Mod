MODULE bugOM4;
  IMPORT SYSTEM, USBHDef, Texts, Oberon;
  TYPE
    Info* = POINTER TO InfoDesc;
    InfoDesc* = RECORD
      state*, lctrl*, lshift*, lalt*, lgui*, rctrl*, rshift*, ralt*, rgui*: BYTE;
      keys*: ARRAY 6 OF BYTE;
    END;
  VAR info: InfoDesc;
    W: Texts.Writer;
  PROCEDURE p*;
    VAR zero!: Info;
  BEGIN zero := SYSTEM.VAL(Info, SYSTEM.ADR(USBHDef.ZERO));
    Texts.WriteHex(W, SYSTEM.VAL(INTEGER, zero)); Texts.WriteLn(W);
    info := zero^;
    Texts.WriteInt(W, info.state, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END p;
BEGIN Texts.OpenWriter(W);
END bugOM4.

OM4P.Compile bugOM4.Mod/s~
System.Free bugOM4~
bugOM4.p

OM4Tool.DecObj bugOM4.m4c
decode bugOM4.m4c
bugOM4 FAC6F603   2    388
imports:
	USBHDef 8F0D4C9E
	Texts 54E05F8E
	Fonts 8365E168
	Files C2FE3933
	Oberon 48D69B5D
	Display 9549BAA5
	Viewers 45222101
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
strings

data    60
code
commands:
	p 00000000
entries
 000000A8 00000000 00000000
pointer refs
    56    44    24    20
fixP =  000000BA
fixV =  000000AA
fixC =  000000B2
fixT =  00000000
entry =  000000A8
 00000000	     B081	SUB SP SP #4
 00000002	     B500	PUSH LR
 00000004	 01000002	MOV R0 lower 16-bits base(1), next at  00000000
 00000008	 00000001	MOVT R0 higher 16-bits const(1)
 0000000C	     9001	STR R0 [ SP + 4 ]
 0000000E	 00000007	MOV R0 lower 16-bits base(0), next at  00000000
 00000012	 00000014	MOVT R0 higher 16-bits var + 20
 00000016	 12000009	MOV R1 lower 16-bits base(2), next at  00000004
 0000001A	 00000005	MOVT R1 higher 16-bits const(5)
 0000001E	     9A01	LDR R2 [ SP + 4 ]
 00000020	 22000010	BL Mod(  2) proc(32)
 00000024	 0000000B	MOV R0 lower 16-bits base(0), next at  0000000E
 00000028	 00000014	MOVT R0 higher 16-bits var + 20
 0000002C	 1200000B	MOV R1 lower 16-bits base(2), next at  00000016
 00000030	 00000005	MOVT R1 higher 16-bits const(5)
 00000034	 21D0000A	BL Mod(  2) proc(29)
 00000038	     9801	LDR R0 [ SP + 4 ]
 0000003A	 1000000B	MOV R1 lower 16-bits base(0), next at  00000024
 0000003E	 00000000	MOVT R1 higher 16-bits var + 0
 00000042	     2205	MOVS R2 #5
 00000044	 F8503B04	LDR R3 [ R0 ] + 4
 00000048	 F8413B04	STR R3 [  R1 ] + 4
 0000004C	     1E52	SUBS R2 R2 #1
 0000004E	     D1F9	BNE #-14, goes to  00000044
 00000050	 0000000B	MOV R0 lower 16-bits base(0), next at  0000003A
 00000054	 00000014	MOVT R0 higher 16-bits var + 20
 00000058	 12000016	MOV R1 lower 16-bits base(2), next at  0000002C
 0000005C	 00000005	MOVT R1 higher 16-bits const(5)
 00000060	 20000008	MOV R2 lower 16-bits base(0), next at  00000050
 00000064	 00000000	MOVT R2 higher 16-bits var + 0
 00000068	     7812	LDRB R2 [ R2 + 0 ]
 0000006A	 F34273C0	SBFX R3 R2 #31 #1
 0000006E	     2401	MOVS R4 #1
 00000070	 21F0001E	BL Mod(  2) proc(31)
 00000074	 0000000A	MOV R0 lower 16-bits base(0), next at  00000060
 00000078	 00000014	MOVT R0 higher 16-bits var + 20
 0000007C	 12000012	MOV R1 lower 16-bits base(2), next at  00000058
 00000080	 00000005	MOVT R1 higher 16-bits const(5)
 00000084	 21D0000A	BL Mod(  2) proc(29)
 00000088	 0500000A	MOV R0 lower 16-bits base(5), next at  00000074
 0000008C	 0000000D	MOVT R0 higher 16-bits var(13)
 00000090	     6800	LDR R0 [ R0 + 0 ]
 00000092	 10000005	MOV R1 lower 16-bits base(0), next at  00000088
 00000096	 00000014	MOVT R1 higher 16-bits var + 20
 0000009A	     6809	LDR R1 [ R1 + 0 ]
 0000009C	 20E0000C	BL Mod(  2) proc(14)
 000000A0	 F85DEB04	LDR LR [ SP ] + 4
 000000A4	     B001	ADD SP SP #4
 000000A6	     4770	BX LR
 000000A8	     B500	PUSH LR
 000000AA	 0000000C	MOV R0 lower 16-bits base(0), next at  00000092
 000000AE	 00000014	MOVT R0 higher 16-bits var + 20
 000000B2	 1200001B	MOV R1 lower 16-bits base(2), next at  0000007C
 000000B6	 00000005	MOVT R1 higher 16-bits const(5)
 000000BA	 2180000F	BL Mod(  2) proc(24)
 000000BE	 F85DEB04	LDR LR [ SP ] + 4
 000000C2	     4770	BX LR
