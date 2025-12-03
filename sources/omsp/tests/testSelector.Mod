MODULE testSelector;

  IMPORT te := testExport;

  TYPE tr = RECORD a, b: INTEGER END;

  VAR r: tr;

  PROCEDURE p*(VAR r: tr);
    VAR q: tr;
  BEGIN r.b := r.a; r.a := r.b;
    q.b := q.a; q.a := q.b
  END p;

BEGIN r.b := r.a; r.a := r.b; r.a := te.v.y; r.b := te.v.x
END testSelector.

OMSPTool.DecObj testSelector.mpc
decode testSelector.mpc
testSelector C6B5286E
imports:
	testExport 1ADE4F94

section     0	d    8	tr
 04 00 FF FF FF FF FF FF
fixups:

section     1	r    4	r
fixups:

section     2	c   42	p
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
fixups:

section     3	c   26	module body
 0000	     4292	MOV &0,&0
 0002	     0000								r.a
 0004	     0000								r.b
 0006	     4292	MOV &5,&3
 0008	     0005								r.b
 000A	     0003								r.a
 000C	     4292	MOV &0,&11
 000E	     0000								te.v.y
 0010	     000B								r.a
 0012	     4292	MOV &0,&9
 0014	     0000								te.v.x
 0016	     0009								r.b
 0018	     4130	RET
fixups:
 0015	s1.4										te.v.x
 000F	s1.4+2									te.v.y
 0017	s0.1+2									r.b	
 0011	s0.1										r.a

section     4	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    3    2
