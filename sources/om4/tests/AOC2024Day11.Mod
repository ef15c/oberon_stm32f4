MODULE AOC2024Day11;
  IMPORT Texts, TE := TextsEx, Oberon, System, UT := UTHash, U := AOCUtils;

  TYPE
    StoneDesc = RECORD(UT.LongintHashDesc)
       next: ARRAY 2 OF LONGINT;
       nbNext: INTEGER;
       count: LONGINT
    END;
    Stone = POINTER TO StoneDesc;

  VAR W: Texts.Writer;
    freelist: Stone;


  PROCEDURE split(n: LONGINT; VAR nl, nr: LONGINT; nbd: INTEGER);
    VAR i, m: INTEGER;
  BEGIN
 ASSERT(nbd > 0); ASSERT(nbd < 20);
 nr := 0; m := 1;
    FOR i := 0 TO nbd - 1 DO INC(nr, n MOD 10*m); m := m*10; n := n DIV 10 END;
    nl := n
  END split;

  PROCEDURE addStone(VAR sto: Stone; s: Stone);
    VAR l!: UT.LongintHash;
  BEGIN l := UT.ADD_LONGINT(sto, s); sto := l(Stone)
  END addStone;

  PROCEDURE add(VAR sto: Stone; id: LONGINT; nb: LONGINT);
    VAR s!: UT.LongintHash; (*Stone*) fl!: UT.Hash;
  BEGIN s := UT.FIND_LONGINT(sto, id);
    CASE s OF
      Stone:
          IF s = NIL THEN 
            IF freelist = NIL THEN NEW(s) ELSE s := freelist; fl := UT.NEXT(freelist); freelist := fl(Stone) END;
            s.key := id; s.count := nb;
            IF id = 0 THEN (* r\E8gle 1 *) s.next[0] := 1; s.nbNext := 1
            ELSIF (U.ilog10(id)+1) MOD 2 = 0 THEN (* r\E8gle 2 *)
              split(id, s.next[0], s.next[1], (U.ilog10(id)+1) DIV 2); s.nbNext := 2
            ELSE (* r\E8gle 3 *) s.next[0] := id*2024; s.nbNext := 1
            END; addStone(sto, s);
         ELSE INC(s.count, nb)
         END
       | UT.LongintHash: ASSERT(FALSE) (* must be a stone *)
     END
  END add;

  PROCEDURE blink(VAR stones: Stone);
    VAR s!, nexts!: Stone; j: INTEGER; n!, t!: UT.Hash;
  BEGIN nexts := NIL; s := stones;
    WHILE s # NIL DO n := UT.NEXT(s);
      FOR j := 0 TO s.nbNext - 1 DO add(nexts, s.next[j], s.count) END;
      t := UT.DELETE(stones, s); stones := t(Stone);
      t := UT.FREE(freelist, s); freelist := t(Stone); (*put s in free list for future reuse*)
      s := n(Stone)
    END;
    stones := nexts
  END blink;

  PROCEDURE print(sto: Stone);
    VAR n!: UT.Hash;
  BEGIN
    WHILE sto # NIL DO
     IF sto.count # 0 THEN TE.WriteLongInt(W, sto.key, 1);
       Texts.Write(W, ":"); TE.WriteLongInt(W, sto.count, 1); Texts.Write(W, " ") END;
      n := UT.NEXT(sto); sto := n(Stone) END;
    Texts.WriteLn(W);
  END print;

  PROCEDURE run*;
    VAR stones!, s!: Stone; n!: UT.Hash; S!: TE.Scanner; id, ns: LONGINT; i: INTEGER; nofBlinks: INTEGER;
  BEGIN stones := NIL; Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); TE.Scan(S);
    nofBlinks := U.ReadL(S);
    WHILE S.class IN {Texts.Int, TE.LongInt} DO id := U.ReadL(S); add(stones, id, 1) END;
    FOR i := 1 TO nofBlinks DO blink(stones); LED(i) END;
    ns := 0; s := stones; WHILE s # NIL DO INC(ns, s.count);  n := UT.NEXT(s); s := n(Stone) END;
(*    print(stones); *)
    freelist := NIL; System.Collect;

    Texts.WriteString(W, "Partie 1: nombre de pierres = "); TE.WriteLongInt(W, ns, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W)
END AOC2024Day11.

OM4P.Compile AOC2024Day11.Mod/s ~ System.Free AOC2024Day11 UTHash ~ SystemLog AOCUtils ~

Partie 1: nombre de pierres = 55312
AOC2024Day11.run 25
125 17 ~

Partie 2: nombre de pierres = 65601038650482
AOC2024Day11.run 75
125 17 ~

Partie 1: nombre de pierres = 224529
AOC2024Day11.run 25
1117 0 8 21078 2389032 142881 93 385 ~

Partie 2: nombre de pierres = 266820198587914
AOC2024Day11.run 75
1117 0 8 21078 2389032 142881 93 385 ~


OM4Tool.DecObj AOC2024Day11.m4c
