MODULE testRWNum;
  IMPORT Files, FilesEx := FilesEx2, Texts, TextsEx := TextsEx2, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE write*;
    VAR f!: Files.File; r!: Files.Rider; v: INTEGER;
  BEGIN f := Files.New("testRWNum.data");
    Files.Set(r, f, 0);
    Files.WriteNum(r, -1000); Files.WriteNum(r, -1); Files.WriteNum(r, 0); Files.WriteNum(r, 1); Files.WriteNum(r, 1000);
    v := 1000; v := v*v*v*v; Texts.WriteString(W, "v = "); Texts.WriteInt(W, v, 1); Texts.WriteLn(W);
    Files.WriteNum(r, v);  
    Files.Register(f);

    Files.Set(r, f, 0); Files.ReadNum(r, v);
    WHILE ~r.eof DO Texts.WriteString(W, "v = "); Texts.WriteInt(W, v, 1); Texts.WriteLn(W); Files.ReadNum(r, v) END;
    Texts.Append(Oberon.Log, W.buf)    
  END write;

  PROCEDURE writeL*;
    VAR f!: Files.File; r!: Files.Rider; v: LONGINT;
  BEGIN f := Files.New("testRWNum.data");
    Files.Set(r, f, 0);
    FilesEx.WriteLongNum(r, -1000); FilesEx.WriteLongNum(r, -1); FilesEx.WriteLongNum(r, 0); FilesEx.WriteLongNum(r, 1); FilesEx.WriteLongNum(r, 1000);
    v := 1000; v := v*v*v*v; Texts.WriteString(W, "v = "); TextsEx.WriteLongInt(W, v, 1); Texts.WriteLn(W);
    FilesEx.WriteLongNum(r, v);  
    Files.Register(f);

    Files.Set(r, f, 0); FilesEx.ReadLongNum(r, v);
    WHILE ~r.eof DO Texts.WriteString(W, "v = "); TextsEx.WriteLongInt(W, v, 1); Texts.WriteLn(W); FilesEx.ReadLongNum(r, v) END;
    Texts.Append(Oberon.Log, W.buf)    
  END writeL;

  PROCEDURE run*;
    VAR f!: Files.File; r!: Files.Rider; v: INTEGER;
  BEGIN f := Files.Old("testRWNum.data");
    Files.Set(r, f, 0); Files.ReadNum(r, v);
    WHILE ~r.eof DO Texts.WriteString(W, "v = "); Texts.WriteInt(W, v, 1); Texts.WriteLn(W); Files.ReadNum(r, v) END;
    Texts.Append(Oberon.Log, W.buf)    
  END run;

  PROCEDURE runL*;
    VAR f!: Files.File; r!: Files.Rider; v: LONGINT;
  BEGIN f := Files.Old("testRWNum.data");
    Files.Set(r, f, 0); FilesEx.ReadLongNum(r, v);
    WHILE ~r.eof DO Texts.WriteString(W, "v = "); TextsEx.WriteLongInt(W, v, 1); Texts.WriteLn(W); FilesEx.ReadLongNum(r, v) END;
    Texts.Append(Oberon.Log, W.buf)    
  END runL;

BEGIN Texts.OpenWriter(W);  
END testRWNum.

Stage 1

OM4P.Compile TextsEx2.Mod FilesEx2.Mod testRWNum.Mod/s ~ System.Free testRWNum FilesEx2 TextsEx2 ~ 
testRWNum.write
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = -727379968
testRWNum.writeL
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = -727379968
testRWNum.run
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = -727379968
testRWNum.runL
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = -727379968

Stage 2

OM4P2.Compile TextsEx2.Mod FilesEx2.Mod testRWNum.Mod/s ~ System.Free testRWNum FilesEx2 TextsEx2 ~ 
testRWNum.write
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = -727379968
testRWNum.writeL
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = 1000000000000
testRWNum.run
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = -777434592
testRWNum.runL
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = 1000000000000

OM4Tool.DecObj testRWNum.m4c
