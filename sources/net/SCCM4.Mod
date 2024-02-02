MODULE SCC; (*NW 13.11.87 / 22.8.90 Ceres-2; nRF24L01+ version PR 21.7.13 / 23.12.13
  CS 21/01/2024*)
  IMPORT SYSTEM, Kernel;

  CONST
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
    RXNE = 0; TXE = 1; BSY = 7;

    (*CRC*)
    CRCBase = 40023000H; CRCDR = 0; CR = 8;
    CRCReset = PeriphBBAlias + (CRCBase + CR - PeriphBase)*32;
    
    HdrSize = 8; MaxPayload = 512; SubPacket = 32; Wait = 50; SendTries = 50;
    MaxPacket = (HdrSize + MaxPayload + SubPacket-1) DIV SubPacket * SubPacket;

  TYPE Header* =
    RECORD valid*: BOOLEAN;
      dadr*, sadr*, typ*: BYTE;
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
  
  PROCEDURE SPIn(src, dst, n: INTEGER);
    VAR sc, rc: INTEGER; data: BYTE;
  BEGIN (*send/rcv n bytes to/from SPI*) ASSERT(n>0);
    sc := 0; rc := 0;
    REPEAT 
      IF SYSTEM.BIT(spiSR, TXE) & (sc < n) THEN (*TX buffer is empty*) 
        SYSTEM.GET(src+sc, data); SYSTEM.PUT(spiData, data); INC(sc)
      END;
      IF SYSTEM.BIT(spiSR, RXNE) & (rc < n) THEN (*RX buffer is not empty*)
        SYSTEM.GET(spiData, data); SYSTEM.PUT(dst+rc, data); INC(sc)
      END
    UNTIL (sc = n) & (rc = n);
    REPEAT UNTIL ~SYSTEM.BIT(spiSR, BSY) (*Wait until SPI is not busy*)
  END SPIn;

  PROCEDURE SPIw(n: BYTE);
  BEGIN (*send into shift reg one byte*)
    SPIn(SYSTEM.ADR(n), SYSTEM.ADR(n), 1)
  END SPIw;

  PROCEDURE SPIr(VAR n: BYTE);
    VAR nop: BYTE;
  BEGIN (*rcv from shift reg one byte*)
    nop := 0FFH;
    SPIn(SYSTEM.ADR(nop), SYSTEM.ADR(n), 1)
  END SPIr;

  PROCEDURE SPIrw(n: BYTE; VAR r: BYTE);
  BEGIN (*send/rcv into/from shift reg one byte*)
    SPIn(SYSTEM.ADR(n), SYSTEM.ADR(r), 1)
  END SPIrw;

  PROCEDURE StartCmd(cmd: INTEGER);
  BEGIN SYSTEM.PUT(netSelectOut, 0); SPIw(cmd)
  END StartCmd;

  PROCEDURE WriteReg1(reg, dat: BYTE);
  BEGIN StartCmd(reg + 20H); SPIw(dat); SYSTEM.PUT(netSelectOut, 1) (*W_REGISTER*)
  END WriteReg1;

  PROCEDURE WriteRegN(reg: BYTE; dat: ARRAY OF CHAR; len: INTEGER); (*disables radio!*)
    VAR i: INTEGER;
  BEGIN StartCmd(reg + 20H);
    FOR i := 0 TO len - 1 DO SPIw(ORD(dat[i])) END; SYSTEM.PUT(netSelectOut, 1) (*W_REGISTER*)
  END WriteRegN;

  PROCEDURE SubRcv(dst: INTEGER; VAR len: BYTE);
    VAR i, data: INTEGER; dat: BYTE;
  BEGIN
    StartCmd(60H); SPIr(len); (*R_RX_PL_WID*)
    ASSERT(len MOD 4 = 0);
    StartCmd(61H); (*R_RX_PAYLOAD*)
    FOR i := 0 TO len-1 DO
      SPIr(dat); SYSTEM.PUT(dst+i, dat)
    END;
    FOR i := 0 TO len-4 BY 4 DO (*Compute CRC*)
      SYSTEM.GET(dst+i, data); SYSTEM.PUT(CRCBase+CRCDR, data)
    END;
    SYSTEM.PUT(netSelectOut, 1); WriteReg1(7, 40H); (*done; STATUS <= clear RX_DR*); 
    SYSTEM.PUT(netSelectOut, 1)
  END SubRcv;

  PROCEDURE doSubSend(src, len: INTEGER; VAR timeout: BOOLEAN);
    VAR i, res, t1, try: INTEGER; x, dat, status: BYTE;
  BEGIN (*already in xmit mode*)
    ASSERT(len-1 IN {0..SubPacket-1});
    StartCmd(0A0H); (*W_TX_PAYLOAD*)
    FOR i := 0 TO len-1 DO
      SYSTEM.GET(src+i, dat); SPIw(dat)
    END;
    SYSTEM.PUT(netSelectOut, 1); (*end W_TX_PAYLOAD command*)
    try := 0;
    SYSTEM.PUT(netEnableOut, 1); (*start xmit pulse, start NOP cmd*)
    REPEAT
      t1 := Kernel.Time();
      REPEAT (*wait for sent or retransmits exceeded*);
        SYSTEM.PUT(netSelectOut, 0); 
        SPIr(status); (*NOP*)
        res := status DIV 10H MOD 4;
        SYSTEM.PUT(netEnableOut, 0); SYSTEM.PUT(netSelectOut, 1); (*end & restart NOP cmd, end =10us pulse on enable*)
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
  END doSubSend;

  PROCEDURE SubSnd(src: INTEGER; VAR timeout: BOOLEAN);
    VAR i, data: INTEGER;
  BEGIN
    doSubSend(src, SubPacket, timeout);
    IF ~timeout THEN 
      FOR i := 0 TO SubPacket-4 BY 4 DO (*Compute CRC*)
        SYSTEM.GET(src+i, data); SYSTEM.PUT(CRCBase+CRCDR, data)
      END
    END
  END SubSnd;

  PROCEDURE SubRcVReq(VAR timeout: BOOLEAN);
    VAR payload: ARRAY 1 OF BYTE;
  BEGIN
    payload[0] := 0; doSubSend(SYSTEM.ADR(payload), 1, timeout);
  END SubRcVReq;
  
  PROCEDURE Flush;
  BEGIN StartCmd(0E1H); SYSTEM.PUT(netSelectOut, 1); StartCmd(0E2H); SYSTEM.PUT(netSelectOut, 1)
