MODULE OM4Tool;  (*NW 18.2.2013
  C. Schoffit 12/11/2023*)
  IMPORT SYSTEM, Files, Texts, Oberon, OM4B, OM4A;

  TYPE
    ExternalRefMap = POINTER TO ExternalRefMapDesc;
    ExternalRefMapDesc = RECORD
      ext: ARRAY OM4A.maxCode OF BYTE
    END;
  
    ITBlockDesc = RECORD
      cond, pos, nofinst: BYTE;
      mask: ARRAY 5 OF CHAR
    END;
  VAR W: Texts.Writer;
    Form: INTEGER;  (*result of ReadType*)
    itB: ITBlockDesc;
    mnemo0: ARRAY 8, 5 OF CHAR;  (*mnemonics*)
    mnemo1: ARRAY 16, 3 OF CHAR;  (*condition mnemonics*)
  
  PROCEDURE WriteHexVLen(VAR W: Texts.Writer; x, n: LONGINT; leadingZero: BOOLEAN);
    VAR i: INTEGER; y: LONGINT;
      a: ARRAY 10 OF CHAR;
  BEGIN ASSERT(n<=10);
    i := 0; Texts.Write(W, " ");
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END;
      x := x DIV 10H; IF x < 0 THEN INC(x, OM4A.C28) END; INC(i)
    UNTIL (i >= n) & (x = 0);
    IF leadingZero & (a[i-1] > "9") THEN Texts.Write(W, "0") END; (*Add a leading 0 if first hex digit is a letter*)
    REPEAT DEC(i); Texts.Write(W, a[i]) UNTIL i = 0
  END WriteHexVLen;

  PROCEDURE Read(VAR R: Files.Rider; VAR n: INTEGER);
    VAR b: BYTE;
  BEGIN Files.ReadByte(R, b);
    IF b < 80H THEN n := b ELSE n := b - 100H END
  END Read;

  PROCEDURE ReadType(VAR R: Files.Rider);
    VAR key, len, lev, size, off: INTEGER;
      ref, mno, class, form, readonly: INTEGER;
      name, modname: ARRAY 32 OF CHAR;
  BEGIN Read(R, ref); Texts.Write(W, " "); Texts.Write(W, "[");
    IF ref < 0 THEN Texts.Write(W, "^"); Texts.WriteInt(W, -ref, 1)
    ELSE Texts.WriteInt(W, ref, 1);
      Read(R, form); Texts.WriteString(W, "  form = "); Texts.WriteInt(W, form, 1);
      IF form = OM4B.Pointer THEN ReadType(R)
      ELSIF form = OM4B.Array THEN
        ReadType(R); Files.ReadNum(R, len); Files.ReadNum(R, size);
        Texts.WriteString(W, "  len = "); Texts.WriteInt(W, len, 1);
        Texts.WriteString(W, "  size = "); Texts.WriteInt(W, size, 1)
      ELSIF form = OM4B.Record THEN
        ReadType(R);  (*base type*)
        Files.ReadNum(R, off); Texts.WriteString(W, "  exno = "); Texts.WriteInt(W, off, 1); 
        Files.ReadNum(R, off); Texts.WriteString(W, "  extlev = "); Texts.WriteInt(W, off, 1);
        Files.ReadNum(R, size); Texts.WriteString(W, "  size = "); Texts.WriteInt(W, size, 1);
        Texts.Write(W, " "); Texts.Write(W, "{"); Read(R, class);
        WHILE class # 0 DO (*fields*)
          Files.ReadString(R, name);
          IF name[0] # 0X THEN Texts.Write(W, " "); Texts.WriteString(W, name); ReadType(R)
          ELSE Texts.WriteString(W, " --")
          END ;
          Files.ReadNum(R, off); Texts.WriteInt(W, off, 4); Read(R, class)
        END ;
        Texts.Write(W, "}")
      ELSIF form = OM4B.Proc THEN
        ReadType(R); Texts.Write(W, "("); Read(R, class);
        WHILE class # 0 DO
          Texts.WriteString(W, " class = "); Texts.WriteInt(W, class, 1); Read(R, readonly);
          IF readonly = 1 THEN Texts.Write(W, "#") END ;
          ReadType(R); Read(R, class)
        END ;
        Texts.Write(W, ")")
      END ;
      Files.ReadString(R, modname);
      IF modname[0] # 0X THEN
        Files.ReadInt(R, key); Files.ReadString(R, name);
        Texts.Write(W, " "); Texts.WriteString(W, modname); Texts.Write(W, "."); Texts.WriteString(W, name);
        Texts.WriteHex(W, key)
      END
    END ;
    Form := form; Texts.Write(W, "]")
  END ReadType;

  PROCEDURE DecSym*;  (*decode symbol file*)
    VAR class, typno, k: INTEGER;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "OM4-decode "); Texts.WriteString(W, S.s);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      F := Files.Old(S.s);
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadInt(R, k); Files.ReadInt(R, k);
        Files.ReadString(R, name); Texts.WriteString(W, name); Texts.WriteHex(W, k);
        Read(R, class); Texts.WriteInt(W, class, 3); (*sym file version*)
        IF class = OM4B.versionkey THEN
          Texts.WriteLn(W); Read(R, class);
          WHILE class # 0 DO
            Texts.WriteInt(W, class, 4); Files.ReadString(R, name); Texts.Write(W, " "); Texts.WriteString(W, name);
            ReadType(R);
            IF class = OM4B.Typ THEN
              Texts.Write(W, "("); Read(R, class);
              WHILE class # 0 DO  (*pointer base fixup*)
                Texts.WriteString(W, " ->"); Texts.WriteInt(W, class, 4); Read(R, class)
              END ;
              Texts.Write(W, ")")
            ELSIF (class = OM4B.Const) OR (class = OM4B.Var) THEN
              Files.ReadNum(R, k); Texts.WriteInt(W, k, 5);  (*Reals, Strings!*)
            END ;
            Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
            Read(R, class)
          END
        ELSE Texts.WriteString(W, " bad symfile version")
        END
      ELSE Texts.WriteString(W, " not found")
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END DecSym;
  
