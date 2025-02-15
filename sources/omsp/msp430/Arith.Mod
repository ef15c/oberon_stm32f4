MODULE Arith; (*runtime module implementing arithmetic operations*)

(*----------------------------------------------------------------*)
(*--- W A R N I N G : never change interfaces of the functions in this module ---*)
(*however, you can comment an unused function here to free some program space*)
(*----------------------------------------------------------------*)

  IMPORT SYSTEM;

  CONST C = 3; (*carry*)

  PROCEDURE mul16*(x, y: INTEGER*): INTEGER; (*do not change this function interface*)
    VAR r: INTEGER*;
    BEGIN r := 0; 
      WHILE x # 0 DO IF ODD(x) THEN INC(r, y) END; INC(y, y); CLRC; RRC(x) END
      RETURN r
    END mul16;

  PROCEDURE divmod16*(x, y: INTEGER*; op: BYTE*): INTEGER; (*do not change this function interface*)
    (*borrowed from TI's  MSP430 C runtime library*)
    VAR q, r: INTEGER*; neg: SET*;
    BEGIN neg := {}; IF y < 0 THEN XOR(y, -1); INC(y); (*y := -y*) neg := {0} END;
      IF x < 0 THEN XOR(x, -1); INC(x); (*x := -x*) XOR(neg, -1) END;
      r := 0; (*initialize the remainder*) q := 1; (*walk 1 across for looping, also hold quotient*)
      REPEAT
        RLA(x, 1); RLC(r); (*shift dividend into remainder*)
        IF SYSTEM.CMP(r, y, C) THEN DEC(r, y) END; (*if current remainder >= divisor, subtract*)
        RLC(q) (*set quotient bit (from carry) and advance loop bit*)
      UNTIL SYSTEM.COND(C);
      IF BIT(neg, {0}) THEN XOR(q, -1); INC(q) (*negate quotient*) END;
      IF BIT(neg, {1}) THEN XOR(r, -1); INC(r) (*negate remainder*) END;
      IF op = 1 THEN q := r (*return remainder instead of quotient*) END

      RETURN q
  END divmod16;

  PROCEDURE set*(x, y: INTEGER*): INTEGER; (*do not change this function interface*)
    VAR r, b: INTEGER*;
    BEGIN
      IF x <= y THEN r := 2; RLA(r, y); b := 1; RLA(b, x); DEC(r, b) ELSE r := 0 END 

      RETURN r
  END set;

  PROCEDURE atoiP*(string: ARRAY OF CHAR; pos: INTEGER): INTEGER;
    VAR r: INTEGER; neg: BOOLEAN;
  BEGIN r := 0; IF string[pos] = "-" THEN neg := TRUE; INC(pos) ELSE neg := FALSE END;
    WHILE (string[pos] >= "0") & (string[pos] <= "9") DO r := r*10; INC(r, ORD(string[pos]) - ORD("0")); INC(pos) END;
    IF neg THEN XOR(r, -1); INC(r) END
    RETURN r
  END atoiP;

  PROCEDURE atoi*(string: ARRAY OF CHAR): INTEGER;
    RETURN atoiP(string, 0)
  END atoi;

END Arith.

OMSPTool.DecSym Arith.sms
Arith CE724D80  1
   1 mul16 [0  form = 10  size = 2 [^4] leaf UR 0070( class = 2 R6 [^4] class = 2 R5 [^4])]       1
   1 divmod16 [0  form = 10  size = 2 [^4] leaf UR 03F0( class = 2 R7 [^1] class = 2 R6 [^4] class = 2 R5 [^4])]       2
   1 set [0  form = 10  size = 2 [^4] leaf UR 01F0( class = 2 R6 [^4] class = 2 R5 [^4])]       3
   1 atoiPL [0  form = 10  size = 2 [^4] UR C000( class = 2 [^4] class = 2 [^4] class = 3# [0  form = 12  size = 4 [^3]  len = -1])]       4
   1 atoi [0  form = 10  size = 2 [^4] UR C000( class = 3# [0  form = 12  size = 4 [^3]  len = -1])]       5
