MODULE testLongInt;
  IMPORT Texts,  Oberon, TextsEx := TextsEx2;

  VAR W: Texts.Writer;

  PROCEDURE run*;
  BEGIN  TextsEx.WriteLongInt(W, LSL(1L, 63), 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END run;

BEGIN Texts.OpenWriter(W)
END testLongInt.

System.Free OM4P2 OM4G2 OM4A2 OM4B2 OM4S2 ~ System.Free OM4Tool OM4D ~
OM4P2.Compile testLongInt.Mod/s ~ System.Free testLongInt ~ testLongInt.run

OM4Tool.DecObj testLongInt.m4c
