MODULE OM4A; (*C. Schoffit 10/11/2023 Instruction encoder for Cortex M4F processor*) 
  IMPORT OM4S;
  
  CONST
    (*Powers of two*)
    C31*=80000000H; C30*=40000000H; C28*=10000000H; C27*=8000000H; C26*=4000000H;
    C25*=2000000H; C24*=1000000H; C23*=800000H; C22*=400000H; 
    C21*=200000H; C20*=100000H; C19*=80000H; C18*=40000H; C17*=20000H;
    C16*=10000H; C15*= 8000H; C13*=2000H; C12*=1000H; C11*=800H; 
    C10*=400H; C9*=200H;C8*=100H; C7*=80H; C6*=40H; C5*=20H; 
    C4*=10H; C3*=8; C2*=4; C1*=2; C0*=1;
    
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
    CS* = 2; CC* = 3; VS* = 6; VC* = 7; HI* = 8;  LS* = 9;  AL* = 14; NV* = 15;

    IT*  = 0BF00H; (*If-Then base*)

    CoP*     = 0EC000000H; (*Coprocessor instruction*)

    BCT1*    = 0D000H;
    (*|1101 cond   imm8   |*)
    BT2*     = 0E000H;
    (*|1110 0   imm11     |*)
    BCT3*    = 0F0008000H;
    (*|1111/0Sco/nd i/mm6 /10J0/J   / imm/11  |
                             1  2             *)
    BT4*     = 0F0009000H;
    (*|11110S   imm10  10J1J   imm11   |
      |                  1 2           |
      B.W T4*)
    BL*      = 0F000D000H;
    (*|1111/0S  /im10/    /11J1/J   /im11/    |
                             1  2
      BL<c><q> <label>*)
    BLX*     = 4780H;
    (*|0100/0111/1 Rm/ 000|
      BLX<c> <Rm>*)
    BX*      = 4700H;
    (*|0100/0111/0 Rm/ 000|
      BX<c><q> <Rm>*)

    NOPT2 = 0F3AF8000H;
    (*1111/0011/1010/1111/1000/0000/0000/0000*)

    MOVIT1*  = 2000H;
    (*|0010/0 Rd/  im/m8  |
      MOVS <Rd>,#<imm8>*)
    MOVSIT2*  = 0F05F0000H;
    (*|1111/0i00/010S/1111/0im3/ Rd / imm/8   |
      MOV{S}<c>.W <Rd>,#<const>*)
    MOVIT3*  = 0F2400000H;
    (*|1111/0i10/0100/imm4/0im3/ Rd / imm/8   |
      MOVW<c> <Rd>,#<imm16>*)

    MVNS*     = 0F07F0000H;
    (*|1111/0i00/011S/1111/0im3/ Rd / imm/8   |
      MVN{S}<c> <Rd>,#<const>*)
      
    MOVT*    = 0F2C00000H;
    (*|1111/0i10/1100/imm4/0im3/ Rd / imm/8   |
      MOVT<c> <Rd>,#<imm16>*)

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
    (*|1110/1110/1D11/0000/ Vd /101s/01M0/ Vm |
      VMOV<c>.F32 <Sd>, <Sm>*)
    
    VLDRT2*  = 0ED100A00H;
    (*|1110 1101 UD01   Rn  Vd  1010   imm8   |
      VLDR<c> <Sd>, [<Rn>{, #+/-<imm>}]*)
    VSTRT2*  = 0ED000A00H;
    (*|1110 1101 UD00  Rn   Vd  1010   imm8   |
      VSTR<c> <Sd>, [<Rn>{, #+/-<imm>}]*)
    VPUSHT2* = 0ED2D0A00H;
    (*|1110/1101/0D10/1101/ Vd  /1010/  imm8  |
      VPUSH{<c>}{<q>}{.<size>} <list>*)
    VPOPT2*  = 0ECBD0A00H;
    (*|1110/1100/1D11/1101/ Vd  /1010/  imm8  |
      VPOP{<c>}{<q>}{.<size>} <list>*)
    
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
    VSQRT*   = 0EEB10AC0H;
    (*|1110/1110/1D11/0001/ Vd /101s/11M0/ Vm |
      VSQRT<c>.F32 <Sd>, <Sm>*)
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
    
    LDRIT4*  = 0F8500800H;
    (*|1111/1000/0101/ Rn / Rt /1PUW/ imm/8   |
      LDR<c> <Rt>,[<Rn>,#-<imm8>]
      LDR<c> <Rt>,[<Rn>],#+/-<imm8>
      LDR<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    LDRBIT3* = 0F8100800H;
    (*|1111 1000 0001  Rn   Rt  1PUW   imm8   |
      LDRB<c> <Rt>,[<Rn>,#-<imm8>]
      LDRB<c> <Rt>,[<Rn>],#+/-<imm8>
      LDRB<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    STRIT4*  = 0F8400800H;
    (*|1111/1000/0100/ Rn / Rt /1PUW/ imm/8   |
      STR<c> <Rt>,[<Rn>,#-<imm8>]
      STR<c> <Rt>,[<Rn>],#+/-<imm8>
      STR<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    STRBIT3* = 0F8000800H;
    (*|1111/1000/0000/ Rn / Rt /1PUW/ imm/8   |
      STRB<c> <Rt>,[<Rn>,#-<imm8>]
      STRB<c> <Rt>,[<Rn>],#+/-<imm8>
      STRB<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
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
    POPT3*  = 0F85D0B04H;
    (*|1111/1000/0101/1101/ Rt /1011/0000/0100|
      POP<c><q> <register>*)
    
    CMPIT1*  = 2800H;
    CMPIT2*  = 0F1B00F00H;
    CMNI*    = 0F1100F00H;
    (*|1111/0i01/0001/ Rn /0im3/1111/ imm/8   |
      CMN<c> <Rn>,#<const>*)
    CMPRT1*  = 4280H;
    CMPRT2*  = 4500H;

    SVC*     = 0DF00H;
    (*|1101/1111/ imm/8   |
      SVC<c> #<imm8>*)
    
    BFC*     = 0F36F0000H;
    (*|1111/0011/0110/1111/0im3/ Rd /im0 /msb |
      BFC<c> <Rd>,#<lsb>,#<width>*)
    
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
    
    DMB*   = 0F3BF8F5FH;
    (*|1111/0011/1011/1111/1000/1111/0101/opti|
      DMB<c><q> {<opt>}
      opti must be 1111*)

    DSB*   = 0F3BF8F4FH;
    (*|1111/0011/1011/1111/1000/1111/0100/opti|
      DSB<c> #<option>
      opti musb be 1111*)
      
    ISB*   = 0F3BF8F6FH;
    (*|1111/0011/1011/1111/1000/1111/0110/opti|
      ISB<c><q> {<opt>}
      opti musb be 1111*)

    RBIT* = 0FA90F0A0H;
    (*|1111/1010/1001/ Rm /1111/ Rd /1010/ Rm |
      RBIT <c><q> <Rd>, <Rm>
      Rm must be encoded twice*)
    BRSIG*   = 1EH; (*Pseudo branch op signature*)
    BRCSIG*  = 1FH; (*Pseudo conditional branch op signature*)

    
    (*Arithmetic and logical operations*)
    NBOPS = 11;
    SUB*=0; ADD*=1; RSB*=2; EOR*=3; AND*=4; BIC*=5; ORR*=6; ADc*=7; SBc*=8; TST*=9; ORN*=10;

    (*Shift operations*)
    LSl*=0; ASr*=1; LSr*=2; ROr*=3;
    
    (*Memory operations*)
    LDR*=0; LDRB*=1; STR*=2; STRB*=3;

  TYPE
    ModuleCode* = POINTER TO ModuleCodeDesc;
    
    ModuleCodeDesc* = RECORD
      pc*: LONGINT; (*program counter*)
      nbRmnITBlockInsts: LONGINT; (*Number of remaining instructions in current IT block*)
      lastInstrSetFlags*: BOOLEAN; (*TRUE if last instructions set flags*)
      code*: ARRAY maxCode OF BYTE;   (*Cortex M4 thumb uses 16bit half-words, but this size does not exists in Oberon 07*)
    END;

  VAR
    imm3map: ARRAY NBOPS OF LONGINT;
    imm8map: ARRAY NBOPS OF LONGINT;
    immthmap: ARRAY NBOPS OF LONGINT;
    imm12map: ARRAY NBOPS OF LONGINT;
    
    reg3map: ARRAY NBOPS OF LONGINT;
    reg3dnmap: ARRAY NBOPS OF LONGINT;
    reg4map: ARRAY NBOPS OF LONGINT;
    reg4shmap: ARRAY NBOPS OF LONGINT;
    
    opnotmap: ARRAY NBOPS OF LONGINT;
    opnegmap: ARRAY NBOPS OF LONGINT;

    shimm5map: ARRAY 4 OF LONGINT;
    shimm5wmap: ARRAY 4 OF LONGINT;

    shreg3map: ARRAY 4 OF LONGINT;
    shreg4map: ARRAY 4 OF LONGINT;

    memimm5map: ARRAY 4 OF LONGINT;
    memimm5shift: ARRAY 4 OF LONGINT;
    memimm8map: ARRAY 4 OF LONGINT;
    memPUWimm8map: ARRAY 4 OF LONGINT;
    memimm12map: ARRAY 4 OF LONGINT;

  PROCEDURE log2*(m: LONGINT; VAR e: LONGINT): LONGINT;
  BEGIN e := 0;
    WHILE ~ODD(m) DO m := m DIV 2; 
      IF (m < 0) THEN INC(m, C31) END;
      INC(e) END ;
    RETURN m
  END log2;
  
  (*instruction assemblers*)

  PROCEDURE modify*(VAR c: ModuleCode; at: LONGINT; with: LONGINT);
  BEGIN
    c.code[at+1] := with DIV C24 MOD C8;
    c.code[at]   := with DIV C16 MOD C8;
    c.code[at+3] := with DIV C8 MOD C8;
    c.code[at+2] := with MOD C8;
  END modify;

  PROCEDURE load22(VAR c: ModuleCode; at: LONGINT): LONGINT;
    VAR res: LONGINT;
  BEGIN
    res := (c.code[at] MOD C6*C8+c.code[at+3])*C8+c.code[at+2];
    RETURN res
  END load22;
  
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
    RETURN 0 + a DIV C3*C7 + b*C3 + a MOD C3
  END format2Reg4;
  
  PROCEDURE format3Reg4*(a, b, c: BYTE): LONGINT;
  BEGIN
    ASSERT ((a < C4) & (b < C4) & (c < C4));
    RETURN 0 + b*C16 + a*C8 + c
  END format3Reg4;
  
  PROCEDURE formatPUWImm8(p, u, w: BOOLEAN; imm8: LONGINT): LONGINT;
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
    a := a DIV C8 MOD C8;
    
    IF val DIV C8 = 0 THEN res := d; retv := TRUE
    ELSIF (a = 0) & (b = d) & (c = 0) THEN res := C12 + d; retv := TRUE
    ELSIF (a = c) & (b = 0) & (d = 0) THEN res := C13 + c; retv := TRUE
    ELSIF (a = b) & (a = c) & (a = d) THEN res := C12+ C13 + d; retv := TRUE
    ELSE a := 31; 
      WHILE (val DIV C8 # 1) & ~ODD(val) DO
        val := val DIV 2; IF val < 0 THEN INC(val, C31) END;
        DEC(a)
      END;
      IF (val DIV C8 = 1) & ~ODD(val) THEN retv := TRUE; 
        res := a DIV C4*C26 + a DIV C1 MOD C3*C12 + a MOD C1*C7 + val DIV C1 MOD C7
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
  VAR halfw, tmiCode: LONGINT;
  BEGIN
    ASSERT(reg < 16);
    IF (reg < 8) & (val >= 0) & (val < C8) THEN (*use encoding T1 if possible*)
      c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(c, MOVIT1 + reg*C8 + val)
    ELSIF formatThumbExpandImm(val, tmiCode) THEN (*else use encoding T2 if possible*)
      IF c.nbRmnITBlockInsts <= 1 THEN (*not in IT block or last in IT block*)
        Put0(c, MOVSIT2 + reg*C8 + tmiCode);
        c.lastInstrSetFlags := TRUE
      ELSE Put0(c, MOVSIT2-C0*C20 + reg*C8 + tmiCode) END  (*MOV instead of MOVS*)
    ELSIF formatThumbExpandImm(-(val+1), tmiCode) THEN (*else use MVNS if possible*)
      IF c.nbRmnITBlockInsts <= 1 THEN (*not in IT block or last in IT block*)
        Put0(c, MVNS + reg*C8 + tmiCode);
        c.lastInstrSetFlags := TRUE
      ELSE Put0(c, MVNS-C0*C20 + reg*C8 + tmiCode) END (*MVN instead of MVNS*)
    ELSE (*else one or two instructions are needed depending on the size of val,
           one for low half word and if necessary a second for high half word*)
      halfw := val MOD C16;
      IF (reg < 8) & (halfw < C8) THEN Put1(c, MOVIT1 + reg*C8 + halfw)
      ELSE Put0(c, MOVIT3 + formatImm16(reg, halfw)) END;
      halfw := val DIV C16 MOD C16;
      IF halfw # 0 THEN
        ASSERT(c.nbRmnITBlockInsts = 0);
        Put0(c, MOVT + formatImm16(reg, halfw))
      END
    END
  END encMOVImm32;

  PROCEDURE encMemImm8PUW*(VAR c: ModuleCode; op: LONGINT; a, b: BYTE; 
    p, u, w: BOOLEAN; imm: LONGINT);
  BEGIN
    ASSERT((imm >= 0) & (imm < C8));
    Put0(c, op + a*C12 + b*C16 + formatPUWImm8(p, u, w, imm))
  END encMemImm8PUW;
  
  PROCEDURE encDPImm32*(VAR c: ModuleCode; op, a, b, t: BYTE; imm: LONGINT);
    VAR tmiCode: LONGINT;
  BEGIN
    ASSERT (op < NBOPS);
    ASSERT ((a < C4) & (b < C4) & (t < C4));
    IF (imm >= 0) & (imm < C3) & (a < C3) & (b < C3) & (imm3map[op] # 0) THEN
      c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(c, imm3map[op] + imm*C6 + b*C3 + a)
    ELSIF (imm >= 0) & (imm < C8) & (a < C3) & (a = b) & (imm8map[op] # 0) THEN
      c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(c, imm8map[op] + a*C8 + imm)
    ELSIF formatThumbExpandImm(imm, tmiCode) THEN
      Put0(c, immthmap[op] + b*C16 + a*C8 + tmiCode);
      c.lastInstrSetFlags := ODD(reg4shmap[op] DIV C20)
    ELSIF (opnotmap[op] < NBOPS) & formatThumbExpandImm(-(imm+1), tmiCode) THEN
      Put0(c, immthmap[opnotmap[op]] + b*C16 + a*C8 + tmiCode);
      c.lastInstrSetFlags := ODD(immthmap[opnotmap[op]] DIV C20)
    ELSIF (opnegmap[op] < NBOPS) & formatThumbExpandImm(-imm, tmiCode) THEN
      Put0(c, immthmap[opnegmap[op]] + b*C16 + a*C8 + tmiCode);
      c.lastInstrSetFlags := ODD(immthmap[opnegmap[op]] DIV C20)
    ELSIF (imm >= 0) & (imm < C12)  & (imm12map[op] # 0) THEN
      Put0(c, imm12map[op] + imm DIV C11 MOD C1*C26 + b*C16 +
        imm DIV C8 MOD C3*C12 + a*C8 + imm MOD C8);
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
  
  PROCEDURE encMemImm32*(VAR c: ModuleCode; op, a, b, t: BYTE; imm: LONGINT);
    VAR imm1, imm2: LONGINT;
  BEGIN
    ASSERT(op <= STRB);
    ASSERT((a < C4) & (b < C4));
    IF (imm < 0) & (imm > -C8) THEN
      encMemImm8PUW(c, memPUWimm8map[op], a, b, TRUE(*Pre-indexed*), 
        FALSE(*subtract*), FALSE(*no write back*), -imm)
    ELSIF (imm < LSL(C5, memimm5shift[op])) & (imm = LSL(ASR(imm, memimm5shift[op]), memimm5shift[op]))
        & (a < C3) & (b < C3) THEN
      (*|0110/1 im/m5 R/n Rt| LDR<c> <Rt>, [<Rn>{,#<imm5>}] T1*)
      (*|0111/1 im/m5 R/n Rt| LDRB<c> <Rt>,[<Rn>{,#<imm5>}] T1*)
      (*|0110/0 im/m5 R/n Rt| STR<c> <Rt>, [<Rn>{,#<imm5>}] T1*)
      (*|0111/0 im/m5 R/n Rt| STRB<c> <Rt>,[<Rn>{,#<imm5>}] T1*)
      Put1(c, memimm5map[op] + ASR(imm, memimm5shift[op])*C6 + b*C3 + a)
    ELSIF (imm < C10) & (imm MOD C2 = 0) & (a < C3) & (b = 13) & (memimm8map[op] # 0) THEN
      (*|1001/1 Rt/  imm8  | LDR<c> <Rt>,[SP{,#<imm8>}] T2*)
      (*|1001/0 Rt/  imm8  | STR<c> <Rt>,[SP{,#<imm8>}] T2*)
      Put1(c, memimm8map[op] + a*C8 + imm DIV C2)
    ELSIF imm < C12 THEN
      (*|1111/1000/1101/ Rn / Rt /    /imm1/2   | LDR<c>.W <Rt>,[<Rn>{,#<imm12>}]  T3*)
      (*|1111/1000/1001/ Rn / Rt /    /imm1/2   | LDRB<c>.W <Rt>,[<Rn>{,#<imm12>}] T2*)
      (*|1111/1000/1100/ Rn / Rt /    /imm1/2   | STR<c>.W <Rt>,[<Rn>{,#<imm12>}]  T3*)
      (*|1111/1000/1000/ Rn / Rt /    /imm1/2   | STRB<c>.W <Rt>,[<Rn>{,#<imm12>}] T2*)
      Put0(c, memimm12map[op] + a*C12 + b*C16 + imm);
    ELSE (*imm = imm1+imm2 et 0 <= imm2 < C12*)
      imm2 := imm MOD C12; imm1 := imm DIV C12*C12;
      encDPImm32(c, ADD, t, b, t, imm1); encMemImm32(c, op, a, t, t, imm2)
    END;
  END encMemImm32;

  PROCEDURE encDPReg*(VAR co: ModuleCode; op, a, b, c: BYTE; shift: LONGINT);
  BEGIN
    ASSERT (op < NBOPS);
    ASSERT ((a < C4) & (b < C4) & (c < C4));
    IF (a < C3) & (b < C3) & (c < C3) & (shift = 0) & (reg3map[op] # 0) THEN
      co.lastInstrSetFlags := co.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(co, reg3map[op] + c*C6 + b*C3 + a)
    ELSIF (a < C3) & (b < C3) & (a = b) & (shift = 0) & (reg3dnmap[op] # 0) THEN
      co.lastInstrSetFlags := co.nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(co, reg3dnmap[op] + c*C3 + a)
    ELSIF (a = b) & (shift = 0) & (reg4map[op] # 0) THEN
      Put1(co, reg4map[op] + a DIV C3*C7 + c*C3 + a MOD C3)
    ELSE Put0(co, reg4shmap[op] + format3Reg4(a, b, c) + formatShiftImm5(shift));
      co.lastInstrSetFlags := ODD(reg4shmap[op] DIV C20);
    END
  END encDPReg;
  
  PROCEDURE encShiftImm5*(VAR c: ModuleCode; op, a, b: BYTE; shift: LONGINT);
  BEGIN
    ASSERT (op <= ROr);
    ASSERT ((a < 15) & (b < C4) & (shift < C5));
    IF (a < C3) & (b < C3) & (shimm5map[op] # 0FFFFH) THEN Put1(c, shimm5map[op] + shift*C6 + b*C3 + a);
      c.lastInstrSetFlags := c.nbRmnITBlockInsts = 0; (* not in IT block *)
    ELSE Put0(c, shimm5wmap[op] + a*C8 + b + formatShiftImm5(shift));
      c.lastInstrSetFlags := ODD(shimm5wmap[op] DIV C20)
    END
  END encShiftImm5;
  
  PROCEDURE encShiftReg*(VAR co: ModuleCode; op, a, b, c: BYTE);
  BEGIN
    ASSERT (op <= ROr);
    ASSERT((a < 15) & (a # 13) & (b < 15) & (b # 13) & (c < 15) & (c # 13));
    IF (a < C3) & (a = b) THEN Put1(co, shreg3map[op] + c*C3 + a);
      co.lastInstrSetFlags := co.nbRmnITBlockInsts = 0; (* not in IT block *)
    ELSE
      Put0(co, shreg4map[op] + format3Reg4(a, b, c));
      co.lastInstrSetFlags := ODD(shreg4map[op] DIV C20)
    END
  END encShiftReg;
  
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
  
  PROCEDURE encCMPImm*(VAR c: ModuleCode; a, t: BYTE; imm: LONGINT);
    VAR tmiCode: LONGINT;
  BEGIN
    ASSERT(a < 15);
    IF (a < 8) & (imm >= 0) & (imm < C8) THEN (*CMP (immediate) T1*) 
      Put1(c, CMPIT1 + a*C8 + imm)
    ELSIF formatThumbExpandImm(imm, tmiCode) THEN (*CMP (immediate) T2*) 
      Put0(c, CMPIT2 + a*C16 + tmiCode) 
    ELSIF formatThumbExpandImm(-imm, tmiCode) THEN (*CMN (immediate) T2*) 
      Put0(c, CMNI + a*C16 + tmiCode) 
    ELSE encMOVImm32(c, t, imm); encCMPReg(c, a, t)
    END;
    c.lastInstrSetFlags := TRUE
  END encCMPImm;
  
  PROCEDURE encMOVReg*(VAR c: ModuleCode; a, b: BYTE);
  BEGIN
    ASSERT((a # 15) OR (c.nbRmnITBlockInsts <= 1));
    Put1(c, MOVRT1 + a DIV C3*C7 + b*C3 + a MOD C3)
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
  
  PROCEDURE encFPMOVReg*(VAR co: ModuleCode; op: LONGINT; r, s: BYTE);
  BEGIN
    ASSERT((r < 13) & (s < C5));
    (*  VMOVSR (s := r)
    *  VMOVRS (r := s) *)
    Put0(co, op + s DIV C1*C16 + r*C12 + s MOD C1*C7)
  END encFPMOVReg;

  PROCEDURE encFPOpReg*(VAR co: ModuleCode; op: LONGINT; a, b, c: BYTE);
  BEGIN
    ASSERT((a < C5) & (b < C5) & (c < C5));
    (* VNEG (a := -c) *)
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
  
  PROCEDURE encMRS*(VAR c: ModuleCode; a, s: LONGINT);
  (*|1111/0011/1110/1111/1000/ Rd /  SY/Sm  |
    MRS<c> <Rd>,<spec_reg>*)
  BEGIN
    ASSERT(a < C4);
    ASSERT(s IN {0..9, 16..20});
    Put0(c, 0F3EF8000H + a*C8 + s)
  END encMRS;

  PROCEDURE encMSR*(VAR c: ModuleCode; a, s: LONGINT);
  (*|1111/0011/1000/ Rn /1000/Mq00/  SY/Sm  |
    MSR<c> <spec_reg>,<Rn>
    Mq is set as "10" to prevent unpredictable behaviour*)
  BEGIN
    ASSERT(a < C4);
    ASSERT(s IN {0..9, 16..20});
    Put0(c, 0F3808800H + a*C16 + s)
  END encMSR;

  (*handling of forward reference, fixups of branch addresses and constant tables*)

  PROCEDURE negated*(cond: LONGINT): LONGINT;
  BEGIN
    IF ODD(cond) THEN DEC(cond) ELSE INC(cond) END;
    RETURN cond
  END negated;

(*  Format of forward jump (B)

    The bits encoding displacement are scattered in ARM thumb B and B<c> instructions.
    FJump generate 32bit pseudo branch instructions with this format:
    11110xxxxxdddddddddddddddddddddd
    
    11110: branch signature
    xxxx : don't care
    dd22 : address of next forward branch to fix
*)

(*  Format of conditional forward jump (B<c>)

    The bits encoding displacement are scattered in ARM thumb B and B<c> instructions.
    CFJump generate 32bit pseudo branch instructions with this format:
    11111xccccdddddddddddddddddddddd
    
    11111: conditinal branch signature
    cccc:  condition
    dd22:  address of next forward branch to fix
*)

  PROCEDURE fix21(VAR c: ModuleCode; at, with: LONGINT);
  (*The statement must be a wide jump with immediate offset (B.W <Label>).*)
    VAR cond: BYTE;
  BEGIN
    cond := c.code[at+1] MOD C2*C2 + c.code[at] DIV C6;
    IF cond = NV THEN modify(c, at, NOPT2) (*branch never is equivalent to NOP*)
    ELSIF cond = AL THEN modify(c, at, BT4 + formatEvenImm25(with)) (*use unconditional branch*)
    ELSE
      ASSERT(cond < 14);
      ASSERT (~ODD(with)); with := with DIV C1;
      IF (with < -C19) OR (with >= C19) THEN OM4S.Mark("cond jump too far")
      ELSE with := with MOD C20;
        modify(c, at, BCT3 + with DIV C19 MOD C1*C26 + cond*C22 + with DIV C11 MOD C6*C16 +
        with DIV C17 MOD C1*C13 + with DIV C18 MOD C1*C11 + with MOD C11)
      END
    END
  END fix21;

  PROCEDURE fix(VAR c: ModuleCode; at, with: LONGINT);
    VAR sig: BYTE;
  BEGIN
    sig := c.code[at+1] DIV C3;
    IF sig = BRCSIG THEN fix21(c, at, with)
    ELSE ASSERT(sig = BRSIG); modify(c, at, BT4 + formatEvenImm25(with)) END
  END fix;
  
(*  Format of forward conditionaljump T1 :
    1101ccccxxxxxxxx
    
    1101: conditional branch signature
    cccc: condition
    xx8 : not used
 *)
 
  PROCEDURE fix8*(VAR c: ModuleCode; at, with: LONGINT);
  (*The statement must be a narrow conditional jump with immediate offset (B<C>.N <Label>).*)
  BEGIN
    ASSERT(c.code[at+1] DIV C4 = BCT1 DIV C12); (*Check op code*)
    ASSERT (~ODD(with)); with := with DIV C1;
    IF (with < -C7) OR (with >= C7) THEN OM4S.Mark("narrow cond jump too far")
    ELSE with := with MOD C8; c.code[at] := with END
  END fix8;

  PROCEDURE fix11*(VAR c: ModuleCode; at, with: LONGINT);
  (*The statement must be a narrow jump with immediate offset (B.N <Label>).*)
  BEGIN
    ASSERT(c.code[at+1] DIV C3 = BT2 DIV C11); (*Check op code*)
    ASSERT (~ODD(with)); with := with DIV C1;
    IF (with < -C10) OR (with >= C10) THEN OM4S.Mark("narrow jump too far")
    ELSE with := with MOD C11; c.code[at] := with MOD C8; INC(c.code[at+1], with DIV C8) END
  END fix11;

  PROCEDURE FixOne*(VAR c: ModuleCode; at: LONGINT);
  BEGIN fix(c, at, c.pc-at-4)
  END FixOne;

  PROCEDURE FixLink*(VAR c: ModuleCode; L: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    WHILE L # 0 DO L1 := load22(c, L); fix(c, L, c.pc-L-4); L := L1 END
  END FixLink;

  PROCEDURE FixLinkWith*(VAR c: ModuleCode; L0, dst: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    WHILE L0 # 0 DO
      L1 := load22(c, L0) MOD C24;
      fix(c, L0, dst-L0-4); L0 := L1
    END
  END FixLinkWith;

  PROCEDURE merged*(VAR c: ModuleCode; L0, L1: LONGINT): LONGINT;
    VAR L2, L3: LONGINT;
  BEGIN 
    IF L0 # 0 THEN L3 := L0;
      REPEAT L2 := L3;
        ASSERT(c.code[L2+1] DIV C3 = BRCSIG); (*Check conditional branch signature*)
        L3 := load22(c, L2) UNTIL L3 = 0;
      modify(c, L2, c.code[L2+1]*C24 + c.code[L2] DIV C6*C22 + L1); L1 := L0
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

  PROCEDURE PushRegs*(VAR c: ModuleCode; rl, rh: BYTE);
    VAR r0: LONGINT;
  BEGIN ASSERT((rl IN {0..7}) & (rh IN {0..12}) & (rl <= rh));
    r0 := ORD({rl..rh});
    IF r0 < C8 THEN (*PUSH T1*) Put1(c, PUSHT1 + r0)
    ELSE (*PUSH T2*) Put0(c, PUSHT2 + r0)
    END
  END PushRegs;

  PROCEDURE SaveRegs*(VAR c: ModuleCode; r: BYTE; VAR frame: LONGINT);  (* R[0 .. r-1]*)
  BEGIN (*r > 0*)
    PushRegs(c, 0, r-1);
    INC(frame, 4*r)
  END SaveRegs;

  PROCEDURE PopRegs*(VAR c: ModuleCode; rl, rh: BYTE);
    VAR r0: LONGINT;
  BEGIN ASSERT((rl IN {0..7}) & (rh IN {0..12}) & (rl <= rh));
    r0 := ORD({rl..rh});
    IF r0 < C8 THEN (*POP T1*) Put1(c, POPT1 + r0)
    ELSE (*POP T2*) Put0(c, POPT2 + r0)
    END
  END PopRegs;

  PROCEDURE RestoreRegs*(VAR c: ModuleCode; r: BYTE; VAR frame: LONGINT); (*R[0 .. r-1]*)
  BEGIN (*r > 0*)
    PopRegs(c, 0, r-1);
    DEC(frame, 4*r)
  END RestoreRegs;

  PROCEDURE SaveFPRegs*(VAR c: ModuleCode; s: BYTE; VAR frame: LONGINT); (*S[0 .. s-1]*)
  BEGIN
    ASSERT(s IN {1..16});
    (*VPUSH{<c>}{<q>}{.<size>} <list>*)
    Put0(c, VPUSHT2 + s);
    INC(frame, 4*s)
  END SaveFPRegs;
  
  PROCEDURE RestoreFPRegs*(VAR c: ModuleCode; s: BYTE; VAR frame: LONGINT); (*S[0 .. s-1]*)
  BEGIN
    ASSERT(s IN {1..16});
    (*VPOP{<c>}{<q>}{.<size>} <list>*)
    Put0(c, VPOPT2 + s);
    DEC(frame, 4*s)
  END RestoreFPRegs;
  
  PROCEDURE Init*(VAR c: ModuleCode);
  BEGIN
    c.pc := 0;  c.lastInstrSetFlags := FALSE; c.nbRmnITBlockInsts := 0
  END Init;

BEGIN
  imm3map[SUB] := 1E00H; imm8map[SUB] := 3800H; immthmap[SUB]  := 0F1B00000H; imm12map[SUB] := 0F2A00000H;
  reg3map[SUB] := 1A00H; reg3dnmap[SUB] := 0H;  reg4map[SUB]   := 0H;    reg4shmap[SUB]     := 0EBB00000H;
  opnotmap[SUB] := NBOPS;  opnegmap[SUB] := ADD;
  
  imm3map[ADD] := 1C00H; imm8map[ADD] := 3000H; immthmap[ADD]  := 0F1100000H; imm12map[ADD] := 0F2000000H;
  reg3map[ADD] := 1800H; reg3dnmap[ADD] := 0H;  reg4map[ADD]   := 4400H; reg4shmap[ADD]     := 0EB100000H;
  opnotmap[ADD] := NBOPS;  opnegmap[ADD] := SUB;
  
  imm3map[RSB] := 4240H; imm8map[RSB] := 0H;    immthmap[RSB]  := 0F1D00000H; imm12map[RSB] := 0H;
  reg3map[RSB] := 0H;    reg3dnmap[RSB] := 0H;  reg4map[RSB] := 0H;    reg4shmap[RSB] := 0EBD00000H;
  opnotmap[RSB] := NBOPS;  opnegmap[RSB] := NBOPS;
  
  imm3map[EOR] := 0H;    imm8map[EOR] := 0H;    immthmap[EOR]  := 0F0900000H; imm12map[EOR] := 0H;
  reg3map[EOR] := 0H;    reg3dnmap[EOR] := 4040H; reg4map[EOR] := 0H;        reg4shmap[EOR] := 0EA900000H;
  opnotmap[EOR] := NBOPS;  opnegmap[EOR] := NBOPS;
  
  imm3map[AND] := 0H;    imm8map[AND] := 0H;    immthmap[AND]  := 0F0100000H; imm12map[AND] := 0H;
  reg3map[AND] := 0H;    reg3dnmap[AND] := 4000H; reg4map[AND] := 0H;    reg4shmap[AND]     := 0EA100000H;
  opnotmap[AND] := BIC;  opnegmap[AND] := NBOPS;
  
  imm3map[BIC] := 0H;    imm8map[BIC] := 0H;    immthmap[BIC]  := 0F0300000H; imm12map[BIC] := 0H;
  reg3map[BIC] := 0H;    reg3dnmap[BIC] := 4380H; reg4map[BIC] := 0H;        reg4shmap[BIC] := 0EA300000H;
  opnotmap[BIC] := AND;  opnegmap[BIC] := NBOPS;
  
  imm3map[ORR] := 0H;    imm8map[ORR] := 0H;    immthmap[ORR]  := 0F0500000H; imm12map[ORR] := 0H;
  reg3map[ORR] := 0H;    reg3dnmap[ORR] := 4300H; reg4map[ORR] := 0H;        reg4shmap[ORR] := 0EA500000H;
  opnotmap[ORR] := ORN;  opnegmap[ORR] := NBOPS;
  
  imm3map[ADc] := 0H;    imm8map[ADc] := 0H;    immthmap[ADc]  := 0F1500000H; imm12map[ADc] := 0H;
  reg3map[ADc] := 0H;    reg3dnmap[ADc] := 4140H; reg4map[ADc] := 0H;        reg4shmap[ADc] := 0EB500000H;
  opnotmap[ADc] := NBOPS;  opnegmap[ADc] := NBOPS;
  
  imm3map[SBc] := 0H;    imm8map[SBc] := 0H;    immthmap[SBc]  := 0F1700F00H; imm12map[SBc] := 0H;
  reg3map[SBc] := 0H;    reg3dnmap[SBc] := 4180H; reg4map[SBc] := 0H;        reg4shmap[SBc] := 0EB700000H;
  opnotmap[SBc] := NBOPS;  opnegmap[SBc] := NBOPS;
  
  imm3map[TST] := 0H;    imm8map[TST] := 0H;    immthmap[TST]  := 0F0100F00H; imm12map[TST] := 0H;
  reg3map[TST] := 0H;    reg3dnmap[TST] := 4200H; reg4map[TST] := 0H;        reg4shmap[TST] := 0EA100F00H;
  opnotmap[TST] := NBOPS;  opnegmap[TST] := NBOPS;
  
  imm3map[ORN] := 0H;    imm8map[ORN] := 0H;    immthmap[ORN]  := 0F0700000H; imm12map[ORN] := 0H;
  reg3map[ORN] := 0H;    reg3dnmap[ORN] := 0H;    reg4map[ORN] := 0H;        reg4shmap[ORN] := 0EA700000H;
  opnotmap[ORN] := ORR;  opnegmap[ORN] := NBOPS;
  
  shimm5map[LSl] :=  0000H; shimm5wmap[LSl] := 0EA5F0000H; shreg3map[LSl] := 4080H; shreg4map[LSl] := 0FA10F000H;
  shimm5map[ASr] :=  1000H; shimm5wmap[ASr] := 0EA5F0020H; shreg3map[ASr] := 4100H; shreg4map[ASr] := 0FA50F000H;
  shimm5map[LSr] :=  0800H; shimm5wmap[LSr] := 0EA5F0010H; shreg3map[LSr] := 40C0H; shreg4map[LSr] := 0FA30F000H;
  shimm5map[ROr] := 0FFFFH; shimm5wmap[ROr] := 0EA5F0030H; shreg3map[ROr] := 41C0H; shreg4map[ROr] := 0FA70F000H;
  
  memimm5map[LDR]  := 6800H; memimm8map[LDR]  := 9800H;  memPUWimm8map[LDR] := LDRIT4;   memimm12map[LDR]  := 0F8D00000H;
  memimm5shift[LDR] := 2; (*offset = ZeroExtend(imm5:'00', 32);*)
  
  memimm5map[LDRB] := 7800H; memimm8map[LDRB] := 0H;     memPUWimm8map[LDRB] := LDRBIT3; memimm12map[LDRB] := 0F8900000H;
  memimm5shift[LDRB] := 0; (*offset = ZeroExtend(imm5, 32);*)
  
  memimm5map[STR]  := 6000H; memimm8map[STR]  := 9000H;  memPUWimm8map[STR] := STRIT4;   memimm12map[STR]  := 0F8C00000H;
  memimm5shift[STR] := 2; (*offset = ZeroExtend(imm5:'00', 32);*)
  
  memimm5map[STRB] := 7000H; memimm8map[STRB] := 0H;     memPUWimm8map[STRB] := STRBIT3; memimm12map[STRB] := 0F8800000H;
  memimm5shift[STRB] := 0; (*offset = ZeroExtend(imm5, 32);*)
END OM4A.
