MODULE testRecStr;

  TYPE rec = RECORD a: INTEGER END;

  VAR s: ARRAY 10 OF CHAR; r*: rec;

BEGIN s := "bonjour"
END testRecStr.

OMSPTool.DecObj testRecStr.mpc
decode testRecStr.mpc
testRecStr 8C4D3A7B
imports:

section     0	d    8	rec
 02 00 FF FF FF FF FF FF
fixups:

section     1	r   10	s
fixups:

section     2	r    2	r
fixups:

section     3	c   22	module body
 0000	     403F	MOV #0,R15
 0002	     0000
 0004	     403E	MOV #0,R14
 0006	     0000
 0008	     4EBF	MOV @R14+,0(R15)
 000A	     0000
 000C	     532F	ADD #2,R15
 000E	     93CE	CMP.B #0,-1(R14)
 0010	     FFFF
 0012	     23FA	JNE $-10, goes to  0008
 0014	     4130	RET
fixups:
 0007	s0.4
 0003	s0.1

section     4	s    8	
bonjour|
fixups:

section     5	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    3    2
