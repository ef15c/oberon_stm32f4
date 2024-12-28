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
  IMPORT SYSTEM, M := msp430g2553, MP := MultiPrecisionArith, Delay := msp430delay;

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
  BEGIN
    (* Configure ADC Temp Sensor Channel *)
    M.ADC10CTL1^ := M.INCH_10 + M.ADC10DIV_3; (* Temp Sensor ADC10CLK/4 *)
    M.ADC10CTL0^ := M.SREF_1 + M.ADC10SHT_3 + M.REFON + M.ADC10ON + M.ADC10IE;
    Delay.CyclesX3(1000 DIV 3); (* __delay_cycles(1000);*) (* Wait for ADC Ref to settle *)
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
  linking msp430g2553 MultiPrecisionArith msp430delay MSPEXP430G2Launchpad, flash 1340, data   38, stack  474 bytes

OMSPTool.DecObj MSPEXP430G2Launchpad.mpc
decode MSPEXP430G2Launchpad.mpc
MSPEXP430G2Launchpad 51A3A09D Flash   942
imports:
	msp430g2553 F10488DC
	MultiPrecisionArith B561C064
	msp430delay EE6A4099
type descriptors

data    38
strings

vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 FFFF FFFF 0000 FFFF FFFF 0000 FFFF FFFF 0000 0000 0000 FFFF FFFF FFFF FFFF FFFF

entries
 c 0204
fixup procedures chains
 0226     0	 0000
 022A     0	 0014
 022E     0	 002E
 0232     0	 003C
 023A     0	 0070
 0312     0	 00C2
 02B0     0	 00E4
 0308     0	 00FE
 0304     2	 0008
 02F4     2	 0006
 02E4     2	 0003
 02D4     2	 0002
 0082     3	 0001
fixup handlers chains
 0119     0	 0138
 0118     0	 019A
 0112     0	 01B4
 011A     0	 01E8
 0115     0	 01FC
fixup data chains
 031A     0	 001C
 028E     0	 0024
 0286     0	 0008
 0316     0	 001A
 0210     0	 0002
 0178     0	 0000
 02FC     0	 0006
 036C     0	 0004
 0236     0	 0001
 02C4     0	 0005
 0268     0	 0018
 030E     0	 0022
 02F8     0	 0020
 0392     0	 001E
