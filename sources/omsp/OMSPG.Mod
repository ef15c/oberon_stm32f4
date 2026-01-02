MODULE OMSPG; (* N.Wirth, 16.4.2016 / 4.4.2017 / 31.5.2019  Oberon compiler;
  C. Schoffit 21.05.24 code generator for MSP430 processor family*)
  IMPORT SYSTEM, Files, A := OMSPA, S := OMSPS, B := OMSPB;
  (*Code generator for Oberon compiler targetting MSP430 processor.
     Procedural interface to Parser OMSPP; result in record "code".
     Procedure Close writes code-files*)

  CONST WordSize* = 2; maxStrs = 10000H;
    Register* = TRUE; Stack* = FALSE;

    Reg = 10; RegI = 11; Cond = 12; Absol = 13; (*internal item modes*)

  TYPE Item* = RECORD(A.Item)
    mode*: INTEGER;
    type*: B.Type;
    obj*: B.Object; (*symbol object, for register variables*)
    a*, b*, c*: INTEGER;
    rdo*, tmp, radr, ptr: BOOLEAN  (*read only, temporary item, runtime address indicator, pointer indicator*)
  END ;

  (* Item forms and meaning of fields:
  mode            c       a         b
  --------------------------------------
  Const           -      value             immediate value
  Var            base     sn       off     direct adr, offset for locals, section number for others
  Par             -      off0      off1    indirect adr
  Stored Const   base     sn       off     proc or immediate or runtime value (+ length for string form)
  Reg             -       -         -
  RegI            -      off        -
  Cond           cond   Fchain   Tchain

    regno is now always in reg field
 *)

    Fixup = POINTER TO FixupDesc;
    FixupDesc = RECORD
      fixadr: INTEGER;
      mno: BYTE; sno, offset: INTEGER;
      next: Fixup
    END;

    ModuleCodeDesc = RECORD (A.ModuleCode) END;
    Content = POINTER TO ModuleCodeDesc;

    Section = POINTER TO SectionDesc;
    SectionDesc = RECORD
      no: INTEGER; name: S.Ident;
      segment: CHAR; size, org: INTEGER; (*org: index to the first byte of the content in mcode*)
      content: Content;
      fixup: Fixup;
      next: Section
    END;

  VAR 
    AllocUp: BOOLEAN; (*if true, registers are in allocated in ascending or from R4 to R15, if false in descending order from R15 to R4*)
    RIU*, VRS: SET;      (*currently in use and variable + parameter register sets*)
    RB, RL: INTEGER; (*register base and limit*)
    PRU*: SET; (*set of registers used in procedure*)
    frame, vframe: INTEGER;   (*frame offset changed in SaveRegs and RestoreRegs + variable and parameter frame offset*)
    traps: ARRAY 8 OF B.Object; arith: ARRAY 4 OF B.Object;

    relmap, urelmap: ARRAY 4 OF INTEGER;    (*condition codes for relations*)
    cm1, c0, c1, c2, pc, sp, sr, cg2, r4, r15: Item-; (*constant Items set by module initialization code*)
    rh: Item;
    curImport: INTEGER;

    head, tail, vectors, body, ccs: Section; nofsec: INTEGER;
    mcode, strings: A.ModuleCode; (*strings and module code segments*)
    varsize*: INTEGER; (*RAM counter*)
    flagsObj: B.Object;

    PutDO0: PROCEDURE(op: BYTE; VAR src, dst: Item);

  PROCEDURE PrintItem(msg: ARRAY OF CHAR; x: Item);
  BEGIN S.DebugString("PrintItem", msg);
    IF x.obj # NIL THEN S.DebugString("name", x.obj.name) END;
    S.DebugHex("@", SYSTEM.ADR(x));
    S.DebugHex("mode", x.mode); S.DebugHex("reg", x.reg); 
    S.DebugHex("a", x.a); S.DebugHex("b", x.b); S.DebugHex("c", x.c);
    S.DebugHex("size", x.type.size);
    S.DebugHex("adr", ORD(x.radr)); S.DebugHex("ptr", ORD(x.ptr));
    S.DebugHex("tmp", ORD(x.tmp)); S.DebugHex("rdo", ORD(x.rdo))
  END PrintItem;

  PROCEDURE pad(x: INTEGER): INTEGER;
    RETURN (x + (WordSize - 1)) DIV WordSize*WordSize
  END pad;

  PROCEDURE SetFCO(x: A.Item; state: BOOLEAN);
  BEGIN
    CASE x OF
      Item: IF state THEN flagsObj := x.obj ELSE flagsObj := NIL END
    | A.Item: flagsObj := NIL
    END;
  END SetFCO;

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
      ELSIF p.name = "divmod16" THEN arith[1] := p
      ELSIF p.name = "set" THEN arith[2] := p
      END
    END
  END RegisterRTproc;

  PROCEDURE SaveRegs(regs: SET);
    VAR n: INTEGER;
  BEGIN
    IF regs # {} THEN
      n := A.PushRegs(mcode, regs); INC(frame, n*WordSize)
    END
  END SaveRegs;

  PROCEDURE RestoreRegs(regs: SET);
    VAR n: INTEGER;
  BEGIN
    IF regs # {} THEN
      n := A.PopRegs(mcode, regs); DEC(frame, n*WordSize)
    END
  END RestoreRegs;

  PROCEDURE EnableCode*(e: BOOLEAN);
  BEGIN A.SetEnabled(e)
  END EnableCode;

  PROCEDURE FixOne*(at: INTEGER);
  BEGIN A.FixOne(mcode, at)
  END FixOne;

  PROCEDURE FixLinkWith*(L, dst: INTEGER);
    VAR L1: INTEGER;
  BEGIN
    IF A.enabled THEN
      WHILE L # 0 DO L1 := L - (mcode.code[L+1] MOD ORD({2})*ORD({8}) + mcode.code[L])*2;
        A.fix(mcode, L, dst-L-2);
        IF L = L1 THEN L := 0 (*force exit*) ELSE L := L1 END;
      END
    END
  END FixLinkWith;

  PROCEDURE FixLink*(L: INTEGER);
  BEGIN FixLinkWith(L, mcode.pc); flagsObj := NIL
  END FixLink;

  PROCEDURE SetAllocationMode*(mode: BOOLEAN);
  BEGIN AllocUp := mode;
    IF AllocUp THEN RL := 16;  RB := A.CG2 + 1
    ELSE RL := A.CG2;  RB := 15
    END
  END SetAllocationMode;

  PROCEDURE SetRIU*(iu: SET);
  BEGIN RIU := iu
  END SetRIU;

  PROCEDURE SetPRU*(pr: SET);
  BEGIN PRU := pr
  END SetPRU;

  PROCEDURE nextR(VAR r: INTEGER);
  BEGIN IF AllocUp THEN INC(r) ELSE DEC(r) END
  END nextR;

  PROCEDURE LimitRegisters*(savedregs: SET);
  BEGIN IF savedregs * {0..3, 16..31} # {} THEN S.Mark("registers out of range"); savedregs := {4..15} END;
    RIU :=  RIU + ({0..15} - savedregs) (*mark non saved registers as not available*)
  END LimitRegisters;

  PROCEDURE allocR*(r: INTEGER);
  BEGIN
    IF RIU*{r} = {} THEN INCL(RIU, r); INCL(PRU, r) ELSE S.Mark("reg already allocated") END
  END allocR;

  PROCEDURE AllocRP(pr: INTEGER): INTEGER;
    VAR RH: INTEGER;
  BEGIN (*register are allocated from the beginning in the order specified by AllocUp value*)
    IF pr # 0FFH THEN RH := pr
    ELSE RH := RB; WHILE (RIU*{RH} # {}) & (RH # RL) DO nextR(RH) END
    END;
    IF RH = RL THEN S.Mark("register stack overflow"); ASSERT(FALSE); RH := 8 END;
    allocR(RH); rh.reg := RH

    RETURN RH
  END AllocRP;

  PROCEDURE AllocR*(): INTEGER;
    RETURN AllocRP(0FFH)
  END AllocR;

  PROCEDURE alloc(VAR x: Item; pr: INTEGER); (*allocate a temporary register to the item*)
  BEGIN
    x.reg := AllocRP(pr); x.am := A.Register; x.ofs := 0; x.tmp := TRUE
  END alloc;

  PROCEDURE freeR*(r: INTEGER);
  BEGIN
    IF r IN RIU THEN EXCL(RIU, r) ELSE S.Mark("reg wild free"); ASSERT(FALSE) END
  END freeR;

  PROCEDURE freeSet(rs: SET);
    VAR r: INTEGER;
  BEGIN IF rs # {} THEN
    FOR r := 0 TO 15 DO IF rs*{r} # {} THEN freeR(r) END END
    END
  END freeSet;

  PROCEDURE free(VAR x: Item);
  BEGIN IF x.tmp THEN freeR(x.reg); x.tmp := FALSE END
  END free;

  PROCEDURE resultRegister*(VAR res: Item);
  BEGIN
    IF AllocUp THEN res := r4 ELSE res := r15 END
  END resultRegister;

  PROCEDURE CheckRegs*;
  BEGIN IF RIU # VRS THEN S.Mark("Reg Stack"); RIU := VRS END;
    IF mcode.pc >= A.maxCode - 40 THEN S.Mark("program too long") END ;
    IF frame # vframe THEN S.Mark("frame error"); frame := vframe END
  END CheckRegs;

  PROCEDURE SetCC(VAR x: Item; n: INTEGER);
  BEGIN x.mode := Cond; x.a := 0; x.b := 0; x.c := n
  END SetCC;

  PROCEDURE TypeChecked(): BOOLEAN;
  RETURN traps[2] # NIL
  END TypeChecked;

  PROCEDURE AssertionChecked*(): BOOLEAN;
  RETURN traps[7] # NIL
  END AssertionChecked;

  PROCEDURE GetFixup(s: Section; mno: BYTE; sno, offset: INTEGER): Fixup;
    VAR f!: Fixup;
  BEGIN ASSERT((mno >= 0) & (mno <= 64)); f := s.fixup;
    WHILE (f # NIL) & ((f.mno # mno) OR (f.sno # sno) OR (f.offset # offset)) DO f := f.next END;
    IF f = NIL THEN NEW(f); f.mno := mno; f.sno := sno; f.offset := offset; f.next := s.fixup; s.fixup := f END

    RETURN f
  END GetFixup;

  PROCEDURE NewSection(content: A.ModuleCode; VAR s: Section; seg: CHAR; name: ARRAY OF CHAR);
  BEGIN ASSERT ((seg = "c") OR (seg = "d") OR (seg = "s") OR (seg = "v") OR (seg = "r"));
    NEW(s); s.segment := seg; s.name := name; s.content := SYSTEM.VAL(Content, SYSTEM.ADR(content));
    IF seg = "c" THEN ccs := s END;
    IF seg = "r" THEN  s.org := varsize ELSE s.org := content.pc END;
    s.no := nofsec; INC(nofsec);
    IF head = NIL THEN head := s; tail := s ELSE tail.next := s; tail := s END;
  END NewSection;

  PROCEDURE DeleteLastSection;
    VAR nt! : Section;
  BEGIN ASSERT(tail.segment # "c");
    DEC(nofsec); DEC(tail.content.pc, tail.size);
    IF head = tail THEN head := NIL; tail := NIL
    ELSE nt := head; WHILE nt.next # tail DO nt := nt.next END; tail := nt; nt.next := NIL
    END
  END DeleteLastSection;

  PROCEDURE GetSection(no: INTEGER): Section;
    VAR s!: Section;
  BEGIN s := head;
    WHILE (s # NIL) & (s.no # no) DO s := s.next END;

    RETURN s
  END GetSection;

  PROCEDURE EmitByte(s: Section; b: BYTE);
  BEGIN s.content.code[s.content.pc] := b; INC(s.content.pc); INC(s.size)
  END EmitByte;

  PROCEDURE EmitWord(VAR s: Section; w: INTEGER);
  BEGIN A.PutWordAt(s.content^, s.content.pc, w); INC(s.content.pc, 2); INC(s.size, 2)
  END EmitWord;

  PROCEDURE AllocV*(o: B.Object; VAR lvs: INTEGER);
    VAR s!: Section;
  BEGIN
    IF o.lev = 0 THEN (*global*) NewSection(mcode, s, "r", o.name); o.val := s.no; s.size := o.type.size; INC(varsize, o.type.size)
    ELSE ASSERT(o.lev > 0); (*local*)
      IF o.type.size > 1 THEN lvs := (lvs + (WordSize - 1)) DIV WordSize * WordSize (*align on WordSize*) END;
      o.val := lvs; INC(lvs, o.type.size)
    END
  END AllocV;

  PROCEDURE AllocP*(o: B.Object);
    VAR s!: Section;
  BEGIN ASSERT(o.lev >= 0);
    NewSection(mcode, s, "c", o.name); o.val := s.no
  END AllocP;

  PROCEDURE EndP*(o: B.Object);
    VAR s!: Section;
  BEGIN s := GetSection(o.val); s.size := s.content.pc - s.org
  END EndP;

  PROCEDURE CheckWord(val: INTEGER);
  BEGIN ASSERT((val >= -ORD({15})) & (val < ORD({16})))
  END CheckWord;

  PROCEDURE UpdateChain(s: Section; pos, val: INTEGER; x: Item): INTEGER;
    VAR res: INTEGER; f!: Fixup;
  BEGIN
    IF x.radr THEN f := GetFixup(s, -x.c, x.a, x.b MOD 10000H); res := f.fixadr; f.fixadr := pos
    ELSIF ~((val >= -ORD({15})) & (val < ORD({16}))) THEN S.Mark("constant out of range"); res := 0
    ELSE res := val
    END

    RETURN res
  END UpdateChain;

  PROCEDURE GetOffset(x: A.Item): INTEGER;
    VAR res: INTEGER;
  BEGIN CASE x OF
    Item: res := UpdateChain(ccs, mcode.pc - ccs.org + 1, x.ofs, x)
    | A.Item: res := x.ofs
    END

    RETURN res
  END GetOffset;

  PROCEDURE CheckWritable*(VAR x: Item);
  BEGIN IF x.mode IN {RegI, Absol} THEN x.rdo := FALSE END
  END CheckWritable;

  PROCEDURE MakeItem*(VAR x: Item; y: B.Object; curlev: INTEGER);
  BEGIN x := c0; x.mode := y.class; x.type := y.type; x.a := y.val; x.rdo := y.rdo; x.c := y.lev; x.obj := y;
    IF (y.class IN {B.Var, B.Par}) THEN
      IF y.register # 0FFH THEN
        x.reg := y.register;
        IF y.class = B.Var THEN x.mode := Reg ELSE x.mode := RegI END
      END;
    ELSIF (y.class = B.StoredConst) & (y.type.form = B.Proc) THEN x.ptr := TRUE (*const procs are always pointers*)
    ELSIF y.type.form = B.String THEN x.a := y.val MOD 10000H (*no*); x.b := LSL(LSR(y.val, 16), 16) (*len*)
    END;

    x.radr := (y.lev <= 0) & (y.class = B.Var) OR (y.class = B.StoredConst); (*global and extenal vars and stored contanst have a runtime address*)
    IF (y.lev > 0) & (y.lev # curlev) & ~(y.class IN {B.Const, B.StoredConst}) OR
        (y.lev >= 0) & (y.class = B.StoredConst) & (GetSection(x.a) = NIL) THEN S.Mark("not accessible ")
    END
  END MakeItem;

  PROCEDURE loadOrdCond(VAR x: Item; pr: BYTE); (*load condition item in a temporary register*)
    VAR pc0, pc1: INTEGER; t!: Item;
  BEGIN ASSERT(x.mode = Cond);
    alloc(x, pr); pc0 := mcode.pc; A.PutJ(mcode, A.negated(x.c), 0);
    FixLink(x.b); t := c1; A.PutDO(mcode, A.MOV, t, x, A.Word);
    pc1 := mcode.pc; A.PutJ(mcode, A.AL, 0);
    A.fix(mcode, pc0, mcode.pc - pc0 - 2); FixLink(x.a); t := c0;
    A.PutDO(mcode, A.MOV, t, x, A.Word);
    A.fix(mcode, pc1, mcode.pc - pc1 - 2)
  END loadOrdCond;

  PROCEDURE setRAO(op: INTEGER; VAR i: Item; dst: BOOLEAN; VAR nba, bw: SET);
    VAR ti!: Item; tptr: BOOLEAN;
  BEGIN ASSERT(ORD(i.radr) < 2); ASSERT(ORD(i.ptr) < 2); (*assure that i.radr and i.ptr were properly initialized*)
    ti := c0;
    IF ~dst & (i.type.size = 1) & (bw = A.Word) THEN S.Mark("move byte to int") END;
    IF (op = A.PUSH) OR (op = A.CALL) THEN dst := FALSE END;
    IF i.type.size = 1 THEN bw := A.Byte END;
    IF dst & i.rdo & ((i.mode = B.Const) OR (op # A.CMP) & (op # A.BIT)) THEN
      (*this op will modify the destination which is read only. We will use a temporary register*)
      ti := i; free(i); i.mode := Reg; alloc(i, 0FFH); i.radr := FALSE; i.rdo := FALSE; i.tmp := TRUE;
      tptr := i.ptr; i.ptr := FALSE; PutDO0(A.MOV, ti, i); setRAO(op, i, dst, nba, bw); i.ptr := tptr
    ELSIF i.mode = B.Var THEN
      IF i.c > 0 THEN i.reg := A.SP; i.am := A.Indexed; i.ofs := i.a + frame
      ELSE i.reg := 0; IF i.ptr THEN i.am := A.Immediate2 ELSE i.am := A.Absolute END
      END
    ELSIF i.mode = Reg THEN i.am := A.Register; i.ofs := 0
    ELSIF i.mode = RegI THEN i.am := A.Indexed; i.ofs := i.a
    ELSIF i.mode = Absol THEN  i.am := A.Absolute; i.ofs := i.a
    ELSIF i.mode = B.Const THEN i.ofs := i.a; i.reg := 0;
      IF i.radr THEN i.am := A.Immediate2 ELSE i.am := A.Immediate END;
      IF dst THEN S.Mark("not writable"); i.am := A.Absolute END
    ELSIF i.mode = B.Par THEN rh.reg := AllocR(); INCL(nba, rh.reg);
      ti.am := A.Indexed; ti.reg := A.SP; ti.obj := NIL; ti.ofs := i.a + frame;
      A.PutDO(mcode, A.MOV, ti, rh, A.Word);
      i.mode := RegI; i.reg := rh.reg; i.a := i.b; i.b := 0; setRAO(op, i, dst, nba, bw)
    ELSIF i.mode = Cond THEN loadOrdCond(i, 0FFH)
    ELSIF i.mode = B.StoredConst THEN i.reg := 0; IF i.ptr THEN i.am := A.Immediate2 ELSE i.am := A.Absolute END
    ELSE S.Mark("bad mode in setRAO")
    END;
  END setRAO;

  PROCEDURE PutSO(op: INTEGER; VAR sd: Item);
    VAR bw, nba: SET;
  BEGIN
    nba := {}; bw := A.Word; setRAO(op, sd, TRUE, nba, bw);
    IF (sd.reg = A.SP) & ((op = A.CALL) & (sd.am = A.Indexed) OR (op = A.PUSH)) THEN
      INC(sd.ofs, WordSize) (*SP is predrecemented, so the offset is augmented by 2*)
    END;
    IF op = A.PUSH THEN INC(frame, WordSize) ELSIF op = A.POP THEN DEC(frame, WordSize) END;
    A.PutSO(mcode, op, sd, bw); freeSet(nba);
  END PutSO;

  PROCEDURE PutJ(cond: BYTE; offset: INTEGER);
  BEGIN A.PutJ(mcode, cond, offset)
  END PutJ;

 PROCEDURE Trap(cond, num: INTEGER);
  (*Trap is implemented as calls to functions in the Trap special module.
     If the procedure Trap.Handle<num> procedure exists and is exported,
     the trap checking code is generated.*)
  VAR t!: Item;
  BEGIN IF cond # A.AL THEN PutJ(A.negated(cond), 4) END;
    MakeItem(t, traps[num], 0); PutSO(A.CALL, t)
  END Trap;

  PROCEDURE convertSize(VAR src: Item; t: B.Type): BOOLEAN;
    VAR tmp: BOOLEAN; it!: Item;
  BEGIN tmp := FALSE;
    IF (src.type.size = 1) & (t.size = 2) THEN (*move byte to word*)
      IF ~(src.mode IN {Reg, B.Const}) THEN
        it := src; free(src); alloc(src, 0FFH); src.mode := Reg; src.rdo := FALSE;
        PutDO0(A.MOV, it, src); tmp := TRUE
      END; src.type := B.intType (*extend source*)
    END

    RETURN tmp
  END convertSize;

  PROCEDURE PutDO(op: BYTE; VAR src, dst: Item);
    VAR bw, nba: SET; tmp: BOOLEAN;
  BEGIN tmp := convertSize(src, dst.type);
    nba := {}; bw := A.Word; setRAO(op, dst, TRUE, nba, bw); setRAO(op, src, FALSE, nba, bw);
    A.PutDO(mcode, op, src, dst, bw); freeSet(nba);
    IF tmp THEN free(src) END
  END PutDO;

  PROCEDURE NilCheck(a: BYTE);
    VAR t!, c!: Item;
  BEGIN
    IF traps[4] # NIL THEN
       t := r15; t.reg := a; c := c0; PutDO(A.CMP, c, t);
      Trap(A.EQ, 4)
    END
  END NilCheck;

  (* loading of operands and addresses into registers *)

  PROCEDURE load(VAR x: Item; pr: BYTE); (*load item in a temporary register*)
    VAR t!: Item; tptr: BOOLEAN;
  BEGIN
    IF (x.mode # Reg) OR ((~x.tmp OR (pr # 0FFH)) & (x.reg # pr)) THEN (*temporary copy needed*)
      t := x; free(x); alloc(x, pr); x.mode := Reg; x.tmp := TRUE; x.rdo := FALSE; x.radr := FALSE;
      tptr := x.ptr; ASSERT(ORD(tptr) < 2); x.ptr := FALSE; PutDO(A.MOV, t, x); x.ptr := tptr;
    END
  END load;

  PROCEDURE push(VAR x: Item; dsize: INTEGER);
    VAR tmp: BOOLEAN;
  BEGIN
    IF (x.type.size = 1) & (dsize = WordSize) THEN tmp := convertSize(x, B.intType); END;
    PutSO(A.PUSH, x);
    free(x)
  END push;

  PROCEDURE Adr*(VAR x:Item);
    VAR t!: Item;
  BEGIN t := c0;
    IF ~x.ptr THEN x.ptr := TRUE;
      IF x.mode = B.Par THEN x.mode := B.Var;
        IF x.b # 0 THEN t.a := x.b; x.type := B.intType; PutDO(A.ADD, t, x) END
      ELSIF x.mode = B.Var THEN
        IF x.c > 0 THEN (*local*) ASSERT(x.tmp = FALSE); x.mode := Reg; x.reg := A.SP; x.rdo := TRUE;
          IF x.a + frame # 0 THEN t.a := x.a + frame; x.type := B.intType; PutDO(A.ADD, t, x) END
        ELSE (*global or imported*) x.mode := B.Const; x.radr := TRUE;
        END
      ELSIF x.mode = RegI THEN x.mode := Reg; x.type := B.intType; x.rdo := FALSE;
        IF x.a # 0 THEN t.radr := x.radr; t.a := x.a; PutDO(A.ADD, t, x); x.radr := FALSE END
      ELSIF ~(x.mode IN {B.Var, B.StoredConst, Absol}) THEN S.Mark("not addressable")
      END
    END
(*
    VAR t!: Item;
  BEGIN t.mode := B.Const; t.type := B.intType; t.obj := NIL;
    IF x.ptr OR (x.mode = Absol) THEN (*Nothing to do*)
    ELSIF x.mode = B.Var THEN
      IF x.c > 0 THEN (*local*) ASSERT(x.tmp = FALSE); x.mode := Reg; x.reg := A.SP; x.rdo := TRUE;
        IF x.a + frame # 0 THEN t.a := x.a + frame; x.type := B.intType; PutDO(A.ADD, t, x) END
      ELSE (*global or imported*) x.mode := B.Const; x.ptr := TRUE;
      END
    ELSIF x.mode = B.Par THEN x.mode := B.Var;
      IF x.b # 0 THEN t.a := x.b; x.type := B.intType; PutDO(A.ADD, t, x) END
    ELSIF x.mode = B.StoredConst THEN  x.mode := B.Const; x.ptr := TRUE;
    ELSIF x.mode = RegI THEN x.mode := Reg;
      IF x.a # 0 THEN t.a := x.a; t.b := x.b; t.c := x.c; x.type := B.intType; PutDO(A.ADD, t, x) END
    ELSE S.Mark("not addressable")
    END;
    x.type := B.intType
*)
  END Adr;

  PROCEDURE loadAdr(VAR x: Item; pr: INTEGER);
  BEGIN Adr(x); load(x, pr)
  END loadAdr;

  PROCEDURE pushAdr(VAR x: Item);
  BEGIN Adr(x); push(x, 2)
  END pushAdr;

  PROCEDURE loadCond(VAR x: Item);
    VAR t!: Item;
  BEGIN
    IF x.type.form = B.Bool THEN
      IF x.mode = B.Const THEN IF x.a = 0 THEN x.c := A.NV ELSE x.c := A.AL END
      ELSE t := c0; PutDO(A.CMP, t, x); x.c := A.NE; free(x)
      END;
      x.mode := Cond; x.a := 0; x.b := 0
    ELSE S.Mark("not Boolean?")
    END
  END loadCond;

  PROCEDURE MakeTypTagAdr(VAR x: Item; T: B.Type);
  BEGIN x := c0; x.mode := B.StoredConst; x.radr := TRUE; x.ptr := TRUE; x.type := B.intType; x.a := T.len; x.c := T.typobj.lev;
    x.rdo := TRUE; x.obj := T.typobj; x.am := A.Undefined
  END MakeTypTagAdr;

  PROCEDURE loadTypTagAdr(T: B.Type; pr: INTEGER): BYTE;
    VAR t!: Item;
  BEGIN MakeTypTagAdr(t, T); load(t, pr);
    RETURN t.reg
  END loadTypTagAdr;

  PROCEDURE pushTypTagAdr(T: B.Type);
    VAR t!: Item;
  BEGIN MakeTypTagAdr(t, T); push(t, WordSize);
  END pushTypTagAdr;

  (* Items: Conversion from constants or from Objects on the Heap to Items on the Stack*)

  PROCEDURE MakeConstItem*(VAR x: Item; typ: B.Type; val: INTEGER);
  BEGIN x.mode := B.Const; x.type := typ; x.a := val; x.c := 0; x.radr := FALSE; x.ptr := FALSE;
    x.rdo := TRUE; x.obj := NIL; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0
  END MakeConstItem;

  PROCEDURE stringFound(str: ARRAY OF CHAR; len: INTEGER; VAR s: Section): BOOLEAN;
   (*if the string already exists in a section, return TRUE with the position in parameter pos*)
    VAR found: BOOLEAN; i: INTEGER;
  BEGIN found := FALSE; s := head;
    WHILE ~found & (s # NIL) DO
      IF s.segment = "s" THEN
        i := 0; WHILE (i < len) & (str[i] = CHR(strings.code[s.org + i])) DO INC(i) END;
        IF i = len THEN found := TRUE ELSE s := s.next END
      ELSE s := s.next
      END
    END

    RETURN found
  END stringFound;

  PROCEDURE Length*(x: Item): INTEGER;
    VAR l: INTEGER;
  BEGIN
    IF x.type.form = B.String THEN l := LSR(x.b, 16)
    ELSE l := x.type.len
    END

    RETURN l
  END Length;

  PROCEDURE stringPut(VAR x: Item; str: ARRAY OF CHAR; len: INTEGER);
    VAR i: INTEGER; s!: Section;
  BEGIN x.mode := B.StoredConst; x.type := B.strType; x.b := LSL(len, 16); x.c := 0 (*global string*);
    x.rdo := TRUE; x.obj := NIL; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0;
    x.radr := TRUE; x.ptr := FALSE;
    IF ~stringFound(str, len, s) THEN NewSection(strings, s, "s", "");
      i := 0; WHILE len > 0 DO EmitByte(s, ORD(str[i])); INC(i); DEC(len) END;
      WHILE s.content.pc MOD WordSize # 0 DO EmitByte(s, 0) END
    END;
    x.a := s.no
  END stringPut;

  PROCEDURE stringPop(x: Item; VAR xs: ARRAY OF CHAR);
    VAR i: INTEGER; s!: Section;
  BEGIN s := GetSection(x.a); ASSERT(s.segment = "s");
    IF (x.obj = NIL) & (s.fixup = NIL) THEN (*string can be removed from table*)
      ASSERT(s = tail); DeleteLastSection
    END;
    i := 0; REPEAT xs[i] := CHR(s.content.code[s.org + i]); INC(i) UNTIL i = Length(x) (*copy string in dest*)
  END stringPop;

  PROCEDURE MakeStringItem*(VAR x: Item); (*copies string from OMSPS-buffer to OMSPG-string stored object*)
  BEGIN stringPut(x, S.str, S.slen)
  END MakeStringItem;

  PROCEDURE MakeConstObject*(VAR obj: B.Object); (*allocate space for a constant object in codata*)
    VAR s!: Section; i: INTEGER;
  BEGIN NewSection(mcode, s, "d", obj.name); obj.val := s.no;
    FOR i := 1 TO obj.type.size DO EmitByte(s, 0FFH) END
  END MakeConstObject;

  (* Code generation for Selectors, Variables, Constants *)

  PROCEDURE Field*(VAR x: Item; y: B.Object);   (* x := x.y *)
  BEGIN
    IF x.mode IN {B.Var, B.StoredConst} THEN IF x.c > 0 THEN INC(x.a, y.val) ELSE INC(x.b,  y.val) END
    ELSIF x.mode IN {RegI, Absol} THEN INC(x.a, y.val)
    ELSIF x.mode = B.Par THEN INC(x.b, y.val)
    ELSIF (x.mode = B.Const) & (y.type.form = B.Proc) THEN INC(x.a, y.val); x.mode := Absol
    ELSE S.Mark("not implemented"); S.DebugHex("x.mode", x.mode)
    END
  END Field;

  PROCEDURE Index*(VAR x, y: Item);   (* x := x[y] *)
    VAR s, lim: INTEGER; t!: Item; typ!: B.Type;
  BEGIN t := c0;
    IF x.type.form = B.String THEN s := 1; lim := x.b
    ELSE s := x.type.base.size; lim := x.type.len END;
    IF s = 0 THEN S.Mark("Invalid array item size")
    ELSE
      IF (y.mode = B.Const) & ((traps[1] = NIL) OR (lim >= 0)) THEN
        IF (y.a < 0) OR (lim >= 0) & (y.a >= lim) THEN S.Mark("bad index") END ;
        IF (x.mode IN {B.Var, B.StoredConst}) THEN IF x.c > 0 THEN INC(x.a, y.a*s) ELSE INC(x.b,  y.a*s) END
        ELSIF x.mode = RegI THEN INC(x.a, y.a*s)
        ELSIF x.mode = B.Par THEN INC(x.b, y.a*s)
        ELSE S.Mark("bad mode in index")
        END
      ELSE
        IF traps[1] # NIL THEN  (*check array bounds*)
          IF lim >= 0 THEN t.a := lim; PutDO(A.CMP, t, y)
          ELSE (*open array*) t := x; t.type := B.intType;
            IF x.mode IN {B.Var, B.Par} THEN t.mode := B.Var; INC(t.a, WordSize)
            ELSIF x.mode IN {Reg, RegI} THEN t.mode := Reg; INC(t.reg)
            ELSE S.Mark("error in Index")
            END; PutDO(A.CMP, t, y)
          END;
          Trap(A.C, 1) (*MSP430 inverts the carry with SUB and CMP instructions*)
        END;
        IF s # 1 THEN t := c0; t.a := s; PutDO(A.MUL, t, y) END;
        IF x.mode IN {B.Var, B.StoredConst} THEN
          load(y, 0FFH); y.type := B.intType; typ := x.type;
          IF x.c > 0 THEN t := sp; PutDO(A.ADD, t, y); (*TODO : tester*) INC(x.a, frame);
          ELSE Adr(x); x.ptr := FALSE
          END;
          free(x); x.reg := y.reg; x.mode := RegI; x.tmp := TRUE; x.type := typ
        ELSIF x.mode = B.Par THEN load(y, 0FFH); t.mode := B.Var;
          t.c := x.c; t.a := x.a; t.tmp := FALSE; t.obj := x.obj; t.type := B.intType; t.radr := FALSE; t.ptr := FALSE;
          PutDO(A.ADD, t, y); free(t);
          free(x); x.mode := RegI; x.reg := y.reg; x.a := x.b; x.tmp := TRUE
        ELSIF x.mode = RegI THEN t := x; t.mode := Reg; t.type := B.intType; PutDO( A.ADD, t, y); free(x);
           x.mode := RegI; x.reg := y.reg; x.tmp := TRUE
        ELSIF x.mode = Absol THEN ASSERT(y.mode = Reg);
          x.mode := RegI; x.reg := y.reg; x.tmp := TRUE;
        ELSE S.Mark("bad mode in index")
        END
      END
    END
  END Index;

  PROCEDURE DeRef*(VAR x: Item);
  BEGIN
    IF (x.mode IN {B.Var, B.StoredConst, B.Par, RegI}) THEN load(x, 0FFH); NilCheck(x.reg); x.mode := RegI; x.a := 0
    ELSIF x.mode = Reg THEN x.mode := RegI; x.a := 0
    ELSIF (x.mode = B.Const) & (x.type.form = B.Pointer) THEN x.mode := Absol
    ELSE S.Mark("bad mode in DeRef")
    END; x.b := 0
  END DeRef;

  PROCEDURE Q(T: B.Type; s: Section);
    VAR f!: Fixup; adr: INTEGER;
  BEGIN (*one entry of type descriptor extension table*)
    IF T.base # NIL THEN f := GetFixup(s, T.base.mno, T.base.len, 0);
      Q(T.base, s); adr := s.content.pc - s.org + 1; EmitWord(s, f.fixadr); f.fixadr := adr
    END
  END Q;

  PROCEDURE BuildTD*(T: B.Type);
    VAR k: INTEGER; s!: Section;
  BEGIN NewSection(mcode, s, "d", T.typobj.name); EmitWord(s, T.size);
    T.len := s.no; (*len used as section number*);
    k := T.nofpar;   (*extension level!*)
    IF k > 3 THEN S.Mark("ext level too large")
    ELSE Q(T, s);
      WHILE k < 3 DO EmitWord(s, -1); INC(k) END
    END ;
  END BuildTD;

  PROCEDURE TypeTest*(VAR x: Item; T: B.Type; varpar, isguard: BOOLEAN);
    VAR t!, pt!, tt!: Item;
  BEGIN
    IF TypeChecked() OR ~isguard THEN
      IF T = NIL THEN free(x); SetCC(x, A.AL)
      ELSE rh.reg := AllocR(); (*fetch tag into RH*)
        IF varpar THEN t := x;
          IF t.mode IN {B.Var, B.Par} THEN t.mode := B.Var; INC(t.a, WordSize)
          ELSIF t.mode IN {Reg, RegI} THEN t.mode := Reg; INC(t.reg)
          ELSE S.Mark("error in TypeTest")
          END; PutDO(A.MOV, t, rh); free(x);
          t := rh; t.mode := RegI; t.a := T.nofpar*2; pt := t; pt.mode := Reg; pt.rdo := FALSE; PutDO(A.MOV, t, pt);
          MakeTypTagAdr(tt, T); PutDO(A.CMP, tt, pt);
          freeR(pt.reg); free(tt);
          IF isguard THEN Trap(A.NE, 2) ELSE SetCC(x, A.EQ) END;
        ELSE S.Mark("pointer not allowed")
        END
      END
    END
  END TypeTest;

  PROCEDURE SetVector*(n: BYTE; VAR h: B.Object);
    VAR f!: Fixup; at: INTEGER;
  BEGIN at := + n*WordSize + 1;
    IF A.GetWordAt(vectors.content^, vectors.org + at - 1) # 0FFFFH THEN S.Mark("vect mult def")
    ELSE f := GetFixup(vectors, -h.lev, h.val, 0); A.PutWordAt(vectors.content^, vectors.org + at - 1, f.fixadr); f.fixadr := at
    END
  END SetVector;

  (* Code generation for Boolean operators *)

  PROCEDURE Not*(VAR x: Item);   (* x := ~x *)
    VAR t: INTEGER;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    x.c := A.negated(x.c); t := x.a; x.a := x.b; x.b := t
  END Not;

  PROCEDURE PutJFix(cond: BYTE; adr: INTEGER);
    VAR offset: INTEGER;
  BEGIN IF adr = 0 THEN offset := 0 ELSE offset := mcode.pc - adr END;
    A.PutJ(mcode, cond, offset)
  END PutJFix;

  PROCEDURE And1*(VAR x: Item);   (* x := x & *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    PutJFix(A.negated(x.c), x.a);
    x.a := mcode.pc-2; FixLink(x.b); x.b := 0
  END And1;

  PROCEDURE And2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := A.merged(mcode, y.a, x.a); x.b := y.b; x.c := y.c
  END And2;

  PROCEDURE Or1*(VAR x: Item);   (* x := x OR *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    PutJFix(x.c, x.b);
    x.b := mcode.pc-2; FixLink(x.a); x.a := 0
  END Or1;

  PROCEDURE Or2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := y.a; x.b := A.merged(mcode, y.b, x.b); x.c := y.c
  END Or2;

  (* Code generation for arithmetic operators *)

  PROCEDURE Neg*(VAR x: Item);   (* x := -x *)
    VAR t!: Item;
  BEGIN
    IF x.type.form = B.Int THEN
      IF x.mode = B.Const THEN x.a := -x.a
      ELSE PutSO(A.NEG, x)
      END
    ELSE (*form = Set*)
      IF x.mode = B.Const THEN x.a := -x.a-1
      ELSE t := cm1; PutDO(A.XOR, t, x)
      END
    END
  END Neg;

  PROCEDURE PrepCall*(VAR x: Item; VAR r, or: SET; VAR am: BOOLEAN);
  BEGIN (*x.type.form = OM4B.Proc*) (* xr := -1; *) am := AllocUp;
    r := RIU; IF x.mode IN {Reg, RegI} THEN EXCL(r, x.reg) END;
    or := x.type.ur*r; (*overwritten registers currently in use by the caller*)
    SaveRegs(or); RIU := RIU - or;
    IF (x.mode # B.StoredConst) & (x.mode > B.Par) THEN push(x, 2) END;
    IF x.obj.type.leaf THEN SetAllocationMode(Register) END;
    PRU := PRU + (x.type.ur - or)
  END PrepCall;

  PROCEDURE getParSize(typ: B.Type): INTEGER;
    VAR par!: B.Object; n, size: INTEGER;
  BEGIN par := typ.dsc; n := typ.nofpar; size := 0;
    WHILE n > 0 DO IF par.register = 0FFH THEN
        IF (par.type.form = B.Array) & (par.type.len < 0) OR (par.type.form = B.Record) THEN INC(size, 2*WordSize)
        ELSE INC(size, WordSize)
        END
      END;
      par := par.next; DEC(n)
    END

    RETURN size
  END getParSize;

  PROCEDURE Call*(VAR x: Item; r, or: SET; am: BOOLEAN);
    VAR rr!, t!: Item; s: INTEGER;
  BEGIN (*x.type.form = B.Proc*) s := getParSize(x.type);
    IF x.mode = B.StoredConst THEN
      IF x.c > 0 THEN x.c := 0 END; (*inner procedure are called the same way as global procedures*) 
      PutSO(A.CALL, x)
    ELSE IF x.mode > B.Par THEN x.mode := RegI; x.reg := A.SP; x.a := s; INC(s, WordSize) END;
      IF traps[5] # NIL THEN t := c0; PutDO(A.CMP, t, x); Trap(A.EQ, 5) END;
      PutSO(A.CALL, x); free(x)
    END;
    IF s # 0 THEN t := c0; t.a := s; rr := sp; PutDO(A.ADD, t, rr); DEC(frame, s) END;
    IF x.type.base.form = B.NoTyp THEN (*procedure*) RIU := VRS; SetAllocationMode(am)
    ELSE (*function*)
      x.tmp := TRUE; x.mode := Reg; x.radr := FALSE; x.ptr := FALSE; resultRegister(rr); x.reg := rr.reg; x.am := A.Register;
      RIU := r; SetAllocationMode(am);
      IF rr.reg IN RIU THEN x.tmp := FALSE; load(x, 0FFH) (*move result in a free register*)
      ELSE INCL(RIU, rr.reg)
      END
    END;
    RestoreRegs(or); RIU := RIU + or
  END Call;

  PROCEDURE AddOp*(op: INTEGER; VAR x, y: Item);   (* x := x +- y *)
    VAR tmp: BOOLEAN;
  BEGIN
    IF op = S.plus THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a + y.a
      ELSIF y.mode = B.Const THEN
        IF y.a # 0 THEN PutDO(A.ADD, y, x) END
      ELSIF (x.mode = B.Const) & (x.a = 0) THEN tmp := convertSize(y, x.type); x := y; 
      ELSE PutDO(A.ADD, y, x); free(y)
      END
    ELSE (*op = S.minus*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a - y.a
      ELSIF y.mode = B.Const THEN
        IF y.a # 0 THEN PutDO(A.SUB, y, x) END
      ELSE PutDO(A.SUB, y, x); free(y)
      END
    END
  END AddOp;

  PROCEDURE MulOp*(VAR x, y: Item);   (* x := x * y *)
    VAR p!, x0!, y0!: Item; r, or: SET; pau: BOOLEAN;
  BEGIN
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a * y.a
    ELSIF (y.mode = B.Const) (* & (y.a >= 2) *)THEN load(x, 0FFH); PutDO(A.MUL, y, x) (*TODO tester*)
    ELSIF (x.mode = B.Const) (* & (x.a >= 2) *)THEN load(y, 0FFH); PutDO(A.MUL, x, y); (*TODO tester*)
      x.mode := Reg; x.reg := y.reg; x.am := A.Register; x.ofs := 0; x.tmp := TRUE
    ELSE
      IF arith[0] = NIL THEN S.Mark("import Arith.mul16 function")
      ELSE MakeItem(p, arith[0], 0); x0 := x; y0 := y; PrepCall(p, r, or, pau); load(x, 5); load(y, 6); Call(p, r, or, pau);
        free(x0); free(y0); x.reg := p.reg
      END
    END
  END MulOp;

  PROCEDURE DivOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
    VAR t!, p!, x0!, y0!: Item; r, or: SET; pau: BOOLEAN; e: INTEGER;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF op = S.div THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a DIV y.a ELSE S.Mark("bad divisor") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) & (A.log2(y.a, e) = 1) THEN load(x, 0FFH); PutDO(A.DIv, y, x); (*TODO tester*)
        x.mode := Reg; x.am := A.Register; x.ofs := 0
      ELSE IF arith[1] = NIL THEN S.Mark("import Arith.divmod16 procedure")
        ELSE IF traps[6] # NIL THEN t := c0; PutDO(A.CMP, t, y); Trap(A.NE, 6); free(y) END;
          MakeItem(p, arith[1], 0); x0 := x; y0 := y; PrepCall(p, r, or, pau); load(x, 5); load(y, 6); t := c0; load(t, 7); Call(p, r, or, pau);
          free(x0); free(y0); x.reg := p.reg
        END
      END
    ELSE (*op = OM4S.mod*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a MOD y.a ELSE S.Mark("bad modulus") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) & (A.log2(y.a, e) = 1) THEN load(x, 0FFH); PutDO(A.MOd, y, x); (*TODO tester*)
        x.mode := Reg; x.am := A.Register; x.ofs := 0
      ELSE IF arith[1] = NIL THEN S.Mark("import Arith.divmod procedure")
        ELSE IF traps[6] # NIL THEN t := c0; PutDO(A.CMP, t, y); Trap(A.NE, 6); free(y) END;
            MakeItem(p, arith[1], 0); x0 := x; y0 := y; PrepCall(p, r, or, pau); load(x, 5); load(y, 6); t := c1; load(t, 7); Call(p, r, or, pau); x.reg := p.reg;
          free(x0); free(y0); x.reg := p.reg
        END
      END
    END
  END DivOp;

  PROCEDURE fix(at, with: INTEGER);
  BEGIN A.fix(mcode, at, with)
  END fix;

  (* Code generation for shift operations *)
  PROCEDURE shift(op: INTEGER; VAR x, y: Item); (* x := op(x, y)*)
    VAR i, pb, pf: INTEGER; t! : Item;
  BEGIN
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := LSL(x.a, y.a)
    ELSIF (y.mode = B.Const) & (y.a <= 4) THEN PutSO(A.NOP0, x); FOR i := 1 TO y.a DO PutSO(op, x) END
    ELSE PutSO(A.NOP0, x); t := c1; PutDO(A.ADD, t, y);
      pb := mcode.pc; PutDO(A.SUB, t, y); pf := mcode.pc; PutJ(A.EQ, 0);
      PutSO(op, x); PutJ(A.AL, pb - mcode.pc - 2); fix(pf, mcode.pc - pf - 2);
      free(y)
    END
  END shift;

  PROCEDURE Rla*(VAR x, y: Item); (* x := RLA(x, y)*)
  BEGIN shift(A.RLA, x, y)
  END Rla;

  PROCEDURE Rra*(VAR x, y: Item); (* x := RRA(x, y)*)
  BEGIN shift(A.RRA, x, y)
  END Rra;

  (* Code generation for sring operators *)
  PROCEDURE StringOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
    VAR xs, ys: ARRAY S.stringBufSize OF CHAR; ix, iy: INTEGER;
  BEGIN
    IF op # S.plus THEN S.Mark("op + expected") END;
    IF (x.mode = B.StoredConst) & (y.mode = B.StoredConst) THEN
      IF y.type.form = B.String THEN stringPop(y, ys) ELSE ys[0] := CHR(y.a); ys[1] := 0X END; stringPop(x, xs);
      ix := 0; WHILE xs[ix] # 0X DO INC(ix) END;
      iy := -1; REPEAT INC(iy); xs[ix] := ys[iy]; INC(ix) UNTIL ys[iy] = 0X; (* xs = xs + ys *)
      stringPut(x, xs, ix)
    ELSE S.Mark("const expected")
    END
  END StringOp;

  (* Code generation for set operators *)

  PROCEDURE Singleton*(VAR x: Item);  (* x := {x} *)
    VAR y!: Item;
  BEGIN y := x; x.mode := B.Const; x.a := 1; Rla(x, y)
  END Singleton;

  PROCEDURE Set*(VAR x, y: Item); (* x := {x .. y} *)
    VAR p!, x0!, y0!: Item; r, or: SET; pau: BOOLEAN;
  BEGIN
    IF (x.mode = B.Const) & ( y.mode = B.Const) THEN
      IF x.a <= y.a THEN x.a := ORD({x.a .. y.a}) ELSE x.a := 0 END
    ELSE IF arith[2] = NIL THEN S.Mark("import Arith.set function")
      ELSE  MakeItem(p, arith[2], 0); x0 := x; y0 := y; PrepCall(p, r, or, pau); load(x, 5); load(y, 6); Call(p, r, or, pau);
        free(x0); free(y0); x.reg := p.reg
      END
    END
  END Set;

  PROCEDURE In*(VAR x, y: Item);  (* x := x IN y *)
    VAR t!: Item; pc0, pc1: INTEGER;
  BEGIN
    IF x.mode = B.Const THEN  t := c0; t.a := LSL(1, x.a); PutDO(A.BIT, t, y);
      free(x)
    ELSE load(x, 0FFH); load(y, 0FFH); t := c1; PutDO(A.ADD, t, x);
      pc0 := mcode.pc; PutDO(A.SUB, t, x); pc1 := mcode.pc; PutJ(A.EQ, 0);
      PutSO(A.RRC, y); PutJ(A.AL, pc0 - mcode.pc -2); fix(pc1, mcode.pc - pc1 - 2);
      PutDO(A.BIT, t, y); free(y); free(x)
    END;
    SetCC(x, A.NE)
  END In;

  PROCEDURE SetOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
    VAR xset, yset: SET; (*x.type.form = Set*)
  BEGIN
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN
      xset := SYSTEM.VAL(SET, x.a); yset := SYSTEM.VAL(SET, y.a);
      IF op = S.plus THEN xset := xset + yset
      ELSIF op = S.minus THEN xset := xset - yset
      ELSIF op = S.times THEN xset := xset * yset
      ELSIF op = S.rdiv THEN xset := xset / yset
      END ;
      x.a := SYSTEM.VAL(INTEGER, xset)
    ELSE load(x, 0FFH);
      IF op = S.plus THEN PutDO(A.BIS, y, x)
      ELSIF op = S.minus THEN PutDO(A.BIC, y, x)
      ELSIF op = S.times THEN PutDO(A.AND, y, x)
      ELSIF op = S.rdiv THEN PutDO(A.XOR, y, x)
      END;
      free(y)
    END
  END SetOp;

  (* Code generation for relations *)

  PROCEDURE AdjustSize(VAR x: Item);
    VAR st!: B.Type;
  BEGIN IF x.type.form = B.Int THEN st := B.byteType ELSIF x.type.form = B.Set THEN st := B.byteSetType ELSE st := NIL END;
    IF (st # NIL) & (x.mode = B.Const) & (x.a >= 0) & (x.a < 100H) THEN x.type := st END
  END AdjustSize;

  PROCEDURE IntCompare*(VAR x, y, z: Item);   (* x < y *)
  BEGIN
    IF (x.mode = Cond) OR (y.mode = Cond) THEN S.Mark("not implemented") END;
    PutDO(A.CMP, y, x); free(y); free(x);
    SetCC(x, z.a)
  END IntCompare;

  PROCEDURE IntRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
  BEGIN
    IF (x.mode = Cond) OR (y.mode = Cond) THEN S.Mark("not implemented") END;
    IF (y.mode = B.Const) & (y.a = 0) &
      (flagsObj # NIL) & (flagsObj = x.obj) & (op < S.gtr) THEN
      IF x.type.size = 1 THEN SetCC(x, urelmap[op - S.eql]) ELSE SetCC(x, relmap[op - S.eql]) END
    ELSE
      AdjustSize(x); AdjustSize(y);
      IF x.type.size # y.type.size THEN
        IF x.type.size = 1 THEN IF x.mode # B.Const THEN load(x, 0FFH) END; x.type := B.intType
        ELSE IF y.mode # B.Const THEN load(y, 0FFH) END; y.type := B.intType
        END (*convert to word*)
      END;
      IF op < S.gtr THEN PutDO(A.CMP, y, x); IF x.type.size = 1 THEN SetCC(x, urelmap[op - S.eql]) ELSE SetCC(x, relmap[op - S.eql]) END
      ELSE PutDO(A.CMP, x, y); IF x.type.size = 1 THEN SetCC(x, urelmap[op - S.gtr + 2]) ELSE SetCC(x, relmap[op - S.gtr + 2]) END
      END
    END;
    free(y); free(x)
  END IntRelation;

  PROCEDURE StringRelation*(op: INTEGER; VAR x0, y0: Item);   (* x := x < y *)
    (*x, y are char arrays or strings*)
    VAR pc0, tbf0: INTEGER; x!, y!: Item;
  BEGIN
    IF x0.type.form = B.String THEN loadAdr(x0, 0FFH) ELSE loadAdr(x0, 0FFH) END;
    IF y0.type.form = B.String THEN loadAdr(y0, 0FFH) ELSE loadAdr(y0, 0FFH) END;
    IF op < S.gtr THEN x := x0; y := y0 ELSE x := y0; y := x0 END;
    (*Compare:*) pc0 := mcode.pc;
    x.am := A.IndirectIncr; rh.reg := AllocR(); A.PutDO(mcode, A.MOV, x, rh, A.Byte);
    y.am := A.IndirectIncr; A.PutDO(mcode, A.CMP, y, rh, A.Byte);
    tbf0 := mcode.pc; PutJ(A.NE, 0) (*JNE Fin*);
    A.PutDO(mcode, A.CMP, c0, rh, A.Byte); (*compare char x^ to 0*)
    PutJ(A.NE, pc0 - mcode.pc - 2) (*JNE Compare*);
    (* Fin: *) fix(tbf0, mcode.pc - tbf0 - 2); free(y0); free(x0); freeR(rh.reg);
    IF op < S.gtr THEN SetCC(x0, urelmap[op - S.eql]) ELSE SetCC(x0, urelmap[op - S.gtr + 2]) END
  END StringRelation;

  (* Code generation of Assignments *)

  PROCEDURE StrToChar*(VAR x: Item);
    VAR sc: ARRAY 2 OF CHAR;
  BEGIN ASSERT((x.type.form = B.String) & (Length(x) = 2));
    stringPop(x, sc); x.type := B.charType; x.a := ORD(sc[0]);
    x.mode := B.Const; x.radr := FALSE; x.ptr := FALSE
  END StrToChar;

  PROCEDURE StoreConstInt(adr, size, val: INTEGER);
    VAR i: INTEGER;
  BEGIN
    FOR i := 1 TO size DO IF mcode.code[adr] # 0FFH THEN S.Mark("already set") END;
      mcode.code[adr] := val MOD 100H; val := val DIV 100H; INC(adr)
    END
  END StoreConstInt;

  PROCEDURE Store*(VAR x, y: Item); (* x := y *)
    VAR adr, val: INTEGER; s!: Section;
   BEGIN
    IF x.mode = B.StoredConst THEN ASSERT(x.c = 0);
      s := GetSection(x.a); adr := x.b + 1; val := UpdateChain(s, adr, y.a, y);
      IF y.mode = B.Const THEN
        IF y.type.form IN {B.Bool, B.Int, B.Set, B.Pointer, B.NilTyp} THEN StoreConstInt(s.org + x.b, x.type.size, val)
        ELSE (* TODO*) S.Mark("not implemented"); S.DebugHex("form", y.type.form);
        END
      ELSIF y.mode = Absol THEN StoreConstInt(adr, x.type.size, val)
      ELSE S.Mark("not allowed is Store"); S.DebugHex("mode", y.mode);
      END
    ELSE PutDO(A.MOV, y, x); free(y); free(x)
    END
  END Store;

  PROCEDURE distance(x, y: Item; VAR d: INTEGER): BOOLEAN;
    VAR res: BOOLEAN; ox, oy: INTEGER;
  BEGIN res := TRUE;
    IF (x.obj # NIL) & (x.obj = y.obj) & (x.mode = y.mode) & ((x.mode # RegI) OR (x.reg = y.reg)) THEN
      IF x.mode = B.Par THEN ox := x.b ELSE ox := x.a END;
      IF y.mode = B.Par THEN oy := y.b ELSE oy := y.a END;
      d := ox - oy
    ELSIF (x.mode = B.Var) & (y.mode = B.Var) & (x.obj.lev > 0) & (x.obj.lev = y.obj.lev) THEN d := x.a - y.a
(* TODO   ELSIF (x.mode = B.Const) & (y.mode = B.Const) & (x.c = 0) & x.radr & y.radr THEN d := x.a - y.a*)
    ELSE res := FALSE
    END

    RETURN res
  END distance;

  PROCEDURE StoreStruct*(VAR x, y: Item); (* x := y *)
    VAR s, pc0, pc1, d: INTEGER; t!, ti!: Item; oneReg: BOOLEAN; xtyp!, ytyp!: B.Type;
  BEGIN IF x.mode = B.StoredConst THEN S.Mark("not implemented in StoreStruct") END;
    t := c0; ti := y;
    pc0 := -1; xtyp := x.type; ytyp := y.type;
    oneReg := distance(x, y, d);
    IF ((ytyp.size < 8) OR oneReg & (ytyp.size < 10)) & (y.mode IN {B.Var, B.StoredConst}) THEN
      s := ytyp.size; x.rdo := FALSE; y.rdo := FALSE;
      WHILE s > 0 DO PutDO(A.MOV, y, x);
        IF x.c >= 0 THEN INC(x.a, 2) ELSE INC(x.b, 2) END;
        IF y.c >= 0 THEN INC(y.a, 2) ELSE INC(y.b, 2) END;
        DEC(s, 2)
      END
    ELSE
      loadAdr(y, 0FFH); IF oneReg THEN free(x); x.reg := y.reg; x.tmp := FALSE; DEC(d, WordSize) ELSE loadAdr(x, 0FFH); d := 0 END; rh.reg := AllocR();
      IF (xtyp.form = B.Array) &  (xtyp.len > 0) THEN
        IF ytyp.len >= 0 THEN
          IF xtyp.size = ytyp.size THEN t.a := (ytyp.size+1) DIV 2; PutDO(A.MOV, t, rh)
          ELSE S.Mark("different length/size, not implemented")
          END
        ELSE (*y  open array*) ti.a := y.a+WordSize; PutDO(A.MOV, ti, rh); s := ytyp.base.size;  (*element size*)
          t := c0; PutDO(A.CMP, t, rh); pc0 := mcode.pc; PutJ(A.EQ, 0); (*JEQ L0*)
          IF s = 1 THEN t := c1; PutDO(A.ADD, t, rh); PutSO(A.RRA, rh)
          ELSIF s # 2 THEN ASSERT(~ODD(s)); t.a := s DIV 2; PutDO(A.MUL, t, rh) (*TODO tester*)
          END;
          IF traps[3] # NIL THEN t.a := (xtyp.size+1) DIV 2+1; PutDO(A.CMP, t, rh); Trap(A.GE, 3) END
        END
      ELSIF xtyp.form = B.Record THEN t.a := xtyp.size DIV 2; PutDO(A.MOV, t, rh)
      ELSE S.Mark("inadmissible assignment")
      END;
      (*L1*) pc1 := mcode.pc; x.am := A.Indexed; x.ofs := d; y.am := A.IndirectIncr;
      A.PutDO(mcode, A.MOV, y, x, A.Word); IF ~oneReg THEN t := c2; PutDO(A.ADD, t, x) END;
      t := c1; PutDO(A.SUB, t, rh); PutJ(A.NE, pc1 - mcode.pc -2); (*BNE L1*)
      (*L0:*) IF pc0 # -1 THEN fix(pc0, mcode.pc - pc0 - 2) END;
      freeR(rh.reg); free(y); free(x)
    END
  END StoreStruct;

  PROCEDURE CopyString*(VAR x, y: Item);  (* x := y *)
    VAR len, pc0, i, dadr, sadr: INTEGER; t!,ti!: Item; ys: ARRAY S.stringBufSize OF CHAR;
      s!: Section;
  BEGIN len := x.type.len; 
    IF x.mode = B.StoredConst THEN ASSERT(x.c = 0);
      IF (y.mode = B.StoredConst) & (y.type.form = B.String) THEN
        IF len < Length(y) THEN S.Mark("string too long")
        ELSE s := GetSection(x.a); dadr := s.org + x.b; sadr := 0; stringPop(y, ys);
          FOR i := 1 TO Length(y) DO IF mcode.code[dadr] # 0FFH THEN S.Mark("already set") END;
            mcode.code[dadr] := ORD(ys[sadr]); INC(dadr); INC(sadr)
          END;
          WHILE dadr MOD WordSize # 0 DO mcode.code[dadr] := 0; INC(dadr) END
        END
      ELSE S.Mark("not allowed")
      END
    ELSE t := c0; ti := y;
      loadAdr(x, 0FFH);
      IF len >= 0 THEN IF len < Length(y) THEN S.Mark("string too long") END
      ELSIF traps[3] # NIL THEN ti.a := x.a+WordSize; PutDO(A.MOV, ti, rh); (*open array len*)
        t.a := Length(y); PutDO(A.CMP, t, rh); Trap(A.L, 3)
      END ;
      loadAdr(y, 0FFH);
      (*L0:*) pc0 := mcode.pc; x.am := A.Indexed; x.ofs := 0; y.am := A.IndirectIncr;
      A.PutDO(mcode, A.MOV, y, x, A.Word); t := c2; PutDO(A.ADD, t, x); (*TODO tester*)
      y.mode := RegI; y.a := -1; y.type := B.byteType; t := c0; PutDO(A.CMP, t, y) (*test.byte 0*); (*TODO tester*)
      PutJ(A.NE, pc0 - mcode.pc -2); (*BNE L0*)
      free(y); free(x)
    END
  END CopyString;

  (* Code generation for parameters *)

  PROCEDURE OpenArrayParam*(VAR x: Item; par: B.Object);
    VAR t!, ti!: Item;
  BEGIN t := c0; t.ofs := x.type.len; ti := c0; ti.am := A.Indexed;
    IF par.register # 0FFH THEN (*in registers*) loadAdr(x, par.register); rh.reg := AllocRP(par.register+1);
      IF t.ofs >= 0 THEN A.PutDO(mcode, A.MOV, t, rh, A.Word)
      ELSE ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
      END
    ELSE (*in stack*) INC(frame, WordSize);
      IF t.ofs >= 0 THEN A.PutSO(mcode, A.PUSH, t, A.Word)
      ELSE ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutSO(mcode, A.PUSH, ti, A.Word)
      END;
      pushAdr(x)
    END
  END OpenArrayParam;

  PROCEDURE VarParam*(VAR x: Item; par: B.Object);
    VAR xmd: INTEGER; t!, ti!: Item; xtyp!: B.Type;
  BEGIN t := c0; xtyp := x.type; t.ofs := xtyp.len;
    ti := c0; ti.am := A.Indexed; xmd := x.mode;
    IF par.register # 0FFH THEN
      loadAdr(x, par.register);
      IF (par.type.form = B.Array) & (par.type.len < 0) THEN rh.reg := AllocRP(par.register+1); (*open array*)
        IF t.ofs >= 0 THEN A.PutDO(mcode, A.MOV, t, rh, A.Word)
        ELSE ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
        END
      ELSIF par.type.form = B.Record THEN
        IF xmd = B.Par THEN rh.reg := AllocRP(par.register+1); ti.reg := A.SP; ti.ofs := x.a+WordSize+frame;
          A.PutDO(mcode, A.MOV, ti, rh, A.Word)
        ELSE xmd := loadTypTagAdr(xtyp, par.register+1)
        END
      END
    ELSE (*in stack*)
      IF (par.type.form = B.Array) & (par.type.len < 0) THEN (*open array*) rh.reg := AllocR();
        INC(frame, WordSize);
        IF t.ofs >= 0 THEN A.PutSO(mcode, A.PUSH, t, A.Word)
        ELSE ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutSO(mcode, A.PUSH, ti, A.Word)
        END
      ELSIF (par.type.form = B.Record) THEN
        IF xmd = B.Par THEN INC(frame, WordSize);
          rh.reg := AllocR(); ti.reg := A.SP; ti.ofs := x.a+WordSize+frame;
          A.PutSO(mcode, A.PUSH, ti, A.Word)
        ELSE pushTypTagAdr(xtyp)
        END
       END;
      pushAdr(x)
    END
  END VarParam;

  PROCEDURE ValueParam*(VAR x: Item; par: B.Object);
  BEGIN IF par.register # 0FFH THEN load(x, par.register) ELSE push(x, par.type.size) END
  END ValueParam;

  PROCEDURE StringParam*(VAR x: Item; par: B.Object);
    VAR t!: Item;
  BEGIN t := c0; t.ofs := Length(x);
    IF par.register # 0FFH THEN loadAdr(x, par.register);
      rh.reg := AllocRP(par.register+1); A.PutDO(mcode, A.MOV, t, rh, A.Word) (*len*)
    ELSE INC(frame, WordSize); A.PutSO(mcode, A.PUSH, t, A.Word) (*len*);
      pushAdr(x)
    END
  END StringParam;

  (*For Statements*)

  PROCEDURE For0*(VAR x, y: Item);
  BEGIN Store(x, y)
  END For0;

  PROCEDURE For1*(VAR x, y, z, w: Item; VAR L: INTEGER);
  BEGIN
    IF w.a > 0 THEN PutDO(A.CMP, x, z)
    ELSIF w.a < 0 THEN PutDO(A.CMP, z, x)
    ELSE S.Mark("zero increment")
    END;
    L := mcode.pc; PutJFix(A.L, 0); free(z)
  END For1;

  PROCEDURE For2*(VAR x, y, w: Item);
  BEGIN free(x); MakeItem(x, x.obj, x.obj.lev); (* discard effects of previous loading if any *)
    x.rdo := FALSE; PutDO(A.ADD, w, x);
  END For2;

  (* Branches, procedure calls, procedure prolog and epilog *)

  PROCEDURE Here*(): INTEGER;
  BEGIN flagsObj := NIL (*this location will likely be referenced*)
  RETURN mcode.pc
  END Here;

  PROCEDURE FJump*(VAR L: INTEGER);
  BEGIN PutJFix(A.AL, L); L := mcode.pc - 2
  END FJump;

  PROCEDURE CFJump*(VAR x: Item);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    IF x.c # A.AL THEN PutJFix(A.negated(x.c), x.a); x.a := mcode.pc - 2 END;
    FixLink(x.b)
  END CFJump;

  PROCEDURE BJump*(L: INTEGER);
  BEGIN PutJ(A.AL, L - mcode.pc - 2)
  END BJump;

  PROCEDURE CBJump*(VAR x: Item; L: INTEGER);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    IF x.c # A.AL THEN PutJ(A.negated(x.c), L - mcode.pc - 2) END;
    FixLink(x.b); FixLinkWith(x.a, L)
  END CBJump;

  PROCEDURE fixup*(VAR x: Item);
  BEGIN FixLink(x.a)
  END fixup;

  PROCEDURE Enter*(size: INTEGER; int: BOOLEAN; savedregs: SET);
    VAR t!, tsp!: Item;
  BEGIN
    frame := 0;

    IF size >= ORD({16}) THEN S.Mark("local variables size exeeded") END;
    IF size # 0 THEN t := c0; t.a := size; tsp := sp; PutDO(A.SUB, t, tsp); INC(frame, size) END;

    SaveRegs(savedregs); (*save registers before use*)
    VRS := RIU; vframe := frame
  END Enter;

  PROCEDURE Return*(form: INTEGER; VAR x: Item; size: INTEGER; int: BOOLEAN; savedregs: SET);
    VAR t!, rr!: Item;
  BEGIN t := c0;
    IF form # B.NoTyp THEN resultRegister(rr); IF rr.reg IN RIU THEN freeR(rr.reg) END;
      load(x, rr.reg); IF x.reg IN RIU THEN free(x) END
    END;

    RestoreRegs(savedregs); PRU := PRU - savedregs;
    IF size # 0 THEN t.ofs := size; A.PutDO(mcode, A.ADD, t, sp, A.Word); DEC(frame, size) END;
    IF int THEN A.PutNO(mcode, A.RETI);
      IF PRU # {} THEN S.Mark("destroyed regs in handler") END
    ELSE A.PutNO(mcode, A.RET)
    END;
    SetAllocationMode(Stack); RIU := {}; VRS := RIU
  END Return;

  (* In-line code procedures*)

  PROCEDURE Increment*(upordown: INTEGER; VAR x, y: Item);
    VAR op: BYTE;
  BEGIN
    IF upordown = 0 THEN op := A.ADD ELSE op := A.SUB END;
    IF y.type.form = B.NoTyp THEN y := c1 END;
    PutDO(op, y, x);
    free(y); free(x)
  END Increment;

  PROCEDURE Include*(inorex: INTEGER; VAR x, y: Item);
    VAR op: BYTE; z!, t!: Item;
  BEGIN IF inorex = 0 THEN op := A.BIS ELSE op := A.BIC END;
    IF y.mode = B.Const THEN t := c0; t.a := LSL(1, y.a); PutDO(op, t, x)
    ELSE z := c1; load(z, 0FFH); Rla(z, y); PutDO(op, z, x); free(z)
    END
  END Include;

  PROCEDURE Assert*(VAR x: Item);
    VAR cond, pc0: INTEGER;
  BEGIN
    IF traps[7] # NIL
    THEN
      pc0 := 0;
      IF x.mode # Cond THEN loadCond(x) END;
      IF x.a = 0 THEN cond := A.negated(x.c);
      ELSE pc0 := mcode.pc; PutJFix(x.c, 0); FixLink(x.a); cond := A.AL
      END;
      Trap(cond, 7); FixLink(x.b);
      IF pc0 # 0 THEN A.fix(mcode, pc0, mcode.pc - pc0 - 2) END
    END
  END Assert;

  PROCEDURE Copy*(VAR x, y, z: Item); (*y := x*)
    VAR pc0, pc1, d: INTEGER; t!: Item; oneReg: BOOLEAN;
  BEGIN pc0 := 0;
    IF z.mode = B.Const THEN
      IF z.a > 0 THEN load(z, 0FFH) ELSE S.Mark("bad count") END
    ELSE load(z, 0FFH);
      IF traps[3] # NIL THEN t := c0; PutDO(A.CMP, t, z); Trap(A.L, 3) END;
      pc0 := mcode.pc; PutJ( A.EQ, 0); (*JEQ L0*)
    END;
    oneReg := distance(y, x, d);
    load(x, 0FFH);
    IF oneReg THEN free(y); y.reg := x.reg; y.tmp := FALSE; DEC(d, WordSize);
    ELSE load(y, 0FFH); d := 0 END;
    pc1 := mcode.pc; x.a := 0; x.am := A.IndirectIncr; y.am := A.Indexed; y.ofs := d;
    A.PutDO(mcode, A.MOV, x, y, A.Word);
    y.am := A.Register; IF ~oneReg THEN t := c2; A.PutDO(mcode, A.ADD, t, y, A.Word) END;
    t := c1; A.PutDO(mcode, A.SUB, t, z, A.Word); PutJ(A.NE, pc1 - mcode.pc - 2); (*BNE L1*)
    IF pc0 # 0 THEN A.fix(mcode, pc0, mcode.pc - pc0 - 2) END; free(z); free(y); free(x)
  END Copy;

  PROCEDURE LogicalSR*(fct: INTEGER; VAR x: Item);
    VAR op: BYTE; t!: Item;
  BEGIN
    IF fct = 0 THEN op := A.BIC ELSE op := A.BIS END;
    t := sr; PutDO(op, x, t); free(x)
  END LogicalSR;

  PROCEDURE LogicalSROnExit*(fct: INTEGER; VAR x: Item);
    VAR op: BYTE; t!: Item;
  BEGIN
    IF fct = 0 THEN op := A.BIC ELSE op := A.BIS END;
    t := c0; t.mode := B.Var; t.c := 1; t.rdo := FALSE; PutDO(op, x, t); free(x); free(t)
  END LogicalSROnExit;

  (*In-line code functions*)

  PROCEDURE Abs*(VAR x: Item);
    VAR pc: INTEGER; t!: Item;
  BEGIN
    IF x.mode = B.Const THEN x.a := ABS(x.a)
    ELSE t := c0; PutDO(A.CMP, t, x); pc := mcode.pc; PutJ(A.GE, 0);
      PutSO(A.NEG, x); A.fix(mcode, pc, mcode.pc - pc - 2)
    END
  END Abs;

  PROCEDURE Odd*(VAR x: Item);
    VAR t!: Item;
  BEGIN t := c1; PutDO(A.BIT, t, x); SetCC(x, A.NE); free(x)
  END Odd;

  PROCEDURE Ord*(VAR x: Item);
  BEGIN IF x.mode = Cond THEN load(x, 0FFH) END
  END Ord;

  PROCEDURE Len*(VAR x: Item);
  BEGIN
    IF x.type.form = B.String THEN free(x); x.mode := B.Const; x.a := Length(x); x.type := B.intType
    ELSIF x.type.len >= 0 THEN free(x); x.mode := B.Const; x.a := x.type.len; x.type := B.intType
    ELSE (*open array*)
      IF x.mode IN {B.Var, B.Par} THEN x.mode := B.Var; INC(x.a, WordSize)
      ELSIF x.mode IN {Reg, RegI} THEN x.mode := Reg; INC(x.reg)
      ELSE S.Mark("bad mode in Len")
      END
    END
  END Len;

  PROCEDURE ClrC*;
  BEGIN A.PutNO(mcode, A.CLRC)
  END ClrC;

  PROCEDURE Nop*;
    VAR a!, b!: Item;
  BEGIN a := c0; b := cg2; PutDO(A.MOV, a, b)
  END Nop;

  PROCEDURE Swpb*(VAR x:Item);
  BEGIN PutSO(A.SWPB, x)
  END Swpb;

  PROCEDURE Shift*(fct: INTEGER; VAR x, y: Item); (*x := x op y*)
  BEGIN IF (x.mode = B.Const) & (y.mode = B.Const) THEN
      IF fct = 0 THEN x.a := LSL(x.a, y.a) ELSIF fct = 2 THEN x.a := ASR(x.a, y.a) END
    ELSE IF fct = 0 THEN Rla(x, y) ELSIF fct = 2 THEN Rra(x, y) END
    END
  END Shift;

  PROCEDURE Rotate*(fct: INTEGER; VAR x: Item);
  BEGIN IF fct = 0 THEN PutSO(A.RLC, x) ELSIF fct = 2 THEN PutSO(A.RRC, x) END
  END Rotate;

  PROCEDURE Logical*(fct: INTEGER; VAR x, y: Item);
    VAR op: BYTE;
  BEGIN
    IF fct = 0 THEN op := A.BIC ELSIF fct = 1 THEN op := A.BIS ELSIF fct = 2 THEN op := A.XOR ELSE op := A.AND END;
    PutDO(op, y, x); free(y); free(x)
  END Logical;

  PROCEDURE ADC*(VAR x, y: Item);
  BEGIN PutDO(A.ADDC, y, x); free(y); free(x)
  END ADC;

  PROCEDURE SBC*(VAR x, y: Item);
  BEGIN PutDO(A.SUBC, y, x); free(y); free(x)
  END SBC;

  PROCEDURE Bit*(VAR x, y: Item);
  BEGIN PutDO(A.BIT, y, x); free(y); free(x);
    SetCC(x, A.NE)
  END Bit;

  PROCEDURE Condition*(VAR x: Item);
  BEGIN (*x.mode = Const*) SetCC(x, x.a)
  END Condition;

  PROCEDURE Val*(VAR x: Item; t: B.Type);
  BEGIN (*if x is integer constant, set x.c to 1 indication that address is known at compile time*)
    IF (t.form = B.Proc) THEN
      IF (x.mode = B.Const) & (x.type.form IN {B.Int, B.Pointer}) THEN x.c := 1 ELSE S.Mark("not allowed") END
    END
  END Val;

  PROCEDURE Open*;
    VAR i: INTEGER;
  BEGIN A.Init(mcode); A.Init(strings); varsize := 0;
    curImport := 0;
    FOR i := 0 TO LEN(traps) - 1 DO traps[i] := NIL END;
    FOR i := 0 TO LEN(arith) - 1 DO arith[i] := NIL END;
    (*one dummy vector is added to targer fixup NIL outside the table*)
    vectors.size := 0; FOR i := 1 TO 32 DO EmitWord(vectors, 0FFFFH); END; vectors.fixup := NIL;
    (*initialise segments*)
    head := NIL; tail := NIL; body := NIL; ccs := NIL;nofsec := 0;
    RIU := {};
    rh.reg := 15; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL; rh.mode := Reg; rh.type := B.intType;
    SetAllocationMode(Stack)
  END Open;

  PROCEDURE Header*;
  BEGIN NewSection(mcode, body, "c", "module body"); (*create the module initialization section*)
    frame := 0; vframe := 0; SetAllocationMode(Stack)
  END Header;

  PROCEDURE WriteWord(VAR R: Files.Rider; w: INTEGER);
  BEGIN Files.WriteByte(R, w MOD 100H); Files.WriteByte(R, w DIV 100H MOD 100H)
  END WriteWord;

  PROCEDURE WriteSection(VAR R: Files.Rider; s: Section);
    VAR i: INTEGER; f!: Fixup;
  BEGIN ASSERT(s.size < 10000H);
    Files.Write(R, s.segment); Files.WriteString(R, s.name); WriteWord(R, s.size);
    IF s.segment # "r" THEN
      FOR i := 0 TO s.size - 1 DO (*write content*) Files.WriteByte(R, s.content.code[s.org + i]) END
    END;
    f := s.fixup;
    WHILE f # NIL DO WriteWord(R, f.fixadr);
      Files.WriteByte(R, f.mno); WriteWord(R, f.sno); WriteWord(R, f.offset);
      f := f.next
    END;
    WriteWord(R, 0)
  END WriteSection;

  PROCEDURE Close*(VAR modid: S.Ident; key, nofent: INTEGER; codeseg: BYTE);
    VAR obj!: B.Object; s!: Section;
      i, j, nofimps: INTEGER;
      name: S.Ident;
      F!: Files.File; R!: Files.Rider;
  BEGIN  (*exit code*) A.PutNO(mcode, A.RET); body.size := mcode.pc - body.org; 
    obj := B.topScope.next; nofimps := 0;
    WHILE obj # NIL DO
      IF (obj.class = B.Mod) & (obj.dsc # B.system) THEN INC(nofimps); (*count imports*)
      END;
      obj := obj.next
    END;

    B.MakeFileName(name, modid, ".mpc"); (*write code file*)
    F := Files.New(name); Files.Set(R, F, 0); Files.WriteString(R, modid); Files.WriteInt(R, key); Files.WriteByte(R, codeseg + 4);
    obj := B.topScope.next;
    WHILE (obj # NIL) & (obj.class = B.Mod) DO  (*imports*)
      IF obj.dsc # B.system THEN Files.WriteString(R, obj(B.Module).orgname); Files.WriteInt(R, obj.val) END;
      obj := obj.next
    END;
    Files.Write(R, 0X);
    s := head; WHILE s # NIL DO WriteSection(R, s); s := s.next END;
    WriteSection(R, vectors); Files.WriteByte(R, 0);
    WriteWord(R, nofent); WriteWord(R, body.no);
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*entries*)
      IF obj.exno # 0 THEN
        IF obj.class IN {B.Var, B.StoredConst} THEN WriteWord(R, obj.val MOD 1000H)
        ELSIF obj.class = B.Typ THEN
          IF obj.type.form = B.Record THEN WriteWord(R, obj.type.len)
          ELSIF (obj.type.form = B.Pointer) & ((obj.type.base.typobj = NIL) OR (obj.type.base.typobj.exno = 0)) THEN
            WriteWord(R,  obj.type.base.len)
          END
        ELSE S.Mark("Unknown entry type")
        END
      END;
      obj := obj.next
    END ;
    Files.Write(R, "O"); Files.Register(F);
    flagsObj := NIL;
    head := NIL; tail := NIL; body := NIL; ccs := NIL;
    vectors.fixup := NIL (*for garbage collection*)
  END Close;

  PROCEDURE initConst(VAR c: Item; v: INTEGER);
  BEGIN c.reg := 0; c.am := A.Immediate; c.ofs := v; c.obj := NIL; c.type := B.intType; c.rdo := TRUE;
    c.mode := B.Const; c.tmp := FALSE; c.a := v
  END initConst;

  PROCEDURE initReg(VAR c: Item; r: BYTE);
  BEGIN c.reg := r; c.am := A.Register; c.ofs := 0; c.obj := NIL; c.type := B.intType;
    c.mode := Reg; c.tmp := FALSE; c.a := 0
  END initReg;

BEGIN PutDO0 := PutDO; A.SetProcs(GetOffset, AllocR, freeR, SetFCO);
  NEW(vectors); vectors.name := "vector table"; vectors.segment := "v";
  vectors.content := SYSTEM.VAL(Content, SYSTEM.ADR(mcode));
  initConst(cm1, -1); initConst(c0, 0); initConst(c1, 1); initConst(c2, 2);
  initReg(pc, A.PC); initReg(sp, A.SP); initReg(sr, A.SR); initReg(cg2, 3); initReg(r4, 4); initReg(r15, 15);
  relmap[0] := A.EQ; relmap[1] := A.NE; relmap[2] := A.L; relmap[3] := A.GE;
  urelmap[0] := A.EQ; urelmap[1] := A.NE; urelmap[2] := A.NC; urelmap[3] := A.C;
  B.SetRegRTProcCallback(RegisterRTproc)
END OMSPG.
