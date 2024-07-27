MODULE testLoadAdr;
  IMPORT Traps;

  TYPE rec = RECORD
    x, y: INTEGER;
	END;

  VAR r1: rec;

  PROCEDURE p(VAR r: rec*);
  BEGIN
    r.x := 1; r.y := 2
  END p;

BEGIN
  p(r1)
END testLoadAdr.


OMSPTool.DecObj testLoadAdr.mpc ~

not leaf:
decode testLoadAdr.mpc
testLoadAdr D9473902    44
imports:
	Traps 45642D7E
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0012
fixup procedures chains
 001C     0	 0000
fixup handlers chains
fixup data chains
 0018     0	 0000
fixup type chains
 0014     0	 0000
entry =  0012
code    34
 0000	     411F	MOV 2(SP),R15
 0002	     0002
 0004	     439F	MOV #1,0(R15)
 0006	     0000
 0008	     411F	MOV 2(SP),R15
 000A	     0002
 000C	     43AF	MOV #2,2(R15)
 000E	     0002
 0010	     4130	RET
 0012	     1230	PUSH #0
 0014	     0000
 0016	     1230	PUSH #0
 0018	     0000
 001A	     12B0	CALL #0
 001C	     0000
 001E	     5221	ADD #4,SP
 0020	     4130	RET

leaf:
decode testLoadAdr.mpc
testLoadAdr D9473902    34
imports:
	Traps 45642D7E
type descriptors
 0004 FFFF FFFF FFFF
data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 000A
fixup procedures chains
 0014     0	 0000
fixup handlers chains
fixup data chains
 000C     0	 0000
fixup type chains
 0010     0	 0000
entry =  000A
code    24
 0000	     4394	MOV #1,0(R4)
 0002	     0000
 0004	     43A4	MOV #2,2(R4)
 0006	     0002
 0008	     4130	RET
 000A	     4034	MOV #0,R4
 000C	     0000
 000E	     4034	MOV #0,R4
 0010	     0000
 0012	     12B0	CALL #0
 0014	     0000
 0016	     4130	RET
