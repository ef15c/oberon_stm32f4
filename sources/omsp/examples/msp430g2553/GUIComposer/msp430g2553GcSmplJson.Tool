gc_simple_json example

OMSPP.Compile jsmn.Mod HALSYSmsp430g255x.Mod JSONCallbacks.Mod/s GUIJson.Mod/s HALCallbacks.Mod/s HALIOmsp430g255x.Mod
 HALTIMmsp430g255x.Mod HALGUImsp430g255x.Mod JSONGUIComm.Mod msp430g2553GcSmplJson.Mod /s

OMSPL.Link 32 4000H 200H msp430g2553GcSmplJson ~

 linking msp430g2553 jsmn Arith JSONCallbacks GUIJson MultiPrecisionArith HALCallbacks HALIOmsp430g255x HALTIMmsp430g255x HALSYSmsp430g255x
  HALGUImsp430g255x JSONGUIComm msp430g2553GcSmplJson, flash 4694, data  258, stack  254 bytes
