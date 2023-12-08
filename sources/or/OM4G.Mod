MODULE OM4G; (* N.Wirth, 16.4.2016 / 4.4.2017 / 31.5.2019  Oberon compiler;
  C. Schoffit 19/10/2023 code generator for Cortex M4 STM32I-DISCO*)
  IMPORT SYSTEM, Files, OM4A, OM4S, OM4B;
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
    maxStrx = 3000; maxTD = 160;
    
    Reg = 10; RegI = 11; Cond = 12; FPReg = 13; (*internal item modes*)

  TYPE Item* = RECORD
    mode*: INTEGER;
    type*: OM4B.Type;
    a*, b*, r: LONGINT;
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

  VAR varsize: LONGINT;   (*data index*)
    tdx, strx: LONGINT;
    entry: LONGINT;   (*main entry point*)
    RH: LONGINT;      (*in use registers R[0] ... R[H-1]*)
    SH: LONGINT;      (*in use floating point registers S[0] ... S[H-1]*)
    frame: LONGINT;   (*frame offset changed in SaveRegs and RestoreRegs*)
    fixORGP, fixORGD, fixORGT: LONGINT;   (*origins of lists of locations to be fixed up by loader*)
    check: BOOLEAN;   (*emit run-time checks*)
    version: INTEGER; (*0 = bare metal program, 1 = oberon system module*)
    
    relmap: ARRAY 6 OF INTEGER;    (*condition codes for relations*)
    data: ARRAY maxTD OF LONGINT;  (*type descriptors*)
    str: ARRAY maxStrx OF CHAR;
    mcode: OM4A.ModuleCode;
    
  PROCEDURE FixOne*(at: LONGINT);
  BEGIN OM4A.FixOne(mcode, at)
  END FixOne;

  PROCEDURE FixLink*(L: LONGINT);
  BEGIN
    OM4A.FixLink(mcode, L)
  END FixLink;

  PROCEDURE incR;
  BEGIN
    IF RH < SP-1 THEN INC(RH) ELSE OM4S.Mark("register stack overflow") END
  END incR;

  PROCEDURE incS;
  BEGIN
    IF SH < NBS-1 THEN INC(SH) ELSE OM4S.Mark("FP register stack overflow") END
  END incS;

  PROCEDURE CheckRegs*;
  BEGIN
    IF RH # 0 THEN OM4S.Mark("Reg Stack"); RH := 0 END ;
    IF SH # 0 THEN OM4S.Mark("FP Reg Stack"); SH := 0 END ;
    IF mcode.pc >= OM4A.maxCode - 40 THEN OM4S.Mark("program too long") END ;
    IF frame # 0 THEN OM4S.Mark("frame error"); frame := 0 END
  END CheckRegs;

  PROCEDURE SetCC(VAR x: Item; n: LONGINT);
  BEGIN x.mode := Cond; x.a := 0; x.b := 0; x.r := n
  END SetCC;

  PROCEDURE Trap(cond, num: LONGINT);
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
  VAR pos: LONGINT;
  BEGIN 
    IF cond # OM4A.AL THEN OM4A.IfThen(mcode, "", cond) END;
    pos := OM4S.Pos();
    ASSERT(pos < OM4A.C20);
    ASSERT(num < OM4A.C4);
    OM4A.Put0(mcode, OM4A.CoP + pos DIV OM4A.C7*OM4A.C12 + pos MOD OM4A.C7*OM4A.C4 + num)
  END Trap;

  (* loading of operands and addresses into registers *)

