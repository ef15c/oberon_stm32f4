(*
OM4P.Compile @  
OM4X.WriteASM BootLoadM4.m4c BootLoadM4.s ~
OM4X.WriteFile BootLoadM4.m4c BootLoadM4.hex 0F000000H ~
*)

MODULE* BootLoad;  (*NW 20.10.2013 / PR 4.2.2014 / CS 09/12/2023; boot from SDHC disk only*)
  IMPORT SYSTEM, BSP;
  CONST SP = 13; LR = 14; PC = 15; (*dedicated registers*) PSP = 16+9; CONTROL = 16+20; (*special registers*)
    VarORG0 = 0D0201000H; MemLim = 0D0800000H; stackOrg = 10010000H;
    SDHandleDescAddr = 200001ACH;

    (*Peripherals*)
    PeriphBase = 40000000H; PeriphBBAlias = 42000000H;

    BLOCKSIZE = 512;
    FSoffset = 80000H; (*block offset*) SectorSize = 1024; bps = SectorSize DIV BLOCKSIZE;

    (*common error flag*) NONE = {}; 

    (*SDIO error flags*) CMD_CRC_FAIL = {0}; DATA_CRC_FAIL = {1}; CMD_RSP_TIMEOUT = {2}; DATA_TIMEOUT = {3}; TX_UNDERRUN = {4};
      RX_OVERRUN = {5}; ADDR_MISALIGNED = {6}; BLOCK_LEN_ERR = {7}; ERASE_SEQ_ERR = {8}; BAD_ERASE_PARAM = {9};
      WRITE_PROT_VIOLATION = {10}; LOCK_UNLOCK_FAILED = {11}; COM_CRC_FAILED = {12}; ILLEGAL_CMD = {13}; CARD_ECC_FAILED = {14};
      CC_ERR = {15}; GENERAL_UNKNOWN_ERR = {16}; STREAM_READ_UNDERRUN= {17}; STREAM_WRITE_OVERRUN = {18};
      CID_CSD_OVERWRITE = {19}; WP_ERASE_SKIP = {20}; CARD_ECC_DISABLED = {21}; ERASE_RESET = {22}; AKE_SEQ_ERR = {23};
      INVALID_VOLTAGE = {24}; ADD_OUT_OF_RANGE = {25}; REQUEST_NOT_APPLICABLE = {26}; INVALID_PARAMETER = {27};
      UNSUPPORTED_FEATURE = {28}; BUSY = {29}; ERROR_DMA = {30}; ERROR_TIMEOUT = {31};

    (*OCR flags*) OCR_ADDR_OUT_OF_RANGE = {31}; OCR_ADDR_MISALIGNED = {30}; OCR_BLOCK_LEN_ERR = {29};
      OCR_ERASE_SEQ_ERR = {28}; OCR_BAD_ERASE_PARAM = {27}; OCR_WRITE_PROT_VIOLATION = {26}; OCR_LOCK_UNLOCK_FAILED = {24};
      OCR_COM_CRC_FAILED = {23}; OCR_ILLEGAL_CMD = {22}; OCR_CARD_ECC_FAILED = {21}; OCR_CC_ERROR = {20};
      OCR_GENERAL_UNKNOWN_ERROR =  {19}; OCR_STREAM_READ_UNDERRUN = {18}; OCR_STREAM_WRITE_OVERRUN = {17};
      OCR_CID_CSD_OVERWRITE = {16}; OCR_WP_ERASE_SKIP = {15}; OCR_CARD_ECC_DISABLED = {14}; OCR_ERASE_RESET = {13};
      OCR_AKE_SEQ_ERROR = {3}; OCR_ERRORBITS = {3, 13..24, 26..31};

    (*R6 responses*) R6_GENERAL_UNKNOWN_ERROR = {13}; R6_ILLEGAL_CMD = {14}; R6_COM_CRC_FAILED = {15};
    (*card version*) CARD_V1_X = 0; CARD_V2_X = 1;

    (*card type*) CARD_SDSC = 0; CARD_SDHC_SDXC = 1;
    (*card states*) CARD_READY = 1; CARD_IDENTIFICATION = 2; CARD_STANDBY = 3; CARD_TRANSFER = 4; CARD_SENDING = 5;
      CARD_RECEIVING = 6; CARD_PROGRAMMING = 7; CARD_DISCONNECTED = 8; CARD_ERROR = 0FFH;

    (*SD commands*) CMD_GO_IDLE_STATE = SYSTEM.VAL(SET, 0); CMD_ALL_SEND_CID = SYSTEM.VAL(SET, 2);
      CMD_SET_REL_ADR = SYSTEM.VAL(SET, 3); CMD_SEL_DESEL_CARD = SYSTEM.VAL(SET, 7); 
      CMD_SEND_IF_COND = SYSTEM.VAL(SET, 8); CMD_SEND_CSD = SYSTEM.VAL(SET, 9);
      CMD_STOP_TRANSMISSION = SYSTEM.VAL(SET, 12); CMD_SEND_STATUS = SYSTEM.VAL(SET, 13);
      CMD_SET_BLOCKLEN = SYSTEM.VAL(SET, 16);
      CMD_READ_SINGLE_BLOCK = SYSTEM.VAL(SET, 17); CMD_READ_MULT_BLOCK = SYSTEM.VAL(SET, 18);
      CMD_WRITE_SINGLE_BLOCK = SYSTEM.VAL(SET, 24); CMD_WRITE_MULT_BLOCK = SYSTEM.VAL(SET, 25);
      CMD_APP_CMD = SYSTEM.VAL(SET, 55);
    (*Application specific commands*) CMD_APP_SET_BUS_WIDTH = SYSTEM.VAL(SET, 6);
      CMD_APP_SET_WR_BLK_ERASE_COUNT = SYSTEM.VAL(SET, 23);
      CMD_APP_SEND_OP_COND = SYSTEM.VAL(SET, 41); CMD_APP_SEND_SCR = SYSTEM.VAL(SET, 51);

    (*ACM41 parameters*) VOLTAGE_WINDOW_SD = {31, 17}; HIGH_CAPACITY = {30}; SWITCH_1_8V_CAPACITY = {24};

    (*SCR flags*) WIDE_BUS_SUPPORT = 18; SINGLE_BIT_BUS_SUPPORT = 16;

    ARG =  BSP.SDIO_BASE + BSP.ARG; CMD =  BSP.SDIO_BASE + BSP.CMD; RESPCMD = BSP.SDIO_BASE + BSP.RESPCMD;
    RESP1 = BSP.SDIO_BASE + BSP.RESP1; RESP2 = BSP.SDIO_BASE + BSP.RESP1 + 4;  RESP3 = BSP.SDIO_BASE + BSP.RESP1 + 8;
    RESP4 = BSP.SDIO_BASE + BSP.RESP1 + 0CH; 
    DTIMER = BSP.SDIO_BASE + BSP.DTIMER; DLEN = BSP.SDIO_BASE + BSP.DLEN;
    DCTRL = BSP.SDIO_BASE + BSP.DCTRL; MASK = BSP.SDIO_BASE + BSP.MASK; FIFO = BSP.SDIO_BASE + BSP.FIFO;
    STA = BSP.SDIO_BASE + BSP.STA; ICR = BSP.SDIO_BASE + BSP.ICR;

    DCTRL_CLEAR_MASK = BSP.DTENm + BSP.DTDIRm + BSP.DTMODEm + BSP.DBLOCKSIZEm;
    CMD_CLEAR_MASK = BSP.CMDINDEXm + BSP.WAITRESPm + BSP.WAITINTm + BSP.WAITPENDm + BSP.CPSMENm + BSP.SDIOSuspendm;

    STATIC_CMD_FLAGS = BSP.CCRCFAILm + BSP.CTIMEOUTm + BSP.CMDRENDm + BSP.CMDSENTm;
    STATIC_DATA_FLAGS = BSP.DCRCFAILm + BSP.DTIMEOUTm + BSP.TXUNDERRm + BSP.RXOVERRm + BSP.DATAENDm + BSP.DBCKENDm + BSP.STBITERRm;
    STATIC_FLAGS = STATIC_CMD_FLAGS + STATIC_DATA_FLAGS + BSP.SDIOITm;

    STREAM3_BASE = BSP.DMA2_BASE + BSP.STREAM_PARAM_SIZE*3;
      s3En = BSP.PeriphBBAlias + (STREAM3_BASE + BSP.SxCR - BSP.PeriphBase + BSP.SxCR_EN DIV 8)*32 + BSP.SxCR_EN MOD 8*4;

    STREAM6_BASE = BSP.DMA2_BASE + BSP.STREAM_PARAM_SIZE*6;
      s6En = BSP.PeriphBBAlias + (STREAM6_BASE + BSP.SxCR - BSP.PeriphBase + BSP.SxCR_EN DIV 8)*32 + BSP.SxCR_EN MOD 8*4;

  TYPE
    SDCardInfoDesc = RECORD
      CardType, CardVersion, Class, RelCardAdd, BlockNbr, BlockSize, LogBlockNbr, LogBlockSize: INTEGER
    END;

    SDHandleDesc = RECORD
      ErrorCode: SET;
      SdCard: SDCardInfoDesc;
      CID, CSD: ARRAY 4 OF INTEGER;
      readErrors, writeErrors, unrecoverableErrors: INTEGER;
      buf: INTEGER (*address of data buffer*)
    END;
    SDHandle = POINTER TO SDHandleDesc;

    SDCardCSDDesc = RECORD
      CSDStruct (*CSD structure*),
      TAAC (*Data read access time 1*), NSAC (*Data read access time 2 in CLK cycles*), MaxBusClkFreq (*Max. bus clock frequency*): BYTE;
      CardComdClasses (*Card command classes*): INTEGER;
      RdBlockLen (*Max. read data block length*): BYTE;
      PartBlockRead (*Partial blocks for read allowed*), WrBlockMisalign (*Write block misalignment*), RdBlockMisalign (*Read block misalignment*),
      DSRImpl (*DSR implemented*): BOOLEAN;
      DeviceSize (*Device Size*): INTEGER;
      MaxRdCurrentVDDMin (*Max. read current @ VDD min*), MaxRdCurrentVDDMax (*Max. read current @ VDD max*),
      MaxWrCurrentVDDMin (*Max. write current @ VDD min*), MaxWrCurrentVDDMax (*Max. write current @ VDD max*),
      DeviceSizeMul (*Device size multiplier*): BYTE;
      EraseBlkEn (*Erase single group enabled*): BOOLEAN;
      SectorSize (*erase sector size*), WrProtectGrSize (*Write protect group size*): BYTE;
      WrProtectGrEnable (*Write protect group enabled*): BOOLEAN;
      WrSpeedFact (*Write speed factor*), MaxWrBlockLen (*Max. write data block length*): BYTE;
      WriteBlockPartial (*Partial blocks for write allowed*): BOOLEAN;
      FileFormatGroup (*File format group*): BYTE;
      CopyFlag (*Copy flag (OTP)*), PermWrProtect (*Permanent write protection*), TempWrProtect (*Temporary write protection*): BOOLEAN;
      FileFormat (*File format*), CSD_CRC (*CSD CRC*): BYTE
    END;

  PROCEDURE Delayus*(d: INTEGER);
    VAR beg, now: INTEGER;
  BEGIN SYSTEM.GET(BSP.DWTBase + BSP.CYCCNT, beg);
    REPEAT SYSTEM.GET(BSP.DWTBase + BSP.CYCCNT, now) UNTIL now - beg >= BSP.HCLKFreq*d
  END  Delayus;

  PROCEDURE reverseBytes(d: INTEGER): INTEGER;
  BEGIN
    RETURN LSL(d MOD 100H, 24) + LSL(LSR(d, 8) MOD 100H, 16) + LSL(LSR(d, 16) MOD 100H, 8) + LSR(d, 24) MOD 100H
  END reverseBytes;

  PROCEDURE WaitForCmd;
    VAR rc, reg: SET;
  BEGIN rc := NONE;
    REPEAT SYSTEM.GET(STA, reg) UNTIL (reg*BSP.CMDSENTm # {}) & (reg*BSP.CMDACTm = {})
  END WaitForCmd;

  PROCEDURE GetCmdResp1(cmd: SET): SET;
    VAR rc, reg: SET;
  BEGIN REPEAT SYSTEM.GET(STA, rc) UNTIL (rc*(BSP.CCRCFAILm + BSP.CMDRENDm + BSP.CTIMEOUTm) # {}) & (rc*BSP.CMDACTm = {}); (*wait for response*)
    rc := rc*(BSP.CTIMEOUTm + BSP.CCRCFAILm);
    SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear cmd static flags*)
    IF rc = NONE THEN
      SYSTEM.GET(RESPCMD, reg);
      IF reg # cmd THEN rc := ILLEGAL_CMD (*response is not from the desired command*)
      ELSE SYSTEM.GET(RESP1, reg); (*we have received a response, retrieve it for analysis*)
        IF reg*OCR_ERRORBITS # {} THEN
          IF reg*OCR_ADDR_OUT_OF_RANGE # {} THEN rc := ADD_OUT_OF_RANGE
          ELSIF reg*OCR_ADDR_MISALIGNED # {} THEN rc := ADDR_MISALIGNED
          ELSIF reg*OCR_BLOCK_LEN_ERR # {} THEN rc := BLOCK_LEN_ERR
          ELSIF reg*OCR_ERASE_SEQ_ERR # {} THEN rc := ERASE_SEQ_ERR
          ELSIF reg*OCR_BAD_ERASE_PARAM # {} THEN rc := BAD_ERASE_PARAM
          ELSIF reg*OCR_WRITE_PROT_VIOLATION # {} THEN rc := WRITE_PROT_VIOLATION
          ELSIF reg*OCR_LOCK_UNLOCK_FAILED # {} THEN rc := LOCK_UNLOCK_FAILED
          ELSIF reg*OCR_COM_CRC_FAILED # {} THEN rc := COM_CRC_FAILED
          ELSIF reg*OCR_ILLEGAL_CMD # {} THEN rc := ILLEGAL_CMD
          ELSIF reg*OCR_CARD_ECC_FAILED # {} THEN rc := CARD_ECC_FAILED
          ELSIF reg*OCR_CC_ERROR # {} THEN rc := CC_ERR
          ELSIF reg*OCR_STREAM_READ_UNDERRUN # {} THEN rc := STREAM_READ_UNDERRUN
          ELSIF reg*OCR_STREAM_WRITE_OVERRUN # {} THEN rc := STREAM_WRITE_OVERRUN
          ELSIF reg*OCR_CID_CSD_OVERWRITE # {} THEN rc := CID_CSD_OVERWRITE
          ELSIF reg*OCR_WP_ERASE_SKIP # {} THEN rc := WP_ERASE_SKIP
          ELSIF reg*OCR_CARD_ECC_DISABLED # {} THEN rc := CARD_ECC_DISABLED
          ELSIF reg*OCR_ERASE_RESET # {} THEN rc := ERASE_RESET
          ELSIF reg*OCR_AKE_SEQ_ERROR # {} THEN rc := AKE_SEQ_ERR
          ELSE rc := GENERAL_UNKNOWN_ERR
          END
        END
      END
    END;

    RETURN rc
  END GetCmdResp1;

  PROCEDURE GetCmdResp3(): SET;
    VAR reg: SET;
  BEGIN
    REPEAT SYSTEM.GET(STA, reg) UNTIL (reg*(BSP.CCRCFAILm + BSP.CMDRENDm + BSP.CTIMEOUTm) # {}) & (reg*BSP.CMDACTm = {}); (*wait for response*)
    reg := reg*(BSP.CTIMEOUTm);
    SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear cmd static flags*)

    RETURN reg
  END GetCmdResp3;

  PROCEDURE GetCmdResp6(cmd: SET; VAR rca: INTEGER): SET;
    VAR rc, reg: SET;
  BEGIN rc := NONE;
    REPEAT SYSTEM.GET(STA, rc) UNTIL (rc*(BSP.CCRCFAILm + BSP.CMDRENDm + BSP.CTIMEOUTm) # {}) & (rc*BSP.CMDACTm = {}); (*wait for response*)
    rc := rc*(BSP.CTIMEOUTm + BSP.CCRCFAILm);
    SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear cmd static flags*)
    IF rc = NONE THEN
      SYSTEM.GET(RESPCMD, reg);
      IF reg # cmd THEN rc := ILLEGAL_CMD (*response is not from the desired command*)
      ELSE SYSTEM.GET(RESP1, reg); (*we have received a response, retrieve it for analysis*)
        IF reg*(R6_GENERAL_UNKNOWN_ERROR + R6_ILLEGAL_CMD + R6_COM_CRC_FAILED) = {} THEN rca := LSR(ORD(reg), 16)
        ELSIF reg*R6_ILLEGAL_CMD # {} THEN rc := ILLEGAL_CMD
        ELSIF reg*R6_COM_CRC_FAILED # {} THEN rc := COM_CRC_FAILED
        ELSE rc := GENERAL_UNKNOWN_ERR
        END
      END
    END;

    RETURN rc
  END GetCmdResp6;

  PROCEDURE GetCmdResp2or7(): SET;
    VAR reg: SET;
  BEGIN
    REPEAT SYSTEM.GET(STA, reg) UNTIL (reg*(BSP.CCRCFAILm + BSP.CMDRENDm + BSP.CTIMEOUTm) # {}) & (reg*BSP.CMDACTm = {}); (*wait for response*)
    reg := reg*(BSP.CTIMEOUTm + BSP.CCRCFAILm);
    SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear cmd static flags*)

    RETURN reg
  END GetCmdResp2or7;

  PROCEDURE GetCardState(VAR hsd: SDHandleDesc): INTEGER;
    VAR reg: SET;
  BEGIN SYSTEM.PUT(ARG, LSL(hsd.SdCard.RelCardAdd, 16)); SYSTEM.GET(CMD, reg);
    SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_SEND_STATUS + BSP.RESPONSE_SHORT + BSP.CPSMENm));
    hsd.ErrorCode := hsd.ErrorCode + GetCmdResp1(CMD_SEND_STATUS); (*check response*)
    SYSTEM.GET(RESP1, reg);

    RETURN LSR(ORD(reg), 9) MOD 16
  END GetCardState;

  PROCEDURE CmdStopTransfer(): SET;
    VAR reg: SET;
  BEGIN
    SYSTEM.PUT(ARG, 0); SYSTEM.GET(CMD, reg);
    SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_STOP_TRANSMISSION + BSP.RESPONSE_SHORT + BSP.CPSMENm));

    RETURN GetCmdResp1(CMD_STOP_TRANSMISSION) (*check response*)
  END CmdStopTransfer;

  PROCEDURE SDReadBlocksDMA*(VAR hsd: SDHandleDesc; pData, blockAdd, nofBlocks: INTEGER): SET;
    VAR reg, lisr, sta: SET;
  BEGIN hsd.ErrorCode := NONE;
    IF nofBlocks < 1 THEN hsd.ErrorCode := INVALID_PARAMETER END;
    IF blockAdd + nofBlocks > hsd.SdCard.LogBlockNbr THEN hsd.ErrorCode := ADD_OUT_OF_RANGE END;
    IF hsd.ErrorCode = NONE THEN
      SYSTEM.PUT(DCTRL, 0); (*Initialize data control register*)
      SYSTEM.PUT(MASK, {}); (*disable all SDIO interrupts*)
      (*Start DMA*)
      SYSTEM.PUT(STREAM3_BASE + BSP.SxPAR, FIFO);
      SYSTEM.PUT(STREAM3_BASE + BSP.SxM0AR, pData);
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.LIFCR, LSL(BSP.STREAM_FLAGSm, BSP.LI_OFS3)); (*Clear all DMA2 stream 3 interrupt flags*)
      SYSTEM.GET(STREAM3_BASE + BSP.SxCR, reg);
      SYSTEM.PUT(STREAM3_BASE + BSP.SxCR, reg - (BSP.HTIEm + BSP.DMEIEm + BSP.SxCR_TCIEm + BSP.TEIEm)); (*disable all interrupts*)
      SYSTEM.GET(STREAM3_BASE + BSP.SxFCR, reg);
      SYSTEM.PUT(STREAM3_BASE + BSP.SxFCR, reg - BSP.FEIEm); (*disable fifo interrupt*)
      SYSTEM.PUT(s3En, 1); (*don't use TRUE because this register must be accessed by words (32 bits)*)
      (*Start SDIO DMA transfer*)
      SYSTEM.PUT(BSP.sdioDmaEn, 1);
      IF hsd.SdCard.CardType # CARD_SDHC_SDXC THEN blockAdd := blockAdd*512 (*convert block to byte*) END;
      (*Configure the SD DPSM (Data Path State Machine*)
      SYSTEM.PUT(DTIMER, 0FFFFFFFFH); SYSTEM.PUT(DLEN, BLOCKSIZE*nofBlocks);
      SYSTEM.GET(DCTRL, reg); (*bs 512, card to host, block mode, enable data transfer*)
      SYSTEM.PUT(DCTRL, reg - DCTRL_CLEAR_MASK + (BSP.DATABLOCK_SIZE_512B + BSP.DTDIRm + BSP.DTENm));
      SYSTEM.PUT(ARG, blockAdd); SYSTEM.GET(CMD, reg);
      IF nofBlocks > 1 THEN (*issue multiple blocks read command*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_READ_MULT_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        hsd.ErrorCode := GetCmdResp1(CMD_READ_MULT_BLOCK) (*check response*)
      ELSE (*issue single block read command*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_READ_SINGLE_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        hsd.ErrorCode := GetCmdResp1(CMD_READ_SINGLE_BLOCK) (*check response*)
      END;
      IF hsd.ErrorCode = NONE THEN (*wait for end of operation*)
        SYSTEM.GET(BSP.DMA2_BASE + BSP.LISR, lisr); SYSTEM.GET(STA, sta);
        WHILE ~(BSP.TEIFx + BSP.LI_OFS3 IN lisr) &
          (sta*(BSP.DCRCFAILm + BSP.DTIMEOUTm + BSP.RXOVERRm + BSP.DATAENDm + BSP.STBITERRm) = {}) DO
          Delayus(100); SYSTEM.GET(BSP.DMA2_BASE + BSP.LISR, lisr); SYSTEM.GET(STA, sta)
        END;
        hsd.ErrorCode := CmdStopTransfer();
        IF ~(BSP.DATAEND IN sta) THEN
          SYSTEM.PUT(s3En, 0); (*abort DMA transfer*)
          IF BSP.TEIFx + BSP.LI_OFS3 IN lisr THEN hsd.ErrorCode := hsd.ErrorCode + ERROR_DMA END;
          IF BSP.DCRCFAIL IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_CRC_FAIL END;
          IF BSP.DTIMEOUT IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_TIMEOUT END;
          IF BSP.RXOVERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + RX_OVERRUN END;
          IF BSP.TXUNDERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + TX_UNDERRUN END;
          IF BSP.STBITERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_TIMEOUT END;
          REPEAT SYSTEM.GET(s3En, reg) UNTIL reg = NONE (*wait until DMA transfer is aborted*)
        END
      END;
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.LIFCR, LSL(BSP.STREAM_FLAGSm, BSP.LI_OFS3)); (*Clear all DMA2 stream 3 interrupt flags*)
      SYSTEM.PUT(ICR, STATIC_FLAGS) (*clear all static flags*)
    END;

    RETURN hsd.ErrorCode
  END SDReadBlocksDMA;

  PROCEDURE ReadSD(VAR hsd: SDHandleDesc; src, dst, nofblocks: INTEGER);
  VAR rc: SET;
  BEGIN IF nofblocks > 128 THEN REPEAT UNTIL FALSE END;
    rc := SDReadBlocksDMA(hsd, hsd.buf, src, nofblocks);
    IF rc = NONE THEN
      WHILE GetCardState(hsd) #CARD_TRANSFER DO Delayus(1000) END
    END;

    IF hsd.ErrorCode = NONE THEN SYSTEM.COPY(hsd.buf, dst, nofblocks*(512 DIV 4)) END
  END ReadSD;

  PROCEDURE SDPowerOn(VAR hsd: SDHandleDesc): SET;
    VAR reg, errorcode: SET;
      count: INTEGER;
      validvoltage: BOOLEAN;
  BEGIN errorcode := NONE; validvoltage := FALSE;
    SYSTEM.PUT(ARG, 0); SYSTEM.GET(CMD, reg);
    SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_GO_IDLE_STATE + BSP.CPSMENm));
    WaitForCmd;
    SYSTEM.PUT(ARG, 1AAH) (*CHECK_PATTERN*); SYSTEM.GET(CMD, reg);
    SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_SEND_IF_COND + BSP.RESPONSE_SHORT + BSP.CPSMENm));
    errorcode := GetCmdResp2or7();
    IF errorcode # NONE THEN hsd.SdCard.CardVersion := CARD_V1_X; errorcode := NONE
    ELSE hsd.SdCard.CardVersion := CARD_V2_X;
    END; count := 0;
    REPEAT (*validate voltage range*)
      SYSTEM.PUT(ARG, 0); SYSTEM.GET(CMD, reg); (*send APP_CMD with 0 as RCA*)
      SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_APP_CMD + BSP.RESPONSE_SHORT + BSP.CPSMENm));
      errorcode := GetCmdResp1(CMD_APP_CMD);
      IF errorcode = NONE THEN (*send ACMD41*)
        SYSTEM.PUT(ARG, VOLTAGE_WINDOW_SD + HIGH_CAPACITY + SWITCH_1_8V_CAPACITY);
        SYSTEM.GET(CMD, reg); (*send APP_CMD with 0 as RCA*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_APP_SEND_OP_COND + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        errorcode := GetCmdResp3();
      END;
      IF errorcode = NONE THEN (*get response*)
        SYSTEM.GET(RESP1, reg); validvoltage := ODD(LSR(ORD(reg), 31))
      END;
      INC(count)
    UNTIL validvoltage OR (errorcode # NONE) OR (count > 0FFFFH);
    IF validvoltage THEN IF reg*HIGH_CAPACITY # {} THEN hsd.SdCard.CardType := CARD_SDHC_SDXC ELSE hsd.SdCard.CardType := CARD_SDSC END
    ELSE errorcode := INVALID_VOLTAGE
    END;

    RETURN errorcode
  END SDPowerOn;

   PROCEDURE GetCardCSD(VAR hsd: SDHandleDesc; VAR csd: SDCardCSDDesc): SET;
    VAR rc: SET;
  BEGIN rc := NONE;
      csd.CSDStruct := LSR(hsd.CSD[0], 30) MOD 4;
      csd.TAAC := LSR(hsd.CSD[0], 16) MOD 100H;
      csd.NSAC := LSR(hsd.CSD[0], 8) MOD 100H;
      csd.MaxBusClkFreq := hsd.CSD[0] MOD 100H;
      csd.CardComdClasses := LSR(hsd.CSD[1], 20) MOD 1000H;
      csd.RdBlockLen := LSR(hsd.CSD[1], 16) MOD 10H;
      csd.PartBlockRead := ODD(LSR(hsd.CSD[1], 15));
      csd.WrBlockMisalign := ODD(LSR(hsd.CSD[1], 14));
      csd.RdBlockMisalign := ODD(LSR(hsd.CSD[1], 13));
      csd.DSRImpl := ODD(LSR(hsd.CSD[1], 12));
      IF hsd.SdCard.CardType = CARD_SDSC THEN
        csd.DeviceSize := hsd.CSD[1] MOD 400H*4 + LSR(hsd.CSD[2], 30) MOD 4;
        csd.MaxRdCurrentVDDMin := LSR(hsd.CSD[2], 27) MOD 8;
        csd.MaxRdCurrentVDDMax := LSR(hsd.CSD[2], 24) MOD 8;
        csd.MaxWrCurrentVDDMin := LSR(hsd.CSD[2], 21) MOD 8;
        csd.MaxWrCurrentVDDMax := LSR(hsd.CSD[2], 18) MOD 8;
        csd.DeviceSizeMul := LSR(hsd.CSD[2], 15) MOD 8;

        hsd.SdCard.BlockNbr := (csd.DeviceSize + 1)*(LSL(1, csd.DeviceSizeMul + 2));
        hsd.SdCard.BlockSize := LSL(1, csd.RdBlockLen);

        hsd.SdCard.LogBlockNbr := hsd.SdCard.BlockNbr*hsd.SdCard.BlockSize DIV 512;
        hsd.SdCard.LogBlockSize := 512
      ELSIF hsd.SdCard.CardType = CARD_SDHC_SDXC THEN
        csd.DeviceSize := hsd.CSD[1] MOD 40H*10000H + LSR(hsd.CSD[2], 16) MOD 10000H;

        hsd.SdCard.BlockNbr := (csd.DeviceSize + 1)*1024;
        hsd.SdCard.BlockSize := 512;

        hsd.SdCard.LogBlockNbr := hsd.SdCard.BlockNbr;
        hsd.SdCard.LogBlockSize := hsd.SdCard.BlockSize
      ELSE hsd.ErrorCode := UNSUPPORTED_FEATURE; rc := UNSUPPORTED_FEATURE
      END;
      IF rc = NONE THEN
        csd.EraseBlkEn := ODD(LSR(hsd.CSD[2], 14));
        csd.SectorSize := LSR(hsd.CSD[2], 7) MOD 80H;
        csd.WrProtectGrSize := hsd.CSD[2] MOD 80H;
        csd.WrProtectGrEnable := ODD(LSR(hsd.CSD[3], 31));
        csd.WrSpeedFact := LSR(hsd.CSD[3], 26) MOD 8;
        csd.MaxWrBlockLen := LSR(hsd.CSD[3], 22) MOD 10H;
        csd.WriteBlockPartial := ODD(LSR(hsd.CSD[3], 21));
        csd.FileFormatGroup := LSR(hsd.CSD[3], 15) MOD 2;
        csd.CopyFlag := ODD(LSR(hsd.CSD[3], 14));
        csd.PermWrProtect := ODD(LSR(hsd.CSD[3], 13));
        csd.TempWrProtect := ODD(LSR(hsd.CSD[3], 12));
        csd.FileFormat := LSR(hsd.CSD[3], 10) MOD 4;
        csd.CSD_CRC := LSR(hsd.CSD[3], 1) MOD 80H
      END;

    RETURN rc
  END GetCardCSD;

  PROCEDURE SDInitCard(VAR hsd: SDHandleDesc): SET;
    VAR CSD: SDCardCSDDesc;
      reg, errorcode: SET;
      sdRca: INTEGER;
  BEGIN errorcode := NONE;
    SYSTEM.GET(BSP.SDIO_BASE + BSP.POWER, reg);
    IF reg*BSP.PWRCTRLm # BSP.POWER_ON THEN errorcode := REQUEST_NOT_APPLICABLE END;
    IF errorcode = NONE THEN (*get all CIDs*)
      SYSTEM.PUT(ARG, 0); SYSTEM.GET(CMD, reg);
      SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_ALL_SEND_CID + BSP.RESPONSE_LONG + BSP.CPSMENm));
      errorcode := GetCmdResp2or7();
      IF errorcode = NONE THEN SYSTEM.GET(RESP1, hsd.CID[0]); SYSTEM.GET(RESP2, hsd.CID[1]);
        SYSTEM.GET(RESP3, hsd.CID[2]); SYSTEM.GET(RESP4, hsd.CID[3])
      END;
      IF errorcode = NONE THEN
        SYSTEM.PUT(ARG, 0); SYSTEM.GET(CMD, reg);
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_SET_REL_ADR + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        errorcode := GetCmdResp6(CMD_SET_REL_ADR, sdRca)
      END;
      IF errorcode = NONE THEN
        hsd.SdCard.RelCardAdd := sdRca;
        SYSTEM.PUT(ARG, LSL(hsd.SdCard.RelCardAdd, 16)); SYSTEM.GET(CMD, reg); (*get CSD*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_SEND_CSD + BSP.RESPONSE_LONG + BSP.CPSMENm));
        errorcode := GetCmdResp2or7()
      END;
      IF errorcode = NONE THEN SYSTEM.GET(RESP1, hsd.CSD[0]); SYSTEM.GET(RESP2, hsd.CSD[1]);
        SYSTEM.GET(RESP3, hsd.CSD[2]); SYSTEM.GET(RESP4, hsd.CSD[3]);
        hsd.SdCard.Class := LSR(hsd.CSD[1], 20);
        errorcode := GetCardCSD(hsd, CSD)
      END;
      IF errorcode = NONE THEN
        SYSTEM.PUT(ARG, LSL(hsd.SdCard.RelCardAdd, 16)); SYSTEM.GET(CMD, reg);
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_SEL_DESEL_CARD + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        errorcode := GetCmdResp1(CMD_SEL_DESEL_CARD)
      END
    END;

    RETURN errorcode
  END SDInitCard;

 PROCEDURE configureGPIO(port: INTEGER; m1b, m2b, m4bl, m4bh, m, os, ot, pup, afrl, afrh: SET);
    VAR reg: SET;
  BEGIN
    SYSTEM.GET(port + BSP.OSPEEDR, reg); SYSTEM.PUT(port + BSP.OSPEEDR, reg - m2b + os);
    SYSTEM.GET(port + BSP.OTYPER, reg); SYSTEM.PUT(port + BSP.OTYPER, reg - m1b + ot);
    SYSTEM.GET(port + BSP.PUPDR, reg); SYSTEM.PUT(port + BSP.PUPDR, reg - m2b + pup);
    SYSTEM.GET(port + BSP.AFRL, reg); SYSTEM.PUT(port + BSP.AFRL, reg - m4bl + afrl);
    SYSTEM.GET(port + BSP.AFRH, reg); SYSTEM.PUT(port + BSP.AFRH, reg - m4bh + afrh);
    SYSTEM.GET(port + BSP.MODER, reg); SYSTEM.PUT(port + BSP.MODER, reg - m2b + m)
  END configureGPIO;

  PROCEDURE SDInit(VAR hsd: SDHandleDesc);
    (*SDIO GPIO Configuration
    PC8     ------> SDIO_D0
    PC9     ------> SDIO_D1
    PC10     ------> SDIO_D2
    PC11     ------> SDIO_D3
    PC12     ------> SDIO_CK
    PD2     ------> SDIO_CMD

    PD4     ------> WRITE_PROTECT
    PD5     ------> CARD_DETECT

    PC3     ------> LED2
    PF9     ------> LED1*)
    CONST 
      maskC_1b = {BSP.LED2Pin, 8, 9, 10, 11, 12}; 
      maskC_2b = LSL(BSP.MASK2, BSP.LED2Pin*2) + LSL(BSP.MASK2, 8*2) + LSL(BSP.MASK2, 9*2) + LSL(BSP.MASK2, 10*2) +
        LSL(BSP.MASK2, 11*2) + LSL(BSP.MASK2, 12*2);
      maskC_4bh = LSL(BSP.MASK4, 8 MOD 8*4) + LSL(BSP.MASK4, 9 MOD 8*4) + LSL(BSP.MASK4, 10 MOD 8*4) +
        LSL(BSP.MASK4, 11 MOD 8*4) + LSL(BSP.MASK4, 12 MOD 8*4);
      maskD_1b = {2, BSP.WRITE_PROTECTPin, BSP.CARD_DETECTPin};
      maskD_2b = LSL(BSP.MASK2, 2*2) + LSL(BSP.MASK2, BSP.WRITE_PROTECTPin*2) + LSL(BSP.MASK2, BSP.CARD_DETECTPin*2);
      maskD_4bl = LSL(BSP.MASK4, 2*4);
      maskF_1b = {BSP.LED1Pin}; maskF_2b = LSL(BSP.MASK2, BSP.LED1Pin*2);
    VAR reg: SET; en: BYTE;
      scr: ARRAY 2 OF SET;
      index: INTEGER;
  BEGIN SYSTEM.PUT(BSP.dma2En, TRUE); SYSTEM.PUT(BSP.sdioEn, TRUE);
    SYSTEM.PUT(BSP.gpiocEn, TRUE); SYSTEM.PUT(BSP.gpiodEn, TRUE); SYSTEM.PUT(BSP.gpiodEn, TRUE); SYSTEM.PUT(BSP.gpiofEn, TRUE);
    SYSTEM.GET(BSP.gpiofEn, en); (*delay*)
    (*GPIOs*)
    configureGPIO(BSP.GPIOC, maskC_1b, maskC_2b, {}, maskC_4bh, 
      LSL(BSP.OUTPUT_MODE, BSP.LED2Pin*2) + LSL(BSP.AF_MODE, 8*2) + LSL(BSP.AF_MODE, 9*2) + LSL(BSP.AF_MODE, 10*2) +
        LSL(BSP.AF_MODE, 11*2) + LSL(BSP.AF_MODE,12*2),
      LSL(BSP.HIGH_SPEED, 8*2) + LSL(BSP.HIGH_SPEED, 9*2) + LSL(BSP.HIGH_SPEED, 10*2) + LSL(BSP.HIGH_SPEED, 11*2) +
        LSL(BSP.HIGH_SPEED,12*2),
      {}, {}, {},
      LSL(SYSTEM.VAL(SET, 12), 8 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 9 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 10 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 11 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 12 MOD 8*4)); (*PC3 output pp ls, PC8..12 AF12 pp hs*)
    configureGPIO(BSP.GPIOD, maskD_1b, maskD_2b, maskD_4bl, {},
      LSL(BSP.AF_MODE, 2*2),
      LSL(BSP.HIGH_SPEED, 2*2),
      {}, LSL(BSP.PULL_UP, BSP.WRITE_PROTECTPin*2) + LSL(BSP.PULL_UP, BSP.CARD_DETECTPin*2),
      LSL(SYSTEM.VAL(SET, 12), 2*4),
      {}); (*PD2 AF12 pp hs, PD4 and PD5 inputs pulled up*)
    configureGPIO(BSP.GPIOF, maskF_1b, maskF_2b, {}, {}, LSL(BSP.OUTPUT_MODE, BSP.LED1Pin*2), {}, {}, {}, {}, {}); (*PF9 output pp ls*)

    Delayus(100); (*wait for pull up to stabilize*)
    IF SYSTEM.BIT(BSP.CARD_DETECTPort + BSP.IDR, BSP.CARD_DETECTPin) THEN
      SYSTEM.PUT(BSP.LED1Out, TRUE); REPEAT UNTIL FALSE (*card missing*)
    END;
    IF SYSTEM.BIT(BSP.WRITE_PROTECTPort + BSP.IDR, BSP.WRITE_PROTECTPin) THEN
      SYSTEM.PUT(BSP.LED2Out, TRUE); REPEAT UNTIL FALSE (*card read only*)
    END;
    SYSTEM.GET(BSP.GPIOD + BSP.PUPDR, reg); (*remove PD4 and PD5 pull up to reduce consumption*)
    SYSTEM.PUT(BSP.GPIOD + BSP.PUPDR, reg - (LSL(BSP.MASK2, BSP.WRITE_PROTECTPin*2) + LSL(BSP.MASK2, BSP.CARD_DETECTPin*2)));
    SYSTEM.PUT(BSP.LED1Out, TRUE); SYSTEM.PUT(BSP.LED2Out, TRUE);

    (*DMAs*)
    SYSTEM.PUT(s3En, 0); REPEAT SYSTEM.GET(s3En, reg) UNTIL reg = NONE; (*wait until DMA is effectively disabled*)
    SYSTEM.PUT(STREAM3_BASE + BSP.SxCR, LSL(SYSTEM.VAL(SET, 4), BSP.CHSEL) + LSL(BSP.INCR4, BSP.MBURST) +
      LSL(BSP.INCR4, BSP.PBURST) + LSL(BSP.SWORD, BSP.MSIZE) + LSL(BSP.SWORD, BSP.PSIZE) + BSP.MINCm +
      BSP.PERIPH_TO_MEMORY + BSP.PFCTRLm);
    SYSTEM.PUT(STREAM3_BASE + BSP.SxFCR, BSP.DMDISm + BSP.FULL_FIFO);

    SYSTEM.PUT(s6En, 0); REPEAT SYSTEM.GET(s6En, reg) UNTIL reg = NONE; (*wait until DMA is effectively disabled*)
    SYSTEM.PUT(STREAM6_BASE + BSP.SxCR, LSL(SYSTEM.VAL(SET, 4), BSP.CHSEL) + LSL(BSP.INCR4, BSP.MBURST) +
      LSL(BSP.INCR4, BSP.PBURST) + LSL(BSP.SWORD, BSP.MSIZE) + LSL(BSP.SWORD, BSP.PSIZE) + BSP.MINCm +
      BSP.MEMORY_TO_PERIPH + BSP.PFCTRLm);
    SYSTEM.PUT(STREAM6_BASE + BSP.SxFCR, BSP.DMDISm + BSP.FULL_FIFO);
    (*Initialize SDIO*)
    SYSTEM.PUT(BSP.SDIO_BASE + BSP.CLKCR, (BSP.WIDE_1B + SYSTEM.VAL(SET, BSP.INIT_CLK_DIV)));
    SYSTEM.PUT(BSP.SDIO_BASE + BSP.POWER, BSP.POWER_ON);
    SYSTEM.PUT(BSP.sdioClkEn, 1); Delayus(2000); (*waiting time required before starting SD initialization*)
    (*Initialize the card*) 
    hsd.ErrorCode := SDPowerOn(hsd); (*identify card operating voltage*)
    IF hsd.ErrorCode = NONE THEN
      hsd.ErrorCode := SDInitCard(hsd); (*Initialize the card*)
    END;
    IF hsd.ErrorCode = NONE THEN (*configure wide bus operation*)
      IF hsd.SdCard.CardType = CARD_SDSC THEN
        SYSTEM.PUT(ARG, 8); (*set block size to 8 bytes (for SDSC only*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_SET_BLOCKLEN + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        hsd.ErrorCode := hsd.ErrorCode + GetCmdResp1(CMD_SET_BLOCKLEN) (*check response*)
      END;
      IF hsd.ErrorCode = NONE THEN
        SYSTEM.PUT(ARG, LSL(hsd.SdCard.RelCardAdd, 16)); SYSTEM.GET(CMD, reg);
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_APP_CMD + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        hsd.ErrorCode := GetCmdResp1(CMD_APP_CMD) (*check response*)
      END;
      IF hsd.ErrorCode = NONE THEN (*Get SCR*)
        SYSTEM.PUT(DTIMER, 0FFFFFFFFH); SYSTEM.PUT(DLEN, 8); (*set DPSM*)
        SYSTEM.GET(DCTRL, reg); (*bs 8, card to host, block mode, enable data transfer*)
        SYSTEM.PUT(DCTRL, reg - DCTRL_CLEAR_MASK + (BSP.DATABLOCK_SIZE_8B + BSP.DTDIRm + BSP.DTENm));
        SYSTEM.PUT(ARG, 0); (*ACMD51 CMD_APP_SEND_SCR with argument as 0*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_APP_SEND_SCR + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        hsd.ErrorCode := GetCmdResp1(CMD_APP_SEND_SCR) (*check response*)
      END;
      IF hsd.ErrorCode = NONE THEN (*poll DPSM flags*) SYSTEM.GET(STA, reg); index := 0;
        WHILE reg*(BSP.DCRCFAILm + BSP.DTIMEOUTm + BSP.RXOVERRm + BSP.STBITERRm + BSP.RXACTm) = BSP.RXACTm DO
          IF BSP.RXDAVL IN reg THEN SYSTEM.GET(FIFO, scr[index]); INC(index) END;
          SYSTEM.GET(STA, reg)
        END;
        IF BSP.DATAEND IN reg THEN scr[0] := SYSTEM.VAL(SET, reverseBytes(ORD(scr[0]))); scr[1] := SYSTEM.VAL(SET, reverseBytes(ORD(scr[1])))
        ELSIF BSP.DCRCFAIL IN reg THEN hsd.ErrorCode := DATA_CRC_FAIL
        ELSIF BSP.RXOVERR IN reg THEN hsd.ErrorCode := RX_OVERRUN
        ELSIF BSP.STBITERR IN reg THEN hsd.ErrorCode := DATA_TIMEOUT
        END;
        SYSTEM.PUT(ICR, STATIC_FLAGS); (*clear data static flags*)
        IF WIDE_BUS_SUPPORT IN scr[1] THEN
          SYSTEM.PUT(ARG, LSL(hsd.SdCard.RelCardAdd, 16)); SYSTEM.GET(CMD, reg);
          SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_APP_CMD + BSP.RESPONSE_SHORT + BSP.CPSMENm));
          hsd.ErrorCode := GetCmdResp1(CMD_APP_CMD); (*check response*)
          IF hsd.ErrorCode = NONE THEN (*ACMD6 CMD_APP_SET_BUS_WIDTH with argument as 2 for wide bus mode*)
            SYSTEM.PUT(ARG, 2);
            SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_APP_SET_BUS_WIDTH + BSP.RESPONSE_SHORT + BSP.CPSMENm));
            hsd.ErrorCode := GetCmdResp1(CMD_APP_SET_BUS_WIDTH) (*check response*)
          END;
          IF hsd.ErrorCode = NONE THEN (*switch SDIO to wide bus mode*)
            SYSTEM.GET(BSP.SDIO_BASE + BSP.CLKCR, reg);
            SYSTEM.PUT(BSP.SDIO_BASE + BSP.CLKCR, reg - BSP.WIDBUSm + BSP.WIDE_4B)
          END
        END
      END;
      IF hsd.ErrorCode = NONE THEN (*switch to transfer frequency*)
        SYSTEM.GET(BSP.SDIO_BASE + BSP.CLKCR, reg);
        SYSTEM.PUT(BSP.SDIO_BASE + BSP.CLKCR, reg - BSP.CLKDIVm + SYSTEM.VAL(SET, BSP.TRANSFER_CLK_DIV));
        SYSTEM.PUT(ARG, 512); (*set block size to 512 bytes (for SDSC only*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_SET_BLOCKLEN + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        hsd.ErrorCode := hsd.ErrorCode + GetCmdResp1(CMD_SET_BLOCKLEN) (*check response*)
      END;
      IF hsd.ErrorCode = NONE THEN (*turn LEDs off*)
        SYSTEM.PUT(BSP.LED1Out, FALSE); SYSTEM.PUT(BSP.LED2Out, FALSE);
      END
    END
  END SDInit;

  PROCEDURE LoadFromDisk;
    CONST sdBuf = (SDHandleDescAddr + SYSTEM.SIZE(SDHandleDesc) + 15) DIV 16*16; (*free SRAM after hsd, aligned to 16-bytes boundary*)
    VAR lim, r: INTEGER; hsd!: SDHandle;
  BEGIN hsd := SYSTEM.VAL(SDHandle, SDHandleDescAddr); hsd.buf := sdBuf; SDInit(hsd^);
    (*start at boot block*)
    ReadSD(hsd^, FSoffset + 2*bps, VarORG0, bps);
    SYSTEM.GET(VarORG0 + 16, lim);
    (*read remaining blocks*)
    r := (lim + (511- VarORG0)) DIV 512 - bps;
    IF r > 0 THEN ReadSD(hsd^, FSoffset + 2*(bps+1), VarORG0+SectorSize, r) END
  END LoadFromDisk;

  PROCEDURE MPUInit; (*initialize the memory protection unit*)
    VAR reg: SET;
  BEGIN (*Make region D0200000 to D07FFFFF executable*)
    SYSTEM.MBI(1); (*DMB*) SYSTEM.GET(BSP.SCB_BASE + BSP.SHCSR, reg); SYSTEM.PUT(BSP.SCB_BASE + BSP.SHCSR, reg - {BSP.MEMFAULTENA});
    SYSTEM.PUT(BSP.MPU_BASE + BSP.MPU_CTRL, 0); (*disable MPU*)
    (*Region 0: start at D0000000, size 8MB, RWX*)
    SYSTEM.PUT(BSP.MPU_BASE + BSP.RNR, 0); SYSTEM.PUT(BSP.MPU_BASE + BSP.RBAR, BSP.Display_FBA + 0);
    SYSTEM.PUT(BSP.MPU_BASE + BSP.RASR, BSP.AP_FULL_ACCESS + BSP.TEX_LEVEL0 + {BSP.C, BSP. S} +
      {BSP.SRD+0 .. BSP.SRD+1} + SYSTEM.VAL(SET, 22*2) + {BSP.RASR_ENABLE});
    SYSTEM.GET(BSP.MPU_BASE + BSP.MPU_CTRL, reg); SYSTEM.PUT(BSP.MPU_BASE + BSP.MPU_CTRL, reg + {BSP.MPU_ENABLE, BSP.PRIVDEFENA}); (*enable MPU*)
    SYSTEM.GET(BSP.SCB_BASE + BSP.SHCSR, reg); SYSTEM.PUT(BSP.SCB_BASE + BSP.SHCSR, reg + {BSP.MEMFAULTENA});
    SYSTEM.MBI(2); (*DSB*); SYSTEM.MBI(3) (*ISB, ensure that MPU settings take effects*)
  END MPUInit;

  PROCEDURE SDRAMInit;
(* FMC GPIO Configuration
  PB5   ------> FMC_SDCKE1
  PB6   ------> FMC_SDNE1
  PC0   ------> FMC_SDNWE
  PD0   ------> FMC_D2
  PD1   ------> FMC_D3
  PD8   ------> FMC_D13
  PD9   ------> FMC_D14
  PD10   ------> FMC_D15
  PD14   ------> FMC_D0
  PD15   ------> FMC_D1
  PE0   ------> FMC_NBL0
  PE1   ------> FMC_NBL1
  PE7   ------> FMC_D4
  PE8   ------> FMC_D5
  PE9   ------> FMC_D6
  PE10   ------> FMC_D7
  PE11   ------> FMC_D8
  PE12   ------> FMC_D9
  PE13   ------> FMC_D10
  PE14   ------> FMC_D11
  PE15   ------> FMC_D12
  PF0   ------> FMC_A0
  PF1   ------> FMC_A1
  PF2   ------> FMC_A2
  PF3   ------> FMC_A3
  PF4   ------> FMC_A4
  PF5   ------> FMC_A5
  PF11   ------> FMC_SDNRAS
  PF12   ------> FMC_A6
  PF13   ------> FMC_A7
  PF14   ------> FMC_A8
  PF15   ------> FMC_A9
  PG0   ------> FMC_A10
  PG1   ------> FMC_A11
  PG4   ------> FMC_BA0
  PG5   ------> FMC_BA1
  PG8   ------> FMC_SDCLK
  PG15   ------> FMC_SDNCAS
*)
    CONST
      maskB_1b = {5, 6};
      maskB_2b = LSL(BSP.MASK2, 5*2) + LSL(BSP.MASK2, 6*2);
      maskB_4bl = LSL(BSP.MASK4, 5*4) + LSL(BSP.MASK4, 6*4);
      maskD_1b = {0, 1, 8, 9, 10, 14, 15};
      maskD_2b = LSL(BSP.MASK2, 0*2) + LSL(BSP.MASK2, 1*2) + 
        LSL(BSP.MASK2, 8*2) + LSL(BSP.MASK2, 9*2) + LSL(BSP.MASK2, 10*2) + LSL(BSP.MASK2, 14*2) + LSL(BSP.MASK2, 15*2);
      maskD_4bl = LSL(BSP.MASK4, 0*4) + LSL(BSP.MASK4, 1*4);
      maskD_4bh = LSL(BSP.MASK4, 8 MOD 8*4) + LSL(BSP.MASK4, 9 MOD 8*4) + LSL(BSP.MASK4, 10 MOD 8*4) +
        LSL(BSP.MASK4, 14 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4);
      maskE_1b = {0, 1, 7, 8, 9, 10, 11, 12, 13, 14, 15};
      maskE_2b = LSL(BSP.MASK2, 0*2) + LSL(BSP.MASK2, 1*2) + LSL(BSP.MASK2, 7*2) +
        LSL(BSP.MASK2, 8*2) + LSL(BSP.MASK2, 9*2) + LSL(BSP.MASK2, 10*2) + LSL(BSP.MASK2, 11*2) + LSL(BSP.MASK2, 12*2) +
        LSL(BSP.MASK2, 13*2) + LSL(BSP.MASK2, 14*2) + LSL(BSP.MASK2, 15*2);
      maskE_4bl = LSL(BSP.MASK4, 0*4) + LSL(BSP.MASK4, 1*4) + LSL(BSP.MASK4, 7*4);
      maskE_4bh = LSL(BSP.MASK4, 8 MOD 8*4) + LSL(BSP.MASK4, 9 MOD 8*4) + LSL(BSP.MASK4, 10 MOD 8*4) +
        LSL(BSP.MASK4, 11 MOD 8*4) + LSL(BSP.MASK4, 12 MOD 8*4) + LSL(BSP.MASK4, 13 MOD 8*4) +
        LSL(BSP.MASK4, 14 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4);
      maskF_1b = {0, 1, 2, 3, 4, 5, 11, 12, 13, 14, 15};
      maskF_2b = LSL(BSP.MASK2, 0*2) + LSL(BSP.MASK2, 1*2) + LSL(BSP.MASK2, 2*2) + LSL(BSP.MASK2, 3*2) + LSL(BSP.MASK2, 4*2) + LSL(BSP.MASK2, 5*2) +
        LSL(BSP.MASK2, 11*2) + LSL(BSP.MASK2, 12*2) + LSL(BSP.MASK2, 13*2) + LSL(BSP.MASK2, 14*2) + LSL(BSP.MASK2, 15*2);
      maskF_4bl = LSL(BSP.MASK4, 0*4) + LSL(BSP.MASK4, 1*4) + LSL(BSP.MASK4, 2*4) + LSL(BSP.MASK4, 3*4) + LSL(BSP.MASK4, 4*4) + LSL(BSP.MASK4, 5*4);
      maskF_4bh = LSL(BSP.MASK4, 11 MOD 8*4) + LSL(BSP.MASK4, 12 MOD 8*4) + LSL(BSP.MASK4, 13 MOD 8*4) +
        LSL(BSP.MASK4, 14 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4);
      maskG_1b = {0, 1, 4, 5, 8, 15};
      maskG_2b = LSL(BSP.MASK2, 0*2) + LSL(BSP.MASK2, 1*2) + LSL(BSP.MASK2, 4*2) + LSL(BSP.MASK2, 5*2) +
        LSL(BSP.MASK2, 8*2) + LSL(BSP.MASK2, 15*2);
      maskG_4bl = LSL(BSP.MASK4, 0*4) + LSL(BSP.MASK4, 1*4) + LSL(BSP.MASK4, 4*4) + LSL(BSP.MASK4, 5*4);
      maskG_4bh = LSL(BSP.MASK4, 8 MOD 8*4) + LSL(BSP.MASK4, 15 MOD 8*4);
    VAR reg: SET;
  BEGIN SYSTEM.GET(BSP.RCC_BASE + BSP.AHB1ENR, reg);
    SYSTEM.PUT(BSP.RCC_BASE + BSP.AHB1ENR, reg + {BSP.GPIOBEN, BSP.GPIOCEN, BSP.GPIODEN, BSP.GPIOEEN, BSP.GPIOFEN, BSP.GPIOGEN});
    SYSTEM.PUT(BSP.RCC_BASE + BSP.AHB3ENR, {BSP.FMCEN});
    
    configureGPIO(BSP.GPIOB, maskB_1b, maskB_2b, maskB_4bl, {},
      LSL(BSP.AF_MODE, 5*2) + LSL(BSP.AF_MODE, 6*2), LSL(BSP.VERY_HIGH_SPEED, 5*2) + LSL(BSP.VERY_HIGH_SPEED, 6*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 5*4) + LSL(SYSTEM.VAL(SET, 12), 6*4), {});
    configureGPIO(BSP.GPIOC, {0}, {0*2}, {0*4}, {}, LSL(BSP.AF_MODE, 0*2), LSL(BSP.VERY_HIGH_SPEED, 0*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4), {});
    configureGPIO(BSP.GPIOD, maskD_1b, maskD_2b, maskD_4bl, maskD_4bh,
      LSL(BSP.AF_MODE, 0*2) + LSL(BSP.AF_MODE, 1*2) + 
        LSL(BSP.AF_MODE, 8*2) + LSL(BSP.AF_MODE, 9*2) + LSL(BSP.AF_MODE, 10*2) + LSL(BSP.AF_MODE, 14*2) + LSL(BSP.AF_MODE, 15*2),
      LSL(BSP.VERY_HIGH_SPEED, 0*2) + LSL(BSP.VERY_HIGH_SPEED, 1*2) + 
        LSL(BSP.VERY_HIGH_SPEED, 8*2) + LSL(BSP.VERY_HIGH_SPEED, 9*2) + LSL(BSP.VERY_HIGH_SPEED, 10*2) + LSL(BSP.VERY_HIGH_SPEED, 14*2) +
        LSL(BSP.VERY_HIGH_SPEED, 15*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4) + LSL(SYSTEM.VAL(SET, 12), 1*4),
      LSL(SYSTEM.VAL(SET, 12), 8 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 9 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 10 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 14 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 15 MOD 8*4));
    configureGPIO(BSP.GPIOE, maskE_1b, maskE_2b, maskE_4bl, maskE_4bh,
      LSL(BSP.AF_MODE, 0*2) + LSL(BSP.AF_MODE, 1*2) + LSL(BSP.AF_MODE, 7*2) +
        LSL(BSP.AF_MODE, 8*2) + LSL(BSP.AF_MODE, 9*2) + LSL(BSP.AF_MODE, 10*2) + LSL(BSP.AF_MODE, 11*2) + LSL(BSP.AF_MODE, 12*2) + 
        LSL(BSP.AF_MODE, 13*2) + LSL(BSP.AF_MODE, 14*2) + LSL(BSP.AF_MODE, 15*2),
      LSL(BSP.VERY_HIGH_SPEED, 0*2) + LSL(BSP.VERY_HIGH_SPEED, 1*2) +  LSL(BSP.VERY_HIGH_SPEED, 7*2) +
        LSL(BSP.VERY_HIGH_SPEED, 8*2) + LSL(BSP.VERY_HIGH_SPEED, 9*2) + LSL(BSP.VERY_HIGH_SPEED, 10*2) + LSL(BSP.VERY_HIGH_SPEED, 11*2) +
        LSL(BSP.VERY_HIGH_SPEED, 12*2) + LSL(BSP.VERY_HIGH_SPEED, 13*2) + LSL(BSP.VERY_HIGH_SPEED, 14*2) + LSL(BSP.VERY_HIGH_SPEED, 15*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4) + LSL(SYSTEM.VAL(SET, 12), 1*4) + LSL(SYSTEM.VAL(SET, 12), 7*4),
      LSL(SYSTEM.VAL(SET, 12), 8 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 9 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 10 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 11 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 12 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 13 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 14 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 15 MOD 8*4));
    configureGPIO(BSP.GPIOF, maskF_1b, maskF_2b, maskF_4bl, maskF_4bh,
      LSL(BSP.AF_MODE, 0*2) + LSL(BSP.AF_MODE, 1*2) + LSL(BSP.AF_MODE, 2*2) + LSL(BSP.AF_MODE, 3*2) + LSL(BSP.AF_MODE, 4*2) + LSL(BSP.AF_MODE, 5*2) +
        LSL(BSP.AF_MODE, 11*2) + LSL(BSP.AF_MODE, 12*2) + LSL(BSP.AF_MODE, 13*2) + LSL(BSP.AF_MODE, 14*2) + LSL(BSP.AF_MODE, 15*2),
      LSL(BSP.VERY_HIGH_SPEED, 0*2) + LSL(BSP.VERY_HIGH_SPEED, 1*2) +  LSL(BSP.VERY_HIGH_SPEED, 2*2) + LSL(BSP.VERY_HIGH_SPEED, 3*2) +
        LSL(BSP.VERY_HIGH_SPEED, 4*2) + LSL(BSP.VERY_HIGH_SPEED, 5*2) + LSL(BSP.VERY_HIGH_SPEED, 11*2) +
        LSL(BSP.VERY_HIGH_SPEED, 12*2) + LSL(BSP.VERY_HIGH_SPEED, 13*2) + LSL(BSP.VERY_HIGH_SPEED, 14*2) + LSL(BSP.VERY_HIGH_SPEED, 15*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4) + LSL(SYSTEM.VAL(SET, 12), 1*4) + LSL(SYSTEM.VAL(SET, 12), 2*4) + LSL(SYSTEM.VAL(SET, 12), 3*4) +
        LSL(SYSTEM.VAL(SET, 12), 4*4) + LSL(SYSTEM.VAL(SET, 12), 5*4),
      LSL(SYSTEM.VAL(SET, 12), 11 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 12 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 13 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 12), 14 MOD 8*4) +  LSL(SYSTEM.VAL(SET, 12), 15 MOD 8*4));
    configureGPIO(BSP.GPIOG, maskG_1b, maskG_2b, maskG_4bl, maskG_4bh,
      LSL(BSP.AF_MODE, 0*2) + LSL(BSP.AF_MODE, 1*2) + LSL(BSP.AF_MODE, 4*2) + LSL(BSP.AF_MODE, 5*2) +
        LSL(BSP.AF_MODE, 8*2) + LSL(BSP.AF_MODE, 15*2),
      LSL(BSP.VERY_HIGH_SPEED, 0*2) + LSL(BSP.VERY_HIGH_SPEED, 1*2) + LSL(BSP.VERY_HIGH_SPEED, 4*2) + LSL(BSP.VERY_HIGH_SPEED, 5*2) +
        LSL(BSP.VERY_HIGH_SPEED, 8*2) + LSL(BSP.VERY_HIGH_SPEED, 15*2), {}, {},
      LSL(SYSTEM.VAL(SET, 12), 0*4) + LSL(SYSTEM.VAL(SET, 12), 1*4) + LSL(SYSTEM.VAL(SET, 12), 4*4) + LSL(SYSTEM.VAL(SET, 12), 5*4),
      LSL(SYSTEM.VAL(SET, 12), 8 MOD 8*4) + LSL(SYSTEM.VAL(SET, 12), 15 MOD 8*4));

    (*FMC and SDRAM Init*)
    (*FMC*)
    (*bank 2, 8_bits column address, 12-bits row address, 16-bits data bus width, 4 internal banks, 3 clocks CAS latency,
      write protection disabled, clock period equals to 2 HCLK periods, read burst enable, read  pipe delay equals to one clock cycle*)
    SYSTEM.GET(BSP.FMC_Bank5_6_R_Base + BSP.SDCR1, reg);
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDCR1, reg - (BSP.RPIPEm + {BSP.RBURST} + BSP.SDCLKm) +
      (BSP.RPIPE_DELAY_1 + {BSP.RBURST} + BSP.CLOCK_PERIOD_2));
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDCR2, BSP.COLUMN_BITS_NUM_8 + BSP.ROW_BITS_NUM_12 + BSP.MEM_BUS_WIDTH_16 +
      {BSP.NB} + BSP.CAS_LATENCY_3);
    (*TMRD 2, TXSR 7, TRAS 4, TRC 7, TWR 3, TRP 2 and TRCD 2*)
    SYSTEM.GET(BSP.FMC_Bank5_6_R_Base + BSP.SDTR1, reg);
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDTR1, reg - (BSP.TRCm + BSP.TRPm) + (LSL(SYSTEM.VAL(SET, 7-1), BSP.TRC) + LSL(SYSTEM.VAL(SET, 2-1), BSP.TRP)));
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDTR2, LSL(SYSTEM.VAL(SET, 2-1), BSP.TMRD) + LSL(SYSTEM.VAL(SET, 7-1), BSP.TXSR) +
    LSL(SYSTEM.VAL(SET, 4-1), BSP.TRAS) +  LSL(SYSTEM.VAL(SET, 3-1), BSP.TWR) + LSL(SYSTEM.VAL(SET, 2-1), BSP.TRCD));
    (*SDRAM*)
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDCMR, BSP.CMD_CLK_CONF_ENABLE + {BSP.CBT2}); (*step 1 enable clock for bank2*)
    REPEAT UNTIL ~SYSTEM.BIT(BSP.FMC_Bank5_6_R_Base + BSP.SDSR, BSP.BUSY);
    Delayus(120); (*step 2 insert at least 100us delay*)
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDCMR, BSP.CMD_PALL + {BSP.CBT2}); (*step 3 precharge all*)
    REPEAT UNTIL ~SYSTEM.BIT(BSP.FMC_Bank5_6_R_Base + BSP.SDSR, BSP.BUSY);
    (*step 4 enable autorefresh mode*)
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDCMR, BSP.CMD_AUTOREFRESH_MODE + {BSP.CBT2} + LSL(SYSTEM.VAL(SET, 4), BSP.NRFS));
    REPEAT UNTIL ~SYSTEM.BIT(BSP.FMC_Bank5_6_R_Base + BSP.SDSR, BSP.BUSY);
    (*step 5 burst length 1, busrt type sequential, cas latency 3, operating mode standard, burst node single*)
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDCMR, BSP.CMD_LOAD_MODE + {BSP.CBT2} + LSL(SYSTEM.VAL(SET, 0 + 0 + 30H + 0 + 200H), BSP.MRD));
    REPEAT UNTIL ~SYSTEM.BIT(BSP.FMC_Bank5_6_R_Base + BSP.SDSR, BSP.BUSY);
    SYSTEM.PUT(BSP.FMC_Bank5_6_R_Base + BSP.SDRTR, LSL(1292, BSP.COUNT)); (*step 6 set refresh rate counter to 1292*)
  END SDRAMInit;

  PROCEDURE CYCNTInit;
    VAR reg: SET;
  BEGIN (*enable micriseconds delay via DWT*)
    SYSTEM.GET(BSP.SCB_BASE + BSP.DEMCR, reg); SYSTEM.PUT(BSP.SCB_BASE + BSP.DEMCR, reg - {BSP.TRCENA}); (*disable TRC*)
    SYSTEM.PUT(BSP.SCB_BASE + BSP.DEMCR, reg + {BSP.TRCENA}); (*enable TRC*)
    SYSTEM.GET(BSP.DWTBase + BSP.DWT_CTRL, reg); SYSTEM.PUT(BSP.DWTBase + BSP.DWT_CTRL, reg - {BSP.CYCCNTENA}); (*disable clock cycle counter*)
    SYSTEM.PUT(BSP.DWTBase + BSP.CYCCNT, 0); (*reset clock cycle counter*)
    SYSTEM.PUT(BSP.DWTBase + BSP.DWT_CTRL, reg + {BSP.CYCCNTENA}); (*enable clock cycle counter*)
  END CYCNTInit;

  PROCEDURE SystemClockInit;
    VAR reg: SET;
  BEGIN SYSTEM.PUT(BSP.pwrEn, TRUE); SYSTEM.PUT(BSP.hseOn, TRUE);
    REPEAT UNTIL SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.HSERDY); (*wait until HSE is ready*)
    SYSTEM.PUT(BSP.pllOn, FALSE); (*disable main PLL*)
    REPEAT UNTIL ~SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.PLLRDY); (*wait until PLL is stopped*)
    (*source HSE, PLLQ = 7, PLLP = 2, PLLN = 168, PLLM = 4*)
    SYSTEM.PUT(BSP.RCC_BASE + BSP.PLLCFGR, LSL(SYSTEM.VAL(SET, 7), BSP.PLLQ) + {BSP.PLLSCR} + LSL(SYSTEM.VAL(SET, 2 DIV 2 - 1), BSP.PLLP) +
      LSL(SYSTEM.VAL(SET, 168), BSP.PLLN) + LSL(SYSTEM.VAL(SET, 4), BSP.PLLM));
    SYSTEM.PUT(BSP.pllOn, TRUE); (*disable main PLL*)
    REPEAT UNTIL SYSTEM.BIT(BSP.RCC_BASE + BSP.RCC_CR, BSP.PLLRDY); (*wait until PLL is ready*)

    SYSTEM.GET(BSP.FLASH_BASE + BSP.ACR, reg);
    IF ORD(reg*BSP.LATENCYm) < 5 THEN (*latency must be greater or equal than 5 according to 168MHz CPU clock*)
      SYSTEM.PUT(BSP.FLASH_BASE + BSP.ACR, 5X); (*byte access to LSB of ACR register*)
      REPEAT SYSTEM.GET(BSP.FLASH_BASE + BSP.ACR, reg) UNTIL ORD(reg*BSP.LATENCYm) = 5
    END;
    (*set the highest APBx dividers to ensure that we did not go through a non-spec phase when we increase HCLK,
       set HPRE = 1 and SW = PLL*)
    SYSTEM.GET(BSP.RCC_BASE + BSP.CFGR, reg);
    SYSTEM.PUT(BSP.RCC_BASE + BSP.CFGR, reg - (BSP.PPRE1m + BSP.PPRE2m + BSP.HPREm + BSP.SWm) +
      (LSL(BSP.HCLK_DIV16, BSP.PPRE1) + LSL(BSP.HCLK_DIV16, BSP.PPRE2) + {1}));
    REPEAT SYSTEM.GET(BSP.RCC_BASE + BSP.CFGR, reg) UNTIL (reg*BSP.SWSm) = {3}; (*wait until system clock is ready*)
    (*set target dividers for APB1 and APN2*)
    SYSTEM.PUT(BSP.RCC_BASE + BSP.CFGR, reg - (BSP.PPRE1m + BSP.PPRE2m) + (LSL(BSP.HCLK_DIV4, BSP.PPRE1) + LSL(BSP.HCLK_DIV2, BSP.PPRE2)));
    SYSTEM.PUT(BSP.SYST_RVR, BSP.HCLKFreq*1000 - 1)
  END SystemClockInit;

  PROCEDURE SystemInit;
    VAR reg: SET;
  BEGIN SYSTEM.PUT(BSP.ACTLR, {BSP.DISMCYCINT}); (*disable interrupt on multi_cycle instructions, as a workaround for 2.3.15 SDRAM silicon bug*)
    (*enable instruction cache, data cache and instruction prefetch*)
    SYSTEM.GET(BSP.FLASH_BASE + BSP.ACR, reg); SYSTEM.PUT(BSP.FLASH_BASE + BSP.ACR, reg + {BSP.ICEN, BSP.DCEN, BSP.PRFTEN});
    SYSTEM.PUT(BSP.SCB_BASE + BSP.AIRCR, LSL(5FAH, 16) + LSL(3, 8)); (*4 bits for group priority field*)
    (*set Systick interrupt priority to 10*)
    SYSTEM.PUT(BSP.SCB_BASE + BSP.SHPR1 + (BSP.SysTickExcNum - 4), CHR(LSL(10, 4)));
    SYSTEM.PUT(BSP.syscfgEn, TRUE); SYSTEM.PUT(BSP.pwrEn, TRUE);
    SYSTEM.PUT(BSP.SCB_BASE + BSP.SHPR1 + (BSP.BusFaultExcNum - 4), CHR(LSL(1, 4)));
    SYSTEM.PUT(BSP.SCB_BASE + BSP.SHPR1 + (BSP.UsageFaultExcNum - 4), CHR(LSL(1, 4)));
    SYSTEM.PUT(BSP.SCB_BASE + BSP.SHPR1 + (BSP.SVCallExcNum - 4), CHR(LSL(15, 4)));
    SYSTEM.PUT(BSP.SCB_BASE + BSP.SHPR1 + (BSP.PendSVExcNum - 4), CHR(LSL(15, 4)))
  END SystemInit;

  PROCEDURE RTCInit;
  VAR res: BYTE;
  BEGIN SYSTEM.PUT(BSP.pwrEn, TRUE); (*enable power interface clock*) SYSTEM.GET(BSP.pwrEn, res); (*delay*)
    SYSTEM.PUT(BSP.dbp, TRUE); (*disable backup domain write protection*)
    REPEAT UNTIL SYSTEM.BIT(BSP.PWR_BASE + BSP.PWR_CR, BSP.DBP); (*protection is disabled now*)
  END RTCInit;

