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
(* msp430g2231.Mod                                                            *)
(*    - Module for definition of peripheral memory map                        *)
(*    Please do not change !                                                  *)
(*                                                                            *)
(******************************************************************************)
(* Version: 1.213                                                             *)
(******************************************************************************)

MODULE msp430g2231;
  IMPORT SYSTEM;
  CONST
  
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

(* Low Power Modes coded with Bits 4-7 in SR *)
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
IE1*                = SYSTEM.VAL(PBYTESET, 0000H); (* Interrupt Enable 1 *)
WDTIE*              = {0}; (* Watchdog Interrupt Enable *)
OFIE*               = {1}; (* Osc. Fault  Interrupt Enable *)
NMIIE*              = {4}; (* NMI Interrupt Enable *)
ACCVIE*             = {5}; (* Flash Access Violation Interrupt Enable *)

IFG1*               = SYSTEM.VAL(PBYTESET, 0002H); (* Interrupt Flag 1 *)
WDTIFG*             = {0}; (* Watchdog Interrupt Flag *)
OFIFG*              = {1}; (* Osc. Fault Interrupt Flag *)
PORIFG*             = {2}; (* Power On Interrupt Flag *)
RSTIFG*             = {3}; (* Reset Interrupt Flag *)
NMIIFG*             = {4}; (* NMI Interrupt Flag *)

(************************************************************
* ADC10
************************************************************)
ADC10DTC0*          = SYSTEM.VAL(PBYTESET, 0048H); (* ADC10 Data Transfer Control 0 *)
ADC10FETCH*         = {0}; (* This bit should normally be reset *)
ADC10B1*            = {1}; (* ADC10 block one *)
ADC10CT*            = {2}; (* ADC10 continuous transfer *)
ADC10TB*            = {3}; (* ADC10 two-block mode *)

ADC10DTC1*          = SYSTEM.VAL(PBYTE, 0049H); (* ADC10 Data Transfer Control 1 *)
ADC10DISABLE*       = 0;

ADC10AE0*           = SYSTEM.VAL(PBYTESET, 004AH); (* ADC10 Analog Enable 0 *)

ADC10CTL0*          = SYSTEM.VAL(PSET, 01B0H); (* ADC10 Control 0 *)
ADC10SC*            = {0};  (* ADC10 Start Conversion *)
ENC*                = {1};  (* ADC10 Enable Conversion *)
ADC10IFG*           = {2};  (* ADC10 Interrupt Flag *)
ADC10IE*            = {3};  (* ADC10 Interrupt Enable *)
ADC10ON*            = {4};  (* ADC10 On/Enable *)
REFON*              = {5};  (* ADC10 Reference on *)
REF2_5V*            = {6};  (* ADC10 Ref 0:1.5V / 1:2.5V *)
MSC*                = {7};  (* ADC10 Multiple SampleConversion *)
REFBURST*           = {8};  (* ADC10 Reference Burst Mode *)
REFOUT*             = {9};  (* ADC10 Enable output of Ref. *)
ADC10SR*            = {10}; (* ADC10 Sampling Rate 0:200ksps / 1:50ksps *)
ADC10SHT0*          = {11}; (* ADC10 Sample Hold Select Bit: 0 *)
ADC10SHT1*          = {12}; (* ADC10 Sample Hold Select Bit: 1 *)
SREF0*              = {13}; (* ADC10 Reference Select Bit: 0 *)
SREF1*              = {14}; (* ADC10 Reference Select Bit: 1 *)
SREF2*              = {15}; (* ADC10 Reference Select Bit: 2 *)

ADC10SHT_0*         = {};                  (* 4 x ADC10CLKs *)
ADC10SHT_1*         = ADC10SHT0;           (* 8 x ADC10CLKs *)
ADC10SHT_2*         = ADC10SHT1;           (* 16 x ADC10CLKs *)
ADC10SHT_3*         = ADC10SHT0+ADC10SHT1; (* 64 x ADC10CLKs *)

