MODULE testSFuncs2;
  VAR t: ARRAY 10 OF INTEGER;
    v1: INTEGER;

  PROCEDURE p(t: ARRAY OF INTEGER*; s: ARRAY OF CHAR*);
    VAR v: INTEGER*;
      u: ARRAY 5 OF INTEGER;
  BEGIN
    v := LEN(t);
    v := LEN(s);
    v := LEN(u)
  END p;
BEGIN
  v1 := LEN(t);
  p(t, "bonjour")
END testSFuncs2.


OMSPTool.DecObj testSFuncs2.mpc

no leaf:
decode testSFuncs2.mpc
testSFuncs2 E31B1F2B Flash    66
imports:
type descriptors

data    22
strings
bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 001C
fixup procedures chains
 0034     0	 0000
fixup handlers chains
fixup data chains
 0020     0	 0014
 0028     0	 0000
fixup constants chains
 0030     0	 0000
fixup types chains
entry =  001C
code    58
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
 0016	     5031	ADD #12,SP
 0018	     000C
 001A	     4130	RET
 001C	     40B2	MOV #10,&0
 001E	     000A
 0020	     0000
 0022	     1230	PUSH #10
 0024	     000A
 0026	     1230	PUSH #0
 0028	     0000
 002A	     1230	PUSH #8
 002C	     0008
 002E	     1230	PUSH #0
 0030	     0000
 0032	     12B0	CALL #0
 0034	     0000
 0036	     5231	ADD #8,SP
 0038	     4130	RET

leaf:
decode testSFuncs2.mpc
testSFuncs2 E31B1F2B Flash    52
imports:
type descriptors

data    22
strings
bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0012
fixup procedures chains
 0028     0	 0000
fixup handlers chains
fixup data chains
 0016     0	 0014
 001A     0	 0000
fixup constants chains
 0022     0	 0000
fixup types chains
entry =  0012
code    44
 0000	     8031	SUB #10,SP
 0002	     000A
 0004	     4508	MOV R5,R8
 0006	     4708	MOV R7,R8
 0008	     4038	MOV #5,R8
 000A	     0005
 000C	     5031	ADD #10,SP
 000E	     000A
 0010	     4130	RET
 0012	     40B2	MOV #10,&0
 0014	     000A
 0016	     0000
 0018	     4034	MOV #0,R4
 001A	     0000
 001C	     4035	MOV #10,R5
 001E	     000A
 0020	     4036	MOV #0,R6
 0022	     0000
 0024	     4237	MOV #8,R7
 0026	     12B0	CALL #0
 0028	     0000
 002A	     4130	RET
