MODULE preserveMSPFlash;
  IMPORT  SYSTEM, MSPFlashTypes;
(*import this module before any else if you want to use the flashBlock procedure
   provided by the bootloader at adress 200H*)

  VAR flashBlock*: MSPFlashTypes.flashBlockType-; dummy: ARRAY 96 OF BYTE; (*protect the flashBlock function installed in RAM from overwriting*)

BEGIN flashBlock := SYSTEM.VAL(MSPFlashTypes.flashBlockType, SYSTEM.ADR(dummy));
END preserveMSPFlash.

OMSPP.Compile preserveMSPFlash.Mod/s~
OMSPTool.DecSym preserveMSPFlash.sms
decode preserveMSPFlash.sms
preserveMSPFlash AB1E1B3D  3
   9 flashBlock [19  form = 7 [0  form = 10 [^9] leaf UR 0000( class = 2 R6 [^4] class = 2 R5 [^7] class = 2 R4 [^7])] MSPFlashTypes.flashBlockType 1E42D179]     1
