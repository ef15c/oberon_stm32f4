MODULE boottest;
  IMPORT preserveMSPFlash, M := msp430g2553, Delay := msp430delay;

  VAR nbc: BYTE;

BEGIN  (* Stop watchdog timer from timing out during initial start-up. *)
    M.WDTCTL^ := M.WDTPW + M.WDTHOLD;

    BIS(M.P1DIR^, {6});

    nbc := 100;
    REPEAT Delay.CyclesX3(125000 DIV 3);
      XOR(M.P1OUT^, {6}); DEC(nbc)
	UNTIL nbc = 0;

	(* Reset in bootloader mode *)
    M.WDTCTL^ := {}
END boottest.

OMSPP.Compile boottest.Mod~
OMSPL.Link 32 3C00H 200H boottest~
  linking preserveMSPFlash msp430g2553 msp430delay boottest
    flash   64, data   98, stack  414 bytes

OMSPTool.DecObj boottest.mpc
decode boottest.mpc
boottest E114F654 Flash    44
imports:
	preserveMSPFlash 26F15285
	msp430g2553 F10488DC
	msp430delay EE6A4099
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures in code space chains
 0018     3	 0001
fixup handlers in vector space chains
fixup data in code space chains
 0022     0	 0000
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0000
code    44
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     D0F2	BIS.B #64,&34
 0008	     0040
 000A	     0022
 000C	     40F2	MOV.B #100,&0
 000E	     0064
 0010	     0000
 0012	     4034	MOV #-23870,R4
 0014	     A2C2
 0016	     12B0	CALL #0
 0018	     0000
 001A	     E0F2	XOR.B #64,&33
 001C	     0040
 001E	     0021
 0020	     83D2	SUB.B #1,&16
 0022	     0010
 0024	     23F6	JNE $-18, goes to  0012
 0026	     4382	MOV #0,&288
 0028	     0120
 002A	     4130	RET
