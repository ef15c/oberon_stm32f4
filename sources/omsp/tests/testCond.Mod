MODULE testCond;

  PROCEDURE p(v: INTEGER);
    VAR b: BOOLEAN*;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END p;

  PROCEDURE q(v: INTEGER*);
    VAR b: BOOLEAN*;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END q;

  PROCEDURE r(v: INTEGER*);
    VAR b: BOOLEAN;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END r;

  PROCEDURE s(v: INTEGER);
    VAR b: BOOLEAN;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END s;

BEGIN p(40); q(40); r(40); s(40)
END testCond.

OMSPP.Compile testCond.Mod~
OMSPTool.DecObj testCond.mpc
decode testCond.mpc
testCond FC136230
imports:

section     0	c   42	p
 0000	     4335	MOV #-1,R5
 0002	     9115	CMP 2(SP),R5
 0004	     0002
 0006	     3403	JGE $+8, goes to  000E
 0008	     9391	CMP #1,2(SP)
 000A	     0002
 000C	     3809	JL $+20, goes to  0020
 000E	     4035	MOV #9,R5
 0010	     0009
 0012	     9115	CMP 2(SP),R5
 0014	     0002
 0016	     3406	JGE $+14, goes to  0024
 0018	     90B1	CMP #11,2(SP)
 001A	     000B
 001C	     0002
 001E	     3402	JGE $+6, goes to  0024
 0020	     4315	MOV #1,R5
 0022	     3C01	JMP $+4, goes to  0026
 0024	     4305	MOV #0,R5
 0026	     4544	MOV.B R5,R4
 0028	     4130	RET
fixups:

section     1	c   34	q
 0000	     4336	MOV #-1,R6
 0002	     9406	CMP R4,R6
 0004	     3402	JGE $+6, goes to  000A
 0006	     9314	CMP #1,R4
 0008	     3807	JL $+16, goes to  0018
 000A	     4036	MOV #9,R6
 000C	     0009
 000E	     9406	CMP R4,R6
 0010	     3405	JGE $+12, goes to  001C
 0012	     9034	CMP #11,R4
 0014	     000B
 0016	     3402	JGE $+6, goes to  001C
 0018	     4316	MOV #1,R6
 001A	     3C01	JMP $+4, goes to  001E
 001C	     4306	MOV #0,R6
 001E	     4645	MOV.B R6,R5
 0020	     4130	RET
fixups:

section     2	c   40	r
 0000	     8321	SUB #2,SP
 0002	     4335	MOV #-1,R5
 0004	     9405	CMP R4,R5
 0006	     3402	JGE $+6, goes to  000C
 0008	     9314	CMP #1,R4
 000A	     3807	JL $+16, goes to  001A
 000C	     4035	MOV #9,R5
 000E	     0009
 0010	     9405	CMP R4,R5
 0012	     3405	JGE $+12, goes to  001E
 0014	     9034	CMP #11,R4
 0016	     000B
 0018	     3402	JGE $+6, goes to  001E
 001A	     4315	MOV #1,R5
 001C	     3C01	JMP $+4, goes to  0020
 001E	     4305	MOV #0,R5
 0020	     45C1	MOV.B R5,0(SP)
 0022	     0000
 0024	     5321	ADD #2,SP
 0026	     4130	RET
fixups:

section     3	c   48	s
 0000	     8321	SUB #2,SP
 0002	     433F	MOV #-1,R15
 0004	     911F	CMP 4(SP),R15
 0006	     0004
 0008	     3403	JGE $+8, goes to  0010
 000A	     9391	CMP #1,4(SP)
 000C	     0004
 000E	     3809	JL $+20, goes to  0022
 0010	     403F	MOV #9,R15
 0012	     0009
 0014	     911F	CMP 4(SP),R15
 0016	     0004
 0018	     3406	JGE $+14, goes to  0026
 001A	     90B1	CMP #11,4(SP)
 001C	     000B
 001E	     0004
 0020	     3402	JGE $+6, goes to  0026
 0022	     431F	MOV #1,R15
 0024	     3C01	JMP $+4, goes to  0028
 0026	     430F	MOV #0,R15
 0028	     4FC1	MOV.B R15,0(SP)
 002A	     0000
 002C	     5321	ADD #2,SP
 002E	     4130	RET
fixups:

section     4	c   38	module body
 0000	     1230	PUSH #40
 0002	     0028
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     4034	MOV #40,R4
 000C	     0028
 000E	     12B0	CALL #0
 0010	     0000
 0012	     4034	MOV #40,R4
 0014	     0028
 0016	     12B0	CALL #0
 0018	     0000
 001A	     1230	PUSH #40
 001C	     0028
 001E	     12B0	CALL #0
 0020	     0000
 0022	     5321	ADD #2,SP
 0024	     4130	RET
fixups:
 0021	s0.3
 0019	s0.2
 0011	s0.1
 0007	s0.0

section     5	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    4
