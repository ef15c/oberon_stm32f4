MODULE testFor;

  PROCEDURE p;
    VAR i,j: INTEGER;
  BEGIN
    FOR i := 1 TO 10 DO j := 2*i END;
    FOR i := 10 TO 1 BY -2 DO END
  END p;

END testFor.

OMSPTool.DecObj testFor.mpc

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
 0002	     431F	MOV #1,R15
 0004	     403E	MOV #10,R14
 0006	     000A
 0008	     9E0F	CMP R14,R15
 000A	     380B	JL #11, goes to  0022
 000C	     4F81	MOV R15,2(SP)
 000E	     0002
 0010	     411F	MOV 2(SP),R15
 0012	     0002
 0014	     5F0F	ADD R15,R15
 0016	     4F81	MOV R15,0(SP)
 0018	     0000
 001A	     411F	MOV 2(SP),R15
 001C	     0002
 001E	     531F	ADD #1,R15
 0020	     3FF1	JMP #-15, goes to  0004
 0022	     403F	MOV #10,R15
 0024	     000A
 0026	     431E	MOV #1,R14
 0028	     9F0E	CMP R15,R14
 002A	     3806	JL #6, goes to  0038
 002C	     4F81	MOV R15,2(SP)
 002E	     0002
 0030	     411F	MOV 2(SP),R15
 0032	     0002
 0034	     832F	SUB #2,R15
 0036	     3FF7	JMP #-9, goes to  0026
 0038	     5221	ADD #4,SP
 003A	     4130	RET
 003C	     4130	RET

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
