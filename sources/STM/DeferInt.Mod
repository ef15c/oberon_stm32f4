MODULE DeferInt;
  (* Christan Schoffit 06.06.26
      This module implements a message queue that is used in the USB stack
      to defer the heavy work outside the IRQ context*)
  TYPE
    Msg* = POINTER TO MsgDesc;
    MsgDesc* = RECORD next: Msg END;

  VAR exhausted*: BOOLEAN;

  PROCEDURE CreatePool*(size: INTEGER; new: PROCEDURE(): Msg): Msg;
    VAR i: INTEGER; head!, item!: Msg;
  BEGIN item := NIL;
    FOR i := 1 TO size DO item := new(); item.next := head; head := item END

    RETURN head
  END CreatePool;

  PROCEDURE Get*(VAR queue: Msg): Msg;
    VAR item!: Msg;
  BEGIN item := queue;
    IF item # NIL THEN queue := item.next ELSE exhausted := TRUE END

    RETURN item
  END Get;

  PROCEDURE Post*(VAR queue: Msg; item: Msg);
  BEGIN item.next := queue; queue := item
  END Post;

END DeferInt.

OM4P.Compile DeferInt.Mod/s~
