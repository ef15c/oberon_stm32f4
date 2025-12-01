MODULE testSFuncs2;
  TYPE rec* = RECORD a, b*: INTEGER END;

  VAR t: ARRAY 10 OF INTEGER;
    v1*: INTEGER; r*: rec;

  PROCEDURE p*(t: ARRAY OF INTEGER; s: ARRAY OF CHAR);
    VAR v: INTEGER;
      u: ARRAY 5 OF INTEGER;
  BEGIN
    v := LEN(t);
    v := LEN(s);
    v := LEN(u);
    REPEAT UNTIL BIT(v, 3) 
  END p;

  PROCEDURE q*(t: ARRAY OF INTEGER*; s: ARRAY OF CHAR*);
    VAR v: INTEGER*;
      u: ARRAY 5 OF INTEGER;
  BEGIN
    v := LEN(t);
    v := LEN(s);
    v := LEN(u);
    REPEAT UNTIL BIT(v, 3) 
  END q;

BEGIN
  v1 := LEN(t);
  p(t, "bonjour");
  q(t, "bonjour")
END testSFuncs2.


OMSPTool.DecObj testSFuncs2.mpc
decode testSFuncs2.mpc
testSFuncs2 B8A50B53
imports:

section     0	d    8	rec
 04 00 FF FF FF FF FF FF
fixups:

section     1	r   20	t
fixups:

section     2	r    2	v1
fixups:

section     3	r    4	r
fixups:

section     4	c   36	p
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     4191	MOV 20(SP),0(SP)
 0006	     0014
 0008	     0000
 000A	     4191	MOV 16(SP),0(SP)
 000C	     0010
 000E	     0000
 0010	     40B1	MOV #5,0(SP)
 0012	     0005
 0014	     0000
 0016	     B0B1	BIT #3,0(SP)
 0018	     0003
 001A	     0000
 001C	     27FC	JEQ $-6, goes to  0016
 001E	     5031	ADD #12,SP
 0020	     000C
 0022	     4130	RET
fixups:

section     5	c   24	q
 0000	     8031	SUB #10,SP
 0002	     000A
 0004	     4508	MOV R5,R8
 0006	     4708	MOV R7,R8
 0008	     4038	MOV #5,R8
 000A	     0005
 000C	     B038	BIT #3,R8
 000E	     0003
 0010	     27FD	JEQ $-4, goes to  000C
 0012	     5031	ADD #10,SP
 0014	     000A
 0016	     4130	RET
fixups:

section     6	c   48	module body
 0000	     40B2	MOV #0,&0
 0002	     0000
 0004	     0000
 0006	     1230	PUSH #10
 0008	     000A
 000A	     1230	PUSH #0
 000C	     0000
 000E	     1230	PUSH #8
 0010	     0008
 0012	     1230	PUSH #0
 0014	     0000
 0016	     12B0	CALL #0
 0018	     0000
 001A	     5231	ADD #8,SP
 001C	     4034	MOV #13,R4
 001E	     000D
 0020	     4035	MOV #10,R5
 0022	     000A
 0024	     4036	MOV #21,R6
 0026	     0015
 0028	     4237	MOV #8,R7
 002A	     12B0	CALL #0
 002C	     0000
 002E	     4130	RET
fixups:
 002D	s0.5
 0019	s0.4
 0027	s0.7
 001F	s0.1
 0005	s0.2
 0003	s0.10

section     7	s    8	
bonjour|
fixups:

section     8	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    6    0    2    3    4    5
