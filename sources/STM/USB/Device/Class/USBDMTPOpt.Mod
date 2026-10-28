MODULE USBDMTPOpt;
  (** ported to Oberon from:
  ******************************************************************************
  * @file    usbd_mtp_opt.c
  * @author  MCD Application Team
  * @brief   This file includes the PTP operations layer
  ******************************************************************************
  *)
  IMPORT SYSTEM, Log := USBLog, Def := USBDef, DDef := USBDDef;

  CONST
    MEDIA_PACKET* = 512;
    CONT_HEADER_SIZE* = 12;
   
  (* MTP response phases    *)
    PHASE_IDLE* = 0;
    OPERATION_REQUEST_PHASE* = 1; (*OUT*)
    DATA_IN_PHASE* = 2; (*R->I*)
    DATA_OUT_PHASE* = 3; (*I->R*)
    RESPONSE_PHASE* = 4; (*IN*)
  (*state diagram:
    {PHASE_IDLE OPERATION_REQUEST_PHASE [DATA_IN_PHASE | DATA_OUT_PHASE] RESPONSE_PHASE}
    note: the presence and the direction of the data phases depend on the operation specified
    in the operation request phase
  *)

  (* MTP Session state    *)
    SESSION_NOT_OPEN* = 0;
    SESSION_OPEN* = 1;

  (* Container Types *)
    CONT_TYPE_UNDEFINED* = 0;
    CONT_TYPE_COMMAND* = 1;
    CONT_TYPE_DATA* = 2;
    CONT_TYPE_RESPONSE* = 3;
    CONT_TYPE_EVENT* = 4;

  (* Form flags *)
    FORM_NONE* = 0;
    FORM_RANGE* = 1;
    FORM_ENUMERATION* = 2;
    FORM_DATETIME* = 3;
    FORM_FIXED_LENGTH_ARRAY* = 4;
    FORM_REGULAR_EXPRESSION* = 5;
    FORM_BYTE_ARRAY* = 6;
    FORM_LONG_STRING* = 0FFH;

  (* Operations code *)
    OP_GET_DEVICE_INFO* = 1001H;
    OP_OPEN_SESSION* = 1002H;
    OP_CLOSE_SESSION* = 1003H;
    OP_GET_STORAGE_IDS* = 1004H;
    OP_GET_STORAGE_INFO* = 1005H;
    OP_GET_NUM_OBJECTS* = 1006H;
    OP_GET_OBJECT_HANDLES* = 1007H;
    OP_GET_OBJECT_INFO* = 1008H;
    OP_GET_OBJECT* = 1009H;
    OP_GET_THUMB* =  100AH;
    OP_DELETE_OBJECT* = 100BH;
    OP_SEND_OBJECT_INFO* = 100CH;
    OP_SEND_OBJECT* = 100DH;
    OP_FORMAT_STORE* = 100FH;
    OP_RESET_DEVICE* = 1010H;
    OP_GET_DEVICE_PROP_DESC* = 1014H;
    OP_GET_DEVICE_PROP_VALUE* = 1015H;
    OP_SET_DEVICE_PROP_VALUE* = 1016H;
    OP_RESET_DEVICE_PROP_VALUE* = 1017H;
    OP_TERMINATE_OPEN_CAPTURE* = 1018H;
    OP_MOVE_OBJECT* = 1019H;
    OP_COPY_OBJECT* = 101AH;
    OP_GET_PARTIAL_OBJECT* = 101BH;
    OP_INITIATE_OPEN_CAPTURE* = 101CH;
    OP_GET_OBJECT_PROPS_SUPPORTED* = 9801H;
    OP_GET_OBJECT_PROP_DESC* = 9802H;
    OP_GET_OBJECT_PROP_VALUE* = 9803H;
    OP_SET_OBJECT_PROP_VALUE* = 9804H;
    OP_GET_OBJECT_PROPLIST* = 9805H;
    OP_GET_OBJECT_REFERENCES* = 9810H;
    OP_GETSERVICEIDS* = 9301H;
    OP_GETSERVICEINFO* = 9302H;
    OP_GETSERVICECAPABILITIES* = 9303H;
    OP_GETSERVICEPROPDESC* = 9304H;

(*
 * MTP Class specification Revision 1.1
 * Appendix A. Object Formats
 *)

  (* MTP Object format codes *)
    OBJ_FORMAT_UNDEFINED* = 3000H;
    OBJ_FORMAT_ASSOCIATION* = 3001H;
    OBJ_FORMAT_SCRIPT* = 3002H;
    OBJ_FORMAT_EXECUTABLE* = 3003H;
    OBJ_FORMAT_TEXT* = 3004H;
    OBJ_FORMAT_HTML* = 3005H;
    OBJ_FORMAT_DPOF* = 3006H;
    OBJ_FORMAT_AIFF* = 3007H;
    OBJ_FORMAT_WAV* = 3008H;
    OBJ_FORMAT_MP3* = 3009H;
    OBJ_FORMAT_AVI* = 300AH;
    OBJ_FORMAT_MPEG* = 300BH;
    OBJ_FORMAT_ASF* = 300CH;
    OBJ_FORMAT_DEFINED* = 3800H;
    OBJ_FORMAT_EXIF_JPEG* = 3801H;
    OBJ_FORMAT_TIFF_EP* = 3802H;
    OBJ_FORMAT_FLASHPIX* = 3803H;
    OBJ_FORMAT_BMP* = 3804H;
    OBJ_FORMAT_CIFF* = 3805H;
    OBJ_FORMAT_UNDEFINED_RESERVED0 * = 3806H;
    OBJ_FORMAT_GIF* = 3807H;
    OBJ_FORMAT_JFIF* = 3808H;
    OBJ_FORMAT_CD* = 3809H;
    OBJ_FORMAT_PICT* = 380AH;
    OBJ_FORMAT_PNG* = 380BH;
    OBJ_FORMAT_UNDEFINED_RESERVED1* = 380CH;
    OBJ_FORMAT_TIFF* = 380DH;
    OBJ_FORMAT_TIFF_IT* = 380EH;
    OBJ_FORMAT_JP2* = 380FH;
    OBJ_FORMAT_JPX* = 3810H;
    OBJ_FORMAT_UNDEFINED_FIRMWARE* = 0B802H;
    OBJ_FORMAT_WINDOWS_IMAGE_FORMAT* = 0B881H;
    OBJ_FORMAT_UNDEFINED_AUDIO* = 0B900H;
    OBJ_FORMAT_WMA* = 0B901H;
    OBJ_FORMAT_OGG* = 0B902H;
    OBJ_FORMAT_AAC* = 0B903H;
    OBJ_FORMAT_AUDIBLE* = 0B904H;
    OBJ_FORMAT_FLAC* = 0B906H;
    OBJ_FORMAT_UNDEFINED_VIDEO* = 0B980H;
    OBJ_FORMAT_WMV* = 0B981H;
    OBJ_FORMAT_MP4_CONTAINER* = 0B982H;
    OBJ_FORMAT_MP2* = 0B983H;
    OBJ_FORMAT_3GP_CONTAINER* = 0B984H;

