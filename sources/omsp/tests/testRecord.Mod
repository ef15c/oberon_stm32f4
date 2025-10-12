MODULE testRecord;

  TYPE rec = RECORD
    a, b: INTEGER;
    c, d: ARRAY 2000 OF INTEGER;
    e: INTEGER
  END;

  VAR r: rec;

  PROCEDURE p(VAR r: rec);
  BEGIN
    r.a := 1;
    r.b := 2;
    r.c := r.d;
    r.e := 3
  END p;

  PROCEDURE q(VAR r: rec*);
  BEGIN
    r.a := 1;
    r.b := 2;
    r.c := r.d;
    r.e := 3
  END q;

BEGIN p(r); q(r)
END testRecord.

OMSPP.Compile testRecord.Mod~
OMSPTool.DecObj testRecord.mpc
decode testRecord.mpc
testRecord 46D659A9 Flash   118
imports:
type descriptors
 1F46 FFFF FFFF FFFF
data  8006
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0052
fixup procedures in code space chains
 005C     0	 0000
 006A     0	 0030
fixup handlers in vector space chains
fixup data in code space chains
 0062     0	 0000
fixup constants in code space chains
 0066     0	 0000
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0052
code   110
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
 001C	     4FBF	MOV @R15+,-4002(R15)
 001E	     F05E
 0020	     831E	SUB #1,R14
 0022	     23FC	JNE $-6, goes to  001C
 0024	     411F	MOV 2(SP),R15
 0026	     0002
 0028	     40BF	MOV #3,8004(R15)
 002A	     0003
 002C	     1F44
 002E	     4130	RET
 0030	     4394	MOV #1,0(R4)
 0032	     0000
 0034	     43A4	MOV #2,2(R4)
 0036	     0002
 0038	     4406	MOV R4,R6
 003A	     5036	ADD #4004,R6
 003C	     0FA4
 003E	     4037	MOV #2000,R7
 0040	     07D0
 0042	     46B6	MOV @R6+,-4002(R6)
 0044	     F05E
 0046	     8317	SUB #1,R7
 0048	     23FC	JNE $-6, goes to  0042
 004A	     40B4	MOV #3,8004(R4)
 004C	     0003
 004E	     1F44
 0050	     4130	RET
 0052	     1230	PUSH #0
 0054	     0000
 0056	     1230	PUSH #0
 0058	     0000
 005A	     12B0	CALL #0
 005C	     0000
 005E	     5221	ADD #4,SP
 0060	     4034	MOV #88,R4
 0062	     0058
 0064	     4035	MOV #84,R5
 0066	     0054
 0068	     12B0	CALL #0
 006A	     0000
 006C	     4130	RET
