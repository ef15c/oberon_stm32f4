MODULE preserveMSPFlash;
  IMPORT  SYSTEM, MSPFlashTypes;
(*import this module before any else if you want to use the flashBlock procedure
   provided by the bootloader*)

  CONST flashBlock* = SYSTEM.VAL(MSPFlashTypes.flashBlockType, 200H);
  VAR dummy*: ARRAY 96 OF BYTE; (*protect the flashBlock function installed in RAM from overwiting*)

END preserveMSPFlash.
