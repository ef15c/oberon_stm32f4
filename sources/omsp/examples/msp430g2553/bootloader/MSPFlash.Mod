MODULE* MSPFlash;
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE flashBlock*(source, dest: PINTEGER*; length: INTEGER*);
  (* Flash length bytes from address dest to address source
    source, dest and length must be even *) 
  BEGIN ASSERT(~ODD(SYSTEM.VAL(INTEGER, source))); ASSERT(~ODD(SYSTEM.VAL(INTEGER, dest)));
    ASSERT(~ODD(SYSTEM.VAL(INTEGER, length)));
    REPEAT UNTIL ~BIT(M.FCTL3^, M.BUSY); (* Wait for flash controller availability *)
    (* Setup block write *)
    M.FCTL3^ := M.FWKEY; (* Clear lock *)
    WHILE length > 0 DO
      M.FCTL1^ := M.FWKEY + M.BLKWRT + M.WRT; (* Enable block write *)
      REPEAT dest^ := source^; INC(SYSTEM.VAL(INTEGER, dest), 2); INC(SYSTEM.VAL(INTEGER, source), 2); (* Write location *)
        DEC(length, 2); (* Two byte written in a single access *)
        REPEAT UNTIL BIT(M.FCTL3^, M.WAIT); (* Wait for end of writing word *)
        (* Detect cross block border *)
        IF ~BIT(SYSTEM.VAL(INTEGER, dest), {0..5}) THEN (* Another block *)
          M.FCTL1^ := M.FWKEY + M.WRT; (* Set BLKWRT = 0 *)
          REPEAT UNTIL ~BIT(M.FCTL3^, M.BUSY) (* Wait for flash controller availability *)
        END;
      UNTIL (length <= 0) OR ~BIT(M.FCTL1^, M.BLKWRT)
    END;
    M.FCTL1^ := M.FWKEY; (* Clear WRT, BLKWRT *)
    REPEAT UNTIL ~BIT(M.FCTL3^, M.BUSY); (* Wait for flash controller availability *)
    M.FCTL3^ := M.FWKEY + M.LOCK; (* Set lock *)
  END flashBlock;


END MSPFlash.

OMSPP.Compile MSPFlash.Mod~

OMSPTool.DecSym MSPFlash.sms
decode MSPFlash.sms
MSPFlash 6F801689  3
   9 flashBlock [0  form = 10 [^9] leaf UR 00F0( class = 2 R6 [^4] class = 2 R5 [^7] class = 2 R4 [^7])]     1

OMSPTool.DecObj MSPFlash.mpc
decode MSPFlash.mpc
MSPFlash 6F801689
code executed from RAM
imports:
	msp430g2553 BBD31A01

section     0	c   94	flashBlock
 0000	     B392	BIT #1,&300
 0002	     012C
 0004	     23FD	JNE $-4, goes to  0000
 0006	     40B2	MOV #-23296,&300
 0008	     A500
 000A	     012C
 000C	     4307	MOV #0,R7
 000E	     9607	CMP R6,R7
 0010	     341C	JGE $+58, goes to  004A
 0012	     40B2	MOV #-23104,&296
 0014	     A5C0
 0016	     0128
 0018	     44A5	MOV @R4,0(R5)
 001A	     0000
 001C	     5325	ADD #2,R5
 001E	     5324	ADD #2,R4
 0020	     8326	SUB #2,R6
 0022	     B2B2	BIT #8,&300
 0024	     012C
 0026	     27FD	JEQ $-4, goes to  0022
 0028	     B035	BIT #63,R5
 002A	     003F
 002C	     2006	JNE $+14, goes to  003A
 002E	     40B2	MOV #-23232,&296
 0030	     A540
 0032	     0128
 0034	     B392	BIT #1,&300
 0036	     012C
 0038	     23FD	JNE $-4, goes to  0034
 003A	     4307	MOV #0,R7
 003C	     9607	CMP R6,R7
 003E	     3404	JGE $+10, goes to  0048
 0040	     B0B2	BIT #128,&296
 0042	     0080
 0044	     0128
 0046	     23E8	JNE $-46, goes to  0018
 0048	     3FE1	JMP $-60, goes to  000C
 004A	     40B2	MOV #-23296,&296
 004C	     A500
 004E	     0128
 0050	     B392	BIT #1,&300
 0052	     012C
 0054	     23FD	JNE $-4, goes to  0050
 0056	     40B2	MOV #-23280,&300
 0058	     A510
 005A	     012C
 005C	     4130	RET
fixups:

section     1	c    2	module body
 0000	     4130	RET
fixups:

section     2	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:

entries:
    1    0
