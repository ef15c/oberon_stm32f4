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

OM4P.Compile OMSPG.Mod/s~ OMSPP.Mod OMSPTool.Mod~
System.Free OMSPP OMSPL OMSPG OMSPTool OMSPD OMSPA~
OMSPP.Compile testFunc.Mod~

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

Version 4:
decode testFunc.mpc
testFunc 4A1F36F8
imports:
section     0	r    0	i

fixups:
section     1	c   10	SumI
 0000	     411F	MOV 4(SP),R15
 0002	     0004
 0004	     511F	ADD 2(SP),R15
 0006	     0002
 0008	     4130	RET
fixups:
section     2	c    6	SumIR
 0000	     4504	MOV R5,R4
 0002	     5604	ADD R6,R4
 0004	     4130	RET
fixups:
section     3	c   40	module body
 0000	     1213	PUSH #1
 0002	     1223	PUSH #2
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5221	ADD #4,SP
 000A	     421E	MOV &0,R14
 000C	     0000
 000E	     5F0E	ADD R15,R14
 0010	     4E82	MOV R14,&13
 0012	     000D
 0014	     4315	MOV #1,R5
 0016	     4326	MOV #2,R6
 0018	     12B0	CALL #0
 001A	     0000
 001C	     421F	MOV &19,R15
 001E	     0013
 0020	     540F	ADD R4,R15
 0022	     4F82	MOV R15,&31
 0024	     001F
 0026	     4130	RET
fixups:
 001B	  0     2     0
 0025	  0     0     0
 0007	  0     1     0
section     4	d   64	vectors table
 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
fixups:

entries:
    3

