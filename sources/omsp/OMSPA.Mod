MODULE OMSPA; (*C. Schoffit 19.05.24 Instruction encoder for MSP430 processor*) 
  IMPORT SYSTEM, OMSPS;

  CONST
    (*Powers of two*)
    C31*=80000000H; C30*=40000000H; C28*=10000000H; C27*=8000000H; C26*=4000000H;
    C25*=2000000H; C24*=1000000H; C23*=800000H; C22*=400000H; 
    C21*=200000H; C20*=100000H; C19*=80000H; C18*=40000H; C17*=20000H;
    C16*=10000H; C15*= 8000H; C13*=2000H; C12*=1000H; C11*=800H; 
    C10*=400H; C9*=200H;C8*=100H; C7*=80H; C6*=40H; C5*=20H; 
    C4*=10H; C3*=8; C2*=4; C1*=2; C0*=1;
    
    maxCode* = 16000*2;

    PC* = 0; SP* = 1; SR* = 2; CG1* = 2; CG2* = 3; (*special registers*)

  (* Cond definition 
    EQ equal (zero)        Z        NE not equal (#zero)   ~Z
    C carry set           C        NC carry clear         ~C
    N negative (minus)    N     
    GE greater or equal  ~(N#V)       L less than          N#V
    AL                     T
  *)
 
    NE* = 0; EQ* = 1; NC* = 2; C* = 3; N* = 4; GE* = 5; L* = 6; AL* = 7; NV* = 8;

  (*Addressing modes flags*)
    Rm* = {}; Im* = {4}; IRm* = {5}; IRAm* = {4..5}; (*source for format I or dest for format II instructions*)
    Rdm* = {}; Idm* = {7}; (*dest for format I instructions*)

  (*Addressing mode names*)
    Register* = 0; Indexed* = 1; Symbolic* = 2; Absolute* = 3; Indirect* = 4; IndirectIncr* = 5; Immediate* = 6; Undefined* = 255;

  (*Instruction size*)
    Byte* = {6}; Word* = {}; 

  (* opcodes *)
  (*Jump*)
  JMPh* = 20H;
  
  (*double operands*)
  (*|0100|*) MOV* = 4; (*hardware native operations*)
  (*|0101|*) ADD* = 5;
  (*|0110|*) ADDC* = 6;
  (*|0111|*) SUBC* = 7;
  (*|1001|*) SUB* = 8;
  (*|1001|*) CMP* = 9;
  (*|1010|*) DADD* = 10;
  (*|1011|*) BIT* = 11;
  (*|1100|*) BIC* = 12;
  (*|1101|*) BIS* = 13;
  (*|1110|*) XOR* = 14;
  (*|1111|*) AND* = 15;

  (*single operand*)
  (* |0/0010/0000| *) RRC* = 20H;
  (* |0/0010/0001| *) SWPB* = 21H;
  (* |0/0010/0010| *) RRA* = 22H;
  (* |0/0010/0011| *) SXT* = 23H;
  (* |0/0010/0100| *) PUSH* = 24H;
  (* |0/0010/0101| *) CALL* = 25H;
  (* |0/0010/0110| *) RETI* = 26H;

  (*emulated single operand*)
  (* |1/0000/0000| *) POP* = 100H;
  (* |1/0000/0001| *) RLA* = 101H;
  (* |1/0000/0002| *) RLC* = 102H;

  (*emulated no operand*)
  (* |1/1000/0000| *) RET* = 180H;

  (*|0000|*) MUL* = 0; (*software implemented operations*)
  (*|0001|*) NEG* = 1;
  (*|0002|*) DIv* = 2;
  (*|0003|*) MOd* = 3;

  TYPE
    ModuleCode* = POINTER TO ModuleCodeDesc;
    
    ModuleCodeDesc* = RECORD
      pc*: LONGINT; (*program counter*)
      code*: ARRAY maxCode OF BYTE;   (*MSP instructions are multiple of 16bit words, but this size does not exists in Oberon 07 cross compiler*)
      pos*: ARRAY maxCode DIV 2 OF INTEGER
    END;

    Item* = RECORD reg*, am*: BYTE; ofs*: INTEGER END;
    GetOffsetProc* = PROCEDURE(VAR x: Item): INTEGER;
    AllocRegisterProc* = PROCEDURE(): INTEGER;
    FreeRegisterProc* = PROCEDURE;

  VAR getOfs : GetOffsetProc; allocR: AllocRegisterProc; freeR: FreeRegisterProc;
     enabled: BOOLEAN;

  PROCEDURE SetProcs*(ofsp: GetOffsetProc; ar: AllocRegisterProc; fr: FreeRegisterProc);
  BEGIN getOfs := ofsp; allocR := ar; freeR := fr
  END SetProcs;

  PROCEDURE log2*(m: LONGINT; VAR e: LONGINT): LONGINT;
  BEGIN e := 0;
    WHILE ~ODD(m) DO m := LSR(m, 1); INC(e); END;
    RETURN m
  END log2;
 
  PROCEDURE SetEnabled*(e: BOOLEAN);
  BEGIN enabled := e
  END SetEnabled;

  (*instruction assemblers*)

  PROCEDURE Emit*(VAR c: ModuleCode; val: INTEGER);
  BEGIN
    IF enabled THEN
      c.code[c.pc+1] := LSR(val, 8) MOD C8;
      c.code[c.pc] := val MOD C8;
      c.pos[c.pc DIV 2] := S.Pos(); INC(c.pc, 2)
    END
  END Emit;

  PROCEDURE encSrc(VAR op: INTEGER; VAR SReg: BYTE; sam: BYTE; VAR SOff: INTEGER; VAR emitSOff: BOOLEAN; VAR params: SET);
  BEGIN
    IF sam = Register THEN ASSERT(SReg # CG2); params := params + Rm
    ELSIF sam = Indexed THEN ASSERT(~(SReg IN {PC, SR, CG2}));
      IF SOff # 0 THEN params := params + Im; emitSOff := TRUE ELSE params := params + IRm END
    ELSIF sam = Symbolic THEN SReg := PC; params := params + Im; emitSOff := TRUE
    ELSIF sam = Absolute THEN SReg := SR; params := params + Im; emitSOff := TRUE
    ELSIF sam = Indirect THEN ASSERT(~(SReg IN {SR, CG2})); params := params + IRm
    ELSIF sam = IndirectIncr THEN ASSERT(~(SReg IN {SR, CG2})); params := params + IRAm
    ELSIF sam = Immediate THEN 
      IF (SOff = 4) & (op # PUSH) (*W/A CPU4 errata*) THEN SReg := CG1; params := params + IRm
      ELSIF (SOff = 8) & (op # PUSH) THEN SReg := CG1; params := params + IRAm
      ELSIF SOff = 0 THEN SReg := CG2; params := params + Rm
      ELSIF SOff = 1 THEN SReg := CG2; params := params + Im
      ELSIF SOff = 2 THEN SReg := CG2; params := params + IRm
      ELSIF SOff = -1 THEN SReg := CG2; params := params + IRAm
      ELSIF (op = ADD) & (SOff < -1) THEN op := SUB; SOff := -SOff; encSrc(op, SReg, sam, SOff, emitSOff, params)
      ELSIF (op = SUB) & (SOff < -1) THEN op := ADD; SOff := -SOff; encSrc(op, SReg, sam, SOff, emitSOff, params)
      ELSE SReg := PC; params := params + IRAm; emitSOff := TRUE
    END
    ELSE S.DebugHex("encSrc sam", sam); ASSERT(FALSE)
    END;
  END encSrc;

 (*double operand instructions format (I):
    |                 A B              |
    | op /Sreg/dWAs/Dreg| *)

  PROCEDURE Put1(VAR c: ModuleCode; op, src, dst: BYTE; params: SET);
  BEGIN
    IF enabled THEN
      c.code[c.pc+1] := LSL(op, 4) + src;
      c.code[c.pc] := ORD(params) + dst;
      c.pos[c.pc DIV 2] := S.Pos(); INC(c.pc, 2)
    END
  END Put1;

  PROCEDURE PutDO*(VAR c: ModuleCode; op: INTEGER; VAR s, d: Item; params: SET);
    VAR emitSOff, emitDOff: BOOLEAN;
  BEGIN (*emit format I instruction*) ASSERT(params = params*Byte); emitSOff := FALSE; emitDOff := FALSE;
    ASSERT(s.reg < 16); ASSERT(d.reg < 16); ASSERT ((s.ofs >= -C15) & (s.ofs <= C16)); ASSERT ((d.ofs >= -C15) & (d.ofs <= C16));
    encSrc(op, s.reg, s.am, s.ofs, emitSOff, params);

    IF d.am = Register THEN ASSERT(d.reg # CG2); params := params + Rdm
    ELSIF d.am = Indexed THEN ASSERT(~(d.reg IN {PC, SR, CG2})); params := params + Idm; emitDOff := TRUE
    ELSIF d.am = Symbolic THEN d.reg := PC; params := params + Idm; emitDOff := TRUE
    ELSIF d.am = Absolute THEN d.reg := SR; params := params + Idm; emitDOff := TRUE
    ELSE ASSERT(FALSE)
    END;

    Put1(c, op, s.reg, d.reg, params);
    IF emitSOff THEN Emit(c, getOfs(s)) END;
    IF emitDOff THEN Emit(c, getOfs(d)) END
  END PutDO;

  (*single operand instructions format (II):
    |                   B               |
    | opc/ode / WAd/Dreg| *)

  PROCEDURE PutSO*(VAR c: ModuleCode; op: INTEGER; VAR ds: Item; params: SET);
    VAR emitDSOff: BOOLEAN; spi: Item;
  BEGIN (*emit format II instruction*) ASSERT(params = params*Byte);
    ASSERT(ds.reg < 16); ASSERT ((ds.ofs >= -C15) & (ds.ofs <= C16));
    emitDSOff := FALSE; spi.reg := SP; spi.am := IndirectIncr; spi.ofs := 0;
    IF op = POP THEN PutDO(c, MOV, spi, ds, Word)
    ELSIF op = RLA THEN PutDO(c, ADD, ds, ds, Word)
    ELSIF op = RLC THEN PutDO(c, ADDC, ds, ds, Word)
    ELSE ASSERT(op < 100H);
      encSrc(op, ds.reg, ds.am, ds.ofs, emitDSOff, params);

      IF enabled THEN
        c.code[c.pc+1] := LSR(op, 1);
        c.code[c.pc]   := LSL(op MOD C1, 7) + ORD(params) + ds.reg;
        c.pos[c.pc DIV 2] := S.Pos(); INC(c.pc, 2);
        IF emitDSOff THEN Emit(c, getOfs(ds)) END
      END
    END
  END PutSO;

  PROCEDURE eswSO*(VAR c: ModuleCode; op: BYTE; VAR d: Item; params: SET);
    VAR t: Item;
  BEGIN IF op = NEG THEN t.reg := 0; t.am := Immediate; t.ofs := -1; PutDO(c, XOR, t, d, params); t.ofs := 1; PutDO(c, ADD, t, d, params)
    ELSE (*TODO*) ASSERT(FALSE)
    END
  END eswSO;

  PROCEDURE eswDO*(VAR c: ModuleCode; op: BYTE; VAR s, d: Item; params: SET);
    VAR t: Item;
  BEGIN
    IF op = MUL THEN 
      IF s.am = Immediate THEN
        IF s.ofs = 0 THEN t.reg := 0; t.am := Immediate; t.ofs := 0; PutDO(c, MOV, t, d, params)
        ELSIF s.ofs < 0 THEN (*multiplicator is negative, change sign of multiplicator, do the multiplication, then change the sign of the result*)
          s.ofs := -s.ofs; eswDO(c, op, s, d, params); eswSO(c, NEG, d, params)
        ELSE (*multiplicator is positive*) WHILE ~ODD(s.ofs) DO PutDO(c, ADD, d, d, params); s.ofs := s.ofs DIV 2 END;
          t.am := Register; t.ofs := 0;
          IF s.ofs # 1 THEN t.reg := allocR(); PutDO(c, MOV, d, t, params);
            REPEAT PutDO(c, ADD, t, t, params); s.ofs := s.ofs DIV 2;
              IF ODD(s.ofs) THEN PutDO(c, ADD, t, d, params) END
            UNTIL s.ofs = 1;
            freeR
          END
        END
      ELSE (*todo multiplication*) ASSERT(FALSE)
      END
    ELSE (*TODO other ops*) ASSERT(FALSE)
    END
  END eswDO;

  (*jump instructions:
    |opcC/nd  /   o/ffse/t   | *)

  PROCEDURE PutJ*(VAR c: ModuleCode; cond: BYTE; offset: LONGINT);
  BEGIN (*emit jump instruction*) ASSERT (cond <=  NV); ASSERT(~ODD(offset));
    IF enabled THEN IF cond = NV THEN (*NOP*) cond := AL; offset := 0 END;
      offset := LSR(offset, 1);
      c.code[c.pc+1] := JMPh + LSL(cond, 2) + LSR(offset, 8) MOD 4;
      c.code[c.pc]   := offset MOD C8;
      c.pos[c.pc DIV 2] := S.Pos(); INC(c.pc, 2)
    END
  END PutJ;

  PROCEDURE PutNO*(VAR c: ModuleCode; op: INTEGER);
  BEGIN
    IF op = RET THEN Put1(c, MOV, SP, PC, IRAm + Rdm + Word)
    ELSE ASSERT(FALSE)
    END
  END PutNO;

  (*handling of forward reference, fixups of branch addresses and constant tables*)

  PROCEDURE negated*(cond: INTEGER): INTEGER;
  BEGIN ASSERT(cond  # N); (*negated of negative condition does not exist*)
    IF cond < N THEN cond := SYSTEM.VAL(BYTE, SYSTEM.VAL(SET, cond) / {0})
    ELSIF cond <= L THEN cond := (L+GE) - cond
    ELSE cond := (NV+AL) - cond
    END
    RETURN cond
  END negated;

  PROCEDURE fix*(VAR c: ModuleCode; at, with: LONGINT);
  (*The statement must be a jump*)
  BEGIN
    IF enabled THEN
      ASSERT(LSR(c.code[at+1], 5) = LSR(JMPh, 5)); (*Check op code*)
      ASSERT (~ODD(with)); with := with DIV 2;
      IF (with < -C10) OR (with >= C10) THEN S.Mark("jump too far")
      ELSE with := with MOD C8; 
        c.code[at+1] := LSL(LSR(c.code[at+1], 2), 2) + LSR(with, 8);
        c.code[at] := with MOD C8 
      END
    END
  END fix;

  PROCEDURE FixOne*(VAR c: ModuleCode; at: LONGINT);
  BEGIN 
    IF enabled THEN fix(c, at, c.pc-at-2) END
  END FixOne;

  PROCEDURE FixLink*(VAR c: ModuleCode; L: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    IF enabled THEN WHILE L # 0 DO L1 := (c.code[L+1] MOD C2*C8 + c.code[L])*2; fix(c, L, c.pc-L-2); L := L1 END END
  END FixLink;

  PROCEDURE FixLinkWith*(VAR c: ModuleCode; L0, dst: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    IF enabled THEN
      WHILE L0 # 0 DO
        L1 := (c.code[L0+1] MOD C2*C8 + c.code[L0])*2;
        fix(c, L0, dst-L0-2); L0 := L1
      END
    END
  END FixLinkWith;

  PROCEDURE merged*(VAR c: ModuleCode; L0, L1: LONGINT): LONGINT;
    VAR L2, L3: LONGINT;
  BEGIN
    IF enabled & (L0 # 0) THEN L3 := L0;
      REPEAT L2 := L3;
        ASSERT(LSR(c.code[L2+1], 13) = LSR(JMPh, 5)); (*must be a jump instruction*)
        L3 := (c.code[L2+1] MOD C2*C8 + c.code[L2])*2
      UNTIL L3 = 0;
      c.code[L2+1] := LSL(LSR(c.code[L2+1], 2), 2) + LSR(L1, 8);
      c.code[L2] := L1 MOD C8;
      L1 := L0
    END

    RETURN L1
  END merged;

  PROCEDURE PushRegs*(VAR c: ModuleCode; rl, rh: BYTE);
    VAR i: INTEGER; t: Item;
  BEGIN t.am := Register; t.ofs := 0;
    FOR i := rh TO rl BY -1 DO t.reg := i; PutSO(c, PUSH, t, Word) END
  END PushRegs;

  PROCEDURE SaveRegs*(VAR c: ModuleCode; r, n: BYTE; VAR frame: LONGINT);  (* R[r .. r+n-1]*)
  BEGIN (*n > 0*)
    PushRegs(c, r, r+n-1);
    INC(frame, 2*r)
  END SaveRegs;

  PROCEDURE PopRegs*(VAR c: ModuleCode; rl, rh: BYTE);
    VAR i: INTEGER; t: Item;
  BEGIN t.am := Register; t.ofs := 0;
    FOR i := rl TO rh DO t.reg := i; PutSO(c, POP, t, Word) END
  END PopRegs;

  PROCEDURE RestoreRegs*(VAR c: ModuleCode; r, n: BYTE; VAR frame: LONGINT); (*R[r .. r+n-1]*)
  BEGIN (*n > 0*)
    PopRegs(c, r, r+n-1);
    DEC(frame, 2*r)
  END RestoreRegs;

  PROCEDURE Init*(VAR c: ModuleCode);
  BEGIN c.pc := 0; enabled := TRUE
  END Init;

END OMSPA.
