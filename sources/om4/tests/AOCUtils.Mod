MODULE AOCUtils;
  IMPORT Texts;

  CONST LONG_MAX* = LSL(1L, 63) - 1; BYTE_MAX* = LSL(1, 8);

  TYPE Vector* = RECORD x*, y*: INTEGER END;
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

  PROCEDURE abs*(a: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN IF a > 0 THEN r := a ELSE r := -a END

    RETURN r
  END abs;

  PROCEDURE pgcd*(a, b: INTEGER): INTEGER;
    VAR r: INTEGER;
  BEGIN
    WHILE b # 0 DO r := a MOD b; a := b; b := r END
    RETURN a
  END pgcd;

  PROCEDURE ppcm*(a, b: INTEGER): INTEGER;
  BEGIN
    RETURN a DIV pgcd(a, b)*b
  END ppcm;

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

  PROCEDURE rotQ*(w, h, x, y: INTEGER; VAR rx, ry: INTEGER);
  BEGIN ASSERT((x >= 0) & (x < w)); ASSERT((y >= 0) & (y < h));
    ry := x; rx := h - y - 1;
  END rotQ;

(*map operations*)
  PROCEDURE Incl*(VAR m: ARRAY OF SET; e: INTEGER);
  BEGIN INCL(m[e DIV 32], e MOD 32)
  END Incl;

  PROCEDURE Excl*(VAR m: ARRAY OF SET; e: INTEGER);
  BEGIN EXCL(m[e DIV 32], e MOD 32)
  END Excl;

  PROCEDURE In*(e: INTEGER; m: ARRAY OF SET): BOOLEAN;
    RETURN e MOD 32 IN m[e DIV 32]
  END In;

  PROCEDURE Card*(m: ARRAY OF SET): INTEGER;
    VAR c, i: INTEGER;
  BEGIN c := 0;
    FOR i := 0 TO LEN(m)*32 - 1 DO IF i IN m[i DIV 32] THEN INC(c) END END;
    RETURN c
  END Card;

BEGIN DIRECTION4[0].x := 0; DIRECTION4[0].y := -1;
  DIRECTION4[1].x := 1; DIRECTION4[1].y := 0;
  DIRECTION4[2].x := 0; DIRECTION4[2].y := 1;
  DIRECTION4[3].x := -1; DIRECTION4[3].y := 0;
END AOCUtils.

Oberon.Batch
  OM4P.Compile AOCUtils.Mod/s~
  System.Free AOCUtils~
~

OM4Tool.DecSym AOCUtils.sm4
decode AOCUtils.sm4
AOCUtils 277EEE4C  2
   1 LONG_MAX [^14]-301989889
   1 BYTE_MAX [^4]     256
   5 Vector [18  form = 13 [^9]  exno = 1  extlev = 0  size = 8 { y [^4]   4 x [^4]   0}]()
   5 Vec3 [19  form = 13 [^9]  exno = 2  extlev = 0  size = 12 { z [^4]   8 y [^4]   4 x [^4]   0}]()
   5 List [20  form = 7 [21  form = 13 [^9]  exno = 3  extlev = 0  size = 12 { next [^20]   8 n [^14]   0}]]()
   5 ListDesc [^21]( ->  20)
   2 DIRECTION4 [0  form = 12 [^18]  len = 4  size = 32]     4
   1 ilog10 [0  form = 10 [^4] ur = 4 ( class = 2 [^14])]       5
   1 strlen [0  form = 10 [^4] ur = 4 ( class = 3# [0  form = 12 [^3]  len = -1  size = 8])]       6
   1 strncmp [0  form = 10 [^4] ur = 4 ( class = 2 [^4] class = 3# [0  form = 12 [^3]  len = -1  size = 8] class = 3# [0  form = 12 [^3]  len = -1  size = 8])]       7
   1 CopyString [0  form = 10 [^9] ur = 4 ( class = 2 [^4] class = 3# [0  form = 12 [^3]  len = -1  size = 8] class = 3 [0  form = 12 [^3]  len = -1  size = 8])]       8
   1 manhattan [0  form = 10 [^4] ur = 4 ( class = 3# [^18] class = 3# [^18])]       9
   1 printVector [0  form = 10 [^9] ur = 5 ( class = 3# [^18] class = 3 [22  form = 13 [^9]  exno = 0  extlev = 0  size = 40 { --  36 --  24 voff [^4]  12 col [^4]   8 fnt [23  form = 7 [24  form = 13 [^9]  exno = 0  extlev = 0  size = 21560 { next [^23]  52 maxY [^4]  48 minY [^4]  44 maxX [^4]  40 minX [^4]  36 height [^4]  32 name [0  form = 12 [^3]  len = 32  size = 32]   0} Fonts.FontDesc 3D79EC98] Fonts.Font 3D79EC98]   4 buf [25  form = 7 [26  form = 13 [^9]  exno = 0  extlev = 0  size = 12 { --   8 --   4 len [^4]   0} Texts.BufDesc DADDC136] Texts.Buffer DADDC136]   0} Texts.Writer DADDC136])]      10
   1 min [0  form = 10 [^4] ur = 4 ( class = 2 [^4] class = 2 [^4])]      11
   1 max [0  form = 10 [^4] ur = 4 ( class = 2 [^4] class = 2 [^4])]      12
   1 abs [0  form = 10 [^4] ur = 4 ( class = 2 [^4])]      13
   1 toIntOfs [0  form = 10 [^4] ur = 4 ( class = 2 [^4] class = 3# [0  form = 12 [^3]  len = -1  size = 8])]      14
   1 toInt [0  form = 10 [^4] ur = 4 ( class = 3# [0  form = 12 [^3]  len = -1  size = 8])]      15
   1 toString [0  form = 10 [^9] ur = 4 ( class = 3 [0  form = 12 [^3]  len = -1  size = 8] class = 2 [^14])]      16
   1 dist32 [0  form = 10 [^14] ur = 8 ( class = 3# [^19] class = 3# [^19])]      17
   1 sort [0  form = 10 [^9] ur = 4 ( class = 3 [^20])]      18
   1 rotQ [0  form = 10 [^9] ur = 4 ( class = 3 [^4] class = 3 [^4] class = 2 [^4] class = 2 [^4] class = 2 [^4] class = 2 [^4])]      19
   1 Incl [0  form = 10 [^9] ur = 4 ( class = 2 [^4] class = 3 [0  form = 12 [^6]  len = -1  size = 8])]      20

