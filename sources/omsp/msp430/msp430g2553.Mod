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
C*                  = {0};
Z*                  = {1};
N*                  = {2};
V*                  = {8};
GIE*                = {3};
CPUOFF*             = {4};
OSCOFF*             = {5};
SCG0*               = {6};
SCG1*               = {7};

(* Low Power Modes coded with Bits 4-7 in SR*)
LPM0_bits*          = CPUOFF;
LPM1_bits*          = SCG0+CPUOFF;
LPM2_bits*          = SCG1+CPUOFF;
LPM3_bits*          = SCG1+SCG0+CPUOFF;
LPM4_bits*          = SCG1+SCG0+OSCOFF+CPUOFF;

(************************************************************
* PERIPHERAL FILE MAP
************************************************************)
(************************************************************
* SPECIAL FUNCTION REGISTER ADDRESSES + CONTROL BITS
************************************************************)
IE1*                = SYSTEM.VAL(PBYTE, 0000H);
WDTIE*              = {0}; (* Watchdog Interrupt Enable *)
OFIE*               = {1}; (* Osc. Fault  Interrupt Enable *)
NMIIE*              = {4}; (* NMI Interrupt Enable *)
ACCVIE*             = {5}; (* Flash Access Violation Interrupt Enable *)

IFG1*               = SYSTEM.VAL(PBYTE, 0002H);
WDTIFG*             = {0}; (* Watchdog Interrupt Flag *)
OFIFG*              = {1}; (* Osc. Fault Interrupt Flag *)
PORIFG*             = {2}; (* Power On Interrupt Flag *)
RSTIFG*             = {3}; (* Reset Interrupt Flag *)
NMIIFG*             = {4}; (* NMI Interrupt Flag *)

IE2*                = SYSTEM.VAL(PBYTE, 0001H);
UC0IE*              = IE2;
UCA0RXIE*           = {0};
UCA0TXIE*           = {1};
UCB0RXIE*           = {2};
UCB0TXIE*           = {3};

IFG2*               = SYSTEM.VAL(PBYTE, 0003H);
UC0IFG*             = IFG2;
UCA0RXIFG*          = {0};
UCA0TXIFG*          = {1};
UCB0RXIFG*          = {2};
UCB0TXIFG*          = {3};

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
FCTL1*              = SYSTEM.VAL(PINTEGER, 0128H);
FCTL2*              = SYSTEM.VAL(PINTEGER, 012AH);
FCTL3*              = SYSTEM.VAL(PINTEGER, 012CH);
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
TA0IV*              = SYSTEM.VAL(PINTEGER, 012EH);
TA0IV_NONE*         = 00H; (* No Interrupt pending *)
TA0IV_TACCR1*       = 02H; (* TA0CCR1_CCIFG *)
TA0IV_TACCR2*       = 04H; (* TA0CCR2_CCIFG *)
TA0IV_6*            = 06H; (* Reserved *)
TA0IV_8*            = 08H; (* Reserved *)
TA0IV_TAIFG*        = 0AH; (* TA0IFG *)

TA0CTL*             = SYSTEM.VAL(PINTEGER, 0160H);
TASSEL1*            = {9}; (* Timer A clock source select 1 *)
TASSEL0*            = {8}; (* Timer A clock source select 0 *)
ID1*                = {7}; (* Timer A clock input divider 1 *)
ID0*                = {6}; (* Timer A clock input divider 0 *)
MC1*                = {5}; (* Timer A mode control 1 *)
MC0*                = {4}; (* Timer A mode control 0 *)
TACLR*              = {2}; (* Timer A counter clear *)
TAIE*               = {1}; (* Timer A counter interrupt enable *)
TAIFG*              = {0}; (* Timer A counter interrupt flag *)

MC_0*               = {}; (* Timer A mode control: 0 - Stop *)
MC_1*               = MC0; (* Timer A mode control: 1 - Up to CCR0 *)
MC_2*               = MC1; (* Timer A mode control: 2 - Continous up *)
MC_3*               = MC0+MC1; (* Timer A mode control: 3 - Up/Down *)

