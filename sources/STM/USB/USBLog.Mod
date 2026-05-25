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

  PROCEDURE User*(msg: ARRAY OF CHAR);
  BEGIN UserString(msg); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END User;

  PROCEDURE Error*(msg: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, "ERROR: "); User(msg)
  END Error;

  PROCEDURE Debug*(msg: ARRAY OF CHAR);
  END Debug;

  PROCEDURE DebugString*(msg: ARRAY OF CHAR);
  END DebugString;

  PROCEDURE DebugInt*(val, len: INTEGER);
  END DebugInt;

BEGIN Texts.OpenWriter(W)
END USBLog.