(*
 * MTP Class specification Revision 1.1
 * Appendix B. Object Properties
 *)

  (* MTP OBJECT PROPERTIES supported*)
    OB_PROP_STORAGE_ID* = 0DC01H;
    OB_PROP_OBJECT_FORMAT* = 0DC02H;
    OB_PROP_PROTECTION_STATUS* = 0DC03H;
    OB_PROP_OBJECT_SIZE* = 0DC04H;
    OB_PROP_ASSOC_TYPE* = 0DC05H;
    OB_PROP_ASSOC_DESC* = 0DC06H;
    OB_PROP_OBJ_FILE_NAME* = 0DC07H;
    OB_PROP_DATE_CREATED* = 0DC08H;
    OB_PROP_DATE_MODIFIED* = 0DC09H;
    OB_PROP_KEYWORDS* = 0DC0AH;
    OB_PROP_PARENT_OBJECT* = 0DC0BH;
    OB_PROP_ALLOWED_FOLD_CONTENTS* = 0DC0CH;
    OB_PROP_HIDDEN* = 0DC0DH;
    OB_PROP_SYSTEM_OBJECT* = 0DC0EH;
    OB_PROP_PERS_UNIQ_OBJ_IDEN* = 0DC41H;
    OB_PROP_SYNCID* = 0DC42H;
    OB_PROP_PROPERTY_BAG* = 0DC43H;
    OB_PROP_NAME* = 0DC44H;
    OB_PROP_CREATED_BY* = 0DC45H;
    OB_PROP_ARTIST* = 0DC46H;
    OB_PROP_DATE_AUTHORED* = 0DC47H;
    OB_PROP_DESCRIPTION* = 0DC48H;
    OB_PROP_URL_REFERENCE* = 0DC49H;
    OB_PROP_LANGUAGELOCALE* = 0DC4AH;
    OB_PROP_COPYRIGHT_INFORMATION* = 0DC4BH;
    OB_PROP_SOURCE* = 0DC4CH;
    OB_PROP_ORIGIN_LOCATION* = 0DC4DH;
    OB_PROP_DATE_ADDED* = 0DC4EH;
    OB_PROP_NON_CONSUMABLE* = 0DC4FH;
    OB_PROP_CORRUPTUNPLAYABLE* = 0DC50H;
    OB_PROP_PRODUCERSERIALNUMBER* = 0DC51H;
    OB_PROP_REPRES_SAMPLE_FORMAT* = 0DC81H;
    OB_PROP_REPRES_SAMPLE_SIZE* = 0DC82H;
    OB_PROP_REPRES_SAMPLE_HEIGHT* = 0DC83H;
    OB_PROP_REPRES_SAMPLE_WIDTH* = 0DC84H;
    OB_PROP_REPRES_SAMPLE_DURATION* = 0DC85H;
    OB_PROP_REPRES_SAMPLE_DATA* = 0DC86H;
    OB_PROP_WIDTH* = 0DC87H;
    OB_PROP_HEIGHT* = 0DC88H;
    OB_PROP_DURATION* = 0DC89H;
    OB_PROP_RATING* = 0DC8AH;
    OB_PROP_TRACK* = 0DC8BH;
    OB_PROP_GENRE* = 0DC8CH;
    OB_PROP_CREDITS* = 0DC8DH;
    OB_PROP_LYRICS* = 0DC8EH;
    OB_PROP_SUBSCRIPTION_CONTENT_ID* = 0DC8FH;
    OB_PROP_PRODUCED_BY* = 0DC90H;
    OB_PROP_USE_COUNT* = 0DC91H;
    OB_PROP_SKIP_COUNT* = 0DC92H;
    OB_PROP_LAST_ACCESSED* = 0DC93H;
    OB_PROP_PARENTAL_RATING* = 0DC94H;
    OB_PROP_META_GENRE* = 0DC95H;
    OB_PROP_COMPOSER* = 0DC96H;
    OB_PROP_EFFECTIVE_RATING* = 0DC97H;
    OB_PROP_SUBTITLE* = 0DC98H;
    OB_PROP_ORIGINAL_RELEASE_DATE* = 0DC99H;
    OB_PROP_ALBUM_NAME* = 0DC9AH;
    OB_PROP_ALBUM_ARTIST* = 0DC9BH;
    OB_PROP_MOOD* = 0DC9CH;
    OB_PROP_DRM_STATUS* = 0DC9DH;
    OB_PROP_SUB_DESCRIPTION* = 0DC9EH;
    OB_PROP_IS_CROPPED* = 0DCD1H;
    OB_PROP_IS_COLOUR_CORRECTED* = 0DCD2H;
    OB_PROP_IMAGE_BIT_DEPTH* = 0DCD3H;
    OB_PROP_FNUMBER* = 0DCD4H;
    OB_PROP_EXPOSURE_TIME* = 0DCD5H;
    OB_PROP_EXPOSURE_INDEX* = 0DCD6H;
    OB_PROP_TOTAL_BITRATE* = 0DE91H;
    OB_PROP_BITRATE_TYPE* = 0DE92H;
    OB_PROP_SAMPLE_RATE* = 0DE93H;
    OB_PROP_NUMBER_OF_CHANNELS* = 0DE94H;
    OB_PROP_AUDIO_BITDEPTH* = 0DE95H;
    OB_PROP_SCAN_TYPE* = 0DE97H;
    OB_PROP_AUDIO_WAVE_CODEC* = 0DE99H;
    OB_PROP_AUDIO_BITRATE* = 0DE9AH;
    OB_PROP_VIDEO_FOURCC_CODEC* = 0DE9BH;
    OB_PROP_VIDEO_BITRATE* = 0DE9CH;
    OB_PROP_FRAMES_PER_THOUSAND_SECONDS* = 0DE9DH;
    OB_PROP_KEYFRAME_DISTANCE* = 0DE9EH;
    OB_PROP_BUFFER_SIZE* = 0DE9FH;
    OB_PROP_ENCODING_QUALITY* = 0DEA0H;
    OB_PROP_ENCODING_PROFILE* = 0DEA1H;
    OB_PROP_DISPLAY_NAME* = 0DCE0H;
    OB_PROP_BODY_TEXT* = 0DCE1H;
    OB_PROP_SUBJECT* = 0DCE2H;
    OB_PROP_PRIORITY* = 0DCE3H;
    OB_PROP_GIVEN_NAME* = 0DD00H;
    OB_PROP_MIDDLE_NAME* = 0DD01H;
    OB_PROP_FAMILY_NAME* = 0DD02H;
    OB_PROP_PREFIX* = 0DD03H;
    OB_PROP_SUFFIX* = 0DD04H;
    OB_PROP_PHONETIC_GIVEN_NAME* = 0DD05H;
    OB_PROP_PHONETIC_FAMILY_NAME* = 0DD06H;
    OB_PROP_EMAIL_PRIMARY* = 0DD07H;
    OB_PROP_EMAIL_PERSONAL_1* = 0DD08H;
    OB_PROP_EMAIL_PERSONAL_2* = 0DD09H;
    OB_PROP_EMAIL_BUSINESS_1* = 0DD0AH;
    OB_PROP_EMAIL_BUSINESS_2* = 0DD0BH;
    OB_PROP_EMAIL_OTHERS* = 0DD0CH;
    OB_PROP_PHONE_NUMBER_PRIMARY* = 0DD0DH;
    OB_PROP_PHONE_NUMBER_PERSONAL* = 0DD0EH;
    OB_PROP_PHONE_NUMBER_PERSONAL_2* = 0DD0FH;
    OB_PROP_PHONE_NUMBER_BUSINESS* = 0DD10H;
    OB_PROP_PHONE_NUMBER_BUSINESS_2* = 0DD11H;
    OB_PROP_PHONE_NUMBER_MOBILE* = 0DD12H;
    OB_PROP_PHONE_NUMBER_MOBILE_2* = 0DD13H;
    OB_PROP_FAX_NUMBER_PRIMARY* = 0DD14H;
    OB_PROP_FAX_NUMBER_PERSONAL* = 0DD15H;
    OB_PROP_FAX_NUMBER_BUSINESS* = 0DD16H;
    OB_PROP_PAGER_NUMBER* = 0DD17H;
    OB_PROP_PHONE_NUMBER_OTHERS* = 0DD18H;
    OB_PROP_PRIMARY_WEB_ADDRESS* = 0DD19H;
    OB_PROP_PERSONAL_WEB_ADDRESS* = 0DD1AH;
    OB_PROP_BUSINESS_WEB_ADDRESS* = 0DD1BH;
    OB_PROP_INSTANT_MSNGER_ADDR* = 0DD1CH;
    OB_PROP_INSTANT_MSNGER_ADDR_2* = 0DD1DH;
    OB_PROP_INSTANT_MSNGER_ADDR_3* = 0DD1EH;
    OB_PROP_POSTAL_ADD_PERSO_FULL* = 0DD1FH;
    OB_PROP_POSTAL_ADD_PERSO_LINE_1* = 0DD20H;
    OB_PROP_POSTAL_ADD_PERSO_LINE_2* = 0DD21H;
    OB_PROP_POSTAL_ADD_PERSO_CITY* = 0DD22H;
    OB_PROP_POSTAL_ADD_PERSO_REGION* = 0DD23H;
    OB_PROP_POSTAL_ADD_PERSO_POSTAL_CODE* = 0DD24H;
    OB_PROP_POSTAL_ADD_PERSO_COUNTRY* = 0DD25H;
    OB_PROP_POSTAL_ADD_BUSNES_FULL*  = 0DD26H;
    OB_PROP_POSTAL_ADD_BUSNES_LIN_1* = 0DD27H;
    OB_PROP_POSTAL_ADD_BUSNES_LIN_2* = 0DD28H;
    OB_PROP_POSTAL_ADD_BUSNES_CITY* = 0DD29H;
    OB_PROP_POSTAL_ADD_BUSNES_REGION* = 0DD2AH;
    OB_PROP_POSTAL_ADD_BUSNES_POSTAL_CODE* = 0DD2BH;
    OB_PROP_POSTAL_ADD_BUSNES_COUNTRY* = 0DD2CH;
    OB_PROP_POSTAL_ADD_OTHER_FULL* = 0DD2DH;
    OB_PROP_POSTAL_ADD_OTHER_LINE_1* = 0DD2EH;
    OB_PROP_POSTAL_ADD_OTHER_LINE_2* = 0DD2FH;
    OB_PROP_POSTAL_ADD_OTHER_CITY* = 0DD30H;
    OB_PROP_POSTAL_ADD_OTHER_REGION* = 0DD31H;
    OB_PROP_POSTAL_ADD_OTHER_POSTAL_CODE* = 0DD32H;
    OB_PROP_POSTAL_ADD_OTHER_COUNTRY* = 0DD33H;
    OB_PROP_ORGANIZATION_NAME* = 0DD34H;
    OB_PROP_PHONETIC_ORGANIZATION_NAME* = 0DD35H;
    OB_PROP_ROLE* = 0DD36H;
    OB_PROP_BIRTHDATE* = 0DD37H;
    OB_PROP_MESSAGE_TO* = 0DD40H;
    OB_PROP_MESSAGE_CC* = 0DD41H;
    OB_PROP_MESSAGE_BCC* = 0DD42H;
    OB_PROP_MESSAGE_READ* = 0DD43H;
    OB_PROP_MESSAGE_RECEIVED_TIME* = 0DD44H;
    OB_PROP_MESSAGE_SENDER* = 0DD45H;
    OB_PROP_ACT_BEGIN_TIME* = 0DD50H;
    OB_PROP_ACT_END_TIME* = 0DD51H;
    OB_PROP_ACT_LOCATION* = 0DD52H;
    OB_PROP_ACT_REQUIRED_ATTENDEES* = 0DD54H;
    OB_PROP_ACT_OPTIONAL_ATTENDEES* = 0DD55H;
    OB_PROP_ACT_RESOURCES* = 0DD56H;
    OB_PROP_ACT_ACCEPTED* = 0DD57H;
    OB_PROP_OWNER* = 0DD5DH;
    OB_PROP_EDITOR* = 0DD5EH;
    OB_PROP_WEBMASTER* = 0DD5FH;
    OB_PROP_URL_SOURCE* = 0DD60H;
    OB_PROP_URL_DESTINATION* = 0DD61H;
    OB_PROP_TIME_BOOKMARK* = 0DD62H;
    OB_PROP_OBJECT_BOOKMARK* = 0DD63H;
    OB_PROP_BYTE_BOOKMARK* = 0DD64H;
    OB_PROP_LAST_BUILD_DATE* = 0DD70H;
    OB_PROP_TIME_TO_LIVE* = 0DD71H;
    OB_PROP_MEDIA_GUID* = 0DD72H;

