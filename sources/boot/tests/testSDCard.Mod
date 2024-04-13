MODULE testSDCard;
  IMPORT SYSTEM, BSP, Texts, Oberon;

  CONST
    (*common error flag*) SUCCESS = {}; 

    (*DMA states*) DMA_RESET = 0; DMA_READY = 1; DMA_BUSY = 2; DMA_TIMEOUT = 3; DMA_ERROR = 4; DMA_ABORT = 5;
    (*DMA error flasg*) TE = {0}; FE = {1}; DME = {2}; TIMEOUT = {5}; PARAM_ERROR = {6}; NO_XFER = {7}; NOT_SUPPORTED_MODE = {8};

    (*SDIO error flags*) ADDR_MISALIGNED = {6}; BLOCK_LEN_ERR = {7}; ERASE_SEQ_ERR = {8}; BAD_ERASE_PARAM = {9};
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

    (*context flags*) NONE = {}; READ_SINGLE_BLOCK = {0}; READ_MULTIPLE_BLOCKS = {1};
    WRITE_SINGLE_BLOCK = {4}; WRITE_MULTIPLE_BLOCKS = {5};
    CONTEXT_IT = {3}; CONTEXT_DMA = {7};

    (*SD commands*) CMD_STOP_TRANSMISSION = SYSTEM.VAL(SET, 12); CMD_SEND_STATUS = SYSTEM.VAL(SET, 13);
      CMD_READ_SINGLE_BLOCK = SYSTEM.VAL(SET, 17); CMD_READ_MULT_BLOCK = SYSTEM.VAL(SET, 18);

    ARG =  BSP.SDIO_BASE + BSP.ARG; CMD =  BSP.SDIO_BASE + BSP.CMD; RESPCMD = BSP.SDIO_BASE + BSP.RESPCMD;
    RESP1 = BSP.SDIO_BASE + BSP.RESP1;
    DTIMER = BSP.SDIO_BASE + BSP.DTIMER; DLEN = BSP.SDIO_BASE + BSP.DLEN;
    DCTRL = BSP.SDIO_BASE + BSP.DCTRL; MASK = BSP.SDIO_BASE + BSP.MASK; FIFO = BSP.SDIO_BASE + BSP.FIFO;
    STA = BSP.SDIO_BASE + BSP.STA; ICR = BSP.SDIO_BASE + BSP.ICR;

    DCTRL_CLEAR_MASK = BSP.DTENm + BSP. DTDIRm + BSP. DTMODEm + BSP.DBLOCKSIZEm;
    CMD_CLEAR_MASK = BSP.CMDINDEXm + BSP.WAITRESPm + BSP.WAITINTm + BSP.WAITPENDm + BSP.CPSMENm + BSP.SDIOSuspendm;

    STATIC_CMD_FLAGS = BSP.CCRCFAILm + BSP.CTIMEOUTm + BSP.CMDRENDm + BSP.CMDSENTm;
    STATIC_DATA_FLAGS = BSP.DCRCFAILm + BSP.DTIMEOUTm + BSP.TXUNDERRm + BSP.RXOVERRm + BSP.DATAENDm + BSP.DBCKENDm;

    STREAM_BASE = BSP.DMA2_BASE + BSP.STREAM_PARAM_SIZE*3;
    s3Dbm = BSP.PeriphBBAlias + (STREAM_BASE + BSP.SxCR - BSP.PeriphBase + BSP.DBM DIV 8)*32 + BSP.DBM MOD 8*4;
    s3En = BSP.PeriphBBAlias + (STREAM_BASE + BSP.SxCR - BSP.PeriphBase + BSP.SxCR_EN DIV 8)*32 + BSP.SxCR_EN MOD 8*4;

    BLOCKSIZE = 512;

  TYPE
    DMAHandleDesc = RECORD
      State: INTEGER;
      ErrorCode: SET
    END;

    SDCardInfoDesc = RECORD
      CardType, CardVersion, Class, RelCardAdd, BlockNbr, BlockSize, LogBlockNbr, LogBlockSize: INTEGER
    END;
    SDCardInfo = POINTER TO SDCardInfoDesc;

    SDHandleDesc = RECORD
      Context, ErrorCode: SET;
      hdmatx, hdmarx: DMAHandleDesc;
      SdCard: SDCardInfo
    END;

  VAR hsd: SDHandleDesc;
    W: Texts.Writer;

