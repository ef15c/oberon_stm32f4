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

IE2*                = SYSTEM.VAL(PBYTESET, 0001H); (* Interrupt Enable 2 *)
UC0IE*              = IE2;
UCA0RXIE*           = {0};
UCA0TXIE*           = {1};
UCB0RXIE*           = {2};
UCB0TXIE*           = {3};

IFG2*               = SYSTEM.VAL(PBYTESET, 0003H); (* Interrupt Flag 2 *)
UC0IFG*             = IFG2;
UCA0RXIFG*          = {0};
UCA0TXIFG*          = {1};
UCB0RXIFG*          = {2};
UCB0TXIFG*          = {3};

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

(************************************************************
* Comparator A
************************************************************)
CACTL1*             = SYSTEM.VAL(PBYTESET, 0059H); (* Comparator A Control 1 *)
CAIFG*              = {0};         (* Comp. A Interrupt Flag *)
CAIE*               = {1};         (* Comp. A Interrupt Enable *)
CAIES*              = {2};         (* Comp. A Int. Edge Select: 0:rising / 1:falling *)
CAON*               = {3};         (* Comp. A enable *)
CAREF0*             = {4};         (* Comp. A Internal Reference Select 0 *)
CAREF1*             = {5};         (* Comp. A Internal Reference Select 1 *)
CARSEL*             = {6};         (* Comp. A Internal Reference Enable *)
CAEX*               = {7};         (* Comp. A Exchange Inputs *)

CAREF_0*            = {};            (* Comp. A Int. Ref. Select 0 : Off *)
CAREF_1*            = CAREF0;        (* Comp. A Int. Ref. Select 1 : 0.25*Vcc *)
CAREF_2*            = CAREF1;        (* Comp. A Int. Ref. Select 2 : 0.5*Vcc *)
CAREF_3*            = CAREF0+CAREF1; (* Comp. A Int. Ref. Select 3 : Vt*)

CACTL2*             = SYSTEM.VAL(PBYTESET, 005AH); (* Comparator A Control 2 *)
CAOUT*              = {0};           (* Comp. A Output *)
CAF*                = {1};           (* Comp. A Enable Output Filter *)
P2CA0*              = {2};           (* Comp. A +Terminal Multiplexer *)
P2CA1*              = {3};           (* Comp. A -Terminal Multiplexer *)
P2CA2*              = {4};           (* Comp. A -Terminal Multiplexer *)
P2CA3*              = {5};           (* Comp. A -Terminal Multiplexer *)
P2CA4*              = {6};           (* Comp. A +Terminal Multiplexer *)
CASHORT*            = {7};           (* Comp. A Short + and - Terminals *)

CAPD*               = SYSTEM.VAL(PBYTESET, 005BH); (* Comparator A Port Disable *)
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
P1SEL2*             = SYSTEM.VAL(PBYTESET, 0041H); (* Port 1 Selection 2 *)
P1REN*              = SYSTEM.VAL(PBYTESET, 0027H); (* Port 1 Resistor Enable *)
P2IN*               = SYSTEM.VAL(PBYTESET, 0028H); (* Port 2 Input *)
P2OUT*              = SYSTEM.VAL(PBYTESET, 0029H); (* Port 2 Output *)
P2DIR*              = SYSTEM.VAL(PBYTESET, 002AH); (* Port 2 Direction *)
P2IFG*              = SYSTEM.VAL(PBYTESET, 002BH); (* Port 2 Interrupt Flag *)
P2IES*              = SYSTEM.VAL(PBYTESET, 002CH); (* Port 2 Interrupt Edge Select *)
P2IE*               = SYSTEM.VAL(PBYTESET, 002DH); (* Port 2 Interrupt Enable *)
P2SEL*              = SYSTEM.VAL(PBYTESET, 002EH); (* Port 2 Selection *)
P2SEL2*             = SYSTEM.VAL(PBYTESET, 0042H); (* Port 2 Selection 2 *)
P2REN*              = SYSTEM.VAL(PBYTESET, 002FH); (* Port 2 Resistor Enable *)
(************************************************************
* DIGITAL I/O Port3 Pull up / Pull down Resistors
************************************************************)
P3IN*               = SYSTEM.VAL(PBYTESET, 0018H); (* Port 3 Input *)
P3OUT*              = SYSTEM.VAL(PBYTESET, 0019H); (* Port 3 Output *)
P3DIR*              = SYSTEM.VAL(PBYTESET, 001AH); (* Port 3 Direction *)
P3SEL*              = SYSTEM.VAL(PBYTESET, 001BH); (* Port 3 Selection *)
P3SEL2*             = SYSTEM.VAL(PBYTESET, 0043H); (* Port 3 Selection 2 *)
P3REN*              = SYSTEM.VAL(PBYTESET, 0010H); (* Port 3 Resistor Enable *)
(************************************************************
* Timer0_A3
************************************************************)
TA0IV*              = SYSTEM.VAL(PINTEGER, 012EH); (* Timer0_A3 Interrupt Vector Word *)
TA0IV_NONE*         = 00H; (* No Interrupt pending *)
TA0IV_TACCR1*       = 02H; (* TA0CCR1_CCIFG *)
TA0IV_TACCR2*       = 04H; (* TA0CCR2_CCIFG *)
TA0IV_6*            = 06H; (* Reserved *)
TA0IV_8*            = 08H; (* Reserved *)
TA0IV_TAIFG*        = 0AH; (* TA0IFG *)

