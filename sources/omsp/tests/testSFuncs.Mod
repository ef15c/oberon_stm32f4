MODULE testSFuncs;
  PROCEDURE p;
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

OMSPTool.DecObj testSFuncs.mpc
decode testSFuncs.mpc
testSFuncs E3E91F2A Flash    62
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 003C
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  003C
code    62
 0000	     8031	SUB #6,SP
 0002	     0006
 0004	     9381	CMP #0,2(SP)
 0006	     0002
 0008	     3404	JGE #4, goes to  0012
 000A	     411F	MOV 2(SP),R15
 000C	     0002
 000E	     E33F	XOR #-1,R15
 0010	     531F	ADD #1,R15
 0012	     4F81	MOV R15,0(SP)
 0014	     0000
 0016	     B391	BIT #1,0(SP)
 0018	     0000
 001A	     2402	JEQ #2, goes to  0020
 001C	     431F	MOV #1,R15
 001E	     3C01	JMP #1, goes to  0022
 0020	     430F	MOV #0,R15
 0022	     4FC1	MOV.B R15,4(SP)
 0024	     0004
 0026	     41D1	MOV.B 4(SP),2(SP)
 0028	     0004
 002A	     0002
 002C	     41E1	MOV.B @SP,5(SP)
 002E	     0005
 0030	     41D1	MOV.B 5(SP),0(SP)
 0032	     0005
 0034	     0000
 0036	     5031	ADD #6,SP
 0038	     0006
 003A	     4130	RET
 003C	     4130	RET