fixup constants chains
fixup types chains
entry =  0204
code   942
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
 007C	     4034	MOV #333,R4
 007E	     014D
 0080	     12B0	CALL #0
 0082	     0000
 0084	     D0B2	BIS #3,&432
 0086	     0003
 0088	     01B0
 008A	     D032	BIS #24,SR
 008C	     0018
 008E	     4292	MOV &436,&0
 0090	     01B4
 0092	     0000
 0094	     43C2	MOV.B #0,&0
 0096	     0000
 0098	     425F	MOV.B &150,R15
 009A	     0096
 009C	     403E	MOV #7,R14
 009E	     0007
 00A0	     9F0E	CMP R15,R14
 00A2	     380B	JL $+24, goes to  00BA
 00A4	     425F	MOV.B &154,R15
 00A6	     009A
 00A8	     5F4F	ADD.B R15,R15
 00AA	     503F	ADD #0,R15
 00AC	     0000
 00AE	     429F	MOV &146,0(R15)
 00B0	     0092
 00B2	     0000
 00B4	     53D2	ADD.B #1,&166
 00B6	     00A6
 00B8	     3FEF	JMP $-32, goes to  0098
 00BA	     4292	MOV &176,&0
 00BC	     00B0
 00BE	     0000
 00C0	     4130	RET
 00C2	     43C2	MOV.B #0,&0
 00C4	     0000
 00C6	     40B2	MOV #2000,&370
 00C8	     07D0
 00CA	     0172
 00CC	     40B2	MOV #528,&352
 00CE	     0210
 00D0	     0160
 00D2	     40B2	MOV #16,&354
 00D4	     0010
 00D6	     0162
 00D8	     40B2	MOV #112,&356
 00DA	     0070
 00DC	     0164
 00DE	     4392	MOV #1,&372
 00E0	     0174
 00E2	     4130	RET
 00E4	     43D2	MOV.B #1,&196
 00E6	     00C4
 00E8	     42A2	MOV #4,&354
 00EA	     0162
 00EC	     40B2	MOV #736,&352
 00EE	     02E0
 00F0	     0160
 00F2	     D0F2	BIS.B #6,&38
 00F4	     0006
 00F6	     0026
 00F8	     D3E2	BIS.B #2,&34
 00FA	     0022
 00FC	     4130	RET
 00FE	     40F2	MOV.B #10,&0
 0100	     000A
 0102	     0000
 0104	     40B2	MOV #26912,&354
 0106	     6920
 0108	     0162
 010A	     D0B2	BIS #12288,&354
 010C	     3000
 010E	     0162
 0110	     B392	BIT #1,&354
 0112	     0162
 0114	     27FD	JEQ $-4, goes to  0110
 0116	     50B2	ADD #52,&370
 0118	     0034
 011A	     0172
 011C	     D0B2	BIS #256,&0
 011E	     0100
 0120	     0000
 0122	     5292	ADD &288,&292
 0124	     0120
 0126	     0124
 0128	     40B2	MOV #4144,&354
 012A	     1030
 012C	     0162
 012E	     B0B2	BIT #16,&354
 0130	     0010
 0132	     0162
 0134	     23FC	JNE $-6, goes to  012E
 0136	     4130	RET
 0138	     93D2	CMP.B #1,&230
 013A	     00E6
 013C	     201F	JNE $+64, goes to  017C
 013E	     50B2	ADD #52,&370
 0140	     0034
 0142	     0172
 0144	     B0B2	BIT #4096,&354
 0146	     1000
 0148	     0162
 014A	     2417	JEQ $+48, goes to  017A
 014C	     93C2	CMP.B #0,&258
 014E	     0102
 0150	     2007	JNE $+16, goes to  0160
 0152	     C0F2	BIC.B #6,&38
 0154	     0006
 0156	     0026
 0158	     C0B2	BIC #16,&354
 015A	     0010
 015C	     0162
 015E	     3C0D	JMP $+28, goes to  017A
 0160	     D0B2	BIS #128,&354
 0162	     0080
 0164	     0162
 0166	     B392	BIT #1,&294
 0168	     0126
 016A	     2403	JEQ $+8, goes to  0172
 016C	     C0B2	BIC #128,&354
 016E	     0080
 0170	     0162
 0172	     1112	RRA &360
 0174	     0168
 0176	     83D2	SUB.B #1,&334
 0178	     014E
 017A	     3C0E	JMP $+30, goes to  0198
 017C	     93D2	CMP.B #1,&0
 017E	     0000
 0180	     2003	JNE $+8, goes to  0188
 0182	     D3D2	BIS.B #1,&33
 0184	     0021
 0186	     3C06	JMP $+14, goes to  0194
 0188	     93E2	CMP.B #2,&382
 018A	     017E
 018C	     2003	JNE $+8, goes to  0194
 018E	     D0F2	BIS.B #64,&33
 0190	     0040
 0192	     0021
 0194	     C392	BIC #1,&354
 0196	     0162
 0198	     1300	RETI
 019A	     C392	BIC #1,&356
 019C	     0164
 019E	     93D2	CMP.B #1,&0
 01A0	     0000
 01A2	     2004	JNE $+10, goes to  01AC
 01A4	     C0F2	BIC.B #65,&33
 01A6	     0041
 01A8	     0021
 01AA	     3C03	JMP $+8, goes to  01B2
 01AC	     E0F2	XOR.B #65,&33
 01AE	     0041
 01B0	     0021
 01B2	     1300	RETI
 01B4	     43C2	MOV.B #0,&35
 01B6	     0023
 01B8	     C2F2	BIC.B #8,&37
 01BA	     0025
 01BC	     40B2	MOV #23069,&288
 01BE	     5A1D
 01C0	     0120
 01C2	     C3D2	BIC.B #1,&2
 01C4	     0002
 01C6	     D3D2	BIS.B #1,&0
 01C8	     0000
 01CA	     93D2	CMP.B #1,&416
 01CC	     01A0
 01CE	     2006	JNE $+14, goes to  01DC
 01D0	     4292	MOV &190,&188
 01D2	     00BE
 01D4	     00BC
 01D6	     43D2	MOV.B #1,&0
 01D8	     0000
 01DA	     3C05	JMP $+12, goes to  01E6
 01DC	     43D2	MOV.B #1,&460
 01DE	     01CC
 01E0	     C0B1	BIC #208,0(SP)
 01E2	     00D0
 01E4	     0000
 01E6	     1300	RETI
 01E8	     C3D2	BIC.B #1,&0
 01EA	     0000
 01EC	     C3D2	BIC.B #1,&2
 01EE	     0002
 01F0	     40B2	MOV #23168,&288
 01F2	     5A80
 01F4	     0120
 01F6	     D2F2	BIS.B #8,&37
 01F8	     0025
 01FA	     1300	RETI
 01FC	     C0B1	BIC #16,0(SP)
 01FE	     0010
 0200	     0000
 0202	     1300	RETI
 0204	     40B2	MOV #23168,&288
 0206	     5A80
 0208	     0120
 020A	     43C2	MOV.B #0,&478
 020C	     01DE
 020E	     43C2	MOV.B #0,&314
 0210	     013A
 0212	     43C2	MOV.B #0,&472
 0214	     01D8
 0216	     43C2	MOV.B #0,&394
 0218	     018A
 021A	     43C2	MOV.B #0,&0
 021C	     0000
 021E	     40B2	MOV #1000,&0
 0220	     03E8
 0222	     0000
 0224	     12B0	CALL #0
 0226	     0000
 0228	     12B0	CALL #0
 022A	     0000
 022C	     12B0	CALL #0
 022E	     0000
 0230	     12B0	CALL #0
 0232	     0000
 0234	     43D2	MOV.B #1,&524
 0236	     020C
 0238	     12B0	CALL #0
 023A	     0000
 023C	     12B0	CALL #0
 023E	     0000
 0240	     D232	BIS #8,SR
 0242	     D0B2	BIS #3,&432
 0244	     0003
 0246	     01B0
 0248	     D032	BIS #24,SR
 024A	     0018
 024C	     425F	MOV.B &540,R15
 024E	     021C
 0250	     5F4F	ADD.B R15,R15
 0252	     503F	ADD #172,R15
 0254	     00AC
 0256	     429F	MOV &436,0(R15)
 0258	     01B4
 025A	     0000
 025C	     53D2	ADD.B #1,&590
 025E	     024E
 0260	     92F2	CMP.B #8,&606
 0262	     025E
 0264	     2002	JNE $+6, goes to  026A
 0266	     43C2	MOV.B #0,&610
 0268	     0262
 026A	     4382	MOV #0,&466
 026C	     01D2
 026E	     43C2	MOV.B #0,&182
 0270	     00B6
 0272	     425F	MOV.B &624,R15
 0274	     0270
 0276	     403E	MOV #7,R14
 0278	     0007
 027A	     9F0E	CMP R15,R14
 027C	     380A	JL $+22, goes to  0292
 027E	     425F	MOV.B &628,R15
 0280	     0274
 0282	     5F4F	ADD.B R15,R15
 0284	     503F	ADD #596,R15
 0286	     0254
 0288	     5FA2	ADD @R15,&620
 028A	     026C
 028C	     53D2	ADD.B #1,&640
 028E	     0280
 0290	     3FF0	JMP $-30, goes to  0272
 0292	     1112	RRA &650
 0294	     028A
 0296	     1112	RRA &660
 0298	     0294
 029A	     1112	RRA &664
 029C	     0298
 029E	     8392	SUB #1,&546
 02A0	     0222
 02A2	     9382	CMP #0,&672
 02A4	     02A0
 02A6	     2403	JEQ $+8, goes to  02AE
 02A8	     93C2	CMP.B #0,&532
 02AA	     0214
 02AC	     2433	JEQ $+104, goes to  0314
 02AE	     12B0	CALL #0
 02B0	     0000
 02B2	     93C2	CMP.B #0,&682
 02B4	     02AA
 02B6	     2407	JEQ $+16, goes to  02C6
 02B8	     40B2	MOV #248,&372
 02BA	     00F8
 02BC	     0174
 02BE	     12B0	CALL #0
 02C0	     0000
 02C2	     43C2	MOV.B #0,&692
 02C4	     02B4
 02C6	     4034	MOV #0,R4
 02C8	     0000
 02CA	     4035	MOV #700,R5
 02CC	     02BC
 02CE	     4216	MOV &668,R6
 02D0	     029C
 02D2	     12B0	CALL #0
 02D4	     0000
 02D6	     4034	MOV #712,R4
 02D8	     02C8
 02DA	     4035	MOV #716,R5
 02DC	     02CC
 02DE	     4036	MOV #630,R6
 02E0	     0276
 02E2	     12B0	CALL #0
 02E4	     0000
 02E6	     4034	MOV #728,R4
 02E8	     02D8
 02EA	     4035	MOV #732,R5
 02EC	     02DC
 02EE	     4036	MOV #761,R6
 02F0	     02F9
 02F2	     12B0	CALL #0
 02F4	     0000
 02F6	     4034	MOV #744,R4
 02F8	     02E8
 02FA	     4035	MOV #748,R5
 02FC	     02EC
 02FE	     4036	MOV #10,R6
 0300	     000A
 0302	     12B0	CALL #0
 0304	     0000
 0306	     12B0	CALL #704
 0308	     02C0
 030A	     40B2	MOV #1000,&676
 030C	     03E8
 030E	     02A4
 0310	     12B0	CALL #574
 0312	     023E
 0314	     421F	MOV &720,R15
 0316	     02D0
 0318	     821F	SUB &468,R15
 031A	     01D4
 031C	     4F82	MOV R15,&0
 031E	     0000
 0320	     90B2	CMP #-5,&798
 0322	     FFFB
 0324	     031E
 0326	     340B	JGE $+24, goes to  033E
 0328	     421F	MOV &804,R15
 032A	     0324
 032C	     E33F	XOR #-1,R15
 032E	     531F	ADD #1,R15
 0330	     4F82	MOV R15,&810
 0332	     032A
 0334	     43E2	MOV.B #2,&536
 0336	     0218
 0338	     C3D2	BIC.B #1,&33
 033A	     0021
 033C	     3C16	JMP $+46, goes to  036A
 033E	     403F	MOV #5,R15
 0340	     0005
 0342	     921F	CMP &818,R15
 0344	     0332
 0346	     3406	JGE $+14, goes to  0354
 0348	     43D2	MOV.B #1,&822
 034A	     0336
 034C	     C0F2	BIC.B #64,&33
 034E	     0040
 0350	     0021
 0352	     3C0B	JMP $+24, goes to  036A
 0354	     43C2	MOV.B #0,&842
 0356	     034A
 0358	     C0B2	BIC #16,&354
 035A	     0010
 035C	     0162
 035E	     C0B2	BIC #16,&356
 0360	     0010
 0362	     0164
 0364	     C0F2	BIC.B #65,&33
 0366	     0041
 0368	     0021
 036A	     93C2	CMP.B #0,&854
 036C	     0356
 036E	     241D	JEQ $+60, goes to  03AA
 0370	     5292	ADD &836,&882
 0372	     0344
 0374	     0372
 0376	     5292	ADD &884,&888
 0378	     0374
 037A	     0378
 037C	     5292	ADD &890,&894
 037E	     037A
 0380	     037E
 0382	     50B2	ADD #20,&896
 0384	     0014
 0386	     0380
 0388	     90B2	CMP #1999,&902
 038A	     07CF
 038C	     0386
 038E	     3404	JGE $+10, goes to  0398
 0390	     4292	MOV &908,&372
 0392	     038C
 0394	     0174
 0396	     3C03	JMP $+8, goes to  039E
 0398	     40B2	MOV #1999,&372
 039A	     07CF
 039C	     0174
 039E	     D0B2	BIS #16,&354
 03A0	     0010
 03A2	     0162
 03A4	     D0B2	BIS #16,&388
 03A6	     0010
 03A8	     0184
 03AA	     3F4B	JMP $-360, goes to  0242
 03AC	     4130	RET
