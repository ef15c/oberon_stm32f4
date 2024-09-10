MODULE testSFuncs3;
  IMPORT SYSTEM, TF := testSFuncs2;

  TYPE rt = RECORD
      a, b, c: INTEGER
    END;
    prt = POINTER TO rt;
    at = ARRAY 3 OF INTEGER;

  VAR g: rt;

  PROCEDURE p(VAR x: INTEGER; y: rt; VAR py: prt; z: INTEGER);
    VAR v: INTEGER; s: SET;
      b: BOOLEAN;
      r: rt; pr!: prt;
      a: at;
  BEGIN
    v := SYSTEM.ADR("bonjour");
    v := SYSTEM.ADR(x);
    v := SYSTEM.ADR(y);
    v := SYSTEM.ADR(py);
    v := SYSTEM.ADR(z);
    v := SYSTEM.ADR(TF.r.b);
    v := SYSTEM.ADR(TF.v1);
    v := SYSTEM.ADR(TF.p);
    v := SYSTEM.ADR(p);
    v := SYSTEM.ADR(g);
    v := SYSTEM.ADR(r);
    v := SYSTEM.ADR(a);
    REPEAT DEC(v) UNTIL SYSTEM.COND(1);
    REPEAT INC(v) UNTIL SYSTEM.CMP(v, 0, 1);
    v := SYSTEM.SIZE(rt);
    pr := SYSTEM.VAL(prt, 100);
    s := SYSTEM.VAL(SET, v);
  END p;

  PROCEDURE q(VAR x: INTEGER*; y: rt*; VAR py: prt*);
    VAR v: INTEGER*; s: SET*;
      b: BOOLEAN;
      r: rt; pr!: prt;
      a: at;
  BEGIN
    v := SYSTEM.ADR("bonjour");
    v := SYSTEM.ADR(x);
    v := SYSTEM.ADR(y);
    v := SYSTEM.ADR(py);
    v := SYSTEM.ADR(TF.r.b);
    v := SYSTEM.ADR(TF.v1);
    v := SYSTEM.ADR(TF.p);
    v := SYSTEM.ADR(p);
    v := SYSTEM.ADR(g);
    v := SYSTEM.ADR(r);
    v := SYSTEM.ADR(a);
    REPEAT DEC(v) UNTIL SYSTEM.COND(1);
    REPEAT INC(v) UNTIL SYSTEM.CMP(v, 0, 1);
    v := SYSTEM.SIZE(rt);
    pr := SYSTEM.VAL(prt, 100);
    s := SYSTEM.VAL(SET, v);
  END q;

END testSFuncs3.


OMSPTool.DecObj testSFuncs3.mpc
decode testSFuncs3.mpc
testSFuncs3 4B322F63 Flash   228
imports:
	testSFuncs2 DD62831C
type descriptors
 0006 FFFF FFFF FFFF
data     6
strings
bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 00E2
fixup procedures chains
 00A2( 00B2)     0	 0010
 009E( 00AE)     1	 0004
fixup handlers chains
fixup data chains
 00A6( 00B6)     0	 0000
 0092( 00A2)     1	 0003
 009A( 00AA)     1	 0002
fixup constants chains
 0088( 0098)     0	 0008
