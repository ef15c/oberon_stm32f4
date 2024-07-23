MODULE testRecord;

  TYPE rec = RECORD
    a, b: INTEGER;
    c, d: ARRAY 2000 OF INTEGER;
	e: INTEGER
  END;

  PROCEDURE p(VAR r: rec*);
  BEGIN
    r.a := 1;
    r.b := 2;
    r.c := r.d;
    r.e := 3
  END p;
  
END testRecord.


OMSPTool.DecObj testRecord.mpc

not leaf:
decode testRecord.mpc
testRecord E4D72F38    54
imports:
type descriptors
 1F46 FFFF FFFF FFFF
data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0030
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0030
code    50
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
 0014	     503F	ADD #4004,R15
 0016	     0FA4
 0018	     403E	MOV #2000,R14
 001A	     07D0
 001C	     4FBF	MOV @R15+,61534(R15)
 001E	     F05E
 0020	     831E	SUB #1,R14
 0022	     23FC	JNE #-4, goes to  001C
 0024	     411F	MOV 2(SP),R15
 0026	     0002
 0028	     40BF	MOV #3,8004(R15)
 002A	     0003
 002C	     1F44
 002E	     4130	RET
 0030	     4130	RET

leaf:
decode testRecord.mpc
testRecord E4D72F38    40
imports:
type descriptors
 1F46 FFFF FFFF FFFF
data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0022
fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0022
code    36
 0000	     4394	MOV #1,0(R4)
 0002	     0000
 0004	     43A4	MOV #2,2(R4)
 0006	     0002
 0008	     4405	MOV R4,R5
 000A	     5035	ADD #4004,R5
 000C	     0FA4
 000E	     4036	MOV #2000,R6
 0010	     07D0
 0012	     45B5	MOV @R5+,61534(R5)
 0014	     F05E
 0016	     8316	SUB #1,R6
 0018	     23FC	JNE #-4, goes to  0012
 001A	     40B4	MOV #3,8004(R4)
 001C	     0003
 001E	     1F44
 0020	     4130	RET
 0022	     4130	RET

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
