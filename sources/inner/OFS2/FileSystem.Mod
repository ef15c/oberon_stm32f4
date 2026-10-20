MODULE FileSystem; (*CS 17.10.26*)
  (*File system Types and low level procedures*)
  IMPORT SYSTEM, SDCard, Kernel, Log := SystemLog;

  CONST
    SectorSize*   = 2048;
    mapsize = 10000H; (*64K sectors, 64* 1024*SectorSize bytes*)
    FnLength*    = 32;
    SecTabSize*   = 64;
    ExTabSize*   = 12;
    DirRootAdr*  = 29;

  TYPE 
    Sector* = ARRAY SectorSize OF BYTE;

  (*filesystem*)
    StorageInfo = POINTER TO StorageInfoDesc;
    StorageInfoDesc = RECORD
      map: ARRAY mapsize DIV 32 OF SET
    END;

    FSHeaderPersistent* = RECORD
      mark*: INTEGER;
      FS_OFFSET*: INTEGER;
      version*: BYTE
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

    FileHeaderData* =
      RECORD (*first page of each file on disk*)
        mark*: INTEGER;
        name*: FileName;
        aleng*, bleng*, date*: INTEGER;
        ext*:  ExtensionTable;
        sec*: SectorTable;
      END ;

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

    DirPageData* = RECORD(DirPageHeader)
      e*:  ARRAY (SectorSize - SYSTEM.SIZE(DirPageHeader)) DIV  SYSTEM.SIZE(DirEntry) DIV 4*4 OF DirEntry
    END;

(* ---------- Disk storage management ----------*)

  PROCEDURE MarkSector*(VAR fshd: FSHeader; sec29: INTEGER);
    VAR sec: INTEGER;
  BEGIN sec := sec29 DIV 29; ASSERT(sec29 = sec*29);
    INCL(fshd.sector.map[sec DIV 32], sec MOD 32); INC(fshd.NofSectors);
  END MarkSector;

  PROCEDURE InitSecMap*(VAR fshd: FSHeader);
    CONST NofReservedSectors = (Kernel.BootReservedSize + SectorSize - 1) DIV SectorSize + 2;
    VAR i, r: INTEGER;
  BEGIN NEW(fshd.sector); fshd.NofSectors := 0; i := 0;
    WHILE i < NofReservedSectors DIV 32 DO fshd.sector.map[i] := {0 .. 31}; INC(i) END;
    r := NofReservedSectors MOD 32; IF r > 0 THEN fshd.sector.map[i] := {0 .. r}; INC(i) END;
    WHILE i < mapsize DIV 32 DO fshd.sector.map[i] := {}; INC(i) END
  END InitSecMap;

  (*Exported procedures:  CreateFS, GetSector, Init, FreeSector, AllocSector, PutSector*)

(* ----- initialization ----- *)

  PROCEDURE GetSector*(VAR fshd: FSHeader; src29: INTEGER; VAR dst: Sector);
    VAR src: INTEGER;
  BEGIN src := src29 DIV 29; ASSERT(src29 = src*29);
    src := src * (SectorSize DIV SDCard.BLOCKSIZE) + fshd.FS_OFFSET;
    SDCard.Read(src, SYSTEM.ADR(dst), SectorSize DIV SDCard.BLOCKSIZE)
  END GetSector;

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
