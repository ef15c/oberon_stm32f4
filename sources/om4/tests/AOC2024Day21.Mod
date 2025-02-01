MODULE AOC2024Day21;
  IMPORT Texts, TE := TextsEx2, Oberon, System, U := AOCUtils, UT := UTHash, L := SystemLog;

  CONST ASCII_MAX = LSL(1, 7);
    MOVES_SIZE = 200;

  TYPE WordDesc = RECORD(UT.HashDesc) word: ARRAY 5 OF CHAR; count: LONGINT END;
    Word = POINTER TO WordDesc;

    Moves = RECORD key: ARRAY MOVES_SIZE OF CHAR; pos: INTEGER END;
    Callback = PROCEDURE(VAR moves: Moves; p: U.Vector);
    ProcessProc = PROCEDURE(code: ARRAY OF CHAR);

  VAR W: Texts.Writer; t: INTEGER; i0, j0, k0: INTEGER;
    numkp: ARRAY 4, 4 OF CHAR; dirkp: ARRAY 2, 4 OF CHAR;
    cnumkp, cdirkp: ARRAY ASCII_MAX OF U.Vector;
    shortmoves: ARRAY MOVES_SIZE OF CHAR; sc, minlen: LONGINT;
    words, skey, freelist: Word;

(* table d'expansion des paires de caract\E8res
      +---------------------+
      | ^ | A  | <  | v | > |
  +---+---+----+----+---+---|
  | ^ | A | >A |v<A | vA|v>A|
  +---+---+----+----+---+---|
  | A | <A| A  |v<<A|v<A| vA|
  +---+---+----+----+---+---|
  | < |>^A|>>^A| A  | >A|>>A|
  +---+---+----+----+---+---|
  | v |^A |^>A | <A | A | >A|
  +---+---+----+----+---+---|
  | > |^<A| ^A |<<A |<A | A |
  +---+---+----+----+---+---+

  clavier
      +---+---+
      | ^ | A |
  +---+---+---+
  | < | v | > |
  +---+---+---+
*)

    expTab: ARRAY ASCII_MAX, ASCII_MAX, 5 OF CHAR;

  PROCEDURE buildExpandTable;
  BEGIN
    expTab[ORD("^"), ORD("^")] := "A";
    expTab[ORD("^"), ORD("A")] := ">A";
    expTab[ORD("^"), ORD("<")] := "v<A";
    expTab[ORD("^"), ORD("v")] := "vA";
    expTab[ORD("^"), ORD(">")] := "v>A";
(*    strcpy(expTab['^']['>'], ">vA");  d\E9grade *)

    expTab[ORD("A"), ORD("^")] := "<A";
    expTab[ORD("A"), ORD("A")] := "A";
    expTab[ORD("A"), ORD("<")] := "v<<A";
(*    strcpy(expTab['A']['v'], "v<A");*)
    expTab[ORD("A"), ORD("v")] := "<vA"; (* am\E9liore *)
    expTab[ORD("A"), ORD(">")] := "vA";

    expTab[ORD("<"), ORD("^")] := ">^A";
    expTab[ORD("<"), ORD("A")] := ">>^A";
    expTab[ORD("<"), ORD("<")] := "A";
    expTab[ORD("<"), ORD("v")] := ">A";
    expTab[ORD("<"), ORD(">")] := ">>A";

    expTab[ORD("v"), ORD("^")] := "^A";
    expTab[ORD("v"), ORD("A")] := "^>A";
(*    strcpy(expTab['v']['A'], ">^A"); d\E9grade *)
    expTab[ORD("v"), ORD("<")] := "<A";
    expTab[ORD("v"), ORD("v")] := "A";
    expTab[ORD("v"), ORD(">")] := ">A";

