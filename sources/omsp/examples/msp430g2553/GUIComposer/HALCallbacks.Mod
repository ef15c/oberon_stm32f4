MODULE HALCallbacks;
  IMPORT G := GUIJson, MP := MultiPrecisionArith, JC := JSONCallbacks;

  VAR rxString: ARRAY G.MAX_STR_LEN OF CHAR;  (* String to transmit or receive data *)

    (* Exported variable used to track the of state of GUI and counter values *)
    bUpdateGUI*: BOOLEAN;
    u8Counter*: BYTE; (* Counter8 will be updated on SW1 press in increments of 50 *)
    u16Counter*: INTEGER; (* Counter16 will be updated on button press in increments of 5000 *)
    u32Counterl*, u32Counterh*: INTEGER; (* Counter32 will be updated on timer in increments of 10000 *)
    qCounter*: INTEGER; (* QMath counter updated on timer based on boolean in increments of qIncrement *)

    (* for RxByteCallback *)
    rxInProgress: BOOLEAN; charCnt: INTEGER;

  PROCEDURE GUIUpdated*;
  BEGIN bUpdateGUI := FALSE;
  END GUIUpdated;

  (*! \brief Function called by HAL when SW1 is pressed
     !
     ! \return none*)
  PROCEDURE ButtonCallbackSW1*;
  BEGIN INC(u8Counter, 50)
  END ButtonCallbackSW1;

  (*! \brief Function called by HAL when SW2 is pressed
     !
     ! \return none*)
  PROCEDURE ButtonCallbackSW2*;
  BEGIN INC(u16Counter, 5000)
  END ButtonCallbackSW2;

  (*! \brief Function called by HAL when there is a periodic timer interrupt
     !
     ! \return none*)
  PROCEDURE TimerCallback*;
  BEGIN
    (* Update 32-bit counter *)
    MP.AddLongInt(u32Counterh, u32Counterl, 10000);
    bUpdateGUI := TRUE;
    IF JC.bEnableSwitch THEN
        INC(qCounter, JC.qIncrement);
        IF qCounter > 6400H (*Q.atoQ("100.0")*) THEN qCounter := 0 END
    END
  END TimerCallback;

  (*! \brief Callback function for GUI HAL. Called when byte is received.
     !
     ! \param[in] data is the byte received from GUI Comm interface.
     !
     ! \return true to wake-up MCU, false to stay in LPM*)
  PROCEDURE RxByteCallback*(data: CHAR): BOOLEAN;
    VAR ret: BOOLEAN;
  BEGIN ret := FALSE;
    IF ~rxInProgress THEN
      IF data # 0AX THEN rxInProgress := TRUE; charCnt := 0; rxString[charCnt] := data END
    ELSE (* in progress *)
      INC(charCnt);
      IF data # 0AX THEN
        IF charCnt >= G.MAX_STR_LEN THEN rxInProgress := FALSE ELSE rxString[charCnt] := data END
      ELSE (* String receive complete *) rxInProgress := FALSE; rxString[charCnt] := 0X;
        IF G.ParseString(rxString) THEN ret := TRUE (* wake-up MCU *) END
      END
    END
    
    RETURN ret

  END RxByteCallback;

BEGIN bUpdateGUI := FALSE; rxString := "";
  u8Counter := 50; u16Counter := 5000; u32Counterl := 10000; u32Counterh := 0;
  qCounter := 0080H; (*Q.atoQ("0.5")*)
  rxInProgress := FALSE; charCnt := 0
END HALCallbacks.
