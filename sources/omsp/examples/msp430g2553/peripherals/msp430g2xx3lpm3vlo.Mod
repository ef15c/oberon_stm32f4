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
//  MSP430G2xx3 Demo - Basic Clock, LPM3 Using WDT ISR, VLO ACLK
//
//  Description: This program operates MSP430 normally in LPM3, pulsing P1.0
//  ~ 6 second intervals. WDT ISR used to wake-up system. All I/O configured
//  as low outputs to eliminate floating inputs. Current consumption does
//  increase when LED is powered on P1.0. Demo for measuring LPM3 current.
//  ACLK = VLO/2, MCLK = SMCLK = default DCO
//
//
//           MSP430G2xx3
//         ---------------
//     /|\|            XIN|-
//      | |               |
//      --|RST        XOUT|-
//        |               |
//        |           P1.0|-->LED
//
//  Eason Zhou
//  Texas Instruments Inc.
//  January 2020
//  Ported to Oberon by C. Schoffit 30.08.2024
//******************************************************************************)

MODULE msp430g2xx3lpm3vlo;
  IMPORT SYSTEM, M := msp430g2553;

  VAR i: INTEGER;

  PROCEDURE* (M.WDT_VECTOR) watchdog_timer;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits) (* Clear LPM3 bits from SR backup *)
  END watchdog_timer;

BEGIN
  BIS(M.BCSCTL1^, M.DIVA_1); (* ACLK/2 *)
  BIS(M.BCSCTL3^, M.LFXT1S_2); (* ACLK = VLO *)
  M.WDTCTL^ := M.WDT_ADLY_1000; (* Interval timer *)
  BIS(M.IE1^, M.WDTIE); (* Enable WDT interrupt *)
  M.P1DIR^ := {0..7}; (* All P1.x outputs *)
  M.P1OUT^ := {}; (* All P1.x reset *)
  M.P2DIR^ := {0..7}; (* All P2.x outputs *)
  M.P2OUT^ := {}; (* All P2.x reset *)
  M.P3DIR^ := {0..7}; (* All P3.x outputs *)
  M.P3OUT^ := {}; (* All P3.x reset *)
  
  REPEAT 
    BIS(M.P1OUT^, {0}); (* Set P1.0 LED on *)
    i := 10000; REPEAT DEC(i) UNTIL i <= 0; (* Delay *)
    BIC(M.P1OUT^, {0}); (* Reset P1.0 LED off *)
    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* Enter LPM3 *)
  UNTIL FALSE
END msp430g2xx3lpm3vlo.

OMSPTool.DecObj msp430g2xx3lpm3vlo.mpc
decode msp430g2xx3lpm3vlo.mpc
msp430g2xx3lpm3vlo 4A3EF8F4 Flash    88
imports:
	msp430g2553 8CA01B9B
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF 0000 FFFF FFFF FFFF FFFF FFFF

entries
 0008
fixup procedures chains
fixup handlers chains
 011A     0	 0000
fixup data chains
 0048     0	 0000
fixup constants chains
fixup types chains
entry =  0008
code    88
 0000	     C0B1	BIC #208,0(SP)
 0002	     00D0
 0004	     0000
 0006	     1300	RETI
 0008	     D0F2	BIS.B #16,&87
 000A	     0010
 000C	     0057
 000E	     D0F2	BIS.B #32,&83
 0010	     0020
 0012	     0053
 0014	     40B2	MOV #23068,&288
 0016	     5A1C
 0018	     0120
 001A	     D3D2	BIS.B #1,&0
 001C	     0000
 001E	     43F2	MOV.B #-1,&34
 0020	     0022
 0022	     43C2	MOV.B #0,&33
 0024	     0021
 0026	     43F2	MOV.B #-1,&42
 0028	     002A
 002A	     43C2	MOV.B #0,&41
 002C	     0029
 002E	     43F2	MOV.B #-1,&26
 0030	     001A
 0032	     43C2	MOV.B #0,&25
 0034	     0019
 0036	     D3D2	BIS.B #1,&33
 0038	     0021
 003A	     40B2	MOV #10000,&0
 003C	     2710
 003E	     0000
 0040	     8392	SUB #1,&62
 0042	     003E
 0044	     430F	MOV #0,R15
 0046	     921F	CMP &66,R15
 0048	     0042
 004A	     3BFA	JL #-6, goes to  0040
 004C	     C3D2	BIC.B #1,&33
 004E	     0021
 0050	     D032	BIS #216,SR
 0052	     00D8
 0054	     3FF0	JMP #-16, goes to  0036
 0056	     4130	RET
