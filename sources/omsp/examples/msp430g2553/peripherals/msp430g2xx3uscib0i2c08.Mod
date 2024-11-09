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
//  MSP430G2xx3 Demo - USCI_B0 I2C Master TX multiple bytes to MSP430 Slave
//
//  Description: This demo connects two MSP430's via the I2C bus. The master
//  transmits to the slave. This is the master code. It continuously
//  transmits an array of data and demonstrates how to implement an I2C
//  master transmitter sending multiple bytes using the USCI_B0 TX interrupt.
//  ACLK = n/a, MCLK = SMCLK = BRCLK = default DCO = ~1.2MHz
//
//  *** to be used with "msp430g2xx3_uscib0_i2c_09.c" ***
//
//                                /|\  /|\
//               MSP430G2xx3      10k  10k     MSP430G2xx3
//                   slave         |    |        master
//             -----------------   |    |  -----------------
//           -|XIN  P3.1/UCB0SDA|<-|---+->|P3.1/UCB0SDA  XIN|-
//            |                 |  |      |                 |
//           -|XOUT             |  |      |             XOUT|-
//            |     P3.2/UCB0SCL|<-+----->|P3.2/UCB0SCL     |
//            |                 |         |                 |
//
//  D. Dang
//  Texas Instruments Inc.
//  February 2011
//  C. Schoffit 22.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscib0i2c08;
  IMPORT SYSTEM, M := msp430g2553;

  CONST TxData = ($11 22 33 44 55$); (* Table of data to transmit *)

  VAR PTxData: PBYTE; (* Pointer to TX data *)
    TXByteCtr: BYTE;

  (*------------------------------------------------------------------------------
   The USCIAB0TX_ISR is structured such that it can be used to transmit any
   number of bytes by pre-loading TXByteCtr with the byte count. Also, TXData
   points to the next byte to transmit.
  ------------------------------------------------------------------------------*)

  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCIAB0TX_ISR;
  BEGIN
    IF TXByteCtr # 0 THEN (* Check TX byte counter *)
      M.UCB0TXBUF^ := PTxData^; INC(SYSTEM.VAL(INTEGER, PTxData)); (* Load TX buffer *)
      DEC(TXByteCtr) (* Decrement TX byte counter *)
    ELSE BIS(M.UCB0CTL1^, M.UCTXSTP); (* I2C stop condition *)
      BIC(M.IFG2^, M.UCB0TXIFG); (* Clear USCI_B0 TX int flag *)
      SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
    END
  END USCIAB0TX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.P1SEL2^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
  M.UCB0CTL0^ := M.UCMST + M.UCMODE_3 + M.UCSYNC; (* I2C Master, synchronous mode*)
  M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
  M.UCB0BR0^ := 12; (* fSCL = SMCLK/12 = ~100kHz *)
  M.UCB0BR1^ := 0;
  M.UCB0I2CSA^ := 48H; (* Slave Address is 048h *)
  BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
  BIS(M.IE2^, M.UCB0TXIE); (* Enable TX interrupt *)

  REPEAT PTxData := SYSTEM.VAL(PBYTE, SYSTEM.ADR(TxData)); (* TX array start address *)
    TXByteCtr := LEN(TxData); (* Load TX byte counter *)
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTP); (* Ensure stop condition got sent *)
    BIS(M.UCB0CTL1^, M.UCTR + M.UCTXSTT); (* I2C TX, start condition *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE) (* Enter LPM0 w/ interrupts, remain in LPM0 until all data is TX'd *)
  UNTIL FALSE
END msp430g2xx3uscib0i2c08.

OMSPTool.DecObj msp430g2xx3uscib0i2c08.mpc
decode msp430g2xx3uscib0i2c08.mpc
msp430g2xx3uscib0i2c08 86FD5B8E Flash   140
imports:
	msp430g2553 F10488DC
type descriptors

data     4
strings
"3DU|
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 002C
fixup procedures chains
fixup handlers chains
 0116     0	 0000
fixup data chains
 0070     0	 0002
 006A     0	 0000
fixup constants chains
 0068     0	 0000
fixup types chains
entry =  002C
code   134
 0000	     120F	PUSH R15
 0002	     93C2	CMP.B #0,&0
 0004	     0000
 0006	     2409	JEQ $+20, goes to  001A
 0008	     421F	MOV &0,R15
 000A	     0000
 000C	     4FE2	MOV.B @R15,&111
 000E	     006F
 0010	     5392	ADD #1,&10
 0012	     000A
 0014	     83D2	SUB.B #1,&4
 0016	     0004
 0018	     3C07	JMP $+16, goes to  0028
 001A	     D2E2	BIS.B #4,&105
 001C	     0069
 001E	     C2F2	BIC.B #8,&3
 0020	     0003
 0022	     C0B1	BIC #16,2(SP)
 0024	     0010
 0026	     0002
 0028	     413F	POP R15
 002A	     1300	RETI
 002C	     40B2	MOV #23168,&288
 002E	     5A80
 0030	     0120
 0032	     D0F2	BIS.B #192,&38
 0034	     00C0
 0036	     0026
 0038	     D0F2	BIS.B #192,&65
 003A	     00C0
 003C	     0041
 003E	     D3D2	BIS.B #1,&105
 0040	     0069
 0042	     40F2	MOV.B #15,&104
 0044	     000F
 0046	     0068
 0048	     40F2	MOV.B #129,&105
 004A	     0081
 004C	     0069
 004E	     40F2	MOV.B #12,&106
 0050	     000C
 0052	     006A
 0054	     43C2	MOV.B #0,&107
 0056	     006B
 0058	     40B2	MOV #72,&282
 005A	     0048
 005C	     011A
 005E	     C3D2	BIC.B #1,&105
 0060	     0069
 0062	     D2F2	BIS.B #8,&1
 0064	     0001
 0066	     40B2	MOV #0,&18
 0068	     0000
 006A	     0012
 006C	     40F2	MOV.B #5,&22
 006E	     0005
 0070	     0016
 0072	     B2E2	BIT.B #4,&105
 0074	     0069
 0076	     23FD	JNE $-4, goes to  0072
 0078	     D0F2	BIS.B #18,&105
 007A	     0012
 007C	     0069
 007E	     D032	BIS #24,SR
 0080	     0018
 0082	     3FF1	JMP $-28, goes to  0066
 0084	     4130	RET
