(* ============================================================================ *)
(* Copyright (c) 2020, Texas Instruments Incorporated                           *)
(*  All rights reserved.                                                        *)
(*                                                                              *)
(*  Redistribution and use in source and binary forms, with or without          *)
(*  modification, are permitted provided that the following conditions          *)
(*  are met:                                                                    *)
(*                                                                              *)
(*  *  Redistributions of source code must retain the above copyright           *)
(*     notice, this list of conditions and the following disclaimer.            *)
(*                                                                              *)
(*  *  Redistributions in binary form must reproduce the above copyright        *)
(*     notice, this list of conditions and the following disclaimer in the      *)
(*     documentation and/or other materials provided with the distribution.     *)
(*                                                                              *)
(*  *  Neither the name of Texas Instruments Incorporated nor the names of      *)
(*     its contributors may be used to endorse or promote products derived      *)
(*     from this software without specific prior written permission.            *)
(*                                                                              *)
(*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,       *)
(*  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR      *)
(*  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR            *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,       *)
(*  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,         *)
(*  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; *)
(*  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,    *)
(*  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR     *)
(*  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,              *)
(*  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                          *)
(* ============================================================================ *)

(******************************************************************************)
(* msp430g2513.Mod                                                            *)
(*    - Module for definition of peripheral memory map                        *)
(*    Please do not change !                                                  *)
(*                                                                            *)
(******************************************************************************)
(* Version: 1.213                                                             *)
(******************************************************************************)

MODULE msp430g2553;
  IMPORT SYSTEM;
  CONST
  
