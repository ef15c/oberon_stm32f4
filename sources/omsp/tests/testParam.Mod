MODULE testParam;
  IMPORT Traps;

  TYPE ti = ARRAY 10 OF INTEGER;

  VAR t0: ti; u0: ARRAY 10 OF INTEGER;

  PROCEDURE p(i: INTEGER; VAR s: ARRAY OF INTEGER);
  BEGIN
    i := i+10; s[i] := 1
  END p;
  
  PROCEDURE r(i: INTEGER*; VAR s: ARRAY OF INTEGER*);
  BEGIN
    i := i+10; s[i] := 1
  END r;
  
  PROCEDURE q(VAR t: ti; VAR u: ARRAY OF INTEGER);
  BEGIN
    p(1, t); p(1, u);
    r(1, t); r(1, u);
  END q;

BEGIN q(t0, u0)
END testParam.


OMSPTool.DecObj testParam.mpc 
decode testParam.mpc
testParam 8614713B Flash   156
imports:
	Traps 37B3757C
type descriptors

data    40
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0086
fixup procedures chains
 0062     0	 0000
 0082     0	 0028
 0094     0	 0044
 0036     1	 0001
fixup handlers chains
fixup data chains
 0088     0	 0000
 0090     0	 0014
fixup constants chains
fixup types chains
entry =  0086
code   156
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
 0028	     4407	MOV R4,R7
 002A	     5037	ADD #10,R7
 002C	     000A
 002E	     4704	MOV R7,R4
 0030	     9604	CMP R6,R4
 0032	     2802	JNC #2, goes to  0038
 0034	     12B0	CALL #22
 0036	     0016
 0038	     4407	MOV R4,R7
 003A	     5707	ADD R7,R7
 003C	     5507	ADD R5,R7
 003E	     4397	MOV #1,0(R7)
 0040	     0000
 0042	     4130	RET
 0044	     1213	PUSH #1
 0046	     1230	PUSH #10
 0048	     000A
 004A	     1211	PUSH 12(SP)
 004C	     000C
 004E	     12B0	CALL #0
 0050	     0000
 0052	     5031	ADD #6,SP
 0054	     0006
 0056	     1213	PUSH #1
 0058	     1211	PUSH 8(SP)
 005A	     0008
 005C	     1211	PUSH 8(SP)
 005E	     0008
 0060	     12B0	CALL #80
 0062	     0050
 0064	     5031	ADD #6,SP
 0066	     0006
 0068	     4314	MOV #1,R4
 006A	     4115	MOV 6(SP),R5
 006C	     0006
 006E	     4036	MOV #10,R6
 0070	     000A
 0072	     12B0	CALL #0
 0074	     0000
 0076	     4314	MOV #1,R4
 0078	     4115	MOV 2(SP),R5
 007A	     0002
 007C	     4116	MOV 4(SP),R6
 007E	     0004
 0080	     12B0	CALL #116
 0082	     0074
 0084	     4130	RET
 0086	     1230	PUSH #0
 0088	     0000
 008A	     1230	PUSH #10
 008C	     000A
 008E	     1230	PUSH #0
 0090	     0000
 0092	     12B0	CALL #0
 0094	     0000
 0096	     5031	ADD #6,SP
 0098	     0006
 009A	     4130	RET
