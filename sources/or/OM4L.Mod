MODULE OM4L;  (*Oberon boot linker/loader for RISC / AP 6.8.20 / CS 14/12/2023*)
  IMPORT SYSTEM, Kernel, OM4A, Files, Modules, Texts, Oberon;
  CONST versionkey = 1X; versionkey0 = 0X; 
    DescSize = 80; BootSec = 2;
    noerr = 0; nofile = 1; badversion = 2; badkey = 3; badfile = 4; nospace = 5;
    VarORG0 = 0D0201000H; MemLim = 0D0800000H; stackOrg = 10010000H;
    HeapOrg = 0D0500000H;
    DestAdr = 8; MemAdr = 12; AllocAdr = 16; RootAdr = 20; StackAdr = 24; HeapOrgAdr = 28;
    ModAdr = 32;
    C4 = 10H; C6 = 40H; C8 = 100H; C10 = 400H; C12 = 1000H; C14 = 4000H; C16 = 10000H;
    C18 = 40000H; C20 = 100000H; C22 = 400000H; C24 = 1000000H; BC = 0E7000000H; BL = 0F7000000H;

  VAR root: Modules.Module;
    AllocPtr, Start, limit, res: INTEGER;
    importing, imported: Modules.ModuleName;
    W: Texts.Writer;

  PROCEDURE thumbSwap(w: INTEGER): INTEGER;
  BEGIN
    RETURN w DIV 100H MOD 100H*1000000H
      + w MOD 100H*10000H
      + w DIV 1000000H MOD 100H*100H
      + w DIV 10000H MOD 100H
  END thumbSwap;

  (* Get unaligned words *)
  PROCEDURE GetWordAt(adr: INTEGER): INTEGER;
    VAR b1, b2, b3, b4: BYTE;
  BEGIN
    SYSTEM.GET(adr, b4); SYSTEM.GET(adr+1, b3); SYSTEM.GET(adr+2, b2); SYSTEM.GET(adr+3, b1);
    RETURN 0+b4+100H*(b3+100H*(b2+100H*b1))
  END GetWordAt;
  
  (* Put unaligned words *)
  PROCEDURE PutWordAt(adr, val: INTEGER);
    VAR b1, b2, b3, b4: BYTE;
  BEGIN
    b4 := val MOD 100H; val := val DIV 100H;
    b3 := val MOD 100H; val := val DIV 100H;
    b2 := val MOD 100H; val := val DIV 100H;
    b1 := val MOD 100H;
    SYSTEM.PUT(adr, b4); SYSTEM.PUT(adr+1, b3); SYSTEM.PUT(adr+2, b2); SYSTEM.PUT(adr+3, b1)
  END PutWordAt;
  
  PROCEDURE MakeFileName(VAR FName: ARRAY OF CHAR; name, ext: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN i := 0; j := 0;  (*assume name suffix less than 4 characters*)
    WHILE (i < 32-5) & (name[i] > 0X) DO FName[i] := name[i]; INC(i) END ;
    REPEAT FName[i]:= ext[j]; INC(i); INC(j) UNTIL ext[j] = 0X;
    FName[i] := 0X
  END MakeFileName;

  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR F: Files.File;
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

  PROCEDURE LinkOne(name: ARRAY OF CHAR; VAR newmod: Modules.Module);
    (*search module in list; if not found, link module.
      res = noerr: already present or linked;
      res = nofile: file not available;
      res = badversion: bad file version;
      res = badkey: key conflict;
      res = badfile: corrupted file;
      res = nospace: insufficient space*)
    VAR mod, impmod: Modules.Module;
      i, n, key, impkey, mno, nofimps, size: INTEGER;
      p, u, v, w: INTEGER;  (*addresses*)
      ch: CHAR;
      body: Modules.Command;
      fixorgP, fixorgD, fixorgT: INTEGER;
      disp, adr, inst, pno, vno, dest, offset: INTEGER;
      name1, impname: Modules.ModuleName;
      F: Files.File; R: Files.Rider;
      import: ARRAY 16 OF Modules.Module;
  BEGIN mod := root; error(noerr, name); nofimps := 0;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*link*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.Read(R, ch);
        Files.ReadInt(R, size); importing := name1;
        IF (ch = versionkey) (*regular module*) OR (ch = versionkey0) (*standalone program*) THEN
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = noerr) DO
            Files.ReadInt(R, impkey);
            LinkOne(impname, impmod); import[nofimps] := impmod; importing := name1;
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
        INC(size, DescSize);
        IF AllocPtr + size < limit THEN (*allocate*)
          p := AllocPtr; mod := SYSTEM.VAL(Modules.Module, p);
          AllocPtr := (p + size + 3) DIV 4 * 4; mod.size := AllocPtr - p;
          IF root = NIL THEN mod.num := 1 ELSE mod.num := root.num + 1 END ;
          mod.next := root; root := mod
        ELSE error(nospace, name1)
        END
      END ;
      IF res = noerr THEN (*read file*)
        INC(p, DescSize); (*allocate descriptor*)
        mod.name := name; 
        i := 0; REPEAT INC(i) UNTIL mod.name[i] = 0X; REPEAT mod.name[i] := 0X; INC(i) UNTIL i=32;
        mod.key := key; mod.refcnt := 0;
        mod.data := p;  (*data*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n, 4) END ;  (*type descriptors*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO SYSTEM.PUT(p, 0); INC(p, 4); DEC(n, 4) END ;  (*variable space*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.Read(R, ch); SYSTEM.PUT(p, ch); INC(p); DEC(n) END ;   (*strings*)
        mod.code := p;  (*program*)
        Files.ReadInt(R, n); (*In Cortex M4 implementation, program size is counted in bytes*)
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n, 4) END ;  (*program code*)
        mod.imp := p;  (*copy imports*)
        i := 0;
        WHILE i < nofimps DO
          SYSTEM.PUT(p, import[i]); INC(p, 4); INC(i)
        END ;
        mod.cmd := p;  (*commands*) Files.Read(R, ch);
        WHILE ch # 0X DO
          REPEAT SYSTEM.PUT(p, ch); INC(p); Files.Read(R, ch) UNTIL ch = 0X;
          REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
          Files.ReadInt(R, n); SYSTEM.PUT(p, n); INC(p, 4); Files.Read(R, ch)
        END ;
        REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
        mod.ent := p;  (*entries*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n) END ;
        mod.ptr := p;  (*pointer references*)
        Files.ReadInt(R, w);
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.data + w - Start + VarORG0); INC(p, 4); Files.ReadInt(R, w) END ;
        SYSTEM.PUT(p, 0); INC(p, 4);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgD); Files.ReadInt(R, fixorgT);
        Files.ReadInt(R, w); body := SYSTEM.VAL(Modules.Command, mod.code + w - Start + VarORG0);
        Files.Read(R, ch);
        IF ch # "O" THEN mod := NIL; error(badfile, name) END
      END ;
      IF res = noerr THEN (*fixup of BL*)
        adr := mod.code + fixorgP;
        WHILE adr # mod.code DO
          inst := GetWordAt(adr);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          mno := inst DIV 10000000H MOD 10H;
          pno := inst DIV 100000H MOD 100H;
          disp := inst MOD 100000H*2;
          SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
          SYSTEM.GET(impmod.ent + pno*4, dest); dest := dest + impmod.code;
          (*dest contains the address of the called procedure relative to Start*)
          offset := dest - adr - 4; (* Offset in bytes *)
          PutWordAt(adr, thumbSwap(OM4A.BL + OM4A.formatEvenImm25(offset)));
          adr := adr - disp
        END ;
        (*fixup of MOV/MOVT*)
        adr := mod.code + fixorgD;
        WHILE adr # mod.code DO
          inst := GetWordAt(adr);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          pno := inst DIV 10000000H MOD 10H; (*destination register*)
          mno := inst DIV 1000000H MOD 10H;
          disp := inst MOD 1000000H*2;
          inst := GetWordAt(adr+4);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          IF mno = 0 THEN (*global*)
            dest := mod.data + inst MOD 1000000H - Start + VarORG0
          ELSE (*import*)  vno := inst MOD 100H;
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            IF ODD(inst DIV 100H) THEN dest := impmod.code + offset - Start + VarORG0
            ELSE dest := impmod.data + offset - Start + VarORG0 END
          END;
          PutWordAt(adr, thumbSwap(OM4A.MOVIT3 + OM4A.formatImm16(pno, dest MOD 10000H)));
          PutWordAt(adr+4, thumbSwap(OM4A.MOVT + OM4A.formatImm16(pno, dest DIV 10000H MOD 10000H)));
          adr := adr - disp
        END ;
        ASSERT(adr = mod.code);
        (*fixup of type descriptors*)
        adr := mod.data + fixorgT*4;
        WHILE adr # mod.data DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV C24 MOD C4;
          vno := inst DIV C12 MOD C12;
          disp := inst MOD C12;
          IF mno = 0 THEN (*global*) inst := mod.data - Start + VarORG0 + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.data - Start + VarORG0 + offset
          END ;
          SYSTEM.PUT(adr, inst); adr := adr - disp*4
        END ;
        SYSTEM.PUT(Start, body) (*module initialization body*)
      ELSIF res >= badkey THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); DEC(import[nofimps].refcnt) END
      END
    END ;
    newmod := mod
  END LinkOne;

  PROCEDURE Link*;  (*link multiple object files together and create a single boot file M.bin from them*)
    VAR i, x: INTEGER;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
      M, p: Modules.Module;
      name: Modules.ModuleName;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN
      root := NIL; Start := Modules.AllocPtr; AllocPtr :=  Start + ModAdr; i := Start;
      WHILE i < AllocPtr DO SYSTEM.PUT(i, 0); INC(i, 4) END ;
      REPEAT LinkOne(S.s, M); Texts.Scan(S) UNTIL (S.class # Texts.Name) OR (res # noerr);
      IF res = noerr THEN p := root; Texts.WriteString(W, "  linking");
        WHILE p # NIL DO (*fixup*) Texts.Write(W, " "); Texts.WriteString(W, p.name);
          M := p; p := p.next;
          IF p # NIL THEN M.next := SYSTEM.VAL(Modules.Module, SYSTEM.VAL(INTEGER, p) - Start + VarORG0) END ;
          M.data := M.data - Start + VarORG0;
          M.code := M.code - Start + VarORG0;
          i := M.imp;
          WHILE i < M.cmd DO SYSTEM.GET(i, x); SYSTEM.PUT(i, x - Start + VarORG0); INC(i, 4) END ;
          M.imp := M.imp - Start + VarORG0;
          M.cmd := M.cmd - Start + VarORG0;
          M.ent := M.ent - Start + VarORG0;
          M.ptr := M.ptr - Start + VarORG0
        END ;
        SYSTEM.GET(Start, x);  (*address of initialization body of the top module relative to Start*)
        SYSTEM.PUT(Start, thumbSwap(OM4A.BT4 + OM4A.formatEvenImm25(x - 4 - VarORG0)));  (*branch instruction to the initialization body of the top module*)
        SYSTEM.PUT(Start + DestAdr, VarORG0);  (*destination address of the prelinked, executable binary*)
        SYSTEM.PUT(Start + MemAdr, MemLim);  (*limit of available memory, typically overwritten by the boot loader*)
        SYSTEM.PUT(Start + AllocAdr, AllocPtr - Start + VarORG0);  (*address of the end of the module space loaded*)
        SYSTEM.PUT(Start + RootAdr, SYSTEM.VAL(INTEGER, root) - Start + VarORG0);  (*current root of the links of loaded modules*)
        SYSTEM.PUT(Start + StackAdr, stackOrg);  (*current limit of the module area, typically overwritten by the boot loader*)
        SYSTEM.PUT(Start + HeapOrgAdr, HeapOrg);  (*start of heeap area*)
        MakeFileName(name, S.s, ".bin"); F := Files.New(name); Files.Set(R, F, 0); i := Start;
        WHILE i < AllocPtr DO SYSTEM.GET(i, x); Files.WriteInt(R, x); INC(i, 4) END ;
        Texts.WriteHex(W, AllocPtr - Start + VarORG0); Files.Register(F)
      ELSE
        Texts.WriteString(W, "Link error:  "); Texts.WriteString(W, importing);
        IF res = nofile THEN Texts.WriteString(W, " module not found")
        ELSIF res = badversion THEN Texts.WriteString(W, " bad version")
        ELSIF res = badkey THEN Texts.WriteString(W, " imports ");
          Texts.WriteString(W, imported); Texts.WriteString(W, " with bad key")
        ELSIF res = badfile THEN Texts.WriteString(W, " corrupted obj file")
        ELSIF res = nospace THEN Texts.WriteString(W, " insufficient space")
        END
      END
    ELSE Texts.WriteString(W, "Usage: OM4L.Link [module...] topmodule")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); root := NIL
  END Link;