(************************************************************
* STANDARD BITS
************************************************************)
(************************************************************
* STATUS REGISTER BITS
************************************************************)
(************************************************************
* PERIPHERAL FILE MAP
************************************************************)
(************************************************************
* SPECIAL FUNCTION REGISTER ADDRESSES + CONTROL BITS
************************************************************)
IE1*                = SYSTEM.VAL(PBYTE, 0000H);
IFG1*               = SYSTEM.VAL(PBYTE, 0002H);
IE2*                = SYSTEM.VAL(PBYTE, 0001H);
IFG2*               = SYSTEM.VAL(PBYTE, 0003H);
(************************************************************
* Basic Clock Module
************************************************************)
DCOCTL*             = SYSTEM.VAL(PBYTE, 0056H);
BCSCTL1*            = SYSTEM.VAL(PBYTE, 0057H);
BCSCTL2*            = SYSTEM.VAL(PBYTE, 0058H);
BCSCTL3*            = SYSTEM.VAL(PBYTE, 0053H);
(************************************************************
* Comparator A
************************************************************)
CACTL1*             = SYSTEM.VAL(PBYTE, 0059H);
CACTL2*             = SYSTEM.VAL(PBYTE, 005AH);
CAPD*               = SYSTEM.VAL(PBYTE, 005BH);
(*************************************************************
* Flash Memory
*************************************************************)
FCTL1*              = SYSTEM.VAL(PBYTE, 0128H);
FCTL2*              = SYSTEM.VAL(PBYTE, 012AH);
FCTL3*              = SYSTEM.VAL(PBYTE, 012CH);
(************************************************************
* DIGITAL I/O Port1/2 Pull up / Pull down Resistors
************************************************************)
P1IN*               = SYSTEM.VAL(PBYTE, 0020H);
P1OUT*              = SYSTEM.VAL(PBYTE, 0021H);
P1DIR*              = SYSTEM.VAL(PBYTE, 0022H);
P1IFG*              = SYSTEM.VAL(PBYTE, 0023H);
P1IES*              = SYSTEM.VAL(PBYTE, 0024H);
P1IE*               = SYSTEM.VAL(PBYTE, 0025H);
P1SEL*              = SYSTEM.VAL(PBYTE, 0026H);
P1SEL2*             = SYSTEM.VAL(PBYTE, 0041H);
P1REN*              = SYSTEM.VAL(PBYTE, 0027H);
P2IN*               = SYSTEM.VAL(PBYTE, 0028H);
P2OUT*              = SYSTEM.VAL(PBYTE, 0029H);
P2DIR*              = SYSTEM.VAL(PBYTE, 002AH);
P2IFG*              = SYSTEM.VAL(PBYTE, 002BH);
P2IES*              = SYSTEM.VAL(PBYTE, 002CH);
P2IE*               = SYSTEM.VAL(PBYTE, 002DH);
P2SEL*              = SYSTEM.VAL(PBYTE, 002EH);
P2SEL2*             = SYSTEM.VAL(PBYTE, 0042H);
P2REN*              = SYSTEM.VAL(PBYTE, 002FH);
(************************************************************
* DIGITAL I/O Port3 Pull up / Pull down Resistors
************************************************************)
P3IN*               = SYSTEM.VAL(PBYTE, 0018H);
P3OUT*              = SYSTEM.VAL(PBYTE, 0019H);
P3DIR*              = SYSTEM.VAL(PBYTE, 001AH);
P3SEL*              = SYSTEM.VAL(PBYTE, 001BH);
P3SEL2*             = SYSTEM.VAL(PBYTE, 0043H);
P3REN*              = SYSTEM.VAL(PBYTE, 0010H);
(************************************************************
* Timer0_A3
************************************************************)
TA0IV*              = SYSTEM.VAL(PBYTE, 012EH);
TA0CTL*             = SYSTEM.VAL(PBYTE, 0160H);
TA0CCTL0*           = SYSTEM.VAL(PBYTE, 0162H);
TA0CCTL1*           = SYSTEM.VAL(PBYTE, 0164H);
TA0CCTL2*           = SYSTEM.VAL(PBYTE, 0166H);
TA0R*               = SYSTEM.VAL(PBYTE, 0170H);
TA0CCR0*            = SYSTEM.VAL(PBYTE, 0172H);
TA0CCR1*            = SYSTEM.VAL(PBYTE, 0174H);
TA0CCR2*            = SYSTEM.VAL(PBYTE, 0176H);
(************************************************************
* Timer1_A3
************************************************************)
TA1IV*              = SYSTEM.VAL(PBYTE, 011EH);
TA1CTL*             = SYSTEM.VAL(PBYTE, 0180H);
TA1CCTL0*           = SYSTEM.VAL(PBYTE, 0182H);
TA1CCTL1*           = SYSTEM.VAL(PBYTE, 0184H);
TA1CCTL2*           = SYSTEM.VAL(PBYTE, 0186H);
TA1R*               = SYSTEM.VAL(PBYTE, 0190H);
TA1CCR0*            = SYSTEM.VAL(PBYTE, 0192H);
TA1CCR1*            = SYSTEM.VAL(PBYTE, 0194H);
TA1CCR2*            = SYSTEM.VAL(PBYTE, 0196H);
(************************************************************
* USCI
************************************************************)
UCA0CTL0*           = SYSTEM.VAL(PBYTE, 0060H);
UCA0CTL1*           = SYSTEM.VAL(PBYTE, 0061H);
UCA0BR0*            = SYSTEM.VAL(PBYTE, 0062H);
UCA0BR1*            = SYSTEM.VAL(PBYTE, 0063H);
UCA0MCTL*           = SYSTEM.VAL(PBYTE, 0064H);
UCA0STAT*           = SYSTEM.VAL(PBYTE, 0065H);
UCA0RXBUF*          = SYSTEM.VAL(PBYTE, 0066H);
UCA0TXBUF*          = SYSTEM.VAL(PBYTE, 0067H);
UCA0ABCTL*          = SYSTEM.VAL(PBYTE, 005DH);
UCA0IRTCTL*         = SYSTEM.VAL(PBYTE, 005EH);
UCA0IRRCTL*         = SYSTEM.VAL(PBYTE, 005FH);
UCB0CTL0*           = SYSTEM.VAL(PBYTE, 0068H);
UCB0CTL1*           = SYSTEM.VAL(PBYTE, 0069H);
UCB0BR0*            = SYSTEM.VAL(PBYTE, 006AH);
UCB0BR1*            = SYSTEM.VAL(PBYTE, 006BH);
UCB0I2CIE*          = SYSTEM.VAL(PBYTE, 006CH);
UCB0STAT*           = SYSTEM.VAL(PBYTE, 006DH);
UCB0RXBUF*          = SYSTEM.VAL(PBYTE, 006EH);
UCB0TXBUF*          = SYSTEM.VAL(PBYTE, 006FH);
UCB0I2COA*          = SYSTEM.VAL(PINTEGER, 0118H);
UCB0I2CSA*          = SYSTEM.VAL(PINTEGER, 011AH);
(************************************************************
* WATCHDOG TIMER
************************************************************)
WDTCTL*             = SYSTEM.VAL(PINTEGER, 0120H);
(************************************************************
* Calibration Data in Info Mem
************************************************************)
CALDCO_16MHZ*       = SYSTEM.VAL(PINTEGER, 10F8H);
CALBC1_16MHZ*       = SYSTEM.VAL(PINTEGER, 10F9H);
CALDCO_12MHZ*       = SYSTEM.VAL(PINTEGER, 10FAH);
CALBC1_12MHZ*       = SYSTEM.VAL(PINTEGER, 10FBH);
CALDCO_8MHZ*        = SYSTEM.VAL(PINTEGER, 10FCH);
CALBC1_8MHZ*        = SYSTEM.VAL(PINTEGER, 10FDH);
CALDCO_1MHZ*        = SYSTEM.VAL(PINTEGER, 10FEH);
CALBC1_1MHZ*        = SYSTEM.VAL(PINTEGER, 10FFH);
(************************************************************
* Calibration Data in Info Mem
************************************************************)
TLV_CHECKSUM*       = SYSTEM.VAL(PINTEGER, 10C0H);
TLV_DCO_30_TAG*     = SYSTEM.VAL(PINTEGER, 10F6H);
TLV_DCO_30_LEN*     = SYSTEM.VAL(PINTEGER, 10F7H);
TLV_ADC10_1_TAG*    = SYSTEM.VAL(PINTEGER, 10DAH);
TLV_ADC10_1_LEN*    = SYSTEM.VAL(PINTEGER, 10DBH);
(************************************************************
* Interrupt Vectors (offset from 0xFFE0)
************************************************************)
(************************************************************
* End of Modules
************************************************************)

END msp430g2553.


OMSPTool.DecObj msp430g2553.mpc
decode msp430g2553.mpc
msp430g2553 60723399 Flash     2
imports:
type descriptors

data     0
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 0000
fixup procedures chains
fixup handlers chains
fixup data chains
fixup constants chains
fixup types chains
entry =  0000
code     2
 0000	     4130	RET