(*
 * MTP Class specification Revision 1.1
 * Appendix C. Device Properties
 *)

  (* MTP device properties code*)
    DEV_PROP_UNDEFINED* = 5000H;
    DEV_PROP_BATTERY_LEVEL* = 5001H;
    DEV_PROP_FUNCTIONAL_MODE* = 5002H;
    DEV_PROP_IMAGE_SIZE* = 5003H;
    DEV_PROP_COMPRESSION_SETTING* = 5004H;
    DEV_PROP_WHITE_BALANCE* = 5005H;
    DEV_PROP_RGB_GAIN* = 5006H;
    DEV_PROP_F_NUMBER* = 5007H;
    DEV_PROP_FOCAL_LENGTH* = 5008H;
    DEV_PROP_FOCUS_DISTANCE* = 5009H;
    DEV_PROP_FOCUS_MODE* = 500AH;
    DEV_PROP_EXPOSURE_METERING_MODE* = 500BH;
    DEV_PROP_FLASH_MODE* = 500CH;
    DEV_PROP_EXPOSURE_TIME* = 500DH;
    DEV_PROP_EXPOSURE_PROGRAM_MODE* = 500EH;
    DEV_PROP_EXPOSURE_INDEX* = 500FH;
    DEV_PROP_EXPOSURE_BIAS_COMPENSATION* = 5010H;
    DEV_PROP_DATETIME* = 5011H;
    DEV_PROP_CAPTURE_DELAY* = 5012H;
    DEV_PROP_STILL_CAPTURE_MODE* = 5013H;
    DEV_PROP_CONTRAST* = 5014H;
    DEV_PROP_SHARPNESS* = 5015H;
    DEV_PROP_DIGITAL_ZOOM* = 5016H;
    DEV_PROP_EFFECT_MODE* = 5017H;
    DEV_PROP_BURST_NUMBER* = 5018H;
    DEV_PROP_BURST_INTERVAL* = 5019H;
    DEV_PROP_TIMELAPSE_NUMBER* = 501AH;
    DEV_PROP_TIMELAPSE_INTERVAL* = 501BH;
    DEV_PROP_FOCUS_METERING_MODE* = 501CH;
    DEV_PROP_UPLOAD_URL* = 501DH;
    DEV_PROP_ARTIST* = 501EH;
    DEV_PROP_COPYRIGHT_INFO* = 501FH;
    DEV_PROP_SYNCHRONIZATION_PARTNER* = 0D401H;
    DEV_PROP_DEVICE_FRIENDLY_NAME* = 0D402H;
    DEV_PROP_VOLUME* = 0D403H;
    DEV_PROP_SUPPORTEDFORMATSORDERED* = 0D404H;
    DEV_PROP_DEVICEICON* = 0D405H;
    DEV_PROP_PLAYBACK_RATE* = 0D410H;
    DEV_PROP_PLAYBACK_OBJECT* = 0D411H;
    DEV_PROP_PLAYBACK_CONTAINER* = 0D412H;
    DEV_PROP_SESSION_INITIATOR_VERSION_INFO* = 0D406H;
    DEV_PROP_PERCEIVED_DEVICE_TYPE* = 0D407H;

  (* MTP storage type *)
    STORAGE_UNDEFINED* =  0;
    STORAGE_FIXED_ROM* = 1;
    STORAGE_REMOVABLE_ROM* = 2;
    STORAGE_FIXED_RAM* = 3;
    STORAGE_REMOVABLE_RAM* =4;

  (* MTP file system type *)
    FILESYSTEM_UNDEFINED* = 0;
    FILESYSTEM_GENERIC_FLAT* = 1;
    FILESYSTEM_GENERIC_HIERARCH* = 2;
    FILESYSTEM_DCF* = 3;

  (* MTP access capability *)
    ACCESS_CAP_RW* = 0; (* read write *)
    ACCESS_CAP_RO_WITHOUT_DEL* = 1;
    ACCESS_CAP_RO_WITH_DEL* = 2;

  (*  MTP event codes*)
    EVENT_UNDEFINED* = 4000H;
    EVENT_CANCELTRANSACTION* = 4001H;
    EVENT_OBJECTADDED* = 4002H;
    EVENT_OBJECTREMOVED* = 4003H;
    EVENT_STOREADDED* = 4004H;
    EVENT_STOREREMOVED* = 4005H;
    EVENT_DEVICEPROPCHANGED* = 4006H;
    EVENT_OBJECTINFOCHANGED* = 4007H;
    EVENT_DEVICEINFOCHANGED* = 4008H;
    EVENT_REQUESTOBJECTTRANSFER* = 4009H;
    EVENT_STOREFULL* = 400AH;
    EVENT_DEVICERESET* = 400BH;
    EVENT_STORAGEINFOCHANGED* = 400CH;
    EVENT_CAPTURECOMPLETE* = 400DH;
    EVENT_UNREPORTEDSTATUS* = 400EH;
    EVENT_OBJECTPROPCHANGED* = 0C801H;
    EVENT_OBJECTPROPDESCCHANGED* = 0C802H;
    EVENT_OBJECTREFERENCESCHANGED* = 0C803H;

  (* MTP response code *)
    RESPONSE_OK* = 2001H;
    RESPONSE_GENERAL_ERROR* = 2002H;
    RESPONSE_SESSION_NOT_OPEN* = 2003H;
    RESPONSE_OPERATION_NOT_SUPPORTED* = 2005H;
    RESPONSE_PARAMETER_NOT_SUPPORTED* = 2006H;
    RESPONSE_INCOMPLETE_TRANSFER* = 2007H;
    RESPONSE_INVALID_STORAGE_ID* = 2008H;
    RESPONSE_INVALID_OBJECT_HANDLE* = 2009H;
    RESPONSE_DEVICEPROP_NOT_SUPPORTED* = 200AH;
    RESPONSE_STORE_FULL* = 200CH;
    RESPONSE_ACCESS_DENIED* = 200FH;
    RESPONSE_STORE_NOT_AVAILABLE* = 2013H;
    RESPONSE_SPECIFICATION_BY_FORMAT_NOT_SUPPORTED* = 2014H;
    RESPONSE_NO_VALID_OBJECT_INFO* = 2015H;
    RESPONSE_DEVICE_BUSY* = 2019H;
    RESPONSE_INVALID_PARENT_OBJECT* = 201AH;
    RESPONSE_INVALID_PARAMETER* = 201DH;
    RESPONSE_SESSION_ALREADY_OPEN* = 201EH;
    RESPONSE_TRANSACTION_CANCELLED* = 201FH;
    RESPONSE_INVALID_OBJECT_PROP_CODE* = 0A801H;
    RESPONSE_SPECIFICATION_BY_GROUP_UNSUPPORTED* = 0A807H;
    RESPONSE_OBJECT_PROP_NOT_SUPPORTED* = 0A80AH;

  (* MTP standard data types supported *)
    DATATYPE_INT8* = 1;
    DATATYPE_UINT8* = 2;
    DATATYPE_INT16* = 3;
    DATATYPE_UINT16* = 4;
    DATATYPE_INT32* = 5;
    DATATYPE_UINT32* = 6;
    DATATYPE_INT64* = 7;
    DATATYPE_UINT64* = 8;
    DATATYPE_UINT128* = 0AH;
    DATATYPE_STR* = 0FFFFH;

  (* MTP reading only or reading/writing *)
    PROP_GET* = 0;
    PROP_GET_SET* = 1;

  (* MTP functional mode *)
    STANDARD_MODE = 0;
    SLEEP_STATE = 1;
    FUNCTIONAL_MODE = STANDARD_MODE;

  (* MTP device info *)
    STANDARD_VERSION =  100;
    VEND_EXT_ID = 6;
    VEND_EXT_VERSION = 100;

