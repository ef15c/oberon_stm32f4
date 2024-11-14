MODULE MultiPrecisionArith; (*C. Schoffit 15.09.24 *)
  IMPORT SYSTEM;

  CONST C = 3; (*carry*)

  PROCEDURE mulu1632*(x, y: INTEGER*; VAR rl, rh: INTEGER*);
    VAR yl, yh: INTEGER*;
    BEGIN rl := 0; rh := 0; yl := y; yh := 0;
      WHILE x # 0 DO IF ODD(x) THEN INC(rl, yl); ADC(rh, yh) END; INC(yl, yl); ADC(yh, yh); CLRC; RRC(x) END
    END mulu1632;

  PROCEDURE SetLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  (*Initialize long integer lh-ll with an integer value n*)
  BEGIN ll := n; IF n < 0 THEN lh := -1 ELSE lh := 0 END
  END SetLongInt;

  PROCEDURE SubLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  (*Subtract integer n from long integer lh-ll*)
  BEGIN DEC(ll, n); SBC(lh, 0)
  END SubLongInt;

  PROCEDURE AddLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  (*Subtract integer n from long integer lh-ll*)
  BEGIN INC(ll, n); ADC(lh, 0)
  END AddLongInt;

  PROCEDURE LongNegate*(VAR lh, ll: INTEGER*);
  BEGIN XOR(ll, -1); XOR(lh, -1); INC(ll, 1); ADC(lh, 0) 
  END LongNegate;

  PROCEDURE MulLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  (*Multiply long integer lh-ll by integer value n*)
    VAR negate: BOOLEAN*; tl, th: INTEGER*;
  BEGIN negate := FALSE;
    IF lh < 0 THEN XOR(negate, -1); XOR(ll, -1); XOR(lh, -1); INC(ll); ADC(lh, 0) END;
    IF n < 0 THEN XOR(negate, -1); XOR(n, -1); INC(n) END;
    th := lh; tl := ll; lh := 0; ll := 0;
    WHILE n # 0 DO IF ODD(n) THEN INC(ll, tl); ADC(lh, th) END; INC(tl, tl); ADC(th, th); CLRC; RRC(n) END;
    IF negate THEN XOR(ll, -1); XOR(lh, -1); INC(ll, 1); ADC(lh, 0) END
  END MulLongInt;

  PROCEDURE DivLongLong*(VAR lh, ll, nh, nl: INTEGER*);
    (*Divide long integer lh-ll by long value nh-nl
      quotient returned in lh-ll, remainder in nh, hl*)
    (*borrowed from TI's  MSP430 C runtime library*)
    VAR ql, qh, rl, rh: INTEGER*; neg: SET*;
    BEGIN neg := {}; IF nh < 0 THEN XOR(nl, -1); XOR(nh, -1); INC(nl); ADC(nh, 0); (*n := -n*) neg := {0} END;
      IF lh < 0 THEN XOR(ll, -1); XOR(lh, -1); INC(ll); ADC(lh, 0); (*l := -l*) XOR(neg, -1) END;
      rh := 0; rl := 0; (*initialize the remainder*) qh := 0; ql := 1; (*walk 1 across for looping, also hold quotient*)
      REPEAT
        RLA(ll, 1); RLC(lh); RLC(rl); RLC(rh); (*shift dividend into remainder*)
        IF (rh > nh) OR (rh = nh) & SYSTEM.CMP(rl, nl, C) THEN DEC(rl, nl); SBC(rh, nh) END; (*if current remainder >= divisor, subtract*)
        RLC(ql); RLC(qh) (*set quotient bit (from carry) and advance loop bit*)
      UNTIL SYSTEM.COND(C);
      IF BIT(neg, {0}) THEN XOR(ql, -1); XOR(qh, -1); INC(ql); ADC(qh, 0) (*negate quotient*) END;
      IF BIT(neg, {1}) THEN XOR(rl, -1); XOR(rh, -1); INC(rl); ADC(rh, 0) (*negate remainder*) END;
      lh := qh; ll := ql; nh := rh; nl := rl (*return remainder and quotient*)
  END DivLongLong;

  PROCEDURE ASRLongInt*(VAR lh, ll: INTEGER*; n: INTEGER*);
  BEGIN WHILE n # 0 DO RRA(lh, 1); RRC(ll); DEC(n) END
  END ASRLongInt;

  PROCEDURE AbsLong*(VAR lh, ll: INTEGER*);
  BEGIN
    IF lh < 0 THEN XOR(ll, -1); XOR(lh, -1); INC(ll); ADC(lh, 0) END
  END AbsLong;

  PROCEDURE SubLongLong*(VAR lh, ll: INTEGER*; nh, nl: INTEGER*);
  (*Subtract long integer nh-nl from long integer lh-ll*)
  BEGIN DEC(ll, nl); SBC(lh, nh)
  END SubLongLong;

END MultiPrecisionArith.

OMSPTool.DecSym MultiPrecisionArith.sms
decode MultiPrecisionArith.sms
MultiPrecisionArith B561C064  1
   1 mulu1632 [0  form = 10  size = 2 [^9] leaf UR 03F0( class = 3 R7 [^4] class = 3 R6 [^4] class = 2 R5 [^4] class = 2 R4 [^4])]       1
   1 SetLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       2
   1 SubLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       3
   1 AddLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       4
   1 LongNegate [0  form = 10  size = 2 [^9] leaf UR 0030( class = 3 R5 [^4] class = 3 R4 [^4])]       5
   1 MulLongInt [0  form = 10  size = 2 [^9] leaf UR 03F0( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       6
   1 DivLongLong [0  form = 10  size = 2 [^9] leaf UR 1FF0( class = 3 R7 [^4] class = 3 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       7
   1 ASRLongInt [0  form = 10  size = 2 [^9] leaf UR 0070( class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]       8
   1 AbsLong [0  form = 10  size = 2 [^9] leaf UR 0030( class = 3 R5 [^4] class = 3 R4 [^4])]       9
   1 SubLongLong [0  form = 10  size = 2 [^9] leaf UR 00F0( class = 2 R7 [^4] class = 2 R6 [^4] class = 3 R5 [^4] class = 3 R4 [^4])]      10
