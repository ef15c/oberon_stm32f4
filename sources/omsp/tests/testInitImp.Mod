MODULE testInitImp;
  IMPORT M := msp430g2553, testInit;

 VAR i: INTEGER;
BEGIN M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  REPEAT testInit.toggleP10;
    i := 50000; REPEAT DEC(i) UNTIL i = 0
  UNTIL FALSE
END testInitImp.

OMSPTool.DecObj testInitImp.mpc
decode testInitImp.mpc
testInitImp 0106A11F Flash    30
imports:
	msp430g2553 8250CA0E
	testInit BBBED741
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
 0008     2	 0001
fixup handlers chains
fixup data chains
 0016     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    30
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     12B0	CALL #0
 0008	     0000
 000A	     40B2	MOV #-15536,&0
 000C	     C350
 000E	     0000
 0010	     8392	SUB #1,&14
 0012	     000E
 0014	     9382	CMP #0,&18
 0016	     0012
 0018	     23FB	JNE #-5, goes to  0010
 001A	     3FF5	JMP #-11, goes to  0006
 001C	     4130	RET
