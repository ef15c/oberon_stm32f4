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
//  MSP430G2x33/G2x53 Demo - ADC10, Output Internal Vref on P1.4 & ADCCLK on P1.3
//
//  Description: Output ADC10 internal Vref on P1.4, toggling between two
//  avaialble options, 2.5v and 1.5v. ADC10OSC also output on P1.3.
//
//               MSP430G2x33/G2x53
//            -----------------
//        /|\|              XIN|-
//         | |                 |
//         --|RST          XOUT|-
//           |                 |
//     Vref<-|A4/P1.4      P1.3|--> ADC10OSC ~ 3.5MHz - 6.5MHz
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 09.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x33adc1006;
  IMPORT SYSTEM, M := msp430g2553;

  PROCEDURE delay;
    VAR ih, il: INTEGER*;
  BEGIN ih := 7H; il := 0FFFFH;
    WHILE (ih # 0) OR (il # 0) DO DEC(il); SBC(ih, 0) END
  END delay;

  PROCEDURE* (M.TIMER0_A0_VECTOR) ^0 ta0_isr;
  BEGIN M.TA0CTL^ := {};
    SYSTEM.BIC_SR_ON_EXIT(M.LPM0_bits) (* Exit LPM0 on return *)
  END ta0_isr;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  M.ADC10CTL1^ := M.CONSEQ_2; (* Repeat single channel *)
  M.ADC10CTL0^ := M.REFOUT + M.REFON + M.MSC + M.ADC10ON;
  SYSTEM.BIS_SR(M.GIE); (* Enable interrupts. *)
  M.TA0CCR0^ := 30; (* Delay to allow Ref to settle *)
  BIS(M.TA0CCTL0^, M.CCIE); (* Compare-mode interrupt. *)
  M.TA0CTL^ := M.TASSEL_2 + M.MC_1; (* TACLK = SMCLK, Up mode. *)
  SYSTEM.BIS_SR(M.LPM0_bits); (* Wait for delay. *)
  BIC(M.TA0CCTL0^, M.CCIE); (* Disable timer Interrupt *)
  SYSTEM.BIC_SR(M.GIE);
  BIS(M.ADC10AE0^, {4}); (* P1.4 ADC option select *)
  (* Output ADC10CLK on P1.3 *)
  BIS(M.P1DIR^, {3}); (* Set P1.3 output direction *)
  BIS(M.P1SEL^, {3}); (* Set P1.3 option select *)

  REPEAT
    BIC(M.ADC10CTL0^, M.ENC); (* ADC10 disable *)
    XOR(M.ADC10CTL0^, M.REF2_5V); (* Toggle Vref 1.5/2.5V *)
    BIS(M.ADC10CTL0^, M.ENC + M.ADC10SC); (* Sampling and conversion start *)
    delay()
  UNTIL FALSE
END msp430g2x33adc1006.

OMSPTool.DecObj msp430g2x33adc1006.mpc
decode msp430g2x33adc1006.mpc
msp430g2x33adc1006 C00A8C81 Flash   120
imports:
	msp430g2553 8250CA0E
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0022
fixup procedures chains
 0072     0	 0000
fixup handlers chains
 0119     0	 0016
fixup data chains
fixup constants chains
fixup types chains
entry =  0022
code   120
 0000	     4034	MOV #7,R4
 0002	     0007
 0004	     4335	MOV #-1,R5
 0006	     9304	CMP #0,R4
 0008	     2002	JNE #2, goes to  000E
 000A	     9305	CMP #0,R5
 000C	     2403	JEQ #3, goes to  0014
 000E	     8315	SUB #1,R5
 0010	     7304	SUBC #0,R4
 0012	     3FF9	JMP #-7, goes to  0006
 0014	     4130	RET
 0016	     4382	MOV #0,&352
 0018	     0160
 001A	     C0B1	BIC #16,0(SP)
 001C	     0010
 001E	     0000
 0020	     1300	RETI
 0022	     40B2	MOV #23168,&288
 0024	     5A80
 0026	     0120
 0028	     42A2	MOV #4,&434
 002A	     01B2
 002C	     40B2	MOV #688,&432
 002E	     02B0
 0030	     01B0
 0032	     D232	BIS #8,SR
 0034	     40B2	MOV #30,&370
 0036	     001E
 0038	     0172
 003A	     D0B2	BIS #16,&354
 003C	     0010
 003E	     0162
 0040	     40B2	MOV #528,&352
 0042	     0210
 0044	     0160
 0046	     D032	BIS #16,SR
 0048	     0010
 004A	     C0B2	BIC #16,&354
 004C	     0010
 004E	     0162
 0050	     C232	BIC #8,SR
 0052	     D0F2	BIS.B #16,&74
 0054	     0010
 0056	     004A
 0058	     D2F2	BIS.B #8,&34
 005A	     0022
 005C	     D2F2	BIS.B #8,&38
 005E	     0026
 0060	     C3A2	BIC #2,&432
 0062	     01B0
 0064	     E0B2	XOR #64,&432
 0066	     0040
 0068	     01B0
 006A	     D0B2	BIS #3,&432
 006C	     0003
 006E	     01B0
 0070	     12B0	CALL #0
 0072	     0000
 0074	     3FF5	JMP #-11, goes to  0060
 0076	     4130	RET
