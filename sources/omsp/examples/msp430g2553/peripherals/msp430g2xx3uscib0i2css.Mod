(******************************************************************************
//   MSP430G2xx3 Demo - USCI_B0, I2C Slave multiple byte TX/RX
//
//   Description: I2C master communicates to I2C slave sending and receiving
//   3 different messages of different length. (This is the slave code). The
//   slave will be in LPM0 mode, waiting for the master to initiate the
//   communication. The slave will send/receive bytes based on the master's
//   request. The slave will handle I2C bytes sent/received using the
//   I2C interrupt.
//   ACLK = NA, MCLK = SMCLK = DCO 16MHz.
//
//
//                   MSP430G2553         3.3V
//                 -----------------   /|\ /|\
//            /|\ |                 |   |  4.7k
//             |  |                 |  4.7k |
//             ---|RST              |   |   |
//                |                 |   |   |
//                |             P1.6|---|---+- I2C Clock (UCB0SCL)
//                |                 |   |
//                |             P1.7|---+----- I2C Data (UCB0SDA)
//                |                 |
//                |                 |
//
//   Nima Eskandari
//   Texas Instruments Inc.
//   April 2017
//  C. Schoffit 01.11.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscib0i2css;
  IMPORT SYSTEM, M := msp430g2553;

(******************************************************************************
   Example Commands ************************************************************
  ******************************************************************************)

CONST SLAVE_ADDR = 48H;

  (* CMD_TYPE_X_SLAVE are example commands the master sends to the slave.
   * The slave will send example SlaveTypeX buffers in response.
   *
   * CMD_TYPE_X_MASTER are example commands the master sends to the slave.
   * The slave will initialize itself to receive MasterTypeX example buffers.
   * *)

    CMD_TYPE_0_SLAVE =  0; CMD_TYPE_1_SLAVE = 1; CMD_TYPE_2_SLAVE = 2;
    CMD_TYPE_0_MASTER = 3; CMD_TYPE_1_MASTER = 4; CMD_TYPE_2_MASTER = 5;
    TYPE_0_LENGTH = 1; TYPE_1_LENGTH = 2; TYPE_2_LENGTH = 6;

    MAX_BUFFER_SIZE = 20;

  (* MasterTypeX are example buffers initialized in the master, they will be
   * sent by the master to the slave.
   * SlaveTypeX are example buffers initialized in the slave, they will be
   * sent by the slave to the master.
   * *)

    SlaveType2 = "ABCD12";
    SlaveType1 = "" + 0FX + 10X;
    SlaveType0 = ($0C$);


  (*******************************************************************************
   General I2C State Machine ***************************************************
  ******************************************************************************)

    IDLE_MODE = 0;
    NACK_MODE = 1;
    TX_REG_ADDRESS_MODE = 2;
    RX_REG_ADDRESS_MODE = 3;
    TX_DATA_MODE = 4;
    RX_DATA_MODE = 5;
    SWITCH_TO_RX_MODE = 6;
    SWITHC_TO_TX_MODE = 7;
    TIMEOUT_MODE = 8;

  TYPE I2C_Mode = BYTE;

  VAR MasterType2: ARRAY TYPE_2_LENGTH OF BYTE;
    MasterType1: ARRAY TYPE_1_LENGTH OF BYTE;
    MasterType0: ARRAY TYPE_0_LENGTH OF BYTE;

    (* Used to track the state of the software state machine *)
    SlaveMode: I2C_Mode;

    (* The Register Address/Command to use *)
    ReceiveRegAddr: BYTE;

    (* ReceiveBuffer: Buffer used to receive data in the ISR
     * RXByteCtr: Number of bytes left to receive
     * ReceiveIndex: The index of the next byte to be received in ReceiveBuffer
     * TransmitBuffer: Buffer used to transmit data in the ISR
     * TXByteCtr: Number of bytes left to transfer
     * TransmitIndex: The index of the next byte to be transmitted in TransmitBuffer
     * *)

    ReceiveBuffer, TransmitBuffer: ARRAY MAX_BUFFER_SIZE OF BYTE;
    RXByteCtr, ReceiveIndex, TXByteCtr, TransmitIndex: BYTE;

  (* Initialized the software state machine according to the received cmd
   *
   * cmd: The command/register address received
   * *)
  PROCEDURE I2C_Slave_ProcessCMD(cmd: BYTE);
  BEGIN ReceiveIndex := 0; TransmitIndex := 0; RXByteCtr := 0; TXByteCtr := 0;
    IF cmd = CMD_TYPE_0_SLAVE THEN (*Send slave device id (This device's id) *)
      SlaveMode := TX_DATA_MODE;
      TXByteCtr := TYPE_0_LENGTH;
      (* Fill out the TransmitBuffer *)
      SYSTEM.COPY(SYSTEM.ADR(SlaveType0), SYSTEM.ADR(TransmitBuffer), TYPE_0_LENGTH);
      BIC(M.IE2^, M.UCB0RXIE); (* Disable RX interrupt *)
      BIS(M.IE2^, M.UCB0TXIE) (* Enable TX interrupt *)
    ELSIF cmd = CMD_TYPE_1_SLAVE THEN (*Send slave device time (This device's time) *)
      SlaveMode := TX_DATA_MODE;
      TXByteCtr := TYPE_1_LENGTH;
      (* Fill out the TransmitBuffer *)
      SYSTEM.COPY(SYSTEM.ADR(SlaveType1), SYSTEM.ADR(TransmitBuffer), TYPE_1_LENGTH);
      BIC(M.IE2^, M.UCB0RXIE); (* Disable RX interrupt *)
      BIS(M.IE2^, M.UCB0TXIE) (* Enable TX interrupt *)
    ELSIF cmd = CMD_TYPE_2_SLAVE THEN (* Send slave device location (This device's location) *)
      SlaveMode := TX_DATA_MODE;
      TXByteCtr := TYPE_2_LENGTH;
      (* Fill out the TransmitBuffer *)
      SYSTEM.COPY(SYSTEM.ADR(SlaveType2), SYSTEM.ADR(TransmitBuffer), TYPE_2_LENGTH);
      BIC(M.IE2^, M.UCB0RXIE); (* Disable RX interrupt *)
      BIS(M.IE2^, M.UCB0TXIE) (* Enable TX interrupt *)
    ELSIF cmd = CMD_TYPE_0_MASTER THEN
      SlaveMode := RX_DATA_MODE;
      RXByteCtr := TYPE_0_LENGTH;
      BIC(M.IE2^, M.UCB0RXIE); (* Disable RX interrupt *)
      BIS(M.IE2^, M.UCB0TXIE) (* Enable TX interrupt *)
    ELSIF cmd = CMD_TYPE_1_MASTER THEN
      SlaveMode := RX_DATA_MODE;
      RXByteCtr := TYPE_1_LENGTH;
      BIC(M.IE2^, M.UCB0RXIE); (* Disable RX interrupt *)
      BIS(M.IE2^, M.UCB0TXIE) (* Enable TX interrupt *)
    ELSIF cmd = CMD_TYPE_2_MASTER THEN
      SlaveMode := RX_DATA_MODE;
      RXByteCtr := TYPE_2_LENGTH;
      BIC(M.IE2^, M.UCB0RXIE); (* Disable RX interrupt *)
      BIS(M.IE2^, M.UCB0TXIE) (* Enable TX interrupt *)
    ELSE NOP
    END
  END I2C_Slave_ProcessCMD;

  (* The transaction between the slave and master is completed. Uses cmd
   * to do post transaction operations. (Place data from ReceiveBuffer
   * to the corresponding buffer based in the last received cmd)
   *
   * cmd: The command/register address corresponding to the completed
   * transaction
   *)
  PROCEDURE I2C_Slave_TransactionDone(cmd: BYTE);
  BEGIN
    IF (cmd = CMD_TYPE_0_SLAVE) (* Slave device id was sent(This device's id) *)
      OR (cmd = CMD_TYPE_1_SLAVE) (* Slave device time was sent(This device's time) *)
      OR (cmd = CMD_TYPE_2_SLAVE) (* Send slave device location (This device's location) *) THEN (*do nothing *)
    ELSIF cmd = CMD_TYPE_0_MASTER THEN SYSTEM.COPY(SYSTEM.ADR(ReceiveBuffer), SYSTEM.ADR(MasterType0), TYPE_0_LENGTH)
    ELSIF cmd = CMD_TYPE_1_MASTER THEN SYSTEM.COPY(SYSTEM.ADR(ReceiveBuffer), SYSTEM.ADR(MasterType1), TYPE_1_LENGTH)
    ELSIF cmd = CMD_TYPE_2_MASTER THEN SYSTEM.COPY(SYSTEM.ADR(ReceiveBuffer), SYSTEM.ADR(MasterType2), TYPE_2_LENGTH)
    ELSE NOP
    END
  END I2C_Slave_TransactionDone;


  (******************************************************************************
   Device Initialization *******************************************************
  ******************************************************************************)


  PROCEDURE initClockTo16MHz;
  BEGIN REPEAT UNTIL ~BIT(M.CALBC1_16MHZ^, {0..7}); (* If calibration constant erased, do not load, trap CPU!!*)
    M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
    M.BCSCTL1^ := M.CALBC1_16MHZ^; (* Set DCO *)
    M.DCOCTL^ := M.CALDCO_16MHZ^
  END initClockTo16MHz;

  PROCEDURE initGPIO;
  BEGIN
    BIS(M.P1SEL^, {6..7}); (* Assign I2C pins to USCI_B0 *)
    BIS(M.P1SEL2^, {6..7}) (* Assign I2C pins to USCI_B0 *)
 END initGPIO;

  PROCEDURE initI2C;
  BEGIN
    BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
    M.UCB0CTL0^ := M.UCMODE_3 + M.UCSYNC; (* I2C Slave, synchronous mode *)
    M.UCB0I2COA^ := SYSTEM.VAL(SET, SLAVE_ADDR); (* Own Address *)
    BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
    BIS(M.UCB0I2CIE^, M.UCSTPIE + M.UCSTTIE); (* Enable STT and STP interrupt *)
    BIS(M.IE2^, M.UCB0RXIE) (* Enable RX interrupt *)
  END initI2C;

  (* for USCI29 silicon erratum *)
  PROCEDURE* (M.TRAPINT_VECTOR) TRAPINT_ISR;
  END TRAPINT_ISR;

  (******************************************************************************
   I2C Interrupt For Received and Transmitted Data******************************
  ******************************************************************************)

  PROCEDURE* (M.USCIAB0TX_VECTOR) {4} USCIAB0TX_ISR;
    VAR rx_val: BYTE;
  BEGIN
    IF BIT(M.IFG2^, M.UCB0RXIFG) THEN (* Receive Data Interrupt *)
      (* Must read from UCB0RXBUF *)
      rx_val := M.UCB0RXBUF^;
      IF SlaveMode = RX_REG_ADDRESS_MODE THEN
        ReceiveRegAddr := rx_val;
        I2C_Slave_ProcessCMD(ReceiveRegAddr)
      ELSIF SlaveMode = RX_DATA_MODE THEN
        ReceiveBuffer[ReceiveIndex] := rx_val; INC(ReceiveIndex);
        DEC(RXByteCtr);
        IF RXByteCtr = 0 THEN (* Done Receiving MSG *)
          SlaveMode := RX_REG_ADDRESS_MODE;
          BIC(M.IE2^, M.UCB0TXIE);
          BIS(M.IE2^, M.UCB0RXIE); (* Enable RX interrupt *)
          I2C_Slave_TransactionDone(ReceiveRegAddr);
        END
      ELSE NOP
      END
    ELSIF BIT(M.IFG2^, M.UCB0TXIFG) THEN (* Transmit Data Interrupt *)
      (* Must write to UCB0TXBUF *)
      IF SlaveMode = TX_DATA_MODE THEN
        M.UCB0TXBUF^ := TransmitBuffer[TransmitIndex]; INC(TransmitIndex);
        DEC(TXByteCtr);
        IF TXByteCtr = 0 THEN (* Done Transmitting MSG *)
          SlaveMode := RX_REG_ADDRESS_MODE;
          BIC(M.IE2^, M.UCB0TXIE);
          BIS(M.IE2^, M.UCB0RXIE); (* Enable RX interrupt *)
          I2C_Slave_TransactionDone(ReceiveRegAddr);
        END
      ELSE NOP
      END
    END
  END USCIAB0TX_ISR;

  (******************************************************************************
   I2C Interrupt For Start, Restart, Nack, Stop ********************************
  ******************************************************************************)

  PROCEDURE* (M.USCIAB0RX_VECTOR) USCIAB0RX_ISR;
  BEGIN
    IF BIT(M.UCB0STAT^, M.UCSTPIFG) THEN (*Stop interrupt *)
      BIC(M.UCB0STAT^, M.UCSTTIFG + M.UCSTPIFG + M.UCNACKIFG); (* Clear START/STOP/NACK Flags *)
    END;
    IF BIT(M.UCB0STAT^, M.UCSTTIFG) THEN
      BIC(M.UCB0STAT^, M.UCSTTIFG) (* Clear START Flags *)
    END
  END USCIAB0RX_ISR;

(*******************************************************************************
 Main ************************************************************************
 Enters LPM0 and waits for I2C interrupts. The data sent from the master is  *
 then interpreted and the device will respond accordingly                    *
*******************************************************************************)

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)
  SlaveMode := RX_REG_ADDRESS_MODE;
  ReceiveRegAddr := 0;
  RXByteCtr := 0;
  TXByteCtr := 0;
  TransmitIndex := 0;

  initClockTo16MHz;
  initGPIO;
  initI2C;

  SYSTEM.BIS_SR(M.LPM0_bits + M.GIE)
END msp430g2xx3uscib0i2css.
