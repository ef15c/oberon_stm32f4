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
    PWR_BASE* = 40007000H;
    PWR_CR* = 0; DBP* = 8;
    dbp* = PeriphBBAlias + (PWR_BASE + PWR_CR - PeriphBase + DBP DIV 8)*32 + DBP MOD 8*4;

    (*RCC*)
    HCLCFreq* = 168; PCLK1Freq* = 42; PCLK2Freq* = 84;(*MHz*)

    RCC_BASE* = 40023800H;
    CFGR* = 8; RTCPRE* = {16..20}; (*clock configuration register*)

    AHB1ENR* = 30H; CRCEN* = 12; GPIOAEN* = 0; GPIOBEN* = 1; GPIOCEN* = 2; GPIODEN* = 3; GPIOEEN* = 4; GPIOFEN* = 5;
      GPIOGEN* = 6; GPIOHEN* = 7; GPIOIEN* = 8; GPIOJEN* = 9; GPIOKEN* = 10;
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


    APB1ENR* = 40H; SPI3EN* = 15; PWREN* = 28; (*APB1 peripheral clock enable register*)
    pwrEn* = PeriphBBAlias + (RCC_BASE + APB1ENR - PeriphBase + PWREN DIV 8)*32 + PWREN MOD 8*4;
    spi3En* = PeriphBBAlias + (RCC_BASE + APB1ENR - PeriphBase + SPI3EN DIV 8)*32 + SPI3EN MOD 8*4;

    APB2ENR* = 44H; USART1EN* = 4;
    usart1En* = PeriphBBAlias + (RCC_BASE +APB2ENR - PeriphBase + USART1EN DIV 8)*32 + USART1EN MOD 8*4;

    BDCR* = 70H; RTCEN* = 15; BDRST* = 16; RTCSEL* = {8..9}; (*backup domain control register*)
    rtcEn* = PeriphBBAlias + (RCC_BASE + BDCR - PeriphBase + RTCEN DIV 8)*32 + RTCEN MOD 8*4;
    bdRst* = PeriphBBAlias + (RCC_BASE + BDCR - PeriphBase + BDRST DIV 8)*32 + BDRST MOD 8*4;

    (*RTC*)
    RTC_BASE* =  40002800H; 
    TR* = 0; RTC_DR* = 4; RTC_CR* = 8; PRER* = 10H; SSR* = 28H; WPR* = 24H;

    ISR* = 0CH; INIT* = 7; INITF* = 6; RSF* = 5;(*flags*)
    rtcInit* = PeriphBBAlias + (RTC_BASE + ISR - PeriphBase + INIT DIV 8)*32 + INIT MOD 8*4;

    (*SPI*)
    SPI2_BASE* = 40003800; SPI3_BASE* = 40003C00H;
    SPI_CR1* = 0; SPE* = 6;
    SPI_CPHAm* = {0}; SPI_CPOLm* = {1};  MSTRm* = {2}; BRm* = {3..5}; SPEm = {SPE}; LSBFIRSTm* = {7}; SSIm* = {8}; SSMm* = {9};
    RXONLYm* = {10}; DFFm* = {11}; CRCNEXTm* = {12}; CECENm = {13}; BIDIOEm* = {14}; BIDIMODEm* = {15};
    BRPS_2* = {}; BRPS_4* = {3}; BRPS_8* = {4}; BRPS_16* = {3,4}; BRPS_32* = {5}; BRPS_64* = {3,5}; BRPS_128* = {4,5}; BRPS_256* = {3..5};
    spe3* = PeriphBBAlias + (SPI3_BASE +SPI_CR1 - PeriphBase + SPE DIV 8)*32 + SPE MOD 8*4;

    SPI_CR2* = 4;

    I2SCFGR* = 1CH; I2SMOD* = 11;
    i2smod3* = PeriphBBAlias + (SPI3_BASE + I2SCFGR - PeriphBase + I2SMOD DIV 8)*32 + I2SMOD MOD 8*4;

    SPI_SR* = 08H; SPI_RXNE* = 0; SPI_TXE* = 1; BSY* = 7;

    SPI_DR* = 0CH;

    (*USART*)
    USART1_BASE* = 40011000H;
    USART_SR* = 0; USART_TXE* = 7; USART_RXNE* = 5;

    USART_DR* = 4;

    USART_BRR* = 8; DIV_Mantissa* = {4..15}; DIV_Fraction* = {0..3};

    USART_CR1* = 0CH; UE* = 13;
    OVER8m* = {15}; UEm* = {UE}; Mm* = {12}; WAKEm* = {11}; PCEm* = {10}; PSm* = {9}; PEIEm* = {8}; TXEIEm* = {7}; TCIEm* = {6};
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

    (*Display*)
    DisplayPortsEnS* = {GPIOAEN, GPIOBEN, GPIOCEN, GPIODEN, GPIOFEN, GPIOGEN};

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

  VAR Leds*: ARRAY 7 OF LONGINT;

  PROCEDURE led*(n: INTEGER);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 6 DO SYSTEM.PUT(Leds[i], ODD(n)); n := n DIV 2 END
  END led;

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
    VAR en: BYTE;
  BEGIN SYSTEM.PUT(gpioeEn, TRUE); SYSTEM.GET(gpioeEn, en); (*delay*)
    configureGPIO(GPIOE, mask_1b, mask_2b, {}, {}, om, {}, od, {}, {}, {}); (*all pins are output, low speed, open-drain, no pullups nor pulldowns*)
  END PS2_initGPIOs;

  PROCEDURE NRF_initGPIOs; (*nrf24L01+*)
    CONST mask_1b = {NRF24L01P_SCKPin, NRF24L01P_MISOPin};
      mask_2b = LSL(MASK2, NRF24L01P_SCKPin*2) + LSL(MASK2, NRF24L01P_MISOPin*2);
      mask_4b = LSL(MASK4, NRF24L01P_SCKPin*4) + LSL(MASK4, NRF24L01P_MISOPin*4);
      afm =  LSL(AF_MODE, NRF24L01P_SCKPin*2) + LSL(AF_MODE, NRF24L01P_MISOPin*2);
      ms = LSL(MEDIUM_SPEED, NRF24L01P_SCKPin*2) + LSL(MEDIUM_SPEED, NRF24L01P_MISOPin*2);
      af = LSL(SYSTEM.VAL(SET, 6), NRF24L01P_SCKPin*4) + LSL(SYSTEM.VAL(SET, 6), NRF24L01P_MISOPin*4); (*AF6*)
    VAR en: BYTE;
  BEGIN
    (*SPI3 for nRF24L01+*)
    (*MOSI*) SYSTEM.PUT(gpiobEn, TRUE); SYSTEM.PUT(gpiodEn, TRUE); SYSTEM.GET(gpiodEn, en); (*delay*)
    configureGPIO(GPIOD, {NRF24L01P_MOSIPin}, LSL(MASK2, NRF24L01P_MOSIPin*2), LSL(MASK4, NRF24L01P_MOSIPin*4), {},
      LSL(AF_MODE, NRF24L01P_MOSIPin*2), LSL(MEDIUM_SPEED, NRF24L01P_MOSIPin*2), {}, {}, SYSTEM.VAL(SET, LSL(5, NRF24L01P_MOSIPin*4)), {}); (*AF5: MOSI*)
    configureGPIO(GPIOB, mask_1b, mask_2b, mask_4b, {}, afm, ms, {}, {}, af, {});
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

  PROCEDURE initGPIOs; (*Initialize GPIOs for all sub systems*)
    VAR reg: SET;
  BEGIN
    (*Display*) SYSTEM.GET(RCC_BASE + AHB1ENR, reg); SYSTEM.PUT(RCC_BASE + AHB1ENR, reg + DisplayPortsEnS);
    SYSTEM.GET(RCC_BASE + AHB1ENR, reg); (*delay*)
