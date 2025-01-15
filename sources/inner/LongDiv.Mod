MODULE LongDiv;
  IMPORT SYSTEM;

  TYPE DivParam* = RECORD D*, S*: LONGINT END;

  PROCEDURE DivL*(VAR p: DivParam);
    (* Divides 2 64bit integers. D is dividend, S is divisor
        at exit D becomes D MOD S and S becomes D DIV S *)
    VAR clzd, clzs, coef, coef2: INTEGER; neg: BOOLEAN; q, rd: LONGINT;
  BEGIN (* Int64 division *)
    IF p.S > 0 THEN
      neg := FALSE;
      IF p.D < 0 THEN neg := TRUE; p.D := -p.D END;
      clzd := CLZ(p.D); clzs :=  CLZ(p.S);
      IF (clzd >= 32) & (clzs >= 32) THEN (*both D and S fit in INTEGER, we can use 32bit division*)
        clzd := SYSTEM.VAL(INTEGER, p.D) DIV SYSTEM.VAL(INTEGER, p.S); 
        DEC(SYSTEM.VAL(INTEGER, p.D), clzd*SYSTEM.VAL(INTEGER, p.S)); p.S := clzd
      ELSE (*64bit division is required*) coef := clzs - clzd;
        IF coef < 0 THEN p.S := 0
        ELSE q := 0; rd := p.S; IF coef > 0 THEN rd := LSL(rd, coef) END;
          WHILE p.D >= p.S DO
            IF p.D < rd THEN rd := LSR(rd, 1); q := LSL(q, 1); DEC(coef) END;
            DEC(p.D, rd); INC(q);
            clzd := CLZ(p.D); clzs := CLZ(rd); coef2 := clzd - clzs; IF coef2 > coef THEN coef2 := coef END;
            IF coef2 > 0 THEN q := LSL(q, coef2); rd := LSR(rd, coef2); DEC(coef, coef2) END
          END; p.S := q
        END
      END; IF neg THEN p.D := -p.D; p.S := -p.S END
    END
  END DivL;
END LongDiv.

