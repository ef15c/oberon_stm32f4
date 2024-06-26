MODULE SDCard2;
  IMPORT SYSTEM, BSP;

  CONST SDHandleDescAddr = 20000368H;
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

    BLOCKSIZE = 512;

  TYPE
    SDCardInfoDesc* = RECORD
      CardType*, CardVersion*, Class*, RelCardAdd*, BlockNbr*, BlockSize*, LogBlockNbr*, LogBlockSize*: INTEGER
    END;

    SDHandleDesc* = RECORD
      ErrorCode*: SET;
      SdCard*: SDCardInfoDesc;
      CID*, CSD*: ARRAY 4 OF INTEGER;
      readErrors*, writeErrors*, unrecoverableErrors*: INTEGER;
      buf*: INTEGER (*address of data buffer*)
    END;
    SDHandle = POINTER TO SDHandleDesc;

    SDCardCSDDesc* = RECORD
      CSDStruct* (*CSD structure*),
      TAAC* (*Data read access time 1*), NSAC* (*Data read access time 2 in CLK cycles*), MaxBusClkFreq* (*Max. bus clock frequency*): BYTE;
      CardComdClasses* (*Card command classes*): INTEGER;
      RdBlockLen* (*Max. read data block length*): BYTE;
      PartBlockRead* (*Partial blocks for read allowed*), WrBlockMisalign* (*Write block misalignment*), RdBlockMisalign* (*Read block misalignment*),
      DSRImpl* (*DSR implemented*): BOOLEAN;
      DeviceSize* (*Device Size*): INTEGER;
      MaxRdCurrentVDDMin* (*Max. read current @ VDD min*), MaxRdCurrentVDDMax* (*Max. read current @ VDD max*),
      MaxWrCurrentVDDMin* (*Max. write current @ VDD min*), MaxWrCurrentVDDMax* (*Max. write current @ VDD max*),
      DeviceSizeMul* (*Device size multiplier*): BYTE;
      EraseBlkEn* (*Erase single group enabled*): BOOLEAN;
      SectorSize* (*erase sector size*), WrProtectGrSize* (*Write protect group size*): BYTE;
      WrProtectGrEnable* (*Write protect group enabled*): BOOLEAN;
      WrSpeedFact* (*Write speed factor*), MaxWrBlockLen* (*Max. write data block length*): BYTE;
      WriteBlockPartial* (*Partial blocks for write allowed*): BOOLEAN;
      FileFormatGroup* (*File format group*): BYTE;
      CopyFlag* (*Copy flag (OTP)*), PermWrProtect* (*Permanent write protection*), TempWrProtect* (*Temporary write protection*): BOOLEAN;
      FileFormat* (*File format*), CSD_CRC* (*CSD CRC*): BYTE
    END;

  VAR hsd*: SDHandle;

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

  PROCEDURE GetCardState(): INTEGER;
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

  PROCEDURE SDReadBlocksDMA(pData, blockAdd, nofBlocks: INTEGER): SET;
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
      IF hsd.SdCard.CardType # CARD_SDHC_SDXC THEN blockAdd := blockAdd*512 (*convert block to byte*) END;
      (*Configure the SD DPSM (Data Path State Machine*)
      SYSTEM.PUT(DTIMER, 0FFFFFFFFH); SYSTEM.PUT(DLEN, BLOCKSIZE*nofBlocks);
      SYSTEM.GET(DCTRL, reg); (*bs 512, card to host, block mode, enable data transfer*)
      SYSTEM.PUT(DCTRL, reg - DCTRL_CLEAR_MASK + (BSP.DATABLOCK_SIZE_512B + BSP.DTDIRm + BSP.DTENm + BSP.DMAENm));
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
          BSP.Delayus(100); SYSTEM.GET(BSP.DMA2_BASE + BSP.LISR, lisr); SYSTEM.GET(STA, sta)
        END;
        hsd.ErrorCode := CmdStopTransfer();
        IF ~(BSP.DATAEND IN sta) THEN
          SYSTEM.PUT(s3En, 0); (*abort DMA transfer*)
          IF BSP.TEIFx + BSP.LI_OFS3 IN lisr THEN hsd.ErrorCode := hsd.ErrorCode + ERROR_DMA END;
          IF BSP.DCRCFAIL IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_CRC_FAIL END;
          IF BSP.DTIMEOUT IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_TIMEOUT END;
          IF BSP.RXOVERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + RX_OVERRUN END;
          IF BSP.TXUNDERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + TX_UNDERRUN END;
          IF BSP.STBITERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_TIMEOUT END
        END
      END;
      REPEAT SYSTEM.GET(s3En, reg) UNTIL reg = NONE; (*wait until DMA transfer is complete*)
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.LIFCR, LSL(BSP.STREAM_FLAGSm, BSP.LI_OFS3)); (*Clear all DMA2 stream 3 interrupt flags*)
      SYSTEM.PUT(ICR, STATIC_FLAGS) (*clear all static flags*)
    END;

    RETURN hsd.ErrorCode
  END SDReadBlocksDMA;

  PROCEDURE SDWriteBlocksDMA(pData, blockAdd, nofBlocks: INTEGER): SET;
    VAR reg, hisr, sta: SET;
  BEGIN hsd.ErrorCode := NONE;
    IF nofBlocks < 1 THEN hsd.ErrorCode := INVALID_PARAMETER END;
    IF blockAdd + nofBlocks > hsd.SdCard.LogBlockNbr THEN hsd.ErrorCode := ADD_OUT_OF_RANGE END;
    IF hsd.ErrorCode = NONE THEN
      SYSTEM.PUT(DCTRL, 0); (*Initialize data control register*)
      SYSTEM.PUT(MASK, {}); (*disable all SDIO interrupts*)

      (*Start DMA*)
      SYSTEM.PUT(STREAM6_BASE + BSP.SxPAR, FIFO);
      SYSTEM.PUT(STREAM6_BASE + BSP.SxM0AR, pData);
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.HIFCR, LSL(BSP.STREAM_FLAGSm, BSP.HI_OFS6)); (*Clear all DMA2 stream 6 interrupt flags*)
      SYSTEM.GET(STREAM6_BASE + BSP.SxCR, reg);
      SYSTEM.PUT(STREAM6_BASE + BSP.SxCR, reg - (BSP.HTIEm + BSP.DMEIEm + BSP.SxCR_TCIEm + BSP.TEIEm)); (*disable all interrupts*)
      SYSTEM.GET(STREAM6_BASE + BSP.SxFCR, reg);
      SYSTEM.PUT(STREAM6_BASE + BSP.SxFCR, reg - BSP.FEIEm); (*disable fifo interrupt*)
      SYSTEM.PUT(s6En, 1); (*don't use TRUE because this register must be accessed by words (32 bits)*)

      IF hsd.SdCard.CardType # CARD_SDHC_SDXC THEN blockAdd := blockAdd*512 (*convert block to byte*) END;
      IF nofBlocks > 1 THEN (*multiple blocks write*)
        SYSTEM.PUT(ARG, LSL(hsd.SdCard.RelCardAdd, 16)); (*Send CMD55 APP_CMD with argument as card's RCA*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_APP_CMD + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        hsd.ErrorCode := GetCmdResp1(CMD_APP_CMD);
        IF hsd.ErrorCode = NONE THEN SYSTEM.PUT(ARG, nofBlocks); (*Send ACMD23 with argument as number of blocks*)
          SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_APP_SET_WR_BLK_ERASE_COUNT + BSP.RESPONSE_SHORT + BSP.CPSMENm));
          hsd.ErrorCode := GetCmdResp1(CMD_APP_SET_WR_BLK_ERASE_COUNT);
        END; (*now the SD card knows how many blocks will be overwritten*)
        IF hsd.ErrorCode = NONE THEN 
          SYSTEM.PUT(ARG, blockAdd); SYSTEM.GET(CMD, reg);
          SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_WRITE_MULT_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm));
          hsd.ErrorCode := GetCmdResp1(CMD_WRITE_MULT_BLOCK) (*check response*)
        END
      ELSE (*issue single block write command*)
        SYSTEM.PUT(ARG, blockAdd); SYSTEM.GET(CMD, reg);
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + (CMD_WRITE_SINGLE_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm));
        hsd.ErrorCode := GetCmdResp1(CMD_WRITE_SINGLE_BLOCK) (*check response*)
      END;

      IF hsd.ErrorCode = NONE THEN (*Configure the SD DPSM (Data Path State Machine*)
        SYSTEM.PUT(DTIMER, 0FFFFFFFFH); SYSTEM.PUT(DLEN, BLOCKSIZE*nofBlocks);
        SYSTEM.GET(DCTRL, reg); (*bs 512, host to card, block mode, enable data transfer, DMA enabled*)
        SYSTEM.PUT(DCTRL, reg - DCTRL_CLEAR_MASK + (BSP.DATABLOCK_SIZE_512B + BSP.DTENm + BSP.DMAENm));

        (*wait for end of operation*)
        SYSTEM.GET(BSP.DMA2_BASE + BSP.HISR, hisr); SYSTEM.GET(STA, sta);
        WHILE ~(BSP.TEIFx + BSP.HI_OFS6 IN hisr) &
          (sta*(BSP.DCRCFAILm + BSP.DTIMEOUTm + BSP.TXUNDERRm + BSP.DATAENDm + BSP.STBITERRm) = {}) DO
          BSP.Delayus(100); SYSTEM.GET(BSP.DMA2_BASE + BSP.HISR, hisr); SYSTEM.GET(STA, sta)
        END;
        hsd.ErrorCode := CmdStopTransfer();
        IF ~(BSP.DATAEND IN sta) THEN
          SYSTEM.PUT(s6En, 0); (*abort DMA transfer*)
          IF BSP.TEIFx + BSP.HI_OFS6 IN hisr THEN hsd.ErrorCode := hsd.ErrorCode + ERROR_DMA END;
          IF BSP.DCRCFAIL IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_CRC_FAIL END;
          IF BSP.DTIMEOUT IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_TIMEOUT END;
          IF BSP.RXOVERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + RX_OVERRUN END;
          IF BSP.TXUNDERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + TX_UNDERRUN END;
          IF BSP.STBITERR IN sta THEN hsd.ErrorCode := hsd.ErrorCode + DATA_TIMEOUT END
        END
      END;
      REPEAT SYSTEM.GET(s6En, reg) UNTIL reg = NONE; (*wait until DMA transfer is complete*)
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.HIFCR, LSL(BSP.STREAM_FLAGSm, BSP.HI_OFS6)); (*Clear all DMA2 stream 6 interrupt flags*)
      SYSTEM.PUT(ICR, STATIC_FLAGS) (*clear all static flags*)
    END;

    RETURN hsd.ErrorCode
  END SDWriteBlocksDMA;

  PROCEDURE Read*(src, dst, nofblocks: INTEGER);
  VAR rc: SET;
  BEGIN BSP.ledsOnOff({0}, {});
    IF nofblocks > 128 THEN BSP.ledsOnOff({1}, {0}); ASSERT(FALSE) END;
    rc := SDReadBlocksDMA(hsd.buf, src, nofblocks);
    IF rc = NONE THEN
      WHILE GetCardState() #CARD_TRANSFER DO BSP.Delayus(1000) END
    END;

    IF hsd.ErrorCode = NONE THEN SYSTEM.COPY(hsd.buf, dst, nofblocks*(512 DIV 4)) ELSE INC(hsd.readErrors); BSP.ledsOnOff({1}, {}) END;
    BSP.ledsOnOff({}, {0});
  END Read;

  PROCEDURE Write*(dst, src, nofblocks: INTEGER);
  VAR rc: SET; retry: INTEGER;
  BEGIN BSP.ledsOnOff({0}, {});
    IF nofblocks > 128 THEN BSP.ledsOnOff({1}, {0}); ASSERT(FALSE) END;
    SYSTEM.COPY(src, hsd.buf, nofblocks*(512 DIV 4));
    REPEAT rc := SDWriteBlocksDMA(hsd.buf, dst, nofblocks);
      IF rc = NONE THEN
        WHILE GetCardState() #CARD_TRANSFER DO BSP.Delayus(1000) END
      END;

      IF hsd.ErrorCode # NONE THEN INC(hsd.writeErrors); BSP.ledsOnOff({1}, {}) END;
      DEC(retry)
    UNTIL (hsd.ErrorCode = NONE) OR (retry = 0);
    IF (hsd.ErrorCode # NONE) THEN INC(hsd.unrecoverableErrors) END;
    BSP.ledsOnOff({}, {0});
  END Write;

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

  PROCEDURE LLInit*;
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
      maskF_1b = {BSP.LED1Pin}; maskF_2b = LSL(BSP.MASK2, BSP.LED1Pin);
    VAR reg: SET; en: BYTE;
      scr: ARRAY 2 OF SET;
      index: INTEGER;
  BEGIN SYSTEM.PUT(BSP.sdioEn, TRUE);
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
      {}, {},
      LSL(SYSTEM.VAL(SET, 12), 2*4),
      {}); (*PD2 AF12 pp hs, PD4 and PD5 inputs pulled up*)
    configureGPIO(BSP.GPIOF, maskF_1b, maskF_2b, {}, {}, LSL(BSP.OUTPUT_MODE, BSP.LED1Pin), {}, {}, {}, {}, {}); (*PF9 output pp ls*)

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
    SYSTEM.PUT(BSP.sdioClkEn, 1); BSP.Delayus(2000); (*waiting time required before starting SD initialization*)
    (*Initialize the card*) 
    hsd.ErrorCode := SDPowerOn(hsd^); (*identify card operating voltage*)
    IF hsd.ErrorCode = NONE THEN
      hsd.ErrorCode := SDInitCard(hsd^); (*Initialize the card*)
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
  END LLInit;

  PROCEDURE Init*;
  BEGIN hsd := SYSTEM.VAL(SDHandle, SDHandleDescAddr);
    hsd.readErrors := 0; hsd.writeErrors := 0; hsd.unrecoverableErrors := 0
  END Init;

END SDCard2.
