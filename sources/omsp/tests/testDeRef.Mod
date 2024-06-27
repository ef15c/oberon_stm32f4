MODULE testDeRef;
  IMPORT SYSTEM;
  TYPE prec = POINTER TO rec;
    rec = RECORD
      x, y: INTEGER
    END;
  VAR r: prec; a: rec; i: INTEGER;
BEGIN r := SYSTEM.VAL(prec, SYSTEM.ADR(a));
  r.x := r.y
END testDeRef.

OMSPTool.DecObj testDeRef.mpc

decode testDeRef.mpc
testDeRef D9C6CB1E    50
imports:
type descriptors
 0004 FFFF FFFF FFFF FFFF
data     8
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0000
pointer refs
 000A
fixup procedures chains
fixup handlers chains
fixup data chains
 0006     0	 000A
 0002     0	 000C
fixup type chains
entry =  0000
code    24
 0000	     403F	MOV #0,R15
 0002	     0000
 0004	     4F82	MOV R15,&0
 0006	     0000
 0008	     421F	MOV &6,R15
 000A	     0006
 000C	     421E	MOV &10,R14
 000E	     000A
 0010	     4E9F	MOV 2(R14),0(R15)
 0012	     0002
 0014	     0000
 0016	     4130	RET


OM4Tool.DecObj testDeRef.m4c
decode testDeRef.m4c
testDeRef D9C6CB1E   1   120
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data    16
strings

code
commands:
entries
     0
pointer refs
    20
fixP =        0
fixD =       38
fixT =        0
entry =        0
 00000000	     B500	PUSH LR
 00000002	 00000001	MOV R0 lower 16-bits base(0)
 00000006	 00000018	MOVT R0 higher 16-bits base + 24
 0000000A	 10000004	MOV R1 lower 16-bits base(0)
 0000000E	 00000014	MOVT R1 higher 16-bits base + 20
 00000012	     6008	STR R0 [ R1 + 0]
 00000014	 00000005	MOV R0 lower 16-bits base(0)
 00000018	 00000014	MOVT R0 higher 16-bits base + 20
 0000001C	     6800	LDR R0 [ R0 + 0]
 0000001E	     2800	CMP R0 #0
 00000020	     BF08	IT EQ
 00000022	 EC001434	TrapEQ 4 at pos 195
 00000026	 10000009	MOV R1 lower 16-bits base(0)
 0000002A	 00000014	MOVT R1 higher 16-bits base + 20
 0000002E	     6809	LDR R1 [ R1 + 0]
 00000030	     2900	CMP R1 #0
 00000032	     BF08	IT EQ
 00000034	 EC0014A4	TrapEQ 4 at pos 202
 00000038	     6849	LDR R1 [ R1 + 4]
 0000003A	     6001	STR R1 [ R0 + 0]
 0000003C	 F85DEB04	LDR LR [ SP ] + 4
 00000040	     4770	BX LR
