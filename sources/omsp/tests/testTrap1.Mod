MODULE testTrap1;
  IMPORT Traps, M := msp430g2553;

VAR a: ARRAY 3 OF INTEGER;
  i: INTEGER;

BEGIN
  M.WDTCTL^ := M.WDTPW + M.WDTHOLD;
  i := 2; a[i] := 0;
  i := 3; a[i] := 0
END testTrap1.

OMSPL.Link 32 4000H 200H testTrap1 ~
