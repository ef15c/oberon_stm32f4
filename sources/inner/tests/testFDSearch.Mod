MODULE testFDSearch; (*CS 01/01/2024*)
  IMPORT SYSTEM, FileDir;

(*Debug FileDir.Search*)  
PROCEDURE test*;
  VAR A: INTEGER; namebuf: FileDir.FileName;
    i: INTEGER;
BEGIN
  LED(10H);
  namebuf := "Oberon10.Scn.Fnt";
  i := 0; WHILE (i < FileDir.FnLength) & (namebuf[i] # 0X) DO INC(i) END;
  WHILE i < FileDir.FnLength DO namebuf[i] := 0X; INC(i) END;
  FileDir.Search(namebuf, A);
  ASSERT(A # 0);
END test;

END testFDSearch.
