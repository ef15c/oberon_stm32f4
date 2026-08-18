MODULE JDraw; (*Raw drawing primitives*)
  IMPORT Display, Input, Viewers, Texts, Oberon, MenuViewers, TextFrames;

  CONST Menu = "System.Close";

  TYPE
    Frame* = POINTER TO FrameDesc;
    Callback = PROCEDURE(F: Frame);
    FrameDesc* = RECORD(Display.FrameDesc)
      col, bcol: BYTE; x0, y0: INTEGER;
      SetupProc, DrawProc, FormDraw, PressedProc: Callback
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
      F.DrawProc(F);
      IF F.FormDraw # NIL THEN F.FormDraw(F) END
    END
  END Redraw;

  PROCEDURE Point*(F: Frame; x0, y0: REAL);
    VAR x, y: INTEGER;
  BEGIN x := ROUND(x0) + F.x0; y := ROUND(y0) + F.y0;
    IF (x >= 0) & (x < F.W) & (y >= 0) & (y < F.H) THEN Display.Dot(F.col, F.X + x, F.Y + y, Display.paint) END
  END Point;

  PROCEDURE Handler(F: Display.Frame; VAR M: Display.FrameMsg);
    VAR F0!: Display.Frame; keys: SET; X, Y, Z: INTEGER;
  BEGIN
    IF M IS Oberon.InputMsg THEN
      IF M(Oberon.InputMsg).id = Oberon.track THEN
        Oberon.DrawMouseArrow(M(Oberon.InputMsg).X, M(Oberon.InputMsg).Y);
        keys := M(Oberon.InputMsg).keys;
        IF keys # {} THEN REPEAT Input.Mouse(keys, X, Y, Z) UNTIL keys = {};
        F(Frame).PressedProc(F(Frame)) END
      END
    ELSIF M IS MenuViewers.ModifyMsg THEN
      F.Y := M(MenuViewers.ModifyMsg).Y; F.H := M(MenuViewers.ModifyMsg).H; Redraw(F(Frame))
    ELSIF M IS Oberon.ControlMsg THEN
      IF M(Oberon.ControlMsg).id = Oberon.neutralize THEN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H) END
    ELSIF M IS Oberon.CopyMsg THEN
      NEW(F0); F0^ := F^; M(Oberon.CopyMsg).F := F0
    END
  END Handler;

  PROCEDURE Start*(F: Frame; t: ARRAY OF CHAR);
    VAR V!: Viewers.Viewer; X, Y: INTEGER;
  BEGIN F.handle := Handler;
    Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(TextFrames.NewMenu(t, Menu), F, TextFrames.menuH, X, Y)
  END Start;

  PROCEDURE SetSetupProc*(F: Frame; p: Callback);
  BEGIN F.SetupProc := p
  END SetSetupProc;

  PROCEDURE SetDrawProc*(F: Frame; p: Callback);
  BEGIN F.DrawProc := p
  END SetDrawProc;

  PROCEDURE SetPressedProc*(F: Frame; p: Callback);
  BEGIN F.PressedProc := p
  END SetPressedProc;

END JDraw.
