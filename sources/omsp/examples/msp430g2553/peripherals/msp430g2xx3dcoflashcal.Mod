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
//  MSP430G2xx3 Demo - DCO Calibration Constants Programmer
//
//  NOTE: THIS CODE REPLACES THE TI FACTORY-PROGRAMMED DCO CALIBRATION
//  CONSTANTS LOCATED IN INFOA WITH NEW VALUES. USE ONLY IF THE ORIGINAL
//  CONSTANTS ACCIDENTALLY GOT CORRUPTED OR ERASED.
//
//  Description: This code re-programs the G2xx2 DCO calibration constants.
//  A software FLL mechanism is used to set the DCO based on an external
//  32kHz reference clock. After each calibration, the values from the
//  clock system are read out and stored in a temporary variable. The final
//  frequency the DCO is set to is 1MHz, and this frequency is also used
//  during Flash programming of the constants. The program end is indicated
//  by the blinking LED.
//  ACLK = LFXT1/8 = 32768/8, MCLK = SMCLK = target DCO
//  //* External watch crystal installed on XIN XOUT is required for ACLK *//
//
//           MSP430G2xx3
//         ---------------
//     /|\|            XIN|-
//      | |               | 32kHz
//      --|RST        XOUT|-
//        |               |
//        |           P1.0|--> LED
//        |           P1.4|--> SMLCK = target DCO
//
//  D. Dang
//  Texas Instruments Inc.
//  May 2010
// C. Schoffit 20.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3dcoflashcal;
  IMPORT SYSTEM, M := msp430g2553;

  CONST
    DELTA_1MHZ = 244; (* 244 x 4096Hz = 999.4Hz *)
    DELTA_8MHZ = 1953; (* 1953 x 4096Hz = 7.99MHz *)
    DELTA_12MHZ = 2930; (* 2930 x 4096Hz = 12.00MHz *)
    DELTA_16MHZ = 3906; (* 3906 x 4096Hz = 15.99MHz *)


  VAR
    CAL_DATA: ARRAY 8 OF BYTESET; (* Temp. storage for constants *)
    i, j: INTEGER;
    Flash_ptrA:  PBYTESET; (* Segment A pointer *)

  PROCEDURE Set_DCO(Delta: INTEGER); (* Set DCO to selected frequency *)
    VAR Compare, Oldcapture: INTEGER;
  BEGIN
    Oldcapture := 0;

    BIS(M.BCSCTL1^, M.DIVA_3); (* ACLK = LFXT1CLK/8 *)
    M.TA0CCTL0^ := M.CM_1 + M.CCIS_1 + M.CAP; (* CAP, ACLK *)
    M.TA0CTL^ := M.TASSEL_2 + M.MC_2 + M.TACLR; (* SMCLK, cont-mode, clear *)

    REPEAT
      REPEAT UNTIL BIT(M.CCIFG, M.TA0CCTL0^); (* Wait until capture occured *)
      BIC(M.TA0CCTL0^, M.CCIFG); (* Capture occured, clear flag *)
      Compare := M.TA0CCR0^; (* Get current captured SMCLK *)
      DEC(Compare, Oldcapture); (* SMCLK difference *)
      Oldcapture := M.TA0CCR0^; (* Save current captured SMCLK *)

      IF Delta < Compare THEN
        DEC(ORD(M.DCOCTL^)); (* DCO is too fast, slow it down *)
        IF (M.DCOCTL^ = {0..7}) (* Did DCO roll under? *) & (M.BCSCTL1^*{0..3} # {}) THEN
          DEC(ORD(M.BCSCTL1^)) (* Select lower RSEL *)
        END
      ELSIF Delta > Compare THEN
        INC(ORD(M.DCOCTL^)); (* DCO is too slow, speed it up *)
        IF (M.DCOCTL^ = {}) (* Did DCO roll over? *) & (M.BCSCTL1^*{0..3} # {0..3}) THEN
          INC(ORD(M.BCSCTL1^)); (* Sel higher RSEL *)
        END
      END
    UNTIL  Delta = Compare;
    M.TA0CCTL0^ := {}; (* Stop TACCR0 *)
    M.TA0CTL^ := {}; (* Stop Timer_A *)
    BIC(M.BCSCTL1^, M.DIVA_3) (* ACLK = LFXT1CLK *)
  END Set_DCO;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)
  i := 0FFFEH; REPEAT DEC(i) UNTIL i = 0; (* Delay for XTAL stabilization *)
  M.P1OUT^ := {}; (* Clear P1 output latches *)
  M.P1SEL^ := {4}; (* P1.4 SMCLK output *)
  M.P1DIR^ := {0, 4}; (* P1.0,4 output *)

  j := 0; (* Reset pointer *)

  Set_DCO(DELTA_16MHZ); (* Set DCO and obtain constants *)
  CAL_DATA[j] := M.DCOCTL^; INC(j);
  CAL_DATA[j] := M.BCSCTL1^; INC(j);

  Set_DCO(DELTA_12MHZ); (* Set DCO and obtain constants *)
  CAL_DATA[j] := M.DCOCTL^; INC(j);
  CAL_DATA[j] := M.BCSCTL1^; INC(j);

  Set_DCO(DELTA_8MHZ); (* Set DCO and obtain constants *)
  CAL_DATA[j] := M.DCOCTL^; INC(j);
  CAL_DATA[j] := M.BCSCTL1^; INC(j);

  Set_DCO(DELTA_1MHZ); (* Set DCO and obtain constants *)
  CAL_DATA[j] := M.DCOCTL^; INC(j);
  CAL_DATA[j] := M.BCSCTL1^; INC(j);

  Flash_ptrA := SYSTEM.VAL(PBYTESET, 10C0H); (* Segment A pointer *)
  M.FCTL2^ := M.FWKEY + M.FSSEL0 + M.FN1; (* MCLK/3 for Flash Timing Generator *)
  M.FCTL1^ := M.FWKEY + M.ERASE; (* Set Erase bit *)
  M.FCTL3^ := M.FWKEY + M.LOCKA; (* Clear LOCK & LOCKA bits *)
  Flash_ptrA^ := {}; (* Dummy write to erase Flash seg A *)
  M.FCTL1^ := M.FWKEY + M.WRT; (* Set WRT bit for write operation *)
  Flash_ptrA := SYSTEM.VAL(PBYTESET, 10F8H); (* Point to beginning of cal consts *)
  FOR j := 0 TO 7 DO Flash_ptrA^ := CAL_DATA[j]; INC(ORD(Flash_ptrA)) END; (* re-flash DCO calibration data *)
  M.FCTL1^ := M.FWKEY; (* Clear WRT bit *)
  M.FCTL3^ := M.FWKEY + M.LOCKA + M.LOCK; (* Set LOCK & LOCKA bit *)

  REPEAT
    XOR(M.P1OUT^, {0}); (* Toggle LED*)
    i := 4000H; REPEAT DEC(i) UNTIL i = 0; (* SW Delay *)
  UNTIL FALSE
END msp430g2xx3dcoflashcal.

OMSPTool.DecObj msp430g2xx3dcoflashcal.mpc
decode msp430g2xx3dcoflashcal.mpc
msp430g2xx3dcoflashcal 61060AFE Flash   494
imports:
	msp430g2553 F10488DC
type descriptors

data    14
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0094
fixup procedures chains
 014E     0	 0000
fixup handlers chains
fixup data chains
 01E6     0	 0008
 01C6     0	 000A
 01BA     0	 0000
 01C2     0	 000C
fixup constants chains
fixup types chains
entry =  0094
code   494
 0000	     8221	SUB #4,SP
 0002	     4381	MOV #0,2(SP)
 0004	     0002
 0006	     D0F2	BIS.B #48,&87
 0008	     0030
 000A	     0057
 000C	     40B2	MOV #20736,&354
 000E	     5100
 0010	     0162
 0012	     40B2	MOV #548,&352
 0014	     0224
 0016	     0160
 0018	     431F	MOV #1,R15
 001A	     B21F	BIT &354,R15
 001C	     0162
 001E	     27FC	JEQ $-6, goes to  0018
 0020	     C392	BIC #1,&354
 0022	     0162
 0024	     4291	MOV &370,0(SP)
 0026	     0172
 0028	     0000
 002A	     8191	SUB 2(SP),0(SP)
 002C	     0002
 002E	     0000
 0030	     4291	MOV &370,2(SP)
 0032	     0172
 0034	     0002
 0036	     91A1	CMP @SP,6(SP)
 0038	     0006
 003A	     340E	JGE $+30, goes to  0058
 003C	     83D2	SUB.B #1,&86
 003E	     0056
 0040	     93F2	CMP.B #-1,&86
 0042	     0056
 0044	     2008	JNE $+18, goes to  0056
 0046	     425F	MOV.B &87,R15
 0048	     0057
 004A	     F07F	AND.B #15,R15
 004C	     000F
 004E	     934F	CMP.B #0,R15
 0050	     2402	JEQ $+6, goes to  0056
 0052	     83D2	SUB.B #1,&87
 0054	     0057
 0056	     3C12	JMP $+38, goes to  007C
 0058	     9191	CMP 6(SP),0(SP)
 005A	     0006
 005C	     0000
 005E	     340E	JGE $+30, goes to  007C
 0060	     53D2	ADD.B #1,&86
 0062	     0056
 0064	     93C2	CMP.B #0,&86
 0066	     0056
 0068	     2009	JNE $+20, goes to  007C
 006A	     425F	MOV.B &87,R15
 006C	     0057
 006E	     F07F	AND.B #15,R15
 0070	     000F
 0072	     907F	CMP.B #15,R15
 0074	     000F
 0076	     2402	JEQ $+6, goes to  007C
 0078	     53D2	ADD.B #1,&87
 007A	     0057
 007C	     91A1	CMP @SP,6(SP)
 007E	     0006
 0080	     23CB	JNE $-104, goes to  0018
 0082	     4382	MOV #0,&354
 0084	     0162
 0086	     4382	MOV #0,&352
 0088	     0160
 008A	     C0F2	BIC.B #48,&87
 008C	     0030
 008E	     0057
 0090	     5221	ADD #4,SP
 0092	     4130	RET
 0094	     40B2	MOV #23168,&288
 0096	     5A80
 0098	     0120
 009A	     40B2	MOV #-2,&0
 009C	     FFFE
 009E	     0000
 00A0	     8392	SUB #1,&158
 00A2	     009E
 00A4	     9382	CMP #0,&162
 00A6	     00A2
 00A8	     23FB	JNE $-8, goes to  00A0
 00AA	     43C2	MOV.B #0,&33
 00AC	     0021
 00AE	     40F2	MOV.B #16,&38
 00B0	     0010
 00B2	     0026
 00B4	     40F2	MOV.B #17,&34
 00B6	     0011
 00B8	     0022
 00BA	     4382	MOV #0,&0
 00BC	     0000
 00BE	     1230	PUSH #3906
 00C0	     0F42
 00C2	     12B0	CALL #0
 00C4	     0000
 00C6	     5321	ADD #2,SP
 00C8	     421F	MOV &188,R15
 00CA	     00BC
 00CC	     503F	ADD #0,R15
 00CE	     0000
 00D0	     42DF	MOV.B &86,0(R15)
 00D2	     0056
 00D4	     0000
 00D6	     5392	ADD #1,&202
 00D8	     00CA
 00DA	     421F	MOV &216,R15
 00DC	     00D8
 00DE	     503F	ADD #206,R15
 00E0	     00CE
 00E2	     42DF	MOV.B &87,0(R15)
 00E4	     0057
 00E6	     0000
 00E8	     5392	ADD #1,&220
 00EA	     00DC
 00EC	     1230	PUSH #2930
 00EE	     0B72
 00F0	     12B0	CALL #196
 00F2	     00C4
 00F4	     5321	ADD #2,SP
 00F6	     421F	MOV &234,R15
 00F8	     00EA
 00FA	     503F	ADD #224,R15
 00FC	     00E0
 00FE	     42DF	MOV.B &86,0(R15)
 0100	     0056
 0102	     0000
 0104	     5392	ADD #1,&248
 0106	     00F8
 0108	     421F	MOV &262,R15
 010A	     0106
 010C	     503F	ADD #252,R15
 010E	     00FC
 0110	     42DF	MOV.B &87,0(R15)
 0112	     0057
 0114	     0000
 0116	     5392	ADD #1,&266
 0118	     010A
 011A	     1230	PUSH #1953
 011C	     07A1
 011E	     12B0	CALL #242
 0120	     00F2
 0122	     5321	ADD #2,SP
 0124	     421F	MOV &280,R15
 0126	     0118
 0128	     503F	ADD #270,R15
 012A	     010E
 012C	     42DF	MOV.B &86,0(R15)
 012E	     0056
 0130	     0000
 0132	     5392	ADD #1,&294
 0134	     0126
 0136	     421F	MOV &308,R15
 0138	     0134
 013A	     503F	ADD #298,R15
 013C	     012A
 013E	     42DF	MOV.B &87,0(R15)
 0140	     0057
 0142	     0000
 0144	     5392	ADD #1,&312
 0146	     0138
 0148	     1230	PUSH #244
 014A	     00F4
 014C	     12B0	CALL #288
 014E	     0120
 0150	     5321	ADD #2,SP
 0152	     421F	MOV &326,R15
 0154	     0146
 0156	     503F	ADD #316,R15
 0158	     013C
 015A	     42DF	MOV.B &86,0(R15)
 015C	     0056
 015E	     0000
 0160	     5392	ADD #1,&340
 0162	     0154
 0164	     421F	MOV &354,R15
 0166	     0162
 0168	     503F	ADD #344,R15
 016A	     0158
 016C	     42DF	MOV.B &87,0(R15)
 016E	     0057
 0170	     0000
 0172	     5392	ADD #1,&358
 0174	     0166
 0176	     40B2	MOV #4288,&0
 0178	     10C0
 017A	     0000
 017C	     40B2	MOV #-23230,&298
 017E	     A542
 0180	     012A
 0182	     40B2	MOV #-23294,&296
 0184	     A502
 0186	     0128
 0188	     40B2	MOV #-23232,&300
 018A	     A540
 018C	     012C
 018E	     421F	MOV &378,R15
 0190	     017A
 0192	     43CF	MOV.B #0,0(R15)
 0194	     0000
 0196	     40B2	MOV #-23232,&296
 0198	     A540
 019A	     0128
 019C	     40B2	MOV #4344,&400
 019E	     10F8
 01A0	     0190
 01A2	     4382	MOV #0,&372
 01A4	     0174
 01A6	     403F	MOV #7,R15
 01A8	     0007
 01AA	     921F	CMP &420,R15
 01AC	     01A4
 01AE	     380D	JL $+28, goes to  01CA
 01B0	     421F	MOV &416,R15
 01B2	     01A0
 01B4	     421E	MOV &428,R14
 01B6	     01AC
 01B8	     503E	ADD #362,R14
 01BA	     016A
 01BC	     4EEF	MOV.B @R14,0(R15)
 01BE	     0000
 01C0	     5392	ADD #1,&434
 01C2	     01B2
 01C4	     5392	ADD #1,&438
 01C6	     01B6
 01C8	     3FEE	JMP $-34, goes to  01A6
 01CA	     40B2	MOV #-23296,&296
 01CC	     A500
 01CE	     0128
 01D0	     40B2	MOV #-23216,&300
 01D2	     A550
 01D4	     012C
 01D6	     E3D2	XOR.B #1,&33
 01D8	     0021
 01DA	     40B2	MOV #16384,&166
 01DC	     4000
 01DE	     00A6
 01E0	     8392	SUB #1,&478
 01E2	     01DE
 01E4	     9382	CMP #0,&482
 01E6	     01E2
 01E8	     23FB	JNE $-8, goes to  01E0
 01EA	     3FF5	JMP $-20, goes to  01D6
 01EC	     4130	RET
