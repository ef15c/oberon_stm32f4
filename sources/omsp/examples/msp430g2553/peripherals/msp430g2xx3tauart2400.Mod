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
//  MSP430G2xx3 Demo - Timer_A, Ultra-Low Pwr UART 2400 Echo, 32kHz ACLK
//
//  Description: Use Timer_A CCR0 hardware output modes and SCCI data latch
//  to implement UART function @ 2400 baud. Software does not directly read and
//  write to RX and TX pins, instead proper use of output modes and SCCI data
//  latch are demonstrated. Use of these hardware features eliminates ISR
//  latency effects as hardware insures that output and input bit latching and
//  timing are perfectly synchronised with Timer_A regardless of other
//  software activity. In the Mainloop the UART function readies the UART to
//  receive one character and waits in LPM3 with all activity interrupt driven.
//  After a character has been received, the UART receive function forces exit
//  from LPM3 in the Mainloop which echo's back the received character.
//  ACLK = TACLK = LFXT1 = 32768Hz, MCLK = SMCLK = default DCO
//  //* An external watch crystal is required on XIN XOUT for ACLK *//	
//
//               MSP430G2xx3
//            -----------------
//        /|\|              XIN|-
//         | |                 | 32kHz
//         --|RST          XOUT|-
//           |                 |
//           |   CCI0B/TXD/P1.5|-------->
//           |                 | 2400 8N1
//           |   CCI0A/RXD/P1.1|<--------
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 02.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3tauart2400;
  IMPORT SYSTEM, M := msp430g2553;

  CONST RXD = {1} (* RXD on P1.1 *); TXD = {5} (* TXD on P1.5 *);

    (* Conditions for 2400 Baud SW UART, ACLK = 32768 *)
    Bitime_5 = 06H; (* ~ 0.5 bit length + small adjustment *)
    Bitime = 0EH; (* 427us bit length ~ 2341 baud *)

  VAR RXTXData: INTEGER; BitCnt: BYTE;

  (* Transmits Character from RXTXData Buffer *)
  PROCEDURE TX_Byte;
    BEGIN BitCnt := 10; (* Load Bit counter, 8data + ST/SP *)
    REPEAT M.TA0CCR0^ := M.TA0R^ UNTIL M.TA0CCR0^ = M.TA0R^; (* Prevent async capture *)
    INC(M.TA0CCR0^, Bitime); (* Some time till first bit *)
    INC(RXTXData, 100H); (* Add mark stop bit to RXTXData *)
    RLA(RXTXData, 1); (* Add space start bit *)
    M.TA0CCTL0^ :=  M.CCIS0 + M.OUTMOD0 + M.CCIE; (* TXD = mark = idle *)
    REPEAT UNTIL ~BIT(M.TA0CCTL0^, M.CCIE); (* Wait for TX completion *)
  END TX_Byte;

  (* UART to Receive Character into RXTXData Buffer *)
  PROCEDURE RX_Ready;
  BEGIN BitCnt := 8; (* Load Bit counter *)
    M.TA0CCTL0^ := M.SCS + M.OUTMOD0 + M.CM1 + M.CAP + M.CCIE; (* Sync, Neg Edge, Cap *)
  END RX_Ready;

  (* Timer A0 interrupt service routine *)
  PROCEDURE* (M.TIMER0_A0_VECTOR) Timer_A;
  BEGIN INC(M.TA0CCR0^, Bitime); (* Add Offset to CCR0 *)
    IF BIT(M.TA0CCTL0^, M.CCIS0) (* TX on CCI0B? *) THEN (* TX *)
      IF BitCnt = 0 THEN BIC(M.TA0CCTL0^, M.CCIE) (* All bits TXed, disable interrupt *)
      ELSE BIS(M.TA0CCTL0^, M.OUTMOD2); (* TX Space *)
        IF BIT(RXTXData, {0}) THEN BIC(M.TA0CCTL0^, M.OUTMOD2) END; (* TX Mark *)
        CLRC; RRC(RXTXData); DEC(BitCnt)
      END
    ELSE (* RX *)
      IF BIT(M.TA0CCTL0^, M.CAP) THEN (* Capture mode = start bit edge *)
        BIC(M.TA0CCTL0^, M.CAP); (* Switch from capture to compare mode *)
        INC(M.TA0CCR0^, Bitime_5)
      ELSE RRA(RXTXData, 1);
        IF BIT(M.TA0CCTL0^, M.SCCI) THEN BIS(RXTXData, {7}) END; (* Get bit waiting in receive latch *)
        DEC(BitCnt);
        IF BitCnt = 0 THEN (* All bits RXed? *)
  (*>>>>>>>>>> Decode of Received Byte Here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*)
          BIC(M.TA0CCTL0^, M.CCIE); (* All bits RXed, disable interrupt *)
          SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Clear LPM3 bits from 0(SP) *)
        END
  (*>>>>>>>>>> Decode of Received Byte Here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*)
      END
    END
  END Timer_A;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  M.BCSCTL3^ := M.XCAP_2;
  M.TA0CCTL0^ := M.OUT; (* TXD Idle as Mark *)
  M.TA0CTL^ := M.TASSEL_1 + M.MC_2; (* ACLK, continuous mode *)
  M.P1SEL^ := TXD + RXD;
  M.P1DIR^ := TXD;

  (* Mainloop *)
  REPEAT RX_Ready; (* UART ready to RX one Byte *)
    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3 w/ interr until char RXed *)
    TX_Byte (* TX Back RXed Byte Received *)
  UNTIL FALSE
