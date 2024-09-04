MODULE OM4X;  (*Oberon boot converter for RISC / AP 13.6.20 / CS 11/12/2023*)
  IMPORT Display, Files, FilesEx, Texts, Oberon;
  CONST noerr = 0; badfile = 4;  (*copied from Modules for use as cross development tool*)
    fixup = 1;
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

  PROCEDURE WriteIntelHex(VAR R: Files.Rider; r: record);  (*write a record in Intel HEX file format*)
    VAR cs: BYTE;
      i: INTEGER;
  BEGIN cs := 0; Files.Write(R, ":");
    FilesEx.WriteHex(R, r.l); FilesEx.WriteHex(R, r.a[0]); FilesEx.WriteHex(R, r.a[1]); FilesEx.WriteHex(R, r.t);
    INC(cs, r.l + r.a[0] + r.a[1] + r.t);
    FOR i:= 0 TO r.l-1 DO FilesEx.WriteHex(R, r.d[i]); INC(cs, r.d[i]) END;
    FilesEx.WriteHex(R, 256-cs); FilesEx.WriteLn(R)
  END WriteIntelHex;

  PROCEDURE WriteAsmLine(VAR R: Files.Rider; r: record);  (*write a record in binary format*)
    VAR i: INTEGER;
  BEGIN
    IF r.t = 0 THEN FilesEx.WriteString(R, "  .byte ");
      FOR i:= 0 TO r.l-1 DO IF i # 0 THEN FilesEx.WriteString(R, ", ") END;
        FilesEx.WriteString(R, "0X"); FilesEx.WriteHex(R, r.d[i]) END
    END; FilesEx.WriteLn(R)
  END WriteAsmLine;

  PROCEDURE SetAddress(VAR a: ARRAY OF BYTE; ad: INTEGER);
  BEGIN
    a[0] := ad DIV 100H MOD 100H;
    a[1] := ad MOD 100H
  END SetAddress;

  PROCEDURE IntToByteArray(i: INTEGER; VAR ba: ARRAY OF BYTE; pos: INTEGER; le: BOOLEAN);
  BEGIN
    IF le THEN
      ba[pos+3] := i DIV 1000000H MOD 100H; ba[pos+2] := i DIV 10000H MOD 100H;
      ba[pos+1] := i DIV 100H MOD 100H; ba[pos] := i MOD 100H
    ELSE
      ba[pos] := i DIV 1000000H MOD 100H; ba[pos+1] := i DIV 10000H MOD 100H;
      ba[pos+2] := i DIV 100H MOD 100H; ba[pos+3] := i MOD 100H
    END
  END IntToByteArray;

  PROCEDURE OutCode(VAR R, R1: Files.Rider; write: Writer; loadaddress: INTEGER; VAR codelen, entry, res: INTEGER);
    VAR n, data: INTEGER; ch: CHAR; b: BYTE;               (*codelen in bytes, entry in bytes*)
      F!: Files.File;
      name: ARRAY 32 OF CHAR;
      r: record;
      la, lah: INTEGER;
  BEGIN res := noerr;
    F := Files.Base(R); Files.ReadString(R, name); Files.ReadInt(R, data); (*key*)
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
    FOR n := 1 TO codelen MOD 4 DO Files.ReadByte(R, b) END; (*Skip padding bytes*)    
    Files.ReadString(R, name);
    WHILE ~R.eof & (name[0] # 0X) DO Files.ReadInt(R, data); Files.ReadString(R, name) END ; (*commands*)
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n*4); (*entries*)
    Files.ReadInt(R, data);
    WHILE ~R.eof & (data >= 0) DO Files.ReadInt(R, data) END ; (*pointer references*)
    Files.ReadInt(R, data); (*fixorgP*) IF data # 0 THEN res := fixup END;
    Files.ReadInt(R, data); (*fixorgD*) IF data # 0 THEN res := fixup END;
    Files.ReadInt(R, data); (*fixorgT*) IF data # 0 THEN res := fixup END;
    Files.ReadInt(R, entry);
    (*write start linear address record (MDK-ARM only)*)
    la := loadaddress + entry + 1; (*Odd value means thumb mode*)
    r.t := 5; r.a[0] := 0; r.a[1] := 0; r.l := 4; IntToByteArray(la, r.d, 0, FALSE); write(R1, r);
    Files.Read(R, ch);
    IF ch # "O" THEN res := badfile END;
    (*write End-of-File (EOF) Record*)
    r.t := 1; r.l := 0; write(R1, r)
  END OutCode;

  PROCEDURE WriteFile*;  (*write code section of M.m4c in hex format to output file*)
    VAR f!, g!: Files.File; Rf!, Rg!: Files.Rider;
      org, vtsize, codelen, entry, lah, oldCol: INTEGER;
      name: ARRAY 32 OF CHAR;
      S!: Texts.Scanner;
      r: record;
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
              org := S.i; Texts.Scan(S);
              IF S.class = Texts.Int THEN
                vtsize := S.i; Texts.Scan(S);
                IF S.class = Texts.Int THEN lah := LSR(org, 16); r.t := 4; r.l := 2; r.a[0] := 0; r.a[1] := 0; (*extended linear address record*)
                  r.d[0] := LSR(lah, 8); r.d[1] := lah MOD 100H; WriteIntelHex(Rg, r); SetAddress(r.a, org); r.t := 0; (*prepare for data record*)
                  IntToByteArray(S.i, r.d, 0, TRUE); IntToByteArray(org + vtsize + 1, r.d, 4, TRUE); r.l := 8; WriteIntelHex(Rg, r);
                  OutCode(Rf, Rg, WriteIntelHex, org + vtsize, codelen, entry, res);
                  IF res = noerr THEN
                    Texts.WriteInt(W, codelen*4, 6); Texts.WriteInt(W, entry, 6);
                    Texts.WriteString(W, "  done"); Files.Register(g)
                  ELSIF res = fixup THEN Texts.WriteString(W, "  program need fixup error")
                  ELSIF res = badfile THEN Texts.WriteString(W, "  input file format error")
                  END
                ELSE res := -1
                END
              ELSE res := -1
              END
            ELSE res := -1
            END
          ELSE Texts.WriteString(W, "  input file empty")
          END
        ELSE Texts.WriteString(W, "  input file not found")
        END
      END
    END;
    IF res = -1 THEN Texts.WriteLn(W); oldCol := W.col; W.col := Display.red; 
      Texts.WriteString(W, "Usage: OM4X.WriteFile M.m4c M.hex LoadAddress VecTabSize StackAddr");
      W.col := oldCol
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WriteFile;

  PROCEDURE WriteCode*;  (*write code section of M.m4c in binary format to output file*)
    VAR f!, g!: Files.File; Rf!, Rg!: Files.Rider;
      codelen, entry: INTEGER;
      name: ARRAY 32 OF CHAR;
      S!: Texts.Scanner;
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
            ELSIF res = fixup THEN Texts.WriteString(W, "  program need fixup error")
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
    VAR f!, g!: Files.File; Rf!, Rg!: Files.Rider;
      codelen, entry, i: INTEGER;
      name: ARRAY 32 OF CHAR;
      S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN Texts.WriteString(W, "  WriteASM "); res := -2;
        Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, S.s);
        f := Files.Old(name);
        IF f # NIL THEN
          IF Files.Length(f) > 0 THEN
            g := Files.New(S.s); Files.Set(Rf, f, 0); Files.Set(Rg, g, 0);
            name := S.s;
            i := 0; WHILE (name[i] # 0X) & (name[i] # ".") DO INC(i) END; name[i] := 0X;
            
            FilesEx.WriteString(Rg,"  .syntax unified"); FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg,"  .cpu cortex-m4"); FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg,"  .thumb"); FilesEx.WriteLn(Rg);
            FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg,"  .global "); FilesEx.WriteString(Rg, name); FilesEx.WriteLn(Rg);
            FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg,"  .thumb_func"); FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg, name); FilesEx.WriteString(Rg, ":"); FilesEx.WriteLn(Rg);
            
            OutCode(Rf, Rg, WriteAsmLine, 0, codelen, entry, res);
            FilesEx.WriteString(Rg,"  // End of file."); FilesEx.WriteLn(Rg);
        
            IF res = noerr THEN
              Texts.WriteInt(W, codelen*4, 6); Texts.WriteInt(W, entry, 6);
              Texts.WriteString(W, "  done"); Files.Register(g)
            ELSIF res = badfile THEN Texts.WriteString(W, "  input file format error")
            ELSIF res = fixup THEN Texts.WriteString(W, "  program need fixup error")
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

  PROCEDURE WritePreLinkedASM*;  (*write pre-linked (.bin) in assembly format to output file*)
    VAR f!, g!: Files.File; Rf!, Rg!: Files.Rider;
      base, i: INTEGER;
      b: BYTE;
      name: ARRAY 32 OF CHAR;
      S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN Texts.WriteString(W, "  WriteASM "); res := -2;
        Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, S.s);
        f := Files.Old(name);
        IF f # NIL THEN
          Files.Set(Rf, f, 8); Files.ReadInt(Rf, base);
          IF Files.Length(f) > 0 THEN
            res := noerr;
            g := Files.New(S.s); Files.Set(Rf, f, 0); Files.Set(Rg, g, 0);
            name := S.s;
            i := 0; WHILE (name[i] # 0X) & (name[i] # ".") DO INC(i) END; name[i] := 0X;
            
            FilesEx.WriteString(Rg, "  .syntax unified"); FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg, "  .cpu cortex-m4"); FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg, "  .thumb"); FilesEx.WriteLn(Rg);
            FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg, "  .section .SDRamFunc,"); Files.Write(Rg, 22X);
            FilesEx.WriteString(Rg, "ax"); Files.Write(Rg, 22X); FilesEx.WriteString(Rg, ",%progbits");
            FilesEx.WriteLn(Rg); FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg,"  .global "); FilesEx.WriteString(Rg, name); FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg,"  .thumb_func"); FilesEx.WriteLn(Rg);
            FilesEx.WriteString(Rg, name); FilesEx.WriteString(Rg, ":"); FilesEx.WriteLn(Rg);
            FilesEx.WriteLn(Rg);

            i := 0; Files.ReadByte(Rf, b);
            WHILE ~Rf.eof DO
              IF i MOD 16 = 0 THEN FilesEx.WriteLn(Rg); FilesEx.WriteString(Rg, "  .byte") ELSE Files.Write(Rg, ",") END;
              FilesEx.WriteString(Rg,"  0x"); FilesEx.WriteHex(Rg, b); INC(i); Files.ReadByte(Rf, b);
            END; FilesEx.WriteLn(Rg); 
            FilesEx.WriteLn(Rg); FilesEx.WriteString(Rg,"  // End of pre-linked file."); FilesEx.WriteLn(Rg);
            
            Texts.WriteInt(W, i, 6); Texts.WriteString(W, "  done"); Files.Register(g)
          ELSE Texts.WriteString(W, "  input file empty")
          END
        ELSE Texts.WriteString(W, "  input file not found")
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: OM4X.WriteASM M.bin M.s") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END WritePreLinkedASM;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4 boot converter CS 11/12/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END OM4X.
