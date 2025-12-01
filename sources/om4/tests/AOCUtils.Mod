MODULE AOCUtils;
  IMPORT Texts, TE := TextsEx;

  CONST LONG_MAX* = LSL(1L, 63) - 1; BYTE_MAX* = LSL(1, 8);

  TYPE Vector* = RECORD x*, y*: INTEGER END;

  VAR DIRECTION4*: ARRAY 4 OF Vector;

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
    WHILE  (i < l) & (i < LEN(a)) & (i < LEN(b)) & (a[i] # 0X) & (a[i] = b[i]) DO INC(i) END;
    IF i = l THEN r := ORD(a[i-1]) - ORD(b[i-1])
    ELSIF (i < LEN(a)) & (i < LEN(b)) THEN r := ORD(a[i]) - ORD(b[i])
    ELSE r := LEN(a) - LEN(b) END

    RETURN r
  END strncmp;

  PROCEDURE CopyString*(VAR d: ARRAY OF CHAR; s: ARRAY OF CHAR; offset: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (offset + i  <  LEN(s)) & (i < LEN(d)) & (s[offset + i] # 0X) DO d[i] := s[offset + i]; INC(i) END;
    IF i < LEN(d) THEN d[i] := 0X END
  END CopyString;

  PROCEDURE manhattan*(p1, p2: Vector): INTEGER;
  (*Calculer la distance de manhattan entre deux points*)
    RETURN ABS(p1.x - p2.x) + ABS(p1.y - p2.y)
  END manhattan;

  PROCEDURE printVector*(VAR W: Texts.Writer; p: Vector);
  BEGIN Texts.Write(W, "("); Texts.WriteInt(W, p.x, 1); Texts.Write(W, ","); Texts.WriteInt(W, p.y, 1);Texts.Write(W, ")")
  END printVector;

  PROCEDURE min*(a, b: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN IF a < b THEN r := a ELSE r := b END

    RETURN r
  END min;

  PROCEDURE max*(a, b: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN IF a > b THEN r := a ELSE r := b END

    RETURN r
  END max;

  PROCEDURE toIntOfs*(c: ARRAY OF CHAR; i: INTEGER): INTEGER;
    VAR r: INTEGER; ch: CHAR;
  BEGIN r := 0;
    WHILE (i < LEN(c)) & (c[i] # 0X) DO ch := c[i];
      IF (ch >= "0") & (ch <= "9") THEN r := r*10; INC(r, ORD(ch) - ORD("0")) END;
      INC(i)
    END

    RETURN r
  END toIntOfs;

  PROCEDURE toInt*(c: ARRAY OF CHAR): INTEGER;
    RETURN  toIntOfs(c, 0)
  END toInt;

BEGIN DIRECTION4[0].x := 0; DIRECTION4[0].y := -1;
  DIRECTION4[1].x := 1; DIRECTION4[1].y := 0;
  DIRECTION4[2].x := 0; DIRECTION4[2].y := 1;
  DIRECTION4[3].x := -1; DIRECTION4[3].y := 0;
END AOCUtils.
