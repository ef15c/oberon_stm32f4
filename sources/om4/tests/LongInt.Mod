MODULE LongInt;
  IMPORT SYSTEM, Texts, Oberon;

  VAR a, b: LONGINT; c: INTEGER;
    W: Texts.Writer;

  PROCEDURE test(a, b: LONGINT);
    VAR c: BOOLEAN;
  BEGIN c := a < b
  END test;

  PROCEDURE Write(l: LONGINT);
    VAR low: INTEGER;
  BEGIN low := l; l := LSR(l, 32);
    Texts.WriteHex(W, l); Texts.WriteHex(W, low); Texts.WriteLn(W);

    Texts.Append(Oberon.Log, W.buf)
  END Write;

  PROCEDURE DivL(VAR D, S: LONGINT);
    (* Divides 2 64bit integers. D is dividend, S is divisor
        at exit D becomes D MOD S and S becomes D DIV S *)
    VAR clzd, clzs, coef, coef2: INTEGER; neg: BOOLEAN; q, rd: LONGINT;
  BEGIN (* Int64 division *) neg := FALSE;
    IF D < 0 THEN neg := TRUE; D := -D END;
    clzd := CLZ(D); clzs :=  CLZ(S);
    IF (clzd >= 32) & (clzs >= 32) THEN (*both D and S fit in INTEGER, we can use 32bit division*)
      clzd := SYSTEM.VAL(INTEGER, D) DIV SYSTEM.VAL(INTEGER, S); 
      DEC(SYSTEM.VAL(INTEGER, D), clzd*SYSTEM.VAL(INTEGER, S)); S := clzd
    ELSE (*64bit division is required*) coef := clzs - clzd;
      IF coef < 0 THEN S := 0
      ELSE q := 0; rd := S; IF coef > 0 THEN rd := LSL(rd, coef) END;
        WHILE D >= S DO
          IF D < rd THEN rd := LSR(rd, 1); q := LSL(q, 1); DEC(coef) END;
          DEC(D, rd); INC(q);
          clzd := CLZ(D); clzs := CLZ(rd); coef2 := clzd - clzs; IF coef2 > coef THEN coef2 := coef END;
          ASSERT(coef2 >= 0); 
          IF coef2 > 0 THEN q := LSL(q, coef2); rd := LSR(rd, coef2); DEC(coef, coef2) END
        END;
        ASSERT(coef = 0); S := q
      END
    END; IF neg THEN D := -D; S := -S END
  END DivL;

  PROCEDURE run*;
    VAR c: INTEGER;
  BEGIN a := 1234567890; a := a*10000000; INC(a, 1234567);
    b := 10;
    DivL(a, b);
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, SYSTEM.VAL(INTEGER, a), 1); Texts.WriteLn(W);
    Write(b);

    Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W)
END LongInt.

OM4Tool.DecObj LongInt.m4c
