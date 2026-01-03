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

section     2	c   18	module body
 0000	     403F	MOV #10,R15
 0002	     000A
 0004	     403E	MOV #0,R14
 0006	     0000
 0008	     4EBE	MOV @R14+,0(R14)
 000A	     0000
 000C	     831F	SUB #1,R15
 000E	     23FC	JNE $-6, goes to  0008
 0010	     4130	RET
fixups:
 000B	s0.1-2-s0.0
 0007	s0.0

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2
