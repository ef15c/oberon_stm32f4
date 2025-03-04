MODULE BSP; (*CS 06.03.24 STM32F429I-DISCO Oberon base board abstraction*)
  IMPORT SYSTEM;

  CONST  MASK2* = {0..1}; MASK4* = {0..3};
    (*Cortex M4*)
    (*DWT*)
     DWTBase* = 0E0001000H;  DWT_CTRL* = 0; CYCCNT* = 4;
      CYCCNTENA* = 0;

    (*SCS_NVIC*)
    NVIC_ISER* = 0E000E100H; NVIC_ICER* = NVIC_ISER + 80H; NVIC_ISPR* = NVIC_ISER + 100H; NVIC_ICPR* = NVIC_ISER + 180H;
    NVIC_IABR* = NVIC_ISER + 200H; NVIC_IPR* = NVIC_ISER + 300H;  

    (*SCS_ACTLR*)
    ACTLR* = 0E000E008H;
      DISOOFP* = 9; DISFPCA* = 8; DISFOLD* = 2; DISDEFWBUF* = 1; DISMCYCINT* = 0;

    (*SCS_SysTick*)
    SYST_CSR* = 0E000E010H;
      COUNTFLAG* = 16; CLKSOURCE* = 2; TICKINT*= 1; SYST_ENABLE* = 0;
    SYST_RVR* = SYST_CSR + 4; SYST_CVR* = SYST_CSR + 8; SYST_CALIB* = SYST_CSR + 0CH;
      NOREF* = 31; SKEW* = 30; TENMSm* = {0..23};

    (*SCB*)
    SCB_BASE* =  0E000ED00H;
    ICSR* = 4;
      PENDSVSET* = 28;
    VTOR* = 8;
      TBLOFF* = {7..31};
    AIRCR*= 0CH;
      VECTKEY* = {13..31}; ENDIANNESS* = 15; PRIGROUP* = {8..10}; SYSTESETREQ* = 2; VECTCLRACTIVE* = 1; VECTRESET* = 1;
    CCR* = 14H;
      STKALIGN* = 9; BFHFNMIGN* = 8; DIV_0_TRP* = 4; UNALIGN_TRP* = 3; USESETMPEND* = 1; NONBASETHRDENA* = 0;
    SHPR1* = 18H;
    SHCSR* = 24H;
      USGFAULTENA* = 18; BUSFAULTENA* = 17; MEMFAULTENA* = 16; SVCALLPENDED* = 15; BUSFAULTPENDED* = 14; MEMFAULTPENDED* = 13;
      USGFAULTPENDED* = 12; SYSTICKACT* = 11; PENDSVACT* = 10; MONITOARACT* = 8; SVCALLACT* = 7; USGFAULTACT* = 3;
      BUSFAULTACT* = 1; MEMFAULTACT* = 0;
    CFSR* = 28H;
      UFSR_Mask* = {16..31}; BFSR_Mask* = {8..15};
      NOCP* = 19; INVSTATE* = 17; PRECISERR* = 9; STKERR* = 12;
    BFAR* = 38H;
    CPACR* = 88H;
      CP11m* = {22..23}; CP10m* = {20..21};
    DEMCR* = 0FCH;
      TRCENA* = 24;

   (*MPU*)
    MPU_BASE* = 0E000ED90H;
    TYPER* = 0; DREGIONm* = {8..15};
    MPU_CTRL* = 4; PRIVDEFENA* = 2; HFNMIENA* = 1; MPU_ENABLE* = 0;
    RNR* = 8; RNR_REGIONm* = {0..7};
    RBAR* = 0CH; MPU_ADDRm* = {5..31}; VALID* = 4; RBAR_REGIONm* = {0..3};
    RASR* = 10H; XN* = 28; RASR_ENABLE* = 0; SRD* = 8;
      APm* = {24..26}; TEXm* = {19..21}; S* = 18; C* = 17; B* = 16; SRDm* = {SRD..SRD+7}; SIZEm* = {1..5};
      AP_NO_ACCESS* = {}; AP_PRIV_RW* = {24}; AP_PRIV_RW_URO* = {25}; AP_FULL_ACCESS* = {24, 25};
      AP_PRIV_RO* = {24, 26}; AP_PRIV_RO_URO* = {25, 26};
      TEX_LEVEL0* = {}; TEX_LEVEL1* = {19}; TEX_LEVEL2* = {20}; 

    (*Memory*)
    SRAMBase* = 20000000H; VecTabBase* = SRAMBase;

    (*Peripherals*)
    PeriphBase* = 40000000H; PeriphBBAlias* = 42000000H;

    (*NVIC*)
    (*Cortex M4*)
    BusFaultExcNum* = 5; UsageFaultExcNum* = 6; SVCallExcNum* = 11; PendSVExcNum* = 14; SysTickExcNum* = 15;

    (*STM32F429*)

    (*IRQ numbers*)
    EXTI0_IRQNum* = 16+6; EXTI1_IRQNum* = 16+7; EXTI2_IRQNum* = 16+8; EXTI3_IRQNum* = 16+9; EXTI4_IRQNum* = 16+10;
    EXTI9_5_IRQNum* = 16+23; EXTI15_10_IRQNum* = 16+40; SDIO_IRQNum* = 16+49; DMA2_Stream3_IRQNum* = 16+59;
    DMA3_Stream6_IRQNum* = 16+69;

    (*FMC for SDRAM*)
    FMC_R_BASE* = 0A0000000H; FMC_Bank5_6_R_Base* = FMC_R_BASE + 140H;
    SDCR1* = 0; SDCR2* = 4;
      RPIPEm* = {13..14}; RBURST* = 12; SDCLKm* = {10..11}; WP* = 9; CASm* = {7..8}; NB* = 6; MWIDm* = {4..5}; NRm* = {2..3}; NCm* = {0..1};
      RPIPE_DELAY_0* = {}; RPIPE_DELAY_1* = {13}; RPIPE_DELAY_2* = {14}; 
      CLOCK_PERIOD_DISABLE* = {}; CLOCK_PERIOD_2* = {11}; CLOCK_PERIOD_3* = {10, 11};
      CAS_LATENCY_1* = {7}; CAS_LATENCY_2* = {8}; CAS_LATENCY_3* = {7, 8};
      MEM_BUS_WIDTH_8* = {}; MEM_BUS_WIDTH_16* = {4}; MEM_BUS_WIDTH_32* = {5};
      ROW_BITS_NUM_11* = {}; ROW_BITS_NUM_12* = {2}; ROW_BITS_NUM_13* = {3};
      COLUMN_BITS_NUM_8* = {}; COLUMN_BITS_NUM_9* = {0}; COLUMN_BITS_NUM_10* = {1}; COLUMN_BITS_NUM_11* = {0, 1};
    SDTR1* = 8; SDTR2* = 0CH;
      TRCD* = 24; TRP* = 20; TWR* = 16; TRC* = 12; TRAS* = 8; TXSR* = 4; TMRD* = 0;
      TRCDm* = {TRCD..TRCD+3}; TRPm* = {TRP..TRP+3}; TWRm* = {TWR..TWR+3}; TRCm* = {TRC..TRC+3}; 
        TRASm* = {TRAS..TRAS+3}; TXSRm* = {TXSR..TXSR+3}; TMRDm* = {TMRD..TMRD+3};
    SDCMR* = 10H;
      MRD* = 9; NRFS* = 5; CBT1* = 4; CBT2* = 3; MODEm* = {0..2};
      MRDm* = {MRD..MRD+12}; NRFSm* = {NRFS..NRFS+3}; 
      CMD_NORMAL_MODE* = {}; CMD_CLK_CONF_ENABLE* = SYSTEM.VAL(SET, 1); CMD_PALL* = SYSTEM.VAL(SET, 2);
      CMD_AUTOREFRESH_MODE* = SYSTEM.VAL(SET, 3); CMD_LOAD_MODE* = SYSTEM.VAL(SET, 4); CMD_SELFREFRESH_MODE* = SYSTEM.VAL(SET, 5);
      CMD_POWERDOWN_MODE* = SYSTEM.VAL(SET, 6);
    SDRTR* = 14H;
      REIE* = 0; COUNT* = 1; CRE* = 0;
     COUNTm* = {COUNT..COUNT+12};
    SDSR* = 18H;
      BUSY* = 5; MODES2* = 3; MODES1* = 1; RE* = 0;
      MODES2m* = {MODES2..MODES2+1}; MODES1m* = {MODES1..MODES1+1};
      SR_NORMAL_MODE* = {}; SR_SELFREFRESH_MODE* = {0}; SR_POWERDOWN_MODE* = {1};

    (*CRC*)
    CRC_BASE* = 40023000H;
    CRC_DR* = 0;
    CRC_IDR* = 4;

    CRC_CR* = 8; CRC_RESET* = 0;
    crcReset* = PeriphBBAlias + (CRC_BASE + CRC_CR - PeriphBase + CRC_RESET DIV 8)*32 + CRC_RESET MOD 8*4;

    (*DMA*)
    DMA1_BASE* = 40026000H; DMA2_BASE* = 40026400H;
    LISR* = 0; LIFCR* = 8; LI_OFS0* = 0; LI_OFS1* = 6; LI_OFS2* = 16; LI_OFS3* = 22;
    HISR* = 4; HIFCR* = 0CH; HI_OFS4* = 0; HI_OFS5* = 6; HI_OFS6* = 16; HI_OFS7* = 22;

    TCIFx* = 5; HTIFx* = 4; TEIFx* = 3; DMEIFx* = 2; FEIFx* = 0; STREAM_FLAGSm* = {TCIFx, HTIFx, TEIFx, DMEIFx, FEIFx};

    STREAM_PARAM_SIZE* = 18H;
    SxCR* = 10H; CHSEL* = 25; MBURST* = 23; PBURST* = 21; CT* = 19; DBM* = 18; PINCOS* = 15; MSIZE* = 13; PSIZE* = 11;
        MINC* = 10; PINC* = 9; CIRC* = 8; PFCTRL* = 5; SxCR_TCIE* = 4; HTIE* = 3;
       TEIE* = 2; DMEIE* = 1; SxCR_EN* = 0;
      CHSELm* = {CHSEL..CHSEL+2}; MBURSTm* = {23..24}; PBURSTm* = {21..22}; PLm* = {16..17}; MSIZEm* = {13..14}; DMA_PSIZEm* = {11..12};
      MINCm* = {MINC}; DIRm* = {6..7}; PFCTRLm* = {PFCTRL}; SxCR_TCIEm* = {SxCR_TCIE}; HTIEm* = {HTIE}; TEIEm* = {TEIE}; DMEIEm* = {DMEIE};

      SINGLE_TRANSFERT* = {}; INCR4* = {0}; INCR8* = {1}; INCR16* = {0, 1};
      SBYTE* = {}; SHALF_WORD* = {0}; SWORD* = {1};
      PERIPH_TO_MEMORY* = {}; MEMORY_TO_PERIPH* = {6}; MEMORY_TO_MEMORY* = {7};
 
    SxNDTR* = 14H; NDTm* = {0..15};
    SxPAR* = 18H; SxM0AR* = 1CH; SxM1AR* = 20H;
    SxFCR* = 24H; FEIE* = 7; DMDIS* = 2;
      FEIEm* = {FEIE}; FSm* = {3..5}; DMDISm* = {DMDIS}; FTHm* = {0..1};
      QUARTER_FULL_FIFO* = {}; HALF_FULL_FIFO* = {0}; THREE_QUARTER_FULL_FIFO* = {1}; FULL_FIFO* = {0, 1};

    (*EXTI*)
    EXTI_BASE* = 40013C00H; EXTI_IMR* = 0; EMR* = 4; RTSR* = 8; FTSR* = 0CH; SWIER* = 10H; PR* = 14H;

    (*FLASH*)
    FLASH_BASE* = 40023C00H;
    ACR* = 0;
      DCRST* = 12; ICRST* = 11; DCEN* = 10; ICEN* = 9; PRFTEN* = 8; LATENCYm* = {0..3};
    KEYR* = 4; OPT_KEYR* = 8; FLASH_SR* = 0CH;
      FLASH_BSY* = 16; RDERR* = 8; PGSERR* = 7; PGPERR* = 6; PGAERR* = 5; WRPERR* = 4; OPERR* = 1; EOP* = 0;
    FLASH_CR* = 10H;
      LOCK* = 31; ERRIE* = 25; EOPIE* = 24; STRT* = 16; MER1* = 15; FLASH_PSIZEm* = {8..9}; SNB* = 3; SNBm* = {SNB..SNB+4}; MER* = 2; SER* = 1; PG* = 0;
        PSIZE_X8* = {}; PSIZE_X16* = {8}; PSIZE_X32* = {9}; PSIZE_X64* = {8..9};
    OPTCR* = 14H;
      SPRMOD* = 31; DB1M* = 30; nWRP* = 16; nWRPm* = {nWRP..nWRP+11}; RDP* = 8; RDPm* = {RDP..RDP+7}; nRST_STDBY* = 7;
      nRST_STOP* = 6; WDG_SW* = 5; BFB2* = 4; BOR_LEV* = 2; BOR_LEVm* = {BOR_LEV..BOR_LEV+1}; OPTSTRT* = 1; OPTLOCK* = 0;
    OPTCR1* = 18H;
      nWRP1* = 16; nWRP1m* = {nWRP1..nWRP1+11};

    (*LTDC*)
    LTDC_BASE* = 40016800H; 
    SSCR* = 8; HSWm* = {16..27}; VSHm* = {0..10};
    BPCR* = 0CH; AHBPm* = {16..27}; AVBMm* = {0..10};
    ACWR* = 10H; AAWm* = {16..27}; AAHm* = {0..10};
    TWCR* = 14H; TOTALWm* = {16..27}; TOTALHm* = {0..10};

    GCR* = 18H; GCR_LTDCEN* = 0;
    HSPOLm* = {31}; VSPOLm* = {30}; DEPOLm* = {29}; PCPOLm* = {28}; DENm* = {16};
    DRWm* = {12..14}; DGWm* = {8..10}; DBWm* = {4..6}; GCR_LTDCENm* = {GCR_LTDCEN};
    gcr_ltdcEn* = PeriphBBAlias + (LTDC_BASE + GCR - PeriphBase + GCR_LTDCEN DIV 8)*32 + GCR_LTDCEN MOD 8*4;

    SRCR* = 24H; VBR* = 1; SRCR_IMR* = 0;
    vbr* = PeriphBBAlias + (LTDC_BASE + SRCR - PeriphBase + VBR DIV 8)*32 + VBR MOD 8*4;
    imr* = PeriphBBAlias + (LTDC_BASE + SRCR - PeriphBase + SRCR_IMR DIV 8)*32 + SRCR_IMR MOD 8*4;

    BCCR* = 2CH; BCREDm* = {16..23}; BCGREENm* = {8..15}; BCBLUEm* = {0..8};

    L0CR* = 84H; CLUTEN* = 4; COLKEN* = 1; LEN* = 0;
    CLUTENm* = {CLUTEN}; COLKENm* = {COLKEN}; LENm* = {LEN};
    l0En* = PeriphBBAlias + (LTDC_BASE + L0CR - PeriphBase + LEN DIV 8)*32 + LEN MOD 8*4;
    l0Cluten* = PeriphBBAlias + (LTDC_BASE + L0CR - PeriphBase + CLUTEN DIV 8)*32 + CLUTEN MOD 8*4;

    L0WHPCR* = 88H; WHSPPOSm* = {16..27}; WHSTPOSm* = {0..11};
    L0WVPCR* = 8CH; WVSPPOSm* = {16..26}; WVSTPOSm* = {0..10};
    L0PFCR* = 94H; PFm* = {0..2};
    L0CACR* = 98H; CONSTAm* = {0..7};
    L0DCCR* = 9CH; DCALPHAm* = {24..31}; DCREDm* = {16..23}; DCGREENm* = {8..15}; DCBLUEm* = {0..7};
    L0BFCR* = 0A0H; BF1m* = {8..10}; BF2m* = {0..2};
    L0CFBAR* = 0ACH;
    L0CFBLR* = 0B0H; CFBPm* = {16..28}; CFBLLm* = {0..12};
    L0CFBLNR* = 0B4H; CFBLNRm* = {0..10};
    L0CLUTWR* = 0C4H; CLUTADDm* = {24..31}; REDm* = {16..23}; GREEMm* = {8..15}; BLUEm* = {0..7};

    (*PWR*)
    PWR_BASE* = 40007000H;
    PWR_CR* = 0; DBP* = 8;
    dbp* = PeriphBBAlias + (PWR_BASE + PWR_CR - PeriphBase + DBP DIV 8)*32 + DBP MOD 8*4;

    (*RCC*)
    HCLKFreq* = 168; PCLK1Freq* = 42; PCLK2Freq* = 84;(*MHz*)

    RCC_BASE* = 40023800H;
    RCC_CR* = 0;
      PLLSAIRDY* = 29; PLLSAION* = 28; PLLI2SRDY* = 27; PLLI2SON* = 26; PLLRDY* = 25; PLLON* = 24; CSSON* = 19;
      HSEBYP* = 18; HSERDY* = 17; HSEON* = 16; HSICAL* = 8; HSITRIM* = 3; HSIRDY* = 1; HSION* = 0;
      HSICALm* = {HSICAL..HSICAL+7}; HSITRIMm* = {HSITRIM..HSITRIM+4};
    pllsaiEn* = PeriphBBAlias + (RCC_BASE + RCC_CR - PeriphBase + PLLSAION DIV 8)*32 + PLLSAION MOD 8*4;
    hseOn* = PeriphBBAlias + (RCC_BASE + RCC_CR - PeriphBase + HSEON DIV 8)*32 + HSEON MOD 8*4;
    pllOn* = PeriphBBAlias + (RCC_BASE + RCC_CR - PeriphBase + PLLON DIV 8)*32 + PLLON MOD 8*4;

    PLLCFGR* = 4;
      PLLQ* = 24; PLLSCR* = 22; PLLP* = 16; PLLN* = 6; PLLM* = 0;
      PLLQm* = {PLLQ..PLLQ+3}; (*0, 1: wrong configuration*) PLLPm* = {PLLP..PLLP+1}; (*PLLP in {2, 4, 6, 8}, field encoded as PLLP DIV 2-1*)
      PLLNm* = {PLLN..PLLN+8}; (*PLLN in {50..432}*) PLLMM* = {PLLM..PLLM+5}; (*PLLM in {2..63}*)

    CFGR* = 8; (*clock configuration register*)
      PPRE2* = 13; PPRE1* = 10; HPRE* = 4;
      MCO2m* = {30..31}; MCO2PREm* = {23..29}; MCO1PREm* = {24..26}; I2SSRC* = 23; MCO1m* = {21..22};
      RTCPREm* = {16..20}; PPRE2m* = {PPRE2..PPRE2+2}; PPRE1m* = {PPRE1..PPRE1+2}; HPREm* = {HPRE..HPRE+3}; SWSm* = {2..3}; SWm* = {0..1};
      HCLK_DIV1* = {}; HCLK_DIV2* = {2}; HCLK_DIV4* = {2, 0}; HCLK_DIV8* = {2, 1};HCLK_DIV16* = {2, 1, 0}; 

    AHB1ENR* = 30H; CRCEN* = 12; GPIOAEN* = 0; GPIOBEN* = 1; GPIOCEN* = 2; GPIODEN* = 3; GPIOEEN* = 4; GPIOFEN* = 5;
      GPIOGEN* = 6; GPIOHEN* = 7; GPIOIEN* = 8; GPIOJEN* = 9; GPIOKEN* = 10; DMA1EN* = 21; DMA2EN* = 22;
    crcEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + CRCEN DIV 8)*32 + CRCEN MOD 8*4;
    gpioaEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOAEN DIV 8)*32 + GPIOAEN MOD 8*4;
    gpiobEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOBEN DIV 8)*32 + GPIOBEN MOD 8*4;
    gpiocEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOCEN DIV 8)*32 + GPIOCEN MOD 8*4;
    gpiodEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIODEN DIV 8)*32 + GPIODEN MOD 8*4;
    gpioeEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOEEN DIV 8)*32 + GPIOEEN MOD 8*4;
    gpiofEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOFEN DIV 8)*32 + GPIOFEN MOD 8*4;
    gpiogEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOGEN DIV 8)*32 + GPIOGEN MOD 8*4;
    gpiohEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOHEN DIV 8)*32 + GPIOHEN MOD 8*4;
    gpioiEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOIEN DIV 8)*32 + GPIOIEN MOD 8*4;
    gpiojEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOJEN DIV 8)*32 + GPIOJEN MOD 8*4;
    gpiokEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + GPIOKEN DIV 8)*32 + GPIOKEN MOD 8*4;
    dma1En* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + DMA1EN DIV 8)*32 + DMA1EN MOD 8*4;
    dma2En* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + DMA2EN DIV 8)*32 + DMA2EN MOD 8*4;

    AHB3ENR* = 38H; FMCEN* = 0;

    APB1ENR* = 40H; SPI3EN* = 15; PWREN* = 28; (*APB1 peripheral clock enable register*)
    pwrEn* = PeriphBBAlias + (RCC_BASE + APB1ENR - PeriphBase + PWREN DIV 8)*32 + PWREN MOD 8*4;
    spi3En* = PeriphBBAlias + (RCC_BASE + APB1ENR - PeriphBase + SPI3EN DIV 8)*32 + SPI3EN MOD 8*4;

    APB2ENR* = 44H; USART1EN* = 4; APB2ENR_SDIOEN* = 11; APB2ENR_LTDCEN* = 26; SYSCFGEN* = 14;
    usart1En* = PeriphBBAlias + (RCC_BASE + APB2ENR - PeriphBase + USART1EN DIV 8)*32 + USART1EN MOD 8*4;
    sdioEn* = PeriphBBAlias + (RCC_BASE + APB2ENR - PeriphBase + APB2ENR_SDIOEN DIV 8)*32 + APB2ENR_SDIOEN MOD 8*4;
    rcc_ltdcEn* = PeriphBBAlias + (RCC_BASE + APB2ENR - PeriphBase + APB2ENR_LTDCEN DIV 8)*32 + APB2ENR_LTDCEN MOD 8*4;
    syscfgEn* = PeriphBBAlias + (RCC_BASE + APB2ENR - PeriphBase + SYSCFGEN DIV 8)*32 + SYSCFGEN MOD 8*4;

    BDCR* = 70H; RTCEN* = 15; BDRST* = 16; RTCSEL* = {8..9}; (*backup domain control register*)
    rtcEn* = PeriphBBAlias + (RCC_BASE + BDCR - PeriphBase + RTCEN DIV 8)*32 + RTCEN MOD 8*4;
    bdRst* = PeriphBBAlias + (RCC_BASE + BDCR - PeriphBase + BDRST DIV 8)*32 + BDRST MOD 8*4;

    PLLSAICFGR* = 88H; PLLSAIRm* = {28..30}; PLLSAIQm* = {24..27}; PLLSAINm* = {6..14};
    DCKCFGR* = 8CH; TIMPREm* = {24}; SAI1BSRCm* = {22..23}; SAI1ASRCm* = {20..21}; PLLSAIDIVRm* = {16..17};
      PLLSAIDIVQm* = {8..12}; PLLS2DIVQm* = {0..4};

    (*RTC*)
    RTC_BASE* =  40002800H; 
    TR* = 0; RTC_DR* = 4; RTC_CR* = 8; PRER* = 10H; SSR* = 28H; WPR* = 24H;

    ISR* = 0CH; INIT* = 7; INITF* = 6; RSF* = 5;(*flags*)
    rtcInit* = PeriphBBAlias + (RTC_BASE + ISR - PeriphBase + INIT DIV 8)*32 + INIT MOD 8*4;

    (*SDIO*)
    SDIO_BASE* = 40012C00H;
    POWER* = 0; PWRCTRLm* = {0..1}; POWER_OFF* = {}; POWER_ON* = {0,1};

    CLKCR* = 4; HWFC_EN* = 14; NEGEDGE* = 13; BYPASS* = 10; PWRSAV* = 9; CLKEN* = 8;
      WIDBUSm* = {11..12}; WIDE_1B* = {}; WIDE_4B* = {11}; WIDE_8B* = {12};
      CLKDIVm* = {0..7}; INIT_CLK_DIV* = 76H (*400kHz*); TRANSFER_CLK_DIV* = 0 (*24MHz*);
    sdioClkEn* =PeriphBBAlias + (SDIO_BASE + CLKCR - PeriphBase + CLKEN DIV 8)*32 + CLKEN MOD 8*4;

    ARG* = 8;

    CMD* = 0CH; RESPCMD* = 10H;
      ATACMDm* = {14}; nIENm* = {13}; ENCMDcomplm* = {12}; SDIOSuspendm* = {11}; CPSMENm* = {10}; WAITPENDm* = {9};
      WAITINTm* = {8}; WAITRESPm* = {6..7}; CMDINDEXm* = {0..5};
      RESPONSE_SHORT* = {6}; RESPONSE_LONG* = {6..7};

    RESP1* = 14H; DTIMER* = 24H; DLEN* = 28H;

    DCTRL* = 2CH; DCTRL_SDIOEN* = 11; RWMOD* = 10; RWSTOP* = 9; RWSTART* = 8; DMAEN* = 3; DTMODE* = 2; DTDIR* = 1; DTEN* = 0;
      DBLOCKSIZEm* = {4..7}; DMAENm* = {DMAEN}; DTMODEm* = {DTMODE}; DTDIRm* = {DTDIR}; DTENm* = {DTEN};
      DATABLOCK_SIZE_1B* = {}; DATABLOCK_SIZE_2B* = {4}; DATABLOCK_SIZE_4B* = {5}; DATABLOCK_SIZE_8B* = {4, 5};
      DATABLOCK_SIZE_16B* = {6}; DATABLOCK_SIZE_32B* = {4, 6}; DATABLOCK_SIZE_64B* = {5, 6}; DATABLOCK_SIZE_128B* = {4, 5, 6};
      DATABLOCK_SIZE_256B* = {7}; DATABLOCK_SIZE_512B* = {4, 7}; DATABLOCK_SIZE_1024B* = {5, 7}; DATABLOCK_SIZE_2048B* = {4, 5, 7};
      DATABLOCK_SIZE_4096B* = {6, 7}; DATABLOCK_SIZE_8192B* = {4, 6, 7}; DATABLOCK_SIZE_16384B* = {5, 6, 7};
    sdioDmaEn* = PeriphBBAlias + (SDIO_BASE + DCTRL - PeriphBase + DMAEN DIV 8)*32 + DMAEN MOD 8*4;

    STA* = 34H; ICR* = 38H;
      CCRCFAIL* = 0; DCRCFAIL* = 1; CTIMEOUT* = 2; DTIMEOUT* = 3; TXUNDERR* = 4; RXOVERR* = 5; CMDREND* = 6; CMDSENT* = 7;
      DATAEND* = 8; STBITERR* = 9; TXDAVL* = 20; RXDAVL* = 21;
      CEDATAENDm* = {23}; SDIOITm* = {22}; RXDAVLm* = {RXDAVL}; TXDAVLm* = {TXDAVL}; RXFIFOEm* = {19}; TXFIFOEm* = {18}; RXFIFOFm* = {17};
      TXFIFOFm* = {16}; RXFIFOHFm*= {15}; TXFIFOHEm* = {14}; RXACTm* = {13}; TXACTm* = {12}; CMDACTm* = {11}; DBCKENDm* = {10};
      STBITERRm* = {STBITERR}; DATAENDm* = {DATAEND}; CMDSENTm* = {CMDSENT}; CMDRENDm* = {CMDREND}; RXOVERRm* = {RXOVERR}; 
      TXUNDERRm* = {TXUNDERR}; DTIMEOUTm* = {DTIMEOUT}; CTIMEOUTm* = {CTIMEOUT}; DCRCFAILm* = {DCRCFAIL}; CCRCFAILm* = {CCRCFAIL};

    MASK* = 3CH; FIFO* = 80H;

    (*SPI*)
    SPI2_BASE* = 40003800; SPI3_BASE* = 40003C00H;
    SPI_CR1* = 0; SPE* = 6;
    SPI_CPHAm* = {0}; SPI_CPOLm* = {1};  MSTRm* = {2}; BRm* = {3..5}; SPEm* = {SPE}; LSBFIRSTm* = {7}; SSIm* = {8}; SSMm* = {9};
    RXONLYm* = {10}; DFFm* = {11}; CRCNEXTm* = {12}; CECENm* = {13}; BIDIOEm* = {14}; BIDIMODEm* = {15};
    BRPS_2* = {}; BRPS_4* = {3}; BRPS_8* = {4}; BRPS_16* = {3,4}; BRPS_32* = {5}; BRPS_64* = {3,5}; BRPS_128* = {4,5}; BRPS_256* = {3..5};
    spe3* = PeriphBBAlias + (SPI3_BASE +SPI_CR1 - PeriphBase + SPE DIV 8)*32 + SPE MOD 8*4;

    SPI_CR2* = 4;

    I2SCFGR* = 1CH; I2SMOD* = 11;
    i2smod3* = PeriphBBAlias + (SPI3_BASE + I2SCFGR - PeriphBase + I2SMOD DIV 8)*32 + I2SMOD MOD 8*4;

    SPI_SR* = 08H; SPI_RXNE* = 0; SPI_TXE* = 1; SPI_BSY* = 7;

    SPI_DR* = 0CH;

    (*SYSCFG*)
    SYSCFG_BASE* = 40013800H; EXTI_CR1* = 8;

    (*USART*)
    USART1_BASE* = 40011000H;
    USART_SR* = 0; USART_TXE* = 7; USART_RXNE* = 5;

    USART_DR* = 4;

    USART_BRR* = 8; DIV_Mantissa* = {4..15}; DIV_Fraction* = {0..3};

    USART_CR1* = 0CH; UE* = 13;
    OVER8m* = {15}; UEm* = {UE}; Mm* = {12}; WAKEm* = {11}; PCEm* = {10}; PSm* = {9}; PEIEm* = {8}; TXEIEm* = {7}; USART_TCIEm* = {6};
      RXNEIEm* = {5}; IDLEIEm* = {4}; TEm* = {3}; REm* = {2}; RWUm* = {1}; SBKm* = {0};
    ue1 = PeriphBBAlias + (USART1_BASE + USART_CR1 - PeriphBase + UE DIV 8)*32 + UE MOD 8*4;

    USART_CR2* = 10H; LINENm* = {14}; STOPm* = {12..13}; CLKENm* = {11}; USART_CPOLm* = {10}; USART_CPHAm* = {9}; LBCLm* = {8}; LBDIEm* = {6};
      HALFSTOPBIT* = {12}; TWOSTOPBITS* = {13}; ONEANDHALFSTOPBIT* = {12..13};
      LBDLm* = {5}; ADDm* = {0..3};

    USART_CR3* = 14H; ONEBITm* = {11}; CTSIEm* = {10}; CTSEm* = {9}; RTSEm* = {8}; DMATm* = {7}; DMARm* = {6}; SCENm* = {5};
      NACKm* = {4}; HDSELm* = {3}; IRLPm* = {2}; IRENm* = {1}; EIEm* = {0};

    (*GPIOs*)    
    GPIOA* = 40020000H; GPIOB* = 40020400H; GPIOC* = 40020800H; GPIOD* = 40020C00H; 
    GPIOE* = 40021000H; GPIOF* = 40021400H; GPIOG* = 40021800H; GPIOH* = 40021C00H;
    GPIOI* = 40022000H; GPIOJ* = 40022400H; GPIOK* = 40022800H;
    MODER* = 0; OTYPER* = 4; OSPEEDR* = 8; PUPDR* = 0CH; IDR* = 10H; ODR* = 14H; BSRR* = 18H; AFRL* = 20H; AFRH* = 24H;
    INPUT_MODE* = {}; OUTPUT_MODE* = {0}; AF_MODE* = {1}; ANALOG_MODE* = {0..1};
    LOW_SPEED* = {}; MEDIUM_SPEED* = {0}; HIGH_SPEED* = {1}; VERY_HIGH_SPEED* = {0..1};
    NO_PULL* = {}; PULL_UP* = {0}; PULL_DOWN* = {1};

    (*base board push buttons*)
    PB1Pin* = 14; PB1Port* = GPIOC;
    PB1In* = PeriphBBAlias + (PB1Port + IDR - PeriphBase + PB1Pin DIV 8)*32 + PB1Pin MOD 8*4;
    PB2Pin* = 15; PB2Port* = GPIOC;
    PB2In* = PeriphBBAlias + (PB2Port + IDR - PeriphBase + PB2Pin DIV 8)*32 + PB2Pin MOD 8*4;
    PB3Pin* =  6; PB3Port*  = GPIOE;
    PB3In* = PeriphBBAlias + (PB3Port + IDR - PeriphBase + PB3Pin DIV 8)*32 + PB3Pin MOD 8*4;
    PB4Pin* = 13; PB4Port* = GPIOC;
    PB4In* = PeriphBBAlias + (PB4Port + IDR - PeriphBase + PB4Pin DIV 8)*32 + PB4Pin MOD 8*4;
    PB5Pin* = 2; PB5Port* = GPIOG;
    PB5In* = PeriphBBAlias + (PB5Port + IDR - PeriphBase + PB5Pin DIV 8)*32 + PB5Pin MOD 8*4;
    PB6Pin* = 6; PB6Port* = GPIOF;
    PB6In* = PeriphBBAlias + (PB6Port + IDR - PeriphBase + PB6Pin DIV 8)*32 + PB6Pin MOD 8*4;
    PB7Pin* = 8; PB7Port* = GPIOF;
    PB7In* = PeriphBBAlias + (PB7Port + IDR - PeriphBase + PB7Pin DIV 8)*32 + PB7Pin MOD 8*4;
    PB8Pin* = 7; PB8Port* = GPIOF;
    PB8In* = PeriphBBAlias + (PB8Port + IDR - PeriphBase + PB8Pin DIV 8)*32 + PB8Pin MOD 8*4;

    (*base board LEDs*)
    LED1Pin* = 9; LED1Port* = GPIOF;
    LED1Out* = PeriphBBAlias + (LED1Port + ODR - PeriphBase + LED1Pin DIV 8)*32 + LED1Pin MOD 8*4;
    LED2Pin* = 3; LED2Port* = GPIOC;
    LED2Out* = PeriphBBAlias + (LED2Port + ODR - PeriphBase + LED2Pin DIV 8)*32 + LED2Pin MOD 8*4;
    LED3Pin* = 5; LED3Port* = GPIOA;
    LED3Out* = PeriphBBAlias + (LED3Port + ODR - PeriphBase + LED3Pin DIV 8)*32 + LED3Pin MOD 8*4;
    LED4Pin* = 7; LED4Port* = GPIOA;
    LED4Out* = PeriphBBAlias + (LED4Port + ODR - PeriphBase + LED4Pin DIV 8)*32 + LED4Pin MOD 8*4;
    LED5Pin* = 13; LED5Port* = GPIOD;
    LED5Out* = PeriphBBAlias + (LED5Port + ODR - PeriphBase + LED5Pin DIV 8)*32 + LED5Pin MOD 8*4;
    LED6Pin* = 12; LED6Port* = GPIOD;
    LED6Out* = PeriphBBAlias + (LED6Port + ODR - PeriphBase + LED6Pin DIV 8)*32 + LED6Pin MOD 8*4;
    LED7Pin* = 3; LED7Port* = GPIOG;
    LED7Out* = PeriphBBAlias + (LED7Port + ODR - PeriphBase + LED7Pin DIV 8)*32 + LED7Pin MOD 8*4;

    (*discovery board push button*)
    B1Pin* = 0; B1Port* = GPIOA; B1ExtiIrqNum* = EXTI0_IRQNum;
    (*discovery board LEDs*)
    LD3Pin* = 13; LD3Port* = GPIOG;
    LD3Out* = PeriphBBAlias + (LD3Port + ODR - PeriphBase + LD3Pin DIV 8)*32 + LD3Pin MOD 8*4;
    LD4Pin* = 14; LD4Port* = GPIOG;
    LD4Out* = PeriphBBAlias + (LD4Port + ODR - PeriphBase + LD4Pin DIV 8)*32 + LD4Pin MOD 8*4;

    (*PS/2 pins*)
    PS2CLOCK1Pin* = 2; PS2CLOCK1Port* = GPIOE; PS2CLOCK1ExtiIrqNum* =  EXTI2_IRQNum;
    PS2CLOCK1In* = PeriphBBAlias + (PS2CLOCK1Port + IDR - PeriphBase + PS2CLOCK1Pin DIV 8)*32 + PS2CLOCK1Pin MOD 8*4;
    PS2CLOCK1Out* = PeriphBBAlias + (PS2CLOCK1Port + ODR - PeriphBase + PS2CLOCK1Pin DIV 8)*32 + PS2CLOCK1Pin MOD 8*4;
    PS2DATA1Pin* = 3; PS2DATA1Port* =  GPIOE;
    PS2DATA1In* = PeriphBBAlias + (PS2DATA1Port + IDR - PeriphBase + PS2DATA1Pin DIV 8)*32 + PS2DATA1Pin MOD 8*4;
    PS2DATA1Out* = PeriphBBAlias + (PS2DATA1Port + ODR - PeriphBase + PS2DATA1Pin DIV 8)*32 + PS2DATA1Pin MOD 8*4;
    PS2CLOCK2Pin* = 4; PS2CLOCK2Port* = GPIOE; PS2CLOCK2ExtiIrqNum* =  EXTI4_IRQNum;
    PS2CLOCK2In* = PeriphBBAlias + (PS2CLOCK2Port + IDR - PeriphBase + PS2CLOCK2Pin DIV 8)*32 + PS2CLOCK2Pin MOD 8*4;
    PS2CLOCK2Out* = PeriphBBAlias + (PS2CLOCK2Port + ODR - PeriphBase + PS2CLOCK2Pin DIV 8)*32 + PS2CLOCK2Pin MOD 8*4;
    PS2DATA2Pin* = 5; PS2DATA2Port* =  GPIOE;
    PS2DATA2In* = PeriphBBAlias + (PS2DATA2Port + IDR - PeriphBase + PS2DATA2Pin DIV 8)*32 + PS2DATA2Pin MOD 8*4;
    PS2DATA2Out* = PeriphBBAlias + (PS2DATA2Port + ODR - PeriphBase + PS2DATA2Pin DIV 8)*32 + PS2DATA2Pin MOD 8*4;

    (*SD card pins*)
    WRITE_PROTECTPin* = 4; WRITE_PROTECTPort* = GPIOD;
    WRITE_PROTECTin* = PeriphBBAlias + (WRITE_PROTECTPort + IDR - PeriphBase + WRITE_PROTECTPin DIV 8)*32 + WRITE_PROTECTPin MOD 8*4;
    CARD_DETECTPin* = 5; CARD_DETECTPort* = GPIOD;
    CARD_DETECTin* = PeriphBBAlias + (CARD_DETECTPort + IDR - PeriphBase + CARD_DETECTPin DIV 8)*32 + CARD_DETECTPin MOD 8*4;

    (*nRF24L01+ pins*)
    NRF24L01P_MOSIPin* = 6; NRF24L01P_MOSIPort* = GPIOD;
    NRF24L01P_IRQPin* = 7; NRF24L01P_IRQPort* = GPIOD;
    NRF24L01P_CEPin* = 9; NRF24L01P_CEPort* = GPIOG;
    NRF24L01P_CEOut* = PeriphBBAlias + (NRF24L01P_CEPort + ODR - PeriphBase + NRF24L01P_CEPin DIV 8)*32 + NRF24L01P_CEPin MOD 8*4;
    NRF24L01P_SCKPin* = 3; NRF24L01P_SCKPort* = GPIOB;
    NRF24L01P_MISOPin* = 4; NRF24L01P_MISOPort* = GPIOB;
    NRF24L01P_CSPin* = 7; NRF24L01P_CSPort* =  GPIOB;
    NRF24L01P_CSOut* = PeriphBBAlias + (NRF24L01P_CSPort + ODR - PeriphBase + NRF24L01P_CSPin DIV 8)*32 + NRF24L01P_CSPin MOD 8*4;

    (*UART pins*)
    UART_RXPin* = 10; UART_RXPort* = GPIOA;
    UART_TXPin* = 9; UART_TXProt* = GPIOA;

    (*nRF24L01+*)
    NRF24L01P_spi* = SPI3_BASE; NRF24L01P_spiEnable* = spe3;

    (*UART*)
    UART_BASE* = USART1_BASE;

    (*Display*)
    Display_Width* = 1366; Display_Height* = 768; Display_BPP* = 8;
    Display_FBA* = 0D0000000H;

    Display_Pitch* = (Display_Width*8 DIV Display_BPP+63) DIV 64*64;

  VAR Leds*: ARRAY 7 OF INTEGER;

  PROCEDURE Delayus*(d: INTEGER);
    VAR beg, now: INTEGER;
  BEGIN SYSTEM.GET(DWTBase + CYCCNT, beg);
    REPEAT SYSTEM.GET(DWTBase + CYCCNT, now) UNTIL now - beg >= HCLKFreq*d
  END  Delayus;


  PROCEDURE led*(n: INTEGER);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 6 DO SYSTEM.PUT(Leds[i], ODD(n)); n := n DIV 2 END
  END led;

  PROCEDURE ledsOnOff*(on, off: SET);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 6 DO 
      IF i IN on THEN SYSTEM.PUT(Leds[i], TRUE) ELSIF i IN off THEN SYSTEM.PUT(Leds[i], FALSE) END
    END
  END ledsOnOff;

  PROCEDURE configureGPIO(port: INTEGER; m1b, m2b, m4bl, m4bh, m, os, ot, pup, afrl, afrh: SET);
    VAR reg: SET;
  BEGIN
    SYSTEM.GET(port + OSPEEDR, reg); SYSTEM.PUT(port + OSPEEDR, reg - m2b + os);
    SYSTEM.GET(port + OTYPER, reg); SYSTEM.PUT(port + OTYPER, reg - m1b + ot);
    SYSTEM.GET(port + PUPDR, reg); SYSTEM.PUT(port + PUPDR, reg - m2b + pup);
    SYSTEM.GET(port + AFRL, reg); SYSTEM.PUT(port + AFRL, reg - m4bl + afrl);
    SYSTEM.GET(port + AFRH, reg); SYSTEM.PUT(port + AFRH, reg - m4bh + afrh);
    SYSTEM.GET(port + MODER, reg); SYSTEM.PUT(port + MODER, reg - m2b + m)
  END configureGPIO;

  PROCEDURE PS2_initGPIOs; (*PS/2*)
    CONST mask_1b = {PS2CLOCK1Pin, PS2DATA1Pin, PS2CLOCK2Pin, PS2DATA2Pin};
      mask_2b = LSL(MASK2, PS2CLOCK1Pin*2) + LSL(MASK2, PS2DATA1Pin*2) + LSL(MASK2, PS2CLOCK2Pin*2) + LSL(MASK2, PS2DATA2Pin*2);
      od = mask_1b;
      om = LSL(OUTPUT_MODE, PS2CLOCK1Pin*2) + LSL(OUTPUT_MODE, PS2DATA1Pin*2) +
        LSL(OUTPUT_MODE, PS2CLOCK2Pin*2) + LSL(OUTPUT_MODE, PS2DATA2Pin*2);
    VAR en: BYTE; reg: SET;
  BEGIN SYSTEM.PUT(gpioeEn, TRUE); SYSTEM.GET(gpioeEn, en); (*delay*)
    configureGPIO(GPIOE, mask_1b, mask_2b, {}, {}, om, {}, od, {}, {}, {}); (*all pins are output, low speed, open-drain, no pullups nor pulldowns*)
    SYSTEM.GET(SYSCFG_BASE + EXTI_CR1, reg); (*PE2 generates interrupt at falldown*)
    SYSTEM.PUT(SYSCFG_BASE + EXTI_CR1, reg - {8..11} + LSL(SYSTEM.VAL(SET, 4), 8)); (*EXTI 2 connected to GPIOE*)
    SYSTEM.GET(SYSCFG_BASE + EXTI_CR1+4, reg); (*PE4 generates interrupt at falldown*)
    SYSTEM.PUT(SYSCFG_BASE + EXTI_CR1+4, reg - {0..3} + SYSTEM.VAL(SET, 4)); (*EXTI 2 connected to GPIOE*)
    SYSTEM.GET(EXTI_BASE + FTSR, reg); SYSTEM.PUT(EXTI_BASE + FTSR, reg + {2, 4});
    SYSTEM.GET(EXTI_BASE + EXTI_IMR, reg); SYSTEM.PUT(EXTI_BASE + EXTI_IMR, reg + {2, 4})
  END PS2_initGPIOs;

  PROCEDURE NRF_initGPIOs; (*nrf24L01+*)
    CONST
      maskB_1b = {NRF24L01P_SCKPin, NRF24L01P_MISOPin, NRF24L01P_CSPin};
      maskB_2b = LSL(MASK2, NRF24L01P_SCKPin*2) + LSL(MASK2, NRF24L01P_MISOPin*2) + LSL(MASK2, NRF24L01P_CSPin*2);
      maskB_4bl = LSL(MASK4, NRF24L01P_SCKPin*4) + LSL(MASK4, NRF24L01P_MISOPin*4) + LSL(MASK4, NRF24L01P_CSPin*4);
      maskD_1b = {NRF24L01P_MOSIPin, NRF24L01P_IRQPin};
      maskD_2b = LSL(MASK2, NRF24L01P_MOSIPin*2) + LSL(MASK2, NRF24L01P_IRQPin*2);
      maskD_4bl = LSL(MASK4, NRF24L01P_MOSIPin*4) + LSL(MASK4, NRF24L01P_IRQPin*4);
      maskG_1b = {NRF24L01P_CEPin};
      maskG_2b = LSL(MASK2, NRF24L01P_CEPin*2);
      maskG_4bh = LSL(MASK4, NRF24L01P_CEPin MOD 8*4);
    VAR en: BYTE; reg: SET;
  BEGIN SYSTEM.GET(RCC_BASE + AHB1ENR, reg); SYSTEM.PUT(RCC_BASE + AHB1ENR, reg + {GPIOBEN, GPIODEN, GPIOGEN});
    SYSTEM.GET(RCC_BASE + AHB1ENR, reg);  (*delay*)
    (*GPIO*)
    SYSTEM.PUT(NRF24L01P_CSOut, 1); (*unselect NRF24L01+ peripheral*);
    (*SPI3*)
    configureGPIO(GPIOB, maskB_1b, maskB_2b, maskB_4bl, {},
      LSL(AF_MODE, NRF24L01P_SCKPin*2) + LSL(AF_MODE, NRF24L01P_MISOPin*2) + LSL(OUTPUT_MODE, NRF24L01P_CSPin*2),
      LSL(MEDIUM_SPEED, NRF24L01P_SCKPin*2) + LSL(MEDIUM_SPEED, NRF24L01P_MISOPin*2), {}, {},
      LSL(SYSTEM.VAL(SET, 6), NRF24L01P_SCKPin*4) + LSL(SYSTEM.VAL(SET, 6), NRF24L01P_MISOPin*4) (*AF6*), {});
    configureGPIO(GPIOD, maskD_1b, maskD_2b, maskD_4bl, {},
      LSL(AF_MODE, NRF24L01P_MOSIPin*2),
      LSL(MEDIUM_SPEED, NRF24L01P_MOSIPin*2), {}, {},
      LSL(SYSTEM.VAL(SET, 5), NRF24L01P_MOSIPin*4), {}); (*AF5: MOSI*)
    configureGPIO(GPIOG, maskG_1b, maskG_2b, {}, maskG_4bh,
      LSL(OUTPUT_MODE, NRF24L01P_CEPin*2), {}, {}, {}, {}, {});
  END NRF_initGPIOs;

  PROCEDURE UART_initGPIOs;
    CONST
      mask_1b = {UART_RXPin, UART_TXPin};
      mask_2b = LSL(MASK2, UART_RXPin*2) + LSL(MASK2, UART_TXPin*2);
      mask_4b = LSL(MASK4, UART_RXPin MOD 8*4) + LSL(MASK4, UART_TXPin MOD 8*4);
      af =  LSL(SYSTEM.VAL(SET, 7), UART_RXPin MOD 8*4) + LSL(SYSTEM.VAL(SET, 7), UART_TXPin MOD 8*4); (*AF7*)
      afm = LSL(AF_MODE, UART_RXPin*2) + LSL(AF_MODE, UART_TXPin*2);
    VAR en: BYTE;
  BEGIN SYSTEM.PUT(gpioaEn, TRUE); SYSTEM.GET(gpioaEn, en); (*delay*)
    configureGPIO(GPIOA, mask_1b, mask_2b, {}, mask_4b, afm, {}, {}, {}, {}, af);
  END UART_initGPIOs;

  PROCEDURE Display_InitGPIOs;
    CONST
      maskA_1b = {3, 4, 6, 11, 12};
      maskA_2b = LSL(MASK2, 3*2) + LSL(MASK2, 4*2) + LSL(MASK2, 6*2) + LSL(MASK2, 11*2) + LSL(MASK2, 12*2);
      maskA_4bl = LSL(MASK4, 3*4) + LSL(MASK4, 4*4) + LSL(MASK4, 6*4);
      maskA_4bh = LSL(MASK4, 11 MOD 8*4) + LSL(MASK4, 12 MOD 8*4);
      maskB_1b = {0, 1, 8, 9, 10, 11};
      maskB_2b = LSL(MASK2, 0*2) + LSL(MASK2, 1*2) + LSL(MASK2, 8*2) + LSL(MASK2, 9*2) + LSL(MASK2, 10*2) + LSL(MASK2, 11*2);
      maskB_4bl = LSL(MASK4, 0*4) + LSL(MASK4, 1*4);
      maskB_4bh =  LSL(MASK4, 8 MOD 8*4) + LSL(MASK4, 9 MOD 8*4) + LSL(MASK4, 10 MOD 8*4) + LSL(MASK4, 11 MOD 8*4);
      maskC_1b = {6, 7};
      maskC_2b =  LSL(MASK2, 6*2) + LSL(MASK2, 7*2);
      maskC_4bl = LSL(MASK4, 6*4) + LSL(MASK4, 7*4);
      maskG_1b = {6, 10, 11, 12};
      maskG_2b = LSL(MASK2, 6*2) + LSL(MASK2, 10*2) + LSL(MASK2, 11*2) + LSL(MASK2, 12*2);
      maskG_4bl = LSL(MASK4, 6*4);
      maskG_4bh = LSL(MASK4, 10 MOD 8*4) + LSL(MASK4, 11 MOD 8*4) + LSL(MASK4, 12 MOD 8*4);
    VAR reg: SET;
  BEGIN SYSTEM.GET(RCC_BASE + AHB1ENR, reg); SYSTEM.PUT(RCC_BASE + AHB1ENR, reg + {GPIOAEN, GPIOBEN, GPIOCEN, GPIODEN, GPIOGEN});
    SYSTEM.GET(RCC_BASE + AHB1ENR, reg); (*delay*)
    (**LTDC GPIO Configuration
    PA3     ------> LTDC_B5
    PA4     ------> LTDC_VSYNC
    PA6     ------> LTDC_G2
    PA11     ------> LTDC_R4
    PA12     ------> LTDC_R5
    PB0     ------> LTDC_R3
    PB1     ------> LTDC_R6
    PB8     ------> LTDC_B6
    PB9     ------> LTDC_B7
    PB10     ------> LTDC_G4
    PB11     ------> LTDC_G5
    PC6     ------> LTDC_HSYNC
    PC7     ------> LTDC_G6
    PD3     ------> LTDC_G7
    PG6     ------> LTDC_R7
    PG10     ------> LTDC_G3
    PG11     ------> LTDC_B3
    PG12     ------> LTDC_B4*)
    configureGPIO(GPIOA, maskA_1b, maskA_2b, maskA_4bl, maskA_4bh,
      LSL(AF_MODE, 3*2) + LSL(AF_MODE, 4*2) + LSL(AF_MODE, 6*2) + LSL(AF_MODE, 11*2) + LSL(AF_MODE, 12*2), (*PA3, 4, 6, 11 and 12 in AF_Mode*)
      LSL(HIGH_SPEED, 3*2) + LSL(HIGH_SPEED, 4*2) + LSL(HIGH_SPEED, 6*2) + LSL(HIGH_SPEED, 11*2) + LSL(HIGH_SPEED, 12*2), (*PA3, 6, 11 and 12 in high speed*)
      {}, (*push-pull*) {}, (*no pullup nor pulldown*)
      LSL(SYSTEM.VAL(SET, 14), 3*4) + LSL(SYSTEM.VAL(SET, 14), 4*4) + LSL(SYSTEM.VAL(SET, 14), 6*4), (*PA3, 4 and 6 in AF14*)
      LSL(SYSTEM.VAL(SET, 14), 11 MOD 8*4) + LSL(SYSTEM.VAL(SET, 14), 12 MOD 8*4)); (*PA 11 and 12 in AF14*)
    configureGPIO(GPIOB, maskB_1b, maskB_2b, maskB_4bl, maskB_4bh,
      LSL(AF_MODE, 0*2) + LSL(AF_MODE, 1*2) + LSL(AF_MODE, 8*2) + LSL(AF_MODE, 9*2) + LSL(AF_MODE, 10*2) + LSL(AF_MODE, 11*2),
      LSL(HIGH_SPEED, 0*2) + LSL(HIGH_SPEED, 1*2) + LSL(HIGH_SPEED, 8*2) + LSL(HIGH_SPEED, 9*2) + LSL(HIGH_SPEED, 10*2) + LSL(HIGH_SPEED, 11*2),
      {}, (*push-pull*) {}, (*no pullup nor pulldown*)
      LSL(SYSTEM.VAL(SET, 9), 0*4) + LSL(SYSTEM.VAL(SET, 9), 1*4), (*PB0 and 1 in AF9*)
      LSL(SYSTEM.VAL(SET, 14), 8 MOD 8*4) + LSL(SYSTEM.VAL(SET, 14), 9 MOD 8*4) +
        LSL(SYSTEM.VAL(SET, 14), 10 MOD 8*4) + LSL(SYSTEM.VAL(SET, 14), 11 MOD 8*4)); (*PB8, 9, 10 and 11 in AF14*)
    configureGPIO(GPIOC, maskC_1b, maskC_2b, maskC_4bl, {},
      LSL(AF_MODE, 6*2) + LSL(AF_MODE, 7*2), LSL(HIGH_SPEED, 6*2) + LSL(HIGH_SPEED, 7*2),
      {}, (*push-pull*) {}, (*no pullup nor pulldown*)
      LSL(SYSTEM.VAL(SET, 14), 6*4) + LSL(SYSTEM.VAL(SET, 14), 7*4), {});
    configureGPIO(GPIOD, {3}, LSL(MASK2, 3*2), LSL(MASK4, 3*4), {}, LSL(AF_MODE, 3*2), LSL(HIGH_SPEED, 3*2),
      {}, (*push-pull*) {}, (*no pullup nor pulldown*)
      LSL(SYSTEM.VAL(SET, 14), 3*4), {});
    configureGPIO(GPIOG, maskG_1b, maskG_2b, maskG_4bl, maskG_4bh,
      LSL(AF_MODE, 6*2) + LSL(AF_MODE, 10*2) + LSL(AF_MODE, 11*2) + LSL(AF_MODE, 12*2),
      LSL(HIGH_SPEED, 6*2) + LSL(HIGH_SPEED, 10*2) + LSL(HIGH_SPEED, 11*2) + LSL(HIGH_SPEED, 12*2),
      {}, {},
      LSL(SYSTEM.VAL(SET, 14), 6*4),
      LSL(SYSTEM.VAL(SET, 9), 10 MOD 8*4) + LSL(SYSTEM.VAL(SET, 14),  11 MOD 8*4) + LSL(SYSTEM.VAL(SET, 9),  12 MOD 8*4))
  END Display_InitGPIOs;

  PROCEDURE initGPIOs; (*Initialize GPIOs not associated to an hardware module*)
    CONST NCS_MEMSPin = 1; NCS_MEMSPort = GPIOC;
      NCS_MEMSOut =  PeriphBBAlias + (NCS_MEMSPort + IDR - PeriphBase + NCS_MEMSPin DIV 8)*32 + NCS_MEMSPin MOD 8*4;
      maskA_1b = {0, 5, 7};
      maskA_2b = LSL(MASK2, 0*2) + LSL(MASK2, 5*2) + LSL(PULL_UP, 7*2);
      maskC_1b = {1, 2, 3, 13, 14, 15};
      maskC_2b = LSL(MASK2, 1*2) + LSL(MASK2, 2*2) + LSL(PULL_UP, 3*2) + LSL(MASK2, 13*2) + LSL(MASK2, 14*2) + LSL(PULL_UP, 15*2);
      maskD_1b = {12, 13};
      maskD_2b = LSL(MASK2, 12*2) + LSL(MASK2, 13*2) + LSL(PULL_UP, 3*2);
      maskE_1b = {6};
      maskE_2b = LSL(MASK2, 6*2);
      maskF_1b = {6, 7, 8, 9};
      maskF_2b = LSL(MASK2, 6*2) + LSL(MASK2, 7*2) + LSL(MASK2, 8*2) + LSL(MASK2, 9*2);
      maskG_1b = {2, 3, 13, 14};
      maskG_2b = LSL(MASK2, 2*2) + LSL(MASK2, 3*2) + LSL(PULL_UP, 13*2) + LSL(MASK2, 14*2);
    VAR reg: SET;
  BEGIN NRF_initGPIOs; (*GPIOs initialized now to prevent NRF24L01P_CSPin to float, so nRF24L01+ is deselected*)
    SYSTEM.GET(RCC_BASE + AHB1ENR, reg);
    SYSTEM.PUT(RCC_BASE + AHB1ENR, reg + {GPIOAEN, GPIOCEN, GPIODEN, GPIOEEN, GPIOFEN, GPIOGEN});
    SYSTEM.GET(RCC_BASE + AHB1ENR, reg); (*delay*)
    SYSTEM.PUT(NCS_MEMSOut, 1); (*unselect MEMS peripheral*)

    (*PA0 as blue push button, PA5 and 7 as LEDs 3 and 4*)
    configureGPIO(GPIOA, maskA_1b, maskA_2b, {}, {}, LSL(OUTPUT_MODE, 5*2) + LSL(OUTPUT_MODE, 7*2), {}, {}, {}, {}, {});
    SYSTEM.GET(SYSCFG_BASE + EXTI_CR1 + B1Pin DIV 4*4, reg); (*blue push button (PA0) generates interrupt at rising*)
    SYSTEM.PUT(SYSCFG_BASE + EXTI_CR1 + B1Pin DIV 4*4, reg - {B1Pin MOD 4*4..B1Pin MOD 4*4+3} + LSL(SYSTEM.VAL(SET, 0), B1Pin MOD 4*4)); 
    (*EXTI 0 now connected to GPIOA*)
    SYSTEM.GET(EXTI_BASE + RTSR, reg); SYSTEM.PUT(EXTI_BASE + RTSR, reg + {B1Pin});
    SYSTEM.GET(EXTI_BASE + EMR, reg); SYSTEM.PUT(EXTI_BASE + EXTI_IMR, reg + {B1Pin});
    (*PC14, 15 and 13 as push buttons 1, 2 and 4*)
    configureGPIO(GPIOC, maskC_1b, maskE_2b, {}, {}, LSL(OUTPUT_MODE, 1*2) + LSL(OUTPUT_MODE, 2*2) + LSL(OUTPUT_MODE, 3*2),
      {}, {}, LSL(PULL_UP, 13*2) + LSL(PULL_UP, 14*2) + LSL(PULL_UP, 15*2), {}, {});
    (*PD12 and 13 as LED 6 and 5*)
    configureGPIO(GPIOD, maskD_1b, maskD_2b, {}, {}, LSL(OUTPUT_MODE, 12*2) + LSL(OUTPUT_MODE, 13*2), {}, {}, {}, {}, {});
   (*PE6 as push button 3*)
    configureGPIO(GPIOE, maskE_1b, maskE_2b, {}, {}, {}, {}, {}, LSL(PULL_UP, 6*2), {}, {});
    (*PF6, 8 and 7 as push buttons 6, 7, 8*)
    configureGPIO(GPIOF, maskF_1b, maskF_2b, {}, {}, LSL(OUTPUT_MODE, 9*2), {}, {}, LSL(PULL_UP, 6*2) + LSL(PULL_UP, 7*2) + LSL(PULL_UP, 8*2), {}, {});
    (*PG2 as push button 5, PG3 as LED 7, PG13 and 14 as LD 3 and 4*)
    configureGPIO(GPIOG, maskG_1b, maskG_2b, {}, {}, LSL(OUTPUT_MODE, 3*2) + LSL(OUTPUT_MODE, 13*2) + LSL(OUTPUT_MODE, 14*2), {}, {},
      LSL(PULL_UP, 2*2), {}, {});
  END initGPIOs;

  PROCEDURE InitPS2*;
  BEGIN PS2_initGPIOs
  END InitPS2;

  PROCEDURE InitCRC*;
    VAR res: BYTE;
  BEGIN SYSTEM.PUT(crcEn, TRUE); (*enable CRC clock*) SYSTEM.GET(crcEn, res); (*delay*)
  END InitCRC;

  PROCEDURE InitDisplay*;
    VAR reg: SET;
      i: INTEGER; r, g, b: BYTE;
  BEGIN Display_InitGPIOs;
    (*PLLSAI*) SYSTEM.PUT(pllsaiEn, FALSE); REPEAT UNTIL ~SYSTEM.BIT(RCC_BASE + RCC_CR, PLLSAIRDY);
    SYSTEM.GET(RCC_BASE + PLLSAICFGR, reg);
    SYSTEM.PUT(RCC_BASE + PLLSAICFGR, reg - (PLLSAINm + PLLSAIRm) + SYSTEM.VAL(SET, LSL(160, 6) + LSL(2, 28))); (*PLLSAIN = 160, PLLSAIR = 2*)
    SYSTEM.GET(RCC_BASE + DCKCFGR, reg); SYSTEM.PUT(RCC_BASE + DCKCFGR, reg - PLLSAIDIVRm); (*PLLSADIVR = 2*)
    SYSTEM.PUT(pllsaiEn, TRUE); REPEAT UNTIL SYSTEM.BIT(RCC_BASE + RCC_CR, PLLSAIRDY);

    (*LTDC*) SYSTEM.PUT(rcc_ltdcEn, TRUE); SYSTEM.GET(rcc_ltdcEn, reg); (*delay*)
    SYSTEM.GET(LTDC_BASE + GCR, reg); SYSTEM.PUT(LTDC_BASE + GCR, reg - (DEPOLm + PCPOLm) + (HSPOLm + VSPOLm)); (*HS and VS polarity high*)
    SYSTEM.GET(LTDC_BASE + SSCR, reg); SYSTEM.PUT(LTDC_BASE + SSCR, reg - (HSWm + VSHm) + SYSTEM.VAL(SET, LSL(143, 16) + 3)); (*HS size 143, VS size 3*)
    SYSTEM.GET(LTDC_BASE + BPCR, reg); SYSTEM.PUT(LTDC_BASE + BPCR, reg - (AHBPm + AVBMm) + SYSTEM.VAL(SET, LSL(356, 16) + 27)); (*Acc HBP 356, AVBP 27*)
    SYSTEM.GET(LTDC_BASE + ACWR, reg); SYSTEM.PUT(LTDC_BASE + ACWR, reg - (AAWm + AAHm) + SYSTEM.VAL(SET, LSL(1722, 16) + 795)); (*Acc AW 1722, AAH 795*)
    SYSTEM.GET(LTDC_BASE + TWCR, reg);
    SYSTEM.PUT(LTDC_BASE + TWCR, reg - (TOTALWm + TOTALHm) + SYSTEM.VAL(SET, LSL(1792, 16) + 798)); (*Total Width 1792, height 798*)
    SYSTEM.GET(LTDC_BASE + BCCR, reg); SYSTEM.PUT(LTDC_BASE + BCCR, reg - (BCREDm + BCGREENm + BCBLUEm)); (*Background red, green and blue 0*)
    SYSTEM.PUT(gcr_ltdcEn, TRUE);

    (*Layer 0*)
    SYSTEM.GET(LTDC_BASE + L0WHPCR, reg);
    SYSTEM.PUT(LTDC_BASE + L0WHPCR, reg - (WHSPPOSm + WHSTPOSm) + SYSTEM.VAL(SET, LSL(1722, 16) + 356+1));(*first visible pixel 357, last 1722*)
    SYSTEM.GET(LTDC_BASE + L0WVPCR, reg);
    SYSTEM.PUT(LTDC_BASE + L0WVPCR, reg - (WVSPPOSm + WVSTPOSm) + SYSTEM.VAL(SET, LSL(795, 16) + 27+1));(*first visible line 28, last 795*)
    SYSTEM.PUT(LTDC_BASE + L0PFCR, 5); (*pixel format L8*)
    SYSTEM.PUT(LTDC_BASE + L0DCCR, 0); (*Default color transparent black*)
    SYSTEM.PUT(LTDC_BASE + L0CACR, 255); (*constant alpha value 1*)
    SYSTEM.PUT(LTDC_BASE + L0BFCR, LSL(6, 8) + 7); (*blending factors 1 and 2 Pixel Alpha x Constant Alpha*)
    SYSTEM.PUT(LTDC_BASE + L0CFBAR, Display_FBA);
    SYSTEM.PUT(LTDC_BASE + L0CFBLR, LSL(Display_Pitch, 16) + (Display_Width + 3)*8 DIV Display_BPP);
    SYSTEM.PUT(LTDC_BASE + L0CFBLNR, Display_Height);
    SYSTEM.PUT(l0En, FALSE); (*disable layer 0 for CLUT update*)
    SYSTEM.PUT(imr, TRUE); (*reload shadow registers immediately*)
    FOR i := 0 TO 255 DO r := LSR(i, 5) MOD 8; g := LSR(i, 2) MOD 8; b := i MOD 4;
      SYSTEM.PUT(LTDC_BASE + L0CLUTWR, LSL(i, 24) + LSL(r*255 DIV 7, 16) + LSL(g*255 DIV 7, 8) + b*255 DIV 3)
    END;
    SYSTEM.PUT(LTDC_BASE + L0CR, CLUTENm + LENm); (*finally (re)enable layer 0 and color lookup table*)
    SYSTEM.PUT(imr, TRUE) (*reload shadow registers immediately*)
  END InitDisplay;

  PROCEDURE InitNRF24L01P*;
    VAR res: BYTE; isStarted: BOOLEAN;
  BEGIN
    (*SPI3*) SYSTEM.PUT(spi3En, TRUE); (*enable SPI3 clock*) SYSTEM.GET(spi3En, res); (*delay*)
    SYSTEM.GET(spe3, isStarted); SYSTEM.PUT(spe3, FALSE); (*disable SPI3 peripheral*)
    SYSTEM.PUT(SPI3_BASE + SPI_CR1, MSTRm + SSIm + SSMm + BRPS_8); (*Master, software slave management, DIV 8 prescaler*)
    SYSTEM.PUT(SPI3_BASE + SPI_CR2, 0);
    SYSTEM.PUT(i2smod3, FALSE); (*make sure that SPI3 is in SPI mode*)
    SYSTEM.PUT(spe3, isStarted) (*restart SPI if it was running before the configuration*)
  END InitNRF24L01P;

  PROCEDURE InitRTC*;
    VAR res: BYTE; bdcr, cfgr: SET;
  BEGIN SYSTEM.PUT(pwrEn, TRUE); (*enable power interface clock*) SYSTEM.GET(pwrEn, res); (*delay*)
    SYSTEM.PUT(dbp, TRUE); (*disable backup domain write protection*)
    REPEAT UNTIL SYSTEM.BIT(PWR_BASE + PWR_CR, DBP); (*protection is disabled now*)
    SYSTEM.GET(RCC_BASE + BDCR, bdcr); 
    IF (bdcr # {}) & (bdcr*RTCSEL # RTCSEL) THEN (*backup domain must be reset to be able to change clock source*)
      SYSTEM.PUT(bdRst, TRUE); SYSTEM.PUT(bdRst, FALSE)
    END;
    SYSTEM.PUT(RCC_BASE + BDCR, bdcr - {0..2} + RTCSEL); (*select HSE oscillator  divided by prescaler as RTC clock source*)
    SYSTEM.GET(RCC_BASE + CFGR, cfgr); SYSTEM.PUT(RCC_BASE + CFGR, ORD(cfgr - RTCPREm) + LSL(16, 16)); (*sets RTC division factor to 16*)
    SYSTEM.PUT(rtcEn, TRUE); (*enable RTC clock*)

    SYSTEM.PUT(RTC_BASE + WPR, 0CAH); SYSTEM.PUT(RTC_BASE + WPR, 53H); (*disable write protection on RTC registers*)
    SYSTEM.PUT(rtcInit, TRUE); (*put RTC in init mode*)
    REPEAT UNTIL SYSTEM.BIT(RTC_BASE + ISR, INITF); (*RTC is now in init mode*)
    SYSTEM.PUT(RTC_BASE + RTC_CR, 0); (*24 hour/day format, output disabled*)
    SYSTEM.PUT(RTC_BASE + PRER, 3999); (*two access are required, with synchronous prescaler first. Value is 3999*)
    SYSTEM.PUT(RTC_BASE + PRER, LSL(124, 16) + 3999); (*then write asynchronous prescaler factor. Value is 124*)
    SYSTEM.PUT(rtcInit, FALSE); (*exit RTC from init mode*)
    SYSTEM.PUT(RTC_BASE + WPR, 0FFH); (*enable write protection on RTC registers*)
  END InitRTC;

  PROCEDURE InitUART*;
    CONST mantissa = PCLK2Freq*1000000 DIV (16*115200);
      fraction = (PCLK2Freq*1000000 - 16*115200*mantissa) DIV 115200;
    VAR res: BYTE; cr: SET;
  BEGIN UART_initGPIOs;
    (*USART1*) SYSTEM.PUT(usart1En, TRUE); (*enable USART1 clock*) SYSTEM.GET(usart1En, res); (*delay*)
    SYSTEM.PUT(ue1, FALSE); (*disable UART*)
    SYSTEM.GET(UART_BASE + USART_CR2, cr); SYSTEM.PUT(UART_BASE + USART_CR2, cr - (STOPm + LINENm + CLKENm)); (*one stop bit*)
    SYSTEM.GET(UART_BASE + USART_CR1, cr);
    SYSTEM.PUT(UART_BASE + USART_CR1, cr - (Mm + PCEm + PSm + TEm + REm + OVER8m) + (TEm + REm)); (*8bits, parity disabled, transmit/receive enabled, 
      oversampling by 16*)
    SYSTEM.GET(UART_BASE + USART_CR3, cr);
    SYSTEM.PUT(UART_BASE + USART_CR3, cr - (RTSEm + CTSEm + SCENm + HDSELm + IRENm)); (*RTS and CTS hardware flow control disabled*)
    SYSTEM.PUT(UART_BASE + USART_BRR, LSL(mantissa, 4) + fraction);
    SYSTEM.PUT(ue1, TRUE); (*enble UART*)
  END InitUART;

  PROCEDURE Init;
  BEGIN initGPIOs;
    Leds[0] := LED1Out; Leds[1] := LED2Out; Leds[2] := LED3Out; Leds[3] := LED4Out; 
    Leds[4] := LED5Out; Leds[5] := LED6Out; Leds[6] := LED7Out
  END Init;

BEGIN Init;
END BSP.

OM4Tool.DecObj BSP.m4c
decode BSP.m4c
BSP 17BE1E3B   2   3356
imports:
type descriptors

data    28
strings

code
commands:
	InitPS2 00000662
	InitCRC 0000066E
	InitDisplay 00000694
	InitNRF24L01P 0000098C
	InitRTC 00000A00
	InitUART 00000B2C
entries
 00000C66 00000000 00000000 00000036 00000082 00000662 0000066E 00000694 0000098C 00000A00 00000B2C
pointer refs

fixP =  00000000
fixV =  00000C56
fixC =  00000000
fixT =  00000000
entry =  00000C66
 00000000	     B082	SUB SP SP #8
 00000002	     B401	PUSH R0
 00000004	     B500	PUSH LR
 00000006	 F2410004	MOV R0 #4100
 0000000A	 F2CE0000	MOVT R0 #57344
 0000000E	     6800	LDR R0 [ R0 + 0 ]
 00000010	     9002	STR R0 [ SP + 8 ]
 00000012	 F2410004	MOV R0 #4100
 00000016	 F2CE0000	MOVT R0 #57344
 0000001A	     6800	LDR R0 [ R0 + 0 ]
 0000001C	     9003	STR R0 [ SP + 12 ]
 0000001E	     9803	LDR R0 [ SP + 12 ]
 00000020	     9902	LDR R1 [ SP + 8 ]
 00000022	     1A40	SUBS R0 R0 R1
 00000024	     21A8	MOVS R1 #168
 00000026	     9A01	LDR R2 [ SP + 4 ]
 00000028	     4351	MULS R1 R2 R1
 0000002A	     4288	CMP R0 R1
 0000002C	     DBF1	BLT #-30, goes to  00000012
 0000002E	 F85DEB04	LDR LR [ SP ] + 4
 00000032	     B003	ADD SP SP #12
 00000034	     4770	BX LR
 00000036	     B081	SUB SP SP #4
 00000038	     B401	PUSH R0
 0000003A	     B500	PUSH LR
 0000003C	     2000	MOVS R0 #0
 0000003E	     2106	MOVS R1 #6
 00000040	     4281	CMP R1 R0
 00000042	 F2C0801A	BLT #52, goes to  0000007A
 00000046	     9002	STR R0 [ SP + 8 ]
 00000048	     9802	LDR R0 [ SP + 8 ]
 0000004A	     2807	CMP R0 #7
 0000004C	     BF28	IT CS
 0000004E	 EC0BE311	TrapCS 1 at pos 24369
 00000052	 10000029	MOV R1 lower 16-bits base(0), next at  00000000
 00000056	 00000000	MOVT R1 higher 16-bits var + 0
 0000005A	 EB110080	ADDS R0 R1 R0 LSL #2
 0000005E	     9901	LDR R1 [ SP + 4 ]
 00000060	 EA5F0171	RORS R1 R1 #1
 00000064	     6800	LDR R0 [ R0 + 0 ]
 00000066	     BF4C	ITE MI
 00000068	     2101	MOVMI R1 #1
 0000006A	     2100	MOVPL R1 #0
 0000006C	     7001	STRB R1 [ R0 + 0 ]
 0000006E	     9801	LDR R0 [ SP + 4 ]
 00000070	     1040	ASRS R0 R0 #1
 00000072	     9001	STR R0 [ SP + 4 ]
 00000074	     9802	LDR R0 [ SP + 8 ]
 00000076	     1C40	ADDS R0 R0 #1
 00000078	     E7E1	B #-62, goes to  0000003E
 0000007A	 F85DEB04	LDR LR [ SP ] + 4
 0000007E	     B002	ADD SP SP #8
 00000080	     4770	BX LR
 00000082	     B081	SUB SP SP #4
 00000084	     B403	PUSH R0 R1
 00000086	     B500	PUSH LR
 00000088	     2000	MOVS R0 #0
 0000008A	     2106	MOVS R1 #6
 0000008C	     4281	CMP R1 R0
 0000008E	 F2C0802E	BLT #92, goes to  000000EE
 00000092	     9003	STR R0 [ SP + 12 ]
 00000094	     9801	LDR R0 [ SP + 4 ]
 00000096	     9903	LDR R1 [ SP + 12 ]
 00000098	     1C49	ADDS R1 R1 #1
 0000009A	     41C8	RORS R0 R0 R1
 0000009C	 F1408010	BPL #32, goes to  000000C0
 000000A0	     9803	LDR R0 [ SP + 12 ]
 000000A2	     2807	CMP R0 #7
 000000A4	     BF28	IT CS
 000000A6	 EC0BF5B1	TrapCS 1 at pos 24539
 000000AA	 1000002C	MOV R1 lower 16-bits base(0), next at  00000052
 000000AE	 00000000	MOVT R1 higher 16-bits var + 0
 000000B2	 EB110080	ADDS R0 R1 R0 LSL #2
 000000B6	     6800	LDR R0 [ R0 + 0 ]
 000000B8	     2101	MOVS R1 #1
 000000BA	     7001	STRB R1 [ R0 + 0 ]
 000000BC	 F000B814	B #40, goes to  000000E8
 000000C0	     9802	LDR R0 [ SP + 8 ]
 000000C2	     9903	LDR R1 [ SP + 12 ]
 000000C4	     1C49	ADDS R1 R1 #1
 000000C6	     41C8	RORS R0 R0 R1
 000000C8	 F140800E	BPL #28, goes to  000000E8
 000000CC	     9803	LDR R0 [ SP + 12 ]
 000000CE	     2807	CMP R0 #7
 000000D0	     BF28	IT CS
 000000D2	 EC0C0091	TrapCS 1 at pos 24585
 000000D6	 10000016	MOV R1 lower 16-bits base(0), next at  000000AA
 000000DA	 00000000	MOVT R1 higher 16-bits var + 0
 000000DE	 EB110080	ADDS R0 R1 R0 LSL #2
 000000E2	     6800	LDR R0 [ R0 + 0 ]
 000000E4	     2100	MOVS R1 #0
 000000E6	     7001	STRB R1 [ R0 + 0 ]
 000000E8	     9803	LDR R0 [ SP + 12 ]
 000000EA	     1C40	ADDS R0 R0 #1
 000000EC	     E7CD	B #-102, goes to  0000008A
 000000EE	 F85DEB04	LDR LR [ SP ] + 4
 000000F2	     B003	ADD SP SP #12
 000000F4	     4770	BX LR
 000000F6	     B081	SUB SP SP #4
 000000F8	 E92D07FF	PUSH R0 R1 R2 R3 R4 R5 R6 R7 R8 R9 R10
 000000FC	     B500	PUSH LR
 000000FE	     9801	LDR R0 [ SP + 4 ]
 00000100	     3008	ADDS R0 R0 #8
 00000102	     6800	LDR R0 [ R0 + 0 ]
 00000104	     900C	STR R0 [ SP + 48 ]
 00000106	     9801	LDR R0 [ SP + 4 ]
 00000108	     3008	ADDS R0 R0 #8
 0000010A	     990C	LDR R1 [ SP + 48 ]
 0000010C	     9A03	LDR R2 [ SP + 12 ]
 0000010E	     4391	BICS R1 R1 R2
 00000110	     9A07	LDR R2 [ SP + 28 ]
 00000112	     4311	ORRS R1 R1 R2
 00000114	     6001	STR R1 [  R0 + 0 ]
 00000116	     9801	LDR R0 [ SP + 4 ]
 00000118	     1D00	ADDS R0 R0 #4
 0000011A	     6800	LDR R0 [ R0 + 0 ]
 0000011C	     900C	STR R0 [ SP + 48 ]
 0000011E	     9801	LDR R0 [ SP + 4 ]
 00000120	     1D00	ADDS R0 R0 #4
 00000122	     990C	LDR R1 [ SP + 48 ]
 00000124	     9A02	LDR R2 [ SP + 8 ]
 00000126	     4391	BICS R1 R1 R2
 00000128	     9A08	LDR R2 [ SP + 32 ]
 0000012A	     4311	ORRS R1 R1 R2
 0000012C	     6001	STR R1 [  R0 + 0 ]
 0000012E	     9801	LDR R0 [ SP + 4 ]
 00000130	     300C	ADDS R0 R0 #12
 00000132	     6800	LDR R0 [ R0 + 0 ]
 00000134	     900C	STR R0 [ SP + 48 ]
 00000136	     9801	LDR R0 [ SP + 4 ]
 00000138	     300C	ADDS R0 R0 #12
 0000013A	     990C	LDR R1 [ SP + 48 ]
 0000013C	     9A03	LDR R2 [ SP + 12 ]
 0000013E	     4391	BICS R1 R1 R2
 00000140	     9A09	LDR R2 [ SP + 36 ]
 00000142	     4311	ORRS R1 R1 R2
 00000144	     6001	STR R1 [  R0 + 0 ]
 00000146	     9801	LDR R0 [ SP + 4 ]
 00000148	     3020	ADDS R0 R0 #32
 0000014A	     6800	LDR R0 [ R0 + 0 ]
 0000014C	     900C	STR R0 [ SP + 48 ]
 0000014E	     9801	LDR R0 [ SP + 4 ]
 00000150	     3020	ADDS R0 R0 #32
 00000152	     990C	LDR R1 [ SP + 48 ]
 00000154	     9A04	LDR R2 [ SP + 16 ]
 00000156	     4391	BICS R1 R1 R2
 00000158	     9A0A	LDR R2 [ SP + 40 ]
 0000015A	     4311	ORRS R1 R1 R2
 0000015C	     6001	STR R1 [  R0 + 0 ]
 0000015E	     9801	LDR R0 [ SP + 4 ]
 00000160	     3024	ADDS R0 R0 #36
 00000162	     6800	LDR R0 [ R0 + 0 ]
 00000164	     900C	STR R0 [ SP + 48 ]
 00000166	     9801	LDR R0 [ SP + 4 ]
 00000168	     3024	ADDS R0 R0 #36
 0000016A	     990C	LDR R1 [ SP + 48 ]
 0000016C	     9A05	LDR R2 [ SP + 20 ]
 0000016E	     4391	BICS R1 R1 R2
 00000170	     9A0B	LDR R2 [ SP + 44 ]
 00000172	     4311	ORRS R1 R1 R2
 00000174	     6001	STR R1 [  R0 + 0 ]
 00000176	     9801	LDR R0 [ SP + 4 ]
 00000178	     6800	LDR R0 [ R0 + 0 ]
 0000017A	     900C	STR R0 [ SP + 48 ]
 0000017C	     9801	LDR R0 [ SP + 4 ]
 0000017E	     990C	LDR R1 [ SP + 48 ]
 00000180	     9A03	LDR R2 [ SP + 12 ]
 00000182	     4391	BICS R1 R1 R2
 00000184	     9A06	LDR R2 [ SP + 24 ]
 00000186	     4311	ORRS R1 R1 R2
 00000188	     6001	STR R1 [  R0 + 0 ]
 0000018A	 F85DEB04	LDR LR [ SP ] + 4
 0000018E	     B00C	ADD SP SP #48
 00000190	     4770	BX LR
 00000192	     B082	SUB SP SP #8
 00000194	     B500	PUSH LR
 00000196	 F2406010	MOV R0 #1552
 0000019A	 F2C42047	MOVT R0 #16967
 0000019E	     2101	MOVS R1 #1
 000001A0	     7001	STRB R1 [ R0 + 0 ]
 000001A2	 F2406010	MOV R0 #1552
 000001A6	 F2C42047	MOVT R0 #16967
 000001AA	     7800	LDRB R0 [ R0 + 0 ]
 000001AC	 F88D0004	STRB R0 [  SP + 4 ]
 000001B0	 F2410000	MOV R0 #4096
 000001B4	 F2C40002	MOVT R0 #16386
 000001B8	     213C	MOVS R1 #60
 000001BA	 F45F627F	MOVS R2 #4080
 000001BE	     2300	MOVS R3 #0
 000001C0	     2400	MOVS R4 #0
 000001C2	 F45F65AA	MOVS R5 #1360
 000001C6	     2600	MOVS R6 #0
 000001C8	     273C	MOVS R7 #60
 000001CA	 F05F0800	MOVS R8 #0
 000001CE	 F05F0900	MOVS R9 #0
 000001D2	 F05F0A00	MOVS R10 #0
 000001D6	 F7FFFF8E	BL #-228, goes to  000000F6
 000001DA	 F6430008	MOV R0 #14344
 000001DE	 F2C40001	MOVT R0 #16385
 000001E2	     6800	LDR R0 [ R0 + 0 ]
 000001E4	     9002	STR R0 [ SP + 8 ]
 000001E6	     9802	LDR R0 [ SP + 8 ]
 000001E8	 F4306070	BICS R0 R0 #3840
 000001EC	 F4506080	ORRS R0 R0 #1024
 000001F0	 F6430108	MOV R1 #14344
 000001F4	 F2C40101	MOVT R1 #16385
 000001F8	     6008	STR R0 [  R1 + 0 ]
 000001FA	 F643000C	MOV R0 #14348
 000001FE	 F2C40001	MOVT R0 #16385
 00000202	     6800	LDR R0 [ R0 + 0 ]
 00000204	     9002	STR R0 [ SP + 8 ]
 00000206	     9802	LDR R0 [ SP + 8 ]
 00000208	 F030000F	BICS R0 R0 #15
 0000020C	 F0500004	ORRS R0 R0 #4
 00000210	 F643010C	MOV R1 #14348
 00000214	 F2C40101	MOVT R1 #16385
 00000218	     6008	STR R0 [  R1 + 0 ]
 0000021A	 F643400C	MOV R0 #15372
 0000021E	 F2C40001	MOVT R0 #16385
 00000222	     6800	LDR R0 [ R0 + 0 ]
 00000224	     9002	STR R0 [ SP + 8 ]
 00000226	     9802	LDR R0 [ SP + 8 ]
 00000228	 F0500014	ORRS R0 R0 #20
 0000022C	 F643410C	MOV R1 #15372
 00000230	 F2C40101	MOVT R1 #16385
 00000234	     6008	STR R0 [  R1 + 0 ]
 00000236	 F6434000	MOV R0 #15360
 0000023A	 F2C40001	MOVT R0 #16385
 0000023E	     6800	LDR R0 [ R0 + 0 ]
 00000240	     9002	STR R0 [ SP + 8 ]
 00000242	     9802	LDR R0 [ SP + 8 ]
 00000244	 F0500014	ORRS R0 R0 #20
 00000248	 F6434100	MOV R1 #15360
 0000024C	 F2C40101	MOVT R1 #16385
 00000250	     6008	STR R0 [  R1 + 0 ]
 00000252	 F85DEB04	LDR LR [ SP ] + 4
 00000256	     B002	ADD SP SP #8
 00000258	     4770	BX LR
 0000025A	     B082	SUB SP SP #8
 0000025C	     B500	PUSH LR
 0000025E	 F6430030	MOV R0 #14384
 00000262	 F2C40002	MOVT R0 #16386
 00000266	     6800	LDR R0 [ R0 + 0 ]
 00000268	     9002	STR R0 [ SP + 8 ]
 0000026A	     9802	LDR R0 [ SP + 8 ]
 0000026C	 F050004A	ORRS R0 R0 #74
 00000270	 F6430130	MOV R1 #14384
 00000274	 F2C40102	MOVT R1 #16386
 00000278	     6008	STR R0 [  R1 + 0 ]
 0000027A	 F6430030	MOV R0 #14384
 0000027E	 F2C40002	MOVT R0 #16386
 00000282	     6800	LDR R0 [ R0 + 0 ]
 00000284	     9002	STR R0 [ SP + 8 ]
 00000286	 F248209C	MOV R0 #33436
 0000028A	 F2C42040	MOVT R0 #16960
 0000028E	     2101	MOVS R1 #1
 00000290	     6001	STR R1 [  R0 + 0 ]
 00000292	 F2404000	MOV R0 #1024
 00000296	 F2C40002	MOVT R0 #16386
 0000029A	     2198	MOVS R1 #152
 0000029C	 F24C32C0	MOV R2 #50112
 000002A0	 F24F0300	MOV R3 #61440
 000002A4	 F2CF030F	MOVT R3 #61455
 000002A8	     2400	MOVS R4 #0
 000002AA	 F45F4585	MOVS R5 #17024
 000002AE	 F45F76A0	MOVS R6 #320
 000002B2	     2700	MOVS R7 #0
 000002B4	 F05F0800	MOVS R8 #0
 000002B8	 F45F29CC	MOVS R9 #417792
 000002BC	 F05F0A00	MOVS R10 #0
 000002C0	 F7FFFF19	BL #-462, goes to  000000F6
 000002C4	 F6404000	MOV R0 #3072
 000002C8	 F2C40002	MOVT R0 #16386
 000002CC	     21C0	MOVS R1 #192
 000002CE	 F45F4270	MOVS R2 #61440
 000002D2	 F05F437F	MOVS R3 #-16777216
 000002D6	     2400	MOVS R4 #0
 000002D8	 F45F5500	MOVS R5 #8192
 000002DC	 F45F5680	MOVS R6 #4096
 000002E0	     2700	MOVS R7 #0
 000002E2	 F05F0800	MOVS R8 #0
 000002E6	 F05F69A0	MOVS R9 #83886080
 000002EA	 F05F0A00	MOVS R10 #0
 000002EE	 F7FFFF02	BL #-508, goes to  000000F6
 000002F2	 F6410000	MOV R0 #6144
 000002F6	 F2C40002	MOVT R0 #16386
 000002FA	 F45F7100	MOVS R1 #512
 000002FE	 F45F2240	MOVS R2 #786432
 00000302	     2300	MOVS R3 #0
 00000304	     24F0	MOVS R4 #240
 00000306	 F45F2580	MOVS R5 #262144
 0000030A	     2600	MOVS R6 #0
 0000030C	     2700	MOVS R7 #0
 0000030E	 F05F0800	MOVS R8 #0
 00000312	 F05F0900	MOVS R9 #0
 00000316	 F05F0A00	MOVS R10 #0
 0000031A	 F7FFFEEC	BL #-552, goes to  000000F6
 0000031E	 F85DEB04	LDR LR [ SP ] + 4
 00000322	     B002	ADD SP SP #8
 00000324	     4770	BX LR
 00000326	     B081	SUB SP SP #4
 00000328	     B500	PUSH LR
 0000032A	 F2406000	MOV R0 #1536
 0000032E	 F2C42047	MOVT R0 #16967
 00000332	     2101	MOVS R1 #1
 00000334	     7001	STRB R1 [ R0 + 0 ]
 00000336	 F2406000	MOV R0 #1536
 0000033A	 F2C42047	MOVT R0 #16967
 0000033E	     7800	LDRB R0 [ R0 + 0 ]
 00000340	 F88D0004	STRB R0 [  SP + 4 ]
 00000344	     2000	MOVS R0 #0
 00000346	 F2C40002	MOVT R0 #16386
 0000034A	 F45F61C0	MOVS R1 #1536
 0000034E	 F45F1270	MOVS R2 #3932160
 00000352	     2300	MOVS R3 #0
 00000354	 F45F647F	MOVS R4 #4080
 00000358	 F45F1520	MOVS R5 #2621440
 0000035C	     2600	MOVS R6 #0
 0000035E	     2700	MOVS R7 #0
 00000360	 F05F0800	MOVS R8 #0
 00000364	 F05F0900	MOVS R9 #0
 00000368	 F45F6AEE	MOVS R10 #1904
 0000036C	 F7FFFEC3	BL #-634, goes to  000000F6
 00000370	 F85DEB04	LDR LR [ SP ] + 4
 00000374	     B001	ADD SP SP #4
 00000376	     4770	BX LR
 00000378	     B081	SUB SP SP #4
 0000037A	     B500	PUSH LR
 0000037C	 F6430030	MOV R0 #14384
 00000380	 F2C40002	MOVT R0 #16386
 00000384	     6800	LDR R0 [ R0 + 0 ]
 00000386	     9001	STR R0 [ SP + 4 ]
 00000388	     9801	LDR R0 [ SP + 4 ]
 0000038A	 F050004F	ORRS R0 R0 #79
 0000038E	 F6430130	MOV R1 #14384
 00000392	 F2C40102	MOVT R1 #16386
 00000396	     6008	STR R0 [  R1 + 0 ]
 00000398	 F6430030	MOV R0 #14384
 0000039C	 F2C40002	MOVT R0 #16386
 000003A0	     6800	LDR R0 [ R0 + 0 ]
 000003A2	     9001	STR R0 [ SP + 4 ]
 000003A4	     2000	MOVS R0 #0
 000003A6	 F2C40002	MOVT R0 #16386
 000003AA	 F6410158	MOV R1 #6232
 000003AE	 F24332C0	MOV R2 #13248
 000003B2	 F2C032C0	MOVT R2 #960
 000003B6	 F24F0300	MOV R3 #61440
 000003BA	 F6C0730F	MOVT R3 #3855
 000003BE	 F45F247F	MOVS R4 #1044480
 000003C2	 F2422580	MOV R5 #8832
 000003C6	 F2C02580	MOVT R5 #640
 000003CA	 F2422680	MOV R6 #8832
 000003CE	 F2C02680	MOVT R6 #640
 000003D2	     2700	MOVS R7 #0
 000003D4	 F05F0800	MOVS R8 #0
 000003D8	 F24E0900	MOV R9 #57344
 000003DC	 F6C0690E	MOVT R9 #3598
 000003E0	 F45F2A6E	MOVS R10 #974848
 000003E4	 F7FFFE87	BL #-754, goes to  000000F6
 000003E8	 F2404000	MOV R0 #1024
 000003EC	 F2C40002	MOVT R0 #16386
 000003F0	 F6407103	MOV R1 #3843
 000003F4	     220F	MOVS R2 #15
 000003F6	 F2C002FF	MOVT R2 #255
 000003FA	     23FF	MOVS R3 #255
 000003FC	 F64F74FF	MOV R4 #65535
 00000400	     250A	MOVS R5 #10
 00000402	 F2C005AA	MOVT R5 #170
 00000406	     260A	MOVS R6 #10
 00000408	 F2C006AA	MOVT R6 #170
 0000040C	     2700	MOVS R7 #0
 0000040E	 F05F0800	MOVS R8 #0
 00000412	 F05F0999	MOVS R9 #153
 00000416	 F64E6AEE	MOV R10 #61166
 0000041A	 F7FFFE6C	BL #-808, goes to  000000F6
 0000041E	 F6400000	MOV R0 #2048
 00000422	 F2C40002	MOVT R0 #16386
 00000426	     21C0	MOVS R1 #192
 00000428	 F45F4270	MOVS R2 #61440
 0000042C	 F05F437F	MOVS R3 #-16777216
 00000430	     2400	MOVS R4 #0
 00000432	 F45F4520	MOVS R5 #40960
 00000436	 F45F4620	MOVS R6 #40960
 0000043A	     2700	MOVS R7 #0
 0000043C	 F05F0800	MOVS R8 #0
 00000440	 F05F496E	MOVS R9 #-301989888
 00000444	 F05F0A00	MOVS R10 #0
 00000448	 F7FFFE55	BL #-854, goes to  000000F6
 0000044C	 F6404000	MOV R0 #3072
 00000450	 F2C40002	MOVT R0 #16386
 00000454	     2108	MOVS R1 #8
 00000456	     22C0	MOVS R2 #192
 00000458	 F45F4370	MOVS R3 #61440
 0000045C	     2400	MOVS R4 #0
 0000045E	     2580	MOVS R5 #128
 00000460	     2680	MOVS R6 #128
 00000462	     2700	MOVS R7 #0
 00000464	 F05F0800	MOVS R8 #0
 00000468	 F45F4960	MOVS R9 #57344
 0000046C	 F05F0A00	MOVS R10 #0
 00000470	 F7FFFE41	BL #-894, goes to  000000F6
 00000474	 F6410000	MOV R0 #6144
 00000478	 F2C40002	MOVT R0 #16386
 0000047C	 F45F51E2	MOVS R1 #7232
 00000480	 F2430200	MOV R2 #12288
 00000484	 F2C032F0	MOVT R2 #1008
 00000488	 F05F6370	MOVS R3 #251658240
 0000048C	 F64F7400	MOV R4 #65280
 00000490	 F2C0040F	MOVT R4 #15
 00000494	 F2420500	MOV R5 #8192
 00000498	 F2C025A0	MOVT R5 #672
 0000049C	 F2420600	MOV R6 #8192
 000004A0	 F2C026A0	MOVT R6 #672
 000004A4	     2700	MOVS R7 #0
 000004A6	 F05F0800	MOVS R8 #0
 000004AA	 F05F6960	MOVS R9 #234881024
 000004AE	 F64E1A00	MOV R10 #59648
 000004B2	 F2C00A09	MOVT R10 #9
 000004B6	 F7FFFE1E	BL #-964, goes to  000000F6
 000004BA	 F85DEB04	LDR LR [ SP ] + 4
 000004BE	     B001	ADD SP SP #4
 000004C0	     4770	BX LR
 000004C2	     B081	SUB SP SP #4
 000004C4	     B500	PUSH LR
 000004C6	 F7FFFEC8	BL #-624, goes to  0000025A
 000004CA	 F6430030	MOV R0 #14384
 000004CE	 F2C40002	MOVT R0 #16386
 000004D2	     6800	LDR R0 [ R0 + 0 ]
 000004D4	     9001	STR R0 [ SP + 4 ]
 000004D6	     9801	LDR R0 [ SP + 4 ]
 000004D8	 F050007D	ORRS R0 R0 #125
 000004DC	 F6430130	MOV R1 #14384
 000004E0	 F2C40102	MOVT R1 #16386
 000004E4	     6008	STR R0 [  R1 + 0 ]
 000004E6	 F6430030	MOV R0 #14384
 000004EA	 F2C40002	MOVT R0 #16386
 000004EE	     6800	LDR R0 [ R0 + 0 ]
 000004F0	     9001	STR R0 [ SP + 4 ]
 000004F2	 F2402004	MOV R0 #516
 000004F6	 F2C42041	MOVT R0 #16961
 000004FA	     2101	MOVS R1 #1
 000004FC	     6001	STR R1 [  R0 + 0 ]
 000004FE	     2000	MOVS R0 #0
 00000500	 F2C40002	MOVT R0 #16386
 00000504	     21A1	MOVS R1 #161
 00000506	 F6444203	MOV R2 #19459
 0000050A	     2300	MOVS R3 #0
 0000050C	     2400	MOVS R4 #0
 0000050E	 F45F4588	MOVS R5 #17408
 00000512	     2600	MOVS R6 #0
 00000514	     2700	MOVS R7 #0
 00000516	 F05F0800	MOVS R8 #0
 0000051A	 F05F0900	MOVS R9 #0
 0000051E	 F05F0A00	MOVS R10 #0
 00000522	 F7FFFDE8	BL #-1072, goes to  000000F6
 00000526	 F6430008	MOV R0 #14344
 0000052A	 F2C40001	MOVT R0 #16385
 0000052E	     6800	LDR R0 [ R0 + 0 ]
 00000530	     9001	STR R0 [ SP + 4 ]
 00000532	     9801	LDR R0 [ SP + 4 ]
 00000534	 F030000F	BICS R0 R0 #15
 00000538	 F0500000	ORRS R0 R0 #0
 0000053C	 F6430108	MOV R1 #14344
 00000540	 F2C40101	MOVT R1 #16385
 00000544	     6008	STR R0 [  R1 + 0 ]
 00000546	 F6434008	MOV R0 #15368
 0000054A	 F2C40001	MOVT R0 #16385
 0000054E	     6800	LDR R0 [ R0 + 0 ]
 00000550	     9001	STR R0 [ SP + 4 ]
 00000552	     9801	LDR R0 [ SP + 4 ]
 00000554	 F0500001	ORRS R0 R0 #1
 00000558	 F6434108	MOV R1 #15368
 0000055C	 F2C40101	MOVT R1 #16385
 00000560	     6008	STR R0 [  R1 + 0 ]
 00000562	 F6434004	MOV R0 #15364
 00000566	 F2C40001	MOVT R0 #16385
 0000056A	     6800	LDR R0 [ R0 + 0 ]
 0000056C	     9001	STR R0 [ SP + 4 ]
 0000056E	     9801	LDR R0 [ SP + 4 ]
 00000570	 F0500001	ORRS R0 R0 #1
 00000574	 F6434100	MOV R1 #15360
 00000578	 F2C40101	MOVT R1 #16385
 0000057C	     6008	STR R0 [  R1 + 0 ]
 0000057E	 F6400000	MOV R0 #2048
 00000582	 F2C40002	MOVT R0 #16386
 00000586	 F24E010E	MOV R1 #57358
 0000058A	 F45F5240	MOVS R2 #12288
 0000058E	     2300	MOVS R3 #0
 00000590	     2400	MOVS R4 #0
 00000592	     2554	MOVS R5 #84
 00000594	     2600	MOVS R6 #0
 00000596	     2700	MOVS R7 #0
 00000598	 F05F48A8	MOVS R8 #1409286144
 0000059C	 F05F0900	MOVS R9 #0
 000005A0	 F05F0A00	MOVS R10 #0
 000005A4	 F7FFFDA7	BL #-1202, goes to  000000F6
 000005A8	 F6404000	MOV R0 #3072
 000005AC	 F2C40002	MOVT R0 #16386
 000005B0	 F45F5140	MOVS R1 #12288
 000005B4	     2240	MOVS R2 #64
 000005B6	 F6C07200	MOVT R2 #3840
 000005BA	     2300	MOVS R3 #0
 000005BC	     2400	MOVS R4 #0
 000005BE	 F05F65A0	MOVS R5 #83886080
 000005C2	     2600	MOVS R6 #0
 000005C4	     2700	MOVS R7 #0
 000005C6	 F05F0800	MOVS R8 #0
 000005CA	 F05F0900	MOVS R9 #0
 000005CE	 F05F0A00	MOVS R10 #0
 000005D2	 F7FFFD90	BL #-1248, goes to  000000F6
 000005D6	 F2410000	MOV R0 #4096
 000005DA	 F2C40002	MOVT R0 #16386
 000005DE	     2140	MOVS R1 #64
 000005E0	 F45F5240	MOVS R2 #12288
 000005E4	     2300	MOVS R3 #0
 000005E6	     2400	MOVS R4 #0
 000005E8	     2500	MOVS R5 #0
 000005EA	     2600	MOVS R6 #0
 000005EC	     2700	MOVS R7 #0
 000005EE	 F45F5880	MOVS R8 #4096
 000005F2	 F05F0900	MOVS R9 #0
 000005F6	 F05F0A00	MOVS R10 #0
 000005FA	 F7FFFD7C	BL #-1288, goes to  000000F6
 000005FE	 F2414000	MOV R0 #5120
 00000602	 F2C40002	MOVT R0 #16386
 00000606	 F45F7170	MOVS R1 #960
 0000060A	 F45F227F	MOVS R2 #1044480
 0000060E	     2300	MOVS R3 #0
 00000610	     2400	MOVS R4 #0
 00000612	 F45F2580	MOVS R5 #262144
 00000616	     2600	MOVS R6 #0
 00000618	     2700	MOVS R7 #0
 0000061A	 F45F38A8	MOVS R8 #86016
 0000061E	 F05F0900	MOVS R9 #0
 00000622	 F05F0A00	MOVS R10 #0
 00000626	 F7FFFD66	BL #-1332, goes to  000000F6
 0000062A	 F6410000	MOV R0 #6144
 0000062E	 F2C40002	MOVT R0 #16386
 00000632	 F246010C	MOV R1 #24588
 00000636	     22F0	MOVS R2 #240
 00000638	 F2C34200	MOVT R2 #13312
 0000063C	     2300	MOVS R3 #0
 0000063E	     2400	MOVS R4 #0
 00000640	     2540	MOVS R5 #64
 00000642	 F2C14500	MOVT R5 #5120
 00000646	     2600	MOVS R6 #0
 00000648	     2700	MOVS R7 #0
 0000064A	 F05F0810	MOVS R8 #16
 0000064E	 F05F0900	MOVS R9 #0
 00000652	 F05F0A00	MOVS R10 #0
 00000656	 F7FFFD4E	BL #-1380, goes to  000000F6
 0000065A	 F85DEB04	LDR LR [ SP ] + 4
 0000065E	     B001	ADD SP SP #4
 00000660	     4770	BX LR
 00000662	     B500	PUSH LR
 00000664	 F7FFFD95	BL #-1238, goes to  00000192
 00000668	 F85DEB04	LDR LR [ SP ] + 4
 0000066C	     4770	BX LR
 0000066E	     B081	SUB SP SP #4
 00000670	     B500	PUSH LR
 00000672	 F2406030	MOV R0 #1584
 00000676	 F2C42047	MOVT R0 #16967
 0000067A	     2101	MOVS R1 #1
 0000067C	     7001	STRB R1 [ R0 + 0 ]
 0000067E	 F2406030	MOV R0 #1584
 00000682	 F2C42047	MOVT R0 #16967
 00000686	     7800	LDRB R0 [ R0 + 0 ]
 00000688	 F88D0004	STRB R0 [  SP + 4 ]
 0000068C	 F85DEB04	LDR LR [ SP ] + 4
 00000690	     B001	ADD SP SP #4
 00000692	     4770	BX LR
 00000694	     B083	SUB SP SP #12
 00000696	     B500	PUSH LR
 00000698	 F7FFFE6E	BL #-804, goes to  00000378
 0000069C	     2070	MOVS R0 #112
 0000069E	 F2C42047	MOVT R0 #16967
 000006A2	     2100	MOVS R1 #0
 000006A4	     7001	STRB R1 [ R0 + 0 ]
 000006A6	     2074	MOVS R0 #116
 000006A8	 F2C42047	MOVT R0 #16967
 000006AC	     6800	LDR R0 [ R0 + 0 ]
 000006AE	     2800	CMP R0 #0
 000006B0	     D1F9	BNE #-14, goes to  000006A6
 000006B2	 F6430088	MOV R0 #14472
 000006B6	 F2C40002	MOVT R0 #16386
 000006BA	     6800	LDR R0 [ R0 + 0 ]
 000006BC	     9001	STR R0 [ SP + 4 ]
 000006BE	     9801	LDR R0 [ SP + 4 ]
 000006C0	 F64771C0	MOV R1 #32704
 000006C4	 F2C70100	MOVT R1 #28672
 000006C8	 EA300001	BICS R0 R0 R10 LSL #0
 000006CC	 F6420100	MOV R1 #10240
 000006D0	 F2C20100	MOVT R1 #8192
 000006D4	 EA500001	ORRS R0 R0 R1 LSL #0
 000006D8	 F6430188	MOV R1 #14472
 000006DC	 F2C40102	MOVT R1 #16386
 000006E0	     6008	STR R0 [  R1 + 0 ]
 000006E2	 F643008C	MOV R0 #14476
 000006E6	 F2C40002	MOVT R0 #16386
 000006EA	     6800	LDR R0 [ R0 + 0 ]
 000006EC	     9001	STR R0 [ SP + 4 ]
 000006EE	     9801	LDR R0 [ SP + 4 ]
 000006F0	 F4303040	BICS R0 R0 #196608
 000006F4	 F643018C	MOV R1 #14476
 000006F8	 F2C40102	MOVT R1 #16386
 000006FC	     6008	STR R0 [  R1 + 0 ]
 000006FE	     2070	MOVS R0 #112
 00000700	 F2C42047	MOVT R0 #16967
 00000704	     2101	MOVS R1 #1
 00000706	     7001	STRB R1 [ R0 + 0 ]
 00000708	     2074	MOVS R0 #116
 0000070A	 F2C42047	MOVT R0 #16967
 0000070E	     6800	LDR R0 [ R0 + 0 ]
 00000710	     2800	CMP R0 #0
 00000712	     D0F9	BEQ #-14, goes to  00000708
 00000714	 F64000E8	MOV R0 #2280
 00000718	 F2C42047	MOVT R0 #16967
 0000071C	     2101	MOVS R1 #1
 0000071E	     7001	STRB R1 [ R0 + 0 ]
 00000720	 F64000E8	MOV R0 #2280
 00000724	 F2C42047	MOVT R0 #16967
 00000728	     6800	LDR R0 [ R0 + 0 ]
 0000072A	     9001	STR R0 [ SP + 4 ]
 0000072C	 F6460018	MOV R0 #26648
 00000730	 F2C40001	MOVT R0 #16385
 00000734	     6800	LDR R0 [ R0 + 0 ]
 00000736	     9001	STR R0 [ SP + 4 ]
 00000738	     9801	LDR R0 [ SP + 4 ]
 0000073A	 F0305040	BICS R0 R0 #805306368
 0000073E	 F0504040	ORRS R0 R0 #-1073741824
 00000742	 F6460118	MOV R1 #26648
 00000746	 F2C40101	MOVT R1 #16385
 0000074A	     6008	STR R0 [  R1 + 0 ]
 0000074C	 F6460008	MOV R0 #26632
 00000750	 F2C40001	MOVT R0 #16385
 00000754	     6800	LDR R0 [ R0 + 0 ]
 00000756	     9001	STR R0 [ SP + 4 ]
 00000758	     9801	LDR R0 [ SP + 4 ]
 0000075A	 F24071FF	MOV R1 #2047
 0000075E	 F6C071FF	MOVT R1 #4095
 00000762	 EA300001	BICS R0 R0 R10 LSL #0
 00000766	     2103	MOVS R1 #3
 00000768	 F2C0018F	MOVT R1 #143
 0000076C	 EA500001	ORRS R0 R0 R1 LSL #0
 00000770	 F6460108	MOV R1 #26632
 00000774	 F2C40101	MOVT R1 #16385
 00000778	     6008	STR R0 [  R1 + 0 ]
 0000077A	 F646000C	MOV R0 #26636
 0000077E	 F2C40001	MOVT R0 #16385
 00000782	     6800	LDR R0 [ R0 + 0 ]
 00000784	     9001	STR R0 [ SP + 4 ]
 00000786	     9801	LDR R0 [ SP + 4 ]
 00000788	 F24071FF	MOV R1 #2047
 0000078C	 F6C071FF	MOVT R1 #4095
 00000790	 EA300001	BICS R0 R0 R10 LSL #0
 00000794	     211B	MOVS R1 #27
 00000796	 F2C01164	MOVT R1 #356
 0000079A	 EA500001	ORRS R0 R0 R1 LSL #0
 0000079E	 F646010C	MOV R1 #26636
 000007A2	 F2C40101	MOVT R1 #16385
 000007A6	     6008	STR R0 [  R1 + 0 ]
 000007A8	 F6460010	MOV R0 #26640
 000007AC	 F2C40001	MOVT R0 #16385
 000007B0	     6800	LDR R0 [ R0 + 0 ]
 000007B2	     9001	STR R0 [ SP + 4 ]
 000007B4	     9801	LDR R0 [ SP + 4 ]
 000007B6	 F24071FF	MOV R1 #2047
 000007BA	 F6C071FF	MOVT R1 #4095
 000007BE	 EA300001	BICS R0 R0 R10 LSL #0
 000007C2	 F240311B	MOV R1 #795
 000007C6	 F2C061BA	MOVT R1 #1722
 000007CA	 EA500001	ORRS R0 R0 R1 LSL #0
 000007CE	 F6460110	MOV R1 #26640
 000007D2	 F2C40101	MOVT R1 #16385
 000007D6	     6008	STR R0 [  R1 + 0 ]
 000007D8	 F6460014	MOV R0 #26644
 000007DC	 F2C40001	MOVT R0 #16385
 000007E0	     6800	LDR R0 [ R0 + 0 ]
 000007E2	     9001	STR R0 [ SP + 4 ]
 000007E4	     9801	LDR R0 [ SP + 4 ]
 000007E6	 F24071FF	MOV R1 #2047
 000007EA	 F6C071FF	MOVT R1 #4095
 000007EE	 EA300001	BICS R0 R0 R10 LSL #0
 000007F2	 F240311E	MOV R1 #798
 000007F6	 F2C07100	MOVT R1 #1792
 000007FA	 EA500001	ORRS R0 R0 R1 LSL #0
 000007FE	 F6460114	MOV R1 #26644
 00000802	 F2C40101	MOVT R1 #16385
 00000806	     6008	STR R0 [  R1 + 0 ]
 00000808	 F646002C	MOV R0 #26668
 0000080C	 F2C40001	MOVT R0 #16385
 00000810	     6800	LDR R0 [ R0 + 0 ]
 00000812	     9001	STR R0 [ SP + 4 ]
 00000814	     9801	LDR R0 [ SP + 4 ]
 00000816	 F010407F	ANDS R0 R0 #-16777216
 0000081A	 F646012C	MOV R1 #26668
 0000081E	 F2C40101	MOVT R1 #16385
 00000822	     6008	STR R0 [  R1 + 0 ]
 00000824	 F2403000	MOV R0 #768
 00000828	 F2C4202D	MOVT R0 #16941
 0000082C	     2101	MOVS R1 #1
 0000082E	     7001	STRB R1 [ R0 + 0 ]
 00000830	 F6460088	MOV R0 #26760
 00000834	 F2C40001	MOVT R0 #16385
 00000838	     6800	LDR R0 [ R0 + 0 ]
 0000083A	     9001	STR R0 [ SP + 4 ]
 0000083C	     9801	LDR R0 [ SP + 4 ]
 0000083E	 F01020F0	ANDS R0 R0 #-268374016
 00000842	 F2401165	MOV R1 #357
 00000846	 F2C061BA	MOVT R1 #1722
 0000084A	 EA500001	ORRS R0 R0 R1 LSL #0
 0000084E	 F6460188	MOV R1 #26760
 00000852	 F2C40101	MOVT R1 #16385
 00000856	     6008	STR R0 [  R1 + 0 ]
 00000858	 F646008C	MOV R0 #26764
 0000085C	 F2C40001	MOVT R0 #16385
 00000860	     6800	LDR R0 [ R0 + 0 ]
 00000862	     9001	STR R0 [ SP + 4 ]
 00000864	     9801	LDR R0 [ SP + 4 ]
 00000866	 F01020F8	ANDS R0 R0 #-134154240
 0000086A	     211C	MOVS R1 #28
 0000086C	 F2C0311B	MOVT R1 #795
 00000870	 EA500001	ORRS R0 R0 R1 LSL #0
 00000874	 F646018C	MOV R1 #26764
 00000878	 F2C40101	MOVT R1 #16385
 0000087C	     6008	STR R0 [  R1 + 0 ]
 0000087E	 F6460094	MOV R0 #26772
 00000882	 F2C40001	MOVT R0 #16385
 00000886	     2105	MOVS R1 #5
 00000888	     6001	STR R1 [  R0 + 0 ]
 0000088A	 F646009C	MOV R0 #26780
 0000088E	 F2C40001	MOVT R0 #16385
 00000892	     2100	MOVS R1 #0
 00000894	     6001	STR R1 [  R0 + 0 ]
 00000896	 F6460098	MOV R0 #26776
 0000089A	 F2C40001	MOVT R0 #16385
 0000089E	     21FF	MOVS R1 #255
 000008A0	     6001	STR R1 [  R0 + 0 ]
 000008A2	 F64600A0	MOV R0 #26784
 000008A6	 F2C40001	MOVT R0 #16385
 000008AA	 F2406107	MOV R1 #1543
 000008AE	     6001	STR R1 [  R0 + 0 ]
 000008B0	 F64600AC	MOV R0 #26796
 000008B4	 F2C40001	MOVT R0 #16385
 000008B8	 F05F4150	MOVS R1 #-805306368
 000008BC	     6001	STR R1 [  R0 + 0 ]
 000008BE	 F64600B0	MOV R0 #26800
 000008C2	 F2C40001	MOVT R0 #16385
 000008C6	 F2405159	MOV R1 #1369
 000008CA	 F2C05180	MOVT R1 #1408
 000008CE	     6001	STR R1 [  R0 + 0 ]
 000008D0	 F64600B4	MOV R0 #26804
 000008D4	 F2C40001	MOVT R0 #16385
 000008D8	 F45F7140	MOVS R1 #768
 000008DC	     6001	STR R1 [  R0 + 0 ]
 000008DE	 F2410080	MOV R0 #4224
 000008E2	 F2C4202D	MOVT R0 #16941
 000008E6	     2100	MOVS R1 #0
 000008E8	     7001	STRB R1 [ R0 + 0 ]
 000008EA	 F2404080	MOV R0 #1152
 000008EE	 F2C4202D	MOVT R0 #16941
 000008F2	     2101	MOVS R1 #1
 000008F4	     7001	STRB R1 [ R0 + 0 ]
 000008F6	     2000	MOVS R0 #0
 000008F8	     21FF	MOVS R1 #255
 000008FA	     4281	CMP R1 R0
 000008FC	 F2C08036	BLT #108, goes to  0000096C
 00000900	     9002	STR R0 [ SP + 8 ]
 00000902	     9802	LDR R0 [ SP + 8 ]
 00000904	     0940	LSRS R0 R0 #5
 00000906	 F36F00DF	BFC R0 #3 #29
 0000090A	 F88D000C	STRB R0 [  SP + 12 ]
 0000090E	     9802	LDR R0 [ SP + 8 ]
 00000910	     0880	LSRS R0 R0 #2
 00000912	 F36F00DF	BFC R0 #3 #29
 00000916	 F88D000D	STRB R0 [  SP + 13 ]
 0000091A	     9802	LDR R0 [ SP + 8 ]
 0000091C	 F36F009F	BFC R0 #2 #30
 00000920	 F88D000E	STRB R0 [  SP + 14 ]
 00000924	     9802	LDR R0 [ SP + 8 ]
 00000926	     0600	LSLS R0 R0 #24
 00000928	 F89D100C	LDRB R1 [ SP + 12 ]
 0000092C	     22FF	MOVS R2 #255
 0000092E	     4351	MULS R1 R2 R1
 00000930	     2207	MOVS R2 #7
 00000932	 FBB1F1F2	UDIV R1 R1 R2
 00000936	     0409	LSLS R1 R1 #16
 00000938	     1840	ADDS R0 R0 R1
 0000093A	 F89D100D	LDRB R1 [ SP + 13 ]
 0000093E	     22FF	MOVS R2 #255
 00000940	     4351	MULS R1 R2 R1
 00000942	     2207	MOVS R2 #7
 00000944	 FBB1F1F2	UDIV R1 R1 R2
 00000948	     0209	LSLS R1 R1 #8
 0000094A	     1840	ADDS R0 R0 R1
 0000094C	 F89D100E	LDRB R1 [ SP + 14 ]
 00000950	     22FF	MOVS R2 #255
 00000952	     4351	MULS R1 R2 R1
 00000954	     2203	MOVS R2 #3
 00000956	 FBB1F1F2	UDIV R1 R1 R2
 0000095A	     1840	ADDS R0 R0 R1
 0000095C	 F64601C4	MOV R1 #26820
 00000960	 F2C40101	MOVT R1 #16385
 00000964	     6008	STR R0 [  R1 + 0 ]
 00000966	     9802	LDR R0 [ SP + 8 ]
 00000968	     1C40	ADDS R0 R0 #1
 0000096A	     E7C5	B #-118, goes to  000008F8
 0000096C	 F6460084	MOV R0 #26756
 00000970	 F2C40001	MOVT R0 #16385
 00000974	     2111	MOVS R1 #17
 00000976	     6001	STR R1 [  R0 + 0 ]
 00000978	 F2404080	MOV R0 #1152
 0000097C	 F2C4202D	MOVT R0 #16941
 00000980	     2101	MOVS R1 #1
 00000982	     7001	STRB R1 [ R0 + 0 ]
 00000984	 F85DEB04	LDR LR [ SP ] + 4
 00000988	     B003	ADD SP SP #12
 0000098A	     4770	BX LR
 0000098C	     B081	SUB SP SP #4
 0000098E	     B500	PUSH LR
 00000990	 F640003C	MOV R0 #2108
 00000994	 F2C42047	MOVT R0 #16967
 00000998	     2101	MOVS R1 #1
 0000099A	     7001	STRB R1 [ R0 + 0 ]
 0000099C	 F640003C	MOV R0 #2108
 000009A0	 F2C42047	MOVT R0 #16967
 000009A4	     7800	LDRB R0 [ R0 + 0 ]
 000009A6	 F88D0004	STRB R0 [  SP + 4 ]
 000009AA	 F2480018	MOV R0 #32792
 000009AE	 F2C42007	MOVT R0 #16903
 000009B2	     7800	LDRB R0 [ R0 + 0 ]
 000009B4	 F88D0005	STRB R0 [  SP + 5 ]
 000009B8	 F2480018	MOV R0 #32792
 000009BC	 F2C42007	MOVT R0 #16903
 000009C0	     2100	MOVS R1 #0
 000009C2	     7001	STRB R1 [ R0 + 0 ]
 000009C4	 F6434000	MOV R0 #15360
 000009C8	 F2C40000	MOVT R0 #16384
 000009CC	 F45F7145	MOVS R1 #788
 000009D0	     6001	STR R1 [  R0 + 0 ]
 000009D2	 F6434004	MOV R0 #15364
 000009D6	 F2C40000	MOVT R0 #16384
 000009DA	     2100	MOVS R1 #0
 000009DC	     6001	STR R1 [  R0 + 0 ]
 000009DE	 F24830AC	MOV R0 #33708
 000009E2	 F2C42007	MOVT R0 #16903
 000009E6	     2100	MOVS R1 #0
 000009E8	     7001	STRB R1 [ R0 + 0 ]
 000009EA	 F2480018	MOV R0 #32792
 000009EE	 F2C42007	MOVT R0 #16903
 000009F2	 F89D1005	LDRB R1 [ SP + 5 ]
 000009F6	     7001	STRB R1 [ R0 + 0 ]
 000009F8	 F85DEB04	LDR LR [ SP ] + 4
 000009FC	     B001	ADD SP SP #4
 000009FE	     4770	BX LR
 00000A00	     B083	SUB SP SP #12
 00000A02	     B500	PUSH LR
 00000A04	 F6400070	MOV R0 #2160
 00000A08	 F2C42047	MOVT R0 #16967
 00000A0C	     2101	MOVS R1 #1
 00000A0E	     7001	STRB R1 [ R0 + 0 ]
 00000A10	 F6400070	MOV R0 #2160
 00000A14	 F2C42047	MOVT R0 #16967
 00000A18	     7800	LDRB R0 [ R0 + 0 ]
 00000A1A	 F88D0004	STRB R0 [  SP + 4 ]
 00000A1E	     2020	MOVS R0 #32
 00000A20	 F2C4200E	MOVT R0 #16910
 00000A24	     2101	MOVS R1 #1
 00000A26	     7001	STRB R1 [ R0 + 0 ]
 00000A28	     2020	MOVS R0 #32
 00000A2A	 F2C4200E	MOVT R0 #16910
 00000A2E	     6800	LDR R0 [ R0 + 0 ]
 00000A30	     2800	CMP R0 #0
 00000A32	     D0F9	BEQ #-14, goes to  00000A28
 00000A34	 F6430070	MOV R0 #14448
 00000A38	 F2C40002	MOVT R0 #16386
 00000A3C	     6800	LDR R0 [ R0 + 0 ]
 00000A3E	     9002	STR R0 [ SP + 8 ]
 00000A40	     9802	LDR R0 [ SP + 8 ]
 00000A42	     2800	CMP R0 #0
 00000A44	 F0008013	BEQ #38, goes to  00000A6E
 00000A48	     9802	LDR R0 [ SP + 8 ]
 00000A4A	 F4107040	ANDS R0 R0 #768
 00000A4E	 F5B07F40	CMP R0 #768
 00000A52	 F000800C	BEQ #24, goes to  00000A6E
 00000A56	 F6406040	MOV R0 #3648
 00000A5A	 F2C42047	MOVT R0 #16967
 00000A5E	     2101	MOVS R1 #1
 00000A60	     7001	STRB R1 [ R0 + 0 ]
 00000A62	 F6406040	MOV R0 #3648
 00000A66	 F2C42047	MOVT R0 #16967
 00000A6A	     2100	MOVS R1 #0
 00000A6C	     7001	STRB R1 [ R0 + 0 ]
 00000A6E	     9802	LDR R0 [ SP + 8 ]
 00000A70	 F0300007	BICS R0 R0 #7
 00000A74	 F4507040	ORRS R0 R0 #768
 00000A78	 F6430170	MOV R1 #14448
 00000A7C	 F2C40102	MOVT R1 #16386
 00000A80	     6008	STR R0 [  R1 + 0 ]
 00000A82	 F6430008	MOV R0 #14344
 00000A86	 F2C40002	MOVT R0 #16386
 00000A8A	     6800	LDR R0 [ R0 + 0 ]
 00000A8C	     9003	STR R0 [ SP + 12 ]
 00000A8E	     9803	LDR R0 [ SP + 12 ]
 00000A90	 F43010F8	BICS R0 R0 #2031616
 00000A94	 F5101080	ADDS R0 R0 #1048576
 00000A98	 F6430108	MOV R1 #14344
 00000A9C	 F2C40102	MOVT R1 #16386
 00000AA0	     6008	STR R0 [  R1 + 0 ]
 00000AA2	 F640603C	MOV R0 #3644
 00000AA6	 F2C42047	MOVT R0 #16967
 00000AAA	     2101	MOVS R1 #1
 00000AAC	     7001	STRB R1 [ R0 + 0 ]
 00000AAE	 F6420024	MOV R0 #10276
 00000AB2	 F2C40000	MOVT R0 #16384
 00000AB6	     21CA	MOVS R1 #202
 00000AB8	     6001	STR R1 [  R0 + 0 ]
 00000ABA	 F6420024	MOV R0 #10276
 00000ABE	 F2C40000	MOVT R0 #16384
 00000AC2	     2153	MOVS R1 #83
 00000AC4	     6001	STR R1 [  R0 + 0 ]
 00000AC6	 F240109C	MOV R0 #412
 00000ACA	 F2C42005	MOVT R0 #16901
 00000ACE	     2101	MOVS R1 #1
 00000AD0	     7001	STRB R1 [ R0 + 0 ]
 00000AD2	 F2401098	MOV R0 #408
 00000AD6	 F2C42005	MOVT R0 #16901
 00000ADA	     6800	LDR R0 [ R0 + 0 ]
 00000ADC	     2800	CMP R0 #0
 00000ADE	     D0F8	BEQ #-16, goes to  00000AD2
 00000AE0	 F6420008	MOV R0 #10248
 00000AE4	 F2C40000	MOVT R0 #16384
 00000AE8	     2100	MOVS R1 #0
 00000AEA	     6001	STR R1 [  R0 + 0 ]
 00000AEC	 F6420010	MOV R0 #10256
 00000AF0	 F2C40000	MOVT R0 #16384
 00000AF4	 F640719F	MOV R1 #3999
 00000AF8	     6001	STR R1 [  R0 + 0 ]
 00000AFA	 F6420010	MOV R0 #10256
 00000AFE	 F2C40000	MOVT R0 #16384
 00000B02	 F640719F	MOV R1 #3999
 00000B06	 F2C0017C	MOVT R1 #124
 00000B0A	     6001	STR R1 [  R0 + 0 ]
 00000B0C	 F240109C	MOV R0 #412
 00000B10	 F2C42005	MOVT R0 #16901
 00000B14	     2100	MOVS R1 #0
 00000B16	     7001	STRB R1 [ R0 + 0 ]
 00000B18	 F6420024	MOV R0 #10276
 00000B1C	 F2C40000	MOVT R0 #16384
 00000B20	     21FF	MOVS R1 #255
 00000B22	     6001	STR R1 [  R0 + 0 ]
 00000B24	 F85DEB04	LDR LR [ SP ] + 4
 00000B28	     B003	ADD SP SP #12
 00000B2A	     4770	BX LR
 00000B2C	     B082	SUB SP SP #8
 00000B2E	     B500	PUSH LR
 00000B30	 F7FFFBF9	BL #-2062, goes to  00000326
 00000B34	 F6400090	MOV R0 #2192
 00000B38	 F2C42047	MOVT R0 #16967
 00000B3C	     2101	MOVS R1 #1
 00000B3E	     7001	STRB R1 [ R0 + 0 ]
 00000B40	 F6400090	MOV R0 #2192
 00000B44	 F2C42047	MOVT R0 #16967
 00000B48	     7800	LDRB R0 [ R0 + 0 ]
 00000B4A	 F88D0004	STRB R0 [  SP + 4 ]
 00000B4E	 F24010B4	MOV R0 #436
 00000B52	 F2C42022	MOVT R0 #16930
 00000B56	     2100	MOVS R1 #0
 00000B58	     7001	STRB R1 [ R0 + 0 ]
 00000B5A	 F2410010	MOV R0 #4112
 00000B5E	 F2C40001	MOVT R0 #16385
 00000B62	     6800	LDR R0 [ R0 + 0 ]
 00000B64	     9002	STR R0 [ SP + 8 ]
 00000B66	     9802	LDR R0 [ SP + 8 ]
 00000B68	 F43040F0	BICS R0 R0 #30720
 00000B6C	 F2410110	MOV R1 #4112
 00000B70	 F2C40101	MOVT R1 #16385
 00000B74	     6008	STR R0 [  R1 + 0 ]
 00000B76	 F241000C	MOV R0 #4108
 00000B7A	 F2C40001	MOVT R0 #16385
 00000B7E	     6800	LDR R0 [ R0 + 0 ]
 00000B80	     9002	STR R0 [ SP + 8 ]
 00000B82	     9802	LDR R0 [ SP + 8 ]
 00000B84	 F249610C	MOV R1 #38412
 00000B88	 EA300001	BICS R0 R0 R10 LSL #0
 00000B8C	 F050000C	ORRS R0 R0 #12
 00000B90	 F241010C	MOV R1 #4108
 00000B94	 F2C40101	MOVT R1 #16385
 00000B98	     6008	STR R0 [  R1 + 0 ]
 00000B9A	 F2410014	MOV R0 #4116
 00000B9E	 F2C40001	MOVT R0 #16385
 00000BA2	     6800	LDR R0 [ R0 + 0 ]
 00000BA4	     9002	STR R0 [ SP + 8 ]
 00000BA6	     9802	LDR R0 [ SP + 8 ]
 00000BA8	 F240312A	MOV R1 #810
 00000BAC	 EA300001	BICS R0 R0 R10 LSL #0
 00000BB0	 F2410114	MOV R1 #4116
 00000BB4	 F2C40101	MOVT R1 #16385
 00000BB8	     6008	STR R0 [  R1 + 0 ]
 00000BBA	 F2410008	MOV R0 #4104
 00000BBE	 F2C40001	MOVT R0 #16385
 00000BC2	 F24021D9	MOV R1 #729
 00000BC6	     6001	STR R1 [  R0 + 0 ]
 00000BC8	 F24010B4	MOV R0 #436
 00000BCC	 F2C42022	MOVT R0 #16930
 00000BD0	     2101	MOVS R1 #1
 00000BD2	     7001	STRB R1 [ R0 + 0 ]
 00000BD4	 F85DEB04	LDR LR [ SP ] + 4
 00000BD8	     B002	ADD SP SP #8
 00000BDA	     4770	BX LR
 00000BDC	     B500	PUSH LR
 00000BDE	 F7FFFC70	BL #-1824, goes to  000004C2
 00000BE2	 F24820A4	MOV R0 #33444
 00000BE6	 F2C42042	MOVT R0 #16962
 00000BEA	 1000058A	MOV R1 lower 16-bits base(0), next at  000000D6
 00000BEE	 00000000	MOVT R1 higher 16-bits var + 0
 00000BF2	     6008	STR R0 [  R1 + 0 ]
 00000BF4	 F240208C	MOV R0 #652
 00000BF8	 F2C42041	MOVT R0 #16961
 00000BFC	 10000009	MOV R1 lower 16-bits base(0), next at  00000BEA
 00000C00	 00000004	MOVT R1 higher 16-bits var + 4
 00000C04	     6008	STR R0 [  R1 + 0 ]
 00000C06	 F2402094	MOV R0 #660
 00000C0A	 F2C42040	MOVT R0 #16960
 00000C0E	 10000009	MOV R1 lower 16-bits base(0), next at  00000BFC
 00000C12	 00000008	MOVT R1 higher 16-bits var + 8
 00000C16	     6008	STR R0 [  R1 + 0 ]
 00000C18	 F240209C	MOV R0 #668
 00000C1C	 F2C42040	MOVT R0 #16960
 00000C20	 10000009	MOV R1 lower 16-bits base(0), next at  00000C0E
 00000C24	 0000000C	MOVT R1 higher 16-bits var + 12
 00000C28	     6008	STR R0 [  R1 + 0 ]
 00000C2A	 F24820B4	MOV R0 #33460
 00000C2E	 F2C42041	MOVT R0 #16961
 00000C32	 10000009	MOV R1 lower 16-bits base(0), next at  00000C20
 00000C36	 00000010	MOVT R1 higher 16-bits var + 16
 00000C3A	     6008	STR R0 [  R1 + 0 ]
 00000C3C	 F24820B0	MOV R0 #33456
 00000C40	 F2C42041	MOVT R0 #16961
 00000C44	 10000009	MOV R1 lower 16-bits base(0), next at  00000C32
 00000C48	 00000014	MOVT R1 higher 16-bits var + 20
 00000C4C	     6008	STR R0 [  R1 + 0 ]
 00000C4E	 F240208C	MOV R0 #652
 00000C52	 F2C42043	MOVT R0 #16963
 00000C56	 10000009	MOV R1 lower 16-bits base(0), next at  00000C44
 00000C5A	 00000018	MOVT R1 higher 16-bits var + 24
 00000C5E	     6008	STR R0 [  R1 + 0 ]
 00000C60	 F85DEB04	LDR LR [ SP ] + 4
 00000C64	     4770	BX LR
 00000C66	     B500	PUSH LR
 00000C68	 F7FFFFB8	BL #-144, goes to  00000BDC
 00000C6C	 F85DEB04	LDR LR [ SP ] + 4
 00000C70	     4770	BX LR
