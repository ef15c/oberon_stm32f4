MODULE USBLog;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   General low level driver configuration
  ******************************************************************************
  *)

  IMPORT Display, Texts, Oberon;

  TYPE MsgCallback = PROCEDURE^5(msg: ARRAY OF CHAR);
    IntCallback = PROCEDURE^5(val, len: INTEGER);
    HexVLenCallback = PROCEDURE^5(x, n: INTEGER; lz: BOOLEAN);
    SetCallback = PROCEDURE^5(s: SET);
    BufCallback = PROCEDURE^5(buf: ARRAY OF BYTE; len: INTEGER);
    LnCallback = PROCEDURE^5;

  VAR W: Texts.Writer; wrnum, rdnum: INTEGER;
    UserCbk, ErrorCbk, DebugCbk,
    UserStringCbk, ErrorStringCbk, DebugStringCbk: MsgCallback;
    UserIntCbk, ErrorIntCbk, DebugIntCbk: IntCallback;
    UserHexVLenCbk, ErrorHexVLenCbk, DebugHexVLenCbk: HexVLenCallback;
    UserSetCbk, ErrorSetCbk, DebugSetCbk: SetCallback;
    UserBufCbk, ErrorBufCbk, DebugBufCbk: BufCallback;
    UserLnCbk, ErrorLnCbk, DebugLnCbk: LnCallback;

  (* DEBUG logging *)
  PROCEDURE DefaultString*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, msg); INC(wrnum)
  END DefaultString;

  PROCEDURE DefaultInt*(val, len: INTEGER);
  BEGIN Texts.WriteInt(W, val, len);  INC(wrnum)
  END DefaultInt;

  PROCEDURE DefaultHexVLen*(x, n: INTEGER; lz: BOOLEAN);
  BEGIN Texts.WriteHexVLen(W, x, n, lz);  INC(wrnum)
  END DefaultHexVLen;

  PROCEDURE DefaultSet*(s: SET);
    VAR i, j: INTEGER; first: BOOLEAN;
  BEGIN first := TRUE; i := 0; Texts.Write(W, "{");
    WHILE i < 32 DO j := i+1;
      IF i IN s THEN IF first THEN first := FALSE ELSE Texts.WriteString(W, ", ") END;
        Texts.WriteInt(W, i, 1);
        IF j IN s THEN Texts.WriteString(W, "..");
          WHILE (j < 32) & (j+1 IN s) DO INC(j) END;
          Texts.WriteInt(W, j, 1); INC(j)
        END
      END;
      i := j
    END;
    Texts.Write(W, "}"); INC(wrnum)
  END DefaultSet;

  PROCEDURE DefaultBuf*(buf: ARRAY OF BYTE; len: INTEGER);
    VAR i: INTEGER;
  BEGIN Texts.Write(W, "("); Texts.WriteInt(W, len, 1); Texts.Write(W, ")");
    FOR i := 0 TO len - 1 DO Texts.Write(W, " "); Texts.WriteHexVLen(W, buf[i], 2, FALSE) END;
    INC(wrnum)
  END DefaultBuf;

  PROCEDURE DefaultLn*;
  BEGIN Texts.WriteLn(W); INC(wrnum)
  END DefaultLn;

  PROCEDURE DefaultUser*(msg: ARRAY OF CHAR);
  BEGIN DefaultString(msg); DefaultLn
  END DefaultUser;

  PROCEDURE DefaultError*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, "ERROR: "); DefaultString(msg)
  END DefaultError;

  PROCEDURE DefaultDebug*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, "DEBUG: "); DefaultString(msg)
  END DefaultDebug;

  PROCEDURE User*(msg: ARRAY OF CHAR);
  BEGIN IF UserCbk # NIL THEN W.col := Display.green; UserCbk(msg) END
  END User;

  PROCEDURE UserString*(msg: ARRAY OF CHAR);
  BEGIN IF UserStringCbk # NIL THEN W.col := Display.green; UserStringCbk(msg) END
  END UserString;

  PROCEDURE UserInt*(val, len: INTEGER);
  BEGIN IF UserIntCbk # NIL THEN W.col := Display.green; UserIntCbk(val, len) END
  END UserInt;

  PROCEDURE UserHexVLen*(x, n: INTEGER; lz: BOOLEAN);
  BEGIN IF UserHexVLenCbk # NIL THEN W.col := Display.green; UserHexVLenCbk(x, n, lz) END
  END UserHexVLen;

  PROCEDURE Error*(msg: ARRAY OF CHAR);
  BEGIN IF ErrorCbk # NIL THEN W.col := Display.red; ErrorCbk(msg) END
  END Error;

  PROCEDURE ErrorLn*;
  BEGIN IF ErrorLnCbk # NIL THEN ErrorLnCbk END
  END ErrorLn;

  PROCEDURE Debug*(msg: ARRAY OF CHAR);
  BEGIN IF DebugCbk # NIL THEN W.col := Display.yellow; DebugCbk(msg) END
  END Debug;

  PROCEDURE DebugString*(msg: ARRAY OF CHAR);
  BEGIN IF DebugStringCbk # NIL THEN W.col := Display.yellow; DebugStringCbk(msg) END
  END DebugString;

  PROCEDURE DebugInt*(val, len: INTEGER);
  BEGIN IF DebugIntCbk # NIL THEN W.col := Display.yellow; DebugIntCbk(val, len) END
  END DebugInt;

  PROCEDURE DebugHexVLen*(x, n: INTEGER; lz: BOOLEAN);
  BEGIN IF DebugHexVLenCbk # NIL THEN W.col := Display.yellow; DebugHexVLenCbk(x, n, lz) END
  END DebugHexVLen;

  PROCEDURE DebugSet*(s: SET);
  BEGIN IF DebugSetCbk # NIL THEN DebugSetCbk(s) END
  END DebugSet;

  PROCEDURE DebugBuf*(buf: ARRAY OF BYTE; len: INTEGER);
  BEGIN IF DebugBufCbk # NIL THEN DebugBufCbk(buf, len) END
  END DebugBuf;

  PROCEDURE DebugLn*;
  BEGIN IF DebugLnCbk # NIL THEN DebugLnCbk END
  END DebugLn;

  PROCEDURE Flush*;
  BEGIN IF wrnum # rdnum THEN Texts.Append(Oberon.Log, W.buf); INC(rdnum) END
  END Flush;

  PROCEDURE SetUserCbks*(prompt, string: MsgCallback; int: IntCallback; hex: HexVLenCallback; 
   set: SetCallback; buf: BufCallback; ln: LnCallback);
  BEGIN UserCbk := prompt; UserStringCbk := string; UserIntCbk := int; UserHexVLenCbk := hex;
    UserSetCbk := set; UserBufCbk := buf; UserLnCbk := ln
  END SetUserCbks;

  PROCEDURE SetErrorCbks*(prompt, string: MsgCallback; int: IntCallback; hex: HexVLenCallback; 
   set: SetCallback; buf: BufCallback; ln: LnCallback);
  BEGIN ErrorCbk := prompt; ErrorStringCbk := string; ErrorIntCbk := int; ErrorHexVLenCbk := hex;
    ErrorSetCbk := set; ErrorBufCbk := buf; ErrorLnCbk := ln
  END SetErrorCbks;

  PROCEDURE SetDebugCbks*(prompt, string: MsgCallback; int: IntCallback; hex: HexVLenCallback; 
   set: SetCallback; buf: BufCallback; ln: LnCallback);
  BEGIN DebugCbk := prompt; DebugStringCbk := string; DebugIntCbk := int; DebugHexVLenCbk := hex;
    DebugSetCbk := set; DebugBufCbk := buf; DebugLnCbk := ln
  END SetDebugCbks;

  PROCEDURE SetDefaultCbks*;
  BEGIN
    SetUserCbks(DefaultUser, DefaultString, DefaultInt, DefaultHexVLen, DefaultSet, DefaultBuf, DefaultLn);
    SetErrorCbks(DefaultError, DefaultString, DefaultInt, DefaultHexVLen, DefaultSet, DefaultBuf, DefaultLn);
    SetDebugCbks(NIL, NIL, NIL, NIL, NIL, NIL, NIL);
  END SetDefaultCbks;

BEGIN Texts.OpenWriter(W); SetDefaultCbks
END USBLog.

OM4Tool.DecSym USBLog.sm4
