MODULE* testRAMcode;
  IMPORT M := msp430g2553;

  VAR i: INTEGER;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  BIS(M.P1DIR^, {0}); (* Set P1.0 to output direction *)

  REPEAT
    XOR(M.P1OUT^, {0}); (* Toggle P1.0 using exclusive-OR *)

    i := 50000; (* Delay *)
    REPEAT DEC(i) UNTIL i = 0
  UNTIL FALSE
END testRAMcode.

OMSPTool.DecObj testRAMcode.mpc
decode testRAMcode.mpc
testRAMcode 633E8DCC Flash    34
code executed from RAM
imports:
	msp430g2553 8250CA0E
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 001A     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    34
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     D3D2	BIS.B #1,&34
 0008	     0022
 000A	     E3D2	XOR.B #1,&33
 000C	     0021
 000E	     40B2	MOV #-15536,&0
 0010	     C350
 0012	     0000
 0014	     8392	SUB #1,&18
 0016	     0012
 0018	     9382	CMP #0,&22
 001A	     0016
 001C	     23FB	JNE #-5, goes to  0014
 001E	     3FF5	JMP #-11, goes to  000A
 0020	     4130	RET
