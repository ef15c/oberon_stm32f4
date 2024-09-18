MODULE testRepeat;

  PROCEDURE p;
    VAR i, j: INTEGER;
  BEGIN
    REPEAT UNTIL FALSE; REPEAT UNTIL TRUE;
    i := 10; REPEAT i := i-1 UNTIL (i = 0) & (i = i);
    i := 10; REPEAT DEC(i) UNTIL (i = 0) OR (i = i)
  END p;
  
END testRepeat.

OMSPTool.DecObj testRepeat.mpc ~
decode testRepeat.mpc
testRepeat 34BBBDE1 Flash    58
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0038
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0038
code    58
 0000	     8221	SUB #4,SP
 0002	     3FFF	JMP $, goes to  0002
 0004	     40B1	MOV #10,0(SP)
 0006	     000A
 0008	     0000
 000A	     412F	MOV @SP,R15
 000C	     831F	SUB #1,R15
 000E	     4F81	MOV R15,0(SP)
 0010	     0000
 0012	     9381	CMP #0,0(SP)
 0014	     0000
 0016	     23F9	JNE $-12, goes to  000A
 0018	     91A1	CMP @SP,0(SP)
 001A	     0000
 001C	     23F6	JNE $-18, goes to  000A
 001E	     40B1	MOV #10,0(SP)
 0020	     000A
 0022	     0000
 0024	     8391	SUB #1,0(SP)
 0026	     0000
 0028	     9381	CMP #0,0(SP)
 002A	     0000
 002C	     2403	JEQ $+8, goes to  0034
 002E	     91A1	CMP @SP,0(SP)
 0030	     0000
 0032	     23F8	JNE $-14, goes to  0024
 0034	     5221	ADD #4,SP
 0036	     4130	RET
 0038	     4130	RET
