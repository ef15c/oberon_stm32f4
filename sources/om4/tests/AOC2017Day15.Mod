MODULE AOC2017Day15;
  IMPORT Texts, Oberon, U := AOCUtils, Log := SystemLog;

  TYPE Layer = RECORD d, r: INTEGER END;

  VAR W: Texts.Writer;

  PROCEDURE parse(VAR sva, svb: LONGINT);
    VAR S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S); ASSERT(S.class = Texts.Int); sva := S.i;
    Texts.Scan(S); ASSERT(S.class = Texts.Int); svb := S.i
  END parse;

  PROCEDURE part1*;
    VAR va, vb: LONGINT; i, c: INTEGER;
  BEGIN parse(va, vb); c := 0;
    Log.DebugInt("va", va, 1); Log.DebugInt("vb", vb, 1);
    FOR i := 1 TO 40*1000000 DO LED(i DIV 200000H);
      va := va*16807 MOD 07FFFFFFFH; vb := vb*48271 MOD 07FFFFFFFH;
      IF va MOD 10000H = vb MOD 10000H THEN INC(c) END
    END;
    Texts.WriteString(W, "Partie 1: judge final count = "); Texts.WriteInt(W, c, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;

  PROCEDURE part2*;
    VAR va, vb: LONGINT; i, c: INTEGER;
  BEGIN parse(va, vb); c := 0;
    Log.DebugInt("va", va, 1); Log.DebugInt("vb", vb, 1);
    FOR i := 1 TO 5*1000000 DO LED(i DIV 80000H);
      REPEAT va := va*16807 MOD 07FFFFFFFH UNTIL va MOD 4 = 0;
      REPEAT vb := vb*48271 MOD 07FFFFFFFH UNTIL vb MOD 8 = 0;
      IF va MOD 10000H = vb MOD 10000H THEN INC(c) END
    END;
    Texts.WriteString(W, "Partie 2: judge final count = "); Texts.WriteInt(W, c, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part2;

BEGIN Texts.OpenWriter(W)
END AOC2017Day15.

Oberon.Batch
  OM4P.Compile AOC2017Day15.Mod/s~
  System.Free AOC2017Day15 AOCUtils~
~

Partie 1: judge final count = 588
AOC2017Day15.part1
65 8921
~

Partie 1: judge final count = 597
AOC2017Day15.part1
516 190
~

Partie 2: judge final count = 309
AOC2017Day15.part2
65 8921
~

Partie 2: judge final count = 303
AOC2017Day15.part2
516 190
~

OM4L.LinkEF System AOC2017Day15~
OM4X.LoadEF AOC2017Day15.efb OM4L.CompareEF AOC2017Day15.efb
