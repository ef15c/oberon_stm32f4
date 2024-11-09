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
//  MSP430G2xx3 Demo - USCI_B0 I2C Master Interface to DAC8571, Write
//
//  Description: Using UCB0TXIE, a continuous sine wave is output to the
//  external DAC using a 16-point look-up table. Only one start condition
//  is executed. Data is handled by the ISR and the CPU is normally in LPM0.
//  ACLK = n/a, MCLK = SMCLK = BRCLK = default DCO = ~1.2MHz
//
//               MSP430G2xx3                       DAC8571
//           ------------------                   ------------
//         -|XIN   P1.7/UCB0SDA|<--------------->|SDA         |
//          |      P1.6/UCB0SCL|---------------->|SCL  I2C    |
//         -|XOUT              |                 |    SLAVE   |
//          |     I2C MASTER   |              GND|A0          |
//
//
//  DAC8571 I2C address = 0x4C (A0 = GND)
//
//  D. Dang
//  Texas Instruments Inc.
//  February 2011
//  C. Schoffit 16.10.24 Built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscib0i2c03;
  IMPORT SYSTEM, M := msp430g2553;

  CONST 
    (* 16 Point 16-bit Sine Table MSB/LSB pair *)
    Sine_Tab = $
      FF FF F6 40 DA 81 B0 FA  7F FF 4F 03 25 7C 09 BD
      00 00 09 BD 25 7C 4F 03 7F FE B0 FA DA 81 F6 40$;

  VAR ByteCtr: BYTE;

  (* USCI_B0 Data ISR *)
  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCIAB0TX_ISR;
  BEGIN M.UCB0TXBUF^ := SYSTEM.VAL(BYTE, Sine_Tab[ByteCtr]); INC(ByteCtr); (* Transmit data byte *)
    AND(ByteCtr, 1FH) (* Do not exceed table *)
  END USCIAB0TX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop Watchdog Timer *)
  ByteCtr := 0;
  BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.P1SEL2^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
  M.UCB0CTL0^ := M.UCMST + M.UCMODE_3 + M.UCSYNC; (* I2C Master, synchronous mode *)
  M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
  M.UCB0BR0^ := 12; (* fSCL = SMCLK/12 = ~100kHz *)
  M.UCB0BR1^ := 0;
  M.UCB0I2CSA^ := 4CH; (* Set slave address *)
  BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
  BIS(M.IE2^, M.UCB0TXIE); (* Enable TX ready interrupt *)
  BIS(M.UCB0CTL1^, M.UCTR + M.UCTXSTT); (* I2C TX, start condition *)
  M.UCB0TXBUF^ :=10H; (* Write DAC control byte *)
  SYSTEM.BIS_SR(M.CPUOFF + M.GIE) (* Enter LPM0 w/ interrupts *)
END msp430g2xx3uscib0i2c03.

OMSPTool.DecObj msp430g2xx3uscib0i2c03.mpc
decode msp430g2xx3uscib0i2c03.mpc
msp430g2xx3uscib0i2c03 72C527C6 Flash   140
imports:
	msp430g2553 F10488DC
type descriptors

data     2
strings
\FF\FF\F6@ځ\B0\FA\FFO%|	\BD||	\BD%|O\FE\B0\FAځ\F6@
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 001C
fixup procedures chains
fixup handlers chains
 0116     0	 0000
fixup data chains
 0024     0	 0000
fixup constants chains
 0008     0	 0000
fixup types chains
entry =  001C
code   108
 0000	     120F	PUSH R15
 0002	     425F	MOV.B &0,R15
 0004	     0000
 0006	     503F	ADD #0,R15
 0008	     0000
 000A	     4FE2	MOV.B @R15,&111
 000C	     006F
 000E	     53D2	ADD.B #1,&4
 0010	     0004
 0012	     F0F2	AND.B #31,&16
 0014	     001F
 0016	     0010
 0018	     413F	POP R15
 001A	     1300	RETI
 001C	     40B2	MOV #23168,&288
 001E	     5A80
 0020	     0120
 0022	     43C2	MOV.B #0,&22
 0024	     0016
 0026	     D0F2	BIS.B #192,&38
 0028	     00C0
 002A	     0026
 002C	     D0F2	BIS.B #192,&65
 002E	     00C0
 0030	     0041
 0032	     D3D2	BIS.B #1,&105
 0034	     0069
 0036	     40F2	MOV.B #15,&104
 0038	     000F
 003A	     0068
 003C	     40F2	MOV.B #129,&105
 003E	     0081
 0040	     0069
 0042	     40F2	MOV.B #12,&106
 0044	     000C
 0046	     006A
 0048	     43C2	MOV.B #0,&107
 004A	     006B
 004C	     40B2	MOV #76,&282
 004E	     004C
 0050	     011A
 0052	     C3D2	BIC.B #1,&105
 0054	     0069
 0056	     D2F2	BIS.B #8,&1
 0058	     0001
 005A	     D0F2	BIS.B #18,&105
 005C	     0012
 005E	     0069
 0060	     40F2	MOV.B #16,&111
 0062	     0010
 0064	     006F
 0066	     D032	BIS #24,SR
 0068	     0018
 006A	     4130	RET
