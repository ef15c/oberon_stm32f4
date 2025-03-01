MODULE testBug;
  TYPE ptr = POINTER TO tr;
    tf = PROCEDURE(pr: ptr): INTEGER;
    tr = RECORD fp: tf END;

  VAR r: ptr; i: INTEGER;

  PROCEDURE p(f: ptr): INTEGER; RETURN 0 END p;

BEGIN (*NEW(r);*) r.fp := p; i := r.fp(r); i := i+i+(r.fp(r))
END testBug.

OMSPTool.DecObj testBug.mpc
decode testBug.mpc
testBug 82C6F0D4 Flash    84
imports:
type descriptors
 0002 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0004 0000
fixup procedures chains
 000A     0	 0000
fixup handlers chains
fixup data chains
 0038     0	 0000
 0048     0	 0002
fixup constants chains
fixup types chains
entry =  0004
code    76
 0000	     430F	MOV #0,R15
 0002	     4130	RET
 0004	     421F	MOV &0,R15
 0006	     0000
 0008	     40BF	MOV #0,0(R15)
 000A	     0000
 000C	     0000
 000E	     421F	MOV &6,R15
 0010	     0006
 0012	     4F2F	MOV @R15,R15
 0014	     120F	PUSH R15
 0016	     1212	PUSH &16
 0018	     0010
 001A	     413F	MOV @SP+,R15
 001C	     128F	CALL R15
 001E	     5321	ADD #2,SP
 0020	     4F82	MOV R15,&0
 0022	     0000
 0024	     421F	MOV &34,R15
 0026	     0022
 0028	     521F	ADD &38,R15
 002A	     0026
 002C	     421E	MOV &24,R14
 002E	     0018
 0030	     4E2E	MOV @R14,R14
 0032	     120F	PUSH R15
 0034	     120E	PUSH R14
 0036	     1212	PUSH &46
 0038	     002E
 003A	     413E	MOV @SP+,R14
 003C	     128E	CALL R14
 003E	     5321	ADD #2,SP
 0040	     4F0E	MOV R15,R14
 0042	     413F	MOV @SP+,R15
 0044	     5E0F	ADD R14,R15
 0046	     4F82	MOV R15,&42
 0048	     002A
 004A	     4130	RET

OM4Tool.DecObj testBug.m4c
decode testBug.m4c
testBug 74DADAB7   1   236
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     8
strings

code
commands:
entries
 00000010
pointer refs
    20
fixP =        0
fixD =      176
fixT =        0
entry =       16
 00000000	     B401	PUSH R0
 00000002	     B500	PUSH LR
 00000004	     2000	MOVS R0 #0
 00000006	 F85DEB04	LDR LR [ SP ] + 4
 0000000A	 F11D0D04	ADDS SP SP #4
 0000000E	     4770	BX LR
 00000010	     B500	PUSH LR
 00000012	 00000009	MOV R0 lower 16-bits base(0)
 00000016	 00000014	MOVT R0 higher 16-bits base + 20
 0000001A	 10000004	MOV R1 lower 16-bits base(0)
 0000001E	 00000000	MOVT R1 higher 16-bits base + 0
 00000022	     DF00	SVC #0
 00000024	 00000005	MOV R0 lower 16-bits base(0)
 00000028	 00000014	MOVT R0 higher 16-bits base + 20
 0000002C	     6800	LDR R0 [ R0 + 0]
 0000002E	     2800	CMP R0 #0
 00000030	     BF08	IT EQ
 00000032	 EC0014D4	TrapEQ 4 at pos 205
 00000036	 F000F800	BL #0, goes to  0000003A
 0000003A	 F1BE013A	SUBS R1 LR #58
 0000003E	     6001	STR R1 [ R0 + 0]
 00000040	 0000000E	MOV R0 lower 16-bits base(0)
 00000044	 00000014	MOVT R0 higher 16-bits base + 20
 00000048	     6800	LDR R0 [ R0 + 0]
 0000004A	     2800	CMP R0 #0
 0000004C	     BF08	IT EQ
 0000004E	 EC0015D4	TrapEQ 4 at pos 221
 00000052	     6800	LDR R0 [ R0 + 0]
 00000054	     B401	PUSH R0
 00000056	 0000000B	MOV R0 lower 16-bits base(0)
 0000005A	 00000014	MOVT R0 higher 16-bits base + 20
 0000005E	     6800	LDR R0 [ R0 + 0]
 00000060	     BC02	POP R1
 00000062	     4788	BLX R1
 00000064	 10000007	MOV R1 lower 16-bits base(0)
 00000068	 00000018	MOVT R1 higher 16-bits base + 24
 0000006C	     6008	STR R0 [ R1 + 0]
 0000006E	 00000005	MOV R0 lower 16-bits base(0)
 00000072	 00000018	MOVT R0 higher 16-bits base + 24
 00000076	     6800	LDR R0 [ R0 + 0]
 00000078	 10000005	MOV R1 lower 16-bits base(0)
 0000007C	 00000018	MOVT R1 higher 16-bits base + 24
 00000080	     6809	LDR R1 [ R1 + 0]
 00000082	     1840	ADDS R0 R0 R1
 00000084	 10000006	MOV R1 lower 16-bits base(0)
 00000088	 00000014	MOVT R1 higher 16-bits base + 20
 0000008C	     6809	LDR R1 [ R1 + 0]
 0000008E	     2900	CMP R1 #0
 00000090	     BF08	IT EQ
 00000092	 EC001704	TrapEQ 4 at pos 240
 00000096	     6809	LDR R1 [ R1 + 0]
 00000098	     B401	PUSH R0
 0000009A	     B402	PUSH R1
 0000009C	 0000000C	MOV R0 lower 16-bits base(0)
 000000A0	 00000014	MOVT R0 higher 16-bits base + 20
 000000A4	     6800	LDR R0 [ R0 + 0]
 000000A6	     BC02	POP R1
 000000A8	     4788	BLX R1
 000000AA	     4601	MOV R1 R0
 000000AC	     BC01	POP R0
 000000AE	     1840	ADDS R0 R0 R1
 000000B0	 1000000A	MOV R1 lower 16-bits base(0)
 000000B4	 00000018	MOVT R1 higher 16-bits base + 24
 000000B8	     6008	STR R0 [ R1 + 0]
 000000BA	 F85DEB04	LDR LR [ SP ] + 4
 000000BE	     4770	BX LR
