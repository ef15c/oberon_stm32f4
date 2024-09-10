MODULE testSProcs2;
  IMPORT SYSTEM;

  VAR a: ARRAY 10 OF INTEGER; b: ARRAY 20 OF CHAR;

BEGIN SYSTEM.COPY(SYSTEM.ADR(a), SYSTEM.ADR(b), 10)
END testSProcs2.

OMSPTool.DecObj testSProcs2.mpc
decode testSProcs2.mpc
testSProcs2 C77404D3 Flash    24
imports:
type descriptors

data    40
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 0002     0	 0000
 0006     0	 0014
fixup constants chains
fixup types chains
entry =  0000
code    24
 0000	     403F	MOV #0,R15
 0002	     0000
 0004	     403E	MOV #0,R14
 0006	     0000
 0008	     403D	MOV #10,R13
 000A	     000A
 000C	     4FBE	MOV @R15+,0(R14)
 000E	     0000
 0010	     532E	ADD #2,R14
 0012	     831D	SUB #1,R13
 0014	     23FB	JNE #-5, goes to  000C
 0016	     4130	RET
