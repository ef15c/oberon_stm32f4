MODULE PS2; (*PS/2 Mouse and keyboard driver*)
  IMPORT SYSTEM, BSP, Kernel;

  CONST NONE = 0; DEVICE_TO_HOST = 1; HOST_TO_DEVICE = 2; (*direction*)
    SUCCESS = 0; IN_PROGRESS = 1; FRAME_ERROR = 2; PARITY_ERROR = 3; NAK = 4; NO_ANSWER = 5; (*status*)
    NO_DEVICE = 0; KEYBOARD = 1; MOUSE = 2;

    BUFFERSIZE = 16;

  TYPE MKB = POINTER TO MKDataBlock;
    MKDataBlock = RECORD
      head, tail: INTEGER; (*Indexes of head and tail of the circular keyboard buffer*)
      kdbBuf: ARRAY BUFFERSIZE OF BYTE;
      MD: INTEGER; (*mouse data*)
      MW, MH: INTEGER; (*mouse limits*)
    END;

  DeviceDesc = RECORD
      direction, statusIn, statusOut, connectedDevice: BYTE;
      clockPin, dataPin: BYTE;
      nofBitsToBeRead, parity: BYTE;
      parityEnabled: BOOLEAN;
      clockIdr, dataIdr, clockPinOut, dataPinOut, ActivityLedOut: LONGINT;
      dataIn, dataOut: INTEGER;
      answerBlock: MKDataBlock;
      tickLastReport, mouseIndex, mouseReportSize: INTEGER;
      mouseBuffer: ARRAY 4 OF BYTE;
    END;

  PROCEDURE PutByteInFIFOBuffer(VAR dev: DeviceDesc);
    VAR bk!: MKB;
      curTick, x, y, dx, dy: INTEGER;
      next: INTEGER;
  BEGIN SYSTEM.PUT(SYSTEM.ADR(bk), SYSTEM.ADR(dev.answerBlock));
    IF dev.connectedDevice = MOUSE THEN
      curTick := Kernel.Time();
      IF curTick - dev.tickLastReport > 5 THEN (*The mouse didn't send report for a while. Start to begin of frame*)
        dev.mouseIndex := 0; dev.tickLastReport := curTick
      END;
      dev.mouseBuffer[dev.mouseIndex] := dev.dataIn; INC(dev.mouseIndex);
      IF dev.mouseIndex >= dev.mouseReportSize THEN (*Process Report*)
        dev.mouseIndex := 0;
        IF LSR(dev.mouseBuffer[0], 6) = 0 THEN (*No overflow*)
          x := bk.MD MOD 1000H; y := LSR(bk.MD, 12) MOD 1000H;
          dx := dev.mouseBuffer[1]; dy := dev.mouseBuffer[2];
          IF ODD(LSR(dev.mouseBuffer[0], 4)) THEN (*dx is negative*) DEC(dx, 100H) END;
          INC(x, dx); IF x < 0 THEN x := 0 ELSIF x >= bk.MW THEN x := bk.MW - 1 END;
          IF ODD(LSR(dev.mouseBuffer[0], 5)) THEN (*dy is negative*) DEC(dy, 100H) END;
          INC(y, dy); IF y < 0 THEN y := 0 ELSIF y >= bk.MH THEN y := bk.MH - 1 END;
          (*Pack mouse report in Oberon's format*)
          bk.MD := LSL(LSR(dev.mouseBuffer[0], 1) MOD 4, 24) + LSL(ORD(ODD(dev.mouseBuffer[0])), 26) + x MOD 1000H + LSL(y MOD 1000H, 12)
        END
      END
    ELSE next := (bk.head + 1) MOD BUFFERSIZE;
      IF next # bk.tail THEN (*buffer has free space*)
        bk.kdbBuf[bk.head] := dev.dataIn; bk.head := next
      END
    END
  END PutByteInFIFOBuffer;

  PROCEDURE requestToSend(VAR dev: DeviceDesc);
  BEGIN
    IF dev.ActivityLedOut # 0 THEN SYSTEM.PUT(dev.ActivityLedOut, TRUE) (*Turn activity LED on*) END;
    SYSTEM.PUT(dev.clockPinOut, 0); BSP.Delayus(150); (*wait for at least 100 microseconds*)
    SYSTEM.PUT(dev.dataPinOut, 0); SYSTEM.PUT(dev.clockPinOut, 1)
    (*now, wait for device to generate clock pulses*)
  END requestToSend;

  PROCEDURE SendByteAsync(VAR dev: DeviceDesc; data: BYTE);
    VAR i: INTEGER; parity: BYTE;
  BEGIN
    dev.direction := HOST_TO_DEVICE; dev.dataOut := (data + 200H)*2;
    (*Parity computation*)
    FOR i := 0 TO 7 DO INC(parity, ORD(ODD(data))); data := LSR(data, 1) END;
    INC(dev.dataOut, LSL(ORD(ODD(parity)), 9)); dev.statusOut := IN_PROGRESS;
    requestToSend(dev)
  END SendByteAsync;

  PROCEDURE ProcessData(VAR dev: DeviceDesc); (*Process a data bit from/to a PS/2 port.*)
  (* Warning : this function is call via a GPIO interrupt : keep it as fast as possible *)
    VAR dataBit: BOOLEAN;
  BEGIN IF dev.direction = NONE THEN
      IF SYSTEM.BIT(dev.clockIdr, dev.clockPin) THEN dev.direction := DEVICE_TO_HOST;
        IF dev.ActivityLedOut # 0 THEN SYSTEM.PUT(dev.ActivityLedOut, FALSE) (*Turn activity LED off*) END
      END
      ELSIF dev.direction = DEVICE_TO_HOST THEN
        IF ~SYSTEM.BIT(dev.clockIdr, dev.clockPin) THEN (* Falling edge of clock *)
          dataBit := SYSTEM.BIT(dev.dataIdr, dev.dataPin);
          IF dev.nofBitsToBeRead = 11 THEN 
            IF dev.ActivityLedOut # 0 THEN SYSTEM.PUT(dev.ActivityLedOut, TRUE) (*Turn activity LED on*) END;
            IF dataBit THEN dev.statusIn := FRAME_ERROR ELSE dev.statusIn := IN_PROGRESS END;
            dev.dataIn := 0; dev.parity := 1
          ELSIF dev.statusIn = IN_PROGRESS THEN
            IF dev.nofBitsToBeRead > 2 THEN dev.dataIn := LSR(dev.dataIn, 1); INC(dev.dataIn, LSL(ORD(dataBit), 7));
              INC(dev.parity, ORD(dataBit))
            ELSIF (dev.nofBitsToBeRead = 2) & dev.parityEnabled THEN
              IF ODD(dev.parity + ORD(dataBit)) THEN dev.statusIn := PARITY_ERROR; SendByteAsync(dev, 0FEH)
              ELSE dev.statusIn := IN_PROGRESS END
            ELSE IF dataBit THEN dev.statusIn := SUCCESS ELSE dev.statusIn := FRAME_ERROR END
            END;
            DEC(dev.nofBitsToBeRead);
            IF dev.nofBitsToBeRead = 0 THEN
              dev.nofBitsToBeRead := 11;
              IF (dev.statusIn = SUCCESS) OR ~dev.parityEnabled THEN PutByteInFIFOBuffer(dev) ELSE SendByteAsync(dev, 0FEH) END;
              IF dev.ActivityLedOut # 0 THEN SYSTEM.PUT(dev.ActivityLedOut, FALSE) (*Turn activity LED off*) END
            END
          END
        END
      ELSIF dev.direction = HOST_TO_DEVICE THEN
        IF ~SYSTEM.BIT(dev.clockIdr, dev.clockPin) THEN (*falling edge*)
          IF dev.dataOut # 0 THEN (*Send data to device*) SYSTEM.PUT(dev.dataPinOut, ODD(dev.dataOut)); dev.dataOut := LSR(dev.dataOut, 1)
          ELSE (*Check ACK from device*) IF SYSTEM.BIT(dev.dataIdr, dev.dataPin) THEN dev.statusOut := NAK ELSE dev.statusOut := SUCCESS END;
            dev.direction := NONE; dev.nofBitsToBeRead := 11
        END
      END
    END
  END ProcessData;

END PS2.
