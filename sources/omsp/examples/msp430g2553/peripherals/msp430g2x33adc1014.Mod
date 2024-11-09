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
//   MSP430G2x33/G2x53 Demo - ADC10, DTC Sample A1-0 16x, AVcc, Repeat Seq, DCO
//
//  Description: Use DTC to sample A1/A0 repeat sequence 16x(32 total samples)
//  with reference to AVcc.  Software sets ADC10SC to trigger sample burst.
//  In Mainloop MSP430 waits in LPM0 to save power until ADC10 conversion
//  complete, ADC10_ISR will force exit from any LPMx in Mainloop on reti.
//  ADC10 internal oscillator times sample period (16x) and conversion (13x).
//  DTC transfers conversion code to RAM 200h - 240h.  ADC10(DTC) interrupt
//  will return system active. 
//
//               MSP430G2x33/G2x53
//            -----------------
//        /|\|              XIN|-
//         | |                 |
//         --|RST          XOUT|-
//           |                 |
//       >---|P1.1/A1          |
//       >---|P1.0/A0          |
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 14.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2x33adc1014;
  IMPORT SYSTEM, M := msp430g2553;

  CONST nofSamples = 32;

  VAR samples: ARRAY nofSamples OF INTEGER;

  (* ADC10 interrupt service routine *)
  PROCEDURE* (M.ADC10_VECTOR) ADC10_ISR;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Clear CPUOFF bit from 0(SP) *)
  END ADC10_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  M.ADC10CTL1^ := M.INCH_1 + M.CONSEQ_3; (* A1/A0, repeat multi channel *)
  M.ADC10CTL0^ := M.ADC10SHT_2 + M.MSC + M.ADC10ON + M.ADC10IE;
  M.ADC10AE0^ := {0, 1}; (* P1.0,1 ADC option select *) 
  M.ADC10DTC1^ := nofSamples; (* 16 conversions *)

  REPEAT
    BIC(M.ADC10CTL0^, M.ENC);
    WHILE BIT(M.ADC10CTL1^, M.ADC10BUSY) DO END; (* Wait if ADC10 core is active *)
    M.ADC10SA^ := SYSTEM.ADR(samples); (* Data buffer start *)
    BIS(M.ADC10CTL0^, M.ENC + M.ADC10SC); (* Sampling and conversion ready *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* LPM0, ADC10_ISR will force exit *)
    NOP; (* space for debugger *)
    NOP (* Set Breakpoint here to read ADC *)
  UNTIL FALSE
END msp430g2x33adc1014.

OMSPTool.DecObj msp430g2x33adc1014.mpc
decode msp430g2x33adc1014.mpc
msp430g2x33adc1014 BF57F1FC Flash    74
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
 0034     0	 0000
fixup constants chains
fixup types chains
entry =  0008
code    74
 0000	     C0B1	BIC #16,0(SP)
 0002	     0010
 0004	     0000
 0006	     1300	RETI
 0008	     40B2	MOV #23168,&288
 000A	     5A80
 000C	     0120
 000E	     40B2	MOV #4102,&434
 0010	     1006
 0012	     01B2
 0014	     40B2	MOV #4248,&432
 0016	     1098
 0018	     01B0
 001A	     40F2	MOV.B #3,&74
 001C	     0003
 001E	     004A
 0020	     40F2	MOV.B #32,&73
 0022	     0020
 0024	     0049
 0026	     C3A2	BIC #2,&432
 0028	     01B0
 002A	     B392	BIT #1,&434
 002C	     01B2
 002E	     2401	JEQ #1, goes to  0032
 0030	     3FFC	JMP #-4, goes to  002A
 0032	     40B2	MOV #0,&444
 0034	     0000
 0036	     01BC
 0038	     D0B2	BIS #3,&432
 003A	     0003
 003C	     01B0
 003E	     D032	BIS #24,SR
 0040	     0018
 0042	     4303	NOP
 0044	     4303	NOP
 0046	     3FEF	JMP #-17, goes to  0026
 0048	     4130	RET
