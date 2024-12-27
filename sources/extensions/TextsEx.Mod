MODULE TextsEx;
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

END TextsEx.