TA0CTL*             = SYSTEM.VAL(PSET, 0160H); (* Timer0_A3 Control *)
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

TA0CCTL0*           = SYSTEM.VAL(PSET, 0162H); (* Timer0_A3 Capture/Compare Control 0 *)
TA0CCTL1*           = SYSTEM.VAL(PSET, 0164H); (* Timer0_A3 Capture/Compare Control 1 *)
TA0CCTL2*           = SYSTEM.VAL(PSET, 0166H); (* Timer0_A3 Capture/Compare Control 2 *)
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

TA0R*               = SYSTEM.VAL(PINTEGER, 0170H); (* Timer0_A3 Counter Register *)
TA0CCR0*            = SYSTEM.VAL(PINTEGER, 0172H); (* Timer0_A3 Capture/Compare 0 *)
TA0CCR1*            = SYSTEM.VAL(PINTEGER, 0174H); (* Timer0_A3 Capture/Compare 1 *)
TA0CCR2*            = SYSTEM.VAL(PINTEGER, 0176H); (* Timer0_A3 Capture/Compare 2 *)

(************************************************************
* Timer1_A3
************************************************************)
TA1IV*              = SYSTEM.VAL(PSET, 011EH);     (* Timer1_A3 Interrupt Vector Word *)
TA1CTL*             = SYSTEM.VAL(PSET, 0180H);     (* Timer1_A3 Control *)
TA1CCTL0*           = SYSTEM.VAL(PSET, 0182H);     (* Timer1_A3 Capture/Compare Control 0 *)
TA1CCTL1*           = SYSTEM.VAL(PSET, 0184H);     (* Timer1_A3 Capture/Compare Control 1 *)
TA1CCTL2*           = SYSTEM.VAL(PSET, 0186H);     (* Timer1_A3 Capture/Compare Control 2 *)
TA1R*               = SYSTEM.VAL(PINTEGER, 0190H); (* Timer1_A3 Counter Register *)
TA1CCR0*            = SYSTEM.VAL(PINTEGER, 0192H); (* Timer1_A3 Capture/Compare 0 *)
TA1CCR1*            = SYSTEM.VAL(PINTEGER, 0194H); (* Timer1_A3 Capture/Compare 1 *)
TA1CCR2*            = SYSTEM.VAL(PINTEGER, 0196H); (* Timer1_A3 Capture/Compare 2 *)
(************************************************************
* USCI
************************************************************)
UCA0CTL0*           = SYSTEM.VAL(PBYTESET, 0060H); (* USCI A0 Control Register 0 *)
(* UART-Mode Bits *)
UCPEN*              = {7}; (* Async. Mode: Parity enable *)
UCPAR*              = {6}; (* Async. Mode: Parity     0:odd / 1:even *)
UCMSB*              = {5}; (* Async. Mode: MSB first  0:LSB / 1:MSB *)
UC7BIT*             = {4}; (* Async. Mode: Data Bits  0:8-bits / 1:7-bits *)
UCSPB*              = {3}; (* Async. Mode: Stop Bits  0:one / 1: two *)
UCMODE1*            = {2}; (* Async. Mode: USCI Mode 1 *)
UCMODE0*            = {1}; (* Async. Mode: USCI Mode 0 *)
UCSYNC *            = {0}; (* Sync-Mode  0:UART-Mode / 1:SPI-Mode *)
(* SPI-Mode Bits *)
UCCKPH*             = {7}; (* Sync. Mode: Clock Phase *)
UCCKPL*             = {6}; (* Sync. Mode: Clock Polarity *)
UCMST*              = {3}; (* Sync. Mode: Master Select *)

UCMODE_0*           = {};              (* Sync. Mode: USCI Mode: 0 *)
UCMODE_1*           = UCMODE0;         (* Sync. Mode: USCI Mode: 1 *)
UCMODE_2*           = UCMODE1;         (* Sync. Mode: USCI Mode: 2 *)
UCMODE_3*           = UCMODE0+UCMODE1; (* Sync. Mode: USCI Mode: 3 *)

