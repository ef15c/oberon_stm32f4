MODULE testAssert;

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
testAssert 49ED7A7C Flash     8
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0006
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0006
code     8
 0000	     8221	SUB #4,SP
 0002	     5221	ADD #4,SP
 0004	     4130	RET
 0006	     4130	RET

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

Traps imported:
decode testAssert.mpc
testAssert 49ED7A7C Flash    78
imports:
	Traps 37B3757C
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 004C
fixup procedures chains
 0046     1	 0003
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
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