PROCEDURE GetCmdResp1(cmd: SET): SET;
  VAR rc, reg: SET;
  BEGIN rc := SUCCESS;
    REPEAT SYSTEM.GET(STA, reg) UNTIL (reg*(BSP.CCRCFAILm + BSP.CMDRENDm + BSP.CTIMEOUTm) # {}) & (reg*BSP.CMDACTm = {}); (*wait for response*)
    reg := reg*(BSP.CTIMEOUTm + BSP.CCRCFAILm);
    IF reg # {} THEN (*error*) rc := reg END;
    SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear cmd static flags*)
    IF rc = SUCCESS THEN
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

  PROCEDURE^3 GetCardState(): INTEGER;
    VAR reg, errorstate: SET;
  BEGIN SYSTEM.PUT(ARG, LSL(hsd.SdCard.RelCardAdd, 16)); SYSTEM.GET(CMD, reg);
    SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_SEND_STATUS + BSP.RESPONSE_SHORT + BSP.CPSMENm);
    errorstate := GetCmdResp1(CMD_SEND_STATUS); (*check response*)
    hsd.ErrorCode := hsd.ErrorCode + errorstate;
    SYSTEM.GET(RESP1, reg);

    RETURN LSR(ORD(reg), 9) MOD 16
  END GetCardState;

  PROCEDURE^3 SDRxCplt;
    (*unused*)
  END SDRxCplt;

  PROCEDURE^3 SDError;
    (*unused*)
  END SDError;

  PROCEDURE^3 CmdStopTransfer(): SET;
    VAR reg: SET;
  BEGIN
    SYSTEM.PUT(ARG, 0); SYSTEM.GET(CMD, reg);
    SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_STOP_TRANSMISSION + BSP.RESPONSE_SHORT + BSP.CPSMENm);

    RETURN GetCmdResp1(CMD_STOP_TRANSMISSION) (*check response*)
  END CmdStopTransfer;

  PROCEDURE^3 DMAReceiveCplt;
    VAR reg, errorstate: SET;
  BEGIN
    IF hsd.Context = READ_MULTIPLE_BLOCKS + CONTEXT_DMA THEN errorstate := CmdStopTransfer();
      IF errorstate # NONE THEN hsd.ErrorCode := hsd.ErrorCode + errorstate; SDError END
    END;
    SYSTEM.PUT(BSP.sdioDmaEn, 0); SYSTEM.PUT(ICR, STATIC_DATA_FLAGS); (*clear data static flags*)
    hsd.Context := NONE; SDRxCplt
