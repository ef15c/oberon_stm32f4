(* --COPYRIGHT--,BSD_EX
 * Copyright (c) 2012, Texas Instruments Incorporated
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *******************************************************************************
 * 
 *                       MSP430 CODE EXAMPLE DISCLAIMER
 *
 * MSP430 code examples are self-contained low-level programs that typically
 * demonstrate a single peripheral function or device feature in a highly
 * concise manner. For this the code may rely on the device's power-on default
 * register values and settings such as the clock configuration and care must
 * be taken when combining code from several examples to avoid potential side
 * effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
 * for an API functional library-approach to peripheral configuration.
 *
 * --/COPYRIGHT--*/
//******************************************************************************
//  MSP430G2xx3 Demo - Timer_A, Ultra-Low Pwr UART 9600 Echo, 32kHz ACLK
//
//  Description: Use Timer_A CCR0 hardware output modes and SCCI data latch
//  to implement UART function @ 9600 baud. Software does not directly read and
//  write to RX and TX pins, instead proper use of output modes and SCCI data
//  latch are demonstrated. Use of these hardware features eliminates ISR
//  latency effects as hardware insures that output and input bit latching and
//  timing are perfectly synchronised with Timer_A regardless of other
//  software activity. In the Mainloop the UART function readies the UART to
//  receive one character and waits in LPM3 with all activity interrupt driven.
//  After a character has been received, the UART receive function forces exit
//  from LPM3 in the Mainloop which configures the port pins (P1 & P2) based
//  on the value of the received byte (i.e., if BIT0 is set, turn on P1.0).

//  ACLK = TACLK = LFXT1 = 32768Hz, MCLK = SMCLK = default DCO
//  //* An external watch crystal is required on XIN XOUT for ACLK *//  
//
//               MSP430G2xx3
//            -----------------
//        /|\|              XIN|-
//         | |                 | 32kHz
//         --|RST          XOUT|-
//           |                 |
//           |   CCI0B/TXD/P1.1|-------->
//           |                 | 9600 8N1
//           |   CCI0A/RXD/P1.2|<--------
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 04.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3tauart9600;
  IMPORT SYSTEM, M := msp430g2553;

  CONST
  (*------------------------------------------------------------------------------
  // Hardware-related definitions
  //------------------------------------------------------------------------------*)
    UART_TXD =  {1}; (* TXD on P1.1 (Timer0_A.OUT0) *)
    UART_RXD = {2}; (* RXD on P1.2 (Timer0_A.CCI1A) *)

  (*------------------------------------------------------------------------------
  // Conditions for 9600 Baud SW UART, SMCLK = 1MHz
  //------------------------------------------------------------------------------*)
    UART_TBIT_DIV_2 = 1000000 DIV (9600 * 2);
    UART_TBIT = 1000000 DIV 9600;

  VAR
  (*------------------------------------------------------------------------------
  // Global variables used for full-duplex UART communication
  //------------------------------------------------------------------------------*)
    txData: INTEGER; (* UART internal variable for TX *)
    rxBuffer: BYTE; (* Received UART character *)

  (* For Timer_A0_ISR  interrupt *)
     txBitCnt: BYTE;

  (* For Timer_A1_ISR interrupt *)
    rxBitCnt: BYTE;
    rxData: BYTE;

  (*------------------------------------------------------------------------------
  // Function configures Timer_A for full-duplex UART operation
  //------------------------------------------------------------------------------*)
  PROCEDURE TimerA_UART_init;
  BEGIN M.TA0CCTL0^ := M.OUT; (* Set TXD Idle as Mark = '1' *)
    M.TA0CCTL1^ := M.SCS + M.CM1 + M.CAP + M.CCIE; (* Sync, Neg Edge, Capture, Int *)
    M.TA0CTL^ := M.TASSEL_2 + M.MC_2; (* SMCLK, start in continuous mode *)
  END TimerA_UART_init;

   (*------------------------------------------------------------------------------
  // Outputs one byte using the Timer_A UART
  //------------------------------------------------------------------------------*)
  PROCEDURE TimerA_UART_tx(byte: BYTE);
  BEGIN REPEAT UNTIL ~BIT(M.TA0CCTL0^, M.CCIE); (* Ensure last char got TX'd *)
    M.TA0CCR0^ := M.TA0R^; (* Current state of TA counter *)
    INC(M.TA0CCR0^, UART_TBIT); (* One bit time till first bit *)
    M.TA0CCTL0^ := M.OUTMOD0 + M.CCIE; (* Set TXD on EQU0, Int *)
    txData := byte; (* Load global variable *)
    BIS(txData, {8}); (* Add mark stop bit to TXData *)
    RLA(txData, 1) (* Add space start bit *)
  END TimerA_UART_tx;

 (*------------------------------------------------------------------------------
  // Prints a string over using the Timer_A UART
  //------------------------------------------------------------------------------*)
  PROCEDURE TimerA_UART_println(string: ARRAY OF CHAR);
    VAR s!: PBYTE;
  BEGIN s := SYSTEM.VAL(PBYTE, SYSTEM.ADR(string));
    WHILE (s^ # 0) DO TimerA_UART_tx(s^); INC(ORD(s)) END;
    TimerA_UART_tx(0DH); TimerA_UART_tx(0AH)
  END  TimerA_UART_println;

  (*------------------------------------------------------------------------------
  // Timer_A UART - Transmit Interrupt Handler
  //------------------------------------------------------------------------------*)
  PROCEDURE* (M.TIMER0_A0_VECTOR) Timer_A0_ISR;
  BEGIN INC(M.TA0CCR0^, UART_TBIT); (* Add Offset to CCRx *)
    IF txBitCnt = 0 THEN (* All bits TXed? *)
      BIC(M.TA0CCTL0^, M.CCIE); (* All bits TXed, disable interrupt *)
      txBitCnt := 10 (* Re-load bit counter *)
    ELSE
      IF ODD(txData) THEN BIC(M.TA0CCTL0^, M.OUTMOD2) (* TX Mark '1' *)
      ELSE BIS(M.TA0CCTL0^, M.OUTMOD2) (* TX Space '0' *)
      END;
      RRA(txData, 1);
      DEC(txBitCnt)
    END
  END Timer_A0_ISR;
      
  (*------------------------------------------------------------------------------
  // Timer_A UART - Receive Interrupt Handler
  //------------------------------------------------------------------------------*)
  PROCEDURE* (M.TIMER0_A1_VECTOR) Timer_A1_ISR;
  BEGIN 
    IF M.TA0IV^ = M.TA0IV_TACCR1 THEN (* TACCR1 CCIFG - UART RX *)
      INC(M.TA0CCR1^, UART_TBIT); (* Add Offset to CCRx *)
      IF BIT(M.TA0CCTL1^, M.CAP) THEN (* Capture mode = start bit edge *)
        BIC(M.TA0CCTL1^, M.CAP); (* Switch capture to compare mode *)
        INC(M.TA0CCR1^, UART_TBIT_DIV_2); (* Point CCRx to middle of D0 *)
      ELSE CLRC; RRC(rxData);
        IF BIT(M.TA0CCTL1^, M.SCCI) THEN BIS(rxData, {7}) (* Get bit waiting in receive latch *) END;
        DEC(rxBitCnt);
        IF rxBitCnt = 0 THEN (* All bits RXed? *)
          rxBuffer := rxData; (* Store in global variable *)
          rxBitCnt := 8; (* Re-load bit counter *)
          BIS(M.TA0CCTL1^, M.CAP); (* Switch compare to capture mode *)
          SYSTEM.BIC_SR_ON_EXIT(M.LPM0_bits) (* Clear LPM0 bits from 0(SP) *)
        END
      END
    END
  END Timer_A1_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  REPEAT UNTIL M.CALBC1_1MHZ^ # {0..7}; (* If calibration constant erased do not load, trap CPU!! *)
    
  M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
  M.BCSCTL1^ := M.CALBC1_1MHZ^; (* Set DCOCLK to 1MHz *)
  M.DCOCTL^ := M.CALDCO_1MHZ^;

  M.P1OUT^ := {}; (* Initialize all GPIO *)
  M.P1SEL^ := UART_TXD + UART_RXD; (* Timer function for TXD/RXD pins *)
  M.P1DIR^ := {0..7} - UART_RXD; (* Set all pins but RXD to output *)
  M.P2OUT^ := {};
  M.P2SEL^ := {};
  M.P2DIR^ := {0..7};

  SYSTEM.BIS_SR(M.GIE);
    
  TimerA_UART_init(); (* Start Timer_A UART *)
  TimerA_UART_println("G2xx2 TimerA UART");
  TimerA_UART_println("READY.");

  (* Initialization for Timer_A0_ISR interrupt *)
  txBitCnt := 10;

  (* Initialization For Timer_A1_ISR interrupt *)
  rxBitCnt := 8;
  rxData := 0;

  REPEAT (* Wait for incoming character *)
    SYSTEM.BIS_SR(M.LPM0_bits);

    (* Update board outputs according to received byte *)
    IF 0 IN SYSTEM.VAL(BYTESET, rxBuffer) THEN BIS(M.P1OUT^, {0}) ELSE BIC(M.P1OUT^, {0}) END;(* P1.0 *)
    IF 1 IN SYSTEM.VAL(BYTESET, rxBuffer) THEN BIS(M.P1OUT^, {3}) ELSE BIC(M.P1OUT^, {3}) END;(* P1.3 *)
    IF 2 IN SYSTEM.VAL(BYTESET, rxBuffer) THEN BIS(M.P1OUT^, {4}) ELSE BIC(M.P1OUT^, {4}) END;(* P1.4 *)
    IF 3 IN SYSTEM.VAL(BYTESET, rxBuffer) THEN BIS(M.P1OUT^, {5}) ELSE BIC(M.P1OUT^, {5}) END;(* P1.5 *)
    IF 4 IN SYSTEM.VAL(BYTESET, rxBuffer) THEN BIS(M.P1OUT^, {6}) ELSE BIC(M.P1OUT^, {6}) END;(* P1.6 *)
    IF 5 IN SYSTEM.VAL(BYTESET, rxBuffer) THEN BIS(M.P1OUT^, {7}) ELSE BIC(M.P1OUT^, {7}) END;(* P1.7 *)
    IF 6 IN SYSTEM.VAL(BYTESET, rxBuffer) THEN BIS(M.P2OUT^, {6}) ELSE BIC(M.P2OUT^, {6}) END;(* P2.6 *)
    IF 7 IN SYSTEM.VAL(BYTESET, rxBuffer) THEN BIS(M.P2OUT^, {7}) ELSE BIC(M.P2OUT^, {7}) END;(* P2.7 *)

    (* Echo received character *)
    TimerA_UART_tx(rxBuffer);
  UNTIL FALSE
END msp430g2xx3tauart9600.

OMSPTool.DecObj msp430g2xx3tauart9600.mpc
decode msp430g2xx3tauart9600.mpc
msp430g2xx3tauart9600 6251E057 Flash   574
imports:
	msp430g2553 F10488DC
type descriptors

data     6
strings
G2xx2 TimerA UART|READY.||
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 010A
fixup procedures chains
 0146     0	 0000
 021C     0	 0012
 0160     0	 0042
fixup handlers chains
 0119     0	 007A
 0118     0	 00B2
fixup data chains
 00AA     0	 0000
 0168     0	 0003
 0170     0	 0005
 016C     0	 0004
 0218     0	 0002
fixup constants chains
 014E     0	 0000
 015C     0	 0012
fixup types chains
entry =  010A
code   548
 0000	     42A2	MOV #4,&354
 0002	     0162
 0004	     40B2	MOV #-30448,&356
 0006	     8910
 0008	     0164
 000A	     40B2	MOV #544,&352
 000C	     0220
 000E	     0160
 0010	     4130	RET
 0012	     B0B2	BIT #16,&354
 0014	     0010
 0016	     0162
 0018	     23FC	JNE $-6, goes to  0012
 001A	     4292	MOV &368,&370
 001C	     0170
 001E	     0172
 0020	     50B2	ADD #104,&370
 0022	     0068
 0024	     0172
 0026	     40B2	MOV #48,&354
 0028	     0030
 002A	     0162
 002C	     415F	MOV.B 2(SP),R15
 002E	     0002
 0030	     4F82	MOV R15,&0
 0032	     0000
 0034	     D0B2	BIS #256,&50
 0036	     0100
 0038	     0032
 003A	     5292	ADD &56,&60
 003C	     0038
 003E	     003C
 0040	     4130	RET
 0042	     8321	SUB #2,SP
 0044	     4191	MOV 4(SP),0(SP)
 0046	     0004
 0048	     0000
 004A	     412F	MOV @SP,R15
 004C	     93CF	CMP.B #0,0(R15)
 004E	     0000
 0050	     2408	JEQ $+18, goes to  0062
 0052	     412F	MOV @SP,R15
 0054	     126F	PUSH.B @R15
 0056	     12B0	CALL #0
 0058	     0000
 005A	     5321	ADD #2,SP
 005C	     5391	ADD #1,0(SP)
 005E	     0000
 0060	     3FF4	JMP $-22, goes to  004A
 0062	     1230	PUSH #13
 0064	     000D
 0066	     12B0	CALL #88
 0068	     0058
 006A	     5321	ADD #2,SP
 006C	     1230	PUSH #10
 006E	     000A
 0070	     12B0	CALL #104
 0072	     0068
 0074	     5321	ADD #2,SP
 0076	     5321	ADD #2,SP
 0078	     4130	RET
 007A	     50B2	ADD #104,&370
 007C	     0068
 007E	     0172
 0080	     93C2	CMP.B #0,&0
 0082	     0000
 0084	     2007	JNE $+16, goes to  0094
 0086	     C0B2	BIC #16,&354
 0088	     0010
 008A	     0162
 008C	     40F2	MOV.B #10,&130
 008E	     000A
 0090	     0082
 0092	     3C0E	JMP $+30, goes to  00B0
 0094	     B392	BIT #1,&62
 0096	     003E
 0098	     2404	JEQ $+10, goes to  00A2
 009A	     C0B2	BIC #128,&354
 009C	     0080
 009E	     0162
 00A0	     3C03	JMP $+8, goes to  00A8
 00A2	     D0B2	BIS #128,&354
 00A4	     0080
 00A6	     0162
 00A8	     1112	RRA &150
 00AA	     0096
 00AC	     83D2	SUB.B #1,&144
 00AE	     0090
 00B0	     1300	RETI
 00B2	     93A2	CMP #2,&302
 00B4	     012E
 00B6	     2028	JNE $+82, goes to  0108
 00B8	     50B2	ADD #104,&372
 00BA	     0068
 00BC	     0174
 00BE	     B0B2	BIT #256,&356
 00C0	     0100
 00C2	     0164
 00C4	     2407	JEQ $+16, goes to  00D4
 00C6	     C0B2	BIC #256,&356
 00C8	     0100
 00CA	     0164
 00CC	     50B2	ADD #52,&372
 00CE	     0034
 00D0	     0174
 00D2	     3C1A	JMP $+54, goes to  0108
 00D4	     C312	BIC #1,SR
 00D6	     1052	RRC.B &0
 00D8	     0000
 00DA	     B0B2	BIT #1024,&356
 00DC	     0400
 00DE	     0164
 00E0	     2403	JEQ $+8, goes to  00E8
 00E2	     D0F2	BIS.B #128,&216
 00E4	     0080
 00E6	     00D8
 00E8	     83D2	SUB.B #1,&0
 00EA	     0000
 00EC	     93C2	CMP.B #0,&234
 00EE	     00EA
 00F0	     200B	JNE $+24, goes to  0108
 00F2	     42D2	MOV.B &230,&0
 00F4	     00E6
 00F6	     0000
 00F8	     42F2	MOV.B #8,&238
 00FA	     00EE
 00FC	     D0B2	BIS #256,&356
 00FE	     0100
 0100	     0164
 0102	     C0B1	BIC #16,0(SP)
 0104	     0010
 0106	     0000
 0108	     1300	RETI
 010A	     40B2	MOV #23168,&288
 010C	     5A80
 010E	     0120
 0110	     93F2	CMP.B #-1,&4351
 0112	     10FF
 0114	     27FD	JEQ $-4, goes to  0110
 0116	     43C2	MOV.B #0,&86
 0118	     0056
 011A	     42D2	MOV.B &4351,&87
 011C	     10FF
 011E	     0057
 0120	     42D2	MOV.B &4350,&86
 0122	     10FE
 0124	     0056
 0126	     43C2	MOV.B #0,&33
 0128	     0021
 012A	     40F2	MOV.B #6,&38
 012C	     0006
 012E	     0026
 0130	     40F2	MOV.B #251,&34
 0132	     00FB
 0134	     0022
 0136	     43C2	MOV.B #0,&41
 0138	     0029
 013A	     43C2	MOV.B #0,&46
 013C	     002E
 013E	     43F2	MOV.B #-1,&42
 0140	     002A
 0142	     D232	BIS #8,SR
 0144	     12B0	CALL #0
 0146	     0000
 0148	     1230	PUSH #18
 014A	     0012
 014C	     1230	PUSH #0
 014E	     0000
 0150	     12B0	CALL #0
 0152	     0000
 0154	     5221	ADD #4,SP
 0156	     1230	PUSH #7
 0158	     0007
 015A	     1230	PUSH #0
 015C	     0000
 015E	     12B0	CALL #338
 0160	     0152
 0162	     5221	ADD #4,SP
 0164	     40F2	MOV.B #10,&174
 0166	     000A
 0168	     00AE
 016A	     42F2	MOV.B #8,&250
 016C	     00FA
 016E	     43C2	MOV.B #0,&244
 0170	     00F4
 0172	     D032	BIS #16,SR
 0174	     0010
 0176	     B3D2	BIT.B #1,&246
 0178	     00F6
 017A	     2403	JEQ $+8, goes to  0182
 017C	     D3D2	BIS.B #1,&33
 017E	     0021
 0180	     3C02	JMP $+6, goes to  0186
 0182	     C3D2	BIC.B #1,&33
 0184	     0021
 0186	     B3E2	BIT.B #2,&376
 0188	     0178
 018A	     2403	JEQ $+8, goes to  0192
 018C	     D2F2	BIS.B #8,&33
 018E	     0021
 0190	     3C02	JMP $+6, goes to  0196
 0192	     C2F2	BIC.B #8,&33
 0194	     0021
 0196	     B2E2	BIT.B #4,&392
 0198	     0188
 019A	     2404	JEQ $+10, goes to  01A4
 019C	     D0F2	BIS.B #16,&33
 019E	     0010
 01A0	     0021
 01A2	     3C03	JMP $+8, goes to  01AA
 01A4	     C0F2	BIC.B #16,&33
 01A6	     0010
 01A8	     0021
 01AA	     B2F2	BIT.B #8,&408
 01AC	     0198
 01AE	     2404	JEQ $+10, goes to  01B8
 01B0	     D0F2	BIS.B #32,&33
 01B2	     0020
 01B4	     0021
 01B6	     3C03	JMP $+8, goes to  01BE
 01B8	     C0F2	BIC.B #32,&33
 01BA	     0020
 01BC	     0021
 01BE	     B0F2	BIT.B #16,&428
 01C0	     0010
 01C2	     01AC
 01C4	     2404	JEQ $+10, goes to  01CE
 01C6	     D0F2	BIS.B #64,&33
 01C8	     0040
 01CA	     0021
 01CC	     3C03	JMP $+8, goes to  01D4
 01CE	     C0F2	BIC.B #64,&33
 01D0	     0040
 01D2	     0021
 01D4	     B0F2	BIT.B #32,&450
 01D6	     0020
 01D8	     01C2
 01DA	     2404	JEQ $+10, goes to  01E4
 01DC	     D0F2	BIS.B #128,&33
 01DE	     0080
 01E0	     0021
 01E2	     3C03	JMP $+8, goes to  01EA
 01E4	     C0F2	BIC.B #128,&33
 01E6	     0080
 01E8	     0021
 01EA	     B0F2	BIT.B #64,&472
 01EC	     0040
 01EE	     01D8
 01F0	     2404	JEQ $+10, goes to  01FA
 01F2	     D0F2	BIS.B #64,&41
 01F4	     0040
 01F6	     0029
 01F8	     3C03	JMP $+8, goes to  0200
 01FA	     C0F2	BIC.B #64,&41
 01FC	     0040
 01FE	     0029
 0200	     B0F2	BIT.B #128,&494
 0202	     0080
 0204	     01EE
 0206	     2404	JEQ $+10, goes to  0210
 0208	     D0F2	BIS.B #128,&41
 020A	     0080
 020C	     0029
 020E	     3C03	JMP $+8, goes to  0216
 0210	     C0F2	BIC.B #128,&41
 0212	     0080
 0214	     0029
 0216	     1252	PUSH.B &516
 0218	     0204
 021A	     12B0	CALL #114
 021C	     0072
 021E	     5321	ADD #2,SP
 0220	     3FA8	JMP $-174, goes to  0172
 0222	     4130	RET
