MODULE testParam;
  IMPORT Traps;

  TYPE ti = ARRAY 10 OF INTEGER;

  PROCEDURE p(i: INTEGER*; VAR s: ARRAY OF INTEGER*);
  BEGIN
    i := i+10; s[i] := 1
  END p;
  
  PROCEDURE q(VAR t: ti; VAR u: ARRAY OF INTEGER);
  BEGIN
    p(1, t);
    p(1, u);
  END q;

END testParam.


OMSPTool.DecObj testParam.mpc 

not leaf:
decode testParam.mpc
testParam D5E6C731    86
imports:
	Traps 45642D7E
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 004E
fixup procedures chains
 0046     0	 0000
 0018     1	 0001
fixup handlers chains
fixup data chains
fixup type chains
entry =  004E
code    80
 0000	     411F	MOV 6(SP),R15
 0002	     0006
 0004	     503F	ADD #10,R15
 0006	     000A
 0008	     4F81	MOV R15,6(SP)
 000A	     0006
 000C	     411F	MOV 6(SP),R15
 000E	     0006
 0010	     911F	CMP 4(SP),R15
 0012	     0004
 0014	     2802	JNC #2, goes to  001A
 0016	     12B0	CALL #0
 0018	     0000
 001A	     5F0F	ADD R15,R15
 001C	     411E	MOV 2(SP),R14
 001E	     0002
 0020	     5E0F	ADD R14,R15
 0022	     439F	MOV #1,0(R15)
 0024	     0000
 0026	     4130	RET
 0028	     1213	PUSH #1
 002A	     1230	PUSH #10
 002C	     000A
 002E	     1211	PUSH 6(SP)
 0030	     0006
 0032	     12B0	CALL #0
 0034	     0000
 0036	     5031	ADD #6,SP
 0038	     0006
 003A	     1213	PUSH #1
 003C	     1211	PUSH 4(SP)
 003E	     0004
 0040	     1211	PUSH 2(SP)
 0042	     0002
 0044	     12B0	CALL #52
 0046	     0034
 0048	     5031	ADD #6,SP
 004A	     0006
 004C	     4130	RET
 004E	     4130	RET

leaf:
decode testParam.mpc
testParam D5E6C731    68
imports:
	Traps 45642D7E
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 003C
fixup procedures chains
 0038     0	 0000
 0010     1	 0001
fixup handlers chains
fixup data chains
fixup type chains
entry =  003C
code    62
 0000	     4407	MOV R4,R7
 0002	     5037	ADD #10,R7
 0004	     000A
 0006	     4704	MOV R7,R4
 0008	     4407	MOV R4,R7
 000A	     9607	CMP R6,R7
 000C	     2802	JNC #2, goes to  0012
 000E	     12B0	CALL #0
 0010	     0000
 0012	     5707	ADD R7,R7
 0014	     4528	MOV @R5,R8
 0016	     5708	ADD R7,R8
 0018	     4398	MOV #1,0(R8)
 001A	     0000
 001C	     4130	RET
 001E	     4314	MOV #1,R4
 0020	     4115	MOV 6(SP),R5
 0022	     0006
 0024	     4036	MOV #10,R6
 0026	     000A
 0028	     12B0	CALL #0
 002A	     0000
 002C	     4314	MOV #1,R4
 002E	     4115	MOV 2(SP),R5
 0030	     0002
 0032	     4116	MOV 4(SP),R6
 0034	     0004
 0036	     12B0	CALL #42
 0038	     002A
 003A	     4130	RET
 003C	     4130	RET
