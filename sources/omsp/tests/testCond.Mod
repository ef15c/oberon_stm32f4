MODULE testCond;

  PROCEDURE p(v: INTEGER);
    VAR b: BOOLEAN*;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END p;

BEGIN p(40)
END testCond.

OMSPTool.DecObj testCond.mpc

leaf, local variable in register:
decode testCond.mpc
testCond D8E1D5B7    60
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 002A
pointer refs

fixup procedures chains
 0030     0	 0000
fixup handlers chains
fixup data chains
fixup type chains
entry =  002A
code    54
 0000	     4335	MOV #-1,R5
 0002	     9115	CMP 2(SP),R5
 0004	     0002
 0006	     3403	JGE #3, goes to  000E
 0008	     9391	CMP #1,2(SP)
 000A	     0002
 000C	     3809	JL #9, goes to  0020
 000E	     4035	MOV #9,R5
 0010	     0009
 0012	     9115	CMP 2(SP),R5
 0014	     0002
 0016	     3406	JGE #6, goes to  0024
 0018	     90B1	CMP #11,2(SP)
 001A	     000B
 001C	     0002
 001E	     3402	JGE #2, goes to  0024
 0020	     4315	MOV #1,R5
 0022	     3C01	JMP #1, goes to  0026
 0024	     4305	MOV #0,R5
 0026	     4544	MOV.B R5,R4
 0028	     4130	RET
 002A	     1230	PUSH #40
 002C	     0028
 002E	     12B0	CALL #0
 0030	     0000
 0032	     5321	ADD #2,SP
 0034	     4130	RET

leaf, param and local variable in registers:
decode testCond.mpc
testCond D8E1D5B7    50
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0022
pointer refs

fixup procedures chains
 0028     0	 0000
fixup handlers chains
fixup data chains
fixup type chains
entry =  0022
code    44
 0000	     4336	MOV #-1,R6
 0002	     9406	CMP R4,R6
 0004	     3402	JGE #2, goes to  000A
 0006	     9314	CMP #1,R4
 0008	     3807	JL #7, goes to  0018
 000A	     4036	MOV #9,R6
 000C	     0009
 000E	     9406	CMP R4,R6
 0010	     3405	JGE #5, goes to  001C
 0012	     9034	CMP #11,R4
 0014	     000B
 0016	     3402	JGE #2, goes to  001C
 0018	     4316	MOV #1,R6
 001A	     3C01	JMP #1, goes to  001E
 001C	     4306	MOV #0,R6
 001E	     4645	MOV.B R6,R5
 0020	     4130	RET
 0022	     4034	MOV #40,R4
 0024	     0028
 0026	     12B0	CALL #0
 0028	     0000
 002A	     4130	RET

leaf, param in register:
decode testCond.mpc
testCond D8E1D5B7    56
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
 002E     0	 0000
fixup handlers chains
fixup data chains
fixup type chains
entry =  0028
code    50
 0000	     8321	SUB #2,SP
 0002	     4335	MOV #-1,R5
 0004	     9405	CMP R4,R5
 0006	     3402	JGE #2, goes to  000C
 0008	     9314	CMP #1,R4
 000A	     3807	JL #7, goes to  001A
 000C	     4035	MOV #9,R5
 000E	     0009
 0010	     9405	CMP R4,R5
 0012	     3405	JGE #5, goes to  001E
 0014	     9034	CMP #11,R4
 0016	     000B
 0018	     3402	JGE #2, goes to  001E
 001A	     4315	MOV #1,R5
 001C	     3C01	JMP #1, goes to  0020
 001E	     4305	MOV #0,R5
 0020	     45C1	MOV.B R5,0(SP)
 0022	     0000
 0024	     5321	ADD #2,SP
 0026	     4130	RET
 0028	     4034	MOV #40,R4
 002A	     0028
 002C	     12B0	CALL #0
 002E	     0000
 0030	     4130	RET

not leaf:
decode testCond.mpc
testCond D8E1D5B7    66
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0030
pointer refs

fixup procedures chains
 0036     0	 0000
fixup handlers chains
fixup data chains
fixup type chains
entry =  0030
code    60
 0000	     8321	SUB #2,SP
 0002	     433F	MOV #-1,R15
 0004	     911F	CMP 4(SP),R15
 0006	     0004
 0008	     3403	JGE #3, goes to  0010
 000A	     9391	CMP #1,4(SP)
 000C	     0004
 000E	     3809	JL #9, goes to  0022
 0010	     403F	MOV #9,R15
 0012	     0009
 0014	     911F	CMP 4(SP),R15
 0016	     0004
 0018	     3406	JGE #6, goes to  0026
 001A	     90B1	CMP #11,4(SP)
 001C	     000B
 001E	     0004
 0020	     3402	JGE #2, goes to  0026
 0022	     431F	MOV #1,R15
 0024	     3C01	JMP #1, goes to  0028
 0026	     430F	MOV #0,R15
 0028	     4FC1	MOV.B R15,0(SP)
 002A	     0000
 002C	     5321	ADD #2,SP
 002E	     4130	RET
 0030	     1230	PUSH #40
 0032	     0028
 0034	     12B0	CALL #0
 0036	     0000
 0038	     5321	ADD #2,SP
 003A	     4130	RET
