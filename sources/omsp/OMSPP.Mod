MODULE OMSPP; (*N. Wirth 1.7.97 / 8.3.2020,
  C. Schoffit 05.06.24 Oberon compiler for MSP430 processor in Oberon-07*)
  IMPORT Display, Texts, Oberon, S := OMSPS, B := OMSPB, G := OMSPG;
  (*Author: Niklaus Wirth, 2014.
    Parser of Oberon-MSP430 compiler. Uses Scanner OMSPS to obtain symbols (tokens),
    OMSPB for definition of data structures and for handling import and export, and
    OMSPG to produce binary code. OMSPP performs type checking and data allocation.
    Parser is target-independent, except for part of the handling of allocations.*)

  TYPE PtrBase = POINTER TO PtrBaseDesc;
    PtrBaseDesc = RECORD  (*list of names of pointer base types*)
      name: S.Ident; type: B.Type; next: PtrBase
    END ;

  VAR sym: INTEGER;   (*last symbol read*)
    dc: LONGINT;    (*data counter*)
    level, exno, version: INTEGER;
    newSF: BOOLEAN;  (*option flag*)
    expression: PROCEDURE (VAR x: G.Item);  (*to avoid forward reference*)
    Type: PROCEDURE (VAR type: B.Type);
    FormalType: PROCEDURE (VAR typ: B.Type; dim: INTEGER);
    modid: S.Ident;
    pbsList: PtrBase;   (*list of names of pointer base types*)
    dummy: B.Object;
    W: Texts.Writer;

  PROCEDURE Check(s: INTEGER; msg: ARRAY OF CHAR);
  BEGIN
    IF sym = s THEN S.Get(sym) ELSE S.Mark(msg) END
  END Check;

  PROCEDURE qualident(VAR obj: B.Object);
  BEGIN obj := B.thisObj(); S.Get(sym);
    IF obj = NIL THEN S.Mark("undef"); obj := dummy END ;
    IF (sym = S.period) & (obj.class = B.Mod) THEN
      S.Get(sym);
      IF sym = S.ident THEN obj := B.thisimport(obj); S.Get(sym);
        IF obj = NIL THEN S.Mark("undef"); obj := dummy END
      ELSE S.Mark("identifier expected"); obj := dummy
      END
    END
  END qualident;

  PROCEDURE CheckBool(VAR x: G.Item);
  BEGIN
    IF x.type.form # B.Bool THEN S.Mark("not Boolean"); x.type := B.boolType END
  END CheckBool;

  PROCEDURE CheckInt(VAR x: G.Item);
  BEGIN
    IF x.type.form # B.Int THEN S.Mark("not Integer"); x.type := B.intType END
  END CheckInt;

  PROCEDURE CheckSet(VAR x: G.Item);
  BEGIN
    IF x.type.form # B.Set THEN S.Mark("not Set"); x.type := B.setType END 
  END CheckSet;

  PROCEDURE CheckSetVal(VAR x: G.Item);
  BEGIN
    IF x.type.form # B.Int THEN S.Mark("not Int"); x.type := B.setType
    ELSIF x.mode = B.Const THEN
      IF (x.a < 0) OR (x.a >= 16) THEN S.Mark("invalid set") END
    END 
  END CheckSetVal;

  PROCEDURE CheckConst(VAR x: G.Item);
  BEGIN
    IF x.mode # B.Const THEN S.Mark("not a constant"); x.mode := B.Const END
  END CheckConst;

  PROCEDURE CheckReadOnly(VAR x: G.Item);
  BEGIN
    IF x.rdo THEN S.Mark("read-only") END
  END CheckReadOnly;

  PROCEDURE CheckExport(VAR expo: BOOLEAN);
  BEGIN
    IF sym = S.times THEN
      expo := TRUE; S.Get(sym);
      IF level # 0 THEN S.Mark("remove asterisk") END
    ELSE expo := FALSE
    END
  END CheckExport;

  PROCEDURE CheckUnsafeMarking(VAR unsafe: BOOLEAN);
  BEGIN
    IF sym = S.emark THEN
      unsafe := TRUE; S.Get(sym);
      IF level = 0 THEN S.Mark("remove exclamation mark") END
    ELSE unsafe := FALSE
    END
  END CheckUnsafeMarking;

  PROCEDURE IsExtension(t0, t1: B.Type): BOOLEAN;
  BEGIN (*t1 is an extension of t0*)
    RETURN (t0 = t1) OR (t1 # NIL) & IsExtension(t0, t1.base)
  END IsExtension;

  (* expressions *)
  PROCEDURE TypeTest(VAR x: G.Item; T: B.Type; guard: BOOLEAN);
    VAR xt!: B.Type;
  BEGIN xt := x.type;
    IF (T.form = xt.form ) & ((T.form = B.Pointer) OR (T.form = B.Record) & (x.mode = B.Par)) THEN
      WHILE (xt # T) & (xt # NIL) DO xt := xt.base END ;
      IF xt # T THEN xt := x.type;
        IF xt.form = B.Pointer THEN
          IF IsExtension(xt.base, T.base) THEN G.TypeTest(x, T.base, FALSE, guard); x.type := T
          ELSE S.Mark("not an extension")
          END
        ELSIF (xt.form = B.Record) & (x.mode = B.Par) THEN
          IF IsExtension(xt, T) THEN  G.TypeTest(x, T, TRUE, guard); x.type := T
          ELSE S.Mark("not an extension")
          END
        ELSE S.Mark("incompatible types")
        END
      ELSIF ~guard THEN G.TypeTest(x, NIL, FALSE, FALSE)
      END
    ELSE S.Mark("type mismatch")
    END;
    IF ~guard THEN x.type := B.boolType END
  END TypeTest;

  PROCEDURE selector(VAR x: G.Item);
    VAR y!: G.Item; obj!: B.Object;
  BEGIN
    WHILE (sym = S.lbrak) OR (sym = S.period) OR (sym = S.arrow)
        OR (sym = S.lparen) & (x.type.form IN {B.Record, B.Pointer}) DO
      IF sym = S.lbrak THEN
        REPEAT S.Get(sym); expression(y);
          IF x.type.form = B.Array THEN
            CheckInt(y); G.Index(x, y); x.type := x.type.base
          ELSE S.Mark("not an array")
          END
        UNTIL sym # S.comma;
        Check(S.rbrak, "no ]")
      ELSIF sym = S.period THEN S.Get(sym);
        IF sym = S.ident THEN
          IF x.type.form = B.Pointer THEN G.DeRef(x); x.type := x.type.base END ;
          IF x.type.form = B.Record THEN
            obj := B.thisfield(x.type); S.Get(sym);
            IF obj # NIL THEN G.Field(x, obj); x.type := obj.type
            ELSE S.Mark("undef")
            END
          ELSE S.Mark("not a record")
          END
        ELSE S.Mark("ident?")
        END
      ELSIF sym = S.arrow THEN
        S.Get(sym);
        IF x.type.form = B.Pointer THEN G.DeRef(x); x.type := x.type.base
        ELSE S.Mark("not a pointer")
        END
      ELSIF (sym = S.lparen) & (x.type.form IN {B.Record, B.Pointer}) THEN (*type guard*)
        S.Get(sym);
        IF sym = S.ident THEN
          qualident(obj);
          IF obj.class = B.Typ THEN TypeTest(x, obj.type, TRUE)
          ELSE S.Mark("guard type expected")
          END
        ELSE S.Mark("not an identifier")
        END ;
        Check(S.rparen, " ) missing")
      END
    END
  END selector;

  PROCEDURE EqualSignatures(t0, t1: B.Type): BOOLEAN;
    VAR p0!, p1!: B.Object; com: BOOLEAN;
  BEGIN com := TRUE;
    IF (t0.base = t1.base) & (t0.nofpar = t1.nofpar) THEN
      p0 := t0.dsc; p1 := t1.dsc;
      WHILE p0 # NIL DO
        IF (p0.class = p1.class) &  (p0.rdo = p1.rdo) &
          ((p0.type = p1.type) OR
          (p0.type.form = B.Array) & (p1.type.form = B.Array) & (p0.type.len = p1.type.len) & (p0.type.base = p1.type.base) OR
          (p0.type.form = B.Proc) & (p1.type.form = B.Proc) & EqualSignatures(p0.type, p1.type))
        THEN p0 := p0.next; p1 := p1.next
        ELSE p0 := NIL; com := FALSE
        END
      END
    ELSE com := FALSE
    END ;
    RETURN com
  END EqualSignatures;

  PROCEDURE CompTypes(t0, t1: B.Type; varpar: BOOLEAN): BOOLEAN;
  BEGIN (*check for assignment compatibility*)
    RETURN (t0 = t1)    (*openarray assignment disallowed in OMSPG*)
      OR (t0.form = B.Array) & (t1.form = B.Array) & (t0.base =  t1.base) & (t0.len = t1.len)
      OR (t0.form = B.Record) & (t1.form = B.Record)  & IsExtension(t0, t1)
      OR ~varpar &
        ((t0.form = B.Pointer) & (t1.form = B.Pointer)  & IsExtension(t0.base, t1.base)
        OR (t0.form = B.Proc) & (t1.form = B.Proc) & EqualSignatures(t0, t1)
        OR (t0.form IN {B.Pointer, B.Proc}) & (t1.form = B.NilTyp))
  END CompTypes;

  PROCEDURE Parameter(par: B.Object);
    VAR x!: G.Item; varpar: BOOLEAN;
  BEGIN expression(x);
    IF par # NIL THEN
      varpar := par.class = B.Par;
      IF CompTypes(par.type, x.type, varpar) THEN
        IF ~varpar THEN G.ValueParam(x, par)
        ELSE (*par.class = Par*)
          IF ~par.rdo THEN CheckReadOnly(x) END ;
          G.VarParam(x, par)
        END
      ELSIF (x.type.form = B.Array) & (par.type.form = B.Array) &
          (x.type.base = par.type.base) & (par.type.len < 0) THEN
        IF ~par.rdo THEN CheckReadOnly(x) END ;
        G.OpenArrayParam(x, par)
      ELSIF (x.type.form = B.String) & varpar & par.rdo & (par.type.form = B.Array) & 
          (par.type.base.form = B.Char) & (par.type.len < 0) THEN G.StringParam(x, par)
      ELSIF ~varpar & (par.type.form = B.Int) & (x.type.form = B.Int) THEN G.ValueParam(x, par)  (*BYTE*)
      ELSIF (x.type.form = B.String) & (x.b = 2) & (par.class = B.Var) & (par.type.form = B.Char) THEN
        G.StrToChar(x); G.ValueParam(x, par)
      ELSIF (par.type.form = B.Array) & (par.type.base = B.byteType) & 
          (par.type.len >= 0) & (par.type.size = x.type.size) THEN
        G.VarParam(x, par)
      ELSE S.Mark("incompatible parameters")
      END
    END
  END Parameter;

  PROCEDURE ParamList(x: G.Item);
    VAR n: INTEGER; par!: B.Object;
  BEGIN par := x.type.dsc; n := 0;
    IF sym # S.rparen THEN
      Parameter(par); n := 1;
      WHILE sym <= S.comma DO
        Check(S.comma, "comma?");
        IF par # NIL THEN par := par.next END ;
        INC(n); Parameter(par)
      END ;
      Check(S.rparen, ") missing")
    ELSE S.Get(sym);
    END;
    IF n < x.type.nofpar THEN S.Mark("too few params")
    ELSIF n > x.type.nofpar THEN S.Mark("too many params")
    END
  END ParamList;

  PROCEDURE StandFunc(VAR x: G.Item; fct: LONGINT; restyp: B.Type);
    VAR y!, z!: G.Item; n, npar: LONGINT;
  BEGIN Check(S.lparen, "no (");
    npar := fct MOD 10; fct := fct DIV 10; expression(x); n := 1;
    IF sym = S.comma THEN S.Get(sym); expression(y); n := 2;
      WHILE sym = S.comma DO S.Get(sym); expression(z); INC(n) END ;
    END;
    Check(S.rparen, "no )");
    IF n = npar THEN
      IF fct = 0 THEN (*ABS*) CheckInt(x); G.Abs(x)
      ELSIF fct = 1 THEN (*ODD*) CheckInt(x); G.Odd(x)
      ELSIF fct = 4 THEN (*ORD*)
        IF x.type.form <= B.Proc THEN G.Ord(x)
        ELSIF (x.type.form = B.String) & (x.b = 2) THEN G.StrToChar(x)
        ELSE S.Mark("bad type")
        END
      ELSIF fct = 5 THEN (*CHR*) CheckInt(x); G.Ord(x)
      ELSIF fct = 6 THEN (*LEN*)
          IF x.type.form = B.Array THEN G.Len(x) ELSE S.Mark("not an array") END
      ELSIF fct IN {7, 8, 9, 10} THEN (*RLS, RLC, RRA, RRC*) CheckInt(y);
        IF x.type.form IN {B.Int, B.Set} THEN G.Shift(fct-7, x, y); restyp := x.type ELSE S.Mark("bad type") END
      ELSIF fct = 11 THEN (*ADC*) G.ADC(x, y)
      ELSIF fct = 12 THEN (*SBC*) G.SBC(x, y)
      ELSIF fct = 14 THEN (*BIT*) CheckInt(x); CheckInt(y); G.Bit(x, y)
      ELSIF fct = 15 THEN (*REG*) CheckConst(x); CheckInt(x); G.Register(x)
      ELSIF fct = 16 THEN (*VAL*)
        IF (x.mode= B.Typ) & (x.type.size <= y.type.size) THEN restyp := x.type; x := y
        ELSE S.Mark("casting not allowed")
        END
      ELSIF fct = 17 THEN (*ADR*) G.Adr(x)
      ELSIF fct = 18 THEN (*SIZE*)
        IF x.mode = B.Typ THEN G.MakeConstItem(x, B.intType, x.type.size)
        ELSE S.Mark("must be a type")
        END
      ELSIF fct = 19 THEN (*COND*) CheckConst(x); CheckInt(x); G.Condition(x)
      ELSIF fct = 22 THEN (*Int Compare*)
        CheckInt(x); CheckInt(y); CheckConst(z); CheckInt(z); G.IntCompare(x, y, z)
      ELSE ASSERT(FALSE)
      END;
      x.type := restyp
    ELSE S.Mark("wrong nof params")
    END
  END StandFunc;

  PROCEDURE element(VAR x: G.Item);
    VAR y!: G.Item;
  BEGIN expression(x); CheckSetVal(x);
    IF sym = S.upto THEN S.Get(sym); expression(y); CheckSetVal(y); G.Set(x, y)
    ELSE G.Singleton(x)
    END ;
    x.type := B.setType
  END element;
  
  PROCEDURE set(VAR x: G.Item);
    VAR y!: G.Item;
  BEGIN
    IF sym >= S.if THEN
      IF sym # S.rbrace THEN S.Mark(" } missing") END ;
      G.MakeConstItem(x, B.setType, 0) (*empty set*)
    ELSE element(x);
      WHILE (sym < S.rparen) OR (sym > S.rbrace) DO
        IF sym = S.comma THEN S.Get(sym)
        ELSIF sym # S.rbrace THEN S.Mark("missing comma")
        END ;
        element(y); G.SetOp(S.plus, x, y)
      END
    END
  END set; 

  PROCEDURE factor(VAR x: G.Item);
    VAR obj!: B.Object; rx, sx: LONGINT;
  BEGIN (*sync*)
    IF (sym < S.char) OR (sym > S.ident) THEN S.Mark("expression expected");
      REPEAT S.Get(sym) UNTIL (sym >= S.char) & (sym <= S.for) OR (sym >= S.then)
    END;
    IF sym = S.ident THEN
      qualident(obj);  
      IF obj.class = B.SFunc THEN StandFunc(x, obj.val, obj.type)
      ELSE G.MakeItem(x, obj, level); selector(x);
        IF sym = S.lparen THEN
          S.Get(sym);
          IF (x.type.form = B.Proc) & (x.type.base.form # B.NoTyp) THEN
            G.PrepCall(x, rx, sx); ParamList(x); G.Call(x, rx, sx); x.type := x.type.base
          ELSE S.Mark("not a function"); ParamList(x)
          END
        END
      END
    ELSIF sym = S.int THEN G.MakeConstItem(x, B.intType, S.ival); S.Get(sym)
    ELSIF sym = S.char THEN G.MakeConstItem(x, B.charType, S.ival); S.Get(sym)
    ELSIF sym = S.nil THEN S.Get(sym); G.MakeConstItem(x, B.nilType, 0)
    ELSIF sym = S.string THEN G.MakeStringItem(x, S.slen); S.Get(sym)
    ELSIF sym = S.lparen THEN S.Get(sym); expression(x); Check(S.rparen, "no )")
    ELSIF sym = S.lbrace THEN S.Get(sym); set(x); Check(S.rbrace, "no }")
    ELSIF sym = S.not THEN S.Get(sym); factor(x); CheckBool(x); G.Not(x)
    ELSIF sym = S.false THEN S.Get(sym); G.MakeConstItem(x, B.boolType, 0)
    ELSIF sym = S.true THEN S.Get(sym); G.MakeConstItem(x, B.boolType, 1)
    ELSE S.Mark("not a factor"); G.MakeConstItem(x, B.intType, 0)
    END
  END factor;

  PROCEDURE term(VAR x: G.Item);
    VAR y!: G.Item; op, f: INTEGER;
  BEGIN factor(x); f := x.type.form;
    WHILE (sym >= S.times) & (sym <= S.and) DO
      op := sym; S.Get(sym);
      IF op = S.times THEN
        IF f = B.Int THEN factor(y); CheckInt(y); G.MulOp(x, y)
         ELSIF f = B.Set THEN factor(y); CheckSet(y); G.SetOp(op, x, y)
        ELSE S.Mark("bad type")
        END
      ELSIF (op = S.div) OR (op = S.mod) THEN
        CheckInt(x); factor(y); CheckInt(y); G.DivOp(op, x, y)
      ELSIF op = S.rdiv THEN
        IF f = B.Set THEN factor(y); CheckSet(y); G.SetOp(op, x, y)
        ELSE S.Mark("bad type")
        END
      ELSE (*op = and*) CheckBool(x); G.And1(x); factor(y); CheckBool(y); G.And2(x, y)
      END
    END
  END term;

  PROCEDURE SimpleExpression(VAR x: G.Item);
    VAR y!: G.Item; op: INTEGER;
  BEGIN
    IF sym = S.minus THEN S.Get(sym); term(x);
      IF x.type.form IN {B.Int, B.Set} THEN G.Neg(x) ELSE CheckInt(x) END
    ELSIF sym = S.plus THEN S.Get(sym); term(x);
    ELSE term(x)
    END ;
    WHILE (sym >= S.plus) & (sym <= S.or) DO
      op := sym; S.Get(sym);
      IF op = S.or THEN G.Or1(x); CheckBool(x); term(y); CheckBool(y); G.Or2(x, y)
      ELSIF x.type.form = B.Int THEN term(y); CheckInt(y); G.AddOp(op, x, y)
      ELSE CheckSet(x); term(y); CheckSet(y); G.SetOp(op, x, y)
      END
    END
  END SimpleExpression;

  PROCEDURE expression0(VAR x: G.Item);
    VAR y!: G.Item; obj!: B.Object; rel, xf, yf: INTEGER;
  BEGIN SimpleExpression(x);
    IF (sym >= S.eql) & (sym <= S.geq) THEN
      rel := sym; S.Get(sym); SimpleExpression(y); xf := x.type.form; yf := y.type.form;
      IF x.type = y.type THEN
        IF (xf IN {B.Char, B.Int}) THEN G.IntRelation(rel, x, y)
        ELSIF (xf IN {B.Set, B.Pointer, B.Proc, B.NilTyp, B.Bool}) THEN
          IF rel <= S.neq THEN G.IntRelation(rel, x, y) ELSE S.Mark("only = or #") END
        ELSIF (xf = B.Array) & (x.type.base.form = B.Char) OR (xf = B.String) THEN
          G.StringRelation(rel, x, y)
        ELSE S.Mark("illegal comparison")
        END
      ELSIF (xf IN {B.Pointer, B.Proc}) & (yf = B.NilTyp)
          OR (yf IN {B.Pointer, B.Proc}) & (xf = B.NilTyp) THEN
        IF rel <= S.neq THEN G.IntRelation(rel, x,  y) ELSE S.Mark("only = or #") END
      ELSIF (xf = B.Pointer) & (yf = B.Pointer) &
          (IsExtension(x.type.base, y.type.base) OR IsExtension(y.type.base, x.type.base))
          OR (xf = B.Proc) & (yf = B.Proc) & EqualSignatures(x.type, y.type) THEN
        IF rel <= S.neq THEN G.IntRelation(rel,  x, y) ELSE S.Mark("only = or #") END
      ELSIF (xf = B.Array) & (x.type.base.form = B.Char) &
            ((yf = B.String) OR (yf = B.Array) & (y.type.base.form = B.Char))
          OR (yf = B.Array) & (y.type.base.form = B.Char) & (xf = B.String) THEN
        G.StringRelation(rel, x, y)
      ELSIF (xf = B.Char) & (yf = B.String) & (y.b = 2) THEN
        G.StrToChar(y); G.IntRelation(rel, x, y)
      ELSIF (yf = B.Char) & (xf = B.String) & (x.b = 2) THEN
        G.StrToChar(x); G.IntRelation(rel, x, y)
      ELSIF (xf = B.Int) & (yf = B.Int) THEN G.IntRelation(rel,  x, y)  (*BYTE*)
      ELSE S.Mark("illegal comparison")
      END;
      x.type := B.boolType
    ELSIF sym = S.in THEN
      S.Get(sym); CheckInt(x); SimpleExpression(y); CheckSet(y); G.In(x, y) ;
      x.type := B.boolType
    ELSIF sym = S.is THEN
      S.Get(sym); qualident(obj); TypeTest(x, obj.type, FALSE) ;
      x.type := B.boolType
    END
  END expression0;

  (* statements *)

  PROCEDURE StandProc(pno: LONGINT);
    VAR nap, npar: LONGINT; (*nof actual/formal parameters*)
      x!, y!, z!: G.Item;
  BEGIN Check(S.lparen, "no (");
    npar := pno MOD 10; pno := pno DIV 10; expression(x); nap := 1;
    IF sym = S.comma THEN S.Get(sym);
      IF pno = 14 (*LDREG*) THEN CheckConst(x); CheckInt(x); G.SetRH(x.a) END;
      expression(y); nap := 2; z.type := B.noType;
      WHILE sym = S.comma DO S.Get(sym); expression(z); INC(nap) END
    ELSE y.type := B.noType
    END;
    Check(S.rparen, "no )");
    IF (npar = nap) OR (pno IN {0, 1}) THEN 
      IF pno IN {0, 1} THEN (*INC, DEC*)
        CheckInt(x); CheckReadOnly(x);
        IF y.type # B.noType THEN CheckInt(y) END ;
        G.Increment(pno, x, y)
      ELSIF pno IN {2, 3} THEN (*INCL, EXCL*)
        CheckSet(x); CheckReadOnly(x); CheckInt(y); G.Include(pno-2, x, y)
      ELSIF pno = 4 THEN CheckBool(x); G.Assert(x)
      ELSIF pno = 10 THEN CheckInt(x); G.Get(x, y)
      ELSIF pno = 11 THEN CheckInt(x); G.Put(x, y)
      ELSIF pno = 12 THEN CheckInt(x); CheckInt(y); CheckInt(z); G.Copy(x, y, z)
      ELSIF pno = 14 THEN G.LDREG(y)
      ELSE ASSERT(FALSE)
      END
    ELSE S.Mark("wrong nof parameters")
    END
  END StandProc;

  PROCEDURE StatSequence;
    VAR obj!: B.Object;
      orgtype!: B.Type; (*original type of case var*)
      x!, y!, z!, w!: G.Item;
      L0, L1, rx, sx: LONGINT;

    PROCEDURE TypeCase(obj: B.Object; VAR x: G.Item);
      VAR typobj!: B.Object;
    BEGIN G.MakeItem(x, obj, level);
      IF sym = S.ident THEN
        qualident(typobj);
        IF typobj.class # B.Typ THEN S.Mark("not a type") END ;
        TypeTest(x, typobj.type, FALSE); obj.type := typobj.type;
        G.CFJump(x); Check(S.colon, ": expected"); StatSequence
      ELSE G.CFJump(x); S.Mark("type id expected")
      END
     END TypeCase;

    PROCEDURE SkipCase;
    BEGIN 
      WHILE sym # S.colon DO S.Get(sym) END ;
      S.Get(sym); StatSequence
    END SkipCase;

  BEGIN (* StatSequence *)
    REPEAT (*sync*) obj := NIL;
      IF ~((sym >= S.ident)  & (sym <= S.for) OR (sym >= S.semicolon)) THEN
        S.Mark("statement expected");
        REPEAT S.Get(sym) UNTIL (sym >= S.ident)
      END ;
      IF sym = S.ident THEN
        qualident(obj); G.MakeItem(x, obj, level);
        IF x.mode = B.SProc THEN StandProc(obj.val)
        ELSE selector(x);
          IF sym = S.becomes THEN (*assignment*)
            S.Get(sym); CheckReadOnly(x); expression(y);
            IF CompTypes(x.type, y.type, FALSE) THEN
              IF (x.type.form <= B.Pointer) OR (x.type.form = B.Proc) THEN G.Store(x, y)
              ELSE G.StoreStruct(x, y)
              END
            ELSIF (x.type.form = B.Array) & (y.type.form = B.Array) & (x.type.base = y.type.base) & (y.type.len < 0) THEN
              G.StoreStruct(x, y)
            ELSIF (x.type.form = B.Array) & (x.type.base.form = B.Char) & (y.type.form = B.String) THEN
              G.CopyString(x, y)
            ELSIF (x.type.form = B.Int) & (y.type.form = B.Int) THEN G.Store(x, y)  (*BYTE*)
            ELSIF (x.type.form = B.Char) & (y.type.form = B.String) & (y.b = 2) THEN
              G.StrToChar(y); G.Store(x, y)
            ELSE S.Mark("illegal assignment")
            END
          ELSIF sym = S.eql THEN S.Mark("should be :="); S.Get(sym); expression(y)
          ELSIF sym = S.lparen THEN (*procedure call*)
            S.Get(sym);
            IF (x.type.form = B.Proc) & (x.type.base.form = B.NoTyp) THEN
              G.PrepCall(x, rx, sx); ParamList(x); G.Call(x, rx, sx)
            ELSE S.Mark("not a procedure"); ParamList(x)
            END
          ELSIF x.type.form = B.Proc THEN (*procedure call without parameters*)
            IF x.type.nofpar > 0 THEN S.Mark("missing parameters") END ;
            IF x.type.base.form = B.NoTyp THEN 
              G.PrepCall(x, rx, sx); G.Call(x, rx, sx)
            ELSE S.Mark("not a procedure")
            END
          ELSIF x.mode = B.Typ THEN S.Mark("illegal assignment")
          ELSE S.Mark("not a procedure")
          END
        END
      ELSIF sym = S.if THEN
        S.Get(sym); expression(x); CheckBool(x); G.CFJump(x);
        Check(S.then, "no THEN");
        StatSequence; L0 := 0;
        WHILE sym = S.elsif DO
          S.Get(sym); G.FJump(L0); G.Fixup(x); expression(x); CheckBool(x);
          G.CFJump(x); Check(S.then, "no THEN"); StatSequence
        END ;
        IF sym = S.else THEN S.Get(sym); G.FJump(L0); G.Fixup(x); StatSequence
        ELSE G.Fixup(x)
        END ;
        G.FixLink(L0); Check(S.end, "no END")
      ELSIF sym = S.while THEN
        S.Get(sym); L0 := G.Here(); expression(x); CheckBool(x); G.CFJump(x);
        Check(S.do, "no DO"); StatSequence; G.BJump(L0);
        WHILE sym = S.elsif DO
          S.Get(sym); G.Fixup(x); expression(x); CheckBool(x); G.CFJump(x);
          Check(S.do, "no DO"); StatSequence; G.BJump(L0)
        END ;
        G.Fixup(x); Check(S.end, "no END")
      ELSIF sym = S.repeat THEN
        S.Get(sym); L0 := G.Here(); StatSequence;
        IF sym = S.until THEN
          S.Get(sym); expression(x); CheckBool(x); G.CBJump(x, L0)
        ELSE S.Mark("missing UNTIL")
        END
      ELSIF sym = S.for THEN
        S.Get(sym);
        IF sym = S.ident THEN
          qualident(obj); G.MakeItem(x, obj, level); CheckInt(x); CheckReadOnly(x);
          IF sym = S.becomes THEN
            S.Get(sym); expression(y); CheckInt(y); G.For0(x, y); L0 := G.Here();
            Check(S.to, "no TO"); expression(z); CheckInt(z); obj.rdo := TRUE;
            IF sym = S.by THEN S.Get(sym); expression(w); CheckConst(w); CheckInt(w)
            ELSE G.MakeConstItem(w, B.intType, 1)
            END;
            Check(S.do, "no DO"); G.For1(x, y, z, w, L1);
            StatSequence; Check(S.end, "no END");
            G.For2(x, y, w); G.BJump(L0); G.FixLink(L1); obj.rdo := FALSE
          ELSE S.Mark(":= expected")
          END
        ELSE S.Mark("identifier expected")
        END
      ELSIF sym = S.case THEN
        S.Get(sym);
        IF sym = S.ident THEN
          qualident(obj); orgtype := obj.type;
          IF (orgtype.form = B.Pointer) OR (orgtype.form = B.Record) & (obj.class = B.Par) THEN
            Check(S.of, "OF expected"); TypeCase(obj, x); L0 := 0;
            WHILE sym = S.bar DO
              S.Get(sym); G.FJump(L0); G.Fixup(x); obj.type := orgtype; TypeCase(obj, x)
            END ;
            G.Fixup(x); G.FixLink(L0); obj.type := orgtype
          ELSE S.Mark("numeric case not implemented");
            Check(S.of, "OF expected"); SkipCase;
            WHILE sym = S.bar DO SkipCase END
          END
        ELSE S.Mark("ident expected")
        END ;
        Check(S.end, "no END")
      END ;
      G.CheckRegs;
      IF sym = S.semicolon THEN S.Get(sym)
      ELSIF sym < S.semicolon THEN S.Mark("missing semicolon?")
      END
    UNTIL sym > S.semicolon
  END StatSequence;

  (* Types and declarations *)

  PROCEDURE IdentList(class: INTEGER; VAR first: B.Object);
    VAR obj!: B.Object;
  BEGIN
    IF sym = S.ident THEN
      B.NewObj(first, S.id, class); S.Get(sym); CheckExport(first.expo); CheckUnsafeMarking(first.unsafe);
      WHILE sym = S.comma DO
        S.Get(sym);
        IF sym = S.ident THEN B.NewObj(obj, S.id, class); S.Get(sym); CheckExport(obj.expo); CheckUnsafeMarking(obj.unsafe)
        ELSE S.Mark("ident?")
        END
      END;
      IF sym = S.colon THEN S.Get(sym) ELSE S.Mark(":?") END
    ELSE first := NIL
    END
  END IdentList;
  
  PROCEDURE ArrayType(VAR type: B.Type);
    VAR x!: G.Item; typ!: B.Type; len: LONGINT;
  BEGIN NEW(typ); typ.form := B.NoTyp;
    expression(x);
    IF (x.mode = B.Const) & (x.type.form = B.Int) & (x.a >= 0) THEN len := x.a
    ELSE len := 1; S.Mark("not a valid length")
    END;
    IF sym = S.of THEN S.Get(sym); Type(typ.base);
      IF (typ.base.form = B.Array) & (typ.base.len < 0) THEN S.Mark("dyn array not allowed") END
    ELSIF sym = S.comma THEN S.Get(sym); ArrayType(typ.base)
    ELSE S.Mark("missing OF"); typ.base := B.intType
    END ;
    typ.size := (len * typ.base.size + 3) DIV 4 * 4;
    typ.form := B.Array; typ.len := len; type := typ
  END ArrayType;

  PROCEDURE RecordType(VAR type: OM4B.Type);
    VAR obj!, obj0!, new!, bot!, base!: OM4B.Object;
      typ!, tp!: OM4B.Type;
      offset, off, n: LONGINT;
  BEGIN NEW(typ); typ.form := OM4B.NoTyp; typ.base := NIL; typ.mno := -level; typ.nofpar := 0; offset := 0; bot := NIL;
    IF sym = OM4S.lparen THEN
      OM4S.Get(sym); (*record extension*)
      IF level # 0 THEN OM4S.Mark("extension of local types not implemented") END ;
      IF sym = OM4S.ident THEN
        qualident(base);
        IF base.class = OM4B.Typ THEN
          IF base.type.form = OM4B.Record THEN typ.base := base.type
          ELSE typ.base := OM4B.intType; OM4S.Mark("invalid extension")
          END ;
          typ.nofpar := typ.base.nofpar + 1; (*"nofpar" here abused for extension level*)
          bot := typ.base.dsc; offset := typ.base.size
        ELSE OM4S.Mark("type expected")
        END
      ELSE OM4S.Mark("ident expected")
      END ;
      Check(OM4S.rparen, "no )")
    END ;
    WHILE sym = OM4S.ident DO  (*fields*)
      n := 0; obj := bot;
      WHILE sym = OM4S.ident DO
        obj0 := obj;
        WHILE (obj0 # NIL) & (obj0.name # OM4S.id) DO obj0 := obj0.next END ;
        IF obj0 # NIL THEN OM4S.Mark("mult def") END ;
        NEW(new); OM4S.CopyId(new.name); new.class := OM4B.Fld; new.next := obj; obj := new; INC(n);
        OM4S.Get(sym); CheckExport(new.expo);
        IF (sym # OM4S.comma) & (sym # OM4S.colon) THEN OM4S.Mark("comma expected")
        ELSIF sym = OM4S.comma THEN OM4S.Get(sym)
        END
      END ;
      Check(OM4S.colon, "colon expected"); Type(tp);
      IF (tp.form = OM4B.Array) & (tp.len < 0) THEN OM4S.Mark("dyn array not allowed") END ;
      IF tp.size > 1 THEN offset := (offset+3) DIV 4 * 4 END ;
      offset := offset + n * tp.size; off := offset; obj0 := obj;
      WHILE obj0 # bot DO obj0.type := tp; obj0.lev := 0; off := off - tp.size; obj0.val := off; obj0 := obj0.next END ;
      bot := obj;
      IF sym = OM4S.semicolon THEN OM4S.Get(sym) ELSIF sym # OM4S.end THEN OM4S.Mark(" ; or END") END
    END ;
    typ.form := OM4B.Record; typ.dsc := bot; typ.size := (offset + 3) DIV 4 * 4; type := typ
  END RecordType;

  PROCEDURE FPSection(VAR adr: LONGINT; VAR nofpar: INTEGER);
    VAR obj!, first!: OM4B.Object; tp!: OM4B.Type;
      parsize: LONGINT; cl: INTEGER; rdo: BOOLEAN;
  BEGIN
    IF sym = OM4S.var THEN OM4S.Get(sym); cl := OM4B.Par ELSE cl := OM4B.Var END ;
    IdentList(cl, first); FormalType(tp, 0); rdo := FALSE;
    IF (cl = OM4B.Var) & (tp.form >= OM4B.Array) THEN cl := OM4B.Par; rdo := TRUE END ;
    IF (tp.form = OM4B.Array) & (tp.len < 0) OR (OM4G.check & (tp.form = OM4B.Record)) THEN
      parsize := 2*OM4G.WordSize  (*open array or record, needs second word for length or type tag*)
    ELSE parsize := OM4G.WordSize
    END ;
    obj := first;
    WHILE obj # NIL DO
      INC(nofpar); obj.class := cl; obj.type := tp; obj.rdo := rdo; obj.lev := level; obj.val := adr;
      adr := adr + parsize; obj := obj.next
    END ;
    IF adr >= 52 THEN OM4S.Mark("too many parameters") END
  END FPSection;

  PROCEDURE ProcedureType(ptype: OM4B.Type; VAR parblksize: LONGINT);
    VAR obj!: OM4B.Object; size: LONGINT; nofpar: INTEGER;
  BEGIN ptype.base := OM4B.noType; size := parblksize; nofpar := 0; ptype.dsc := NIL;
    IF sym = OM4S.lparen THEN
      OM4S.Get(sym);
      IF sym = OM4S.rparen THEN OM4S.Get(sym)
      ELSE FPSection(size, nofpar);
        WHILE sym = OM4S.semicolon DO OM4S.Get(sym); FPSection(size, nofpar) END ;
        Check(OM4S.rparen, "no )")
      END ;
      IF sym = OM4S.colon THEN  (*function*)
        OM4S.Get(sym);
        IF sym = OM4S.ident THEN
          qualident(obj); ptype.base := obj.type;
          IF ~((obj.class = OM4B.Typ) & (obj.type.form IN {OM4B.Byte .. OM4B.Pointer, OM4B.Proc})) THEN
            OM4S.Mark("illegal function type")
          END
        ELSE OM4S.Mark("type identifier expected")
        END
      END
    END ;
    ptype.nofpar := nofpar; parblksize := size
  END ProcedureType;

  PROCEDURE FormalType0(VAR typ: OM4B.Type; dim: INTEGER);
    VAR obj!: OM4B.Object; dmy: LONGINT;
  BEGIN
    IF sym = OM4S.ident THEN
      qualident(obj);
      IF obj.class = OM4B.Typ THEN typ := obj.type ELSE OM4S.Mark("not a type"); typ := OM4B.intType END
    ELSIF sym = OM4S.array THEN
      OM4S.Get(sym); Check(OM4S.of, "OF ?");
      IF dim >= 1 THEN OM4S.Mark("multi-dimensional open arrays not implemented") END ;
      NEW(typ); typ.form := OM4B.Array; typ.len := -1; typ.size := 2*OM4G.WordSize; 
      FormalType(typ.base, dim+1)
    ELSIF sym = OM4S.procedure THEN
      OM4S.Get(sym); OM4B.OpenScope;
      NEW(typ); typ.form := OM4B.Proc; typ.size := OM4G.WordSize; dmy := 0; ProcedureType(typ, dmy);
      typ.dsc := OM4B.topScope.next; OM4B.CloseScope
    ELSE OM4S.Mark("identifier expected"); typ := OM4B.noType
    END
  END FormalType0;

  PROCEDURE CheckRecLevel(lev: INTEGER);
  BEGIN
    IF lev # 0 THEN OM4S.Mark("ptr base must be global") END
  END CheckRecLevel;

  PROCEDURE Type0(VAR type: OM4B.Type);
    VAR dmy: LONGINT; obj!: OM4B.Object; ptbase!: PtrBase;
  BEGIN type := OM4B.intType; (*sync*)
    IF (sym # OM4S.ident) & (sym < OM4S.array) THEN OM4S.Mark("not a type");
      REPEAT OM4S.Get(sym) UNTIL (sym = OM4S.ident) OR (sym >= OM4S.array)
    END ;
    IF sym = OM4S.ident THEN
      qualident(obj);
      IF obj.class = OM4B.Typ THEN
        IF (obj.type # NIL) & (obj.type.form # OM4B.NoTyp) THEN type := obj.type END
      ELSE OM4S.Mark("not a type or undefined")
      END
    ELSIF sym = OM4S.array THEN OM4S.Get(sym); ArrayType(type)
    ELSIF sym = OM4S.record THEN
      OM4S.Get(sym); RecordType(type); Check(OM4S.end, "no END")
    ELSIF sym = OM4S.pointer THEN
      OM4S.Get(sym); Check(OM4S.to, "no TO");
      NEW(type);  type.form := OM4B.Pointer; type.size := OM4G.WordSize; type.base := OM4B.intType;
      IF sym = OM4S.ident THEN
        obj := OM4B.thisObj();
        IF obj # NIL THEN
          IF (obj.class = OM4B.Typ) & (obj.type.form IN {OM4B.Record, OM4B.NoTyp}) THEN
            CheckRecLevel(obj.lev); type.base := obj.type
          ELSIF obj.class = OM4B.Mod THEN OM4S.Mark("external base type not implemented")
          ELSE OM4S.Mark("no valid base type")
          END
        ELSE CheckRecLevel(level); (*enter into list of forward references to be fixed in Declarations*)
          NEW(ptbase); OM4S.CopyId(ptbase.name); ptbase.type := type; ptbase.next := pbsList; pbsList := ptbase
        END ;
        OM4S.Get(sym)
      ELSE Type(type.base);
        IF (type.base.form # OM4B.Record) OR (type.base.typobj = NIL) THEN OM4S.Mark("must point to named record") END ;
        CheckRecLevel(level)
      END
    ELSIF sym = OM4S.procedure THEN
      OM4S.Get(sym); OM4B.OpenScope;
      NEW(type); type.form := OM4B.Proc; type.size := OM4G.WordSize; dmy := 0;
      ProcedureType(type, dmy); type.dsc := OM4B.topScope.next; OM4B.CloseScope
    ELSE OM4S.Mark("illegal type")
    END
  END Type0;

  PROCEDURE containsPointer(type: OM4B.Type): BOOLEAN;
    VAR obj!: OM4B.Object; res: BOOLEAN;
  BEGIN
    (*ASSERT(Type.form = OM4B.Record);*)
    obj := type.dsc; res := FALSE;
    WHILE ~res & (obj # NIL) DO 
      IF obj.type.form = OM4B.Record THEN res := containsPointer(obj.type)
      ELSIF (obj.type.form = OM4B.Pointer) OR (obj.type.form = OM4B.NilTyp) THEN res := TRUE
      END;
      obj := obj.next
    END;
    RETURN res
  END containsPointer;

  PROCEDURE Declarations(VAR varsize: LONGINT);
    VAR obj!, first!: OM4B.Object;
      x!: OM4G.Item; tp!: OM4B.Type; ptbase!: PtrBase;
      expo, unsafe, umm, umf: BOOLEAN; id: OM4S.Ident;
  BEGIN (*sync*) pbsList := NIL;
    IF (sym < OM4S.const) & (sym # OM4S.end) & (sym # OM4S.return) THEN OM4S.Mark("declaration?");
      REPEAT OM4S.Get(sym) UNTIL (sym >= OM4S.const) OR (sym = OM4S.end) OR (sym = OM4S.return)
    END ;
    IF sym = OM4S.const THEN
      OM4S.Get(sym);
      WHILE sym = OM4S.ident DO
        OM4S.CopyId(id); OM4S.Get(sym); CheckExport(expo);
        IF sym = OM4S.eql THEN OM4S.Get(sym) ELSE OM4S.Mark("= ?") END;
        expression(x);
        IF (x.type.form = OM4B.String) & (x.b = 2) THEN OM4G.StrToChar(x) END ;
        OM4B.NewObj(obj, id, OM4B.Const); obj.expo := expo;
        IF x.mode = OM4B.Const THEN obj.val := x.a; obj.lev := x.b; obj.type := x.type
        ELSE OM4S.Mark("expression not constant"); obj.type := OM4B.intType
        END;
        Check(OM4S.semicolon, "; missing")
      END
    END ;
    IF sym = OM4S.type THEN
      OM4S.Get(sym);
      WHILE sym = OM4S.ident DO
        OM4S.CopyId(id); OM4S.Get(sym); CheckExport(expo);
        IF sym = OM4S.eql THEN OM4S.Get(sym) ELSE OM4S.Mark("=?") END ;
        Type(tp);
        OM4B.NewObj(obj, id, OM4B.Typ); obj.type := tp; obj.expo := expo; obj.lev := level;
        IF tp.typobj = NIL THEN tp.typobj := obj END ;
        IF expo & (obj.type.form = OM4B.Record) THEN obj.exno := exno; INC(exno) ELSE obj.exno := 0 END ;
        IF tp.form = OM4B.Record THEN
          ptbase := pbsList;  (*check whether this is base of a pointer type; search and fixup*)
          WHILE ptbase # NIL DO
            IF obj.name = ptbase.name THEN ptbase.type.base := obj.type END ;
            ptbase := ptbase.next
          END ;
          IF level = 0 THEN OM4G.BuildTD(tp, dc) END    (*type descriptor; len used as its address*)
        END ;
        Check(OM4S.semicolon, "; missing")
      END
    END ;
    IF sym = OM4S.var THEN
      OM4S.Get(sym);
      WHILE sym = OM4S.ident DO
        IdentList(OM4B.Var, first); Type(tp);
        (*check for unsafe pointers*)
        unsafe := FALSE;
        IF level # 0 THEN
          IF tp.form = OM4B.Pointer THEN unsafe := TRUE
          ELSIF tp.form = OM4B.Record THEN unsafe := containsPointer(tp)
          END
        END;
        obj := first; umm := FALSE; umf := FALSE;
        WHILE obj # NIL DO
          IF unsafe & ~obj.unsafe THEN umm := TRUE END;
          IF ~unsafe & obj.unsafe THEN umf := TRUE END;
          obj.type := tp; obj.lev := level;
          IF tp.size > 1 THEN varsize := (varsize + 3) DIV 4 * 4 (*align*) END ;
          obj.val := varsize; varsize := varsize + obj.type.size;
          IF obj.expo THEN obj.exno := exno; INC(exno) END ;
          obj := obj.next
        END ;
        IF umm THEN OM4S.Mark("mark unsafe vars with an exclamation mark") 
        ELSIF umf THEN OM4S.Mark("remove exclamation mark") END;
        Check(OM4S.semicolon, "; missing")
      END
    END ;
    varsize := (varsize + 3) DIV 4 * 4;
    ptbase := pbsList;
    WHILE ptbase # NIL DO
      IF ptbase.type.base.form = OM4B.Int THEN OM4S.Mark("undefined pointer base of") END ;
      ptbase := ptbase.next
    END ;
    IF (sym >= OM4S.const) & (sym <= OM4S.var) THEN OM4S.Mark("declaration in bad order") END
  END Declarations;

  PROCEDURE ProcedureDecl;
    VAR proc!: OM4B.Object;
      type!: OM4B.Type;
      procid: OM4S.Ident;
      x!: OM4G.Item;
      locblksize, parblksize, L: LONGINT;
      int: BOOLEAN; reglim: INTEGER;
  BEGIN (* ProcedureDecl *) int := FALSE; OM4S.Get(sym); 
    IF sym = OM4S.times THEN OM4S.Get(sym); int := TRUE END ;
    IF sym = OM4S.arrow THEN OM4S.Get(sym); reglim := OM4S.ival; Check(OM4S.int, "missing register limit");
    ELSE reglim := -1
    END;
    IF sym = OM4S.ident THEN
      OM4S.CopyId(procid); OM4S.Get(sym);
      OM4B.NewObj(proc, OM4S.id, OM4B.Const);
      parblksize := 4;
      NEW(type); type.form := OM4B.Proc; type.size := OM4G.WordSize;
      proc.type := type; proc.val := -1; proc.lev := level; 
      CheckExport(proc.expo);
      IF proc.expo THEN proc.exno := exno; INC(exno) END ;
      OM4B.OpenScope; INC(level); type.base := OM4B.noType;
      ProcedureType(type, parblksize);  (*formal parameter list*)
      Check(OM4S.semicolon, "no ;"); locblksize := parblksize; 
      Declarations(locblksize);
      proc.val := OM4G.Here(); 
      proc.type.dsc := OM4B.topScope.next;
      IF sym = OM4S.procedure THEN
        L := 0; OM4G.FJump(L);
        REPEAT ProcedureDecl; Check(OM4S.semicolon, "no ;") UNTIL sym # OM4S.procedure;
        OM4G.FixOne(L); proc.val := OM4G.Here(); proc.type.dsc := OM4B.topScope.next
      END ;
      OM4G.Enter(parblksize, locblksize, int, reglim);
      IF sym = OM4S.begin THEN OM4S.Get(sym); StatSequence END ;
      IF sym = OM4S.return THEN
        OM4S.Get(sym); expression(x);
        IF type.base = OM4B.noType THEN OM4S.Mark("this is not a function")
        ELSIF ~CompTypes(type.base, x.type, FALSE) THEN OM4S.Mark("wrong result type")
        END
      ELSIF type.base.form # OM4B.NoTyp THEN
        OM4S.Mark("function without result"); type.base := OM4B.noType
      END ;
      OM4G.Return(type.base.form, x, locblksize, reglim);
      OM4B.CloseScope; DEC(level); Check(OM4S.end, "no END");
      IF sym = OM4S.ident THEN
        IF OM4S.id # procid THEN OM4S.Mark("no match") END ;
        OM4S.Get(sym)
      ELSE OM4S.Mark("no proc id")
      END
    ELSE OM4S.Mark("proc id expected")
    END
  END ProcedureDecl;

  PROCEDURE Import;
    VAR impid, impid1: OM4S.Ident;
  BEGIN
    IF sym = OM4S.ident THEN
      OM4S.CopyId(impid); OM4S.Get(sym);
      IF sym = OM4S.becomes THEN
        OM4S.Get(sym);
        IF sym = OM4S.ident THEN OM4S.CopyId(impid1); OM4S.Get(sym)
        ELSE OM4S.Mark("id expected"); impid1 := impid
        END
      ELSE impid1 := impid
      END ;
      OM4B.Import(impid, impid1)
    ELSE OM4S.Mark("id expected")
    END
  END Import;

  PROCEDURE Module;
    VAR key: LONGINT; oldCol: INTEGER;
  BEGIN Texts.WriteString(W, "  compiling "); OM4S.Get(sym);
    IF sym = OM4S.module THEN
      OM4S.Get(sym);
      IF sym = OM4S.times THEN version := 0; dc := 8; Texts.Write(W, "*"); OM4S.Get(sym) ELSE dc := 0; version := 1 END ;
      OM4B.Init; OM4B.OpenScope;
      IF sym = OM4S.ident THEN
        OM4S.CopyId(modid); OM4S.Get(sym);
        Texts.WriteString(W, modid); Texts.Append(Oberon.Log, W.buf)
      ELSE OM4S.Mark("identifier expected")
      END ;
      Check(OM4S.semicolon, "no ;"); level := 0; exno := 1; key := 0;
      IF sym = OM4S.import THEN
        OM4S.Get(sym); Import;
        WHILE sym = OM4S.comma DO OM4S.Get(sym); Import END ;
        Check(OM4S.semicolon, "; missing")
      END ;
      OM4G.Open(version); Declarations(dc); OM4G.SetDataSize((dc + 3) DIV 4 * 4);
      WHILE sym = OM4S.procedure DO ProcedureDecl; Check(OM4S.semicolon, "no ;") END ;
      OM4G.Header;
      IF sym = OM4S.begin THEN OM4S.Get(sym); StatSequence END ;
      Check(OM4S.end, "no END");
      IF sym = OM4S.ident THEN
        IF OM4S.id # modid THEN OM4S.Mark("no match") END ;
        OM4S.Get(sym)
      ELSE OM4S.Mark("identifier missing")
      END ;
      IF sym # OM4S.period THEN OM4S.Mark("period missing") END ;
      IF (OM4S.errcnt = 0) & (version # 0) THEN
        OM4B.Export(modid, newSF, key);
        IF newSF THEN Texts.WriteString(W, " new symbol file") END
      END ;
      IF OM4S.errcnt = 0 THEN
        Texts.WriteInt(W, OM4G.Here(), 6); Texts.WriteInt(W, dc, 6); Texts.WriteHex(W, key);
        OM4G.Close(modid, key, exno)
      ELSE Texts.WriteLn(W); oldCol := W.col; W.col := Display.red; Texts.WriteString(W, "compilation FAILED"); W.col := oldCol 
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      OM4B.CloseScope; pbsList := NIL
    ELSE OM4S.Mark("must start with MODULE")
    END
  END Module;

  PROCEDURE Option(VAR S: Texts.Scanner);
  BEGIN newSF := FALSE;
    IF S.nextCh = "/" THEN
      Texts.Scan(S); Texts.Scan(S); 
      IF (S.class = Texts.Name) & (S.s[0] = "s") THEN newSF := TRUE END
    END
  END Option;

  PROCEDURE Compile*;
    VAR beg, end, time: LONGINT;
      T!: Texts.Text;
      S!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Char THEN
      IF S.c = "@" THEN
        Option(S); Oberon.GetSelection(T, beg, end, time);
        IF time >= 0 THEN OM4S.Init(T, beg); Module END
      ELSIF S.c = "^" THEN
        Option(S); Oberon.GetSelection(T, beg, end, time);
        IF time >= 0 THEN
          Texts.OpenScanner(S, T, beg); Texts.Scan(S);
          IF S.class = Texts.Name THEN
            Texts.WriteString(W, S.s); NEW(T); Texts.Open(T, S.s);
            IF T.len > 0 THEN OM4S.Init(T, 0); Module END
          END
        END
      END
    ELSE 
      WHILE S.class = Texts.Name DO
        NEW(T); Texts.Open(T, S.s);
        IF T.len > 0 THEN Option(S); OM4S.Init(T, 0); Module
        ELSE Texts.WriteString(W, S.s); Texts.WriteString(W, " not found");
          Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
        END ;
        IF (T.len # 0) & (OM4S.errcnt = 0) THEN Texts.Scan(S) ELSE S.class := 0 END
      END
    END;
    Oberon.Collect(0)
  END Compile;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4 Compiler  19/10/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
  NEW(dummy); dummy.class := OM4B.Const; dummy.type := OM4B.intType;
  expression := expression0; Type := Type0; FormalType := FormalType0
END OM4P.
