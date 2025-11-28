MODULE OMSPL;  (*Oberon linker for MSP430 / AP 6.8.20 / CS 27.11.2025*)
  (* Object code V3 file format:
      CodeFile = name key version imports sections entries "O".
      imports  = {name key} 0X.
      sections = {segment name size content fixups} 0X.
      segment  = "r" | "c" | "d" | "s" | "v".
      content  = {byte}.
      fixups   = {fixadr mno sno offset} 0.
      entries  = nof {sno}.

      name: string containing the module or object name
      key: CRC32 hash of the modules's symbol file
      version: 0: legacy mode, 1: legacy RAM execution mode,
               2, 3: not used, reserved for future use
               4: sections mode, 5: sections RAM execution mode

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
          mno: the nodule index in the import array. The value 0 means
            the current module. Others values is the rank of the
            imported module.
          sno: is the section index in the mno indexed module.
          offset: is the offset in byte of the referenced data.
      
          the vectors table is a particular type of section flagged
          with "v" segment. It appears exactly once in the object file.
      
      nof: number of items
      sno: section index starting from 0.
      
      entries: exported objects. The first one is the section index of
        the initialization code of the module.
*)

  IMPORT SYSTEM, Modules, Display, G := OMSPG, Files, FilesEx, Texts, Oberon, TextsEx, L := SystemLog;
  CONST noerr = 0; nofile = 1; duphandler = 2; badkey = 3; badfile = 4; nospace = 5; nopar = 6; noinit = 7; notsupported = 8;
    RAMOrigin = 200H; FlashEnd = 10000H;
    EXEFlag = 10000H;

  TYPE 
    Module = POINTER TO ModDesc;
    Name = ARRAY 32 OF CHAR;

    ModDesc = RECORD
      name: Name;
      next: Module;
      key, num: INTEGER;
      varsto, flashsto, codeexe, codesto, codesize: INTEGER;  (*addresses*)
      ent: ARRAY 64 OF INTEGER;
      codeseg: BYTE
    END;

    Segment = POINTER TO SegmentDesc;

    SegmentDesc = RECORD
      origin, allocPtr: INTEGER;
      m: ARRAY FlashEnd OF BYTE
    END;

  VAR first, last, firstM, lastM: Module;
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

  PROCEDURE LinkOne(name: ARRAY OF CHAR; VAR newmod: Module;
    VAR sec: ARRAY OF INTEGER; VAR MW: Texts.Writer);
    (*search module in list; if not found, link module.
      res = noerr: already present or linked;
      res = nofile: file not available;
      res = badkey: key conflict;
      res = badfile: corrupted file;
      res = nospace: insufficient space*)
    VAR mod!, impmod!: Module;
      i, n, key, impkey, nofimps, nofsecs: INTEGER;
      w, size: INTEGER;  (*addresses and size*)
      ch: CHAR;
      adr, ofs, sno, no, dest: INTEGER;
      name1, impname: Name;
      F!: Files.File; R!: Files.Rider;
      import!: ARRAY 16 OF Module;
      mno, nv, codeseg: BYTE;
      vec: ARRAY 32 OF INTEGER;
      secfpos: INTEGER;
  BEGIN mod := first; error(noerr, name);
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*link*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.ReadByte(R, codeseg);
        IF codeseg IN {4, 5} THEN codeseg := codeseg MOD 2;
          IF name # name1 THEN error(badfile, name) END;
          importing := name1; nofimps := 0;
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = noerr) DO
            Files.ReadInt(R, impkey);
            LinkOne(impname, impmod, sec, MW); import[nofimps] := impmod; INC(nofimps);
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
        NEW(mod);
        IF first = NIL THEN mod.num := 1; first := mod ELSE mod.num := last.num + 1; last.next := mod END;
        last := mod; mod.next := NIL;
        mod.name := name;
        i := 0; REPEAT INC(i) UNTIL mod.name[i] = 0X; REPEAT mod.name[i] := 0X; INC(i) UNTIL i=32;
        mod.key := key; mod.codeseg := codeseg;
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
          Files.ReadString(R, name1); Texts.WriteString(MW, name1); Texts.Write(MW, 09X);Texts.Write(MW, ch);
          FilesEx.ReadHalfWord(R, size);
          IF (ch = "c") OR (ch = "d") OR (ch = "s") THEN (*in flash memory*)
            IF size >= G.WordSize THEN padFlash END; sec[nofsecs] := Flash.allocPtr + EXEFlag;
            TextsEx.WriteHexVLen(MW, Flash.allocPtr, 4, FALSE); Texts.Write(MW, 09X);
            FOR i := 0 TO size - 1 DO Files.ReadByte(R, mno); EmitByte(mno) END;
          ELSIF ch = "v" THEN (*vector table*)
            FOR i := 0 TO size DIV 2 - 1 DO FilesEx.ReadHalfWord(R, w); vec[i] := w END; (*module vector table*)
          ELSIF ch = "r" THEN
            IF size >= G.WordSize THEN align(RAMAllocPtr) END;
            TextsEx.WriteHexVLen(MW, RAMAllocPtr, 4, FALSE); Texts.Write(MW, 09X);
            sec[nofsecs] := RAMAllocPtr; INC(RAMAllocPtr, size)
          ELSE error(badfile, name)
          END;
          Texts.WriteInt(MW, size, 1); Texts.WriteLn(MW);
          FilesEx.ReadHalfWord(R, adr); (*skip fixup data*)
          WHILE adr # 0 DO
            Files.ReadByte(R, mno); FilesEx.ReadHalfWord(R, sno); FilesEx.ReadHalfWord(R, ofs);

            FilesEx.ReadHalfWord(R, adr)
          END;
          INC(nofsecs);
          Files.Read(R, ch)
        END;
        padFlash; mod.codesize := Flash.allocPtr - mod.flashsto;
        IF codeseg = 1 THEN mod.codeexe := RAMAllocPtr; INC(RAMAllocPtr, mod.codesize)
        ELSE mod.codeexe := Flash.origin + mod.flashsto
        END;
        Texts.WriteString(MW, "codeexe"); Texts.Write(MW, 09X); 
        TextsEx.WriteHexVLen(MW, mod.codeexe, 4, FALSE); Texts.WriteLn(MW);
        (*second pass: fixup addresses*)
        Files.Set(R, Files.Base(R), secfpos); (*rewind rider to beginning of sections list*)
        no := 0; Files.Read(R, ch);
        WHILE ch # 0X DO (*go to fixup data*)
          Files.ReadString(R, name1); FilesEx.ReadHalfWord(R, size);
          IF (ch = "c") OR (ch = "d") OR (ch = "s") THEN FOR i := 0 TO size - 1 DO Files.ReadByte(R, mno) END
          ELSIF ch = "v" THEN (*vector table*)
            FOR i := 0 TO size DIV 2 - 1 DO FilesEx.ReadHalfWord(R, w) END (*module vector table*)
          END;
          FilesEx.ReadHalfWord(R, adr); (*skip fixup data*)
          WHILE adr # 0 DO
            Files.ReadByte(R, mno); FilesEx.ReadHalfWord(R, sno); FilesEx.ReadHalfWord(R, ofs);
            IF mno = 0 THEN dest := sec[sno]; IF dest >= EXEFlag THEN DEC(dest, EXEFlag - mod.codeexe) END
            ELSE dest := import[mno - 1].ent[sno] END;
            INC(dest, ofs); (*dest contains now the runtime address*)
            IF ch = "v" THEN (*vector table*)
              REPEAT i := (adr - 1) DIV 2;
                IF vector[i] # 0FFFFH THEN
                  Texts.WriteString(W, "interrupt vector number"); Texts.WriteInt(W, i, 3); error(duphandler, name1)
                END;
                vector[i] := dest; adr := vec[i]
              UNTIL adr = 0;
            ELSE w := sec[no] MOD 10000H;
              REPEAT n := GetWordAt(w + adr - 1); PutWordAt(w + adr - 1, dest); adr := n UNTIL adr = 0
            END;

            FilesEx.ReadHalfWord(R, adr)
          END;

          INC(no); Files.Read(R, ch)
        END;
        FilesEx.ReadHalfWord(R, n); (*number of entries*)
        FOR i := 0 TO n - 1 DO FilesEx.ReadHalfWord(R, sno);
          dest := sec[sno]; IF dest >= EXEFlag THEN DEC(dest, EXEFlag - mod.codeexe) END;
          mod.ent[i] := dest
        END;

        IF GetWordAt(mod.codesto + mod.ent[0]) = 4130H THEN (*module init is empty*)
          DEC(mod.codesize, 2); mod.ent[0] := -1; (*mark init address as invalid*)
          IF codeseg = 1 THEN DEC(RAMAllocPtr, 2) END;
          DEC(Flash.allocPtr, 2)
        END;

        Files.Read(R, ch);
        IF ch # "O" THEN mod := NIL; error(badfile, name) END
      END ;
      IF res >= badkey THEN importing := name END
    END;
    newmod := mod
  END LinkOne;

  PROCEDURE Link*;  (*link multiple object files together and create a single MSP430 TI-TXT file M.txt from them*)
    VAR i, x, vecsize, isrtrap, count, oldcol: INTEGER;
      F!: Files.File; R!: Files.Rider; MT!: Texts.Text; MW!: Texts.Writer;
      S!: Texts.Scanner;
      M!, p!: Module;
      name: Name;
      modlist: ARRAY 64 OF Name;
      nbmod, mi: INTEGER;
      sec: ARRAY 512 OF INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := noerr; count := 0;
    Flash := SYSTEM.VAL(Segment, Modules.AllocPtr); FOR i := 0 TO 31 DO vector[i] := 0FFFFH END;
    IF S.class = Texts.Int THEN  vecsize := S.i; Texts.Scan(S) ELSE vecsize := 0; res := nopar END;
    IF S.class = Texts.Int THEN  limit := S.i - vecsize; Flash.origin := FlashEnd - S.i; Flash.allocPtr := 0; Texts.Scan(S) ELSE res := nopar END;
    IF (res = noerr) & (S.class = Texts.Int) THEN RAMLimit := RAMOrigin + S.i; RAMAllocPtr := RAMOrigin; Texts.Scan(S) ELSE res := nopar END;
    IF (res = noerr) & (S.class = Texts.Name) THEN nbmod := 0; REPEAT modlist[nbmod] := S.s; INC(nbmod); Texts.Scan(S) UNTIL S.class # Texts.Name;
(*      firstM := NIL; lastM := NIL; mi := 0; REPEAT Mark(modlist[mi], M); INC(mi) UNTIL (mi >= nbmod) OR (res # noerr);*)
      NEW(MT); Texts.Open(MT, ""); Texts.OpenWriter(MW);
      first := NIL; last := NIL; mi := 0; REPEAT LinkOne(modlist[mi], M, sec, MW); INC(mi) UNTIL (mi >= nbmod) OR (res # noerr);
      Texts.Append(MT, MW.buf);
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
      END;
      MakeFileName(name, S.s, ".map"); Texts.Close(MT, name)
    ELSE Texts.WriteString(W, "Usage: OMSPL.Link VectorTableSize FlashSize RAMSize [module...] topmodule")
    END;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Link;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OMSP linker  AP 6.8.20 / CS 26.10.25");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
END OMSPL.
