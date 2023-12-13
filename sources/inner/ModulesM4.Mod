MODULE Modules;  (*Link and load on RISC; NW 20.10.2013 / 8.1.2019
  CS 12/12/2023*)
  IMPORT SYSTEM, Files;
  CONST versionkey = 1X; DescSize = 80;

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
  
  TYPE Module* = POINTER TO ModDesc;
    Command* = PROCEDURE;
    ModuleName* = ARRAY 32 OF CHAR;

    ModDesc* = RECORD
        name*: ModuleName;
        next*: Module;
        key*, num*, size*, refcnt*: INTEGER;
        data*, code*, imp*, cmd*, ent*, ptr*, unused: INTEGER  (*addresses*)
      END ;

  VAR root*, M: Module;
    AllocPtr*, res*: INTEGER;
    importing*, imported*: ModuleName;
    limit: INTEGER;

  PROCEDURE formatEvenImm25*(disp: LONGINT): LONGINT;
  (* |00000S   imm10  00J0J   imm11   |
     |                  1 2
     I1 = NOT(J1 EOR S); I2 = NOT(J2 EOR S); imm32 = SignExtend(S:I1:I2:imm10:imm11:'0', 32);
  *) 
  VAR res: LONGINT;
    S, J1, J2: BYTE;
    imm10, imm11: LONGINT;
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
  
  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR i: INTEGER;
      filename: ModuleName;
  BEGIN i := 0;
    WHILE name[i] # 0X DO filename[i] := name[i]; INC(i) END ;
    filename[i] := "."; filename[i+1] := "r"; filename[i+2] := "s"; filename[i+3] := "c"; filename[i+4] := 0X;
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

  PROCEDURE Load*(name: ARRAY OF CHAR; VAR newmod: Module);
    (*search module in list; if not found, load module.
      res = 0: already present or loaded; res = 2: file not available; res = 3: key conflict;
      res = 4: bad file version; res = 5: corrupted file; res = 7: no space*)
    VAR mod, impmod: Module;
      i, n, key, impkey, mno, nofimps, size: INTEGER;
      p, u, v, w: INTEGER;  (*addresses*)
      b: BYTE;
      ch: CHAR;
      body: Command;
      fixorgP, fixorgD, fixorgT: INTEGER;
      disp, adr, inst, pno, vno, dest, offset, trpbase, noftrps: INTEGER;
      name1, impname: ModuleName;
      F: Files.File; R: Files.Rider;
      import: ARRAY 16 OF Module;
  BEGIN mod := root; error(0, name); nofimps := 0;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*load*)
      Check(name);
      IF res = 0 THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.Read(R, ch);
        Files.ReadInt(R, size); importing := name1;
        IF ch = versionkey THEN
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
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.data + w); INC(p, 4); Files.ReadInt(R, w) END ;
        SYSTEM.PUT(p, 0); INC(p, 4);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgD); Files.ReadInt(R, fixorgT);
        Files.ReadInt(R, w); body := SYSTEM.VAL(Command, mod.code + w);
        Files.Read(R, ch);
        IF ch # "O" THEN (*corrupted file*)  mod := NIL; error(4, name) END
      END ;
      IF res = 0 THEN (*fixup of BL*)
        noftrps := 0; trpbase := p; (*trampoline area*)
        adr := mod.code + fixorgP;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
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
          SYSTEM.PUT(adr, BL + formatEvenImm25(offset));
          adr := adr - disp
        END ;
        INC(p, noftrps*8);
        (*fixup of LDR/STR/ADD*)
      (* TODO J'en suis là, le fixup fixorgD est à modifier *)

        adr := mod.code + fixorgD*4;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV 100000H MOD 10H;
          disp := inst MOD 1000H;
          IF mno = 0 THEN (*global*)
            SYSTEM.PUT(adr, (inst DIV 1000000H * 10H + MT) * 100000H + mod.num * 4)
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod); v := impmod.num;
            SYSTEM.PUT(adr, (inst DIV 1000000H * 10H + MT) * 100000H + v*4);
            SYSTEM.GET(adr+4, inst); vno := inst MOD 100H;
            SYSTEM.GET(impmod.ent + vno*4, offset);
            IF ODD(inst DIV 100H) THEN offset := offset + impmod.code - impmod.data END ;
            SYSTEM.PUT(adr+4, inst DIV 10000H * 10000H + offset)
          END ;
          adr := adr - disp*4
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
        body   (*initialize module*)
      ELSIF res >= 3 THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); DEC(import[nofimps].refcnt) END
      END 
    END ;
    newmod :=  mod
  END Load;

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
        IF s = name THEN res := 0; w := mod.code + k ELSE SYSTEM.GET(adr, ch) END
      END
    END
    RETURN SYSTEM.VAL(Command, w)
  END ThisCommand;

  PROCEDURE Free*(name: ARRAY OF CHAR);
    VAR mod, imp: Module; p, q: INTEGER;
  BEGIN mod := root; res := 0;
    WHILE (mod # NIL) & (mod.name # name) DO mod := mod.next END ;
    IF mod # NIL THEN
      IF mod.refcnt = 0 THEN
        mod.name[0] := 0X; p := mod.imp; q := mod.cmd;
        WHILE p < q DO SYSTEM.GET(p, imp); DEC(imp.refcnt); INC(p, 4) END ;
      ELSE res := 1
      END
    END
  END Free;

  PROCEDURE Init*;
  BEGIN Files.Init; MTOrg := SYSTEM.REG(MT);
    SYSTEM.GET(16, AllocPtr); SYSTEM.GET(20, root); 
    (*TODO : à reprendre : SYSTEM.GET(24, limit); DEC(limit, 8000H) *)
    (*avec quelque chose du genre : *) SYSTEM.GET(12, limit); DEC(limit, 300000H);
    (*pour laisser 3 Mo de mémoire pour le tas*)
  END Init;

BEGIN Init; Load("Oberon", M);
    LED(res); REPEAT UNTIL FALSE  (*only if load fails*)
END Modules.
