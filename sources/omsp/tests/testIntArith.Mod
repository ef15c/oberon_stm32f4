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

END testIntArith.


OMSPTool.DecObj testIntArith.mpc
decode testIntArith.mpc
testIntArith 57D15311 Flash    88
imports:
	Arith BDF2CFB8
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0056
fixup procedures chains
 004A     1	 0002
 0026     1	 0001
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0056
code    88
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
 0048	     12B0	CALL #56
 004A	     0038
 004C	     4481	MOV R4,0(SP)
 004E	     0000
 0050	     5031	ADD #6,SP
 0052	     0006
 0054	     4130	RET
 0056	     4130	RET
