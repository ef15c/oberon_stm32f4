MODULE Oberon; (*JG 6.9.90 / 23.9.93 / 13.8.94 / NW 14.4.2013 / 22.12.2015
  CS 20/12/2023*)
  IMPORT SYSTEM, BSP, PS2, Kernel, Files, Modules, Input, Display, Viewers, Fonts, Texts;

  CONST (*message ids*)
    consume* = 0; track* = 1; defocus* = 0; neutralize* = 1; mark* = 2;
    off = 0; idle = 1; active = 2;   (*task states*)
    BasicCycle = 20;
    ESC = 1BX; SETSTAR = 1AX;
    PR = BSP.EXTI_BASE + BSP.PR;

  TYPE Painter* = PROCEDURE (x, y: INTEGER);
    Marker* = RECORD Fade*, Draw*: Painter END;
    
    Cursor* = RECORD
        marker*: Marker; on*: BOOLEAN; X*, Y*: INTEGER
    END;

    InputMsg* = RECORD (Display.FrameMsg)
      id*: INTEGER;
      keys*: SET;
      X*, Y*, Z*: INTEGER;
      ch*: CHAR;
      fnt*: Fonts.Font;
      col*, voff*: INTEGER
    END;

    SelectionMsg* = RECORD (Display.FrameMsg)
      time*: INTEGER;
      text*: Texts.Text;
      beg*, end*: INTEGER
    END;

    ControlMsg* = RECORD (Display.FrameMsg)
      id*, X*, Y*: INTEGER
    END;

    CopyMsg* = RECORD (Display.FrameMsg)
      F*: Display.Frame
    END;

    Task* = POINTER TO TaskDesc;

    Handler* = PROCEDURE;

    TaskDesc* = RECORD
      state, nextTime, period*: INTEGER;
      next: Task;
      handle: Handler
    END;

  VAR User*: ARRAY 8 OF CHAR; Password*: INTEGER;
    Arrow*, Star*: Marker;
    Mouse, Pointer: Cursor;
    FocusViewer*: Viewers.Viewer;
    Log*: Texts.Text;

    Par*: RECORD
      vwr*: Viewers.Viewer;
      frame*: Display.Frame;
      text*: Texts.Text;
      pos*: INTEGER
    END;

    CurFnt*: Fonts.Font;
    CurCol*, CurOff*: INTEGER;
    NofTasks*: INTEGER;

    CurTask: Task;
    DW, DH, CL: INTEGER;
    ActCnt: INTEGER; (*action count for GC*)
    Mod: Modules.Module;

    ps2: ARRAY 2 OF PS2.DeviceDesc;

    prevZ: INTEGER;

  (*user identification*)

  PROCEDURE Code(VAR s: ARRAY OF CHAR): INTEGER;
    VAR i: INTEGER; a, b, c: INTEGER;
  BEGIN
    a := 0; b := 0; i := 0;
    WHILE s[i] # 0X DO
      c := b; b := a; a := (c MOD 509 + 1) * 127 + ORD(s[i]);
      INC(i)
    END;
    IF b >= 32768 THEN b := b - 65536 END;
    RETURN b * 65536 + a
  END Code;

  PROCEDURE SetUser* (VAR user, password: ARRAY OF CHAR);
  BEGIN User := user; Password := Code(password)
  END SetUser;

  PROCEDURE Clock*(): INTEGER;
  BEGIN RETURN Kernel.Clock()
  END Clock;

  PROCEDURE SetClock* (d: INTEGER);
  BEGIN Kernel.SetClock(d)
  END SetClock;

  PROCEDURE Time*(): INTEGER;
  BEGIN RETURN Kernel.Time()
  END Time;

  (*cursor handling*)

  PROCEDURE FlipArrow (X, Y: INTEGER);
  BEGIN
    IF X < CL THEN
      IF X > DW - 15 THEN X := DW - 15 END
    ELSE
      IF X > CL + DW - 15 THEN X := CL + DW - 15 END
    END;
    IF Y < 14 THEN Y := 14 ELSIF Y > DH THEN Y := DH END;
    Display.CopyPattern(Display.white, Display.arrow, X, Y - 14, Display.invert)
  END FlipArrow;
     
  PROCEDURE FlipStar (X, Y: INTEGER);
  BEGIN
    IF X < CL THEN
      IF X < 7 THEN X := 7 ELSIF X > DW - 8 THEN X := DW - 8 END
    ELSE
      IF X < CL + 7 THEN X := CL + 7 ELSIF X > CL + DW - 8 THEN X := CL + DW - 8 END
    END ;
    IF Y < 7 THEN Y := 7 ELSIF Y > DH - 8 THEN Y := DH - 8 END;
    Display.CopyPattern(Display.white, Display.star, X - 7, Y - 7, Display.invert)
  END FlipStar;

  PROCEDURE OpenCursor(VAR c: Cursor);
  BEGIN c.on := FALSE; c.X := 0; c.Y := 0
  END OpenCursor;
 
  PROCEDURE FadeCursor(VAR c: Cursor);
  BEGIN IF c.on THEN c.marker.Fade(c.X, c.Y); c.on := FALSE END
  END FadeCursor;

  PROCEDURE DrawCursor(VAR c: Cursor; m: Marker; x, y: INTEGER);
  BEGIN
    IF c.on & ((x # c.X) OR (y # c.Y) OR (m.Draw # c.marker.Draw)) THEN
      c.marker.Fade(c.X, c.Y); c.on := FALSE
    END;
    IF ~c.on THEN
      m.Draw(x, y); c.marker := m; c.X := x; c.Y := y; c.on := TRUE
    END
  END DrawCursor;

  PROCEDURE DrawMouse*(m: Marker; x, y: INTEGER);
  BEGIN DrawCursor(Mouse, m, x, y)
  END DrawMouse;

  PROCEDURE DrawMouseArrow*(x, y: INTEGER);
  BEGIN DrawCursor(Mouse, Arrow, x, y)
  END DrawMouseArrow;

  PROCEDURE FadeMouse*;
  BEGIN FadeCursor(Mouse)
  END FadeMouse;

  PROCEDURE DrawPointer*(x, y: INTEGER);
  BEGIN DrawCursor(Pointer, Star, x, y)
  END DrawPointer;

  (*display management*)

  PROCEDURE RemoveMarks* (X, Y, W, H: INTEGER);
  BEGIN
    IF (Mouse.X > X - 16) & (Mouse.X < X + W + 16) & (Mouse.Y > Y - 16) & (Mouse.Y < Y + H + 16) THEN
      FadeCursor(Mouse)
    END;
    IF (Pointer.X > X - 8) & (Pointer.X < X + W + 8) & (Pointer.Y > Y - 8) & (Pointer.Y < Y + H + 8) THEN
      FadeCursor(Pointer)
    END
  END RemoveMarks;

  PROCEDURE HandleFiller (V: Display.Frame; VAR M: Display.FrameMsg);
  BEGIN
    CASE M OF
    InputMsg: IF M.id = track THEN DrawCursor(Mouse, Arrow, M.X, M.Y) END |
    ControlMsg: IF M.id = mark THEN DrawCursor(Pointer, Star, M.X, M.Y) END |
    Viewers.ViewerMsg:
      IF (M.id = Viewers.restore) & (V.W > 0) & (V.H > 0) THEN
        RemoveMarks(V.X, V.Y, V.W, V.H);
        Display.ReplConst(Display.black, V.X, V.Y, V.W, V.H, Display.replace)
      ELSIF (M.id = Viewers.modify) & (M.Y < V.Y) THEN
        RemoveMarks(V.X, M.Y, V.W, V.Y - M.Y);
        Display.ReplConst(Display.black, V.X, M.Y, V.W, V.Y - M.Y, Display.replace)
      END
    END
  END HandleFiller;

  PROCEDURE OpenDisplay* (UW, SW, H: INTEGER);
    VAR Filler!: Viewers.Viewer;
  BEGIN
     Input.SetMouseLimits(Viewers.curW + UW + SW, H);
     Display.ReplConst(Display.black, Viewers.curW, 0, UW + SW, H, Display.replace);
     NEW(Filler); Filler.handle := HandleFiller;
     Viewers.InitTrack(UW, H, Filler); (*init user track*)
     NEW(Filler); Filler.handle := HandleFiller;
     Viewers.InitTrack(SW, H, Filler) (*init system track*)
  END OpenDisplay;

  PROCEDURE DisplayWidth* (X: INTEGER): INTEGER;
  BEGIN RETURN DW
  END DisplayWidth;

  PROCEDURE DisplayHeight* (X: INTEGER): INTEGER;
  BEGIN RETURN DH
  END DisplayHeight;

  PROCEDURE OpenTrack* (X, W: INTEGER);
    VAR Filler!: Viewers.Viewer;
  BEGIN
    NEW(Filler); Filler.handle := HandleFiller;
    Viewers.OpenTrack(X, W, Filler)
  END OpenTrack;

  PROCEDURE UserTrack* (X: INTEGER): INTEGER;
  BEGIN RETURN X DIV DW * DW
  END UserTrack;

  PROCEDURE SystemTrack* (X: INTEGER): INTEGER;
  BEGIN RETURN X DIV DW * DW + DW DIV 8 * 5
  END SystemTrack;

  PROCEDURE UY (X: INTEGER): INTEGER;
    VAR h: INTEGER;
      fil!, bot!, alt!, max!: Display.Frame;
  BEGIN
    Viewers.Locate(X, 0, fil, bot, alt, max);
    IF fil.H >= DH DIV 8 THEN h := DH ELSE h := max.Y + max.H DIV 2 END ;
    RETURN h
  END UY;

  PROCEDURE AllocateUserViewer* (DX: INTEGER; VAR X, Y: INTEGER);
  BEGIN
    IF Pointer.on THEN X := Pointer.X; Y := Pointer.Y
    ELSE X := DX DIV DW * DW; Y := UY(X)
    END
  END AllocateUserViewer;

  PROCEDURE SY (X: INTEGER): INTEGER;
    VAR H0, H1, H2, H3, y: INTEGER;
      fil!, bot!, alt!, max!: Display.Frame;
  BEGIN H3 := DH - DH DIV 3;
    H2 := H3 - H3 DIV 2; H1 := DH DIV 5; H0 := DH DIV 10;
    Viewers.Locate(X, DH, fil, bot, alt, max);
    IF fil.H >= DH DIV 8 THEN y := DH
    ELSIF max.H >= DH - H0 THEN y := max.Y + H3
    ELSIF max.H >= H3 - H0 THEN y := max.Y + H2
    ELSIF max.H >= H2 - H0 THEN y := max.Y + H1
    ELSIF max # bot THEN y := max.Y + max.H DIV 2
    ELSIF bot.H >= H1 THEN y := bot.H DIV 2
    ELSE y := alt.Y + alt.H DIV 2
    END ;
    RETURN y
  END SY;

  PROCEDURE AllocateSystemViewer* (DX: INTEGER; VAR X, Y: INTEGER);
  BEGIN
    IF Pointer.on THEN X := Pointer.X; Y := Pointer.Y
    ELSE X := DX DIV DW * DW + DW DIV 8 * 5; Y := SY(X)
    END
  END AllocateSystemViewer;

  PROCEDURE MarkedViewer* (): Viewers.Viewer;
  BEGIN RETURN Viewers.This(Pointer.X, Pointer.Y)
  END MarkedViewer;

  PROCEDURE PassFocus* (V: Viewers.Viewer);
    VAR M: ControlMsg;
  BEGIN M.id := defocus; FocusViewer.handle(FocusViewer, M); FocusViewer := V
  END PassFocus;

  PROCEDURE OpenLog*(T: Texts.Text);
  BEGIN Log := T
  END OpenLog;

  (*command interpretation*)
  PROCEDURE SetPar*(F: Display.Frame; T: Texts.Text; pos: INTEGER);
  BEGIN Par.vwr := Viewers.This(F.X, F.Y); Par.frame := F; Par.text := T; Par.pos := pos
  END SetPar;

  PROCEDURE Call* (name: ARRAY OF CHAR; VAR res: INTEGER);
    VAR mod!: Modules.Module; P: Modules.Command;
      i, j: INTEGER; ch: CHAR;
      Mname, Cname: ARRAY 32 OF CHAR;
  BEGIN i := 0; ch := name[0];
    WHILE (ch # ".") & (ch # 0X) DO Mname[i] := ch; INC(i); ch := name[i] END ;
    IF ch = "." THEN
      Mname[i] := 0X; INC(i);
      Modules.Load(Mname, mod); res := Modules.res;
      IF Modules.res = 0 THEN
        j := 0; ch := name[i]; INC(i);
        WHILE ch # 0X DO Cname[j] := ch; INC(j); ch := name[i]; INC(i) END ;
        Cname[j] := 0X;
        P := Modules.ThisCommand(mod, Cname); res := Modules.res;
        IF Modules.res = 0 THEN P END
      END
    ELSE res := 5
    END
  END Call;

  PROCEDURE GetSelection* (VAR text: Texts.Text; VAR beg, end, time: INTEGER);
    VAR M!: SelectionMsg;
  BEGIN
    M.time := -1; Viewers.Broadcast(M); time := M.time;
    IF time >= 0 THEN text := M.text; beg := M.beg; end := M.end END
  END GetSelection;

  PROCEDURE GC;
    VAR mod!: Modules.Module;
  BEGIN
    IF (ActCnt <= 0) OR (Kernel.allocated >= Kernel.heapLim - Kernel.heapOrg - 10000H) THEN
      Kernel.DisableAbortHandler;
      mod := Modules.root; LED(21H);
      WHILE mod # NIL DO
        IF mod.name[0] # 0X THEN Kernel.Mark(mod.ptr) END ;
        mod := mod.next
      END ;
      LED(23H);
      Files.RestoreList; LED(27H);
      Kernel.Scan; LED(20H);
      ActCnt := BasicCycle;
      Kernel.EnableAbortHandler
    END
  END GC;

  PROCEDURE module(t: Task): Modules.Module;
    VAR adr: INTEGER; mod!: Modules.Module;
  BEGIN adr := SYSTEM.VAL(INTEGER, t.handle); mod := Modules.root;
    WHILE (mod # NIL) & ((mod.name[0] = 0X) OR (adr < mod.code) OR (adr >= mod.imp)) DO mod := mod.next END

    RETURN mod
  END module;

  PROCEDURE NewTask*(h: Handler; period: INTEGER): Task;
    VAR t!: Task;
  BEGIN NEW(t); t.state := off; t.next := t; t.handle := h; t.period := period; RETURN t
  END NewTask;
  
  PROCEDURE Install* (T: Task);
    VAR mod!: Modules.Module;
  BEGIN mod := module(T);
    IF (mod # NIL) & (T.state = off) THEN Modules.IncRefcnt(mod, 1);
      T.next := CurTask.next; CurTask.next := T; T.state := idle; T.nextTime := 0; INC(NofTasks)
    END
  END Install;

  PROCEDURE Remove* (T: Task);
    VAR t!: Task; mod!: Modules.Module;
  BEGIN
    IF T.state # off THEN t := T; mod := module(T); IF mod # NIL THEN Modules.IncRefcnt(mod, -1) END;
      WHILE t.next # T DO t := t.next END ;
      t.next := T.next; T.state := off; T.next := NIL; CurTask := t; DEC(NofTasks)
    END
  END Remove;

  PROCEDURE Collect* (count: INTEGER);
  BEGIN ActCnt := count
  END Collect;

  PROCEDURE SetFont* (fnt: Fonts.Font);
  BEGIN CurFnt := fnt
  END SetFont;

  PROCEDURE SetColor* (col: INTEGER);
  BEGIN CurCol := col
  END SetColor;

  PROCEDURE SetOffset* (voff: INTEGER);
  BEGIN CurOff := voff
  END SetOffset;

  PROCEDURE Loop*;
    VAR V!: Viewers.Viewer; M!: InputMsg; N: ControlMsg;
       prevX, prevY, X, Y, Z, t: INTEGER; keys: SET; ch: CHAR;
  BEGIN
    REPEAT
      Input.Mouse(keys, X, Y, Z);
      IF Input.Available() > 0 THEN Input.Read(ch);
        IF ch = ESC THEN
          N.id := neutralize; Viewers.Broadcast(N); FadeCursor(Pointer); LED(0)
        ELSIF ch = SETSTAR THEN
          N.id := mark; N.X := X; N.Y := Y; V := Viewers.This(X, Y); V.handle(V, N)
        ELSE M.id := consume; M.ch := ch; M.fnt := CurFnt; M.col := CurCol; M.voff := CurOff;
          FocusViewer.handle(FocusViewer, M); DEC(ActCnt)
        END
      ELSIF keys # {} THEN
        M.id := track; M.X := X; M.Y := Y; M.keys := keys;
        REPEAT V := Viewers.This(M.X, M.Y); V.handle(V, M); Input.Mouse(M.keys, M.X, M.Y, M.Z)
        UNTIL M.keys = {};
        DEC(ActCnt)
      ELSE
        IF (X # prevX) OR (Y # prevY) OR (Z # prevZ) OR ~Mouse.on THEN
          M.id := track; M.X := X; M.Z := Z - prevZ;
          IF Y >= Display.Height THEN Y := Display.Height END ;
          M.Y := Y; M.keys := keys; V := Viewers.This(X, Y); V.handle(V, M); prevX := X; prevY := Y; prevZ := Z
        END;
        CurTask := CurTask.next; t := Kernel.Time();
        IF t >= CurTask.nextTime THEN
          CurTask.nextTime := t + CurTask.period; CurTask.state := active; CurTask.handle; CurTask.state := idle
        END
      END
    UNTIL FALSE
  END Loop;

  PROCEDURE^3 ps2_1IrqHandler;
    VAR pr: SET;
  BEGIN SYSTEM.GET(PR, pr);
    IF ps2[0].clockPin IN pr THEN
      pr := {ps2[0].clockPin}; SYSTEM.PUT(PR, pr); (*clear pending IRQ*)
      PS2.ProcessData(ps2[0])
    END
  END ps2_1IrqHandler;

  PROCEDURE^3 ps2_2IrqHandler;
    VAR pr: SET;
  BEGIN SYSTEM.GET(PR, pr);
    IF ps2[1].clockPin IN pr THEN
      pr := {ps2[1].clockPin}; SYSTEM.PUT(PR, pr); (*clear pending IRQ*)
      PS2.ProcessData(ps2[1])
    END
  END ps2_2IrqHandler;

  PROCEDURE Reset*;
  BEGIN
    IF CurTask.state = active THEN Remove(CurTask) END ; Loop
  END Reset;

  PROCEDURE installPS2IrqHandlers;
    VAR irqNum: INTEGER;
  BEGIN BSP.InitPS2;
    Kernel.Install(SYSTEM.ADR(ps2_1IrqHandler), BSP.VecTabBase + BSP.PS2CLOCK1ExtiIrqNum*4);
    Kernel.Install(SYSTEM.ADR(ps2_2IrqHandler), BSP.VecTabBase + BSP.PS2CLOCK2ExtiIrqNum*4);

    irqNum := BSP.PS2CLOCK1ExtiIrqNum - 16;
    SYSTEM.PUT(BSP.NVIC_ISER + irqNum DIV 32*4, {irqNum MOD 32});

    irqNum := BSP.PS2CLOCK2ExtiIrqNum - 16;
    SYSTEM.PUT(BSP.NVIC_ISER + irqNum DIV 32*4, {irqNum MOD 32})

  END installPS2IrqHandlers;

  PROCEDURE initModules(m: Modules.Module);
    VAR body: Modules.Command;
      ba: INTEGER;
  BEGIN
    IF m.name # "Oberon" THEN initModules(m.next);
      IF m.refcnt = -1 (*resident module*) THEN SYSTEM.GET(m.ent, ba);
        body := SYSTEM.VAL(Modules.Command, m.code + ba + 1); body
      END;
    END
  END initModules;

BEGIN User[0] := 0X; prevZ := 0;
  Arrow.Fade := FlipArrow; Arrow.Draw := FlipArrow;
  Star.Fade := FlipStar; Star.Draw := FlipStar;
  OpenCursor(Mouse); OpenCursor(Pointer);

  DW := Display.Width; DH := Display.Height; CL := DW;
  OpenDisplay(DW DIV 8 * 5, Display.Width - DW DIV 8 * 5, DH);
  FocusViewer := Viewers.This(0, 0);
  CurFnt := Fonts.Default; CurCol := Display.white; CurOff := 0;

  ActCnt := 0; CurTask := NewTask(GC, 1000); Install(CurTask);

  (*Initialize PS/2 devices*)
  installPS2IrqHandlers;

  ps2[0].clockPin := BSP.PS2CLOCK1Pin;
  ps2[0].clock_In := BSP.PS2CLOCK1In; ps2[0].clock_Out := BSP.PS2CLOCK1Out;
  ps2[0].data_In := BSP.PS2DATA1In; ps2[0].data_Out := BSP.PS2DATA1Out;
  ps2[0].keyboardLED := BSP.LD3Out; ps2[0].mouseLED := BSP.LD4Out;
  PS2.InitDevice(ps2[0]);

  ps2[1].clockPin := BSP.PS2CLOCK2Pin;
  ps2[1].clock_In := BSP.PS2CLOCK2In; ps2[1].clock_Out := BSP.PS2CLOCK2Out;
  ps2[1].data_In := BSP.PS2DATA2In; ps2[1].data_Out := BSP.PS2DATA2Out;
  ps2[1].keyboardLED := BSP.LD3Out; ps2[1].mouseLED := BSP.LD4Out;
  PS2.InitDevice(ps2[1]);

  (*Since we'll never exit this initilization block, we need to perform here
     the initilization of the remaining resident modules*)
  initModules(Modules.root);
  Modules.Load("System", Mod);   Modules.Load("OnStartup", Mod); Mod := NIL;
  Loop

END Oberon.

OM4Tool.DecSym Oberon.sm4
decode Oberon.sm4
Oberon A4821F19  1
   1 consume [^4]       0
   1 track [^4]       1
   1 defocus [^4]       0
   1 neutralize [^4]       1
   1 mark [^4]       2
   5 Painter [15  form = 10 [^9]( class = 2 [^4] class = 2 [^4])]()
   5 Marker [16  form = 13 [^9]  exno = 1  extlev = 0  size = 8 { Draw [^15]   4 Fade [^15]   0}]()
   5 Cursor [17  form = 13 [^9]  exno = 2  extlev = 0  size = 20 { Y [^4]  16 X [^4]  12 on [^2]   8 marker [^16]   0}]()
   5 InputMsg [18  form = 13 [19  form = 13 [^9]  exno = 0  extlev = 0  size = 0 {} Display.FrameMsg 5CE12DC0]  exno = 3  extlev = 1  size = 36 { voff [^4]  32 col [^4]  28 fnt [20  form = 7 [21  form = 13 [^9]  exno = 0  extlev = 0  size = 21560 { next [^20]  52 maxY [^4]  48 minY [^4]  44 maxX [^4]  40 minX [^4]  36 height [^4]  32 name [0  form = 12 [^3]  len = 32  size = 32]   0} Fonts.FontDesc AA480AE7] Fonts.Font AA480AE7]  24 ch [^3]  20 Z [^4]  16 Y [^4]  12 X [^4]   8 keys [^6]   4 id [^4]   0}]()
   5 SelectionMsg [22  form = 13 [^19]  exno = 4  extlev = 1  size = 16 { end [^4]  12 beg [^4]   8 text [23  form = 7 [24  form = 13 [^9]  exno = 0  extlev = 0  size = 24 { --  16 --  12 notify [25  form = 10 [^9]( class = 2 [^4] class = 2 [^4] class = 2 [^4] class = 2 [^23]) Texts.Notifier C476A8CA]   8 changed [^2]   4 len [^4]   0} Texts.TextDesc C476A8CA] Texts.Text C476A8CA]   4 time [^4]   0}]()
   5 ControlMsg [26  form = 13 [^19]  exno = 5  extlev = 1  size = 12 { Y [^4]   8 X [^4]   4 id [^4]   0}]()
   5 CopyMsg [27  form = 13 [^19]  exno = 6  extlev = 1  size = 4 { F [28  form = 7 [29  form = 13 [^9]  exno = 0  extlev = 0  size = 28 { handle [30  form = 10 [^9]( class = 3 [^19] class = 2 [^28]) Display.Handler 5CE12DC0]  24 H [^4]  20 W [^4]  16 Y [^4]  12 X [^4]   8 dsc [^28]   4 next [^28]   0} Display.FrameDesc 5CE12DC0] Display.Frame 5CE12DC0]   0}]()
   5 Task [31  form = 7 [32  form = 13 [^9]  exno = 7  extlev = 0  size = 20 { --  12 period [^4]   8}]]()
   5 Handler [33  form = 10 [^9]()]()
   5 TaskDesc [^32]( ->  31)
   2 User [0  form = 12 [^3]  len = 8  size = 8]     8
   2 Password [^4]     9
   2 Arrow [^16]    10
   2 Star [^16]    11
   2 FocusViewer [34  form = 7 [35  form = 13 [^29]  exno = 0  extlev = 1  size = 32 { state [^4]  28} Viewers.ViewerDesc 6CD44D67] Viewers.Viewer 6CD44D67]    12
   2 Log [^23]    13
   2 Par [0  form = 13 [^9]  exno = 0  extlev = 0  size = 16 { pos [^4]  12 text [^23]   8 frame [^28]   4 vwr [^34]   0}]    14
   2 CurFnt [^20]    15
   2 CurCol [^4]    16
   2 CurOff [^4]    17
   2 NofTasks [^4]    18
   1 SetUser [0  form = 10 [^9]( class = 3 [0  form = 12 [^3]  len = -1  size = 8] class = 3 [0  form = 12 [^3]  len = -1  size = 8])]      19
   1 Clock [0  form = 10 [^4]()]      20
   1 SetClock [0  form = 10 [^9]( class = 2 [^4])]      21
   1 Time [0  form = 10 [^4]()]      22
   1 DrawMouse [0  form = 10 [^9]( class = 2 [^4] class = 2 [^4] class = 3# [^16])]      23
   1 DrawMouseArrow [0  form = 10 [^9]( class = 2 [^4] class = 2 [^4])]      24
   1 FadeMouse [0  form = 10 [^9]()]      25
   1 DrawPointer [0  form = 10 [^9]( class = 2 [^4] class = 2 [^4])]      26
   1 RemoveMarks [0  form = 10 [^9]( class = 2 [^4] class = 2 [^4] class = 2 [^4] class = 2 [^4])]      27
   1 OpenDisplay [0  form = 10 [^9]( class = 2 [^4] class = 2 [^4] class = 2 [^4])]      28
   1 DisplayWidth [0  form = 10 [^4]( class = 2 [^4])]      29
   1 DisplayHeight [0  form = 10 [^4]( class = 2 [^4])]      30
   1 OpenTrack [0  form = 10 [^9]( class = 2 [^4] class = 2 [^4])]      31
   1 UserTrack [0  form = 10 [^4]( class = 2 [^4])]      32
   1 SystemTrack [0  form = 10 [^4]( class = 2 [^4])]      33
   1 AllocateUserViewer [0  form = 10 [^9]( class = 3 [^4] class = 3 [^4] class = 2 [^4])]      34
   1 AllocateSystemViewer [0  form = 10 [^9]( class = 3 [^4] class = 3 [^4] class = 2 [^4])]      35
   1 MarkedViewer [0  form = 10 [^34]()]      36
   1 PassFocus [0  form = 10 [^9]( class = 2 [^34])]      37
   1 OpenLog [0  form = 10 [^9]( class = 2 [^23])]      38
   1 SetPar [0  form = 10 [^9]( class = 2 [^4] class = 2 [^23] class = 2 [^28])]      39
   1 Call [0  form = 10 [^9]( class = 3 [^4] class = 3# [0  form = 12 [^3]  len = -1  size = 8])]      40
   1 GetSelection [0  form = 10 [^9]( class = 3 [^4] class = 3 [^4] class = 3 [^4] class = 3 [^23])]      41
   1 NewTask [0  form = 10 [^31]( class = 2 [^4] class = 2 [^33])]      42
   1 Install [0  form = 10 [^9]( class = 2 [^31])]      43
   1 Remove [0  form = 10 [^9]( class = 2 [^31])]      44
   1 Collect [0  form = 10 [^9]( class = 2 [^4])]      45
   1 SetFont [0  form = 10 [^9]( class = 2 [^20])]      46
   1 SetColor [0  form = 10 [^9]( class = 2 [^4])]      47
   1 SetOffset [0  form = 10 [^9]( class = 2 [^4])]      48
   1 Loop [0  form = 10 [^9]()]      49
   1 Reset [0  form = 10 [^9]()]      50

