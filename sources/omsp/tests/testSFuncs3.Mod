MODULE testSFuncs3;
  IMPORT SYSTEM, TF := testSFuncs2;

  TYPE rt = RECORD
      a, b, c: INTEGER
    END;
    prt = POINTER TO rt;
    at = ARRAY 3 OF INTEGER;

  VAR g: rt;

  PROCEDURE p;								(* stack frame AaaaaaPRRrrrrr BSsVv@@ *)
    VAR v: INTEGER; s: SET;
      b: BOOLEAN;
      r: rt; pr!: prt;
      a: at;
  BEGIN
    REPEAT DEC(v) UNTIL SYSTEM.COND(1);
    REPEAT INC(v) UNTIL SYSTEM.CMP(v, 0, 1);
    v := SYSTEM.ADR(TF.r.b);
    v := SYSTEM.ADR(TF.v1);
    v := SYSTEM.ADR(TF.p);
    v := SYSTEM.ADR(p);
    v := SYSTEM.ADR(g);
    v := SYSTEM.ADR(r);
    v := SYSTEM.ADR(a);
    v := SYSTEM.SIZE(rt);
    pr := SYSTEM.VAL(prt, 100);
    s := SYSTEM.VAL(SET, v);
    v := SYSTEM.REG(2)
  END p;

END testSFuncs3.


OMSPTool.DecObj testSFuncs3.mpc
decode testSFuncs3.mpc
testSFuncs3 E31C1F2B Flash   108
imports:
	testSFuncs2 6353DF1C
type descriptors
 0006 FFFF FFFF FFFF
data     6
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0062
fixup procedures chains
 0026     1	 0004
fixup handlers chains
fixup data chains
 0036     0	 0000
 0016     1	 0003
 0020     1	 0002
fixup constants chains
fixup types chains
entry =  0062
code   100
 0000	     8031	SUB #20,SP
 0002	     0014
 0004	     8391	SUB #1,18(SP)
 0006	     0012
 0008	     23FD	JNE #-3, goes to  0004
 000A	     5391	ADD #1,18(SP)
 000C	     0012
 000E	     9381	CMP #0,18(SP)
 0010	     0012
 0012	     23FB	JNE #-5, goes to  000A
 0014	     403F	MOV #0,R15
 0016	     0000
 0018	     532F	ADD #2,R15
 001A	     4F81	MOV R15,18(SP)
 001C	     0012
 001E	     40B1	MOV #0,18(SP)
 0020	     0000
 0022	     0012
 0024	     40B1	MOV #0,18(SP)
 0026	     0000
 0028	     0012
 002A	     400F	MOV PC,R15
 002C	     803F	SUB #44,R15
 002E	     002C
 0030	     4F81	MOV R15,18(SP)
 0032	     0012
 0034	     40B1	MOV #0,18(SP)
 0036	     0000
 0038	     0012
 003A	     410F	MOV SP,R15
 003C	     523F	ADD #8,R15
 003E	     4F81	MOV R15,18(SP)
 0040	     0012
 0042	     4181	MOV SP,18(SP)
 0044	     0012
 0046	     40B1	MOV #6,18(SP)
 0048	     0006
 004A	     0012
 004C	     4291	MOV &100,6(SP)
 004E	     0064
 0050	     0006
 0052	     4191	MOV 18(SP),16(SP)
 0054	     0012
 0056	     0010
 0058	     4281	MOV SR,18(SP)
 005A	     0012
 005C	     5031	ADD #20,SP
 005E	     0014
 0060	     4130	RET
 0062	     4130	RET
