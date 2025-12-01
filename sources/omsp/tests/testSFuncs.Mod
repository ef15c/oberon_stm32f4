MODULE testSFuncs;
  PROCEDURE p*;
    VAR a, v: INTEGER;
      b: BOOLEAN; c: CHAR;
  BEGIN
    a := ABS(v);
    b := ODD(a);
    v := ORD(b);
    c := CHR(a);
    a := ORD(c)
  END p;

END testSFuncs.

OMSPP.Compile testSFuncs.Mod/s~
OMSPTool.DecObj testSFuncs.mpc
decode testSFuncs.mpc
testSFuncs 2EE74D58
imports:

section     0	c   64	p
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     9381	CMP #0,2(SP)
 0006	     0002
 0008	     3404	JGE $+10, goes to  0012
 000A	     411F	MOV 2(SP),R15
 000C	     0002
 000E	     E33F	XOR #-1,R15
 0010	     531F	ADD #1,R15
 0012	     4F81	MOV R15,0(SP)
 0014	     0000
 0016	     B391	BIT #1,0(SP)
 0018	     0000
 001A	     2402	JEQ $+6, goes to  0020
 001C	     431F	MOV #1,R15
 001E	     3C01	JMP $+4, goes to  0022
 0020	     430F	MOV #0,R15
 0022	     4FC1	MOV.B R15,4(SP)
 0024	     0004
 0026	     415F	MOV.B 4(SP),R15
 0028	     0004
 002A	     4F81	MOV R15,2(SP)
 002C	     0002
 002E	     41E1	MOV.B @SP,5(SP)
 0030	     0005
 0032	     415F	MOV.B 5(SP),R15
 0034	     0005
 0036	     4F81	MOV R15,0(SP)
 0038	     0000
 003A	     5031	ADD #6,SP
 003C	     0006
 003E	     4130	RET
fixups:

section     1	c    2	module body
 0000	     4130	RET
fixups:

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1    0
