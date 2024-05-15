MODULE StackTrace;
  IMPORT Texts, Oberon, System;

  VAR W: Texts.Writer;

  PROCEDURE showDump*;
  BEGIN 
   Texts.WriteString(W, "cause: "); Texts.WriteInt(W, System.stack.cause, 1); Texts.WriteLn(W);
   Texts.WriteString(W, "eos : "); Texts.WriteHex(W, System.stack.eos); Texts.WriteLn(W);
   Texts.WriteString(W, "PC : "); Texts.WriteHex(W, System.stack.PC); Texts.WriteLn(W);
   Texts.WriteString(W, "LR : "); Texts.WriteHex(W, System.stack.LR); Texts.WriteLn(W);
   Texts.WriteString(W, "stack size: "); Texts.WriteInt(W, System.stack.len, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END showDump;

BEGIN Texts.OpenWriter(W)
END StackTrace.

OM4Tool.DecObj StackTrace.m4c

decode StackTrace.m4c
StackTrace ADB1E700   1   732
imports:
	Texts 5DE8CCCE
	Fonts DFE2F6B3
	Files 73F5D686
	Oberon 6A8ED1EE
	Display BB8A47EF
	Viewers 0950B104
	PS2 6B8C9D46
	System 9EC8A202
type descriptors

data    40
strings
cause: |eos : ||PC : |||LR : |||stack size: ||||
code
commands:
	showDump    0
entries
   486     0
pointer refs
    36    24     4     0
fixP =      504
fixD =      496
fixT =        0
entry =      486
 00000000	     B500	PUSH LR
 00000002	 00000001	MOV R0 lower 16-bits base(0)
 00000006	 00000000	MOVT R0 higher 16-bits base + 0
 0000000A	 11000004	MOV R1 lower 16-bits base(1)
 0000000E	 00000005	MOVT R1 higher 16-bits var(5)
 00000012	 20000004	MOV R2 lower 16-bits base(0)
 00000016	 00000028	MOVT R2 higher 16-bits base + 40
 0000001A	     2308	MOVS R3 #8
 0000001C	 11D0000E	BL Mod(  1) proc(29)
 00000020	 00000007	MOV R0 lower 16-bits base(0)
 00000024	 00000000	MOVT R0 higher 16-bits base + 0
 00000028	 11000004	MOV R1 lower 16-bits base(1)
 0000002C	 00000005	MOVT R1 higher 16-bits var(5)
 00000030	 28000004	MOV R2 lower 16-bits base(8)
 00000034	 00000002	MOVT R2 higher 16-bits var(2)
 00000038	     6812	LDR R2 [ R2 + 0]
 0000003A	     2A00	CMP R2 #0
 0000003C	     BF08	IT EQ
 0000003E	 EC001344	TrapEQ 4 at pos 180
 00000042	     7812	LDRB R2 [ R2 + 0]
 00000044	     2301	MOVS R3 #1
 00000046	 11E00015	BL Mod(  1) proc(30)
 0000004A	 0000000D	MOV R0 lower 16-bits base(0)
 0000004E	 00000000	MOVT R0 higher 16-bits base + 0
 00000052	 11000004	MOV R1 lower 16-bits base(1)
 00000056	 00000005	MOVT R1 higher 16-bits var(5)
 0000005A	 11C0000A	BL Mod(  1) proc(28)
 0000005E	 00000006	MOV R0 lower 16-bits base(0)
 00000062	 00000000	MOVT R0 higher 16-bits base + 0
 00000066	 11000004	MOV R1 lower 16-bits base(1)
 0000006A	 00000005	MOVT R1 higher 16-bits var(5)
 0000006E	 20000004	MOV R2 lower 16-bits base(0)
 00000072	 00000030	MOVT R2 higher 16-bits base + 48
 00000076	     2307	MOVS R3 #7
 00000078	 11D0000F	BL Mod(  1) proc(29)
 0000007C	 00000007	MOV R0 lower 16-bits base(0)
 00000080	 00000000	MOVT R0 higher 16-bits base + 0
 00000084	 11000004	MOV R1 lower 16-bits base(1)
 00000088	 00000005	MOVT R1 higher 16-bits var(5)
 0000008C	 28000004	MOV R2 lower 16-bits base(8)
 00000090	 00000002	MOVT R2 higher 16-bits var(2)
 00000094	     6812	LDR R2 [ R2 + 0]
 00000094	     6812	LDR R2 [ R2 + 0]
 00000096	     2A00	CMP R2 #0
 00000098	     BF08	IT EQ
 0000009A	 EC002114	TrapEQ 4 at pos 273
 0000009E	     6852	LDR R2 [ R2 + 4]
 000000A0	 11F00014	BL Mod(  1) proc(31)
 000000A4	 0000000C	MOV R0 lower 16-bits base(0)
 000000A8	 00000000	MOVT R0 higher 16-bits base + 0
 000000AC	 11000004	MOV R1 lower 16-bits base(1)
 000000B0	 00000005	MOVT R1 higher 16-bits var(5)
 000000B4	 11C0000A	BL Mod(  1) proc(28)
 000000B8	 00000006	MOV R0 lower 16-bits base(0)
 000000BC	 00000000	MOVT R0 higher 16-bits base + 0
 000000C0	 11000004	MOV R1 lower 16-bits base(1)
 000000C4	 00000005	MOVT R1 higher 16-bits var(5)
 000000C8	 20000004	MOV R2 lower 16-bits base(0)
 000000CC	 00000038	MOVT R2 higher 16-bits base + 56
 000000D0	     2306	MOVS R3 #6
 000000D2	 11D0000F	BL Mod(  1) proc(29)
 000000D6	 00000007	MOV R0 lower 16-bits base(0)
 000000DA	 00000000	MOVT R0 higher 16-bits base + 0
 000000DE	 11000004	MOV R1 lower 16-bits base(1)
 000000E2	 00000005	MOVT R1 higher 16-bits var(5)
 000000E6	 28000004	MOV R2 lower 16-bits base(8)
 000000EA	 00000002	MOVT R2 higher 16-bits var(2)
 000000EE	     6812	LDR R2 [ R2 + 0]
 000000F0	     2A00	CMP R2 #0
 000000F2	     BF08	IT EQ
 000000F4	 EC002694	TrapEQ 4 at pos 361
 000000F8	     6892	LDR R2 [ R2 + 8]
 000000FA	 11F00014	BL Mod(  1) proc(31)
 000000FE	 0000000C	MOV R0 lower 16-bits base(0)
 00000102	 00000000	MOVT R0 higher 16-bits base + 0
 00000106	 11000004	MOV R1 lower 16-bits base(1)
 0000010A	 00000005	MOVT R1 higher 16-bits var(5)
0000010E	 11C0000A	BL Mod(  1) proc(28)
 00000112	 00000006	MOV R0 lower 16-bits base(0)
 00000116	 00000000	MOVT R0 higher 16-bits base + 0
 0000011A	 11000004	MOV R1 lower 16-bits base(1)
 0000011E	 00000005	MOVT R1 higher 16-bits var(5)
 00000122	 20000004	MOV R2 lower 16-bits base(0)
 00000126	 00000040	MOVT R2 higher 16-bits base + 64
 0000012A	     2306	MOVS R3 #6
 0000012C	 11D0000F	BL Mod(  1) proc(29)
 00000130	 00000007	MOV R0 lower 16-bits base(0)
 00000134	 00000000	MOVT R0 higher 16-bits base + 0
 00000138	 11000004	MOV R1 lower 16-bits base(1)
 0000013C	 00000005	MOVT R1 higher 16-bits var(5)
 00000140	 28000004	MOV R2 lower 16-bits base(8)
 00000144	 00000002	MOVT R2 higher 16-bits var(2)
 00000148	     6812	LDR R2 [ R2 + 0]
 0000014A	     2A00	CMP R2 #0
 0000014C	     BF08	IT EQ
 0000014E	 EC003414	TrapEQ 4 at pos 449
 00000152	     68D2	LDR R2 [ R2 + 12]
 00000154	 11F00014	BL Mod(  1) proc(31)
 00000158	 0000000C	MOV R0 lower 16-bits base(0)
 0000015C	 00000000	MOVT R0 higher 16-bits base + 0
 00000160	 11000004	MOV R1 lower 16-bits base(1)
 00000164	 00000005	MOVT R1 higher 16-bits var(5)
 00000168	 11C0000A	BL Mod(  1) proc(28)
 0000016C	 00000006	MOV R0 lower 16-bits base(0)
 00000170	 00000000	MOVT R0 higher 16-bits base + 0
 00000174	 11000004	MOV R1 lower 16-bits base(1)
 00000178	 00000005	MOVT R1 higher 16-bits var(5)
 0000017C	 20000004	MOV R2 lower 16-bits base(0)
 00000180	 00000048	MOVT R2 higher 16-bits base + 72
 00000184	     230D	MOVS R3 #13
 00000186	 11D0000F	BL Mod(  1) proc(29)
 0000018A	 00000007	MOV R0 lower 16-bits base(0)
 0000018E	 00000000	MOVT R0 higher 16-bits base + 0
 00000192	 11000004	MOV R1 lower 16-bits base(1)
 00000196	 00000005	MOVT R1 higher 16-bits var(5)
 0000019A	 28000004	MOV R2 lower 16-bits base(8)
 0000019E	 00000002	MOVT R2 higher 16-bits var(2)
 000001A2	     6812	LDR R2 [ R2 + 0]
 000001A4	     2A00	CMP R2 #0
 000001A6	     BF08	IT EQ
 000001A8	 EC004214	TrapEQ 4 at pos 545
 000001AC	     6912	LDR R2 [ R2 + 16]
 000001AE	     2301	MOVS R3 #1
 000001B0	 11E00015	BL Mod(  1) proc(30)
 000001B4	 0000000D	MOV R0 lower 16-bits base(0)
 000001B8	 00000000	MOVT R0 higher 16-bits base + 0
 000001BC	 11000004	MOV R1 lower 16-bits base(1)
 000001C0	 00000005	MOVT R1 higher 16-bits var(5)
 000001C4	 11C0000A	BL Mod(  1) proc(28)
 000001C8	 04000006	MOV R0 lower 16-bits base(4)
 000001CC	 0000000D	MOVT R0 higher 16-bits var(13)
 000001D0	     6800	LDR R0 [ R0 + 0]
 000001D2	 10000005	MOV R1 lower 16-bits base(0)
 000001D6	 00000000	MOVT R1 higher 16-bits base + 0
 000001DA	     6809	LDR R1 [ R1 + 0]
 000001DC	 10E0000C	BL Mod(  1) proc(14)
 000001E0	 F85DEB04	LDR LR [ SP ] + 4
 000001E4	     4770	BX LR
 000001E6	     B500	PUSH LR
 000001E8	 0000000B	MOV R0 lower 16-bits base(0)
 000001EC	 00000000	MOVT R0 higher 16-bits base + 0
 000001F0	 11000004	MOV R1 lower 16-bits base(1)
 000001F4	 00000005	MOVT R1 higher 16-bits var(5)
 000001F8	 1170000E	BL Mod(  1) proc(23)
 000001FC	 F85DEB04	LDR LR [ SP ] + 4
 00000200	     4770	BX LR
