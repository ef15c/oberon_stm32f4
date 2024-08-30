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
MOD0*               = {0};(* Modulation Bit 0 *)
MOD1*               = {1};(* Modulation Bit 1 *)
MOD2*               = {2};(* Modulation Bit 2 *)
MOD3*               = {3};(* Modulation Bit 3 *)
MOD4*               = {4};(* Modulation Bit 4 *)
DCO0*               = {5};(* DCO Select Bit 0 *)
DCO1*               = {6};(* DCO Select Bit 1 *)
DCO2*               = {7};(* DCO Select Bit 2 *)

BCSCTL1*            = SYSTEM.VAL(PBYTE, 0057H);
RSEL0*              = {0};(* Range Select Bit 0 *)
RSEL1*              = {1};(* Range Select Bit 1 *)
RSEL2*              = {2};(* Range Select Bit 2 *)
RSEL3*              = {3};(* Range Select Bit 3 *)
DIVA0*              = {4};(* ACLK Divider 0 *)
DIVA1*              = {5};(* ACLK Divider 1 *)
XTS*                = {6};(* LFXTCLK 0:Low Freq. / 1: High Freq. *)
XT2OFF*             = {7};(* Enable XT2CLK *)

DIVA_0*             = {};(* ACLK Divider 0: /1 *)
DIVA_1*             = DIVA0;(* ACLK Divider 1: /2 *)
DIVA_2*             = DIVA1;(* ACLK Divider 2: /4 *)
DIVA_3*             = DIVA0+DIVA1;(* ACLK Divider 3: /8 *)

BCSCTL2*            = SYSTEM.VAL(PBYTE, 0058H);
DIVS0*              = {1}(* SMCLK Divider 0 *)
DIVS1*              = {2}(* SMCLK Divider 1 *)
SELS*               = {3};(* SMCLK Source Select 0:DCOCLK / 1:XT2CLK/LFXTCLK *)
DIVM0*              = {4}(* MCLK Divider 0 *)
DIVM1*              = {5}(* MCLK Divider 1 *)
SELM0*              = {6}(* MCLK Source Select 0 *)
SELM1*              = {7}(* MCLK Source Select 1 *)

DIVS_0*             = {};(* SMCLK Divider 0: /1 *)
DIVS_1*             = DIVS0;(* SMCLK Divider 1: /2 *)
DIVS_2*             = DIVS1;(* SMCLK Divider 2: /4 *)
DIVS_3*             = DIVS0+DIVS1;(* SMCLK Divider 3: /8 *)

DIVM_0*             = {};(* MCLK Divider 0: /1 *)
DIVM_1*             = DIVM0;(* MCLK Divider 1: /2 *)
DIVM_2*             = DIVM1;(* MCLK Divider 2: /4 *)
DIVM_3*             = DIVM0+DIVM1;(* MCLK Divider 3: /8 *)

SELM_0*             = {};(* MCLK Source Select 0: DCOCLK *)
SELM_1*             = SELM0;(* MCLK Source Select 1: DCOCLK *)
SELM_2*             = SELM1;(* MCLK Source Select 2: XT2CLK/LFXTCLK *)
SELM_3*             = SELM0+SELM1;(* MCLK Source Select 3: LFXTCLK *)

BCSCTL3*            = SYSTEM.VAL(PBYTE, 0053H);

LFXT1OF*            = {0};(* Low/high Frequency Oscillator Fault Flag *)
XT2OF*              = {1};(* High frequency oscillator 2 fault flag *)
XCAP0*              = {2};(* XIN/XOUT Cap 0 *)
XCAP1*              = {3};(* XIN/XOUT Cap 1 *)
LFXT1S0*            = {4};(* Mode 0 for LFXT1 (XTS = 0) *)
LFXT1S1*            = {5};(* Mode 1 for LFXT1 (XTS = 0) *)
XT2S0*              = {6};(* Mode 0 for XT2 *)
XT2S1*              = {7};(* Mode 1 for XT2 *)

XCAP_0*             = {};(* XIN/XOUT Cap : 0 pF *)
XCAP_1*             = XCAP0;(* XIN/XOUT Cap : 6 pF *)
XCAP_2*             = XCAP1;(* XIN/XOUT Cap : 10 pF *)
XCAP_3*             = XCAP0+XCAP1;(* XIN/XOUT Cap : 12.5 pF *)

LFXT1S_0*           = {};    (* Mode 0 for LFXT1 : Normal operation *)
LFXT1S_1*           = LFXT1S0;    (* Mode 1 for LFXT1 : Reserved *)
LFXT1S_2*           = LFXT1S1;    (* Mode 2 for LFXT1 : VLO *)
LFXT1S_3*           = LFXT1S0+LFXT1S1;    (* Mode 3 for LFXT1 : Digital input signal *)

XT2S_0*             = {};(* Mode 0 for XT2 : 0.4 - 1 MHz *)
XT2S_1*             = XT2S0;(* Mode 1 for XT2 : 1 - 4 MHz *)
XT2S_2*             = XT2S1;(* Mode 2 for XT2 : 2 - 16 MHz *)
XT2S_3*             = XT2S0+XT2S1;(* Mode 3 for XT2 : Digital input signal *)

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
