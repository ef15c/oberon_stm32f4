MODULE OM4P; (*N. Wirth 1.7.97 / 8.3.2020,
  C. Schoffit 05.02.25 Oberon compiler for Cortex M4 in Oberon-07*)
  IMPORT Display, Texts, Oberon, S := OM4S, B := OM4B, G := OM4G;
  (*Author: Niklaus Wirth, 2014.
    Parser of Oberon-Cortex M4 compiler. Uses Scanner OM4S to obtain symbols (tokens),
    OM4B for definition of data structures and for handling import and export, and
    OM4G to produce binary code. OM4P performs type checking and data allocation.
    Parser is target-independent, except for part of the handling of allocations.*)
 
  TYPE PtrBase = POINTER TO PtrBaseDesc;
    PtrBaseDesc = RECORD  (*list of names of pointer base types*)
      name: S.Ident; type: B.Type; next: PtrBase
    END ;
  
  VAR sym: INTEGER;   (*last symbol read*)
    vc, cc: INTEGER;    (*variable counter, const counter*)
    level, exno, version: INTEGER;
    newSF, initmode: BOOLEAN;  (*option flag*)
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

  PROCEDURE CheckReal(VAR x: G.Item);
  BEGIN
    IF x.type.form # B.Real THEN S.Mark("not Real"); x.type := B.realType END
  END CheckReal;

  PROCEDURE CheckSet(VAR x: G.Item);
  BEGIN
    IF x.type.form # B.Set THEN S.Mark("not Set"); x.type := B.setType END 
  END CheckSet;

  PROCEDURE CheckSetVal(VAR x: G.Item);
  BEGIN
    IF x.type.form # B.Int THEN S.Mark("not Int"); x.type := B.setType
    ELSIF x.mode = B.Const THEN
      IF (x.a < 0) OR (x.a >= 32) THEN S.Mark("invalid set") END
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
    END ;
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
            CheckInt(y); G.Index(x, y)
          ELSE S.Mark("not an array")
          END
        UNTIL sym # S.comma;
        Check(S.rbrak, "no ]")
      ELSIF sym = S.period THEN S.Get(sym);
        IF sym = S.ident THEN
          IF x.type.form = B.Pointer THEN G.DeRef(x); x.type := x.type.base END ;
          IF x.type.form = B.Record THEN
            obj := B.thisfield(x.type); S.Get(sym);
            IF obj # NIL THEN G.Field(x, obj)
            ELSE S.Mark("undef")
            END
          ELSE S.Mark("not a record"); S.Get(sym)
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
    RETURN (t0 = t1)    (*openarray assignment disallowed in OM4G*)
      OR (t0.form = B.Array) & (t1.form = B.Array) & (t0.base =  t1.base) & (t0.len = t1.len)
      OR (t0.form = B.Record) & (t1.form = B.Record)  & IsExtension(t0, t1)
      OR ~varpar &
        ((t0.form = B.Pointer) & (t1.form = B.Pointer)  & IsExtension(t0.base, t1.base)
        OR (t0.form = B.Proc) & (t1.form = B.Proc) & EqualSignatures(t0, t1)
        OR (t0.form IN {B.Pointer, B.Proc}) & (t1.form = B.NilTyp))
  END CompTypes;

  PROCEDURE StandFunc(VAR x: G.Item; fct: INTEGER; restyp: B.Type);
    VAR y!, z!: G.Item; n, npar: INTEGER;
  BEGIN Check(S.lparen, "no (");
    npar := fct MOD 10; fct := fct DIV 10; expression(x); n := 1;
    IF sym = S.comma THEN S.Get(sym); expression(y); n := 2;
      WHILE sym = S.comma DO S.Get(sym); expression(z); INC(n) END ;
    END;
    Check(S.rparen, "no )");
    IF n = npar THEN
      IF fct = 0 THEN (*ABS*)
        IF x.type.form IN {B.Int, B.Real} THEN G.Abs(x); restyp := x.type ELSE S.Mark("bad type") END
      ELSIF fct = 1 THEN (*ODD*) CheckInt(x); G.Odd(x)
      ELSIF fct = 2 THEN (*FLOOR*) CheckReal(x); G.Floor(x)
      ELSIF fct = 3 THEN (*FLT*) CheckInt(x); G.Float(x)
      ELSIF fct = 4 THEN (*ORD*)
        IF x.type.form <= B.Proc THEN G.Ord(x, restyp)
        ELSIF (x.type.form = B.String) & (x.b = 2) THEN G.StrToChar(x)
        ELSE S.Mark("bad type")
        END
      ELSIF fct = 5 THEN (*CHR*) CheckInt(x); G.Ord(x, restyp)
      ELSIF fct = 6 THEN (*LEN*)
          IF x.type.form = B.Array THEN G.Len(x) ELSE S.Mark("not an array") END
      ELSIF fct IN {7, 8, 9, 10} THEN (*LSL, ASR, ROR, LSR*) CheckInt(y);
        IF x.type.form IN {B.Int, B.Set} THEN G.Shift(fct-7, x, y); restyp := x.type ELSE S.Mark("bad type") END
      ELSIF fct = 11 THEN (*ADC*) G.ADC(x, y)
      ELSIF fct = 12 THEN (*SBC*) G.SBC(x, y)
      ELSIF fct = 13 THEN (*UML*) G.UML(x, y)
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
      ELSIF fct = 20 THEN (*SQRT*) CheckReal(x); G.Sqrt(x)
      ELSIF fct = 21 THEN (*SVC*) CheckConst(x); CheckInt(x); G.SVC(x)
      ELSIF fct = 22 THEN (*Int Compare*)
        CheckInt(x); CheckInt(y); CheckConst(z); CheckInt(z); G.IntCompare(x, y, z)
      ELSIF fct = 23 THEN (*reverse bits*) CheckInt(x); G.Rbit(x)
      ELSIF fct = 24 THEN (*TOSET*) CheckInt(x)
      ELSIF fct = 25 THEN (*count leading zeros*) CheckInt(x); G.Clz(x)
      ELSIF fct = 26 THEN (*exclusive OR*); G.XOR(x, y); restyp := x.type
      END ;
      x.type := restyp
    ELSE S.Mark("wrong nof params")
    END
  END StandFunc;

  PROCEDURE lvalue(VAR x: G.Item);
    VAR obj!: B.Object;
  BEGIN
    IF sym = S.ident THEN qualident(obj); IF initmode & (obj.lev = 0) THEN obj.rdo := FALSE END;
      IF obj.class = B.SFunc THEN StandFunc(x, obj.val, obj.type)
      ELSE G.MakeItem(x, obj, level);
        IF x.mode = B.SProc THEN S.Mark("not assignable") ELSE selector(x) END
      END
    ELSE S.Mark("not assignable")
    END
   END lvalue;

  PROCEDURE Parameter(par: B.Object);
    VAR x!: G.Item; varpar: BOOLEAN;
  BEGIN
    IF par # NIL THEN
      varpar := par.class = B.Par;
      IF varpar & (sym = S.ident) THEN lvalue(x) ELSE expression(x) END;
      IF CompTypes(par.type, x.type, varpar) THEN
        IF ~varpar THEN G.ValueParam(x, par.type)
        ELSE (*par.class = Par*)
          IF ~par.rdo THEN CheckReadOnly(x) END ;
          G.VarParam(x, par.type)
        END
      ELSIF (x.type.form = B.Array) & (par.type.form = B.Array) &
          (x.type.base = par.type.base) & (par.type.len < 0) THEN
        IF ~par.rdo THEN CheckReadOnly(x) END ;
        G.OpenArrayParam(x)
      ELSIF (x.type.form = B.String) & varpar & par.rdo & (par.type.form = B.Array) & 
          (par.type.base.form = B.Char) & (par.type.len < 0) THEN G.StringParam(x)
      ELSIF ~varpar & (par.type.form = B.Int) & (x.type.form = B.Int) THEN G.ValueParam(x, par.type)  (*BYTE*)
      ELSIF (x.type.form = B.String) & (x.b = 2) & (par.class = B.Var) & (par.type.form = B.Char) THEN
        G.StrToChar(x); G.ValueParam(x, par.type)
      ELSIF (par.type.form = B.Array) & (par.type.base = B.byteType) & 
          (par.type.len >= 0) & (par.type.size = x.type.size) THEN
        G.VarParam(x, par.type)
      ELSE S.Mark("incompatible parameters")
      END
    ELSE expression(x)
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
    END ;
    IF n < x.type.nofpar THEN S.Mark("too few params")
    ELSIF n > x.type.nofpar THEN S.Mark("too many params")
    END
  END ParamList;

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
    VAR obj!: B.Object; rx, sx: INTEGER;
  BEGIN (*sync*)
    IF (sym < S.char) OR (sym > S.ident) THEN S.Mark("expression expected");
      REPEAT S.Get(sym) UNTIL (sym >= S.char) & (sym <= S.for) OR (sym >= S.then)
    END ;
    IF sym = S.ident THEN
      qualident(obj); IF initmode & (obj.lev = 0) THEN obj.rdo := FALSE END;
      IF obj.class = B.SFunc THEN StandFunc(x, obj.val, obj.type)
      ELSE G.MakeItem(x, obj, level); x.dip := TRUE; (* allocate extra register for long int*) selector(x);
        IF sym = S.lparen THEN
          S.Get(sym);
          IF (x.type.form = B.Proc) & (x.type.base.form # B.NoTyp) THEN
            obj.used := TRUE;
            G.PrepCall(x, rx, sx); ParamList(x); G.Call(x, rx, sx); x.type := x.type.base
          ELSE S.Mark("not a function"); ParamList(x)
          END
        END
      END
    ELSIF sym = S.int THEN G.MakeConstItem(x, B.intType, S.ival); S.Get(sym)
    ELSIF sym = S.long THEN G.MakeConstItem(x, B.longintType, S.ival); S.Get(sym)
    ELSIF sym = S.real THEN G.MakeRealItem(x, S.rval); S.Get(sym)
    ELSIF sym = S.char THEN G.MakeConstItem(x, B.charType, S.ival); S.Get(sym)
    ELSIF sym = S.nil THEN S.Get(sym); G.MakeConstItem(x, B.nilType, 0)
    ELSIF sym = S.string THEN G.MakeStringItem(x); S.Get(sym)
    ELSIF sym = S.lparen THEN S.Get(sym); expression(x); Check(S.rparen, "no )")
    ELSIF sym = S.lbrace THEN S.Get(sym); set(x); Check(S.rbrace, "no }")
    ELSIF sym = S.not THEN S.Get(sym); factor(x); CheckBool(x); G.Not(x)
    ELSIF sym = S.false THEN S.Get(sym); G.MakeConstItem(x, B.boolType, 0)
    ELSIF sym = S.true THEN S.Get(sym); G.MakeConstItem(x, B.boolType, 1)
    ELSE S.Mark("not a factor"); S.Get(sym); G.MakeConstItem(x, B.intType, 0)
    END
  END factor;

  PROCEDURE term(VAR x: G.Item);
    VAR y!: G.Item; op, f: INTEGER;
  BEGIN factor(x); f := x.type.form;
    WHILE (sym >= S.times) & (sym <= S.and) DO
      op := sym; S.Get(sym);
      IF op = S.times THEN
        IF f = B.Int THEN factor(y); CheckInt(y); G.MulOp(x, y)
        ELSIF f = B.Real THEN factor(y); CheckReal(y); G.RealOp(op, x, y)
        ELSIF f = B.Set THEN factor(y); CheckSet(y); G.SetOp(op, x, y)
        ELSE S.Mark("bad type")
        END
      ELSIF (op = S.div) OR (op = S.mod) THEN
        CheckInt(x); factor(y); CheckInt(y); G.DivOp(op, x, y)
      ELSIF op = S.rdiv THEN
        IF f = B.Real THEN factor(y); CheckReal(y); G.RealOp(op, x, y)
        ELSIF f = B.Set THEN factor(y); CheckSet(y); G.SetOp(op, x, y)
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
      IF x.type.form IN {B.Int, B.Real, B.Set} THEN G.Neg(x) ELSE CheckInt(x) END
    ELSIF sym = S.plus THEN S.Get(sym); term(x);
    ELSE term(x)
    END ;
    WHILE (sym >= S.plus) & (sym <= S.or) DO
      op := sym; S.Get(sym);
      IF op = S.or THEN G.Or1(x); CheckBool(x); term(y); CheckBool(y); G.Or2(x, y)
      ELSIF x.type.form = B.Int THEN term(y); CheckInt(y); G.AddOp(op, x, y)
      ELSIF x.type.form = B.Real THEN term(y); CheckReal(y); G.RealOp(op, x, y)
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
        ELSIF xf = B.Real THEN G.RealRelation(rel, x, y)
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
      END ;
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

  PROCEDURE StandProc(pno: INTEGER);
    VAR nap, npar: INTEGER; (*nof actual/formal parameters*)
      x!, y!, z!: G.Item;
  BEGIN Check(S.lparen, "no (");
    npar := pno MOD 10; pno := pno DIV 10;
    IF pno IN {0..3, 5..7} THEN lvalue(x) ELSE expression(x) END; nap := 1;
    IF sym = S.comma THEN
      S.Get(sym); IF pno = 14 (*LDREG*) THEN 
        CheckConst(x); CheckInt(x); IF x.a < 16 THEN G.SetRH(x.a) END 
      END;
      IF pno IN {7, 10} THEN lvalue(y) ELSE expression(y) END; nap := 2; z.type := B.noType;
      WHILE sym = S.comma DO S.Get(sym); expression(z); INC(nap) END
    ELSE y.type := B.noType
    END ;
    Check(S.rparen, "no )");
    IF (npar = nap) OR (pno IN {0, 1}) THEN 
      IF pno IN {0, 1} THEN (*INC, DEC*)
        CheckInt(x); CheckReadOnly(x);
        IF y.type # B.noType THEN CheckInt(y) END ;
        G.Increment(pno, x, y)
      ELSIF pno IN {2, 3} THEN (*INCL, EXCL*)
        CheckSet(x); CheckReadOnly(x); CheckInt(y); G.Include(pno-2, x, y)
      ELSIF pno = 4 THEN CheckBool(x); G.Assert(x)
      ELSIF pno = 5 THEN(*NEW*) CheckReadOnly(x);
         IF (x.type.form = B.Pointer) & (x.type.base.form = B.Record) THEN G.New(x)
         ELSE S.Mark("not a pointer to record")
         END
      ELSIF pno = 6 THEN CheckReal(x); CheckInt(y); CheckReadOnly(x); G.Pack(x, y)
      ELSIF pno = 7 THEN CheckReal(x); CheckInt(y); CheckReadOnly(x); G.Unpk(x, y)
      ELSIF pno = 8 THEN
        IF x.type.form <= B.Set THEN G.Led(x) ELSE S.Mark("bad type") END
      ELSIF pno = 10 THEN CheckInt(x); G.Get(x, y)
      ELSIF pno = 11 THEN CheckInt(x); G.Put(x, y)
      ELSIF pno = 12 THEN CheckInt(x); CheckInt(y); CheckInt(z); G.Copy(x, y, z)
      ELSIF pno = 14 THEN G.LDREG(x, y)
      ELSIF pno = 15 THEN CheckConst(x); CheckInt(x); G.MBI(x.a) (*Memory barrier instructions*)
      ELSIF pno = 16 THEN CheckConst(x); CheckInt(x); G.Jump(x.a) (*Jump to absolute address*)
      END
    ELSE S.Mark("wrong nof parameters")
    END
  END StandProc;

  PROCEDURE StatSequence;
    VAR obj!: B.Object;
      orgtype!: B.Type; (*original type of case var*)
      x!, y!, z!, w!: G.Item;
      L0, L1, rx, sx: INTEGER;

    PROCEDURE TypeCase(obj: B.Object; VAR x: G.Item);
      VAR typobj!: B.Object;
    BEGIN
      G.MakeItem(x, obj, level);
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
              obj.used := TRUE;
              G.PrepCall(x, rx, sx); ParamList(x); G.Call(x, rx, sx)
            ELSE S.Mark("not a procedure"); ParamList(x)
            END
          ELSIF x.type.form = B.Proc THEN (*procedure call without parameters*)
            IF x.type.nofpar > 0 THEN S.Mark("missing parameters") END ;
            IF x.type.base.form = B.NoTyp THEN 
              obj.used := TRUE;
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
            END ;
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
    VAR x!: G.Item; typ!: B.Type; len: INTEGER;
  BEGIN NEW(typ); typ.form := B.NoTyp;
    expression(x);
    IF (x.mode = B.Const) & (x.type.form = B.Int) & (x.a >= 0) THEN len := x.a
    ELSE len := 1; S.Mark("not a valid length")
    END ;
    IF sym = S.of THEN S.Get(sym); Type(typ.base);
      IF (typ.base.form = B.Array) & (typ.base.len < 0) THEN S.Mark("dyn array not allowed") END
    ELSIF sym = S.comma THEN S.Get(sym); ArrayType(typ.base)
    ELSE S.Mark("missing OF"); typ.base := B.intType
    END ;
    typ.size := (len * typ.base.size + 3) DIV 4 * 4;
    typ.form := B.Array; typ.len := len; type := typ
  END ArrayType;

  PROCEDURE RecordType(VAR type: B.Type);
    VAR obj!, obj0!, new!, bot!, base!: B.Object;
      typ!, tp!: B.Type;
      offset, off, n: INTEGER;
  BEGIN NEW(typ); typ.form := B.NoTyp; typ.base := NIL; typ.mno := -level; typ.nofpar := 0; offset := 0; bot := NIL;
    IF sym = S.lparen THEN
      S.Get(sym); (*record extension*)
      IF level # 0 THEN S.Mark("extension of local types not implemented") END ;
      IF sym = S.ident THEN
        qualident(base);
        IF base.class = B.Typ THEN
          IF base.type.form = B.Record THEN typ.base := base.type
          ELSE typ.base := B.intType; S.Mark("invalid extension")
          END ;
          typ.nofpar := typ.base.nofpar + 1; (*"nofpar" here abused for extension level*)
          bot := typ.base.dsc; offset := typ.base.size
        ELSE S.Mark("type expected")
        END
      ELSE S.Mark("ident expected")
      END ;
      Check(S.rparen, "no )")
    END ;
    WHILE sym = S.ident DO  (*fields*)
      n := 0; obj := bot;
      WHILE sym = S.ident DO
        obj0 := obj;
        WHILE (obj0 # NIL) & (obj0.name # S.id) DO obj0 := obj0.next END ;
        IF obj0 # NIL THEN S.Mark("mult def") END ;
        NEW(new); S.CopyId(new.name); new.class := B.Fld; new.next := obj; obj := new; INC(n);
        S.Get(sym); CheckExport(new.expo);
        IF (sym # S.comma) & (sym # S.colon) THEN S.Mark("comma expected")
        ELSIF sym = S.comma THEN S.Get(sym)
        END
      END ;
      Check(S.colon, "colon expected"); Type(tp);
      IF (tp.form = B.Array) & (tp.len < 0) THEN S.Mark("dyn array not allowed") END ;
      IF tp.size > 1 THEN offset := (offset+3) DIV 4 * 4 END ;
      offset := offset + n * tp.size; off := offset; obj0 := obj;
      WHILE obj0 # bot DO obj0.type := tp; obj0.lev := 0; off := off - tp.size; obj0.val := off; obj0 := obj0.next END ;
      bot := obj;
      IF sym = S.semicolon THEN S.Get(sym) ELSIF sym # S.end THEN S.Mark(" ; or END") END
    END ;
    typ.form := B.Record; typ.dsc := bot; typ.size := (offset + 3) DIV 4 * 4; type := typ
  END RecordType;

  PROCEDURE FPSection(VAR adr: INTEGER; VAR nofpar: INTEGER);
    VAR obj!, first!: B.Object; tp!: B.Type;
      parsize: INTEGER; cl: INTEGER; rdo: BOOLEAN;
  BEGIN
    IF sym = S.var THEN S.Get(sym); cl := B.Par ELSE cl := B.Var END ;
    IdentList(cl, first); FormalType(tp, 0); rdo := FALSE;
    IF (cl = B.Var) & (tp.form IN {B.Array, B.Record}) THEN cl := B.Par; rdo := TRUE END ;
    IF (tp.form = B.Array) & (tp.len < 0) OR (G.check & (tp.form = B.Record)) THEN
      parsize := 2*G.WordSize  (*open array or record, needs second word for length or type tag*)
    ELSIF G.isLongint(tp) & (cl = B.Var) THEN parsize := 2*G.WordSize
    ELSE parsize := G.WordSize
    END ;
    obj := first;
    WHILE obj # NIL DO
      INC(nofpar); obj.class := cl; obj.type := tp; obj.rdo := rdo; obj.lev := level; obj.val := adr;
      adr := adr + parsize; obj := obj.next
    END ;
    IF adr > 52 THEN S.Mark("too many parameters") END
  END FPSection;

  PROCEDURE ProcedureType(ptype: B.Type; VAR parblksize: INTEGER);
    VAR obj!: B.Object; size, nofpar: INTEGER;
  BEGIN ptype.base := B.noType; size := parblksize; nofpar := 0; ptype.dsc := NIL;
    IF sym = S.lparen THEN
      S.Get(sym);
      IF sym = S.rparen THEN S.Get(sym)
      ELSE FPSection(size, nofpar);
        WHILE sym = S.semicolon DO S.Get(sym); FPSection(size, nofpar) END ;
        Check(S.rparen, "no )")
      END ;
      IF sym = S.colon THEN  (*function*)
        S.Get(sym);
        IF sym = S.ident THEN
          qualident(obj); ptype.base := obj.type;
          IF ~((obj.class = B.Typ) & (obj.type.form IN {B.Byte .. B.Pointer, B.Proc})) THEN
            S.Mark("illegal function type")
          END
        ELSE S.Mark("type identifier expected")
        END
      END
    END ;
    ptype.nofpar := nofpar; parblksize := size
  END ProcedureType;

  PROCEDURE FormalType0(VAR typ: B.Type; dim: INTEGER);
    VAR obj!: B.Object; dmy: INTEGER;
  BEGIN
    IF sym = S.ident THEN
      qualident(obj);
      IF obj.class = B.Typ THEN typ := obj.type ELSE S.Mark("not a type"); typ := B.intType END
    ELSIF sym = S.array THEN
      S.Get(sym); Check(S.of, "OF ?");
      IF dim >= 1 THEN S.Mark("multi-dimensional open arrays not implemented") END ;
      NEW(typ); typ.form := B.Array; typ.len := -1; typ.size := 2*G.WordSize; 
      FormalType(typ.base, dim+1)
    ELSIF sym = S.procedure THEN
      S.Get(sym); B.OpenScope;
      NEW(typ); typ.form := B.Proc; typ.size := G.WordSize; dmy := 0; ProcedureType(typ, dmy);
      typ.dsc := B.topScope.next; B.CloseScope
    ELSE S.Mark("identifier expected"); typ := B.noType
    END
  END FormalType0;

  PROCEDURE CheckRecLevel(lev: INTEGER);
  BEGIN
    IF lev # 0 THEN S.Mark("ptr base must be global") END
  END CheckRecLevel;

  PROCEDURE Type0(VAR type: B.Type);
    VAR dmy: INTEGER; obj!: B.Object; ptbase!: PtrBase;
  BEGIN type := B.intType; (*sync*)
    IF (sym # S.ident) & (sym < S.array) THEN S.Mark("not a type");
      REPEAT S.Get(sym) UNTIL (sym = S.ident) OR (sym >= S.array)
    END ;
    IF sym = S.ident THEN
      qualident(obj);
      IF obj.class = B.Typ THEN
        IF (obj.type # NIL) & (obj.type.form # B.NoTyp) THEN type := obj.type END
      ELSE S.Mark("not a type or undefined")
      END
    ELSIF sym = S.array THEN S.Get(sym); ArrayType(type)
    ELSIF sym = S.record THEN
      S.Get(sym); RecordType(type); Check(S.end, "no END")
    ELSIF sym = S.pointer THEN
      S.Get(sym); Check(S.to, "no TO");
      NEW(type);  type.form := B.Pointer; type.size := G.WordSize; type.base := B.intType;
      IF sym = S.ident THEN
        obj := B.thisObj();
        IF obj # NIL THEN
          IF (obj.class = B.Typ) & (obj.type.form IN {B.Record, B.NoTyp}) THEN
            CheckRecLevel(obj.lev); type.base := obj.type
          ELSIF obj.class = B.Mod THEN S.Mark("external base type not implemented")
          ELSE S.Mark("no valid base type")
          END
        ELSE CheckRecLevel(level); (*enter into list of forward references to be fixed in Declarations*)
          NEW(ptbase); S.CopyId(ptbase.name); ptbase.type := type; ptbase.next := pbsList; pbsList := ptbase
        END ;
        S.Get(sym)
      ELSE Type(type.base);
        IF (type.base.form # B.Record) OR (type.base.typobj = NIL) THEN S.Mark("must point to named record") END ;
        CheckRecLevel(level)
      END
    ELSIF sym = S.procedure THEN
      S.Get(sym); B.OpenScope;
      NEW(type); type.form := B.Proc; type.size := G.WordSize; dmy := 0;
      ProcedureType(type, dmy); type.dsc := B.topScope.next; B.CloseScope
    ELSE S.Mark("illegal type")
    END
  END Type0;

  PROCEDURE containsPointer(type: B.Type): BOOLEAN;
    VAR obj!: B.Object; res: BOOLEAN;
  BEGIN res := FALSE;
    IF type.form = B.Pointer THEN res := TRUE
    ELSIF type.form = B.Record THEN obj := type.dsc;
      WHILE ~res & (obj # NIL) DO 
        IF obj.type.form = B.NilTyp (*hidden pointer*) THEN res := TRUE
        ELSE res := containsPointer(obj.type)
        END;
        obj := obj.next
      END
    ELSIF type.form = B.Array THEN res := containsPointer(type.base)
    END
    RETURN res
  END containsPointer;

  PROCEDURE Declarations(VAR varsize: INTEGER);
    VAR obj!, first!: B.Object;
      x!: G.Item; tp!: B.Type; ptbase!: PtrBase;
      expo, unsafe, umm, umf, onetimeinit: BOOLEAN; id: S.Ident;
  BEGIN (*sync*) pbsList := NIL;
    IF (sym < S.const) & (sym # S.end) & (sym # S.return) THEN S.Mark("declaration?");
      REPEAT S.Get(sym) UNTIL (sym >= S.const) OR (sym = S.end) OR (sym = S.return)
    END ;
    IF sym = S.const THEN
      S.Get(sym);
      WHILE sym = S.ident DO
        S.CopyId(id); S.Get(sym); CheckExport(expo);
        IF sym = S.eql THEN S.Get(sym) ELSE S.Mark("= ?") END;
        expression(x);
        IF (x.type.form = B.String) & (x.b = 2) THEN G.StrToChar(x) END ;
        B.NewObj(obj, id, B.Const); obj.expo := expo;
        IF x.mode = B.Const THEN
          IF x.type.form = B.String THEN ASSERT(x.a < 10000H); ASSERT(x.b < 10000H); IF obj.expo THEN obj.exno := exno; INC(exno) END;
            obj.lev := x.r; obj.val := x.a MOD 10000H + x.b*10000H; (*for strings constants, encode address and length in obj.val*)
          ELSE obj.val := x.a
          END; obj.type := x.type
        ELSE S.Mark("expression not constant"); obj.type := B.intType
        END;
        Check(S.semicolon, "; missing")
      END
    END ;
    IF sym = S.type THEN
      S.Get(sym);
      WHILE sym = S.ident DO
        S.CopyId(id); S.Get(sym); CheckExport(expo);
        IF sym = S.eql THEN S.Get(sym) ELSE S.Mark("=?") END ;
        Type(tp);
        B.NewObj(obj, id, B.Typ); obj.type := tp; obj.expo := expo; obj.lev := level;
        IF tp.typobj = NIL THEN tp.typobj := obj END ;
        IF expo & (obj.type.form = B.Record) THEN obj.exno := exno; INC(exno) ELSE obj.exno := 0 END ;
        IF tp.form = B.Record THEN
          ptbase := pbsList;  (*check whether this is base of a pointer type; search and fixup*)
          WHILE ptbase # NIL DO
            IF obj.name = ptbase.name THEN ptbase.type.base := obj.type END ;
            ptbase := ptbase.next
          END ;
          IF level = 0 THEN G.BuildTD(tp, cc) END    (*type descriptor; len used as its address*)
        END ;
        Check(S.semicolon, "; missing")
      END
    END ;
    IF sym = S.var THEN
      S.Get(sym);
      WHILE sym = S.ident DO onetimeinit := FALSE;
        IdentList(B.Var, first); Type(tp);
        IF sym = S.minus THEN
          IF level = 0 THEN onetimeinit := TRUE
          ELSE S.Mark("remove hyphen")
          END; S.Get(sym) 
        END;
        IF level = 0 THEN unsafe := FALSE ELSE unsafe := containsPointer(tp) END; (*check for unsafe pointers*)
        obj := first; umm := FALSE; umf := FALSE;
        WHILE obj # NIL DO
          IF unsafe & ~obj.unsafe THEN umm := TRUE END;
          IF ~unsafe & obj.unsafe THEN umf := TRUE END;
          obj.type := tp; obj.lev := level;
          IF tp.size > 1 THEN varsize := (varsize + 3) DIV 4 * 4 (*align*) END ;
          obj.val := varsize; varsize := varsize + obj.type.size;
          IF obj.expo THEN obj.exno := exno; INC(exno) END ;
          IF onetimeinit THEN obj.rdo := TRUE END;
          obj := obj.next
        END ;
        IF umm THEN S.Mark("mark unsafe vars with an exclamation mark") 
        ELSIF umf THEN S.Mark("remove exclamation mark") END;
        Check(S.semicolon, "; missing")
      END
    END ;
    varsize := (varsize + 3) DIV 4 * 4;
    ptbase := pbsList;
    WHILE ptbase # NIL DO
      IF ptbase.type.base.form = B.Int THEN S.Mark("undefined pointer base of") END ;
      ptbase := ptbase.next
    END ;
    IF (sym >= S.const) & (sym <= S.var) THEN S.Mark("declaration in bad order") END
  END Declarations;

  PROCEDURE ProcedureDecl;
    VAR proc!: B.Object;
      type!: B.Type;
      procid: S.Ident;
      x!: G.Item;
      locblksize, parblksize, L: INTEGER;
      int: BOOLEAN; reglim: INTEGER;
  BEGIN (* ProcedureDecl *) int := FALSE; S.Get(sym); 
    IF sym = S.times THEN S.Get(sym); int := TRUE END ;
    IF sym = S.arrow THEN S.Get(sym); reglim := S.ival; Check(S.int, "missing register limit");
    ELSE reglim := -1
    END;
    IF sym = S.ident THEN
      S.CopyId(procid); S.Get(sym);
      B.NewObj(proc, S.id, B.Const);
      parblksize := 4;
      NEW(type); type.form := B.Proc; type.size := G.WordSize;
      proc.type := type; proc.lev := level; 
      CheckExport(proc.expo);
      IF proc.expo THEN proc.exno := exno; INC(exno) END ;
      B.OpenScope; INC(level); type.base := B.noType;
      ProcedureType(type, parblksize);  (*formal parameter list*)
      Check(S.semicolon, "no ;"); locblksize := parblksize; 
      Declarations(locblksize);
      proc.val := G.Here(); 
      proc.type.dsc := B.topScope.next;
      IF sym = S.procedure THEN
        L := 0; G.FJump(L);
        REPEAT ProcedureDecl; Check(S.semicolon, "no ;") UNTIL sym # S.procedure;
        G.FixOne(L); proc.val := G.Here(); proc.type.dsc := B.topScope.next
      END ;
      G.Enter(parblksize, locblksize, int, reglim);
      IF sym = S.begin THEN S.Get(sym); StatSequence END ;
      IF sym = S.return THEN
        S.Get(sym); expression(x);
        IF type.base = B.noType THEN S.Mark("this is not a function")
        ELSIF ~CompTypes(type.base, x.type, FALSE) THEN S.Mark("wrong result type")
        END
      ELSIF type.base.form # B.NoTyp THEN
        S.Mark("function without result"); type.base := B.noType
      END ;
      G.Return(type.base.form, x, locblksize, reglim);
      B.CloseScope; DEC(level); Check(S.end, "no END");
      IF sym = S.ident THEN
        IF S.id # procid THEN S.Mark("no match") END ;
        S.Get(sym)
      ELSE S.Mark("no proc id")
      END
    ELSE S.Mark("proc id expected")
    END
  END ProcedureDecl;

  PROCEDURE Import;
    VAR impid, impid1: S.Ident;
  BEGIN
    IF sym = S.ident THEN
      S.CopyId(impid); S.Get(sym);
      IF sym = S.becomes THEN
        S.Get(sym);
        IF sym = S.ident THEN S.CopyId(impid1); S.Get(sym)
        ELSE S.Mark("id expected"); impid1 := impid
        END
      ELSE impid1 := impid
      END ;
      B.Import(impid, impid1)
    ELSE S.Mark("id expected")
    END
  END Import;

  PROCEDURE Module;
    VAR key, oldCol: INTEGER;
  BEGIN Texts.WriteString(W, "  compiling "); S.Get(sym);
    IF sym = S.module THEN
      S.Get(sym); vc := 0; cc := 0;
      IF sym = S.times THEN version := 0; Texts.Write(W, "*"); S.Get(sym) ELSE version := 1 END;
      initmode := FALSE;
      B.Init; B.OpenScope;
      IF sym = S.ident THEN
        S.CopyId(modid); S.Get(sym);
        Texts.WriteString(W, modid); Texts.Append(Oberon.Log, W.buf)
      ELSE S.Mark("identifier expected")
      END ;
      Check(S.semicolon, "no ;"); level := 0; exno := 1; key := 0;
      IF sym = S.import THEN
        S.Get(sym); Import;
        WHILE sym = S.comma DO S.Get(sym); Import END ;
        Check(S.semicolon, "; missing")
      END ;
      G.Open(version); Declarations(vc); G.SetDataSize((vc + 3) DIV 4 * 4, (cc + 3) DIV 4 * 4);
      WHILE sym = S.procedure DO ProcedureDecl; Check(S.semicolon, "no ;") END ;
      initmode := TRUE;
      G.Header;
      IF sym = S.begin THEN S.Get(sym); StatSequence END ;
      Check(S.end, "no END");
      IF sym = S.ident THEN
        IF S.id # modid THEN S.Mark("no match") END ;
        S.Get(sym)
      ELSE S.Mark("identifier missing")
      END ;
      IF sym # S.period THEN S.Mark("period missing") END ;
      IF (S.errcnt = 0) & (version # 0) THEN
        B.Export(modid, newSF, key);
        IF newSF THEN Texts.WriteString(W, " new symbol file") END
      END ;
      IF S.errcnt = 0 THEN
        Texts.WriteInt(W, G.Here(), 6); Texts.WriteInt(W, vc, 8); Texts.WriteInt(W, cc, 8);; Texts.WriteHex(W, key);
        G.Close(modid, key, exno)
      ELSE Texts.WriteLn(W); oldCol := W.col; W.col := Display.red; Texts.WriteString(W, "compilation FAILED"); W.col := oldCol 
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      B.CloseScope; pbsList := NIL
    ELSE S.Mark("must start with MODULE")
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
    VAR beg, end, time: INTEGER;
      T!: Texts.Text;
      S1!: Texts.Scanner;
  BEGIN Texts.OpenScanner(S1, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S1);
    IF S1.class = Texts.Char THEN
      IF S1.c = "@" THEN
        Option(S1); Oberon.GetSelection(T, beg, end, time);
        IF time >= 0 THEN S.Init(T, beg); Module END
      ELSIF S1.c = "^" THEN
        Option(S1); Oberon.GetSelection(T, beg, end, time);
        IF time >= 0 THEN
          Texts.OpenScanner(S1, T, beg); Texts.Scan(S1);
          IF S1.class = Texts.Name THEN
            Texts.WriteString(W, S1.s); NEW(T); Texts.Open(T, S1.s);
            IF T.len > 0 THEN S.Init(T, 0); Module
            ELSE Texts.WriteString(W, " not found");
              Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
            END
          END
        END
      END
    ELSE 
      WHILE S1.class = Texts.Name DO
        NEW(T); Texts.Open(T, S1.s);
        IF T.len > 0 THEN Option(S1); S.Init(T, 0); Module
        ELSE Texts.WriteString(W, S1.s); Texts.WriteString(W, " not found");
          Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
        END ;
        IF (T.len # 0) & (S.errcnt = 0) THEN Texts.Scan(S1) ELSE S1.class := 0 END
      END
    END;
    Oberon.Collect(0)
  END Compile;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4 Compiler  05.02.25");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
  NEW(dummy); dummy.class := B.Var; dummy.type := B.intType; dummy.val := 0;
  expression := expression0; Type := Type0; FormalType := FormalType0
END OM4P.
