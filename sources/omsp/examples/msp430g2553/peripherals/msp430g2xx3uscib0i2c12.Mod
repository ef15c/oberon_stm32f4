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
//  MSP430G2xx3 Demo - USCI_B0 I2C Master TX/RX multiple bytes from MSP430 Slave
//                     with a repeated start in between TX and RX operations.
//
//  Description: This demo connects two MSP430's via the I2C bus. The master
//  transmits to the slave, then a repeated start is generated followed by a 
//  receive operation. This is the master code. This code demonstrates how to 
//  implement an I2C repeated start with the USCI module using the USCI_B0 TX 
//  interrupt.
//  ACLK = n/a, MCLK = SMCLK = BRCLK = default DCO = ~1.2MHz
//
//	***to be used with msp430x22x4_uscib0_i2c_13.c***
//
//                                /|\  /|\
//               MSP430F24x      10k  10k     MSP430G2xx3
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

MODULE msp430g2xx3uscib0i2c12;
  IMPORT SYSTEM, M := msp430g2553;

  CONST NUM_BYTES_TX = 3; (* How many bytes? *)
    NUM_BYTES_RX = 2;

  VAR RXByteCtr: INTEGER;
    RPT_Flag, RX: BOOLEAN; (* enables repeated start when TRUE *)
    RxBuffer: ARRAY 128 OF BYTE; (* Allocate 128 byte of RAM *)
    PRxData: PBYTE; (* Pointers to TX data and RX data *)
    TXByteCtr, MSData: BYTE;

  (*-------------------------------------------------------------------------------
   The USCI_B0 data ISR is used to move received data from the I2C slave
   to the MSP430 memory. It is structured such that it can be used to receive
   any 2+ number of bytes by pre-loading RXByteCtr with the byte count.
  -------------------------------------------------------------------------------*)
  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCIAB0TX_ISR;
  BEGIN
    IF RX THEN (* Master Recieve? *)
      DEC(RXByteCtr); (* Decrement RX byte counter *)
      IF RXByteCtr # 0 THEN PRxData^ := M.UCB0RXBUF^; (* Move RX data to address PRxData *)
        INC(SYSTEM.VAL(INTEGER, PRxData))
      ELSE
        IF ~RPT_Flag THEN BIS(M.UCB0CTL1^, M.UCTXSTP); (* No Repeated Start: stop condition *)
        ELSE (* if Repeated Start: do nothing *) RPT_Flag := FALSE END;
        PRxData^ := M.UCB0RXBUF^; (* Move final RX data to PRxData *)
        SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF); (* Exit LPM0 *)
      END
    ELSE (* Master Transmit *)
      IF TXByteCtr # 0 (* Check TX byte counter *)
      THEN M.UCB0TXBUF^ := MSData; (* Load TX buffer *)
        INC(MSData); DEC(TXByteCtr) (* Decrement TX byte counter *)
      ELSE
        IF RPT_Flag THEN RPT_Flag := FALSE;
          TXByteCtr := NUM_BYTES_TX; (* Load TX byte counter *)
          SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF)
        ELSE BIS(M.UCB0CTL1^, M.UCTXSTP); (* I2C stop condition *)
          BIC(M.IFG2^, M.UCB0TXIFG); (* Clear USCI_B0 TX int flag *)
          SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
        END
      END
    END
  END USCIAB0TX_ISR;

  PROCEDURE Setup_TX;
  BEGIN SYSTEM.BIC_SR(M.GIE);
    RX := FALSE;
    BIC(M.IE2^, M.UCB0RXIE);
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTP); (* Ensure stop condition got sent. Disable RX interrupt *)
    BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
    M.UCB0CTL0^ := M.UCMST + M.UCMODE_3 + M.UCSYNC; (* I2C Master, synchronous mode *)
    M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
    M.UCB0BR0^ := 12; (* fSCL = SMCLK/12 = ~100kHz *)
    M.UCB0BR1^ := 0;
    M.UCB0I2CSA^ := 48H; (* Slave Address is 048h *)
    BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
    BIS(M.IE2^, M.UCB0TXIE) (* Enable TX interrupt *)
  END Setup_TX;

  PROCEDURE Transmit;
  BEGIN
    TXByteCtr := NUM_BYTES_TX; (* Load TX byte counter *)
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTP); (* Ensure stop condition got sent *)
    BIS(M.UCB0CTL1^, M.UCTR + M.UCTXSTT); (* I2C TX, start condition *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE) (* Enter LPM0 w/ interrupts *)
  END Transmit;

  PROCEDURE Setup_RX;
  BEGIN SYSTEM.BIC_SR(M.GIE);
    RX := TRUE;
    BIC(M.IE2^, M.UCB0TXIE);
    BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
    M.UCB0CTL0^ := M.UCMST + M.UCMODE_3 + M.UCSYNC; (* I2C Master, synchronous mode *)
    M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
    M.UCB0BR0^ := 12; (* fSCL = SMCLK/12 = ~100kHz *)
    M.UCB0BR1^ := 0;
    M.UCB0I2CSA^ := 48H; (* Slave Address is 048h *)
    BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
    BIS(M.IE2^, M.UCB0RXIE) (* Enable RX interrupt *)
  END Setup_RX;

  PROCEDURE Receive;
  BEGIN
    PRxData := SYSTEM.VAL(PBYTE, SYSTEM.ADR(RxBuffer)); (* Start of RX buffer *)
    RXByteCtr := NUM_BYTES_RX-1; (* Load RX byte counter *)
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTP); (* Ensure stop condition got sent *)
    BIS(M.UCB0CTL1^, M.UCTXSTT); (* I2C start condition *)
    SYSTEM.BIS_SR(M.CPUOFF +M. GIE) (* Enter LPM0 w/ interrupts *)
  END Receive;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  RPT_Flag := FALSE;
  RX := FALSE;
  MSData := 55H;
  BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  BIS(M.P1SEL2^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
  
  REPEAT (* Transmit process *) Setup_TX;
    RPT_Flag := TRUE;
    Transmit;
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTP); (* Ensure stop condition got sent *)
  
    (* Receive process *) Setup_RX();
    Receive();
    REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTP); (* Ensure stop condition got sent *)
  UNTIL FALSE
