MODULE AOC2017Day14;
  IMPORT Texts, Oberon, U := AOCUtils, A10 := AOC2017Day10, Log := SystemLog;

  TYPE Layer = RECORD d, r: INTEGER END;

  VAR W: Texts.Writer;
    pm: INTEGER; map: ARRAY 2000 OF SET;
    F: ARRAY 50 OF Layer; nl: INTEGER;
    c: ARRAY 10 OF INTEGER; nc: INTEGER;
    reg: ARRAY 128, 128 OF INTEGER;

  PROCEDURE parse(VAR s: ARRAY OF CHAR);
    VAR S!: Texts.Scanner;

    PROCEDURE Copy(s: ARRAY OF CHAR; VAR d: ARRAY OF CHAR);
      VAR i: INTEGER;
    BEGIN i := 0; WHILE s[i] # 0X DO d[i] := s[i]; INC(i) END;
      d[i] := "-"; INC(i); d[i] := 0X
    END Copy;

  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    ASSERT(S.class = Texts.Name); Copy(S.s, s)
  END parse;

  PROCEDURE part1*;
    VAR s, si: ARRAY 32 OF CHAR;
      i, j: INTEGER; h: A10.Hash;
      nbs: INTEGER; d: BYTE;
  BEGIN parse(s); nbs := 0;
    FOR i := 0 TO 127 DO LED(i); si := s; U.AppendIntToString(si, i);
      A10.HashString(si, h);
      FOR j := 0 TO 15 DO d := h[j];
        WHILE d # 0 DO IF ODD(d) THEN INC(nbs) END; d := LSR(d, 1) END
      END
    END;
    Texts.WriteString(W, "Partie 1: nb used squares = "); Texts.WriteInt(W, nbs, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;

  PROCEDURE part2*;
    VAR s, si: ARRAY 32 OF CHAR;
      map: ARRAY 128 OF A10.Hash;
      nr, i, j: INTEGER;

    PROCEDURE paint(map: ARRAY OF A10.Hash; g: INTEGER);
      VAR i, j: INTEGER; done: BOOLEAN;

      PROCEDURE check(i, j, g: INTEGER): BOOLEAN;
        VAR r: BOOLEAN;
      BEGIN r := FALSE;
        IF (i >= 0) & (i < 128) & (j >= 0) & (j < 128) THEN
          IF reg[i, j] = g THEN r := TRUE ELSE ASSERT(reg[i, j] = 0) END
        END
        RETURN r
      END check;

    BEGIN
      REPEAT done := TRUE;
        FOR i := 0 TO 127 DO
          FOR j := 0 TO 127 DO
            IF (reg[i, j] = 0) & ((7 - j MOD 8) IN TOSET(map[i, j DIV 8])) THEN
              (*see if at least one of the 4 neighbours is in group g*)
              IF check(i-1, j, g) OR check(i, j+1, g) OR check(i+1, j, g) OR check(i, j-1, g) THEN
                done := FALSE; reg[i, j] := g; (*add square to group g*)
              END
            END
          END
        END
      UNTIL done
    END paint;

  BEGIN CLEAR(reg); parse(s);
    FOR i := 0 TO 127 DO LED(i); si := s; U.AppendIntToString(si, i);
      A10.HashString(si, map[i])
    END; nr := 0;
    FOR i := 0 TO 127 DO
      FOR j := 0 TO 127 DO
        IF (reg[i, j] = 0) & ((7 - j MOD 8) IN TOSET(map[i, j DIV 8])) THEN
          INC(nr); LED(nr); reg[i, j] := nr; paint(map, nr)
        END
      END
    END;
    Texts.WriteString(W, "Partie 2: nb of regions = "); Texts.WriteInt(W, nr, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part2;

BEGIN Texts.OpenWriter(W)
END AOC2017Day14.

Oberon.Batch
  OM4P.Compile AOC2017Day14.Mod/s~
  System.Free AOC2017Day14 AOCUtils~
~

Partie 1: nb used squares = 8108
AOC2017Day14.part1
flqrgnkx
~

Partie 2: nb of regions = 1242
AOC2017Day14.part2
flqrgnkx
~

Partie 1: nb used squares = 8316
AOC2017Day14.part1
ljoxqyyw
~

Partie 2: nb of regions = 1074
AOC2017Day14.part2
ljoxqyyw
~
