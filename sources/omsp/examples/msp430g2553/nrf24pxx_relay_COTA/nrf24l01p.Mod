MODULE nrf24l01p;
  (*
   * nrrf24l01p.Mod
   *
   *  Created on: 1 dec. 2013
   *      Author: C. Schoffit
   * Oberon portage 17.03.25

    Copyright (c) 2013 Christian Schoffit sphpn@free.fr

    This file is part of nrf24l01+ for msp430 project.

    nrf24l01+ for msp430 is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    nrf24l01+ for msp430 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with nrf24l01+ for msp430; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

 *)
  IMPORT SYSTEM, M := msp430g2553, Delay := msp430delay;

  CONST
    (*System configuration*)
    CPU_FREQ* = 16;

    (*NRF24L01+ useful register values*)
    EMIT* = {1..3}; RECEIVE* = {0..3};
    LOW_POWER* = {1, 5}; HIGH_POWER* = {1..2, 5};
    EN_DPL* = {2}; EN_ACK_PAY* = {1} + EN_DPL;

    (* Commands *)
    R_REGISTER* = {};
    W_REGISTER* = {5};
    R_RX_PAYLOAD* = {0, 5..6};
    W_TX_PAYLOAD* = {5, 7};
    FLUSH_TX* = {0, 5..7};
    FLUSH_RX* = {1, 5..7};
    REUSE_TX_PL* = {0..1, 5..7};
    R_RX_PL_WID* = {5..6};
    W_ACK_PAYLOAD* = {3, 5, 7};
    NOP*  = {0..7};

    (* Registers *)
    CONFIG* =  TOSET(0);
    EN_AA* = TOSET(1);
    EN_RXADDR* = TOSET(2);
    SETUP_AW* = TOSET(3);
    SETUP_RETR* = TOSET(4);
    RF_CH* = TOSET(5);
    RF_SETUP* = TOSET(6);
    STATUS* = TOSET(7);
    OBSERVE_TX* = TOSET(8);
    RPD* = TOSET(9);
    RX_ADDR_P0* = TOSET(0AH);
    TX_ADDR* = TOSET(10H);
    RX_PW_P0* = TOSET(11H);
    FIFO_STATUS* = TOSET(17H);
    DYNPD* = TOSET(1CH);
    FEATURE* = TOSET(1DH);

    (* Flags *)
    (*For STATUS and CONFIG*)
    MAX_RT* = {4};
    TX_DS* = {5};
    RX_DR* = {6};

    (*For FIFO_STATUS*)
    RX_EMPTY* = {0};

    BUFSZ = 6;

  TYPE (* nRF24l01+ breakout configuration structures *)
    RadioPipe* = RECORD payload_length*: BYTE; address*: ARRAY 6 OF CHAR END;
    Radio* = POINTER TO RadioSetup;
    RadioSetup* = RECORD direction*: BYTESET; channel*: BYTE; rf_setup*, features*: BYTESET;
      pipes_count*: BYTE; pipes*: ARRAY 6 OF RadioPipe
    END;

    (* nRF24l01+ breakout I/O assignments *)
    RegisterBit* = RECORD reg*: PBYTESET; bit*: BYTESET END;

    PipeConfig* = RECORD payloadLength*: INTEGER; addrPipe*: PBYTE END;

    Instance* = RECORD ce*, csn*, (* outputs *) irq* (* interrupt input *): RegisterBit;
      txifg* (* UC TX flag *), ucbusy* (* UC busy flag *): RegisterBit;
      txbuf* (* TX buffer *), rxbuf* (* RX buffer *): PBYTE;
      ready*: PBYTE; (* Flag that indicates if the device is ready to send data *)
      radio*: Radio
    END;

    IORegisters = POINTER TO IORegistersDesc;
    IORegistersDesc = RECORD in, out, dir, ifg, ies, ie, sel, ren: BYTE END;

  VAR p1InterruptMask*, p2InterruptMask*: BYTESET;

  PROCEDURE talk*(instance: Instance*; 
    sz: INTEGER*; cmd, rep: PBYTESET* );
  (** Send a command to nRF24l01+ breakout and retrieve the answer
   *  Parameters :
   *  instance (Input) : configuration data of involved nrf24l01+ breakout
   *  sz  (input) : length in bytes of the command and the answer
   *  cmd (input) : array of command bytes to send to breakout
   *  rep (output) : array of answer bytes received from the breakout *)
  VAR i: INTEGER*;
  BEGIN
    (* Select SPI communication with the breakout *)
    BIC(instance.csn.reg^, instance.csn.bit); (* CSN is going LOW*)

    i := sz;
    WHILE i > 0 DO
      REPEAT UNTIL BIT(instance.txifg.reg^, instance.txifg.bit); (* Wait for USCI availability *)
      (* USCI is ready, send character *)
      instance.txbuf^ := ORD(cmd^); INC(ORD(cmd));
      REPEAT UNTIL ~BIT(instance.ucbusy.reg^, instance.ucbusy.bit); (* Wait for USCI availability *)
      IF rep # NIL THEN rep^ := TOSET(instance.rxbuf^); INC(ORD(rep)) END;
      DEC(i)
    END;

    (* USCI transmission terninated, free SPI communication SPI with the breakout *)
    BIS(instance.csn.reg^, instance.csn.bit); (* CSN is going HIGH *)
  END talk;

  (* **** WARNING ****
   * When using interrupts it's very important to reset SEL and SEL2 bits for the pins mapped to the IRQ signal of nRF24l01+ modules
   * It is also mandatory to provide interrupts handle for all ports containing pins mapped to IRQ signals.
   *
   * The recommended template is the following:
   *
   ============================================
    IMPORT SYSTEM, M := msp430g2xxx, nrf24l01p;

    PROCEDURE* (M.PORTx_VECTOR) PORTx_ISR_HOOK;
    BEGIN
      IF M.PxIFG^*p1InterruptMask THEN BIC(M.PxIFG, pxInterruptMask) END;
     SYSTEM.BIC _SR_ON_EXIT(M.LPM4_bits);
    END;
   ============================================
   * When interrupted by a nRF24l01+ module, the MCU exits from sleeping mode, allowing the process of the event in the main loop
   *)

  PROCEDURE registerIrq*(instance: Instance*);
    (* Registers a pin mapped to a nRF24l01+ IRQ signal and handles the needed register settings *)
    VAR ok: BOOLEAN*; port!: IORegisters*; pin: BYTESET*;
  BEGIN
    IF instance.irq.reg # NIL THEN
      ok := TRUE;
      IF instance.irq.reg = M.P1IN THEN BIS(p1InterruptMask, instance.irq.bit)
      ELSIF instance.irq.reg = M.P2IN THEN BIS(p2InterruptMask, instance.irq.bit)
      ELSE ok := FALSE
      END;

      IF ok THEN port := SYSTEM.VAL(IORegisters, ORD(instance.irq.reg)); pin := instance.irq.bit;
        (* nrf24l01+ IRQ seems to be a push-pull output, so I don't use the internal pull up resistor to reduce consumption *)
        BIC(port.dir, pin); (* set input direction without pulling resistor *)
        BIC(port.ren, pin);
        BIC(port.ifg, pin); (* clear pending interrupt *)
        BIS(port.ies, pin); (* enable interrupt on pin when falling down *)
        BIS(port.ie, pin)
      END
    END
  END registerIrq;

  PROCEDURE powerDown*(instance: Instance);
  (**
   *  Go to power off mode from standby-I mode
   *)
  VAR cmd, rep: ARRAY BUFSZ OF BYTESET;
  BEGIN (* Power down *)
    cmd[1] := {0, 2..3};
    REPEAT cmd[0] := W_REGISTER + CONFIG;
      talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
      cmd[0] := R_REGISTER + CONFIG;
      talk(instance, 2, PTR(PBYTESET, cmd[0]), PTR(PBYTESET, rep[0]))
    UNTIL rep[1] = cmd[1]
  END powerDown;

  PROCEDURE powerUp*(instance: Instance);
  (**
   *  Go to standby-I mode from power off mode
   *)
  VAR cmd, rep: ARRAY BUFSZ OF BYTESET;
  BEGIN (* Power up nRF24l01+ module *)
    cmd[1] := instance.radio.direction;
    REPEAT cmd[0] := W_REGISTER + CONFIG;
      talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
      cmd[0] := R_REGISTER + CONFIG;
      talk(instance, 2, PTR(PBYTESET, cmd[0]), PTR(PBYTESET, rep[0]))
    UNTIL rep[1] = cmd[1];

    Delay.CyclesX3(5*CPU_FREQ*1000 DIV 3); (* 5 ms delay *)
  END powerUp;

  PROCEDURE init*(instance: Instance);
  (** Initialize a nRF24l01p breakout
   *  Parameters :
   *  instance (Input) : configuration data of involved nrf24l01+ breakout
   *)
    VAR cmd: ARRAY BUFSZ OF BYTESET;
      i: INTEGER; dpl, pll: BYTE;
      j: INTEGER; car: BYTE;
  BEGIN
    IF (instance.radio.pipes_count > 0) & (instance.radio.pipes_count <= 6) THEN (* The radio configuration is defined *)
      Delay.CyclesX3(5*CPU_FREQ*1000 DIV 3); (* 5 ms delay *)

      powerDown(instance);
      cmd[0] := FLUSH_RX; (* Flush RX FIFO *)
      talk(instance, 1, PTR(PBYTESET, cmd[0]), NIL);
      cmd[0] := FLUSH_TX; (* Flush TX FIFO *)
      talk(instance, 1, PTR(PBYTESET, cmd[0]), NIL);
      cmd[0] := W_REGISTER + STATUS; (* Reset nrf24l01p interrupts *)
      cmd[1] := MAX_RT + TX_DS + RX_DR; (* CLear interrupt flags *)
      talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
      cmd[0] := W_REGISTER + RF_CH;
      cmd[1] := TOSET(instance.radio.channel); (* Set channel. Actual frequency is 2500+channel MHz *)
      talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
      cmd[0] := W_REGISTER + EN_RXADDR; (* Pipes activation *)
      cmd[1] := {0}; RLA(cmd[1], instance.radio.pipes_count); DEC(ORD(cmd[1])); (* c code: cmd[1] = (1<<(instance->radio->pipes_count))-1;*)
      talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
      dpl := 0;
      i := instance.radio.pipes_count - 1;
      REPEAT
        (* configuration of pipe i receive address *)
        j := 0; cmd[0] := TOSET(ORD(W_REGISTER + RX_ADDR_P0) + i);
        REPEAT car := ORD(instance.radio.pipes[i].address[j]); INC(j);
          IF car # 0 THEN cmd[j] := TOSET(car) END
        UNTIL car = 0;
        talk(instance, j, PTR(PBYTESET, cmd[0]), NIL);
        IF (instance.radio.direction = EMIT) & (i = 0) THEN
          (* receive addres is the same as transmit address *)
          cmd[0] := W_REGISTER + TX_ADDR;
          talk(instance, j, PTR(PBYTESET, cmd[0]), NIL);
        END;
        cmd[0] := TOSET(ORD(W_REGISTER + RX_PW_P0) + i); (* payload length of pipe i *)
        pll := instance.radio.pipes[i].payload_length;
        cmd[1] := TOSET(pll); (* Payload size in bytes *)
        talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
        (* Determine Dynamic Payload Length flag *)
        RLA(dpl, 1); IF (pll = 0) THEN INC(dpl) END; (* This pipe has a dynamic length *)
        DEC(i)
      UNTIL i < 0;
      cmd[0] := W_REGISTER + DYNPD;
      cmd[1] := TOSET(dpl); (* Enables Dynamic Payload length on pipes with 0 in RX_PW_Px *)
      talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
      cmd[0] := W_REGISTER + FEATURE; (* Enables features *)
      cmd[1] := instance.radio.features;
      IF dpl # 0 THEN BIS(cmd[1], EN_DPL) END; (* Enables Dynamic Payload Length if at least one pipe uses it *)
      talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
      cmd[0] := W_REGISTER + RF_SETUP;
      cmd[1] := instance.radio.rf_setup;
      talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL);
      IF instance.radio.direction = EMIT THEN
        (* Automatic retransmission after 1750 us.
         * According the data sheet, a delay of 1500 us is sufficient
         * even if the receive breakout has to send 32 bytes of data.
         * With my calculation, it should be at least 1576 us.
         * To be on the safe side, I'll take 1750 us, so 6 in the 4 high bits *)
        cmd[0] := W_REGISTER + SETUP_RETR;
        cmd[1] := TOSET(63H);
        talk(instance, 2, PTR(PBYTESET, cmd[0]), NIL)
      END
    END
  END init;

  PROCEDURE pulseCE*(instance: Instance);
  (* Starts the transmission by setting a high pulse on CE signal *)
  BEGIN
	(* Indicate that the device is busy *)
    IF instance.ready # NIL THEN instance.ready^ := ORD(FALSE) END;
    BIS(instance.ce.reg^, instance.ce.bit); (* A high pulse on CE starts the transmission. The minimum pulse width on CE is 10 us *)
    Delay.CyclesX3(12*CPU_FREQ DIV 3); (* Wait at least 10 us *)
    BIC(instance.ce.reg^, instance.ce.bit);
  END pulseCE;

  PROCEDURE setCE*(instance: Instance*);
  (* Start receive *)
  BEGIN BIS(instance.ce.reg^, instance.ce.bit)
  END setCE;

  PROCEDURE resetCE*(instance: Instance*);
  (* Stop receive *)
  BEGIN BIC(instance.ce.reg^, instance.ce.bit)
  END resetCE;

BEGIN p1InterruptMask := {}; p2InterruptMask := {};
END nrf24l01p.

OMSPTool.DecObj nrf24l01p.mpc
decode nrf24l01p.mpc
nrf24l01p 3885754F Flash  1118
imports:
	msp430g2553 F10488DC
	msp430delay EE6A4099
type descriptors
 0008 FFFF FFFF FFFF 0036 FFFF FFFF FFFF 0004 FFFF FFFF FFFF 0004 FFFF FFFF FFFF 001C FFFF FFFF FFFF 0008 FFFF FFFF FFFF
data     2
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 0424 k 0000 k 0008 k 0010 k 0018 k 0020 d 0000 d 0001 c 0000 c 0052 c 009E c 00E8 c 0140 c 03D0 c 0410 c 041A
fixup procedures in code space chains
 03C8     0	 0000
 0178     0	 009E
 03FC     2	 0001
fixup handlers in vector space chains
fixup data in code space chains
 042A     0	 0001
 0426     0	 0000
fixup constants in code space chains
fixup variables in constant space chains
fixup constants in constant space chains
entry =  0424
code  1070
 0000	     441A	MOV 4(R4),R10
 0002	     0004
 0004	     C4DA	BIC.B 6(R4),0(R10)
 0006	     0006
 0008	     0000
 000A	     4609	MOV R6,R9
 000C	     430A	MOV #0,R10
 000E	     990A	CMP R9,R10
 0010	     341A	JGE $+54, goes to  0046
 0012	     441A	MOV 12(R4),R10
 0014	     000C
 0016	     B4DA	BIT.B 14(R4),0(R10)
 0018	     000E
 001A	     0000
 001C	     27FA	JEQ $-10, goes to  0012
 001E	     441A	MOV 20(R4),R10
 0020	     0014
 0022	     47EA	MOV.B @R7,0(R10)
 0024	     0000
 0026	     5317	ADD #1,R7
 0028	     441A	MOV 16(R4),R10
 002A	     0010
 002C	     B4DA	BIT.B 18(R4),0(R10)
 002E	     0012
 0030	     0000
 0032	     23FA	JNE $-10, goes to  0028
 0034	     9308	CMP #0,R8
 0036	     2405	JEQ $+12, goes to  0042
 0038	     441A	MOV 22(R4),R10
 003A	     0016
 003C	     4AE8	MOV.B @R10,0(R8)
 003E	     0000
 0040	     5318	ADD #1,R8
 0042	     8319	SUB #1,R9
 0044	     3FE3	JMP $-56, goes to  000C
 0046	     441A	MOV 4(R4),R10
 0048	     0004
 004A	     D4DA	BIS.B 6(R4),0(R10)
 004C	     0006
 004E	     0000
 0050	     4130	RET
 0052	     9384	CMP #0,8(R4)
 0054	     0008
 0056	     2422	JEQ $+70, goes to  009C
 0058	     4356	MOV.B #1,R6
 005A	     90B4	CMP #32,8(R4)
 005C	     0020
 005E	     0008
 0060	     2004	JNE $+10, goes to  006A
 0062	     D4D2	BIS.B 10(R4),&0
 0064	     000A
 0066	     0000
 0068	     3C09	JMP $+20, goes to  007C
 006A	     90B4	CMP #40,8(R4)
 006C	     0028
 006E	     0008
 0070	     2004	JNE $+10, goes to  007A
 0072	     D4D2	BIS.B 10(R4),&0
 0074	     000A
 0076	     0000
 0078	     3C01	JMP $+4, goes to  007C
 007A	     4346	MOV.B #0,R6
 007C	     9346	CMP.B #0,R6
 007E	     240E	JEQ $+30, goes to  009C
 0080	     4417	MOV 8(R4),R7
 0082	     0008
 0084	     4458	MOV.B 10(R4),R8
 0086	     000A
 0088	     C8C7	BIC.B R8,2(R7)
 008A	     0002
 008C	     C8C7	BIC.B R8,7(R7)
 008E	     0007
 0090	     C8C7	BIC.B R8,3(R7)
 0092	     0003
 0094	     D8C7	BIS.B R8,4(R7)
 0096	     0004
 0098	     D8C7	BIS.B R8,5(R7)
 009A	     0005
 009C	     4130	RET
 009E	     8031	SUB #12,SP
 00A0	     000C
 00A2	     40F1	MOV.B #13,1(SP)
 00A4	     000D
 00A6	     0001
 00A8	     40F1	MOV.B #32,0(SP)
 00AA	     0020
 00AC	     0000
 00AE	     4114	MOV 14(SP),R4
 00B0	     000E
 00B2	     4115	MOV 16(SP),R5
 00B4	     0010
 00B6	     4326	MOV #2,R6
 00B8	     4107	MOV SP,R7
 00BA	     4308	MOV #0,R8
 00BC	     12B0	CALL #0
 00BE	     0000
 00C0	     43C1	MOV.B #0,0(SP)
 00C2	     0000
 00C4	     4114	MOV 14(SP),R4
 00C6	     000E
 00C8	     4115	MOV 16(SP),R5
 00CA	     0010
 00CC	     4326	MOV #2,R6
 00CE	     4107	MOV SP,R7
 00D0	     4108	MOV SP,R8
 00D2	     5038	ADD #6,R8
 00D4	     0006
 00D6	     12B0	CALL #190
 00D8	     00BE
 00DA	     91D1	CMP.B 1(SP),7(SP)
 00DC	     0001
 00DE	     0007
 00E0	     23E3	JNE $-56, goes to  00A8
 00E2	     5031	ADD #12,SP
 00E4	     000C
 00E6	     4130	RET
 00E8	     8031	SUB #12,SP
 00EA	     000C
 00EC	     411F	MOV 14(SP),R15
 00EE	     000E
 00F0	     4F1F	MOV 26(R15),R15
 00F2	     001A
 00F4	     4FE1	MOV.B @R15,1(SP)
 00F6	     0001
 00F8	     40F1	MOV.B #32,0(SP)
 00FA	     0020
 00FC	     0000
 00FE	     4114	MOV 14(SP),R4
 0100	     000E
 0102	     4115	MOV 16(SP),R5
 0104	     0010
 0106	     4326	MOV #2,R6
 0108	     4107	MOV SP,R7
 010A	     4308	MOV #0,R8
 010C	     12B0	CALL #216
 010E	     00D8
 0110	     43C1	MOV.B #0,0(SP)
 0112	     0000
 0114	     4114	MOV 14(SP),R4
 0116	     000E
 0118	     4115	MOV 16(SP),R5
 011A	     0010
 011C	     4326	MOV #2,R6
 011E	     4107	MOV SP,R7
 0120	     4108	MOV SP,R8
 0122	     5038	ADD #6,R8
 0124	     0006
 0126	     12B0	CALL #270
 0128	     010E
 012A	     91D1	CMP.B 1(SP),7(SP)
 012C	     0001
 012E	     0007
 0130	     23E3	JNE $-56, goes to  00F8
 0132	     4034	MOV #26666,R4
 0134	     682A
 0136	     12B0	CALL #0
 0138	     0000
 013A	     5031	ADD #12,SP
 013C	     000C
 013E	     4130	RET
 0140	     8031	SUB #14,SP
 0142	     000E
 0144	     411F	MOV 16(SP),R15
 0146	     0010
 0148	     4F1F	MOV 26(R15),R15
 014A	     001A
 014C	     430E	MOV #0,R14
 014E	     9F5E	CMP.B 4(R15),R14
 0150	     0004
 0152	     2D3B	JC $+632, goes to  03CA
 0154	     411F	MOV 16(SP),R15
 0156	     0010
 0158	     4F1F	MOV 26(R15),R15
 015A	     001A
 015C	     403E	MOV #6,R14
 015E	     0006
 0160	     9F5E	CMP.B 4(R15),R14
 0162	     0004
 0164	     2932	JNC $+614, goes to  03CA
 0166	     4034	MOV #26666,R4
 0168	     682A
 016A	     12B0	CALL #312
 016C	     0138
 016E	     1211	PUSH 20(SP)
 0170	     0014
 0172	     1211	PUSH 20(SP)
 0174	     0014
 0176	     12B0	CALL #0
 0178	     0000
 017A	     5221	ADD #4,SP
 017C	     40F1	MOV.B #226,0(SP)
 017E	     00E2
 0180	     0000
 0182	     4114	MOV 16(SP),R4
 0184	     0010
 0186	     4115	MOV 18(SP),R5
 0188	     0012
 018A	     4316	MOV #1,R6
 018C	     4107	MOV SP,R7
 018E	     4308	MOV #0,R8
 0190	     12B0	CALL #296
 0192	     0128
 0194	     40F1	MOV.B #225,0(SP)
 0196	     00E1
 0198	     0000
 019A	     4114	MOV 16(SP),R4
 019C	     0010
 019E	     4115	MOV 18(SP),R5
 01A0	     0012
 01A2	     4316	MOV #1,R6
 01A4	     4107	MOV SP,R7
 01A6	     4308	MOV #0,R8
 01A8	     12B0	CALL #402
 01AA	     0192
 01AC	     40F1	MOV.B #39,0(SP)
 01AE	     0027
 01B0	     0000
 01B2	     40F1	MOV.B #112,1(SP)
 01B4	     0070
 01B6	     0001
 01B8	     4114	MOV 16(SP),R4
 01BA	     0010
 01BC	     4115	MOV 18(SP),R5
 01BE	     0012
 01C0	     4326	MOV #2,R6
 01C2	     4107	MOV SP,R7
 01C4	     4308	MOV #0,R8
 01C6	     12B0	CALL #426
 01C8	     01AA
 01CA	     40F1	MOV.B #37,0(SP)
 01CC	     0025
 01CE	     0000
 01D0	     411F	MOV 16(SP),R15
 01D2	     0010
 01D4	     4F1F	MOV 26(R15),R15
 01D6	     001A
 01D8	     4FD1	MOV.B 1(R15),1(SP)
 01DA	     0001
 01DC	     0001
 01DE	     4114	MOV 16(SP),R4
 01E0	     0010
 01E2	     4115	MOV 18(SP),R5
 01E4	     0012
 01E6	     4326	MOV #2,R6
 01E8	     4107	MOV SP,R7
 01EA	     4308	MOV #0,R8
 01EC	     12B0	CALL #456
 01EE	     01C8
 01F0	     40F1	MOV.B #34,0(SP)
 01F2	     0022
 01F4	     0000
 01F6	     43D1	MOV.B #1,1(SP)
 01F8	     0001
 01FA	     411F	MOV 16(SP),R15
 01FC	     0010
 01FE	     4F1F	MOV 26(R15),R15
 0200	     001A
 0202	     4F5F	MOV.B 4(R15),R15
 0204	     0004
 0206	     535F	ADD.B #1,R15
 0208	     835F	SUB.B #1,R15
 020A	     2404	JEQ $+10, goes to  0214
 020C	     51D1	ADD.B 1(SP),1(SP)
 020E	     0001
 0210	     0001
 0212	     3FFA	JMP $-10, goes to  0208
 0214	     83D1	SUB.B #1,1(SP)
 0216	     0001
 0218	     4114	MOV 16(SP),R4
 021A	     0010
 021C	     4115	MOV 18(SP),R5
 021E	     0012
 0220	     4326	MOV #2,R6
 0222	     4107	MOV SP,R7
 0224	     4308	MOV #0,R8
 0226	     12B0	CALL #494
 0228	     01EE
 022A	     43C1	MOV.B #0,8(SP)
 022C	     0008
 022E	     411F	MOV 16(SP),R15
 0230	     0010
 0232	     4F1F	MOV 26(R15),R15
 0234	     001A
 0236	     4F5F	MOV.B 4(R15),R15
 0238	     0004
 023A	     835F	SUB.B #1,R15
 023C	     4F81	MOV R15,6(SP)
 023E	     0006
 0240	     4381	MOV #0,10(SP)
 0242	     000A
 0244	     403F	MOV #42,R15
 0246	     002A
 0248	     511F	ADD 6(SP),R15
 024A	     0006
 024C	     4FC1	MOV.B R15,0(SP)
 024E	     0000
 0250	     411F	MOV 16(SP),R15
 0252	     0010
 0254	     4F1F	MOV 26(R15),R15
 0256	     001A
 0258	     411E	MOV 6(SP),R14
 025A	     0006
 025C	     5E0E	ADD R14,R14
 025E	     5E0E	ADD R14,R14
 0260	     5E0E	ADD R14,R14
 0262	     5F0E	ADD R15,R14
 0264	     411F	MOV 10(SP),R15
 0266	     000A
 0268	     5E0F	ADD R14,R15
 026A	     4FD1	MOV.B 8(R15),12(SP)
 026C	     0008
 026E	     000C
 0270	     5391	ADD #1,10(SP)
 0272	     000A
 0274	     93C1	CMP.B #0,12(SP)
 0276	     000C
 0278	     2406	JEQ $+14, goes to  0286
 027A	     411F	MOV 10(SP),R15
 027C	     000A
 027E	     510F	ADD SP,R15
 0280	     41DF	MOV.B 12(SP),0(R15)
 0282	     000C
 0284	     0000
 0286	     93C1	CMP.B #0,12(SP)
 0288	     000C
 028A	     23E2	JNE $-58, goes to  0250
 028C	     4114	MOV 16(SP),R4
 028E	     0010
 0290	     4115	MOV 18(SP),R5
 0292	     0012
 0294	     4116	MOV 10(SP),R6
 0296	     000A
 0298	     4107	MOV SP,R7
 029A	     4308	MOV #0,R8
 029C	     12B0	CALL #552
 029E	     0228
 02A0	     411F	MOV 16(SP),R15
 02A2	     0010
 02A4	     4F1F	MOV 26(R15),R15
 02A6	     001A
 02A8	     90FF	CMP.B #14,0(R15)
 02AA	     000E
 02AC	     0000
 02AE	     2010	JNE $+34, goes to  02D0
 02B0	     9381	CMP #0,6(SP)
 02B2	     0006
 02B4	     200D	JNE $+28, goes to  02D0
 02B6	     40F1	MOV.B #48,0(SP)
 02B8	     0030
 02BA	     0000
 02BC	     4114	MOV 16(SP),R4
 02BE	     0010
 02C0	     4115	MOV 18(SP),R5
 02C2	     0012
 02C4	     4116	MOV 10(SP),R6
 02C6	     000A
 02C8	     4107	MOV SP,R7
 02CA	     4308	MOV #0,R8
 02CC	     12B0	CALL #670
 02CE	     029E
 02D0	     403F	MOV #49,R15
 02D2	     0031
 02D4	     511F	ADD 6(SP),R15
 02D6	     0006
 02D8	     4FC1	MOV.B R15,0(SP)
 02DA	     0000
 02DC	     411F	MOV 16(SP),R15
 02DE	     0010
 02E0	     4F1F	MOV 26(R15),R15
 02E2	     001A
 02E4	     411E	MOV 6(SP),R14
 02E6	     0006
 02E8	     5E0E	ADD R14,R14
 02EA	     5E0E	ADD R14,R14
 02EC	     5E0E	ADD R14,R14
 02EE	     5F0E	ADD R15,R14
 02F0	     4ED1	MOV.B 6(R14),9(SP)
 02F2	     0006
 02F4	     0009
 02F6	     41D1	MOV.B 9(SP),1(SP)
 02F8	     0009
 02FA	     0001
 02FC	     4114	MOV 16(SP),R4
 02FE	     0010
 0300	     4115	MOV 18(SP),R5
 0302	     0012
 0304	     4326	MOV #2,R6
 0306	     4107	MOV SP,R7
 0308	     4308	MOV #0,R8
 030A	     12B0	CALL #718
 030C	     02CE
 030E	     51D1	ADD.B 8(SP),8(SP)
 0310	     0008
 0312	     0008
 0314	     93C1	CMP.B #0,9(SP)
 0316	     0009
 0318	     2002	JNE $+6, goes to  031E
 031A	     53D1	ADD.B #1,8(SP)
 031C	     0008
 031E	     8391	SUB #1,6(SP)
 0320	     0006
 0322	     9381	CMP #0,6(SP)
 0324	     0006
 0326	     378C	JGE $-230, goes to  0240
 0328	     40F1	MOV.B #60,0(SP)
 032A	     003C
 032C	     0000
 032E	     41D1	MOV.B 8(SP),1(SP)
 0330	     0008
 0332	     0001
 0334	     4114	MOV 16(SP),R4
 0336	     0010
 0338	     4115	MOV 18(SP),R5
 033A	     0012
 033C	     4326	MOV #2,R6
 033E	     4107	MOV SP,R7
 0340	     4308	MOV #0,R8
 0342	     12B0	CALL #780
 0344	     030C
 0346	     40F1	MOV.B #61,0(SP)
 0348	     003D
 034A	     0000
 034C	     411F	MOV 16(SP),R15
 034E	     0010
 0350	     4F1F	MOV 26(R15),R15
 0352	     001A
 0354	     4FD1	MOV.B 3(R15),1(SP)
 0356	     0003
 0358	     0001
 035A	     93C1	CMP.B #0,8(SP)
 035C	     0008
 035E	     2402	JEQ $+6, goes to  0364
 0360	     D2E1	BIS.B #4,1(SP)
 0362	     0001
 0364	     4114	MOV 16(SP),R4
 0366	     0010
 0368	     4115	MOV 18(SP),R5
 036A	     0012
 036C	     4326	MOV #2,R6
 036E	     4107	MOV SP,R7
 0370	     4308	MOV #0,R8
 0372	     12B0	CALL #836
 0374	     0344
 0376	     40F1	MOV.B #38,0(SP)
 0378	     0026
 037A	     0000
 037C	     411F	MOV 16(SP),R15
 037E	     0010
 0380	     4F1F	MOV 26(R15),R15
 0382	     001A
 0384	     4FD1	MOV.B 2(R15),1(SP)
 0386	     0002
 0388	     0001
 038A	     4114	MOV 16(SP),R4
 038C	     0010
 038E	     4115	MOV 18(SP),R5
 0390	     0012
 0392	     4326	MOV #2,R6
 0394	     4107	MOV SP,R7
 0396	     4308	MOV #0,R8
 0398	     12B0	CALL #884
 039A	     0374
 039C	     411F	MOV 16(SP),R15
 039E	     0010
 03A0	     4F1F	MOV 26(R15),R15
 03A2	     001A
 03A4	     90FF	CMP.B #14,0(R15)
 03A6	     000E
 03A8	     0000
 03AA	     200F	JNE $+32, goes to  03CA
 03AC	     40F1	MOV.B #36,0(SP)
 03AE	     0024
 03B0	     0000
 03B2	     40F1	MOV.B #99,1(SP)
 03B4	     0063
 03B6	     0001
 03B8	     4114	MOV 16(SP),R4
 03BA	     0010
 03BC	     4115	MOV 18(SP),R5
 03BE	     0012
 03C0	     4326	MOV #2,R6
 03C2	     4107	MOV SP,R7
 03C4	     4308	MOV #0,R8
 03C6	     12B0	CALL #922
 03C8	     039A
 03CA	     5031	ADD #14,SP
 03CC	     000E
 03CE	     4130	RET
 03D0	     411F	MOV 2(SP),R15
 03D2	     0002
 03D4	     938F	CMP #0,24(R15)
 03D6	     0018
 03D8	     2406	JEQ $+14, goes to  03E6
 03DA	     411F	MOV 2(SP),R15
 03DC	     0002
 03DE	     4F1F	MOV 24(R15),R15
 03E0	     0018
 03E2	     43CF	MOV.B #0,0(R15)
 03E4	     0000
 03E6	     411F	MOV 2(SP),R15
 03E8	     0002
 03EA	     4F2F	MOV @R15,R15
 03EC	     411E	MOV 2(SP),R14
 03EE	     0002
 03F0	     DEDF	BIS.B 2(R14),0(R15)
 03F2	     0002
 03F4	     0000
 03F6	     4034	MOV #64,R4
 03F8	     0040
 03FA	     12B0	CALL #364
 03FC	     016C
 03FE	     411F	MOV 2(SP),R15
 0400	     0002
 0402	     4F2F	MOV @R15,R15
 0404	     411E	MOV 2(SP),R14
 0406	     0002
 0408	     CEDF	BIC.B 2(R14),0(R15)
 040A	     0002
 040C	     0000
 040E	     4130	RET
 0410	     4426	MOV @R4,R6
 0412	     D4D6	BIS.B 2(R4),0(R6)
 0414	     0002
 0416	     0000
 0418	     4130	RET
 041A	     4426	MOV @R4,R6
 041C	     C4D6	BIC.B 2(R4),0(R6)
 041E	     0002
 0420	     0000
 0422	     4130	RET
 0424	     43C2	MOV.B #0,&102
 0426	     0066
 0428	     43C2	MOV.B #0,&118
 042A	     0076
 042C	     4130	RET
