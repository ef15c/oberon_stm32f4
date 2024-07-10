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
    obj*: B.Object; (*symbol object, for register variables and update of "used at" chain*)
    a*, b*, c: LONGINT;
    rdo*, tmp: BOOLEAN  (*read only*)
  END ;

  (* Item forms and meaning of fields:
    mode    c           a           b                      
    ----------------------------
    Const   -        value   (proc adr)        (immediate value)
    Var     base      off           -                 (direct adr)
    Par      -          off0        off1              (indirect adr)
    Reg     -           -            -
    RegI    -          off           -
    Cond   cond   Fchain  Tchain
 
    regno is now always in reg field
 *)

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
    RIU, VRS: SET;      (*in use and variable+parameter register sets*)
    RB, RL: INTEGER; (*register base and limit*)
    PRU*: SET; (*set of registers used in procedure*)
    frame: LONGINT;   (*frame offset changed in SaveRegs and RestoreRegs*)
    traps: ARRAY 8 OF B.Object; arith: ARRAY 4 OF B.Object;
    vector: ARRAY 32 OF INTEGER;
    
    relmap: ARRAY 4 OF INTEGER;    (*condition codes for relations*)
    data: ARRAY maxTD OF INTEGER;  (*type descriptors*)
    str: ARRAY maxStrx OF CHAR;
    mcode: A.ModuleCode;
    frmOfsSegs: FrameOffset;

    cm1, c0, c1, c2, pc, sp, r4, r15, rh: Item;
    curImport: INTEGER;

  PROCEDURE CheckRTImport*(impid: S.Ident);
  BEGIN
    IF impid = "Traps" THEN curImport := 1
    ELSIF impid = "Arith" THEN curImport := 2
    ELSE curImport := 0
    END
  END CheckRTImport;

  PROCEDURE RegisterRTproc*(p: B.Object);
  BEGIN IF curImport = 1 THEN
      IF p.name = "ArrayOutOfRange" THEN traps[1] := p
      ELSIF p.name = "TypeGuardFailure" THEN traps[2] := p
      ELSIF p.name = "CopyOverflow" THEN traps[3] := p
      ELSIF p.name = "AccessViaNILPointer" THEN traps[4] := p
      ELSIF p.name = "IllegalProcedureCall" THEN traps[5] := p
      ELSIF p.name = "DivisionByZero" THEN traps[6] := p
      ELSIF p.name = "AssertionViolated" THEN traps[7] := p
      END
    ELSIF curImport = 2 THEN
      IF p.name = "mul16" THEN arith[0] := p
      END
    END
  END RegisterRTproc;

  PROCEDURE OfsPTOS(offset: INTEGER; increment: BOOLEAN);
  BEGIN
    IF increment THEN INC(offset, frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos) END;
      IF offset # frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos THEN
      frmOfsSegs.Segs[frmOfsSegs.NofSegs].end := mcode.pc;
      INC(frmOfsSegs.NofSegs); frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos := offset
    END
  END OfsPTOS;

  PROCEDURE EnableCode*(e: BOOLEAN);
  BEGIN A.SetEnabled(e)
  END EnableCode;

  PROCEDURE FixOne*(at: LONGINT);
  BEGIN A.FixOne(mcode, at)
  END FixOne;

  PROCEDURE FixLink*(L: LONGINT);
  BEGIN
    A.FixLink(mcode, L)
  END FixLink;

  PROCEDURE SetRegisterAllocation*;
  BEGIN IF ~AllocUp THEN AllocUp  := TRUE; RIU := {}; RL := 16;  RB := A.CG2 + 1 END
  END SetRegisterAllocation;

  PROCEDURE ClearRIU*;
  BEGIN RIU := {}
  END ClearRIU;

  PROCEDURE ClearPRU*;
  BEGIN PRU := {}
  END ClearPRU;

  PROCEDURE nextR(VAR r: INTEGER);
  BEGIN IF AllocUp THEN INC(r) ELSE DEC(r) END
  END nextR;

  PROCEDURE allocR*(r: INTEGER);
  BEGIN
    IF RIU*{r} = {} THEN INCL(RIU, r); INCL(PRU, r) ELSE S.Mark("reg already allocated") END
  END allocR;

  PROCEDURE AllocR*(): INTEGER;
    VAR RH: INTEGER;
  BEGIN (*register are allocated beginning in order according to AllocUp value*)
