MODULE testFunc2;
  TYPE ptr = POINTER TO tr;
    tf = PROCEDURE(pr: ptr): INTEGER;
    tr = RECORD fp: tf END;

  VAR r: ptr; i: INTEGER;

  PROCEDURE p(f: ptr): INTEGER; RETURN 0 END p;

BEGIN (*NEW(r);*) r.fp := p; i := r.fp(r); i := i+i+(r.fp(r))
END testFunc2.

OMSPTool.DecObj testFunc2.mpc
decode testFunc2.mpc
testFunc2 3685528E Flash    88
imports:
type descriptors
 0002 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 000C
fixup procedures chains
 000A( 0012)     0	 0008
fixup handlers chains
fixup data chains
 003A( 0042)     0	 0000
 004C( 0054)     0	 0002
fixup constants chains
fixup types chains
entry =  000C
code    80
 0000( 0008)	     430F	MOV #0,R15
 0002( 000A)	     4130	RET
 0004( 000C)	     421F	MOV &0,R15
 0006( 000E)	     0000
 0008( 0010)	     40BF	MOV #0,0(R15)
 000A( 0012)	     0000
 000C( 0014)	     0000
 000E( 0016)	     421F	MOV &6,R15
 0010( 0018)	     0006
 0012( 001A)	     4F2F	MOV @R15,R15
 0014( 001C)	     120F	PUSH R15
 0016( 001E)	     1212	PUSH &16
 0018( 0020)	     0010
 001A( 0022)	     411F	MOV -2(SP),R15
 001C( 0024)	     FFFE
 001E( 0026)	     128F	CALL R15
 0020( 0028)	     5221	ADD #4,SP
 0022( 002A)	     4F82	MOV R15,&0
 0024( 002C)	     0000
 0026( 002E)	     421F	MOV &36,R15
 0028( 0030)	     0024
 002A( 0032)	     521F	ADD &40,R15
 002C( 0034)	     0028
 002E( 0036)	     421E	MOV &24,R14
 0030( 0038)	     0018
 0032( 003A)	     4E2E	MOV @R14,R14
 0034( 003C)	     120F	PUSH R15
 0036( 003E)	     120E	PUSH R14
 0038( 0040)	     1212	PUSH &48
 003A( 0042)	     0030
 003C( 0044)	     411E	MOV -2(SP),R14
 003E( 0046)	     FFFE
 0040( 0048)	     128E	CALL R14
 0042( 004A)	     5221	ADD #4,SP
 0044( 004C)	     4F0E	MOV R15,R14
 0046( 004E)	     413F	POP R15
 0048( 0050)	     5E0F	ADD R14,R15
 004A( 0052)	     4F82	MOV R15,&44
 004C( 0054)	     002C
 004E( 0056)	     4130	RET
