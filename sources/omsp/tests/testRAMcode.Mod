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

OMSPP.Compile testRAMcode.Mod ~
OMSPL.Link 32 4000H 200H testRAMcode ~
  linking msp430g2553 testRAMcode*
    flash   60, data   32, stack  480 bytes

OMSPTool.DecObj testRAMcode.mpc
decode testRAMcode.mpc
testRAMcode 6ABCB6A2
code executed from RAM
imports:
	msp430g2553 BBD31A01

section     0	r    2	i
fixups:

section     1	c   30	module body
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
 0014	     8392	SUB #1,&19
 0016	     0013
 0018	     23FD	JNE $-4, goes to  0014
 001A	     3FF7	JMP $-16, goes to  000A
 001C	     4130	RET
fixups:
 0017	s0.0

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1
