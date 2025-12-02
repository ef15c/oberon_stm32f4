MODULE testRWNum;
  IMPORT Files, FilesEx, Texts, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE write*;
    VAR f!: Files.File; r!: Files.Rider; v: INTEGER;
  BEGIN f := Files.New("testRWNum.data");
    Files.Set(r, f, 0);
    Files.WriteNum(r, -1000); Files.WriteNum(r, -1); Files.WriteNum(r, 0); Files.WriteNum(r, 1); Files.WriteNum(r, 1000);
    v := 1000; v := v*v*v*v; Files.WriteNum(r, v); Files.WriteNum(r, 0D0000000H);
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
    v := 1000; v := v*v*v*v; FilesEx.WriteLongNum(r, v); FilesEx.WriteLongNum(r, 0D0000000H);
    Files.Register(f);

    Files.Set(r, f, 0); FilesEx.ReadLongNum(r, v);
    WHILE ~r.eof DO Texts.WriteString(W, "v = "); Texts.WriteInt(W, v, 1); Texts.WriteLn(W); FilesEx.ReadLongNum(r, v) END;
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
    WHILE ~r.eof DO Texts.WriteString(W, "v = "); Texts.WriteInt(W, v, 1); Texts.WriteLn(W); FilesEx.ReadLongNum(r, v) END;
    Texts.Append(Oberon.Log, W.buf)    
  END runL;

BEGIN Texts.OpenWriter(W);  
END testRWNum.

OM4P.Compile testRWNum.Mod/s ~
System.Free testRWNum LongInt testScan SystemLog ~ 
testRWNum.write
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = -727379968
v = -805306368
testRWNum.writeL
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = 1000000000000
v = 3489660928
testRWNum.run
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = -777434592
v = -805306368
testRWNum.runL
v = -1000
v = -1
v = 0
v = 1
v = 1000
v = 1000000000000
v = 3489660928

OM4Tool.DecObj testRWNum.m4c
