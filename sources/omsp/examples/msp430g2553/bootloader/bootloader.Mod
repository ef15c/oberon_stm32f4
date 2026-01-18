MODULE bootloader;
  IMPORT SYSTEM, M := msp430g2553, MSPFlash, Types, Delay := msp430delay;

  CONST APP_START = SYSTEM.VAL(Types.PPROC, 0FFE2H);
    NOWHERE = SYSTEM.VAL(PBYTE, 0A000H); (*non mapped address*)
    BUF_SIZE = 64;

  VAR cc: CHAR; byte: BYTE; add, nbElt: INTEGER; address: PBYTE; buffer: ARRAY BUF_SIZE OF BYTE;

  PROCEDURE*(16+1) main_appli;
    (* Dummy aplication code for test
     * Will be replaced when flashing real application
     *)
  BEGIN
    (*
    /* Stop watchdog timer from timing out during initial start-up. */
    WDTCTL = WDTPW | WDTHOLD;

    P1DIR |= BIT6;
    P1OUT |= BIT3;
    P1REN |= BIT3;

	do {
		__delay_cycles(1250000);
		P1OUT ^= BIT6;
	} while ((P1IN & BIT3));
    *)
	(* Reset in bootloader mode *)
    M.WDTCTL^ := {}
  END main_appli;

  PROCEDURE toHexa(v: BYTE*): CHAR;
    VAR r: BYTE*;
  BEGIN IF v < 10 THEN r := ORD("0") ELSE r := ORD("A") - 10 END;
    INC(r, v)

    RETURN CHR(r)
  END toHexa;

  PROCEDURE serialOutChar(c: CHAR*);
  BEGIN REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (* Wait until UCA0TXBUF is empty. *)
    M.UCA0TXBUF^ := ORD(c)
  END serialOutChar;

  PROCEDURE serialOutString(msg: PBYTE);
  BEGIN WHILE msg^ # 0 DO serialOutChar(CHR(msg^)); INC(SYSTEM.VAL(INTEGER, msg)) END
  END serialOutString;

  PROCEDURE sendOK;
  BEGIN serialOutString(SYSTEM.VAL(PBYTE, SYSTEM.ADR("OK"+0DX+0AX)))
  END sendOK;

  PROCEDURE sendKO;
  BEGIN serialOutString(SYSTEM.VAL(PBYTE, SYSTEM.ADR("KO"+0DX+0AX)))
  END sendKO;

  PROCEDURE prompt;
  BEGIN serialOutString(SYSTEM.VAL(PBYTE, SYSTEM.ADR("sDBoot3 ready"+0DX+0AX)))
  END prompt;

  PROCEDURE serialInChar;
  BEGIN IF BIT(M.UCA0STAT^, M.UCOE) THEN sendKO; BIS(M.P1OUT^, {6}) END;
    REPEAT UNTIL BIT(M.IFG2^, M.UCA0RXIFG); (* Wait for char *)
    cc := CHR(M.UCA0RXBUF^);
  END serialInChar;

  PROCEDURE hexa(c: CHAR*): INTEGER;
  BEGIN
    IF (c >= "0") & (c <= "9") THEN DEC(SYSTEM.VAL(BYTE, c), ORD("0"))
    ELSE AND(SYSTEM.VAL(BYTE, c), 0DFH); DEC(SYSTEM.VAL(BYTE, c), ORD("A")-10)
    END

    RETURN 0+ORD(c)
  END hexa;

  PROCEDURE waitFlash;
  BEGIN REPEAT UNTIL ~BIT(M.FCTL3^, M.BUSY) (* Wait for flash controller availability *)
  END waitFlash;

  PROCEDURE flushBuffer;
    (* Write remaining characters to flash memory *)
  BEGIN
    IF nbElt > 0 THEN
      MSPFlash.flashBlock(SYSTEM.VAL(PINTEGER, PTR(PBYTE, buffer[0])), SYSTEM.VAL(PINTEGER, address), nbElt);
     (* flashBlock is also used by sDiary *)
      INC(SYSTEM.VAL(INTEGER, address), nbElt); (* Move address pointer just after the last byte written *)
      nbElt := 0;
      sendOK
    END
  END flushBuffer;

  PROCEDURE addByteInBuffer(byte: BYTE);
  BEGIN buffer[nbElt] := byte; INC(nbElt);
    IF nbElt = BUF_SIZE THEN flushBuffer END
  END addByteInBuffer;

  PROCEDURE getHexNumber(termination: CHAR);
  BEGIN (* get address *) add := 0; serialInChar;
    WHILE cc # termination DO RLA(add, 4); INC(add, hexa(cc)); serialInChar END
  END getHexNumber;

