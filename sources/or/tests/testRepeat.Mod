MODULE testRepeat;

  PROCEDURE p;
    VAR i: INTEGER;
  BEGIN
    i := 10; REPEAT i := i-1 UNTIL i = 0;
  END p;
  
END testRepeat.


(*
ORTool.DecObj testRepeat.rsc ~

decode testRepeat.rsc

OM4Tool.DecObj testRepeat.m4c ~

decode testRepeat.m4c

*)