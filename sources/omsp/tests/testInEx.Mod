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

 END testInEx.

OMSPTool.DecObj testInEx.mpc
decode testInEx.mpc
testInEx 3FD5DD17 Flash    98
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0060
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0060
code    98
 0000	     8221	SUB #4,SP
 0002	     D2B1	BIS #8,0(SP)
 0004	     0000
 0006	     431F	MOV #1,R15
 0008	     411E	MOV 2(SP),R14
 000A	     0002
 000C	     531E	ADD #1,R14
 000E	     831E	SUB #1,R14
 0010	     2402	JEQ #2, goes to  0016
 0012	     5F0F	ADD R15,R15
 0014	     3FFC	JMP #-4, goes to  000E
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
 002A	     2402	JEQ #2, goes to  0030
 002C	     5F0F	ADD R15,R15
 002E	     3FFC	JMP #-4, goes to  0028
 0030	     CF81	BIC R15,0(SP)
 0032	     0000
 0034	     5221	ADD #4,SP
 0036	     4130	RET
 0038	     D234	BIS #8,R4
 003A	     4316	MOV #1,R6
 003C	     4507	MOV R5,R7
 003E	     5317	ADD #1,R7
 0040	     8317	SUB #1,R7
 0042	     2402	JEQ #2, goes to  0048
 0044	     5606	ADD R6,R6
 0046	     3FFC	JMP #-4, goes to  0040
 0048	     D604	BIS R6,R4
 004A	     C034	BIC #32,R4
 004C	     0020
 004E	     4316	MOV #1,R6
 0050	     4507	MOV R5,R7
 0052	     5317	ADD #1,R7
 0054	     8317	SUB #1,R7
 0056	     2402	JEQ #2, goes to  005C
 0058	     5606	ADD R6,R6
 005A	     3FFC	JMP #-4, goes to  0054
 005C	     C604	BIC R6,R4
 005E	     4130	RET
 0060	     4130	RET
