MODULE DynMenu;
  IMPORT Display, Viewers, Texts, Oberon, MenuViewers, TextFrames;

  VAR end: INTEGER; buf: Texts.Buffer; W: Texts.Writer;

  PROCEDURE Restore(F: Display.Frame);
  BEGIN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);
    Display.ReplConst(Display.black, F.X, F.Y, F.W, F.H, Display.replace); (*clear*)
  END Restore;

  PROCEDURE Handle(G: Display.Frame; VAR M: Display.FrameMsg);
    VAR G1!: Display.Frame;
  BEGIN
    CASE G OF Display.Frame:
      CASE M OF
      Oberon.InputMsg:
        IF M.id = Oberon.track THEN Oberon.DrawMouseArrow(M.X, M.Y) END |
      Oberon.CopyMsg:
        Oberon.RemoveMarks(G.X, G.Y, G.W, G.H); NEW(G1); G1^ := G^; M.F := G1 |
      MenuViewers.ModifyMsg:
        IF (M.Y # G.Y) OR (M.H # G.H) THEN G.Y := M.Y; G.H := M.H; Restore(G) END
      END
    END
  END Handle;

  PROCEDURE Open*;
    VAR F!: Display.Frame; V!: Viewers.Viewer; X, Y: INTEGER; M!: TextFrames.Frame;
  BEGIN NEW(F); F.handle := Handle;
    Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    M := TextFrames.NewMenu("Dynamic menu", "System.Close System.Copy System.Grow DynMenu.Start");
    V := MenuViewers.New(M, F, TextFrames.menuH, X, Y);
    end := M.text.len
  END Open;

  PROCEDURE Start*;
    VAR F!: TextFrames.Frame; T!: Texts.Text;
  BEGIN F := Oberon.Par.frame(TextFrames.Frame); T := F.text;
    Texts.Delete(T, end, T.len, buf); Texts.WriteString(W, " DynMenu.M1");
    Texts.Append(T, W.buf)
  END Start;

  PROCEDURE M1*;
    VAR F!: TextFrames.Frame; T!: Texts.Text;
  BEGIN F := Oberon.Par.frame(TextFrames.Frame); T := F.text;
    Texts.Delete(T, end, T.len, buf); Texts.WriteString(W, " DynMenu.M2");
    Texts.Append(T, W.buf)
  END M1;

PROCEDURE M2*;
    VAR F!: TextFrames.Frame; T!: Texts.Text;
  BEGIN F := Oberon.Par.frame(TextFrames.Frame); T := F.text;
    Texts.Delete(T, end, T.len, buf); Texts.WriteString(W, " DynMenu.M1");
    Texts.Append(T, W.buf)
END M2;


BEGIN NEW(buf); Texts.OpenBuf(buf); Texts.OpenWriter(W); W.col := Display.yellow
END DynMenu.

OM4P.Compile DynMenu.Mod/s~
System.Free DynMenu~
DynMenu.Open
