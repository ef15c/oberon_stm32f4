MODULE Conv;

  PROCEDURE toHexa*(val: BYTE*): CHAR;
    VAR res: CHAR*;
  BEGIN
    IF val<10 THEN res := CHR(val + ORD("0"))
    ELSIF val<16 THEN res := CHR(val-10+ORD("A"))
    ELSE res := "?"
	END

    RETURN res
  END toHexa;

END Conv.
