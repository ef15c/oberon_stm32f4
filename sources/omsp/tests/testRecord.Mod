MODULE testRecord;

  TYPE rec = RECORD
    a, b: INTEGER;
    c, d: ARRAY 2000 OF INTEGER;
    e: INTEGER
  END;

  VAR r: rec;

  PROCEDURE p(VAR r: rec);
  BEGIN
    r.a := 1;
    r.b := 2;
    r.c := r.d;
    r.e := 3
  END p;

  PROCEDURE q(VAR r: rec*);
  BEGIN
    r.a := 1;
    r.b := 2;
    r.c := r.d;
    r.e := 3
  END q;

BEGIN p(r); q(r)
END testRecord.

OMSPP.Compile testRecord.Mod~
OMSPTool.DecObj testRecord.mpc
decode testRecord.mpc
testRecord AA343CF7
imports:

section     0	d    8	rec
 46 1F FF FF FF FF FF FF
fixups:

section     1	r 8006	r
fixups:

section     2	c   48	p
 0000	     411F	MOV 2(SP),R15
 0002	     0002
 0004	     439F	MOV #1,0(R15)
 0006	     0000
 0008	     411F	MOV 2(SP),R15
 000A	     0002
 000C	     43AF	MOV #2,2(R15)
 000E	     0002
 0010	     411F	MOV 2(SP),R15
 0012	     0002
 0014	     503F	ADD #4004,R15
 0016	     0FA4
 0018	     403E	MOV #2000,R14
 001A	     07D0
 001C	     4FBF	MOV @R15+,-4002(R15)
 001E	     F05E
 0020	     831E	SUB #1,R14
 0022	     23FC	JNE $-6, goes to  001C
 0024	     411F	MOV 2(SP),R15
 0026	     0002
 0028	     40BF	MOV #3,8004(R15)
 002A	     0003
 002C	     1F44
 002E	     4130	RET
fixups:

section     3	c   34	q
 0000	     4394	MOV #1,0(R4)
 0002	     0000
 0004	     43A4	MOV #2,2(R4)
 0006	     0002
 0008	     4406	MOV R4,R6
 000A	     5036	ADD #4004,R6
 000C	     0FA4
 000E	     4037	MOV #2000,R7
 0010	     07D0
 0012	     46B6	MOV @R6+,-4002(R6)
 0014	     F05E
 0016	     8317	SUB #1,R7
 0018	     23FC	JNE $-6, goes to  0012
 001A	     40B4	MOV #3,8004(R4)
 001C	     0003
 001E	     1F44
 0020	     4130	RET
fixups:

section     4	c   28	module body
 0000	     1230	PUSH #0
 0002	     0000
 0004	     1230	PUSH #0
 0006	     0000
 0008	     12B0	CALL #0
 000A	     0000
 000C	     5221	ADD #4,SP
 000E	     4034	MOV #7,R4
 0010	     0007
 0012	     4035	MOV #3,R5
 0014	     0003
 0016	     12B0	CALL #0
 0018	     0000
 001A	     4130	RET
fixups:
 0019	s0.3
 000B	s0.2
 0011	s0.1
 0015	s0.0

section     5	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    4
