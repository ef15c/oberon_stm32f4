MODULE TestDragon;   (* hk 11 July 2024 *)
  IMPORT Math, Out;  
  (* For Math.power see: https://github.com/hansklav/Oberon-07/blob/master/Math.Mod *)

  CONST
    pi = 3.1415926535;
    p = 4.0;  (* order of dragon curve *)

  PROCEDURE Correct*;  (* TestDragon.Correct *)   (* correct result for x2 *)
    VAR h, x1, x2: REAL;  s: INTEGER;
  BEGIN
    s := 0;  x1 := 7.499998E-01;
    h := 2.500000E-01;
    Out.String("s  = "); Out.Int(s, 2); Out.String("    h ="); Out.Real(h, 14); Out.Ln;
    x2 := x1 + h * Math.cos( (FLT(s) - p/2.0) * pi/2.0 );  (* <-- expression tested *)
    Out.String("x1 ="); Out.Real(x1, 14); Out.Ln;
    Out.String("x2 ="); Out.Real(x2, 14); Out.Ln;
    Out.Ln
  END Correct;

  PROCEDURE Incorrect*;  (* TestDragon.Incorrect *)   (* incorrect result for x2 *)
    VAR h, x1, x2: REAL;  s: INTEGER;
  BEGIN
    s := 0;  x1 := 7.499998E-01;
    h := Math.power(2.0, -p/2.0);  (* the result for h from Math.power() is correct: *)
    Out.String("s  = "); Out.Int(s, 2); Out.String("    h ="); Out.Real(h, 14); Out.Ln;
    x2 := x1 + h * Math.cos( (FLT(s) - p/2.0) * pi/2.0 );  (* <-- why incorrect result?? *)
    Out.String("x1 ="); Out.Real(x1, 14); Out.Ln;
    Out.String("x2 ="); Out.Real(x2, 14); Out.Ln;
    Out.Ln
  END Incorrect;

END TestDragon.
