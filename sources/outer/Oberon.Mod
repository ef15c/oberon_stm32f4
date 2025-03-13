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
      X*, Y*: INTEGER;
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

    ps2*: ARRAY 2 OF PS2.DeviceDesc;

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
       prevX, prevY, X, Y, t: INTEGER; keys: SET; ch: CHAR;
  BEGIN
    REPEAT
      Input.Mouse(keys, X, Y);
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
        REPEAT V := Viewers.This(M.X, M.Y); V.handle(V, M); Input.Mouse(M.keys, M.X, M.Y)
        UNTIL M.keys = {};
        DEC(ActCnt)
      ELSE
        IF (X # prevX) OR (Y # prevY) OR ~Mouse.on THEN
          M.id := track; M.X := X; 
          IF Y >= Display.Height THEN Y := Display.Height END ;
          M.Y := Y; M.keys := keys; V := Viewers.This(X, Y); V.handle(V, M); prevX := X; prevY := Y
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
  BEGIN
    SYSTEM.GET(PR, pr);
    IF ps2[1].clockPin IN pr THEN
      pr := {ps2[1].clockPin}; SYSTEM.PUT(PR, pr); (*clear pending IRQ*)
      PS2.ProcessData(ps2[1])
    END
  END ps2_2IrqHandler;

  PROCEDURE Reset*;
  BEGIN
    IF CurTask.state = active THEN Remove(CurTask) END ; Loop
  END Reset;

  PROCEDURE SendByteAsync*(idx, data: BYTE);
  BEGIN IF idx < 2 THEN
      PS2.SendByteAsync(ps2[idx], data)
    END
  END SendByteAsync;

  PROCEDURE WaitForAnswer*(idx: BYTE; timeout: INTEGER): INTEGER;
    VAR res: INTEGER;
  BEGIN IF idx < 2 THEN
      res := PS2.WaitForAnswer(ps2[idx], timeout)
    END;
    RETURN res
  END WaitForAnswer;

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

BEGIN User[0] := 0X;
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

  ps2[0].connectedDevice := PS2.NO_DEVICE;
  ps2[0].clockPin := BSP.PS2CLOCK1Pin;
  ps2[0].clock_In := BSP.PS2CLOCK1In; ps2[0].clock_Out := BSP.PS2CLOCK1Out;
  ps2[0].data_In := BSP.PS2DATA1In; ps2[0].data_Out := BSP.PS2DATA1Out;
  ps2[0].keyboardLED := BSP.LD3Out; ps2[0].mouseLED := BSP.LD4Out;
  PS2.InitDevice(ps2[0]);

  ps2[1].connectedDevice := PS2.NO_DEVICE;
  ps2[1].clockPin := BSP.PS2CLOCK2Pin;
  ps2[1].clock_In := BSP.PS2CLOCK2In; ps2[1].clock_Out := BSP.PS2CLOCK2Out;
  ps2[1].data_In := BSP.PS2DATA2In; ps2[1].data_Out := BSP.PS2DATA2Out;
  ps2[1].keyboardLED := BSP.LD3Out; ps2[1].mouseLED := BSP.LD4Out;
  PS2.InitDevice(ps2[1]);

  Modules.Load("System", Mod); Modules.Load("OnStartup", Mod); Mod := NIL;

  Loop
END Oberon.

OM4Tool.DecObj Oberon.m4c
decode Oberon.m4c
Oberon 45CA3794   1   7296
imports:
	BSP F222E0EE
	PS2 FA464427
	Kernel B4228008
	Files 5B83E95D
	Modules D7D09919
	Input 40A57B9C
	Display 722EE7B9
	Viewers 24AB6B3A
	Fonts AA480AE7
	Texts 854A4CE2
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000020 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000040 0002800B FFFFFFFF FFFFFFFF 00000014 FFFFFFFF 00000020 00040006 FFFFFFFF FFFFFFFF 00000004 FFFFFFFF 00000020 00058006 FFFFFFFF FFFFFFFF FFFFFFFF 00000020 0006C005 FFFFFFFF FFFFFFFF 00000000 FFFFFFFF 00000020 FFFFFFFF FFFFFFFF FFFFFFFF 0000000C FFFFFFFF
data   308
strings
System||OnStartup|||
code
commands:
	FadeMouse 000003E6
	Loop 0000110C
	Reset 00001462
entries
 0000158A 00000000 00000014 00000028 00000040 00000058 0000006C 00000084 0000009C 000000A4 000000A8 000000B0 000000E0 000000E4 000000E8 000000F8 000000FC 00000100 00000104 00000120 00000086 000000CC 000000D8 000000EA 0000038A 000003B2 000003E6 00000402 00000436 000006F6 00000784 0000079A 000007B0 000007E4 00000814 000008C2 00000AD8 00000B5A 00000B7A 00000BC6 00000BDE 00000C34 00000D98 00000F10 00000F64 00000FFC 000010AC 000010C4 000010DC 000010F4 0000110C 00001462 00001496 000014D6
pointer refs
   224   228   240   236   232   248   264   284   348   436
fixP =  00001848
fixD =  0000184E
fixT =  0000001C
entry =  0000158A
 00000000	     B084	SUB SP SP #16
 00000002	     B403	PUSH R0 R1
 00000004	     B500	PUSH LR
 00000006	     2000	MOVS R0 #0
 00000008	     9004	STR R0 [ SP + 16 ]
 0000000A	     2000	MOVS R0 #0
 0000000C	     9005	STR R0 [ SP + 20 ]
 0000000E	     2000	MOVS R0 #0
 00000010	     9003	STR R0 [ SP + 12 ]
 00000012	     9803	LDR R0 [ SP + 12 ]
 00000014	     9902	LDR R1 [ SP + 8 ]
 00000016	     4288	CMP R0 R1
 00000018	     BF28	IT CS
 0000001A	 EC00F0C1	TrapCS 1 at pos 1932
 0000001E	     9901	LDR R1 [ SP + 4 ]
 00000020	     1808	ADDS R0 R1 R0
 00000022	     7800	LDRB R0 [ R0 + 0 ]
 00000024	     2800	CMP R0 #0
 00000026	 F000801D	BEQ #58, goes to  00000064
 0000002A	     9805	LDR R0 [ SP + 20 ]
 0000002C	     9006	STR R0 [ SP + 24 ]
 0000002E	     9804	LDR R0 [ SP + 16 ]
 00000030	     9005	STR R0 [ SP + 20 ]
 00000032	     9806	LDR R0 [ SP + 24 ]
 00000034	 F24011FD	MOV R1 #509
 00000038	 FBB0F2F1	UDIV R2 R0 R1
 0000003C	     434A	MULS R2 R1 R2
 0000003E	     1A80	SUBS R0 R0 R2
 00000040	     1C40	ADDS R0 R0 #1
 00000042	     217F	MOVS R1 #127
 00000044	     4348	MULS R0 R1 R0
 00000046	     9903	LDR R1 [ SP + 12 ]
 00000048	     9A02	LDR R2 [ SP + 8 ]
 0000004A	     4291	CMP R1 R2
 0000004C	     BF28	IT CS
 0000004E	 EC00F501	TrapCS 1 at pos 2000
 00000052	     9A01	LDR R2 [ SP + 4 ]
 00000054	     1851	ADDS R1 R2 R1
 00000056	     7809	LDRB R1 [ R1 + 0 ]
 00000058	     1840	ADDS R0 R0 R1
 0000005A	     9004	STR R0 [ SP + 16 ]
 0000005C	     9803	LDR R0 [ SP + 12 ]
 0000005E	     1C40	ADDS R0 R0 #1
 00000060	     9003	STR R0 [ SP + 12 ]
 00000062	     E7D6	B #-84, goes to  00000012
 00000064	     9805	LDR R0 [ SP + 20 ]
 00000066	 F5B04F00	CMP R0 #32768
 0000006A	 F2C08004	BLT #8, goes to  00000076
 0000006E	     9805	LDR R0 [ SP + 20 ]
 00000070	 F5B03080	SUBS R0 R0 #65536
 00000074	     9005	STR R0 [ SP + 20 ]
 00000076	     9805	LDR R0 [ SP + 20 ]
 00000078	     0400	LSLS R0 R0 #16
 0000007A	     9904	LDR R1 [ SP + 16 ]
 0000007C	     1840	ADDS R0 R0 R1
 0000007E	 F85DEB04	LDR LR [ SP ] + 4
 00000082	     B006	ADD SP SP #24
 00000084	     4770	BX LR
 00000086	     B40F	PUSH R0 R1 R2 R3
 00000088	     B500	PUSH LR
 0000008A	 00000045	MOV R0 lower 16-bits base(0), next at  00000000
 0000008E	 0000009C	MOVT R0 higher 16-bits var + 156
 00000092	     9901	LDR R1 [ SP + 4 ]
 00000094	     9A02	LDR R2 [ SP + 8 ]
 00000096	     2A00	CMP R2 #0
 00000098	     D00B	BEQ #22, goes to  000000B2
 0000009A	     1CD2	ADDS R2 R2 #3
 0000009C	     1092	ASRS R2 R2 #2
 0000009E	     2A02	CMP R2 #2
 000000A0	     BFC8	IT GT
 000000A2	 EC011093	TrapGT 3 at pos 2185
 000000A6	 F8513B04	LDR R3 [ R1 ] + 4
 000000AA	 F8403B04	STR R3 [  R0 ] + 4
 000000AE	     1E52	SUBS R2 R2 #1
 000000B0	     D1F9	BNE #-14, goes to  000000A6
 000000B2	     9803	LDR R0 [ SP + 12 ]
 000000B4	     9904	LDR R1 [ SP + 16 ]
 000000B6	 F7FFFFA3	BL #-186, goes to  00000000
 000000BA	 10000018	MOV R1 lower 16-bits base(0), next at  0000008A
 000000BE	 000000A4	MOVT R1 higher 16-bits var + 164
 000000C2	     6008	STR R0 [  R1 + 0 ]
 000000C4	 F85DEB04	LDR LR [ SP ] + 4
 000000C8	     B004	ADD SP SP #16
 000000CA	     4770	BX LR
 000000CC	     B500	PUSH LR
 000000CE	 31800067	BL Mod(  3) proc(24)
 000000D2	 F85DEB04	LDR LR [ SP ] + 4
 000000D6	     4770	BX LR
 000000D8	     B401	PUSH R0
 000000DA	     B500	PUSH LR
 000000DC	     9801	LDR R0 [ SP + 4 ]
 000000DE	 31900008	BL Mod(  3) proc(25)
 000000E2	 F85DEB04	LDR LR [ SP ] + 4
 000000E6	     B001	ADD SP SP #4
 000000E8	     4770	BX LR
 000000EA	     B500	PUSH LR
 000000EC	 31700007	BL Mod(  3) proc(23)
 000000F0	 F85DEB04	LDR LR [ SP ] + 4
 000000F4	     4770	BX LR
 000000F6	     B403	PUSH R0 R1
 000000F8	     B500	PUSH LR
 000000FA	     9801	LDR R0 [ SP + 4 ]
 000000FC	 10000021	MOV R1 lower 16-bits base(0), next at  000000BA
 00000100	 00000114	MOVT R1 higher 16-bits var + 276
 00000104	     6809	LDR R1 [ R1 + 0 ]
 00000106	     4288	CMP R0 R1
 00000108	 F2808013	BGE #38, goes to  00000132
 0000010C	 00000008	MOV R0 lower 16-bits base(0), next at  000000FC
 00000110	 0000010C	MOVT R0 higher 16-bits var + 268
 00000114	     6800	LDR R0 [ R0 + 0 ]
 00000116	     380F	SUBS R0 R0 #15
 00000118	     9901	LDR R1 [ SP + 4 ]
 0000011A	     4281	CMP R1 R0
 0000011C	 F3408007	BLE #14, goes to  0000012E
 00000120	 0000000A	MOV R0 lower 16-bits base(0), next at  0000010C
 00000124	 0000010C	MOVT R0 higher 16-bits var + 268
 00000128	     6800	LDR R0 [ R0 + 0 ]
 0000012A	     380F	SUBS R0 R0 #15
 0000012C	     9001	STR R0 [ SP + 4 ]
 0000012E	 F000B81D	B #58, goes to  0000016C
 00000132	 00000009	MOV R0 lower 16-bits base(0), next at  00000120
 00000136	 00000114	MOVT R0 higher 16-bits var + 276
 0000013A	     6800	LDR R0 [ R0 + 0 ]
 0000013C	 10000005	MOV R1 lower 16-bits base(0), next at  00000132
 00000140	 0000010C	MOVT R1 higher 16-bits var + 268
 00000144	     6809	LDR R1 [ R1 + 0 ]
 00000146	     1840	ADDS R0 R0 R1
 00000148	     380F	SUBS R0 R0 #15
 0000014A	     9901	LDR R1 [ SP + 4 ]
 0000014C	     4281	CMP R1 R0
 0000014E	 F340800D	BLE #26, goes to  0000016C
 00000152	 0000000B	MOV R0 lower 16-bits base(0), next at  0000013C
 00000156	 00000114	MOVT R0 higher 16-bits var + 276
 0000015A	     6800	LDR R0 [ R0 + 0 ]
 0000015C	 10000005	MOV R1 lower 16-bits base(0), next at  00000152
 00000160	 0000010C	MOVT R1 higher 16-bits var + 268
 00000164	     6809	LDR R1 [ R1 + 0 ]
 00000166	     1840	ADDS R0 R0 R1
 00000168	     380F	SUBS R0 R0 #15
 0000016A	     9001	STR R0 [ SP + 4 ]
 0000016C	     9802	LDR R0 [ SP + 8 ]
 0000016E	     280E	CMP R0 #14
 00000170	 F2808004	BGE #8, goes to  0000017C
 00000174	     200E	MOVS R0 #14
 00000176	     9002	STR R0 [ SP + 8 ]
 00000178	 F000B80F	B #30, goes to  0000019A
 0000017C	     9802	LDR R0 [ SP + 8 ]
 0000017E	 10000011	MOV R1 lower 16-bits base(0), next at  0000015C
 00000182	 00000110	MOVT R1 higher 16-bits var + 272
 00000186	     6809	LDR R1 [ R1 + 0 ]
 00000188	     4288	CMP R0 R1
 0000018A	 F3408006	BLE #12, goes to  0000019A
 0000018E	 00000008	MOV R0 lower 16-bits base(0), next at  0000017E
 00000192	 00000110	MOVT R0 higher 16-bits var + 272
 00000196	     6800	LDR R0 [ R0 + 0 ]
 00000198	     9002	STR R0 [ SP + 8 ]
 0000019A	     20FF	MOVS R0 #255
 0000019C	 17000007	MOV R1 lower 16-bits base(7), next at  0000018E
 000001A0	 00000003	MOVT R1 higher 16-bits var(3)
 000001A4	     6809	LDR R1 [ R1 + 0 ]
 000001A6	     9A01	LDR R2 [ SP + 4 ]
 000001A8	     9B02	LDR R3 [ SP + 8 ]
 000001AA	     3B0E	SUBS R3 R3 #14
 000001AC	     2402	MOVS R4 #2
 000001AE	 70D00061	BL Mod(  7) proc(13)
 000001B2	 F85DEB04	LDR LR [ SP ] + 4
 000001B6	     B002	ADD SP SP #8
 000001B8	     4770	BX LR
 000001BA	     B403	PUSH R0 R1
 000001BC	     B500	PUSH LR
 000001BE	     9801	LDR R0 [ SP + 4 ]
 000001C0	 10000012	MOV R1 lower 16-bits base(0), next at  0000019C
 000001C4	 00000114	MOVT R1 higher 16-bits var + 276
 000001C8	     6809	LDR R1 [ R1 + 0 ]
 000001CA	     4288	CMP R0 R1
 000001CC	 F280801B	BGE #54, goes to  00000206
 000001D0	     9801	LDR R0 [ SP + 4 ]
 000001D2	     2807	CMP R0 #7
 000001D4	 F2808004	BGE #8, goes to  000001E0
 000001D8	     2007	MOVS R0 #7
 000001DA	     9001	STR R0 [ SP + 4 ]
 000001DC	 F000B811	B #34, goes to  00000202
 000001E0	 00000010	MOV R0 lower 16-bits base(0), next at  000001C0
 000001E4	 0000010C	MOVT R0 higher 16-bits var + 268
 000001E8	     6800	LDR R0 [ R0 + 0 ]
 000001EA	     3808	SUBS R0 R0 #8
 000001EC	     9901	LDR R1 [ SP + 4 ]
 000001EE	     4281	CMP R1 R0
 000001F0	 F3408007	BLE #14, goes to  00000202
 000001F4	 0000000A	MOV R0 lower 16-bits base(0), next at  000001E0
 000001F8	 0000010C	MOVT R0 higher 16-bits var + 268
 000001FC	     6800	LDR R0 [ R0 + 0 ]
 000001FE	     3808	SUBS R0 R0 #8
 00000200	     9001	STR R0 [ SP + 4 ]
 00000202	 F000B830	B #96, goes to  00000266
 00000206	 00000009	MOV R0 lower 16-bits base(0), next at  000001F4
 0000020A	 00000114	MOVT R0 higher 16-bits var + 276
 0000020E	     6800	LDR R0 [ R0 + 0 ]
 00000210	     1DC0	ADDS R0 R0 #7
 00000212	     9901	LDR R1 [ SP + 4 ]
 00000214	     4281	CMP R1 R0
 00000216	 F2808009	BGE #18, goes to  0000022C
 0000021A	 0000000A	MOV R0 lower 16-bits base(0), next at  00000206
 0000021E	 00000114	MOVT R0 higher 16-bits var + 276
 00000222	     6800	LDR R0 [ R0 + 0 ]
 00000224	     1DC0	ADDS R0 R0 #7
 00000226	     9001	STR R0 [ SP + 4 ]
 00000228	 F000B81D	B #58, goes to  00000266
 0000022C	 00000009	MOV R0 lower 16-bits base(0), next at  0000021A
 00000230	 00000114	MOVT R0 higher 16-bits var + 276
 00000234	     6800	LDR R0 [ R0 + 0 ]
 00000236	 10000005	MOV R1 lower 16-bits base(0), next at  0000022C
 0000023A	 0000010C	MOVT R1 higher 16-bits var + 268
 0000023E	     6809	LDR R1 [ R1 + 0 ]
 00000240	     1840	ADDS R0 R0 R1
 00000242	     3808	SUBS R0 R0 #8
 00000244	     9901	LDR R1 [ SP + 4 ]
 00000246	     4281	CMP R1 R0
 00000248	 F340800D	BLE #26, goes to  00000266
 0000024C	 0000000B	MOV R0 lower 16-bits base(0), next at  00000236
 00000250	 00000114	MOVT R0 higher 16-bits var + 276
 00000254	     6800	LDR R0 [ R0 + 0 ]
 00000256	 10000005	MOV R1 lower 16-bits base(0), next at  0000024C
 0000025A	 0000010C	MOVT R1 higher 16-bits var + 268
 0000025E	     6809	LDR R1 [ R1 + 0 ]
 00000260	     1840	ADDS R0 R0 R1
 00000262	     3808	SUBS R0 R0 #8
 00000264	     9001	STR R0 [ SP + 4 ]
 00000266	     9802	LDR R0 [ SP + 8 ]
 00000268	     2807	CMP R0 #7
 0000026A	 F2808004	BGE #8, goes to  00000276
 0000026E	     2007	MOVS R0 #7
 00000270	     9002	STR R0 [ SP + 8 ]
 00000272	 F000B811	B #34, goes to  00000298
 00000276	 00000010	MOV R0 lower 16-bits base(0), next at  00000256
 0000027A	 00000110	MOVT R0 higher 16-bits var + 272
 0000027E	     6800	LDR R0 [ R0 + 0 ]
 00000280	     3808	SUBS R0 R0 #8
 00000282	     9902	LDR R1 [ SP + 8 ]
 00000284	     4281	CMP R1 R0
 00000286	 F3408007	BLE #14, goes to  00000298
 0000028A	 0000000A	MOV R0 lower 16-bits base(0), next at  00000276
 0000028E	 00000110	MOVT R0 higher 16-bits var + 272
 00000292	     6800	LDR R0 [ R0 + 0 ]
 00000294	     3808	SUBS R0 R0 #8
 00000296	     9002	STR R0 [ SP + 8 ]
 00000298	     20FF	MOVS R0 #255
 0000029A	 17000008	MOV R1 lower 16-bits base(7), next at  0000028A
 0000029E	 00000004	MOVT R1 higher 16-bits var(4)
 000002A2	     6809	LDR R1 [ R1 + 0 ]
 000002A4	     9A01	LDR R2 [ SP + 4 ]
 000002A6	     1FD2	SUBS R2 R2 #7
 000002A8	     9B02	LDR R3 [ SP + 8 ]
 000002AA	     1FDB	SUBS R3 R3 #7
 000002AC	     2402	MOVS R4 #2
 000002AE	 70D00080	BL Mod(  7) proc(13)
 000002B2	 F85DEB04	LDR LR [ SP ] + 4
 000002B6	     B002	ADD SP SP #8
 000002B8	     4770	BX LR
 000002BA	     B403	PUSH R0 R1
 000002BC	     B500	PUSH LR
 000002BE	     2000	MOVS R0 #0
 000002C0	     9901	LDR R1 [ SP + 4 ]
 000002C2	     7208	STRB R0 [ R1 + 8 ]
 000002C4	     2000	MOVS R0 #0
 000002C6	     9901	LDR R1 [ SP + 4 ]
 000002C8	     60C8	STR R0 [  R1 + 12 ]
 000002CA	     2000	MOVS R0 #0
 000002CC	     9901	LDR R1 [ SP + 4 ]
 000002CE	     6108	STR R0 [  R1 + 16 ]
 000002D0	 F85DEB04	LDR LR [ SP ] + 4
 000002D4	     B002	ADD SP SP #8
 000002D6	     4770	BX LR
 000002D8	     B403	PUSH R0 R1
 000002DA	     B500	PUSH LR
 000002DC	     9801	LDR R0 [ SP + 4 ]
 000002DE	     7A00	LDRB R0 [ R0 + 8 ]
 000002E0	     2800	CMP R0 #0
 000002E2	 F000800A	BEQ #20, goes to  000002FA
 000002E6	     9801	LDR R0 [ SP + 4 ]
 000002E8	     68C0	LDR R0 [ R0 + 12 ]
 000002EA	     9901	LDR R1 [ SP + 4 ]
 000002EC	     6909	LDR R1 [ R1 + 16 ]
 000002EE	     9A01	LDR R2 [ SP + 4 ]
 000002F0	     6812	LDR R2 [ R2 + 0 ]
 000002F2	     4790	BLX R2
 000002F4	     2000	MOVS R0 #0
 000002F6	     9901	LDR R1 [ SP + 4 ]
 000002F8	     7208	STRB R0 [ R1 + 8 ]
 000002FA	 F85DEB04	LDR LR [ SP ] + 4
 000002FE	     B002	ADD SP SP #8
 00000300	     4770	BX LR
 00000302	     B43F	PUSH R0 R1 R2 R3 R4 R5
 00000304	     B500	PUSH LR
 00000306	     9801	LDR R0 [ SP + 4 ]
 00000308	     7A00	LDRB R0 [ R0 + 8 ]
 0000030A	     2800	CMP R0 #0
 0000030C	 F000801D	BEQ #58, goes to  0000034A
 00000310	     9805	LDR R0 [ SP + 20 ]
 00000312	     9901	LDR R1 [ SP + 4 ]
 00000314	     68C9	LDR R1 [ R1 + 12 ]
 00000316	     4288	CMP R0 R1
 00000318	 F040800D	BNE #26, goes to  00000336
 0000031C	     9806	LDR R0 [ SP + 24 ]
 0000031E	     9901	LDR R1 [ SP + 4 ]
 00000320	     6909	LDR R1 [ R1 + 16 ]
 00000322	     4288	CMP R0 R1
 00000324	 F0408007	BNE #14, goes to  00000336
 00000328	     9803	LDR R0 [ SP + 12 ]
 0000032A	     6840	LDR R0 [ R0 + 4 ]
 0000032C	     9901	LDR R1 [ SP + 4 ]
 0000032E	     6849	LDR R1 [ R1 + 4 ]
 00000330	     4288	CMP R0 R1
 00000332	 F000800A	BEQ #20, goes to  0000034A
 00000336	     9801	LDR R0 [ SP + 4 ]
 00000338	     68C0	LDR R0 [ R0 + 12 ]
 0000033A	     9901	LDR R1 [ SP + 4 ]
 0000033C	     6909	LDR R1 [ R1 + 16 ]
 0000033E	     9A01	LDR R2 [ SP + 4 ]
 00000340	     6812	LDR R2 [ R2 + 0 ]
 00000342	     4790	BLX R2
 00000344	     2000	MOVS R0 #0
 00000346	     9901	LDR R1 [ SP + 4 ]
 00000348	     7208	STRB R0 [ R1 + 8 ]
 0000034A	     9801	LDR R0 [ SP + 4 ]
 0000034C	     7A00	LDRB R0 [ R0 + 8 ]
 0000034E	     2800	CMP R0 #0
 00000350	 F0408017	BNE #46, goes to  00000382
 00000354	     9805	LDR R0 [ SP + 20 ]
 00000356	     9906	LDR R1 [ SP + 24 ]
 00000358	     9A03	LDR R2 [ SP + 12 ]
 0000035A	     6852	LDR R2 [ R2 + 4 ]
 0000035C	     4790	BLX R2
 0000035E	     9801	LDR R0 [ SP + 4 ]
 00000360	     9903	LDR R1 [ SP + 12 ]
 00000362	     2202	MOVS R2 #2
 00000364	 F8513B04	LDR R3 [ R1 ] + 4
 00000368	 F8403B04	STR R3 [  R0 ] + 4
 0000036C	     1E52	SUBS R2 R2 #1
 0000036E	     D1F9	BNE #-14, goes to  00000364
 00000370	     9805	LDR R0 [ SP + 20 ]
 00000372	     9901	LDR R1 [ SP + 4 ]
 00000374	     60C8	STR R0 [  R1 + 12 ]
 00000376	     9806	LDR R0 [ SP + 24 ]
 00000378	     9901	LDR R1 [ SP + 4 ]
 0000037A	     6108	STR R0 [  R1 + 16 ]
 0000037C	     2001	MOVS R0 #1
 0000037E	     9901	LDR R1 [ SP + 4 ]
 00000380	     7208	STRB R0 [ R1 + 8 ]
 00000382	 F85DEB04	LDR LR [ SP ] + 4
 00000386	     B006	ADD SP SP #24
 00000388	     4770	BX LR
 0000038A	     B40F	PUSH R0 R1 R2 R3
 0000038C	     B500	PUSH LR
 0000038E	 0000007A	MOV R0 lower 16-bits base(0), next at  0000029A
 00000392	 000000B8	MOVT R0 higher 16-bits var + 184
 00000396	 10000004	MOV R1 lower 16-bits base(0), next at  0000038E
 0000039A	 00000014	MOVT R1 higher 16-bits var + 20
 0000039E	     9A01	LDR R2 [ SP + 4 ]
 000003A0	     9B02	LDR R3 [ SP + 8 ]
 000003A2	     9C03	LDR R4 [ SP + 12 ]
 000003A4	     9D04	LDR R5 [ SP + 16 ]
 000003A6	 F7FFFFAC	BL #-168, goes to  00000302
 000003AA	 F85DEB04	LDR LR [ SP ] + 4
 000003AE	     B004	ADD SP SP #16
 000003B0	     4770	BX LR
 000003B2	     B403	PUSH R0 R1
 000003B4	     B500	PUSH LR
 000003B6	 00000010	MOV R0 lower 16-bits base(0), next at  00000396
 000003BA	 000000B8	MOVT R0 higher 16-bits var + 184
 000003BE	 10000004	MOV R1 lower 16-bits base(0), next at  000003B6
 000003C2	 00000014	MOVT R1 higher 16-bits var + 20
 000003C6	 20000004	MOV R2 lower 16-bits base(0), next at  000003BE
 000003CA	 000000A8	MOVT R2 higher 16-bits var + 168
 000003CE	 30000004	MOV R3 lower 16-bits base(0), next at  000003C6
 000003D2	 00000000	MOVT R3 higher 16-bits var + 0
 000003D6	     9C01	LDR R4 [ SP + 4 ]
 000003D8	     9D02	LDR R5 [ SP + 8 ]
 000003DA	 F7FFFF92	BL #-220, goes to  00000302
 000003DE	 F85DEB04	LDR LR [ SP ] + 4
 000003E2	     B002	ADD SP SP #8
 000003E4	     4770	BX LR
 000003E6	     B500	PUSH LR
 000003E8	 0000000D	MOV R0 lower 16-bits base(0), next at  000003CE
 000003EC	 000000B8	MOVT R0 higher 16-bits var + 184
 000003F0	 10000004	MOV R1 lower 16-bits base(0), next at  000003E8
 000003F4	 00000014	MOVT R1 higher 16-bits var + 20
 000003F8	 F7FFFF6E	BL #-292, goes to  000002D8
 000003FC	 F85DEB04	LDR LR [ SP ] + 4
 00000400	     4770	BX LR
 00000402	     B403	PUSH R0 R1
 00000404	     B500	PUSH LR
 00000406	 0000000B	MOV R0 lower 16-bits base(0), next at  000003F0
 0000040A	 000000CC	MOVT R0 higher 16-bits var + 204
 0000040E	 10000004	MOV R1 lower 16-bits base(0), next at  00000406
 00000412	 00000014	MOVT R1 higher 16-bits var + 20
 00000416	 20000004	MOV R2 lower 16-bits base(0), next at  0000040E
 0000041A	 000000B0	MOVT R2 higher 16-bits var + 176
 0000041E	 30000004	MOV R3 lower 16-bits base(0), next at  00000416
 00000422	 00000000	MOVT R3 higher 16-bits var + 0
 00000426	     9C01	LDR R4 [ SP + 4 ]
 00000428	     9D02	LDR R5 [ SP + 8 ]
 0000042A	 F7FFFF6A	BL #-300, goes to  00000302
 0000042E	 F85DEB04	LDR LR [ SP ] + 4
 00000432	     B002	ADD SP SP #8
 00000434	     4770	BX LR
 00000436	     B40F	PUSH R0 R1 R2 R3
 00000438	     B500	PUSH LR
 0000043A	     9801	LDR R0 [ SP + 4 ]
 0000043C	     3810	SUBS R0 R0 #16
 0000043E	 10000010	MOV R1 lower 16-bits base(0), next at  0000041E
 00000442	 000000C4	MOVT R1 higher 16-bits var + 196
 00000446	     6809	LDR R1 [ R1 + 0 ]
 00000448	     4281	CMP R1 R0
 0000044A	 F340802C	BLE #88, goes to  000004A6
 0000044E	     9801	LDR R0 [ SP + 4 ]
 00000450	     9903	LDR R1 [ SP + 12 ]
 00000452	     1840	ADDS R0 R0 R1
 00000454	     3010	ADDS R0 R0 #16
 00000456	 1000000C	MOV R1 lower 16-bits base(0), next at  0000043E
 0000045A	 000000C4	MOVT R1 higher 16-bits var + 196
 0000045E	     6809	LDR R1 [ R1 + 0 ]
 00000460	     4281	CMP R1 R0
 00000462	 F2808020	BGE #64, goes to  000004A6
 00000466	     9802	LDR R0 [ SP + 8 ]
 00000468	     3810	SUBS R0 R0 #16
 0000046A	 1000000A	MOV R1 lower 16-bits base(0), next at  00000456
 0000046E	 000000C8	MOVT R1 higher 16-bits var + 200
 00000472	     6809	LDR R1 [ R1 + 0 ]
 00000474	     4281	CMP R1 R0
 00000476	 F3408016	BLE #44, goes to  000004A6
 0000047A	     9802	LDR R0 [ SP + 8 ]
 0000047C	     9904	LDR R1 [ SP + 16 ]
 0000047E	     1840	ADDS R0 R0 R1
 00000480	     3010	ADDS R0 R0 #16
 00000482	 1000000C	MOV R1 lower 16-bits base(0), next at  0000046A
 00000486	 000000C8	MOVT R1 higher 16-bits var + 200
 0000048A	     6809	LDR R1 [ R1 + 0 ]
 0000048C	     4281	CMP R1 R0
 0000048E	 F280800A	BGE #20, goes to  000004A6
 00000492	 00000008	MOV R0 lower 16-bits base(0), next at  00000482
 00000496	 000000B8	MOVT R0 higher 16-bits var + 184
 0000049A	 10000004	MOV R1 lower 16-bits base(0), next at  00000492
 0000049E	 00000014	MOVT R1 higher 16-bits var + 20
 000004A2	 F7FFFF19	BL #-462, goes to  000002D8
 000004A6	     9801	LDR R0 [ SP + 4 ]
 000004A8	     3808	SUBS R0 R0 #8
 000004AA	 10000008	MOV R1 lower 16-bits base(0), next at  0000049A
 000004AE	 000000D8	MOVT R1 higher 16-bits var + 216
 000004B2	     6809	LDR R1 [ R1 + 0 ]
 000004B4	     4281	CMP R1 R0
 000004B6	 F340802C	BLE #88, goes to  00000512
 000004BA	     9801	LDR R0 [ SP + 4 ]
 000004BC	     9903	LDR R1 [ SP + 12 ]
 000004BE	     1840	ADDS R0 R0 R1
 000004C0	     3008	ADDS R0 R0 #8
 000004C2	 1000000C	MOV R1 lower 16-bits base(0), next at  000004AA
 000004C6	 000000D8	MOVT R1 higher 16-bits var + 216
 000004CA	     6809	LDR R1 [ R1 + 0 ]
 000004CC	     4281	CMP R1 R0
 000004CE	 F2808020	BGE #64, goes to  00000512
 000004D2	     9802	LDR R0 [ SP + 8 ]
 000004D4	     3808	SUBS R0 R0 #8
 000004D6	 1000000A	MOV R1 lower 16-bits base(0), next at  000004C2
 000004DA	 000000DC	MOVT R1 higher 16-bits var + 220
 000004DE	     6809	LDR R1 [ R1 + 0 ]
 000004E0	     4281	CMP R1 R0
 000004E2	 F3408016	BLE #44, goes to  00000512
 000004E6	     9802	LDR R0 [ SP + 8 ]
 000004E8	     9904	LDR R1 [ SP + 16 ]
 000004EA	     1840	ADDS R0 R0 R1
 000004EC	     3008	ADDS R0 R0 #8
 000004EE	 1000000C	MOV R1 lower 16-bits base(0), next at  000004D6
 000004F2	 000000DC	MOVT R1 higher 16-bits var + 220
 000004F6	     6809	LDR R1 [ R1 + 0 ]
 000004F8	     4281	CMP R1 R0
 000004FA	 F280800A	BGE #20, goes to  00000512
 000004FE	 00000008	MOV R0 lower 16-bits base(0), next at  000004EE
 00000502	 000000CC	MOVT R0 higher 16-bits var + 204
 00000506	 10000004	MOV R1 lower 16-bits base(0), next at  000004FE
 0000050A	 00000014	MOVT R1 higher 16-bits var + 20
 0000050E	 F7FFFEE3	BL #-570, goes to  000002D8
 00000512	 F85DEB04	LDR LR [ SP ] + 4
 00000516	     B004	ADD SP SP #16
 00000518	     4770	BX LR
 0000051A	     B407	PUSH R0 R1 R2
 0000051C	     B500	PUSH LR
 0000051E	     9803	LDR R0 [ SP + 12 ]
 00000520	     6840	LDR R0 [ R0 + 4 ]
 00000522	 1000000E	MOV R1 lower 16-bits base(0), next at  00000506
 00000526	 00000028	MOVT R1 higher 16-bits var + 40
 0000052A	     4281	CMP R1 R0
 0000052C	 F040801D	BNE #58, goes to  0000056A
 00000530	     9802	LDR R0 [ SP + 8 ]
 00000532	     6800	LDR R0 [ R0 + 0 ]
 00000534	     2801	CMP R0 #1
 00000536	 F0408016	BNE #44, goes to  00000566
 0000053A	 0000000C	MOV R0 lower 16-bits base(0), next at  00000522
 0000053E	 000000B8	MOVT R0 higher 16-bits var + 184
 00000542	 10000004	MOV R1 lower 16-bits base(0), next at  0000053A
 00000546	 00000014	MOVT R1 higher 16-bits var + 20
 0000054A	 20000004	MOV R2 lower 16-bits base(0), next at  00000542
 0000054E	 000000A8	MOVT R2 higher 16-bits var + 168
 00000552	 30000004	MOV R3 lower 16-bits base(0), next at  0000054A
 00000556	 00000000	MOVT R3 higher 16-bits var + 0
 0000055A	     9C02	LDR R4 [ SP + 8 ]
 0000055C	     68A4	LDR R4 [ R4 + 8 ]
 0000055E	     9D02	LDR R5 [ SP + 8 ]
 00000560	     68ED	LDR R5 [ R5 + 12 ]
 00000562	 F7FFFECE	BL #-612, goes to  00000302
 00000566	 F000B8C2	B #388, goes to  000006EE
 0000056A	     9803	LDR R0 [ SP + 12 ]
 0000056C	     6840	LDR R0 [ R0 + 4 ]
 0000056E	 1000000E	MOV R1 lower 16-bits base(0), next at  00000552
 00000572	 00000058	MOVT R1 higher 16-bits var + 88
 00000576	     4281	CMP R1 R0
 00000578	 F040801D	BNE #58, goes to  000005B6
 0000057C	     9802	LDR R0 [ SP + 8 ]
 0000057E	     6800	LDR R0 [ R0 + 0 ]
 00000580	     2802	CMP R0 #2
 00000582	 F0408016	BNE #44, goes to  000005B2
 00000586	 0000000C	MOV R0 lower 16-bits base(0), next at  0000056E
 0000058A	 000000CC	MOVT R0 higher 16-bits var + 204
 0000058E	 10000004	MOV R1 lower 16-bits base(0), next at  00000586
 00000592	 00000014	MOVT R1 higher 16-bits var + 20
 00000596	 20000004	MOV R2 lower 16-bits base(0), next at  0000058E
 0000059A	 000000B0	MOVT R2 higher 16-bits var + 176
 0000059E	 30000004	MOV R3 lower 16-bits base(0), next at  00000596
 000005A2	 00000000	MOVT R3 higher 16-bits var + 0
 000005A6	     9C02	LDR R4 [ SP + 8 ]
 000005A8	     6864	LDR R4 [ R4 + 4 ]
 000005AA	     9D02	LDR R5 [ SP + 8 ]
 000005AC	     68AD	LDR R5 [ R5 + 8 ]
 000005AE	 F7FFFEA8	BL #-688, goes to  00000302
 000005B2	 F000B89C	B #312, goes to  000006EE
 000005B6	     9803	LDR R0 [ SP + 12 ]
 000005B8	     6840	LDR R0 [ R0 + 4 ]
 000005BA	 1800000E	MOV R1 lower 16-bits base(8), next at  0000059E
 000005BE	 00000002	MOVT R1 higher 16-bits var(2)
 000005C2	     4281	CMP R1 R0
 000005C4	 F0408093	BNE #294, goes to  000006EE
 000005C8	     9802	LDR R0 [ SP + 8 ]
 000005CA	     6800	LDR R0 [ R0 + 0 ]
 000005CC	     2800	CMP R0 #0
 000005CE	 F040804A	BNE #148, goes to  00000666
 000005D2	     9801	LDR R0 [ SP + 4 ]
 000005D4	     2800	CMP R0 #0
 000005D6	     BF08	IT EQ
 000005D8	 EC025524	TrapEQ 4 at pos 4818
 000005DC	     6900	LDR R0 [ R0 + 16 ]
 000005DE	     2800	CMP R0 #0
 000005E0	 F3408041	BLE #130, goes to  00000666
 000005E4	     9801	LDR R0 [ SP + 4 ]
 000005E6	     2800	CMP R0 #0
 000005E8	     BF08	IT EQ
 000005EA	 EC0255E4	TrapEQ 4 at pos 4830
 000005EE	     6940	LDR R0 [ R0 + 20 ]
 000005F0	     2800	CMP R0 #0
 000005F2	 F3408038	BLE #112, goes to  00000666
 000005F6	     9801	LDR R0 [ SP + 4 ]
 000005F8	     2800	CMP R0 #0
 000005FA	     BF08	IT EQ
 000005FC	 EC026004	TrapEQ 4 at pos 4864
 00000600	     6880	LDR R0 [ R0 + 8 ]
 00000602	     9901	LDR R1 [ SP + 4 ]
 00000604	     2900	CMP R1 #0
 00000606	     BF08	IT EQ
 00000608	 EC026054	TrapEQ 4 at pos 4869
 0000060C	     68C9	LDR R1 [ R1 + 12 ]
 0000060E	     9A01	LDR R2 [ SP + 4 ]
 00000610	     2A00	CMP R2 #0
 00000612	     BF08	IT EQ
 00000614	 EC0260A4	TrapEQ 4 at pos 4874
 00000618	     6912	LDR R2 [ R2 + 16 ]
 0000061A	     9B01	LDR R3 [ SP + 4 ]
 0000061C	     2B00	CMP R3 #0
 0000061E	     BF08	IT EQ
 00000620	 EC0260F4	TrapEQ 4 at pos 4879
 00000624	     695B	LDR R3 [ R3 + 20 ]
 00000626	 F7FFFF06	BL #-500, goes to  00000436
 0000062A	     2000	MOVS R0 #0
 0000062C	     9901	LDR R1 [ SP + 4 ]
 0000062E	     2900	CMP R1 #0
 00000630	     BF08	IT EQ
 00000632	 EC0263E4	TrapEQ 4 at pos 4926
 00000636	     6889	LDR R1 [ R1 + 8 ]
 00000638	     9A01	LDR R2 [ SP + 4 ]
 0000063A	     2A00	CMP R2 #0
 0000063C	     BF08	IT EQ
 0000063E	 EC026434	TrapEQ 4 at pos 4931
 00000642	     68D2	LDR R2 [ R2 + 12 ]
 00000644	     9B01	LDR R3 [ SP + 4 ]
 00000646	     2B00	CMP R3 #0
 00000648	     BF08	IT EQ
 0000064A	 EC026484	TrapEQ 4 at pos 4936
 0000064E	     691B	LDR R3 [ R3 + 16 ]
 00000650	     9C01	LDR R4 [ SP + 4 ]
 00000652	     2C00	CMP R4 #0
 00000654	     BF08	IT EQ
 00000656	 EC0264D4	TrapEQ 4 at pos 4941
 0000065A	     6964	LDR R4 [ R4 + 20 ]
 0000065C	     2500	MOVS R5 #0
 0000065E	 70C001D8	BL Mod(  7) proc(12)
 00000662	 F000B844	B #136, goes to  000006EE
 00000666	     9802	LDR R0 [ SP + 8 ]
 00000668	     6800	LDR R0 [ R0 + 0 ]
 0000066A	     2801	CMP R0 #1
 0000066C	 F040803F	BNE #126, goes to  000006EE
 00000670	     9801	LDR R0 [ SP + 4 ]
 00000672	     2800	CMP R0 #0
 00000674	     BF08	IT EQ
 00000676	 EC027104	TrapEQ 4 at pos 5008
 0000067A	     9902	LDR R1 [ SP + 8 ]
 0000067C	     6889	LDR R1 [ R1 + 8 ]
 0000067E	     68C0	LDR R0 [ R0 + 12 ]
 00000680	     4281	CMP R1 R0
 00000682	 F2808034	BGE #104, goes to  000006EE
 00000686	     9801	LDR R0 [ SP + 4 ]
 00000688	     2800	CMP R0 #0
 0000068A	     BF08	IT EQ
 0000068C	 EC0272E4	TrapEQ 4 at pos 5038
 00000690	     6880	LDR R0 [ R0 + 8 ]
 00000692	     9902	LDR R1 [ SP + 8 ]
 00000694	     6889	LDR R1 [ R1 + 8 ]
 00000696	     9A01	LDR R2 [ SP + 4 ]
 00000698	     2A00	CMP R2 #0
 0000069A	     BF08	IT EQ
 0000069C	 EC027384	TrapEQ 4 at pos 5048
 000006A0	     6912	LDR R2 [ R2 + 16 ]
 000006A2	     9B01	LDR R3 [ SP + 4 ]
 000006A4	     2B00	CMP R3 #0
 000006A6	     BF08	IT EQ
 000006A8	 EC0273D4	TrapEQ 4 at pos 5053
 000006AC	     68DB	LDR R3 [ R3 + 12 ]
 000006AE	     9C02	LDR R4 [ SP + 8 ]
 000006B0	     68A4	LDR R4 [ R4 + 8 ]
 000006B2	     1B1B	SUBS R3 R3 R4
 000006B4	 F7FFFEBF	BL #-642, goes to  00000436
 000006B8	     2000	MOVS R0 #0
 000006BA	     9901	LDR R1 [ SP + 4 ]
 000006BC	     2900	CMP R1 #0
 000006BE	     BF08	IT EQ
 000006C0	 EC027724	TrapEQ 4 at pos 5106
 000006C4	     6889	LDR R1 [ R1 + 8 ]
 000006C6	     9A02	LDR R2 [ SP + 8 ]
 000006C8	     6892	LDR R2 [ R2 + 8 ]
 000006CA	     9B01	LDR R3 [ SP + 4 ]
 000006CC	     2B00	CMP R3 #0
 000006CE	     BF08	IT EQ
 000006D0	 EC0277C4	TrapEQ 4 at pos 5116
 000006D4	     691B	LDR R3 [ R3 + 16 ]
 000006D6	     9C01	LDR R4 [ SP + 4 ]
 000006D8	     2C00	CMP R4 #0
 000006DA	     BF08	IT EQ
 000006DC	 EC028014	TrapEQ 4 at pos 5121
 000006E0	     68E4	LDR R4 [ R4 + 12 ]
 000006E2	     9D02	LDR R5 [ SP + 8 ]
 000006E4	     68AD	LDR R5 [ R5 + 8 ]
 000006E6	     1B64	SUBS R4 R4 R5
 000006E8	     2500	MOVS R5 #0
 000006EA	 70C00046	BL Mod(  7) proc(12)
 000006EE	 F85DEB04	LDR LR [ SP ] + 4
 000006F2	     B003	ADD SP SP #12
 000006F4	     4770	BX LR
 000006F6	     B081	SUB SP SP #4
 000006F8	     B407	PUSH R0 R1 R2
 000006FA	     B500	PUSH LR
 000006FC	 080000A1	MOV R0 lower 16-bits base(8), next at  000005BA
 00000700	 00000003	MOVT R0 higher 16-bits var(3)
 00000704	     6800	LDR R0 [ R0 + 0 ]
 00000706	     9901	LDR R1 [ SP + 4 ]
 00000708	     1840	ADDS R0 R0 R1
 0000070A	     9902	LDR R1 [ SP + 8 ]
 0000070C	     1840	ADDS R0 R0 R1
 0000070E	     9903	LDR R1 [ SP + 12 ]
 00000710	 60400013	BL Mod(  6) proc(4)
 00000714	     2000	MOVS R0 #0
 00000716	 1800000D	MOV R1 lower 16-bits base(8), next at  000006FC
 0000071A	 00000003	MOVT R1 higher 16-bits var(3)
 0000071E	     6809	LDR R1 [ R1 + 0 ]
 00000720	     2200	MOVS R2 #0
 00000722	     9B01	LDR R3 [ SP + 4 ]
 00000724	     9C02	LDR R4 [ SP + 8 ]
 00000726	     191B	ADDS R3 R3 R4
 00000728	     9C03	LDR R4 [ SP + 12 ]
 0000072A	     2500	MOVS R5 #0
 0000072C	 70C0000E	BL Mod(  7) proc(12)
 00000730	     A804	ADD R0 SP #16
 00000732	 1800000E	MOV R1 lower 16-bits base(8), next at  00000716
 00000736	 00000001	MOVT R1 higher 16-bits var(1)
 0000073A	     DF00	SVC #0
 0000073C	     9804	LDR R0 [ SP + 16 ]
 0000073E	     2800	CMP R0 #0
 00000740	     BF08	IT EQ
 00000742	 EC02A434	TrapEQ 4 at pos 5443
 00000746	 F2AF212D	ADR R1 L 0000051B
 0000074A	     6181	STR R1 [  R0 + 24 ]
 0000074C	     9801	LDR R0 [ SP + 4 ]
 0000074E	     9903	LDR R1 [ SP + 12 ]
 00000750	     9A04	LDR R2 [ SP + 16 ]
 00000752	 80C00013	BL Mod(  8) proc(12)
 00000756	     A804	ADD R0 SP #16
 00000758	 18000013	MOV R1 lower 16-bits base(8), next at  00000732
 0000075C	 00000001	MOVT R1 higher 16-bits var(1)
 00000760	     DF00	SVC #0
 00000762	     9804	LDR R0 [ SP + 16 ]
 00000764	     2800	CMP R0 #0
 00000766	     BF08	IT EQ
 00000768	 EC02B2F4	TrapEQ 4 at pos 5551
 0000076C	 F2AF2155	ADR R1 L 0000051B
 00000770	     6181	STR R1 [  R0 + 24 ]
 00000772	     9802	LDR R0 [ SP + 8 ]
 00000774	     9903	LDR R1 [ SP + 12 ]
 00000776	     9A04	LDR R2 [ SP + 16 ]
 00000778	 80C00013	BL Mod(  8) proc(12)
 0000077C	 F85DEB04	LDR LR [ SP ] + 4
 00000780	     B004	ADD SP SP #16
 00000782	     4770	BX LR
 00000784	     B401	PUSH R0
 00000786	     B500	PUSH LR
 00000788	 00000018	MOV R0 lower 16-bits base(0), next at  00000758
 0000078C	 0000010C	MOVT R0 higher 16-bits var + 268
 00000790	     6800	LDR R0 [ R0 + 0 ]
 00000792	 F85DEB04	LDR LR [ SP ] + 4
 00000796	     B001	ADD SP SP #4
 00000798	     4770	BX LR
 0000079A	     B401	PUSH R0
 0000079C	     B500	PUSH LR
 0000079E	 0000000B	MOV R0 lower 16-bits base(0), next at  00000788
 000007A2	 00000110	MOVT R0 higher 16-bits var + 272
 000007A6	     6800	LDR R0 [ R0 + 0 ]
 000007A8	 F85DEB04	LDR LR [ SP ] + 4
 000007AC	     B001	ADD SP SP #4
 000007AE	     4770	BX LR
 000007B0	     B081	SUB SP SP #4
 000007B2	     B403	PUSH R0 R1
 000007B4	     B500	PUSH LR
 000007B6	     A803	ADD R0 SP #12
 000007B8	 1800000D	MOV R1 lower 16-bits base(8), next at  0000079E
 000007BC	 00000001	MOVT R1 higher 16-bits var(1)
 000007C0	     DF00	SVC #0
 000007C2	     9803	LDR R0 [ SP + 12 ]
 000007C4	     2800	CMP R0 #0
 000007C6	     BF08	IT EQ
 000007C8	 EC02E324	TrapEQ 4 at pos 5938
 000007CC	 F2AF21B5	ADR R1 L 0000051B
 000007D0	     6181	STR R1 [  R0 + 24 ]
 000007D2	     9801	LDR R0 [ SP + 4 ]
 000007D4	     9902	LDR R1 [ SP + 8 ]
 000007D6	     9A03	LDR R2 [ SP + 12 ]
 000007D8	 80D00030	BL Mod(  8) proc(13)
 000007DC	 F85DEB04	LDR LR [ SP ] + 4
 000007E0	     B003	ADD SP SP #12
 000007E2	     4770	BX LR
 000007E4	     B401	PUSH R0
 000007E6	     B500	PUSH LR
 000007E8	 00000018	MOV R0 lower 16-bits base(0), next at  000007B8
 000007EC	 0000010C	MOVT R0 higher 16-bits var + 268
 000007F0	     6800	LDR R0 [ R0 + 0 ]
 000007F2	     2800	CMP R0 #0
 000007F4	     BFD8	IT LE
 000007F6	 EC02F416	TrapLE 6 at pos 6081
 000007FA	     9901	LDR R1 [ SP + 4 ]
 000007FC	 FBB1F0F0	UDIV R0 R1 R0
 00000800	 1000000C	MOV R1 lower 16-bits base(0), next at  000007E8
 00000804	 0000010C	MOVT R1 higher 16-bits var + 268
 00000808	     6809	LDR R1 [ R1 + 0 ]
 0000080A	     4348	MULS R0 R1 R0
 0000080C	 F85DEB04	LDR LR [ SP ] + 4
 00000810	     B001	ADD SP SP #4
 00000812	     4770	BX LR
 00000814	     B401	PUSH R0
 00000816	     B500	PUSH LR
 00000818	 0000000C	MOV R0 lower 16-bits base(0), next at  00000800
 0000081C	 0000010C	MOVT R0 higher 16-bits var + 268
 00000820	     6800	LDR R0 [ R0 + 0 ]
 00000822	     2800	CMP R0 #0
 00000824	     BFD8	IT LE
 00000826	 EC030206	TrapLE 6 at pos 6176
 0000082A	     9901	LDR R1 [ SP + 4 ]
 0000082C	 FBB1F0F0	UDIV R0 R1 R0
 00000830	 1000000C	MOV R1 lower 16-bits base(0), next at  00000818
 00000834	 0000010C	MOVT R1 higher 16-bits var + 268
 00000838	     6809	LDR R1 [ R1 + 0 ]
 0000083A	     4348	MULS R0 R1 R0
 0000083C	 10000006	MOV R1 lower 16-bits base(0), next at  00000830
 00000840	 0000010C	MOVT R1 higher 16-bits var + 268
 00000844	     6809	LDR R1 [ R1 + 0 ]
 00000846	     10C9	ASRS R1 R1 #3
 00000848	     2205	MOVS R2 #5
 0000084A	     4351	MULS R1 R2 R1
 0000084C	     1840	ADDS R0 R0 R1
 0000084E	 F85DEB04	LDR LR [ SP ] + 4
 00000852	     B001	ADD SP SP #4
 00000854	     4770	BX LR
 00000856	     B085	SUB SP SP #20
 00000858	     B401	PUSH R0
 0000085A	     B500	PUSH LR
 0000085C	     9801	LDR R0 [ SP + 4 ]
 0000085E	     2100	MOVS R1 #0
 00000860	     AA03	ADD R2 SP #12
 00000862	     AB04	ADD R3 SP #16
 00000864	     AC05	ADD R4 SP #20
 00000866	     AD06	ADD R5 SP #24
 00000868	 80B00048	BL Mod(  8) proc(11)
 0000086C	     9803	LDR R0 [ SP + 12 ]
 0000086E	     2800	CMP R0 #0
 00000870	     BF08	IT EQ
 00000872	 EC031704	TrapEQ 4 at pos 6384
 00000876	 1000001D	MOV R1 lower 16-bits base(0), next at  0000083C
 0000087A	 00000110	MOVT R1 higher 16-bits var + 272
 0000087E	     6809	LDR R1 [ R1 + 0 ]
 00000880	     10C9	ASRS R1 R1 #3
 00000882	     6940	LDR R0 [ R0 + 20 ]
 00000884	     4288	CMP R0 R1
 00000886	 F2C08008	BLT #16, goes to  0000089A
 0000088A	 0000000A	MOV R0 lower 16-bits base(0), next at  00000876
 0000088E	 00000110	MOVT R0 higher 16-bits var + 272
 00000892	     6800	LDR R0 [ R0 + 0 ]
 00000894	     9002	STR R0 [ SP + 8 ]
 00000896	 F000B80F	B #30, goes to  000008B8
 0000089A	     9806	LDR R0 [ SP + 24 ]
 0000089C	     2800	CMP R0 #0
 0000089E	     BF08	IT EQ
 000008A0	 EC032194	TrapEQ 4 at pos 6425
 000008A4	     9906	LDR R1 [ SP + 24 ]
 000008A6	     2900	CMP R1 #0
 000008A8	     BF08	IT EQ
 000008AA	 EC032214	TrapEQ 4 at pos 6433
 000008AE	     6949	LDR R1 [ R1 + 20 ]
 000008B0	     1049	ASRS R1 R1 #1
 000008B2	     68C0	LDR R0 [ R0 + 12 ]
 000008B4	     1840	ADDS R0 R0 R1
 000008B6	     9002	STR R0 [ SP + 8 ]
 000008B8	     9802	LDR R0 [ SP + 8 ]
 000008BA	 F85DEB04	LDR LR [ SP ] + 4
 000008BE	     B006	ADD SP SP #24
 000008C0	     4770	BX LR
 000008C2	     B407	PUSH R0 R1 R2
 000008C4	     B500	PUSH LR
 000008C6	 0000001E	MOV R0 lower 16-bits base(0), next at  0000088A
 000008CA	 000000D4	MOVT R0 higher 16-bits var + 212
 000008CE	     7800	LDRB R0 [ R0 + 0 ]
 000008D0	     2800	CMP R0 #0
 000008D2	 F0008010	BEQ #32, goes to  000008F6
 000008D6	 00000008	MOV R0 lower 16-bits base(0), next at  000008C6
 000008DA	 000000D8	MOVT R0 higher 16-bits var + 216
 000008DE	     6800	LDR R0 [ R0 + 0 ]
 000008E0	     9902	LDR R1 [ SP + 8 ]
 000008E2	     6008	STR R0 [  R1 + 0 ]
 000008E4	 00000007	MOV R0 lower 16-bits base(0), next at  000008D6
 000008E8	 000000DC	MOVT R0 higher 16-bits var + 220
 000008EC	     6800	LDR R0 [ R0 + 0 ]
 000008EE	     9903	LDR R1 [ SP + 12 ]
 000008F0	     6008	STR R0 [  R1 + 0 ]
 000008F2	 F000B81A	B #52, goes to  0000092A
 000008F6	 00000009	MOV R0 lower 16-bits base(0), next at  000008E4
 000008FA	 0000010C	MOVT R0 higher 16-bits var + 268
 000008FE	     6800	LDR R0 [ R0 + 0 ]
 00000900	     2800	CMP R0 #0
 00000902	     BFD8	IT LE
 00000904	 EC0335F6	TrapLE 6 at pos 6623
 00000908	     9901	LDR R1 [ SP + 4 ]
 0000090A	 FBB1F0F0	UDIV R0 R1 R0
 0000090E	 1000000C	MOV R1 lower 16-bits base(0), next at  000008F6
 00000912	 0000010C	MOVT R1 higher 16-bits var + 268
 00000916	     6809	LDR R1 [ R1 + 0 ]
 00000918	     4348	MULS R0 R1 R0
 0000091A	     9902	LDR R1 [ SP + 8 ]
 0000091C	     6008	STR R0 [  R1 + 0 ]
 0000091E	     9802	LDR R0 [ SP + 8 ]
 00000920	     6800	LDR R0 [ R0 + 0 ]
 00000922	 F7FFFF98	BL #-208, goes to  00000856
 00000926	     9903	LDR R1 [ SP + 12 ]
 00000928	     6008	STR R0 [  R1 + 0 ]
 0000092A	 F85DEB04	LDR LR [ SP ] + 4
 0000092E	     B003	ADD SP SP #12
 00000930	     4770	BX LR
 00000932	     B089	SUB SP SP #36
 00000934	     B401	PUSH R0
 00000936	     B500	PUSH LR
 00000938	 00000015	MOV R0 lower 16-bits base(0), next at  0000090E
 0000093C	 00000110	MOVT R0 higher 16-bits var + 272
 00000940	     6800	LDR R0 [ R0 + 0 ]
 00000942	     2103	MOVS R1 #3
 00000944	 FBB0F0F1	UDIV R0 R0 R1
 00000948	 10000008	MOV R1 lower 16-bits base(0), next at  00000938
 0000094C	 00000110	MOVT R1 higher 16-bits var + 272
 00000950	     6809	LDR R1 [ R1 + 0 ]
 00000952	     1A08	SUBS R0 R1 R0
 00000954	     9005	STR R0 [ SP + 20 ]
 00000956	     9805	LDR R0 [ SP + 20 ]
 00000958	     1040	ASRS R0 R0 #1
 0000095A	     9905	LDR R1 [ SP + 20 ]
 0000095C	     1A08	SUBS R0 R1 R0
 0000095E	     9004	STR R0 [ SP + 16 ]
 00000960	 0000000C	MOV R0 lower 16-bits base(0), next at  00000948
 00000964	 00000110	MOVT R0 higher 16-bits var + 272
 00000968	     6800	LDR R0 [ R0 + 0 ]
 0000096A	     2105	MOVS R1 #5
 0000096C	 FBB0F0F1	UDIV R0 R0 R1
 00000970	     9003	STR R0 [ SP + 12 ]
 00000972	 00000009	MOV R0 lower 16-bits base(0), next at  00000960
 00000976	 00000110	MOVT R0 higher 16-bits var + 272
 0000097A	     6800	LDR R0 [ R0 + 0 ]
 0000097C	     210A	MOVS R1 #10
 0000097E	 FBB0F0F1	UDIV R0 R0 R1
 00000982	     9002	STR R0 [ SP + 8 ]
 00000984	     9801	LDR R0 [ SP + 4 ]
 00000986	 1000000A	MOV R1 lower 16-bits base(0), next at  00000972
 0000098A	 00000110	MOVT R1 higher 16-bits var + 272
 0000098E	     6809	LDR R1 [ R1 + 0 ]
 00000990	     AA07	ADD R2 SP #28
 00000992	     AB08	ADD R3 SP #32
 00000994	     AC09	ADD R4 SP #36
 00000996	     AD0A	ADD R5 SP #40
 00000998	 80B00098	BL Mod(  8) proc(11)
 0000099C	     9807	LDR R0 [ SP + 28 ]
 0000099E	     2800	CMP R0 #0
 000009A0	     BF08	IT EQ
 000009A2	 EC0361B4	TrapEQ 4 at pos 6939
 000009A6	 10000010	MOV R1 lower 16-bits base(0), next at  00000986
 000009AA	 00000110	MOVT R1 higher 16-bits var + 272
 000009AE	     6809	LDR R1 [ R1 + 0 ]
 000009B0	     10C9	ASRS R1 R1 #3
 000009B2	     6940	LDR R0 [ R0 + 20 ]
 000009B4	     4288	CMP R0 R1
 000009B6	 F2C08008	BLT #16, goes to  000009CA
 000009BA	 0000000A	MOV R0 lower 16-bits base(0), next at  000009A6
 000009BE	 00000110	MOVT R0 higher 16-bits var + 272
 000009C2	     6800	LDR R0 [ R0 + 0 ]
 000009C4	     9006	STR R0 [ SP + 24 ]
 000009C6	 F000B882	B #260, goes to  00000ACE
 000009CA	     980A	LDR R0 [ SP + 40 ]
 000009CC	     2800	CMP R0 #0
 000009CE	     BF08	IT EQ
 000009D0	 EC036444	TrapEQ 4 at pos 6980
 000009D4	 1000000D	MOV R1 lower 16-bits base(0), next at  000009BA
 000009D8	 00000110	MOVT R1 higher 16-bits var + 272
 000009DC	     6809	LDR R1 [ R1 + 0 ]
 000009DE	     9A02	LDR R2 [ SP + 8 ]
 000009E0	     1A89	SUBS R1 R1 R2
 000009E2	     6940	LDR R0 [ R0 + 20 ]
 000009E4	     4288	CMP R0 R1
 000009E6	 F2C0800B	BLT #22, goes to  00000A00
 000009EA	     980A	LDR R0 [ SP + 40 ]
 000009EC	     2800	CMP R0 #0
 000009EE	     BF08	IT EQ
 000009F0	 EC0365F4	TrapEQ 4 at pos 7007
 000009F4	     68C0	LDR R0 [ R0 + 12 ]
 000009F6	     9905	LDR R1 [ SP + 20 ]
 000009F8	     1840	ADDS R0 R0 R1
 000009FA	     9006	STR R0 [ SP + 24 ]
 000009FC	 F000B867	B #206, goes to  00000ACE
 00000A00	     980A	LDR R0 [ SP + 40 ]
 00000A02	     2800	CMP R0 #0
 00000A04	     BF08	IT EQ
 00000A06	 EC036744	TrapEQ 4 at pos 7028
 00000A0A	     9905	LDR R1 [ SP + 20 ]
 00000A0C	     9A02	LDR R2 [ SP + 8 ]
 00000A0E	     1A89	SUBS R1 R1 R2
 00000A10	     6940	LDR R0 [ R0 + 20 ]
 00000A12	     4288	CMP R0 R1
 00000A14	 F2C0800B	BLT #22, goes to  00000A2E
 00000A18	     980A	LDR R0 [ SP + 40 ]
 00000A1A	     2800	CMP R0 #0
 00000A1C	     BF08	IT EQ
 00000A1E	 EC0370F4	TrapEQ 4 at pos 7055
 00000A22	     68C0	LDR R0 [ R0 + 12 ]
 00000A24	     9904	LDR R1 [ SP + 16 ]
 00000A26	     1840	ADDS R0 R0 R1
 00000A28	     9006	STR R0 [ SP + 24 ]
 00000A2A	 F000B850	B #160, goes to  00000ACE
 00000A2E	     980A	LDR R0 [ SP + 40 ]
 00000A30	     2800	CMP R0 #0
 00000A32	     BF08	IT EQ
 00000A34	 EC037244	TrapEQ 4 at pos 7076
 00000A38	     9904	LDR R1 [ SP + 16 ]
 00000A3A	     9A02	LDR R2 [ SP + 8 ]
 00000A3C	     1A89	SUBS R1 R1 R2
 00000A3E	     6940	LDR R0 [ R0 + 20 ]
 00000A40	     4288	CMP R0 R1
 00000A42	 F2C0800B	BLT #22, goes to  00000A5C
 00000A46	     980A	LDR R0 [ SP + 40 ]
 00000A48	     2800	CMP R0 #0
 00000A4A	     BF08	IT EQ
 00000A4C	 EC0373F4	TrapEQ 4 at pos 7103
 00000A50	     68C0	LDR R0 [ R0 + 12 ]
 00000A52	     9903	LDR R1 [ SP + 12 ]
 00000A54	     1840	ADDS R0 R0 R1
 00000A56	     9006	STR R0 [ SP + 24 ]
 00000A58	 F000B839	B #114, goes to  00000ACE
 00000A5C	     980A	LDR R0 [ SP + 40 ]
 00000A5E	     9908	LDR R1 [ SP + 32 ]
 00000A60	     4288	CMP R0 R1
 00000A62	 F0008011	BEQ #34, goes to  00000A88
 00000A66	     980A	LDR R0 [ SP + 40 ]
 00000A68	     2800	CMP R0 #0
 00000A6A	     BF08	IT EQ
 00000A6C	 EC037684	TrapEQ 4 at pos 7144
 00000A70	     990A	LDR R1 [ SP + 40 ]
 00000A72	     2900	CMP R1 #0
 00000A74	     BF08	IT EQ
 00000A76	 EC037704	TrapEQ 4 at pos 7152
 00000A7A	     6949	LDR R1 [ R1 + 20 ]
 00000A7C	     1049	ASRS R1 R1 #1
 00000A7E	     68C0	LDR R0 [ R0 + 12 ]
 00000A80	     1840	ADDS R0 R0 R1
 00000A82	     9006	STR R0 [ SP + 24 ]
 00000A84	 F000B823	B #70, goes to  00000ACE
 00000A88	     9808	LDR R0 [ SP + 32 ]
 00000A8A	     2800	CMP R0 #0
 00000A8C	     BF08	IT EQ
 00000A8E	 EC038064	TrapEQ 4 at pos 7174
 00000A92	     6940	LDR R0 [ R0 + 20 ]
 00000A94	     9903	LDR R1 [ SP + 12 ]
 00000A96	     4288	CMP R0 R1
 00000A98	 F2C0800A	BLT #20, goes to  00000AB0
 00000A9C	     9808	LDR R0 [ SP + 32 ]
 00000A9E	     2800	CMP R0 #0
 00000AA0	     BF08	IT EQ
 00000AA2	 EC0381C4	TrapEQ 4 at pos 7196
 00000AA6	     6940	LDR R0 [ R0 + 20 ]
 00000AA8	     1040	ASRS R0 R0 #1
 00000AAA	     9006	STR R0 [ SP + 24 ]
 00000AAC	 F000B80F	B #30, goes to  00000ACE
 00000AB0	     9809	LDR R0 [ SP + 36 ]
 00000AB2	     2800	CMP R0 #0
 00000AB4	     BF08	IT EQ
 00000AB6	 EC038364	TrapEQ 4 at pos 7222
 00000ABA	     9909	LDR R1 [ SP + 36 ]
 00000ABC	     2900	CMP R1 #0
 00000ABE	     BF08	IT EQ
 00000AC0	 EC0383E4	TrapEQ 4 at pos 7230
 00000AC4	     6949	LDR R1 [ R1 + 20 ]
 00000AC6	     1049	ASRS R1 R1 #1
 00000AC8	     68C0	LDR R0 [ R0 + 12 ]
 00000ACA	     1840	ADDS R0 R0 R1
 00000ACC	     9006	STR R0 [ SP + 24 ]
 00000ACE	     9806	LDR R0 [ SP + 24 ]
 00000AD0	 F85DEB04	LDR LR [ SP ] + 4
 00000AD4	     B00A	ADD SP SP #40
 00000AD6	     4770	BX LR
 00000AD8	     B407	PUSH R0 R1 R2
 00000ADA	     B500	PUSH LR
 00000ADC	 00000084	MOV R0 lower 16-bits base(0), next at  000009D4
 00000AE0	 000000D4	MOVT R0 higher 16-bits var + 212
 00000AE4	     7800	LDRB R0 [ R0 + 0 ]
 00000AE6	     2800	CMP R0 #0
 00000AE8	 F0008010	BEQ #32, goes to  00000B0C
 00000AEC	 00000008	MOV R0 lower 16-bits base(0), next at  00000ADC
 00000AF0	 000000D8	MOVT R0 higher 16-bits var + 216
 00000AF4	     6800	LDR R0 [ R0 + 0 ]
 00000AF6	     9902	LDR R1 [ SP + 8 ]
 00000AF8	     6008	STR R0 [  R1 + 0 ]
 00000AFA	 00000007	MOV R0 lower 16-bits base(0), next at  00000AEC
 00000AFE	 000000DC	MOVT R0 higher 16-bits var + 220
 00000B02	     6800	LDR R0 [ R0 + 0 ]
 00000B04	     9903	LDR R1 [ SP + 12 ]
 00000B06	     6008	STR R0 [  R1 + 0 ]
 00000B08	 F000B823	B #70, goes to  00000B52
 00000B0C	 00000009	MOV R0 lower 16-bits base(0), next at  00000AFA
 00000B10	 0000010C	MOVT R0 higher 16-bits var + 268
 00000B14	     6800	LDR R0 [ R0 + 0 ]
 00000B16	     2800	CMP R0 #0
 00000B18	     BFD8	IT LE
 00000B1A	 EC03A026	TrapLE 6 at pos 7426
 00000B1E	     9901	LDR R1 [ SP + 4 ]
 00000B20	 FBB1F0F0	UDIV R0 R1 R0
 00000B24	 1000000C	MOV R1 lower 16-bits base(0), next at  00000B0C
 00000B28	 0000010C	MOVT R1 higher 16-bits var + 268
 00000B2C	     6809	LDR R1 [ R1 + 0 ]
 00000B2E	     4348	MULS R0 R1 R0
 00000B30	 10000006	MOV R1 lower 16-bits base(0), next at  00000B24
 00000B34	 0000010C	MOVT R1 higher 16-bits var + 268
 00000B38	     6809	LDR R1 [ R1 + 0 ]
 00000B3A	     10C9	ASRS R1 R1 #3
 00000B3C	     2205	MOVS R2 #5
 00000B3E	     4351	MULS R1 R2 R1
 00000B40	     1840	ADDS R0 R0 R1
 00000B42	     9902	LDR R1 [ SP + 8 ]
 00000B44	     6008	STR R0 [  R1 + 0 ]
 00000B46	     9802	LDR R0 [ SP + 8 ]
 00000B48	     6800	LDR R0 [ R0 + 0 ]
 00000B4A	 F7FFFEF2	BL #-540, goes to  00000932
 00000B4E	     9903	LDR R1 [ SP + 12 ]
 00000B50	     6008	STR R0 [  R1 + 0 ]
 00000B52	 F85DEB04	LDR LR [ SP ] + 4
 00000B56	     B003	ADD SP SP #12
 00000B58	     4770	BX LR
 00000B5A	     B500	PUSH LR
 00000B5C	 00000016	MOV R0 lower 16-bits base(0), next at  00000B30
 00000B60	 000000D8	MOVT R0 higher 16-bits var + 216
 00000B64	     6800	LDR R0 [ R0 + 0 ]
 00000B66	 10000005	MOV R1 lower 16-bits base(0), next at  00000B5C
 00000B6A	 000000DC	MOVT R1 higher 16-bits var + 220
 00000B6E	     6809	LDR R1 [ R1 + 0 ]
 00000B70	 809000EC	BL Mod(  8) proc(9)
 00000B74	 F85DEB04	LDR LR [ SP ] + 4
 00000B78	     4770	BX LR
 00000B7A	     B083	SUB SP SP #12
 00000B7C	     B401	PUSH R0
 00000B7E	     B500	PUSH LR
 00000B80	     2000	MOVS R0 #0
 00000B82	     9002	STR R0 [ SP + 8 ]
 00000B84	 0000000F	MOV R0 lower 16-bits base(0), next at  00000B66
 00000B88	 000000E0	MOVT R0 higher 16-bits var + 224
 00000B8C	     6800	LDR R0 [ R0 + 0 ]
 00000B8E	     2800	CMP R0 #0
 00000B90	     BF08	IT EQ
 00000B92	 EC03C294	TrapEQ 4 at pos 7721
 00000B96	     6980	LDR R0 [ R0 + 24 ]
 00000B98	     B401	PUSH R0
 00000B9A	 0000000B	MOV R0 lower 16-bits base(0), next at  00000B84
 00000B9E	 000000E0	MOVT R0 higher 16-bits var + 224
 00000BA2	     6800	LDR R0 [ R0 + 0 ]
 00000BA4	     A903	ADD R1 SP #12
 00000BA6	 20000006	MOV R2 lower 16-bits base(0), next at  00000B9A
 00000BAA	 00000058	MOVT R2 higher 16-bits var + 88
 00000BAE	     BC08	POP R3
 00000BB0	     4798	BLX R3
 00000BB2	     9801	LDR R0 [ SP + 4 ]
 00000BB4	 10000007	MOV R1 lower 16-bits base(0), next at  00000BA6
 00000BB8	 000000E0	MOVT R1 higher 16-bits var + 224
 00000BBC	     6008	STR R0 [  R1 + 0 ]
 00000BBE	 F85DEB04	LDR LR [ SP ] + 4
 00000BC2	     B004	ADD SP SP #16
 00000BC4	     4770	BX LR
 00000BC6	     B401	PUSH R0
 00000BC8	     B500	PUSH LR
 00000BCA	     9801	LDR R0 [ SP + 4 ]
 00000BCC	 1000000C	MOV R1 lower 16-bits base(0), next at  00000BB4
 00000BD0	 000000E4	MOVT R1 higher 16-bits var + 228
 00000BD4	     6008	STR R0 [  R1 + 0 ]
 00000BD6	 F85DEB04	LDR LR [ SP ] + 4
 00000BDA	     B001	ADD SP SP #4
 00000BDC	     4770	BX LR
 00000BDE	     B407	PUSH R0 R1 R2
 00000BE0	     B500	PUSH LR
 00000BE2	     9801	LDR R0 [ SP + 4 ]
 00000BE4	     2800	CMP R0 #0
 00000BE6	     BF08	IT EQ
 00000BE8	 EC03E284	TrapEQ 4 at pos 7976
 00000BEC	     6880	LDR R0 [ R0 + 8 ]
 00000BEE	     9901	LDR R1 [ SP + 4 ]
 00000BF0	     2900	CMP R1 #0
 00000BF2	     BF08	IT EQ
 00000BF4	 EC03E2D4	TrapEQ 4 at pos 7981
 00000BF8	     68C9	LDR R1 [ R1 + 12 ]
 00000BFA	 80900045	BL Mod(  8) proc(9)
 00000BFE	 10000019	MOV R1 lower 16-bits base(0), next at  00000BCC
 00000C02	 000000E8	MOVT R1 higher 16-bits var + 232
 00000C06	     6008	STR R0 [  R1 + 0 ]
 00000C08	     9801	LDR R0 [ SP + 4 ]
 00000C0A	 10000006	MOV R1 lower 16-bits base(0), next at  00000BFE
 00000C0E	 000000EC	MOVT R1 higher 16-bits var + 236
 00000C12	     6008	STR R0 [  R1 + 0 ]
 00000C14	     9802	LDR R0 [ SP + 8 ]
 00000C16	 10000006	MOV R1 lower 16-bits base(0), next at  00000C0A
 00000C1A	 000000F0	MOVT R1 higher 16-bits var + 240
 00000C1E	     6008	STR R0 [  R1 + 0 ]
 00000C20	     9803	LDR R0 [ SP + 12 ]
 00000C22	 10000006	MOV R1 lower 16-bits base(0), next at  00000C16
 00000C26	 000000F4	MOVT R1 higher 16-bits var + 244
 00000C2A	     6008	STR R0 [  R1 + 0 ]
 00000C2C	 F85DEB04	LDR LR [ SP ] + 4
 00000C30	     B003	ADD SP SP #12
 00000C32	     4770	BX LR
 00000C34	     B095	SUB SP SP #84
 00000C36	     B407	PUSH R0 R1 R2
 00000C38	     B500	PUSH LR
 00000C3A	     2000	MOVS R0 #0
 00000C3C	     9006	STR R0 [ SP + 24 ]
 00000C3E	     2000	MOVS R0 #0
 00000C40	     9902	LDR R1 [ SP + 8 ]
 00000C42	     4288	CMP R0 R1
 00000C44	     BF28	IT CS
 00000C46	 EC0403C1	TrapCS 1 at pos 8252
 00000C4A	     9901	LDR R1 [ SP + 4 ]
 00000C4C	     1808	ADDS R0 R1 R0
 00000C4E	     7800	LDRB R0 [ R0 + 0 ]
 00000C50	 F88D0020	STRB R0 [  SP + 32 ]
 00000C54	 F89D0020	LDRB R0 [ SP + 32 ]
 00000C58	     282E	CMP R0 #46
 00000C5A	 F000801E	BEQ #60, goes to  00000C9A
 00000C5E	 F89D0020	LDRB R0 [ SP + 32 ]
 00000C62	     2800	CMP R0 #0
 00000C64	 F0008019	BEQ #50, goes to  00000C9A
 00000C68	     9806	LDR R0 [ SP + 24 ]
 00000C6A	     2820	CMP R0 #32
 00000C6C	     BF28	IT CS
 00000C6E	 EC0406A1	TrapCS 1 at pos 8298
 00000C72	     4468	ADD R0 SP R0
 00000C74	 F89D1020	LDRB R1 [ SP + 32 ]
 00000C78	 F8801024	STRB R1 [  R0 + 36 ]
 00000C7C	     9806	LDR R0 [ SP + 24 ]
 00000C7E	     1C40	ADDS R0 R0 #1
 00000C80	     9006	STR R0 [ SP + 24 ]
 00000C82	     9806	LDR R0 [ SP + 24 ]
 00000C84	     9902	LDR R1 [ SP + 8 ]
 00000C86	     4288	CMP R0 R1
 00000C88	     BF28	IT CS
 00000C8A	 EC041071	TrapCS 1 at pos 8327
 00000C8E	     9901	LDR R1 [ SP + 4 ]
 00000C90	     1808	ADDS R0 R1 R0
 00000C92	     7800	LDRB R0 [ R0 + 0 ]
 00000C94	 F88D0020	STRB R0 [  SP + 32 ]
 00000C98	     E7DC	B #-72, goes to  00000C54
 00000C9A	 F89D0020	LDRB R0 [ SP + 32 ]
 00000C9E	     282E	CMP R0 #46
 00000CA0	 F0408073	BNE #230, goes to  00000D8A
 00000CA4	     9806	LDR R0 [ SP + 24 ]
 00000CA6	     2820	CMP R0 #32
 00000CA8	     BF28	IT CS
 00000CAA	 EC041311	TrapCS 1 at pos 8369
 00000CAE	     4468	ADD R0 SP R0
 00000CB0	     2100	MOVS R1 #0
 00000CB2	 F8801024	STRB R1 [  R0 + 36 ]
 00000CB6	     9806	LDR R0 [ SP + 24 ]
 00000CB8	     1C40	ADDS R0 R0 #1
 00000CBA	     9006	STR R0 [ SP + 24 ]
 00000CBC	     A809	ADD R0 SP #36
 00000CBE	     2120	MOVS R1 #32
 00000CC0	     AA04	ADD R2 SP #16
 00000CC2	 50800064	BL Mod(  5) proc(8)
 00000CC6	 05000052	MOV R0 lower 16-bits base(5), next at  00000C22
 00000CCA	 00000004	MOVT R0 higher 16-bits var(4)
 00000CCE	     6800	LDR R0 [ R0 + 0 ]
 00000CD0	     9903	LDR R1 [ SP + 12 ]
 00000CD2	     6008	STR R0 [  R1 + 0 ]
 00000CD4	 05000007	MOV R0 lower 16-bits base(5), next at  00000CC6
 00000CD8	 00000004	MOVT R0 higher 16-bits var(4)
 00000CDC	     6800	LDR R0 [ R0 + 0 ]
 00000CDE	     2800	CMP R0 #0
 00000CE0	 F0408051	BNE #162, goes to  00000D86
 00000CE4	     2000	MOVS R0 #0
 00000CE6	     9007	STR R0 [ SP + 28 ]
 00000CE8	     9806	LDR R0 [ SP + 24 ]
 00000CEA	     9902	LDR R1 [ SP + 8 ]
 00000CEC	     4288	CMP R0 R1
 00000CEE	     BF28	IT CS
 00000CF0	 EC042301	TrapCS 1 at pos 8496
 00000CF4	     9901	LDR R1 [ SP + 4 ]
 00000CF6	     1808	ADDS R0 R1 R0
 00000CF8	     7800	LDRB R0 [ R0 + 0 ]
 00000CFA	 F88D0020	STRB R0 [  SP + 32 ]
 00000CFE	     9806	LDR R0 [ SP + 24 ]
 00000D00	     1C40	ADDS R0 R0 #1
 00000D02	     9006	STR R0 [ SP + 24 ]
 00000D04	 F89D0020	LDRB R0 [ SP + 32 ]
 00000D08	     2800	CMP R0 #0
 00000D0A	 F000801C	BEQ #56, goes to  00000D46
 00000D0E	     9807	LDR R0 [ SP + 28 ]
 00000D10	     2820	CMP R0 #32
 00000D12	     BF28	IT CS
 00000D14	 EC0425B1	TrapCS 1 at pos 8539
 00000D18	     4468	ADD R0 SP R0
 00000D1A	 F89D1020	LDRB R1 [ SP + 32 ]
 00000D1E	 F8801044	STRB R1 [  R0 + 68 ]
 00000D22	     9807	LDR R0 [ SP + 28 ]
 00000D24	     1C40	ADDS R0 R0 #1
 00000D26	     9007	STR R0 [ SP + 28 ]
 00000D28	     9806	LDR R0 [ SP + 24 ]
 00000D2A	     9902	LDR R1 [ SP + 8 ]
 00000D2C	     4288	CMP R0 R1
 00000D2E	     BF28	IT CS
 00000D30	 EC042781	TrapCS 1 at pos 8568
 00000D34	     9901	LDR R1 [ SP + 4 ]
 00000D36	     1808	ADDS R0 R1 R0
 00000D38	     7800	LDRB R0 [ R0 + 0 ]
 00000D3A	 F88D0020	STRB R0 [  SP + 32 ]
 00000D3E	     9806	LDR R0 [ SP + 24 ]
 00000D40	     1C40	ADDS R0 R0 #1
 00000D42	     9006	STR R0 [ SP + 24 ]
 00000D44	     E7DE	B #-68, goes to  00000D04
 00000D46	     9807	LDR R0 [ SP + 28 ]
 00000D48	     2820	CMP R0 #32
 00000D4A	     BF28	IT CS
 00000D4C	 EC043171	TrapCS 1 at pos 8599
 00000D50	     4468	ADD R0 SP R0
 00000D52	     2100	MOVS R1 #0
 00000D54	 F8801044	STRB R1 [  R0 + 68 ]
 00000D58	     9804	LDR R0 [ SP + 16 ]
 00000D5A	     A911	ADD R1 SP #68
 00000D5C	     2220	MOVS R2 #32
 00000D5E	 5090004E	BL Mod(  5) proc(9)
 00000D62	     9005	STR R0 [ SP + 20 ]
 00000D64	 05000048	MOV R0 lower 16-bits base(5), next at  00000CD4
 00000D68	 00000004	MOVT R0 higher 16-bits var(4)
 00000D6C	     6800	LDR R0 [ R0 + 0 ]
 00000D6E	     9903	LDR R1 [ SP + 12 ]
 00000D70	     6008	STR R0 [  R1 + 0 ]
 00000D72	 05000007	MOV R0 lower 16-bits base(5), next at  00000D64
 00000D76	 00000004	MOVT R0 higher 16-bits var(4)
 00000D7A	     6800	LDR R0 [ R0 + 0 ]
 00000D7C	     2800	CMP R0 #0
 00000D7E	 F0408002	BNE #4, goes to  00000D86
 00000D82	     9805	LDR R0 [ SP + 20 ]
 00000D84	     4780	BLX R0
 00000D86	 F000B803	B #6, goes to  00000D90
 00000D8A	     2005	MOVS R0 #5
 00000D8C	     9903	LDR R1 [ SP + 12 ]
 00000D8E	     6008	STR R0 [  R1 + 0 ]
 00000D90	 F85DEB04	LDR LR [ SP ] + 4
 00000D94	     B018	ADD SP SP #96
 00000D96	     4770	BX LR
 00000D98	     B084	SUB SP SP #16
 00000D9A	     B40F	PUSH R0 R1 R2 R3
 00000D9C	     B500	PUSH LR
 00000D9E	 F05F30FF	MOVS R0 #-1
 00000DA2	     9005	STR R0 [ SP + 20 ]
 00000DA4	     A805	ADD R0 SP #20
 00000DA6	 1000001A	MOV R1 lower 16-bits base(0), next at  00000D72
 00000DAA	 00000040	MOVT R1 higher 16-bits var + 64
 00000DAE	 80F00028	BL Mod(  8) proc(15)
 00000DB2	     9805	LDR R0 [ SP + 20 ]
 00000DB4	     9904	LDR R1 [ SP + 16 ]
 00000DB6	     6008	STR R0 [  R1 + 0 ]
 00000DB8	     9804	LDR R0 [ SP + 16 ]
 00000DBA	     6800	LDR R0 [ R0 + 0 ]
 00000DBC	     2800	CMP R0 #0
 00000DBE	 F2C08009	BLT #18, goes to  00000DD4
 00000DC2	     9806	LDR R0 [ SP + 24 ]
 00000DC4	     9901	LDR R1 [ SP + 4 ]
 00000DC6	     6008	STR R0 [  R1 + 0 ]
 00000DC8	     9807	LDR R0 [ SP + 28 ]
 00000DCA	     9902	LDR R1 [ SP + 8 ]
 00000DCC	     6008	STR R0 [  R1 + 0 ]
 00000DCE	     9808	LDR R0 [ SP + 32 ]
 00000DD0	     9903	LDR R1 [ SP + 12 ]
 00000DD2	     6008	STR R0 [  R1 + 0 ]
 00000DD4	 F85DEB04	LDR LR [ SP ] + 4
 00000DD8	     B008	ADD SP SP #32
 00000DDA	     4770	BX LR
 00000DDC	     B081	SUB SP SP #4
 00000DDE	     B500	PUSH LR
 00000DE0	 0000001D	MOV R0 lower 16-bits base(0), next at  00000DA6
 00000DE4	 00000118	MOVT R0 higher 16-bits var + 280
 00000DE8	     6800	LDR R0 [ R0 + 0 ]
 00000DEA	     2800	CMP R0 #0
 00000DEC	 F3408015	BLE #42, goes to  00000E1A
 00000DF0	 03000008	MOV R0 lower 16-bits base(3), next at  00000DE0
 00000DF4	 00000005	MOVT R0 higher 16-bits var(5)
 00000DF8	     6800	LDR R0 [ R0 + 0 ]
 00000DFA	 13000005	MOV R1 lower 16-bits base(3), next at  00000DF0
 00000DFE	 00000004	MOVT R1 higher 16-bits var(4)
 00000E02	     6809	LDR R1 [ R1 + 0 ]
 00000E04	     1A40	SUBS R0 R0 R1
 00000E06	 F5B03080	SUBS R0 R0 #65536
 00000E0A	 13000008	MOV R1 lower 16-bits base(3), next at  00000DFA
 00000E0E	 00000002	MOVT R1 higher 16-bits var(2)
 00000E12	     6809	LDR R1 [ R1 + 0 ]
 00000E14	     4281	CMP R1 R0
 00000E16	 F2C08039	BLT #114, goes to  00000E8C
 00000E1A	 31C00036	BL Mod(  3) proc(28)
 00000E1E	 0500000A	MOV R0 lower 16-bits base(5), next at  00000E0A
 00000E22	 00000002	MOVT R0 higher 16-bits var(2)
 00000E26	     6800	LDR R0 [ R0 + 0 ]
 00000E28	     9001	STR R0 [ SP + 4 ]
 00000E2A	     2021	MOVS R0 #33
 00000E2C	     DF01	SVC #1
 00000E2E	     9801	LDR R0 [ SP + 4 ]
 00000E30	     2800	CMP R0 #0
 00000E32	 F0008019	BEQ #50, goes to  00000E68
 00000E36	     9801	LDR R0 [ SP + 4 ]
 00000E38	     2800	CMP R0 #0
 00000E3A	     BF08	IT EQ
 00000E3C	 EC048404	TrapEQ 4 at pos 9280
 00000E40	     7800	LDRB R0 [ R0 + 0 ]
 00000E42	     2800	CMP R0 #0
 00000E44	 F0008008	BEQ #16, goes to  00000E58
 00000E48	     9801	LDR R0 [ SP + 4 ]
 00000E4A	     2800	CMP R0 #0
 00000E4C	     BF08	IT EQ
 00000E4E	 EC048614	TrapEQ 4 at pos 9313
 00000E52	     6C80	LDR R0 [ R0 + 72 ]
 00000E54	 30F0001D	BL Mod(  3) proc(15)
 00000E58	     9801	LDR R0 [ SP + 4 ]
 00000E5A	     2800	CMP R0 #0
 00000E5C	     BF08	IT EQ
 00000E5E	 EC049004	TrapEQ 4 at pos 9344
 00000E62	     6A00	LDR R0 [ R0 + 32 ]
 00000E64	     9001	STR R0 [ SP + 4 ]
 00000E66	     E7E2	B #-60, goes to  00000E2E
 00000E68	     2023	MOVS R0 #35
 00000E6A	     DF01	SVC #1
 00000E6C	 41E0000C	BL Mod(  4) proc(30)
 00000E70	     2027	MOVS R0 #39
 00000E72	     DF01	SVC #1
 00000E74	 31000004	BL Mod(  3) proc(16)
 00000E78	     2020	MOVS R0 #32
 00000E7A	     DF01	SVC #1
 00000E7C	     2014	MOVS R0 #20
 00000E7E	 10000030	MOV R1 lower 16-bits base(0), next at  00000E1E
 00000E82	 00000118	MOVT R1 higher 16-bits var + 280
 00000E86	     6008	STR R0 [  R1 + 0 ]
 00000E88	 31D0000A	BL Mod(  3) proc(29)
 00000E8C	 F85DEB04	LDR LR [ SP ] + 4
 00000E90	     B001	ADD SP SP #4
 00000E92	     4770	BX LR
 00000E94	     B082	SUB SP SP #8
 00000E96	     B401	PUSH R0
 00000E98	     B500	PUSH LR
 00000E9A	     9801	LDR R0 [ SP + 4 ]
 00000E9C	     2800	CMP R0 #0
 00000E9E	     BF08	IT EQ
 00000EA0	 EC04B304	TrapEQ 4 at pos 9648
 00000EA4	     6900	LDR R0 [ R0 + 16 ]
 00000EA6	     9002	STR R0 [ SP + 8 ]
 00000EA8	 05000015	MOV R0 lower 16-bits base(5), next at  00000E7E
 00000EAC	 00000002	MOVT R0 higher 16-bits var(2)
 00000EB0	     6800	LDR R0 [ R0 + 0 ]
 00000EB2	     9003	STR R0 [ SP + 12 ]
 00000EB4	     9803	LDR R0 [ SP + 12 ]
 00000EB6	     2800	CMP R0 #0
 00000EB8	 F0008025	BEQ #74, goes to  00000F06
 00000EBC	     9803	LDR R0 [ SP + 12 ]
 00000EBE	     2800	CMP R0 #0
 00000EC0	     BF08	IT EQ
 00000EC2	 EC04B6A4	TrapEQ 4 at pos 9706
 00000EC6	     7800	LDRB R0 [ R0 + 0 ]
 00000EC8	     2800	CMP R0 #0
 00000ECA	 F0008014	BEQ #40, goes to  00000EF6
 00000ECE	     9803	LDR R0 [ SP + 12 ]
 00000ED0	     2800	CMP R0 #0
 00000ED2	     BF08	IT EQ
 00000ED4	 EC04C064	TrapEQ 4 at pos 9734
 00000ED8	     9902	LDR R1 [ SP + 8 ]
 00000EDA	     6B80	LDR R0 [ R0 + 56 ]
 00000EDC	     4281	CMP R1 R0
 00000EDE	 F2C0800A	BLT #20, goes to  00000EF6
 00000EE2	     9803	LDR R0 [ SP + 12 ]
 00000EE4	     2800	CMP R0 #0
 00000EE6	     BF08	IT EQ
 00000EE8	 EC04C1A4	TrapEQ 4 at pos 9754
 00000EEC	     9902	LDR R1 [ SP + 8 ]
 00000EEE	     6BC0	LDR R0 [ R0 + 60 ]
 00000EF0	     4281	CMP R1 R0
 00000EF2	 F2C08008	BLT #16, goes to  00000F06
 00000EF6	     9803	LDR R0 [ SP + 12 ]
 00000EF8	     2800	CMP R0 #0
 00000EFA	     BF08	IT EQ
 00000EFC	 EC04C2F4	TrapEQ 4 at pos 9775
 00000F00	     6A00	LDR R0 [ R0 + 32 ]
 00000F02	     9003	STR R0 [ SP + 12 ]
 00000F04	     E7D6	B #-84, goes to  00000EB4
 00000F06	     9803	LDR R0 [ SP + 12 ]
 00000F08	 F85DEB04	LDR LR [ SP ] + 4
 00000F0C	     B003	ADD SP SP #12
 00000F0E	     4770	BX LR
 00000F10	     B081	SUB SP SP #4
 00000F12	     B403	PUSH R0 R1
 00000F14	     B500	PUSH LR
 00000F16	     A803	ADD R0 SP #12
 00000F18	 10000038	MOV R1 lower 16-bits base(0), next at  00000EA8
 00000F1C	 00000084	MOVT R1 higher 16-bits var + 132
 00000F20	     DF00	SVC #0
 00000F22	     9803	LDR R0 [ SP + 12 ]
 00000F24	     2800	CMP R0 #0
 00000F26	     BF08	IT EQ
 00000F28	 EC04D354	TrapEQ 4 at pos 9909
 00000F2C	     2100	MOVS R1 #0
 00000F2E	     6001	STR R1 [  R0 + 0 ]
 00000F30	     9803	LDR R0 [ SP + 12 ]
 00000F32	     2800	CMP R0 #0
 00000F34	     BF08	IT EQ
 00000F36	 EC04D444	TrapEQ 4 at pos 9924
 00000F3A	     9903	LDR R1 [ SP + 12 ]
 00000F3C	     60C1	STR R1 [  R0 + 12 ]
 00000F3E	     9803	LDR R0 [ SP + 12 ]
 00000F40	     2800	CMP R0 #0
 00000F42	     BF08	IT EQ
 00000F44	 EC04D534	TrapEQ 4 at pos 9939
 00000F48	     9901	LDR R1 [ SP + 4 ]
 00000F4A	     6101	STR R1 [  R0 + 16 ]
 00000F4C	     9803	LDR R0 [ SP + 12 ]
 00000F4E	     2800	CMP R0 #0
 00000F50	     BF08	IT EQ
 00000F52	 EC04D624	TrapEQ 4 at pos 9954
 00000F56	     9902	LDR R1 [ SP + 8 ]
 00000F58	     6081	STR R1 [  R0 + 8 ]
 00000F5A	     9803	LDR R0 [ SP + 12 ]
 00000F5C	 F85DEB04	LDR LR [ SP ] + 4
 00000F60	     B003	ADD SP SP #12
 00000F62	     4770	BX LR
 00000F64	     B081	SUB SP SP #4
 00000F66	     B401	PUSH R0
 00000F68	     B500	PUSH LR
 00000F6A	     9801	LDR R0 [ SP + 4 ]
 00000F6C	 F7FFFF92	BL #-220, goes to  00000E94
 00000F70	     9002	STR R0 [ SP + 8 ]
 00000F72	     9802	LDR R0 [ SP + 8 ]
 00000F74	     2800	CMP R0 #0
 00000F76	 F000803D	BEQ #122, goes to  00000FF4
 00000F7A	     9801	LDR R0 [ SP + 4 ]
 00000F7C	     2800	CMP R0 #0
 00000F7E	     BF08	IT EQ
 00000F80	 EC04E7E4	TrapEQ 4 at pos 10110
 00000F84	     6800	LDR R0 [ R0 + 0 ]
 00000F86	     2800	CMP R0 #0
 00000F88	 F0408034	BNE #104, goes to  00000FF4
 00000F8C	     A802	ADD R0 SP #8
 00000F8E	     2101	MOVS R1 #1
 00000F90	 50700084	BL Mod(  5) proc(7)
 00000F94	     9801	LDR R0 [ SP + 4 ]
 00000F96	     2800	CMP R0 #0
 00000F98	     BF08	IT EQ
 00000F9A	 EC04F324	TrapEQ 4 at pos 10162
 00000F9E	 10000043	MOV R1 lower 16-bits base(0), next at  00000F18
 00000FA2	 00000108	MOVT R1 higher 16-bits var + 264
 00000FA6	     6809	LDR R1 [ R1 + 0 ]
 00000FA8	     2900	CMP R1 #0
 00000FAA	     BF08	IT EQ
 00000FAC	 EC04F424	TrapEQ 4 at pos 10178
 00000FB0	     68C9	LDR R1 [ R1 + 12 ]
 00000FB2	     60C1	STR R1 [  R0 + 12 ]
 00000FB4	 0000000B	MOV R0 lower 16-bits base(0), next at  00000F9E
 00000FB8	 00000108	MOVT R0 higher 16-bits var + 264
 00000FBC	     6800	LDR R0 [ R0 + 0 ]
 00000FBE	     2800	CMP R0 #0
 00000FC0	     BF08	IT EQ
 00000FC2	 EC04F504	TrapEQ 4 at pos 10192
 00000FC6	     9901	LDR R1 [ SP + 4 ]
 00000FC8	     60C1	STR R1 [  R0 + 12 ]
 00000FCA	     9801	LDR R0 [ SP + 4 ]
 00000FCC	     2800	CMP R0 #0
 00000FCE	     BF08	IT EQ
 00000FD0	 EC04F5E4	TrapEQ 4 at pos 10206
 00000FD4	     2101	MOVS R1 #1
 00000FD6	     6001	STR R1 [  R0 + 0 ]
 00000FD8	     9801	LDR R0 [ SP + 4 ]
 00000FDA	     2800	CMP R0 #0
 00000FDC	     BF08	IT EQ
 00000FDE	 EC04F724	TrapEQ 4 at pos 10226
 00000FE2	     2100	MOVS R1 #0
 00000FE4	     6041	STR R1 [  R0 + 4 ]
 00000FE6	 00000019	MOV R0 lower 16-bits base(0), next at  00000FB4
 00000FEA	 00000104	MOVT R0 higher 16-bits var + 260
 00000FEE	     6801	LDR R1 [ R0 + 0 ]
 00000FF0	     1C49	ADDS R1 R1 #1
 00000FF2	     6001	STR R1 [  R0 + 0 ]
 00000FF4	 F85DEB04	LDR LR [ SP ] + 4
 00000FF8	     B002	ADD SP SP #8
 00000FFA	     4770	BX LR
 00000FFC	     B082	SUB SP SP #8
 00000FFE	     B401	PUSH R0
 00001000	     B500	PUSH LR
 00001002	     9801	LDR R0 [ SP + 4 ]
 00001004	     2800	CMP R0 #0
 00001006	     BF08	IT EQ
 00001008	 EC0507C4	TrapEQ 4 at pos 10364
 0000100C	     6800	LDR R0 [ R0 + 0 ]
 0000100E	     2800	CMP R0 #0
 00001010	 F0008048	BEQ #144, goes to  000010A4
 00001014	     9801	LDR R0 [ SP + 4 ]
 00001016	     9002	STR R0 [ SP + 8 ]
 00001018	     9801	LDR R0 [ SP + 4 ]
 0000101A	 F7FFFF3B	BL #-394, goes to  00000E94
 0000101E	     9003	STR R0 [ SP + 12 ]
 00001020	     9803	LDR R0 [ SP + 12 ]
 00001022	     2800	CMP R0 #0
 00001024	 F0008005	BEQ #10, goes to  00001032
 00001028	     A803	ADD R0 SP #12
 0000102A	 F05F31FF	MOVS R1 #-1
 0000102E	 5070004F	BL Mod(  5) proc(7)
 00001032	     9802	LDR R0 [ SP + 8 ]
 00001034	     2800	CMP R0 #0
 00001036	     BF08	IT EQ
 00001038	 EC051664	TrapEQ 4 at pos 10470
 0000103C	     68C0	LDR R0 [ R0 + 12 ]
 0000103E	     9901	LDR R1 [ SP + 4 ]
 00001040	     4288	CMP R0 R1
 00001042	 F0008008	BEQ #16, goes to  00001056
 00001046	     9802	LDR R0 [ SP + 8 ]
 00001048	     2800	CMP R0 #0
 0000104A	     BF08	IT EQ
 0000104C	 EC051794	TrapEQ 4 at pos 10489
 00001050	     68C0	LDR R0 [ R0 + 12 ]
 00001052	     9002	STR R0 [ SP + 8 ]
 00001054	     E7ED	B #-38, goes to  00001032
 00001056	     9802	LDR R0 [ SP + 8 ]
 00001058	     2800	CMP R0 #0
 0000105A	     BF08	IT EQ
 0000105C	 EC0520C4	TrapEQ 4 at pos 10508
 00001060	     9901	LDR R1 [ SP + 4 ]
 00001062	     2900	CMP R1 #0
 00001064	     BF08	IT EQ
 00001066	 EC052164	TrapEQ 4 at pos 10518
 0000106A	     68C9	LDR R1 [ R1 + 12 ]
 0000106C	     60C1	STR R1 [  R0 + 12 ]
 0000106E	     9801	LDR R0 [ SP + 4 ]
 00001070	     2800	CMP R0 #0
 00001072	     BF08	IT EQ
 00001074	 EC0521F4	TrapEQ 4 at pos 10527
 00001078	     2100	MOVS R1 #0
 0000107A	     6001	STR R1 [  R0 + 0 ]
 0000107C	     9801	LDR R0 [ SP + 4 ]
 0000107E	     2800	CMP R0 #0
 00001080	     BF08	IT EQ
 00001082	 EC0522E4	TrapEQ 4 at pos 10542
 00001086	     2100	MOVS R1 #0
 00001088	     60C1	STR R1 [  R0 + 12 ]
 0000108A	     9802	LDR R0 [ SP + 8 ]
 0000108C	 10000053	MOV R1 lower 16-bits base(0), next at  00000FE6
 00001090	 00000108	MOVT R1 higher 16-bits var + 264
 00001094	     6008	STR R0 [  R1 + 0 ]
 00001096	 00000005	MOV R0 lower 16-bits base(0), next at  0000108C
 0000109A	 00000104	MOVT R0 higher 16-bits var + 260
 0000109E	     6801	LDR R1 [ R0 + 0 ]
 000010A0	     1E49	SUBS R1 R1 #1
 000010A2	     6001	STR R1 [  R0 + 0 ]
 000010A4	 F85DEB04	LDR LR [ SP ] + 4
 000010A8	     B003	ADD SP SP #12
 000010AA	     4770	BX LR
 000010AC	     B401	PUSH R0
 000010AE	     B500	PUSH LR
 000010B0	     9801	LDR R0 [ SP + 4 ]
 000010B2	 1000000E	MOV R1 lower 16-bits base(0), next at  00001096
 000010B6	 00000118	MOVT R1 higher 16-bits var + 280
 000010BA	     6008	STR R0 [  R1 + 0 ]
 000010BC	 F85DEB04	LDR LR [ SP ] + 4
 000010C0	     B001	ADD SP SP #4
 000010C2	     4770	BX LR
 000010C4	     B401	PUSH R0
 000010C6	     B500	PUSH LR
 000010C8	     9801	LDR R0 [ SP + 4 ]
 000010CA	 1000000C	MOV R1 lower 16-bits base(0), next at  000010B2
 000010CE	 000000F8	MOVT R1 higher 16-bits var + 248
 000010D2	     6008	STR R0 [  R1 + 0 ]
 000010D4	 F85DEB04	LDR LR [ SP ] + 4
 000010D8	     B001	ADD SP SP #4
 000010DA	     4770	BX LR
 000010DC	     B401	PUSH R0
 000010DE	     B500	PUSH LR
 000010E0	     9801	LDR R0 [ SP + 4 ]
 000010E2	 1000000C	MOV R1 lower 16-bits base(0), next at  000010CA
 000010E6	 000000FC	MOVT R1 higher 16-bits var + 252
 000010EA	     6008	STR R0 [  R1 + 0 ]
 000010EC	 F85DEB04	LDR LR [ SP ] + 4
 000010F0	     B001	ADD SP SP #4
 000010F2	     4770	BX LR
 000010F4	     B401	PUSH R0
 000010F6	     B500	PUSH LR
 000010F8	     9801	LDR R0 [ SP + 4 ]
 000010FA	 1000000C	MOV R1 lower 16-bits base(0), next at  000010E2
 000010FE	 00000100	MOVT R1 higher 16-bits var + 256
 00001102	     6008	STR R0 [  R1 + 0 ]
 00001104	 F85DEB04	LDR LR [ SP ] + 4
 00001108	     B001	ADD SP SP #4
 0000110A	     4770	BX LR
 0000110C	     B093	SUB SP SP #76
 0000110E	     B500	PUSH LR
 00001110	     A812	ADD R0 SP #72
 00001112	     A90F	ADD R1 SP #60
 00001114	     AA10	ADD R2 SP #64
 00001116	 60300074	BL Mod(  6) proc(3)
 0000111A	 60100002	BL Mod(  6) proc(1)
 0000111E	     2800	CMP R0 #0
 00001120	 F3408078	BLE #240, goes to  00001214
 00001124	     A813	ADD R0 SP #76
 00001126	 60200006	BL Mod(  6) proc(2)
 0000112A	 F89D004C	LDRB R0 [ SP + 76 ]
 0000112E	     281B	CMP R0 #27
 00001130	 F0408017	BNE #46, goes to  00001162
 00001134	     2001	MOVS R0 #1
 00001136	     900A	STR R0 [ SP + 40 ]
 00001138	     A80A	ADD R0 SP #40
 0000113A	 10000020	MOV R1 lower 16-bits base(0), next at  000010FA
 0000113E	 00000058	MOVT R1 higher 16-bits var + 88
 00001142	 80F0000E	BL Mod(  8) proc(15)
 00001146	 00000006	MOV R0 lower 16-bits base(0), next at  0000113A
 0000114A	 000000CC	MOVT R0 higher 16-bits var + 204
 0000114E	 10000004	MOV R1 lower 16-bits base(0), next at  00001146
 00001152	 00000014	MOVT R1 higher 16-bits var + 20
 00001156	 F7FFF8BF	BL #-3714, goes to  000002D8
 0000115A	     2000	MOVS R0 #0
 0000115C	     DF01	SVC #1
 0000115E	 F000B857	B #174, goes to  00001210
 00001162	 F89D004C	LDRB R0 [ SP + 76 ]
 00001166	     281A	CMP R0 #26
 00001168	 F040801C	BNE #56, goes to  000011A4
 0000116C	     2002	MOVS R0 #2
 0000116E	     900A	STR R0 [ SP + 40 ]
 00001170	     980F	LDR R0 [ SP + 60 ]
 00001172	     900B	STR R0 [ SP + 44 ]
 00001174	     9810	LDR R0 [ SP + 64 ]
 00001176	     900C	STR R0 [ SP + 48 ]
 00001178	     980F	LDR R0 [ SP + 60 ]
 0000117A	     9910	LDR R1 [ SP + 64 ]
 0000117C	 8090001D	BL Mod(  8) proc(9)
 00001180	     9001	STR R0 [ SP + 4 ]
 00001182	     9801	LDR R0 [ SP + 4 ]
 00001184	     2800	CMP R0 #0
 00001186	     BF08	IT EQ
 00001188	 EC058694	TrapEQ 4 at pos 11369
 0000118C	     6980	LDR R0 [ R0 + 24 ]
 0000118E	     B401	PUSH R0
 00001190	     9802	LDR R0 [ SP + 8 ]
 00001192	     A90B	ADD R1 SP #44
 00001194	 20000023	MOV R2 lower 16-bits base(0), next at  0000114E
 00001198	 00000058	MOVT R2 higher 16-bits var + 88
 0000119C	     BC08	POP R3
 0000119E	     4798	BLX R3
 000011A0	 F000B836	B #108, goes to  00001210
 000011A4	     2000	MOVS R0 #0
 000011A6	     9002	STR R0 [ SP + 8 ]
 000011A8	 F89D004C	LDRB R0 [ SP + 76 ]
 000011AC	 F88D0018	STRB R0 [  SP + 24 ]
 000011B0	 0000000E	MOV R0 lower 16-bits base(0), next at  00001194
 000011B4	 000000F8	MOVT R0 higher 16-bits var + 248
 000011B8	     6800	LDR R0 [ R0 + 0 ]
 000011BA	     9007	STR R0 [ SP + 28 ]
 000011BC	 00000006	MOV R0 lower 16-bits base(0), next at  000011B0
 000011C0	 000000FC	MOVT R0 higher 16-bits var + 252
 000011C4	     6800	LDR R0 [ R0 + 0 ]
 000011C6	     9008	STR R0 [ SP + 32 ]
 000011C8	 00000006	MOV R0 lower 16-bits base(0), next at  000011BC
 000011CC	 00000100	MOVT R0 higher 16-bits var + 256
 000011D0	     6800	LDR R0 [ R0 + 0 ]
 000011D2	     9009	STR R0 [ SP + 36 ]
 000011D4	 00000006	MOV R0 lower 16-bits base(0), next at  000011C8
 000011D8	 000000E0	MOVT R0 higher 16-bits var + 224
 000011DC	     6800	LDR R0 [ R0 + 0 ]
 000011DE	     2800	CMP R0 #0
 000011E0	     BF08	IT EQ
 000011E2	 EC0596A4	TrapEQ 4 at pos 11498
 000011E6	     6980	LDR R0 [ R0 + 24 ]
 000011E8	     B401	PUSH R0
 000011EA	 0000000B	MOV R0 lower 16-bits base(0), next at  000011D4
 000011EE	 000000E0	MOVT R0 higher 16-bits var + 224
 000011F2	     6800	LDR R0 [ R0 + 0 ]
 000011F4	     A903	ADD R1 SP #12
 000011F6	 20000006	MOV R2 lower 16-bits base(0), next at  000011EA
 000011FA	 00000028	MOVT R2 higher 16-bits var + 40
 000011FE	     BC08	POP R3
 00001200	     4798	BLX R3
 00001202	 00000006	MOV R0 lower 16-bits base(0), next at  000011F6
 00001206	 00000118	MOVT R0 higher 16-bits var + 280
 0000120A	     6801	LDR R1 [ R0 + 0 ]
 0000120C	     1E49	SUBS R1 R1 #1
 0000120E	     6001	STR R1 [  R0 + 0 ]
 00001210	 F000B8C4	B #392, goes to  0000139C
 00001214	     9812	LDR R0 [ SP + 72 ]
 00001216	     2800	CMP R0 #0
 00001218	 F000802D	BEQ #90, goes to  00001276
 0000121C	     2001	MOVS R0 #1
 0000121E	     9002	STR R0 [ SP + 8 ]
 00001220	     980F	LDR R0 [ SP + 60 ]
 00001222	     9004	STR R0 [ SP + 16 ]
 00001224	     9810	LDR R0 [ SP + 64 ]
 00001226	     9005	STR R0 [ SP + 20 ]
 00001228	     9812	LDR R0 [ SP + 72 ]
 0000122A	     9003	STR R0 [ SP + 12 ]
 0000122C	     9804	LDR R0 [ SP + 16 ]
 0000122E	     9905	LDR R1 [ SP + 20 ]
 00001230	 8090005A	BL Mod(  8) proc(9)
 00001234	     9001	STR R0 [ SP + 4 ]
 00001236	     9801	LDR R0 [ SP + 4 ]
 00001238	     2800	CMP R0 #0
 0000123A	     BF08	IT EQ
 0000123C	 EC05B1E4	TrapEQ 4 at pos 11678
 00001240	     6980	LDR R0 [ R0 + 24 ]
 00001242	     B401	PUSH R0
 00001244	     9802	LDR R0 [ SP + 8 ]
 00001246	     A903	ADD R1 SP #12
 00001248	 20000023	MOV R2 lower 16-bits base(0), next at  00001202
 0000124C	 00000028	MOVT R2 higher 16-bits var + 40
 00001250	     BC08	POP R3
 00001252	     4798	BLX R3
 00001254	     A803	ADD R0 SP #12
 00001256	     A904	ADD R1 SP #16
 00001258	     AA05	ADD R2 SP #20
 0000125A	 60300015	BL Mod(  6) proc(3)
 0000125E	     9803	LDR R0 [ SP + 12 ]
 00001260	     2800	CMP R0 #0
 00001262	     D1E3	BNE #-58, goes to  0000122C
 00001264	 0000000E	MOV R0 lower 16-bits base(0), next at  00001248
 00001268	 00000118	MOVT R0 higher 16-bits var + 280
 0000126C	     6801	LDR R1 [ R0 + 0 ]
 0000126E	     1E49	SUBS R1 R1 #1
 00001270	     6001	STR R1 [  R0 + 0 ]
 00001272	 F000B893	B #294, goes to  0000139C
 00001276	     980F	LDR R0 [ SP + 60 ]
 00001278	     990D	LDR R1 [ SP + 52 ]
 0000127A	     4288	CMP R0 R1
 0000127C	 F040800D	BNE #26, goes to  0000129A
 00001280	     9810	LDR R0 [ SP + 64 ]
 00001282	     990E	LDR R1 [ SP + 56 ]
 00001284	     4288	CMP R0 R1
 00001286	 F0408008	BNE #16, goes to  0000129A
 0000128A	 00000013	MOV R0 lower 16-bits base(0), next at  00001264
 0000128E	 000000C0	MOVT R0 higher 16-bits var + 192
 00001292	     7800	LDRB R0 [ R0 + 0 ]
 00001294	     2800	CMP R0 #0
 00001296	 F0408028	BNE #80, goes to  000012EA
 0000129A	     2001	MOVS R0 #1
 0000129C	     9002	STR R0 [ SP + 8 ]
 0000129E	     980F	LDR R0 [ SP + 60 ]
 000012A0	     9004	STR R0 [ SP + 16 ]
 000012A2	     9810	LDR R0 [ SP + 64 ]
 000012A4	 F5B07F40	CMP R0 #768
 000012A8	 F2C08003	BLT #6, goes to  000012B2
 000012AC	 F45F7040	MOVS R0 #768
 000012B0	     9010	STR R0 [ SP + 64 ]
 000012B2	     9810	LDR R0 [ SP + 64 ]
 000012B4	     9005	STR R0 [ SP + 20 ]
 000012B6	     9812	LDR R0 [ SP + 72 ]
 000012B8	     9003	STR R0 [ SP + 12 ]
 000012BA	     980F	LDR R0 [ SP + 60 ]
 000012BC	     9910	LDR R1 [ SP + 64 ]
 000012BE	 80900032	BL Mod(  8) proc(9)
 000012C2	     9001	STR R0 [ SP + 4 ]
 000012C4	     9801	LDR R0 [ SP + 4 ]
 000012C6	     2800	CMP R0 #0
 000012C8	     BF08	IT EQ
 000012CA	 EC05D5F4	TrapEQ 4 at pos 11999
 000012CE	     6980	LDR R0 [ R0 + 24 ]
 000012D0	     B401	PUSH R0
 000012D2	     9802	LDR R0 [ SP + 8 ]
 000012D4	     A903	ADD R1 SP #12
 000012D6	 20000026	MOV R2 lower 16-bits base(0), next at  0000128A
 000012DA	 00000028	MOVT R2 higher 16-bits var + 40
 000012DE	     BC08	POP R3
 000012E0	     4798	BLX R3
 000012E2	     980F	LDR R0 [ SP + 60 ]
 000012E4	     900D	STR R0 [ SP + 52 ]
 000012E6	     9810	LDR R0 [ SP + 64 ]
 000012E8	     900E	STR R0 [ SP + 56 ]
 000012EA	 0000000A	MOV R0 lower 16-bits base(0), next at  000012D6
 000012EE	 00000108	MOVT R0 higher 16-bits var + 264
 000012F2	     6800	LDR R0 [ R0 + 0 ]
 000012F4	     2800	CMP R0 #0
 000012F6	     BF08	IT EQ
 000012F8	 EC05E2A4	TrapEQ 4 at pos 12074
 000012FC	     68C0	LDR R0 [ R0 + 12 ]
 000012FE	 1000000A	MOV R1 lower 16-bits base(0), next at  000012EA
 00001302	 00000108	MOVT R1 higher 16-bits var + 264
 00001306	     6008	STR R0 [  R1 + 0 ]
 00001308	 31700025	BL Mod(  3) proc(23)
 0000130C	     9011	STR R0 [ SP + 68 ]
 0000130E	 00000008	MOV R0 lower 16-bits base(0), next at  000012FE
 00001312	 00000108	MOVT R0 higher 16-bits var + 264
 00001316	     6800	LDR R0 [ R0 + 0 ]
 00001318	     2800	CMP R0 #0
 0000131A	     BF08	IT EQ
 0000131C	 EC05E604	TrapEQ 4 at pos 12128
 00001320	     9911	LDR R1 [ SP + 68 ]
 00001322	     6840	LDR R0 [ R0 + 4 ]
 00001324	     4281	CMP R1 R0
 00001326	 F2C08039	BLT #114, goes to  0000139C
 0000132A	 0000000E	MOV R0 lower 16-bits base(0), next at  0000130E
 0000132E	 00000108	MOVT R0 higher 16-bits var + 264
 00001332	     6800	LDR R0 [ R0 + 0 ]
 00001334	     2800	CMP R0 #0
 00001336	     BF08	IT EQ
 00001338	 EC05F004	TrapEQ 4 at pos 12160
 0000133C	 10000009	MOV R1 lower 16-bits base(0), next at  0000132A
 00001340	 00000108	MOVT R1 higher 16-bits var + 264
 00001344	     6809	LDR R1 [ R1 + 0 ]
 00001346	     2900	CMP R1 #0
 00001348	     BF08	IT EQ
 0000134A	 EC05F164	TrapEQ 4 at pos 12182
 0000134E	     9A11	LDR R2 [ SP + 68 ]
 00001350	     6889	LDR R1 [ R1 + 8 ]
 00001352	     1851	ADDS R1 R2 R1
 00001354	     6041	STR R1 [  R0 + 4 ]
 00001356	 0000000D	MOV R0 lower 16-bits base(0), next at  0000133C
 0000135A	 00000108	MOVT R0 higher 16-bits var + 264
 0000135E	     6800	LDR R0 [ R0 + 0 ]
 00001360	     2800	CMP R0 #0
 00001362	     BF08	IT EQ
 00001364	 EC05F254	TrapEQ 4 at pos 12197
 00001368	     2102	MOVS R1 #2
 0000136A	     6001	STR R1 [  R0 + 0 ]
 0000136C	 0000000B	MOV R0 lower 16-bits base(0), next at  00001356
 00001370	 00000108	MOVT R0 higher 16-bits var + 264
 00001374	     6800	LDR R0 [ R0 + 0 ]
 00001376	     2800	CMP R0 #0
 00001378	     BF08	IT EQ
 0000137A	 EC05F3F4	TrapEQ 4 at pos 12223
 0000137E	     6900	LDR R0 [ R0 + 16 ]
 00001380	     B401	PUSH R0
 00001382	     BC01	POP R0
 00001384	     4780	BLX R0
 00001386	 0000000D	MOV R0 lower 16-bits base(0), next at  0000136C
 0000138A	 00000108	MOVT R0 higher 16-bits var + 264
 0000138E	     6800	LDR R0 [ R0 + 0 ]
 00001390	     2800	CMP R0 #0
 00001392	     BF08	IT EQ
 00001394	 EC05F4E4	TrapEQ 4 at pos 12238
 00001398	     2101	MOVS R1 #1
 0000139A	     6001	STR R1 [  R0 + 0 ]
 0000139C	     E6B8	B #-656, goes to  00001110
 0000139E	 F85DEB04	LDR LR [ SP ] + 4
 000013A2	     B013	ADD SP SP #76
 000013A4	     4770	BX LR
 000013A6	     B081	SUB SP SP #4
 000013A8	     B500	PUSH LR
 000013AA	 F6434014	MOV R0 #15380
 000013AE	 F2C40001	MOVT R0 #16385
 000013B2	     6800	LDR R0 [ R0 + 0 ]
 000013B4	     9001	STR R0 [ SP + 4 ]
 000013B6	     9801	LDR R0 [ SP + 4 ]
 000013B8	 10000019	MOV R1 lower 16-bits base(0), next at  00001386
 000013BC	 00000124	MOVT R1 higher 16-bits var + 292
 000013C0	     7809	LDRB R1 [ R1 + 0 ]
 000013C2	     1C49	ADDS R1 R1 #1
 000013C4	     41C8	RORS R0 R0 R1
 000013C6	 F1408019	BPL #50, goes to  000013FC
 000013CA	 00000009	MOV R0 lower 16-bits base(0), next at  000013B8
 000013CE	 00000124	MOVT R0 higher 16-bits var + 292
 000013D2	     7800	LDRB R0 [ R0 + 0 ]
 000013D4	     2101	MOVS R1 #1
 000013D6	 FA11F000	LSLS R0 R1 R0
 000013DA	     9001	STR R0 [ SP + 4 ]
 000013DC	 F6434014	MOV R0 #15380
 000013E0	 F2C40001	MOVT R0 #16385
 000013E4	     9901	LDR R1 [ SP + 4 ]
 000013E6	     6001	STR R1 [  R0 + 0 ]
 000013E8	 0000000F	MOV R0 lower 16-bits base(0), next at  000013CA
 000013EC	 00000120	MOVT R0 higher 16-bits var + 288
 000013F0	 12000004	MOV R1 lower 16-bits base(2), next at  000013E8
 000013F4	 00000003	MOVT R1 higher 16-bits var(3)
 000013F8	 20700078	BL Mod(  2) proc(7)
 000013FC	 F85DEB04	LDR LR [ SP ] + 4
 00001400	     B001	ADD SP SP #4
 00001402	     4770	BX LR
 00001404	     B081	SUB SP SP #4
 00001406	     B500	PUSH LR
 00001408	 F6434014	MOV R0 #15380
 0000140C	 F2C40001	MOVT R0 #16385
 00001410	     6800	LDR R0 [ R0 + 0 ]
 00001412	     9001	STR R0 [ SP + 4 ]
 00001414	     9801	LDR R0 [ SP + 4 ]
 00001416	 10000013	MOV R1 lower 16-bits base(0), next at  000013F0
 0000141A	 0000017C	MOVT R1 higher 16-bits var + 380
 0000141E	     7809	LDRB R1 [ R1 + 0 ]
 00001420	     1C49	ADDS R1 R1 #1
 00001422	     41C8	RORS R0 R0 R1
 00001424	 F1408019	BPL #50, goes to  0000145A
 00001428	 00000009	MOV R0 lower 16-bits base(0), next at  00001416
 0000142C	 0000017C	MOVT R0 higher 16-bits var + 380
 00001430	     7800	LDRB R0 [ R0 + 0 ]
 00001432	     2101	MOVS R1 #1
 00001434	 FA11F000	LSLS R0 R1 R0
 00001438	     9001	STR R0 [ SP + 4 ]
 0000143A	 F6434014	MOV R0 #15380
 0000143E	 F2C40001	MOVT R0 #16385
 00001442	     9901	LDR R1 [ SP + 4 ]
 00001444	     6001	STR R1 [  R0 + 0 ]
 00001446	 0000000F	MOV R0 lower 16-bits base(0), next at  00001428
 0000144A	 00000178	MOVT R0 higher 16-bits var + 376
 0000144E	 12000004	MOV R1 lower 16-bits base(2), next at  00001446
 00001452	 00000003	MOVT R1 higher 16-bits var(3)
 00001456	 2070002F	BL Mod(  2) proc(7)
 0000145A	 F85DEB04	LDR LR [ SP ] + 4
 0000145E	     B001	ADD SP SP #4
 00001460	     4770	BX LR
 00001462	     B500	PUSH LR
 00001464	 0000000B	MOV R0 lower 16-bits base(0), next at  0000144E
 00001468	 00000108	MOVT R0 higher 16-bits var + 264
 0000146C	     6800	LDR R0 [ R0 + 0 ]
 0000146E	     2800	CMP R0 #0
 00001470	     BF08	IT EQ
 00001472	 EC064284	TrapEQ 4 at pos 12840
 00001476	     6800	LDR R0 [ R0 + 0 ]
 00001478	     2802	CMP R0 #2
 0000147A	 F0408007	BNE #14, goes to  0000148C
 0000147E	 0000000D	MOV R0 lower 16-bits base(0), next at  00001464
 00001482	 00000108	MOVT R0 higher 16-bits var + 264
 00001486	     6800	LDR R0 [ R0 + 0 ]
 00001488	 F7FFFDB8	BL #-1168, goes to  00000FFC
 0000148C	 F7FFFE3E	BL #-900, goes to  0000110C
 00001490	 F85DEB04	LDR LR [ SP ] + 4
 00001494	     4770	BX LR
 00001496	     B403	PUSH R0 R1
 00001498	     B500	PUSH LR
 0000149A	 F89D0004	LDRB R0 [ SP + 4 ]
 0000149E	     2802	CMP R0 #2
 000014A0	 F2808015	BGE #42, goes to  000014CE
 000014A4	 F89D0004	LDRB R0 [ SP + 4 ]
 000014A8	     2802	CMP R0 #2
 000014AA	     BF28	IT CS
 000014AC	 EC065451	TrapCS 1 at pos 12997
 000014B0	     2158	MOVS R1 #88
 000014B2	     4348	MULS R0 R1 R0
 000014B4	 1000001B	MOV R1 lower 16-bits base(0), next at  0000147E
 000014B8	 00000120	MOVT R1 higher 16-bits var + 288
 000014BC	     1808	ADDS R0 R1 R0
 000014BE	 12000005	MOV R1 lower 16-bits base(2), next at  000014B4
 000014C2	 00000003	MOVT R1 higher 16-bits var(3)
 000014C6	 F89D2008	LDRB R2 [ SP + 8 ]
 000014CA	 2050003A	BL Mod(  2) proc(5)
 000014CE	 F85DEB04	LDR LR [ SP ] + 4
 000014D2	     B002	ADD SP SP #8
 000014D4	     4770	BX LR
 000014D6	     B081	SUB SP SP #4
 000014D8	     B403	PUSH R0 R1
 000014DA	     B500	PUSH LR
 000014DC	 F89D0004	LDRB R0 [ SP + 4 ]
 000014E0	     2802	CMP R0 #2
 000014E2	 F2808015	BGE #42, goes to  00001510
 000014E6	 F89D0004	LDRB R0 [ SP + 4 ]
 000014EA	     2802	CMP R0 #2
 000014EC	     BF28	IT CS
 000014EE	 EC067021	TrapCS 1 at pos 13186
 000014F2	     2158	MOVS R1 #88
 000014F4	     4348	MULS R0 R1 R0
 000014F6	 1000001C	MOV R1 lower 16-bits base(0), next at  000014BE
 000014FA	 00000120	MOVT R1 higher 16-bits var + 288
 000014FE	     1808	ADDS R0 R1 R0
 00001500	 12000005	MOV R1 lower 16-bits base(2), next at  000014F6
 00001504	 00000003	MOVT R1 higher 16-bits var(3)
 00001508	     9A02	LDR R2 [ SP + 8 ]
 0000150A	 20600020	BL Mod(  2) proc(6)
 0000150E	     9003	STR R0 [ SP + 12 ]
 00001510	     9803	LDR R0 [ SP + 12 ]
 00001512	 F85DEB04	LDR LR [ SP ] + 4
 00001516	     B003	ADD SP SP #12
 00001518	     4770	BX LR
 0000151A	     B081	SUB SP SP #4
 0000151C	     B500	PUSH LR
 0000151E	 1050000A	BL Mod(  1) proc(5)
 00001522	 F2AF107D	ADR R0 L 000013A7
 00001526	     2160	MOVS R1 #96
 00001528	 F2C20100	MOVT R1 #8192
 0000152C	 31A00007	BL Mod(  3) proc(26)
 00001530	 F2AF102F	ADR R0 L 00001405
 00001534	     2168	MOVS R1 #104
 00001536	 F2C20100	MOVT R1 #8192
 0000153A	 31A00007	BL Mod(  3) proc(26)
 0000153E	     2008	MOVS R0 #8
 00001540	     9001	STR R0 [ SP + 4 ]
 00001542	     9801	LDR R0 [ SP + 4 ]
 00001544	     1140	ASRS R0 R0 #5
 00001546	     0080	LSLS R0 R0 #2
 00001548	 F24E1100	MOV R1 #57600
 0000154C	 F2CE0100	MOVT R1 #57344
 00001550	     1808	ADDS R0 R1 R0
 00001552	     9901	LDR R1 [ SP + 4 ]
 00001554	 F36F115F	BFC R1 #5 #27
 00001558	     2201	MOVS R2 #1
 0000155A	 FA12F101	LSLS R1 R2 R1
 0000155E	     6001	STR R1 [  R0 + 0 ]
 00001560	     200A	MOVS R0 #10
 00001562	     9001	STR R0 [ SP + 4 ]
 00001564	     9801	LDR R0 [ SP + 4 ]
 00001566	     1140	ASRS R0 R0 #5
 00001568	     0080	LSLS R0 R0 #2
 0000156A	 F24E1100	MOV R1 #57600
 0000156E	 F2CE0100	MOVT R1 #57344
 00001572	     1808	ADDS R0 R1 R0
 00001574	     9901	LDR R1 [ SP + 4 ]
 00001576	 F36F115F	BFC R1 #5 #27
 0000157A	     2201	MOVS R2 #1
 0000157C	 FA12F101	LSLS R1 R2 R1
 00001580	     6001	STR R1 [  R0 + 0 ]
 00001582	 F85DEB04	LDR LR [ SP ] + 4
 00001586	     B001	ADD SP SP #4
 00001588	     4770	BX LR
 0000158A	     B500	PUSH LR             ; d0208d62:   push    {lr} => d0208f5c:   bl      0xd02019e2
 0000158C	     2000	MOVS R0 #0
 0000158E	 10000047	MOV R1 lower 16-bits base(0), next at  00001500
 00001592	 0000009C	MOVT R1 higher 16-bits var + 156
 00001596	     7008	STRB R0 [ R1 + 0 ]
 00001598	 F000F800	BL #0, goes to  0000159C
 0000159C	 F24141A6	MOV R1 #5286
 000015A0	 EBAE0001	SUB R0 LR R1 LSL #0
 000015A4	 1000000B	MOV R1 lower 16-bits base(0), next at  0000158E
 000015A8	 000000A8	MOVT R1 higher 16-bits var + 168
 000015AC	     6008	STR R0 [  R1 + 0 ]
 000015AE	 F000F800	BL #0, goes to  000015B2
 000015B2	 F24141BC	MOV R1 #5308
 000015B6	 EBAE0001	SUB R0 LR R1 LSL #0
 000015BA	 1000000B	MOV R1 lower 16-bits base(0), next at  000015A4
 000015BE	 000000AC	MOVT R1 higher 16-bits var + 172
 000015C2	     6008	STR R0 [  R1 + 0 ]
 000015C4	 F000F800	BL #0, goes to  000015C8
 000015C8	 F241410E	MOV R1 #5134
 000015CC	 EBAE0001	SUB R0 LR R1 LSL #0
 000015D0	 1000000B	MOV R1 lower 16-bits base(0), next at  000015BA
 000015D4	 000000B0	MOVT R1 higher 16-bits var + 176
 000015D8	     6008	STR R0 [  R1 + 0 ]
 000015DA	 F000F800	BL #0, goes to  000015DE
 000015DE	 F2414124	MOV R1 #5156
 000015E2	 EBAE0001	SUB R0 LR R1 LSL #0
 000015E6	 1000000B	MOV R1 lower 16-bits base(0), next at  000015D0
 000015EA	 000000B4	MOVT R1 higher 16-bits var + 180
 000015EE	     6008	STR R0 [  R1 + 0 ]
 000015F0	 00000005	MOV R0 lower 16-bits base(0), next at  000015E6
 000015F4	 000000B8	MOVT R0 higher 16-bits var + 184
 000015F8	 10000004	MOV R1 lower 16-bits base(0), next at  000015F0
 000015FC	 00000014	MOVT R1 higher 16-bits var + 20
 00001600	 F7FEFE5B	BL #-4938, goes to  000002BA
 00001604	 00000006	MOV R0 lower 16-bits base(0), next at  000015F8
 00001608	 000000CC	MOVT R0 higher 16-bits var + 204
 0000160C	 10000004	MOV R1 lower 16-bits base(0), next at  00001604
 00001610	 00000014	MOVT R1 higher 16-bits var + 20
 00001614	 F7FEFE51	BL #-4958, goes to  000002BA
 00001618	 F2405056	MOV R0 #1366
 0000161C	 10000008	MOV R1 lower 16-bits base(0), next at  0000160C
 00001620	 0000010C	MOVT R1 higher 16-bits var + 268
 00001624	     6008	STR R0 [  R1 + 0 ]
 00001626	 F45F7040	MOVS R0 #768
 0000162A	 10000007	MOV R1 lower 16-bits base(0), next at  0000161C
 0000162E	 00000110	MOVT R1 higher 16-bits var + 272
 00001632	     6008	STR R0 [  R1 + 0 ]
 00001634	 00000005	MOV R0 lower 16-bits base(0), next at  0000162A
 00001638	 0000010C	MOVT R0 higher 16-bits var + 268
 0000163C	     6800	LDR R0 [ R0 + 0 ]
 0000163E	 10000005	MOV R1 lower 16-bits base(0), next at  00001634
 00001642	 00000114	MOVT R1 higher 16-bits var + 276
 00001646	     6008	STR R0 [  R1 + 0 ]
 00001648	 00000005	MOV R0 lower 16-bits base(0), next at  0000163E
 0000164C	 0000010C	MOVT R0 higher 16-bits var + 268
 00001650	     6800	LDR R0 [ R0 + 0 ]
 00001652	     10C0	ASRS R0 R0 #3
 00001654	     2105	MOVS R1 #5
 00001656	     4348	MULS R0 R1 R0
 00001658	 10000008	MOV R1 lower 16-bits base(0), next at  00001648
 0000165C	 0000010C	MOVT R1 higher 16-bits var + 268
 00001660	     6809	LDR R1 [ R1 + 0 ]
 00001662	     10C9	ASRS R1 R1 #3
 00001664	     2205	MOVS R2 #5
 00001666	     4351	MULS R1 R2 R1
 00001668	 F2405256	MOV R2 #1366
 0000166C	 EBD10102	RSBS R1 R1 R2 LSL #0
 00001670	 2000000C	MOV R2 lower 16-bits base(0), next at  00001658
 00001674	 00000110	MOVT R2 higher 16-bits var + 272
 00001678	     6812	LDR R2 [ R2 + 0 ]
 0000167A	 F7FFF83C	BL #-3976, goes to  000006F6
 0000167E	     2000	MOVS R0 #0
 00001680	     2100	MOVS R1 #0
 00001682	 809000A4	BL Mod(  8) proc(9)
 00001686	 1000000B	MOV R1 lower 16-bits base(0), next at  00001670
 0000168A	 000000E0	MOVT R1 higher 16-bits var + 224
 0000168E	     6008	STR R0 [  R1 + 0 ]
 00001690	 09000005	MOV R0 lower 16-bits base(9), next at  00001686
 00001694	 00000002	MOVT R0 higher 16-bits var(2)
 00001698	     6800	LDR R0 [ R0 + 0 ]
 0000169A	 10000005	MOV R1 lower 16-bits base(0), next at  00001690
 0000169E	 000000F8	MOVT R1 higher 16-bits var + 248
 000016A2	     6008	STR R0 [  R1 + 0 ]
 000016A4	     20FF	MOVS R0 #255
 000016A6	 10000006	MOV R1 lower 16-bits base(0), next at  0000169A
 000016AA	 000000FC	MOVT R1 higher 16-bits var + 252
 000016AE	     6008	STR R0 [  R1 + 0 ]
 000016B0	     2000	MOVS R0 #0
 000016B2	 10000006	MOV R1 lower 16-bits base(0), next at  000016A6
 000016B6	 00000100	MOVT R1 higher 16-bits var + 256
 000016BA	     6008	STR R0 [  R1 + 0 ]
 000016BC	     2000	MOVS R0 #0
 000016BE	 10000006	MOV R1 lower 16-bits base(0), next at  000016B2
 000016C2	 00000118	MOVT R1 higher 16-bits var + 280
 000016C6	     6008	STR R0 [  R1 + 0 ]
 000016C8	 F6AF00EF	ADR R0 L 00000DDD
 000016CC	 F45F717A	MOVS R1 #1000
 000016D0	 F7FFFC1E	BL #-1988, goes to  00000F10
 000016D4	 1000000B	MOV R1 lower 16-bits base(0), next at  000016BE
 000016D8	 00000108	MOVT R1 higher 16-bits var + 264
 000016DC	     6008	STR R0 [  R1 + 0 ]
 000016DE	 00000005	MOV R0 lower 16-bits base(0), next at  000016D4
 000016E2	 00000108	MOVT R0 higher 16-bits var + 264
 000016E6	     6800	LDR R0 [ R0 + 0 ]
 000016E8	 F7FFFC3C	BL #-1928, goes to  00000F64
 000016EC	 F7FFFF15	BL #-470, goes to  0000151A
 000016F0	     2000	MOVS R0 #0
 000016F2	 1000000A	MOV R1 lower 16-bits base(0), next at  000016DE
 000016F6	 00000123	MOVT R1 higher 16-bits var + 291
 000016FA	     7008	STRB R0 [ R1 + 0 ]
 000016FC	     2002	MOVS R0 #2
 000016FE	 10000006	MOV R1 lower 16-bits base(0), next at  000016F2
 00001702	 00000124	MOVT R1 higher 16-bits var + 292
 00001706	     7008	STRB R0 [ R1 + 0 ]
 00001708	 F2402008	MOV R0 #520
 0000170C	 F2C42042	MOVT R0 #16962
 00001710	 10000009	MOV R1 lower 16-bits base(0), next at  000016FE
 00001714	 0000012C	MOVT R1 higher 16-bits var + 300
 00001718	     6008	STR R0 [  R1 + 0 ]
 0000171A	 F2402088	MOV R0 #648
 0000171E	 F2C42042	MOVT R0 #16962
 00001722	 10000009	MOV R1 lower 16-bits base(0), next at  00001710
 00001726	 00000134	MOVT R1 higher 16-bits var + 308
 0000172A	     6008	STR R0 [  R1 + 0 ]
 0000172C	 F240200C	MOV R0 #524
 00001730	 F2C42042	MOVT R0 #16962
 00001734	 10000009	MOV R1 lower 16-bits base(0), next at  00001722
 00001738	 00000130	MOVT R1 higher 16-bits var + 304
 0000173C	     6008	STR R0 [  R1 + 0 ]
 0000173E	 F240208C	MOV R0 #652
 00001742	 F2C42042	MOVT R0 #16962
 00001746	 10000009	MOV R1 lower 16-bits base(0), next at  00001734
 0000174A	 00000138	MOVT R1 higher 16-bits var + 312
 0000174E	     6008	STR R0 [  R1 + 0 ]
 00001750	 F24020B4	MOV R0 #692
 00001754	 F2C42043	MOVT R0 #16963
 00001758	 10000009	MOV R1 lower 16-bits base(0), next at  00001746
 0000175C	 00000144	MOVT R1 higher 16-bits var + 324
 00001760	     6008	STR R0 [  R1 + 0 ]
 00001762	 F24020B8	MOV R0 #696
 00001766	 F2C42043	MOVT R0 #16963
 0000176A	 10000009	MOV R1 lower 16-bits base(0), next at  00001758
 0000176E	 00000140	MOVT R1 higher 16-bits var + 320
 00001772	     6008	STR R0 [  R1 + 0 ]
 00001774	 00000005	MOV R0 lower 16-bits base(0), next at  0000176A
 00001778	 00000120	MOVT R0 higher 16-bits var + 288
 0000177C	 12000004	MOV R1 lower 16-bits base(2), next at  00001774
 00001780	 00000003	MOVT R1 higher 16-bits var(3)
 00001784	 20A00081	BL Mod(  2) proc(10) <= Problème dans cette procédure
 00001788	     2000	MOVS R0 #0
 0000178A	 10000007	MOV R1 lower 16-bits base(0), next at  0000177C
 0000178E	 0000017B	MOVT R1 higher 16-bits var + 379
 00001792	     7008	STRB R0 [ R1 + 0 ]
 00001794	     2004	MOVS R0 #4
 00001796	 10000006	MOV R1 lower 16-bits base(0), next at  0000178A
 0000179A	 0000017C	MOVT R1 higher 16-bits var + 380
 0000179E	     7008	STRB R0 [ R1 + 0 ]
 000017A0	 F2402010	MOV R0 #528
 000017A4	 F2C42042	MOVT R0 #16962
 000017A8	 10000009	MOV R1 lower 16-bits base(0), next at  00001796
 000017AC	 00000184	MOVT R1 higher 16-bits var + 388
 000017B0	     6008	STR R0 [  R1 + 0 ]
 000017B2	 F2402090	MOV R0 #656
 000017B6	 F2C42042	MOVT R0 #16962
 000017BA	 10000009	MOV R1 lower 16-bits base(0), next at  000017A8
 000017BE	 0000018C	MOVT R1 higher 16-bits var + 396
 000017C2	     6008	STR R0 [  R1 + 0 ]
 000017C4	 F2402014	MOV R0 #532
 000017C8	 F2C42042	MOVT R0 #16962
 000017CC	 10000009	MOV R1 lower 16-bits base(0), next at  000017BA
 000017D0	 00000188	MOVT R1 higher 16-bits var + 392
 000017D4	     6008	STR R0 [  R1 + 0 ]
 000017D6	 F2402094	MOV R0 #660
 000017DA	 F2C42042	MOVT R0 #16962
 000017DE	 10000009	MOV R1 lower 16-bits base(0), next at  000017CC
 000017E2	 00000190	MOVT R1 higher 16-bits var + 400
 000017E6	     6008	STR R0 [  R1 + 0 ]
 000017E8	 F24020B4	MOV R0 #692
 000017EC	 F2C42043	MOVT R0 #16963
 000017F0	 10000009	MOV R1 lower 16-bits base(0), next at  000017DE
 000017F4	 0000019C	MOVT R1 higher 16-bits var + 412
 000017F8	     6008	STR R0 [  R1 + 0 ]
 000017FA	 F24020B8	MOV R0 #696
 000017FE	 F2C42043	MOVT R0 #16963
 00001802	 10000009	MOV R1 lower 16-bits base(0), next at  000017F0
 00001806	 00000198	MOVT R1 higher 16-bits var + 408
 0000180A	     6008	STR R0 [  R1 + 0 ]
 0000180C	 00000005	MOV R0 lower 16-bits base(0), next at  00001802
 00001810	 00000178	MOVT R0 higher 16-bits var + 376
 00001814	 12000004	MOV R1 lower 16-bits base(2), next at  0000180C
 00001818	 00000003	MOVT R1 higher 16-bits var(3)
 0000181C	 20A0004C	BL Mod(  2) proc(10)
 00001820	 00000006	MOV R0 lower 16-bits base(0), next at  00001814
 00001824	 000001D0	MOVT R0 higher 16-bits var + 464
 00001828	     2107	MOVS R1 #7
 0000182A	 20000005	MOV R2 lower 16-bits base(0), next at  00001820
 0000182E	 0000011C	MOVT R2 higher 16-bits var + 284
 00001832	 5080000B	BL Mod(  5) proc(8)
 00001836	 00000006	MOV R0 lower 16-bits base(0), next at  0000182A
 0000183A	 000001D8	MOVT R0 higher 16-bits var + 472
 0000183E	     210A	MOVS R1 #10
 00001840	 20000005	MOV R2 lower 16-bits base(0), next at  00001836
 00001844	 0000011C	MOVT R2 higher 16-bits var + 284
 00001848	 5080000B	BL Mod(  5) proc(8)
 0000184C	     2000	MOVS R0 #0
 0000184E	 10000007	MOV R1 lower 16-bits base(0), next at  00001840
 00001852	 0000011C	MOVT R1 higher 16-bits var + 284
 00001856	     6008	STR R0 [  R1 + 0 ]
 00001858	 F7FFFC58	BL #-1872, goes to  0000110C
 0000185C	 F85DEB04	LDR LR [ SP ] + 4
 00001860	     4770	BX LR
