MODULE AOC2017Day10;
  IMPORT Texts, Oberon, L := SystemLog;

  TYPE ProcessProc = PROCEDURE(i: INTEGER);
    Hash* = ARRAY 16 OF BYTE;

  VAR W: Texts.Writer;
    list: ARRAY 256 (*5*) OF (*INTEGER*)BYTE;
    position, skip: INTEGER;
    sequence: ARRAY 128 OF (*INTEGER*)BYTE; len: INTEGER;

  PROCEDURE toHexa(b: BYTE): CHAR;
    VAR r: CHAR;
  BEGIN
    IF b < 10 THEN r := CHR(b + ORD("0"))
    ELSIF b < 16 THEN r := CHR(b + (ORD("a") - 10))
    ELSE r := "?"
    END

    RETURN r 
  END toHexa;

  PROCEDURE parse(process: ProcessProc);
    VAR S!: Texts.Scanner;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    WHILE S.class = Texts.Int DO process(S.i);
      Texts.Scan(S); IF S.class = Texts.Char THEN Texts.Scan(S) END
    END
  END parse;

 PROCEDURE parse2(process: ProcessProc);
    VAR S!: Texts.Scanner; ch: CHAR; i: INTEGER;
  BEGIN len := 0;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Read(S, ch);
    WHILE (ch = 0DX) OR (ch = " ") DO Texts.Read(S, ch) END;
    WHILE ch # 0DX DO sequence[len] := ORD(ch); INC(len);
      Texts.Read(S, ch);
    END;
    sequence[len] := 17; INC(len);
    sequence[len] := 31; INC(len);
    sequence[len] := 73; INC(len);
    sequence[len] := 47; INC(len);
    sequence[len] := 23; INC(len);
    process(len)    
  END parse2;

 PROCEDURE parse2b(VAR s: ARRAY OF BYTE; VAR len: INTEGER);
    VAR S!: Texts.Scanner; ch: CHAR; i: INTEGER;
  BEGIN len := 0;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Read(S, ch);
    WHILE (ch = 0DX) OR (ch = " ") DO Texts.Read(S, ch) END;
    WHILE ch # 0DX DO s[len] := ORD(ch); INC(len);
      Texts.Read(S, ch);
    END
  END parse2b;

  PROCEDURE wrap(i: INTEGER): INTEGER;
  BEGIN WHILE i >= LEN(list) DO DEC(i, LEN(list)) END
    RETURN i
  END wrap;

  PROCEDURE doPart1(length: INTEGER);
    VAR i, j, t: INTEGER;
  BEGIN i := position; j := i + length - 1;
    WHILE i < j DO t := list[wrap(i)]; list[wrap(i)] := list[wrap(j)]; list[wrap(j)] := t;
      INC(i); DEC(j)
    END;
    position := wrap(position + length + skip); INC(skip)
  END doPart1;

  PROCEDURE doPart2(b: INTEGER);
    VAR n, m, i, j, t: INTEGER;
  BEGIN
    FOR n := 1 TO 64 DO
      FOR m := 0 TO b - 1 DO
        i := position; j := i + sequence[m] - 1;
        WHILE i < j DO t := list[wrap(i)]; list[wrap(i)] := list[wrap(j)]; list[wrap(j)] := t;
          INC(i); DEC(j)
        END;
        position := wrap(position + sequence[m] + skip); INC(skip)
      END
    END
  END doPart2;

  PROCEDURE part1*;
    VAR i: INTEGER;
  BEGIN position := 0; skip := 0; FOR i := 0 TO LEN(list) - 1 DO list[i] := i END;
    parse(doPart1);
    Texts.WriteString(W, "Partie 1: prd = "); Texts.WriteInt(W, list[0]*list[1], 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part1;

  PROCEDURE part2*;
    VAR i, j: INTEGER; hash: ARRAY 33 OF CHAR; b: SET;
  BEGIN position := 0; skip := 0; FOR i := 0 TO LEN(list) - 1 DO list[i] := i END;
    parse2(doPart2);
    FOR i := 0 TO 15*16 BY 16 DO b := {};
      FOR j := i TO i + 15 DO b := b/TOSET(list[j]) END;
      hash[i DIV 8] := toHexa(ORD(b) DIV 16);
      hash[i DIV 8 + 1] := toHexa(ORD(b) MOD 16);
    END; hash[32] := 0X;
    Texts.WriteString(W, "Partie 2: hash string = "); Texts.WriteString(W, hash); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part2;

  PROCEDURE ComputeHash(seq: ARRAY OF BYTE; len: INTEGER; VAR h: Hash);
    VAR position, skip: INTEGER;
      n, m, i, j, t: INTEGER;
      ring: ARRAY 256 OF INTEGER;
      b: SET;

    PROCEDURE wrap(i, rl: INTEGER): INTEGER;
    BEGIN WHILE i >= rl DO DEC(i, rl) END
      RETURN i
    END wrap;

  BEGIN position := 0; skip := 0; FOR i := 0 TO LEN(ring) - 1 DO ring[i] := i END;
    FOR n := 1 TO 64 DO
      FOR m := 0 TO len - 1 DO
        i := position; j := i + seq[m] - 1;
        WHILE i < j DO t := ring[wrap(i, LEN(ring))]; ring[wrap(i, LEN(ring))] := ring[wrap(j, LEN(ring))]; ring[wrap(j, LEN(ring))] := t;
          INC(i); DEC(j)
        END;
        position := wrap(position + seq[m] + skip, LEN(ring)); INC(skip)
      END
    END;

    FOR i := 0 TO 15*16 BY 16 DO b := {};
      FOR j := i TO i + 15 DO b := b/TOSET(ring[j]) END;
      h[i DIV 16] := ORD(b)
    END

  END ComputeHash;

  PROCEDURE HashBytes*(bytes: ARRAY OF BYTE; len: INTEGER; VAR h: Hash);
    VAR seq: ARRAY 128 OF BYTE;

    PROCEDURE Copy(s: ARRAY OF BYTE; VAR d: ARRAY OF BYTE; VAR len: INTEGER);
      VAR i: INTEGER;
    BEGIN i := 0; WHILE i < len DO d[i] := s[i]; INC(i) END;
      d[len] := 17; INC(len);
      d[len] := 31; INC(len);
      d[len] := 73; INC(len);
      d[len] := 47; INC(len);
      d[len] := 23; INC(len)
    END Copy;

  BEGIN Copy(bytes, seq, len); ComputeHash(seq, len, h)
  END HashBytes;

  PROCEDURE HashString*(string: ARRAY OF CHAR; VAR h: Hash);
    VAR seq: ARRAY 128 OF BYTE; l: INTEGER;

    PROCEDURE Copy(s: ARRAY OF CHAR; VAR d: ARRAY OF BYTE; VAR l: INTEGER);
    BEGIN l := 0; WHILE s[l] # 0X DO d[l] := ORD(s[l]); INC(l) END;
      d[l] := 17; INC(l);
      d[l] := 31; INC(l);
      d[l] := 73; INC(l);
      d[l] := 47; INC(l);
      d[l] := 23; INC(l)
    END Copy;

  BEGIN Copy(string, seq, len); ComputeHash(seq, len, h)
  END HashString;

  PROCEDURE part2b*;
    VAR s: ARRAY 128 OF BYTE; h: Hash; hash: ARRAY 33 OF CHAR;
      l, i: INTEGER;
  BEGIN parse2b(s, l); HashBytes(s, l, h);
    FOR i := 0 TO 30 BY 2 DO
      hash[i] := toHexa(ORD(h[i DIV 2]) DIV 16);
      hash[i + 1] := toHexa(ORD(h[i DIV 2]) MOD 16);
    END; hash[32] := 0X;
    Texts.WriteString(W, "Partie 2b: hash string = "); Texts.WriteString(W, hash); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END part2b;

BEGIN Texts.OpenWriter(W)
END AOC2017Day10.

Oberon.Batch
  OM4P.Compile AOC2017Day10.Mod/s~
  System.Free AOC2017Day10~
~

Partie 1: prd = 8536
AOC2017Day10.part1
97,167,54,178,2,11,209,174,119,248,254,0,255,1,64,190
~

Partie 2: hash string = aff593797989d665349efe11bb4fd99b
AOC2017Day10.part2
97,167,54,178,2,11,209,174,119,248,254,0,255,1,64,190

Partie 2b: hash string = aff593797989d665349efe11bb4fd99b
AOC2017Day10.part2b
97,167,54,178,2,11,209,174,119,248,254,0,255,1,64,190
~
