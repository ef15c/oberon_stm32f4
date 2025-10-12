MODULE testLoadAdr;
  IMPORT Traps;

  TYPE rec = RECORD
    x, y: INTEGER;
	END;

  VAR r1: rec;

  PROCEDURE p(VAR r: rec);
  BEGIN
    r.x := 1; r.y := 2
  END p;

  PROCEDURE q(VAR r: rec*);
  BEGIN
    r.x := 1; r.y := 2
  END q;

BEGIN
  p(r1); q(r1)
END testLoadAdr.

OMSPP.Compile testLoadAdr.Mod~
OMSPTool.DecObj testLoadAdr.mpc
decode testLoadAdr.mpc
testLoadAdr 07B5CAD6 Flash    64
imports:
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 001C
fixup procedures in code space chains
 0026     0	 0000
 0034     0	 0012
fixup handlers in vector space chains
fixup data in code space chains
 002C     0	 0000
fixup constants in code space chains
 0030     0	 0000
fixup variables in constant space chains
fixup constants in constant space chains
entry =  001C
code    56
 0000	     411F	MOV 2(SP),R15
 0002	     0002
 0004	     439F	MOV #1,0(R15)
 0006	     0000
 0008	     411F	MOV 2(SP),R15
 000A	     0002
 000C	     43AF	MOV #2,2(R15)
 000E	     0002
 0010	     4130	RET
 0012	     4394	MOV #1,0(R4)
 0014	     0000
 0016	     43A4	MOV #2,2(R4)
 0018	     0002
 001A	     4130	RET
 001C	     1230	PUSH #0
 001E	     0000
 0020	     1230	PUSH #0
 0022	     0000
 0024	     12B0	CALL #0
 0026	     0000
 0028	     5221	ADD #4,SP
 002A	     4034	MOV #34,R4
 002C	     0022
 002E	     4035	MOV #30,R5
 0030	     001E
 0032	     12B0	CALL #0
 0034	     0000
 0036	     4130	RET
