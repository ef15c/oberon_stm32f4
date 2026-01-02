MODULE testFunc2;
  TYPE ptr = POINTER TO tr;
    tf = PROCEDURE(pr: ptr): INTEGER;
    tr* = RECORD fp: tf END;

  VAR r: ptr; i: INTEGER; s: tr;

  PROCEDURE p(f: ptr): INTEGER; RETURN 0 END p;

BEGIN r := PTR(ptr, s); r.fp := p; i := r.fp(r); i := i+i+(r.fp(r))
END testFunc2.

OMSPP.Compile testFunc2.Mod~
OMSPL.Link 32 4000H 200H testFunc2~
  linking testFunc2
    flash   92, data    6, stack  506 bytes

OMSPTool.DecObj testFunc2.mpc
decode testFunc2.mpc
testFunc2 24A56152
imports:

section     0	d    8	tr
 02 00 FF FF FF FF FF FF
fixups:

section     1	r    2	r
fixups:

section     2	r    2	i
fixups:

section     3	r    2	s
fixups:

section     4	c    4	p
 0000	     430F	MOV #0,R15
 0002	     4130	RET
fixups:

section     5	c   74	module body
 0000	     40B2	MOV #0,&0
 0002	     0000
 0004	     0000
 0006	     421F	MOV &5,R15
 0008	     0005
 000A	     40BF	MOV #0,0(R15)
 000C	     0000
 000E	     0000
 0010	     421F	MOV &9,R15
 0012	     0009
 0014	     122F	PUSH @R15
 0016	     1212	PUSH &19
 0018	     0013
 001A	     1291	CALL 4(SP)
 001C	     0004
 001E	     5221	ADD #4,SP
 0020	     4F82	MOV R15,&0
 0022	     0000
 0024	     421F	MOV &35,R15
 0026	     0023
 0028	     521F	ADD &39,R15
 002A	     0027
 002C	     421E	MOV &25,R14
 002E	     0019
 0030	     120F	PUSH R15
 0032	     122E	PUSH @R14
 0034	     1212	PUSH &47
 0036	     002F
 0038	     1291	CALL 4(SP)
 003A	     0004
 003C	     5221	ADD #4,SP
 003E	     4F0E	MOV R15,R14
 0040	     413F	POP R15
 0042	     5E0F	ADD R14,R15
 0044	     4F82	MOV R15,&43
 0046	     002B
 0048	     4130	RET
fixups:
 0047	s0.2
 000D	s0.4
 0037	s0.1
 0003	s0.3

section     6	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    5    0
