MODULE testSProcs2;
  IMPORT SYSTEM;

  VAR a: ARRAY 10 OF INTEGER; b: ARRAY 20 OF CHAR;

BEGIN SYSTEM.COPY(SYSTEM.ADR(a), SYSTEM.ADR(b), 10)
END testSProcs2.

OMSPTool.DecObj testSProcs2.mpc
decode testSProcs2.mpc
testSProcs2 C77404D3 Flash    18
imports:
type descriptors

data    40
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 0006     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    18
 0000	     403F	MOV #10,R15
 0002	     000A
 0004	     403E	MOV #0,R14
 0006	     0000
 0008	     4EBE	MOV @R14+,18(R14)
 000A	     0012
 000C	     831F	SUB #1,R15
 000E	     23FC	JNE $-6, goes to  0008
 0010	     4130	RET
