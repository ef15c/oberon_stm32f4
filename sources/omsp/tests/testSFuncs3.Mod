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
testSFuncs3 E31C1F2B Flash   228
imports:
	testSFuncs2 E55368AA
type descriptors
 0006 FFFF FFFF FFFF
data     6
strings
bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 00D2
fixup procedures chains
 00A2     0	 0000
 009E     1	 0004
fixup handlers chains
fixup data chains
 00A6     0	 0000
 0092     1	 0003
 009A     1	 0002
fixup constants chains
 0088     0	 0008
fixup types chains
entry =  00D2
code   212
 0000	     8031	SUB #20,SP
 0002	     0014
 0004	     40B1	MOV #0,0(SP)
 0006	     0000
 0008	     0000
 000A	     4191	MOV 30(SP),0(SP)
 000C	     001E
 000E	     0000
 0010	     4191	MOV 26(SP),0(SP)
 0012	     001A
 0014	     0000
 0016	     4191	MOV 24(SP),0(SP)
 0018	     0018
 001A	     0000
 001C	     410F	MOV SP,R15
 001E	     503F	ADD #22,R15
 0020	     0016
 0022	     4F81	MOV R15,0(SP)
 0024	     0000
 0026	     403F	MOV #0,R15
 0028	     0000
 002A	     532F	ADD #2,R15
 002C	     4F81	MOV R15,0(SP)
 002E	     0000
 0030	     40B1	MOV #0,0(SP)
 0032	     0000
 0034	     0000
 0036	     40B1	MOV #0,0(SP)
 0038	     0000
 003A	     0000
 003C	     40B1	MOV #0,0(SP)
 003E	     0000
 0040	     0000
 0042	     40B1	MOV #0,0(SP)
 0044	     0000
 0046	     0000
 0048	     410F	MOV SP,R15
 004A	     503F	ADD #6,R15
 004C	     0006
 004E	     4F81	MOV R15,0(SP)
 0050	     0000
 0052	     410F	MOV SP,R15
 0054	     503F	ADD #14,R15
 0056	     000E
 0058	     4F81	MOV R15,0(SP)
 005A	     0000
 005C	     8391	SUB #1,0(SP)
 005E	     0000
 0060	     23FD	JNE #-3, goes to  005C
 0062	     5391	ADD #1,0(SP)
 0064	     0000
 0066	     9381	CMP #0,0(SP)
 0068	     0000
 006A	     23FB	JNE #-5, goes to  0062
 006C	     40B1	MOV #6,0(SP)
 006E	     0006
 0070	     0000
 0072	     40B1	MOV #100,12(SP)
 0074	     0064
 0076	     000C
 0078	     41A1	MOV @SP,2(SP)
 007A	     0002
 007C	     5031	ADD #20,SP
 007E	     0014
 0080	     4130	RET
 0082	     8031	SUB #16,SP
 0084	     0010
 0086	     4038	MOV #6,R8
 0088	     0006
 008A	     4408	MOV R4,R8
 008C	     4508	MOV R5,R8
 008E	     4708	MOV R7,R8
 0090	     403A	MOV #40,R10
 0092	     0028
 0094	     532A	ADD #2,R10
 0096	     4A08	MOV R10,R8
 0098	     4038	MOV #50,R8
 009A	     0032
 009C	     4038	MOV #56,R8
 009E	     0038
 00A0	     4038	MOV #62,R8
 00A2	     003E
 00A4	     4038	MOV #68,R8
 00A6	     0044
 00A8	     410A	MOV SP,R10
 00AA	     532A	ADD #2,R10
 00AC	     4A08	MOV R10,R8
 00AE	     410A	MOV SP,R10
 00B0	     503A	ADD #10,R10
 00B2	     000A
 00B4	     4A08	MOV R10,R8
 00B6	     8318	SUB #1,R8
 00B8	     23FE	JNE #-2, goes to  00B6
 00BA	     5318	ADD #1,R8
 00BC	     9308	CMP #0,R8
 00BE	     23FD	JNE #-3, goes to  00BA
 00C0	     4038	MOV #6,R8
 00C2	     0006
 00C4	     40B1	MOV #100,8(SP)
 00C6	     0064
 00C8	     0008
 00CA	     4809	MOV R8,R9
 00CC	     5031	ADD #16,SP
 00CE	     0010
 00D0	     4130	RET
 00D2	     4130	RET
