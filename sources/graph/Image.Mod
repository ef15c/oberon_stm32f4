MODULE Image;
  IMPORT Files, Display, Viewers, Texts, Oberon, MenuViewers, TextFrames, BMP;

  CONST Menu = "System.Close  System.Copy  System.Grow";

  TYPE Frame = POINTER TO FrameDesc;
    FrameDesc = RECORD(Display.FrameDesc)
      R: Files.Rider
    END;

  VAR W: Texts.Writer;

  PROCEDURE shiftR(v: INTEGER; n: INTEGER): INTEGER;
  BEGIN ASSERT(n > 0); v := LSR(v, n-1);
    IF ODD(v) THEN v := ORD(LSR(TOSET(v), 1) + {0}) ELSE v := LSR(v, 1) END

    RETURN v
  END shiftR;

  PROCEDURE buildColorMap(ct: BMP.ColorTable; VAR cm: BMP.ColorMap; nb: INTEGER);
    VAR r, g, b, i: INTEGER;
  BEGIN
    FOR i := 0 TO nb - 1 DO r := LSR(ct[i], 16) MOD 100H; g := LSR(ct[i], 8) MOD 100H; b := ct[i] MOD 100H;
      cm[i] := LSL(shiftR(r, 5), 5) + LSL(shiftR(g, 5), 2) + shiftR(b, 6)
    END
  END buildColorMap;

  PROCEDURE getFile(VAR name: ARRAY OF CHAR): Files.File;
    VAR S!: Texts.Scanner; F!: Files.File; i: INTEGER;
  BEGIN F := NIL; Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN i := 0; WHILE S.s[i] # 0X DO name[i] := S.s[i]; INC(i) END; name[i] := 0X;
      F := Files.Old(name); IF F = NIL THEN Texts.WriteString(W, "file not found"); Texts.WriteLn(W) END
    ELSE Texts.WriteString(W, "file name missing"); Texts.WriteLn(W)
    END;
    Texts.Append(Oberon.Log, W.buf)

    RETURN F
  END getFile;

  PROCEDURE Infos*;
    VAR F!: Files.File; R!: Files.Rider; name: ARRAY 32 OF CHAR;
      h: BMP.Header; dh: BMP.DIBHeader; ct: BMP.ColorTable;
      i: INTEGER; cm: BMP.ColorMap;
    oldCol: INTEGER;
  BEGIN F := getFile(name);
    IF F # NIL THEN Files.Set(R, F, 0); Texts.WriteString(W, name); BMP.ReadHeader(R, h);
      IF h.signature[0] # 0X THEN Texts.WriteString(W, " file size"); Texts.WriteInt(W, h.filesize, 8);
        Texts.WriteString(W, ", data offset"); Texts.WriteInt(W, h.dataoffset, 8);
        Texts.WriteLn(W); BMP.ReadDIBHeader(R, dh);
        IF dh.size # 0 THEN
          Texts.WriteString(W, "DIB header size"); Texts.WriteInt(W, dh.size, 8);
          Texts.WriteLn(W);
          Texts.WriteString(W, "width"); Texts.WriteInt(W, dh.width, 8);
          Texts.WriteString(W, ", height"); Texts.WriteInt(W, dh.height, 8);
          Texts.WriteLn(W);
          Texts.WriteString(W, "planes"); Texts.WriteInt(W, dh.planes, 8);
          Texts.WriteString(W, ", bitcount"); Texts.WriteInt(W, dh.bitcount, 8);
          Texts.WriteLn(W);
          Texts.WriteString(W, "compression"); Texts.WriteInt(W, dh.compression, 8);
          Texts.WriteString(W, ", imagesize"); Texts.WriteInt(W, dh.imagesize, 8);
          Texts.WriteLn(W);
          Texts.WriteString(W, "horizontal resolution"); Texts.WriteInt(W, dh.hres, 8);
          Texts.WriteString(W, ", vertical resolution"); Texts.WriteInt(W, dh.vres, 8);
          Texts.WriteLn(W);
          Texts.WriteString(W, "number of palette colors"); Texts.WriteInt(W, dh.nbpalcol, 8);
          Texts.WriteString(W, ", number of important colors"); Texts.WriteInt(W, dh.nbimportantcol, 8);
          Texts.WriteLn(W); BMP.ReadColorTable(R, dh, ct); buildColorMap(ct, cm, dh.nbpalcol);
          Texts.WriteString(W, "color table (CLUT index):"); Texts.WriteLn(W);
          FOR i := 0 TO dh.nbpalcol - 1 DO Texts.WriteHex(W, ct[i]); Texts.WriteString(W, " (");
            oldCol := W.col; W.col := cm[i]; Texts.WriteInt(W, cm[i], 3); W.col := oldCol;
            Texts.Write(W, ")");
            IF i MOD 4 = 3 THEN Texts.WriteLn(W) END
          END; Texts.WriteLn(W);
          Texts.WriteString(W, "file pos"); Texts.WriteInt(W, Files.Pos(R), 8);
          Texts.WriteLn(W); BMP.DumpImage(R, h, dh, 10, W)
        ELSE Texts.WriteString(W, "format not supported"); Texts.WriteLn(W)
        END
      ELSE Texts.WriteString(W, "format not supported"); Texts.WriteLn(W)
      END
    END;
    Texts.Append(Oberon.Log, W.buf)
  END Infos;

  PROCEDURE WriteInt(label: ARRAY OF CHAR; val: INTEGER);
  BEGIN Texts.WriteString(W, label); Texts.WriteInt(W, val, 1)
  END WriteInt;

  PROCEDURE ShowImage(F: Frame);
    VAR bh: BMP.Header; dh: BMP.DIBHeader; ct: BMP.ColorTable; cm: BMP.ColorMap; fr: BMP.ImageFrame;
  BEGIN Display.ReplConst(24H, F.X, F.Y, F.W, F.H, Display.replace);
    BMP.ReadHeader(F.R, bh); BMP.ReadDIBHeader(F.R, dh); BMP.ReadColorTable(F.R, dh, ct);
    buildColorMap(ct, cm, dh.nbpalcol);
    IF (bh.signature[0] # 0X) & (dh.size # 0) THEN
      fr.x := F.X; fr.y := F.Y; fr.w := F.W; fr.h := F.H; fr.ix := 0; fr.iy := 0;
      IF dh.width > fr.w THEN (*crop image*) fr.ix := (dh.width - fr.w) DIV 2
      ELSE (*center image*) INC(fr.x, (fr.w - dh.width) DIV 2); fr.w := dh.width
      END;
      IF dh.height > fr.h THEN (*crop image*) fr.iy := (dh.height - fr.h) DIV 2
      ELSE (*center image*) INC(fr.y, (fr.h - dh.height) DIV 2); fr.h := dh.height
      END;
      IF fr.h > 0 THEN BMP.DisplayImage(F.R, bh, dh, cm, fr) END
    END;
  END ShowImage;

  PROCEDURE Handler(F: Display.Frame; VAR M: Display.FrameMsg);
    VAR F0!: Frame;
  BEGIN CASE M OF
      Oberon.InputMsg: IF M.id = Oberon.track THEN Oberon.DrawMouseArrow(M.X, M.Y) END
    | MenuViewers.ModifyMsg: F.Y := M.Y; F.H := M.H; ShowImage(F(Frame))
    | Oberon.ControlMsg: IF M.id = Oberon.neutralize THEN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H) END
    | Oberon.CopyMsg: NEW(F0); F0^ := F(Frame)^; M.F := F0
    END
  END Handler;

  PROCEDURE New(): Frame;
    VAR F!: Frame;
  BEGIN NEW(F); F.handle := Handler

    RETURN F
  END New;

  PROCEDURE Show*;
    VAR F!: Files.File; name: ARRAY 32 OF CHAR;
      V!: Viewers.Viewer; X, Y: INTEGER; Fr!: Frame;
  BEGIN F := getFile(name);
    IF F # NIL THEN Fr := New(); Files.Set(Fr.R, F, 0);
      Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
      V := MenuViewers.New(TextFrames.NewMenu(name, Menu), Fr, TextFrames.menuH, X, Y)
    END
  END Show;

  PROCEDURE toHexa(val: BYTE): CHAR;
    VAR res: CHAR;
  BEGIN
    IF val<10 THEN res := CHR(val + ORD("0"))
    ELSIF val<16 THEN res := CHR(val+(ORD("A")-10))
    ELSE res := "?"
	END

    RETURN res
  END toHexa;

  PROCEDURE ScreenShot*;
    VAR name: ARRAY 32 OF CHAR; F!: Files.File; R!: Files.Rider;
      i, dt: INTEGER;
  BEGIN name := "screenshot"; dt := Oberon.Clock(); i := 10;
    REPEAT name[i] := toHexa(dt MOD 10H); dt := LSR(dt, 4); INC(i) UNTIL dt = 0;
    name[i] := "."; name[i+1] := "b"; name[i+2] := "m"; name[i+3] := "p"; name[i+4] := 0X;
    Texts.WriteString(W, name);
    F := Files.New(name);
    IF F # NIL THEN Files.Set(R, F, 0); BMP.TakeScreenShot(R); Files.Register(F)
    ELSE Texts.WriteString(W, " failed")
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END ScreenShot;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Image tool   C. Schoffit 19.04.25");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END Image.

OM4P.Compile BMP.Mod/s Image.Mod/s~
System.Free Image BMP~
Image.Show img8bpprle.bmp
Image.Infos img8bpprle.bmp

Image.Show img8bpp.bmp
Image.Infos img8bpp.bmp

Image.ScreenShot
