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
testTypTag 3F04311C Flash   128
imports:
type descriptors
 0002 FFFF FFFF FFFF 0004 0000 FFFF FFFF
data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 006A
fixup procedures in code space chains
 0052     0	 0000
 005C     0	 0032
 006C     0	 0042
fixup handlers in vector space chains
fixup data in code space chains
fixup constants in code space chains
 0048     0	 0008
fixup variables in constant space chains
fixup constants in constant space chains
 000A     0	 0000
entry =  006A
code   112
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
 0014	     903F	CMP #0,R15
 0016	     0000
 0018	     2006	JNE $+14, goes to  0026
 001A	     411F	MOV 4(SP),R15
 001C	     0004
 001E	     4FD1	MOV.B 2(R15),0(SP)
 0020	     0002
 0022	     0000
 0024	     3C04	JMP $+10, goes to  002E
 0026	     411F	MOV 4(SP),R15
 0028	     0004
 002A	     4FE1	MOV.B @R15,0(SP)
 002C	     0000
 002E	     5321	ADD #2,SP
 0030	     4130	RET
 0032	     8321	SUB #2,SP
 0034	     411F	MOV 4(SP),R15
 0036	     0004
 0038	     4FD1	MOV.B 2(R15),0(SP)
 003A	     0002
 003C	     0000
 003E	     5321	ADD #2,SP
 0040	     4130	RET
 0042	     8031	SUB #6,SP
 0044	     0006
 0046	     1230	PUSH #22
 0048	     0016
 004A	     410F	MOV SP,R15
 004C	     532F	ADD #2,R15
 004E	     120F	PUSH R15
 0050	     12B0	CALL #0
 0052	     0000
 0054	     5221	ADD #4,SP
 0056	     1211	PUSH 6(SP)
 0058	     0006
 005A	     12B0	CALL #0
 005C	     0000
 005E	     5321	ADD #2,SP
 0060	     43D1	MOV.B #1,2(SP)
 0062	     0002
 0064	     5031	ADD #6,SP
 0066	     0006
 0068	     4130	RET
 006A	     12B0	CALL #0
 006C	     0000
 006E	     4130	RET
