MODULE testRepeat;

  PROCEDURE p*;
    VAR i, j: INTEGER;
  BEGIN
    REPEAT UNTIL FALSE; REPEAT UNTIL TRUE;
    i := 10; REPEAT i := i-1 UNTIL (i = 0) & (i = i);
    i := 10; REPEAT DEC(i) UNTIL (i = 0) OR (i = i)
  END p;
  
END testRepeat.

OMSPTool.DecObj testRepeat.mpc ~
decode testRepeat.mpc
testRepeat 0771591F
imports:

section     0	c   48	p
 0000	     8221	SUB #4,SP
 0002	     3FFF	JMP $, goes to  0002
 0004	     40B1	MOV #10,0(SP)
 0006	     000A
 0008	     0000
 000A	     412F	MOV @SP,R15
 000C	     831F	SUB #1,R15
 000E	     4F81	MOV R15,0(SP)
 0010	     0000
 0012	     23FB	JNE $-8, goes to  000A
 0014	     91A1	CMP @SP,0(SP)
 0016	     0000
 0018	     23F8	JNE $-14, goes to  000A
 001A	     40B1	MOV #10,0(SP)
 001C	     000A
 001E	     0000
 0020	     8391	SUB #1,0(SP)
 0022	     0000
 0024	     2403	JEQ $+8, goes to  002C
 0026	     91A1	CMP @SP,0(SP)
 0028	     0000
 002A	     23FA	JNE $-10, goes to  0020
 002C	     5221	ADD #4,SP
 002E	     4130	RET
fixups:

section     1	c    2	module body
 0000	     4130	RET
fixups:

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1    0
