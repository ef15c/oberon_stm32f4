MODULE OM4A; (*C. Schoffit 10/11/2023 Instruction encoder for Cortex M4F processor*) 
  IMPORT OM4S;
  
  CONST
    (*Powers of two*)
    C30*=40000000H; C28*=10000000H; C27*=8000000H; C26*=4000000H;
    C25*=2000000H; C24*=1000000H; C23*=800000H; C22*=400000H; 
    C21*=200000H; C20*=100000H; C19*=80000H; C18*=40000H; C17*=20000H;
    C16*=10000H; C13*=2000H; C12*=1000H; C11*=800H; 
    C10*=400H; C9*=200H;C8*=100H; C7*=80H; C6*=40H; C5*=20H; 
    C4*=10H; C3*=8; C2*=4; C1*=2;
    
    maxCode* = 16000*4;
    
  (* Cond definition 
    MI negative (minus)    N        PL positive (plus)     ~N
    EQ equal (zero)        Z        NE not equal (#zero)   ~Z
    CS carry set           C        CC carry clear         ~C
    VS overflow set        V        VC overflow clear      ~V
    LS less or same      ~C|Z       HI high             ~(~C|Z)
    LT less than          N#V       GE greater or equal  ~(N#V)
    LE less or equal    (N#V)|Z     GT greater than  ~((N#V)|Z)
    AL                     T        NV                      F
 *)
 
    MI* = 4; PL* = 5; EQ* = 0; NE* = 1; LT* = 11; GE* = 10; LE* = 13; GT* = 12;
    CC* = 3; AL* = 14; NV*=15;

    IT*  = 0BF00H; (*If-Then base*)

    CoP*     = 0ED000000H; (*Coprocessor instruction*)

    BCT1*    = 0D000H;
    (*|1101 cond   imm8   |*)
    BT2*     = 0E000H;
    (*|1110 0   imm11     |*)
    BCT3*    = 0F0008000H;
    (*|1111/0Sco/nd i/mm6 /10J0/J   / imm/11  |
                             1  2             *)
    BT4*    = 0F0009000H;
    (*|11110S   imm10  10J1J   imm11   |
      |                  1 2           |
      B.W T4*)
    BL*     = 0F000D000H;
    (*|1111/0S  /im10/    /11J1/J   /im11/    |
                             1  2
      BL<c><q> <label>*)
    BLX*    = 4780H;
    (*|0100/0111/1 Rm/ 000|
      BLX<c> <Rm>*)
    BX*     = 4700H;
    (*|0100/0111/0 Rm/ 000|
      BX<c><q> <Rm>*)

    MOVIT3*    = 0F2400000H;
    (*|1111/0i10/0100/imm4/0im3/ Rd / imm/8   |
      MOVW<c> <Rd>,#<imm16>*)
    MOVIT1*    = 2000H;
    (*|0010/0 Rd/  im/m8  |
      MOVS <Rd>,#<imm8>*)
    MOVT*    = 0F2C00000H;

    MOVRT1*  = 4600H;
    (*|0100/0110/D Rm/  Rd|
      MOV<c> <Rd>,<Rm>*)
      
    VMOVSR*  = 0EE000A10H;
    (*|1110/1110/000o/ Vn / Rt /1010/N001/0000|
      VMOV (between Arm core register and single-precision register)
      VMOV{<c>}{<q>} <Sn>,<Rt> o=0*)
    VMOVRS*  = 0EE100A10H;
    (*|1110/1110/000o/ Vn / Rt /1010/N001/0000|
      VMOV (between Arm core register and single-precision register)
      VMOV{<c>}{<q>}<Rt>,<Sn> o=1*)
    VMOVSS*  = 0EEB00A40H;
    (*|1110 1110 1D11 0000  Vd  101s 01M0  Vm |
      VMOV<c>.F32 <Sd>, <Sm>*)
      
    VLDRT2*    = 0ED100A00H;
    (*|1110 1101 UD01   Rn  Vd  1010   imm8   |
      VLDR<c> <Sd>, [<Rn>{, #+/-<imm>}]*)
    VSTRT2*  = 0ED000A00H;
    (*|1110 1101 UD00  Rn   Vd  1010   imm8   |
      VSTR<c> <Sd>, [<Rn>{, #+/-<imm>}]*)
    
    VNEG*    = 0EEB10A40H;
    (*|1110 1110 1D11 0001  Vd  101s 01M0  Vm |
      VNEG<c>.F32 <Sd>, <Sm>*)
    VADD*    = 0EE300A00H;
    (*|1110 1110 0D11  Vn   Vd  101s N0M0  Vm |
      VADD<c>.F32 <Sd>, <Sn>, <Sm>*)
    VSUB*    = 0EE300A40H;
    (*|1110 1110 0D11  Vn   Vd  101s N1M0  Vm |
      VSUB<c>.F32 <Sd>, <Sn>, <Sm>*)
    VMUL*    = 0EE200A00H;
    (*|1110 1110 0D10  Vn   Vd  101s N0M0  Vm |
      VMUL<c>.F32 <Sd>, <Sn>, <Sm>*)
    VDIV*    = 0EE800A00H;
    (*|1110 1110 1D00  Vn   Vd  101s N0M0  Vm |
      VDIV<c>.F32 <Sd>, <Sn>, <Sm>*)
    VCMP0*   = 0EEB50A40H;
    (*|1110 1110 1D11 0101  Vd  101s E100 0000|
      VCMP{E}<c>.F32 <Sd>, #0.0*)
    VCMP*    = 0EEB40A40H;
    (*|1110 1110 1D11 0100  Vd  101s E1M0  Vm |
      VCMP{E}<c>.F32 <Sd>, <Sm>*)
    VABS*    = 0EEB00AC0H;
    (*|1110/1110/1D11/0000/ Vd /101s/11M0/ Vm |
      VABS<c>.F32 <Sd>, <Sm>*)
    VCVTSF*  = 0EEBD0A40H;
    (*|1110/1110/1D11/1op2/ Vd /101s/o1M0/ Vm |
      VCVT{R}{<c>}{<q>}.S32.F32 <Sd>, <Sm> Encoded as op2 = b101, sz = 0, o = 0*)
    VCVTFS*  = 0EEB80AC0H;
    (*|1110/1110/1D11/1op2/ Vd /101s/o1M0/ Vm |
      VCVT{<c>}{<q>}.F32.<Tm> <Sd>, <Sm> Encoded as op2 = b000, s = 0, o = 1*)
    
    VMRS*    = 0EEF10A10H;
    (*|1110 1110 1111 0001  Rt  1010 0001 0000|
      VMRS<c> <Rt>, FPSCR*)
    
    LDRIT3*  = 0F8D00000H;
    (*|1111/1000/1101/ Rn / Rt /    /imm1/2   |
      LDR<c>.W <Rt>,[<Rn>{,#<imm12>}]*)
    LDRIT4*  = 0F8500800H;
    (*|1111/1000/0101/ Rn / Rt /1PUW/ imm/8   |
      LDR<c> <Rt>,[<Rn>,#-<imm8>]
      LDR<c> <Rt>,[<Rn>],#+/-<imm8>
      LDR<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    LDRBIT2* = 0F8900000H;
    (*|1111 1000 1001  Rn   Rt      imm12     |
      LDRB<c>.W <Rt>,[<Rn>{,#<imm12>}]*)
    LDRBIT3* = 0F8100800H;
    (*|1111 1000 0001  Rn   Rt  1PUW   imm8   |
      LDRB<c> <Rt>,[<Rn>,#-<imm8>]
      LDRB<c> <Rt>,[<Rn>],#+/-<imm8>
      LDRB<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    STRIT3* = 0F8C00000H;
    (*|1111/1000/1100/ Rn / Rt /    /imm1/2   |
      STR<c>.W <Rt>,[<Rn>,#<imm12>]*)
    STRIT4* = 0F8400800H;
    (*|1111/1000/0100/ Rn / Rt /1PUW/ imm/8   |
      STR<c> <Rt>,[<Rn>,#-<imm8>]
      STR<c> <Rt>,[<Rn>],#+/-<imm8>
      STR<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    STRBIT2* = 0F8800000H;
    (*|1111 1000 1000  Rn   Rt      imm12     |
      STRB<c>.W <Rt>,[<Rn>,#<imm12>]*)

    PUSHT1* = 0B400H;
    (*|1011/010M/reg_/list|
      PUSH<c> <registers>*)
    PUSHT2* = 0E92D0000H;
    (*|1110/1001/0010/1101/0M0 /reg_/list/    |
      PUSH<c>.W <registers>*)
    POPT1*  = 0BC00H;
    (*|1011/110P/reg_/list|
      POP<c> <registers>*)
    POPT2*  = 0E8BD0000H;
    (*|1110/1000/1011/1101/PM0 /reg_/list/    |
      POP<c>.W <registers>*)
    
    CMPIT1*  = 2800H;
    CMPIT2*  = 0F1B00F00H;
    CMPRT1*  = 4280H;
    CMPRT2*  = 4500H;

    SVC*     = 0DF00H;
    (*|1101/1111/ imm/8   |
      SVC<c> #<imm8>*)
    
    BFC*     = 0F36F0000H;
    (*|1111/0011/0110/1111/0im3/ Rd /im0 /msb |
      BFC<c> <Rd>,#<lsb>,#<width>*)
    
    BRSIG*   = 1EH;

    
    (* Arithmetic and logical operations *)
    SUB*=0; ADD*=1; RSB*=2; EOR*=3; AND*=4; BIC*=5; ORR*=6; ADc*=7; SBc*=8; TST*=9;

    (* Shift operations *)
    LSl*=0; ASR*=1; LSR*=2; ROR*=3;

    MULT1*  = 4340H;
    (*|0100/0011/01Rn/ Rdm|
      MULS <Rdm>,<Rn>,<Rdm>   Outside IT block.
      MUL<c> <Rdm>,<Rn>,<Rdm> Inside IT block.*)
    MULT2*  = 0FB00F000H;
    (*|1111/1011/0000/ Rn /1111/ Rd /0000/ Rm |
      MUL<c> <Rd>,<Rn>,<Rm>*)
    UDIV*  = 0FBB0F0F0H;
    (*|1111/1011/1011/ Rn /1111/ Rd /1111/ Rm |
      UDIV<c><q> {<Rd>,} <Rn>, <Rm>*)
    UMULL* = 0FBA00000H;
  (*|1111/1011/1010/ Rn /RdLo/RdHi/0000/ Rm |
    UMULL<c><q> <RdLo>, <RdHi>, <Rn>, <Rm>*)
    
(*  Format of pseudo operations for accessing external vars and procs

    These pseudo-instructions will be fixup at load or link time by
    the Modules or OM4L modules.

  1/ Variables
    The size of the offset is limited to 12 bits, that is 1K words.
    This is too short to implement the fixup link. We'll use pseudo
    LDR/STR/ADD instructions.

    Getting base address
    LDR:
    aaaannnndddddddddddddddddddddddd
    
    aaaa: destination register
    nnnn: number of the module
    dd24: offset DIV 2 of next op to fix for SB loading
    
    Accessing external variable
    LDR/STR/ADD
    ooosaaaabbbb000000000000000pvvvv
    
    ooo:  operation code 000: LDR, 001: STR, 010: ADD
    s:    size of operation (0: 4 bytes, 1: 1 byte)
    aaaa: destination register
    bbbb: operand register
    p:    program based variable
    vvvv: number of the variable
  
  2/ Procedures
    No need to encode the instruction wich is always 
    LDR r, <proc address>+1:
    
    aaaannnnppppppppdddddddddddddddd

    aaaa: destination register
    nnnn:     number of the module
    pppppppp: number of the procedure
    dd16: offset DIV 2 of next op to fix for procedure address loading
*)
    EXTLDR* =0; EXTSTR* =2; EXTADD* =4;
    EXTLDRB*=1; EXTSTRB*=3; EXTADDB*=5;
    EXTVLDR*=6; EXTVSTR*=7;

  TYPE
    ModuleCode* = POINTER TO ModuleCodeDesc;
    
    ModuleCodeDesc* = RECORD
      pc*: LONGINT; (*program counter*)
      nbRmnITBlockInsts: LONGINT; (*Number of remaining instructions in current IT block*)
      lastInstrSetFlags*: BOOLEAN; (*TRUE if last instructions set flags*)
      code*: ARRAY maxCode OF BYTE;   (*Cortex M4 thumb uses 16bit half-words, but this size does not exists in Oberon 07*)
    END;

  VAR
    imm3map: ARRAY 10 OF LONGINT;
    imm8map: ARRAY 10 OF LONGINT;
    immthmap: ARRAY 10 OF LONGINT;
    imm12map: ARRAY 10 OF LONGINT;
    
    reg3map: ARRAY 10 OF LONGINT;
    reg4map: ARRAY 10 OF LONGINT;
    reg4shmap: ARRAY 10 OF LONGINT;

    shimm5map: ARRAY 4 OF LONGINT;
    shimm5wmap: ARRAY 4 OF LONGINT;

    shreg3map: ARRAY 4 OF LONGINT;
    shreg4map: ARRAY 4 OF LONGINT;

  (*instruction assemblers*)

  PROCEDURE modify*(VAR c: ModuleCode; at: LONGINT; with: LONGINT);
  BEGIN
    c.code[at+1] := with DIV C24;
    c.code[at]   := with DIV C16 MOD C8;
    c.code[at+3] := with DIV C8 MOD C8;
    c.code[at+2] := with MOD C8;
  END modify;

  PROCEDURE load24(VAR c: ModuleCode; at: LONGINT): LONGINT;
    VAR res: LONGINT;
  BEGIN
    res := (c.code[at+3]*C8+c.code[at+2])*C8+c.code[at+1];
    RETURN res
  END load24;
  
  PROCEDURE Put0*(VAR c: ModuleCode; op: LONGINT);
  BEGIN (*emit format-0 instruction (32bit)
         format: op8:p24 *)
    c.lastInstrSetFlags := FALSE;
    IF c.nbRmnITBlockInsts > 0 THEN DEC(c.nbRmnITBlockInsts) END;
    modify(c, c.pc, op);
    INC(c.pc, 4)
  END Put0;

  PROCEDURE Put1*(VAR c: ModuleCode; op: LONGINT);
  BEGIN (*emit format-1 instruction (16bit)*)
    c.lastInstrSetFlags := FALSE;
    IF c.nbRmnITBlockInsts > 0 THEN DEC(c.nbRmnITBlockInsts) END;
    c.code[c.pc+1] := op DIV C8 MOD C8;
    c.code[c.pc]   := op MOD C8;
    INC(c.pc, 2)
  END Put1;

  PROCEDURE formatEvenImm25*(disp: LONGINT): LONGINT;
  (* |00000S   imm10  00J0J   imm11   |
     |                  1 2
     I1 = NOT(J1 EOR S); I2 = NOT(J2 EOR S); imm32 = SignExtend(S:I1:I2:imm10:imm11:'0', 32);
  *) 
  VAR res: LONGINT;
    S, J1, J2: BYTE;
    imm10, imm11: LONGINT;
  BEGIN
    ASSERT(~ODD(disp));
    IF (disp < -16777216) OR (disp >= 16777216) THEN OM4S.Mark("jump too far") END;
    disp := disp DIV C1;
    S := disp DIV C23 MOD C1;
    disp := disp MOD C23;
    (*J1 = NOT(I1) EOR S
     J2 = NOT(I2) EOR S*)
    J1 := disp DIV C22 MOD C1;
    disp := disp MOD C22;
    J2 := disp DIV C21 MOD C1;
    disp := disp MOD C21;
    IF S=0 THEN
      J1 := 1-J1;
      J2 := 1-J2;
    END;
    imm10 := disp DIV C11 MOD C10;
    imm11 := disp MOD C11;
 
    RETURN imm11 + S*C26 + imm10*C16+J1*C13+J2*C11
  END formatEvenImm25;
  
  PROCEDURE formatShiftImm5*(shift: LONGINT): LONGINT;
  BEGIN
    ASSERT(shift < C5);
    RETURN shift DIV C2*C12 + shift MOD C2*C6
  END formatShiftImm5;

  PROCEDURE format2Reg4*(a, b: BYTE): LONGINT;
  BEGIN
    ASSERT ((a < C4) & (b < C4));
    RETURN 0 + a DIV 3*C7 + b*C3 + a MOD 3
  END format2Reg4;
  
  PROCEDURE format3Reg4*(a, b, c: BYTE): LONGINT;
  BEGIN
    ASSERT ((a < C4) & (b < C4) & (c < C4));
    RETURN 0 + b*C16 + a*C8 + c
  END format3Reg4;
  
  PROCEDURE formatPUWImm8*(p, u, w: BOOLEAN; imm8: LONGINT): LONGINT;
  BEGIN
    ASSERT((imm8 >= 0) & (imm8 < C8));
    RETURN ORD(p)*C10 + ORD(u)*C9 + ORD(w)*C8 + imm8
  END formatPUWImm8;
  
  PROCEDURE formatThumbExpandImm*(val: LONGINT; VAR res: LONGINT): BOOLEAN;
  (* Put |0000/0i00/0000/0000/0im3/0000/abcd/efgh| in res if  val can be
     encoded as "modified immediate constants" in a thumb instruction
     or return false if it can't*)
    VAR a, b, c, d : LONGINT;
      retv : BOOLEAN;
  BEGIN
    retv := FALSE;
    d := val MOD C8;
    a := val DIV C8;
    c := a MOD C8;
    a := a DIV C8;
    b := a MOD C8;
    a := a DIV C8;
    
    IF val DIV C8 = 0 THEN res := d; retv := TRUE
    ELSIF (a = 0) & (b = d) & (c = 0) THEN res := C12 + d; retv := TRUE
    ELSIF (a = c) & (b = 0) & (d = 0) THEN res := C13 + d; retv := TRUE
    ELSIF (a = b) & (a = c) & (a = d) THEN res := C12+ C13 + d; retv := TRUE
    ELSE
      c := d MOD C7;
      a := (c + C7)*C24;
      b := 8;
      WHILE (b <= 23) & ~retv DO
        IF (a = val) THEN res := b DIV C4*C26 + b DIV C1 MOD C3*C12 + b MOD C1*C7 + c; ; retv := TRUE
        ELSE a := a DIV C1; INC(b)
        END
      END
    END;
    RETURN retv
  END formatThumbExpandImm;
  
  PROCEDURE formatImm16*(reg: BYTE; val: LONGINT): LONGINT;
  (*|xxxxxixxxxxximm4ximm reg  imm8  |
    |                   3            |
    val = imm4:i:imm3:imm8*)
  BEGIN
    RETURN val DIV C12 MOD C4*C16 + val DIV C11 MOD C1*C26 + 
           val DIV C8 MOD C3*C12 + reg*C8 + val MOD C8
  END formatImm16;

  PROCEDURE encMOVImm32*(VAR c: ModuleCode; reg: BYTE; val: LONGINT);
  VAR hw: LONGINT;  
  BEGIN
    ASSERT(reg < 16);
    hw := val MOD C16;
    IF (reg < 8) & (hw < C8) THEN 
      c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(c, MOVIT1 + reg*C8 + hw);
    ELSE Put0(c, MOVIT3 + formatImm16(reg, val)) END;
    hw := val DIV C16 MOD C16;
    IF hw # 0 THEN
      ASSERT(c.nbRmnITBlockInsts = 0);
      Put0(c, MOVT + formatImm16(reg, val))
    END
  END encMOVImm32;

  PROCEDURE encMemImm12*(VAR c: ModuleCode; op, a, b: BYTE; imm: LONGINT; msg: ARRAY OF CHAR);
  BEGIN
  (*|111110001101 Rn  Rt   imm12     |
     F   8   D LDR (immediate) T3
    
    |111110001001 Rn  Rt   imm12     |
     F   8   9 LDRB (immediate) T2*)
    IF imm >= C12 THEN OM4S.Mark(msg) END;
    Put0(c, op + a*C12 + b*C16 + imm);
  END encMemImm12;
  
  PROCEDURE encDPImm32*(VAR c: ModuleCode; op, a, b, t: BYTE; imm: LONGINT);
    VAR tmiCode: LONGINT;
  BEGIN
    ASSERT (op <= TST);
    ASSERT ((a < C4) & (b < C4) & (t < C4));
    IF (imm >= 0) & (imm < C3) & (a < C3) & (b < C3) & (imm3map[op] # 0) THEN
      (*|   op  immbbbaaa|
        RSB (immediate) T1*)
      c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(c, imm3map[op] + imm*C6 + b*C3 + a)
    ELSIF (imm >= 0) & (imm < C8) & (a < C3) & (a = b) & (imm8map[op] # 0) THEN
      c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(c, imm8map[op] + a*C8 + imm)
    ELSIF formatThumbExpandImm(imm, tmiCode) THEN
      Put0(c, immthmap[op] + b*C16 + a*C8 + tmiCode);
      c.lastInstrSetFlags := ODD(reg4shmap[op] DIV C20);
    ELSIF (imm >= 0) & (imm < C12)  & (imm12map[op] # 0) THEN
      (*|  o1 i  o2 sbbbboim3aaaa  imm8  |
        RSB (immediate) T2*) 
      Put0(c, imm12map[op] + imm DIV C11 MOD C1*C20 + b*C16 +
        imm DIV C8 MOD C3*C12 + a*C8 + imm MOD C8);
      c.lastInstrSetFlags := ODD(imm12map[op] DIV C20);
    ELSE
      ASSERT(c.nbRmnITBlockInsts = 0);
      encMOVImm32(c, t, imm);
      IF (a < C3) & (b < C3) & (t < C3) & (reg3map[op] # 0) THEN
        c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
        Put1(c, reg3map[op] + t*C6 + b*C3 + a)
      ELSE Put0(c, reg4shmap[op] + format3Reg4(a, b, 0) + t);
        c.lastInstrSetFlags := ODD(reg4shmap[op] DIV C20);
      END
    END
  END encDPImm32;
  
  PROCEDURE encDPReg*(VAR co: ModuleCode; op, a, b, c: BYTE; shift: LONGINT);
  BEGIN
    ASSERT (op <= TST);
    ASSERT ((a < C4) & (b < C4) & (c < C4));
    IF (a < C3) & (b < C3) & (c < C3) & (shift = 0) & (reg3map[op] # 0) THEN
      (*ADD/SUB (Register) T1*)
      co.lastInstrSetFlags := co.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(co, reg3map[op] + c*C6 + b*C3 + a)
    ELSIF (a = b) & (shift = 0) & (reg4map[op] # 0) THEN
      (*ADD (Register) T2*)
      Put1(co, reg4map[op] + a DIV C3*C7 + c*C3 + a MOD C3)
    ELSE (*ADD (Register) T3, SUB (Register) T2 *)
      Put0(co, reg4shmap[op] + format3Reg4(a, b, c) + formatShiftImm5(shift));
      co.lastInstrSetFlags := ODD(reg4shmap[op] DIV C20);
    END
  END encDPReg;
  
  PROCEDURE encShiftImm5*(VAR c: ModuleCode; op, a, b: BYTE; shift: LONGINT);
  BEGIN
    ASSERT (op <= ROR);
    ASSERT ((a < 15) & (b < C4) & (shift < C5));
    IF (a < C3) & (b < C3) & (shimm5map[op] # 0FFFFH) THEN Put1(c, shimm5map[op] + shift*C6 + b*C3 + a);
      c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
    ELSE Put0(c, shimm5wmap[op] + a*C8 + b + formatShiftImm5(shift));
      c.lastInstrSetFlags := ODD(shimm5wmap[op] DIV C20)
    END
  END encShiftImm5;
  
  PROCEDURE encShiftReg*(VAR co: ModuleCode; op, a, b, c: BYTE);
  BEGIN
    ASSERT (op <= ROR);
    ASSERT((a < 15) & (a # 13) & (b < 15) & (b # 13) & (c < 15) & (c # 13));
    IF (a < C3) & (a = b) THEN Put1(co, shreg3map[op] + c*C3 + a);
      co.lastInstrSetFlags := co.nbRmnITBlockInsts = 0; (* not in IT block *)
    ELSE
      Put0(co, shreg4map[op] + format3Reg4(a, b, c));
      co.lastInstrSetFlags := ODD(shreg4map[op] DIV C20)
    END
  END encShiftReg;
  
  PROCEDURE encCMPImm8*(VAR c: ModuleCode; a, imm: LONGINT);
  BEGIN
    ASSERT(a < 15);
    ASSERT((imm >= 0) & (imm < C8));
    IF a < 8 THEN Put1(c, CMPIT1 + a*C3 + imm)
    ELSE Put0(c, CMPIT2 + a*C16 + imm) END;
    c.lastInstrSetFlags := TRUE
  END encCMPImm8;
  
  PROCEDURE encCMPReg*(VAR c: ModuleCode; a, b: BYTE);
  BEGIN
    ASSERT((a < 15) & (b < 15));
    IF (a < 8) & (b < 8) THEN
      (*CMP (register) T1*)
      Put1(c, CMPRT1 + b*C3 + a)
    ELSE (*CMP (register) T2*)
      Put1(c, CMPRT2 + format2Reg4(a, b))
    END;
    c.lastInstrSetFlags := TRUE
  END encCMPReg;
  
  PROCEDURE encMOVReg*(VAR c: ModuleCode; a, b: BYTE);
  BEGIN
    ASSERT((a # 15) OR (c.nbRmnITBlockInsts <= 1));
    Put1(c, MOVRT1 + a DIV 3*C7 + b*C3 + a MOD 3)
  END encMOVReg;
  
  PROCEDURE encMUL*(VAR co: ModuleCode; a, b, c: BYTE);
  BEGIN
    ASSERT((a < 15) & (a # 13) & (b < 15) & (b # 13) & (c < 15) & (c # 13));
    IF (a = b) & (a < C3) & (c < C3) THEN Put1(co, MULT1 + c*C3 + a)
    ELSIF (a = c) & (a < C3) & (b < C3) THEN Put1(co, MULT1 + b*C3 + a)
    ELSE Put0(co, MULT2 + format3Reg4(a, b, c)) END
  END encMUL;
  
  PROCEDURE encUDIV*(VAR co: ModuleCode; a, b, c: BYTE);
  BEGIN
    ASSERT((a < 15) & (a # 13) & (b < 15) & (b # 13) & (c < 15) & (c # 13));
    Put0(co, UDIV + format3Reg4(a, b, c))
  END encUDIV;
  
  PROCEDURE encFPOpReg*(VAR co: ModuleCode; op, a, b, c: BYTE);
  BEGIN
    ASSERT((a < C5) & (b < C5) & (c < C5));
    (* VNEG (a := -c)
    *  VMOVSR (b := a)
    *  VMOVRS (a := b) *)
    Put0(co, op + a MOD C1*C22 + b DIV C1*C16 + a DIV C1*C12 + b MOD C1*C7 + c MOD C1*C5 + c DIV C1)
  END encFPOpReg;

  PROCEDURE encBackBranch*(VAR c: ModuleCode; cond: BYTE; L: LONGINT);
    VAR ofs: LONGINT;
  BEGIN ASSERT((cond < C4) & (cond # NV));
    ASSERT(~ODD(L-c.pc));
    ofs := (L - (c.pc + 4)) DIV C1; ASSERT(ofs < 0);
    IF (cond # AL) & (ofs > -C7) THEN (*T1*) Put1(c, BCT1 + cond*C8 + ofs MOD C8)
    ELSIF (cond = AL) & (ofs > -C10) THEN (*T2*) Put1(c, BT2 + ofs MOD C11)
    ELSIF (cond # AL) & (ofs > -C19) THEN (*T3*) 
      Put0(c, BCT3 + ofs DIV C19 MOD C1*C26 + cond*C22 + ofs DIV C11 MOD C6*C16 +
        ofs DIV C17 MOD C1*C13 + ofs DIV C18 MOD C1*C11 + ofs MOD C11)
    ELSIF ofs > -C23 THEN
      IF (cond # AL) THEN Put1(c, IT + cond*C4 + C3 (*IT cond*));  c.nbRmnITBlockInsts := 1
      END;
      Put0(c, BT4 + formatEvenImm25(ofs*C1))
    ELSE OM4S.Mark("branch too far")
    END
  END encBackBranch;
  
  PROCEDURE encBFC*(VAR c: ModuleCode; a, l, m: BYTE);
  BEGIN
    ASSERT((a < C4) & (l < C5) & (m >= l) & (m < C5));
    Put0(c, BFC + l DIV C2*C12 + a*C8 + l MOD C2*C6 + m)
  END encBFC;
  
  PROCEDURE encStaticAccess*(VAR c: ModuleCode; base, op, ope, a, b: BYTE; par: LONGINT);
  BEGIN
    ASSERT(base <= 0);
    ASSERT((a < C4) & (b < C4));
    IF base=0 THEN (*static variable in current module*)
      IF par >= C12 THEN OM4S.Mark("static var too far") END;
      Put0(c, op + a*C12 + b*C16 + par)
    ELSE
      ASSERT(ope < C4);
      ASSERT(par < C4);
      Put0(c, ope*C28 + a*C24 + b*C20 + par)
    END
  END encStaticAccess;
  
  PROCEDURE encStaticRealAccess*(VAR c: ModuleCode; base, op, ope, s, r: BYTE; par: LONGINT);
  BEGIN
    ASSERT(base <= 0);
    ASSERT((r < C4) & (s < C5));
    ASSERT(par >= 0);
    IF base=0 THEN (*static real variable in current module*)
      ASSERT(par MOD C2 = 0);
      IF par >= C10 THEN OM4S.Mark("static real var too far") END;
      Put0(c, op + 1*C23(*ADD*) + s MOD C1*C22 + r*C16 + s DIV C1*C12 + par DIV C2)
    ELSE
      ASSERT(ope < C4);
      ASSERT(par < C4);
      IF s >= C4 THEN OM4S.Mark("extern real var access not implemented for registers above 15") END;
      Put0(c, ope*C28 + s*C24 + r*C20 + par)
    END
  END encStaticRealAccess;

  PROCEDURE encMRS*(VAR c: ModuleCode; a, s: LONGINT);
  (*|1111/0011/1110/1111/1000/ Rd /  SY/Sm  |
    MRS<c> <Rd>,<spec_reg>*)
  BEGIN
    ASSERT(a < C4);
    ASSERT(s IN {0..9, 16..20});
    Put0(c, 0F3EF8000H + a*C8 + s)
  END encMRS;

  (*handling of forward reference, fixups of branch addresses and constant tables*)

  PROCEDURE negated*(cond: LONGINT): LONGINT;
  BEGIN
    IF ODD(cond) THEN DEC(cond) ELSE INC(cond) END;
    RETURN cond
  END negated;

(*  Format of forward jump (B):

    The bits encoding displacement are scattered in ARM thumb B and B<c> instructions.
    FJump and CFJump generate 32bit pseudo branch instructions with this format:
    11110ddddddddddddddddddddddddddd
    
    11110: branch signature
    d: link descriptor (27 bits)
*)

  PROCEDURE fix25*(VAR c: ModuleCode; at, with: LONGINT);
  (*The statement must be a wide jump with immediate offset (B.W <Label>).*)
  BEGIN
    ASSERT(c.code[at+1] DIV C3 = BRSIG); (*Check branch signature*)
    IF with >= C24 THEN OM4S.Mark("forward jump too far")
    ELSE modify(c, at, BT4 + formatEvenImm25(with)) END
  END fix25;

  PROCEDURE fix8*(VAR c: ModuleCode; at, with: LONGINT);
  (*The statement must be a narrow jump with immediate offset (B.N <Label>).*)
  BEGIN
    ASSERT(c.code[at+1] DIV C4*C4 = BCT1); (*Check op code*)
    ASSERT (~ODD(with)); with := with DIV C1;
    IF (with < -C7) OR (with >= C7) THEN OM4S.Mark("narrow jump too far");
    with := with MOD C8;
    ELSE INC(c.code[at], with) END
  END fix8;

  PROCEDURE FixOne*(VAR c: ModuleCode; at: LONGINT);
  BEGIN fix25(c, at, c.pc-at-4)
  END FixOne;

  PROCEDURE FixLink*(VAR c: ModuleCode; L: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    WHILE L # 0 DO L1 := load24(c, L); fix25(c, L, c.pc-L-4); L := L1 END
  END FixLink;

  PROCEDURE FixLinkWith*(VAR c: ModuleCode; L0, dst: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    WHILE L0 # 0 DO
      L1 := load24(c, L0) MOD C24;
      modify(c, L0, dst-L0-4); L0 := L1
    END
  END FixLinkWith;

  PROCEDURE merged*(VAR c: ModuleCode; L0, L1: LONGINT): LONGINT;
    VAR L2, L3: LONGINT;
  BEGIN 
    IF L0 # 0 THEN L3 := L0;
      REPEAT L2 := L3; ASSERT(c.code[L2] DIV C3 = BRSIG); (*Check branch signature*)
        L3 := load24(c, L2) UNTIL L3 = 0;
      modify(c, L2, L2 DIV C27 * C27 + L1); L1 := L0
    END ;
    RETURN L1
  END merged;

  PROCEDURE IfThen*(VAR c: ModuleCode; xyz: ARRAY OF CHAR; firstcond : BYTE);
    VAR suffix, mask: BYTE; i, res: LONGINT;
  BEGIN
    ASSERT((firstcond < C4) & (firstcond # NV));
    suffix := C3; mask := 0; res := IT + firstcond*C4; i := 0; 
    WHILE xyz[i] # 0X DO mask := mask*C1; suffix := suffix DIV C1; ASSERT(suffix # 0); 
      IF xyz[i] = "T" THEN INC(mask, firstcond MOD C1)
      ELSE ASSERT(xyz[i] = "E"); INC(mask, negated(firstcond) MOD C1)
      END;
      INC(i)
    END;
    INC(res, LSL(mask, 4-i) + suffix); Put1(c, res); c.nbRmnITBlockInsts := i+1
  END IfThen;
  
  PROCEDURE Init*(VAR c: ModuleCode);
  BEGIN
    c.pc := 0;  c.lastInstrSetFlags := FALSE; c.nbRmnITBlockInsts := 0
  END Init;

BEGIN
  imm3map[SUB] := 1E00H; imm8map[SUB] := 3800H; immthmap[SUB]  := 0F1B00000H; imm12map[SUB] := 0F2A00000H;
  reg3map[SUB] := 1A00H; reg4map[SUB] := 0H;    reg4shmap[SUB] := 0EBB00000H;
  
  imm3map[ADD] := 1C00H; imm8map[ADD] := 3000H; immthmap[ADD]  := 0F1100000H; imm12map[ADD] := 0F2000000H;
  reg3map[ADD] := 1800H; reg4map[ADD] := 4400H; reg4shmap[ADD] := 0EB100000H;
  
  imm3map[RSB] := 4240H; imm8map[RSB] := 0H;    immthmap[RSB]  := 0F1D00000H; imm12map[RSB] := 0H;
  reg3map[RSB] := 0H;    reg4map[RSB] := 0H;    reg4shmap[RSB] := 0EBD00000H;
  
  imm3map[EOR] := 0H;    imm8map[EOR] := 0H;    immthmap[EOR]  := 0F0900000H; imm12map[EOR] := 0H;
  reg3map[EOR] := 4040H; reg4map[EOR] := 0H;    reg4shmap[EOR] := 0EA900000H;
  
  imm3map[AND] := 0H;    imm8map[AND] := 0H;    immthmap[AND]  := 0F0100000H; imm12map[AND] := 0H;
  reg3map[AND] := 4000H; reg4map[AND] := 0H;    reg4shmap[AND] := 0EA100000H;
  
  imm3map[BIC] := 0H;    imm8map[BIC] := 0H;    immthmap[BIC]  := 0F0300000H; imm12map[BIC] := 0H;
  reg3map[BIC] := 4380H; reg4map[BIC] := 0H;    reg4shmap[BIC] := 0EA300000H;
  
  imm3map[ORR] := 0H;    imm8map[ORR] := 0H;    immthmap[ORR]  := 0F0500000H; imm12map[ORR] := 0H;
  reg3map[ORR] := 4300H; reg4map[ORR] := 0H;    reg4shmap[ORR] := 0EA500000H;
  
  imm3map[ADc] := 0H;    imm8map[ADc] := 0H;    immthmap[ADc]  := 0F1500000H; imm12map[ADc] := 0H;
  reg3map[ADc] := 4140H; reg4map[ADc] := 0H;    reg4shmap[ADc] := 0EB500000H;
  
  imm3map[SBc] := 0H;    imm8map[SBc] := 0H;    immthmap[SBc]  := 0F1700F00H; imm12map[SBc] := 0H;
  reg3map[SBc] := 4180H; reg4map[SBc] := 0H;    reg4shmap[SBc] := 0EB700000H;
  
  imm3map[TST] := 0H;    imm8map[TST] := 0H;    immthmap[TST]  := 0F0100F00H; imm12map[TST] := 0H;
  reg3map[TST] := 4200H; reg4map[TST] := 0H;    reg4shmap[TST] := 0EA100F00H;
  
  shimm5map[LSl] :=  0000H; shimm5wmap[LSl] := 0EA5F0000H; shreg3map[LSl] := 4080H; shreg4map[LSl] := 0FA10F000H;
  shimm5map[ASR] :=  1000H; shimm5wmap[ASR] := 0EA5F0020H; shreg3map[ASR] := 4100H; shreg4map[ASR] := 0FA50F000H;
  shimm5map[LSR] :=  0800H; shimm5wmap[LSR] := 0EA5F0010H; shreg3map[LSR] := 40C0H; shreg4map[LSR] := 0FA30F000H;
  shimm5map[ROR] := 0FFFFH; shimm5wmap[ROR] := 0EA5F0030H; shreg3map[ROR] := 41C0H; shreg4map[ROR] := 0FA70F000H;
END OM4A.