MODULE testSFuncs;
  IMPORT SYSTEM;
  PROCEDURE p;
    VAR a, v: LONGINT;
      r, s: REAL;
      b: BOOLEAN;
  BEGIN
    a := ABS(v);
    s := ABS(r);
    s := SQRT(r);
    b := ODD(a);
    v := FLOOR(r);
    r := FLT(v);
    v := ORD(b);
  END p;
BEGIN
END testSFuncs.


(*
ORTool.DecObj testSFuncs.rsc ~

decode testSFuncs.rsc

OM4Tool.DecObj testSFuncs.m4c ~

*)