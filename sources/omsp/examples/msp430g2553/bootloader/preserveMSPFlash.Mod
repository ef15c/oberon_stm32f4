MODULE preserveMSPFlash;
(*import this module before any else if you want to use the flashBlock procedure
   provided by the bootloader*)

  CONST flashBlockAddr* = 200H;
  VAR dummy*: ARRAY 96 OF BYTE; (*protect the flashBlock function installed in RAM from overwiting*)

END preserveMSPFlash.