(*    strcpy(expTab['>']['^'], "^<A");*)
    expTab[ORD(">"), ORD("^")] := "<^A"; (* am\E9liore *)
    expTab[ORD(">"), ORD("A")] := "^A";
    expTab[ORD(">"), ORD("<")] := "<<A";
    expTab[ORD(">"), ORD("v")] := "<A";
    expTab[ORD(">"), ORD(">")] :=  "A";
  END  buildExpandTable;

  PROCEDURE buildMoves(ckp: ARRAY OF U. Vector; f, p0: U.Vector; VAR code: Moves; proc: Callback; VAR moves: Moves);
    VAR p, np, pp: U.Vector; i, ppos, cpos, ki: INTEGER;
  BEGIN p := p0; ki := ORD(code.key[code.pos]);
    IF ki # 0 THEN
      np := ckp[ki]; ASSERT((np.x >= 0) & (np.y >= 0));
      IF  (p.y = f.y) & (np.x = f.x) THEN (* mouvement vertical en premier *)
        WHILE np.y > p.y DO moves.key[moves.pos] := "v"; INC(moves.pos); INC(p.y) END;
        WHILE np.y < p.y DO moves.key[moves.pos] := "^"; INC(moves.pos); DEC(p.y) END;

        WHILE np.x > p.x DO moves.key[moves.pos] := ">"; INC(moves.pos); INC(p.x) END;
        WHILE np.x < p.x DO moves.key[moves.pos] := "<"; INC(moves.pos); DEC(p.x) END;

        moves.key[moves.pos] := "A"; INC(moves.pos);
        cpos := code.pos; INC(code.pos); buildMoves(ckp, f, p, code, proc, moves); code.pos := cpos
      ELSIF (p.x = f.x) & (np.y = f.y) THEN (* mouvement horizontal en premier *)
        WHILE np.x > p.x DO moves.key[moves.pos] := ">"; INC(moves.pos); INC(p.x) END;
        WHILE np.x < p.x DO moves.key[moves.pos] := "<"; INC(moves.pos); DEC(p.x) END;

        WHILE np.y > p.y DO moves.key[moves.pos] := "v"; INC(moves.pos); INC(p.y) END;
        WHILE np.y < p.y DO moves.key[moves.pos] := "^"; INC(moves.pos); DEC(p.y) END;

        moves.key[moves.pos] := "A"; INC(moves.pos);
        cpos := code.pos; INC(code.pos); buildMoves(ckp, f, p, code, proc, moves); code.pos := cpos
      ELSE (* On essaie les deux sens *)
        IF (np.x # p.x) & (np.y # p.y) THEN
          ppos := moves.pos; pp := p;
          WHILE np.y > p.y DO moves.key[moves.pos] := "v"; INC(moves.pos); INC(p.y) END;
          WHILE np.y < p.y DO moves.key[moves.pos] := "^"; INC(moves.pos); DEC(p.y) END;

          WHILE np.x > p.x DO moves.key[moves.pos] := ">"; INC(moves.pos); INC(p.x) END;
          WHILE np.x < p.x DO moves.key[moves.pos] := "<"; INC(moves.pos); DEC(p.x) END;

          moves.key[moves.pos] := "A"; INC(moves.pos);
          cpos := code.pos; INC(code.pos); buildMoves(ckp, f, p, code, proc, moves); code.pos := cpos;
          moves.pos := ppos; p := pp;
        END;
        WHILE np.x > p.x DO moves.key[moves.pos] := ">"; INC(moves.pos); INC(p.x) END;
        WHILE np.x < p.x DO moves.key[moves.pos] := "<"; INC(moves.pos); DEC(p.x) END;

        WHILE np.y > p.y DO moves.key[moves.pos] := "v"; INC(moves.pos); INC(p.y) END;
        WHILE np.y < p.y DO moves.key[moves.pos] := "^"; INC(moves.pos); DEC(p.y) END;

        moves.key[moves.pos] := "A"; INC(moves.pos);
        cpos := code.pos; INC(code.pos); buildMoves(ckp, f, p, code, proc, moves); code.pos := cpos;
      END
    ELSE
      moves.key[moves.pos] := 0X; proc(moves, p);
    END
  END buildMoves;

  PROCEDURE c3(VAR moves: Moves; p: U.Vector);
    VAR bl: INTEGER;
  BEGIN (* printf("moves: %s position %d,%d\n", moves, p.x, p.y); *)
    bl := U.strlen(shortmoves);
    IF (bl = 0) OR (bl > U.strlen(moves.key)) THEN shortmoves := moves.key END
  END c3;

  PROCEDURE c2(VAR moves: Moves; p: U.Vector);
    VAR moves2: Moves; p0: U.Vector;
  BEGIN (* printf("moves: %s position %d,%d\n", moves, p.x, p.y); *)
    p0.x := 0; p0.y := 0; moves.pos := 0; moves2.pos := 0;
    buildMoves(cdirkp, p0, cdirkp[ORD("A")], moves, c3, moves2)
  END c2;

  PROCEDURE c1(VAR moves: Moves; p: U.Vector);
    VAR moves2: Moves; p0: U.Vector;
  BEGIN (* printf("moves: %s position %d,%d\n", moves, p.x, p.y); *)
    p0.x := 0; p0.y := 0; moves.pos := 0; moves2.pos := 0;
    buildMoves(cdirkp, p0, cdirkp[ORD("A")], moves, c2, moves2)
  END c1;

  PROCEDURE parse(process: ProcessProc);
    VAR S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    WHILE S.class = Texts.String DO process(S.s); Texts.Scan(S) END
  END parse;

  PROCEDURE processPart1(code: ARRAY OF CHAR);
    VAR c, m: Moves; f: U.Vector; np: INTEGER;
  BEGIN shortmoves[0] := 0X; c.pos := 0; c.key := code; f.x := 0; f.y := 3; m.pos := 0;
    buildMoves(cnumkp, f, cnumkp[ORD("A")], c, c1, m);
    np := U.toInt(code); INC(sc, np*U.strlen(shortmoves))
  END processPart1;

  PROCEDURE part1*;
  BEGIN sc := 0; parse(processPart1);
    Texts.WriteString(W, "Partie 1: sc = "); TE.WriteLongInt(W, sc, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;

  PROCEDURE getHash(d: UT.Hash): INTEGER;
    VAR r: INTEGER;
  BEGIN
    CASE d OF
      Word: r := UT.HASH_STRING(d.word)
    | UT.Hash: ASSERT(FALSE)
    END

    RETURN r
  END getHash;
  
  PROCEDURE isEqual(a, b: UT.Hash): BOOLEAN;
    VAR r: BOOLEAN;
  BEGIN
    CASE a OF
      Word: r := a.word = b(Word).word
    | UT.Hash: ASSERT(FALSE)
    END

    RETURN r
  END isEqual;
  
  PROCEDURE expand(pk, nk: BYTE; cnt: LONGINT; VAR words: Word);
    VAR w!: Word; t!: UT.Hash;
  BEGIN skey.word := expTab[pk, nk]; t := UT.FIND(words, skey, getHash, isEqual); w := t(Word);
    IF w = NIL THEN IF freelist = NIL THEN NEW(w) ELSE w := freelist; t := UT.NEXT(freelist); freelist := t(Word) END;
      w.word := expTab[pk, nk]; w.count := cnt;
      t := UT.ADD(words, w, getHash); words := t(Word)
    ELSE INC(w.count, cnt)
    END
  END expand;

  PROCEDURE c1p2(VAR moves: Moves; p: U.Vector);
    VAR j, k: INTEGER; pk: BYTE; pwords!, w!: Word; tw!, tmp!: UT.Hash;
      len: LONGINT;
  BEGIN pk := ORD("A");
    FOR j := 0 TO U.strlen(moves.key) - 1 DO
      expand(pk, ORD(moves.key[j]), 1, words); pk := ORD(moves.key[j])
    END;

    FOR k := 1 TO 24 DO LED(k); pwords := words; words := NIL; w := pwords;
      WHILE w # NIL DO tmp := UT.NEXT(w); pk := ORD("A");
        FOR j := 0 TO U.strlen(w.word) -1 DO
          expand(pk, ORD(w.word[j]), w.count, words); pk := ORD(w.word[j])
        END; tw := UT.DELETE(pwords, w); pwords := tw(Word);
        tw := UT.FREE(freelist, w); freelist := tw(Word);
        w := tmp(Word)
      END
    END;

    len := 0; w := words;
    WHILE w # NIL DO tmp := UT.NEXT(w);
      INC(len, w.count * U.strlen(w.word));
      tw := UT.DELETE(words, w); words := tw(Word);
      tw := UT.FREE(freelist, w); freelist := tw(Word);
      w := tmp(Word)
    END;

    IF len < minlen THEN minlen := len END
  END c1p2;

  PROCEDURE processPart2(code: ARRAY OF CHAR);
    VAR c, m: Moves; f: U.Vector; np: INTEGER;
  BEGIN minlen := U.LONG_MAX; c.pos := 0; c.key := code; f.x := 0; f.y := 3; m.pos := 0;
    buildMoves(cnumkp, f, cnumkp[ORD("A")], c, c1p2, m);
    np := U.toInt(code); INC(sc, minlen*np)
  END processPart2;

  PROCEDURE part2*;
  BEGIN sc := 0; parse(processPart2);
    Texts.WriteString(W, "Partie 2: sc = "); TE.WriteLongInt(W, sc, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf); words := NIL
  END part2;

BEGIN Texts.OpenWriter(W); NEW(skey);
  numkp[0] := "789"; numkp[1] := "456"; numkp[2] := "123"; numkp[3] := "#0A";
  dirkp[0] := "#^A"; dirkp[1] := "<v>";

  FOR i0 := 0 TO LEN(numkp) - 1 DO
    FOR j0 := 0 TO LEN(numkp[0]) - 1 DO
      k0 := ORD(numkp[i0, j0]);
      IF k0 = ORD("#") THEN cnumkp[k0].x := -1; cnumkp[k0].y := -1 ELSE  cnumkp[k0].x := j0; cnumkp[k0].y := i0 END
    END
  END;
 
  FOR i0 := 0 TO LEN(dirkp) - 1 DO
    FOR j0 := 0 TO LEN(dirkp[0]) - 1 DO
      k0 := ORD(dirkp[i0, j0]);
      IF k0 = ORD("#") THEN cdirkp[k0].x := -1; cdirkp[k0].y := -1 ELSE  cdirkp[k0].x := j0; cdirkp[k0].y := i0 END
    END
  END;
  buildExpandTable

END AOC2024Day21.

OM4P2.Compile AOC2024Day21.Mod/s ~ System.Free AOC2024Day21 testLongInt AOCUtils UTHash SystemLog ~
OM4Tool.DecObj AOC2024Day21.m4c

Partie 1: sc = 126384
AOC2024Day21.part1
"029A"
"980A"
"179A"
"456A"
"379A"
~

Partie 1: sc = 157230
AOC2024Day21.part1
"340A"
"149A"
"582A"
"780A"
"463A"
~

Partie 2: sc = 195969155897936
AOC2024Day21.part2
"340A"
"149A"
"582A"
"780A"
"463A"
~