BEGIN M.WDTCTL^ := M.WDTPW + M.WDTHOLD;
  M.P1OUT^ := {0, 3}; M.P1REN^ := {3..5, 7}; (*PIN 3 senses push button, all input pull resistor are enabled*)

  M.FCTL3^ := M.FWKEY + M.LOCK; (* Reset Flash password violation if any *)
  IF BIT(M.IFG1^, M.WDTIFG) OR ~BIT(M.P1IN^, {3}) THEN (* Watchdog reboot or button pressed: Enter boot mode *)
    M.FCTL2^ := M.FWKEY + M.FSSEL_1 + M.FN5 + M.FN3 + M.FN1 + M.FN0; (*main clock divided by 44*)

    M.P1SEL^ := {1, 2}; M.P1SEL2^ := {1, 2}; (*PIN 1 and 2 configured for UART*)
    M.P1DIR^ := {0, 6}; (*PIN 0 and 6 drive LEDs*)
    M.P2SEL^ := {}; M.P2DIR^ := {}; M.P2REN^ := {0..7}; M.P3DIR^ := {}; M.P3REN^ := {0..7}; (*prevent floating on P2 and P3*)

    M.BCSCTL2^ := M.SELM_0 + M.DIVM_0 + M.DIVS_0; (*MCLK = DCOCLK divided by 1, SMCLK = DCOCLK divided by 1*)
    IF M.CALBC1_16MHZ^ # {0..7} THEN Delay.CyclesX3(100000 DIV 3); (*allow time for VCC to rise*)
      M.DCOCTL^ := {}; M.BCSCTL1^ := M.CALBC1_16MHZ^; M.DCOCTL^ := M.CALDCO_16MHZ^ (*apply calibration values for 16MHz DCO clock*)
    END;
    BIS(M.BCSCTL1^, M.XT2OFF + M.DIVA_0); M.BCSCTL3^ := M.LFXT1S_2; (*ACLK = VLO*)

    BIS(M.UCA0CTL1^, M.UCSWRST); (*Disable USCI*)
    M.UCA0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (*select SMCLK clock*)
    M.UCA0MCTL^ := M.UCBRF_0 + M.UCBRS_6; (*First stage 0, second stage 6*)
    M.UCA0BR0^ := 160; M.UCA0BR1^ := 1; (*clock presaler set at 1*256+160 = 416*)
    BIC(M.UCA0CTL1^, M.UCSWRST); (*Enable USCI*)

    BIC(M.P1OUT^, {0}); (*Turn main LED on to signal ready to flash state*)
    BIC(M.IFG1^, M.WDTIFG); (* Reset Watchdog Interrupt Flag *)
    prompt; address := NOWHERE; nbElt := 0; (* No firmware charater received yet *)
    serialInChar; 
    REPEAT
      IF cc = "z" THEN (* Erase command*)
        getHexNumber(" "); (* get number of blocks to erase *)
        waitFlash; M.FCTL3^ := M.FWKEY; (* Clear Flash memory lock *)
        WHILE add > 0 DO M.FCTL1^ := M.FWKEY + M.ERASE; (* Enable segment erase *)
          address^ := 0; (* Dummy write to erase segment *)
          INC(SYSTEM.VAL(INTEGER, address), 512); DEC(add); waitFlash
        END;
        sendOK
      ELSIF cc = "i" THEN prompt
      ELSIF cc = "@" THEN (* Address *)
        flushBuffer; getHexNumber(0DX); address := SYSTEM.VAL(PBYTE, add); sendOK
      ELSIF cc = "r" THEN (* Read data from flash *)
        getHexNumber(" "); (* get the number of bytes to read *)
        WHILE add > 0 DO serialOutChar(toHexa(address^ DIV 10H)); serialOutChar(toHexa(address^ MOD 10H));
          INC(SYSTEM.VAL(INTEGER, address)); serialOutChar(" "); DEC(add)
        END
      ELSIF cc = "q" THEN (* End of file, finish flash write and reboot to transfer control to the new appli *)
        flushBuffer; M.FCTL1^ := {}; (* Reboot application via flash PW fault*)
      ELSE (* line of data *)
        WHILE (cc # 0DX) & (cc # 0AX) DO byte := hexa(cc)*10H; serialInChar; INC(byte, hexa(cc));
          addByteInBuffer(byte); serialInChar;
          IF cc = " " THEN serialInChar END
        END
      END;
      serialInChar; (* get next char or skip \r *) IF cc = 0AX THEN serialInChar (* Skip \n *) END
    UNTIL FALSE
  END;
  APP_START.p; (* Start user application *)
END bootloader.

OMSPP.Compile MSPFlash.Mod/s bootloader.Mod/s~
OMSPL.Link 32 4000H 200H bootloader~
  linking msp430g2553 MSPFlash* Types msp430delay bootloader
    flash  974, data  166, stack  346 bytes

OMSPTool.DecObj bootloader.mpc
decode bootloader.mpc
bootloader 2BB965A8
imports:
	msp430g2553 BBD31A01
	MSPFlash 6F801689
	Types 5D7B970E
	msp430delay AAE4F156

section     0	r    1	cc
fixups:

section     1	r    1	byte
fixups:

section     2	r    2	add
fixups:

section     3	r    2	nbElt
fixups:

section     4	r    2	address
fixups:

section     5	r   64	buffer
fixups:

section     6	c    6	main_appli
 0000	     4382	MOV #0,&288
 0002	     0120
 0004	     1300	RETI
fixups:

section     7	c   20	toHexa
 0000	     9075	CMP.B #10,R5
 0002	     000A
 0004	     2C03	JC $+8, goes to  000C
 0006	     4074	MOV.B #48,R4
 0008	     0030
 000A	     3C02	JMP $+6, goes to  0010
 000C	     4074	MOV.B #55,R4
 000E	     0037
 0010	     5544	ADD.B R5,R4
 0012	     4130	RET
fixups:

section     8	c   12	serialOutChar
 0000	     B3E2	BIT.B #2,&3
 0002	     0003
 0004	     27FD	JEQ $-4, goes to  0000
 0006	     44C2	MOV.B R4,&103
 0008	     0067
 000A	     4130	RET
fixups:

section     9	c   28	serialOutString
 0000	     411F	MOV 2(SP),R15
 0002	     0002
 0004	     93CF	CMP.B #0,0(R15)
 0006	     0000
 0008	     2408	JEQ $+18, goes to  001A
 000A	     4114	MOV 2(SP),R4
 000C	     0002
 000E	     4464	MOV.B @R4,R4
 0010	     12B0	CALL #0
 0012	     0000
 0014	     5391	ADD #1,2(SP)
 0016	     0002
 0018	     3FF3	JMP $-24, goes to  0000
 001A	     4130	RET
fixups:
 0013	s0.8

section    10	c   12	sendOK
 0000	     1230	PUSH #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     4130	RET
fixups:
 0007	s0.9
 0003	s0.11

section    11	s    6	
OK
||
fixups:

section    12	c   12	sendKO
 0000	     1230	PUSH #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     4130	RET
fixups:
 0007	s0.9
 0003	s0.13

section    13	s    6	
KO
||
fixups:

section    14	c   12	prompt
 0000	     1230	PUSH #0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     5321	ADD #2,SP
 000A	     4130	RET
fixups:
 0007	s0.9
 0003	s0.15

section    15	s   16	
sDBoot3 ready
|
fixups:

section    16	c   32	serialInChar
 0000	     B0F2	BIT.B #32,&101
 0002	     0020
 0004	     0065
 0006	     2405	JEQ $+12, goes to  0012
 0008	     12B0	CALL #0
 000A	     0000
 000C	     D0F2	BIS.B #64,&33
 000E	     0040
 0010	     0021
 0012	     B3D2	BIT.B #1,&3
 0014	     0003
 0016	     27FD	JEQ $-4, goes to  0012
 0018	     42D2	MOV.B &102,&0
 001A	     0066
 001C	     0000
 001E	     4130	RET
fixups:
 001D	s0.0
 000B	s0.12

section    17	c   32	hexa
 0000	     9075	CMP.B #48,R5
 0002	     0030
 0004	     2807	JNC $+16, goes to  0014
 0006	     4074	MOV.B #57,R4
 0008	     0039
 000A	     9544	CMP.B R5,R4
 000C	     2803	JNC $+8, goes to  0014
 000E	     8075	SUB.B #48,R5
 0010	     0030
 0012	     3C04	JMP $+10, goes to  001C
 0014	     F075	AND.B #223,R5
 0016	     00DF
 0018	     8075	SUB.B #55,R5
 001A	     0037
 001C	     4504	MOV R5,R4
 001E	     4130	RET
fixups:

section    18	c    8	waitFlash
 0000	     B392	BIT #1,&300
 0002	     012C
 0004	     23FD	JNE $-4, goes to  0000
 0006	     4130	RET
fixups:

section    19	c   40	flushBuffer
 0000	     430F	MOV #0,R15
 0002	     921F	CMP &0,R15
 0004	     0000
 0006	     340F	JGE $+32, goes to  0026
 0008	     4034	MOV #0,R4
 000A	     0000
 000C	     4215	MOV &0,R5
 000E	     0000
 0010	     4216	MOV &5,R6
 0012	     0005
 0014	     12B0	CALL #0
 0016	     0000
 0018	     5292	ADD &19,&15
 001A	     0013
 001C	     000F
 001E	     4382	MOV #0,&27
 0020	     001B
 0022	     12B0	CALL #0
 0024	     0000
 0026	     4130	RET
fixups:
 0025	s0.10
 0017	s2.1
 001D	s0.4
 000B	s0.5
 0021	s0.3

section    20	c   28	addByteInBuffer
 0000	     421F	MOV &0,R15
 0002	     0000
 0004	     41DF	MOV.B 2(SP),0(R15)
 0006	     0002
 0008	     0000
 000A	     5392	ADD #1,&3
 000C	     0003
 000E	     90B2	CMP #64,&13
 0010	     0040
 0012	     000D
 0014	     2002	JNE $+6, goes to  001A
 0016	     12B0	CALL #0
 0018	     0000
 001A	     4130	RET
fixups:
 0019	s0.19
 0009	s0.5
 0013	s0.3

section    21	c   60	getHexNumber
 0000	     4382	MOV #0,&0
 0002	     0000
 0004	     12B0	CALL #0
 0006	     0000
 0008	     91D2	CMP.B 2(SP),&0
 000A	     0002
 000C	     0000
 000E	     2415	JEQ $+44, goes to  003A
 0010	     5292	ADD &3,&19
 0012	     0003
 0014	     0013
 0016	     5292	ADD &21,&25
 0018	     0015
 001A	     0019
 001C	     5292	ADD &27,&31
 001E	     001B
 0020	     001F
 0022	     5292	ADD &33,&37
 0024	     0021
 0026	     0025
 0028	     4255	MOV.B &13,R5
 002A	     000D
 002C	     12B0	CALL #0
 002E	     0000
 0030	     5482	ADD R4,&39
 0032	     0027
 0034	     12B0	CALL #7
 0036	     0007
 0038	     3FE7	JMP $-48, goes to  0008
 003A	     4130	RET
fixups:
 002F	s0.17
 002B	s0.0
 0037	s0.16
 0033	s0.2

section    22	c  514	module body
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     40F2	MOV.B #9,&33
 0008	     0009
 000A	     0021
 000C	     40F2	MOV.B #184,&39
 000E	     00B8
 0010	     0027
 0012	     40B2	MOV #-23280,&300
 0014	     A510
 0016	     012C
 0018	     B3D2	BIT.B #1,&2
 001A	     0002
 001C	     2003	JNE $+8, goes to  0024
 001E	     B2F2	BIT.B #8,&32
 0020	     0020
 0022	     20EC	JNE $+474, goes to  01FC
 0024	     40B2	MOV #-23189,&298
 0026	     A56B
 0028	     012A
 002A	     40F2	MOV.B #6,&38
 002C	     0006
 002E	     0026
 0030	     40F2	MOV.B #6,&65
 0032	     0006
 0034	     0041
 0036	     40F2	MOV.B #65,&34
 0038	     0041
 003A	     0022
 003C	     43C2	MOV.B #0,&46
 003E	     002E
 0040	     43C2	MOV.B #0,&42
 0042	     002A
 0044	     43F2	MOV.B #-1,&47
 0046	     002F
 0048	     43C2	MOV.B #0,&26
 004A	     001A
 004C	     43F2	MOV.B #-1,&16
 004E	     0010
 0050	     43C2	MOV.B #0,&88
 0052	     0058
 0054	     93F2	CMP.B #-1,&4345
 0056	     10F9
 0058	     240C	JEQ $+26, goes to  0072
 005A	     4034	MOV #-32203,R4
 005C	     8235
 005E	     12B0	CALL #0
 0060	     0000
 0062	     43C2	MOV.B #0,&86
 0064	     0056
 0066	     42D2	MOV.B &4345,&87
 0068	     10F9
 006A	     0057
 006C	     42D2	MOV.B &4344,&86
 006E	     10F8
 0070	     0056
 0072	     D0F2	BIS.B #128,&87
 0074	     0080
 0076	     0057
 0078	     40F2	MOV.B #32,&83
 007A	     0020
 007C	     0053
 007E	     D3D2	BIS.B #1,&97
 0080	     0061
 0082	     40F2	MOV.B #129,&97
 0084	     0081
 0086	     0061
 0088	     40F2	MOV.B #12,&100
 008A	     000C
 008C	     0064
 008E	     40F2	MOV.B #160,&98
 0090	     00A0
 0092	     0062
 0094	     43D2	MOV.B #1,&99
 0096	     0063
 0098	     C3D2	BIC.B #1,&97
 009A	     0061
 009C	     C3D2	BIC.B #1,&33
 009E	     0021
 00A0	     C3D2	BIC.B #1,&2
 00A2	     0002
 00A4	     12B0	CALL #0
 00A6	     0000
 00A8	     40B2	MOV #-24576,&0
 00AA	     A000
 00AC	     0000
 00AE	     4382	MOV #0,&0
 00B0	     0000
 00B2	     12B0	CALL #0
 00B4	     0000
 00B6	     90F2	CMP.B #122,&0
 00B8	     007A
 00BA	     0000
 00BC	     2020	JNE $+66, goes to  00FE
 00BE	     1270	PUSH.B #32
 00C0	     0020
 00C2	     12B0	CALL #0
 00C4	     0000
 00C6	     5321	ADD #2,SP
 00C8	     12B0	CALL #0
 00CA	     0000
 00CC	     40B2	MOV #-23296,&300
 00CE	     A500
 00D0	     012C
 00D2	     430F	MOV #0,R15
 00D4	     921F	CMP &0,R15
 00D6	     0000
 00D8	     340F	JGE $+32, goes to  00F8
 00DA	     40B2	MOV #-23294,&296
 00DC	     A502
 00DE	     0128
 00E0	     421F	MOV &173,R15
 00E2	     00AD
 00E4	     43CF	MOV.B #0,0(R15)
 00E6	     0000
 00E8	     50B2	ADD #512,&227
 00EA	     0200
 00EC	     00E3
 00EE	     8392	SUB #1,&215
 00F0	     00D7
 00F2	     12B0	CALL #203
 00F4	     00CB
 00F6	     3FED	JMP $-36, goes to  00D2
 00F8	     12B0	CALL #0
 00FA	     0000
 00FC	     3C76	JMP $+238, goes to  01EA
 00FE	     90F2	CMP.B #105,&187
 0100	     0069
 0102	     00BB
 0104	     2003	JNE $+8, goes to  010C
 0106	     12B0	CALL #167
 0108	     00A7
 010A	     3C6F	JMP $+224, goes to  01EA
 010C	     90F2	CMP.B #64,&259
 010E	     0040
 0110	     0103
 0112	     200D	JNE $+28, goes to  012E
 0114	     12B0	CALL #0
 0116	     0000
 0118	     1270	PUSH.B #13
 011A	     000D
 011C	     12B0	CALL #197
 011E	     00C5
 0120	     5321	ADD #2,SP
 0122	     4292	MOV &241,&237
 0124	     00F1
 0126	     00ED
 0128	     12B0	CALL #251
 012A	     00FB
 012C	     3C5E	JMP $+190, goes to  01EA
 012E	     90F2	CMP.B #114,&273
 0130	     0072
 0132	     0111
 0134	     2029	JNE $+84, goes to  0188
 0136	     1270	PUSH.B #32
 0138	     0020
 013A	     12B0	CALL #287
 013C	     011F
 013E	     5321	ADD #2,SP
 0140	     430F	MOV #0,R15
 0142	     921F	CMP &293,R15
 0144	     0125
 0146	     341F	JGE $+64, goes to  0186
 0148	     4214	MOV &295,R4
 014A	     0127
 014C	     4464	MOV.B @R4,R4
 014E	     1104	RRA R4
 0150	     1104	RRA R4
 0152	     1104	RRA R4
 0154	     1104	RRA R4
 0156	     4445	MOV.B R4,R5
 0158	     12B0	CALL #0
 015A	     0000
 015C	     12B0	CALL #0
 015E	     0000
 0160	     4214	MOV &331,R4
 0162	     014B
 0164	     4464	MOV.B @R4,R4
 0166	     F074	AND.B #15,R4
 0168	     000F
 016A	     4445	MOV.B R4,R5
 016C	     12B0	CALL #347
 016E	     015B
 0170	     12B0	CALL #351
 0172	     015F
 0174	     5392	ADD #1,&355
 0176	     0163
 0178	     4074	MOV.B #32,R4
 017A	     0020
 017C	     12B0	CALL #371
 017E	     0173
 0180	     8392	SUB #1,&325
 0182	     0145
 0184	     3FDD	JMP $-68, goes to  0140
 0186	     3C31	JMP $+100, goes to  01EA
 0188	     90F2	CMP.B #113,&307
 018A	     0071
 018C	     0133
 018E	     2005	JNE $+12, goes to  019A
 0190	     12B0	CALL #279
 0192	     0117
 0194	     4382	MOV #0,&296
 0196	     0128
 0198	     3C28	JMP $+82, goes to  01EA
 019A	     90F2	CMP.B #13,&397
 019C	     000D
 019E	     018D
 01A0	     2424	JEQ $+74, goes to  01EA
 01A2	     90F2	CMP.B #10,&415
 01A4	     000A
 01A6	     019F
 01A8	     2420	JEQ $+66, goes to  01EA
 01AA	     4255	MOV.B &423,R5
 01AC	     01A7
 01AE	     12B0	CALL #0
 01B0	     0000
 01B2	     5404	ADD R4,R4
 01B4	     5404	ADD R4,R4
 01B6	     5404	ADD R4,R4
 01B8	     5404	ADD R4,R4
 01BA	     44C2	MOV.B R4,&0
 01BC	     0000
 01BE	     12B0	CALL #181
 01C0	     00B5
 01C2	     4255	MOV.B &429,R5
 01C4	     01AD
 01C6	     12B0	CALL #433
 01C8	     01B1
 01CA	     54C2	ADD.B R4,&445
 01CC	     01BD
 01CE	     1252	PUSH.B &461
 01D0	     01CD
 01D2	     12B0	CALL #0
 01D4	     0000
 01D6	     5321	ADD #2,SP
 01D8	     12B0	CALL #449
 01DA	     01C1
 01DC	     90F2	CMP.B #32,&453
 01DE	     0020
 01E0	     01C5
 01E2	     2002	JNE $+6, goes to  01E8
 01E4	     12B0	CALL #475
 01E6	     01DB
 01E8	     3FD8	JMP $-78, goes to  019A
 01EA	     12B0	CALL #487
 01EC	     01E7
 01EE	     90F2	CMP.B #10,&481
 01F0	     000A
 01F2	     01E1
 01F4	     2002	JNE $+6, goes to  01FA
 01F6	     12B0	CALL #493
 01F8	     01ED
 01FA	     3F5D	JMP $-324, goes to  00B6
 01FC	     1292	CALL &65506
 01FE	     FFE2
 0200	     4130	RET
fixups:
 01D5	s0.20
 01D1	s0.1
 01C9	s0.17
 017F	s0.8
 016F	s0.7
 0193	s0.19
 012B	s0.10
 0183	s0.2
 00F5	s0.18
 013D	s0.21
 01F3	s0.0
 01F9	s0.16
 00B1	s0.3
 0177	s0.4
 0109	s0.14
 0061	s4.1

section    23	v   64	vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
fixups:
 0023	s0.6

entries:
   22
