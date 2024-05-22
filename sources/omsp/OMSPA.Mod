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

  (* Addressing modes *)
    Rm* = {}; Im* = {4}; IRm* = {5}; IRAm* = {4..5}; (*source for format I or dest for format II instructions*)
    Rdm* = {}; Idm* = {7}; (*dest for format I instructions*)

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
  (* |000100100| *) PUSH* = 24H;
  (* |000100101| *) CALL* = 25H;

  (*|0000|*) MUL* = 0; (*software implemented operations*)
  (*|0001|*) NEG* = 1;

  TYPE
    ModuleCode* = POINTER TO ModuleCodeDesc;
    
    ModuleCodeDesc* = RECORD
      pc*: LONGINT; (*program counter*)
      code*: ARRAY maxCode OF BYTE;   (*MSP instructions are multiple of 16bit words, but this size does not exists in Oberon 07 cross compiler*)
      pos*: ARRAY maxCode DIV 2 OF INTEGER
    END;

  PROCEDURE log2*(m: LONGINT; VAR e: LONGINT): LONGINT;
  BEGIN e := 0;
    WHILE ~ODD(m) DO m := LSR(m, 1); INC(e); END;
    RETURN m
  END log2;

  PROCEDURE AdToAs(params: SET): SET;
  BEGIN RETURN params*Byte + LSR(params*Idm, 3)
  END AdToAs;
  
  (*instruction assemblers*)

  PROCEDURE Emit*(VAR c: ModuleCode; val: INTEGER);
  BEGIN
    c.code[c.pc+1] := LSR(val, 8) MOD C8;
    c.code[c.pc] := val MOD C8;
  END Emit;

 (*double operand instructions format (I):
    |                 A B              |
    | op /Sreg/dWAs/Dreg| *)

  PROCEDURE PutDO*(VAR c: ModuleCode; op, SReg, DReg: BYTE; params: SET);
  BEGIN (*emit format I instruction*)
    c.code[c.pc+1] := LSL(op, 4) + SReg;
    c.code[c.pc] := ORD(params) + DReg;
    c.pos[c.pc DIV 2] := OMSPS.Pos(); INC(c.pc, 2)
  END PutDO;

  PROCEDURE PutDOImm16*(VAR c: ModuleCode; op: BYTE; imm16: INTEGER; DReg: BYTE; params: SET);
  BEGIN (*use constant generator if possible*)
    ASSERT (params*IRAm = {}); (*params must not contain any As flag*)
    IF imm16 = 4 THEN PutDO(c, op, CG1, DReg, params + IRm)
    ELSIF imm16 = 8 THEN PutDO(c, op, CG1, DReg, params + IRAm)
    ELSIF imm16 = 0 THEN PutDO(c, op, CG2, DReg, params + Rm)
    ELSIF imm16 = 1 THEN PutDO(c, op, CG2, DReg, params + Im)
    ELSIF imm16 = 2 THEN PutDO(c, op, CG2, DReg, params + IRm)
    ELSIF imm16 = -1 THEN PutDO(c, op, CG2, DReg, params + IRAm)
    ELSE PutDO(c, op, PC, DReg, params + IRAm); Emit(c, imm16)
    END
  END PutDOImm16;

  (*single operand instructions format (II):
    |                   B               |
    | opc/ode / WAd/Dreg| *)

  PROCEDURE PutSO*(VAR c: ModuleCode; op: LONGINT; DSReg: BYTE; params: SET);
  BEGIN (*emit format II instruction*)
    c.code[c.pc+1] := LSR(op, 1);
    c.code[c.pc]   := LSL(op MOD C1, 7) + ORD(params) + DSReg;
    c.pos[c.pc DIV 2] := OMSPS.Pos(); INC(c.pc, 2)
  END PutSO;

  PROCEDURE PutSOImm16*(VAR c: ModuleCode; op: BYTE; imm16: INTEGER; params: SET);
  BEGIN (*use constant generator if possible*)
    IF (imm16 = 4) & (op # PUSH (*workaround CPU4*)) THEN PutSO(c, op, CG1, params + IRm)
    ELSIF (imm16 = 8) & (op # PUSH (*workaround CPU4*)) THEN PutSO(c, op, CG1, params + IRAm)
    ELSIF imm16 = 0 THEN PutSO(c, op, CG2, params + Rm)
    ELSIF imm16 = 1 THEN PutSO(c, op, CG2, params + Im)
    ELSIF imm16 = 2 THEN PutSO(c, op, CG2, params + IRm)
    ELSIF imm16 = -1 THEN PutSO(c, op, CG2, params + IRAm)
    ELSE PutSO(c, op, PC, params + IRAm); Emit(c, imm16)
    END
  END PutSOImm16;

  PROCEDURE eswSO*(VAR c: ModuleCode; op: BYTE; DSReg: BYTE; params: SET; tmp: BYTE);
  BEGIN ASSERT (tmp < C4);
    IF op = NEG THEN PutDOImm16(c, XOR, -1, DSReg, params); PutDOImm16(c, ADD, 1, DSReg, params)
    ELSE (*TODO*) ASSERT(FALSE)
    END
  END eswSO;

  PROCEDURE eswDOImm16*(VAR c: ModuleCode; op: BYTE; imm16: INTEGER; DReg: BYTE; params: SET; tmp: BYTE);
  BEGIN ASSERT (tmp < C4);
    IF op = MUL THEN
      IF imm16 = 0 THEN PutDOImm16(c, MOV, 0, DReg, params)
      ELSIF imm16 < 0 THEN (*multiplicator is negative, change sign of multiplicator, do the multiplication, then change the sign of the result*)
        eswDOImm16(c, op, -imm16, DReg, params, tmp); eswSO(c, NEG, DReg, AdToAs(params), tmp)
      ELSE (*multiplicator is positive*) WHILE ~ODD(imm16) DO PutDO(c, ADD, DReg, DReg, AdToAs(params)); imm16 := imm16 DIV 2 END;
        IF imm16 # 1 THEN PutDO(c, MOV, DReg, tmp, AdToAs(params) + Rdm);
          REPEAT PutDO(c, ADD, tmp, tmp, params*Byte + Rm + Rdm); imm16 := imm16 DIV 2;
            IF ODD(imm16) THEN PutDO(c, ADD, tmp, DReg, AdToAs(params)) END
          UNTIL imm16 = 1
        END
      END
    ELSE (*TODO*) ASSERT(FALSE)
    END
  END eswDOImm16;

  (*jump instructions:
    |opcC/nd  /   o/ffse/t   | *)

  PROCEDURE PutJ*(VAR c: ModuleCode; cond: BYTE; offset: LONGINT);
  BEGIN (*emit jump instruction*) ASSERT (cond < 8);
    c.code[c.pc+1] := JMPh + LSL(cond, 2) + LSR(offset, 8);
    c.code[c.pc]   := offset MOD C8;
    c.pos[c.pc DIV 2] := OMSPS.Pos(); INC(c.pc, 2)
  END PutJ;

  (*handling of forward reference, fixups of branch addresses and constant tables*)

  PROCEDURE negated*(cond: INTEGER): INTEGER;
  BEGIN ASSERT(cond  # N); (*negated of negative condition does not exist*)
    IF cond < N THEN cond := SYSTEM.VAL(BYTE, SYSTEM.VAL(SET, cond) / {1})
    ELSIF cond <= L THEN cond := (L+GE) - cond
    ELSE cond := (NV+AL) - cond
    END
    RETURN cond
  END negated;

  PROCEDURE fix*(VAR c: ModuleCode; at, with: LONGINT);
  (*The statement must be a jump*)
  BEGIN
    ASSERT(LSR(c.code[at+1], 13) = LSR(JMPh, 5)); (*Check op code*)
    ASSERT (~ODD(with)); with := with DIV 2;
    IF (with < -C10) OR (with >= C10) THEN OMSPS.Mark("jump too far")
    ELSE with := with MOD C8; 
      c.code[at+1] := LSL(LSR(c.code[at+1], 2), 2) + LSR(with, 8);
      c.code[at] := with MOD C8 
    END
  END fix;

  PROCEDURE FixOne*(VAR c: ModuleCode; at: LONGINT);
  BEGIN fix(c, at, c.pc-at-2)
  END FixOne;

  PROCEDURE FixLink*(VAR c: ModuleCode; L: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    WHILE L # 0 DO L1 := (c.code[L+1] MOD C2*C8 + c.code[L])*2; fix(c, L, c.pc-L-2); L := L1 END
  END FixLink;

  PROCEDURE FixLinkWith*(VAR c: ModuleCode; L0, dst: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    WHILE L0 # 0 DO
      L1 := (c.code[L0+1] MOD C2*C8 + c.code[L0])*2;
      fix(c, L0, dst-L0-2); L0 := L1
    END
  END FixLinkWith;

  PROCEDURE merged*(VAR c: ModuleCode; L0, L1: LONGINT): LONGINT;
    VAR L2, L3: LONGINT;
  BEGIN 
    IF L0 # 0 THEN L3 := L0;
      REPEAT L2 := L3;
        ASSERT(LSR(c.code[L2+1], 13) = LSR(JMPh, 5)); (*must be a jump instruction*)
        L3 := (c.code[L2+1] MOD C2*C8 + c.code[L2])*2
      UNTIL L3 = 0;
      c.code[L2+1] := LSL(LSR(c.code[L2+1], 2), 2) + LSR(L1, 8);
      c.code[L2] := L1 MOD C8;
      L1 := L0
    END ;
    RETURN L1
  END merged;

  PROCEDURE PushRegs*(VAR c: ModuleCode; rl, rh: BYTE);
    VAR i: INTEGER;
  BEGIN
    FOR i := rh TO rl BY -1 DO PutSO(c, PUSH, i, Word + Rm) END
  END PushRegs;

  PROCEDURE SaveRegs*(VAR c: ModuleCode; r: BYTE; VAR frame: LONGINT);  (* R[16-r .. 15]*)
  BEGIN (*r > 0*)
    PushRegs(c, 16-r, 15);
    INC(frame, 2*r)
  END SaveRegs;

  PROCEDURE PopRegs*(VAR c: ModuleCode; rl, rh: BYTE);
    VAR i: INTEGER;
  BEGIN
    FOR i := rl TO rh DO PutDO(c, MOV, SP, i, Word + IRAm + Rdm) END
  END PopRegs;

  PROCEDURE RestoreRegs*(VAR c: ModuleCode; r: BYTE; VAR frame: LONGINT); (*R[16-5 .. 15]*)
  BEGIN (*r > 0*)
    PopRegs(c, 16-r, 15);
    DEC(frame, 2*r)
  END RestoreRegs;

  PROCEDURE Init*(VAR c: ModuleCode);
  BEGIN
    c.pc := 0
  END Init;

END OMSPA.