ID_0*               = {}; (* Timer A input divider: 0 - /1 *)
ID_1*               = ID0; (* Timer A input divider: 1 - /2 *)
ID_2*               = ID1; (* Timer A input divider: 2 - /4 *)
ID_3*               = ID0+ID1; (* Timer A input divider: 3 - /8 *)

TASSEL_0*           = {}; (* Timer A clock source select: 0 - TACLK *)
TASSEL_1*           = TASSEL0; (* Timer A clock source select: 1 - ACLK *)
TASSEL_2*           = TASSEL1; (* Timer A clock source select: 2 - SMCLK *)
TASSEL_3*           = TASSEL0+TASSEL1; (* Timer A clock source select: 3 - INCLK *)

TA0CCTL0*           = SYSTEM.VAL(PINTEGER, 0162H);
TA0CCTL1*           = SYSTEM.VAL(PINTEGER, 0164H);
TA0CCTL2*           = SYSTEM.VAL(PINTEGER, 0166H);
CM1*                = {15}; (* Capture mode 1 *)
CM0*                = {14}; (* Capture mode 0 *)
CCIS1*              = {13}; (* Capture input select 1 *)
CCIS0*              = {12}; (* Capture input select 0 *)
SCS*                = {11}; (* Capture sychronize *)
SCCI*               = {10}; (* Latched capture signal (read) *)
CAP*                = {9}; (* Capture mode: 1 /Compare mode : 0 *)
OUTMOD2*            = {7}; (* Output mode 2 *)
OUTMOD1*            = {6}; (* Output mode 1 *)
OUTMOD0*            = {5}; (* Output mode 0 *)
CCIE*               = {4}; (* Capture/compare interrupt enable *)
CCI*                = {3}; (* Capture input signal (read) *)
OUT*                = {2}; (* PWM Output signal if output mode 0 *)
COV*                = {1}; (* Capture/compare overflow flag *)
CCIFG*              = {0}; (* Capture/compare interrupt flag *)

OUTMOD_0*           = {}; (* PWM output mode: 0 - output only *)
OUTMOD_1*           = OUTMOD0; (* PWM output mode: 1 - set *)
OUTMOD_2*           = OUTMOD1; (* PWM output mode: 2 - PWM toggle/reset *)
OUTMOD_3*           = OUTMOD0+OUTMOD1; (* PWM output mode: 3 - PWM set/reset *)
OUTMOD_4*           = OUTMOD2; (* PWM output mode: 4 - toggle *)
OUTMOD_5*           = OUTMOD2+OUTMOD0; (* PWM output mode: 5 - Reset *)
OUTMOD_6*           = OUTMOD2+OUTMOD1; (* PWM output mode: 6 - PWM toggle/set *)
OUTMOD_7*           = OUTMOD2+OUTMOD0+OUTMOD1; (* PWM output mode: 7 - PWM reset/set *)
CCIS_0*             = {}; (* Capture input select: 0 - CCIxA *)
CCIS_1*             = CCIS0; (* Capture input select: 1 - CCIxB *)
CCIS_2*             = CCIS1; (* Capture input select: 2 - GND *)
CCIS_3*             = CCIS0+CCIS1; (* Capture input select: 3 - Vcc *)
CM_0*               = {}; (* Capture mode: 0 - disabled *)
CM_1*               = CM0; (* Capture mode: 1 - pos. edge *)
CM_2*               = CM1; (* Capture mode: 1 - neg. edge *)
CM_3*               = CM0+CM1; (* Capture mode: 1 - both edges *)

TA0R*               = SYSTEM.VAL(PINTEGER, 0170H);
TA0CCR0*            = SYSTEM.VAL(PINTEGER, 0172H);
TA0CCR1*            = SYSTEM.VAL(PINTEGER, 0174H);
TA0CCR2*            = SYSTEM.VAL(PINTEGER, 0176H);