END msp430g2xx3tauart2400.

OMSPTool.DecObj msp430g2xx3tauart2400.mpc
decode msp430g2xx3tauart2400.mpc
msp430g2xx3tauart2400 08C74C3D Flash   236
imports:
	msp430g2553 F10488DC
type descriptors

data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 00BC
fixup procedures chains
 00E6     0	 0000
 00DE     0	 0036
fixup handlers chains
 0119     0	 0042
fixup data chains
 00AA     0	 0002
 00A2     0	 0000
fixup constants chains
fixup types chains
entry =  00BC
code   236
 0000	     40F2	MOV.B #10,&0
 0002	     000A
 0004	     0000
 0006	     4292	MOV &368,&370
 0008	     0170
 000A	     0172
 000C	     9292	CMP &368,&370
 000E	     0170
 0010	     0172
 0012	     23F9	JNE $-12, goes to  0006
 0014	     50B2	ADD #14,&370
 0016	     000E
 0018	     0172
 001A	     50B2	ADD #256,&0
 001C	     0100
 001E	     0000
 0020	     5292	ADD &30,&34
 0022	     001E
 0024	     0022
 0026	     40B2	MOV #4144,&354
 0028	     1030
 002A	     0162
 002C	     B0B2	BIT #16,&354
 002E	     0010
 0030	     0162
 0032	     23FC	JNE $-6, goes to  002C
 0034	     4130	RET
 0036	     42F2	MOV.B #8,&4
 0038	     0004
 003A	     40B2	MOV #-30416,&354
 003C	     8930
 003E	     0162
 0040	     4130	RET
 0042	     50B2	ADD #14,&370
 0044	     000E
 0046	     0172
 0048	     B0B2	BIT #4096,&354
 004A	     1000
 004C	     0162
 004E	     2416	JEQ $+46, goes to  007C
 0050	     93C2	CMP.B #0,&56
 0052	     0038
 0054	     2004	JNE $+10, goes to  005E
 0056	     C0B2	BIC #16,&354
 0058	     0010
 005A	     0162
 005C	     3C0E	JMP $+30, goes to  007A
 005E	     D0B2	BIS #128,&354
 0060	     0080
 0062	     0162
 0064	     B392	BIT #1,&36
 0066	     0024
 0068	     2403	JEQ $+8, goes to  0070
 006A	     C0B2	BIC #128,&354
 006C	     0080
 006E	     0162
 0070	     C312	BIC #1,SR
 0072	     1012	RRC &102
 0074	     0066
 0076	     83D2	SUB.B #1,&82
 0078	     0052
 007A	     3C1F	JMP $+64, goes to  00BA
 007C	     B0B2	BIT #256,&354
 007E	     0100
 0080	     0162
 0082	     2407	JEQ $+16, goes to  0092
 0084	     C0B2	BIC #256,&354
 0086	     0100
 0088	     0162
 008A	     50B2	ADD #6,&370
 008C	     0006
 008E	     0172
 0090	     3C14	JMP $+42, goes to  00BA
 0092	     1112	RRA &116
 0094	     0074
 0096	     B0B2	BIT #1024,&354
 0098	     0400
 009A	     0162
 009C	     2403	JEQ $+8, goes to  00A4
 009E	     D0B2	BIS #128,&148
 00A0	     0080
 00A2	     0094
 00A4	     83D2	SUB.B #1,&120
 00A6	     0078
 00A8	     93C2	CMP.B #0,&166
 00AA	     00A6
 00AC	     2006	JNE $+14, goes to  00BA
 00AE	     C0B2	BIC #16,&354
 00B0	     0010
 00B2	     0162
 00B4	     C0B1	BIC #208,0(SP)
 00B6	     00D0
 00B8	     0000
 00BA	     1300	RETI
 00BC	     40B2	MOV #23168,&288
 00BE	     5A80
 00C0	     0120
 00C2	     42F2	MOV.B #8,&83
 00C4	     0053
 00C6	     42A2	MOV #4,&354
 00C8	     0162
 00CA	     40B2	MOV #288,&352
 00CC	     0120
 00CE	     0160
 00D0	     40F2	MOV.B #34,&38
 00D2	     0022
 00D4	     0026
 00D6	     40F2	MOV.B #32,&34
 00D8	     0020
 00DA	     0022
 00DC	     12B0	CALL #0
 00DE	     0000
 00E0	     D032	BIS #216,SR
 00E2	     00D8
 00E4	     12B0	CALL #0
 00E6	     0000
 00E8	     3FF9	JMP $-12, goes to  00DC
 00EA	     4130	RET
