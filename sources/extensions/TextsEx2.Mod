MODULE TextsEx2;
  IMPORT Texts;

  PROCEDURE WriteHexVLen*(VAR W: Texts.Writer; x, n: INTEGER; leadingZero: BOOLEAN);
    VAR i: INTEGER; y: INTEGER;
      a: ARRAY 10 OF CHAR;
  BEGIN ASSERT(n<=10);
    i := 0; Texts.Write(W, " ");
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END;
      x := x DIV 10H; IF x < 0 THEN INC(x, 10000000H) END; INC(i)
    UNTIL (i >= n) & (x = 0);
    IF leadingZero & (a[i-1] > "9") THEN Texts.Write(W, "0") END; (*Add a leading 0 if first hex digit is a letter*)
    REPEAT DEC(i); Texts.Write(W, a[i]) UNTIL i = 0
  END WriteHexVLen;

  PROCEDURE WriteLongInt*(VAR W: Texts.Writer; x: LONGINT; n: INTEGER);
    VAR i: INTEGER; x0: LONGINT;
      a: ARRAY 20 OF CHAR;
  BEGIN
    IF x = -x THEN Texts.WriteString(W, " -9223372036854775808")
    ELSE i := 0;
      IF x < 0 THEN DEC(n); x0 := -x ELSE x0 := x END;
      REPEAT
        a[i] := CHR(x0 MOD 10 + 30H); x0 := x0 DIV 10; INC(i)
      UNTIL x0 = 0;
      WHILE n > i DO Texts.Write(W, " "); DEC(n) END;
      IF x < 0 THEN Texts.Write(W, "-") END;
      REPEAT DEC(i); Texts.Write(W, a[i]) UNTIL i = 0
    END
  END WriteLongInt;

END TextsEx2.

OM4P2.Compile TextsEx2.Mod/s ~
