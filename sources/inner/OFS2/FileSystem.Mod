MODULE FileSystem; (*CS 17.10.26*)
  (*File system Types and low level procedures*)
  IMPORT SYSTEM, SDCard, Kernel, Log := SystemLog;

  CONST
    SectorSize*   = 2048;
    mapsize = 10000H; (*64K sectors, 64* 1024*SectorSize bytes*)
    FnLength*    = 32;
    SecTabSize*   = 64;
    ExTabSize*   = 12;
    IndexSize*   = SectorSize DIV 4;
    DirRootAdr*  = 29;

    FSMark = 97A1EAD9H;
    DirMark*    = 9B1EA38DH;
    HeaderMark* = 9BA71D86H;

  TYPE 
    Sector* = ARRAY SectorSize OF BYTE;

  (*filesystem*)
    StorageInfo = POINTER TO StorageInfoDesc;
    StorageInfoDesc = RECORD
      map: ARRAY mapsize DIV 32 OF SET
    END;

    FSHeaderPersistent = RECORD
      mark: INTEGER;
      FS_OFFSET: INTEGER;
      version: BYTE
    END;

    FSHeader* = RECORD(FSHeaderPersistent)
      sector: StorageInfo;
      NofSectors*: INTEGER;
    END;

    FSHeaderPage* = RECORD(FSHeader)
      fill: ARRAY SectorSize - SYSTEM.SIZE(FSHeader) OF BYTE
    END;

    FSHdP* = POINTER TO FSHeaderPage;

  (*file*)
    DiskAdr*      = INTEGER;
    FileName*       = ARRAY FnLength OF CHAR;
    SectorTable*    = ARRAY SecTabSize OF DiskAdr;
    ExtensionTable* = ARRAY ExTabSize OF DiskAdr;

    FileHeader* =
      RECORD (*first page of each file on disk*)
        mark*: INTEGER;
        name*: FileName;
        aleng*, bleng*, date*: INTEGER;
        ext*:  ExtensionTable;
        sec*: SectorTable;
      END ;

    FileHeaderPage* = RECORD(FileHeader)
      fill: ARRAY SectorSize - SYSTEM.SIZE(FileHeader) OF BYTE
    END;

    FileHd* = POINTER TO FileHeaderPage;
    IndexSector* = ARRAY IndexSize OF DiskAdr;
    DataSector* = ARRAY SectorSize OF BYTE;

 (*directory*)
    DirEntry* =  (*B-tree node*)
      RECORD
        name*: FileName;
        adr*: DiskAdr; (*sec no of file header*)
        date*, size*: INTEGER;
        p*:    DiskAdr  (*sec no of descendant in directory*)
      END ;

    DirPageHeader* = RECORD
      mark*:  INTEGER;
      m*:     INTEGER;
      p0*:    DiskAdr  (*sec no of left descendant in directory*)
    END;

    DirPageData = RECORD(DirPageHeader)
        e*:  ARRAY (SectorSize - SYSTEM.SIZE(DirPageHeader)) DIV  SYSTEM.SIZE(DirEntry) DIV 4*4 OF DirEntry
    END;

    DirPage*  = RECORD(DirPageData)
      fill:  ARRAY SectorSize - SYSTEM.SIZE(DirPageData) OF BYTE;
    END ;

(*    DirPg* = POINTER TO DirPage;*)

(* ---------- Disk storage management ----------*)

  PROCEDURE MarkSector*(VAR fshd: FSHeader; sec29: INTEGER);
    VAR sec: INTEGER;
  BEGIN sec := sec29 DIV 29; ASSERT(sec29 = sec*29);
    INCL(fshd.sector.map[sec DIV 32], sec MOD 32); INC(fshd.NofSectors);
  END MarkSector;

  PROCEDURE InitSecMap(VAR fshd: FSHeader);
    CONST NofReservedSectors = (Kernel.BootReservedSize + SectorSize - 1) DIV SectorSize + 2;
    VAR i, r: INTEGER;
  BEGIN NEW(fshd.sector); fshd.NofSectors := 0; i := 0;
    WHILE i < NofReservedSectors DIV 32 DO fshd.sector.map[i] := {0 .. 31}; INC(i) END;
    r := NofReservedSectors MOD 32; IF r > 0 THEN fshd.sector.map[i] := {0 .. r}; INC(i) END;
    WHILE i < mapsize DIV 32 DO fshd.sector.map[i] := {}; INC(i) END
  END InitSecMap;

  (*Exported procedures:  CreateFS, GetSector, Init, FreeSector, AllocSector, PutSector*)

