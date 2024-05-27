MODULE OMSPG; (* N.Wirth, 16.4.2016 / 4.4.2017 / 31.5.2019  Oberon compiler;
  C. Schoffit 21.05.24 code generator for MSP430 processor family*)
  IMPORT SYSTEM, Files, A := OMSPA, S := OMSPS, B := OMSPB;
  (*Code generator for Oberon compiler targetting MSP430 processor.
     Procedural interface to Parser OMSPP; result in record "code".
     Procedure Close writes code-files*)

  CONST WordSize* = 2;
    maxStrx = 3000; maxTD = 160; maxFOS = 1000;
    
    Reg = 10; RegI = 11; Cond = 12; (*internal item modes*)

  TYPE Item* = RECORD(A.Item)
    mode*: INTEGER;
    type*: B.Type;
    obj: B.Object; (*for update of usedAt*)
    a*, b*, r: LONGINT;
    rdo*: BOOLEAN  (*read only*)
  END ;

  (* Item forms and meaning of fields:
    mode    r           a           b                      obj
    ----------------------------------------------------------
    Const   -        value   (proc adr)               -                    (immediate value)
    Var     base      off           -            ext ref (base <= 0)    (direct adr)
    Par      -          off0        off1                     -                     (indirect adr)
    Reg     regno    -            -                        -
    RegI    regno   off           -                        -
    Cond    cond   Fchain  Tchain                   - *)

    FrameOffsetSegment = RECORD
      end, ofsptos (*offset with previous top of stack*): INTEGER
    END;

    FrameOffsetDesc = RECORD
      NofSegs: INTEGER;
      Segs: ARRAY maxFOS OF FrameOffsetSegment
    END;

    FrameOffset = POINTER TO FrameOffsetDesc;

  VAR varsize: LONGINT;   (*data index*)
    tdx, strx: LONGINT;
    entry: LONGINT;   (*main entry point*)
    AllocUp: BOOLEAN; (*if true, registers are in allocated in ascending or from R4 to R15, if false in descending order from R15 to R4*)
    RH: LONGINT;      (*in use registers R[15] ... R[H+1]*)
    RL: INTEGER; (*register limit*)
    frame: LONGINT;   (*frame offset changed in SaveRegs and RestoreRegs*)
    fixORGT: LONGINT;   (*origins of lists of locations to be fixed up by linker*)
    traps: ARRAY 7 OF B.Object; arith: ARRAY 4 OF B.Object;
    
    relmap: ARRAY 6 OF INTEGER;    (*condition codes for relations*)
    data: ARRAY maxTD OF LONGINT;  (*type descriptors*)
    str: ARRAY maxStrx OF CHAR;
    mcode: A.ModuleCode;
    frmOfsSegs: FrameOffset;

    cm1, c0, c1, pc, sp, r4, r15: Item;

  PROCEDURE OfsPTOS(offset: INTEGER; increment: BOOLEAN);
  BEGIN IF increment THEN INC(offset, frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos) END;
      IF offset # frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos THEN
      frmOfsSegs.Segs[frmOfsSegs.NofSegs].end := mcode.pc;
      INC(frmOfsSegs.NofSegs); frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos := offset
    END
  END OfsPTOS;

  PROCEDURE FixOne*(at: LONGINT);
  BEGIN A.FixOne(mcode, at)
  END FixOne;

  PROCEDURE FixLink*(L: LONGINT);
  BEGIN
    A.FixLink(mcode, L)
  END FixLink;

  PROCEDURE allocR;
    VAR success: BOOLEAN;
  BEGIN (*register are allocated beginning in order according to AllocUp value*)
    success := FALSE;
    IF AllocUp THEN IF RH < RL-1 THEN INC(RH); success := TRUE END
    ELSE IF RH > RL+1 THEN DEC(RH); success := TRUE END
    END;
    IF ~success THEN S.Mark("register stack overflow") END
  END allocR;

  PROCEDURE freeR;
    VAR success: BOOLEAN;
  BEGIN (*register are allocated beginning in order according to AllocUp value*)
    success := FALSE;
    IF AllocUp THEN IF RH > 0 THEN DEC(RH); success := TRUE END
    ELSE IF RH < 15 THEN INC(RH); success := TRUE END
    END;
    IF ~success THEN S.Mark("register stack underflow") END
  END freeR;

  PROCEDURE resultRegister(VAR res: Item);
  BEGIN
    IF AllocUp THEN res := r4 ELSE res := r15 END
  END resultRegister;

  PROCEDURE SetRH*(r: BYTE);
  BEGIN
    ASSERT(r < A.C4);
    RH := r
  END SetRH;
  
  PROCEDURE CheckRegs*;
  BEGIN
    IF RH # 15 THEN S.Mark("Reg Stack"); RH := 0 END ;
    IF mcode.pc >= A.maxCode - 40 THEN S.Mark("program too long") END ;
    IF frame # 0 THEN S.Mark("frame error"); frame := 0 END
  END CheckRegs;

  PROCEDURE SetCC(VAR x: Item; n: LONGINT);
  BEGIN x.mode := Cond; x.a := 0; x.b := 0; x.r := n
  END SetCC;

  PROCEDURE SetTrap*(num: INTEGER; proc: B.Object);
  BEGIN traps[num] := proc
  END SetTrap;
 
  PROCEDURE SetArith*(num: INTEGER; proc: B.Object);
  BEGIN arith[num] := proc
  END SetArith;
 
  PROCEDURE GetOffset(VAR x: Item): INTEGER;
    VAR res: INTEGER;
  BEGIN IF x.ofs = A.C16 THEN (*Imported object*) res := x.obj.usedat; x.obj.usedat := mcode.pc ELSE res := x.ofs END
    RETURN res
  END GetOffset;

 PROCEDURE Trap(cond, num: LONGINT);
  (*Trap is implemented as calls to functions in the Trap special module.  
     If the procedure Trap.Handle<num> procedure exists and is exported,
     the trap checking code is generated.*)
  VAR l: INTEGER; t!: Item;
  BEGIN A.PutJ(mcode, A.negated(cond), 4); t.reg := 0; t.am := A.Immediate; t.ofs := A.C16; t.obj := traps[num];
    A.PutSO(mcode, A.CALL, t, A.Word)
  END Trap;

  PROCEDURE NilCheck(a: BYTE);
    VAR t!: Item;
  BEGIN t.reg := a; t.am := A.Register; t.ofs := 0; t.obj := NIL;
    IF traps[4] # NIL THEN
      A.PutDO(mcode, A.CMP, c0, t, A.Word);
      Trap(A.EQ, 4) 
    END
  END NilCheck;

  (* loading of operands and addresses into registers *)

  PROCEDURE load(VAR x: Item);
    VAR pc0, pc1: LONGINT; bw: SET; rh!, t!, ti!, sva!: Item;
  BEGIN rh.reg := RH; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL; t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    ti.am := A.Indexed; ti.obj := NIL; sva.reg := 0; sva.ofs := A.C16; sva.obj := x.obj;
    IF x.mode # Reg THEN
      IF x.type.size = 1 THEN bw := A.Byte ELSE bw := A.Word END ;
      IF x.mode = B.Const THEN
        IF x.type.form = B.Proc THEN
          IF x.r > 0 THEN S.Mark("not allowed")
          ELSIF x.r = 0 THEN A.PutDO(mcode, A.MOV, pc, rh, A.Word); (*Put address of next statement in RH*)
            t.ofs := mcode.pc - x.a; A.PutDO(mcode, A.SUB, t, rh, A.Word) (*substract offset to compute absolute address*)
          ELSE sva.am := A.Immediate (*imported*); A.PutDO(mcode, A.MOV, sva, rh, A.Word)
          END
        ELSE t.ofs := x.a; A.PutDO(mcode, A.MOV, t, rh, A.Word)
        END;
        x.r := RH; allocR
      ELSIF x.mode = B.Var THEN
        IF x.r > 0 THEN (*local*) ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, bw)
        ELSE sva.am := A.Absolute; A.PutDO(mcode, A.MOV, sva, rh, bw)
        END; x.r := RH; allocR
      ELSIF x.mode = B.Par THEN ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
        ti.reg := RH; ti.ofs := x.b; A.PutDO(mcode, A.MOV, ti, rh, bw); x.r := RH; allocR
      ELSIF x.mode = RegI THEN ti.reg := x.r; ti.ofs := x.a; x.reg := x.r; x.am := A.Register; x.ofs := 0; A.PutDO(mcode, A.MOV, ti, x, bw)
      ELSIF x.mode = Cond THEN
        pc0 := mcode.pc; A.PutJ(mcode, A.negated(x.r), 0);
        FixLink(x.b); A.PutDO(mcode, A.MOV, c1, rh, A.Word); A.fix(mcode, pc0, mcode.pc - pc0 - 2);
        FixLink(x.a); A.PutDO(mcode, A.MOV, c0, rh, A.Word); A.fix(mcode, pc1, mcode.pc - pc1 - 2);
        x.r := RH; allocR
      END;
      x.mode := Reg; x.reg := x.r; x.am := A.Register; x.ofs := 0
    END
  END load;

  PROCEDURE loadAdr(VAR x: Item);
    VAR rh!, t!, ti!, sva!: Item;
  BEGIN rh.reg := RH; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL; t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    ti.am := A.Indexed; ti.obj := NIL; sva.reg := 0; sva.obj := x.obj; sva.ofs := A.C16;
    IF x.mode = B.Var THEN
      IF x.r > 0 THEN (*local*) A.PutDO(mcode, A.MOV, sp, rh, A.Word);
        IF x.a + frame # 0 THEN t.ofs := x.a + frame; A.PutDO(mcode, A.ADD, t, rh, A.Word) END
      ELSE sva.am := A.Immediate; A.PutDO(mcode, A.MOV, sva, rh, A.Word)
      END;
      x.r := RH; allocR
    ELSIF x.mode = B.Par THEN ti.reg := A.SP; ti.ofs := x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
      IF x.b # 0 THEN t.ofs := x.b; A.PutDO(mcode, A.ADD, t, rh, A.Word) END;
      x.r := RH; allocR
    ELSIF x.mode = RegI THEN
      IF x.a # 0 THEN t.ofs := x.a; x.reg := x.r; x.am := A.Register; x.ofs := 0; A.PutDO(mcode, A.ADD, t, x, A.Word) END
    ELSE S.Mark("address error")
    END;
    x.mode := Reg; x.reg := x.r; x.am := A.Register; x.ofs := 0
  END loadAdr;

  PROCEDURE loadCond(VAR x: Item);
  BEGIN
    IF x.type.form = B.Bool THEN
      IF x.mode = B.Const THEN IF x.a = 0 THEN x.r := A.NV ELSE x.r := A.AL END
      ELSE load(x); A.PutDO(mcode, A.CMP, c0, x, A.Word); x.r := A.NE; freeR
      END;
      x.mode := Cond; x.a := 0; x.b := 0
    ELSE S.Mark("not Boolean?")
    END
  END loadCond;

  PROCEDURE loadTypTagAdr(T: B.Type);
    VAR x!: Item;
  BEGIN x.mode := B.Var; x.type := NIL; x.a := T.len; x.r := -T.mno; loadAdr(x)
  END loadTypTagAdr;

  PROCEDURE loadStringAdr(VAR x: Item);
    VAR rh!: Item;
  BEGIN x.r := 0; x.a := varsize+x.a; x.reg := 0; x.am := A.Immediate; x.ofs := A.C16;
    rh.reg := RH; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL; A.PutDO(mcode, A.MOV, x, rh, A.Word);
    x.mode := Reg; x.r := RH; x.reg := x.r; x.am := A.Register; x.ofs := 0; allocR
  END loadStringAdr;

  (* Items: Conversion from constants or from Objects on the Heap to Items on the Stack*)

  PROCEDURE MakeConstItem*(VAR x: Item; typ: B.Type; val: LONGINT);
  BEGIN x.mode := B.Const; x.type := typ; x.a := val
  END MakeConstItem;

  PROCEDURE MakeStringItem*(VAR x: Item; len: LONGINT); (*copies string from OMSPS-buffer to OMSPG-string array*)
    VAR i: LONGINT;
  BEGIN x.mode := B.Const; x.type := B.strType; x.a := strx; x.b := len; i := 0;
    IF strx + len + 4 < maxStrx THEN
      WHILE len > 0 DO str[strx] := S.str[i]; INC(strx); INC(i); DEC(len) END ;
      WHILE strx MOD 4 # 0 DO str[strx] := 0X; INC(strx) END
    ELSE S.Mark("too many strings")
    END
  END MakeStringItem;

  PROCEDURE MakeItem*(VAR x: Item; y: B.Object; curlev: LONGINT);
  BEGIN x.mode := y.class; x.type := y.type; x.a := y.val; x.rdo := y.rdo; x.obj := y; x.reg := 0; x.am := A.Undefined; x.ofs := 0;
    IF y.class = B.Par THEN x.b := 0
    ELSIF (y.class = B.Const) & (y.type.form = B.String) THEN x.b := y.lev  (*len*) ;
    ELSE x.r := y.lev
    END ;
    IF (y.lev > 0) & (y.lev # curlev) & (y.class # B.Const) THEN S.Mark("not accessible ") END
  END MakeItem;

  (* Code generation for Selectors, Variables, Constants *)

  PROCEDURE Field*(VAR x: Item; y: B.Object);   (* x := x.y *)
  BEGIN;
    IF x.mode = B.Var THEN
      IF x.r >= 0 THEN x.a := x.a + y.val
      ELSE loadAdr(x); x.mode := RegI; x.a := y.val
      END
    ELSIF x.mode = RegI THEN x.a := x.a + y.val
    ELSIF x.mode = B.Par THEN x.b := x.b + y.val
    END
  END Field;

  PROCEDURE Index*(VAR x, y: Item);   (* x := x[y] *)
    VAR s, lim: LONGINT; rh!, t!, ti!, sva!: Item;
  BEGIN rh.reg := RH; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL; t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    ti.am := A.Indexed; ti.obj := NIL; sva.obj := x.obj; sva.reg := 0; sva.ofs := A.C16; s := x.type.base.size; 
    IF s=0 THEN S.Mark("Invalid array item size")
    ELSE
      lim := x.type.len;
      IF (y.mode = B.Const) & (lim >= 0) THEN
        IF (y.a < 0) OR (y.a >= lim) THEN S.Mark("bad index") END ;
        IF (x.mode # B.Var) OR (x.r >= 0) OR (y.a = 0) THEN
          IF x.mode IN {B.Var, RegI} THEN INC(x.a, y.a * s)
          ELSIF x.mode = B.Par THEN x.b := y.a * s + x.b
          END
        ELSE x.am := A.Immediate; x.ofs := A.C16; x.reg := 0; A.PutDO(mcode, A.MOV, x, rh, A.Word);
          x.mode := RegI; x.r := RH; x.a := y.a * s; x.reg := x.r; x.am := A.Register; x.ofs := 0; allocR
        END
      ELSE load(y);
        IF traps[1] # NIL THEN  (*check array bounds*)
          IF lim >= 0 THEN t.ofs := lim; A.PutDO(mcode, A.CMP, t, y, A.Word)
          ELSE (*open array*)
            IF x.mode IN {B.Var, B.Par} THEN ti.reg := A.SP; ti.ofs := x.a + 4 + frame; A.PutDO(mcode, A.CMP, ti, y, A.Word)
            ELSE S.Mark("error in Index")
            END
          END;
          Trap(A.C, 1) (*MSP430 inverts the carry with SUB and CMP instructions*)
        END;
        t.ofs := s; A.eswDO(mcode, A.MUL, t, y, A.Word, RH);
        IF x.mode = B.Var THEN
          IF x.r > 0 THEN A.PutDO(mcode, A.ADD, sp, y, A.Word); INC(x.a, frame)
          ELSE sva.am := A.Immediate; A.PutDO(mcode, A.MOV, sva, rh, A.Word); 
            A.PutDO(mcode, A.ADD, rh, y, A.Word); x.a := 0
          END;
          x.r := y.r; x.mode := RegI; x.reg := x.r; x.am := A.Register; x.ofs := 0
        ELSIF x.mode = B.Par THEN ti.reg := A.SP; ti.ofs := x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
          A.PutDO(mcode, A.ADD, rh, y, A.Word); x.mode := RegI; x.r := y.r; x.a := x.b; x.reg := x.r; x.am := A.Register; x.ofs := 0
        ELSIF x.mode = RegI THEN A.PutDO(mcode, A.ADD, y, x, A.Word); freeR
        END
      END
    END
  END Index;

  PROCEDURE DeRef*(VAR x: Item);
  BEGIN
    IF x.mode IN {B.Var, B.Par, RegI} THEN load(x); NilCheck(x.r)
    ELSIF x.mode # Reg THEN S.Mark("bad mode in DeRef") END;
    x.mode := RegI; x.a := 0; x.b := 0
  END DeRef;

  PROCEDURE Q(T: B.Type; VAR dcw: LONGINT);
  BEGIN (*one entry of type descriptor extension table*)
    IF T.base # NIL THEN
      Q(T.base, dcw); data[dcw] := (T.mno*1000H + T.len) * 1000H + dcw - fixORGT;
      fixORGT := dcw; INC(dcw)
    END
  END Q;

  PROCEDURE FindPtrFlds(typ: B.Type; off: LONGINT; VAR dcw: LONGINT);
    VAR fld!: B.Object; i, s: LONGINT;
  BEGIN
    IF (typ.form = B.Pointer) OR (typ.form = B.NilTyp) THEN data[dcw] := off; INC(dcw)
    ELSIF typ.form = B.Record THEN
      fld := typ.dsc;
      WHILE fld # NIL DO FindPtrFlds(fld.type, fld.val + off, dcw); fld := fld.next END
    ELSIF typ.form = B.Array THEN
      s := typ.base.size;
      FOR i := 0 TO typ.len-1 DO FindPtrFlds(typ.base, i*s + off, dcw) END
    END
  END FindPtrFlds;

  PROCEDURE BuildTD*(T: B.Type; VAR dc: LONGINT);
    VAR dcw, k, s: LONGINT;  (*dcw = word address*)
  BEGIN dcw := dc DIV 4; s := T.size; (*convert size for heap allocation*)
    IF s <= 24 THEN s := 32 ELSIF s <= 56 THEN s := 64 ELSIF s <= 120 THEN s := 128
    ELSE s := (s+263) DIV 256 * 256
    END ;
    T.len := dc; data[dcw] := s; INC(dcw);  (*len used as address*)
    k := T.nofpar;   (*extension level!*)
    IF k > 3 THEN S.Mark("ext level too large")
    ELSE Q(T, dcw);
      WHILE k < 3 DO data[dcw] := -1; INC(dcw); INC(k) END
    END ;
    FindPtrFlds(T, 0, dcw); data[dcw] := -1; INC(dcw); tdx := dcw; dc := dcw*4;
    IF tdx >= maxTD THEN S.Mark("too many record types"); tdx := 0 END
  END BuildTD;

  PROCEDURE TypeTest*(VAR x: Item; T: B.Type; varpar, isguard: BOOLEAN);
    VAR pc0: LONGINT; ti!, rh!, rh1!: Item;
  BEGIN ti.am := A.Indexed; ti.obj := NIL; rh.reg := RH; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL; rh1 := rh;
    IF (traps[2] = NIL) OR (T = NIL) THEN
      IF x.mode >= Reg THEN freeR END ;
      SetCC(x, A.AL)
    ELSE (*fetch tag into RH*)
      IF varpar THEN ti.reg := A.SP; ti.ofs := x.a+4+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
      ELSE load(x); A.PutDO(mcode, A.CMP, c0, x, A.Word);
        pc0 := mcode.pc; A.PutJ(mcode, A.EQ, 0); (*NIL belongs to every pointer type*)
        ti.reg := x.r; ti.ofs := -8; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
      END;
      ti.reg := RH; allocR; ti.ofs := T.nofpar*4; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
      loadTypTagAdr(T) (*tag of T*); rh1.reg := RH; A.PutDO(mcode, A.CMP, rh, rh1, A.Word); freeR; freeR;
      IF isguard THEN
        IF traps[2] # NIL THEN Trap(A.NE, 2) END
      ELSE SetCC(x, A.EQ);
        IF ~varpar THEN freeR END
      END;
      IF ~varpar THEN A.fix(mcode, pc0, mcode.pc - pc0 - 2) END
    END
  END TypeTest;

  PROCEDURE setRAO(VAR i: Item);
  BEGIN
    IF i.mode = B.Var THEN
      IF i.r > 0 THEN i.reg := A.SP; i.am := A.Indexed; i.ofs := i.a + frame ELSE i.reg := 0; i.am := A.Absolute; i.ofs := A.C16 (*use static var address*) END
  ELSIF i.mode = Reg THEN i.reg := i.r; i.am := A.Register; i.ofs := 0
  ELSIF i.mode = RegI THEN i.reg := i.r; i.am := A.Indexed; i.ofs := i.a
  END;
  END setRAO;

  PROCEDURE PutDO(op: BYTE; VAR src, dst: Item; params: SET);
  BEGIN 
    IF ~(src.mode IN {B.Const, B.Var, Reg, RegI}) THEN load(src) END;
    IF ~(dst.mode IN {B.Var, Reg, RegI}) THEN load(dst) END;

    IF src.mode = B.Const THEN src.reg := 0; src.am := A.Immediate; src.ofs := src.a ELSE setRAO(src) END; 
    setRAO(dst);

    A.PutDO(mcode, op, src, dst, params)
  END PutDO;

  PROCEDURE PutSO(op: INTEGER; VAR sd: Item; params: SET);
  BEGIN 
    IF ~(sd.mode IN {B.Const, B.Var, Reg, RegI}) THEN load(sd) END;
 
    IF sd.mode = B.Const THEN sd.reg := 0; sd.am := A.Immediate; sd.ofs := sd.a ELSE setRAO(sd) END; 

    A.PutSO(mcode, op, sd, params)
  END PutSO;

  (* Code generation for Boolean operators *)

  PROCEDURE Not*(VAR x: Item);   (* x := ~x *)
    VAR t: LONGINT;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    x.r := A.negated(x.r); t := x.a; x.a := x.b; x.b := t
  END Not;

  PROCEDURE And1*(VAR x: Item);   (* x := x & *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.PutJ(mcode, A.negated(x.r), x.a);
    x.a := mcode.pc-2; A.FixLink(mcode, x.b); x.b := 0
  END And1;

  PROCEDURE And2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := A.merged(mcode, y.a, x.a); x.b := y.b; x.r := y.r
  END And2;

  PROCEDURE Or1*(VAR x: Item);   (* x := x OR *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.PutJ(mcode, x.r, x.b);
    x.b := mcode.pc-2; A.FixLink(mcode, x.a); x.a := 0
  END Or1;

  PROCEDURE Or2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := y.a; x.b := A.merged(mcode, y.b, x.b); x.r := y.r
  END Or2;

  (* Code generation for arithmetic operators *)

  PROCEDURE Neg*(VAR x: Item);   (* x := -x *)
  BEGIN
    IF x.type.form = B.Int THEN
      IF x.mode = B.Const THEN x.a := -x.a
      ELSE load(x); A.eswSO(mcode, A.NEG, x, A.Word)
      END
    ELSE (*form = Set*)
      IF x.mode = B.Const THEN x.a := -x.a-1 
      ELSE PutDO(A.XOR, cm1, x, A.Word)
      END
    END
  END Neg;

  PROCEDURE AddOp*(op: LONGINT; VAR x, y: Item);   (* x := x +- y *)
    VAR t!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF op = S.plus THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a + y.a
      ELSIF y.mode = B.Const THEN
        IF y.a # 0 THEN t.ofs := y.a; PutDO(A.ADD, t, x, A.Word) END
      ELSE PutDO(A.ADD, y, x, A.Word); IF y.mode IN {Reg, RegI} THEN freeR END
      END
    ELSE (*op = S.minus*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a - y.a
      ELSIF y.mode = B.Const THEN load(x);
        IF y.a # 0 THEN t.ofs := y.a; PutDO(A.SUB, t, x, A.Word) END
      ELSE PutDO(A.SUB, y, x, A.Word); IF y.mode IN {Reg, RegI} THEN freeR END
      END
    END
  END AddOp;

  PROCEDURE PrepCall*(VAR x: Item; VAR r, n: LONGINT);
  BEGIN (*x.type.form = OM4B.Proc*) ASSERT(~AllocUp);
    IF x.mode > B.Par THEN load(x) END; n := 0+x.obj.type.ldr - RH; (*number of overwritten registers currently in use by the caller*)
    IF n > 0 THEN r := RH + 1; A.SaveRegs(mcode, r, n, frame); OfsPTOS(n, TRUE); RH := 0 END;
    AllocUp := x.obj.type.leaf
  END PrepCall;

  PROCEDURE Call*(VAR x: Item; r, n: LONGINT);
    VAR rh!, rr!, dr!: Item;
  BEGIN (*x.type.form = B.Proc*) rh.reg := RH; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL;
    IF x.mode = B.Const THEN x.reg := 0; x.am := A.Immediate; x.ofs := A.C16; (*address must be computed at link time*)
      A.PutSO(mcode, A.CALL, x, A.Word)
    ELSE
      IF x.mode <= B.Par THEN PutSO(A.CALL, x, A.Word); IF x.mode IN {Reg, RegI} THEN freeR END
      ELSE PutSO(A.POP, rh, A.Word); OfsPTOS(-1, TRUE); DEC(r); DEC(frame, 2)
      END;
      IF traps[5] # NIL THEN PutDO(A.CMP, c0, rh, A.Word); Trap(A.EQ, 5) END;
      A.PutSO(mcode, A.CALL, rh, A.Word)
    END;
    IF x.type.base.form = B.NoTyp THEN (*procedure*) RH := 15;
    ELSE (*function*) resultRegister(rr);
      IF r # rr.reg THEN dr.reg := r; dr.am := A.Register; dr.ofs := 0; A.PutDO(mcode, A.MOV, rr, dr, A.Word);
        IF n > 0 THEN A.RestoreRegs(mcode, r, n, frame); OfsPTOS(-r, TRUE) END
      END;
      x.mode := Reg; x.r := r; RH := r-1
    END;
    AllocUp := FALSE
  END Call;

  PROCEDURE MulOp*(VAR x, y: Item);   (* x := x * y *)
    VAR t!, p!: Item; r, n: INTEGER;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a * y.a
    ELSIF (y.mode = B.Const) & (y.a >= 2) THEN load(x); t.ofs := y.a; A.eswDO(mcode, A.MUL, t, x, A.Word, RH)
    ELSIF (x.mode = B.Const) & (x.a >= 2) THEN load(y); t.ofs := x.a; A.eswDO(mcode, A.MUL, t, y, A.Word, RH);
      x.mode := Reg; x.r := y.r; x.reg := x.r; x.am := A.Register; x.ofs := 0
    ELSE IF arith[0] = NIL THEN S.Mark("import Arith.mul function") 
      ELSE  MakeItem(p, arith[0], 0); PrepCall(p, r, n); load(x); load(y); Call(p, r, n)
      END
    END
  END MulOp;

  PROCEDURE DivOp*(op: LONGINT; VAR x, y: Item);   (* x := x op y *)
    VAR t!, p!, rh!: Item; r, n: INTEGER;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL; rh.reg := RH; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL;
    IF op = S.div THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a DIV y.a ELSE S.Mark("bad divisor") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) THEN load(x); t.ofs := y.a; A.eswDO(mcode, A.DIv, t, x, A.Word, RH);
        x.mode := Reg; x.r := y.r; x.reg := x.r; x.am := A.Register; x.ofs := 0
      ELSE IF arith[1] = NIL THEN S.Mark("import Arith.div procedure")
        ELSE IF traps[6] # NIL THEN PutDO(A.CMP, y, c0, A.Word); Trap(A.GE, 6); IF y.mode IN {Reg, RegI} THEN freeR END END;
          MakeItem(p, arith[1], 0); PrepCall(p, r, n); load(x); load(y); Call(p, r, n); PutDO(A.MOV, x, rh, A.Word); x.r := RH; x.mode := Reg; allocR
        END
      END
    ELSE (*op = OM4S.mod*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a MOD y.a ELSE S.Mark("bad modulus") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) THEN load(x); t.ofs := y.a; A.eswDO(mcode, A.MOd, t, x, A.Word, RH);
        x.mode := Reg; x.r := y.r; x.reg := x.r; x.am := A.Register; x.ofs := 0
      ELSE IF arith[1] = NIL THEN S.Mark("import Arith.div procedure")
        ELSE IF traps[6] # NIL THEN PutDO(A.CMP, y, c0, A.Word); Trap(A.GE, 6); IF y.mode IN {Reg, RegI} THEN freeR END END;
          MakeItem(p, arith[1], 0); PrepCall(p, r, n); load(x); load(y); Call(p, r, n); PutDO(A.MOV, y, rh, A.Word); x.r := RH; x.mode := Reg; allocR
        END
      END
    END
  END DivOp;


  (* Code generation for set operators *)

  PROCEDURE Singleton*(VAR x: Item);  (* x := {x} *)
  BEGIN
    IF x.mode = OM4B.Const THEN x.a := LSL(1, x.a)
    ELSE load(x); OM4A.encMOVImm32(mcode, RH, 1); OM4A.encShiftReg(mcode, OM4A.LSl, x.r, RH,  x.r)
    END
  END Singleton;

  PROCEDURE Set*(VAR x, y: Item);   (* x := {x .. y} *)
  BEGIN
    IF (x.mode = OM4B.Const) & ( y.mode = OM4B.Const) THEN
      IF x.a <= y.a THEN x.a := LSL(2, y.a) - LSL(1, x.a) ELSE x.a := 0 END
    ELSE
      IF (x.mode = OM4B.Const) & (x.a <= 8) THEN x.a := LSL(-1, x.a)
      ELSE load(x); OM4A.encMOVImm32(mcode, RH, -1); OM4A.encShiftReg(mcode, OM4A.LSl, x.r, RH, x.r)
      END;
      IF (y.mode = OM4B.Const) & (y.a < 8) THEN OM4A.encMOVImm32(mcode, RH, LSL(-2, y.a)); y.mode := Reg; y.r := RH; incR
      ELSE load(y); OM4A.encMOVImm32(mcode, RH, -2); OM4A.encShiftReg(mcode, OM4A.LSl, y.r, RH, y.r)
      END;      
      IF x.mode = OM4B.Const THEN
        IF x.a # 0 THEN OM4A.encDPImm32(mcode, OM4A.EOR, y.r, y.r, RH, -1);
          OM4A.encDPImm32(mcode, OM4A.AND, RH-1, y.r, RH, x.a)
        END;
        x.mode := Reg; x.r := RH-1
      ELSE DEC(RH); OM4A.encDPReg(mcode, OM4A.BIC, x.r, x.r, y.r, 0)
      END
    END
  END Set;

  PROCEDURE In*(VAR x, y: Item);  (* x := x IN y *)
  BEGIN load(y);
    IF x.mode = OM4B.Const THEN OM4A.encShiftImm5(mcode, OM4A.ROr, y.r, y.r, (x.a + 1) MOD 20H); DEC(RH)
    ELSE load(x); OM4A.encDPImm32(mcode, OM4A.ADD, x.r, x.r, RH, 1); OM4A.encShiftReg(mcode, OM4A.ROr, y.r, y.r, x.r); DEC(RH, 2)
    END ;
    SetCC(x, OM4A.MI)
  END In;

  PROCEDURE SetOp*(op: LONGINT; VAR x, y: Item);   (* x := x op y *)
    VAR xset, yset: SET; (*x.type.form = Set*)
  BEGIN
    IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN
      xset := SYSTEM.VAL(SET, x.a); yset := SYSTEM.VAL(SET, y.a);
      IF op = OM4S.plus THEN xset := xset + yset
      ELSIF op = OM4S.minus THEN xset := xset - yset
      ELSIF op = OM4S.times THEN xset := xset * yset
      ELSIF op = OM4S.rdiv THEN xset := xset / yset
      END ;
      x.a := SYSTEM.VAL(LONGINT, xset)
    ELSIF y.mode = OM4B.Const THEN
      load(x);
      IF op = OM4S.plus THEN OM4A.encDPImm32(mcode, OM4A.ORR, x.r, x.r, RH, y.a)
      ELSIF op = OM4S.minus THEN OM4A.encDPImm32(mcode, OM4A.BIC, x.r, x.r, RH, y.a)
      ELSIF op = OM4S.times THEN OM4A.encDPImm32(mcode, OM4A.AND, x.r, x.r, RH, y.a)
      ELSIF op = OM4S.rdiv THEN OM4A.encDPImm32(mcode, OM4A.EOR, x.r, x.r, RH, y.a)
      END ;
    ELSE load(x); load(y);
      IF op = OM4S.plus THEN OM4A.encDPReg(mcode, OM4A.ORR, RH-2, x.r, y.r, 0)
      ELSIF op = OM4S.minus THEN OM4A.encDPReg(mcode, OM4A.BIC, RH-2, x.r, y.r, 0)
      ELSIF op = OM4S.times THEN OM4A.encDPReg(mcode, OM4A.AND, RH-2, x.r, y.r, 0)
      ELSIF op = OM4S.rdiv THEN OM4A.encDPReg(mcode, OM4A.EOR, RH-2, x.r, y.r, 0)
      END ;
      DEC(RH); x.r := RH-1
    END 
  END SetOp;

  (* Code generation for relations *)

  PROCEDURE IntCompare*(VAR x, y, z: Item);   (* x < y *)
  BEGIN
    IF (y.mode = OM4B.Const) & (y.type.form # OM4B.Proc) THEN
      load(x); OM4A.encCMPImm(mcode, x.r, RH, y.a); DEC(RH)
    ELSE
      IF (x.mode = Cond) OR (y.mode = Cond) THEN OM4S.Mark("not implemented") END ;
      load(x); load(y); OM4A.encCMPReg(mcode, x.r, y.r); DEC(RH, 2)
    END;
    SetCC(x, z.a)
  END IntCompare;

  PROCEDURE IntRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
  BEGIN
    IF (y.mode = OM4B.Const) & (y.type.form # OM4B.Proc) THEN
      load(x);
      IF (y.a # 0) OR ~(op IN {OM4S.eql, OM4S.neq}) OR ~mcode.lastInstrSetFlags THEN
        OM4A.encCMPImm(mcode, x.r, RH, y.a)
      END;
      DEC(RH)
    ELSE
      IF (x.mode = Cond) OR (y.mode = Cond) THEN OM4S.Mark("not implemented") END ;
      load(x); load(y); OM4A.encCMPReg(mcode, x.r, y.r); DEC(RH, 2)
    END ;
    SetCC(x, relmap[op - OM4S.eql])
  END IntRelation;

  PROCEDURE RealRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
  BEGIN loadFP(x);
    IF (y.mode = OM4B.Const) & (y.a = 0) THEN OM4A.encFPOpReg(mcode, OM4A.VCMP0, x.r, 0, 0); DEC(SH)
    ELSE loadFP(y); OM4A.encFPOpReg(mcode, OM4A.VCMP, x.r, 0, y.r); DEC(SH, 2)
    END;
    OM4A.Put0(mcode, OM4A.VMRS + APSRnzcv*OM4A.C12);
    mcode.lastInstrSetFlags := TRUE;
    SetCC(x, relmap[op - OM4S.eql])
  END RealRelation;

  PROCEDURE StringRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
    (*x, y are char arrays or strings*)
    VAR pc0, tbf0: LONGINT;
  BEGIN
    IF x.type.form = OM4B.String THEN loadStringAdr(x) ELSE loadAdr(x) END ;
    IF y.type.form = OM4B.String THEN loadStringAdr(y) ELSE loadAdr(y) END ;
  (*Compare:*) pc0 := mcode.pc;
    OM4A.encMemImm8PUW(mcode, OM4A.LDRBIT3, RH, x.r, FALSE, TRUE, TRUE, 1);
    OM4A.encMemImm8PUW(mcode, OM4A.LDRBIT3, RH+1, y.r, FALSE, TRUE, TRUE, 1);
    OM4A.encCMPReg(mcode, RH, RH+1); tbf0 := mcode.pc; OM4A.Put1(mcode, OM4A.BCT1 + OM4A.NE*OM4A.C8); (*OM4A.BC OM4A.NE Fin*)
    incR; OM4A.encCMPImm(mcode, RH-1, RH, 0); DEC(RH); OM4A.encBackBranch(mcode, OM4A.NE, pc0); (*OM4A.BC OM4A.NE Compare*)
  (* Fin: *) OM4A.fix8(mcode, tbf0, mcode.pc - tbf0 - 4);
    DEC(RH, 2); SetCC(x, relmap[op - OM4S.eql])
  END StringRelation;

  (* Code generation of Assignments *)

  PROCEDURE StrToChar*(VAR x: Item);
  BEGIN x.type := OM4B.charType; DEC(strx, 4); x.a := ORD(str[x.a])
  END StrToChar;

  PROCEDURE Store*(VAR x, y: Item); (* x := y *)
    VAR op: LONGINT;
  BEGIN IF ~(y.mode IN {Reg, FPReg}) THEN
      IF y.type.form = OM4B.Real THEN loadFP(y) ELSE load(y) END
    END;
    IF x.type.size = 1 THEN op := OM4A.STRB ELSE op := OM4A.STR END ;
    IF x.mode = OM4B.Var THEN
      IF x.r > 0 THEN (*local*)
        IF y.mode = FPReg THEN ASSERT((x.a + frame) MOD OM4A.C2 = 0);
          IF x.a + frame >= OM4A.C10 THEN OM4S.Mark("local real var too far")
          END;
          OM4A.Put0(mcode, OM4A.VSTRT2 + 1*OM4A.C23(*ADD*) +
            y.r MOD OM4A.C1*OM4A.C22 + SP*OM4A.C16 + y.r DIV OM4A.C1*OM4A.C12 +
            (x.a + frame) DIV OM4A.C2)
        ELSE OM4A.encMemImm32(mcode, op, y.r, SP, RH, x.a + frame)
        END
      ELSE GetStaticVarAddress(x, RH);
        IF y.mode = FPReg THEN
          OM4A.Put0(mcode, OM4A.VSTRT2 + 1*OM4A.C23(*ADD*) +
            y.r MOD OM4A.C1*OM4A.C22 + RH*OM4A.C16 + y.r DIV OM4A.C1*OM4A.C12)
        ELSE incR; OM4A.encMemImm32(mcode, op, y.r, RH-1, RH, 0); DEC(RH) END
      END    
    ELSIF x.mode = OM4B.Par THEN
      incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a + frame); DEC(RH);
      IF y.mode = FPReg THEN ASSERT((x.b) MOD OM4A.C2 = 0);
        IF x.a + frame >= OM4A.C10 THEN OM4S.Mark("real param offset 1 too far")
        END;
        OM4A.Put0(mcode, OM4A.VSTRT2 + 1*OM4A.C23 + y.r MOD OM4A.C1*OM4A.C22 + RH*OM4A.C16 + y.r DIV OM4A.C1*OM4A.C12 + (x.b) DIV OM4A.C2)
      ELSE incR; OM4A.encMemImm32(mcode, op, y.r, RH-1, RH, x.b); DEC(RH)
      END
    ELSIF x.mode = RegI THEN
      IF y.mode = FPReg THEN ASSERT((x.a) MOD OM4A.C2 = 0);
        IF x.a + frame >= OM4A.C10 THEN OM4S.Mark("RegI too far")
        END;
        OM4A.Put0(mcode, OM4A.VSTRT2 + 1*OM4A.C23 + y.r MOD OM4A.C1*OM4A.C22 + x.r*OM4A.C16 + y.r DIV OM4A.C1*OM4A.C12 + (x.a + frame) DIV OM4A.C2);
        DEC(SH)
      ELSE OM4A.encMemImm32(mcode, op, y.r, x.r, RH, x.a); DEC(RH)
      END
    ELSE OM4S.Mark("bad mode in Store")
    END;
    IF y.mode = FPReg THEN DEC(SH) ELSE DEC(RH)
    END
  END Store;

  PROCEDURE StoreStruct*(VAR x, y: Item); (* x := y, frame = 0 *)
    VAR s, pc0, pc1: LONGINT;
  BEGIN
    pc0 := -1;
    IF y.type.size # 0 THEN
      loadAdr(x); loadAdr(y);
      IF (x.type.form = OM4B.Array) &  (x.type.len > 0) THEN
        IF y.type.len >= 0 THEN 
          IF x.type.size = y.type.size THEN OM4A.encMOVImm32(mcode, RH, (y.type.size+3) DIV 4)
          ELSE OM4S.Mark("different length/size, not implemented")
          END
        ELSE (*y  open array*) incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, y.a+4); DEC(RH); s := y.type.base.size;  (*element size*)
          incR; OM4A.encCMPImm(mcode ,RH-1, RH, 0); DEC(RH); pc0 := mcode.pc; OM4A.Put1(mcode, OM4A.BCT1 + OM4A.EQ*OM4A.C8); (*BEQ L0*)
          IF s = 1 THEN incR; OM4A.encDPImm32(mcode, OM4A.ADD, RH-1, RH-1, RH, 3); DEC(RH); OM4A.encShiftImm5(mcode, OM4A.ASr, RH, RH, 2)
          ELSIF s # 4 THEN ASSERT(s MOD 4 = 0); incR; OM4A.encMOVImm32(mcode, RH, s DIV 4); OM4A.encMUL(mcode, RH-1, RH-1, RH); DEC(RH)
          END;
          IF check THEN
            incR; OM4A.encCMPImm(mcode, RH-1, RH, (x.type.size+3) DIV 4); Trap(OM4A.GT, 3); DEC(RH)
          END
        END
      ELSIF x.type.form = OM4B.Record THEN OM4A.encMOVImm32(mcode, RH, x.type.size DIV 4)
      ELSE OM4S.Mark("inadmissible assignment")
      END ;
      (*L1*) pc1 := mcode.pc; incR;
      OM4A.encMemImm8PUW(mcode, OM4A.LDRIT4, RH, y.r, FALSE, TRUE, TRUE, 4);
      OM4A.encMemImm8PUW(mcode, OM4A.STRIT4, RH, x.r, FALSE, TRUE, TRUE, 4);
      OM4A.encDPImm32(mcode, OM4A.SUB, RH-1, RH-1, RH, 1); DEC(RH);
      OM4A.encBackBranch(mcode, OM4A.NE, pc1); (*BNE L1*)
      (*L0:*) IF pc0 # -1 THEN OM4A.fix8(mcode, pc0, mcode.pc - pc0 - 4)
              END
    END;
    RH := 0
  END StoreStruct;

  PROCEDURE CopyString*(VAR x, y: Item);  (* x := y *) 
     VAR len, pc0: LONGINT;
   BEGIN loadAdr(x); len := x.type.len;
    IF len >= 0 THEN
      IF len < y.b THEN OM4S.Mark("string too long") END
    ELSIF check THEN incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a+4); (*open array len, frame = 0*)
      OM4A.encCMPImm(mcode, RH-1, RH, y.b); DEC(RH); Trap(OM4A.LT, 3)
    END ;
    loadStringAdr(y);
    (*L0:*) pc0 := mcode.pc;
    OM4A.encMemImm8PUW(mcode, OM4A.LDRIT4, RH, y.r, FALSE, TRUE, TRUE, 4);
    OM4A.encMemImm8PUW(mcode, OM4A.STRIT4, RH, x.r, FALSE, TRUE, TRUE, 4);
    OM4A.encShiftImm5(mcode, OM4A.ASr, RH, RH, 24); OM4A.encBackBranch(mcode, OM4A.NE, pc0); (*BNE L0*)
    RH := 0
   END CopyString;
  
  (* Code generation for parameters *)
  
  PROCEDURE OpenArrayParam*(VAR x: Item);
  BEGIN loadAdr(x);
    IF x.type.len >= 0 THEN OM4A.encMOVImm32(mcode, RH, x.type.len) 
    ELSE incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a+4+frame); DEC(RH)
    END ; incR
  END OpenArrayParam;

  PROCEDURE VarParam*(VAR x: Item; ftype: OM4B.Type);
    VAR xmd: INTEGER;
  BEGIN xmd := x.mode; loadAdr(x);
    IF (ftype.form = OM4B.Array) & (ftype.len < 0) THEN (*open array*)
      IF x.type.len >= 0 THEN OM4A.encMOVImm32(mcode, RH, x.type.len) 
      ELSE  incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a+4+frame); DEC(RH)
      END; incR
    ELSIF (ftype.form = OM4B.Record) & check THEN
      IF xmd = OM4B.Par THEN
        OM4A.encMemImm32(mcode, OM4A.LDR, RH, SP, RH, x.a+4+frame); incR 
      ELSE loadTypTagAdr(x.type)
      END
    END
  END VarParam;

  PROCEDURE ValueParam*(VAR x: Item);
  BEGIN load(x) (*Force loading in core registers even for real*)
  END ValueParam;

  PROCEDURE StringParam*(VAR x: Item);
  BEGIN loadStringAdr(x); OM4A.encMOVImm32(mcode, RH, x.b); incR  (*len*)
  END StringParam;

  (*For Statements*)

  PROCEDURE For0*(VAR x, y: Item);
  BEGIN load(y)
  END For0;

  PROCEDURE For1*(VAR x, y, z, w: Item; VAR L: LONGINT);
  BEGIN 
    load(z); OM4A.encCMPReg(mcode, y.r, z.r); DEC(RH);
    L := mcode.pc;
    IF w.a > 0 THEN OM4A.Put0(mcode, OM4A.BRCSIG*OM4A.C27 + OM4A.GT*OM4A.C22);
    ELSIF w.a < 0 THEN OM4A.Put0(mcode, OM4A.BRCSIG*OM4A.C27 + OM4A.LT*OM4A.C22);
    ELSE OM4S.Mark("zero increment");
      OM4A.Put0(mcode, OM4A.BRCSIG*OM4A.C27 + OM4A.MI*OM4A.C22);
    END;
    Store(x, y)
  END For1;

  PROCEDURE For2*(VAR x, y, w: Item);
  BEGIN load(x); OM4A.encDPImm32(mcode, OM4A.ADD, x.r, x.r, RH, w.a); DEC(RH)
  END For2;

  (* Branches, procedure calls, procedure prolog and epilog *)

  PROCEDURE Here*(): LONGINT;
  BEGIN RETURN mcode.pc
  END Here;

  PROCEDURE FJump*(VAR L: LONGINT);
  BEGIN OM4A.Put0(mcode, OM4A.BRSIG*OM4A.C27 + L); L := mcode.pc-4
  END FJump;

  PROCEDURE CFJump*(VAR x: Item);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    OM4A.Put0(mcode, OM4A.BRCSIG*OM4A.C27 + OM4A.negated(x.r)*OM4A.C22 + x.a);
    OM4A.FixLink(mcode, x.b); x.a := mcode.pc-4
  END CFJump;

  PROCEDURE BJump*(L: LONGINT);
  BEGIN OM4A.encBackBranch(mcode, OM4A.AL, L)
  END BJump;

  PROCEDURE CBJump*(VAR x: Item; L: LONGINT);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    OM4A.encBackBranch(mcode, OM4A.negated(x.r), L); OM4A.FixLink(mcode, x.b); OM4A.FixLinkWith(mcode, x.a, L)
  END CBJump;

  PROCEDURE Fixup*(VAR x: Item);
  BEGIN OM4A.FixLink(mcode, x.a)
  END Fixup;

  PROCEDURE Enter*(parblksize, locblksize: LONGINT; int: BOOLEAN; reglim: INTEGER);
    VAR r: LONGINT;
  BEGIN OfsPTOS(0, FALSE); frame := 0;
    IF locblksize >= OM4A.C16 THEN OM4S.Mark("local variables size exeeded") END;
    r := (parblksize-4) DIV 4;
    IF int THEN (*interrupt procedure, lot of registers are already saved in interrupt frame*)
      (*Store interrupt frame address in R0*)
      OM4A.encDPImm32(mcode, OM4A.TST, 0, LR, r, 4);
      OM4A.IfThen(mcode, "E", OM4A.EQ);
      OM4A.encMRS(mcode, 0, MSP);
      OM4A.encMRS(mcode, 0, PSP)
    END;

    IF locblksize - parblksize # 0 THEN
      OM4A.encDPImm32(mcode, OM4A.SUB, SP, SP, r, locblksize - parblksize); OfsPTOS((locblksize - parblksize) DIV 4, TRUE) END;

    IF r > 0 THEN OM4A.PushRegs(mcode, 0, r-1); OfsPTOS(r, TRUE) END;
    IF reglim >= 0 THEN (*sets the number of usable registers. This is useful to ensure that interrupt handlers do not corrupt registers*)
      RL := reglim+1; IF reglim >= 4 THEN
       OM4A.PushRegs(mcode, 4, reglim); OfsPTOS(reglim - 3, TRUE) (*protect usable registers, assuming that R0 to R3 are already saved in interrupt frame*)
      END
    END;
    (*PUSH T1 LR *) OM4A.Put1(mcode, OM4A.PUSHT1 + OM4A.C8); OfsPTOS(1, TRUE)
  END Enter;

  PROCEDURE Return*(form: INTEGER; VAR x: Item; size: LONGINT; reglim: INTEGER);
  BEGIN
    IF form # OM4B.NoTyp THEN 
      IF x.type.form = OM4B.Real THEN loadFP(x); ELSE load(x) END
    END;
    (*POP T3 LR *) OM4A.encMemImm8PUW(mcode, OM4A.LDRIT4, LR, SP, FALSE, TRUE, TRUE, 4); OfsPTOS(-1, TRUE);
    IF reglim >= 0 THEN IF reglim >= 4 THEN OM4A.PopRegs(mcode, 4, reglim); OfsPTOS(3 - reglim, TRUE) END; RL := SP END;
    IF size # 4 THEN OM4A.encDPImm32(mcode, OM4A.ADD, SP, SP, RH, size - 4); OfsPTOS((4 - size) DIV 4, TRUE) END;
    IF frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos # 0 THEN OM4S.DebugHex("stack seg", frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos) END;
    OM4A.Put1(mcode, OM4A.BX + LR*OM4A.C3); RH := 0; SH := 0;
  END Return;

  (* In-line code procedures*)

  PROCEDURE Increment*(upordown: LONGINT; VAR x, y: Item);
    VAR op, zr, vl, vs: LONGINT;
  BEGIN (*frame = 0*)
    IF upordown = 0 THEN op := OM4A.ADD ELSE op := OM4A.SUB END ;
    IF x.type = OM4B.byteType THEN vl := OM4A.LDRB; vs := OM4A.STRB ELSE vl := OM4A.LDR; vs := OM4A.STR END ;
    IF y.type.form = OM4B.NoTyp THEN y.mode := OM4B.Const; y.a := 1 END ;
    IF (x.mode = OM4B.Var) & (x.r > 0) THEN
      zr := RH; incR; OM4A.encMemImm32(mcode, vl, zr, SP, RH, x.a);
      IF y.mode = OM4B.Const THEN OM4A.encDPImm32(mcode, op, zr, zr, RH, y.a) ELSE load(y); OM4A.encDPReg(mcode, op, zr, zr, y.r, 0); DEC(RH) END ;
      OM4A.encMemImm32(mcode, vs, zr, SP, RH, x.a); DEC(RH)
    ELSE loadAdr(x); zr := RH; incR; OM4A.encMemImm32(mcode, vl, zr, x.r, RH, 0);
      IF y.mode = OM4B.Const THEN OM4A.encDPImm32(mcode, op, zr, zr, RH, y.a) ELSE load(y); OM4A.encDPReg(mcode, op, zr, zr, y.r, 0); DEC(RH) END ;
      OM4A.encMemImm32(mcode, vs, zr, x.r, RH, 0); DEC(RH, 2)
    END
  END Increment;

  PROCEDURE Include*(inorex: LONGINT; VAR x, y: Item);
    VAR op, zr: LONGINT;
  BEGIN loadAdr(x); zr := RH; incR; OM4A.encMemImm32(mcode, OM4A.LDR, zr, x.r, RH, 0);
    IF inorex = 0 THEN op := OM4A.ORR ELSE op := OM4A.BIC END ;
    IF y.mode = OM4B.Const THEN OM4A.encDPImm32(mcode, op, zr, zr, RH, LSL(1, y.a))
    ELSE load(y); OM4A.encMOVImm32(mcode, RH, 1); OM4A.encShiftReg(mcode, OM4A.LSl, y.r, RH, y.r); OM4A.encDPReg(mcode, op, zr, zr, y.r, 0); DEC(RH)
    END ;
    OM4A.encMemImm32(mcode, OM4A.STR, zr, x.r, RH, 0); DEC(RH, 2)
  END Include;

  PROCEDURE Assert*(VAR x: Item);
    VAR cond, pc0: LONGINT;
  BEGIN
    pc0 := 0;
    IF x.mode # Cond THEN loadCond(x) END;
    IF x.a = 0 THEN cond := OM4A.negated(x.r);
    ELSE pc0 := mcode.pc; OM4A.Put1(mcode, OM4A.BCT1 + x.r*OM4A.C8);
      OM4A.FixLink(mcode, x.a); cond := OM4A.AL
    END ;
    Trap(cond, 7); OM4A.FixLink(mcode, x.b);
    IF pc0 # 0 THEN OM4A.fix8(mcode, pc0, mcode.pc - pc0 - 4) END
  END Assert; 

  PROCEDURE New*(VAR x: Item);
  BEGIN loadAdr(x); loadTypTagAdr(x.type.base); (*Trap(OM4A.AL, 0)*) OM4A.Put1(mcode, OM4A.SVC); RH := 0; SH := 0
  END New;

  PROCEDURE Pack*(VAR x, y: Item);
    VAR z!: Item;
  BEGIN (*Load x in a core register*)
    z := x; load(x); load(y);
    OM4A.encDPReg(mcode, OM4A.ADD, x.r, x.r, y.r, 23); DEC(RH); Store(z, x);
  END Pack;

  PROCEDURE Unpk*(VAR x, y: Item);
    VAR z!, e0!: Item;
  BEGIN (*Load x in a core register*)
    z := x; load(x); e0.mode := Reg; e0.r := RH; e0.type := OM4B.intType;
    OM4A.encShiftImm5(mcode, OM4A.ASr, RH, x.r, 23); 
    incR; OM4A.encDPImm32(mcode, OM4A.SUB, RH-1, RH-1, RH, 127); DEC(RH);
    Store(y, e0); incR; OM4A.encDPReg(mcode, OM4A.SUB, x.r, x.r, RH, 23); Store(z, x);
  END Unpk;

(* The SVC mechanism will be used to communicate with undelying firmware,
   in order to hide board level details, like the LED attachement to ports.*)
   
  PROCEDURE Led*(VAR x: Item);
  (*SVC #1 is assigned to LEDS*)
  BEGIN load(x); OM4A.Put1(mcode, OM4A.SVC + 1); DEC(RH)
  END Led;

  (*Call service*)
  PROCEDURE SVC*(VAR x: Item);
  BEGIN (*x.mode = Const*)
    OM4A.Put1(mcode, OM4A.SVC + x.a MOD OM4A.C8); 
    x.mode := Reg; x.r := 0; RH := 1
  END SVC;
  
  PROCEDURE Get*(VAR x, y: Item);
  BEGIN load(x); x.type := y.type; x.mode := RegI; x.a := 0; Store(y, x)
  END Get;

  PROCEDURE Put*(VAR x, y: Item);
  BEGIN load(x); x.type := y.type; x.mode := RegI; x.a := 0; Store(x, y)
  END Put;

  PROCEDURE Copy*(VAR x, y, z: Item);
    VAR pc0, pc1: LONGINT;
  BEGIN load(x); load(y);
    pc0 := 0;
    IF z.mode = OM4B.Const THEN
      IF z.a > 0 THEN load(z) ELSE OM4S.Mark("bad count") END
    ELSE load(z);
      IF check THEN 
          IF ~mcode.lastInstrSetFlags THEN OM4A.encCMPImm(mcode, z.r, RH, 0) END;
        Trap(OM4A.LT, 3)
      END;
      pc0 := mcode.pc; OM4A.Put1(mcode, OM4A.BCT1 + OM4A.EQ*OM4A.C8); (*BEQ L0*)
    END ;
    pc1 := mcode.pc;
    OM4A.encMemImm8PUW(mcode, OM4A.LDRIT4, RH, x.r, FALSE, TRUE, TRUE, 4);
    OM4A.encMemImm8PUW(mcode, OM4A.STRIT4, RH, y.r, FALSE, TRUE, TRUE, 4);
    OM4A.encDPImm32(mcode, OM4A.SUB, z.r, z.r, RH, 1); OM4A.encBackBranch(mcode, OM4A.NE, pc1); (*BNE L1*)
    IF pc0 # 0 THEN OM4A.fix8(mcode, pc0, mcode.pc - pc0 - 4) END; DEC(RH, 3)
  END Copy;

  PROCEDURE LDREG*(VAR x, y: Item);
  BEGIN (*x is constant*)
    load(y);  IF x.a > OM4A.C4 THEN OM4A.encMSR(mcode, y.r, x.a - OM4A.C4) END; RH := 0
  END LDREG;

  (*In-line code functions*)

  PROCEDURE Abs*(VAR x: Item);
  BEGIN
    IF x.mode = OM4B.Const THEN x.a := ABS(x.a)
    ELSE IF x.type.form = OM4B.Real THEN loadFP(x); ELSE load(x) END;
      IF x.mode = FPReg THEN OM4A.encFPOpReg(mcode, OM4A.VABS, x.r, 0, x.r)
      ELSE OM4A.encCMPImm(mcode ,x.r, RH, 0); OM4A.IfThen(mcode, "", OM4A.LT);
        OM4A.encDPImm32(mcode, OM4A.RSB, x.r, x.r, RH, 0)
      END
    END
  END Abs;

  PROCEDURE Sqrt*(VAR x: Item);
  BEGIN
    IF x.mode = OM4B.Const THEN x.a := SYSTEM.VAL(INTEGER, SQRT(SYSTEM.VAL(REAL, x.a)))
    ELSE loadFP(x); OM4A.encFPOpReg(mcode, OM4A.VSQRT, x.r, 0, x.r)
    END
  END Sqrt;

  PROCEDURE Odd*(VAR x: Item);
  BEGIN load(x); OM4A.encShiftImm5(mcode, OM4A.ROr, x.r, x.r, 1); SetCC(x, OM4A.MI); DEC(RH)
  END Odd;

  PROCEDURE Floor*(VAR x: Item);
  BEGIN loadFP(x); OM4A.encFPOpReg(mcode, OM4A.VCVTSF, x.r, 0, x.r);
    x.type := OM4B.intType;
  END Floor;

  PROCEDURE Float*(VAR x: Item);
  BEGIN x.type := OM4B.realType; loadFP(x);
    OM4A.encFPOpReg(mcode, OM4A.VCVTFS, x.r, 0, x.r)
  END Float;

  PROCEDURE Ord*(VAR x: Item);
  BEGIN
    IF x.mode IN {OM4B.Var, OM4B.Par, RegI, Cond} THEN load(x) END
  END Ord;

  PROCEDURE Len*(VAR x: Item);
  BEGIN
    IF x.type.len >= 0 THEN
      IF x.mode = RegI THEN DEC(RH) END ;
      x.mode := OM4B.Const; x.a := x.type.len
    ELSE (*open array*) incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a + 4 + frame);
      x.mode := Reg; x.r := RH-1
    END 
  END Len;

  PROCEDURE Shift*(fct: LONGINT; VAR x, y: Item);
    VAR op: LONGINT;
  BEGIN IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN
      IF fct = 0 THEN x.a := LSL(x.a, y.a) ELSIF fct = 1 THEN x.a := ASR(x.a, y.a) ELSIF fct = 2 THEN x.a := ROR(x.a, y.a) ELSE x.a := LSR(x.a, y.a) END 
    ELSE load(x);
      IF fct = 0 THEN op := OM4A.LSl ELSIF fct = 1 THEN op := OM4A.ASr ELSIF fct = 2 THEN op := OM4A.ROr ELSE op := OM4A.LSr END ;
      IF y.mode = OM4B.Const THEN OM4A.encShiftImm5(mcode, op, x.r, x.r, y.a MOD 20H)
      ELSE load(y); OM4A.encShiftReg(mcode, op, RH-2, x.r, y.r); DEC(RH); x.r := RH-1
      END
    END
  END Shift;

  PROCEDURE ADC*(VAR x, y: Item);
  BEGIN load(x); load(y); OM4A.encDPReg(mcode, OM4A.ADc, x.r, x.r, y.r, 0); DEC(RH)
  END ADC;

  PROCEDURE SBC*(VAR x, y: Item);
  BEGIN load(x); load(y); OM4A.encDPReg(mcode, OM4A.SBc, x.r, x.r, y.r, 0); DEC(RH)
  END SBC;

  PROCEDURE UML*(VAR x, y: Item);
  BEGIN load(x); load(y); OM4A.Put0(mcode, OM4A.UMULL + x.r*OM4A.C16 + x.r*OM4A.C12 + y.r*OM4A.C8 + y.r); DEC(RH)
  END UML;

  PROCEDURE MBI*(VAR i: INTEGER);
  BEGIN (*x.mode = OM4B.Const*)
    IF i = 1 THEN OM4A.Put0(mcode, OM4A.DMB)
    ELSIF i = 2 THEN OM4A.Put0(mcode, OM4A.DSB)
    ELSIF i = 3 THEN OM4A.Put0(mcode, OM4A.ISB)
    ELSE OM4S.Mark("bad MBI")
    END
  END MBI;

  PROCEDURE Rbit*(VAR x: Item);
  BEGIN load(x); OM4A.Put0(mcode, OM4A.RBIT + x.r*OM4A.C16 + x.r*OM4A.C8 + x.r)
  END Rbit;

  PROCEDURE Bit*(VAR x, y: Item);
  BEGIN IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) &
    ((x.a >= 20000000H) & (x.a < 20100000H) OR (x.a >= 40000000H) & (x.a < 40100000H)) THEN
      (*Use bit banding*)
      x.a := x.a DIV OM4A.C28*OM4A.C28 + 2000000H + (x.a MOD OM4A.C28 + y.a DIV 8)*32 + y.a MOD 8*4; load(x);
      OM4A.encMemImm32(mcode, OM4A.LDR, x.r, x.r, RH, 0); x.type := OM4B.boolType
    ELSE load(x);
      OM4A.encMemImm32(mcode, OM4A.LDR, x.r, x.r, RH, 0);
      IF y.mode = OM4B.Const THEN OM4A.encShiftImm5(mcode, OM4A.ROr, x.r, x.r, y.a+1); DEC(RH)
      ELSE load(y); OM4A.encDPImm32(mcode, OM4A.ADD, y.r, y.r, RH, 1); OM4A.encShiftReg(mcode, OM4A.ROr, x.r, x.r, y.r); DEC(RH, 2)
      END ;
      SetCC(x, OM4A.MI)
    END
  END Bit;

  PROCEDURE Register*(VAR x: Item);
  BEGIN (*x.mode = Const*)
    OM4A.encMOVReg(mcode, RH, x.a MOD OM4A.C4); x.mode := Reg; x.r := RH; incR
  END Register;

  PROCEDURE Adr*(VAR x: Item);
  BEGIN 
    IF x.mode IN {OM4B.Var, OM4B.Par, RegI} THEN loadAdr(x)
    ELSIF (x.mode = OM4B.Const) & (x.type.form = OM4B.Proc) THEN load(x)
    ELSIF (x.mode = OM4B.Const) & (x.type.form = OM4B.String) THEN loadStringAdr(x)
    ELSE OM4S.Mark("not addressable")
    END
  END Adr;

  PROCEDURE Condition*(VAR x: Item);
  BEGIN (*x.mode = Const*) SetCC(x, x.a)
  END Condition;

  PROCEDURE Open*(v: INTEGER);
  BEGIN OM4A.Init(mcode); frmOfsSegs.NofSegs := 0; frmOfsSegs.Segs[0].ofsptos := 0;
    tdx := 0; strx := 0; RH := 0; SH := 0; fixORGP := 0; fixORGD := 0; fixORGT := 0; check := v # 0; version := v;
    IF v = 0 THEN mcode.pc := 4; (*Make room for the jump to entry point instruction*) END
  END Open;

  PROCEDURE SetDataSize*(dc: LONGINT);
  BEGIN varsize := dc
  END SetDataSize;

  PROCEDURE Header*;
  BEGIN entry := mcode.pc; OfsPTOS(0, FALSE);
    IF version = 0 THEN OM4A.modify(mcode, 0, OM4A.BT4 + OM4A.formatEvenImm25(mcode.pc-4))
    ELSE (*PUSH T1 LR *) OM4A.Put1(mcode, OM4A.PUSHT1 + OM4A.C8); OfsPTOS(1, TRUE)
    END
  END Header;

  PROCEDURE NofPtrs(typ: OM4B.Type): LONGINT;
    VAR fld!: OM4B.Object; n: LONGINT;
  BEGIN
    IF (typ.form = OM4B.Pointer) OR (typ.form = OM4B.NilTyp) THEN n := 1
    ELSIF typ.form = OM4B.Record THEN
      fld := typ.dsc; n := 0;
      WHILE fld # NIL DO n := NofPtrs(fld.type) + n; fld := fld.next END
    ELSIF typ.form = OM4B.Array THEN n := NofPtrs(typ.base) * typ.len
    ELSE n := 0
    END ;
    RETURN n
  END NofPtrs;

  PROCEDURE FindPtrs(VAR R: Files.Rider; typ: OM4B.Type; adr: LONGINT);
    VAR fld!: OM4B.Object; i, s: LONGINT;
  BEGIN
    IF (typ.form = OM4B.Pointer) OR (typ.form = OM4B.NilTyp) THEN Files.WriteInt(R, adr)
    ELSIF typ.form = OM4B.Record THEN
      fld := typ.dsc;
      WHILE fld # NIL DO FindPtrs(R, fld.type, fld.val + adr); fld := fld.next END
    ELSIF typ.form = OM4B.Array THEN
      s := typ.base.size;
      FOR i := 0 TO typ.len-1 DO FindPtrs(R, typ.base, i*s + adr) END
    END
  END FindPtrs;

  PROCEDURE Close*(VAR modid: OM4S.Ident; key, nofent: LONGINT);
    VAR obj!, obj2!: OM4B.Object;
      i, comsize, nofimps, nofptrs, nofusedextprocs, size: LONGINT;
      name: OM4S.Ident;
      F!: Files.File; R!: Files.Rider;
  BEGIN  (*exit code*)
    IF version = 0 THEN
      (*OM4A.BX R0 : Jump to the beginning of the program loaded by the Boot Loader*)
      OM4A.encMOVImm32(mcode, 0, VarORG0+1); (*odd address to thumb mode*) OM4A.Put1(mcode, OM4A.BX)
    ELSE (*POP T3 LR *) OM4A.encMemImm8PUW(mcode, OM4A.LDRIT4, LR, SP, FALSE, TRUE, TRUE, 4); OfsPTOS(-1, TRUE);
      OM4A.Put1(mcode, OM4A.BX + LR*OM4A.C3)
    END ;
    obj := OM4B.topScope.next; nofimps := 0; comsize := 4; nofptrs := 0; nofusedextprocs := 0;
    (*count user external procedures*)
    WHILE obj # NIL DO
      IF (obj.class = OM4B.Mod) & (obj.dsc # OM4B.system) THEN INC(nofimps); (*count imports*)
        obj2 := obj.dsc;
        WHILE (obj2 # NIL) DO
          IF obj2.used & (obj2.lev < 0) & (obj2.class = OM4B.Const) & (obj2.type.form = OM4B.Proc) THEN INC(nofusedextprocs) (*count external procs called*)
          END;
          obj2 := obj2.next
        END
      ELSIF (obj.exno # 0) & (obj.class = OM4B.Const) & (obj.type.form = OM4B.Proc)
          & (obj.type.nofpar = 0) & (obj.type.base = OM4B.noType) THEN i := 0; (*count commands*)
        WHILE obj.name[i] # 0X DO INC(i) END ;
        i := (i+4) DIV 4 * 4; INC(comsize, i+4)
      ELSIF obj.class = OM4B.Var THEN INC(nofptrs, NofPtrs(obj.type))  (*count pointers*)
      END ;
      obj := obj.next
    END ;
    
    (*varsize includes type descriptors*)
    size := varsize + strx + comsize + (mcode.pc+3) DIV 4*4 + (nofimps + nofent + nofptrs + 1)*4 + nofusedextprocs*8;
    (*size is aligned on 4 bytes boundary*)
    
    OM4B.MakeFileName(name, modid, ".m4c"); (*write code file*)
    F := Files.New(name); Files.Set(R, F, 0); Files.WriteString(R, modid); Files.WriteInt(R, key); Files.Write(R, CHR(version));
    Files.WriteInt(R, size);
    obj := OM4B.topScope.next;
    WHILE (obj # NIL) & (obj.class = OM4B.Mod) DO  (*imports*)
      IF obj.dsc # OM4B.system THEN Files.WriteString(R, obj(OM4B.Module).orgname); Files.WriteInt(R, obj.val) END ;
      obj := obj.next
    END ;
    Files.Write(R, 0X);
    Files.WriteInt(R, tdx*4);
    i := 0;
    WHILE i < tdx DO Files.WriteInt(R, data[i]); INC(i) END ; (*type descriptors*)
    Files.WriteInt(R, varsize - tdx*4);  (*data*)
    Files.WriteInt(R, strx);
    FOR i := 0 TO strx-1 DO Files.Write(R, str[i]) END ;  (*strings*)
    Files.WriteInt(R, mcode.pc);  (*code len*)
    FOR i := 0 TO mcode.pc-1 DO Files.WriteByte(R, mcode.code[i]) END ;  (*program*)
    FOR i := 1 TO mcode.pc MOD 4 DO Files.WriteByte(R, 0) END ;  (*align to 4 byte boundary*)
    obj := OM4B.topScope.next;
    WHILE obj # NIL DO  (*commands*)
      IF (obj.exno # 0) & (obj.class = OM4B.Const) & (obj.type.form = OM4B.Proc) &
          (obj.type.nofpar = 0) & (obj.type.base = OM4B.noType) THEN
        Files.WriteString(R, obj.name); Files.WriteInt(R, obj.val)
      END ;
      obj := obj.next
    END ;
    Files.Write(R, 0X);
    Files.WriteInt(R, nofent); Files.WriteInt(R, entry);
    obj := OM4B.topScope.next;
    WHILE obj # NIL DO  (*entries*)
      IF obj.exno # 0 THEN
        IF (obj.class = OM4B.Const) & (obj.type.form = OM4B.Proc) OR (obj.class = OM4B.Var) THEN
          Files.WriteInt(R, obj.val);
        ELSIF obj.class = OM4B.Typ THEN
          IF obj.type.form = OM4B.Record THEN Files.WriteInt(R,  obj.type.len MOD OM4A.C16)
          ELSIF (obj.type.form = OM4B.Pointer) & ((obj.type.base.typobj = NIL) OR (obj.type.base.typobj.exno = 0)) THEN
            Files.WriteInt(R,  obj.type.base.len MOD OM4A.C16)
          END
        END
      END ;
      obj := obj.next
    END ;
    obj := OM4B.topScope.next;
    WHILE obj # NIL DO  (*pointer variables*)
      IF obj.class = OM4B.Var THEN FindPtrs(R, obj.type, obj.val) END ;
      obj := obj.next
    END ;
    Files.WriteInt(R, -1);
    Files.WriteInt(R, fixORGP); Files.WriteInt(R, fixORGD); Files.WriteInt(R, fixORGT); Files.WriteInt(R, entry);
    Files.Write(R, "O"); Files.Register(F);
    (*write object addresses to source position mapping in .osm file*)
    OM4B.MakeFileName(name, modid, ".osm"); F := Files.New(name); Files.Set(R, F, 0); Files.WriteInt(R, mcode.pc DIV 2); size := 1;
    FOR i := 1 TO mcode.pc DIV 2 - 1 DO 
      IF (size < 255) & (mcode.pos[i] = mcode.pos[i-1]) THEN INC(size) ELSE Files.WriteByte(R, size); Files.WriteInt(R, mcode.pos[i - 1]); size := 1 END
    END; Files.WriteByte(R, size); Files.WriteInt(R, mcode.pos[mcode.pc DIV 2 - 1]); Files.Register(F);
    (*write word offset with caller top of stack*)
    OfsPTOS(-1, FALSE); (*close last segment*) OM4B.MakeFileName(name, modid, ".rao"); F := Files.New(name); Files.Set(R, F, 0); 
    Files.WriteInt(R, frmOfsSegs.NofSegs);
    FOR i := 0 TO frmOfsSegs.NofSegs DO Files.WriteInt(R, frmOfsSegs.Segs[i].end); Files.WriteInt(R, frmOfsSegs.Segs[i].ofsptos) END;
    Files.Register(F)
  END Close;

BEGIN NEW(mcode); NEW(frmOfsSegs); A.SetGetOfsProc(GetOffset);
  cm1.reg := 0; c0.am := A.Immediate; c0.ofs := -1; t.obj := NIL;
  c0.reg := 0; c0.am := A.Immediate; c0.ofs := 0; t.obj := NIL;
  c1.reg := 0; c0.am := A.Immediate; c0.ofs := 1; t.obj := NIL;
  pc.reg := A.PC; pc.am := A.Register; pc.ofs := 0; pc.obj := NIL;
  sp.reg := A.SP; sp.am := A.Register; sp.ofs := 0; sp.obj := NIL;
  r4.reg := 4; r4.am := A.Register; r4.ofs := 0; r4.obj := NIL;
  r15.reg := 15; r15.am := A.Register; r15.ofs := 0; r15.obj := NIL;
  relmap[0] := OM4A.EQ; relmap[1] := OM4A.NE; relmap[2] := OM4A.LT; 
  relmap[3] := OM4A.LE; relmap[4] := OM4A.GT; relmap[5] := OM4A.GE;
  AllocUp := FALSE; RL := SP
END OM4G.
