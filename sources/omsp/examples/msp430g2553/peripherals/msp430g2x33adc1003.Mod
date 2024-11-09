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
//  MSP430G2x33/G2x53 Demo - ADC10, Sample A10 Temp, Set P1.0 if Temp ++ ~2C
//
//  Description: se ADC10 and the integrated temperature sensor to detect
//  temperature gradients. The temperature sensor output voltage is sampled
//  ~ every 120ms and compared with the defined delta values using an ISR.
//  (ADC10OSC/4)/64 determines sample time which needs to be greater than
//  30us for temperature sensor.
//  ADC10 is operated in repeat-single channel mode with the sample and
//  convert trigger sourced from Timer_A CCR1. The ADC10IFG at the end
//  of each converstion will trigger an ISR.
//  ACLK = n/a, MCLK = SMCLK = default DCO ~ 1.2MHz, ADC10CLK = ADC10OSC
//
//                MSP430G2x33/G2x53
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//            |A10          P1.0|-->LED
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit, 09.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x33adc1003;
  IMPORT SYSTEM, M := msp430g2553;

  CONST ADCDeltaOn = 3; (* ~ 2 Deg C delta for LED on *)

  VAR FirstADCVal: INTEGER; (* holds 1st ADC result*)

  PROCEDURE* (M.ADC10_VECTOR) {15} ADC10_ISR;
  BEGIN
    IF M.ADC10MEM^ >= FirstADCVal + ADCDeltaOn THEN BIS(M.P1OUT^, {0}) (* LED on *)
    ELSE BIC(M.P1OUT^, {0}) (* LED off *)
    END
  END ADC10_ISR;

  PROCEDURE* (M.TIMER0_A0_VECTOR) ta0_isr;
  BEGIN M.TA0CTL^ := {};
    SYSTEM.BIC_SR_ON_EXIT(M.LPM0_bits) (* Exit LPM0 on return *)
  END ta0_isr;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog *)
  M.ADC10CTL1^ := M.ADC10DIV_3 + M.INCH_10 + M.SHS_1 + M.CONSEQ_2; (* TA trig., rpt, A10 *)
  M.ADC10CTL0^ := M.SREF_1 + M.ADC10SHT_3 + M.REF2_5V + M.ADC10IE + M.REFON + M.ADC10ON;
  SYSTEM.BIS_SR(M.GIE); (* Enable interrupts. *)
  M.TA0CCR0^ := 30; (* Delay to allow Ref to settle *)
  BIS(M.TA0CCTL0^, M.CCIE); (* Compare-mode interrupt. *)
  M.TA0CTL^ := M.TASSEL_2 + M.MC_1; (* TACLK = SMCLK, Up mode. *)
  SYSTEM.BIS_SR(M.LPM0_bits); (* Wait for delay. *)
  BIC(M.TA0CCTL0^, M.CCIE); (* Disable timer Interrupt *)
  SYSTEM.BIC_SR(M.GIE);
  BIS(M.ADC10CTL0^, M.ENC);
  M.TA0CCTL1^ := M.OUTMOD_4; (* Toggle on EQU1 (TAR = 0) *)
  M.TA0CTL^ := M.TASSEL_2 + M.MC_2; (* SMCLK, cont-mode *)
  REPEAT UNTIL BIT(M.ADC10CTL0^, M.ADC10IFG); (* First conversion *)
  FirstADCVal := M.ADC10MEM^; (* Read out 1st ADC value *)
  M.P1OUT^ := {}; (* Clear P1 *)
  M.P1DIR^ :={0}; (* P1.0 as output *)
  SYSTEM.BIS_SR(M.LPM0_bits + M.GIE) (* Enter LPM0 w/ interrupt *)
END msp430g2x33adc1003.

OMSPTool.DecObj msp430g2x33adc1003.mpc
decode msp430g2x33adc1003.mpc
msp430g2x33adc1003 B782B419 Flash   134
imports:
	msp430g2553 F10488DC
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 002A
fixup procedures chains
fixup handlers chains
 0115     0	 0000
 0119     0	 001E
fixup data chains
 0076     0	 0000
fixup constants chains
fixup types chains
entry =  002A
code   134
 0000	     120F	PUSH R15
 0002	     421F	MOV &0,R15
 0004	     0000
 0006	     503F	ADD #3,R15
 0008	     0003
 000A	     9F82	CMP R15,&436
 000C	     01B4
 000E	     3803	JL $+8, goes to  0016
 0010	     D3D2	BIS.B #1,&33
 0012	     0021
 0014	     3C02	JMP $+6, goes to  001A
 0016	     C3D2	BIC.B #1,&33
 0018	     0021
 001A	     413F	POP R15
 001C	     1300	RETI
 001E	     4382	MOV #0,&352
 0020	     0160
 0022	     C0B1	BIC #16,0(SP)
 0024	     0010
 0026	     0000
 0028	     1300	RETI
 002A	     40B2	MOV #23168,&288
 002C	     5A80
 002E	     0120
 0030	     40B2	MOV #-23452,&434
 0032	     A464
 0034	     01B2
 0036	     40B2	MOV #14456,&432
 0038	     3878
 003A	     01B0
 003C	     D232	BIS #8,SR
 003E	     40B2	MOV #30,&370
 0040	     001E
 0042	     0172
 0044	     D0B2	BIS #16,&354
 0046	     0010
 0048	     0162
 004A	     40B2	MOV #528,&352
 004C	     0210
 004E	     0160
 0050	     D032	BIS #16,SR
 0052	     0010
 0054	     C0B2	BIC #16,&354
 0056	     0010
 0058	     0162
 005A	     C232	BIC #8,SR
 005C	     D3A2	BIS #2,&432
 005E	     01B0
 0060	     40B2	MOV #128,&356
 0062	     0080
 0064	     0164
 0066	     40B2	MOV #544,&352
 0068	     0220
 006A	     0160
 006C	     B2A2	BIT #4,&432
 006E	     01B0
 0070	     27FD	JEQ $-4, goes to  006C
 0072	     4292	MOV &436,&4
 0074	     01B4
 0076	     0004
 0078	     43C2	MOV.B #0,&33
 007A	     0021
 007C	     43D2	MOV.B #1,&34
 007E	     0022
 0080	     D032	BIS #24,SR
 0082	     0018
 0084	     4130	RET
