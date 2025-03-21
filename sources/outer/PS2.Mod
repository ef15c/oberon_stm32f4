MODULE PS2; (*PS/2 Mouse and keyboard driver*)
  IMPORT SYSTEM, BSP, Kernel;

  CONST ON = 1; OFF = 0; HIGH = 1; LOW = 0;
    NONE = 0; DEVICE_TO_HOST = 1; HOST_TO_DEVICE = 2; (*direction*)
    SUCCESS* = 0; IN_PROGRESS* = 1; FRAME_ERROR* = 2; PARITY_ERROR* = 3; NAK* = 4; NO_ANSWER* = 5; (*status*)
    NO_DEVICE* = 0; KEYBOARD* = 1; MOUSE* = 2;

    BUFFERSIZE* = 16;

  TYPE
    CircularBuffer* = POINTER TO CircularBufferDesc;
    CircularBufferDesc* = RECORD
      head*, tail*: INTEGER; (*Indexes of head and tail of the circular keyboard buffer*)
      buffer*: ARRAY BUFFERSIZE OF BYTE
    END;

    MKB* = POINTER TO MKDataBlock;
    MKDataBlock* = RECORD
      KB*: CircularBufferDesc;
      MD*: INTEGER; (*mouse data*)
      MW*, MH*: INTEGER; (*mouse limits*)
    END;

  Device* = POINTER TO DeviceDesc;
  DeviceDesc* = RECORD
      direction, statusIn*, statusOut*, connectedDevice*: BYTE;
      clockPin*, nofBitsToBeRead, parity: BYTE;
      parityEnabled*, haveWheel: BOOLEAN;
      clock_In*, data_In*, clock_Out*, data_Out*, activityLED, mouseLED*, keyboardLED*: INTEGER;
      dataIn, dataOut, tickLastReport, mouseReportSize, badEdge*: INTEGER;
      dest*: CircularBuffer; buf: CircularBufferDesc
    END;

  VAR mkb*: MKB; mkbBlock: MKDataBlock; keyboard*: Device;
    KBLeds: SET;

  PROCEDURE^3 PutByteInFIFOBuffer(VAR dev: DeviceDesc);
    CONST YO = 7; XO = 6; YS = 5; XS = 4; MBO = 3; BM = 2; BR = 1; BL = 0;
      MaxMove = 200;
    VAR curTick, x, y, dx, dy: INTEGER; flags: SET;
      next: INTEGER;
  BEGIN
    IF dev.connectedDevice = MOUSE THEN
      curTick := Kernel.Time();
      IF curTick - dev.tickLastReport > 5 THEN (*The mouse didn't send report for a while. Start to begin of frame*)
        dev.buf.head := 0; dev.tickLastReport := curTick
      END;
      dev.buf.buffer[dev.buf.head] := dev.dataIn; INC(dev.buf.head);
      IF dev.buf.head >= dev.mouseReportSize THEN (*Process Report*)
        dev.buf.head := 0; flags := SYSTEM.VAL(SET, 0+dev.buf.buffer[0]);
        IF flags*{XO, YO, MBO} = {MBO} THEN (*No overflow*)
          x := mkb.MD MOD 1000H; y := LSR(mkb.MD, 12) MOD 1000H;
          dx := dev.buf.buffer[1]; dy := dev.buf.buffer[2];
          IF flags*{XS} # {} THEN (*dx is negative*) DEC(dx, 100H) END;
          IF flags*{YS} # {} THEN (*dy is negative*) DEC(dy, 100H) END;
          IF (dx > -MaxMove) & (dx < MaxMove) & (dy > -MaxMove) & (dy < MaxMove) THEN (*accept packet*)
            INC(x, dx); IF x < 0 THEN x := 0 ELSIF x >= mkb.MW THEN x := mkb.MW - 1 END;
            INC(y, dy); IF y < 0 THEN y := 0 ELSIF y >= mkb.MH THEN y := mkb.MH - 1 END;
            (*Pack mouse report in Oberon's format*)
            mkb.MD := LSL(ORD(flags*{BM, BR}), 23) + LSL(ORD(flags*{BL}), 26) + x MOD 1000H + LSL(y MOD 1000H, 12)
          END
        END
      END
    ELSE next := (dev.dest.head + 1) MOD BUFFERSIZE;
      IF next # dev.dest.tail THEN (*buffer has free space*) dev.dest.buffer[dev.dest.head] := dev.dataIn; dev.dest.head := next END
    END
  END PutByteInFIFOBuffer;

  PROCEDURE^3 requestToSend(VAR dev: DeviceDesc);
  BEGIN
    IF dev.activityLED # 0 THEN SYSTEM.PUT(dev.activityLED, ON) END;
    SYSTEM.PUT(dev.clock_Out, LOW); BSP.Delayus(150); (*wait for at least 100 microseconds*)
    SYSTEM.PUT(dev.data_Out, LOW); SYSTEM.PUT(dev.clock_Out, HIGH)
    (*now, wait for device to generate clock pulses*)
  END requestToSend;

  PROCEDURE^3 SendByteAsync*(VAR dev: DeviceDesc; data: BYTE);
    VAR i: INTEGER; parity: BYTE;
  BEGIN parity := 1;
    dev.direction := HOST_TO_DEVICE; dev.dataOut := (data + 200H)*2;
    (*Parity computation*)
    FOR i := 0 TO 7 DO INC(parity, ORD(ODD(data))); data := LSR(data, 1) END;
    INC(dev.dataOut, LSL(ORD(ODD(parity)), 9)); dev.statusOut := IN_PROGRESS;
    requestToSend(dev)
  END SendByteAsync;

  PROCEDURE DrawByteFormFIFOBuffer(VAR dev: DeviceDesc): INTEGER;
    VAR res: INTEGER;
  BEGIN
    IF dev.dest.tail # dev.dest.head THEN (*The buffer has unread data*)
      res := dev.dest.buffer[dev.dest.tail];
      dev.dest.tail := (dev.dest.tail+1) MOD BUFFERSIZE;
    ELSE res := -1
    END;
    RETURN res
  END DrawByteFormFIFOBuffer;


  PROCEDURE WaitForAnswer*(VAR dev: DeviceDesc; timeout: INTEGER): INTEGER;
    VAR answer: INTEGER;
  BEGIN
    answer := DrawByteFormFIFOBuffer(dev);
    WHILE (answer = -1) & (timeout # 0) DO DEC(timeout); (*Wait until buffer is not empty*)
    	BSP.Delayus(1000);
        answer := DrawByteFormFIFOBuffer(dev)
    END;
    RETURN answer
  END WaitForAnswer;

  PROCEDURE^3 ProcessData*(VAR dev: DeviceDesc); (*Process a data bit from/to a PS/2 port.*)
  (* Warning : this function is call via a GPIO interrupt : keep it as fast as possible *)
    VAR clockBit, dataBit: BOOLEAN;
  BEGIN SYSTEM.GET(dev.clock_In, clockBit); SYSTEM.GET(dev.data_In, dataBit);
    IF dev.direction = DEVICE_TO_HOST THEN
      IF ~clockBit THEN (* Falling edge of clock *)
        IF dev.nofBitsToBeRead = 11 THEN 
          IF dev.activityLED # 0 THEN SYSTEM.PUT(dev.activityLED, ON) END;
          IF dataBit THEN dev.statusIn := FRAME_ERROR 
          ELSE dev.statusIn := IN_PROGRESS END;
          dev.dataIn := 0; dev.parity := 1
        ELSIF dev.statusIn = IN_PROGRESS THEN
          IF dev.nofBitsToBeRead > 2 THEN dev.dataIn := LSR(dev.dataIn, 1); INC(dev.dataIn, LSL(ORD(dataBit), 7));
            INC(dev.parity, ORD(dataBit))
          ELSIF (dev.nofBitsToBeRead = 2) & dev.parityEnabled THEN
            IF ODD(dev.parity + ORD(dataBit)) THEN dev.statusIn := PARITY_ERROR; SendByteAsync(dev, 0FEH); dev.dataOut := LSR(dev.dataOut, 1)
            ELSE dev.statusIn := IN_PROGRESS END
          ELSE IF dataBit THEN dev.statusIn := SUCCESS ELSE dev.statusIn := FRAME_ERROR END
          END
        END;
        DEC(dev.nofBitsToBeRead);
        IF dev.nofBitsToBeRead = 0 THEN
          dev.nofBitsToBeRead := 11;
          IF (dev.statusIn = SUCCESS) OR ~dev.parityEnabled THEN 
            SYSTEM.PUT(dev.clock_Out, LOW); (*Keep clock low while processing byte*); PutByteInFIFOBuffer(dev);
            SYSTEM.PUT(dev.clock_Out, HIGH); (*Release clock*)
          ELSE SendByteAsync(dev, 0FEH); dev.dataOut := LSR(dev.dataOut, 1) END;
          IF dev.activityLED # 0 THEN SYSTEM.PUT(dev.activityLED, OFF) END
        END
      ELSE INC(dev.badEdge)
      END
    ELSIF dev.direction = HOST_TO_DEVICE THEN
      IF ~clockBit THEN (*falling edge*)
        IF dev.dataOut # 0 THEN (*Send data to device*) SYSTEM.PUT(dev.data_Out, ODD(dev.dataOut)); dev.dataOut := LSR(dev.dataOut, 1)
        ELSE (*Check ACK from device*) IF dataBit THEN dev.statusOut := NAK ELSE dev.statusOut := SUCCESS END;
          dev.direction := DEVICE_TO_HOST; dev.nofBitsToBeRead := 11
        END
      ELSE INC(dev.badEdge)
      END
    END; Kernel.setSPHWM
  END ProcessData;

  PROCEDURE SendByte*(VAR dev: DeviceDesc; data: BYTE): BYTE;
  BEGIN
    SendByteAsync(dev, data);
    REPEAT UNTIL dev.statusIn # IN_PROGRESS; (*wait for answer*)
    RETURN dev.statusIn
  END SendByte;

  PROCEDURE SetCapsLock*(state: BOOLEAN);
    VAR rc: INTEGER;
  BEGIN
    IF keyboard # NIL THEN BSP.Delayus(20000);
      IF state THEN INCL(KBLeds, 2) ELSE EXCL(KBLeds, 2) END;
      SendByteAsync(keyboard^, 0EDH);
      IF WaitForAnswer(keyboard^, 35) = 0FAH THEN
        SendByteAsync(keyboard^, ORD(KBLeds));
        rc := WaitForAnswer(keyboard^, 35)
      END
    END    
  END SetCapsLock;

  PROCEDURE ReadId(VAR dev: DeviceDesc);
    VAR nbTries, res: INTEGER;
  BEGIN nbTries := 3;
    (*Stop reporting*)
    REPEAT DEC(nbTries);
      SendByteAsync(dev, 0F5H);
      res := WaitForAnswer(dev, 35)
    UNTIL (nbTries = 0) OR (res = 0FAH);
    nbTries := 3;
    (*Send the read ID command*)
    REPEAT DEC(nbTries);
      SendByteAsync(dev, 0F2H);
      res := WaitForAnswer(dev, 35)
    UNTIL (nbTries = 0) OR (res = 0FAH)
 END ReadId;

  PROCEDURE ParseReadIdAnswer(VAR dev: DeviceDesc);
    VAR id1, WheelInitSeq, i, res: INTEGER;
      data: BYTE;
  BEGIN id1 := WaitForAnswer(dev, 35);
    IF (id1 = 0ABH) & (WaitForAnswer(dev, 35) = 83H) THEN
      dev.activityLED := dev.keyboardLED; (*Map the activity LED for a keyboard device*)
      dev.connectedDevice := KEYBOARD; keyboard := SYSTEM.VAL(Device, SYSTEM.ADR(dev));
      SendByteAsync(dev, 0F4H); (*Enable data reporting*)
      res := WaitForAnswer(dev, 35);
      dev.dest := SYSTEM.VAL(CircularBuffer, SYSTEM.ADR(mkb.KB));
    ELSIF (id1 = 0) OR (id1 = 3) THEN
      dev.activityLED := dev.mouseLED; (*Map the device type and activity LED for a mouse device*)
      dev.haveWheel := FALSE; dev.mouseReportSize := 3; (*Initialize mouse state*)
      IF id1 = 3 THEN (*This is a wheel mouse*)
        dev.haveWheel := TRUE; dev.mouseReportSize := 4;
      ELSE (*Try to activate wheel mode*)
        WheelInitSeq := SYSTEM.ADR($F3 C8 F3 64 F3 50$); i := 0;
        REPEAT SYSTEM.GET(WheelInitSeq + i, data); SendByteAsync(dev, data); res := WaitForAnswer(dev, 35); INC(i) UNTIL (i = 6) OR (res # 0FAH);
        IF res = 0FAH THEN
          SendByteAsync(dev, 0F2H); (*Reread device type*)
          IF WaitForAnswer(dev, 35) = 0FAH THEN
            IF WaitForAnswer(dev, 35) = 3 THEN dev.haveWheel := TRUE; dev.mouseReportSize := 4 END;
          END
        END
      END;
      dev.tickLastReport := Kernel.Time(); dev.buf.tail := 0; mkb.MW := 1366; mkb.MH := 768;
      dev.connectedDevice := MOUSE;
      SendByteAsync(dev, 0F4H); (*Enable data reporting*)
      res := WaitForAnswer(dev, 35);
    ELSE dev.connectedDevice := NO_DEVICE (*No known device connected*)
    END
  END ParseReadIdAnswer;

  PROCEDURE ProbeDevice(VAR dev: DeviceDesc);
  BEGIN
    ReadId(dev);
    ParseReadIdAnswer(dev);
  END ProbeDevice;

  PROCEDURE InitDevice*(VAR dev: DeviceDesc);
  BEGIN (*Inhibit device data transmission*) SYSTEM.PUT(dev.clock_Out, LOW); BSP.Delayus(150);
     dev.connectedDevice := NO_DEVICE; dev.direction := NONE; dev.dest := SYSTEM.VAL(CircularBuffer, SYSTEM.ADR(dev.buf));
    dev.buf.head := 0; dev.buf.tail := 0;
    dev.activityLED := 0;
    dev.nofBitsToBeRead := 11;
    dev.statusIn := NO_ANSWER; dev.statusOut := NO_ANSWER;
    dev.parityEnabled := TRUE;

    ProbeDevice(dev);
  END InitDevice;

BEGIN mkb := SYSTEM.VAL(MKB, SYSTEM.ADR(mkbBlock));
END PS2.

OM4Tool.DecSym PS2.sm4
decode PS2.sm4
PS2 65F39FC1  1
   1 SUCCESS [^4]       0
   1 IN_PROGRESS [^4]       1
   1 FRAME_ERROR [^4]       2
   1 PARITY_ERROR [^4]       3
   1 NAK [^4]       4
   1 NO_ANSWER [^4]       5
   1 NO_DEVICE [^4]       0
   1 KEYBOARD [^4]       1
   1 MOUSE [^4]       2
   1 BUFFERSIZE [^4]      16
   5 CircularBuffer [15  form = 7 [16  form = 13 [^9]  exno = 1  extlev = 0  size = 24 { buffer [0  form = 12 [^1]  len = 16  size = 16]   8 tail [^4]   4 head [^4]   0}]]()
   5 CircularBufferDesc [^16]( ->  15)
   5 MKB [17  form = 7 [18  form = 13 [^9]  exno = 2  extlev = 0  size = 36 { MH [^4]  32 MW [^4]  28 MD [^4]  24 KB [^16]   0}]]()
   5 MKDataBlock [^18]( ->  17)
   5 Device [19  form = 7 [20  form = 13 [^9]  exno = 3  extlev = 0  size = 88 { dest [^15]  60 badEdge [^4]  56 keyboardLED [^4]  36 mouseLED [^4]  32 data_Out [^4]  24 clock_Out [^4]  20 data_In [^4]  16 clock_In [^4]  12 parityEnabled [^2]   7 clockPin [^1]   4 connectedDevice [^1]   3 statusOut [^1]   2 statusIn [^1]   1}]]()
   5 DeviceDesc [^20]( ->  19)
   2 mkb [^17]     4
   2 keyboard [^19]     5
   1 SendByteAsync [0  form = 10 [^9]( class = 2 [^1] class = 3 [^20])]       6
   1 WaitForAnswer [0  form = 10 [^4]( class = 2 [^4] class = 3 [^20])]       7
   1 ProcessData [0  form = 10 [^9]( class = 3 [^20])]       8
   1 SendByte [0  form = 10 [^1]( class = 2 [^1] class = 3 [^20])]       9
   1 SetCapsLock [0  form = 10 [^9]( class = 2 [^2])]      10
   1 InitDevice [0  form = 10 [^9]( class = 3 [^20])]      11