(*todo*)
  END DMAReceiveCplt;

  PROCEDURE^3 DMAError;
    VAR reg: SET; CardState: INTEGER;
  BEGIN
    IF (hsd.hdmarx.ErrorCode*TE = TE) OR (hsd.hdmatx.ErrorCode*TE = TE) THEN
      SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear all static flags*)
      SYSTEM.GET(MASK, reg); (*disable all interrupts*)
      SYSTEM.PUT(MASK, reg - (BSP.DCRCFAILm + BSP.DTIMEOUTm + BSP.TXUNDERRm + BSP.RXOVERRm + BSP.DATAENDm + BSP.STBITERRm));
      hsd.ErrorCode := hsd.ErrorCode + ERROR_DMA; CardState := GetCardState();
      IF (CardState = CARD_RECEIVING) OR (CardState = CARD_SENDING) THEN hsd.ErrorCode := hsd.ErrorCode + CmdStopTransfer();
        hsd.Context := NONE
      END;
      SDError
    END
  END DMAError;

  PROCEDURE^3 RXDMAIrqHandler;
    VAR lisr, cr, fcr: SET; res: INTEGER;
  BEGIN SYSTEM.GET(BSP.DMA2_BASE + BSP.LISR, lisr); lisr := lisr*LSL(BSP.STREAM_FLAGSm, BSP.LI_OFS3); (*put DMA2 stream 3 flags in reg*)
    SYSTEM.GET(STREAM_BASE + BSP.SxCR, cr); SYSTEM.GET(STREAM_BASE + BSP.SxFCR, fcr);
    IF (BSP.TEIE IN cr) & (LSL(BSP.TEIFx, BSP.LI_OFS3) IN lisr) THEN (*transfer error*)
      cr := cr - BSP.TEIEm; SYSTEM.PUT(STREAM_BASE + BSP.SxCR, cr); (*disable transfer error interrupt*)
      hsd.hdmarx.ErrorCode := hsd.hdmarx.ErrorCode + TE
    END;
