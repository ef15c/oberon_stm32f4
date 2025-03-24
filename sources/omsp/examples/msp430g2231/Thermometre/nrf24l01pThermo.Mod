MODULE nrf24l01pThermo;
  IMPORT M := msp430g2231, Delay := msp430delay;
(*
 * nrrf24l01p.Mod
 *
 *  Created on: 1 dec. 2013
 *      Author: C. Schoffit
 * Oberon portage 17.03.25

   Copyright (c) 2013 Christian Schoffit sphpn@free.fr

This file is part of nrf24l01+ for msp430 project.

    This module is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This module is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this module; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

 *)

  CONST (* Affectation des E/S au nRF24l01+ "breakout" *)
    (* Sorties *)
    PO_CE = M.P1OUT; CE = {4}; (* CE P1.4 *)
    PO_CSN =  M.P1OUT; CSN = {0}; (* CSN P1.0 *)

    (* Interruptions *)
    PF_IRQ* = M.P1IFG; IRQ* = {3}; (* IRQ P1.3 *)

    (* Commandes *)
    NOP* =  0FFH;
    R_REGISTER* =  0;
    W_REGISTER* = 20H;
    R_RX_PL_WID* = 60H;
    R_RX_PAYLOAD* = 61H;
    W_TX_PAYLOAD* = 0A0H;
    FLUSH_TX* = 0E1H;
    FLUSH_RX* = 0E2H;

    (* Registres *)
    CONFIG* = 0;
    EN_AA* = 1;
    EN_RXADDR* = 2;
    SETUP_AW* = 3;
    SETUP_RETR* = 4;
    RF_CH* = 5;
    RF_SETUP* = 6;
    STATUS* = 7;
    OBSERVE_TX* = 8;
    RX_ADDR_P0* = 0AH;
    RX_ADDR_P1* = 0BH;
    RX_ADDR_P2* = 0CH;
    TX_ADDR* = 10H;
    RX_PW_P0* = 11H;
    RX_PW_P1* = 12H;
    RX_PW_P2* = 13H;
    FIFO_STATUS* = 17H;
    DYNPD* = 1CH;
    FEATURE* = 1DH;

    (* Flags *)
    MAX_RT* = {4};
    TX_DS* = {5};
    RX_DR* = {6};
    RX_EMPTY* = {0};

    CPU_FREQ* = 1; (* MHz *)

  VAR ready*: BOOLEAN; (* Flag that indicates if the device is ready to send data *)

  PROCEDURE talk*(sz: INTEGER*; cmd, rep: PBYTE*);
  (** Envoie une commande au nRF24l01p et recupere la reponse
   *  Parametres :
   *  sz  (entree) : longueur en octets de la commande et de la reponse
   *  cmd (entree) : pointeur sur la sequence d'octets de commande a envoyer au module
   *  rep (sortie) : pointeur sur sequence d'octets de reponse renvoyes par le module *)
    VAR i: INTEGER*;
  BEGIN
	(* Selection de la communication SPI avec le module *)
	BIC(PO_CSN^, CSN); (* CSN is going LOW *)

	FOR i := sz TO 1 BY -1 DO REPEAT UNTIL M.USICNT^ = {}; (* Wait for USI availability *)
      M.USISRL^ := cmd^; INC(ORD(cmd)); M.USICNT^ := TOSET(8); (* USI is ready, send character*)
      REPEAT UNTIL BIT(M.USICTL1^, M.USIIFG); (* Wait for USI availability *)
      IF rep # NIL THEN rep^ := M.USISRL^; INC(ORD(rep)) END
      END; (* USI transmission terninated *)

	(* Liberation de la communication SPI avec le module *)
	BIS(PO_CSN^, CSN); (* CSN is going HIGH *)
  END talk;

  PROCEDURE pulseCE*;
  (* Starts the transmission by setting a high pulse on CE signal *)
  BEGIN
    ready := FALSE; (* Indicate that the device is busy *)
	(* A high pulse on CE starts the transmission. The minimum pulse width on CE is 10 \B5s *)
	BIS(PO_CE^, CE);
    Delay.CyclesX3(12*CPU_FREQ DIV 3); (* Wait at least 10 \B5s *)
	BIC(PO_CE^, CE);
  END pulseCE;

  PROCEDURE setCE*; (* Start receive *)
  BEGIN BIS(PO_CE^, CE)
  END setCE;


  PROCEDURE resetCE*; (* Stop receive *)
  BEGIN BIC(PO_CE^, CE)
  END resetCE;

  PROCEDURE setReady*;
  BEGIN ready := TRUE;
  END setReady;

BEGIN ready := TRUE
END nrf24l01pThermo.

OMSPTool.DecSym nrf24l01pThermo.sms
decode nrf24l01pThermo.sms
nrf24l01pThermo B74D2B31  1
   1 PF_IRQ [^18]      35
   1 IRQ [^6]       8
   1 NOP [^4]     255
   1 R_REGISTER [^4]       0
   1 W_REGISTER [^4]      32
   1 R_RX_PL_WID [^4]      96
   1 R_RX_PAYLOAD [^4]      97
   1 W_TX_PAYLOAD [^4]     160
   1 FLUSH_TX [^4]     225
   1 FLUSH_RX [^4]     226
   1 CONFIG [^4]       0
   1 EN_AA [^4]       1
   1 EN_RXADDR [^4]       2
   1 SETUP_AW [^4]       3
   1 SETUP_RETR [^4]       4
   1 RF_CH [^4]       5
   1 RF_SETUP [^4]       6
   1 STATUS [^4]       7
   1 OBSERVE_TX [^4]       8
   1 RX_ADDR_P0 [^4]      10
   1 RX_ADDR_P1 [^4]      11
   1 RX_ADDR_P2 [^4]      12
   1 TX_ADDR [^4]      16
   1 RX_PW_P0 [^4]      17
   1 RX_PW_P1 [^4]      18
   1 RX_PW_P2 [^4]      19
   1 FIFO_STATUS [^4]      23
   1 DYNPD [^4]      28
   1 FEATURE [^4]      29
   1 MAX_RT [^6]      16
   1 TX_DS [^6]      32
   1 RX_DR [^6]      64
   1 RX_EMPTY [^6]       1
   1 CPU_FREQ [^4]       1
   2 ready [^2]     1
   1 talk [0  form = 10  size = 2 [^9] leaf UR 00F0( class = 2 R6 [^14] class = 2 R5 [^14] class = 2 R4 [^4])]       2
   1 pulseCE [0  form = 10  size = 2 [^9] UR 0010()]       3
   1 setCE [0  form = 10  size = 2 [^9] UR 0000()]       4
   1 resetCE [0  form = 10  size = 2 [^9] UR 0000()]       5
   1 setReady [0  form = 10  size = 2 [^9] UR 0000()]       6

OMSPTool.DecObj nrf24l01pThermo.mpc
decode nrf24l01pThermo.mpc
nrf24l01pThermo 91FDB45D Flash   106
imports:
	msp430g2231 5D5FCA6E
	msp430delay EE6A4099
type descriptors

data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0064 d 0000 c 0000 c 0036 c 004E c 0056 c 005E
fixup procedures chains
 0044     2	 0001
fixup handlers chains
fixup data chains
 0066     0	 0000
fixup constants chains
fixup types chains
entry =  0064
code   106
 0000	     C3D2	BIC.B #1,&33
 0002	     0021
 0004	     4407	MOV R4,R7
 0006	     9317	CMP #1,R7
 0008	     3813	JL $+40, goes to  0030
 000A	     93C2	CMP.B #0,&123
 000C	     007B
 000E	     23FD	JNE $-4, goes to  000A
 0010	     45E2	MOV.B @R5,&124
 0012	     007C
 0014	     5315	ADD #1,R5
 0016	     42F2	MOV.B #8,&123
 0018	     007B
 001A	     B3D2	BIT.B #1,&121
 001C	     0079
 001E	     27FD	JEQ $-4, goes to  001A
 0020	     9306	CMP #0,R6
 0022	     2404	JEQ $+10, goes to  002C
 0024	     42D6	MOV.B &124,0(R6)
 0026	     007C
 0028	     0000
 002A	     5316	ADD #1,R6
 002C	     5337	ADD #-1,R7
 002E	     3FEB	JMP $-40, goes to  0006
 0030	     D3D2	BIS.B #1,&33
 0032	     0021
 0034	     4130	RET
 0036	     43C2	MOV.B #0,&0
 0038	     0000
 003A	     D0F2	BIS.B #16,&33
 003C	     0010
 003E	     0021
 0040	     4224	MOV #4,R4
 0042	     12B0	CALL #0
 0044	     0000
 0046	     C0F2	BIC.B #16,&33
 0048	     0010
 004A	     0021
 004C	     4130	RET
 004E	     D0F2	BIS.B #16,&33
 0050	     0010
 0052	     0021
 0054	     4130	RET
 0056	     C0F2	BIC.B #16,&33
 0058	     0010
 005A	     0021
 005C	     4130	RET
 005E	     43D2	MOV.B #1,&56
 0060	     0038
 0062	     4130	RET
 0064	     43D2	MOV.B #1,&96
 0066	     0060
 0068	     4130	RET
