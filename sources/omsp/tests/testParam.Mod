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

OMSPP.Compile testParam.Mod/s~
OMSPTool.DecObj testParam.mpc 
decode testParam.mpc
testParam 847D84B2
imports:
	Traps 3714F611

section     0	r   20	t0
fixups:

section     1	r   20	u0
fixups:

section     2	c   40	p
 0000	     411F	MOV 6(SP),R15
 0002	     0006
 0004	     503F	ADD #10,R15
 0006	     000A
 0008	     4F81	MOV R15,6(SP)
 000A	     0006
 000C	     9191	CMP 4(SP),6(SP)
 000E	     0004
 0010	     0006
 0012	     2802	JNC $+6, goes to  0018
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
fixups:
 0017	s1.1

section     3	c   28	r
 0000	     4407	MOV R4,R7
 0002	     5037	ADD #10,R7
 0004	     000A
 0006	     4704	MOV R7,R4
 0008	     9604	CMP R6,R4
 000A	     2802	JNC $+6, goes to  0010
 000C	     12B0	CALL #0
 000E	     0000
 0010	     4407	MOV R4,R7
 0012	     5707	ADD R7,R7
 0014	     5507	ADD R5,R7
 0016	     4397	MOV #1,0(R7)
 0018	     0000
 001A	     4130	RET
fixups:
 000F	s1.1

section     4	c   66	q
 0000	     1213	PUSH #1
 0002	     1230	PUSH #10
 0004	     000A
 0006	     1211	PUSH 12(SP)
 0008	     000C
 000A	     12B0	CALL #0
 000C	     0000
 000E	     5031	ADD #6,SP
 0010	     0006
 0012	     1213	PUSH #1
 0014	     1211	PUSH 8(SP)
 0016	     0008
 0018	     1211	PUSH 8(SP)
 001A	     0008
 001C	     12B0	CALL #13
 001E	     000D
 0020	     5031	ADD #6,SP
 0022	     0006
 0024	     4314	MOV #1,R4
 0026	     4115	MOV 6(SP),R5
 0028	     0006
 002A	     4036	MOV #10,R6
 002C	     000A
 002E	     12B0	CALL #0
 0030	     0000
 0032	     4314	MOV #1,R4
 0034	     4115	MOV 2(SP),R5
 0036	     0002
 0038	     4116	MOV 4(SP),R6
 003A	     0004
 003C	     12B0	CALL #49
 003E	     0031
 0040	     4130	RET
fixups:
 003F	s0.3
 001F	s0.2

section     5	c   22	module body
 0000	     1230	PUSH #0
 0002	     0000
 0004	     1230	PUSH #10
 0006	     000A
 0008	     1230	PUSH #0
 000A	     0000
 000C	     12B0	CALL #0
 000E	     0000
 0010	     5031	ADD #6,SP
 0012	     0006
 0014	     4130	RET
fixups:
 000F	s0.4
 000B	s0.1
 0003	s0.0

section     6	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    5
