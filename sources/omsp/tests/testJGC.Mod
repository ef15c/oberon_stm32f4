MODULE testJGC;
  IMPORT JC := JSONGUIComm;

BEGIN JC.sendInt("p1", 0, 1); JC.sendUInt8("p130", 130);
  JC.sendInt16("p10000", 10000);   JC.sendInt16("m10000", -10000);
  JC.sendInt8("p2", 2); JC.sendInt8("m2", -2);
  JC.sendUInt16("p10000", 10000); JC.sendUInt16("p40000", 40000);
  JC.sendInt32("p100000", 1, 34464); JC.sendInt32("m2", 65535, 65534);
  JC.sendBool("true", TRUE); JC.sendBool("false", FALSE)
END testJGC.

OMSPL.Link 32 4000H 200H testJGC ~
  linking MultiPrecisionArith msp430g2553 HALSYSmsp430g255x jsmn Arith JSONCallbacks GUIJson HALCallbacks HALIOmsp430g255x
  HALGUImsp430g255x JSONGUIComm testJGC, flash 4594, data  254, stack  258 bytes
