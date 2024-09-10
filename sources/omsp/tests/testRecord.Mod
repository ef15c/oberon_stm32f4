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

  PROCEDURE q(VAR r: rec*);
  BEGIN
    r.a := 1;
    r.b := 2;
    r.c := r.d;
    r.e := 3
  END q;

END testRecord.


OMSPTool.DecObj testRecord.mpc
decode testRecord.mpc
testRecord 46D659A9 Flash    92
imports:
type descriptors
 1F46 FFFF FFFF FFFF
data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 005A
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  005A
code    84
 0000( 0008)	     411F	MOV 2(SP),R15
 0002( 000A)	     0002
 0004( 000C)	     439F	MOV #1,0(R15)
 0006( 000E)	     0000
 0008( 0010)	     411F	MOV 2(SP),R15
 000A( 0012)	     0002
 000C( 0014)	     43AF	MOV #2,2(R15)
 000E( 0016)	     0002
 0010( 0018)	     411F	MOV 2(SP),R15
 0012( 001A)	     0002
 0014( 001C)	     503F	ADD #4004,R15
 0016( 001E)	     0FA4
 0018( 0020)	     403E	MOV #2000,R14
 001A( 0022)	     07D0
 001C( 0024)	     4FBF	MOV @R15+,-4002(R15)
 001E( 0026)	     F05E
 0020( 0028)	     831E	SUB #1,R14
 0022( 002A)	     23FC	JNE #-4, goes to  001C
 0024( 002C)	     411F	MOV 2(SP),R15
 0026( 002E)	     0002
 0028( 0030)	     40BF	MOV #3,8004(R15)
 002A( 0032)	     0003
 002C( 0034)	     1F44
 002E( 0036)	     4130	RET
 0030( 0038)	     4394	MOV #1,0(R4)
 0032( 003A)	     0000
 0034( 003C)	     43A4	MOV #2,2(R4)
 0036( 003E)	     0002
 0038( 0040)	     4406	MOV R4,R6
 003A( 0042)	     5036	ADD #4004,R6
 003C( 0044)	     0FA4
 003E( 0046)	     4037	MOV #2000,R7
 0040( 0048)	     07D0
 0042( 004A)	     46B6	MOV @R6+,-4002(R6)
 0044( 004C)	     F05E
 0046( 004E)	     8317	SUB #1,R7
 0048( 0050)	     23FC	JNE #-4, goes to  0042
 004A( 0052)	     40B4	MOV #3,8004(R4)
 004C( 0054)	     0003
 004E( 0056)	     1F44
 0050( 0058)	     4130	RET
 0052( 005A)	     4130	RET
