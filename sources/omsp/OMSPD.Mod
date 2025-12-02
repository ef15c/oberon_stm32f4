MODULE OMSPD;  (*MSP430 Disassembler C. Schoffit 09.06.24*)
  IMPORT SYSTEM, Texts, A := OMSPA;

  VAR mnemo1: ARRAY 8, 3 OF CHAR;  (*condition mnemonics*)
    mnemo2: ARRAY 7, 5 OF CHAR;  (*single-operand mnemonics*)
    mnemo3: ARRAY 12, 5 OF CHAR;  (*single-operand mnemonics*)

(* ---------------------------------------------------*)

  PROCEDURE WriteReg*(VAR W: Texts.Writer; r: BYTE);
  BEGIN
    IF r = 0 THEN Texts.WriteString(W, "PC")
    ELSIF r = 1 THEN Texts.WriteString(W, "SP")
    ELSIF r = 2 THEN Texts.WriteString(W, "SR")
    ELSIF r = 3 THEN Texts.WriteString(W, "CG2")
    ELSE Texts.WriteString(W, "R"); Texts.WriteInt(W, r MOD 10H, 1)
    END
  END WriteReg;
 
  PROCEDURE WritePCOffset(VAR W: Texts.Writer; at, ofs: INTEGER);
    VAR ofsb: INTEGER;
  BEGIN IF ofs >= 200H THEN DEC(ofs, 400H) END; ofs := 2*ofs; ofsb := ofs + 2;
    Texts.WriteString(W, " $");
    IF ofsb > 0 THEN Texts.Write(W, "+") END;
    IF ofsb # 0 THEN Texts.WriteInt(W, ofsb, 1) END;
    Texts.WriteString(W, ", goes to "); Texts.WriteHexVLen(W, at + ofs, 4, FALSE);
  END WritePCOffset;

  PROCEDURE WordToInt(x : INTEGER): INTEGER;
  BEGIN IF x >= 8000H THEN DEC(x, 10000H) END
    RETURN x
  END WordToInt;

  PROCEDURE isConstant(op: SET; src: BYTE; VAR c: INTEGER): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN res := FALSE;
    IF src = A.CG1 THEN
      IF op*A.IRAm = A.IRm THEN res := TRUE; c := 4
      ELSIF op*A.IRAm = A.IRAm THEN res := TRUE; c := 8
      END
    ELSIF src = A.CG2 THEN res := TRUE;
      IF op*A.IRAm = A.Rm THEN c := 0
      ELSIF op*A.IRAm = A.Im THEN c := 1
      ELSIF op*A.IRAm = A.IRm THEN c := 2
      ELSIF op*A.IRAm = A.IRAm THEN c := -1
      END
    ELSIF c >= 8000H THEN DEC(c, 10000H)
    END

    RETURN res
  END isConstant;

  PROCEDURE WriteSD(VAR W: Texts.Writer; VAR c: ARRAY OF BYTE; VAR i: INTEGER; op: SET; reg: BYTE);
    VAR ct: INTEGER;
  BEGIN
    IF isConstant(op, reg, ct) THEN Texts.Write(W, "#"); Texts.WriteInt(W, ct, 1)
    ELSIF (op*A.IRAm = A.IRAm) & (reg = A.PC) THEN (*immediate*)
      ct := c[i+1]*100H + c[i]; INC(i, 2); Texts.Write(W, "#"); Texts.WriteInt(W, WordToInt(ct), 1)
    ELSIF (op*A.IRAm = A.Im) & (reg = A.SR) THEN (*absolute*)
      ct := c[i+1]*100H + c[i]; INC(i, 2); Texts.Write(W, "&"); Texts.WriteInt(W, ct, 1)
    ELSE
      IF op*A.IRm = A.IRm THEN (*indirect*) Texts.WriteString(W, "@");
        WriteReg(W, reg); IF op*A.IRAm = A.IRAm THEN (*auto increment*) Texts.WriteString(W, "+") END
      ELSIF op*A.Im = A.Im THEN (*indexed*) ct := c[i+1]*100H + c[i]; INC(i, 2);
        Texts.WriteInt(W, WordToInt(ct), 1); Texts.Write(W, "("); WriteReg(W, reg); Texts.Write(W, ")")
      ELSE WriteReg(W, reg)
      END
    END
  END WriteSD;

  PROCEDURE WriteD(VAR W: Texts.Writer; VAR c: ARRAY OF BYTE; VAR i: INTEGER; op: SET);
    VAR ct: INTEGER; reg: BYTE;
  BEGIN reg := ORD(op) MOD 10H;
    IF op*A.Idm = A.Idm THEN (*indexed*) ct := c[i+1]*100H + c[i]; INC(i, 2);
      IF reg = A.SR THEN (*absolute*) Texts.Write(W, "&"); Texts.WriteInt(W, ct, 1)
      ELSE Texts.WriteInt(W, WordToInt(ct), 1); Texts.Write(W, "("); WriteReg(W, reg); Texts.Write(W, ")")
      END
    ELSE WriteReg(W, reg)
    END
  END WriteD;

  PROCEDURE WriteSize(VAR W: Texts.Writer; op: SET);
  BEGIN IF op*A.Byte = A.Byte THEN Texts.WriteString(W, ".B") END
  END WriteSize;

  PROCEDURE opcode*(VAR W: Texts.Writer; VAR c: ARRAY OF BYTE; VAR i: INTEGER; base: INTEGER);
    CONST 
      SOMSK = {10..15}; SO = {12}; (*Single operand*)
      JMPMSK = {13..15}; JMP = {13}; (*jump*)
                  
    VAR b1, b2, t: BYTE;
      op: SET;
  BEGIN b1 := c[i+1]; b2 := c[i]; INC(i, 2);
    op := SYSTEM.VAL(SET, 0+b2+100H*b1);
    Texts.WriteString(W, "    "); Texts.WriteHexVLen(W, ORD(op), 4, FALSE); Texts.Write(W, 9X);
    IF SYSTEM.VAL(INTEGER, op) = 4130H THEN Texts.WriteString(W, "RET")
    ELSIF SYSTEM.VAL(INTEGER, op) = 4303H THEN Texts.WriteString(W, "NOP")
    ELSIF op*SOMSK = SO THEN (*Single-operand (Format II) instructions*)
      t := LSR(SYSTEM.VAL(INTEGER, op), 7) MOD 8; Texts.WriteString(W, mnemo2[t]);
      IF t # 6 THEN
        IF t IN {0, 2, 4} THEN WriteSize(W, op) END; Texts.Write(W, " ");
        WriteSD(W, c, i, op, b2 MOD 10H)
      END
    ELSIF op*JMPMSK = JMP THEN Texts.WriteString(W, "J"); Texts.WriteString(W, mnemo1[LSR(b1, 2) MOD 8]);
      WritePCOffset(W, i + base, b1 MOD 4*100H + b2)
    ELSE t := b1 DIV 10H;
      IF t  IN {4..15} THEN (*Double-operand (format I) instructions*)
        IF (t = A.MOV) & (b1 MOD 10H = A.SP) & (op*A.IRAm = A.IRAm) THEN (*POP*)
          Texts.WriteString(W, "POP"); WriteSize(W, op); Texts.Write(W, " ");
          WriteD(W, c, i, op)
        ELSE
          DEC(t, 4); Texts.WriteString(W, mnemo3[t]); WriteSize(W, op); Texts.Write(W, " ");
          WriteSD(W, c, i, op, b1 MOD 10H); Texts.Write(W, ",");
          WriteD(W, c, i, op)
        END
      ELSE Texts.WriteString(W, "TODO other format")
      END
    END
  END opcode;

BEGIN
  mnemo1[A.NE] := "NE"; mnemo1[A.EQ] := "EQ"; mnemo1[A.NC] := "NC"; mnemo1[A.C] := "C";
  mnemo1[A.N] := "N"; mnemo1[A.GE] := "GE"; mnemo1[A.L] := "L"; mnemo1[A.AL] := "MP";

  mnemo2[0] := "RRC"; mnemo2[1] := "SWPB"; mnemo2[2] := "RRA"; mnemo2[3] := "SXT";
  mnemo2[4] := "PUSH"; mnemo2[5] := "CALL"; mnemo2[6] := "RETI";

  mnemo3[0] := "MOV"; mnemo3[1] := "ADD"; mnemo3[2] := "ADDC"; mnemo3[3] := "SUBC";
  mnemo3[4] := "SUB"; mnemo3[5] := "CMP"; mnemo3[6] := "DADD"; mnemo3[7] := "BIT";
  mnemo3[8] := "BIC"; mnemo3[9] := "BIS"; mnemo3[10] := "XOR"; mnemo3[11] := "AND";
END OMSPD.
