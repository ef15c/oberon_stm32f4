MODULE Net; (*NW 3.7.88 / 25.8.91 / PR 7.8.13 / 9.12.13 CS 20/01/24*)
  IMPORT Files, Texts, SCC, Oberon;

  CONST PakSize = 512;
    T0 = 300; (*timeout*)
    ACK = 10H; NAK = 25H; NPR = 26H; (*acknowledgements*)
    NRQ = 34H; NRS = 35H; (*name request, response*)
    SND = 41H; REC = 42H; MSG = 44H;
    TRQ = 46H; TIM = 47H; (*time requests*)

  VAR W: Texts.Writer;
     Server: Oberon.Task;
     head0, head1: SCC.Header;
     partner: ARRAY 8 OF CHAR;
     dmy: ARRAY 8 OF BYTE;
     protected: BOOLEAN; (*write-protection*)

  PROCEDURE SetPartner(name: ARRAY OF CHAR);
  BEGIN head0.dadr := head1.sadr; partner := name
  END SetPartner;

  PROCEDURE Send(t: BYTE; L: INTEGER; data: ARRAY OF BYTE);
  BEGIN head0.typ := t; head0.len := L; SCC.SendPacket(head0, data)
  END Send;

  PROCEDURE ReceiveHead(timeout: INTEGER);
    VAR time: INTEGER;
  BEGIN time := Oberon.Time() + timeout;
    REPEAT
      SCC.ReceiveHead(head1);
      IF head1.valid & (head1.sadr # head0.dadr) THEN
        SCC.Skip(head1.len); head1.valid := FALSE
      END;
      IF ~head1.valid & (Oberon.Time() >= time) THEN head1.typ := 0FFH END
    UNTIL head1.valid OR (head1.typ = 0FFH)
  END ReceiveHead;

  PROCEDURE FindPartner(name: ARRAY OF CHAR; VAR res: INTEGER);
    VAR k, retry: INTEGER;
      Id: ARRAY 8 OF CHAR; IdB: ARRAY 8 OF BYTE;
  BEGIN SCC.Skip(SCC.Available()); res := 0; k := 0;
    WHILE (k < 7) & (name[k] # 0X) DO Id[k] := name[k]; IdB[k] := ORD(Id[k]); INC(k) END;
    Id[k] := 0X; IdB[k] := 0; (* <-- also terminate IdB *)
    IF Id # partner THEN retry := 10; res := 1;
      REPEAT head0.dadr := 0FFH; Send(NRQ, k+1, IdB); SCC.ReceiveHead(head1);
        IF head1.valid THEN IF head1.typ = NRS THEN SetPartner(Id); res := 0 ELSE SCC.Skip(head1.len); head1.valid := FALSE END
        ELSE  partner[0] := 0X
        END;
        DEC(retry)
      UNTIL head1.valid OR (retry = 0)
    END
  END FindPartner;

  PROCEDURE AppendS(s: ARRAY OF CHAR; VAR d: ARRAY OF BYTE; VAR k: INTEGER);
    VAR i: INTEGER; ch: CHAR;
  BEGIN i := 0;
    REPEAT ch := s[i]; d[k] := ORD(ch); INC(i); INC(k) UNTIL ch = 0X
  END AppendS;

  PROCEDURE AppendW(s: INTEGER; VAR d: ARRAY OF BYTE;
      n: INTEGER; VAR k: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0;
    REPEAT d[k] := s MOD 100H; s := s DIV 100H; INC(i); INC(k) UNTIL i = n
  END AppendW;

  PROCEDURE PickS(VAR s: ARRAY OF CHAR);
    VAR i: INTEGER; x: BYTE;
  BEGIN i := 0;
    REPEAT SCC.Receive(x); s[i] := CHR(x); INC(i) UNTIL x = 0
  END PickS;

  PROCEDURE PickQ(VAR w: INTEGER);
    VAR x0, x1, x2, x3: BYTE;
  BEGIN SCC.Receive(x0); SCC.Receive(x1); SCC.Receive(x2); SCC.Receive(x3);
    w := x0 + 100H * (x1 + 100H * (x2 + 100H * x3))
  END PickQ;

  PROCEDURE SendData(F: Files.File);
    VAR k, retry, seqno, nseqno: INTEGER;
      x: BYTE;
      len: INTEGER;
      R!: Files.Rider;
      buf: ARRAY PakSize OF BYTE;
  BEGIN Files.Set(R, F, 0); len := 0; seqno := 0;
    REPEAT k := 0;
      REPEAT Files.ReadByte(R, x);
        IF ~R.eof THEN buf[k] := x; INC(k) END
      UNTIL R.eof OR (k = PakSize); retry := 20; nseqno := (seqno + 1) MOD 8;
      REPEAT Send(seqno, k, buf); ReceiveHead(T0); DEC(retry);
        IF head1.typ # nseqno + ACK THEN SCC.Delayms(100); END
      UNTIL (head1.typ = nseqno + ACK) OR (retry = 0);
      seqno := nseqno; len := len + k;
      IF head1.typ # seqno + ACK THEN
        Texts.WriteString(W, " failed"); k := 0
      END
    UNTIL k < PakSize;
    Texts.WriteInt(W, len, 7)
  END SendData;

  PROCEDURE ReceiveData(F: Files.File; VAR done: BOOLEAN);
    VAR k, retry, seqno: INTEGER;
     x: BYTE;
     len: INTEGER;
     R!: Files.Rider;
  BEGIN Files.Set(R, F, 0); seqno := 0; len := 0; retry := 20; k := PakSize;
    REPEAT
     IF head1.typ = seqno THEN k := 0;
       WHILE k < head1.len DO
         SCC.Receive(x); Files.WriteByte(R, x); INC(k)
       END ;
       seqno := (seqno + 1) MOD 8; len := len + head1.len;
       REPEAT Send(seqno + ACK, 0, dmy); ReceiveHead(T0); DEC(retry) UNTIL head1.valid OR (retry = 0);
       IF k < PakSize THEN done := TRUE END
     ELSE SCC.Delayms(100); DEC(retry);
       IF retry = 0 THEN
         Texts.WriteString(W, " failed"); done := FALSE; k := 0
       END ; retry := 20;
       REPEAT Send(seqno + ACK, 0, dmy); ReceiveHead(T0); DEC(retry) UNTIL head1.valid OR (retry = 0)
     END ;
    UNTIL k < PakSize;
    Texts.WriteInt(W, len, 7)
  END ReceiveData;

  PROCEDURE reply(msg: INTEGER);
  BEGIN LED(msg*2);
    IF msg = 0 THEN Texts.WriteString(W, " done")
    ELSIF msg = 1 THEN Texts.WriteString(W, " no link")
    ELSIF msg = 2 THEN Texts.WriteString(W, " no permission")
    ELSIF msg = 3 THEN Texts.WriteString(W, " not done")
    ELSIF msg = 4 THEN Texts.WriteString(W, " not found")
    ELSIF msg = 5 THEN Texts.WriteString(W, " no response")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END reply;

  PROCEDURE Serve;
    VAR i: INTEGER;
      done: BOOLEAN; x: BYTE;
      F!: Files.File;
      pw, clock, newclock: INTEGER;
      Id: ARRAY 8 OF CHAR;
      IdB: ARRAY 8 OF BYTE;
      FileName: ARRAY 32 OF CHAR;
  BEGIN
    SCC.ReceiveHead(head1);
    IF head1.valid THEN
      IF head1.typ = SND THEN
        PickS(Id); PickQ(pw); PickS(FileName);
        Texts.WriteString(W, Id); Texts.Write(W, " ");
        Texts.WriteString(W, FileName);
        F := Files.Old(FileName);
        IF F # NIL THEN
          Texts.WriteString(W, " sending"); SetPartner(Id);
          Texts.Append(Oberon.Log, W.buf); SendData(F)
        ELSE Send(NAK, 0, dmy); Texts.Write(W, "~")
        END ;
        reply(0)
      ELSIF head1.typ = REC THEN
        PickS(Id); PickQ(pw); PickS(FileName);
        IF ~protected THEN
          Texts.WriteString(W, Id); Texts.Write(W, " ");
          Texts.WriteString(W, FileName);
          F := Files.New(FileName);
          IF F # NIL THEN
            Texts.WriteString(W, " receiving"); SetPartner(Id);
            Texts.Append(Oberon.Log, W.buf);
            Send(ACK, 0, dmy); ReceiveHead(T0); ReceiveData(F, done);
            IF done THEN Files.Register(F) END
          ELSE Send(NAK, 0, dmy); Texts.Write(W, "~")
          END ;
          reply(0)
        ELSE Send(NPR, 0, dmy)
        END
      ELSIF head1.typ = MSG THEN i := 0;
        WHILE i < head1.len DO SCC.Receive(x); Texts.Write(W, CHR(x));
          INC(i) END ;
        Send(ACK, 0, dmy); reply(0)
      ELSIF head1.typ = TRQ THEN
        i := 0; AppendW(Oberon.Clock(), IdB, 4, i); Send(TIM, 4, IdB)
      ELSIF head1.typ = TIM THEN PickQ(newclock); PickS(Id); PickQ(pw);
        clock := Oberon.Clock();
        IF ~protected & (Id[0] # 0X) & (ABS(pw - clock) > 10) THEN
          Oberon.SetClock(newclock);
          Texts.WriteString(W, Id); Texts.WriteString(W, 
          " changed System.Date");
          Texts.WriteClock(W, newclock); reply(0)
         END
      ELSIF head1.typ = NRQ THEN
        i := 0;
        REPEAT SCC.Receive(x); Id[i] := CHR(x); INC(i);
          IF i = 7 THEN Id[7] := 0X; x := 0 END
        UNTIL x = 0;
        WHILE i < head1.len DO SCC.Receive(x); INC(i) END ;
        IF Id = Oberon.User THEN
          SetPartner(Id); Send(NRS, 0, dmy)
        END
      ELSE SCC.Skip(head1.len)
      END
    END
  END Serve;

  PROCEDURE GetPar1(VAR S: Texts.Scanner);
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S)
  END GetPar1;

  PROCEDURE GetPar(VAR S: Texts.Scanner; VAR end: INTEGER);
    VAR T!: Texts.Text; beg, tm: INTEGER;
  BEGIN Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, tm);
      IF tm >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    ELSE end := Oberon.Par.text.len
    END
  END GetPar;

  PROCEDURE SendFiles*;
    VAR k, retry: INTEGER;
      end: INTEGER;
      S!: Texts.Scanner;
      F!: Files.File;
      buf: ARRAY 64 OF BYTE;
  BEGIN GetPar1(S);
    IF S.class = Texts.Name THEN
      FindPartner(S.s, k);
      IF k = 0 THEN
        GetPar(S, end);
        WHILE (Texts.Pos(S) < end) & (S.class = Texts.Name) DO
          Texts.WriteString(W, S.s); k := 0;
          AppendS(Oberon.User, buf, k); AppendW(Oberon.Password, buf, 4, k);
          AppendS(S.s, buf, k);
          IF S.nextCh = ":" THEN (*prefix*)
            Texts.Scan(S); Texts.Scan(S);
            IF S.class = Texts.Name THEN
              buf[k-1] := ORD("."); AppendS(S.s, buf, k);
              Texts.Write(W, ":"); Texts.WriteString(W, S.s)
            END
          END ;
          F := Files.Old(S.s);
          IF F # NIL THEN retry := 10;
            REPEAT Send(REC, k, buf); ReceiveHead(T0); DEC(retry) UNTIL head1.valid OR (retry = 0);
            IF head1.typ = ACK THEN
              Texts.WriteString(W, " sending"); Texts.Append(Oberon.Log, W.buf);
              SendData(F); reply(0)
            ELSIF head1.typ = NPR THEN reply(2); end := 0
            ELSIF head1.typ = NAK THEN reply(3); end := 0
            ELSE reply(5); end := 0
            END
          ELSE reply(4)
          END ;
          Texts.Scan(S)
        END
      ELSE reply(1)
      END
    END
  END SendFiles;

  PROCEDURE ReceiveFiles*;
    VAR k, retry: INTEGER; done: BOOLEAN;
      end: INTEGER;
      S!: Texts.Scanner;
      F!: Files.File;
      buf: ARRAY 64 OF BYTE;
  BEGIN GetPar1(S);
    IF S.class = Texts.Name THEN
      FindPartner(S.s, k);
      IF k = 0 THEN
        GetPar(S, end);
        WHILE (Texts.Pos(S) < end) & (S.class = Texts.Name) DO
          Texts.WriteString(W, S.s);
          k := 0; AppendS(Oberon.User, buf, k); AppendW(Oberon.Password,
            buf, 4, k);
          AppendS(S.s, buf, k);
          IF S.nextCh = ":" THEN (*prefix*)
            Texts.Scan(S); Texts.Scan(S);
            IF S.class = Texts.Name THEN
              buf[k-1] := ORD("."); AppendS(S.s, buf, k);
              Texts.Write(W, ":"); Texts.WriteString(W, S.s)
            END
          END ;
          Texts.WriteString(W, " receiving"); Texts.Append(Oberon.Log, W.buf);
          retry := 20;
          REPEAT Send(SND, k, buf); ReceiveHead(T0); DEC(retry); UNTIL head1.valid OR (retry = 0);
          IF head1.typ = 0 THEN
            F := Files.New(S.s);
            IF F # NIL THEN
              ReceiveData(F, done);
              IF done THEN Files.Register(F); reply(0) ELSE reply(3); end := 0 END
            ELSE reply(3); Send(NAK, 0, dmy)
            END
          ELSIF head1.typ = NAK THEN reply(4)
          ELSIF head1.typ = NPR THEN reply(2); end := 0
          ELSE reply(5); end := 0
          END ;
          Texts.Scan(S)
        END
      ELSE reply(1)
      END
    END
  END ReceiveFiles;

  PROCEDURE SendMsg*;
    VAR i: INTEGER; ch: CHAR;
      S!: Texts.Scanner;
      msg: ARRAY 64 OF BYTE;
  BEGIN GetPar1(S);
    IF S.class = Texts.Name THEN
      FindPartner(S.s, i);
      IF i = 0 THEN
        Texts.Read(S, ch);
        WHILE (ch >= " ") & (i < 64) DO
          msg[i] := ORD(ch); INC(i); Texts.Read(S, ch)
        END ;
        Send(MSG, i, msg); ReceiveHead(T0);
        IF head1.typ # ACK THEN reply(3) END
      ELSE reply(1)
      END
    END
  END SendMsg;

  PROCEDURE doGetTime*(partner: ARRAY OF CHAR);
    VAR dt, res, retry: INTEGER;
  BEGIN Texts.WriteString(W, "setting time");
    FindPartner(partner, res);
    IF res = 0 THEN retry := 10;
      REPEAT Send(TRQ, 0, dmy); ReceiveHead(T0); DEC(retry) UNTIL head1.valid OR (retry = 0);
      IF head1.typ = TIM THEN
        PickQ(dt); Oberon.SetClock(dt); reply(0)
      END
    ELSE reply(1)
    END
  END doGetTime;

  PROCEDURE GetTime*;
    VAR S!: Texts.Scanner;
  BEGIN GetPar1(S);
    IF S.class = Texts.Name THEN doGetTime(S.s) END
  END GetTime;

  PROCEDURE StartServer*;
    VAR S!: Texts.Scanner;
      end: INTEGER;
      channel: BYTE;
  BEGIN GetPar1(S);
    IF S.class = Texts.Int THEN
      channel := S.i; GetPar(S, end);
      IF (Texts.Pos(S) < end) & (S.class = Texts.Name) THEN
        protected := TRUE; partner[0] := 0X; SCC.Start(channel, S.s);
        Oberon.Remove(Server); Oberon.Install(Server);
        Texts.WriteString(W, " Server started as "); Texts.WriteString(W, S.s);
        Texts.WriteString(W, " on channel "); Texts.WriteInt(W, channel, 1);
        Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
      END
    END
  END StartServer;

  PROCEDURE Unprotect*;
  BEGIN protected := FALSE
  END Unprotect;

  PROCEDURE WProtect*;
  BEGIN protected := TRUE
  END WProtect;

  PROCEDURE doReset*(channel: BYTE; name: ARRAY OF CHAR);
  BEGIN
    SCC.Start(channel, name);
    Texts.WriteString(W, " Client set as "); Texts.WriteString(W, name);
    Texts.WriteString(W, " on channel "); Texts.WriteInt(W, channel, 1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END doReset;

  PROCEDURE Reset*;
    VAR S!: Texts.Scanner;
      end: INTEGER;
      channel: BYTE;
  BEGIN GetPar1(S);
    IF S.class = Texts.Int THEN
      channel := S.i; GetPar(S, end);
      IF (Texts.Pos(S) < end) & (S.class IN {Texts.Name, Texts.String}) THEN
        doReset(channel, S.s)
      END
    END
  END Reset;

  PROCEDURE StopServer*;
  BEGIN Oberon.Remove(Server); Texts.WriteString(W, " Server stopped");
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END StopServer;

  PROCEDURE tstFindPartner*;
    VAR S!: Texts.Scanner;
      res: INTEGER;
  BEGIN GetPar1(S);
    IF S.class = Texts.Name THEN
      FindPartner(S.s, res);
      Texts.WriteString(W, "tstFindPartner:"); Texts.WriteInt(W, res, 1);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END tstFindPartner;

  PROCEDURE SCCStatus*;
  BEGIN
    Texts.WriteString(W, "SCC.Available() ");
    Texts.WriteInt(W, SCC.Available(), 1);
    Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END SCCStatus;

  PROCEDURE SCCPrintConfig*;
  BEGIN SCC.PrintConfig(W); Texts.Append(Oberon.Log, W.buf)
  END SCCPrintConfig;

  PROCEDURE SCCShowRxPacket*;
  BEGIN SCC.ShowRxPacket(W); Texts.Append(Oberon.Log, W.buf)
  END SCCShowRxPacket;

  PROCEDURE ShowHead1*;
  BEGIN Texts.WriteString(W, "Valid "); Texts.WriteInt(W, ORD(head1.valid), 1);
    Texts.WriteString(W, ", type "); Texts.WriteInt(W, head1.typ, 1);
    Texts.WriteString(W, ", length "); Texts.WriteInt(W, head1.len, 1);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END ShowHead1;

BEGIN Texts.OpenWriter(W); Server := Oberon.NewTask(Serve, 500);
  SCC.SetWriter(W, Oberon.Log)
END Net.
