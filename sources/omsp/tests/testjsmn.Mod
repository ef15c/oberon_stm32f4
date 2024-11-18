MODULE testjsmn;
  IMPORT C := JSONCallbacks, G := GUIJson, M := msp430g2553;

  VAR r: BOOLEAN;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD;
  M.P1OUT^ := {0};
  M.P1DIR^ := {0};
  r := G.ParseString("{" + 22X + "bEnable" + 22X + ":true}"); IF ~C.bEnableSwitch THEN M.P1OUT^ := {} END;
  r := G.ParseString("{" + 22X + "bEnable" + 22X + ":false}"); IF C.bEnableSwitch THEN M.P1OUT^ := {} END;
  r := G.ParseString("{" + 22X + "u16Data" + 22X + ":128}"); IF C.qIncrement # 128 THEN M.P1OUT^ := {} END;
  r := G.ParseString("{" + 22X + "u16Data" + 22X + ":307}"); IF C.qIncrement # 307 THEN M.P1OUT^ := {} END
END testjsmn.

OMSPL.Link 32 4000H 200H testjsmn ~

  linking Arith JSONCallbacks jsmn GUIJson msp430g2553 testjsmn, flash 2918, data  158, stack  354 bytes
