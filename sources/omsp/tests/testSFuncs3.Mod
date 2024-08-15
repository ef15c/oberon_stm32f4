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
testSFuncs3 E31C1F2B Flash   112
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
 0066
fixup procedures chains
 0026     1	 0004
fixup handlers chains
fixup data chains
 0038     0	 0000
 0016     1	 0003
 0020     1	 0002
fixup constants chains
fixup types chains
entry =  0066
code   104
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
 0024	     403F	MOV #0,R15
 0026	     0000
 0028	     4F81	MOV R15,18(SP)
 002A	     0012
 002C	     400F	MOV PC,R15
 002E	     803F	SUB #46,R15
 0030	     002E
 0032	     4F81	MOV R15,18(SP)
 0034	     0012
 0036	     40B1	MOV #0,18(SP)
 0038	     0000
 003A	     0012
 003C	     410F	MOV SP,R15
 003E	     523F	ADD #8,R15
 0040	     4F81	MOV R15,18(SP)
 0042	     0012
 0044	     4181	MOV SP,18(SP)
 0046	     0012
 0048	     40B1	MOV #6,18(SP)
 004A	     0006
 004C	     0012
 004E	     4291	MOV &100,6(SP)
 0050	     0064
 0052	     0006
 0054	     4191	MOV 18(SP),16(SP)
 0056	     0012
 0058	     0010
 005A	     420F	MOV SR,R15
 005C	     4F81	MOV R15,18(SP)
 005E	     0012
 0060	     5031	ADD #20,SP
 0062	     0014
 0064	     4130	RET
 0066	     4130	RET
