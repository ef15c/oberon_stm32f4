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
 00000000	     8221	SUB #4,SP
 00000002	     5221	ADD #4,SP
 00000004	     4130	RET
 00000006	     4130	RET

Traps imported:
decode testAssert.mpc
testAssert DAE74D27    90
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
 0050
pointer refs

fixup procedures chains
 004A     1	 0001
fixup handlers chains
fixup data chains
fixup type chains
entry =  0050
code    82
 00000000	     8221	SUB #4,SP
 00000002	     9381	CMP #0,0(SP)
 00000004	     0000
 00000006	     2002	JNE #2, goes to  0000000C
 00000008	     12B0	CALL #0
 0000000A	     0000
 0000000C	     9381	CMP #0,0(SP)
 0000000E	     0000
 00000010	     2803	JNC #3, goes to  00000018
 00000012	     9381	CMP #0,2(SP)
 00000014	     0002
 00000016	     2003	JNE #3, goes to  0000001E
 00000018	     3C00	JMP #0, goes to  0000001A
 0000001A	     12B0	CALL #10
 0000001C	     000A
 0000001E	     9381	CMP #0,0(SP)
 00000020	     0000
 00000022	     2005	JNE #5, goes to  0000002E
 00000024	     9381	CMP #0,2(SP)
 00000026	     0002
 00000028	     2002	JNE #2, goes to  0000002E
 0000002A	     12B0	CALL #28
 0000002C	     001C
 0000002E	     9381	CMP #0,0(SP)
 00000030	     0000
 00000032	     2803	JNC #3, goes to  0000003A
 00000034	     9381	CMP #0,2(SP)
 00000036	     0002
 00000038	     2009	JNE #9, goes to  0000004C
 0000003A	     9391	CMP #1,0(SP)
 0000003C	     0000
 0000003E	     2C03	JC #3, goes to  00000046
 00000040	     9391	CMP #1,2(SP)
 00000042	     0002
 00000044	     2403	JEQ #3, goes to  0000004C
 00000046	     3C00	JMP #0, goes to  00000048
 00000048	     12B0	CALL #44
 0000004A	     002C
 0000004C	     5221	ADD #4,SP
 0000004E	     4130	RET
 00000050	     4130	RET
