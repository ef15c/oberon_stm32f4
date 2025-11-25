MODULE OMSPTool;  (*NW 18.2.2013
  C. Schoffit  09.06.24*)
  IMPORT Files, Texts, Oberon, B := OMSPB, A := OMSPA, D := OMSPD, TextsEx;

  VAR W: Texts.Writer;
    Form: INTEGER;  (*result of ReadType*)
    mcode: A.ModuleCode;

  PROCEDURE Read(VAR R: Files.Rider; VAR n: INTEGER);
    VAR b: BYTE;
  BEGIN Files.ReadByte(R, b);
    IF b < 80H THEN n := b ELSE n := b - 100H END
  END Read;

  PROCEDURE ReadWord(VAR R: Files.Rider; VAR n: INTEGER);
    VAR b1, b2: BYTE;
  BEGIN Files.ReadByte(R, b1); Files.ReadByte(R, b2);
    n := b1 + b2*100H
  END ReadWord;

  PROCEDURE ReadType(VAR R: Files.Rider);
    VAR key, len, size, off: INTEGER;
      ref, class, form, readonly: INTEGER;
      name, modname: ARRAY 32 OF CHAR;
  BEGIN Read(R, ref); Texts.Write(W, " "); Texts.Write(W, "[");
    IF ref < 0 THEN Texts.Write(W, "^"); Texts.WriteInt(W, -ref, 1);
      IF -ref IN {B.Array, B.Record} THEN form := 0 ELSE form := -ref END
    ELSE Texts.WriteInt(W, ref, 1);
      Read(R, form); Texts.WriteString(W, "  form = "); Texts.WriteInt(W, form, 1);
      IF form = B.Pointer THEN ReadType(R)
      ELSIF form = B.Array THEN
        ReadType(R); Files.ReadNum(R, len); Texts.WriteString(W, "  len = "); Texts.WriteInt(W, len, 1);
        Files.ReadNum(R, size); Texts.WriteString(W, "  size = "); Texts.WriteInt(W, size, 1);
      ELSIF form = B.Record THEN
        ReadType(R); (*base type*) Texts.Write(W, "{"); 
        Files.ReadNum(R, off); Texts.WriteString(W, "  exno = "); Texts.WriteInt(W, off, 1); 
        Files.ReadNum(R, off); Texts.WriteString(W, "  extlev = "); Texts.WriteInt(W, off, 1);
        Files.ReadNum(R, size); Texts.WriteString(W, "  size = "); Texts.WriteInt(W, size, 1);
        Texts.Write(W, " "); Texts.Write(W, "{"); Read(R, class);
        WHILE class # 0 DO (*fields*)
          Files.ReadString(R, name);
          IF name[0] # 0X THEN Texts.Write(W, " "); Texts.WriteString(W, name); ReadType(R)
          ELSE Texts.WriteString(W, " --")
          END ;
          Files.ReadNum(R, off); Texts.WriteInt(W, off, 4); Read(R, class)
        END ;
        Texts.Write(W, "}")
      ELSIF form = B.Proc THEN
        ReadType(R); Read(R, class); IF class = 1 THEN Texts.WriteString(W, " leaf") END;
        Files.ReadInt(R, off); Texts.WriteString(W, " UR"); TextsEx.WriteHexVLen(W, off, 4, FALSE);
        Texts.Write(W, "("); Read(R, class);
        WHILE class # 0 DO
          Texts.WriteString(W, " class = "); Texts.WriteInt(W, class, 1); Read(R, readonly);
          IF readonly = 1 THEN Texts.Write(W, "#") END;
          Read(R, off); IF off # -1 THEN Texts.WriteString(W, " R"); Texts.WriteInt(W, off, 1) END;
          ReadType(R); Read(R, class)
        END ;
        Texts.Write(W, ")")
      END ;
      Files.ReadString(R, modname);
      IF modname[0] # 0X THEN
        Files.ReadInt(R, key); Files.ReadString(R, name);
        Texts.Write(W, " "); Texts.WriteString(W, modname); Texts.Write(W, "."); Texts.WriteString(W, name);
        Texts.WriteHex(W, key)
      END
    END ;
    Form := form; Texts.Write(W, "]")
  END ReadType;

  PROCEDURE DecSym*;  (*decode symbol file*)
    VAR class, k: INTEGER;
      name: ARRAY 32 OF CHAR;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "decode "); Texts.WriteString(W, S.s);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      F := Files.Old(S.s);
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadInt(R, k); Files.ReadInt(R, k);
        Files.ReadString(R, name); Texts.WriteString(W, name); Texts.WriteHex(W, k);
        Read(R, class); Texts.WriteInt(W, class, 3); (*sym file version*)
        IF class = B.versionkey THEN
          Texts.WriteLn(W); Read(R, class);
          WHILE class # 0 DO
            Texts.WriteInt(W, class, 4); Files.ReadString(R, name); Texts.Write(W, " "); Texts.WriteString(W, name);
            ReadType(R);
            IF class = B.Typ THEN
              Texts.Write(W, "("); Read(R, class);
              WHILE class # 0 DO  (*pointer base fixup*)
                Texts.WriteString(W, " ->"); Texts.WriteInt(W, class, 4); Read(R, class)
              END ;
              Texts.Write(W, ")")
            ELSIF class = B.Const THEN
              IF Form = B.String THEN Files.ReadInt(R, k); Texts.WriteInt(W, k DIV 10000H, 6); (*len*) k := k MOD 10000H
              ELSE Files.ReadNum(R, k)
              END; Texts.WriteInt(W, k, 8);
            ELSIF class IN {B.Var, B.StoredConst} THEN
              Files.ReadNum(R, k); Texts.WriteInt(W, k, 6) (*exno*)
            END;
            Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
            Read(R, class)
          END
        ELSE Texts.WriteString(W, " bad symfile version")
        END
      ELSE Texts.WriteString(W, " not found")
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END DecSym;

