MODULE testInEx;
  PROCEDURE p;
    VAR s: SET;
      p: INTEGER;
  BEGIN
    INCL(s, 3); INCL(s, p);
    EXCL(s, 5); EXCL(s, p);
  END p;
  
  PROCEDURE q;
    VAR s: SET*;
      p: INTEGER*;
  BEGIN
    INCL(s, 3); INCL(s, p);
    EXCL(s, 5); EXCL(s, p);
  END q;

BEGIN p; q
END testInEx.

OMSPP.Compile testInEx.Mod~
OMSPTool.DecObj testInEx.mpc
decode testInEx.mpc
testInEx 4D3E82C4
imports:

section     0	c   56	p
 0000	     8221	SUB #4,SP
 0002	     D2B1	BIS #8,0(SP)
 0004	     0000
 0006	     431F	MOV #1,R15
 0008	     411E	MOV 2(SP),R14
 000A	     0002
 000C	     531E	ADD #1,R14
 000E	     831E	SUB #1,R14
 0010	     2402	JEQ $+6, goes to  0016
 0012	     5F0F	ADD R15,R15
 0014	     3FFC	JMP $-6, goes to  000E
 0016	     DF81	BIS R15,0(SP)
 0018	     0000
 001A	     C0B1	BIC #32,0(SP)
 001C	     0020
 001E	     0000
 0020	     431F	MOV #1,R15
 0022	     411E	MOV 2(SP),R14
 0024	     0002
 0026	     531E	ADD #1,R14
 0028	     831E	SUB #1,R14
 002A	     2402	JEQ $+6, goes to  0030
 002C	     5F0F	ADD R15,R15
 002E	     3FFC	JMP $-6, goes to  0028
 0030	     CF81	BIC R15,0(SP)
 0032	     0000
 0034	     5221	ADD #4,SP
 0036	     4130	RET
fixups:

section     1	c   40	q
 0000	     D234	BIS #8,R4
 0002	     4316	MOV #1,R6
 0004	     4507	MOV R5,R7
 0006	     5317	ADD #1,R7
 0008	     8317	SUB #1,R7
 000A	     2402	JEQ $+6, goes to  0010
 000C	     5606	ADD R6,R6
 000E	     3FFC	JMP $-6, goes to  0008
 0010	     D604	BIS R6,R4
 0012	     C034	BIC #32,R4
 0014	     0020
 0016	     4316	MOV #1,R6
 0018	     4507	MOV R5,R7
 001A	     5317	ADD #1,R7
 001C	     8317	SUB #1,R7
 001E	     2402	JEQ $+6, goes to  0024
 0020	     5606	ADD R6,R6
 0022	     3FFC	JMP $-6, goes to  001C
 0024	     C604	BIC R6,R4
 0026	     4130	RET
fixups:

section     2	c   10	module body
 0000	     12B0	CALL #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     4130	RET
fixups:
 0007	s0.1
 0003	s0.0

section     3	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    2