(*S.DebugHex("AllocR AllocUp", ORD(AllocUp)); S.DebugHex("    RIU", ORD(RIU)); S.DebugHex("    RB", RB);*)
    RH := RB; WHILE (RIU*{RH} # {}) & (RH # RL) DO nextR(RH) END;
    IF RH = RL THEN S.Mark("register stack overflow"); rh.reg := RB ELSE allocR(RH); rh.reg := RH END

    RETURN RH
  END AllocR;

  PROCEDURE alloc(VAR x: Item);
  BEGIN
(*S.DebugHex("alloc", SYSTEM.ADR(x)); S.DebugHex("    x.obj", ORD(x.obj)); S.DebugHex("    x.mode", ORD(x.mode)); S.DebugHex("    x.a", ORD(x.a));
S.DebugHex("    x.tmp", ORD(x.tmp));*)
(*IF x.obj # NIL THEN S.DebugString("    name", x.obj.name) END;*)
    IF x.tmp OR ((x.obj = NIL) OR (x.obj.register = 0FFH)) OR ~(x.mode IN {Reg, RegI}) THEN
      x.reg := AllocR(); x.am := A.Register; x.tmp := TRUE
    END
  END alloc;

  PROCEDURE freeR*(r: INTEGER);
  BEGIN
(*S.DebugHex("freeR", r); S.DebugHex("    RIU", ORD(RIU));*)
    IF RIU*{r} # {} THEN EXCL(RIU, r)
    ELSE S.Mark("reg wild free"); ASSERT(FALSE) END
  END freeR;

  PROCEDURE free(VAR x: Item);
  BEGIN
(*S.DebugHex("free", SYSTEM.ADR(x)); S.DebugHex("    x.obj", ORD(x.obj)); S.DebugHex("    x.mode", ORD(x.mode)); S.DebugHex("    x.tmp", ORD(x.tmp));*)
(*IF x.obj # NIL THEN S.DebugString("    name", x.obj.name) END;*)
     IF x.tmp THEN
      freeR(x.reg)
    END
  END free;

  PROCEDURE resultRegister*(VAR res: Item);
  BEGIN
    IF AllocUp THEN res := r4 ELSE res := r15 END
  END resultRegister;
 
  PROCEDURE CheckRegs*;
  BEGIN IF RIU # VRS THEN S.Mark("Reg Stack"); RIU := VRS END;
    IF mcode.pc >= A.maxCode - 40 THEN S.Mark("program too long") END ;
    IF frame # 0 THEN S.Mark("frame error"); frame := 0 END
  END CheckRegs;

  PROCEDURE SetCC(VAR x: Item; n: LONGINT);
  BEGIN x.mode := Cond; x.a := 0; x.b := 0; x.c := n
  END SetCC;

  PROCEDURE TypeChecked*(): BOOLEAN;
  RETURN traps[2] # NIL
  END TypeChecked;

  PROCEDURE AssertionChecked*(): BOOLEAN;
  RETURN traps[7] # NIL
  END AssertionChecked;

  PROCEDURE GetOffset(VAR x: A.Item): INTEGER;
    VAR res: INTEGER;
  BEGIN IF x.ofs = A.C16 THEN (*Imported object*) res := x(Item).obj.usedat; x(Item).obj.usedat := mcode.pc ELSE res := x.ofs END
    RETURN res
  END GetOffset;

 PROCEDURE Trap(cond, num: LONGINT);
  (*Trap is implemented as calls to functions in the Trap special module.  
     If the procedure Trap.Handle<num> procedure exists and is exported,
     the trap checking code is generated.*)
  VAR l: INTEGER; t!: Item;
  BEGIN IF cond # A.AL THEN A.PutJ(mcode, A.negated(cond), 4) END; 
    t.reg := 0; t.am := A.Immediate; t.ofs := A.C16; t.obj := traps[num];
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
    VAR pc0, pc1: LONGINT; bw: SET; t!, ti!, sva!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
(*S.DebugHex("load x.mode", x.mode);*)
    ti.am := A.Indexed; ti.obj := NIL; sva.reg := 0; sva.ofs := A.C16; sva.obj := x.obj;
    IF x.mode # Reg THEN
      IF x.type.size = 1 THEN bw := A.Byte ELSE bw := A.Word END;
      IF x.mode = B.Const THEN alloc(x);
        IF x.type.form = B.Proc THEN
          IF x.c > 0 THEN S.Mark("not allowed")
          ELSIF x.c = 0 THEN A.PutDO(mcode, A.MOV, pc, x, A.Word); (*Put address of next statement in RH*)
            t.ofs := mcode.pc - x.a; A.PutDO(mcode, A.SUB, t, x, A.Word) (*substract offset to compute absolute address*)
          ELSE sva.am := A.Immediate (*imported*); A.PutDO(mcode, A.MOV, sva, x, A.Word)
          END
        ELSE t.ofs := x.a; A.PutDO(mcode, A.MOV, t, x, A.Word)
        END;
      ELSIF x.mode = B.Var THEN
        IF x.c > 0 THEN (*local*) alloc(x); ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, bw)
        ELSE alloc(x); sva.am := A.Absolute; A.PutDO(mcode, A.MOV, sva, rh, bw)
        END
      ELSIF x.mode = B.Par THEN alloc(x); ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
        ti.reg := rh.reg; ti.ofs := x.b; A.PutDO(mcode, A.MOV, ti, rh, bw)
      ELSIF x.mode = RegI THEN ti.reg := x.reg; ti.ofs := x.a; x.am := A.Register; x.ofs := 0; A.PutDO(mcode, A.MOV, ti, x, bw)
      ELSIF x.mode = Cond THEN
        pc0 := mcode.pc; A.PutJ(mcode, A.negated(x.c), 0);
        FixLink(x.b); A.PutDO(mcode, A.MOV, c1, rh, A.Word); pc1 := mcode.pc; A.PutJ(mcode, A.AL, 0);
        A.fix(mcode, pc0, mcode.pc - pc0 - 2); FixLink(x.a); A.PutDO(mcode, A.MOV, c0, rh, A.Word);
        A.fix(mcode, pc1, mcode.pc - pc1 - 2); alloc(x)
      END;
      x.mode := Reg; x.tmp := TRUE
    ELSIF (*mode = REG*) x.tmp & (x.obj # NIL) & (x.reg = x.obj.register) THEN (*temporary copy needed*)
      x.am := A.Register; t := x;  alloc(x); A.PutDO(mcode, A.MOV, t, x, A.Word)
    END;
(*S.DebugHex("    x.tmp", ORD(x.tmp));*)
    x.am := A.Register; x.ofs := 0
  END load;

  PROCEDURE push(VAR x: Item);
    VAR pc0, pc1: LONGINT; bw: SET; t!, ti!, sva!: Item;
  BEGIN
(*S.DebugHex("push", SYSTEM.ADR(x)); S.DebugHex("    RIU", ORD(RIU));*)
 t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    ti.am := A.Indexed; ti.obj := NIL; sva.reg := 0; sva.ofs := A.C16; sva.obj := x.obj;
    IF x.type.size = 1 THEN bw := A.Byte ELSE bw := A.Word END ;
    IF x.mode = B.Const THEN
      IF x.type.form = B.Proc THEN
        IF x.c > 0 THEN S.Mark("not allowed")
        ELSIF x.c = 0 THEN A.PutDO(mcode, A.MOV, pc, rh, A.Word); (*Put address of next statement in RH*)
          t.ofs := mcode.pc - x.a; A.PutDO(mcode, A.SUB, t, rh, A.Word); (*substract offset to compute absolute address*)
          A.PutSO(mcode, A.PUSH, rh, A.Word)
        ELSE sva.am := A.Immediate (*imported*); A.PutSO(mcode, A.PUSH, sva, A.Word)
        END
      ELSE t.ofs := x.a; A.PutSO(mcode, A.PUSH, t, A.Word)
      END
    ELSIF x.mode = B.Var THEN
      IF x.c > 0 THEN (*local*) ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutSO(mcode, A.PUSH, ti, bw)
      ELSE sva.am := A.Absolute; A.PutSO(mcode, A.PUSH, sva, bw)
      END
    ELSIF x.mode = B.Par THEN ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
      ti.reg := rh.reg; ti.ofs := x.b; A.PutSO(mcode, A.PUSH, ti, bw)
    ELSIF x.mode = RegI THEN ti.reg := x.reg; ti.ofs := x.a; x.am := A.Register; x.ofs := 0; A.PutSO(mcode, A.PUSH, ti, bw)
    ELSIF x.mode = Cond THEN
      pc0 := mcode.pc; A.PutJ(mcode, A.negated(x.c), 0);
      FixLink(x.b); A.PutSO(mcode, A.PUSH, c1, A.Word); A.fix(mcode, pc0, mcode.pc - pc0 - 2);
      FixLink(x.a); A.PutSO(mcode, A.MOV, c0, A.Word); A.fix(mcode, pc1, mcode.pc - pc1 - 2)
    END
  END push;

  PROCEDURE loadAdr(VAR x: Item);
    VAR t!, ti!, sva!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    ti.am := A.Indexed; ti.obj := NIL; sva.reg := 0; sva.obj := x.obj; sva.ofs := A.C16;
    IF x.mode = B.Var THEN
      IF x.c > 0 THEN (*local*) alloc(x); A.PutDO(mcode, A.MOV, sp, rh, A.Word);
        IF x.a + frame # 0 THEN t.ofs := x.a + frame; A.PutDO(mcode, A.ADD, t, rh, A.Word) END
      ELSE alloc(x); sva.am := A.Immediate; A.PutDO(mcode, A.MOV, sva, rh, A.Word)
      END
    ELSIF x.mode = B.Par THEN alloc(x);
      ti.reg := A.SP; ti.ofs := x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
      IF x.b # 0 THEN t.ofs := x.b; A.PutDO(mcode, A.ADD, t, rh, A.Word) END
    ELSIF x.mode = RegI THEN
      IF x.a # 0 THEN t.ofs := x.a; x.am := A.Register; x.ofs := 0; A.PutDO(mcode, A.ADD, t, x, A.Word) END
    ELSE S.Mark("address error")
    END;
    x.mode := Reg; x.am := A.Register; x.ofs := 0
  END loadAdr;

  PROCEDURE pushAdr(VAR x: Item);
    VAR t!, ti!, sva!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    ti.am := A.Indexed; ti.obj := NIL; sva.reg := 0; sva.obj := x.obj; sva.ofs := A.C16;
    IF x.mode = B.Var THEN
      IF x.c > 0 THEN (*local*)
        IF x.a + frame # 0 THEN A.PutDO(mcode, A.MOV, sp, rh, A.Word);
          t.ofs := x.a + frame; A.PutDO(mcode, A.ADD, t, rh, A.Word); A.PutSO(mcode, A.PUSH, rh, A.Word)
        ELSE A.PutSO(mcode, A.PUSH, sp, A.Word)
        END
      ELSE sva.am := A.Immediate; A.PutSO(mcode, A.PUSH, sva, A.Word)
      END
    ELSIF x.mode = B.Par THEN
      ti.reg := A.SP; ti.ofs := x.a + frame; 
      IF x.b # 0 THEN A.PutDO(mcode, A.MOV, ti, rh, A.Word);
        A.PutDO(mcode, A.ADD, t, rh, A.Word); A.PutSO(mcode, A.PUSH, rh, A.Word)
      ELSE A.PutSO(mcode, A.PUSH, t, A.Word)
      END
    ELSIF x.mode = RegI THEN
      x.am := A.Register; x.ofs := 0;
      IF x.a # 0 THEN t.ofs := x.a; x.a := 0; A.PutDO(mcode, A.ADD, t, x, A.Word) END;
      A.PutSO(mcode, A.PUSH, x, A.Word)
    ELSE S.Mark("address error")
    END;
  END pushAdr;

  PROCEDURE loadCond(VAR x: Item);
  BEGIN
    IF x.type.form = B.Bool THEN
      IF x.mode = B.Const THEN IF x.a = 0 THEN x.c := A.NV ELSE x.c := A.AL END
      ELSE load(x); A.PutDO(mcode, A.CMP, c0, x, A.Word); x.c := A.NE; free(x)
      END;
      x.mode := Cond; x.a := 0; x.b := 0
    ELSE S.Mark("not Boolean?")
    END
  END loadCond;

  PROCEDURE loadTypTagAdr(T: B.Type);
    VAR x!: Item;
  BEGIN x.mode := B.Var; x.type := NIL; x.a := T.len; x.c := -T.mno; x.obj := NIL; loadAdr(x)
  END loadTypTagAdr;

  PROCEDURE pushTypTagAdr(T: B.Type);
    VAR x!: Item;
  BEGIN x.mode := B.Var; x.type := NIL; x.a := T.len; x.c := -T.mno; pushAdr(x)
  END pushTypTagAdr;

  PROCEDURE loadStringAdr(VAR x: Item);
  BEGIN x.c := 0; x.a := varsize+x.a; x.reg := 0; x.am := A.Immediate; x.ofs := A.C16;
    A.PutDO(mcode, A.MOV, x, rh, A.Word); alloc(x);
    x.mode := Reg; x.am := A.Register; x.ofs := 0
  END loadStringAdr;

  PROCEDURE pushStringAdr(x: Item);
    VAR x1!: Item;
  BEGIN x1.c := 0; x1.a := varsize+x.a; x1.reg := 0; x1.am := A.Immediate; x1.ofs := A.C16; x1.obj := x.obj;
    A.PutSO(mcode, A.PUSH, x1, A.Word)
  END pushStringAdr;

  (* Items: Conversion from constants or from Objects on the Heap to Items on the Stack*)

  PROCEDURE MakeConstItem*(VAR x: Item; typ: B.Type; val: LONGINT);
  BEGIN x.mode := B.Const; x.type := typ; x.a := val; x.obj := NIL; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0;
  END MakeConstItem;

  PROCEDURE MakeStringItem*(VAR x: Item; len: LONGINT); (*copies string from OMSPS-buffer to OMSPG-string array*)
    VAR i: LONGINT;
  BEGIN x.mode := B.Const; x.type := B.strType; x.a := strx; x.b := len; i := 0; x.obj := NIL; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0;
    IF strx + len + 2 < maxStrx THEN
      WHILE len > 0 DO str[strx] := S.str[i]; INC(strx); INC(i); DEC(len) END ;
      WHILE strx MOD 2 # 0 DO str[strx] := 0X; INC(strx) END
    ELSE S.Mark("too many strings")
    END
  END MakeStringItem;

  PROCEDURE MakeItem*(VAR x: Item; y: B.Object; curlev: LONGINT);
  BEGIN x.mode := y.class; x.type := y.type; x.a := y.val; x.rdo := y.rdo; x.obj := y; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0;
    IF (y.class IN {B.Var, B.Par}) & (y.register # 0FFH) THEN
      x.reg := y.register;
      IF y.class = B.Var THEN x.mode := Reg ELSE x.mode := RegI; x.b := 0 (*TODO: check this*) END
    ELSIF (y.class = B.Const) & (y.type.form = B.String) THEN x.b := y.lev  (*len*) ;
    ELSE x.c := y.lev
    END ;
    IF (y.lev > 0) & (y.lev # curlev) & (y.class # B.Const) THEN S.Mark("not accessible ") END
  END MakeItem;

  (* Code generation for Selectors, Variables, Constants *)

  PROCEDURE Field*(VAR x: Item; y: B.Object);   (* x := x.y *)
  BEGIN;
    IF x.mode = B.Var THEN
      IF x.c >= 0 THEN x.a := x.a + y.val
      ELSE loadAdr(x); x.mode := RegI; x.a := y.val
      END
    ELSIF x.mode = RegI THEN x.a := x.a + y.val
    ELSIF x.mode = B.Par THEN x.b := x.b + y.val
    END
  END Field;

  PROCEDURE Index*(VAR x, y: Item);   (* x := x[y] *)
    VAR s, lim: LONGINT; t!, ti!, sva!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    ti.am := A.Indexed; ti.obj := NIL; sva.obj := x.obj; sva.reg := 0; sva.ofs := A.C16; s := x.type.base.size; 
    IF s=0 THEN S.Mark("Invalid array item size")
    ELSE
      lim := x.type.len;
      IF (y.mode = B.Const) & (lim >= 0) THEN
        IF (y.a < 0) OR (y.a >= lim) THEN S.Mark("bad index") END ;
        IF (x.mode # B.Var) OR (x.c >= 0) OR (y.a = 0) THEN
          IF x.mode IN {B.Var, RegI} THEN INC(x.a, y.a * s)
          ELSIF x.mode = B.Par THEN x.b := y.a * s + x.b
          END
        ELSE x.am := A.Immediate; x.ofs := A.C16; x.reg := 0; A.PutDO(mcode, A.MOV, x, rh, A.Word);
          alloc(x); x.mode := RegI; x.a := y.a * s; x.am := A.Register; x.ofs := 0
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
        t.ofs := s; A.eswDO(mcode, A.MUL, t, y, A.Word);
        IF x.mode = B.Var THEN
          IF x.c > 0 THEN A.PutDO(mcode, A.ADD, sp, y, A.Word); INC(x.a, frame)
          ELSE sva.am := A.Immediate; A.PutDO(mcode, A.MOV, sva, rh, A.Word); 
            A.PutDO(mcode, A.ADD, rh, y, A.Word); x.a := 0
          END;
          x.reg := y.reg; x.mode := RegI; x.am := A.Register; x.ofs := 0
        ELSIF x.mode = B.Par THEN ti.reg := A.SP; ti.ofs := x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
          A.PutDO(mcode, A.ADD, rh, y, A.Word); x.mode := RegI; x.reg := y.reg; x.a := x.b; x.am := A.Register; x.ofs := 0
        ELSIF x.mode = RegI THEN A.PutDO(mcode, A.ADD, y, x, A.Word); free(y)
        END
      END
    END
  END Index;

  PROCEDURE DeRef*(VAR x: Item);
  BEGIN
    IF x.mode IN {B.Var, B.Par, RegI} THEN load(x); NilCheck(x.reg)
    ELSIF x.mode # Reg THEN S.Mark("bad mode in DeRef") END;
    x.mode := RegI; x.a := 0; x.b := 0
  END DeRef;

  PROCEDURE Q(T: B.Type; VAR dcw: LONGINT);
  BEGIN (*one entry of type descriptor extension table*)
    IF T.base # NIL THEN
      Q(T.base, dcw); data[dcw] := T.typobj.usedat;
      T.typobj.usedat := dcw; INC(dcw)
    END
  END Q;

  PROCEDURE BuildTD*(T: B.Type; VAR dc: LONGINT);
    VAR dcw, k, s: LONGINT;  (*dcw = word address*)
  BEGIN dcw := dc DIV 2; s := T.size;
    T.len := dc; data[dcw] := s; INC(dcw); (*len used as address*)
    k := T.nofpar;   (*extension level!*)
    IF k > 3 THEN S.Mark("ext level too large")
    ELSE Q(T, dcw);
      WHILE k < 3 DO data[dcw] := -1; INC(dcw); INC(k) END
    END ;
    tdx := dcw; dc := dcw*2;
    IF tdx >= maxTD THEN S.Mark("too many record types"); tdx := 0 END
  END BuildTD;

  PROCEDURE TypeTest*(VAR x: Item; T: B.Type; varpar, isguard: BOOLEAN); (*TODO fix this proceedure*)
    VAR pc0: LONGINT; ti!, pt!, tt!: Item;
  BEGIN ti.am := A.Indexed; ti.obj := NIL; pt.am := A.Register; pt.ofs := 0; pt.obj := NIL; tt.am := A.Register; tt.ofs := 0; tt.obj := NIL;
    IF (traps[2] = NIL) OR (T = NIL) THEN IF x.mode > Reg THEN freeR(rh.reg) END; SetCC(x, A.AL)
    ELSE (*fetch tag into RH*)
      IF varpar THEN ti.reg := A.SP; ti.ofs := x.a+2+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
      ELSE load(x); A.PutDO(mcode, A.CMP, c0, x, A.Word);
        pc0 := mcode.pc; A.PutJ(mcode, A.EQ, 0); (*NIL belongs to every pointer type*)
        ti.reg := x.reg; ti.ofs := -8; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
      END;
      ti.reg := rh.reg; ti.ofs := T.nofpar*2; pt.reg := rh.reg; A.PutDO(mcode, A.MOV, ti, pt, A.Word); rh.reg := AllocR(); 
      tt := rh; loadTypTagAdr(T) (*tag of T*); A.PutDO(mcode, A.CMP, pt, tt, A.Word); freeR(rh.reg); free(x);
      IF isguard THEN
        IF traps[2] # NIL THEN Trap(A.NE, 2) END
      ELSE SetCC(x, A.EQ);
        IF ~varpar THEN free(x) END
      END;
      IF ~varpar THEN A.fix(mcode, pc0, mcode.pc - pc0 - 2) END
    END
  END TypeTest;

  PROCEDURE SetVector*(n: BYTE; VAR h: B.Object);
  BEGIN IF vector[n] # 0FFFFH THEN S.Mark("vect mult def")
    ELSE vector[n] := h.usedat; h.usedat := n END
  END SetVector;

  PROCEDURE writable(i: Item): BOOLEAN;
    RETURN (i.mode # B.Const) OR (i.type.form = B.Pointer)
  END writable;

  PROCEDURE setRAO(op: INTEGER; VAR i: Item; dst: BOOLEAN; VAR nba: INTEGER; VAR bw: SET);
    VAR ti!: Item;
  BEGIN
    IF i.type.size = 1 THEN bw := A.Byte END;
    IF dst & i.rdo & (~writable(i) OR (op # A.PUSH) & (op # A.CALL) & (op # A.CMP) & (op # A.BIT)) THEN i.tmp := TRUE; load(i)
    ELSIF i.mode = B.Var THEN
      IF i.c > 0 THEN i.reg := A.SP; i.am := A.Indexed; i.ofs := i.a + frame ELSE i.reg := 0; i.am := A.Absolute; i.ofs := A.C16 (*use static var address*) END
    ELSIF i.mode = Reg THEN i.am := A.Register; i.ofs := 0
    ELSIF i.mode = RegI THEN i.am := A.Indexed; i.ofs := i.a
    ELSIF i.mode = B.Const THEN  i.ofs := i.a; i.reg := 0;
      IF i.type.form = B.Pointer THEN i.am := A.Absolute;
        IF i.type.base.size = 1 THEN bw := A.Byte END;
      ELSE i.am := A.Immediate; IF dst THEN S.Mark("not writable") END
      END
    ELSIF i.mode = B.Par THEN ASSERT(nba = -1); rh.reg := AllocR(); nba := rh.reg;
      ti.am := A.Indexed; ti.reg := A.SP; ti.obj := NIL; ti.ofs := i.a + frame;
      A.PutDO(mcode, A.MOV, ti, rh, A.Word); i.mode := RegI; i.reg := rh.reg; i.a := i.b; i.b := 0; setRAO(op, i, dst, nba, bw)
    ELSE load(i)
    END
  END setRAO;

  PROCEDURE PutDO(op: BYTE; VAR src, dst: Item);
    VAR bw: SET; nba: INTEGER;
  BEGIN nba := -1; bw := A.Word; setRAO(op, dst, TRUE, nba, bw); setRAO(op, src, FALSE, nba, bw);
    A.PutDO(mcode, op, src, dst, bw);
    IF nba >= 0 THEN freeR(nba) END
  END PutDO;

  PROCEDURE PutSO(op: INTEGER; VAR sd: Item);
    VAR bw: SET; nba: INTEGER;
  BEGIN nba := -1; bw := A.Word; setRAO(op, sd, TRUE, nba, bw);
    A.PutSO(mcode, op, sd, bw);
    IF nba >= 0 THEN freeR(nba) END
  END PutSO;

  (* Code generation for Boolean operators *)

  PROCEDURE Not*(VAR x: Item);   (* x := ~x *)
    VAR t: LONGINT;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    x.c := A.negated(x.c); t := x.a; x.a := x.b; x.b := t
  END Not;

  PROCEDURE And1*(VAR x: Item);   (* x := x & *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.PutJ(mcode, A.negated(x.c), x.a);
    x.a := mcode.pc-2; A.FixLink(mcode, x.b); x.b := 0
  END And1;

  PROCEDURE And2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := A.merged(mcode, y.a, x.a); x.b := y.b; x.c := y.c
  END And2;

  PROCEDURE Or1*(VAR x: Item);   (* x := x OR *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.PutJ(mcode, x.c, x.b);
    x.b := mcode.pc-2; A.FixLink(mcode, x.a); x.a := 0
  END Or1;

  PROCEDURE Or2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := y.a; x.b := A.merged(mcode, y.b, x.b); x.c := y.c
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
      ELSE load(x); PutDO(A.XOR, cm1, x)
      END
    END
  END Neg;

  PROCEDURE PrepCall*(VAR x: Item; VAR r, or: SET);
    VAR n: INTEGER;
  BEGIN (*x.type.form = OM4B.Proc*) ASSERT(~AllocUp);
    IF x.mode > B.Par THEN load(x) END;
    r := RIU; or := x.obj.type.ur*RIU; (*overwritten registers currently in use by the caller*)
    IF or # {} THEN n := A.PushRegs(mcode, or); INC(frame, WordSize*n); OfsPTOS(n, TRUE) END;
    IF x.obj.type.leaf THEN SetRegisterAllocation;
      IF x.type.base.form # B.NoTyp THEN rh.reg := AllocR() END (*allocate result register*)
    END
  END PrepCall;

  PROCEDURE Call*(VAR x: Item; r, or: SET; s: LONGINT);
    VAR rr!, t!: Item; n: INTEGER;
  BEGIN (*x.type.form = B.Proc*)
    IF x.mode = B.Const THEN x.reg := 0; x.am := A.Immediate; x.ofs := A.C16; (*address must be computed at link time*)
      A.PutSO(mcode, A.CALL, x, A.Word)
    ELSE
      IF x.mode <= B.Par THEN IF traps[5] # NIL THEN PutDO(A.CMP, c0, x); Trap(A.EQ, 5) END;
        PutSO(A.CALL, x); free(x)
      ELSE rh.reg := AllocR(); PutSO(A.POP, rh); OfsPTOS(-1, TRUE); EXCL(r, rh.reg); DEC(frame, WordSize);
        IF traps[5] # NIL THEN PutDO(A.CMP, c0, rh); Trap(A.EQ, 5) END;
        A.PutSO(mcode, A.CALL, rh, A.Word); freeR(rh.reg)
      END;
    END;
    IF s # 0 THEN t.reg := 0; t.am := A.Immediate; t.obj := NIL; t.ofs := s; A.PutDO(mcode, A.ADD, t, sp, A.Word) END;
    IF x.type.base.form = B.NoTyp THEN (*procedure*) RIU := {}; AllocUp := FALSE; RB := 15
    ELSE (*function*) 
      x.tmp := TRUE; x.mode := Reg; resultRegister(rr); x.reg := rr.reg; x.am := A.Register;
      RIU := r; AllocUp := FALSE; RB := 15; INCL(RIU, rr.reg);
      IF or # {} THEN n := A.PopRegs(mcode, or); DEC(frame, WordSize*n); OfsPTOS(-n, TRUE) END
    END
  END Call;

  PROCEDURE AddOp*(op: LONGINT; VAR x, y: Item);   (* x := x +- y *)
    VAR t!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF op = S.plus THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a + y.a
      ELSIF y.mode = B.Const THEN
        IF y.a # 0 THEN t.ofs := y.a; PutDO(A.ADD, t, x) END
      ELSE PutDO(A.ADD, y, x); free(y)
      END
    ELSE (*op = S.minus*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a - y.a
      ELSIF y.mode = B.Const THEN
        IF y.a # 0 THEN t.ofs := y.a; PutDO(A.SUB, t, x) END
      ELSE PutDO(A.SUB, y, x); free(y)
      END
    END
  END AddOp;

  PROCEDURE MulOp*(VAR x, y: Item);   (* x := x * y *)
    VAR t!, p!: Item; r, or: SET; s: INTEGER;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a * y.a
    ELSIF (y.mode = B.Const)  & (y.a >= 2) THEN x.tmp := TRUE; load(x); t.ofs := y.a; A.eswDO(mcode, A.MUL, t, x, A.Word)
    ELSIF (x.mode = B.Const) & (x.a >= 2) THEN
(*;S.DebugHex("MulOp y.mode", y.mode);*)
 y.tmp := TRUE; load(y); t.ofs := x.a; A.eswDO(mcode, A.MUL, t, y, A.Word);
      x.mode := Reg; x.reg := y.reg; x.am := A.Register; x.ofs := 0; x.tmp := TRUE
    ELSE
      IF arith[0] = NIL THEN S.Mark("import Arith.mul function") 
      ELSE  MakeItem(p, arith[0], 0); PrepCall(p, r, or); load(x); load(y); Call(p, r, or, s); ASSERT(s = 0); free(y)
      END
    END
  END MulOp;

  PROCEDURE DivOp*(op: LONGINT; VAR x, y: Item);   (* x := x op y *)
    VAR t!, p!: Item; r, or: SET; s: INTEGER;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF op = S.div THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a DIV y.a ELSE S.Mark("bad divisor") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) THEN load(x); t.ofs := y.a; A.eswDO(mcode, A.DIv, t, x, A.Word);
        x.mode := Reg; x.reg := y.reg; x.am := A.Register; x.ofs := 0
      ELSE IF arith[1] = NIL THEN S.Mark("import Arith.div procedure")
        ELSE IF traps[6] # NIL THEN PutDO(A.CMP, y, c0); Trap(A.GE, 6); free(y) END;
          MakeItem(p, arith[1], 0); PrepCall(p, r, or);
          load(x); load(y); Call(p, r, or, s); ASSERT(s = 0); free(y)
        END
      END
    ELSE (*op = OM4S.mod*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a MOD y.a ELSE S.Mark("bad modulus") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) THEN load(x); t.ofs := y.a; A.eswDO(mcode, A.MOd, t, x, A.Word);
        x.mode := Reg; x.reg := y.reg; x.am := A.Register; x.ofs := 0
      ELSE IF arith[1] = NIL THEN S.Mark("import Arith.div procedure")
        ELSE IF traps[6] # NIL THEN PutDO(A.CMP, y, c0); Trap(A.GE, 6); free(y) END;
          MakeItem(p, arith[1], 0); PrepCall(p, r, or); load(x); load(y); Call(p, r, or, s); ASSERT(s = 0); PutDO(A.MOV, y, x); free(y)
        END
      END
    END
  END DivOp;

  (* Code generation for shift operations *)
  PROCEDURE shift(op: INTEGER; VAR x, y: Item); (* x := LSL(x, y)*)
    VAR i, pb, pf: INTEGER;
  BEGIN
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := LSL(x.a, y.a) 
    ELSIF (y.mode = B.Const) & (y.a <= 4) THEN PutSO(A.NOP0, x); FOR i := 1 TO y.a DO PutDO(A.ADD, x, x) END
    ELSE PutSO(A.NOP0, x); PutDO(A.ADD, c1, y);
      pb := mcode.pc; PutDO(A.SUB, c1, y); pf := mcode.pc; A.PutJ(mcode, A.EQ, 0);
      PutSO(op, x); A.PutJ(mcode, A.AL, pb - mcode.pc - 2); A.fix(mcode, pf, mcode.pc - pf - 2);
      free(y)
    END
  END shift;

  PROCEDURE Rla*(VAR x, y: Item); (* x := LSL(x, y)*)
  BEGIN shift(A.RLA, x, y)
  END Rla;

  PROCEDURE Rra*(VAR x, y: Item); (* x := LSL(x, y)*)
  BEGIN shift(A.RRA, x, y)
  END Rra;

  (* Code generation for set operators *)

  PROCEDURE Singleton*(VAR x: Item);  (* x := {x} *)
    VAR y!: Item;
  BEGIN y := x; x.mode := B.Const; x.a := 1; Rla(x, y)
  END Singleton;

  PROCEDURE Set*(VAR x, y: Item); (* x := {x .. y} *)
    VAR p!: Item; r, or: SET; s: INTEGER;
  BEGIN
    IF (x.mode = B.Const) & ( y.mode = B.Const) THEN
      IF x.a <= y.a THEN x.a := ORD({x.a .. y.a}) ELSE x.a := 0 END
    ELSE IF arith[2] = NIL THEN S.Mark("import Arith.set procedure")
      ELSE MakeItem(p, arith[2], 0); PrepCall(p, r, or); load(x); load(y); Call(p, r, or, s); ASSERT(s = 0)
      END
    END
  END Set;

  PROCEDURE In*(VAR x, y: Item);  (* x := x IN y *)
    VAR c!: Item; pc0, pc1: INTEGER;
  BEGIN 
    IF x.mode = B.Const THEN  c.reg := 0; c.am := A.Immediate; c.ofs := LSL(1, x.a); c.obj := NIL; PutDO(A.BIT, c, y);
      free(x)
    ELSE load(x); load(y); PutDO(A.ADD, c1, x); 
      pc0 := mcode.pc; PutDO(A.SUB, c1, x); pc1 := mcode.pc; A.PutJ(mcode, A.EQ, 0);
      PutSO(A.RRC, y); A.PutJ(mcode, A.AL, pc0 - mcode.pc -2); A.fix(mcode, pc1, mcode.pc - pc1 - 2);
      PutDO(A.BIT, c1, y); free(y); free(x)
    END;
    SetCC(x, A.NE)
  END In;

  PROCEDURE SetOp*(op: LONGINT; VAR x, y: Item);   (* x := x op y *)
    VAR xset, yset: SET; (*x.type.form = Set*)
  BEGIN
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN
      xset := SYSTEM.VAL(SET, x.a); yset := SYSTEM.VAL(SET, y.a);
      IF op = S.plus THEN xset := xset + yset
      ELSIF op = S.minus THEN xset := xset - yset
      ELSIF op = S.times THEN xset := xset * yset
      ELSIF op = S.rdiv THEN xset := xset / yset
      END ;
      x.a := SYSTEM.VAL(LONGINT, xset)
    ELSE load(x);
      IF op = S.plus THEN PutDO(A.BIS, y, x)
      ELSIF op = S.minus THEN PutDO(A.BIC, y, x)
      ELSIF op = S.times THEN PutDO(A.AND, y, x)
      ELSIF op = S.rdiv THEN PutDO(A.XOR, y, x)
      END;
      free(y)
    END
  END SetOp;

  (* Code generation for relations *)

  PROCEDURE IntCompare*(VAR x, y, z: Item);   (* x < y *)
  BEGIN
    IF (x.mode = Cond) OR (y.mode = Cond) THEN S.Mark("not implemented") END;
    PutDO(A.CMP, y, x); free(y); free(x);
    SetCC(x, z.a)
  END IntCompare;

  PROCEDURE IntRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
  BEGIN
    IF (x.mode = Cond) OR (y.mode = Cond) THEN S.Mark("not implemented") END;
    IF op < S.gtr THEN PutDO(A.CMP, y, x); SetCC(x, relmap[op - S.eql])
    ELSE PutDO(A.CMP, x, y); SetCC(x, relmap[op - S.gtr + 2])
    END;
    free(y); free(x)
  END IntRelation;

  PROCEDURE StringRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
    (*x, y are char arrays or strings*)
    VAR pc0, tbf0: LONGINT; x1!: Item;
  BEGIN
    IF x.type.form = B.String THEN loadStringAdr(x) ELSE loadAdr(x) END ; x.am := A.Indexed; x.ofs := 0; x1 := x; x1.am := A.IndirectIncr;
    IF y.type.form = B.String THEN loadStringAdr(y) ELSE loadAdr(y) END ; y.am := A.IndirectIncr;
    (*Compare:*) pc0 := mcode.pc; A.PutDO(mcode, A.CMP, y, x, A.Byte); tbf0 := mcode.pc; A.PutJ(mcode, A.NE, 0) (*JNE Fin*);
    A.PutDO(mcode, A.BIT, x1, x, A.Byte) (*increment x and test if x^ is 0*); A.PutJ(mcode, A.NE, pc0 - mcode.pc - 2) (*JNE Compare*);
    (* Fin: *) A.fix(mcode, tbf0, mcode.pc - tbf0 - 2); free(y); free(x);
    SetCC(x, relmap[op - S.eql])
  END StringRelation;

  (* Code generation of Assignments *)

  PROCEDURE StrToChar*(VAR x: Item);
  BEGIN x.type := B.charType; DEC(strx, 2); x.a := ORD(str[x.a])
  END StrToChar;

  PROCEDURE Store*(VAR x, y: Item); (* x := y *)
  BEGIN PutDO(A.MOV, y, x); free(y); free(x)
  END Store;

  PROCEDURE StoreStruct*(VAR x, y: Item); (* x := y, frame = 0 *)
    VAR s, pc0, pc1: LONGINT; t!, ti!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL; ti.am := A.Indexed; ti.obj := NIL;
    pc0 := -1;
    IF y.type.size # 0 THEN rh.reg := AllocR(); loadAdr(x); loadAdr(y);
      IF (x.type.form = B.Array) &  (x.type.len > 0) THEN
        IF y.type.len >= 0 THEN 
          IF x.type.size = y.type.size THEN t.ofs := (y.type.size+1) DIV 2; PutDO(A.MOV, t, rh)
          ELSE S.Mark("different length/size, not implemented")
          END
        ELSE (*y  open array*) ti.reg := A.SP; ti.ofs := y.a+2; PutDO(A.MOV, ti, rh); s := y.type.base.size;  (*element size*)
          A.PutDO(mcode, A.CMP, c0, rh, A.Word); pc0 := mcode.pc; A.PutJ(mcode, A.EQ, 0); (*BEQ L0*)
          IF s = 1 THEN A.PutDO(mcode, A.ADD, c1, rh, A.Word); A.PutSO(mcode, A.RRA, rh, A.Word)
          ELSIF s # 2 THEN ASSERT(~ODD(s)); t.ofs := s DIV 2; A.eswDO(mcode, A.MUL, t, rh, A.Word)
          END;
          IF traps[3] # NIL THEN t.ofs := (x.type.size+1) DIV 2+1; A.PutDO(mcode, A.CMP, t, rh, A.Word); Trap(A.GE, 3) END
        END
      ELSIF x.type.form = B.Record THEN t.ofs := x.type.size DIV 2; A.PutDO(mcode, A.MOV, t, rh, A.Word)
      ELSE S.Mark("inadmissible assignment")
      END;
      (*L1*) pc1 := mcode.pc; x.am := A.Indexed; x.ofs := 0; y.am := A.IndirectIncr;
      A.PutDO(mcode, A.MOV, y, x, A.Word); x.am := A.Register; A.PutDO(mcode, A.ADD, c2, x, A.Word);
      A.PutDO(mcode, A.SUB, c1, rh, A.Word); A.PutJ(mcode, A.NE, pc1 - mcode.pc -2); (*BNE L1*)
      (*L0:*) IF pc0 # -1 THEN A.fix(mcode, pc0, mcode.pc - pc0 - 2) END;
      free(y); free(x); freeR(rh.reg)
    END
  END StoreStruct;

  PROCEDURE CopyString*(VAR x, y: Item);  (* x := y *) 
     VAR len, pc0: LONGINT; t!,ti!, x1!: Item;
   BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL; ti.am := A.Indexed; ti.obj := NIL;
    loadAdr(x); len := x.type.len;
    IF len >= 0 THEN
      IF len < y.b THEN S.Mark("string too long") END
    ELSIF traps[3] # NIL THEN t.reg := A.SP; t.ofs := x.a+2; A.PutDO(mcode, A.MOV, t, rh, A.Word); (*open array len, frame = 0*)
      t.ofs := y.b; A.PutDO(mcode, A.CMP, t, rh, A.Word); Trap(A.L, 3)
    END ;
    loadStringAdr(y);
    (*L0:*) pc0 := mcode.pc; x.am := A.Indexed; x.ofs := 0; y.am := A.IndirectIncr; x1 := x;
    A.PutDO(mcode, A.MOV, y, x, A.Word); x.am := A.Register; A.PutDO(mcode, A.ADD, c1, x, A.Word); (*x points to high byte of current word*)
    x.am := A.IndirectIncr; A.PutDO(mcode, A.BIT, x, x1, A.Byte) (*test 0 and increment x register*); A.PutJ(mcode, A.NE, pc0 - mcode.pc -2); (*BNE L0*)
    free(y); free(x)
   END CopyString;
  
  (* Code generation for parameters *)
  
  PROCEDURE OpenArrayParam*(VAR x: Item; par: B.Object);
    VAR t!, ti!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;  t.ofs := x.type.len;
    ti.am := A.Indexed; ti.obj := NIL;
    IF par.register # 0FFH THEN loadAdr(x); rh.reg := AllocR();
      IF t.ofs >= 0 THEN A.PutDO(mcode, A.MOV, t, rh, A.Word)
      ELSE ti.reg := A.SP; ti.ofs := x.a+2+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
      END
    ELSE (*in stack*) pushAdr(x);
      IF t.ofs >= 0 THEN A.PutSO(mcode, A.PUSH, t, A.Word)
      ELSE ti.reg := A.SP; ti.ofs := x.a+2+frame; A.PutSO(mcode, A.PUSH, ti, A.Word)
      END
    END
  END OpenArrayParam;

  PROCEDURE VarParam*(VAR x: Item; par: B.Object);
    VAR xmd: INTEGER; t!, ti!, rh!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;  t.ofs := x.type.len;
    ti.am := A.Indexed; ti.obj := NIL;
    IF par.register #0FFH THEN
      xmd := x.mode; loadAdr(x);
      IF (par.type.form = B.Array) & (par.type.len < 0) THEN rh.reg := AllocR(); (*open array*)
        IF t.ofs >= 0 THEN A.PutDO(mcode, A.MOV, t, rh, A.Word)
        ELSE ti.reg := A.SP; ti.ofs := x.a+2+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
        END
      ELSIF (par.type.form = B.Record) & (traps[2] # NIL) THEN rh.reg := AllocR();
        IF xmd = B.Par THEN ti.reg := A.SP; ti.ofs := x.a+2+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
        ELSE loadTypTagAdr(x.type)
        END
      END
    ELSE (*in stack*)
      xmd := x.mode; pushAdr(x);
      IF (par.type.form = B.Array) & (par.type.len < 0) THEN (*open array*) rh.reg := AllocR();
        IF t.ofs >= 0 THEN A.PutSO(mcode, A.PUSH, t, A.Word)
        ELSE ti.reg := A.SP; ti.ofs := x.a+2+frame; A.PutSO(mcode, A.PUSH, ti, A.Word)
        END
      ELSIF (par.type.form = B.Record) & (traps[2] # NIL) THEN
        IF xmd = B.Par THEN rh.reg := AllocR(); ti.reg := A.SP; ti.ofs := x.a+2+frame; A.PutSO(mcode, A.PUSH, ti, A.Word)
        ELSE pushTypTagAdr(x.type)
        END
      END
    END
  END VarParam;

  PROCEDURE ValueParam*(VAR x: Item; par: B.Object);
  BEGIN IF par.register #0FFH THEN load(x) ELSE push(x) END
  END ValueParam;

  PROCEDURE StringParam*(VAR x: Item; par: B.Object);
    VAR t!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL; t.ofs := x.b;
    IF par.register # 0FFH THEN loadStringAdr(x); rh.reg := AllocR(); A.PutDO(mcode, A.MOV, t, rh, A.Word) (*len*)
    ELSE pushStringAdr(x); A.PutSO(mcode, A.PUSH, t, A.Word); (*len*)
    END
  END StringParam;

  (*For Statements*)

  PROCEDURE For0*(VAR x, y: Item);
  BEGIN Store(x, y)
  END For0;

  PROCEDURE For1*(VAR x, y, z, w: Item; VAR L: LONGINT);
  BEGIN
    IF w.a > 0 THEN PutDO(A.CMP, x, z)
    ELSIF w.a < 0 THEN PutDO(A.CMP, z, x)
    ELSE S.Mark("zero increment")
    END;
    L := mcode.pc; A.PutJ(mcode, A.L, 0); free(z)
  END For1;

  PROCEDURE For2*(VAR x, y, w: Item);
  BEGIN x.rdo := FALSE; PutDO(A.ADD, w, x);
  END For2;

  (* Branches, procedure calls, procedure prolog and epilog *)

  PROCEDURE Here*(): LONGINT;
  RETURN mcode.pc
  END Here;

  PROCEDURE FJump*(VAR L: LONGINT);
  BEGIN A.PutJ(mcode, A.AL, L); L := mcode.pc - 2
  END FJump;

  PROCEDURE CFJump*(VAR x: Item);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.PutJ(mcode, A.negated(x.c), x.a);
    A.FixLink(mcode, x.b); x.a := mcode.pc - 2
  END CFJump;

  PROCEDURE BJump*(L: LONGINT);
  BEGIN A.PutJ(mcode, A.AL, L - mcode.pc - 2)
  END BJump;

  PROCEDURE CBJump*(VAR x: Item; L: LONGINT);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.PutJ(mcode, A.negated(x.c), L - mcode.pc - 2); A.FixLink(mcode, x.b); A.FixLinkWith(mcode, x.a, L)
  END CBJump;

  PROCEDURE Fixup*(VAR x: Item);
  BEGIN A.FixLink(mcode, x.a)
  END Fixup;

  PROCEDURE Enter*(size: LONGINT; int: BOOLEAN; nofusedregs: INTEGER);
    VAR t!: Item; regl, regh: BYTE; n: INTEGER;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    OfsPTOS(0, FALSE); frame := 0;
    IF size >= A.C16 THEN S.Mark("local variables size exeeded") END;

    IF size # 0 THEN
      t.ofs := size; A.PutDO(mcode, A.SUB, t, sp, A.Word); OfsPTOS(size DIV 2, TRUE)
    END;

    IF nofusedregs >= 0 THEN (*sets the number of usable registers. This is useful to ensure that interrupt handlers do not corrupt registers*)
      IF AllocUp THEN regl := A.CG2 + 1; RL := nofusedregs + regl; regh := RL - 1 ELSE regh :=  15; RL := 15 - nofusedregs; regl := RL + 1 END;
      IF regh > regl THEN
        n := A.PushRegs(mcode, {regl .. regh}); OfsPTOS(nofusedregs, TRUE) (*save registers before use*)
      END
    ELSE IF AllocUp THEN RL := 16 ELSE RL := A.CG2 END
    END; VRS := RIU;
  END Enter;

  PROCEDURE Return*(form: INTEGER; VAR x: Item; size: LONGINT; int: BOOLEAN; nofusedregs: INTEGER);
    VAR t!: Item; regl, regh: BYTE; n: INTEGER;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF form # B.NoTyp THEN load(x) END;
    IF nofusedregs >= 0 THEN
      IF AllocUp THEN regl := A.CG2 + 1; RL := nofusedregs + regl; regh := RL - 1 ELSE regh :=  15; RL := 15 - nofusedregs; regl := RL + 1 END;
      IF regh > regl THEN n := A.PopRegs(mcode, {regl .. regh}); OfsPTOS(-nofusedregs, TRUE) END;
      IF AllocUp THEN RL := 16 ELSE RL := A.CG2 END
    END;
    IF size # 0 THEN t.ofs := size; A.PutDO(mcode, A.ADD, t, sp, A.Word); OfsPTOS(-size DIV 2, TRUE) END;
    IF frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos # 0 THEN S.DebugHex("stack seg", frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos) END;
    IF int THEN A.PutSO(mcode, A.RETI, pc, A.Word) ELSE A.PutNO(mcode, A.RET) END;
    AllocUp := FALSE; RIU := {}; RB := 15; VRS := RIU
  END Return;

  (* In-line code procedures*)

  PROCEDURE Increment*(upordown: LONGINT; VAR x, y: Item);
    VAR op: BYTE; zr: LONGINT;
  BEGIN (*frame = 0*)
    IF upordown = 0 THEN op := A.ADD ELSE op := A.SUB END;
    IF y.type.form = B.NoTyp THEN y.mode := B.Const; y.a := 1; y.tmp := FALSE END;
    PutDO(op, y, x);
    free(y); free(x)
  END Increment;

  PROCEDURE Include*(inorex: INTEGER; VAR x, y: Item);
    VAR op: BYTE; z!, t!: Item;
  BEGIN     IF inorex = 0 THEN op := A.BIS ELSE op := A.BIC END;
    IF y.mode = B.Const THEN t.mode := B.Const; t.tmp := FALSE; t.obj := NIL; t.ofs := 0; t.a := LSL(1, y.a); PutDO(op, t, x)
    ELSE z.mode := B.Const; z.a := 1; z.tmp := FALSE; z.ofs := 0; Rla(z, y); PutDO(op, z, x);
      free(z)
    END
  END Include;

  PROCEDURE Assert*(VAR x: Item);
    VAR cond, pc0: LONGINT;
  BEGIN
    IF traps[7] # NIL
    THEN
      pc0 := 0;
      IF x.mode # Cond THEN loadCond(x) END;
      IF x.a = 0 THEN cond := A.negated(x.c);
      ELSE pc0 := mcode.pc; A.PutJ(mcode, x.c, 0); A.FixLink(mcode, x.a); cond := A.AL
      END;
      Trap(cond, 7); A.FixLink(mcode, x.b);
      IF pc0 # 0 THEN A.fix(mcode, pc0, mcode.pc - pc0 - 2) END
    END
  END Assert; 
  
  PROCEDURE Get*(VAR x, y: Item);
  BEGIN PutDO(A.MOV, x, y); free(y); free(x)
  END Get;

  PROCEDURE Put*(VAR x, y: Item);
    VAR bw: SET;
  BEGIN PutDO(A.MOV, y, x); free(y); free(x)
  END Put;

  PROCEDURE Copy*(VAR x, y, z: Item);
    VAR pc0, pc1: LONGINT;
  BEGIN load(x); load(y);
    pc0 := 0;
    IF z.mode = B.Const THEN
      IF z.a > 0 THEN load(z) ELSE S.Mark("bad count") END
    ELSE load(z);
      IF traps[3] # NIL THEN PutDO(A.CMP, c0, z); Trap(A.L, 3) END;
      pc0 := mcode.pc; A.PutJ(mcode, A.EQ, 0); (*BEQ L0*)
    END;
    pc1 := mcode.pc;
    x.am := A.IndirectIncr; y.am := A.Indexed; y.ofs := 0; PutDO(A.MOV, x, y);
    y.am := A.Register; PutDO(A.ADD, c1, y);
    PutDO(A.SUB, c1, z); A.PutJ(mcode, A.NE, pc1 - mcode.pc - 2); (*BNE L1*)
    IF pc0 # 0 THEN A.fix(mcode, pc0, mcode.pc - pc0 - 2) END; free(z); free(y); free(x)
  END Copy;

  PROCEDURE LDREG*(VAR y: Item);
  BEGIN load(y); RIU := {}
  END LDREG;

  (*In-line code functions*)

  PROCEDURE Abs*(VAR x: Item);
  BEGIN
    IF x.mode = B.Const THEN x.a := ABS(x.a) ELSE A.eswSO(mcode, A.NEG, x, A.Word) END
  END Abs;

  PROCEDURE Odd*(VAR x: Item);
  BEGIN PutDO(A.BIT, c1, x); SetCC(x, A.NE); free(x)
  END Odd;

  PROCEDURE Ord*(VAR x: Item);
  BEGIN (*todo : check if load(x) is really needed*)
    IF x.mode IN {B.Var, B.Par, RegI, Cond} THEN load(x) END
  END Ord;

  PROCEDURE Len*(VAR x: Item);
    VAR ti!: Item;
  BEGIN ti.am := A.Indexed; ti.obj := NIL;
    IF x.type.len >= 0 THEN
      IF x.mode = RegI THEN free(x) END;
      x.mode := B.Const; x.a := x.type.len
    ELSE (*open array*) alloc(x); ti.reg := A.SP; ti.ofs := x.a + 2 + frame; A.PutDO(mcode, A.MOV, ti, x, A.Word);
    END 
  END Len;

  PROCEDURE Shift*(fct: LONGINT; VAR x, y: Item);
    VAR op: LONGINT;
  BEGIN IF (x.mode = B.Const) & (y.mode = B.Const) THEN
      IF fct = 0 THEN x.a := LSL(x.a, y.a) ELSIF fct = 1 THEN x.a := ASR(x.a, y.a) END 
    ELSE 
      IF fct = 0 THEN Rla(x, y) ELSIF fct = 1 THEN Rra(x, y) END;
      free(y)
    END
  END Shift;

  PROCEDURE Rotate*(fct: LONGINT; VAR x: Item);
    VAR op: LONGINT;
  BEGIN IF fct = 0 THEN PutSO(A.RLC, x) ELSIF fct = 1 THEN PutSO(A.RRC, x) END
  END Rotate;

  PROCEDURE Logical*(fct: INTEGER; VAR x, y: Item);
    VAR op: BYTE;
  BEGIN
    IF fct = 0 THEN op := A.BIC ELSIF fct = 1 THEN op := A.BIS ELSIF fct = 2 THEN op := A.XOR ELSE op := A.AND END;
    PutDO(op, y, x); free(y); free(x)
  END Logical;

  PROCEDURE ADC*(VAR x, y: Item);
  BEGIN PutDO(A.ADDC, y, x); free(y)
  END ADC;

  PROCEDURE SBC*(VAR x, y: Item);
  BEGIN PutDO(A.SUBC, y, x); free(y)
  END SBC;

  PROCEDURE Bit*(VAR x, y: Item);
    VAR t!, t1!: Item;
  BEGIN t.am := A.Immediate; t.reg := 0; t.obj := NIL;
    x.mode := RegI; x.a := 0; load(x);
    IF y.mode = B.Const THEN t.ofs := LSL(1, y.a); A.PutDO(mcode, A.BIT, t, x, A.Word)
    ELSE t1.mode := B.Const; t1.a := 1; t1.obj := NIL; Rla(t1, y); PutDO(A.BIT, t1, x)
    END;
    free(x); free(y);
    SetCC(x, A.NE)
  END Bit;

  PROCEDURE Register*(VAR x: Item);
  BEGIN (*x.mode = Const*)
    x.reg := x.a; x.mode := Reg; PutDO(A.MOV, x, rh); alloc(x)
  END Register;

  PROCEDURE Adr*(VAR x: Item);
  BEGIN 
    IF x.mode IN {B.Var, B.Par, RegI} THEN loadAdr(x)
    ELSIF (x.mode = B.Const) & (x.type.form = B.Proc) THEN load(x)
    ELSIF (x.mode = B.Const) & (x.type.form = B.String) THEN loadStringAdr(x)
    ELSE S.Mark("not addressable")
    END
  END Adr;

  PROCEDURE Condition*(VAR x: Item);
  BEGIN (*x.mode = Const*) SetCC(x, x.a)
  END Condition;

  PROCEDURE Open*;
    VAR i: INTEGER;
  BEGIN A.Init(mcode); curImport := 0; frmOfsSegs.NofSegs := 0; frmOfsSegs.Segs[0].ofsptos := 0;
    FOR i := 0 TO LEN(traps) - 1 DO traps[i] := NIL END;
    FOR i := 0 TO LEN(arith) - 1 DO arith[i] := NIL END;
    FOR i := 0 TO LEN(vector) - 1 DO vector[i] := 0FFFFH END;
    tdx := 0; strx := 0; RIU := {};
    rh.reg := 15; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL; rh.mode := Reg; rh.type := B.intType;
    AllocUp := FALSE; RL := A.CG2; RB := 15;
  END Open;

  PROCEDURE SetDataSize*(dc: LONGINT);
  BEGIN varsize := dc
  END SetDataSize;

  PROCEDURE Header*;
  BEGIN entry := mcode.pc; OfsPTOS(0, FALSE); RB := 15
  END Header;

  PROCEDURE WriteWord(VAR R: Files.Rider; w: INTEGER);
  BEGIN Files.WriteByte(R, w MOD 100H); Files.WriteByte(R, w DIV 100H MOD 100H);
  END WriteWord;

  PROCEDURE FindPtrs(VAR R: Files.Rider; typ: B.Type; adr: LONGINT);
    VAR fld!: B.Object; i, s: LONGINT;
  BEGIN
    IF (typ.form = B.Pointer) OR (typ.form = B.NilTyp) THEN WriteWord(R, adr)
    ELSIF typ.form = B.Record THEN
      fld := typ.dsc;
      WHILE fld # NIL DO FindPtrs(R, fld.type, fld.val + adr); fld := fld.next END
    ELSIF typ.form = B.Array THEN
      s := typ.base.size;
      FOR i := 0 TO typ.len-1 DO FindPtrs(R, typ.base, i*s + adr) END
    END
  END FindPtrs;

  PROCEDURE WriteFixup(VAR R: Files.Rider; class: BYTE; form: INTEGER);
    VAR obj!, obj2!: B.Object;
  BEGIN
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*local objects fixup chains*)
      IF (obj.class = class) & ((form = 0) OR (obj.type.form = form)) & (obj.usedat # 0) & (obj.lev = 0) THEN
        WriteWord(R, obj.usedat); Files.WriteByte(R, 0); (*local object*); WriteWord(R, obj.val); (*relative address*)
      END;
      obj := obj.next
    END;
    obj := B.topScope.next;
    WHILE (obj # NIL) & (obj.class = B.Mod) DO  (*imported objects fixup chains*)
      IF obj.dsc # B.system THEN
        obj2 := obj.dsc;
        WHILE obj2 # NIL DO
          IF (obj2.class = class) & ((form = 0) OR (obj2.type.form = form)) & (obj2.usedat # 0) & (obj2.lev < 0) THEN
            WriteWord(R, obj2.usedat); Files.WriteByte(R, -obj2.lev); (*module number*); WriteWord(R, obj2.val); (*object number*)
          END;
          obj2 := obj2.next
        END
      END;
      obj := obj.next
    END;
    WriteWord(R, 0);
  END WriteFixup;

  PROCEDURE Close*(VAR modid: S.Ident; key, nofent: LONGINT);
    VAR obj!, obj2!: B.Object;
      i, comsize, nofimps, size: LONGINT;
      name: S.Ident;
      F!: Files.File; R!: Files.Rider;
  BEGIN  (*exit code*) A.PutNO(mcode, A.RET); OfsPTOS(-1, TRUE);
    obj := B.topScope.next; nofimps := 0; comsize := 2;
    WHILE obj # NIL DO
      IF (obj.class = B.Mod) & (obj.dsc # B.system) THEN INC(nofimps); (*count imports*)
      ELSIF (obj.exno # 0) & (obj.class = B.Const) & (obj.type.form = B.Proc)
          & (obj.type.nofpar = 0) & (obj.type.base = B.noType) THEN i := 0; (*count commands*)
        WHILE obj.name[i] # 0X DO INC(i) END ;
        i := (i+2) DIV 2 * 2; INC(comsize, i+2)
      END ;
      obj := obj.next
    END ;
    
    (*varsize includes type descriptors*)
    size := varsize + strx + comsize + mcode.pc + (nofimps + nofent + 1)*2; (*size is aligned on 2 bytes boundary*)
    
    B.MakeFileName(name, modid, ".mpc"); (*write code file*)
    F := Files.New(name); Files.Set(R, F, 0); Files.WriteString(R, modid); Files.WriteInt(R, key);
    WriteWord(R, size);
    obj := B.topScope.next;
    WHILE (obj # NIL) & (obj.class = B.Mod) DO  (*imports*)
      IF obj.dsc # B.system THEN Files.WriteString(R, obj(B.Module).orgname); Files.WriteInt(R, obj.val) END;
      obj := obj.next
    END;
    Files.Write(R, 0X);
    WriteWord(R, tdx*2);
    i := 0;
    WHILE i < tdx DO WriteWord(R, data[i]); INC(i) END ; (*type descriptors*)
    WriteWord(R, varsize - tdx*2);  (*data*)
    WriteWord(R, strx);
    FOR i := 0 TO strx-1 DO Files.Write(R, str[i]) END ;  (*strings*)
    WriteWord(R, mcode.pc);  (*code len*)
    FOR i := 0 TO mcode.pc-1 DO Files.WriteByte(R, mcode.code[i]) END ;  (*program*)
    Files.WriteByte(R, LEN(vector));  (*Vectors table*)
    FOR i := 0 TO LEN(vector) - 1 DO WriteWord(R, vector[i]) END;
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*commands*)
      IF (obj.exno # 0) & (obj.class = B.Const) & (obj.type.form = B.Proc) &
          (obj.type.nofpar = 0) & (obj.type.base = B.noType) THEN
        Files.WriteString(R, obj.name); WriteWord(R, obj.val)
      END ;
      obj := obj.next
    END ;
    Files.Write(R, 0X);
    WriteWord(R, nofent); WriteWord(R, entry);
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*entries*)
      IF obj.exno # 0 THEN
        IF (obj.class = B.Const) & (obj.type.form = B.Proc) OR (obj.class = B.Var) THEN
          WriteWord(R, obj.val);
        ELSIF obj.class = B.Typ THEN
          IF obj.type.form = B.Record THEN WriteWord(R, obj.type.len)
          ELSIF (obj.type.form = B.Pointer) & ((obj.type.base.typobj = NIL) OR (obj.type.base.typobj.exno = 0)) THEN
            WriteWord(R,  obj.type.base.len)
          END
        END
      END ;
      obj := obj.next
    END ;
    WriteFixup(R, B.Const, B.Proc); (*procedures fixup data*)
    WriteFixup(R, B.Const, B.Handler); (*interrupt handlers fixup data*)
    WriteFixup(R, B.Var, 0); (*variable fixup data*)
    (*record types fixup data*)
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*local types fixup chains*)
      IF (obj.class = B.Typ) & (obj.usedat # 0) & (obj.type.mno = 0) THEN
        WriteWord(R, obj.usedat); Files.WriteByte(R, 0); (*local type*); WriteWord(R, obj.type.len); (*relative address*)
      END;
      obj := obj.next
    END;
    obj := B.topScope.next;
    WHILE (obj # NIL) & (obj.class = B.Mod) DO  (*imported types fixup chains*)
      IF obj.dsc # B.system THEN
        obj2 := obj.dsc;
        WHILE obj2 # NIL DO
          IF (obj2.class = B.Typ) & (obj2.usedat # 0) & (obj2.type.mno > 0) THEN
            WriteWord(R, obj2.usedat); Files.WriteByte(R, obj2.type.mno); (*module number*); WriteWord(R, obj2.type.len); (*object address*)
          END;
          obj2 := obj2.next
        END
      END;
      obj := obj.next
    END;
    WriteWord(R, 0);
    WriteWord(R, entry);
    Files.Write(R, "O"); Files.Register(F);
    (*write object addresses to source position mapping in .o43 file*)
    B.MakeFileName(name, modid, ".o43"); F := Files.New(name); Files.Set(R, F, 0); WriteWord(R, mcode.pc DIV 2); size := 1;
    FOR i := 1 TO mcode.pc DIV 2 - 1 DO 
      IF (size < 255) & (mcode.pos[i] = mcode.pos[i-1]) THEN INC(size) ELSE Files.WriteByte(R, size); Files.WriteInt(R, mcode.pos[i - 1]); size := 1 END
    END; Files.WriteByte(R, size); Files.WriteInt(R, mcode.pos[mcode.pc DIV 2 - 1]); Files.Register(F);
    (*write word offset with caller top of stack*)
    OfsPTOS(-1, FALSE); (*close last segment*) B.MakeFileName(name, modid, ".r43"); F := Files.New(name); Files.Set(R, F, 0); 
    Files.WriteInt(R, frmOfsSegs.NofSegs);
    FOR i := 0 TO frmOfsSegs.NofSegs DO Files.WriteInt(R, frmOfsSegs.Segs[i].end); Files.WriteInt(R, frmOfsSegs.Segs[i].ofsptos) END;
    Files.Register(F)
  END Close;

  PROCEDURE initConst(VAR c: Item; v: INTEGER);
  BEGIN c.reg := 0; c.am := A.Immediate; c.ofs := v; c.obj := NIL; c.type := B.intType;
    c.mode := B.Const; c.tmp := FALSE; c.a := v
  END initConst;

BEGIN NEW(mcode); NEW(frmOfsSegs); A.SetProcs(GetOffset, AllocR, freeR);
  initConst(cm1, -1); initConst(c0, 0); initConst(c1, 1); initConst(c2, 2);
  pc.reg := A.PC; pc.am := A.Register; pc.ofs := 0; pc.obj := NIL; pc.type := B.intType;
  sp.reg := A.SP; sp.am := A.Register; sp.ofs := 0; sp.obj := NIL; sp.type := B.intType;
  r4.reg := 4; r4.am := A.Register; r4.ofs := 0; r4.obj := NIL; r4.type := B.intType;
  r15.reg := 15; r15.am := A.Register; r15.ofs := 0; r15.obj := NIL; r15.type := B.intType;
  relmap[0] := A.EQ; relmap[1] := A.NE; relmap[2] := A.L; relmap[3] := A.GE;
  B.SetRegRTProcCallback(RegisterRTproc)
END OMSPG.
