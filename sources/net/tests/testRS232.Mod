MODULE testRS232;
  IMPORT RS232;

PROCEDURE hello*;
  VAR d: INTEGER;
BEGIN
  RS232.SendStr("Hello from Oberon!");
  RS232.Rec(d)
END hello;

END testRS232.
