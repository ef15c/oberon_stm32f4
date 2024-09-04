MODULE OMSPL;  (*Oberon linker for MSP430 / AP 6.8.20 / CS 31.08.2024*)
  IMPORT SYSTEM, Modules, A := OMSPA, G := OMSPG, Files, FilesEx, Texts, TextsEx, Oberon;
  CONST noerr = 0; nofile = 1; duphandler = 2; badkey = 3; badfile = 4; nospace = 5; nopar = 6; noinit = 7;
    RAMOrigin = 200H; FlashEnd = 10000H;

  TYPE Module = POINTER TO ModDesc;
    ModuleName = ARRAY 32 OF CHAR;

    ModDesc = RECORD
        name: ModuleName;
        next: Module;
        key, num, size: INTEGER;
        data, flash: INTEGER;  (*addresses*)
        ent: ARRAY 64 OF INTEGER
     END;

    Segment = POINTER TO SegmentDesc;

    SegmentDesc = RECORD
      origin, allocPtr: INTEGER;
      m: ARRAY FlashEnd OF BYTE
    END;

  VAR first: Module;
    RAMAllocPtr, RAMLimit, limit, res: INTEGER;
    Flash: Segment; vector: ARRAY 32 OF INTEGER;
    importing, imported: ModuleName;
    W: Texts.Writer;

  (* Get unaligned words *)
  PROCEDURE GetWordAt(adr: INTEGER): INTEGER;
    RETURN 0 + Flash.m[adr] + 100H*Flash.m[adr + 1]
  END GetWordAt;

  (* Put unaligned words *)
  PROCEDURE PutWordAt(adr, val: INTEGER);
  BEGIN Flash.m[adr] := val MOD 100H; val := val DIV 100H;
    Flash.m[adr + 1] := val MOD 100H;
  END PutWordAt;

  PROCEDURE MakeFileName(VAR FName: ARRAY OF CHAR; name, ext: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN i := 0; j := 0;  (*assume name suffix less than 4 characters*)
    WHILE (i < 32-5) & (name[i] > 0X) DO FName[i] := name[i]; INC(i) END ;
    REPEAT FName[i]:= ext[j]; INC(i); INC(j) UNTIL ext[j] = 0X;
    FName[i] := 0X
  END MakeFileName;

  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR F!: Files.File;
      filename: ModuleName;
  BEGIN MakeFileName(filename, name, ".mpc"); F := Files.Old(filename)
    RETURN F
  END ThisFile;

  PROCEDURE error(n: INTEGER; name: ARRAY OF CHAR);
  BEGIN res := n; importing := name
  END error;

  PROCEDURE Check(s: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR;
  BEGIN ch := s[0]; res := 1; i := 1;
    IF (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z") THEN
      REPEAT ch := s[i]; INC(i)
      UNTIL ~((ch >= "0") & (ch <= "9") OR (ch >= "A") & (ch <= "Z")
        OR (ch >= "a") & (ch <= "z") OR (ch = ".")) OR (i = 32);
      IF (i < 32) & (ch = 0X) THEN res := 0 END
    END
  END Check;

  (*destbase: start address of the destination, relative to Flash.origin
     fixbase: start address of the elements to be fixed, relative to Flash.origin*)
  PROCEDURE fixupFlash(VAR R: Files.Rider; import: ARRAY OF Module; destbase, fixbase: INTEGER);
    VAR adr, dest, nadr: INTEGER; mno: BYTE; impmod!: Module;
  BEGIN
    FilesEx.ReadHalfWord(R, adr); (*fixup procedures*)
    WHILE adr # 0 DO Files.ReadByte(R, mno); FilesEx.ReadHalfWord(R, dest);
      IF mno = 0 THEN (*current module*) INC(dest, destbase)
      ELSE (*imported*) impmod :=  import[mno - 1]; dest := impmod.flash + impmod.ent[dest]
      END; INC(dest, Flash.origin);
      REPEAT INC(adr, fixbase);
        nadr := GetWordAt(adr); PutWordAt(adr, dest); adr := nadr
      UNTIL nadr = 0;
      FilesEx.ReadHalfWord(R, adr) (*go to next chain*)
    END;
  END fixupFlash;

  PROCEDURE LinkOne(name: ARRAY OF CHAR; VAR newmod: Module);
    (*search module in list; if not found, link module.
      res = noerr: already present or linked;
      res = nofile: file not available;
      res = badkey: key conflict;
      res = badfile: corrupted file;
      res = nospace: insufficient space*)
    VAR mod!, prev!, impmod!: Module;
      i, n, key, impkey, nofimps, flashSize, code: INTEGER;
      f, w: INTEGER;  (*addresses*)
      ch: CHAR;
      adr, nadr, dest: INTEGER;
      name1, impname: ModuleName;
      F!: Files.File; R!: Files.Rider;
      import!: ARRAY 16 OF Module;
      mno, nv: BYTE; vec: ARRAY 32 OF INTEGER;
  BEGIN mod := first; prev := NIL; error(noerr, name); nofimps := 0;
    WHILE (mod # NIL) & (name # mod.name) DO prev := mod; mod := mod.next END ;
    IF mod = NIL THEN (*link*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key);
        FilesEx.ReadHalfWord(R, flashSize); importing := name1;
        Files.ReadString(R, impname);   (*imports*)
        WHILE (impname[0] # 0X) & (res = noerr) DO
          Files.ReadInt(R, impkey);
          LinkOne(impname, impmod); import[nofimps] := impmod;
          IF res = noerr THEN importing := name1;
            IF impmod.key # impkey THEN error(badkey, name1); imported := impname END;
            Files.ReadString(R, impname)
          END
        END
      ELSE error(nofile, name)
      END;
      IF res = noerr THEN
        IF flashSize < limit - Flash.allocPtr THEN (*allocate*)
          f := Flash.allocPtr; NEW(mod);
          Flash.allocPtr := (f + flashSize + (G.WordSize - 1) ) DIV G.WordSize*G.WordSize; mod.size := Flash.allocPtr - f;
          IF prev = NIL THEN mod.num := 1; first := mod ELSE mod.num := prev.num + 1; prev.next := mod END;
          mod.next := NIL
        ELSE error(nospace, name1)
        END
      END;
      IF res = noerr THEN (*read file*)
        mod.name := name; 
        i := 0; REPEAT INC(i) UNTIL mod.name[i] = 0X; REPEAT mod.name[i] := 0X; INC(i) UNTIL i=32;
        mod.key := key;
        mod.flash := f; (*flash segment*)
        FilesEx.ReadHalfWord(R, n); (*size of type descriptors*)
        WHILE n > 0 DO FilesEx.ReadHalfWord(R, w); PutWordAt(f, w); INC(f, G.WordSize); DEC(n, G.WordSize) END;  (*type descriptors*)
        FilesEx.ReadHalfWord(R, n); (*size of data*)
        mod.data := RAMAllocPtr; INC(RAMAllocPtr, n); (*note: data is never initialized*)
        IF RAMAllocPtr >= RAMLimit THEN error(nospace, name1) END
      END;
      IF res = noerr THEN (*continue reading*)
        FilesEx.ReadHalfWord(R, n); (*size of strings*)
        WHILE n > 0 DO Files.Read(R, ch); Flash.m[f] := ORD(ch); INC(f); DEC(n) END;   (*strings*)
        code := f;
        FilesEx.ReadHalfWord(R, n); (*In MSP430 implementation, program size is counted in bytes*)
        WHILE n > 0 DO FilesEx.ReadHalfWord(R, w); PutWordAt(f, w); INC(f, G.WordSize); DEC(n, G.WordSize) END ;  (*program code*)
        Files.ReadByte(R, nv); (*number of entries in vector table*)
        FOR i := 0 TO nv - 1 DO FilesEx.ReadHalfWord(R, w); vec[i] := w END; (*module vector table*)
        FilesEx.ReadHalfWord(R, n); (*number of entries*)
        FOR i := 0 TO n - 1 DO FilesEx.ReadHalfWord(R, mod.ent[i]) END; (*entries*)
        IF GetWordAt(mod.flash + mod.ent[0]) = 4130H THEN (*module init is empty*)
          DEC(Flash.allocPtr, 2); PutWordAt(mod.flash + mod.ent[0], -1) (*mark init address as invalid*)
        END;

        fixupFlash(R, import, mod.flash, code); (*fixup procedures*)

        FilesEx.ReadHalfWord(R, i); (*fixup handlers*)
        WHILE i # 0 DO Files.ReadByte(R, mno); ASSERT(mno = 0); FilesEx.ReadHalfWord(R, dest); INC(dest, mod.flash);
          REPEAT DEC(i, 100H);
            IF vector[i] # 0FFFFH THEN
              Texts.WriteString(W, "interrupt vector number"); Texts.WriteInt(W, i, 3); error(duphandler, name1)
            END;
            vector[i] := dest; i := vec[i]
          UNTIL i = 0;
          FilesEx.ReadHalfWord(R, i) (*go to next chain*)
        END;

        FilesEx.ReadHalfWord(R, adr); (*fixup data*)
        WHILE adr # 0 DO Files.ReadByte(R, mno); FilesEx.ReadHalfWord(R, dest);
          IF mno = 0 THEN (*current module*) INC(dest, mod.data)
          ELSE (*imported*) impmod :=  import[mno - 1]; dest := impmod.data + impmod.ent[dest]
          END; INC(dest, RAMOrigin);
          REPEAT INC(adr, mod.flash);
            nadr := code + GetWordAt(adr); PutWordAt(adr, dest);
            adr := nadr
          UNTIL adr = mod.flash;
          FilesEx.ReadHalfWord(R, adr) (*go to next chain*)
        END;

        fixupFlash(R, import, mod.flash, code); (*fixup constants*)
        fixupFlash(R, import, mod.flash, mod.flash); (*fixup types*)

        FilesEx.ReadHalfWord(R, w);
        Files.Read(R, ch);
        IF ch # "O" THEN mod := NIL; error(badfile, name) END
      END ;
      IF res >= badkey THEN importing := name END
    END;
    newmod := mod
  END LinkOne;

  PROCEDURE Link*;  (*link multiple object files together and create a single MSP430 TI-TXT file M.txt from them*)
    VAR i, x, vecsize, isrtrap: INTEGER;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
      M!, p!: Module;
      name: ModuleName;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := noerr;
    Flash := SYSTEM.VAL(Segment, Modules.AllocPtr); FOR i := 0 TO 31 DO vector[i] := 0FFFFH END;
    IF S.class = Texts.Int THEN  vecsize := S.i; Texts.Scan(S) ELSE res := nopar END;
    IF S.class = Texts.Int THEN  limit := S.i - vecsize; Flash.origin := FlashEnd - S.i; Flash.allocPtr := 0; Texts.Scan(S) ELSE res := nopar END;
    IF (res = noerr) & (S.class = Texts.Int) THEN RAMLimit := RAMOrigin + S.i; RAMAllocPtr := RAMOrigin; Texts.Scan(S) ELSE res := nopar END;
    IF (res = noerr) & (S.class = Texts.Name) THEN first := NIL; 
      REPEAT LinkOne(S.s, M); Texts.Scan(S) UNTIL (S.class # Texts.Name) OR (res # noerr);
      IF res = noerr THEN Texts.WriteString(W, "  linking");
        (*prolog*) vector[31] := Flash.allocPtr; p := first;
        (*MOV RAMLimit, SP*) PutWordAt(Flash.allocPtr, 4031H); INC(Flash.allocPtr, 2); PutWordAt(Flash.allocPtr, RAMLimit); INC(Flash.allocPtr, 2);
        WHILE p # NIL DO (*fixup*) Texts.Write(W, " "); Texts.WriteString(W, p.name);
          IF p.ent[0] >= 0 THEN (*init code present*)
            (*CALL Flash.origin + p.flash + p.ent[0]*);
            PutWordAt(Flash.allocPtr, 12B0H); INC(Flash.allocPtr, 2); PutWordAt(Flash.allocPtr, Flash.origin + p.flash + p.ent[0]); INC(Flash.allocPtr, 2)
          END;
          p := p.next
        END
      END;
      IF (res = noerr) & (M.ent[0] < 0) THEN error(noinit, M.name) END;
      IF res = noerr THEN
        MakeFileName(name, S.s, ".txt"); F := Files.New(name); Files.Set(R, F, 0);

        i := 32 - vecsize DIV 2; isrtrap := -1; (*install default ISR trap if required*)
        REPEAT
          IF vector[i] = 0FFFFH THEN (*isrtrap is needed*)
            isrtrap := Flash.allocPtr; PutWordAt(Flash.allocPtr, 0D032H); INC(Flash.allocPtr, 2); PutWordAt(Flash.allocPtr, 0010H); INC(Flash.allocPtr, 2);
            PutWordAt(Flash.allocPtr, 3FFDH); INC(Flash.allocPtr, 2); 
          END;
          INC(i)
        UNTIL (i >= 31) OR (isrtrap > 0);

        (*write TI-TXT file*)
        i := 0; Files.Write(R, "@"); FilesEx.WriteHexHalfWord(R, Flash.origin); FilesEx.WriteLn(R); (*code*)
        WHILE i < Flash.allocPtr DO
          FilesEx.WriteHex(R, Flash.m[i]); Files.Write(R, " "); INC(i);
          IF i MOD 16 = 0 THEN FilesEx.WriteLn(R) END
        END;
        IF i MOD 16 # 0 THEN FilesEx.WriteLn(R) END;

        i := 0; x := 32 - vecsize DIV 2; Files.Write(R, "@"); FilesEx.WriteHexHalfWord(R, FlashEnd - x*2); FilesEx.WriteLn(R); (*vector table*)
        WHILE x < 32 DO IF vector[x] = 0FFFFH THEN vector[x] := isrtrap END;
          FilesEx.WriteHex(R, (Flash.origin + vector[x]) MOD 100H); Files.Write(R, " ");
          FilesEx.WriteHex(R, (Flash.origin + vector[x]) DIV 100H MOD 100H); Files.Write(R, " ");
          INC(i,2); IF i MOD 16 = 0 THEN FilesEx.WriteLn(R) END;
          INC(x)
        END;
        IF i MOD 16 # 0 THEN FilesEx.WriteLn(R) END;
        Files.Write(R, "q"); FilesEx.WriteLn(R);
        Files.Register(F)
      ELSE
        Texts.WriteString(W, "Link error:  "); Texts.WriteString(W, importing);
        IF res = nofile THEN Texts.WriteString(W, " module not found")
        ELSIF res = duphandler THEN Texts.WriteString(W, " duplicate interrupt handler")
        ELSIF res = badkey THEN Texts.WriteString(W, " imports ");
          Texts.WriteString(W, imported); Texts.WriteString(W, " with bad key")
        ELSIF res = badfile THEN Texts.WriteString(W, " corrupted obj file")
        ELSIF res = nospace THEN Texts.WriteString(W, " insufficient space")
        ELSIF res = noinit THEN Texts.WriteString(W, " top module init code missing")
        END
      END
    ELSE Texts.WriteString(W, "Usage: OMSPL.Link VectorTableSize FlashSize RAMSize [module...] topmodule")
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Link;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OMSP linker  AP 6.8.20 / CS 31.08.2024");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
END OMSPL.
