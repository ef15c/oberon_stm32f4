MODULE FileDir2;   (*NW 12.1.86 / 23.8.90 / 15.8.2013 CS 17.03.24 / 17.10.26*)
  IMPORT SYSTEM, FileSystem, Kernel;
  (*File Directory is a B-tree with its root page at DirRootAdr.
    Each entry contains a file name, a modification date, a size and the disk address of the file's head sector*)

  CONST
    HeaderSize* = SYSTEM.SIZE(FileSystem.FileHeader);
    DirPgSize* = (FileSystem.SectorSize - SYSTEM.SIZE(FileSystem.DirPageHeader)) DIV  SYSTEM.SIZE(FileSystem.DirEntry) DIV 4*4;
    N = DirPgSize DIV 2;

  TYPE
    EntryHandler*   = PROCEDURE (name: FileSystem.FileName; sec: FileSystem.DiskAdr; VAR continue: BOOLEAN);

  (*Exported procedures: Search, Insert, Delete, Enumerate, Init*)

   PROCEDURE Search*(VAR fshd: FileSystem.FSHeader; name: FileSystem.FileName; VAR A: FileSystem.DiskAdr);
    VAR i, L, R: INTEGER; dadr: FileSystem.DiskAdr;
      a: FileSystem.DirPage;
  BEGIN dadr := FileSystem.DirRootAdr; A := 0;
    REPEAT FileSystem.GetSector(fshd, dadr, a); ASSERT(a.mark = FileSystem.DirMark);
      L := 0; R := a.m; (*binary search*)
      WHILE L < R DO
        i := (L+R) DIV 2;
        IF name <= a.e[i].name THEN R := i ELSE L := i+1 END
      END ;
      IF (R < a.m) & (name = a.e[R].name) THEN A := a.e[R].adr (*found*)
      ELSIF R = 0 THEN dadr := a.p0
      ELSE dadr := a.e[R-1].p
      END ;
    UNTIL (dadr = 0) OR (A # 0)
  END Search;

  PROCEDURE insert(VAR fshd: FileSystem.FSHeader; 
                   name: FileSystem.FileName;
                   dpg0:  FileSystem.DiskAdr;
                   VAR h: BOOLEAN;
                   VAR v: FileSystem.DirEntry;
                   fad:     FileSystem.DiskAdr;
                   date,
                   size: INTEGER);
    (*h = "tree has become higher and v is ascending element"*)
    VAR ch: CHAR;
      i, j, L, R: INTEGER;
      dpg1: FileSystem.DiskAdr;
      u: FileSystem.DirEntry;
      a!: FileSystem.DirPg;

  BEGIN NEW(a); (*~h*) FileSystem.GetSector(fshd, dpg0, a^); ASSERT(a.mark = FileSystem.DirMark);
    L := 0; R := a.m; (*binary search*)
    WHILE L < R DO
      i := (L+R) DIV 2;
      IF name <= a.e[i].name THEN R := i ELSE L := i+1 END
    END ;
    IF (R < a.m) & (name = a.e[R].name) THEN
      a.e[R].adr := fad; a.e[R].date := date; a.e[R].size := size; FileSystem.PutSector(fshd, dpg0, a^)  (*replace*)
    ELSE (*not on this page*)
      IF R = 0 THEN dpg1 := a.p0 ELSE dpg1 := a.e[R-1].p END ;
      IF dpg1 = 0 THEN (*not in tree, insert*)
        u.adr := fad; u.date := date; u.size := size; u.p := 0; h := TRUE; j := 0;
        REPEAT ch := name[j]; u.name[j] := ch; INC(j)
        UNTIL ch = 0X;
        WHILE j < FileSystem.FnLength DO u.name[j] := 0X; INC(j) END ;
      ELSE
        insert(fshd, name, dpg1, h, u, fad, date, size)
      END ;
      IF h THEN (*insert u to the left of e[R]*)
        IF a.m < DirPgSize THEN
          h := FALSE; i := a.m;
          WHILE i > R DO DEC(i); a.e[i+1] := a.e[i] END ;
          a.e[R] := u; INC(a.m)
        ELSE (*split page and assign the middle element to v*)
          a.m := N; a.mark := FileSystem.DirMark;
          IF R < N THEN (*insert in left half*)
            v := a.e[N-1]; i := N-1;
            WHILE i > R DO DEC(i); a.e[i+1] := a.e[i] END ;
            a.e[R] := u; FileSystem.PutSector(fshd, dpg0, a^);
            FileSystem.AllocSector(fshd, dpg0, dpg0); i := 0;
            WHILE i < N DO a.e[i] := a.e[i+N]; INC(i) END
          ELSE (*insert in right half*)
            FileSystem.PutSector(fshd, dpg0, a^);
            FileSystem.AllocSector(fshd, dpg0, dpg0); DEC(R, N); i := 0;
            IF R = 0 THEN v := u
            ELSE v := a.e[N];
              WHILE i < R-1 DO a.e[i] := a.e[N+1+i]; INC(i) END ;
              a.e[i] := u; INC(i)
            END ;
            WHILE i < N DO a.e[i] := a.e[N+i]; INC(i) END
          END ;
          a.p0 := v.p; v.p := dpg0
        END ;
        FileSystem.PutSector(fshd, dpg0, a^)
      END
    END
  END insert;

  PROCEDURE Insert*(VAR fshd: FileSystem.FSHeader; name: FileSystem.FileName; fad: FileSystem.DiskAdr; date, size: INTEGER);
    VAR  oldroot: FileSystem.DiskAdr;
      h: BOOLEAN; U: FileSystem.DirEntry;
      a: FileSystem.DirPage;
  BEGIN h := FALSE; Kernel.DisableAbortHandler;
    insert(fshd, name, FileSystem.DirRootAdr, h, U, fad, date, size);
    IF h THEN (*root overflow*)
      FileSystem.GetSector(fshd, FileSystem.DirRootAdr, a); ASSERT(a.mark = FileSystem.DirMark);
      FileSystem.AllocSector(fshd, FileSystem.DirRootAdr, oldroot); FileSystem.PutSector(fshd, oldroot, a);
      a.mark := FileSystem.DirMark; a.m := 1; a.p0 := oldroot; a.e[0] := U;
      FileSystem.PutSector(fshd, FileSystem.DirRootAdr, a)
    END; Kernel.EnableAbortHandler
  END Insert;


  PROCEDURE underflow(VAR fshd: FileSystem.FSHeader; VAR c: FileSystem.DirPage;  (*ancestor page*)
                      dpg0:  FileSystem.DiskAdr;
                      s:     INTEGER;  (*insertion point in c*)
                      VAR h: BOOLEAN); (*c undersize*)
    VAR i, k: INTEGER;
        dpg1: FileSystem.DiskAdr;
        a, b: FileSystem.DirPage;  (*a := underflowing page, b := neighbouring page*)
  BEGIN FileSystem.GetSector(fshd, dpg0, a); ASSERT(a.mark = FileSystem.DirMark);
    (*h & a.m = N-1 & dpg0 = c.e[s-1].p*)
    IF s < c.m THEN (*b := page to the right of a*)
      dpg1 := c.e[s].p; FileSystem.GetSector(fshd, dpg1, b); ASSERT(b.mark = FileSystem.DirMark);
      k := (b.m-(N-1)) DIV 2; (*k = no. of items available on page b*)
      a.e[N-1] := c.e[s]; a.e[N-1].p := b.p0;
      IF k > 0 THEN
        (*move k-1 items from b to a, one to c*) i := 0;
        WHILE i < k-1 DO a.e[i+N] := b.e[i]; INC(i) END ;
        c.e[s] := b.e[i]; b.p0 := c.e[s].p;
        c.e[s].p := dpg1; b.m := b.m - k; i := 0;
        WHILE i < b.m DO b.e[i] := b.e[i+k]; INC(i) END ;
        FileSystem.PutSector(fshd, dpg1, b); a.m := N-1+k; h := FALSE
      ELSE (*merge pages a and b, discard b*) i := 0;
        WHILE i < N DO a.e[i+N] := b.e[i]; INC(i) END ;
        i := s; DEC(c.m);
        WHILE i < c.m DO c.e[i] := c.e[i+1]; INC(i) END ;
        a.m := 2*N; h := c.m < N
      END ;
      FileSystem.PutSector(fshd, dpg0, a)
    ELSE (*b := page to the left of a*) DEC(s);
      IF s = 0 THEN dpg1 := c.p0 ELSE dpg1 := c.e[s-1].p END ;
      FileSystem.GetSector(fshd, dpg1, b); ASSERT(b.mark = FileSystem.DirMark);
      k := (b.m-(N-1)) DIV 2; (*k = no. of items available on page b*)
      IF k > 0 THEN
        i := N-1;
        WHILE i > 0 DO DEC(i); a.e[i+k] := a.e[i] END ;
        i := k-1; a.e[i] := c.e[s]; a.e[i].p := a.p0;
        (*move k-1 items from b to a, one to c*) b.m := b.m - k;
        WHILE i > 0 DO DEC(i); a.e[i] := b.e[i+b.m+1] END ;
        c.e[s] := b.e[b.m]; a.p0 := c.e[s].p;
        c.e[s].p := dpg0; a.m := N-1+k; h := FALSE;
        FileSystem.PutSector(fshd, dpg0, a)
      ELSE (*merge pages a and b, discard a*)
        c.e[s].p := a.p0; b.e[N] := c.e[s]; i := 0;
        WHILE i < N-1 DO b.e[i+(N+1)] := a.e[i]; INC(i) END ;
        b.m := 2*N; DEC(c.m); h := c.m < N
      END ;
      FileSystem.PutSector(fshd, dpg1, b)
    END
  END underflow;

  PROCEDURE delete(VAR fshd: FileSystem.FSHeader; name: FileSystem.FileName;
                   dpg0: FileSystem.DiskAdr;
                   VAR h: BOOLEAN;
                   VAR fad: FileSystem.DiskAdr);
  (*search and delete entry with key name; if a page underflow arises,
    balance with adjacent page or merge; h := "page dpg0 is undersize"*)

    VAR i, L, R: INTEGER;
      dpg1: FileSystem.DiskAdr;
      a!: FileSystem.DirPg;

    PROCEDURE del(VAR fshd: FileSystem.FSHeader; VAR a: FileSystem.DirPage; R: INTEGER; dpg1: FileSystem.DiskAdr; VAR h: BOOLEAN);
      VAR dpg2: FileSystem.DiskAdr;  (*global: a, R*)
          b!: FileSystem.DirPg;
    BEGIN NEW(b); FileSystem.GetSector(fshd, dpg1, b^); ASSERT(b.mark = FileSystem.DirMark); dpg2 := b.e[b.m-1].p;
      IF dpg2 # 0 THEN del(fshd, a, R, dpg2, h);
        IF h THEN underflow(fshd, b^, dpg2, b.m, h); FileSystem.PutSector(fshd, dpg1, b^) END
      ELSE
        b.e[b.m-1].p := a.e[R].p; a.e[R] := b.e[b.m-1];
        DEC(b.m); h := b.m < N; FileSystem.PutSector(fshd, dpg1, b^)
      END
    END del;

  BEGIN NEW(a); (*~h*) FileSystem.GetSector(fshd, dpg0, a^); ASSERT(a.mark = FileSystem.DirMark);
    L := 0; R := a.m; (*binary search*)
    WHILE L < R DO
      i := (L+R) DIV 2;
      IF name <= a.e[i].name THEN R := i ELSE L := i+1 END
    END ;
    IF R = 0 THEN dpg1 := a.p0 ELSE dpg1 := a.e[R-1].p END ;
    IF (R < a.m) & (name = a.e[R].name) THEN
      (*found, now delete*) fad := a.e[R].adr;
      IF dpg1 = 0 THEN  (*a is a leaf page*)
        DEC(a.m); h := a.m < N; i := R;
        WHILE i < a.m DO a.e[i] := a.e[i+1]; INC(i) END
      ELSE del(fshd, a^, R, dpg1, h);
        IF h THEN underflow(fshd, a^, dpg1, R, h) END
      END ;
      FileSystem.PutSector(fshd, dpg0, a^)
    ELSIF dpg1 # 0 THEN
      delete(fshd, name, dpg1, h, fad);
      IF h THEN underflow(fshd, a^, dpg1, R, h); FileSystem.PutSector(fshd, dpg0, a^) END
    ELSE (*not in tree*) fad := 0
    END
  END delete;

  PROCEDURE Delete*(VAR fshd: FileSystem.FSHeader; name: FileSystem.FileName; VAR fad: FileSystem.DiskAdr);
    VAR h: BOOLEAN; newroot: FileSystem.DiskAdr;
      a: FileSystem.DirPage;
  BEGIN h := FALSE; Kernel.DisableAbortHandler;
    delete(fshd, name, FileSystem.DirRootAdr, h, fad);
    IF h THEN (*root underflow*)
      FileSystem.GetSector(fshd, FileSystem.DirRootAdr, a); ASSERT(a.mark = FileSystem.DirMark);
      IF (a.m = 0) & (a.p0 # 0) THEN
        newroot := a.p0; FileSystem.GetSector(fshd, newroot, a); ASSERT(a.mark = FileSystem.DirMark);
        FileSystem.PutSector(fshd, FileSystem.DirRootAdr, a) (*discard newroot*)
      END
    END; Kernel.EnableAbortHandler
  END Delete;

  PROCEDURE enumerate(VAR fshd: FileSystem.FSHeader;
                      prefix:   ARRAY OF CHAR;
                      dpg:          FileSystem.DiskAdr;
                      proc:         EntryHandler;
                      VAR continue: BOOLEAN);
    VAR i, j: INTEGER; pfx, nmx: CHAR;
      dpg1: FileSystem.DiskAdr; a!: FileSystem.DirPg;
  BEGIN NEW(a); FileSystem.GetSector(fshd, dpg, a^); ASSERT(a.mark = FileSystem.DirMark); i := 0;
    WHILE (i < a.m) & continue DO
      j := 0;
      REPEAT pfx := prefix[j]; nmx := a.e[i].name[j]; INC(j)
      UNTIL (nmx # pfx) OR (pfx = 0X);
      IF nmx >= pfx THEN
        IF i = 0 THEN dpg1 := a.p0 ELSE dpg1 := a.e[i-1].p END ;
        IF dpg1 # 0 THEN enumerate(fshd, prefix, dpg1, proc, continue) END ;
        IF pfx = 0X THEN
          IF continue THEN proc(a.e[i].name, a.e[i].adr, continue) END
        ELSE continue := FALSE
        END
      END ;
      INC(i)
    END ;
    IF continue & (i > 0) & (a.e[i-1].p # 0) THEN
      enumerate(fshd, prefix, a.e[i-1].p, proc, continue)
    END
  END enumerate;

  PROCEDURE Enumerate*(VAR fshd: FileSystem.FSHeader; prefix: ARRAY OF CHAR; proc: EntryHandler);
    VAR b: BOOLEAN;
  BEGIN b := TRUE; enumerate(fshd, prefix, FileSystem.DirRootAdr, proc, b)
  END Enumerate;

END FileDir2.
