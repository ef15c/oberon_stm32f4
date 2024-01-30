MODULE SCC; (*NW 13.11.87 / 22.8.90 Ceres-2; nRF24L01+ version PR 21.7.13 / 23.12.13
  CS 21/01/2024*)
  IMPORT SYSTEM, Kernel;

  CONST
(*    swi = -60; spiData = -48; spiCtrl = -44;*)

    (*STM32F429*)
    
    (*Unique device ID register (96 bits)*)
    UIDREgAdr = 1FFF7A10H;
    
    (*GPIOs*)
    PeriphBase = 40000000H; PeriphBBAlias = 42000000H;
    
    GPIOBBase = 40020400H; GPIOGBase = 40021800H; GPIODBase = 40020C00H;
    IDR = 10H; ODR = 14H; BSRR = 18H;
    netSelect = 7; (*PB7*) netEnable = 9; (*PG9*) netIRQ = 7; (*PD7*)
    netSelectOut = PeriphBBAlias + (GPIOBBase + ODR - PeriphBase + netSelect DIV 8)*32 + netSelect MOD 8*4;
    netEnableOut = PeriphBBAlias + (GPIOGBase + ODR - PeriphBase + netEnable DIV 8)*32 + netEnable MOD 8*4;
    netIRQIn = PeriphBBAlias + (GPIODBase + IDR - PeriphBase + netIRQ DIV 8)*32 + netIRQ MOD 8*4;
    
    (*SPI*)
    SPI3Base = 40003C00H; DR = 0CH; SR = 8;
    spiData = SPI3Base + DR; spiSR = SPI3Base + SR;
    RXNE = 0; TXE = 1;
    
    HdrSize = 8; MaxPayload = 512; SubPacket = 32; Wait = 50; SendTries = 50;
    MaxPacket = (HdrSize + MaxPayload + SubPacket-1) DIV SubPacket * SubPacket;

  TYPE Header* =
    RECORD valid*: BOOLEAN;
      typ*: BYTE;
      fil1, fil2: BYTE;
      len*: INTEGER (*of data following header*)
    END ;

  VAR
    filter*: BOOLEAN; rcvd: INTEGER;
    rx: RECORD
      hd: Header;
      dat: ARRAY MaxPacket-HdrSize OF BYTE
    END;

  PROCEDURE Delayms(d: INTEGER);
    VAR beg: INTEGER;
  BEGIN beg := Kernel.Time();
    REPEAT UNTIL Kernel.Time() - beg > d
  END Delayms;
  
  PROCEDURE SPIWrite(n: BYTE);
  BEGIN (*send into shift reg one byte*)
    REPEAT UNTIL SYSTEM.BIT(spiSR, TXE) (*wait until TX buffer is empty*); SYSTEM.PUT(spiData, n);
  END SPIWrite;

  PROCEDURE SPIRead(VAR n: BYTE);
  BEGIN (*rcv form shift reg one byte, at current speed*)
    REPEAT UNTIL SYSTEM.BIT(spiSR, RXNE) (*wait until TX buffer is empty*); SYSTEM.PUT(spiData, n);
  END SPIRead;

  PROCEDURE StartCmd(cmd: INTEGER);
  BEGIN SYSTEM.PUT(netSelectOut, 0); SPIWrite(cmd)
  END StartCmd;

  PROCEDURE WriteReg1(reg, dat: BYTE); (*disables radio!*)
  BEGIN SYSTEM.PUT(netEnableOut, 0); StartCmd(reg + 20H); SPIWrite(dat); SYSTEM.PUT(netSelectOut, 1) (*W_REGISTER*)
  END WriteReg1;

  PROCEDURE WriteRegN(reg: BYTE; dat: ARRAY OF CHAR; len: INTEGER); (*disables radio!*)
    VAR i: INTEGER;
  BEGIN SYSTEM.PUT(netEnableOut, 0); StartCmd(reg + 20H);
    FOR i := 0 TO len - 1 DO SPIWrite(ORD(dat[i])) END; SYSTEM.PUT(netSelectOut, 1) (*W_REGISTER*)
  END WriteRegN;

  PROCEDURE SubRcv(dst: INTEGER);
    VAR i: INTEGER; dat: BYTE;
  BEGIN
    StartCmd(61H); (*R_RX_PAYLOAD, disables radio*)
    FOR i := 0 TO SubPacket-1 DO
      SPIWrite(-1); SPIRead(dat); SYSTEM.PUT(dst+i, dat)
    END;
    SYSTEM.PUT(netSelectOut, 1); WriteReg1(7, 40H); (*done; STATUS <= clear RX_DR*); 
    SYSTEM.PUT(netSelectOut, 1); SYSTEM.PUT(netEnableOut, 1); (*enable radio*)
  END SubRcv;

  PROCEDURE SubSnd(src: INTEGER; VAR timeout: BOOLEAN);
    VAR i, res, t1, try: INTEGER; x, dat, status: BYTE;
  BEGIN (*already in xmit mode*)
    StartCmd(0A0H); (*W_TX_PAYLOAD*)
    FOR i := 0 TO SubPacket-1 DO
      SYSTEM.GET(src+i, dat); SPIWrite(dat)
    END;
    SYSTEM.PUT(netSelectOut, 1); (*end W_TX_PAYLOAD command*)
    try := 0;
    SYSTEM.PUT(netSelectOut, 0); SYSTEM.PUT(netEnableOut, 1); (*start xmit pulse, start NOP cmd*)
    REPEAT
      t1 := Kernel.Time();
      REPEAT (*wait for sent or retransmits exceeded*);
        SPIWrite(0FFH); SPIRead(status); (*NOP*)
        res := status DIV 10H MOD 4;
        SYSTEM.PUT(netEnableOut, 0); SYSTEM.PUT(netSelectOut, 1); SYSTEM.PUT(netSelectOut, 0); (*end & restart NOP cmd, end =10us pulse on enable*)
      UNTIL res # 0;
      IF res = 2 THEN WriteReg1(7, 20H) (*TX_DS: sent, ack received; reset it*)
      ELSIF res = 1 THEN WriteReg1(7, 10H); INC(try); (*MAX_RT: retransmits exceeded; reset it*)
        IF try = SendTries THEN res := 0
        ELSE REPEAT UNTIL Kernel.Time() - t1 >= Wait;
          SYSTEM.PUT(netEnableOut, 1); SYSTEM.PUT(netSelectOut, 0); (*start xmit pulse, start NOP cmd again*)
        END
      END
    UNTIL res # 1;
    timeout := (res # 2)
  END SubSnd;

  PROCEDURE Flush;
  BEGIN StartCmd(0E1H); SYSTEM.PUT(netSelectOut, 1); StartCmd(0E2H); SYSTEM.PUT(netSelectOut, 1)
(*FLUSH_TX, FLUSH_RX*)
  END Flush;

  PROCEDURE ResetRcv;
  BEGIN SYSTEM.PUT(SYSTEM.ADR(rx), 0); rx.hd.len := 0; rcvd := 0
  END ResetRcv;

  PROCEDURE Listen(b: BOOLEAN);
  BEGIN
    WriteReg1(0, 07EH + ORD(b)); (*CONFIG <= mask ints; EN_CRC(2 byte), PWR_UP, PRX/PTX*)
    IF b THEN SYSTEM.PUT(netEnableOut, 1); END (*turn radio on*)
  END Listen;

  PROCEDURE Start*(channel: BYTE; pipeName: ARRAY OF CHAR);
    VAR len: INTEGER;
  BEGIN SYSTEM.PUT(netEnableOut, 0); Delayms(5);
    len := 0; WHILE (len < LEN(pipeName)) & (pipeName[len] # 0X) DO INC(len) END;
    WriteReg1(0, 07CH); (*CONFIG <= mask ints; EN_CRC(2 byte), PWR_DOWN, PTX*)
    Flush; WriteReg1(7, 70H); (*STATUS <= clear ints*)
    WriteReg1(5, channel); (*RF_CH <= channel: 5, 15, 25...*)
    WriteReg1(6, 22H); (*RF_SETUP = 250kb for better range, -12dBm*)
    WriteReg1(1, 3FH); (*EN_AA enable Enable 'Auto Acknowledgment' on all pipes*)
    WriteReg1(2, 1H); (*EN_RXADDR enable pipe 0*)
    ASSERT(len IN {3..5});
    WriteReg1(3, len-2); (*SETUP_AW setup address length*)
    WriteRegN(0AH, pipeName, len); (*RX_ADDR_P0 define pipe 0 receive address*)
    WriteRegN(10H, pipeName, len); (*TX_ADDR define pipe transmit address*)
    WriteReg1(11H, 0); (*RX_PW_P0 <= pipe 0 payload width = 0 to allow ACK payload*)
    WriteReg1(1CH, 1); (*DYNPD Enable dynamic payload length data pipe 0. (Requires EN_DPL and ENAA_P0)*)
    WriteReg1(1DH, 6); (*FEATURE Enables Dynamic Payload Length and Payload with ACK*)
    Flush(); Listen(TRUE); ResetRcv
  END Start;

(*j'en suis là*)

  PROCEDURE SendPacket*(VAR head: Header; dat: ARRAY OF BYTE);
    VAR len, i, off: INTEGER; timeout: BOOLEAN; 
    payload: ARRAY SubPacket OF BYTE;
  BEGIN (*let any receive ack finish before turning radio off*)
    i := Kernel.Time();
    REPEAT SPICtrl({netEnable, netSelect}); SPIWrite(0FFH); SPICtrl({netEnable}) (*NOP*)
    UNTIL Kernel.Time() - i >= Wait;
    IF Adr = 0 THEN Adr := i MOD 100H END;
    Listen(FALSE);
    head.sadr := Adr; head.valid := TRUE;
    SYSTEM.COPY(SYSTEM.ADR(head), SYSTEM.ADR(payload), HdrSize DIV 4);
    i := HdrSize; off := 0; len := head.len;
    WHILE (len > 0) & (i < SubPacket) DO payload[i] := dat[off]; INC(i); INC(off); DEC(len) END;
    WHILE i < SubPacket DO payload[i] := 0; INC(i) END;
    SubSnd(SYSTEM.ADR(payload), timeout);
    WHILE ~timeout & (len # 0) DO i := 0; (*send the rest*)
      WHILE (len > 0) & (i < SubPacket) DO payload[i] := dat[off]; INC(i); INC(off); DEC(len) END;
      WHILE i < SubPacket DO payload[i] := 0; INC(i) END;
      SubSnd(SYSTEM.ADR(payload), timeout)
    END;
    Listen(TRUE)
  END SendPacket;

  PROCEDURE Available*(): INTEGER;
  BEGIN (*packet already rcvd*)
    RETURN rx.hd.len - rcvd
  END Available;

  PROCEDURE Receive*(VAR x: BYTE);
  BEGIN (*packet already rcvd*)
    IF rcvd < rx.hd.len THEN x := rx.dat[rcvd]; INC(rcvd) ELSE x := 0 END
  END Receive;

  PROCEDURE Rcvd(time: INTEGER): BOOLEAN;
    VAR status, fifoStatus: BYTE; rcvd: BOOLEAN;
      t1: INTEGER;
  BEGIN t1 := Kernel.Time();
    REPEAT
      SPICtrl({netEnable, netSelect}); SPIWrite(17H); (*R_REGISTER FIFO_STATUS*)
      SYSTEM.GET(spiData, status); SPIWrite(-1); SYSTEM.GET(spiData, fifoStatus); SPICtrl({netEnable});
      rcvd := ODD(status DIV 40H) OR ~ODD(fifoStatus) (*RX_DR (data ready) or RX FIFO not empty*)
    UNTIL rcvd OR (Kernel.Time() - t1 >= time);
    RETURN rcvd
  END Rcvd;

  PROCEDURE ReceiveHead*(VAR head: Header);  (*actually, recv whole packet*)
    VAR adr, n: INTEGER;
  BEGIN head.valid := FALSE;
    IF Rcvd(0) THEN
      ResetRcv; adr := SYSTEM.ADR(rx); SubRcv(adr);
      n := (rx.hd.len + HdrSize - 1) DIV SubPacket;
      IF (rx.hd.len <= MaxPayload)
          & ((rx.hd.dadr = 0FFH) OR ~filter OR (Adr = 0) OR (rx.hd.dadr = Adr)) THEN
        WHILE (n > 0) & Rcvd(Wait) DO
          INC(adr, SubPacket); SubRcv(adr); DEC(n)
        END;
        rx.hd.valid := (n = 0)
      ELSE WHILE Rcvd(Wait) DO SubRcv(adr) END; ResetRcv  (*discard packet*)
      END;
      head := rx.hd
    END
  END ReceiveHead;

  PROCEDURE Skip*(m: INTEGER);
    VAR dmy: BYTE;
  BEGIN WHILE m # 0 DO Receive(dmy); DEC(m) END
  END Skip;

  PROCEDURE Stop*;
  BEGIN SPICtrl({}); Flush(); ResetRcv
  END Stop;

BEGIN Start(TRUE)
END SCC.