(*    IF (BSP.FEIE IN fcr) & (LSL(BSP.FEIFx, BSP.LI_OFS3) IN lisr) THEN (*fifo error*) hsd.hdmarx.ErrorCode := hsd.hdmarx.ErrorCode + FE END;
    IF (BSP.DMEIE IN cr) & (LSL(BSP.DMEIFx, BSP.LI_OFS3) IN lisr) THEN (*direct memory error*) hsd.hdmarx.ErrorCode := hsd.hdmarx.ErrorCode + DME END;*)
    IF (BSP.SxCR_TCIE IN cr) & (LSL(BSP.TCIFx, BSP.LI_OFS3) IN lisr) THEN (*transfer complete*)
      hsd.hdmarx.State := DMA_READY;
      IF hsd.hdmarx.State = DMA_ABORT THEN cr := cr - (BSP.SxCR_TCIEm + BSP.TEIEm); SYSTEM.PUT(STREAM_BASE + BSP.SxCR, cr); (*disable interrupts*)
      ELSE cr := cr - BSP.SxCR_TCIEm; SYSTEM.PUT(STREAM_BASE + BSP.SxCR, cr); (*disable transfer complete interrupt*)
        DMAReceiveCplt
      END;
      IF hsd.hdmarx.ErrorCode # NONE THEN (*manage error cases*)
        IF hsd.hdmarx.ErrorCode*TE # NONE THEN (*tranfer error*) hsd.hdmarx.State := DMA_ABORT;
          SYSTEM.PUT(s3En, 0); REPEAT SYSTEM.GET(s3En, res) UNTIL res = 0; hsd.hdmarx.State := DMA_READY
        END;
        DMAError
      END
    END;
    SYSTEM.PUT(BSP.DMA2_BASE + BSP.LIFCR, lisr); (*clear error flags*)
  END RXDMAIrqHandler;

  PROCEDURE SDReadBlocksDMA*(ci: SDCardInfo; pData, blockAdd, nofBlocks: INTEGER): SET;
    VAR rc, reg: SET;
  BEGIN rc := SUCCESS;
    IF nofBlocks < 1 THEN rc := INVALID_PARAMETER END;
    IF blockAdd + nofBlocks > ci.LogBlockNbr THEN rc := ADD_OUT_OF_RANGE END;
    IF rc = SUCCESS THEN
      SYSTEM.PUT(DCTRL, 0); (*Initialize data control register*)
      SYSTEM.GET(MASK, reg); SYSTEM.PUT(MASK, reg + (BSP.DCRCFAILm + BSP.DTIMEOUTm + BSP.RXOVERRm + BSP.DATAENDm + BSP.STBITERRm));
      (*Start DMA*)
      (*SYSTEM.PUT(STREAM_BASE + BSP.SxPAR, FIFO); inutile de le faire a chaque fois *)
      (*SYSTEM.PUT(STREAM_BASE + BSP.SxNDTR, BLOCKSIZE*nofBlocks DIV 4); inutile quand le peripherique controle le flux*)
      SYSTEM.PUT(STREAM_BASE + BSP.SxM0AR, pData);
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.LIFCR, LSL(BSP.STREAM_FLAGSm, BSP.LI_OFS3)); (*Clear all DMA2 stream 3 interrupt flags*)
      SYSTEM.GET(STREAM_BASE + BSP.SxCR, reg);
      SYSTEM.PUT(STREAM_BASE + BSP.SxCR, reg + (BSP.SxCR_TCIEm + BSP.TEIEm)); (*enable applicable interrupts*)
      SYSTEM.PUT(s3En, 1); (*don't use TRUE because this register must be accessed by words (32 bits)*)
      (*Start SDIO DMA transfer*)
      SYSTEM.PUT(BSP.sdioDmaEn, 1);
      IF ci.CardType # CARD_SDHC_SDXC THEN blockAdd := blockAdd*512 (*convert block to byte*) END;
      (*Configure the SD DPSM (Data Path State Machine*)
      SYSTEM.PUT(DTIMER, 0FFFFFFFFH); SYSTEM.PUT(DLEN, BLOCKSIZE*nofBlocks);
      SYSTEM.GET(DCTRL, reg); (*bs 512, card to host, block mode, enable data transfer*)
      SYSTEM.PUT(DCTRL, reg - DCTRL_CLEAR_MASK + SYSTEM.VAL(SET, LSL(9, 4)) + BSP.DTDIRm + BSP.DTENm);
      SYSTEM.PUT(ARG, blockAdd); SYSTEM.GET(CMD, reg);
      IF nofBlocks > 1 THEN 
        hsd.Context := READ_MULTIPLE_BLOCKS + CONTEXT_DMA;
        (*issue multiple blocks read command*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_READ_MULT_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm)
      ELSE
        hsd.Context := READ_SINGLE_BLOCK + CONTEXT_DMA;
        (*issue single block read command*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_READ_SINGLE_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm)
      END;
      rc := GetCmdResp1(CMD_READ_MULT_BLOCK); (*check response*)
      IF rc # SUCCESS THEN
        SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear all static flags*) hsd.Context := NONE
      END
    END;

    RETURN rc
  END SDReadBlocksDMA;

  PROCEDURE showCardInfo*;
  BEGIN Texts.WriteString(W, "CardType "); Texts.WriteHex(W, hsd.SdCard.CardType); Texts.WriteLn(W);
    Texts.WriteString(W, "CardVersion "); Texts.WriteHex(W, hsd.SdCard.CardVersion); Texts.WriteLn(W);
    Texts.WriteString(W, " Class"); Texts.WriteHex(W, hsd.SdCard.Class); Texts.WriteLn(W);
    Texts.WriteString(W, " RelCardAddr"); Texts.WriteHex(W, hsd.SdCard.RelCardAdd); Texts.WriteLn(W);
    Texts.WriteString(W, " BlockNbr"); Texts.WriteHex(W, hsd.SdCard.BlockNbr); Texts.WriteLn(W);
    Texts.WriteString(W, " BlockSize"); Texts.WriteHex(W, hsd.SdCard.BlockSize); Texts.WriteLn(W);
    Texts.WriteString(W, " LogBlockNbr"); Texts.WriteHex(W, hsd.SdCard.LogBlockNbr); Texts.WriteLn(W);
    Texts.WriteString(W, " LogBlockSize"); Texts.WriteHex(W, hsd.SdCard.LogBlockSize); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END showCardInfo;

BEGIN hsd.SdCard := SYSTEM.VAL(SDCardInfo, SYSTEM.SVC(8))
; Texts.OpenWriter(W)
END testSDCard.
