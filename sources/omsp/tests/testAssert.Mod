MODULE testAssert;

  PROCEDURE p;
    VAR a,b: INTEGER;
  BEGIN
    ASSERT(a # 0);
    ASSERT((a # 0) & (b # 0));
    ASSERT((a # 0) OR (b # 0));
    ASSERT((a # 0) & (b # 0) OR (a = 1) & (b = 1));
  END p;

BEGIN p
END testAssert.

OMSPP.Compile testAssert.Mod~
OMSPTool.DecObj testAssert.mpc

Traps not imported:
decode testAssert.mpc
testAssert A50F1F22
imports:

section     0	c    6	p
 0000	     8221	SUB #4,SP
 0002	     5221	ADD #4,SP
 0004	     4130	RET
fixups:

section     1	c    6	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4130	RET
fixups:
 0003	s0.0

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1

MODULE testAssert;
  IMPORT Traps;

  PROCEDURE p;
    VAR a,b: INTEGER;
  BEGIN
    ASSERT(a # 0);
    ASSERT((a # 0) & (b # 0));
    ASSERT((a # 0) OR (b # 0));
    ASSERT((a # 0) & (b # 0) OR (a = 1) & (b = 1))
  END p;

BEGIN p
END testAssert.

OMSPP.Compile @/s
OMSPTool.DecObj testAssert.mpc

Traps imported:
decode testAssert.mpc
testAssert A50F1F22
imports:
	Traps 3714F611

section     0	c   76	p
 0000	     8221	SUB #4,SP
 0002	     9381	CMP #0,0(SP)
 0004	     0000
 0006	     2002	JNE $+6, goes to  000C
 0008	     12B0	CALL #0
 000A	     0000
 000C	     9381	CMP #0,0(SP)
 000E	     0000
 0010	     2403	JEQ $+8, goes to  0018
 0012	     9381	CMP #0,2(SP)
 0014	     0002
 0016	     2002	JNE $+6, goes to  001C
 0018	     12B0	CALL #11
 001A	     000B
 001C	     9381	CMP #0,0(SP)
 001E	     0000
 0020	     2005	JNE $+12, goes to  002C
 0022	     9381	CMP #0,2(SP)
 0024	     0002
 0026	     2002	JNE $+6, goes to  002C
 0028	     12B0	CALL #27
 002A	     001B
 002C	     9381	CMP #0,0(SP)
 002E	     0000
 0030	     2403	JEQ $+8, goes to  0038
 0032	     9381	CMP #0,2(SP)
 0034	     0002
 0036	     2008	JNE $+18, goes to  0048
 0038	     9391	CMP #1,0(SP)
 003A	     0000
 003C	     2003	JNE $+8, goes to  0044
 003E	     9391	CMP #1,2(SP)
 0040	     0002
 0042	     2402	JEQ $+6, goes to  0048
 0044	     12B0	CALL #43
 0046	     002B
 0048	     5221	ADD #4,SP
 004A	     4130	RET
fixups:
 0047	s1.3

section     1	c    6	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4130	RET
fixups:
 0003	s0.0

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1
