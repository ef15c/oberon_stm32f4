MODULE FilesEx;
  IMPORT Files;

  CONST nothexdigit = 0;

  VAR res*: SET;

  PROCEDURE ResetErrors*;
  BEGIN res := {}
  END ResetErrors;

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

END FilesEx.
