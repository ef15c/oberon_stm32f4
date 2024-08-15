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
BEGIN
  v1 := LEN(t);
  p(t, "bonjour")
END testSFuncs2.


OMSPTool.DecObj testSFuncs2.mpc

no leaf:
decode testSFuncs2.mpc
testSFuncs2 6353DF1C Flash    80
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
 0022 0000 0014 0016 0000
fixup procedures chains
 003A     0	 0000
fixup handlers chains
fixup data chains
 0026     0	 0014
 002E     0	 0000
fixup constants chains
 0036     0	 0008
fixup types chains
entry =  0022
code    64
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
 0022	     40B2	MOV #10,&0
 0024	     000A
 0026	     0000
 0028	     1230	PUSH #10
 002A	     000A
 002C	     1230	PUSH #0
 002E	     0000
 0030	     1230	PUSH #8
 0032	     0008
 0034	     1230	PUSH #0
 0036	     0000
 0038	     12B0	CALL #0
 003A	     0000
 003C	     5231	ADD #8,SP
 003E	     4130	RET

leaf:
decode testSFuncs2.mpc
testSFuncs2 5258E61D Flash    64
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
 0016 0000 0014 0016 0000
fixup procedures chains
 002C     0	 0000
fixup handlers chains
fixup data chains
 001A     0	 0014
 001E     0	 0000
fixup constants chains
 0026     0	 0008
fixup types chains
entry =  0016
code    48
 0000	     8031	SUB #10,SP
 0002	     000A
 0004	     4508	MOV R5,R8
 0006	     4708	MOV R7,R8
 0008	     4038	MOV #5,R8
 000A	     0005
 000C	     B238	BIT #8,R8
 000E	     27FE	JEQ #-2, goes to  000C
 0010	     5031	ADD #10,SP
 0012	     000A
 0014	     4130	RET
 0016	     40B2	MOV #10,&0
 0018	     000A
 001A	     0000
 001C	     4034	MOV #0,R4
 001E	     0000
 0020	     4035	MOV #10,R5
 0022	     000A
 0024	     4036	MOV #0,R6
 0026	     0000
 0028	     4237	MOV #8,R7
 002A	     12B0	CALL #0
 002C	     0000
 002E	     4130	RET