(*TODO*)

    PS2_initGPIOs; NRF_initGPIOs; UART_initGPIOs
  END initGPIOs;

  PROCEDURE InitCRC*;
    VAR res: BYTE;
  BEGIN SYSTEM.PUT(crcEn, TRUE); (*enable CRC clock*) SYSTEM.GET(crcEn, res); (*delay*)
  END InitCRC;

  PROCEDURE InitDisplay*;
    VAR res: BYTE;
  BEGIN (*LTDC*)
  END InitDisplay;

  PROCEDURE InitNRF24L01P*;
    VAR res: BYTE; isStarted: BOOLEAN;
  BEGIN (*SPI3*) SYSTEM.PUT(spi3En, TRUE); (*enable SPI3 clock*) SYSTEM.GET(spi3En, res); (*delay*)
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

  PROCEDURE InitUART*;
    CONST mantissa = PCLK2Freq*1000000 DIV (16*115200);
      fraction = (PCLK2Freq*1000000 - 16*115200*mantissa) DIV 115200;
    VAR res: BYTE; cr: SET;
  BEGIN (*USART1*) SYSTEM.PUT(usart1En, TRUE); (*enable USART1 clock*) SYSTEM.GET(usart1En, res); (*delay*)
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

  PROCEDURE Init*;
  BEGIN initGPIOs;
    Leds[0] := LED1Out; Leds[1] := LED2Out; Leds[2] := LED3Out; Leds[3] := LED4Out; 
    Leds[4] := LED5Out; Leds[5] := LED6Out; Leds[6] := LED7Out
  END Init;

END BSP.
