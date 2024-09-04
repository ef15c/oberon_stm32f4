MODULE FilesEx;
  IMPORT Files;

  PROCEDURE WriteHex*(VAR R: Files.Rider; x: BYTE);  (*write a byte in 2 digit hex format*)
    VAR i: INTEGER; y: LONGINT;
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
