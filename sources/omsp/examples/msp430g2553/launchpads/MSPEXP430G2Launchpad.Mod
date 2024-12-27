(*
 * main.c
 *
 * MSP-EXP430G2-LaunchPad User Experience Application
 *
 * Copyright (C) 2011 Texas Instruments Incorporated - http://www.ti.com/
 *
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/


/******************************************************************************
 *                  MSP-EXP430G2-LaunchPad User Experience Application
 *
 * 1. Device starts up in LPM3 + blinking LED to indicate device is alive
 *    + Upon first button press, device transitions to application mode
 * 2. Application Mode
 *    + Continuously sample ADC Temp Sensor channel, compare result against
 *      initial value
 *    + Set PWM based on measured ADC offset: Red LED for positive offset, Green
 *      LED for negative offset
 *    + Transmit temperature value via TimerA UART to PC
 *    + Button Press --> Calibrate using current temperature
 *                       Send character '\B0' via UART, notifying PC
 *
 * Changes:
 *
 * 1.2  + Updated register naming conventions to reflect latest standard by TI
 * 	         e.g.: CCR0 --> TACCR0, CCTL0 --> TACCTL0
 * 	    + Changed method to capture TAR value into TACCR0 by using capture a
 * 	      SW-triggered event. [Changing TACCR input from GND to VCC]
 * 1.1  + LED1 & LED2 labels changed so that Green LED(LED2) indicates sampled
 *        temperature colder than calibrated temperature and vice versa
 *        with Red LED (LED1).
 *      + Turn off peripheral function of TXD after transmitting byte to
 *        eliminate the extra glitch at the end of UART transmission
 * 1.0  Initial Release Version
 *
 * Texas Instruments, Inc.
 ******************************************************************************)

MODULE MSPEXP430G2Launchpad;
  IMPORT SYSTEM, M := msp430g2553, MP := MultiPrecisionArith;

  CONST LED1 = {0}; LED2 = {6};
    LED_DIR = M.P1DIR;
    LED_OUT = M.P1OUT;

    BUTTON = {3};
    BUTTON_OUT = M.P1OUT;
    BUTTON_DIR = M.P1DIR;
    BUTTON_IN = M.P1IN;
    BUTTON_IE = M.P1IE;
    BUTTON_IES = M.P1IES;
    BUTTON_IFG = M.P1IFG;
    BUTTON_REN = M.P1REN;

    TXD = {1}; (* TXD on P1.1 *) RXD = {2}; (* RXD on P1.2*)

    APP_STANDBY_MODE =  0; APP_APPLICATION_MODE = 1;

    TIMER_PWM_MODE = 0; TIMER_UART_MODE = 1;
    TIMER_PWM_PERIOD = 2000; TIMER_PWM_OFFSET = 20;

    TEMP_SAME = 0; TEMP_HOT = 1; TEMP_COLD = 2;

    TEMP_THRESHOLD = 5;

    (* Conditions for 9600/4=2400 Baud SW UART, SMCLK = 1MHz *)
    Bitime_5 = 5*4; (* ~ 0.5 bit length + small adjustment *)
    Bitime = 13*4; (*0DH *)

    UART_UPDATE_INTERVAL = 1000;

  VAR BitCnt : BYTE;
    applicationMode, timerMode, tempMode: BYTE;
    tempPolarity: BYTE;
    calibrateUpdate: BOOLEAN;
    TXByte: INTEGER;

    (* Using an 8-value moving average filter on sampled ADC values *)
    tempMeasured: ARRAY 8 OF INTEGER;
    tempMeasuredPosition: BYTE;
    tempAverage, tempCalibrated, tempDifference: INTEGER;
    tmpH: INTEGER;

    uartUpdateTimer: INTEGER;
    i: BYTE;

  PROCEDURE InitializeClocks;
  BEGIN
    M.BCSCTL1^ := M.CALBC1_1MHZ^; (* Set range *)
    M.DCOCTL^ := M.CALDCO_1MHZ^;
    BIC(M.BCSCTL2^, M.DIVS_3) (* SMCLK = DCO = 1MHz *)
  END InitializeClocks;

  PROCEDURE InitializeButton; (* Configure Push Button *)
  BEGIN
    BIC(BUTTON_DIR^, BUTTON);
    BIS(BUTTON_OUT^, BUTTON);
    BIS(BUTTON_REN^, BUTTON);
    BIS(BUTTON_IES^, BUTTON);
    BIC(BUTTON_IFG^, BUTTON);
    BIS(BUTTON_IE^, BUTTON)
  END InitializeButton;

  PROCEDURE InitializeLeds;
  BEGIN
    BIS(LED_DIR^, LED1 + LED2);
    BIC(LED_OUT^, LED1 + LED2)
  END InitializeLeds;

  PROCEDURE PreApplicationMode; (* Blinks LED, waits for button press *)
  BEGIN
    BIS(LED_OUT^, LED1); (* To enable the LED toggling effect *)
    BIC(LED_OUT^, LED2);

    BIS(M.BCSCTL1^, M.DIVA_1); (* ACLK/2 *)
    BIS(M.BCSCTL3^, M.LFXT1S_2); (* ACLK = VLO *)

    M.TA0CCR0^ := 1200;
    M.TA0CTL^ := M.TASSEL_1 + M.MC_1; (* TACLK = SMCLK, Up mode. *)
    M.TA0CCTL1^ := M.CCIE + M.OUTMOD_3; (* TACCTL1 Capture Compare *)
    M.TA0CCR1^ := 600;
    SYSTEM.BIS_SR(M.LPM3_bits + M.GIE) (* LPM0 with interrupts enabled *)
  END PreApplicationMode;

  PROCEDURE ConfigureAdcTempSensor;
    VAR i: BYTE*;
  BEGIN
    (* Configure ADC Temp Sensor Channel *)
    M.ADC10CTL1^ := M.INCH_10 + M.ADC10DIV_3; (* Temp Sensor ADC10CLK/4 *)
    M.ADC10CTL0^ := M.SREF_1 + M.ADC10SHT_3 + M.REFON + M.ADC10ON + M.ADC10IE;
    FOR i := 1 TO 1000 DO NOP END; (* TODO __delay_cycles(1000);*) (* Wait for ADC Ref to settle *)
    BIS(M.ADC10CTL0^, M.ENC + M.ADC10SC) ; (* Sampling and conversion start *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE); (* LPM0 with interrupts enabled *)
    tempCalibrated := M.ADC10MEM^;
    FOR i := 0 TO 7 DO tempMeasured[i] := tempCalibrated END;
    tempAverage := tempCalibrated
  END ConfigureAdcTempSensor;

  PROCEDURE ConfigureTimerPwm;
  BEGIN
    timerMode := TIMER_PWM_MODE;

    M.TA0CCR0^ := TIMER_PWM_PERIOD;
    M.TA0CTL^ := M.TASSEL_2 + M.MC_1; (* TACLK = SMCLK, Up mode. *)
    M.TA0CCTL0^ := M.CCIE;
    M.TA0CCTL1^ := M.CCIE + M.OUTMOD_3; (* TACCTL1 Capture Compare *)
    M.TA0CCR1^ := 1
  END ConfigureTimerPwm;

  PROCEDURE ConfigureTimerUart;
  BEGIN
    timerMode := TIMER_UART_MODE; (* Configure TimerA0 UART TX *)

    M.TA0CCTL0^ := M.OUT; (* TXD Idle as Mark *)
    M.TA0CTL^ := M.TASSEL_2 + M.MC_2 + M.ID_3; (* SMCLK/8, continuous mode *)
    BIS(M.P1SEL^, TXD + RXD);
    BIS(M.P1DIR^, TXD)
  END ConfigureTimerUart;

(* Function Transmits Character from TXByte *)
  PROCEDURE Transmit;
  BEGIN BitCnt := 10; (* Load Bit counter, 8data + ST/SP *)
    (* Simulate a timer capture event to obtain the value of TAR into the TACCR0 register *)
    M.TA0CCTL0^ := M.CM_1 + M.CCIS_2  + M.SCS + M.CAP + M.OUTMOD0; (* capture on rising edge, initially set to GND as input // clear CCIFG flag *)
    BIS(M.TA0CCTL0^, M.CCIS_3); (*change input to Vcc, effectively rising the edge, triggering the capture action *)

    REPEAT UNTIL BIT(M.TA0CCTL0^, M.CCIFG); (*allowing for the capturing//updating TACCR0. *)

    INC(M.TA0CCR0^, Bitime); (* Some time till first bit *)
    BIS(TXByte, {8}); (* Add mark stop bit to TXByte *)
    RLA(TXByte, 1); (* Add space start bit *)
    M.TA0CCTL0^ :=  M.CCIS0 + M.OUTMOD0 + M.CCIE; (* TXD = mark = idle *)

    REPEAT UNTIL ~BIT(M.TA0CCTL0^, M.CCIE) (* Wait for TX completion *)
  END Transmit;

  (* Timer A0 interrupt service routine *)
  PROCEDURE* (M.TIMER0_A0_VECTOR) Timer_A;
  BEGIN
    IF timerMode = TIMER_UART_MODE THEN
      INC(M.TA0CCR0^, Bitime); (* Add Offset to TACCR0 *)
      IF BIT(M.TA0CCTL0^, M.CCIS0) THEN (* TX on CCI0B? *)
        IF BitCnt = 0 THEN
          BIC(M.P1SEL^, TXD+RXD);
          BIC(M.TA0CCTL0^, M.CCIE); (* All bits TXed, disable interrupt *)
        ELSE
          BIS(M.TA0CCTL0^, M.OUTMOD2); (* TX Space *)
          IF ODD(TXByte) THEN BIC(M.TA0CCTL0^, M.OUTMOD2) END; (* TX Mark *)
          RRA(TXByte, 1); DEC(BitCnt)
        END
      END
    ELSE
      IF tempPolarity = TEMP_HOT THEN  BIS(LED_OUT^, LED1)
      ELSIF tempPolarity = TEMP_COLD THEN BIS(LED_OUT^, LED2) END;
      BIC(M.TA0CCTL0^, M.CCIFG)
    END
  END Timer_A;

  PROCEDURE* (M.TIMER0_A1_VECTOR) ta1_isr;
  BEGIN BIC(M.TA0CCTL1^, M.CCIFG);
    IF applicationMode = APP_APPLICATION_MODE THEN BIC(LED_OUT^, LED1 + LED2) ELSE XOR(LED_OUT^, LED1 + LED2) END
  END ta1_isr;

  (* *************************************************************
   * Port Interrupt for Button Press
   * 1. During standby mode: to exit and enter application mode
   * 2. During application mode: to recalibrate temp sensor
   * *********************************************************** *)
  PROCEDURE* (M.PORT1_VECTOR) PORT1_ISR;
  BEGIN
    BUTTON_IFG^ := {};
    BIC(BUTTON_IE^, BUTTON); (* Debounce *)
    M.WDTCTL^ := M.WDT_ADLY_250;
    BIC(M.IFG1^, M.WDTIFG); (* clear interrupt flag *)
    BIS(M.IE1^, M.WDTIE);

    IF applicationMode = APP_APPLICATION_MODE THEN tempCalibrated := tempAverage; calibrateUpdate  := TRUE;
    ELSE
      applicationMode := APP_APPLICATION_MODE; (* Switch from STANDBY to APPLICATION MODE *)
      SYSTEM.BIC_SR_ON_EXIT(M.LPM3_bits)
    END
  END PORT1_ISR;

  (* WDT Interrupt Service Routine used to de-bounce button press *)
  PROCEDURE* (M.WDT_VECTOR) WDT_ISR;
  BEGIN
    BIC(M.IE1^, M.WDTIE); (** disable interrupt *)
    BIC(M.IFG1^, M.WDTIFG); (* clear interrupt flag *)
    M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* put WDT back in hold state *)
    BIS(BUTTON_IE^, BUTTON) (* Debouncing complete *)
  END WDT_ISR;

  (* ADC10 interrupt service routine *)
  PROCEDURE* (M.ADC10_VECTOR) ADC10_ISR;
  BEGIN SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Return to active mode *)
  END ADC10_ISR;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop WDT *)

  applicationMode := APP_STANDBY_MODE; timerMode := TIMER_PWM_MODE;
  calibrateUpdate := FALSE; tempPolarity := TEMP_SAME;
  tempMeasuredPosition := 0;
  uartUpdateTimer := UART_UPDATE_INTERVAL;

  InitializeClocks; InitializeButton; InitializeLeds;
  PreApplicationMode; (* Blinks LEDs, waits for button press *)

  (* Application Mode begins *)
  applicationMode := APP_APPLICATION_MODE;
  ConfigureAdcTempSensor; ConfigureTimerPwm;

  SYSTEM.BIS_SR(M.GIE); (* Enable interrupts. *)

  (* Main Application Loop *)
  REPEAT
    BIS(M.ADC10CTL0^, M.ENC + M.ADC10SC); (* Sampling and conversion start *)
    SYSTEM.BIS_SR(M.CPUOFF +M. GIE); (* LPM0 with interrupts enabled *)

    (* Moving average filter out of 8 values to somewhat stabilize sampled ADC *)
    tempMeasured[tempMeasuredPosition] := M.ADC10MEM^; INC(tempMeasuredPosition);
    IF tempMeasuredPosition = 8 THEN tempMeasuredPosition := 0 END;
    tempAverage := 0; FOR i := 0 TO 7 DO INC(tempAverage, tempMeasured[i]) END; RRA(tempAverage, 3); (* Divide by 8 to get average *)

    DEC(uartUpdateTimer);
    IF (uartUpdateTimer = 0) OR calibrateUpdate THEN
      ConfigureTimerUart;
      IF calibrateUpdate THEN
        TXByte := 248; (* A character with high value, outside of temp range *) Transmit;
        calibrateUpdate := FALSE
      END;

      (* TXByte := ((tempAverage - 630) * 761) / 1024 ); *)
      MP.SetLongInt(tmpH, TXByte, tempAverage); MP.SubLongInt(tmpH, TXByte, 630);
      MP.MulLongInt(tmpH, TXByte, 761); MP.ASRLongInt(tmpH, TXByte, 10);
      Transmit;

      uartUpdateTimer := UART_UPDATE_INTERVAL;
      ConfigureTimerPwm;
    END;

    tempDifference := tempAverage - tempCalibrated;
    IF tempDifference < -TEMP_THRESHOLD THEN tempDifference := -tempDifference;
      tempPolarity := TEMP_COLD; BIC(LED_OUT^, LED1)
    ELSIF tempDifference > TEMP_THRESHOLD THEN
      tempPolarity := TEMP_HOT; BIC(LED_OUT^, LED2)
    ELSE
      tempPolarity := TEMP_SAME;
      BIC(M.TA0CCTL0^, M.CCIE);
      BIC(M.TA0CCTL1^, M.CCIE);
      BIC(LED_OUT^, LED1 + LED2)
    END;

    IF tempPolarity # TEMP_SAME THEN
      RLA(tempDifference, 3);
      INC(tempDifference, TIMER_PWM_OFFSET);
      IF tempDifference < TIMER_PWM_PERIOD-1 THEN M.TA0CCR1^ := tempDifference ELSE M.TA0CCR1^ := TIMER_PWM_PERIOD-1 END;
      BIS(M.TA0CCTL0^, M.CCIE);
      BIS(M.TA1CCTL1^, M.CCIE)
    END
  UNTIL FALSE
END MSPEXP430G2Launchpad.

OMSPL.Link 32 4000H 200H MSPEXP430G2Launchpad ~
  linking msp430g2553 MultiPrecisionArith MSPEXP430G2Launchpad, flash 1330, data   38, stack  474 bytes

OMSPTool.DecObj MSPEXP430G2Launchpad.mpc
decode MSPEXP430G2Launchpad.mpc
MSPEXP430G2Launchpad 51A3A09D Flash   938
imports:
	msp430g2553 F10488DC
	MultiPrecisionArith B561C064
type descriptors

data    38
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF 0000 FFFF FFFF 0000 FFFF FFFF 0000 0000 0000 FFFF FFFF FFFF FFFF FFFF

entries
 c 0202
fixup procedures chains
 0224     0	 0000
 0228     0	 0014
 022C     0	 002E
 0230     0	 003C
 0238     0	 0070
 030E     0	 00C0
 02AC     0	 00E2
 0304     0	 00FC
 0300     2	 0008
 02F0     2	 0006
 02E0     2	 0003
 02D0     2	 0002
fixup handlers chains
 0119     0	 0136
 0118     0	 0198
 0112     0	 01B2
 011A     0	 01E6
 0115     0	 01FA
fixup data chains
 0316     0	 001C
 0284     0	 0008
 0312     0	 001A
 020E     0	 0002
 0176     0	 0000
 02F8     0	 0006
 0368     0	 0004
 0234     0	 0001
 02C0     0	 0005
 0266     0	 0018
 030A     0	 0022
 027E     0	 0024
 02F4     0	 0020
 038E     0	 001E
fixup constants chains
fixup types chains
entry =  0202
code   938
 0000	     42D2	MOV.B &4351,&87
 0002	     10FF
 0004	     0057
 0006	     42D2	MOV.B &4350,&86
 0008	     10FE
 000A	     0056
 000C	     C0F2	BIC.B #6,&88
 000E	     0006
 0010	     0058
 0012	     4130	RET
 0014	     C2F2	BIC.B #8,&34
 0016	     0022
 0018	     D2F2	BIS.B #8,&33
 001A	     0021
 001C	     D2F2	BIS.B #8,&39
 001E	     0027
 0020	     D2F2	BIS.B #8,&36
 0022	     0024
 0024	     C2F2	BIC.B #8,&35
 0026	     0023
 0028	     D2F2	BIS.B #8,&37
 002A	     0025
 002C	     4130	RET
 002E	     D0F2	BIS.B #65,&34
 0030	     0041
 0032	     0022
 0034	     C0F2	BIC.B #65,&33
 0036	     0041
 0038	     0021
 003A	     4130	RET
 003C	     D3D2	BIS.B #1,&33
 003E	     0021
 0040	     C0F2	BIC.B #64,&33
 0042	     0040
 0044	     0021
 0046	     D0F2	BIS.B #16,&87
 0048	     0010
 004A	     0057
 004C	     D0F2	BIS.B #32,&83
 004E	     0020
 0050	     0053
 0052	     40B2	MOV #1200,&370
 0054	     04B0
 0056	     0172
 0058	     40B2	MOV #272,&352
 005A	     0110
 005C	     0160
 005E	     40B2	MOV #112,&356
 0060	     0070
 0062	     0164
 0064	     40B2	MOV #600,&372
 0066	     0258
 0068	     0174
 006A	     D032	BIS #216,SR
 006C	     00D8
 006E	     4130	RET
 0070	     40B2	MOV #-24480,&434
 0072	     A060
 0074	     01B2
 0076	     40B2	MOV #14392,&432
 0078	     3838
 007A	     01B0
 007C	     4354	MOV.B #1,R4
 007E	     4035	MOV #1000,R5
 0080	     03E8
 0082	     9405	CMP R4,R5
 0084	     3803	JL $+8, goes to  008C
 0086	     4303	NOP
 0088	     5314	ADD #1,R4
 008A	     3FF9	JMP $-12, goes to  007E
 008C	     D0B2	BIS #3,&432
 008E	     0003
 0090	     01B0
 0092	     D032	BIS #24,SR
 0094	     0018
 0096	     4292	MOV &436,&0
 0098	     01B4
 009A	     0000
 009C	     4344	MOV.B #0,R4
 009E	     4035	MOV #7,R5
 00A0	     0007
 00A2	     9405	CMP R4,R5
 00A4	     3809	JL $+20, goes to  00B8
 00A6	     4405	MOV R4,R5
 00A8	     5545	ADD.B R5,R5
 00AA	     5035	ADD #0,R5
 00AC	     0000
 00AE	     4295	MOV &154,0(R5)
 00B0	     009A
 00B2	     0000
 00B4	     5314	ADD #1,R4
 00B6	     3FF3	JMP $-24, goes to  009E
 00B8	     4292	MOV &176,&0
 00BA	     00B0
 00BC	     0000
 00BE	     4130	RET
 00C0	     43C2	MOV.B #0,&0
 00C2	     0000
 00C4	     40B2	MOV #2000,&370
 00C6	     07D0
 00C8	     0172
 00CA	     40B2	MOV #528,&352
 00CC	     0210
 00CE	     0160
 00D0	     40B2	MOV #16,&354
 00D2	     0010
 00D4	     0162
 00D6	     40B2	MOV #112,&356
 00D8	     0070
 00DA	     0164
 00DC	     4392	MOV #1,&372
 00DE	     0174
 00E0	     4130	RET
 00E2	     43D2	MOV.B #1,&194
 00E4	     00C2
 00E6	     42A2	MOV #4,&354
 00E8	     0162
 00EA	     40B2	MOV #736,&352
 00EC	     02E0
 00EE	     0160
 00F0	     D0F2	BIS.B #6,&38
 00F2	     0006
 00F4	     0026
 00F6	     D3E2	BIS.B #2,&34
 00F8	     0022
 00FA	     4130	RET
 00FC	     40F2	MOV.B #10,&0
 00FE	     000A
 0100	     0000
 0102	     40B2	MOV #26912,&354
 0104	     6920
 0106	     0162
 0108	     D0B2	BIS #12288,&354
 010A	     3000
 010C	     0162
 010E	     B392	BIT #1,&354
 0110	     0162
 0112	     27FD	JEQ $-4, goes to  010E
 0114	     50B2	ADD #52,&370
 0116	     0034
 0118	     0172
 011A	     D0B2	BIS #256,&0
 011C	     0100
 011E	     0000
 0120	     5292	ADD &286,&290
 0122	     011E
 0124	     0122
 0126	     40B2	MOV #4144,&354
 0128	     1030
 012A	     0162
 012C	     B0B2	BIT #16,&354
 012E	     0010
 0130	     0162
 0132	     23FC	JNE $-6, goes to  012C
 0134	     4130	RET
 0136	     93D2	CMP.B #1,&228
 0138	     00E4
 013A	     201F	JNE $+64, goes to  017A
 013C	     50B2	ADD #52,&370
 013E	     0034
 0140	     0172
 0142	     B0B2	BIT #4096,&354
 0144	     1000
 0146	     0162
 0148	     2417	JEQ $+48, goes to  0178
 014A	     93C2	CMP.B #0,&256
 014C	     0100
 014E	     2007	JNE $+16, goes to  015E
 0150	     C0F2	BIC.B #6,&38
 0152	     0006
 0154	     0026
 0156	     C0B2	BIC #16,&354
 0158	     0010
 015A	     0162
 015C	     3C0D	JMP $+28, goes to  0178
 015E	     D0B2	BIS #128,&354
 0160	     0080
 0162	     0162
 0164	     B392	BIT #1,&292
 0166	     0124
 0168	     2403	JEQ $+8, goes to  0170
 016A	     C0B2	BIC #128,&354
 016C	     0080
 016E	     0162
 0170	     1112	RRA &358
 0172	     0166
 0174	     83D2	SUB.B #1,&332
 0176	     014C
 0178	     3C0E	JMP $+30, goes to  0196
 017A	     93D2	CMP.B #1,&0
 017C	     0000
 017E	     2003	JNE $+8, goes to  0186
 0180	     D3D2	BIS.B #1,&33
 0182	     0021
 0184	     3C06	JMP $+14, goes to  0192
 0186	     93E2	CMP.B #2,&380
 0188	     017C
 018A	     2003	JNE $+8, goes to  0192
 018C	     D0F2	BIS.B #64,&33
 018E	     0040
 0190	     0021
 0192	     C392	BIC #1,&354
 0194	     0162
 0196	     1300	RETI
 0198	     C392	BIC #1,&356
 019A	     0164
 019C	     93D2	CMP.B #1,&0
 019E	     0000
 01A0	     2004	JNE $+10, goes to  01AA
 01A2	     C0F2	BIC.B #65,&33
 01A4	     0041
 01A6	     0021
 01A8	     3C03	JMP $+8, goes to  01B0
 01AA	     E0F2	XOR.B #65,&33
 01AC	     0041
 01AE	     0021
 01B0	     1300	RETI
 01B2	     43C2	MOV.B #0,&35
 01B4	     0023
 01B6	     C2F2	BIC.B #8,&37
 01B8	     0025
 01BA	     40B2	MOV #23069,&288
 01BC	     5A1D
 01BE	     0120
 01C0	     C3D2	BIC.B #1,&2
 01C2	     0002
 01C4	     D3D2	BIS.B #1,&0
 01C6	     0000
 01C8	     93D2	CMP.B #1,&414
 01CA	     019E
 01CC	     2006	JNE $+14, goes to  01DA
 01CE	     4292	MOV &188,&186
 01D0	     00BC
 01D2	     00BA
 01D4	     43D2	MOV.B #1,&0
 01D6	     0000
 01D8	     3C05	JMP $+12, goes to  01E4
 01DA	     43D2	MOV.B #1,&458
 01DC	     01CA
 01DE	     C0B1	BIC #208,0(SP)
 01E0	     00D0
 01E2	     0000
 01E4	     1300	RETI
 01E6	     C3D2	BIC.B #1,&0
 01E8	     0000
 01EA	     C3D2	BIC.B #1,&2
 01EC	     0002
 01EE	     40B2	MOV #23168,&288
 01F0	     5A80
 01F2	     0120
 01F4	     D2F2	BIS.B #8,&37
 01F6	     0025
 01F8	     1300	RETI
 01FA	     C0B1	BIC #16,0(SP)
 01FC	     0010
 01FE	     0000
 0200	     1300	RETI
 0202	     40B2	MOV #23168,&288
 0204	     5A80
 0206	     0120
 0208	     43C2	MOV.B #0,&476
 020A	     01DC
 020C	     43C2	MOV.B #0,&312
 020E	     0138
 0210	     43C2	MOV.B #0,&470
 0212	     01D6
 0214	     43C2	MOV.B #0,&392
 0216	     0188
 0218	     43C2	MOV.B #0,&0
 021A	     0000
 021C	     40B2	MOV #1000,&0
 021E	     03E8
 0220	     0000
 0222	     12B0	CALL #0
 0224	     0000
 0226	     12B0	CALL #0
 0228	     0000
 022A	     12B0	CALL #0
 022C	     0000
 022E	     12B0	CALL #0
 0230	     0000
 0232	     43D2	MOV.B #1,&522
 0234	     020A
 0236	     12B0	CALL #0
 0238	     0000
 023A	     12B0	CALL #0
 023C	     0000
 023E	     D232	BIS #8,SR
 0240	     D0B2	BIS #3,&432
 0242	     0003
 0244	     01B0
 0246	     D032	BIS #24,SR
 0248	     0018
 024A	     425F	MOV.B &538,R15
 024C	     021A
 024E	     5F4F	ADD.B R15,R15
 0250	     503F	ADD #172,R15
 0252	     00AC
 0254	     429F	MOV &436,0(R15)
 0256	     01B4
 0258	     0000
 025A	     53D2	ADD.B #1,&588
 025C	     024C
 025E	     92F2	CMP.B #8,&604
 0260	     025C
 0262	     2002	JNE $+6, goes to  0268
 0264	     43C2	MOV.B #0,&608
 0266	     0260
 0268	     4382	MOV #0,&464
 026A	     01D0
 026C	     43C2	MOV.B #0,&0
 026E	     0000
 0270	     425F	MOV.B &622,R15
 0272	     026E
 0274	     403E	MOV #7,R14
 0276	     0007
 0278	     9F0E	CMP R15,R14
 027A	     3809	JL $+20, goes to  028E
 027C	     425F	MOV.B &626,R15
 027E	     0272
 0280	     5F4F	ADD.B R15,R15
 0282	     503F	ADD #594,R15
 0284	     0252
 0286	     5FA2	ADD @R15,&618
 0288	     026A
 028A	     531F	ADD #1,R15
 028C	     3FF1	JMP $-28, goes to  0270
 028E	     1112	RRA &648
 0290	     0288
 0292	     1112	RRA &656
 0294	     0290
 0296	     1112	RRA &660
 0298	     0294
 029A	     8392	SUB #1,&544
 029C	     0220
 029E	     9382	CMP #0,&668
 02A0	     029C
 02A2	     2403	JEQ $+8, goes to  02AA
 02A4	     93C2	CMP.B #0,&530
 02A6	     0212
 02A8	     2433	JEQ $+104, goes to  0310
 02AA	     12B0	CALL #0
 02AC	     0000
 02AE	     93C2	CMP.B #0,&678
 02B0	     02A6
 02B2	     2407	JEQ $+16, goes to  02C2
 02B4	     40B2	MOV #248,&370
 02B6	     00F8
 02B8	     0172
 02BA	     12B0	CALL #0
 02BC	     0000
 02BE	     43C2	MOV.B #0,&688
 02C0	     02B0
 02C2	     4034	MOV #0,R4
 02C4	     0000
 02C6	     4035	MOV #696,R5
 02C8	     02B8
 02CA	     4216	MOV &664,R6
 02CC	     0298
 02CE	     12B0	CALL #0
 02D0	     0000
 02D2	     4034	MOV #708,R4
 02D4	     02C4
 02D6	     4035	MOV #712,R5
 02D8	     02C8
 02DA	     4036	MOV #630,R6
 02DC	     0276
 02DE	     12B0	CALL #0
 02E0	     0000
 02E2	     4034	MOV #724,R4
 02E4	     02D4
 02E6	     4035	MOV #728,R5
 02E8	     02D8
 02EA	     4036	MOV #761,R6
 02EC	     02F9
 02EE	     12B0	CALL #0
 02F0	     0000
 02F2	     4034	MOV #740,R4
 02F4	     02E4
 02F6	     4035	MOV #744,R5
 02F8	     02E8
 02FA	     4036	MOV #10,R6
 02FC	     000A
 02FE	     12B0	CALL #0
 0300	     0000
 0302	     12B0	CALL #700
 0304	     02BC
 0306	     40B2	MOV #1000,&672
 0308	     03E8
 030A	     02A0
 030C	     12B0	CALL #572
 030E	     023C
 0310	     421F	MOV &716,R15
 0312	     02CC
 0314	     821F	SUB &466,R15
 0316	     01D2
 0318	     4F82	MOV R15,&0
 031A	     0000
 031C	     90B2	CMP #-5,&794
 031E	     FFFB
 0320	     031A
 0322	     340B	JGE $+24, goes to  033A
 0324	     421F	MOV &800,R15
 0326	     0320
 0328	     E33F	XOR #-1,R15
 032A	     531F	ADD #1,R15
 032C	     4F82	MOV R15,&806
 032E	     0326
 0330	     43E2	MOV.B #2,&534
 0332	     0216
 0334	     C3D2	BIC.B #1,&33
 0336	     0021
 0338	     3C16	JMP $+46, goes to  0366
 033A	     403F	MOV #5,R15
 033C	     0005
 033E	     921F	CMP &814,R15
 0340	     032E
 0342	     3406	JGE $+14, goes to  0350
 0344	     43D2	MOV.B #1,&818
 0346	     0332
 0348	     C0F2	BIC.B #64,&33
 034A	     0040
 034C	     0021
 034E	     3C0B	JMP $+24, goes to  0366
 0350	     43C2	MOV.B #0,&838
 0352	     0346
 0354	     C0B2	BIC #16,&354
 0356	     0010
 0358	     0162
 035A	     C0B2	BIC #16,&356
 035C	     0010
 035E	     0164
 0360	     C0F2	BIC.B #65,&33
 0362	     0041
 0364	     0021
 0366	     93C2	CMP.B #0,&850
 0368	     0352
 036A	     241D	JEQ $+60, goes to  03A6
 036C	     5292	ADD &832,&878
 036E	     0340
 0370	     036E
 0372	     5292	ADD &880,&884
 0374	     0370
 0376	     0374
 0378	     5292	ADD &886,&890
 037A	     0376
 037C	     037A
 037E	     50B2	ADD #20,&892
 0380	     0014
 0382	     037C
 0384	     90B2	CMP #1999,&898
 0386	     07CF
 0388	     0382
 038A	     3404	JGE $+10, goes to  0394
 038C	     4292	MOV &904,&372
 038E	     0388
 0390	     0174
 0392	     3C03	JMP $+8, goes to  039A
 0394	     40B2	MOV #1999,&372
 0396	     07CF
 0398	     0174
 039A	     D0B2	BIS #16,&354
 039C	     0010
 039E	     0162
 03A0	     D0B2	BIS #16,&388
 03A2	     0010
 03A4	     0184
 03A6	     3F4C	JMP $-358, goes to  0240
 03A8	     4130	RET
