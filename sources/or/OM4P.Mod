MODULE OM4P; (*N. Wirth 1.7.97 / 8.3.2020,
  C. Schoffit 19/10/2023 Oberon compiler for Cortex M4 in Oberon-07*)
  IMPORT Display, Texts, Oberon, OM4S, OM4B, OM4G;
  (*Author: Niklaus Wirth, 2014.
    Parser of Oberon-RISC compiler. Uses Scanner OM4S to obtain symbols (tokens),
    OM4B for definition of data structures and for handling import and export, and
    OM4G to produce binary code. OM4P performs type checking and data allocation.
    Parser is target-independent, except for part of the handling of allocations.*)
 
  TYPE PtrBase = POINTER TO PtrBaseDesc;
    PtrBaseDesc = RECORD  (*list of names of pointer base types*)
      name: OM4S.Ident; type: OM4B.Type; next: PtrBase
    END ;
  
  VAR sym: INTEGER;   (*last symbol read*)
    dc: LONGINT;    (*data counter*)
    level, exno, version: INTEGER;
    newSF: BOOLEAN;  (*option flag*)
    expression: PROCEDURE (VAR x: OM4G.Item);  (*to avoid forward reference*)
    Type: PROCEDURE (VAR type: OM4B.Type);
    FormalType: PROCEDURE (VAR typ: OM4B.Type; dim: INTEGER);
    modid: OM4S.Ident;
    pbsList: PtrBase;   (*list of names of pointer base types*)
    dummy: OM4B.Object;
    W: Texts.Writer;

  PROCEDURE Check(s: INTEGER; msg: ARRAY OF CHAR);
  BEGIN
    IF sym = s THEN OM4S.Get(sym) ELSE OM4S.Mark(msg) END
  END Check;

  PROCEDURE qualident(VAR obj: OM4B.Object);
  BEGIN obj := OM4B.thisObj(); OM4S.Get(sym);
    IF obj = NIL THEN OM4S.Mark("undef"); obj := dummy END ;
    IF (sym = OM4S.period) & (obj.class = OM4B.Mod) THEN
      OM4S.Get(sym);
      IF sym = OM4S.ident THEN obj := OM4B.thisimport(obj); OM4S.Get(sym);
        IF obj = NIL THEN OM4S.Mark("undef"); obj := dummy END
      ELSE OM4S.Mark("identifier expected"); obj := dummy
      END
    END
  END qualident;

  PROCEDURE CheckBool(VAR x: OM4G.Item);
  BEGIN
    IF x.type.form # OM4B.Bool THEN OM4S.Mark("not Boolean"); x.type := OM4B.boolType END
  END CheckBool;

  PROCEDURE CheckInt(VAR x: OM4G.Item);
  BEGIN
    IF x.type.form # OM4B.Int THEN OM4S.Mark("not Integer"); x.type := OM4B.intType END
  END CheckInt;

  PROCEDURE CheckReal(VAR x: OM4G.Item);
  BEGIN
    IF x.type.form # OM4B.Real THEN OM4S.Mark("not Real"); x.type := OM4B.realType END
  END CheckReal;

  PROCEDURE CheckSet(VAR x: OM4G.Item);
  BEGIN
    IF x.type.form # OM4B.Set THEN OM4S.Mark("not Set"); x.type := OM4B.setType END 
  END CheckSet;

  PROCEDURE CheckSetVal(VAR x: OM4G.Item);
  BEGIN
    IF x.type.form # OM4B.Int THEN OM4S.Mark("not Int"); x.type := OM4B.setType
    ELSIF x.mode = OM4B.Const THEN
      IF (x.a < 0) OR (x.a >= 32) THEN OM4S.Mark("invalid set") END
    END 
  END CheckSetVal;

  PROCEDURE CheckConst(VAR x: OM4G.Item);
  BEGIN
    IF x.mode # OM4B.Const THEN OM4S.Mark("not a constant"); x.mode := OM4B.Const END
  END CheckConst;

  PROCEDURE CheckReadOnly(VAR x: OM4G.Item);
  BEGIN
    IF x.rdo THEN OM4S.Mark("read-only") END
  END CheckReadOnly;

  PROCEDURE CheckExport(VAR expo: BOOLEAN);
  BEGIN
    IF sym = OM4S.times THEN
      expo := TRUE; OM4S.Get(sym);
      IF level # 0 THEN OM4S.Mark("remove asterisk") END
    ELSE expo := FALSE
    END
  END CheckExport;


  PROCEDURE CheckUnsafeMarking(VAR unsafe: BOOLEAN);
  BEGIN
    IF sym = OM4S.emark THEN
      unsafe := TRUE; OM4S.Get(sym);
      IF level = 0 THEN OM4S.Mark("remove exclamation mark") END
    ELSE unsafe := FALSE
    END
  END CheckUnsafeMarking;

  PROCEDURE IsExtension(t0, t1: OM4B.Type): BOOLEAN;
  BEGIN (*t1 is an extension of t0*)
    RETURN (t0 = t1) OR (t1 # NIL) & IsExtension(t0, t1.base)
  END IsExtension;

  (* expressions *)

  PROCEDURE TypeTest(VAR x: OM4G.Item; T: OM4B.Type; guard: BOOLEAN);
    VAR xt!: OM4B.Type;
  BEGIN xt := x.type;
    IF (T.form = xt.form ) & ((T.form = OM4B.Pointer) OR (T.form = OM4B.Record) & (x.mode = OM4B.Par)) THEN
      WHILE (xt # T) & (xt # NIL) DO xt := xt.base END ;
      IF xt # T THEN xt := x.type;
        IF xt.form = OM4B.Pointer THEN
          IF IsExtension(xt.base, T.base) THEN OM4G.TypeTest(x, T.base, FALSE, guard); x.type := T
          ELSE OM4S.Mark("not an extension")
          END
        ELSIF (xt.form = OM4B.Record) & (x.mode = OM4B.Par) THEN
          IF IsExtension(xt, T) THEN  OM4G.TypeTest(x, T, TRUE, guard); x.type := T
          ELSE OM4S.Mark("not an extension")
          END
        ELSE OM4S.Mark("incompatible types")
        END
      ELSIF ~guard THEN OM4G.TypeTest(x, NIL, FALSE, FALSE)
      END
    ELSE OM4S.Mark("type mismatch")
    END ;
    IF ~guard THEN x.type := OM4B.boolType END
  END TypeTest;

  PROCEDURE selector(VAR x: OM4G.Item);
    VAR y!: OM4G.Item; obj!: OM4B.Object;
  BEGIN
    WHILE (sym = OM4S.lbrak) OR (sym = OM4S.period) OR (sym = OM4S.arrow)
        OR (sym = OM4S.lparen) & (x.type.form IN {OM4B.Record, OM4B.Pointer}) DO
      IF sym = OM4S.lbrak THEN
        REPEAT OM4S.Get(sym); expression(y);
          IF x.type.form = OM4B.Array THEN
            CheckInt(y); OM4G.Index(x, y); x.type := x.type.base
          ELSE OM4S.Mark("not an array")
          END
        UNTIL sym # OM4S.comma;
        Check(OM4S.rbrak, "no ]")
      ELSIF sym = OM4S.period THEN OM4S.Get(sym);
        IF sym = OM4S.ident THEN
          IF x.type.form = OM4B.Pointer THEN OM4G.DeRef(x); x.type := x.type.base END ;
          IF x.type.form = OM4B.Record THEN
            obj := OM4B.thisfield(x.type); OM4S.Get(sym);
            IF obj # NIL THEN OM4G.Field(x, obj); x.type := obj.type
            ELSE OM4S.Mark("undef")
            END
          ELSE OM4S.Mark("not a record")
          END
        ELSE OM4S.Mark("ident?")
        END
      ELSIF sym = OM4S.arrow THEN
        OM4S.Get(sym);
        IF x.type.form = OM4B.Pointer THEN OM4G.DeRef(x); x.type := x.type.base
        ELSE OM4S.Mark("not a pointer")
        END
      ELSIF (sym = OM4S.lparen) & (x.type.form IN {OM4B.Record, OM4B.Pointer}) THEN (*type guard*)
        OM4S.Get(sym);
        IF sym = OM4S.ident THEN
          qualident(obj);
          IF obj.class = OM4B.Typ THEN TypeTest(x, obj.type, TRUE)
          ELSE OM4S.Mark("guard type expected")
          END
        ELSE OM4S.Mark("not an identifier")
        END ;
        Check(OM4S.rparen, " ) missing")
      END
    END
  END selector;

  PROCEDURE EqualSignatures(t0, t1: OM4B.Type): BOOLEAN;
    VAR p0!, p1!: OM4B.Object; com: BOOLEAN;
  BEGIN com := TRUE;
    IF (t0.base = t1.base) & (t0.nofpar = t1.nofpar) THEN
      p0 := t0.dsc; p1 := t1.dsc;
      WHILE p0 # NIL DO
        IF (p0.class = p1.class) &  (p0.rdo = p1.rdo) &
          ((p0.type = p1.type) OR
          (p0.type.form = OM4B.Array) & (p1.type.form = OM4B.Array) & (p0.type.len = p1.type.len) & (p0.type.base = p1.type.base) OR
          (p0.type.form = OM4B.Proc) & (p1.type.form = OM4B.Proc) & EqualSignatures(p0.type, p1.type))
        THEN p0 := p0.next; p1 := p1.next
        ELSE p0 := NIL; com := FALSE
        END
      END
    ELSE com := FALSE
    END ;
    RETURN com
  END EqualSignatures;

  PROCEDURE CompTypes(t0, t1: OM4B.Type; varpar: BOOLEAN): BOOLEAN;
  BEGIN (*check for assignment compatibility*)
    RETURN (t0 = t1)    (*openarray assignment disallowed in OM4G*)
      OR (t0.form = OM4B.Array) & (t1.form = OM4B.Array) & (t0.base =  t1.base) & (t0.len = t1.len)
      OR (t0.form = OM4B.Record) & (t1.form = OM4B.Record)  & IsExtension(t0, t1)
      OR ~varpar &
        ((t0.form = OM4B.Pointer) & (t1.form = OM4B.Pointer)  & IsExtension(t0.base, t1.base)
        OR (t0.form = OM4B.Proc) & (t1.form = OM4B.Proc) & EqualSignatures(t0, t1)
        OR (t0.form IN {OM4B.Pointer, OM4B.Proc}) & (t1.form = OM4B.NilTyp))
  END CompTypes;

  PROCEDURE Parameter(par: OM4B.Object);
    VAR x!: OM4G.Item; varpar: BOOLEAN;
  BEGIN expression(x);
    IF par # NIL THEN
      varpar := par.class = OM4B.Par;
      IF CompTypes(par.type, x.type, varpar) THEN
        IF ~varpar THEN OM4G.ValueParam(x)
        ELSE (*par.class = Par*)
          IF ~par.rdo THEN CheckReadOnly(x) END ;
          OM4G.VarParam(x, par.type)
        END
      ELSIF (x.type.form = OM4B.Array) & (par.type.form = OM4B.Array) &
          (x.type.base = par.type.base) & (par.type.len < 0) THEN
        IF ~par.rdo THEN CheckReadOnly(x) END ;
        OM4G.OpenArrayParam(x)
      ELSIF (x.type.form = OM4B.String) & varpar & par.rdo & (par.type.form = OM4B.Array) & 
          (par.type.base.form = OM4B.Char) & (par.type.len < 0) THEN OM4G.StringParam(x)
      ELSIF ~varpar & (par.type.form = OM4B.Int) & (x.type.form = OM4B.Int) THEN OM4G.ValueParam(x)  (*BYTE*)
      ELSIF (x.type.form = OM4B.String) & (x.b = 2) & (par.class = OM4B.Var) & (par.type.form = OM4B.Char) THEN
        OM4G.StrToChar(x); OM4G.ValueParam(x)
      ELSIF (par.type.form = OM4B.Array) & (par.type.base = OM4B.byteType) & 
          (par.type.len >= 0) & (par.type.size = x.type.size) THEN
        OM4G.VarParam(x, par.type)
      ELSE OM4S.Mark("incompatible parameters")
      END
    END
  END Parameter;

  PROCEDURE ParamList(VAR x: OM4G.Item);
    VAR n: INTEGER; par!: OM4B.Object;
  BEGIN par := x.type.dsc; n := 0;
    IF sym # OM4S.rparen THEN
      Parameter(par); n := 1;
      WHILE sym <= OM4S.comma DO
        Check(OM4S.comma, "comma?");
        IF par # NIL THEN par := par.next END ;
        INC(n); Parameter(par)
      END ;
      Check(OM4S.rparen, ") missing")
    ELSE OM4S.Get(sym);
    END ;
    IF n < x.type.nofpar THEN OM4S.Mark("too few params")
    ELSIF n > x.type.nofpar THEN OM4S.Mark("too many params")
    END
  END ParamList;

  PROCEDURE StandFunc(VAR x: OM4G.Item; fct: LONGINT; restyp: OM4B.Type);
    VAR y!, z!: OM4G.Item; n, npar: LONGINT;
  BEGIN Check(OM4S.lparen, "no (");
    npar := fct MOD 10; fct := fct DIV 10; expression(x); n := 1;
    IF sym = OM4S.comma THEN OM4S.Get(sym); expression(y); n := 2;
      WHILE sym = OM4S.comma DO OM4S.Get(sym); expression(z); INC(n) END ;
    END;
    Check(OM4S.rparen, "no )");
    IF n = npar THEN
      IF fct = 0 THEN (*ABS*)
        IF x.type.form IN {OM4B.Int, OM4B.Real} THEN OM4G.Abs(x); restyp := x.type ELSE OM4S.Mark("bad type") END
      ELSIF fct = 1 THEN (*ODD*) CheckInt(x); OM4G.Odd(x)
      ELSIF fct = 2 THEN (*FLOOR*) CheckReal(x); OM4G.Floor(x)
      ELSIF fct = 3 THEN (*FLT*) CheckInt(x); OM4G.Float(x)
      ELSIF fct = 4 THEN (*ORD*)
        IF x.type.form <= OM4B.Proc THEN OM4G.Ord(x)
        ELSIF (x.type.form = OM4B.String) & (x.b = 2) THEN OM4G.StrToChar(x)
        ELSE OM4S.Mark("bad type")
        END
      ELSIF fct = 5 THEN (*CHR*) CheckInt(x); OM4G.Ord(x)
      ELSIF fct = 6 THEN (*LEN*)
          IF x.type.form = OM4B.Array THEN OM4G.Len(x) ELSE OM4S.Mark("not an array") END
      ELSIF fct IN {7, 8, 9, 10} THEN (*LSL, ASR, ROR, LSR*) CheckInt(y);
        IF x.type.form IN {OM4B.Int, OM4B.Set} THEN OM4G.Shift(fct-7, x, y); restyp := x.type ELSE OM4S.Mark("bad type") END
      ELSIF fct = 11 THEN (*ADC*) OM4G.ADC(x, y)
      ELSIF fct = 12 THEN (*SBC*) OM4G.SBC(x, y)
      ELSIF fct = 13 THEN (*UML*) OM4G.UML(x, y)
      ELSIF fct = 14 THEN (*BIT*) CheckInt(x); CheckInt(y); OM4G.Bit(x, y)
      ELSIF fct = 15 THEN (*REG*) CheckConst(x); CheckInt(x); OM4G.Register(x)
      ELSIF fct = 16 THEN (*VAL*)
        IF (x.mode= OM4B.Typ) & (x.type.size <= y.type.size) THEN restyp := x.type; x := y
        ELSE OM4S.Mark("casting not allowed")
        END
      ELSIF fct = 17 THEN (*ADR*) OM4G.Adr(x)
      ELSIF fct = 18 THEN (*SIZE*)
        IF x.mode = OM4B.Typ THEN OM4G.MakeConstItem(x, OM4B.intType, x.type.size)
        ELSE OM4S.Mark("must be a type")
        END
      ELSIF fct = 19 THEN (*COND*) CheckConst(x); CheckInt(x); OM4G.Condition(x)
      ELSIF fct = 20 THEN (*SQRT*) CheckReal(x); OM4G.Sqrt(x)
      ELSIF fct = 21 THEN (*SVC*) CheckConst(x); CheckInt(x); OM4G.SVC(x)
      ELSIF fct = 22 THEN (*Int Compare*)
        CheckInt(x); CheckInt(y); CheckConst(z); CheckInt(z); OM4G.IntCompare(x, y, z)
      END ;
      x.type := restyp
    ELSE OM4S.Mark("wrong nof params")
    END
  END StandFunc;

  PROCEDURE element(VAR x: OM4G.Item);
    VAR y!: OM4G.Item;
  BEGIN expression(x); CheckSetVal(x);
    IF sym = OM4S.upto THEN OM4S.Get(sym); expression(y); CheckSetVal(y); OM4G.Set(x, y)
    ELSE OM4G.Singleton(x)
    END ;
    x.type := OM4B.setType
  END element;
  
  PROCEDURE set(VAR x: OM4G.Item);
    VAR y!: OM4G.Item;
  BEGIN
    IF sym >= OM4S.if THEN
      IF sym # OM4S.rbrace THEN OM4S.Mark(" } missing") END ;
      OM4G.MakeConstItem(x, OM4B.setType, 0) (*empty set*)
    ELSE element(x);
      WHILE (sym < OM4S.rparen) OR (sym > OM4S.rbrace) DO
        IF sym = OM4S.comma THEN OM4S.Get(sym)
        ELSIF sym # OM4S.rbrace THEN OM4S.Mark("missing comma")
        END ;
        element(y); OM4G.SetOp(OM4S.plus, x, y)
      END
    END
  END set; 

  PROCEDURE factor(VAR x: OM4G.Item);
    VAR obj!: OM4B.Object; rx, sx: LONGINT;
  BEGIN (*sync*)
    IF (sym < OM4S.char) OR (sym > OM4S.ident) THEN OM4S.Mark("expression expected");
      REPEAT OM4S.Get(sym) UNTIL (sym >= OM4S.char) & (sym <= OM4S.for) OR (sym >= OM4S.then)
    END ;
    IF sym = OM4S.ident THEN
      qualident(obj);  
      IF obj.class = OM4B.SFunc THEN StandFunc(x, obj.val, obj.type)
      ELSE OM4G.MakeItem(x, obj, level); selector(x);
        IF sym = OM4S.lparen THEN
          OM4S.Get(sym);
          IF (x.type.form = OM4B.Proc) & (x.type.base.form # OM4B.NoTyp) THEN
            obj.used := TRUE;
            OM4G.PrepCall(x, rx, sx); ParamList(x); OM4G.Call(x, rx, sx); x.type := x.type.base
          ELSE OM4S.Mark("not a function"); ParamList(x)
          END
        END
      END
    ELSIF sym = OM4S.int THEN OM4G.MakeConstItem(x, OM4B.intType, OM4S.ival); OM4S.Get(sym)
    ELSIF sym = OM4S.real THEN OM4G.MakeRealItem(x, OM4S.rval); OM4S.Get(sym)
    ELSIF sym = OM4S.char THEN OM4G.MakeConstItem(x, OM4B.charType, OM4S.ival); OM4S.Get(sym)
    ELSIF sym = OM4S.nil THEN OM4S.Get(sym); OM4G.MakeConstItem(x, OM4B.nilType, 0)
    ELSIF sym = OM4S.string THEN OM4G.MakeStringItem(x, OM4S.slen); OM4S.Get(sym)
    ELSIF sym = OM4S.lparen THEN OM4S.Get(sym); expression(x); Check(OM4S.rparen, "no )")
    ELSIF sym = OM4S.lbrace THEN OM4S.Get(sym); set(x); Check(OM4S.rbrace, "no }")
    ELSIF sym = OM4S.not THEN OM4S.Get(sym); factor(x); CheckBool(x); OM4G.Not(x)
    ELSIF sym = OM4S.false THEN OM4S.Get(sym); OM4G.MakeConstItem(x, OM4B.boolType, 0)
    ELSIF sym = OM4S.true THEN OM4S.Get(sym); OM4G.MakeConstItem(x, OM4B.boolType, 1)
    ELSE OM4S.Mark("not a factor"); OM4G.MakeConstItem(x, OM4B.intType, 0)
    END
  END factor;

  PROCEDURE term(VAR x: OM4G.Item);
    VAR y!: OM4G.Item; op, f: INTEGER;
  BEGIN factor(x); f := x.type.form;
    WHILE (sym >= OM4S.times) & (sym <= OM4S.and) DO
      op := sym; OM4S.Get(sym);
      IF op = OM4S.times THEN
        IF f = OM4B.Int THEN factor(y); CheckInt(y); OM4G.MulOp(x, y)
        ELSIF f = OM4B.Real THEN factor(y); CheckReal(y); OM4G.RealOp(op, x, y)
        ELSIF f = OM4B.Set THEN factor(y); CheckSet(y); OM4G.SetOp(op, x, y)
        ELSE OM4S.Mark("bad type")
        END
      ELSIF (op = OM4S.div) OR (op = OM4S.mod) THEN
        CheckInt(x); factor(y); CheckInt(y); OM4G.DivOp(op, x, y)
      ELSIF op = OM4S.rdiv THEN
        IF f = OM4B.Real THEN factor(y); CheckReal(y); OM4G.RealOp(op, x, y)
        ELSIF f = OM4B.Set THEN factor(y); CheckSet(y); OM4G.SetOp(op, x, y)
        ELSE OM4S.Mark("bad type")
        END
      ELSE (*op = and*) CheckBool(x); OM4G.And1(x); factor(y); CheckBool(y); OM4G.And2(x, y)
      END
    END
  END term;

  PROCEDURE SimpleExpression(VAR x: OM4G.Item);
    VAR y!: OM4G.Item; op: INTEGER;
  BEGIN
    IF sym = OM4S.minus THEN OM4S.Get(sym); term(x);
      IF x.type.form IN {OM4B.Int, OM4B.Real, OM4B.Set} THEN OM4G.Neg(x) ELSE CheckInt(x) END
    ELSIF sym = OM4S.plus THEN OM4S.Get(sym); term(x);
    ELSE term(x)
    END ;
    WHILE (sym >= OM4S.plus) & (sym <= OM4S.or) DO
      op := sym; OM4S.Get(sym);
      IF op = OM4S.or THEN OM4G.Or1(x); CheckBool(x); term(y); CheckBool(y); OM4G.Or2(x, y)
      ELSIF x.type.form = OM4B.Int THEN term(y); CheckInt(y); OM4G.AddOp(op, x, y)
      ELSIF x.type.form = OM4B.Real THEN term(y); CheckReal(y); OM4G.RealOp(op, x, y)
      ELSE CheckSet(x); term(y); CheckSet(y); OM4G.SetOp(op, x, y)
      END
    END
  END SimpleExpression;

  PROCEDURE expression0(VAR x: OM4G.Item);
    VAR y!: OM4G.Item; obj!: OM4B.Object; rel, xf, yf: INTEGER;
  BEGIN SimpleExpression(x);
    IF (sym >= OM4S.eql) & (sym <= OM4S.geq) THEN
      rel := sym; OM4S.Get(sym); SimpleExpression(y); xf := x.type.form; yf := y.type.form;
      IF x.type = y.type THEN
        IF (xf IN {OM4B.Char, OM4B.Int}) THEN OM4G.IntRelation(rel, x, y)
        ELSIF xf = OM4B.Real THEN OM4G.RealRelation(rel, x, y)
        ELSIF (xf IN {OM4B.Set, OM4B.Pointer, OM4B.Proc, OM4B.NilTyp, OM4B.Bool}) THEN
          IF rel <= OM4S.neq THEN OM4G.IntRelation(rel, x, y) ELSE OM4S.Mark("only = or #") END
        ELSIF (xf = OM4B.Array) & (x.type.base.form = OM4B.Char) OR (xf = OM4B.String) THEN
          OM4G.StringRelation(rel, x, y)
        ELSE OM4S.Mark("illegal comparison")
        END
      ELSIF (xf IN {OM4B.Pointer, OM4B.Proc}) & (yf = OM4B.NilTyp)
          OR (yf IN {OM4B.Pointer, OM4B.Proc}) & (xf = OM4B.NilTyp) THEN
        IF rel <= OM4S.neq THEN OM4G.IntRelation(rel, x,  y) ELSE OM4S.Mark("only = or #") END
      ELSIF (xf = OM4B.Pointer) & (yf = OM4B.Pointer) &
          (IsExtension(x.type.base, y.type.base) OR IsExtension(y.type.base, x.type.base))
          OR (xf = OM4B.Proc) & (yf = OM4B.Proc) & EqualSignatures(x.type, y.type) THEN
        IF rel <= OM4S.neq THEN OM4G.IntRelation(rel,  x, y) ELSE OM4S.Mark("only = or #") END
      ELSIF (xf = OM4B.Array) & (x.type.base.form = OM4B.Char) &
            ((yf = OM4B.String) OR (yf = OM4B.Array) & (y.type.base.form = OM4B.Char))
          OR (yf = OM4B.Array) & (y.type.base.form = OM4B.Char) & (xf = OM4B.String) THEN
        OM4G.StringRelation(rel, x, y)
      ELSIF (xf = OM4B.Char) & (yf = OM4B.String) & (y.b = 2) THEN
        OM4G.StrToChar(y); OM4G.IntRelation(rel, x, y)
      ELSIF (yf = OM4B.Char) & (xf = OM4B.String) & (x.b = 2) THEN
        OM4G.StrToChar(x); OM4G.IntRelation(rel, x, y)
      ELSIF (xf = OM4B.Int) & (yf = OM4B.Int) THEN OM4G.IntRelation(rel,  x, y)  (*BYTE*)
      ELSE OM4S.Mark("illegal comparison")
      END ;
      x.type := OM4B.boolType
    ELSIF sym = OM4S.in THEN
      OM4S.Get(sym); CheckInt(x); SimpleExpression(y); CheckSet(y); OM4G.In(x, y) ;
      x.type := OM4B.boolType
    ELSIF sym = OM4S.is THEN
      OM4S.Get(sym); qualident(obj); TypeTest(x, obj.type, FALSE) ;
      x.type := OM4B.boolType
    END
  END expression0;

  (* statements *)

  PROCEDURE StandProc(pno: LONGINT);
    VAR nap, npar: LONGINT; (*nof actual/formal parameters*)
      x!, y!, z!: OM4G.Item;
  BEGIN Check(OM4S.lparen, "no (");
    npar := pno MOD 10; pno := pno DIV 10; expression(x); nap := 1;
    IF sym = OM4S.comma THEN
      OM4S.Get(sym); IF pno = 14 (*LDREG*) THEN 
        CheckConst(x); CheckInt(x); IF x.a < 16 THEN OM4G.SetRH(x.a) END 
      END;
      expression(y); nap := 2; z.type := OM4B.noType;
      WHILE sym = OM4S.comma DO OM4S.Get(sym); expression(z); INC(nap) END
    ELSE y.type := OM4B.noType
    END ;
    Check(OM4S.rparen, "no )");
    IF (npar = nap) OR (pno IN {0, 1}) THEN 
      IF pno IN {0, 1} THEN (*INC, DEC*)
        CheckInt(x); CheckReadOnly(x);
        IF y.type # OM4B.noType THEN CheckInt(y) END ;
        OM4G.Increment(pno, x, y)
      ELSIF pno IN {2, 3} THEN (*INCL, EXCL*)
        CheckSet(x); CheckReadOnly(x); CheckInt(y); OM4G.Include(pno-2, x, y)
      ELSIF pno = 4 THEN CheckBool(x); OM4G.Assert(x)
      ELSIF pno = 5 THEN(*NEW*) CheckReadOnly(x);
         IF (x.type.form = OM4B.Pointer) & (x.type.base.form = OM4B.Record) THEN OM4G.New(x)
         ELSE OM4S.Mark("not a pointer to record")
         END
      ELSIF pno = 6 THEN CheckReal(x); CheckInt(y); CheckReadOnly(x); OM4G.Pack(x, y)
      ELSIF pno = 7 THEN CheckReal(x); CheckInt(y); CheckReadOnly(x); OM4G.Unpk(x, y)
      ELSIF pno = 8 THEN
        IF x.type.form <= OM4B.Set THEN OM4G.Led(x) ELSE OM4S.Mark("bad type") END
      ELSIF pno = 10 THEN CheckInt(x); OM4G.Get(x, y)
      ELSIF pno = 11 THEN CheckInt(x); OM4G.Put(x, y)
      ELSIF pno = 12 THEN CheckInt(x); CheckInt(y); CheckInt(z); OM4G.Copy(x, y, z)
      ELSIF pno = 14 THEN OM4G.LDREG(x, y)
      ELSIF pno = 15 THEN CheckConst(x); CheckInt(x); OM4G.MBI(x.a) (*Memory barrier instructions*)
      END
    ELSE OM4S.Mark("wrong nof parameters")
    END
  END StandProc;

  PROCEDURE StatSequence;
    VAR obj!: OM4B.Object;
      orgtype!: OM4B.Type; (*original type of case var*)
      x!, y!, z!, w!: OM4G.Item;
      L0, L1, rx, sx: LONGINT;

    PROCEDURE TypeCase(obj: OM4B.Object; VAR x: OM4G.Item);
      VAR typobj!: OM4B.Object;
    BEGIN
      OM4G.MakeItem(x, obj, level);
      IF sym = OM4S.ident THEN
        qualident(typobj);
        IF typobj.class # OM4B.Typ THEN OM4S.Mark("not a type") END ;
        TypeTest(x, typobj.type, FALSE); obj.type := typobj.type;
        OM4G.CFJump(x); Check(OM4S.colon, ": expected"); StatSequence
      ELSE OM4G.CFJump(x); OM4S.Mark("type id expected")
      END
     END TypeCase;

    PROCEDURE SkipCase;
    BEGIN 
      WHILE sym # OM4S.colon DO OM4S.Get(sym) END ;
      OM4S.Get(sym); StatSequence
    END SkipCase;

  BEGIN (* StatSequence *)
    REPEAT (*sync*) obj := NIL;
      IF ~((sym >= OM4S.ident)  & (sym <= OM4S.for) OR (sym >= OM4S.semicolon)) THEN
        OM4S.Mark("statement expected");
        REPEAT OM4S.Get(sym) UNTIL (sym >= OM4S.ident)
      END ;
      IF sym = OM4S.ident THEN
        qualident(obj); OM4G.MakeItem(x, obj, level);
        IF x.mode = OM4B.SProc THEN StandProc(obj.val)
        ELSE selector(x);
          IF sym = OM4S.becomes THEN (*assignment*)
            OM4S.Get(sym); CheckReadOnly(x); expression(y);
            IF CompTypes(x.type, y.type, FALSE) THEN
              IF (x.type.form <= OM4B.Pointer) OR (x.type.form = OM4B.Proc) THEN OM4G.Store(x, y)
              ELSE OM4G.StoreStruct(x, y)
              END
            ELSIF (x.type.form = OM4B.Array) & (y.type.form = OM4B.Array) & (x.type.base = y.type.base) & (y.type.len < 0) THEN
              OM4G.StoreStruct(x, y)
            ELSIF (x.type.form = OM4B.Array) & (x.type.base.form = OM4B.Char) & (y.type.form = OM4B.String) THEN
              OM4G.CopyString(x, y)
            ELSIF (x.type.form = OM4B.Int) & (y.type.form = OM4B.Int) THEN OM4G.Store(x, y)  (*BYTE*)
            ELSIF (x.type.form = OM4B.Char) & (y.type.form = OM4B.String) & (y.b = 2) THEN
              OM4G.StrToChar(y); OM4G.Store(x, y)
            ELSE OM4S.Mark("illegal assignment")
            END
          ELSIF sym = OM4S.eql THEN OM4S.Mark("should be :="); OM4S.Get(sym); expression(y)
          ELSIF sym = OM4S.lparen THEN (*procedure call*)
            OM4S.Get(sym);
            IF (x.type.form = OM4B.Proc) & (x.type.base.form = OM4B.NoTyp) THEN
              obj.used := TRUE;
              OM4G.PrepCall(x, rx, sx); ParamList(x); OM4G.Call(x, rx, sx)
            ELSE OM4S.Mark("not a procedure"); ParamList(x)
            END
          ELSIF x.type.form = OM4B.Proc THEN (*procedure call without parameters*)
            IF x.type.nofpar > 0 THEN OM4S.Mark("missing parameters") END ;
            IF x.type.base.form = OM4B.NoTyp THEN 
              obj.used := TRUE;
              OM4G.PrepCall(x, rx, sx); OM4G.Call(x, rx, sx)
            ELSE OM4S.Mark("not a procedure")
            END
          ELSIF x.mode = OM4B.Typ THEN OM4S.Mark("illegal assignment")
          ELSE OM4S.Mark("not a procedure")
          END
        END
      ELSIF sym = OM4S.if THEN
        OM4S.Get(sym); expression(x); CheckBool(x); OM4G.CFJump(x);
        Check(OM4S.then, "no THEN");
        StatSequence; L0 := 0;
        WHILE sym = OM4S.elsif DO
          OM4S.Get(sym); OM4G.FJump(L0); OM4G.Fixup(x); expression(x); CheckBool(x);
          OM4G.CFJump(x); Check(OM4S.then, "no THEN"); StatSequence
        END ;
        IF sym = OM4S.else THEN OM4S.Get(sym); OM4G.FJump(L0); OM4G.Fixup(x); StatSequence
        ELSE OM4G.Fixup(x)
        END ;
        OM4G.FixLink(L0); Check(OM4S.end, "no END")
      ELSIF sym = OM4S.while THEN
        OM4S.Get(sym); L0 := OM4G.Here(); expression(x); CheckBool(x); OM4G.CFJump(x);
        Check(OM4S.do, "no DO"); StatSequence; OM4G.BJump(L0);
        WHILE sym = OM4S.elsif DO
          OM4S.Get(sym); OM4G.Fixup(x); expression(x); CheckBool(x); OM4G.CFJump(x);
          Check(OM4S.do, "no DO"); StatSequence; OM4G.BJump(L0)
        END ;
        OM4G.Fixup(x); Check(OM4S.end, "no END")
      ELSIF sym = OM4S.repeat THEN
        OM4S.Get(sym); L0 := OM4G.Here(); StatSequence;
        IF sym = OM4S.until THEN
          OM4S.Get(sym); expression(x); CheckBool(x); OM4G.CBJump(x, L0)
        ELSE OM4S.Mark("missing UNTIL")
        END
      ELSIF sym = OM4S.for THEN
        OM4S.Get(sym);
        IF sym = OM4S.ident THEN
          qualident(obj); OM4G.MakeItem(x, obj, level); CheckInt(x); CheckReadOnly(x);
          IF sym = OM4S.becomes THEN
            OM4S.Get(sym); expression(y); CheckInt(y); OM4G.For0(x, y); L0 := OM4G.Here();
            Check(OM4S.to, "no TO"); expression(z); CheckInt(z); obj.rdo := TRUE;
            IF sym = OM4S.by THEN OM4S.Get(sym); expression(w); CheckConst(w); CheckInt(w)
            ELSE OM4G.MakeConstItem(w, OM4B.intType, 1)
            END ;
            Check(OM4S.do, "no DO"); OM4G.For1(x, y, z, w, L1);
            StatSequence; Check(OM4S.end, "no END");
            OM4G.For2(x, y, w); OM4G.BJump(L0); OM4G.FixLink(L1); obj.rdo := FALSE
          ELSE OM4S.Mark(":= expected")
          END
        ELSE OM4S.Mark("identifier expected")
        END
      ELSIF sym = OM4S.case THEN
        OM4S.Get(sym);
        IF sym = OM4S.ident THEN
          qualident(obj); orgtype := obj.type;
          IF (orgtype.form = OM4B.Pointer) OR (orgtype.form = OM4B.Record) & (obj.class = OM4B.Par) THEN
            Check(OM4S.of, "OF expected"); TypeCase(obj, x); L0 := 0;
            WHILE sym = OM4S.bar DO
              OM4S.Get(sym); OM4G.FJump(L0); OM4G.Fixup(x); obj.type := orgtype; TypeCase(obj, x)
            END ;
            OM4G.Fixup(x); OM4G.FixLink(L0); obj.type := orgtype
          ELSE OM4S.Mark("numeric case not implemented");
            Check(OM4S.of, "OF expected"); SkipCase;
            WHILE sym = OM4S.bar DO SkipCase END
          END
        ELSE OM4S.Mark("ident expected")
        END ;
        Check(OM4S.end, "no END")
      END ;
      OM4G.CheckRegs;
      IF sym = OM4S.semicolon THEN OM4S.Get(sym)
      ELSIF sym < OM4S.semicolon THEN OM4S.Mark("missing semicolon?")
      END
    UNTIL sym > OM4S.semicolon
  END StatSequence;

  (* Types and declarations *)

  PROCEDURE IdentList(class: INTEGER; VAR first: OM4B.Object);
    VAR obj!: OM4B.Object;
  BEGIN
    IF sym = OM4S.ident THEN
      OM4B.NewObj(first, OM4S.id, class); OM4S.Get(sym); CheckExport(first.expo); CheckUnsafeMarking(first.unsafe);
      WHILE sym = OM4S.comma DO
        OM4S.Get(sym);
        IF sym = OM4S.ident THEN OM4B.NewObj(obj, OM4S.id, class); OM4S.Get(sym); CheckExport(obj.expo); CheckUnsafeMarking(obj.unsafe)
        ELSE OM4S.Mark("ident?")
        END
      END;
      IF sym = OM4S.colon THEN OM4S.Get(sym) ELSE OM4S.Mark(":?") END
    ELSE first := NIL
    END
  END IdentList;
  
  PROCEDURE ArrayType(VAR type: OM4B.Type);
    VAR x!: OM4G.Item; typ!: OM4B.Type; len: LONGINT;
  BEGIN NEW(typ); typ.form := OM4B.NoTyp;
    expression(x);
    IF (x.mode = OM4B.Const) & (x.type.form = OM4B.Int) & (x.a >= 0) THEN len := x.a
    ELSE len := 1; OM4S.Mark("not a valid length")
    END ;
    IF sym = OM4S.of THEN OM4S.Get(sym); Type(typ.base);
      IF (typ.base.form = OM4B.Array) & (typ.base.len < 0) THEN OM4S.Mark("dyn array not allowed") END
    ELSIF sym = OM4S.comma THEN OM4S.Get(sym); ArrayType(typ.base)
    ELSE OM4S.Mark("missing OF"); typ.base := OM4B.intType
    END ;
    typ.size := (len * typ.base.size + 3) DIV 4 * 4;
    typ.form := OM4B.Array; typ.len := len; type := typ
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
  BEGIN OM4G.Init;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
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
    END ;
    OM4G.DeInit;
    Oberon.Collect(0)
  END Compile;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4 Compiler  19/10/2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
  NEW(dummy); dummy.class := OM4B.Const; dummy.type := OM4B.intType;
  expression := expression0; Type := Type0; FormalType := FormalType0
END OM4P.
