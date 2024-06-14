MODULE testAssert;
  IMPORT Traps;

  PROCEDURE p;
    VAR a,b: INTEGER;
  BEGIN
    ASSERT(a # 0);
    ASSERT((a # 0) & (b # 0));
    ASSERT((a # 0) OR (b # 0));
    ASSERT((a # 0) & (b # 0) OR (a = 1) & (b = 1));
  END p;
  
END testAssert.

OMSPTool.DecObj testAssert.mpc

Traps not imported:
decode testAssert.mpc
testAssert DAE74D27    14
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0006
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0006
code     8
 0000	     8221	SUB #4,SP
 0002	     5221	ADD #4,SP
 0004	     4130	RET
 0006	     4130	RET

Traps imported:
testAssert DAE74D27    86
imports:
	Traps 251F09BA
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 004C
pointer refs

fixup procedures chains
 0046     1	 0001
fixup handlers chains
fixup data chains
fixup type chains
entry =  004C
code    78
 0000	     8221	SUB #4,SP
 0002	     9381	CMP #0,0(SP)
 0004	     0000
 0006	     2002	JNE #2, goes to  000C
 0008	     12B0	CALL #0
 000A	     0000
 000C	     9381	CMP #0,0(SP)
 000E	     0000
 0010	     2403	JEQ #3, goes to  0018
 0012	     9381	CMP #0,2(SP)
 0014	     0002
 0016	     2002	JNE #2, goes to  001C
 0018	     12B0	CALL #10
 001A	     000A
 001C	     9381	CMP #0,0(SP)
 001E	     0000
 0020	     2005	JNE #5, goes to  002C
 0022	     9381	CMP #0,2(SP)
 0024	     0002
 0026	     2002	JNE #2, goes to  002C
 0028	     12B0	CALL #26
 002A	     001A
 002C	     9381	CMP #0,0(SP)
 002E	     0000
 0030	     2403	JEQ #3, goes to  0038
 0032	     9381	CMP #0,2(SP)
 0034	     0002
 0036	     2008	JNE #8, goes to  0048
 0038	     9391	CMP #1,0(SP)
 003A	     0000
 003C	     2003	JNE #3, goes to  0044
 003E	     9391	CMP #1,2(SP)
 0040	     0002
 0042	     2402	JEQ #2, goes to  0048
 0044	     12B0	CALL #42
 0046	     002A
 0048	     5221	ADD #4,SP
 004A	     4130	RET
 004C	     4130	RET

OM4Tool.DecObj testAssert.m4c
decode testAssert.mpc
testAssert DAE74D27  14
  pos 7934  TRAP   7 in OM4Tool at 00000FB2
decode testAssert.m4c
testAssert DAE74D27   1   116
imports:
type descriptors

data     0
strings

code
commands:
entries
    96
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       96
 00000000	 F1BD0D08	SUBS SP SP #8
 00000004	     B500	PUSH LR
 00000006	     9801	LDR R0 [SP + 4]
 00000008	     2800	CMP R0 #0
 0000000A	     BF08	IT EQ
 0000000C	 EC000677	TrapEQ 7 at pos 103
 00000010	     9801	LDR R0 [SP + 4]
 00000012	     2800	CMP R0 #0
 00000014	 F0008003	BEQ #6, goes to  0000001E
 00000018	     9802	LDR R0 [SP + 8]
 0000001A	     2800	CMP R0 #0
 0000001C	     D101	BNE #2, goes to  00000022
 0000001E	 EC001067	Trap 7 at pos 134
 00000022	     9801	LDR R0 [SP + 4]
 00000024	     2800	CMP R0 #0
 00000026	 F0408005	BNE #10, goes to  00000034
 0000002A	     9802	LDR R0 [SP + 8]
 0000002C	     2800	CMP R0 #0
 0000002E	     BF08	IT EQ
 00000030	 EC001267	TrapEQ 7 at pos 166
 00000034	     9801	LDR R0 [SP + 4]
 00000036	     2800	CMP R0 #0
 00000038	 F0008004	BEQ #8, goes to  00000044
 0000003C	     9802	LDR R0 [SP + 8]
 0000003E	     2800	CMP R0 #0
 00000040	 F0408009	BNE #18, goes to  00000056
 00000044	     9801	LDR R0 [SP + 4]
 00000046	     2801	CMP R0 #1
 00000048	 F0408003	BNE #6, goes to  00000052
 0000004C	     9802	LDR R0 [SP + 8]
 0000004E	     2801	CMP R0 #1
 00000050	     D001	BEQ #2, goes to  00000056
 00000052	 EC0015A7	Trap 7 at pos 218
 00000056	 F85DEB04	LDR LR [ SP ] + 4
 0000005A	 F11D0D08	ADDS SP SP #8
 0000005E	     4770	BX LR
 00000060	     B500	PUSH LR
 00000062	 F85DEB04	LDR LR [ SP ] + 4
 00000066	     4770	BX LR
