MODULE Modules;  (*Link and load; NW 20.10.2013 / 8.1.2019
  on Cortex M4 CS 12/12/2023*)
  IMPORT SYSTEM, Kernel, Files;
  CONST DescSize = 80;

    (*Powers of two*)
    C31=80000000H; C30=40000000H; C28=10000000H; C27=8000000H; C26=4000000H;
    C25=2000000H; C24=1000000H; C23=800000H; C22=400000H; 
    C21=200000H; C20=100000H; C19=80000H; C18=40000H; C17=20000H;
    C16=10000H; C15= 8000H; C13=2000H; C12=1000H; C11=800H; 
    C10=400H; C9=200H;C8=100H; C7=80H; C6=40H; C5=20H; 
    C4=10H; C3=8; C2=4; C1=2; C0=1;

    BL = 0F000D000H;
    (*|1111/0S  /im10/    /11J1/J   /im11/    |
                             1  2
      BL<c><q> <label>*)
  
    MOVIT3  = 0F2400000H;
    (*|1111/0i10/0100/imm4/0im3/ Rd / imm/8   |
      MOVW<c> <Rd>,#<imm16>*)

    MOVT    = 0F2C00000H;
    (*|1111/0i10/1100/imm4/0im3/ Rd / imm/8   |
      MOVT<c> <Rd>,#<imm16>*)

  TYPE Module* = POINTER TO ModDesc;
    Command* = PROCEDURE;
    ModuleName* = ARRAY 32 OF CHAR;

    ModDesc* = RECORD
        name*: ModuleName;
        next*: Module;
        key*, num*, size*, refcnt*: INTEGER;
        data*, code*, imp*, cmd*, ent*, ptr*, const*: INTEGER  (*addresses*)
      END ;

  VAR root*, M: Module;
    AllocPtr*, res*: INTEGER;
    importing*, imported*: ModuleName;
    limit: INTEGER;

  PROCEDURE formatEvenImm25(disp: INTEGER): INTEGER;
  (* |00000S   imm10  00J0J   imm11   |
     |                  1 2
     I1 = NOT(J1 EOR S); I2 = NOT(J2 EOR S); imm32 = SignExtend(S:I1:I2:imm10:imm11:'0', 32);
  *) 
  VAR res: INTEGER;
    S, J1, J2: BYTE;
    imm10, imm11: INTEGER;
  BEGIN
    disp := disp DIV C1;
    S := disp DIV C23 MOD C1;
    disp := disp MOD C23;
    (*J1 = NOT(I1) EOR S
     J2 = NOT(I2) EOR S*)
    J1 := disp DIV C22 MOD C1;
    disp := disp MOD C22;
    J2 := disp DIV C21 MOD C1;
    disp := disp MOD C21;
    IF S=0 THEN
      J1 := 1-J1;
      J2 := 1-J2;
    END;
    imm10 := disp DIV C11 MOD C10;
    imm11 := disp MOD C11;
 
    RETURN imm11 + S*C26 + imm10*C16+J1*C13+J2*C11
  END formatEvenImm25;
  
  PROCEDURE formatImm16(reg: BYTE; val: INTEGER): INTEGER;
  (*|xxxxxixxxxxximm4ximm reg  imm8  |
    |                   3            |
    val = imm4:i:imm3:imm8*)
  BEGIN
    RETURN val DIV C12 MOD C4*C16 + val DIV C11 MOD C1*C26 + 
           val DIV C8 MOD C3*C12 + reg*C8 + val MOD C8
  END formatImm16;

  PROCEDURE thumbSwap(w: INTEGER): INTEGER;
  BEGIN
    RETURN w DIV 100H MOD 100H*1000000H
      + w MOD 100H*10000H
      + w DIV 1000000H MOD 100H*100H
      + w DIV 10000H MOD 100H
  END thumbSwap;
    
  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR i: INTEGER;
      filename: ModuleName;
  BEGIN i := 0;
    WHILE name[i] # 0X DO filename[i] := name[i]; INC(i) END ;
    filename[i] := "."; filename[i+1] := "m"; filename[i+2] := "4"; filename[i+3] := "c"; filename[i+4] := 0X;
    RETURN Files.Old(filename)
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

  PROCEDURE IncRefcnt*(VAR mod: Module; v: INTEGER);
  BEGIN IF mod.refcnt # -1 THEN INC(mod.refcnt, v) END
  END IncRefcnt;

  PROCEDURE Load*(name: ARRAY OF CHAR; VAR newmod: Module);
    (*search module in list; if not found, load module.
      res = 0: already present or loaded; res = 2: file not available; res = 3: key conflict;
      res = 4: bad file version; res = 5: corrupted file; res = 7: no space*)
    VAR mod!, impmod!: Module;
      i, n, key, impkey, mno, nofimps, size: INTEGER;
      p, u, v, w: INTEGER;  (*addresses*)
      b: BYTE;
      ch: CHAR;
      shrinkable: BOOLEAN;
      body: Command;
      fixorgP, fixorgD, fixorgT: INTEGER;
      disp, adr, inst, pno, vno, dest, offset, trpbase, noftrps: INTEGER;
      name1, impname: ModuleName;
      F!: Files.File; R!: Files.Rider;
      import!: ARRAY 16 OF Module;
  BEGIN mod := root; error(0, name); nofimps := 0; shrinkable := FALSE;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*load*)
      Check(name);
      IF res = 0 THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.Read(R, ch);
        Files.ReadInt(R, size); importing := name1;
        IF ch = 1X THEN
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = 0) DO
            Files.ReadInt(R, impkey);
            Load(impname, impmod); import[nofimps] := impmod; importing := name1;
            IF res = 0 THEN
              IF impmod.key = impkey THEN INC(impmod.refcnt); INC(nofimps)
              ELSE error(3, name1); imported := impname
              END
            END ;
            Files.ReadString(R, impname)
          END
        ELSE error(2, name1)
        END
      ELSE error(1, name)
      END ;
      IF res = 0 THEN (*search for a hole in the list allocate and link*)
        INC(size, DescSize); mod := root;
        WHILE (mod # NIL) & ~((mod.name[0] = 0X) & (mod.size >= size)) DO mod := mod.next END ;
        IF mod = NIL THEN (*no large enough hole was found*)
          IF AllocPtr + size < limit THEN (*allocate*)
            shrinkable := TRUE;
            p := AllocPtr; mod := SYSTEM.VAL(Module, p);
            AllocPtr := (p + size + 3) DIV 4 * 4; mod.size := AllocPtr - p; mod.num := root.num + 1;
            mod.next := root; root := mod
          ELSE error(7, name1)
          END
        ELSE (*fill hole*) p := SYSTEM.VAL(INTEGER, mod)
        END
      END ; 
      IF res = 0 THEN (*read file*)
        INC(p, DescSize); (*allocate descriptor*)
        mod.name := name; mod.key := key; mod.refcnt := 0;
        mod.data := p;  (*data*); mod.const := mod.data;
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
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.data + w); INC(p, 4); Files.ReadInt(R, w) END ;
        SYSTEM.PUT(p, 0); INC(p, 4);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgD); Files.ReadInt(R, fixorgT);
        Files.ReadInt(R, w); body := SYSTEM.VAL(Command, mod.code + w + 1);
        Files.Read(R, ch);
        IF ch # "O" THEN (*corrupted file*)  mod := NIL; error(4, name) END
      END ;
      IF res = 0 THEN (*fixup of BL*)
        noftrps := 0; trpbase := p; (*trampoline area*)
        adr := mod.code + fixorgP;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          mno := inst DIV 10000000H MOD 10H;
          pno := inst DIV 100000H MOD 100H;
          disp := inst MOD 100000H*2;
          SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
          SYSTEM.GET(impmod.ent + pno*4, dest); dest := dest + impmod.code;
          (*dest contains the absolute address of the called procedure*)
          offset := dest - adr - 4; (* Offset in bytes *)
          IF (offset < -16777216) OR (offset >= 16777216) THEN
            (*The destination is out of reachable range. Install trampoline AKA veneer code in ARM world*)
            i := 0; u := trpbase;
            SYSTEM.GET(u+4, w);
            WHILE (i < noftrps) & (dest # w) DO INC(u, 8); SYSTEM.GET(u+4, w); INC(i) END;
            IF i >= noftrps THEN (*Create trampoline, u is aligned to 4 bytes boundary*)
              (*0DFF800F0H is object code for ldr pc, [pc] when pc MOD 4 = 0*)
              INC(noftrps); SYSTEM.PUT(u, 0DFF800F0H); SYSTEM.PUT(u+4, dest+1)
            END;
            dest := u; (*branch to trampoline*)
            offset := dest - adr - 4 (* Offset in bytes *)
          END;
          SYSTEM.PUT(adr, thumbSwap(BL + formatEvenImm25(offset)));
          adr := adr - disp
        END ;
        INC(p, noftrps*8);
        (*fixup of MOV/MOVT*)
        adr := mod.code + fixorgD;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          pno := inst DIV 10000000H MOD 10H; (*destination register*)
          mno := inst DIV 1000000H MOD 10H;
          disp := inst MOD 1000000H*2;
          SYSTEM.GET(adr+4, inst);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          IF mno = 0 THEN (*global*)
            dest := mod.data + inst MOD 1000000H
          ELSE (*import*)  vno := inst MOD 100H;
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            IF ODD(inst DIV 100H) THEN dest := impmod.code + offset + 1 (*thumb execution state*)
            ELSE dest := impmod.data + offset END
          END;
          SYSTEM.PUT(adr, thumbSwap(MOVIT3 + formatImm16(pno, dest MOD 10000H)));
          SYSTEM.PUT(adr+4, thumbSwap(MOVT + formatImm16(pno, dest DIV 10000H MOD 10000H)));
          adr := adr - disp
        END ;
        (*fixup of type descriptors*)
        adr := mod.data + fixorgT*4;
        WHILE adr # mod.data DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV 1000000H MOD 10H;
          vno := inst DIV 1000H MOD 1000H;
          disp := inst MOD 1000H;
          IF mno = 0 THEN (*global*) inst := mod.data + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.data + offset
          END ;
          SYSTEM.PUT(adr, inst); adr := adr - disp*4
        END ;
        body;   (*initialize module*)
        IF shrinkable & (AllocPtr > p) THEN DEC(mod.size, AllocPtr - p); AllocPtr := p END (*remove trampoline unused space*)
      ELSIF res >= 3 THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); DEC(import[nofimps].refcnt) END
      END 
    END ;
    newmod :=  mod
  END Load;

  PROCEDURE fixupMOV(VAR mod: Module; chain: INTEGER; varchain: BOOLEAN);
    VAR disp, adr, inst, mno, pno, vno, dest, offset: INTEGER;
      impmod!: Module; base: INTEGER;
  BEGIN 
    adr := mod.code + chain; (*chain root address*)
    WHILE adr # mod.code DO
      SYSTEM.GET(adr, inst);
      inst := thumbSwap(inst); (*Put bytes in the right order*)
      pno := inst DIV 10000000H MOD 10H; (*destination register*)
      mno := inst DIV 1000000H MOD 10H;
      disp := inst MOD 1000000H*2;
      SYSTEM.GET(adr+4, inst);
      inst := thumbSwap(inst); (*Put bytes in the right order*)
      IF mno = 0 THEN (*global*) IF varchain THEN base := mod.data ELSE base := mod.const END;
        dest := base + inst MOD 1000000H
      ELSE (*import*)  vno := inst MOD 100H;
        SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
        SYSTEM.GET(impmod.ent + vno*4, offset);
        IF ODD(inst DIV 100H) THEN dest := impmod.code + offset + 1 (*thumb execution state*)
        ELSE IF varchain THEN base := impmod.data ELSE base := impmod.const END; dest := base + offset END
      END;
      SYSTEM.PUT(adr, thumbSwap(MOVIT3 + formatImm16(pno, dest MOD 10000H)));
      SYSTEM.PUT(adr+4, thumbSwap(MOVT + formatImm16(pno, dest DIV 10000H MOD 10000H)));
      adr := adr - disp
    END;
  END fixupMOV;

 PROCEDURE Load2*(name: ARRAY OF CHAR; VAR newmod: Module);
    (*search module in list; if not found, load module.
      res = 0: already present or loaded; res = 1: file not available;
      res = 2: bad file version; res = 3: key conflict;
      res = 4: corrupted file; res = 7: no space*)
    VAR mod!, impmod!: Module;
      i, n, key, impkey, mno, nofimps, size: INTEGER;
      p, u, v, w: INTEGER;  (*addresses*)
      b, version: BYTE;
      ch: CHAR;
      shrinkable: BOOLEAN;
      body: Command;
      fixorgP, fixorgV, fixorgC, fixorgT: INTEGER;
      disp, adr, inst, pno, vno, dest, offset, trpbase, noftrps: INTEGER;
      name1, impname: ModuleName;
      F!: Files.File; R!: Files.Rider;
      import!: ARRAY 16 OF Module;
  BEGIN mod := root; error(0, name); nofimps := 0; shrinkable := FALSE;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*load*)
      Check(name);
      IF res = 0 THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.ReadByte(R, version);
        Files.ReadInt(R, size); importing := name1;
        IF version IN {1, 2} THEN
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = 0) DO
            Files.ReadInt(R, impkey);
            Load2(impname, impmod); import[nofimps] := impmod; importing := name1;
            IF res = 0 THEN
              IF impmod.key = impkey THEN IncRefcnt(impmod, 1); INC(nofimps)
              ELSE error(3, name1); imported := impname
              END
            END ;
            Files.ReadString(R, impname)
          END
        ELSE error(2, name1)
        END
      ELSE error(1, name)
      END ;
      IF res = 0 THEN (*search for a hole in the list allocate and link*)
        INC(size, DescSize); mod := root;
        WHILE (mod # NIL) & ~((mod.name[0] = 0X) & (mod.size >= size)) DO mod := mod.next END ;
        IF mod = NIL THEN (*no large enough hole was found*)
          IF AllocPtr + size < limit THEN (*allocate*)
            shrinkable := TRUE;
            p := AllocPtr; mod := SYSTEM.VAL(Module, p);
            AllocPtr := (p + size + 3) DIV 4 * 4; mod.size := AllocPtr - p; mod.num := root.num + 1;
            mod.next := root; root := mod
          ELSE error(7, name1)
          END
        ELSE (*fill hole*) p := SYSTEM.VAL(INTEGER, mod)
        END
      END ;
      IF res = 0 THEN (*read file*)
        INC(p, DescSize); (*allocate descriptor*)
        mod.name := name; mod.key := key; mod.refcnt := 0;
        mod.const := p; (*constants*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n, 4) END ;  (*type descriptors*)
        IF version = 2 THEN Files.ReadInt(R, n); (*strings are stored before variables*)
         WHILE n > 0 DO Files.Read(R, ch); SYSTEM.PUT(p, ch); INC(p); DEC(n) END;
          mod.data := p (*variables*)
        ELSE mod.data := mod.const
        END;
        Files.ReadInt(R, n);
        WHILE n > 0 DO SYSTEM.PUT(p, 0); INC(p, 4); DEC(n, 4) END ;  (*variable space*)
        IF version < 2 THEN Files.ReadInt(R, n); (*strings are stored after variables*)
          WHILE n > 0 DO Files.Read(R, ch); SYSTEM.PUT(p, ch); INC(p); DEC(n) END  (*strings*)
        END;
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
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.data + w); INC(p, 4); Files.ReadInt(R, w) END ;
        SYSTEM.PUT(p, 0); INC(p, 4);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgV);
        IF version = 2 THEN Files.ReadInt(R, fixorgC) END; Files.ReadInt(R, fixorgT);
        Files.ReadInt(R, w); body := SYSTEM.VAL(Command, mod.code + w + 1);
        Files.Read(R, ch);
        IF ch # "O" THEN (*corrupted file*)  mod := NIL; error(4, name) END
      END ;
      IF res = 0 THEN (*fixup of BL*)
        noftrps := 0; trpbase := p; (*trampoline area*)
        adr := mod.code + fixorgP;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
          inst := thumbSwap(inst); (*Put bytes in the right order*)
          mno := inst DIV 10000000H MOD 10H;
          pno := inst DIV 100000H MOD 100H;
          disp := inst MOD 100000H*2;
          SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
          SYSTEM.GET(impmod.ent + pno*4, dest); dest := dest + impmod.code;
          (*dest contains the absolute address of the called procedure*)
          offset := dest - adr - 4; (* Offset in bytes *)
          IF (offset < -16777216) OR (offset >= 16777216) THEN
            (*The destination is out of reachable range. Install trampoline AKA veneer code in ARM world*)
            i := 0; u := trpbase;
            SYSTEM.GET(u+4, w);
            WHILE (i < noftrps) & (dest # w) DO INC(u, 8); SYSTEM.GET(u+4, w); INC(i) END;
            IF i >= noftrps THEN (*Create trampoline, u is aligned to 4 bytes boundary*)
              (*0F8DFF000H is object code for ldr pc, [pc] when pc MOD 4 = 0*)
              INC(noftrps); SYSTEM.PUT(u, thumbSwap(0F8DFF000H)); SYSTEM.PUT(u+4, dest+1)
            END;
            dest := u; (*branch to trampoline*)
            offset := dest - adr - 4 (* Offset in bytes *)
          END;
          SYSTEM.PUT(adr, thumbSwap(BL + formatEvenImm25(offset)));
          adr := adr - disp
        END ;
        INC(p, noftrps*8);
        (*fixup of MOV/MOVT*)
        fixupMOV(mod, fixorgV, TRUE);
        IF version = 2 THEN fixupMOV(mod, fixorgC, FALSE) END;
        (*fixup of type descriptors*)
        adr := mod.const + fixorgT*4;
        WHILE adr # mod.const DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV 1000000H MOD 10H;
          vno := inst DIV 1000H MOD 1000H;
          disp := inst MOD 1000H;
          IF mno = 0 THEN (*global*) inst := mod.const + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.const + offset
          END ;
          SYSTEM.PUT(adr, inst); adr := adr - disp*4
        END ;
        body;   (*initialize module*)
        IF shrinkable & (AllocPtr > p) THEN DEC(mod.size, AllocPtr - p); AllocPtr := p END (*remove trampoline unused space*)
      ELSIF res >= 3 THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); IncRefcnt(import[nofimps], -1) END
      END 
    END ;
    newmod :=  mod
  END Load2;

  PROCEDURE ThisCommand*(mod: Module; name: ARRAY OF CHAR): Command;
    VAR k, adr, w: INTEGER; ch: CHAR;
      s: ARRAY 32 OF CHAR;
  BEGIN res := 5; w := 0;
    IF mod # NIL THEN
      adr := mod.cmd; SYSTEM.GET(adr, ch);
      WHILE (ch # 0X) & (res # 0) DO k := 0; (*read command name*)
        REPEAT s[k] := ch; INC(k); INC(adr); SYSTEM.GET(adr, ch) UNTIL ch = 0X;
        s[k] := 0X;
        REPEAT INC(adr) UNTIL adr MOD 4 = 0;
        SYSTEM.GET(adr, k); INC(adr, 4);
        IF s = name THEN res := 0; w := mod.code + k + 1 (*thumb execution state*) ELSE SYSTEM.GET(adr, ch) END
      END
    END
    RETURN SYSTEM.VAL(Command, w)
  END ThisCommand;

  PROCEDURE Free*(name: ARRAY OF CHAR);
    VAR mod!, imp!: Module; p, q: INTEGER;
  BEGIN mod := root; res := 0;
    WHILE (mod # NIL) & (mod.name # name) DO mod := mod.next END ;
    IF mod # NIL THEN
      IF mod.refcnt = 0 THEN
        mod.name[0] := 0X; p := mod.imp; q := mod.cmd;
        WHILE p < q DO SYSTEM.GET(p, imp); IncRefcnt(imp, -1); INC(p, 4) END;
        WHILE root.name[0] = 0X DO (*deallocate freed modules at end of module space*)
          AllocPtr := SYSTEM.VAL(INTEGER, root); root := root.next
        END
      ELSE res := 1
      END
    END
  END Free;

  PROCEDURE Init;
  BEGIN
    SYSTEM.GET(Kernel.bootParams+16, AllocPtr); SYSTEM.GET(Kernel.bootParams+20, root); 
    SYSTEM.GET(Kernel.bootParams+28, limit) (*The end of the module space is the beginning of the heap*)
  END Init;

BEGIN Init; Load("Oberon", M);
    LED(res); REPEAT UNTIL FALSE  (*only if load fails*)
END Modules.

OM4Tool.DecObj Modules.m4c
decode Modules.m4c
Modules D7D09919   2   4652
imports:
	Kernel B4228008
	Files 5B83E95D
type descriptors
 00000080 FFFFFFFF FFFFFFFF FFFFFFFF 00000020 FFFFFFFF
strings
Oberon||
data    84
code
commands:
entries
 0000111C 00000000 00000000 00000008 0000000C 00000010 00000030 000003AA 000003CA 00000EA4 00000FA4
pointer refs
     0     4
fixP =  00000A56
fixV =  00001138
fixC =  00001122
fixT =  00000000
entry =  0000111C
 00000000	     B084	SUB SP SP #16
 00000002	     B401	PUSH R0
 00000004	     B500	PUSH LR
 00000006	     9801	LDR R0 [ SP + 4 ]
 00000008	     1040	ASRS R0 R0 #1
 0000000A	     9001	STR R0 [ SP + 4 ]
 0000000C	     9801	LDR R0 [ SP + 4 ]
 0000000E	     15C0	ASRS R0 R0 #23
 00000010	 F36F005F	BFC R0 #1 #31
 00000014	 F88D000C	STRB R0 [  SP + 12 ]
 00000018	     9801	LDR R0 [ SP + 4 ]
 0000001A	 F36F50DF	BFC R0 #23 #9
 0000001E	     9001	STR R0 [ SP + 4 ]
 00000020	     9801	LDR R0 [ SP + 4 ]
 00000022	     1580	ASRS R0 R0 #22
 00000024	 F36F005F	BFC R0 #1 #31
 00000028	 F88D000D	STRB R0 [  SP + 13 ]
 0000002C	     9801	LDR R0 [ SP + 4 ]
 0000002E	 F36F509F	BFC R0 #22 #10
 00000032	     9001	STR R0 [ SP + 4 ]
 00000034	     9801	LDR R0 [ SP + 4 ]
 00000036	     1540	ASRS R0 R0 #21
 00000038	 F36F005F	BFC R0 #1 #31
 0000003C	 F88D000E	STRB R0 [  SP + 14 ]
 00000040	     9801	LDR R0 [ SP + 4 ]
 00000042	 F36F505F	BFC R0 #21 #11
 00000046	     9001	STR R0 [ SP + 4 ]
 00000048	 F89D000C	LDRB R0 [ SP + 12 ]
 0000004C	     2800	CMP R0 #0
 0000004E	 F040800C	BNE #24, goes to  0000006A
 00000052	 F89D000D	LDRB R0 [ SP + 13 ]
 00000056	 F1D00001	RSBS R0 R0 #1
 0000005A	 F88D000D	STRB R0 [  SP + 13 ]
 0000005E	 F89D000E	LDRB R0 [ SP + 14 ]
 00000062	 F1D00001	RSBS R0 R0 #1
 00000066	 F88D000E	STRB R0 [  SP + 14 ]
 0000006A	     9801	LDR R0 [ SP + 4 ]
 0000006C	     12C0	ASRS R0 R0 #11
 0000006E	 F36F209F	BFC R0 #10 #22
 00000072	     9004	STR R0 [ SP + 16 ]
 00000074	     9801	LDR R0 [ SP + 4 ]
 00000076	 F36F20DF	BFC R0 #11 #21
 0000007A	     9005	STR R0 [ SP + 20 ]
 0000007C	 F89D000C	LDRB R0 [ SP + 12 ]
 00000080	     0680	LSLS R0 R0 #26
 00000082	     9905	LDR R1 [ SP + 20 ]
 00000084	     1808	ADDS R0 R1 R0
 00000086	     9904	LDR R1 [ SP + 16 ]
 00000088	     0409	LSLS R1 R1 #16
 0000008A	     1840	ADDS R0 R0 R1
 0000008C	 F89D100D	LDRB R1 [ SP + 13 ]
 00000090	     0349	LSLS R1 R1 #13
 00000092	     1840	ADDS R0 R0 R1
 00000094	 F89D100E	LDRB R1 [ SP + 14 ]
 00000098	     02C9	LSLS R1 R1 #11
 0000009A	     1840	ADDS R0 R0 R1
 0000009C	 F85DEB04	LDR LR [ SP ] + 4
 000000A0	     B005	ADD SP SP #20
 000000A2	     4770	BX LR
 000000A4	     B403	PUSH R0 R1
 000000A6	     B500	PUSH LR
 000000A8	     9802	LDR R0 [ SP + 8 ]
 000000AA	     1300	ASRS R0 R0 #12
 000000AC	 F36F101F	BFC R0 #4 #28
 000000B0	     0400	LSLS R0 R0 #16
 000000B2	     9902	LDR R1 [ SP + 8 ]
 000000B4	     12C9	ASRS R1 R1 #11
 000000B6	 F36F015F	BFC R1 #1 #31
 000000BA	     0689	LSLS R1 R1 #26
 000000BC	     1840	ADDS R0 R0 R1
 000000BE	     9902	LDR R1 [ SP + 8 ]
 000000C0	     1209	ASRS R1 R1 #8
 000000C2	 F36F01DF	BFC R1 #3 #29
 000000C6	     0309	LSLS R1 R1 #12
 000000C8	     1840	ADDS R0 R0 R1
 000000CA	 F89D1004	LDRB R1 [ SP + 4 ]
 000000CE	     0209	LSLS R1 R1 #8
 000000D0	     1840	ADDS R0 R0 R1
 000000D2	     9902	LDR R1 [ SP + 8 ]
 000000D4	 F36F211F	BFC R1 #8 #24
 000000D8	     1840	ADDS R0 R0 R1
 000000DA	 F85DEB04	LDR LR [ SP ] + 4
 000000DE	     B002	ADD SP SP #8
 000000E0	     4770	BX LR
 000000E2	     B401	PUSH R0
 000000E4	     B500	PUSH LR
 000000E6	     9801	LDR R0 [ SP + 4 ]
 000000E8	     1200	ASRS R0 R0 #8
 000000EA	 F36F201F	BFC R0 #8 #24
 000000EE	     0600	LSLS R0 R0 #24
 000000F0	     9901	LDR R1 [ SP + 4 ]
 000000F2	 F36F211F	BFC R1 #8 #24
 000000F6	     0409	LSLS R1 R1 #16
 000000F8	     1840	ADDS R0 R0 R1
 000000FA	     9901	LDR R1 [ SP + 4 ]
 000000FC	     1609	ASRS R1 R1 #24
 000000FE	 F36F211F	BFC R1 #8 #24
 00000102	     0209	LSLS R1 R1 #8
 00000104	     1840	ADDS R0 R0 R1
 00000106	     9901	LDR R1 [ SP + 4 ]
 00000108	     1409	ASRS R1 R1 #16
 0000010A	 F36F211F	BFC R1 #8 #24
 0000010E	     1840	ADDS R0 R0 R1
 00000110	 F85DEB04	LDR LR [ SP ] + 4
 00000114	     B001	ADD SP SP #4
 00000116	     4770	BX LR
 00000118	     B081	SUB SP SP #4
 0000011A	     B401	PUSH R0
 0000011C	     B500	PUSH LR
 0000011E	     9801	LDR R0 [ SP + 4 ]
 00000120	     7800	LDRB R0 [ R0 + 0 ]
 00000122	 F88D000B	STRB R0 [  SP + 11 ]
 00000126	     9801	LDR R0 [ SP + 4 ]
 00000128	     1C40	ADDS R0 R0 #1
 0000012A	     7800	LDRB R0 [ R0 + 0 ]
 0000012C	 F88D000A	STRB R0 [  SP + 10 ]
 00000130	     9801	LDR R0 [ SP + 4 ]
 00000132	     1C80	ADDS R0 R0 #2
 00000134	     7800	LDRB R0 [ R0 + 0 ]
 00000136	 F88D0009	STRB R0 [  SP + 9 ]
 0000013A	     9801	LDR R0 [ SP + 4 ]
 0000013C	     1CC0	ADDS R0 R0 #3
 0000013E	     7800	LDRB R0 [ R0 + 0 ]
 00000140	 F88D0008	STRB R0 [  SP + 8 ]
 00000144	 F89D000B	LDRB R0 [ SP + 11 ]
 00000148	 F89D1008	LDRB R1 [ SP + 8 ]
 0000014C	     0209	LSLS R1 R1 #8
 0000014E	 F89D2009	LDRB R2 [ SP + 9 ]
 00000152	     1851	ADDS R1 R2 R1
 00000154	     0209	LSLS R1 R1 #8
 00000156	 F89D200A	LDRB R2 [ SP + 10 ]
 0000015A	     1851	ADDS R1 R2 R1
 0000015C	     0209	LSLS R1 R1 #8
 0000015E	     1840	ADDS R0 R0 R1
 00000160	 F85DEB04	LDR LR [ SP ] + 4
 00000164	     B002	ADD SP SP #8
 00000166	     4770	BX LR
 00000168	     B081	SUB SP SP #4
 0000016A	     B403	PUSH R0 R1
 0000016C	     B500	PUSH LR
 0000016E	     9802	LDR R0 [ SP + 8 ]
 00000170	 F36F201F	BFC R0 #8 #24
 00000174	 F88D000F	STRB R0 [  SP + 15 ]
 00000178	     9802	LDR R0 [ SP + 8 ]
 0000017A	     1200	ASRS R0 R0 #8
 0000017C	     9002	STR R0 [ SP + 8 ]
 0000017E	     9802	LDR R0 [ SP + 8 ]
 00000180	 F36F201F	BFC R0 #8 #24
 00000184	 F88D000E	STRB R0 [  SP + 14 ]
 00000188	     9802	LDR R0 [ SP + 8 ]
 0000018A	     1200	ASRS R0 R0 #8
 0000018C	     9002	STR R0 [ SP + 8 ]
 0000018E	     9802	LDR R0 [ SP + 8 ]
 00000190	 F36F201F	BFC R0 #8 #24
 00000194	 F88D000D	STRB R0 [  SP + 13 ]
 00000198	     9802	LDR R0 [ SP + 8 ]
 0000019A	     1200	ASRS R0 R0 #8
 0000019C	     9002	STR R0 [ SP + 8 ]
 0000019E	     9802	LDR R0 [ SP + 8 ]
 000001A0	 F36F201F	BFC R0 #8 #24
 000001A4	 F88D000C	STRB R0 [  SP + 12 ]
 000001A8	     9801	LDR R0 [ SP + 4 ]
 000001AA	 F89D100F	LDRB R1 [ SP + 15 ]
 000001AE	     7001	STRB R1 [ R0 + 0 ]
 000001B0	     9801	LDR R0 [ SP + 4 ]
 000001B2	     1C40	ADDS R0 R0 #1
 000001B4	 F89D100E	LDRB R1 [ SP + 14 ]
 000001B8	     7001	STRB R1 [ R0 + 0 ]
 000001BA	     9801	LDR R0 [ SP + 4 ]
 000001BC	     1C80	ADDS R0 R0 #2
 000001BE	 F89D100D	LDRB R1 [ SP + 13 ]
 000001C2	     7001	STRB R1 [ R0 + 0 ]
 000001C4	     9801	LDR R0 [ SP + 4 ]
 000001C6	     1CC0	ADDS R0 R0 #3
 000001C8	 F89D100C	LDRB R1 [ SP + 12 ]
 000001CC	     7001	STRB R1 [ R0 + 0 ]
 000001CE	 F85DEB04	LDR LR [ SP ] + 4
 000001D2	     B003	ADD SP SP #12
 000001D4	     4770	BX LR
 000001D6	     B089	SUB SP SP #36
 000001D8	     B403	PUSH R0 R1
 000001DA	     B500	PUSH LR
 000001DC	     2000	MOVS R0 #0
 000001DE	     9003	STR R0 [ SP + 12 ]
 000001E0	     9803	LDR R0 [ SP + 12 ]
 000001E2	     9902	LDR R1 [ SP + 8 ]
 000001E4	     4288	CMP R0 R1
 000001E6	     BF28	IT CS
 000001E8	 EC01A181	TrapCS 1 at pos 3352
 000001EC	     9901	LDR R1 [ SP + 4 ]
 000001EE	     1808	ADDS R0 R1 R0
 000001F0	     7800	LDRB R0 [ R0 + 0 ]
 000001F2	     2800	CMP R0 #0
 000001F4	 F0008014	BEQ #40, goes to  00000220
 000001F8	     9803	LDR R0 [ SP + 12 ]
 000001FA	     2820	CMP R0 #32
 000001FC	     BF28	IT CS
 000001FE	 EC01A2C1	TrapCS 1 at pos 3372
 00000202	     4468	ADD R0 SP R0
 00000204	     9903	LDR R1 [ SP + 12 ]
 00000206	     9A02	LDR R2 [ SP + 8 ]
 00000208	     4291	CMP R1 R2
 0000020A	     BF28	IT CS
 0000020C	 EC01A371	TrapCS 1 at pos 3383
 00000210	     9A01	LDR R2 [ SP + 4 ]
 00000212	     1851	ADDS R1 R2 R1
 00000214	     7809	LDRB R1 [ R1 + 0 ]
 00000216	     7401	STRB R1 [ R0 + 16 ]
 00000218	     9803	LDR R0 [ SP + 12 ]
 0000021A	     1C40	ADDS R0 R0 #1
 0000021C	     9003	STR R0 [ SP + 12 ]
 0000021E	     E7DF	B #-66, goes to  000001E0
 00000220	     9803	LDR R0 [ SP + 12 ]
 00000222	     2820	CMP R0 #32
 00000224	     BF28	IT CS
 00000226	 EC01A551	TrapCS 1 at pos 3413
 0000022A	     4468	ADD R0 SP R0
 0000022C	     212E	MOVS R1 #46
 0000022E	     7401	STRB R1 [ R0 + 16 ]
 00000230	     9803	LDR R0 [ SP + 12 ]
 00000232	     1C40	ADDS R0 R0 #1
 00000234	     2820	CMP R0 #32
 00000236	     BF28	IT CS
 00000238	 EC01A6B1	TrapCS 1 at pos 3435
 0000023C	     4468	ADD R0 SP R0
 0000023E	     216D	MOVS R1 #109
 00000240	     7401	STRB R1 [ R0 + 16 ]
 00000242	     9803	LDR R0 [ SP + 12 ]
 00000244	     1C80	ADDS R0 R0 #2
 00000246	     2820	CMP R0 #32
 00000248	     BF28	IT CS
 0000024A	 EC01B011	TrapCS 1 at pos 3457
 0000024E	     4468	ADD R0 SP R0
 00000250	     2134	MOVS R1 #52
 00000252	     7401	STRB R1 [ R0 + 16 ]
 00000254	     9803	LDR R0 [ SP + 12 ]
 00000256	     1CC0	ADDS R0 R0 #3
 00000258	     2820	CMP R0 #32
 0000025A	     BF28	IT CS
 0000025C	 EC01B171	TrapCS 1 at pos 3479
 00000260	     4468	ADD R0 SP R0
 00000262	     2163	MOVS R1 #99
 00000264	     7401	STRB R1 [ R0 + 16 ]
 00000266	     9803	LDR R0 [ SP + 12 ]
 00000268	     1D00	ADDS R0 R0 #4
 0000026A	     2820	CMP R0 #32
 0000026C	     BF28	IT CS
 0000026E	 EC01B2D1	TrapCS 1 at pos 3501
 00000272	     4468	ADD R0 SP R0
 00000274	     2100	MOVS R1 #0
 00000276	     7401	STRB R1 [ R0 + 16 ]
 00000278	     A804	ADD R0 SP #16
 0000027A	     2120	MOVS R1 #32
 0000027C	 2020013E	BL Mod(  2) proc(2)
 00000280	 F85DEB04	LDR LR [ SP ] + 4
 00000284	     B00B	ADD SP SP #44
 00000286	     4770	BX LR
 00000288	     B407	PUSH R0 R1 R2
 0000028A	     B500	PUSH LR
 0000028C	     9801	LDR R0 [ SP + 4 ]
 0000028E	 10000147	MOV R1 lower 16-bits base(0), next at  00000000
 00000292	 0000000C	MOVT R1 higher 16-bits var + 12
 00000296	     6008	STR R0 [  R1 + 0 ]
 00000298	 00000005	MOV R0 lower 16-bits base(0), next at  0000028E
 0000029C	 00000010	MOVT R0 higher 16-bits var + 16
 000002A0	     9902	LDR R1 [ SP + 8 ]
 000002A2	     9A03	LDR R2 [ SP + 12 ]
 000002A4	     2A00	CMP R2 #0
 000002A6	     D00B	BEQ #22, goes to  000002C0
 000002A8	     1CD2	ADDS R2 R2 #3
 000002AA	     1092	ASRS R2 R2 #2
 000002AC	     2A08	CMP R2 #8
 000002AE	     BFC8	IT GT
 000002B0	 EC01C423	TrapGT 3 at pos 3650
 000002B4	 F8513B04	LDR R3 [ R1 ] + 4
 000002B8	 F8403B04	STR R3 [  R0 ] + 4
 000002BC	     1E52	SUBS R2 R2 #1
 000002BE	     D1F9	BNE #-14, goes to  000002B4
 000002C0	 F85DEB04	LDR LR [ SP ] + 4
 000002C4	     B003	ADD SP SP #12
 000002C6	     4770	BX LR
 000002C8	     B082	SUB SP SP #8
 000002CA	     B403	PUSH R0 R1
 000002CC	     B500	PUSH LR
 000002CE	     2000	MOVS R0 #0
 000002D0	     9902	LDR R1 [ SP + 8 ]
 000002D2	     4288	CMP R0 R1
 000002D4	     BF28	IT CS
 000002D6	 EC01D201	TrapCS 1 at pos 3744
 000002DA	     9901	LDR R1 [ SP + 4 ]
 000002DC	     1808	ADDS R0 R1 R0
 000002DE	     7800	LDRB R0 [ R0 + 0 ]
 000002E0	 F88D0010	STRB R0 [  SP + 16 ]
 000002E4	     2001	MOVS R0 #1
 000002E6	 10000027	MOV R1 lower 16-bits base(0), next at  00000298
 000002EA	 0000000C	MOVT R1 higher 16-bits var + 12
 000002EE	     6008	STR R0 [  R1 + 0 ]
 000002F0	     2001	MOVS R0 #1
 000002F2	     9003	STR R0 [ SP + 12 ]
 000002F4	 F89D0010	LDRB R0 [ SP + 16 ]
 000002F8	     2841	CMP R0 #65
 000002FA	 F2C08005	BLT #10, goes to  00000308
 000002FE	 F89D0010	LDRB R0 [ SP + 16 ]
 00000302	     285A	CMP R0 #90
 00000304	 F340800A	BLE #20, goes to  0000031C
 00000308	 F89D0010	LDRB R0 [ SP + 16 ]
 0000030C	     2861	CMP R0 #97
 0000030E	 F2C08048	BLT #144, goes to  000003A2
 00000312	 F89D0010	LDRB R0 [ SP + 16 ]
 00000316	     287A	CMP R0 #122
 00000318	 F3008043	BGT #134, goes to  000003A2
 0000031C	     9803	LDR R0 [ SP + 12 ]
 0000031E	     9902	LDR R1 [ SP + 8 ]
 00000320	     4288	CMP R0 R1
 00000322	     BF28	IT CS
 00000324	 EC01E0E1	TrapCS 1 at pos 3854
 00000328	     9901	LDR R1 [ SP + 4 ]
 0000032A	     1808	ADDS R0 R1 R0
 0000032C	     7800	LDRB R0 [ R0 + 0 ]
 0000032E	 F88D0010	STRB R0 [  SP + 16 ]
 00000332	     9803	LDR R0 [ SP + 12 ]
 00000334	     1C40	ADDS R0 R0 #1
 00000336	     9003	STR R0 [ SP + 12 ]
 00000338	 F89D0010	LDRB R0 [ SP + 16 ]
 0000033C	     2830	CMP R0 #48
 0000033E	 F2C08005	BLT #10, goes to  0000034C
 00000342	 F89D0010	LDRB R0 [ SP + 16 ]
 00000346	     2839	CMP R0 #57
 00000348	 F3408019	BLE #50, goes to  0000037E
 0000034C	 F89D0010	LDRB R0 [ SP + 16 ]
 00000350	     2841	CMP R0 #65
 00000352	 F2C08005	BLT #10, goes to  00000360
 00000356	 F89D0010	LDRB R0 [ SP + 16 ]
 0000035A	     285A	CMP R0 #90
 0000035C	 F340800F	BLE #30, goes to  0000037E
 00000360	 F89D0010	LDRB R0 [ SP + 16 ]
 00000364	     2861	CMP R0 #97
 00000366	 F2C08005	BLT #10, goes to  00000374
 0000036A	 F89D0010	LDRB R0 [ SP + 16 ]
 0000036E	     287A	CMP R0 #122
 00000370	 F3408005	BLE #10, goes to  0000037E
 00000374	 F89D0010	LDRB R0 [ SP + 16 ]
 00000378	     282E	CMP R0 #46
 0000037A	 F0408003	BNE #6, goes to  00000384
 0000037E	     9803	LDR R0 [ SP + 12 ]
 00000380	     2820	CMP R0 #32
 00000382	     D1CB	BNE #-106, goes to  0000031C
 00000384	     9803	LDR R0 [ SP + 12 ]
 00000386	     2820	CMP R0 #32
 00000388	 F280800B	BGE #22, goes to  000003A2
 0000038C	 F89D0010	LDRB R0 [ SP + 16 ]
 00000390	     2800	CMP R0 #0
 00000392	 F0408006	BNE #12, goes to  000003A2
 00000396	     2000	MOVS R0 #0
 00000398	 10000059	MOV R1 lower 16-bits base(0), next at  000002E6
 0000039C	 0000000C	MOVT R1 higher 16-bits var + 12
 000003A0	     6008	STR R0 [  R1 + 0 ]
 000003A2	 F85DEB04	LDR LR [ SP ] + 4
 000003A6	     B004	ADD SP SP #16
 000003A8	     4770	BX LR
 000003AA	     B403	PUSH R0 R1
 000003AC	     B500	PUSH LR
 000003AE	     9801	LDR R0 [ SP + 4 ]
 000003B0	     6800	LDR R0 [ R0 + 0 ]
 000003B2	     2800	CMP R0 #0
 000003B4	     BF08	IT EQ
 000003B6	 EC0202E4	TrapEQ 4 at pos 4142
 000003BA	     6B01	LDR R1 [ R0 + 48 ]
 000003BC	     9A02	LDR R2 [ SP + 8 ]
 000003BE	     1889	ADDS R1 R1 R2
 000003C0	     6301	STR R1 [  R0 + 48 ]
 000003C2	 F85DEB04	LDR LR [ SP ] + 4
 000003C6	     B002	ADD SP SP #8
 000003C8	     4770	BX LR
 000003CA	     B0C2	SUB SP SP #264
 000003CC	     B407	PUSH R0 R1 R2
 000003CE	     B500	PUSH LR
 000003D0	 0000001C	MOV R0 lower 16-bits base(0), next at  00000398
 000003D4	 00000000	MOVT R0 higher 16-bits var + 0
 000003D8	     6800	LDR R0 [ R0 + 0 ]
 000003DA	     9004	STR R0 [ SP + 16 ]
 000003DC	     2000	MOVS R0 #0
 000003DE	     9901	LDR R1 [ SP + 4 ]
 000003E0	     9A02	LDR R2 [ SP + 8 ]
 000003E2	 F7FFFF51	BL #-350, goes to  00000288
 000003E6	     2000	MOVS R0 #0
 000003E8	     900B	STR R0 [ SP + 44 ]
 000003EA	     2000	MOVS R0 #0
 000003EC	 F88D0046	STRB R0 [  SP + 70 ]
 000003F0	     9804	LDR R0 [ SP + 16 ]
 000003F2	     2800	CMP R0 #0
 000003F4	 F0008018	BEQ #48, goes to  00000428
 000003F8	     9804	LDR R0 [ SP + 16 ]
 000003FA	     2800	CMP R0 #0
 000003FC	     BF08	IT EQ
 000003FE	 EC027034	TrapEQ 4 at pos 4995
 00000402	     9901	LDR R1 [ SP + 4 ]
 00000404	 F8112B01	LDRB R2 [  R1 ] + 1
 00000408	 F8103B01	LDRB R3 [  R0 ] + 1
 0000040C	     429A	CMP R2 R3
 0000040E	     D101	BNE #2, goes to  00000414
 00000410	     2A00	CMP R2 #0
 00000412	     D1F7	BNE #-18, goes to  00000404
 00000414	 F0008008	BEQ #16, goes to  00000428
 00000418	     9804	LDR R0 [ SP + 16 ]
 0000041A	     2800	CMP R0 #0
 0000041C	     BF08	IT EQ
 0000041E	 EC027174	TrapEQ 4 at pos 5015
 00000422	     6A00	LDR R0 [ R0 + 32 ]
 00000424	     9004	STR R0 [ SP + 16 ]
 00000426	     E7E3	B #-58, goes to  000003F0
 00000428	     9804	LDR R0 [ SP + 16 ]
 0000042A	     2800	CMP R0 #0
 0000042C	 F0408533	BNE #2662, goes to  00000E96
 00000430	     9801	LDR R0 [ SP + 4 ]
 00000432	     9902	LDR R1 [ SP + 8 ]
 00000434	 F7FFFF48	BL #-368, goes to  000002C8
 00000438	 00000034	MOV R0 lower 16-bits base(0), next at  000003D0
 0000043C	 0000000C	MOVT R0 higher 16-bits var + 12
 00000440	     6800	LDR R0 [ R0 + 0 ]
 00000442	     2800	CMP R0 #0
 00000444	 F0408007	BNE #14, goes to  00000456
 00000448	     9801	LDR R0 [ SP + 4 ]
 0000044A	     9902	LDR R1 [ SP + 8 ]
 0000044C	 F7FFFEC3	BL #-634, goes to  000001D6
 00000450	     902F	STR R0 [ SP + 188 ]
 00000452	 F000B802	B #4, goes to  0000045A
 00000456	     2000	MOVS R0 #0
 00000458	     902F	STR R0 [ SP + 188 ]
 0000045A	     982F	LDR R0 [ SP + 188 ]
 0000045C	     2800	CMP R0 #0
 0000045E	 F00080B8	BEQ #368, goes to  000005D2
 00000462	     A830	ADD R0 SP #192
 00000464	 12000232	MOV R1 lower 16-bits base(2), next at  00000000
 00000468	 00000001	MOVT R1 higher 16-bits const(1)
 0000046C	     9A2F	LDR R2 [ SP + 188 ]
 0000046E	     2300	MOVS R3 #0
 00000470	 20B000FA	BL Mod(  2) proc(11)
 00000474	     A830	ADD R0 SP #192
 00000476	 12000009	MOV R1 lower 16-bits base(2), next at  00000464
 0000047A	 00000001	MOVT R1 higher 16-bits const(1)
 0000047E	     AA1F	ADD R2 SP #124
 00000480	     2320	MOVS R3 #32
 00000482	 21400009	BL Mod(  2) proc(20)
 00000486	     A830	ADD R0 SP #192
 00000488	 12000009	MOV R1 lower 16-bits base(2), next at  00000476
 0000048C	 00000001	MOVT R1 higher 16-bits const(1)
 00000490	     AA08	ADD R2 SP #32
 00000492	 21100008	BL Mod(  2) proc(17)
 00000496	     A830	ADD R0 SP #192
 00000498	 12000008	MOV R1 lower 16-bits base(2), next at  00000488
 0000049C	 00000001	MOVT R1 higher 16-bits const(1)
 000004A0	 F10D0245	ADD R2 SP #69
 000004A4	 21000009	BL Mod(  2) proc(16)
 000004A8	     A830	ADD R0 SP #192
 000004AA	 12000009	MOV R1 lower 16-bits base(2), next at  00000498
 000004AE	 00000001	MOVT R1 higher 16-bits const(1)
 000004B2	     AA0C	ADD R2 SP #48
 000004B4	 21100008	BL Mod(  2) proc(17)
 000004B8	 00000040	MOV R0 lower 16-bits base(0), next at  00000438
 000004BC	 00000010	MOVT R0 higher 16-bits var + 16
 000004C0	     A91F	ADD R1 SP #124
 000004C2	     2208	MOVS R2 #8
 000004C4	 F8513B04	LDR R3 [ R1 ] + 4
 000004C8	 F8403B04	STR R3 [  R0 ] + 4
 000004CC	     1E52	SUBS R2 R2 #1
 000004CE	     D1F9	BNE #-14, goes to  000004C4
 000004D0	 F89D0045	LDRB R0 [ SP + 69 ]
 000004D4	     2801	CMP R0 #1
 000004D6	 F0408075	BNE #234, goes to  000005C4
 000004DA	     A830	ADD R0 SP #192
 000004DC	 12000019	MOV R1 lower 16-bits base(2), next at  000004AA
 000004E0	 00000001	MOVT R1 higher 16-bits const(1)
 000004E4	     AA27	ADD R2 SP #156
 000004E6	     2320	MOVS R3 #32
 000004E8	 2140001A	BL Mod(  2) proc(20)
 000004EC	 F89D009C	LDRB R0 [ SP + 156 ]
 000004F0	     2800	CMP R0 #0
 000004F2	 F0008065	BEQ #202, goes to  000005C0
 000004F6	 0000001F	MOV R0 lower 16-bits base(0), next at  000004B8
 000004FA	 0000000C	MOVT R0 higher 16-bits var + 12
 000004FE	     6800	LDR R0 [ R0 + 0 ]
 00000500	     2800	CMP R0 #0
 00000502	 F040805D	BNE #186, goes to  000005C0
 00000506	     A830	ADD R0 SP #192
 00000508	 12000016	MOV R1 lower 16-bits base(2), next at  000004DC
 0000050C	 00000001	MOVT R1 higher 16-bits const(1)
 00000510	     AA09	ADD R2 SP #36
 00000512	 21100015	BL Mod(  2) proc(17)
 00000516	     A827	ADD R0 SP #156
 00000518	     2120	MOVS R1 #32
 0000051A	     AA05	ADD R2 SP #20
 0000051C	 F7FFFF55	BL #-342, goes to  000003CA
 00000520	     980B	LDR R0 [ SP + 44 ]
 00000522	     2810	CMP R0 #16
 00000524	     BF28	IT CS
 00000526	 EC02B191	TrapCS 1 at pos 5529
 0000052A	 EB0D0080	ADD R0 SP R0 LSL #2
 0000052E	     9905	LDR R1 [ SP + 20 ]
 00000530	 F8C010D8	STR R1 [  R0 + 216 ]
 00000534	 0000001F	MOV R0 lower 16-bits base(0), next at  000004F6
 00000538	 00000010	MOVT R0 higher 16-bits var + 16
 0000053C	     A91F	ADD R1 SP #124
 0000053E	     2208	MOVS R2 #8
 00000540	 F8513B04	LDR R3 [ R1 ] + 4
 00000544	 F8403B04	STR R3 [  R0 ] + 4
 00000548	     1E52	SUBS R2 R2 #1
 0000054A	     D1F9	BNE #-14, goes to  00000540
 0000054C	 0000000C	MOV R0 lower 16-bits base(0), next at  00000534
 00000550	 0000000C	MOVT R0 higher 16-bits var + 12
 00000554	     6800	LDR R0 [ R0 + 0 ]
 00000556	     2800	CMP R0 #0
 00000558	 F0408028	BNE #80, goes to  000005AC
 0000055C	     9805	LDR R0 [ SP + 20 ]
 0000055E	     2800	CMP R0 #0
 00000560	     BF08	IT EQ
 00000562	 EC02B704	TrapEQ 4 at pos 5616
 00000566	     6A40	LDR R0 [ R0 + 36 ]
 00000568	     9909	LDR R1 [ SP + 36 ]
 0000056A	     4288	CMP R0 R1
 0000056C	 F040800D	BNE #26, goes to  0000058A
 00000570	     9805	LDR R0 [ SP + 20 ]
 00000572	     2800	CMP R0 #0
 00000574	     BF08	IT EQ
 00000576	 EC02C104	TrapEQ 4 at pos 5648
 0000057A	     6B01	LDR R1 [ R0 + 48 ]
 0000057C	     1C49	ADDS R1 R1 #1
 0000057E	     6301	STR R1 [  R0 + 48 ]
 00000580	     980B	LDR R0 [ SP + 44 ]
 00000582	     1C40	ADDS R0 R0 #1
 00000584	     900B	STR R0 [ SP + 44 ]
 00000586	 F000B811	B #34, goes to  000005AC
 0000058A	     2003	MOVS R0 #3
 0000058C	     A91F	ADD R1 SP #124
 0000058E	     2220	MOVS R2 #32
 00000590	 F7FFFE7A	BL #-780, goes to  00000288
 00000594	 00000024	MOV R0 lower 16-bits base(0), next at  0000054C
 00000598	 00000030	MOVT R0 higher 16-bits var + 48
 0000059C	     A927	ADD R1 SP #156
 0000059E	     2208	MOVS R2 #8
 000005A0	 F8513B04	LDR R3 [ R1 ] + 4
 000005A4	 F8403B04	STR R3 [  R0 ] + 4
 000005A8	     1E52	SUBS R2 R2 #1
 000005AA	     D1F9	BNE #-14, goes to  000005A0
 000005AC	     A830	ADD R0 SP #192
 000005AE	 12000053	MOV R1 lower 16-bits base(2), next at  00000508
 000005B2	 00000001	MOVT R1 higher 16-bits const(1)
 000005B6	     AA27	ADD R2 SP #156
 000005B8	     2320	MOVS R3 #32
 000005BA	 21400054	BL Mod(  2) proc(20)
 000005BE	     E795	B #-214, goes to  000004EC
 000005C0	 F000B805	B #10, goes to  000005CE
 000005C4	     2002	MOVS R0 #2
 000005C6	     A91F	ADD R1 SP #124
 000005C8	     2220	MOVS R2 #32
 000005CA	 F7FFFE5D	BL #-838, goes to  00000288
 000005CE	 F000B805	B #10, goes to  000005DC
 000005D2	     2001	MOVS R0 #1
 000005D4	     9901	LDR R1 [ SP + 4 ]
 000005D6	     9A02	LDR R2 [ SP + 8 ]
 000005D8	 F7FFFE56	BL #-852, goes to  00000288
 000005DC	 00000024	MOV R0 lower 16-bits base(0), next at  00000594
 000005E0	 0000000C	MOVT R0 higher 16-bits var + 12
 000005E4	     6800	LDR R0 [ R0 + 0 ]
 000005E6	     2800	CMP R0 #0
 000005E8	 F040808B	BNE #278, goes to  00000702
 000005EC	     980C	LDR R0 [ SP + 48 ]
 000005EE	     3050	ADDS R0 R0 #80
 000005F0	     900C	STR R0 [ SP + 48 ]
 000005F2	 0000000B	MOV R0 lower 16-bits base(0), next at  000005DC
 000005F6	 00000000	MOVT R0 higher 16-bits var + 0
 000005FA	     6800	LDR R0 [ R0 + 0 ]
 000005FC	     9004	STR R0 [ SP + 16 ]
 000005FE	     9804	LDR R0 [ SP + 16 ]
 00000600	     2800	CMP R0 #0
 00000602	 F000801B	BEQ #54, goes to  0000063C
 00000606	     9804	LDR R0 [ SP + 16 ]
 00000608	     2800	CMP R0 #0
 0000060A	     BF08	IT EQ
 0000060C	 EC02F1D4	TrapEQ 4 at pos 6045
 00000610	     7800	LDRB R0 [ R0 + 0 ]
 00000612	     2800	CMP R0 #0
 00000614	 F040800A	BNE #20, goes to  0000062C
 00000618	     9804	LDR R0 [ SP + 16 ]
 0000061A	     2800	CMP R0 #0
 0000061C	     BF08	IT EQ
 0000061E	 EC02F324	TrapEQ 4 at pos 6066
 00000622	     6AC0	LDR R0 [ R0 + 44 ]
 00000624	     990C	LDR R1 [ SP + 48 ]
 00000626	     4288	CMP R0 R1
 00000628	 F2808008	BGE #16, goes to  0000063C
 0000062C	     9804	LDR R0 [ SP + 16 ]
 0000062E	     2800	CMP R0 #0
 00000630	     BF08	IT EQ
 00000632	 EC02F4F4	TrapEQ 4 at pos 6095
 00000636	     6A00	LDR R0 [ R0 + 32 ]
 00000638	     9004	STR R0 [ SP + 16 ]
 0000063A	     E7E0	B #-64, goes to  000005FE
 0000063C	     9804	LDR R0 [ SP + 16 ]
 0000063E	     2800	CMP R0 #0
 00000640	 F040805D	BNE #186, goes to  000006FE
 00000644	 00000029	MOV R0 lower 16-bits base(0), next at  000005F2
 00000648	 00000008	MOVT R0 higher 16-bits var + 8
 0000064C	     6800	LDR R0 [ R0 + 0 ]
 0000064E	     990C	LDR R1 [ SP + 48 ]
 00000650	     1840	ADDS R0 R0 R1
 00000652	 10000007	MOV R1 lower 16-bits base(0), next at  00000644
 00000656	 00000050	MOVT R1 higher 16-bits var + 80
 0000065A	     6809	LDR R1 [ R1 + 0 ]
 0000065C	     4288	CMP R0 R1
 0000065E	 F2808047	BGE #142, goes to  000006F0
 00000662	     2001	MOVS R0 #1
 00000664	 F88D0046	STRB R0 [  SP + 70 ]
 00000668	 0000000B	MOV R0 lower 16-bits base(0), next at  00000652
 0000066C	 00000008	MOVT R0 higher 16-bits var + 8
 00000670	     6800	LDR R0 [ R0 + 0 ]
 00000672	     900D	STR R0 [ SP + 52 ]
 00000674	     980D	LDR R0 [ SP + 52 ]
 00000676	     9004	STR R0 [ SP + 16 ]
 00000678	     980D	LDR R0 [ SP + 52 ]
 0000067A	     990C	LDR R1 [ SP + 48 ]
 0000067C	     1840	ADDS R0 R0 R1
 0000067E	     1CC0	ADDS R0 R0 #3
 00000680	     1080	ASRS R0 R0 #2
 00000682	     0080	LSLS R0 R0 #2
 00000684	 1000000E	MOV R1 lower 16-bits base(0), next at  00000668
 00000688	 00000008	MOVT R1 higher 16-bits var + 8
 0000068C	     6008	STR R0 [  R1 + 0 ]
 0000068E	     9804	LDR R0 [ SP + 16 ]
 00000690	     2800	CMP R0 #0
 00000692	     BF08	IT EQ
 00000694	 EC0315D4	TrapEQ 4 at pos 6365
 00000698	 1000000A	MOV R1 lower 16-bits base(0), next at  00000684
 0000069C	 00000008	MOVT R1 higher 16-bits var + 8
 000006A0	     6809	LDR R1 [ R1 + 0 ]
 000006A2	     9A0D	LDR R2 [ SP + 52 ]
 000006A4	     1A89	SUBS R1 R1 R2
 000006A6	     62C1	STR R1 [  R0 + 44 ]
 000006A8	     9804	LDR R0 [ SP + 16 ]
 000006AA	     2800	CMP R0 #0
 000006AC	     BF08	IT EQ
 000006AE	 EC031764	TrapEQ 4 at pos 6390
 000006B2	 1000000D	MOV R1 lower 16-bits base(0), next at  00000698
 000006B6	 00000000	MOVT R1 higher 16-bits var + 0
 000006BA	     6809	LDR R1 [ R1 + 0 ]
 000006BC	     2900	CMP R1 #0
 000006BE	     BF08	IT EQ
 000006C0	 EC032024	TrapEQ 4 at pos 6402
 000006C4	     6A89	LDR R1 [ R1 + 40 ]
 000006C6	     1C49	ADDS R1 R1 #1
 000006C8	     6281	STR R1 [  R0 + 40 ]
 000006CA	     9804	LDR R0 [ SP + 16 ]
 000006CC	     2800	CMP R0 #0
 000006CE	     BF08	IT EQ
 000006D0	 EC0321C4	TrapEQ 4 at pos 6428
 000006D4	 10000011	MOV R1 lower 16-bits base(0), next at  000006B2
 000006D8	 00000000	MOVT R1 higher 16-bits var + 0
 000006DC	     6809	LDR R1 [ R1 + 0 ]
 000006DE	     6201	STR R1 [  R0 + 32 ]
 000006E0	     9804	LDR R0 [ SP + 16 ]
 000006E2	 10000007	MOV R1 lower 16-bits base(0), next at  000006D4
 000006E6	 00000000	MOVT R1 higher 16-bits var + 0
 000006EA	     6008	STR R0 [  R1 + 0 ]
 000006EC	 F000B805	B #10, goes to  000006FA
 000006F0	     2007	MOVS R0 #7
 000006F2	     A91F	ADD R1 SP #124
 000006F4	     2220	MOVS R2 #32
 000006F6	 F7FFFDC7	BL #-1138, goes to  00000288
 000006FA	 F000B802	B #4, goes to  00000702
 000006FE	     9804	LDR R0 [ SP + 16 ]
 00000700	     900D	STR R0 [ SP + 52 ]
 00000702	 00000010	MOV R0 lower 16-bits base(0), next at  000006E2
 00000706	 0000000C	MOVT R0 higher 16-bits var + 12
 0000070A	     6800	LDR R0 [ R0 + 0 ]
 0000070C	     2800	CMP R0 #0
 0000070E	 F04081B0	BNE #864, goes to  00000A72
 00000712	     980D	LDR R0 [ SP + 52 ]
 00000714	     3050	ADDS R0 R0 #80
 00000716	     900D	STR R0 [ SP + 52 ]
 00000718	     9804	LDR R0 [ SP + 16 ]
 0000071A	     2800	CMP R0 #0
 0000071C	     BF08	IT EQ
 0000071E	 EC034174	TrapEQ 4 at pos 6679
 00000722	     9901	LDR R1 [ SP + 4 ]
 00000724	     9A02	LDR R2 [ SP + 8 ]
 00000726	     2A00	CMP R2 #0
 00000728	     D00B	BEQ #22, goes to  00000742
 0000072A	     1CD2	ADDS R2 R2 #3
 0000072C	     1092	ASRS R2 R2 #2
 0000072E	     2A08	CMP R2 #8
 00000730	     BFC8	IT GT
 00000732	 EC034203	TrapGT 3 at pos 6688
 00000736	 F8513B04	LDR R3 [ R1 ] + 4
 0000073A	 F8403B04	STR R3 [  R0 ] + 4
 0000073E	     1E52	SUBS R2 R2 #1
 00000740	     D1F9	BNE #-14, goes to  00000736
 00000742	     9804	LDR R0 [ SP + 16 ]
 00000744	     2800	CMP R0 #0
 00000746	     BF08	IT EQ
 00000748	 EC034284	TrapEQ 4 at pos 6696
 0000074C	     9908	LDR R1 [ SP + 32 ]
 0000074E	     6241	STR R1 [  R0 + 36 ]
 00000750	     9804	LDR R0 [ SP + 16 ]
 00000752	     2800	CMP R0 #0
 00000754	     BF08	IT EQ
 00000756	 EC0343B4	TrapEQ 4 at pos 6715
 0000075A	     2100	MOVS R1 #0
 0000075C	     6301	STR R1 [  R0 + 48 ]
 0000075E	     9804	LDR R0 [ SP + 16 ]
 00000760	     2800	CMP R0 #0
 00000762	     BF08	IT EQ
 00000764	 EC034524	TrapEQ 4 at pos 6738
 00000768	     990D	LDR R1 [ SP + 52 ]
 0000076A	     6341	STR R1 [  R0 + 52 ]
 0000076C	     A830	ADD R0 SP #192
 0000076E	 120000E0	MOV R1 lower 16-bits base(2), next at  000005AE
 00000772	 00000001	MOVT R1 higher 16-bits const(1)
 00000776	     AA07	ADD R2 SP #28
 00000778	 211000DF	BL Mod(  2) proc(17)
 0000077C	     9807	LDR R0 [ SP + 28 ]
 0000077E	     2800	CMP R0 #0
 00000780	 F3408012	BLE #36, goes to  000007A8
 00000784	     A830	ADD R0 SP #192
 00000786	 1200000C	MOV R1 lower 16-bits base(2), next at  0000076E
 0000078A	 00000001	MOVT R1 higher 16-bits const(1)
 0000078E	     AA10	ADD R2 SP #64
 00000790	 2110000C	BL Mod(  2) proc(17)
 00000794	     980D	LDR R0 [ SP + 52 ]
 00000796	     9910	LDR R1 [ SP + 64 ]
 00000798	     6001	STR R1 [  R0 + 0 ]
 0000079A	     980D	LDR R0 [ SP + 52 ]
 0000079C	     1D00	ADDS R0 R0 #4
 0000079E	     900D	STR R0 [ SP + 52 ]
 000007A0	     9807	LDR R0 [ SP + 28 ]
 000007A2	     1F00	SUBS R0 R0 #4
 000007A4	     9007	STR R0 [ SP + 28 ]
 000007A6	     E7E9	B #-46, goes to  0000077C
 000007A8	     A830	ADD R0 SP #192
 000007AA	 12000012	MOV R1 lower 16-bits base(2), next at  00000786
 000007AE	 00000001	MOVT R1 higher 16-bits const(1)
 000007B2	     AA07	ADD R2 SP #28
 000007B4	 21100012	BL Mod(  2) proc(17)
 000007B8	     9807	LDR R0 [ SP + 28 ]
 000007BA	     2800	CMP R0 #0
 000007BC	 F340800A	BLE #20, goes to  000007D4
 000007C0	     980D	LDR R0 [ SP + 52 ]
 000007C2	     2100	MOVS R1 #0
 000007C4	     6001	STR R1 [  R0 + 0 ]
 000007C6	     980D	LDR R0 [ SP + 52 ]
 000007C8	     1D00	ADDS R0 R0 #4
 000007CA	     900D	STR R0 [ SP + 52 ]
 000007CC	     9807	LDR R0 [ SP + 28 ]
 000007CE	     1F00	SUBS R0 R0 #4
 000007D0	     9007	STR R0 [ SP + 28 ]
 000007D2	     E7F1	B #-30, goes to  000007B8
 000007D4	     A830	ADD R0 SP #192
 000007D6	 12000016	MOV R1 lower 16-bits base(2), next at  000007AA
 000007DA	 00000001	MOVT R1 higher 16-bits const(1)
 000007DE	     AA07	ADD R2 SP #28
 000007E0	 21100016	BL Mod(  2) proc(17)
 000007E4	     9807	LDR R0 [ SP + 28 ]
 000007E6	     2800	CMP R0 #0
 000007E8	 F3408014	BLE #40, goes to  00000814
 000007EC	     A830	ADD R0 SP #192
 000007EE	 1200000C	MOV R1 lower 16-bits base(2), next at  000007D6
 000007F2	 00000001	MOVT R1 higher 16-bits const(1)
 000007F6	 F10D0245	ADD R2 SP #69
 000007FA	 2100000D	BL Mod(  2) proc(16)
 000007FE	     980D	LDR R0 [ SP + 52 ]
 00000800	 F89D1045	LDRB R1 [ SP + 69 ]
 00000804	     7001	STRB R1 [ R0 + 0 ]
 00000806	     980D	LDR R0 [ SP + 52 ]
 00000808	     1C40	ADDS R0 R0 #1
 0000080A	     900D	STR R0 [ SP + 52 ]
 0000080C	     9807	LDR R0 [ SP + 28 ]
 0000080E	     1E40	SUBS R0 R0 #1
 00000810	     9007	STR R0 [ SP + 28 ]
 00000812	     E7E7	B #-50, goes to  000007E4
 00000814	     9804	LDR R0 [ SP + 16 ]
 00000816	     2800	CMP R0 #0
 00000818	     BF08	IT EQ
 0000081A	 EC037714	TrapEQ 4 at pos 7153
 0000081E	     990D	LDR R1 [ SP + 52 ]
 00000820	     6381	STR R1 [  R0 + 56 ]
 00000822	     A830	ADD R0 SP #192
 00000824	 1200001B	MOV R1 lower 16-bits base(2), next at  000007EE
 00000828	 00000001	MOVT R1 higher 16-bits const(1)
 0000082C	     AA07	ADD R2 SP #28
 0000082E	 2110001A	BL Mod(  2) proc(17)
 00000832	     9807	LDR R0 [ SP + 28 ]
 00000834	     2800	CMP R0 #0
 00000836	 F3408012	BLE #36, goes to  0000085E
 0000083A	     A830	ADD R0 SP #192
 0000083C	 1200000C	MOV R1 lower 16-bits base(2), next at  00000824
 00000840	 00000001	MOVT R1 higher 16-bits const(1)
 00000844	     AA10	ADD R2 SP #64
 00000846	 2110000C	BL Mod(  2) proc(17)
 0000084A	     980D	LDR R0 [ SP + 52 ]
 0000084C	     9910	LDR R1 [ SP + 64 ]
 0000084E	     6001	STR R1 [  R0 + 0 ]
 00000850	     980D	LDR R0 [ SP + 52 ]
 00000852	     1D00	ADDS R0 R0 #4
 00000854	     900D	STR R0 [ SP + 52 ]
 00000856	     9807	LDR R0 [ SP + 28 ]
 00000858	     1F00	SUBS R0 R0 #4
 0000085A	     9007	STR R0 [ SP + 28 ]
 0000085C	     E7E9	B #-46, goes to  00000832
 0000085E	     9804	LDR R0 [ SP + 16 ]
 00000860	     2800	CMP R0 #0
 00000862	     BF08	IT EQ
 00000864	 EC0395E4	TrapEQ 4 at pos 7390
 00000868	     990D	LDR R1 [ SP + 52 ]
 0000086A	     63C1	STR R1 [  R0 + 60 ]
 0000086C	     2000	MOVS R0 #0
 0000086E	     9006	STR R0 [ SP + 24 ]
 00000870	     9806	LDR R0 [ SP + 24 ]
 00000872	     990B	LDR R1 [ SP + 44 ]
 00000874	     4288	CMP R0 R1
 00000876	 F2808012	BGE #36, goes to  0000089E
 0000087A	     9806	LDR R0 [ SP + 24 ]
 0000087C	     2810	CMP R0 #16
 0000087E	     BF28	IT CS
 00000880	 EC03A451	TrapCS 1 at pos 7493
 00000884	 EB0D0080	ADD R0 SP R0 LSL #2
 00000888	     990D	LDR R1 [ SP + 52 ]
 0000088A	 F8D000D8	LDR R0 [ R0 + 216 ]
 0000088E	     6008	STR R0 [  R1 + 0 ]
 00000890	     980D	LDR R0 [ SP + 52 ]
 00000892	     1D00	ADDS R0 R0 #4
 00000894	     900D	STR R0 [ SP + 52 ]
 00000896	     9806	LDR R0 [ SP + 24 ]
 00000898	     1C40	ADDS R0 R0 #1
 0000089A	     9006	STR R0 [ SP + 24 ]
 0000089C	     E7E8	B #-48, goes to  00000870
 0000089E	     9804	LDR R0 [ SP + 16 ]
 000008A0	     2800	CMP R0 #0
 000008A2	     BF08	IT EQ
 000008A4	 EC03A774	TrapEQ 4 at pos 7543
 000008A8	     990D	LDR R1 [ SP + 52 ]
 000008AA	     6401	STR R1 [  R0 + 64 ]
 000008AC	     A830	ADD R0 SP #192
 000008AE	 12000039	MOV R1 lower 16-bits base(2), next at  0000083C
 000008B2	 00000001	MOVT R1 higher 16-bits const(1)
 000008B6	 F10D0245	ADD R2 SP #69
 000008BA	 2100003A	BL Mod(  2) proc(16)
 000008BE	 F89D0045	LDRB R0 [ SP + 69 ]
 000008C2	     2800	CMP R0 #0
 000008C4	 F0008037	BEQ #110, goes to  00000936
 000008C8	     980D	LDR R0 [ SP + 52 ]
 000008CA	 F89D1045	LDRB R1 [ SP + 69 ]
 000008CE	     7001	STRB R1 [ R0 + 0 ]
 000008D0	     980D	LDR R0 [ SP + 52 ]
 000008D2	     1C40	ADDS R0 R0 #1
 000008D4	     900D	STR R0 [ SP + 52 ]
 000008D6	     A830	ADD R0 SP #192
 000008D8	 12000015	MOV R1 lower 16-bits base(2), next at  000008AE
 000008DC	 00000001	MOVT R1 higher 16-bits const(1)
 000008E0	 F10D0245	ADD R2 SP #69
 000008E4	 21000015	BL Mod(  2) proc(16)
 000008E8	 F89D0045	LDRB R0 [ SP + 69 ]
 000008EC	     2800	CMP R0 #0
 000008EE	     D1EB	BNE #-42, goes to  000008C8
 000008F0	     980D	LDR R0 [ SP + 52 ]
 000008F2	     2100	MOVS R1 #0
 000008F4	     7001	STRB R1 [ R0 + 0 ]
 000008F6	     980D	LDR R0 [ SP + 52 ]
 000008F8	     1C40	ADDS R0 R0 #1
 000008FA	     900D	STR R0 [ SP + 52 ]
 000008FC	     980D	LDR R0 [ SP + 52 ]
 000008FE	 F36F009F	BFC R0 #2 #30
 00000902	     2800	CMP R0 #0
 00000904	     D1F4	BNE #-24, goes to  000008F0
 00000906	     A830	ADD R0 SP #192
 00000908	 12000018	MOV R1 lower 16-bits base(2), next at  000008D8
 0000090C	 00000001	MOVT R1 higher 16-bits const(1)
 00000910	     AA07	ADD R2 SP #28
 00000912	 21100017	BL Mod(  2) proc(17)
 00000916	     980D	LDR R0 [ SP + 52 ]
 00000918	     9907	LDR R1 [ SP + 28 ]
 0000091A	     6001	STR R1 [  R0 + 0 ]
 0000091C	     980D	LDR R0 [ SP + 52 ]
 0000091E	     1D00	ADDS R0 R0 #4
 00000920	     900D	STR R0 [ SP + 52 ]
 00000922	     A830	ADD R0 SP #192
 00000924	 1200000E	MOV R1 lower 16-bits base(2), next at  00000908
 00000928	 00000001	MOVT R1 higher 16-bits const(1)
 0000092C	 F10D0245	ADD R2 SP #69
 00000930	 2100000F	BL Mod(  2) proc(16)
 00000934	     E7C3	B #-122, goes to  000008BE
 00000936	     980D	LDR R0 [ SP + 52 ]
 00000938	     2100	MOVS R1 #0
 0000093A	     7001	STRB R1 [ R0 + 0 ]
 0000093C	     980D	LDR R0 [ SP + 52 ]
 0000093E	     1C40	ADDS R0 R0 #1
 00000940	     900D	STR R0 [ SP + 52 ]
 00000942	     980D	LDR R0 [ SP + 52 ]
 00000944	 F36F009F	BFC R0 #2 #30
 00000948	     2800	CMP R0 #0
 0000094A	     D1F4	BNE #-24, goes to  00000936
 0000094C	     9804	LDR R0 [ SP + 16 ]
 0000094E	     2800	CMP R0 #0
 00000950	     BF08	IT EQ
 00000952	 EC03D6A4	TrapEQ 4 at pos 7914
 00000956	     990D	LDR R1 [ SP + 52 ]
 00000958	     6441	STR R1 [  R0 + 68 ]
 0000095A	     A830	ADD R0 SP #192
 0000095C	 1200001C	MOV R1 lower 16-bits base(2), next at  00000924
 00000960	 00000001	MOVT R1 higher 16-bits const(1)
 00000964	     AA07	ADD R2 SP #28
 00000966	 2110001B	BL Mod(  2) proc(17)
 0000096A	     9807	LDR R0 [ SP + 28 ]
 0000096C	     2800	CMP R0 #0
 0000096E	 F3408012	BLE #36, goes to  00000996
 00000972	     A830	ADD R0 SP #192
 00000974	 1200000C	MOV R1 lower 16-bits base(2), next at  0000095C
 00000978	 00000001	MOVT R1 higher 16-bits const(1)
 0000097C	     AA10	ADD R2 SP #64
 0000097E	 2110000C	BL Mod(  2) proc(17)
 00000982	     980D	LDR R0 [ SP + 52 ]
 00000984	     9910	LDR R1 [ SP + 64 ]
 00000986	     6001	STR R1 [  R0 + 0 ]
 00000988	     980D	LDR R0 [ SP + 52 ]
 0000098A	     1D00	ADDS R0 R0 #4
 0000098C	     900D	STR R0 [ SP + 52 ]
 0000098E	     9807	LDR R0 [ SP + 28 ]
 00000990	     1E40	SUBS R0 R0 #1
 00000992	     9007	STR R0 [ SP + 28 ]
 00000994	     E7E9	B #-46, goes to  0000096A
 00000996	     9804	LDR R0 [ SP + 16 ]
 00000998	     2800	CMP R0 #0
 0000099A	     BF08	IT EQ
 0000099C	 EC03F004	TrapEQ 4 at pos 8064
 000009A0	     990D	LDR R1 [ SP + 52 ]
 000009A2	     6481	STR R1 [  R0 + 72 ]
 000009A4	     A830	ADD R0 SP #192
 000009A6	 12000019	MOV R1 lower 16-bits base(2), next at  00000974
 000009AA	 00000001	MOVT R1 higher 16-bits const(1)
 000009AE	     AA10	ADD R2 SP #64
 000009B0	 21100019	BL Mod(  2) proc(17)
 000009B4	     9810	LDR R0 [ SP + 64 ]
 000009B6	     2800	CMP R0 #0
 000009B8	 F2C08016	BLT #44, goes to  000009E8
 000009BC	     9804	LDR R0 [ SP + 16 ]
 000009BE	     2800	CMP R0 #0
 000009C0	     BF08	IT EQ
 000009C2	 EC03F6A4	TrapEQ 4 at pos 8170
 000009C6	     6B40	LDR R0 [ R0 + 52 ]
 000009C8	     9910	LDR R1 [ SP + 64 ]
 000009CA	     1840	ADDS R0 R0 R1
 000009CC	     990D	LDR R1 [ SP + 52 ]
 000009CE	     6008	STR R0 [  R1 + 0 ]
 000009D0	     980D	LDR R0 [ SP + 52 ]
 000009D2	     1D00	ADDS R0 R0 #4
 000009D4	     900D	STR R0 [ SP + 52 ]
 000009D6	     A830	ADD R0 SP #192
 000009D8	 12000019	MOV R1 lower 16-bits base(2), next at  000009A6
 000009DC	 00000001	MOVT R1 higher 16-bits const(1)
 000009E0	     AA10	ADD R2 SP #64
 000009E2	 21100019	BL Mod(  2) proc(17)
 000009E6	     E7E5	B #-54, goes to  000009B4
 000009E8	     980D	LDR R0 [ SP + 52 ]
 000009EA	     2100	MOVS R1 #0
 000009EC	     6001	STR R1 [  R0 + 0 ]
 000009EE	     980D	LDR R0 [ SP + 52 ]
 000009F0	     1D00	ADDS R0 R0 #4
 000009F2	     900D	STR R0 [ SP + 52 ]
 000009F4	     A830	ADD R0 SP #192
 000009F6	 1200000F	MOV R1 lower 16-bits base(2), next at  000009D8
 000009FA	 00000001	MOVT R1 higher 16-bits const(1)
 000009FE	     AA13	ADD R2 SP #76
 00000A00	 2110000F	BL Mod(  2) proc(17)
 00000A04	     A830	ADD R0 SP #192
 00000A06	 12000008	MOV R1 lower 16-bits base(2), next at  000009F6
 00000A0A	 00000001	MOVT R1 higher 16-bits const(1)
 00000A0E	     AA14	ADD R2 SP #80
 00000A10	 21100008	BL Mod(  2) proc(17)
 00000A14	     A830	ADD R0 SP #192
 00000A16	 12000008	MOV R1 lower 16-bits base(2), next at  00000A06
 00000A1A	 00000001	MOVT R1 higher 16-bits const(1)
 00000A1E	     AA15	ADD R2 SP #84
 00000A20	 21100008	BL Mod(  2) proc(17)
 00000A24	     A830	ADD R0 SP #192
 00000A26	 12000008	MOV R1 lower 16-bits base(2), next at  00000A16
 00000A2A	 00000001	MOVT R1 higher 16-bits const(1)
 00000A2E	     AA10	ADD R2 SP #64
 00000A30	 21100008	BL Mod(  2) proc(17)
 00000A34	     9804	LDR R0 [ SP + 16 ]
 00000A36	     2800	CMP R0 #0
 00000A38	     BF08	IT EQ
 00000A3A	 EC041554	TrapEQ 4 at pos 8405
 00000A3E	     6B80	LDR R0 [ R0 + 56 ]
 00000A40	     9910	LDR R1 [ SP + 64 ]
 00000A42	     1840	ADDS R0 R0 R1
 00000A44	     1C40	ADDS R0 R0 #1
 00000A46	     9012	STR R0 [ SP + 72 ]
 00000A48	     A830	ADD R0 SP #192
 00000A4A	 12000012	MOV R1 lower 16-bits base(2), next at  00000A26
 00000A4E	 00000001	MOVT R1 higher 16-bits const(1)
 00000A52	 F10D0245	ADD R2 SP #69
 00000A56	 21000013	BL Mod(  2) proc(16)
 00000A5A	 F89D0045	LDRB R0 [ SP + 69 ]
 00000A5E	     284F	CMP R0 #79
 00000A60	 F0008007	BEQ #14, goes to  00000A72
 00000A64	     2000	MOVS R0 #0
 00000A66	     9004	STR R0 [ SP + 16 ]
 00000A68	     2004	MOVS R0 #4
 00000A6A	     9901	LDR R1 [ SP + 4 ]
 00000A6C	     9A02	LDR R2 [ SP + 8 ]
 00000A6E	 F7FFFC0B	BL #-2026, goes to  00000288
 00000A72	 000001B8	MOV R0 lower 16-bits base(0), next at  00000702
 00000A76	 0000000C	MOVT R0 higher 16-bits var + 12
 00000A7A	     6800	LDR R0 [ R0 + 0 ]
 00000A7C	     2800	CMP R0 #0
 00000A7E	 F04081D6	BNE #940, goes to  00000E2E
 00000A82	     2000	MOVS R0 #0
 00000A84	     901E	STR R0 [ SP + 120 ]
 00000A86	     980D	LDR R0 [ SP + 52 ]
 00000A88	     901D	STR R0 [ SP + 116 ]
 00000A8A	     9804	LDR R0 [ SP + 16 ]
 00000A8C	     2800	CMP R0 #0
 00000A8E	     BF08	IT EQ
 00000A90	 EC043484	TrapEQ 4 at pos 8648
 00000A94	     6B80	LDR R0 [ R0 + 56 ]
 00000A96	     9913	LDR R1 [ SP + 76 ]
 00000A98	     1840	ADDS R0 R0 R1
 00000A9A	     9017	STR R0 [ SP + 92 ]
 00000A9C	     9804	LDR R0 [ SP + 16 ]
 00000A9E	     2800	CMP R0 #0
 00000AA0	     BF08	IT EQ
 00000AA2	 EC043704	TrapEQ 4 at pos 8688
 00000AA6	     9917	LDR R1 [ SP + 92 ]
 00000AA8	     6B80	LDR R0 [ R0 + 56 ]
 00000AAA	     4281	CMP R1 R0
 00000AAC	 F0008091	BEQ #290, goes to  00000BD2
 00000AB0	     9817	LDR R0 [ SP + 92 ]
 00000AB2	 F7FFFB31	BL #-2462, goes to  00000118
 00000AB6	     9018	STR R0 [ SP + 96 ]
 00000AB8	     9818	LDR R0 [ SP + 96 ]
 00000ABA	 F7FFFB12	BL #-2524, goes to  000000E2
 00000ABE	     9018	STR R0 [ SP + 96 ]
 00000AC0	     9818	LDR R0 [ SP + 96 ]
 00000AC2	     1700	ASRS R0 R0 #28
 00000AC4	 F36F101F	BFC R0 #4 #28
 00000AC8	     900A	STR R0 [ SP + 40 ]
 00000ACA	     9818	LDR R0 [ SP + 96 ]
 00000ACC	     1500	ASRS R0 R0 #20
 00000ACE	 F36F201F	BFC R0 #8 #24
 00000AD2	     9019	STR R0 [ SP + 100 ]
 00000AD4	     9818	LDR R0 [ SP + 96 ]
 00000AD6	 F36F501F	BFC R0 #20 #12
 00000ADA	     0040	LSLS R0 R0 #1
 00000ADC	     9016	STR R0 [ SP + 88 ]
 00000ADE	     9804	LDR R0 [ SP + 16 ]
 00000AE0	     2800	CMP R0 #0
 00000AE2	     BF08	IT EQ
 00000AE4	 EC045754	TrapEQ 4 at pos 8949
 00000AE8	     990A	LDR R1 [ SP + 40 ]
 00000AEA	     1E49	SUBS R1 R1 #1
 00000AEC	     0089	LSLS R1 R1 #2
 00000AEE	     6BC0	LDR R0 [ R0 + 60 ]
 00000AF0	     1840	ADDS R0 R0 R1
 00000AF2	     6800	LDR R0 [ R0 + 0 ]
 00000AF4	     9005	STR R0 [ SP + 20 ]
 00000AF6	     9805	LDR R0 [ SP + 20 ]
 00000AF8	     2800	CMP R0 #0
 00000AFA	     BF08	IT EQ
 00000AFC	 EC0462B4	TrapEQ 4 at pos 9003
 00000B00	     9919	LDR R1 [ SP + 100 ]
 00000B02	     0089	LSLS R1 R1 #2
 00000B04	     6C40	LDR R0 [ R0 + 68 ]
 00000B06	     1840	ADDS R0 R0 R1
 00000B08	     6800	LDR R0 [ R0 + 0 ]
 00000B0A	     901B	STR R0 [ SP + 108 ]
 00000B0C	     9805	LDR R0 [ SP + 20 ]
 00000B0E	     2800	CMP R0 #0
 00000B10	     BF08	IT EQ
 00000B12	 EC046564	TrapEQ 4 at pos 9046
 00000B16	     991B	LDR R1 [ SP + 108 ]
 00000B18	     6B80	LDR R0 [ R0 + 56 ]
 00000B1A	     1808	ADDS R0 R1 R0
 00000B1C	     901B	STR R0 [ SP + 108 ]
 00000B1E	     981B	LDR R0 [ SP + 108 ]
 00000B20	     9917	LDR R1 [ SP + 92 ]
 00000B22	     1A40	SUBS R0 R0 R1
 00000B24	     1F00	SUBS R0 R0 #4
 00000B26	     901C	STR R0 [ SP + 112 ]
 00000B28	     981C	LDR R0 [ SP + 112 ]
 00000B2A	 F1B04F7F	CMP R0 #-16777216
 00000B2E	 F2C08005	BLT #10, goes to  00000B3C
 00000B32	     981C	LDR R0 [ SP + 112 ]
 00000B34	 F1B07F80	CMP R0 #16777216
 00000B38	 F2C08036	BLT #108, goes to  00000BA8
 00000B3C	     2000	MOVS R0 #0
 00000B3E	     9006	STR R0 [ SP + 24 ]
 00000B40	     981D	LDR R0 [ SP + 116 ]
 00000B42	     900E	STR R0 [ SP + 56 ]
 00000B44	     980E	LDR R0 [ SP + 56 ]
 00000B46	     1D00	ADDS R0 R0 #4
 00000B48	     6800	LDR R0 [ R0 + 0 ]
 00000B4A	     9010	STR R0 [ SP + 64 ]
 00000B4C	     9806	LDR R0 [ SP + 24 ]
 00000B4E	     991E	LDR R1 [ SP + 120 ]
 00000B50	     4288	CMP R0 R1
 00000B52	 F2808010	BGE #32, goes to  00000B76
 00000B56	     981B	LDR R0 [ SP + 108 ]
 00000B58	     9910	LDR R1 [ SP + 64 ]
 00000B5A	     4288	CMP R0 R1
 00000B5C	 F000800B	BEQ #22, goes to  00000B76
 00000B60	     980E	LDR R0 [ SP + 56 ]
 00000B62	     3008	ADDS R0 R0 #8
 00000B64	     900E	STR R0 [ SP + 56 ]
 00000B66	     980E	LDR R0 [ SP + 56 ]
 00000B68	     1D00	ADDS R0 R0 #4
 00000B6A	     6800	LDR R0 [ R0 + 0 ]
 00000B6C	     9010	STR R0 [ SP + 64 ]
 00000B6E	     9806	LDR R0 [ SP + 24 ]
 00000B70	     1C40	ADDS R0 R0 #1
 00000B72	     9006	STR R0 [ SP + 24 ]
 00000B74	     E7EA	B #-44, goes to  00000B4C
 00000B76	     9806	LDR R0 [ SP + 24 ]
 00000B78	     991E	LDR R1 [ SP + 120 ]
 00000B7A	     4288	CMP R0 R1
 00000B7C	 F2C0800D	BLT #26, goes to  00000B9A
 00000B80	     981E	LDR R0 [ SP + 120 ]
 00000B82	     1C40	ADDS R0 R0 #1
 00000B84	     901E	STR R0 [ SP + 120 ]
 00000B86	     980E	LDR R0 [ SP + 56 ]
 00000B88	     21F0	MOVS R1 #240
 00000B8A	 F6CD71F8	MOVT R1 #57336
 00000B8E	     6001	STR R1 [  R0 + 0 ]
 00000B90	     980E	LDR R0 [ SP + 56 ]
 00000B92	     1D00	ADDS R0 R0 #4
 00000B94	     991B	LDR R1 [ SP + 108 ]
 00000B96	     1C49	ADDS R1 R1 #1
 00000B98	     6001	STR R1 [  R0 + 0 ]
 00000B9A	     980E	LDR R0 [ SP + 56 ]
 00000B9C	     901B	STR R0 [ SP + 108 ]
 00000B9E	     981B	LDR R0 [ SP + 108 ]
 00000BA0	     9917	LDR R1 [ SP + 92 ]
 00000BA2	     1A40	SUBS R0 R0 R1
 00000BA4	     1F00	SUBS R0 R0 #4
 00000BA6	     901C	STR R0 [ SP + 112 ]
 00000BA8	     9817	LDR R0 [ SP + 92 ]
 00000BAA	     B401	PUSH R0
 00000BAC	     981D	LDR R0 [ SP + 116 ]
 00000BAE	 F7FFFA27	BL #-2994, goes to  00000000
 00000BB2	 F24D0100	MOV R1 #53248
 00000BB6	 F2CF0100	MOVT R1 #61440
 00000BBA	     1808	ADDS R0 R1 R0
 00000BBC	 F7FFFA91	BL #-2782, goes to  000000E2
 00000BC0	     4601	MOV R1 R0
 00000BC2	     BC01	POP R0
 00000BC4	 F7FFFAD0	BL #-2656, goes to  00000168
 00000BC8	     9817	LDR R0 [ SP + 92 ]
 00000BCA	     9916	LDR R1 [ SP + 88 ]
 00000BCC	     1A40	SUBS R0 R0 R1
 00000BCE	     9017	STR R0 [ SP + 92 ]
 00000BD0	     E764	B #-312, goes to  00000A9C
 00000BD2	     981E	LDR R0 [ SP + 120 ]
 00000BD4	     00C0	LSLS R0 R0 #3
 00000BD6	     990D	LDR R1 [ SP + 52 ]
 00000BD8	     1809	ADDS R1 R1 R0
 00000BDA	     910D	STR R1 [ SP + 52 ]
 00000BDC	     9804	LDR R0 [ SP + 16 ]
 00000BDE	     2800	CMP R0 #0
 00000BE0	     BF08	IT EQ
 00000BE2	 EC04E614	TrapEQ 4 at pos 10081
 00000BE6	     6B80	LDR R0 [ R0 + 56 ]
 00000BE8	     9914	LDR R1 [ SP + 80 ]
 00000BEA	     1840	ADDS R0 R0 R1
 00000BEC	     9017	STR R0 [ SP + 92 ]
 00000BEE	     9804	LDR R0 [ SP + 16 ]
 00000BF0	     2800	CMP R0 #0
 00000BF2	     BF08	IT EQ
 00000BF4	 EC04F094	TrapEQ 4 at pos 10121
 00000BF8	     9917	LDR R1 [ SP + 92 ]
 00000BFA	     6B80	LDR R0 [ R0 + 56 ]
 00000BFC	     4281	CMP R1 R0
 00000BFE	 F0008092	BEQ #292, goes to  00000D26
 00000C02	     9817	LDR R0 [ SP + 92 ]
 00000C04	 F7FFFA88	BL #-2800, goes to  00000118
 00000C08	     9018	STR R0 [ SP + 96 ]
 00000C0A	     9818	LDR R0 [ SP + 96 ]
 00000C0C	 F7FFFA69	BL #-2862, goes to  000000E2
 00000C10	     9018	STR R0 [ SP + 96 ]
 00000C12	     9818	LDR R0 [ SP + 96 ]
 00000C14	     1700	ASRS R0 R0 #28
 00000C16	 F36F101F	BFC R0 #4 #28
 00000C1A	     9019	STR R0 [ SP + 100 ]
 00000C1C	     9818	LDR R0 [ SP + 96 ]
 00000C1E	     1600	ASRS R0 R0 #24
 00000C20	 F36F101F	BFC R0 #4 #28
 00000C24	     900A	STR R0 [ SP + 40 ]
 00000C26	     9818	LDR R0 [ SP + 96 ]
 00000C28	 F36F601F	BFC R0 #24 #8
 00000C2C	     0040	LSLS R0 R0 #1
 00000C2E	     9016	STR R0 [ SP + 88 ]
 00000C30	     9817	LDR R0 [ SP + 92 ]
 00000C32	     1D00	ADDS R0 R0 #4
 00000C34	 F7FFFA70	BL #-2848, goes to  00000118
 00000C38	     9018	STR R0 [ SP + 96 ]
 00000C3A	     9818	LDR R0 [ SP + 96 ]
 00000C3C	 F7FFFA51	BL #-2910, goes to  000000E2
 00000C40	     9018	STR R0 [ SP + 96 ]
 00000C42	     980A	LDR R0 [ SP + 40 ]
 00000C44	     2800	CMP R0 #0
 00000C46	 F040800D	BNE #26, goes to  00000C64
 00000C4A	     9804	LDR R0 [ SP + 16 ]
 00000C4C	     2800	CMP R0 #0
 00000C4E	     BF08	IT EQ
 00000C50	 EC052354	TrapEQ 4 at pos 10549
 00000C54	     9918	LDR R1 [ SP + 96 ]
 00000C56	 F36F611F	BFC R1 #24 #8
 00000C5A	     6B40	LDR R0 [ R0 + 52 ]
 00000C5C	     1840	ADDS R0 R0 R1
 00000C5E	     901B	STR R0 [ SP + 108 ]
 00000C60	 F000B836	B #108, goes to  00000CD0
 00000C64	     9818	LDR R0 [ SP + 96 ]
 00000C66	 F36F201F	BFC R0 #8 #24
 00000C6A	     901A	STR R0 [ SP + 104 ]
 00000C6C	     9804	LDR R0 [ SP + 16 ]
 00000C6E	     2800	CMP R0 #0
 00000C70	     BF08	IT EQ
 00000C72	 EC053194	TrapEQ 4 at pos 10649
 00000C76	     990A	LDR R1 [ SP + 40 ]
 00000C78	     1E49	SUBS R1 R1 #1
 00000C7A	     0089	LSLS R1 R1 #2
 00000C7C	     6BC0	LDR R0 [ R0 + 60 ]
 00000C7E	     1840	ADDS R0 R0 R1
 00000C80	     6800	LDR R0 [ R0 + 0 ]
 00000C82	     9005	STR R0 [ SP + 20 ]
 00000C84	     9805	LDR R0 [ SP + 20 ]
 00000C86	     2800	CMP R0 #0
 00000C88	     BF08	IT EQ
 00000C8A	 EC053514	TrapEQ 4 at pos 10705
 00000C8E	     991A	LDR R1 [ SP + 104 ]
 00000C90	     0089	LSLS R1 R1 #2
 00000C92	     6C40	LDR R0 [ R0 + 68 ]
 00000C94	     1840	ADDS R0 R0 R1
 00000C96	     6800	LDR R0 [ R0 + 0 ]
 00000C98	     901C	STR R0 [ SP + 112 ]
 00000C9A	     9818	LDR R0 [ SP + 96 ]
 00000C9C	     1200	ASRS R0 R0 #8
 00000C9E	 EA5F0070	RORS R0 R0 #1
 00000CA2	 F140800C	BPL #24, goes to  00000CBE
 00000CA6	     9805	LDR R0 [ SP + 20 ]
 00000CA8	     2800	CMP R0 #0
 00000CAA	     BF08	IT EQ
 00000CAC	 EC0541E4	TrapEQ 4 at pos 10782
 00000CB0	     6B80	LDR R0 [ R0 + 56 ]
 00000CB2	     991C	LDR R1 [ SP + 112 ]
 00000CB4	     1840	ADDS R0 R0 R1
 00000CB6	     1C40	ADDS R0 R0 #1
 00000CB8	     901B	STR R0 [ SP + 108 ]
 00000CBA	 F000B809	B #18, goes to  00000CD0
 00000CBE	     9805	LDR R0 [ SP + 20 ]
 00000CC0	     2800	CMP R0 #0
 00000CC2	     BF08	IT EQ
 00000CC4	 EC0546A4	TrapEQ 4 at pos 10858
 00000CC8	     6B40	LDR R0 [ R0 + 52 ]
 00000CCA	     991C	LDR R1 [ SP + 112 ]
 00000CCC	     1840	ADDS R0 R0 R1
 00000CCE	     901B	STR R0 [ SP + 108 ]
 00000CD0	     9817	LDR R0 [ SP + 92 ]
 00000CD2	     B401	PUSH R0
 00000CD4	     981A	LDR R0 [ SP + 104 ]
 00000CD6	     991C	LDR R1 [ SP + 112 ]
 00000CD8	 F36F411F	BFC R1 #16 #16
 00000CDC	 F7FFF9E2	BL #-3132, goes to  000000A4
 00000CE0	     2100	MOVS R1 #0
 00000CE2	 F2CF2140	MOVT R1 #62016
 00000CE6	     1808	ADDS R0 R1 R0
 00000CE8	 F7FFF9FB	BL #-3082, goes to  000000E2
 00000CEC	     4601	MOV R1 R0
 00000CEE	     BC01	POP R0
 00000CF0	 F7FFFA3A	BL #-2956, goes to  00000168
 00000CF4	     9817	LDR R0 [ SP + 92 ]
 00000CF6	     1D00	ADDS R0 R0 #4
 00000CF8	     B401	PUSH R0
 00000CFA	     981A	LDR R0 [ SP + 104 ]
 00000CFC	     991C	LDR R1 [ SP + 112 ]
 00000CFE	     1409	ASRS R1 R1 #16
 00000D00	 F36F411F	BFC R1 #16 #16
 00000D04	 F7FFF9CE	BL #-3172, goes to  000000A4
 00000D08	     2100	MOVS R1 #0
 00000D0A	 F2CF21C0	MOVT R1 #62144
 00000D0E	     1808	ADDS R0 R1 R0
 00000D10	 F7FFF9E7	BL #-3122, goes to  000000E2
 00000D14	     4601	MOV R1 R0
 00000D16	     BC01	POP R0
 00000D18	 F7FFFA26	BL #-2996, goes to  00000168
 00000D1C	     9817	LDR R0 [ SP + 92 ]
 00000D1E	     9916	LDR R1 [ SP + 88 ]
 00000D20	     1A40	SUBS R0 R0 R1
 00000D22	     9017	STR R0 [ SP + 92 ]
 00000D24	     E763	B #-314, goes to  00000BEE
 00000D26	     9804	LDR R0 [ SP + 16 ]
 00000D28	     2800	CMP R0 #0
 00000D2A	     BF08	IT EQ
 00000D2C	 EC0571B4	TrapEQ 4 at pos 11163
 00000D30	     9915	LDR R1 [ SP + 84 ]
 00000D32	     0089	LSLS R1 R1 #2
 00000D34	     6B40	LDR R0 [ R0 + 52 ]
 00000D36	     1840	ADDS R0 R0 R1
 00000D38	     9017	STR R0 [ SP + 92 ]
 00000D3A	     9804	LDR R0 [ SP + 16 ]
 00000D3C	     2800	CMP R0 #0
 00000D3E	     BF08	IT EQ
 00000D40	 EC057454	TrapEQ 4 at pos 11205
 00000D44	     9917	LDR R1 [ SP + 92 ]
 00000D46	     6B40	LDR R0 [ R0 + 52 ]
 00000D48	     4281	CMP R1 R0
 00000D4A	 F0008049	BEQ #146, goes to  00000DE0
 00000D4E	     9817	LDR R0 [ SP + 92 ]
 00000D50	     6800	LDR R0 [ R0 + 0 ]
 00000D52	     9018	STR R0 [ SP + 96 ]
 00000D54	     9818	LDR R0 [ SP + 96 ]
 00000D56	     1600	ASRS R0 R0 #24
 00000D58	 F36F101F	BFC R0 #4 #28
 00000D5C	     900A	STR R0 [ SP + 40 ]
 00000D5E	     9818	LDR R0 [ SP + 96 ]
 00000D60	     1300	ASRS R0 R0 #12
 00000D62	 F36F301F	BFC R0 #12 #20
 00000D66	     901A	STR R0 [ SP + 104 ]
 00000D68	     9818	LDR R0 [ SP + 96 ]
 00000D6A	 F36F301F	BFC R0 #12 #20
 00000D6E	     9016	STR R0 [ SP + 88 ]
 00000D70	     980A	LDR R0 [ SP + 40 ]
 00000D72	     2800	CMP R0 #0
 00000D74	 F040800B	BNE #22, goes to  00000D8E
 00000D78	     9804	LDR R0 [ SP + 16 ]
 00000D7A	     2800	CMP R0 #0
 00000D7C	     BF08	IT EQ
 00000D7E	 EC059184	TrapEQ 4 at pos 11416
 00000D82	     6B40	LDR R0 [ R0 + 52 ]
 00000D84	     991A	LDR R1 [ SP + 104 ]
 00000D86	     1840	ADDS R0 R0 R1
 00000D88	     9018	STR R0 [ SP + 96 ]
 00000D8A	 F000B820	B #64, goes to  00000DCE
 00000D8E	     9804	LDR R0 [ SP + 16 ]
 00000D90	     2800	CMP R0 #0
 00000D92	     BF08	IT EQ
 00000D94	 EC059574	TrapEQ 4 at pos 11479
 00000D98	     990A	LDR R1 [ SP + 40 ]
 00000D9A	     1E49	SUBS R1 R1 #1
 00000D9C	     0089	LSLS R1 R1 #2
 00000D9E	     6BC0	LDR R0 [ R0 + 60 ]
 00000DA0	     1840	ADDS R0 R0 R1
 00000DA2	     6800	LDR R0 [ R0 + 0 ]
 00000DA4	     9005	STR R0 [ SP + 20 ]
 00000DA6	     9805	LDR R0 [ SP + 20 ]
 00000DA8	     2800	CMP R0 #0
 00000DAA	     BF08	IT EQ
 00000DAC	 EC05A0F4	TrapEQ 4 at pos 11535
 00000DB0	     991A	LDR R1 [ SP + 104 ]
 00000DB2	     0089	LSLS R1 R1 #2
 00000DB4	     6C40	LDR R0 [ R0 + 68 ]
 00000DB6	     1840	ADDS R0 R0 R1
 00000DB8	     6800	LDR R0 [ R0 + 0 ]
 00000DBA	     901C	STR R0 [ SP + 112 ]
 00000DBC	     9805	LDR R0 [ SP + 20 ]
 00000DBE	     2800	CMP R0 #0
 00000DC0	     BF08	IT EQ
 00000DC2	 EC05A414	TrapEQ 4 at pos 11585
 00000DC6	     6B40	LDR R0 [ R0 + 52 ]
 00000DC8	     991C	LDR R1 [ SP + 112 ]
 00000DCA	     1840	ADDS R0 R0 R1
 00000DCC	     9018	STR R0 [ SP + 96 ]
 00000DCE	     9817	LDR R0 [ SP + 92 ]
 00000DD0	     9918	LDR R1 [ SP + 96 ]
 00000DD2	     6001	STR R1 [  R0 + 0 ]
 00000DD4	     9816	LDR R0 [ SP + 88 ]
 00000DD6	     0080	LSLS R0 R0 #2
 00000DD8	     9917	LDR R1 [ SP + 92 ]
 00000DDA	     1A08	SUBS R0 R1 R0
 00000DDC	     9017	STR R0 [ SP + 92 ]
 00000DDE	     E7AC	B #-168, goes to  00000D3A
 00000DE0	     9812	LDR R0 [ SP + 72 ]
 00000DE2	     4780	BLX R0
 00000DE4	 F89D0046	LDRB R0 [ SP + 70 ]
 00000DE8	     2800	CMP R0 #0
 00000DEA	 F000801E	BEQ #60, goes to  00000E2A
 00000DEE	 000001BE	MOV R0 lower 16-bits base(0), next at  00000A72
 00000DF2	 00000008	MOVT R0 higher 16-bits var + 8
 00000DF6	     6800	LDR R0 [ R0 + 0 ]
 00000DF8	     990D	LDR R1 [ SP + 52 ]
 00000DFA	     4288	CMP R0 R1
 00000DFC	 F3408015	BLE #42, goes to  00000E2A
 00000E00	     9804	LDR R0 [ SP + 16 ]
 00000E02	     2800	CMP R0 #0
 00000E04	     BF08	IT EQ
 00000E06	 EC05B7C4	TrapEQ 4 at pos 11772
 00000E0A	 1000000E	MOV R1 lower 16-bits base(0), next at  00000DEE
 00000E0E	 00000008	MOVT R1 higher 16-bits var + 8
 00000E12	     6809	LDR R1 [ R1 + 0 ]
 00000E14	     9A0D	LDR R2 [ SP + 52 ]
 00000E16	     1A89	SUBS R1 R1 R2
 00000E18	     6AC2	LDR R2 [ R0 + 44 ]
 00000E1A	     1A52	SUBS R2 R2 R1
 00000E1C	     62C2	STR R2 [  R0 + 44 ]
 00000E1E	     980D	LDR R0 [ SP + 52 ]
 00000E20	 1000000B	MOV R1 lower 16-bits base(0), next at  00000E0A
 00000E24	 00000008	MOVT R1 higher 16-bits var + 8
 00000E28	     6008	STR R0 [  R1 + 0 ]
 00000E2A	 F000B834	B #104, goes to  00000E96
 00000E2E	 00000007	MOV R0 lower 16-bits base(0), next at  00000E20
 00000E32	 0000000C	MOVT R0 higher 16-bits var + 12
 00000E36	     6800	LDR R0 [ R0 + 0 ]
 00000E38	     2803	CMP R0 #3
 00000E3A	 F2C0802C	BLT #88, goes to  00000E96
 00000E3E	 00000008	MOV R0 lower 16-bits base(0), next at  00000E2E
 00000E42	 00000010	MOVT R0 higher 16-bits var + 16
 00000E46	     9901	LDR R1 [ SP + 4 ]
 00000E48	     9A02	LDR R2 [ SP + 8 ]
 00000E4A	     2A00	CMP R2 #0
 00000E4C	     D00B	BEQ #22, goes to  00000E66
 00000E4E	     1CD2	ADDS R2 R2 #3
 00000E50	     1092	ASRS R2 R2 #2
 00000E52	     2A08	CMP R2 #8
 00000E54	     BFC8	IT GT
 00000E56	 EC05C6E3	TrapGT 3 at pos 11886
 00000E5A	 F8513B04	LDR R3 [ R1 ] + 4
 00000E5E	 F8403B04	STR R3 [  R0 ] + 4
 00000E62	     1E52	SUBS R2 R2 #1
 00000E64	     D1F9	BNE #-14, goes to  00000E5A
 00000E66	     980B	LDR R0 [ SP + 44 ]
 00000E68	     2800	CMP R0 #0
 00000E6A	 F3408014	BLE #40, goes to  00000E96
 00000E6E	     980B	LDR R0 [ SP + 44 ]
 00000E70	     1E40	SUBS R0 R0 #1
 00000E72	     900B	STR R0 [ SP + 44 ]
 00000E74	     980B	LDR R0 [ SP + 44 ]
 00000E76	     2810	CMP R0 #16
 00000E78	     BF28	IT CS
 00000E7A	 EC05D2D1	TrapCS 1 at pos 11949
 00000E7E	 EB0D0080	ADD R0 SP R0 LSL #2
 00000E82	 F8D000D8	LDR R0 [ R0 + 216 ]
 00000E86	     2800	CMP R0 #0
 00000E88	     BF08	IT EQ
 00000E8A	 EC05D344	TrapEQ 4 at pos 11956
 00000E8E	     6B01	LDR R1 [ R0 + 48 ]
 00000E90	     1E49	SUBS R1 R1 #1
 00000E92	     6301	STR R1 [  R0 + 48 ]
 00000E94	     E7E7	B #-50, goes to  00000E66
 00000E96	     9804	LDR R0 [ SP + 16 ]
 00000E98	     9903	LDR R1 [ SP + 12 ]
 00000E9A	     6008	STR R0 [  R1 + 0 ]
 00000E9C	 F85DEB04	LDR LR [ SP ] + 4
 00000EA0	     B045	ADD SP SP #276
 00000EA2	     4770	BX LR
 00000EA4	     B08C	SUB SP SP #48
 00000EA6	     B407	PUSH R0 R1 R2
 00000EA8	     B500	PUSH LR
 00000EAA	     2005	MOVS R0 #5
 00000EAC	 10000037	MOV R1 lower 16-bits base(0), next at  00000E3E
 00000EB0	 0000000C	MOVT R1 higher 16-bits var + 12
 00000EB4	     6008	STR R0 [  R1 + 0 ]
 00000EB6	     2000	MOVS R0 #0
 00000EB8	     9006	STR R0 [ SP + 24 ]
 00000EBA	     9801	LDR R0 [ SP + 4 ]
 00000EBC	     2800	CMP R0 #0
 00000EBE	 F000806C	BEQ #216, goes to  00000F9A
 00000EC2	     9801	LDR R0 [ SP + 4 ]
 00000EC4	     2800	CMP R0 #0
 00000EC6	     BF08	IT EQ
 00000EC8	 EC05F394	TrapEQ 4 at pos 12217
 00000ECC	     6C00	LDR R0 [ R0 + 64 ]
 00000ECE	     9005	STR R0 [ SP + 20 ]
 00000ED0	     9805	LDR R0 [ SP + 20 ]
 00000ED2	     7800	LDRB R0 [ R0 + 0 ]
 00000ED4	 F88D001C	STRB R0 [  SP + 28 ]
 00000ED8	 F89D001C	LDRB R0 [ SP + 28 ]
 00000EDC	     2800	CMP R0 #0
 00000EDE	 F000805C	BEQ #184, goes to  00000F9A
 00000EE2	 0000001B	MOV R0 lower 16-bits base(0), next at  00000EAC
 00000EE6	 0000000C	MOVT R0 higher 16-bits var + 12
 00000EEA	     6800	LDR R0 [ R0 + 0 ]
 00000EEC	     2800	CMP R0 #0
 00000EEE	 F0008054	BEQ #168, goes to  00000F9A
 00000EF2	     2000	MOVS R0 #0
 00000EF4	     9004	STR R0 [ SP + 16 ]
 00000EF6	     9804	LDR R0 [ SP + 16 ]
 00000EF8	     2820	CMP R0 #32
 00000EFA	     BF28	IT CS
 00000EFC	 EC060261	TrapCS 1 at pos 12326
 00000F00	     4468	ADD R0 SP R0
 00000F02	 F89D101C	LDRB R1 [ SP + 28 ]
 00000F06	 F8801020	STRB R1 [  R0 + 32 ]
 00000F0A	     9804	LDR R0 [ SP + 16 ]
 00000F0C	     1C40	ADDS R0 R0 #1
 00000F0E	     9004	STR R0 [ SP + 16 ]
 00000F10	     9805	LDR R0 [ SP + 20 ]
 00000F12	     1C40	ADDS R0 R0 #1
 00000F14	     9005	STR R0 [ SP + 20 ]
 00000F16	     9805	LDR R0 [ SP + 20 ]
 00000F18	     7800	LDRB R0 [ R0 + 0 ]
 00000F1A	 F88D001C	STRB R0 [  SP + 28 ]
 00000F1E	 F89D001C	LDRB R0 [ SP + 28 ]
 00000F22	     2800	CMP R0 #0
 00000F24	     D1E7	BNE #-50, goes to  00000EF6
 00000F26	     9804	LDR R0 [ SP + 16 ]
 00000F28	     2820	CMP R0 #32
 00000F2A	     BF28	IT CS
 00000F2C	 EC0606F1	TrapCS 1 at pos 12399
 00000F30	     4468	ADD R0 SP R0
 00000F32	     2100	MOVS R1 #0
 00000F34	 F8801020	STRB R1 [  R0 + 32 ]
 00000F38	     9805	LDR R0 [ SP + 20 ]
 00000F3A	     1C40	ADDS R0 R0 #1
 00000F3C	     9005	STR R0 [ SP + 20 ]
 00000F3E	     9805	LDR R0 [ SP + 20 ]
 00000F40	 F36F009F	BFC R0 #2 #30
 00000F44	     2800	CMP R0 #0
 00000F46	     D1F7	BNE #-18, goes to  00000F38
 00000F48	     9805	LDR R0 [ SP + 20 ]
 00000F4A	     6800	LDR R0 [ R0 + 0 ]
 00000F4C	     9004	STR R0 [ SP + 16 ]
 00000F4E	     9805	LDR R0 [ SP + 20 ]
 00000F50	     1D00	ADDS R0 R0 #4
 00000F52	     9005	STR R0 [ SP + 20 ]
 00000F54	     A808	ADD R0 SP #32
 00000F56	     9902	LDR R1 [ SP + 8 ]
 00000F58	 F8102B01	LDRB R2 [  R0 ] + 1
 00000F5C	 F8113B01	LDRB R3 [  R1 ] + 1
 00000F60	     429A	CMP R2 R3
 00000F62	     D101	BNE #2, goes to  00000F68
 00000F64	     2A00	CMP R2 #0
 00000F66	     D1F7	BNE #-18, goes to  00000F58
 00000F68	 F0408012	BNE #36, goes to  00000F90
 00000F6C	     2000	MOVS R0 #0
 00000F6E	 10000046	MOV R1 lower 16-bits base(0), next at  00000EE2
 00000F72	 0000000C	MOVT R1 higher 16-bits var + 12
 00000F76	     6008	STR R0 [  R1 + 0 ]
 00000F78	     9801	LDR R0 [ SP + 4 ]
 00000F7A	     2800	CMP R0 #0
 00000F7C	     BF08	IT EQ
 00000F7E	 EC0617D4	TrapEQ 4 at pos 12541
 00000F82	     6B80	LDR R0 [ R0 + 56 ]
 00000F84	     9904	LDR R1 [ SP + 16 ]
 00000F86	     1840	ADDS R0 R0 R1
 00000F88	     1C40	ADDS R0 R0 #1
 00000F8A	     9006	STR R0 [ SP + 24 ]
 00000F8C	 F000B804	B #8, goes to  00000F98
 00000F90	     9805	LDR R0 [ SP + 20 ]
 00000F92	     7800	LDRB R0 [ R0 + 0 ]
 00000F94	 F88D001C	STRB R0 [  SP + 28 ]
 00000F98	     E79E	B #-196, goes to  00000ED8
 00000F9A	     9806	LDR R0 [ SP + 24 ]
 00000F9C	 F85DEB04	LDR LR [ SP ] + 4
 00000FA0	     B00F	ADD SP SP #60
 00000FA2	     4770	BX LR
 00000FA4	     B084	SUB SP SP #16
 00000FA6	     B403	PUSH R0 R1
 00000FA8	     B500	PUSH LR
 00000FAA	 0000001E	MOV R0 lower 16-bits base(0), next at  00000F6E
 00000FAE	 00000000	MOVT R0 higher 16-bits var + 0
 00000FB2	     6800	LDR R0 [ R0 + 0 ]
 00000FB4	     9003	STR R0 [ SP + 12 ]
 00000FB6	     2000	MOVS R0 #0
 00000FB8	 10000007	MOV R1 lower 16-bits base(0), next at  00000FAA
 00000FBC	 0000000C	MOVT R1 higher 16-bits var + 12
 00000FC0	     6008	STR R0 [  R1 + 0 ]
 00000FC2	     9803	LDR R0 [ SP + 12 ]
 00000FC4	     2800	CMP R0 #0
 00000FC6	 F0008018	BEQ #48, goes to  00000FFA
 00000FCA	     9803	LDR R0 [ SP + 12 ]
 00000FCC	     2800	CMP R0 #0
 00000FCE	     BF08	IT EQ
 00000FD0	 EC064184	TrapEQ 4 at pos 12824
 00000FD4	     9901	LDR R1 [ SP + 4 ]
 00000FD6	 F8102B01	LDRB R2 [  R0 ] + 1
 00000FDA	 F8113B01	LDRB R3 [  R1 ] + 1
 00000FDE	     429A	CMP R2 R3
 00000FE0	     D101	BNE #2, goes to  00000FE6
 00000FE2	     2A00	CMP R2 #0
 00000FE4	     D1F7	BNE #-18, goes to  00000FD6
 00000FE6	 F0008008	BEQ #16, goes to  00000FFA
 00000FEA	     9803	LDR R0 [ SP + 12 ]
 00000FEC	     2800	CMP R0 #0
 00000FEE	     BF08	IT EQ
 00000FF0	 EC064334	TrapEQ 4 at pos 12851
 00000FF4	     6A00	LDR R0 [ R0 + 32 ]
 00000FF6	     9003	STR R0 [ SP + 12 ]
 00000FF8	     E7E3	B #-58, goes to  00000FC2
 00000FFA	     9803	LDR R0 [ SP + 12 ]
 00000FFC	     2800	CMP R0 #0
 00000FFE	 F0008061	BEQ #194, goes to  000010C4
 00001002	     9803	LDR R0 [ SP + 12 ]
 00001004	     2800	CMP R0 #0
 00001006	     BF08	IT EQ
 00001008	 EC064634	TrapEQ 4 at pos 12899
 0000100C	     6B00	LDR R0 [ R0 + 48 ]
 0000100E	     2800	CMP R0 #0
 00001010	 F0408052	BNE #164, goes to  000010B8
 00001014	     9803	LDR R0 [ SP + 12 ]
 00001016	     2800	CMP R0 #0
 00001018	     BF08	IT EQ
 0000101A	 EC0647D4	TrapEQ 4 at pos 12925
 0000101E	     2100	MOVS R1 #0
 00001020	     7001	STRB R1 [ R0 + 0 ]
 00001022	     9803	LDR R0 [ SP + 12 ]
 00001024	     2800	CMP R0 #0
 00001026	     BF08	IT EQ
 00001028	 EC065144	TrapEQ 4 at pos 12948
 0000102C	     6BC0	LDR R0 [ R0 + 60 ]
 0000102E	     9005	STR R0 [ SP + 20 ]
 00001030	     9803	LDR R0 [ SP + 12 ]
 00001032	     2800	CMP R0 #0
 00001034	     BF08	IT EQ
 00001036	 EC065224	TrapEQ 4 at pos 12962
 0000103A	     6C00	LDR R0 [ R0 + 64 ]
 0000103C	     9006	STR R0 [ SP + 24 ]
 0000103E	     9805	LDR R0 [ SP + 20 ]
 00001040	     9906	LDR R1 [ SP + 24 ]
 00001042	     4288	CMP R0 R1
 00001044	 F280800F	BGE #30, goes to  00001066
 00001048	     9805	LDR R0 [ SP + 20 ]
 0000104A	     6800	LDR R0 [ R0 + 0 ]
 0000104C	     9004	STR R0 [ SP + 16 ]
 0000104E	     9804	LDR R0 [ SP + 16 ]
 00001050	     2800	CMP R0 #0
 00001052	     BF08	IT EQ
 00001054	 EC0655D4	TrapEQ 4 at pos 13021
 00001058	     6B01	LDR R1 [ R0 + 48 ]
 0000105A	     1E49	SUBS R1 R1 #1
 0000105C	     6301	STR R1 [  R0 + 48 ]
 0000105E	     9805	LDR R0 [ SP + 20 ]
 00001060	     1D00	ADDS R0 R0 #4
 00001062	     9005	STR R0 [ SP + 20 ]
 00001064	     E7EB	B #-42, goes to  0000103E
 00001066	 00000057	MOV R0 lower 16-bits base(0), next at  00000FB8
 0000106A	 00000000	MOVT R0 higher 16-bits var + 0
 0000106E	     6800	LDR R0 [ R0 + 0 ]
 00001070	     2800	CMP R0 #0
 00001072	     BF08	IT EQ
 00001074	 EC066064	TrapEQ 4 at pos 13062
 00001078	     7800	LDRB R0 [ R0 + 0 ]
 0000107A	     2800	CMP R0 #0
 0000107C	 F040801A	BNE #52, goes to  000010B4
 00001080	 0000000D	MOV R0 lower 16-bits base(0), next at  00001066
 00001084	 00000000	MOVT R0 higher 16-bits var + 0
 00001088	     6800	LDR R0 [ R0 + 0 ]
 0000108A	 10000005	MOV R1 lower 16-bits base(0), next at  00001080
 0000108E	 00000008	MOVT R1 higher 16-bits var + 8
 00001092	     6008	STR R0 [  R1 + 0 ]
 00001094	 00000005	MOV R0 lower 16-bits base(0), next at  0000108A
 00001098	 00000000	MOVT R0 higher 16-bits var + 0
 0000109C	     6800	LDR R0 [ R0 + 0 ]
 0000109E	     2800	CMP R0 #0
 000010A0	     BF08	IT EQ
 000010A2	 EC067084	TrapEQ 4 at pos 13192
 000010A6	     6A00	LDR R0 [ R0 + 32 ]
 000010A8	 1000000A	MOV R1 lower 16-bits base(0), next at  00001094
 000010AC	 00000000	MOVT R1 higher 16-bits var + 0
 000010B0	     6008	STR R0 [  R1 + 0 ]
 000010B2	     E7D8	B #-80, goes to  00001066
 000010B4	 F000B806	B #12, goes to  000010C4
 000010B8	     2001	MOVS R0 #1
 000010BA	 10000009	MOV R1 lower 16-bits base(0), next at  000010A8
 000010BE	 0000000C	MOVT R1 higher 16-bits var + 12
 000010C2	     6008	STR R0 [  R1 + 0 ]
 000010C4	 F85DEB04	LDR LR [ SP ] + 4
 000010C8	     B006	ADD SP SP #24
 000010CA	     4770	BX LR
 000010CC	     B500	PUSH LR
 000010CE	 0100000A	MOV R0 lower 16-bits base(1), next at  000010BA
 000010D2	 0000000A	MOVT R0 higher 16-bits var(10)
 000010D6	     6800	LDR R0 [ R0 + 0 ]
 000010D8	     3010	ADDS R0 R0 #16
 000010DA	     6800	LDR R0 [ R0 + 0 ]
 000010DC	 10000007	MOV R1 lower 16-bits base(0), next at  000010CE
 000010E0	 00000008	MOVT R1 higher 16-bits var + 8
 000010E4	     6008	STR R0 [  R1 + 0 ]
 000010E6	 01000005	MOV R0 lower 16-bits base(1), next at  000010DC
 000010EA	 0000000A	MOVT R0 higher 16-bits var(10)
 000010EE	     6800	LDR R0 [ R0 + 0 ]
 000010F0	     3014	ADDS R0 R0 #20
 000010F2	     6800	LDR R0 [ R0 + 0 ]
 000010F4	 10000007	MOV R1 lower 16-bits base(0), next at  000010E6
 000010F8	 00000000	MOVT R1 higher 16-bits var + 0
 000010FC	     6008	STR R0 [  R1 + 0 ]
 000010FE	 01000005	MOV R0 lower 16-bits base(1), next at  000010F4
 00001102	 0000000A	MOVT R0 higher 16-bits var(10)
 00001106	     6800	LDR R0 [ R0 + 0 ]
 00001108	     301C	ADDS R0 R0 #28
 0000110A	     6800	LDR R0 [ R0 + 0 ]
 0000110C	 10000007	MOV R1 lower 16-bits base(0), next at  000010FE
 00001110	 00000050	MOVT R1 higher 16-bits var + 80
 00001114	     6008	STR R0 [  R1 + 0 ]
 00001116	 F85DEB04	LDR LR [ SP ] + 4
 0000111A	     4770	BX LR
 0000111C	     B500	PUSH LR
 0000111E	 F7FFFFD5	BL #-86, goes to  000010CC
 00001122	 0000036C	MOV R0 lower 16-bits base(0), next at  00000A4A
 00001126	 00000018	MOVT R0 higher 16-bits const + 24
 0000112A	     2107	MOVS R1 #7
 0000112C	 20000010	MOV R2 lower 16-bits base(0), next at  0000110C
 00001130	 00000004	MOVT R2 higher 16-bits var + 4
 00001134	 F7FFF949	BL #-3438, goes to  000003CA
 00001138	 00000006	MOV R0 lower 16-bits base(0), next at  0000112C
 0000113C	 0000000C	MOVT R0 higher 16-bits var + 12
 00001140	     6800	LDR R0 [ R0 + 0 ]
 00001142	     DF01	SVC #1
 00001144	     E7FE	B #-4, goes to  00001144
 00001146	 F85DEB04	LDR LR [ SP ] + 4
 0000114A	     4770	BX LR
