MODULE testLoadAdr;
  TYPE rec = RECORD
    x, y: INTEGER;
	END;

  VAR r1: rec;

  PROCEDURE p(VAR r: rec);
  BEGIN
    r.x := 1; r.y := 2
  END p;

  PROCEDURE q(VAR r: rec*);
  BEGIN
    r.x := 1; r.y := 2
  END q;

BEGIN
  p(r1); q(r1)
END testLoadAdr.

OMSPP.Compile testLoadAdr.Mod~
OMSPTool.DecObj testLoadAdr.mpc
decode testLoadAdr.mpc
testLoadAdr 0AF6EC0F
imports:

section     0	d    8	rec
 04 00 FF FF FF FF FF FF
fixups:

section     1	r    4	r1
fixups:

section     2	c   18	p
 0000	     411F	MOV 2(SP),R15
 0002	     0002
 0004	     439F	MOV #1,0(R15)
 0006	     0000
 0008	     411F	MOV 2(SP),R15
 000A	     0002
 000C	     43AF	MOV #2,2(R15)
 000E	     0002
 0010	     4130	RET
fixups:

section     3	c   10	q
 0000	     4394	MOV #1,0(R4)
 0002	     0000
 0004	     43A4	MOV #2,2(R4)
 0006	     0002
 0008	     4130	RET
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
