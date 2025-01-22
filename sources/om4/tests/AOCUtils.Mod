MODULE AOCUtils;
  IMPORT Texts, TE := TextsEx2;

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

END AOCUtils.
