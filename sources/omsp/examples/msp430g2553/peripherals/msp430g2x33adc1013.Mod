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
//  MSP430G2x33/G2x53 Demo - ADC10, DTC Sample A1 32x, AVcc, TA0 Trig, DCO
//
//  Description; A1 is sampled in 32x burst using DTC 16 times per second
//  (ACLK/2048) with reference to AVcc. Activity is interrupt driven.
//  Timer_A in upmode uses TA0 toggle to drive ADC10 conversion. Sample burst
//  is automatically triggered by TA0 rising edge every 2048 ACLK cycles.
//  ADC10_ISR will exit from LPM3 mode and return CPU active. Internal ADC10OSC
//  times sample (16x) and conversion (13x). DTC transfers conversion code to
//  RAM 200h - 240h. In the Mainloop P1.0 is toggled. Normal Mode is LPM3.
//  //* An external watch crystal on XIN XOUT is required for ACLK *//
//
//               MSP430G2x33/G2x53
//            -----------------
//        /|\|              XIN|-
//         | |                 | 32kHz
//         --|RST          XOUT|-
//           |                 |
//       >---|P1.1/A1     P1.0 |--> LED
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x33adc1013;
  IMPORT SYSTEM, M := msp430g2553;

  CONST nofSamples = 32;

  VAR samples: ARRAY nofSamples OF INTEGER;

  (* ADC10 interrupt service routine *)
  PROCEDURE* (M.ADC10_VECTOR) ADC10_ISR;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits); (* Clear LPM3 bits from 0(SP) *)
  END ADC10_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  M.ADC10CTL1^ := M.INCH_1 + M.SHS_2 + M.CONSEQ_2; (* TA0 trigger *)
  M.ADC10CTL0^ := M.ADC10SHT_2 + M.MSC + M.ADC10ON + M.ADC10IE;
  M.ADC10DTC1^ := nofSamples; (* 32 conversions *)
  BIS(M.P1DIR^, {0}); (* Set P1.0 output *)
  BIS(M.ADC10AE0^, {1}); (* P1.1 ADC10 option select *)
  M.TA0CCR0^ := 1024-1; (* PWM Period *)
  M.TA0CCTL0^ := M.OUTMOD_4; (* TACCR0 toggle *)
  M.TA0CTL^ := M.TASSEL_1 + M.MC_1; (* ACLK, up mode *)

  REPEAT
    BIC(M.ADC10CTL0^, M.ENC);
    WHILE BIT(M.ADC10CTL1^, M.ADC10BUSY) DO END; (* Wait if ADC10 core is active *)
    M.ADC10SA^ := SYSTEM.ADR(samples); (* Data buffer start *)
    BIS(M.ADC10CTL0^, M.ENC); (* Sampling and conversion ready *)
    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE); (* Enter LPM3, enable interrupts *)
    XOR(M.P1OUT^, {0}); (* Toggle P1.0 using exclusive-OR *)
  UNTIL FALSE
END msp430g2x33adc1013.

OMSPTool.DecObj msp430g2x33adc1013.mpc
decode msp430g2x33adc1013.mpc
msp430g2x33adc1013 FE8FD394 Flash    92
imports:
	msp430g2553 8250CA0E
type descriptors

data    64
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0008
fixup procedures chains
fixup handlers chains
 0115     0	 0000
fixup data chains
 0048     0	 0000
fixup constants chains
fixup types chains
entry =  0008
code    92
 0000	     C0B1	BIC #208,0(SP)
 0002	     00D0
 0004	     0000
 0006	     1300	RETI
 0008	     40B2	MOV #23168,&288
 000A	     5A80
 000C	     0120
 000E	     40B2	MOV #6148,&434
 0010	     1804
 0012	     01B2
 0014	     40B2	MOV #4248,&432
 0016	     1098
 0018	     01B0
 001A	     40F2	MOV.B #32,&73
 001C	     0020
 001E	     0049
 0020	     D3D2	BIS.B #1,&34
 0022	     0022
 0024	     D3E2	BIS.B #2,&74
 0026	     004A
 0028	     40B2	MOV #1023,&370
 002A	     03FF
 002C	     0172
 002E	     40B2	MOV #128,&354
 0030	     0080
 0032	     0162
 0034	     40B2	MOV #272,&352
 0036	     0110
 0038	     0160
 003A	     C3A2	BIC #2,&432
 003C	     01B0
 003E	     B392	BIT #1,&434
 0040	     01B2
 0042	     2401	JEQ #1, goes to  0046
 0044	     3FFC	JMP #-4, goes to  003E
 0046	     40B2	MOV #0,&444
 0048	     0000
 004A	     01BC
 004C	     D3A2	BIS #2,&432
 004E	     01B0
 0050	     D032	BIS #216,SR
 0052	     00D8
 0054	     E3D2	XOR.B #1,&33
 0056	     0021
 0058	     3FF0	JMP #-16, goes to  003A
 005A	     4130	RET
