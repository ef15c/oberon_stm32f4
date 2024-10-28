(******************************************************************************
//   MSP430G2xx3 Demo - USCI_B0, I2C Master multiple byte TX/RX
//
//   Description: I2C master communicates to I2C slave sending and receiving
//   3 different messages of different length. I2C master will enter LPM0 mode
//   while waiting for the messages to be sent/receiving using I2C interrupt.
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
//   C. Schoffit 27.10.24, built with Oberon MSP430 compiler
//******************************************************************************)

MODULE msp430g2xx3uscib0i2csm;
  IMPORT SYSTEM, M := msp430g2553;

  CONST SLAVE_ADDR = 48H;

(*******************************************************************************
   Example Commands ************************************************************
  ******************************************************************************)

(* CMD_TYPE_X_SLAVE are example commands the master sends to the slave.
 * The slave will send example SlaveTypeX buffers in response.
 *
 * CMD_TYPE_X_MASTER are example commands the master sends to the slave.
 * The slave will initialize itself to receive MasterTypeX example buffers.
 * *)

    CMD_TYPE_0_SLAVE = 0;
    CMD_TYPE_1_SLAVE = 1;
    CMD_TYPE_2_SLAVE = 2;

    CMD_TYPE_0_MASTER = 3;
    CMD_TYPE_1_MASTER = 4;
    CMD_TYPE_2_MASTER = 5;

    TYPE_0_LENGTH = 1;
    TYPE_1_LENGTH = 2;
    TYPE_2_LENGTH = 6;

    MAX_BUFFER_SIZE = 20;

(* MasterTypeX are example buffers initialized in the master, they will be
 * sent by the master to the slave.
 * SlaveTypeX are example buffers initialized in the slave, they will be
 * sent by the slave to the master.
 * *)

    MasterType2 = "F4192B";
    MasterType1 = "" + 8X + 9X;
    MasterType0 = ($11$);

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

  VAR SlaveType2: ARRAY TYPE_2_LENGTH OF BYTE;
    SlaveType1: ARRAY TYPE_1_LENGTH OF BYTE;
    SlaveType0: ARRAY TYPE_0_LENGTH OF BYTE;

  (*******************************************************************************
   General I2C State Machine ***************************************************
  ******************************************************************************)

  (* Used to track the state of the software state machine*)
    MasterMode: I2C_Mode;

  (* The Register Address/Command to use*)
    TransmitRegAddr: BYTE;

  (* ReceiveBuffer: Buffer used to receive data in the ISR
   * RXByteCtr: Number of bytes left to receive
   * ReceiveIndex: The index of the next byte to be received in ReceiveBuffer
   * TransmitBuffer: Buffer used to transmit data in the ISR
   * TXByteCtr: Number of bytes left to transfer
   * TransmitIndex: The index of the next byte to be transmitted in TransmitBuffer
   * *)

    ReceiveBuffer, TransmitBuffer: ARRAY MAX_BUFFER_SIZE OF BYTE;
    RXByteCtr, ReceiveIndex, TXByteCtr, TransmitIndex: BYTE;


  (* I2C Write and Read Functions *)

  (* For slave device with dev_addr, writes the data specified in *reg_data
   *
   * dev_addr: The slave device address.
   *           Example: SLAVE_ADDR
   * reg_addr: The register or command to send to the slave.
   *           Example: CMD_TYPE_0_MASTER
   * *reg_data: The buffer to write
   *           Example: MasterType0
   * count: The length of *reg_data
   *           Example: TYPE_0_LENGTH
   *  *)

  PROCEDURE I2C_Master_WriteReg(dev_addr, reg_addr: BYTE; reg_data: ARRAY OF CHAR; count: BYTE);
  BEGIN
    (* Initialize state machine *)
    MasterMode := TX_REG_ADDRESS_MODE;
    TransmitRegAddr := reg_addr;

    (* Copy register data to TransmitBuffer *)
    SYSTEM.COPY(SYSTEM.ADR(reg_data), SYSTEM.ADR(TransmitBuffer), count);

    TXByteCtr := count;
    RXByteCtr := 0;
    ReceiveIndex := 0;
    TransmitIndex := 0;

    (* Initialize slave address and interrupts *)
    M.UCB0I2CSA^ := dev_addr;
    BIC(M.IFG2^, M.UCB0TXIFG + M.UCB0RXIFG); (* Clear any pending interrupts *)
    BIC(M.IE2^, M.UCB0RXIE); (* Disable RX interrupt *)
    BIS(M.IE2^, M.UCB0TXIE); (* Enable TX interrupt *)

    BIS(M.UCB0CTL1^, M.UCTR + M.UCTXSTT); (* I2C TX, start condition *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE) (* Enter LPM0 w/ interrupts *)
  END I2C_Master_WriteReg;


  (* For slave device with dev_addr, read the data specified in slaves reg_addr.
   * The received data is available in ReceiveBuffer
   *
   * dev_addr: The slave device address.
   *           Example: SLAVE_ADDR
   * reg_addr: The register or command to send to the slave.
   *           Example: CMD_TYPE_0_SLAVE
   * count: The length of data to read
   *           Example: TYPE_0_LENGTH
   *  *)

  PROCEDURE I2C_Master_ReadReg(dev_addr, reg_addr, count: BYTE);
  BEGIN
    (* Initialize state machine *)
    MasterMode := TX_REG_ADDRESS_MODE;
    TransmitRegAddr := reg_addr;
    RXByteCtr := count;
    TXByteCtr := 0;
    ReceiveIndex := 0;
    TransmitIndex := 0;

    (* Initialize slave address and interrupts *)
    M.UCB0I2CSA^ := dev_addr;
    BIC(M.IFG2^, M.UCB0TXIFG + M.UCB0RXIFG); (* Clear any pending interrupts *)
    BIC(M.IE2^, M.UCB0RXIE); (* Disable RX interrupt *)
    BIS(M.IE2^, M.UCB0TXIE); (* Enable TX interrupt *)

    BIS(M.UCB0CTL1^, M.UCTR + M.UCTXSTT); (* I2C TX, start condition *)
    SYSTEM.BIS_SR(M.CPUOFF + M.GIE) (* Enter LPM0 w/ interrupts *)
  END I2C_Master_ReadReg;

  (******************************************************************************
   Device Initialization *******************************************************
  ******************************************************************************)

  PROCEDURE initClockTo16MHz;
  BEGIN
    REPEAT UNTIL M.CALBC1_16MHZ^ # {0..7}; (* If calibration constant erased do not load, trap CPU!! *)
    M.DCOCTL^ := {}; (* Select lowest DCOx and MODx settings *)
    M.BCSCTL1^ := M.CALBC1_16MHZ^; (* Set DCO *)
    M.DCOCTL^ := M.CALDCO_16MHZ^
  END initClockTo16MHz;

  PROCEDURE initGPIO;
  BEGIN
    BIS(M.P1DIR^, {0..4});
    BIS(M.P1OUT^, {0..4});

    BIS(M.P1SEL^, {6, 7}); (* Assign I2C pins to USCI_B0 *)
    BIS(M.P1SEL2^, {6, 7}) (* Assign I2C pins to USCI_B0 *)
  END initGPIO;

  PROCEDURE initI2C;
  BEGIN
   BIS(M.UCB0CTL1^, M.UCSWRST); (* Enable SW reset *)
    M.UCB0CTL0^ := M.UCMST + M.UCMODE_3 + M.UCSYNC; (* I2C Master, synchronous mode *)
    M.UCB0CTL1^ := M.UCSSEL_2 + M.UCSWRST; (* Use SMCLK, keep SW reset *)
    M.UCB0BR0^ := 160; (* fSCL = SMCLK/160 = ~100kHz *)
    M.UCB0BR1^ := 0;
    M.UCB0I2CSA^ := SLAVE_ADDR; (* Slave Address *)
    BIC(M.UCB0CTL1^, M.UCSWRST); (* Clear SW reset, resume operation *)
    BIS(M.UCB0I2CIE^, M.UCNACKIE)
  END initI2C;

  (* for USCI29 silicon erratum *)
  PROCEDURE* (M.TRAPINT_VECTOR) ^0 TRAPINT_ISR;
  END TRAPINT_ISR;

  (*******************************************************************************
   I2C Interrupt For Received and Transmitted Data******************************
  ******************************************************************************)

  PROCEDURE* (M.USCIAB0TX_VECTOR) ^-1 USCIAB0TX_ISR;
    VAR rx_val: BYTE*;
  BEGIN
    IF BIT(M.IFG2^, M.UCB0RXIFG) THEN (* Receive Data Interrupt *)
      (* Must read from UCB0RXBUF *)
      rx_val := M.UCB0RXBUF^;

      IF RXByteCtr # 0 THEN
          ReceiveBuffer[ReceiveIndex] := rx_val; INC(ReceiveIndex);
          DEC(RXByteCtr)
      END;

      IF RXByteCtr = 1 THEN BIS(M.UCB0CTL1^, M.UCTXSTP)
      ELSIF RXByteCtr = 0 THEN
          BIC(M.IE2^, M.UCB0RXIE);
          MasterMode := IDLE_MODE;
          SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
      END
    ELSIF BIT(M.IFG2^, M.UCB0TXIFG) THEN (* Transmit Data Interrupt *)
      IF MasterMode = TX_REG_ADDRESS_MODE THEN
        M.UCB0TXBUF^ := TransmitRegAddr;
        IF RXByteCtr # 0 THEN  MasterMode := SWITCH_TO_RX_MODE (* Need to start receiving now *)
        ELSE MasterMode := TX_DATA_MODE; (* Continue to transmision with the data in Transmit Buffer *)
        END
      ELSIF MasterMode = SWITCH_TO_RX_MODE THEN
        BIS(M.IE2^, M.UCB0RXIE); (* Enable RX interrupt *)
        BIC(M.IE2^, M.UCB0TXIE); (* Disable TX interrupt *)
        BIC( M.UCB0CTL1^, M.UCTR); (* Switch to receiver *)
        MasterMode := RX_DATA_MODE; (* State state is to receive data *)
        BIS(M.UCB0CTL1^, M.UCTXSTT); (* Send repeated start *)
        IF RXByteCtr = 1 THEN (*Must send stop since this is the N-1 byte *)
          REPEAT UNTIL ~BIT(M.UCB0CTL1^, M.UCTXSTT);
          BIS(M.UCB0CTL1^, M.UCTXSTP) (* Send stop condition *)
        END
      ELSIF MasterMode = TX_DATA_MODE THEN
        IF TXByteCtr # 0 THEN
          M. UCB0TXBUF^ := TransmitBuffer[TransmitIndex]; INC(TransmitIndex);
          DEC(TXByteCtr)
        ELSE (* Done with transmission *)
          BIS(M.UCB0CTL1^, M.UCTXSTP); (* Send stop condition *)
          MasterMode := IDLE_MODE;
          BIC(M.IE2^, M.UCB0TXIE); (* disable TX interrupt *)
          SYSTEM.BIC_SR_ON_EXIT(M.CPUOFF) (* Exit LPM0 *)
        END
      ELSE NOP
      END
    END
  END USCIAB0TX_ISR;


  (******************************************************************************
   I2C Interrupt For Start, Restart, Nack, Stop ********************************
  ******************************************************************************)

  PROCEDURE* (M.USCIAB0RX_VECTOR) ^0 USCIAB0RX_ISR;
  BEGIN
    IF BIT(M.UCB0STAT^, M.UCNACKIFG) THEN BIC(M.UCB0STAT^, M.UCNACKIFG) (* Clear NACK Flags *) END;
    IF BIT(M.UCB0STAT^, M.UCSTPIFG) THEN (* Stop or NACK Interrupt *)
      BIC(M.UCB0STAT^, M.UCSTTIFG + M.UCSTPIFG + M.UCNACKIFG) (* Clear START/STOP/NACK Flags *)
    END;
    IF BIT(M.UCB0STAT^, M.UCSTTIFG) THEN BIC(M.UCB0STAT^, M.UCSTTIFG) (* Clear START Flags *) END
  END USCIAB0RX_ISR;


  (******************************************************************************
   Main ************************************************************************
   Send and receive three messages containing the example commands *************
  ******************************************************************************)

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD; (* Stop watchdog timer *)

  MasterMode := IDLE_MODE;
  TransmitRegAddr := 0;
  RXByteCtr := 0; ReceiveIndex := 0;
  TXByteCtr := 0; TransmitIndex := 0;

  initClockTo16MHz();
  initGPIO();
  initI2C();

  I2C_Master_WriteReg(SLAVE_ADDR, CMD_TYPE_0_MASTER, MasterType0, TYPE_0_LENGTH);
  I2C_Master_WriteReg(SLAVE_ADDR, CMD_TYPE_1_MASTER, MasterType1, TYPE_1_LENGTH);
  I2C_Master_WriteReg(SLAVE_ADDR, CMD_TYPE_2_MASTER, MasterType2, TYPE_2_LENGTH);

  I2C_Master_ReadReg(SLAVE_ADDR, CMD_TYPE_0_SLAVE, TYPE_0_LENGTH);
  SYSTEM.COPY(SYSTEM.ADR(ReceiveBuffer), SYSTEM.ADR(SlaveType0), TYPE_0_LENGTH);

  I2C_Master_ReadReg(SLAVE_ADDR, CMD_TYPE_1_SLAVE, TYPE_1_LENGTH);
  SYSTEM.COPY(SYSTEM.ADR(ReceiveBuffer), SYSTEM.ADR(SlaveType1), TYPE_1_LENGTH);

  I2C_Master_ReadReg(SLAVE_ADDR, CMD_TYPE_2_SLAVE, TYPE_2_LENGTH);
  SYSTEM.COPY(SYSTEM.ADR(ReceiveBuffer), SYSTEM.ADR(SlaveType2), TYPE_2_LENGTH);

  SYSTEM.BIS_SR(M.LPM0_bits +M. GIE)
END msp430g2xx3uscib0i2csm.

OMSPTool.DecObj msp430g2xx3uscib0i2csm.mpc
decode msp430g2xx3uscib0i2csm.mpc
msp430g2xx3uscib0i2csm 4A6C115A Flash   730
imports:
	msp430g2553 F10488DC
type descriptors

data    56
strings
F4192B||	|||
vector table
 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF
 0000 FFFF FFFF FFFF FFFF FFFF 0000 0000 FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF

entries
 c 01F0
fixup procedures chains
 0262     0	 0000
 02B0     0	 0056
 0210     0	 0094
 0214     0	 00AC
 0218     0	 00C6
fixup handlers chains
 0110     0	 00F0
 0116     0	 00F2
 0117     0	 01CE
fixup data chains
 01F8     0	 000A
 01FC     0	 000B
 01A4     0	 0020
 0208     0	 0036
 0200     0	 0034
 0204     0	 0035
 020C     0	 0037
 02BC     0	 000C
fixup constants chains
 025A     0	 0000
 0240     0	 0008
 0226     0	 000C
fixup types chains
entry =  01F0
code   716
 0000	     43E2	MOV.B #2,&0
 0002	     0000
 0004	     41D2	MOV.B 8(SP),&0
 0006	     0008
 0008	     0000
 000A	     415F	MOV.B 2(SP),R15
 000C	     0002
 000E	     2409	JEQ $+20, goes to  0022
 0010	     411E	MOV 4(SP),R14
 0012	     0004
 0014	     403D	MOV #0,R13
 0016	     0000
 0018	     4EBD	MOV @R14+,0(R13)
 001A	     0000
 001C	     532D	ADD #2,R13
 001E	     831F	SUB #1,R15
 0020	     23FB	JNE $-8, goes to  0018
 0022	     41D2	MOV.B 2(SP),&0
 0024	     0002
 0026	     0000
 0028	     43C2	MOV.B #0,&0
 002A	     0000
 002C	     43C2	MOV.B #0,&0
 002E	     0000
 0030	     43C2	MOV.B #0,&0
 0032	     0000
 0034	     415F	MOV.B 10(SP),R15
 0036	     000A
 0038	     4F82	MOV R15,&282
 003A	     011A
 003C	     C0F2	BIC.B #12,&3
 003E	     000C
 0040	     0003
 0042	     C2E2	BIC.B #4,&1
 0044	     0001
 0046	     D2F2	BIS.B #8,&1
 0048	     0001
 004A	     D0F2	BIS.B #18,&105
 004C	     0012
 004E	     0069
 0050	     D032	BIS #24,SR
 0052	     0018
 0054	     4130	RET
 0056	     43E2	MOV.B #2,&2
 0058	     0002
 005A	     41D2	MOV.B 4(SP),&8
 005C	     0004
 005E	     0008
 0060	     41D2	MOV.B 2(SP),&42
 0062	     0002
 0064	     002A
 0066	     43C2	MOV.B #0,&38
 0068	     0026
 006A	     43C2	MOV.B #0,&46
 006C	     002E
 006E	     43C2	MOV.B #0,&50
 0070	     0032
 0072	     415F	MOV.B 6(SP),R15
 0074	     0006
 0076	     4F82	MOV R15,&282
 0078	     011A
 007A	     C0F2	BIC.B #12,&3
 007C	     000C
 007E	     0003
 0080	     C2E2	BIC.B #4,&1
 0082	     0001
 0084	     D2F2	BIS.B #8,&1
 0086	     0001
 0088	     D0F2	BIS.B #18,&105
 008A	     0012
 008C	     0069
 008E	     D032	BIS #24,SR
 0090	     0018
 0092	     4130	RET
 0094	     93F2	CMP.B #-1,&4345
 0096	     10F9
 0098	     27FD	JEQ $-4, goes to  0094
 009A	     43C2	MOV.B #0,&86
 009C	     0056
 009E	     42D2	MOV.B &4345,&87
 00A0	     10F9
 00A2	     0057
 00A4	     42D2	MOV.B &4344,&86
 00A6	     10F8
 00A8	     0056
 00AA	     4130	RET
 00AC	     D0F2	BIS.B #31,&34
 00AE	     001F
 00B0	     0022
 00B2	     D0F2	BIS.B #31,&33
 00B4	     001F
 00B6	     0021
 00B8	     D0F2	BIS.B #192,&38
 00BA	     00C0
 00BC	     0026
 00BE	     D0F2	BIS.B #192,&65
 00C0	     00C0
 00C2	     0041
 00C4	     4130	RET
 00C6	     D3D2	BIS.B #1,&105
 00C8	     0069
 00CA	     40F2	MOV.B #15,&104
 00CC	     000F
 00CE	     0068
 00D0	     40F2	MOV.B #129,&105
 00D2	     0081
 00D4	     0069
 00D6	     40F2	MOV.B #160,&106
 00D8	     00A0
 00DA	     006A
 00DC	     43C2	MOV.B #0,&107
 00DE	     006B
 00E0	     40B2	MOV #72,&282
 00E2	     0048
 00E4	     011A
 00E6	     C3D2	BIC.B #1,&105
 00E8	     0069
 00EA	     D2F2	BIS.B #8,&108
 00EC	     006C
 00EE	     4130	RET
 00F0	     1300	RETI
 00F2	     1204	PUSH R4
 00F4	     B2E2	BIT.B #4,&3
 00F6	     0003
 00F8	     2420	JEQ $+66, goes to  013A
 00FA	     4254	MOV.B &110,R4
 00FC	     006E
 00FE	     93C2	CMP.B #0,&100
 0100	     0064
 0102	     240A	JEQ $+22, goes to  0118
 0104	     4254	MOV.B &108,R4
 0106	     006C
 0108	     5034	ADD #0,R4
 010A	     0000
 010C	     44C4	MOV.B R4,0(R4)
 010E	     0000
 0110	     53D2	ADD.B #1,&262
 0112	     0106
 0114	     83D2	SUB.B #1,&256
 0116	     0100
 0118	     93D2	CMP.B #1,&278
 011A	     0116
 011C	     2003	JNE $+8, goes to  0124
 011E	     D2E2	BIS.B #4,&105
 0120	     0069
 0122	     3C0A	JMP $+22, goes to  0138
 0124	     93C2	CMP.B #0,&282
 0126	     011A
 0128	     2007	JNE $+16, goes to  0138
 012A	     C2E2	BIC.B #4,&1
 012C	     0001
 012E	     43C2	MOV.B #0,&88
 0130	     0058
 0132	     C0B1	BIC #16,2(SP)
 0134	     0010
 0136	     0002
 0138	     3C48	JMP $+146, goes to  01CA
 013A	     B2F2	BIT.B #8,&3
 013C	     0003
 013E	     2445	JEQ $+140, goes to  01CA
 0140	     93E2	CMP.B #2,&304
 0142	     0130
 0144	     200D	JNE $+28, goes to  0160
 0146	     42D2	MOV.B &94,&111
 0148	     005E
 014A	     006F
 014C	     93C2	CMP.B #0,&294
 014E	     0126
 0150	     2404	JEQ $+10, goes to  015A
 0152	     40F2	MOV.B #6,&322
 0154	     0006
 0156	     0142
 0158	     3C02	JMP $+6, goes to  015E
 015A	     42E2	MOV.B #4,&342
 015C	     0156
 015E	     3C35	JMP $+108, goes to  01CA
 0160	     90F2	CMP.B #6,&348
 0162	     0006
 0164	     015C
 0166	     2015	JNE $+44, goes to  0192
 0168	     D2E2	BIS.B #4,&1
 016A	     0001
 016C	     C2F2	BIC.B #8,&1
 016E	     0001
 0170	     C0F2	BIC.B #16,&105
 0172	     0010
 0174	     0069
 0176	     40F2	MOV.B #5,&356
 0178	     0005
 017A	     0164
 017C	     D3E2	BIS.B #2,&105
 017E	     0069
 0180	     93D2	CMP.B #1,&334
 0182	     014E
 0184	     2005	JNE $+12, goes to  0190
 0186	     B3E2	BIT.B #2,&105
 0188	     0069
 018A	     23FD	JNE $-4, goes to  0186
 018C	     D2E2	BIS.B #4,&105
 018E	     0069
 0190	     3C1C	JMP $+58, goes to  01CA
 0192	     92E2	CMP.B #4,&378
 0194	     017A
 0196	     2018	JNE $+50, goes to  01C8
 0198	     93C2	CMP.B #0,&104
 019A	     0068
 019C	     240B	JEQ $+24, goes to  01B4
 019E	     4254	MOV.B &112,R4
 01A0	     0070
 01A2	     5034	ADD #22,R4
 01A4	     0016
 01A6	     44E2	MOV.B @R4,&111
 01A8	     006F
 01AA	     53D2	ADD.B #1,&416
 01AC	     01A0
 01AE	     83D2	SUB.B #1,&410
 01B0	     019A
 01B2	     3C09	JMP $+20, goes to  01C6
 01B4	     D2E2	BIS.B #4,&105
 01B6	     0069
 01B8	     43C2	MOV.B #0,&404
 01BA	     0194
 01BC	     C2F2	BIC.B #8,&1
 01BE	     0001
 01C0	     C0B1	BIC #16,2(SP)
 01C2	     0010
 01C4	     0002
 01C6	     3C01	JMP $+4, goes to  01CA
 01C8	     4303	NOP
 01CA	     4134	POP R4
 01CC	     1300	RETI
 01CE	     B2F2	BIT.B #8,&109
 01D0	     006D
 01D2	     2402	JEQ $+6, goes to  01D8
 01D4	     C2F2	BIC.B #8,&109
 01D6	     006D
 01D8	     B2E2	BIT.B #4,&109
 01DA	     006D
 01DC	     2403	JEQ $+8, goes to  01E4
 01DE	     C0F2	BIC.B #14,&109
 01E0	     000E
 01E2	     006D
 01E4	     B3E2	BIT.B #2,&109
 01E6	     006D
 01E8	     2402	JEQ $+6, goes to  01EE
 01EA	     C3E2	BIC.B #2,&109
 01EC	     006D
 01EE	     1300	RETI
 01F0	     40B2	MOV #23168,&288
 01F2	     5A80
 01F4	     0120
 01F6	     43C2	MOV.B #0,&442
 01F8	     01BA
 01FA	     43C2	MOV.B #0,&328
 01FC	     0148
 01FE	     43C2	MOV.B #0,&386
 0200	     0182
 0202	     43C2	MOV.B #0,&274
 0204	     0112
 0206	     43C2	MOV.B #0,&432
 0208	     01B0
 020A	     43C2	MOV.B #0,&428
 020C	     01AC
 020E	     12B0	CALL #0
 0210	     0000
 0212	     12B0	CALL #0
 0214	     0000
 0216	     12B0	CALL #0
 0218	     0000
 021A	     1230	PUSH #72
 021C	     0048
 021E	     1230	PUSH #3
 0220	     0003
 0222	     1213	PUSH #1
 0224	     1230	PUSH #0
 0226	     0000
 0228	     1213	PUSH #1
 022A	     12B0	CALL #0
 022C	     0000
 022E	     5031	ADD #10,SP
 0230	     000A
 0232	     1230	PUSH #72
 0234	     0048
 0236	     1230	PUSH #4
 0238	     0004
 023A	     1230	PUSH #3
 023C	     0003
 023E	     1230	PUSH #0
 0240	     0000
 0242	     1223	PUSH #2
 0244	     12B0	CALL #556
 0246	     022C
 0248	     5031	ADD #10,SP
 024A	     000A
 024C	     1230	PUSH #72
 024E	     0048
 0250	     1230	PUSH #5
 0252	     0005
 0254	     1230	PUSH #7
 0256	     0007
 0258	     1230	PUSH #0
 025A	     0000
 025C	     1230	PUSH #6
 025E	     0006
 0260	     12B0	CALL #582
 0262	     0246
 0264	     5031	ADD #10,SP
 0266	     000A
 0268	     1230	PUSH #72
 026A	     0048
 026C	     1203	PUSH #0
 026E	     1213	PUSH #1
 0270	     12B0	CALL #0
 0272	     0000
 0274	     5031	ADD #6,SP
 0276	     0006
 0278	     431F	MOV #1,R15
 027A	     403E	MOV #266,R14
 027C	     010A
 027E	     4EBE	MOV @R14+,-6(R14)
 0280	     FFFA
 0282	     831F	SUB #1,R15
 0284	     23FC	JNE $-6, goes to  027E
 0286	     1230	PUSH #72
 0288	     0048
 028A	     1213	PUSH #1
 028C	     1223	PUSH #2
 028E	     12B0	CALL #626
 0290	     0272
 0292	     5031	ADD #6,SP
 0294	     0006
 0296	     432F	MOV #2,R15
 0298	     403E	MOV #636,R14
 029A	     027C
 029C	     4EBE	MOV @R14+,-8(R14)
 029E	     FFF8
 02A0	     831F	SUB #1,R15
 02A2	     23FC	JNE $-6, goes to  029C
 02A4	     1230	PUSH #72
 02A6	     0048
 02A8	     1223	PUSH #2
 02AA	     1230	PUSH #6
 02AC	     0006
 02AE	     12B0	CALL #656
 02B0	     0290
 02B2	     5031	ADD #6,SP
 02B4	     0006
 02B6	     403F	MOV #6,R15
 02B8	     0006
 02BA	     403E	MOV #666,R14
 02BC	     029A
 02BE	     4EBE	MOV @R14+,-14(R14)
 02C0	     FFF2
 02C2	     831F	SUB #1,R15
 02C4	     23FC	JNE $-6, goes to  02BE
 02C6	     D032	BIS #24,SR
 02C8	     0018
 02CA	     4130	RET
