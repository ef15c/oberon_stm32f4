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
testSFuncs3 E31C1F2B Flash   224
imports:
	testSFuncs2 6353DF1C
type descriptors
 0006 FFFF FFFF FFFF
data     6
strings
bonjour|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 00CE
fixup procedures chains
 009C     1	 0004
fixup handlers chains
fixup data chains
 00A8     0	 0000
 0090     1	 0003
 0098     1	 0002
fixup constants chains
 0086     0	 0008
fixup types chains
entry =  00CE
code   208
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
 003C	     400F	MOV PC,R15
 003E	     803F	SUB #62,R15
 0040	     003E
 0042	     4F81	MOV R15,18(SP)
 0044	     0012
 0046	     40B1	MOV #0,18(SP)
 0048	     0000
 004A	     0012
 004C	     410F	MOV SP,R15
 004E	     523F	ADD #8,R15
 0050	     4F81	MOV R15,18(SP)
 0052	     0012
 0054	     4181	MOV SP,18(SP)
 0056	     0012
 0058	     8391	SUB #1,18(SP)
 005A	     0012
 005C	     23FD	JNE #-3, goes to  0058
 005E	     5391	ADD #1,18(SP)
 0060	     0012
 0062	     9381	CMP #0,18(SP)
 0064	     0012
 0066	     23FB	JNE #-5, goes to  005E
 0068	     40B1	MOV #6,18(SP)
 006A	     0006
 006C	     0012
 006E	     40B1	MOV #100,6(SP)
 0070	     0064
 0072	     0006
 0074	     4191	MOV 18(SP),16(SP)
 0076	     0012
 0078	     0010
 007A	     5031	ADD #20,SP
 007C	     0014
 007E	     4130	RET
 0080	     8031	SUB #16,SP
 0082	     0010
 0084	     4038	MOV #6,R8
 0086	     0006
 0088	     4408	MOV R4,R8
 008A	     4508	MOV R5,R8
 008C	     4708	MOV R7,R8
 008E	     403A	MOV #40,R10
 0090	     0028
 0092	     532A	ADD #2,R10
 0094	     4A08	MOV R10,R8
 0096	     4038	MOV #50,R8
 0098	     0032
 009A	     4038	MOV #56,R8
 009C	     0038
 009E	     400A	MOV PC,R10
 00A0	     803A	SUB #160,R10
 00A2	     00A0
 00A4	     4A08	MOV R10,R8
 00A6	     4038	MOV #72,R8
 00A8	     0048
 00AA	     410A	MOV SP,R10
 00AC	     523A	ADD #8,R10
 00AE	     4A08	MOV R10,R8
 00B0	     4108	MOV SP,R8
 00B2	     8318	SUB #1,R8
 00B4	     23FE	JNE #-2, goes to  00B2
 00B6	     5318	ADD #1,R8
 00B8	     9308	CMP #0,R8
 00BA	     23FD	JNE #-3, goes to  00B6
 00BC	     4038	MOV #6,R8
 00BE	     0006
 00C0	     40B1	MOV #100,6(SP)
 00C2	     0064
 00C4	     0006
 00C6	     4809	MOV R8,R9
 00C8	     5031	ADD #16,SP
 00CA	     0010
 00CC	     4130	RET
 00CE	     4130	RET
