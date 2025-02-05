MODULE TextsEx;
  IMPORT Texts;

  CONST (*scanner symbol classes*)
    LongInt* = 7;

  TYPE
    Scanner* = RECORD(Texts.Scanner)
      l*: LONGINT
    END;

  PROCEDURE Scan* (VAR S: Scanner);
    CONST maxExp = 38; maxM = 16777216; (*2^24*)
    VAR ch: CHAR;
      neg, negE, hex: BOOLEAN;
      i, j, d, e, s: INTEGER; h, n: LONGINT;
      x: REAL;
  BEGIN ch := S.nextCh; i := 0;
    WHILE (ch = " ") OR (ch = Texts.TAB) OR (ch = Texts.CR) DO
      IF ch = Texts.CR THEN INC(S.line) END ;
      Texts.Read(S, ch)
    END ;
    IF ("A" <= ch) & (ch <= "Z") OR ("a" <= ch) & (ch <= "z") THEN (*name*)
      REPEAT S.s[i] := ch; INC(i); Texts.Read(S, ch)
      UNTIL ((ch # "_") & ((ch < "0") & (ch # ".") OR ("9" < ch) & (ch < "A") OR ("Z" < ch) & (ch < "a") OR ("z" < ch))) OR (i = 31);
      S.s[i] := 0X; S.len := i; S.class := Texts.Name
    ELSIF ch = 22X THEN (*string*)
      Texts.Read(S, ch);
      WHILE (ch # 22X) & (ch >= " ") & (i # 31) DO S.s[i] := ch; INC(i); Texts.Read(S, ch) END;
      S.s[i] := 0X; S.len := i+1; Texts.Read(S, ch); S.class := Texts.String
    ELSE hex := FALSE;
      IF ch = "-" THEN neg := TRUE; Texts.Read(S, ch) ELSE neg := FALSE END ;
      IF ("0" <= ch) & (ch <= "9") THEN (*number*)
        n := ORD(ch) - 30H; h := n; Texts.Read(S, ch);
        WHILE ("0" <= ch) & (ch <= "9") OR ("A" <= ch) & (ch <= "F") DO
          IF ch <= "9" THEN d := ORD(ch) - 30H ELSE d := ORD(ch) - 37H; hex := TRUE END ;
          n := n*10 + d; h := h*10H + d; Texts.Read(S, ch)
        END ;
        IF ch = "H" THEN (*hex integer*) Texts.Read(S, ch);
          IF LSR(h, 32) = 0 THEN S.i := h; S.class := Texts.Int  (*neg?*) ELSE S.l := h; S.class := LongInt END
        ELSIF ch = "." THEN (*real number*)
          Texts.Read(S, ch); x := 0.0; e := 0; j := 0;
          WHILE ("0" <= ch) & (ch <= "9") DO  (*fraction*)
            h := n*10 + (ORD(ch) - 30H);
            IF h < maxM THEN n := h; INC(j) END ;
            Texts.Read(S, ch)
          END ;
          IF ch = "E" THEN (*scale factor*)
            s := 0; Texts.Read(S, ch);
            IF ch = "-" THEN negE := TRUE; Texts.Read(S, ch)
            ELSE negE := FALSE;
              IF ch = "+" THEN Texts.Read(S, ch) END
            END ;
            WHILE ("0" <= ch) & (ch <= "9") DO
              s := s*10 + ORD(ch) - 30H; Texts.Read(S, ch)
            END ;
            IF negE THEN DEC(e, s) ELSE INC(e, s) END ;
          END ;
          x := FLT(n); DEC(e, j);
          IF e < 0 THEN
            IF e >= -maxExp THEN x := x / Texts.Ten(-e) ELSE x := 0.0 END
          ELSIF e > 0 THEN
            IF e <= maxExp THEN x := Texts.Ten(e) * x ELSE x := 0.0 END
          END ;
          IF neg THEN S.x := -x ELSE S.x := x END ;
          IF hex THEN S.class := 0 ELSE S.class := Texts.Real END
        ELSIF ch = "L" THEN (*long integer*) Texts.Read(S, ch); S.class := LongInt;
          IF neg THEN S.l := -n ELSE S.l := n END
        ELSE (*decimal integer*)
          IF neg THEN n := -n END;
          IF (n >= -LSL(1, 31)) & (n < LSL(1, 31)) THEN S.class := Texts.Int; S.i := n 
          ELSE S.class := LongInt; S.l := n
          END;
          IF hex THEN S.class := Texts.Inval END
        END
      ELSE (*special character*) S.class := Texts.Char;
        IF neg THEN S.c := "-" ELSE S.c := ch; Texts.Read(S, ch) END
      END
    END ;
    S.nextCh := ch
  END Scan;

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
    IF (x < 0) & (-x < 0) THEN Texts.WriteString(W, " -9223372036854775808")
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

END TextsEx.