(* ---------------------------------------------------*)

  PROCEDURE WriteReg(r: LONGINT);
  BEGIN Texts.Write(W, " ");
    IF r < 12 THEN Texts.WriteString(W, "R"); Texts.WriteInt(W, r MOD 10H, 1)
    ELSIF r = 12 THEN Texts.WriteString(W, "MT")
    ELSIF r = 13 THEN Texts.WriteString(W, "SP")
    ELSIF r = 14 THEN Texts.WriteString(W, "LR")
    ELSE Texts.WriteString(W, "PC")
    END
  END WriteReg;

  PROCEDURE ThumbExpandImm(op: SET): LONGINT;
  (*15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
                    i                          imm3             a b c d e f g h
    ThumbExpandImm(i:imm3:imm8);*)
    CONST iimm3Msk = {26, 12..14};
      f1 = {}; f2 = {12}; f3={13}; f4 = {12..13};
    VAR res, i: LONGINT;
      b4: BYTE;
  BEGIN
    b4 := ORD(op) MOD OM4A.C8;
    IF op*iimm3Msk = f1 THEN (*0000x: 00000000 00000000 00000000 abcdefgh*)
      res := b4
    ELSIF op*iimm3Msk=f2 THEN (*0001x: 00000000 abcdefgh 00000000 abcdefgh (note b)*)
      ASSERT(b4 # 0);
      res := b4*OM4A.C16 + b4
    ELSIF op*iimm3Msk=f3 THEN (*0010x: abcdefgh 00000000 abcdefgh 00000000 (note b)*)
      ASSERT(b4 # 0);
      res := b4*OM4A.C24 + b4*OM4A.C8
    ELSIF op*iimm3Msk=f4 THEN (*0011x: abcdefgh abcdefgh abcdefgh abcdefgh (note b)*)
      ASSERT(b4 # 0);
      res := b4*OM4A.C24 + b4*OM4A.C16 + b4*OM4A.C8 + b4
    ELSE (*01000: 1bcdefgh 00000000 00000000 00000000
           01001: 01bcdefg h0000000 00000000 00000000
           01010: 001bcdef gh000000 00000000 00000000
           01011: 0001bcde fgh00000 00000000 00000000
           .      .
           .      . 8-bit values shifted to other positions
           .      .
           11101: 00000000 00000000 000001bc defgh000
           11110: 00000000 00000000 0000001b cdefgh00
           11111: 00000000 00000000 00000001 bcdefgh0*)
      b4 := b4 MOD OM4A.C7 + OM4A.C7; 
      i := ORD(op) DIV OM4A.C26 MOD OM4A.C1 + ORD(op) DIV OM4A.C12 MOD OM4A.C3 +
           ORD(op) DIV OM4A.C7 MOD OM4A.C1 - 8;
      ASSERT((i >= 0) & (i < 24));
      res := b4*OM4A.C24;
      WHILE i > 0 DO res := ASR(res, 1); IF res < 0 THEN INC(res, OM4A.C31) END; DEC(i)
      END
    END;
    RETURN res
    (*Note b. UNPREDICTABLE if abcdefgh == 00000000.*)
  END ThumbExpandImm;
  
  PROCEDURE SignExtendEven25(op: SET): LONGINT;
    VAR res: LONGINT;
    s, j1, j2: BOOLEAN;
  BEGIN res := 0;
    s := 26 IN op;
    j1 := 13 IN op;
    j2 := 11 IN op;
    IF ~(j1 # s) THEN INC(res, OM4A.C22) END;
    IF ~(j2 # s) THEN INC(res, OM4A.C21) END;
    INC(res, ORD(op) DIV OM4A.C16 MOD OM4A.C10*OM4A.C11);
    INC(res, ORD(op) MOD OM4A.C11);
    res := LSL(res, 1);
    IF s THEN (* Negative offset*) INC(res, LSL(-1, 24)) END;
    RETURN res
  END SignExtendEven25;
  
  PROCEDURE SignExtendEven8(imm: LONGINT): LONGINT;
  BEGIN IF imm > OM4A.C7 THEN DEC(imm, OM4A.C8) END;
    RETURN imm*OM4A.C1
  END SignExtendEven8;
  
  PROCEDURE imm16(b1, b2, b3, b4: BYTE): LONGINT;
  BEGIN
    RETURN 0 + b2 MOD OM4A.C4*OM4A.C12 + b1 DIV OM4A.C2 MOD OM4A.C1*OM4A.C11 +
              b3 DIV OM4A.C4 MOD OM4A.C3*OM4A.C8 + b4
  END imm16;
  
  PROCEDURE WriteOp(op: SET; mnemo: ARRAY OF CHAR; setFlagsOutsideITB, bit20SetsFlag: BOOLEAN);
  BEGIN Texts.WriteString(W, mnemo); IF bit20SetsFlag & (20 IN op) THEN Texts.Write(W, "S") END;
    IF itB.pos < itB.nofinst THEN
      IF itB.mask[itB.pos] = "T" THEN Texts.WriteString(W, mnemo1[itB.cond])
      ELSE Texts.WriteString(W, mnemo1[OM4A.negated(itB.cond)])
      END;
      INC(itB.pos)
    ELSIF setFlagsOutsideITB THEN Texts.Write(W, "S")
    END
  END WriteOp;
  
  PROCEDURE opcode(VAR c: OM4A.ModuleCode; VAR er: ExternalRefMap; VAR i: LONGINT);
    CONST
      (*32-bit instructions*)
      T32MSK1 = {25..28, 22}; T32MSK2 = {25..28}; T32MSK3 = {26..28};
      T32MSK4 = {25, 27..28, 15}; T32MSK5 = {27..28, 15}; T32MSK6 = {24..28, 20};
      T32MSK7 = {25..28, 20..22};
      
      (*T32MSK4 10 x0xxxxx 0: Data processing (modified immediate) on page A5-138*)
      DataProcModImm = {28};
      (*T32MSK4 10 x1xxxxx 0: Data processing (plain binary immediate) on page A5-141*)
      DataProcPlainBinImm = {28, 25};
      (*T32MSK5 10 xxxxxxx 1: Branches and miscellaneous control on page A5-142*)
      BrMiscCtrl = {28, 15};
      (*T32MSK3 01 1xxxxxx x: Coprocessor instructions on page A5-158*)
      CoProc = {26..27};

      (*T32MSK6 11 000xxx0 x: Store single data item on page A5-149*)
      StrSingleDataItem = {27..28};

      (*T32MSK7 11 00xx101 x Load word on page A5-146*)
      LdrWord = {27..28, 22, 20};

      T32MSK41 = {21..24}; T32MSK42 = {20..24}; 
      (*T32MSK41 1101x SUB (immediate) on page A7-402 or CMP (immediate) on page A7-223*)
      SubCmpModImm = {24, 23, 21};
      (*T32MSK41 1000x ADD (immediate) on page A7-190 or CMN (immediate) on page A7-221*)
      AddCmnModImm = {24};
      (*T32MSK41 0000x AND (immediate) on page A7-200 or TST (immediate) on page A7-419*)
      AndTstModImm = {};
      
      (*T32MSK42 00100 -: Move Wide, 16-bit MOV (immediate) on page A7-291*)
      MW16Bit = {22};
      (*T32MSK42 01100 -: Move Top, 16-bit MOVT on page A7-296*)
      MoveTop = {23, 22};
      
      T32MSK61 = {21..23}; T32MSK62 = {21..23, 11};
      (*T32MSK61 100 xxxxxx Store Register Byte STRB (immediate) on page A7-389*)
      StrRegByteImmT2 = {23};
      (*T32MSK61 110 xxxxxx Store Register STR (immediate) on page A7-386*)
      StrRegImmT3 = {22..23};
      
      (*T32MSK62 010 1xxxxx Store Register STR (immediate) on page A7-386*)
      StrRegImmT4 = {22, 11};
      
      T32MSK71 = {23..24}; T32MSK72 = {23..24, 11, 8};
      (*T32MSK71 01 xxxxxx: Rn # 1111: Load Register LDR (immediate) on page A7-246*)
      (*T32MSK71 0x xxxxxx: Rn = 1111: Load Register LDR (literal) on page A7-248*)
      LdrRegImmOrLit = {23};

      (*T32MSK72 00 1xx1xx not 1111 LDR (immediate) on page A7-246*)
      LdrREgImmOrLit2 = {11, 8};
      
      T32MSK51 = {12, 14}; T32MSK52 = {21..26, 12, 14};
      (*T32MSK51 1x1 xxxxxxx: Branch with Link BL on page A7-213*)
      BrWithLnk = {12, 14};
      (*T32MSK52 0x0 011111x: Move from Special Register MRS on page A7-300*)
      MovFrSpReg = {21..25};
      
      T32MSK31 = {11}; T32MSK32 = {8..11};
      (*T32MSK31 0: Oberon implementation for Trap*)
      Trap = {};
      (*T32MSK32 1010: Single-precision floating point coprocessor*)
      FPSingle = {11, 9};

      T32MSK321 = {20..25, 4}; T32MSK322 = {24..25, 20..21}; T32MSK323 = {28, 23, 20..21, 6};
      (*T32MSK321 A7.7.243 VMOV (between Arm core register and single-precision register)*)
      VMOVSR = {25, 4};
      
      (*T32MSK322 A7.7.259 VSTR*)
      VSTR = {24};
      (*T32MSK322 1xx01 - FP Load Register VLDR on page A7-473*)
      VLDR = {20, 24};
      
      (*T32MSK323 0 0x11 - x0 FP Add VADD on page A7-456*)
      VADD = {20..21};
      
      (*16-bit instructions*)
      T16MSK1 = {14..15}; T16MSK2 = {10..15}; T16MSK3 = {11..15}; T16MSK4 = {12..15};
      T16MSK5 = {13..15};
      
      (*T16MSK2 010001: Special data instructions and branch and exchange on page A5-132*)
      SpecDataBrEx = {14, 10};
      (*T16MSK2 010000 Data processing on page A5-131*)
      DataProc = {14};
      
      (*T16MSK4 1011xx: Miscellaneous 16-bit instructions on page A5-134*)
      Misc16bInst = {15, 12..13};
      (*T16MSK4 1101xx Conditional branch, and Supervisor Call on page A5-136*)
      CondBrAndSVC = {14..15, 12};
      
      (*T16MSK1 00xxxx: Shift (immediate), add, subtract, move, and compare on page A5-130*)
      ShAdSuMoCm = {};
      
      T16MSK21 = {8..9}; T16MSK22 = {6..9}; T16MSK23 = {7..9};
      
      (*T16MSK22 1010 Compare Registers CMP (register) on page A7-224*)
      CmpReg = {9, 7};
      
      (*T16MSK23 110x: Branch and Exchange BX on page A7-215*)
      BrEx = {8..9};
      (*T16MSK23 111x: Branch with Link and Exchange BLX (register) on page A7-214*)
      BrLEx = {7..9};
      
      T16MSK41 = {5..11}; T16MSK42 = {7..11}; T16MSK43 = {8..11}; T16MSK44 = {6..11};
      T16MSK45 = {9..11};
      
      (*T16MSK43 1111xxx: If-Then, and hints on page A5-135*)
      IfThenHints = {8..11};
      (*T16MSK45 010xxxx: Push Multiple Registers PUSH on page A7-322*)
      PushMultRegs = {10};
      
      T16MSK11 = {11..13}; T16MSK12 = {9..13};
      
      (*T16MSK11 101xx: Compare CMP (immediate) on page A7-223*)
      CmpImm = {13, 11};
      (*T16MSK11 100xx: Move MOV (immediate) on page A7-291*)
      Move = {13};
      (*T16MSK11 110xx: Add 8-bit immediate ADD (immediate) on page A7-190*)
      AddImm8 = {13, 12};
      (*T16MSK11 010xx Arithmetic Shift Right ASR (immediate) on page A7-203*)
      ASRImmT1 = {12};

      (*T16MSK12 01110 Add 3-bit immediate ADD (immediate) on page A7-190*)
      AddImm3 = {10..12};
      
    VAR b1, b2, b3, b4, t, Rn, Rd, Rt, Rm, Sn, Sd, Sm, mno, ext, exop, proc: BYTE;
      op: SET;
  BEGIN
    ext := er.ext[i];
    b1 := c.code[i+1]; b2 := c.code[i]; INC(i, 2);
    IF ext = 0 THEN
      t := b1 DIV OM4A.C3; 
      IF t >= 01DH THEN (*32-bit instruction*)
        b3 := c.code[i+1]; b4 := c.code[i]; INC(i, 2);
        op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
        Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
        IF op*T32MSK4 = DataProcModImm THEN
          (* T32MSK4 10 x0xxxxx 0: Data processing (modified immediate) on page A5-138*)
          Rn := b2 MOD OM4A.C4; Rd := b3 MOD OM4A.C4;
          IF op*T32MSK41 = SubCmpModImm THEN
            IF Rd = 15 THEN WriteOp(op, "CMP", FALSE, FALSE)
            ELSE WriteOp(op, "SUB", FALSE, TRUE); WriteReg(Rd)
            END;
            WriteReg(Rn); Texts.WriteString(W, " #"); 
            Texts.WriteInt(W, ThumbExpandImm(op), 1)
          ELSIF op*T32MSK41 = AddCmnModImm THEN
            IF Rd = 15 THEN WriteOp(op, "CMN", FALSE, FALSE)
            ELSE WriteOp(op, "ADD", FALSE, TRUE); WriteReg(Rd)
            END;
            WriteReg(Rn); Texts.WriteString(W, " #");
            Texts.WriteInt(W, ThumbExpandImm(op), 1)
          ELSIF op*T32MSK41 = AndTstModImm THEN
            (*T32MSK41 0000x AND (immediate) on page A7-200 or TST (immediate) on page A7-419*)
            IF Rd = 15 THEN WriteOp(op, "TST", FALSE, FALSE)
            ELSE WriteOp(op, "AND", FALSE, TRUE); WriteReg(Rd)
            END;
            WriteReg(Rn); Texts.WriteString(W, " #"); 
            Texts.WriteInt(W, ThumbExpandImm(op), 1)
          ELSE Texts.WriteString(W, "TODO: not AddCmnModImm")
          END
        ELSIF op*T32MSK4 = DataProcPlainBinImm THEN
          (*T32MSK4 10 x1xxxxx 0: Data processing (plain binary immediate) on page A5-141*)
          Rn := b2 MOD OM4A.C4;
          Rd := b3 MOD OM4A.C4;
          IF op*T32MSK42 = MW16Bit THEN
            (*T32MSK42 00100 -: Move Wide, 16-bit MOV (immediate) on page A7-291*)
            WriteOp(op, "MOV", FALSE, FALSE); WriteReg(Rd); Texts.WriteString(W, " #");
            Texts.WriteInt(W, imm16(b1, b2, b3, b4), 6)
          ELSIF op*T32MSK42 = MoveTop THEN
            (*T32MSK42 01100 -: Move Top, 16-bit MOVT on page A7-296*)
            WriteOp(op, "MOVT", FALSE, FALSE); WriteReg(Rd); Texts.WriteString(W, " #");
            Texts.WriteInt(W, imm16(b1, b2, b3, b4), 6)
          ELSE Texts.WriteString(W, "TODO: not MW16Bit")
          END
        ELSIF op*T32MSK6 = StrSingleDataItem THEN
          (*T32MSK6 11 000xxx0 x: Store single data item on page A5-149*)
          Rn := b2 MOD OM4A.C4; Rt := b3 DIV OM4A.C4;
          IF op*T32MSK61 = StrRegImmT3 THEN
            (*T32MSK61 110 xxxxxx: Store Register STR (immediate) on page A7-386*)
            (*STR<c>.W <Rt>,[<Rn>,#<imm12>]*)
            WriteOp(op, "STR", FALSE, FALSE); WriteReg(Rt); Texts.WriteString(W, " ["); WriteReg(Rn);
            Texts.WriteString(W, " + "); Texts.WriteInt(W, ORD(op) MOD OM4A.C12, 1); Texts.WriteString(W, " ]")
          ELSIF op*T32MSK61 = StrRegByteImmT2 THEN
            (*T32MSK61 100 xxxxxx Store Register Byte STRB (immediate) on page A7-389*)
            (*STRB<c>.W <Rt>,[<Rn>,#<imm12>]*)
            WriteOp(op, "STRB", FALSE, FALSE);  WriteReg(Rt); Texts.WriteString(W, " ["); WriteReg(Rn);
            Texts.WriteString(W, " + "); Texts.WriteInt(W, ORD(op) MOD OM4A.C12, 1); Texts.WriteString(W, " ]")
          ELSIF op*T32MSK62 = StrRegImmT4 THEN
            (*T32MSK62 010 1xxxxx Store Register STR (immediate) on page A7-386*)
            (*STR<c> <Rt>,[<Rn>,#-<imm8>]
              STR<c> <Rt>,[<Rn>],#+/-<imm8>
              STR<c> <Rt>,[<Rn>,#+/-<imm8>]!*)
            WriteOp(op, "STR", FALSE, FALSE); WriteReg(Rt); Texts.WriteString(W, " ["); WriteReg(Rn);
            IF ~(10 IN op) THEN (*post-indexed*) Texts.WriteString(W, " ] ") END;
            IF 9 IN op THEN (*add*) Texts.WriteString(W, "+ ") ELSE Texts.WriteString(W, "- ") END;
            Texts.WriteInt(W, b4, 1);
            IF 10 IN op THEN (*pre-indexed*) Texts.WriteString(W, " ]");
              IF 8 IN op THEN (*write-back*) Texts.Write(W, "!") END
            END
          ELSE Texts.WriteString(W, "TODO: not StrRegImmT4")
          END
        ELSIF op*T32MSK7 = LdrWord THEN
          (*T32MSK7 11 00xx101 x Load word on page A5-146*)
          Rn := b2 MOD OM4A.C4; Rt := b3 DIV OM4A.C4;
          IF (op*T32MSK71 = LdrRegImmOrLit) & (Rn # 15) THEN
            (*T32MSK71 01 xxxxxx: Rn # 1111: Load Register LDR (immediate) on page A7-246*)
            (*LDR<c>.W <Rt>,[<Rn>{,#<imm12>}] T3*)
            WriteOp(op, "LDR", FALSE, FALSE); WriteReg(Rt); Texts.WriteString(W, " ["); WriteReg(Rn);
            Texts.WriteString(W, " + "); Texts.WriteInt(W, ORD(op) MOD OM4A.C12, 1); Texts.WriteString(W, " ]")
          ELSIF (op*T32MSK72 = LdrREgImmOrLit2)  & (Rn # 15) THEN
            (*T32MSK72 00 1xx1xx not 1111 LDR (immediate) on page A7-246*)
            (*LDR<c> <Rt>,[<Rn>,#-<imm8>]
              LDR<c> <Rt>,[<Rn>],#+/-<imm8>
              LDR<c> <Rt>,[<Rn>,#+/-<imm8>]! T4*)
            WriteOp(op, "LDR", FALSE, FALSE); WriteReg(Rt); Texts.WriteString(W, " ["); WriteReg(Rn);
            IF ~(10 IN op) THEN (*post-indexed*) Texts.WriteString(W, " ] ") END;
            IF 9 IN op THEN (*add*) Texts.WriteString(W, "+ ") ELSE Texts.WriteString(W, "- ") END;
            Texts.WriteInt(W, b4, 1);
            IF 10 IN op THEN (*pre-indexed*) Texts.WriteString(W, " ]");
              IF 8 IN op THEN (*write-back*) Texts.Write(W, "!") END
            END
          ELSE Texts.WriteString(W, "TODO: not LdrREgImmOrLit2")
          END
        ELSIF op*T32MSK5 = BrMiscCtrl THEN
          IF op*T32MSK51 = BrWithLnk THEN
            (*T32MSK51 1x1 xxxxxxx: Branch with Link BL on page A7-213*)
            (*BL<c> <label> Outside or last in IT block*)
            WriteOp(op, "BL", FALSE, FALSE); Texts.WriteString(W, " #"); Texts.WriteInt(W, SignExtendEven25(op), 1);
          ELSIF op*T32MSK52 = MovFrSpReg THEN
            (*T32MSK52 0x0 011111x: Move from Special Register MRS on page A7-300*)
            (*MRS<c> <Rd>,<spec_reg>*)
            Rd := b3 MOD OM4A.C4;
            WriteOp(op, "MRS", FALSE, FALSE); WriteReg(Rd);
            IF b4 = 8 THEN Texts.WriteString(W, " MSP")
            ELSIF b4 = 9 THEN Texts.WriteString(W, " PSP")
            ELSE Texts.WriteString(W, "TODO SYSm="); Texts.WriteInt(W, b4, 1)
            END
          ELSE Texts.WriteString(W, "TODO: not MovFrSpReg")
          END
        ELSIF op*T32MSK3 = CoProc THEN
          (*T32MSK3 01 1xxxxxx x: Coprocessor instructions on page A5-158*)
          (*1110/11xx/xxxx/xxxx/xxxx/xxxx/xxxx/xxxx*)
          IF op*T32MSK31 = Trap THEN
            (*T32MSK31 0: Oberon implementation for Trap*)
            WriteOp(op, "Trap", FALSE, FALSE); Texts.Write(W, " "); Texts.WriteInt(W, b4 MOD OM4A.C4, 2);
            Texts.WriteString(W, " at pos "); 
            Texts.WriteInt(W, 0+b1 MOD OM4A.C1*OM4A.C19 + b2*OM4A.C11 + b3 DIV OM4A.C4*OM4A.C7 +
              b3 MOD OM4A.C3*OM4A.C4 + b4 DIV OM4A.C4, 7);
          ELSIF op*T32MSK32 = FPSingle THEN
            (*T32MSK32 1010: Single-precision floating point coprocessor*)
            (*1110/11xx/xxxx/xxxx/xxxx/1010/xxxx/xxxx*)
            IF op*T32MSK321 = VMOVSR THEN
              (*T32MSK321 A7.7.243 VMOV (between Arm core register and single-precision register)*)
              (*VMOV<c> <Sn>, <Rt> 1110/1110/000o/ Vn / Rt /1010/N--1/----*)
              Sn := b2 MOD OM4A.C4*OM4A.C1 + b4 DIV OM4A.C7;
              Rt := b3 DIV OM4A.C4;
              WriteOp(op, "VMOV", FALSE, FALSE); Texts.WriteString(W, " S"); Texts.WriteInt(W, Sn, 1);
              Texts.Write(W, " "); WriteReg(Rt)
            ELSIF op*T32MSK322 = VSTR THEN
              (*T32MSK322 A7.7.259 VSTR*)
              (*VSTR<c> <Sd>, [<Rn>{, #+/-<imm>}] 1110/1101/UD00/ Rn / Vd /1010/ imm/8   *)
              Sd := b3 DIV OM4A.C4*OM4A.C1 + b2 DIV OM4A.C6 MOD OM4A.C1;
              Rn := b2 MOD OM4A.C4;
              WriteOp(op, "VSTR", FALSE, FALSE); Texts.WriteString(W, " S"); Texts.WriteInt(W, Sd, 1);
              Texts.WriteString(W, " ["); WriteReg(Rn);
              IF 23 IN op THEN Texts.WriteString(W, " + ") ELSE  Texts.WriteString(W, " - ") END;
              Texts.WriteInt(W, b4*OM4A.C2, 1); Texts.WriteString(W, " ]")
            ELSIF op*T32MSK322 = VLDR THEN
              (*T32MSK322 1xx01 - FP Load Register VLDR on page A7-473*)
              (*VLDR<c> <Sd>, [<Rn>{, #+/-<imm>}]*)
              Sd := b3 DIV OM4A.C4*OM4A.C1 + b2 DIV OM4A.C6 MOD OM4A.C1;
              Rn := b2 MOD OM4A.C4;
              WriteOp(op, "VLDR", FALSE, FALSE); Texts.WriteString(W, " S"); Texts.WriteInt(W, Sd, 1);
              Texts.WriteString(W, " ["); WriteReg(Rn);
              IF 23 IN op THEN Texts.WriteString(W, " + ") ELSE  Texts.WriteString(W, " - " ) END;
              Texts.WriteInt(W, b4*OM4A.C2, 1); Texts.WriteString(W, " ]")
            ELSIF op*T32MSK323 = VADD THEN
              (*T32MSK323 0 0x11 - x0 FP Add VADD on page A7-456*)
              (*VADD{<c>}{<q>}.F32 {<Sd>,} <Sn>, <Sm>*)
              Sd := b3 DIV OM4A.C4*OM4A.C1 + b2 DIV OM4A.C6 MOD OM4A.C1;
              Sn := b2 MOD OM4A.C4*OM4A.C1 + b4 DIV OM4A.C7;
              Sm := b4 MOD OM4A.C4*OM4A.C1 + b4 DIV OM4A.C5 MOD OM4A.C1;
              WriteOp(op, "VADD", FALSE, FALSE); Texts.WriteString(W, " S"); Texts.WriteInt(W, Sd, 1);
              Texts.WriteString(W, " S"); Texts.WriteInt(W, Sn, 1); Texts.WriteString(W, " S"); Texts.WriteInt(W, Sm, 1)
            ELSE Texts.WriteString(W, "TODO: not VADD")
            END
          ELSE Texts.WriteString(W, "TODO: not FPSingle")
          END
        ELSE Texts.WriteString(W, "TODO 32-bit thumb instruction")
        END
      ELSE op := SYSTEM.VAL(SET, 0+b2+100H*b1);
        Texts.WriteString(W, "    "); WriteHexVLen(W, ORD(op), 4, FALSE); Texts.Write(W, 9X);
        IF op*T16MSK2 = SpecDataBrEx THEN
          (*T16MSK2 010001: Special data instructions and branch and exchange on page A5-132*)
          Rm := b2 DIV OM4A.C3 MOD OM4A.C4;
          IF op*T16MSK23 = BrEx THEN
            (*T16MSK23 110x: Branch and Exchange BX on page A7-215*)
            WriteOp(op, "BX", FALSE, FALSE); WriteReg(Rm)
          ELSIF op*T16MSK23 = BrLEx THEN
            (*T16MSK23 111x: Branch with Link and Exchange BLX (register) on page A7-214*)
            WriteOp(op, "BLX", FALSE, FALSE); WriteReg(Rm)
          ELSE Texts.WriteString(W, "TODO: not BrLEx")
          END
        ELSIF op*T16MSK2 = DataProc THEN
          (*T16MSK2 010000 Data processing on page A5-131*)
          IF op*T16MSK22 = CmpReg THEN
            (*T16MSK22 1010 Compare Registers CMP (register) on page A7-224*)
            (*CMP<c> <Rn>,<Rm>*)
            Rn := b2 MOD OM4A.C3;
            Rm := b2 DIV OM4A.C3 MOD OM4A.C3;
            WriteOp(op, "CMP", FALSE, FALSE); WriteReg(Rn); WriteReg(Rm)
          ELSE Texts.WriteString(W, "TODO: not CmpReg")
          END
        ELSIF op*T16MSK4 = Misc16bInst THEN
          (*T16MSK4 1011xx: Miscellaneous 16-bit instructions on page A5-134*)
          IF op*T16MSK43 = IfThenHints THEN
            (*T16MSK43 1111xxx: If-Then, and hints on page A5-135*)
            IF b2 MOD OM4A.C4 # 0 THEN
              (*xxxx not 0000 If-Then IT on page A7-236*)
              Texts.WriteString(W, "IT");
              b3 := b2 DIV OM4A.C4; (*condition*)
              t := 3; WHILE ~ODD(b2) DO b2 := ASR(b2, 1); DEC(t) END;
              itB.cond := b3; itB.pos := 0; itB.nofinst := 1; itB.mask[0] := "T";
              FOR b4 := t TO 1 BY -1 DO 
                IF ASR(b2, b4) MOD OM4A.C1 = b3 MOD OM4A.C1 THEN 
                  Texts.WriteString(W, "T"); itB.mask[itB.nofinst] := "T"
                ELSE Texts.WriteString(W, "E"); itB.mask[itB.nofinst] := "E"
                END;
                INC(itB.nofinst)
              END;
              itB.mask[itB.nofinst] := 0X;
              Texts.WriteString(W, " "); Texts.WriteString(W, mnemo1[b3]);
            ELSE Texts.WriteString(W, "TODO: not If-Then")
            END
          ELSIF op*T16MSK45 = PushMultRegs THEN
            (*T16MSK45 010xxxx: Push Multiple Registers PUSH on page A7-322*)
            (*PUSH<c> <registers>*)
            WriteOp(op, "PUSH", FALSE, FALSE);
            FOR t := 0 TO 7 DO IF t IN op THEN WriteReg(t) END
            END;
            IF 8 IN op THEN WriteReg(14) END
          ELSE Texts.WriteString(W, "TODO: not IfThenHints")
          END
        ELSIF op*T16MSK1 = ShAdSuMoCm THEN
          (*T16MSK1 00xxxx: Shift (immediate), add, subtract, move, and compare on page A5-130*)
          IF op*T16MSK11 = CmpImm THEN
            (*T16MSK11 101xx: Compare CMP (immediate) on page A7-223*)
            (*CMP<c> <Rn>,#<imm8>*)
            Rn := b1 MOD OM4A.C3;
            WriteOp(op, "CMP", FALSE, FALSE); WriteReg(Rn); Texts.WriteString(W, " #");
            Texts.WriteInt(W, b2, 1)
          ELSIF op*T16MSK11 = Move THEN
            (*T16MSK11 100xx: Move MOV (immediate) on page A7-291*)
            (*MOVS <Rd>,#<imm8>   Outside IT block.
              MOV<c> <Rd>,#<imm8> Inside IT block.*)
            Rn := b1 MOD OM4A.C3;
            WriteOp(op, "MOV", TRUE, FALSE); WriteReg(Rn); Texts.WriteString(W, " #");
            Texts.WriteInt(W, b2, 1)
          ELSIF op*T16MSK11 = AddImm8 THEN
            (*T16MSK11 110xx: Add 8-bit immediate ADD (immediate) on page A7-190*)
            (*ADDS <Rdn>,#<imm8> Outside IT block.
              ADD<c> <Rdn>,#<imm8> Inside IT block.*)
            Rn := b1 MOD OM4A.C3;
            WriteOp(op, "ADD", TRUE, FALSE); WriteReg(Rn); Texts.WriteString(W, " #");
            Texts.WriteInt(W, b2, 1)
          ELSIF op*T16MSK12 = AddImm3 THEN
            (*T16MSK12 01110 Add 3-bit immediate ADD (immediate) on page A7-190*)
            (*ADDS <Rd>,<Rn>,#<imm3> Outside IT block.
              ADD<c> <Rd>,<Rn>,#<imm3> Inside IT block.*)
            Rn := b2 DIV OM4A.C3 MOD OM4A.C3;
            Rd := b2 MOD OM4A.C3;
            WriteOp(op, "ADD", TRUE, FALSE); WriteReg(Rd); WriteReg(Rn); Texts.WriteString(W, " #");
            Texts.WriteInt(W, b1 MOD OM4A.C1*OM4A.C2 + b2 DIV OM4A.C6, 1)
          ELSIF op*T16MSK11 = ASRImmT1 THEN
            (*T16MSK11 010xx Arithmetic Shift Right ASR (immediate) on page A7-203*)
            (*ASRS <Rd>,<Rm>,#<imm5> Outside IT block.
              ASR<c> <Rd>,<Rm>,#<imm5> Inside IT block.*)
            Rm := b2 DIV OM4A.C3 MOD OM4A.C3;
            Rd := b2 MOD OM4A.C3;            
            WriteOp(op, "ASR", TRUE, FALSE); WriteReg(Rd); WriteReg(Rm); Texts.WriteString(W, " #");
            Texts.WriteInt(W, b1 MOD OM4A.C3*OM4A.C2 + b2 DIV OM4A.C6, 1)
          ELSE Texts.WriteString(W, "TODO: not ASRImmT1")
          END
        ELSIF op*T16MSK4 = CondBrAndSVC THEN
          (*T16MSK4 1101xx Conditional branch, and Supervisor Call on page A5-136*)
          IF b1 MOD OM4A.C4 = 0EH THEN Texts.WriteString(W, "TODO UDF on page A7-425")
          ELSIF b1 MOD OM4A.C4 = 0FH THEN Texts.WriteString(W, "TODO SVC on page A7-409")
          ELSE
            (*B<c> <label> Not permitted in IT block.*)
            WriteOp(op, "B", FALSE, FALSE); Texts.Write(W, " ");
            Texts.WriteString(W, mnemo1[b1 MOD OM4A.C4]);
            Texts.WriteString(W, " #"); Texts.WriteInt(W, SignExtendEven8(b2), 1)
          END
        ELSE Texts.WriteString(W, "TODO 16-bit thumb instruction")
        END
      END
    ELSIF ext = 1 THEN (*Get static base*)
      b3 := c.code[i+1]; b4 := c.code[i]; INC(i, 2);
      op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
      Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
      Rd := b1 DIV OM4A.C4; mno := b1 MOD OM4A.C4;
      WriteOp(op, "LDR", FALSE, FALSE); WriteReg(Rd); Texts.WriteString(W, " [ MT + Base(");
      Texts.WriteInt(W, mno, 1); Texts.WriteString(W, ") ]")
    ELSIF ext = 2 THEN (*LDR/STR/ADD relative to static base/VLDR/VSTR*)
      b3 := c.code[i+1]; b4 := c.code[i]; INC(i, 2);
      op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
      Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
      exop := b1 DIV OM4A.C4;
      Rd := b1 MOD OM4A.C4; Rn := b2 DIV OM4A.C4;
      WriteOp(op, mnemo0[exop], FALSE, FALSE);
      IF exop < OM4A.EXTVLDR THEN WriteReg(Rd)
      ELSE (* EXTVLDR or EXTVSTR*) Texts.WriteString(W, " S");
        Texts.WriteInt(W, Rd, 1)
      END;
      Texts.WriteString(W, " ["); WriteReg(Rn);
      Texts.WriteString(W, " + Var("); Texts.WriteInt(W, b4, 1);
      Texts.WriteString(W, ") ]");
      IF ODD(b3) THEN Texts.WriteString(W, " Prog based") END
    ELSIF ext = 3 THEN (*BL Call external procedure*)
      b3 := c.code[i+1]; b4 := c.code[i]; INC(i, 2);
      op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
      Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
      mno := b1 DIV OM4A.C4; proc := b1 MOD OM4A.C4*OM4A.C4 + b2 DIV OM4A.C4;
      WriteOp(op, "BL", FALSE, FALSE); Texts.WriteString(W, " Mod("); Texts.WriteInt(W, mno, 3);
      Texts.WriteString(W, ") proc("); Texts.WriteInt(W, proc, 1);
      Texts.WriteString(W, ")")
    ELSE Texts.WriteString(W, "TODO: External reference");
      INC(i, 2)
    END
  END opcode;

  PROCEDURE Sync(VAR R: Files.Rider);
    VAR ch: CHAR;
  BEGIN Files.Read(R, ch); Texts.WriteString(W, "Sync "); Texts.Write(W, ch); Texts.WriteLn(W)
  END Sync;
  
  PROCEDURE Write(VAR R: Files.Rider; x: INTEGER);
  BEGIN Files.WriteByte(R, x)  (* -128 <= x < 128 *)
  END Write;

  PROCEDURE DecObj*;   (*decode object file*)
    VAR class, i, n, key, size, fix, adr, data, len: INTEGER;
      bl, bh, mno: BYTE;
      next: INTEGER;
      ch: CHAR;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
      mcode: OM4A.ModuleCode;
      eref: ExternalRefMap;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "decode "); Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN
        NEW(mcode); NEW(eref);
        Files.Set(R, F, 0); Files.ReadString(R, name); Texts.WriteLn(W); Texts.WriteString(W, name);
        Files.ReadInt(R, key); Texts.WriteHex(W, key); Read(R, class); Texts.WriteInt(W, class, 4); (*version*)
        Files.ReadInt(R, size); Texts.WriteInt(W, size, 6); Texts.WriteLn(W);
        Texts.WriteString(W, "imports:"); Texts.WriteLn(W); Files.ReadString(R, name);
        WHILE name[0] # 0X DO
          Texts.Write(W, 9X); Texts.WriteString(W, name);
          Files.ReadInt(R, key); Texts.WriteHex(W, key); Texts.WriteLn(W);
          Files.ReadString(R, name)
        END ;
      (* Sync(R); *)
        Texts.WriteString(W, "type descriptors"); Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        Files.ReadInt(R, n); n := n DIV 4; i := 0;
        WHILE i < n DO Files.ReadInt(R, data); Texts.WriteHex(W, data); INC(i) END ;
        Texts.WriteLn(W);
        Texts.WriteString(W, "data"); Files.ReadInt(R, data); Texts.WriteInt(W, data, 6); Texts.WriteLn(W);
        Texts.WriteString(W, "strings"); Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        Files.ReadInt(R, n); i := 0;
        WHILE i < n DO Files.Read(R, ch); Texts.Write(W, ch); INC(i) END ;
        Texts.WriteLn(W);
        Texts.WriteString(W, "code"); Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        Files.ReadInt(R, mcode.pc); i := 0;
        WHILE i < mcode.pc DO Files.ReadByte(R, mcode.code[i]); eref.ext[i] := 0; INC(i)
        END;
      (* Sync(R); *)
        Texts.WriteString(W, "commands:"); Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        Files.ReadString(R, name);
        WHILE name[0] # 0X DO
          Texts.Write(W, 9X); Texts.WriteString(W, name);
          Files.ReadInt(R, adr); Texts.WriteInt(W, adr, 5); Texts.WriteLn(W);
          Files.ReadString(R, name)
        END ;
      (* Sync(R); *)
        Texts.WriteString(W, "entries"); Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        Files.ReadInt(R, n); i := 0;
        WHILE i < n DO
          Files.ReadInt(R, adr); Texts.WriteInt(W, adr, 6); INC(i)
        END ;
        Texts.WriteLn(W);
      (* Sync(R); *)
        Texts.WriteString(W, "pointer refs"); Texts.WriteLn(W); Files.ReadInt(R, adr);
        Texts.Append(Oberon.Log, W.buf);
        WHILE adr # -1 DO Texts.WriteInt(W, adr, 6); Files.ReadInt(R, adr) END ;
        Texts.WriteLn(W);
      (* Sync(R); *)
        Files.ReadInt(R, data); Texts.WriteString(W, "fixP = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        WHILE data # 0 DO eref.ext[data] := 3;
          next := data-(mcode.code[data+2] + 100H*(mcode.code[data+3] + 100H*(mcode.code[data] MOD OM4A.C4)))*OM4A.C1;
          data := next
        END;
        Files.ReadInt(R, data); Texts.WriteString(W, "fixD = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        WHILE data # 0 DO eref.ext[data] := 1; mno := mcode.code[data+1] MOD OM4A.C4;
          IF mno # 0 THEN eref.ext[data+4] := 2 END; 
          next := data-(mcode.code[data+2] + 100H*(mcode.code[data+3] + 100H*mcode.code[data]))*OM4A.C1;
          data := next
        END;
        Files.ReadInt(R, data); Texts.WriteString(W, "fixT = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        Files.ReadInt(R, data); Texts.WriteString(W, "entry = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        Files.Read(R, ch);
        Texts.Append(Oberon.Log, W.buf);
        IF ch # "O" THEN Texts.WriteString(W, "format error"); Texts.WriteLn(W) END;
      (* Sync(R); *)
        (* TODO Locate external references *)
        i := 0;
        WHILE i < mcode.pc DO
          Texts.WriteInt(W, i, 4); Texts.Write(W, 9X); 
          opcode(mcode, eref, i); Texts.WriteLn(W)
        END
      ELSE Texts.WriteString(W, " not found"); Texts.WriteLn(W)
      END ;
      Texts.Append(Oberon.Log, W.buf)
    END
  END DecObj;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OM4Tool 12.11.2023");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
  itB.pos := 0; itB.nofinst := 0;
  mnemo0[0] := "LDR";  mnemo0[1] := "LDRB";  mnemo0[2] := "STR";
  mnemo0[3] := "STRB"; mnemo0[4] := "ADD";   mnemo0[5] := "ADDB";
  mnemo0[6] := "VLDR"; mnemo0[7] := "VSTR";
  
  mnemo1[OM4A.MI] := "MI"; mnemo1[OM4A.PL] := "PL"; mnemo1[OM4A.EQ] := "EQ"; mnemo1[OM4A.NE] := "NE";
  mnemo1[OM4A.LT] := "LT"; mnemo1[OM4A.GE] := "GE"; mnemo1[OM4A.LE] := "LE"; mnemo1[OM4A.GT] := "GT";
  mnemo1[OM4A.CC] := "CC"; mnemo1[OM4A.AL] := "AL"; mnemo1[OM4A.NV] := "NV"
END OM4Tool.