fixup types chains
entry =  00E2
code   212
 0000( 0010)	     8031	SUB #20,SP
 0002( 0012)	     0014
 0004( 0014)	     40B1	MOV #0,0(SP)
 0006( 0016)	     0000
 0008( 0018)	     0000
 000A( 001A)	     4191	MOV 30(SP),0(SP)
 000C( 001C)	     001E
 000E( 001E)	     0000
 0010( 0020)	     4191	MOV 26(SP),0(SP)
 0012( 0022)	     001A
 0014( 0024)	     0000
 0016( 0026)	     4191	MOV 24(SP),0(SP)
 0018( 0028)	     0018
 001A( 002A)	     0000
 001C( 002C)	     410F	MOV SP,R15
 001E( 002E)	     503F	ADD #22,R15
 0020( 0030)	     0016
 0022( 0032)	     4F81	MOV R15,0(SP)
 0024( 0034)	     0000
 0026( 0036)	     403F	MOV #0,R15
 0028( 0038)	     0000
 002A( 003A)	     532F	ADD #2,R15
 002C( 003C)	     4F81	MOV R15,0(SP)
 002E( 003E)	     0000
 0030( 0040)	     40B1	MOV #0,0(SP)
 0032( 0042)	     0000
 0034( 0044)	     0000
 0036( 0046)	     40B1	MOV #0,0(SP)
 0038( 0048)	     0000
 003A( 004A)	     0000
 003C( 004C)	     40B1	MOV #0,0(SP)
 003E( 004E)	     0000
 0040( 0050)	     0000
 0042( 0052)	     40B1	MOV #0,0(SP)
 0044( 0054)	     0000
 0046( 0056)	     0000
 0048( 0058)	     410F	MOV SP,R15
 004A( 005A)	     503F	ADD #6,R15
 004C( 005C)	     0006
 004E( 005E)	     4F81	MOV R15,0(SP)
 0050( 0060)	     0000
 0052( 0062)	     410F	MOV SP,R15
 0054( 0064)	     503F	ADD #14,R15
 0056( 0066)	     000E
 0058( 0068)	     4F81	MOV R15,0(SP)
 005A( 006A)	     0000
 005C( 006C)	     8391	SUB #1,0(SP)
 005E( 006E)	     0000
 0060( 0070)	     23FD	JNE #-3, goes to  005C
 0062( 0072)	     5391	ADD #1,0(SP)
 0064( 0074)	     0000
 0066( 0076)	     9381	CMP #0,0(SP)
 0068( 0078)	     0000
 006A( 007A)	     23FB	JNE #-5, goes to  0062
 006C( 007C)	     40B1	MOV #6,0(SP)
 006E( 007E)	     0006
 0070( 0080)	     0000
 0072( 0082)	     40B1	MOV #100,12(SP)
 0074( 0084)	     0064
 0076( 0086)	     000C
 0078( 0088)	     41A1	MOV @SP,2(SP)
 007A( 008A)	     0002
 007C( 008C)	     5031	ADD #20,SP
 007E( 008E)	     0014
 0080( 0090)	     4130	RET
 0082( 0092)	     8031	SUB #16,SP
 0084( 0094)	     0010
 0086( 0096)	     4038	MOV #6,R8
 0088( 0098)	     0006
 008A( 009A)	     4408	MOV R4,R8
 008C( 009C)	     4508	MOV R5,R8
 008E( 009E)	     4708	MOV R7,R8
 0090( 00A0)	     403A	MOV #40,R10
 0092( 00A2)	     0028
 0094( 00A4)	     532A	ADD #2,R10
 0096( 00A6)	     4A08	MOV R10,R8
 0098( 00A8)	     4038	MOV #50,R8
 009A( 00AA)	     0032
 009C( 00AC)	     4038	MOV #56,R8
 009E( 00AE)	     0038
 00A0( 00B0)	     4038	MOV #62,R8
 00A2( 00B2)	     003E
 00A4( 00B4)	     4038	MOV #68,R8
 00A6( 00B6)	     0044
 00A8( 00B8)	     410A	MOV SP,R10
 00AA( 00BA)	     532A	ADD #2,R10
 00AC( 00BC)	     4A08	MOV R10,R8
 00AE( 00BE)	     410A	MOV SP,R10
 00B0( 00C0)	     503A	ADD #10,R10
 00B2( 00C2)	     000A
 00B4( 00C4)	     4A08	MOV R10,R8
 00B6( 00C6)	     8318	SUB #1,R8
 00B8( 00C8)	     23FE	JNE #-2, goes to  00B6
 00BA( 00CA)	     5318	ADD #1,R8
 00BC( 00CC)	     9308	CMP #0,R8
 00BE( 00CE)	     23FD	JNE #-3, goes to  00BA
 00C0( 00D0)	     4038	MOV #6,R8
 00C2( 00D2)	     0006
 00C4( 00D4)	     40B1	MOV #100,8(SP)
 00C6( 00D6)	     0064
 00C8( 00D8)	     0008
 00CA( 00DA)	     4809	MOV R8,R9
 00CC( 00DC)	     5031	ADD #16,SP
 00CE( 00DE)	     0010
 00D0( 00E0)	     4130	RET
 00D2( 00E2)	     4130	RET
