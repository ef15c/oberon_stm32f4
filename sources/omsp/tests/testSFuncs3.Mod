MODULE testSFuncs3;
  IMPORT SYSTEM, TF := testSFuncs2;

  TYPE rt = RECORD
      a, b, c: INTEGER
    END;
    prt = POINTER TO rt;
    at = ARRAY 3 OF INTEGER;

  VAR g: rt;

  PROCEDURE p(VAR x: INTEGER; y: rt; VAR py: prt; z: INTEGER);
    VAR v: INTEGER; s: SET;
      b: BOOLEAN;
      r: rt; pr!: prt;
      a: at;
  BEGIN
    v := SYSTEM.ADR("bonjour");
    v := SYSTEM.ADR(x);
    v := SYSTEM.ADR(y);
    v := SYSTEM.ADR(py);
    v := SYSTEM.ADR(z);
    v := SYSTEM.ADR(TF.r.b);
    v := SYSTEM.ADR(TF.v1);
    v := SYSTEM.ADR(TF.p);
    v := SYSTEM.ADR(p);
    v := SYSTEM.ADR(g);
    v := SYSTEM.ADR(r);
    v := SYSTEM.ADR(a);
    REPEAT DEC(v) UNTIL SYSTEM.COND(1);
    REPEAT INC(v) UNTIL SYSTEM.CMP(v, 0, 1);
    v := SYSTEM.SIZE(rt);
    pr := SYSTEM.VAL(prt, 100);
    s := SYSTEM.VAL(SET, v);
  END p;

  PROCEDURE q*(VAR x: INTEGER*; y: rt*; VAR py: prt*);
    VAR v: INTEGER*; s: SET*;
      b: BOOLEAN;
      r: rt; pr!: prt;
      a: at;
  BEGIN
    v := SYSTEM.ADR("bonjour");
    v := SYSTEM.ADR(x);
    v := SYSTEM.ADR(y);
    v := SYSTEM.ADR(py);
    v := SYSTEM.ADR(TF.r.b);
    v := SYSTEM.ADR(TF.v1);
    v := SYSTEM.ADR(TF.p);
    v := SYSTEM.ADR(p);
    v := SYSTEM.ADR(g);
    v := SYSTEM.ADR(r);
    v := SYSTEM.ADR(a);
    REPEAT DEC(v) UNTIL SYSTEM.COND(1);
    REPEAT INC(v) UNTIL SYSTEM.CMP(v, 0, 1);
    v := SYSTEM.SIZE(rt);
    pr := SYSTEM.VAL(prt, 100);
    s := SYSTEM.VAL(SET, v);
  END q;

END testSFuncs3.


OMSPTool.DecObj testSFuncs3.mpc
decode testSFuncs3.mpc
testSFuncs3 8E127D7E
imports:
	testSFuncs2 B8A50B53

section     0	d    8	rt
 06 00 FF FF FF FF FF FF
fixups:

section     1	r    6	g
fixups:

section     2	c  126	p
 0000	     8031	SUB #20,SP
 0002	     0014
 0004	     40B1	MOV #0,0(SP)
 0006	     0000
 0008	     0000
 000A	     4191	MOV 30(SP),0(SP)
 000C	     001E
 000E	     0000
 0010	     4191	MOV 26(SP),0(SP)
 0012	     001A
 0014	     0000
 0016	     4191	MOV 24(SP),0(SP)
 0018	     0018
 001A	     0000
 001C	     410F	MOV SP,R15
 001E	     503F	ADD #22,R15
 0020	     0016
 0022	     4F81	MOV R15,0(SP)
 0024	     0000
 0026	     40B1	MOV #0,0(SP)
 0028	     0000
 002A	     0000
 002C	     40B1	MOV #0,0(SP)
 002E	     0000
 0030	     0000
 0032	     40B1	MOV #0,0(SP)
 0034	     0000
 0036	     0000
 0038	     40B1	MOV #0,0(SP)
 003A	     0000
 003C	     0000
 003E	     40B1	MOV #0,0(SP)
 0040	     0000
 0042	     0000
 0044	     410F	MOV SP,R15
 0046	     503F	ADD #6,R15
 0048	     0006
 004A	     4F81	MOV R15,0(SP)
 004C	     0000
 004E	     410F	MOV SP,R15
 0050	     503F	ADD #14,R15
 0052	     000E
 0054	     4F81	MOV R15,0(SP)
 0056	     0000
 0058	     8391	SUB #1,0(SP)
 005A	     0000
 005C	     23FD	JNE $-4, goes to  0058
 005E	     5391	ADD #1,0(SP)
 0060	     0000
 0062	     9381	CMP #0,0(SP)
 0064	     0000
 0066	     23FB	JNE $-8, goes to  005E
 0068	     40B1	MOV #6,0(SP)
 006A	     0006
 006C	     0000
 006E	     40B1	MOV #100,12(SP)
 0070	     0064
 0072	     000C
 0074	     41A1	MOV @SP,2(SP)
 0076	     0002
 0078	     5031	ADD #20,SP
 007A	     0014
 007C	     4130	RET
fixups:
 0041	s0.1
 003B	s0.2
 0035	s1.4
 002F	s1.2
 0029	s1.3+2
 0007	s0.3

section     3	s    8	
bonjour|
fixups:

section     4	c   76	q
 0000	     8031	SUB #16,SP
 0002	     0010
 0004	     4038	MOV #0,R8
 0006	     0000
 0008	     4408	MOV R4,R8
 000A	     4508	MOV R5,R8
 000C	     4708	MOV R7,R8
 000E	     4038	MOV #0,R8
 0010	     0000
 0012	     4038	MOV #0,R8
 0014	     0000
 0016	     4038	MOV #0,R8
 0018	     0000
 001A	     4038	MOV #0,R8
 001C	     0000
 001E	     4038	MOV #0,R8
 0020	     0000
 0022	     410A	MOV SP,R10
 0024	     532A	ADD #2,R10
 0026	     4A08	MOV R10,R8
 0028	     410A	MOV SP,R10
 002A	     503A	ADD #10,R10
 002C	     000A
 002E	     4A08	MOV R10,R8
 0030	     8318	SUB #1,R8
 0032	     23FE	JNE $-2, goes to  0030
 0034	     5318	ADD #1,R8
 0036	     9308	CMP #0,R8
 0038	     23FD	JNE $-4, goes to  0034
 003A	     4038	MOV #6,R8
 003C	     0006
 003E	     40B1	MOV #100,8(SP)
 0040	     0064
 0042	     0008
 0044	     4809	MOV R8,R9
 0046	     5031	ADD #16,SP
 0048	     0010
 004A	     4130	RET
fixups:
 0021	s0.1
 001D	s0.2
 0019	s1.4
 0015	s1.2
 0011	s1.3+2
 0007	s0.3

section     5	c    2	module body
 0000	     4130	RET
fixups:

section     6	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    5    4
