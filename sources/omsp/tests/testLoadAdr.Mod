MODULE testLoadAdr;
  TYPE rec = RECORD
    x, y: INTEGER;
	END;

  VAR r1: rec;

  PROCEDURE p(VAR r: rec*);
  BEGIN
    r.x := 1; r.y := 2
  END p;

BEGIN
  p(r1)
END testLoadAdr.


OMSPTool.DecObj testLoadAdr.mpc ~

not leaf:
decode testLoadAdr.mpc
testLoadAdr D9473902    46
imports:
	Traps 8AC7BA63
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0012
fixup procedures chains
 001C     0	 0000
fixup handlers chains
fixup data chains
 0018     0	 0000
fixup type chains
 0014     0	 0000
entry =  0012
code    34
 0000	     411F	MOV 2(SP),R15
 0002	     0002
 0004	     439F	MOV #1,0(R15)
 0006	     0000
 0008	     411F	MOV 2(SP),R15
 000A	     0002
 000C	     43AF	MOV #2,2(R15)
 000E	     0002
 0010	     4130	RET
 0012	     1230	PUSH #0
 0014	     0000
 0016	     1230	PUSH #0
 0018	     0000
 001A	     12B0	CALL #0
 001C	     0000
 001E	     5221	ADD #4,SP
 0020	     4130	RET

leaf:
decode testLoadAdr.mpc
testLoadAdr D9473902    36
imports:
	Traps 8AC7BA63
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 000A
fixup procedures chains
 0014     0	 0000
fixup handlers chains
fixup data chains
 000C     0	 0000
fixup type chains
 0010     0	 0000
entry =  000A
code    24
 0000	     4394	MOV #1,0(R4)
 0002	     0000
 0004	     43A4	MOV #2,2(R4)
 0006	     0002
 0008	     4130	RET
 000A	     4034	MOV #0,R4
 000C	     0000
 000E	     4035	MOV #0,R5
 0010	     0000
 0012	     12B0	CALL #0
 0014	     0000
 0016	     4130	RET


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
