MODULE FilesEx2;
  IMPORT Files;

  PROCEDURE ReadHalfWord*(VAR R: Files.Rider; VAR n: INTEGER);
    VAR b1, b2: BYTE;
  BEGIN Files.ReadByte(R, b1); Files.ReadByte(R, b2);
    n := b1 + b2*100H
  END ReadHalfWord;

  PROCEDURE WriteHex*(VAR R: Files.Rider; x: BYTE);  (*write a byte in 2 digit hex format*)
    VAR i: INTEGER; y: INTEGER;
      a: ARRAY 2 OF CHAR;
  BEGIN i := 0;
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END ;
      x := x DIV 10H; INC(i)
    UNTIL i = 2;
    REPEAT DEC(i); Files.Write(R, a[i]) UNTIL i = 0 ;
  END WriteHex;

  PROCEDURE WriteHexWord*(VAR R: Files.Rider; w: INTEGER);  (*write a word in 8 digit hex format*)
    VAR i: INTEGER; b: ARRAY 4 OF BYTE;
  BEGIN
    FOR i := 0 TO 3 DO b[i] := w MOD 100H; w := w DIV 100H END;
    FOR i := 3 TO 0 BY -1 DO WriteHex(R, b[i]) END
  END WriteHexWord;
  
  PROCEDURE WriteHexHalfWord*(VAR R: Files.Rider; w: INTEGER);  (*write a half word in 4 digit hex format*)
    VAR i: INTEGER; b: ARRAY 2 OF BYTE;
  BEGIN
    FOR i := 0 TO 1 DO b[i] := w MOD 100H; w := w DIV 100H END;
    FOR i := 1 TO 0 BY -1 DO WriteHex(R, b[i]) END
  END WriteHexHalfWord;
 
  PROCEDURE WriteString*(VAR R: Files.Rider; x: ARRAY OF CHAR);  (*write a string without trailing null character*)
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE x[i] # 0X DO Files.Write(R, x[i]); INC(i) END
  END WriteString;

  PROCEDURE WriteLn*(VAR R: Files.Rider);
  BEGIN Files.Write(R, 0DX)
  END WriteLn;

  PROCEDURE ReadLongInt*(VAR R: Files.Rider; VAR l: LONGINT);
    VAR x: ARRAY 8 OF BYTE; i: INTEGER;
  BEGIN FOR i := 0 TO 7 DO Files.ReadByte(R, x[i]) END;
    l := 0; FOR i:= 7 TO 0 BY -1 DO l := l*100H + x[i] END
  END ReadLongInt;

  PROCEDURE ReadLongNum*(VAR R: Files.Rider; VAR x: LONGINT);
    VAR n: INTEGER; y: LONGINT; b: BYTE;
  BEGIN
(* TODO: supprimer le code jaune quand la compilation "bootstrap" avec OM4P.Compile ne sera plus n\E9cessaire*)
    x := 1; n := 1;
    IF ASR(LSL(x, 64-n), 64-n) = 0 THEN (* le support des entiers 64 bits n'est pas encore en place *)
      Files.ReadNum(R, n); x := n; (* On utilise le code original*)
    ELSE
      n := 0; y := 0; x := 0; Files.ReadByte(R, b);
      WHILE b >= 80H DO y := b-80H; INC(x, LSL(y, n)); INC(n, 7); Files.ReadByte(R, b) END;
      y := b; INC(x, LSL(y, n)); (*store last number*);
      INC(n, 7); IF n > 64 THEN n := 64 END; x := ASR(LSL(x, 64-n), 64-n) (*sign extend the number*)
    END
  END ReadLongNum;

  PROCEDURE WriteLongNum*(VAR R: Files.Rider; x: LONGINT);
    VAR x0: LONGINT; i: INTEGER;
  BEGIN
(* TODO: supprimer le code jaune quand la compilation "bootstrap" avec OM4P.Compile ne sera plus n\E9cessaire*)
    x0 := 0;
    IF x0 < -40H THEN (* le support des litt\E9raux entiers 64 bits n'est pas encore en place *)
      Files.WriteNum(R, x); (* On utilise le code original*)
    ELSE
      WHILE (x < -40H) OR (x >= 40H) DO Files.WriteByte(R, x MOD 80H + 80H); x := ASR(x, 7) END ;
      Files.WriteByte(R, x MOD 80H)
    END
  END WriteLongNum;

END FilesEx2.

OM4Tool.DecObj FilesEx2.m4c
