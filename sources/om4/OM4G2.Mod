MODULE OM4G2; (* N.Wirth, 16.4.2016 / 4.4.2017 / 31.5.2019  Oberon compiler;
  C. Schoffit 19/10/2023 code generator for Cortex M4 STM32I-DISCO*)
  IMPORT SYSTEM, Files, A := OM4A2, S := OM4S2, B := OM4B2;
  (*Code generator for Oberon compiler targetting Cortex M4F processor.
     Procedural interface to Parser OM4P; result in record "code".
     Procedure Close writes code-files*)

  CONST WordSize* = 4;
    SP = 13; LR = 14; PC = 15; (*dedicated registers*)
    MSP = 8; PSP = 9;
    APSRnzcv = 15; (*APSR_nzcv is encoded as <Rt> = '1111'*)
    NBS = 32; (* Number of single float registers in the FPU bank *)
    VarORG0 = 0D0201000H;  (*for bare metal program only, 
    0D0200400H is the end address of VGA buffers*)
    maxStrx = 3000; maxTD = 160; maxFOS = 1000;
    
    Reg = 10; RegI = 11; Cond = 12; FPReg = 13; (*internal item modes*)

  TYPE Item* = RECORD
    mode*: INTEGER;
    type*: B.Type;
    a*: LONGINT; b*, r*: INTEGER;
    rdo*: BOOLEAN  (*read only*)
  END ;

  (* Item forms and meaning of fields:
    mode    r      a       b
    ---------------------------------
    Const   -      value   (proc adr)  (immediate value)
    Var     base   off     -           (direct adr)
    Par      -     off0    off1        (indirect adr)
    Reg     regno
    FPReg   regno
    RegI    regno  off     -
    Cond    cond   Fchain  Tchain  *)

    FrameOffsetSegment = RECORD
      end, ofsptos (*offset with previous top of stack*): INTEGER
    END;

    FrameOffset = RECORD
      NofSegs: INTEGER;
      Segs: ARRAY maxFOS OF FrameOffsetSegment
    END;

  VAR varsize: INTEGER;   (*data index*)
    tdx, strx: INTEGER;
    entry: INTEGER;   (*main entry point*)
    RH: INTEGER;      (*in use registers R[0] ... R[H-1]*)
    RL: INTEGER; (*register limit*)
    SH: INTEGER;      (*in use floating point registers S[0] ... S[H-1]*)
    frame: INTEGER;   (*frame offset changed in SaveRegs and RestoreRegs*)
    fixORGP, fixORGD, fixORGT: INTEGER;   (*origins of lists of locations to be fixed up by loader*)
    check*: BOOLEAN;   (*emit run-time checks*)
    version: INTEGER; (*0 = bare metal program, 1 = oberon system module*)
    
    relmap: ARRAY 6 OF INTEGER;    (*condition codes for relations*)
    data: ARRAY maxTD OF INTEGER;  (*type descriptors*)
    str: ARRAY maxStrx OF CHAR;
    mcode: A.ModuleCode;
    frmOfsSegs: FrameOffset;

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

  PROCEDURE FixOne*(at: INTEGER);
  BEGIN A.FixOne(mcode, at)
  END FixOne;

  PROCEDURE FixLink*(L: INTEGER);
  BEGIN
    A.FixLink(mcode, L)
  END FixLink;

  PROCEDURE incR;
  BEGIN
    IF RH < RL-1 THEN INC(RH) ELSE S.Mark("register stack overflow"); RH := 8 END
  END incR;

  PROCEDURE dincR;
  BEGIN incR; incR
  END dincR;

  PROCEDURE incS;
  BEGIN
    IF SH < NBS-1 THEN INC(SH) ELSE S.Mark("FP register stack overflow") END
  END incS;

  PROCEDURE SetRH*(r: BYTE);
  BEGIN
    ASSERT(r < A.C4);
    RH := r
  END SetRH;
  
  PROCEDURE CheckRegs*;
  BEGIN
    IF RH # 0 THEN S.Mark("Reg Stack"); RH := 0 END ;
    IF SH # 0 THEN S.Mark("FP Reg Stack"); SH := 0 END ;
    IF mcode.pc >= A.maxCode - 40 THEN S.Mark("program too long") END ;
    IF frame # 0 THEN S.Mark("frame error"); frame := 0 END
  END CheckRegs;

  PROCEDURE SetCC(VAR x: Item; n: INTEGER);
  BEGIN x.mode := Cond; x.a := 0; x.b := 0; x.r := n
  END SetCC;

  PROCEDURE Trap(cond, num: INTEGER);
  (*
    Trap is implemented as a coprocessor instruction targeting a
    non existing coprocessor, i.e. not CP10 or CP11 assocatied to FPU.
    The encoding is 1110/11xx/xxxx/xxxx/xxxx/0xxx/xxxx/xxxx, that leaves 25 bits
    for describing the trap number and file position.
    
    In this implementation, 24 bits will be used, like in RISC-5 code:
    1110/110p/pppp/pppp/pppp/0ppp/pppp/nnnn
    This will generate an exception trapped by the usage fault handler 
    implemented as the trap procedure of the System module.
  *)
  VAR pos: INTEGER;
  BEGIN 
    IF cond # A.AL THEN A.IfThen(mcode, "", cond) END;
    pos := S.Pos();
    ASSERT(pos < A.C20);
    ASSERT(num < A.C4);
    A.Put0(mcode, A.CoP + pos DIV A.C7*A.C12 + pos MOD A.C7*A.C4 + num)
  END Trap;

  (*  Format of pseudo operations for accessing static vars and procs

    These pseudo-instructions will be fixup at load or link time by
    the Modules or OM4L modules.

  1/ Variables (entire address space is accessible)
    We'll use pseudo  MOV and MOVT instructions and encode the fixup link in the pseudo MOV instruction.

    a/ Getting lower 16-bits of absolute address
    MOV a, #imm16:
    aaaa/nnnn/dddd/dddd/dddd/dddd/dddd/dddd
    
    aaaa: destination register
    nnnn: number of the module
    dd24: offset DIV 2 of next op to fix for runtime absolute address
    
    b/ Getting higher 16-bits of absolute address
    MOVT a, #imm16
     
    if nnnn < 0
    0000/0000/0000/0000/0000/000p/vvvv/vvvv
    a:    specified in previous instruction
    p:    program based procedure
    vvv8: number of the variable or procedure
    
    else if nnnn = 0, object cannot be a constant procedure
    00000000/oooo/oooo/oooo/oooo/oooo/oooo
    oo24: offset of the variable
  
  2/ Procedures (entire address space is accessible with veneer code
                 when needed)
    BL <proc address>:
    
    nnnn/pppp/pppp/dddd/dddd/dddd/dddd/dddd

    nnnn:     number of the module
    pppppppp: number of the procedure
    dd20: offset DIV 2 of next op to fix for procedure address loading
    
*)

  PROCEDURE GetStaticVarAddress(x: Item; a: BYTE);
    VAR progbaseIndic: INTEGER;
  BEGIN    
    ASSERT((x.r <= 0) & (a < 13));
    IF mcode.pc-fixORGD > A.C25 THEN S.Mark("too many instruction between static access") END;
    (* MOV a, #imm16 *)
    A.Put0(mcode, a*A.C28 + (-x.r)*A.C24 + (mcode.pc-fixORGD) DIV A.C1);
    fixORGD := mcode.pc-4;
    (*If x.r = 0, x.a contains the offset of the variable computed at compile time,
      else if x.r < 0, x.a contains the variable or procedure number and the base indicator*)
    IF (x.type # NIL) & (x.type.form = B.Proc) & (x.r < 0) THEN progbaseIndic := A.C8 
    ELSE progbaseIndic := 0 END;
    (* MOVT a, #imm16 *)
    A.Put0(mcode, progbaseIndic + x.a)
  END GetStaticVarAddress;
  
  PROCEDURE NilCheck(a: BYTE);
  BEGIN
    IF check THEN
      IF ~mcode.lastInstrSetFlags THEN  incR; A.encCMPImm(mcode, a, RH, 0); DEC(RH) END ;
      Trap(A.EQ, 4) 
    END
  END NilCheck;

  (* loading of operands and addresses into registers *)

  PROCEDURE doLoad(VAR x: Item; target: INTEGER);
    VAR op, pc0, pc1: INTEGER;
  BEGIN
    ASSERT(target IN {Reg, FPReg});
    ASSERT((target # FPReg) OR (x.type.form = B.Real));
    IF x.type.size = 1 THEN op := A.LDRB ELSE op := A.LDR END ;
    IF x.mode # target THEN
      IF x.mode = B.Const THEN
        IF x.type.form = B.Proc THEN
          IF x.r > 0 THEN S.Mark("not allowed")
          ELSIF x.r = 0 THEN 
            (*optimisation possible : si align(PC+4, 4) - x.a < 4096 on peut 
              utiliser l'equivalent de l'assembleur ADR RH, <label>*)
            A.Put0(mcode, A.BL + A.formatEvenImm25(0)); (*Put address+1 of next statement in LR*)
            A.encDPImm32(mcode, A.SUB, RH, LR, RH, mcode.pc - x.a)
          ELSE GetStaticVarAddress(x, RH) 
          END;
          x.r := RH; incR
        ELSE
          IF x.type.size = 8 THEN (* LONGINT *) A.encMOVImm64(mcode, RH, RH + 1, x.a); x.r := RH; dincR
          ELSE A.encMOVImm32(mcode, RH, x.a);
            IF target = FPReg THEN
              A.encFPMOVReg(mcode, A.VMOVSR, RH, SH);
              x.r := SH; incS
            ELSE x.r := RH; incR
            END
          END
        END;
      ELSIF x.mode = B.Var THEN
        IF x.r > 0 THEN (*local*) 
          IF target = FPReg THEN ASSERT((x.a + frame) MOD A.C2 = 0);
            IF x.a + frame >= A.C10 THEN S.Mark("local real var too far") END;
            A.Put0(mcode, A.VLDRT2 + 1*A.C23 + SH MOD A.C1*A.C22 + SP*A.C16 + SH DIV A.C1*A.C12 + (x.a + frame) DIV A.C2);
            x.r := SH; incS
          ELSIF x.type.size = 8 THEN (* LONGINT *) dincR; A.encDMemImm32(mcode, A.LDRD, RH-2, RH-1, SP, RH, x.a + frame); x.r := RH-2
          ELSE incR; A.encMemImm32(mcode, op, RH-1, SP, RH, x.a + frame); x.r := RH-1
          END
        ELSE GetStaticVarAddress(x, RH); x.mode := RegI; x.r := RH; x.a := 0; incR; doLoad(x, target)
        END
      ELSIF x.mode = B.Par THEN
        incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a + frame); DEC(RH);
        IF target = FPReg THEN ASSERT((x.b) MOD A.C2 = 0);
          IF x.b >= A.C10 THEN S.Mark("real param offset 1 too far") END;
          A.Put0(mcode, A.VLDRT2 + 1*A.C23 + SH MOD A.C1*A.C22 + RH*A.C16 + SH DIV A.C1*A.C12 + x.b DIV A.C2);
          x.r := SH; incS
        ELSIF x.type.size = 8 THEN (* LONGINT *) dincR; A.encDMemImm32(mcode, A.LDRD, RH-2, RH-1, RH-2, RH, x.b); x.r := RH-2
        ELSE incR; A.encMemImm32(mcode, op, RH-1, RH-1, RH, x.b); x.r := RH-1
        END
      ELSIF x.mode = RegI THEN 
        IF target = FPReg THEN ASSERT(x.a MOD A.C2 = 0);
          IF x.a >= A.C10 THEN S.Mark("real RegI too far") END;
          A.Put0(mcode, A.VLDRT2 + 1*A.C23 + SH MOD A.C1*A.C22 + x.r*A.C16 + SH DIV A.C1*A.C12 + x.a DIV A.C2);
          x.r := SH; incS; DEC(RH)
        ELSIF x.type.size = 8 THEN (*LONGINT*) incR; A.encDMemImm32(mcode, A.LDRD, x.r, x.r+1, x.r, RH, x.a)
        ELSE  A.encMemImm32(mcode, op, x.r, x.r, RH, x.a)
        END
      ELSIF x.mode = Cond THEN
        IF (x.a = 0) & (x.b = 0) THEN (*No "false" or "true" chains*)
          A.IfThen(mcode, "E", x.r);
          A.encMOVImm32(mcode, RH, 1);
          A.encMOVImm32(mcode, RH, 0)
        ELSE (*A "true" and/or "false" chain need to be fixed, do it the classical way*)
          pc0 := mcode.pc; A.Put1(mcode, A.BCT1 + A.negated(x.r)*A.C8);
          FixLink(x.b); A.encMOVImm32(mcode, RH, 1); pc1 := mcode.pc; A.Put1(mcode, A.BT2);
          A.fix8(mcode, pc0, mcode.pc - pc0 - 4); FixLink(x.a); A.encMOVImm32(mcode, RH, 0);
          A.fix11(mcode, pc1, mcode.pc - pc1 - 4);
        END;
        x.r := RH; incR
      ELSIF x.mode = Reg THEN A.encFPMOVReg(mcode, A.VMOVSR, x.r, SH) (*Reg to FPReg*); x.r := SH; incS; DEC(RH)
      ELSIF x.mode = FPReg THEN A.encFPMOVReg(mcode, A.VMOVRS, RH, x.r) (*FPReg to Reg*); x.r := RH; incR; DEC(SH)
      END;
      x.mode := target
    END
  END doLoad;

  PROCEDURE load(VAR x: Item); (*Load item in top core register*)
  BEGIN doLoad(x, Reg);
  END load;
  
  PROCEDURE loadFP(VAR x: Item); (*Load item in top FPU register*)
  BEGIN doLoad(x, FPReg);
  END loadFP;
  
  PROCEDURE loadAdr(VAR x: Item);
  BEGIN
    IF x.mode = B.Var THEN
      IF x.r > 0 THEN (*local*) A.encDPImm32(mcode, A.ADD, RH, SP, RH, x.a + frame)
      ELSE GetStaticVarAddress(x, RH) 
      END;
      x.r := RH; incR
    ELSIF x.mode = B.Par THEN incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a + frame); DEC(RH);
      IF x.b # 0 THEN incR; A.encDPImm32(mcode, A.ADD, RH-1, RH-1, RH, x.b); DEC(RH) END;
      x.r := RH; incR
    ELSIF x.mode = RegI THEN
      IF x.a # 0 THEN A.encDPImm32(mcode, A.ADD, x.r, x.r, RH, x.a) END
    ELSE S.Mark("address error")
    END;
    x.mode := Reg
  END loadAdr;

  PROCEDURE loadCond(VAR x: Item);
  BEGIN
    IF x.type.form = B.Bool THEN
      IF x.mode = B.Const THEN IF x.a = 0 THEN x.r := A.NV ELSE x.r := A.AL END
      ELSE load(x);
        IF ~mcode.lastInstrSetFlags THEN A.encCMPImm(mcode, x.r, RH, 0) END;
        x.r := A.NE; DEC(RH)
      END ;
      x.mode := Cond; x.a := 0; x.b := 0
    ELSE S.Mark("not Boolean?")
    END
  END loadCond;

  PROCEDURE loadTypTagAdr(T: B.Type);
    VAR x!: Item;
  BEGIN x.mode := B.Var; x.type := NIL; x.a := T.len; x.r := -T.mno; loadAdr(x)
  END loadTypTagAdr;

  PROCEDURE loadStringAdr(VAR x: Item);
  BEGIN 
    IF x.r =  0 THEN x.a := varsize+x.a END; GetStaticVarAddress(x, RH);
    incR; x.mode := Reg; x.r := RH-1
  END loadStringAdr;

  (* Items: Conversion from constants or from Objects on the Heap to Items on the Stack*)

  PROCEDURE MakeConstItem*(VAR x: Item; typ: B.Type; val: INTEGER);
  BEGIN x.mode := B.Const; x.type := typ; x.a := val
  END MakeConstItem;

  PROCEDURE MakeRealItem*(VAR x: Item; val: REAL);
  BEGIN x.mode := B.Const; x.type := B.realType; x.a := SYSTEM.VAL(INTEGER, val)
  END MakeRealItem;

  PROCEDURE MakeStringItem*(VAR x: Item); (*copies string from OM4S-buffer to OM4G-string array*)
    VAR i, len: INTEGER;
  BEGIN len := S.slen; x.mode := B.Const; x.type := B.strType; x.a := strx; x.r := 0; x.b := len; i := 0;
    IF strx + len + 4 < maxStrx THEN
      WHILE len > 0 DO str[strx] := S.str[i]; INC(strx); INC(i); DEC(len) END ;
      WHILE strx MOD 4 # 0 DO str[strx] := 0X; INC(strx) END
    ELSE S.Mark("too many strings")
    END
  END MakeStringItem;

  PROCEDURE MakeItem*(VAR x: Item; y: B.Object; curlev: INTEGER);
  BEGIN x.mode := y.class; x.type := y.type; x.a := y.val; x.rdo := y.rdo; x.r := y.lev;
    IF y.class = B.Par THEN x.b := 0
    ELSIF (y.class = B.Const) & (y.type.form = B.String) THEN
      x.a := y.val MOD 10000H; x.b := y.val DIV 10000H MOD 10000H (*len*)
    END;
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
    VAR s, lim, p2: INTEGER;
  BEGIN s := x.type.base.size; 
    IF s=0 THEN S.Mark("Invalid array item size")
    ELSE
      lim := x.type.len;
      IF (y.mode = B.Const) & (lim >= 0) THEN
        IF (y.a < 0) OR (y.a >= lim) THEN S.Mark("bad index") END ;
        IF (x.mode # B.Var) OR (x.r >= 0) OR (y.a = 0) THEN
          IF x.mode IN {B.Var, RegI} THEN INC(x.a, y.a * s)
          ELSIF x.mode = B.Par THEN x.b := y.a * s + x.b
          END
        ELSE GetStaticVarAddress(x, RH); x.mode := RegI; x.r := RH; x.a := y.a * s; incR
        END
      ELSE load(y);
        IF check THEN  (*check array bounds*)
          IF lim >= 0 THEN A.encCMPImm(mcode, y.r, RH, lim)
          ELSE (*open array*)
            IF x.mode IN {B.Var, B.Par} THEN
              incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a + 4 + frame); DEC(RH);
              A.encCMPReg(mcode, y.r, RH)
            ELSE S.Mark("error in Index")
            END
          END ;
          Trap(A.CS, 1) (*ARM inverts the carry with SUB and CMP instructions*)
        END ;
        (* Compute the shift to apply when s is a power of two *)
        IF A.log2(s, p2) # 1 THEN A.encMOVImm32(mcode, RH, s);
          A.encMUL(mcode, y.r, y.r, RH); p2 := 0
        END ;
        IF x.mode = B.Var THEN
          IF x.r > 0 THEN A.encDPReg(mcode, A.ADD, y.r, SP, y.r, A.LSl, p2, TRUE); INC(x.a, frame)
          ELSE GetStaticVarAddress(x, RH);
            A.encDPReg(mcode, A.ADD, y.r, RH, y.r, A.LSl, p2, TRUE); x.a := 0
          END ;
          x.r := y.r; x.mode := RegI
        ELSIF x.mode = B.Par THEN
          incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a + frame); DEC(RH);
          A.encDPReg(mcode, A.ADD, y.r, RH, y.r, A.LSl, p2, TRUE); x.mode := RegI; x.r := y.r; x.a := x.b
        ELSIF x.mode = RegI THEN
          A.encDPReg(mcode, A.ADD, x.r, x.r, y.r, A.LSl, p2, TRUE); DEC(RH)
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

  PROCEDURE Q(T: B.Type; VAR dcw: INTEGER);
  BEGIN (*one entry of type descriptor extension table*)
    IF T.base # NIL THEN
      ASSERT((T.mno >= 0) & (T.mno < 256));
      ASSERT((T.len >= 0) & (T.len < 1000H));
      ASSERT((dcw - fixORGT >= 0) & (dcw - fixORGT < 1000H));
      Q(T.base, dcw); data[dcw] := (T.mno*1000H + T.len) * 1000H + dcw - fixORGT;
      fixORGT := dcw; INC(dcw)
    END
  END Q;

  PROCEDURE FindPtrFlds(typ: B.Type; off: INTEGER; VAR dcw: INTEGER);
    VAR fld!: B.Object; i, s: INTEGER;
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

  PROCEDURE BuildTD*(T: B.Type; VAR dc: INTEGER);
    VAR dcw, k, s: INTEGER;  (*dcw = word address*)
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
    VAR pc0: INTEGER;
  BEGIN
    IF ~check OR (T = NIL) THEN
      IF x.mode >= Reg THEN DEC(RH) END ;
      SetCC(x, A.AL)
    ELSE (*fetch tag into RH*)
      IF varpar THEN incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a+4+frame); DEC(RH)
      ELSE load(x);
        IF ~mcode.lastInstrSetFlags THEN A.encCMPImm(mcode, x.r, RH, 0) END ;
        pc0 := mcode.pc; A.Put1(mcode, A.BCT1 + A.EQ*A.C8);  (*NIL belongs to every pointer type*)
        incR; A.encMemImm32(mcode, A.LDR, RH-1, x.r, RH, -8); DEC(RH)
      END;
      incR; A.encMemImm32(mcode, A.LDR, RH-1, RH-1, RH, T.nofpar*4);
      loadTypTagAdr(T);  (*tag of T*)
      A.encCMPReg(mcode, RH-1, RH-2); DEC(RH, 2);
      IF isguard THEN
        IF check THEN Trap(A.NE, 2) END
      ELSE SetCC(x, A.EQ);
        IF ~varpar THEN DEC(RH) END
      END;
      IF ~varpar THEN A.fix8(mcode, pc0, mcode.pc - pc0 - 4) END
    END
  END TypeTest;

  (* Code generation for Boolean operators *)

  PROCEDURE Not*(VAR x: Item);   (* x := ~x *)
    VAR t: INTEGER;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    x.r := A.negated(x.r); t := x.a; x.a := x.b; x.b := t
  END Not;

  PROCEDURE And1*(VAR x: Item);   (* x := x & *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.Put0(mcode, A.BRCSIG*A.C27 + A.negated(x.r)*A.C22 + x.a);
    x.a := mcode.pc-4; A.FixLink(mcode, x.b); x.b := 0
  END And1;

  PROCEDURE And2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := A.merged(mcode, y.a, x.a); x.b := y.b; x.r := y.r
  END And2;

  PROCEDURE Or1*(VAR x: Item);   (* x := x OR *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.Put0(mcode, A.BRCSIG*A.C27 + x.r*A.C22 + x.b);
    x.b := mcode.pc-4; A.FixLink(mcode, x.a); x.a := 0
  END Or1;

  PROCEDURE Or2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := y.a; x.b := A.merged(mcode, y.b, x.b); x.r := y.r
  END Or2;

  (* Code generation for arithmetic operators *)

  PROCEDURE convertInt(VAR x: Item; t: B.Type);
  BEGIN
    IF x.type.form = B.Int THEN ASSERT(t.form = B.Int);
      IF x.type # t THEN
        IF (t = B.longintType) & (x.mode # B.Const) THEN load(x); ASSERT(x.r = RH-1); incR;
          A.Put0(mcode, A.SBFX + x.r*A.C16 + (x.r+1)*A.C8 + 31 DIV A.C2*A.C12 + 31 MOD A.C2*A.C6 + 0); (*SBFX x.r+1, x.r, 31, 1*)
          x.type := t
        ELSE x.type := t; load(x)
        END
      END
    END
  END convertInt;

  PROCEDURE Neg*(VAR x: Item);   (* x := -x *)
  BEGIN
    IF x.type.form IN {B.Int, B.LongInt} THEN
      IF x.mode = B.Const THEN x.a := -x.a
      ELSE load(x);
        IF x.type.size = 8 THEN incR; A.encMOVImm32(mcode, RH-1, 0);
          A.encDPImm32(mcode, A.RSB, x.r, x.r, RH, 0); A.encDPReg(mcode, A.SBc, x.r+1, RH-1, x.r+1, A.LSl, 0, TRUE); DEC(RH)
        ELSE A.encDPImm32(mcode, A.RSB, x.r, x.r, RH, 0);
        END;
      END
    ELSIF x.type.form = B.Real THEN
      IF x.mode = B.Const THEN x.a := x.a + 7FFFFFFFH + 1
      ELSE loadFP(x); A.encFPOpReg(mcode, A.VNEG, x.r, 0, x.r)
      END
    ELSE (*form = Set*)
      IF x.mode = B.Const THEN x.a := -x.a-1 
      ELSE load(x); A.encDPImm32(mcode, A.EOR, x.r, x.r, RH, -1)
      END
    END
  END Neg;

  PROCEDURE AddOp*(op: INTEGER; VAR x, y: Item);   (* x := x +- y *)
    VAR xr: BYTE;
  BEGIN convertInt(y, x.type);
    IF op = S.plus THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a + y.a
      ELSIF y.mode = B.Const THEN load(x);
        IF y.a # 0 THEN A.encDPImm32(mcode, A.ADD, x.r, x.r, RH, y.a);
          IF x.type.size = 8 THEN A.encDPImm32(mcode, A.ADc, x.r+1, x.r+1, RH, (* y.a TODO DIV 100000000H*)0) END
        END
      ELSE load(x); load(y); IF x.r < y.r THEN xr := x.r ELSE xr := y.r END;
        A.encDPReg(mcode, A.ADD, xr, x.r, y.r, A.LSl, 0, TRUE);
        IF x.type.size = 8 THEN  A.encDPReg(mcode, A.ADc, xr+1, x.r+1, y.r+1, A.LSl, 0, TRUE); DEC(RH)
        END; x.r := xr; DEC(RH)
      END
    ELSE (*op = S.minus*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a - y.a
      ELSIF y.mode = B.Const THEN load(x);
        IF y.a # 0 THEN A.encDPImm32(mcode, A.SUB, x.r, x.r, RH, y.a) END;
          IF x.type.size = 8 THEN A.encDPImm32(mcode, A.SBc, x.r+1, x.r+1, RH, (* y.a TODO DIV 100000000H*)0) END
      ELSE load(x); load(y); IF x.r < y.r THEN xr := x.r ELSE xr := y.r END;
        A.encDPReg(mcode, A.SUB, xr, x.r, y.r, A.LSl, 0, TRUE);
        IF x.type.size = 8 THEN A.encDPReg(mcode, A.SBc, xr+1, x.r+1, y.r+1, A.LSl, 0, TRUE); DEC(RH)
        END; x.r := xr; DEC(RH)
      END
    END
  END AddOp;

  PROCEDURE Lsl(VAR x, y: Item);
  BEGIN load(x);
    IF y.mode = B.Const THEN
      IF y.a <= 0 THEN S.Mark("shift amount must be positive")
      ELSIF y.a < 32 THEN
        IF x.type.size = 8 THEN A.encShiftImm5(mcode, A.LSl, x.r+1, x.r+1, y.a); A.encDPReg(mcode, A.ORR, x.r+1, x.r+1, x.r, A.LSr, 32-y.a, TRUE) END;
        A.encShiftImm5(mcode, A.LSl, x.r, x.r, y.a)
      ELSIF y.a < 64 THEN
        IF x.type.size = 8 THEN A.encShiftImm5(mcode, A.LSl, x.r+1, x.r, y.a-32) END;
        A.encMOVImm32(mcode, x.r, 0)
      ELSE
        IF x.type.size = 8 THEN A.encMOVImm32(mcode, x.r+1, 0) END;
        A.encMOVImm32(mcode, x.r, 0)
      END
    ELSE load(y); ASSERT(x.r < y.r);
      IF x.type.size = 8 THEN
        dincR; A.encDPImm32(mcode, A.SUB, RH-1, y.r, RH, 32); A.encShiftReg(mcode, A.LSl, RH-1, x.r, RH-1, TRUE);
        A.encDPImm32(mcode, A.RSB, RH-2, y.r, RH, 32); A.encShiftReg(mcode, A.LSl, x.r+1, x.r+1, y.r, TRUE);
        A.encShiftReg(mcode, A.LSr, RH-2, x.r, RH-2, TRUE); A.encDPReg(mcode, A.ORR, x.r+1, x.r+1, RH-1, A.LSl, 0, TRUE);
        A.encShiftReg(mcode, A.LSl, x.r, x.r, y.r, TRUE); A.encDPReg(mcode, A.ORR, x.r+1, x.r+1, RH-2, A.LSl, 0, TRUE); DEC(RH, 3)
      ELSE A.encShiftReg(mcode, A.LSl, x.r, x.r, y.r, TRUE); DEC(RH)
      END
    END;
  END Lsl;

  PROCEDURE Lsr(VAR x, y: Item);
  BEGIN load(x);
    IF y.mode = B.Const THEN
      IF y.a <= 0 THEN S.Mark("shift amount must be positive")
      ELSIF y.a < 32 THEN A.encShiftImm5(mcode, A.LSr, x.r, x.r, y.a);
        IF x.type.size = 8 THEN A.encDPReg(mcode, A.ORR, x.r, x.r, x.r+1, A.LSl, 32-y.a, TRUE); A.encShiftImm5(mcode, A.LSr, x.r+1, x.r+1, y.a) END
      ELSIF y.a = 32 THEN A.encMOVReg(mcode, x.r, x.r+1); A.encMOVImm32(mcode, x.r+1, 0)
      ELSIF y.a < 64 THEN
        IF x.type.size = 8 THEN A.encShiftImm5(mcode, A.LSr, x.r, x.r+1, y.a-32); A.encMOVImm32(mcode, x.r+1, 0)
        ELSE A.encMOVImm32(mcode, x.r, 0)
        END
      ELSE
        IF x.type.size = 8 THEN A.encMOVImm32(mcode, x.r+1, 0) END;
        A.encMOVImm32(mcode, x.r, 0)
      END
    ELSE load(y); ASSERT(x.r < y.r);
      IF x.type.size = 8 THEN
        dincR; A.encDPImm32(mcode, A.RSB, RH-1, y.r, RH, 32); A.encShiftReg(mcode, A.LSl, RH-1, x.r+1, RH-1, TRUE);
        A.encDPImm32(mcode, A.SUB, RH-2, y.r, RH, 32); A.encShiftReg(mcode, A.LSr, x.r, x.r, y.r, TRUE);
        A.encShiftReg(mcode, A.LSr, RH-2, x.r+1, RH-2, TRUE); A.encDPReg(mcode, A.ORR, x.r, x.r, RH-1, A.LSl, 0, TRUE);
        A.encDPReg(mcode, A.ORR, x.r, x.r, RH-2, A.LSl, 0, TRUE); A.encShiftReg(mcode, A.LSr, x.r+1, x.r+1, y.r, TRUE); DEC(RH, 3)
      ELSE A.encShiftReg(mcode, A.LSr, x.r, x.r, y.r, TRUE); DEC(RH)
      END
    END;
  END Lsr;

  PROCEDURE Asr(VAR x, y: Item);
  BEGIN load(x);
    IF y.mode = B.Const THEN
      IF y.a <= 0 THEN S.Mark("shift amount must be positive")
      ELSIF y.a < 32 THEN
        IF x.type.size = 8 THEN A.encShiftImm5(mcode, A.LSr, x.r, x.r, y.a);
          A.encDPReg(mcode, A.ORR, x.r, x.r, x.r+1, A.LSl, 32-y.a, TRUE); A.encShiftImm5(mcode, A.ASr, x.r+1, x.r+1, y.a)
        ELSE A.encShiftImm5(mcode, A.ASr, x.r, x.r, y.a)
        END
      ELSIF y.a = 32 THEN A.encMOVReg(mcode, x.r, x.r+1); A.encShiftImm5(mcode, A.ASr, x.r+1, x.r+1, 31)
      ELSIF y.a < 64 THEN
        IF x.type.size = 8 THEN A.encShiftImm5(mcode, A.ASr, x.r, x.r+1, y.a-32); A.encShiftImm5(mcode, A.ASr, x.r+1, x.r+1, 31)
        ELSE A.encMOVImm32(mcode, x.r, 0)
        END
      ELSE
        IF x.type.size = 8 THEN A.encShiftImm5(mcode, A.ASr, x.r+1, x.r+1, 31); A.encMOVReg(mcode, x.r, x.r+1)
        ELSE A.encShiftImm5(mcode, A.ASr, x.r, x.r, 31)
        END
      END
    ELSE load(y); ASSERT(x.r < y.r);
      IF x.type.size = 8 THEN
        dincR; A.encDPImm32(mcode, A.RSB, RH-1, y.r, RH, 32); A.encShiftReg(mcode, A.LSl, RH-1, x.r+1, RH-1, TRUE);
        A.encDPImm32(mcode, A.SUB, RH-2, y.r, RH, 32); A.encShiftReg(mcode, A.LSr, x.r, x.r, y.r, FALSE);
        A.IfThen(mcode, "", A.PL); A.encShiftReg(mcode, A.ASr, RH-2, x.r+1, RH-2, FALSE);
        A.encDPReg(mcode, A.ORR, x.r, x.r, RH-1, A.LSl, 0, FALSE);
        A.IfThen(mcode, "", A.PL); A.encDPReg(mcode, A.ORR, x.r, x.r, RH-2, A.LSl, 0, FALSE);
        A.encShiftReg(mcode, A.ASr, x.r+1, x.r+1, y.r, TRUE); DEC(RH, 3)
      ELSE A.encShiftReg(mcode, A.ASr, x.r, x.r, y.r, TRUE); DEC(RH)
      END
    END;
  END Asr;

  PROCEDURE MulOp*(VAR x, y: Item);   (* x := x * y *)
    VAR e, xr: INTEGER;
  BEGIN convertInt(y, x.type);
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN x.a := x.a * y.a
    ELSIF (y.mode = B.Const) & (y.a >= 2) & (A.log2(y.a, e) = 1) THEN y.a := e; Lsl(x, y)
    ELSIF (x.mode = B.Const) & (x.a >= 2) & (A.log2(x.a, e) = 1) THEN x.a := e; Lsl(y, x); x.mode := Reg; x.r := y.r
    (*Lower half 32bit of result of a multiplication (32b*32b => 32b) is the same for signed and unsigned integers*)
    ELSE load(x); load(y); IF x.r < y.r THEN xr := x.r ELSE xr := y.r END;
      IF x.type.size = 8 THEN dincR; A.encMUL(mcode, RH-2, x.r, y.r+1); A.encMUL(mcode, RH-1, x.r+1, y.r); 
          A.encDPReg(mcode, A.ADD, RH-2, RH-2, RH-1, A.LSl, 0, TRUE); A.Put0(mcode, A.UMULL + x.r*A.C16 + xr*A.C12 + (xr+1)*A.C8 + y.r);
          A.encDPReg(mcode, A.ADD, xr+1, xr+1, RH-2, A.LSl, 0, TRUE); DEC(RH, 4)
      ELSE A.encMUL(mcode, xr, x.r, y.r); DEC(RH)
      END; x.r := xr
    END
  END MulOp;

  PROCEDURE DivOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
    VAR e: INTEGER;
  BEGIN
    IF op = S.div THEN
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a DIV y.a ELSE S.Mark("bad divisor") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) & (A.log2(y.a, e) = 1) THEN load(x); A.encShiftImm5(mcode, A.ASr, x.r, x.r, e)
      ELSIF y.mode = B.Const THEN
        IF y.a > 0 THEN load(x); load(y); A.encUDIV(mcode, RH-2, x.r, y.r); DEC(RH); x.r := RH-1 ELSE S.Mark("bad divisor") END
      ELSE load(y);
        IF check THEN 
          IF ~mcode.lastInstrSetFlags THEN A.encCMPImm(mcode, y.r, RH, 0) END;
          Trap(A.LE, 6)
        END;
        load(x); A.encUDIV(mcode, RH-2, x.r, y.r); DEC(RH); x.r := RH-1
      END
    ELSE (*op = S.mod*)
      IF (x.mode = B.Const) & (y.mode = B.Const) THEN
        IF y.a > 0 THEN x.a := x.a MOD y.a ELSE S.Mark("bad modulus") END
      ELSIF (y.mode = B.Const) & (y.a >= 2) & (A.log2(y.a, e) = 1) THEN load(x);
        A.encBFC(mcode, x.r, e, 31)
      ELSIF y.mode = B.Const THEN
        IF y.a > 0 THEN load(x); load(y); 
          A.encUDIV(mcode, RH, x.r, y.r); A.encMUL(mcode, RH, RH, y.r); A.encDPReg(mcode, A.SUB, RH-2, x.r, RH, A.LSl, 0, TRUE);
          DEC(RH); x.r := RH-1
        ELSE S.Mark("bad modulus") END
      ELSE load(y);
        IF check THEN 
          IF ~mcode.lastInstrSetFlags THEN A.encCMPImm(mcode, y.r, RH, 0) END;
          Trap(A.LE, 6)
        END;
        load(x); A.encUDIV(mcode, RH, x.r, y.r); A.encMUL(mcode, RH, RH, y.r); A.encDPReg(mcode, A.SUB, RH-2, x.r, RH, A.LSl, 0, TRUE);
        DEC(RH); x.r := RH-1
      END
    END
  END DivOp;

  (* Code generation for REAL operators *)

  PROCEDURE RealOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
  BEGIN loadFP(x); loadFP(y);
    IF op = S.plus THEN A.encFPOpReg(mcode, A.VADD, SH-2, x.r, y.r)
    ELSIF op = S.minus THEN A.encFPOpReg(mcode, A.VSUB, SH-2, x.r, y.r)
    ELSIF op = S.times THEN A.encFPOpReg(mcode, A.VMUL, SH-2, x.r, y.r)
    ELSIF op = S.rdiv THEN A.encFPOpReg(mcode, A.VDIV, SH-2, x.r, y.r)
    END;
    DEC(SH); x.r := SH-1
  END RealOp;

  (* Code generation for set operators *)

  PROCEDURE Singleton*(VAR x: Item);  (* x := {x} *)
  BEGIN
    IF x.mode = B.Const THEN x.a := LSL(1, x.a)
    ELSE load(x); A.encMOVImm32(mcode, RH, 1); A.encShiftReg(mcode, A.LSl, x.r, RH,  x.r, TRUE)
    END
  END Singleton;

  PROCEDURE Set*(VAR x, y: Item);   (* x := {x .. y} *)
  BEGIN
    IF (x.mode = B.Const) & ( y.mode = B.Const) THEN
      IF x.a <= y.a THEN x.a := ORD({x.a .. y.a})(*LSL(2, y.a) - LSL(1, x.a)*) ELSE x.a := 0 END
    ELSE
      IF (x.mode = B.Const) & (x.a <= 8) THEN x.a := LSL(-1, x.a)
      ELSE load(x); A.encMOVImm32(mcode, RH, -1); A.encShiftReg(mcode, A.LSl, x.r, RH, x.r, TRUE)
      END;
      IF (y.mode = B.Const) & (y.a < 8) THEN A.encMOVImm32(mcode, RH, LSL(-2, y.a)); y.mode := Reg; y.r := RH; incR
      ELSE load(y); A.encMOVImm32(mcode, RH, -2); A.encShiftReg(mcode, A.LSl, y.r, RH, y.r, TRUE)
      END;      
      IF x.mode = B.Const THEN
        IF x.a # 0 THEN A.encDPImm32(mcode, A.EOR, y.r, y.r, RH, -1);
          A.encDPImm32(mcode, A.AND, RH-1, y.r, RH, x.a)
        END;
        x.mode := Reg; x.r := RH-1
      ELSE DEC(RH); A.encDPReg(mcode, A.BIC, x.r, x.r, y.r, A.LSl, 0, TRUE)
      END
    END
  END Set;

  PROCEDURE In*(VAR x, y: Item);  (* x := x IN y *)
  BEGIN load(y);
    IF x.mode = B.Const THEN A.encShiftImm5(mcode, A.ROr, y.r, y.r, (x.a + 1) MOD 20H); DEC(RH)
    ELSE load(x); A.encDPImm32(mcode, A.ADD, x.r, x.r, RH, 1); A.encShiftReg(mcode, A.ROr, y.r, y.r, x.r, TRUE); DEC(RH, 2)
    END ;
    SetCC(x, A.MI)
  END In;

  PROCEDURE SetOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
    VAR xset, yset: SET; (*x.type.form = Set*)
  BEGIN
    IF (x.mode = B.Const) & (y.mode = B.Const) THEN
      xset := TOSET(x.a); yset := TOSET(y.a);
      IF op = S.plus THEN xset := xset + yset
      ELSIF op = S.minus THEN xset := xset - yset
      ELSIF op = S.times THEN xset := xset * yset
      ELSIF op = S.rdiv THEN xset := xset / yset
      END ;
      x.a := SYSTEM.VAL(INTEGER, xset)
    ELSIF y.mode = B.Const THEN
      load(x);
      IF op = S.plus THEN A.encDPImm32(mcode, A.ORR, x.r, x.r, RH, y.a)
      ELSIF op = S.minus THEN A.encDPImm32(mcode, A.BIC, x.r, x.r, RH, y.a)
      ELSIF op = S.times THEN A.encDPImm32(mcode, A.AND, x.r, x.r, RH, y.a)
      ELSIF op = S.rdiv THEN A.encDPImm32(mcode, A.EOR, x.r, x.r, RH, y.a)
      END ;
    ELSE load(x); load(y);
      IF op = S.plus THEN A.encDPReg(mcode, A.ORR, RH-2, x.r, y.r, A.LSl, 0, TRUE)
      ELSIF op = S.minus THEN A.encDPReg(mcode, A.BIC, RH-2, x.r, y.r, A.LSl, 0, TRUE)
      ELSIF op = S.times THEN A.encDPReg(mcode, A.AND, RH-2, x.r, y.r, A.LSl, 0, TRUE)
      ELSIF op = S.rdiv THEN A.encDPReg(mcode, A.EOR, RH-2, x.r, y.r, A.LSl, 0, TRUE)
      END ;
      DEC(RH); x.r := RH-1
    END 
  END SetOp;

  (* Code generation for relations *)

  PROCEDURE IntCompare*(VAR x, y, z: Item);   (* x < y *)
  BEGIN
    IF (y.mode = B.Const) & (y.type.form # B.Proc) THEN
      load(x); A.encCMPImm(mcode, x.r, RH, y.a); DEC(RH)
    ELSE
      IF (x.mode = Cond) OR (y.mode = Cond) THEN S.Mark("not implemented") END ;
      load(x); load(y); A.encCMPReg(mcode, x.r, y.r); DEC(RH, 2)
    END;
    SetCC(x, z.a)
  END IntCompare;

  PROCEDURE IntRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
  BEGIN
    IF (y.mode = B.Const) & (y.type.form # B.Proc) THEN
      load(x);
      IF x.type.size = 8 THEN
        IF op IN {S.eql, S.neq} THEN A.encCMPImm(mcode, x.r+1, RH, LSR(y.a, 32)); A.IfThen(mcode, "", A.EQ);
          A.encCMPImm(mcode, x.r, RH, y.a) 
        ELSIF op = S.gtr THEN A.encCMPImm(mcode, x.r, RH, y.a+1); A.encDPImm32(mcode, A.SBc, x.r+1, x.r+1, RH, LSR(y.a+1, 32)); op := S.geq
        ELSIF op = S.leq THEN A.encCMPImm(mcode, x.r, RH, y.a+1); A.encDPImm32(mcode, A.SBc, x.r+1, x.r+1, RH, LSR(y.a+1, 32)); op := S.lss
        ELSE A.encCMPImm(mcode, x.r, RH, y.a); A.encDPImm32(mcode, A.SBc, x.r+1, x.r+1, RH, LSR(y.a, 32))
        END; DEC(RH, 2);
      ELSE IF (y.a # 0) OR ~(op IN {S.eql, S.neq}) OR ~mcode.lastInstrSetFlags THEN A.encCMPImm(mcode, x.r, RH, y.a) END; DEC(RH)
      END
    ELSE
      IF (x.mode = Cond) OR (y.mode = Cond) THEN S.Mark("not implemented") END;
      IF x.type # y.type THEN
        IF x.type = B.longintType THEN convertInt(y, x.type); load(x)
        ELSIF y.type = B.longintType THEN convertInt(x, y.type); load(y)
        END
      ELSE load(x); load(y)
      END;
      IF x.type.size = 8 THEN
        IF op IN {S.eql, S.neq} THEN A.encCMPReg(mcode, x.r+1, y.r+1); A.IfThen(mcode, "", A.EQ);
          A.encCMPReg(mcode, x.r, y.r) 
        ELSIF op = S.gtr THEN A.encCMPReg(mcode, y.r, x.r); A.encDPReg(mcode, A.SBc, y.r+1, y.r+1, x.r+1, A.LSl, 0, TRUE); op := S.lss
        ELSIF op = S.leq THEN A.encCMPReg(mcode, y.r, y.r); A.encDPReg(mcode, A.SBc, y.r+1, y.r+1, x.r+1, A.LSl, 0, TRUE); op := S.geq
        ELSE A.encCMPReg(mcode, x.r, y.r); A.encDPReg(mcode, A.SBc, x.r+1, x.r+1, y.r+1, A.LSl, 0, TRUE)
        END; DEC(RH, 4)
      ELSE A.encCMPReg(mcode, x.r, y.r); DEC(RH, 2)
      END
    END ;
    SetCC(x, relmap[op - S.eql])
  END IntRelation;

  PROCEDURE RealRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
  BEGIN loadFP(x);
    IF (y.mode = B.Const) & (y.a = 0) THEN A.encFPOpReg(mcode, A.VCMP0, x.r, 0, 0); DEC(SH)
    ELSE loadFP(y); A.encFPOpReg(mcode, A.VCMP, x.r, 0, y.r); DEC(SH, 2)
    END;
    A.Put0(mcode, A.VMRS + APSRnzcv*A.C12);
    mcode.lastInstrSetFlags := TRUE;
    SetCC(x, relmap[op - S.eql])
  END RealRelation;

  PROCEDURE StringRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
    (*x, y are char arrays or strings*)
    VAR pc0, tbf0: INTEGER;
  BEGIN
    IF x.type.form = B.String THEN loadStringAdr(x) ELSE loadAdr(x) END ;
    IF y.type.form = B.String THEN loadStringAdr(y) ELSE loadAdr(y) END ;
  (*Compare:*) pc0 := mcode.pc;
    A.encMemImm8PUW(mcode, A.LDRBIT3, RH, x.r, FALSE, TRUE, TRUE, 1);
    A.encMemImm8PUW(mcode, A.LDRBIT3, RH+1, y.r, FALSE, TRUE, TRUE, 1);
    A.encCMPReg(mcode, RH, RH+1); tbf0 := mcode.pc; A.Put1(mcode, A.BCT1 + A.NE*A.C8); (*A.BC A.NE Fin*)
    incR; A.encCMPImm(mcode, RH-1, RH, 0); DEC(RH); A.encBackBranch(mcode, A.NE, pc0); (*A.BC A.NE Compare*)
  (* Fin: *) A.fix8(mcode, tbf0, mcode.pc - tbf0 - 4);
    DEC(RH, 2); SetCC(x, relmap[op - S.eql])
  END StringRelation;

  (* Code generation of Assignments *)

  PROCEDURE StrToChar*(VAR x: Item);
  BEGIN x.type := B.charType; DEC(strx, 4); x.a := ORD(str[x.a])
  END StrToChar;

  PROCEDURE Store*(VAR x, y: Item); (* x := y *)
    VAR op: INTEGER;
  BEGIN convertInt(y, x.type); ASSERT(frame = 0);
    IF ~(y.mode IN {Reg, FPReg}) THEN
      IF y.type.form = B.Real THEN loadFP(y) ELSE load(y) END
    END;
    IF x.type.size = 1 THEN op := A.STRB ELSE op := A.STR END ;
    IF x.mode = B.Var THEN
      IF x.r > 0 THEN (*local*)
        IF y.mode = FPReg THEN ASSERT((x.a + frame) MOD A.C2 = 0);
          IF x.a + frame >= A.C10 THEN S.Mark("local real var too far")
          END;
          A.Put0(mcode, A.VSTRT2 + 1*A.C23(*ADD*) +
            y.r MOD A.C1*A.C22 + SP*A.C16 + y.r DIV A.C1*A.C12 +
            (x.a + frame) DIV A.C2)
        ELSIF x.type.size = 8 THEN (*longint*) A.encDMemImm32(mcode, A.STRD, y.r, y.r+1, SP, RH, x.a + frame)
        ELSE A.encMemImm32(mcode, op, y.r, SP, RH, x.a + frame)
        END
      ELSE GetStaticVarAddress(x, RH);
        IF y.mode = FPReg THEN
          A.Put0(mcode, A.VSTRT2 + 1*A.C23(*ADD*) +
            y.r MOD A.C1*A.C22 + RH*A.C16 + y.r DIV A.C1*A.C12)
        ELSIF x.type.size = 8 THEN (*longint*) incR; A.encDMemImm32(mcode, A.STRD, y.r, y.r+1, RH-1, RH, 0); DEC(RH)
        ELSE incR; A.encMemImm32(mcode, op, y.r, RH-1, RH, 0); DEC(RH)
        END
      END    
    ELSIF x.mode = B.Par THEN
      incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a + frame); DEC(RH);
      IF y.mode = FPReg THEN ASSERT((x.b) MOD A.C2 = 0);
        IF x.a + frame >= A.C10 THEN S.Mark("real param offset 1 too far")
        END;
        A.Put0(mcode, A.VSTRT2 + 1*A.C23 + y.r MOD A.C1*A.C22 + RH*A.C16 + y.r DIV A.C1*A.C12 + (x.b) DIV A.C2)
      ELSIF x.type.size = 8 THEN (*longint*) incR; A.encDMemImm32(mcode, A.STRD, y.r, y.r+1, RH-1, RH, x.b); DEC(RH)
      ELSE incR; A.encMemImm32(mcode, op, y.r, RH-1, RH, x.b); DEC(RH)
      END
    ELSIF x.mode = RegI THEN
S.DebugHex("RH RegI", RH);
      IF y.mode = FPReg THEN ASSERT((x.a) MOD A.C2 = 0);
        IF x.a + frame >= A.C10 THEN S.Mark("RegI too far")
        END;
        A.Put0(mcode, A.VSTRT2 + 1*A.C23 + y.r MOD A.C1*A.C22 + x.r*A.C16 + y.r DIV A.C1*A.C12 + (x.a + frame) DIV A.C2);
        DEC(SH)
      ELSE A.encMemImm32(mcode, op, y.r, x.r, RH, x.a); DEC(RH)
      END
    ELSE S.Mark("bad mode in Store")
    END;
    IF y.mode = FPReg THEN DEC(SH)
    ELSIF y.type.size = 8 THEN DEC(RH, 2)
    ELSE DEC(RH)
    END
  END Store;

  PROCEDURE StoreStruct*(VAR x, y: Item); (* x := y, frame = 0 *)
    VAR s, pc0, pc1: INTEGER;
  BEGIN
    pc0 := -1;
    IF y.type.size # 0 THEN
      loadAdr(x); loadAdr(y);
      IF (x.type.form = B.Array) &  (x.type.len > 0) THEN
        IF y.type.len >= 0 THEN 
          IF x.type.size = y.type.size THEN A.encMOVImm32(mcode, RH, (y.type.size+3) DIV 4)
          ELSE S.Mark("different length/size, not implemented")
          END
        ELSE (*y  open array*) incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, y.a+4); DEC(RH); s := y.type.base.size;  (*element size*)
          incR; A.encCMPImm(mcode ,RH-1, RH, 0); DEC(RH); pc0 := mcode.pc; A.Put1(mcode, A.BCT1 + A.EQ*A.C8); (*BEQ L0*)
          IF s = 1 THEN incR; A.encDPImm32(mcode, A.ADD, RH-1, RH-1, RH, 3); DEC(RH); A.encShiftImm5(mcode, A.ASr, RH, RH, 2)
          ELSIF s # 4 THEN ASSERT(s MOD 4 = 0); incR; A.encMOVImm32(mcode, RH, s DIV 4); A.encMUL(mcode, RH-1, RH-1, RH); DEC(RH)
          END;
          IF check THEN
            incR; A.encCMPImm(mcode, RH-1, RH, (x.type.size+3) DIV 4); Trap(A.GT, 3); DEC(RH)
          END
        END
      ELSIF x.type.form = B.Record THEN A.encMOVImm32(mcode, RH, x.type.size DIV 4)
      ELSE S.Mark("inadmissible assignment")
      END ;
      (*L1*) pc1 := mcode.pc; incR;
      A.encMemImm8PUW(mcode, A.LDRIT4, RH, y.r, FALSE, TRUE, TRUE, 4);
      A.encMemImm8PUW(mcode, A.STRIT4, RH, x.r, FALSE, TRUE, TRUE, 4);
      A.encDPImm32(mcode, A.SUB, RH-1, RH-1, RH, 1); DEC(RH);
      A.encBackBranch(mcode, A.NE, pc1); (*BNE L1*)
      (*L0:*) IF pc0 # -1 THEN A.fix8(mcode, pc0, mcode.pc - pc0 - 4) END
    END;
    RH := 0
  END StoreStruct;

  PROCEDURE CopyString*(VAR x, y: Item);  (* x := y *) 
     VAR len, pc0: INTEGER;
   BEGIN loadAdr(x); len := x.type.len;
    IF len >= 0 THEN
      IF len < y.b THEN S.Mark("string too long") END
    ELSIF check THEN incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a+4); (*open array len, frame = 0*)
      A.encCMPImm(mcode, RH-1, RH, y.b); DEC(RH); Trap(A.LT, 3)
    END ;
    loadStringAdr(y);
    (*L0:*) pc0 := mcode.pc;
    A.encMemImm8PUW(mcode, A.LDRIT4, RH, y.r, FALSE, TRUE, TRUE, 4);
    A.encMemImm8PUW(mcode, A.STRIT4, RH, x.r, FALSE, TRUE, TRUE, 4);
    A.encShiftImm5(mcode, A.ASr, RH, RH, 24); A.encBackBranch(mcode, A.NE, pc0); (*BNE L0*)
    RH := 0
   END CopyString;
  
  (* Code generation for parameters *)
  
  PROCEDURE OpenArrayParam*(VAR x: Item);
  BEGIN loadAdr(x);
    IF x.type.len >= 0 THEN A.encMOVImm32(mcode, RH, x.type.len) 
    ELSE incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a+4+frame); DEC(RH)
    END ; incR
  END OpenArrayParam;

  PROCEDURE VarParam*(VAR x: Item; ftype: B.Type);
    VAR xmd: INTEGER;
  BEGIN xmd := x.mode; loadAdr(x);
    IF (ftype.form = B.Array) & (ftype.len < 0) THEN (*open array*)
      IF x.type.len >= 0 THEN A.encMOVImm32(mcode, RH, x.type.len) 
      ELSE  incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a+4+frame); DEC(RH)
      END; incR
    ELSIF (ftype.form = B.Record) & check THEN
      IF xmd = B.Par THEN
        A.encMemImm32(mcode, A.LDR, RH, SP, RH, x.a+4+frame); incR 
      ELSE loadTypTagAdr(x.type)
      END
    END
  END VarParam;

  PROCEDURE ValueParam*(VAR x: Item; t: B.Type);
  BEGIN convertInt(x, t); load(x) (*Force loading in core registers even for real*)
  END ValueParam;

  PROCEDURE StringParam*(VAR x: Item);
  BEGIN loadStringAdr(x); A.encMOVImm32(mcode, RH, x.b); incR  (*len*)
  END StringParam;

  (*For Statements*)

  PROCEDURE For0*(VAR x, y: Item);
  BEGIN load(y)
  END For0;

  PROCEDURE For1*(VAR x, y, z, w: Item; VAR L: INTEGER);
  BEGIN 
    load(z); A.encCMPReg(mcode, y.r, z.r); DEC(RH);
    L := mcode.pc;
    IF w.a > 0 THEN A.Put0(mcode, A.BRCSIG*A.C27 + A.GT*A.C22);
    ELSIF w.a < 0 THEN A.Put0(mcode, A.BRCSIG*A.C27 + A.LT*A.C22);
    ELSE S.Mark("zero increment");
      A.Put0(mcode, A.BRCSIG*A.C27 + A.MI*A.C22);
    END;
    Store(x, y)
  END For1;

  PROCEDURE For2*(VAR x, y, w: Item);
  BEGIN load(x); A.encDPImm32(mcode, A.ADD, x.r, x.r, RH, w.a); DEC(RH)
  END For2;

  (* Branches, procedure calls, procedure prolog and epilog *)

  PROCEDURE Here*(): INTEGER;
  BEGIN RETURN mcode.pc
  END Here;

  PROCEDURE FJump*(VAR L: INTEGER);
  BEGIN A.Put0(mcode, A.BRSIG*A.C27 + L); L := mcode.pc-4
  END FJump;

  PROCEDURE CFJump*(VAR x: Item);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.Put0(mcode, A.BRCSIG*A.C27 + A.negated(x.r)*A.C22 + x.a);
    A.FixLink(mcode, x.b); x.a := mcode.pc-4
  END CFJump;

  PROCEDURE BJump*(L: INTEGER);
  BEGIN A.encBackBranch(mcode, A.AL, L)
  END BJump;

  PROCEDURE CBJump*(VAR x: Item; L: INTEGER);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    A.encBackBranch(mcode, A.negated(x.r), L); A.FixLink(mcode, x.b); A.FixLinkWith(mcode, x.a, L)
  END CBJump;

  PROCEDURE Fixup*(VAR x: Item);
  BEGIN A.FixLink(mcode, x.a)
  END Fixup;

  PROCEDURE PrepCall*(VAR x: Item; VAR r, s: INTEGER);
    VAR xr: INTEGER;
  BEGIN (*x.type.form = B.Proc*) xr := -1;
    IF x.mode > B.Par THEN load(x); xr := x.r; DEC(RH); ASSERT(xr = RH) END ;
    r := RH; IF RH > 0 THEN A.SaveRegs(mcode, RH, frame); OfsPTOS(r, r, TRUE); RH := 0 END;
    s := SH; IF SH > 0 THEN A.SaveFPRegs(mcode, SH, frame); OfsPTOS(s, s, TRUE); SH := 0 END;
    IF xr >= 0 THEN A.PushRegs(mcode, xr, xr); INC(frame, 4); OfsPTOS(1, 1, TRUE) END;
  END PrepCall;

  PROCEDURE Call*(VAR x: Item; r, s: INTEGER);
  BEGIN (*x.type.form = B.Proc*)
    IF x.mode = B.Const THEN
      IF x.r >= 0 THEN A.Put0(mcode, A.BL + A.formatEvenImm25(x.a - (mcode.pc+4)))
      ELSE (*imported*)
        IF mcode.pc - fixORGP < A.C21 THEN
          A.Put0(mcode, (-x.r)*A.C28 + x.a*A.C20 + (mcode.pc - fixORGP) DIV A.C1); fixORGP := mcode.pc-4;
          (*Branching range is -16777216 to 16777214. If caller is in SDRAM (0xD0000000)
          * and callee in Flash (0x08000000), the offset will not be in the permissible
          * range. In this case, the loader will have to generate a "veneer code" near the caller
          * which will jump to the callee. This code could be LDR PC, [PC] followed by the absolute
          * callee address.*)
        ELSE S.Mark("fixup impossible")
        END
      END
    ELSE
      IF x.mode <= B.Par THEN load(x); DEC(RH)
      ELSE
        IF RH < 8 THEN (*POP T1*) A.Put1(mcode, A.POPT1 + LSL(1, RH))
        ELSE (*POP T3*) A.Put0(mcode, A.POPT3 + RH*A.C12) 
        END; OfsPTOS(-1, -1, TRUE); DEC(frame, 4)
      END;
      (*No NIL check needed because every even address will cause an usage fault exception
        because only thumb instruction are supported*)
      A.Put1(mcode, A.BLX + RH*A.C3)
    END ;
    IF x.type.base.form = B.NoTyp THEN (*procedure*) RH := 0; SH := 0;
    ELSE (*function*)
      IF s > 0 THEN (* VMOV Ss, S0*) A.Put0(mcode, A.VMOVSS + s DIV A.C1*A.C12 +
        s MOD A.C1*A.C22); A.RestoreFPRegs(mcode, s, frame); OfsPTOS(-s, -s, TRUE) END ;
      IF r > 0 THEN A.encMOVReg(mcode, r, 0); 
        A.RestoreRegs(mcode, r, frame); OfsPTOS(-r, -r, TRUE) END ;
      IF x.type.base.form = B.Real THEN x.mode := FPReg; x.r := s; SH := s+1; RH := r 
      ELSE x.mode := Reg; x.r := r;
        IF x.type.base = B.longintType THEN RH := r+2 ELSE RH := r+1 END;
        SH := s
      END
    END
  END Call;

  PROCEDURE Enter*(parblksize, locblksize: INTEGER; int: BOOLEAN; reglim: INTEGER);
    VAR r: INTEGER;
  BEGIN OfsPTOS(0, -1, FALSE); frame := 0;
    IF locblksize >= A.C16 THEN S.Mark("local variables size exeeded") END;
    r := (parblksize-4) DIV 4;
    IF int THEN (*interrupt procedure, lot of registers are already saved in interrupt frame*)
      (*Store interrupt frame address in R0*)
      A.encDPImm32(mcode, A.TST, 0, LR, r, 4);
      A.IfThen(mcode, "E", A.EQ);
      A.encMRS(mcode, 0, MSP);
      A.encMRS(mcode, 0, PSP)
    END;

    IF reglim >= 0 THEN (*sets the number of usable registers. This is useful to ensure that interrupt handlers do not corrupt registers*)
      RL := reglim+1;
      IF reglim >= 4 THEN
        A.PushRegs(mcode, 4, reglim); OfsPTOS(reglim - 3, 0, TRUE) (*protect usable registers, assuming that R0 to R3 are already saved in interrupt frame*)
      END
    END;

    IF locblksize - parblksize # 0 THEN (*reserve memory for variables*)
      A.encDPImm32(mcode, A.SUB, SP, SP, r, locblksize - parblksize); OfsPTOS((locblksize - parblksize) DIV 4, 0, TRUE)
    END;
    IF r > 0 THEN A.PushRegs(mcode, 0, r-1); OfsPTOS(r, 0, TRUE) END; (*reserve memory for parameters and initialize them*)

    (*PUSH T1 LR *) A.Put1(mcode, A.PUSHT1 + A.C8); OfsPTOS(1, 1, TRUE)
  END Enter;

  PROCEDURE Return*(form: INTEGER; VAR x: Item; size: INTEGER; reglim: INTEGER);
  BEGIN
    IF form # B.NoTyp THEN 
      IF x.type.form = B.Real THEN loadFP(x); ELSE load(x) END
    END;
    (*POP T3 LR *) A.encMemImm8PUW(mcode, A.LDRIT4, LR, SP, FALSE, TRUE, TRUE, 4); OfsPTOS(-1, -1, TRUE);
    IF size # 4 THEN A.encDPImm32(mcode, A.ADD, SP, SP, RH, size - 4); OfsPTOS((4 - size) DIV 4, 0, TRUE) END;
    IF reglim >= 0 THEN IF reglim >= 4 THEN A.PopRegs(mcode, 4, reglim); OfsPTOS(3 - reglim, 0, TRUE) END; RL := SP END;
    IF frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos MOD 10000H # 0 THEN S.DebugHex("stack seg", frmOfsSegs.Segs[frmOfsSegs.NofSegs].ofsptos) END;
    A.Put1(mcode, A.BX + LR*A.C3); RH := 0; SH := 0;
  END Return;

  (* In-line code procedures*)

  PROCEDURE doInc(VAR x, y: Item; op, op2, zr, vl, vs: INTEGER);
  BEGIN
    IF y.mode = B.Const THEN A.encDPImm32(mcode, op, zr, zr, RH, y.a);
      IF x.type = B.longintType THEN A.encDPImm32(mcode, op2, zr+1, zr+1, RH, (* y.a TODO DIV 100000000H*)0) END
    ELSE load(y); A.encDPReg(mcode, op, zr, zr, y.r, A.LSl, 0, TRUE); DEC(RH);
      IF x.type = B.longintType THEN A.encDPReg(mcode, op2, zr+1, zr+1, y.r+1, A.LSl, 0, TRUE); DEC(RH) END
    END
  END doInc;

  PROCEDURE Increment*(upordown: INTEGER; VAR x, y: Item); (*x := x+y OR x := x+1 if y not defined*)
    VAR op, op2, zr, vl, vs: INTEGER;
  BEGIN (*frame = 0*)
    IF upordown = 0 THEN op := A.ADD; op2 := A.ADc ELSE op := A.SUB; op2 := A.SBc END ;
    IF x.type = B.byteType THEN vl := A.LDRB; vs := A.STRB ELSE vl := A.LDR; vs := A.STR END ;
    IF y.type.form = B.NoTyp THEN y.type := B.intType; y.mode := B.Const; y.a := 1 END ;
    convertInt(y, x.type);
    IF (x.mode = B.Var) & (x.r > 0) THEN zr := RH;
      IF x.type = B.longintType THEN dincR; A.encDMemImm32(mcode, A.LDRD, zr, zr+1, SP, RH, x.a)
      ELSE incR; A.encMemImm32(mcode, vl, zr, SP, RH, x.a)
      END; doInc(x, y, op, op2, zr, vl, vs);
      IF x.type = B.longintType THEN A.encDMemImm32(mcode, A.STRD, zr, zr+1, SP, RH, x.a); DEC(RH, 2)
      ELSE A.encMemImm32(mcode, vs, zr, SP, RH, x.a); DEC(RH)
      END
    ELSE loadAdr(x); zr := RH; incR;
      IF x.type = B.longintType THEN incR; A.encDMemImm32(mcode, A.LDRD, zr, zr+1, x.r, RH, 0)
      ELSE A.encMemImm32(mcode, vl, zr, x.r, RH, 0)
      END; doInc(x, y, op, op2, zr, vl, vs);
      IF x.type = B.longintType THEN A.encDMemImm32(mcode, A.STRD, zr, zr+1, x.r, RH, 0); DEC(RH, 3)
      ELSE A.encMemImm32(mcode, vs, zr, x.r, RH, 0); DEC(RH, 2)
      END;
    END
  END Increment;

  PROCEDURE Include*(inorex: INTEGER; VAR x, y: Item);
    VAR op, zr: INTEGER;
  BEGIN loadAdr(x); zr := RH; incR; A.encMemImm32(mcode, A.LDR, zr, x.r, RH, 0);
    IF inorex = 0 THEN op := A.ORR ELSE op := A.BIC END ;
    IF y.mode = B.Const THEN A.encDPImm32(mcode, op, zr, zr, RH, LSL(1, y.a))
    ELSE load(y); A.encMOVImm32(mcode, RH, 1); A.encShiftReg(mcode, A.LSl, y.r, RH, y.r, TRUE); A.encDPReg(mcode, op, zr, zr, y.r, A.LSl, 0, TRUE); DEC(RH)
    END ;
    A.encMemImm32(mcode, A.STR, zr, x.r, RH, 0); DEC(RH, 2)
  END Include;

  PROCEDURE Assert*(VAR x: Item);
    VAR cond, pc0: INTEGER;
  BEGIN
    pc0 := 0;
    IF x.mode # Cond THEN loadCond(x) END;
    IF x.a = 0 THEN cond := A.negated(x.r);
    ELSE pc0 := mcode.pc; A.Put1(mcode, A.BCT1 + x.r*A.C8);
      A.FixLink(mcode, x.a); cond := A.AL
    END ;
    Trap(cond, 7); A.FixLink(mcode, x.b);
    IF pc0 # 0 THEN A.fix8(mcode, pc0, mcode.pc - pc0 - 4) END
  END Assert; 

  PROCEDURE New*(VAR x: Item);
  BEGIN loadAdr(x); loadTypTagAdr(x.type.base); (*Trap(A.AL, 0)*) A.Put1(mcode, A.SVC); RH := 0; SH := 0
  END New;

  PROCEDURE Pack*(VAR x, y: Item);
    VAR z!: Item;
  BEGIN (*Load x in a core register*)
    z := x; load(x); load(y);
    A.encDPReg(mcode, A.ADD, x.r, x.r, y.r, A.LSl, 23, TRUE); DEC(RH); Store(z, x);
  END Pack;

  PROCEDURE Unpk*(VAR x, y: Item);
    VAR z!, e0!: Item;
  BEGIN (*Load x in a core register*)
    z := x; load(x); e0.mode := Reg; e0.r := RH; e0.type := B.intType;
    A.encShiftImm5(mcode, A.ASr, RH, x.r, 23); 
    incR; A.encDPImm32(mcode, A.SUB, RH-1, RH-1, RH, 127); DEC(RH);
    Store(y, e0); incR; A.encDPReg(mcode, A.SUB, x.r, x.r, RH, A.LSl, 23, TRUE); Store(z, x);
  END Unpk;

(* The SVC mechanism will be used to communicate with undelying firmware,
   in order to hide board level details, like the LED attachement to ports.*)
   
  PROCEDURE Led*(VAR x: Item);
  (*SVC #1 is assigned to LEDS*)
  BEGIN load(x); A.Put1(mcode, A.SVC + 1); DEC(RH)
  END Led;

  (*Call service*)
  PROCEDURE SVC*(VAR x: Item);
  BEGIN (*x.mode = Const*)
    A.Put1(mcode, A.SVC + x.a MOD A.C8); 
    x.mode := Reg; x.r := 0; RH := 1
  END SVC;
  
  PROCEDURE Get*(VAR x, y: Item);
  BEGIN load(x); x.type := y.type; x.mode := RegI; x.a := 0; Store(y, x)
  END Get;

  PROCEDURE Put*(VAR x, y: Item);
  BEGIN load(x); x.type := y.type; x.mode := RegI; x.a := 0; Store(x, y)
  END Put;

  PROCEDURE Copy*(VAR x, y, z: Item);
    VAR pc0, pc1: INTEGER;
  BEGIN load(x); load(y);
    pc0 := 0;
    IF z.mode = B.Const THEN
      IF z.a > 0 THEN load(z) ELSE S.Mark("bad count") END
    ELSE load(z);
      IF check THEN 
          IF ~mcode.lastInstrSetFlags THEN A.encCMPImm(mcode, z.r, RH, 0) END;
        Trap(A.LT, 3)
      END;
      pc0 := mcode.pc; A.Put1(mcode, A.BCT1 + A.EQ*A.C8); (*BEQ L0*)
    END ;
    pc1 := mcode.pc;
    A.encMemImm8PUW(mcode, A.LDRIT4, RH, x.r, FALSE, TRUE, TRUE, 4);
    A.encMemImm8PUW(mcode, A.STRIT4, RH, y.r, FALSE, TRUE, TRUE, 4);
    A.encDPImm32(mcode, A.SUB, z.r, z.r, RH, 1); A.encBackBranch(mcode, A.NE, pc1); (*BNE L1*)
    IF pc0 # 0 THEN A.fix8(mcode, pc0, mcode.pc - pc0 - 4) END; DEC(RH, 3)
  END Copy;

  PROCEDURE LDREG*(VAR x, y: Item);
  BEGIN (*x is constant*)
    load(y);  IF x.a > A.C4 THEN A.encMSR(mcode, y.r, x.a - A.C4) END; RH := 0
  END LDREG;

  (*In-line code functions*)

  PROCEDURE Abs*(VAR x: Item);
  BEGIN
    IF x.mode = B.Const THEN x.a := ABS(x.a)
    ELSE IF x.type.form = B.Real THEN loadFP(x); ELSE load(x) END;
      IF x.mode = FPReg THEN A.encFPOpReg(mcode, A.VABS, x.r, 0, x.r)
      ELSE A.encCMPImm(mcode ,x.r, RH, 0); A.IfThen(mcode, "", A.LT);
        A.encDPImm32(mcode, A.RSB, x.r, x.r, RH, 0)
      END
    END
  END Abs;

  PROCEDURE Sqrt*(VAR x: Item);
  BEGIN
    IF x.mode = B.Const THEN x.a := SYSTEM.VAL(INTEGER, SQRT(SYSTEM.VAL(REAL, x.a)))
    ELSE loadFP(x); A.encFPOpReg(mcode, A.VSQRT, x.r, 0, x.r)
    END
  END Sqrt;

  PROCEDURE Odd*(VAR x: Item);
  BEGIN load(x); A.encShiftImm5(mcode, A.ROr, x.r, x.r, 1); SetCC(x, A.MI); DEC(RH)
  END Odd;

  PROCEDURE Floor*(VAR x: Item);
  BEGIN loadFP(x); A.encFPOpReg(mcode, A.VCVTSF, x.r, 0, x.r);
    x.type := B.intType;
  END Floor;

  PROCEDURE Float*(VAR x: Item);
  BEGIN x.type := B.realType; loadFP(x);
    A.encFPOpReg(mcode, A.VCVTFS, x.r, 0, x.r)
  END Float;

  PROCEDURE Ord*(VAR x: Item);
  BEGIN
    IF x.mode IN {B.Var, B.Par, RegI, Cond} THEN load(x) END
  END Ord;

  PROCEDURE Len*(VAR x: Item);
  BEGIN
    IF x.type.len >= 0 THEN
      IF x.mode = RegI THEN DEC(RH) END ;
      x.mode := B.Const; x.a := x.type.len
    ELSE (*open array*) incR; A.encMemImm32(mcode, A.LDR, RH-1, SP, RH, x.a + 4 + frame);
      x.mode := Reg; x.r := RH-1
    END 
  END Len;

  PROCEDURE Shift*(fct: INTEGER; VAR x, y: Item);
    VAR op: INTEGER;
  BEGIN IF (x.mode = B.Const) & (y.mode = B.Const) THEN
      IF fct = 0 THEN x.a := LSL(x.a, y.a) ELSIF fct = 1 THEN x.a := ASR(x.a, y.a) ELSIF fct = 2 THEN x.a := ROR(x.a, y.a) ELSE x.a := LSR(x.a, y.a) END 
    ELSE load(x);
      IF fct = 0 THEN Lsl(x, y) ELSIF fct = 1 THEN Asr(x, y) ELSIF fct = 3 THEN Lsr(x, y)
      ELSE op := A.ROr; IF x.type.size = 8 THEN S.Mark("not implemented") END;
        IF y.mode = B.Const THEN A.encShiftImm5(mcode, op, x.r, x.r, y.a MOD 20H)
        ELSE load(y); A.encShiftReg(mcode, op, RH-2, x.r, y.r, TRUE); DEC(RH); x.r := RH-1
        END
      END
    END
  END Shift;

  PROCEDURE ADC*(VAR x, y: Item);
  BEGIN load(x); load(y); A.encDPReg(mcode, A.ADc, x.r, x.r, y.r, A.LSl, 0, TRUE); DEC(RH)
  END ADC;

  PROCEDURE SBC*(VAR x, y: Item);
  BEGIN load(x); load(y); A.encDPReg(mcode, A.SBc, x.r, x.r, y.r, A.LSl, 0, TRUE); DEC(RH)
  END SBC;

  PROCEDURE UML*(VAR x, y: Item);
  BEGIN load(x); load(y); A.Put0(mcode, A.UMULL + x.r*A.C16 + x.r*A.C12 + y.r*A.C8 + y.r); DEC(RH)
  END UML;

  PROCEDURE MBI*(i: INTEGER);
  BEGIN (*x.mode = B.Const*)
    IF i = 1 THEN A.Put0(mcode, A.DMB)
    ELSIF i = 2 THEN A.Put0(mcode, A.DSB)
    ELSIF i = 3 THEN A.Put0(mcode, A.ISB)
    ELSE S.Mark("bad MBI")
    END
  END MBI;

  PROCEDURE Rbit*(VAR x: Item);
  BEGIN load(x); A.Put0(mcode, A.RBIT + x.r*A.C16 + x.r*A.C8 + x.r)
  END Rbit;

  PROCEDURE Clz*(VAR x: Item);
  (*Count leading 0, x is INTEGER or LONGINT, result is INTEGER*)
  BEGIN load(x);
    IF x.type.size = 8 THEN A.Put0(mcode, A.CLZ + x.r+1*A.C16 + x.r+1*A.C8 + x.r+1);
      A.encCMPImm(mcode, x.r+1, RH, 32); A.IfThen(mcode, "TE", A.EQ);
      A.Put0(mcode, A.CLZ + x.r*A.C16 + x.r*A.C8 + x.r); A.encDPReg(mcode, A.ADD, x.r, x.r+1, x.r, A.LSl, 0, FALSE);
      A.encMOVReg(mcode, x.r, x.r+1); DEC(RH)
    ELSE A.Put0(mcode, A.CLZ + x.r*A.C16 + x.r*A.C8 + x.r)
    END;
    x.type := B.intType
  END Clz;

  PROCEDURE Bit*(VAR x, y: Item);
  BEGIN IF (x.mode = B.Const) & (y.mode = B.Const) &
    ((x.a >= 20000000H) & (x.a < 20100000H) OR (x.a >= 40000000H) & (x.a < 40100000H)) THEN
      (*Use bit banding*)
      x.a := x.a DIV A.C28*A.C28 + 2000000H + (x.a MOD A.C28 + y.a DIV 8)*32 + y.a MOD 8*4; load(x);
      A.encMemImm32(mcode, A.LDR, x.r, x.r, RH, 0); x.type := B.boolType
    ELSE load(x);
      A.encMemImm32(mcode, A.LDR, x.r, x.r, RH, 0);
      IF y.mode = B.Const THEN A.encShiftImm5(mcode, A.ROr, x.r, x.r, y.a+1); DEC(RH)
      ELSE load(y); A.encDPImm32(mcode, A.ADD, y.r, y.r, RH, 1); A.encShiftReg(mcode, A.ROr, x.r, x.r, y.r, TRUE); DEC(RH, 2)
      END ;
      SetCC(x, A.MI)
    END
  END Bit;

  PROCEDURE Register*(VAR x: Item);
  BEGIN (*x.mode = Const*)
    A.encMOVReg(mcode, RH, x.a MOD A.C4); x.mode := Reg; x.r := RH; incR
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

  PROCEDURE Open*(v: INTEGER);
  BEGIN A.Init(mcode); frmOfsSegs.NofSegs := 0; frmOfsSegs.Segs[0].ofsptos := 0FFFF0000H;
    tdx := 0; strx := 0; RH := 0; SH := 0; fixORGP := 0; fixORGD := 0; fixORGT := 0; check := v # 0; version := v; RL := SP;
    IF v = 0 THEN mcode.pc := 4; (*Make room for the jump to entry point instruction*) END
  END Open;

  PROCEDURE SetDataSize*(dc: INTEGER);
  BEGIN varsize := dc
  END SetDataSize;

  PROCEDURE Header*;
  BEGIN entry := mcode.pc; OfsPTOS(0, -1, FALSE);
    IF version = 0 THEN A.modify(mcode, 0, A.BT4 + A.formatEvenImm25(mcode.pc-4))
    ELSE (*PUSH T1 LR *) A.Put1(mcode, A.PUSHT1 + A.C8); OfsPTOS(1, 1, TRUE)
    END
  END Header;

  PROCEDURE NofPtrs(typ: B.Type): INTEGER;
    VAR fld!: B.Object; n: INTEGER;
  BEGIN
    IF (typ.form = B.Pointer) OR (typ.form = B.NilTyp) THEN n := 1
    ELSIF typ.form = B.Record THEN
      fld := typ.dsc; n := 0;
      WHILE fld # NIL DO n := NofPtrs(fld.type) + n; fld := fld.next END
    ELSIF typ.form = B.Array THEN n := NofPtrs(typ.base) * typ.len
    ELSE n := 0
    END ;
    RETURN n
  END NofPtrs;

  PROCEDURE FindPtrs(VAR R: Files.Rider; typ: B.Type; adr: INTEGER);
    VAR fld!: B.Object; i, s: INTEGER;
  BEGIN
    IF (typ.form = B.Pointer) OR (typ.form = B.NilTyp) THEN Files.WriteInt(R, adr)
    ELSIF typ.form = B.Record THEN
      fld := typ.dsc;
      WHILE fld # NIL DO FindPtrs(R, fld.type, fld.val + adr); fld := fld.next END
    ELSIF typ.form = B.Array THEN
      s := typ.base.size;
      FOR i := 0 TO typ.len-1 DO FindPtrs(R, typ.base, i*s + adr) END
    END
  END FindPtrs;

  PROCEDURE Close*(VAR modid: S.Ident; key, nofent: INTEGER);
    VAR obj!, obj2!: B.Object;
      i, comsize, nofimps, nofptrs, nofusedextprocs, size: INTEGER;
      name: S.Ident;
      F!: Files.File; R!: Files.Rider;
  BEGIN  (*exit code*)
    IF version = 0 THEN
      (*A.BX R0 : Jump to the beginning of the program loaded by the Boot Loader*)
      A.encMOVImm32(mcode, 0, VarORG0+1); (*odd address to thumb mode*) A.Put1(mcode, A.BX)
    ELSE (*POP T3 LR *) A.encMemImm8PUW(mcode, A.LDRIT4, LR, SP, FALSE, TRUE, TRUE, 4); OfsPTOS(-1, -1, TRUE);
      A.Put1(mcode, A.BX + LR*A.C3)
    END ;
    obj := B.topScope.next; nofimps := 0; comsize := 4; nofptrs := 0; nofusedextprocs := 0;
    (*count user external procedures*)
    WHILE obj # NIL DO
      IF (obj.class = B.Mod) & (obj.dsc # B.system) THEN INC(nofimps); (*count imports*)
        obj2 := obj.dsc;
        WHILE (obj2 # NIL) DO
          IF obj2.used & (obj2.lev < 0) & (obj2.class = B.Const) & (obj2.type.form = B.Proc) THEN INC(nofusedextprocs) (*count external procs called*)
          END;
          obj2 := obj2.next
        END
      ELSIF (obj.exno # 0) & (obj.class = B.Const) & (obj.type.form = B.Proc)
          & (obj.type.nofpar = 0) & (obj.type.base = B.noType) THEN i := 0; (*count commands*)
        WHILE obj.name[i] # 0X DO INC(i) END ;
        i := (i+4) DIV 4 * 4; INC(comsize, i+4)
      ELSIF obj.class = B.Var THEN INC(nofptrs, NofPtrs(obj.type))  (*count pointers*)
      END ;
      obj := obj.next
    END ;
    
    (*varsize includes type descriptors*)
    size := varsize + strx + comsize + (mcode.pc+3) DIV 4*4 + (nofimps + nofent + nofptrs + 1)*4 + nofusedextprocs*8;
    (*size is aligned on 4 bytes boundary*)
    
    B.MakeFileName(name, modid, ".m4c"); (*write code file*)
    F := Files.New(name); Files.Set(R, F, 0); Files.WriteString(R, modid); Files.WriteInt(R, key); Files.Write(R, CHR(version));
    Files.WriteInt(R, size);
    obj := B.topScope.next;
    WHILE (obj # NIL) & (obj.class = B.Mod) DO  (*imports*)
      IF obj.dsc # B.system THEN Files.WriteString(R, obj(B.Module).orgname); Files.WriteInt(R, obj.val) END ;
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
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*commands*)
      IF (obj.exno # 0) & (obj.class = B.Const) & (obj.type.form = B.Proc) &
          (obj.type.nofpar = 0) & (obj.type.base = B.noType) THEN
        Files.WriteString(R, obj.name); Files.WriteInt(R, obj.val)
      END ;
      obj := obj.next
    END ;
    Files.Write(R, 0X);
    Files.WriteInt(R, nofent); Files.WriteInt(R, entry);
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*entries*)
      IF obj.exno # 0 THEN
        IF (obj.class = B.Const) & (obj.type.form = B.Proc) OR (obj.class = B.Var) THEN Files.WriteInt(R, obj.val)
        ELSIF (obj.class = B.Const) & (obj.type.form = B.String) THEN Files.WriteInt(R, obj.val MOD 10000H + varsize)
        ELSIF obj.class = B.Typ THEN
          IF obj.type.form = B.Record THEN ASSERT((obj.type.len >= 0) & (obj.type.len < A.C16)); Files.WriteInt(R,  obj.type.len MOD A.C16)
          ELSIF (obj.type.form = B.Pointer) & ((obj.type.base.typobj = NIL) OR (obj.type.base.typobj.exno = 0)) THEN
            ASSERT((obj.type.base.len >= 0) & (obj.type.base.len < A.C16)); Files.WriteInt(R,  obj.type.base.len MOD A.C16)
          END
        END
      END ;
      obj := obj.next
    END ;
    obj := B.topScope.next;
    WHILE obj # NIL DO  (*pointer variables*)
      IF obj.class = B.Var THEN FindPtrs(R, obj.type, obj.val) END ;
      obj := obj.next
    END ;
    Files.WriteInt(R, -1);
    Files.WriteInt(R, fixORGP); Files.WriteInt(R, fixORGD); Files.WriteInt(R, fixORGT); Files.WriteInt(R, entry);
    Files.Write(R, "O"); Files.Register(F);
    (*write object addresses to source position mapping in .osm file*)
    B.MakeFileName(name, modid, ".osm"); F := Files.New(name); Files.Set(R, F, 0); Files.WriteInt(R, mcode.pc DIV 2); size := 1;
    FOR i := 1 TO mcode.pc DIV 2 - 1 DO 
      IF (size < 255) & (mcode.pos[i] = mcode.pos[i-1]) THEN INC(size) ELSE Files.WriteByte(R, size); Files.WriteInt(R, mcode.pos[i - 1]); size := 1 END
    END; Files.WriteByte(R, size); Files.WriteInt(R, mcode.pos[mcode.pc DIV 2 - 1]); Files.Register(F);
    (*write word offset with caller top of stack*)
    OfsPTOS(-1, -1, FALSE); (*close last segment*) B.MakeFileName(name, modid, ".rao"); F := Files.New(name); Files.Set(R, F, 0); 
    Files.WriteInt(R, frmOfsSegs.NofSegs);
    FOR i := 0 TO frmOfsSegs.NofSegs DO Files.WriteInt(R, frmOfsSegs.Segs[i].end); Files.WriteInt(R, frmOfsSegs.Segs[i].ofsptos) END;
    Files.Register(F)
  END Close;

BEGIN
  relmap[0] := A.EQ; relmap[1] := A.NE; relmap[2] := A.LT; 
  relmap[3] := A.LE; relmap[4] := A.GT; relmap[5] := A.GE
END OM4G2.
