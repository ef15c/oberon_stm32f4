MODULE nrf24pRelayTypes;
  IMPORT N := nrf24l01p;

  TYPE Config* = POINTER TO ConfigDesc;
    ConfigDesc* = RECORD version*, lcd_vop*: BYTE; confReceiver*: N.RadioSetup END;

END nrf24pRelayTypes.

OMSPTool.DecSym nrf24pRelayTypes.sms
