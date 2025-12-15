MODULE Math;   (*Standard functions;  NW 12.10.2013*)
(* 32-bit version *)
(* hk 10 Aug. 2022, 18 May 2024                                                        *)
(* The missing arctan(x), a corrected ln(x), and some additional constants and         *)
(* functions for convenience.                                                          *)
(* Procedures sqrt, exp, sin and cos can be found in module Math by NW 12.10.2013      *)
(*Rational arithmetics CS 15.12.2025*)

  CONST
    pi* = 3.14159265358979323846;
    e* = 2.71828182845904523536;

  TYPE RATIONAL* = RECORD p, q: INTEGER END;

  VAR R0*, R1*: RATIONAL-;

 PROCEDURE ln* (x: REAL): REAL;  (* hk 18.5.2024 / jr 22.5.2024 *)
  (** Returns the natural (base e) logarithm of x *)
  (* ln(x) = 2*arctanh( (x-1)/(x+1) )
     around 0, arctanh() is almost linear with slope 1
  *)
    CONST
      c1 = 1.4142135;  (* sqrt(2) *)
      c2 = 0.6931472;  (* ln(2) *)
      c3 = 0.89554059;
      c4 = 1.82984424;
      c5 = 1.65677798;
    VAR e: INTEGER;
  BEGIN
    ASSERT(x > 0.0); UNPK(x, e);            (* x in 1 .. 2 *)
    IF x > c1 THEN x := x*0.5; INC(e) END;  (* x in 0.7 .. 1.4) *)
    x := (x - 1.0)/(x + 1.0);               (* x in -0.17 .. 0.17 *)
    x := FLT(e)*c2 + x*(c3 + c4/(c5 - x*x))
  RETURN x 
  END ln;

  PROCEDURE exp*(x: REAL): REAL;
    CONST
      c1 = 1.4426951;  (*1/ln(2) *)
      p0 = 1.513864173E3;
      p1= 2.020170000E1;
      p2 = 2.309432127E-2;
      q0 = 4.368088670E3;
      q1 = 2.331782320E2;
    VAR n: INTEGER; p, y, yy: REAL;
  BEGIN y := c1*x;
    n := FLOOR(y + 0.5); y := y - FLT(n);
    yy := y*y;
    p := ((p2*yy + p1)*yy + p0)*y;
    p := p/((yy + q1)*yy + q0 - p) + 0.5;
    PACK(p, n+1); RETURN p
  END exp;

  PROCEDURE power* (x, e: REAL): REAL;
  (** Returns x to the power e (x^e) *)
  BEGIN ASSERT(x > 0.0)
  RETURN exp(e * ln(x))
  END power;

  PROCEDURE log* (x, b: REAL): REAL;
  (** Returns the logarithm of x base b *)
  BEGIN ASSERT(x > 0.0)
  RETURN ln(x) / ln(b)
  END log;

  PROCEDURE sin*(x: REAL): REAL;
    CONST
      c1 =  6.3661977E-1; (*2/pi*)
      p0 =  7.8539816E-1;
      p1 = -8.0745512E-2;
      p2 =  2.4903946E-3;
      p3 = -3.6576204E-5;
      p4 =  3.1336162E-7;
      p5 = -1.7571493E-9;
      p6 =  6.8771004E-12;
      q0 =  9.9999999E-1;
      q1 = -3.0842514E-1;
      q2 =  1.5854344E-2;
      q3 = -3.2599189E-4;
      q4 =  3.5908591E-6;
      q5 = -2.4609457E-8;
      q6 =  1.1363813E-10;
    VAR n: INTEGER; y, yy, f: REAL;
  BEGIN y := c1*x;
    IF y >= 0.0 THEN n := FLOOR(y + 0.5) ELSE n := FLOOR(y - 0.5) END ;
    y := (y - FLT(n)) * 2.0; yy := y*y;
    IF ODD(n) THEN f := (((((q6*yy + q5)*yy + q4)*yy + q3)*yy + q2)*yy + q1)*yy + q0
    ELSE f := ((((((p6*yy + p5)*yy + p4)*yy + p3)*yy + p2)*yy + p1)*yy + p0)*y
    END ;
    IF ODD(n DIV 2) THEN f := -f END ;
    RETURN f
  END sin;

  PROCEDURE cos*(x: REAL): REAL;
    CONST
      c1 =  6.3661977E-1; (*2/pi*)
      p0 =  7.8539816E-1;
      p1 = -8.0745512E-2;
      p2 =  2.4903946E-3;
      p3 = -3.6576204E-5;
      p4 =  3.1336162E-7;
      p5 = -1.7571493E-9;
      p6 = 6.8771004E-12;
      q0 =  9.9999999E-1;
      q1 = -3.0842514E-1;
      q2 =  1.5854344E-2;
      q3 = -3.2599189E-4;
      q4 =  3.5908591E-6;
      q5 = -2.4609457E-8;
      q6 =  1.1363813E-10;
    VAR n: INTEGER; y, yy, f: REAL;
  BEGIN y := c1*x;
    IF y >= 0.0 THEN n := FLOOR(y + 0.5) ELSE n := FLOOR(y - 0.5) END ;
    y := (y - FLT(n)) * 2.0; yy := y*y;
    IF ~ODD(n) THEN f := (((((q6*yy + q5)*yy + q4)*yy + q3)*yy + q2)*yy + q1)*yy + q0
    ELSE f := ((((((p6*yy + p5)*yy + p4)*yy + p3)*yy + p2)*yy + p1)*yy + p0)*y
    END ;
    IF ODD((n+1) DIV 2) THEN f := -f END ;
    RETURN f
  END cos;

  PROCEDURE tan* (x: REAL): REAL;
  (** Returns the tangent of x radians *)
  BEGIN
  RETURN sin(x) / cos(x)
  END tan;
  
  PROCEDURE arctan* (x: REAL): REAL;
  (** Returns the arctangent (inverse tangent) in radians of x *)
  (*  ETH Oberon, (C) 2001 ETH Zuerich Institut fuer Computersysteme *)
    CONST         
      c51 =   2.41421365738;     (* 1 + sqrt(2) *)
      c52 =   4.14213567972E-1;  (* sqrt(2) - 1 *)
      s51 =   1.57079637051;      (* pi/2 *)
      s52 =   7.85398185253E-1;  (* pi/4 *)
      p50 =   6.36918878555;
      q50 =   1.98769211769;
      q51 = -4.43698644638;
      q52 =   8.60141944885;
    VAR y, yy, s: REAL;
  BEGIN
    y := ABS(x);  s := 0.0;
    IF y > c51 THEN y := -1.0/y;  s := s51
    ELSIF y > c52 THEN y := (y - 1.0) / (y + 1.0);  s := s52
    END;
    yy := y*y;
    y := p50 * y / (yy + q52 + q51 / (yy + q50)) + s;
    IF x < 0.0 THEN y := -y END
  RETURN y
  END arctan;

  PROCEDURE sqrt*(x: REAL): REAL;
    CONST c1 = 0.70710680;   (* 1/sqrt(2) *)
      c2 = 0.590162067;
      c3 = 1.4142135;  (*sqrt(2)*)
    VAR s: REAL; e: INTEGER;
  BEGIN ASSERT(x >= 0.0);
    IF x > 0.0 THEN
      UNPK(x, e);
      s := c2*(x+c1);
      s := s + (x/s);
      s := 0.25*s + x/s;
      s := 0.5 * (s + x/s);
      IF ODD(e) THEN s := c3*s END ;
      PACK(s, e DIV 2)
    ELSE s := 0.0
    END ;
    RETURN s
  END sqrt;

  PROCEDURE RsetI*(VAR r: RATIONAL; x: INTEGER);
  BEGIN r.p := x; r.q := 1
  END RsetI;

  PROCEDURE ItoS*(VAR s: ARRAY OF CHAR; x: INTEGER; VAR p: INTEGER; l: INTEGER);
    VAR i, j, k: INTEGER; neg: BOOLEAN; t: CHAR;
  BEGIN IF x < 0 THEN neg := TRUE; x := -x END; i := p;
    REPEAT s[i] := CHR(x MOD 10 + ORD("0")); x := x DIV 10; INC(i) UNTIL x = 0;
    IF neg THEN s[i] := "-"; INC(i) END; WHILE i < p + l DO s[i] := " "; INC(i) END;
    j := p; k := i - 1; WHILE j < k DO t := s[j]; s[j] := s[k]; s[k] := t END; (*reverse string*)
    p := i; s[p] := 0X
  END ItoS;

  PROCEDURE RtoS*(VAR s: ARRAY OF CHAR; r: RATIONAL; l: INTEGER);
    VAR pos: INTEGER;
  BEGIN pos := 0; ItoS(s, r.p, pos, 1);
    IF r.q # 1 THEN s[pos] := "/"; INC(pos); ItoS(s, r.q, pos, 1) END
  END RtoS;

  PROCEDURE Rcmp*(a, b: RATIONAL): INTEGER;
    VAR r: INTEGER; na, nb: LONGINT;
  BEGIN na := 1L*a.p*b.q; nb := 1L*b.p*a.q;
    IF na > nb THEN r := 1
    ELSIF na = nb THEN r := 0
    ELSE r := -1
    END

    RETURN r

  END Rcmp;

  PROCEDURE Rdiv*(VAR d: RATIONAL; q: RATIONAL);
  BEGIN d.p := d.p*q.q; d.q := d.q*q.p
  END Rdiv;

BEGIN R0.p := 0; R0.q := 1; R1.p := 0; R1.q := 1
END Math.
