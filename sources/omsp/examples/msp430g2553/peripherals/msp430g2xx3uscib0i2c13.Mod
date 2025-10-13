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
//  MSP430x22x4 Demo - USCI_B0 I2C Slave RX/TX multiple bytes to MSP430 Master
//
//  Description: This demo connects two MSP430's via the I2C bus. The slave
//  recieves then transmits to the master. This is the slave code. The interrupt 
//  driven data transmission is demonstrated using the USCI_B0 TX interrupt.
//  ACLK = n/a, MCLK = SMCLK = default DCO = ~1.045Mhz
//
//	***to be used with msp430x22x4_uscib0_i2c_12.c***
//
//                                /|\  /|\
//               MSP430G2xx3       10k  10k     MSP430G2xx3
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
//  C. Schoffit 24.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscib0i2c13;
  IMPORT SYSTEM, M := msp430g2553;

  CONST NUM_BYTES = 2; (* How many bytes? *)
  (***** Please note this value needs to be the same as NUM_BYTES_RX in the
       associated master code. This definition lets the slave know when to
       switch from RX interrupt sources to TX interrupt sources. This is 
       important since the interrupt vectors are shared by TX and RX flags. *)

  VAR PRxData: PBYTE; (* Pointers to TX data and RX data *)
    RxBuffer: ARRAY 128 OF BYTE; (* Allocate 128 byte of RAM *)
    SLV_Data, TXByteCtr, RXByteCtr: BYTE;
    RX: BOOLEAN;

  (* for USCI29 silicon erratum *)
  PROCEDURE* (M.TRAPINT_VECTOR) TRAPINT_ISR;
  END TRAPINT_ISR;

  (*------------------------------------------------------------------------------
   The USCI_B0 data ISR is used to move data from MSP430 memory to the
   I2C master. PTxData points to the next byte to be transmitted, and TXByteCtr
   keeps track of the number of bytes transmitted.
  ------------------------------------------------------------------------------*)
  PROCEDURE* (M.USCIAB0TX_VECTOR) {15} USCIAB0TX_ISR;
  BEGIN
    IF ~RX  THEN M.UCB0TXBUF^ := SLV_Data; INC(SLV_Data); (* Transmit data at address PTxData *)
      INC(TXByteCtr) (* Increment TX byte counter *)
    ELSE PRxData^ := M.UCB0RXBUF^; INC(SYSTEM.VAL(INTEGER, PRxData)); (* Move RX data to address PRxData *)
      INC(RXByteCtr); (* Increment RX byte count *)
      IF RXByteCtr >= NUM_BYTES THEN (* Received enough bytes to switch *)
        RX := FALSE; (* to TX? *)
        BIC(M.IE2^, M.UCB0RXIE); BIS(M.IE2^, M.UCB0TXIE);
        RXByteCtr := 0
      END
    END
  END USCIAB0TX_ISR;

  (*------------------------------------------------------------------------------
   The USCI_B0 state ISR is used to wake up the CPU from LPM0 in order to do
   processing in the main program after data has been transmitted. LPM0 is
   only exit in case of a (re-)start or stop condition when actual data
   was transmitted.
  ------------------------------------------------------------------------------*)
  PROCEDURE* (M.USCIAB0RX_VECTOR) USCIAB0RX_ISR;
  BEGIN
    IF ~RX & (TXByteCtr # 0)  THEN (* Check TX byte counter *) (*shoudn't it be TXByteCtr = NUM_BYTES-1 according to the comment? *)
      SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 if data was transmitted *)
    END;
    BIC(M.UCB0STAT^, M.UCSTPIFG + M.UCSTTIFG) (* Clear interrupt flags *)
  END USCIAB0RX_ISR;

  PROCEDURE Setup_RX;
  BEGIN
    SYSTEM.BIC_SR(M.GIE);
    RX := TRUE;
    BIC(M.IE2^, M.UCB0TXIE); (* Disable TX interrupt *)
    BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
    M.UCB0CTL0^ := M.UCMODE_3 + M.UCSYNC; (* I2C Slave, synchronous mode *)
    M.UCB0I2COA^ := SYSTEM.VAL(SET, 48H); (* Own Address is 048h *)
    BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
    BIS(M.UCB0I2CIE^, M.UCSTPIE + M.UCSTTIE); (* Enable STT and STP interrupt *)
    BIS(M.IE2^, M.UCB0RXIE) (* Enable RX interrupt *)
  END Setup_RX;

  PROCEDURE Receive;
  BEGIN
    PRxData := SYSTEM.VAL(PBYTE, SYSTEM.ADR(RxBuffer)); (* Start of RX buffer *)
    RXByteCtr := 0; (* Clear RX byte count *)
    TXByteCtr := 0;
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE) (* Enter LPM0 w/ interrupts, remain in LPM0 until master finishes TX *)
  END Receive;

  PROCEDURE USCI_SLAVE_SETUP;
  BEGIN
    BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
    BIS(M.P1SEL2^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
    Setup_RX();
    Receive();
  END USCI_SLAVE_SETUP;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  SLV_Data := 11H;
  RX := FALSE;

  REPEAT USCI_SLAVE_SETUP UNTIL FALSE
END msp430g2xx3uscib0i2c13.

OMSPTool.DecObj msp430g2xx3uscib0i2c13.mpc
decode msp430g2xx3uscib0i2c13.mpc
msp430g2xx3uscib0i2c13 3BC8404B Flash   204
imports:
	msp430g2553 F10488DC
type descriptors

data   136
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 0000 FFFF FFFF FFFF FFFF FFFF 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 00B4
fixup procedures chains
 00AC     0	 0060
 00B0     0	 008A
 00C6     0	 009E
fixup handlers chains
 0110     0	 0000
 0116     0	 0002
 0117     0	 0046
fixup data chains
 00C2     0	 0087
 00BE     0	 0084
 0096     0	 0085
 008E     0	 0002
 0092     0	 0086
 008C     0	 0004
fixup constants chains
fixup types chains
entry =  00B4
code   204
 0000	     1300	RETI
 0002	     120F	PUSH R15
 0004	     93C2	CMP.B #0,&0
 0006	     0000
 0008	     2008	JNE $+18, goes to  001A
 000A	     42D2	MOV.B &0,&111
 000C	     0000
 000E	     006F
 0010	     53D2	ADD.B #1,&12
 0012	     000C
 0014	     53D2	ADD.B #1,&0
 0016	     0000
 0018	     3C14	JMP $+42, goes to  0042
 001A	     421F	MOV &0,R15
 001C	     0000
 001E	     42DF	MOV.B &110,0(R15)
 0020	     006E
 0022	     0000
 0024	     5392	ADD #1,&28
 0026	     001C
 0028	     53D2	ADD.B #1,&0
 002A	     0000
 002C	     93E2	CMP.B #2,&42
 002E	     002A
 0030	     2808	JNC $+18, goes to  0042
 0032	     43C2	MOV.B #0,&6
 0034	     0006
 0036	     C2E2	BIC.B #4,&1
 0038	     0001
 003A	     D2F2	BIS.B #8,&1
 003C	     0001
 003E	     43C2	MOV.B #0,&46
 0040	     002E
 0042	     413F	POP R15
 0044	     1300	RETI
 0046	     93C2	CMP.B #0,&52
 0048	     0034
 004A	     2006	JNE $+14, goes to  0058
 004C	     93C2	CMP.B #0,&22
 004E	     0016
 0050	     2403	JEQ $+8, goes to  0058
 0052	     C0B1	BIC #16,0(SP)
 0054	     0010
 0056	     0000
 0058	     C0F2	BIC.B #6,&109
 005A	     0006
 005C	     006D
 005E	     1300	RETI
 0060	     C232	BIC #8,SR
 0062	     43D2	MOV.B #1,&72
 0064	     0048
 0066	     C2F2	BIC.B #8,&1
 0068	     0001
 006A	     D3D2	BIS.B #1,&105
 006C	     0069
 006E	     40F2	MOV.B #7,&104
 0070	     0007
 0072	     0068
 0074	     40B2	MOV #72,&280
 0076	     0048
 0078	     0118
 007A	     C3D2	BIC.B #1,&105
 007C	     0069
 007E	     D0F2	BIS.B #6,&108
 0080	     0006
 0082	     006C
 0084	     D2E2	BIS.B #4,&1
 0086	     0001
 0088	     4130	RET
 008A	     40B2	MOV #0,&38
 008C	     0000
 008E	     0026
 0090	     43C2	MOV.B #0,&64
 0092	     0040
 0094	     43C2	MOV.B #0,&78
 0096	     004E
 0098	     D032	BIS #24,SR
 009A	     0018
 009C	     4130	RET
 009E	     D0F2	BIS.B #192,&38
 00A0	     00C0
 00A2	     0026
 00A4	     D0F2	BIS.B #192,&65
 00A6	     00C0
 00A8	     0041
 00AA	     12B0	CALL #0
 00AC	     0000
 00AE	     12B0	CALL #0
 00B0	     0000
 00B2	     4130	RET
 00B4	     40B2	MOV #23168,&288
 00B6	     5A80
 00B8	     0120
 00BA	     40F2	MOV.B #17,&18
 00BC	     0011
 00BE	     0012
 00C0	     43C2	MOV.B #0,&100
 00C2	     0064
 00C4	     12B0	CALL #0
 00C6	     0000
 00C8	     3FFD	JMP $-4, goes to  00C4
 00CA	     4130	RET