UCA0CTL1*           = SYSTEM.VAL(PBYTESET, 0061H); 
(* UART-Mode Bits *)
UCSSEL1*            = {7}; (* USCI 0 Clock Source Select 1 *)
UCSSEL0*            = {6}; (* USCI 0 Clock Source Select 0 *)
UCRXEIE*            = {5}; (* RX Error interrupt enable *)
UCBRKIE*            = {4}; (* Break interrupt enable *)
UCDORM*             = {3}; (* Dormant (Sleep) Mode *)
UCTXADDR*           = {2}; (* Send next Data as Address *)
UCTXBRK*            = {1}; (* Send next Data as Break *)
UCSWRST*            = {0}; (* USCI Software Reset *)

(* SPI-Mode Bits *)
(*res                 {1..5} reserved *)

UCSSEL_0*           = {};              (* USCI 0 Clock Source: 0 *)
UCSSEL_1*           = UCSSEL0;         (* USCI 0 Clock Source: 1 *)
UCSSEL_2*           = UCSSEL1;         (* USCI 0 Clock Source: 2 *)
UCSSEL_3*           = UCSSEL0+UCSSEL1; (* USCI 0 Clock Source: 3 *)

UCA0BR0*            = SYSTEM.VAL(PBYTE, 0062H);
UCA0BR1*            = SYSTEM.VAL(PBYTE, 0063H);
UCA0MCTL*           = SYSTEM.VAL(PBYTESET, 0064H);
UCBRF3*             = {7}; (* USCI First Stage Modulation Select 3 *)
UCBRF2*             = {6}; (* USCI First Stage Modulation Select 2 *)
UCBRF1*             = {5}; (* USCI First Stage Modulation Select 1 *)
UCBRF0*             = {4}; (* USCI First Stage Modulation Select 0 *)
UCBRS2*             = {3}; (* USCI Second Stage Modulation Select 2 *)
UCBRS1*             = {2}; (* USCI Second Stage Modulation Select 1 *)
UCBRS0*             = {1}; (* USCI Second Stage Modulation Select 0 *)
UCOS16*             = {0}; (* USCI 16-times Oversampling enable *)

UCBRF_0*            = {};                          (* USCI First Stage Modulation: 0 *)
UCBRF_1*            = UCBRF0;                      (* USCI First Stage Modulation: 1 *)
UCBRF_2*            = UCBRF1;                      (* USCI First Stage Modulation: 2 *)
UCBRF_3*            = UCBRF0+UCBRF1;               (* USCI First Stage Modulation: 3 *)
UCBRF_4*            = UCBRF2;                      (* USCI First Stage Modulation: 4 *)
UCBRF_5*            = UCBRF0+UCBRF2;               (* USCI First Stage Modulation: 5 *)
UCBRF_6*            = UCBRF1+UCBRF2;               (* USCI First Stage Modulation: 6 *)
UCBRF_7*            = UCBRF0+UCBRF1+UCBRF2;        (* USCI First Stage Modulation: 7 *)
UCBRF_8*            = UCBRF3;                      (* USCI First Stage Modulation: 8 *)
UCBRF_9*            = UCBRF0+UCBRF3;               (* USCI First Stage Modulation: 9 *)
UCBRF_10*           = UCBRF1+UCBRF3;               (* USCI First Stage Modulation: A *)
UCBRF_11*           = UCBRF0+UCBRF1+UCBRF3;        (* USCI First Stage Modulation: B *)
UCBRF_12*           = UCBRF2+UCBRF3;               (* USCI First Stage Modulation: C *)
UCBRF_13*           = UCBRF0+UCBRF2+UCBRF3;        (* USCI First Stage Modulation: D *)
UCBRF_14*           = UCBRF1+UCBRF2+UCBRF3;        (* USCI First Stage Modulation: E *)
UCBRF_15*           = UCBRF0+UCBRF1+UCBRF2+UCBRF3; (* USCI First Stage Modulation: F *)

UCBRS_0*            = {};                   (* USCI Second Stage Modulation: 0 *)
UCBRS_1*            = UCBRS0;               (* USCI Second Stage Modulation: 1 *)
UCBRS_2*            = UCBRS1;               (* USCI Second Stage Modulation: 2 *)
UCBRS_3*            = UCBRS0+UCBRS1;        (* USCI Second Stage Modulation: 3 *)
UCBRS_4*            = UCBRS2;               (* USCI Second Stage Modulation: 4 *)
UCBRS_5*            = UCBRS0+UCBRS2;        (* USCI Second Stage Modulation: 5 *)
UCBRS_6*            = UCBRS1+UCBRS2;        (* USCI Second Stage Modulation: 6 *)
UCBRS_7*            = UCBRS0+UCBRS1+UCBRS2; (* USCI Second Stage Modulation: 7 *)

