MODULE Mira; (* 'Chaos esthétique' after Gumowski & Mira *)

IMPORT Display, D := JDraw;

CONST
 white   = Display.white;
 red     = Display.red;
 green   = Display.green;
 blue    = Display.blue;
 black   = Display.black;
 lightBlue   = 73H;
 lightGreen  = 5EH;
 darkGreen   = 0CH;
 darkBlue    = 2;
 yellow      = Display.yellow; 
 saddleBrown = 64H;
 darkOrange  = 0E8H;

VAR
 a: REAL;  k: INTEGER;
 x1, x2, x3, x4, x5, x6, x7: REAL;
 y1, y2, y3, y4, y5, y6, y7: REAL;
 p1, p2, p3, p4, p5, p6, p7: INTEGER;

PROCEDURE Setup(F: D.Frame);
BEGIN
 D.SetSize(F, 450,450);
 D.SetBackground(F, 0);
 D.NoLoop(F);
END Setup;

PROCEDURE Orbit (F: D.Frame; x, y: REAL; p: INTEGER);
 VAR c, u, w, z: REAL;
  k, kMax: INTEGER;
BEGIN
 c := 2.0 - 2.0*a;
 kMax := 1000*p;
 w := a*x + c*x*x/(1.0 + x*x);
 FOR k := 1 TO kMax DO
  D.Point(F, 8.0*x, 8.0*y);
  z := x;
  x := y + w;
  u := x*x;
  w := a*x + c*u/(1.0 + u);
  y := w - z;
 END
END Orbit;

PROCEDURE Restore(F: D.Frame);
 VAR x, y: REAL;
  p: INTEGER;
BEGIN
 D.Translate(F, 210.0, 220.0);
 D.Stroke(F, lightBlue);
 x := x1;  y := y1;  p := p1;
 Orbit(F, x, y, p);
 D.Stroke(F, darkBlue);
 x := x2;  y := y2;  p := p2;
 Orbit(F, x, y, p);
 D.Stroke(F, lightGreen);
 x := x3;  y := y3;  p := p3;
 Orbit(F, x, y, p);
 D.Stroke(F, saddleBrown);
 x := x4; y := y4;  p := p4;
 Orbit(F, x, y, p);
 D.Stroke(F, darkOrange);
 x := x5;  y := y5;  p := p5;
 Orbit(F, x, y, p);
 D.Stroke(F, yellow);
 x := x6;  y := y6;  p := p6;
 Orbit(F, x, y, p);
 D.Stroke(F, white);
 x := x7;  y := y7;  p := p7;
 Orbit(F, x, y, p)
END Restore;

PROCEDURE MousePressed(F: D.Frame);
 VAR mod: INTEGER;
BEGIN INC(k);
 mod := k MOD 3;
 IF mod = 0 THEN
  a  :=  0.18;
  x1 :=  8.0;  y1 := 0.0;  p1 := 2;
  x2 := 20.0;  y2 := 0.0;  p2 := 2;
  x3 := 15.0;  y3 := 0.0;  p3 := 6;
  x4 :=  5.3;  y4 := 0.0;  p4 := 2;
  x5 :=  9.0;  y5 := 0.0;  p5 := 2;
  x6 :=  0.0;  y6 := 0.0;  p6 := 0;
  x7 :=  0.0;  y7 := 0.0;  p7 := 0;
 ELSIF mod = 1 THEN
  a  := -0.05;
  x1 :=  9.8;  y1 := 0.0;  p1 := 1;
  x2 := 20.0;  y2 := 0.0;  p2 := 4;
  x3 := 15.0;  y3 := 0.0;  p3 := 2;
  x2 :=  2.0;  y4 := 0.0;  p4 := 4;
  x5 := 18.0;  y5 := 0.0;  p5 := 2;
  x6 := 25.0;  y6 := 0.0;  p6 := 6;
  x7 :=  7.5;  y7 := 0.0;  p7 := 4;
 ELSE
  a  :=   0.3; 
  x1 :=   7.0;  y1 := 0.0;  p1 := 2; 
  x2 := -12.0;  y2 := 0.0;  p2 := 2; 
  x3 := -21.0;  y3 := 0.0;  p3 := 2; 
  x4 := -21.0;  y4 := 0.0;  p4 := 0; 
  x5 := -21.0;  y5 := 0.0;  p5 := 0; 
  x6 :=   0.0;  y6 := 0.0;  p6 := 0; 
  x7 :=   0.0;  y7 := 0.0;  p7 := 0;
 END;
 D.SetBackground(F, black);
 D.Redraw(F)
END MousePressed;

PROCEDURE Draw*;
  VAR F!: D.Frame;
BEGIN
  a  :=   0.3;  k  := 2;
  x1 :=   7.0;  y1 := 0.0;  p1 := 2;
  x2 := -12.0;  y2 := 0.0;  p2 := 2;
  x3 := -21.0;  y3 := 0.0;  p3 := 2;
  x4 := -21.0;  y4 := 0.0;  p4 := 0;
  x5 := -21.0;  y5 := 0.0;  p5 := 0;
  x6 :=   0.0;  y6 := 0.0;  p6 := 0;
  x7 :=   0.0;  y7 := 0.0;  p7 := 0;
  F := D.New();
  D.SetSetupProc(F, Setup);
  D.SetDrawProc(F, Restore);
  D.SetPressedProc(F, MousePressed);
  D.Start(F, "Mira")
END Draw;

END Mira.

Net.SendFiles CS JDraw.Mod Mira.Mod~
OM4P.Compile JDraw.Mod/s Mira.Mod/s~
System.Free Mira JDraw~

Mira.Draw
