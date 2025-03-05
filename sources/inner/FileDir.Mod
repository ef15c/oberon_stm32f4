MODULE FileDir;   (*NW 12.1.86 / 23.8.90 / 15.8.2013 CS 17/03/24*)
  IMPORT Kernel;

  (*File Directory is a B-tree with its root page at DirRootAdr.
    Each entry contains a file name and the disk address of the file's head sector*)

  CONST FnLength*    = 32;
        SecTabSize*   = 64;
        ExTabSize*   = 12;
        SectorSize*   = Kernel.SectorLength;
        IndexSize*   = SectorSize DIV 4;
        HeaderSize*  = 352;
        DirRootAdr*  = 29;
        DirPgSize*   = (SectorSize - 12) DIV 40 DIV 4*4 (*24*);
        N = DirPgSize DIV 2;
        DirMark*    = 9B1EA38DH;
        HeaderMark* = 9BA71D86H;
        FillerSize = SectorSize - 12 - DirPgSize*40 (*52*);

  TYPE DiskAdr      = INTEGER;
    FileName*       = ARRAY FnLength OF CHAR;
    SectorTable*    = ARRAY SecTabSize OF DiskAdr;
    ExtensionTable* = ARRAY ExTabSize OF DiskAdr;
    EntryHandler*   = PROCEDURE (name: FileName; sec: DiskAdr; VAR continue: BOOLEAN);

    FileHeader* =
      RECORD (*first page of each file on disk*)
        mark*: INTEGER;
        name*: FileName;
        aleng*, bleng*, date*: INTEGER;
        ext*:  ExtensionTable;
        sec*: SectorTable;
        fill: ARRAY SectorSize - HeaderSize OF BYTE;
      END ;

    FileHd* = POINTER TO FileHeader;
    IndexSector* = ARRAY IndexSize OF DiskAdr;
    DataSector* = ARRAY SectorSize OF BYTE;

    DirEntry* =  (*B-tree node*)
      RECORD
        name*: FileName;
        adr*:  DiskAdr; (*sec no of file header*)
        p*:    DiskAdr  (*sec no of descendant in directory*)
      END ;

    DirPage*  =
      RECORD mark*:  INTEGER;
        m*:     INTEGER;
        p0*:    DiskAdr;  (*sec no of left descendant in directory*)
        fill:  ARRAY FillerSize OF BYTE;
        e*:  ARRAY DirPgSize OF DirEntry
      END ;

      DirPg* = POINTER TO DirPage;

  VAR hd: FileHd;

  (*Exported procedures: Search, Insert, Delete, Enumerate, Init*)

  PROCEDURE Search*(name: FileName; VAR A: DiskAdr);
    VAR i, L, R: INTEGER; dadr: DiskAdr;
      a!: DirPg;
  BEGIN NEW(a); dadr := DirRootAdr; A := 0;
    REPEAT Kernel.GetSector(dadr, a^); ASSERT(a.mark = DirMark);
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

  PROCEDURE insert(name: FileName;
                   dpg0:  DiskAdr;
                   VAR h: BOOLEAN;
                   VAR v: DirEntry;
                   fad:     DiskAdr);
    (*h = "tree has become higher and v is ascending element"*)
    VAR ch: CHAR;
      i, j, L, R: INTEGER;
      dpg1: DiskAdr;
      u: DirEntry;
      a!: DirPg;

  BEGIN NEW(a); (*~h*) Kernel.GetSector(dpg0, a^); ASSERT(a.mark = DirMark);
    L := 0; R := a.m; (*binary search*)
    WHILE L < R DO
      i := (L+R) DIV 2;
      IF name <= a.e[i].name THEN R := i ELSE L := i+1 END
    END ;
    IF (R < a.m) & (name = a.e[R].name) THEN
      a.e[R].adr := fad; Kernel.PutSector(dpg0, a^)  (*replace*)
    ELSE (*not on this page*)
      IF R = 0 THEN dpg1 := a.p0 ELSE dpg1 := a.e[R-1].p END ;
      IF dpg1 = 0 THEN (*not in tree, insert*)
        u.adr := fad; u.p := 0; h := TRUE; j := 0;
        REPEAT ch := name[j]; u.name[j] := ch; INC(j)
        UNTIL ch = 0X;
        WHILE j < FnLength DO u.name[j] := 0X; INC(j) END ;
      ELSE
        insert(name, dpg1, h, u, fad)
      END ;
      IF h THEN (*insert u to the left of e[R]*)
        IF a.m < DirPgSize THEN
          h := FALSE; i := a.m;
          WHILE i > R DO DEC(i); a.e[i+1] := a.e[i] END ;
          a.e[R] := u; INC(a.m)
        ELSE (*split page and assign the middle element to v*)
          a.m := N; a.mark := DirMark;
          IF R < N THEN (*insert in left half*)
            v := a.e[N-1]; i := N-1;
            WHILE i > R DO DEC(i); a.e[i+1] := a.e[i] END ;
            a.e[R] := u; Kernel.PutSector(dpg0, a^);
            Kernel.AllocSector(dpg0, dpg0); i := 0;
            WHILE i < N DO a.e[i] := a.e[i+N]; INC(i) END
          ELSE (*insert in right half*)
            Kernel.PutSector(dpg0, a^);
            Kernel.AllocSector(dpg0, dpg0); DEC(R, N); i := 0;
            IF R = 0 THEN v := u
            ELSE v := a.e[N];
              WHILE i < R-1 DO a.e[i] := a.e[N+1+i]; INC(i) END ;
              a.e[i] := u; INC(i)
            END ;
            WHILE i < N DO a.e[i] := a.e[N+i]; INC(i) END
          END ;
          a.p0 := v.p; v.p := dpg0
        END ;
        Kernel.PutSector(dpg0, a^)
      END
    END
  END insert;

  PROCEDURE Insert*(name: FileName; fad: DiskAdr);
    VAR  oldroot: DiskAdr;
      h: BOOLEAN; U: DirEntry;
      a!: DirPg;
  BEGIN NEW(a); h := FALSE; Kernel.DisableAbortHandler;
    insert(name, DirRootAdr, h, U, fad);
    IF h THEN (*root overflow*)
      Kernel.GetSector(DirRootAdr, a^); ASSERT(a.mark = DirMark);
      Kernel.AllocSector(DirRootAdr, oldroot); Kernel.PutSector(oldroot, a^);
      a.mark := DirMark; a.m := 1; a.p0 := oldroot; a.e[0] := U;
      Kernel.PutSector(DirRootAdr, a^)
    END; Kernel.EnableAbortHandler
  END Insert;


  PROCEDURE underflow(VAR c: DirPage;  (*ancestor page*)
                      dpg0:  DiskAdr;
                      s:     INTEGER;  (*insertion point in c*)
                      VAR h: BOOLEAN); (*c undersize*)
    VAR i, k: INTEGER;
        dpg1: DiskAdr;
        a!, b!: DirPg;  (*a := underflowing page, b := neighbouring page*)
  BEGIN NEW(a); NEW(b); Kernel.GetSector(dpg0, a^); ASSERT(a.mark = DirMark);
    (*h & a.m = N-1 & dpg0 = c.e[s-1].p*)
    IF s < c.m THEN (*b := page to the right of a*)
      dpg1 := c.e[s].p; Kernel.GetSector(dpg1, b^); ASSERT(b.mark = DirMark);
      k := (b.m-N+1) DIV 2; (*k = no. of items available on page b*)
      a.e[N-1] := c.e[s]; a.e[N-1].p := b.p0;
      IF k > 0 THEN
        (*move k-1 items from b to a, one to c*) i := 0;
        WHILE i < k-1 DO a.e[i+N] := b.e[i]; INC(i) END ;
        c.e[s] := b.e[i]; b.p0 := c.e[s].p;
        c.e[s].p := dpg1; b.m := b.m - k; i := 0;
        WHILE i < b.m DO b.e[i] := b.e[i+k]; INC(i) END ;
        Kernel.PutSector(dpg1, b^); a.m := N-1+k; h := FALSE
      ELSE (*merge pages a and b, discard b*) i := 0;
        WHILE i < N DO a.e[i+N] := b.e[i]; INC(i) END ;
        i := s; DEC(c.m);
        WHILE i < c.m DO c.e[i] := c.e[i+1]; INC(i) END ;
        a.m := 2*N; h := c.m < N
      END ;
      Kernel.PutSector(dpg0, a^)
    ELSE (*b := page to the left of a*) DEC(s);
      IF s = 0 THEN dpg1 := c.p0 ELSE dpg1 := c.e[s-1].p END ;
      Kernel.GetSector(dpg1, b^); ASSERT(b.mark = DirMark);
      k := (b.m-N+1) DIV 2; (*k = no. of items available on page b*)
      IF k > 0 THEN
        i := N-1;
        WHILE i > 0 DO DEC(i); a.e[i+k] := a.e[i] END ;
        i := k-1; a.e[i] := c.e[s]; a.e[i].p := a.p0;
        (*move k-1 items from b to a, one to c*) b.m := b.m - k;
        WHILE i > 0 DO DEC(i); a.e[i] := b.e[i+b.m+1] END ;
        c.e[s] := b.e[b.m]; a.p0 := c.e[s].p;
        c.e[s].p := dpg0; a.m := N-1+k; h := FALSE;
        Kernel.PutSector(dpg0, a^)
      ELSE (*merge pages a and b, discard a*)
        c.e[s].p := a.p0; b.e[N] := c.e[s]; i := 0;
        WHILE i < N-1 DO b.e[i+N+1] := a.e[i]; INC(i) END ;
        b.m := 2*N; DEC(c.m); h := c.m < N
      END ;
      Kernel.PutSector(dpg1, b^)
    END
  END underflow;

  PROCEDURE delete(name: FileName;
                   dpg0: DiskAdr;
                   VAR h: BOOLEAN;
                   VAR fad: DiskAdr);
  (*search and delete entry with key name; if a page underflow arises,
    balance with adjacent page or merge; h := "page dpg0 is undersize"*)

    VAR i, L, R: INTEGER;
      dpg1: DiskAdr;
      a!: DirPg;

    PROCEDURE del(VAR a: DirPage; R: INTEGER; dpg1: DiskAdr; VAR h: BOOLEAN);
      VAR dpg2: DiskAdr;  (*global: a, R*)
          b!: DirPg;
    BEGIN NEW(b); Kernel.GetSector(dpg1, b^); ASSERT(b.mark = DirMark); dpg2 := b.e[b.m-1].p;
      IF dpg2 # 0 THEN del(a, R, dpg2, h);
        IF h THEN underflow(b^, dpg2, b.m, h); Kernel.PutSector(dpg1, b^) END
      ELSE
        b.e[b.m-1].p := a.e[R].p; a.e[R] := b.e[b.m-1];
        DEC(b.m); h := b.m < N; Kernel.PutSector(dpg1, b^)
      END
    END del;

  BEGIN NEW(a); (*~h*) Kernel.GetSector(dpg0, a^); ASSERT(a.mark = DirMark);
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
      ELSE del(a^, R, dpg1, h);
        IF h THEN underflow(a^, dpg1, R, h) END
      END ;
      Kernel.PutSector(dpg0, a^)
    ELSIF dpg1 # 0 THEN
      delete(name, dpg1, h, fad);
      IF h THEN underflow(a^, dpg1, R, h); Kernel.PutSector(dpg0, a^) END
    ELSE (*not in tree*) fad := 0
    END
  END delete;

  PROCEDURE Delete*(name: FileName; VAR fad: DiskAdr);
    VAR h: BOOLEAN; newroot: DiskAdr;
      a!: DirPg;
  BEGIN NEW(a); h := FALSE; Kernel.DisableAbortHandler;
    delete(name, DirRootAdr, h, fad);
    IF h THEN (*root underflow*)
      Kernel.GetSector(DirRootAdr, a^); ASSERT(a.mark = DirMark);
      IF (a.m = 0) & (a.p0 # 0) THEN
        newroot := a.p0; Kernel.GetSector(newroot, a^); ASSERT(a.mark = DirMark);
        Kernel.PutSector(DirRootAdr, a^) (*discard newroot*)
      END
    END; Kernel.EnableAbortHandler
  END Delete;

  PROCEDURE enumerate(prefix:   ARRAY OF CHAR;
                      dpg:          DiskAdr;
                      proc:         EntryHandler;
                      VAR continue: BOOLEAN);
    VAR i, j: INTEGER; pfx, nmx: CHAR;
      dpg1: DiskAdr; a!: DirPg;
  BEGIN NEW(a); Kernel.GetSector(dpg, a^); ASSERT(a.mark = DirMark); i := 0;
    WHILE (i < a.m) & continue DO
      j := 0;
      REPEAT pfx := prefix[j]; nmx := a.e[i].name[j]; INC(j)
      UNTIL (nmx # pfx) OR (pfx = 0X);
      IF nmx >= pfx THEN
        IF i = 0 THEN dpg1 := a.p0 ELSE dpg1 := a.e[i-1].p END ;
        IF dpg1 # 0 THEN enumerate(prefix, dpg1, proc, continue) END ;
        IF pfx = 0X THEN
          IF continue THEN proc(a.e[i].name, a.e[i].adr, continue) END
        ELSE continue := FALSE
        END
      END ;
      INC(i)
    END ;
    IF continue & (i > 0) & (a.e[i-1].p # 0) THEN
      enumerate(prefix, a.e[i-1].p, proc, continue)
    END
  END enumerate;

  PROCEDURE Enumerate*(prefix: ARRAY OF CHAR; proc: EntryHandler);
    VAR b: BOOLEAN;
  BEGIN b := TRUE; enumerate(prefix, DirRootAdr, proc, b)
  END Enumerate;

(* ----- initialization ----- *)

PROCEDURE Init;
    VAR k: INTEGER;
        A: ARRAY 2000 OF DiskAdr;

    PROCEDURE MarkSectors(VAR A: ARRAY OF DiskAdr; k: INTEGER);
      VAR L, R, i, j, n: INTEGER; x: DiskAdr;
        B: IndexSector;

      PROCEDURE sift(VAR A: ARRAY OF DiskAdr; L, R: INTEGER);
        VAR i, j: INTEGER; x: DiskAdr;
      BEGIN j := L; x := A[j];
        REPEAT i := j; j := 2*j + 1;
          IF (j+1 < R) & (A[j] < A[j+1]) THEN INC(j) END ;
          IF (j < R) & (x <= A[j]) THEN A[i] := A[j] END
        UNTIL (j >= R) OR (x > A[j]);
        A[i] := x
      END sift;

    BEGIN L := k DIV 2; R := k; (*heapsort*)
      WHILE L > 0 DO DEC(L); sift(A, L, R) END ;
      WHILE R > 0 DO
        DEC(R); x := A[0]; A[0] := A[R]; A[R] := x; sift(A, L, R)
      END ;
      WHILE L < k DO
        Kernel.GetSector(A[L], hd^); ASSERT(hd.mark = HeaderMark);
        IF hd.aleng < SecTabSize THEN j := hd.aleng + 1;
          REPEAT DEC(j); Kernel.MarkSector(hd.sec[j]) UNTIL j = 0
        ELSE j := SecTabSize;
          REPEAT DEC(j); Kernel.MarkSector(hd.sec[j]) UNTIL j = 0;
          n := (hd.aleng - SecTabSize) DIV IndexSize; i := 0;
          WHILE i <= n DO
            Kernel.MarkSector(hd.ext[i]);
            Kernel.GetSector(hd.ext[i], B); (*index sector*)
            IF i < n THEN j := IndexSize ELSE j := (hd.aleng - SecTabSize) MOD IndexSize + 1 END ;
            REPEAT DEC(j); Kernel.MarkSector(B[j]) UNTIL j = 0;
            INC(i)
          END
        END ;
        INC(L)
      END
    END MarkSectors;

    PROCEDURE TraverseDir(VAR A: ARRAY OF DiskAdr; VAR k: INTEGER; dpg: DiskAdr);
      VAR i: INTEGER; a!: DirPg;
    BEGIN IF dpg # 0 THEN NEW(a);
        Kernel.GetSector(dpg, a^); ASSERT(a.mark = DirMark); Kernel.MarkSector(dpg); i := 0;
        WHILE i < a.m DO
          A[k] := a.e[i].adr; INC(k); INC(i);
          IF k = 2000 THEN MarkSectors(A, k); k := 0 END
        END ;
        TraverseDir(A, k, a.p0); i := 0;
        WHILE i < a.m DO TraverseDir(A, k, a.e[i].p); INC(i) END
      END
    END TraverseDir;

  BEGIN NEW(hd); k := 0; TraverseDir(A, k, DirRootAdr); MarkSectors(A, k); hd := NIL;
  END Init; 

BEGIN Init
END FileDir.

OM4Tool.DecObj FileDir.m4c
decode FileDir.m4c
FileDir 486CC119   2   6972
imports:
	Kernel FC60F94D
type descriptors
 00000500 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000040 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000500 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data     4
strings

code
commands:
entries
 00001A8E 00000000 00000014 00000028 00000000 000006DC 000012AC 00001572
pointer refs
     0
fixP =  0000195A
fixV =  00001A76
fixC =  00001A4C
fixT =  00000000
entry =  00001A8E
 00000000	     B085	SUB SP SP #20
 00000002	     B403	PUSH R0 R1
 00000004	     B500	PUSH LR
 00000006	     A807	ADD R0 SP #28
 00000008	 10000004	MOV R1 lower 16-bits base(0), next at  00000000
 0000000C	 00000028	MOVT R1 higher 16-bits const + 40
 00000010	     DF00	SVC #0
 00000012	     201D	MOVS R0 #29
 00000014	     9006	STR R0 [ SP + 24 ]
 00000016	     2000	MOVS R0 #0
 00000018	     9902	LDR R1 [ SP + 8 ]
 0000001A	     6008	STR R0 [  R1 + 0 ]
 0000001C	     9806	LDR R0 [ SP + 24 ]
 0000001E	     9907	LDR R1 [ SP + 28 ]
 00000020	     2900	CMP R1 #0
 00000022	     BF08	IT EQ
 00000024	 EC010344	TrapEQ 4 at pos 2100
 00000028	 11300014	BL Mod(  1) proc(19)
 0000002C	     9807	LDR R0 [ SP + 28 ]
 0000002E	     2800	CMP R0 #0
 00000030	     BF08	IT EQ
 00000032	 EC010434	TrapEQ 4 at pos 2115
 00000036	     6800	LDR R0 [ R0 + 0 ]
 00000038	 F24A318D	MOV R1 #41869
 0000003C	 F6C9311E	MOVT R1 #39710
 00000040	     4288	CMP R0 R1
 00000042	     BF18	IT NE
 00000044	 EC0104F7	TrapNE 7 at pos 2127
 00000048	     2000	MOVS R0 #0
 0000004A	     9004	STR R0 [ SP + 16 ]
 0000004C	     9807	LDR R0 [ SP + 28 ]
 0000004E	     2800	CMP R0 #0
 00000050	     BF08	IT EQ
 00000052	 EC010664	TrapEQ 4 at pos 2150
 00000056	     6840	LDR R0 [ R0 + 4 ]
 00000058	     9005	STR R0 [ SP + 20 ]
 0000005A	     9804	LDR R0 [ SP + 16 ]
 0000005C	     9905	LDR R1 [ SP + 20 ]
 0000005E	     4288	CMP R0 R1
 00000060	 F2808026	BGE #76, goes to  000000B0
 00000064	     9804	LDR R0 [ SP + 16 ]
 00000066	     9905	LDR R1 [ SP + 20 ]
 00000068	     1840	ADDS R0 R0 R1
 0000006A	     1040	ASRS R0 R0 #1
 0000006C	     9003	STR R0 [ SP + 12 ]
 0000006E	     9807	LDR R0 [ SP + 28 ]
 00000070	     2800	CMP R0 #0
 00000072	     BF08	IT EQ
 00000074	 EC0113F4	TrapEQ 4 at pos 2239
 00000078	     9903	LDR R1 [ SP + 12 ]
 0000007A	     2918	CMP R1 #24
 0000007C	     BF28	IT CS
 0000007E	 EC011421	TrapCS 1 at pos 2242
 00000082	     2228	MOVS R2 #40
 00000084	     4351	MULS R1 R2 R1
 00000086	     1840	ADDS R0 R0 R1
 00000088	     9901	LDR R1 [ SP + 4 ]
 0000008A	     3040	ADDS R0 R0 #64
 0000008C	 F8112B01	LDRB R2 [  R1 ] + 1
 00000090	 F8103B01	LDRB R3 [  R0 ] + 1
 00000094	     429A	CMP R2 R3
 00000096	     D101	BNE #2, goes to  0000009C
 00000098	     2A00	CMP R2 #0
 0000009A	     D1F7	BNE #-18, goes to  0000008C
 0000009C	 F3008004	BGT #8, goes to  000000A8
 000000A0	     9803	LDR R0 [ SP + 12 ]
 000000A2	     9005	STR R0 [ SP + 20 ]
 000000A4	 F000B803	B #6, goes to  000000AE
 000000A8	     9803	LDR R0 [ SP + 12 ]
 000000AA	     1C40	ADDS R0 R0 #1
 000000AC	     9004	STR R0 [ SP + 16 ]
 000000AE	     E7D4	B #-88, goes to  0000005A
 000000B0	     9807	LDR R0 [ SP + 28 ]
 000000B2	     2800	CMP R0 #0
 000000B4	     BF08	IT EQ
 000000B6	 EC012034	TrapEQ 4 at pos 2307
 000000BA	     9905	LDR R1 [ SP + 20 ]
 000000BC	     6840	LDR R0 [ R0 + 4 ]
 000000BE	     4281	CMP R1 R0
 000000C0	 F280802B	BGE #86, goes to  0000011A
 000000C4	     9807	LDR R0 [ SP + 28 ]
 000000C6	     2800	CMP R0 #0
 000000C8	     BF08	IT EQ
 000000CA	 EC012124	TrapEQ 4 at pos 2322
 000000CE	     9905	LDR R1 [ SP + 20 ]
 000000D0	     2918	CMP R1 #24
 000000D2	     BF28	IT CS
 000000D4	 EC012151	TrapCS 1 at pos 2325
 000000D8	     2228	MOVS R2 #40
 000000DA	     4351	MULS R1 R2 R1
 000000DC	     1840	ADDS R0 R0 R1
 000000DE	     9901	LDR R1 [ SP + 4 ]
 000000E0	     3040	ADDS R0 R0 #64
 000000E2	 F8112B01	LDRB R2 [  R1 ] + 1
 000000E6	 F8103B01	LDRB R3 [  R0 ] + 1
 000000EA	     429A	CMP R2 R3
 000000EC	     D101	BNE #2, goes to  000000F2
 000000EE	     2A00	CMP R2 #0
 000000F0	     D1F7	BNE #-18, goes to  000000E2
 000000F2	 F0408012	BNE #36, goes to  0000011A
 000000F6	     9807	LDR R0 [ SP + 28 ]
 000000F8	     2800	CMP R0 #0
 000000FA	     BF08	IT EQ
 000000FC	 EC012294	TrapEQ 4 at pos 2345
 00000100	     9905	LDR R1 [ SP + 20 ]
 00000102	     2918	CMP R1 #24
 00000104	     BF28	IT CS
 00000106	 EC0122C1	TrapCS 1 at pos 2348
 0000010A	     2228	MOVS R2 #40
 0000010C	     4351	MULS R1 R2 R1
 0000010E	     1840	ADDS R0 R0 R1
 00000110	     6E00	LDR R0 [ R0 + 96 ]
 00000112	     9902	LDR R1 [ SP + 8 ]
 00000114	     6008	STR R0 [  R1 + 0 ]
 00000116	 F000B81D	B #58, goes to  00000154
 0000011A	     9805	LDR R0 [ SP + 20 ]
 0000011C	     2800	CMP R0 #0
 0000011E	 F0408009	BNE #18, goes to  00000134
 00000122	     9807	LDR R0 [ SP + 28 ]
 00000124	     2800	CMP R0 #0
 00000126	     BF08	IT EQ
 00000128	 EC0125E4	TrapEQ 4 at pos 2398
 0000012C	     6880	LDR R0 [ R0 + 8 ]
 0000012E	     9006	STR R0 [ SP + 24 ]
 00000130	 F000B810	B #32, goes to  00000154
 00000134	     9807	LDR R0 [ SP + 28 ]
 00000136	     2800	CMP R0 #0
 00000138	     BF08	IT EQ
 0000013A	 EC012754	TrapEQ 4 at pos 2421
 0000013E	     9905	LDR R1 [ SP + 20 ]
 00000140	     1E49	SUBS R1 R1 #1
 00000142	     2918	CMP R1 #24
 00000144	     BF28	IT CS
 00000146	 EC0127A1	TrapCS 1 at pos 2426
 0000014A	     2228	MOVS R2 #40
 0000014C	     4351	MULS R1 R2 R1
 0000014E	     1840	ADDS R0 R0 R1
 00000150	     6E40	LDR R0 [ R0 + 100 ]
 00000152	     9006	STR R0 [ SP + 24 ]
 00000154	     9806	LDR R0 [ SP + 24 ]
 00000156	     2800	CMP R0 #0
 00000158	 F0008005	BEQ #10, goes to  00000166
 0000015C	     9802	LDR R0 [ SP + 8 ]
 0000015E	     6800	LDR R0 [ R0 + 0 ]
 00000160	     2800	CMP R0 #0
 00000162	 F43FAF5B	BEQ #-330, goes to  0000001C
 00000166	 F85DEB04	LDR LR [ SP ] + 4
 0000016A	     B007	ADD SP SP #28
 0000016C	     4770	BX LR
 0000016E	     B091	SUB SP SP #68
 00000170	     B43F	PUSH R0 R1 R2 R3 R4 R5
 00000172	     B500	PUSH LR
 00000174	     A817	ADD R0 SP #92
 00000176	 100000B7	MOV R1 lower 16-bits base(0), next at  00000008
 0000017A	 00000028	MOVT R1 higher 16-bits const + 40
 0000017E	     DF00	SVC #0
 00000180	     9802	LDR R0 [ SP + 8 ]
 00000182	     9917	LDR R1 [ SP + 92 ]
 00000184	     2900	CMP R1 #0
 00000186	     BF08	IT EQ
 00000188	 EC016434	TrapEQ 4 at pos 2883
 0000018C	 113000B2	BL Mod(  1) proc(19)
 00000190	     9817	LDR R0 [ SP + 92 ]
 00000192	     2800	CMP R0 #0
 00000194	     BF08	IT EQ
 00000196	 EC016524	TrapEQ 4 at pos 2898
 0000019A	     6800	LDR R0 [ R0 + 0 ]
 0000019C	 F24A318D	MOV R1 #41869
 000001A0	 F6C9311E	MOVT R1 #39710
 000001A4	     4288	CMP R0 R1
 000001A6	     BF18	IT NE
 000001A8	 EC0165E7	TrapNE 7 at pos 2910
 000001AC	     2000	MOVS R0 #0
 000001AE	     900A	STR R0 [ SP + 40 ]
 000001B0	     9817	LDR R0 [ SP + 92 ]
 000001B2	     2800	CMP R0 #0
 000001B4	     BF08	IT EQ
 000001B6	 EC016734	TrapEQ 4 at pos 2931
 000001BA	     6840	LDR R0 [ R0 + 4 ]
 000001BC	     900B	STR R0 [ SP + 44 ]
 000001BE	     980A	LDR R0 [ SP + 40 ]
 000001C0	     990B	LDR R1 [ SP + 44 ]
 000001C2	     4288	CMP R0 R1
 000001C4	 F2808026	BGE #76, goes to  00000214
 000001C8	     980A	LDR R0 [ SP + 40 ]
 000001CA	     990B	LDR R1 [ SP + 44 ]
 000001CC	     1840	ADDS R0 R0 R1
 000001CE	     1040	ASRS R0 R0 #1
 000001D0	     9008	STR R0 [ SP + 32 ]
 000001D2	     9817	LDR R0 [ SP + 92 ]
 000001D4	     2800	CMP R0 #0
 000001D6	     BF08	IT EQ
 000001D8	 EC017464	TrapEQ 4 at pos 3014
 000001DC	     9908	LDR R1 [ SP + 32 ]
 000001DE	     2918	CMP R1 #24
 000001E0	     BF28	IT CS
 000001E2	 EC017491	TrapCS 1 at pos 3017
 000001E6	     2228	MOVS R2 #40
 000001E8	     4351	MULS R1 R2 R1
 000001EA	     1840	ADDS R0 R0 R1
 000001EC	     9901	LDR R1 [ SP + 4 ]
 000001EE	     3040	ADDS R0 R0 #64
 000001F0	 F8112B01	LDRB R2 [  R1 ] + 1
 000001F4	 F8103B01	LDRB R3 [  R0 ] + 1
 000001F8	     429A	CMP R2 R3
 000001FA	     D101	BNE #2, goes to  00000200
 000001FC	     2A00	CMP R2 #0
 000001FE	     D1F7	BNE #-18, goes to  000001F0
 00000200	 F3008004	BGT #8, goes to  0000020C
 00000204	     9808	LDR R0 [ SP + 32 ]
 00000206	     900B	STR R0 [ SP + 44 ]
 00000208	 F000B803	B #6, goes to  00000212
 0000020C	     9808	LDR R0 [ SP + 32 ]
 0000020E	     1C40	ADDS R0 R0 #1
 00000210	     900A	STR R0 [ SP + 40 ]
 00000212	     E7D4	B #-88, goes to  000001BE
 00000214	     9817	LDR R0 [ SP + 92 ]
 00000216	     2800	CMP R0 #0
 00000218	     BF08	IT EQ
 0000021A	 EC018064	TrapEQ 4 at pos 3078
 0000021E	     990B	LDR R1 [ SP + 44 ]
 00000220	     6840	LDR R0 [ R0 + 4 ]
 00000222	     4281	CMP R1 R0
 00000224	 F2808032	BGE #100, goes to  0000028C
 00000228	     9817	LDR R0 [ SP + 92 ]
 0000022A	     2800	CMP R0 #0
 0000022C	     BF08	IT EQ
 0000022E	 EC018154	TrapEQ 4 at pos 3093
 00000232	     990B	LDR R1 [ SP + 44 ]
 00000234	     2918	CMP R1 #24
 00000236	     BF28	IT CS
 00000238	 EC018181	TrapCS 1 at pos 3096
 0000023C	     2228	MOVS R2 #40
 0000023E	     4351	MULS R1 R2 R1
 00000240	     1840	ADDS R0 R0 R1
 00000242	     9901	LDR R1 [ SP + 4 ]
 00000244	     3040	ADDS R0 R0 #64
 00000246	 F8112B01	LDRB R2 [  R1 ] + 1
 0000024A	 F8103B01	LDRB R3 [  R0 ] + 1
 0000024E	     429A	CMP R2 R3
 00000250	     D101	BNE #2, goes to  00000256
 00000252	     2A00	CMP R2 #0
 00000254	     D1F7	BNE #-18, goes to  00000246
 00000256	 F0408019	BNE #50, goes to  0000028C
 0000025A	     9817	LDR R0 [ SP + 92 ]
 0000025C	     2800	CMP R0 #0
 0000025E	     BF08	IT EQ
 00000260	 EC0182D4	TrapEQ 4 at pos 3117
 00000264	     990B	LDR R1 [ SP + 44 ]
 00000266	     2918	CMP R1 #24
 00000268	     BF28	IT CS
 0000026A	 EC018301	TrapCS 1 at pos 3120
 0000026E	     2228	MOVS R2 #40
 00000270	     4351	MULS R1 R2 R1
 00000272	     1840	ADDS R0 R0 R1
 00000274	     9906	LDR R1 [ SP + 24 ]
 00000276	     6601	STR R1 [  R0 + 96 ]
 00000278	     9802	LDR R0 [ SP + 8 ]
 0000027A	     9917	LDR R1 [ SP + 92 ]
 0000027C	     2900	CMP R1 #0
 0000027E	     BF08	IT EQ
 00000280	 EC018574	TrapEQ 4 at pos 3159
 00000284	 1140007C	BL Mod(  1) proc(20)
 00000288	 F000BA24	B #1096, goes to  000006D4
 0000028C	     980B	LDR R0 [ SP + 44 ]
 0000028E	     2800	CMP R0 #0
 00000290	 F0408009	BNE #18, goes to  000002A6
 00000294	     9817	LDR R0 [ SP + 92 ]
 00000296	     2800	CMP R0 #0
 00000298	     BF08	IT EQ
 0000029A	 EC019234	TrapEQ 4 at pos 3235
 0000029E	     6880	LDR R0 [ R0 + 8 ]
 000002A0	     900C	STR R0 [ SP + 48 ]
 000002A2	 F000B810	B #32, goes to  000002C6
 000002A6	     9817	LDR R0 [ SP + 92 ]
 000002A8	     2800	CMP R0 #0
 000002AA	     BF08	IT EQ
 000002AC	 EC019344	TrapEQ 4 at pos 3252
 000002B0	     990B	LDR R1 [ SP + 44 ]
 000002B2	     1E49	SUBS R1 R1 #1
 000002B4	     2918	CMP R1 #24
 000002B6	     BF28	IT CS
 000002B8	 EC019391	TrapCS 1 at pos 3257
 000002BC	     2228	MOVS R2 #40
 000002BE	     4351	MULS R1 R2 R1
 000002C0	     1840	ADDS R0 R0 R1
 000002C2	     6E40	LDR R0 [ R0 + 100 ]
 000002C4	     900C	STR R0 [ SP + 48 ]
 000002C6	     980C	LDR R0 [ SP + 48 ]
 000002C8	     2800	CMP R0 #0
 000002CA	 F0408037	BNE #110, goes to  0000033C
 000002CE	     9806	LDR R0 [ SP + 24 ]
 000002D0	     9015	STR R0 [ SP + 84 ]
 000002D2	     2000	MOVS R0 #0
 000002D4	     9016	STR R0 [ SP + 88 ]
 000002D6	     2001	MOVS R0 #1
 000002D8	     9903	LDR R1 [ SP + 12 ]
 000002DA	     7008	STRB R0 [ R1 + 0 ]
 000002DC	     2000	MOVS R0 #0
 000002DE	     9009	STR R0 [ SP + 36 ]
 000002E0	     9809	LDR R0 [ SP + 36 ]
 000002E2	     2820	CMP R0 #32
 000002E4	     BF28	IT CS
 000002E6	 EC01A401	TrapCS 1 at pos 3392
 000002EA	     9901	LDR R1 [ SP + 4 ]
 000002EC	     1808	ADDS R0 R1 R0
 000002EE	     7800	LDRB R0 [ R0 + 0 ]
 000002F0	 F88D001C	STRB R0 [  SP + 28 ]
 000002F4	     9809	LDR R0 [ SP + 36 ]
 000002F6	     2820	CMP R0 #32
 000002F8	     BF28	IT CS
 000002FA	 EC01A4B1	TrapCS 1 at pos 3403
 000002FE	     4468	ADD R0 SP R0
 00000300	 F89D101C	LDRB R1 [ SP + 28 ]
 00000304	 F8801034	STRB R1 [  R0 + 52 ]
 00000308	     9809	LDR R0 [ SP + 36 ]
 0000030A	     1C40	ADDS R0 R0 #1
 0000030C	     9009	STR R0 [ SP + 36 ]
 0000030E	 F89D001C	LDRB R0 [ SP + 28 ]
 00000312	     2800	CMP R0 #0
 00000314	     D1E4	BNE #-56, goes to  000002E0
 00000316	     9809	LDR R0 [ SP + 36 ]
 00000318	     2820	CMP R0 #32
 0000031A	 F280800D	BGE #26, goes to  00000338
 0000031E	     9809	LDR R0 [ SP + 36 ]
 00000320	     2820	CMP R0 #32
 00000322	     BF28	IT CS
 00000324	 EC01B181	TrapCS 1 at pos 3480
 00000328	     4468	ADD R0 SP R0
 0000032A	     2100	MOVS R1 #0
 0000032C	 F8801034	STRB R1 [  R0 + 52 ]
 00000330	     9809	LDR R0 [ SP + 36 ]
 00000332	     1C40	ADDS R0 R0 #1
 00000334	     9009	STR R0 [ SP + 36 ]
 00000336	     E7EE	B #-36, goes to  00000316
 00000338	 F000B80B	B #22, goes to  00000352
 0000033C	     9801	LDR R0 [ SP + 4 ]
 0000033E	     990C	LDR R1 [ SP + 48 ]
 00000340	     9A03	LDR R2 [ SP + 12 ]
 00000342	     AB0D	ADD R3 SP #52
 00000344	 400000E7	MOV R4 lower 16-bits base(0), next at  00000176
 00000348	 00000014	MOVT R4 higher 16-bits const + 20
 0000034C	     9D06	LDR R5 [ SP + 24 ]
 0000034E	 F7FFFF0E	BL #-484, goes to  0000016E
 00000352	     9803	LDR R0 [ SP + 12 ]
 00000354	     7800	LDRB R0 [ R0 + 0 ]
 00000356	     2800	CMP R0 #0
 00000358	 F00081BC	BEQ #888, goes to  000006D4
 0000035C	     9817	LDR R0 [ SP + 92 ]
 0000035E	     2800	CMP R0 #0
 00000360	     BF08	IT EQ
 00000362	 EC01C294	TrapEQ 4 at pos 3625
 00000366	     6840	LDR R0 [ R0 + 4 ]
 00000368	     2818	CMP R0 #24
 0000036A	 F2808057	BGE #174, goes to  0000041C
 0000036E	     2000	MOVS R0 #0
 00000370	     9903	LDR R1 [ SP + 12 ]
 00000372	     7008	STRB R0 [ R1 + 0 ]
 00000374	     9817	LDR R0 [ SP + 92 ]
 00000376	     2800	CMP R0 #0
 00000378	     BF08	IT EQ
 0000037A	 EC01C594	TrapEQ 4 at pos 3673
 0000037E	     6840	LDR R0 [ R0 + 4 ]
 00000380	     9008	STR R0 [ SP + 32 ]
 00000382	     9808	LDR R0 [ SP + 32 ]
 00000384	     990B	LDR R1 [ SP + 44 ]
 00000386	     4288	CMP R0 R1
 00000388	 F3408028	BLE #80, goes to  000003DC
 0000038C	     9808	LDR R0 [ SP + 32 ]
 0000038E	     1E40	SUBS R0 R0 #1
 00000390	     9008	STR R0 [ SP + 32 ]
 00000392	     9817	LDR R0 [ SP + 92 ]
 00000394	     2800	CMP R0 #0
 00000396	     BF08	IT EQ
 00000398	 EC01C7F4	TrapEQ 4 at pos 3711
 0000039C	     9908	LDR R1 [ SP + 32 ]
 0000039E	     1C49	ADDS R1 R1 #1
 000003A0	     2918	CMP R1 #24
 000003A2	     BF28	IT CS
 000003A4	 EC01D041	TrapCS 1 at pos 3716
 000003A8	     2228	MOVS R2 #40
 000003AA	     4351	MULS R1 R2 R1
 000003AC	     1840	ADDS R0 R0 R1
 000003AE	     9917	LDR R1 [ SP + 92 ]
 000003B0	     2900	CMP R1 #0
 000003B2	     BF08	IT EQ
 000003B4	 EC01D0B4	TrapEQ 4 at pos 3723
 000003B8	     9A08	LDR R2 [ SP + 32 ]
 000003BA	     2A18	CMP R2 #24
 000003BC	     BF28	IT CS
 000003BE	 EC01D0E1	TrapCS 1 at pos 3726
 000003C2	     2328	MOVS R3 #40
 000003C4	     435A	MULS R2 R3 R2
 000003C6	     1889	ADDS R1 R1 R2
 000003C8	     3040	ADDS R0 R0 #64
 000003CA	     3140	ADDS R1 R1 #64
 000003CC	     220A	MOVS R2 #10
 000003CE	 F8513B04	LDR R3 [ R1 ] + 4
 000003D2	 F8403B04	STR R3 [  R0 ] + 4
 000003D6	     1E52	SUBS R2 R2 #1
 000003D8	     D1F9	BNE #-14, goes to  000003CE
 000003DA	     E7D2	B #-92, goes to  00000382
 000003DC	     9817	LDR R0 [ SP + 92 ]
 000003DE	     2800	CMP R0 #0
 000003E0	     BF08	IT EQ
 000003E2	 EC01D224	TrapEQ 4 at pos 3746
 000003E6	     990B	LDR R1 [ SP + 44 ]
 000003E8	     2918	CMP R1 #24
 000003EA	     BF28	IT CS
 000003EC	 EC01D251	TrapCS 1 at pos 3749
 000003F0	     2228	MOVS R2 #40
 000003F2	     4351	MULS R1 R2 R1
 000003F4	     1840	ADDS R0 R0 R1
 000003F6	     3040	ADDS R0 R0 #64
 000003F8	     A90D	ADD R1 SP #52
 000003FA	     220A	MOVS R2 #10
 000003FC	 F8513B04	LDR R3 [ R1 ] + 4
 00000400	 F8403B04	STR R3 [  R0 ] + 4
 00000404	     1E52	SUBS R2 R2 #1
 00000406	     D1F9	BNE #-14, goes to  000003FC
 00000408	     9817	LDR R0 [ SP + 92 ]
 0000040A	     2800	CMP R0 #0
 0000040C	     BF08	IT EQ
 0000040E	 EC01D334	TrapEQ 4 at pos 3763
 00000412	     6841	LDR R1 [ R0 + 4 ]
 00000414	     1C49	ADDS R1 R1 #1
 00000416	     6041	STR R1 [  R0 + 4 ]
 00000418	 F000B954	B #680, goes to  000006C4
 0000041C	     9817	LDR R0 [ SP + 92 ]
 0000041E	     2800	CMP R0 #0
 00000420	     BF08	IT EQ
 00000422	 EC01E014	TrapEQ 4 at pos 3841
 00000426	     210C	MOVS R1 #12
 00000428	     6041	STR R1 [  R0 + 4 ]
 0000042A	     9817	LDR R0 [ SP + 92 ]
 0000042C	     2800	CMP R0 #0
 0000042E	     BF08	IT EQ
 00000430	 EC01E0E4	TrapEQ 4 at pos 3854
 00000434	 F24A318D	MOV R1 #41869
 00000438	 F6C9311E	MOVT R1 #39710
 0000043C	     6001	STR R1 [  R0 + 0 ]
 0000043E	     980B	LDR R0 [ SP + 44 ]
 00000440	     280C	CMP R0 #12
 00000442	 F2808090	BGE #288, goes to  00000566
 00000446	     9817	LDR R0 [ SP + 92 ]
 00000448	     2800	CMP R0 #0
 0000044A	     BF08	IT EQ
 0000044C	 EC01E5F4	TrapEQ 4 at pos 3935
 00000450	     9904	LDR R1 [ SP + 16 ]
 00000452	 F51070FC	ADDS R0 R0 #504
 00000456	     220A	MOVS R2 #10
 00000458	 F8503B04	LDR R3 [ R0 ] + 4
 0000045C	 F8413B04	STR R3 [  R1 ] + 4
 00000460	     1E52	SUBS R2 R2 #1
 00000462	     D1F9	BNE #-14, goes to  00000458
 00000464	     200B	MOVS R0 #11
 00000466	     9008	STR R0 [ SP + 32 ]
 00000468	     9808	LDR R0 [ SP + 32 ]
 0000046A	     990B	LDR R1 [ SP + 44 ]
 0000046C	     4288	CMP R0 R1
 0000046E	 F3408028	BLE #80, goes to  000004C2
 00000472	     9808	LDR R0 [ SP + 32 ]
 00000474	     1E40	SUBS R0 R0 #1
 00000476	     9008	STR R0 [ SP + 32 ]
 00000478	     9817	LDR R0 [ SP + 92 ]
 0000047A	     2800	CMP R0 #0
 0000047C	     BF08	IT EQ
 0000047E	 EC01F164	TrapEQ 4 at pos 3990
 00000482	     9908	LDR R1 [ SP + 32 ]
 00000484	     1C49	ADDS R1 R1 #1
 00000486	     2918	CMP R1 #24
 00000488	     BF28	IT CS
 0000048A	 EC01F1B1	TrapCS 1 at pos 3995
 0000048E	     2228	MOVS R2 #40
 00000490	     4351	MULS R1 R2 R1
 00000492	     1840	ADDS R0 R0 R1
 00000494	     9917	LDR R1 [ SP + 92 ]
 00000496	     2900	CMP R1 #0
 00000498	     BF08	IT EQ
 0000049A	 EC01F224	TrapEQ 4 at pos 4002
 0000049E	     9A08	LDR R2 [ SP + 32 ]
 000004A0	     2A18	CMP R2 #24
 000004A2	     BF28	IT CS
 000004A4	 EC01F251	TrapCS 1 at pos 4005
 000004A8	     2328	MOVS R3 #40
 000004AA	     435A	MULS R2 R3 R2
 000004AC	     1889	ADDS R1 R1 R2
 000004AE	     3040	ADDS R0 R0 #64
 000004B0	     3140	ADDS R1 R1 #64
 000004B2	     220A	MOVS R2 #10
 000004B4	 F8513B04	LDR R3 [ R1 ] + 4
 000004B8	 F8403B04	STR R3 [  R0 ] + 4
 000004BC	     1E52	SUBS R2 R2 #1
 000004BE	     D1F9	BNE #-14, goes to  000004B4
 000004C0	     E7D2	B #-92, goes to  00000468
 000004C2	     9817	LDR R0 [ SP + 92 ]
 000004C4	     2800	CMP R0 #0
 000004C6	     BF08	IT EQ
 000004C8	 EC01F3B4	TrapEQ 4 at pos 4027
 000004CC	     990B	LDR R1 [ SP + 44 ]
 000004CE	     2918	CMP R1 #24
 000004D0	     BF28	IT CS
 000004D2	 EC01F3E1	TrapCS 1 at pos 4030
 000004D6	     2228	MOVS R2 #40
 000004D8	     4351	MULS R1 R2 R1
 000004DA	     1840	ADDS R0 R0 R1
 000004DC	     3040	ADDS R0 R0 #64
 000004DE	     A90D	ADD R1 SP #52
 000004E0	     220A	MOVS R2 #10
 000004E2	 F8513B04	LDR R3 [ R1 ] + 4
 000004E6	 F8403B04	STR R3 [  R0 ] + 4
 000004EA	     1E52	SUBS R2 R2 #1
 000004EC	     D1F9	BNE #-14, goes to  000004E2
 000004EE	     9802	LDR R0 [ SP + 8 ]
 000004F0	     9917	LDR R1 [ SP + 92 ]
 000004F2	     2900	CMP R1 #0
 000004F4	     BF08	IT EQ
 000004F6	 EC01F5F4	TrapEQ 4 at pos 4063
 000004FA	 1140013B	BL Mod(  1) proc(20)
 000004FE	     9802	LDR R0 [ SP + 8 ]
 00000500	     A902	ADD R1 SP #8
 00000502	 11200004	BL Mod(  1) proc(18)
 00000506	     2000	MOVS R0 #0
 00000508	     9008	STR R0 [ SP + 32 ]
 0000050A	     9808	LDR R0 [ SP + 32 ]
 0000050C	     280C	CMP R0 #12
 0000050E	 F2808028	BGE #80, goes to  00000562
 00000512	     9817	LDR R0 [ SP + 92 ]
 00000514	     2800	CMP R0 #0
 00000516	     BF08	IT EQ
 00000518	 EC020334	TrapEQ 4 at pos 4147
 0000051C	     9908	LDR R1 [ SP + 32 ]
 0000051E	     2918	CMP R1 #24
 00000520	     BF28	IT CS
 00000522	 EC020361	TrapCS 1 at pos 4150
 00000526	     2228	MOVS R2 #40
 00000528	     4351	MULS R1 R2 R1
 0000052A	     1840	ADDS R0 R0 R1
 0000052C	     9917	LDR R1 [ SP + 92 ]
 0000052E	     2900	CMP R1 #0
 00000530	     BF08	IT EQ
 00000532	 EC0203D4	TrapEQ 4 at pos 4157
 00000536	     9A08	LDR R2 [ SP + 32 ]
 00000538	     320C	ADDS R2 R2 #12
 0000053A	     2A18	CMP R2 #24
 0000053C	     BF28	IT CS
 0000053E	 EC020421	TrapCS 1 at pos 4162
 00000542	     2328	MOVS R3 #40
 00000544	     435A	MULS R2 R3 R2
 00000546	     1889	ADDS R1 R1 R2
 00000548	     3040	ADDS R0 R0 #64
 0000054A	     3140	ADDS R1 R1 #64
 0000054C	     220A	MOVS R2 #10
 0000054E	 F8513B04	LDR R3 [ R1 ] + 4
 00000552	 F8403B04	STR R3 [  R0 ] + 4
 00000556	     1E52	SUBS R2 R2 #1
 00000558	     D1F9	BNE #-14, goes to  0000054E
 0000055A	     9808	LDR R0 [ SP + 32 ]
 0000055C	     1C40	ADDS R0 R0 #1
 0000055E	     9008	STR R0 [ SP + 32 ]
 00000560	     E7D3	B #-90, goes to  0000050A
 00000562	 F000B8A4	B #328, goes to  000006AE
 00000566	     9802	LDR R0 [ SP + 8 ]
 00000568	     9917	LDR R1 [ SP + 92 ]
 0000056A	     2900	CMP R1 #0
 0000056C	     BF08	IT EQ
 0000056E	 EC0211D4	TrapEQ 4 at pos 4253
 00000572	 11400038	BL Mod(  1) proc(20)
 00000576	     9802	LDR R0 [ SP + 8 ]
 00000578	     A902	ADD R1 SP #8
 0000057A	 11200004	BL Mod(  1) proc(18)
 0000057E	     980B	LDR R0 [ SP + 44 ]
 00000580	     380C	SUBS R0 R0 #12
 00000582	     900B	STR R0 [ SP + 44 ]
 00000584	     2000	MOVS R0 #0
 00000586	     9008	STR R0 [ SP + 32 ]
 00000588	     980B	LDR R0 [ SP + 44 ]
 0000058A	     2800	CMP R0 #0
 0000058C	 F040800B	BNE #22, goes to  000005A6
 00000590	     9804	LDR R0 [ SP + 16 ]
 00000592	     A90D	ADD R1 SP #52
 00000594	     220A	MOVS R2 #10
 00000596	 F8513B04	LDR R3 [ R1 ] + 4
 0000059A	 F8403B04	STR R3 [  R0 ] + 4
 0000059E	     1E52	SUBS R2 R2 #1
 000005A0	     D1F9	BNE #-14, goes to  00000596
 000005A2	 F000B857	B #174, goes to  00000654
 000005A6	     9817	LDR R0 [ SP + 92 ]
 000005A8	     2800	CMP R0 #0
 000005AA	     BF08	IT EQ
 000005AC	 EC022184	TrapEQ 4 at pos 4376
 000005B0	     9904	LDR R1 [ SP + 16 ]
 000005B2	 F5107008	ADDS R0 R0 #544
 000005B6	     220A	MOVS R2 #10
 000005B8	 F8503B04	LDR R3 [ R0 ] + 4
 000005BC	 F8413B04	STR R3 [  R1 ] + 4
 000005C0	     1E52	SUBS R2 R2 #1
 000005C2	     D1F9	BNE #-14, goes to  000005B8
 000005C4	     980B	LDR R0 [ SP + 44 ]
 000005C6	     1E40	SUBS R0 R0 #1
 000005C8	     9908	LDR R1 [ SP + 32 ]
 000005CA	     4281	CMP R1 R0
 000005CC	 F2808029	BGE #82, goes to  00000622
 000005D0	     9817	LDR R0 [ SP + 92 ]
 000005D2	     2800	CMP R0 #0
 000005D4	     BF08	IT EQ
 000005D6	 EC0223F4	TrapEQ 4 at pos 4415
 000005DA	     9908	LDR R1 [ SP + 32 ]
 000005DC	     2918	CMP R1 #24
 000005DE	     BF28	IT CS
 000005E0	 EC022421	TrapCS 1 at pos 4418
 000005E4	     2228	MOVS R2 #40
 000005E6	     4351	MULS R1 R2 R1
 000005E8	     1840	ADDS R0 R0 R1
 000005EA	     9917	LDR R1 [ SP + 92 ]
 000005EC	     2900	CMP R1 #0
 000005EE	     BF08	IT EQ
 000005F0	 EC022494	TrapEQ 4 at pos 4425
 000005F4	     220D	MOVS R2 #13
 000005F6	     9B08	LDR R3 [ SP + 32 ]
 000005F8	     18D2	ADDS R2 R2 R3
 000005FA	     2A18	CMP R2 #24
 000005FC	     BF28	IT CS
 000005FE	 EC022501	TrapCS 1 at pos 4432
 00000602	     2328	MOVS R3 #40
 00000604	     435A	MULS R2 R3 R2
 00000606	     1889	ADDS R1 R1 R2
 00000608	     3040	ADDS R0 R0 #64
 0000060A	     3140	ADDS R1 R1 #64
 0000060C	     220A	MOVS R2 #10
 0000060E	 F8513B04	LDR R3 [ R1 ] + 4
 00000612	 F8403B04	STR R3 [  R0 ] + 4
 00000616	     1E52	SUBS R2 R2 #1
 00000618	     D1F9	BNE #-14, goes to  0000060E
 0000061A	     9808	LDR R0 [ SP + 32 ]
 0000061C	     1C40	ADDS R0 R0 #1
 0000061E	     9008	STR R0 [ SP + 32 ]
 00000620	     E7D0	B #-96, goes to  000005C4
 00000622	     9817	LDR R0 [ SP + 92 ]
 00000624	     2800	CMP R0 #0
 00000626	     BF08	IT EQ
 00000628	 EC022704	TrapEQ 4 at pos 4464
 0000062C	     9908	LDR R1 [ SP + 32 ]
 0000062E	     2918	CMP R1 #24
 00000630	     BF28	IT CS
 00000632	 EC022731	TrapCS 1 at pos 4467
 00000636	     2228	MOVS R2 #40
 00000638	     4351	MULS R1 R2 R1
 0000063A	     1840	ADDS R0 R0 R1
 0000063C	     3040	ADDS R0 R0 #64
 0000063E	     A90D	ADD R1 SP #52
 00000640	     220A	MOVS R2 #10
 00000642	 F8513B04	LDR R3 [ R1 ] + 4
 00000646	 F8403B04	STR R3 [  R0 ] + 4
 0000064A	     1E52	SUBS R2 R2 #1
 0000064C	     D1F9	BNE #-14, goes to  00000642
 0000064E	     9808	LDR R0 [ SP + 32 ]
 00000650	     1C40	ADDS R0 R0 #1
 00000652	     9008	STR R0 [ SP + 32 ]
 00000654	     9808	LDR R0 [ SP + 32 ]
 00000656	     280C	CMP R0 #12
 00000658	 F2808029	BGE #82, goes to  000006AE
 0000065C	     9817	LDR R0 [ SP + 92 ]
 0000065E	     2800	CMP R0 #0
 00000660	     BF08	IT EQ
 00000662	 EC023314	TrapEQ 4 at pos 4529
 00000666	     9908	LDR R1 [ SP + 32 ]
 00000668	     2918	CMP R1 #24
 0000066A	     BF28	IT CS
 0000066C	 EC023341	TrapCS 1 at pos 4532
 00000670	     2228	MOVS R2 #40
 00000672	     4351	MULS R1 R2 R1
 00000674	     1840	ADDS R0 R0 R1
 00000676	     9917	LDR R1 [ SP + 92 ]
 00000678	     2900	CMP R1 #0
 0000067A	     BF08	IT EQ
 0000067C	 EC0233B4	TrapEQ 4 at pos 4539
 00000680	     220C	MOVS R2 #12
 00000682	     9B08	LDR R3 [ SP + 32 ]
 00000684	     18D2	ADDS R2 R2 R3
 00000686	     2A18	CMP R2 #24
 00000688	     BF28	IT CS
 0000068A	 EC023401	TrapCS 1 at pos 4544
 0000068E	     2328	MOVS R3 #40
 00000690	     435A	MULS R2 R3 R2
 00000692	     1889	ADDS R1 R1 R2
 00000694	     3040	ADDS R0 R0 #64
 00000696	     3140	ADDS R1 R1 #64
 00000698	     220A	MOVS R2 #10
 0000069A	 F8513B04	LDR R3 [ R1 ] + 4
 0000069E	 F8403B04	STR R3 [  R0 ] + 4
 000006A2	     1E52	SUBS R2 R2 #1
 000006A4	     D1F9	BNE #-14, goes to  0000069A
 000006A6	     9808	LDR R0 [ SP + 32 ]
 000006A8	     1C40	ADDS R0 R0 #1
 000006AA	     9008	STR R0 [ SP + 32 ]
 000006AC	     E7D2	B #-92, goes to  00000654
 000006AE	     9817	LDR R0 [ SP + 92 ]
 000006B0	     2800	CMP R0 #0
 000006B2	     BF08	IT EQ
 000006B4	 EC0236B4	TrapEQ 4 at pos 4587
 000006B8	     9904	LDR R1 [ SP + 16 ]
 000006BA	     6A49	LDR R1 [ R1 + 36 ]
 000006BC	     6081	STR R1 [  R0 + 8 ]
 000006BE	     9802	LDR R0 [ SP + 8 ]
 000006C0	     9904	LDR R1 [ SP + 16 ]
 000006C2	     6248	STR R0 [  R1 + 36 ]
 000006C4	     9802	LDR R0 [ SP + 8 ]
 000006C6	     9917	LDR R1 [ SP + 92 ]
 000006C8	     2900	CMP R1 #0
 000006CA	     BF08	IT EQ
 000006CC	 EC024304	TrapEQ 4 at pos 4656
 000006D0	 114000AB	BL Mod(  1) proc(20)
 000006D4	 F85DEB04	LDR LR [ SP ] + 4
 000006D8	     B017	ADD SP SP #92
 000006DA	     4770	BX LR
 000006DC	     B08D	SUB SP SP #52
 000006DE	     B403	PUSH R0 R1
 000006E0	     B500	PUSH LR
 000006E2	     A80F	ADD R0 SP #60
 000006E4	 100001D0	MOV R1 lower 16-bits base(0), next at  00000344
 000006E8	 00000028	MOVT R1 higher 16-bits const + 40
 000006EC	     DF00	SVC #0
 000006EE	     2000	MOVS R0 #0
 000006F0	 F88D0010	STRB R0 [  SP + 16 ]
 000006F4	 11900012	BL Mod(  1) proc(25)
 000006F8	     9801	LDR R0 [ SP + 4 ]
 000006FA	     211D	MOVS R1 #29
 000006FC	     AA04	ADD R2 SP #16
 000006FE	     AB05	ADD R3 SP #20
 00000700	 4000000E	MOV R4 lower 16-bits base(0), next at  000006E4
 00000704	 00000014	MOVT R4 higher 16-bits const + 20
 00000708	     9D02	LDR R5 [ SP + 8 ]
 0000070A	 F7FFFD30	BL #-1440, goes to  0000016E
 0000070E	 F89D0010	LDRB R0 [ SP + 16 ]
 00000712	     2800	CMP R0 #0
 00000714	 F0008050	BEQ #160, goes to  000007B8
 00000718	     201D	MOVS R0 #29
 0000071A	     990F	LDR R1 [ SP + 60 ]
 0000071C	     2900	CMP R1 #0
 0000071E	     BF08	IT EQ
 00000720	 EC026774	TrapEQ 4 at pos 4983
 00000724	 11300018	BL Mod(  1) proc(19)
 00000728	     980F	LDR R0 [ SP + 60 ]
 0000072A	     2800	CMP R0 #0
 0000072C	     BF08	IT EQ
 0000072E	 EC027064	TrapEQ 4 at pos 4998
 00000732	     6800	LDR R0 [ R0 + 0 ]
 00000734	 F24A318D	MOV R1 #41869
 00000738	 F6C9311E	MOVT R1 #39710
 0000073C	     4288	CMP R0 R1
 0000073E	     BF18	IT NE
 00000740	 EC027127	TrapNE 7 at pos 5010
 00000744	     201D	MOVS R0 #29
 00000746	     A903	ADD R1 SP #12
 00000748	 11200012	BL Mod(  1) proc(18)
 0000074C	     9803	LDR R0 [ SP + 12 ]
 0000074E	     990F	LDR R1 [ SP + 60 ]
 00000750	     2900	CMP R1 #0
 00000752	     BF08	IT EQ
 00000754	 EC0275F4	TrapEQ 4 at pos 5087
 00000758	 11400008	BL Mod(  1) proc(20)
 0000075C	     980F	LDR R0 [ SP + 60 ]
 0000075E	     2800	CMP R0 #0
 00000760	     BF08	IT EQ
 00000762	 EC0276D4	TrapEQ 4 at pos 5101
 00000766	 F24A318D	MOV R1 #41869
 0000076A	 F6C9311E	MOVT R1 #39710
 0000076E	     6001	STR R1 [  R0 + 0 ]
 00000770	     980F	LDR R0 [ SP + 60 ]
 00000772	     2800	CMP R0 #0
 00000774	     BF08	IT EQ
 00000776	 EC0277D4	TrapEQ 4 at pos 5117
 0000077A	     2101	MOVS R1 #1
 0000077C	     6041	STR R1 [  R0 + 4 ]
 0000077E	     980F	LDR R0 [ SP + 60 ]
 00000780	     2800	CMP R0 #0
 00000782	     BF08	IT EQ
 00000784	 EC028084	TrapEQ 4 at pos 5128
 00000788	     9903	LDR R1 [ SP + 12 ]
 0000078A	     6081	STR R1 [  R0 + 8 ]
 0000078C	     980F	LDR R0 [ SP + 60 ]
 0000078E	     2800	CMP R0 #0
 00000790	     BF08	IT EQ
 00000792	 EC028184	TrapEQ 4 at pos 5144
 00000796	     3040	ADDS R0 R0 #64
 00000798	     A905	ADD R1 SP #20
 0000079A	     220A	MOVS R2 #10
 0000079C	 F8513B04	LDR R3 [ R1 ] + 4
 000007A0	 F8403B04	STR R3 [  R0 ] + 4
 000007A4	     1E52	SUBS R2 R2 #1
 000007A6	     D1F9	BNE #-14, goes to  0000079C
 000007A8	     201D	MOVS R0 #29
 000007AA	     990F	LDR R1 [ SP + 60 ]
 000007AC	     2900	CMP R1 #0
 000007AE	     BF08	IT EQ
 000007B0	 EC028484	TrapEQ 4 at pos 5192
 000007B4	 1140002E	BL Mod(  1) proc(20)
 000007B8	 11A00002	BL Mod(  1) proc(26)
 000007BC	 F85DEB04	LDR LR [ SP ] + 4
 000007C0	     B00F	ADD SP SP #60
 000007C2	     4770	BX LR
 000007C4	     B085	SUB SP SP #20
 000007C6	     B41F	PUSH R0 R1 R2 R3 R4
 000007C8	     B500	PUSH LR
 000007CA	     A809	ADD R0 SP #36
 000007CC	 10000066	MOV R1 lower 16-bits base(0), next at  00000700
 000007D0	 00000028	MOVT R1 higher 16-bits const + 40
 000007D4	     DF00	SVC #0
 000007D6	     A80A	ADD R0 SP #40
 000007D8	 10000006	MOV R1 lower 16-bits base(0), next at  000007CC
 000007DC	 00000028	MOVT R1 higher 16-bits const + 40
 000007E0	     DF00	SVC #0
 000007E2	     9803	LDR R0 [ SP + 12 ]
 000007E4	     9909	LDR R1 [ SP + 36 ]
 000007E6	     2900	CMP R1 #0
 000007E8	     BF08	IT EQ
 000007EA	 EC02B7D4	TrapEQ 4 at pos 5629
 000007EE	 1130001B	BL Mod(  1) proc(19)
 000007F2	     9809	LDR R0 [ SP + 36 ]
 000007F4	     2800	CMP R0 #0
 000007F6	     BF08	IT EQ
 000007F8	 EC02C0C4	TrapEQ 4 at pos 5644
 000007FC	     6800	LDR R0 [ R0 + 0 ]
 000007FE	 F24A318D	MOV R1 #41869
 00000802	 F6C9311E	MOVT R1 #39710
 00000806	     4288	CMP R0 R1
 00000808	     BF18	IT NE
 0000080A	 EC02C187	TrapNE 7 at pos 5656
 0000080E	     9804	LDR R0 [ SP + 16 ]
 00000810	     9901	LDR R1 [ SP + 4 ]
 00000812	     6849	LDR R1 [ R1 + 4 ]
 00000814	     4288	CMP R0 R1
 00000816	 F280818B	BGE #790, goes to  00000B30
 0000081A	     9804	LDR R0 [ SP + 16 ]
 0000081C	     2818	CMP R0 #24
 0000081E	     BF28	IT CS
 00000820	 EC02D0B1	TrapCS 1 at pos 5771
 00000824	     2128	MOVS R1 #40
 00000826	     4348	MULS R0 R1 R0
 00000828	     9901	LDR R1 [ SP + 4 ]
 0000082A	     1808	ADDS R0 R1 R0
 0000082C	     6E40	LDR R0 [ R0 + 100 ]
 0000082E	     9008	STR R0 [ SP + 32 ]
 00000830	     9808	LDR R0 [ SP + 32 ]
 00000832	     990A	LDR R1 [ SP + 40 ]
 00000834	     2900	CMP R1 #0
 00000836	     BF08	IT EQ
 00000838	 EC02D294	TrapEQ 4 at pos 5801
 0000083C	 11300027	BL Mod(  1) proc(19)
 00000840	     980A	LDR R0 [ SP + 40 ]
 00000842	     2800	CMP R0 #0
 00000844	     BF08	IT EQ
 00000846	 EC02D384	TrapEQ 4 at pos 5816
 0000084A	     6800	LDR R0 [ R0 + 0 ]
 0000084C	 F24A318D	MOV R1 #41869
 00000850	 F6C9311E	MOVT R1 #39710
 00000854	     4288	CMP R0 R1
 00000856	     BF18	IT NE
 00000858	 EC02D447	TrapNE 7 at pos 5828
 0000085C	     980A	LDR R0 [ SP + 40 ]
 0000085E	     2800	CMP R0 #0
 00000860	     BF08	IT EQ
 00000862	 EC02D544	TrapEQ 4 at pos 5844
 00000866	     6840	LDR R0 [ R0 + 4 ]
 00000868	     380C	SUBS R0 R0 #12
 0000086A	     1C40	ADDS R0 R0 #1
 0000086C	     1040	ASRS R0 R0 #1
 0000086E	     9007	STR R0 [ SP + 28 ]
 00000870	     9809	LDR R0 [ SP + 36 ]
 00000872	     2800	CMP R0 #0
 00000874	     BF08	IT EQ
 00000876	 EC02E134	TrapEQ 4 at pos 5907
 0000087A	     9904	LDR R1 [ SP + 16 ]
 0000087C	     2918	CMP R1 #24
 0000087E	     BF28	IT CS
 00000880	 EC02E221	TrapCS 1 at pos 5922
 00000884	     2228	MOVS R2 #40
 00000886	     4351	MULS R1 R2 R1
 00000888	     9A01	LDR R2 [ SP + 4 ]
 0000088A	     1851	ADDS R1 R2 R1
 0000088C	 F51070FC	ADDS R0 R0 #504
 00000890	     3140	ADDS R1 R1 #64
 00000892	     220A	MOVS R2 #10
 00000894	 F8513B04	LDR R3 [ R1 ] + 4
 00000898	 F8403B04	STR R3 [  R0 ] + 4
 0000089C	     1E52	SUBS R2 R2 #1
 0000089E	     D1F9	BNE #-14, goes to  00000894
 000008A0	     9809	LDR R0 [ SP + 36 ]
 000008A2	     2800	CMP R0 #0
 000008A4	     BF08	IT EQ
 000008A6	 EC02E274	TrapEQ 4 at pos 5927
 000008AA	     990A	LDR R1 [ SP + 40 ]
 000008AC	     2900	CMP R1 #0
 000008AE	     BF08	IT EQ
 000008B0	 EC02E364	TrapEQ 4 at pos 5942
 000008B4	     6889	LDR R1 [ R1 + 8 ]
 000008B6	 F8C0121C	STR R1 [  R0 + 540 ]
 000008BA	     9807	LDR R0 [ SP + 28 ]
 000008BC	     2800	CMP R0 #0
 000008BE	 F34080C3	BLE #390, goes to  00000A48
 000008C2	     2000	MOVS R0 #0
 000008C4	     9006	STR R0 [ SP + 24 ]
 000008C6	     9807	LDR R0 [ SP + 28 ]
 000008C8	     1E40	SUBS R0 R0 #1
 000008CA	     9906	LDR R1 [ SP + 24 ]
 000008CC	     4281	CMP R1 R0
 000008CE	 F2808028	BGE #80, goes to  00000922
 000008D2	     9809	LDR R0 [ SP + 36 ]
 000008D4	     2800	CMP R0 #0
 000008D6	     BF08	IT EQ
 000008D8	 EC02F214	TrapEQ 4 at pos 6049
 000008DC	     9906	LDR R1 [ SP + 24 ]
 000008DE	     310C	ADDS R1 R1 #12
 000008E0	     2918	CMP R1 #24
 000008E2	     BF28	IT CS
 000008E4	 EC02F261	TrapCS 1 at pos 6054
 000008E8	     2228	MOVS R2 #40
 000008EA	     4351	MULS R1 R2 R1
 000008EC	     1840	ADDS R0 R0 R1
 000008EE	     990A	LDR R1 [ SP + 40 ]
 000008F0	     2900	CMP R1 #0
 000008F2	     BF08	IT EQ
 000008F4	 EC02F2D4	TrapEQ 4 at pos 6061
 000008F8	     9A06	LDR R2 [ SP + 24 ]
 000008FA	     2A18	CMP R2 #24
 000008FC	     BF28	IT CS
 000008FE	 EC02F301	TrapCS 1 at pos 6064
 00000902	     2328	MOVS R3 #40
 00000904	     435A	MULS R2 R3 R2
 00000906	     1889	ADDS R1 R1 R2
 00000908	     3040	ADDS R0 R0 #64
 0000090A	     3140	ADDS R1 R1 #64
 0000090C	     220A	MOVS R2 #10
 0000090E	 F8513B04	LDR R3 [ R1 ] + 4
 00000912	 F8403B04	STR R3 [  R0 ] + 4
 00000916	     1E52	SUBS R2 R2 #1
 00000918	     D1F9	BNE #-14, goes to  0000090E
 0000091A	     9806	LDR R0 [ SP + 24 ]
 0000091C	     1C40	ADDS R0 R0 #1
 0000091E	     9006	STR R0 [ SP + 24 ]
 00000920	     E7D1	B #-94, goes to  000008C6
 00000922	     9804	LDR R0 [ SP + 16 ]
 00000924	     2818	CMP R0 #24
 00000926	     BF28	IT CS
 00000928	 EC02F4D1	TrapCS 1 at pos 6093
 0000092C	     2128	MOVS R1 #40
 0000092E	     4348	MULS R0 R1 R0
 00000930	     9901	LDR R1 [ SP + 4 ]
 00000932	     1808	ADDS R0 R1 R0
 00000934	     990A	LDR R1 [ SP + 40 ]
 00000936	     2900	CMP R1 #0
 00000938	     BF08	IT EQ
 0000093A	 EC02F544	TrapEQ 4 at pos 6100
 0000093E	     9A06	LDR R2 [ SP + 24 ]
 00000940	     2A18	CMP R2 #24
 00000942	     BF28	IT CS
 00000944	 EC02F571	TrapCS 1 at pos 6103
 00000948	     2328	MOVS R3 #40
 0000094A	     435A	MULS R2 R3 R2
 0000094C	     1889	ADDS R1 R1 R2
 0000094E	     3040	ADDS R0 R0 #64
 00000950	     3140	ADDS R1 R1 #64
 00000952	     220A	MOVS R2 #10
 00000954	 F8513B04	LDR R3 [ R1 ] + 4
 00000958	 F8403B04	STR R3 [  R0 ] + 4
 0000095C	     1E52	SUBS R2 R2 #1
 0000095E	     D1F9	BNE #-14, goes to  00000954
 00000960	     980A	LDR R0 [ SP + 40 ]
 00000962	     2800	CMP R0 #0
 00000964	     BF08	IT EQ
 00000966	 EC02F5D4	TrapEQ 4 at pos 6109
 0000096A	     9904	LDR R1 [ SP + 16 ]
 0000096C	     2918	CMP R1 #24
 0000096E	     BF28	IT CS
 00000970	 EC02F671	TrapCS 1 at pos 6119
 00000974	     2228	MOVS R2 #40
 00000976	     4351	MULS R1 R2 R1
 00000978	     9A01	LDR R2 [ SP + 4 ]
 0000097A	     1851	ADDS R1 R2 R1
 0000097C	     6E49	LDR R1 [ R1 + 100 ]
 0000097E	     6081	STR R1 [  R0 + 8 ]
 00000980	     9804	LDR R0 [ SP + 16 ]
 00000982	     2818	CMP R0 #24
 00000984	     BF28	IT CS
 00000986	 EC02F791	TrapCS 1 at pos 6137
 0000098A	     2128	MOVS R1 #40
 0000098C	     4348	MULS R0 R1 R0
 0000098E	     9901	LDR R1 [ SP + 4 ]
 00000990	     1808	ADDS R0 R1 R0
 00000992	     9908	LDR R1 [ SP + 32 ]
 00000994	     6641	STR R1 [  R0 + 100 ]
 00000996	     980A	LDR R0 [ SP + 40 ]
 00000998	     2800	CMP R0 #0
 0000099A	     BF08	IT EQ
 0000099C	 EC030084	TrapEQ 4 at pos 6152
 000009A0	     990A	LDR R1 [ SP + 40 ]
 000009A2	     2900	CMP R1 #0
 000009A4	     BF08	IT EQ
 000009A6	 EC0300F4	TrapEQ 4 at pos 6159
 000009AA	     6849	LDR R1 [ R1 + 4 ]
 000009AC	     9A07	LDR R2 [ SP + 28 ]
 000009AE	     1A89	SUBS R1 R1 R2
 000009B0	     6041	STR R1 [  R0 + 4 ]
 000009B2	     2000	MOVS R0 #0
 000009B4	     9006	STR R0 [ SP + 24 ]
 000009B6	     980A	LDR R0 [ SP + 40 ]
 000009B8	     2800	CMP R0 #0
 000009BA	     BF08	IT EQ
 000009BC	 EC030324	TrapEQ 4 at pos 6194
 000009C0	     9906	LDR R1 [ SP + 24 ]
 000009C2	     6840	LDR R0 [ R0 + 4 ]
 000009C4	     4281	CMP R1 R0
 000009C6	 F2808029	BGE #82, goes to  00000A1C
 000009CA	     980A	LDR R0 [ SP + 40 ]
 000009CC	     2800	CMP R0 #0
 000009CE	     BF08	IT EQ
 000009D0	 EC030394	TrapEQ 4 at pos 6201
 000009D4	     9906	LDR R1 [ SP + 24 ]
 000009D6	     2918	CMP R1 #24
 000009D8	     BF28	IT CS
 000009DA	 EC0303C1	TrapCS 1 at pos 6204
 000009DE	     2228	MOVS R2 #40
 000009E0	     4351	MULS R1 R2 R1
 000009E2	     1840	ADDS R0 R0 R1
 000009E4	     990A	LDR R1 [ SP + 40 ]
 000009E6	     2900	CMP R1 #0
 000009E8	     BF08	IT EQ
 000009EA	 EC030434	TrapEQ 4 at pos 6211
 000009EE	     9A06	LDR R2 [ SP + 24 ]
 000009F0	     9B07	LDR R3 [ SP + 28 ]
 000009F2	     18D2	ADDS R2 R2 R3
 000009F4	     2A18	CMP R2 #24
 000009F6	     BF28	IT CS
 000009F8	 EC030481	TrapCS 1 at pos 6216
 000009FC	     2328	MOVS R3 #40
 000009FE	     435A	MULS R2 R3 R2
 00000A00	     1889	ADDS R1 R1 R2
 00000A02	     3040	ADDS R0 R0 #64
 00000A04	     3140	ADDS R1 R1 #64
 00000A06	     220A	MOVS R2 #10
 00000A08	 F8513B04	LDR R3 [ R1 ] + 4
 00000A0C	 F8403B04	STR R3 [  R0 ] + 4
 00000A10	     1E52	SUBS R2 R2 #1
 00000A12	     D1F9	BNE #-14, goes to  00000A08
 00000A14	     9806	LDR R0 [ SP + 24 ]
 00000A16	     1C40	ADDS R0 R0 #1
 00000A18	     9006	STR R0 [ SP + 24 ]
 00000A1A	     E7CC	B #-104, goes to  000009B6
 00000A1C	     9808	LDR R0 [ SP + 32 ]
 00000A1E	     990A	LDR R1 [ SP + 40 ]
 00000A20	     2900	CMP R1 #0
 00000A22	     BF08	IT EQ
 00000A24	 EC030794	TrapEQ 4 at pos 6265
 00000A28	 114000F6	BL Mod(  1) proc(20)
 00000A2C	     9809	LDR R0 [ SP + 36 ]
 00000A2E	     2800	CMP R0 #0
 00000A30	     BF08	IT EQ
 00000A32	 EC0307E4	TrapEQ 4 at pos 6270
 00000A36	     210B	MOVS R1 #11
 00000A38	     9A07	LDR R2 [ SP + 28 ]
 00000A3A	     1889	ADDS R1 R1 R2
 00000A3C	     6041	STR R1 [  R0 + 4 ]
 00000A3E	     2000	MOVS R0 #0
 00000A40	     9905	LDR R1 [ SP + 20 ]
 00000A42	     7008	STRB R0 [ R1 + 0 ]
 00000A44	 F000B86A	B #212, goes to  00000B1C
 00000A48	     2000	MOVS R0 #0
 00000A4A	     9006	STR R0 [ SP + 24 ]
 00000A4C	     9806	LDR R0 [ SP + 24 ]
 00000A4E	     280C	CMP R0 #12
 00000A50	 F2808028	BGE #80, goes to  00000AA4
 00000A54	     9809	LDR R0 [ SP + 36 ]
 00000A56	     2800	CMP R0 #0
 00000A58	     BF08	IT EQ
 00000A5A	 EC031644	TrapEQ 4 at pos 6372
 00000A5E	     9906	LDR R1 [ SP + 24 ]
 00000A60	     310C	ADDS R1 R1 #12
 00000A62	     2918	CMP R1 #24
 00000A64	     BF28	IT CS
 00000A66	 EC031691	TrapCS 1 at pos 6377
 00000A6A	     2228	MOVS R2 #40
 00000A6C	     4351	MULS R1 R2 R1
 00000A6E	     1840	ADDS R0 R0 R1
 00000A70	     990A	LDR R1 [ SP + 40 ]
 00000A72	     2900	CMP R1 #0
 00000A74	     BF08	IT EQ
 00000A76	 EC031704	TrapEQ 4 at pos 6384
 00000A7A	     9A06	LDR R2 [ SP + 24 ]
 00000A7C	     2A18	CMP R2 #24
 00000A7E	     BF28	IT CS
 00000A80	 EC031731	TrapCS 1 at pos 6387
 00000A84	     2328	MOVS R3 #40
 00000A86	     435A	MULS R2 R3 R2
 00000A88	     1889	ADDS R1 R1 R2
 00000A8A	     3040	ADDS R0 R0 #64
 00000A8C	     3140	ADDS R1 R1 #64
 00000A8E	     220A	MOVS R2 #10
 00000A90	 F8513B04	LDR R3 [ R1 ] + 4
 00000A94	 F8403B04	STR R3 [  R0 ] + 4
 00000A98	     1E52	SUBS R2 R2 #1
 00000A9A	     D1F9	BNE #-14, goes to  00000A90
 00000A9C	     9806	LDR R0 [ SP + 24 ]
 00000A9E	     1C40	ADDS R0 R0 #1
 00000AA0	     9006	STR R0 [ SP + 24 ]
 00000AA2	     E7D3	B #-90, goes to  00000A4C
 00000AA4	     9804	LDR R0 [ SP + 16 ]
 00000AA6	     9006	STR R0 [ SP + 24 ]
 00000AA8	     9801	LDR R0 [ SP + 4 ]
 00000AAA	     1D00	ADDS R0 R0 #4
 00000AAC	     6801	LDR R1 [ R0 + 0 ]
 00000AAE	     1E49	SUBS R1 R1 #1
 00000AB0	     6001	STR R1 [  R0 + 0 ]
 00000AB2	     9806	LDR R0 [ SP + 24 ]
 00000AB4	     9901	LDR R1 [ SP + 4 ]
 00000AB6	     6849	LDR R1 [ R1 + 4 ]
 00000AB8	     4288	CMP R0 R1
 00000ABA	 F2808020	BGE #64, goes to  00000AFE
 00000ABE	     9806	LDR R0 [ SP + 24 ]
 00000AC0	     2818	CMP R0 #24
 00000AC2	     BF28	IT CS
 00000AC4	 EC0323B1	TrapCS 1 at pos 6459
 00000AC8	     2128	MOVS R1 #40
 00000ACA	     4348	MULS R0 R1 R0
 00000ACC	     9901	LDR R1 [ SP + 4 ]
 00000ACE	     1808	ADDS R0 R1 R0
 00000AD0	     9906	LDR R1 [ SP + 24 ]
 00000AD2	     1C49	ADDS R1 R1 #1
 00000AD4	     2918	CMP R1 #24
 00000AD6	     BF28	IT CS
 00000AD8	 EC032471	TrapCS 1 at pos 6471
 00000ADC	     2228	MOVS R2 #40
 00000ADE	     4351	MULS R1 R2 R1
 00000AE0	     9A01	LDR R2 [ SP + 4 ]
 00000AE2	     1851	ADDS R1 R2 R1
 00000AE4	     3040	ADDS R0 R0 #64
 00000AE6	     3140	ADDS R1 R1 #64
 00000AE8	     220A	MOVS R2 #10
 00000AEA	 F8513B04	LDR R3 [ R1 ] + 4
 00000AEE	 F8403B04	STR R3 [  R0 ] + 4
 00000AF2	     1E52	SUBS R2 R2 #1
 00000AF4	     D1F9	BNE #-14, goes to  00000AEA
 00000AF6	     9806	LDR R0 [ SP + 24 ]
 00000AF8	     1C40	ADDS R0 R0 #1
 00000AFA	     9006	STR R0 [ SP + 24 ]
 00000AFC	     E7D9	B #-78, goes to  00000AB2
 00000AFE	     9809	LDR R0 [ SP + 36 ]
 00000B00	     2800	CMP R0 #0
 00000B02	     BF08	IT EQ
 00000B04	 EC032614	TrapEQ 4 at pos 6497
 00000B08	     2118	MOVS R1 #24
 00000B0A	     6041	STR R1 [  R0 + 4 ]
 00000B0C	     9801	LDR R0 [ SP + 4 ]
 00000B0E	     6840	LDR R0 [ R0 + 4 ]
 00000B10	     280C	CMP R0 #12
 00000B12	     BFB4	ITE LT
 00000B14	     2001	MOVLT R0 #1
 00000B16	     2000	MOVGE R0 #0
 00000B18	     9905	LDR R1 [ SP + 20 ]
 00000B1A	     7008	STRB R0 [ R1 + 0 ]
 00000B1C	     9803	LDR R0 [ SP + 12 ]
 00000B1E	     9909	LDR R1 [ SP + 36 ]
 00000B20	     2900	CMP R1 #0
 00000B22	     BF08	IT EQ
 00000B24	 EC033234	TrapEQ 4 at pos 6563
 00000B28	 11400080	BL Mod(  1) proc(20)
 00000B2C	 F000B9AA	B #852, goes to  00000E84
 00000B30	     9804	LDR R0 [ SP + 16 ]
 00000B32	     1E40	SUBS R0 R0 #1
 00000B34	     9004	STR R0 [ SP + 16 ]
 00000B36	     9804	LDR R0 [ SP + 16 ]
 00000B38	     2800	CMP R0 #0
 00000B3A	 F0408005	BNE #10, goes to  00000B48
 00000B3E	     9801	LDR R0 [ SP + 4 ]
 00000B40	     6880	LDR R0 [ R0 + 8 ]
 00000B42	     9008	STR R0 [ SP + 32 ]
 00000B44	 F000B80C	B #24, goes to  00000B60
 00000B48	     9804	LDR R0 [ SP + 16 ]
 00000B4A	     1E40	SUBS R0 R0 #1
 00000B4C	     2818	CMP R0 #24
 00000B4E	     BF28	IT CS
 00000B50	 EC0340A1	TrapCS 1 at pos 6666
 00000B54	     2128	MOVS R1 #40
 00000B56	     4348	MULS R0 R1 R0
 00000B58	     9901	LDR R1 [ SP + 4 ]
 00000B5A	     1808	ADDS R0 R1 R0
 00000B5C	     6E40	LDR R0 [ R0 + 100 ]
 00000B5E	     9008	STR R0 [ SP + 32 ]
 00000B60	     9808	LDR R0 [ SP + 32 ]
 00000B62	     990A	LDR R1 [ SP + 40 ]
 00000B64	     2900	CMP R1 #0
 00000B66	     BF08	IT EQ
 00000B68	 EC034334	TrapEQ 4 at pos 6707
 00000B6C	 11300022	BL Mod(  1) proc(19)
 00000B70	     980A	LDR R0 [ SP + 40 ]
 00000B72	     2800	CMP R0 #0
 00000B74	     BF08	IT EQ
 00000B76	 EC034424	TrapEQ 4 at pos 6722
 00000B7A	     6800	LDR R0 [ R0 + 0 ]
 00000B7C	 F24A318D	MOV R1 #41869
 00000B80	 F6C9311E	MOVT R1 #39710
 00000B84	     4288	CMP R0 R1
 00000B86	     BF18	IT NE
 00000B88	 EC0344E7	TrapNE 7 at pos 6734
 00000B8C	     980A	LDR R0 [ SP + 40 ]
 00000B8E	     2800	CMP R0 #0
 00000B90	     BF08	IT EQ
 00000B92	 EC0345E4	TrapEQ 4 at pos 6750
 00000B96	     6840	LDR R0 [ R0 + 4 ]
 00000B98	     380C	SUBS R0 R0 #12
 00000B9A	     1C40	ADDS R0 R0 #1
 00000B9C	     1040	ASRS R0 R0 #1
 00000B9E	     9007	STR R0 [ SP + 28 ]
 00000BA0	     9807	LDR R0 [ SP + 28 ]
 00000BA2	     2800	CMP R0 #0
 00000BA4	 F34080FB	BLE #502, goes to  00000D9E
 00000BA8	     200B	MOVS R0 #11
 00000BAA	     9006	STR R0 [ SP + 24 ]
 00000BAC	     9806	LDR R0 [ SP + 24 ]
 00000BAE	     2800	CMP R0 #0
 00000BB0	 F3408029	BLE #82, goes to  00000C06
 00000BB4	     9806	LDR R0 [ SP + 24 ]
 00000BB6	     1E40	SUBS R0 R0 #1
 00000BB8	     9006	STR R0 [ SP + 24 ]
 00000BBA	     9809	LDR R0 [ SP + 36 ]
 00000BBC	     2800	CMP R0 #0
 00000BBE	     BF08	IT EQ
 00000BC0	 EC0355C4	TrapEQ 4 at pos 6876
 00000BC4	     9906	LDR R1 [ SP + 24 ]
 00000BC6	     9A07	LDR R2 [ SP + 28 ]
 00000BC8	     1889	ADDS R1 R1 R2
 00000BCA	     2918	CMP R1 #24
 00000BCC	     BF28	IT CS
 00000BCE	 EC035611	TrapCS 1 at pos 6881
 00000BD2	     2228	MOVS R2 #40
 00000BD4	     4351	MULS R1 R2 R1
 00000BD6	     1840	ADDS R0 R0 R1
 00000BD8	     9909	LDR R1 [ SP + 36 ]
 00000BDA	     2900	CMP R1 #0
 00000BDC	     BF08	IT EQ
 00000BDE	 EC035684	TrapEQ 4 at pos 6888
 00000BE2	     9A06	LDR R2 [ SP + 24 ]
 00000BE4	     2A18	CMP R2 #24
 00000BE6	     BF28	IT CS
 00000BE8	 EC0356B1	TrapCS 1 at pos 6891
 00000BEC	     2328	MOVS R3 #40
 00000BEE	     435A	MULS R2 R3 R2
 00000BF0	     1889	ADDS R1 R1 R2
 00000BF2	     3040	ADDS R0 R0 #64
 00000BF4	     3140	ADDS R1 R1 #64
 00000BF6	     220A	MOVS R2 #10
 00000BF8	 F8513B04	LDR R3 [ R1 ] + 4
 00000BFC	 F8403B04	STR R3 [  R0 ] + 4
 00000C00	     1E52	SUBS R2 R2 #1
 00000C02	     D1F9	BNE #-14, goes to  00000BF8
 00000C04	     E7D2	B #-92, goes to  00000BAC
 00000C06	     9807	LDR R0 [ SP + 28 ]
 00000C08	     1E40	SUBS R0 R0 #1
 00000C0A	     9006	STR R0 [ SP + 24 ]
 00000C0C	     9809	LDR R0 [ SP + 36 ]
 00000C0E	     2800	CMP R0 #0
 00000C10	     BF08	IT EQ
 00000C12	 EC036074	TrapEQ 4 at pos 6919
 00000C16	     9906	LDR R1 [ SP + 24 ]
 00000C18	     2918	CMP R1 #24
 00000C1A	     BF28	IT CS
 00000C1C	 EC0360A1	TrapCS 1 at pos 6922
 00000C20	     2228	MOVS R2 #40
 00000C22	     4351	MULS R1 R2 R1
 00000C24	     1840	ADDS R0 R0 R1
 00000C26	     9904	LDR R1 [ SP + 16 ]
 00000C28	     2918	CMP R1 #24
 00000C2A	     BF28	IT CS
 00000C2C	 EC036141	TrapCS 1 at pos 6932
 00000C30	     2228	MOVS R2 #40
 00000C32	     4351	MULS R1 R2 R1
 00000C34	     9A01	LDR R2 [ SP + 4 ]
 00000C36	     1851	ADDS R1 R2 R1
 00000C38	     3040	ADDS R0 R0 #64
 00000C3A	     3140	ADDS R1 R1 #64
 00000C3C	     220A	MOVS R2 #10
 00000C3E	 F8513B04	LDR R3 [ R1 ] + 4
 00000C42	 F8403B04	STR R3 [  R0 ] + 4
 00000C46	     1E52	SUBS R2 R2 #1
 00000C48	     D1F9	BNE #-14, goes to  00000C3E
 00000C4A	     9809	LDR R0 [ SP + 36 ]
 00000C4C	     2800	CMP R0 #0
 00000C4E	     BF08	IT EQ
 00000C50	 EC036194	TrapEQ 4 at pos 6937
 00000C54	     9906	LDR R1 [ SP + 24 ]
 00000C56	     2918	CMP R1 #24
 00000C58	     BF28	IT CS
 00000C5A	 EC0361C1	TrapCS 1 at pos 6940
 00000C5E	     2228	MOVS R2 #40
 00000C60	     4351	MULS R1 R2 R1
 00000C62	     1840	ADDS R0 R0 R1
 00000C64	     9909	LDR R1 [ SP + 36 ]
 00000C66	     2900	CMP R1 #0
 00000C68	     BF08	IT EQ
 00000C6A	 EC036264	TrapEQ 4 at pos 6950
 00000C6E	     6889	LDR R1 [ R1 + 8 ]
 00000C70	     6641	STR R1 [  R0 + 100 ]
 00000C72	     980A	LDR R0 [ SP + 40 ]
 00000C74	     2800	CMP R0 #0
 00000C76	     BF08	IT EQ
 00000C78	 EC0365C4	TrapEQ 4 at pos 7004
 00000C7C	     990A	LDR R1 [ SP + 40 ]
 00000C7E	     2900	CMP R1 #0
 00000C80	     BF08	IT EQ
 00000C82	 EC036634	TrapEQ 4 at pos 7011
 00000C86	     6849	LDR R1 [ R1 + 4 ]
 00000C88	     9A07	LDR R2 [ SP + 28 ]
 00000C8A	     1A89	SUBS R1 R1 R2
 00000C8C	     6041	STR R1 [  R0 + 4 ]
 00000C8E	     9806	LDR R0 [ SP + 24 ]
 00000C90	     2800	CMP R0 #0
 00000C92	 F340802F	BLE #94, goes to  00000CF4
 00000C96	     9806	LDR R0 [ SP + 24 ]
 00000C98	     1E40	SUBS R0 R0 #1
 00000C9A	     9006	STR R0 [ SP + 24 ]
 00000C9C	     9809	LDR R0 [ SP + 36 ]
 00000C9E	     2800	CMP R0 #0
 00000CA0	     BF08	IT EQ
 00000CA2	 EC0370B4	TrapEQ 4 at pos 7051
 00000CA6	     9906	LDR R1 [ SP + 24 ]
 00000CA8	     2918	CMP R1 #24
 00000CAA	     BF28	IT CS
 00000CAC	 EC0370E1	TrapCS 1 at pos 7054
 00000CB0	     2228	MOVS R2 #40
 00000CB2	     4351	MULS R1 R2 R1
 00000CB4	     1840	ADDS R0 R0 R1
 00000CB6	     990A	LDR R1 [ SP + 40 ]
 00000CB8	     2900	CMP R1 #0
 00000CBA	     BF08	IT EQ
 00000CBC	 EC037154	TrapEQ 4 at pos 7061
 00000CC0	     9A0A	LDR R2 [ SP + 40 ]
 00000CC2	     2A00	CMP R2 #0
 00000CC4	     BF08	IT EQ
 00000CC6	 EC0371B4	TrapEQ 4 at pos 7067
 00000CCA	     9B06	LDR R3 [ SP + 24 ]
 00000CCC	     6852	LDR R2 [ R2 + 4 ]
 00000CCE	     189A	ADDS R2 R3 R2
 00000CD0	     1C52	ADDS R2 R2 #1
 00000CD2	     2A18	CMP R2 #24
 00000CD4	     BF28	IT CS
 00000CD6	 EC0371E1	TrapCS 1 at pos 7070
 00000CDA	     2328	MOVS R3 #40
 00000CDC	     435A	MULS R2 R3 R2
 00000CDE	     1889	ADDS R1 R1 R2
 00000CE0	     3040	ADDS R0 R0 #64
 00000CE2	     3140	ADDS R1 R1 #64
 00000CE4	     220A	MOVS R2 #10
 00000CE6	 F8513B04	LDR R3 [ R1 ] + 4
 00000CEA	 F8403B04	STR R3 [  R0 ] + 4
 00000CEE	     1E52	SUBS R2 R2 #1
 00000CF0	     D1F9	BNE #-14, goes to  00000CE6
 00000CF2	     E7CC	B #-104, goes to  00000C8E
 00000CF4	     9804	LDR R0 [ SP + 16 ]
 00000CF6	     2818	CMP R0 #24
 00000CF8	     BF28	IT CS
 00000CFA	 EC037331	TrapCS 1 at pos 7091
 00000CFE	     2128	MOVS R1 #40
 00000D00	     4348	MULS R0 R1 R0
 00000D02	     9901	LDR R1 [ SP + 4 ]
 00000D04	     1808	ADDS R0 R1 R0
 00000D06	     990A	LDR R1 [ SP + 40 ]
 00000D08	     2900	CMP R1 #0
 00000D0A	     BF08	IT EQ
 00000D0C	 EC0373A4	TrapEQ 4 at pos 7098
 00000D10	     9A0A	LDR R2 [ SP + 40 ]
 00000D12	     2A00	CMP R2 #0
 00000D14	     BF08	IT EQ
 00000D16	 EC0373E4	TrapEQ 4 at pos 7102
 00000D1A	     6852	LDR R2 [ R2 + 4 ]
 00000D1C	     2A18	CMP R2 #24
 00000D1E	     BF28	IT CS
 00000D20	 EC0373F1	TrapCS 1 at pos 7103
 00000D24	     2328	MOVS R3 #40
 00000D26	     435A	MULS R2 R3 R2
 00000D28	     1889	ADDS R1 R1 R2
 00000D2A	     3040	ADDS R0 R0 #64
 00000D2C	     3140	ADDS R1 R1 #64
 00000D2E	     220A	MOVS R2 #10
 00000D30	 F8513B04	LDR R3 [ R1 ] + 4
 00000D34	 F8403B04	STR R3 [  R0 ] + 4
 00000D38	     1E52	SUBS R2 R2 #1
 00000D3A	     D1F9	BNE #-14, goes to  00000D30
 00000D3C	     9809	LDR R0 [ SP + 36 ]
 00000D3E	     2800	CMP R0 #0
 00000D40	     BF08	IT EQ
 00000D42	 EC037454	TrapEQ 4 at pos 7109
 00000D46	     9904	LDR R1 [ SP + 16 ]
 00000D48	     2918	CMP R1 #24
 00000D4A	     BF28	IT CS
 00000D4C	 EC0374F1	TrapCS 1 at pos 7119
 00000D50	     2228	MOVS R2 #40
 00000D52	     4351	MULS R1 R2 R1
 00000D54	     9A01	LDR R2 [ SP + 4 ]
 00000D56	     1851	ADDS R1 R2 R1
 00000D58	     6E49	LDR R1 [ R1 + 100 ]
 00000D5A	     6081	STR R1 [  R0 + 8 ]
 00000D5C	     9804	LDR R0 [ SP + 16 ]
 00000D5E	     2818	CMP R0 #24
 00000D60	     BF28	IT CS
 00000D62	 EC037611	TrapCS 1 at pos 7137
 00000D66	     2128	MOVS R1 #40
 00000D68	     4348	MULS R0 R1 R0
 00000D6A	     9901	LDR R1 [ SP + 4 ]
 00000D6C	     1808	ADDS R0 R1 R0
 00000D6E	     9903	LDR R1 [ SP + 12 ]
 00000D70	     6641	STR R1 [  R0 + 100 ]
 00000D72	     9809	LDR R0 [ SP + 36 ]
 00000D74	     2800	CMP R0 #0
 00000D76	     BF08	IT EQ
 00000D78	 EC037704	TrapEQ 4 at pos 7152
 00000D7C	     210B	MOVS R1 #11
 00000D7E	     9A07	LDR R2 [ SP + 28 ]
 00000D80	     1889	ADDS R1 R1 R2
 00000D82	     6041	STR R1 [  R0 + 4 ]
 00000D84	     2000	MOVS R0 #0
 00000D86	     9905	LDR R1 [ SP + 20 ]
 00000D88	     7008	STRB R0 [ R1 + 0 ]
 00000D8A	     9803	LDR R0 [ SP + 12 ]
 00000D8C	     9909	LDR R1 [ SP + 36 ]
 00000D8E	     2900	CMP R1 #0
 00000D90	     BF08	IT EQ
 00000D92	 EC038294	TrapEQ 4 at pos 7209
 00000D96	 11400115	BL Mod(  1) proc(20)
 00000D9A	 F000B86B	B #214, goes to  00000E74
 00000D9E	     9804	LDR R0 [ SP + 16 ]
 00000DA0	     2818	CMP R0 #24
 00000DA2	     BF28	IT CS
 00000DA4	 EC038661	TrapCS 1 at pos 7270
 00000DA8	     2128	MOVS R1 #40
 00000DAA	     4348	MULS R0 R1 R0
 00000DAC	     9901	LDR R1 [ SP + 4 ]
 00000DAE	     1808	ADDS R0 R1 R0
 00000DB0	     9909	LDR R1 [ SP + 36 ]
 00000DB2	     2900	CMP R1 #0
 00000DB4	     BF08	IT EQ
 00000DB6	 EC038704	TrapEQ 4 at pos 7280
 00000DBA	     6889	LDR R1 [ R1 + 8 ]
 00000DBC	     6641	STR R1 [  R0 + 100 ]
 00000DBE	     980A	LDR R0 [ SP + 40 ]
 00000DC0	     2800	CMP R0 #0
 00000DC2	     BF08	IT EQ
 00000DC4	 EC038754	TrapEQ 4 at pos 7285
 00000DC8	     9904	LDR R1 [ SP + 16 ]
 00000DCA	     2918	CMP R1 #24
 00000DCC	     BF28	IT CS
 00000DCE	 EC039021	TrapCS 1 at pos 7298
 00000DD2	     2228	MOVS R2 #40
 00000DD4	     4351	MULS R1 R2 R1
 00000DD6	     9A01	LDR R2 [ SP + 4 ]
 00000DD8	     1851	ADDS R1 R2 R1
 00000DDA	 F5107008	ADDS R0 R0 #544
 00000DDE	     3140	ADDS R1 R1 #64
 00000DE0	     220A	MOVS R2 #10
 00000DE2	 F8513B04	LDR R3 [ R1 ] + 4
 00000DE6	 F8403B04	STR R3 [  R0 ] + 4
 00000DEA	     1E52	SUBS R2 R2 #1
 00000DEC	     D1F9	BNE #-14, goes to  00000DE2
 00000DEE	     2000	MOVS R0 #0
 00000DF0	     9006	STR R0 [ SP + 24 ]
 00000DF2	     9806	LDR R0 [ SP + 24 ]
 00000DF4	     280B	CMP R0 #11
 00000DF6	 F2808029	BGE #82, goes to  00000E4C
 00000DFA	     980A	LDR R0 [ SP + 40 ]
 00000DFC	     2800	CMP R0 #0
 00000DFE	     BF08	IT EQ
 00000E00	 EC039284	TrapEQ 4 at pos 7336
 00000E04	     9906	LDR R1 [ SP + 24 ]
 00000E06	     310C	ADDS R1 R1 #12
 00000E08	     1C49	ADDS R1 R1 #1
 00000E0A	     2918	CMP R1 #24
 00000E0C	     BF28	IT CS
 00000E0E	 EC0392F1	TrapCS 1 at pos 7343
 00000E12	     2228	MOVS R2 #40
 00000E14	     4351	MULS R1 R2 R1
 00000E16	     1840	ADDS R0 R0 R1
 00000E18	     9909	LDR R1 [ SP + 36 ]
 00000E1A	     2900	CMP R1 #0
 00000E1C	     BF08	IT EQ
 00000E1E	 EC039364	TrapEQ 4 at pos 7350
 00000E22	     9A06	LDR R2 [ SP + 24 ]
 00000E24	     2A18	CMP R2 #24
 00000E26	     BF28	IT CS
 00000E28	 EC039391	TrapCS 1 at pos 7353
 00000E2C	     2328	MOVS R3 #40
 00000E2E	     435A	MULS R2 R3 R2
 00000E30	     1889	ADDS R1 R1 R2
 00000E32	     3040	ADDS R0 R0 #64
 00000E34	     3140	ADDS R1 R1 #64
 00000E36	     220A	MOVS R2 #10
 00000E38	 F8513B04	LDR R3 [ R1 ] + 4
 00000E3C	 F8403B04	STR R3 [  R0 ] + 4
 00000E40	     1E52	SUBS R2 R2 #1
 00000E42	     D1F9	BNE #-14, goes to  00000E38
 00000E44	     9806	LDR R0 [ SP + 24 ]
 00000E46	     1C40	ADDS R0 R0 #1
 00000E48	     9006	STR R0 [ SP + 24 ]
 00000E4A	     E7D2	B #-92, goes to  00000DF2
 00000E4C	     980A	LDR R0 [ SP + 40 ]
 00000E4E	     2800	CMP R0 #0
 00000E50	     BF08	IT EQ
 00000E52	 EC039534	TrapEQ 4 at pos 7379
 00000E56	     2118	MOVS R1 #24
 00000E58	     6041	STR R1 [  R0 + 4 ]
 00000E5A	     9801	LDR R0 [ SP + 4 ]
 00000E5C	     1D00	ADDS R0 R0 #4
 00000E5E	     6801	LDR R1 [ R0 + 0 ]
 00000E60	     1E49	SUBS R1 R1 #1
 00000E62	     6001	STR R1 [  R0 + 0 ]
 00000E64	     9801	LDR R0 [ SP + 4 ]
 00000E66	     6840	LDR R0 [ R0 + 4 ]
 00000E68	     280C	CMP R0 #12
 00000E6A	     BFB4	ITE LT
 00000E6C	     2001	MOVLT R0 #1
 00000E6E	     2000	MOVGE R0 #0
 00000E70	     9905	LDR R1 [ SP + 20 ]
 00000E72	     7008	STRB R0 [ R1 + 0 ]
 00000E74	     9808	LDR R0 [ SP + 32 ]
 00000E76	     990A	LDR R1 [ SP + 40 ]
 00000E78	     2900	CMP R1 #0
 00000E7A	     BF08	IT EQ
 00000E7C	 EC03A1F4	TrapEQ 4 at pos 7455
 00000E80	 11400075	BL Mod(  1) proc(20)
 00000E84	 F85DEB04	LDR LR [ SP ] + 4
 00000E88	     B00A	ADD SP SP #40
 00000E8A	     4770	BX LR
 00000E8C	 F000B8C4	B #392, goes to  00001018
 00000E90	     B082	SUB SP SP #8
 00000E92	     B41F	PUSH R0 R1 R2 R3 R4
 00000E94	     B500	PUSH LR
 00000E96	     A807	ADD R0 SP #28
 00000E98	 10000360	MOV R1 lower 16-bits base(0), next at  000007D8
 00000E9C	 00000028	MOVT R1 higher 16-bits const + 40
 00000EA0	     DF00	SVC #0
 00000EA2	     9804	LDR R0 [ SP + 16 ]
 00000EA4	     9907	LDR R1 [ SP + 28 ]
 00000EA6	     2900	CMP R1 #0
 00000EA8	     BF08	IT EQ
 00000EAA	 EC03E544	TrapEQ 4 at pos 8020
 00000EAE	 11300017	BL Mod(  1) proc(19)
 00000EB2	     9807	LDR R0 [ SP + 28 ]
 00000EB4	     2800	CMP R0 #0
 00000EB6	     BF08	IT EQ
 00000EB8	 EC03E634	TrapEQ 4 at pos 8035
 00000EBC	     6800	LDR R0 [ R0 + 0 ]
 00000EBE	 F24A318D	MOV R1 #41869
 00000EC2	 F6C9311E	MOVT R1 #39710
 00000EC6	     4288	CMP R0 R1
 00000EC8	     BF18	IT NE
 00000ECA	 EC03E6F7	TrapNE 7 at pos 8047
 00000ECE	     9807	LDR R0 [ SP + 28 ]
 00000ED0	     2800	CMP R0 #0
 00000ED2	     BF08	IT EQ
 00000ED4	 EC03E7B4	TrapEQ 4 at pos 8059
 00000ED8	     9907	LDR R1 [ SP + 28 ]
 00000EDA	     2900	CMP R1 #0
 00000EDC	     BF08	IT EQ
 00000EDE	 EC03E7F4	TrapEQ 4 at pos 8063
 00000EE2	     6849	LDR R1 [ R1 + 4 ]
 00000EE4	     1E49	SUBS R1 R1 #1
 00000EE6	     2918	CMP R1 #24
 00000EE8	     BF28	IT CS
 00000EEA	 EC03F021	TrapCS 1 at pos 8066
 00000EEE	     2228	MOVS R2 #40
 00000EF0	     4351	MULS R1 R2 R1
 00000EF2	     1840	ADDS R0 R0 R1
 00000EF4	     6E40	LDR R0 [ R0 + 100 ]
 00000EF6	     9006	STR R0 [ SP + 24 ]
 00000EF8	     9806	LDR R0 [ SP + 24 ]
 00000EFA	     2800	CMP R0 #0
 00000EFC	 F0008029	BEQ #82, goes to  00000F52
 00000F00	     9801	LDR R0 [ SP + 4 ]
 00000F02	     9902	LDR R1 [ SP + 8 ]
 00000F04	     9A03	LDR R2 [ SP + 12 ]
 00000F06	     9B06	LDR R3 [ SP + 24 ]
 00000F08	     9C05	LDR R4 [ SP + 20 ]
 00000F0A	 F7FFFFC1	BL #-126, goes to  00000E90
 00000F0E	     9805	LDR R0 [ SP + 20 ]
 00000F10	     7800	LDRB R0 [ R0 + 0 ]
 00000F12	     2800	CMP R0 #0
 00000F14	 F000801B	BEQ #54, goes to  00000F4E
 00000F18	     9807	LDR R0 [ SP + 28 ]
 00000F1A	     2800	CMP R0 #0
 00000F1C	     BF08	IT EQ
 00000F1E	 EC03F504	TrapEQ 4 at pos 8144
 00000F22	 10000045	MOV R1 lower 16-bits base(0), next at  00000E98
 00000F26	 00000028	MOVT R1 higher 16-bits const + 40
 00000F2A	     9A06	LDR R2 [ SP + 24 ]
 00000F2C	     9B07	LDR R3 [ SP + 28 ]
 00000F2E	     2B00	CMP R3 #0
 00000F30	     BF08	IT EQ
 00000F32	 EC03F5A4	TrapEQ 4 at pos 8154
 00000F36	     685B	LDR R3 [ R3 + 4 ]
 00000F38	     9C05	LDR R4 [ SP + 20 ]
 00000F3A	 F7FFFC43	BL #-1914, goes to  000007C4
 00000F3E	     9804	LDR R0 [ SP + 16 ]
 00000F40	     9907	LDR R1 [ SP + 28 ]
 00000F42	     2900	CMP R1 #0
 00000F44	     BF08	IT EQ
 00000F46	 EC03F7A4	TrapEQ 4 at pos 8186
 00000F4A	 1140004E	BL Mod(  1) proc(20)
 00000F4E	 F000B85F	B #190, goes to  00001010
 00000F52	     9807	LDR R0 [ SP + 28 ]
 00000F54	     2800	CMP R0 #0
 00000F56	     BF08	IT EQ
 00000F58	 EC040154	TrapEQ 4 at pos 8213
 00000F5C	     9907	LDR R1 [ SP + 28 ]
 00000F5E	     2900	CMP R1 #0
 00000F60	     BF08	IT EQ
 00000F62	 EC040194	TrapEQ 4 at pos 8217
 00000F66	     6849	LDR R1 [ R1 + 4 ]
 00000F68	     1E49	SUBS R1 R1 #1
 00000F6A	     2918	CMP R1 #24
 00000F6C	     BF28	IT CS
 00000F6E	 EC0401C1	TrapCS 1 at pos 8220
 00000F72	     2228	MOVS R2 #40
 00000F74	     4351	MULS R1 R2 R1
 00000F76	     1840	ADDS R0 R0 R1
 00000F78	     9903	LDR R1 [ SP + 12 ]
 00000F7A	     2918	CMP R1 #24
 00000F7C	     BF28	IT CS
 00000F7E	 EC040281	TrapCS 1 at pos 8232
 00000F82	     2228	MOVS R2 #40
 00000F84	     4351	MULS R1 R2 R1
 00000F86	     9A01	LDR R2 [ SP + 4 ]
 00000F88	     1851	ADDS R1 R2 R1
 00000F8A	     6E49	LDR R1 [ R1 + 100 ]
 00000F8C	     6641	STR R1 [  R0 + 100 ]
 00000F8E	     9803	LDR R0 [ SP + 12 ]
 00000F90	     2818	CMP R0 #24
 00000F92	     BF28	IT CS
 00000F94	 EC040321	TrapCS 1 at pos 8242
 00000F98	     2128	MOVS R1 #40
 00000F9A	     4348	MULS R0 R1 R0
 00000F9C	     9901	LDR R1 [ SP + 4 ]
 00000F9E	     1808	ADDS R0 R1 R0
 00000FA0	     9907	LDR R1 [ SP + 28 ]
 00000FA2	     2900	CMP R1 #0
 00000FA4	     BF08	IT EQ
 00000FA6	 EC040394	TrapEQ 4 at pos 8249
 00000FAA	     9A07	LDR R2 [ SP + 28 ]
 00000FAC	     2A00	CMP R2 #0
 00000FAE	     BF08	IT EQ
 00000FB0	 EC0403D4	TrapEQ 4 at pos 8253
 00000FB4	     6852	LDR R2 [ R2 + 4 ]
 00000FB6	     1E52	SUBS R2 R2 #1
 00000FB8	     2A18	CMP R2 #24
 00000FBA	     BF28	IT CS
 00000FBC	 EC040401	TrapCS 1 at pos 8256
 00000FC0	     2328	MOVS R3 #40
 00000FC2	     435A	MULS R2 R3 R2
 00000FC4	     1889	ADDS R1 R1 R2
 00000FC6	     3040	ADDS R0 R0 #64
 00000FC8	     3140	ADDS R1 R1 #64
 00000FCA	     220A	MOVS R2 #10
 00000FCC	 F8513B04	LDR R3 [ R1 ] + 4
 00000FD0	 F8403B04	STR R3 [  R0 ] + 4
 00000FD4	     1E52	SUBS R2 R2 #1
 00000FD6	     D1F9	BNE #-14, goes to  00000FCC
 00000FD8	     9807	LDR R0 [ SP + 28 ]
 00000FDA	     2800	CMP R0 #0
 00000FDC	     BF08	IT EQ
 00000FDE	 EC040514	TrapEQ 4 at pos 8273
 00000FE2	     6841	LDR R1 [ R0 + 4 ]
 00000FE4	     1E49	SUBS R1 R1 #1
 00000FE6	     6041	STR R1 [  R0 + 4 ]
 00000FE8	     9807	LDR R0 [ SP + 28 ]
 00000FEA	     2800	CMP R0 #0
 00000FEC	     BF08	IT EQ
 00000FEE	 EC0405C4	TrapEQ 4 at pos 8284
 00000FF2	     6840	LDR R0 [ R0 + 4 ]
 00000FF4	     280C	CMP R0 #12
 00000FF6	     BFB4	ITE LT
 00000FF8	     2001	MOVLT R0 #1
 00000FFA	     2000	MOVGE R0 #0
 00000FFC	     9905	LDR R1 [ SP + 20 ]
 00000FFE	     7008	STRB R0 [ R1 + 0 ]
 00001000	     9804	LDR R0 [ SP + 16 ]
 00001002	     9907	LDR R1 [ SP + 28 ]
 00001004	     2900	CMP R1 #0
 00001006	     BF08	IT EQ
 00001008	 EC0407C4	TrapEQ 4 at pos 8316
 0000100C	 11400061	BL Mod(  1) proc(20)
 00001010	 F85DEB04	LDR LR [ SP ] + 4
 00001014	     B007	ADD SP SP #28
 00001016	     4770	BX LR
 00001018	     B085	SUB SP SP #20
 0000101A	     B40F	PUSH R0 R1 R2 R3
 0000101C	     B500	PUSH LR
 0000101E	     A809	ADD R0 SP #36
 00001020	 1000007F	MOV R1 lower 16-bits base(0), next at  00000F22
 00001024	 00000028	MOVT R1 higher 16-bits const + 40
 00001028	     DF00	SVC #0
 0000102A	     9802	LDR R0 [ SP + 8 ]
 0000102C	     9909	LDR R1 [ SP + 36 ]
 0000102E	     2900	CMP R1 #0
 00001030	     BF08	IT EQ
 00001032	 EC041464	TrapEQ 4 at pos 8390
 00001036	 11300015	BL Mod(  1) proc(19)
 0000103A	     9809	LDR R0 [ SP + 36 ]
 0000103C	     2800	CMP R0 #0
 0000103E	     BF08	IT EQ
 00001040	 EC041554	TrapEQ 4 at pos 8405
 00001044	     6800	LDR R0 [ R0 + 0 ]
 00001046	 F24A318D	MOV R1 #41869
 0000104A	 F6C9311E	MOVT R1 #39710
 0000104E	     4288	CMP R0 R1
 00001050	     BF18	IT NE
 00001052	 EC041617	TrapNE 7 at pos 8417
 00001056	     2000	MOVS R0 #0
 00001058	     9006	STR R0 [ SP + 24 ]
 0000105A	     9809	LDR R0 [ SP + 36 ]
 0000105C	     2800	CMP R0 #0
 0000105E	     BF08	IT EQ
 00001060	 EC041764	TrapEQ 4 at pos 8438
 00001064	     6840	LDR R0 [ R0 + 4 ]
 00001066	     9007	STR R0 [ SP + 28 ]
 00001068	     9806	LDR R0 [ SP + 24 ]
 0000106A	     9907	LDR R1 [ SP + 28 ]
 0000106C	     4288	CMP R0 R1
 0000106E	 F2808026	BGE #76, goes to  000010BE
 00001072	     9806	LDR R0 [ SP + 24 ]
 00001074	     9907	LDR R1 [ SP + 28 ]
 00001076	     1840	ADDS R0 R0 R1
 00001078	     1040	ASRS R0 R0 #1
 0000107A	     9005	STR R0 [ SP + 20 ]
 0000107C	     9809	LDR R0 [ SP + 36 ]
 0000107E	     2800	CMP R0 #0
 00001080	     BF08	IT EQ
 00001082	 EC042494	TrapEQ 4 at pos 8521
 00001086	     9905	LDR R1 [ SP + 20 ]
 00001088	     2918	CMP R1 #24
 0000108A	     BF28	IT CS
 0000108C	 EC0424C1	TrapCS 1 at pos 8524
 00001090	     2228	MOVS R2 #40
 00001092	     4351	MULS R1 R2 R1
 00001094	     1840	ADDS R0 R0 R1
 00001096	     9901	LDR R1 [ SP + 4 ]
 00001098	     3040	ADDS R0 R0 #64
 0000109A	 F8112B01	LDRB R2 [  R1 ] + 1
 0000109E	 F8103B01	LDRB R3 [  R0 ] + 1
 000010A2	     429A	CMP R2 R3
 000010A4	     D101	BNE #2, goes to  000010AA
 000010A6	     2A00	CMP R2 #0
 000010A8	     D1F7	BNE #-18, goes to  0000109A
 000010AA	 F3008004	BGT #8, goes to  000010B6
 000010AE	     9805	LDR R0 [ SP + 20 ]
 000010B0	     9007	STR R0 [ SP + 28 ]
 000010B2	 F000B803	B #6, goes to  000010BC
 000010B6	     9805	LDR R0 [ SP + 20 ]
 000010B8	     1C40	ADDS R0 R0 #1
 000010BA	     9006	STR R0 [ SP + 24 ]
 000010BC	     E7D4	B #-88, goes to  00001068
 000010BE	     9807	LDR R0 [ SP + 28 ]
 000010C0	     2800	CMP R0 #0
 000010C2	 F0408009	BNE #18, goes to  000010D8
 000010C6	     9809	LDR R0 [ SP + 36 ]
 000010C8	     2800	CMP R0 #0
 000010CA	     BF08	IT EQ
 000010CC	 EC043184	TrapEQ 4 at pos 8600
 000010D0	     6880	LDR R0 [ R0 + 8 ]
 000010D2	     9008	STR R0 [ SP + 32 ]
 000010D4	 F000B810	B #32, goes to  000010F8
 000010D8	     9809	LDR R0 [ SP + 36 ]
 000010DA	     2800	CMP R0 #0
 000010DC	     BF08	IT EQ
 000010DE	 EC043294	TrapEQ 4 at pos 8617
 000010E2	     9907	LDR R1 [ SP + 28 ]
 000010E4	     1E49	SUBS R1 R1 #1
 000010E6	     2918	CMP R1 #24
 000010E8	     BF28	IT CS
 000010EA	 EC0432E1	TrapCS 1 at pos 8622
 000010EE	     2228	MOVS R2 #40
 000010F0	     4351	MULS R1 R2 R1
 000010F2	     1840	ADDS R0 R0 R1
 000010F4	     6E40	LDR R0 [ R0 + 100 ]
 000010F6	     9008	STR R0 [ SP + 32 ]
 000010F8	     9809	LDR R0 [ SP + 36 ]
 000010FA	     2800	CMP R0 #0
 000010FC	     BF08	IT EQ
 000010FE	 EC043464	TrapEQ 4 at pos 8646
 00001102	     9907	LDR R1 [ SP + 28 ]
 00001104	     6840	LDR R0 [ R0 + 4 ]
 00001106	     4281	CMP R1 R0
 00001108	 F28080A2	BGE #324, goes to  00001250
 0000110C	     9809	LDR R0 [ SP + 36 ]
 0000110E	     2800	CMP R0 #0
 00001110	     BF08	IT EQ
 00001112	 EC043554	TrapEQ 4 at pos 8661
 00001116	     9907	LDR R1 [ SP + 28 ]
 00001118	     2918	CMP R1 #24
 0000111A	     BF28	IT CS
 0000111C	 EC043581	TrapCS 1 at pos 8664
 00001120	     2228	MOVS R2 #40
 00001122	     4351	MULS R1 R2 R1
 00001124	     1840	ADDS R0 R0 R1
 00001126	     9901	LDR R1 [ SP + 4 ]
 00001128	     3040	ADDS R0 R0 #64
 0000112A	 F8112B01	LDRB R2 [  R1 ] + 1
 0000112E	 F8103B01	LDRB R3 [  R0 ] + 1
 00001132	     429A	CMP R2 R3
 00001134	     D101	BNE #2, goes to  0000113A
 00001136	     2A00	CMP R2 #0
 00001138	     D1F7	BNE #-18, goes to  0000112A
 0000113A	 F0408089	BNE #274, goes to  00001250
 0000113E	     9809	LDR R0 [ SP + 36 ]
 00001140	     2800	CMP R0 #0
 00001142	     BF08	IT EQ
 00001144	 EC0440A4	TrapEQ 4 at pos 8714
 00001148	     9907	LDR R1 [ SP + 28 ]
 0000114A	     2918	CMP R1 #24
 0000114C	     BF28	IT CS
 0000114E	 EC0440D1	TrapCS 1 at pos 8717
 00001152	     2228	MOVS R2 #40
 00001154	     4351	MULS R1 R2 R1
 00001156	     1840	ADDS R0 R0 R1
 00001158	     6E00	LDR R0 [ R0 + 96 ]
 0000115A	     9904	LDR R1 [ SP + 16 ]
 0000115C	     6008	STR R0 [  R1 + 0 ]
 0000115E	     9808	LDR R0 [ SP + 32 ]
 00001160	     2800	CMP R0 #0
 00001162	 F040804A	BNE #148, goes to  000011FA
 00001166	     9809	LDR R0 [ SP + 36 ]
 00001168	     2800	CMP R0 #0
 0000116A	     BF08	IT EQ
 0000116C	 EC0444F4	TrapEQ 4 at pos 8783
 00001170	     6841	LDR R1 [ R0 + 4 ]
 00001172	     1E49	SUBS R1 R1 #1
 00001174	     6041	STR R1 [  R0 + 4 ]
 00001176	     9809	LDR R0 [ SP + 36 ]
 00001178	     2800	CMP R0 #0
 0000117A	     BF08	IT EQ
 0000117C	 EC0445A4	TrapEQ 4 at pos 8794
 00001180	     6840	LDR R0 [ R0 + 4 ]
 00001182	     280C	CMP R0 #12
 00001184	     BFB4	ITE LT
 00001186	     2001	MOVLT R0 #1
 00001188	     2000	MOVGE R0 #0
 0000118A	     9903	LDR R1 [ SP + 12 ]
 0000118C	     7008	STRB R0 [ R1 + 0 ]
 0000118E	     9807	LDR R0 [ SP + 28 ]
 00001190	     9005	STR R0 [ SP + 20 ]
 00001192	     9809	LDR R0 [ SP + 36 ]
 00001194	     2800	CMP R0 #0
 00001196	     BF08	IT EQ
 00001198	 EC0447D4	TrapEQ 4 at pos 8829
 0000119C	     9905	LDR R1 [ SP + 20 ]
 0000119E	     6840	LDR R0 [ R0 + 4 ]
 000011A0	     4281	CMP R1 R0
 000011A2	 F2808028	BGE #80, goes to  000011F6
 000011A6	     9809	LDR R0 [ SP + 36 ]
 000011A8	     2800	CMP R0 #0
 000011AA	     BF08	IT EQ
 000011AC	 EC045044	TrapEQ 4 at pos 8836
 000011B0	     9905	LDR R1 [ SP + 20 ]
 000011B2	     2918	CMP R1 #24
 000011B4	     BF28	IT CS
 000011B6	 EC045071	TrapCS 1 at pos 8839
 000011BA	     2228	MOVS R2 #40
 000011BC	     4351	MULS R1 R2 R1
 000011BE	     1840	ADDS R0 R0 R1
 000011C0	     9909	LDR R1 [ SP + 36 ]
 000011C2	     2900	CMP R1 #0
 000011C4	     BF08	IT EQ
 000011C6	 EC0450E4	TrapEQ 4 at pos 8846
 000011CA	     9A05	LDR R2 [ SP + 20 ]
 000011CC	     1C52	ADDS R2 R2 #1
 000011CE	     2A18	CMP R2 #24
 000011D0	     BF28	IT CS
 000011D2	 EC045131	TrapCS 1 at pos 8851
 000011D6	     2328	MOVS R3 #40
 000011D8	     435A	MULS R2 R3 R2
 000011DA	     1889	ADDS R1 R1 R2
 000011DC	     3040	ADDS R0 R0 #64
 000011DE	     3140	ADDS R1 R1 #64
 000011E0	     220A	MOVS R2 #10
 000011E2	 F8513B04	LDR R3 [ R1 ] + 4
 000011E6	 F8403B04	STR R3 [  R0 ] + 4
 000011EA	     1E52	SUBS R2 R2 #1
 000011EC	     D1F9	BNE #-14, goes to  000011E2
 000011EE	     9805	LDR R0 [ SP + 20 ]
 000011F0	     1C40	ADDS R0 R0 #1
 000011F2	     9005	STR R0 [ SP + 20 ]
 000011F4	     E7CD	B #-102, goes to  00001192
 000011F6	 F000B821	B #66, goes to  0000123C
 000011FA	     9809	LDR R0 [ SP + 36 ]
 000011FC	     2800	CMP R0 #0
 000011FE	     BF08	IT EQ
 00001200	 EC045324	TrapEQ 4 at pos 8882
 00001204	 100000F2	MOV R1 lower 16-bits base(0), next at  00001020
 00001208	 00000028	MOVT R1 higher 16-bits const + 40
 0000120C	     9A07	LDR R2 [ SP + 28 ]
 0000120E	     9B08	LDR R3 [ SP + 32 ]
 00001210	     9C03	LDR R4 [ SP + 12 ]
 00001212	 F7FFFE3D	BL #-902, goes to  00000E90
 00001216	     9803	LDR R0 [ SP + 12 ]
 00001218	     7800	LDRB R0 [ R0 + 0 ]
 0000121A	     2800	CMP R0 #0
 0000121C	 F000800E	BEQ #28, goes to  0000123C
 00001220	     9809	LDR R0 [ SP + 36 ]
 00001222	     2800	CMP R0 #0
 00001224	     BF08	IT EQ
 00001226	 EC0455F4	TrapEQ 4 at pos 8927
 0000122A	 10000013	MOV R1 lower 16-bits base(0), next at  00001204
 0000122E	 00000028	MOVT R1 higher 16-bits const + 40
 00001232	     9A08	LDR R2 [ SP + 32 ]
 00001234	     9B07	LDR R3 [ SP + 28 ]
 00001236	     9C03	LDR R4 [ SP + 12 ]
 00001238	 F7FFFAC4	BL #-2680, goes to  000007C4
 0000123C	     9802	LDR R0 [ SP + 8 ]
 0000123E	     9909	LDR R1 [ SP + 36 ]
 00001240	     2900	CMP R1 #0
 00001242	     BF08	IT EQ
 00001244	 EC0461C4	TrapEQ 4 at pos 8988
 00001248	 11400109	BL Mod(  1) proc(20)
 0000124C	 F000B82A	B #84, goes to  000012A4
 00001250	     9808	LDR R0 [ SP + 32 ]
 00001252	     2800	CMP R0 #0
 00001254	 F0008023	BEQ #70, goes to  0000129E
 00001258	     9801	LDR R0 [ SP + 4 ]
 0000125A	     9908	LDR R1 [ SP + 32 ]
 0000125C	     9A03	LDR R2 [ SP + 12 ]
 0000125E	     9B04	LDR R3 [ SP + 16 ]
 00001260	 F7FFFEDA	BL #-588, goes to  00001018
 00001264	     9803	LDR R0 [ SP + 12 ]
 00001266	     7800	LDRB R0 [ R0 + 0 ]
 00001268	     2800	CMP R0 #0
 0000126A	 F0008016	BEQ #44, goes to  0000129A
 0000126E	     9809	LDR R0 [ SP + 36 ]
 00001270	     2800	CMP R0 #0
 00001272	     BF08	IT EQ
 00001274	 EC046744	TrapEQ 4 at pos 9076
 00001278	 10000027	MOV R1 lower 16-bits base(0), next at  0000122A
 0000127C	 00000028	MOVT R1 higher 16-bits const + 40
 00001280	     9A08	LDR R2 [ SP + 32 ]
 00001282	     9B07	LDR R3 [ SP + 28 ]
 00001284	     9C03	LDR R4 [ SP + 12 ]
 00001286	 F7FFFA9D	BL #-2758, goes to  000007C4
 0000128A	     9802	LDR R0 [ SP + 8 ]
 0000128C	     9909	LDR R1 [ SP + 36 ]
 0000128E	     2900	CMP R1 #0
 00001290	     BF08	IT EQ
 00001292	 EC0471C4	TrapEQ 4 at pos 9116
 00001296	 11400027	BL Mod(  1) proc(20)
 0000129A	 F000B803	B #6, goes to  000012A4
 0000129E	     2000	MOVS R0 #0
 000012A0	     9904	LDR R1 [ SP + 16 ]
 000012A2	     6008	STR R0 [  R1 + 0 ]
 000012A4	 F85DEB04	LDR LR [ SP ] + 4
 000012A8	     B009	ADD SP SP #36
 000012AA	     4770	BX LR
 000012AC	     B083	SUB SP SP #12
 000012AE	     B403	PUSH R0 R1
 000012B0	     B500	PUSH LR
 000012B2	     A805	ADD R0 SP #20
 000012B4	 1000001E	MOV R1 lower 16-bits base(0), next at  00001278
 000012B8	 00000028	MOVT R1 higher 16-bits const + 40
 000012BC	     DF00	SVC #0
 000012BE	     2000	MOVS R0 #0
 000012C0	 F88D000C	STRB R0 [  SP + 12 ]
 000012C4	 11900017	BL Mod(  1) proc(25)
 000012C8	     9801	LDR R0 [ SP + 4 ]
 000012CA	     211D	MOVS R1 #29
 000012CC	     AA03	ADD R2 SP #12
 000012CE	     9B02	LDR R3 [ SP + 8 ]
 000012D0	 F7FFFEA2	BL #-700, goes to  00001018
 000012D4	 F89D000C	LDRB R0 [ SP + 12 ]
 000012D8	     2800	CMP R0 #0
 000012DA	 F000804D	BEQ #154, goes to  00001378
 000012DE	     201D	MOVS R0 #29
 000012E0	     9905	LDR R1 [ SP + 20 ]
 000012E2	     2900	CMP R1 #0
 000012E4	     BF08	IT EQ
 000012E6	 EC0496D4	TrapEQ 4 at pos 9453
 000012EA	 11300013	BL Mod(  1) proc(19)
 000012EE	     9805	LDR R0 [ SP + 20 ]
 000012F0	     2800	CMP R0 #0
 000012F2	     BF08	IT EQ
 000012F4	 EC0497C4	TrapEQ 4 at pos 9468
 000012F8	     6800	LDR R0 [ R0 + 0 ]
 000012FA	 F24A318D	MOV R1 #41869
 000012FE	 F6C9311E	MOVT R1 #39710
 00001302	     4288	CMP R0 R1
 00001304	     BF18	IT NE
 00001306	 EC04A087	TrapNE 7 at pos 9480
 0000130A	     9805	LDR R0 [ SP + 20 ]
 0000130C	     2800	CMP R0 #0
 0000130E	     BF08	IT EQ
 00001310	 EC04A164	TrapEQ 4 at pos 9494
 00001314	     6840	LDR R0 [ R0 + 4 ]
 00001316	     2800	CMP R0 #0
 00001318	 F040802E	BNE #92, goes to  00001378
 0000131C	     9805	LDR R0 [ SP + 20 ]
 0000131E	     2800	CMP R0 #0
 00001320	     BF08	IT EQ
 00001322	 EC04A234	TrapEQ 4 at pos 9507
 00001326	     6880	LDR R0 [ R0 + 8 ]
 00001328	     2800	CMP R0 #0
 0000132A	 F0008025	BEQ #74, goes to  00001378
 0000132E	     9805	LDR R0 [ SP + 20 ]
 00001330	     2800	CMP R0 #0
 00001332	     BF08	IT EQ
 00001334	 EC04A454	TrapEQ 4 at pos 9541
 00001338	     6880	LDR R0 [ R0 + 8 ]
 0000133A	     9004	STR R0 [ SP + 16 ]
 0000133C	     9804	LDR R0 [ SP + 16 ]
 0000133E	     9905	LDR R1 [ SP + 20 ]
 00001340	     2900	CMP R1 #0
 00001342	     BF08	IT EQ
 00001344	 EC04A644	TrapEQ 4 at pos 9572
 00001348	 1130002F	BL Mod(  1) proc(19)
 0000134C	     9805	LDR R0 [ SP + 20 ]
 0000134E	     2800	CMP R0 #0
 00001350	     BF08	IT EQ
 00001352	 EC04A734	TrapEQ 4 at pos 9587
 00001356	     6800	LDR R0 [ R0 + 0 ]
 00001358	 F24A318D	MOV R1 #41869
 0000135C	 F6C9311E	MOVT R1 #39710
 00001360	     4288	CMP R0 R1
 00001362	     BF18	IT NE
 00001364	 EC04A7F7	TrapNE 7 at pos 9599
 00001368	     201D	MOVS R0 #29
 0000136A	     9905	LDR R1 [ SP + 20 ]
 0000136C	     2900	CMP R1 #0
 0000136E	     BF08	IT EQ
 00001370	 EC04B284	TrapEQ 4 at pos 9640
 00001374	 11400016	BL Mod(  1) proc(20)
 00001378	 11A00002	BL Mod(  1) proc(26)
 0000137C	 F85DEB04	LDR LR [ SP ] + 4
 00001380	     B005	ADD SP SP #20
 00001382	     4770	BX LR
 00001384	     B085	SUB SP SP #20
 00001386	     B41F	PUSH R0 R1 R2 R3 R4
 00001388	     B500	PUSH LR
 0000138A	     A80A	ADD R0 SP #40
 0000138C	 1000006C	MOV R1 lower 16-bits base(0), next at  000012B4
 00001390	 00000028	MOVT R1 higher 16-bits const + 40
 00001394	     DF00	SVC #0
 00001396	     9803	LDR R0 [ SP + 12 ]
 00001398	     990A	LDR R1 [ SP + 40 ]
 0000139A	     2900	CMP R1 #0
 0000139C	     BF08	IT EQ
 0000139E	 EC04E254	TrapEQ 4 at pos 10021
 000013A2	 11300015	BL Mod(  1) proc(19)
 000013A6	     980A	LDR R0 [ SP + 40 ]
 000013A8	     2800	CMP R0 #0
 000013AA	     BF08	IT EQ
 000013AC	 EC04E344	TrapEQ 4 at pos 10036
 000013B0	     6800	LDR R0 [ R0 + 0 ]
 000013B2	 F24A318D	MOV R1 #41869
 000013B6	 F6C9311E	MOVT R1 #39710
 000013BA	     4288	CMP R0 R1
 000013BC	     BF18	IT NE
 000013BE	 EC04E407	TrapNE 7 at pos 10048
 000013C2	     2000	MOVS R0 #0
 000013C4	     9006	STR R0 [ SP + 24 ]
 000013C6	     980A	LDR R0 [ SP + 40 ]
 000013C8	     2800	CMP R0 #0
 000013CA	     BF08	IT EQ
 000013CC	 EC04E5B4	TrapEQ 4 at pos 10075
 000013D0	     9906	LDR R1 [ SP + 24 ]
 000013D2	     6840	LDR R0 [ R0 + 4 ]
 000013D4	     4281	CMP R1 R0
 000013D6	 F2808098	BGE #304, goes to  0000150A
 000013DA	     9805	LDR R0 [ SP + 20 ]
 000013DC	     7800	LDRB R0 [ R0 + 0 ]
 000013DE	     2800	CMP R0 #0
 000013E0	 F0008093	BEQ #294, goes to  0000150A
 000013E4	     2000	MOVS R0 #0
 000013E6	     9007	STR R0 [ SP + 28 ]
 000013E8	     9807	LDR R0 [ SP + 28 ]
 000013EA	     9902	LDR R1 [ SP + 8 ]
 000013EC	     4288	CMP R0 R1
 000013EE	     BF28	IT CS
 000013F0	 EC04F161	TrapCS 1 at pos 10134
 000013F4	     9901	LDR R1 [ SP + 4 ]
 000013F6	     1808	ADDS R0 R1 R0
 000013F8	     7800	LDRB R0 [ R0 + 0 ]
 000013FA	 F88D0020	STRB R0 [  SP + 32 ]
 000013FE	     980A	LDR R0 [ SP + 40 ]
 00001400	     2800	CMP R0 #0
 00001402	     BF08	IT EQ
 00001404	 EC04F224	TrapEQ 4 at pos 10146
 00001408	     9906	LDR R1 [ SP + 24 ]
 0000140A	     2918	CMP R1 #24
 0000140C	     BF28	IT CS
 0000140E	 EC04F251	TrapCS 1 at pos 10149
 00001412	     2228	MOVS R2 #40
 00001414	     4351	MULS R1 R2 R1
 00001416	     1840	ADDS R0 R0 R1
 00001418	     9907	LDR R1 [ SP + 28 ]
 0000141A	     2920	CMP R1 #32
 0000141C	     BF28	IT CS
 0000141E	 EC04F2D1	TrapCS 1 at pos 10157
 00001422	     1840	ADDS R0 R0 R1
 00001424	 F8900040	LDRB R0 [ R0 + 64 ]
 00001428	 F88D0021	STRB R0 [  SP + 33 ]
 0000142C	     9807	LDR R0 [ SP + 28 ]
 0000142E	     1C40	ADDS R0 R0 #1
 00001430	     9007	STR R0 [ SP + 28 ]
 00001432	 F89D0021	LDRB R0 [ SP + 33 ]
 00001436	 F89D1020	LDRB R1 [ SP + 32 ]
 0000143A	     4288	CMP R0 R1
 0000143C	 F0408004	BNE #8, goes to  00001448
 00001440	 F89D0020	LDRB R0 [ SP + 32 ]
 00001444	     2800	CMP R0 #0
 00001446	     D1CF	BNE #-98, goes to  000013E8
 00001448	 F89D0021	LDRB R0 [ SP + 33 ]
 0000144C	 F89D1020	LDRB R1 [ SP + 32 ]
 00001450	     4288	CMP R0 R1
 00001452	 F2C08056	BLT #172, goes to  00001502
 00001456	     9806	LDR R0 [ SP + 24 ]
 00001458	     2800	CMP R0 #0
 0000145A	 F0408009	BNE #18, goes to  00001470
 0000145E	     980A	LDR R0 [ SP + 40 ]
 00001460	     2800	CMP R0 #0
 00001462	     BF08	IT EQ
 00001464	 EC050184	TrapEQ 4 at pos 10264
 00001468	     6880	LDR R0 [ R0 + 8 ]
 0000146A	     9009	STR R0 [ SP + 36 ]
 0000146C	 F000B810	B #32, goes to  00001490
 00001470	     980A	LDR R0 [ SP + 40 ]
 00001472	     2800	CMP R0 #0
 00001474	     BF08	IT EQ
 00001476	 EC050294	TrapEQ 4 at pos 10281
 0000147A	     9906	LDR R1 [ SP + 24 ]
 0000147C	     1E49	SUBS R1 R1 #1
 0000147E	     2918	CMP R1 #24
 00001480	     BF28	IT CS
 00001482	 EC0502E1	TrapCS 1 at pos 10286
 00001486	     2228	MOVS R2 #40
 00001488	     4351	MULS R1 R2 R1
 0000148A	     1840	ADDS R0 R0 R1
 0000148C	     6E40	LDR R0 [ R0 + 100 ]
 0000148E	     9009	STR R0 [ SP + 36 ]
 00001490	     9809	LDR R0 [ SP + 36 ]
 00001492	     2800	CMP R0 #0
 00001494	 F0008007	BEQ #14, goes to  000014A6
 00001498	     9801	LDR R0 [ SP + 4 ]
 0000149A	     9902	LDR R1 [ SP + 8 ]
 0000149C	     9A09	LDR R2 [ SP + 36 ]
 0000149E	     9B04	LDR R3 [ SP + 16 ]
 000014A0	     9C05	LDR R4 [ SP + 20 ]
 000014A2	 F7FFFF6F	BL #-290, goes to  00001384
 000014A6	 F89D0020	LDRB R0 [ SP + 32 ]
 000014AA	     2800	CMP R0 #0
 000014AC	 F0408026	BNE #76, goes to  000014FC
 000014B0	     9805	LDR R0 [ SP + 20 ]
 000014B2	     7800	LDRB R0 [ R0 + 0 ]
 000014B4	     2800	CMP R0 #0
 000014B6	 F000801F	BEQ #62, goes to  000014F8
 000014BA	     980A	LDR R0 [ SP + 40 ]
 000014BC	     2800	CMP R0 #0
 000014BE	     BF08	IT EQ
 000014C0	 EC0513A4	TrapEQ 4 at pos 10426
 000014C4	     9906	LDR R1 [ SP + 24 ]
 000014C6	     2918	CMP R1 #24
 000014C8	     BF28	IT CS
 000014CA	 EC0513D1	TrapCS 1 at pos 10429
 000014CE	     2228	MOVS R2 #40
 000014D0	     4351	MULS R1 R2 R1
 000014D2	     1840	ADDS R0 R0 R1
 000014D4	     3040	ADDS R0 R0 #64
 000014D6	     990A	LDR R1 [ SP + 40 ]
 000014D8	     2900	CMP R1 #0
 000014DA	     BF08	IT EQ
 000014DC	 EC051474	TrapEQ 4 at pos 10439
 000014E0	     9A06	LDR R2 [ SP + 24 ]
 000014E2	     2A18	CMP R2 #24
 000014E4	     BF28	IT CS
 000014E6	 EC0514A1	TrapCS 1 at pos 10442
 000014EA	     2328	MOVS R3 #40
 000014EC	     435A	MULS R2 R3 R2
 000014EE	     1889	ADDS R1 R1 R2
 000014F0	     6E09	LDR R1 [ R1 + 96 ]
 000014F2	     9A05	LDR R2 [ SP + 20 ]
 000014F4	     9B04	LDR R3 [ SP + 16 ]
 000014F6	     4798	BLX R3
 000014F8	 F000B803	B #6, goes to  00001502
 000014FC	     2000	MOVS R0 #0
 000014FE	     9905	LDR R1 [ SP + 20 ]
 00001500	     7008	STRB R0 [ R1 + 0 ]
 00001502	     9806	LDR R0 [ SP + 24 ]
 00001504	     1C40	ADDS R0 R0 #1
 00001506	     9006	STR R0 [ SP + 24 ]
 00001508	     E75D	B #-326, goes to  000013C6
 0000150A	     9805	LDR R0 [ SP + 20 ]
 0000150C	     7800	LDRB R0 [ R0 + 0 ]
 0000150E	     2800	CMP R0 #0
 00001510	 F000802B	BEQ #86, goes to  0000156A
 00001514	     9806	LDR R0 [ SP + 24 ]
 00001516	     2800	CMP R0 #0
 00001518	 F3408027	BLE #78, goes to  0000156A
 0000151C	     980A	LDR R0 [ SP + 40 ]
 0000151E	     2800	CMP R0 #0
 00001520	     BF08	IT EQ
 00001522	 EC0524C4	TrapEQ 4 at pos 10572
 00001526	     9906	LDR R1 [ SP + 24 ]
 00001528	     1E49	SUBS R1 R1 #1
 0000152A	     2918	CMP R1 #24
 0000152C	     BF28	IT CS
 0000152E	 EC052511	TrapCS 1 at pos 10577
 00001532	     2228	MOVS R2 #40
 00001534	     4351	MULS R1 R2 R1
 00001536	     1840	ADDS R0 R0 R1
 00001538	     6E40	LDR R0 [ R0 + 100 ]
 0000153A	     2800	CMP R0 #0
 0000153C	 F0008015	BEQ #42, goes to  0000156A
 00001540	     9801	LDR R0 [ SP + 4 ]
 00001542	     9902	LDR R1 [ SP + 8 ]
 00001544	     9A0A	LDR R2 [ SP + 40 ]
 00001546	     2A00	CMP R2 #0
 00001548	     BF08	IT EQ
 0000154A	 EC052794	TrapEQ 4 at pos 10617
 0000154E	     9B06	LDR R3 [ SP + 24 ]
 00001550	     1E5B	SUBS R3 R3 #1
 00001552	     2B18	CMP R3 #24
 00001554	     BF28	IT CS
 00001556	 EC0527E1	TrapCS 1 at pos 10622
 0000155A	     2428	MOVS R4 #40
 0000155C	     4363	MULS R3 R4 R3
 0000155E	     18D2	ADDS R2 R2 R3
 00001560	     6E52	LDR R2 [ R2 + 100 ]
 00001562	     9B04	LDR R3 [ SP + 16 ]
 00001564	     9C05	LDR R4 [ SP + 20 ]
 00001566	 F7FFFF0D	BL #-486, goes to  00001384
 0000156A	 F85DEB04	LDR LR [ SP ] + 4
 0000156E	     B00A	ADD SP SP #40
 00001570	     4770	BX LR
 00001572	     B081	SUB SP SP #4
 00001574	     B407	PUSH R0 R1 R2
 00001576	     B500	PUSH LR
 00001578	     2001	MOVS R0 #1
 0000157A	 F88D0010	STRB R0 [  SP + 16 ]
 0000157E	     9801	LDR R0 [ SP + 4 ]
 00001580	     9902	LDR R1 [ SP + 8 ]
 00001582	     221D	MOVS R2 #29
 00001584	     9B03	LDR R3 [ SP + 12 ]
 00001586	     AC04	ADD R4 SP #16
 00001588	 F7FFFEFC	BL #-520, goes to  00001384
 0000158C	 F85DEB04	LDR LR [ SP ] + 4
 00001590	     B004	ADD SP SP #16
 00001592	     4770	BX LR
 00001594	 F000BA51	B #1186, goes to  00001A3A
 00001598	 F000B87F	B #254, goes to  0000169A
 0000159C	     B083	SUB SP SP #12
 0000159E	     B40F	PUSH R0 R1 R2 R3
 000015A0	     B500	PUSH LR
 000015A2	     9803	LDR R0 [ SP + 12 ]
 000015A4	     9006	STR R0 [ SP + 24 ]
 000015A6	     9806	LDR R0 [ SP + 24 ]
 000015A8	     9902	LDR R1 [ SP + 8 ]
 000015AA	     4288	CMP R0 R1
 000015AC	     BF28	IT CS
 000015AE	 EC057411	TrapCS 1 at pos 11201
 000015B2	     9901	LDR R1 [ SP + 4 ]
 000015B4	 EB110080	ADDS R0 R1 R0 LSL #2
 000015B8	     6800	LDR R0 [ R0 + 0 ]
 000015BA	     9007	STR R0 [ SP + 28 ]
 000015BC	     9806	LDR R0 [ SP + 24 ]
 000015BE	     9005	STR R0 [ SP + 20 ]
 000015C0	     9806	LDR R0 [ SP + 24 ]
 000015C2	     0040	LSLS R0 R0 #1
 000015C4	     1C40	ADDS R0 R0 #1
 000015C6	     9006	STR R0 [ SP + 24 ]
 000015C8	     9806	LDR R0 [ SP + 24 ]
 000015CA	     1C40	ADDS R0 R0 #1
 000015CC	     9904	LDR R1 [ SP + 16 ]
 000015CE	     4288	CMP R0 R1
 000015D0	 F280801B	BGE #54, goes to  0000160A
 000015D4	     9806	LDR R0 [ SP + 24 ]
 000015D6	     9902	LDR R1 [ SP + 8 ]
 000015D8	     4288	CMP R0 R1
 000015DA	     BF28	IT CS
 000015DC	 EC058061	TrapCS 1 at pos 11270
 000015E0	     9901	LDR R1 [ SP + 4 ]
 000015E2	 EB110080	ADDS R0 R1 R0 LSL #2
 000015E6	     9906	LDR R1 [ SP + 24 ]
 000015E8	     1C49	ADDS R1 R1 #1
 000015EA	     9A02	LDR R2 [ SP + 8 ]
 000015EC	     4291	CMP R1 R2
 000015EE	     BF28	IT CS
 000015F0	 EC0580F1	TrapCS 1 at pos 11279
 000015F4	     9A01	LDR R2 [ SP + 4 ]
 000015F6	 EB120181	ADDS R1 R2 R1 LSL #2
 000015FA	     6800	LDR R0 [ R0 + 0 ]
 000015FC	     6809	LDR R1 [ R1 + 0 ]
 000015FE	     4288	CMP R0 R1
 00001600	 F2808003	BGE #6, goes to  0000160A
 00001604	     9806	LDR R0 [ SP + 24 ]
 00001606	     1C40	ADDS R0 R0 #1
 00001608	     9006	STR R0 [ SP + 24 ]
 0000160A	     9806	LDR R0 [ SP + 24 ]
 0000160C	     9904	LDR R1 [ SP + 16 ]
 0000160E	     4288	CMP R0 R1
 00001610	 F2808022	BGE #68, goes to  00001658
 00001614	     9806	LDR R0 [ SP + 24 ]
 00001616	     9902	LDR R1 [ SP + 8 ]
 00001618	     4288	CMP R0 R1
 0000161A	     BF28	IT CS
 0000161C	 EC058441	TrapCS 1 at pos 11332
 00001620	     9901	LDR R1 [ SP + 4 ]
 00001622	 EB110080	ADDS R0 R1 R0 LSL #2
 00001626	     9907	LDR R1 [ SP + 28 ]
 00001628	     6800	LDR R0 [ R0 + 0 ]
 0000162A	     4281	CMP R1 R0
 0000162C	 F3008014	BGT #40, goes to  00001658
 00001630	     9805	LDR R0 [ SP + 20 ]
 00001632	     9902	LDR R1 [ SP + 8 ]
 00001634	     4288	CMP R0 R1
 00001636	     BF28	IT CS
 00001638	 EC0584F1	TrapCS 1 at pos 11343
 0000163C	     9901	LDR R1 [ SP + 4 ]
 0000163E	 EB110080	ADDS R0 R1 R0 LSL #2
 00001642	     9906	LDR R1 [ SP + 24 ]
 00001644	     9A02	LDR R2 [ SP + 8 ]
 00001646	     4291	CMP R1 R2
 00001648	     BF28	IT CS
 0000164A	 EC058571	TrapCS 1 at pos 11351
 0000164E	     9A01	LDR R2 [ SP + 4 ]
 00001650	 EB120181	ADDS R1 R2 R1 LSL #2
 00001654	     6809	LDR R1 [ R1 + 0 ]
 00001656	     6001	STR R1 [  R0 + 0 ]
 00001658	     9806	LDR R0 [ SP + 24 ]
 0000165A	     9904	LDR R1 [ SP + 16 ]
 0000165C	     4288	CMP R0 R1
 0000165E	 F280800D	BGE #26, goes to  0000167C
 00001662	     9806	LDR R0 [ SP + 24 ]
 00001664	     9902	LDR R1 [ SP + 8 ]
 00001666	     4288	CMP R0 R1
 00001668	     BF28	IT CS
 0000166A	 EC0587F1	TrapCS 1 at pos 11391
 0000166E	     9901	LDR R1 [ SP + 4 ]
 00001670	 EB110080	ADDS R0 R1 R0 LSL #2
 00001674	     9907	LDR R1 [ SP + 28 ]
 00001676	     6800	LDR R0 [ R0 + 0 ]
 00001678	     4281	CMP R1 R0
 0000167A	     DD9F	BLE #-194, goes to  000015BC
 0000167C	     9805	LDR R0 [ SP + 20 ]
 0000167E	     9902	LDR R1 [ SP + 8 ]
 00001680	     4288	CMP R0 R1
 00001682	     BF28	IT CS
 00001684	 EC0590E1	TrapCS 1 at pos 11406
 00001688	     9901	LDR R1 [ SP + 4 ]
 0000168A	 EB110080	ADDS R0 R1 R0 LSL #2
 0000168E	     9907	LDR R1 [ SP + 28 ]
 00001690	     6001	STR R1 [  R0 + 0 ]
 00001692	 F85DEB04	LDR LR [ SP ] + 4
 00001696	     B007	ADD SP SP #28
 00001698	     4770	BX LR
 0000169A	 F5AD6D83	SUB SP SP #1048
 0000169E	     B407	PUSH R0 R1 R2
 000016A0	     B500	PUSH LR
 000016A2	     9803	LDR R0 [ SP + 12 ]
 000016A4	     1040	ASRS R0 R0 #1
 000016A6	     9004	STR R0 [ SP + 16 ]
 000016A8	     9803	LDR R0 [ SP + 12 ]
 000016AA	     9005	STR R0 [ SP + 20 ]
 000016AC	     9804	LDR R0 [ SP + 16 ]
 000016AE	     2800	CMP R0 #0
 000016B0	 F340800A	BLE #20, goes to  000016C8
 000016B4	     9804	LDR R0 [ SP + 16 ]
 000016B6	     1E40	SUBS R0 R0 #1
 000016B8	     9004	STR R0 [ SP + 16 ]
 000016BA	     9801	LDR R0 [ SP + 4 ]
 000016BC	     9902	LDR R1 [ SP + 8 ]
 000016BE	     9A04	LDR R2 [ SP + 16 ]
 000016C0	     9B05	LDR R3 [ SP + 20 ]
 000016C2	 F7FFFF6B	BL #-298, goes to  0000159C
 000016C6	     E7F1	B #-30, goes to  000016AC
 000016C8	     9805	LDR R0 [ SP + 20 ]
 000016CA	     2800	CMP R0 #0
 000016CC	 F3408034	BLE #104, goes to  00001738
 000016D0	     9805	LDR R0 [ SP + 20 ]
 000016D2	     1E40	SUBS R0 R0 #1
 000016D4	     9005	STR R0 [ SP + 20 ]
 000016D6	     2000	MOVS R0 #0
 000016D8	     9902	LDR R1 [ SP + 8 ]
 000016DA	     4288	CMP R0 R1
 000016DC	     BF28	IT CS
 000016DE	 EC05A311	TrapCS 1 at pos 11569
 000016E2	     9901	LDR R1 [ SP + 4 ]
 000016E4	 EB110080	ADDS R0 R1 R0 LSL #2
 000016E8	     6800	LDR R0 [ R0 + 0 ]
 000016EA	     9009	STR R0 [ SP + 36 ]
 000016EC	     2000	MOVS R0 #0
 000016EE	     9902	LDR R1 [ SP + 8 ]
 000016F0	     4288	CMP R0 R1
 000016F2	     BF28	IT CS
 000016F4	 EC05A371	TrapCS 1 at pos 11575
 000016F8	     9901	LDR R1 [ SP + 4 ]
 000016FA	 EB110080	ADDS R0 R1 R0 LSL #2
 000016FE	     9905	LDR R1 [ SP + 20 ]
 00001700	     9A02	LDR R2 [ SP + 8 ]
 00001702	     4291	CMP R1 R2
 00001704	     BF28	IT CS
 00001706	 EC05A3F1	TrapCS 1 at pos 11583
 0000170A	     9A01	LDR R2 [ SP + 4 ]
 0000170C	 EB120181	ADDS R1 R2 R1 LSL #2
 00001710	     6809	LDR R1 [ R1 + 0 ]
 00001712	     6001	STR R1 [  R0 + 0 ]
 00001714	     9805	LDR R0 [ SP + 20 ]
 00001716	     9902	LDR R1 [ SP + 8 ]
 00001718	     4288	CMP R0 R1
 0000171A	     BF28	IT CS
 0000171C	 EC05A451	TrapCS 1 at pos 11589
 00001720	     9901	LDR R1 [ SP + 4 ]
 00001722	 EB110080	ADDS R0 R1 R0 LSL #2
 00001726	     9909	LDR R1 [ SP + 36 ]
 00001728	     6001	STR R1 [  R0 + 0 ]
 0000172A	     9801	LDR R0 [ SP + 4 ]
 0000172C	     9902	LDR R1 [ SP + 8 ]
 0000172E	     9A04	LDR R2 [ SP + 16 ]
 00001730	     9B05	LDR R3 [ SP + 20 ]
 00001732	 F7FFFF33	BL #-410, goes to  0000159C
 00001736	     E7C7	B #-114, goes to  000016C8
 00001738	     9804	LDR R0 [ SP + 16 ]
 0000173A	     9903	LDR R1 [ SP + 12 ]
 0000173C	     4288	CMP R0 R1
 0000173E	 F28080E3	BGE #454, goes to  00001908
 00001742	     9804	LDR R0 [ SP + 16 ]
 00001744	     9902	LDR R1 [ SP + 8 ]
 00001746	     4288	CMP R0 R1
 00001748	     BF28	IT CS
 0000174A	 EC05B181	TrapCS 1 at pos 11672
 0000174E	     9901	LDR R1 [ SP + 4 ]
 00001750	 EB110080	ADDS R0 R1 R0 LSL #2
 00001754	     6800	LDR R0 [ R0 + 0 ]
 00001756	 10000BAB	MOV R1 lower 16-bits base(0), next at  00000000
 0000175A	 00000000	MOVT R1 higher 16-bits var + 0
 0000175E	     6809	LDR R1 [ R1 + 0 ]
 00001760	     2900	CMP R1 #0
 00001762	     BF08	IT EQ
 00001764	 EC05B1E4	TrapEQ 4 at pos 11678
 00001768	 113001E3	BL Mod(  1) proc(19)
 0000176C	 0000000B	MOV R0 lower 16-bits base(0), next at  00001756
 00001770	 00000000	MOVT R0 higher 16-bits var + 0
 00001774	     6800	LDR R0 [ R0 + 0 ]
 00001776	     2800	CMP R0 #0
 00001778	     BF08	IT EQ
 0000177A	 EC05B2E4	TrapEQ 4 at pos 11694
 0000177E	     6800	LDR R0 [ R0 + 0 ]
 00001780	 F6415186	MOV R1 #7558
 00001784	 F6C931A7	MOVT R1 #39847
 00001788	     4288	CMP R0 R1
 0000178A	     BF18	IT NE
 0000178C	 EC05B3D7	TrapNE 7 at pos 11709
 00001790	 00000012	MOV R0 lower 16-bits base(0), next at  0000176C
 00001794	 00000000	MOVT R0 higher 16-bits var + 0
 00001798	     6800	LDR R0 [ R0 + 0 ]
 0000179A	     2800	CMP R0 #0
 0000179C	     BF08	IT EQ
 0000179E	 EC05B514	TrapEQ 4 at pos 11729
 000017A2	     6A40	LDR R0 [ R0 + 36 ]
 000017A4	     2840	CMP R0 #64
 000017A6	 F2808027	BGE #78, goes to  000017F8
 000017AA	 0000000D	MOV R0 lower 16-bits base(0), next at  00001790
 000017AE	 00000000	MOVT R0 higher 16-bits var + 0
 000017B2	     6800	LDR R0 [ R0 + 0 ]
 000017B4	     2800	CMP R0 #0
 000017B6	     BF08	IT EQ
 000017B8	 EC05B714	TrapEQ 4 at pos 11761
 000017BC	     6A40	LDR R0 [ R0 + 36 ]
 000017BE	     1C40	ADDS R0 R0 #1
 000017C0	     9007	STR R0 [ SP + 28 ]
 000017C2	     9807	LDR R0 [ SP + 28 ]
 000017C4	     1E40	SUBS R0 R0 #1
 000017C6	     9007	STR R0 [ SP + 28 ]
 000017C8	 0000000F	MOV R0 lower 16-bits base(0), next at  000017AA
 000017CC	 00000000	MOVT R0 higher 16-bits var + 0
 000017D0	     6800	LDR R0 [ R0 + 0 ]
 000017D2	     2800	CMP R0 #0
 000017D4	     BF08	IT EQ
 000017D6	 EC05C284	TrapEQ 4 at pos 11816
 000017DA	     9907	LDR R1 [ SP + 28 ]
 000017DC	     2940	CMP R1 #64
 000017DE	     BF28	IT CS
 000017E0	 EC05C2B1	TrapCS 1 at pos 11819
 000017E4	 EB100081	ADDS R0 R0 R1 LSL #2
 000017E8	     6E00	LDR R0 [ R0 + 96 ]
 000017EA	 11000041	BL Mod(  1) proc(16)
 000017EE	     9807	LDR R0 [ SP + 28 ]
 000017F0	     2800	CMP R0 #0
 000017F2	     D1E6	BNE #-52, goes to  000017C2
 000017F4	 F000B884	B #264, goes to  00001900
 000017F8	     2040	MOVS R0 #64
 000017FA	     9007	STR R0 [ SP + 28 ]
 000017FC	     9807	LDR R0 [ SP + 28 ]
 000017FE	     1E40	SUBS R0 R0 #1
 00001800	     9007	STR R0 [ SP + 28 ]
 00001802	 0000001D	MOV R0 lower 16-bits base(0), next at  000017C8
 00001806	 00000000	MOVT R0 higher 16-bits var + 0
 0000180A	     6800	LDR R0 [ R0 + 0 ]
 0000180C	     2800	CMP R0 #0
 0000180E	     BF08	IT EQ
 00001810	 EC05D084	TrapEQ 4 at pos 11912
 00001814	     9907	LDR R1 [ SP + 28 ]
 00001816	     2940	CMP R1 #64
 00001818	     BF28	IT CS
 0000181A	 EC05D0B1	TrapCS 1 at pos 11915
 0000181E	 EB100081	ADDS R0 R0 R1 LSL #2
 00001822	     6E00	LDR R0 [ R0 + 96 ]
 00001824	 1100001D	BL Mod(  1) proc(16)
 00001828	     9807	LDR R0 [ SP + 28 ]
 0000182A	     2800	CMP R0 #0
 0000182C	     D1E6	BNE #-52, goes to  000017FC
 0000182E	 00000016	MOV R0 lower 16-bits base(0), next at  00001802
 00001832	 00000000	MOVT R0 higher 16-bits var + 0
 00001836	     6800	LDR R0 [ R0 + 0 ]
 00001838	     2800	CMP R0 #0
 0000183A	     BF08	IT EQ
 0000183C	 EC05D324	TrapEQ 4 at pos 11954
 00001840	     6A40	LDR R0 [ R0 + 36 ]
 00001842	     3840	SUBS R0 R0 #64
 00001844	     1200	ASRS R0 R0 #8
 00001846	     9008	STR R0 [ SP + 32 ]
 00001848	     2000	MOVS R0 #0
 0000184A	     9006	STR R0 [ SP + 24 ]
 0000184C	     9806	LDR R0 [ SP + 24 ]
 0000184E	     9908	LDR R1 [ SP + 32 ]
 00001850	     4288	CMP R0 R1
 00001852	 F3008055	BGT #170, goes to  00001900
 00001856	 00000014	MOV R0 lower 16-bits base(0), next at  0000182E
 0000185A	 00000000	MOVT R0 higher 16-bits var + 0
 0000185E	     6800	LDR R0 [ R0 + 0 ]
 00001860	     2800	CMP R0 #0
 00001862	     BF08	IT EQ
 00001864	 EC05E164	TrapEQ 4 at pos 12054
 00001868	     9906	LDR R1 [ SP + 24 ]
 0000186A	     290C	CMP R1 #12
 0000186C	     BF28	IT CS
 0000186E	 EC05E191	TrapCS 1 at pos 12057
 00001872	 EB100081	ADDS R0 R0 R1 LSL #2
 00001876	     6B00	LDR R0 [ R0 + 48 ]
 00001878	 1100002A	BL Mod(  1) proc(16)
 0000187C	 00000013	MOV R0 lower 16-bits base(0), next at  00001856
 00001880	 00000000	MOVT R0 higher 16-bits var + 0
 00001884	     6800	LDR R0 [ R0 + 0 ]
 00001886	     2800	CMP R0 #0
 00001888	     BF08	IT EQ
 0000188A	 EC05E3F4	TrapEQ 4 at pos 12095
 0000188E	     9906	LDR R1 [ SP + 24 ]
 00001890	     290C	CMP R1 #12
 00001892	     BF28	IT CS
 00001894	 EC05E421	TrapCS 1 at pos 12098
 00001898	 EB100081	ADDS R0 R0 R1 LSL #2
 0000189C	     6B00	LDR R0 [ R0 + 48 ]
 0000189E	     A90A	ADD R1 SP #40
 000018A0	 11300014	BL Mod(  1) proc(19)
 000018A4	     9806	LDR R0 [ SP + 24 ]
 000018A6	     9908	LDR R1 [ SP + 32 ]
 000018A8	     4288	CMP R0 R1
 000018AA	 F2808005	BGE #10, goes to  000018B8
 000018AE	 F45F7080	MOVS R0 #256
 000018B2	     9007	STR R0 [ SP + 28 ]
 000018B4	 F000B80F	B #30, goes to  000018D6
 000018B8	 0000001E	MOV R0 lower 16-bits base(0), next at  0000187C
 000018BC	 00000000	MOVT R0 higher 16-bits var + 0
 000018C0	     6800	LDR R0 [ R0 + 0 ]
 000018C2	     2800	CMP R0 #0
 000018C4	     BF08	IT EQ
 000018C6	 EC05F154	TrapEQ 4 at pos 12181
 000018CA	     6A40	LDR R0 [ R0 + 36 ]
 000018CC	     3840	SUBS R0 R0 #64
 000018CE	 F36F201F	BFC R0 #8 #24
 000018D2	     1C40	ADDS R0 R0 #1
 000018D4	     9007	STR R0 [ SP + 28 ]
 000018D6	     9807	LDR R0 [ SP + 28 ]
 000018D8	     1E40	SUBS R0 R0 #1
 000018DA	     9007	STR R0 [ SP + 28 ]
 000018DC	     9807	LDR R0 [ SP + 28 ]
 000018DE	 F5B07F80	CMP R0 #256
 000018E2	     BF28	IT CS
 000018E4	 EC05F6D1	TrapCS 1 at pos 12269
 000018E8	 EB0D0080	ADD R0 SP R0 LSL #2
 000018EC	     6A80	LDR R0 [ R0 + 40 ]
 000018EE	 11000027	BL Mod(  1) proc(16)
 000018F2	     9807	LDR R0 [ SP + 28 ]
 000018F4	     2800	CMP R0 #0
 000018F6	     D1EE	BNE #-36, goes to  000018D6
 000018F8	     9806	LDR R0 [ SP + 24 ]
 000018FA	     1C40	ADDS R0 R0 #1
 000018FC	     9006	STR R0 [ SP + 24 ]
 000018FE	     E7A5	B #-182, goes to  0000184C
 00001900	     9804	LDR R0 [ SP + 16 ]
 00001902	     1C40	ADDS R0 R0 #1
 00001904	     9004	STR R0 [ SP + 16 ]
 00001906	     E717	B #-466, goes to  00001738
 00001908	 F85DEB04	LDR LR [ SP ] + 4
 0000190C	 F20D4D24	ADD SP SP #1060
 00001910	     4770	BX LR
 00001912	     B082	SUB SP SP #8
 00001914	     B40F	PUSH R0 R1 R2 R3
 00001916	     B500	PUSH LR
 00001918	     9804	LDR R0 [ SP + 16 ]
 0000191A	     2800	CMP R0 #0
 0000191C	 F0008089	BEQ #274, goes to  00001A32
 00001920	     A806	ADD R0 SP #24
 00001922	 100002CB	MOV R1 lower 16-bits base(0), next at  0000138C
 00001926	 00000028	MOVT R1 higher 16-bits const + 40
 0000192A	     DF00	SVC #0
 0000192C	     9804	LDR R0 [ SP + 16 ]
 0000192E	     9906	LDR R1 [ SP + 24 ]
 00001930	     2900	CMP R1 #0
 00001932	     BF08	IT EQ
 00001934	 EC062104	TrapEQ 4 at pos 12560
 00001938	 11300025	BL Mod(  1) proc(19)
 0000193C	     9806	LDR R0 [ SP + 24 ]
 0000193E	     2800	CMP R0 #0
 00001940	     BF08	IT EQ
 00001942	 EC0621F4	TrapEQ 4 at pos 12575
 00001946	     6800	LDR R0 [ R0 + 0 ]
 00001948	 F24A318D	MOV R1 #41869
 0000194C	 F6C9311E	MOVT R1 #39710
 00001950	     4288	CMP R0 R1
 00001952	     BF18	IT NE
 00001954	 EC0622B7	TrapNE 7 at pos 12587
 00001958	     9804	LDR R0 [ SP + 16 ]
 0000195A	 11000011	BL Mod(  1) proc(16)
 0000195E	     2000	MOVS R0 #0
 00001960	     9005	STR R0 [ SP + 20 ]
 00001962	     9806	LDR R0 [ SP + 24 ]
 00001964	     2800	CMP R0 #0
 00001966	     BF08	IT EQ
 00001968	 EC062614	TrapEQ 4 at pos 12641
 0000196C	     9905	LDR R1 [ SP + 20 ]
 0000196E	     6840	LDR R0 [ R0 + 4 ]
 00001970	     4281	CMP R1 R0
 00001972	 F2808030	BGE #96, goes to  000019D6
 00001976	     9803	LDR R0 [ SP + 12 ]
 00001978	     6800	LDR R0 [ R0 + 0 ]
 0000197A	     9902	LDR R1 [ SP + 8 ]
 0000197C	     4288	CMP R0 R1
 0000197E	     BF28	IT CS
 00001980	 EC062731	TrapCS 1 at pos 12659
 00001984	     9901	LDR R1 [ SP + 4 ]
 00001986	 EB110080	ADDS R0 R1 R0 LSL #2
 0000198A	     9906	LDR R1 [ SP + 24 ]
 0000198C	     2900	CMP R1 #0
 0000198E	     BF08	IT EQ
 00001990	 EC0627A4	TrapEQ 4 at pos 12666
 00001994	     9A05	LDR R2 [ SP + 20 ]
 00001996	     2A18	CMP R2 #24
 00001998	     BF28	IT CS
 0000199A	 EC0627D1	TrapCS 1 at pos 12669
 0000199E	     2328	MOVS R3 #40
 000019A0	     435A	MULS R2 R3 R2
 000019A2	     1889	ADDS R1 R1 R2
 000019A4	     6E09	LDR R1 [ R1 + 96 ]
 000019A6	     6001	STR R1 [  R0 + 0 ]
 000019A8	     9803	LDR R0 [ SP + 12 ]
 000019AA	     6801	LDR R1 [ R0 + 0 ]
 000019AC	     1C49	ADDS R1 R1 #1
 000019AE	     6001	STR R1 [  R0 + 0 ]
 000019B0	     9805	LDR R0 [ SP + 20 ]
 000019B2	     1C40	ADDS R0 R0 #1
 000019B4	     9005	STR R0 [ SP + 20 ]
 000019B6	     9803	LDR R0 [ SP + 12 ]
 000019B8	     6800	LDR R0 [ R0 + 0 ]
 000019BA	 F5B06FFA	CMP R0 #2000
 000019BE	 F0408009	BNE #18, goes to  000019D4
 000019C2	     9801	LDR R0 [ SP + 4 ]
 000019C4	     9902	LDR R1 [ SP + 8 ]
 000019C6	     9A03	LDR R2 [ SP + 12 ]
 000019C8	     6812	LDR R2 [ R2 + 0 ]
 000019CA	 F7FFFE66	BL #-820, goes to  0000169A
 000019CE	     2000	MOVS R0 #0
 000019D0	     9903	LDR R1 [ SP + 12 ]
 000019D2	     6008	STR R0 [  R1 + 0 ]
 000019D4	     E7C5	B #-118, goes to  00001962
 000019D6	     9801	LDR R0 [ SP + 4 ]
 000019D8	     9902	LDR R1 [ SP + 8 ]
 000019DA	     9A03	LDR R2 [ SP + 12 ]
 000019DC	     9B06	LDR R3 [ SP + 24 ]
 000019DE	     2B00	CMP R3 #0
 000019E0	     BF08	IT EQ
 000019E2	 EC063784	TrapEQ 4 at pos 12792
 000019E6	     689B	LDR R3 [ R3 + 8 ]
 000019E8	 F7FFFF93	BL #-218, goes to  00001912
 000019EC	     2000	MOVS R0 #0
 000019EE	     9005	STR R0 [ SP + 20 ]
 000019F0	     9806	LDR R0 [ SP + 24 ]
 000019F2	     2800	CMP R0 #0
 000019F4	     BF08	IT EQ
 000019F6	 EC064184	TrapEQ 4 at pos 12824
 000019FA	     9905	LDR R1 [ SP + 20 ]
 000019FC	     6840	LDR R0 [ R0 + 4 ]
 000019FE	     4281	CMP R1 R0
 00001A00	 F2808017	BGE #46, goes to  00001A32
 00001A04	     9801	LDR R0 [ SP + 4 ]
 00001A06	     9902	LDR R1 [ SP + 8 ]
 00001A08	     9A03	LDR R2 [ SP + 12 ]
 00001A0A	     9B06	LDR R3 [ SP + 24 ]
 00001A0C	     2B00	CMP R3 #0
 00001A0E	     BF08	IT EQ
 00001A10	 EC064314	TrapEQ 4 at pos 12849
 00001A14	     9C05	LDR R4 [ SP + 20 ]
 00001A16	     2C18	CMP R4 #24
 00001A18	     BF28	IT CS
 00001A1A	 EC064341	TrapCS 1 at pos 12852
 00001A1E	     2528	MOVS R5 #40
 00001A20	     436C	MULS R4 R5 R4
 00001A22	     191B	ADDS R3 R3 R4
 00001A24	     6E5B	LDR R3 [ R3 + 100 ]
 00001A26	 F7FFFF74	BL #-280, goes to  00001912
 00001A2A	     9805	LDR R0 [ SP + 20 ]
 00001A2C	     1C40	ADDS R0 R0 #1
 00001A2E	     9005	STR R0 [ SP + 20 ]
 00001A30	     E7DE	B #-68, goes to  000019F0
 00001A32	 F85DEB04	LDR LR [ SP ] + 4
 00001A36	     B006	ADD SP SP #24
 00001A38	     4770	BX LR
 00001A3A	 F6417044	MOV R0 #8004
 00001A3E	 EBAD0D00	SUB SP SP R0 LSL #0
 00001A42	     B500	PUSH LR
 00001A44	 000000C6	MOV R0 lower 16-bits base(0), next at  000018B8
 00001A48	 00000000	MOVT R0 higher 16-bits var + 0
 00001A4C	 10000095	MOV R1 lower 16-bits base(0), next at  00001922
 00001A50	 00000000	MOVT R1 higher 16-bits const + 0
 00001A54	     DF00	SVC #0
 00001A56	     2000	MOVS R0 #0
 00001A58	     9001	STR R0 [ SP + 4 ]
 00001A5A	     A802	ADD R0 SP #8
 00001A5C	 F45F61FA	MOVS R1 #2000
 00001A60	     AA01	ADD R2 SP #4
 00001A62	     231D	MOVS R3 #29
 00001A64	 F7FFFF55	BL #-342, goes to  00001912
 00001A68	     A802	ADD R0 SP #8
 00001A6A	 F45F61FA	MOVS R1 #2000
 00001A6E	     9A01	LDR R2 [ SP + 4 ]
 00001A70	 F7FFFE13	BL #-986, goes to  0000169A
 00001A74	     2000	MOVS R0 #0
 00001A76	 10000019	MOV R1 lower 16-bits base(0), next at  00001A44
 00001A7A	 00000000	MOVT R1 higher 16-bits var + 0
 00001A7E	     6008	STR R0 [  R1 + 0 ]
 00001A80	 F85DEB04	LDR LR [ SP ] + 4
 00001A84	 F6417044	MOV R0 #8004
 00001A88	 EB0D0D00	ADD SP SP R0 LSL #0
 00001A8C	     4770	BX LR
 00001A8E	     B500	PUSH LR
 00001A90	 F7FFFFD3	BL #-90, goes to  00001A3A
 00001A94	 F85DEB04	LDR LR [ SP ] + 4
 00001A98	     4770	BX LR
