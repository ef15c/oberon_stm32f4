MODULE SCC; (*NW 13.11.87 / 22.8.90 Ceres-2; nRF24L01+ version PR 21.7.13 / 23.12.13
  CS 21/01/2024*)
  IMPORT SYSTEM, Kernel, Texts, TextsEx;

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
    SPI3Base = 40003C00H; DR = 0CH; SR = 8; CR1 = 0;
    spiData = SPI3Base + DR; spiSR = SPI3Base + SR; spiCR1 = SPI3Base + CR1;
    RXNE = 0; TXE = 1; BSY = 7;
    SPE = 6;
    spiEnable = PeriphBBAlias + (spiCR1 - PeriphBase + SPE DIV 8)*32 + SPE MOD 8*4;

    (*CRC*)
    CRCBase = 40023000H; CRCDR = 0; CR = 8;
    CRCReset = PeriphBBAlias + (CRCBase + CR - PeriphBase)*32;

    (*DWT*)
    DWTBase = 0E0001000H;  CYCCNT = 4;
    HCLCFREQ = 168;
    
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
      dat: ARRAY MaxPacket-HdrSize+4 OF BYTE
    END;

  PROCEDURE Delayms(d: INTEGER);
    VAR beg: INTEGER;
  BEGIN beg := Kernel.Time();
    REPEAT UNTIL Kernel.Time() - beg > d
  END Delayms;
  
  PROCEDURE Delayus(d: INTEGER);
    VAR beg, now: INTEGER;
  BEGIN SYSTEM.GET(DWTBase + CYCCNT, beg);
    REPEAT SYSTEM.GET(DWTBase + CYCCNT, now) UNTIL now - beg >= HCLCFREQ*d
  END  Delayus;

  PROCEDURE SPIn(src, dst, n: INTEGER);
    VAR sc, rc: INTEGER; data: BYTE;
  BEGIN (*send/rcv n bytes to/from SPI*) ASSERT(n>0);
    sc := 0; rc := 0;
    REPEAT 
      IF SYSTEM.BIT(spiSR, TXE) & (sc < n) THEN (*TX buffer is empty*) 
        SYSTEM.GET(src+sc, data); SYSTEM.PUT(spiData, data); INC(sc)
      END;
      IF SYSTEM.BIT(spiSR, RXNE) & (rc < n) THEN (*RX buffer is not empty*)
        SYSTEM.GET(spiData, data); SYSTEM.PUT(dst+rc, data); INC(rc)
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

  PROCEDURE ReadReg1*(reg: BYTE; VAR dat: BYTE);
  BEGIN ASSERT((reg <= 17H) OR (reg = 1CH) OR (reg = 1DH));
    StartCmd(reg); SPIr(dat); SYSTEM.PUT(netSelectOut, 1) (*R_REGISTER*)
  END ReadReg1;

  PROCEDURE WriteReg1(reg, dat: BYTE);
  BEGIN StartCmd(reg + 20H); SPIw(dat); SYSTEM.PUT(netSelectOut, 1) (*W_REGISTER*)
  END WriteReg1;

  PROCEDURE ReadRegN*(reg: BYTE; VAR dat: ARRAY OF BYTE; len: INTEGER);
    VAR i: INTEGER;
  BEGIN ASSERT((reg <= 17H) OR (reg = 1CH) OR (reg = 1DH));
    StartCmd(reg);
    FOR i := 0 TO len - 1 DO SPIr(dat[i]) END; SYSTEM.PUT(netSelectOut, 1) (*W_REGISTER*)
  END ReadRegN;

  PROCEDURE WriteRegNC(reg: BYTE; dat: ARRAY OF CHAR; len: INTEGER);
    VAR i: INTEGER;
  BEGIN StartCmd(reg + 20H);
    FOR i := 0 TO len - 1 DO SPIw(ORD(dat[i])) END; SYSTEM.PUT(netSelectOut, 1) (*W_REGISTER*)
  END WriteRegNC;

  PROCEDURE SubRcv(dst: INTEGER; VAR len: BYTE);
    VAR i, data: INTEGER; dat: BYTE;
  BEGIN
    StartCmd(60H); SPIr(len); (*R_RX_PL_WID*)
    SYSTEM.PUT(netSelectOut, 1);
    ASSERT(len MOD 4 = 0);
    ASSERT(len > 0);
    IF len <= 32 THEN
      StartCmd(61H); (*R_RX_PAYLOAD*)
      FOR i := 0 TO len-1 DO
        SPIr(dat); SYSTEM.PUT(dst+i, dat)
      END;
      SYSTEM.PUT(netSelectOut, 1);
      FOR i := 0 TO len-4 BY 4 DO (*Compute CRC*)
        SYSTEM.GET(dst+i, data); SYSTEM.PUT(CRCBase+CRCDR, data)
      END
    ELSE len := 0
    END;
    WriteReg1(7, 40H); (*done; STATUS <= clear RX_DR*)
  END SubRcv;

  PROCEDURE Flush;
  BEGIN StartCmd(0E1H); SYSTEM.PUT(netSelectOut, 1); StartCmd(0E2H); SYSTEM.PUT(netSelectOut, 1)