SREF_0*             = {};                (* VR+ = AVCC and VR- = AVSS *)
SREF_1*             = SREF0;             (* VR+ = VREF+ and VR- = AVSS *)
SREF_2*             = SREF1;             (* VR+ = VEREF+ and VR- = AVSS *)
SREF_3*             = SREF0+SREF1;       (* VR+ = VEREF+ and VR- = AVSS *)
SREF_4*             = SREF2;             (* VR+ = AVCC and VR- = VREF-/VEREF- *)
SREF_5*             = SREF0+SREF2;       (* VR+ = VREF+ and VR- = VREF-/VEREF- *)
SREF_6*             = SREF1+SREF2;       (* VR+ = VEREF+ and VR- = VREF-/VEREF- *)
SREF_7*             = SREF0+SREF1+SREF2; (* VR+ = VEREF+ and VR- = VREF-/VEREF- *)

ADC10CTL1*          = SYSTEM.VAL(PSET, 01B2H); (* ADC10 Control 1 *)
ADC10BUSY*          = {0};  (* ADC10 BUSY *)
CONSEQ0*            = {1};  (* ADC10 Conversion Sequence Select 0 *)
CONSEQ1*            = {2};  (* ADC10 Conversion Sequence Select 1 *)
ADC10SSEL0*         = {3};  (* ADC10 Clock Source Select Bit: 0 *)
ADC10SSEL1*         = {4};  (* ADC10 Clock Source Select Bit: 1 *)
ADC10DIV0*          = {5};  (* ADC10 Clock Divider Select Bit: 0 *)
ADC10DIV1*          = {6};  (* ADC10 Clock Divider Select Bit: 1 *)
ADC10DIV2*          = {7};  (* ADC10 Clock Divider Select Bit: 2 *)
ISSH*               = {8};  (* ADC10 Invert Sample Hold Signal *)
ADC10DF*            = {9};  (* ADC10 Data Format 0:binary 1:2's complement *)
SHS0*               = {10}; (* ADC10 Sample/Hold Source Bit: 0 *)
SHS1*               = {11}; (* ADC10 Sample/Hold Source Bit: 1 *)
INCH0*              = {12}; (* ADC10 Input Channel Select Bit: 0 *)
INCH1*              = {13}; (* ADC10 Input Channel Select Bit: 1 *)
INCH2*              = {14}; (* ADC10 Input Channel Select Bit: 2 *)
INCH3*              = {15}; (* ADC10 Input Channel Select Bit: 3 *)

CONSEQ_0*           = {};              (* Single channel single conversion *)
CONSEQ_1*           = CONSEQ0;         (* Sequence of channels *)
CONSEQ_2*           = CONSEQ1;         (* Repeat single channel *)
CONSEQ_3*           = CONSEQ0+CONSEQ1; (* Repeat sequence of channels *)

ADC10SSEL_0*        = {};                    (* ADC10OSC *)
ADC10SSEL_1*        = ADC10SSEL0;            (* ACLK *)
ADC10SSEL_2*        = ADC10SSEL1;            (* MCLK *)
ADC10SSEL_3*        = ADC10SSEL0+ADC10SSEL1; (* SMCLK *)

ADC10DIV_0*         = {};                            (* ADC10 Clock Divider Select 0 *)
ADC10DIV_1*         = ADC10DIV0;                     (* ADC10 Clock Divider Select 1 *)
ADC10DIV_2*         = ADC10DIV1;                     (* ADC10 Clock Divider Select 2 *)
ADC10DIV_3*         = ADC10DIV0+ADC10DIV1;           (* ADC10 Clock Divider Select 3 *)
ADC10DIV_4*         = ADC10DIV2;                     (* ADC10 Clock Divider Select 4 *)
ADC10DIV_5*         = ADC10DIV0+ADC10DIV2;           (* ADC10 Clock Divider Select 5 *)
ADC10DIV_6*         = ADC10DIV1+ADC10DIV2;           (* ADC10 Clock Divider Select 6 *)
ADC10DIV_7*         = ADC10DIV0+ADC10DIV1+ADC10DIV2; (* ADC10 Clock Divider Select 7 *)

SHS_0*              = {};        (* ADC10SC *)
SHS_1*              = SHS0;      (* TA3 OUT1 *)
SHS_2*              = SHS1;      (* TA3 OUT0 *)
SHS_3*              = SHS0+SHS1; (* TA3 OUT2 *)

INCH_0*             = {};                      (* Selects Channel 0 *)
INCH_1*             = INCH0;                   (* Selects Channel 1 *)
INCH_2*             = INCH1;                   (* Selects Channel 2 *)
INCH_3*             = INCH0+INCH1;             (* Selects Channel 3 *)
INCH_4*             = INCH2;                   (* Selects Channel 4 *)
INCH_5*             = INCH0+INCH2;             (* Selects Channel 5 *)
INCH_6*             = INCH1+INCH2;             (* Selects Channel 6 *)
INCH_7*             = INCH0+INCH1+INCH2;       (* Selects Channel 7 *)
INCH_8*             = INCH3;                   (* Selects Channel 8 *)
INCH_9*             = INCH0+INCH3;             (* Selects Channel 9 *)
INCH_10*            = INCH1+INCH3;                   (* Selects Channel 10 *)
INCH_11*            = INCH0+INCH1+INCH3;       (* Selects Channel 11 *)
INCH_12*            = INCH2+INCH3;             (* Selects Channel 12 *)
INCH_13*            = INCH0+INCH2+INCH3;       (* Selects Channel 13 *)
INCH_14*            = INCH1+INCH2+INCH3;       (* Selects Channel 14 *)
INCH_15*            = INCH0+INCH1+INCH2+INCH3; (* Selects Channel 15 *)

ADC10MEM*              = SYSTEM.VAL(PINTEGER, 01B4H); (* ADC10 Memory *)
ADC10SA*               = SYSTEM.VAL(PINTEGER, 01BCH); (* ADC10 Data Transfer Start Address *)

(************************************************************
* Basic Clock Module
************************************************************)
DCOCTL*             = SYSTEM.VAL(PBYTESET, 0056H); (* DCO Clock Frequency Control *)
MOD0*               = {0}; (* Modulation Bit 0 *)
MOD1*               = {1}; (* Modulation Bit 1 *)
MOD2*               = {2}; (* Modulation Bit 2 *)
MOD3*               = {3}; (* Modulation Bit 3 *)
MOD4*               = {4}; (* Modulation Bit 4 *)
DCO0*               = {5}; (* DCO Select Bit 0 *)
DCO1*               = {6}; (* DCO Select Bit 1 *)
DCO2*               = {7}; (* DCO Select Bit 2 *)

BCSCTL1*            = SYSTEM.VAL(PBYTESET, 0057H); (* Basic Clock System Control 1 *)
RSEL0*              = {0}; (* Range Select Bit 0 *)
RSEL1*              = {1}; (* Range Select Bit 1 *)
RSEL2*              = {2}; (* Range Select Bit 2 *)
RSEL3*              = {3}; (* Range Select Bit 3 *)
DIVA0*              = {4}; (* ACLK Divider 0 *)
DIVA1*              = {5}; (* ACLK Divider 1 *)
XTS*                = {6}; (* LFXTCLK 0:Low Freq. / 1: High Freq. *)
XT2OFF*             = {7}; (* Enable XT2CLK *)

DIVA_0*             = {};          (* ACLK Divider 0: /1 *)
DIVA_1*             = DIVA0;       (* ACLK Divider 1: /2 *)
DIVA_2*             = DIVA1;       (* ACLK Divider 2: /4 *)
DIVA_3*             = DIVA0+DIVA1; (* ACLK Divider 3: /8 *)

BCSCTL2*            = SYSTEM.VAL(PBYTESET, 0058H); (* Basic Clock System Control 2 *)
DIVS0*              = {1}; (* SMCLK Divider 0 *)
DIVS1*              = {2}; (* SMCLK Divider 1 *)
SELS*               = {3}; (* SMCLK Source Select 0:DCOCLK / 1:XT2CLK/LFXTCLK *)
DIVM0*              = {4}; (* MCLK Divider 0 *)
DIVM1*              = {5}; (* MCLK Divider 1 *)
SELM0*              = {6}; (* MCLK Source Select 0 *)
SELM1*              = {7}; (* MCLK Source Select 1 *)

DIVS_0*             = {};          (* SMCLK Divider 0: /1 *)
DIVS_1*             = DIVS0;       (* SMCLK Divider 1: /2 *)
DIVS_2*             = DIVS1;       (* SMCLK Divider 2: /4 *)
DIVS_3*             = DIVS0+DIVS1; (* SMCLK Divider 3: /8 *)

DIVM_0*             = {};          (* MCLK Divider 0: /1 *)
DIVM_1*             = DIVM0;       (* MCLK Divider 1: /2 *)
DIVM_2*             = DIVM1;       (* MCLK Divider 2: /4 *)
DIVM_3*             = DIVM0+DIVM1; (* MCLK Divider 3: /8 *)

SELM_0*             = {};          (* MCLK Source Select 0: DCOCLK *)
SELM_1*             = SELM0;       (* MCLK Source Select 1: DCOCLK *)
SELM_2*             = SELM1;       (* MCLK Source Select 2: XT2CLK/LFXTCLK *)
SELM_3*             = SELM0+SELM1; (* MCLK Source Select 3: LFXTCLK *)

BCSCTL3*            = SYSTEM.VAL(PBYTESET, 0053H); (* Basic Clock System Control 3 *)
LFXT1OF*            = {0}; (* Low/high Frequency Oscillator Fault Flag *)
XT2OF*              = {1}; (* High frequency oscillator 2 fault flag *)
XCAP0*              = {2}; (* XIN/XOUT Cap 0 *)
XCAP1*              = {3}; (* XIN/XOUT Cap 1 *)
LFXT1S0*            = {4}; (* Mode 0 for LFXT1 (XTS = 0) *)
LFXT1S1*            = {5}; (* Mode 1 for LFXT1 (XTS = 0) *)
XT2S0*              = {6}; (* Mode 0 for XT2 *)
XT2S1*              = {7}; (* Mode 1 for XT2 *)

XCAP_0*             = {};          (* XIN/XOUT Cap : 0 pF *)
XCAP_1*             = XCAP0;       (* XIN/XOUT Cap : 6 pF *)
XCAP_2*             = XCAP1;       (* XIN/XOUT Cap : 10 pF *)
XCAP_3*             = XCAP0+XCAP1; (* XIN/XOUT Cap : 12.5 pF *)

LFXT1S_0*           = {};              (* Mode 0 for LFXT1 : Normal operation *)
LFXT1S_1*           = LFXT1S0;         (* Mode 1 for LFXT1 : Reserved *)
LFXT1S_2*           = LFXT1S1;         (* Mode 2 for LFXT1 : VLO *)
LFXT1S_3*           = LFXT1S0+LFXT1S1; (* Mode 3 for LFXT1 : Digital input signal *)

XT2S_0*             = {};          (* Mode 0 for XT2 : 0.4 - 1 MHz *)
XT2S_1*             = XT2S0;       (* Mode 1 for XT2 : 1 - 4 MHz *)
XT2S_2*             = XT2S1;       (* Mode 2 for XT2 : 2 - 16 MHz *)
XT2S_3*             = XT2S0+XT2S1; (* Mode 3 for XT2 : Digital input signal *)

(*************************************************************
* Flash Memory
*************************************************************)
FRKEY*              = SYSTEM.VAL(SET, 9600H);  (* Flash key returned by read *)
FWKEY*              = SYSTEM.VAL(SET, 0A500H); (* Flash key for write *)
FXKEY*              = SYSTEM.VAL(SET, 3300H);  (* for use with XOR instruction *)

FCTL1*              = SYSTEM.VAL(PSET, 0128H); (* FLASH Control 1 *)
ERASE*              = {1};           (* Enable bit for Flash segment erase *)
MERAS*              = {2};           (* Enable bit for Flash mass erase *)
WRT*                = {6};           (* Enable bit for Flash write *)
BLKWRT*             = {7};           (* Enable bit for Flash segment write *)
SEGWRT*             = {7};           (* old definition, enable bit for Flash segment write *)

FCTL2*              = SYSTEM.VAL(PSET, 012AH); (* FLASH Control 2 *)
FN0*                = {0};            (* Divide Flash clock by 1 to 64 using FN0 to FN5 according to: *)
FN1*                = {1};            (*  32*FN5 + 16*FN4 + 8*FN3 + 4*FN2 + 2*FN1 + FN0 + 1 *)
FN2*                = {2};
FN3*                = {3};
FN4*                = {4};
FN5*                = {5};
FSSEL0*             = {6};            (* Flash clock select 0, to distinguish from USART SSELx *)
FSSEL1*             = {7};            (* Flash clock select 1 *)

FSSEL_0*            = {};             (* Flash clock select: 0 - ACLK *)
FSSEL_1*            = FSSEL0;         (* Flash clock select: 1 - MCLK *)
FSSEL_2*            = FSSEL1;         (* Flash clock select: 2 - SMCLK *)
FSSEL_3*            = FSSEL0+FSSEL1;  (* Flash clock select: 3 - SMCLK *)

FCTL3*              = SYSTEM.VAL(PSET, 012CH); (* FLASH Control 3 *)
BUSY*               = {0};            (* Flash busy: 1 *)
KEYV*               = {1};            (* Flash Key violation flag *)
ACCVIFG*            = {2};            (* Flash Access violation flag *)
WAIT*               = {3};            (* Wait flag for segment write *)
LOCK*               = {4};            (* Lock bit: 1 - Flash is locked (read only) *)
EMEX*               = {5};            (* Flash Emergency Exit *)
LOCKA*              = {6};            (* Segment A Lock bit: read = 1 - Segment is locked (read only) *)
FAIL*               = {7};            (* Last Program or Erase failed *)

(************************************************************
* DIGITAL I/O Port1/2 Pull up / Pull down Resistors
************************************************************)
P1IN*               = SYSTEM.VAL(PBYTESET, 0020H); (* Port 1 Input *)
P1OUT*              = SYSTEM.VAL(PBYTESET, 0021H); (* Port 1 Output *)
P1DIR*              = SYSTEM.VAL(PBYTESET, 0022H); (* Port 1 Direction *)
P1IFG*              = SYSTEM.VAL(PBYTESET, 0023H); (* Port 1 Interrupt Flag *)
P1IES*              = SYSTEM.VAL(PBYTESET, 0024H); (* Port 1 Interrupt Edge Select *)
P1IE*               = SYSTEM.VAL(PBYTESET, 0025H); (* Port 1 Interrupt Enable *)
P1SEL*              = SYSTEM.VAL(PBYTESET, 0026H); (* Port 1 Selection *)
P1REN*              = SYSTEM.VAL(PBYTESET, 0027H); (* Port 1 Resistor Enable *)
P2IN*               = SYSTEM.VAL(PBYTESET, 0028H); (* Port 2 Input *)
P2OUT*              = SYSTEM.VAL(PBYTESET, 0029H); (* Port 2 Output *)
P2DIR*              = SYSTEM.VAL(PBYTESET, 002AH); (* Port 2 Direction *)
P2IFG*              = SYSTEM.VAL(PBYTESET, 002BH); (* Port 2 Interrupt Flag *)
P2IES*              = SYSTEM.VAL(PBYTESET, 002CH); (* Port 2 Interrupt Edge Select *)
P2IE*               = SYSTEM.VAL(PBYTESET, 002DH); (* Port 2 Interrupt Enable *)
P2SEL*              = SYSTEM.VAL(PBYTESET, 002EH); (* Port 2 Selection *)
P2REN*              = SYSTEM.VAL(PBYTESET, 002FH); (* Port 2 Resistor Enable *)

(************************************************************
* Timer A2
************************************************************)
TAIV*               = SYSTEM.VAL(PINTEGER, 012EH); (* Timer0_A3 Interrupt Vector Word *)
TAIV_NONE*          = 00H; (* No Interrupt pending *)
TAIV_TACCR1*        = 02H; (* TA0CCR1_CCIFG *)
TAIV_TACCR2*        = 04H; (* TA0CCR2_CCIFG *)
TAIV_6*             = 06H; (* Reserved *)
TAIV_8*             = 08H; (* Reserved *)
TAIV_TAIFG*         = 0AH; (* TA0IFG *)

TACTL*              = SYSTEM.VAL(PSET, 0160H); (* Timer0_A3 Control *)
TASSEL1*            = {9}; (* Timer A clock source select 1 *)
TASSEL0*            = {8}; (* Timer A clock source select 0 *)
ID1*                = {7}; (* Timer A clock input divider 1 *)
ID0*                = {6}; (* Timer A clock input divider 0 *)
MC1*                = {5}; (* Timer A mode control 1 *)
MC0*                = {4}; (* Timer A mode control 0 *)
TACLR*              = {2}; (* Timer A counter clear *)
TAIE*               = {1}; (* Timer A counter interrupt enable *)
TAIFG*              = {0}; (* Timer A counter interrupt flag *)

MC_0*               = {};      (* Timer A mode control: 0 - Stop *)
MC_1*               = MC0;     (* Timer A mode control: 1 - Up to CCR0 *)
MC_2*               = MC1;     (* Timer A mode control: 2 - Continous up *)
MC_3*               = MC0+MC1; (* Timer A mode control: 3 - Up/Down *)

ID_0*               = {};      (* Timer A input divider: 0 - /1 *)
ID_1*               = ID0;     (* Timer A input divider: 1 - /2 *)
ID_2*               = ID1;     (* Timer A input divider: 2 - /4 *)
ID_3*               = ID0+ID1; (* Timer A input divider: 3 - /8 *)

TASSEL_0*           = {};              (* Timer A clock source select: 0 - TACLK *)
TASSEL_1*           = TASSEL0;         (* Timer A clock source select: 1 - ACLK *)
TASSEL_2*           = TASSEL1;         (* Timer A clock source select: 2 - SMCLK *)
TASSEL_3*           = TASSEL0+TASSEL1; (* Timer A clock source select: 3 - INCLK *)

TACCTL0*            = SYSTEM.VAL(PSET, 0162H); (* Timer0_A3 Capture/Compare Control 0 *)
TACCTL1*            = SYSTEM.VAL(PSET, 0164H); (* Timer0_A3 Capture/Compare Control 1 *)
CM1*                = {15}; (* Capture mode 1 *)
CM0*                = {14}; (* Capture mode 0 *)
CCIS1*              = {13}; (* Capture input select 1 *)
CCIS0*              = {12}; (* Capture input select 0 *)
SCS*                = {11}; (* Capture sychronize *)
SCCI*               = {10}; (* Latched capture signal (read) *)
CAP*                = {8};  (* Capture mode: 1 /Compare mode : 0 *)
OUTMOD2*            = {7};  (* Output mode 2 *)
OUTMOD1*            = {6};  (* Output mode 1 *)
OUTMOD0*            = {5};  (* Output mode 0 *)
CCIE*               = {4};  (* Capture/compare interrupt enable *)
CCI*                = {3};  (* Capture input signal (read) *)
OUT*                = {2};  (* PWM Output signal if output mode 0 *)
COV*                = {1};  (* Capture/compare overflow flag *)
CCIFG*              = {0};  (* Capture/compare interrupt flag *)

OUTMOD_0*           = {};                      (* PWM output mode: 0 - output only *)
OUTMOD_1*           = OUTMOD0;                 (* PWM output mode: 1 - set *)
OUTMOD_2*           = OUTMOD1;                 (* PWM output mode: 2 - PWM toggle/reset *)
OUTMOD_3*           = OUTMOD0+OUTMOD1;         (* PWM output mode: 3 - PWM set/reset *)
OUTMOD_4*           = OUTMOD2;                 (* PWM output mode: 4 - toggle *)
OUTMOD_5*           = OUTMOD2+OUTMOD0;         (* PWM output mode: 5 - Reset *)
OUTMOD_6*           = OUTMOD2+OUTMOD1;         (* PWM output mode: 6 - PWM toggle/set *)
OUTMOD_7*           = OUTMOD2+OUTMOD0+OUTMOD1; (* PWM output mode: 7 - PWM reset/set *)
CCIS_0*             = {};          (* Capture input select: 0 - CCIxA *)
CCIS_1*             = CCIS0;       (* Capture input select: 1 - CCIxB *)
CCIS_2*             = CCIS1;       (* Capture input select: 2 - GND *)
CCIS_3*             = CCIS0+CCIS1; (* Capture input select: 3 - Vcc *)
CM_0*               = {};      (* Capture mode: 0 - disabled *)
CM_1*               = CM0;     (* Capture mode: 1 - pos. edge *)
CM_2*               = CM1;     (* Capture mode: 1 - neg. edge *)
CM_3*               = CM0+CM1; (* Capture mode: 1 - both edges *)

TAR*                = SYSTEM.VAL(PINTEGER, 0170H); (* Timer0_A3 Counter Register *)
TACCR0*             = SYSTEM.VAL(PINTEGER, 0172H); (* Timer0_A3 Capture/Compare 0 *)
TACCR1*             = SYSTEM.VAL(PINTEGER, 0174H); (* Timer0_A3 Capture/Compare 1 *)

(************************************************************
* USI
************************************************************)
USICTL0*            = SYSTEM.VAL(PBYTESET, 0078H); (* USI  Control Register 0 *)
USIPE7*             = {7};         (* USI  Port Enable Px.7 *)
USIPE6*             = {6};         (* USI  Port Enable Px.6 *)
USIPE5*             = {5};         (* USI  Port Enable Px.5 *)
USILSB*             = {4};         (* USI  LSB first  1:LSB / 0:MSB *)
USIMST*             = {3};         (* USI  Master Select  0:Slave / 1:Master *)
USIGE*              = {2};         (* USI  General Output Enable Latch *)
USIOE*              = {1};         (* USI  Output Enable *)
USISWRST*           = {0};         (* USI  Software Reset *)

USICTL1*           = SYSTEM.VAL(PBYTESET, 0079H); (* USI  Control Register 1 *)
USICKPH*           = {7};          (* USI  Sync. Mode: Clock Phase *)
USII2C*            = {6};          (* USI  I2C Mode *)
USISTTIE*          = {5};          (* USI  START Condition interrupt enable *)
USIIE*             = {4};          (* USI  Counter Interrupt enable *)
USIAL*             = {3};          (* USI  Arbitration Lost *)
USISTP*            = {2};          (* USI  STOP Condition received *)
USISTTIFG*         = {1};          (* USI  START Condition interrupt Flag *)
USIIFG*            = {0};          (* USI  Counter Interrupt Flag *)

USICKCTL*          = SYSTEM.VAL(PBYTESET, 007AH); (* USI  Clock Control Register *)
USIDIV2*           = {7};          (* USI  Clock Divider 2 *)
USIDIV1*           = {6};          (* USI  Clock Divider 1 *)
USIDIV0*           = {5};          (* USI  Clock Divider 0 *)
USISSEL2*          = {4};          (* USI  Clock Source Select 2 *)
USISSEL1*          = {3};          (* USI  Clock Source Select 1 *)
USISSEL0*          = {2};          (* USI  Clock Source Select 0 *)
USICKPL*           = {1};          (* USI  Clock Polarity 0:Inactive=Low / 1:Inactive=High *)
USISWCLK*          = {0};          (* USI  Software Clock *)

USIDIV_0*          = {};                          (* USI  Clock Divider: 0 *)
USIDIV_1*          = USIDIV0;                     (* USI  Clock Divider: 1 *)
USIDIV_2*          = USIDIV1;                     (* USI  Clock Divider: 2 *)
USIDIV_3*          = USIDIV0 + USIDIV1;           (* USI  Clock Divider: 3 *)
USIDIV_4*          = USIDIV2;                     (* USI  Clock Divider: 4 *)
USIDIV_5*          = USIDIV0 + USIDIV2;           (* USI  Clock Divider: 5 *)
USIDIV_6*          = USIDIV1 + USIDIV2;           (* USI  Clock Divider: 6 *)
USIDIV_7*          = USIDIV0 + USIDIV1 + USIDIV2; (* USI  Clock Divider: 7 *)

USISSEL_0*         = {};                             (* USI  Clock Source: 0 *)
USISSEL_1*         = USISSEL0;                       (* USI  Clock Source: 1 *)
USISSEL_2*         = USISSEL1;                       (* USI  Clock Source: 2 *)
USISSEL_3*         = USISSEL0 + USISSEL1;            (* USI  Clock Source: 3 *)
USISSEL_4*         = USISSEL2;                       (* USI  Clock Source: 4 *)
USISSEL_5*         = USISSEL0 + USISSEL2;            (* USI  Clock Source: 5 *)
USISSEL_6*         = USISSEL1 + USISSEL2;            (* USI  Clock Source: 6 *)
USISSEL_7*         = USISSEL0 + USISSEL1 + USISSEL2; (* USI  Clock Source: 7 *)

USICNT*            = SYSTEM.VAL(PBYTESET, 007BH); (* USI  Bit Counter Register *)
USISCLREL*         = {7};          (* USI  SCL Released *)
USI16B*            = {6};          (* USI  16 Bit Shift Register Enable *)
USIIFGCC*          = {5};          (* USI  Interrupt Flag Clear Control *)
USICNT4*           = {4};          (* USI  Bit Count 4 *)
USICNT3*           = {3};          (* USI  Bit Count 3 *)
USICNT2*           = {2};          (* USI  Bit Count 2 *)
USICNT1*           = {1};          (* USI  Bit Count 1 *)
USICNT0*           = {0};          (* USI  Bit Count 0 *)

USISRL*            = SYSTEM.VAL(PBYTE, 007CH); (* USI  Low Byte Shift Register *)
USISRH*            = SYSTEM.VAL(PBYTE, 007DH); (* USI  High Byte Shift Register *)
USICTL*            = SYSTEM.VAL(PSET, 0078H);     (* USI  Control Register *)
USICCTL*           = SYSTEM.VAL(PSET, 007AH);     (* USI  Clock and Counter Control Register *)
USISR*             = SYSTEM.VAL(PINTEGER, 007CH);     (* USI  Shift Register *)

(************************************************************
* WATCHDOG TIMER
************************************************************)
WDTCTL*             = SYSTEM.VAL(PSET, 0120H);

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
WDT_MDLY_32*        = (WDTPW+WDTTMSEL+WDTCNTCL);               (* 32ms interval (default) *)
WDT_MDLY_8*         = (WDTPW+WDTTMSEL+WDTCNTCL+WDTIS0);        (* 8ms     " *)
WDT_MDLY_0_5*       = (WDTPW+WDTTMSEL+WDTCNTCL+WDTIS1);        (* 0.5ms   " *)
WDT_MDLY_0_064*     = (WDTPW+WDTTMSEL+WDTCNTCL+WDTIS1+WDTIS0); (* 0.064ms " *)
(* WDT is clocked by fACLK (assumed 32KHz) *)
WDT_ADLY_1000*      = (WDTPW+WDTTMSEL+WDTCNTCL+WDTSSEL);               (* 1000ms  " *)
WDT_ADLY_250*       = (WDTPW+WDTTMSEL+WDTCNTCL+WDTSSEL+WDTIS0);        (* 250ms   " *)
WDT_ADLY_16*        = (WDTPW+WDTTMSEL+WDTCNTCL+WDTSSEL+WDTIS1);        (* 16ms    " *)
WDT_ADLY_1_9*       = (WDTPW+WDTTMSEL+WDTCNTCL+WDTSSEL+WDTIS1+WDTIS0); (* 1.9ms   " *)
(* Watchdog mode -> reset after expired time *)
(* WDT is clocked by fSMCLK (assumed 1MHz) *)
WDT_MRST_32*        = (WDTPW+WDTCNTCL); (* 32ms interval (default) *)
WDT_MRST_8*         = (WDTPW+WDTCNTCL+WDTIS0);        (* 8ms     " *)
WDT_MRST_0_5*       = (WDTPW+WDTCNTCL+WDTIS1);        (* 0.5ms   " *)
WDT_MRST_0_064*     = (WDTPW+WDTCNTCL+WDTIS1+WDTIS0); (* 0.064ms " *)
(* WDT is clocked by fACLK (assumed 32KHz) *)
WDT_ARST_1000*      = (WDTPW+WDTCNTCL+WDTSSEL);               (* 1000ms  " *)
WDT_ARST_250*       = (WDTPW+WDTCNTCL+WDTSSEL+WDTIS0);        (* 250ms   " *)
WDT_ARST_16*        = (WDTPW+WDTCNTCL+WDTSSEL+WDTIS1);        (* 16ms    " *)
WDT_ARST_1_9*       = (WDTPW+WDTCNTCL+WDTSSEL+WDTIS1+WDTIS0); (* 1.9ms   " *)

(* INTERRUPT CONTROL *)
(* These two bits are defined in the Special Function Registers *)
(* WDTIE, WDTIFG *)

(************************************************************
* Calibration Data in Info Mem
************************************************************)
CALDCO_1MHZ*        = SYSTEM.VAL(PBYTESET, 10FEH);
CALBC1_1MHZ*        = SYSTEM.VAL(PBYTESET, 10FFH);

(************************************************************
* Interrupt Vectors (offset from 0xFFE0)
************************************************************)
PORT1_VECTOR*       = 16+2;                 (* 0xFFE4 Port 1 *)
PORT2_VECTOR*       = 16+3;                 (* 0xFFE6 Port 2 *)
USI_VECTOR*         = 16+4;                 (* 0xFFE8 USI *)
ADC10_VECTOR*       = 16+5;                 (* 0xFFEA ADC10 *)
TIMERA1_VECTOR*     = 16+8;                 (* 0xFFF0 Timer0_A CC1, TA0 *)
TIMERA0_VECTOR*     = 16+9;                 (* 0xFFF2 Timer0_A CC0 *)
WDT_VECTOR*         = 16+10;                (* 0xFFF4 Watchdog Timer *)
NMI_VECTOR*         = 16+14;                (* 0xFFFC Non-maskable *)
RESET_VECTOR*       = 16+15;                (* 0xFFFE Reset [Highest Priority] *)

(************************************************************
* End of Modules
************************************************************)

END msp430g2231.