(************************************************************
* Timer1_A3
************************************************************)
TA1IV*              = SYSTEM.VAL(PINTEGER, 011EH);
TA1CTL*             = SYSTEM.VAL(PINTEGER, 0180H);
TA1CCTL0*           = SYSTEM.VAL(PINTEGER, 0182H);
TA1CCTL1*           = SYSTEM.VAL(PINTEGER, 0184H);
TA1CCTL2*           = SYSTEM.VAL(PINTEGER, 0186H);
TA1R*               = SYSTEM.VAL(PINTEGER, 0190H);
TA1CCR0*            = SYSTEM.VAL(PINTEGER, 0192H);
TA1CCR1*            = SYSTEM.VAL(PINTEGER, 0194H);
TA1CCR2*            = SYSTEM.VAL(PINTEGER, 0196H);
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

(* The bit names have been prefixed with "WDT" *)
WDTIS0*             = {0};
WDTIS1*             = {1};
WDTSSEL*            = {2};
WDTCNTCL*           = {3};
WDTTMSEL*           = {4};
WDTNMI*             = {5};
WDTNMIES*           = {6};
WDTHOLD*            = {7};

WDTPW*              = SYSTEM.VAL(SET, 5A00H);

(* WDT-interval times [1ms] coded with Bits 0-2 *
 * WDT is clocked by fSMCLK (assumed 1MHz) *)
