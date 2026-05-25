MODULE USBLog;
  (** ported to Oberon from:
  ******************************************************************************
  * @author  MCD Application Team
  * @brief   General low level driver configuration
  ******************************************************************************
  *)

  IMPORT Texts, Oberon;

  VAR W: Texts.Writer;

  (* DEBUG logging *)
  PROCEDURE UserString*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, msg)
  END UserString;

  PROCEDURE UserInt*(val, len: INTEGER);
  BEGIN Texts.WriteInt(W, val, len)
  END UserInt;

  PROCEDURE UserHexVLen*(x, n: INTEGER; lz: BOOLEAN);
  BEGIN Texts.WriteHexVLen(W, x, n, lz)
  END UserHexVLen;

  PROCEDURE UserSet*(s: SET);
    VAR i, j: INTEGER; sep: ARRAY 3 OF CHAR;
  BEGIN sep := "{"; i := 0;
    WHILE i < 32 DO j := i+1;
      IF i IN s THEN Texts.WriteString(W, sep); sep := ", ";
        Texts.WriteInt(W, i, 1);
        IF j IN s THEN Texts.WriteString(W, "..");
          WHILE (j < 32) & (j+1 IN s) DO INC(j) END;
          Texts.WriteInt(W, j, 1); INC(j)
        END
      END;
      i := j
    END;
    Texts.Write(W, "}")
  END UserSet;

  PROCEDURE UserLn*;
  BEGIN Texts.WriteLn(W);
  END UserLn;

  PROCEDURE User*(msg: ARRAY OF CHAR);
  BEGIN UserString(msg); UserLn;
  END User;

  PROCEDURE Error*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, "ERROR: "); User(msg)
  END Error;

  PROCEDURE Debug*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, "DEBUG: "); Texts.WriteString(W, msg)
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

  PROCEDURE DebugLn*;
  BEGIN UserLn
  END DebugLn;

  PROCEDURE Flush*;
  BEGIN Texts.Append(Oberon.Log, W.buf)
  END Flush;

BEGIN Texts.OpenWriter(W)
END USBLog.
