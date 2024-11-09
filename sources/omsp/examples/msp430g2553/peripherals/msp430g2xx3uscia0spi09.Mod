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
//   MSP430G2xx3 Demo - USCI_A0, SPI 3-Wire Master Incremented Data
//
//   Description: SPI master talks to SPI slave using 3-wire mode. Incrementing
//   data is sent by the master starting at 0x01. Received data is expected to
//   be same as the previous transmission.  USCI RX ISR is used to handle
//   communication with the CPU, normally in LPM0. If high, P1.0 indicates
//   valid data reception.
//   ACLK = n/a, MCLK = SMCLK = DCO ~1.2MHz, BRCLK = SMCLK/2
//
//   Use with SPI Slave Data Echo code example. If slave is in debug mode, P3.6
//   slave reset signal conflicts with slave's JTAG; to work around, use IAR's
//   "Release JTAG on Go" on slave device.  If breakpoints are set in
//   slave RX ISR, master must stopped also to avoid overrunning slave
//   RXBUF.
//
//                    MSP430G2xx3
//                 -----------------
//             /|\|              XIN|-
//              | |                 |
//              --|RST          XOUT|-
//                |                 |
//                |             P1.2|-> Data Out (UCA0SIMO)
//                |                 |
//          LED <-|P1.0         P1.1|<- Data In (UCA0SOMI)
//                |                 |
//  Slave reset <-|P1.5         P1.4|-> Serial Clock Out (UCA0CLK)
//
//
//   D. Dang
//   Texas Instruments Inc.
//   February 2011
//   C. Schoffit 06.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscia0spi09;
  IMPORT SYSTEM, M := msp430g2553, Delay := msp430delay;

  VAR MST_Data, SLV_Data: BYTE;

  (* Test for valid RX and TX character *)
  PROCEDURE* (M.USCIAB0RX_VECTOR) {4} USCIA0RX_ISR;
  BEGIN REPEAT UNTIL BIT(M.IFG2^, M.UCA0TXIFG); (* USCI_A0 TX buffer ready? *)
    IF M.UCA0RXBUF^ = SLV_Data THEN (* Test for correct character RX'd *)
      BIS(M.P1OUT^, {0}); (* If correct, light LED *)
    ELSE BIC(M.P1OUT^, {0}); (* If incorrect, clear LED *)
    END;

    INC(MST_Data); (* Increment master value *)
    INC(SLV_Data); (* Increment expected slave value *)
    M.UCA0TXBUF^ := MST_Data; (* Send next value *)

    Delay.CyclesX3(50 DIV 3) (* Add time between transmissions to make sure slave can keep up *)
  END USCIA0RX_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  M.P1OUT^ :=  {}; (* P1 setup for LED & reset output *)
  BIS(M.P1DIR^, {0, 5});
  M.P1SEL^ := {1, 2, 4};
  M.P1SEL2^ := {1, 2, 4};
  BIS(M.UCA0CTL0^, M.UCCKPL + M.UCMSB + M.UCMST + M.UCSYNC); (* 3-pin, 8-bit SPI master *)
  BIS(M.UCA0CTL1^, M.UCSSEL_2); (* SMCLK *)
  BIS(M.UCA0BR0^, 2); (* /2 *)
  M.UCA0BR1^ := 0;
  M.UCA0MCTL^ := {}; (* No modulation *)
  BIC(M.UCA0CTL1^, M.UCSWRST); (* **Initialize USCI state machine** *)
  BIS(M.IE2^, M.UCA0RXIE); (* Enable USCI0 RX interrupt *)

  BIC(M.P1OUT^, {5}); (* Now with SPI signals initialized, *)
  BIS(M.P1OUT^, {5}); (* reset slave *)

  Delay.CyclesX3(75 DIV 3); (* Wait for slave to initialize *)

  MST_Data := 1; (* Initialize data values *)
  SLV_Data := 0;

  M.UCA0TXBUF^ := MST_Data; (* Transmit first character *)

  SYSTEM.BIS_SR(M.LPM0_bits + M.GIE) (* CPU off, enable interrupts *)
END msp430g2xx3uscia0spi09.

OMSPTool.DecObj msp430g2xx3uscia0spi09.mpc
decode msp430g2xx3uscia0spi09.mpc
msp430g2xx3uscia0spi09 9431AEA0 Flash   152
imports:
	msp430g2553 F10488DC
	msp430delay EE6A4099
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0034
fixup procedures chains
 0082     2	 0001
fixup handlers chains
 0117     0	 0000
fixup data chains
 008A     0	 0001
 008E     0	 0000
fixup constants chains
fixup types chains
entry =  0034
code   152
 0000	     1204	PUSH R4
 0002	     B3E2	BIT.B #2,&3
 0004	     0003
 0006	     27FD	JEQ $-4, goes to  0002
 0008	     92D2	CMP.B &0,&102
 000A	     0000
 000C	     0066
 000E	     2003	JNE $+8, goes to  0016
 0010	     D3D2	BIS.B #1,&33
 0012	     0021
 0014	     3C02	JMP $+6, goes to  001A
 0016	     C3D2	BIC.B #1,&33
 0018	     0021
 001A	     53D2	ADD.B #1,&0
 001C	     0000
 001E	     53D2	ADD.B #1,&10
 0020	     000A
 0022	     42D2	MOV.B &28,&103
 0024	     001C
 0026	     0067
 0028	     4034	MOV #16,R4
 002A	     0010
 002C	     12B0	CALL #0
 002E	     0000
 0030	     4134	POP R4
 0032	     1300	RETI
 0034	     40B2	MOV #23168,&288
 0036	     5A80
 0038	     0120
 003A	     43C2	MOV.B #0,&33
 003C	     0021
 003E	     D0F2	BIS.B #33,&34
 0040	     0021
 0042	     0022
 0044	     40F2	MOV.B #22,&38
 0046	     0016
 0048	     0026
 004A	     40F2	MOV.B #22,&65
 004C	     0016
 004E	     0041
 0050	     D0F2	BIS.B #105,&96
 0052	     0069
 0054	     0060
 0056	     D0F2	BIS.B #128,&97
 0058	     0080
 005A	     0061
 005C	     D3E2	BIS.B #2,&98
 005E	     0062
 0060	     43C2	MOV.B #0,&99
 0062	     0063
 0064	     43C2	MOV.B #0,&100
 0066	     0064
 0068	     C3D2	BIC.B #1,&97
 006A	     0061
 006C	     D3D2	BIS.B #1,&1
 006E	     0001
 0070	     C0F2	BIC.B #32,&33
 0072	     0020
 0074	     0021
 0076	     D0F2	BIS.B #32,&33
 0078	     0020
 007A	     0021
 007C	     4034	MOV #25,R4
 007E	     0019
 0080	     12B0	CALL #46
 0082	     002E
 0084	     43D2	MOV.B #1,&36
 0086	     0024
 0088	     43C2	MOV.B #0,&32
 008A	     0020
 008C	     42D2	MOV.B &134,&103
 008E	     0086
 0090	     0067
 0092	     D032	BIS #24,SR
 0094	     0018
 0096	     4130	RET
