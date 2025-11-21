MODULE OMSPL;  (*Oberon linker for MSP430 / AP 6.8.20 / CS 31.08.2024*)
  (* Object code V2 file format:
      CodeFile    = name key version size imports typedesc varsize constants code vectors entries 
                           procFix handlerFix dataFix constFix varCstFix constCstFix entry "O".
      imports      = {modname key} 0X.
      typedesc    = nof {word}.
      constants   = nof {byte}
      code          = nof {byte}.
      vectors      = nof {word}.
      entries      = nof {char word word}.
      procFix      = fixChain.
      handlerFix = fixChain.
      dataFix      = fixChain.
      constFix     = fixChain.
      varCstFix    = fixChain.
      constCstFix = fixChain.
      fixChain    = {word, byte word word word} 0.

      version: 0: legacy mode, 1: legacy RAM execution mode, 2: new node, 3: new RAM execution mode*)

  IMPORT SYSTEM, Modules, Display, G := OMSPG, Files, FilesEx, Texts, Oberon, TextsEx;
  CONST noerr = 0; nofile = 1; duphandler = 2; badkey = 3; badfile = 4; nospace = 5; nopar = 6; noinit = 7; notsupported = 8;
    RAMOrigin = 200H; FlashEnd = 10000H;

  TYPE Object = POINTER TO ObjectDesc;
    ObjectDesc = RECORD
      seg: CHAR;
      mno: BYTE; a, size: INTEGER; (*original address of the object (procedure, string or stored constant*)
      org, uadr: INTEGER; (*Flash offset and top address of the usage tracking list*)
      next: Object
    END;

    Module = POINTER TO ModDesc;
    ModuleName = ARRAY 32 OF CHAR;

    ModDesc = RECORD
      name: ModuleName;
      next: Module;
      key, num, size: INTEGER;
      data, conststo, codeexe, codesto, codesize: INTEGER;  (*addresses*)
      ent: ARRAY 64 OF INTEGER;
      codeseg: BYTE;
      rl, tdl, nrl: Object (*referenced, to do, unreferenced lists*)
    END;

    Segment = POINTER TO SegmentDesc;

    SegmentDesc = RECORD
      origin, allocPtr: INTEGER;
      m: ARRAY FlashEnd OF BYTE
    END;

  VAR first, last, firstM, lastM: Module;
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

  PROCEDURE EmitWord(val: INTEGER);
  BEGIN PutWordAt(Flash.allocPtr, val); INC(Flash.allocPtr, 2);
  END EmitWord;

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

  (*destbase: start address of the destination, relative to flash or RAM origin
     fixbase: start address of the elements to be fixed, relative to Flash.origin*)
  PROCEDURE fixupFlash(VAR R: Files.Rider; import: ARRAY OF Module; destbase, fixbase: INTEGER);
    VAR adr, ofs, size, dest, nadr: INTEGER; mno: BYTE; impmod!: Module;
  BEGIN
    FilesEx.ReadHalfWord(R, adr);
    WHILE adr # 0 DO Files.ReadByte(R, mno); FilesEx.ReadHalfWord(R, dest); FilesEx.ReadHalfWord(R, ofs);
      FilesEx.ReadHalfWord(R, size);
      IF mno = 0 THEN (*current module*) INC(dest, destbase)
      ELSE (*imported*) impmod :=  import[mno - 1]; dest := impmod.ent[dest]
      END; INC(dest, ofs);
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
    VAR mod!, impmod!: Module;
      i, n, key, impkey, nofimps, flashSize: INTEGER;
      f, w, s: INTEGER;  (*addresses and size*)
      ch: CHAR;
      adr, ofs, nadr, dest: INTEGER;
      name1, impname: ModuleName;
      F!: Files.File; R!: Files.Rider;
      import!: ARRAY 16 OF Module;
      mno, nv, codeseg: BYTE; vec: ARRAY 32 OF INTEGER;
  BEGIN mod := first; error(noerr, name); nofimps := 0; flashSize := LSL(1, 31) - 1;
    key := 0; codeseg := 0FFH; f := 0;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*link*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.ReadByte(R, codeseg);
        IF codeseg IN {2, 3} THEN codeseg := codeseg MOD 2;
          FilesEx.ReadHalfWord(R, flashSize); importing := name1;
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = noerr) DO
            Files.ReadInt(R, impkey);
            LinkOne(impname, impmod); import[nofimps] := impmod; INC(nofimps);
            IF res = noerr THEN importing := name1;
              IF impmod.key # impkey THEN error(badkey, name1); imported := impname END;
              Files.ReadString(R, impname)
            END
          END
        ELSE error(notsupported, name)
        END
      ELSE error(nofile, name)
      END;
      IF res = noerr THEN
        IF flashSize < limit - Flash.allocPtr THEN (*allocate*)
          f := Flash.allocPtr; NEW(mod);
          Flash.allocPtr := (f + flashSize + (G.WordSize - 1) ) DIV G.WordSize*G.WordSize; mod.size := Flash.allocPtr - f;
          IF first = NIL THEN mod.num := 1; first := mod ELSE mod.num := last.num + 1; last.next := mod END;
          last := mod; mod.next := NIL
        ELSE error(nospace, name1)
        END
      END;
      IF res = noerr THEN (*read file*)
        mod.name := name;
        i := 0; REPEAT INC(i) UNTIL mod.name[i] = 0X; REPEAT mod.name[i] := 0X; INC(i) UNTIL i=32;
        mod.key := key; mod.codeseg := codeseg;
        mod.conststo := f; (*const section storage address*)
        FilesEx.ReadHalfWord(R, n); (*number of type descriptors words*)
        WHILE n > 0 DO FilesEx.ReadHalfWord(R, w); PutWordAt(f, w); INC(f, G.WordSize); DEC(n) END;  (*type descriptors*)
        FilesEx.ReadHalfWord(R, n); (*size of data*)
        mod.data := RAMAllocPtr; INC(RAMAllocPtr, n); (*note: data is never initialized*)
        IF RAMAllocPtr >= RAMLimit THEN error(nospace, name1) END
      END;
      IF res = noerr THEN (*continue reading*)
        FilesEx.ReadHalfWord(R, n); (*size of stored constants*)
        WHILE n > 0 DO Files.Read(R, ch); Flash.m[f] := ORD(ch); INC(f); DEC(n) END;
        WHILE f MOD G.WordSize # 0 DO Flash.m[f] := 0FFH; INC(f) END; (*align to G.WordSize*)
        FilesEx.ReadHalfWord(R, n); (*In MSP430 implementation, program size is counted in bytes*)
        mod.codesto := f; mod.codesize := n;
        IF codeseg = 1 THEN mod.codeexe := RAMAllocPtr; INC(RAMAllocPtr, n)
        ELSE mod.codeexe := Flash.origin + f
        END;
        WHILE n > 0 DO FilesEx.ReadHalfWord(R, w); PutWordAt(f, w); INC(f, G.WordSize); DEC(n, G.WordSize) END ; (*program code*)
        Files.ReadByte(R, nv); (*number of entries in vector table*)
        FOR i := 0 TO nv - 1 DO FilesEx.ReadHalfWord(R, w); vec[i] := w END; (*module vector table*)
        FilesEx.ReadHalfWord(R, n); (*number of entries*)
        FOR i := 0 TO n - 1 DO Files.Read(R, ch); FilesEx.ReadHalfWord(R, w); FilesEx.ReadHalfWord(R, s); (*entries*)
          IF ch = "c" THEN (*code*) INC(w, mod.codeexe)
          ELSIF ch = "d" THEN (*data*) INC(w, mod.data)
          ELSE ASSERT(ch = "k"); (*constant*) INC(w, Flash.origin + mod.conststo)
          END; mod.ent[i] := w
        END;
        fixupFlash(R, import, mod.codeexe, mod.codesto); (*fixup procedures*)

        FilesEx.ReadHalfWord(R, i); (*fixup handlers*)
        WHILE i # 0 DO Files.ReadByte(R, mno); ASSERT(mno = 0); FilesEx.ReadHalfWord(R, dest);
          FilesEx.ReadHalfWord(R, ofs); ASSERT(ofs = 0); FilesEx.ReadHalfWord(R, s); INC(dest, mod.codeexe);
          REPEAT DEC(i, 100H);
            IF vector[i] # 0FFFFH THEN
              Texts.WriteString(W, "interrupt vector number"); Texts.WriteInt(W, i, 3); error(duphandler, name1)
            END;
            vector[i] := dest; i := vec[i]
          UNTIL i = 0;
          FilesEx.ReadHalfWord(R, i) (*go to next chain*)
        END;

        FilesEx.ReadHalfWord(R, adr); (*fixup data*)
        WHILE adr # 0 DO Files.ReadByte(R, mno); FilesEx.ReadHalfWord(R, dest); FilesEx.ReadHalfWord(R, ofs);
          FilesEx.ReadHalfWord(R, s);
          IF mno = 0 THEN (*current module*) INC(dest, mod.data)
          ELSE (*imported*) impmod :=  import[mno - 1]; dest := impmod.ent[dest]
          END; INC(dest, ofs);
          REPEAT INC(adr, mod.codesto);
            nadr := GetWordAt(adr); PutWordAt(adr, dest); adr := nadr
          UNTIL adr = 0;
          FilesEx.ReadHalfWord(R, adr) (*go to next chain*)
        END;

        fixupFlash(R, import, Flash.origin + mod.conststo, mod.codesto); (*fixup constants in code space*)
        fixupFlash(R, import, mod.data, mod.conststo); (*fixup variables in constant space*)
        fixupFlash(R, import, Flash.origin + mod.conststo, mod.conststo); (*fixup constants in constants space*)

        FilesEx.ReadHalfWord(R, w);
        IF GetWordAt(mod.codesto + w) = 4130H THEN (*module init is empty*)
          DEC(mod.codesize, 2); mod.ent[0] := -1; (*mark init address as invalid*)
          IF codeseg = 1 THEN DEC(RAMAllocPtr, 2) ELSE DEC(Flash.allocPtr, 2) END
        END;

        Files.Read(R, ch);
        IF ch # "O" THEN mod := NIL; error(badfile, name) END
      END ;
      IF res >= badkey THEN importing := name END
    END;
    newmod := mod
  END LinkOne;

  PROCEDURE printObject(o: Object);
  BEGIN Texts.Write(W, o.seg); Texts.WriteInt(W, o.mno, 1);
    Texts.Write(W, "."); TextsEx.WriteHexVLen(W, o.a, 4, FALSE);
    Texts.WriteString(W, " ^"); TextsEx.WriteHexVLen(W, o.org, 4, FALSE);
    Texts.WriteString(W, "+"); TextsEx.WriteHexVLen(W, o.uadr, 4, FALSE);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END printObject;

  PROCEDURE Mark(name: ARRAY OF CHAR; VAR newmod: Module);
    VAR mod!, impmod!: Module; name1: ModuleName;
      F!: Files.File; R!: Files.Rider;
      f, w, s, i, n: INTEGER;
      b: BYTE; ch: CHAR;
      o!, nx!, pr!, td!: Object;
      import!: ARRAY 16 OF Module; nbi: INTEGER;

    PROCEDURE findObject(l: Object; mno: BYTE; seg: CHAR; a: INTEGER): Object;
    VAR o!: Object;
    BEGIN o := l;
      WHILE (o # NIL) & ((ORD(o.mno > 0) # ORD(mno > 0)) OR (o.seg # seg) OR (o.a # a)) DO o := o.next END

      RETURN o
    END findObject;

    PROCEDURE takeObject(VAR l: Object; mno: BYTE; seg: CHAR; a: INTEGER);
    (*remove object from list*)
    VAR o!, p!: Object;
    BEGIN o := l; p := NIL;
      WHILE (o # NIL) & ((ORD(o.mno > 0) # ORD(mno > 0)) OR (o.seg # seg) OR (o.a # a)) DO p := o; o := o.next END;
      IF o # NIL THEN IF p = NIL THEN l := o.next ELSE p.next := o.next END END
    END takeObject;

    PROCEDURE putObject(VAR l: Object; mno: BYTE; seg: CHAR; a, size, org, uadr: INTEGER);
    (*put object in list*)
    VAR o!: Object;
    BEGIN o := findObject(l, mno, seg, a);
      IF o = NIL THEN NEW(o); o.mno := mno; o.seg := seg; o.a := a; o.size := size;
        o.org := org; o.uadr := uadr; o.next := l; l := o
      END
    END putObject;

    PROCEDURE addObject(m: Module; ref: BOOLEAN; mno: BYTE; seg: CHAR; a, size, org, uadr: INTEGER);
    (*add an object in the appropriate list of the module*)
    VAR o!: Object;
    BEGIN o := findObject(m.rl, mno, seg, a);
      IF o = NIL THEN (*not already referenced*)
        o := findObject(m.tdl, mno, seg, a);
        IF o = NIL THEN (*not already in to do list*)
          IF ref THEN takeObject(m.nrl, mno, seg, a); (*remove form non referenced list*)
            putObject(m.tdl, mno, seg, a, size, org, uadr) (*and put it in to do list*)
          ELSE putObject(m.nrl, mno, seg, a, size, org, uadr) (*put object in unreferenced list*)
          END
        END
      END
    END addObject;

    PROCEDURE skipChainArray(VAR R: Files.Rider);
      VAR w: INTEGER; b: BYTE;
    BEGIN FilesEx.ReadHalfWord(R, w); (*usage adress*)
      WHILE w # 0 DO Files.ReadByte(R, b); (*module index*)
        FilesEx.ReadHalfWord(R, w); (*adress or number of object *) FilesEx.ReadHalfWord(R, w); (*offset*)
        FilesEx.ReadHalfWord(R, w); (*size*)
        FilesEx.ReadHalfWord(R, w); (*usage adress*)
      END
    END skipChainArray;

    PROCEDURE parseChainArray(VAR R: Files.Rider; import: ARRAY OF Module; seg: CHAR; org: INTEGER; ref: BOOLEAN);
      VAR adr, w, t, s: INTEGER; mno: BYTE; o!: Object;
    BEGIN FilesEx.ReadHalfWord(R, adr); (*usage adress*)
      WHILE adr # 0 DO Files.ReadByte(R, mno); (*module index*)
        FilesEx.ReadHalfWord(R, w); (*adress or number of object *) FilesEx.ReadHalfWord(R, t); (*offset*)
        FilesEx.ReadHalfWord(R, s); (*size*)
        addObject(import[mno], ref, mno, seg, w, s, org, adr);
        FilesEx.ReadHalfWord(R, adr); (*usage adress*)
      END
    END parseChainArray;

    PROCEDURE findMod(name: ARRAY OF CHAR): Module;
      VAR mod!: Module;
    BEGIN mod := firstM;
      WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END

     RETURN mod
    END findMod;

    PROCEDURE appendMod(newmod: Module);
      VAR i: INTEGER;
    BEGIN
      i := 0; REPEAT INC(i) UNTIL newmod.name[i] = 0X; REPEAT newmod.name[i] := 0X; INC(i) UNTIL i=LEN(newmod.name);
      IF firstM = NIL THEN firstM := newmod ELSE lastM.next := newmod END;
      lastM := newmod; newmod.next := NIL;
    END appendMod;

    PROCEDURE isRefBy(t, c: Object): BOOLEAN;
      (*returns TRUE if the object t is referenced by the object c*)
      VAR uadr, p: INTEGER;
    BEGIN ASSERT(c.mno = 0); (*not external*)
      uadr := t.uadr;
      WHILE (uadr # 0) & ((t.uadr  < c.a) OR (t.uadr >= c.a + c.size)) DO
        p := uadr; uadr := GetWordAt(t.org + uadr);
IF uadr >= p THEN printObject(t); printObject(c) END;
        ASSERT(uadr < p)
      END

      RETURN uadr # 0
    END isRefBy;

  BEGIN error(noerr, name); mod := findMod(name);
    Texts.WriteString(W, "Mark "); Texts.WriteString(W, name); Texts.WriteLn(W);
    IF mod = NIL THEN NEW(mod); mod.name := name; appendMod(mod) END;
    IF (mod.rl = NIL) (*first visit*) OR (mod.tdl # NIL) (*new refs*) THEN (*load objects and mark those referenced in body*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, w); mod.key := w; Files.ReadByte(R, b); (*version*)
        IF b IN {2, 3} THEN FilesEx.ReadHalfWord(R, w); (*skip flashsize*)
          Files.ReadString(R, name1); import[0] := mod; nbi := 0; (*load imports table*)
          WHILE (name1[0] # 0X) DO Files.ReadInt(R, w); (*expected import key*)
            impmod := findMod(name1);
            IF impmod = NIL THEN NEW(impmod); impmod.name := name1; impmod.key := w; appendMod(impmod)
            ELSE IF w # impmod.key THEN error(badkey, name1) END
            END; INC(nbi); import[nbi] := impmod;
            Files.ReadString(R, name1)
          END;
          f := 0; mod.conststo := f; (*const section storage address*)
          FilesEx.ReadHalfWord(R, n); (*number of type descriptors words*)
          WHILE n > 0 DO FilesEx.ReadHalfWord(R, w); PutWordAt(f, w); INC(f, G.WordSize); DEC(n) END;  (*type descriptors*)
          FilesEx.ReadHalfWord(R, w); (*size of data*)
          FilesEx.ReadHalfWord(R, n); (*size of stored constants*)
          WHILE n > 0 DO Files.Read(R, ch); Flash.m[f] := ORD(ch); INC(f); DEC(n) END; (*stored constants*)
          WHILE f MOD G.WordSize # 0 DO Flash.m[f] := 0FFH; INC(f) END; (*align to G.WordSize*)
          FilesEx.ReadHalfWord(R, n); (*In MSP430 implementation, program size is counted in bytes*)
          mod.codesto := f;
          WHILE n > 0 DO FilesEx.ReadHalfWord(R, w); PutWordAt(f, w); INC(f, G.WordSize); DEC(n, G.WordSize) END; (*skip program code*)
          Files.ReadByte(R, b); (*number of entries in vector table*)
          FOR i := 0 TO b - 1 DO FilesEx.ReadHalfWord(R, w) END; (*skip module vector table*)
          FilesEx.ReadHalfWord(R, n); (*number of entries*)
          Files.Read(R, ch); FilesEx.ReadHalfWord(R, w); FilesEx.ReadHalfWord(R, s);
          addObject(mod, TRUE, 0, ch, w, s, 0, 0); (*first entry is body adress*)
          FOR i := 1 TO n - 1 DO Files.Read(R, ch); FilesEx.ReadHalfWord(R, w); FilesEx.ReadHalfWord(R, s); (*entries*)
            addObject(mod, FALSE, 0, ch, w, s, 0, 0)
          END;
          parseChainArray(R, import, "c", mod.codesto, FALSE); (*procedures*)
          parseChainArray(R, import, "c", mod.codesto, TRUE); (*handlers*)
          skipChainArray(R); (*variables in code*)
          parseChainArray(R, import, "k", mod.codesto, FALSE); (*constants in code*)
          skipChainArray(R); (*variables in stored constants*)
          parseChainArray(R, import, "k", mod.conststo, FALSE); (*constants in stored constants*)
          FilesEx.ReadHalfWord(R, w); (*entry*)
          Files.Read(R, ch);
          IF ch = "O" THEN (*File is OK, we can process the to do list*)
            Texts.WriteString(W, "format OK"); Texts.WriteLn(W);
            WHILE mod.tdl # NIL DO td := mod.tdl; mod.tdl := td.next; o := mod.nrl; pr := NIL;
              WHILE o # NIL DO nx := o.next;
                IF isRefBy(o, td) THEN printObject(o);
                  IF pr = NIL THEN mod.nrl := nx ELSE pr.next := nx END; (*remove object from the unreferenced list*)
                  addObject(import[o.mno], TRUE, 0, o.seg, o.a, o.size, o.org, o.uadr) (*assign object to the to do list*)
                ELSE pr := o
                END; o := nx
              END
            END;
            (*Mark imported modules*)
            i := 1; WHILE i < nbi DO Mark(import[i].name, impmod); INC(i) END
          ELSE mod := NIL; error(badfile, name)
          END
        ELSE error(notsupported, name)
        END
      ELSE error(nofile, name)
      END;
    END
  END Mark;

  PROCEDURE Link*;  (*link multiple object files together and create a single MSP430 TI-TXT file M.txt from them*)
    VAR i, x, vecsize, isrtrap, count, oldcol: INTEGER;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
      M!, p!: Module;
      name: ModuleName;
      modlist: ARRAY 64 OF ModuleName;
      nbmod, mi: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := noerr; count := 0;
    Flash := SYSTEM.VAL(Segment, Modules.AllocPtr); FOR i := 0 TO 31 DO vector[i] := 0FFFFH END;
    IF S.class = Texts.Int THEN  vecsize := S.i; Texts.Scan(S) ELSE vecsize := 0; res := nopar END;
    IF S.class = Texts.Int THEN  limit := S.i - vecsize; Flash.origin := FlashEnd - S.i; Flash.allocPtr := 0; Texts.Scan(S) ELSE res := nopar END;
    IF (res = noerr) & (S.class = Texts.Int) THEN RAMLimit := RAMOrigin + S.i; RAMAllocPtr := RAMOrigin; Texts.Scan(S) ELSE res := nopar END;
    IF (res = noerr) & (S.class = Texts.Name) THEN nbmod := 0; REPEAT modlist[nbmod] := S.s; INC(nbmod); Texts.Scan(S) UNTIL S.class # Texts.Name;
(*      firstM := NIL; lastM := NIL; mi := 0; REPEAT Mark(modlist[mi], M); INC(mi) UNTIL (mi >= nbmod) OR (res # noerr);*)
      first := NIL; last := NIL; mi := 0; REPEAT LinkOne(modlist[mi], M); INC(mi) UNTIL (mi >= nbmod) OR (res # noerr);
      IF res = noerr THEN Texts.WriteString(W, "  linking");
        (*prolog*) vector[31] := Flash.origin + Flash.allocPtr; p := first;
        (*MOV RAMLimit, SP*) EmitWord(4031H); EmitWord(RAMLimit);
        WHILE p # NIL DO (*fixup*) Texts.Write(W, " "); Texts.WriteString(W, p.name);
          IF p.codeseg = 1 THEN (*module executed from RAM*) Texts.Write(W, "*");
            (*copy code from Flash to RAM*)
            (*MOV p.codesize DIV 2,R15*) EmitWord(403FH); EmitWord(p.codesize DIV 2);
            (*MOV Flash.origin + p.codesto,R14*) EmitWord(403EH);  EmitWord(Flash.origin + p.codesto);
            (*MOV @R14+,p.codeexe - (Flash.origin + p.codesto)(R14) - 2*) EmitWord(4EBEH); EmitWord(p.codeexe - Flash.origin - p.codesto - 2);
            (*SUB #1,R15*) EmitWord(831FH);
            (*JNE $-8*) EmitWord(23FCH)
          END;
          INC(count); IF count MOD 8 = 0 THEN count := 0; Texts.WriteLn(W) END;
          IF p.ent[0] >= 0 THEN (*init code present: CALL p.ent[0]*); EmitWord(12B0H); EmitWord(p.ent[0]) END;
          p := p.next
        END
      END;
      IF (res = noerr) & (M.ent[0] < 0) THEN error(noinit, M.name) END;
      IF res = noerr THEN
        MakeFileName(name, S.s, ".txt"); F := Files.New(name); Files.Set(R, F, 0);

        i := 32 - vecsize DIV 2; isrtrap := -1; (*install default ISR trap if required*)
        REPEAT
          IF vector[i] = 0FFFFH THEN (*isrtrap is needed*) isrtrap := Flash.origin + Flash.allocPtr;
            EmitWord(0D032H); EmitWord( 0010H); EmitWord(3FFDH) END;
          INC(i)
        UNTIL (i >= 31) OR (isrtrap > 0);

        (*write TI-TXT file*)
        i := 0; Files.Write(R, "@"); FilesEx.WriteHexHalfWord(R, Flash.origin); FilesEx.WriteLn(R); (*code*)
        WHILE i < Flash.allocPtr DO
          FilesEx.WriteHex(R, Flash.m[i]); Files.Write(R, " "); INC(i);
          IF i MOD 16 = 0 THEN FilesEx.WriteLn(R) END
        END;
        IF i MOD 16 # 0 THEN FilesEx.WriteLn(R) END;

        i := 0; x := 32 - vecsize DIV 2; Files.Write(R, "@"); FilesEx.WriteHexHalfWord(R, FlashEnd - vecsize); FilesEx.WriteLn(R); (*vector table*)
        WHILE x < 32 DO IF vector[x] = 0FFFFH THEN vector[x] := isrtrap END;
          FilesEx.WriteHex(R, vector[x] MOD 100H); Files.Write(R, " ");
          FilesEx.WriteHex(R, vector[x] DIV 100H MOD 100H); Files.Write(R, " ");
          INC(i,2); IF i MOD 16 = 0 THEN FilesEx.WriteLn(R) END;
          INC(x)
        END;
        IF i MOD 16 # 0 THEN FilesEx.WriteLn(R) END;
        Files.Write(R, "q"); FilesEx.WriteLn(R);
        Files.Register(F);
        IF count MOD 8 # 0 THEN count := 0; Texts.WriteLn(W) END;
        Texts.WriteString(W, "    flash"); Texts.WriteInt(W, Flash.allocPtr, 5);
        Texts.WriteString(W, ", data"); Texts.WriteInt(W, RAMAllocPtr - RAMOrigin, 5);
        Texts.WriteString(W, ", stack"); Texts.WriteInt(W, RAMLimit - RAMAllocPtr, 5);
        Texts.WriteString(W, " bytes")
      ELSE oldcol := W.col; W.col := Display.red;
        Texts.WriteString(W, "Link error:  "); Texts.WriteString(W, importing);
        IF res = nofile THEN Texts.WriteString(W, " module not found")
        ELSIF res = duphandler THEN Texts.WriteString(W, " duplicate interrupt handler")
        ELSIF res = badkey THEN Texts.WriteString(W, " imports ");
          Texts.WriteString(W, imported); Texts.WriteString(W, " with bad key")
        ELSIF res = badfile THEN Texts.WriteString(W, " corrupted obj file")
        ELSIF res = nospace THEN Texts.WriteString(W, " insufficient space")
        ELSIF res = noinit THEN Texts.WriteString(W, " top module init code missing")
        ELSIF res = notsupported THEN Texts.WriteString(W, " version not supported")
        END; W.col := oldcol
      END
    ELSE Texts.WriteString(W, "Usage: OMSPL.Link VectorTableSize FlashSize RAMSize [module...] topmodule")
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Link;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OMSP linker  AP 6.8.20 / CS 26.10.25");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
END OMSPL.