(* ----- initialization ----- *)

  PROCEDURE CreateFS*(fssec: INTEGER);
    VAR fshsp!: FSHeaderPage; (*header mapped on sector fssec*)
      root: DirPage;
  BEGIN ASSERT(fssec >= 100000H); CLEAR(fshsp); fshsp.mark := 97A1EAD9H; fshsp.FS_OFFSET := fssec; fshsp.version := 2;
    SDCard.Write(fssec, SYSTEM.ADR(fshsp), SectorSize DIV SDCard.BLOCKSIZE);
    CLEAR(root); root.mark := DirMark;
    SDCard.Write(fssec + 4, SYSTEM.ADR(root), SectorSize DIV SDCard.BLOCKSIZE);
  END  CreateFS;

  PROCEDURE GetSector*(VAR fshd: FSHeader; src29: INTEGER; VAR dst: Sector);
    VAR src: INTEGER;
  BEGIN src := src29 DIV 29; ASSERT(src29 = src*29);
    src := src * (SectorSize DIV SDCard.BLOCKSIZE) + fshd.FS_OFFSET;
    SDCard.Read(src, SYSTEM.ADR(dst), SectorSize DIV SDCard.BLOCKSIZE)
  END GetSector;

  PROCEDURE Init*(VAR fshd: FSHeader; fssec: INTEGER);
    VAR k: INTEGER;
      A: ARRAY 2000 OF DiskAdr;
      fshdp!: FSHeaderPage; (*header mapped on sector fssec*)

    PROCEDURE MarkSectors(VAR fshd: FSHeader; VAR A: ARRAY OF DiskAdr; k: INTEGER);
      VAR L, R, i, j, n: INTEGER; x: DiskAdr;
        fhd: FileHeaderPage;
        B: IndexSector;

      PROCEDURE sift(VAR fshd: FSHeader; VAR A: ARRAY OF DiskAdr; L, R: INTEGER);
        VAR i, j: INTEGER; x: DiskAdr;
      BEGIN j := L; x := A[j];
        REPEAT i := j; j := 2*j + 1;
          IF (j+1 < R) & (A[j] < A[j+1]) THEN INC(j) END ;
          IF (j < R) & (x <= A[j]) THEN A[i] := A[j] END
        UNTIL (j >= R) OR (x > A[j]);
        A[i] := x
      END sift;

    BEGIN L := k DIV 2; R := k; (*heapsort*)
      WHILE L > 0 DO DEC(L); sift(fshd, A, L, R) END ;
      WHILE R > 0 DO
        DEC(R); x := A[0]; A[0] := A[R]; A[R] := x; sift(fshd, A, L, R)
      END ;
      WHILE L < k DO
        GetSector(fshd, A[L], fhd); ASSERT(fhd.mark = HeaderMark);
        IF fhd.aleng < SecTabSize THEN j := fhd.aleng + 1;
          REPEAT DEC(j); MarkSector(fshd, fhd.sec[j]) UNTIL j = 0
        ELSE j := SecTabSize;
          REPEAT DEC(j); MarkSector(fshd, fhd.sec[j]) UNTIL j = 0;
          n := (fhd.aleng - SecTabSize) DIV IndexSize; i := 0;
          WHILE i <= n DO
            MarkSector(fshd, fhd.ext[i]);
            GetSector(fshd, fhd.ext[i], B); (*index sector*)
            IF i < n THEN j := IndexSize ELSE j := (fhd.aleng - SecTabSize) MOD IndexSize + 1 END ;
            REPEAT DEC(j); MarkSector(fshd, B[j]) UNTIL j = 0;
            INC(i)
          END
        END ;
        INC(L)
      END
    END MarkSectors;

    PROCEDURE TraverseDir(VAR fshd: FSHeader; VAR A: ARRAY OF DiskAdr; VAR k: INTEGER; dpg: DiskAdr);
      VAR i: INTEGER; a: DirPage;
    BEGIN IF dpg # 0 THEN
        GetSector(fshd, dpg, a); ASSERT(a.mark = DirMark); MarkSector(fshd, dpg); i := 0;
        WHILE i < a.m DO
          A[k] := a.e[i].adr; INC(k); INC(i);
          IF k = 2000 THEN MarkSectors(fshd, A, k); k := 0 END
        END ;
        TraverseDir(fshd, A, k, a.p0); i := 0;
        WHILE i < a.m DO TraverseDir(fshd, A, k, a.e[i].p); INC(i) END
      END
    END TraverseDir;
  BEGIN SDCard.Read(fssec, SYSTEM.ADR(fshdp), SectorSize DIV SDCard.BLOCKSIZE);
    ASSERT(fshdp.mark = FSMark); ASSERT(fshdp.version = 2);
    CLEAR(fshd); SYSTEM.COPY(SYSTEM.ADR(fshdp), SYSTEM.ADR(fshd), SYSTEM.SIZE(FSHeaderPersistent) DIV 4);
    InitSecMap(fshd);
    k := 0; TraverseDir(fshd, A, k, DirRootAdr); MarkSectors(fshd, A, k)
  END Init; 

 PROCEDURE FreeSector*(VAR fshd: FSHeader; sec29: INTEGER);
    VAR sec: INTEGER;
  BEGIN sec := sec29 DIV 29; ASSERT(sec29 = sec*29);
    EXCL(fshd.sector.map[sec DIV 32], sec MOD 32); DEC(fshd.NofSectors)
  END FreeSector;

  PROCEDURE AllocSector*(VAR fshd: FSHeader; hint29: INTEGER; VAR sec29: INTEGER);
    VAR hint, s: INTEGER;
  BEGIN (*find free sector, starting after hint*)
    hint := hint29 DIV 29; ASSERT(hint29 = hint*29); s := hint;
    REPEAT INC(s);
      IF s >= mapsize THEN s := 1 END ;
    UNTIL ~(s MOD 32 IN fshd.sector.map[s DIV 32]) OR (s = hint);
    ASSERT (~(s MOD 32 IN fshd.sector.map[s DIV 32]));
    INCL(fshd.sector.map[s DIV 32], s MOD 32); INC(fshd.NofSectors); sec29 := s * 29
  END AllocSector;

  PROCEDURE PutSector*(VAR fshd: FSHeader; dst29: INTEGER; VAR src: Sector);
    VAR dst: INTEGER;
  BEGIN dst := dst29 DIV 29; ASSERT(dst29 = dst*29);
    dst := dst * (SectorSize DIV SDCard.BLOCKSIZE) + fshd.FS_OFFSET;
    SDCard.Write(dst, SYSTEM.ADR(src), SectorSize DIV SDCard.BLOCKSIZE);
  END PutSector;

END FileSystem.
