MODULE OMSPTool;  (*NW 18.2.2013
  C. Schoffit  09.06.24*)
  IMPORT SYSTEM, Files, Texts, Oberon, B := OMSPB, A := OMSPA, D := OMSPD, Modules, TextsEx;

  TYPE
    ExternalRefMap = POINTER TO ExternalRefMapDesc;
    ExternalRefMapDesc = RECORD
      ext: ARRAY A.maxCode OF BYTE
    END;

  VAR W: Texts.Writer;
    Form: INTEGER;  (*result of ReadType*)

  PROCEDURE Read(VAR R: Files.Rider; VAR n: INTEGER);
    VAR b: BYTE;
  BEGIN Files.ReadByte(R, b);
    IF b < 80H THEN n := b ELSE n := b - 100H END
  END Read;

  PROCEDURE ReadWord(VAR R: Files.Rider; VAR n: INTEGER);
    VAR b1, b2: BYTE;
  BEGIN Files.ReadByte(R, b1); Files.ReadByte(R, b2);
    n := b1 + b2*100H
  END ReadWord;

(* On verra �a plus tard...
  PROCEDURE ReadType(VAR R: Files.Rider);
    VAR key, len, lev, size, off: INTEGER;
      ref, class, form, readonly: INTEGER;
      name, modname: ARRAY 32 OF CHAR;
  BEGIN Read(R, ref); Texts.Write(W, " "); Texts.Write(W, "[");
    IF ref < 0 THEN Texts.Write(W, "^"); Texts.WriteInt(W, -ref, 1)
    ELSE Texts.WriteInt(W, ref, 1);
      Read(R, form); Texts.WriteString(W, "  form = "); Texts.WriteInt(W, form, 1);
      IF form = OM4B.Pointer THEN ReadType(R)
      ELSIF form = OM4B.Array THEN
        ReadType(R); Files.ReadNum(R, len); Files.ReadNum(R, size);
        Texts.WriteString(W, "  len = "); Texts.WriteInt(W, len, 1);
        Texts.WriteString(W, "  size = "); Texts.WriteInt(W, size, 1)
      ELSIF form = OM4B.Record THEN
        ReadType(R);  (*base type*)
        Files.ReadNum(R, off); Texts.WriteString(W, "  exno = "); Texts.WriteInt(W, off, 1); 
        Files.ReadNum(R, off); Texts.WriteString(W, "  extlev = "); Texts.WriteInt(W, off, 1);
        Files.ReadNum(R, size); Texts.WriteString(W, "  size = "); Texts.WriteInt(W, size, 1);
        Texts.Write(W, " "); Texts.Write(W, "{"); Read(R, class);
        WHILE class # 0 DO (*fields*)
          Files.ReadString(R, name);
          IF name[0] # 0X THEN Texts.Write(W, " "); Texts.WriteString(W, name); ReadType(R)
          ELSE Texts.WriteString(W, " --")
          END ;
          Files.ReadNum(R, off); Texts.WriteInt(W, off, 4); Read(R, class)
        END ;
        Texts.Write(W, "}")
      ELSIF form = OM4B.Proc THEN
        ReadType(R); Texts.Write(W, "("); Read(R, class);
        WHILE class # 0 DO
          Texts.WriteString(W, " class = "); Texts.WriteInt(W, class, 1); Read(R, readonly);
          IF readonly = 1 THEN Texts.Write(W, "#") END ;
          ReadType(R); Read(R, class)
        END ;
        Texts.Write(W, ")")
      END ;
      Files.ReadString(R, modname);
      IF modname[0] # 0X THEN
        Files.ReadInt(R, key); Files.ReadString(R, name);
        Texts.Write(W, " "); Texts.WriteString(W, modname); Texts.Write(W, "."); Texts.WriteString(W, name);
        Texts.WriteHex(W, key)
      END
    END ;
    Form := form; Texts.Write(W, "]")
  END ReadType;

  PROCEDURE DecSym*;  (*decode symbol file*)
    VAR class, typno, k: INTEGER;
      name: ARRAY 32 OF CHAR;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "decode "); Texts.WriteString(W, S.s);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      F := Files.Old(S.s);
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadInt(R, k); Files.ReadInt(R, k);
        Files.ReadString(R, name); Texts.WriteString(W, name); Texts.WriteHex(W, k);
        Read(R, class); Texts.WriteInt(W, class, 3); (*sym file version*)
        IF class = OM4B.versionkey THEN
          Texts.WriteLn(W); Read(R, class);
          WHILE class # 0 DO
            Texts.WriteInt(W, class, 4); Files.ReadString(R, name); Texts.Write(W, " "); Texts.WriteString(W, name);
            ReadType(R);
            IF class = OM4B.Typ THEN
              Texts.Write(W, "("); Read(R, class);
              WHILE class # 0 DO  (*pointer base fixup*)
                Texts.WriteString(W, " ->"); Texts.WriteInt(W, class, 4); Read(R, class)
              END ;
              Texts.Write(W, ")")
            ELSIF (class = OM4B.Const) OR (class = OM4B.Var) THEN
              Files.ReadNum(R, k); Texts.WriteInt(W, k, 5);  (*Reals, Strings!*)
            END ;
            Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
            Read(R, class)
          END
        ELSE Texts.WriteString(W, " bad symfile version")
        END
      ELSE Texts.WriteString(W, " not found")
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END DecSym;
*)
(* ---------------------------------------------------*)

  PROCEDURE opcode(VAR c: ARRAY OF BYTE; VAR er: ExternalRefMap; VAR i: LONGINT; base: LONGINT);                  
    VAR b1, b2, ext, proc: BYTE;
      op: SET;
  BEGIN
    ext := er.ext[i];
    IF ext = 0 THEN
      D.opcode(W, c, i, base)
    ELSE (* on verra aussi �a plus tard
      b1 := c[i+1]; b2 := c[i]; INC(i, 2);
      IF ext = 1 THEN (*Get lower 16-bits of address of the object*)
        op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
        Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
        RdG := b1 DIV OM4A.C4; mno := b1 MOD OM4A.C4;
        OM4D.WriteOp(W, op, "MOV", FALSE, FALSE); OM4D.WriteReg(W, RdG); Texts.WriteString(W, " lower 16-bits base(");
        Texts.WriteInt(W, mno, 1); Texts.WriteString(W, ")")
      ELSIF ext = 2 THEN (*Get higher 16-bits of address of the object*)
        op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
        Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
        OM4D.WriteOp(W, op, "MOVT", FALSE, FALSE); OM4D.WriteReg(W, RdG);
        Texts.WriteString(W, " higher 16-bits ");
        IF mno = 0 THEN Texts.WriteString(W, "base + "); 
          Texts.WriteInt(W, 0+b4+100H*(b3+100H*b2), 1)
        ELSE Texts.WriteString(W, "var("); Texts.WriteInt(W, b4, 1);
          Texts.WriteString(W, ")");
          IF ODD(b3) THEN Texts.WriteString(W, " Prog based") END
        END
      ELSIF ext = 3 THEN (*BL Call external procedure*)
        op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
        Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
        mno := b1 DIV OM4A.C4; proc := b1 MOD OM4A.C4*OM4A.C4 + b2 DIV OM4A.C4;
        OM4D.WriteOp(W, op, "BL", FALSE, FALSE); Texts.WriteString(W, " Mod("); Texts.WriteInt(W, mno, 3);
        Texts.WriteString(W, ") proc("); Texts.WriteInt(W, proc, 1);
        Texts.WriteString(W, ")")
      ELSE Texts.WriteString(W, "TODO: External reference")
      END
*)
    END
  END opcode;

  PROCEDURE Sync(VAR R: Files.Rider);
    VAR ch: CHAR;
  BEGIN Files.Read(R, ch); Texts.WriteString(W, "Sync "); Texts.Write(W, ch); Texts.WriteLn(W)
  END Sync;
 
  PROCEDURE Write(VAR R: Files.Rider; x: INTEGER);
  BEGIN Files.WriteByte(R, x)  (* -128 <= x < 128 *)
  END Write;

  PROCEDURE fixup(msg: ARRAY OF CHAR; VAR R: Files.Rider);
    VAR data: INTEGER; mno: BYTE;
  BEGIN
    Texts.WriteString(W, "fixup "); Texts.WriteString(W, msg); Texts.WriteString(W, " chains"); Texts.WriteLn(W);
    ReadWord(R, data);
    WHILE data # 0 DO TextsEx.WriteHexVLen(W, data, 4, FALSE);
      Files.ReadByte(R, mno); Texts.WriteInt(W, mno, 6); Texts.Write(W, 9X);
      ReadWord(R, data); TextsEx.WriteHexVLen(W, data, 4, FALSE); Texts.WriteLn(W);
      ReadWord(R, data)
    END
  END fixup;

  PROCEDURE DecObj*;   (*decode object file*)
    VAR class, i, n, key, size, fix, adr, data: INTEGER;
      bl: BYTE;
      next: INTEGER;
      ch: CHAR;
      name: ARRAY 32 OF CHAR;
      F!: Files.File; R!: Files.Rider;
      S1!: Texts.Scanner;
      mcode!: A.ModuleCode;
      eref!: ExternalRefMap;
  BEGIN Texts.OpenScanner(S1, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S1);
    IF S1.class = Texts.Name THEN
      Texts.WriteString(W, "decode "); Texts.WriteString(W, S1.s); F := Files.Old(S1.s);
      IF F # NIL THEN
        NEW(mcode); NEW(eref);
        Files.Set(R, F, 0); Files.ReadString(R, name); Texts.WriteLn(W); Texts.WriteString(W, name);
        Files.ReadInt(R, key); Texts.WriteHex(W, key);
        ReadWord(R, size); Texts.WriteInt(W, size, 6); Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf); ASSERT(size < 100000);
        Texts.WriteString(W, "imports:"); Texts.WriteLn(W); Files.ReadString(R, name);
        WHILE name[0] # 0X DO
          Texts.Write(W, 9X); Texts.WriteString(W, name);
          Files.ReadInt(R, key); Texts.WriteHex(W, key); Texts.WriteLn(W);
          Files.ReadString(R, name)
        END ;
      (* Sync(R); *)
        Texts.WriteString(W, "type descriptors"); Texts.WriteLn(W);
        ReadWord(R, n); n := n DIV 2; i := 0;
        WHILE i < n DO ReadWord(R, data); TextsEx.WriteHexVLen(W, data, 4, FALSE); INC(i) END;
        Texts.WriteLn(W);
        Texts.WriteString(W, "data"); ReadWord(R, data); Texts.WriteInt(W, data, 6); Texts.WriteLn(W);
        Texts.WriteString(W, "strings"); Texts.WriteLn(W);
        ReadWord(R, n); i := 0;
        WHILE i < n DO Files.Read(R, ch); IF ch=0X THEN ch := "|" END; Texts.Write(W, ch); INC(i) END ;
        Texts.WriteLn(W);
        (*code*)
        ReadWord(R, mcode.pc); i := 0;
        WHILE i < mcode.pc DO Files.ReadByte(R, mcode.code[i]); eref.ext[i] := 0; INC(i) END;
       (* Sync(R); *)
        Texts.WriteString(W, "vector table"); Texts.WriteLn(W);
        Files.ReadByte(R, bl); i := 0;
        WHILE i < bl DO ReadWord(R, data); TextsEx.WriteHexVLen(W, data, 4, FALSE); INC(i);
          IF i MOD 16 = 0 THEN Texts.WriteLn(W) END
        END;
        Texts.WriteLn(W);
        Texts.WriteString(W, "commands:"); Texts.WriteLn(W);
        Files.ReadString(R, name);
        WHILE name[0] # 0X DO
          Texts.Write(W, 9X); Texts.WriteString(W, name);
          ReadWord(R, adr); TextsEx.WriteHexVLen(W, adr, 4, FALSE); Texts.WriteLn(W);
          Files.ReadString(R, name)
        END;
      (* Sync(R); *)
        Texts.WriteString(W, "entries"); Texts.WriteLn(W);
        ReadWord(R, n); i := 0;
        WHILE i < n DO
          ReadWord(R, adr); TextsEx.WriteHexVLen(W, adr, 4, FALSE); INC(i)
        END ;
        Texts.WriteLn(W);
      (* Sync(R); *)
        Texts.WriteString(W, "pointer refs"); Texts.WriteLn(W); ReadWord(R, adr);
        WHILE adr # 0FFFFH DO TextsEx.WriteHexVLen(W, adr, 4, FALSE); ReadWord(R, adr); Texts.Append(Oberon.Log, W.buf) END ;
        Texts.WriteLn(W);
      (* Sync(R); *)
      fixup("procedures", R);
      fixup("handlers", R);
      fixup("data", R);
      fixup("type", R);
