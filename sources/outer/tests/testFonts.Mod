MODULE testFonts;

  IMPORT SYSTEM, Files, Texts, Oberon;
  
  CONST FontFileId = 0DBH; boxHeaderSize = 8;
    white* = 255; NofBPP* = 8; NofPixperWord* = 32 DIV NofBPP;
    
  TYPE Font* = POINTER TO FontDesc;
    FontDesc* = RECORD
      name*: ARRAY 32 OF CHAR;
      height*, minX*, maxX*, minY*, maxY*: INTEGER;
      next*: Font;
      T: ARRAY 128 OF INTEGER;
      raster: ARRAY 20480 OF BYTE
    END ;

    LargeFontDesc = RECORD (FontDesc) ext: ARRAY 20480 OF BYTE END ;
    LargeFont = POINTER TO LargeFontDesc;
    RunRec = RECORD beg, end: BYTE END ;
    BoxRec = RECORD dx, x, y, w, h: BYTE END ;

VAR W: Texts.Writer; Default*, DefaultR5*, root*, rootR5*: Font;

PROCEDURE GetPat*(fnt: Font; ch: CHAR; VAR dx, x, y, w, h, patadr: INTEGER);
  VAR pa: INTEGER;  dxb, xb, yb: BYTE;
BEGIN pa := fnt.T[ORD(ch) MOD 80H]; patadr := pa;
  SYSTEM.GET(pa-3, dxb); SYSTEM.GET(pa-2, xb); SYSTEM.GET(pa-1, yb); SYSTEM.GET(pa, h); 
  w := h MOD 100H; h := h DIV 10000H MOD 100H;
  dx := dxb; x := xb; IF yb < 128 THEN y := yb ELSE y := yb - 256 END
END GetPat;

PROCEDURE This*(name: ARRAY OF CHAR): Font;
  VAR F: Font; LF: LargeFont;
    f: Files.File; R: Files.Rider;
    NofRuns, NofBoxes: BYTE;
    NofBytes: INTEGER;
    height, minX, maxX, minY, maxY: BYTE;
    i, j, k, m, n, o, pw, w: INTEGER;
    a, a0: INTEGER;
    b, beg, end: BYTE;
    run: ARRAY 16 OF RunRec;
    box: ARRAY 512 OF BoxRec;

  PROCEDURE RdInt16(VAR R: Files.Rider; VAR b0: BYTE);
    VAR b1: BYTE;
  BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1)
  END RdInt16;

