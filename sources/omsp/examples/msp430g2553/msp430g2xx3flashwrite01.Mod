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
//  MSP430G2xx3 Demo - Flash In-System Programming, Copy SegC to SegD
//
//  Description: This program first erases flash seg C, then it increments all
//  values in seg C, then it erases seg D, then copies seg C to seg D.
//  Assumed MCLK 771kHz - 1428kHz.
//  //* Set Breakpoint on NOP in the Mainloop to avoid Stressing Flash *//
//
//               MSP430G2xx3
//            -----------------
//        /|\|              XIN|-
//         | |                 |
//         --|RST          XOUT|-
//           |                 |
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit 25.09.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3flashwrite01;
  IMPORT SYSTEM, M := msp430g2553;

  VAR value: BYTE; (* 8-bit value to write to segment A *)

  PROCEDURE write_SegC(value: BYTE*);
    VAR Flash_ptr!: PBYTE*; (* Flash pointer *)
      i: INTEGER*;
  BEGIN
    Flash_ptr := SYSTEM.VAL(PBYTE, 1040H); (* Initialize Flash pointer *)
    M.FCTL1^ := M.FWKEY + M.ERASE; (* Set Erase bit *)
    M.FCTL3^ := M.FWKEY; (* Clear Lock bit *)
    Flash_ptr^ := 0; (* Dummy write to erase Flash segment *)

    M.FCTL1^ := M.FWKEY + M.WRT; (* Set WRT bit for write operation *)

    i := 64; REPEAT DEC(i); Flash_ptr^ := value; INC(ORD(Flash_ptr)) UNTIL i = 0; (* Write value to flash *)

    M.FCTL1^ := M.FWKEY; (* Clear WRT bit *)
    M.FCTL3^ := M.FWKEY + M.LOCK (* Set LOCK bit *)
  END write_SegC;

(* Original version:
  PROCEDURE copy_C2D;
    VAR Flash_ptrC! (* Segment C pointer *), Flash_ptrD! (* Segment D pointer *): PBYTE*;
    i: INTEGER*;
  BEGIN
    Flash_ptrC := SYSTEM.VAL(PBYTE, 1040H); (* Initialize Flash segment C pointer *)
    Flash_ptrD := SYSTEM.VAL(PBYTE, 1000H); (* Initialize Flash segment D pointer *)
    M.FCTL1^ := M.FWKEY + M.ERASE; (* Set Erase bit *)
    M.FCTL3^ := M.FWKEY; (* Clear Lock bit *)
    Flash_ptrD^ := 0; (* Dummy write to erase Flash segment D *)
    M.FCTL1^ := M.FWKEY + M.WRT; (* Set WRT bit for write operation *)

    i := 64; REPEAT DEC(i); Flash_ptrD^ := Flash_ptrC^; INC(ORD(Flash_ptrD)); INC(ORD(Flash_ptrC)) UNTIL i = 0;

    M.FCTL1^ := M.FWKEY; (* Clear WRT bit *)
    M.FCTL3^ := M.FWKEY + M.LOCK; (* Set LOCK bit *)
  END copy_C2D;*)

  (* Improved version *)
  PROCEDURE copy_C2D;
    CONST Flash_ptrC = SYSTEM.VAL(PINTEGER, 1040H); (* Segment C pointer *)
      Flash_ptrD = SYSTEM.VAL(PINTEGER, 1000H); (* Segment D pointer *)
  BEGIN
    M.FCTL1^ := M.FWKEY + M.ERASE; (* Set Erase bit *)
    M.FCTL3^ := M.FWKEY; (* Clear Lock bit *)
    Flash_ptrD^ := 0; (* Dummy write to erase Flash segment D *)
    M.FCTL1^ := M.FWKEY + M.WRT; (* Set WRT bit for write operation *)

    SYSTEM.COPY(ORD(Flash_ptrC), ORD(Flash_ptrD), 32);

    M.FCTL1^ := M.FWKEY; (* Clear WRT bit *)
    M.FCTL3^ := M.FWKEY + M.LOCK; (* Set LOCK bit *)
  END copy_C2D;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  REPEAT UNTIL M.CALBC1_1MHZ^ # {0..7}; (* If calibration constant erased do not load, trap CPU!! *)
  M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
  M.BCSCTL1^ := M.CALBC1_1MHZ^; (* Set DCO to 1MHz *)
  M.DCOCTL^ := M.CALDCO_1MHZ^;
  M.FCTL2^ := M.FWKEY + M.FSSEL0 + M.FN1; (* MCLK/3 for Flash Timing Generator *)
  value := 0; (* initialize value *)

  REPEAT write_SegC(value); INC(value); (* Write segment C, increment value *)
    copy_C2D(); (* Copy segment C to D *)
   NOP; (* SET BREAKPOINT HERE *)
  UNTIL FALSE (* Repeat forever *)
