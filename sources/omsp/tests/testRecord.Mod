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
testRecord E4D72F38 Flash    58
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
fixup constants chains
fixup types chains
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
 001C	     4FBF	MOV @R15+,-4002(R15)
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
testRecord E4D72F38 Flash    44
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
fixup constants chains
fixup types chains
entry =  0022
code    36
 0000	     4394	MOV #1,0(R4)
 0002	     0000
 0004	     43A4	MOV #2,2(R4)
 0006	     0002
 0008	     4406	MOV R4,R6
 000A	     5036	ADD #4004,R6
 000C	     0FA4
 000E	     4037	MOV #2000,R7
 0010	     07D0
 0012	     46B6	MOV @R6+,-4002(R6)
 0014	     F05E
 0016	     8317	SUB #1,R7
 0018	     23FC	JNE #-4, goes to  0012
 001A	     40B4	MOV #3,8004(R4)
 001C	     0003
 001E	     1F44
 0020	     4130	RET
 0022	     4130	RET
