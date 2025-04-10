MODULE OMSPB;   (*NW 25.6.2014  / AP 4.3.2020 / 8.3.2019  in Oberon-07
  C. Schoffit 19.05.2 for Texas Instruments MSP430 Family*)
  IMPORT Files, CRC32, S := OMSPS;
  (*Definition of data types Object and Type, which together form the data structure
    called "symbol table". Contains procedures for creation of Objects, and for search:
    NewObj, this, thisimport, thisfield (and OpenScope, CloseScope).
    Handling of import and export, i.e. reading and writing of "symbol files" is done by procedures
    Import and Export. This module contains the list of standard identifiers, with which
    the symbol table (universe), and that of the pseudo-module SYSTEM are initialized. *)

  CONST versionkey* = 1; maxTypTab = 64;
    (* class values*) Head* = 0;
      Const* = 1; Var* = 2; Par* = 3; Fld* = 4; Typ* = 5;
      SProc* = 6; SFunc* = 7; Mod* = 8; StoredConst* = 9;

    (* form values*)
      Byte* = 1; Bool* = 2; Char* = 3; Int* = 4; Set* = 6;
      Pointer* = 7; NilTyp* = 8; NoTyp* = 9; Proc* = 10;
      String* = 11; Array* = 12; Record* = 13; PointerToByte* = 14; Handler* = 15;
      ByteSet* = 16; PointerToSet* = 17; PointerToByteSet* = 18;
      LastForm = PointerToByteSet;
      
  TYPE Object* = POINTER TO ObjDesc;
    Module* = POINTER TO ModDesc;
    Type* = POINTER TO TypeDesc;

    ObjDesc*= RECORD
      class*, exno*, register*: BYTE; (*register = 0FFH if memory allocation, else contains the register number*)
      expo*, unsafe*, rdo*: BOOLEAN;   (*exported / unsafe / read-only*)
      lev*, usedat*: INTEGER;
      next*, dsc*: Object;
      type*: Type;
      name*: S.Ident;
      val*: INTEGER
    END ;

    ModDesc* = RECORD (ObjDesc) orgname*: S.Ident END ;

    TypeDesc* = RECORD
      form*, ref*, mno*: INTEGER;  (*ref is only used for import/export*)
      nofpar*: INTEGER;  (*for procedures, extension level for records*)
      len*: INTEGER;  (*for arrays, len < 0 => open array; for records: adr of descriptor*)
      dsc*, typobj*: Object;
      base*: Type;  (*for arrays, records, pointers*)
      size*: INTEGER;  (*in bytes; always multiple of 2, except for Byte, Bool and Char*)
      leaf*: BOOLEAN; ur*: SET (*leafness of procedures, set of registers used by the procedure*)
    END ;

  (* Object classes and the meaning of "val":
    class    val
    ----------
    Var      address
    Par      address
    Const    value or lenth/address for strings
    Fld      offset
    Typ      type descriptor (TD) address
    SProc    inline code number
    SFunc    inline code number
    Mod      key

  Type forms and the meaning of "dsc" and "base":
    form     dsc      base
    ------------------------
    Pointer  -        type of dereferenced object
    Proc     params   result type
    Array    -        type of elements
    Record   fields   extension *)

    RegRTProcCallback* = PROCEDURE(p: Object);

  VAR topScope*, universe, system*: Object;
    byteType*, boolType*, charType*, byteSetType*: Type;
    intType*, setType*, nilType*, noType*, strType*: Type;
    ptrByteType*, ptrIntType*, ptrByteSetType*,ptrSetType*: Type;
    nofmod, Ref: INTEGER;
    typtab: ARRAY maxTypTab OF Type;
    regRTProc: RegRTProcCallback;

  PROCEDURE SetRegRTProcCallback*(p: RegRTProcCallback);
  BEGIN regRTProc := p
  END SetRegRTProcCallback;

  PROCEDURE NewObj*(VAR obj: Object; id: S.Ident; class: INTEGER);  (*insert new Object with name id*)
    VAR new!, x!: Object;
  BEGIN x := topScope;
    WHILE (x.next # NIL) & (x.next.name # id) DO x := x.next END ;
    IF x.next = NIL THEN
      NEW(new); new.name := id; new.class := class; new.next := NIL; new.rdo := FALSE; new.usedat := 0; new.register := 0FFH; new.dsc := NIL;
      x.next := new; obj := new
    ELSE obj := x.next; S.Mark("mult def")
    END 
  END NewObj;

  PROCEDURE thisObj*(): Object;
    VAR s!, x!: Object;
  BEGIN s := topScope;
    REPEAT x := s.next;
      WHILE (x # NIL) & (x.name # S.id) DO x := x.next END ;
      s := s.dsc
    UNTIL (x # NIL) OR (s = NIL);
    RETURN x
  END thisObj;

  PROCEDURE thisimport*(mod: Object): Object;
    VAR obj!: Object;
  BEGIN
    IF mod.rdo THEN
      IF mod.name[0] # 0X THEN
        obj := mod.dsc;
        WHILE (obj # NIL) & (obj.name # S.id) DO obj := obj.next END
      ELSE obj := NIL
      END
    ELSE obj := NIL
    END ;
    RETURN obj
  END thisimport;

  PROCEDURE thisfield*(rec: Type): Object;
    VAR fld!: Object;
  BEGIN fld := rec.dsc;
    WHILE (fld # NIL) & (fld.name # S.id) DO fld := fld.next END ;
    RETURN fld
  END thisfield;

  PROCEDURE OpenScope*;
    VAR s!: Object;
  BEGIN NEW(s); s.class := Head; s.dsc := topScope; s.next := NIL; topScope := s
  END OpenScope;

  PROCEDURE CloseScope*;
  BEGIN topScope := topScope.dsc
  END CloseScope;

  (*------------------------------- Import ---------------------------------*)

  PROCEDURE MakeFileName*(VAR FName: S.Ident; name, ext: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN i := 0; j := 0;  (*assume name suffix less than 4 characters*)
    WHILE (i < S.IdLen-5) & (name[i] > 0X) DO FName[i] := name[i]; INC(i) END ;
    REPEAT FName[i]:= ext[j]; INC(i); INC(j) UNTIL ext[j] = 0X;
    FName[i] := 0X
  END MakeFileName;
  
  PROCEDURE ThisModule(name, orgname: S.Ident; decl: BOOLEAN; key: INTEGER): Object;
    VAR mod!: Module; obj!, obj1!: Object;
  BEGIN obj1 := topScope; obj := obj1.next;  (*search for module*)
    WHILE (obj # NIL) & (obj(Module).orgname # orgname) DO obj1 := obj; obj := obj1.next END ;
    IF obj = NIL THEN  (*new module, search for alias*)
      obj := topScope.next;
      WHILE (obj # NIL) & (obj.name # name) DO obj := obj.next END ;
      IF obj = NIL THEN (*insert new module*)
        NEW(mod); mod.class := Mod; mod.rdo := FALSE;
        mod.name := name; mod.orgname := orgname; mod.val := key;
        mod.lev := nofmod; INC(nofmod); mod.dsc := NIL; mod.next := NIL;
        IF decl THEN mod.type := noType ELSE mod.type := nilType END ;
        obj1.next := mod; obj := mod
      ELSIF decl THEN
        IF obj.type.form = NoTyp THEN S.Mark("mult def") ELSE S.Mark("invalid import order") END
      ELSE S.Mark("conflict with alias")
      END
    ELSIF decl THEN (*module already present, explicit import by declaration*)
      IF  obj.type.form = NoTyp THEN S.Mark("mult def") ELSE S.Mark("invalid import order") END
    END ;
    RETURN obj
  END ThisModule;

  PROCEDURE Read(VAR R: Files.Rider; VAR x: INTEGER);
    VAR b: BYTE;
  BEGIN Files.ReadByte(R, b);
    IF b < 80H THEN x := b ELSE x := b - 100H END
  END Read;
  
  PROCEDURE InType(VAR R: Files.Rider; thismod: Object; VAR T: Type);
    VAR key: INTEGER;
      ref, class, form, np, tmp: INTEGER;
      fld!, par!, obj!, mod!, last!: Object;
      t!: Type;
      name, modname: S.Ident;
  BEGIN Read(R, ref);
    IF ref < 0 THEN T := typtab[-ref]  (*already read*)
    ELSE NEW(t); T := t; typtab[ref] := t; t.mno := thismod.lev;
      Read(R, form); t.form := form; Files.ReadNum(R, t.size);
      IF form = Pointer THEN InType(R, thismod, t.base);
      ELSIF form = Array THEN InType(R, thismod, t.base); Files.ReadNum(R, t.len)
      ELSIF form = Record THEN
        InType(R, thismod, t.base);
        IF t.base.form = NoTyp THEN t.base := NIL; obj := NIL ELSE obj := t.base.dsc END ;
        Files.ReadNum(R, t.len); (*TD adr/exno*)
        Files.ReadNum(R, t.nofpar);  (*ext level*)
        Read(R, class); last := NIL;
        WHILE class # 0 DO  (*fields*)
          NEW(fld); fld.class := class; Files.ReadString(R, fld.name);
          IF last = NIL THEN t.dsc := fld ELSE last.next := fld END ;
          last := fld;
          IF fld.name[0] # 0X THEN fld.expo := TRUE; InType(R, thismod, fld.type) ELSE fld.expo := FALSE; fld.type := nilType END ;
          Files.ReadNum(R, fld.val); Read(R, class)
        END ;
        IF last = NIL THEN t.dsc := obj ELSE last.next := obj END
      ELSIF form = Proc THEN
        InType(R, thismod, t.base); Read(R, tmp); t.leaf := tmp = 1; Files.ReadSet(R, t.ur);
        obj := NIL; np := 0; Read(R, class);
        WHILE class # 0 DO  (*parameters*)
          NEW(par); par.class := class; Read(R, tmp); par.rdo := tmp = 1; Files.ReadByte(R, par.register);
          InType(R, thismod, par.type); par.next := obj; obj := par; INC(np); Read(R, class)
        END ;
        t.dsc := obj; t.nofpar := np
      END ;
      Files.ReadString(R, modname);
      IF modname[0] #  0X THEN  (*re-import ========*)
        Files.ReadInt(R, key); Files.ReadString(R, name);
        mod := ThisModule(modname, modname, FALSE, key);
        obj := mod.dsc;  (*search type*)
        WHILE (obj # NIL) & (obj.name # name) DO obj := obj.next END ;
        IF obj # NIL THEN T := obj.type   (*type object found in object list of mod*)
        ELSE (*insert new type object in object list of mod*)
          NEW(obj); obj.name := name; obj.class := Typ; obj.next := mod.dsc; mod.dsc := obj; obj.type := t; obj.usedat := 0;
          t.mno := mod.lev; t.typobj := obj; T := t
        END ;
        typtab[ref] := T
      END
    END
  END InType;
  
  PROCEDURE Import*(VAR modid, modid1: S.Ident);
    VAR key, class, k: INTEGER;
      obj!: Object;  t!: Type;
      thismod!: Object;
      modname, fname: S.Ident;
      F!: Files.File; R!: Files.Rider;
  BEGIN
    IF modid1 = "SYSTEM" THEN
      thismod := ThisModule(modid, modid1, TRUE, 0); DEC(nofmod);
      thismod.lev := 0; thismod.dsc := system; thismod.rdo := TRUE
    ELSE MakeFileName(fname, modid1, ".sms"); F := Files.Old(fname);
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadInt(R, key); Files.ReadInt(R, key); Files.ReadString(R, modname);
        thismod := ThisModule(modid, modid1, TRUE, key); thismod.rdo := TRUE;
        Read(R, class); (*version key*)
        IF class # versionkey THEN S.Mark("wrong version") END ;
        Read(R, class);
        WHILE class # 0 DO
          NEW(obj); obj.class := class; obj.usedat := 0; Files.ReadString(R, obj.name);
          InType(R, thismod, obj.type); obj.lev := -thismod.lev;
          IF class = Typ THEN
            t := obj.type; t.typobj := obj; Read(R, k);  (*fixup bases of previously declared pointer types*)
            WHILE k # 0 DO typtab[k].base := t; Read(R, k) END
          ELSE
            IF class = Const THEN IF obj.type.form = String THEN Files.ReadInt(R, obj.val) ELSE Files.ReadNum(R, obj.val) END;
              IF obj.type.form = Proc THEN regRTProc(obj) END
            ELSIF class IN {Var, StoredConst} THEN Files.ReadNum(R, obj.val); obj.rdo := TRUE; obj.usedat := 0; obj.register := 0FFH
            END
          END ;
          obj.next := thismod.dsc; thismod.dsc := obj; Read(R, class)
        END ;
      ELSE S.Mark("import not available")
      END
    END
  END Import;

  (*-------------------------------- Export ---------------------------------*)

  PROCEDURE Write(VAR R: Files.Rider; x: INTEGER);
  BEGIN Files.WriteByte(R, x)
  END Write;

  PROCEDURE OutType(VAR R: Files.Rider; t: Type);
    VAR obj!, mod!, fld!, bot!: Object;

    PROCEDURE OutPar(VAR R: Files.Rider; par: Object; n: INTEGER);
    BEGIN
      IF n > 0 THEN
        OutPar(R, par.next, n-1);
        Write(R, par.class);
        IF par.rdo THEN Write(R, 1) ELSE Write(R, 0) END;
        Write(R, par.register);
        OutType(R, par.type)
      END
    END OutPar;

    PROCEDURE FindHiddenPointers(VAR R: Files.Rider; typ: Type; offset: INTEGER);
      VAR fld!: Object; i, n: INTEGER;
    BEGIN
      IF (typ.form = Pointer) OR (typ.form = NilTyp) THEN Write(R, Fld); Write(R, 0); Files.WriteNum(R, offset)
      ELSIF typ.form = Record THEN fld := typ.dsc;
        WHILE fld # NIL DO FindHiddenPointers(R, fld.type, fld.val + offset); fld := fld.next END
      ELSIF typ.form = Array THEN i := 0; n := typ.len;
        WHILE i < n DO FindHiddenPointers(R, typ.base, typ.base.size * i + offset); INC(i) END
      END
    END FindHiddenPointers;

  BEGIN
    IF t.ref > 0 THEN (*type was already output*) Write(R, -t.ref)
    ELSE obj := t.typobj;
      IF obj # NIL THEN Write(R, Ref); t.ref := Ref; INC(Ref) ELSE (*anonymous*) Write(R, 0) END ;
      Write(R, t.form); Files.WriteNum(R, t.size);
      IF t.form = Pointer THEN OutType(R, t.base)
      ELSIF t.form = Array THEN OutType(R, t.base); Files.WriteNum(R, t.len)
      ELSIF t.form = Record THEN
        IF t.base # NIL THEN OutType(R, t.base); bot := t.base.dsc ELSE OutType(R, noType); bot := NIL END ;
        IF obj # NIL THEN Files.WriteNum(R, obj.exno) ELSE Write(R, 0) END ;
        Files.WriteNum(R, t.nofpar);
        fld := t.dsc;
        WHILE fld # bot DO  (*fields*)
          IF fld.expo THEN
            Write(R, Fld); Files.WriteString(R, fld.name); OutType(R, fld.type); Files.WriteNum(R, fld.val)  (*offset*)
          ELSE FindHiddenPointers(R, fld.type, fld.val)
          END ;
          fld := fld.next
        END ;
        Write(R, 0)
      ELSIF t.form = Proc THEN OutType(R, t.base); IF t.leaf THEN Write(R, 1) ELSE Write(R, 0) END;
        Files.WriteSet(R, t.ur); OutPar(R, t.dsc, t.nofpar); Write(R, 0)
      END ;
      IF (t.mno > 0) & (obj # NIL) THEN  (*re-export, output name*)
        mod := topScope.next;
        WHILE (mod # NIL) & (mod.lev # t.mno) DO mod := mod.next END ;
        IF mod # NIL THEN Files.WriteString(R, mod(Module).orgname); Files.WriteInt(R, mod.val); Files.WriteString(R, obj.name)
        ELSE S.Mark("re-export not found"); Write(R, 0)
        END
      ELSE Write(R, 0)
      END
    END
  END OutType;

  PROCEDURE Export*(VAR modid: S.Ident; VAR newSF: BOOLEAN; VAR key: INTEGER);
    VAR x, sum, oldkey: INTEGER;
      obj!, obj0!: Object;
      filename: S.Ident;
      F!, F1!: Files.File; R!, R1!: Files.Rider;
  BEGIN Ref := LastForm + 1; MakeFileName(filename, modid, ".sms");
    F := Files.New(filename); Files.Set(R, F, 0);
    Files.WriteInt(R, 0); (*placeholder*)
    Files.WriteInt(R, 0); (*placeholder for key to be inserted at the end*)
    Files.WriteString(R, modid); Write(R, versionkey);
    obj := topScope.next;
    WHILE obj # NIL DO
      IF obj.expo THEN
        Write(R, obj.class); Files.WriteString(R, obj.name);
        OutType(R, obj.type);
        IF obj.class = Typ THEN
          IF obj.type.form = Record THEN
            obj0 := topScope.next;  (*check whether this is base of previously declared pointer types*)
            WHILE obj0 # obj DO
              IF (obj0.type.form = Pointer) & (obj0.type.base = obj.type) & (obj0.type.ref > 0) THEN Write(R, obj0.type.ref) END ;
              obj0 := obj0.next
            END
          END ;
          Write(R, 0)
        ELSIF obj.class = Const THEN
          IF obj.type.form = Proc THEN Files.WriteNum(R, obj.exno)
          ELSIF obj.type.form = String THEN Files.WriteInt(R, obj.val DIV 10000H*10000H + obj.exno)
          ELSE Files.WriteNum(R, obj.val)
          END
        ELSIF obj.class IN {Var, StoredConst} THEN Files.WriteNum(R, obj.exno)
        END
      END ;
      obj := obj.next
    END ;
    REPEAT Write(R, 0) UNTIL Files.Length(F) MOD 4 = 0;
    FOR Ref := LastForm + 1 TO maxTypTab-1 DO typtab[Ref] := NIL END ;
    Files.Set(R, F, 0); CRC32.reset; Files.ReadInt(R, x);  (* compute key (checksum) *)
    WHILE ~R.eof DO CRC32.write(x); Files.ReadInt(R, x) END; sum := CRC32.read();
    F1 := Files.Old(filename); (*sum is new key*)
    IF F1 # NIL THEN Files.Set(R1, F1, 4); Files.ReadInt(R1, oldkey) ELSE oldkey := sum+1 END ;
    IF sum # oldkey THEN
      IF newSF OR (F1 = NIL) THEN
        key := sum; newSF := TRUE; Files.Set(R, F, 4); Files.WriteInt(R, sum); Files.Register(F)  (*insert checksum*)
      ELSE S.Mark("new symbol file inhibited")
      END
    ELSE newSF := FALSE; key := sum
    END
  END Export;

  PROCEDURE Init*;
  BEGIN topScope := universe; nofmod := 1
  END Init;
  
  PROCEDURE type2(ref, form, size: INTEGER; base: Type): Type;
    VAR tp!: Type;
  BEGIN NEW(tp); tp.form := form; tp.size := size; tp.ref := ref; tp.base := base;
    IF ref >= 0 THEN typtab[ref] := tp END; RETURN tp
  END type2;

  PROCEDURE type(ref, form, size: INTEGER): Type;
  BEGIN RETURN  type2(ref, form, size, NIL)
  END type;

  PROCEDURE enter(name: ARRAY OF CHAR; cl: INTEGER; type: Type; n: INTEGER);
    VAR obj!: Object;
  BEGIN NEW(obj); obj.name := name; obj.class := cl; obj.type := type; obj.val := n; obj.dsc := NIL;
    IF cl = Typ THEN type.typobj := obj END ;
    obj.next := system; system := obj
  END enter;
  
BEGIN
  byteType := type(Byte, Int, 1);
  boolType := type(Bool, Bool, 1);
  charType := type(Char, Char,1);
  byteSetType := type(ByteSet, Set, 1);
  intType := type(Int, Int, 2);
  setType := type(Set, Set, 2);
  nilType := type(NilTyp, NilTyp, 2);
  noType := type(NoTyp, NoTyp, 2);
  strType := type(String, String, 4);
  ptrByteType := type2(PointerToByte, Pointer, 2, byteType);
  ptrIntType := type2(Pointer, Pointer, 2, intType);
  ptrByteSetType := type2(PointerToByteSet, Pointer, 2, byteSetType);
  ptrSetType := type2(PointerToSet, Pointer, 2, setType);
    
  (*initialize universe with data types and in-line procedures;
    BIC, BIS, XOR, AND, ADC, SBC, CLRC, RLA, RLC, RRA, RRC, COND, CMP are not in language definition*)
  system := NIL;  (*n = procno*10 + nofpar*)
  enter("ABS", SFunc, intType, 1); (*functions*)
  enter("ODD", SFunc, boolType, 11);
  enter("ORD", SFunc, intType, 41);
  enter("CHR", SFunc, charType, 51);
  enter("LEN", SFunc, intType, 61);
  enter("TOSET", SFunc, setType, 71);
  enter("BIT", SFunc, boolType, 142);
  enter("INC", SProc, noType, 1); (*procedures*)
  enter("DEC", SProc, noType, 11);
  enter("INCL", SProc, noType, 22);
  enter("EXCL", SProc, noType, 32);
  enter("ASSERT", SProc, noType, 41);
  enter("BIC", SProc, noType, 52);
  enter("BIS", SProc, noType, 62);
  enter("XOR", SProc, noType, 72);
  enter("AND", SProc, noType, 82); (*91, 101 and 123 are in SYSTEM pseudo-module*)
  enter("CLRC", SProc, noType, 130);
  enter("NOP", SProc, noType, 140);
  enter("ADC", SProc, noType, 152);
  enter("SBC", SProc, noType, 162);
  enter("RLA", SProc, noType, 172);
  enter("RLC", SProc, noType, 181);
  enter("RRA", SProc, noType, 192);
  enter("RRC", SProc, noType, 201); (*211 and 221 are in SYSTEM pseudo-module*)
  enter("SWPB", SProc, intType, 231);
  enter("PTR", SProc, noType, 242);
  enter("SET", Typ, setType, 0);   (*types*)
  enter("BYTESET", Typ, byteSetType, 0);
  enter("BOOLEAN", Typ, boolType, 0);
  enter("BYTE", Typ, byteType, 0);
  enter("CHAR", Typ, charType, 0);
  enter("INTEGER", Typ, intType, 0);
  enter("PBYTE", Typ, ptrByteType, 0);
  enter("PINTEGER", Typ, ptrIntType, 0);
  enter("PBYTESET", Typ, ptrByteSetType, 0);
  enter("PSET", Typ, ptrSetType, 0);

  topScope := NIL; OpenScope; topScope.next := system; universe := topScope;

  system := NIL;  (* initialize "unsafe" pseudo-module SYSTEM*)
  enter("COND", SFunc, boolType, 191);
  enter("CMP", SFunc, boolType, 223);
  enter("SIZE", SFunc, intType, 181);
  enter("ADR", SFunc, intType, 171);
  enter("VAL", SFunc, intType, 162);
  enter("BIC_SR", SProc, noType, 91); (*procedures*)
  enter("BIS_SR", SProc, noType, 101);
  enter("COPY", SProc, noType, 123);
  enter("BIC_SR_ON_EXIT", SProc, noType, 211);
  enter("BIS_SR_ON_EXIT", SProc, noType, 221)
END OMSPB.
