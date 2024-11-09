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
//  MSP430G2xx3 Demo - USCI_B0 I2C Master Interface to PCF8574, Read/Write
//
//  Description: I2C communication with a PCF8574 in read and write mode is
//  demonstrated. PCF8574 port P is configured with P0-P3 input, P4-P7. Read
//  P0-P3 input data is written back to Port P4-P7. This example uses the
//  RX ISR and generates an I2C restart condition while switching from
//  master receiver to master transmitter.
//  ACLK = n/a, MCLK = SMCLK = TACLK = BRCLK = default DCO = ~1.2MHz
//
//                                MSP430G2xx3
//                              -----------------
//                  /|\ /|\ /|\|              XIN|-
//                  10k 10k  | |                 |
//       PCF8574     |   |   --|RST          XOUT|-
//       ---------   |   |     |                 |
//  --->|P0    SDA|<-|---+---->|P1.7/UCB0SDA     |
//  --->|P1       |  |         |                 |
//  --->|P2       |  |         |                 |
//  --->|P3    SCL|<-+---------|P1.6/UCB0SCL     |
//  <---|P4       |            |                 |
//  <---|P5       |            |                 |
//  <---|P6       |            |                 |
//  <---|P7       |            |                 |
//   +--|A0,A1,A2 |            |                 |
//   |  |         |            |                 |
//  \|/
//
//  D. Dang
//  Texas Instruments Inc.
//  February 2011
//  C. Schoffit 14.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscib0i2c02;
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE* (M.TIMER0_A0_VECTOR) TA0_ISR;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
  END TA0_ISR;

  (* USCI_B0 Data ISR *)
  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCIAB0TX_ISR;
  BEGIN M.UCB0TXBUF^ := (M.UCB0RXBUF^ * 10H) + 0FH; (* Move RX data to TX *)
  SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
  END USCIAB0TX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop Watchdog Timer *)
  
  BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.P1SEL2^, {6, 7}); (*Assign I2C pins to USCI_B0 *)
  BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
  M.UCB0CTL0^ := M.UCMST + M.UCMODE_3 + M.UCSYNC; (* I2C Master, synchronous mode *)
  M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
  M.UCB0BR0^ := 12; (* fSCL = SMCLK/12 = ~100kHz *)
  M.UCB0BR1^ := 0;
  M.UCB0I2CSA^ := 20H; (* Set slave address *)
  BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
  BIS(M.IE2^, M.UCB0RXIE); (* Enable RX interrupt *)
  M.TA0CCTL0^ := M.CCIE; (* TACCR0 interrupt enabled *)
  M.TA0CTL^ := M.TASSEL_2 + M.MC_2; (* SMCLK, contmode *)

  REPEAT SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* CPU off, interrupts enabled *)
    BIC(M.UCB0CTL1^, M.UCTR); (* I2C RX *)
    BIS(M.UCB0CTL1^, M.UCTXSTT); (* I2C start condition *)
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTT); (* Loop until I2C STT is sent *)
    BIS(M.UCB0CTL1^, M.UCTR + M.UCTXSTT); (* I2C TX, start condition *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* CPU off, interrupts enabled *)
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTT); (* Loop until I2C STT is sent *)
    BIS(M.UCB0CTL1^, M.UCTXSTP); (* I2C stop condition after 1st TX *)
  UNTIL FALSE
END msp430g2xx3uscib0i2c02.

OMSPTool.DecObj msp430g2xx3uscib0i2c02.mpc
decode msp430g2xx3uscib0i2c02.mpc
msp430g2xx3uscib0i2c02 69ED2ABE Flash   154
imports:
	msp430g2553 F10488DC
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0028
fixup procedures chains
fixup handlers chains
 0119     0	 0000
 0116     0	 0008
fixup data chains
fixup constants chains
fixup types chains
entry =  0028
code   154
 0000	     C0B1	BIC #16,0(SP)
 0002	     0010
 0004	     0000
 0006	     1300	RETI
 0008	     120F	PUSH R15
 000A	     425F	MOV.B &110,R15
 000C	     006E
 000E	     5F0F	ADD R15,R15
 0010	     5F0F	ADD R15,R15
 0012	     5F0F	ADD R15,R15
 0014	     5F0F	ADD R15,R15
 0016	     507F	ADD.B #15,R15
 0018	     000F
 001A	     4FC2	MOV.B R15,&111
 001C	     006F
 001E	     C0B1	BIC #16,2(SP)
 0020	     0010
 0022	     0002
 0024	     413F	POP R15
 0026	     1300	RETI
 0028	     40B2	MOV #23168,&288
 002A	     5A80
 002C	     0120
 002E	     D0F2	BIS.B #192,&38
 0030	     00C0
 0032	     0026
 0034	     D0F2	BIS.B #192,&65
 0036	     00C0
 0038	     0041
 003A	     D3D2	BIS.B #1,&105
 003C	     0069
 003E	     40F2	MOV.B #15,&104
 0040	     000F
 0042	     0068
 0044	     40F2	MOV.B #129,&105
 0046	     0081
 0048	     0069
 004A	     40F2	MOV.B #12,&106
 004C	     000C
 004E	     006A
 0050	     43C2	MOV.B #0,&107
 0052	     006B
 0054	     40B2	MOV #32,&282
 0056	     0020
 0058	     011A
 005A	     C3D2	BIC.B #1,&105
 005C	     0069
 005E	     D2E2	BIS.B #4,&1
 0060	     0001
 0062	     40B2	MOV #16,&354
 0064	     0010
 0066	     0162
 0068	     40B2	MOV #544,&352
 006A	     0220
 006C	     0160
 006E	     D032	BIS #24,SR
 0070	     0018
 0072	     C0F2	BIC.B #16,&105
 0074	     0010
 0076	     0069
 0078	     D3E2	BIS.B #2,&105
 007A	     0069
 007C	     B3E2	BIT.B #2,&105
 007E	     0069
 0080	     23FD	JNE $-4, goes to  007C
 0082	     D0F2	BIS.B #18,&105
 0084	     0012
 0086	     0069
 0088	     D032	BIS #24,SR
 008A	     0018
 008C	     B3E2	BIT.B #2,&105
 008E	     0069
 0090	     23FD	JNE $-4, goes to  008C
 0092	     D2E2	BIS.B #4,&105
 0094	     0069
 0096	     3FEB	JMP $-40, goes to  006E
 0098	     4130	RET