UCA0STAT*           = SYSTEM.VAL(PBYTESET, 0065H);
(* UART-Mode Bits *)
UCLISTEN*           = {7}; (* USCI Listen mode *)
UCFE*               = {6}; (* USCI Frame Error Flag *)
UCOE*               = {5}; (* USCI Overrun Error Flag *)
UCPE*               = {4}; (* USCI Parity Error Flag *)
UCBRK*              = {3}; (* USCI Break received *)
UCRXERR*            = {2}; (* USCI RX Error Flag *)
UCADDR *            = {1}; (* USCI Address received Flag *)
UCBUSY *            = {0}; (* USCI Busy Flag *)

UCIDLE *            = {1}; (* USCI Idle line detected Flag *)

UCA0RXBUF*          = SYSTEM.VAL(PBYTE, 0066H);
UCA0TXBUF*          = SYSTEM.VAL(PBYTE, 0067H);
UCA0ABCTL*          = SYSTEM.VAL(PBYTESET, 005DH);
(*res               {6..7} reserved *)
UCDELIM1*           = {5}; (* Break Sync Delimiter 1 *)
UCDELIM0*           = {4}; (* Break Sync Delimiter 0 *)
UCSTOE *            = {3}; (* Sync-Field Timeout error *)
UCBTOE *            = {2}; (* Break Timeout error *)
(*res               {1} reserved *)
UCABDEN*            = {0}; (* Auto Baud Rate detect enable *)

UCA0IRTCTL*         = SYSTEM.VAL(PBYTESET, 005EH);
UCIRTXPL5*          = {7}; (* IRDA Transmit Pulse Length 5 *)
UCIRTXPL4*          = {6}; (* IRDA Transmit Pulse Length 4 *)
UCIRTXPL3*          = {5}; (* IRDA Transmit Pulse Length 3 *)
UCIRTXPL2*          = {4}; (* IRDA Transmit Pulse Length 2 *)
UCIRTXPL1*          = {3}; (* IRDA Transmit Pulse Length 1 *)
UCIRTXPL0*          = {2}; (* IRDA Transmit Pulse Length 0 *)
UCIRTXCLK*          = {1}; (* IRDA Transmit Pulse Clock Select *)
UCIREN*             = {0}; (* IRDA Encoder/Decoder enable *)

UCA0IRRCTL*         = SYSTEM.VAL(PBYTESET, 005FH);
UCIRRXFL5*          = {7}; (* IRDA Receive Filter Length 5 *)
UCIRRXFL4*          = {6}; (* IRDA Receive Filter Length 4 *)
UCIRRXFL3*          = {5}; (* IRDA Receive Filter Length 3 *)
UCIRRXFL2*          = {4}; (* IRDA Receive Filter Length 2 *)
UCIRRXFL1*          = {3}; (* IRDA Receive Filter Length 1 *)
UCIRRXFL0*          = {2}; (* IRDA Receive Filter Length 0 *)
UCIRRXPL*           = {1}; (* IRDA Receive Input Polarity *)
UCIRRXFE*           = {0}; (* IRDA Receive Filter enable *)

UCB0CTL0*           = SYSTEM.VAL(PBYTESET, 0068H);
(* I2C-Mode Bits *)
UCA10*              = {7}; (* 10-bit Address Mode *)
UCSLA10*            = {6}; (* 10-bit Slave Address Mode *)
UCMM*               = {5}; (* Multi-Master Environment *)
(*res                 {4}  reserved *)

UCB0CTL1*           = SYSTEM.VAL(PBYTESET, 0069H);
(* I2C-Mode Bits *)
(*res                 {5}  reserved *)
UCTR*               = {4}; (* Transmit/Receive Select/Flag *)
UCTXNACK*           = {3}; (* Transmit NACK *)
UCTXSTP*            = {2}; (* Transmit STOP *)
UCTXSTT*            = {1}; (* Transmit START *)

UCB0BR0*            = SYSTEM.VAL(PBYTE, 006AH);
UCB0BR1*            = SYSTEM.VAL(PBYTE, 006BH);
UCB0I2CIE*          = SYSTEM.VAL(PBYTESET, 006CH);
(*res               {4..7} reserved *)
UCNACKIE*           = {3}; (* NACK Condition interrupt enable *)
UCSTPIE*            = {2}; (* STOP Condition interrupt enable *)
UCSTTIE*            = {1}; (* START Condition interrupt enable *)
UCALIE *            = {0}; (* Arbitration Lost interrupt enable *)

UCB0STAT*           = SYSTEM.VAL(PBYTESET, 006DH);
(* I2C-Mode Bits *)
(*res                 {7}  reserved *)
UCSCLLOW*           = {6}; (* SCL low *)
UCGC*               = {5}; (* General Call address received Flag *)
UCBBUSY*            = {4}; (* Bus Busy Flag *)
UCNACKIFG*          = {3}; (* NAK Condition interrupt Flag *)
UCSTPIFG*           = {2}; (* STOP Condition interrupt Flag *)
UCSTTIFG*           = {1}; (* START Condition interrupt Flag *)
UCALIFG*            = {0}; (* Arbitration Lost interrupt Flag *)

