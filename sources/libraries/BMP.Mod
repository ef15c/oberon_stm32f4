MODULE BMP;
  IMPORT Files, FilesEx, Display, Texts, TextsEx;

  TYPE Header* = RECORD signature*: ARRAY 3 OF CHAR; filesize*, dataoffset*: INTEGER END;
    DIBHeader* = RECORD size*, width*, height*, planes*, bitcount*, compression*, imagesize*,
      hres*, vres*, nbpalcol*, nbimportantcol*: INTEGER END;
    ImageFrame* = RECORD w*, h*, x*, y*, ix*, iy*: INTEGER END;
    ColorTable* = ARRAY 256 OF INTEGER; ColorMap* = ARRAY 256 OF BYTE;

  PROCEDURE ReadHeader*(VAR R: Files.Rider; VAR h: Header);
    VAR dummy: INTEGER;
  BEGIN Files.Set(R, Files.Base(R), 0); (*Move to beginning of file*)
    Files.Read(R, h.signature[0]); Files.Read(R, h.signature[1]); h.signature[2] := 0X;
    IF h.signature = "BM" THEN Files.ReadInt(R, h.filesize); Files.ReadInt(R, dummy); Files.ReadInt(R, h.dataoffset)
    ELSE h.signature[0] := 0X (*not supported*)
    END
  END ReadHeader;

  PROCEDURE ReadDIBHeader*(VAR R: Files.Rider; VAR h: DIBHeader);
    VAR i, dummy: INTEGER;
  BEGIN (*assume the rider is at the right position*)
    Files.ReadInt(R, h.size);
    IF h.size >= 40 THEN Files.ReadInt(R, h.width); Files.ReadInt(R, h.height);
      FilesEx.ReadHalfWord(R, h.planes); FilesEx.ReadHalfWord(R, h.bitcount); 
      Files.ReadInt(R, h.compression);
      IF (h.bitcount # 8) OR ~(h.compression IN {0, 1}) THEN h.size := 0 (*not supported*) END;
      Files.ReadInt(R, h.imagesize);
      Files.ReadInt(R, h.hres); Files.ReadInt(R, h.vres);
      Files.ReadInt(R, h.nbpalcol); Files.ReadInt(R, h.nbimportantcol);
      i := 40; WHILE i < h.size DO Files.ReadInt(R, dummy); INC(i, 4) END
    ELSE h.size := 0 (*not supported*)
    END
  END ReadDIBHeader;

  PROCEDURE ReadColorTable*(VAR R: Files.Rider; h: DIBHeader; VAR ct: ColorTable);
    VAR i: INTEGER;
  BEGIN FOR i := 0 TO h.nbpalcol - 1 DO Files.ReadInt(R, ct[i]) END
  END ReadColorTable;

  PROCEDURE DisplayImage*(VAR R: Files.Rider; bh: Header; dh: DIBHeader; cm: ColorMap; fr: ImageFrame);
    VAR i, j, c: INTEGER; count, value, pixel: BYTE;
  BEGIN Files.Set(R, Files.Base(R), bh.dataoffset); ASSERT(dh.bitcount = 8);
    IF dh.compression = 0 THEN (*no compression*)
      FOR i := 0 TO fr.iy + fr.h - 1 DO j := 0;
        WHILE j < dh.width DO Files.ReadByte(R, pixel);
          IF (i >= fr.iy) & (j >= fr.ix) & (j < fr.ix + fr.w) THEN Display.Dot(cm[pixel], fr.x - fr.ix + j, fr.y - fr.iy + i, Display.replace) END;
          INC(j)
        END; WHILE j MOD 4 # 0 DO Files.ReadByte(R, pixel); INC(j) END
      END
    ELSE (*RLE8 compression*) i := 0; j := 0;
      REPEAT Files.ReadByte(R, count); Files.ReadByte(R, value);
        IF ~R.eof THEN
          IF count = 0 THEN (*escape value*)
            IF value = 0 THEN (*end of line*) j := 0; INC(i)
            ELSIF value = 1 THEN (*end of image*) i := fr.iy + fr.h
            ELSIF value = 2 THEN (*jump*) Files.ReadByte(R, value); INC(i, value); Files.ReadByte(R, value); INC(j, value)
            ELSE (*absolute mode*) c := 0;
              WHILE c < value DO Files.ReadByte(R, pixel);
                IF (i >= fr.iy) & (j >= fr.ix) & (j < fr.ix + fr.w) THEN Display.Dot(cm[pixel], fr.x - fr.ix + j, fr.y - fr.iy + i, Display.replace) END;
                INC(j); INC(c)
              END;
              WHILE c MOD 2 # 0 DO Files.ReadByte(R, pixel); INC(c) END
            END
          ELSE (*encoded mode*)
            IF i >= fr.iy THEN
              IF (j + count >= fr.ix) & (j < fr.ix + fr.w) THEN IF j < fr.ix THEN DEC(count, fr.ix - j); j := fr.ix END;
                c := count; IF j + c >= fr.ix + fr.w THEN c := fr.ix + fr.w - j END; DEC(count, c);
                Display.ReplConst(cm[value], fr.x - fr.ix + j, fr.y - fr.iy + i, c, 1, Display.replace); INC(j, c)
              END
            END; INC(j, count)
          END
        END
      UNTIL i >= fr.iy + fr.h
    END

  END DisplayImage;

  PROCEDURE DumpImage*(VAR R: Files.Rider; bh: Header; dh: DIBHeader; n: INTEGER; VAR W: Texts.Writer);
    VAR i, j, c: INTEGER; count, value, pixel: BYTE;
  BEGIN Files.Set(R, Files.Base(R), bh.dataoffset); ASSERT(dh.bitcount = 8);
    IF dh.compression = 0 THEN (*no compression*)
      FOR i := 0 TO n - 1 DO Texts.WriteString(W, "line "); Texts.WriteInt(W, i, 1); Texts.WriteLn(W); j := 0;
        WHILE j < dh.width DO Files.ReadByte(R, pixel); TextsEx.WriteHexVLen(W, pixel, 2, TRUE);
          IF j MOD 16 = 15 THEN Texts.WriteLn(W) END; INC(j)
        END; WHILE j MOD 4 # 0 DO Files.ReadByte(R, pixel); INC(j) END;
        Texts.WriteLn(W)
      END
    ELSE (*RLE8 compression*) i := 0; j := 0; Texts.WriteString(W, "line "); Texts.WriteInt(W, i, 1); Texts.WriteLn(W);
      REPEAT Files.ReadByte(R, count); Files.ReadByte(R, value);
        IF ~R.eof THEN
          IF count = 0 THEN (*escape value*)
            IF value = 0 THEN (*end of line*) ASSERT(j = dh.width); j := 0; INC(i);
              Texts.WriteLn(W); Texts.WriteString(W, "line "); Texts.WriteInt(W, i, 1); Texts.WriteLn(W)
            ELSIF value = 1 THEN (*end of image*) i := n
            ELSIF value = 2 THEN (*jump*) ASSERT(FALSE)
            ELSE (*absolute mode*)
              FOR c := 1 TO value DO Files.ReadByte(R, pixel);
                TextsEx.WriteHexVLen(W, pixel, 2, TRUE); IF j MOD 16 = 15 THEN Texts.WriteLn(W) END;
                INC(j)
              END;
              WHILE c MOD 2 # 0 DO Files.ReadByte(R, pixel); INC(c) END
            END
          ELSE (*encoded mode*)
            REPEAT TextsEx.WriteHexVLen(W, value, 2, TRUE); IF j MOD 16 = 15 THEN Texts.WriteLn(W) END;
              INC(j); DEC(count)
            UNTIL count = 0
          END
        END
      UNTIL i >= n
    END
  END DumpImage;

  PROCEDURE TakeScreenShot*(VAR R: Files.Rider);
    VAR i, j, k, r, g, b: INTEGER; l: Display.Line; count, value: INTEGER; pos: INTEGER;
  BEGIN (*write header*)
    Files.Write(R, "B"); Files.Write(R, "M"); Files.WriteInt(R, 0); (*placeholder for file size, offset 2*); Files.WriteInt(R, 0);
    Files.WriteInt(R, 14 + 40 + 256*4); (*data offset*)
    (*write DIB header*)
    Files.WriteInt(R, 40); (*BITMAPINFOHEADER*) Files.WriteInt(R, Display.Width); Files.WriteInt(R, Display.Height);
    FilesEx.WriteHalfWord(R, 1); FilesEx.WriteHalfWord(R, 8); Files.WriteInt(R, 1);
    Files.WriteInt(R, 0); (*placeholder for image data size, offset 34 *) Files.WriteInt(R, 2835); Files.WriteInt(R, 2835);
    Files.WriteInt(R, 256); Files.WriteInt(R, 256);
    (*write palette*)
    FOR i := 0 TO 255 DO r := LSR(i, 5) MOD 8; g := LSR(i, 2) MOD 8; b := i MOD 4;
      Files.WriteInt(R, LSL(r*255 DIV 7, 16) + LSL(g*255 DIV 7, 8) + b*255 DIV 3)
    END;
    (*write image data*)
    FOR i := 0 TO Display.Height - 1 DO Display.GetLine(i, l); j := 0;
      WHILE j < Display.Width DO value := l[j]; count := 0;
        REPEAT INC(count); INC(j) UNTIL (j >= Display.Width) OR (l[j] # value) OR (count = 0FFH);
        IF count > 1 THEN Files.WriteByte(R, count); Files.WriteByte(R, value) (*encoded data*)
        ELSE k := j; WHILE (k < Display.Width - 1) & (l[k] # l[k + 1]) & (count # 0FFH) DO INC(count); INC(k) END;
          IF count = 1 THEN Files.WriteByte(R, count); Files.WriteByte(R, value) (*encoded data one byte*)
          ELSE IF count = 2 THEN INC(k); count := 3 END; (*count must be 3 at least*)
            Files.WriteByte(R, 0); Files.WriteByte(R, count);
            IF ODD(count) THEN INC(count) END; (*padding current run to 16 bit*)
            DEC(j); WHILE (j < Display.Width) & (j < k) DO Files.WriteByte(R, l[j]); INC(j); DEC(count) END;
            WHILE count > 0 DO Files.WriteByte(R, 0); DEC(count) END; (*padding bytes*)
          END
        END
      END; Files.WriteByte(R, 0); Files.WriteByte(R, 0) (*end of line*)
    END; Files.WriteByte(R, 0); Files.WriteByte(R, 1); (*end of image*)
    pos := Files.Pos(R); Files.Set(R, Files.Base(R), 2); Files.WriteInt(R, pos); (*fix file size placeholder*)
    Files.Set(R, Files.Base(R), 34); Files.WriteInt(R, pos - 14 + 40 + 256*4) (*and image datasize placeholder*)
  END TakeScreenShot;

END BMP.

OM4P.Compile BMP.Mod/s~
