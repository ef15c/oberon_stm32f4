MODULE testParam;
  IMPORT Traps;

  TYPE ti = ARRAY 10 OF INTEGER;

  VAR t0: ti; u0: ARRAY 10 OF INTEGER;

  PROCEDURE p(i: INTEGER; VAR s: ARRAY OF INTEGER);
  BEGIN
    i := i+10; s[i] := 1
  END p;
  
  PROCEDURE q(VAR t: ti; VAR u: ARRAY OF INTEGER);
  BEGIN
    p(1, t);
    p(1, u);
  END q;

BEGIN q(t0, u0)
END testParam.


OMSPTool.DecObj testParam.mpc 

not leaf:
decode testParam.mpc
testParam D5E6C731   146
imports:
	Traps 45642D7E
type descriptors

data    40
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 004E
fixup procedures chains
 0046     0	 0000
 005C     0	 0028
 0016     1	 0001
fixup handlers chains
fixup data chains
 0050     0	 0000
 0058     0	 0014
fixup type chains
entry =  004E
code   100
 0000	     411F	MOV 6(SP),R15
 0002	     0006
 0004	     503F	ADD #10,R15
 0006	     000A
 0008	     4F81	MOV R15,6(SP)
 000A	     0006
 000C	     9191	CMP 4(SP),6(SP)
 000E	     0004
 0010	     0006
 0012	     2802	JNC #2, goes to  0018
 0014	     12B0	CALL #0
 0016	     0000
 0018	     411F	MOV 6(SP),R15
 001A	     0006
 001C	     5F0F	ADD R15,R15
 001E	     511F	ADD 2(SP),R15
 0020	     0002
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
 004E	     1230	PUSH #0
 0050	     0000
 0052	     1230	PUSH #10
 0054	     000A
 0056	     1230	PUSH #0
 0058	     0000
 005A	     12B0	CALL #0
 005C	     0000
 005E	     5031	ADD #6,SP
 0060	     0006
 0062	     4130	RET

leaf:
decode testParam.mpc
testParam D5E6C731   126
imports:
	Traps 45642D7E
type descriptors

data    40
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 003A
fixup procedures chains
 0036     0	 0000
 0048     0	 001C
 000E     1	 0001
fixup handlers chains
fixup data chains
 003C     0	 0000
 0044     0	 0014
fixup type chains
entry =  003A
code    80
 0000	     4407	MOV R4,R7
 0002	     5037	ADD #10,R7
 0004	     000A
 0006	     4704	MOV R7,R4
 0008	     9604	CMP R6,R4
 000A	     2802	JNC #2, goes to  0010
 000C	     12B0	CALL #0
 000E	     0000
 0010	     4407	MOV R4,R7
 0012	     5707	ADD R7,R7
 0014	     5507	ADD R5,R7
 0016	     4397	MOV #1,0(R7)
 0018	     0000
 001A	     4130	RET
 001C	     4314	MOV #1,R4
 001E	     4115	MOV 6(SP),R5
 0020	     0006
 0022	     4036	MOV #10,R6
 0024	     000A
 0026	     12B0	CALL #0
 0028	     0000
 002A	     4314	MOV #1,R4
 002C	     4115	MOV 2(SP),R5
 002E	     0002
 0030	     4116	MOV 4(SP),R6
 0032	     0004
 0034	     12B0	CALL #40
 0036	     0028
 0038	     4130	RET
 003A	     1230	PUSH #0
 003C	     0000
 003E	     1230	PUSH #10
 0040	     000A
 0042	     1230	PUSH #0
 0044	     0000
 0046	     12B0	CALL #0
 0048	     0000
 004A	     5031	ADD #6,SP
 004C	     0006
 004E	     4130	RET
