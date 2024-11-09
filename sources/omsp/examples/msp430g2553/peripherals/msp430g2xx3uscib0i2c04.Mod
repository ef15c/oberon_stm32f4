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
//  MSP430G2xx3 Demo - USCI_B0 I2C Master RX single bytes from MSP430 Slave
//
//  Description: This demo connects two MSP430's via the I2C bus. The master
//  reads from the slave. This is the master code. The data from the slave
//  transmitter begins at 0 and increments with each transfer. The received
//  data is in R5 and is checked for validity. If the received data is
//  incorrect, the CPU is trapped and the P1.0 LED will stay on. The USCI_B0
//  RX interrupt is used to know when new data has been received.
//  ACLK = n/a, MCLK = SMCLK = BRCLK = default DCO = ~1.2MHz
//
//  *** to be used with "msp430g2xx3_uscib0_i2c_05.c" ***
//
//                                /|\  /|\
//               MSP430G2xx3      10k  10k     MSP430G2xx3
//                   slave         |    |        master
//             -----------------   |    |  -----------------
//           -|XIN  P1.7/UCB0SDA|<-|---+->|P1.7/UCB0SDA  XIN|-
//            |                 |  |      |                 | 32kHz
//           -|XOUT             |  |      |             XOUT|-
//            |     P1.6/UCB0SCL|<-+----->|P1.6/UCB0SCL     |
//            |                 |         |             P1.0|--> LED
//
//  D. Dang
//  Texas Instruments Inc.
//  February 2011
//  C. Schoffit 17.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscib0i2c04;
  IMPORT SYSTEM, M := msp430g2553;

  VAR RXData, RXCompare: BYTE;

  (* USCI_B0 Data ISR *)
  PROCEDURE* (M.USCIAB0TX_VECTOR) USCIAB0TX_ISR;
  BEGIN RXData := M.UCB0RXBUF^; (* Get RX data *)
  SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
  END USCIAB0TX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIC(M.P1OUT^, {0}); (* P1.0 = 0 *)
  BIS(M.P1DIR^, {0}); (* P1.0 output *)
  BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.P1SEL2^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
  M.UCB0CTL0^ := M.UCMST + M.UCMODE_3 + M.UCSYNC; (* I2C Master, synchronous mode *)
  M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
  M.UCB0BR0^ := 12; (* fSCL = SMCLK/12 = ~100kHz *)
  M.UCB0BR1^ := 0;
  M.UCB0I2CSA^ := 48H; (* Slave Address is 048h *)
  BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
  BIS(M.IE2^, M.UCB0RXIE); (* Enable RX interrupt *)
  RXCompare := 0; (* Used to check incoming data *)

  REPEAT
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTP); (* Ensure stop condition got sent *)
    BIS(M.UCB0CTL1^, M.UCTXSTT); (* I2C start condition *)
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTT); (* Start condition sent? *)
    BIS(M.UCB0CTL1^, M.UCTXSTP); (* I2C stop condition *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* Enter LPM0 w/ interrupts *)

    IF RXData # RXCompare THEN (* Trap CPU if wrong *) BIS(M.P1OUT^, {0}); (* P1.0 = 1 *) REPEAT UNTIL FALSE (* Trap CPU *)
    ELSE INC(RXCompare) (* Increment correct RX value *)
    END
  UNTIL FALSE
END msp430g2xx3uscib0i2c04.

OMSPTool.DecObj msp430g2xx3uscib0i2c04.mpc
decode msp430g2xx3uscib0i2c04.mpc
msp430g2xx3uscib0i2c04 331D05AE Flash   132
imports:
	msp430g2553 F10488DC
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 000E
fixup procedures chains
fixup handlers chains
 0116     0	 0000
fixup data chains
 0070     0	 0000
 007E     0	 0001
fixup constants chains
fixup types chains
entry =  000E
code   132
 0000	     42D2	MOV.B &110,&0
 0002	     006E
 0004	     0000
 0006	     C0B1	BIC #16,0(SP)
 0008	     0010
 000A	     0000
 000C	     1300	RETI
 000E	     40B2	MOV #23168,&288
 0010	     5A80
 0012	     0120
 0014	     C3D2	BIC.B #1,&33
 0016	     0021
 0018	     D3D2	BIS.B #1,&34
 001A	     0022
 001C	     D0F2	BIS.B #192,&38
 001E	     00C0
 0020	     0026
 0022	     D0F2	BIS.B #192,&65
 0024	     00C0
 0026	     0041
 0028	     D3D2	BIS.B #1,&105
 002A	     0069
 002C	     40F2	MOV.B #15,&104
 002E	     000F
 0030	     0068
 0032	     40F2	MOV.B #129,&105
 0034	     0081
 0036	     0069
 0038	     40F2	MOV.B #12,&106
 003A	     000C
 003C	     006A
 003E	     43C2	MOV.B #0,&107
 0040	     006B
 0042	     40B2	MOV #72,&282
 0044	     0048
 0046	     011A
 0048	     C3D2	BIC.B #1,&105
 004A	     0069
 004C	     D2E2	BIS.B #4,&1
 004E	     0001
 0050	     43C2	MOV.B #0,&0
 0052	     0000
 0054	     B2E2	BIT.B #4,&105
 0056	     0069
 0058	     23FD	JNE $-4, goes to  0054
 005A	     D3E2	BIS.B #2,&105
 005C	     0069
 005E	     B3E2	BIT.B #2,&105
 0060	     0069
 0062	     23FD	JNE $-4, goes to  005E
 0064	     D2E2	BIS.B #4,&105
 0066	     0069
 0068	     D032	BIS #24,SR
 006A	     0018
 006C	     92D2	CMP.B &82,&4
 006E	     0052
 0070	     0004
 0072	     2404	JEQ $+10, goes to  007C
 0074	     D3D2	BIS.B #1,&33
 0076	     0021
 0078	     3FFF	JMP $, goes to  0078
 007A	     3C02	JMP $+6, goes to  0080
 007C	     53D2	ADD.B #1,&110
 007E	     006E
 0080	     3FE9	JMP $-44, goes to  0054
 0082	     4130	RET
