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
//  MSP430G2xx3 Demo - Basic Clock, Output Buffered clocks with preloaded DCO
//                     calibration constants for BCSCTL1 and DCOCTL.
//  Description: Buffer ACLK on P1.0, default SMCLK(DCO) on P1.4 and MCLK/10 on
//  P1.1. DCO is software selectable to 1, 8, 12, or 16Mhz using calibration
//  contstants in INFOA.
//
//  ACLK = LFXT1 = 32768, MCLK = SMCLK = Selectable at 1, 8, 12 or 16Mhz
//  //* External watch crystal installed on XIN XOUT is required for ACLK *//	
//	//* By default, the MSP430 uses XT1 to source ACLK; P2.6/7 configured 
//  //* automatically.
//               MSP430G2xx3
//             -----------------
//         /|\|         P2.6/XIN|-
//          | |                 | 32kHz
//          --|RST     P2.7/XOUT|-
//            |                 |
//            |       P1.4/SMCLK|-->SMCLK = Default DCO
//            |             P1.1|-->MCLK/10 = DCO/10
//            |        P1.0/ACLK|-->ACLK = 32kHz
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 20.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3dcocalib;
  IMPORT SYSTEM, M := msp430g2553;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop Watchdog Timer *)

  (* 1Mhz *)
  IF M.CALBC1_1MHZ^ = {0..7} THEN (* If calibration constant erased*) REPEAT UNTIL FALSE (*do not load, trap CPU!!*) END;
  M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
  M.BCSCTL1^ := M.CALBC1_1MHZ^; (* Set range *)
  M.DCOCTL^ := M.CALDCO_1MHZ^; (* Set DCO step + modulation *)

(*  (* 8Mhz *)
  IF M.CALBC1_8MHZ^ = {0..7} THEN (* If calibration constant erased*) REPEAT UNTIL FALSE (*do not load, trap CPU!!*) END;
  M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
  M.BCSCTL1^ := M.CALBC1_8MHZ^; (* Set range *)
  M.DCOCTL^ := M.CALDCO_8MHZ^; (* Set DCO step + modulation *)

  (* 12Mhz *)
  IF M.CALBC1_12MHZ^ = {0..7} THEN (* If calibration constant erased*) REPEAT UNTIL FALSE (*do not load, trap CPU!!*) END;
  M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
  M.BCSCTL1^ := M.CALBC1_12MHZ^; (* Set range *)
  M.DCOCTL^ := M.CALDCO_12MHZ^; (* Set DCO step + modulation *)

  (* 16Mhz *)
  IF M.CALBC1_16MHZ^ = {0..7} THEN (* If calibration constant erased*) REPEAT UNTIL FALSE (*do not load, trap CPU!!*) END;
  M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
  M.BCSCTL1^ := M.CALBC1_16MHZ^; (* Set range *)
  M.DCOCTL^ := M.CALDCO_16MHZ^; (* Set DCO step + modulation *) *)

  BIS(M.P1DIR^, {0, 1, 4}); (* P1.0,1 and P1.4 outputs *)
  BIS(M.P1SEL^, {0, 4}); (* P1.0,4 ACLK, SMCLK output *)

  REPEAT BIS(M.P1OUT^, {1}); (* P1.1 = 1 *) BIC(M.P1OUT^, {1}); (* P1.1 = 0 *) UNTIL FALSE
END msp430g2xx3dcocalib.

OMSPTool.DecObj msp430g2xx3dcocalib.mpc
decode msp430g2xx3dcocalib.mpc
msp430g2xx3dcocalib 01FCEFA5 Flash    54
imports:
	msp430g2553 A54A24F2
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0000
code    54
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     93F2	CMP.B #-1,&4351
 0008	     10FF
 000A	     2001	JNE $+4, goes to  000E
 000C	     3FFF	JMP $, goes to  000C
 000E	     43C2	MOV.B #0,&86
 0010	     0056
 0012	     42D2	MOV.B &4351,&87
 0014	     10FF
 0016	     0057
 0018	     42D2	MOV.B &4350,&86
 001A	     10FE
 001C	     0056
 001E	     D0F2	BIS.B #19,&34
 0020	     0013
 0022	     0022
 0024	     D0F2	BIS.B #17,&38
 0026	     0011
 0028	     0026
 002A	     D3E2	BIS.B #2,&33
 002C	     0021
 002E	     C3E2	BIC.B #2,&33
 0030	     0021
 0032	     3FFB	JMP $-8, goes to  002A
 0034	     4130	RET
