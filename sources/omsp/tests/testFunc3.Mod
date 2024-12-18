MODULE testBug6;

  PROCEDURE f(i: INTEGER*): INTEGER;
    RETURN i
  END f;

  PROCEDURE g(i: INTEGER);
  BEGIN i := f(i+1+f(i))
  END g;

BEGIN g(3)
END testBug6.

OMSPL.Link 32 4000H 200H testBug6 ~

OMSPTool.DecObj testBug6.mpc
decode testBug6.mpc
testBug6 06B14883 Flash    50
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0026
fixup procedures chains
 001E     0	 0000
 002C     0	 0004
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0026
code    50
 0000	     4504	MOV R5,R4
 0002	     4130	RET
 0004	     4114	MOV 2(SP),R4
 0006	     0002
 0008	     5314	ADD #1,R4
 000A	     1204	PUSH R4
 000C	     4115	MOV 4(SP),R5
 000E	     0004
 0010	     12B0	CALL #0
 0012	     0000
 0014	     4405	MOV R4,R5
 0016	     4134	POP R4
 0018	     5504	ADD R5,R4
 001A	     4405	MOV R4,R5
 001C	     12B0	CALL #18
 001E	     0012
 0020	     4481	MOV R4,2(SP)
 0022	     0002
 0024	     4130	RET
 0026	     1230	PUSH #3
 0028	     0003
 002A	     12B0	CALL #0
 002C	     0000
 002E	     5321	ADD #2,SP
 0030	     4130	RET