(*---------------------------------------------------*)

  PROCEDURE DecObj*;   (*decode object file*)
    VAR i, n, key, adr, data, size, no: INTEGER;
      bl: BYTE;
      ch: CHAR;
      name: ARRAY 32 OF CHAR;
      F!: Files.File; R!: Files.Rider;
      S1!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S1, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S1);
    IF S1.class = Texts.Name THEN
      Texts.WriteString(W, "decode "); Texts.WriteString(W, S1.s); F := Files.Old(S1.s);
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name); Texts.WriteLn(W); Texts.WriteString(W, name);
        Files.ReadInt(R, key); Texts.WriteHex(W, key); Files.ReadByte(R, bl);
        IF bl IN {4..5} THEN bl := bl MOD 2;
          IF bl = 1 THEN Texts.WriteString(W, "code executed from RAM"); Texts.WriteLn(W); END;
          Texts.Append(Oberon.Log, W.buf); Texts.WriteLn(W);
          Texts.WriteString(W, "imports:"); Texts.WriteLn(W); Files.ReadString(R, name);
          WHILE name[0] # 0X DO
            Texts.Write(W, 9X); Texts.WriteString(W, name);
            Files.ReadInt(R, key); Texts.WriteHex(W, key); Texts.WriteLn(W);
            Files.ReadString(R, name)
          END; Texts.WriteLn(W);
          Files.Read(R, ch); no := 0;
          WHILE ~R.eof & (ch # 0X) DO Texts.WriteString(W, "section "); Texts.WriteInt(W, no, 5);
            Texts.Write(W, 09X); Texts.Write(W, ch);
            Files.ReadString(R, name); ReadWord(R, size);
            Texts.WriteInt(W, size, 5); Texts.Write(W, 09X);
            Texts.WriteString(W, name); Texts.WriteLn(W);
            IF ch = "c" THEN (*code section*) A.Init(mcode); (*read code*)
              FOR i := 0 TO size - 1 DO Files.ReadByte(R, mcode.code[i]) END;
              i := 0;
              WHILE i < size DO
                TextsEx.WriteHexVLen(W, i, 4, FALSE);
                Texts.Write(W, 9X); adr := i + 2;
                D.opcode(W, mcode.code, i, 0); Texts.WriteLn(W);
                FOR n := adr TO i - 2 BY 2 DO (*print operation data*)
                  TextsEx.WriteHexVLen(W, n, 4, FALSE);
                  Texts.Write(W, 9X); Texts.WriteString(W, "    ");
                  data := mcode.code[n+1]*100H + mcode.code[n];
                  TextsEx.WriteHexVLen(W, data, 4, FALSE); Texts.WriteLn(W)
                END
              END;
            ELSIF ch = "v" THEN i := 0;
              WHILE i < size DIV 2 DO ReadWord(R, adr); TextsEx.WriteHexVLen(W, adr, 4, FALSE);
                IF (i + 1) MOD 10H = 0 THEN Texts.WriteLn(W) END; INC(i)
              END;
              IF i MOD 10H # 0 THEN Texts.WriteLn(W) END
            ELSIF ch # "r" THEN i := 0;
              WHILE i < size DO Files.ReadByte(R, bl); TextsEx.WriteHexVLen(W, bl, 2, FALSE);
                IF (i + 1) MOD 10H = 0 THEN Texts.WriteLn(W) END; INC(i)
              END;
              IF i MOD 10H # 0 THEN Texts.WriteLn(W) END
            END;
            Texts.WriteString(W, "fixups:"); Texts.WriteLn(W);
            ReadWord(R, adr);
            WHILE adr # 0 DO TextsEx.WriteHexVLen(W, adr, 4, FALSE); Texts.Write(W, 09X);
              Files.ReadByte(R, bl); Texts.Write(W, "s"); Texts.WriteInt(W, bl, 1);
              ReadWord(R, n); Texts.Write(W, "."); Texts.WriteInt(W, n, 1);
              ReadWord(R, n);
              IF n # 0 THEN IF n > 0 THEN  Texts.Write(W, "+") END;
                Texts.WriteInt(W, n, 1)
              END;
              Texts.WriteLn(W);
              ReadWord(R, adr)
            END;
            Texts.WriteLn(W);
            INC(no); Files.Read(R, ch)
          END;
          Texts.WriteString(W, "entries:"); Texts.WriteLn(W);
          ReadWord(R, n); i := 0;
          WHILE i < n DO
            ReadWord(R, no); Texts.WriteInt(W, no, 5);
            IF (i + 1) MOD 10 = 0 THEN Texts.WriteLn(W) END;
            INC(i)
          END;
          IF i MOD 10 # 0 THEN Texts.WriteLn(W) END;
          Files.Read(R, ch); IF ch # "O" THEN Texts.WriteString(W, "format error"); Texts.WriteLn(W) END;
        ELSE Texts.WriteString(W, " bad version"); Texts.WriteLn(W)
        END
      ELSE Texts.WriteString(W, " not found"); Texts.WriteLn(W)
      END ;
      Texts.Append(Oberon.Log, W.buf)
    END
  END DecObj;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OMSPTool 21.10.25");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END OMSPTool.
