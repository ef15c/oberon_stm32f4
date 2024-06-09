MODULE OMSPD;  (*MSP430 Disassembler C. Schoffit 09.06.24*)
  IMPORT SYSTEM, Texts, TextsEx, B := OMSPB, A := OMSPA;

  VAR mnemo1: ARRAY 8, 3 OF CHAR;  (*condition mnemonics*)
    mnemo2: ARRAY 7, 5 OF CHAR;  (*single-operand mnemonics*)

(* ---------------------------------------------------*)

  PROCEDURE WriteReg*(VAR W: Texts.Writer; r: BYTE);
  BEGIN Texts.Write(W, " ");
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
  
  PROCEDURE opcode*(VAR W: Texts.Writer; VAR c: ARRAY OF BYTE; VAR i: LONGINT; base: LONGINT);
    CONST 
      SOMSK = {10..15}; SO = {12}; (*Single operand*)
      JMPMSK = {13..15}; JMP = {13}; (*jump*)
                  
    VAR b1, b2, t, src, dst: BYTE;
      op: SET;
  BEGIN
    b1 := c[i+1]; b2 := c[i]; INC(i, 2);
    op := SYSTEM.VAL(SET, 0+b2+100H*b1);
    Texts.WriteString(W, "    "); TextsEx.WriteHexVLen(W, ORD(op), 4, FALSE); Texts.Write(W, 9X);
    IF op*SOMSK = SOMSK THEN (*Single-operand (Format II) instructions*)
      t := LSR(SYSTEM.VAL(INTEGER, op), 7) MOD 8; Texts.WriteString(W, mnemo2[t]);
      IF t IN {0, 3, 5} THEN IF op*{6} = {} THEN Texts.WriteString(W, ".W") ELSE Texts.WriteString(W, ".B") END END
    ELSE Texts.WriteString(W, "TODO other format")
    END
  END opcode;

BEGIN
  mnemo1[A.NE] := "NE"; mnemo1[A.EQ] := "EQ"; mnemo1[A.NC] := "NC"; mnemo1[A.C] := "C";
  mnemo1[A.N] := "N"; mnemo1[A.GE] := "GE"; mnemo1[A.L] := "L"; mnemo1[A.AL] := "MP";

  mnemo2[0] := "RRC"; mnemo2[1] := "SWPB"; mnemo2[2] := "RRA"; mnemo2[3] := "SXT";
  mnemo2[4] := "PUSH"; mnemo2[5] := "CALL"; mnemo2[6] := "RETI";
END OMSPD.
