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
testSelector 7BB7CD1E Flash    82
imports:
	testExport 266A3416
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0032
fixup procedures chains
fixup handlers chains
fixup data chains
 003E( 0046)     0	 0000
 0046( 004E)     0	 0002
 0042( 004A)     1	 0004
fixup constants chains
fixup types chains
entry =  0032
code    74
 0000( 0008)	     8221	SUB #4,SP
 0002( 000A)	     411F	MOV 6(SP),R15
 0004( 000C)	     0006
 0006( 000E)	     411E	MOV 6(SP),R14
 0008( 0010)	     0006
 000A( 0012)	     4EAF	MOV @R14,2(R15)
 000C( 0014)	     0002
 000E( 0016)	     411F	MOV 6(SP),R15
 0010( 0018)	     0006
 0012( 001A)	     411E	MOV 6(SP),R14
 0014( 001C)	     0006
 0016( 001E)	     4E9F	MOV 2(R14),0(R15)
 0018( 0020)	     0002
 001A( 0022)	     0000
 001C( 0024)	     41A1	MOV @SP,2(SP)
 001E( 0026)	     0002
 0020( 0028)	     4191	MOV 2(SP),0(SP)
 0022( 002A)	     0002
 0024( 002C)	     0000
 0026( 002E)	     5221	ADD #4,SP
 0028( 0030)	     4130	RET
 002A( 0032)	     4292	MOV &0,&0
 002C( 0034)	     0000
 002E( 0036)	     0000
 0030( 0038)	     4292	MOV &46,&44
 0032( 003A)	     002E
 0034( 003C)	     002C
 0036( 003E)	     403F	MOV #0,R15
 0038( 0040)	     0000
 003A( 0042)	     4F92	MOV 2(R15),&52
 003C( 0044)	     0002
 003E( 0046)	     0034
 0040( 0048)	     403F	MOV #56,R15
 0042( 004A)	     0038
 0044( 004C)	     4FA2	MOV @R15,&50
 0046( 004E)	     0032
 0048( 0050)	     4130	RET
