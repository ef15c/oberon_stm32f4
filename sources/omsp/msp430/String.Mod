MODULE String; (*provides some character string operations*)
  IMPORT Arith, MP := MultiPrecisionArith;

  PROCEDURE FromLong*(th, tl, nbc: INTEGER; VAR str: ARRAY OF CHAR);
    VAR dh, dl: INTEGER;
  BEGIN str[nbc] := 0X; DEC(nbc );
    REPEAT dh := 0; dl := 10; MP.DivLongLong(th, tl, dh, dl); (*d : = t%10; t /= 10;*)
      str[nbc] := CHR(dl + ORD("0"));
      DEC(nbc)
    UNTIL (nbc < 0) OR (th = 0) OR (tl = 0);
    WHILE nbc >= 0 DO str[nbc] := " "; DEC(nbc) END
  END FromLong;

  PROCEDURE FromInteger*(t, nbc: INTEGER; VAR str: ARRAY OF CHAR);
    VAR d: INTEGER; neg: BOOLEAN;
  BEGIN str[nbc] := 0X; DEC(nbc ); IF t < 0 THEN neg := TRUE; t := -t ELSE neg := FALSE END;
    REPEAT d :=  t MOD 10; t := t DIV 10;
      str[nbc] := CHR(d + ORD("0"));
      DEC(nbc)
    UNTIL (nbc < 0) OR (t = 0);
    IF neg & (nbc >= 0) THEN str[nbc] := "-"; DEC(nbc) END;
    WHILE nbc >= 0 DO str[nbc] := " "; DEC(nbc) END
  END FromInteger;

END String.