(*FLUSH_TX, FLUSH_RX*)
  END Flush;

  PROCEDURE doSubSend(src, len: INTEGER; VAR timeout: BOOLEAN);
    VAR i, res: INTEGER; x, dat, status: BYTE;
  BEGIN
    ASSERT(len-1 IN {0..SubPacket-1});
    StartCmd(0A0H); (*W_TX_PAYLOAD*)
    FOR i := 0 TO len-1 DO
      SYSTEM.GET(src+i, dat); SPIw(dat)
    END;
    SYSTEM.PUT(netSelectOut, 1); (*end W_TX_PAYLOAD command*)
    SYSTEM.PUT(netEnableOut, 1); (*start xmit pulse*); Delayus(12); SYSTEM.PUT(netEnableOut, 0);
    REPEAT Delayms(1); SYSTEM.PUT(netSelectOut, 0); SPIr(status); (*NOP*); SYSTEM.PUT(netSelectOut, 1);
      res := status DIV 10H MOD 4
    UNTIL res # 0;
    WriteReg1(7, 30H); (*reset TX_DS and/or MAX-RT*)
    IF res = 1 THEN (*MAX-RT*) StartCmd(0E1H); SYSTEM.PUT(netSelectOut, 1) END;
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
  
  PROCEDURE ResetRcv;
  BEGIN SYSTEM.PUT(SYSTEM.ADR(rx), 0); rx.hd.len := 0; rcvd := 0
  END ResetRcv;

  PROCEDURE PowerUp;
  BEGIN WriteReg1(0, 7EH); (*CONFIG <= mask ints; EN_CRC(2 byte), PWR_UP, PTX*)
    Delayms(5)
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
    WriteRegNC(0AH, pipeName, len); (*RX_ADDR_P0 define pipe 0 receive address*)
    WriteRegNC(10H, pipeName, len); (*TX_ADDR define pipe transmit address*)
    WriteReg1(11H, 0); (*RX_PW_P0 <= pipe 0 payload width = 0 because of dynamic payload*)
    WriteReg1(1CH, 1); (*DYNPD Enable dynamic payload length data pipe 0. (Requires EN_DPL and ENAA_P0)*)
    WriteReg1(1DH, 6); (*FEATURE Enables Dynamic Payload Length and Payload with ACK*)
    WriteReg1(4, 63H); (*SETUP_RETR ARD = 1750�s, ARC = 3*)
    Flush(); ResetRcv
  END Start;

  PROCEDURE PrintReg1(VAR W: Texts.Writer; n: BYTE; t: ARRAY OF CHAR; VAR dat: BYTE);
  BEGIN ReadReg1(n, dat); Texts.WriteString(W, t);  Texts.WriteString(W, " = "); 
    TextsEx.WriteHexVLen(W, dat, 2, FALSE); Texts.WriteLn(W)
  END PrintReg1;
  
  PROCEDURE PrintRegN(VAR W: Texts.Writer; n: BYTE; t: ARRAY OF CHAR; len: INTEGER);
    VAR dat: ARRAY 5 OF BYTE; i: INTEGER;
  BEGIN ReadRegN(n, dat, len); Texts.WriteString(W, t);  Texts.WriteString(W, " = "); 
    FOR i := 0 TO len-1 DO TextsEx.WriteHexVLen(W, dat[i], 1, FALSE) END; Texts.WriteLn(W)
  END PrintRegN;
  
  PROCEDURE PrintConfig*(VAR W: Texts.Writer);
    VAR dat: BYTE; data: INTEGER;
  BEGIN Texts.WriteString(W, "nRF24l01+:"); Texts.WriteLn(W);
    PrintReg1(W, 0, "CONFIG", dat); PrintReg1(W, 7, "STATUS", dat); PrintReg1(W, 17H, "FIFO_STATUS", dat);
    PrintReg1(W, 5, "RF_CH", dat); PrintReg1(W, 6, "RF_SETUP", dat);
    PrintReg1(W, 1, "EN_AA", dat); PrintReg1(W, 2, "EN_RXADDR", dat);
    PrintReg1(W, 3, "SETUP_AW", dat); PrintRegN(W, 0AH, "RX_ADDR_P0", dat+2);
    PrintRegN(W, 10H, "TX_ADDR", dat+2); PrintReg1(W, 11H, "RX_PW_P0", dat);
    PrintReg1(W, 1CH, "DYNPD", dat); PrintReg1(W, 1DH, "FEATURE", dat);
    PrintReg1(W, 4, "SETUP_RETR", dat);
    SYSTEM.GET(DWTBase + CYCCNT, data); Texts.WriteString(W, "CYCCNT = "); Texts.WriteInt(W, data, 1); Texts.WriteLn(W)
  END PrintConfig;
  
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
	IF ~timeout THEN
      SYSTEM.GET(CRCBase + CRCDR, off); SYSTEM.PUT(SYSTEM.ADR(payload), off); (*send CRC*)
      i := 4; WHILE i < SubPacket DO payload[i] := 0; INC(i) END;
      SubSnd(SYSTEM.ADR(payload), timeout)
    END
  END SendPacket;

  PROCEDURE Available*(): INTEGER;
  BEGIN (*packet already rcvd*)
    RETURN rx.hd.len - rcvd
  END Available;

  PROCEDURE Receive*(VAR x: BYTE);
  BEGIN (*packet already rcvd*)
    IF rcvd < rx.hd.len THEN x := rx.dat[rcvd]; INC(rcvd) ELSE x := 0 END
  END Receive;

  PROCEDURE RXFIFOAvail(): BOOLEAN;
    VAR status, fifoStatus: BYTE;
  BEGIN
      SYSTEM.PUT(netSelectOut, 0); SPIrw(17H, status); (*R_REGISTER FIFO_STATUS*)
      SPIr(fifoStatus); SYSTEM.PUT(netSelectOut, 1);
      RETURN (status DIV 2 MOD 8 # 7) & (ODD(status DIV 40H) OR ~ODD(fifoStatus)) (*RX_DR (data ready) or RX FIFO not empty*)
  END RXFIFOAvail;

  PROCEDURE Rcvd(time: INTEGER): BOOLEAN;
    VAR status, fifoStatus: BYTE; rcvd, timeout: BOOLEAN;
      t1: INTEGER;
  BEGIN t1 := Kernel.Time();
    IF RXFIFOAvail() THEN rcvd := TRUE
    ELSE rcvd := FALSE;
      REPEAT SubRcVReq(timeout);
        IF ~timeout THEN rcvd := RXFIFOAvail() END;
        IF ~rcvd THEN Delayms(100) END
      UNTIL rcvd OR (Kernel.Time() - t1 >= time)
    END;
    RETURN rcvd
  END Rcvd;

  PROCEDURE ReceiveHead*(VAR head: Header);  (*actually, recv whole packet*)
    VAR adr, data, n: INTEGER; len: BYTE;
  BEGIN PowerUp;
    head.valid := FALSE; SYSTEM.PUT(CRCReset, 1); (*Reset STM32 CRC Unit*)
    IF Rcvd(10) THEN
      ResetRcv; adr := SYSTEM.ADR(rx); SubRcv(adr, len); LED(len);
      n := rx.hd.len + HdrSize - len;
      IF rx.hd.len <= MaxPayload THEN
        WHILE (n > 0) & Rcvd(Wait) DO
          INC(adr, len); SubRcv(adr, len); DEC(n, len)
        END;
        IF (n <= 0) & Rcvd(Wait) THEN INC(adr, len); SubRcv(adr, len); SYSTEM.GET(CRCBase+CRCDR, data); (*Check CRC*)
          IF data = 0 THEN rx.hd.valid := (n <= 0) ELSE rx.hd.valid := FALSE; ResetRcv END;
        ELSE ResetRcv  (*discard packet*)
        END
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

  PROCEDURE Wait1Sec*;
  BEGIN Delayms(1000)
  END Wait1Sec;

  PROCEDURE ShowRxPacket*(VAR W: Texts.Writer);
    VAR i, adr: INTEGER; dat: BYTE;
  BEGIN
    adr := SYSTEM.ADR(rx);
    FOR i := 0 TO (rx.hd.len + HdrSize +  SubPacket -1) DIV SubPacket*SubPacket + 3 DO SYSTEM.GET(adr + i, dat);
      TextsEx.WriteHexVLen(W, dat, 2, FALSE); 
      IF i MOD 32 = 31 THEN Texts.WriteLn(W) END
    END;
    Texts.WriteLn(W)
  END ShowRxPacket;

BEGIN SYSTEM.PUT(spiEnable, TRUE)
END SCC.