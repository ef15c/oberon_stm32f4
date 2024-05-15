MODULE testTrap;
  IMPORT SYSTEM;

 TYPE R1 = RECORD END;
   R2 = RECORD(R1) a: INTEGER END;
   PR2 = POINTER TO R2;

  PROCEDURE Trap1*;
    VAR i: INTEGER; a: ARRAY 1 OF INTEGER;
  BEGIN
    i := 1; a[i] := i
  END Trap1;

  PROCEDURE trap2(r: R1);
    VAR i: INTEGER;
  BEGIN
    i := r(R2).a
  END trap2;

  PROCEDURE Trap2*;
    VAR r: R1;
  BEGIN trap2(r)
  END Trap2;

  PROCEDURE trap3( VAR a: ARRAY OF CHAR);
  BEGIN a := "123456789"
  END trap3;

  PROCEDURE Trap3*;
    VAR a: ARRAY 3 OF CHAR;
  BEGIN trap3(a)
  END Trap3;

  PROCEDURE Trap4*;
    VAR r!: PR2; i: INTEGER;
  BEGIN r := NIL; i := r.a
  END Trap4;

  PROCEDURE Trap5*;
    VAR p: PROCEDURE;
  BEGIN p := NIL; p
  END Trap5;

  PROCEDURE Trap6*;
    VAR i: INTEGER;
  BEGIN i := 0; i := 1 DIV i
  END Trap6;

  PROCEDURE Trap7*;
  BEGIN ASSERT(FALSE)
  END Trap7;

  PROCEDURE Trap8*;
    VAR r!: PR2; i: INTEGER;
  BEGIN r := SYSTEM.VAL(PR2, 10020000H); i := r.a
  END Trap8;

  PROCEDURE Trap9*;
  BEGIN Trap9
  END Trap9;

END testTrap.
