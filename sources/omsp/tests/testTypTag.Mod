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
 007A
fixup procedures chains
 0052( 0062)     0	 0010
 005C( 006C)     0	 0042
 006C( 007C)     0	 0052
fixup handlers chains
fixup data chains
fixup constants chains
 0048( 0058)     0	 0008
fixup types chains
 000A     0	 0000
entry =  007A
code   112
 0000( 0010)	     8321	SUB #2,SP
 0002( 0012)	     411F	MOV 4(SP),R15
 0004( 0014)	     0004
 0006( 0016)	     4FD1	MOV.B 2(R15),0(SP)
 0008( 0018)	     0002
 000A( 001A)	     0000
 000C( 001C)	     411F	MOV 6(SP),R15
 000E( 001E)	     0006
 0010( 0020)	     4F1F	MOV 2(R15),R15
 0012( 0022)	     0002
 0014( 0024)	     903F	CMP #0,R15
 0016( 0026)	     0000
 0018( 0028)	     2006	JNE #6, goes to  0026
 001A( 002A)	     411F	MOV 4(SP),R15
 001C( 002C)	     0004
 001E( 002E)	     4FD1	MOV.B 2(R15),0(SP)
 0020( 0030)	     0002
 0022( 0032)	     0000
 0024( 0034)	     3C04	JMP #4, goes to  002E
 0026( 0036)	     411F	MOV 4(SP),R15
 0028( 0038)	     0004
 002A( 003A)	     4FE1	MOV.B @R15,0(SP)
 002C( 003C)	     0000
 002E( 003E)	     5321	ADD #2,SP
 0030( 0040)	     4130	RET
 0032( 0042)	     8321	SUB #2,SP
 0034( 0044)	     411F	MOV 4(SP),R15
 0036( 0046)	     0004
 0038( 0048)	     4FD1	MOV.B 2(R15),0(SP)
 003A( 004A)	     0002
 003C( 004C)	     0000
 003E( 004E)	     5321	ADD #2,SP
 0040( 0050)	     4130	RET
 0042( 0052)	     8031	SUB #6,SP
 0044( 0054)	     0006
 0046( 0056)	     1230	PUSH #22
 0048( 0058)	     0016
 004A( 005A)	     410F	MOV SP,R15
 004C( 005C)	     532F	ADD #2,R15
 004E( 005E)	     120F	PUSH R15
 0050( 0060)	     12B0	CALL #0
 0052( 0062)	     0000
 0054( 0064)	     5221	ADD #4,SP
 0056( 0066)	     1211	PUSH 6(SP)
 0058( 0068)	     0006
 005A( 006A)	     12B0	CALL #0
 005C( 006C)	     0000
 005E( 006E)	     5321	ADD #2,SP
 0060( 0070)	     43D1	MOV.B #1,2(SP)
 0062( 0072)	     0002
 0064( 0074)	     5031	ADD #6,SP
 0066( 0076)	     0006
 0068( 0078)	     4130	RET
 006A( 007A)	     12B0	CALL #0
 006C( 007C)	     0000
 006E( 007E)	     4130	RET
