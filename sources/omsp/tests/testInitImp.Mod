MODULE testInitImp;
  IMPORT testInit;

 VAR i: INTEGER;
BEGIN
  REPEAT testInit.toggleP10;
    i := 50000; REPEAT DEC(i) UNTIL i = 0
  UNTIL FALSE
END testInitImp.

OMSPTool.DecObj testInitImp.mpc
decode testInitImp.mpc
testInitImp E94D4107 Flash    24
imports:
	testInit FB808D89
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
 0002     1	 0001
fixup handlers chains
fixup data chains
 0010     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    24
 0000	     12B0	CALL #0
 0002	     0000
 0004	     40B2	MOV #-15536,&0
 0006	     C350
 0008	     0000
 000A	     8392	SUB #1,&8
 000C	     0008
 000E	     9382	CMP #0,&12
 0010	     000C
 0012	     23FB	JNE #-5, goes to  000A
 0014	     3FF5	JMP #-11, goes to  0000
 0016	     4130	RET
