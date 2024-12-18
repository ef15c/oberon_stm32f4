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
 c 0004
fixup procedures chains
 000A     0	 0000
fixup handlers chains
fixup data chains
 003A     0	 0000
 004C     0	 0002
fixup constants chains
fixup types chains
entry =  0004
code    80
 0000	     430F	MOV #0,R15
 0002	     4130	RET
 0004	     421F	MOV &0,R15
 0006	     0000
 0008	     40BF	MOV #0,0(R15)
 000A	     0000
 000C	     0000
 000E	     421F	MOV &6,R15
 0010	     0006
 0012	     4F2F	MOV @R15,R15
 0014	     120F	PUSH R15
 0016	     1212	PUSH &16
 0018	     0010
 001A	     411F	MOV -2(SP),R15
 001C	     FFFE
 001E	     128F	CALL R15
 0020	     5221	ADD #4,SP
 0022	     4F82	MOV R15,&0
 0024	     0000
 0026	     421F	MOV &36,R15
 0028	     0024
 002A	     521F	ADD &40,R15
 002C	     0028
 002E	     421E	MOV &24,R14
 0030	     0018
 0032	     4E2E	MOV @R14,R14
 0034	     120F	PUSH R15
 0036	     120E	PUSH R14
 0038	     1212	PUSH &48
 003A	     0030
 003C	     411F	MOV -2(SP),R15
 003E	     FFFE
 0040	     128F	CALL R15
 0042	     5221	ADD #4,SP
 0044	     4F0E	MOV R15,R14
 0046	     413F	POP R15
 0048	     5E0F	ADD R14,R15
 004A	     4F82	MOV R15,&44
 004C	     002C
 004E	     4130	RET
