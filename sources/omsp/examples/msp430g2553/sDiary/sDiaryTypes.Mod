MODULE sDiaryTypes;
  CONST TITLE_LEN* = 4*14; (*4 lines of 14 characters*)

  TYPE DE* = POINTER TO DEDesc;
    DEDesc* = RECORD (*Diary entry structure*)
      titre*: ARRAY TITLE_LEN OF BYTE;
      cron*: ARRAY 6 OF BYTE; (*"crontab like" min hour dom month year dow, 0xFF accept all value*)
      clearingDelay*: INTEGER (*number of minutes before erasing screen*)
    END;
    
END sDiaryTypes.
