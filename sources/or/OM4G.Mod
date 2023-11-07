MODULE OM4G; (* N.Wirth, 16.4.2016 / 4.4.2017 / 31.5.2019  Oberon compiler; 
  C. Schoffit 19/10/2023 code generator for Cortex M4 STM32I-DISCO*)
  IMPORT SYSTEM, Files, OM4S, OM4B;
  (*Code generator for Oberon compiler targetting Cortex M4F processor.
     Procedural interface to Parser OM4P; result in array "code".
     Procedure Close writes code-files*)

  CONST WordSize* = 4;
    MT = 12; SP = 13; LNK = 14; PC = 15; (*dedicated registers*)
    APSRnzcv = 15; (*APSR_nzcv is encoded as <Rt> = '1111'*)
    NBS = 32; (* Number of single float registers in the FPU bank *)
    VarORG0 = 0D0201000H;  (*for bare metal program only, 
    0D0200400H is the end address of VGA buffers*)
    maxCode = 16000*4; maxStrx = 2400; maxTD = 160;
    
    (*Powers of two*)
    C30=40000000H; C28=10000000H; C27=8000000H; C26=4000000H;
    C25=2000000H; C24=1000000H; C23=800000H; C22=400000H; 
    C21=200000H; C20=100000H; C19=80000H; C18=40000H; C17=20000H;
    C16=10000H; C13=2000H; C12=1000H; C11=800H; 
    C10=400H; C9=200H;C8=100H; C7=80H; C6=40H; C5=20H; 
    C4=10H; C3=8; C2=4; C1=2;
    
    Reg = 10; RegI = 11; Cond = 12;  (*internal item modes*)

    MI = 4; PL = 5; EQ = 0; NE = 1; LT = 11; GE = 10; LE = 13; GT = 12;
    CC = 3; AL = 14; NV=15;

    IT  = 0BF00H; (*If-Then base*)

    CoP     = 0ED000000H; (*Coprocessor instruction*)

    BL     = 0F000C000H;
    (*|11110S   imm10  11J1J   imm11   |
      |                  1 2           |
      BL<c> <label> *)

    (*B<c> <label>*)
    BCT1    = 0D000H;
    (*|1101 cond   imm8   |*)
    BT2     = 0E000H;
    (*|1110 0   imm11     |*)
    BCT3    = 0F0008000H;
    (*|1111/0Sco/nd i/mm6 /10J0/J   / imm/11  |
                             1  2             *)
    BT4    = 0F0009000H;
    (*|11110S   imm10  10J1J   imm11   |
      |                  1 2           |
      B.W T4*)
    BLX    = 4780H;
    (*|0100/0111/1 Rm/ 000|
      BLX<c> <Rm>*)

    MOVIT3    = 0F2400000H;
    (*|1111/0i10/0100/imm4/0im3/ Rd / imm/8   |
      MOVW<c> <Rd>,#<imm16>*)
    MOVIT1    = 2000H;
    (*|0010/0 Rd/  im/m8  |
      MOVS <Rd>,#<imm8>*)
    MOVT    = 0F2C00000H;

    VMOVSR  = 0EE000A10H;
    (*|1110 1110 000o  Vn   Rt  1010 N001 0000|
      VMOV (between Arm core register and single-precision register)
      VMOV{<c>}{<q>} <Sn>,<Rt> o=0*)
      
    VMOVSS  = 0EEB00A40H;
    (*|1110 1110 1D11 0000  Vd  101s 01M0  Vm |
      VMOV<c>.F32 <Sd>, <Sm>*)
      
    VLDR    = 0ED900A00H;
    (*|1110 1101 UD01   Rn  Vd  1010   imm8   |
      VLDR<c> <Sd>, [<Rn>{, #+/-<imm>}]*)
    VSTR    = 0ED800A00H;
    (*|1110 1101 UD00  Rn   Vd  1010   imm8   |
      VSTR<c> <Sd>, [<Rn>{, #+/-<imm>}]*)
    
    VNEG    = 0EEB10A40H;
    (*|1110 1110 1D11 0001  Vd  101s 01M0  Vm |
      VNEG<c>.F32 <Sd>, <Sm>*)
    VADD    = 0EE300A00H;
    (*|1110 1110 0D11  Vn   Vd  101s N0M0  Vm |
      VADD<c>.F32 <Sd>, <Sn>, <Sm>*)
    VSUB    = 0EE300A40H;
    (*|1110 1110 0D11  Vn   Vd  101s N1M0  Vm |
      VSUB<c>.F32 <Sd>, <Sn>, <Sm>*)
    VMUL    = 0EE200A00H;
    (*|1110 1110 0D10  Vn   Vd  101s N0M0  Vm |
      VMUL<c>.F32 <Sd>, <Sn>, <Sm>*)
    VDIV    = 0EE800A00H;
    (*|1110 1110 1D00  Vn   Vd  101s N0M0  Vm |
      VDIV<c>.F32 <Sd>, <Sn>, <Sm>*)
    VCMP0   = 0EEB50A40H;
    (*|1110 1110 1D11 0101  Vd  101s E100 0000|
      VCMP{E}<c>.F32 <Sd>, #0.0*)
    VCMP    = 0EEB40A40H;
    (*|1110 1110 1D11 0100  Vd  101s E1M0  Vm |
      VCMP{E}<c>.F32 <Sd>, <Sm>*)
    VMRS    = 0EEF10A10H;
    (*|1110 1110 1111 0001  Rt  1010 0001 0000|
      VMRS<c> <Rt>, FPSCR*)
    
    LDRIT3  = 0F8D00000H;
    (*|1111/1000/1101/ Rn / Rt /    /imm1/2   |
      LDR<c>.W <Rt>,[<Rn>{,#<imm12>}]*)
    LDRIT4  = 0F8500800H;
    (*|1111/1000/0101/ Rn / Rt /1PUW/ imm/8   |
      LDR<c> <Rt>,[<Rn>,#-<imm8>]
      LDR<c> <Rt>,[<Rn>],#+/-<imm8>
      LDR<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    LDRBIT2 = 0F8900000H;
    (*|1111 1000 1001  Rn   Rt      imm12     |
      LDRB<c>.W <Rt>,[<Rn>{,#<imm12>}]*)
    LDRBIT3 = 0F8100800H;
    (*|1111 1000 0001  Rn   Rt  1PUW   imm8   |
      LDRB<c> <Rt>,[<Rn>,#-<imm8>]
      LDRB<c> <Rt>,[<Rn>],#+/-<imm8>
      LDRB<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    STRIT3 = 0F8C00000H;
    (*|1111/1000/1100/ Rn / Rt /    /imm1/2   |
      STR<c>.W <Rt>,[<Rn>,#<imm12>]*)
    STRIT4 = 0F8400800H;
    (*|1111/1000/0100/ Rn / Rt /1PUW/ imm/8   |
      STR<c> <Rt>,[<Rn>,#-<imm8>]
      STR<c> <Rt>,[<Rn>],#+/-<imm8>
      STR<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
    
    STRBIT2 = 0F8800000H;
    (*|1111 1000 1000  Rn   Rt      imm12     |
      STRB<c>.W <Rt>,[<Rn>,#<imm12>]*)

    PUSHT1 = 0B400H;
    (*|1011/010M/reg_/list|
      PUSH<c> <registers>*)
    PUSHT2 = 0E92D0000H;
    (*|1110/1001/0010/1101/0M0 /reg_/list/    |
      PUSH<c>.W <registers>*)
    POPT1  = 0BC00H;
    (*|1011/110P/reg_/list|
      POP<c> <registers>*)
    POPT2  = 0E8BD0000H;
    (*|1110/1000/1011/1101/PM0 /reg_/list/    |
      POP<c>.W <registers>*)
    
    CMPIT1  = 2800H;
    CMPIT2  = 0F1B00F00H;
    CMPRT1  = 4280H;
    CMPRT2  = 4500H;
    
    BRSIG   = 1EH;

    
    (* Arithmetic and logical operations *)
    SUB=0; ADD=1; RSB=2; EOR=3; AND=4; BIC=5; ORR=6;

    (* Shift operations *)
    LSl=0; ASR=1; LSR=2; ROR=3;

    MULT1  = 4340H;
    (*|0100/0011/01Rn/ Rdm|
      MULS <Rdm>,<Rn>,<Rdm>   Outside IT block.
      MUL<c> <Rdm>,<Rn>,<Rdm> Inside IT block.*)
    MULT2  = 0FB00F000H;
    (*|1111/1011/0000/ Rn /1111/ Rd /0000/ Rm |
      MUL<c> <Rd>,<Rn>,<Rm>*)
    UDIV  = 0FBB0F0F0H;
    
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
    RegI    regno  off     -
    Cond    cond   Fchain  Tchain  *)

  VAR pc*, varsize: LONGINT;   (*program counter, data index*)
    tdx, strx: LONGINT;
    entry: LONGINT;   (*main entry point*)
    RH: LONGINT;      (*in use registers R[0] ... R[H-1]*)
    SH: LONGINT;      (*in use floating point registers S[0] ... S[H-1]*)
    frame: LONGINT;   (*frame offset changed in SaveRegs and RestoreRegs*)
    fixORGP, fixORGD, fixORGT: LONGINT;   (*origins of lists of locations to be fixed up by loader*)
    check: BOOLEAN;   (*emit run-time checks*)
    version: INTEGER; (*0 = bare metal program, 1 = oberon system module*)
    
    relmap: ARRAY 6 OF INTEGER;    (*condition codes for relations*)
    code: ARRAY maxCode OF BYTE;   (*Cortex M4 thumb uses 16bit half-words, but this size does not exists in Oberon 07*)
    data: ARRAY maxTD OF LONGINT;  (*type descriptors*)
    str: ARRAY maxStrx OF CHAR;
    
    imm3map: ARRAY 10 OF LONGINT;
    imm8map: ARRAY 10 OF LONGINT;
    imm12map: ARRAY 10 OF LONGINT;
    
    reg3map: ARRAY 10 OF LONGINT;
    reg4map: ARRAY 10 OF LONGINT;
    reg4shmap: ARRAY 10 OF LONGINT;

    shimm5map: ARRAY 5 OF LONGINT;
    shimm5wmap: ARRAY 5 OF LONGINT;

    shreg3map: ARRAY 5 OF LONGINT;
    shreg4map: ARRAY 5 OF LONGINT;

    lastInstrSetFlags: BOOLEAN; (*TRUE if last instructions set flags according to RH*)
    nbRmnITBlockInsts: LONGINT; (*Number of remaining instructions in current IT block*)
    
  (*instruction assemblers according to formats*)

  PROCEDURE modify(at: LONGINT; with: LONGINT);
  BEGIN
    code[at+1] := with DIV C24;
    code[at]   := with DIV C16 MOD C8;
    code[at+3] := with DIV C8 MOD C8;
    code[at+2] := with MOD C8;
  END modify;

  PROCEDURE load24(at: LONGINT): LONGINT;
    VAR res: LONGINT;
  BEGIN
    res := (code[at+3]*C8+code[at+2])*C8+code[at+1];
    RETURN res
  END load24;
  
  PROCEDURE Put0(op: LONGINT);
  BEGIN (*emit format-0 instruction (32bit)
         format: op8:p24 *)
    lastInstrSetFlags := FALSE;
    IF nbRmnITBlockInsts > 0 THEN DEC(nbRmnITBlockInsts) END;
    modify(pc, op);
    INC(pc, 4)
  END Put0;

  PROCEDURE Put1(op: LONGINT);
  BEGIN (*emit format-1 instruction (16bit)*)
    lastInstrSetFlags := FALSE;
    IF nbRmnITBlockInsts > 0 THEN DEC(nbRmnITBlockInsts) END;
    code[pc+1] := op DIV C8 MOD C8;
    code[pc]   := op MOD C8;
    INC(pc, 2)
  END Put1;

  PROCEDURE formatEvenImm25(disp: LONGINT): LONGINT;
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
  
  PROCEDURE formatShiftImm5(shift: LONGINT): LONGINT;
  BEGIN
    ASSERT(shift < C5);
    RETURN shift DIV C2*C12 + shift MOD C2*C6
  END formatShiftImm5;

  PROCEDURE format3Reg4(a, b, c: BYTE): LONGINT;
  BEGIN
    ASSERT ((a < C4) & (b < C4) & (c < C4));
    RETURN 0 + b*C16 + a*C8 + c
  END format3Reg4;
  
  PROCEDURE formatPUWImm8(p, u, w: BOOLEAN; imm8: LONGINT): LONGINT;
  BEGIN
    ASSERT((imm8 >= 0) & (imm8 < C8));
    RETURN ORD(p)*C10 + ORD(u)*C9 + ORD(w)*C8 + imm8
  END formatPUWImm8;
  
  PROCEDURE encMovImm32(reg: BYTE; val: LONGINT);
  VAR hw: LONGINT;
  
    PROCEDURE formatImm16(reg: BYTE; val: LONGINT): LONGINT;
    (*|xxxxxixxxxxximm4ximm reg  imm8  |
      |                   3            |
      val = imm4:i:imm3:imm8*)
    BEGIN
      RETURN val DIV C12 MOD C4*C16 + val DIV C11 MOD C1*C26 + 
             val DIV C8 MOD C3*C12 + reg*C8 + val MOD C8
    END formatImm16;

  BEGIN
    ASSERT(reg < 16);
    hw := val MOD C16;
    IF (reg < 8) & (hw < C8) THEN 
      lastInstrSetFlags := nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(MOVIT1 + reg*C8 + hw);
    ELSE Put0(MOVIT3 + formatImm16(reg, val)) END;
    hw := val DIV C16 MOD C16;
    IF hw # 0 THEN
      ASSERT(nbRmnITBlockInsts = 0);
      Put0(MOVT + formatImm16(reg, val))
    END
  END encMovImm32;

  PROCEDURE encMemImm12(op, a, b: BYTE; imm: LONGINT; msg: ARRAY OF CHAR);
  BEGIN
  (*|111110001101 Rn  Rt   imm12     |
     F   8   D LDR (immediate) T3
    
    |111110001001 Rn  Rt   imm12     |
     F   8   9 LDRB (immediate) T2*)
    IF imm >= C12 THEN OM4S.Mark(msg) END;
    Put0(op + a*C12 + b*C16 + imm);
  END encMemImm12;
  
  PROCEDURE encDPImm32(op, a, b: BYTE; imm: LONGINT);
  BEGIN
    ASSERT (op <= ORR);
    ASSERT ((a < C4) & (b < C4));
    IF (imm >= 0) & (imm < C3) & (a < C3) & (b < C3) & (imm3map[op] # 0) THEN
      (*|   op  immbbbaaa|
        RSB (immediate) T1*)
      lastInstrSetFlags := nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(imm3map[op] + imm*C6 + b*C3 + a)
    ELSIF (imm >= 0) & (imm < C8) & (a < C3) & (a = b) & (imm8map[op] # 0) THEN
      lastInstrSetFlags := nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(imm8map[op] + a*C8 + imm)
      (*TODO: ajouter la forme ThumbExpandImm*)
    ELSIF (imm >= 0) & (imm < C12)  & (imm12map[op] # 0) THEN
      (*|  o1 i  o2 sbbbboim3aaaa  imm8  |
        RSB (immediate) T2*) 
      Put0(imm12map[op] + imm DIV C11 MOD C1*C20 + b*C16 +
        imm DIV C8 MOD C3*C12 + a*C8 + imm MOD C8);
      lastInstrSetFlags := ODD(imm12map[op] DIV C20);
    ELSE
      ASSERT(nbRmnITBlockInsts = 0);
      encMovImm32(RH, imm);
      IF (a < C3) & (b < C3) & (RH < C3) & (reg3map[op] # 0) THEN
        lastInstrSetFlags := nbRmnITBlockInsts = 0; (* not in IT block *)
        Put1(reg3map[op] + RH*C6 + b*C3 + a)
      ELSE Put0(reg4shmap[op] + format3Reg4(a, b, 0) + RH);
        lastInstrSetFlags := ODD(reg4shmap[op] DIV C20);
      END
    END
  END encDPImm32;
  
  PROCEDURE encDPReg(op, a, b, c: BYTE; shift: LONGINT);
  BEGIN
    ASSERT (op <= ORR);
    ASSERT ((a < C4) & (b < C4) & (c < C4));
    IF (a < C3) & (b < C3) & (c < C3) & (shift = 0) & (reg3map[op] # 0) THEN
      (*ADD/SUB (Register) T1*)
      lastInstrSetFlags := nbRmnITBlockInsts = 0; (* not in IT block *)
      Put1(reg3map[op] + c*C6 + b*C3 + a)
    ELSIF (a = b) & (shift = 0) & (reg4map[op] # 0) THEN
      (*ADD (Register) T2*)
      Put1(reg4map[op] + a DIV C3*C7 + c*C3 + a MOD C3)
    ELSE (*ADD (Register) T3, SUB (Register) T2 *)
      Put0(reg4shmap[op] + format3Reg4(a, b, c) + formatShiftImm5(shift));
      lastInstrSetFlags := ODD(reg4shmap[op] DIV C20);
    END
  END encDPReg;
  
  PROCEDURE encShiftImm5(op, a, b: BYTE; shift: LONGINT);
  BEGIN
    ASSERT (op <= ROR);
    ASSERT ((a < 15) & (b < C4) & (shift < C5));
    IF (a < C3) & (b < C3) & (shimm5map[op] # 0FFFFH) THEN Put1(shimm5map[op] + shift*C6 + b*C3 + a);
      lastInstrSetFlags := nbRmnITBlockInsts = 0; (* not in IT block *)
    ELSE Put0(shimm5wmap[op] + a*C8 + b + formatShiftImm5(shift));
      lastInstrSetFlags := ODD(shimm5wmap[op] DIV C20)
    END
  END encShiftImm5;
  
  PROCEDURE encShiftReg(op, a, b, c: BYTE);
  BEGIN
    ASSERT (op <= ROR);
    ASSERT((a < 15) & (a # 13) & (b < 15) & (b # 13) & (c < 15) & (c # 13));
    IF (a < C3) & (a = b) THEN Put1(shreg3map[op] + c*C3 + a);
      lastInstrSetFlags := nbRmnITBlockInsts = 0; (* not in IT block *)
    ELSE
      Put0(shreg4map[op] + format3Reg4(a, b, c));
      lastInstrSetFlags := ODD(shreg4map[op] DIV C20)
    END
  END encShiftReg;
  
  PROCEDURE encCMPImm8(a, imm: LONGINT);
  BEGIN
    ASSERT(a < 15);
    ASSERT((imm >= 0) & (imm < C8));
    IF a < 8 THEN Put1(CMPIT1 + a*C3 + imm)
    ELSE Put0(CMPIT2 + a*C16 + imm) END;
    lastInstrSetFlags := TRUE
  END encCMPImm8;
  
  PROCEDURE encCMPReg(a, b: BYTE);
  BEGIN
    ASSERT ((a < 15) & (b < 15));
    IF (a < 8) & (b < 8) THEN
      (*CMP (register) T1*)
      Put1(CMPRT1 + b*C3 + a)
    ELSE (*CMP (register) T2*)
      Put1(CMPRT2 + a DIV 3*C7 + b*C3 + a MOD 3)
    END;
    lastInstrSetFlags := TRUE
  END encCMPReg;
  
  PROCEDURE encMUL(a, b, c: BYTE);
  BEGIN
    ASSERT((a < 15) & (a # 13) & (b < 15) & (b # 13) & (c < 15) & (c # 13));
    IF (a = b) & (a < C3) & (c < C3) THEN Put1(MULT1 + c*C3 + a)
    ELSIF (a = c) & (a < C3) & (b < C3) THEN Put1(MULT1 + b*C3 + a)
    ELSE Put0(MULT2 + format3Reg4(a, b, c)) END
  END encMUL;
  
  PROCEDURE encUDIV(a, b, c: BYTE);
  BEGIN
    ASSERT((a < 15) & (a # 13) & (b < 15) & (b # 13) & (c < 15) & (c # 13));
    Put0(UDIV + format3Reg4(a, b, c))
  END encUDIV;
  
  PROCEDURE encFPOpReg(op, a, b, c: BYTE);
  BEGIN
    ASSERT((a < C5) & (b < C5) & (c < C5));
    (* VNEG (a := -c)
    *  VMOVSR (b := a) *)
    Put0(op + a MOD C1*C22 + b DIV C1*C16 + a DIV C1*C12 + b MOD C1*C7 + c MOD C1*C5 + c DIV C1)
  END encFPOpReg;

  PROCEDURE encBackBranch(cond: BYTE; L: LONGINT);
    VAR ofs: LONGINT;
  BEGIN ASSERT((cond < C4) & (cond # NV));
    ASSERT(~ODD(L-pc));
    ofs := (L - (pc + 4)) DIV C1; ASSERT(ofs < 0);
    IF (cond # AL) & (ofs > -C7) THEN (*T1*) Put1(BCT1 + cond*C8 + ofs MOD C8)
    ELSIF (cond = AL) & (ofs > -C10) THEN (*T2*) Put1(BT2 + ofs MOD C11)
    ELSIF (cond # AL) & (ofs > -C19) THEN (*T3*) 
      Put0(BCT3 + ofs DIV C19 MOD C1*C26 + cond*C22 + ofs DIV C11 MOD C6*C16 +
        ofs DIV C17 MOD C1*C13 + ofs DIV C18 MOD C1*C11 + ofs MOD C11)
    ELSIF ofs > -C23 THEN
      IF (cond # AL) THEN Put1(IT + cond*C4 + 8H (*IT cond*));  nbRmnITBlockInsts := 1
      END;
      Put0(BT4 + formatEvenImm25(ofs*C1))
    ELSE OM4S.Mark("branch too far")
    END
  END encBackBranch;
  
  PROCEDURE incR;
  BEGIN
    IF RH < MT-1 THEN INC(RH) ELSE OM4S.Mark("register stack overflow") END
  END incR;

  PROCEDURE incS;
  BEGIN
    IF SH < NBS-1 THEN INC(SH) ELSE OM4S.Mark("FP register stack overflow") END
  END incS;

  PROCEDURE CheckRegs*;
  BEGIN
    IF RH # 0 THEN OM4S.Mark("Reg Stack"); RH := 0 END ;
    IF SH # 0 THEN OM4S.Mark("FP Reg Stack"); SH := 0 END ;
    IF pc >= maxCode - 40 THEN OM4S.Mark("program too long") END ;
    IF frame # 0 THEN OM4S.Mark("frame error"); frame := 0 END
  END CheckRegs;

  PROCEDURE SetCC(VAR x: Item; n: LONGINT);
  BEGIN x.mode := Cond; x.a := 0; x.b := 0; x.r := n
  END SetCC;

  (* Cond definition 
    0000 MI negative (minus)    N       1000 PL positive (plus)     ~N
    0001 EQ equal (zero)        Z       1001 NE not equal (#zero)   ~Z
    0010 CS carry set           C       1010 CC carry clear         ~C
    0011 VS overflow set        V       1011 VC overflow clear      ~V
    0100 LS less or same      ~C|Z      1100 HI high             ~(~C|Z)
    0101 LT less than          N#V      1101 GE greater or equal  ~(N#V)
    0110 LE less or equal    (N#V)|Z    1110 GT greater than  ~((N#V)|Z)
    0111 true                   T       1111 false                   F
 *)
 
  PROCEDURE Trap(cond, num: LONGINT);
  (*
    Trap is implemented as a coprocessor instruction targeting a
    non existing coprocessor, i.e. not CP10 or CP11 assocatied to FPU.
    The encoding is 111x11xxxxxxxxxxxxxx0xxxxxxxxxxx, that leaves 26 bits
    for describing the trap number and file position.
    
    In this implementation, 24 bits will be used, like in RISC-5 code
    1110110ppppppppppppp0pppppppnnnn
    This will generate an exception trapped by the usage fault handler 
    implemented as the trap procedure of the System module.
  *)
  VAR pos: LONGINT;
  BEGIN 
    ASSERT(cond # NV);
    (*IT<cond> encoding if needed*)
    IF cond # AL THEN Put1(IT + cond*C4 + 8H (*IT cond*));  nbRmnITBlockInsts := 1 END;
    pos := OM4S.Pos();
    ASSERT(pos < C20);
    ASSERT(num < C4);
    Put0(CoP + pos DIV C7*C12 + pos MOD C7*C4 + num)
  END Trap;

  (*handling of forward reference, fixups of branch addresses and constant tables*)

  PROCEDURE negated(cond: LONGINT): LONGINT;
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

  PROCEDURE fix25(at, with: LONGINT);
  (*The statement must be a wide jump with immediate offset (B.W <Label>).*)
  BEGIN
    ASSERT(code[at+1] DIV C3 = BRSIG); (*Check branch signature*)
    IF with >= C24 THEN OM4S.Mark("forward jump too far")
    ELSE modify(at, BT4 + formatEvenImm25(with)) END
  END fix25;

  PROCEDURE fix8(at, with: LONGINT);
  (*The statement must be a narrow jump with immediate offset (B.N <Label>).*)
  BEGIN
    ASSERT(code[at+1] DIV C4*C4 = BCT1); (*Check op code*)
    ASSERT (~ODD(with)); with := with DIV C1;
    IF (with < -C7) OR (with >= C7) THEN OM4S.Mark("narrow jump too far");
    with := with MOD C8;
    ELSE INC(code[at], with) END
  END fix8;

  PROCEDURE FixOne*(at: LONGINT);
  BEGIN fix25(at, pc-at-4)
  END FixOne;

  PROCEDURE FixLink*(L: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    WHILE L # 0 DO L1 := load24(L); fix25(L, pc-L-4); L := L1 END
  END FixLink;

  PROCEDURE FixLinkWith(L0, dst: LONGINT);
    VAR L1: LONGINT;
  BEGIN
    WHILE L0 # 0 DO
      L1 := load24(L0) MOD C24;
      modify(L0, dst-L0-4); L0 := L1
    END
  END FixLinkWith;

  PROCEDURE merged(L0, L1: LONGINT): LONGINT;
    VAR L2, L3: LONGINT;
  BEGIN 
    IF L0 # 0 THEN L3 := L0;
      REPEAT L2 := L3; ASSERT(code[L2] DIV C3 = BRSIG); (*Check branch signature*)
        L3 := load24(L2) UNTIL L3 = 0;
      modify(L2, L2 DIV C27 * C27 + L1); L1 := L0
    END ;
    RETURN L1
  END merged;

  (* loading of operands and addresses into registers *)

  PROCEDURE GetSB(base: LONGINT);
  BEGIN
    IF version = 0 THEN encMovImm32(RH, VarORG0)
    ELSE
      IF pc-fixORGD > C25 THEN OM4S.Mark("too many instruction between static access") END;
      Put0(RH*C28 + (-base)*C24 + (pc-fixORGD) DIV C1);
      fixORGD := pc-4
    END
  END GetSB;

  PROCEDURE encStaticAccess(base, op, ope, a, b: BYTE; par: LONGINT);
  BEGIN
    ASSERT(base <= 0);
    ASSERT((a < C4) & (b < C4));
    IF base=0 THEN (*static variable in current module*)
      IF par >= C12 THEN OM4S.Mark("static var too far") END;
      Put0(op + a*C12 + b*C16 + par)
    ELSE
      ASSERT(ope < C4);
      ASSERT(par < C4);
      Put0(ope*C28 + a*C24 + b*C20 + par)
    END
  END encStaticAccess;
  
  PROCEDURE encStaticRealAccess(base, op, ope, s, r: BYTE; par: LONGINT);
  BEGIN
    ASSERT(base <= 0);
    ASSERT((r < C4) & (s < C5));
    IF base=0 THEN (*static real variable in current module*)
      ASSERT(par MOD C2 = 0);
      IF par >= C10 THEN OM4S.Mark("static real var too far") END;
      Put0(op + 1*C23 + s MOD C1*C22 + r*C16 + s DIV C1*C12 + par DIV C2)
    ELSE
      ASSERT(ope < C4);
      ASSERT(par < C4);
      IF s >= C4 THEN OM4S.Mark("extern real var access not implemented for registers above 15") END;
      Put0(ope*C28 + s*C24 + r*C20 + par)
    END
  END encStaticRealAccess;
  
  PROCEDURE NilCheck;
  BEGIN IF check THEN Trap(EQ, 4) END
  END NilCheck;

  PROCEDURE load(VAR x: Item);
    VAR op, opext: LONGINT;
  BEGIN
    IF x.type.size = 1 THEN op := LDRBIT2; opext := EXTLDRB
    ELSE op := LDRIT3; opext := EXTLDR END ;
    IF x.mode # Reg THEN
      IF x.mode = OM4B.Const THEN
        IF x.type.form = OM4B.Proc THEN
          IF x.r > 0 THEN OM4S.Mark("not allowed")
          ELSIF x.r = 0 THEN
            Put0(BL + formatEvenImm25(0));  (* Put address of next statement in LR *)
            encDPImm32(SUB, RH, LNK, pc - x.a + 1 (*For Thumb state*) )
          ELSE GetSB(x.r); Put0(EXTADD*C28 + RH*C24 + RH*C20 + C8 (*mark as progbase-relative*) + x.a)
          END;
          x.r := RH; incR
        ELSE encMovImm32(RH, x.a);
          IF x.type.form = OM4B.Real THEN
            encFPOpReg(VMOVSR, RH, SH, 0);
            x.r := SH; incS
          ELSE x.r := RH; incR
          END
        END;
      ELSIF x.mode = OM4B.Var THEN
        IF x.r > 0 THEN (*local*) 
          IF x.type.form = OM4B.Real THEN ASSERT((x.a + frame) MOD C2 = 0);
            IF x.a + frame >= C10 THEN OM4S.Mark("local real var too far") 
            END;
            Put0(VLDR + 1*C23 + SH MOD C1*C22 + SP*C16 + SH DIV C1*C12 + (x.a + frame) DIV C2);
            x.r := SH; incS
          ELSE encMemImm12(op, RH, SP, x.a + frame, "local var too far");
            x.r := RH; incR
          END
        ELSE GetSB(x.r);
          IF x.type.form = OM4B.Real THEN encStaticRealAccess(x.r, VLDR, EXTVLDR, SH, RH, x.a);
            x.r := SH; incS
          ELSE encStaticAccess(x.r, op, opext, RH, RH, x.a);
            x.r := RH; incR
          END
        END
      ELSIF x.mode = OM4B.Par THEN
        encMemImm12(LDRIT3, RH, SP, x.a + frame, "param offset 0 too far");
        IF x.type.form = OM4B.Real THEN ASSERT((x.b + frame) MOD C2 = 0);
          IF x.b + frame >= C10 THEN OM4S.Mark("real param offset 1 too far") 
          END;
          Put0(VLDR + 1*C23 + SH MOD C1*C22 + RH*C16 + SH DIV C1*C12 + (x.b + frame) DIV C2);
          x.r := SH; incS
        ELSE  encMemImm12(op, RH, RH, x.b, "param offset 1 too far");
          x.r := RH; incR
        END
      ELSIF x.mode = RegI THEN 
        IF x.type.form = OM4B.Real THEN ASSERT((x.a + frame) MOD C2 = 0);
          IF x.a + frame >= C10 THEN OM4S.Mark("real RegI too far") 
          END;
          Put0(VLDR + 1*C23 + SH MOD C1*C22 + x.r*C16 + SH DIV C1*C12 + (x.a + frame) DIV C2);
          x.r := SH; incS; DEC(RH)
        ELSE  encMemImm12(op, x.r, x.r, x.a, "RegI too far")          
        END
      ELSIF x.mode = Cond THEN
        Put1(IT + x.r*C4 + negated(x.r) MOD C1*C3 + C2); (* ITE cond *) nbRmnITBlockInsts := 2;
        encMovImm32(RH, 1);
        encMovImm32(RH, 0);
        x.r := RH; incR
      END ;
      x.mode := Reg
    END
  END load;

  PROCEDURE loadAdr(VAR x: Item);
  BEGIN
    IF x.mode = OM4B.Var THEN
      IF x.r > 0 THEN (*local*) encDPImm32(ADD, RH, SP, x.a + frame)
      ELSE GetSB(x.r); encStaticAccess(x.r, ADD, EXTADD, RH, RH, x.a) END;
      x.r := RH; incR
    ELSIF x.mode = OM4B.Par THEN encMemImm12(LDRIT3, RH, SP, x.a + frame, "param too far");
      IF x.b # 0 THEN encDPImm32(ADD, RH, RH, x.b) END;
      x.r := RH; incR
    ELSIF x.mode = RegI THEN
      IF x.a # 0 THEN encDPImm32(ADD, x.r, x.r, x.a) END
    ELSE OM4S.Mark("address error")
    END;
    x.mode := Reg
  END loadAdr;

  PROCEDURE loadCond(VAR x: Item);
  BEGIN
    IF x.type.form = OM4B.Bool THEN
      IF x.mode = OM4B.Const THEN IF x.a = 0 THEN x.r := NV ELSE x.r := AL END
      ELSE load(x);
        IF ~lastInstrSetFlags THEN encCMPImm8(x.r, 0) END ;
        x.r := NE; DEC(RH)
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
  BEGIN GetSB(0); 
    ASSERT(varsize+x.a < C12); encDPImm32(ADD, RH, RH, varsize+x.a);
    x.mode := Reg; x.r := RH; incR
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

  PROCEDURE log2(m: LONGINT; VAR e: LONGINT): LONGINT;
  BEGIN ASSERT(m > 0);
    e := 0;
    WHILE ~ODD(m) DO m := m DIV 2; 
      IF (m < 0) THEN m := -m END;
      INC(e) END ;
    RETURN m
  END log2;
  
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
        IF lim >= 0 THEN encCMPImm8(y.r, lim)
        ELSE (*open array*)
          IF x.mode IN {OM4B.Var, OM4B.Par} THEN
            encMemImm12(LDRIT3, RH, SP, x.a + 4 + frame, "array too big"); encCMPReg(y.r, RH)
          ELSE OM4S.Mark("error in Index")
          END
        END ;
        Trap(CC, 1)  (*BCC*)
      END ;
      (* Compute the shift to apply when s is a power of two *)
      IF log2(s, p2) # 1 THEN encMUL(y.r, y.r, s); p2 := 0 END ;
      IF x.mode = OM4B.Var THEN
        IF x.r > 0 THEN encDPReg(ADD, y.r, SP, y.r, p2); INC(x.a, frame)
        ELSE GetSB(x.r);
          IF x.r = 0 THEN encDPReg(ADD, y.r, RH, y.r, p2)
          ELSE Put0(EXTADD*C28 + RH*C24 + RH*C20 + x.a); encDPReg(ADD, y.r, RH, y.r, p2); x.a := 0
          END
        END ;
        x.r := y.r; x.mode := RegI
      ELSIF x.mode = OM4B.Par THEN
        encMemImm12(LDRIT3, RH, SP, x.a + frame, "param too far");
        encDPReg(ADD, y.r, RH, y.r, p2); x.mode := RegI; x.r := y.r; x.a := x.b
      ELSIF x.mode = RegI THEN
        encDPReg(ADD, x.r, x.r, y.r, p2); DEC(RH)
      END
    END
  END Index;

  PROCEDURE DeRef*(VAR x: Item);
  BEGIN
    IF x.mode = OM4B.Var THEN
      IF x.r > 0 THEN (*local*) encMemImm12(LDRIT3, RH, SP, x.a + frame, "local ref too far")
      ELSE GetSB(x.r); encStaticAccess(x.r, LDRIT3, EXTLDR, RH, RH, x.a) END;
      NilCheck; x.r := RH; incR
    ELSIF x.mode = OM4B.Par THEN
      encMemImm12(LDRIT3, RH, SP, x.a + frame, "par1 ref too far");
      encMemImm12(LDRIT3, RH, RH, x.b, "par2 ref too far"); NilCheck; x.r := RH; incR
    ELSIF x.mode = RegI THEN encMemImm12(LDRIT3, x.r, x.r, x.a, "RegI ref too far"); NilCheck
    ELSIF x.mode # Reg THEN OM4S.Mark("bad mode in DeRef")
    END ;
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
      SetCC(x, AL)
    ELSE (*fetch tag into RH*)
      IF varpar THEN encMemImm12(LDRIT3, RH, SP, x.a+4+frame, "tag too far")
      ELSE load(x);
        pc0 := pc; Put1(BCT1 + EQ*C8);  (*NIL belongs to every pointer type*)
        encMemImm12(LDRIT3, RH, x.r, -8, "")
      END ;
      encMemImm12(LDRIT3, RH, RH, T.nofpar*4, "T.nofpar too big"); incR;
      loadTypTagAdr(T);  (*tag of T*)
      encCMPReg(RH-1, RH-2); DEC(RH, 2);
      IF ~varpar THEN fix8(pc0, pc - pc0 - 4) END ;
      IF isguard THEN
        IF check THEN Trap(NE, 2) END
      ELSE SetCC(x, EQ);
        IF ~varpar THEN DEC(RH) END
      END
    END
  END TypeTest;

  (* Code generation for Boolean operators *)

  PROCEDURE Not*(VAR x: Item);   (* x := ~x *)
    VAR t: LONGINT;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    x.r := negated(x.r); t := x.a; x.a := x.b; x.b := t
  END Not;

  PROCEDURE And1*(VAR x: Item);   (* x := x & *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    Put1(IT + negated(x.r)*C4 + 8H (*IT cond*));  nbRmnITBlockInsts := 1;
    Put0(BRSIG*C27 + x.a);
    x.a := pc-4; FixLink(x.b); x.b := 0
  END And1;

  PROCEDURE And2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := merged(y.a, x.a); x.b := y.b; x.r := y.r
  END And2;

  PROCEDURE Or1*(VAR x: Item);   (* x := x OR *)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    Put1(IT + x.r*C4 + 8H (*IT cond*));  nbRmnITBlockInsts := 1;
    Put0(BRSIG*C27 + x.b);
    x.b := pc-4; FixLink(x.a); x.a := 0
  END Or1;

  PROCEDURE Or2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := y.a; x.b := merged(y.b, x.b); x.r := y.r
  END Or2;

  (* Code generation for arithmetic operators *)

  PROCEDURE Neg*(VAR x: Item);   (* x := -x *)
  BEGIN
    IF x.type.form = OM4B.Int THEN
      IF x.mode = OM4B.Const THEN x.a := -x.a
      ELSE load(x); encDPImm32(RSB, x.r, x.r, 0)
      END
    ELSIF x.type.form = OM4B.Real THEN
      IF x.mode = OM4B.Const THEN x.a := x.a + 7FFFFFFFH + 1
      ELSE load(x); encFPOpReg(VNEG, x.r, 0, x.r)
      END
    ELSE (*form = Set*)
      IF x.mode = OM4B.Const THEN x.a := -x.a-1 
      ELSE load(x); encDPImm32(EOR, x.r, x.r, -1)
      END
    END
  END Neg;

  PROCEDURE AddOp*(op: LONGINT; VAR x, y: Item);   (* x := x +- y *)
  BEGIN
    IF op = OM4S.plus THEN
      IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN x.a := x.a + y.a
      ELSIF y.mode = OM4B.Const THEN load(x);
        IF y.a # 0 THEN encDPImm32(ADD, x.r, x.r, y.a) END
      ELSE load(x); load(y); encDPReg(ADD, RH-2, x.r, y.r, 0); DEC(RH); x.r := RH-1
      END
    ELSE (*op = OM4S.minus*)
      IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN x.a := x.a - y.a
      ELSIF y.mode = OM4B.Const THEN load(x);
        IF y.a # 0 THEN encDPImm32(SUB, x.r, x.r, y.a) END
      ELSE load(x); load(y); encDPReg(SUB, RH-2, x.r, y.r, 0); DEC(RH); x.r := RH-1
      END
    END
  END AddOp;

  PROCEDURE MulOp*(VAR x, y: Item);   (* x := x * y *)
    VAR e: LONGINT;
  BEGIN
    IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN x.a := x.a * y.a
    ELSIF (y.mode = OM4B.Const) & (y.a >= 2) & (log2(y.a, e) = 1) THEN load(x); encShiftImm5(LSl, x.r, x.r, e)
    (*Low half multiplication (32b*32b => 32b) is the same for signed and unsinged integers*)
    ELSIF (x.mode = OM4B.Const) & (x.a >= 2) & (log2(x.a, e) = 1) THEN load(y); encShiftImm5(LSl, y.r, y.r, e); x.mode := Reg; x.r := y.r
    ELSE load(x); load(y); encMUL(RH-2, x.r, y.r); DEC(RH); x.r := RH-1
    END
  END MulOp;

  PROCEDURE DivOp*(op: LONGINT; VAR x, y: Item);   (* x := x op y *)
    VAR e: LONGINT;
  BEGIN
    IF op = OM4S.div THEN
      IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN
        IF y.a > 0 THEN x.a := x.a DIV y.a ELSE OM4S.Mark("bad divisor") END
      ELSIF (y.mode = OM4B.Const) & (y.a >= 2) & (log2(y.a, e) = 1) THEN load(x); encShiftImm5(ASR, x.r, x.r, e)
      ELSIF y.mode = OM4B.Const THEN
        IF y.a > 0 THEN load(x); load(y); encUDIV(RH-2, x.r, y.r); DEC(RH); x.r := RH-1 ELSE OM4S.Mark("bad divisor") END
      ELSE load(y);
        IF check THEN Trap(LE, 6) END;
        load(x); encUDIV(RH-2, x.r, y.r); DEC(RH); x.r := RH-1
      END
    ELSE (*op = OM4S.mod*)

      IF (x.mode = OM4B.Const) & (y.mode = OM4B.Const) THEN
        IF y.a > 0 THEN x.a := x.a MOD y.a ELSE OM4S.Mark("bad modulus") END
      ELSIF (y.mode = OM4B.Const) & (y.a >= 2) & (log2(y.a, e) = 1) THEN load(x);
        encShiftImm5(LSl, x.r, x.r, 32-e); encShiftImm5(LSR, x.r, x.r, 32-e)
      ELSIF y.mode = OM4B.Const THEN
        IF y.a > 0 THEN load(x); load(y); 
          encUDIV(RH, x.r, y.r); encMUL(RH, RH, y.r); encDPReg(SUB, RH-2, RH-2, RH, 0);
          DEC(RH); x.r := RH-1
        ELSE OM4S.Mark("bad modulus") END
      ELSE load(y);
        IF check THEN Trap(LE, 6) END;
        load(x); encUDIV(RH, x.r, y.r); encMUL(RH, RH, y.r); encDPReg(SUB, RH-2, RH-2, RH, 0);
        DEC(RH); x.r := RH-1
      END
    END
  END DivOp;

  (* Code generation for REAL operators *)

  PROCEDURE RealOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
  BEGIN load(x); load(y);
    IF op = OM4S.plus THEN encFPOpReg(VADD, SH-2, x.r, y.r)
    ELSIF op = OM4S.minus THEN encFPOpReg(VSUB, SH-2, x.r, y.r)
    ELSIF op = OM4S.times THEN encFPOpReg(VMUL, SH-2, x.r, y.r)
    ELSIF op = OM4S.rdiv THEN encFPOpReg(VDIV, SH-2, x.r, y.r)
    END;
    DEC(SH); x.r := SH-1
  END RealOp;

  (* Code generation for set operators *)

  PROCEDURE Singleton*(VAR x: Item);  (* x := {x} *)
  BEGIN
    IF x.mode = OM4B.Const THEN x.a := LSL(1, x.a)
    ELSE load(x); encMovImm32(RH, 1); encShiftReg(LSl, x.r, RH,  x.r)
    END
  END Singleton;

  PROCEDURE Set*(VAR x, y: Item);   (* x := {x .. y} *)
  BEGIN
    IF (x.mode = OM4B.Const) & ( y.mode = OM4B.Const) THEN
      IF x.a <= y.a THEN x.a := LSL(2, y.a) - LSL(1, x.a) ELSE x.a := 0 END
    ELSE
      load(x); encMovImm32(RH, -1); encShiftReg(LSl, x.r, RH, x.r);
      load(y); encMovImm32(RH, -2); encShiftReg(LSl, y.r, RH, y.r);
      IF x.mode = OM4B.Const THEN
        IF x.a # 0 THEN encDPImm32(EOR, y.r, y.r, -1); encDPImm32(AND, RH-1, y.r, x.a) END ;
        x.mode := Reg; x.r := RH-1 (*TODO Vérifier s'il ne maque pas des DEC(RH)*)
      ELSE DEC(RH); encDPReg(BIC, RH-1, x.r, y.r, 0)
      END
    END
  END Set;

  PROCEDURE In*(VAR x, y: Item);  (* x := x IN y *)
  BEGIN load(y);
    IF x.mode = OM4B.Const THEN encShiftImm5(ROR, y.r, y.r, (x.a + 1) MOD 20H); DEC(RH)
    ELSE load(x); encDPReg(ADD, x.r, x.r, 1, 0); encShiftReg(ROR, y.r, y.r, x.r); DEC(RH, 2)
    END ;
    SetCC(x, MI)
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
      IF op = OM4S.plus THEN encDPImm32(ORR, x.r, x.r, y.a)
      ELSIF op = OM4S.minus THEN encDPImm32(BIC, x.r, x.r, y.a)
      ELSIF op = OM4S.times THEN encDPImm32(AND, x.r, x.r, y.a)
      ELSIF op = OM4S.rdiv THEN encDPImm32(EOR, x.r, x.r, y.a)
      END ;
    ELSE load(x); load(y);
      IF op = OM4S.plus THEN encDPImm32(ORR, RH-2, x.r, y.r)
      ELSIF op = OM4S.minus THEN encDPImm32(BIC, RH-2, x.r, y.r)
      ELSIF op = OM4S.times THEN encDPImm32(AND, RH-2, x.r, y.r)
      ELSIF op = OM4S.rdiv THEN encDPImm32(EOR, RH-2, x.r, y.r)
      END ;
      DEC(RH); x.r := RH-1
    END 
  END SetOp;

  (* Code generation for relations *)

  PROCEDURE IntRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
  BEGIN
    IF (y.mode = OM4B.Const) & (y.type.form # OM4B.Proc) THEN
      load(x);
      IF (y.a # 0) OR ~(op IN {OM4S.eql, OM4S.neq}) OR ~lastInstrSetFlags THEN
        encMovImm32(RH, y.a); encCMPReg(x.r, RH)
      END;
      DEC(RH)
    ELSE
      IF (x.mode = Cond) OR (y.mode = Cond) THEN OM4S.Mark("not implemented") END ;
      load(x); load(y); encCMPReg(x.r, y.r); DEC(RH, 2)
    END ;
    SetCC(x, relmap[op - OM4S.eql])
  END IntRelation;

  PROCEDURE RealRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
  BEGIN load(x);
    IF (y.mode = OM4B.Const) & (y.a = 0) THEN encFPOpReg(VCMP0, x.r, 0, 0); DEC(RH)
    ELSE load(y); encFPOpReg(VCMP, x.r, 0, y.r); DEC(RH, 2)
    END;
    Put0(VMRS + APSRnzcv*C12);
    lastInstrSetFlags := TRUE;
    SetCC(x, relmap[op - OM4S.eql])
  END RealRelation;

  PROCEDURE StringRelation*(op: INTEGER; VAR x, y: Item);   (* x := x < y *)
    (*x, y are char arrays or strings*)
    VAR pc0, tbf0: LONGINT;
  BEGIN
    IF x.type.form = OM4B.String THEN loadStringAdr(x) ELSE loadAdr(x) END ;
    IF y.type.form = OM4B.String THEN loadStringAdr(y) ELSE loadAdr(y) END ;
  (*Compare:*) pc0 := pc;
    encMemImm12(LDRBIT3, RH, x.r, formatPUWImm8(FALSE, TRUE, TRUE, 1), "");
    encMemImm12(LDRBIT3, RH+1, y.r, formatPUWImm8(FALSE, TRUE, TRUE, 1), "");
    encCMPReg(RH, RH+1); tbf0 := pc; Put1(BCT1 + NE*C8); (*BC NE Fin*)
    encCMPImm8(RH, 0); encBackBranch(NE, pc0); (*BC NE Compare*)
  (* Fin: *) fix8(tbf0, pc - tbf0 - 4);
    DEC(RH, 2); SetCC(x, relmap[op - OM4S.eql])
  END StringRelation;

  (* Code generation of Assignments *)

  PROCEDURE StrToChar*(VAR x: Item);
  BEGIN x.type := OM4B.charType; DEC(strx, 4); x.a := ORD(str[x.a])
  END StrToChar;

  PROCEDURE Store*(VAR x, y: Item); (* x := y *)
    VAR op, opext: LONGINT;
  BEGIN  load(y);
    IF x.type.size = 1 THEN op := STRBIT2; opext := EXTSTRB
    ELSE op := STRIT3; opext := EXTSTR END ;
    IF x.mode = OM4B.Var THEN
      IF x.r > 0 THEN (*local*)
        IF y.type.form = OM4B.Real THEN ASSERT((x.a + frame) MOD C2 = 0);
          IF x.a + frame >= C10 THEN OM4S.Mark("local real var too far")
          END;
          Put0(VSTR + 1*C23 + SH MOD C1*C22 + SP*C16 + SH DIV C1*C12 + (x.a + frame) DIV C2)
        ELSE encMemImm12(op, y.r, SP, x.a + frame, "local var too far")
        END
      ELSE GetSB(x.r);
        IF y.type.form = OM4B.Real THEN encStaticRealAccess(x.r, VSTR, EXTVSTR, y.r, RH, x.a)
        ELSE encStaticAccess(x.r, op, opext, y.r, RH, x.a)
        END
      END    
    ELSIF x.mode = OM4B.Par THEN
      encMemImm12(LDRIT3, RH, SP, x.a + frame, "param offset 0 too far"); 
      IF y.type.form = OM4B.Real THEN ASSERT((x.b) MOD C2 = 0);
        IF x.a + frame >= C10 THEN OM4S.Mark("param offset 1 too far")
        END;
        Put0(VSTR + 1*C23 + SH MOD C1*C22 + RH*C16 + SH DIV C1*C12 + (x.b) DIV C2)
      ELSE encMemImm12(op, y.r, RH, x.b, "param offset 1 too far")
      END
    ELSIF x.mode = RegI THEN
      IF y.type.form = OM4B.Real THEN ASSERT((x.a) MOD C2 = 0);
        IF x.a + frame >= C10 THEN OM4S.Mark("RegI too far")
        END;
        Put0(VSTR + 1*C23 + y.r MOD C1*C22 + x.r*C16 + y.r DIV C1*C12 + (x.a + frame) DIV C2);
        DEC(SH)
      ELSE encMemImm12(op, y.r, x.r, x.a, "RegI too far"); DEC(RH)
      END
    ELSE OM4S.Mark("bad mode in Store")
    END;
    IF y.type.form = OM4B.Real THEN DEC(SH) ELSE DEC(RH)
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
          IF x.type.size = y.type.size THEN encMovImm32(RH, (y.type.size+3) DIV 4)
          ELSE OM4S.Mark("different length/size, not implemented")
          END
        ELSE (*y  open array*) encMemImm12(LDRIT3, RH, SP, y.a+4, "struct too far"); s := y.type.base.size;  (*element size*)
          encCMPImm8(RH, 0); pc0 := pc; Put1(BCT1 + EQ*C8); (*BEQ L0*)
          IF s = 1 THEN encDPImm32(ADD, RH, RH, 3); encShiftImm5(ASR, RH, RH, 2)
          ELSIF s # 4 THEN ASSERT(s MOD 4 = 0); incR; encMovImm32(RH, s DIV 4); encMUL(RH-1, RH-1, RH); DEC(RH)
          END;
          IF check THEN
            incR; encMovImm32(RH, (x.type.size+3) DIV 4); encCMPReg(RH-1, RH); Trap(GT, 3); DEC(RH)
          END
        END
      ELSIF x.type.form = OM4B.Record THEN encMovImm32(RH, x.type.size DIV 4)
      ELSE OM4S.Mark("inadmissible assignment")
      END ;
      incR;
      (*L1*) pc1 := pc;
      encMemImm12(LDRIT4, RH, y.r, formatPUWImm8(FALSE, TRUE, TRUE, 4), "");
      encMemImm12(STRIT4, RH, x.r, formatPUWImm8(FALSE, TRUE, TRUE, 4), "");
      DEC(RH);
      encDPImm32(SUB, RH, RH, 1); encBackBranch(NE, pc1); (*BNE L1*)
      (*L0:*) IF pc0 # -1 THEN fix8(pc0, pc - pc0 - 4) 
              END
    END;
    RH := 0
  END StoreStruct;

  PROCEDURE CopyString*(VAR x, y: Item);  (* x := y *) 
     VAR len, pc0: LONGINT;
   BEGIN loadAdr(x); len := x.type.len;
    IF len >= 0 THEN
      IF len < y.b THEN OM4S.Mark("string too long") END
    ELSIF check THEN encMemImm12(LDRIT3, RH, SP, x.a+4, "string too far");  (*open array len, frame = 0*)
      encCMPImm8(RH, y.b); Trap(LT, 3)
    END ;
    loadStringAdr(y);
    (*L0:*) pc0 := pc;
    encMemImm12(LDRIT4, RH, y.r, formatPUWImm8(FALSE, TRUE, TRUE, 4), "");
    encMemImm12(STRIT4, RH, x.r, formatPUWImm8(FALSE, TRUE, TRUE, 4), "");
    encShiftImm5(ASR, RH, RH, 24); encBackBranch(NE, pc0); (*BNE L0*)
    RH := 0
   END CopyString;
  
  (* Code generation for parameters *)
  
  PROCEDURE OpenArrayParam*(VAR x: Item);
  BEGIN loadAdr(x);
    IF x.type.len >= 0 THEN encMovImm32(RH, x.type.len) ELSE encMemImm12(LDRIT3, RH, SP, x.a+4+frame, "open array param too far") END ;
    incR
  END OpenArrayParam;

  PROCEDURE VarParam*(VAR x: Item; ftype: OM4B.Type);
    VAR xmd: INTEGER;
  BEGIN xmd := x.mode; loadAdr(x);
    IF (ftype.form = OM4B.Array) & (ftype.len < 0) THEN (*open array*)
      IF x.type.len >= 0 THEN encMovImm32(RH, x.type.len) ELSE  encMemImm12(LDRIT3, RH, SP, x.a+4+frame, "array param too far") END ;
      incR
    ELSIF ftype.form = OM4B.Record THEN
      IF xmd = OM4B.Par THEN encMemImm12(LDRIT3, RH, SP, x.a+4+frame, "record param too far"); incR ELSE loadTypTagAdr(x.type) END
    END
  END VarParam;

  PROCEDURE ValueParam*(VAR x: Item);
  BEGIN load(x)
  END ValueParam;

  PROCEDURE StringParam*(VAR x: Item);
  BEGIN loadStringAdr(x); encMovImm32(RH, x.b); incR  (*len*)
  END StringParam;

  (*For Statements*)

  PROCEDURE For0*(VAR x, y: Item);
  BEGIN load(y)
  END For0;

  PROCEDURE For1*(VAR x, y, z, w: Item; VAR L: LONGINT);
  BEGIN 
    load(z); encCMPReg(y.r, z.r); DEC(RH);
    IF w.a > 0 THEN Put1(IT + GT*C4 + 8H (*IT cond*))
    ELSIF w.a < 0 THEN Put1(IT + LT*C4 + 8H)
    ELSE OM4S.Mark("zero increment"); Put1(IT + MI*C4 + 8H)
    END;
    nbRmnITBlockInsts := 1;
    L := pc;
    Put0(BRSIG*C27);
    Store(x, y)
  END For1;

  PROCEDURE For2*(VAR x, y, w: Item);
  BEGIN load(x); DEC(RH); encDPImm32(ADD, x.r, x.r, w.a)
  END For2;

  (* Branches, procedure calls, procedure prolog and epilog *)

  PROCEDURE Here*(): LONGINT;
  BEGIN RETURN pc
  END Here;

  PROCEDURE FJump*(VAR L: LONGINT);
  BEGIN Put0(BRSIG*C27 + L); L := pc-4
  END FJump;

  PROCEDURE CFJump*(VAR x: Item);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    Put1(IT + negated(x.r) + 8H (*IT cond*));
    Put0(BRSIG*C27 + x.a); FixLink(x.b); x.a := pc-4
  END CFJump;

  PROCEDURE BJump*(L: LONGINT);
  BEGIN encBackBranch(AL, L)
  END BJump;

  PROCEDURE CBJump*(VAR x: Item; L: LONGINT);
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END;
    encBackBranch(negated(x.r), L); FixLink(x.b); FixLinkWith(x.a, L)
  END CBJump;

  PROCEDURE Fixup*(VAR x: Item);
  BEGIN FixLink(x.a)
  END Fixup;

  PROCEDURE SaveRegs(r: LONGINT);  (* R[0 .. r-1]*)
    VAR r0: LONGINT;
  BEGIN 
    ASSERT(r IN {0..13});
    r0 := LSL(1, r) - 1;
    IF r0 < C8 THEN (*PUSH T1*) Put1(PUSHT1 + r0)
    ELSE (*PUSH T2*) Put0(PUSHT2 + r0)
    END;
    INC(frame, 4*r)
  END SaveRegs;

  PROCEDURE RestoreRegs(r: LONGINT); (*R[0 .. r-1]*)
    VAR r0: LONGINT;
  BEGIN (*r > 0*) r0 := r;
    ASSERT(r IN {0..13});
    r0 := LSL(1, r) - 1;
    IF r0 < C8 THEN (*POP T1*) Put1(POPT1 + r0)
    ELSE (*POP T2*) Put0(POPT2 + r0)
    END;
    DEC(frame, 4*r)
  END RestoreRegs;

  PROCEDURE PrepCall*(VAR x: Item; VAR r: LONGINT);
  BEGIN (*x.type.form = OM4B.Proc*)
    IF x.mode > OM4B.Par THEN load(x) END ;
    r := RH;
    IF RH > 0 THEN SaveRegs(RH); RH := 0 END
  END PrepCall;

  PROCEDURE Call*(VAR x: Item; r: LONGINT);
  BEGIN (*x.type.form = OM4B.Proc*)
    IF x.mode = OM4B.Const THEN
      IF x.r >= 0 THEN encBackBranch(AL, x.a)
      ELSE (*imported*)
        IF pc - fixORGP < C16 THEN
        (*aaaannnnppppppppdddddddddddddddd*)
          Put0(RH*C28 + (-x.r)*C24 + x.a*C16 + pc - fixORGP); fixORGP := pc-4;
          Put1(BLX + RH*C3) (*Attention : nécéssite de placer l'adresse 
            ablosule et non relative au début du module dans les descripteurs de
            module chagée par le module Modules*)
        ELSE OM4S.Mark("fixup impossible")
        END
      END
    ELSE
      IF x.mode <= OM4B.Par THEN load(x); DEC(RH)
      ELSE encMemImm12(LDRIT3, RH, SP, 0, ""); encDPImm32(ADD, SP, SP, 4); DEC(r); DEC(frame, 4)
      END ;
      IF check THEN Trap(EQ, 5) END ;
      Put1(BLX + RH*C3)
    END ;
    IF x.type.base.form = OM4B.NoTyp THEN (*procedure*) RH := 0
    ELSE (*function*)
      IF r > 0 THEN encMovImm32(r, 0); RestoreRegs(r) END ;
      x.mode := Reg; x.r := r; RH := r+1
    END
  END Call;

  PROCEDURE Enter*(parblksize, locblksize: LONGINT; int: BOOLEAN);
    VAR a, r: LONGINT;
  BEGIN frame := 0;
    IF ~int THEN (*procedure prolog*)
      IF locblksize >= C16 THEN OM4S.Mark("too many locals") END ;
      a := 4; r := 0;
      encDPImm32(SUB, SP, SP, locblksize); encMemImm12(STRIT3, LNK, SP, 0, "");
      WHILE a < parblksize DO encMemImm12(STRIT3, r, SP, a, ""); INC(r); INC(a, 4) END
      ELSE (*interrupt procedure*) 
      OM4S.Mark("Not implemented yet");
(* TODO : à reprendre 
      encDPImm32(SUB, SP, SP, locblksize); encMemImm12(STRIT3, 0, SP, 0, ""); encMemImm12(STRIT3, 1, SP, 4, ""); encMemImm12(STRIT3, 2, SP, 8, "")
*)
      (*R0, R1, R2 saved on stack*)
    END
  END Enter;

  PROCEDURE Return*(form: INTEGER; VAR x: Item; size: LONGINT; int: BOOLEAN);
  BEGIN
    IF form # OM4B.NoTyp THEN load(x) END ;
    IF ~int THEN (*procedure epilog*)
      encMemImm12(LDRIT3, LNK, SP, 0, ""); encDPImm32(ADD, SP, SP, size); Put1(BLX + LNK*C3)
    ELSE (*interrupt return, restore R2, R1, R0*)
      OM4S.Mark("Not implemented yet");
(* TODO : à reprendre 
      Put2(Ldr, 2, SP, 8); Put2(Ldr, 1, SP, 4); Put2(Ldr, 0, SP, 0); Put1(Add, SP, SP, size);
      Put3(BR, 7, C4) *)(*RTI*)
    END ;
    RH := 0
  END Return;

(* TODO: j'en suis là *)

  (* In-line code procedures*)

  PROCEDURE Increment*(upordown: LONGINT; VAR x, y: Item);
    VAR op, zr, v: LONGINT;
  BEGIN (*frame = 0*)
    IF upordown = 0 THEN op := Add ELSE op := Sub END ;
    IF x.type = OM4B.byteType THEN v := 1 ELSE v := 0 END ;
    IF y.type.form = OM4B.NoTyp THEN y.mode := OM4B.Const; y.a := 1 END ;
    IF (x.mode = OM4B.Var) & (x.r > 0) THEN
      zr := RH; Put2(Ldr+v, zr, SP, x.a); incR;
      IF y.mode = OM4B.Const THEN Put1a(op, zr, zr, y.a) ELSE load(y); Put0(op, zr, zr, y.r); DEC(RH) END ;
      Put2(Str+v, zr, SP, x.a); DEC(RH)
    ELSE loadAdr(x); zr := RH; Put2(Ldr+v, RH, x.r, 0); incR;
      IF y.mode = OM4B.Const THEN Put1a(op, zr, zr, y.a) ELSE load(y); Put0(op, zr, zr, y.r); DEC(RH) END ;
      Put2(Str+v, zr, x.r, 0); DEC(RH, 2)
    END
  END Increment;

  PROCEDURE Include*(inorex: LONGINT; VAR x, y: Item);
    VAR op, zr: LONGINT;
  BEGIN loadAdr(x); zr := RH; Put2(Ldr, RH, x.r, 0); incR;
    IF inorex = 0 THEN op := Ior ELSE op := Ann END ;
    IF y.mode = OM4B.Const THEN Put1a(op, zr, zr, LSL(1, y.a))
    ELSE load(y); Put1(Mov, RH, 0, 1); Put0(Lsl, y.r, RH, y.r); Put0(op, zr, zr, y.r); DEC(RH)
    END ;
    Put2(Str, zr, x.r, 0); DEC(RH, 2)
  END Include;

  PROCEDURE Assert*(VAR x: Item);
    VAR cond: LONGINT;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    IF x.a = 0 THEN cond := negated(x.r)
    ELSE Put3(BC, x.r, x.b); FixLink(x.a); x.b := pc-1; cond := AL
    END ;
    Trap(cond, 7); FixLink(x.b)
  END Assert; 

  PROCEDURE New*(VAR x: Item);
  BEGIN loadAdr(x); loadTypTagAdr(x.type.base); Trap(AL, 0); RH := 0
  END New;

  PROCEDURE Pack*(VAR x, y: Item);
    VAR z: Item;
  BEGIN z := x; load(x); load(y);
    Put1(Lsl, y.r, y.r, 23); Put0(Add, x.r, x.r, y.r); DEC(RH); Store(z, x)
  END Pack;

  PROCEDURE Unpk*(VAR x, y: Item);
    VAR z, e0: Item;
  BEGIN  z := x; load(x); e0.mode := Reg; e0.r := RH; e0.type := OM4B.intType;
    Put1(Asr, RH, x.r, 23); Put1(Sub, RH, RH, 127); Store(y, e0); incR;
    Put1(Lsl, RH, RH, 23); Put0(Sub, x.r, x.r, RH); Store(z, x)
  END Unpk;

  PROCEDURE Led*(VAR x: Item);
  BEGIN load(x); Put1(Mov, RH, 0, -60); Put2(Str, x.r, RH, 0); DEC(RH)
  END Led;

  PROCEDURE Get*(VAR x, y: Item);
  BEGIN load(x); x.type := y.type; x.mode := RegI; x.a := 0; Store(y, x)
  END Get;

  PROCEDURE Put*(VAR x, y: Item);
  BEGIN load(x); x.type := y.type; x.mode := RegI; x.a := 0; Store(x, y)
  END Put;

  PROCEDURE Copy*(VAR x, y, z: Item);
  BEGIN load(x); load(y);
    IF z.mode = OM4B.Const THEN
      IF z.a > 0 THEN load(z) ELSE OM4S.Mark("bad count") END
    ELSE load(z);
      IF check THEN Trap(LT, 3) END ;
      Put3(BC, EQ, 6)
    END ;
    Put2(Ldr, RH, x.r, 0); Put1(Add, x.r, x.r, 4);
    Put2(Str, RH, y.r, 0); Put1(Add, y.r, y.r, 4);
    Put1(Sub, z.r, z.r, 1); Put3(BC, NE, -6); DEC(RH, 3)
  END Copy;

  PROCEDURE LDPSR*(VAR x: Item);
  BEGIN (*x.mode = Const*)  Put3(0, 15, x.a + 20H)
  END LDPSR;

  PROCEDURE LDREG*(VAR x, y: Item);
  BEGIN
    IF y.mode = OM4B.Const THEN Put1a(Mov, x.a, 0, y.a)
    ELSE load(y); Put0(Mov, x.a, 0, y.r); DEC(RH)
    END
  END LDREG;

  (*In-line code functions*)

  PROCEDURE Abs*(VAR x: Item);
  BEGIN
    IF x.mode = OM4B.Const THEN x.a := ABS(x.a)
    ELSE load(x);
      IF x.type.form = OM4B.Real THEN Put1(Lsl, x.r, x.r, 1); Put1(Ror, x.r, x.r, 1)
      ELSE Put1(Cmp, x.r, x.r, 0); Put3(BC, GE, 2); Put1(Mov, RH, 0, 0); Put0(Sub, x.r, RH, x.r)
      END
    END
  END Abs;

  PROCEDURE Odd*(VAR x: Item);
  BEGIN load(x); Put1(And, x.r, x.r, 1); SetCC(x, NE); DEC(RH)
  END Odd;

  PROCEDURE Floor*(VAR x: Item);
  BEGIN load(x); Put1(Mov+U, RH, 0, 4B00H); Put0(Fad+V, x.r, x.r, RH)
  END Floor;

  PROCEDURE Float*(VAR x: Item);
  BEGIN load(x); Put1(Mov+U, RH, 0, 4B00H);  Put0(Fad+U, x.r, x.r, RH)
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
    ELSE (*open array*) Put2(Ldr, RH, SP, x.a + 4 + frame); x.mode := Reg; x.r := RH; incR
    END 
  END Len;

  PROCEDURE Shift*(fct: LONGINT; VAR x, y: Item);
    VAR op: LONGINT;
  BEGIN load(x);
    IF fct = 0 THEN op := Lsl ELSIF fct = 1 THEN op := Asr ELSE op := Ror END ;
    IF y.mode = OM4B.Const THEN Put1(op, x.r, x.r, y.a MOD 20H)
    ELSE load(y); Put0(op, RH-2, x.r, y.r); DEC(RH); x.r := RH-1
    END
  END Shift;

  PROCEDURE ADC*(VAR x, y: Item);
  BEGIN load(x); load(y); Put0(Add+C13, x.r, x.r, y.r); DEC(RH)
  END ADC;

  PROCEDURE SBC*(VAR x, y: Item);
  BEGIN load(x); load(y); Put0(Sub+C13, x.r, x.r, y.r); DEC(RH)
  END SBC;

  PROCEDURE UML*(VAR x, y: Item);
  BEGIN load(x); load(y); Put0(Mul+C13, x.r, x.r, y.r); DEC(RH)
  END UML;

  PROCEDURE Bit*(VAR x, y: Item);
  BEGIN load(x); Put2(Ldr, x.r, x.r, 0);
    IF y.mode = OM4B.Const THEN Put1(Ror, x.r, x.r, y.a+1); DEC(RH)
    ELSE load(y); Put1(Add, y.r, y.r, 1); Put0(Ror, x.r, x.r, y.r); DEC(RH, 2)
    END ;
    SetCC(x, MI)
  END Bit;

  PROCEDURE Register*(VAR x: Item);
  BEGIN (*x.mode = Const*)
    Put0(Mov, RH, 0, x.a MOD C4); x.mode := Reg; x.r := RH; incR
  END Register;

  PROCEDURE H*(VAR x: Item);
  BEGIN (*x.mode = Const*)
    Put0(Mov + U + x.a MOD 2 * V, RH, 0, 0); x.mode := Reg; x.r := RH; incR
  END H;

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
  BEGIN pc := 0; tdx := 0; strx := 0; RH := 0; fixORGP := 0; fixORGD := 0; fixORGT := 0; check := v # 0; version := v;
    IF v = 0 THEN pc := 1;
      REPEAT code[pc] := 0; INC(pc) UNTIL pc = 8
    END
  END Open;

  PROCEDURE SetDataSize*(dc: LONGINT);
  BEGIN varsize := dc
  END SetDataSize;

  PROCEDURE Header*;
  BEGIN entry := pc*4;
    IF version = 0 THEN code[0] := 0E7000000H-1 + pc;  Put1a(Mov, SP, 0, StkORG0)  (*RISC-0*)
    ELSE Put1(Sub, SP, SP, 4); Put2(Str, LNK, SP, 0)
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
    VAR obj: OM4B.Object;
      i, comsize, nofimps, nofptrs, size: LONGINT;
      name: OM4S.Ident;
      F: Files.File; R: Files.Rider;
  BEGIN  (*exit code*)
    IF version = 0 THEN Put1(Mov, 0, 0, 0); Put3(BR, 7, 0)  (*RISC-0*)
    ELSE Put2(Ldr, LNK, SP, 0); Put1(Add, SP, SP, 4); Put3(BR, 7, LNK)
    END ;
    obj := OM4B.topScope.next; nofimps := 0; comsize := 4; nofptrs := 0;
    WHILE obj # NIL DO
      IF (obj.class = OM4B.Mod) & (obj.dsc # OM4B.system) THEN INC(nofimps) (*count imports*)
      ELSIF (obj.exno # 0) & (obj.class = OM4B.Const) & (obj.type.form = OM4B.Proc)
          & (obj.type.nofpar = 0) & (obj.type.base = OM4B.noType) THEN i := 0; (*count commands*)
        WHILE obj.name[i] # 0X DO INC(i) END ;
        i := (i+4) DIV 4 * 4; INC(comsize, i+4)
      ELSIF obj.class = OM4B.Var THEN INC(nofptrs, NofPtrs(obj.type))  (*count pointers*)
      END ;
      obj := obj.next
    END ;
    size := varsize + strx + comsize + (pc + nofimps + nofent + nofptrs + 1)*4;  (*varsize includes type descriptors*)
    
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
    Files.WriteInt(R, pc);  (*code len*)
    FOR i := 0 TO pc-1 DO Files.WriteInt(R, code[i]) END ;  (*program*)
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
          IF obj.type.form = OM4B.Record THEN Files.WriteInt(R,  obj.type.len MOD C16)
          ELSIF (obj.type.form = OM4B.Pointer) & ((obj.type.base.typobj = NIL) OR (obj.type.base.typobj.exno = 0)) THEN
            Files.WriteInt(R,  obj.type.base.len MOD C16)
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
    Files.Write(R, "O"); Files.Register(F)
  END Close;

BEGIN relmap[0] := EQ; relmap[1] := NE; relmap[2] := LT; relmap[3] := LE; relmap[4] := GT; relmap[5] := GE;

  imm3map[SUB] := 1E00H; imm8map[SUB] := 3800H; imm12map[SUB] := 0F2A00000H; reg3map[SUB] := 1A00H; reg4map[SUB] = 0H;    reg4shmap[SUB] := 0EBB00000H;
  imm3map[ADD] := 1C00H; imm8map[ADD] := 3000H; imm12map[ADD] := 0F2000000H; reg3map[ADD] := 1800H; reg4map[ADD] = 4400H; reg4shmap[ADD] := 0EB100000H;
  imm3map[RSB] := 4240H; imm8map[RSB] := 0H;    imm12map[RSB] := 0H;         reg3map[RSB] := 0H;    reg4map[RSB] = 0H;    reg4shmap[RSB] := 0EBD00000H;
  imm3map[EOR] := 0H;    imm8map[EOR] := 0H;    imm12map[EOR] := 0H;         reg3map[EOR] := 4040H; reg4map[EOR] = 0H;    reg4shmap[EOR] := 0EA900000H;
  imm3map[AND] := 0H;    imm8map[AND] := 0H;    imm12map[AND] := 0H;         reg3map[AND] := 4000H; reg4map[AND] = 0H;    reg4shmap[AND] := 0EA100000H;
  imm3map[BIC] := 0H;    imm8map[BIC] := 0H;    imm12map[BIC] := 0H;         reg3map[BIC] := 4380H; reg4map[BIC] = 0H;    reg4shmap[BIC] := 0EA300000H;
  imm3map[ORR] := 0H;    imm8map[ORR] := 0H;    imm12map[ORR] := 0H;         reg3map[ORR] := 4300H; reg4map[ORR] = 0H;    reg4shmap[ORR] := 0EA500000H;
  
  shimm5map[LSl] :=  0000H; shimm5wmap[LS1] := 0EA5F0000H; shreg3map[LSl] := 4080H; shreg4map[LSl] := 0FA10F000H;
  shimm5map[ASR] :=  1000H; shimm5wmap[ASR] := 0EA5F0020H; shreg3map[ASR] := 4100H; shreg4map[ASR] := 0FA50F000H;
  shimm5map[LSR] :=  0800H; shimm5wmap[LSR] := 0EA5F0010H; shreg3map[LSR] := 40C0H; shreg4map[LSR] := 0FA30F000H;
  shimm5map[ROR] := 0FFFFH; shimm5wmap[ROR] := 0EA5F0030H; shreg3map[ROR] := 41C0H; shreg4map[ROR] := 0FA70F000H;
  
  lastInstrSetFlags := FALSE; nbRmnITBlockInsts := 0
END OM4G.
