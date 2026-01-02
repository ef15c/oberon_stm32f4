MODULE testString;
  CONST st* = "salut"; st1* = "hi";
  TYPE R* = RECORD END;
  VAR s*: ARRAY 10 OF CHAR; c: CHAR;

  PROCEDURE p(m: ARRAY OF CHAR);
  BEGIN
  END p;

BEGIN
  s := "bonjour";
  p(s); p(st); p("salut"); p("hi");
  c := "a"
END testString.

System.Free OMSPL OMSPP OMSPG~
OMSPP.Compile testString.Mod/s~
OMSPL.Link 32 4000H 200H testString ~
  linking testString
    flash  118, data   11, stack  501 bytes

OMSPTool.DecObj testString.mpc
decode testString.mpc
testString 4C4AD16E
imports:

section     0	s    6	
salut|
fixups:

section     1	s    4	
hi||
fixups:

section     2	d    8	R
 00 00 FF FF FF FF FF FF
fixups:

section     3	r   10	s
fixups:

section     4	r    1	c
fixups:

section     5	c    2	p
 0000	     4130	RET
fixups:

section     6	c   84	module body
 0000	     403F	MOV #0,R15
 0002	     0000
 0004	     403E	MOV #0,R14
 0006	     0000
 0008	     4EBF	MOV @R14+,0(R15)
 000A	     0000
 000C	     532F	ADD #2,R15
 000E	     93CE	CMP.B #0,-1(R14)
 0010	     FFFF
 0012	     23FA	JNE $-10, goes to  0008
 0014	     1230	PUSH #10
 0016	     000A
 0018	     1230	PUSH #3
 001A	     0003
 001C	     12B0	CALL #0
 001E	     0000
 0020	     5221	ADD #4,SP
 0022	     1230	PUSH #6
 0024	     0006
 0026	     1230	PUSH #0
 0028	     0000
 002A	     12B0	CALL #31
 002C	     001F
 002E	     5221	ADD #4,SP
 0030	     1230	PUSH #6
 0032	     0006
 0034	     1230	PUSH #41
 0036	     0029
 0038	     12B0	CALL #45
 003A	     002D
 003C	     5221	ADD #4,SP
 003E	     1230	PUSH #3
 0040	     0003
 0042	     1230	PUSH #0
 0044	     0000
 0046	     12B0	CALL #59
 0048	     003B
 004A	     5221	ADD #4,SP
 004C	     40F2	MOV.B #97,&0
 004E	     0061
 0050	     0000
 0052	     4130	RET
fixups:
 0051	s0.4
 0045	s0.1
 0037	s0.0
 0049	s0.5
 0007	s0.7
 001B	s0.3

section     7	s    8	
bonjour|
fixups:

section     8	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    6    0    1    2    3

OMSPTool.DecSym testString.sms
decode testString.sms
testString 4C4AD16E  3
   9 st [^11]     6     1
   9 st1 [^11]     3     2
   5 R [19  form = 13 [^9]{  exno = 3  extlev = 0  size = 0 {}]()
   2 s [0  form = 12 [^3]  len = 10  size = 10]     4
