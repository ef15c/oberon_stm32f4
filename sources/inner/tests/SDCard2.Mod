MODULE SDCard2;
  IMPORT SYSTEM, BSP;

  CONST
    (*common error flag*) NONE = {}; 

    (*SDIO error flags*) CMD_CRC_FAIL = {0}; DATA_CRC_FAIL = {1}; CMD_RSP_TIMEOUT = {2}; DATA_TIMEOUT = {3}; TX_UNDERRUN = {4};
      RX_OVERRUN = {5}; ADDR_MISALIGNED = {6}; BLOCK_LEN_ERR = {7}; ERASE_SEQ_ERR = {8}; BAD_ERASE_PARAM = {9};
      WRITE_PROT_VIOLATION = {10}; LOCK_UNLOCK_FAILED = {11}; COM_CRC_FAILED = {12}; ILLEGAL_CMD = {13}; CARD_ECC_FAILED = {14};
      CC_ERR = {15}; GENERAL_UNKNOWN_ERR = {16}; STREAM_READ_UNDERRUN= {17}; STREAM_WRITE_OVERRUN = {18};
      CID_CSD_OVERWRITE = {19}; WP_ERASE_SKIP = {20}; CARD_ECC_DISABLED = {21}; ERASE_RESET = {22}; AKE_SEQ_ERR = {23};
      ADD_OUT_OF_RANGE = {25}; INVALID_PARAMETER = {27}; UNSUPPORTED_FEATURE = {28}; BUSY = {29}; ERROR_DMA = {30};
      ERROR_TIMEOUT = {31};

    (*OCR flags*) OCR_ADDR_OUT_OF_RANGE = {31}; OCR_ADDR_MISALIGNED = {30}; OCR_BLOCK_LEN_ERR = {29};
      OCR_ERASE_SEQ_ERR = {28}; OCR_BAD_ERASE_PARAM = {27}; OCR_WRITE_PROT_VIOLATION = {26}; OCR_LOCK_UNLOCK_FAILED = {24};
      OCR_COM_CRC_FAILED = {23}; OCR_ILLEGAL_CMD = {22}; OCR_CARD_ECC_FAILED = {21}; OCR_CC_ERROR = {20};
      OCR_GENERAL_UNKNOWN_ERROR =  {19}; OCR_STREAM_READ_UNDERRUN = {18}; OCR_STREAM_WRITE_OVERRUN = {17};
      OCR_CID_CSD_OVERWRITE = {16}; OCR_WP_ERASE_SKIP = {15}; OCR_CARD_ECC_DISABLED = {14}; OCR_ERASE_RESET = {13};
      OCR_AKE_SEQ_ERROR = {3}; OCR_ERRORBITS = {3, 13..24, 26..31};

    (*card type*) CARD_SDSC = 0; CARD_SDHC_SDXC = 1; CARD_SECURED = 3;
    (*card states*) CARD_READY = 1; CARD_IDENTIFICATION = 2; CARD_STANDBY = 3; CARD_TRANSFER = 4; CARD_SENDING = 5;
      CARD_RECEIVING = 6; CARD_PROGRAMMING = 7; CARD_DISCONNECTED = 8; CARD_ERROR = 0FFH;

    (*SD commands*) CMD_STOP_TRANSMISSION = SYSTEM.VAL(SET, 12); CMD_SEND_STATUS = SYSTEM.VAL(SET, 13);
      CMD_READ_SINGLE_BLOCK = SYSTEM.VAL(SET, 17); CMD_READ_MULT_BLOCK = SYSTEM.VAL(SET, 18);
      CMD_APP_CMD = SYSTEM.VAL(SET, 55); CMD_APP_SET_WR_BLK_ERASE_COUNT = SYSTEM.VAL(SET, 23);
      CMD_WRITE_SINGLE_BLOCK = SYSTEM.VAL(SET, 24); CMD_WRITE_MULT_BLOCK = SYSTEM.VAL(SET, 25);

    ARG =  BSP.SDIO_BASE + BSP.ARG; CMD =  BSP.SDIO_BASE + BSP.CMD; RESPCMD = BSP.SDIO_BASE + BSP.RESPCMD;
    RESP1 = BSP.SDIO_BASE + BSP.RESP1;
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
    SDCardInfo = POINTER TO SDCardInfoDesc;

    SDHandleDesc* = RECORD
      ErrorCode*: SET;
      SdCard*: SDCardInfo;
      readErrors*, writeErrors*, unrecoverableErrors*: INTEGER
    END;

  VAR hsd*: SDHandleDesc; sdBuf: INTEGER;

  PROCEDURE GetCmdResp1(cmd: SET): SET;
    VAR rc, reg: SET;
  BEGIN rc := NONE;
    REPEAT SYSTEM.GET(STA, reg) UNTIL (reg*(BSP.CCRCFAILm + BSP.CMDRENDm + BSP.CTIMEOUTm) # {}) & (reg*BSP.CMDACTm = {}); (*wait for response*)
    reg := reg*(BSP.CTIMEOUTm + BSP.CCRCFAILm);
    IF reg # {} THEN (*error*) rc := reg END;
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

  PROCEDURE GetCardState(): INTEGER;
    VAR reg: SET;
  BEGIN SYSTEM.PUT(ARG, LSL(hsd.SdCard.RelCardAdd, 16)); SYSTEM.GET(CMD, reg);
    SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_SEND_STATUS + BSP.RESPONSE_SHORT + BSP.CPSMENm);
    hsd.ErrorCode := hsd.ErrorCode + GetCmdResp1(CMD_SEND_STATUS); (*check response*)
    SYSTEM.GET(RESP1, reg);

    RETURN LSR(ORD(reg), 9) MOD 16
  END GetCardState;

 PROCEDURE CmdStopTransfer(): SET;
    VAR reg: SET;
  BEGIN
    SYSTEM.PUT(ARG, 0); SYSTEM.GET(CMD, reg);
    SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_STOP_TRANSMISSION + BSP.RESPONSE_SHORT + BSP.CPSMENm);

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
      SYSTEM.PUT(DCTRL, reg - DCTRL_CLEAR_MASK + SYSTEM.VAL(SET, LSL(9, 4)) + BSP.DTDIRm + BSP.DTENm + BSP.DMAENm);
      SYSTEM.PUT(ARG, blockAdd); SYSTEM.GET(CMD, reg);
      IF nofBlocks > 1 THEN (*issue multiple blocks read command*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_READ_MULT_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm);
        hsd.ErrorCode := GetCmdResp1(CMD_READ_MULT_BLOCK) (*check response*)
      ELSE (*issue single block read command*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_READ_SINGLE_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm);
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
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_APP_CMD + BSP.RESPONSE_SHORT + BSP.CPSMENm);
        hsd.ErrorCode := GetCmdResp1(CMD_APP_CMD);
        IF hsd.ErrorCode = NONE THEN SYSTEM.PUT(ARG, nofBlocks); (*Send ACMD23 with argument as number of blocks*)
          SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_APP_SET_WR_BLK_ERASE_COUNT + BSP.RESPONSE_SHORT + BSP.CPSMENm);
          hsd.ErrorCode := GetCmdResp1(CMD_APP_SET_WR_BLK_ERASE_COUNT);
        END; (*now the SD card knows how many blocks will be overwritten*)
        IF hsd.ErrorCode = NONE THEN 
          SYSTEM.PUT(ARG, blockAdd); SYSTEM.GET(CMD, reg);
          SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_WRITE_MULT_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm);
          hsd.ErrorCode := GetCmdResp1(CMD_WRITE_MULT_BLOCK) (*check response*)
        END
      ELSE (*issue single block write command*)
        SYSTEM.PUT(ARG, blockAdd); SYSTEM.GET(CMD, reg);
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_WRITE_SINGLE_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm);
        hsd.ErrorCode := GetCmdResp1(CMD_WRITE_SINGLE_BLOCK) (*check response*)
      END;

      IF hsd.ErrorCode = NONE THEN (*Configure the SD DPSM (Data Path State Machine*)
        SYSTEM.PUT(DTIMER, 0FFFFFFFFH); SYSTEM.PUT(DLEN, BLOCKSIZE*nofBlocks);
        SYSTEM.GET(DCTRL, reg); (*bs 512, host to card, block mode, enable data transfer, DMA enabled*)
        SYSTEM.PUT(DCTRL, reg - DCTRL_CLEAR_MASK + SYSTEM.VAL(SET, LSL(9, 4)) + BSP.DTENm + BSP.DMAENm);

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
    rc := SDReadBlocksDMA(sdBuf, src, nofblocks);
    IF rc = NONE THEN
      WHILE GetCardState() #CARD_TRANSFER DO BSP.Delayus(1000) END
    END;

    IF hsd.ErrorCode = NONE THEN SYSTEM.COPY(sdBuf, dst, nofblocks*(512 DIV 4)) ELSE INC(hsd.readErrors); BSP.ledsOnOff({1}, {}) END;
    BSP.ledsOnOff({}, {0});
  END Read;

  PROCEDURE Write*(dst, src, nofblocks: INTEGER);
  VAR rc: SET; retry: INTEGER;
  BEGIN BSP.ledsOnOff({0}, {});
    IF nofblocks > 128 THEN BSP.ledsOnOff({1}, {0}); ASSERT(FALSE) END;
    SYSTEM.COPY(src, sdBuf, nofblocks*(512 DIV 4));
    REPEAT rc := SDWriteBlocksDMA(sdBuf, dst, nofblocks);
      IF rc = NONE THEN
        WHILE GetCardState() #CARD_TRANSFER DO BSP.Delayus(1000) END
      END;

      IF hsd.ErrorCode # NONE THEN INC(hsd.writeErrors); BSP.ledsOnOff({1}, {}) END;
      DEC(retry)
    UNTIL (hsd.ErrorCode = NONE) OR (retry = 0);
    IF (hsd.ErrorCode # NONE) THEN INC(hsd.unrecoverableErrors) END;
    BSP.ledsOnOff({}, {0});
  END Write;

  PROCEDURE Init*;
  BEGIN hsd.SdCard := SYSTEM.VAL(SDCardInfo, SYSTEM.SVC(8)); sdBuf := SYSTEM.SVC(9);
    hsd.readErrors := 0; hsd.writeErrors := 0; hsd.unrecoverableErrors := 0
  END Init;

END SDCard2.