BEGIN F := root;
  WHILE (F # NIL) & (name # F.name) DO F := F.next END;
  IF F = NIL THEN
    f := Files.Old(name);
    IF f # NIL THEN
      Files.Set(R, f, 0); Files.ReadByte(R, b);
      IF b = FontFileId THEN
        Files.ReadByte(R, b); (*abstraction*)
        Files.ReadByte(R, b); (*family*)
        Files.ReadByte(R, b); (*variant*)
        RdInt16(R, height); RdInt16(R, minX); RdInt16(R, maxX); RdInt16(R, minY); RdInt16(R, maxY); RdInt16(R, NofRuns);
        NofBoxes := 0; k := 0;
        WHILE k # NofRuns DO
          RdInt16(R, beg);
          run[k].beg := beg; RdInt16(R, end);
          run[k].end := end; NofBoxes := NofBoxes + end - beg; INC(k);
(*          Texts.WriteString(W, "Run ["); Texts.WriteInt(W, beg, 1);
          Texts.WriteString(W, ", "); Texts.WriteInt(W, end, 1); 
          Texts.WriteString(W, "["); Texts.WriteLn(W);
          Texts.Append(Oberon.Log, W.buf)*)
        END;
        NofBytes := boxHeaderSize; j := 0;
        WHILE j # NofBoxes DO
          RdInt16(R, box[j].dx); RdInt16(R, box[j].x); RdInt16(R, box[j].y);
          RdInt16(R, box[j].w); RdInt16(R, box[j].h);
          NofBytes := NofBytes + boxHeaderSize + (box[j].w + NofPixperWord-1) DIV NofPixperWord*4 * box[j].h;
(*          Texts.WriteString(W, "Boxes dx="); Texts.WriteInt(W, box[j].dx, 1);
          Texts.WriteString(W, ", x="); Texts.WriteInt(W, box[j].x, 1); 
          Texts.WriteString(W, ", y="); Texts.WriteInt(W, box[j].y, 1); 
          Texts.WriteString(W, ", w="); Texts.WriteInt(W, box[j].w, 1); 
          Texts.WriteString(W, ", h="); Texts.WriteInt(W, box[j].h, 1); 
          Texts.WriteLn(W);
          Texts.Append(Oberon.Log, W.buf);*)
          INC(j)
        END;
        IF NofBytes < 20400 THEN NEW(F) ELSE NEW(LF); F := LF END ;
        F.name := name;
        F.height := height; F.minX := minX; F.maxX := maxX; F.maxY := maxY;
        IF minY >= 80H THEN F.minY := minY - 100H ELSE F.minY := minY END ;
        a0 := SYSTEM.ADR(F.raster);
        SYSTEM.PUT(a0, 0); INC(a0, 4); SYSTEM.PUT(a0, 0);
        (*null pattern for characters not in a run*)
        a := a0+4; j := 0; k := 0; m := 0;
        WHILE k < NofRuns DO
          WHILE (m < run[k].beg) & (m < 128) DO F.T[m] := a0; INC(m) END;
          WHILE (m < run[k].end) & (m < 128) DO
            Texts.WriteString(W, "Character '"); Texts.Write(W, CHR(m));
(*            Texts.WriteString(W, "', dx="); Texts.WriteInt(W, box[j].dx, 1);
            Texts.WriteString(W, ", x="); Texts.WriteInt(W, box[j].x, 1); 
            Texts.WriteString(W, ", y="); Texts.WriteInt(W, box[j].y, 1); 
            Texts.WriteString(W, ", w="); Texts.WriteInt(W, box[j].w, 1); 
            Texts.WriteString(W, ", h="); Texts.WriteInt(W, box[j].h, 1); 
            Texts.WriteLn(W);
            Texts.Append(Oberon.Log, W.buf);*)
            Texts.WriteString(W, "', w="); Texts.WriteInt(W, box[j].w, 1); 
            Texts.WriteString(W, ", h="); Texts.WriteInt(W, box[j].h, 1); 
            Texts.WriteLn(W);
            SYSTEM.PUT(a+1, box[j].dx); SYSTEM.PUT(a+2, box[j].x); SYSTEM.PUT(a+3, box[j].y);
            INC(a, 4); F.T[m] := a;
            SYSTEM.PUT(a, 0 + box[j].h*10000H + box[j].w); INC(a, 4);
            n := (box[j].w + 7) DIV 8 * box[j].h;
            w := box[j].w;
            WHILE n # 0 DO DEC(n); Files.ReadByte(R, b); 
              (*Convert pixels from 1 BPP to Display.NofBPP BPP*)
              o := w; IF o > 8 THEN o := 8 END;
              WHILE o > 0 DO pw := 0; 
                FOR i := 1 TO NofPixperWord DO
                  IF ODD(b) THEN INC(pw, white) END; pw := ROR(pw, NofBPP); b := b DIV 2
                END;
                SYSTEM.PUT(a, pw); INC(a, 4); DEC(o, NofPixperWord); DEC(w, NofPixperWord);
                Texts.WriteHex(W, pw);
              END;
              IF w <= 0 THEN w := box[j].w; Texts.WriteLn(W) END
            END ;
            Texts.Append(Oberon.Log, W.buf);
            INC(j); INC(m)
          END;
          INC(k)
        END;
        WHILE m < 128 DO F.T[m] := a0; INC(m) END ;
        F.next := root; root := F
      ELSE (*bad file id*) F := Default
      END
    ELSE (*font file not available*) F := Default
    END
  END;
  RETURN F
END This;

PROCEDURE GetPatR5*(fnt: Font; ch: CHAR; VAR dx, x, y, w, h, patadr: INTEGER);
  VAR pa: INTEGER;  dxb, xb, yb, wb, hb: BYTE;
BEGIN pa := fnt.T[ORD(ch) MOD 80H]; patadr := pa;
  SYSTEM.GET(pa-3, dxb); SYSTEM.GET(pa-2, xb); SYSTEM.GET(pa-1, yb); SYSTEM.GET(pa, wb); SYSTEM.GET(pa+1, hb);
  dx := dxb; x := xb; y := yb; w := wb; h := hb;
  IF yb < 128 THEN y := yb ELSE y := yb - 256 END
END GetPatR5;

PROCEDURE ThisR5*(name: ARRAY OF CHAR): Font;
  VAR F: Font; LF: LargeFont;
    f: Files.File; R: Files.Rider;
    NofRuns, NofBoxes: BYTE;
    NofBytes: INTEGER;
    height, minX, maxX, minY, maxY: BYTE;
    i, j, k, m, n: INTEGER;
    a, a0: INTEGER;
    b, beg, end: BYTE;
    run: ARRAY 16 OF RunRec;
    box: ARRAY 512 OF BoxRec;

  PROCEDURE RdInt16(VAR R: Files.Rider; VAR b0: BYTE);
    VAR b1: BYTE;
  BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1)
  END RdInt16;

