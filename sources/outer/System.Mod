MODULE System; (*JG 3.10.90 / NW 12.10.93 / NW 20.6.2016 / CS 19/12/2023*)
  IMPORT SYSTEM, BSP, SDCard, Kernel, FileDir, Files, Modules,
    Input, Display, Viewers, Fonts, Texts, Oberon, MenuViewers, TextFrames;

  CONST
    StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store";
    LogMenu = "Edit.Locate System.Copy System.Grow System.Clear Edit.Store";
    
    ABORTKEY = 2; (*Reserved in CFSR*)

    (*To improve readability*)
    CFSR = BSP.SCB_BASE + BSP.CFSR; ICSR = BSP.SCB_BASE + BSP.ICSR; BFAR = BSP.SCB_BASE + BSP.BFAR;
    NOCP = BSP.NOCP; INVSTATE = BSP.INVSTATE; STKERR = BSP.STKERR; PRECISERR = BSP.PRECISERR;
    PENDSVSET = BSP.PENDSVSET;
    UFSR_Mask = BSP.UFSR_Mask; BFSR_Mask = BSP.BFSR_Mask;

    PR = BSP.EXTI_BASE + BSP.PR;

  TYPE
    StackDumpDesc* = RECORD
      cause*: BYTE;
      cfsr*: SET; bfar*, eos*, PC*, LR*: INTEGER;
      len*: INTEGER;
      stack*: ARRAY 10000H DIV 4 OF INTEGER
    END;
    StackDump* = POINTER TO StackDumpDesc;

  VAR W: Texts.Writer;
    pat: ARRAY 32 OF CHAR;
    TrappedAdr: INTEGER; cfsr: SET;
    stack*: StackDump;
    modBase: INTEGER;

  PROCEDURE GetArg(VAR S: Texts.Scanner);
    VAR T!: Texts.Text; beg, end, time: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END
  END GetArg;

  PROCEDURE EndLine;
  BEGIN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END EndLine;

  (* ------------- Toolbox for system control ---------------*)

  PROCEDURE SetUser*;
    VAR i: INTEGER; ch: CHAR;
      user: ARRAY 8 OF CHAR;
      password: ARRAY 16 OF CHAR;
  BEGIN i := 0; Input.Read(ch);
    WHILE (ch # "/") & (i < 7) DO user[i] := ch; INC(i); Input.Read(ch) END;
    user[i] := 0X; i := 0; Input.Read(ch);
    WHILE (ch > " ") & (i < 15) DO password[i] := ch; INC(i); Input.Read(ch) END;
    password[i] := 0X; Oberon.SetUser(user, password)
  END SetUser;

  PROCEDURE SetFont*;
    VAR S!: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN Oberon.SetFont(Fonts.This(S.s)) END
  END SetFont;

  PROCEDURE SetColor*;
    VAR S!: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN Oberon.SetColor(S.i) END
  END SetColor;

  PROCEDURE SetOffset*;
    VAR S!: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN Oberon.SetOffset(S.i) END
  END SetOffset;

  PROCEDURE DisplayDate*;
    VAR dt: INTEGER;
  BEGIN  Texts.WriteString(W, "System.Clock");
    dt := Oberon.Clock(); Texts.WriteClock(W, dt); EndLine
  END DisplayDate;

  PROCEDURE Date*;
    VAR S!: Texts.Scanner;
      dt, hr, min, sec, yr, mo, day: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN (*set clock*)
      day := S.i; Texts.Scan(S); mo := S.i; Texts.Scan(S); yr := S.i; Texts.Scan(S);
      hr := S.i; Texts.Scan(S); min := S.i; Texts.Scan(S); sec := S.i;
      dt := ((((yr*16 + mo)*32 + day)*32 + hr)*64 + min)*64 + sec;
      Kernel.SetClock(dt)
    ELSE (*read clock*) DisplayDate
    END
  END Date;

  PROCEDURE Collect*;
  BEGIN Oberon.Collect(0)
  END Collect;

  (* ------------- Toolbox for standard display ---------------*)

  PROCEDURE Open*;  (*open viewer in system track*)
    VAR X, Y: INTEGER;
      V!: Viewers.Viewer;
      S!: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
      V := MenuViewers.New(
        TextFrames.NewMenu(S.s, StandardMenu),
        TextFrames.NewText(TextFrames.Text(S.s), 0), TextFrames.menuH, X, Y)
    END
  END Open;

  PROCEDURE Clear*;  (*clear Log*)
    VAR T!: Texts.Text; F!: Display.Frame; buf!: Texts.Buffer;
  BEGIN F := Oberon.Par.frame;
    IF (F # NIL) & (F.next IS TextFrames.Frame) & (F = Oberon.Par.vwr.dsc) THEN
      NEW(buf); Texts.OpenBuf(buf); T := F.next(TextFrames.Frame).text; Texts.Delete(T, 0, T.len, buf)
    END
  END Clear;

  PROCEDURE Close*;
    VAR V!: Viewers.Viewer;
  BEGIN
    IF Oberon.Par.frame = Oberon.Par.vwr.dsc THEN V := Oberon.Par.vwr
    ELSE V := Oberon.MarkedViewer()
    END;
    Viewers.Close(V)
  END Close;

  PROCEDURE CloseTrack*;
    VAR V!: Viewers.Viewer;
  BEGIN V := Oberon.MarkedViewer(); Viewers.CloseTrack(V.X)
  END CloseTrack;

  PROCEDURE Recall*;
    VAR V!: Viewers.Viewer; M: Viewers.ViewerMsg;
  BEGIN Viewers.Recall(V);
    IF (V#NIL) & (V.state = 0) THEN
      Viewers.Open(V, V.X, V.Y + V.H); M.id := Viewers.restore; V.handle(V, M)
    END
  END Recall;

  PROCEDURE Copy*;
    VAR V!, V1!: Viewers.Viewer; M!: Oberon.CopyMsg; N: Viewers.ViewerMsg;
  BEGIN V := Oberon.Par.vwr; V.handle(V, M); V1 := M.F(Viewers.Viewer);
    Viewers.Open(V1, V.X, V.Y + V.H DIV 2);
    N.id := Viewers.restore; V1.handle(V1, N)
  END Copy;

  PROCEDURE Grow*;
    VAR V!, V1!: Viewers.Viewer; M!: Oberon.CopyMsg; N: Viewers.ViewerMsg;
      DW, DH: INTEGER;
  BEGIN V := Oberon.Par.vwr;
    DW := Oberon.DisplayWidth(V.X); DH := Oberon.DisplayHeight(V.X);
    IF V.H < DH - Viewers.minH THEN Oberon.OpenTrack(V.X, V.W)
    ELSIF V.W < DW THEN Oberon.OpenTrack(Oberon.UserTrack(V.X), DW)
    END;
    IF (V.H < DH - Viewers.minH) OR (V.W < DW) THEN
      V.handle(V, M); V1 := M.F(Viewers.Viewer);
      Viewers.Open(V1, V.X, DH);;
      N.id := Viewers.restore; V1.handle(V1, N)
    END
  END Grow;

  (* ------------- Toolbox for module management ---------------*)

  PROCEDURE Free1(VAR S: Texts.Scanner);
  BEGIN Texts.WriteString(W, S.s); Texts.WriteString(W, " unloading");
    Modules.Free(S.s);
    IF Modules.res # 0 THEN Texts.WriteString(W, " failed") END;
    EndLine
  END Free1;

  PROCEDURE Free*;
    VAR T!: Texts.Text;
      beg, end, time: INTEGER;
      S!: Texts.Scanner;
  BEGIN Texts.WriteString(W, "System.Free"); EndLine;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S);
        IF S.class = Texts.Name THEN Free1(S) END
      END
    ELSE
      WHILE S.class = Texts.Name DO Free1(S); Texts.Scan(S) END
    END ;
    Oberon.Collect(0)
  END Free;

  PROCEDURE FreeFonts*;
  BEGIN Texts.WriteString(W, "System.FreeFonts"); Fonts.Free; EndLine
  END FreeFonts;

  (* ------------- Toolbox of file system ---------------*)

  PROCEDURE List(name: FileDir.FileName; adr: INTEGER; VAR cont: BOOLEAN);
    VAR i0, i, j0, j: INTEGER; hp: FileDir.FileHeader;
  BEGIN
    i := 0;
    WHILE (pat[i] > "*") & (pat[i] = name[i]) DO INC(i) END ;
    IF (pat[i] = 0X) & (name[i] = 0X) THEN i0 := i; j0 := i
    ELSIF pat[i] = "*" THEN
      i0 := i; j0 := i+1;
      WHILE name[i0] # 0X DO
        i := i0; j := j0;
        WHILE (name[i] # 0X) & (name[i] = pat[j]) DO INC(i); INC(j) END ;
        IF pat[j] = 0X THEN
          IF name[i] = 0X THEN (*match*) j0 := j ELSE INC(i0) END
        ELSIF pat[j] = "*" THEN i0 := i; j0 := j+1
        ELSE INC(i0)
        END
      END
    END ;
    IF (name[i0] = 0X) & (pat[j0] = 0X) THEN (*found*)
      Texts.WriteString(W, name);
      IF pat[j0+1] = "!" THEN (*option*)
        Kernel.GetSector(adr, hp);
        Texts.Write(W, 9X); Texts.WriteClock(W, hp.date);
        Texts.WriteInt(W, hp.aleng*FileDir.SectorSize + hp.bleng - FileDir.HeaderSize, 8); (*length*)
        (*Texts.WriteHex(W, adr)*)
      END ;
      Texts.WriteLn(W)
    END
  END List;

  PROCEDURE Directory*;
    VAR X, Y, i: INTEGER; ch: CHAR;
      R!: Texts.Reader;
      T!, t!: Texts.Text;
      V!: Viewers.Viewer;
      beg, end, time: INTEGER;
      pre: ARRAY 32 OF CHAR;
  BEGIN Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos); Texts.Read(R, ch);
    WHILE ch = " " DO Texts.Read(R, ch) END;
    IF (ch = "^") OR (ch = 0DX) THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN
        Texts.OpenReader(R, T, beg); Texts.Read(R, ch);
        WHILE ch <= " " DO Texts.Read(R, ch) END
      END
    END ;
    i := 0;
    WHILE ch > "!" DO pat[i] := ch; INC(i); Texts.Read(R, ch) END;
    pat[i] := 0X;
    IF ch = "!" THEN pat[i+1] := "!" END ;  (*directory option*)
    i := 0;
    WHILE pat[i] > "*" DO pre[i] := pat[i]; INC(i) END;
    pre[i] := 0X;
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y); t := TextFrames.Text("");
    V := MenuViewers.New(
      TextFrames.NewMenu("System.Directory", StandardMenu),
      TextFrames.NewText(t, 0), TextFrames.menuH, X, Y);
    FileDir.Enumerate(pre, List); Texts.Append(t, W.buf)
  END Directory;

  PROCEDURE CopyFiles*;
    VAR f!, g!: Files.File; Rf!, Rg!: Files.Rider; ch: CHAR;
      name: ARRAY 32 OF CHAR;
      S!: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.CopyFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      name := S.s; Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.c = "=") THEN Texts.Scan(S);
        IF (S.class = Texts.Char) & (S.c = ">") THEN Texts.Scan(S);
          IF S.class = Texts.Name THEN
            Texts.WriteString(W, name); Texts.WriteString(W, " => "); Texts.WriteString(W, S.s);
            Texts.WriteString(W, " copying"); Texts.Append(Oberon.Log, W.buf);
            f := Files.Old(name);
            IF f # NIL THEN g := Files.New(S.s);
              Files.Set(Rf, f, 0); Files.Set(Rg, g, 0); Files.Read(Rf, ch);
              WHILE ~Rf.eof DO Files.Write(Rg, ch); Files.Read(Rf, ch) END;
              Files.Register(g)
            ELSE Texts.WriteString(W, " failed")
            END ;
            EndLine
          END
        END
      END ;
      Texts.Scan(S)
    END
  END CopyFiles;

  PROCEDURE CompareFiles*;
    VAR f!, g!: Files.File; Rf!, Rg!: Files.Rider; chf, chg: CHAR;
      name: ARRAY 32 OF CHAR;
      S!: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.CompareFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      name := S.s; Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.c = "=") THEN Texts.Scan(S);
        IF S.class = Texts.Name THEN
          Texts.WriteString(W, name); Texts.WriteString(W, " and "); Texts.WriteString(W, S.s);
          Texts.WriteString(W, " comparing"); Texts.Append(Oberon.Log, W.buf);
          f := Files.Old(name);
          IF f # NIL THEN g := Files.Old(S.s);
            IF g # NIL THEN Files.Set(Rf, f, 0); Files.Set(Rg, g, 0); Files.Read(Rf, chf); Files.Read(Rg, chg);
              WHILE (chf = chg) & ~Rf.eof & ~Rg.eof DO Files.Read(Rf, chf); Files.Read(Rg, chg) END;
              IF ~Rf.eof OR ~Rg.eof THEN Texts.WriteString(W, " different at pos "); Texts.WriteInt(W, Files.Pos(Rf)-1, 1)
              ELSE Texts.WriteString(W, " same")
              END
            ELSE Texts.WriteString(W, " failed "); Texts.WriteString(W, S.s);  Texts.WriteString(W, " not found")
            END
          ELSE Texts.WriteString(W, " failed "); Texts.WriteString(W, name);  Texts.WriteString(W, " not found")
          END;
          EndLine
        END
      END ;
      Texts.Scan(S)
    END
  END CompareFiles;

  PROCEDURE RenameFiles*;
    VAR res: INTEGER;
      name: ARRAY 32 OF CHAR;
      S!: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.RenameFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      name := S.s; Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.c = "=") THEN Texts.Scan(S);
        IF (S.class = Texts.Char) & (S.c = ">") THEN Texts.Scan(S);
          IF S.class = Texts.Name THEN
            Texts.WriteString(W, name); Texts.WriteString(W, " => "); Texts.WriteString(W, S.s);
            Texts.WriteString(W, " renaming"); Files.Rename(name, S.s, res);
            IF res > 1 THEN Texts.WriteString(W, " failed") END;
            EndLine
          END
        END
      END ;
      Texts.Scan(S)
    END
  END RenameFiles;

  PROCEDURE DeleteFiles*;
    VAR res: INTEGER; S!: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.DeleteFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      Texts.WriteString(W, S.s); Texts.WriteString(W, " deleting");
      Files.Delete(S.s, res);
      IF res # 0 THEN Texts.WriteString(W, " failed") END;
      EndLine; Texts.Scan(S)
    END
  END DeleteFiles;

  (* ------------- Toolbox for system inspection ---------------*)

  PROCEDURE Watch*;
    VAR modUsed, size: INTEGER;
  BEGIN Texts.WriteString(W, "System.Watch"); Texts.WriteLn(W);
    modUsed := Modules.AllocPtr - modBase;
    Texts.WriteString(W, "  Modules space (bytes)"); Texts.WriteInt(W, modUsed, 8);
    size := Kernel.heapOrg - modBase;
    Texts.WriteInt(W, (modUsed * 100 + size DIV 2) DIV size, 4); Texts.Write(W, "%"); EndLine;
    Texts.WriteString(W, "  Heap space"); Texts.WriteInt(W, Kernel.allocated, 8);
    size := Kernel.heapLim - Kernel.heapOrg;
    Texts.WriteInt(W, (Kernel.allocated * 100 + size DIV 2) DIV size, 4); Texts.Write(W, "%"); EndLine;
    Texts.WriteString(W, "  Disk sectors "); Texts.WriteInt(W, Kernel.NofSectors, 4);
    Texts.WriteInt(W, Kernel.NofSectors * 100 DIV 10000H, 4); Texts.WriteString(W, "%, read errors "); Texts.WriteInt(W, SDCard.hsd.readErrors, 1);
    Texts.WriteString(W, ", write errors "); Texts.WriteInt(W, SDCard.hsd.writeErrors, 1); Texts.WriteString(W, ", unrecoverable ");
    Texts.WriteInt(W, SDCard.hsd.unrecoverableErrors, 1); EndLine;
    Texts.WriteString(W, "  Tasks"); Texts.WriteInt(W, Oberon.NofTasks, 4); EndLine;
    Texts.WriteString(W, "  MSP high water mark   "); Texts.WriteHex(W, Kernel.SPHWM); EndLine
  END Watch;

  PROCEDURE ShowModules*;
    VAR T!: Texts.Text;
      V!: Viewers.Viewer;
      M!: Modules.Module;
      X, Y: INTEGER;
  BEGIN T := TextFrames.Text("");
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(TextFrames.NewMenu("System.ShowModules", StandardMenu),
        TextFrames.NewText(T, 0), TextFrames.menuH, X, Y);
    M := Modules.root;
    WHILE M # NIL DO
      IF M.name[0] # 0X THEN
        Texts.WriteString(W, M.name); Texts.Write(W, 9X); Texts.WriteHex(W, ORD(M));
        Texts.WriteHex(W, M.code); Texts.WriteInt(W, M.refcnt, 4)
      ELSE Texts.WriteString(W, "---")
      END ;
      Texts.WriteLn(W); M := M.next
    END;
    Texts.Append(T, W.buf)
  END ShowModules;

  PROCEDURE ShowCommands*;
    VAR M!: Modules.Module;
      comadr: INTEGER; ch: CHAR;
      T!: Texts.Text;
      S!: Texts.Scanner;
      V!: Viewers.Viewer;
      X, Y: INTEGER;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      Modules.Load(S.s, M);
      IF M # NIL THEN
        Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y); T := TextFrames.Text("");
        V := MenuViewers.New(TextFrames.NewMenu("System.Commands", StandardMenu),
            TextFrames.NewText(T, 0), TextFrames.menuH, X, Y);
        comadr := M.cmd; SYSTEM.GET(comadr, ch); INC(comadr);
        WHILE ch # 0X DO
          Texts.WriteString(W, S.s); Texts.Write(W, ".");
          REPEAT Texts.Write(W, ch); SYSTEM.GET(comadr, ch); INC(comadr)
          UNTIL ch = 0X;
          WHILE comadr MOD 4 # 0 DO INC(comadr) END ;
          Texts.WriteLn(W); INC(comadr, 4); SYSTEM.GET(comadr, ch); INC(comadr)
        END ;
        Texts.Append(T, W.buf)
      END
    END
  END ShowCommands;

  PROCEDURE ShowFonts*;
    VAR fnt!: Fonts.Font;
  BEGIN Texts.WriteString(W, "System.ShowFonts"); Texts.WriteLn(W); fnt := Fonts.root;
    WHILE fnt # NIL DO
      Texts.Write(W, 9X); Texts.WriteString(W, fnt.name); Texts.WriteLn(W); fnt := fnt.next
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END ShowFonts;

  PROCEDURE OpenViewers;
    VAR logV!, toolV!: Viewers.Viewer;
      menu!, main!: Display.Frame;
      X, Y: INTEGER;
  BEGIN Texts.WriteString(W, "Oberon V5  NW 14.4.2013 / CS 04.02.25"); EndLine;
    Oberon.AllocateSystemViewer(0, X, Y);
    menu := TextFrames.NewMenu("System.Log", LogMenu);
    main := TextFrames.NewText(Oberon.Log, 0);
    logV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y);
    Oberon.AllocateSystemViewer(0, X, Y);
    menu := TextFrames.NewMenu("System.Tool", StandardMenu);
    main := TextFrames.NewText(TextFrames.Text("System.Tool"), 0);
    toolV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y)
  END OpenViewers;

  PROCEDURE ExtendDisplay*;
    VAR V!: Viewers.Viewer;
      X, Y, DX, DW, DH: INTEGER;
      S!: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      DX := Viewers.curW; DW := Oberon.DisplayWidth(DX); DH := Oberon.DisplayHeight(DX);
      Oberon.OpenDisplay(DW DIV 8 * 5, DW DIV 8 * 3, DH);
      Oberon.AllocateSystemViewer(DX, X, Y);
      V := MenuViewers.New(
        TextFrames.NewMenu(S.s, StandardMenu),
        TextFrames.NewText(TextFrames.Text(S.s), 0),
        TextFrames.menuH, X, Y)
    END
  END ExtendDisplay;

  PROCEDURE* Trap(VAR f: Kernel.ExceptionFrameDesc);
    VAR icsr: SET; w, inst: INTEGER;
  BEGIN
    SYSTEM.GET(CFSR, cfsr);
    IF NOCP IN cfsr THEN (*Trap*)
      SYSTEM.GET(f.returnAddress, inst);
      w := inst DIV 10000H MOD 10H;
    ELSIF INVSTATE IN cfsr THEN w := 5 (*probably illegal procedure call*)
    END;
    IF w = 5 THEN TrappedAdr := f.lr ELSE TrappedAdr := f.returnAddress END;
    (*Trigger abort by requesting a PendSV interrupt*)
    IF cfsr - {NOCP, INVSTATE} # {} THEN (*other fault*)
      BSP.led(127); REPEAT UNTIL FALSE (*Other faults need debugging*)
    END;
    SYSTEM.GET(ICSR, icsr); INCL(icsr, PENDSVSET); SYSTEM.PUT(ICSR, icsr); SYSTEM.MBI(3); (*ISB*)
    SYSTEM.PUT(CFSR, cfsr*UFSR_Mask); (*reset UFSR flags*) Kernel.setSPHWM
  END Trap;

  PROCEDURE* BusFaultHandler(VAR f: Kernel.ExceptionFrameDesc);
    VAR icsr: SET; w, inst: INTEGER;
  BEGIN SYSTEM.GET(CFSR, cfsr);
    IF PRECISERR IN cfsr THEN SYSTEM.GET(BFAR, stack.bfar) END;
    IF ~(STKERR IN cfsr) THEN TrappedAdr := f.returnAddress 
    ELSIF PRECISERR IN cfsr THEN TrappedAdr := stack.bfar
    END;
    (*Trigger abort by requesting a PendSV interrupt*)
    SYSTEM.GET(ICSR, icsr); INCL(icsr, PENDSVSET); SYSTEM.PUT(ICSR, icsr); SYSTEM.MBI(3); (*ISB*)
    SYSTEM.PUT(CFSR, cfsr*BFSR_Mask); (*reset BFSR flags*) Kernel.setSPHWM
  END BusFaultHandler;

  (*Handle abort key press*)
  PROCEDURE* AbortHandler(VAR f: Kernel.ExceptionFrameDesc);
    VAR icsr: SET;
  BEGIN cfsr := {ABORTKEY}; TrappedAdr := f.returnAddress;
    (*Trigger abort by requesting a PendSV interrupt*)
    SYSTEM.GET(ICSR, icsr); INCL(icsr, PENDSVSET); SYSTEM.PUT(ICSR, icsr); SYSTEM.MBI(3); (*ISB*)
    SYSTEM.PUT(PR, {BSP.B1Pin}); (* Clear pending IRQ*) Kernel.setSPHWM
  END AbortHandler;

  PROCEDURE Reset;
    VAR inst, w, i: INTEGER; code: INTEGER; mod!: Modules.Module;
  BEGIN
    IF NOCP IN cfsr THEN (*Trap*)      
      SYSTEM.GET(TrappedAdr, inst);
      inst := inst DIV 100H MOD 100H*1000000H
        + inst MOD 100H*10000H
        + inst DIV 1000000H MOD 100H*100H
        + inst DIV 10000H MOD 100H; (*thumb swap*)

      w := inst MOD 10H;
      inst := inst DIV 10H; (*inst contains 1110/110p/pppp/pppp/pppp/0ppp/pppp*)
      inst := (inst DIV 100H*80H + inst MOD 80H) MOD 100000H;
      Texts.WriteLn(W); Texts.WriteString(W, "  pos "); Texts.WriteInt(W, inst, 4)
    ELSIF INVSTATE IN cfsr THEN w := 5 (*probably illegal procedure call*)
    ELSIF STKERR IN cfsr THEN w := 9; (*Bus Fault: stack overflow*)
      (*trying to find nearest return adress*) i := 0;
      REPEAT TrappedAdr := stack.stack[i] - 1; INC(i) UNTIL ((TrappedAdr >= modBase) & (TrappedAdr < Modules.AllocPtr)) OR (i >= stack.len);
      IF i >=  stack.len THEN TrappedAdr := 0 END
    ELSIF PRECISERR IN cfsr THEN w := 8 (*Bus Fault: data access precise error*)
    ELSIF ABORTKEY IN cfsr THEN w := 10 (*User pressed the abort key*)
    ELSE w := 11 (*TODO Fault to be characterized*)
    END;
    Texts.WriteString(W, "  TRAP"); Texts.WriteInt(W, w, 4);
    IF TrappedAdr # 0 THEN
      code := 0; mod := Modules.root;
      WHILE (mod # NIL) & ((mod.name[0] = 0X) OR (TrappedAdr < mod.code) OR (TrappedAdr >= mod.imp)) DO mod := mod.next END ;
      IF mod # NIL THEN code := mod.code; Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name) END ;
      Texts.WriteString(W, " at"); Texts.WriteHex(W, TrappedAdr - code);
      stack.PC := TrappedAdr; TrappedAdr := 0
    END; stack.cause := w; Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); cfsr := {}; Oberon.Reset
  END Reset;
  
  PROCEDURE* PendSVHandler(cf: Kernel.ExceptionFrame);
  (*Abort current command by resetting stack and reentering the main loop*)
    CONST LR = 14; PSP=16+9;
    VAR f!: Kernel.ExceptionFrame;
      lr: SET; sz: INTEGER;
  BEGIN
    lr := SYSTEM.VAL(SET, SYSTEM.REG(LR)); IF 4 IN lr THEN sz := 20H ELSE sz := 68H END;
    IF ORD(lr*{0..3}) = 0DH THEN (*return to thread mode with process stack*)
      (*dump the stack*) stack.cfsr := cfsr;
      IF ~(PRECISERR IN cfsr) THEN stack.bfar := 0 END;
      IF STKERR IN cfsr THEN (*stack overflow*) stack.eos := 10000000H; stack.LR := 0FFFFFFFFH;
      ELSE stack.eos := SYSTEM.VAL(INTEGER, cf) + sz; stack.LR := cf.lr; IF 9 IN SYSTEM.VAL(SET, cf.xpsr) THEN (*stack was realigned*) INC(stack.eos, 4) END
      END; stack.len := (10010000H - stack.eos) DIV 4;
      IF (stack.eos < 10010000H) & (stack.len <= 10000H DIV 4) THEN SYSTEM.COPY(stack.eos, SYSTEM.ADR(stack.stack), stack.len) END;
      Kernel.setSPHWM;
      (*build exception frame*)
      f := SYSTEM.VAL(Kernel.ExceptionFrame, 10010000H - sz);
      f.r0 := 0; f.r1 := 0; f.r2 := 0; f.r3 := 0; f.r12 := 0; f.lr := 0FFFFFFFFH; f.returnAddress := SYSTEM.ADR(Reset);
      f.xpsr := 01000000H; (*Bit 24 as 1 to indicate thumb mode*)
      SYSTEM.LDREG(PSP, SYSTEM.VAL(INTEGER, f)); SYSTEM.MBI(3) (*ISB*)
    END
  END PendSVHandler;

  PROCEDURE installAbortHandler;
    VAR reg: SET; irqNum: INTEGER;
  BEGIN Kernel.Install(SYSTEM.ADR(AbortHandler), BSP.VecTabBase+BSP.B1ExtiIrqNum*4);
    Kernel.EnableAbortHandler
  END installAbortHandler;

  PROCEDURE activateHandlers;
    VAR reg: SET;
  BEGIN
    SYSTEM.GET(BSP.SCB_BASE + BSP.SHCSR, reg); (*enable usage fault and bus fault exceptions*)
    SYSTEM.PUT(BSP.SCB_BASE + BSP.SHCSR, reg + {BSP.USGFAULTENA, BSP.BUSFAULTENA});
  END activateHandlers;

BEGIN SYSTEM.GET(Kernel.bootParams+16, modBase);
  Texts.OpenWriter(W);
  Oberon.OpenLog(TextFrames.Text("")); OpenViewers;
  Kernel.Install(SYSTEM.ADR(Trap), BSP.VecTabBase+BSP.UsageFaultExcNum*4);
  Kernel.Install(SYSTEM.ADR(BusFaultHandler), BSP.VecTabBase+BSP.BusFaultExcNum*4);
  installAbortHandler;
  Kernel.Install(SYSTEM.ADR(PendSVHandler), BSP.VecTabBase+BSP.PendSVExcNum*4);
  activateHandlers;
  stack := SYSTEM.VAL(StackDump, (*20000600H*) 0D0110000H); stack.len := 0; stack.cause := 0;
  stack.cfsr := {}; stack.bfar := 0; stack.eos := 0; stack.PC := 0; stack.LR := 0
END System.
