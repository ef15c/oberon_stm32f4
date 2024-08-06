MODULE testString;
  CONST st* = "salut"; st1 = "hi";
  VAR s: ARRAY 10 OF CHAR;

  PROCEDURE p(m: ARRAY OF CHAR);
  BEGIN
  END p;

BEGIN
  s := "bonjour";
  p(s); p(st); p("salut")
END testString.


OMSPTool.DecObj testString.mpc
decode testString.mpc
testString DF726B2B Flash    84
imports:
type descriptors

data    10
strings
salut|hi||bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0002
fixup procedures chains
 003C     0	 0000
fixup handlers chains
fixup data chains
 001C     0	 0000
fixup types and strings chains
 0038     0	 0000
 0008     0	 000A
entry =  0002
code    66
 0000	     4130	RET
 0002	     403F	MOV #0,R15
 0004	     0000
 0006	     403E	MOV #0,R14
 0008	     0000
 000A	     4EBF	MOV @R14+,0(R15)
 000C	     0000
 000E	     532F	ADD #2,R15
 0010	     93CE	CMP.B #0,65535(R14)
 0012	     FFFF
 0014	     23FA	JNE #-6, goes to  000A
 0016	     1230	PUSH #10
 0018	     000A
 001A	     1230	PUSH #4
 001C	     0004
 001E	     12B0	CALL #0
 0020	     0000
 0022	     5221	ADD #4,SP
 0024	     1230	PUSH #6
 0026	     0006
 0028	     1230	PUSH #0
 002A	     0000
 002C	     12B0	CALL #32
 002E	     0020
 0030	     5221	ADD #4,SP
 0032	     1230	PUSH #6
 0034	     0006
 0036	     1230	PUSH #42
 0038	     002A
 003A	     12B0	CALL #46
 003C	     002E
 003E	     5221	ADD #4,SP
 0040	     4130	RET

OM4Tool.DecObj testString.m4c
decode testString.m4c
testString DF5AB52B   1   120
imports:
type descriptors

data    12
strings
salut|||bonjour|
code
commands:
entries
    14
pointer refs

fixP =        0
fixD =       58
fixT =        0
entry =       14
 00000000	     B403	PUSH R0 R1
 00000002	     B500	PUSH LR
 00000004	 F85DEB04	LDR LR [ SP ] + 4
 00000008	 F11D0D08	ADDS SP SP #8
 0000000C	     4770	BX LR
 0000000E	     B500	PUSH LR
 00000010	 00000008	MOV R0 lower 16-bits base(0)
 00000014	 00000000	MOVT R0 higher 16-bits base + 0
 00000018	 10000004	MOV R1 lower 16-bits base(0)
 0000001C	 00000014	MOVT R1 higher 16-bits base + 20
 00000020	 F8512B04	LDR R2 [ R1 ] + 4
 00000024	 F8402B04	STR R2 [ R0 ] + 4
 00000028	     1612	ASRS R2 R2 #24
 0000002A	     D1F9	BNE #-14, goes to  00000020
 0000002C	 0000000A	MOV R0 lower 16-bits base(0)
 00000030	 00000000	MOVT R0 higher 16-bits base + 0
 00000034	     210A	MOVS R1 #10
 00000036	 F7FFFFE3	BL #-58, goes to  00000000
 0000003A	 00000007	MOV R0 lower 16-bits base(0)
 0000003E	 0000000C	MOVT R0 higher 16-bits base + 12
 00000042	     2106	MOVS R1 #6
 00000044	 F7FFFFDC	BL #-72, goes to  00000000
 00000048	 F85DEB04	LDR LR [ SP ] + 4
 0000004C	     4770	BX LR

OM4Tool.DecSym testString.sm4
decode testString.sm4
testString DF5AB52B  1
   1 st [^11]    0