UCB0RXBUF*          = SYSTEM.VAL(PBYTE, 006EH);
UCB0TXBUF*          = SYSTEM.VAL(PBYTE, 006FH);
UCB0I2COA*          = SYSTEM.VAL(PSET, 0118H);
UCGCEN*             = {15}; (* I2C General Call enable *)

UCB0I2CSA*          = SYSTEM.VAL(PINTEGER, 011AH);

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
CALDCO_16MHZ*       = SYSTEM.VAL(PBYTESET, 10F8H);
CALBC1_16MHZ*       = SYSTEM.VAL(PBYTESET, 10F9H);
CALDCO_12MHZ*       = SYSTEM.VAL(PBYTESET, 10FAH);
CALBC1_12MHZ*       = SYSTEM.VAL(PBYTESET, 10FBH);
CALDCO_8MHZ*        = SYSTEM.VAL(PBYTESET, 10FCH);
CALBC1_8MHZ*        = SYSTEM.VAL(PBYTESET, 10FDH);
CALDCO_1MHZ*        = SYSTEM.VAL(PBYTESET, 10FEH);
CALBC1_1MHZ*        = SYSTEM.VAL(PBYTESET, 10FFH);
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

OMSPTool.DecSym msp430g2553.sms
decode msp430g2553.sms
msp430g2553 F10488DC  1
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
   1 IE1 [^18]       0
   1 WDTIE [^6]       1
   1 OFIE [^6]       2
   1 NMIIE [^6]      16
   1 ACCVIE [^6]      32
   1 IFG1 [^18]       2
   1 WDTIFG [^6]       1
   1 OFIFG [^6]       2
   1 PORIFG [^6]       4
   1 RSTIFG [^6]       8
   1 NMIIFG [^6]      16
   1 IE2 [^18]       1
   1 UC0IE [^18]       1
   1 UCA0RXIE [^6]       1
   1 UCA0TXIE [^6]       2
   1 UCB0RXIE [^6]       4
   1 UCB0TXIE [^6]       8
   1 IFG2 [^18]       3
   1 UC0IFG [^18]       3
   1 UCA0RXIFG [^6]       1
   1 UCA0TXIFG [^6]       2
   1 UCB0RXIFG [^6]       4
   1 UCB0TXIFG [^6]       8
   1 ADC10DTC0 [^18]      72
   1 ADC10FETCH [^6]       1
   1 ADC10B1 [^6]       2
   1 ADC10CT [^6]       4
   1 ADC10TB [^6]       8
   1 ADC10DTC1 [^14]      73
   1 ADC10DISABLE [^4]       0
   1 ADC10AE0 [^18]      74
   1 ADC10CTL0 [^17]     432
   1 ADC10SC [^6]       1
   1 ENC [^6]       2
   1 ADC10IFG [^6]       4
   1 ADC10IE [^6]       8
   1 ADC10ON [^6]      16
   1 REFON [^6]      32
   1 REF2_5V [^6]      64
   1 MSC [^6]     128
   1 REFBURST [^6]     256
   1 REFOUT [^6]     512
   1 ADC10SR [^6]    1024
   1 ADC10SHT0 [^6]    2048
   1 ADC10SHT1 [^6]    4096
   1 SREF0 [^6]    8192
   1 SREF1 [^6]   16384
   1 SREF2 [^6]   32768
   1 ADC10SHT_0 [^6]       0
   1 ADC10SHT_1 [^6]    2048
   1 ADC10SHT_2 [^6]    4096
   1 ADC10SHT_3 [^6]    6144
   1 SREF_0 [^6]       0
   1 SREF_1 [^6]    8192
   1 SREF_2 [^6]   16384
   1 SREF_3 [^6]   24576
   1 SREF_4 [^6]   32768
   1 SREF_5 [^6]   40960
   1 SREF_6 [^6]   49152
   1 SREF_7 [^6]   57344
   1 ADC10CTL1 [^17]     434
   1 ADC10BUSY [^6]       1
   1 CONSEQ0 [^6]       2
   1 CONSEQ1 [^6]       4
   1 ADC10SSEL0 [^6]       8
   1 ADC10SSEL1 [^6]      16
   1 ADC10DIV0 [^6]      32
   1 ADC10DIV1 [^6]      64
   1 ADC10DIV2 [^6]     128
   1 ISSH [^6]     256
   1 ADC10DF [^6]     512
   1 SHS0 [^6]    1024
   1 SHS1 [^6]    2048
   1 INCH0 [^6]    4096
   1 INCH1 [^6]    8192
   1 INCH2 [^6]   16384
   1 INCH3 [^6]   32768
   1 CONSEQ_0 [^6]       0
   1 CONSEQ_1 [^6]       2
   1 CONSEQ_2 [^6]       4
   1 CONSEQ_3 [^6]       6
   1 ADC10SSEL_0 [^6]       0
   1 ADC10SSEL_1 [^6]       8
   1 ADC10SSEL_2 [^6]      16
   1 ADC10SSEL_3 [^6]      24
   1 ADC10DIV_0 [^6]       0
   1 ADC10DIV_1 [^6]      32
   1 ADC10DIV_2 [^6]      64
   1 ADC10DIV_3 [^6]      96
   1 ADC10DIV_4 [^6]     128
   1 ADC10DIV_5 [^6]     160
   1 ADC10DIV_6 [^6]     192
   1 ADC10DIV_7 [^6]     224
   1 SHS_0 [^6]       0
   1 SHS_1 [^6]    1024
   1 SHS_2 [^6]    2048
   1 SHS_3 [^6]    3072
   1 INCH_0 [^6]       0
   1 INCH_1 [^6]    4096
   1 INCH_2 [^6]    8192
   1 INCH_3 [^6]   12288
   1 INCH_4 [^6]   16384
   1 INCH_5 [^6]   20480
   1 INCH_6 [^6]   24576
   1 INCH_7 [^6]   28672
   1 INCH_8 [^6]   32768
   1 INCH_9 [^6]   36864
   1 INCH_10 [^6]   40960
   1 INCH_11 [^6]   45056
   1 INCH_12 [^6]   49152
   1 INCH_13 [^6]   53248
   1 INCH_14 [^6]   57344
   1 INCH_15 [^6]   61440
   1 ADC10MEM [^7]     436
   1 ADC10SA [^7]     444
   1 DCOCTL [^18]      86
   1 MOD0 [^6]       1
   1 MOD1 [^6]       2
   1 MOD2 [^6]       4
   1 MOD3 [^6]       8
   1 MOD4 [^6]      16
   1 DCO0 [^6]      32
   1 DCO1 [^6]      64
   1 DCO2 [^6]     128
   1 BCSCTL1 [^18]      87
   1 RSEL0 [^6]       1
   1 RSEL1 [^6]       2
   1 RSEL2 [^6]       4
   1 RSEL3 [^6]       8
   1 DIVA0 [^6]      16
   1 DIVA1 [^6]      32
   1 XTS [^6]      64
   1 XT2OFF [^6]     128
   1 DIVA_0 [^6]       0
   1 DIVA_1 [^6]      16
   1 DIVA_2 [^6]      32
   1 DIVA_3 [^6]      48
   1 BCSCTL2 [^18]      88
   1 DIVS0 [^6]       2
   1 DIVS1 [^6]       4
   1 SELS [^6]       8
   1 DIVM0 [^6]      16
   1 DIVM1 [^6]      32
   1 SELM0 [^6]      64
   1 SELM1 [^6]     128
   1 DIVS_0 [^6]       0
   1 DIVS_1 [^6]       2
   1 DIVS_2 [^6]       4
   1 DIVS_3 [^6]       6
   1 DIVM_0 [^6]       0
   1 DIVM_1 [^6]      16
   1 DIVM_2 [^6]      32
   1 DIVM_3 [^6]      48
   1 SELM_0 [^6]       0
   1 SELM_1 [^6]      64
   1 SELM_2 [^6]     128
   1 SELM_3 [^6]     192
   1 BCSCTL3 [^18]      83
   1 LFXT1OF [^6]       1
   1 XT2OF [^6]       2
   1 XCAP0 [^6]       4
   1 XCAP1 [^6]       8
   1 LFXT1S0 [^6]      16
   1 LFXT1S1 [^6]      32
   1 XT2S0 [^6]      64
   1 XT2S1 [^6]     128
   1 XCAP_0 [^6]       0
   1 XCAP_1 [^6]       4
   1 XCAP_2 [^6]       8
   1 XCAP_3 [^6]      12
   1 LFXT1S_0 [^6]       0
   1 LFXT1S_1 [^6]      16
   1 LFXT1S_2 [^6]      32
   1 LFXT1S_3 [^6]      48
   1 XT2S_0 [^6]       0
   1 XT2S_1 [^6]      64
   1 XT2S_2 [^6]     128
   1 XT2S_3 [^6]     192
   1 CACTL1 [^18]      89
   1 CAIFG [^6]       1
   1 CAIE [^6]       2
   1 CAIES [^6]       4
   1 CAON [^6]       8
   1 CAREF0 [^6]      16
   1 CAREF1 [^6]      32
   1 CARSEL [^6]      64
   1 CAEX [^6]     128
   1 CAREF_0 [^6]       0
   1 CAREF_1 [^6]      16
   1 CAREF_2 [^6]      32
   1 CAREF_3 [^6]      48
   1 CACTL2 [^18]      90
   1 CAOUT [^6]       1
   1 CAF [^6]       2
   1 P2CA0 [^6]       4
   1 P2CA1 [^6]       8
   1 P2CA2 [^6]      16
   1 P2CA3 [^6]      32
   1 P2CA4 [^6]      64
   1 CASHORT [^6]     128
   1 CAPD [^18]      91
   1 FRKEY [^6]   38400
   1 FWKEY [^6]   42240
   1 FXKEY [^6]   13056
   1 FCTL1 [^17]     296
   1 ERASE [^6]       2
   1 MERAS [^6]       4
   1 WRT [^6]      64
   1 BLKWRT [^6]     128
   1 SEGWRT [^6]     128
   1 FCTL2 [^17]     298
   1 FN0 [^6]       1
   1 FN1 [^6]       2
   1 FN2 [^6]       4
   1 FN3 [^6]       8
   1 FN4 [^6]      16
   1 FN5 [^6]      32
   1 FSSEL0 [^6]      64
   1 FSSEL1 [^6]     128
   1 FSSEL_0 [^6]       0
   1 FSSEL_1 [^6]      64
   1 FSSEL_2 [^6]     128
   1 FSSEL_3 [^6]     192
   1 FCTL3 [^17]     300
   1 BUSY [^6]       1
   1 KEYV [^6]       2
   1 ACCVIFG [^6]       4
   1 WAIT [^6]       8
   1 LOCK [^6]      16
   1 EMEX [^6]      32
   1 LOCKA [^6]      64
   1 FAIL [^6]     128
   1 P1IN [^18]      32
   1 P1OUT [^18]      33
   1 P1DIR [^18]      34
   1 P1IFG [^18]      35
   1 P1IES [^18]      36
   1 P1IE [^18]      37
   1 P1SEL [^18]      38
   1 P1SEL2 [^18]      65
   1 P1REN [^18]      39
   1 P2IN [^18]      40
   1 P2OUT [^18]      41
   1 P2DIR [^18]      42
   1 P2IFG [^18]      43
   1 P2IES [^18]      44
   1 P2IE [^18]      45
   1 P2SEL [^18]      46
   1 P2SEL2 [^18]      66
   1 P2REN [^18]      47
   1 P3IN [^18]      24
   1 P3OUT [^18]      25
   1 P3DIR [^18]      26
   1 P3SEL [^18]      27
   1 P3SEL2 [^18]      67
   1 P3REN [^18]      16
   1 TA0IV [^7]     302
   1 TA0IV_NONE [^4]       0
   1 TA0IV_TACCR1 [^4]       2
   1 TA0IV_TACCR2 [^4]       4
   1 TA0IV_6 [^4]       6
   1 TA0IV_8 [^4]       8
   1 TA0IV_TAIFG [^4]      10
   1 TA0CTL [^17]     352
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
   1 TA0CCTL0 [^17]     354
   1 TA0CCTL1 [^17]     356
   1 TA0CCTL2 [^17]     358
   1 CM1 [^6]   32768
   1 CM0 [^6]   16384
   1 CCIS1 [^6]    8192
   1 CCIS0 [^6]    4096
   1 SCS [^6]    2048
   1 SCCI [^6]    1024
   1 CAP [^6]     256
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
   1 TA1IV [^17]     286
   1 TA1CTL [^17]     384
   1 TA1CCTL0 [^17]     386
   1 TA1CCTL1 [^17]     388
   1 TA1CCTL2 [^17]     390
   1 TA1R [^7]     400
   1 TA1CCR0 [^7]     402
   1 TA1CCR1 [^7]     404
   1 TA1CCR2 [^7]     406
   1 UCA0CTL0 [^18]      96
   1 UCPEN [^6]     128
   1 UCPAR [^6]      64
   1 UCMSB [^6]      32
   1 UC7BIT [^6]      16
   1 UCSPB [^6]       8
   1 UCMODE1 [^6]       4
   1 UCMODE0 [^6]       2
   1 UCSYNC [^6]       1
   1 UCCKPH [^6]     128
   1 UCCKPL [^6]      64
   1 UCMST [^6]       8
   1 UCMODE_0 [^6]       0
   1 UCMODE_1 [^6]       2
   1 UCMODE_2 [^6]       4
   1 UCMODE_3 [^6]       6
   1 UCA0CTL1 [^18]      97
   1 UCSSEL1 [^6]     128
   1 UCSSEL0 [^6]      64
   1 UCRXEIE [^6]      32
   1 UCBRKIE [^6]      16
   1 UCDORM [^6]       8
   1 UCTXADDR [^6]       4
   1 UCTXBRK [^6]       2
   1 UCSWRST [^6]       1
   1 UCSSEL_0 [^6]       0
   1 UCSSEL_1 [^6]      64
   1 UCSSEL_2 [^6]     128
   1 UCSSEL_3 [^6]     192
   1 UCA0BR0 [^14]      98
   1 UCA0BR1 [^14]      99
   1 UCA0MCTL [^18]     100
   1 UCBRF3 [^6]     128
   1 UCBRF2 [^6]      64
   1 UCBRF1 [^6]      32
   1 UCBRF0 [^6]      16
   1 UCBRS2 [^6]       8
   1 UCBRS1 [^6]       4
   1 UCBRS0 [^6]       2
   1 UCOS16 [^6]       1
   1 UCBRF_0 [^6]       0
   1 UCBRF_1 [^6]      16
   1 UCBRF_2 [^6]      32
   1 UCBRF_3 [^6]      48
   1 UCBRF_4 [^6]      64
   1 UCBRF_5 [^6]      80
   1 UCBRF_6 [^6]      96
   1 UCBRF_7 [^6]     112
   1 UCBRF_8 [^6]     128
   1 UCBRF_9 [^6]     144
   1 UCBRF_10 [^6]     160
   1 UCBRF_11 [^6]     176
   1 UCBRF_12 [^6]     192
   1 UCBRF_13 [^6]     208
   1 UCBRF_14 [^6]     224
   1 UCBRF_15 [^6]     240
   1 UCBRS_0 [^6]       0
   1 UCBRS_1 [^6]       2
   1 UCBRS_2 [^6]       4
   1 UCBRS_3 [^6]       6
   1 UCBRS_4 [^6]       8
   1 UCBRS_5 [^6]      10
   1 UCBRS_6 [^6]      12
   1 UCBRS_7 [^6]      14
   1 UCA0STAT [^18]     101
   1 UCLISTEN [^6]     128
   1 UCFE [^6]      64
   1 UCOE [^6]      32
   1 UCPE [^6]      16
   1 UCBRK [^6]       8
   1 UCRXERR [^6]       4
   1 UCADDR [^6]       2
   1 UCBUSY [^6]       1
   1 UCIDLE [^6]       2
   1 UCA0RXBUF [^14]     102
   1 UCA0TXBUF [^14]     103
   1 UCA0ABCTL [^18]      93
   1 UCDELIM1 [^6]      32
   1 UCDELIM0 [^6]      16
   1 UCSTOE [^6]       8
   1 UCBTOE [^6]       4
   1 UCABDEN [^6]       1
   1 UCA0IRTCTL [^18]      94
   1 UCIRTXPL5 [^6]     128
   1 UCIRTXPL4 [^6]      64
   1 UCIRTXPL3 [^6]      32
   1 UCIRTXPL2 [^6]      16
   1 UCIRTXPL1 [^6]       8
   1 UCIRTXPL0 [^6]       4
   1 UCIRTXCLK [^6]       2
   1 UCIREN [^6]       1
   1 UCA0IRRCTL [^18]      95
   1 UCIRRXFL5 [^6]     128
   1 UCIRRXFL4 [^6]      64
   1 UCIRRXFL3 [^6]      32
   1 UCIRRXFL2 [^6]      16
   1 UCIRRXFL1 [^6]       8
   1 UCIRRXFL0 [^6]       4
   1 UCIRRXPL [^6]       2
   1 UCIRRXFE [^6]       1
   1 UCB0CTL0 [^18]     104
   1 UCA10 [^6]     128
   1 UCSLA10 [^6]      64
   1 UCMM [^6]      32
   1 UCB0CTL1 [^18]     105
   1 UCTR [^6]      16
   1 UCTXNACK [^6]       8
   1 UCTXSTP [^6]       4
   1 UCTXSTT [^6]       2
   1 UCB0BR0 [^14]     106
   1 UCB0BR1 [^14]     107
   1 UCB0I2CIE [^18]     108
   1 UCNACKIE [^6]       8
   1 UCSTPIE [^6]       4
   1 UCSTTIE [^6]       2
   1 UCALIE [^6]       1
   1 UCB0STAT [^18]     109
   1 UCSCLLOW [^6]      64
   1 UCGC [^6]      32
   1 UCBBUSY [^6]      16
   1 UCNACKIFG [^6]       8
   1 UCSTPIFG [^6]       4
   1 UCSTTIFG [^6]       2
   1 UCALIFG [^6]       1
   1 UCB0RXBUF [^14]     110
   1 UCB0TXBUF [^14]     111
   1 UCB0I2COA [^17]     280
   1 UCGCEN [^6]   32768
   1 UCB0I2CSA [^7]     282
   1 WDTCTL [^17]     288
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
   1 CALDCO_16MHZ [^18]    4344
   1 CALBC1_16MHZ [^18]    4345
   1 CALDCO_12MHZ [^18]    4346
   1 CALBC1_12MHZ [^18]    4347
   1 CALDCO_8MHZ [^18]    4348
   1 CALBC1_8MHZ [^18]    4349
   1 CALDCO_1MHZ [^18]    4350
   1 CALBC1_1MHZ [^18]    4351
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