(*
  (*receive state machine states*)
    RECEIVE_IDLE_STATE* = 0;
    RECEIVE_COMMAND_DATA* = 1;
    RECEIVE_FIRST_DATA* = 2;
    RECEIVE_REST_OF_DATA* = 3;
    SEND_RESPONSE* = 4;
*)

  TYPE
    BufferDesc* = RECORD(Def.BufferDesc) data*: ARRAY 2*MEDIA_PACKET OF BYTE END;
    CircularBuffer* = RECORD(BufferDesc) circular*: BOOLEAN; wlen*: INTEGER END;
    Buffer* = POINTER TO CircularBuffer;

    ContainerHeader* = RECORD(Def.BufferDesc)
      CLen*: INTEGER;
      type*, code*: HALFWORD;
      trans_id*: INTEGER
    END;

    ParamContainer* = RECORD(ContainerHeader)
      Param1*, Param2*, Param3*, Param4*, Param5*: INTEGER
    END;

    Handle* = POINTER TO HandleDesc;
    HandleDesc* = RECORD(Def.ClassHandleDesc)
      alt_setting*: Def.ByteBuffer;
      dev_status*: Def.IntegerBuffer;
      rx_buff*, tx_buff*: Buffer; (* must be 32-bit aligned *)
      TransactionPhase*, SessionState*(*, RECEIVE_DATA_STATUS**): BYTE;
      ReqOp*, Response*: ParamContainer;
      cur_len*, readbytes*: INTEGER;
      obj_format*: HALFWORD;
      session_id, storage_id, objhandle: INTEGER
(*      objectInfo: Buffer*)
    END;

    String = ARRAY 256 OF CHAR;
    DateTimeString = ARRAY 20 OF CHAR;

    UserIf* = POINTER TO UserIfDesc;
    UserIfDesc* = RECORD(DDef.UserDataDesc)
      Init*, DeInit*: PROCEDURE;
      Create_NewObject*: PROCEDURE(objInfo: BufferDesc; objhandle: INTEGER): HALFWORD;
      GetIdx*: PROCEDURE(Param3, objhandle: INTEGER): INTEGER;
      GetParentObject*: PROCEDURE(Param: INTEGER): INTEGER;
      GetObjectFormat*: PROCEDURE(Param: INTEGER): HALFWORD;
      GetObjectName_len*: PROCEDURE(Param: INTEGER): BYTE;
      GetObjectName*: PROCEDURE(Param: INTEGER; objlen: BYTE; VAR buf: String);
      GetObjectSize*: PROCEDURE(oh: INTEGER): INTEGER;
      GetMaxCapability*: PROCEDURE(): LONGINT;
      GetFreeSpaceInBytes*: PROCEDURE(): LONGINT;
      GetNewIndex*: PROCEDURE(objformat: HALFWORD): INTEGER;
(*      WriteData*: PROCEDURE(buff: BufferDesc);
      GetContainerLength*: PROCEDURE(Param1: INTEGER): INTEGER;
*)
      DeleteObject*: PROCEDURE(Param1: INTEGER): HALFWORD;
      Cancel*: PROCEDURE(Phase: INTEGER);
