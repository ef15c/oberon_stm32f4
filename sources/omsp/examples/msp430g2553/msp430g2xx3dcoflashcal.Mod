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
msp430g2xx3dcoflashcal 61060AFE Flash   512
imports:
	msp430g2553 A54A24F2
type descriptors

data    14
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0094
fixup procedures chains
 015A     0	 0000
fixup handlers chains
fixup data chains
 01F8     0	 0008
 01D8     0	 000A
 01CA     0	 0000
 01D4     0	 000C
fixup constants chains
fixup types chains
entry =  0094
code   512
 0000	     8221	SUB #4,SP
 0002	     4381	MOV #0,2(SP)
 0004	     0002
 0006	     D0F2	BIS.B #48,&87
 0008	     0030
 000A	     0057
 000C	     40B2	MOV #20992,&354
 000E	     5200
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
 00CC	     403E	MOV #0,R14
 00CE	     0000
 00D0	     5E0F	ADD R14,R15
 00D2	     42DF	MOV.B &86,0(R15)
 00D4	     0056
 00D6	     0000
 00D8	     5392	ADD #1,&202
 00DA	     00CA
 00DC	     421F	MOV &218,R15
 00DE	     00DA
 00E0	     403E	MOV #206,R14
 00E2	     00CE
 00E4	     5E0F	ADD R14,R15
 00E6	     42DF	MOV.B &87,0(R15)
 00E8	     0057
 00EA	     0000
 00EC	     5392	ADD #1,&222
 00EE	     00DE
 00F0	     1230	PUSH #2930
 00F2	     0B72
 00F4	     12B0	CALL #196
 00F6	     00C4
 00F8	     5321	ADD #2,SP
 00FA	     421F	MOV &238,R15
 00FC	     00EE
 00FE	     403E	MOV #226,R14
 0100	     00E2
 0102	     5E0F	ADD R14,R15
 0104	     42DF	MOV.B &86,0(R15)
 0106	     0056
 0108	     0000
 010A	     5392	ADD #1,&252
 010C	     00FC
 010E	     421F	MOV &268,R15
 0110	     010C
 0112	     403E	MOV #256,R14
 0114	     0100
 0116	     5E0F	ADD R14,R15
 0118	     42DF	MOV.B &87,0(R15)
 011A	     0057
 011C	     0000
 011E	     5392	ADD #1,&272
 0120	     0110
 0122	     1230	PUSH #1953
 0124	     07A1
 0126	     12B0	CALL #246
 0128	     00F6
 012A	     5321	ADD #2,SP
 012C	     421F	MOV &288,R15
 012E	     0120
 0130	     403E	MOV #276,R14
 0132	     0114
 0134	     5E0F	ADD R14,R15
 0136	     42DF	MOV.B &86,0(R15)
 0138	     0056
 013A	     0000
 013C	     5392	ADD #1,&302
 013E	     012E
 0140	     421F	MOV &318,R15
 0142	     013E
 0144	     403E	MOV #306,R14
 0146	     0132
 0148	     5E0F	ADD R14,R15
 014A	     42DF	MOV.B &87,0(R15)
 014C	     0057
 014E	     0000
 0150	     5392	ADD #1,&322
 0152	     0142
 0154	     1230	PUSH #244
 0156	     00F4
 0158	     12B0	CALL #296
 015A	     0128
 015C	     5321	ADD #2,SP
 015E	     421F	MOV &338,R15
 0160	     0152
 0162	     403E	MOV #326,R14
 0164	     0146
 0166	     5E0F	ADD R14,R15
 0168	     42DF	MOV.B &86,0(R15)
 016A	     0056
 016C	     0000
 016E	     5392	ADD #1,&352
 0170	     0160
 0172	     421F	MOV &368,R15
 0174	     0170
 0176	     403E	MOV #356,R14
 0178	     0164
 017A	     5E0F	ADD R14,R15
 017C	     42DF	MOV.B &87,0(R15)
 017E	     0057
 0180	     0000
 0182	     5392	ADD #1,&372
 0184	     0174
 0186	     40B2	MOV #4288,&0
 0188	     10C0
 018A	     0000
 018C	     40B2	MOV #-23230,&298
 018E	     A542
 0190	     012A
 0192	     40B2	MOV #-23294,&296
 0194	     A502
 0196	     0128
 0198	     40B2	MOV #-23232,&300
 019A	     A540
 019C	     012C
 019E	     421F	MOV &394,R15
 01A0	     018A
 01A2	     43CF	MOV.B #0,0(R15)
 01A4	     0000
 01A6	     40B2	MOV #-23232,&296
 01A8	     A540
 01AA	     0128
 01AC	     40B2	MOV #4344,&416
 01AE	     10F8
 01B0	     01A0
 01B2	     4382	MOV #0,&388
 01B4	     0184
 01B6	     403F	MOV #7,R15
 01B8	     0007
 01BA	     921F	CMP &436,R15
 01BC	     01B4
 01BE	     380E	JL $+30, goes to  01DC
 01C0	     421F	MOV &432,R15
 01C2	     01B0
 01C4	     421E	MOV &444,R14
 01C6	     01BC
 01C8	     403D	MOV #376,R13
 01CA	     0178
 01CC	     5D0E	ADD R13,R14
 01CE	     4EEF	MOV.B @R14,0(R15)
 01D0	     0000
 01D2	     5392	ADD #1,&450
 01D4	     01C2
 01D6	     5392	ADD #1,&454
 01D8	     01C6
 01DA	     3FED	JMP $-36, goes to  01B6
 01DC	     40B2	MOV #-23296,&296
 01DE	     A500
 01E0	     0128
 01E2	     40B2	MOV #-23216,&300
 01E4	     A550
 01E6	     012C
 01E8	     E3D2	XOR.B #1,&33
 01EA	     0021
 01EC	     40B2	MOV #16384,&166
 01EE	     4000
 01F0	     00A6
 01F2	     8392	SUB #1,&496
 01F4	     01F0
 01F6	     9382	CMP #0,&500
 01F8	     01F4
 01FA	     23FB	JNE $-8, goes to  01F2
 01FC	     3FF5	JMP $-20, goes to  01E8
 01FE	     4130	RET
