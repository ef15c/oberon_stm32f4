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
testSFuncs3 E31C1F2B Flash   216
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
 00C6
fixup procedures chains
 009C     0	 0000
 0098     1	 0004
fixup handlers chains
fixup data chains
 00A0     0	 0000
 008C     1	 0003
 0094     1	 0002
fixup constants chains
 0082     0	 0008
fixup types chains
entry =  00C6
code   200
 0000	     8031	SUB #20,SP
 0002	     0014
 0004	     40B1	MOV #0,18(SP)
 0006	     0000
 0008	     0012
 000A	     4191	MOV 30(SP),18(SP)
 000C	     001E
 000E	     0012
 0010	     4191	MOV 26(SP),18(SP)
 0012	     001A
 0014	     0012
 0016	     4191	MOV 24(SP),18(SP)
 0018	     0018
 001A	     0012
 001C	     410F	MOV SP,R15
 001E	     503F	ADD #22,R15
 0020	     0016
 0022	     4F81	MOV R15,18(SP)
 0024	     0012
 0026	     403F	MOV #0,R15
 0028	     0000
 002A	     532F	ADD #2,R15
 002C	     4F81	MOV R15,18(SP)
 002E	     0012
 0030	     40B1	MOV #0,18(SP)
 0032	     0000
 0034	     0012
 0036	     40B1	MOV #0,18(SP)
 0038	     0000
 003A	     0012
 003C	     40B1	MOV #0,18(SP)
 003E	     0000
 0040	     0012
 0042	     40B1	MOV #0,18(SP)
 0044	     0000
 0046	     0012
 0048	     410F	MOV SP,R15
 004A	     523F	ADD #8,R15
 004C	     4F81	MOV R15,18(SP)
 004E	     0012
 0050	     4181	MOV SP,18(SP)
 0052	     0012
 0054	     8391	SUB #1,18(SP)
 0056	     0012
 0058	     23FD	JNE #-3, goes to  0054
 005A	     5391	ADD #1,18(SP)
 005C	     0012
 005E	     9381	CMP #0,18(SP)
 0060	     0012
 0062	     23FB	JNE #-5, goes to  005A
 0064	     40B1	MOV #6,18(SP)
 0066	     0006
 0068	     0012
 006A	     40B1	MOV #100,6(SP)
 006C	     0064
 006E	     0006
 0070	     4191	MOV 18(SP),16(SP)
 0072	     0012
 0074	     0010
 0076	     5031	ADD #20,SP
 0078	     0014
 007A	     4130	RET
 007C	     8031	SUB #16,SP
 007E	     0010
 0080	     4038	MOV #6,R8
 0082	     0006
 0084	     4408	MOV R4,R8
 0086	     4508	MOV R5,R8
 0088	     4708	MOV R7,R8
 008A	     403A	MOV #40,R10
 008C	     0028
 008E	     532A	ADD #2,R10
 0090	     4A08	MOV R10,R8
 0092	     4038	MOV #50,R8
 0094	     0032
 0096	     4038	MOV #56,R8
 0098	     0038
 009A	     4038	MOV #62,R8
 009C	     003E
 009E	     4038	MOV #68,R8
 00A0	     0044
 00A2	     410A	MOV SP,R10
 00A4	     523A	ADD #8,R10
 00A6	     4A08	MOV R10,R8
 00A8	     4108	MOV SP,R8
 00AA	     8318	SUB #1,R8
 00AC	     23FE	JNE #-2, goes to  00AA
 00AE	     5318	ADD #1,R8
 00B0	     9308	CMP #0,R8
 00B2	     23FD	JNE #-3, goes to  00AE
 00B4	     4038	MOV #6,R8
 00B6	     0006
 00B8	     40B1	MOV #100,6(SP)
 00BA	     0064
 00BC	     0006
 00BE	     4809	MOV R8,R9
 00C0	     5031	ADD #16,SP
 00C2	     0010
 00C4	     4130	RET
 00C6	     4130	RET
