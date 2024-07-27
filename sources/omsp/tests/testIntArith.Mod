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
testIntArith 1E5C3E2F    84
imports:
	Arith 82E1081E
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 004C
fixup procedures chains
 0040     1	 0002
 0020     1	 0001
fixup handlers chains
fixup data chains
fixup type chains
entry =  004C
code    78
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     411F	MOV 2(SP),R15
 0006	     0002
 0008	     512F	ADD @SP,R15
 000A	     4F81	MOV R15,4(SP)
 000C	     0004
 000E	     411F	MOV 2(SP),R15
 0010	     0002
 0012	     812F	SUB @SP,R15
 0014	     4F81	MOV R15,4(SP)
 0016	     0004
 0018	     4115	MOV 2(SP),R5
 001A	     0002
 001C	     4126	MOV @SP,R6
 001E	     12B0	CALL #0
 0020	     0000
 0022	     4481	MOV R4,4(SP)
 0024	     0004
 0026	     4115	MOV 2(SP),R5
 0028	     0002
 002A	     4126	MOV @SP,R6
 002C	     4307	MOV #0,R7
 002E	     12B0	CALL #0
 0030	     0000
 0032	     4481	MOV R4,4(SP)
 0034	     0004
 0036	     4115	MOV 2(SP),R5
 0038	     0002
 003A	     4126	MOV @SP,R6
 003C	     4317	MOV #1,R7
 003E	     12B0	CALL #48
 0040	     0030
 0042	     4481	MOV R4,4(SP)
 0044	     0004
 0046	     5031	ADD #6,SP
 0048	     0006
 004A	     4130	RET
 004C	     4130	RET
