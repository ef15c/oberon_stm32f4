MODULE JDraw; (*Raw drawing primitives*)
  IMPORT Display, Viewers, Texts, Oberon, MenuViewers, TextFrames;

  CONST Menu = "System.Close";

  TYPE
    Frame* = POINTER TO FrameDesc;
    FrameDesc* = RECORD(Display.FrameDesc)
      col, bcol: BYTE; x0, y0: INTEGER;
      SetupProc, DrawProc, FormDraw, PressedProc: PROCEDURE
    END;

  PROCEDURE ROUND(x: REAL): INTEGER;
    RETURN FLOOR(x + 0.5)
  END ROUND;

  PROCEDURE SetSize*(F: Frame; w, h: INTEGER); (*no effect*)
  END SetSize;

  PROCEDURE SetBackground*(F: Frame; col: BYTE);
  BEGIN F.bcol := col
  END SetBackground;

  PROCEDURE NoLoop*(F: Frame); (*no effect*)
  END NoLoop;

  PROCEDURE Translate*(F: Frame; x0, y0: REAL);
  BEGIN F.x0 := ROUND(x0); F.y0 := ROUND(y0)
  END Translate;

  PROCEDURE Stroke*(F: Frame; col: BYTE);
  BEGIN F.col := col
  END Stroke;

  PROCEDURE InnerDraw(F: Frame);
  END InnerDraw;

  PROCEDURE Redraw*(F: Frame);
  BEGIN Display.ReplConst(Display.black, F.X, F.Y, F.W, F.H, Display.replace);
    IF F.DrawProc # NIL THEN
      F.DrawProc;
      IF F.FormDraw # NIL THEN F.FormDraw END
    END
  END Redraw;

  PROCEDURE Point*(F: Frame; x0, y0: REAL);
    VAR x, y: INTEGER;
  BEGIN x := ROUND(x0) + F.x0; y := ROUND(y0) + F.y0;
    IF (x >= 0) & (x < F.W) & (y >= 0) & (y < F.H) THEN Display.Dot(F.col, x, y, Display.paint) END
  END Point;

  PROCEDURE Handler(F: Display.Frame; VAR M: Display.FrameMsg);
    VAR F0!: Display.Frame;
  BEGIN
    IF M IS Oberon.InputMsg THEN
      IF M(Oberon.InputMsg).id = Oberon.track THEN
        Oberon.DrawMouseArrow(M(Oberon.InputMsg).X, M(Oberon.InputMsg).Y);
        IF M(Oberon.InputMsg).keys # {} THEN F(Frame).PressedProc END
      END
    ELSIF M IS MenuViewers.ModifyMsg THEN
      F.Y := M(MenuViewers.ModifyMsg).Y; F.H := M(MenuViewers.ModifyMsg).H; Redraw(F(Frame))
    ELSIF M IS Oberon.ControlMsg THEN
      IF M(Oberon.ControlMsg).id = Oberon.neutralize THEN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H) END
    ELSIF M IS Oberon.CopyMsg THEN
      NEW(F0); F0^ := F^; M(Oberon.CopyMsg).F := F0
    END
  END Handler;

  PROCEDURE New*(): Frame;
    VAR F!: Frame;
  BEGIN NEW(F); F.handle := Handler; RETURN F
  END New;

  PROCEDURE Start*(F: Frame; t: ARRAY OF CHAR);
    VAR V!: Viewers.Viewer; X, Y: INTEGER;
  BEGIN Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(TextFrames.NewMenu(t, Menu), F, TextFrames.menuH, X, Y)
  END Start;

  PROCEDURE SetSetupProc*(F: Frame; p: PROCEDURE);
  BEGIN F.SetupProc := p
  END SetSetupProc;

  PROCEDURE SetDrawProc*(F: Frame; p: PROCEDURE);
  BEGIN F.DrawProc := p
  END SetDrawProc;

  PROCEDURE SetPressedProc*(F: Frame; p: PROCEDURE);
  BEGIN F.PressedProc := p
  END SetPressedProc;

END JDraw.
