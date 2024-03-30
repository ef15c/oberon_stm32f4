MODULE BSP; (*CS 06.03.24 STM32F429I-DISCO Oberon base board abstraction*)
  IMPORT SYSTEM;

  CONST  MASK2* = {0..1}; MASK4* = {0..3};
    (*STM32F429*)
    (*Cortex M4*)
    SCB_BASE* =  0E000ED00H;
    ICSR* = 4; CFSR* = 28H; BFAR* = 38H;
    PENDSVSET* = 28;
    UFSR_Mask* = {16..31}; BFSR_Mask* = {8..15};
    NOCP* = 19; INVSTATE* = 17; PRECISERR* = 9; STKERR* = 12;

    (*DWT*)
    DWTBase* = 0E0001000H;  CYCCNT* = 4;
    HCLCFREQ* = 168;

    (*Memory*)
    SRAMBase* = 20000000H; VecTabBase* = SRAMBase;

    (*Peripherals*)
    PeriphBase* = 40000000H; PeriphBBAlias* = 42000000H;

    (*NVIC*)
    (*Cortex M4*)
    BusFaultExcNum* = 5;
    UsageFaultExcNum* = 6;
    SVCallExcNum* = 11;
    PendSVExcNum* = 14;
    SysTickExcNum* = 15;

    (*STM32F429*)

    (*IRQ numbers*)
    EXTI0_IRQNum* = 16+6; EXTI1_IRQNum* = 16+7; EXTI2_IRQNum* = 16+8; EXTI3_IRQNum* = 16+9; EXTI4_IRQNum* = 16+10;
    EXTI9_5_IRQNum* = 16+23; EXTI15_10_IRQNum* = 16+40;

    (*CRC*)
    CRC_BASE* = 40023000H;
    CRC_DR* = 0;
    CRC_IDR* = 4;

    CRC_CR* = 8; CRC_RESET* = 0;
    crcReset* = PeriphBBAlias + (CRC_BASE + CRC_CR - PeriphBase + CRC_RESET DIV 8)*32 + CRC_RESET MOD 8*4;

    (*EXTI*)
    EXTI_BASE* = 40013C00H; PR* = 14H;

    (*PWR*)
    PWR_BASE* = 40007000H; PWR_CR* = 0;
    DBP* = 8;
    dbp* = PeriphBBAlias + (PWR_BASE + PWR_CR - PeriphBase + DBP DIV 8)*32 + DBP MOD 8*4;

    (*RCC*)
    RCC_BASE* = 40023800H;
    CFGR* = 8; RTCPRE* = {16..20}; (*clock configuration register*)

    AHB1ENR* = 30H; CRCEN* = 12;
    crcEn* = PeriphBBAlias + (RCC_BASE + AHB1ENR - PeriphBase + CRCEN DIV 8)*32 + CRCEN MOD 8*4;

    APB1ENR* = 40H; SPI3EN* = 15; PWREN* = 28; (*APB1 peripheral clock enable register*)
    pwrEn* = PeriphBBAlias + (RCC_BASE + APB1ENR - PeriphBase + PWREN DIV 8)*32 + PWREN MOD 8*4;
    spi3En* = PeriphBBAlias + (RCC_BASE + APB1ENR - PeriphBase + SPI3EN DIV 8)*32 + SPI3EN MOD 8*4;

    BDCR* = 70H; RTCEN* = 15; BDRST* = 16; RTCSEL* = {8..9}; (*backup domain control register*)
    rtcEn* = PeriphBBAlias + (RCC_BASE + BDCR - PeriphBase + RTCEN DIV 8)*32 + RTCEN MOD 8*4;
    bdRst* = PeriphBBAlias + (RCC_BASE + BDCR - PeriphBase + BDRST DIV 8)*32 + BDRST MOD 8*4;

    (*RTC*)
    RTC_BASE* =  40002800H; 
    TR* = 0; RTC_DR* = 4; RTC_CR* = 8; PRER* = 10H; SSR* = 28H; WPR* = 24H; ISR* = 0CH; (*registers*)
    INIT* = 7; INITF* = 6; RSF* = 5;(*flags*)
    rtcInit* = PeriphBBAlias + (RTC_BASE + ISR - PeriphBase + INIT DIV 8)*32 + INIT MOD 8*4;

    (*SPI*)
    SPI2_BASE* = 40003800; SPI3_BASE* = 40003C00H;
    CR1* = 0;
    SPE* = 6; 
    CPHAm* = {0}; CPOLm* = {1};  MSTRm* = {2}; BRm* = {3..5}; SPEm = {SPE}; LSBFIRSTm* = {7}; SSIm* = {8}; SSMm* = {9};
    RXONLYm* = {10}; DFFm* = {11}; CRCNEXTm* = {12}; CECENm = {13}; BIDIOEm* = {14}; BIDIMODEm* = {15};
    BRPS_2* = {}; BRPS_4* = {3}; BRPS_8* = {4}; BRPS_16* = {3,4}; BRPS_32* = {5}; BRPS_64* = {3,5}; BRPS_128* = {4,5}; BRPS_256* = {3..5};
    spe3* = PeriphBBAlias + (SPI3_BASE +CR1 - PeriphBase + SPE DIV 8)*32 + SPE MOD 8*4;
    CR2* = 4;
    I2SCFGR* = 1CH;
    I2SMOD* = 11;
    i2smod3* = PeriphBBAlias + (SPI3_BASE + I2SCFGR - PeriphBase + I2SMOD DIV 8)*32 + I2SMOD MOD 8*4;
    SR* = 08H;
    RXNE* = 0; TXE* = 1; BSY* = 7;
    SPI_DR* = 0CH;

    (*GPIOs*)    
    GPIOA* = 40020000H; GPIOB* = 40020400H; GPIOC* = 40020800H; GPIOD* = 40020C00H; 
    GPIOE* = 40021000H; GPIOF* = 40021400H; GPIOG* = 40021800H; GPIOH* = 40021C00H;
    GPIOI* = 40022000H; GPIOJ* = 40022400H; GPIOK* = 40022800H;
    MODER* = 0; OTYPER* = 4; OSPEEDR* = 8; PUPDR* = 0CH; IDR* = 10H; ODR* = 14H; BSRR* = 18H; AFRL = 20H; AFRH = 24H;
    INPUT_MODE* = {}; OUTPUT_MODE* = {0}; AF_MODE* = {1}; ANALOG_MODE* = {0..1};
    LOW_SPEED* = {}; MEDIUM_SPEED* = {0}; HIGH_SPEED* = {1}; VERY_HIGH_SPEED* = {0..1};
    NO_PULL* = {}; PULL_UP* = {0}; PULL_DOWN* = {1};

    (*base board push buttons*)
    PB1Pin* = 14; PB1Port* = GPIOC; PB1ExtiIrqNum* = EXTI15_10_IRQNum;
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
    LD3Pin* = 13; LD3Port* = GPIOG;
    LD3Out* = PeriphBBAlias + (LD3Port + ODR - PeriphBase + LD3Pin DIV 8)*32 + LD3Pin MOD 8*4;
    LD4Pin* = 14; LD4Port* = GPIOG;
    LD4Out* = PeriphBBAlias + (LD4Port + ODR - PeriphBase + LD4Pin DIV 8)*32 + LD4Pin MOD 8*4;

    (*PS/2 pins*)
    PS2Port = GPIOE;
    PS2CLOCK1Pin* = 2; PS2CLOCK1Port* = PS2Port; PS2CLOCK1ExtiIrqNum* =  EXTI2_IRQNum;
    PS2CLOCK1In* = PeriphBBAlias + (PS2CLOCK1Port + IDR - PeriphBase + PS2CLOCK1Pin DIV 8)*32 + PS2CLOCK1Pin MOD 8*4;
    PS2CLOCK1Out* = PeriphBBAlias + (PS2CLOCK1Port + ODR - PeriphBase + PS2CLOCK1Pin DIV 8)*32 + PS2CLOCK1Pin MOD 8*4;
    PS2DATA1Pin* = 3; PS2DATA1Port* =  PS2Port;
    PS2DATA1In* = PeriphBBAlias + (PS2DATA1Port + IDR - PeriphBase + PS2DATA1Pin DIV 8)*32 + PS2DATA1Pin MOD 8*4;
    PS2DATA1Out* = PeriphBBAlias + (PS2DATA1Port + ODR - PeriphBase + PS2DATA1Pin DIV 8)*32 + PS2DATA1Pin MOD 8*4;
    PS2CLOCK2Pin* = 4; PS2CLOCK2Port* = PS2Port; PS2CLOCK2ExtiIrqNum* =  EXTI4_IRQNum;
    PS2CLOCK2In* = PeriphBBAlias + (PS2CLOCK2Port + IDR - PeriphBase + PS2CLOCK2Pin DIV 8)*32 + PS2CLOCK2Pin MOD 8*4;
    PS2CLOCK2Out* = PeriphBBAlias + (PS2CLOCK2Port + ODR - PeriphBase + PS2CLOCK2Pin DIV 8)*32 + PS2CLOCK2Pin MOD 8*4;
    PS2DATA2Pin* = 5; PS2DATA2Port* =  PS2Port;
    PS2DATA2In* = PeriphBBAlias + (PS2DATA2Port + IDR - PeriphBase + PS2DATA2Pin DIV 8)*32 + PS2DATA2Pin MOD 8*4;
    PS2DATA2Out* = PeriphBBAlias + (PS2DATA2Port + ODR - PeriphBase + PS2DATA2Pin DIV 8)*32 + PS2DATA2Pin MOD 8*4;

    (*SD card pins*)
    WRITE_PROTECTPin* = 4; WRITE_PROTECTPort* = GPIOD;
    WRITE_PROTECTin* = PeriphBBAlias + (WRITE_PROTECTPort + IDR - PeriphBase + WRITE_PROTECTPin DIV 8)*32 + WRITE_PROTECTPin MOD 8*4;
    CARD_DETECTPin* = 5; CARD_DETECTPort* = GPIOD;
    CARD_DETECTin* = PeriphBBAlias + (CARD_DETECTPort + IDR - PeriphBase + CARD_DETECTPin DIV 8)*32 + CARD_DETECTPin MOD 8*4;

    (*nRF24L01+*) NRF24L01P_SMPort = GPIOB; NRF24L01P_MSAFR = AFRL;
    NRF24L01P_MOSIPin* = 6; NRF24L01P_MOSIPort* =  GPIOD; NRF24L01P_MOSIAFR* = AFRL;
    NRF24L01P_IRQPin* = 7; NRF24L01P_IRQPort* = GPIOD;
    NRF24L01P_CEPin* = 9; NRF24L01P_CEPort* = GPIOG;
    NRF24L01P_CEOut* = PeriphBBAlias + (NRF24L01P_CEPort + ODR - PeriphBase + NRF24L01P_CEPin DIV 8)*32 + NRF24L01P_CEPin MOD 8*4;
    NRF24L01P_SCKPin* = 3; NRF24L01P_SCKPort* = NRF24L01P_SMPort;
    NRF24L01P_MISOPin* = 4; NRF24L01P_MISOPort* = NRF24L01P_SMPort;
    NRF24L01P_CSPin* = 7; NRF24L01P_CSPort* =  GPIOB;
    NRF24L01P_CSOut* = PeriphBBAlias + (NRF24L01P_CSPort + ODR - PeriphBase + NRF24L01P_CSPin DIV 8)*32 + NRF24L01P_CSPin MOD 8*4;

    (*nRF24L01+*)
    NRF24L01P_spi* = SPI3_BASE; NRF24L01P_spiEnable* = spe3;

  VAR Leds*: ARRAY 7 OF LONGINT;

  PROCEDURE led*(n: INTEGER);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 6 DO SYSTEM.PUT(Leds[i], ODD(n)); n := n DIV 2 END
  END led;

  PROCEDURE initGPIOs; (*Initialize GPIOs for all sub systems*)
    CONST
      (*PS/2*)
      maskPS2_1b = {PS2CLOCK1Pin, PS2DATA1Pin, PS2CLOCK2Pin, PS2DATA2Pin};
      maskPS2_2b = LSL(MASK2, PS2CLOCK1Pin*2) + LSL(MASK2, PS2DATA1Pin*2) + LSL(MASK2, PS2CLOCK2Pin*2) + LSL(MASK2, PS2DATA2Pin*2);
      omPS2 = LSL(OUTPUT_MODE, PS2CLOCK1Pin*2) + LSL(OUTPUT_MODE, PS2DATA1Pin*2) +
        LSL(OUTPUT_MODE, PS2CLOCK2Pin*2) + LSL(OUTPUT_MODE, PS2DATA2Pin*2);

      maskNRF_1b = {NRF24L01P_SCKPin, NRF24L01P_MISOPin};
      maskNRF_2b = LSL(MASK2, NRF24L01P_SCKPin*2) + LSL(MASK2, NRF24L01P_MISOPin*2);
      maskNRF_4b = LSL(MASK4, NRF24L01P_SCKPin*4) + LSL(MASK4, NRF24L01P_MISOPin*4);
      msNRF = LSL(MEDIUM_SPEED, NRF24L01P_SCKPin*2) + LSL(MEDIUM_SPEED, NRF24L01P_MISOPin*2);
      afNRF = LSL(SYSTEM.VAL(SET, 6), NRF24L01P_SCKPin*4) + LSL(SYSTEM.VAL(SET, 6), NRF24L01P_MISOPin*4);
      afmNRF =  LSL(AF_MODE, NRF24L01P_SCKPin*2) + LSL(AF_MODE, NRF24L01P_MISOPin*2);

    VAR reg: SET;
  BEGIN
   (*PS/2*)
    SYSTEM.GET(PS2Port + OSPEEDR, reg); SYSTEM.PUT(PS2Port + OSPEEDR, reg - maskPS2_2b); (*all pins are low speed*)
    SYSTEM.GET(PS2Port + OTYPER, reg); SYSTEM.PUT(PS2Port + OTYPER, reg + maskPS2_1b); (*all pins are open-drain*)
    SYSTEM.GET(PS2Port + PUPDR, reg); SYSTEM.PUT(PS2Port + PUPDR, reg - maskPS2_2b); (*all pins have no pullups nor pulldowns*)
    SYSTEM.GET(PS2Port + MODER, reg); SYSTEM.PUT(PS2Port + MODER, reg - maskPS2_2b + omPS2); (*all pins are output*)

    (*SPI3 for nRF24L01+*)
    (*MOSI*)
    SYSTEM.GET(NRF24L01P_MOSIPort + OSPEEDR, reg); 
    SYSTEM.PUT(NRF24L01P_MOSIPort + OSPEEDR, reg - LSL(MASK2, NRF24L01P_MOSIPin*2) + LSL(MEDIUM_SPEED, NRF24L01P_MOSIPin*2));

    SYSTEM.GET(NRF24L01P_MOSIPort + OTYPER, reg); SYSTEM.PUT(NRF24L01P_MOSIPort + OTYPER, reg - {NRF24L01P_MOSIPin}); (*output push-pull*)

    SYSTEM.GET(NRF24L01P_MOSIPort + PUPDR, reg);
    SYSTEM.PUT(NRF24L01P_MOSIPort + PUPDR, reg - LSL(MASK2, NRF24L01P_MOSIPin*2)); (*no pullup nor pulldown*)

    SYSTEM.GET(NRF24L01P_MOSIPort + NRF24L01P_MOSIAFR, reg);
    SYSTEM.PUT(NRF24L01P_MOSIPort + NRF24L01P_MOSIAFR,
      reg - LSL(MASK4, NRF24L01P_MOSIPin*4) + SYSTEM.VAL(SET, LSL(5, NRF24L01P_MOSIPin*4)));(*AF5: MOSI*)

    SYSTEM.GET(NRF24L01P_MOSIPort + MODER, reg);
    SYSTEM.PUT(NRF24L01P_MOSIPort + MODER,reg - LSL(MASK2, NRF24L01P_MOSIPin*2) + LSL(AF_MODE, NRF24L01P_MOSIPin*2)); (*alternate function mode*)

    (*SCK, MISO*)
    SYSTEM.GET(NRF24L01P_SMPort + OSPEEDR, reg); SYSTEM.PUT(NRF24L01P_SMPort + OSPEEDR, reg - maskNRF_2b + msNRF); (*pins are medium speed*)
    SYSTEM.GET(NRF24L01P_SMPort + OTYPER, reg); SYSTEM.PUT(NRF24L01P_SMPort + OTYPER, reg - maskNRF_1b); (*output push-pull*)
    SYSTEM.GET(NRF24L01P_SMPort + PUPDR, reg); SYSTEM.PUT(NRF24L01P_SMPort + PUPDR, reg - maskNRF_2b); (*no pullup nor pulldown*)
    SYSTEM.GET(NRF24L01P_SMPort + NRF24L01P_MSAFR, reg); SYSTEM.PUT(NRF24L01P_SMPort + NRF24L01P_MSAFR, reg - maskNRF_4b + afNRF);(*AF6: SCK, MISO*)
    SYSTEM.GET(NRF24L01P_SMPort + MODER, reg); SYSTEM.PUT(NRF24L01P_SMPort + MODER, reg - maskNRF_2b + afmNRF); (*alternate function mode*)

  END initGPIOs;

  PROCEDURE InitCRC*;
    VAR res: BYTE;
  BEGIN SYSTEM.PUT(crcEn, TRUE); (*enable CRC clock*) SYSTEM.GET(crcEn, res); (*delay*)
  END InitCRC;

  PROCEDURE InitNRF24L01P*;
    VAR res: BYTE;
  BEGIN (*SPI3*) SYSTEM.PUT(spi3En, TRUE); (*enable power interface clock*) SYSTEM.GET(spi3En, res); (*delay*)
    SYSTEM.PUT(spe3, FALSE); (*disable SPI3 peripheral*)
    SYSTEM.PUT(SPI3_BASE + CR1, MSTRm + SSIm + SSMm + BRPS_8); (*Master, software slave management, DIV 8 prescaler*)
    SYSTEM.PUT(SPI3_BASE + CR2, 0);
    SYSTEM.PUT(i2smod3, FALSE); (*make sure that SPI3 is in SPI mode*)
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
    SYSTEM.GET(RCC_BASE + CFGR, cfgr); SYSTEM.PUT(RCC_BASE + CFGR, ORD(cfgr - RTCPRE) + LSL(16, 16)); (*sets RTC division factor to 16*)
    SYSTEM.PUT(rtcEn, TRUE); (*enable RTC clock*)

    SYSTEM.PUT(RTC_BASE + WPR, 0CAH); SYSTEM.PUT(RTC_BASE + WPR, 53H); (*disable write protection on RTC registers*)
    SYSTEM.PUT(rtcInit, TRUE); (*put RTC in init mode*)
    REPEAT UNTIL SYSTEM.BIT(RTC_BASE + ISR, INITF); (*RTC is now in init mode*)
    SYSTEM.PUT(RTC_BASE + RTC_CR, 0); (*24 hour/day format, output disabled*)
    SYSTEM.PUT(RTC_BASE + PRER, 3999); (*two access are required, with synchronous prescaler first. Value is 3999*)
    SYSTEM.PUT(RTC_BASE + PRER, LSL(124, 16) + 3999); (*then write asynchronous prescaler factor. Value is 124*)
    SYSTEM.PUT(rtcInit, FALSE); (*exit RTC from init mode*)
    SYSTEM.PUT(WPR, 0FFH); (*enable write protection on RTC registers*)
  END InitRTC;

  PROCEDURE Init*;
  BEGIN initGPIOs;
    Leds[0] := LED1Out; Leds[1] := LED2Out; Leds[2] := LED3Out; Leds[3] := LED4Out; 
    Leds[4] := LED5Out; Leds[5] := LED6Out; Leds[6] := LED7Out
  END Init;

END BSP.
