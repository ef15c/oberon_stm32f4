MODULE testInitImp;
  IMPORT M := msp430g2553, testInit;

 VAR i: INTEGER;
BEGIN M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  REPEAT testInit.toggleP10;
    i := 50000; REPEAT DEC(i) UNTIL i = 0
  UNTIL FALSE
END testInitImp.

OMSPL.Link 32 4000H 200H testInitImp ~
  linking msp430g2553 testInit testInitImp
    flash   56, data    2, stack  510 bytes

OMSPTool.DecObj testInitImp.mpc
decode testInitImp.mpc
testInitImp 08849A71
imports:
	msp430g2553 BBD31A01
	testInit 1B108661

section     0	r    2	i
fixups:

section     1	c   26	module body
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     12B0	CALL #0
 0008	     0000
 000A	     40B2	MOV #-15536,&0
 000C	     C350
 000E	     0000
 0010	     8392	SUB #1,&15
 0012	     000F
 0014	     23FD	JNE $-4, goes to  0010
 0016	     3FF7	JMP $-16, goes to  0006
 0018	     4130	RET
fixups:
 0013	s0.0
 0009	s2.1

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1
