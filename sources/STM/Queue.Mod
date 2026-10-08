MODULE Queue;
  (* Christan Schoffit 06.06.26
      This module implements a message queue that is used in the USB stack
      to defer the heavy work outside the IRQ context*)
  IMPORT BSP, Kernel;

  TYPE
    Msg* = POINTER TO MsgDesc;
    MsgDesc* = RECORD time*, ts*: INTEGER; guard: BOOLEAN; next: Msg END;

  VAR exhausted: BOOLEAN;

  PROCEDURE CreatePool*(size: INTEGER; new: PROCEDURE(): Msg): Msg;
    VAR i: INTEGER; head!, item!: Msg;
  BEGIN head := new(); head.guard := TRUE;
    FOR i := 1 TO size DO item := new(); item.next := head; head := item END

    RETURN head
  END CreatePool;

  PROCEDURE Get*(VAR queue: Msg): Msg;
    VAR item!: Msg;
  BEGIN item := NIL;
    IF queue # NIL THEN
      IF queue.guard THEN exhausted := TRUE
      ELSE item := queue; queue := item.next; item.next := NIL
      END
    END

    RETURN item
  END Get;

  PROCEDURE PostFirst*(VAR queue: Msg; item: Msg);
  BEGIN item.next := queue; queue := item
  END PostFirst;

  PROCEDURE Post*(VAR queue: Msg; item: Msg);
    VAR t!: Msg;
  BEGIN
    IF item # NIL THEN
      item.time := Kernel.Time(); item.ts := BSP.TimeStamp(); item.next := NIL;
      IF queue = NIL THEN queue := item
      ELSE t := queue; WHILE t.next # NIL DO t := t.next END;
        t.next := item
      END
    END
  END Post;

  PROCEDURE HaveExhaustedPools*(): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN res := exhausted; exhausted := FALSE

    RETURN res
  END HaveExhaustedPools;

  PROCEDURE IsExhausted*(queue: Msg): BOOLEAN;
    RETURN queue.guard
  END IsExhausted;

END Queue.

OM4P.Compile Queue.Mod/s~
