MODULE OM4L;  (*Oberon boot linker/loader for Cortex M4 STM32I-DISCO / AP 6.8.20 / CS 25.02.25*)
  IMPORT SYSTEM, Kernel, A := OM4A, Files, Modules, Texts, Oberon, FLASH;
  CONST DescSize = 80; BootSec = 2;
    noerr = 0; nofile = 1; badversion = 2; badkey = 3; badfile = 4; nospace = 5; nofit = 6; different = 7;
    MemLim = 0D0800000H; stackOrg = 10010000H; SDCard = 200001ACH;
    HeapOrg = 0D0500000H;
    SDHandleAdr = 4; DestAdr = 8; MemAdr = 12; AllocAdr = 16; RootAdr = 20; StackAdr = 24; HeapOrgAdr = 28;
    ModAdr = 32;
 
    TYPE ModulesList = POINTER TO ModulesListDesc;
      ModulesListDesc = RECORD body: INTEGER; next: ModulesList END;
      Segment = RECORD org, size, start, cur: INTEGER END;

  VAR root: Modules.Module;
    limit, res: INTEGER;
    importing, imported: Modules.ModuleName;
    modules, tail: ModulesList;
    sdram, flash, sram: Segment;
    W: Texts.Writer;

  PROCEDURE thumbSwap(w: INTEGER): INTEGER;
  BEGIN
    RETURN w DIV 100H MOD 100H*1000000H
      + w MOD 100H*10000H
      + w DIV 1000000H MOD 100H*100H
      + w DIV 10000H MOD 100H
  END thumbSwap;

  PROCEDURE MakeFileName(VAR FName: ARRAY OF CHAR; name, ext: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN i := 0; j := 0;  (*assume name suffix less than 4 characters*)
    WHILE (i < 32-5) & (name[i] > 0X) DO FName[i] := name[i]; INC(i) END ;
    REPEAT FName[i]:= ext[j]; INC(i); INC(j) UNTIL ext[j] = 0X;
    FName[i] := 0X
  END MakeFileName;

  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR F!: Files.File;
      filename: Modules.ModuleName;
  BEGIN MakeFileName(filename, name, ".m4c"); F := Files.Old(filename); RETURN F
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

  PROCEDURE put(VAR s: Segment; data: INTEGER);
  BEGIN
    IF s.cur + 4 <= s.size THEN 
      IF s.start # 0 THEN SYSTEM.PUT(s.start + s.cur, data) END;
      INC(s.cur, 4)
    ELSE res := nofit 
    END
  END put;

  PROCEDURE putByte(VAR s: Segment; data: BYTE);
  BEGIN
    IF s.cur + 1 <= s.size THEN 
      IF s.start # 0 THEN SYSTEM.PUT(s.start + s.cur, data) END;
      INC(s.cur)
    ELSE res := nofit 
    END
  END putByte;

  PROCEDURE checkSize(VAR s: Segment; sz: INTEGER);
  BEGIN IF s.start + s.cur + sz > limit THEN res := nospace END
  END checkSize;

  PROCEDURE allocate(VAR s: Segment; sz: INTEGER);
  BEGIN INC(s.cur, sz);
  END allocate;

   PROCEDURE LinkOne(name: ARRAY OF CHAR; VAR newmod: Modules.Module; VAR code, var, const: Segment);
    (*search module in list; if not found, link module.
      res = noerr: already present or linked;
      res = nofile: file not available;
      res = badversion: bad file version;
      res = badkey: key conflict;
      res = badfile: corrupted file;
      res = nospace: insufficient space
      res = nofit: insufficient space in section

      Object code V2 file format:
      CodeFile    = name key version size imports typedesc varsize strings code commands entries ptrrefs fixP fixV fixC fixT body "O".
      imports      = {modname key} 0X.
      typedesc    = nof {byte}.
      strings        = nof {char}
      code          = nof {word}.
      commands = {comname offset} 0X.
      entries       = nof {word}.
      ptrrefs        = {word} 0.
    *)
    VAR mod!, impmod!: Modules.Module;
      i, n, key, impkey, mno, nofimps, size: INTEGER;
      startMod, w: INTEGER;  (*addresses*)
      ch: CHAR; version: BYTE;
      fixorgP, fixorgV, fixorgC, fixorgT: INTEGER;
      disp, adr, inst, pno, vno, dest, offset: INTEGER;
      name1, impname: Modules.ModuleName;
      F!: Files.File; R!: Files.Rider;
      import!: ARRAY 16 OF Modules.Module;
  BEGIN mod := root; error(noerr, name); nofimps := 0;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*link*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.ReadByte(R, version);
        Files.ReadInt(R, size); importing := name1;
        IF (version = 1) & (var.org = const.org) OR (version = 2) (*regular module*) THEN
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = noerr) DO
            Files.ReadInt(R, impkey);
            LinkOne(impname, impmod, code, var, const); import[nofimps] := impmod; importing := name1;
            IF res = noerr THEN
              IF impmod.key = impkey THEN INC(impmod.refcnt); INC(nofimps)
              ELSE error(badkey, name1); imported := impname
              END
            END ;
            Files.ReadString(R, impname)
          END
        ELSE error(badversion, name1)
        END
      ELSE error(nofile, name)
      END ;
      IF res = noerr THEN
        INC(size, DescSize); checkSize(code, size);
        IF res = noerr THEN (*allocate*)
          startMod := code.cur; mod := SYSTEM.VAL(Modules.Module, code.start + startMod);
          IF root = NIL THEN mod.num := 1 ELSE mod.num := root.num + 1 END ;
          IF tail = NIL THEN NEW(tail); modules := tail ELSE NEW(tail.next); tail := tail.next END;
          mod.next := root; root := mod
        ELSE error(nospace, name1)
        END
      END ;
      IF res = noerr THEN (*read file*)
        allocate(const, DescSize); (*allocate descriptor*)
        mod.name := name; 
        i := 0; REPEAT INC(i) UNTIL mod.name[i] = 0X; REPEAT mod.name[i] := 0X; INC(i) UNTIL i=32;
        mod.key := key; mod.refcnt := 0;
        mod.const := const.cur;
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); put(const, w); DEC(n, 4) END ;  (*type descriptors*)
        IF version = 2 THEN Files.ReadInt(R, n); (*strings are stored before variables*)
         WHILE n > 0 DO Files.Read(R, ch); putByte(const, ORD(ch)); DEC(n) END ;
          mod.data := var.cur
        ELSE mod.data := mod.const
        END;
        Files.ReadInt(R, n); (*variables*)
        IF var.start = 0 THEN allocate(var, n) (*variable space*)
        ELSE WHILE n > 0 DO put(var, 0); DEC(n, 4) END
        END;
        IF version < 2 THEN Files.ReadInt(R, n); (*strings are stored after variables*)
          WHILE n > 0 DO Files.Read(R, ch); putByte(const, ORD(ch)); DEC(n) END
        END;
        mod.code := code.cur;  (*program*)
        Files.ReadInt(R, n); (*In Cortex M4 implementation, program size is counted in bytes*)
        WHILE n > 0 DO Files.ReadInt(R, w); put(code, w); DEC(n, 4) END ;  (*program code*)
        mod.imp := const.cur;  (*copy imports*)
        i := 0;
        WHILE i < nofimps DO
          put(const, SYSTEM.VAL(INTEGER, import[i])); INC(i)
        END ;
        mod.cmd := const.cur;  (*commands*) Files.Read(R, ch);
        WHILE ch # 0X DO
          REPEAT putByte(const, ORD(ch)); Files.Read(R, ch) UNTIL ch = 0X;
          REPEAT putByte(const, 0) UNTIL const.cur MOD 4 = 0;
          Files.ReadInt(R, n); put(const, n); Files.Read(R, ch)
        END ;
        REPEAT put(const, 0) UNTIL const.cur MOD 4 = 0;
        mod.ent := const.cur;  (*entries*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); put(const, w); DEC(n) END ;
        mod.ptr := const.cur;  (*pointer references*)
        Files.ReadInt(R, w);
        WHILE w >= 0 DO put(const, mod.data + w + var.org); Files.ReadInt(R, w) END ;
        put(const, 0);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgV);
        IF version = 2 THEN Files.ReadInt(R, fixorgC) END; Files.ReadInt(R, fixorgT);
        Files.ReadInt(R, w); tail.body := SYSTEM.VAL(INTEGER, mod.code + w);
        Files.Read(R, ch);
        IF ch # "O" THEN mod := NIL; error(badfile, name) END
      END ;
      IF res = noerr THEN (*fixup of BL*)
        adr := mod.code + fixorgP;
        WHILE adr # mod.code DO
          SYSTEM.GET(code.start + adr, inst);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          mno := inst DIV 10000000H MOD 10H;
          pno := inst DIV 100000H MOD 100H;
          disp := inst MOD 100000H*2;
          SYSTEM.GET(const.start + mod.imp + (mno-1)*4, impmod);
          SYSTEM.GET(const.start + impmod.ent + pno*4, dest); dest := dest + impmod.code;
          (*dest contains the address of the called procedure relative to Start*)
          offset := dest - adr - 4; (* Offset in bytes *)
          SYSTEM.PUT(code.start + adr, thumbSwap(A.BL + A.formatEvenImm25(offset)));
          adr := adr - disp
        END ;
        (*fixup of MOV/MOVT*)
        adr := mod.code + fixorgV; (*variable chain*)
        WHILE adr # mod.code DO
          SYSTEM.GET(code.start + adr, inst);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          pno := inst DIV 10000000H MOD 10H; (*destination register*)
          mno := inst DIV 1000000H MOD 10H;
          disp := inst MOD 1000000H*2;
          SYSTEM.GET(code.start + adr+4, inst);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          IF mno = 0 THEN (*global*)
            dest := mod.data + inst MOD 1000000H + var.org
          ELSE (*import*)  vno := inst MOD 100H;
            SYSTEM.GET(const.start + mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(const.start + impmod.ent + vno*4, offset);
            IF ODD(inst DIV 100H) THEN dest := impmod.code + offset + 1 + code.org (*thumb execution state*)
            ELSE dest := impmod.data + offset + var.org END
          END;
          SYSTEM.PUT(code.start + adr, thumbSwap(A.MOVIT3 + A.formatImm16(pno, dest MOD 10000H)));
          SYSTEM.PUT(code.start + adr+4, thumbSwap(A.MOVT + A.formatImm16(pno, dest DIV 10000H MOD 10000H)));
          adr := adr - disp
        END;
        IF version = 2 THEN
          adr := mod.code + fixorgC; (*constant chain*)
          WHILE adr # mod.code DO
            SYSTEM.GET(code.start + adr, inst);
            inst := thumbSwap(inst); (*Put bytes in the right order*)
            pno := inst DIV 10000000H MOD 10H; (*destination register*)
            mno := inst DIV 1000000H MOD 10H;
            disp := inst MOD 1000000H*2;
            SYSTEM.GET(code.start + adr+4, inst);
            inst := thumbSwap(inst); (*Put bytes in the right order*)
            IF mno = 0 THEN (*global*)
              dest := mod.const + inst MOD 1000000H + const.org
            ELSE (*import*)  vno := inst MOD 100H;
              SYSTEM.GET(const.start + mod.imp + (mno-1)*4, impmod);
              SYSTEM.GET(const.start + impmod.ent + vno*4, offset);
              IF ODD(inst DIV 100H) THEN dest := impmod.code + offset + 1 + code.org (*thumb execution state*)
              ELSE dest := impmod.const + offset + const.org END
            END;
            SYSTEM.PUT(code.start + adr, thumbSwap(A.MOVIT3 + A.formatImm16(pno, dest MOD 10000H)));
            SYSTEM.PUT(code.start + adr+4, thumbSwap(A.MOVT + A.formatImm16(pno, dest DIV 10000H MOD 10000H)));
            adr := adr - disp
          END;
        END;
        (*fixup of type descriptors*)
        adr := mod.const + fixorgT*4;
        WHILE adr # mod.const DO
          SYSTEM.GET(const.start + adr, inst);
          mno := inst DIV A.C24 MOD A.C4;
          vno := inst DIV A.C12 MOD A.C12;
          disp := inst MOD A.C12;
          IF mno = 0 THEN (*global*) inst := mod.const + const.org + vno
          ELSE (*import*)
            SYSTEM.GET(const.start + mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(const.start + impmod.ent + vno*4, offset);
            inst := impmod.const + const.org + offset
          END ;
          SYSTEM.PUT(const.start + adr, inst); adr := adr - disp*4
        END ;
        mod.size := (const.cur - startMod + 3) DIV 4*4
      ELSIF res >= badkey THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); DEC(import[nofimps].refcnt) END
      END
    END ;
    newmod := mod
  END LinkOne;

  PROCEDURE Link*;  (*link multiple object files together and create a single boot file M.bin from them*)
    VAR i, x: INTEGER;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
      M!, p!: Modules.Module;
      name: Modules.ModuleName;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN root := NIL; sdram.start := Modules.AllocPtr; sdram.cur := 0;
      i := 0; WHILE i < ModAdr DO put(sdram, 0); INC(i, 4) END ;
      REPEAT LinkOne(S.s, M, sdram, sdram, sdram); Texts.Scan(S) UNTIL (S.class # Texts.Name) OR (res # noerr);
      IF res = noerr THEN p := root; Texts.WriteString(W, "  linking");
        WHILE p # NIL DO (*fixup*) Texts.Write(W, " "); Texts.WriteString(W, p.name);
          M := p; p := p.next;
          IF p # NIL THEN M.next := SYSTEM.VAL(Modules.Module, SYSTEM.VAL(INTEGER, p) - sdram.start + sdram.org) END ;
          INC(M.const, sdram.org);
          INC(M.data, sdram.org);
          INC(M.code, sdram.org);
          i := M.imp;
          WHILE i < M.cmd DO SYSTEM.GET(i + sdram.start, x); SYSTEM.PUT(i + sdram.start, x -sdram.start + sdram.org); INC(i, 4) END ;
          INC(M.imp, sdram.org);
          INC(M.cmd, sdram.org);
          INC(M.ent, sdram.org);
          INC(M.ptr, sdram.org)
        END ;
        SYSTEM.PUT(sdram.start, thumbSwap(A.BT4 + A.formatEvenImm25(sdram.cur - 4)));  (*branch instruction to the initialization sequence*)
        tail := modules; (*generate initilization sequence*)
        WHILE tail # NIL DO (*call each module body in order*)
          put(sdram, thumbSwap(A.BL + A.formatEvenImm25(tail.body - 4 - sdram.cur)));
          tail := tail.next
        END;
        SYSTEM.PUT(sdram.start + DestAdr, sdram.org);  (*destination address of the prelinked, executable binary*)
        SYSTEM.PUT(sdram.start + SDHandleAdr, SDCard);  (*address of the SD card description*)
        SYSTEM.PUT(sdram.start + MemAdr, MemLim);  (*limit of available memory*)
        SYSTEM.PUT(sdram.start + AllocAdr, sdram.cur + sdram.org);  (*address of the end of the module space loaded*)
        SYSTEM.PUT(sdram.start + RootAdr, SYSTEM.VAL(INTEGER, root) - sdram.start + sdram.org);  (*current root of the links of loaded modules*)
        SYSTEM.PUT(sdram.start + StackAdr, stackOrg);  (*current limit of the module area*)
        SYSTEM.PUT(sdram.start + HeapOrgAdr, HeapOrg);  (*start of heeap area*)
        MakeFileName(name, S.s, ".bin"); F := Files.New(name); Files.Set(R, F, 0); i := sdram.start;
        WHILE i < sdram.cur + sdram.start DO SYSTEM.GET(i, x); Files.WriteInt(R, x); INC(i, 4) END ;
        Texts.WriteInt(W, sdram.cur, 8); Files.Register(F)
      ELSE
        Texts.WriteString(W, "Link error:  "); Texts.WriteString(W, importing);
        IF res = nofile THEN Texts.WriteString(W, " module not found")
        ELSIF res = badversion THEN Texts.WriteString(W, " bad version")
        ELSIF res = badkey THEN Texts.WriteString(W, " imports ");
          Texts.WriteString(W, imported); Texts.WriteString(W, " with bad key")
        ELSIF res = badfile THEN Texts.WriteString(W, " corrupted obj file")
        ELSIF res = nospace THEN Texts.WriteString(W, " insufficient space")
        ELSIF res = nofit THEN Texts.WriteString(W, " insufficient space in section")
        END
      END
    ELSE Texts.WriteString(W, "Usage: OM4L.Link [module...] topmodule")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); root := NIL; modules := NIL
  END Link;

  PROCEDURE LinkEF*;  (*link multiple object files together and create a single FLASH boot file M.efb from them*)
    VAR i, x, pc: INTEGER;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
      M!, p!: Modules.Module;
      name: Modules.ModuleName;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN root := NIL; flash.start := Modules.AllocPtr; flash.cur := 0;
      sram.start := 0; sram.cur := 0;
      i := 0; WHILE i < ModAdr DO put(flash, 0); INC(i, 4) END;
      REPEAT LinkOne(S.s, M, flash, sram, flash); Texts.Scan(S) UNTIL (S.class # Texts.Name) OR (res # noerr);
      IF res = noerr THEN p := root; Texts.WriteString(W, "  linking");
        WHILE p # NIL DO (*fixup*) Texts.Write(W, " "); Texts.WriteString(W, p.name);
          M := p; p := p.next;
          IF p # NIL THEN M.next := SYSTEM.VAL(Modules.Module, SYSTEM.VAL(INTEGER, p) - flash.start + flash.org) END ;
          INC(M.const, flash.org);
          INC(M.data, sram.org);
          INC(M.code, flash.org);
          i := M.imp;
          WHILE i < M.cmd DO SYSTEM.GET(i + flash.start, x); SYSTEM.PUT(i + flash.start, x - flash.start + flash.org); INC(i, 4) END ;
          INC(M.imp, flash.org);
          INC(M.cmd, flash.org);
          INC(M.ent, flash.org);
          INC(M.ptr, flash.org);
          M.refcnt := -1; (*cannot be unloaded*)
        END ;
        SYSTEM.PUT(flash.start, thumbSwap(A.BT4 + A.formatEvenImm25(flash.cur - 4)));  (*branch instruction to the initialization sequence*)
        ASSERT(sram.cur MOD 4 = 0);
        IF sram.cur > 0 THEN
          putByte(flash, 0); putByte(flash, 20H); (* MOVS R0, #0*)
          put(flash, thumbSwap(A.MOVIT3 + A.formatImm16(1, sram.org MOD 10000H)));
          put(flash, thumbSwap(A.MOVT + A.formatImm16(1, sram.org DIV 10000H MOD 10000H))); (* MOV R1, <sram.org>*)
          put(flash, thumbSwap(A.MOVIT3 + A.formatImm16(2, sram.cur DIV 4 MOD 10000H)));
          put(flash, thumbSwap(A.MOVT + A.formatImm16(2, sram.cur DIV 40000H MOD 10000H))); (* MOV R2, <sram.cur DIV 4>*)
          pc := flash.cur; put(flash, thumbSwap(A.STRIT4 + A.C16 + A.formatPUWImm8(FALSE, TRUE, TRUE, 4)));  (*STR R0, [R1],#4*) 
          putByte(flash, 1); putByte(flash, 3AH); (*SUB R3, #1*);
          putByte(flash, (pc - flash.cur - 4) DIV 2 MOD A.C8); putByte(flash, A.BCT1 DIV A.C8 + A.NE) (*BNE <pc>*)
        END;
        tail := modules; (*generate initilization sequence*)
        WHILE tail # NIL DO (*call each module body in order*)
          put(flash, thumbSwap(A.BL + A.formatEvenImm25(tail.body - 4 - flash.cur)));
          tail := tail.next
        END;
        SYSTEM.PUT(flash.start + DestAdr, flash.org);  (*destination address of the prelinked, executable binary*)
        SYSTEM.PUT(flash.start + SDHandleAdr, SDCard);  (*address of the SD card description*)
        SYSTEM.PUT(flash.start + MemAdr, MemLim);  (*limit of available memory*)
        SYSTEM.PUT(flash.start + AllocAdr, sdram.org);  (*address of the first free module space*)
        SYSTEM.PUT(flash.start + RootAdr, SYSTEM.VAL(INTEGER, root) - flash.start + flash.org);  (*current root of the links of loaded modules*)
        SYSTEM.PUT(flash.start + StackAdr, stackOrg);  (*current limit of the module area*)
        SYSTEM.PUT(flash.start + HeapOrgAdr, HeapOrg);  (*start of heeap area*)
        IF flash.cur MOD 4 # 0 THEN putByte(flash, 0); putByte(flash, 0BFH) (*padding NOP*) END; ASSERT(flash.cur MOD 4 = 0);
        MakeFileName(name, S.s, ".efb"); F := Files.New(name); Files.Set(R, F, 0); i := flash.start;
        WHILE i < flash.cur + flash.start DO SYSTEM.GET(i, x); Files.WriteInt(R, x); INC(i, 4) END ;
        Texts.WriteInt(W, flash.cur, 8); Texts.WriteInt(W, sram.cur, 8); Files.Register(F)
      ELSE
        Texts.WriteString(W, "Link error:  "); Texts.WriteString(W, importing);
        IF res = nofile THEN Texts.WriteString(W, " module not found")
        ELSIF res = badversion THEN Texts.WriteString(W, " bad version")
        ELSIF res = badkey THEN Texts.WriteString(W, " imports ");
          Texts.WriteString(W, imported); Texts.WriteString(W, " with bad key")
        ELSIF res = badfile THEN Texts.WriteString(W, " corrupted obj file")
        ELSIF res = nospace THEN Texts.WriteString(W, " insufficient space")
        ELSIF res = nofit THEN Texts.WriteString(W, " insufficient space in section")
        END
      END
    ELSE Texts.WriteString(W, "Usage: OM4L.Link [module...] topmodule")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); root := NIL; modules := NIL
  END LinkEF;

  PROCEDURE Load*;  (*load prelinked boot file M.bin onto the boot area of the local disk*)
    VAR i, secno: INTEGER; b: BYTE;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
      buf: ARRAY Kernel.SectorLength OF BYTE;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "  loading "); Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF (F # NIL) & (Files.Length(F) <= 63488) THEN Texts.WriteString(W, " onto boot area"); Texts.WriteInt(W, Files.Length(F), 7);
        secno := BootSec; i := 0; Files.Set(R, F, 0); Files.ReadByte(R, b); res := noerr;
        WHILE ~R.eof DO buf[i] := b; INC(i);
          IF i = Kernel.SectorLength THEN Kernel.PutSector(secno*29, buf); INC(secno); i := 0 END ;
          Files.ReadByte(R, b)
        END ;
        IF i > 0 THEN
          WHILE i < Kernel.SectorLength DO buf[i] := 0; INC(i) END ;
          Kernel.PutSector(secno*29, buf)
        END
      ELSE Texts.WriteString(W, " not found or too big")
      END
    ELSE Texts.WriteString(W, "Usage: OM4L.Load M.bin")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Load;

  PROCEDURE LoadEF*;  (*load prelinked boot file M.efb onto the module area of the internal flash memory*)
    VAR i, adr, d: INTEGER;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
      buf: ARRAY 32 OF INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "  loading "); Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN Files.Set(R, F, 8); Files.ReadInt(R, d);
        IF d = 08004000H THEN Texts.WriteString(W, " onto module area"); Texts.WriteInt(W, Files.Length(F), 7);
          FLASH.Open; adr := d; i := 0; Files.Set(R, F, 0); Files.ReadInt(R, d); res := noerr;
          WHILE ~R.eof DO buf[i] := d; INC(i);
            IF i = LEN(buf) THEN FLASH.Write(adr, buf, i); INC(adr, LEN(buf)*4); i := 0 END;
            Files.ReadInt(R, d)
          END ;
          IF i > 0 THEN FLASH.Write(adr, buf, i) END;
          FLASH.Close
        ELSE Texts.WriteString(W, " bad format")
        END
      ELSE Texts.WriteString(W, " not found")
      END
    ELSE Texts.WriteString(W, "Usage: OM4L.LoadEF M.efb")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END LoadEF;

  PROCEDURE CompareEF*;  (*compare prelinked boot file M.efb with the module area of the internal flash memory*)
    VAR adr, d, df: INTEGER;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "  comparing "); Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN Files.Set(R, F, 8); Files.ReadInt(R, d);
        IF d = 08004000H THEN Texts.WriteString(W, " with module area"); Texts.WriteInt(W, Files.Length(F), 7);
          adr := d; Files.Set(R, F, 0); Files.ReadInt(R, d); res := noerr;
          WHILE ~R.eof & (res = noerr) DO SYSTEM.GET(adr, df); INC(adr, 4);
            IF df # d THEN res := different END;
            Files.ReadInt(R, d)
          END;
          IF res = noerr THEN Texts.WriteString(W, " same") ELSE Texts.WriteString(W, " different") END
        ELSE Texts.WriteString(W, " bad format")
        END
      ELSE Texts.WriteString(W, " not found")
      END
    ELSE Texts.WriteString(W, "Usage: OM4L.CompareEF M.efb")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END CompareEF;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4 Boot linker/loader  AP 6.8.20 / CS 25.02.25");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); 
  limit := Kernel.heapOrg; (*The end of the module space is the beginning of the heap*)
  IF limit = 0 THEN limit := Kernel.stackOrg - Kernel.stackSize END; (*Hack if ran on RISC-5 machine*)
  sdram.org := 0D0201000H; sdram.size := limit - sdram.org; (*usable SDRAM area between system variables and heap*)
  flash.org := 08004000H; flash.size := 200000H - 4000H; (*usable flash area after the bootloader*)
  sram.org := 20000600H; sram.size := 30000H - 600H - 100H; (*usable sram area between sdcard buffer and main stack*)
END OM4L.
