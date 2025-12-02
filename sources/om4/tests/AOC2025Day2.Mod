MODULE AOC2025Day2;
  IMPORT Texts, Oberon, U := AOCUtils, L := SystemLog;

  TYPE ProcessProc = PROCEDURE(a, b: LONGINT);

  VAR W: Texts.Writer;
    n, n128, next, sum: LONGINT;
    pc: INTEGER;

  PROCEDURE parse(process: ProcessProc);
    VAR S!: Texts.Scanner; a, b: LONGINT;
  BEGIN 
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); (*"a"*)
    WHILE S.class = Texts.Int DO a := S.i; Texts.Scan(S); (*"-b"*)
      ASSERT(S.class = Texts.Int); b := S.i; Texts.Scan(S); (*","*)
      ASSERT(b <= 0); b := -b;
      ASSERT((S.class = Texts.Char) & ((S.c = ",") OR(S.c = "~"))); Texts.Scan(S); (*"a"*)
      process(a, b)
    END
  END parse;

  PROCEDURE doPart1(a, b: LONGINT);
    VAR id: LONGINT; st: ARRAY 25 OF CHAR;
      i, ml: INTEGER;
  BEGIN
    FOR id := a TO b DO U.toString(id, st); ml := U.strlen(st);
      IF ~ODD(ml) THEN ml := ml DIV 2;
        i := 0; WHILE (i < ml) & (st[i] = st[i + ml]) DO INC(i) END;
        IF (i >= ml) THEN INC(sum, id) END
      END;
      DEC(n); IF n < next THEN INC(pc); LED(pc); next := n - n128 END
    END
  END doPart1;

  PROCEDURE doPart2(a, b: LONGINT);
    VAR id: LONGINT; st: ARRAY 25 OF CHAR;
      i, j, ml: INTEGER; illegal: BOOLEAN;
  BEGIN
    FOR id := a TO b DO U.toString(id, st); ml := U.strlen(st);
      i := 1; illegal := FALSE;
      WHILE ~illegal & (i <= ml DIV 2) DO
        IF ml MOD i = 0 THEN j := 0;
          WHILE (j < ml - i) & (st[j] = st[j + i]) DO INC(j) END;
          IF j >= ml - i THEN illegal := TRUE; INC(sum, id) END;
        END;
        INC(i)
      END;
      DEC(n); IF n < next THEN INC(pc); LED(pc); next := n - n128 END
    END
  END doPart2;

  PROCEDURE count(a, b: LONGINT);
  BEGIN INC(n, b - a + 1)
  END count;

  PROCEDURE part1*;
  BEGIN
    n := 0; parse(count);
    sum := 0; pc := 0; n128 := n DIV 128; next := n - n128; parse(doPart1);
    Texts.WriteString(W, "Partie 1: sum = "); Texts.WriteInt(W, sum, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;

  PROCEDURE part2*;
  BEGIN
    n := 0; parse(count);
    sum := 0; pc := 0; n128 := n DIV 128; next := n - n128; parse(doPart2);
    Texts.WriteString(W, "Partie 2: sum = "); Texts.WriteInt(W, sum, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part2;

BEGIN Texts.OpenWriter(W)
END AOC2025Day2.

OM4P.Compile AOC2025Day2.Mod/s~
System.Free AOC2025Day2 SystemLog AOCUtils~

Test data
AOC2025Day2.part1
AOC2025Day2.part2
11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
1698522-1698528,446443-446449,38593856-38593862,565653-565659,
824824821-824824827,2121212118-2121212124
~
Partie 1: sum = 1227775554
Partie 2: sum = 4174379265

Puzzle data
AOC2025Day2.part1
AOC2025Day2.part2
78847-119454,636-933,7143759788-7143793713,9960235-10043487,44480-68595,23468-43311,89-123,785189-1014654,3829443354-3829647366,647009-692765,2-20,30-42,120909-197026,5477469-5677783,9191900808-9191943802,1045643-1169377,46347154-46441299,2349460-2379599,719196-779497,483556-641804,265244-450847,210541-230207,195-275,75702340-75883143,58-84,2152-3237,3367-5895,1552-2029,9575-13844,6048-8966,419388311-419470147,936-1409,9292901468-9292987321
~
Partie 1: sum = 17077011375
Partie 2: sum = 36037497037
