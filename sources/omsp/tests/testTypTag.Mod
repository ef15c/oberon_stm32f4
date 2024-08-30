MODULE testTypTag;
  TYPE tr = RECORD a: INTEGER; END;
    tr1 = RECORD(tr) b: BYTE END;
    tpr = POINTER TO tr;
    tpr1 = POINTER TO tr1;
    
PROCEDURE p(VAR v: tr);
    VAR b: BYTE;
BEGIN b := v(tr1).b;
  CASE v OF
    tr1: b := v.b
  | tr: b := v.a
  END
END p;

PROCEDURE p2(v: tpr);
    VAR b: BYTE;
BEGIN b := v(tpr1).b
END p2;

PROCEDURE q;
  VAR r: tr1;
    pr!: tpr1;
  
BEGIN p(r); p2(pr);
  r.b := 1
END q;

BEGIN q
END testTypTag.

OMSPTool.DecObj testTypTag.mpc
decode testTypTag.mpc
testTypTag C9E44629 Flash   130
imports:
type descriptors
 0002 FFFF FFFF FFFF 0004 0000 FFFF FFFF
data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 006C
fixup procedures chains
 0054     0	 0000
 005E     0	 0034
 006E     0	 0044
fixup handlers chains
fixup data chains
fixup constants chains
 004A     0	 0008
fixup types chains
 000A     0	 0000
entry =  006C
code   114
 0000	     8321	SUB #2,SP
 0002	     411F	MOV 4(SP),R15
 0004	     0004
 0006	     4FD1	MOV.B 2(R15),0(SP)
 0008	     0002
 000A	     0000
 000C	     411F	MOV 6(SP),R15
 000E	     0006
 0010	     4F1F	MOV 2(R15),R15
 0012	     0002
 0014	     403E	MOV #0,R14
 0016	     0000
 0018	     9F0E	CMP R15,R14
 001A	     2006	JNE #6, goes to  0028
 001C	     411F	MOV 4(SP),R15
 001E	     0004
 0020	     4FD1	MOV.B 2(R15),0(SP)
 0022	     0002
 0024	     0000
 0026	     3C04	JMP #4, goes to  0030
 0028	     411F	MOV 4(SP),R15
 002A	     0004
 002C	     4FE1	MOV.B @R15,0(SP)
 002E	     0000
 0030	     5321	ADD #2,SP
 0032	     4130	RET
 0034	     8321	SUB #2,SP
 0036	     411F	MOV 4(SP),R15
 0038	     0004
 003A	     4FD1	MOV.B 2(R15),0(SP)
 003C	     0002
 003E	     0000
 0040	     5321	ADD #2,SP
 0042	     4130	RET
 0044	     8031	SUB #6,SP
 0046	     0006
 0048	     1230	PUSH #22
 004A	     0016
 004C	     410F	MOV SP,R15
 004E	     532F	ADD #2,R15
 0050	     120F	PUSH R15
 0052	     12B0	CALL #0
 0054	     0000
 0056	     5221	ADD #4,SP
 0058	     1211	PUSH 6(SP)
 005A	     0006
 005C	     12B0	CALL #0
 005E	     0000
 0060	     5321	ADD #2,SP
 0062	     43D1	MOV.B #1,2(SP)
 0064	     0002
 0066	     5031	ADD #6,SP
 0068	     0006
 006A	     4130	RET
 006C	     12B0	CALL #0
 006E	     0000
 0070	     4130	RET
