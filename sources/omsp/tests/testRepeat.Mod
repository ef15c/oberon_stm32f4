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
testRepeat DAE43F27 Flash    64
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 003E
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  003E
code    64
 0000	     8221	SUB #4,SP
 0002	     3FFF	JMP #-1, goes to  0002
 0004	     40B1	MOV #10,2(SP)
 0006	     000A
 0008	     0002
 000A	     411F	MOV 2(SP),R15
 000C	     0002
 000E	     831F	SUB #1,R15
 0010	     4F81	MOV R15,2(SP)
 0012	     0002
 0014	     9381	CMP #0,2(SP)
 0016	     0002
 0018	     23F8	JNE #-8, goes to  000A
 001A	     9191	CMP 2(SP),2(SP)
 001C	     0002
 001E	     0002
 0020	     23F4	JNE #-12, goes to  000A
 0022	     40B1	MOV #10,2(SP)
 0024	     000A
 0026	     0002
 0028	     8391	SUB #1,2(SP)
 002A	     0002
 002C	     9381	CMP #0,2(SP)
 002E	     0002
 0030	     2404	JEQ #4, goes to  003A
 0032	     9191	CMP 2(SP),2(SP)
 0034	     0002
 0036	     0002
 0038	     23F7	JNE #-9, goes to  0028
 003A	     5221	ADD #4,SP
 003C	     4130	RET
 003E	     4130	RET
