MODULE testLongInt;
  IMPORT Texts, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE p;
    VAR a, b: LONGINT;
  BEGIN a := ASR(1L, a)
  END p;

  PROCEDURE run*;
    VAR x: LONGINT;
  BEGIN x := 1000; WHILE (x < -40H) OR (x >= 40H) DO x := ASR(x, 7) END ;
  END run;

BEGIN Texts.OpenWriter(W)
END testLongInt.

OM4P2.Compile testLongInt.Mod/s ~ System.Free testLongInt ~ testLongInt.run

OM4Tool.DecObj testLongInt.m4c
