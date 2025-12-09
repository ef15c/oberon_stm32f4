MODULE AOCUtils;
  IMPORT Texts, L := SystemLog;

  CONST LONG_MAX* = LSL(1L, 63) - 1; BYTE_MAX* = LSL(1, 8);

  TYPE Vector* = RECORD x*, y*, param*: INTEGER END;
    Vec3* = RECORD x*, y*, z*: INTEGER END;
    List* = POINTER TO ListDesc;
    ListDesc* = RECORD n*: LONGINT; next*: List END;

  VAR DIRECTION4*: ARRAY 4 OF Vector;

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

  PROCEDURE toString*(x: LONGINT; VAR s: ARRAY OF CHAR);
    VAR i, j, l: INTEGER; c: CHAR;
  BEGIN ASSERT(x >= 0);
    l := 0;
    REPEAT s[l] := CHR(ORD("0") + x MOD 10); x := x DIV 10; INC(l) UNTIL x = 0; s[l] := 0X;
    i := 0; j := l - 1; WHILE i < j DO c := s[i]; s[i] := s[j]; s[j] := c; INC(i); DEC(j) END; (*reverse digits*)
  END toString;

  PROCEDURE dist32*(a, b: Vec3): LONGINT;
    VAR dx, dy, dz: LONGINT;
  BEGIN dx := a.x - b.x; dy := a.y - b.y; dz := a.z - b.z;

    RETURN dx*dx + dy*dy + dz*dz
  END dist32;

  PROCEDURE sort*(VAR h: List);
    VAR max: LONGINT; r!, p!, q!, t!: List;
  BEGIN r := h; t := NIL;
    WHILE r # NIL DO max := r.n; p := NIL; q := r;
      WHILE q.next # NIL DO
        IF q.next.n > max THEN max := q.next.n; p := q END;
        q := q.next
      END;
      IF p # NIL THEN q := p.next; p.next := q.next ELSE q := r; r := r.next END; (*remove q from original list*)
      q.next := NIL;
      IF t = NIL THEN h := q; t := h ELSE t.next := q; t := q END (*append q to the destination list*)
    END
  END sort;

  PROCEDURE cmpVector(a, b: Vector; col: INTEGER): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN
    IF col = 1 THEN res := (a.x < b.x) OR ((a.x = b.x) & (a.y < b.y)) (*sort by x then y*)
    ELSIF col = 2 THEN res := (a.y < b.y) OR ((a.y = b.y) & (a.x < b.x)) (*sort by y then x*)
    ELSE res := a.param < b.param
    END

    RETURN res
  END cmpVector;

  PROCEDURE doVectorSort(VAR a: ARRAY OF Vector; col: INTEGER; L, R: INTEGER);
    VAR i, j: INTEGER; w, x: Vector;
  BEGIN
    i := L; j := R;
    x := a[(L+R) DIV 2];
    REPEAT
      WHILE cmpVector(a[i], x, col) DO i := i+1 END;
      WHILE cmpVector(x, a[j], col) DO j := j-1 END;
      IF i <= j THEN
        w := a[i]; a[i] := a[j]; a[j] := w;
        i := i+1; j := j-1
      END
    UNTIL i > j;
    IF L < j THEN doVectorSort(a, col, L, j) END;
    IF i < R THEN doVectorSort(a, col, i, R) END
  END doVectorSort;

  PROCEDURE VectorSort*(VAR a: ARRAY OF Vector; col: INTEGER; n: INTEGER);
  BEGIN IF n = 0 THEN n := LEN(a) END;
    doVectorSort(a, col, 0, n - 1)
  END VectorSort;

BEGIN DIRECTION4[0].x := 0; DIRECTION4[0].y := -1;
  DIRECTION4[1].x := 1; DIRECTION4[1].y := 0;
  DIRECTION4[2].x := 0; DIRECTION4[2].y := 1;
  DIRECTION4[3].x := -1; DIRECTION4[3].y := 0;
END AOCUtils.
