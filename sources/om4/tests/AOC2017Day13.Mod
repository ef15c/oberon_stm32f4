MODULE AOC2017Day13;
  IMPORT Texts, Oberon, U := AOCUtils, Log := SystemLog;

  TYPE Layer = RECORD d, r: INTEGER END;

  VAR W: Texts.Writer;
    pm: INTEGER; map: ARRAY 2000 OF SET;
    F: ARRAY 50 OF Layer; nl: INTEGER;
    c: ARRAY 10 OF INTEGER; nc: INTEGER;

  PROCEDURE parse1(): INTEGER;
    VAR S!: Texts.Scanner;
      sev, de, r: INTEGER;
  BEGIN sev := 0;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    WHILE S.class = Texts.Int DO de := S.i; Texts.Scan(S);
      ASSERT((S.class = Texts.Char) & (S.c = ":")); Texts.Scan(S);
      ASSERT(S.class = Texts.Int); r := S.i; Texts.Scan(S);
      IF de MOD ((r-1)*2) = 0 THEN INC(sev, de*r) END
    END
    RETURN sev
  END parse1;

  PROCEDURE parse2;
    VAR S!: Texts.Scanner;
      de, r, nppcm, l: INTEGER;
  BEGIN pm := 1; CLEAR(map); U.Incl(map, 0); nl := 0;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    WHILE S.class = Texts.Int DO de := S.i; Texts.Scan(S);
      ASSERT((S.class = Texts.Char) & (S.c = ":")); Texts.Scan(S);
      ASSERT(S.class = Texts.Int); r := S.i; Texts.Scan(S);
      nppcm := U.ppcm(pm, (r-1)*2);
      IF nppcm DIV 32 < LEN(map) THEN l := pm;
        IF nppcm > pm THEN (*expand sieve*)
          WHILE pm < nppcm DO IF U.In(pm - l, map) THEN U.Incl(map, pm) END;
            INC(pm)
          END
        END;
        FOR l := 0 TO pm-1 DO IF (l + de) MOD ((r-1)*2) = 0 THEN U.Excl(map, l) END END
      ELSE (*store layer for delayed check*)
        F[nl].d := de; F[nl].r := r; INC(nl)
      END
    END
  END parse2;

  PROCEDURE part1*;
    VAR s: INTEGER;
  BEGIN s := parse1();
    Texts.WriteString(W, "Partie 1: severity = "); Texts.WriteInt(W, s, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;

  PROCEDURE part2*;
    VAR i, j, b: INTEGER; pass: BOOLEAN;
  BEGIN parse2;
     nc := 0; FOR i := 0 TO pm-1 DO IF U.In(i, map) THEN c[nc] := i; INC(nc) END END;
    b := 0; pass := FALSE;
    WHILE ~pass DO i := 0;
      WHILE ~pass & (i < nc) DO
        pass := TRUE; j := 0;
        WHILE pass & (j < nl) DO pass := (b + c[i] + F[j].d) MOD ((F[j].r-1)*2) # 0;
          INC(j)
        END;
        IF ~pass THEN INC(i) END
      END;
      IF ~pass THEN INC(b, pm) END
    END;
    Texts.WriteString(W, "Partie 2: delay = "); Texts.WriteInt(W, b + c[i], 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part2;

BEGIN Texts.OpenWriter(W)
END AOC2017Day13.

Oberon.Batch
  OM4P.Compile AOC2017Day13.Mod/s~
  System.Free AOC2017Day13 AOCUtils~
~

R=1: 
R=2: 01
R=3: 0121
R=4: 012321
R=5: 01234321
Period(R) = (R-1)*2
Catch every (delay + depth) MOD ((R-1)*2) = 0

Delay=0
------
0: 3 | 0 MOD 4 = 0 => catch
1: 2 | 1 MOD 2 = 1 => no catch
4: 4 | 4 MOD 6 = 4 => no catch
6: 4 | 6 MOD 6 = 0 => catch

Part 2, Delay = d
-----
0: 3 | d MOD 4 # 0   =>      d = {1, 2, 3} + 4*k0
1: 2 | (d+1) MOD 2 # 0 => d = 2*k1 => d = 2 + 4*k0 => {2, 6, 10} + 12*k2
4: 4 | (d+4) MOD 6 # 0 d = {0, 1, 3, 4, 5} + 6*k2 => {0, 1, 3, 4, 5, 6, 7, 9, 10, 11} + 12*k2 => {6, 10} + 12*k2
6: 4 | (d+6) MOD 6 # 0 d = {1, 3, 4, 5) => {1, 3, 4, 5, 7, 9, 10, 11} => 10+12*k2

Partie 1: severity = 24
AOC2017Day13.part1
Partie 2: delay = 10
AOC2017Day13.part2
0: 3
1: 2
4: 4
6: 4
~

Part 2, Delay = d
-----
0: 3 | d MOD 4 # 0   =>      d = {1, 2, 3} + 4*k0
1: 2 | (d+1) MOD 2 # 0 => d = 2*k1 => d = 2 + 4*k0 => {2, 6, 10} + 12*k2

2: 4 | (d+2) MOD 6 # 0 => d = {0, 1, 2, 3, 5} + 6*k2
4: 4 | (d+4) MOD 6 # 0 => d = {0, 1, 3, 5} + 6*k2 => {0, 1, 3, 5, 6, 7, 9, 11} + 12*k2

       | 6 + 12*k2
6: 5
8: 6

Partie 1: severity = 2164
AOC2017Day13.part1
Partie 2: delay = 3861798
AOC2017Day13.part2
0: 3
1: 2
2: 4
4: 4
6: 5
8: 6
10: 6
12: 8
14: 6
16: 6
18: 9
20: 8
22: 8
24: 8
26: 12
28: 8
30: 12
32: 12
34: 12
36: 10
38: 14
40: 12
42: 10
44: 8
46: 12
48: 14
50: 12
52: 14
54: 14
56: 14
58: 12
62: 14
64: 12
66: 12
68: 14
70: 14
72: 14
74: 17
76: 14
78: 18
84: 14
90: 20
92: 14
~
