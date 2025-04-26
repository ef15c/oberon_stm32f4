MODULE FilesEx;
  IMPORT Files;

  CONST nothexdigit = 0;

  VAR res*: SET;

  PROCEDURE ResetErrors*;
  BEGIN res := {}
  END ResetErrors;

  PROCEDURE ReadHalfWord*(VAR R: Files.Rider; VAR n: INTEGER);
    VAR b1, b2: BYTE;
  BEGIN Files.ReadByte(R, b1); Files.ReadByte(R, b2);
    n := b1 + b2*100H
  END ReadHalfWord;

  PROCEDURE WriteHalfWord*(VAR R: Files.Rider; n: INTEGER);
  BEGIN Files.WriteByte(R, n MOD 100H); Files.WriteByte(R, n DIV 100H MOD 100H)
  END WriteHalfWord;

  PROCEDURE valueHexDigit(c: CHAR): BYTE;
    VAR x: BYTE;
  BEGIN
    IF c < "0" THEN INCL(res, nothexdigit)
    ELSIF c <= "9" THEN x := ORD(c) - ORD("0")
    ELSIF c < "A" THEN INCL(res, nothexdigit)
    ELSIF c <= "F" THEN x := ORD(c) - (ORD("A") - 10)
    ELSE INCL(res, nothexdigit)
    END

    RETURN x
  END valueHexDigit;

  PROCEDURE ReadHex*(VAR R: Files.Rider; VAR x: BYTE); (*read to hex digits into a byte*)
    VAR ch: CHAR;
  BEGIN Files.Read(R, ch); x := valueHexDigit(ch)*10H;
    Files.Read(R, ch); INC(x, valueHexDigit(ch))
  END ReadHex;

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

  PROCEDURE WriteLongInt*(VAR R: Files.Rider; l: LONGINT);
    VAR i: INTEGER;
  BEGIN FOR i := 0 TO 7 DO Files.WriteByte(R, l MOD 100H); l := LSR(l, 8) END
  END WriteLongInt;

  PROCEDURE ReadLongNum*(VAR R: Files.Rider; VAR x: LONGINT);
    VAR n: INTEGER; y: LONGINT; b: BYTE;
  BEGIN
    n := 0; y := 0; x := 0; Files.ReadByte(R, b);
    WHILE b >= 80H DO y := b-80H; INC(x, LSL(y, n)); INC(n, 7); Files.ReadByte(R, b) END;
    y := b; INC(x, LSL(y, n)); (*store last number*);
    INC(n, 7); IF n > 64 THEN n := 64 END; x := ASR(LSL(x, 64-n), 64-n) (*sign extend the number*)
  END ReadLongNum;

  PROCEDURE WriteLongNum*(VAR R: Files.Rider; x: LONGINT);
  BEGIN
    WHILE (x < -40H) OR (x >= 40H) DO Files.WriteByte(R, x MOD 80H + 80H); x := ASR(x, 7) END ;
    Files.WriteByte(R, x MOD 80H)
  END WriteLongNum;

END FilesEx.
