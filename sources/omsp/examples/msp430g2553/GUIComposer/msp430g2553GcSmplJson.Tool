gc_simple_json example

OMSPP.Compile jsmn.Mod HALSYSmsp430g255x.Mod JSONCallbacks.Mod/s GUIJson.Mod/s HALIOmsp430g255x.Mod
 HALTIMmsp430g255x.Mod HALGUImsp430g255x.Mod JSONGUIComm.Mod/s msp430g2553GcSmplJson.Mod /s

OMSPL.Link 32 4000H 200H msp430g2553GcSmplJson ~
  linking msp430g2553 MultiPrecisionArith HALSYSmsp430g255x HALIOmsp430g255x HALTIMmsp430g255x jsmn Arith JSONCallbacks HALGUImsp430g255x
  GUIJson JSONGUIComm msp430g2553GcSmplJson, flash 4668, data  260, stack  252 bytes