END msp430g2xx3uscib0i2c12.

OMSPTool.DecObj msp430g2xx3uscib0i2c12.mpc
decode msp430g2xx3uscib0i2c12.mpc
msp430g2xx3uscib0i2c12 20E04D33 Flash   360
imports:
	msp430g2553 F10488DC
type descriptors

data   136
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0124
fixup procedures chains
 0146     0	 0084
 014E     0	 00BE
 0158     0	 00D6
 015C     0	 010A
fixup handlers chains
 0116     0	 0000
fixup data chains
 0130     0	 0003
 0112     0	 0000
 010E     0	 0084
 014A     0	 0002
 00C2     0	 0086
 0136     0	 0087
 010C     0	 0004
fixup constants chains
fixup types chains
entry =  0124
code   360
 0000	     120F	PUSH R15
 0002	     93C2	CMP.B #0,&0
 0004	     0000
 0006	     241E	JEQ $+62, goes to  0044
 0008	     8392	SUB #1,&0
 000A	     0000
 000C	     9382	CMP #0,&10
 000E	     000A
 0010	     2408	JEQ $+18, goes to  0022
 0012	     421F	MOV &0,R15
 0014	     0000
 0016	     42DF	MOV.B &110,0(R15)
 0018	     006E
 001A	     0000
 001C	     5392	ADD #1,&20
 001E	     0014
 0020	     3C10	JMP $+34, goes to  0042
 0022	     93C2	CMP.B #0,&0
 0024	     0000
 0026	     2003	JNE $+8, goes to  002E
 0028	     D2E2	BIS.B #4,&105
 002A	     0069
 002C	     3C02	JMP $+6, goes to  0032
 002E	     43C2	MOV.B #0,&36
 0030	     0024
 0032	     421F	MOV &30,R15
 0034	     001E
 0036	     42DF	MOV.B &110,0(R15)
 0038	     006E
 003A	     0000
 003C	     C0B1	BIC #16,2(SP)
 003E	     0010
 0040	     0002
 0042	     3C1E	JMP $+62, goes to  0080
 0044	     93C2	CMP.B #0,&0
 0046	     0000
 0048	     2408	JEQ $+18, goes to  005A
 004A	     42D2	MOV.B &0,&111
 004C	     0000
 004E	     006F
 0050	     53D2	ADD.B #1,&76
 0052	     004C
 0054	     83D2	SUB.B #1,&70
 0056	     0046
 0058	     3C13	JMP $+40, goes to  0080
 005A	     93C2	CMP.B #0,&48
 005C	     0030
 005E	     2409	JEQ $+20, goes to  0072
 0060	     43C2	MOV.B #0,&92
 0062	     005C
 0064	     40F2	MOV.B #3,&86
 0066	     0003
 0068	     0056
 006A	     C0B1	BIC #16,2(SP)
 006C	     0010
 006E	     0002
 0070	     3C07	JMP $+16, goes to  0080
 0072	     D2E2	BIS.B #4,&105
 0074	     0069
 0076	     C2F2	BIC.B #8,&3
 0078	     0003
 007A	     C0B1	BIC #16,2(SP)
 007C	     0010
 007E	     0002
 0080	     413F	POP R15
 0082	     1300	RETI
 0084	     C232	BIC #8,SR
 0086	     43C2	MOV.B #0,&4
 0088	     0004
 008A	     C2E2	BIC.B #4,&1
 008C	     0001
 008E	     B2E2	BIT.B #4,&105
 0090	     0069
 0092	     23FD	JNE $-4, goes to  008E
 0094	     D3D2	BIS.B #1,&105
 0096	     0069
 0098	     40F2	MOV.B #15,&104
 009A	     000F
 009C	     0068
 009E	     40F2	MOV.B #129,&105
 00A0	     0081
 00A2	     0069
 00A4	     40F2	MOV.B #12,&106
 00A6	     000C
 00A8	     006A
 00AA	     43C2	MOV.B #0,&107
 00AC	     006B
 00AE	     40B2	MOV #72,&282
 00B0	     0048
 00B2	     011A
 00B4	     C3D2	BIC.B #1,&105
 00B6	     0069
 00B8	     D2F2	BIS.B #8,&1
 00BA	     0001
 00BC	     4130	RET
 00BE	     40F2	MOV.B #3,&104
 00C0	     0003
 00C2	     0068
 00C4	     B2E2	BIT.B #4,&105
 00C6	     0069
 00C8	     23FD	JNE $-4, goes to  00C4
 00CA	     D0F2	BIS.B #18,&105
 00CC	     0012
 00CE	     0069
 00D0	     D032	BIS #24,SR
 00D2	     0018
 00D4	     4130	RET
 00D6	     C232	BIC #8,SR
 00D8	     43D2	MOV.B #1,&136
 00DA	     0088
 00DC	     C2F2	BIC.B #8,&1
 00DE	     0001
 00E0	     D3D2	BIS.B #1,&105
 00E2	     0069
 00E4	     40F2	MOV.B #15,&104
 00E6	     000F
 00E8	     0068
 00EA	     40F2	MOV.B #129,&105
 00EC	     0081
 00EE	     0069
 00F0	     40F2	MOV.B #12,&106
 00F2	     000C
 00F4	     006A
 00F6	     43C2	MOV.B #0,&107
 00F8	     006B
 00FA	     40B2	MOV #72,&282
 00FC	     0048
 00FE	     011A
 0100	     C3D2	BIC.B #1,&105
 0102	     0069
 0104	     D2E2	BIS.B #4,&1
 0106	     0001
 0108	     4130	RET
 010A	     40B2	MOV #0,&52
 010C	     0000
 010E	     0034
 0110	     4392	MOV #1,&14
 0112	     000E
 0114	     B2E2	BIT.B #4,&105
 0116	     0069
 0118	     23FD	JNE $-4, goes to  0114
 011A	     D3E2	BIS.B #2,&105
 011C	     0069
 011E	     D032	BIS #24,SR
 0120	     0018
 0122	     4130	RET
 0124	     40B2	MOV #23168,&288
 0126	     5A80
 0128	     0120
 012A	     43C2	MOV.B #0,&98
 012C	     0062
 012E	     43C2	MOV.B #0,&218
 0130	     00DA
 0132	     40F2	MOV.B #85,&82
 0134	     0055
 0136	     0052
 0138	     D0F2	BIS.B #192,&38
 013A	     00C0
 013C	     0026
 013E	     D0F2	BIS.B #192,&65
 0140	     00C0
 0142	     0041
 0144	     12B0	CALL #0
 0146	     0000
 0148	     43D2	MOV.B #1,&300
 014A	     012C
 014C	     12B0	CALL #0
 014E	     0000
 0150	     B2E2	BIT.B #4,&105
 0152	     0069
 0154	     23FD	JNE $-4, goes to  0150
 0156	     12B0	CALL #0
 0158	     0000
 015A	     12B0	CALL #0
 015C	     0000
 015E	     B2E2	BIT.B #4,&105
 0160	     0069
 0162	     23FD	JNE $-4, goes to  015E
 0164	     3FEF	JMP $-32, goes to  0144
 0166	     4130	RET
