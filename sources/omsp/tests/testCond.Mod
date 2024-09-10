MODULE testCond;

  PROCEDURE p(v: INTEGER);
    VAR b: BOOLEAN*;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END p;

  PROCEDURE q(v: INTEGER*);
    VAR b: BOOLEAN*;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END q;

  PROCEDURE r(v: INTEGER*);
    VAR b: BOOLEAN;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END r;

  PROCEDURE s(v: INTEGER);
    VAR b: BOOLEAN;
  BEGIN b := (v>-1) & (v<1) OR (v>9) & (v<11)
  END s;

BEGIN p(40); q(40); r(40); s(40)
END testCond.

OMSPTool.DecObj testCond.mpc
decode testCond.mpc
testCond 8EF83DE3 Flash   202
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 00A4
fixup procedures chains
 00AA     0	 0000
 00B4     0	 002A
 00BC     0	 004C
 00C4     0	 0074
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  00A4
code   202
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
 002A	     4336	MOV #-1,R6
 002C	     9406	CMP R4,R6
 002E	     3402	JGE #2, goes to  0034
 0030	     9314	CMP #1,R4
 0032	     3807	JL #7, goes to  0042
 0034	     4036	MOV #9,R6
 0036	     0009
 0038	     9406	CMP R4,R6
 003A	     3405	JGE #5, goes to  0046
 003C	     9034	CMP #11,R4
 003E	     000B
 0040	     3402	JGE #2, goes to  0046
 0042	     4316	MOV #1,R6
 0044	     3C01	JMP #1, goes to  0048
 0046	     4306	MOV #0,R6
 0048	     4645	MOV.B R6,R5
 004A	     4130	RET
 004C	     8321	SUB #2,SP
 004E	     4335	MOV #-1,R5
 0050	     9405	CMP R4,R5
 0052	     3402	JGE #2, goes to  0058
 0054	     9314	CMP #1,R4
 0056	     3807	JL #7, goes to  0066
 0058	     4035	MOV #9,R5
 005A	     0009
 005C	     9405	CMP R4,R5
 005E	     3405	JGE #5, goes to  006A
 0060	     9034	CMP #11,R4
 0062	     000B
 0064	     3402	JGE #2, goes to  006A
 0066	     4315	MOV #1,R5
 0068	     3C01	JMP #1, goes to  006C
 006A	     4305	MOV #0,R5
 006C	     45C1	MOV.B R5,0(SP)
 006E	     0000
 0070	     5321	ADD #2,SP
 0072	     4130	RET
 0074	     8321	SUB #2,SP
 0076	     433F	MOV #-1,R15
 0078	     911F	CMP 4(SP),R15
 007A	     0004
 007C	     3403	JGE #3, goes to  0084
 007E	     9391	CMP #1,4(SP)
 0080	     0004
 0082	     3809	JL #9, goes to  0096
 0084	     403F	MOV #9,R15
 0086	     0009
 0088	     911F	CMP 4(SP),R15
 008A	     0004
 008C	     3406	JGE #6, goes to  009A
 008E	     90B1	CMP #11,4(SP)
 0090	     000B
 0092	     0004
 0094	     3402	JGE #2, goes to  009A
 0096	     431F	MOV #1,R15
 0098	     3C01	JMP #1, goes to  009C
 009A	     430F	MOV #0,R15
 009C	     4FC1	MOV.B R15,0(SP)
 009E	     0000
 00A0	     5321	ADD #2,SP
 00A2	     4130	RET
 00A4	     1230	PUSH #40
 00A6	     0028
 00A8	     12B0	CALL #0
 00AA	     0000
 00AC	     5321	ADD #2,SP
 00AE	     4034	MOV #40,R4
 00B0	     0028
 00B2	     12B0	CALL #0
 00B4	     0000
 00B6	     4034	MOV #40,R4
 00B8	     0028
 00BA	     12B0	CALL #0
 00BC	     0000
 00BE	     1230	PUSH #40
 00C0	     0028
 00C2	     12B0	CALL #0
 00C4	     0000
 00C6	     5321	ADD #2,SP
 00C8	     4130	RET
