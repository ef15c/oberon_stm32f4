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
//   MSP430G2xx3 Demo - Reset on Invalid Address fetch, Toggle P1.0
//
//  Description: Toggle P1.0 by xor'ing P1.0 inside of a software loop that
//  ends with TAR loaded with 3FFFh - op-code for "jmp $" This simulates a code
//  error. The MSP430F21x1 will force a reset because it will not allow a fetch
//  from within the address range of the peripheral memory, as is seen by
//  return to the mainloop and LED flash.
//  In contrast, an MSP430F1xx device will "jmp $" stopping code execution with
//  no LED flash.
//  ACLK = n/a, MCLK = SMCLK = default DCO
//
//                MSP430G2xx3
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//            |             P1.0|-->LED
//
//  D. Dang
//  Texas Instruments Inc.
//  December 2010
//  C. Schoffit, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3wdt05;
  IMPORT SYSTEM, M := msp430g2553, Types;

  CONST dummy = SYSTEM.VAL(Types.procedure, M.TA0R);

  VAR i: INTEGER;
BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  BIS(M.P1DIR^, {0}); (* Set P1.0 to output direction *)
  M.TA0R^ := 3FFFH; (* Opcode for "jmp $" *)

  REPEAT
    XOR(M.P1OUT^, {0}); (* Toggle P1.0 using exclusive-OR *)

    i := 50000; (* Delay *)
    REPEAT DEC(i) UNTIL i = 0;
    dummy
  UNTIL FALSE
END msp430g2xx3wdt05.

OMSPTool.DecObj msp430g2xx3wdt05.mpc
decode msp430g2xx3wdt05.mpc
msp430g2xx3wdt05 5E015924 Flash    44
imports:
	msp430g2553 F10488DC
	Types E8A91E57
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0000
fixup procedures chains
fixup handlers chains
fixup data chains
 0020     0	 0000
fixup constants chains
fixup types chains
entry =  0000
code    44
 0000	     40B2	MOV #23168,&288
 0002	     5A80
 0004	     0120
 0006	     D3D2	BIS.B #1,&34
 0008	     0022
 000A	     40B2	MOV #16383,&368
 000C	     3FFF
 000E	     0170
 0010	     E3D2	XOR.B #1,&33
 0012	     0021
 0014	     40B2	MOV #-15536,&0
 0016	     C350
 0018	     0000
 001A	     8392	SUB #1,&24
 001C	     0018
 001E	     9382	CMP #0,&28
 0020	     001C
 0022	     23FB	JNE $-8, goes to  001A
 0024	     12B0	CALL #368
 0026	     0170
 0028	     3FF3	JMP $-24, goes to  0010
 002A	     4130	RET
