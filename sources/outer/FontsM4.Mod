MODULE Fonts; (*JG 18.11.90; PDR 8.6.12; NW 18.1.2019
  CS 30/12/2023 adapted to 8 bits per pixel*)
  IMPORT SYSTEM, Files, Display;

  CONST FontFileId = 0DBH; boxHeaderSize = 8;

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
    
VAR Default*, root*: Font;

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
    i, j, k, m, n, o, pw: INTEGER;
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
          run[k].end := end; NofBoxes := NofBoxes + end - beg; INC(k)
        END;
        NofBytes := boxHeaderSize; j := 0;
        WHILE j # NofBoxes DO
          RdInt16(R, box[j].dx); RdInt16(R, box[j].x); RdInt16(R, box[j].y);
          RdInt16(R, box[j].w); RdInt16(R, box[j].h);
          NofBytes := NofBytes + boxHeaderSize + (box[j].w + Display.NofPixperWord-1) DIV Display.NofPixperWord*4 * box[j].h;
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
            SYSTEM.PUT(a+1, box[j].dx); SYSTEM.PUT(a+2, box[j].x); SYSTEM.PUT(a+3, box[j].y);
            INC(a, 4); F.T[m] := a;
            SYSTEM.PUT(a, 0 + box[j].h*10000H + box[j].w); INC(a, 4);
            n := (box[j].w + 7) DIV 8 * box[j].h;
            WHILE n # 0 DO DEC(n); Files.ReadByte(R, b); 
              (*Convert pixels from 1 BPP to Display.NofBPP BPP*)
              o := 8;
              WHILE o >= 0 DO pw := 0; 
                FOR j := 1 TO Display.NofPixperWord DO
                  IF ODD(b) THEN INC(pw, Display.white) END; pw := ROR(pw, Display.NofBPP); b := b DIV 2
                END;
                SYSTEM.PUT(a, pw); INC(a, 4); DEC(o, Display.NofPixperWord)
              END
            END ;
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

PROCEDURE Free*;  (*remove all but first two from font list*)
BEGIN IF root.next # NIL THEN root.next.next := NIL END
END Free;

BEGIN root := NIL; Default := This("Oberon10.Scn.Fnt")
END Fonts.
