MODULE TextTools; (*Text utilities, C. Schoffit 29.07.26*)
  IMPORT Files, Texts, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE ToRaw*;
    VAR S!: Texts.Scanner; source, dest: ARRAY 32 OF CHAR;
      T!: Texts.Text; r!: Texts.Reader; D!: Files.File; R!: Files.Rider; ch: CHAR;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF ~(S.class IN {Texts.String, Texts.Name}) THEN Texts.WriteString(W, "invalid source file")
    ELSE source := S.s; Texts.Scan(S);
      IF ~(S.class IN {Texts.String, Texts.Name}) THEN Texts.WriteString(W, "invalid destination file")
      ELSE dest := S.s; NEW(T); Texts.Open(T, source); D := Files.New(dest);
        IF D = NIL THEN Texts.WriteString(W, "cannot create dest file")
        ELSE Files.Set(R, D, 0); Texts.OpenReader(r, T, 0);
          Texts.Read(r, ch);
          WHILE ~r.eot DO IF ch = 0DX THEN ch := Texts.CR END;
            Files.Write(R, ch); Texts.Read(r, ch)
          END;
          Files.Register(D);
          Texts.WriteString(W, "rich text converted to raw file")
        END
      END
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END ToRaw;

BEGIN Texts.OpenWriter(W)
END TextTools.

OM4P.Compile TextTools.Mod~
System.Free TextTools~

TextTools.ToRaw TextTools.Mod TextTools.Mod.raw