(*      CopyBuffer*: PROCEDURE(s, d: Def.Buffer; idx: INTEGER);*)
      PutVendorExtension*, PutDeviceOpsSupported*, PutDeviceEventsSupported*,
      PutDevicePropsSupported*, PutDeviceCaptureFormatsSupported*, PutDevicePlaybackFormatsSupported*,
      PutManufacturer*, PutModel*, PutDeviceVersion*, PutSerialNumber*, (*DeviceInfo callbacks*)
      PutStorageIDs*, PutStorageType*, PutFilesystemType*, PutAccessCapability*, PutMaxCapacity*,
      PutFreeSpaceInBytes*, PutFreeSpaceInObjects*, PutStorageDescription*,
      PutVolumeIdentifier*: PROCEDURE(b: Def.Buffer); (*StorageInfo callbacks*)
      PutObjectHandles*: PROCEDURE(dev: Def.Handle; b: Def.Buffer; sid, ofc, f: INTEGER): HALFWORD;
      PutObjectStorageId*, PutObjectFormat*, PutProtectionStatus*, PutObjectCompressedSize*,
      PutThumbFormat*, PutThumbCompressedSize*, PutThumbPixWidth*, PutThumbPixHeight*,
      PutImageInfo*, PutParentObject*,
      PutAssociationType*, PutAssociationDesc*, PutSequenceNumber*, PutFilename*,
      PutDateCreated*, PutDateModified*, PutKeywords*: PROCEDURE(b: Def.Buffer; oh: INTEGER); (*ObjectInfo callbacks*)
      PutObjectPropsSupported*: PROCEDURE(b: Def.Buffer; ofc: INTEGER);
      PutObjectPropDefValue*, PutObjectPropGroupCode*, PutObjectPropFormFlag*,
      PutObjectPropGetSet*: PROCEDURE(b: Def.Buffer; opc, of, dt: INTEGER); (*ObjectPropDesc callbacks*)
      PutObjectPropList*: PROCEDURE(dev: Def.Handle; b: Def.Buffer; oh, ofc, opc, opgc, depth: INTEGER): HALFWORD;
      PutObjectPropValue*: PROCEDURE(b: Def.Buffer; oh, opc: INTEGER);
      PutObject*: PROCEDURE(dev: Def.Handle; b: Def.Buffer; oh: INTEGER): HALFWORD;
      PutDeviceFriendlyName*: PROCEDURE(b: Def.Buffer);
      PutDevicePropValue*: PROCEDURE(b: Def.Buffer; dpc: INTEGER);
      PutNextData*: PROCEDURE(dev: Def.Handle; b: Def.Buffer);
(*      ScratchBuff*: Generic*)
    END;

  PROCEDURE SwitchBuffer*(d: Def.Buffer);
  BEGIN (*wlen contains the amount of excess data fetched at previous call*)
    CASE d OF
      Buffer: INC(d.offset, d.size DIV 2); IF d.offset >= d.size THEN d.offset := 0 END; (*switch buffer*)
        d.length := d.wlen + d.offset (*set writing position*)
    | Def.Buffer: ASSERT(FALSE)
    END
  END SwitchBuffer;

  PROCEDURE Overflow*(d: Def.Buffer): BOOLEAN;
    VAR o: BOOLEAN;
  BEGIN
    CASE d OF
      Buffer: d.wlen := d.length - d.offset; IF d.wlen < 0 THEN INC(d.wlen, d.size) END;
      o := d.wlen >= d.size DIV 2
    | Def.Buffer: ASSERT(FALSE)
    END
    RETURN o
  END Overflow;

  PROCEDURE PrepareBuffer*(d: Def.Buffer);
    (*prepare the buffer for next send*)
  BEGIN
    CASE d OF
      Buffer: d.length := d.wlen; IF d.length >  d.size DIV 2 THEN d.length := d.size DIV 2 END;
        DEC(d.wlen, d.length); (*wlen contains the amount of excess data to be sent at next call*)
    | Def.Buffer: ASSERT(FALSE)
    END
  END PrepareBuffer;

  PROCEDURE BeginArray*(d: Def.Buffer; VAR beg: INTEGER);
  BEGIN Def.PutInteger(d, 0); (*placeholder for the number of elements of the array*)
    beg := d.length
  END BeginArray;

  PROCEDURE EndArray*(d: Def.Buffer; beg, elementSize: INTEGER);
    VAR length, count: INTEGER;
  BEGIN length := d.length; d.length := beg - 4; count := (length - beg) DIV elementSize;
    Def.PutInteger(d, count); d.length := length;
  END EndArray;

  PROCEDURE ReadByte(b: Def.Buffer): BYTE;
    VAR r: BYTE;
  BEGIN
    CASE b OF
      Buffer: r := b.data[b.index]; INC(b.index)
    | Def.Buffer: ASSERT(FALSE)
    END

    RETURN r
  END ReadByte;

  PROCEDURE WriteByte(b: Def.Buffer; v: BYTE);
  BEGIN
    CASE b OF
      Buffer: b.data[b.length] := v; INC(b.length);
        IF b.circular & (b.length >= b.size) THEN (*circular mode buffer*) b.length := 0 END
    | Def.Buffer: ASSERT(FALSE)
    END
  END WriteByte;

  PROCEDURE NewBuffer*(): Buffer;
    VAR b!: Buffer;
  BEGIN NEW(b); b.size := SYSTEM.SIZE(BufferDesc) - SYSTEM.SIZE(Def.BufferDesc);
    b.ReadByte := ReadByte; b.WriteByte := WriteByte
    RETURN b
  END NewBuffer;

  PROCEDURE NewHandle*(): Handle;
    VAR h!: Handle;
  BEGIN NEW(h);
      h.rx_buff := NewBuffer(); h.tx_buff := NewBuffer();
      NEW(h.dev_status); h.dev_status.size := SYSTEM.SIZE(Def.IntegerBufferDesc) - SYSTEM.SIZE(Def.BufferDesc);
      NEW(h.alt_setting); h.alt_setting.size := SYSTEM.SIZE(Def.ByteBufferDesc) - SYSTEM.SIZE(Def.BufferDesc);
      h.ReqOp.size := SYSTEM.SIZE(ParamContainer) - SYSTEM.SIZE(Def.BufferDesc);
      h.Response.size := SYSTEM.SIZE(ParamContainer) - SYSTEM.SIZE(Def.BufferDesc); h.Response.type := CONT_TYPE_RESPONSE
