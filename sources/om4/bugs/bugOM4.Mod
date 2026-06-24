MODULE bugOM4;
  IMPORT Q := Queue;

  TYPE
    DebugMsg = POINTER TO DebugMsgDesc;
    DebugMsgDesc = RECORD(Q.MsgDesc) END;

  VAR DebugMP: Q.Msg;

  PROCEDURE p*;
    VAR msg!: Q.Msg; dbm!: DebugMsg;
      i: INTEGER;
  BEGIN
    FOR i := 1 TO 10 DO
      msg := Q.Get(DebugMP);
      IF msg # NIL THEN dbm := msg(DebugMsg); CLEAR(dbm^);
      END
    END
  END p;

    PROCEDURE newDebugMsg(): Q.Msg;
      VAR item!: DebugMsg;
    BEGIN NEW(item)

      RETURN item
    END newDebugMsg;

BEGIN DebugMP := Q.CreatePool(1, newDebugMsg)
END bugOM4.

OM4P.Compile bugOM4.Mod/s~
System.Free bugOM4~
bugOM4.p

OM4Tool.DecObj bugOM4.m4c
