MODULE OMSPL;  (*Oberon linker for MSP430 / AP 6.8.20 / CS 27.11.2025*)
  (* Object code V3 file format:
      CodeFile = name key version imports sections entries "O".
      imports  = {name key} 0X.
      sections = {segment name size content fixups} 0X.
      segment  = "r" | "c" | "d" | "s" | "v".
      content  = {byte}.
      fixups   = {fixadr mno sno offset mnor snor} 0.
      entries  = nof {sno}.

      name: string containing the module or object name
      key: CRC32 hash of the modules's symbol file
      version: 0: legacy mode, 1: legacy RAM execution mode,
               2: sections mode, 3: sections RAM execution mode

      sections: blocks of data or code that can be omitted by
        the linker if they are not referenced. Except for vector table,
        each section corresponds to a global object (variable, stored const
        or procedure). Sections can appear in any order.
        
        segment: "r" for variables in RAM,
                 "c" for code in flash memory,
                 "d" for data in flash memory,
                 "s" for strings in flash memory,
                 "v" for vectors table
        size: size in bytes of the segment
        content: the code, data, strings or vector to be placed into flash memory.
          It is empty for RAM segment.
          
        fixups: these are backward linked list of referenced sections.
          The linker will walk them to resolve static addresses.
          
          fixadr: the address of the most recent reference to a section.
            the value at this address contains the next reference. The
            value 0 marks the end of the list.
          mno: the module index in the import array. The value 0 means
            the current module. Others values is the rank of the
            imported module.
          sno: is the section index in the mno indexed module.
          offset: is the offset in byte of the referenced data.
          mnor: if # 0FFH, mnor is the module index of a section used to compute an offset.
          snor: is the section index of an offset base. The offset placed in the generated code
                   follow this formula:
                     offset = address of section (mno, smo) plus offset minus address of section (mnor, smor)
      
          the vectors table is a particular type of section flagged
          with "v" segment. It appears exactly once in the object file.
      
      nof: number of items
      sno: section index starting from 0.
      
      entries: exported objects. The first one is the section index of
        the initialization code of the module.
*)

  IMPORT SYSTEM, Modules, Display, G := OMSPG, Files, FilesEx, Texts, Oberon, L := SystemLog;

  CONST version = 1;
    noerr = 0; nofile = 1; duphandler = 2; badkey = 3; badfile = 4; nospace = 5; nopar = 6; noinit = 7; notsupported = 8;
    RAMOrigin = 200H; FlashEnd = 10000H; MaxSec = 512;

  TYPE 
    Module = POINTER TO ModDesc;
    Name = ARRAY 32 OF CHAR;

    ModDesc = RECORD
      name: Name;
      next: Module;
      key, num: INTEGER;
      varsto, flashsto, codeexe, flashsize: INTEGER;  (*addresses*)
      ent: ARRAY 64 OF INTEGER;
      codeseg: BYTE
    END;

    Segment = POINTER TO SegmentDesc;

    SegmentDesc = RECORD
      origin, allocPtr: INTEGER;
      m: ARRAY FlashEnd OF BYTE
    END;

    Section = RECORD
      segment: CHAR; name: Name;
      eadr, size: INTEGER (*effective address and size*)
    END;

    (*section dependency tree*)
    Depend = POINTER TO DependDesc;
    DependDesc = RECORD
      mno: BYTE;
      sno: INTEGER;
      next: Depend
    END;

    SecDep = POINTER TO SecDepDesc;
    SecDepDesc = RECORD
      no: INTEGER;
      dep: Depend;
      next: SecDep
    END;

    ModMaps = POINTER TO ModMapsDesc;
    ModMapsDesc = RECORD
      name: Name;
      next: ModMaps;
      sections: SecDep;
      import: ARRAY 16 OF ModMaps; nofimps: INTEGER;
      ent: ARRAY 64 OF INTEGER;
      refm, tdm: ARRAY MaxSec DIV 32 OF SET; (*bitmaps for referenced and to do sections*)
    END;

  VAR first, last: Module; maps: ModMaps;
    RAMAllocPtr, RAMLimit, limit, res: INTEGER;
    Flash: Segment; vector: ARRAY 32 OF INTEGER;
    importing, imported: Name;
    W: Texts.Writer;

  PROCEDURE align(VAR a: INTEGER);
  BEGIN a := (a + (G.WordSize - 1) ) DIV G.WordSize*G.WordSize
  END align;

  (* Get unaligned words *)
  PROCEDURE GetWordAt(adr: INTEGER): INTEGER;
    RETURN 0 + Flash.m[adr] + 100H*Flash.m[adr + 1]
  END GetWordAt;

  (* Put unaligned words *)
  PROCEDURE PutWordAt(adr, val: INTEGER);
  BEGIN Flash.m[adr] := val MOD 100H; val := val DIV 100H;
    Flash.m[adr + 1] := val MOD 100H;
  END PutWordAt;

  PROCEDURE EmitByte(val: BYTE);
  BEGIN 
    IF Flash.allocPtr <= limit THEN Flash.m[Flash.allocPtr] := val; INC(Flash.allocPtr)
    ELSE res := nospace
    END;
  END EmitByte;

  PROCEDURE EmitWord(val: INTEGER);
  BEGIN 
    IF Flash.allocPtr <= limit THEN PutWordAt(Flash.allocPtr, val); INC(Flash.allocPtr, G.WordSize);
    ELSE res := nospace
    END;
  END EmitWord;

  PROCEDURE padFlash; (*align flash allocatopn address a on word size boundary*)
  BEGIN WHILE Flash.allocPtr MOD G.WordSize # 0 DO EmitByte(0) END
  END padFlash;

  PROCEDURE MakeFileName(VAR FName: ARRAY OF CHAR; name, ext: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN i := 0; j := 0;  (*assume name suffix less than 4 characters*)
    WHILE (i < 32-5) & (name[i] > 0X) DO FName[i] := name[i]; INC(i) END ;
    REPEAT FName[i]:= ext[j]; INC(i); INC(j) UNTIL ext[j] = 0X;
    FName[i] := 0X
  END MakeFileName;

  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR F!: Files.File;
      filename: Name;
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

  PROCEDURE FindModMap(name: ARRAY OF CHAR; VAR mm: ModMaps);
  BEGIN mm := maps;
    WHILE (mm # NIL) & (name # mm.name) DO mm := mm.next END;
    IF mm = NIL THEN NEW(mm); mm.name := name; mm.next := maps; maps := mm END
  END FindModMap;

  PROCEDURE LinkOne(name: ARRAY OF CHAR; VAR newmod: Module;
    VAR sec: ARRAY OF Section; VAR MW: Texts.Writer);
    (*search module in list; if not found, link module.
      res = noerr: already present or linked;
      res = nofile: file not available;
      res = badkey: key conflict;
      res = badfile: corrupted file;
      res = nospace: insufficient space*)
    VAR mod!, impmod!: Module;
      i, k, l, nofimps: INTEGER;
      ch: CHAR;
      adr, ofs, sno, no, snor, dest: INTEGER; (*fixup data*)
      name1: Name;
      F!: Files.File; R!: Files.Rider;
      import!: ARRAY 16 OF Module;
      mno, mnor: BYTE;
      vec: ARRAY 32 OF INTEGER; (*vector table*)
      secfpos, nofsecs: INTEGER; mm!: ModMaps; keep: BOOLEAN;
  BEGIN mod := first; error(noerr, name);
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*link*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, k); Files.ReadByte(R, mno);
        IF mno IN {version*2, version*2+1} THEN mno := mno MOD 2;
          IF name = name1 THEN nofimps := 0;
            Files.ReadString(R, name1);   (*imports*)
            WHILE (name1[0] # 0X) & (res = noerr) DO
              Files.ReadInt(R, l);
              LinkOne(name1, impmod, sec, MW); import[nofimps] := impmod; INC(nofimps);
              IF res = noerr THEN
                IF impmod.key # l THEN error(badkey, name); imported := name1 END;
                Files.ReadString(R, name1)
              END
            END
          ELSE error(badfile, name)
          END
        ELSE error(notsupported, name)
        END
      ELSE error(nofile, name)
      END;
      IF res = noerr THEN MW.col := Display.yellow;
        Texts.WriteString(MW, "Module "); Texts.WriteString(MW, name); Texts.WriteLn(MW);
        MW.col := Display.white; FindModMap(name, mm);
        NEW(mod);
        IF first = NIL THEN mod.num := 1; first := mod ELSE mod.num := last.num + 1; last.next := mod END;
        last := mod; mod.next := NIL;
        mod.name := name;
        i := 0; REPEAT INC(i) UNTIL mod.name[i] = 0X; REPEAT mod.name[i] := 0X; INC(i) UNTIL i=32;
        mod.key := k; mod.codeseg := mno;
        mod.varsto := RAMAllocPtr; (*storage address in RAM*)
        mod.flashsto := Flash.allocPtr; (*storage address in flash memory*)
       (*sections:
           As the sections can appear in any order, a two passes processus is required.
           The first pass allocate space and load the contents of all the sections.
           The runtime addresses of all the sections are known after this pass.
           The second pass perform all the necessary runtime addresses fixups*)
        (*first pass: place sections*)
        secfpos := Files.Pos(R); nofsecs := 0;
        Files.Read(R, ch);
        WHILE ch # 0X DO
          sec[nofsecs].segment := ch; sec[nofsecs].eadr := -1;
          keep := nofsecs MOD 16 IN mm.refm[nofsecs DIV 16]; (*keep the section if referenced*)
(*L.DebugInt("sno", nofsecs, 1);
L.DebugBool("keep", keep);*)
          Files.ReadString(R, sec[nofsecs].name); Files.ReadHalfWord(R, sec[nofsecs].size);
          IF (ch = "c") OR (ch = "d") OR (ch = "s") THEN (*in flash memory*)
            IF keep THEN
              IF sec[nofsecs].size >= G.WordSize THEN padFlash END; sec[nofsecs].eadr := Flash.allocPtr;
              FOR i := 0 TO sec[nofsecs].size - 1 DO Files.ReadByte(R, mno); EmitByte(mno) END
            ELSE FOR i := 0 TO sec[nofsecs].size - 1 DO Files.ReadByte(R, mno) END (*skip data*)
            END
          ELSIF ch = "v" THEN (*vector table*)
            FOR i := 0 TO sec[nofsecs].size DIV 2 - 1 DO Files.ReadHalfWord(R, adr); vec[i] := adr END; (*module vector table*)
          ELSIF ch = "r" THEN
            IF keep THEN
              IF sec[nofsecs].size >= G.WordSize THEN align(RAMAllocPtr) END; sec[nofsecs].eadr := RAMAllocPtr;
              INC(RAMAllocPtr, sec[nofsecs].size)
            END
          ELSE error(badfile, name)
          END;
          Files.ReadHalfWord(R, adr); (*skip fixup data*)
          WHILE adr # 0 DO
            Files.ReadByte(R, mno); Files.ReadHalfWord(R, sno); Files.ReadHalfWord(R, ofs);
            Files.ReadByte(R, mnor); Files.ReadHalfWord(R, snor);
            Files.ReadHalfWord(R, adr)
          END;
          INC(nofsecs);
          Files.Read(R, ch)
        END;
        padFlash; mod.flashsize := Flash.allocPtr - mod.flashsto;
        IF mod.codeseg = 1 THEN (*execute in RAM*) mod.codeexe := RAMAllocPtr; INC(RAMAllocPtr, mod.flashsize)
        ELSE mod.codeexe := Flash.origin + mod.flashsto
        END;
        (*compute effective address*)
        FOR i := 0 TO nofsecs - 1 DO
          IF i MOD 16 IN mm.refm[i DIV 16] THEN (*adjust address of the section if referenced*)
            Texts.WriteString(MW, sec[i].name); Texts.Write(MW, 09X);
            ch := sec[i].segment; Texts.Write(MW, ch);
            IF (ch = "c") OR (ch = "d") OR (ch = "s") THEN (*in flash memory*)
              DEC(sec[i].eadr, mod.flashsto - mod.codeexe)
            END; 
            IF ch # "v" THEN Texts.WriteHexVLen(MW, sec[i].eadr, 4, FALSE) END; Texts.Write(MW, 09X);
            Texts.WriteInt(MW, sec[i].size, 1); Texts.WriteLn(MW)
          END
        END;

        Texts.WriteString(MW, "codeexe"); Texts.Write(MW, 09X); 
        Texts.WriteHexVLen(MW, mod.codeexe, 4, FALSE); Texts.WriteLn(MW);
        (*second pass: fixup addresses*)
        Files.Set(R, Files.Base(R), secfpos); (*rewind rider to beginning of sections list*)
        no := 0; Files.Read(R, ch);
        WHILE ch # 0X DO (*go to fixup data*)
          keep := no MOD 16 IN mm.refm[no DIV 16]; (*fixup the section dependencies if referenced*)
          Files.ReadString(R, name1); Files.ReadHalfWord(R, k);
          IF (ch = "c") OR (ch = "d") OR (ch = "s") OR (ch = "v") THEN
            FOR i := 0 TO k - 1 DO Files.ReadByte(R, mno) END (*skip content*)
          END;
          Files.ReadHalfWord(R, adr); (*entering fixup data*)
          WHILE adr # 0 DO
            Files.ReadByte(R, mno); Files.ReadHalfWord(R, sno); Files.ReadHalfWord(R, ofs);
            Files.ReadByte(R, mnor); Files.ReadHalfWord(R, snor);
            IF keep THEN
              IF mno = 0 THEN dest := sec[sno].eadr ELSE dest := import[mno - 1].ent[sno] END;
              INC(dest, ofs); (*dest contains now the effective address*)
              IF mnor # 0FFH THEN
                IF mnor = 0 THEN DEC(dest, sec[snor].eadr) ELSE DEC(dest, import[mnor - 1].ent[snor]) END
              END;
              IF ch = "v" THEN (*vector table*)
                REPEAT i := (adr - 1) DIV 2;
                  IF vector[i] # 0FFFFH THEN
                    Texts.WriteString(W, "interrupt vector number"); Texts.WriteInt(W, i, 3); error(duphandler, name1)
                  END;
                  vector[i] := dest; adr := vec[i]
                UNTIL adr = 0;
              ELSE l := sec[no].eadr; IF ch # "r" THEN DEC(l, mod.codeexe - mod.flashsto) END;
                REPEAT k := GetWordAt(l + adr - 1); PutWordAt(l + adr - 1, dest); adr := k UNTIL adr = 0
              END
            END;
            Files.ReadHalfWord(R, adr)
          END;
          INC(no); Files.Read(R, ch)
        END;
        Files.ReadHalfWord(R, k); (*number of entries*)
        FOR i := 0 TO k - 1 DO Files.ReadHalfWord(R, sno);
          mod.ent[i] := sec[sno].eadr
        END;

        IF GetWordAt(mod.ent[0] - mod.codeexe + mod.flashsto) = 4130H THEN (*module init is empty*)
          DEC(mod.flashsize, 2); mod.ent[0] := -1; (*mark init address as invalid*)
          IF mod.codeseg = 1 THEN DEC(RAMAllocPtr, 2) END;
          DEC(Flash.allocPtr, 2)
        END;

        Files.Read(R, ch);
        IF ch # "O" THEN mod := NIL; error(badfile, name) END
      END ;
      IF res >= badkey THEN importing := name END;
      Texts.WriteLn(MW)
    END;
    newmod := mod
  END LinkOne;

(*
  PROCEDURE FindSecDep(mm: ModMaps; sno: INTEGER; VAR s: SecDep);
  BEGIN s := mm.sections;
    WHILE (s # NIL) & (sno # s.no) DO s := s.next END;
    IF s = NIL THEN NEW(s); s.no := sno; s.next := mm.sections; mm.sections := s END
  END FindSecDep;
*)

  PROCEDURE Mark(name: ARRAY OF CHAR; VAR mm: ModMaps);
    VAR im!: ModMaps;
      F!: Files.File; R!: Files.Rider;
      name1: Name;
      ch: CHAR; b: BYTE;
      i, w, no: INTEGER;
      s!: SecDep; d!: Depend; done: BOOLEAN;
  BEGIN error(noerr, name);
    FindModMap(name, mm);
    IF mm.sections = NIL THEN (*load module data from object file*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, w); Files.ReadByte(R, b);
        IF b IN {version*2, version*2+1} THEN
          IF name = name1 THEN mm.import[0] := mm;
            Files.ReadString(R, name1);   (*imports*)
            WHILE (name1[0] # 0X) & (res = noerr) DO
              Files.ReadInt(R, w); Mark(name1, im); INC(mm.nofimps); mm.import[mm.nofimps] := im;
              Files.ReadString(R, name1)
            END;
            no := 0; Files.Read(R, ch);  (*sections*)
            WHILE ch # 0X DO NEW(s); s.next := mm.sections; mm.sections := s; s.no := no;
              IF ch = "v" THEN INCL(mm.tdm[no DIV 32], no MOD 32) END; (*add the interrupt handler to do list*)
              (*go to fixup data*)
              Files.ReadString(R, name1); Files.ReadHalfWord(R, w);
              IF (ch = "c") OR (ch = "d") OR (ch = "s") OR (ch = "v") THEN
                FOR i := 0 TO w - 1 DO Files.ReadByte(R, b) END (*skip content*)
              END;
              Files.ReadHalfWord(R, w); (*entering fixup data*)
              WHILE w # 0 DO NEW(d); d.next := s.dep; s.dep := d;
                Files.ReadByte(R, d.mno); Files.ReadHalfWord(R, d.sno); Files.ReadHalfWord(R, i); (*skip offset*)
                Files.ReadByte(R, b); Files.ReadHalfWord(R, w);
                IF b # 0FFH THEN NEW(d); d.next := s.dep; s.dep := d; d.mno := b; d.sno := w END;
                Files.ReadHalfWord(R, w)
              END;
              INC(no); Files.Read(R, ch)
            END;
            Files.ReadHalfWord(R, w); (*number of entries*)
            FOR i := 0 TO w - 1 DO Files.ReadHalfWord(R, mm.ent[i]) END;
            INCL(mm.tdm[mm.ent[0] DIV 32], mm.ent[0] MOD 32); (*add the module init section to the to do list*)
            Files.Read(R, ch);
            IF ch # "O" THEN mm := NIL; error(badfile, name) END
          ELSE error(badfile, name)
          END
        ELSE error(notsupported, name)
        END
      ELSE error(nofile, name)
      END
    END;
    IF res = noerr THEN (*process the to do list*)
      REPEAT done := TRUE;
        s := mm.sections;
        WHILE s # NIL DO
          IF s.no MOD 32 IN mm.tdm[s.no DIV 32] THEN
            IF ~(s.no MOD 32 IN mm.refm[s.no DIV 32]) THEN
              INCL(mm.refm[s.no DIV 32], s.no MOD 32); (*insert in referenced map*)
              d := s.dep;
              WHILE d # NIL DO
                (*insert referenced section in to do list*)
                IF d.mno = 0 THEN (*current module*) INCL(mm.tdm[d.sno DIV 32], d.sno MOD 32)
                ELSE (*imported*) im := mm.import[d.mno]; i := im.ent[d.sno];
                  INCL(im.tdm[i DIV 32], i MOD 32);
                END;
                done := FALSE;
                d := d.next
              END
            END;
            EXCL(mm.tdm[s.no DIV 32], s.no MOD 32); (*remove from to do list*)
          END;
          s := s.next
        END
      UNTIL done
    END;
    FOR i := 1 TO mm.nofimps DO Mark(mm.import[i].name, im) END
  END Mark;

  PROCEDURE Link*;  (*link multiple object files together and create a single MSP430 TI-TXT file M.txt from them*)
    VAR i, x, vecsize, isrtrap, count, oldcol: INTEGER;
      F!: Files.File; R!: Files.Rider; MT!: Texts.Text; MW!: Texts.Writer;
      S!: Texts.Scanner;
      M!, p!: Module; MM!: ModMaps;
      name: Name;
      modlist: ARRAY 64 OF Name;
      nbmod, mi: INTEGER;
      sec: ARRAY MaxSec OF Section;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := noerr; count := 0;
    Flash := SYSTEM.VAL(Segment, Modules.AllocPtr); FOR i := 0 TO 31 DO vector[i] := 0FFFFH END;
    IF S.class = Texts.Int THEN  vecsize := S.i; Texts.Scan(S) ELSE vecsize := 0; res := nopar END;
    IF S.class = Texts.Int THEN  limit := S.i - vecsize; Flash.origin := FlashEnd - S.i; Flash.allocPtr := 0; Texts.Scan(S) ELSE res := nopar END;
    IF (res = noerr) & (S.class = Texts.Int) THEN RAMLimit := RAMOrigin + S.i; RAMAllocPtr := RAMOrigin; Texts.Scan(S) ELSE res := nopar END;
    IF (res = noerr) & (S.class = Texts.Name) THEN nbmod := 0; REPEAT modlist[nbmod] := S.s; INC(nbmod); Texts.Scan(S) UNTIL S.class # Texts.Name;
      maps := NIL; mi := 0; REPEAT Mark(modlist[mi], MM); INC(mi) UNTIL (mi >= nbmod) OR (res # noerr);
      NEW(MT); Texts.Open(MT, ""); Texts.OpenWriter(MW);
      first := NIL; last := NIL; mi := 0; REPEAT LinkOne(modlist[mi], M, sec, MW); INC(mi) UNTIL (mi >= nbmod) OR (res # noerr);
      Texts.Append(MT, MW.buf);
      IF res = noerr THEN Texts.WriteString(W, "  linking");
        (*prolog*) padFlash; vector[31] := Flash.origin + Flash.allocPtr; p := first;
        (*MOV RAMLimit, SP*) EmitWord(4031H); EmitWord(RAMLimit);
        WHILE p # NIL DO (*fixup*) Texts.Write(W, " "); Texts.WriteString(W, p.name);
          IF p.codeseg = 1 THEN (*module executed from RAM*) Texts.Write(W, "*");
            (*copy code from Flash to RAM*)
            (*MOV p.flashsize DIV 2,R15*) EmitWord(403FH); EmitWord(p.flashsize DIV 2);
            (*MOV Flash.origin + p.flashsto,R14*) EmitWord(403EH);  EmitWord(Flash.origin + p.flashsto);
            (*MOV @R14+,p.codeexe - (Flash.origin + p.flashsto)(R14) - 2*) EmitWord(4EBEH); EmitWord(p.codeexe - Flash.origin - p.flashsto - 2);
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
      ELSE  Texts.WriteLn(W); oldcol := W.col; W.col := Display.red;
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
      END;
      MakeFileName(name, S.s, ".map"); Texts.Close(MT, name)
    ELSE Texts.WriteString(W, "Usage: OMSPL.Link VectorTableSize FlashSize RAMSize [module...] topmodule")
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
    first := NIL; last := NIL; maps := NIL
  END Link;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OMSP linker  AP 6.8.20 / CS 26.10.25");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
END OMSPL.
