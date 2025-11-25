MODULE testIntArith;
  IMPORT Arith;

PROCEDURE p;
    VAR a, b, c: INTEGER;
BEGIN
  a := b + c;
  a := b - c;
  a := b * c;
  a := b DIV c;
  a := b MOD c
END p;

BEGIN p
END testIntArith.

OMSPP.Compile testIntArith.Mod~
OMSPTool.DecObj testIntArith.mpc
decode testIntArith.mpc
testIntArith 253A0CC2
imports:
	Arith 1D2566D6

section     0	c   86	p
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     411F	MOV 2(SP),R15
 0006	     0002
 0008	     511F	ADD 4(SP),R15
 000A	     0004
 000C	     4F81	MOV R15,0(SP)
 000E	     0000
 0010	     411F	MOV 2(SP),R15
 0012	     0002
 0014	     811F	SUB 4(SP),R15
 0016	     0004
 0018	     4F81	MOV R15,0(SP)
 001A	     0000
 001C	     4115	MOV 2(SP),R5
 001E	     0002
 0020	     4116	MOV 4(SP),R6
 0022	     0004
 0024	     12B0	CALL #0
 0026	     0000
 0028	     4481	MOV R4,0(SP)
 002A	     0000
 002C	     4115	MOV 2(SP),R5
 002E	     0002
 0030	     4116	MOV 4(SP),R6
 0032	     0004
 0034	     4307	MOV #0,R7
 0036	     12B0	CALL #0
 0038	     0000
 003A	     4481	MOV R4,0(SP)
 003C	     0000
 003E	     4115	MOV 2(SP),R5
 0040	     0002
 0042	     4116	MOV 4(SP),R6
 0044	     0004
 0046	     4317	MOV #1,R7
 0048	     12B0	CALL #57
 004A	     0039
 004C	     4481	MOV R4,0(SP)
 004E	     0000
 0050	     5031	ADD #6,SP
 0052	     0006
 0054	     4130	RET
fixups:
 004B	s1.2
 0027	s1.1

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
