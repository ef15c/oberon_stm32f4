MODULE testFS2; (*test of filesystem v2*)
  IMPORT SYSTEM, BSP, Kernel, FileSystem, FileDir2, Files2, FileDir, Files, Texts, Oberon, Log := SystemLog;

  CONST
    SectorSize*   = FileDir2.SectorSize;

  TYPE
    Sector* = ARRAY SectorSize OF BYTE;

  VAR W: Texts.Writer; nof: INTEGER;

  PROCEDURE p*;
    VAR dp: FileDir2.DirPage;
  BEGIN
    Log.DebugInt("FileHeaderPage size", SYSTEM.SIZE(FileDir2.FileHeader), 1);
    Log.DebugInt("File header size", SYSTEM.SIZE(FileDir2.FileHeader), 1);
    Log.DebugInt("LEN(e)", LEN(dp.e), 1);
    Log.DebugInt("DirPgSize", FileDir2.DirPgSize, 1);
  END p;

  PROCEDURE CreateFS100000H*;
  BEGIN FileDir2.CreateFS(100000H)
  END CreateFS100000H;

  PROCEDURE InitFS100000H*;
  BEGIN Files2.Init(100000H); Oberon.AddPostMarkCallback(Files2.RestoreList)
  END InitFS100000H;

  PROCEDURE DeInitFS100000H*;
  BEGIN Oberon.DelPostMarkCallback(Files2.RestoreList);
    BSP.ledsOnOff({}, {4})
  END DeInitFS100000H;

  PROCEDURE CopyFile*;
    VAR S!: Texts.Scanner;
      F2!: Files2.File; R2!: Files2.Rider;
      F!: Files.File; R!: Files.Rider; v: CHAR;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Log.DebugString("copy name", S.s);
      F := Files.Old(S.s); Files.Set(R, F, 0);
      F2 := Files2.New(S.s); Files2.Set(R2, F2, 0);
      Files.Read(R, v);
      WHILE ~R.eof DO Files2.Write(R2, v); Files.Read(R, v) END;
      Files2.Register(F2)
    END
  END CopyFile;

  PROCEDURE DeleteFile*;
    VAR S!: Texts.Scanner; res: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Log.DebugString("delete name", S.s); Files2.Delete(S.s, res);
      IF res # 0 THEN Log.DebugInt("res", res, 1); END
    END
  END DeleteFile;

  PROCEDURE RenameFile*;
    VAR S!: Texts.Scanner; res: INTEGER; from: FileDir2.FileName;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN from := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN
        Log.DebugString("rename file", from); Log.DebugString("to", S.s);
        Files2.Rename(from, S.s, res);
        IF res # 0 THEN Log.DebugInt("res", res, 1); END
      END
    END
  END RenameFile;

  PROCEDURE MakeCopyCommand(name: FileDir.FileName; adr: INTEGER; VAR cont: BOOLEAN);
    VAR header: INTEGER; fshd!: FileSystem.FSHeader;
  BEGIN INC(nof); fshd := Files2.fshd; FileDir2.Search(fshd, name, header);
    IF header = 0 THEN (*the file does not exist on OFS2*)
      Texts.WriteString(W, "testFS2.CopyFile "); Texts.WriteString(W, name);
      Texts.Write(W, "~"); Texts.WriteLn(W)
    END;
    IF Kernel.allocated > 3000000 THEN
      Log.DebugInt("aborted, nb of files enumerated", nof, 1); cont := FALSE
    END
  END MakeCopyCommand;

  PROCEDURE CopyAllList*;
  BEGIN nof := 0;
    FileDir.Enumerate("", MakeCopyCommand); Texts.Append(Oberon.Log, W.buf);
    Oberon.Collect(0)
  END CopyAllList;

  PROCEDURE CompareFile*;
    VAR S!: Texts.Scanner;
      F2!: Files2.File; R2!: Files2.Rider;
      F!: Files.File; R!: Files.Rider; v, v2: CHAR;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      F := Files.Old(S.s); F2 := Files2.Old(S.s);
      IF F2 = NIL THEN (*the file does not exist on OFS2*)
        IF F # NIL THEN
          Texts.WriteString(W, "testFS2.CopyFile "); Texts.WriteString(W, S.s);
          Texts.Write(W, "~"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
        ELSE Log.DebugString("doesn't exist anywhere", S.s)
        END
      ELSIF F # NIL THEN Files.Set(R, F, 0); Files2.Set(R2, F2, 0);
        Files.Read(R, v); Files2.Read(R2, v2);
        WHILE ~R.eof & ~R2.eof & (v = v2) DO Files2.Read(R2, v2); Files.Read(R, v) END;
        IF (ORD(R.eof ) # ORD(R2.eof)) OR (v # v2) THEN Log.DebugString("different", S.s) END
      ELSE
        Texts.WriteString(W, "testFS2.DeleteFile "); Texts.WriteString(W, S.s);
        Texts.Write(W, "~"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
      END
    END;
  END CompareFile;

  PROCEDURE MaxLevel*;
    VAR max: INTEGER;

    PROCEDURE ml(dpg0, cur: INTEGER; VAR max: INTEGER);
      VAR a: FileDir2.DirPage; fshd!: FileSystem.FSHeader; i: INTEGER;
    BEGIN
      fshd := Files2.fshd; IF cur > max THEN max := cur END;
      FileSystem.GetSector(fshd, dpg0, a); ASSERT(a.mark = FileDir2.DirMark);
      IF a.p0 # 0 THEN
        ml(a.p0, cur + 1, max); (*visit left descendant*)
        FOR i := 0 TO a.m - 1 DO ml(a.e[i].p, cur + 1, max) END (*visit all right descendants*)
     END
   END ml;

  BEGIN max := 0; ml(FileDir2.DirRootAdr, 1, max); Log.DebugInt("max level", max, 1)
  END MaxLevel;

  PROCEDURE Usage*;
  BEGIN Log.DebugInt("Nb of allocated sectors", Files2.fshd.NofSectors, 1)
  END Usage;

BEGIN Texts.OpenWriter(W);
END testFS2.

OM4P.Compile FileSystem.Mod/s FileDir2.Mod/s Files2.Mod/s testFS2.Mod/s~
testFS2.DeInitFS100000H~
System.Free testFS2 Files2 FileDir2 FileSystem~
testFS2.p
FileHeaderPage size = 2048
File header size = 352
LEN(e) = 40
DirPgSize = 40
testFS2.InitFS100000H
testFS2.CopyAllList
testFS2.CopyFile OM4P.efb~
testFS2.CompareFile OM4P.efb~
testFS2.MaxLevel~
testFS2.DeleteFile usbhpipes.c.Bak~
testFS2.RenameFile usbhpipes.c.Bak usbhpipes.c.Bak.Bak
testFS2.RenameFile usbhpipes.c.Bak.Bak usbhpipes.c.Bak
testFS2.Usage

Oberon.Batch
testFS2.InitFS100000H
~
testFS2.CreateFS100000H

OM4Tool.DecObj testFS2.m4c
