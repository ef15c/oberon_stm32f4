MODULE OMSPD;  (*MSP430 Disassembler C. Schoffit 09.06.24*)
  IMPORT SYSTEM, Texts, TextsEx, B := OMSPB, A := OMSPA;

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
 
  PROCEDURE WritePCOffset(VAR W: Texts.Writer; at: LONGINT; ofs: LONGINT);
  BEGIN
    Texts.WriteString(W, " #"); Texts.WriteInt(W, ofs, 1);
    Texts.WriteString(W, ", goes to "); Texts.WriteHex(W, at+ofs);
  END WritePCOffset;

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
    END

    RETURN res
  END isConstant;

  PROCEDURE opcode*(VAR W: Texts.Writer; VAR c: ARRAY OF BYTE; VAR i: LONGINT; base: LONGINT);
    CONST 
      SOMSK = {10..15}; SO = {12}; (*Single operand*)
      JMPMSK = {13..15}; JMP = {13}; (*jump*)
                  
    VAR b1, b2, t, src, dst: BYTE;
      op: SET; ct: INTEGER;
  BEGIN
    b1 := c[i+1]; b2 := c[i]; INC(i, 2);
    op := SYSTEM.VAL(SET, 0+b2+100H*b1);
    Texts.WriteString(W, "    "); TextsEx.WriteHexVLen(W, ORD(op), 4, FALSE); Texts.Write(W, 9X);
    IF SYSTEM.VAL(INTEGER, op) = 4130H THEN Texts.WriteString(W, "RET");
    ELSIF op*SOMSK = SOMSK THEN (*Single-operand (Format II) instructions*)
      t := LSR(SYSTEM.VAL(INTEGER, op), 7) MOD 8; Texts.WriteString(W, mnemo2[t]);
      IF t IN {0, 3, 5} THEN IF op*A.Byte = A.Byte THEN Texts.WriteString(W, ".B") END END;
      Texts.Write(W, " ");
      (*TODO*)
    ELSIF op*JMPMSK = JMP THEN Texts.WriteString(W, "TODO Jump instructions")
    ELSE t := b1 DIV 10H;
      IF t  IN {4..15} THEN (*Double-operand (format I) instructions*)
        DEC(t, 4); Texts.WriteString(W, mnemo3[t]);
        IF op*A.Byte = A.Byte THEN Texts.WriteString(W, ".B") END; Texts.Write(W, " ");
        IF isConstant(op, b1 MOD 10H, ct) THEN Texts.Write(W, "#"); Texts.WriteInt(W, ct, 1)
        ELSE
          IF op*A.IRm = A.IRm THEN (*indirec*) Texts.WriteString(W, "@");
            WriteReg(W, b1 MOD 10H); IF op*A.IRAm = A.IRAm THEN (*auto increment*) Texts.WriteString(W, "+") END
          ELSIF op*A.Im = A.Im THEN (*indexed*) t := c[i+1]*100H + c[i]; INC(i, 2);
            Texts.WriteInt(W, t, 1); Texts.Write(W, "("); WriteReg(W, b1 MOD 10H); Texts.Write(W, ")")
          ELSE WriteReg(W, b1 MOD 10H)
          END;
        END;
        Texts.Write(W, ",");
        IF op*A.Idm = A.Idm THEN (*indexed*);  t := c[i+1]*100H + c[i]; INC(i, 2);
          Texts.WriteInt(W, t, 1); Texts.Write(W, "("); WriteReg(W, b2 MOD 10H); Texts.Write(W, ")")
        ELSE WriteReg(W, b2 MOD 10H)
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