BEGIN F := rootR5;
  WHILE (F # NIL) & (name # F.name) DO F := F.next END;
  IF F = NIL THEN
    f := Files.Old(name);
    IF f # NIL THEN
      Files.Set(R, f, 0); Files.ReadByte(R, b);
      IF b = FontFileId THEN
        Files.ReadByte(R, b); (*abstraction*)
        Files.ReadByte(R, b); (*family*)
        Files.ReadByte(R, b); (*variant*)
        RdInt16(R, height); RdInt16(R, minX); RdInt16(R, maxX); RdInt16(R, minY); RdInt16(R, maxY); RdInt16(R, NofRuns);
        NofBoxes := 0; k := 0;
        WHILE k # NofRuns DO
          RdInt16(R, beg);
          run[k].beg := beg; RdInt16(R, end);
          run[k].end := end; NofBoxes := NofBoxes + end - beg; INC(k);
(*          Texts.WriteString(W, "RunR5 ["); Texts.WriteInt(W, beg, 1);
          Texts.WriteString(W, ", "); Texts.WriteInt(W, end, 1); 
          Texts.WriteString(W, "["); Texts.WriteLn(W);
          Texts.Append(Oberon.Log, W.buf)*)
        END;
        NofBytes := 5; j := 0;
        WHILE j # NofBoxes DO
          RdInt16(R, box[j].dx); RdInt16(R, box[j].x); RdInt16(R, box[j].y);
          RdInt16(R, box[j].w); RdInt16(R, box[j].h);
          NofBytes := NofBytes + 5 + (box[j].w + 7) DIV 8 * box[j].h;
(*          Texts.WriteString(W, "BoxesR5 dx="); Texts.WriteInt(W, box[j].dx, 1);
          Texts.WriteString(W, ", x="); Texts.WriteInt(W, box[j].x, 1); 
          Texts.WriteString(W, ", y="); Texts.WriteInt(W, box[j].y, 1); 
          Texts.WriteString(W, ", w="); Texts.WriteInt(W, box[j].w, 1); 
          Texts.WriteString(W, ", h="); Texts.WriteInt(W, box[j].h, 1); 
          Texts.WriteLn(W);
          Texts.Append(Oberon.Log, W.buf);*)
          INC(j)
        END;
        IF NofBytes < 2300 THEN NEW(F) ELSE NEW(LF); F := LF END ;
        F.name := name;
        F.height := height; F.minX := minX; F.maxX := maxX; F.maxY := maxY;
        IF minY >= 80H THEN F.minY := minY - 100H ELSE F.minY := minY END ;
        a0 := SYSTEM.ADR(F.raster);
        SYSTEM.PUT(a0, 0X); SYSTEM.PUT(a0+1, 0X); SYSTEM.PUT(a0+2, 0X); SYSTEM.PUT(a0+3, 0X); SYSTEM.PUT(a0+4, 0X);
        (*null pattern for characters not in a run*)
        INC(a0, 3); a := a0+2; j := 0; k := 0; m := 0;
        WHILE k < NofRuns DO
          WHILE (m < run[k].beg) & (m < 128) DO F.T[m] := a0; INC(m) END;
          WHILE (m < run[k].end) & (m < 128) DO
(*            Texts.WriteString(W, "CharacterR5 '"); Texts.Write(W, CHR(m));
            Texts.WriteString(W, "', dx="); Texts.WriteInt(W, box[j].dx, 1);
            Texts.WriteString(W, ", x="); Texts.WriteInt(W, box[j].x, 1); 
            Texts.WriteString(W, ", y="); Texts.WriteInt(W, box[j].y, 1); 
            Texts.WriteString(W, ", w="); Texts.WriteInt(W, box[j].w, 1); 
            Texts.WriteString(W, ", h="); Texts.WriteInt(W, box[j].h, 1); 
            Texts.WriteLn(W);
            Texts.Append(Oberon.Log, W.buf);*)
            F.T[m] := a+3;
            SYSTEM.PUT(a, box[j].dx); SYSTEM.PUT(a+1, box[j].x); SYSTEM.PUT(a+2, box[j].y);
            SYSTEM.PUT(a+3, box[j].w); SYSTEM.PUT(a+4, box[j].h); INC(a, 5);
            n := (box[j].w + 7) DIV 8 * box[j].h;
            WHILE n # 0 DO DEC(n); Files.ReadByte(R, b); SYSTEM.PUT(a, b); INC(a) END ;
            INC(j); INC(m)
          END;
          INC(k)
        END;
        WHILE m < 128 DO F.T[m] := a0; INC(m) END ;
        F.next := rootR5; rootR5 := F
      ELSE (*bad file id*) F := Default
      END
    ELSE (*font file not available*) F := Default
    END
  END;
  RETURN F
END ThisR5;

PROCEDURE test*;
  VAR dx, x, y, w, h, patadr: INTEGER;
BEGIN
  GetPat(Default, "a", dx, x, y, w, h, patadr);
  Texts.WriteString(W, "w="); Texts.WriteInt(W, w, 1);
  Texts.WriteString(W, ", h="); Texts.WriteInt(W, h, 1); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf);
  
  GetPatR5(DefaultR5, "a", dx, x, y, w, h, patadr);
  Texts.WriteString(W, "R5 w="); Texts.WriteInt(W, w, 1);
  Texts.WriteString(W, ", h="); Texts.WriteInt(W, h, 1); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf);
END test;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "test Fonts 03/01/2024");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
  root := NIL; Default := NIL; Default := This("Oberon10.Scn.Fnt");
  rootR5 := NIL; DefaultR5 := NIL; DefaultR5 := ThisR5("Oberon10.Scn.Fnt");
END testFonts.
