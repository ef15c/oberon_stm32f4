MODULE FontUtils;
  IMPORT Files, Texts, Oberon;

  CONST FontFileId = 0DBH;

  TYPE RunRec = RECORD beg, end: BYTE END;
    BoxRec = RECORD dx, x, y, w, h: INTEGER END ;

  VAR W: Texts.Writer;


  PROCEDURE chgExt(VAR name: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := LEN(name);
    REPEAT DEC(i) UNTIL (i <= 0) OR (name[i] = ".");
    name[i+1] := "b"; name[i+2] := "d"; name[i+3] := "f"
  END chgExt;

  PROCEDURE CRLF(VAR R: Files.Rider);
  BEGIN
    Files.Write(R, 0DX); Files.Write(R, 0AX); 
  END CRLF;

  PROCEDURE WriteString(VAR R: Files.Rider; s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Files.Write(R, s[i]); INC(i) END
  END WriteString;

  PROCEDURE doWriteInt(VAR R: Files.Rider; v: INTEGER);
  BEGIN
    IF v >= 10 THEN doWriteInt(R, v DIV 10) END;
    Files.Write(R, CHR(ORD("0") + v MOD 10))    
  END doWriteInt;

  PROCEDURE WriteInt(VAR R: Files.Rider; v: INTEGER);
    VAR i: INTEGER;
  BEGIN IF v < 0 THEN Files.Write(R, "-"); v := -v END;
    IF v = 0 THEN Files.Write(R, "0") ELSE doWriteInt(R, v) END 
  END WriteInt;

  PROCEDURE WriteHexDigit(VAR R: Files.Rider; v: BYTE);
  BEGIN
    IF v < 10 THEN Files.Write(R, CHR(ORD("0") + v)) ELSE Files.Write(R, CHR(ORD("A") + v-10)) END
  END WriteHexDigit;

  PROCEDURE WriteHex(VAR R: Files.Rider; v: BYTE);
    VAR i: INTEGER;
  BEGIN WriteHexDigit(R, v DIV 10H); WriteHexDigit(R, v MOD 10H); 
  END WriteHex;

  PROCEDURE ToBDF*;  (*write code section of M.m4c in binary format to output file*)
    VAR f!, g!: Files.File; Rf!, Rg!: Files.Rider;
      NofRuns, height, width, minX, maxX, minY, maxY: INTEGER;
      name: ARRAY 32 OF CHAR;
      S!: Texts.Scanner;
      b, ab, fam, var: BYTE;
      h, i, j, k, l, m, n, w, beg, end, NofBoxes: INTEGER;
      run: ARRAY 16 OF RunRec;
      box: ARRAY 512 OF BoxRec;
      bm: ARRAY 32*32 DIV 8 OF BYTE;

  PROCEDURE RdInt16(VAR R: Files.Rider; VAR x: INTEGER);
    VAR b0, b1: BYTE;
  BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1);
    x := b0 + b1*100H;
    IF x > 8000H THEN x := x - 10000H END
  END RdInt16;

  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN name := S.s; f := Files.Old(name);
      IF f # NIL THEN Files.Set(Rf, f, 0); Files.ReadByte(Rf, ab);
        chgExt(name); g := Files.New(name); Files.Set(Rg, g, 0);
        IF ab = FontFileId THEN
          WriteString(Rg, "STARTFONT 2.1"); CRLF(Rg);
          WriteString(Rg, "FONT "); WriteString(Rg, name); CRLF(Rg);
          Files.ReadByte(Rf, ab); (*abstraction*)
          Files.ReadByte(Rf, fam); (*family*)
          Files.ReadByte(Rf, var); (*variant*)
          RdInt16(Rf, height); RdInt16(Rf, minX); RdInt16(Rf, maxX); RdInt16(Rf, minY); RdInt16(Rf, maxY); RdInt16(Rf, NofRuns); 
          width := maxX - minX + 1;
          WriteString(Rg, "SIZE "); WriteInt(Rg, height); WriteString(Rg, " 75 75"); CRLF(Rg);
          WriteString(Rg, "FONTBOUNDINGBOX "); WriteInt(Rg, width); WriteString(Rg, " "); WriteInt(Rg, height); WriteString(Rg, " ");
          WriteInt(Rg, minX); WriteString(Rg, " "); WriteInt(Rg, minY); CRLF(Rg);
          WriteString(Rg, "STARTPROPERTIES 6"); CRLF(Rg);
          WriteString(Rg, "ABSTRACTION "); WriteInt(Rg, ab); CRLF(Rg);
          WriteString(Rg, "FAMILY "); WriteInt(Rg, fam); CRLF(Rg);
          WriteString(Rg, "VARIANT "); WriteInt(Rg, var); CRLF(Rg);
          WriteString(Rg, "CHARSET_REGISTRY ISO8859-15"); CRLF(Rg);
          WriteString(Rg, "FONT_ASCENT "); WriteInt(Rg, maxY); CRLF(Rg);
          WriteString(Rg, "FONT_DESCENT "); WriteInt(Rg, -minY); CRLF(Rg);
          WriteString(Rg, "ENDPROPERTIES"); CRLF(Rg);
          (*compute the number of glyphs in the font*)
          NofBoxes := 0; k := 0;
          WHILE k # NofRuns DO
            RdInt16(Rf, beg);
            run[k].beg := beg; RdInt16(Rf, end);
            run[k].end := end; NofBoxes := NofBoxes + end - beg; INC(k)
          END;
          WriteString(Rg, "CHARS "); WriteInt(Rg, NofBoxes); CRLF(Rg);
          j := 0;
          WHILE j # NofBoxes DO
            RdInt16(Rf, box[j].dx); RdInt16(Rf, box[j].x); RdInt16(Rf, box[j].y);
            RdInt16(Rf, box[j].w); RdInt16(Rf, box[j].h);
            INC(j)
          END;
          k :=0; j := 0;
          WHILE k < NofRuns DO
            FOR m := run[k].beg TO run[k].end - 1 DO
              WriteString(Rg, "STARTCHAR "); WriteInt(Rg, m); CRLF(Rg);
              WriteString(Rg, "ENCODING "); WriteInt(Rg, m); CRLF(Rg);
              WriteString(Rg, "SWIDTH "); WriteInt(Rg, box[j].dx*1000 DIV width); WriteString(Rg, " 0"); CRLF(Rg);
              WriteString(Rg, "DWIDTH "); WriteInt(Rg, box[j].dx); WriteString(Rg, " 0"); CRLF(Rg);
              WriteString(Rg, "BBX "); WriteInt(Rg, box[j].w); WriteString(Rg, " "); WriteInt(Rg, box[j].h);
              WriteString(Rg, " "); WriteInt(Rg, box[j].x); WriteString(Rg, " "); WriteInt(Rg, box[j].y); CRLF(Rg);
              WriteString(Rg, "BITMAP"); CRLF(Rg);
              w := box[j].w; h := box[j].h; l := (w + 7) DIV 8;
              FOR i := 0 TO  (w + 7) DIV 8*h-1 DO Files.ReadByte(Rf, bm[i]) END;
              FOR i := 1 TO h DO
                FOR n := 0 TO l-1 DO WriteHex(Rg, LSR(RBIT(bm[(h-i)*l + n]), 24)) END;
                CRLF(Rg)
              END ;
              INC(j);
              WriteString(Rg, "ENDCHAR"); CRLF(Rg);
            END;
            INC(k)
          END;
          WriteString(Rg, "ENDFONT"); CRLF(Rg);

          Files.Register(g); Texts.WriteString(W, "font converted in "); Texts.WriteString(W, name);
        ELSE Texts.WriteString(W, "bad file id")
        END
      ELSE Texts.WriteString(W, "file "); Texts.WriteString(W, name); Texts.WriteString(W, " not found")
      END
    ELSE Texts.WriteString(W, "Usage: FontUtils.ToBDF <fontName>")
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END ToBDF;

BEGIN Texts.OpenWriter(W)
END FontUtils.
