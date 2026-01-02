MODULE testTypTag;
  TYPE tr = RECORD a: INTEGER; END;
    tr1 = RECORD(tr) b: BYTE END;
    tpr = POINTER TO tr;
    tpr1 = POINTER TO tr1;
    
PROCEDURE p(VAR v: tr);
    VAR b: BYTE;
BEGIN b := v(tr1).b;
  CASE v OF
    tr1: b := v.b
  | tr: b := v.a
  END
END p;

PROCEDURE p2(v: tpr);
    VAR b: BYTE;
BEGIN b := v(tpr1).b
END p2;

PROCEDURE q;
  VAR r: tr1;
    pr!: tpr1;
  
BEGIN p(r); p2(pr);
  r.b := 1
END q;

BEGIN q
END testTypTag.

OMSPP.Compile testTypTag.Mod ~
OMSPL.Link 32 4000H 200H testTypTag ~
  linking testTypTag
    flash  142, data    0, stack  512 bytes

OMSPTool.DecObj testTypTag.mpc
decode testTypTag.mpc
testTypTag 88478888
imports:

section     0	d    8	tr
 02 00 FF FF FF FF FF FF
fixups:

section     1	d    8	tr1
 04 00 00 00 FF FF FF FF
fixups:
 0003	s0.0

section     2	c   50	p
 0000	     8321	SUB #2,SP
 0002	     411F	MOV 4(SP),R15
 0004	     0004
 0006	     4FD1	MOV.B 2(R15),0(SP)
 0008	     0002
 000A	     0000
 000C	     411F	MOV 6(SP),R15
 000E	     0006
 0010	     4F1F	MOV 2(R15),R15
 0012	     0002
 0014	     903F	CMP #0,R15
 0016	     0000
 0018	     2006	JNE $+14, goes to  0026
 001A	     411F	MOV 4(SP),R15
 001C	     0004
 001E	     4FD1	MOV.B 2(R15),0(SP)
 0020	     0002
 0022	     0000
 0024	     3C04	JMP $+10, goes to  002E
 0026	     411F	MOV 4(SP),R15
 0028	     0004
 002A	     4FE1	MOV.B @R15,0(SP)
 002C	     0000
 002E	     5321	ADD #2,SP
 0030	     4130	RET
fixups:
 0017	s0.1

section     3	c   16	p2
 0000	     8321	SUB #2,SP
 0002	     411F	MOV 4(SP),R15
 0004	     0004
 0006	     4FD1	MOV.B 2(R15),0(SP)
 0008	     0002
 000A	     0000
 000C	     5321	ADD #2,SP
 000E	     4130	RET
fixups:

section     4	c   40	q
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     1230	PUSH #0
 0006	     0000
 0008	     410F	MOV SP,R15
 000A	     532F	ADD #2,R15
 000C	     120F	PUSH R15
 000E	     12B0	CALL #0
 0010	     0000
 0012	     5221	ADD #4,SP
 0014	     1211	PUSH 6(SP)
 0016	     0006
 0018	     12B0	CALL #0
 001A	     0000
 001C	     5321	ADD #2,SP
 001E	     43D1	MOV.B #1,2(SP)
 0020	     0002
 0022	     5031	ADD #6,SP
 0024	     0006
 0026	     4130	RET
fixups:
 001B	s0.3
 0011	s0.2
 0007	s0.1

section     5	c    6	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     4130	RET
fixups:
 0003	s0.4

section     6	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    5