WDT_MDLY_32*        = (WDTPW+WDTTMSEL+WDTCNTCL); (* 32ms interval (default) *)
WDT_MDLY_8*         = (WDTPW+WDTTMSEL+WDTCNTCL+WDTIS0); (* 8ms     " *)
WDT_MDLY_0_5*       = (WDTPW+WDTTMSEL+WDTCNTCL+WDTIS1); (* 0.5ms   " *)
WDT_MDLY_0_064*     = (WDTPW+WDTTMSEL+WDTCNTCL+WDTIS1+WDTIS0); (* 0.064ms " *)
(* WDT is clocked by fACLK (assumed 32KHz) *)
WDT_ADLY_1000*      = (WDTPW+WDTTMSEL+WDTCNTCL+WDTSSEL); (* 1000ms  " *)
WDT_ADLY_250*       = (WDTPW+WDTTMSEL+WDTCNTCL+WDTSSEL+WDTIS0); (* 250ms   " *)
WDT_ADLY_16*        = (WDTPW+WDTTMSEL+WDTCNTCL+WDTSSEL+WDTIS1); (* 16ms    " *)
WDT_ADLY_1_9*       = (WDTPW+WDTTMSEL+WDTCNTCL+WDTSSEL+WDTIS1+WDTIS0); (* 1.9ms   " *)
(* Watchdog mode -> reset after expired time *)
(* WDT is clocked by fSMCLK (assumed 1MHz) *)
WDT_MRST_32*        = (WDTPW+WDTCNTCL); (* 32ms interval (default) *)
WDT_MRST_8*         = (WDTPW+WDTCNTCL+WDTIS0); (* 8ms     " *)
WDT_MRST_0_5*       = (WDTPW+WDTCNTCL+WDTIS1); (* 0.5ms   " *)
WDT_MRST_0_064*     = (WDTPW+WDTCNTCL+WDTIS1+WDTIS0); (* 0.064ms " *)
(* WDT is clocked by fACLK (assumed 32KHz) *)
WDT_ARST_1000*      = (WDTPW+WDTCNTCL+WDTSSEL); (* 1000ms  " *)
WDT_ARST_250*       = (WDTPW+WDTCNTCL+WDTSSEL+WDTIS0); (* 250ms   " *)
WDT_ARST_16*        = (WDTPW+WDTCNTCL+WDTSSEL+WDTIS1); (* 16ms    " *)
WDT_ARST_1_9*       = (WDTPW+WDTCNTCL+WDTSSEL+WDTIS1+WDTIS0); (* 1.9ms   " *)

(* INTERRUPT CONTROL *)
(* These two bits are defined in the Special Function Registers *)
(* WDTIE               0x01 *)
(* WDTIFG              0x01 *)

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
TRAPINT_VECTOR*     = 16+0;                 (* 0xFFE0 TRAPINT *)
PORT1_VECTOR*       = 16+2;                 (* 0xFFE4 Port 1 *)
PORT2_VECTOR*       = 16+3;                 (* 0xFFE6 Port 2 *)
ADC10_VECTOR*       = 16+5;                 (* 0xFFEA ADC10 *)
USCIAB0TX_VECTOR*   = 16+6;                 (* 0xFFEC USCI A0/B0 Transmit *)
USCIAB0RX_VECTOR*   = 16+7;                 (* 0xFFEE USCI A0/B0 Receive *)
TIMER0_A1_VECTOR*   = 16+8;                 (* 0xFFF0 Timer0_A CC1, TA0 *)
TIMER0_A0_VECTOR*   = 16+9;                 (* 0xFFF2 Timer0_A CC0 *)
WDT_VECTOR*         = 16+10;                (* 0xFFF4 Watchdog Timer *)
COMPARATORA_VECTOR* = 16+11;                (* 0xFFF6 Comparator A *)
TIMER1_A1_VECTOR*   = 16+12;                (* 0xFFF8 Timer1_A CC1-4, TA1 *)
TIMER1_A0_VECTOR*   = 16+13;                (* 0xFFFA Timer1_A CC0 *)
NMI_VECTOR*         = 16+14;                (* 0xFFFC Non-maskable *)
RESET_VECTOR*       = 16+15;                (* 0xFFFE Reset [Highest Priority] *)
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

OMSPTool.DecSym msp430g2553.sms
decode msp430g2553.sms
msp430g2553 B7A7F8F7  1
   1 C [^6]       1
   1 Z [^6]       2
   1 N [^6]       4
   1 V [^6]     256
   1 GIE [^6]       8
   1 CPUOFF [^6]      16
   1 OSCOFF [^6]      32
   1 SCG0 [^6]      64
   1 SCG1 [^6]     128
   1 LPM0_bits [^6]      16
   1 LPM1_bits [^6]      80
   1 LPM2_bits [^6]     144
   1 LPM3_bits [^6]     208
   1 LPM4_bits [^6]     240
   1 IE1 [^14]       0
   1 WDTIE [^6]       1
   1 OFIE [^6]       2
   1 NMIIE [^6]      16
   1 ACCVIE [^6]      32
   1 IFG1 [^14]       2
   1 WDTIFG [^6]       1
   1 OFIFG [^6]       2
   1 PORIFG [^6]       4
   1 RSTIFG [^6]       8
   1 NMIIFG [^6]      16
   1 IE2 [^14]       1
   1 UC0IE [^14]       1
   1 UCA0RXIE [^6]       1
   1 UCA0TXIE [^6]       2
   1 UCB0RXIE [^6]       4
   1 UCB0TXIE [^6]       8
   1 IFG2 [^14]       3
   1 UC0IFG [^14]       3
   1 UCA0RXIFG [^6]       1
   1 UCA0TXIFG [^6]       2
   1 UCB0RXIFG [^6]       4
   1 UCB0TXIFG [^6]       8
   1 DCOCTL [^14]      86
   1 BCSCTL1 [^14]      87
   1 BCSCTL2 [^14]      88
   1 BCSCTL3 [^14]      83
   1 CACTL1 [^14]      89
   1 CACTL2 [^14]      90
   1 CAPD [^14]      91
   1 FCTL1 [^7]     296
   1 FCTL2 [^7]     298
   1 FCTL3 [^7]     300
   1 P1IN [^14]      32
   1 P1OUT [^14]      33
   1 P1DIR [^14]      34
   1 P1IFG [^14]      35
   1 P1IES [^14]      36
   1 P1IE [^14]      37
   1 P1SEL [^14]      38
   1 P1SEL2 [^14]      65
   1 P1REN [^14]      39
   1 P2IN [^14]      40
   1 P2OUT [^14]      41
   1 P2DIR [^14]      42
   1 P2IFG [^14]      43
   1 P2IES [^14]      44
   1 P2IE [^14]      45
   1 P2SEL [^14]      46
   1 P2SEL2 [^14]      66
   1 P2REN [^14]      47
   1 P3IN [^14]      24
   1 P3OUT [^14]      25
   1 P3DIR [^14]      26
   1 P3SEL [^14]      27
   1 P3SEL2 [^14]      67
   1 P3REN [^14]      16
   1 TA0IV [^7]     302
   1 TA0IV_NONE [^4]       0
   1 TA0IV_TACCR1 [^4]       2
   1 TA0IV_TACCR2 [^4]       4
   1 TA0IV_6 [^4]       6
   1 TA0IV_8 [^4]       8
   1 TA0IV_TAIFG [^4]      10
   1 TA0CTL [^7]     352
   1 TASSEL1 [^6]     512
   1 TASSEL0 [^6]     256
   1 ID1 [^6]     128
   1 ID0 [^6]      64
   1 MC1 [^6]      32
   1 MC0 [^6]      16
   1 TACLR [^6]       4
   1 TAIE [^6]       2
   1 TAIFG [^6]       1
   1 MC_0 [^6]       0
   1 MC_1 [^6]      16
   1 MC_2 [^6]      32
   1 MC_3 [^6]      48
   1 ID_0 [^6]       0
   1 ID_1 [^6]      64
   1 ID_2 [^6]     128
   1 ID_3 [^6]     192
   1 TASSEL_0 [^6]       0
   1 TASSEL_1 [^6]     256
   1 TASSEL_2 [^6]     512
   1 TASSEL_3 [^6]     768
   1 TA0CCTL0 [^7]     354
   1 TA0CCTL1 [^7]     356
   1 TA0CCTL2 [^7]     358
   1 CM1 [^6]   32768
   1 CM0 [^6]   16384
   1 CCIS1 [^6]    8192
   1 CCIS0 [^6]    4096
   1 SCS [^6]    2048
   1 SCCI [^6]    1024
   1 CAP [^6]     512
   1 OUTMOD2 [^6]     128
   1 OUTMOD1 [^6]      64
   1 OUTMOD0 [^6]      32
   1 CCIE [^6]      16
   1 CCI [^6]       8
   1 OUT [^6]       4
   1 COV [^6]       2
   1 CCIFG [^6]       1
   1 OUTMOD_0 [^6]       0
   1 OUTMOD_1 [^6]      32
   1 OUTMOD_2 [^6]      64
   1 OUTMOD_3 [^6]      96
   1 OUTMOD_4 [^6]     128
   1 OUTMOD_5 [^6]     160
   1 OUTMOD_6 [^6]     192
   1 OUTMOD_7 [^6]     224
   1 CCIS_0 [^6]       0
   1 CCIS_1 [^6]    4096
   1 CCIS_2 [^6]    8192
   1 CCIS_3 [^6]   12288
   1 CM_0 [^6]       0
   1 CM_1 [^6]   16384
   1 CM_2 [^6]   32768
   1 CM_3 [^6]   49152
   1 TA0R [^7]     368
   1 TA0CCR0 [^7]     370
   1 TA0CCR1 [^7]     372
   1 TA0CCR2 [^7]     374
   1 TA1IV [^7]     286
   1 TA1CTL [^7]     384
   1 TA1CCTL0 [^7]     386
   1 TA1CCTL1 [^7]     388
   1 TA1CCTL2 [^7]     390
   1 TA1R [^7]     400
   1 TA1CCR0 [^7]     402
   1 TA1CCR1 [^7]     404
   1 TA1CCR2 [^7]     406
   1 UCA0CTL0 [^14]      96
   1 UCA0CTL1 [^14]      97
   1 UCA0BR0 [^14]      98
   1 UCA0BR1 [^14]      99
   1 UCA0MCTL [^14]     100
   1 UCA0STAT [^14]     101
   1 UCA0RXBUF [^14]     102
   1 UCA0TXBUF [^14]     103
   1 UCA0ABCTL [^14]      93
   1 UCA0IRTCTL [^14]      94
   1 UCA0IRRCTL [^14]      95
   1 UCB0CTL0 [^14]     104
   1 UCB0CTL1 [^14]     105
   1 UCB0BR0 [^14]     106
   1 UCB0BR1 [^14]     107
   1 UCB0I2CIE [^14]     108
   1 UCB0STAT [^14]     109
   1 UCB0RXBUF [^14]     110
   1 UCB0TXBUF [^14]     111
   1 UCB0I2COA [^7]     280
   1 UCB0I2CSA [^7]     282
   1 WDTCTL [^7]     288
   1 WDTIS0 [^6]       1
   1 WDTIS1 [^6]       2
   1 WDTSSEL [^6]       4
   1 WDTCNTCL [^6]       8
   1 WDTTMSEL [^6]      16
   1 WDTNMI [^6]      32
   1 WDTNMIES [^6]      64
   1 WDTHOLD [^6]     128
   1 WDTPW [^6]   23040
   1 WDT_MDLY_32 [^6]   23064
   1 WDT_MDLY_8 [^6]   23065
   1 WDT_MDLY_0_5 [^6]   23066
   1 WDT_MDLY_0_064 [^6]   23067
   1 WDT_ADLY_1000 [^6]   23068
   1 WDT_ADLY_250 [^6]   23069
   1 WDT_ADLY_16 [^6]   23070
   1 WDT_ADLY_1_9 [^6]   23071
   1 WDT_MRST_32 [^6]   23048
   1 WDT_MRST_8 [^6]   23049
   1 WDT_MRST_0_5 [^6]   23050
   1 WDT_MRST_0_064 [^6]   23051
   1 WDT_ARST_1000 [^6]   23052
   1 WDT_ARST_250 [^6]   23053
   1 WDT_ARST_16 [^6]   23054
   1 WDT_ARST_1_9 [^6]   23055
   1 CALDCO_16MHZ [^7]    4344
   1 CALBC1_16MHZ [^7]    4345
   1 CALDCO_12MHZ [^7]    4346
   1 CALBC1_12MHZ [^7]    4347
   1 CALDCO_8MHZ [^7]    4348
   1 CALBC1_8MHZ [^7]    4349
   1 CALDCO_1MHZ [^7]    4350
   1 CALBC1_1MHZ [^7]    4351
   1 TLV_CHECKSUM [^7]    4288
   1 TLV_DCO_30_TAG [^7]    4342
   1 TLV_DCO_30_LEN [^7]    4343
   1 TLV_ADC10_1_TAG [^7]    4314
   1 TLV_ADC10_1_LEN [^7]    4315
   1 TRAPINT_VECTOR [^4]      16
   1 PORT1_VECTOR [^4]      18
   1 PORT2_VECTOR [^4]      19
   1 ADC10_VECTOR [^4]      21
   1 USCIAB0TX_VECTOR [^4]      22
   1 USCIAB0RX_VECTOR [^4]      23
   1 TIMER0_A1_VECTOR [^4]      24
   1 TIMER0_A0_VECTOR [^4]      25
   1 WDT_VECTOR [^4]      26
   1 COMPARATORA_VECTOR [^4]      27
   1 TIMER1_A1_VECTOR [^4]      28
   1 TIMER1_A0_VECTOR [^4]      29
   1 NMI_VECTOR [^4]      30
   1 RESET_VECTOR [^4]      31
