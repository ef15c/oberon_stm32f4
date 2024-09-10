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


OMSPTool.DecObj testLoadAdr.mpc
decode testLoadAdr.mpc
testLoadAdr 07B5CAD6 Flash    64
imports:
	Traps 37B3757C
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0024
fixup procedures chains
 0026( 002E)     0	 0008
 0034( 003C)     0	 001A
fixup handlers chains
fixup data chains
 002C( 0034)     0	 0000
fixup constants chains
 0030( 0038)     0	 0000
fixup types chains
entry =  0024
code    56
 0000( 0008)	     411F	MOV 2(SP),R15
 0002( 000A)	     0002
 0004( 000C)	     439F	MOV #1,0(R15)
 0006( 000E)	     0000
 0008( 0010)	     411F	MOV 2(SP),R15
 000A( 0012)	     0002
 000C( 0014)	     43AF	MOV #2,2(R15)
 000E( 0016)	     0002
 0010( 0018)	     4130	RET
 0012( 001A)	     4394	MOV #1,0(R4)
 0014( 001C)	     0000
 0016( 001E)	     43A4	MOV #2,2(R4)
 0018( 0020)	     0002
 001A( 0022)	     4130	RET
 001C( 0024)	     1230	PUSH #0
 001E( 0026)	     0000
 0020( 0028)	     1230	PUSH #0
 0022( 002A)	     0000
 0024( 002C)	     12B0	CALL #0
 0026( 002E)	     0000
 0028( 0030)	     5221	ADD #4,SP
 002A( 0032)	     4034	MOV #34,R4
 002C( 0034)	     0022
 002E( 0036)	     4035	MOV #30,R5
 0030( 0038)	     001E
 0032( 003A)	     12B0	CALL #0
 0034( 003C)	     0000
 0036( 003E)	     4130	RET
