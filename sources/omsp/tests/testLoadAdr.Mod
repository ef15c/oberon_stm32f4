MODULE testLoadAdr;
  TYPE rec = RECORD
    x, y: INTEGER;
	END;

  VAR r1: rec;

  PROCEDURE p(VAR r: rec);
  BEGIN
    r.x := 1; r.y := 2
  END p;

BEGIN
  p(r1)
END testLoadAdr.


OMSPTool.DecObj testLoadAdr.mpc ~

decode testLoadAdr.mpc
testLoadAdr D9473902    44
imports:
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 000E
fixup procedures chains
 0014     0	 0000
fixup handlers chains
fixup data chains
 0010     0	 0008
fixup type chains
entry =  000E
code    26
 0000	     412F	MOV @SP,R15
 0002	     439F	MOV #1,0(R15)
 0004	     0000
 0006	     412F	MOV @SP,R15
 0008	     43AF	MOV #2,2(R15)
 000A	     0002
 000C	     4130	RET
 000E	     1230	PUSH #0
 0010	     0000
 0012	     12B0	CALL #0
 0014	     0000
 0016	     5321	ADD #2,SP
 0018	     4130	RET

OM4Tool.DecObj testLoadAdr.m4c ~

decode testLoadAdr.m4c
testLoadAdr D9473902   1    96
imports:
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     8
strings

code
commands:
entries
    26
pointer refs

fixP =        0
fixD =       36
fixT =        0
entry =       26
 00000000	     B403	PUSH R0 R1
 00000002	     B500	PUSH LR
 00000004	     2001	MOVS R0 #1
 00000006	     9901	LDR R1 [SP + 4]
 00000008	     6008	STR R0 [ R1 + 0]
 0000000A	     2002	MOVS R0 #2
 0000000C	     9901	LDR R1 [SP + 4]
 0000000E	     6048	STR R0 [ R1 + 4]
 00000010	 F85DEB04	LDR LR [ SP ] + 4
 00000014	 F11D0D08	ADDS SP SP #8
 00000018	     4770	BX LR
 0000001A	     B500	PUSH LR
 0000001C	 0000000E	MOV R0 lower 16-bits base(0)
 00000020	 00000014	MOVT R0 higher 16-bits base + 20
 00000024	 10000004	MOV R1 lower 16-bits base(0)
 00000028	 00000000	MOVT R1 higher 16-bits base + 0
 0000002C	 F7FFFFE8	BL #-48, goes to  00000000
 00000030	 F85DEB04	LDR LR [ SP ] + 4
 00000034	     4770	BX LR
