MODULE AOC2017Day17;
  IMPORT Texts, Oberon, U := AOCUtils, Log := SystemLog;

  VAR W: Texts.Writer;
(*    ring: ARRAY 2018 OF INTEGER;*)

  PROCEDURE parse(VAR step: INTEGER);
    VAR S!: Texts.Scanner; c: CHAR;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    ASSERT(S.class = Texts.Int); step := S.i
  END parse;

(*
  PROCEDURE part1*;
    VAR nb, step, p, i: INTEGER;
  BEGIN ring[0] := 0; nb := 1; p := 0;
    parse(step);
    REPEAT INC(p, step); p := (p + 1) MOD nb;
      FOR i := nb - 1 TO p BY -1 DO ring[i+1] := ring[i] END; ring[p + 1] := nb;
      INC(nb)
    UNTIL nb = 2018;
    INC(p, 2); IF p >= 2018 THEN DEC(p, 2018) END;
    Texts.WriteString(W, "Partie 1: number after last insertion = "); Texts.WriteInt(W, ring[p], 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;
*)

  PROCEDURE part2*;
    VAR nb, step, p, i: INTEGER;
  BEGIN nb := 1; p := 0;
    parse(step);
    REPEAT INC(p, step); p := (p + 1) MOD nb;
      INC(nb);
      IF p = 0 THEN
        Texts.WriteString(W, "nb = "); Texts.WriteInt(W, nb, 1);
        Texts.WriteString(W, ", va0 = "); Texts.WriteInt(W, nb - 1, 1);
        Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
      END
    UNTIL nb = 50000000
  END part2;

BEGIN Texts.OpenWriter(W)
END AOC2017Day17.

Oberon.Batch
  OM4P.Compile AOC2017Day17.Mod/s~
  System.Free AOC2017Day17 AOCUtils~
~

Partie 1: number after last insertion = 638
AOC2017Day17.part1
3
~

Partie 1: number after last insertion = 1244
AOC2017Day17.part1
370
~

AOC2017Day17.part2
3
~

nb = 2, va0 = 1
nb = 4, va0 = 3
nb = 247, va0 = 246
nb = 559, va0 = 558
nb = 738, va0 = 737
nb = 746, va0 = 745
nb = 831, va0 = 830
nb = 1158, va0 = 1157
nb = 7100, va0 = 7099
nb = 15955, va0 = 15954
nb = 96026, va0 = 96025
nb = 190600, va0 = 190599
nb = 307326, va0 = 307325
nb = 2564109, va0 = 2564108
nb = 3602731, va0 = 3602730
nb = 7074214, va0 = 7074213
nb = 11162913, va0 = 11162912
AOC2017Day17.part2
370
~

OM4L.LinkEF System AOC2017Day17~
OM4X.LoadEF AOC2017Day17.efb OM4L.CompareEF AOC2017Day17.efb
