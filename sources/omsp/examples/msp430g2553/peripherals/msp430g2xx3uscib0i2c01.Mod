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
//  MSP430G2xx3 Demo - USCI_B0 I2C Master to TMP100, Set P1.0 if Temp > 27C
//
//  Description: I2C interface to TMP100 temperature sensor in 9-bit mode.
//  Timer_A CCR0 interrupt is used to wake up and read the two bytes of
//  the TMP100 temperature register every 62ms. If the temperature is greater
//  than 27C, P1.0 is set, else reset. CPU is operated in LPM0. I2C speed
//  is ~100kHz.
//  ACLK = n/a, MCLK = SMCLK = TACLK = BRCLK = default DCO = ~1.2MHz
//
//         /|\           /|\ /|\
//          |   TMP100   10k 10k     MSP430G2xx3
//          |   -------   |   |   -------------------
//          +--|Vcc SDA|<-|---+->|P1.7/UCB0SDA    XIN|-
//          |  |       |  |      |                   |
//          +--|A1,A0  |  |      |               XOUT|-
//             |       |  |      |                   |
//          +--|Vss SCL|<-+------|P1.6/UCB0SCL   P1.0|---> LED
//         \|/  -------          |                   |
//
//  D. Dang
//  Texas Instruments Inc.
//  February 2011
//  C. Schoffit 10.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscib0i2c01;
  IMPORT SYSTEM, M := msp430g2553;

  VAR RxByteCtr, RxWord: INTEGER;

  PROCEDURE*(M.TIMER0_A0_VECTOR) TA0_ISR;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
  END TA0_ISR;

  (* The USCIAB0TX_ISR is structured such that it can be used to receive any
    2 + number of bytes by pre-loading RxByteCtr with the byte count. *)
  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCIAB0TX_ISR;
  BEGIN DEC(RxByteCtr); (* Decrement RX byte counter *)
    IF RxByteCtr # 0 THEN RxWord := M.UCB0RXBUF^; SWPB(RxWord); (* Get received byte *)
      IF RxByteCtr = 1 THEN (* Only one byte left? *) BIS(M.UCB0CTL1^, M.UCTXSTP) (* Generate I2C stop condition *) END;
    ELSE BIS(RxWord, M.UCB0RXBUF^); (* Get final received byte, Combine MSB and LSB *)
      SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
    END
  END USCIAB0TX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIS(M.P1DIR^, {0}); (* P1.0 output *)
  BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.P1SEL2^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
  M.UCB0CTL0^ := M.UCMST + M.UCMODE_3 + M.UCSYNC; (* I2C Master, synchronous mode *)
  M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
  M.UCB0BR0^ := 12; (* fSCL = SMCLK/12 = ~100kHz *)
  M.UCB0BR1^ := 0;
  M.UCB0I2CSA^ := 4EH; (* Set slave address *)
  BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
  BIS(M.IE2^, M.UCB0RXIE); (* Enable RX interrupt *)
  M.TA0CTL^ := M.TASSEL_2 + M.MC_2; (* SMCLK, contmode *)

  REPEAT RxByteCtr := 2; (* Load RX byte counter *)
    BIS(M.UCB0CTL1^, M.UCTXSTT); (* I2C start condition *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* Enter LPM0, enable interrupts *)
    (* Remain in LPM0 until all data is RX'd *)

    IF RxWord < 1B00H THEN (* >27C? *)
     BIC( M.P1OUT^, {0}) (* No, P1.0 = 0 *)
    ELSE BIS(M.P1OUT^, {0}) (* Yes, P1.0 = 1 *)
    END;

    SYSTEM.BIC_SR(M.GIE);
    BIS(M.TA0CCTL0^, M.CCIE); (* TACCR0 interrupt enabled *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* Enter LPM0, enable interrupts *)
    (* Remain in LPM0 until TACCR0 interrupt occurs*)
    BIC(M.TA0CCTL0^, M.CCIE); (* TACCR0 interrupt disabled *)
  UNTIL FALSE
END msp430g2xx3uscib0i2c01.

OMSPTool.DecObj msp430g2xx3uscib0i2c01.mpc
decode msp430g2xx3uscib0i2c01.mpc
msp430g2xx3uscib0i2c01 44953D36 Flash   182
imports:
	msp430g2553 F10488DC
type descriptors

data     4
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 003E
fixup procedures chains
fixup handlers chains
 0119     0	 0000
 0116     0	 0008
fixup data chains
 0084     0	 0000
 0092     0	 0002
fixup constants chains
fixup types chains
entry =  003E
code   182
 0000	     C0B1	BIC #16,0(SP)
 0002	     0010
 0004	     0000
 0006	     1300	RETI
 0008	     120F	PUSH R15
 000A	     8392	SUB #1,&0
 000C	     0000
 000E	     9382	CMP #0,&12
 0010	     000C
 0012	     240C	JEQ $+26, goes to  002C
 0014	     425F	MOV.B &110,R15
 0016	     006E
 0018	     4F82	MOV R15,&0
 001A	     0000
 001C	     1092	SWPB &26
 001E	     001A
 0020	     9392	CMP #1,&16
 0022	     0010
 0024	     2002	JNE $+6, goes to  002A
 0026	     D2E2	BIS.B #4,&105
 0028	     0069
 002A	     3C07	JMP $+16, goes to  003A
 002C	     425F	MOV.B &110,R15
 002E	     006E
 0030	     DF82	BIS R15,&30
 0032	     001E
 0034	     C0B1	BIC #16,2(SP)
 0036	     0010
 0038	     0002
 003A	     413F	POP R15
 003C	     1300	RETI
 003E	     40B2	MOV #23168,&288
 0040	     5A80
 0042	     0120
 0044	     D3D2	BIS.B #1,&34
 0046	     0022
 0048	     D0F2	BIS.B #192,&38
 004A	     00C0
 004C	     0026
 004E	     D0F2	BIS.B #192,&65
 0050	     00C0
 0052	     0041
 0054	     D3D2	BIS.B #1,&105
 0056	     0069
 0058	     40F2	MOV.B #15,&104
 005A	     000F
 005C	     0068
 005E	     40F2	MOV.B #129,&105
 0060	     0081
 0062	     0069
 0064	     40F2	MOV.B #12,&106
 0066	     000C
 0068	     006A
 006A	     43C2	MOV.B #0,&107
 006C	     006B
 006E	     40B2	MOV #78,&282
 0070	     004E
 0072	     011A
 0074	     C3D2	BIC.B #1,&105
 0076	     0069
 0078	     D2E2	BIS.B #4,&1
 007A	     0001
 007C	     40B2	MOV #544,&352
 007E	     0220
 0080	     0160
 0082	     43A2	MOV #2,&34
 0084	     0022
 0086	     D3E2	BIS.B #2,&105
 0088	     0069
 008A	     D032	BIS #24,SR
 008C	     0018
 008E	     90B2	CMP #6912,&50
 0090	     1B00
 0092	     0032
 0094	     3403	JGE $+8, goes to  009C
 0096	     C3D2	BIC.B #1,&33
 0098	     0021
 009A	     3C02	JMP $+6, goes to  00A0
 009C	     D3D2	BIS.B #1,&33
 009E	     0021
 00A0	     C232	BIC #8,SR
 00A2	     D0B2	BIS #16,&354
 00A4	     0010
 00A6	     0162
 00A8	     D032	BIS #24,SR
 00AA	     0018
 00AC	     C0B2	BIC #16,&354
 00AE	     0010
 00B0	     0162
 00B2	     3FE7	JMP $-48, goes to  0082
 00B4	     4130	RET
