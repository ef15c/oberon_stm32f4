MODULE LFQ;
  (* Christan Schoffit 20.11.26
      Lock free queue module*)
  IMPORT SYSTEM, BSP, Kernel;

  TYPE
    Msg* = POINTER TO MsgDesc;
    MsgDesc* = RECORD type*, time*, ts*: INTEGER; next: Msg END;
    Queue* = RECORD head, tail: Msg; sizePL: INTEGER; exhO, exhP: BYTE END;

  PROCEDURE InitQueue*(VAR queue: Queue; adr, len, size: INTEGER);
    VAR i: INTEGER; t!, item!: Msg;
  BEGIN ASSERT(len > 1); t := SYSTEM.VAL(Msg, adr); t.type := -1;
    queue.head :=  t; queue.tail := t; queue.sizePL := (size - SYSTEM.SIZE(MsgDesc)) DIV 4;
    FOR i := 1 TO len - 1 DO INC(adr, size); item := SYSTEM.VAL(Msg, adr);
      item.type := -1; t.next := item; t := item
    END;
    item.next := queue.head; (*close the ring*)
  END InitQueue;

  PROCEDURE Poll*(VAR queue: Queue): Msg;
    VAR item!, head!: Msg;
  BEGIN item := NIL;
    REPEAT head := LDREX(queue.head);
      IF head # queue.tail THEN item := head; head := head.next;
        SYSTEM.MBI(1) (*data memory barrier*)
      END
    UNTIL STREX(queue.head, head)

    RETURN item
  END Poll;

  PROCEDURE Offer*(VAR queue: Queue; VAR item: MsgDesc; type: INTEGER);
    VAR tail!: Msg;
  BEGIN
    REPEAT tail := LDREX(queue.tail);
      IF tail.next = queue.head THEN INC(queue.exhO) (*queue is full*)
      ELSE tail.time := Kernel.Time(); tail.ts := BSP.TimeStamp(); tail.type := type;
        SYSTEM.COPY(SYSTEM.ADR(item) + SYSTEM.SIZE(MsgDesc),
          ORD(tail) + SYSTEM.SIZE(MsgDesc), queue.sizePL);
        tail := tail.next
      END;
      SYSTEM.MBI(1) (*data memory barrier*)
    UNTIL STREX(queue.tail, tail)
  END Offer;

  PROCEDURE ExhaustedQueue*(VAR queue: Queue): BOOLEAN;
    VAR eq: BOOLEAN;
  BEGIN eq := queue.exhO # queue.exhP; queue.exhP := queue.exhO
    RETURN eq
  END ExhaustedQueue;

  PROCEDURE Tail*(VAR queue: Queue): Msg;
    RETURN LDREX(queue.tail)
  END Tail;

END LFQ.

OM4P.Compile LFQ.Mod/s~
OM4Tool.DecObj LFQ.m4c
