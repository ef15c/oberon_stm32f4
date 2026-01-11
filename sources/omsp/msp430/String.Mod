MODULE String; (*provides some character string operations*)
  IMPORT MP := MultiPrecisionArith;

  PROCEDURE FromLong*(th, tl, nbc: INTEGER; pad: CHAR; VAR str: ARRAY OF CHAR);
    VAR dh, dl: INTEGER; neg: BOOLEAN;
  BEGIN str[nbc] := 0X; DEC(nbc);
    neg := FALSE; IF th < 0 THEN MP.LongNegate(th, tl); neg := TRUE END;
    REPEAT dh := 0; dl := 10; MP.DivLongLong(th, tl, dh, dl); (*d : = t%10; t /= 10;*)
      str[nbc] := CHR(dl + ORD("0"));
      DEC(nbc)
    UNTIL (nbc < 0) OR (th = 0) & (tl = 0);
    IF neg & (nbc >= 0) THEN str[nbc] := "-"; DEC(nbc) END;
    WHILE nbc >= 0 DO str[nbc] := pad; DEC(nbc) END
  END FromLong;

  PROCEDURE FromInteger*(t, nbc: INTEGER; pad: CHAR; VAR str: ARRAY OF CHAR);
    VAR h: INTEGER;
  BEGIN h := 0;
    IF t < 0 THEN h := -1 END; FromLong(h, t, nbc, pad, str)
  END FromInteger;

END String.