(*  Format of pseudo operations for accessing static vars and procs

    These pseudo-instructions will be fixup at load or link time by
    the Modules or OM4L modules.

  1/ Variables (entire address space is accessible)
    The size of the offset is limited to 12 bits, that is 1K words.
    This is too short to implement the fixup link. We'll use pseudo
    LDR/STR/ADD instructions.

    a/ Getting lower 16-bits of absolute address
    MOV a, #imm16:
    aaaannnndddddddddddddddddddddddd
    
    aaaa: destination register
    nnnn: number of the module
    dd24: offset DIV 2 of next op to fix for runtime absolute address
    
    b/ Getting higher 16-bits of absolute address
    MOVT a, #imm16
     
    if nnnn > 0
    00000000000000000000000pvvvvvvvv
    a:    specified in previous instruction
    p:    program based procedure
    vvv8: number of the variable or procedure
    
    else if nnnn = 0, object cannot be a constant procedure
    00000000oooooooooooooooooooooooo
    oo24: offset of the variable
  
  2/ Procedures (entire address space is accessible with veneer code
                 when needed)
    BL <proc address>:
    
    nnnnppppppppdddddddddddddddddddd

    nnnn:     number of the module
    pppppppp: number of the procedure
    dd20: offset DIV 2 of next op to fix for procedure address loading
    
*)

  PROCEDURE GetStaticVarAddress(x: Item; a: BYTE);
    VAR progbaseIndic: LONGINT;
  BEGIN    
    ASSERT((x.r <= 0) & (a < 13));
    IF mcode.pc-fixORGD > OM4A.C25 THEN OM4S.Mark("too many instruction between static access") END;
    (* MOV a, #imm16 *)
    OM4A.Put0(mcode, RH*OM4A.C28 + (-x.r)*OM4A.C24 + (mcode.pc-fixORGD) DIV OM4A.C1);
    fixORGD := mcode.pc-4;
    (*If x.r = 0, x.a contains the offset of the variable computed at compile time,
      else if x.r < 0, x.a contains the variable or procedure number and the base indicator*)
    IF (x.type # NIL) & (x.type.form = OM4B.Proc) & (x.r < 0) THEN progbaseIndic := OM4A.C8 
    ELSE progbaseIndic := 0 END;
    (* MOVT a, #imm16 *)
    OM4A.Put0(mcode, progbaseIndic + x.a)
  END GetStaticVarAddress;
  
  PROCEDURE NilCheck(a: BYTE);
  BEGIN
    IF check THEN
      IF ~mcode.lastInstrSetFlags THEN  incR; OM4A.encCMPImm(mcode, a, RH, 0); DEC(RH) END ;
      Trap(OM4A.EQ, 4) 
    END
  END NilCheck;

  PROCEDURE doLoad(VAR x: Item; target: INTEGER);
    VAR op, pc0, pc1: LONGINT;
  BEGIN
    ASSERT(target IN {Reg, FPReg});
    ASSERT((target # FPReg) OR (x.type.form = OM4B.Real));
    IF x.type.size = 1 THEN op := OM4A.LDRB ELSE op := OM4A.LDR END ;
    IF x.mode # target THEN
      IF x.mode = OM4B.Const THEN
        IF x.type.form = OM4B.Proc THEN
          IF x.r > 0 THEN OM4S.Mark("not allowed")
          ELSIF x.r = 0 THEN (* Put address of next statement in LR *)
            (*Si align(PC+4, 4) - x.a < 4096 on peut utiliser l'équivalent de l'assembleur ADR RH, <label>*)
            OM4A.Put0(mcode, OM4A.BL + OM4A.formatEvenImm25(0)); 
            OM4A.encDPImm32(mcode, OM4A.SUB, RH, LR, RH, mcode.pc - x.a)
          ELSE GetStaticVarAddress(x, RH) END;
          x.r := RH; incR
        ELSE OM4A.encMOVImm32(mcode, RH, x.a);
          IF target = FPReg THEN
            OM4A.encFPOpReg(mcode, OM4A.VMOVSR, RH, SH, 0);
            x.r := SH; incS
          ELSE x.r := RH; incR
          END
        END;
      ELSIF x.mode = OM4B.Var THEN
        IF x.r > 0 THEN (*local*) 
          IF target = FPReg THEN ASSERT((x.a + frame) MOD OM4A.C2 = 0);
            IF x.a + frame >= OM4A.C10 THEN OM4S.Mark("local real var too far") END;
            OM4A.Put0(mcode, OM4A.VLDRT2 + 1*OM4A.C23 + SH MOD OM4A.C1*OM4A.C22 + SP*OM4A.C16 + SH DIV OM4A.C1*OM4A.C12 + (x.a + frame) DIV OM4A.C2);
            x.r := SH; incS
          ELSE incR; OM4A.encMemImm32(mcode, op, RH-1, SP, RH, x.a + frame); x.r := RH-1
          END
        ELSE GetStaticVarAddress(x, RH); x.mode := RegI; x.r := RH; x.a := 0; incR; doLoad(x, target)
        END
      ELSIF x.mode = OM4B.Par THEN
        incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a + frame); DEC(RH);
        IF target = FPReg THEN ASSERT((x.b + frame) MOD OM4A.C2 = 0);
          IF x.b + frame >= OM4A.C10 THEN OM4S.Mark("real param offset 1 too far") END;
          OM4A.Put0(mcode, OM4A.VLDRT2 + 1*OM4A.C23 + SH MOD OM4A.C1*OM4A.C22 + RH*OM4A.C16 + SH DIV OM4A.C1*OM4A.C12 + (x.b + frame) DIV OM4A.C2);
          x.r := SH; incS
        ELSE  incR; OM4A.encMemImm32(mcode, op, RH-1, RH-1, RH, x.b); x.r := RH-1
        END
      ELSIF x.mode = RegI THEN 
        IF target = FPReg THEN ASSERT(x.a MOD OM4A.C2 = 0);
          IF x.a >= OM4A.C10 THEN OM4S.Mark("real RegI too far") END;
          OM4A.Put0(mcode, OM4A.VLDRT2 + 1*OM4A.C23 + SH MOD OM4A.C1*OM4A.C22 + x.r*OM4A.C16 + SH DIV OM4A.C1*OM4A.C12 + x.a DIV OM4A.C2);
          x.r := SH; incS; DEC(RH)
        ELSE  OM4A.encMemImm32(mcode, op, x.r, x.r, RH, x.a)
        END
      ELSIF x.mode = Cond THEN
        IF (x.a = 0) & (x.b = 0) THEN (*No "false" or "true" chains*)
          OM4A.IfThen(mcode, "E", x.r);
          OM4A.encMOVImm32(mcode, RH, 1);
          OM4A.encMOVImm32(mcode, RH, 0)
        ELSE (*A "true" and/or "false" chain need to be fixed, do it the classical way*)
          pc0 := mcode.pc; OM4A.Put1(mcode, OM4A.BCT1 + OM4A.negated(x.r)*OM4A.C8);
          FixLink(x.b); OM4A.encMOVImm32(mcode, RH, 1); pc1 := mcode.pc; OM4A.Put1(mcode, OM4A.BT2);
          OM4A.fix8(mcode, pc0, mcode.pc - pc0 - 4); FixLink(x.a); OM4A.encMOVImm32(mcode, RH, 0);
          OM4A.fix11(mcode, pc1, mcode.pc - pc1 - 4);
        END;
        x.r := RH; incR
      ELSIF x.mode = Reg THEN OM4A.encFPOpReg(mcode, OM4A.VMOVSR, x.r, SH, 0) (*Reg to FPReg*); x.r := SH; incS; DEC(RH)
      ELSIF x.mode = FPReg THEN OM4A.encFPOpReg(mcode, OM4A.VMOVRS, RH, x.r, 0) (*FPReg to Reg*); x.r := RH; incR; DEC(SH)
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
    IF x.mode = OM4B.Var THEN
      IF x.r > 0 THEN (*local*) OM4A.encDPImm32(mcode, OM4A.ADD, RH, SP, RH, x.a + frame)
      ELSE GetStaticVarAddress(x, RH) END;
      x.r := RH; incR
    ELSIF x.mode = OM4B.Par THEN incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a + frame); DEC(RH);
      IF x.b # 0 THEN incR; OM4A.encDPImm32(mcode, OM4A.ADD, RH-1, RH-1, RH, x.b); DEC(RH) END;
      x.r := RH; incR
    ELSIF x.mode = RegI THEN
      IF x.a # 0 THEN OM4A.encDPImm32(mcode, OM4A.ADD, x.r, x.r, RH, x.a) END
    ELSE OM4S.Mark("address error")
    END;
    x.mode := Reg
  END loadAdr;

  PROCEDURE loadCond(VAR x: Item);
  BEGIN
    IF x.type.form = OM4B.Bool THEN
      IF x.mode = OM4B.Const THEN IF x.a = 0 THEN x.r := OM4A.NV ELSE x.r := OM4A.AL END
      ELSE load(x);
        IF ~mcode.lastInstrSetFlags THEN OM4A.encCMPImm(mcode, x.r, RH, 0) END;
        x.r := OM4A.NE; DEC(RH)
      END ;
      x.mode := Cond; x.a := 0; x.b := 0
    ELSE OM4S.Mark("not Boolean?")
    END
  END loadCond;

  PROCEDURE loadTypTagAdr(T: OM4B.Type);
    VAR x: Item;
  BEGIN x.mode := OM4B.Var; x.a := T.len; x.r := -T.mno; loadAdr(x)
  END loadTypTagAdr;

  PROCEDURE loadStringAdr(VAR x: Item);
  BEGIN x.r := 0; x.a := varsize+x.a; GetStaticVarAddress(x, RH);
    incR; x.mode := Reg; x.r := RH-1
  END loadStringAdr;

  (* Items: Conversion from constants or from Objects on the Heap to Items on the Stack*)

  PROCEDURE MakeConstItem*(VAR x: Item; typ: OM4B.Type; val: LONGINT);
  BEGIN x.mode := OM4B.Const; x.type := typ; x.a := val
  END MakeConstItem;

  PROCEDURE MakeRealItem*(VAR x: Item; val: REAL);
  BEGIN x.mode := OM4B.Const; x.type := OM4B.realType; x.a := SYSTEM.VAL(LONGINT, val)
  END MakeRealItem;

  PROCEDURE MakeStringItem*(VAR x: Item; len: LONGINT); (*copies string from OM4S-buffer to OM4G-string array*)
    VAR i: LONGINT;
  BEGIN x.mode := OM4B.Const; x.type := OM4B.strType; x.a := strx; x.b := len; i := 0;
    IF strx + len + 4 < maxStrx THEN
      WHILE len > 0 DO str[strx] := OM4S.str[i]; INC(strx); INC(i); DEC(len) END ;
      WHILE strx MOD 4 # 0 DO str[strx] := 0X; INC(strx) END
    ELSE OM4S.Mark("too many strings")
    END
  END MakeStringItem;

  PROCEDURE MakeItem*(VAR x: Item; y: OM4B.Object; curlev: LONGINT);
  BEGIN x.mode := y.class; x.type := y.type; x.a := y.val; x.rdo := y.rdo;
    IF y.class = OM4B.Par THEN x.b := 0
    ELSIF (y.class = OM4B.Const) & (y.type.form = OM4B.String) THEN x.b := y.lev  (*len*) ;
    ELSE x.r := y.lev
    END ;
    IF (y.lev > 0) & (y.lev # curlev) & (y.class # OM4B.Const) THEN OM4S.Mark("not accessible ") END
  END MakeItem;

  (* Code generation for Selectors, Variables, Constants *)

  PROCEDURE Field*(VAR x: Item; y: OM4B.Object);   (* x := x.y *)
  BEGIN;
    IF x.mode = OM4B.Var THEN
      IF x.r >= 0 THEN x.a := x.a + y.val
      ELSE loadAdr(x); x.mode := RegI; x.a := y.val
      END
    ELSIF x.mode = RegI THEN x.a := x.a + y.val
    ELSIF x.mode = OM4B.Par THEN x.b := x.b + y.val
    END
  END Field;

  PROCEDURE Index*(VAR x, y: Item);   (* x := x[y] *)
    VAR s, lim, p2: LONGINT;
  BEGIN s := x.type.base.size; lim := x.type.len;
    IF (y.mode = OM4B.Const) & (lim >= 0) THEN
      IF (y.a < 0) OR (y.a >= lim) THEN OM4S.Mark("bad index") END ;
      IF x.mode IN {OM4B.Var, RegI} THEN x.a := y.a * s + x.a
      ELSIF x.mode = OM4B.Par THEN x.b := y.a * s + x.b
      END
    ELSE load(y);
      IF check THEN  (*check array bounds*)
        IF lim >= 0 THEN OM4A.encCMPImm(mcode, y.r, RH, lim)
        ELSE (*open array*)
          IF x.mode IN {OM4B.Var, OM4B.Par} THEN
            incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a + 4 + frame); DEC(RH);
            OM4A.encCMPReg(mcode, y.r, RH)
          ELSE OM4S.Mark("error in Index")
          END
        END ;
        Trap(OM4A.CS, 1) (*ARM inverts the carry with SUB and CMP instructions*)
      END ;
      (* Compute the shift to apply when s is a power of two *)
      IF OM4A.log2(s, p2) # 1 THEN OM4A.encMUL(mcode, y.r, y.r, s); p2 := 0 END ;
      IF x.mode = OM4B.Var THEN
        IF x.r > 0 THEN OM4A.encDPReg(mcode, OM4A.ADD, y.r, SP, y.r, p2); INC(x.a, frame)
        ELSE GetStaticVarAddress(x, RH);
          OM4A.encDPReg(mcode, OM4A.ADD, y.r, RH, y.r, p2); x.a := 0
        END ;
        x.r := y.r; x.mode := RegI
      ELSIF x.mode = OM4B.Par THEN
        incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a + frame); DEC(RH);
        OM4A.encDPReg(mcode, OM4A.ADD, y.r, RH, y.r, p2); x.mode := RegI; x.r := y.r; x.a := x.b
      ELSIF x.mode = RegI THEN
        OM4A.encDPReg(mcode, OM4A.ADD, x.r, x.r, y.r, p2); DEC(RH)
      END
    END
  END Index;

  PROCEDURE DeRef*(VAR x: Item);
  BEGIN
    IF x.mode IN {OM4B.Var, OM4B.Par, RegI} THEN load(x); NilCheck(x.r)
    ELSIF x.mode # Reg THEN OM4S.Mark("bad mode in DeRef") END;
    x.mode := RegI; x.a := 0; x.b := 0
  END DeRef;

  PROCEDURE Q(T: OM4B.Type; VAR dcw: LONGINT);
  BEGIN (*one entry of type descriptor extension table*)
    IF T.base # NIL THEN
      Q(T.base, dcw); data[dcw] := (T.mno*1000H + T.len) * 1000H + dcw - fixORGT;
      fixORGT := dcw; INC(dcw)
    END
  END Q;

  PROCEDURE FindPtrFlds(typ: OM4B.Type; off: LONGINT; VAR dcw: LONGINT);
    VAR fld: OM4B.Object; i, s: LONGINT;
  BEGIN
    IF (typ.form = OM4B.Pointer) OR (typ.form = OM4B.NilTyp) THEN data[dcw] := off; INC(dcw)
    ELSIF typ.form = OM4B.Record THEN
      fld := typ.dsc;
      WHILE fld # NIL DO FindPtrFlds(fld.type, fld.val + off, dcw); fld := fld.next END
    ELSIF typ.form = OM4B.Array THEN
      s := typ.base.size;
      FOR i := 0 TO typ.len-1 DO FindPtrFlds(typ.base, i*s + off, dcw) END
    END
  END FindPtrFlds;

  PROCEDURE BuildTD*(T: OM4B.Type; VAR dc: LONGINT);
    VAR dcw, k, s: LONGINT;  (*dcw = word address*)
  BEGIN dcw := dc DIV 4; s := T.size; (*convert size for heap allocation*)
    IF s <= 24 THEN s := 32 ELSIF s <= 56 THEN s := 64 ELSIF s <= 120 THEN s := 128
    ELSE s := (s+263) DIV 256 * 256
    END ;
    T.len := dc; data[dcw] := s; INC(dcw);  (*len used as address*)
    k := T.nofpar;   (*extension level!*)
    IF k > 3 THEN OM4S.Mark("ext level too large")
    ELSE Q(T, dcw);
      WHILE k < 3 DO data[dcw] := -1; INC(dcw); INC(k) END
    END ;
    FindPtrFlds(T, 0, dcw); data[dcw] := -1; INC(dcw); tdx := dcw; dc := dcw*4;
    IF tdx >= maxTD THEN OM4S.Mark("too many record types"); tdx := 0 END
  END BuildTD;

  PROCEDURE TypeTest*(VAR x: Item; T: OM4B.Type; varpar, isguard: BOOLEAN);
    VAR pc0: LONGINT;
  BEGIN
    IF T = NIL THEN
      IF x.mode >= Reg THEN DEC(RH) END ;
      SetCC(x, OM4A.AL)
    ELSE (*fetch tag into RH*)
      IF varpar THEN incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, x.a+4+frame); DEC(RH)
      ELSE load(x);
        pc0 := mcode.pc; OM4A.Put1(mcode, OM4A.BCT1 + OM4A.EQ*OM4A.C8);  (*NIL belongs to every pointer type*)
        incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, x.r, RH, -8); DEC(RH)
      END;
      incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, RH-1, RH, T.nofpar*4);
      loadTypTagAdr(T);  (*tag of T*)
      OM4A.encCMPReg(mcode, RH-1, RH-2); DEC(RH, 2);
      IF ~varpar THEN OM4A.fix8(mcode, pc0, mcode.pc - pc0 - 4) END ;
      IF isguard THEN
        IF check THEN Trap(OM4A.NE, 2) END
      ELSE SetCC(x, OM4A.EQ);
        IF ~varpar THEN DEC(RH) END
      END
    END
  END TypeTest;

  (* Code generation for Boolean operators *)

  PROCEDURE Not*(VAR x: Item);   (* x := ~x *)
    VAR t: LONGINT;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    x.r := OM4A.negated(x.r); t := x.a; x.a := x.b; x.b := t
  END Not;

  PROCEDURE And1*(VAR x: Item);   (* x := x & *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    OM4A.Put0(mcode, OM4A.BRCSIG*OM4A.C27 + OM4A.negated(x.r)*OM4A.C22 + x.a);
    x.a := mcode.pc-4; OM4A.FixLink(mcode, x.b); x.b := 0
  END And1;

  PROCEDURE And2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := OM4A.merged(mcode, y.a, x.a); x.b := y.b; x.r := y.r
  END And2;

  PROCEDURE Or1*(VAR x: Item);   (* x := x OR *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    OM4A.Put0(mcode, OM4A.BRCSIG*OM4A.C27 + x.r*OM4A.C22 + x.b);
    x.b := mcode.pc-4; OM4A.FixLink(mcode, x.a); x.a := 0
  END Or1;

  PROCEDURE Or2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := y.a; x.b := OM4A.merged(mcode, y.b, x.b); x.r := y.r
  END Or2;

  (* Code generation for arithmetic operators *)

  PROCEDURE Neg*(VAR x: Item);   (* x := -x *)
  BEGIN
    IF x.type.form = OM4B.Int THEN
      IF x.mode = OM4B.Const THEN x.a := -x.a
      ELSE load(x); OM4A.encDPImm32(mcode, OM4A.RSB, x.r, x.r, RH, 0)
      END
    ELSIF x.type.form = OM4B.Real THEN
      IF x.mode = OM4B.Const THEN x.a := x.a + 7FFFFFFFH + 1
      ELSE loadFP(x); OM4A.encFPOpReg(mcode, OM4A.VNEG, x.r, 0, x.r)
      END
    ELSE (*form = Set*)
      IF x.mode = OM4B.Const THEN x.a := -x.a-1 
      ELSE load(x); OM4A.encDPImm32(mcode, OM4A.EOR, x.r, x.r, RH, -1)
      END
    END
  END Neg;

  PROCEDURE AddOp*(op: LONGINT; VAR x, y: Item);   (* x := x +- y *)
  BEGIN
    IF op = OM4S.plus THEN
      IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN x.a := x.a + y.a
      ELSIF y.mode = OM4B.Const THEN load(x);
        IF y.a # 0 THEN OM4A.encDPImm32(mcode, OM4A.ADD, x.r, x.r, RH, y.a) END
      ELSE load(x); load(y); OM4A.encDPReg(mcode, OM4A.ADD, RH-2, x.r, y.r, 0); DEC(RH); x.r := RH-1
      END
    ELSE (*op = OM4S.minus*)
      IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN x.a := x.a - y.a
      ELSIF y.mode = OM4B.Const THEN load(x);
        IF y.a # 0 THEN OM4A.encDPImm32(mcode, OM4A.SUB, x.r, x.r, RH, y.a) END
      ELSE load(x); load(y); OM4A.encDPReg(mcode, OM4A.SUB, RH-2, x.r, y.r, 0); DEC(RH); x.r := RH-1
      END
    END
  END AddOp;

  PROCEDURE MulOp*(VAR x, y: Item);   (* x := x * y *)
    VAR e: LONGINT;
  BEGIN
    IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN x.a := x.a * y.a
    ELSIF (y.mode = OM4B.Const) & (y.a >= 2) & (OM4A.log2(y.a, e) = 1) THEN load(x); OM4A.encShiftImm5(mcode, OM4A.LSl, x.r, x.r, e)
    (*Lower half 32bit of result of a multiplication (32b*32b => 32b) is the same for signed and unsigned integers*)
    ELSIF (x.mode = OM4B.Const) & (x.a >= 2) & (OM4A.log2(x.a, e) = 1) THEN load(y); OM4A.encShiftImm5(mcode, OM4A.LSl, y.r, y.r, e); x.mode := Reg; x.r := y.r
    ELSE load(x); load(y); OM4A.encMUL(mcode, RH-2, x.r, y.r); DEC(RH); x.r := RH-1
    END
  END MulOp;

  PROCEDURE DivOp*(op: LONGINT; VAR x, y: Item);   (* x := x op y *)
    VAR e: LONGINT;
  BEGIN
    IF op = OM4S.div THEN
      IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN
        IF y.a > 0 THEN x.a := x.a DIV y.a ELSE OM4S.Mark("bad divisor") END
      ELSIF (y.mode = OM4B.Const) & (y.a >= 2) & (OM4A.log2(y.a, e) = 1) THEN load(x); OM4A.encShiftImm5(mcode, OM4A.ASR, x.r, x.r, e)
      ELSIF y.mode = OM4B.Const THEN
        IF y.a > 0 THEN load(x); load(y); OM4A.encUDIV(mcode, RH-2, x.r, y.r); DEC(RH); x.r := RH-1 ELSE OM4S.Mark("bad divisor") END
      ELSE load(y);
        IF check THEN 
          IF ~mcode.lastInstrSetFlags THEN OM4A.encCMPImm(mcode, y.r, RH, 0) END;
          Trap(OM4A.LE, 6)
        END;
        load(x); OM4A.encUDIV(mcode, RH-2, x.r, y.r); DEC(RH); x.r := RH-1
      END
    ELSE (*op = OM4S.mod*)

      IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN
        IF y.a > 0 THEN x.a := x.a MOD y.a ELSE OM4S.Mark("bad modulus") END
      ELSIF (y.mode = OM4B.Const) & (y.a >= 2) & (OM4A.log2(y.a, e) = 1) THEN load(x);
        OM4A.encShiftImm5(mcode, OM4A.LSl, x.r, x.r, 32-e); OM4A.encShiftImm5(mcode, OM4A.LSR, x.r, x.r, 32-e)
      ELSIF y.mode = OM4B.Const THEN
        IF y.a > 0 THEN load(x); load(y); 
          OM4A.encUDIV(mcode, RH, x.r, y.r); OM4A.encMUL(mcode, RH, RH, y.r); OM4A.encDPReg(mcode, OM4A.SUB, RH-2, x.r, RH, 0);
          DEC(RH); x.r := RH-1
        ELSE OM4S.Mark("bad modulus") END
      ELSE load(y);
        IF check THEN 
          IF ~mcode.lastInstrSetFlags THEN OM4A.encCMPImm(mcode, y.r, RH, 0) END;
          Trap(OM4A.LE, 6)
        END;
        load(x); OM4A.encUDIV(mcode, RH, x.r, y.r); OM4A.encMUL(mcode, RH, RH, y.r); OM4A.encDPReg(mcode, OM4A.SUB, RH-2, x.r, RH, 0);
        DEC(RH); x.r := RH-1
      END
    END
  END DivOp;

  (* Code generation for REAL operators *)

  PROCEDURE RealOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
  BEGIN loadFP(x); loadFP(y);
    IF op = OM4S.plus THEN OM4A.encFPOpReg(mcode, OM4A.VADD, SH-2, x.r, y.r)
    ELSIF op = OM4S.minus THEN OM4A.encFPOpReg(mcode, OM4A.VSUB, SH-2, x.r, y.r)
    ELSIF op = OM4S.times THEN OM4A.encFPOpReg(mcode, OM4A.VMUL, SH-2, x.r, y.r)
    ELSIF op = OM4S.rdiv THEN OM4A.encFPOpReg(mcode, OM4A.VDIV, SH-2, x.r, y.r)
    END;
    DEC(SH); x.r := SH-1
  END RealOp;

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
      ELSE DEC(RH); OM4A.encDPReg(mcode, OM4A.BIC, RH-1, x.r, y.r, 0)
      END
    END
  END Set;

  PROCEDURE In*(VAR x, y: Item);  (* x := x IN y *)
  BEGIN load(y);
    IF x.mode = OM4B.Const THEN OM4A.encShiftImm5(mcode, OM4A.ROR, y.r, y.r, (x.a + 1) MOD 20H); DEC(RH)
    ELSE load(x); OM4A.encDPImm32(mcode, OM4A.ADD, x.r, x.r, RH, 1); OM4A.encShiftReg(mcode, OM4A.ROR, y.r, y.r, x.r); DEC(RH, 2)
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
          IF s = 1 THEN incR; OM4A.encDPImm32(mcode, OM4A.ADD, RH-1, RH-1, RH, 3); DEC(RH); OM4A.encShiftImm5(mcode, OM4A.ASR, RH, RH, 2)
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
    OM4A.encShiftImm5(mcode, OM4A.ASR, RH, RH, 24); OM4A.encBackBranch(mcode, OM4A.NE, pc0); (*BNE L0*)
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
    ELSIF ftype.form = OM4B.Record THEN
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

  PROCEDURE PrepCall*(VAR x: Item; VAR r, s: LONGINT);
  BEGIN (*x.type.form = OM4B.Proc*)
    IF x.mode > OM4B.Par THEN load(x) END ;
    r := RH; IF RH > 0 THEN OM4A.SaveRegs(mcode, RH, frame); RH := 0 END;
    s := SH; IF SH > 0 THEN OM4A.SaveFPRegs(mcode, SH, frame); SH := 0 END
  END PrepCall;

  PROCEDURE Call*(VAR x: Item; r, s: LONGINT);
  BEGIN (*x.type.form = OM4B.Proc*)
    IF x.mode = OM4B.Const THEN
      IF x.r >= 0 THEN OM4A.Put0(mcode, OM4A.BL + OM4A.formatEvenImm25(x.a - (mcode.pc+4)))
      ELSE (*imported*)
        IF mcode.pc - fixORGP < OM4A.C21 THEN
          OM4A.Put0(mcode, (-x.r)*OM4A.C28 + x.a*OM4A.C20 + (mcode.pc - fixORGP) DIV OM4A.C1); fixORGP := mcode.pc-4;
          (*Branching range is -16777216 to 16777214. If caller is in SDRAM (0xD0000000)
          * and callee in Flash (0x08000000), the offset will not be in the permissible
          * range. In this case, the loader will have to generate a "veneer code" near the caller
          * which will jump to the callee. This code could be LDR PC, [PC] followed by the absolute
          * callee address.*)
        ELSE OM4S.Mark("fixup impossible")
        END
      END
    ELSE
      IF x.mode <= OM4B.Par THEN load(x); DEC(RH)
      ELSE incR; OM4A.encMemImm32(mcode, OM4A.LDR, RH-1, SP, RH, 0); DEC(RH);
        OM4A.encDPImm32(mcode, OM4A.ADD, SP, SP, RH, 4); DEC(r); DEC(frame, 4)
      END ;
      IF check THEN 
        IF ~mcode.lastInstrSetFlags THEN incR; OM4A.encCMPImm(mcode, RH-1, RH, 0); DEC(RH) END;
        Trap(OM4A.EQ, 5) 
      END;
      OM4A.Put1(mcode, OM4A.BLX + RH*OM4A.C3)
    END ;
    IF x.type.base.form = OM4B.NoTyp THEN (*procedure*) RH := 0; SH := 0;
    ELSE (*function*)
      IF r > 0 THEN OM4A.encMOVReg(mcode, r, 0); 
        OM4A.RestoreRegs(mcode, r, frame) END ;
      IF s > 0 THEN (* VMOV Ss, S0*) OM4A.Put0(mcode, OM4A.VMOVSS + s DIV OM4A.C1*OM4A.C12 +
        s MOD OM4A.C1*OM4A.C22); OM4A.RestoreFPRegs(mcode, s, frame) END ;
      IF x.type.base.form = OM4B.Real THEN x.mode := FPReg; x.r := s; SH := s+1; RH := r 
      ELSE x.mode := Reg; x.r := r; RH := r+1; SH := s END
    END
  END Call;

  PROCEDURE Enter*(parblksize, locblksize: LONGINT; int: BOOLEAN);
    VAR r: LONGINT;
  BEGIN frame := 0;
    IF locblksize >= OM4A.C16 THEN OM4S.Mark("too many locals") END;
    IF int THEN (*interrupt procedure, lot of registers are already saved in interrupt frame*)
      (*Store interrupt frame address in R0*)
      OM4A.encDPImm32(mcode, OM4A.TST, 0, LR, RH, 4);
      OM4A.IfThen(mcode, "E", OM4A.EQ);
      OM4A.encMRS(mcode, 0, MSP);
      OM4A.encMRS(mcode, 0, PSP)
    END;

    IF locblksize - parblksize # 0 THEN
      OM4A.encDPImm32(mcode, OM4A.SUB, SP, SP, RH, locblksize - parblksize) END;

    r := LSL(1, (parblksize-4) DIV 4) - 1;
    IF r > 0 THEN
      IF r < OM4A.C8 THEN (*PUSH T1*) OM4A.Put1(mcode, OM4A.PUSHT1 + r)
      ELSE (*PUSH T2*) OM4A.Put0(mcode, OM4A.PUSHT2 + r) END
    END;
    (*PUSH T1 LR *) OM4A.Put1(mcode, OM4A.PUSHT1 + OM4A.C8)
  END Enter;

  PROCEDURE Return*(form: INTEGER; VAR x: Item; size: LONGINT; int: BOOLEAN);
  BEGIN
    IF form # OM4B.NoTyp THEN 
      IF x.type.form = OM4B.Real THEN loadFP(x); ELSE load(x) END
    END;
    (*POP T3 LR *) OM4A.encMemImm8PUW(mcode, OM4A.LDRIT4, LR, SP, FALSE, TRUE, TRUE, 4);
    IF size - 4 # 0 THEN OM4A.encDPImm32(mcode, OM4A.ADD, SP, SP, RH, size - 4) END;
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
  BEGIN loadAdr(x); loadTypTagAdr(x.type.base); Trap(OM4A.AL, 0); RH := 0; SH := 0
  END New;

  PROCEDURE Pack*(VAR x, y: Item);
    VAR z: Item;
  BEGIN (*Load x in a core register*)
    z := x; load(x); load(y);
    OM4A.encDPReg(mcode, OM4A.ADD, x.r, x.r, y.r, 23); DEC(RH); Store(z, x);
  END Pack;

  PROCEDURE Unpk*(VAR x, y: Item);
    VAR z, e0: Item;
  BEGIN (*Load x in a core register*)
    z := x; load(x); e0.mode := Reg; e0.r := RH; e0.type := OM4B.intType;
    OM4A.encShiftImm5(mcode, OM4A.ASR, RH, x.r, 23); 
    incR; OM4A.encDPImm32(mcode, OM4A.SUB, RH-1, RH-1, RH, 127); DEC(RH);
    Store(y, e0); incR; OM4A.encDPReg(mcode, OM4A.SUB, x.r, x.r, RH, 23); Store(z, x);
  END Unpk;

(* The SVC mechanism will be used to communicate with undelying firmware,
   in order to hide board level details, like the LED attachement to ports.*)
   
  PROCEDURE Led*(VAR x: Item);
  (*SVC #1 is assigned to LEDS*)
  BEGIN load(x); OM4A.Put1(mcode, OM4A.SVC + 1); DEC(RH)
  END Led;

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
  BEGIN
    IF y.mode = OM4B.Const THEN OM4A.encMOVImm32(mcode, x.a, y.a)
    ELSE load(y); OM4A.encMOVReg(mcode, x.a, y.r); DEC(RH)
    END
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
(* TODO uncomment only when using OM4 native compiler 
    IF x.mode = OM4B.Const THEN x.a := SQRT(x.a)
    ELSE *) loadFP(x); OM4A.encFPOpReg(mcode, OM4A.VSQRT, x.r, 0, x.r)
(*    END*)
  END Sqrt;

  PROCEDURE Odd*(VAR x: Item);
  BEGIN load(x); OM4A.encShiftImm5(mcode, OM4A.ROR, x.r, x.r, 1); SetCC(x, OM4A.MI); DEC(RH)
  END Odd;

  PROCEDURE Floor*(VAR x: Item);
  BEGIN loadFP(x); OM4A.encFPOpReg(mcode, OM4A.VCVTSF, x.r, 0, x.r);
    x.type.form := OM4B.Int;
  END Floor;

  PROCEDURE Float*(VAR x: Item);
  BEGIN x.type.form := OM4B.Real; loadFP(x);
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
  BEGIN load(x);
    IF fct = 0 THEN op := OM4A.LSl ELSIF fct = 1 THEN op := OM4A.ASR ELSE op := OM4A.ROR END ;
    IF y.mode = OM4B.Const THEN OM4A.encShiftImm5(mcode, op, x.r, x.r, y.a MOD 20H)
    ELSE load(y); OM4A.encShiftImm5(mcode, op, RH-2, x.r, y.r); DEC(RH); x.r := RH-1
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

  PROCEDURE Bit*(VAR x, y: Item);
  BEGIN load(x); OM4A.encMemImm32(mcode, OM4A.LDR, x.r, x.r, RH, 0);
    IF y.mode = OM4B.Const THEN OM4A.encShiftImm5(mcode, OM4A.ROR, x.r, x.r, y.a+1); DEC(RH)
    ELSE load(y); OM4A.encDPImm32(mcode, OM4A.ADD, y.r, y.r, RH, 1); OM4A.encShiftReg(mcode, OM4A.ROR, x.r, x.r, y.r); DEC(RH, 2)
    END ;
    SetCC(x, OM4A.MI)
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
  BEGIN NEW(mcode); OM4A.Init(mcode);
    tdx := 0; strx := 0; RH := 0; SH := 0; fixORGP := 0; fixORGD := 0; fixORGT := 0; check := v # 0; version := v;
    IF v = 0 THEN mcode.pc := 4;
      REPEAT mcode.code[mcode.pc] := 0; INC(mcode.pc) UNTIL mcode.pc = 8*4
    END
  END Open;

  PROCEDURE SetDataSize*(dc: LONGINT);
  BEGIN varsize := dc
  END SetDataSize;

  PROCEDURE Header*;
  BEGIN entry := mcode.pc;
    IF version = 0 THEN OM4A.modify(mcode, 0, OM4A.BT4 + OM4A.formatEvenImm25(mcode.pc-4))
    ELSE (*PUSH T1 LR *) OM4A.Put1(mcode, OM4A.PUSHT1 + OM4A.C8)
    END
  END Header;

  PROCEDURE NofPtrs(typ: OM4B.Type): LONGINT;
    VAR fld: OM4B.Object; n: LONGINT;
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
    VAR fld: OM4B.Object; i, s: LONGINT;
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
    VAR obj, obj2: OM4B.Object;
      i, comsize, nofimps, nofptrs, nofusedextprocs, size: LONGINT;
      name: OM4S.Ident;
      F: Files.File; R: Files.Rider;
  BEGIN  (*exit code*)
    IF version = 0 THEN
      (*OM4A.BX R0 : Jump to the beginning of the program loaded by the Boot Loader*)
      OM4A.encMOVImm32(mcode, 0, VarORG0); OM4A.Put1(mcode, OM4A.BX)
    ELSE (*POP T3 LR *) OM4A.encMemImm8PUW(mcode, OM4A.LDRIT4, LR, SP, FALSE, TRUE, TRUE, 4);
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
    size := varsize + strx + comsize + mcode.pc + (nofimps + nofent + nofptrs + 1)*4 + nofusedextprocs*8;  (*varsize includes type descriptors and trampolines*)
    
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
    mcode := NIL
  END Close;

BEGIN relmap[0] := OM4A.EQ; relmap[1] := OM4A.NE; relmap[2] := OM4A.LT; 
  relmap[3] := OM4A.LE; relmap[4] := OM4A.GT; relmap[5] := OM4A.GE;
END OM4G.
