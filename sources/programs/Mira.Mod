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

TYPE
  Frame = POINTER TO FrameDesc;
  FrameDesc = RECORD(D.FrameDesc)
    a: REAL;  k: INTEGER;
    x1, x2, x3, x4, x5, x6, x7: REAL;
    y1, y2, y3, y4, y5, y6, y7: REAL;
    p1, p2, p3, p4, p5, p6, p7: INTEGER
  END;

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
  CASE F OF Frame:
    c := 2.0 - 2.0*F.a;
    kMax := 1000*p;
    w := F.a*x + c*x*x/(1.0 + x*x);
    FOR k := 1 TO kMax DO
      D.Point(F, 8.0*x, 8.0*y);
      z := x;
      x := y + w;
      u := x*x;
      w := F.a*x + c*u/(1.0 + u);
      y := w - z;
    END
  END
END Orbit;

PROCEDURE Restore(F: D.Frame);
 VAR x, y: REAL;
  p: INTEGER;
BEGIN
  CASE F OF Frame:
    D.Translate(F, 210.0, 220.0);
    D.Stroke(F, lightBlue);
    x := F.x1;  y := F.y1;  p := F.p1;
    Orbit(F, x, y, p);
    D.Stroke(F, darkBlue);
    x := F.x2;  y := F.y2;  p := F.p2;
    Orbit(F, x, y, p);
    D.Stroke(F, lightGreen);
    x := F.x3;  y := F.y3;  p := F.p3;
    Orbit(F, x, y, p);
    D.Stroke(F, saddleBrown);
    x := F.x4; y := F.y4;  p := F.p4;
    Orbit(F, x, y, p);
    D.Stroke(F, darkOrange);
    x := F.x5;  y := F.y5;  p := F.p5;
    Orbit(F, x, y, p);
    D.Stroke(F, yellow);
    x := F.x6;  y := F.y6;  p := F.p6;
    Orbit(F, x, y, p);
    D.Stroke(F, white);
    x := F.x7;  y := F.y7;  p := F.p7;
    Orbit(F, x, y, p)
  END
END Restore;

PROCEDURE MousePressed(F: D.Frame);
 VAR mod: INTEGER;
BEGIN
  CASE F OF Frame:
    INC(F.k);
    mod := F.k MOD 3;
    IF mod = 0 THEN
      F.a  :=  0.18;
      F.x1 :=  8.0;  F.y1 := 0.0;  F.p1 := 2;
      F.x2 := 20.0;  F.y2 := 0.0;  F.p2 := 2;
      F.x3 := 15.0;  F.y3 := 0.0;  F.p3 := 6;
      F.x4 :=  5.3;  F.y4 := 0.0;  F.p4 := 2;
      F.x5 :=  9.0;  F.y5 := 0.0;  F.p5 := 2;
      F.x6 :=  0.0;  F.y6 := 0.0;  F.p6 := 0;
      F.x7 :=  0.0;  F.y7 := 0.0;  F.p7 := 0;
   ELSIF mod = 1 THEN
      F.a  := -0.05;
      F.x1 :=  9.8;  F.y1 := 0.0;  F.p1 := 1;
      F.x2 := 20.0;  F.y2 := 0.0;  F.p2 := 4;
      F.x3 := 15.0;  F.y3 := 0.0;  F.p3 := 2;
      F.x2 :=  2.0;  F.y4 := 0.0;  F.p4 := 4;
      F.x5 := 18.0;  F.y5 := 0.0;  F.p5 := 2;
      F.x6 := 25.0;  F.y6 := 0.0;  F.p6 := 6;
      F.x7 :=  7.5;  F.y7 := 0.0;  F.p7 := 4;
   ELSE
      F.a  :=   0.3; 
      F.x1 :=   7.0;  F.y1 := 0.0;  F.p1 := 2; 
      F.x2 := -12.0;  F.y2 := 0.0;  F.p2 := 2; 
      F.x3 := -21.0;  F.y3 := 0.0;  F.p3 := 2; 
      F.x4 := -21.0;  F.y4 := 0.0;  F.p4 := 0; 
      F.x5 := -21.0;  F.y5 := 0.0;  F.p5 := 0; 
      F.x6 :=   0.0;  F.y6 := 0.0;  F.p6 := 0; 
      F.x7 :=   0.0;  F.y7 := 0.0;  F.p7 := 0
    END
  END;
  D.SetBackground(F, black);
  D.Redraw(F)
END MousePressed;

PROCEDURE Draw*;
  VAR F!: Frame;
BEGIN  NEW(F);
  F.a  :=   0.3;  F.k  := 2;
  F.x1 :=   7.0;  F.y1 := 0.0;  F.p1 := 2;
  F.x2 := -12.0;  F.y2 := 0.0;  F.p2 := 2;
  F.x3 := -21.0;  F.y3 := 0.0;  F.p3 := 2;
  F.x4 := -21.0;  F.y4 := 0.0;  F.p4 := 0;
  F.x5 := -21.0;  F.y5 := 0.0;  F.p5 := 0;
  F.x6 :=   0.0;  F.y6 := 0.0;  F.p6 := 0;
  F.x7 :=   0.0;  F.y7 := 0.0;  F.p7 := 0;
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
