MODULE preserveMSPFlash;
  IMPORT  SYSTEM, MSPFlashTypes;
(*import this module before any else if you want to use the flashBlock procedure
   provided by the bootloader at adress 200H*)

  VAR flashBlock*: MSPFlashTypes.flashBlockType-; dummy: ARRAY 96 OF BYTE; (*protect the flashBlock function installed in RAM from overwriting*)

BEGIN flashBlock := SYSTEM.VAL(MSPFlashTypes.flashBlockType, SYSTEM.ADR(dummy));
END preserveMSPFlash.

OMSPP.Compile preserveMSPFlash.Mod/s~
OMSPTool.DecSym preserveMSPFlash.sms
