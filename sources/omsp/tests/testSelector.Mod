MODULE testSelector;

  IMPORT te := testExport;

  TYPE tr = RECORD a, b: INTEGER END;

  VAR r: tr;

  PROCEDURE p(VAR r: tr);
    VAR q: tr;
  BEGIN r.b := r.a; r.a := r.b;
    q.b := q.a; q.a := q.b
  END p;

BEGIN r.b := r.a; r.a := r.b; r.a := te.v.y; r.b := te.v.x
END testSelector.

OMSPTool.DecObj testSelector.mpc
decode testSelector.mpc
testSelector 4C4F402A Flash    82
imports:
	testExport F14DC58E
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 002A
fixup procedures chains
fixup handlers chains
fixup data chains
 003E     0	 0000
 0046     0	 0002
 0042     1	 0004
fixup constants chains
fixup types chains
entry =  002A
code    74
 0000	     8221	SUB #4,SP
 0002	     411F	MOV 6(SP),R15
 0004	     0006
 0006	     411E	MOV 6(SP),R14
 0008	     0006
 000A	     4EAF	MOV @R14,2(R15)
 000C	     0002
 000E	     411F	MOV 6(SP),R15
 0010	     0006
 0012	     411E	MOV 6(SP),R14
 0014	     0006
 0016	     4E9F	MOV 2(R14),0(R15)
 0018	     0002
 001A	     0000
 001C	     41A1	MOV @SP,2(SP)
 001E	     0002
 0020	     4191	MOV 2(SP),0(SP)
 0022	     0002
 0024	     0000
 0026	     5221	ADD #4,SP
 0028	     4130	RET
 002A	     4292	MOV &0,&0
 002C	     0000
 002E	     0000
 0030	     4292	MOV &46,&44
 0032	     002E
 0034	     002C
 0036	     403F	MOV #0,R15
 0038	     0000
 003A	     4F92	MOV 2(R15),&52
 003C	     0002
 003E	     0034
 0040	     403F	MOV #56,R15
 0042	     0038
 0044	     4FA2	MOV @R15,&50
 0046	     0032
 0048	     4130	RET
