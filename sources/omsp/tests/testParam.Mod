MODULE testParam;

  TYPE ti = ARRAY 10 OF INTEGER;

  PROCEDURE p(i: INTEGER; VAR s: ARRAY OF INTEGER);
  BEGIN
    i := i+10; s[i] := 1
  END p;
  
  PROCEDURE q(VAR t: ti; VAR u: ARRAY OF INTEGER);
  BEGIN
    p(1, t);
    p(1, u);
  END q;

END testParam.


OMSPTool.DecObj testParam.mpc 

not leaf:
decode testParam.mpc
testParam D5E6C731    76
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
entries
 0044
fixup procedures chains
 003C     0	 0000
fixup handlers chains
fixup data chains
fixup type chains
entry =  0044
code    70
 0000	     411F	MOV 6(SP),R15
 0002	     0006
 0004	     503F	ADD #10,R15
 0006	     000A
 0008	     4F81	MOV R15,6(SP)
 000A	     0006
 000C	     411F	MOV 6(SP),R15
 000E	     0006
 0010	     5F0F	ADD R15,R15
 0012	     411E	MOV 2(SP),R14
 0014	     0002
 0016	     5E0F	ADD R14,R15
 0018	     439F	MOV #1,0(R15)
 001A	     0000
 001C	     4130	RET
 001E	     1213	PUSH #1
 0020	     1230	PUSH #10
 0022	     000A
 0024	     1211	PUSH 6(SP)
 0026	     0006
 0028	     12B0	CALL #0
 002A	     0000
 002C	     5031	ADD #6,SP
 002E	     0006
 0030	     1213	PUSH #1
 0032	     1211	PUSH 4(SP)
 0034	     0004
 0036	     1211	PUSH 2(SP)
 0038	     0002
 003A	     12B0	CALL #42
 003C	     002A
 003E	     5031	ADD #6,SP
 0040	     0006
 0042	     4130	RET
 0044	     4130	RET


OM4Tool.DecObj testParam.m4c
decode testParam.m4c
testParam D5E6C731   1    96
imports:
type descriptors

data     0
strings

code
commands:
entries
    76
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       76
 00000000	     B407	PUSH R0 R1 R2
 00000002	     B500	PUSH LR
 00000004	     9801	LDR R0 [SP + 4]
 00000006	     300A	ADDS R0 #10
 00000008	     9001	STR R0 [SP + 4]
 0000000A	     9801	LDR R0 [SP + 4]
 0000000C	     9903	LDR R1 [SP + 12]
 0000000E	     4288	CMP R0 R1
 00000010	     BF28	IT CS
 00000012	 EC001041	TrapCS 1 at pos 132
 00000016	     9902	LDR R1 [SP + 8]
 00000018	 EB110080	ADDS R0 R1 R0 LSL #2
 0000001C	     2101	MOVS R1 #1
 0000001E	     6001	STR R1 [ R0 + 0]
 00000020	 F85DEB04	LDR LR [ SP ] + 4
 00000024	 F11D0D0C	ADDS SP SP #12
 00000028	     4770	BX LR
 0000002A	     B407	PUSH R0 R1 R2
 0000002C	     B500	PUSH LR
 0000002E	     2001	MOVS R0 #1
 00000030	     9901	LDR R1 [SP + 4]
 00000032	     220A	MOVS R2 #10
 00000034	 F7FFFFE4	BL #-56, goes to  00000000
 00000038	     2001	MOVS R0 #1
 0000003A	     9902	LDR R1 [SP + 8]
 0000003C	     9A03	LDR R2 [SP + 12]
 0000003E	 F7FFFFDF	BL #-66, goes to  00000000
 00000042	 F85DEB04	LDR LR [ SP ] + 4
 00000046	 F11D0D0C	ADDS SP SP #12
 0000004A	     4770	BX LR
 0000004C	     B500	PUSH LR
 0000004E	 F85DEB04	LDR LR [ SP ] + 4
 00000052	     4770	BX LR
