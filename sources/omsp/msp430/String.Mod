MODULE String; (*provides some character string operations*)
  IMPORT MP := MultiPrecisionArith;

  PROCEDURE FromLong*(th, tl, nbc, len: INTEGER; VAR str: ARRAY OF CHAR);
    VAR dh, dl, i, j: INTEGER; neg: BOOLEAN; t: CHAR;
  BEGIN IF len >= LEN(str) THEN len := LEN(str) - 1 END;
    IF nbc > len THEN nbc := len END;
    i := 0; neg := FALSE; IF th < 0 THEN MP.LongNegate(th, tl); neg := TRUE; DEC(nbc) END;
    REPEAT dh := 0; dl := 10; MP.DivLongLong(th, tl, dh, dl); (*d : = t%10; t /= 10;*)
      str[i] := CHR(dl + ORD("0")); INC(i)
    UNTIL (i >= nbc) & (th = 0) & (tl = 0);
    IF neg THEN str[i] := "-"; INC(i) END;
    WHILE i < len DO str[i] := " "; INC(i) END;
    str[i] := 0X; DEC(i); j := 0;
    WHILE j < i DO t := str[i]; str[i] := str[j]; str[j] := t; DEC(i); INC(j) END
  END FromLong;

  PROCEDURE FromInteger*(t, nbc, len: INTEGER; VAR str: ARRAY OF CHAR);
    VAR h: INTEGER;
  BEGIN h := 0;
    IF t < 0 THEN h := -1 END; FromLong(h, t, nbc, len, str)
  END FromInteger;

END String.

OMSPTool.DecObj String.mpc
