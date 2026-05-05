MODULE LongDiv;
  IMPORT SYSTEM;

  TYPE DivParam* = RECORD D*, S*: LONGINT END;

  PROCEDURE DivL*(VAR p: DivParam);
    (* Divides 2 64bit integers. D is dividend, S is divisor
        at exit D becomes D MOD S and S becomes D DIV S *)
    VAR clzd, clzs, coef, coef2: INTEGER; neg: SET; q, rd: LONGINT;
  BEGIN (* Int64 division *)
    IF p.S = 0 THEN clzd := SYSTEM.VAL(INTEGER, p.D) DIV SYSTEM.VAL(INTEGER, p.S) (* force DIVBYZERO exception*)
    ELSE neg := {};
      IF p.S < 0 THEN p.S := -p.S; neg := {0} END;
      IF p.D < 0 THEN p.D := -p.D; neg := neg / {0, 1} END;
      clzd := CLZ(p.D); clzs :=  CLZ(p.S);
      IF (clzd >= 33) & (clzs >= 33) THEN (*both D and S fit in INTEGER, we can use 32bit division*)
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
      END;
      IF 0 IN neg THEN p.S := -p.S END; (*negate quotient*)
      IF 1 IN neg THEN p.D := -p.D END (*negate remainder*)
    END
  END DivL;
END LongDiv.

OM4Tool.DecObj LongDiv.m4c
