MODULE OM4X;  (*Oberon boot converter for RISC / AP 13.6.20 / CS 11/12/2023*)
  IMPORT Files, Texts, Oberon;
  CONST CR = 0DX; noerr = 0; badfile = 4;  (*copied from Modules for use as cross development tool*)

  TYPE record = RECORD
      t, l: BYTE;
      a: ARRAY 2 OF BYTE;
      d: ARRAY 16 OF BYTE
    END;
    
    Writer = PROCEDURE(VAR R: Files.Rider; r: record);

  VAR res*: INTEGER;
    W: Texts.Writer;

  PROCEDURE WriteBinary(VAR R: Files.Rider; r: record);  (*write a record in binary format*)
    VAR i: INTEGER;
  BEGIN
    IF r.t = 0 THEN FOR i:= 0 TO r.l-1 DO Files.WriteByte(R, r.d[i]) END
    END
  END WriteBinary;

  PROCEDURE WriteHex(VAR R: Files.Rider; x: BYTE);  (*write a byte in 2 digit hex format*)
    VAR i: INTEGER; y: LONGINT;
      a: ARRAY 2 OF CHAR;
  BEGIN i := 0;
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END ;
      x := x DIV 10H; INC(i)
    UNTIL i = 2;
    REPEAT DEC(i); Files.Write(R, a[i]) UNTIL i = 0 ;
  END WriteHex;

  PROCEDURE WriteString(VAR R: Files.Rider; x: ARRAY OF CHAR);  (*write a string without trailing null character*)
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE x[i] # 0X DO Files.Write(R, x[i]); INC(i) END
  END WriteString;

  PROCEDURE WriteIntelHex(VAR R: Files.Rider; r: record);  (*write a record in Intel HEX file format*)
    VAR cs: BYTE;
      i: INTEGER;
  BEGIN cs := 0; Files.Write(R, ":");
    WriteHex(R, r.l); WriteHex(R, r.a[0]); WriteHex(R, r.a[1]); WriteHex(R, r.t);
    INC(cs, r.l + r.a[0] + r.a[1] + r.t);
    FOR i:= 0 TO r.l-1 DO WriteHex(R, r.d[i]); INC(cs, r.d[i]) END;
    WriteHex(R, 256-cs); Files.Write(R, CR)
  END WriteIntelHex;

  PROCEDURE WriteAsmLine(VAR R: Files.Rider; r: record);  (*write a record in binary format*)
    VAR i: INTEGER;
  BEGIN
    IF r.t = 0 THEN WriteString(R, "  .byte ");
      FOR i:= 0 TO r.l-1 DO IF i # 0 THEN WriteString(R, ", ") END;
        WriteString(R, "0X"); WriteHex(R, r.d[i]) END
    END; Files.Write(R, CR)
  END WriteAsmLine;

  PROCEDURE SetAddress(VAR a: ARRAY OF BYTE; ad: INTEGER);
  BEGIN
    a[0] := ad DIV 100H MOD 100H;
    a[1] := ad MOD 100H
  END SetAddress;
  
  PROCEDURE OutCode(VAR R, R1: Files.Rider; write: Writer; loadaddress: INTEGER; VAR codelen, entry, res: INTEGER);
    VAR n, data: INTEGER; ch: CHAR; b: BYTE;               (*codelen in bytes, entry in bytes*)
      F: Files.File;
      name: ARRAY 32 OF CHAR;
      r: record;
      la, lah: INTEGER;
  BEGIN F := Files.Base(R); Files.ReadString(R, name); Files.ReadInt(R, data); (*key*)
    Files.ReadByte(R, b); (*version*) Files.ReadInt(R, data); (*size*)
    Files.ReadString(R, name); (*imports*)
    WHILE ~R.eof & (name[0] # 0X) DO Files.ReadInt(R, data); (*key*) Files.ReadString(R, name) END ;
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n); (*type descriptors*)
    Files.ReadInt(R, n); (*variable space*)
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n); (*strings*)
    Files.ReadInt(R, codelen); n := 0; la := loadaddress; lah := 0; 
    r.t := 0; r.l := 0; SetAddress(r.a, la);
    WHILE ~R.eof & (n < codelen) DO
      IF la DIV 10000H MOD 10000H # lah THEN
        (*Write pending record*)
        IF r.l # 0 THEN write(R1, r) END;
        lah := la DIV 10000H MOD 10000H;
        (*Write extended linear address record with upper 16-bits of the load address*)
        r.t := 4; r.l := 2; r.a[0] := 0; r.a[1] := 0;
        r.d[0] := lah DIV 100H MOD 100H; r.d[1] := lah MOD 100H; write(R1, r);
        r.l := 0; SetAddress(r.a, la); r.t := 0; (*prepare for data record*);
      END;
      Files.ReadByte(R, r.d[r.l]); INC(r.l); INC(n); INC(la);
      IF r.l = LEN(r.d) THEN (*data array is full: output the line*)
        write(R1, r); r.l := 0; SetAddress(r.a, la)
      END
    END ; (*write code*)
    IF r.l # 0 THEN write(R1, r) (*data array is not empty: output the line*) END;
    Files.ReadString(R, name);
    WHILE ~R.eof & (name[0] # 0X) DO Files.ReadInt(R, data); Files.ReadString(R, name) END ; (*commands*)
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n*4); (*entries*)
    Files.ReadInt(R, data);
    WHILE ~R.eof & (data >= 0) DO Files.ReadInt(R, data) END ; (*pointer references*)
    Files.ReadInt(R, data); (*fixorgP*) Files.ReadInt(R, data); (*fixorgD*)
    Files.ReadInt(R, data); (*fixorgT*) Files.ReadInt(R, entry);
    (*write start linear address record (MDK-ARM only)*)
    la := loadaddress + entry + 1; (*Odd value means thumb mode*)
    r.t := 5; r.a[0] := 0; r.a[1] := 0; r.l := 4; r.d[0] := la DIV 1000000H MOD 100H;
    r.d[1] := la DIV 10000H MOD 100H; r.d[2] := la DIV 100H MOD 100H;
    r.d[3] := la MOD 100H; write(R1, r);
    Files.Read(R, ch);
    IF ch # "O" THEN res := badfile ELSE res := noerr END;
    (*write End-of-File (EOF) Record*)
    r.t := 1; r.l := 0; write(R1, r)
  END OutCode;

  PROCEDURE WriteFile*;  (*write code section of M.m4c in hex format to output file*)
    VAR f, g: Files.File; Rf, Rg: Files.Rider;
      n, codelen, filelen, entry: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN Texts.WriteString(W, "  WriteFile "); res := -2;
        Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, S.s);
        f := Files.Old(name);
        IF f # NIL THEN
          IF Files.Length(f) > 0 THEN
            g := Files.New(S.s); Files.Set(Rf, f, 0); Files.Set(Rg, g, 0);
            Texts.Scan(S);
            IF S.class = Texts.Int THEN
              OutCode(Rf, Rg, WriteIntelHex, S.i, codelen, entry, res);
              IF res = noerr THEN
                Texts.WriteInt(W, codelen*4, 6); Texts.WriteInt(W, entry, 6);
                Texts.WriteString(W, "  done"); Files.Register(g)
              ELSIF res = badfile THEN Texts.WriteString(W, "  input file format error")
              END
            ELSE res := -1
            END
          ELSE Texts.WriteString(W, "  input file empty")
          END
        ELSE Texts.WriteString(W, "  input file not found")
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: OM4X.WriteFile M.m4c M.hex LoadAddress") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WriteFile;

  PROCEDURE WriteCode*;  (*write code section of M.m4c in binary format to output file*)
    VAR f, g: Files.File; Rf, Rg: Files.Rider;
      codelen, entry: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN Texts.WriteString(W, "  WriteCode "); res := -2;
        Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, S.s);
        f := Files.Old(name);
        IF f # NIL THEN
          IF Files.Length(f) > 0 THEN
            g := Files.New(S.s); Files.Set(Rf, f, 0); Files.Set(Rg, g, 0);
            OutCode(Rf, Rg, WriteBinary, 0, codelen, entry, res);
            IF res = noerr THEN
              Texts.WriteInt(W, codelen*4, 6); Texts.WriteInt(W, entry, 6);
              Texts.WriteString(W, "  done"); Files.Register(g)
            ELSIF res = badfile THEN Texts.WriteString(W, "  input file format error")
            END
          ELSE Texts.WriteString(W, "  input file empty")
          END
        ELSE Texts.WriteString(W, "  input file not found")
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: OM4X.WriteCode M.m4c M.code") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WriteCode;

  PROCEDURE WriteASM*;  (*write code section of M.m4c in assembly format to output file*)
    VAR f, g: Files.File; Rf, Rg: Files.Rider;
      codelen, entry, i: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN Texts.WriteString(W, "  WriteCode "); res := -2;
        Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, S.s);
        f := Files.Old(name);
        IF f # NIL THEN
          IF Files.Length(f) > 0 THEN
            g := Files.New(S.s); Files.Set(Rf, f, 0); Files.Set(Rg, g, 0);
            name := S.s;
            i := 0; WHILE (name[i] # 0X) & (name[i] # ".") DO INC(i) END; name[i] := 0X;
            
            WriteString(Rg,"  .syntax unified"); Files.Write(Rg, CR);
            WriteString(Rg,"  .cpu cortex-m4"); Files.Write(Rg, CR);
            WriteString(Rg,"  .thumb"); Files.Write(Rg, CR);
            Files.Write(Rg, CR);
            WriteString(Rg,"  .global "); WriteString(Rg, name); Files.Write(Rg, CR);
            Files.Write(Rg, CR);
            WriteString(Rg,"  .thumb_func"); Files.Write(Rg, CR);
            WriteString(Rg, name); WriteString(Rg, ":"); Files.Write(Rg, CR);
            
            OutCode(Rf, Rg, WriteAsmLine, 0, codelen, entry, res);
            WriteString(Rg,"  // End of file."); Files.Write(Rg, CR);
            
            IF res = noerr THEN
              Texts.WriteInt(W, codelen*4, 6); Texts.WriteInt(W, entry, 6);
              Texts.WriteString(W, "  done"); Files.Register(g)
            ELSIF res = badfile THEN Texts.WriteString(W, "  input file format error")
            END
          ELSE Texts.WriteString(W, "  input file empty")
          END
        ELSE Texts.WriteString(W, "  input file not found")
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: OM4X.WriteASM M.m4c M.s") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WriteASM;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4 boot converter CS 11/12/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END OM4X.
