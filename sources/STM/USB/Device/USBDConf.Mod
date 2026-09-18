MODULE USBDConf;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   Peripheral mode sizes configuration
  ******************************************************************************
  *)

  CONST
  (* Maximum number of supported media : Flash *)
    MAX_NUM_INTERFACES* = 1;
    MAX_NUM_CONFIGURATION* = 1;
    SUPPORT_USER_STRING_DESC* = TRUE;
    SELF_POWERED* = TRUE;

END USBDConf.
