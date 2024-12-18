MODULE testFunc;

  VAR i: INTEGER;

  PROCEDURE SumI(a, b: INTEGER): INTEGER;
  BEGIN
    RETURN a + b
  END SumI;

  PROCEDURE SumIR(a, b: INTEGER*): INTEGER;
  BEGIN
    RETURN a + b
  END SumIR;

BEGIN
  i := i + SumI(1, 2);
  i := i + SumIR(1, 2)
END testFunc.

OMSPTool.DecObj testFunc.mpc
decode testFunc.mpc
testFunc 38F4692B Flash    56
imports:
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0010
fixup procedures chains
 0016     0	 0000
 002A     0	 000A
fixup handlers chains
fixup data chains
 0034     0	 0000
fixup constants chains
fixup types chains
entry =  0010
code    56
 0000	     411F	MOV 4(SP),R15
 0002	     0004
 0004	     511F	ADD 2(SP),R15
 0006	     0002
 0008	     4130	RET
 000A	     4504	MOV R5,R4
 000C	     5604	ADD R6,R4
 000E	     4130	RET
 0010	     1213	PUSH #1
 0012	     1223	PUSH #2
 0014	     12B0	CALL #0
 0016	     0000
 0018	     5221	ADD #4,SP
 001A	     421E	MOV &0,R14
 001C	     0000
 001E	     5F0E	ADD R15,R14
 0020	     4E82	MOV R14,&28
 0022	     001C
 0024	     4315	MOV #1,R5
 0026	     4326	MOV #2,R6
 0028	     12B0	CALL #0
 002A	     0000
 002C	     421F	MOV &34,R15
 002E	     0022
 0030	     540F	ADD R4,R15
 0032	     4F82	MOV R15,&46
 0034	     002E
 0036	     4130	RET
