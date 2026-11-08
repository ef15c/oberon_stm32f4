MODULE AOCHexGrid;
  IMPORT U := AOCUtils;

  CONST N* = 0; NE* = 1; SE* = 2; S* = 3; SW* = 4; NW* = 5;

  VAR moves*: ARRAY 6 OF U.Vector;

BEGIN
  moves[0].x := 0; moves[0].y := 2; (*north*)
  moves[1].x := 1; moves[1].y := 1; (*northeast*)
  moves[2].x := 1; moves[2].y := -1; (*southeast*)
  moves[3].x := 0; moves[3].y := -2; (*south*)
  moves[4].x := -1; moves[4].y := -1; (*southwest*)
  moves[5].x := -1; moves[5].y := 1 (*northwest*)
END AOCHexGrid.

Oberon.Batch
  OM4P.Compile AOCHexGrid.Mod/s~
  System.Free AOCHexGrid AOCUtils~
~
