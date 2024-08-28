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
testString 6ACDB7DC Flash   104
imports:
type descriptors

data    12
strings
salut|hi||bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0002 0000 0006 0000
fixup procedures chains
 004A     0	 0000
fixup handlers chains
fixup data chains
 001C     0	 0000
 0052     0	 000A
fixup constants chains
 0038     0	 0000
 0046     0	 0006
 0008     0	 000A
fixup types chains
entry =  0002
code    86
 0000	     4130	RET
 0002	     403F	MOV #0,R15
 0004	     0000
 0006	     403E	MOV #0,R14
 0008	     0000
 000A	     4EBF	MOV @R14+,0(R15)
 000C	     0000
 000E	     532F	ADD #2,R15
 0010	     93CE	CMP.B #0,-1(R14)
 0012	     FFFF
 0014	     23FA	JNE #-6, goes to  000A
 0016	     1230	PUSH #10
 0018	     000A
 001A	     1230	PUSH #4
 001C	     0004
 001E	     12B0	CALL #0
 0020	     0000
 0022	     5221	ADD #4,SP
 0024	     1230	PUSH #6
 0026	     0006
 0028	     1230	PUSH #0
 002A	     0000
 002C	     12B0	CALL #32
 002E	     0020
 0030	     5221	ADD #4,SP
 0032	     1230	PUSH #6
 0034	     0006
 0036	     1230	PUSH #42
 0038	     002A
 003A	     12B0	CALL #46
 003C	     002E
 003E	     5221	ADD #4,SP
 0040	     1230	PUSH #3
 0042	     0003
 0044	     1230	PUSH #0
 0046	     0000
 0048	     12B0	CALL #60
 004A	     003C
 004C	     5221	ADD #4,SP
 004E	     40F2	MOV.B #97,&0
 0050	     0061
 0052	     0000
 0054	     4130	RET

OMSPTool.DecSym testString.sms
decode testString.sms
testString 6ACDB7DC  1
   1 st [^11]     6       1
   1 st1 [^11]     3       2
   2 s [0  form = 12  size = 10 [^3]  len = 10]     3
