MODULE BSP; (*CS 06.03.24 STM32F429I-DISCO Oberon base board abstraction*)
  IMPORT SYSTEM;

  CONST  (*STM32F429*)
    (*GPIOs*)
    PeriphBase* = 40000000H; PeriphBBAlias* = 42000000H;
    
    GPIOA* = 40020000H; GPIOB* = 40020400H; GPIOC* = 40020800H; GPIOD* = 40020C00H; 
    GPIOE* = 40021000H; GPIOF* = 40021400H; GPIOG* = 40021800H; GPIOH* = 40021C00H;
    GPIOI* = 40022000H; GPIOJ* = 40022400H; GPIOK* = 40022800H;
    IDR = 10H; ODR = 14H; BSRR = 18H;

    PB1Pin* = 14; PB1Port* = GPIOC; (*PB1_EXTI_IRQn EXTI15_10_IRQn*)
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

(*
#define PS2_CLOCK_1_Pin GPIO_PIN_2
#define PS2_CLOCK_1_GPIO_Port GPIOE
#define PS2_CLOCK_1_EXTI_IRQn EXTI2_IRQn
#define PS2_DATA_1_Pin GPIO_PIN_3
#define PS2_DATA_1_GPIO_Port GPIOE
#define PS2_CLOCK_2_Pin GPIO_PIN_4
#define PS2_CLOCK_2_GPIO_Port GPIOE
#define PS2_CLOCK_2_EXTI_IRQn EXTI4_IRQn
#define PS2_DATA_2_Pin GPIO_PIN_5
#define PS2_DATA_2_GPIO_Port GPIOE
#define WRITE_PROTECT_Pin GPIO_PIN_4
#define WRITE_PROTECT_GPIO_Port GPIOD
#define CARD_DETECT_Pin GPIO_PIN_5
#define CARD_DETECT_GPIO_Port GPIOD
#define NRF24L01P_MOSI_Pin GPIO_PIN_6
#define NRF24L01P_MOSI_GPIO_Port GPIOD
#define NRF24L01P_IRQ_Pin GPIO_PIN_7
#define NRF24L01P_IRQ_GPIO_Port GPIOD
#define NRF24L01P_CE_Pin GPIO_PIN_9
#define NRF24L01P_CE_GPIO_Port GPIOG
#define NRF24L01P_SCK_Pin GPIO_PIN_3
#define NRF24L01P_SCK_GPIO_Port GPIOB
#define NRF24L01P_MISO_Pin GPIO_PIN_4
#define NRF24L01P_MISO_GPIO_Port GPIOB
#define NRF24L01P_CS_Pin GPIO_PIN_7
#define NRF24L01P_CS_GPIO_Port GPIOB
*)

  VAR Leds*: ARRAY 7 OF LONGINT;

  PROCEDURE led*(n: INTEGER);
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 6 DO SYSTEM.PUT(Leds[i], ODD(n)); n := n DIV 2 END
  END led;

  PROCEDURE Init*;
  BEGIN Leds[0] := LED1Out; Leds[1] := LED2Out; Leds[2] := LED3Out; Leds[3] := LED4Out; 
    Leds[4] := LED5Out; Leds[5] := LED6Out; Leds[6] := LED7Out
  END Init;

END BSP.

OM4Tool.DecObj BSP.m4c
