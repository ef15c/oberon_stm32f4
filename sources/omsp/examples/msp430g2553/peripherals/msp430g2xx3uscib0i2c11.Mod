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
//  MSP430G2xx3 Demo - USCI_B0 I2C Slave TX multiple bytes to MSP430 Master
//
//  Description: This demo connects two MSP430's via the I2C bus. The slave
//  transmits to the master. This is the slave code. The interrupt driven
//  data transmission is demonstrated using the USCI_B0 TX interrupt.
//  ACLK = n/a, MCLK = SMCLK = default DCO = ~1.2MHz
//
//  *** to be used with "msp430g2xx3_uscib0_i2c_10.c" ***
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
//  C. Schoffit 23.10.24, built with Oberon MSP430 compiler
//******************************************************************************)
MODULE msp430g2xx3uscib0i2c11;
  IMPORT SYSTEM, M := msp430g2553;

  CONST TxData = ($11 22 33 44 55$); (*Table of data to transmit *)

  VAR PTxData: PBYTE; (* Pointer to TX data *)
    TXByteCtr: BYTE;

  (* for USCI29 silicon erratum *)
  PROCEDURE* (M.TRAPINT_VECTOR) TRAPINT_ISR;
  END TRAPINT_ISR;

  (*------------------------------------------------------------------------------
   The USCI_B0 data ISR is used to move data from MSP430 memory to the
   I2C master. PTxData points to the next byte to be transmitted, and TXByteCtr
   keeps track of the number of bytes transmitted.
  ------------------------------------------------------------------------------*)
  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCIAB0TX_ISR;
  BEGIN M.UCB0TXBUF^ := PTxData^; INC(SYSTEM.VAL(INTEGER, PTxData)); (* Transmit data at address PTxData *)
    INC(TXByteCtr) (* Increment TX byte counter *)
  END USCIAB0TX_ISR;

  (*------------------------------------------------------------------------------
   The USCI_B0 state ISR is used to wake up the CPU from LPM0 in order to do
   processing in the main program after data has been transmitted. LPM0 is
   only exit in case of a (re-)start or stop condition when actual data
   was transmitted.
  ------------------------------------------------------------------------------*)
  PROCEDURE* (M.USCIAB0RX_VECTOR) USCIAB0RX_ISR;
  BEGIN BIC(M.UCB0STAT^, M.UCSTPIFG + M.UCSTTIFG); (* Clear interrupt flags *)
    IF TXByteCtr # 0 THEN (* Check TX byte counter *)
      SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 if data was transmitted *)
    END
  END USCIAB0RX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.P1SEL2^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
  M.UCB0CTL0^ := M.UCMODE_3 + M.UCSYNC; (* I2C Slave, synchronous mode *)
  M.UCB0I2COA^ := SYSTEM.VAL(SET, 48H); (* Own Address is 048h *)
  BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
  BIS(M.UCB0I2CIE^, M.UCSTPIE + M.UCSTTIE); (* Enable STT and STP interrupt *)
  BIS(M.IE2^, M.UCB0TXIE); (* Enable TX interrupt *)

  REPEAT PTxData := SYSTEM.VAL(PBYTE, SYSTEM.ADR(TxData)); (* Start of TX buffer *)
    TXByteCtr := 0; (* Clear TX byte count *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* Enter LPM0 w/ interrupts remain in LPM0 until master finishes RX *)
    NOP (* Set breakpoint >>here<< and read out the TXByteCtr counter *)
  UNTIL FALSE
END msp430g2xx3uscib0i2c11.
