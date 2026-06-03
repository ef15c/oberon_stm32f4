MODULE USBHConf;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   General low level driver configuration
  ******************************************************************************
  *)

  CONST
    MAX_NUM_ENDPOINTS* = 2;
    MAX_NUM_INTERFACES* = 2;
    MAX_NUM_CONFIGURATION* = 1;
    MAX_NUM_SUPPORTED_CLASS* = 1;
    MAX_SIZE_CONFIGURATION* = 200H;
    MAX_DATA_BUFFER* = 200H;

END USBHConf.
