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
//  MSP430G2xx3 Demo - USCI_B0 I2C Slave RX multiple bytes from MSP430 Master
//
//  Description: This demo connects two MSP430's via the I2C bus. The master
//  transmits to the slave. This is the slave code. The interrupt driven
//  data receiption is demonstrated using the USCIB0 RX interrupt.
//  ACLK = n/a, MCLK = SMCLK = default DCO = ~1.2MHz
//
//  *** to be used with "msp430g2xx3_uscib0_i2c_08.c" ***
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

MODULE msp430g2xx3uscib0i2c09;
  IMPORT SYSTEM, M := msp430g2553;

  VAR PRxData: PBYTE; (* Pointer to RX data *)
    RXByteCtr: BYTE;
    RxBuffer: ARRAY 128 OF BYTE; (* Allocate 128 byte of RAM *)

  (* for USCI29 silicon erratum *)
  PROCEDURE* (M.TRAPINT_VECTOR) TRAPINT_ISR;
  END TRAPINT_ISR;

  (*------------------------------------------------------------------------------
   The USCI_B0 data ISR is used to move received data from the I2C master
   to the MSP430 memory.
  ------------------------------------------------------------------------------*)
  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCIAB0TX_ISR;
  BEGIN PRxData^ := M.UCB0RXBUF^; INC(SYSTEM.VAL(INTEGER, PRxData)); (* Move RX data to address PRxData *)
    INC(RXByteCtr); (* Increment RX byte count *)
  END USCIAB0TX_ISR;

  (*------------------------------------------------------------------------------
   The USCI_B0 state ISR is used to wake up the CPU from LPM0 in order to
   process the received data in the main program. LPM0 is only exit in case
   of a (re-)start or stop condition when actual data was received.
  ------------------------------------------------------------------------------*)
  PROCEDURE* (M.USCIAB0RX_VECTOR) USCIAB0RX_ISR;
  BEGIN BIC(M.UCB0STAT^, M.UCSTPIFG + M.UCSTTIFG); (* Clear interrupt flags *)
    IF RXByteCtr # 0 THEN (* Check RX byte counter *)
      SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 if data was received *)
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
  BIS(M.IE2^, M.UCB0RXIE); (* Enable RX interrupt *)

  REPEAT PRxData := SYSTEM.VAL(PBYTE, SYSTEM.ADR(RxBuffer)); (* Start of RX buffer *)
    RXByteCtr := 0; (* Clear RX byte count *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* Enter LPM0 w/ interrupts, remain in LPM0 until master finishes TX *)
    NOP (* Set breakpoint >>here<< and read out the RxData buffer *)
  UNTIL FALSE
END msp430g2xx3uscib0i2c09.
