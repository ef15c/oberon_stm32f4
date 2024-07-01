MODULE testFor;

  PROCEDURE p;
    VAR i,j: INTEGER*;
  BEGIN
    FOR i := 1 TO 10 DO j := 2*i END;
    FOR i := 10 TO 1 BY -2 DO END
  END p;

END testFor.

OMSPTool.DecObj testFor.mpc

not leaf:
decode testFor.mpc
testFor 74E5D4BB    68
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 003C
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  003C
code    62
 0000	     8221	SUB #4,SP
 0002	     4391	MOV #1,2(SP)
 0004	     0002
 0006	     403F	MOV #10,R15
 0008	     000A
 000A	     911F	CMP 2(SP),R15
 000C	     0002
 000E	     3809	JL #9, goes to  0022
 0010	     411F	MOV 2(SP),R15
 0012	     0002
 0014	     5F0F	ADD R15,R15
 0016	     4F81	MOV R15,0(SP)
 0018	     0000
 001A	     411F	MOV 2(SP),R15
 001C	     0002
 001E	     531F	ADD #1,R15
 0020	     3FF2	JMP #-14, goes to  0006
 0022	     40B1	MOV #10,2(SP)
 0024	     000A
 0026	     0002
 0028	     431F	MOV #1,R15
 002A	     9F81	CMP R15,2(SP)
 002C	     0002
 002E	     3804	JL #4, goes to  0038
 0030	     411F	MOV 2(SP),R15
 0032	     0002
 0034	     832F	SUB #2,R15
 0036	     3FF8	JMP #-8, goes to  0028
 0038	     5221	ADD #4,SP
 003A	     4130	RET
 003C	     4130	RET

leaf:
decode testFor.mpc
testFor 74E5D4BB    44
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0024
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0024
code    38
 0000	     4314	MOV #1,R4
 0002	     4036	MOV #10,R6
 0004	     000A
 0006	     9406	CMP R4,R6
 0008	     3805	JL #5, goes to  0014
 000A	     4406	MOV R4,R6
 000C	     5606	ADD R6,R6
 000E	     4605	MOV R6,R5
 0010	     5314	ADD #1,R4
 0012	     3FF7	JMP #-9, goes to  0002
 0014	     4034	MOV #10,R4
 0016	     000A
 0018	     4316	MOV #1,R6
 001A	     9604	CMP R6,R4
 001C	     3802	JL #2, goes to  0022
 001E	     8324	SUB #2,R4
 0020	     3FFB	JMP #-5, goes to  0018
 0022	     4130	RET
 0024	     4130	RET

OM4Tool.DecObj testFor.m4c

decode testFor.m4c
testFor 74E5D4BB   1    80
imports:
type descriptors

data     0
strings

code
commands:
entries
    60
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       60
 00000000	 F1BD0D08	SUBS SP SP #8
 00000004	     B500	PUSH LR
 00000006	     2001	MOVS R0 #1
 00000008	     210A	MOVS R1 #10
 0000000A	     4288	CMP R0 R1
 0000000C	 F3008007	BGT #14, goes to  0000001E
 00000010	     9001	STR R0 [SP + 4]
 00000012	     9801	LDR R0 [SP + 4]
 00000014	     0040	LSLS R0 R0 #1
 00000016	     9002	STR R0 [SP + 8]
 00000018	     9801	LDR R0 [SP + 4]
 0000001A	     1C40	ADDS R0 R0 #1
 0000001C	     E7F4	B #-24, goes to  00000008
 0000001E	     200A	MOVS R0 #10
 00000020	     2101	MOVS R1 #1
 00000022	     4288	CMP R0 R1
 00000024	 F2C08005	BLT #10, goes to  00000032
 00000028	     9001	STR R0 [SP + 4]
 0000002A	     9801	LDR R0 [SP + 4]
 0000002C	 F1B00002	SUBS R0 R0 #2
 00000030	     E7F6	B #-20, goes to  00000020
 00000032	 F85DEB04	LDR LR [ SP ] + 4
 00000036	 F11D0D08	ADDS SP SP #8
 0000003A	     4770	BX LR
 0000003C	     B500	PUSH LR
 0000003E	 F85DEB04	LDR LR [ SP ] + 4
 00000042	     4770	BX LR
