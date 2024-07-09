MODULE testInEx;
  PROCEDURE p;
    VAR s: SET*;
      p: INTEGER*;
  BEGIN
    INCL(s, 3); INCL(s, p);
    EXCL(s, 5); EXCL(s, p);
  END p;
  
END testInEx.

OMSPTool.DecObj testInEx.mpc

not leaf:
decode testInEx.mpc
testInEx ECB8D4BD    60
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0034
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0034
code    54
 0000	     8221	SUB #4,SP
 0002	     D2B1	BIS #8,2(SP)
 0004	     0002
 0006	     431F	MOV #1,R15
 0008	     412E	MOV @SP,R14
 000A	     531E	ADD #1,R14
 000C	     831E	SUB #1,R14
 000E	     2402	JEQ #2, goes to  0014
 0010	     5F0F	ADD R15,R15
 0012	     3FFC	JMP #-4, goes to  000C
 0014	     DF81	BIS R15,2(SP)
 0016	     0002
 0018	     C0B1	BIC #32,2(SP)
 001A	     0020
 001C	     0002
 001E	     431F	MOV #1,R15
 0020	     412E	MOV @SP,R14
 0022	     531E	ADD #1,R14
 0024	     831E	SUB #1,R14
 0026	     2402	JEQ #2, goes to  002C
 0028	     5F0F	ADD R15,R15
 002A	     3FFC	JMP #-4, goes to  0024
 002C	     CF81	BIC R15,2(SP)
 002E	     0002
 0030	     5221	ADD #4,SP
 0032	     4130	RET
 0034	     4130	RET

leaf:
decode testInEx.mpc
testInEx ECB8D4BD    48
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0028
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0028
code    42
 0000	     D234	BIS #8,R4
 0002	     4316	MOV #1,R6
 0004	     4507	MOV R5,R7
 0006	     5317	ADD #1,R7
 0008	     8317	SUB #1,R7
 000A	     2402	JEQ #2, goes to  0010
 000C	     5606	ADD R6,R6
 000E	     3FFC	JMP #-4, goes to  0008
 0010	     D604	BIS R6,R4
 0012	     C034	BIC #32,R4
 0014	     0020
 0016	     4316	MOV #1,R6
 0018	     4507	MOV R5,R7
 001A	     5317	ADD #1,R7
 001C	     8317	SUB #1,R7
 001E	     2402	JEQ #2, goes to  0024
 0020	     5606	ADD R6,R6
 0022	     3FFC	JMP #-4, goes to  001C
 0024	     C604	BIC R6,R4
 0026	     4130	RET
 0028	     4130	RET