(* on verra �a plus tard
        WHILE data # 0 DO eref.ext[data] := 3;
          next := data-(mcode.code[data+2] + 100H*(mcode.code[data+3] + 100H*(mcode.code[data] MOD OM4A.C4)))*OM4A.C1;
          data := next
        END;
        Files.ReadInt(R, data); Texts.WriteString(W, "fixD = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        WHILE data # 0 DO eref.ext[data] := 1; eref.ext[data+4] := 2;
          next := data-(mcode.code[data+2] + 100H*(mcode.code[data+3] + 100H*mcode.code[data]))*OM4A.C1;
          data := next
        END;
        Files.ReadInt(R, data); Texts.WriteString(W, "fixT = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
*)
        ReadWord(R, data); Texts.WriteString(W, "entry = "); TextsEx.WriteHexVLen(W, data, 4, FALSE); Texts.WriteLn(W);
        Files.Read(R, ch);
        IF ch # "O" THEN Texts.WriteString(W, "format error"); Texts.WriteLn(W) END;
      (* Sync(R); *)
        Texts.WriteString(W, "code");  Texts.WriteInt(W, mcode.pc, 6); Texts.WriteLn(W); 
        i := 0;
        WHILE i < mcode.pc DO
          TextsEx.WriteHexVLen(W, i, 4, FALSE); Texts.Write(W, 9X); adr := i + 2;
          opcode(mcode.code, eref, i, 0); Texts.WriteLn(W);
          FOR n := adr TO i - 2 BY 2 DO (*print operation data*)
            TextsEx.WriteHexVLen(W, n, 4, FALSE); Texts.Write(W, 9X); Texts.WriteString(W, "    ");
            data := mcode.code[n+1]*100H + mcode.code[n];
            TextsEx.WriteHexVLen(W, data, 4, FALSE); Texts.WriteLn(W)
          END
        END
      ELSE Texts.WriteString(W, " not found"); Texts.WriteLn(W)
      END ;
      Texts.Append(Oberon.Log, W.buf)
    END
  END DecObj;

  PROCEDURE EmitByte(VAR W:Texts.Writer; v: BYTE; VAR p: INTEGER; base: INTEGER;
    msg: ARRAY OF CHAR);
  BEGIN
    Texts.WriteHex(W, p+base); Texts.Write(W, 9X); 
    Texts.WriteString(W, "    .byte "); Texts.WriteInt(W, v, 1);
    Texts.WriteString(W, "; "); Texts.WriteString(W, msg);
    Texts.WriteLn(W); INC(p);
  END EmitByte;
  
  PROCEDURE EmitWord(VAR W:Texts.Writer; v: INTEGER; VAR p: INTEGER; base: INTEGER;
    msg: ARRAY OF CHAR);
  BEGIN
    Texts.WriteHex(W, p+base); Texts.Write(W, 9X); 
    Texts.WriteString(W, "    .word "); Texts.WriteHex(W, v);
    Texts.WriteString(W, "H; "); Texts.WriteString(W, msg);
    Texts.WriteLn(W); INC(p, 4);
  END EmitWord;
 
  PROCEDURE EmitString(VAR W:Texts.Writer; s: ARRAY OF CHAR; l: INTEGER; VAR p: INTEGER;
     base: INTEGER; msg: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    Texts.WriteHex(W, p+base); Texts.Write(W, 9X); 
    Texts.WriteString(W, "    .ascii "); Texts.Write(W, 22X); Texts.WriteString(W, s); Texts.Write(W, 22X);
    Texts.WriteLn(W); i := 0; WHILE s[i] # 0X DO INC(i) END;
    Texts.WriteString(W, "        .fill "); Texts.WriteInt(W, l-i, 1); Texts.WriteString(W, ", 1, 0"); 
    Texts.WriteString(W, "; "); Texts.WriteString(W, msg);
    Texts.WriteLn(W); INC(p, l)
  END EmitString;

(*On verra �a plus tard  
  PROCEDURE DecBin*;   (*decode binary boot file*)
    VAR i, n, modLoc, root, ramOrg, data: INTEGER;
      F!: Files.File; R!: Files.Rider;
      S!: Texts.Scanner;
      bpb: ARRAY SYSTEM.SIZE(Modules.ModDesc) DIV 4 OF INTEGER; bp!: BootParams;
      mcode!: OM4A.ModuleCode;
      mod!: Modules.Module;
      ok: BOOLEAN;
      ch: CHAR;
      name: ARRAY 32 OF CHAR;
  BEGIN ok := TRUE; Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "decode "); Texts.WriteString(W, S.s); Texts.WriteLn(W);
      F := Files.Old(S.s);
      IF F # NIL THEN
        NEW(mcode);
        Files.Set(R, F, 0); 
        FOR i := 0 TO SYSTEM.SIZE(BootParamsList) DIV 4 - 1 DO Files.ReadInt(R, bpb[i]) END;
        bp := SYSTEM.VAL(BootParams, SYSTEM.ADR(bpb)); 
        ramOrg := bp.BootfileLoadAOrg; root := bp.RootModule;
        n := 0; Texts.WriteHex(W, n+ramOrg); Texts.Write(W, 9X);
        OM4D.opcode(W, bp.BranchToRootInit, n, ramOrg); Texts.WriteLn(W);
        EmitWord(W, bp.unused, n, ramOrg, "unused"); EmitWord(W, bp.BootfileLoadAOrg, n, ramOrg, "RAM origin");
        EmitWord(W, bp.MemLim, n, ramOrg, "RAM end"); EmitWord(W, bp.BootfileLoadEnd, n, ramOrg, "Boot file load end");
        EmitWord(W, bp.RootModule, n, ramOrg, "Root module descriptor"); EmitWord(W, bp.StackOrg, n, ramOrg, "Stack origin"); 
        EmitWord(W, bp.HeapOrg, n, ramOrg, "Heap origin");
        REPEAT (* Decode module information *)
          modLoc := n;
          FOR i := 0 TO SYSTEM.SIZE(Modules.ModDesc) DIV 4 - 1 DO Files.ReadInt(R, bpb[i]) END;
          mod := SYSTEM.VAL(Modules.Module, SYSTEM.ADR(bpb));
          EmitString(W, mod.name, SYSTEM.SIZE(Modules.ModuleName), n, ramOrg, "Module name");
          EmitWord(W, ORD(mod.next), n, ramOrg, "Next module descriptor location");
          EmitWord(W, mod.key, n, ramOrg, "Key");
          EmitWord(W, mod.num, n, ramOrg, "Num");
          EmitWord(W, mod.size, n, ramOrg, "Size");
          EmitWord(W, mod.refcnt, n, ramOrg, "References count");
          EmitWord(W, mod.data, n, ramOrg, "Data section");
          EmitWord(W, mod.code, n, ramOrg, "Code section");
          EmitWord(W, mod.imp, n, ramOrg, "Import section");
          EmitWord(W, mod.cmd, n, ramOrg, "Commands section");
          EmitWord(W, mod.ent, n, ramOrg, "Entries section");
          EmitWord(W, mod.ptr, n, ramOrg, "Pointer section");
          INC(n, 4); (*unused*)

          IF ok & (n+ramOrg = mod.data) THEN  Texts.WriteString(W, "; data section found"); Texts.WriteLn(W)
          ELSE
            ok := FALSE;
            Texts.WriteString(W, "format error, at "); Texts.WriteHex(W, n+ramOrg); 
            Texts.WriteLn(W)
          END;
          IF ok THEN
            i := 0;
            WHILE (n - modLoc < mod.size) & (n+ramOrg # mod.code) DO 
              Files.ReadInt(R, data);
              IF data # 0 THEN
                IF i # 0 THEN Texts.WriteHex(W, ramOrg+n-4*i); Texts.Write(W, 9X);
                  Texts.WriteString(W, "    .fill "); Texts.WriteInt(W, i, 1);
                  Texts.WriteString(W, ", 4, 0"); Texts.WriteLn(W); i := 0;
                END;
                EmitWord(W, data, n, ramOrg, "")
              ELSE i := i+1; INC(n, 4)
              END
            END;
            IF i # 0 THEN Texts.WriteHex(W, ramOrg+n-4*i); Texts.Write(W, 9X);
              Texts.WriteString(W, "    .fill "); Texts.WriteInt(W, i, 1);
              Texts.WriteString(W, ", 4, 0"); Texts.WriteLn(W)
            END;
          END;
          IF ok & (n+ramOrg = mod.code) THEN Texts.WriteString(W, "; code section found"); Texts.WriteLn(W)
          ELSE
            ok := FALSE;
            Texts.WriteString(W, "format error, at "); Texts.WriteHex(W, n+ramOrg); 
            Texts.WriteLn(W)
          END;
          IF ok THEN
            mcode.pc := 0;
            WHILE (n - modLoc < mod.size) & (n+ramOrg # mod.imp) DO 
              Files.ReadByte(R, mcode.code[mcode.pc]); INC(mcode.pc); INC(n)
            END;
            i := 0; 
            WHILE i < mcode.pc DO 
              Texts.WriteHex(W, mod.code + i); Texts.Write(W, 9X); OM4D.opcode(W, mcode.code, i, mod.code);
              Texts.WriteLn(W)
            END
          END;
          IF ok & (n+ramOrg = mod.imp) THEN Texts.WriteString(W, "; import section found"); Texts.WriteLn(W)
          ELSE
            ok := FALSE;
            Texts.WriteString(W, "format error, at "); Texts.WriteHex(W, n+ramOrg); 
            Texts.WriteLn(W)
          END;
          IF ok THEN
            WHILE (n - modLoc < mod.size) & (n+ramOrg # mod.cmd) DO 
              Files.ReadInt(R, data);
              EmitWord(W, data, n, ramOrg, "");
            END
          END;
          IF ok & (n+ramOrg = mod.cmd) THEN Texts.WriteString(W, "; commands section found"); Texts.WriteLn(W)
          ELSE
            ok := FALSE;
            Texts.WriteString(W, "format error, at "); Texts.WriteHex(W, n+ramOrg); 
            Texts.WriteLn(W)
          END;
          IF ok THEN
            Files.Read(R, ch);
            WHILE (n - modLoc < mod.size) & (ch # 0X) DO
              name[0] := ch; i := 1; REPEAT Files.Read(R, ch); name[i] := ch; INC(i) UNTIL ch = 0X;
              WHILE i MOD 4 # 0 DO Files.Read(R, ch); INC(i) END;
              EmitString(W, name, i, n, ramOrg, "Name");
              Files.ReadInt(R, data);
              EmitWord(W, data, n, ramOrg, "Address");
              Files.Read(R, ch);
            END;
            EmitByte(W, ORD(ch), n, ramOrg, "Padding");
            REPEAT Files.Read(R, ch); EmitByte(W, ORD(ch), n, ramOrg, "Padding") UNTIL n MOD 4 = 0;
          END;
          IF ok & (n+ramOrg = mod.ent) THEN Texts.WriteString(W, "; entries section found"); Texts.WriteLn(W)
          ELSE
            ok := FALSE;
            Texts.WriteString(W, "format error, at "); Texts.WriteHex(W, n+ramOrg); 
            Texts.WriteLn(W)
          END;
          IF ok THEN
            WHILE (n - modLoc < mod.size) & (n+ramOrg # mod.ptr) DO 
              Files.ReadInt(R, data);
              EmitWord(W, data, n, ramOrg, "");
            END
          END;
          IF ok & (n+ramOrg = mod.ptr) THEN Texts.WriteString(W, "; pointers section found"); Texts.WriteLn(W)
          ELSE
            ok := FALSE;
            Texts.WriteString(W, "format error, at "); Texts.WriteHex(W, n+ramOrg); 
            Texts.WriteLn(W)
          END;
          IF ok THEN
            REPEAT
              Files.ReadInt(R, data);
              EmitWord(W, data, n, ramOrg, "");
            UNTIL (data = 0) OR (n - modLoc >= mod.size);
          END;
          IF data = 0 THEN
            IF n - modLoc < mod.size THEN Texts.WriteString(W, "; trampoline section found"); Texts.WriteLn(W);
              WHILE n - modLoc < mod.size DO Files.ReadInt(R, data); EmitWord(W, data, n, ramOrg, "") END
            END
          ELSE
            ok := FALSE;
            Texts.WriteString(W, "format error, at "); Texts.WriteHex(W, n+ramOrg); 
            Texts.WriteLn(W)
          END
        UNTIL ~ok OR (modLoc + ramOrg = root)
      ELSE Texts.WriteString(W, " not found"); Texts.WriteLn(W)
      END;
      Texts.Append(Oberon.Log, W.buf)
    END
  END DecBin;
*)
BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OMSPTool 10.06.24");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END OMSPTool.