(* Disabled for now to avoid RISC-5 bootfile corruption
  PROCEDURE Load*;  (*load prelinked boot file M.bin onto the boot area of the local disk*)
    VAR i, secno: LONGINT; b: BYTE;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
      buf: ARRAY Kernel.SectorLength OF BYTE;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "  loading "); Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN Texts.WriteString(W, " onto boot area"); Texts.WriteInt(W, Files.Length(F), 7);
        secno := BootSec; i := 0; Files.Set(R, F, 0); Files.ReadByte(R, b); res := noerr;
        WHILE ~R.eof DO buf[i] := b; INC(i);
          IF i = Kernel.SectorLength THEN Kernel.PutSector(secno*29, buf); INC(secno); i := 0 END ;
          Files.ReadByte(R, b)
        END ;
        IF i > 0 THEN
          WHILE i < Kernel.SectorLength DO buf[i] := 0; INC(i) END ;
          Kernel.PutSector(secno*29, buf)
        END
      ELSE Texts.WriteString(W, " not found")
      END
    ELSE Texts.WriteString(W, "Usage: OM4L.Load M.bin")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Load;
*)

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4 Boot linker/loader  AP 6.8.20 / CS 14/12/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); 
  SYSTEM.GET(HeapOrg, limit); (*The end of the module space is the beginning of the heap*)
  IF limit = 0 THEN limit := Kernel.stackOrg - Kernel.stackSize END; (*Hack if ran by RISC-5 machine*)
END OM4L.
