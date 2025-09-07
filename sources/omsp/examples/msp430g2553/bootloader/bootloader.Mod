MODULE bootloader;
  IMPORT SYSTEM, M := msp430g2553, MSPFlash, Types, Delay := msp430delay;

  CONST APP_RESET_VECTOR = SYSTEM.VAL(Types.PPROC, 0FFE2H);
    APP_START = SYSTEM.VAL(PBYTE, 0C400H);
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
    prompt; address := APP_START; nbElt := 0; (* No firmware charater received yet *)
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
  APP_RESET_VECTOR.p; (* Start user application *)
END bootloader.

OMSPP.Compile MSPFlash.Mod bootloader.Mod~
OMSPL.Link 32 4000H 200H bootloader~
  linking msp430g2553 MSPFlash* Types msp430delay bootloader
    flash  990, data  166, stack  346 bytes

OMSPTool.DecObj bootloader.mpc
decode bootloader.mpc
bootloader 9CFADC3C Flash   850
imports:
	msp430g2553 F10488DC
	MSPFlash 950E56FD
	Types 03DB4129
	msp430delay EE6A4099
type descriptors

data    72
strings
OK
||KO
||sDBoot3 ready
|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 012E
fixup procedures in code space chains
 029C     0	 0006
 02AC     0	 001A
 0060     0	 0026
 0258     0	 0042
 0070     0	 004E
 0236     0	 005A
 0326     0	 0066
 02F6     0	 0086
 0222     0	 00A6
 02C0     0	 00AE
 0302     0	 00D6
 026A     0	 00F2
 00C4     2	 0001
 018E     4	 0001
fixup handlers in vector space chains
 0111     0	 0000
fixup data in code space chains
 02FE     0	 0001
 02B0     0	 0002
 02A4     0	 0006
 00DE     0	 0008
 01DE     0	 0004
 0320     0	 0000
fixup constants in code space chains
 005C     0	 000C
 0050     0	 0006
 0044     0	 0000
