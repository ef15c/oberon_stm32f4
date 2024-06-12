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
IE1*                = 0000H;
IFG1*               = 0002H;
IE2*                = 0001H;
IFG2*               = 0003H;
(************************************************************
* Basic Clock Module
************************************************************)
DCOCTL*             = 0056H;
BCSCTL1*            = 0057H;
BCSCTL2*            = 0058H;
BCSCTL3*            = 0053H;
(************************************************************
* Comparator A
************************************************************)
CACTL1*             = 0059H;
CACTL2*             = 005AH;
CAPD*               = 005BH;
(*************************************************************
* Flash Memory
*************************************************************)
FCTL1*              = 0128H;
FCTL2*              = 012AH;
FCTL3*              = 012CH;
(************************************************************
* DIGITAL I/O Port1/2 Pull up / Pull down Resistors
************************************************************)
P1IN*               = 0020H;
P1OUT*              = 0021H;
P1DIR*              = 0022H;
P1IFG*              = 0023H;
P1IES*              = 0024H;
P1IE*               = 0025H;
P1SEL*              = 0026H;
P1SEL2*             = 0041H;
P1REN*              = 0027H;
P2IN*               = 0028H;
P2OUT*              = 0029H;
P2DIR*              = 002AH;
P2IFG*              = 002BH;
P2IES*              = 002CH;
P2IE*               = 002DH;
P2SEL*              = 002EH;
P2SEL2*             = 0042H;
P2REN*              = 002FH;
(************************************************************
* DIGITAL I/O Port3 Pull up / Pull down Resistors
************************************************************)
P3IN*               = 0018H;
P3OUT*              = 0019H;
P3DIR*              = 001AH;
P3SEL*              = 001BH;
P3SEL2*             = 0043H;
P3REN*              = 0010H;
(************************************************************
* Timer0_A3
************************************************************)
TA0IV*              = 012EH;
TA0CTL*             = 0160H;
TA0CCTL0*           = 0162H;
TA0CCTL1*           = 0164H;
TA0CCTL2*           = 0166H;
TA0R*               = 0170H;
TA0CCR0*            = 0172H;
TA0CCR1*            = 0174H;
TA0CCR2*            = 0176H;
(************************************************************
* Timer1_A3
************************************************************)
TA1IV*              = 011EH;
TA1CTL*             = 0180H;
TA1CCTL0*           = 0182H;
TA1CCTL1*           = 0184H;
TA1CCTL2*           = 0186H;
TA1R*               = 0190H;
TA1CCR0*            = 0192H;
TA1CCR1*            = 0194H;
TA1CCR2*            = 0196H;
(************************************************************
* USCI
************************************************************)
UCA0CTL0*           = 0060H;
UCA0CTL1*           = 0061H;
UCA0BR0*            = 0062H;
UCA0BR1*            = 0063H;
UCA0MCTL*           = 0064H;
UCA0STAT*           = 0065H;
UCA0RXBUF*          = 0066H;
UCA0TXBUF*          = 0067H;
UCA0ABCTL*          = 005DH;
UCA0IRTCTL*         = 005EH;
UCA0IRRCTL*         = 005FH;
UCB0CTL0*           = 0068H;
UCB0CTL1*           = 0069H;
UCB0BR0*            = 006AH;
UCB0BR1*            = 006BH;
UCB0I2CIE*          = 006CH;
UCB0STAT*           = 006DH;
UCB0RXBUF*          = 006EH;
UCB0TXBUF*          = 006FH;
UCB0I2COA*          = 0118H;
UCB0I2CSA*          = 011AH;
(************************************************************
* WATCHDOG TIMER
************************************************************)
WDTCTL*             = 0120H;
(************************************************************
* Calibration Data in Info Mem
************************************************************)
CALDCO_16MHZ*       = 10F8H;
CALBC1_16MHZ*       = 10F9H;
CALDCO_12MHZ*       = 10FAH;
CALBC1_12MHZ*       = 10FBH;
CALDCO_8MHZ*        = 10FCH;
CALBC1_8MHZ*        = 10FDH;
CALDCO_1MHZ*        = 10FEH;
CALBC1_1MHZ*        = 10FFH;
(************************************************************
* Calibration Data in Info Mem
************************************************************)
TLV_CHECKSUM*       = 10C0H;
TLV_DCO_30_TAG*     = 10F6H;
TLV_DCO_30_LEN*     = 10F7H;
TLV_ADC10_1_TAG*    = 10DAH;
TLV_ADC10_1_LEN*    = 10DBH;
(************************************************************
* Interrupt Vectors (offset from 0xFFE0)
************************************************************)
(************************************************************
* End of Modules
************************************************************)

END msp430g2553.