BEGIN SystemInit; SystemClockInit; CYCNTInit; SDRAMInit; MPUInit; LoadFromDisk; RTCInit;
  SYSTEM.PUT(BSP.RTC_BASE + BSP.BKPxR + 0, VarORG0);
  SYSTEM.LDREG(PSP, stackOrg); (*initialize process stack*) SYSTEM.LDREG(CONTROL, 2); (*switch to process stack in thread mode*); SYSTEM.MBI(3); (*ISB*)
  SYSTEM.JUMP(VarORG0+1)
END BootLoad.

OM4Tool.DecObj BootLoad.m4c
decode BootLoad.m4c
BootLoad 00000000   0   6720
imports:
	BSP F222E0EE
type descriptors
 00000040 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000080 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000040 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     0
strings

code
commands:
entries
 000019A0 00000004 00000480
pointer refs

fixP =  00000000
fixD =  00000000
fixT =  00000000
entry =  000019A0
 00000000	 F001BCCE	B #6556, goes to  000019A0
 00000004	     B082	SUB SP SP #8
 00000006	     B401	PUSH R0
 00000008	     B500	PUSH LR
 0000000A	 F2410004	MOV R0 #4100
 0000000E	 F2CE0000	MOVT R0 #57344
 00000012	     6800	LDR R0 [ R0 + 0 ]
 00000014	     9002	STR R0 [ SP + 8 ]
 00000016	 F2410004	MOV R0 #4100
 0000001A	 F2CE0000	MOVT R0 #57344
 0000001E	     6800	LDR R0 [ R0 + 0 ]
 00000020	     9003	STR R0 [ SP + 12 ]
 00000022	     9803	LDR R0 [ SP + 12 ]
 00000024	     9902	LDR R1 [ SP + 8 ]
 00000026	     1A40	SUBS R0 R0 R1
 00000028	     21A8	MOVS R1 #168
 0000002A	     9A01	LDR R2 [ SP + 4 ]
 0000002C	     4351	MULS R1 R2 R1
 0000002E	     4288	CMP R0 R1
 00000030	     DBF1	BLT #-30, goes to  00000016
 00000032	 F85DEB04	LDR LR [ SP ] + 4
 00000036	     B003	ADD SP SP #12
 00000038	     4770	BX LR
 0000003A	     B401	PUSH R0
 0000003C	     B500	PUSH LR
 0000003E	     9801	LDR R0 [ SP + 4 ]
 00000040	 F36F201F	BFC R0 #8 #24
 00000044	     0600	LSLS R0 R0 #24
 00000046	     9901	LDR R1 [ SP + 4 ]
 00000048	     0A09	LSRS R1 R1 #8
 0000004A	 F36F211F	BFC R1 #8 #24
 0000004E	     0409	LSLS R1 R1 #16
 00000050	     1840	ADDS R0 R0 R1
 00000052	     9901	LDR R1 [ SP + 4 ]
 00000054	     0C09	LSRS R1 R1 #16
 00000056	 F36F211F	BFC R1 #8 #24
 0000005A	     0209	LSLS R1 R1 #8
 0000005C	     1840	ADDS R0 R0 R1
 0000005E	     9901	LDR R1 [ SP + 4 ]
 00000060	     0E09	LSRS R1 R1 #24
 00000062	 F36F211F	BFC R1 #8 #24
 00000066	     1840	ADDS R0 R0 R1
 00000068	 F85DEB04	LDR LR [ SP ] + 4
 0000006C	     B001	ADD SP SP #4
 0000006E	     4770	BX LR
 00000070	     B082	SUB SP SP #8
 00000072	     B500	PUSH LR
 00000074	     2000	MOVS R0 #0
 00000076	     9001	STR R0 [ SP + 4 ]
 00000078	 F6424034	MOV R0 #11316
 0000007C	 F2C40001	MOVT R0 #16385
 00000080	     6800	LDR R0 [ R0 + 0 ]
 00000082	     9002	STR R0 [ SP + 8 ]
 00000084	     9802	LDR R0 [ SP + 8 ]
 00000086	 F0100080	ANDS R0 R0 #128
 0000008A	 F43FAFF5	BEQ #-22, goes to  00000078
 0000008E	     9802	LDR R0 [ SP + 8 ]
 00000090	 F4106000	ANDS R0 R0 #2048
 00000094	     D1F0	BNE #-32, goes to  00000078
 00000096	 F85DEB04	LDR LR [ SP ] + 4
 0000009A	     B002	ADD SP SP #8
 0000009C	     4770	BX LR
 0000009E	     B082	SUB SP SP #8
 000000A0	     B401	PUSH R0
 000000A2	     B500	PUSH LR
 000000A4	 F6424034	MOV R0 #11316
 000000A8	 F2C40001	MOVT R0 #16385
 000000AC	     6800	LDR R0 [ R0 + 0 ]
 000000AE	     9002	STR R0 [ SP + 8 ]
 000000B0	     9802	LDR R0 [ SP + 8 ]
 000000B2	 F0100045	ANDS R0 R0 #69
 000000B6	 F43FAFF5	BEQ #-22, goes to  000000A4
 000000BA	     9802	LDR R0 [ SP + 8 ]
 000000BC	 F4106000	ANDS R0 R0 #2048
 000000C0	     D1F0	BNE #-32, goes to  000000A4
 000000C2	     9802	LDR R0 [ SP + 8 ]
 000000C4	 F0100005	ANDS R0 R0 #5
 000000C8	     9002	STR R0 [ SP + 8 ]
 000000CA	 F6424038	MOV R0 #11320
 000000CE	 F2C40001	MOVT R0 #16385
 000000D2	     21C5	MOVS R1 #197
 000000D4	     6001	STR R1 [  R0 + 0 ]
 000000D6	     9802	LDR R0 [ SP + 8 ]
 000000D8	     2800	CMP R0 #0
 000000DA	 F04080D4	BNE #424, goes to  00000286
 000000DE	 F6424010	MOV R0 #11280
 000000E2	 F2C40001	MOVT R0 #16385
 000000E6	     6800	LDR R0 [ R0 + 0 ]
 000000E8	     9003	STR R0 [ SP + 12 ]
 000000EA	     9803	LDR R0 [ SP + 12 ]
 000000EC	     9901	LDR R1 [ SP + 4 ]
 000000EE	     4288	CMP R0 R1
 000000F0	 F0008005	BEQ #10, goes to  000000FE
 000000F4	 F45F5000	MOVS R0 #8192
 000000F8	     9002	STR R0 [ SP + 8 ]
 000000FA	 F000B8C4	B #392, goes to  00000286
 000000FE	 F6424014	MOV R0 #11284
 00000102	 F2C40001	MOVT R0 #16385
 00000106	     6800	LDR R0 [ R0 + 0 ]
 00000108	     9003	STR R0 [ SP + 12 ]
 0000010A	     9803	LDR R0 [ SP + 12 ]
 0000010C	 F24E0108	MOV R1 #57352
 00000110	 F6CF51FF	MOVT R1 #65023
 00000114	 EA100001	ANDS R0 R0 R1 LSL #0
 00000118	 F00080B5	BEQ #362, goes to  00000286
 0000011C	     9803	LDR R0 [ SP + 12 ]
 0000011E	 F0104000	ANDS R0 R0 # -2147483648
 00000122	 F0008005	BEQ #10, goes to  00000130
 00000126	 F05F7000	MOVS R0 #33554432
 0000012A	     9002	STR R0 [ SP + 8 ]
 0000012C	 F000B8AB	B #342, goes to  00000286
 00000130	     9803	LDR R0 [ SP + 12 ]
 00000132	 F0104080	ANDS R0 R0 #1073741824
 00000136	 F0008004	BEQ #8, goes to  00000142
 0000013A	     2040	MOVS R0 #64
 0000013C	     9002	STR R0 [ SP + 8 ]
 0000013E	 F000B8A2	B #324, goes to  00000286
 00000142	     9803	LDR R0 [ SP + 12 ]
 00000144	 F0105000	ANDS R0 R0 #536870912
 00000148	 F0008004	BEQ #8, goes to  00000154
 0000014C	     2080	MOVS R0 #128
 0000014E	     9002	STR R0 [ SP + 8 ]
 00000150	 F000B899	B #306, goes to  00000286
 00000154	     9803	LDR R0 [ SP + 12 ]
 00000156	 F0105080	ANDS R0 R0 #268435456
 0000015A	 F0008005	BEQ #10, goes to  00000168
 0000015E	 F45F7080	MOVS R0 #256
 00000162	     9002	STR R0 [ SP + 8 ]
 00000164	 F000B88F	B #286, goes to  00000286
 00000168	     9803	LDR R0 [ SP + 12 ]
 0000016A	 F0106000	ANDS R0 R0 #134217728
 0000016E	 F0008005	BEQ #10, goes to  0000017C
 00000172	 F45F7000	MOVS R0 #512
 00000176	     9002	STR R0 [ SP + 8 ]
 00000178	 F000B885	B #266, goes to  00000286
 0000017C	     9803	LDR R0 [ SP + 12 ]
 0000017E	 F0106080	ANDS R0 R0 #67108864
 00000182	 F0008005	BEQ #10, goes to  00000190
 00000186	 F45F6080	MOVS R0 #1024
 0000018A	     9002	STR R0 [ SP + 8 ]
 0000018C	 F000B87B	B #246, goes to  00000286
 00000190	     9803	LDR R0 [ SP + 12 ]
 00000192	 F0107080	ANDS R0 R0 #16777216
 00000196	 F0008005	BEQ #10, goes to  000001A4
 0000019A	 F45F6000	MOVS R0 #2048
 0000019E	     9002	STR R0 [ SP + 8 ]
 000001A0	 F000B871	B #226, goes to  00000286
 000001A4	     9803	LDR R0 [ SP + 12 ]
 000001A6	 F4100000	ANDS R0 R0 #8388608
 000001AA	 F0008005	BEQ #10, goes to  000001B8
 000001AE	 F45F5080	MOVS R0 #4096
 000001B2	     9002	STR R0 [ SP + 8 ]
 000001B4	 F000B867	B #206, goes to  00000286
 000001B8	     9803	LDR R0 [ SP + 12 ]
 000001BA	 F4100080	ANDS R0 R0 #4194304
 000001BE	 F0008005	BEQ #10, goes to  000001CC
 000001C2	 F45F5000	MOVS R0 #8192
 000001C6	     9002	STR R0 [ SP + 8 ]
 000001C8	 F000B85D	B #186, goes to  00000286
 000001CC	     9803	LDR R0 [ SP + 12 ]
 000001CE	 F4101000	ANDS R0 R0 #2097152
 000001D2	 F0008005	BEQ #10, goes to  000001E0
 000001D6	 F45F4080	MOVS R0 #16384
 000001DA	     9002	STR R0 [ SP + 8 ]
 000001DC	 F000B853	B #166, goes to  00000286
 000001E0	     9803	LDR R0 [ SP + 12 ]
 000001E2	 F4101080	ANDS R0 R0 #1048576
 000001E6	 F0008005	BEQ #10, goes to  000001F4
 000001EA	 F45F4000	MOVS R0 #32768
 000001EE	     9002	STR R0 [ SP + 8 ]
 000001F0	 F000B849	B #146, goes to  00000286
 000001F4	     9803	LDR R0 [ SP + 12 ]
 000001F6	 F4102080	ANDS R0 R0 #262144
 000001FA	 F0008005	BEQ #10, goes to  00000208
 000001FE	 F45F3000	MOVS R0 #131072
 00000202	     9002	STR R0 [ SP + 8 ]
 00000204	 F000B83F	B #126, goes to  00000286
 00000208	     9803	LDR R0 [ SP + 12 ]
 0000020A	 F4103000	ANDS R0 R0 #131072
 0000020E	 F0008005	BEQ #10, goes to  0000021C
 00000212	 F45F2080	MOVS R0 #262144
 00000216	     9002	STR R0 [ SP + 8 ]
 00000218	 F000B835	B #106, goes to  00000286
 0000021C	     9803	LDR R0 [ SP + 12 ]
 0000021E	 F4103080	ANDS R0 R0 #65536
 00000222	 F0008005	BEQ #10, goes to  00000230
 00000226	 F45F2000	MOVS R0 #524288
 0000022A	     9002	STR R0 [ SP + 8 ]
 0000022C	 F000B82B	B #86, goes to  00000286
 00000230	     9803	LDR R0 [ SP + 12 ]
 00000232	 F4104000	ANDS R0 R0 #32768
 00000236	 F0008005	BEQ #10, goes to  00000244
 0000023A	 F45F1080	MOVS R0 #1048576
 0000023E	     9002	STR R0 [ SP + 8 ]
 00000240	 F000B821	B #66, goes to  00000286
 00000244	     9803	LDR R0 [ SP + 12 ]
 00000246	 F4104080	ANDS R0 R0 #16384
 0000024A	 F0008005	BEQ #10, goes to  00000258
 0000024E	 F45F1000	MOVS R0 #2097152
 00000252	     9002	STR R0 [ SP + 8 ]
 00000254	 F000B817	B #46, goes to  00000286
 00000258	     9803	LDR R0 [ SP + 12 ]
 0000025A	 F4105000	ANDS R0 R0 #8192
 0000025E	 F0008005	BEQ #10, goes to  0000026C
 00000262	 F45F0080	MOVS R0 #4194304
 00000266	     9002	STR R0 [ SP + 8 ]
 00000268	 F000B80D	B #26, goes to  00000286
 0000026C	     9803	LDR R0 [ SP + 12 ]
 0000026E	 F0100008	ANDS R0 R0 #8
 00000272	 F0008005	BEQ #10, goes to  00000280
 00000276	 F45F0000	MOVS R0 #8388608
 0000027A	     9002	STR R0 [ SP + 8 ]
 0000027C	 F000B803	B #6, goes to  00000286
 00000280	 F45F3080	MOVS R0 #65536
 00000284	     9002	STR R0 [ SP + 8 ]
 00000286	     9802	LDR R0 [ SP + 8 ]
 00000288	 F85DEB04	LDR LR [ SP ] + 4
 0000028C	     B003	ADD SP SP #12
 0000028E	     4770	BX LR
 00000290	     B081	SUB SP SP #4
 00000292	     B500	PUSH LR
 00000294	 F6424034	MOV R0 #11316
 00000298	 F2C40001	MOVT R0 #16385
 0000029C	     6800	LDR R0 [ R0 + 0 ]
 0000029E	     9001	STR R0 [ SP + 4 ]
 000002A0	     9801	LDR R0 [ SP + 4 ]
 000002A2	 F0100045	ANDS R0 R0 #69
 000002A6	 F43FAFF5	BEQ #-22, goes to  00000294
 000002AA	     9801	LDR R0 [ SP + 4 ]
 000002AC	 F4106000	ANDS R0 R0 #2048
 000002B0	     D1F0	BNE #-32, goes to  00000294
 000002B2	     9801	LDR R0 [ SP + 4 ]
 000002B4	 F0100004	ANDS R0 R0 #4
 000002B8	     9001	STR R0 [ SP + 4 ]
 000002BA	 F6424038	MOV R0 #11320
 000002BE	 F2C40001	MOVT R0 #16385
 000002C2	     21C5	MOVS R1 #197
 000002C4	     6001	STR R1 [  R0 + 0 ]
 000002C6	     9801	LDR R0 [ SP + 4 ]
 000002C8	 F85DEB04	LDR LR [ SP ] + 4
 000002CC	     B001	ADD SP SP #4
 000002CE	     4770	BX LR
 000002D0	     B082	SUB SP SP #8
 000002D2	     B403	PUSH R0 R1
 000002D4	     B500	PUSH LR
 000002D6	     2000	MOVS R0 #0
 000002D8	     9003	STR R0 [ SP + 12 ]
 000002DA	 F6424034	MOV R0 #11316
 000002DE	 F2C40001	MOVT R0 #16385
 000002E2	     6800	LDR R0 [ R0 + 0 ]
 000002E4	     9003	STR R0 [ SP + 12 ]
 000002E6	     9803	LDR R0 [ SP + 12 ]
 000002E8	 F0100045	ANDS R0 R0 #69
 000002EC	 F43FAFF5	BEQ #-22, goes to  000002DA
 000002F0	     9803	LDR R0 [ SP + 12 ]
 000002F2	 F4106000	ANDS R0 R0 #2048
 000002F6	     D1F0	BNE #-32, goes to  000002DA
 000002F8	     9803	LDR R0 [ SP + 12 ]
 000002FA	 F0100005	ANDS R0 R0 #5
 000002FE	     9003	STR R0 [ SP + 12 ]
 00000300	 F6424038	MOV R0 #11320
 00000304	 F2C40001	MOVT R0 #16385
 00000308	     21C5	MOVS R1 #197
 0000030A	     6001	STR R1 [  R0 + 0 ]
 0000030C	     9803	LDR R0 [ SP + 12 ]
 0000030E	     2800	CMP R0 #0
 00000310	 F0408038	BNE #112, goes to  00000384
 00000314	 F6424010	MOV R0 #11280
 00000318	 F2C40001	MOVT R0 #16385
 0000031C	     6800	LDR R0 [ R0 + 0 ]
 0000031E	     9004	STR R0 [ SP + 16 ]
 00000320	     9804	LDR R0 [ SP + 16 ]
 00000322	     9901	LDR R1 [ SP + 4 ]
 00000324	     4288	CMP R0 R1
 00000326	 F0008005	BEQ #10, goes to  00000334
 0000032A	 F45F5000	MOVS R0 #8192
 0000032E	     9003	STR R0 [ SP + 12 ]
 00000330	 F000B828	B #80, goes to  00000384
 00000334	 F6424014	MOV R0 #11284
 00000338	 F2C40001	MOVT R0 #16385
 0000033C	     6800	LDR R0 [ R0 + 0 ]
 0000033E	     9004	STR R0 [ SP + 16 ]
 00000340	     9804	LDR R0 [ SP + 16 ]
 00000342	 F4104060	ANDS R0 R0 #57344
 00000346	 F0408006	BNE #12, goes to  00000356
 0000034A	     9804	LDR R0 [ SP + 16 ]
 0000034C	     0C00	LSRS R0 R0 #16
 0000034E	     9902	LDR R1 [ SP + 8 ]
 00000350	     6008	STR R0 [  R1 + 0 ]
 00000352	 F000B817	B #46, goes to  00000384
 00000356	     9804	LDR R0 [ SP + 16 ]
 00000358	 F4104080	ANDS R0 R0 #16384
 0000035C	 F0008005	BEQ #10, goes to  0000036A
 00000360	 F45F5000	MOVS R0 #8192
 00000364	     9003	STR R0 [ SP + 12 ]
 00000366	 F000B80D	B #26, goes to  00000384
 0000036A	     9804	LDR R0 [ SP + 16 ]
 0000036C	 F4104000	ANDS R0 R0 #32768
 00000370	 F0008005	BEQ #10, goes to  0000037E
 00000374	 F45F5080	MOVS R0 #4096
 00000378	     9003	STR R0 [ SP + 12 ]
 0000037A	 F000B803	B #6, goes to  00000384
 0000037E	 F45F3080	MOVS R0 #65536
 00000382	     9003	STR R0 [ SP + 12 ]
 00000384	     9803	LDR R0 [ SP + 12 ]
 00000386	 F85DEB04	LDR LR [ SP ] + 4
 0000038A	     B004	ADD SP SP #16
 0000038C	     4770	BX LR
 0000038E	     B081	SUB SP SP #4
 00000390	     B500	PUSH LR
 00000392	 F6424034	MOV R0 #11316
 00000396	 F2C40001	MOVT R0 #16385
 0000039A	     6800	LDR R0 [ R0 + 0 ]
 0000039C	     9001	STR R0 [ SP + 4 ]
 0000039E	     9801	LDR R0 [ SP + 4 ]
 000003A0	 F0100045	ANDS R0 R0 #69
 000003A4	 F43FAFF5	BEQ #-22, goes to  00000392
 000003A8	     9801	LDR R0 [ SP + 4 ]
 000003AA	 F4106000	ANDS R0 R0 #2048
 000003AE	     D1F0	BNE #-32, goes to  00000392
 000003B0	     9801	LDR R0 [ SP + 4 ]
 000003B2	 F0100005	ANDS R0 R0 #5
 000003B6	     9001	STR R0 [ SP + 4 ]
 000003B8	 F6424038	MOV R0 #11320
 000003BC	 F2C40001	MOVT R0 #16385
 000003C0	     21C5	MOVS R1 #197
 000003C2	     6001	STR R1 [  R0 + 0 ]
 000003C4	     9801	LDR R0 [ SP + 4 ]
 000003C6	 F85DEB04	LDR LR [ SP ] + 4
 000003CA	     B001	ADD SP SP #4
 000003CC	     4770	BX LR
 000003CE	     B081	SUB SP SP #4
 000003D0	     B401	PUSH R0
 000003D2	     B500	PUSH LR
 000003D4	     9801	LDR R0 [ SP + 4 ]
 000003D6	     6900	LDR R0 [ R0 + 16 ]
 000003D8	     0400	LSLS R0 R0 #16
 000003DA	 F6424108	MOV R1 #11272
 000003DE	 F2C40101	MOVT R1 #16385
 000003E2	     6008	STR R0 [  R1 + 0 ]
 000003E4	 F642400C	MOV R0 #11276
 000003E8	 F2C40001	MOVT R0 #16385
 000003EC	     6800	LDR R0 [ R0 + 0 ]
 000003EE	     9002	STR R0 [ SP + 8 ]
 000003F0	     9802	LDR R0 [ SP + 8 ]
 000003F2	 F64071FF	MOV R1 #4095
 000003F6	 EA300001	BICS R0 R0 R1 LSL #0
 000003FA	 F240414D	MOV R1 #1101
 000003FE	 EA500001	ORRS R0 R0 R1 LSL #0
 00000402	 F642410C	MOV R1 #11276
 00000406	 F2C40101	MOVT R1 #16385
 0000040A	     6008	STR R0 [  R1 + 0 ]
 0000040C	     200D	MOVS R0 #13
 0000040E	 F7FFFE46	BL #-884, goes to  0000009E
 00000412	     9901	LDR R1 [ SP + 4 ]
 00000414	     6809	LDR R1 [ R1 + 0 ]
 00000416	 EA510000	ORRS R0 R1 R0 LSL #0
 0000041A	     9901	LDR R1 [ SP + 4 ]
 0000041C	     6008	STR R0 [  R1 + 0 ]
 0000041E	 F6424014	MOV R0 #11284
 00000422	 F2C40001	MOVT R0 #16385
 00000426	     6800	LDR R0 [ R0 + 0 ]
 00000428	     9002	STR R0 [ SP + 8 ]
 0000042A	     9802	LDR R0 [ SP + 8 ]
 0000042C	     0A40	LSRS R0 R0 #9
 0000042E	 F36F101F	BFC R0 #4 #28
 00000432	 F85DEB04	LDR LR [ SP ] + 4
 00000436	     B002	ADD SP SP #8
 00000438	     4770	BX LR
 0000043A	     B081	SUB SP SP #4
 0000043C	     B500	PUSH LR
 0000043E	 F6424008	MOV R0 #11272
 00000442	 F2C40001	MOVT R0 #16385
 00000446	     2100	MOVS R1 #0
 00000448	     6001	STR R1 [  R0 + 0 ]
 0000044A	 F642400C	MOV R0 #11276
 0000044E	 F2C40001	MOVT R0 #16385
 00000452	     6800	LDR R0 [ R0 + 0 ]
 00000454	     9001	STR R0 [ SP + 4 ]
 00000456	     9801	LDR R0 [ SP + 4 ]
 00000458	 F64071FF	MOV R1 #4095
 0000045C	 EA300001	BICS R0 R0 R1 LSL #0
 00000460	 F240414C	MOV R1 #1100
 00000464	 EA500001	ORRS R0 R0 R1 LSL #0
 00000468	 F642410C	MOV R1 #11276
 0000046C	 F2C40101	MOVT R1 #16385
 00000470	     6008	STR R0 [  R1 + 0 ]
 00000472	     200C	MOVS R0 #12
 00000474	 F7FFFE13	BL #-986, goes to  0000009E
 00000478	 F85DEB04	LDR LR [ SP ] + 4
 0000047C	     B001	ADD SP SP #4
 0000047E	     4770	BX LR
 00000480	     B083	SUB SP SP #12
 00000482	     B40F	PUSH R0 R1 R2 R3
 00000484	     B500	PUSH LR
 00000486	     2000	MOVS R0 #0
 00000488	     9901	LDR R1 [ SP + 4 ]
 0000048A	     6008	STR R0 [  R1 + 0 ]
 0000048C	     9804	LDR R0 [ SP + 16 ]
 0000048E	     2801	CMP R0 #1
 00000490	 F2808004	BGE #8, goes to  0000049C
 00000494	 F05F6000	MOVS R0 #134217728
 00000498	     9901	LDR R1 [ SP + 4 ]
 0000049A	     6008	STR R0 [  R1 + 0 ]
 0000049C	     9803	LDR R0 [ SP + 12 ]
 0000049E	     9904	LDR R1 [ SP + 16 ]
 000004A0	     1840	ADDS R0 R0 R1
 000004A2	     9901	LDR R1 [ SP + 4 ]
 000004A4	     69C9	LDR R1 [ R1 + 28 ]
 000004A6	     4288	CMP R0 R1
 000004A8	 F3408004	BLE #8, goes to  000004B4
 000004AC	 F05F7000	MOVS R0 #33554432
 000004B0	     9901	LDR R1 [ SP + 4 ]
 000004B2	     6008	STR R0 [  R1 + 0 ]
 000004B4	     9801	LDR R0 [ SP + 4 ]
 000004B6	     6800	LDR R0 [ R0 + 0 ]
 000004B8	     2800	CMP R0 #0
 000004BA	 F040813F	BNE #638, goes to  0000073C
 000004BE	 F642402C	MOV R0 #11308
 000004C2	 F2C40001	MOVT R0 #16385
 000004C6	     2100	MOVS R1 #0
 000004C8	     6001	STR R1 [  R0 + 0 ]
 000004CA	 F642403C	MOV R0 #11324
 000004CE	 F2C40001	MOVT R0 #16385
 000004D2	     2100	MOVS R1 #0
 000004D4	     6001	STR R1 [  R0 + 0 ]
 000004D6	 F2464060	MOV R0 #25696
 000004DA	 F2C40002	MOVT R0 #16386
 000004DE	 F6424180	MOV R1 #11392
 000004E2	 F2C40101	MOVT R1 #16385
 000004E6	     6001	STR R1 [  R0 + 0 ]
 000004E8	 F2464064	MOV R0 #25700
 000004EC	 F2C40002	MOVT R0 #16386
 000004F0	     9902	LDR R1 [ SP + 8 ]
 000004F2	     6001	STR R1 [  R0 + 0 ]
 000004F4	 F2464008	MOV R0 #25608
 000004F8	 F2C40002	MOVT R0 #16386
 000004FC	 F05F6174	MOVS R1 #255852544
 00000500	     6001	STR R1 [  R0 + 0 ]
 00000502	 F2464058	MOV R0 #25688
 00000506	 F2C40002	MOVT R0 #16386
 0000050A	     6800	LDR R0 [ R0 + 0 ]
 0000050C	     9005	STR R0 [ SP + 20 ]
 0000050E	     9805	LDR R0 [ SP + 20 ]
 00000510	 F030001E	BICS R0 R0 #30
 00000514	 F2464158	MOV R1 #25688
 00000518	 F2C40102	MOVT R1 #16386
 0000051C	     6008	STR R0 [  R1 + 0 ]
 0000051E	 F246406C	MOV R0 #25708
 00000522	 F2C40002	MOVT R0 #16386
 00000526	     6800	LDR R0 [ R0 + 0 ]
 00000528	     9005	STR R0 [ SP + 20 ]
 0000052A	     9805	LDR R0 [ SP + 20 ]
 0000052C	 F0300080	BICS R0 R0 #128
 00000530	 F246416C	MOV R1 #25708
 00000534	 F2C40102	MOVT R1 #16386
 00000538	     6008	STR R0 [  R1 + 0 ]
 0000053A	 F6483000	MOV R0 #35584
 0000053E	 F2C4204C	MOVT R0 #16972
 00000542	     2101	MOVS R1 #1
 00000544	     6001	STR R1 [  R0 + 0 ]
 00000546	 F248508C	MOV R0 #34188
 0000054A	 F2C42025	MOVT R0 #16933
 0000054E	     2101	MOVS R1 #1
 00000550	     6001	STR R1 [  R0 + 0 ]
 00000552	     9801	LDR R0 [ SP + 4 ]
 00000554	     6840	LDR R0 [ R0 + 4 ]
 00000556	     2801	CMP R0 #1
 00000558	 F0008003	BEQ #6, goes to  00000562
 0000055C	     9803	LDR R0 [ SP + 12 ]
 0000055E	     0240	LSLS R0 R0 #9
 00000560	     9003	STR R0 [ SP + 12 ]
 00000562	 F6424024	MOV R0 #11300
 00000566	 F2C40001	MOVT R0 #16385
 0000056A	 F05F31FF	MOVS R1 #-1
 0000056E	     6001	STR R1 [  R0 + 0 ]
 00000570	     9804	LDR R0 [ SP + 16 ]
 00000572	     0240	LSLS R0 R0 #9
 00000574	 F6424128	MOV R1 #11304
 00000578	 F2C40101	MOVT R1 #16385
 0000057C	     6008	STR R0 [  R1 + 0 ]
 0000057E	 F642402C	MOV R0 #11308
 00000582	 F2C40001	MOVT R0 #16385
 00000586	     6800	LDR R0 [ R0 + 0 ]
 00000588	     9005	STR R0 [ SP + 20 ]
 0000058A	     9805	LDR R0 [ SP + 20 ]
 0000058C	 F03000F7	BICS R0 R0 #247
 00000590	 F0500093	ORRS R0 R0 #147
 00000594	 F642412C	MOV R1 #11308
 00000598	 F2C40101	MOVT R1 #16385
 0000059C	     6008	STR R0 [  R1 + 0 ]
 0000059E	 F6424008	MOV R0 #11272
 000005A2	 F2C40001	MOVT R0 #16385
 000005A6	     9903	LDR R1 [ SP + 12 ]
 000005A8	     6001	STR R1 [  R0 + 0 ]
 000005AA	 F642400C	MOV R0 #11276
 000005AE	 F2C40001	MOVT R0 #16385
 000005B2	     6800	LDR R0 [ R0 + 0 ]
 000005B4	     9005	STR R0 [ SP + 20 ]
 000005B6	     9804	LDR R0 [ SP + 16 ]
 000005B8	     2801	CMP R0 #1
 000005BA	 F3408015	BLE #42, goes to  000005E8
 000005BE	     9805	LDR R0 [ SP + 20 ]
 000005C0	 F64071FF	MOV R1 #4095
 000005C4	 EA300001	BICS R0 R0 R1 LSL #0
 000005C8	 F2404152	MOV R1 #1106
 000005CC	 EA500001	ORRS R0 R0 R1 LSL #0
 000005D0	 F642410C	MOV R1 #11276
 000005D4	 F2C40101	MOVT R1 #16385
 000005D8	     6008	STR R0 [  R1 + 0 ]
 000005DA	     2012	MOVS R0 #18
 000005DC	 F7FFFD5F	BL #-1346, goes to  0000009E
 000005E0	     9901	LDR R1 [ SP + 4 ]
 000005E2	     6008	STR R0 [  R1 + 0 ]
 000005E4	 F000B813	B #38, goes to  0000060E
 000005E8	     9805	LDR R0 [ SP + 20 ]
 000005EA	 F64071FF	MOV R1 #4095
 000005EE	 EA300001	BICS R0 R0 R1 LSL #0
 000005F2	 F2404151	MOV R1 #1105
 000005F6	 EA500001	ORRS R0 R0 R1 LSL #0
 000005FA	 F642410C	MOV R1 #11276
 000005FE	 F2C40101	MOVT R1 #16385
 00000602	     6008	STR R0 [  R1 + 0 ]
 00000604	     2011	MOVS R0 #17
 00000606	 F7FFFD4A	BL #-1388, goes to  0000009E
 0000060A	     9901	LDR R1 [ SP + 4 ]
 0000060C	     6008	STR R0 [  R1 + 0 ]
 0000060E	     9801	LDR R0 [ SP + 4 ]
 00000610	     6800	LDR R0 [ R0 + 0 ]
 00000612	     2800	CMP R0 #0
 00000614	 F0408082	BNE #260, goes to  0000071C
 00000618	 F2464000	MOV R0 #25600
 0000061C	 F2C40002	MOVT R0 #16386
 00000620	     6800	LDR R0 [ R0 + 0 ]
 00000622	     9006	STR R0 [ SP + 24 ]
 00000624	 F6424034	MOV R0 #11316
 00000628	 F2C40001	MOVT R0 #16385
 0000062C	     6800	LDR R0 [ R0 + 0 ]
 0000062E	     9007	STR R0 [ SP + 28 ]
 00000630	     9806	LDR R0 [ SP + 24 ]
 00000632	 EA5F60B0	RORS R0 R0 #26
 00000636	 F1008017	BMI #46, goes to  00000668
 0000063A	     9807	LDR R0 [ SP + 28 ]
 0000063C	 F240312A	MOV R1 #810
 00000640	 EA100001	ANDS R0 R0 R1 LSL #0
 00000644	 F0408010	BNE #32, goes to  00000668
 00000648	     2064	MOVS R0 #100
 0000064A	 F7FFFCDB	BL #-1610, goes to  00000004
 0000064E	 F2464000	MOV R0 #25600
 00000652	 F2C40002	MOVT R0 #16386
 00000656	     6800	LDR R0 [ R0 + 0 ]
 00000658	     9006	STR R0 [ SP + 24 ]
 0000065A	 F6424034	MOV R0 #11316
 0000065E	 F2C40001	MOVT R0 #16385
 00000662	     6800	LDR R0 [ R0 + 0 ]
 00000664	     9007	STR R0 [ SP + 28 ]
 00000666	     E7E3	B #-58, goes to  00000630
 00000668	 F7FFFEE7	BL #-562, goes to  0000043A
 0000066C	     9901	LDR R1 [ SP + 4 ]
 0000066E	     6008	STR R0 [  R1 + 0 ]
 00000670	     9807	LDR R0 [ SP + 28 ]
 00000672	 EA5F2070	RORS R0 R0 #9
 00000676	 F1008051	BMI #162, goes to  0000071C
 0000067A	 F6483000	MOV R0 #35584
 0000067E	 F2C4204C	MOVT R0 #16972
 00000682	     2100	MOVS R1 #0
 00000684	     6001	STR R1 [  R0 + 0 ]
 00000686	     9806	LDR R0 [ SP + 24 ]
 00000688	 EA5F60B0	RORS R0 R0 #26
 0000068C	 F1408006	BPL #12, goes to  0000069C
 00000690	     9801	LDR R0 [ SP + 4 ]
 00000692	     6800	LDR R0 [ R0 + 0 ]
 00000694	 F0504080	ORRS R0 R0 #1073741824
 00000698	     9901	LDR R1 [ SP + 4 ]
 0000069A	     6008	STR R0 [  R1 + 0 ]
 0000069C	     9807	LDR R0 [ SP + 28 ]
 0000069E	 EA5F00B0	RORS R0 R0 #2
 000006A2	 F1408006	BPL #12, goes to  000006B2
 000006A6	     9801	LDR R0 [ SP + 4 ]
 000006A8	     6800	LDR R0 [ R0 + 0 ]
 000006AA	 F0500002	ORRS R0 R0 #2
 000006AE	     9901	LDR R1 [ SP + 4 ]
 000006B0	     6008	STR R0 [  R1 + 0 ]
 000006B2	     9807	LDR R0 [ SP + 28 ]
 000006B4	 EA5F1030	RORS R0 R0 #4
 000006B8	 F1408006	BPL #12, goes to  000006C8
 000006BC	     9801	LDR R0 [ SP + 4 ]
 000006BE	     6800	LDR R0 [ R0 + 0 ]
 000006C0	 F0500008	ORRS R0 R0 #8
 000006C4	     9901	LDR R1 [ SP + 4 ]
 000006C6	     6008	STR R0 [  R1 + 0 ]
 000006C8	     9807	LDR R0 [ SP + 28 ]
 000006CA	 EA5F10B0	RORS R0 R0 #6
 000006CE	 F1408006	BPL #12, goes to  000006DE
 000006D2	     9801	LDR R0 [ SP + 4 ]
 000006D4	     6800	LDR R0 [ R0 + 0 ]
 000006D6	 F0500020	ORRS R0 R0 #32
 000006DA	     9901	LDR R1 [ SP + 4 ]
 000006DC	     6008	STR R0 [  R1 + 0 ]
 000006DE	     9807	LDR R0 [ SP + 28 ]
 000006E0	 EA5F1070	RORS R0 R0 #5
 000006E4	 F1408006	BPL #12, goes to  000006F4
 000006E8	     9801	LDR R0 [ SP + 4 ]
 000006EA	     6800	LDR R0 [ R0 + 0 ]
 000006EC	 F0500010	ORRS R0 R0 #16
 000006F0	     9901	LDR R1 [ SP + 4 ]
 000006F2	     6008	STR R0 [  R1 + 0 ]
 000006F4	     9807	LDR R0 [ SP + 28 ]
 000006F6	 EA5F20B0	RORS R0 R0 #10
 000006FA	 F1408006	BPL #12, goes to  0000070A
 000006FE	     9801	LDR R0 [ SP + 4 ]
 00000700	     6800	LDR R0 [ R0 + 0 ]
 00000702	 F0500008	ORRS R0 R0 #8
 00000706	     9901	LDR R1 [ SP + 4 ]
 00000708	     6008	STR R0 [  R1 + 0 ]
 0000070A	 F6483000	MOV R0 #35584
 0000070E	 F2C4204C	MOVT R0 #16972
 00000712	     6800	LDR R0 [ R0 + 0 ]
 00000714	     9005	STR R0 [ SP + 20 ]
 00000716	     9805	LDR R0 [ SP + 20 ]
 00000718	     2800	CMP R0 #0
 0000071A	     D1F6	BNE #-20, goes to  0000070A
 0000071C	 F2464008	MOV R0 #25608
 00000720	 F2C40002	MOVT R0 #16386
 00000724	 F05F6174	MOVS R1 #255852544
 00000728	     6001	STR R1 [  R0 + 0 ]
 0000072A	 F6424038	MOV R0 #11320
 0000072E	 F2C40001	MOVT R0 #16385
 00000732	 F24071FF	MOV R1 #2047
 00000736	 F2C00140	MOVT R1 #64
 0000073A	     6001	STR R1 [  R0 + 0 ]
 0000073C	     9801	LDR R0 [ SP + 4 ]
 0000073E	     6800	LDR R0 [ R0 + 0 ]
 00000740	 F85DEB04	LDR LR [ SP ] + 4
 00000744	     B007	ADD SP SP #28
 00000746	     4770	BX LR
 00000748	     B081	SUB SP SP #4
 0000074A	     B40F	PUSH R0 R1 R2 R3
 0000074C	     B500	PUSH LR
 0000074E	     9804	LDR R0 [ SP + 16 ]
 00000750	     2880	CMP R0 #128
 00000752	 F3408001	BLE #2, goes to  00000758
 00000756	     E7FE	B #-4, goes to  00000756
 00000758	     9801	LDR R0 [ SP + 4 ]
 0000075A	     9901	LDR R1 [ SP + 4 ]
 0000075C	     6D09	LDR R1 [ R1 + 80 ]
 0000075E	     9A02	LDR R2 [ SP + 8 ]
 00000760	     9B04	LDR R3 [ SP + 16 ]
 00000762	 F7FFFE8D	BL #-742, goes to  00000480
 00000766	     9005	STR R0 [ SP + 20 ]
 00000768	     9805	LDR R0 [ SP + 20 ]
 0000076A	     2800	CMP R0 #0
 0000076C	 F040800B	BNE #22, goes to  00000786
 00000770	     9801	LDR R0 [ SP + 4 ]
 00000772	 F7FFFE2C	BL #-936, goes to  000003CE
 00000776	     2804	CMP R0 #4
 00000778	 F0008005	BEQ #10, goes to  00000786
 0000077C	 F45F707A	MOVS R0 #1000
 00000780	 F7FFFC40	BL #-1920, goes to  00000004
 00000784	     E7F4	B #-24, goes to  00000770
 00000786	     9801	LDR R0 [ SP + 4 ]
 00000788	     6800	LDR R0 [ R0 + 0 ]
 0000078A	     2800	CMP R0 #0
 0000078C	 F040800C	BNE #24, goes to  000007A8
 00000790	     9804	LDR R0 [ SP + 16 ]
 00000792	     01C0	LSLS R0 R0 #7
 00000794	     9901	LDR R1 [ SP + 4 ]
 00000796	     6D09	LDR R1 [ R1 + 80 ]
 00000798	     9A03	LDR R2 [ SP + 12 ]
 0000079A	     D005	BEQ #10, goes to  000007A8
 0000079C	 F8513B04	LDR R3 [ R1 ] + 4
 000007A0	 F8423B04	STR R3 [  R2 ] + 4
 000007A4	     1E40	SUBS R0 R0 #1
 000007A6	     D1F9	BNE #-14, goes to  0000079C
 000007A8	 F85DEB04	LDR LR [ SP ] + 4
 000007AC	     B005	ADD SP SP #20
 000007AE	     4770	BX LR
 000007B0	     B084	SUB SP SP #16
 000007B2	     B401	PUSH R0
 000007B4	     B500	PUSH LR
 000007B6	     2000	MOVS R0 #0
 000007B8	     9003	STR R0 [ SP + 12 ]
 000007BA	     2000	MOVS R0 #0
 000007BC	 F88D0014	STRB R0 [  SP + 20 ]
 000007C0	 F6424008	MOV R0 #11272
 000007C4	 F2C40001	MOVT R0 #16385
 000007C8	     2100	MOVS R1 #0
 000007CA	     6001	STR R1 [  R0 + 0 ]
 000007CC	 F642400C	MOV R0 #11276
 000007D0	 F2C40001	MOVT R0 #16385
 000007D4	     6800	LDR R0 [ R0 + 0 ]
 000007D6	     9002	STR R0 [ SP + 8 ]
 000007D8	     9802	LDR R0 [ SP + 8 ]
 000007DA	 F64071FF	MOV R1 #4095
 000007DE	 EA300001	BICS R0 R0 R1 LSL #0
 000007E2	 F4506080	ORRS R0 R0 #1024
 000007E6	 F642410C	MOV R1 #11276
 000007EA	 F2C40101	MOVT R1 #16385
 000007EE	     6008	STR R0 [  R1 + 0 ]
 000007F0	 F7FFFC3E	BL #-1924, goes to  00000070
 000007F4	 F6424008	MOV R0 #11272
 000007F8	 F2C40001	MOVT R0 #16385
 000007FC	 F45F71D5	MOVS R1 #426
 00000800	     6001	STR R1 [  R0 + 0 ]
 00000802	 F642400C	MOV R0 #11276
 00000806	 F2C40001	MOVT R0 #16385
 0000080A	     6800	LDR R0 [ R0 + 0 ]
 0000080C	     9002	STR R0 [ SP + 8 ]
 0000080E	     9802	LDR R0 [ SP + 8 ]
 00000810	 F64071FF	MOV R1 #4095
 00000814	 EA300001	BICS R0 R0 R1 LSL #0
 00000818	 F4506089	ORRS R0 R0 #1096
 0000081C	 F642410C	MOV R1 #11276
 00000820	 F2C40101	MOVT R1 #16385
 00000824	     6008	STR R0 [  R1 + 0 ]
 00000826	 F7FFFDB2	BL #-1180, goes to  0000038E
 0000082A	     9003	STR R0 [ SP + 12 ]
 0000082C	     9803	LDR R0 [ SP + 12 ]
 0000082E	     2800	CMP R0 #0
 00000830	 F0008007	BEQ #14, goes to  00000842
 00000834	     2000	MOVS R0 #0
 00000836	     9901	LDR R1 [ SP + 4 ]
 00000838	     6088	STR R0 [  R1 + 8 ]
 0000083A	     2000	MOVS R0 #0
 0000083C	     9003	STR R0 [ SP + 12 ]
 0000083E	 F000B803	B #6, goes to  00000848
 00000842	     2001	MOVS R0 #1
 00000844	     9901	LDR R1 [ SP + 4 ]
 00000846	     6088	STR R0 [  R1 + 8 ]
 00000848	     2000	MOVS R0 #0
 0000084A	     9004	STR R0 [ SP + 16 ]
 0000084C	 F6424008	MOV R0 #11272
 00000850	 F2C40001	MOVT R0 #16385
 00000854	     2100	MOVS R1 #0
 00000856	     6001	STR R1 [  R0 + 0 ]
 00000858	 F642400C	MOV R0 #11276
 0000085C	 F2C40001	MOVT R0 #16385
 00000860	     6800	LDR R0 [ R0 + 0 ]
 00000862	     9002	STR R0 [ SP + 8 ]
 00000864	     9802	LDR R0 [ SP + 8 ]
 00000866	 F64071FF	MOV R1 #4095
 0000086A	 EA300001	BICS R0 R0 R1 LSL #0
 0000086E	 F2404177	MOV R1 #1143
 00000872	 EA500001	ORRS R0 R0 R1 LSL #0
 00000876	 F642410C	MOV R1 #11276
 0000087A	 F2C40101	MOVT R1 #16385
 0000087E	     6008	STR R0 [  R1 + 0 ]
 00000880	     2037	MOVS R0 #55
 00000882	 F7FFFC0C	BL #-2024, goes to  0000009E
 00000886	     9003	STR R0 [ SP + 12 ]
 00000888	     9803	LDR R0 [ SP + 12 ]
 0000088A	     2800	CMP R0 #0
 0000088C	 F040801F	BNE #62, goes to  000008CE
 00000890	 F6424008	MOV R0 #11272
 00000894	 F2C40001	MOVT R0 #16385
 00000898	     2100	MOVS R1 #0
 0000089A	 F2CC1102	MOVT R1 #49410
 0000089E	     6001	STR R1 [  R0 + 0 ]
 000008A0	 F642400C	MOV R0 #11276
 000008A4	 F2C40001	MOVT R0 #16385
 000008A8	     6800	LDR R0 [ R0 + 0 ]
 000008AA	     9002	STR R0 [ SP + 8 ]
 000008AC	     9802	LDR R0 [ SP + 8 ]
 000008AE	 F64071FF	MOV R1 #4095
 000008B2	 EA300001	BICS R0 R0 R1 LSL #0
 000008B6	 F2404169	MOV R1 #1129
 000008BA	 EA500001	ORRS R0 R0 R1 LSL #0
 000008BE	 F642410C	MOV R1 #11276
 000008C2	 F2C40101	MOVT R1 #16385
 000008C6	     6008	STR R0 [  R1 + 0 ]
 000008C8	 F7FFFCE2	BL #-1596, goes to  00000290
 000008CC	     9003	STR R0 [ SP + 12 ]
 000008CE	     9803	LDR R0 [ SP + 12 ]
 000008D0	     2800	CMP R0 #0
 000008D2	 F040800F	BNE #30, goes to  000008F4
 000008D6	 F6424014	MOV R0 #11284
 000008DA	 F2C40001	MOVT R0 #16385
 000008DE	     6800	LDR R0 [ R0 + 0 ]
 000008E0	     9002	STR R0 [ SP + 8 ]
 000008E2	     9802	LDR R0 [ SP + 8 ]
 000008E4	     0FC0	LSRS R0 R0 #31
 000008E6	 EA5F0070	RORS R0 R0 #1
 000008EA	     BF4C	ITE MI
 000008EC	     2001	MOVMI R0 #1
 000008EE	     2000	MOVPL R0 #0
 000008F0	 F88D0014	STRB R0 [  SP + 20 ]
 000008F4	     9804	LDR R0 [ SP + 16 ]
 000008F6	     1C40	ADDS R0 R0 #1
 000008F8	     9004	STR R0 [ SP + 16 ]
 000008FA	 F89D0014	LDRB R0 [ SP + 20 ]
 000008FE	     2800	CMP R0 #0
 00000900	 F0408009	BNE #18, goes to  00000916
 00000904	     9803	LDR R0 [ SP + 12 ]
 00000906	     2800	CMP R0 #0
 00000908	 F0408005	BNE #10, goes to  00000916
 0000090C	     9804	LDR R0 [ SP + 16 ]
 0000090E	 F64F71FF	MOV R1 #65535
 00000912	     4288	CMP R0 R1
 00000914	     DD9A	BLE #-204, goes to  0000084C
 00000916	 F89D0014	LDRB R0 [ SP + 20 ]
 0000091A	     2800	CMP R0 #0
 0000091C	 F000800F	BEQ #30, goes to  0000093E
 00000920	     9802	LDR R0 [ SP + 8 ]
 00000922	 F0104080	ANDS R0 R0 #1073741824
 00000926	 F0008005	BEQ #10, goes to  00000934
 0000092A	     2001	MOVS R0 #1
 0000092C	     9901	LDR R1 [ SP + 4 ]
 0000092E	     6048	STR R0 [  R1 + 4 ]
 00000930	 F000B803	B #6, goes to  0000093A
 00000934	     2000	MOVS R0 #0
 00000936	     9901	LDR R1 [ SP + 4 ]
 00000938	     6048	STR R0 [  R1 + 4 ]
 0000093A	 F000B803	B #6, goes to  00000944
 0000093E	 F05F7080	MOVS R0 #16777216
 00000942	     9003	STR R0 [ SP + 12 ]
 00000944	     9803	LDR R0 [ SP + 12 ]
 00000946	 F85DEB04	LDR LR [ SP ] + 4
 0000094A	     B005	ADD SP SP #20
 0000094C	     4770	BX LR
 0000094E	     B081	SUB SP SP #4
 00000950	     B403	PUSH R0 R1
 00000952	     B500	PUSH LR
 00000954	     2000	MOVS R0 #0
 00000956	     9003	STR R0 [ SP + 12 ]
 00000958	     9801	LDR R0 [ SP + 4 ]
 0000095A	     6B40	LDR R0 [ R0 + 52 ]
 0000095C	     0F80	LSRS R0 R0 #30
 0000095E	 F36F009F	BFC R0 #2 #30
 00000962	     9902	LDR R1 [ SP + 8 ]
 00000964	     7008	STRB R0 [ R1 + 0 ]
 00000966	     9801	LDR R0 [ SP + 4 ]
 00000968	     6B40	LDR R0 [ R0 + 52 ]
 0000096A	     0C00	LSRS R0 R0 #16
 0000096C	 F36F201F	BFC R0 #8 #24
 00000970	     9902	LDR R1 [ SP + 8 ]
 00000972	     7048	STRB R0 [ R1 + 1 ]
 00000974	     9801	LDR R0 [ SP + 4 ]
 00000976	     6B40	LDR R0 [ R0 + 52 ]
 00000978	     0A00	LSRS R0 R0 #8
 0000097A	 F36F201F	BFC R0 #8 #24
 0000097E	     9902	LDR R1 [ SP + 8 ]
 00000980	     7088	STRB R0 [ R1 + 2 ]
 00000982	     9801	LDR R0 [ SP + 4 ]
 00000984	     6B40	LDR R0 [ R0 + 52 ]
 00000986	 F36F201F	BFC R0 #8 #24
 0000098A	     9902	LDR R1 [ SP + 8 ]
 0000098C	     70C8	STRB R0 [ R1 + 3 ]
 0000098E	     9801	LDR R0 [ SP + 4 ]
 00000990	     6B80	LDR R0 [ R0 + 56 ]
 00000992	     0D00	LSRS R0 R0 #20
 00000994	 F36F301F	BFC R0 #12 #20
 00000998	     9902	LDR R1 [ SP + 8 ]
 0000099A	     6048	STR R0 [  R1 + 4 ]
 0000099C	     9801	LDR R0 [ SP + 4 ]
 0000099E	     6B80	LDR R0 [ R0 + 56 ]
 000009A0	     0C00	LSRS R0 R0 #16
 000009A2	 F36F101F	BFC R0 #4 #28
 000009A6	     9902	LDR R1 [ SP + 8 ]
 000009A8	     7208	STRB R0 [ R1 + 8 ]
 000009AA	     9801	LDR R0 [ SP + 4 ]
 000009AC	     6B80	LDR R0 [ R0 + 56 ]
 000009AE	     0BC0	LSRS R0 R0 #15
 000009B0	 EA5F0070	RORS R0 R0 #1
 000009B4	     BF4C	ITE MI
 000009B6	     2001	MOVMI R0 #1
 000009B8	     2000	MOVPL R0 #0
 000009BA	     9902	LDR R1 [ SP + 8 ]
 000009BC	     7248	STRB R0 [ R1 + 9 ]
 000009BE	     9801	LDR R0 [ SP + 4 ]
 000009C0	     6B80	LDR R0 [ R0 + 56 ]
 000009C2	     0B80	LSRS R0 R0 #14
 000009C4	 EA5F0070	RORS R0 R0 #1
 000009C8	     BF4C	ITE MI
 000009CA	     2001	MOVMI R0 #1
 000009CC	     2000	MOVPL R0 #0
 000009CE	     9902	LDR R1 [ SP + 8 ]
 000009D0	     7288	STRB R0 [ R1 + 10 ]
 000009D2	     9801	LDR R0 [ SP + 4 ]
 000009D4	     6B80	LDR R0 [ R0 + 56 ]
 000009D6	     0B40	LSRS R0 R0 #13
 000009D8	 EA5F0070	RORS R0 R0 #1
 000009DC	     BF4C	ITE MI
 000009DE	     2001	MOVMI R0 #1
 000009E0	     2000	MOVPL R0 #0
 000009E2	     9902	LDR R1 [ SP + 8 ]
 000009E4	     72C8	STRB R0 [ R1 + 11 ]
 000009E6	     9801	LDR R0 [ SP + 4 ]
 000009E8	     6B80	LDR R0 [ R0 + 56 ]
 000009EA	     0B00	LSRS R0 R0 #12
 000009EC	 EA5F0070	RORS R0 R0 #1
 000009F0	     BF4C	ITE MI
 000009F2	     2001	MOVMI R0 #1
 000009F4	     2000	MOVPL R0 #0
 000009F6	     9902	LDR R1 [ SP + 8 ]
 000009F8	     7308	STRB R0 [ R1 + 12 ]
 000009FA	     9801	LDR R0 [ SP + 4 ]
 000009FC	     6840	LDR R0 [ R0 + 4 ]
 000009FE	     2800	CMP R0 #0
 00000A00	 F0408050	BNE #160, goes to  00000AA4
 00000A04	     9801	LDR R0 [ SP + 4 ]
 00000A06	     6B80	LDR R0 [ R0 + 56 ]
 00000A08	 F36F209F	BFC R0 #10 #22
 00000A0C	     0080	LSLS R0 R0 #2
 00000A0E	     9901	LDR R1 [ SP + 4 ]
 00000A10	     6BC9	LDR R1 [ R1 + 60 ]
 00000A12	     0F89	LSRS R1 R1 #30
 00000A14	 F36F019F	BFC R1 #2 #30
 00000A18	     1840	ADDS R0 R0 R1
 00000A1A	     9902	LDR R1 [ SP + 8 ]
 00000A1C	     6108	STR R0 [  R1 + 16 ]
 00000A1E	     9801	LDR R0 [ SP + 4 ]
 00000A20	     6BC0	LDR R0 [ R0 + 60 ]
 00000A22	     0EC0	LSRS R0 R0 #27
 00000A24	 F36F00DF	BFC R0 #3 #29
 00000A28	     9902	LDR R1 [ SP + 8 ]
 00000A2A	     7508	STRB R0 [ R1 + 20 ]
 00000A2C	     9801	LDR R0 [ SP + 4 ]
 00000A2E	     6BC0	LDR R0 [ R0 + 60 ]
 00000A30	     0E00	LSRS R0 R0 #24
 00000A32	 F36F00DF	BFC R0 #3 #29
 00000A36	     9902	LDR R1 [ SP + 8 ]
 00000A38	     7548	STRB R0 [ R1 + 21 ]
 00000A3A	     9801	LDR R0 [ SP + 4 ]
 00000A3C	     6BC0	LDR R0 [ R0 + 60 ]
 00000A3E	     0D40	LSRS R0 R0 #21
 00000A40	 F36F00DF	BFC R0 #3 #29
 00000A44	     9902	LDR R1 [ SP + 8 ]
 00000A46	     7588	STRB R0 [ R1 + 22 ]
 00000A48	     9801	LDR R0 [ SP + 4 ]
 00000A4A	     6BC0	LDR R0 [ R0 + 60 ]
 00000A4C	     0C80	LSRS R0 R0 #18
 00000A4E	 F36F00DF	BFC R0 #3 #29
 00000A52	     9902	LDR R1 [ SP + 8 ]
 00000A54	     75C8	STRB R0 [ R1 + 23 ]
 00000A56	     9801	LDR R0 [ SP + 4 ]
 00000A58	     6BC0	LDR R0 [ R0 + 60 ]
 00000A5A	     0BC0	LSRS R0 R0 #15
 00000A5C	 F36F00DF	BFC R0 #3 #29
 00000A60	     9902	LDR R1 [ SP + 8 ]
 00000A62	     7608	STRB R0 [ R1 + 24 ]
 00000A64	     9802	LDR R0 [ SP + 8 ]
 00000A66	     6900	LDR R0 [ R0 + 16 ]
 00000A68	     1C40	ADDS R0 R0 #1
 00000A6A	     9902	LDR R1 [ SP + 8 ]
 00000A6C	     7E09	LDRB R1 [ R1 + 24 ]
 00000A6E	     1C89	ADDS R1 R1 #2
 00000A70	     2201	MOVS R2 #1
 00000A72	 FA12F101	LSLS R1 R2 R1
 00000A76	     4348	MULS R0 R1 R0
 00000A78	     9901	LDR R1 [ SP + 4 ]
 00000A7A	     6148	STR R0 [  R1 + 20 ]
 00000A7C	     2001	MOVS R0 #1
 00000A7E	     9902	LDR R1 [ SP + 8 ]
 00000A80	     7A09	LDRB R1 [ R1 + 8 ]
 00000A82	     4088	LSLS R0 R0 R1
 00000A84	     9901	LDR R1 [ SP + 4 ]
 00000A86	     6188	STR R0 [  R1 + 24 ]
 00000A88	     9801	LDR R0 [ SP + 4 ]
 00000A8A	     6940	LDR R0 [ R0 + 20 ]
 00000A8C	     9901	LDR R1 [ SP + 4 ]
 00000A8E	     6989	LDR R1 [ R1 + 24 ]
 00000A90	     4348	MULS R0 R1 R0
 00000A92	     1240	ASRS R0 R0 #9
 00000A94	     9901	LDR R1 [ SP + 4 ]
 00000A96	     61C8	STR R0 [  R1 + 28 ]
 00000A98	 F45F7000	MOVS R0 #512
 00000A9C	     9901	LDR R1 [ SP + 4 ]
 00000A9E	     6208	STR R0 [  R1 + 32 ]
 00000AA0	 F000B82D	B #90, goes to  00000AFE
 00000AA4	     9801	LDR R0 [ SP + 4 ]
 00000AA6	     6840	LDR R0 [ R0 + 4 ]
 00000AA8	     2801	CMP R0 #1
 00000AAA	 F0408021	BNE #66, goes to  00000AF0
 00000AAE	     9801	LDR R0 [ SP + 4 ]
 00000AB0	     6B80	LDR R0 [ R0 + 56 ]
 00000AB2	 F36F109F	BFC R0 #6 #26
 00000AB6	     0400	LSLS R0 R0 #16
 00000AB8	     9901	LDR R1 [ SP + 4 ]
 00000ABA	     6BC9	LDR R1 [ R1 + 60 ]
 00000ABC	     0C09	LSRS R1 R1 #16
 00000ABE	 F36F411F	BFC R1 #16 #16
 00000AC2	     1840	ADDS R0 R0 R1
 00000AC4	     9902	LDR R1 [ SP + 8 ]
 00000AC6	     6108	STR R0 [  R1 + 16 ]
 00000AC8	     9802	LDR R0 [ SP + 8 ]
 00000ACA	     6900	LDR R0 [ R0 + 16 ]
 00000ACC	     1C40	ADDS R0 R0 #1
 00000ACE	     0280	LSLS R0 R0 #10
 00000AD0	     9901	LDR R1 [ SP + 4 ]
 00000AD2	     6148	STR R0 [  R1 + 20 ]
 00000AD4	 F45F7000	MOVS R0 #512
 00000AD8	     9901	LDR R1 [ SP + 4 ]
 00000ADA	     6188	STR R0 [  R1 + 24 ]
 00000ADC	     9801	LDR R0 [ SP + 4 ]
 00000ADE	     6940	LDR R0 [ R0 + 20 ]
 00000AE0	     9901	LDR R1 [ SP + 4 ]
 00000AE2	     61C8	STR R0 [  R1 + 28 ]
 00000AE4	     9801	LDR R0 [ SP + 4 ]
 00000AE6	     6980	LDR R0 [ R0 + 24 ]
 00000AE8	     9901	LDR R1 [ SP + 4 ]
 00000AEA	     6208	STR R0 [  R1 + 32 ]
 00000AEC	 F000B807	B #14, goes to  00000AFE
 00000AF0	 F05F5080	MOVS R0 #268435456
 00000AF4	     9901	LDR R1 [ SP + 4 ]
 00000AF6	     6008	STR R0 [  R1 + 0 ]
 00000AF8	 F05F5080	MOVS R0 #268435456
 00000AFC	     9003	STR R0 [ SP + 12 ]
 00000AFE	     9803	LDR R0 [ SP + 12 ]
 00000B00	     2800	CMP R0 #0
 00000B02	 F0408072	BNE #228, goes to  00000BEA
 00000B06	     9801	LDR R0 [ SP + 4 ]
 00000B08	     6BC0	LDR R0 [ R0 + 60 ]
 00000B0A	     0B80	LSRS R0 R0 #14
 00000B0C	 EA5F0070	RORS R0 R0 #1
 00000B10	     BF4C	ITE MI
 00000B12	     2001	MOVMI R0 #1
 00000B14	     2000	MOVPL R0 #0
 00000B16	     9902	LDR R1 [ SP + 8 ]
 00000B18	     7648	STRB R0 [ R1 + 25 ]
 00000B1A	     9801	LDR R0 [ SP + 4 ]
 00000B1C	     6BC0	LDR R0 [ R0 + 60 ]
 00000B1E	     09C0	LSRS R0 R0 #7
 00000B20	 F36F10DF	BFC R0 #7 #25
 00000B24	     9902	LDR R1 [ SP + 8 ]
 00000B26	     7688	STRB R0 [ R1 + 26 ]
 00000B28	     9801	LDR R0 [ SP + 4 ]
 00000B2A	     6BC0	LDR R0 [ R0 + 60 ]
 00000B2C	 F36F10DF	BFC R0 #7 #25
 00000B30	     9902	LDR R1 [ SP + 8 ]
 00000B32	     76C8	STRB R0 [ R1 + 27 ]
 00000B34	     9801	LDR R0 [ SP + 4 ]
 00000B36	     6C00	LDR R0 [ R0 + 64 ]
 00000B38	     0FC0	LSRS R0 R0 #31
 00000B3A	 EA5F0070	RORS R0 R0 #1
 00000B3E	     BF4C	ITE MI
 00000B40	     2001	MOVMI R0 #1
 00000B42	     2000	MOVPL R0 #0
 00000B44	     9902	LDR R1 [ SP + 8 ]
 00000B46	     7708	STRB R0 [ R1 + 28 ]
 00000B48	     9801	LDR R0 [ SP + 4 ]
 00000B4A	     6C00	LDR R0 [ R0 + 64 ]
 00000B4C	     0E80	LSRS R0 R0 #26
 00000B4E	 F36F00DF	BFC R0 #3 #29
 00000B52	     9902	LDR R1 [ SP + 8 ]
 00000B54	     7748	STRB R0 [ R1 + 29 ]
 00000B56	     9801	LDR R0 [ SP + 4 ]
 00000B58	     6C00	LDR R0 [ R0 + 64 ]
 00000B5A	     0D80	LSRS R0 R0 #22
 00000B5C	 F36F101F	BFC R0 #4 #28
 00000B60	     9902	LDR R1 [ SP + 8 ]
 00000B62	     7788	STRB R0 [ R1 + 30 ]
 00000B64	     9801	LDR R0 [ SP + 4 ]
 00000B66	     6C00	LDR R0 [ R0 + 64 ]
 00000B68	     0D40	LSRS R0 R0 #21
 00000B6A	 EA5F0070	RORS R0 R0 #1
 00000B6E	     BF4C	ITE MI
 00000B70	     2001	MOVMI R0 #1
 00000B72	     2000	MOVPL R0 #0
 00000B74	     9902	LDR R1 [ SP + 8 ]
 00000B76	     77C8	STRB R0 [ R1 + 31 ]
 00000B78	     9801	LDR R0 [ SP + 4 ]
 00000B7A	     6C00	LDR R0 [ R0 + 64 ]
 00000B7C	     0BC0	LSRS R0 R0 #15
 00000B7E	 F36F005F	BFC R0 #1 #31
 00000B82	     9902	LDR R1 [ SP + 8 ]
 00000B84	 F8810020	STRB R0 [  R1 + 32 ]
 00000B88	     9801	LDR R0 [ SP + 4 ]
 00000B8A	     6C00	LDR R0 [ R0 + 64 ]
 00000B8C	     0B80	LSRS R0 R0 #14
 00000B8E	 EA5F0070	RORS R0 R0 #1
 00000B92	     BF4C	ITE MI
 00000B94	     2001	MOVMI R0 #1
 00000B96	     2000	MOVPL R0 #0
 00000B98	     9902	LDR R1 [ SP + 8 ]
 00000B9A	 F8810021	STRB R0 [  R1 + 33 ]
 00000B9E	     9801	LDR R0 [ SP + 4 ]
 00000BA0	     6C00	LDR R0 [ R0 + 64 ]
 00000BA2	     0B40	LSRS R0 R0 #13
 00000BA4	 EA5F0070	RORS R0 R0 #1
 00000BA8	     BF4C	ITE MI
 00000BAA	     2001	MOVMI R0 #1
 00000BAC	     2000	MOVPL R0 #0
 00000BAE	     9902	LDR R1 [ SP + 8 ]
 00000BB0	 F8810022	STRB R0 [  R1 + 34 ]
 00000BB4	     9801	LDR R0 [ SP + 4 ]
 00000BB6	     6C00	LDR R0 [ R0 + 64 ]
 00000BB8	     0B00	LSRS R0 R0 #12
 00000BBA	 EA5F0070	RORS R0 R0 #1
 00000BBE	     BF4C	ITE MI
 00000BC0	     2001	MOVMI R0 #1
 00000BC2	     2000	MOVPL R0 #0
 00000BC4	     9902	LDR R1 [ SP + 8 ]
 00000BC6	 F8810023	STRB R0 [  R1 + 35 ]
 00000BCA	     9801	LDR R0 [ SP + 4 ]
 00000BCC	     6C00	LDR R0 [ R0 + 64 ]
 00000BCE	     0A80	LSRS R0 R0 #10
 00000BD0	 F36F009F	BFC R0 #2 #30
 00000BD4	     9902	LDR R1 [ SP + 8 ]
 00000BD6	 F8810024	STRB R0 [  R1 + 36 ]
 00000BDA	     9801	LDR R0 [ SP + 4 ]
 00000BDC	     6C00	LDR R0 [ R0 + 64 ]
 00000BDE	     0840	LSRS R0 R0 #1
 00000BE0	 F36F10DF	BFC R0 #7 #25
 00000BE4	     9902	LDR R1 [ SP + 8 ]
 00000BE6	 F8810025	STRB R0 [  R1 + 37 ]
 00000BEA	     9803	LDR R0 [ SP + 12 ]
 00000BEC	 F85DEB04	LDR LR [ SP ] + 4
 00000BF0	     B003	ADD SP SP #12
 00000BF2	     4770	BX LR
 00000BF4	     B08D	SUB SP SP #52
 00000BF6	     B401	PUSH R0
 00000BF8	     B500	PUSH LR
 00000BFA	     2000	MOVS R0 #0
 00000BFC	     900D	STR R0 [ SP + 52 ]
 00000BFE	 F6424000	MOV R0 #11264
 00000C02	 F2C40001	MOVT R0 #16385
 00000C06	     6800	LDR R0 [ R0 + 0 ]
 00000C08	     900C	STR R0 [ SP + 48 ]
 00000C0A	     980C	LDR R0 [ SP + 48 ]
 00000C0C	 F0100003	ANDS R0 R0 #3
 00000C10	     2803	CMP R0 #3
 00000C12	 F0008003	BEQ #6, goes to  00000C1C
 00000C16	 F05F6080	MOVS R0 #67108864
 00000C1A	     900D	STR R0 [ SP + 52 ]
 00000C1C	     980D	LDR R0 [ SP + 52 ]
 00000C1E	     2800	CMP R0 #0
 00000C20	 F04080D4	BNE #424, goes to  00000DCC
 00000C24	 F6424008	MOV R0 #11272
 00000C28	 F2C40001	MOVT R0 #16385
 00000C2C	     2100	MOVS R1 #0
 00000C2E	     6001	STR R1 [  R0 + 0 ]
 00000C30	 F642400C	MOV R0 #11276
 00000C34	 F2C40001	MOVT R0 #16385
 00000C38	     6800	LDR R0 [ R0 + 0 ]
 00000C3A	     900C	STR R0 [ SP + 48 ]
 00000C3C	     980C	LDR R0 [ SP + 48 ]
 00000C3E	 F64071FF	MOV R1 #4095
 00000C42	 EA300001	BICS R0 R0 R1 LSL #0
 00000C46	 F24041C2	MOV R1 #1218
 00000C4A	 EA500001	ORRS R0 R0 R1 LSL #0
 00000C4E	 F642410C	MOV R1 #11276
 00000C52	 F2C40101	MOVT R1 #16385
 00000C56	     6008	STR R0 [  R1 + 0 ]
 00000C58	 F7FFFB99	BL #-2254, goes to  0000038E
 00000C5C	     900D	STR R0 [ SP + 52 ]
 00000C5E	     980D	LDR R0 [ SP + 52 ]
 00000C60	     2800	CMP R0 #0
 00000C62	 F040801C	BNE #56, goes to  00000C9E
 00000C66	 F6424014	MOV R0 #11284
 00000C6A	 F2C40001	MOVT R0 #16385
 00000C6E	     6800	LDR R0 [ R0 + 0 ]
 00000C70	     9901	LDR R1 [ SP + 4 ]
 00000C72	     6248	STR R0 [  R1 + 36 ]
 00000C74	 F6424018	MOV R0 #11288
 00000C78	 F2C40001	MOVT R0 #16385
 00000C7C	     6800	LDR R0 [ R0 + 0 ]
 00000C7E	     9901	LDR R1 [ SP + 4 ]
 00000C80	     6288	STR R0 [  R1 + 40 ]
 00000C82	 F642401C	MOV R0 #11292
 00000C86	 F2C40001	MOVT R0 #16385
 00000C8A	     6800	LDR R0 [ R0 + 0 ]
 00000C8C	     9901	LDR R1 [ SP + 4 ]
 00000C8E	     62C8	STR R0 [  R1 + 44 ]
 00000C90	 F6424020	MOV R0 #11296
 00000C94	 F2C40001	MOVT R0 #16385
 00000C98	     6800	LDR R0 [ R0 + 0 ]
 00000C9A	     9901	LDR R1 [ SP + 4 ]
 00000C9C	     6308	STR R0 [  R1 + 48 ]
 00000C9E	     980D	LDR R0 [ SP + 52 ]
 00000CA0	     2800	CMP R0 #0
 00000CA2	 F040801F	BNE #62, goes to  00000CE4
 00000CA6	 F6424008	MOV R0 #11272
 00000CAA	 F2C40001	MOVT R0 #16385
 00000CAE	     2100	MOVS R1 #0
 00000CB0	     6001	STR R1 [  R0 + 0 ]
 00000CB2	 F642400C	MOV R0 #11276
 00000CB6	 F2C40001	MOVT R0 #16385
 00000CBA	     6800	LDR R0 [ R0 + 0 ]
 00000CBC	     900C	STR R0 [ SP + 48 ]
 00000CBE	     980C	LDR R0 [ SP + 48 ]
 00000CC0	 F64071FF	MOV R1 #4095
 00000CC4	 EA300001	BICS R0 R0 R1 LSL #0
 00000CC8	 F2404143	MOV R1 #1091
 00000CCC	 EA500001	ORRS R0 R0 R1 LSL #0
 00000CD0	 F642410C	MOV R1 #11276
 00000CD4	 F2C40101	MOVT R1 #16385
 00000CD8	     6008	STR R0 [  R1 + 0 ]
 00000CDA	     2003	MOVS R0 #3
 00000CDC	     A90E	ADD R1 SP #56
 00000CDE	 F7FFFAF7	BL #-2578, goes to  000002D0
 00000CE2	     900D	STR R0 [ SP + 52 ]
 00000CE4	     980D	LDR R0 [ SP + 52 ]
 00000CE6	     2800	CMP R0 #0
 00000CE8	 F0408022	BNE #68, goes to  00000D30
 00000CEC	     980E	LDR R0 [ SP + 56 ]
 00000CEE	     9901	LDR R1 [ SP + 4 ]
 00000CF0	     6108	STR R0 [  R1 + 16 ]
 00000CF2	     9801	LDR R0 [ SP + 4 ]
 00000CF4	     6900	LDR R0 [ R0 + 16 ]
 00000CF6	     0400	LSLS R0 R0 #16
 00000CF8	 F6424108	MOV R1 #11272
 00000CFC	 F2C40101	MOVT R1 #16385
 00000D00	     6008	STR R0 [  R1 + 0 ]
 00000D02	 F642400C	MOV R0 #11276
 00000D06	 F2C40001	MOVT R0 #16385
 00000D0A	     6800	LDR R0 [ R0 + 0 ]
 00000D0C	     900C	STR R0 [ SP + 48 ]
 00000D0E	     980C	LDR R0 [ SP + 48 ]
 00000D10	 F64071FF	MOV R1 #4095
 00000D14	 EA300001	BICS R0 R0 R1 LSL #0
 00000D18	 F24041C9	MOV R1 #1225
 00000D1C	 EA500001	ORRS R0 R0 R1 LSL #0
 00000D20	 F642410C	MOV R1 #11276
 00000D24	 F2C40101	MOVT R1 #16385
 00000D28	     6008	STR R0 [  R1 + 0 ]
 00000D2A	 F7FFFB30	BL #-2464, goes to  0000038E
 00000D2E	     900D	STR R0 [ SP + 52 ]
 00000D30	     980D	LDR R0 [ SP + 52 ]
 00000D32	     2800	CMP R0 #0
 00000D34	 F0408026	BNE #76, goes to  00000D84
 00000D38	 F6424014	MOV R0 #11284
 00000D3C	 F2C40001	MOVT R0 #16385
 00000D40	     6800	LDR R0 [ R0 + 0 ]
 00000D42	     9901	LDR R1 [ SP + 4 ]
 00000D44	     6348	STR R0 [  R1 + 52 ]
 00000D46	 F6424018	MOV R0 #11288
 00000D4A	 F2C40001	MOVT R0 #16385
 00000D4E	     6800	LDR R0 [ R0 + 0 ]
 00000D50	     9901	LDR R1 [ SP + 4 ]
 00000D52	     6388	STR R0 [  R1 + 56 ]
 00000D54	 F642401C	MOV R0 #11292
 00000D58	 F2C40001	MOVT R0 #16385
 00000D5C	     6800	LDR R0 [ R0 + 0 ]
 00000D5E	     9901	LDR R1 [ SP + 4 ]
 00000D60	     63C8	STR R0 [  R1 + 60 ]
 00000D62	 F6424020	MOV R0 #11296
 00000D66	 F2C40001	MOVT R0 #16385
 00000D6A	     6800	LDR R0 [ R0 + 0 ]
 00000D6C	     9901	LDR R1 [ SP + 4 ]
 00000D6E	     6408	STR R0 [  R1 + 64 ]
 00000D70	     9801	LDR R0 [ SP + 4 ]
 00000D72	     6B80	LDR R0 [ R0 + 56 ]
 00000D74	     0D00	LSRS R0 R0 #20
 00000D76	     9901	LDR R1 [ SP + 4 ]
 00000D78	     60C8	STR R0 [  R1 + 12 ]
 00000D7A	     9801	LDR R0 [ SP + 4 ]
 00000D7C	     A902	ADD R1 SP #8
 00000D7E	 F7FFFDE6	BL #-1076, goes to  0000094E
 00000D82	     900D	STR R0 [ SP + 52 ]
 00000D84	     980D	LDR R0 [ SP + 52 ]
 00000D86	     2800	CMP R0 #0
 00000D88	 F0408020	BNE #64, goes to  00000DCC
 00000D8C	     9801	LDR R0 [ SP + 4 ]
 00000D8E	     6900	LDR R0 [ R0 + 16 ]
 00000D90	     0400	LSLS R0 R0 #16
 00000D92	 F6424108	MOV R1 #11272
 00000D96	 F2C40101	MOVT R1 #16385
 00000D9A	     6008	STR R0 [  R1 + 0 ]
 00000D9C	 F642400C	MOV R0 #11276
 00000DA0	 F2C40001	MOVT R0 #16385
 00000DA4	     6800	LDR R0 [ R0 + 0 ]
 00000DA6	     900C	STR R0 [ SP + 48 ]
 00000DA8	     980C	LDR R0 [ SP + 48 ]
 00000DAA	 F64071FF	MOV R1 #4095
 00000DAE	 EA300001	BICS R0 R0 R1 LSL #0
 00000DB2	 F2404147	MOV R1 #1095
 00000DB6	 EA500001	ORRS R0 R0 R1 LSL #0
 00000DBA	 F642410C	MOV R1 #11276
 00000DBE	 F2C40101	MOVT R1 #16385
 00000DC2	     6008	STR R0 [  R1 + 0 ]
 00000DC4	     2007	MOVS R0 #7
 00000DC6	 F7FFF96A	BL #-3372, goes to  0000009E
 00000DCA	     900D	STR R0 [ SP + 52 ]
 00000DCC	     980D	LDR R0 [ SP + 52 ]
 00000DCE	 F85DEB04	LDR LR [ SP ] + 4
 00000DD2	     B00E	ADD SP SP #56
 00000DD4	     4770	BX LR
 00000DD6	     B081	SUB SP SP #4
 00000DD8	 E92D07FF	PUSH R0 R1 R2 R3 R4 R5 R6 R7 R8 R9 R10
 00000DDC	     B500	PUSH LR
 00000DDE	     9801	LDR R0 [ SP + 4 ]
 00000DE0	     3008	ADDS R0 R0 #8
 00000DE2	     6800	LDR R0 [ R0 + 0 ]
 00000DE4	     900C	STR R0 [ SP + 48 ]
 00000DE6	     9801	LDR R0 [ SP + 4 ]
 00000DE8	     3008	ADDS R0 R0 #8
 00000DEA	     990C	LDR R1 [ SP + 48 ]
 00000DEC	     9A03	LDR R2 [ SP + 12 ]
 00000DEE	     4391	BICS R1 R1 R2
 00000DF0	     9A07	LDR R2 [ SP + 28 ]
 00000DF2	     4311	ORRS R1 R1 R2
 00000DF4	     6001	STR R1 [  R0 + 0 ]
 00000DF6	     9801	LDR R0 [ SP + 4 ]
 00000DF8	     1D00	ADDS R0 R0 #4
 00000DFA	     6800	LDR R0 [ R0 + 0 ]
 00000DFC	     900C	STR R0 [ SP + 48 ]
 00000DFE	     9801	LDR R0 [ SP + 4 ]
 00000E00	     1D00	ADDS R0 R0 #4
 00000E02	     990C	LDR R1 [ SP + 48 ]
 00000E04	     9A02	LDR R2 [ SP + 8 ]
 00000E06	     4391	BICS R1 R1 R2
 00000E08	     9A08	LDR R2 [ SP + 32 ]
 00000E0A	     4311	ORRS R1 R1 R2
 00000E0C	     6001	STR R1 [  R0 + 0 ]
 00000E0E	     9801	LDR R0 [ SP + 4 ]
 00000E10	     300C	ADDS R0 R0 #12
 00000E12	     6800	LDR R0 [ R0 + 0 ]
 00000E14	     900C	STR R0 [ SP + 48 ]
 00000E16	     9801	LDR R0 [ SP + 4 ]
 00000E18	     300C	ADDS R0 R0 #12
 00000E1A	     990C	LDR R1 [ SP + 48 ]
 00000E1C	     9A03	LDR R2 [ SP + 12 ]
 00000E1E	     4391	BICS R1 R1 R2
 00000E20	     9A09	LDR R2 [ SP + 36 ]
 00000E22	     4311	ORRS R1 R1 R2
 00000E24	     6001	STR R1 [  R0 + 0 ]
 00000E26	     9801	LDR R0 [ SP + 4 ]
 00000E28	     3020	ADDS R0 R0 #32
 00000E2A	     6800	LDR R0 [ R0 + 0 ]
 00000E2C	     900C	STR R0 [ SP + 48 ]
 00000E2E	     9801	LDR R0 [ SP + 4 ]
 00000E30	     3020	ADDS R0 R0 #32
 00000E32	     990C	LDR R1 [ SP + 48 ]
 00000E34	     9A04	LDR R2 [ SP + 16 ]
 00000E36	     4391	BICS R1 R1 R2
 00000E38	     9A0A	LDR R2 [ SP + 40 ]
 00000E3A	     4311	ORRS R1 R1 R2
 00000E3C	     6001	STR R1 [  R0 + 0 ]
 00000E3E	     9801	LDR R0 [ SP + 4 ]
 00000E40	     3024	ADDS R0 R0 #36
 00000E42	     6800	LDR R0 [ R0 + 0 ]
 00000E44	     900C	STR R0 [ SP + 48 ]
 00000E46	     9801	LDR R0 [ SP + 4 ]
 00000E48	     3024	ADDS R0 R0 #36
 00000E4A	     990C	LDR R1 [ SP + 48 ]
 00000E4C	     9A05	LDR R2 [ SP + 20 ]
 00000E4E	     4391	BICS R1 R1 R2
 00000E50	     9A0B	LDR R2 [ SP + 44 ]
 00000E52	     4311	ORRS R1 R1 R2
 00000E54	     6001	STR R1 [  R0 + 0 ]
 00000E56	     9801	LDR R0 [ SP + 4 ]
 00000E58	     6800	LDR R0 [ R0 + 0 ]
 00000E5A	     900C	STR R0 [ SP + 48 ]
 00000E5C	     9801	LDR R0 [ SP + 4 ]
 00000E5E	     990C	LDR R1 [ SP + 48 ]
 00000E60	     9A03	LDR R2 [ SP + 12 ]
 00000E62	     4391	BICS R1 R1 R2
 00000E64	     9A06	LDR R2 [ SP + 24 ]
 00000E66	     4311	ORRS R1 R1 R2
 00000E68	     6001	STR R1 [  R0 + 0 ]
 00000E6A	 F85DEB04	LDR LR [ SP ] + 4
 00000E6E	     B00C	ADD SP SP #48
 00000E70	     4770	BX LR
 00000E72	     B085	SUB SP SP #20
 00000E74	     B401	PUSH R0
 00000E76	     B500	PUSH LR
 00000E78	 F2406058	MOV R0 #1624
 00000E7C	 F2C42047	MOVT R0 #16967
 00000E80	     2101	MOVS R1 #1
 00000E82	     7001	STRB R1 [ R0 + 0 ]
 00000E84	 F64000AC	MOV R0 #2220
 00000E88	 F2C42047	MOVT R0 #16967
 00000E8C	     2101	MOVS R1 #1
 00000E8E	     7001	STRB R1 [ R0 + 0 ]
 00000E90	 F2406008	MOV R0 #1544
 00000E94	 F2C42047	MOVT R0 #16967
 00000E98	     2101	MOVS R1 #1
 00000E9A	     7001	STRB R1 [ R0 + 0 ]
 00000E9C	 F240600C	MOV R0 #1548
 00000EA0	 F2C42047	MOVT R0 #16967
 00000EA4	     2101	MOVS R1 #1
 00000EA6	     7001	STRB R1 [ R0 + 0 ]
 00000EA8	 F240600C	MOV R0 #1548
 00000EAC	 F2C42047	MOVT R0 #16967
 00000EB0	     2101	MOVS R1 #1
 00000EB2	     7001	STRB R1 [ R0 + 0 ]
 00000EB4	 F2406014	MOV R0 #1556
 00000EB8	 F2C42047	MOVT R0 #16967
 00000EBC	     2101	MOVS R1 #1
 00000EBE	     7001	STRB R1 [ R0 + 0 ]
 00000EC0	 F2406014	MOV R0 #1556
 00000EC4	 F2C42047	MOVT R0 #16967
 00000EC8	     7800	LDRB R0 [ R0 + 0 ]
 00000ECA	 F88D000C	STRB R0 [  SP + 12 ]
 00000ECE	 F6400000	MOV R0 #2048
 00000ED2	 F2C40002	MOVT R0 #16386
 00000ED6	 F6417108	MOV R1 #7944
 00000EDA	     22C0	MOVS R2 #192
 00000EDC	 F2C032FF	MOVT R2 #1023
 00000EE0	     2300	MOVS R3 #0
 00000EE2	 F64F74FF	MOV R4 #65535
 00000EE6	 F2C0040F	MOVT R4 #15
 00000EEA	     2540	MOVS R5 #64
 00000EEC	 F2C025AA	MOVT R5 #682
 00000EF0	     2600	MOVS R6 #0
 00000EF2	 F2C026AA	MOVT R6 #682
 00000EF6	     2700	MOVS R7 #0
 00000EF8	 F05F0800	MOVS R8 #0
 00000EFC	 F05F0900	MOVS R9 #0
 00000F00	 F64C4ACC	MOV R10 #52428
 00000F04	 F2C00A0C	MOVT R10 #12
 00000F08	 F7FFFF65	BL #-310, goes to  00000DD6
 00000F0C	 F6404000	MOV R0 #3072
 00000F10	 F2C40002	MOVT R0 #16386
 00000F14	     2134	MOVS R1 #52
 00000F16	 F45F6273	MOVS R2 #3888
 00000F1A	 F45F6370	MOVS R3 #3840
 00000F1E	     2400	MOVS R4 #0
 00000F20	     2520	MOVS R5 #32
 00000F22	     2620	MOVS R6 #32
 00000F24	     2700	MOVS R7 #0
 00000F26	 F45F68A0	MOVS R8 #1280
 00000F2A	 F45F6940	MOVS R9 #3072
 00000F2E	 F05F0A00	MOVS R10 #0
 00000F32	 F7FFFF50	BL #-352, goes to  00000DD6
 00000F36	 F2414000	MOV R0 #5120
 00000F3A	 F2C40002	MOVT R0 #16386
 00000F3E	 F45F7100	MOVS R1 #512
 00000F42	 F45F2240	MOVS R2 #786432
 00000F46	     2300	MOVS R3 #0
 00000F48	     2400	MOVS R4 #0
 00000F4A	 F45F2580	MOVS R5 #262144
 00000F4E	     2600	MOVS R6 #0
 00000F50	     2700	MOVS R7 #0
 00000F52	 F05F0800	MOVS R8 #0
 00000F56	 F05F0900	MOVS R9 #0
 00000F5A	 F05F0A00	MOVS R10 #0
 00000F5E	 F7FFFF3A	BL #-396, goes to  00000DD6
 00000F62	     2064	MOVS R0 #100
 00000F64	 F7FFF84E	BL #-3940, goes to  00000004
 00000F68	 F2482014	MOV R0 #33300
 00000F6C	 F2C42041	MOVT R0 #16961
 00000F70	     6800	LDR R0 [ R0 + 0 ]
 00000F72	     2800	CMP R0 #0
 00000F74	 F0008007	BEQ #14, goes to  00000F86
 00000F78	 F24820A4	MOV R0 #33444
 00000F7C	 F2C42042	MOVT R0 #16962
 00000F80	     2101	MOVS R1 #1
 00000F82	     7001	STRB R1 [ R0 + 0 ]
 00000F84	     E7FE	B #-4, goes to  00000F84
 00000F86	 F2482010	MOV R0 #33296
 00000F8A	 F2C42041	MOVT R0 #16961
 00000F8E	     6800	LDR R0 [ R0 + 0 ]
 00000F90	     2800	CMP R0 #0
 00000F92	 F0008007	BEQ #14, goes to  00000FA4
 00000F96	 F240208C	MOV R0 #652
 00000F9A	 F2C42041	MOVT R0 #16961
 00000F9E	     2101	MOVS R1 #1
 00000FA0	     7001	STRB R1 [ R0 + 0 ]
 00000FA2	     E7FE	B #-4, goes to  00000FA2
 00000FA4	 F640400C	MOV R0 #3084
 00000FA8	 F2C40002	MOVT R0 #16386
 00000FAC	     6800	LDR R0 [ R0 + 0 ]
 00000FAE	     9002	STR R0 [ SP + 8 ]
 00000FB0	     9802	LDR R0 [ SP + 8 ]
 00000FB2	 F4306070	BICS R0 R0 #3840
 00000FB6	 F640410C	MOV R1 #3084
 00000FBA	 F2C40102	MOVT R1 #16386
 00000FBE	     6008	STR R0 [  R1 + 0 ]
 00000FC0	 F24820A4	MOV R0 #33444
 00000FC4	 F2C42042	MOVT R0 #16962
 00000FC8	     2101	MOVS R1 #1
 00000FCA	     7001	STRB R1 [ R0 + 0 ]
 00000FCC	 F240208C	MOV R0 #652
 00000FD0	 F2C42041	MOVT R0 #16961
 00000FD4	     2101	MOVS R1 #1
 00000FD6	     7001	STRB R1 [ R0 + 0 ]
 00000FD8	 F6483000	MOV R0 #35584
 00000FDC	 F2C4204C	MOVT R0 #16972
 00000FE0	     2100	MOVS R1 #0
 00000FE2	     6001	STR R1 [  R0 + 0 ]
 00000FE4	 F6483000	MOV R0 #35584
 00000FE8	 F2C4204C	MOVT R0 #16972
 00000FEC	     6800	LDR R0 [ R0 + 0 ]
 00000FEE	     9002	STR R0 [ SP + 8 ]
 00000FF0	     9802	LDR R0 [ SP + 8 ]
 00000FF2	     2800	CMP R0 #0
 00000FF4	     D1F6	BNE #-20, goes to  00000FE4
 00000FF6	 F2464058	MOV R0 #25688
 00000FFA	 F2C40002	MOVT R0 #16386
 00000FFE	 F2454120	MOV R1 #21536
 00001002	 F6C001A0	MOVT R1 #2208
 00001006	     6001	STR R1 [  R0 + 0 ]
 00001008	 F246406C	MOV R0 #25708
 0000100C	 F2C40002	MOVT R0 #16386
 00001010	     2107	MOVS R1 #7
 00001012	     6001	STR R1 [  R0 + 0 ]
 00001014	 F2494000	MOV R0 #37888
 00001018	 F2C4204C	MOVT R0 #16972
 0000101C	     2100	MOVS R1 #0
 0000101E	     6001	STR R1 [  R0 + 0 ]
 00001020	 F2494000	MOV R0 #37888
 00001024	 F2C4204C	MOVT R0 #16972
 00001028	     6800	LDR R0 [ R0 + 0 ]
 0000102A	     9002	STR R0 [ SP + 8 ]
 0000102C	     9802	LDR R0 [ SP + 8 ]
 0000102E	     2800	CMP R0 #0
 00001030	     D1F6	BNE #-20, goes to  00001020
 00001032	 F24640A0	MOV R0 #25760
 00001036	 F2C40002	MOVT R0 #16386
 0000103A	 F2454160	MOV R1 #21600
 0000103E	 F6C001A0	MOVT R1 #2208
 00001042	     6001	STR R1 [  R0 + 0 ]
 00001044	 F24640B4	MOV R0 #25780
 00001048	 F2C40002	MOVT R0 #16386
 0000104C	     2107	MOVS R1 #7
 0000104E	     6001	STR R1 [  R0 + 0 ]
 00001050	 F6424004	MOV R0 #11268
 00001054	 F2C40001	MOVT R0 #16385
 00001058	     2176	MOVS R1 #118
 0000105A	     6001	STR R1 [  R0 + 0 ]
 0000105C	 F6424000	MOV R0 #11264
 00001060	 F2C40001	MOVT R0 #16385
 00001064	     2103	MOVS R1 #3
 00001066	     6001	STR R1 [  R0 + 0 ]
 00001068	 F24800A0	MOV R0 #32928
 0000106C	 F2C42025	MOVT R0 #16933
 00001070	     2101	MOVS R1 #1
 00001072	     6001	STR R1 [  R0 + 0 ]
 00001074	 F45F60FA	MOVS R0 #2000
 00001078	 F7FEFFC4	BL #-4216, goes to  00000004
 0000107C	     9801	LDR R0 [ SP + 4 ]
 0000107E	 F7FFFB97	BL #-2258, goes to  000007B0
 00001082	     9901	LDR R1 [ SP + 4 ]
 00001084	     6008	STR R0 [  R1 + 0 ]
 00001086	     9801	LDR R0 [ SP + 4 ]
 00001088	     6800	LDR R0 [ R0 + 0 ]
 0000108A	     2800	CMP R0 #0
 0000108C	 F0408005	BNE #10, goes to  0000109A
 00001090	     9801	LDR R0 [ SP + 4 ]
 00001092	 F7FFFDAF	BL #-1186, goes to  00000BF4
 00001096	     9901	LDR R1 [ SP + 4 ]
 00001098	     6008	STR R0 [  R1 + 0 ]
 0000109A	     9801	LDR R0 [ SP + 4 ]
 0000109C	     6800	LDR R0 [ R0 + 0 ]
 0000109E	     2800	CMP R0 #0
 000010A0	 F040817E	BNE #764, goes to  000013A0
 000010A4	     9801	LDR R0 [ SP + 4 ]
 000010A6	     6840	LDR R0 [ R0 + 4 ]
 000010A8	     2800	CMP R0 #0
 000010AA	 F040801B	BNE #54, goes to  000010E4
 000010AE	 F6424008	MOV R0 #11272
 000010B2	 F2C40001	MOVT R0 #16385
 000010B6	     2108	MOVS R1 #8
 000010B8	     6001	STR R1 [  R0 + 0 ]
 000010BA	     9802	LDR R0 [ SP + 8 ]
 000010BC	 F64071FF	MOV R1 #4095
 000010C0	 EA300001	BICS R0 R0 R1 LSL #0
 000010C4	 F450608A	ORRS R0 R0 #1104
 000010C8	 F642410C	MOV R1 #11276
 000010CC	 F2C40101	MOVT R1 #16385
 000010D0	     6008	STR R0 [  R1 + 0 ]
 000010D2	     2010	MOVS R0 #16
 000010D4	 F7FEFFE3	BL #-4154, goes to  0000009E
 000010D8	     9901	LDR R1 [ SP + 4 ]
 000010DA	     6809	LDR R1 [ R1 + 0 ]
 000010DC	 EA510000	ORRS R0 R1 R0 LSL #0
 000010E0	     9901	LDR R1 [ SP + 4 ]
 000010E2	     6008	STR R0 [  R1 + 0 ]
 000010E4	     9801	LDR R0 [ SP + 4 ]
 000010E6	     6800	LDR R0 [ R0 + 0 ]
 000010E8	     2800	CMP R0 #0
 000010EA	 F0408021	BNE #66, goes to  00001130
 000010EE	     9801	LDR R0 [ SP + 4 ]
 000010F0	     6900	LDR R0 [ R0 + 16 ]
 000010F2	     0400	LSLS R0 R0 #16
 000010F4	 F6424108	MOV R1 #11272
 000010F8	 F2C40101	MOVT R1 #16385
 000010FC	     6008	STR R0 [  R1 + 0 ]
 000010FE	 F642400C	MOV R0 #11276
 00001102	 F2C40001	MOVT R0 #16385
 00001106	     6800	LDR R0 [ R0 + 0 ]
 00001108	     9002	STR R0 [ SP + 8 ]
 0000110A	     9802	LDR R0 [ SP + 8 ]
 0000110C	 F64071FF	MOV R1 #4095
 00001110	 EA300001	BICS R0 R0 R1 LSL #0
 00001114	 F2404177	MOV R1 #1143
 00001118	 EA500001	ORRS R0 R0 R1 LSL #0
 0000111C	 F642410C	MOV R1 #11276
 00001120	 F2C40101	MOVT R1 #16385
 00001124	     6008	STR R0 [  R1 + 0 ]
 00001126	     2037	MOVS R0 #55
 00001128	 F7FEFFB9	BL #-4238, goes to  0000009E
 0000112C	     9901	LDR R1 [ SP + 4 ]
 0000112E	     6008	STR R0 [  R1 + 0 ]
 00001130	     9801	LDR R0 [ SP + 4 ]
 00001132	     6800	LDR R0 [ R0 + 0 ]
 00001134	     2800	CMP R0 #0
 00001136	 F0408036	BNE #108, goes to  000011A6
 0000113A	 F6424024	MOV R0 #11300
 0000113E	 F2C40001	MOVT R0 #16385
 00001142	 F05F31FF	MOVS R1 #-1
 00001146	     6001	STR R1 [  R0 + 0 ]
 00001148	 F6424028	MOV R0 #11304
 0000114C	 F2C40001	MOVT R0 #16385
 00001150	     2108	MOVS R1 #8
 00001152	     6001	STR R1 [  R0 + 0 ]
 00001154	 F642402C	MOV R0 #11308
 00001158	 F2C40001	MOVT R0 #16385
 0000115C	     6800	LDR R0 [ R0 + 0 ]
 0000115E	     9002	STR R0 [ SP + 8 ]
 00001160	     9802	LDR R0 [ SP + 8 ]
 00001162	 F03000F7	BICS R0 R0 #247
 00001166	 F0500033	ORRS R0 R0 #51
 0000116A	 F642412C	MOV R1 #11308
 0000116E	 F2C40101	MOVT R1 #16385
 00001172	     6008	STR R0 [  R1 + 0 ]
 00001174	 F6424008	MOV R0 #11272
 00001178	 F2C40001	MOVT R0 #16385
 0000117C	     2100	MOVS R1 #0
 0000117E	     6001	STR R1 [  R0 + 0 ]
 00001180	     9802	LDR R0 [ SP + 8 ]
 00001182	 F64071FF	MOV R1 #4095
 00001186	 EA300001	BICS R0 R0 R1 LSL #0
 0000118A	 F2404173	MOV R1 #1139
 0000118E	 EA500001	ORRS R0 R0 R1 LSL #0
 00001192	 F642410C	MOV R1 #11276
 00001196	 F2C40101	MOVT R1 #16385
 0000119A	     6008	STR R0 [  R1 + 0 ]
 0000119C	     2033	MOVS R0 #51
 0000119E	 F7FEFF7E	BL #-4356, goes to  0000009E
 000011A2	     9901	LDR R1 [ SP + 4 ]
 000011A4	     6008	STR R0 [  R1 + 0 ]
 000011A6	     9801	LDR R0 [ SP + 4 ]
 000011A8	     6800	LDR R0 [ R0 + 0 ]
 000011AA	     2800	CMP R0 #0
 000011AC	 F04080B6	BNE #364, goes to  0000131C
 000011B0	 F6424034	MOV R0 #11316
 000011B4	 F2C40001	MOVT R0 #16385
 000011B8	     6800	LDR R0 [ R0 + 0 ]
 000011BA	     9002	STR R0 [ SP + 8 ]
 000011BC	     2000	MOVS R0 #0
 000011BE	     9006	STR R0 [ SP + 24 ]
 000011C0	     9802	LDR R0 [ SP + 8 ]
 000011C2	 F242212A	MOV R1 #8746
 000011C6	 EA100001	ANDS R0 R0 R1 LSL #0
 000011CA	 F5B05F00	CMP R0 #8192
 000011CE	 F0408018	BNE #48, goes to  00001202
 000011D2	     9802	LDR R0 [ SP + 8 ]
 000011D4	 EA5F50B0	RORS R0 R0 #22
 000011D8	 F140800C	BPL #24, goes to  000011F4
 000011DC	     9806	LDR R0 [ SP + 24 ]
 000011DE	 EB0D0080	ADD R0 SP R0 LSL #2
 000011E2	 F6424180	MOV R1 #11392
 000011E6	 F2C40101	MOVT R1 #16385
 000011EA	     6809	LDR R1 [ R1 + 0 ]
 000011EC	     6101	STR R1 [  R0 + 16 ]
 000011EE	     9806	LDR R0 [ SP + 24 ]
 000011F0	     1C40	ADDS R0 R0 #1
 000011F2	     9006	STR R0 [ SP + 24 ]
 000011F4	 F6424034	MOV R0 #11316
 000011F8	 F2C40001	MOVT R0 #16385
 000011FC	     6800	LDR R0 [ R0 + 0 ]
 000011FE	     9002	STR R0 [ SP + 8 ]
 00001200	     E7DE	B #-68, goes to  000011C0
 00001202	     9802	LDR R0 [ SP + 8 ]
 00001204	 EA5F2070	RORS R0 R0 #9
 00001208	 F140800A	BPL #20, goes to  00001220
 0000120C	     9804	LDR R0 [ SP + 16 ]
 0000120E	 F7FEFF14	BL #-4568, goes to  0000003A
 00001212	     9004	STR R0 [ SP + 16 ]
 00001214	     9805	LDR R0 [ SP + 20 ]
 00001216	 F7FEFF10	BL #-4576, goes to  0000003A
 0000121A	     9005	STR R0 [ SP + 20 ]
 0000121C	 F000B81C	B #56, goes to  00001258
 00001220	     9802	LDR R0 [ SP + 8 ]
 00001222	 EA5F00B0	RORS R0 R0 #2
 00001226	 F1408005	BPL #10, goes to  00001234
 0000122A	     2002	MOVS R0 #2
 0000122C	     9901	LDR R1 [ SP + 4 ]
 0000122E	     6008	STR R0 [  R1 + 0 ]
 00001230	 F000B812	B #36, goes to  00001258
 00001234	     9802	LDR R0 [ SP + 8 ]
 00001236	 EA5F10B0	RORS R0 R0 #6
 0000123A	 F1408005	BPL #10, goes to  00001248
 0000123E	     2020	MOVS R0 #32
 00001240	     9901	LDR R1 [ SP + 4 ]
 00001242	     6008	STR R0 [  R1 + 0 ]
 00001244	 F000B808	B #16, goes to  00001258
 00001248	     9802	LDR R0 [ SP + 8 ]
 0000124A	 EA5F20B0	RORS R0 R0 #10
 0000124E	 F1408003	BPL #6, goes to  00001258
 00001252	     2008	MOVS R0 #8
 00001254	     9901	LDR R1 [ SP + 4 ]
 00001256	     6008	STR R0 [  R1 + 0 ]
 00001258	 F6424038	MOV R0 #11320
 0000125C	 F2C40001	MOVT R0 #16385
 00001260	 F24071FF	MOV R1 #2047
 00001264	 F2C00140	MOVT R1 #64
 00001268	     6001	STR R1 [  R0 + 0 ]
 0000126A	     9805	LDR R0 [ SP + 20 ]
 0000126C	 EA5F40F0	RORS R0 R0 #19
 00001270	 F1408054	BPL #168, goes to  0000131C
 00001274	     9801	LDR R0 [ SP + 4 ]
 00001276	     6900	LDR R0 [ R0 + 16 ]
 00001278	     0400	LSLS R0 R0 #16
 0000127A	 F6424108	MOV R1 #11272
 0000127E	 F2C40101	MOVT R1 #16385
 00001282	     6008	STR R0 [  R1 + 0 ]
 00001284	 F642400C	MOV R0 #11276
 00001288	 F2C40001	MOVT R0 #16385
 0000128C	     6800	LDR R0 [ R0 + 0 ]
 0000128E	     9002	STR R0 [ SP + 8 ]
 00001290	     9802	LDR R0 [ SP + 8 ]
 00001292	 F64071FF	MOV R1 #4095
 00001296	 EA300001	BICS R0 R0 R1 LSL #0
 0000129A	 F2404177	MOV R1 #1143
 0000129E	 EA500001	ORRS R0 R0 R1 LSL #0
 000012A2	 F642410C	MOV R1 #11276
 000012A6	 F2C40101	MOVT R1 #16385
 000012AA	     6008	STR R0 [  R1 + 0 ]
 000012AC	     2037	MOVS R0 #55
 000012AE	 F7FEFEF6	BL #-4628, goes to  0000009E
 000012B2	     9901	LDR R1 [ SP + 4 ]
 000012B4	     6008	STR R0 [  R1 + 0 ]
 000012B6	     9801	LDR R0 [ SP + 4 ]
 000012B8	     6800	LDR R0 [ R0 + 0 ]
 000012BA	     2800	CMP R0 #0
 000012BC	 F0408019	BNE #50, goes to  000012F2
 000012C0	 F6424008	MOV R0 #11272
 000012C4	 F2C40001	MOVT R0 #16385
 000012C8	     2102	MOVS R1 #2
 000012CA	     6001	STR R1 [  R0 + 0 ]
 000012CC	     9802	LDR R0 [ SP + 8 ]
 000012CE	 F64071FF	MOV R1 #4095
 000012D2	 EA300001	BICS R0 R0 R1 LSL #0
 000012D6	 F2404146	MOV R1 #1094
 000012DA	 EA500001	ORRS R0 R0 R1 LSL #0
 000012DE	 F642410C	MOV R1 #11276
 000012E2	 F2C40101	MOVT R1 #16385
 000012E6	     6008	STR R0 [  R1 + 0 ]
 000012E8	     2006	MOVS R0 #6
 000012EA	 F7FEFED8	BL #-4688, goes to  0000009E
 000012EE	     9901	LDR R1 [ SP + 4 ]
 000012F0	     6008	STR R0 [  R1 + 0 ]
 000012F2	     9801	LDR R0 [ SP + 4 ]
 000012F4	     6800	LDR R0 [ R0 + 0 ]
 000012F6	     2800	CMP R0 #0
 000012F8	 F0408010	BNE #32, goes to  0000131C
 000012FC	 F6424004	MOV R0 #11268
 00001300	 F2C40001	MOVT R0 #16385
 00001304	     6800	LDR R0 [ R0 + 0 ]
 00001306	     9002	STR R0 [ SP + 8 ]
 00001308	     9802	LDR R0 [ SP + 8 ]
 0000130A	 F43050C0	BICS R0 R0 #6144
 0000130E	 F4506000	ORRS R0 R0 #2048
 00001312	 F6424104	MOV R1 #11268
 00001316	 F2C40101	MOVT R1 #16385
 0000131A	     6008	STR R0 [  R1 + 0 ]
 0000131C	     9801	LDR R0 [ SP + 4 ]
 0000131E	     6800	LDR R0 [ R0 + 0 ]
 00001320	     2800	CMP R0 #0
 00001322	 F040802C	BNE #88, goes to  0000137E
 00001326	 F6424004	MOV R0 #11268
 0000132A	 F2C40001	MOVT R0 #16385
 0000132E	     6800	LDR R0 [ R0 + 0 ]
 00001330	     9002	STR R0 [ SP + 8 ]
 00001332	     9802	LDR R0 [ SP + 8 ]
 00001334	 F03000FF	BICS R0 R0 #255
 00001338	 F0500000	ORRS R0 R0 #0
 0000133C	 F6424104	MOV R1 #11268
 00001340	 F2C40101	MOVT R1 #16385
 00001344	     6008	STR R0 [  R1 + 0 ]
 00001346	 F6424008	MOV R0 #11272
 0000134A	 F2C40001	MOVT R0 #16385
 0000134E	 F45F7100	MOVS R1 #512
 00001352	     6001	STR R1 [  R0 + 0 ]
 00001354	     9802	LDR R0 [ SP + 8 ]
 00001356	 F64071FF	MOV R1 #4095
 0000135A	 EA300001	BICS R0 R0 R1 LSL #0
 0000135E	 F450608A	ORRS R0 R0 #1104
 00001362	 F642410C	MOV R1 #11276
 00001366	 F2C40101	MOVT R1 #16385
 0000136A	     6008	STR R0 [  R1 + 0 ]
 0000136C	     2010	MOVS R0 #16
 0000136E	 F7FEFE96	BL #-4820, goes to  0000009E
 00001372	     9901	LDR R1 [ SP + 4 ]
 00001374	     6809	LDR R1 [ R1 + 0 ]
 00001376	 EA510000	ORRS R0 R1 R0 LSL #0
 0000137A	     9901	LDR R1 [ SP + 4 ]
 0000137C	     6008	STR R0 [  R1 + 0 ]
 0000137E	     9801	LDR R0 [ SP + 4 ]
 00001380	     6800	LDR R0 [ R0 + 0 ]
 00001382	     2800	CMP R0 #0
 00001384	 F040800C	BNE #24, goes to  000013A0
 00001388	 F24820A4	MOV R0 #33444
 0000138C	 F2C42042	MOVT R0 #16962
 00001390	     2100	MOVS R1 #0
 00001392	     7001	STRB R1 [ R0 + 0 ]
 00001394	 F240208C	MOV R0 #652
 00001398	 F2C42041	MOVT R0 #16961
 0000139C	     2100	MOVS R1 #0
 0000139E	     7001	STRB R1 [ R0 + 0 ]
 000013A0	 F85DEB04	LDR LR [ SP ] + 4
 000013A4	     B006	ADD SP SP #24
 000013A6	     4770	BX LR
 000013A8	     B083	SUB SP SP #12
 000013AA	     B500	PUSH LR
 000013AC	 F24010AC	MOV R0 #428
 000013B0	 F2C20000	MOVT R0 #8192
 000013B4	     9003	STR R0 [ SP + 12 ]
 000013B6	     9803	LDR R0 [ SP + 12 ]
 000013B8	 F2402100	MOV R1 #512
 000013BC	 F2C20100	MOVT R1 #8192
 000013C0	     6501	STR R1 [  R0 + 80 ]
 000013C2	     9803	LDR R0 [ SP + 12 ]
 000013C4	 F7FFFD55	BL #-1366, goes to  00000E72
 000013C8	     9803	LDR R0 [ SP + 12 ]
 000013CA	     2104	MOVS R1 #4
 000013CC	 F2C00108	MOVT R1 #8
 000013D0	 F2410200	MOV R2 #4096
 000013D4	 F2CD0220	MOVT R2 #53280
 000013D8	     2302	MOVS R3 #2
 000013DA	 F7FFF9B5	BL #-3222, goes to  00000748
 000013DE	 F2410010	MOV R0 #4112
 000013E2	 F2CD0020	MOVT R0 #53280
 000013E6	     6800	LDR R0 [ R0 + 0 ]
 000013E8	     9001	STR R0 [ SP + 4 ]
 000013EA	     9801	LDR R0 [ SP + 4 ]
 000013EC	 F24F11FF	MOV R1 #61951
 000013F0	 F6C271DF	MOVT R1 #12255
 000013F4	     1840	ADDS R0 R0 R1
 000013F6	     1240	ASRS R0 R0 #9
 000013F8	     1E80	SUBS R0 R0 #2
 000013FA	     9002	STR R0 [ SP + 8 ]
 000013FC	     9802	LDR R0 [ SP + 8 ]
 000013FE	     2800	CMP R0 #0
 00001400	 F340800B	BLE #22, goes to  0000141A
 00001404	     9803	LDR R0 [ SP + 12 ]
 00001406	     2106	MOVS R1 #6
 00001408	 F2C00108	MOVT R1 #8
 0000140C	 F2414200	MOV R2 #5120
 00001410	 F2CD0220	MOVT R2 #53280
 00001414	     9B02	LDR R3 [ SP + 8 ]
 00001416	 F7FFF997	BL #-3282, goes to  00000748
 0000141A	 F85DEB04	LDR LR [ SP ] + 4
 0000141E	     B003	ADD SP SP #12
 00001420	     4770	BX LR
 00001422	     B081	SUB SP SP #4
 00001424	     B500	PUSH LR
 00001426	 F3BF8F5F	DMB
 0000142A	 F64E5024	MOV R0 #60708
 0000142E	 F2CE0000	MOVT R0 #57344
 00001432	     6800	LDR R0 [ R0 + 0 ]
 00001434	     9001	STR R0 [ SP + 4 ]
 00001436	     9801	LDR R0 [ SP + 4 ]
 00001438	 F4303080	BICS R0 R0 #65536
 0000143C	 F64E5124	MOV R1 #60708
 00001440	 F2CE0100	MOVT R1 #57344
 00001444	     6008	STR R0 [  R1 + 0 ]
 00001446	 F64E5094	MOV R0 #60820
 0000144A	 F2CE0000	MOVT R0 #57344
 0000144E	     2100	MOVS R1 #0
 00001450	     6001	STR R1 [  R0 + 0 ]
 00001452	 F64E5098	MOV R0 #60824
 00001456	 F2CE0000	MOVT R0 #57344
 0000145A	     2100	MOVS R1 #0
 0000145C	     6001	STR R1 [  R0 + 0 ]
 0000145E	 F64E509C	MOV R0 #60828
 00001462	 F2CE0000	MOVT R0 #57344
 00001466	 F05F4150	MOVS R1 #-805306368
 0000146A	     6001	STR R1 [  R0 + 0 ]
 0000146C	 F64E50A0	MOV R0 #60832
 00001470	 F2CE0000	MOVT R0 #57344
 00001474	 F240312D	MOV R1 #813
 00001478	 F2C03106	MOVT R1 #774
 0000147C	     6001	STR R1 [  R0 + 0 ]
 0000147E	 F64E5094	MOV R0 #60820
 00001482	 F2CE0000	MOVT R0 #57344
 00001486	     6800	LDR R0 [ R0 + 0 ]
 00001488	     9001	STR R0 [ SP + 4 ]
 0000148A	     9801	LDR R0 [ SP + 4 ]
 0000148C	 F0500005	ORRS R0 R0 #5
 00001490	 F64E5194	MOV R1 #60820
 00001494	 F2CE0100	MOVT R1 #57344
 00001498	     6008	STR R0 [  R1 + 0 ]
 0000149A	 F64E5024	MOV R0 #60708
 0000149E	 F2CE0000	MOVT R0 #57344
 000014A2	     6800	LDR R0 [ R0 + 0 ]
 000014A4	     9001	STR R0 [ SP + 4 ]
 000014A6	     9801	LDR R0 [ SP + 4 ]
 000014A8	 F4503080	ORRS R0 R0 #65536
 000014AC	 F64E5124	MOV R1 #60708
 000014B0	 F2CE0100	MOVT R1 #57344
 000014B4	     6008	STR R0 [  R1 + 0 ]
 000014B6	 F3BF8F4F	DSB
 000014BA	 F3BF8F6F	ISB
 000014BE	 F85DEB04	LDR LR [ SP ] + 4
 000014C2	     B001	ADD SP SP #4
 000014C4	     4770	BX LR
 000014C6	     B081	SUB SP SP #4
 000014C8	     B500	PUSH LR
 000014CA	 F6430030	MOV R0 #14384
 000014CE	 F2C40002	MOVT R0 #16386
 000014D2	     6800	LDR R0 [ R0 + 0 ]
 000014D4	     9001	STR R0 [ SP + 4 ]
 000014D6	     9801	LDR R0 [ SP + 4 ]
 000014D8	 F050007E	ORRS R0 R0 #126
 000014DC	 F6430130	MOV R1 #14384
 000014E0	 F2C40102	MOVT R1 #16386
 000014E4	     6008	STR R0 [  R1 + 0 ]
 000014E6	 F6430038	MOV R0 #14392
 000014EA	 F2C40002	MOVT R0 #16386
 000014EE	     2101	MOVS R1 #1
 000014F0	     6001	STR R1 [  R0 + 0 ]
 000014F2	 F2404000	MOV R0 #1024
 000014F6	 F2C40002	MOVT R0 #16386
 000014FA	     2160	MOVS R1 #96
 000014FC	 F45F5270	MOVS R2 #15360
 00001500	 F05F637F	MOVS R3 #267386880
 00001504	     2400	MOVS R4 #0
 00001506	 F45F5520	MOVS R5 #10240
 0000150A	 F45F5670	MOVS R6 #15360
 0000150E	     2700	MOVS R7 #0
 00001510	 F05F0800	MOVS R8 #0
 00001514	 F05F694C	MOVS R9 #213909504
 00001518	 F05F0A00	MOVS R10 #0
 0000151C	 F7FFFC5B	BL #-1866, goes to  00000DD6
 00001520	 F6400000	MOV R0 #2048
 00001524	 F2C40002	MOVT R0 #16386
 00001528	     2101	MOVS R1 #1
 0000152A	     2201	MOVS R2 #1
 0000152C	     2301	MOVS R3 #1
 0000152E	     2400	MOVS R4 #0
 00001530	     2502	MOVS R5 #2
 00001532	     2603	MOVS R6 #3
 00001534	     2700	MOVS R7 #0
 00001536	 F05F0800	MOVS R8 #0
 0000153A	 F05F090C	MOVS R9 #12
 0000153E	 F05F0A00	MOVS R10 #0
 00001542	 F7FFFC48	BL #-1904, goes to  00000DD6
 00001546	 F6404000	MOV R0 #3072
 0000154A	 F2C40002	MOVT R0 #16386
 0000154E	 F24C7103	MOV R1 #50947
 00001552	     220F	MOVS R2 #15
 00001554	 F2CF023F	MOVT R2 #61503
 00001558	     23FF	MOVS R3 #255
 0000155A	 F64074FF	MOV R4 #4095
 0000155E	 F6CF7400	MOVT R4 #65280
 00001562	     250A	MOVS R5 #10
 00001564	 F2CA052A	MOVT R5 #41002
 00001568	     260F	MOVS R6 #15
 0000156A	 F2CF063F	MOVT R6 #61503
 0000156E	     2700	MOVS R7 #0
 00001570	 F05F0800	MOVS R8 #0
 00001574	 F05F09CC	MOVS R9 #204
 00001578	 F6404ACC	MOV R10 #3276
 0000157C	 F6CC4A00	MOVT R10 #52224
 00001580	 F7FFFC29	BL #-1966, goes to  00000DD6
 00001584	 F2410000	MOV R0 #4096
 00001588	 F2C40002	MOVT R0 #16386
 0000158C	 F64F7183	MOV R1 #65411
 00001590	 F24C020F	MOV R2 #49167
 00001594	 F6CF72FF	MOVT R2 #65535
 00001598	     23FF	MOVS R3 #255
 0000159A	 F2CF0300	MOVT R3 #61440
 0000159E	 F05F34FF	MOVS R4 #-1
 000015A2	 F248050A	MOV R5 #32778
 000015A6	 F6CA25AA	MOVT R5 #43690
 000015AA	 F24C060F	MOV R6 #49167
 000015AE	 F6CF76FF	MOVT R6 #65535
 000015B2	     2700	MOVS R7 #0
 000015B4	 F05F0800	MOVS R8 #0
 000015B8	 F24009CC	MOV R9 #204
 000015BC	 F2CC0900	MOVT R9 #49152
 000015C0	 F05F3ACC	MOVS R10 #-858993460
 000015C4	 F7FFFC07	BL #-2034, goes to  00000DD6
 000015C8	 F2414000	MOV R0 #5120
 000015CC	 F2C40002	MOVT R0 #16386
 000015D0	 F64F013F	MOV R1 #63551
 000015D4	 F64072FF	MOV R2 #4095
 000015D8	 F6CF72C0	MOVT R2 #65472
 000015DC	 F07F437F	MVNS R3 #-16777216
 000015E0	 F24F0400	MOV R4 #61440
 000015E4	 F6CF74FF	MOVT R4 #65535
 000015E8	 F64025AA	MOV R5 #2730
 000015EC	 F6CA2580	MOVT R5 #43648
 000015F0	 F64076FF	MOV R6 #4095
 000015F4	 F6CF76C0	MOVT R6 #65472
 000015F8	     2700	MOVS R7 #0
 000015FA	 F05F0800	MOVS R8 #0
 000015FE	 F64C49CC	MOV R9 #52428
 00001602	 F2C009CC	MOVT R9 #204
 00001606	 F24C0A00	MOV R10 #49152
 0000160A	 F6CC4ACC	MOVT R10 #52428
 0000160E	 F7FFFBE2	BL #-2108, goes to  00000DD6
 00001612	 F6410000	MOV R0 #6144
 00001616	 F2C40002	MOVT R0 #16386
 0000161A	 F2481133	MOV R1 #33075
 0000161E	 F640720F	MOV R2 #3855
 00001622	 F2CC0203	MOVT R2 #49155
 00001626	 F05F13FF	MOVS R3 #16711935
 0000162A	     240F	MOVS R4 #15
 0000162C	 F2CF0400	MOVT R4 #61440
 00001630	 F640250A	MOV R5 #2570
 00001634	 F2C80502	MOVT R5 #32770
 00001638	 F640760F	MOV R6 #3855
 0000163C	 F2CC0603	MOVT R6 #49155
 00001640	     2700	MOVS R7 #0
 00001642	 F05F0800	MOVS R8 #0
 00001646	 F05F19CC	MOVS R9 #13369548
 0000164A	 F2400A0C	MOV R10 #12
 0000164E	 F2CC0A00	MOVT R10 #49152
 00001652	 F7FFFBC0	BL #-2176, goes to  00000DD6
 00001656	 F2401040	MOV R0 #320
 0000165A	 F2CA0000	MOVT R0 #40960
 0000165E	     6800	LDR R0 [ R0 + 0 ]
 00001660	     9001	STR R0 [ SP + 4 ]
 00001662	     9801	LDR R0 [ SP + 4 ]
 00001664	 F43040F8	BICS R0 R0 #31744
 00001668	 F4505060	ORRS R0 R0 #14336
 0000166C	 F2401140	MOV R1 #320
 00001670	 F2CA0100	MOVT R1 #40960
 00001674	     6008	STR R0 [  R1 + 0 ]
 00001676	 F2401044	MOV R0 #324
 0000167A	 F2CA0000	MOVT R0 #40960
 0000167E	 F45F71EA	MOVS R1 #468
 00001682	     6001	STR R1 [  R0 + 0 ]
 00001684	 F2401048	MOV R0 #328
 00001688	 F2CA0000	MOVT R0 #40960
 0000168C	     6800	LDR R0 [ R0 + 0 ]
 0000168E	     9001	STR R0 [ SP + 4 ]
 00001690	     9801	LDR R0 [ SP + 4 ]
 00001692	 F24F0100	MOV R1 #61440
 00001696	 F2C001F0	MOVT R1 #240
 0000169A	 EA300001	BICS R0 R0 R1 LSL #0
 0000169E	 F4501083	ORRS R0 R0 #1073152
 000016A2	 F2401148	MOV R1 #328
 000016A6	 F2CA0100	MOVT R1 #40960
 000016AA	     6008	STR R0 [  R1 + 0 ]
 000016AC	 F240104C	MOV R0 #332
 000016B0	 F2CA0000	MOVT R0 #40960
 000016B4	 F2403161	MOV R1 #865
 000016B8	 F2C01102	MOVT R1 #258
 000016BC	     6001	STR R1 [  R0 + 0 ]
 000016BE	 F2401050	MOV R0 #336
 000016C2	 F2CA0000	MOVT R0 #40960
 000016C6	     2109	MOVS R1 #9
 000016C8	     6001	STR R1 [  R0 + 0 ]
 000016CA	 F2401058	MOV R0 #344
 000016CE	 F2CA0000	MOVT R0 #40960
 000016D2	     6800	LDR R0 [ R0 + 0 ]
 000016D4	 EA5F10B0	RORS R0 R0 #6
 000016D8	     D4F7	BMI #-18, goes to  000016CA
 000016DA	     2078	MOVS R0 #120
 000016DC	 F7FEFC92	BL #-5852, goes to  00000004
 000016E0	 F2401050	MOV R0 #336
 000016E4	 F2CA0000	MOVT R0 #40960
 000016E8	     210A	MOVS R1 #10
 000016EA	     6001	STR R1 [  R0 + 0 ]
 000016EC	 F2401058	MOV R0 #344
 000016F0	 F2CA0000	MOVT R0 #40960
 000016F4	     6800	LDR R0 [ R0 + 0 ]
 000016F6	 EA5F10B0	RORS R0 R0 #6
 000016FA	     D4F7	BMI #-18, goes to  000016EC
 000016FC	 F2401050	MOV R0 #336
 00001700	 F2CA0000	MOVT R0 #40960
 00001704	     218B	MOVS R1 #139
 00001706	     6001	STR R1 [  R0 + 0 ]
 00001708	 F2401058	MOV R0 #344
 0000170C	 F2CA0000	MOVT R0 #40960
 00001710	     6800	LDR R0 [ R0 + 0 ]
 00001712	 EA5F10B0	RORS R0 R0 #6
 00001716	     D4F7	BMI #-18, goes to  00001708
 00001718	 F2401050	MOV R0 #336
 0000171C	 F2CA0000	MOVT R0 #40960
 00001720	 F246010C	MOV R1 #24588
 00001724	 F2C00104	MOVT R1 #4
 00001728	     6001	STR R1 [  R0 + 0 ]
 0000172A	 F2401058	MOV R0 #344
 0000172E	 F2CA0000	MOVT R0 #40960
 00001732	     6800	LDR R0 [ R0 + 0 ]
 00001734	 EA5F10B0	RORS R0 R0 #6
 00001738	     D4F7	BMI #-18, goes to  0000172A
 0000173A	 F2401054	MOV R0 #340
 0000173E	 F2CA0000	MOVT R0 #40960
 00001742	 F6402118	MOV R1 #2584
 00001746	     6001	STR R1 [  R0 + 0 ]
 00001748	 F85DEB04	LDR LR [ SP ] + 4
 0000174C	     B001	ADD SP SP #4
 0000174E	     4770	BX LR
 00001750	     B081	SUB SP SP #4
 00001752	     B500	PUSH LR
 00001754	 F64E50FC	MOV R0 #60924
 00001758	 F2CE0000	MOVT R0 #57344
 0000175C	     6800	LDR R0 [ R0 + 0 ]
 0000175E	     9001	STR R0 [ SP + 4 ]
 00001760	     9801	LDR R0 [ SP + 4 ]
 00001762	 F0307080	BICS R0 R0 #16777216
 00001766	 F64E51FC	MOV R1 #60924
 0000176A	 F2CE0100	MOVT R1 #57344
 0000176E	     6008	STR R0 [  R1 + 0 ]
 00001770	     9801	LDR R0 [ SP + 4 ]
 00001772	 F0507080	ORRS R0 R0 #16777216
 00001776	 F64E51FC	MOV R1 #60924
 0000177A	 F2CE0100	MOVT R1 #57344
 0000177E	     6008	STR R0 [  R1 + 0 ]
 00001780	 F2410000	MOV R0 #4096
 00001784	 F2CE0000	MOVT R0 #57344
 00001788	     6800	LDR R0 [ R0 + 0 ]
 0000178A	     9001	STR R0 [ SP + 4 ]
 0000178C	     9801	LDR R0 [ SP + 4 ]
 0000178E	 F0300001	BICS R0 R0 #1
 00001792	 F2410100	MOV R1 #4096
 00001796	 F2CE0100	MOVT R1 #57344
 0000179A	     6008	STR R0 [  R1 + 0 ]
 0000179C	 F2410004	MOV R0 #4100
 000017A0	 F2CE0000	MOVT R0 #57344
 000017A4	     2100	MOVS R1 #0
 000017A6	     6001	STR R1 [  R0 + 0 ]
 000017A8	     9801	LDR R0 [ SP + 4 ]
 000017AA	 F0500001	ORRS R0 R0 #1
 000017AE	 F2410100	MOV R1 #4096
 000017B2	 F2CE0100	MOVT R1 #57344
 000017B6	     6008	STR R0 [  R1 + 0 ]
 000017B8	 F85DEB04	LDR LR [ SP ] + 4
 000017BC	     B001	ADD SP SP #4
 000017BE	     4770	BX LR
 000017C0	     B081	SUB SP SP #4
 000017C2	     B500	PUSH LR
 000017C4	 F6400070	MOV R0 #2160
 000017C8	 F2C42047	MOVT R0 #16967
 000017CC	     2101	MOVS R1 #1
 000017CE	     7001	STRB R1 [ R0 + 0 ]
 000017D0	     2040	MOVS R0 #64
 000017D2	 F2C42047	MOVT R0 #16967
 000017D6	     2101	MOVS R1 #1
 000017D8	     7001	STRB R1 [ R0 + 0 ]
 000017DA	     2044	MOVS R0 #68
 000017DC	 F2C42047	MOVT R0 #16967
 000017E0	     6800	LDR R0 [ R0 + 0 ]
 000017E2	     2800	CMP R0 #0
 000017E4	     D0F9	BEQ #-14, goes to  000017DA
 000017E6	     2060	MOVS R0 #96
 000017E8	 F2C42047	MOVT R0 #16967
 000017EC	     2100	MOVS R1 #0
 000017EE	     7001	STRB R1 [ R0 + 0 ]
 000017F0	     2064	MOVS R0 #100
 000017F2	 F2C42047	MOVT R0 #16967
 000017F6	     6800	LDR R0 [ R0 + 0 ]
 000017F8	     2800	CMP R0 #0
 000017FA	     D1F9	BNE #-14, goes to  000017F0
 000017FC	 F6430004	MOV R0 #14340
 00001800	 F2C40002	MOVT R0 #16386
 00001804	 F6422104	MOV R1 #10756
 00001808	 F2C07140	MOVT R1 #1856
 0000180C	     6001	STR R1 [  R0 + 0 ]
 0000180E	     2060	MOVS R0 #96
 00001810	 F2C42047	MOVT R0 #16967
 00001814	     2101	MOVS R1 #1
 00001816	     7001	STRB R1 [ R0 + 0 ]
 00001818	     2064	MOVS R0 #100
 0000181A	 F2C42047	MOVT R0 #16967
 0000181E	     6800	LDR R0 [ R0 + 0 ]
 00001820	     2800	CMP R0 #0
 00001822	     D0F9	BEQ #-14, goes to  00001818
 00001824	 F6434000	MOV R0 #15360
 00001828	 F2C40002	MOVT R0 #16386
 0000182C	     6800	LDR R0 [ R0 + 0 ]
 0000182E	     9001	STR R0 [ SP + 4 ]
 00001830	     9801	LDR R0 [ SP + 4 ]
 00001832	 F010000F	ANDS R0 R0 #15
 00001836	     2805	CMP R0 #5
 00001838	 F2808011	BGE #34, goes to  0000185E
 0000183C	 F6434000	MOV R0 #15360
 00001840	 F2C40002	MOVT R0 #16386
 00001844	     2105	MOVS R1 #5
 00001846	     7001	STRB R1 [ R0 + 0 ]
 00001848	 F6434000	MOV R0 #15360
 0000184C	 F2C40002	MOVT R0 #16386
 00001850	     6800	LDR R0 [ R0 + 0 ]
 00001852	     9001	STR R0 [ SP + 4 ]
 00001854	     9801	LDR R0 [ SP + 4 ]
 00001856	 F010000F	ANDS R0 R0 #15
 0000185A	     2805	CMP R0 #5
 0000185C	     D1F4	BNE #-24, goes to  00001848
 0000185E	 F6430008	MOV R0 #14344
 00001862	 F2C40002	MOVT R0 #16386
 00001866	     6800	LDR R0 [ R0 + 0 ]
 00001868	     9001	STR R0 [ SP + 4 ]
 0000186A	     9801	LDR R0 [ SP + 4 ]
 0000186C	 F64F41F3	MOV R1 #64755
 00001870	 EA300001	BICS R0 R0 R1 LSL #0
 00001874	 F64F4102	MOV R1 #64514
 00001878	 EA500001	ORRS R0 R0 R1 LSL #0
 0000187C	 F6430108	MOV R1 #14344
 00001880	 F2C40102	MOVT R1 #16386
 00001884	     6008	STR R0 [  R1 + 0 ]
 00001886	 F6430008	MOV R0 #14344
 0000188A	 F2C40002	MOVT R0 #16386
 0000188E	     6800	LDR R0 [ R0 + 0 ]
 00001890	     9001	STR R0 [ SP + 4 ]
 00001892	     9801	LDR R0 [ SP + 4 ]
 00001894	 F010000C	ANDS R0 R0 #12
 00001898	     2808	CMP R0 #8
 0000189A	     D1F4	BNE #-24, goes to  00001886
 0000189C	     9801	LDR R0 [ SP + 4 ]
 0000189E	 F430407C	BICS R0 R0 #64512
 000018A2	 F4504014	ORRS R0 R0 #37888
 000018A6	 F6430108	MOV R1 #14344
 000018AA	 F2C40102	MOVT R1 #16386
 000018AE	     6008	STR R0 [  R1 + 0 ]
 000018B0	 F24E0014	MOV R0 #57364
 000018B4	 F2CE0000	MOVT R0 #57344
 000018B8	 F249013F	MOV R1 #36927
 000018BC	 F2C00102	MOVT R1 #2
 000018C0	     6001	STR R1 [  R0 + 0 ]
 000018C2	 F85DEB04	LDR LR [ SP ] + 4
 000018C6	     B001	ADD SP SP #4
 000018C8	     4770	BX LR
 000018CA	     B081	SUB SP SP #4
 000018CC	     B500	PUSH LR
 000018CE	 F24E0008	MOV R0 #57352
 000018D2	 F2CE0000	MOVT R0 #57344
 000018D6	     2101	MOVS R1 #1
 000018D8	     6001	STR R1 [  R0 + 0 ]
 000018DA	 F6434000	MOV R0 #15360
 000018DE	 F2C40002	MOVT R0 #16386
 000018E2	     6800	LDR R0 [ R0 + 0 ]
 000018E4	     9001	STR R0 [ SP + 4 ]
 000018E6	     9801	LDR R0 [ SP + 4 ]
 000018E8	 F45060E0	ORRS R0 R0 #1792
 000018EC	 F6434100	MOV R1 #15360
 000018F0	 F2C40102	MOVT R1 #16386
 000018F4	     6008	STR R0 [  R1 + 0 ]
 000018F6	 F64E500C	MOV R0 #60684
 000018FA	 F2CE0000	MOVT R0 #57344
 000018FE	 F2403100	MOV R1 #768
 00001902	 F2C051FA	MOVT R1 #1530
 00001906	     6001	STR R1 [  R0 + 0 ]
 00001908	 F64E5023	MOV R0 #60707
 0000190C	 F2CE0000	MOVT R0 #57344
 00001910	     21A0	MOVS R1 #160
 00001912	     7001	STRB R1 [ R0 + 0 ]
 00001914	 F64000B8	MOV R0 #2232
 00001918	 F2C42047	MOVT R0 #16967
 0000191C	     2101	MOVS R1 #1
 0000191E	     7001	STRB R1 [ R0 + 0 ]
 00001920	 F6400070	MOV R0 #2160
 00001924	 F2C42047	MOVT R0 #16967
 00001928	     2101	MOVS R1 #1
 0000192A	     7001	STRB R1 [ R0 + 0 ]
 0000192C	 F64E5019	MOV R0 #60697
 00001930	 F2CE0000	MOVT R0 #57344
 00001934	     2110	MOVS R1 #16
 00001936	     7001	STRB R1 [ R0 + 0 ]
 00001938	 F64E501A	MOV R0 #60698
 0000193C	 F2CE0000	MOVT R0 #57344
 00001940	     2110	MOVS R1 #16
 00001942	     7001	STRB R1 [ R0 + 0 ]
 00001944	 F64E501F	MOV R0 #60703
 00001948	 F2CE0000	MOVT R0 #57344
 0000194C	     21F0	MOVS R1 #240
 0000194E	     7001	STRB R1 [ R0 + 0 ]
 00001950	 F64E5022	MOV R0 #60706
 00001954	 F2CE0000	MOVT R0 #57344
 00001958	     21F0	MOVS R1 #240
 0000195A	     7001	STRB R1 [ R0 + 0 ]
 0000195C	 F85DEB04	LDR LR [ SP ] + 4
 00001960	     B001	ADD SP SP #4
 00001962	     4770	BX LR
 00001964	     B081	SUB SP SP #4
 00001966	     B500	PUSH LR
 00001968	 F6400070	MOV R0 #2160
 0000196C	 F2C42047	MOVT R0 #16967
 00001970	     2101	MOVS R1 #1
 00001972	     7001	STRB R1 [ R0 + 0 ]
 00001974	 F6400070	MOV R0 #2160
 00001978	 F2C42047	MOVT R0 #16967
 0000197C	     7800	LDRB R0 [ R0 + 0 ]
 0000197E	 F88D0004	STRB R0 [  SP + 4 ]
 00001982	     2020	MOVS R0 #32
 00001984	 F2C4200E	MOVT R0 #16910
 00001988	     2101	MOVS R1 #1
 0000198A	     7001	STRB R1 [ R0 + 0 ]
 0000198C	     2020	MOVS R0 #32
 0000198E	 F2C4200E	MOVT R0 #16910
 00001992	     6800	LDR R0 [ R0 + 0 ]
 00001994	     2800	CMP R0 #0
 00001996	     D0F9	BEQ #-14, goes to  0000198C
 00001998	 F85DEB04	LDR LR [ SP ] + 4
 0000199C	     B001	ADD SP SP #4
 0000199E	     4770	BX LR
 000019A0	 F7FFFF93	BL #-218, goes to  000018CA
 000019A4	 F7FFFF0C	BL #-488, goes to  000017C0
 000019A8	 F7FFFED2	BL #-604, goes to  00001750
 000019AC	 F7FFFD8B	BL #-1258, goes to  000014C6
 000019B0	 F7FFFD37	BL #-1426, goes to  00001422
 000019B4	 F7FFFCF8	BL #-1552, goes to  000013A8
 000019B8	 F7FFFFD4	BL #-88, goes to  00001964
 000019BC	 F6420050	MOV R0 #10320
 000019C0	 F2C40000	MOVT R0 #16384
 000019C4	 F2410100	MOV R1 #4096
 000019C8	 F2CD0120	MOVT R1 #53280
 000019CC	     6001	STR R1 [  R0 + 0 ]
 000019CE	     2000	MOVS R0 #0
 000019D0	 F2C10001	MOVT R0 #4097
 000019D4	 F3808809	MSR PSP R0
 000019D8	     2002	MOVS R0 #2
 000019DA	 F3808814	MSR CONTROL R0
 000019DE	 F3BF8F6F	ISB
 000019E2	 F8DFF004	LDR PC = D0201001H

