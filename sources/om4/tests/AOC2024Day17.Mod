MODULE AOC2024Day17;
  IMPORT Texts, TE := TextsEx2, Oberon, U := AOCUtils, L := SystemLog;

  TYPE Regs = RECORD A, B, C: LONGINT; PC: INTEGER END;
    OutProc = PROCEDURE(v: INTEGER; next: BOOLEAN; a: INTEGER): BOOLEAN;

   VAR W: Texts.Writer; digit: ARRAY 1024 OF INTEGER;

  (*PROCEDURE pow2(n: INTEGER) = LSL(1L, n)*)

  PROCEDURE combine(i: INTEGER; a: LONGINT; p: ARRAY OF INTEGER);
    VAR j: INTEGER;
  BEGIN
    IF i = -1 THEN Texts.WriteString(W, "Partie 2: valeur initiale du registre A = ");
      TE.WriteLongInt(W, a, 1); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    ELSE a := a*8;
      FOR j := 0 TO 7 DO
        IF digit[a MOD 1024 + j] = p[i] THEN (*On peut construire le nombre*) combine(i-1, a + j, p) END
      END
    END
  END combine;

  PROCEDURE parse(VAR r: Regs; VAR p: ARRAY OF INTEGER; VAR ps: INTEGER);
    VAR S!: TE.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); TE.Scan(S);
    r.A := U.ReadL(S); r.B := 0; r.C := 0; r.PC := 0; ps := 0;
    WHILE S.class IN {Texts.Int, TE.LongInt} DO p[ps] := U.ReadL(S); INC(ps) END
  END parse;

  PROCEDURE value(r: Regs; c: INTEGER): LONGINT;
    VAR res: LONGINT;
  BEGIN ASSERT((c >= 0) & (c < 7));
    IF c < 4 THEN res := c ELSIF c = 4 THEN res := r.A ELSIF c = 5 THEN res := r.B ELSIF c = 6 THEN res := r.C ELSE res := -1 END

    RETURN res
  END value;

  PROCEDURE execProg(VAR r: Regs; VAR p: ARRAY OF INTEGER; VAR ps: INTEGER; out: OutProc);
    VAR next: BOOLEAN; oc, arg, a: INTEGER;
  BEGIN next := FALSE; a := r.A;
    WHILE r.PC < ps DO oc := p[r.PC]; arg := p[r.PC + 1];
      IF  oc = 0 THEN (* adv *) r.A := r.A DIV LSL(1L, value(r, arg))
      ELSIF oc = 1 THEN (* bxl *) r.B := XOR(r.B, arg)
      ELSIF oc = 2 THEN (* bst *) r.B := value(r, arg) MOD 8
      ELSIF oc = 3 THEN (* jnz *) IF r.A # 0 THEN r.PC := arg - 2 END;
      ELSIF oc = 4 THEN (* bxc *) r.B := XOR(r.B, r.C)
      ELSIF oc = 5 THEN (* out *) IF out(value(r, arg) MOD 8, next, a) THEN r.PC := ps (*stop program*) END; next := TRUE
      ELSIF oc = 7 THEN (* cdv *) r.C := r.A DIV LSL(1L, value(r, arg))
      ELSE Texts.WriteString(W, "\nInconnu : "); Texts.WriteInt(W, oc, 1); Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf); ASSERT(FALSE)
      END;
      INC(r.PC, 2)
    END
  END execProg;

  PROCEDURE print(v: INTEGER; next: BOOLEAN; a: INTEGER): BOOLEAN;
  BEGIN
    IF next THEN Texts.Write(W, ",") END;
    TE.WriteLongInt(W, v, 1)

    RETURN FALSE (*continue exection*)
  END print;

  PROCEDURE part1*;
    VAR r: Regs; p: ARRAY 20 OF INTEGER; ps: INTEGER;
  BEGIN parse(r, p, ps); execProg(r, p, ps, print); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;

  PROCEDURE store(v: INTEGER; next: BOOLEAN; a: INTEGER): BOOLEAN;
  BEGIN digit[a] := v

    RETURN TRUE (*stop exection*)
  END store;

  PROCEDURE compare(v: INTEGER; next: BOOLEAN; a: INTEGER): BOOLEAN;
  BEGIN ASSERT(digit[a-1024] = v)

    RETURN TRUE (*stop exection*)
  END compare;

  PROCEDURE part2*;
    VAR r: Regs; p: ARRAY 20 OF INTEGER; ps, a: INTEGER;
  BEGIN parse(r, p, ps);
    a := 0; WHILE a < 1024 DO r.A := a; r.B := 0; r.C := 0; r.PC := 0; execProg(r, p, ps, store); INC(a) END;
    WHILE a < 2048 DO r.A := a; r.B := 0; r.C := 0; r.PC := 0; execProg(r, p, ps, compare); INC(a) END;
(*    FOR a := 0 TO 1023 DO Texts.WriteInt(W, digit[a], 2);
      IF (a+1) MOD 64 = 0 THEN Texts.WriteLn(W) END
    END; Texts.Append(Oberon.Log, W.buf);*)
    combine(ps - 1, 0, p)
  END part2;
BEGIN  Texts.OpenWriter(W)
END AOC2024Day17.

OM4P2.Compile AOC2024Day17.Mod/s ~ System.Free AOC2024Day17 SystemLog ~
OM4Tool.DecObj AOC2024Day17.m4c

4,6,3,5,6,3,5,2,1,0
AOC2024Day17.part1
729 0 1 5 4 3 0 ~

2,1,0,4,6,2,4,2,0
AOC2024Day17.part1
53437164 2 4 1 7 7 5 4 1 1 4 5 5 0 3 3 0 ~

0,3,5,4,3,0
AOC2024Day17.part1
117440 0 3 5 4 3 0 ~

Partie 2: valeur initiale du registre A = 109685330781408
Partie 2: valeur initiale du registre A = 109685364335840
Partie 2: valeur initiale du registre A = 140471656359136
Partie 2: valeur initiale du registre A = 140471689913568
AOC2024Day17.part2
53437164 2 4 1 7 7 5 4 1 1 4 5 5 0 3 3 0 ~

2,4,1,7,7,5,4,1,1,4,5,5,0,3,3,0
AOC2024Day17.part1
109685330781408 2 4 1 7 7 5 4 1 1 4 5 5 0 3 3 0 ~
