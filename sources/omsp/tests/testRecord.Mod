MODULE testRecord;

  TYPE rec = RECORD
    a, b: INTEGER;
    c, d: ARRAY 2000 OF INTEGER;
	e: INTEGER
  END;

  PROCEDURE p(VAR r: rec);
  BEGIN
    r.a := 1;
    r.b := 2;
    r.c := r.d;
    r.e := 3
  END p;
  
END testRecord.


OMSPTool.DecObj testRecord.mpc

decode testRecord.mpc
testRecord E4D72F38    62
imports:
type descriptors
 1F46 FFFF FFFF FFFF
data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0038
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0038
code    58
 0000	     411F	MOV 2(SP),R15
 0002	     0002
 0004	     439F	MOV #1,0(R15)
 0006	     0000
 0008	     411F	MOV 2(SP),R15
 000A	     0002
 000C	     43AF	MOV #2,2(R15)
 000E	     0002
 0010	     411F	MOV 2(SP),R15
 0012	     0002
 0014	     522F	ADD #4,R15
 0016	     411E	MOV 2(SP),R14
 0018	     0002
 001A	     503E	ADD #4004,R14
 001C	     0FA4
 001E	     403D	MOV #2000,R13
 0020	     07D0
 0022	     4EBF	MOV @R14+,0(R15)
 0024	     0000
 0026	     532F	ADD #2,R15
 0028	     831D	SUB #1,R13
 002A	     23FB	JNE #-5, goes to  0022
 002C	     411F	MOV 2(SP),R15
 002E	     0002
 0030	     40BF	MOV #3,8004(R15)
 0032	     0003
 0034	     1F44
 0036	     4130	RET
 0038	     4130	RET


OM4Tool.DecObj testRecord.m4c
decode testRecord.m4c
testRecord E4D72F38   1   108
imports:
type descriptors
 00003F00 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
commands:
entries
    66
pointer refs

fixP =        0
fixD =        0
fixT =        0
entry =       66
 00000000	     B403	PUSH R0 R1
 00000002	     B500	PUSH LR
 00000004	     2001	MOVS R0 #1
 00000006	     9901	LDR R1 [SP + 4]
 00000008	     6008	STR R0 [ R1 + 0]
 0000000A	     2002	MOVS R0 #2
 0000000C	     9901	LDR R1 [SP + 4]
 0000000E	     6048	STR R0 [ R1 + 4]
 00000010	     9801	LDR R0 [SP + 4]
 00000012	     3008	ADDS R0 #8
 00000014	     9901	LDR R1 [SP + 4]
 00000016	 F6417248	MOV R2 #8008
 0000001A	     1889	ADDS R1 R1 R2
 0000001C	 F45F62FA	MOVS R2 #2000
 00000020	 F8513B04	LDR R3 [ R1 ] + 4
 00000024	 F8403B04	STR R3 [ R0 ] + 4
 00000028	     1E52	SUBS R2 R2 #1
 0000002A	     D1F9	BNE #-14, goes to  00000020
 0000002C	     2003	MOVS R0 #3
 0000002E	     9901	LDR R1 [SP + 4]
 00000030	 F5115240	ADDS R2 R1 #12288
 00000034	 F8C20E88	STR R0 [ R2 + 3720 ]
 00000038	 F85DEB04	LDR LR [ SP ] + 4
 0000003C	 F11D0D08	ADDS SP SP #8
 00000040	     4770	BX LR
 00000042	     B500	PUSH LR
 00000044	 F85DEB04	LDR LR [ SP ] + 4
 00000048	     4770	BX LR