(*      h.objectInfo := NewBuffer()*)
    RETURN h
  END NewHandle;

  PROCEDURE PutString*(d: Def.Buffer; s: ARRAY OF CHAR);
    VAR i, l: INTEGER;
  BEGIN l := 0; WHILE s[l] # 0X DO INC(l) END;
    ASSERT(l <= 255);
    IF l = 0 THEN Def.PutByte(d, l)
    ELSE Def.PutByte(d, l+1); i := 0;
      REPEAT ASSERT(ORD(s[i]) < 80H); Def.PutHalfword(d, ORD(s[i])); INC(i) UNTIL i > l
    END
  END PutString;

  PROCEDURE PutHexByte*(d: Def.Buffer; b: BYTE);
  BEGIN
    IF b < 10 THEN Def.PutHalfword(d, b + ORD("0"))
    ELSE  Def.PutHalfword(d, b + (ORD("A") - 10))
    END
  END PutHexByte;

  PROCEDURE PutHexInteger*(d: Def.Buffer; x: INTEGER);
    VAR i: INTEGER;
  BEGIN FOR i := 1 TO 8 DO x := ROR(x, 28); PutHexByte(d, x MOD 10H) END
  END PutHexInteger;

  PROCEDURE GetRxBuffSize*(): INTEGER;
    RETURN SYSTEM.SIZE(BufferDesc) - SYSTEM.SIZE(Def.BufferDesc)
  END GetRxBuffSize;

  (**
  * @brief  USBD_MTP_OPT_OpenSession
  *         Open a new session
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE OpenSession*(dev: DDef.Handle);
    VAR hmtp!: Handle;
  BEGIN
    hmtp := dev.ClassDataCmsit[dev.classId](Handle);
    (* Param1 == Session ID*)
    IF hmtp.ReqOp.Param1 = 0 THEN hmtp.Response.code := RESPONSE_INVALID_PARAMETER
    ELSIF hmtp.SessionState = SESSION_OPEN THEN (* driver supports single session *)
      hmtp.Response.code := RESPONSE_SESSION_ALREADY_OPEN; hmtp.Response.Param1 := hmtp.session_id;
      hmtp.Response.CLen := CONT_HEADER_SIZE + 4;
    ELSE hmtp.Response.code := RESPONSE_OK; hmtp.SessionState := SESSION_OPEN; hmtp.session_id := hmtp.ReqOp.Param1
    END;
    Log.User("MTP session open")
  END OpenSession;

  (**
  * @brief  USBD_MTP_OPT_CloseSession
  *         Open a new session
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE CloseSession*(dev: DDef.Handle);
    VAR hmtp!: Handle;
  BEGIN
    hmtp := dev.ClassDataCmsit[dev.classId](Handle);
    IF hmtp.SessionState = SESSION_NOT_OPEN THEN hmtp.Response.code := RESPONSE_SESSION_NOT_OPEN
    ELSE hmtp.Response.code := RESPONSE_OK; hmtp.SessionState := SESSION_NOT_OPEN
    END;
    Log.User("MTP session closed")
  END CloseSession;

  (**
  * @brief  MTP_Get_DeviceInfo
  *         Fill the MTP_DeviceInfo struct
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_DeviceInfo(uif: UserIf; d: Buffer);
  BEGIN
    Def.PutHalfword(d, STANDARD_VERSION);
    Def.PutInteger(d, VEND_EXT_ID);
    Def.PutHalfword(d, VEND_EXT_VERSION);
    uif.PutVendorExtension(d); 
    Def.PutHalfword(d, FUNCTIONAL_MODE); (* device supports one mode , standard mode *)
    (* All supported operation *)
    uif.PutDeviceOpsSupported(d);
    uif.PutDeviceEventsSupported(d);
    uif.PutDevicePropsSupported(d);
    uif.PutDeviceCaptureFormatsSupported(d);
    uif.PutDevicePlaybackFormatsSupported(d);
    uif.PutManufacturer(d);
    uif.PutModel(d);
    uif.PutDeviceVersion(d);
    uif.PutSerialNumber(d)
  END Get_DeviceInfo;

  (**
  * @brief  MTP_Get_StorageIDS
  *         Fill the MTP_StorageIDS struct
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_StorageIDs(uif: UserIf; d: Buffer);
  BEGIN uif.PutStorageIDs(d)
  END Get_StorageIDs;

  (**
  * @brief  MTP_Get_StorageInfo
  *         Fill the MTP_StorageInfo struct
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_StorageInfo(uif: UserIf; d: Buffer);
  BEGIN
    uif.PutStorageType(d);
    uif.PutFilesystemType(d); 
    uif.PutAccessCapability(d); 
    uif.PutMaxCapacity(d);
    uif.PutFreeSpaceInBytes(d);
    uif.PutFreeSpaceInObjects(d);
    uif.PutStorageDescription(d);
    uif.PutVolumeIdentifier(d)
  END Get_StorageInfo;

  (**
  * @brief  MTP_Get_ObjectHandle
  *         Fill the MTP_ObjectHandle struct
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_ObjectHandles(dev: Def.Handle; uif: UserIf; hmtp: Handle): HALFWORD;
    RETURN uif.PutObjectHandles(dev, hmtp.tx_buff, hmtp.ReqOp.Param1,
      hmtp.ReqOp.Param2, hmtp.ReqOp.Param3)
  END Get_ObjectHandles;

  (**
  * @brief  MTP_Get_ObjectPropSupp
  *         Fill the MTP_ObjectPropSupp struct
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_ObjectPropsSupp(uif: UserIf; hmtp: Handle);
  BEGIN uif.PutObjectPropsSupported(hmtp.tx_buff, hmtp.ReqOp.Param1)
  END Get_ObjectPropsSupp;

  PROCEDURE Get_ObjectPropDatatype*(opc: HALFWORD): HALFWORD;
    VAR dt: HALFWORD;
  BEGIN
    IF opc = OB_PROP_OBJECT_FORMAT THEN dt := DATATYPE_UINT16
    ELSIF opc = OB_PROP_STORAGE_ID THEN dt := DATATYPE_UINT32
    ELSIF opc = OB_PROP_OBJ_FILE_NAME THEN dt := DATATYPE_STR
    ELSIF opc = OB_PROP_OBJECT_SIZE THEN dt := DATATYPE_UINT64
(*
    ELSIF opc = OB_PROP_NAME THEN dt := DATATYPE_STR
    ELSIF opc = OB_PROP_PERS_UNIQ_OBJ_IDEN THEN dt := DATATYPE_UINT128
*)
    ELSIF opc = OB_PROP_DATE_MODIFIED THEN dt := DATATYPE_STR
    ELSIF opc = OB_PROP_WIDTH THEN dt := DATATYPE_UINT32
    ELSIF opc = OB_PROP_HEIGHT THEN dt := DATATYPE_UINT32
    ELSIF opc = OB_PROP_IMAGE_BIT_DEPTH THEN dt := DATATYPE_UINT32
    ELSE dt := 0; Log.Error("Get_ObjectPropDatatype: ObjectPropCode ");
      Log.ErrorHexVLen(opc, 4, FALSE); Log.ErrorString(" not handled"); Log.ErrorLn
    END
    RETURN dt
  END Get_ObjectPropDatatype;

  (**
  * @brief  MTP_Get_ObjectPropDesc
  *         Fill the MTP_ObjectPropDesc struct
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_ObjectPropDesc(uif: UserIf; hmtp: Handle): HALFWORD;
    VAR ret: HALFWORD; opc, of, dt: INTEGER; d!: Buffer;
  BEGIN ret := RESPONSE_OK;
    opc := hmtp.ReqOp.Param1; of := hmtp.ReqOp.Param2;
    dt := Get_ObjectPropDatatype(opc);
    IF dt # 0 THEN
      d := hmtp.tx_buff;
      Def.PutHalfword(d, opc); (*first field is always the property code*)
      Def.PutHalfword(d, dt);
      uif.PutObjectPropGetSet(d, opc, of, dt);
      uif.PutObjectPropDefValue(d, opc, of, dt);
      uif.PutObjectPropGroupCode(d, opc, of, dt);
      uif.PutObjectPropFormFlag(d, opc, of, dt)
    ELSE ret := RESPONSE_OBJECT_PROP_NOT_SUPPORTED (*todo: implement this in backend callback*)
    END
    RETURN ret
  END Get_ObjectPropDesc;

  (**
  * @brief  MTP_Get_ObjectPropValue
  *         Get the property value
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_ObjectPropValue(uif: UserIf; hmtp: Handle);
  BEGIN uif.PutObjectPropValue(hmtp.tx_buff, hmtp.ReqOp.Param1, hmtp.ReqOp.Param2)
  END Get_ObjectPropValue;

  (**
  * @brief  MTP_Get_ObjectPropList
  *         Get the object property list data to be transmitted
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_ObjectPropList(dev: Def.Handle; uif: UserIf; hmtp: Handle): HALFWORD;
    RETURN uif.PutObjectPropList(dev, hmtp.tx_buff, hmtp.ReqOp.Param1,
      hmtp.ReqOp.Param2, hmtp.ReqOp.Param3, hmtp.ReqOp.Param4, hmtp.ReqOp.Param5)
  END Get_ObjectPropList;

  (**
  * @brief  MTP_Get_Object
  *         Get the object content
  * @param  pdev: device instance
  * @param  uif: backend procedures
  * @param  hmtp: mtp handle
  * @retval None
  *)
  PROCEDURE Get_Object(dev: Def.Handle; uif: UserIf; hmtp: Handle): HALFWORD;
    RETURN uif.PutObject(dev, hmtp.tx_buff, hmtp.ReqOp.Param1)
  END Get_Object;

  (**
  * @brief  MTP_Get_DevicePropDesc
  *         Fill the MTP_DevicePropDesc struct
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_DevicePropDesc(uif: UserIf; d: Buffer);
  BEGIN uif.PutDeviceFriendlyName(d)
  END  Get_DevicePropDesc;

  (**
  * @brief  MTP_Get_ObjectInfo
  *         Fill the MTP_ObjectInfo struct
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_ObjectInfo(uif: UserIf; hmtp: Handle);
    VAR oh: INTEGER; d!: Buffer;
  BEGIN 
    oh := hmtp.ReqOp.Param1; d := hmtp.tx_buff;
    uif.PutObjectStorageId(d, oh);
    uif.PutObjectFormat(d, oh);
    uif.PutProtectionStatus(d, oh);
    uif.PutObjectCompressedSize(d, oh);
    uif.PutThumbFormat(d, oh);
    uif.PutThumbCompressedSize(d, oh);
    uif.PutThumbPixWidth(d, oh);
    uif.PutThumbPixHeight(d, oh);
    uif.PutImageInfo(d, oh);
    uif.PutParentObject(d, oh);
    uif.PutAssociationType(d, oh);
    uif.PutAssociationDesc(d, oh);
    uif.PutSequenceNumber(d, oh);
    uif.PutFilename(d, oh);
    uif.PutDateCreated(d, oh);
    uif.PutDateModified(d, oh);
    uif.PutKeywords(d, oh);
  END Get_ObjectInfo;

  PROCEDURE GetContainerLength*(c: Def.Buffer): INTEGER;
    VAR index, len: INTEGER;
  BEGIN index := c.index; c.index := 0;
    len := Def.GetInteger(c); c.index := index
    RETURN len
  END GetContainerLength;

  PROCEDURE UpdateContainerLength*(c: Def.Buffer; len: INTEGER);
    VAR length: HALFWORD;
  BEGIN length := c.length; c.length := 0;
    Def.PutInteger(c, len); c.length := length
  END UpdateContainerLength;

  (**
  * @brief  MTP_Get_PayloadContent
  *         Get the payload data of generic container
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE Get_PayloadContent(dev: DDef.Handle);
    VAR hmtp!: Handle; uif!: UserIf; op(*, n_idx*): INTEGER; d!: Buffer;
  BEGIN
    hmtp := dev.ClassDataCmsit[dev.classId](Handle); hmtp.Response.code := RESPONSE_OK;
    uif := dev.UserData[dev.classId](UserIf);
    op := hmtp.ReqOp.code; d := hmtp.tx_buff; d.length := 0;
    (*prepare the container header*)
    Def.PutInteger(d, -2); (*mark the container size as uninitialized*)
    Def.PutHalfword(d, CONT_TYPE_DATA); Def.PutHalfword(d, op); Def.PutInteger(d, hmtp.ReqOp.trans_id);    
    hmtp.TransactionPhase := DATA_IN_PHASE;
    IF op = OP_GET_DEVICE_INFO THEN Get_DeviceInfo(uif, d)
    ELSIF op = OP_GET_DEVICE_PROP_DESC THEN Get_DevicePropDesc(uif, d)
    ELSIF op = OP_GET_STORAGE_IDS THEN Get_StorageIDs(uif, d)
    ELSIF op = OP_GET_STORAGE_INFO THEN Get_StorageInfo(uif, d)
    ELSIF op = OP_GET_OBJECT_HANDLES THEN hmtp.Response.code := Get_ObjectHandles(dev, uif, hmtp)
    ELSIF op = OP_GET_OBJECT_INFO THEN Get_ObjectInfo(uif, hmtp)
    ELSIF op = OP_GET_OBJECT_PROPS_SUPPORTED THEN Get_ObjectPropsSupp(uif, hmtp)
    ELSIF op = OP_GET_OBJECT_PROP_DESC THEN hmtp.Response.code := Get_ObjectPropDesc(uif, hmtp)
    ELSIF op = OP_GET_OBJECT_PROPLIST THEN hmtp.Response.code := Get_ObjectPropList(dev, uif, hmtp)
    ELSIF op = OP_GET_OBJECT_PROP_VALUE THEN Get_ObjectPropValue(uif, hmtp)
    ELSIF op = OP_GET_OBJECT THEN hmtp.Response.code := Get_Object(dev, uif, hmtp)
    ELSIF op = OP_SEND_OBJECT_INFO THEN hmtp.TransactionPhase := DATA_OUT_PHASE
(*TODO: Move the following statements in the response phase
      n_idx := uif.GetNewIndex(hmtp.obj_format);
      Def.PutInteger(d, hmtp.storage_id);
      Def.PutInteger(d, hmtp.objhandle);
      Def.PutInteger(d, n_idx)*)
    ELSIF op = OP_GET_DEVICE_PROP_VALUE THEN uif.PutDevicePropValue(d, hmtp.ReqOp.Param1)
    ELSE hmtp.Response.code := RESPONSE_OPERATION_NOT_SUPPORTED;
      Log.Error("Unhandled op: "); Log.ErrorHexVLen(op, 8, FALSE); Log.ErrorLn; Log.Flush
    END;
    IF GetContainerLength(d) = -2 THEN (*the getter does not set the size, assumed to be d.length*)
      UpdateContainerLength(d, d.length)
    END
  END Get_PayloadContent;

(*
  PROCEDURE Respond(hmtp: Handle; code: INTEGER);
  BEGIN
    hmtp.GenericContainer.trans_id := hmtp.OperationsContainer.trans_id;
    hmtp.GenericContainer.type := CONT_TYPE_RESPONSE;
    hmtp.ResponseCode := code;
    hmtp.GenericContainer.CLen :=  CONT_HEADER_SIZE
  END Respond;
*)

  (**
  * @brief  USBD_MTP_OPT_GetDeviceInfo
  *         Get all device information
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE GetDeviceInfo*(dev: DDef.Handle);
    VAR hmtp!: Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Handle);
    IF hmtp.SessionState = SESSION_NOT_OPEN THEN (* no session opened *)
      (* if GetDevice Info called outside a session then SessionID and Transaction_ID shall be 0x00000000*)
      (* Param1 == session ID*)
      IF (hmtp.ReqOp.Param1 = 0) & (hmtp.ReqOp.trans_id = 0) THEN
        hmtp.Response.code := RESPONSE_OK
      ELSE hmtp.Response.code := RESPONSE_INVALID_PARAMETER
      END
    ELSE hmtp.Response.code := RESPONSE_OK
    END;
    IF hmtp.Response.code = RESPONSE_OK THEN Get_PayloadContent(dev) END
  END GetDeviceInfo;

  (**
  * @brief  Process
  *         Process the requested operation
  * @param  dev: device instance
  * @retval None
  *)
  PROCEDURE ProcessOp*(dev: DDef.Handle);
    VAR hmtp!: Handle;
  BEGIN hmtp := dev.ClassDataCmsit[dev.classId](Handle);
    Get_PayloadContent(dev)
  END ProcessOp;

  (**
  * @brief  USBD_MTP_OPT_GetObject
  *         Get binary data from an object
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE GetObject*(dev: DDef.Handle);
    VAR hmtp!: Handle; uif!: UserIf; d!: Buffer;
  BEGIN
(*TODO
    hmtp := dev.ClassDataCmsit[dev.classId](Handle); hmtp.GenericContainer.length := 0;
    uif := dev.UserData[dev.classId](UserIf);
    hmtp.GenericContainer.code := 0;
    hmtp.GenericContainer.CLen := uif.GetObjectSize(hmtp.OperationsContainer.Param1) + CONT_HEADER_SIZE;
    hmtp.GenericContainer.trans_id := hmtp.OperationsContainer.trans_id;
    hmtp.GenericContainer.type := CONT_TYPE_DATA;
    hmtp.ResponseCode := RESPONSE_OK
*)
  END GetObject;

  (**
  * @brief  USBD_MTP_OPT_SendObject
  *         Send object from host to MTP device
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE SendObject*(dev: DDef.Handle; buff: Buffer);
    VAR hmtp!: Handle; uif!: UserIf;
  BEGIN
(* TODO replace following:
    hmtp := dev.ClassDataCmsit[dev.classId](Handle); hmtp.GenericContainer.length := 0;
    uif := dev.UserData[dev.classId](UserIf);
    IF hmtp.RECEIVE_DATA_STATUS = RECEIVE_IDLE_STATE THEN
      hmtp.RECEIVE_DATA_STATUS := RECEIVE_COMMAND_DATA
    ELSIF hmtp.RECEIVE_DATA_STATUS = RECEIVE_COMMAND_DATA THEN buff.offset := 0;
      hmtp.RECEIVE_DATA_STATUS := RECEIVE_FIRST_DATA
    ELSIF hmtp.RECEIVE_DATA_STATUS = RECEIVE_FIRST_DATA THEN
      IF buff.length >= buff.CLen THEN (*all data is sent in the first packet*)
        hmtp.GenericContainer.code :=  RESPONSE_OK;
        hmtp.GenericContainer.trans_id := hmtp.OperationsContainer.trans_id;
        hmtp.GenericContainer.type := CONT_TYPE_RESPONSE;
        hmtp.GenericContainer.CLen := CONT_HEADER_SIZE;
        hmtp.GenericContainer.length :=  hmtp.GenericContainer.CLen;
        hmtp.RECEIVE_DATA_STATUS := RECEIVE_IDLE_STATE;
      ELSE hmtp.RECEIVE_DATA_STATUS := RECEIVE_REST_OF_DATA;
        buff.offset := CONT_HEADER_SIZE (*next packet doesn't have container header*)
      END;
      DEC(hmtp.GenericContainer.length, CONT_HEADER_SIZE); (*subtract header size from data length*)
      hmtp.cur_len := 0; uif.WriteData(buff^)
    ELSIF hmtp.RECEIVE_DATA_STATUS = RECEIVE_REST_OF_DATA THEN uif.WriteData(buff^)
    ELSIF hmtp.RECEIVE_DATA_STATUS = SEND_RESPONSE THEN
      buff.length := 0; uif.WriteData(buff^); (* send 0 length to stop write process *)
      hmtp.GenericContainer.code :=  RESPONSE_OK;
      hmtp.GenericContainer.trans_id := hmtp.OperationsContainer.trans_id;
      hmtp.GenericContainer.type := CONT_TYPE_RESPONSE;
      hmtp.GenericContainer.CLen := CONT_HEADER_SIZE;
      hmtp.GenericContainer.length :=  hmtp.GenericContainer.CLen;
      hmtp.RECEIVE_DATA_STATUS := RECEIVE_IDLE_STATE
    END;
    hmtp.ResponseCode := RESPONSE_OK
*)
  END SendObject;

  (**
  * @brief  USBD_MTP_OPT_SendObjectInfo
  *         Send the object information from host to MTP device
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE SendObjectInfo*(dev: DDef.Handle; buff: Buffer);
    VAR hmtp!: Handle; uif!: UserIf;
  BEGIN
(* TODO replace following:
    hmtp := dev.ClassDataCmsit[dev.classId](Handle); hmtp.GenericContainer.length := 0;
    uif := dev.UserData[dev.classId](UserIf);
    IF hmtp.RECEIVE_DATA_STATUS = RECEIVE_IDLE_STATE THEN
      hmtp.RECEIVE_DATA_STATUS := RECEIVE_COMMAND_DATA
    ELSIF hmtp.RECEIVE_DATA_STATUS = RECEIVE_COMMAND_DATA THEN
      (* store object handle and storage id for future use *)
      IF hmtp.OperationsContainer.Param2 = 0FFFFFFFFH THEN hmtp.objhandle := 0
      ELSE hmtp.objhandle := hmtp.OperationsContainer.Param2
      END;
      hmtp.storage_id := hmtp.OperationsContainer.Param1;
      hmtp.RECEIVE_DATA_STATUS := RECEIVE_FIRST_DATA
    ELSIF hmtp.RECEIVE_DATA_STATUS = RECEIVE_FIRST_DATA THEN
      hmtp.objectInfo.length := 0; CopyContainerToDataset(buff(Generic), hmtp.objectInfo);
      hmtp.RECEIVE_DATA_STATUS := RECEIVE_REST_OF_DATA
    ELSIF hmtp.RECEIVE_DATA_STATUS = RECEIVE_REST_OF_DATA THEN
      CopyContainerToDataset(buff(Generic), hmtp.objectInfo)
    ELSIF hmtp.RECEIVE_DATA_STATUS = SEND_RESPONSE THEN
      hmtp.objectInfo.index := 4; (*go to object format*)
      hmtp.obj_format := Def.GetHalfword(hmtp.objectInfo);
      hmtp.ResponseCode := uif.Create_NewObject(hmtp.objectInfo^, hmtp.objhandle);
      IF Get_PayloadContent(dev) = Def.OK THEN (*todo the following code is strange after a Get_PayloadContent*)
        hmtp.GenericContainer.code := hmtp.ResponseCode;
        hmtp.GenericContainer.CLen :=  CONT_HEADER_SIZE + hmtp.GenericContainer.length;
        hmtp.GenericContainer.type := CONT_TYPE_RESPONSE;
        hmtp.GenericContainer.trans_id := hmtp.OperationsContainer.trans_id
      ELSE Respond(hmtp, RESPONSE_INVALID_PARAMETER)
      END;
      hmtp.GenericContainer.length := hmtp.GenericContainer.CLen;
      hmtp.RECEIVE_DATA_STATUS := RECEIVE_IDLE_STATE
    END
*)
  END SendObjectInfo;

  (**
  * @brief  USBD_MTP_OPT_DeleteObject
  *         Delete the object from the device
  * @param  pdev: device instance
  * @retval None
  *)
  PROCEDURE DeleteObject*(dev: DDef.Handle);
    VAR hmtp!: Handle; uif!: UserIf;
  BEGIN
(*TODO
    hmtp := dev.ClassDataCmsit[dev.classId](Handle); hmtp.GenericContainer.length := 0;
    uif := dev.UserData[dev.classId](UserIf);
    hmtp.GenericContainer.trans_id := hmtp.OperationsContainer.trans_id;
    hmtp.GenericContainer.type := CONT_TYPE_RESPONSE;
    hmtp.GenericContainer.CLen :=  CONT_HEADER_SIZE + hmtp.GenericContainer.length;
    hmtp.GenericContainer.length := hmtp.GenericContainer.CLen;
    hmtp.ResponseCode := uif.DeleteObject(hmtp.OperationsContainer.Param1)
*)
  END DeleteObject;

END USBDMTPOpt.
