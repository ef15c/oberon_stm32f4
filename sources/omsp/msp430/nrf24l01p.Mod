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

  PROCEDURE pulseCE*(instance: Instance* );
  (* Starts the transmission by setting a high pulse on CE signal *)
    VAR i: INTEGER*;
  BEGIN
	(* Indicate that the device is busy *)
    IF instance.ready # NIL THEN instance.ready^ := ORD(FALSE) END;
    BIS(instance.ce.reg^, instance.ce.bit); (* A high pulse on CE starts the transmission. The minimum pulse width on CE is 10 us *)
    i := 12*CPU_FREQ DIV 3; REPEAT DEC(i) UNTIL SYSTEM.COND(1); (* Wait at least 10 us *)
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
