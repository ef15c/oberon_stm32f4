MODULE OMSPG; (* N.Wirth, 16.4.2016 / 4.4.2017 / 31.5.2019  Oberon compiler;
  C. Schoffit 21.05.24 code generator for MSP430 processor family*)
  IMPORT SYSTEM, Files, A := OMSPA, S := OMSPS, B := OMSPB;
  (*Code generator for Oberon compiler targetting MSP430 processor.
     Procedural interface to Parser OMSPP; result in record "code".
     Procedure Close writes code-files*)

  CONST WordSize* = 2;
    maxStrx = 3000; maxGD = 200; maxTD = 160; maxFOS = 1000;
    Register* = TRUE; Stack* = FALSE;
    
    Reg = 10; RegI = 11; Cond = 12; Absol = 13; (*internal item modes*)

  TYPE Item* = RECORD(A.Item)
    mode*: INTEGER;
    type*: B.Type;
    obj*: B.Object; (*symbol object, for register variables and update of "used at" chain*)
    a*, b*, c*: INTEGER;
    rdo*, tmp: BOOLEAN  (*read only*)
  END ;

  (* Item forms and meaning of fields:
    mode    c           a           b                      
    ----------------------------
    Const   -        value                           (proc adr) or (immediate or runtime value)
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

    FrameOffset = RECORD
      NofSegs: INTEGER;
      Segs: ARRAY maxFOS OF FrameOffsetSegment
    END;

    FixData = RECORD
      adr, usedat: INTEGER
    END;

    FixupCond = PROCEDURE(obj: B.Object; local:BOOLEAN): BOOLEAN; (*fixup selection criteria*)
    FixupAction = PROCEDURE(VAR R: Files.Rider; obj: B.Object; local:BOOLEAN); (*fixup action*)

  VAR varsize: INTEGER;   (*data index*)
    tdx, strx, mstrx, nofstrs: INTEGER;
    gvdata: ARRAY maxGD OF FixData; (*global variables references tracking*)
    tddata: ARRAY maxTD OF INTEGER; (*type descriptors data*)
    strdata: ARRAY maxStrx OF CHAR;
    entry: INTEGER;   (*main entry point*)
    AllocUp: BOOLEAN; (*if true, registers are in allocated in ascending or from R4 to R15, if false in descending order from R15 to R4*)
    RIU*, VRS: SET;      (*currently in use and variable + parameter register sets*)
    RB, RL: INTEGER; (*register base and limit*)
    PRU*: SET; (*set of registers used in procedure*)
    frame, vframe: INTEGER;   (*frame offset changed in SaveRegs and RestoreRegs + variable and parameter frame offset*)
    traps: ARRAY 8 OF B.Object; arith: ARRAY 4 OF B.Object;
    vector: ARRAY 32 OF INTEGER;
    
    relmap, urelmap: ARRAY 4 OF INTEGER;    (*condition codes for relations*)
    cm1, c0, c1, c2, pc, sp, sr, cg2, r4, r15: Item-; (*constant Items set by module initialization code*)
    rh: Item;
    curImport: INTEGER;

    mcode: A.ModuleCode;
    frmOfsSegs: FrameOffset;

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

  PROCEDURE OfsPTOS(frameofs, returnofs: INTEGER; increment: BOOLEAN);
    VAR offset: INTEGER;
  BEGIN
    IF increment THEN
      INC(frameofs, frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos MOD 10000H);
      INC(returnofs, frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos DIV 10000H);
    END; offset := returnofs*10000H + frameofs;
    IF offset # frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos THEN
      frmOfsSegs.Segs[frmOfsSegs.NofSegs].end := mcode.pc;
      INC(frmOfsSegs.NofSegs); frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos := offset
    END
  END OfsPTOS;

  PROCEDURE adjFrmOfs(size: INTEGER);
  BEGIN INC(frame, size);
    OfsPTOS(size DIV WordSize, size DIV WordSize, TRUE)
  END  adjFrmOfs;

  PROCEDURE SaveRegs(regs: SET);
    VAR n: INTEGER;
  BEGIN
    IF regs # {} THEN
      n := A.PushRegs(mcode, regs); adjFrmOfs(n*WordSize)
    END
  END SaveRegs;

  PROCEDURE RestoreRegs(regs: SET);
    VAR n: INTEGER;
  BEGIN
    IF regs # {} THEN
      n := A.PopRegs(mcode, regs); adjFrmOfs(-n*WordSize)
    END
  END RestoreRegs;

  PROCEDURE EnableCode*(e: BOOLEAN);
  BEGIN A.SetEnabled(e)
  END EnableCode;

  PROCEDURE FixOne*(at: INTEGER);
  BEGIN A.FixOne(mcode, at)
  END FixOne;

  PROCEDURE FixLink*(L: INTEGER);
  BEGIN
    A.FixLink(mcode, L)
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
    IF RH = RL THEN S.Mark("register stack overflow"); RH := 8 END;
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
    IF r IN RIU THEN EXCL(RIU, r)
    ELSE S.Mark("reg wild free") END
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

  PROCEDURE GetOffset(x: A.Item): INTEGER;
    VAR res, ofs, a, c, i: INTEGER; o!: B.Object;
  BEGIN CASE x OF
    Item:
      o := x.obj; ofs := x.ofs; a := x.a; c := x.c;
      IF (c = 0) & (ofs >= A.C17) THEN (*global constants with address encoded in offset*) a := ofs - A.C17; ofs := A.C16 END;
      IF (c = 0) & (ofs > A.C16) THEN (*global strings with index encoded in offset*)
        a := ofs - A.C16; res := ORD(strdata[a]) + ORD(strdata[a + 1]) * 100H;
        strdata[a] := CHR(mcode.pc MOD 100H); strdata[a + 1] := CHR(mcode.pc DIV 100H)
      ELSIF ofs >= A.C16 THEN
        IF ((x.mode = B.Var) OR (x.mode = B.Const) & (o # NIL) & (o.type.form # B.Proc)) &
          (c = 0) & (o.class # B.Typ) THEN (*global variable*) i := 0;
          WHILE (gvdata[i].adr # -1) & (gvdata[i].adr # a) DO INC(i) END;
          IF gvdata[i].adr = -1 THEN gvdata[i].adr := a; gvdata[i].usedat := 0; gvdata[i+1].adr := -1 END;
          res := gvdata[i].usedat; gvdata[i].usedat := mcode.pc
        ELSE (*Imported variable or other object type*) res := o.usedat; o.usedat := mcode.pc END
      ELSE res := ofs
      END
    | A.Item: ASSERT(FALSE)
    END

    RETURN res
  END GetOffset;

 PROCEDURE Trap(cond, num: INTEGER);
  (*Trap is implemented as calls to functions in the Trap special module.  
     If the procedure Trap.Handle<num> procedure exists and is exported,
     the trap checking code is generated.*)
  VAR t!: Item;
  BEGIN IF cond # A.AL THEN A.PutJ(mcode, A.negated(cond), 4) END; 
    t.reg := 0; t.am := A.Immediate; t.ofs := A.C16; t.obj := traps[num];
    A.PutSO(mcode, A.CALL, t, A.Word)
  END Trap;

  PROCEDURE NilCheck(a: BYTE);
    VAR t!, c!: Item;
  BEGIN t.reg := a; t.am := A.Register; t.ofs := 0; t.obj := NIL;
    IF traps[4] # NIL THEN
      c := c0; A.PutDO(mcode, A.CMP, c, t, A.Word);
      Trap(A.EQ, 4) 
    END
  END NilCheck;

  (* loading of operands and addresses into registers *)

  PROCEDURE load(VAR x: Item; pr: BYTE); (*load item in a temporary register*)
    VAR pc0, pc1: INTEGER; bw: SET; t!, ti!, sva!: Item;
  BEGIN t := x; t.reg := 0; t.am := A.Immediate;
    ti.am := A.Indexed; ti.obj := NIL; sva := x; sva.ofs := A.C16;
    IF x.type.size = 1 THEN bw := A.Byte ELSE bw := A.Word END;
    IF x.mode = B.Const THEN alloc(x, pr);
      IF x.type.form = B.Proc THEN
        IF x.c > 0 THEN S.Mark("not allowed")
        ELSE sva.am := A.Immediate (*imported*); A.PutDO(mcode, A.MOV, sva, x, A.Word)
        END
      ELSE t.ofs := x.a; A.PutDO(mcode, A.MOV, t, x, A.Word)
      END
    ELSIF x.mode = B.Var THEN alloc(x, pr);
      IF x.c > 0 THEN (*local*) ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, bw)
      ELSE  sva.am := A.Absolute; A.PutDO(mcode, A.MOV, sva, rh, bw)
      END
    ELSIF x.mode = B.Par THEN alloc(x, pr); ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
      ti.reg := rh.reg; ti.ofs := x.b; A.PutDO(mcode, A.MOV, ti, rh, bw)
    ELSIF x.mode = RegI THEN ti.reg := x.reg; ti.ofs := x.a; x.am := A.Register; x.ofs := 0; 
      IF ~x.tmp OR (pr # 0FFH) & (x.reg # pr) THEN free(x); alloc(x, pr) END;
      A.PutDO(mcode, A.MOV, ti, x, bw)
    ELSIF x.mode = Reg THEN
      IF ~x.tmp OR (pr # 0FFH) & (x.reg # pr) THEN (*temporary copy needed*)
        x.am := A.Register; t := x; free(x); alloc(x, pr); A.PutDO(mcode, A.MOV, t, x, A.Word) END
    ELSIF x.mode = Absol THEN alloc(x, pr); t.am := A.Absolute; t.ofs := x.a; A.PutDO(mcode, A.MOV, t, x, bw)
    ELSIF x.mode = Cond THEN alloc(x, pr);
      pc0 := mcode.pc; A.PutJ(mcode, A.negated(x.c), 0);
      FixLink(x.b); t := c1; A.PutDO(mcode, A.MOV, t, x, A.Word); pc1 := mcode.pc; A.PutJ(mcode, A.AL, 0);
      A.fix(mcode, pc0, mcode.pc - pc0 - 2); FixLink(x.a); t := c0; A.PutDO(mcode, A.MOV, t, x, A.Word);
      A.fix(mcode, pc1, mcode.pc - pc1 - 2)
    ELSE S.Mark("bad mode in load"); alloc(x, pr)
    END;
    x.mode := Reg; x.tmp := TRUE; x.am := A.Register; x.ofs := 0
  END load;

  PROCEDURE setRAO(op: INTEGER; VAR i: Item; dst: BOOLEAN; VAR nba, bw: SET);
    VAR ti!: Item;
  BEGIN IF (op = A.PUSH) OR (op = A.CALL) THEN dst := FALSE END;
    IF ~((dst OR (i.type.size = 2) OR (bw = A.Byte))) THEN S.Mark("move byte to int") END;
    IF i.type.size = 1 THEN bw := A.Byte END;
    IF dst & i.rdo & ((i.mode = B.Const) OR (op # A.CMP) & (op # A.BIT)) THEN load(i, 0FFH)
    ELSIF i.mode = B.Var THEN
      IF i.c > 0 THEN i.reg := A.SP; i.am := A.Indexed; i.ofs := i.a + frame ELSE i.reg := 0; i.am := A.Absolute; i.ofs := A.C16 (*use static var address*) END
    ELSIF i.mode = Reg THEN i.am := A.Register; i.ofs := 0
    ELSIF i.mode = RegI THEN i.am := A.Indexed; i.ofs := i.a
    ELSIF i.mode = Absol THEN  i.am := A.Absolute; i.ofs := i.a
    ELSIF i.mode = B.Const THEN i.ofs := i.a; i.reg := 0;
      i.am := A.Immediate;
      IF (i.type.form = B.Proc) & (i.c <= 0) THEN i.ofs := A.C16 END;
      IF dst THEN S.Mark("not writable"); i.am := A.Absolute END
    ELSIF i.mode = B.Par THEN rh.reg := AllocR(); INCL(nba, rh.reg);
      ti.am := A.Indexed; ti.reg := A.SP; ti.obj := NIL; ti.ofs := i.a + frame;
      A.PutDO(mcode, A.MOV, ti, rh, A.Word); i.mode := RegI; i.reg := rh.reg; i.a := i.b; i.b := 0; setRAO(op, i, dst, nba, bw)
    ELSE load(i, 0FFH)
    END
  END setRAO;

  PROCEDURE PutDO(op: BYTE; VAR src, dst: Item);
    VAR bw, nba: SET; tmp: BOOLEAN;
  BEGIN tmp := FALSE;
    IF (src.type.size = 1) & (dst.type.size = 2) THEN (*move byte to word*)
      IF src.mode # Reg THEN load(src, 0FFH); tmp := TRUE; END; src.type := B.intType (*extend source*)
    END;
    nba := {}; bw := A.Word; setRAO(op, dst, TRUE, nba, bw); setRAO(op, src, FALSE, nba, bw);
    A.PutDO(mcode, op, src, dst, bw); freeSet(nba);
    IF tmp THEN free(src) END
  END PutDO;

  PROCEDURE PutSO(op: INTEGER; VAR sd: Item);
    VAR bw, nba: SET;
  BEGIN nba := {}; bw := A.Word; setRAO(op, sd, TRUE, nba, bw);
    A.PutSO(mcode, op, sd, bw); freeSet(nba)
  END PutSO;

  PROCEDURE push(VAR x: Item; dsize: INTEGER);
    VAR pc0, pc1: INTEGER; bw: SET; t!, ti!, sva!: Item;
  BEGIN
    bw := A.Word;
    IF x.type.size = 1 THEN
      IF dsize = 1 THEN bw := A.Byte ELSE (*convert byte to word before push*) load(x, 0FFH); x.type := B.intType END
    END;
    adjFrmOfs(WordSize); t := x; t.reg := 0; t.am := A.Immediate;
    ti.am := A.Indexed; ti.obj := NIL; sva := x; sva.ofs := A.C16;
  (*  IF x.type.size = 1 THEN bw := A.Byte ELSE bw := A.Word END; *)
    IF x.mode = Reg THEN PutSO(A.PUSH, x)
    ELSIF x.mode = B.Const THEN
      IF x.type.form = B.Proc THEN
        IF x.c > 0 THEN S.Mark("not allowed")
        ELSE sva.am := A.Immediate (*imported*); A.PutSO(mcode, A.PUSH, sva, A.Word)
        END
      ELSE t.ofs := x.a; A.PutSO(mcode, A.PUSH, t, bw)
      END
    ELSIF x.mode = B.Var THEN
      IF x.c > 0 THEN (*local*) ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutSO(mcode, A.PUSH, ti, bw)
      ELSE sva.am := A.Absolute; A.PutSO(mcode, A.PUSH, sva, bw)
      END
    ELSIF x.mode = B.Par THEN ti.reg := A.SP; ti.ofs :=  x.a + frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word);
      ti.reg := rh.reg; ti.ofs := x.b; A.PutSO(mcode, A.PUSH, ti, bw)
    ELSIF x.mode = RegI THEN ti.reg := x.reg; ti.ofs := x.a; x.am := A.Register; x.ofs := 0; A.PutSO(mcode, A.PUSH, ti, bw)
    ELSIF x.mode = Absol THEN t.am := A.Absolute; t.ofs := x.a; A.PutSO(mcode, A.PUSH, t, bw)
    ELSIF x.mode = Cond THEN
      pc0 := mcode.pc; A.PutJ(mcode, A.negated(x.c), 0);
      FixLink(x.b); t := c1; A.PutSO(mcode, A.PUSH, t, A.Word); pc1 := mcode.pc; A.PutJ(mcode, A.AL, 0);
      A.fix(mcode, pc0, mcode.pc - pc0 - 2); FixLink(x.a); t := c0; A.PutSO(mcode, A.PUSH, t, A.Word);
      A.fix(mcode, pc1, mcode.pc - pc1 - 2)
    ELSE S.Mark("bad mode in push")
    END;
    free(x)
  END push;

  PROCEDURE Adr*(VAR x:Item);
    VAR t!: Item;
  BEGIN t.mode := B.Const; t.type := B.intType; t.obj := NIL;
    IF x.mode = B.Var THEN
      IF x.c > 0 THEN (*local*) ASSERT(x.tmp = FALSE); x.mode := Reg; x.reg := A.SP; x.rdo := TRUE;
        IF x.a + frame # 0 THEN t.a := x.a + frame; PutDO(A.ADD, t, x) END
      ELSE (*global or imported*) x.mode := B.Const; INC(x.a, A.C17)
      END
    ELSIF x.mode = B.Par THEN x.mode := B.Var;
      IF x.b # 0 THEN t.a := x.b; PutDO(A.ADD, t, x) END
    ELSIF (x.mode = B.Const) & (x.type.form = B.String) THEN INC(x.a, A.C16) (*encode string index in constant value*)
    ELSIF (x.mode = B.Const) & (x.type.form = B.Proc) & (x.c <= 0) THEN x.a := A.C16 (*use runtime proc address*)
    ELSIF x.mode = RegI THEN x.mode := Reg;
      IF x.a # 0 THEN t.a := x.a; PutDO(A.ADD, t, x) END
    ELSE S.Mark("not addressable")
    END;
    x.type := B.intType
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

  PROCEDURE loadTypTagAdr(T: B.Type; pr: INTEGER): BYTE;
    VAR sva!: Item;
  BEGIN sva.am := A.Immediate; sva.ofs := A.C16; sva.obj := T.typobj;
    rh.reg := AllocRP(pr); A.PutDO(mcode, A.MOV, sva, rh, A.Word)
    RETURN rh.reg
  END loadTypTagAdr;

  PROCEDURE pushTypTagAdr(T: B.Type);
    VAR sva!: Item;
  BEGIN sva.am := A.Immediate; sva.ofs := A.C16; sva.obj := T.typobj;
    adjFrmOfs(WordSize); A.PutSO(mcode, A.PUSH, sva, A.Word)
  END pushTypTagAdr;

  PROCEDURE loadStringAdr(VAR x: Item; pr: INTEGER);
  BEGIN x.am := A.Immediate; x.ofs := A.C16+x.a;
     rh.reg := AllocRP(pr); A.PutDO(mcode, A.MOV, x, rh, A.Word);
    x.mode := Reg; x.am := A.Register; x.reg := rh.reg; x.ofs := 0; x.tmp := TRUE
  END loadStringAdr;

  PROCEDURE pushStringAdr(x: Item);
    VAR x1!: Item;
  BEGIN x1 := x; x1.c := 0; x1.am := A.Immediate; x1.ofs := A.C16+x.a;
    adjFrmOfs(WordSize); A.PutSO(mcode, A.PUSH, x1, A.Word)
  END pushStringAdr;

  (* Items: Conversion from constants or from Objects on the Heap to Items on the Stack*)

  PROCEDURE MakeTypTagAdr(VAR x: Item; T: B.Type);
  BEGIN x.mode := B.Const; x.type := B.intType; x.a := A.C16; x.c := 0;
    x.rdo := TRUE; x.obj := T.typobj; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0
  END MakeTypTagAdr;

  PROCEDURE MakeConstItem*(VAR x: Item; typ: B.Type; val: INTEGER);
  BEGIN x.mode := B.Const; x.type := typ; x.a := val; x.c := 0;
    x.rdo := TRUE; x.obj := NIL; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0
  END MakeConstItem;

  PROCEDURE GetStringAddress(usedat: INTEGER): INTEGER;
    VAR adr, ua: INTEGER;
  BEGIN adr := 0; ua := maxStrx - WordSize; adr := 0;
    WHILE (adr <  strx) & (ua # usedat) DO
      WHILE strdata[adr] # 0X DO INC(adr) END; INC(adr); WHILE adr MOD WordSize # 0 DO INC(adr) END;
      DEC(ua, WordSize)
    END;

    RETURN adr
  END GetStringAddress;

  PROCEDURE stringFound(str: ARRAY OF CHAR; VAR usedat: INTEGER): BOOLEAN;
   (*if the string exists in table, return TRUE with the position in parameter pos*)
    VAR found: BOOLEAN; i, pos: INTEGER;
  BEGIN found := FALSE;
    pos := 0; usedat := maxStrx;
    WHILE ~found & (pos < strx) DO DEC(usedat, WordSize);
      i := 0; WHILE (str[i] # 0X) & (str[i] = strdata[pos + i]) DO INC(i) END;
      IF str[i] = strdata[pos + i] THEN found := TRUE ELSE WHILE strdata[pos + i] # 0X DO INC(i) END END;
      INC(pos, i + 1); WHILE pos MOD WordSize # 0 DO INC(pos) END
    END

    RETURN found
  END stringFound;

  PROCEDURE stringPut(VAR x: Item; str: ARRAY OF CHAR; len: INTEGER);
    VAR i: INTEGER;
  BEGIN x.mode := B.Const; x.type := B.strType; x.b := len; x.c := 0 (*global string*);
    x.rdo := TRUE; x.obj := NIL; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0;
    IF ~stringFound(str, x.a) THEN
      IF strx + len  + WordSize < mstrx THEN
        FOR i := 1 TO WordSize DO DEC(mstrx); strdata[mstrx] := 0X END; (*reserve room for usage tracking data*); x.a := mstrx;
        i := 0; WHILE len > 0 DO strdata[strx] := str[i]; INC(strx); INC(i); DEC(len) END;
        WHILE strx MOD WordSize # 0 DO strdata[strx] := 0X; INC(strx) END; INC(nofstrs)
      ELSE S.Mark("too many strings")
      END
    END
  END stringPut;

  PROCEDURE stringPop(x: Item; VAR xs: ARRAY OF CHAR);
    VAR sx, sxno, i: INTEGER;
  BEGIN sxno := (maxStrx - x.a) DIV WordSize - 1; sx := 0;
    WHILE sxno > 0 DO
      WHILE strdata[sx] # 0X DO INC(sx) END; REPEAT INC(sx) UNTIL sx MOD WordSize = 0; (*skip current string*)
      DEC(sxno)
    END;
    IF (x.a = mstrx) & (ORD(strdata[mstrx]) + ORD(strdata[mstrx + 1])*100H = 0) THEN (*string can be removed from table*)
      strx := sx; INC(mstrx, 2); DEC(nofstrs)
    END;
    i := 0; DEC(sx); REPEAT INC(sx); xs[i] := strdata[sx]; INC(i) UNTIL strdata[sx] = 0X (*copy string in dest*)
  END stringPop;

  PROCEDURE MakeStringItem*(VAR x: Item); (*copies string from OMSPS-buffer to OMSPG-string array*)
  BEGIN stringPut(x, S.str, S.slen)
  END MakeStringItem;

  PROCEDURE MakeItem*(VAR x: Item; y: B.Object; curlev: INTEGER);
  BEGIN x.mode := y.class; x.type := y.type; x.a := y.val; x.rdo := y.rdo; x.c := y.lev;
    x.obj := y; x.tmp := FALSE; x.reg := 0; x.am := A.Undefined; x.ofs := 0;
    IF (y.class IN {B.Var, B.Par}) THEN
      x.b := 0; x.c := y.lev;
      IF y.register # 0FFH THEN
        x.reg := y.register;
        IF y.class = B.Var THEN x.mode := Reg ELSE x.mode := RegI END
      END
    ELSIF (y.class = B.Const) & (y.type.form = B.String) THEN 
      x.a := y.val MOD 10000H; x.b := y.val DIV 10000H MOD 10000H (*len*)
    END;
    IF (y.lev > 0) & (y.lev # curlev) & (y.class # B.Const) THEN S.Mark("not accessible ") END
  END MakeItem;

  (* Code generation for Selectors, Variables, Constants *)

  PROCEDURE Field*(VAR x: Item; y: B.Object);   (* x := x.y *)
  BEGIN
    IF x.mode = B.Var THEN
      IF x.c >= 0 THEN x.a := x.a + y.val
      ELSE loadAdr(x, 0FFH); x.mode := RegI; x.a := y.val
      END
    ELSIF x.mode = RegI THEN INC(x.a, y.val)
    ELSIF x.mode = B.Par THEN INC(x.b, y.val)
    END
  END Field;

  PROCEDURE Index*(VAR x, y: Item);   (* x := x[y] *)
    VAR s, lim: INTEGER; t!: Item; typ!: B.Type;
  BEGIN
    IF x.type.form = B.String THEN s := 1; lim := x.b
    ELSE s := x.type.base.size; lim := x.type.len END;
    IF s = 0 THEN S.Mark("Invalid array item size")
    ELSE
      IF (y.mode = B.Const) & ((traps[1] = NIL) OR (lim >= 0)) THEN
        IF (y.a < 0) OR (lim >= 0) & (y.a >= lim) THEN S.Mark("bad index") END ;
        IF (x.type.form # B.String) & ((x.mode # B.Var) OR (x.c >= 0) OR (y.a = 0)) THEN
          IF x.mode IN {B.Var, RegI} THEN INC(x.a, y.a * s)
          ELSIF x.mode = B.Par THEN x.b := y.a * s + x.b
          END
        ELSE loadAdr(x, 0FFH) (*x.am := A.Immediate; x.ofs := A.C16; x.reg := 0; rh.reg := AllocR(); A.PutDO(mcode, A.MOV, x, rh, A.Word);
          x.reg := rh.reg; x.mode := RegI; x.a := y.a * s; x.am := A.Register; x.ofs := 0; x.tmp := TRUE *)
        END
      ELSE
        IF traps[1] # NIL THEN  (*check array bounds*)
          IF lim >= 0 THEN t.mode := B.Const; t.type := B.intType; t.a := lim; PutDO(A.CMP, t, y)
          ELSE (*open array*) t := x; t.type := B.intType;
            IF x.mode IN {B.Var, B.Par} THEN t.mode := B.Var; INC(t.a, WordSize)
            ELSIF x.mode IN {Reg, RegI} THEN t.mode := Reg; INC(t.reg)
            ELSE S.Mark("error in Index")
            END; PutDO(A.CMP, t, y)
          END;
          Trap(A.C, 1) (*MSP430 inverts the carry with SUB and CMP instructions*)
        END;
        IF s # 1 THEN t.mode := B.Const; t.type := B.intType; t.a := s; PutDO(A.MUL, t, y) END;
        IF (x.mode = B.Var) OR (x.type.form = B.String) THEN load(y, 0FFH); y.type := B.intType; typ := x.type;
          IF x.c > 0 THEN A.PutDO(mcode, A.ADD, sp, y, A.Word); INC(x.a, frame)
          ELSE Adr(x); PutDO(A.ADD, x, y); x.a := 0
          END;
          free(x); x.reg := y.reg; x.mode := RegI; x.tmp := TRUE; x.type := typ
        ELSIF x.mode = B.Par THEN load(y, 0FFH); t.mode := B.Var; 
          t.c := x.c; t.a := x.a; t.tmp := FALSE; t.obj := x.obj; t.type := B.intType; PutDO(A.ADD, t, y); free(t);
          free(x); x.mode := RegI; x.reg := y.reg; x.a := x.b; x.tmp := TRUE
        ELSIF x.mode = RegI THEN x.mode := Reg; t := x; t.type := B.intType; PutDO( A.ADD, t, y);
          free(x); x.mode := RegI; x.reg := y.reg; x.tmp := TRUE
        END
      END
    END
  END Index;

  PROCEDURE DeRef*(VAR x: Item);
  BEGIN
    IF (x.mode IN {B.Var, B.Par, RegI}) THEN load(x, 0FFH); NilCheck(x.reg); x.mode := RegI; x.a := 0
    ELSIF x.mode = Reg THEN x.mode := RegI; x.a := 0
    ELSIF x.type.form = B.Pointer THEN x.mode := Absol; x.b := 0
    ELSE S.Mark("bad mode in DeRef") 
    END; x.b := 0
  END DeRef;

  PROCEDURE Q(T: B.Type);
  BEGIN (*one entry of type descriptor extension table*)
    IF T.base # NIL THEN
      Q(T.base); tddata[tdx] := T.base.typobj.val;
      T.base.typobj.val := tdx*WordSize; INC(tdx)
    END
  END Q;

  PROCEDURE BuildTD*(T: B.Type);
    VAR k, s: INTEGER;
  BEGIN s := T.size;
    T.len := WordSize*tdx (*len used as address*); tddata[tdx] := s; INC(tdx);
    k := T.nofpar;   (*extension level!*)
    IF k > 3 THEN S.Mark("ext level too large")
    ELSE Q(T);
      WHILE k < 3 DO tddata[tdx] := -1; INC(tdx); INC(k) END
    END ;
    IF tdx >= maxTD THEN S.Mark("too many record types"); tdx := 0 END
  END BuildTD;

  PROCEDURE TypeTest*(VAR x: Item; T: B.Type; varpar, isguard: BOOLEAN);
    VAR t!, pt!, tt!: Item;
  BEGIN (*ti.am := A.Indexed; ti.obj := NIL; pt.am := A.Register; pt.ofs := 0; pt.obj := NIL; tt.am := A.Register; tt.ofs := 0; tt.obj := NIL;*)
    IF TypeChecked() OR ~isguard THEN
      IF T = NIL THEN free(x); SetCC(x, A.AL)
      ELSE rh.reg := AllocR(); (*fetch tag into RH*)
        IF varpar THEN t := x;
          IF t.mode IN {B.Var, B.Par} THEN t.mode := B.Var; INC(t.a, WordSize)
          ELSIF t.mode IN {Reg, RegI} THEN t.mode := Reg; INC(t.reg)
          ELSE S.Mark("error in TypeTest")
          END; PutDO(A.MOV, t, rh); free(x);
          t := rh; t.mode := RegI; t.a := T.nofpar*2; pt := t; pt.mode := Reg; pt.rdo := FALSE; PutDO(A.MOV, t, pt);
          MakeTypTagAdr(tt, T); (*tt.reg := loadTypTagAdr(T, 0FFH) (*tag of T*); tt.mode := Reg;*) PutDO(A.CMP, tt, pt);
          freeR(pt.reg); free(tt);
          IF isguard THEN Trap(A.NE, 2) ELSE SetCC(x, A.EQ) END;
        ELSE S.Mark("pointer not allowed")
        END
      END
    END
  END TypeTest;

  PROCEDURE SetVector*(n: BYTE; VAR h: B.Object);
  BEGIN IF vector[n] # 0FFFFH THEN S.Mark("vect mult def")
    ELSE vector[n] := h.usedat; h.usedat := n+100H END
  END SetVector;

  (* Code generation for Boolean operators *)

  PROCEDURE Not*(VAR x: Item);   (* x := ~x *)
    VAR t: INTEGER;
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
    VAR xr: INTEGER;
  BEGIN (*x.type.form = OM4B.Proc*) xr := -1; am := AllocUp;
    IF x.mode > B.Par THEN load(x, 0FFH); xr := x.reg; EXCL(RIU, xr) END;
    r := RIU; or := x.type.ur*RIU; (*overwritten registers currently in use by the caller*)
    SaveRegs(or); RIU := RIU - or;
    IF xr >= 0 THEN SaveRegs({xr}) END;
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
    IF x.mode = B.Const THEN PutSO(A.CALL, x)
    ELSE
      IF x.mode <= B.Par THEN IF traps[5] # NIL THEN t := c0; PutDO(A.CMP, t, x); Trap(A.EQ, 5) END;
        PutSO(A.CALL, x); free(x)
      ELSE rh.reg := AllocR();
        IF s = 0 THEN PutSO(A.POP, rh); adjFrmOfs(-WordSize)
        ELSE t := sp; t.mode := RegI; t.a := -x.type.size; PutDO(A.MOV, t, rh); INC(s, WordSize)
        END;
        IF traps[5] # NIL THEN t := c0; PutDO(A.CMP, t, rh); Trap(A.EQ, 5) END;
        A.PutSO(mcode, A.CALL, rh, A.Word); freeR(rh.reg)
      END;
    END;
    IF s # 0 THEN t := c0; t.a := s; rr := sp; PutDO(A.ADD, t, rr); adjFrmOfs(-s) END;
    IF x.type.base.form = B.NoTyp THEN (*procedure*) RIU := VRS; SetAllocationMode(am)
    ELSE (*function*) 
      x.tmp := TRUE; x.mode := Reg; resultRegister(rr); x.reg := rr.reg; x.am := A.Register;
      RIU := r; SetAllocationMode(am); 
      IF rr.reg IN RIU THEN x.tmp := FALSE; load(x, 0FFH) (*move result in a free register*)
      ELSE INCL(RIU, rr.reg)
      END
    END;
    RestoreRegs(or); RIU := RIU + or
  END Call;

  PROCEDURE AddOp*(op: INTEGER; VAR x, y: Item);   (* x := x +- y *)
  BEGIN
    IF op = S.plus THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a + y.a
      ELSIF y.mode = B.Const THEN
        IF y.a # 0 THEN PutDO(A.ADD, y, x) END
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
    VAR t!, p!, x0!, y0!: Item; r, or: SET; pau: BOOLEAN;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a * y.a
    ELSIF (y.mode = B.Const)  & (y.a >= 2) THEN load(x, 0FFH); t.ofs := y.a; A.PutDO(mcode, A.MUL, t, x, A.Word)
    ELSIF (x.mode = B.Const) & (x.a >= 2) THEN load(y, 0FFH); t.ofs := x.a; A.PutDO(mcode, A.MUL, t, y, A.Word);
      x.mode := Reg; x.reg := y.reg; x.am := A.Register; x.ofs := 0; x.tmp := TRUE
    ELSE
      IF arith[0] = NIL THEN S.Mark("import Arith.mul16 function") 
      ELSE MakeItem(p, arith[0], 0); x0 := x; y0 := y; PrepCall(p, r, or, pau); load(x, 5); load(y, 6); Call(p, r, or, pau);
        free(x0); free(y0); x.reg := p.reg;
      END
    END
  END MulOp;

  PROCEDURE DivOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
    VAR t!, p!, x0!, y0!: Item; r, or: SET; pau: BOOLEAN;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF op = S.div THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a DIV y.a ELSE S.Mark("bad divisor") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) THEN load(x, 0FFH); t.ofs := y.a; A.PutDO(mcode, A.DIv, t, x, A.Word);
        x.mode := Reg; x.am := A.Register; x.ofs := 0
      ELSE IF arith[1] = NIL THEN S.Mark("import Arith.divmod16 procedure")
        ELSE IF traps[6] # NIL THEN t := c0; PutDO(A.CMP, t, y); Trap(A.NE, 6); free(y) END;
          MakeItem(p, arith[1], 0); x0 := x; y0 := y; PrepCall(p, r, or, pau); load(x, 5); load(y, 6); t := c0; load(t, 7); Call(p, r, or, pau);
          free(x0); free(y0); x.reg := p.reg;
        END
      END
    ELSE (*op = OM4S.mod*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a MOD y.a ELSE S.Mark("bad modulus") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) THEN load(x, 0FFH); t.ofs := y.a; A.PutDO(mcode, A.MOd, t, x, A.Word);
        x.mode := Reg; x.am := A.Register; x.ofs := 0
      ELSE IF arith[1] = NIL THEN S.Mark("import Arith.divmod procedure")
        ELSE IF traps[6] # NIL THEN t := c0; PutDO(A.CMP, t, y); Trap(A.NE, 6); free(y) END;
            MakeItem(p, arith[1], 0); x0 := x; y0 := y; PrepCall(p, r, or, pau); load(x, 5); load(y, 6); t := c1; load(t, 7); Call(p, r, or, pau); x.reg := p.reg;
          free(x0); free(y0); x.reg := p.reg;
        END
      END
    END
  END DivOp;

  (* Code generation for shift operations *)
  PROCEDURE shift(op: INTEGER; VAR x, y: Item); (* x := op(x, y)*)
    VAR i, pb, pf: INTEGER; t! : Item;
  BEGIN
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := LSL(x.a, y.a) 
    ELSIF (y.mode = B.Const) & (y.a <= 4) THEN PutSO(A.NOP0, x); FOR i := 1 TO y.a DO PutSO(op, x) END
    ELSE PutSO(A.NOP0, x); t := c1; PutDO(A.ADD, t, y);
      pb := mcode.pc; PutDO(A.SUB, t, y); pf := mcode.pc; A.PutJ(mcode, A.EQ, 0);
      PutSO(op, x); A.PutJ(mcode, A.AL, pb - mcode.pc - 2); A.fix(mcode, pf, mcode.pc - pf - 2);
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
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN
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
        free(x0); free(y0); x.reg := p.reg;
      END
    END
  END Set;

  PROCEDURE In*(VAR x, y: Item);  (* x := x IN y *)
    VAR c!: Item; pc0, pc1: INTEGER; t!: Item;
  BEGIN 
    IF x.mode = B.Const THEN  c.mode := B.Const; c.type := B.intType; c.a := LSL(1, x.a); c.obj := NIL; PutDO(A.BIT, c, y);
      free(x)
    ELSE load(x, 0FFH); load(y, 0FFH); t := c1; PutDO(A.ADD, t, x); 
      pc0 := mcode.pc; PutDO(A.SUB, t, x); pc1 := mcode.pc; A.PutJ(mcode, A.EQ, 0);
      PutSO(A.RRC, y); A.PutJ(mcode, A.AL, pc0 - mcode.pc -2); A.fix(mcode, pc1, mcode.pc - pc1 - 2);
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
    AdjustSize(x); AdjustSize(y);
    IF x.type.size # y.type.size THEN
      IF x.type.size = 1 THEN IF x.mode # B.Const THEN load(x, 0FFH) END; x.type := B.intType
      ELSE IF y.mode # B.Const THEN load(y, 0FFH) END; y.type := B.intType
      END (*convert to word*)
    END;
    IF op < S.gtr THEN PutDO(A.CMP, y, x); IF x.type.size = 1 THEN SetCC(x, urelmap[op - S.eql]) ELSE SetCC(x, relmap[op - S.eql]) END
    ELSE PutDO(A.CMP, x, y); IF x.type.size = 1 THEN SetCC(x, urelmap[op - S.gtr + 2]) ELSE SetCC(x, relmap[op - S.gtr + 2]) END
    END;
    free(y); free(x)
  END IntRelation;

  PROCEDURE StringRelation*(op: INTEGER; VAR x0, y0: Item);   (* x := x < y *)
    (*x, y are char arrays or strings*)
    VAR pc0, tbf0: INTEGER; x!, y!: Item;
  BEGIN
    IF x0.type.form = B.String THEN loadStringAdr(x0, 0FFH) ELSE loadAdr(x0, 0FFH) END;
    IF y0.type.form = B.String THEN loadStringAdr(y0, 0FFH) ELSE loadAdr(y0, 0FFH) END;
    IF op < S.gtr THEN x := x0; y := y0 ELSE x := y0; y := x0 END;
    (*Compare:*) pc0 := mcode.pc;
    x.am := A.IndirectIncr; rh.reg := AllocR(); A.PutDO(mcode, A.MOV, x, rh, A.Byte);
    y.am := A.IndirectIncr; A.PutDO(mcode, A.CMP, y, rh, A.Byte);
    tbf0 := mcode.pc; A.PutJ(mcode, A.NE, 0) (*JNE Fin*);
    A.PutDO(mcode, A.CMP, c0, rh, A.Byte); (*compare char x^ to 0*)
    A.PutJ(mcode, A.NE, pc0 - mcode.pc - 2) (*JNE Compare*);
    (* Fin: *) A.fix(mcode, tbf0, mcode.pc - tbf0 - 2); free(y0); free(x0); freeR(rh.reg);
    IF op < S.gtr THEN SetCC(x0, urelmap[op - S.eql]) ELSE SetCC(x0, urelmap[op - S.gtr + 2]) END
  END StringRelation;

  (* Code generation of Assignments *)

  PROCEDURE StrToChar*(VAR x: Item);
  BEGIN ASSERT(x.b = 2); x.type := B.charType;
    DEC(strx, WordSize); INC(mstrx, WordSize); DEC(nofstrs); (*remove string from strdata table*)
    x.a := ORD(strdata[strx])
  END StrToChar;

  PROCEDURE Store*(VAR x, y: Item); (* x := y *)
   BEGIN PutDO(A.MOV, y, x); free(y); free(x)
  END Store;

  PROCEDURE distance(x, y: Item; VAR d: INTEGER): BOOLEAN;
    VAR res: BOOLEAN; ox, oy: INTEGER;
  BEGIN res := TRUE;
    IF (x.obj # NIL) & (x.obj = y.obj) & (x.mode = y.mode) & ((x.mode # RegI) OR (x.reg = y.reg)) THEN
      IF x.mode = B.Par THEN ox := x.b ELSE ox := x.a END;
      IF y.mode = B.Par THEN oy := y.b ELSE oy := y.a END;
      d := ox - oy
    ELSIF (x.mode = B.Var) & (y.mode = B.Var) & (x.obj.lev >= 0) & (x.obj.lev = y.obj.lev) THEN d := x.a - y.a
    ELSIF (x.mode = B.Const) & (y.mode = B.Const) & (x.a >= A.C17) & (y.a >= A.C17) THEN d := x.a - y.a
    ELSE res := FALSE
    END

    RETURN res
  END distance;

  PROCEDURE StoreStruct*(VAR x, y: Item); (* x := y *)
    VAR s, pc0, pc1, d: INTEGER; t!, ti!: Item; oneReg: BOOLEAN; xtyp!, ytyp!: B.Type;
  BEGIN t.mode := B.Const; t.type := B.intType; t.reg := 0; t.am := A.Immediate; t.obj := NIL; ti := y;
    pc0 := -1; xtyp := x.type; ytyp := y.type;
    oneReg := distance(x, y, d);
    IF ytyp.size # 0 THEN
      loadAdr(y, 0FFH); IF oneReg THEN free(x); x.reg := y.reg; x.tmp := FALSE; DEC(d, WordSize) ELSE loadAdr(x, 0FFH); d := 0 END; rh.reg := AllocR(); 
      IF (xtyp.form = B.Array) &  (xtyp.len > 0) THEN
        IF ytyp.len >= 0 THEN 
          IF xtyp.size = ytyp.size THEN t.a := (ytyp.size+1) DIV 2; PutDO(A.MOV, t, rh)
          ELSE S.Mark("different length/size, not implemented")
          END
        ELSE (*y  open array*) ti.a := y.a+WordSize; PutDO(A.MOV, ti, rh); s := ytyp.base.size;  (*element size*)
          t := c0; PutDO(A.CMP, t, rh); pc0 := mcode.pc; A.PutJ(mcode, A.EQ, 0); (*JEQ L0*)
          IF s = 1 THEN t := c1; PutDO(A.ADD, t, rh); PutSO(A.RRA, rh)
          ELSIF s # 2 THEN ASSERT(~ODD(s)); t.ofs := s DIV 2; A.PutDO(mcode, A.MUL, t, rh, A.Word)
          END;
          IF traps[3] # NIL THEN t.a := (xtyp.size+1) DIV 2+1; PutDO(A.CMP, t, rh); Trap(A.GE, 3) END
        END
      ELSIF xtyp.form = B.Record THEN t.a := xtyp.size DIV 2; PutDO(A.MOV, t, rh)
      ELSE S.Mark("inadmissible assignment")
      END;
      (*L1*) pc1 := mcode.pc; x.am := A.Indexed; x.ofs := d; y.am := A.IndirectIncr;
      A.PutDO(mcode, A.MOV, y, x, A.Word); IF ~oneReg THEN t := c2; PutDO(A.ADD, t, x) END;
      t := c1; PutDO(A.SUB, t, rh); A.PutJ(mcode, A.NE, pc1 - mcode.pc -2); (*BNE L1*)
      (*L0:*) IF pc0 # -1 THEN A.fix(mcode, pc0, mcode.pc - pc0 - 2) END;
      freeR(rh.reg); free(y); free(x)
    END
  END StoreStruct;

  PROCEDURE CopyString*(VAR x, y: Item);  (* x := y *)
     VAR len, pc0: INTEGER; t!,ti!, x1!: Item;
   BEGIN t.mode := B.Const; t.type := B.intType; t.reg := 0; t.am := A.Immediate; t.obj := NIL; ti := y;
    len := x.type.len; loadAdr(x, 0FFH);
    IF len >= 0 THEN
      IF len < y.b THEN S.Mark("string too long") END
    ELSIF traps[3] # NIL THEN ti.a := x.a+WordSize; PutDO(A.MOV, ti, rh); (*open array len*)
      t.a := y.b; PutDO(A.CMP, t, rh); Trap(A.L, 3)
    END ;
    loadStringAdr(y, 0FFH);
    (*L0:*) pc0 := mcode.pc; x.am := A.Indexed; x.ofs := 0; y.am := A.IndirectIncr; x1 := x;
    A.PutDO(mcode, A.MOV, y, x, A.Word); x.am := A.Register; t := c2; A.PutDO(mcode, A.ADD, t, x, A.Word);
    y.am := A.Indexed; y.ofs := -1; t := c0; A.PutDO(mcode, A.CMP, t, y, A.Byte) (*test 0*); A.PutJ(mcode, A.NE, pc0 - mcode.pc -2); (*BNE L0*)
    free(y); free(x)
   END CopyString;
  
  (* Code generation for parameters *)
  
  PROCEDURE OpenArrayParam*(VAR x: Item; par: B.Object);
    VAR t!, ti!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;  t.ofs := x.type.len;
    ti.am := A.Indexed; ti.obj := NIL;
    IF par.register # 0FFH THEN (*in registers*) loadAdr(x, par.register); rh.reg := AllocRP(par.register+1);
      IF t.ofs >= 0 THEN A.PutDO(mcode, A.MOV, t, rh, A.Word)
      ELSE ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
      END
    ELSE (*in stack*) adjFrmOfs(WordSize);
      IF t.ofs >= 0 THEN A.PutSO(mcode, A.PUSH, t, A.Word)
      ELSE ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutSO(mcode, A.PUSH, ti, A.Word)
      END;
      pushAdr(x)
    END
  END OpenArrayParam;

  PROCEDURE VarParam*(VAR x: Item; par: B.Object);
    VAR xmd: INTEGER; t!, ti!: Item; xtyp!: B.Type;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL; xtyp := x.type; t.ofs := xtyp.len;
    ti.am := A.Indexed; ti.obj := NIL; xmd := x.mode;
    IF par.register # 0FFH THEN
      loadAdr(x, par.register);
      IF (par.type.form = B.Array) & (par.type.len < 0) THEN rh.reg := AllocRP(par.register+1); (*open array*)
        IF t.ofs >= 0 THEN A.PutDO(mcode, A.MOV, t, rh, A.Word)
        ELSE ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
        END
      ELSIF par.type.form = B.Record THEN
        IF xmd = B.Par THEN rh.reg := AllocRP(par.register+1); ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutDO(mcode, A.MOV, ti, rh, A.Word)
        ELSE xmd := loadTypTagAdr(xtyp, par.register+1)
        END
      END
    ELSE (*in stack*)
      IF (par.type.form = B.Array) & (par.type.len < 0) THEN (*open array*) rh.reg := AllocR();
        adjFrmOfs(WordSize);
        IF t.ofs >= 0 THEN A.PutSO(mcode, A.PUSH, t, A.Word)
        ELSE ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutSO(mcode, A.PUSH, ti, A.Word)
        END
      ELSIF (par.type.form = B.Record) THEN
        IF xmd = B.Par THEN adjFrmOfs(WordSize);
          rh.reg := AllocR(); ti.reg := A.SP; ti.ofs := x.a+WordSize+frame; A.PutSO(mcode, A.PUSH, ti, A.Word)
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
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL; t.ofs := x.b;
    IF par.register # 0FFH THEN loadStringAdr(x, par.register);
      rh.reg := AllocRP(par.register+1); A.PutDO(mcode, A.MOV, t, rh, A.Word) (*len*)
    ELSE adjFrmOfs(WordSize); A.PutSO(mcode, A.PUSH, t, A.Word) (*len*);
      pushStringAdr(x)
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
    L := mcode.pc; A.PutJ(mcode, A.L, 0); free(z)
  END For1;

  PROCEDURE For2*(VAR x, y, w: Item);
  BEGIN free(x); MakeItem(x, x.obj, x.obj.lev); (* discard effects of previous loading if any *)
    x.rdo := FALSE; PutDO(A.ADD, w, x);
  END For2;

  (* Branches, procedure calls, procedure prolog and epilog *)

  PROCEDURE Here*(): INTEGER;
  RETURN mcode.pc
  END Here;

  PROCEDURE FJump*(VAR L: INTEGER);
  BEGIN A.PutJ(mcode, A.AL, L); L := mcode.pc - 2
  END FJump;

  PROCEDURE CFJump*(VAR x: Item);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    IF x.c # A.AL THEN A.PutJ(mcode, A.negated(x.c), x.a); x.a := mcode.pc - 2 END;
    A.FixLink(mcode, x.b)
  END CFJump;

  PROCEDURE BJump*(L: INTEGER);
  BEGIN A.PutJ(mcode, A.AL, L - mcode.pc - 2)
  END BJump;

  PROCEDURE CBJump*(VAR x: Item; L: INTEGER);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    IF x.c # A.AL THEN A.PutJ(mcode, A.negated(x.c), L - mcode.pc - 2) END;
    A.FixLink(mcode, x.b); A.FixLinkWith(mcode, x.a, L)
  END CBJump;

  PROCEDURE Fixup*(VAR x: Item);
  BEGIN A.FixLink(mcode, x.a)
  END Fixup;

  PROCEDURE Enter*(size: INTEGER; int: BOOLEAN; savedregs: SET);
    VAR t!, tsp!: Item;
  BEGIN
    OfsPTOS(0, 0, FALSE); IF int THEN (*SR copy is on TOS*) OfsPTOS(1, 1, TRUE) END;
    frame := 0;

    IF size >= A.C16 THEN S.Mark("local variables size exeeded") END;
    IF size # 0 THEN t := c0; t.a := size; tsp := sp; PutDO(A.SUB, t, tsp); adjFrmOfs(size) END;

    SaveRegs(savedregs); (*save registers before use*)
    VRS := RIU; vframe := frame
  END Enter;

  PROCEDURE Return*(form: INTEGER; VAR x: Item; size: INTEGER; int: BOOLEAN; savedregs: SET);
    VAR t!, rr!: Item;
  BEGIN t.reg := 0; t.am := A.Immediate; t.obj := NIL;
    IF form # B.NoTyp THEN resultRegister(rr); x.tmp := TRUE; IF rr.reg IN RIU THEN freeR(rr.reg) END;
      load(x, rr.reg); IF x.reg IN RIU THEN free(x) END
    END;

    RestoreRegs(savedregs); PRU := PRU - savedregs;
    IF size # 0 THEN t.ofs := size; A.PutDO(mcode, A.ADD, t, sp, A.Word); adjFrmOfs(-size) END;
    IF int THEN A.PutNO(mcode, A.RETI); OfsPTOS(-1, -1, TRUE);
      IF PRU # {} THEN S.Mark("destroyed regs in handler") END
    ELSE A.PutNO(mcode, A.RET)
    END;
    IF frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos # 0 THEN S.DebugHex("stack seg", frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos) END;
    SetAllocationMode(Stack); RIU := {}; VRS := RIU
  END Return;

  (* In-line code procedures*)

  PROCEDURE Increment*(upordown: INTEGER; VAR x, y: Item);
    VAR op: BYTE;
  BEGIN
    IF upordown = 0 THEN op := A.ADD ELSE op := A.SUB END;
    IF y.type.form = B.NoTyp THEN y.mode := B.Const; y.a := 1; y.tmp := FALSE END;
    PutDO(op, y, x);
    free(y); free(x)
  END Increment;

  PROCEDURE Include*(inorex: INTEGER; VAR x, y: Item);
    VAR op: BYTE; z!, t!: Item;
  BEGIN IF inorex = 0 THEN op := A.BIS ELSE op := A.BIC END;
    IF y.mode = B.Const THEN t.mode := B.Const; t.type := B.intType; t.tmp := FALSE; t.obj := NIL; t.ofs := 0; t.a := LSL(1, y.a); PutDO(op, t, x)
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
      ELSE pc0 := mcode.pc; A.PutJ(mcode, x.c, 0); A.FixLink(mcode, x.a); cond := A.AL
      END;
      Trap(cond, 7); A.FixLink(mcode, x.b);
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
      pc0 := mcode.pc; A.PutJ(mcode, A.EQ, 0); (*JEQ L0*)
    END;
    oneReg := distance(y, x, d);
    load(x, 0FFH);
    IF oneReg THEN free(y); y.reg := x.reg; y.tmp := FALSE; DEC(d, WordSize);
    ELSE load(y, 0FFH); d := 0 END;
    pc1 := mcode.pc; x.a := 0; x.am := A.IndirectIncr; y.am := A.Indexed; y.ofs := d; A.PutDO(mcode, A.MOV, x, y, A.Word);
    y.am := A.Register; IF ~oneReg THEN t := c2; A.PutDO(mcode, A.ADD, t, y, A.Word) END;
    t := c1; A.PutDO(mcode, A.SUB, t, z, A.Word); A.PutJ(mcode, A.NE, pc1 - mcode.pc - 2); (*BNE L1*)
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
    t.mode := B.Var; t.c := 1; t.type := B.intType; t.a := 0; t.tmp := FALSE; t.rdo := FALSE; PutDO(op, x, t); free(x); free(t)
  END LogicalSROnExit;

  (*In-line code functions*)

  PROCEDURE Abs*(VAR x: Item);
    VAR pc: INTEGER; t!: Item;
  BEGIN
    IF x.mode = B.Const THEN x.a := ABS(x.a) 
    ELSE t := c0; PutDO(A.CMP, t, x); pc := mcode.pc; A.PutJ(mcode, A.GE, 0);
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
    IF x.type.form = B.String THEN free(x); x.mode := B.Const; x.a := x.b; x.type := B.intType
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
  BEGIN A.PutDO(mcode, A.MOV, c0, cg2, A.Word)
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
  BEGIN A.Init(mcode); gvdata[0].adr := -1; curImport := 0; frmOfsSegs.NofSegs := 0; frmOfsSegs.Segs[0].ofsptos := 0;
    FOR i := 0 TO LEN(traps) - 1 DO traps[i] := NIL END;
    FOR i := 0 TO LEN(arith) - 1 DO arith[i] := NIL END;
    FOR i := 0 TO LEN(vector) - 1 DO vector[i] := 0FFFFH END;
    tdx := 0; strx := 0; mstrx := maxStrx; nofstrs := 0; RIU := {};
    rh.reg := 15; rh.am := A.Register; rh.ofs := 0; rh.obj := NIL; rh.mode := Reg; rh.type := B.intType;
    SetAllocationMode(Stack)
  END Open;

  PROCEDURE SetDataSize*(dc: INTEGER);
  BEGIN varsize := dc
  END SetDataSize;

  PROCEDURE Header*;
  BEGIN entry := mcode.pc; frame := 0; vframe := 0; OfsPTOS(0, 0, FALSE); SetAllocationMode(Stack)
  END Header;

  PROCEDURE WriteWord(VAR R: Files.Rider; w: INTEGER);
  BEGIN Files.WriteByte(R, w MOD 100H); Files.WriteByte(R, w DIV 100H MOD 100H);
  END WriteWord;

  PROCEDURE procFixupCond(obj: B.Object; local:BOOLEAN): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN res := (obj.class = B.Const) & (obj.type.form = B.Proc) & (obj.usedat # 0);
    IF local THEN res := res & (obj.lev = 0) ELSE res := res & (obj.lev < 0) END

    RETURN res
  END procFixupCond;

  PROCEDURE handlerFixupCond(obj: B.Object; local:BOOLEAN): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN res := (obj.class = B.Const) & (obj.type.form = B.Handler) & (obj.usedat # 0);
    IF local THEN res := res & (obj.lev = 0) ELSE res := res & (obj.lev < 0) END

    RETURN res
  END handlerFixupCond;

  PROCEDURE varFixupCond(obj: B.Object; local:BOOLEAN): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN res := (obj.class = B.Var) & (obj.usedat # 0);
    IF local THEN res := res & (obj.lev = 0) ELSE res := res & (obj.lev < 0) END

    RETURN res
  END varFixupCond;

  PROCEDURE constFixupCond(obj: B.Object; local:BOOLEAN): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN res := obj.usedat # 0;
    IF local THEN res := res & (obj.class = B.Typ) & (obj.type.mno = 0)
    ELSE res := res & ((obj.class = B.Typ) & (obj.type.mno > 0) OR
      (obj.class = B.Const) & (obj.type.form = B.String) & (obj.lev < 0))
    END

    RETURN res
  END constFixupCond;

  PROCEDURE typFixupCond(obj: B.Object; local:BOOLEAN): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN res := (obj.class = B.Typ) & (obj.val # 0);
    IF local THEN res := res & (obj.type.mno = 0) ELSE res := res & (obj.type.mno > 0) END

    RETURN res
  END typFixupCond;

  PROCEDURE objFixupAction(VAR R: Files.Rider; obj: B.Object; local:BOOLEAN);
  BEGIN WriteWord(R, obj.usedat); Files.WriteByte(R, -obj.lev); (*module number*)
    WriteWord(R, obj.val) (*local object relative address or imported object number*)
  END objFixupAction;

  PROCEDURE constFixupAction(VAR R: Files.Rider; obj: B.Object; local:BOOLEAN);
  BEGIN WriteWord(R, obj.usedat);
    IF local THEN Files.WriteByte(R, 0); (*local type*); WriteWord(R, obj.type.len) (*relative address*)
    ELSIF obj.class = B.Typ THEN Files.WriteByte(R, obj.type.mno); (*module number*); WriteWord(R, obj.type.len)
    ELSE (*exported string*) Files.WriteByte(R, -obj.lev); (*module number*); WriteWord(R, obj.val MOD 10000H) (*object number*)
    END
  END constFixupAction;

  PROCEDURE typFixupAction(VAR R: Files.Rider; obj: B.Object; local:BOOLEAN);
  BEGIN WriteWord(R, obj.val); Files.WriteByte(R, obj.type.mno); (*module number*)
    WriteWord(R, obj.type.len) (*local object relative address or imported object number*)
  END typFixupAction;

  PROCEDURE WriteFixup(VAR R: Files.Rider; cond: FixupCond; action: FixupAction);
    VAR obj!, obj2!: B.Object;
  BEGIN
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*local elements fixup chains*)
      IF cond(obj, TRUE) THEN ASSERT(obj.class # B.Var); action(R, obj, TRUE) END;
      obj := obj.next
    END;
    obj := B.topScope.next;
    WHILE (obj # NIL) & (obj.class = B.Mod) DO  (*imported elements fixup chains*)
      IF obj.dsc # B.system THEN
        obj2 := obj.dsc;
        WHILE obj2 # NIL DO
          IF cond(obj2, FALSE) THEN action(R, obj2, FALSE) END;
          obj2 := obj2.next
        END
      END;
      obj := obj.next
    END;
    WriteWord(R, 0)
  END WriteFixup;

  PROCEDURE Close*(VAR modid: S.Ident; key, nofent: INTEGER; codeseg: BYTE);
    VAR obj!: B.Object;
      i, sx, suax, nofimps, fixadr, flashSize: INTEGER;
      name: S.Ident;
      F!: Files.File; R!: Files.Rider;
  BEGIN  (*exit code*) A.PutNO(mcode, A.RET);
    obj := B.topScope.next; nofimps := 0;
    WHILE obj # NIL DO
      IF (obj.class = B.Mod) & (obj.dsc # B.system) THEN INC(nofimps); (*count imports*)
      END;
      obj := obj.next
    END;
    
    flashSize := tdx*WordSize + strx + mcode.pc;
    
    B.MakeFileName(name, modid, ".mpc"); (*write code file*)
    F := Files.New(name); Files.Set(R, F, 0); Files.WriteString(R, modid); Files.WriteInt(R, key); Files.WriteByte(R, codeseg);
    WriteWord(R, flashSize);
    obj := B.topScope.next;
    WHILE (obj # NIL) & (obj.class = B.Mod) DO  (*imports*)
      IF obj.dsc # B.system THEN Files.WriteString(R, obj(B.Module).orgname); Files.WriteInt(R, obj.val) END;
      obj := obj.next
    END;
    Files.Write(R, 0X);
    WriteWord(R, tdx*WordSize);
    i := 0;
    WHILE i < tdx DO WriteWord(R, tddata[i]); INC(i) END ; (*type descriptors*)
    WriteWord(R, varsize);  (*data*)
    WriteWord(R, strx);
    FOR i := 0 TO strx-1 DO Files.Write(R, strdata[i]) END ;  (*strings*)
    WriteWord(R, mcode.pc);  (*code len*)
    FOR i := 0 TO mcode.pc-1 DO Files.WriteByte(R, mcode.code[i]) END ;  (*program*)
    Files.WriteByte(R, LEN(vector));  (*Vectors table*)
    FOR i := 0 TO LEN(vector) - 1 DO WriteWord(R, vector[i]) END;
    WriteWord(R, nofent); Files.Write(R, "c"); (*code segment*) WriteWord(R, entry);
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*entries*)
      IF obj.exno # 0 THEN
        IF (obj.class = B.Const) & (obj.type.form IN {B.Proc, B.Handler}) THEN Files.Write(R, "c"); (*code section*) WriteWord(R, obj.val)
        ELSIF obj.class = B.Var THEN Files.Write(R, "d"); (*data section*) WriteWord(R, obj.val)
        ELSIF (obj.class = B.Const) & (obj.type.form = B.String) THEN Files.Write(R, "k"); (*const section (string)*)
          WriteWord(R, GetStringAddress(obj.val MOD 10000H))
        ELSIF obj.class = B.Typ THEN Files.Write(R, "k"); (*const sesction (tag)*)
          IF obj.type.form = B.Record THEN WriteWord(R, obj.type.len)
          ELSIF (obj.type.form = B.Pointer) & ((obj.type.base.typobj = NIL) OR (obj.type.base.typobj.exno = 0)) THEN
            WriteWord(R,  obj.type.base.len)
          END
        END
      END ;
      obj := obj.next
    END ;
    WriteFixup(R, procFixupCond, objFixupAction); (*procedures fixup data*)
    WriteFixup(R, handlerFixupCond, objFixupAction); (*interrupt handlers fixup data*)
    i := 0; WHILE gvdata[i].adr # -1 DO WriteWord(R, gvdata[i].usedat); Files.WriteByte(R, 0); WriteWord(R, gvdata[i].adr); INC(i) END; (*global variables fixup data*)
    WriteFixup(R, varFixupCond, objFixupAction); (*variable fixup data*)
    (*local strings fixup data*)
    suax := maxStrx; sx := 0;
    FOR i := 1 TO nofstrs DO
      DEC(suax, 2); fixadr := ORD(strdata[suax]) + ORD(strdata[suax + 1])*100H;
      IF fixadr # 0 THEN WriteWord(R, fixadr); Files.WriteByte(R, 0); WriteWord(R, sx + tdx*WordSize (*skip td*)) END;
      WHILE strdata[sx] # 0X DO INC(sx) END; REPEAT INC(sx) UNTIL sx MOD WordSize = 0
    END;
    WriteFixup(R, constFixupCond, constFixupAction); (*fixup data for references to constants in code*)
    WriteFixup(R, typFixupCond, typFixupAction); (*fixup data for type extension*)
    WriteWord(R, entry);
    Files.Write(R, "O"); Files.Register(F);
    (*write object addresses to source position mapping in .o43 file*)
    B.MakeFileName(name, modid, ".o43"); F := Files.New(name); Files.Set(R, F, 0); WriteWord(R, mcode.pc DIV 2); sx := 1;
    FOR i := 1 TO mcode.pc DIV 2 - 1 DO 
      IF (sx < 255) & (mcode.pos[i] = mcode.pos[i-1]) THEN INC(sx) ELSE Files.WriteByte(R, sx); Files.WriteInt(R, mcode.pos[i - 1]); sx := 1 END
    END; Files.WriteByte(R, sx); Files.WriteInt(R, mcode.pos[mcode.pc DIV 2 - 1]); Files.Register(F);
    (*write word offset with caller top of stack*)
    OfsPTOS(-1, -1, FALSE); (*close last segment*) B.MakeFileName(name, modid, ".r43"); F := Files.New(name); Files.Set(R, F, 0); 
    Files.WriteInt(R, frmOfsSegs.NofSegs);
    FOR i := 0 TO frmOfsSegs.NofSegs DO Files.WriteInt(R, frmOfsSegs.Segs[i].end); Files.WriteInt(R, frmOfsSegs.Segs[i].ofsptos) END;
    Files.Register(F)
  END Close;

  PROCEDURE initConst(VAR c: Item; v: INTEGER);
  BEGIN c.reg := 0; c.am := A.Immediate; c.ofs := v; c.obj := NIL; c.type := B.intType; c.rdo := TRUE;
    c.mode := B.Const; c.tmp := FALSE; c.a := v
  END initConst;

  PROCEDURE initReg(VAR c: Item; r: BYTE);
  BEGIN c.reg := r; c.am := A.Register; c.ofs := 0; c.obj := NIL; c.type := B.intType;
    c.mode := Reg; c.tmp := FALSE; c.a := 0
  END initReg;

BEGIN A.SetProcs(GetOffset, AllocR, freeR);
  initConst(cm1, -1); initConst(c0, 0); initConst(c1, 1); initConst(c2, 2);
  initReg(pc, A.PC); initReg(sp, A.SP); initReg(sr, A.SR); initReg(cg2, 3); initReg(r4, 4); initReg(r15, 15);
  relmap[0] := A.EQ; relmap[1] := A.NE; relmap[2] := A.L; relmap[3] := A.GE;
  urelmap[0] := A.EQ; urelmap[1] := A.NE; urelmap[2] := A.NC; urelmap[3] := A.C;
  B.SetRegRTProcCallback(RegisterRTproc)
END OMSPG.