END msp430g2xx3flashwrite01.

OMSPTool.DecObj msp430g2xx3flashwrite01.mpc
decode msp430g2xx3flashwrite01.mpc
msp430g2xx3flashwrite01 782D7E90 Flash   174
imports:
	msp430g2553 AFE820A5
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0072
fixup procedures chains
 009E     0	 0000
 00A6     0	 0038
fixup handlers chains
fixup data chains
 00A2     0	 0000
fixup constants chains
fixup types chains
entry =  0072
code   174
 0000	     4035	MOV #4160,R5
 0002	     1040
 0004	     40B2	MOV #-23294,&296
 0006	     A502
 0008	     0128
 000A	     40B2	MOV #-23296,&300
 000C	     A500
 000E	     012C
 0010	     43C5	MOV.B #0,0(R5)
 0012	     0000
 0014	     40B2	MOV #-23232,&296
 0016	     A540
 0018	     0128
 001A	     4036	MOV #64,R6
 001C	     0040
 001E	     8316	SUB #1,R6
 0020	     44C5	MOV.B R4,0(R5)
 0022	     0000
 0024	     5315	ADD #1,R5
 0026	     9306	CMP #0,R6
 0028	     23FA	JNE $-10, goes to  001E
 002A	     40B2	MOV #-23296,&296
 002C	     A500
 002E	     0128
 0030	     40B2	MOV #-23280,&300
 0032	     A510
 0034	     012C
 0036	     4130	RET
 0038	     40B2	MOV #-23294,&296
 003A	     A502
 003C	     0128
 003E	     40B2	MOV #-23296,&300
 0040	     A500
 0042	     012C
 0044	     4382	MOV #0,&4096
 0046	     1000
 0048	     40B2	MOV #-23232,&296
 004A	     A540
 004C	     0128
 004E	     403F	MOV #32,R15
 0050	     0020
 0052	     403E	MOV #4160,R14
 0054	     1040
 0056	     403D	MOV #4096,R13
 0058	     1000
 005A	     4EBD	MOV @R14+,0(R13)
 005C	     0000
 005E	     532D	ADD #2,R13
 0060	     831F	SUB #1,R15
 0062	     23FB	JNE $-8, goes to  005A
 0064	     40B2	MOV #-23296,&296
 0066	     A500
 0068	     0128
 006A	     40B2	MOV #-23280,&300
 006C	     A510
 006E	     012C
 0070	     4130	RET
 0072	     40B2	MOV #23168,&288
 0074	     5A80
 0076	     0120
 0078	     93F2	CMP.B #-1,&4351
 007A	     10FF
 007C	     27FD	JEQ $-4, goes to  0078
 007E	     43C2	MOV.B #0,&86
 0080	     0056
 0082	     42D2	MOV.B &4351,&87
 0084	     10FF
 0086	     0057
 0088	     42D2	MOV.B &4350,&86
 008A	     10FE
 008C	     0056
 008E	     40B2	MOV #-23230,&298
 0090	     A542
 0092	     012A
 0094	     43C2	MOV.B #0,&0
 0096	     0000
 0098	     4254	MOV.B &150,R4
 009A	     0096
 009C	     12B0	CALL #0
 009E	     0000
 00A0	     53D2	ADD.B #1,&154
 00A2	     009A
 00A4	     12B0	CALL #0
 00A6	     0000
 00A8	     4303	NOP
 00AA	     3FF6	JMP $-18, goes to  0098
 00AC	     4130	RET
