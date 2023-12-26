MODULE DrawArrow;

  IMPORT Display;
  
  PROCEDURE Draw*;
    VAR x, y: INTEGER;
  BEGIN
    FOR y := 0 TO Display.Height-1 - 15 DO
      FOR x := 0 TO Display.Width-1 - 15 DO     
        Display.CopyPattern(Display.white, Display.arrow, x, y, Display.invert);
        Display.CopyPattern(Display.white, Display.arrow, x, y, Display.invert)
      END
    END
  END Draw;

END DrawArrow.
