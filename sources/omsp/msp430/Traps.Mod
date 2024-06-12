MODULE Traps; (*runtime module implementing the trap handlers*)
  IMPORT SYSTEM, M := msp430g2553;

PROCEDURE Assert*;
  VAR p0: SET*;
BEGIN SYSTEM.GET(M.P1OUT, SYSTEM.VAL(BYTE, p0)); SYSTEM.PUT(M.P1OUT, SYSTEM.VAL(BYTE, p0 + {0}));
  REPEAT UNTIL FALSE
END Assert;

END Traps.

OMSPTool.DecObj Traps.mpc

Stack allocation:
OMSPTool 10.06.24
decode Traps.mpc
Traps D6D85184    44
imports:
	msp430g2553 3E53F538
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
	Assert 0000
entries
 0016 0000
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  0016
code
 00000000	     8321	SUB #2,SP
 00000002	     42D1	MOV.B &33,0(SP)
 00000004	     0021
 00000006	     0000
 00000008	     412F	MOV @SP,R15
 0000000A	     D31F	BIS #1,R15
 0000000C	     4FC2	MOV.B R15,&33
 0000000E	     0021
 00000010	     3FFF	JMP #-1, goes to  00000010
 00000012	     5321	ADD #2,SP
 00000014	     4130	RET
 00000016	     4130	RET

Register allocation:
decode Traps.mpc
Traps D6D95184    36
imports:
	msp430g2553 3E53F538
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

commands:
	Assert 0000
entries
 000E 0000
pointer refs

fixup procedures chains
fixup handlers chains
fixup data chains
fixup type chains
entry =  000E
code
 00000000	     4254	MOV.B &33,R4
 00000002	     0021
 00000004	     D314	BIS #1,R4
 00000006	     44C2	MOV.B R4,&33
 00000008	     0021
 0000000A	     3FFF	JMP #-1, goes to  0000000A
 0000000C	     4130	RET
 0000000E	     4130	RET
