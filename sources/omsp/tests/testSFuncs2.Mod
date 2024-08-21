MODULE testSFuncs2;
  TYPE rec* = RECORD a, b*: INTEGER END;

  VAR t: ARRAY 10 OF INTEGER;
    v1*: INTEGER; r*: rec;

  PROCEDURE p*(t: ARRAY OF INTEGER; s: ARRAY OF CHAR);
    VAR v: INTEGER;
      u: ARRAY 5 OF INTEGER;
  BEGIN
    v := LEN(t);
    v := LEN(s);
    v := LEN(u);
    REPEAT UNTIL BIT(v, 3) 
  END p;

  PROCEDURE q*(t: ARRAY OF INTEGER*; s: ARRAY OF CHAR*);
    VAR v: INTEGER*;
      u: ARRAY 5 OF INTEGER;
  BEGIN
    v := LEN(t);
    v := LEN(s);
    v := LEN(u);
    REPEAT UNTIL BIT(v, 3) 
  END q;

BEGIN
  v1 := LEN(t);
  p(t, "bonjour");
  q(t, "bonjour")
END testSFuncs2.


OMSPTool.DecObj testSFuncs2.mpc
decode testSFuncs2.mpc
testSFuncs2 E55368AA Flash   120
imports:
type descriptors
 0004 FFFF FFFF FFFF
data    26
strings
bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0038 0000 0014 0016 0000 0022
fixup procedures chains
 0050     0	 0000
 0064     0	 0022
fixup handlers chains
fixup data chains
 003C     0	 0014
 0056     0	 0000
fixup constants chains
 005E     0	 0008
fixup types chains
entry =  0038
code   104
 0000	     8031	SUB #12,SP
 0002	     000C
 0004	     4191	MOV 20(SP),10(SP)
 0006	     0014
 0008	     000A
 000A	     4191	MOV 16(SP),10(SP)
 000C	     0010
 000E	     000A
 0010	     40B1	MOV #5,10(SP)
 0012	     0005
 0014	     000A
 0016	     B2B1	BIT #8,10(SP)
 0018	     000A
 001A	     27FD	JEQ #-3, goes to  0016
 001C	     5031	ADD #12,SP
 001E	     000C
 0020	     4130	RET
 0022	     8031	SUB #10,SP
 0024	     000A
 0026	     4508	MOV R5,R8
 0028	     4708	MOV R7,R8
 002A	     4038	MOV #5,R8
 002C	     0005
 002E	     B238	BIT #8,R8
 0030	     27FE	JEQ #-2, goes to  002E
 0032	     5031	ADD #10,SP
 0034	     000A
 0036	     4130	RET
 0038	     40B2	MOV #10,&0
 003A	     000A
 003C	     0000
 003E	     1230	PUSH #10
 0040	     000A
 0042	     1230	PUSH #0
 0044	     0000
 0046	     1230	PUSH #8
 0048	     0008
 004A	     1230	PUSH #0
 004C	     0000
 004E	     12B0	CALL #0
 0050	     0000
 0052	     5231	ADD #8,SP
 0054	     4034	MOV #68,R4
 0056	     0044
 0058	     4035	MOV #10,R5
 005A	     000A
 005C	     4036	MOV #76,R6
 005E	     004C
 0060	     4237	MOV #8,R7
 0062	     12B0	CALL #0
 0064	     0000
 0066	     4130	RET

OMSPTool.DecSym testSFuncs2.sms
decode testSFuncs2.sms
testSFuncs2 E55368AA  1
   5 rec [16  form = 13  size = 4 [^9]{  exno = 1  extlev = 0 { b [^4]   2}]()
   2 v1 [^4]     2
   2 r [^16]     3
   1 p [0  form = 10  size = 2 [^9]( class = 3# [0  form = 12  size = 4 [^3]  len = -1] class = 3# [0  form = 12  size = 4 [^4]  len = -1])]       4
   1 q [0  form = 10  size = 2 [^9] leaf UR 01F0( class = 3# R6 [0  form = 12  size = 4 [^3]  len = -1] class = 3# R4 [0  form = 12  size = 4 [^4]  len = -1])]       5
