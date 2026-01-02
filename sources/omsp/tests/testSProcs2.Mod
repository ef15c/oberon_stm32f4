MODULE testSProcs2;
  IMPORT SYSTEM;

  VAR a: ARRAY 10 OF INTEGER; b: ARRAY 20 OF CHAR;

BEGIN SYSTEM.COPY(SYSTEM.ADR(a), SYSTEM.ADR(b), 10)
END testSProcs2.

OMSPP.Compile testSProcs2.Mod ~
OMSPL.Link 32 4000H 200H testSProcs2 ~
  linking testSProcs2
    flash   32, data   40, stack  472 bytes

OMSPTool.DecObj testSProcs2.mpc
decode testSProcs2.mpc
testSProcs2 CEF63FBD
imports:

section     0	r   20	a
fixups:

section     1	r   20	b
fixups:

section     2	c   24	module body
 0000	     403F	MOV #10,R15
 0002	     000A
 0004	     403E	MOV #0,R14
 0006	     0000
 0008	     403D	MOV #0,R13
 000A	     0000
 000C	     4EBD	MOV @R14+,0(R13)
 000E	     0000
 0010	     532D	ADD #2,R13
 0012	     831F	SUB #1,R15
 0014	     23FB	JNE $-8, goes to  000C
 0016	     4130	RET
fixups:
 000B	s0.1
 0007	s0.0

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2
