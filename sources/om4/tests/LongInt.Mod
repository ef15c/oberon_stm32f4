MODULE LongInt;
  IMPORT SYSTEM, Kernel, Texts, Oberon;

  TYPE DivParam = RECORD  D, S: LONGINT END;

  VAR f: Kernel.ExceptionFrameDesc;
    W: Texts.Writer;

  PROCEDURE WriteL(l: LONGINT);
    VAR low: INTEGER;
  BEGIN low := l; l := LSR(l, 32);
    Texts.WriteHex(W, l); Texts.WriteHex(W, low); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END WriteL;

  PROCEDURE Write(h, l: INTEGER);
    VAR low: INTEGER;
  BEGIN Texts.WriteHex(W, h); Texts.WriteHex(W, l); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END Write;

  PROCEDURE DivL(VAR p: DivParam);
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

  PROCEDURE run*;
    VAR t: LONGINT;
  BEGIN t := 1234567890; t := t*10000000; INC(t, 1234567);
    f.r1 := LSR(t, 32); f.r0 := t; f.r3 := 0; f.r2 := 10;
    DivL(SYSTEM.VAL(DivParam, f));
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, f.r0, 1); Texts.WriteLn(W);
    Write(f.r3, f.r2);

    f.r1 := f.r3; f.r0 := f.r2; f.r3 := 0; f.r2 := 1024;
    DivL(SYSTEM.VAL(DivParam, f));
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, f.r0, 1); Texts.WriteLn(W);
    Write(f.r3, f.r2);

    f.r1 := f.r3; f.r0 := f.r2; f.r3 := 0; f.r2 := 1;
    DivL(SYSTEM.VAL(DivParam, f));
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, f.r0, 1); Texts.WriteLn(W);
    Write(f.r3, f.r2);

    f.r1 := f.r3; f.r0 := f.r2;
    DivL(SYSTEM.VAL(DivParam, f));
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, f.r0, 1); Texts.WriteLn(W);
    Write(f.r3, f.r2);

    f.r1 := f.r3; f.r0 := f.r2; f.r3 := 0; f.r2 := 0;
    DivL(SYSTEM.VAL(DivParam, f));
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, f.r0, 1); Texts.WriteLn(W);
    Write(f.r3, f.r2);

    f.r1 := 0; f.r0 := 1; f.r3 := -1; f.r2 := -1;
    DivL(SYSTEM.VAL(DivParam, f));
    Texts.WriteString(W, "-----"); Texts.WriteLn(W);
    Texts.WriteInt(W, f.r0, 1); Texts.WriteLn(W);
    Write(f.r3, f.r2);

    t := t DIV 10; WriteL(t);

   Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W)
END LongInt.

OM4Tool.DecObj LongInt.m4c

-----
7
 000462D5 3C8ABAC0
-----
704
 00000118 B54F22AE
-----
0
 00000118 B54F22AE
-----
0
 00000000 00000001
-----
1
 00000000 00000000
-----
1
 FFFFFFFF FFFFFFFF