fixup variables in constant space chains
fixup constants in constant space chains
entry =  012E
code   822
 0000	     4382	MOV #0,&288
 0002	     0120
 0004	     1300	RETI
 0006	     9075	CMP.B #10,R5
 0008	     000A
 000A	     2C03	JC $+8, goes to  0012
 000C	     4074	MOV.B #48,R4
 000E	     0030
 0010	     3C02	JMP $+6, goes to  0016
 0012	     4074	MOV.B #55,R4
 0014	     0037
 0016	     5544	ADD.B R5,R4
 0018	     4130	RET
 001A	     B3E2	BIT.B #2,&3
 001C	     0003
 001E	     27FD	JEQ $-4, goes to  001A
 0020	     44C2	MOV.B R4,&103
 0022	     0067
 0024	     4130	RET
 0026	     411F	MOV 2(SP),R15
 0028	     0002
 002A	     93CF	CMP.B #0,0(R15)
 002C	     0000
 002E	     2408	JEQ $+18, goes to  0040
 0030	     4114	MOV 2(SP),R4
 0032	     0002
 0034	     4464	MOV.B @R4,R4
 0036	     12B0	CALL #0
 0038	     0000
 003A	     5391	ADD #1,2(SP)
 003C	     0002
 003E	     3FF3	JMP $-24, goes to  0026
 0040	     4130	RET
 0042	     1230	PUSH #0
 0044	     0000
 0046	     12B0	CALL #0
 0048	     0000
 004A	     5321	ADD #2,SP
 004C	     4130	RET
 004E	     1230	PUSH #0
 0050	     0000
 0052	     12B0	CALL #72
 0054	     0048
 0056	     5321	ADD #2,SP
 0058	     4130	RET
 005A	     1230	PUSH #0
 005C	     0000
 005E	     12B0	CALL #84
 0060	     0054
 0062	     5321	ADD #2,SP
 0064	     4130	RET
 0066	     B0F2	BIT.B #32,&101
 0068	     0020
 006A	     0065
 006C	     2405	JEQ $+12, goes to  0078
 006E	     12B0	CALL #0
 0070	     0000
 0072	     D0F2	BIS.B #64,&33
 0074	     0040
 0076	     0021
 0078	     B3D2	BIT.B #1,&3
 007A	     0003
 007C	     27FD	JEQ $-4, goes to  0078
 007E	     42D2	MOV.B &102,&0
 0080	     0066
 0082	     0000
 0084	     4130	RET
 0086	     9075	CMP.B #48,R5
 0088	     0030
 008A	     2807	JNC $+16, goes to  009A
 008C	     4034	MOV #57,R4
 008E	     0039
 0090	     9544	CMP.B R5,R4
 0092	     2803	JNC $+8, goes to  009A
 0094	     8075	SUB.B #48,R5
 0096	     0030
 0098	     3C04	JMP $+10, goes to  00A2
 009A	     F075	AND.B #223,R5
 009C	     00DF
 009E	     8075	SUB.B #55,R5
 00A0	     0037
 00A2	     4504	MOV R5,R4
 00A4	     4130	RET
 00A6	     B392	BIT #1,&300
 00A8	     012C
 00AA	     23FD	JNE $-4, goes to  00A6
 00AC	     4130	RET
 00AE	     430F	MOV #0,R15
 00B0	     921F	CMP &0,R15
 00B2	     0000
 00B4	     340F	JGE $+32, goes to  00D4
 00B6	     4034	MOV #0,R4
 00B8	     0000
 00BA	     4215	MOV &0,R5
 00BC	     0000
 00BE	     4216	MOV &178,R6
 00C0	     00B2
 00C2	     12B0	CALL #0
 00C4	     0000
 00C6	     5292	ADD &192,&188
 00C8	     00C0
 00CA	     00BC
 00CC	     4382	MOV #0,&200
 00CE	     00C8
 00D0	     12B0	CALL #0
 00D2	     0000
 00D4	     4130	RET
 00D6	     421F	MOV &206,R15
 00D8	     00CE
 00DA	     41DF	MOV.B 2(SP),184(R15)
 00DC	     0002
 00DE	     00B8
 00E0	     5392	ADD #1,&216
 00E2	     00D8
 00E4	     90B2	CMP #64,&226
 00E6	     0040
 00E8	     00E2
 00EA	     2002	JNE $+6, goes to  00F0
 00EC	     12B0	CALL #0
 00EE	     0000
 00F0	     4130	RET
 00F2	     4382	MOV #0,&0
 00F4	     0000
 00F6	     12B0	CALL #0
 00F8	     0000
 00FA	     91D2	CMP.B 2(SP),&130
 00FC	     0002
 00FE	     0082
 0100	     2415	JEQ $+44, goes to  012C
 0102	     5292	ADD &244,&260
 0104	     00F4
 0106	     0104
 0108	     5292	ADD &262,&266
 010A	     0106
 010C	     010A
 010E	     5292	ADD &268,&272
 0110	     010C
 0112	     0110
 0114	     5292	ADD &274,&278
 0116	     0112
 0118	     0116
 011A	     4255	MOV.B &254,R5
 011C	     00FE
 011E	     12B0	CALL #0
 0120	     0000
 0122	     5482	ADD R4,&280
 0124	     0118
 0126	     12B0	CALL #248
 0128	     00F8
 012A	     3FE7	JMP $-48, goes to  00FA
 012C	     4130	RET
 012E	     40B2	MOV #23168,&288
 0130	     5A80
 0132	     0120
 0134	     40F2	MOV.B #9,&33
 0136	     0009
 0138	     0021
 013A	     40F2	MOV.B #184,&39
 013C	     00B8
 013E	     0027
 0140	     40B2	MOV #-23280,&300
 0142	     A510
 0144	     012C
 0146	     B3D2	BIT.B #1,&2
 0148	     0002
 014A	     2003	JNE $+8, goes to  0152
 014C	     B2F2	BIT.B #8,&32
 014E	     0020
 0150	     20EC	JNE $+474, goes to  032A
 0152	     40B2	MOV #-23189,&298
 0154	     A56B
 0156	     012A
 0158	     40F2	MOV.B #6,&38
 015A	     0006
 015C	     0026
 015E	     40F2	MOV.B #6,&65
 0160	     0006
 0162	     0041
 0164	     40F2	MOV.B #65,&34
 0166	     0041
 0168	     0022
 016A	     43C2	MOV.B #0,&46
 016C	     002E
 016E	     43C2	MOV.B #0,&42
 0170	     002A
 0172	     43F2	MOV.B #-1,&47
 0174	     002F
 0176	     43C2	MOV.B #0,&26
 0178	     001A
 017A	     43F2	MOV.B #-1,&16
 017C	     0010
 017E	     43C2	MOV.B #0,&88
 0180	     0058
 0182	     93F2	CMP.B #-1,&4345
 0184	     10F9
 0186	     240C	JEQ $+26, goes to  01A0
 0188	     4034	MOV #-32203,R4
 018A	     8235
 018C	     12B0	CALL #0
 018E	     0000
 0190	     43C2	MOV.B #0,&86
 0192	     0056
 0194	     42D2	MOV.B &4345,&87
 0196	     10F9
 0198	     0057
 019A	     42D2	MOV.B &4344,&86
 019C	     10F8
 019E	     0056
 01A0	     D0F2	BIS.B #128,&87
 01A2	     0080
 01A4	     0057
 01A6	     40F2	MOV.B #32,&83
 01A8	     0020
 01AA	     0053
 01AC	     D3D2	BIS.B #1,&97
 01AE	     0061
 01B0	     40F2	MOV.B #129,&97
 01B2	     0081
 01B4	     0061
 01B6	     40F2	MOV.B #12,&100
 01B8	     000C
 01BA	     0064
 01BC	     40F2	MOV.B #160,&98
 01BE	     00A0
 01C0	     0062
 01C2	     43D2	MOV.B #1,&99
 01C4	     0063
 01C6	     C3D2	BIC.B #1,&97
 01C8	     0061
 01CA	     C3D2	BIC.B #1,&33
 01CC	     0021
 01CE	     C3D2	BIC.B #1,&2
 01D0	     0002
 01D2	     12B0	CALL #0
 01D4	     0000
 01D6	     40B2	MOV #-15360,&202
 01D8	     C400
 01DA	     00CA
 01DC	     4382	MOV #0,&232
 01DE	     00E8
 01E0	     12B0	CALL #296
 01E2	     0128
 01E4	     90F2	CMP.B #122,&284
 01E6	     007A
 01E8	     011C
 01EA	     2020	JNE $+66, goes to  022C
 01EC	     1270	PUSH.B #32
 01EE	     0020
 01F0	     12B0	CALL #0
 01F2	     0000
 01F4	     5321	ADD #2,SP
 01F6	     12B0	CALL #0
 01F8	     0000
 01FA	     40B2	MOV #-23296,&300
 01FC	     A500
 01FE	     012C
 0200	     430F	MOV #0,R15
 0202	     921F	CMP &292,R15
 0204	     0124
 0206	     340F	JGE $+32, goes to  0226
 0208	     40B2	MOV #-23294,&296
 020A	     A502
 020C	     0128
 020E	     421F	MOV &474,R15
 0210	     01DA
 0212	     43CF	MOV.B #0,0(R15)
 0214	     0000
 0216	     50B2	ADD #512,&528
 0218	     0200
 021A	     0210
 021C	     8392	SUB #1,&516
 021E	     0204
 0220	     12B0	CALL #504
 0222	     01F8
 0224	     3FED	JMP $-36, goes to  0200
 0226	     12B0	CALL #210
 0228	     00D2
 022A	     3C76	JMP $+238, goes to  0318
 022C	     90F2	CMP.B #105,&488
 022E	     0069
 0230	     01E8
 0232	     2003	JNE $+8, goes to  023A
 0234	     12B0	CALL #468
 0236	     01D4
 0238	     3C6F	JMP $+224, goes to  0318
 023A	     90F2	CMP.B #64,&560
 023C	     0040
 023E	     0230
 0240	     200D	JNE $+28, goes to  025C
 0242	     12B0	CALL #238
 0244	     00EE
 0246	     1270	PUSH.B #13
 0248	     000D
 024A	     12B0	CALL #498
 024C	     01F2
 024E	     5321	ADD #2,SP
 0250	     4292	MOV &542,&538
 0252	     021E
 0254	     021A
 0256	     12B0	CALL #552
 0258	     0228
 025A	     3C5E	JMP $+190, goes to  0318
 025C	     90F2	CMP.B #114,&574
 025E	     0072
 0260	     023E
 0262	     2029	JNE $+84, goes to  02B6
 0264	     1270	PUSH.B #32
 0266	     0020
 0268	     12B0	CALL #588
 026A	     024C
 026C	     5321	ADD #2,SP
 026E	     430F	MOV #0,R15
 0270	     921F	CMP &594,R15
 0272	     0252
 0274	     341F	JGE $+64, goes to  02B4
 0276	     4214	MOV &596,R4
 0278	     0254
 027A	     4464	MOV.B @R4,R4
 027C	     1104	RRA R4
 027E	     1104	RRA R4
 0280	     1104	RRA R4
 0282	     1104	RRA R4
 0284	     4405	MOV R4,R5
 0286	     12B0	CALL #0
 0288	     0000
 028A	     12B0	CALL #56
 028C	     0038
 028E	     4214	MOV &632,R4
 0290	     0278
 0292	     4464	MOV.B @R4,R4
 0294	     F034	AND #15,R4
 0296	     000F
 0298	     4405	MOV R4,R5
 029A	     12B0	CALL #648
 029C	     0288
 029E	     12B0	CALL #652
 02A0	     028C
 02A2	     5392	ADD #1,&656
 02A4	     0290
 02A6	     4034	MOV #32,R4
 02A8	     0020
 02AA	     12B0	CALL #672
 02AC	     02A0
 02AE	     8392	SUB #1,&626
 02B0	     0272
 02B2	     3FDD	JMP $-68, goes to  026E
 02B4	     3C31	JMP $+100, goes to  0318
 02B6	     90F2	CMP.B #113,&608
 02B8	     0071
 02BA	     0260
 02BC	     2005	JNE $+12, goes to  02C8
 02BE	     12B0	CALL #580
 02C0	     0244
 02C2	     4382	MOV #0,&296
 02C4	     0128
 02C6	     3C28	JMP $+82, goes to  0318
 02C8	     90F2	CMP.B #13,&698
 02CA	     000D
 02CC	     02BA
 02CE	     2424	JEQ $+74, goes to  0318
 02D0	     90F2	CMP.B #10,&716
 02D2	     000A
 02D4	     02CC
 02D6	     2420	JEQ $+66, goes to  0318
 02D8	     4255	MOV.B &724,R5
 02DA	     02D4
 02DC	     12B0	CALL #288
 02DE	     0120
 02E0	     5404	ADD R4,R4
 02E2	     5404	ADD R4,R4
 02E4	     5404	ADD R4,R4
 02E6	     5404	ADD R4,R4
 02E8	     44C2	MOV.B R4,&0
 02EA	     0000
 02EC	     12B0	CALL #482
 02EE	     01E2
 02F0	     4255	MOV.B &730,R5
 02F2	     02DA
 02F4	     12B0	CALL #734
 02F6	     02DE
 02F8	     54C2	ADD.B R4,&746
 02FA	     02EA
 02FC	     1252	PUSH.B &762
 02FE	     02FA
 0300	     12B0	CALL #0
 0302	     0000
 0304	     5321	ADD #2,SP
 0306	     12B0	CALL #750
 0308	     02EE
 030A	     90F2	CMP.B #32,&754
 030C	     0020
 030E	     02F2
 0310	     2002	JNE $+6, goes to  0316
 0312	     12B0	CALL #776
 0314	     0308
 0316	     3FD8	JMP $-78, goes to  02C8
 0318	     12B0	CALL #788
 031A	     0314
 031C	     90F2	CMP.B #10,&782
 031E	     000A
 0320	     030E
 0322	     2002	JNE $+6, goes to  0328
 0324	     12B0	CALL #794
 0326	     031A
 0328	     3F5D	JMP $-324, goes to  01E4
 032A	     1212	PUSH &65506
 032C	     FFE2
 032E	     1291	CALL 2(SP)
 0330	     0002
 0332	     5321	ADD #2,SP
 0334	     4130	RET
