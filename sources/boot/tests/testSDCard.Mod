MODULE testSDCard;
  IMPORT SYSTEM, BSP;

  CONST
    (*error flags*) SUCCESS = {}; ADDR_MISALIGNED = {6}; BLOCK_LEN_ERR = {7}; ERASE_SEQ_ERR = {8}; BAD_ERASE_PARAM = {9};
    WRITE_PROT_VIOLATION = {10}; LOCK_UNLOCK_FAILED = {11}; COM_CRC_FAILED = {12}; ILLEGAL_CMD = {13}; CARD_ECC_FAILED = {14};
    CC_ERR = {15}; GENERAL_UNKNOWN_ERR = {16}; STREAM_READ_UNDERRUN= {17}; STREAM_WRITE_OVERRUN = {18};
    CID_CSD_OVERWRITE = {19}; WP_ERASE_SKIP = {20}; CARD_ECC_DISABLED = {21}; ERASE_RESET = {22}; AKE_SEQ_ERR = {23};
    ADD_OUT_OF_RANGE = {25}; INVALID_PARAMETER = {27};

    (*OCR flags*) OCR_ADDR_OUT_OF_RANGE = {31}; OCR_ADDR_MISALIGNED = {30}; OCR_BLOCK_LEN_ERR = {29};
      OCR_ERASE_SEQ_ERR = {28}; OCR_BAD_ERASE_PARAM = {27}; OCR_WRITE_PROT_VIOLATION = {26}; OCR_LOCK_UNLOCK_FAILED = {24};
      OCR_COM_CRC_FAILED = {23}; OCR_ILLEGAL_CMD = {22}; OCR_CARD_ECC_FAILED = {21}; OCR_CC_ERROR = {20};
      OCR_GENERAL_UNKNOWN_ERROR =  {19}; OCR_STREAM_READ_UNDERRUN = {18}; OCR_STREAM_WRITE_OVERRUN = {17};
      OCR_CID_CSD_OVERWRITE = {16}; OCR_WP_ERASE_SKIP = {15}; OCR_CARD_ECC_DISABLED = {14}; OCR_ERASE_RESET = {13};
      OCR_AKE_SEQ_ERROR = {3}; OCR_ERRORBITS = {3, 13..24, 26..31};

    (*card type*) CARD_SDSC = 0; CARD_SDHC_SDXC = 1; CARD_SECURED = 3;

    (*context flags*) NONE = {}; READ_SINGLE_BLOCK = {0}; READ_MULTIPLE_BLOCKS = {1};
    WRITE_SINGLE_BLOCK = {4}; WRITE_MULTIPLE_BLOCKS = {5};
    CONTEXT_IT = {3}; CONTEXT_DMA = {7};

    CMD_READ_SINGLE_BLOCK = SYSTEM.VAL(SET, 17); CMD_READ_MULT_BLOCK = SYSTEM.VAL(SET, 18);

    ARG =  BSP.SDIO_BASE + BSP.ARG; CMD =  BSP.SDIO_BASE + BSP.CMD; RESPCMD = BSP.SDIO_BASE + BSP.RESPCMD;
    RESP1 = BSP.SDIO_BASE + BSP.RESP1;
    DTIMER = BSP.SDIO_BASE + BSP.DTIMER; DLEN = BSP.SDIO_BASE + BSP.DLEN;
    DCTRL = BSP.SDIO_BASE + BSP.DCTRL; MASK = BSP.SDIO_BASE + BSP.MASK; FIFO = BSP.SDIO_BASE + BSP.FIFO;
    STA = BSP.SDIO_BASE + BSP.STA; ICR = BSP.SDIO_BASE + BSP.ICR;

    DCTRL_CLEAR_MASK = BSP.DTENm + BSP. DTDIRm + BSP. DTMODEm + BSP.DBLOCKSIZEm;
    CMD_CLEAR_MASK = BSP.CMDINDEXm + BSP.WAITRESPm + BSP.WAITINTm + BSP.WAITPENDm + BSP.CPSMENm + BSP.SDIOSuspendm;

    STATIC_CMD_FLAGS = BSP.CCRCFAILm + BSP.CTIMEOUTm + BSP.CMDRENDm + BSP.CMDSENTm;

    STREAM_BASE = BSP.DMA2_BASE + BSP.STREAM_PARAM_SIZE*3;
    s3Dbm = BSP.PeriphBBAlias + (STREAM_BASE + BSP.SxCR - BSP.PeriphBase + BSP.DBM DIV 8)*32 + BSP.DBM MOD 8*4;
    s3En = BSP.PeriphBBAlias + (STREAM_BASE + BSP.SxCR - BSP.PeriphBase + BSP.SxCR_EN DIV 8)*32 + BSP.SxCR_EN MOD 8*4;

    BLOCKSIZE = 512;

  TYPE
    SDCardInfoDesc = RECORD
      CardType, CardVersion, Class, RelCardAddr, BlockNbr, BlockSize, LogBlockNbr, LogBlockSize: INTEGER
    END;

  VAR Context: SET;

  PROCEDURE GetCmdResp1(cmd: SET): SET;
  VAR rc, reg: SET;
  BEGIN rc := SUCCESS;
    REPEAT SYSTEM.GET(STA, reg) UNTIL (reg*(BSP.CCRCFAILm + BSP.CMDRENDm + BSP.CTIMEOUTm) # {}) OR (reg*BSP.CMDACTm = {}); (*wait for response*)
    reg := reg*(BSP.CTIMEOUTm + BSP.CCRCFAILm);
    IF reg # {} THEN (*error*) rc := reg END;
    SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear all static flags*)
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

  PROCEDURE SDReadBlocksDMA*(ci: SDCardInfoDesc; pData, blockAdd, nofBlocks: INTEGER): SET;
    VAR rc, reg: SET;
  BEGIN rc := SUCCESS;
    IF nofBlocks < 1 THEN rc := INVALID_PARAMETER END;
    IF blockAdd + nofBlocks > ci.LogBlockNbr THEN rc := ADD_OUT_OF_RANGE END;
    IF rc = SUCCESS THEN
      (*Start DMA*)
      SYSTEM.PUT(DCTRL, 0); (*Initialize data control register*)
      SYSTEM.GET(MASK, reg); SYSTEM.PUT(MASK, reg + BSP.DCRCFAILm + BSP.DTIMEOUTm + BSP.RXOVERRm + BSP.DATAENDm + BSP.STBITERRm);
      (*SYSTEM.PUT(STREAM_BASE + BSP.SxPAR, FIFO); inutile de le faire a chaque fois *)
      SYSTEM.PUT(STREAM_BASE + BSP.SxNDTR, BLOCKSIZE*nofBlocks DIV 4);
      SYSTEM.PUT(STREAM_BASE + BSP.SxM0AR, pData);
      SYSTEM.PUT(BSP.DMA2_BASE + BSP.LIFCR, LSL(3DH, BSP.LI_OFS3)); (*Clear all DMA2 stream 3 interrupt flags*)
      SYSTEM.GET(STREAM_BASE + BSP.SxCR, reg);
      SYSTEM.PUT(STREAM_BASE + BSP.SxCR, reg + (BSP.SxCR_TCIEm + BSP.TEIEm + BSP.DMEIEm)); (*enable common interrupts*)
      SYSTEM.PUT(s3En, 1); (*don't use TRUE because this register must be accessed by words (32 bits)*)
      (*Start SDIO DMA transfer*)
      SYSTEM.PUT(BSP.sdioDmaEn, 1);
      IF ci.CardType # CARD_SDHC_SDXC THEN blockAdd := blockAdd*512 (*convert block to byte*) END;
      (* Configure the SD DPSM (Data Path State Machine *)
      SYSTEM.PUT(DTIMER, 0FFFFFFFFH); SYSTEM.PUT(DLEN, BLOCKSIZE*nofBlocks);
      SYSTEM.GET(DCTRL, reg); (*bs 512, card to host, block mode, enable data transfer*)
      SYSTEM.PUT(DCTRL, reg - DCTRL_CLEAR_MASK + SYSTEM.VAL(SET, LSL(9, 4)) + BSP.DTDIRm + BSP.DTENm);
      SYSTEM.PUT(ARG, blockAdd); SYSTEM.GET(CMD, reg);
      IF nofBlocks > 1 THEN 
        Context := READ_MULTIPLE_BLOCKS + CONTEXT_DMA;
        (*issue multiple blocks read command*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_READ_MULT_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm)
      ELSE
        Context := READ_SINGLE_BLOCK + CONTEXT_DMA;
        (*issue single block read command*)
        SYSTEM.PUT(CMD, reg - CMD_CLEAR_MASK + CMD_READ_SINGLE_BLOCK + BSP.RESPONSE_SHORT + BSP.CPSMENm)
      END;
      rc := GetCmdResp1(CMD_READ_MULT_BLOCK); (*check response*)
      IF rc # SUCCESS THEN
        SYSTEM.PUT(ICR, STATIC_CMD_FLAGS); (*clear all static flags*) Context := {}
      END
    END;

    RETURN rc
  END SDReadBlocksDMA;

END testSDCard.