(*FLUSH_TX, FLUSH_RX*)
  END Flush;

  PROCEDURE ResetRcv;
  BEGIN SYSTEM.PUT(SYSTEM.ADR(rx), 0); rx.hd.len := 0; rcvd := 0
  END ResetRcv;

  PROCEDURE PowerUp;
  BEGIN WriteReg1(0, 7EH); (*CONFIG <= mask ints; EN_CRC(2 byte), PWR_UP, PTX*)
  END PowerUp;

  PROCEDURE Start*(channel: BYTE; pipeName: ARRAY OF CHAR);
    VAR len: INTEGER;
  BEGIN SYSTEM.PUT(netEnableOut, 0); Delayms(5);
    len := 0; WHILE (len < LEN(pipeName)) & (pipeName[len] # 0X) DO INC(len) END;
    WriteReg1(0, 7CH); (*CONFIG <= mask ints; EN_CRC(2 byte), PWR_DOWN, PTX*)
    Flush; WriteReg1(7, 70H); (*STATUS <= clear ints*)
    WriteReg1(5, channel); (*RF_CH <= channel: 5, 15, 25...*)
    WriteReg1(6, 22H); (*RF_SETUP = 250kb for better range, -12dBm*)
    WriteReg1(1, 3FH); (*EN_AA enable Enable 'Auto Acknowledgment' on all pipes*)
    WriteReg1(2, 1); (*EN_RXADDR enable pipe 0*)
    ASSERT(len IN {3..5});
    WriteReg1(3, len-2); (*SETUP_AW setup address length*)
    WriteRegN(0AH, pipeName, len); (*RX_ADDR_P0 define pipe 0 receive address*)
    WriteRegN(10H, pipeName, len); (*TX_ADDR define pipe transmit address*)
    WriteReg1(11H, 0); (*RX_PW_P0 <= pipe 0 payload width = 0 to allow ACK payload*)
    WriteReg1(1CH, 1); (*DYNPD Enable dynamic payload length data pipe 0. (Requires EN_DPL and ENAA_P0)*)
    WriteReg1(1DH, 6); (*FEATURE Enables Dynamic Payload Length and Payload with ACK*)
    WriteReg1(4, 63H); (*SETUP_RETR ARD = 1750µs, ARC = 3*)
    Flush(); ResetRcv
  END Start;

  PROCEDURE SendPacket*(VAR head: Header; dat: ARRAY OF BYTE);
    VAR len, i, off: INTEGER; timeout: BOOLEAN; 
    payload: ARRAY SubPacket OF BYTE;
  BEGIN PowerUp;
    head.valid := TRUE; SYSTEM.PUT(CRCReset, 1); (*Reset STM32 CRC Unit*)
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
    SYSTEM.GET(CRCBase + CRCDR, off); SYSTEM.PUT(SYSTEM.ADR(payload), off); (*send CRC*)
    i := 4; WHILE i < SubPacket DO payload[i] := 0; INC(i) END;
    SubSnd(SYSTEM.ADR(payload), timeout)
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
    VAR status, fifoStatus: BYTE; rcvd, timeout: BOOLEAN;
      t1: INTEGER;
  BEGIN t1 := Kernel.Time();
    REPEAT
      SubRcVReq(timeout);
      IF ~timeout THEN
        SYSTEM.PUT(netSelectOut, 0); SPIrw(17H, status); (*R_REGISTER FIFO_STATUS*)
        SPIr(fifoStatus); SYSTEM.PUT(netSelectOut, 1);
        rcvd := ODD(status DIV 40H) OR ~ODD(fifoStatus) (*RX_DR (data ready) or RX FIFO not empty*)
      END
    UNTIL rcvd OR (Kernel.Time() - t1 >= time);
    RETURN rcvd
  END Rcvd;

  PROCEDURE ReceiveHead*(VAR head: Header);  (*actually, recv whole packet*)
    VAR adr, data, n: INTEGER; len: BYTE;
  BEGIN PowerUp;
    head.valid := FALSE; SYSTEM.PUT(CRCReset, 1); (*Reset STM32 CRC Unit*)
    IF Rcvd(0) THEN
      ResetRcv; adr := SYSTEM.ADR(rx); SubRcv(adr, len);
      n := rx.hd.len + HdrSize - len;
      IF rx.hd.len <= MaxPayload THEN
        WHILE (n > 0) & Rcvd(Wait) DO
          INC(adr, len); SubRcv(adr, len); DEC(n, len)
        END;
        SubRcv(adr, len); SYSTEM.GET(CRCBase+CRCDR, data); (*Check CRC*)
        IF data = 0 THEN rx.hd.valid := (n = 0) ELSE rx.hd.valid := FALSE END
      ELSE WHILE Rcvd(Wait) DO SubRcv(adr, len) END; ResetRcv  (*discard packet*)
      END;
      head := rx.hd
    END
  END ReceiveHead;

  PROCEDURE Skip*(m: INTEGER);
    VAR dmy: BYTE;
  BEGIN WHILE m # 0 DO Receive(dmy); DEC(m) END
  END Skip;

  PROCEDURE Stop*;
  BEGIN SYSTEM.PUT(netSelectOut, 1); SYSTEM.PUT(netEnableOut, 0); Flush(); ResetRcv
  END Stop;

END SCC.
