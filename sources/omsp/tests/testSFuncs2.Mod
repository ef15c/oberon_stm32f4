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
testSFuncs2 DD62831C Flash   124
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
 004C 0000 0014 0016 0010 0034
fixup procedures chains
 0054( 0064)     0	 0010
 0068( 0078)     0	 0034
fixup handlers chains
fixup data chains
 0040( 0050)     0	 0014
 005A( 006A)     0	 0000
fixup constants chains
 0062( 0072)     0	 0008
fixup types chains
entry =  004C
code   108
 0000( 0010)	     8031	SUB #12,SP
 0002( 0012)	     000C
 0004( 0014)	     4191	MOV 20(SP),0(SP)
 0006( 0016)	     0014
 0008( 0018)	     0000
 000A( 001A)	     4191	MOV 16(SP),0(SP)
 000C( 001C)	     0010
 000E( 001E)	     0000
 0010( 0020)	     40B1	MOV #5,0(SP)
 0012( 0022)	     0005
 0014( 0024)	     0000
 0016( 0026)	     B0B1	BIT #3,0(SP)
 0018( 0028)	     0003
 001A( 002A)	     0000
 001C( 002C)	     27FC	JEQ #-4, goes to  0016
 001E( 002E)	     5031	ADD #12,SP
 0020( 0030)	     000C
 0022( 0032)	     4130	RET
 0024( 0034)	     8031	SUB #10,SP
 0026( 0036)	     000A
 0028( 0038)	     4508	MOV R5,R8
 002A( 003A)	     4708	MOV R7,R8
 002C( 003C)	     4038	MOV #5,R8
 002E( 003E)	     0005
 0030( 0040)	     B038	BIT #3,R8
 0032( 0042)	     0003
 0034( 0044)	     27FD	JEQ #-3, goes to  0030
 0036( 0046)	     5031	ADD #10,SP
 0038( 0048)	     000A
 003A( 004A)	     4130	RET
 003C( 004C)	     40B2	MOV #10,&0
 003E( 004E)	     000A
 0040( 0050)	     0000
 0042( 0052)	     1230	PUSH #10
 0044( 0054)	     000A
 0046( 0056)	     1230	PUSH #0
 0048( 0058)	     0000
 004A( 005A)	     1230	PUSH #8
 004C( 005C)	     0008
 004E( 005E)	     1230	PUSH #0
 0050( 0060)	     0000
 0052( 0062)	     12B0	CALL #0
 0054( 0064)	     0000
 0056( 0066)	     5231	ADD #8,SP
 0058( 0068)	     4034	MOV #72,R4
 005A( 006A)	     0048
 005C( 006C)	     4035	MOV #10,R5
 005E( 006E)	     000A
 0060( 0070)	     4036	MOV #80,R6
 0062( 0072)	     0050
 0064( 0074)	     4237	MOV #8,R7
 0066( 0076)	     12B0	CALL #0
 0068( 0078)	     0000
 006A( 007A)	     4130	RET
