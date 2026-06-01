MODULE USBLog;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   General low level driver configuration
  ******************************************************************************
  *)

  IMPORT Texts, Oberon;

  VAR W: Texts.Writer; wrnum, rdnum: INTEGER;

  (* DEBUG logging *)
  PROCEDURE UserString*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, msg); INC(wrnum)
  END UserString;

  PROCEDURE UserInt*(val, len: INTEGER);
  BEGIN Texts.WriteInt(W, val, len);  INC(wrnum)
  END UserInt;

  PROCEDURE UserHexVLen*(x, n: INTEGER; lz: BOOLEAN);
  BEGIN Texts.WriteHexVLen(W, x, n, lz);  INC(wrnum)
  END UserHexVLen;

  PROCEDURE UserSet*(s: SET);
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
  END UserSet;

  PROCEDURE UserBuf*(buf: ARRAY OF BYTE; len: INTEGER);
    VAR i: INTEGER;
  BEGIN Texts.Write(W, "("); Texts.WriteInt(W, len, 1); Texts.Write(W, ")");
    FOR i := 0 TO len - 1 DO Texts.Write(W, " "); Texts.WriteHexVLen(W, buf[i], 2, FALSE) END;
    INC(wrnum)
  END UserBuf;

  PROCEDURE UserLn*;
  BEGIN Texts.WriteLn(W); INC(wrnum)
  END UserLn;

  PROCEDURE User*(msg: ARRAY OF CHAR);
  BEGIN UserString(msg); UserLn
  END User;

  PROCEDURE Error*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, "ERROR: "); User(msg)
  END Error;

  PROCEDURE Debug*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, "DEBUG: "); Texts.WriteString(W, msg); INC(wrnum)
  END Debug;

  PROCEDURE DebugString*(msg: ARRAY OF CHAR);
  BEGIN UserString(msg)
  END DebugString;

  PROCEDURE DebugInt*(val, len: INTEGER);
  BEGIN UserInt(val, len)
  END DebugInt;

  PROCEDURE DebugHexVLen*(x, n: INTEGER; lz: BOOLEAN);
  BEGIN UserHexVLen(x, n, lz)
  END DebugHexVLen;

  PROCEDURE DebugSet*(s: SET);
  BEGIN UserSet(s)
  END DebugSet;

  PROCEDURE DebugBuf*(buf: ARRAY OF BYTE; len: INTEGER);
  BEGIN UserBuf(buf, len)
  END DebugBuf;

  PROCEDURE DebugLn*;
  BEGIN UserLn
  END DebugLn;

  PROCEDURE Flush*;
  BEGIN IF wrnum # rdnum THEN Texts.Append(Oberon.Log, W.buf); INC(rdnum) END
  END Flush;

BEGIN Texts.OpenWriter(W)
END USBLog.
