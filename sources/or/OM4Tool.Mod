MODULE OM4Tool;  (*NW 18.2.2013
  C. Schoffit 12/11/2023*)
  IMPORT SYSTEM, Files, Texts, Oberon, OM4B, OM4A;

  TYPE
    ExternalRefMap = POINTER TO ExternalRefMapDesc;
    ExternalRefMapDesc = RECORD
      ext: ARRAY OM4A.maxCode OF BYTE
    END;
  
  VAR W: Texts.Writer;
    Form: INTEGER;  (*result of ReadType*)
    mnemo0: ARRAY 8, 5 OF CHAR;  (*mnemonics*)
  
  PROCEDURE WriteHexVLen (VAR W: Texts.Writer; x, n: LONGINT);
    VAR i: INTEGER; y: LONGINT;
      a: ARRAY 10 OF CHAR;
  BEGIN i := 0; Texts.Write(W, " ");
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END;
      x := x DIV 10H; INC(i)
    UNTIL (i >= n) & (x = 0);
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
    IF r < 12 THEN Texts.WriteString(W, " R"); Texts.WriteInt(W, r MOD 10H, 1)
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
  
  PROCEDURE opcode(VAR c: OM4A.ModuleCode; VAR er: ExternalRefMap; VAR i: LONGINT);
    CONST
      (*32-bit instructions*)
      SCMSK1 = {25..28, 22}; SCMSK2 = {25..28}; SCMSK3 = {26..28};
      SCMSK4 = {25, 27..28, 15}; SCMSK5 = {27..28, 15}; SCMSK6 = {24..28, 20};
      SCMSK7 = {25..28, 20..22};
      
      (*SCMSK4 10 x0xxxxx 0: Data processing (modified immediate) on page A5-138*)
      DataProcModImm = {28};
      (*SCMSK4 10 x1xxxxx 0: Data processing (plain binary immediate) on page A5-141*)
      DataProcPlainBinImm = {28, 25};

      (*SCMSK6 11 000xxx0 x: Store single data item on page A5-149*)
      StrSingleDataItem = {27..28};

      (*SCMSK7 11 00xx101 x Load word on page A5-146*)
      LdrWord = {27..28, 22, 20};

      SCMSK41 = {21..24};      
      (*SCMSK41 1101x SUB (immediate) on page A7-402 or CMP (immediate) on page A7-223*)
      SubCmpModImm = {24, 23, 21};
      (*SCMSK41 1000x ADD (immediate) on page A7-190 or CMN (immediate) on page A7-221*)
      AddCmnModImm = {24};
      
      SCMSK61 = {21..23};
      SCMSK62 = {21..23, 11};
      (*SCMSK61 010 1xxxxx: Store Register STR (immediate) on page A7-386*)
      StrRegImmT3 = {22..23};
      StrRegImmT4 = {22, 11};
      
      SCMSK71 = {23..24};
      (*01 xxxxxx: Rn # 1111: Load Register LDR (immediate) on page A7-246*)
      (*0x xxxxxx: Rn = 1111: Load Register LDR (literal) on page A7-248*)
      LdrRegImmOrLit = {23};

      (*16-bit instructions*)
      T16MSK1 = {14..15}; T16MSK2 = {10..15}; T16MSK3 = {11..15}; T16MSK4 = {12..15};
      T16MSK5 = {13..15};
      
      (*T16MSK2 010001: Special data instructions and branch and exchange on page A5-132*)
      SpecDataBrEx = {14, 10};
      
      T16MSK21 = {8..9}; T16MSK22 = {6..9}; T16MSK23 = {7..9};
      
      (*T16MSK23 110x: Branch and Exchange BX on page A7-215*)
      BrEx = {8..9};
      
    VAR b1, b2, b3, b4, t, Rn, Rd, Rt, Rm, mno, ext, exop: BYTE;
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
        IF op*SCMSK4 = DataProcModImm THEN
          (* SCMSK4 10 x0xxxxx 0: Data processing (modified immediate) on page A5-138*)
          Rn := b2 MOD OM4A.C4; Rd := b3 MOD OM4A.C4;
          IF op*SCMSK41 = SubCmpModImm THEN
            IF Rd = 15 THEN Texts.WriteString(W, "CMP") ELSE Texts.WriteString(W, "SUB")
            END;
            WriteReg(Rd); WriteReg(Rn); Texts.WriteString(W, " #"); 
            WriteHexVLen(W, ThumbExpandImm(op), 2); Texts.Write(W, "H")
          ELSIF op*SCMSK41 = AddCmnModImm THEN
            IF Rd = 15 THEN Texts.WriteString(W, "CMN") ELSE Texts.WriteString(W, "ADD")
            END;
            WriteReg(Rd); WriteReg(Rn); Texts.WriteString(W, " #"); 
            WriteHexVLen(W, ThumbExpandImm(op), 2); Texts.Write(W, "H")
          ELSE Texts.WriteString(W, "TODO: not AddCmnModImm")
          END
        ELSIF op*SCMSK4 = DataProcPlainBinImm THEN
          (*SCMSK4 10 x1xxxxx 0: Data processing (plain binary immediate) on page A5-141*)
          Texts.WriteString(W, "TODO: DataProcPlainBinImm")
        ELSIF op*SCMSK6 = StrSingleDataItem THEN
          (*SCMSK6 11 000xxx0 x: Store single data item on page A5-149*)
          IF op*SCMSK61 = StrRegImmT3 THEN
          (*SCMSK61 110 1xxxxx: Store Register STR (immediate) on page A7-386*)
          (*STR<c>.W <Rt>,[<Rn>,#<imm12>]*)
            Rn := b2 MOD OM4A.C4; Rt := b3 DIV OM4A.C4;
            Texts.WriteString(W, "STR"); WriteReg(Rt); Texts.WriteString(W, " ["); WriteReg(Rn);
            Texts.WriteString(W, " #"); WriteHexVLen(W, ORD(op) MOD OM4A.C12, 2);
            Texts.WriteString(W, "H]")
          ELSE Texts.WriteString(W, "TODO: not StrRegImmT3")
          END
        ELSIF op*SCMSK7 = LdrWord THEN
          (*SCMSK7 11 00xx101 x Load word on page A5-146*)
          Rn := b2 MOD OM4A.C4;
          IF (op*SCMSK71 = LdrRegImmOrLit) & (Rn # 15) THEN
            (*01 xxxxxx: Rn # 1111: Load Register LDR (immediate) on page A7-246*)
            (*LDR<c>.W <Rt>,[<Rn>{,#<imm12>}]*)
            Rt := b3 DIV OM4A.C4;
            Texts.WriteString(W, "LDR"); WriteReg(Rt); Texts.WriteString(W, " ["); WriteReg(Rn);
            Texts.WriteString(W, " #"); WriteHexVLen(W, ORD(op) MOD OM4A.C12, 2);
            Texts.WriteString(W, "H]")
          ELSE Texts.WriteString(W, "TODO: not LdrRegImmOrLit")
          END
        ELSE Texts.WriteString(W, "???")
        END
      ELSE op := SYSTEM.VAL(SET, 0+b2+100H*b1);
        WriteHexVLen(W, ORD(op), 4); Texts.Write(W, 9X);
        IF op*T16MSK2 = SpecDataBrEx THEN
          (*T16MSK2 010001: Special data instructions and branch and exchange on page A5-132*)
          IF op*T16MSK23 = BrEx THEN
            (*T16MSK23 110x: Branch and Exchange BX on page A7-215*)
            Rm := b2 DIV OM4A.C3;
            Texts.WriteString(W, "BX"); WriteReg(Rm)
          ELSE Texts.WriteString(W, "TODO: not BrEx")
          END
        ELSE Texts.WriteString(W, "TODO 16-bit thumb instruction")
        END
      END
    ELSIF ext = 1 THEN (*Get static base*)
      b3 := c.code[i+1]; b4 := c.code[i]; INC(i, 2);
      op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
      Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
      Rd := b1 DIV OM4A.C4; mno := b1 MOD OM4A.C4;
      Texts.WriteString(W, "LDR"); WriteReg(Rd); Texts.WriteString(W, " = Base[");
      Texts.WriteInt(W, mno, 3); Texts.WriteString(W, "]");
    ELSIF ext = 2 THEN (*LDR/STR/ADD relative to static base*)
      b3 := c.code[i+1]; b4 := c.code[i]; INC(i, 2);
      op := SYSTEM.VAL(SET, 0+b4+100H*(b3+100H*(b2+100H*b1)));
      Texts.WriteHex(W, ORD(op)); Texts.Write(W, 9X);
      exop := b1 DIV OM4A.C4;
      IF exop < OM4A.EXTVLDR THEN
        Rd := b1 MOD OM4A.C4; Rn := b2 DIV OM4A.C4;
        Texts.WriteString(W, mnemo0[exop]); WriteReg(Rd); WriteReg(Rn);
        Texts.WriteString(W, " = Var["); Texts.WriteInt(W, b4, 4);
        Texts.WriteString(W, "]");
        IF ODD(b3) THEN Texts.WriteString(W, " Prog based") END;
      ELSE Texts.WriteString(W, "TODO: Real external reference");
      END
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
        WHILE i < mcode.pc DO
          Files.ReadByte(R, mcode.code[i]); eref.ext[i] := 0;
(*          Texts.WriteInt(W, i, 4); Texts.Write(W, 9X); WriteHexVLen(W, data, 4);
          Texts.Write(W, 9X); opcode(data); Texts.WriteLn(W);*) INC(i)
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
        Files.ReadInt(R, data); Texts.WriteString(W, "fixD = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        i := 10;
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
  mnemo0[0] := "LDR";
  mnemo0[1] := "LDRB";
  mnemo0[2] := "STR";
  mnemo0[3] := "STRB";
  mnemo0[4] := "ADD";
  mnemo0[5] := "ADDB";
  mnemo0[6] := "VLDR";
  mnemo0[7] := "VSTR";
END OM4Tool.
