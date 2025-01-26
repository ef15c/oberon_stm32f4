MODULE AOCUtils;
  IMPORT Texts, TE := TextsEx2, L := SystemLog;

  PROCEDURE ReadL*(VAR S: TE.Scanner): LONGINT;
    VAR r: LONGINT;
  BEGIN IF S.class = Texts.Int THEN r := S.i ELSE ASSERT(S.class = TE.LongInt); r := S.l END; TE.Scan(S)
    RETURN r
  END ReadL;

  PROCEDURE ilog10*(x: LONGINT): INTEGER;
  (** Calculer le logarithme en base 10 d'un entier *)
    VAR r: INTEGER;
  BEGIN
    IF x <= 0 THEN  r := -1
    ELSE
      r := 0;
      WHILE x >= 10 DO INC(r); x := x DIV 10 END
    END

    RETURN r
  END ilog10;

  PROCEDURE strlen*(s: ARRAY OF CHAR): INTEGER;
    VAR r: INTEGER;
  BEGIN r := 0; WHILE (s[r] # 0X) & (r < LEN(s)) DO INC(r) END

    RETURN r
  END strlen;

  PROCEDURE strncmp*(a, b: ARRAY OF CHAR; l: INTEGER): INTEGER;
    VAR r, i: INTEGER;
  BEGIN i := 0; ASSERT(l > 0);
(*;L.DebugString("a", a); L.DebugString("b", b); L.DebugInt("l", l, 1);*)
    WHILE  (i < l) & (i < LEN(a)) & (i < LEN(b)) & (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END;
    IF i = l THEN r := ORD(a[i-1]) - ORD(b[i-1])
    ELSIF (i < LEN(a)) & (i < LEN(b)) THEN r := ORD(a[i]) - ORD(b[i])
    ELSE r := LEN(a) - LEN(b) END
(*; L.DebugInt("r", r, 1);*)

    RETURN r
  END strncmp;

  PROCEDURE CopyString*(VAR d: ARRAY OF CHAR; s: ARRAY OF CHAR; offset: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (offset + i  <  LEN(s)) & (i < LEN(d)) & (s[offset + i] # 0X) DO d[i] := s[offset + i]; INC(i) END;
    IF i < LEN(d) THEN d[i] := 0X END
  END CopyString;

END AOCUtils.
