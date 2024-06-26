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


OM4Tool.DecObj testDeRef.m4c ~

decode testDeRef.m4c
testDeRef D9C6CB1E   1   102
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     4
strings

code
commands:
entries
     0
pointer refs
    20
fixP =        0
fixD =       32
fixT =        0
entry =        0
   0	     B500	PUSH LR
   2	 00000001	LDR R0 [ MT + Base(0) ]
   6	     3014	ADDS R0 #20
   8	 10000003	LDR R1 [ MT + Base(0) ]
  12	 EC001040	Trap 0 at pos 132
  16	 00000004	LDR R0 [ MT + Base(0) ]
  20	 F8D00014	LDR R0 [ R0 + 20 ]
  24	     2800	CMP R0 #0
  26	     BF08	IT EQ
  28	 EC0010B4	TrapEQ 4 at pos 139
  32	 10000008	LDR R1 [ MT + Base(0) ]
  36	 F8D11014	LDR R1 [ R1 + 20 ]
  40	     2900	CMP R1 #0
  42	     BF08	IT EQ
  44	 EC001124	TrapEQ 4 at pos 146
  48	 F8D11004	LDR R1 [ R1 + 4 ]
  52	 F8C01000	STR R1 [ R0 + 0 ]
  56	 F85DEB04	LDR LR [ SP ] + 4
  60	     4770	BX LR

