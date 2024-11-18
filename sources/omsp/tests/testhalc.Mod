MODULE testhalc;
  IMPORT C := JSONCallbacks, H := HALCallbacks, M := msp430g2553;

  PROCEDURE receive(s: ARRAY OF CHAR);
    VAR i: INTEGER; r: BOOLEAN;
  BEGIN i := 0; WHILE s[i] # 0X DO r := H.RxByteCallback(s[i]); INC(i) END
  END receive;

BEGIN 
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD;
  M.P1OUT^ := {0};
  M.P1DIR^ := {0};
  H.ButtonCallbackSW1; IF H.u8Counter # 100 THEN M.P1OUT^ := {} END;
  H.ButtonCallbackSW2; IF H.u16Counter # 10000 THEN M.P1OUT^ := {} END;
  H.TimerCallback; IF (H.u32Counterh # 0) OR (H.u32Counterl # 20000) THEN M.P1OUT^ := {} END;
  IF H.qCounter # 100H THEN M.P1OUT^ := {} END;
  receive("{" + 22X + "bEnable" + 22X + ":true}" + 0AX); IF ~C.bEnableSwitch THEN M.P1OUT^ := {} END;
  receive("{" + 22X + "bEnable" + 22X + ":false}" + 0AX); IF C.bEnableSwitch THEN M.P1OUT^ := {} END;
  receive("{" + 22X + "u16Data" + 22X + ":128}" + 0AX); IF C.qIncrement # 128 THEN M.P1OUT^ := {} END;
  receive("{" + 22X + "u16Data" + 22X + ":307}" + 0AX); IF C.qIncrement # 307 THEN M.P1OUT^ := {} END
END testhalc.

OMSPL.Link 32 4000H 200H testhalc ~
  linking Arith JSONCallbacks jsmn GUIJson MultiPrecisionArith HALCallbacks msp430g2553 testhalc, flash 3666, data  234, stack  278 bytes
