MODULE testRS232;
  IMPORT RS232;

PROCEDURE hello*;
  VAR d: INTEGER;
BEGIN
  RS232.SendStr("Hello from Oberon!");
  RS232.Send(0AH); RS232.Send(0DH);
(*  RS232.Rec(d)*)
END hello;

END testRS232.

OM4P.Compile testRS232.Mod~
System.Free testRS232~
testRS232.hello
