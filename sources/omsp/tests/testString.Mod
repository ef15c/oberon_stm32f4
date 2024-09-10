MODULE testString;
  CONST st* = "salut"; st1* = "hi";
  VAR s*: ARRAY 10 OF CHAR; c: CHAR;

  PROCEDURE p(m: ARRAY OF CHAR);
  BEGIN
  END p;

BEGIN
  s := "bonjour";
  p(s); p(st); p("salut"); p("hi");
  c := "a"
END testString.


OMSPTool.DecObj testString.mpc
decode testString.mpc
testString 14B437F3 Flash   104
imports:
type descriptors

data    12
strings
salut|hi||bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0014 0000 0006 0000
fixup procedures chains
 004A( 005C)     0	 0012
fixup handlers chains
fixup data chains
 001C( 002E)     0	 0000
 0052( 0064)     0	 000A
fixup constants chains
 0038( 004A)     0	 0000
 0046( 0058)     0	 0006
 0008( 001A)     0	 000A
fixup types chains
entry =  0014
code    86
 0000( 0012)	     4130	RET
 0002( 0014)	     403F	MOV #0,R15
 0004( 0016)	     0000
 0006( 0018)	     403E	MOV #0,R14
 0008( 001A)	     0000
 000A( 001C)	     4EBF	MOV @R14+,0(R15)
 000C( 001E)	     0000
 000E( 0020)	     532F	ADD #2,R15
 0010( 0022)	     93CE	CMP.B #0,-1(R14)
 0012( 0024)	     FFFF
 0014( 0026)	     23FA	JNE #-6, goes to  000A
 0016( 0028)	     1230	PUSH #10
 0018( 002A)	     000A
 001A( 002C)	     1230	PUSH #4
 001C( 002E)	     0004
 001E( 0030)	     12B0	CALL #0
 0020( 0032)	     0000
 0022( 0034)	     5221	ADD #4,SP
 0024( 0036)	     1230	PUSH #6
 0026( 0038)	     0006
 0028( 003A)	     1230	PUSH #0
 002A( 003C)	     0000
 002C( 003E)	     12B0	CALL #32
 002E( 0040)	     0020
 0030( 0042)	     5221	ADD #4,SP
 0032( 0044)	     1230	PUSH #6
 0034( 0046)	     0006
 0036( 0048)	     1230	PUSH #42
 0038( 004A)	     002A
 003A( 004C)	     12B0	CALL #46
 003C( 004E)	     002E
 003E( 0050)	     5221	ADD #4,SP
 0040( 0052)	     1230	PUSH #3
 0042( 0054)	     0003
 0044( 0056)	     1230	PUSH #0
 0046( 0058)	     0000
 0048( 005A)	     12B0	CALL #60
 004A( 005C)	     003C
 004C( 005E)	     5221	ADD #4,SP
 004E( 0060)	     40F2	MOV.B #97,&0
 0050( 0062)	     0061
 0052( 0064)	     0000
 0054( 0066)	     4130	RET

OMSPTool.DecSym testString.sms
decode testString.sms
testString 14B437F3  1
   1 st [^11]     6       1
   1 st1 [^11]     3       2
   2 s [0  form = 12  size = 10 [^3]  len = 10]     3
