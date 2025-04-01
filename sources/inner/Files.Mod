MODULE Files;  (*NW 11.1.86 / 22.9.93 / 25.5.95 / 25.12.95 / 15.8.2013*)
  IMPORT SYSTEM, Kernel, FileDir;

  (*A file consists of a sequence of pages. The first page
    contains the header. Part of the header is the page table, an array
    of disk addresses to the pages. A file is referenced through riders.
    A rider indicates a current position and refers to a file*)

  CONST MaxBufs    = 4;
      HS        = FileDir.HeaderSize;
      SS        = FileDir.SectorSize;
      STS       = FileDir.SecTabSize;
      XS        = FileDir.IndexSize;

  TYPE  DiskAdr = INTEGER;
      File*    = POINTER TO FileDesc;
      Buffer  = POINTER TO BufferRecord;
      Index   = POINTER TO IndexRecord;

    Rider* =
      RECORD eof*: BOOLEAN;
        res*: INTEGER;
        file: File;
        apos, bpos: INTEGER;
        buf: Buffer
      END ;

    FileDesc =
      RECORD next: INTEGER; (*list of files invisible to the GC*)
        nofbufs, aleng, bleng: INTEGER;
        modH, registered: BOOLEAN;
        firstbuf: Buffer;
        sechint: DiskAdr;
        name: FileDir.FileName;
        date: INTEGER;
        ext:  ARRAY FileDir.ExTabSize OF Index;
        sec: FileDir.SectorTable
      END ;

    BufferRecord =
      RECORD apos, lim: INTEGER;
        mod: BOOLEAN;
        next: Buffer;
        data: FileDir.DataSector
      END ;

    IndexRecord =
      RECORD adr: DiskAdr;
        mod: BOOLEAN;
        sec: FileDir.IndexSector
      END ;

    (*aleng * SS + bleng = length (including header)
      apos * SS + bpos = current position
      0 <= bpos <= lim <= SS
      0 <= apos <= aleng < PgTabSize
      (apos < aleng) & (lim = SS) OR (apos = aleng) *)

  VAR root: INTEGER (*File*);  (*list of open files*)

  PROCEDURE Check(s: ARRAY OF CHAR;
        VAR name: FileDir.FileName; VAR res: INTEGER);
    VAR i: INTEGER; ch: CHAR;
  BEGIN ch := s[0]; i := 0;
    IF (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z") THEN
      REPEAT name[i] := ch; INC(i); ch := s[i]
      UNTIL ~((ch >= "0") & (ch <= "9") OR (ch >= "A") & (ch <= "Z")
        OR (ch >= "a") & (ch <= "z") OR (ch = ".")) OR (i = FileDir.FnLength);
      IF i = FileDir.FnLength THEN res := 4
      ELSIF ch = 0X THEN res := 0;
        WHILE i < FileDir.FnLength DO name[i] := 0X; INC(i) END
      ELSE res := 5
      END
    ELSIF ch = 0X THEN name[0] := 0X; res := -1
    ELSE res := 3
    END
  END Check;

  PROCEDURE Old*(name: ARRAY OF CHAR): File;
    VAR i, k, res: INTEGER;
      f!: File;
      header: DiskAdr;
      buf!: Buffer;
      F!: FileDir.FileHd;
      namebuf: FileDir.FileName;
      inxpg!: Index;
  BEGIN f := NIL; Check(name, namebuf, res);
    IF res = 0 THEN
      FileDir.Search(namebuf, header);
      IF header # 0 THEN
        f := SYSTEM.VAL(File, root);
        WHILE (f # NIL) & (f.sec[0] # header) DO f := SYSTEM.VAL(File, f.next) END ;
        IF f = NIL THEN (*file not yet present*)
          NEW(buf); buf.apos := 0; buf.next := buf; buf.mod := FALSE;
          F := SYSTEM.VAL(FileDir.FileHd, SYSTEM.ADR(buf.data));
          Kernel.GetSector(header, buf.data); ASSERT(F.mark = FileDir.HeaderMark);
          NEW(f); f.aleng := F.aleng; f.bleng := F.bleng; f.date := F.date;
          IF f.aleng = 0 THEN buf.lim := f.bleng ELSE buf.lim := SS END ;
          f.firstbuf := buf; f.nofbufs := 1; f.name := namebuf; f.registered := TRUE;
          f.sec := F.sec;
          k := (f.aleng + (XS-STS)) DIV XS; i := 0;
          WHILE i < k DO
            NEW(inxpg); inxpg.adr := F.ext[i]; inxpg.mod := FALSE;
            Kernel.GetSector(inxpg.adr, inxpg.sec); f.ext[i] := inxpg; INC(i)
          END ;
          WHILE i < FileDir.ExTabSize DO f.ext[i] := NIL; INC(i) END ;
          f.sechint := header; f.modH := FALSE; f.next := root; root := SYSTEM.VAL(INTEGER, f)
        END
      END
    END ;
    RETURN f
  END Old;

  PROCEDURE New*(name: ARRAY OF CHAR): File;
    VAR i, res: INTEGER;
      f!: File;
      buf!: Buffer;
      F!: FileDir.FileHd;
      namebuf: FileDir.FileName;
  BEGIN f := NIL; Check(name, namebuf, res);
    IF res <= 0 THEN
      NEW(buf); buf.apos := 0; buf.mod := TRUE; buf.lim := HS; buf.next := buf;
      F := SYSTEM.VAL(FileDir.FileHd, SYSTEM.ADR(buf.data));
      F.mark := FileDir.HeaderMark;
      F.aleng := 0; F.bleng := HS; F.name := namebuf;
      F.date := Kernel.Clock();
      NEW(f); f.aleng := 0; f.bleng := HS; f.modH := TRUE;
      f.registered := FALSE; f.date := F.date;
      f.firstbuf := buf; f.nofbufs := 1; f.name := namebuf; f.sechint := 0;
      i := 0;
      REPEAT f.ext[i] := NIL; F.ext[i] := 0; INC(i) UNTIL i = FileDir.ExTabSize;
      i := 0;
      REPEAT f.sec[i] := 0; F.sec[i] := 0; INC(i) UNTIL i = STS
    END ;
    RETURN f
  END New;

  PROCEDURE UpdateHeader(f: File; VAR F: FileDir.FileHeader);
    VAR k: INTEGER;
  BEGIN F.aleng := f.aleng; F.bleng := f.bleng;
    F.sec := f.sec; k := (f.aleng + (XS-STS)) DIV XS;
    WHILE k > 0 DO DEC(k); F.ext[k] := f.ext[k].adr END
  END UpdateHeader;

  PROCEDURE ReadBuf(f: File; buf: Buffer; pos: INTEGER);
    VAR sec: DiskAdr;
  BEGIN
    IF pos < STS THEN sec := f.sec[pos]
    ELSE sec := f.ext[(pos-STS) DIV XS].sec[(pos-STS) MOD XS]
    END ;
    Kernel.GetSector(sec, buf.data);
    IF pos < f.aleng THEN buf.lim := SS ELSE buf.lim := f.bleng END ;
    buf.apos := pos; buf.mod := FALSE
  END ReadBuf;

  PROCEDURE WriteBuf(f: File; buf: Buffer);
    VAR i, k: INTEGER;
      secadr: DiskAdr; inx!: Index;
  BEGIN 
    IF buf.apos < STS THEN
      secadr := f.sec[buf.apos];
      IF secadr = 0 THEN
        Kernel.AllocSector(f.sechint, secadr);
        f.modH := TRUE; f.sec[buf.apos] := secadr; f.sechint := secadr
      END ;
      IF buf.apos = 0 THEN
        UpdateHeader(f, SYSTEM.VAL(FileDir.FileHeader, buf.data)); f.modH := FALSE
      END
    ELSE i := (buf.apos - STS) DIV XS; inx := f.ext[i];
      IF inx = NIL THEN
        NEW(inx); inx.adr := 0; inx.sec[0] := 0; f.ext[i] := inx; f.modH := TRUE
      END ;
      k := (buf.apos - STS) MOD XS; secadr := inx.sec[k];
      IF secadr = 0 THEN
        Kernel.AllocSector(f.sechint, secadr);
        f.modH := TRUE; inx.mod := TRUE; inx.sec[k] := secadr; f.sechint := secadr
      END
    END ;
    Kernel.PutSector(secadr, buf.data); buf.mod := FALSE
  END WriteBuf;

  PROCEDURE Buf(f: File; pos: INTEGER): Buffer;
    VAR buf!: Buffer;
  BEGIN buf := f.firstbuf;
    WHILE (buf.apos # pos) & (buf.next # f.firstbuf) DO buf := buf.next END ;
    IF buf.apos # pos THEN buf := NIL END ;
    RETURN buf
  END Buf;

  PROCEDURE GetBuf(f: File; pos: INTEGER): Buffer;
    VAR buf!: Buffer;
  BEGIN buf := f.firstbuf;
    WHILE (buf.apos # pos) & (buf.next # f.firstbuf) DO buf := buf.next END ;
    IF buf.apos # pos THEN 
      IF f.nofbufs < MaxBufs THEN  (*allocate new buffer*)
        NEW(buf); buf.next := f.firstbuf.next; f.firstbuf.next := buf; INC(f.nofbufs)
      ELSE (*reuse a buffer*) f.firstbuf := buf;
        IF buf.mod THEN WriteBuf(f, buf) END
      END ;
      IF pos <= f.aleng THEN ReadBuf(f, buf, pos) ELSE buf.apos := pos; buf.lim := 0; buf.mod := FALSE END
    END ;
    RETURN buf
  END GetBuf;

  PROCEDURE Unbuffer(f: File);
    VAR i, k: INTEGER;
      buf!: Buffer;
      inx!: Index;
      head!: FileDir.FileHd;
  BEGIN NEW(head); buf := f.firstbuf;
    REPEAT
      IF buf.mod THEN WriteBuf(f, buf) END ;
      buf := buf.next
    UNTIL buf = f.firstbuf;
    k := (f.aleng + (XS-STS)) DIV XS; i := 0;
    WHILE i < k DO
      inx := f.ext[i]; INC(i);
      IF inx.mod THEN
        IF inx.adr = 0 THEN
          Kernel.AllocSector(f.sechint, inx.adr); f.sechint := inx.adr; f.modH := TRUE
        END ;
        Kernel.PutSector(inx.adr, inx.sec); inx.mod := FALSE
      END
    END ;
    IF f.modH THEN
      Kernel.GetSector(f.sec[0], head^); UpdateHeader(f, head^);
      Kernel.PutSector(f.sec[0], head^); f.modH := FALSE
    END
  END Unbuffer;

  PROCEDURE Register*(f: File);
  BEGIN
    IF (f # NIL) & (f.name[0] # 0X) THEN
      Unbuffer(f);
      IF ~f.registered THEN
        FileDir.Insert(f.name, f.sec[0]); f.registered := TRUE; f.next := root; root := SYSTEM.VAL(INTEGER, f)
      END
    END
  END Register;

  PROCEDURE Close*(f: File);
  BEGIN
    IF f # NIL THEN Unbuffer(f) END
  END Close;

  PROCEDURE Purge*(f: File);
    VAR a, i, j, k: INTEGER;
      ind: FileDir.IndexSector;
  BEGIN
    IF f # NIL THEN a := f.aleng + 1; f.aleng := 0; f.bleng := HS;
      IF a <= STS THEN i := a;
      ELSE i := STS; DEC(a, i); j := (a-1) MOD XS; k := (a-1) DIV XS;
        WHILE k >= 0 DO
          Kernel.GetSector(f.ext[k].adr, ind);
          REPEAT DEC(j); Kernel.FreeSector(ind[j]) UNTIL j = 0;
          Kernel.FreeSector(f.ext[k].adr); j := XS; DEC(k)
        END
      END ;
      REPEAT DEC(i); Kernel.FreeSector(f.sec[i]) UNTIL i = 0
    END
  END Purge;

  PROCEDURE Delete*(name: ARRAY OF CHAR; VAR res: INTEGER);
    VAR adr: DiskAdr;
        namebuf: FileDir.FileName;
  BEGIN Check(name, namebuf, res);
    IF res = 0 THEN
      FileDir.Delete(namebuf, adr);
      IF adr = 0 THEN res := 2 END
    END
  END Delete;

  PROCEDURE Rename*(old, new: ARRAY OF CHAR; VAR res: INTEGER);
    VAR adr: DiskAdr;
        oldbuf, newbuf: FileDir.FileName;
        head!: FileDir.FileHd;
  BEGIN NEW(head); Check(old, oldbuf, res);
    IF res = 0 THEN
      Check(new, newbuf, res);
      IF res = 0 THEN
        FileDir.Delete(oldbuf, adr);
        IF adr # 0 THEN
          FileDir.Insert(newbuf, adr);
          Kernel.GetSector(adr, head^); head.name := newbuf; Kernel.PutSector(adr, head^)
        ELSE res := 2
        END
      END
    END
  END Rename;

  PROCEDURE Length*(f: File): INTEGER;
  BEGIN RETURN f.aleng * SS + f.bleng - HS
  END Length;

  PROCEDURE Date*(f: File): INTEGER;
  BEGIN RETURN f.date
  END Date;

  (*---------------------------Read---------------------------*)

  PROCEDURE Set*(VAR r: Rider; f: File; pos: INTEGER);
    VAR a, b: INTEGER;
  BEGIN  r.eof := FALSE; r.res := 0;
    IF f # NIL THEN
      IF pos < 0 THEN a := 0; b := HS
      ELSIF pos < f.aleng * SS + f.bleng - HS THEN
        a := (pos + HS) DIV SS; b := (pos + HS) MOD SS;
      ELSE a := f.aleng; b := f.bleng
      END ;
      r.file := f; r.apos := a; r.bpos := b; r.buf := f.firstbuf
    ELSE r.file:= NIL
    END
  END Set;

  PROCEDURE Pos*(VAR r: Rider): INTEGER;
  BEGIN RETURN r.apos * SS + r.bpos - HS
  END Pos;

  PROCEDURE Base*(VAR r: Rider): File;
  BEGIN RETURN r.file
  END Base;

  PROCEDURE ReadByte*(VAR r: Rider; VAR x: BYTE);
    VAR buf!: Buffer;
  BEGIN
    IF r.apos # r.buf.apos THEN r.buf := GetBuf(r.file, r.apos) END ;
    IF r.bpos < r.buf.lim THEN x := r.buf.data[r.bpos]; INC(r.bpos)
    ELSIF r.apos < r.file.aleng THEN
      INC(r.apos); buf := Buf(r.file, r.apos);
      IF buf = NIL THEN
        IF r.buf.mod THEN WriteBuf(r.file, r.buf) END ;
        ReadBuf(r.file, r.buf, r.apos)
      ELSE r.buf := buf
      END ;
      x := r.buf.data[0]; r.bpos := 1
    ELSE x := 0; r.eof := TRUE
    END
  END ReadByte;

  PROCEDURE ReadBytes*(VAR r: Rider; VAR x: ARRAY OF BYTE; n: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0;  (*this implementation is to be improved*)
    WHILE i < n DO ReadByte(r, x[i]); INC(i) END
  END ReadBytes;

  PROCEDURE Read*(VAR r: Rider; VAR ch: CHAR);
    VAR buf!: Buffer;  (*same as ReadByte*)
  BEGIN
    IF r.apos # r.buf.apos THEN r.buf := GetBuf(r.file, r.apos) END ;
    IF r.bpos < r.buf.lim THEN ch := CHR(r.buf.data[r.bpos]); INC(r.bpos)
    ELSIF r.apos < r.file.aleng THEN
      INC(r.apos); buf := Buf(r.file, r.apos);
      IF buf = NIL THEN
        IF r.buf.mod THEN WriteBuf(r.file, r.buf) END ;
        ReadBuf(r.file, r.buf, r.apos)
      ELSE r.buf := buf
      END ;
      ch := CHR(r.buf.data[0]); r.bpos := 1
    ELSE ch := 0X; r.eof := TRUE
    END
  END Read;

  PROCEDURE ReadInt*(VAR R: Rider; VAR x: INTEGER);
    VAR x0, x1, x2, x3: BYTE;
  BEGIN ReadByte(R, x0); ReadByte(R, x1); ReadByte(R, x2); ReadByte(R, x3);
    x := ((x3 * 100H + x2) * 100H + x1) * 100H + x0
  END ReadInt;

  PROCEDURE ReadSet*(VAR R: Rider; VAR s: SET);
  BEGIN ReadInt(R, SYSTEM.VAL(INTEGER, s))
  END ReadSet;

  PROCEDURE ReadReal*(VAR R: Rider; VAR x: REAL);
    VAR n: INTEGER;
  BEGIN ReadInt(R, SYSTEM.VAL(INTEGER, x))
  END ReadReal;

  PROCEDURE ReadString*(VAR R: Rider; VAR x: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR;
  BEGIN i := 0; Read(R, ch);
    WHILE ch # 0X DO
      IF i < LEN(x)-1 THEN x[i] := ch; INC(i) END ;
      Read(R, ch)
    END ;
    x[i] := 0X
  END ReadString;

  PROCEDURE ReadNum*(VAR R: Rider; VAR x: INTEGER);
    VAR n, y: INTEGER; b: BYTE;
  BEGIN n := 32; y := 0; ReadByte(R, b);
    WHILE b >= 80H DO y := ROR(y + b-80H, 7); DEC(n, 7); ReadByte(R, b) END ;
    IF n <= 4 THEN x := ROR(y + b MOD 10H, 4) ELSE x := ASR(ROR(y + b, 7), n-7) END
  END ReadNum;
        
  (*---------------------------Write---------------------------*)

  PROCEDURE NewExt(f: File);
    VAR i, k: INTEGER; ext!: Index;
  BEGIN k := (f.aleng - STS) DIV XS;
    NEW(ext); ext.adr := 0; ext.mod := TRUE; f.ext[k] := ext; i := XS;
    REPEAT DEC(i); ext.sec[i] := 0 UNTIL i = 0
  END NewExt;

  PROCEDURE WriteByte*(VAR r: Rider; x: BYTE);
    VAR f!: File; buf!: Buffer;
  BEGIN
    IF r.apos # r.buf.apos THEN r.buf := GetBuf(r.file, r.apos); END ;
    IF r.bpos >= r.buf.lim THEN
      IF r.bpos < SS THEN
        INC(r.buf.lim); INC(r.file.bleng); r.file.modH := TRUE
      ELSE f := r.file; WriteBuf(f, r.buf); INC(r.apos); buf := Buf(r.file, r.apos);
        IF buf = NIL THEN
          IF r.apos <= f.aleng THEN ReadBuf(f, r.buf, r.apos)
          ELSE r.buf.apos := r.apos; r.buf.lim := 1; f.aleng := f.aleng + 1; f.bleng := 1; f.modH := TRUE;
            IF (f.aleng - STS) MOD XS = 0 THEN NewExt(f) END
          END
        ELSE r.buf := buf
        END ;
        r.bpos := 0
      END
    END ;
    r.buf.data[r.bpos] := x; INC(r.bpos); r.buf.mod := TRUE
  END WriteByte;

  PROCEDURE WriteBytes*(VAR r: Rider; x: ARRAY OF BYTE; n: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0; (*this implementation is to be improed*)
    WHILE i < n DO WriteByte(r, x[i]); INC(i) END
  END WriteBytes;

  PROCEDURE Write*(VAR r: Rider; ch: CHAR);
    VAR f!: File; buf!: Buffer;
  BEGIN (*same as WriteByte*)
    IF r.apos # r.buf.apos THEN r.buf := GetBuf(r.file, r.apos); END ;
    IF r.bpos >= r.buf.lim THEN
      IF r.bpos < SS THEN
        INC(r.buf.lim); INC(r.file.bleng); r.file.modH := TRUE
      ELSE f := r.file; WriteBuf(f, r.buf); INC(r.apos); buf := Buf(r.file, r.apos);
        IF buf = NIL THEN
          IF r.apos <= f.aleng THEN ReadBuf(f, r.buf, r.apos)
          ELSE r.buf.apos := r.apos; r.buf.lim := 1; f.aleng := f.aleng + 1; f.bleng := 1; f.modH := TRUE;
            IF (f.aleng - STS) MOD XS = 0 THEN NewExt(f) END
          END
        ELSE r.buf := buf
        END ;
        r.bpos := 0
      END
    END ;
    r.buf.data[r.bpos] := ORD(ch); INC(r.bpos); r.buf.mod := TRUE
  END Write;

  PROCEDURE WriteInt*(VAR R: Rider; x: INTEGER);
  BEGIN WriteByte(R, x MOD 100H);
    WriteByte(R, x DIV 100H MOD 100H);
    WriteByte(R, x DIV 10000H MOD 100H);
    WriteByte(R, x DIV 1000000H MOD 100H)
  END WriteInt;

  PROCEDURE WriteSet*(VAR R: Rider; s: SET);
  BEGIN WriteInt(R, ORD(s))
  END WriteSet;

  PROCEDURE WriteReal*(VAR R: Rider; x: REAL);
  BEGIN  WriteInt(R, ORD(x))
  END WriteReal;

  PROCEDURE WriteString*(VAR R: Rider; x: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR;
  BEGIN i := 0;
    REPEAT ch := x[i]; Write(R, ch); INC(i) UNTIL ch = 0X
  END WriteString;

  PROCEDURE WriteNum*(VAR R: Rider; x: INTEGER);
  BEGIN
    WHILE (x < -40H) OR (x >= 40H) DO WriteByte(R, x MOD 80H + 80H); x := ASR(x, 7) END ;
    WriteByte(R, x MOD 80H)
  END WriteNum;

  (*---------------------------System use---------------------------*)

  PROCEDURE RestoreList*; (*after mark phase of garbage collection*)
    VAR f, f0: INTEGER;

    PROCEDURE mark(f: INTEGER): INTEGER;
      VAR m: INTEGER;
    BEGIN
      IF f = 0 THEN m := -1 ELSE SYSTEM.GET(f-4, m) END ;
      RETURN m
    END mark;

  BEGIN (*field "next" has offset 0*)
    WHILE mark(root) = 0 DO SYSTEM.GET(root, root) END ;
    f := root;
    WHILE f # 0 DO
      f0 := f;
      REPEAT SYSTEM.GET(f0, f0) UNTIL mark(f0) # 0;
      SYSTEM.PUT(f, f0); f := f0
    END
  END RestoreList;

BEGIN root := 0;
END Files.

OM4Tool.DecObj Files.m4c
decode Files.m4c
Files 8C405D7D   2   7268
imports:
	Kernel B4228008
	FileDir 486CC119
type descriptors
 00000020 FFFFFFFF FFFFFFFF FFFFFFFF 00000014 00000008 FFFFFFFF 00000200 FFFFFFFF FFFFFFFF FFFFFFFF 00000040 00000044 00000048 0000004C 00000050 00000054 00000058 0000005C 00000060 00000064 00000068 0000006C 00000014 FFFFFFFF 00000500 FFFFFFFF FFFFFFFF FFFFFFFF 0000000C FFFFFFFF 00000500 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
strings

data     4
code
commands:
	RestoreList 00001A6E
entries
 00001ADA 0000001C 00000000 00000140 00000432 00000D56 00000DE0 00000DFA 00000F24 00000F5E 00001002 0000102E 00001046 00001108 00001124 00001134 0000124C 00001288 000013A0 000013FC 00001412 0000142A 00001498 000015AE 0000175A 00001798 00001944 0000198E 000019A4 000019BA 000019FC 00001A6E
pointer refs

fixP =  00000FEC
fixV =  00001ADE
fixC =  00001534
fixT =  00000000
entry =  00001ADA
 00000000	     B082	SUB SP SP #8
 00000002	     B40F	PUSH R0 R1 R2 R3
 00000004	     B500	PUSH LR
 00000006	     2000	MOVS R0 #0
 00000008	     9902	LDR R1 [ SP + 8 ]
 0000000A	     4288	CMP R0 R1
 0000000C	     BF28	IT CS
 0000000E	 EC00E4D1	TrapCS 1 at pos 1869
 00000012	     9901	LDR R1 [ SP + 4 ]
 00000014	     1808	ADDS R0 R1 R0
 00000016	     7800	LDRB R0 [ R0 + 0 ]
 00000018	 F88D0018	STRB R0 [  SP + 24 ]
 0000001C	     2000	MOVS R0 #0
 0000001E	     9005	STR R0 [ SP + 20 ]
 00000020	 F89D0018	LDRB R0 [ SP + 24 ]
 00000024	     2841	CMP R0 #65
 00000026	 F2C08005	BLT #10, goes to  00000034
 0000002A	 F89D0018	LDRB R0 [ SP + 24 ]
 0000002E	     285A	CMP R0 #90
 00000030	 F340800A	BLE #20, goes to  00000048
 00000034	 F89D0018	LDRB R0 [ SP + 24 ]
 00000038	     2861	CMP R0 #97
 0000003A	 F2C0806C	BLT #216, goes to  00000116
 0000003E	 F89D0018	LDRB R0 [ SP + 24 ]
 00000042	     287A	CMP R0 #122
 00000044	 F3008067	BGT #206, goes to  00000116
 00000048	     9805	LDR R0 [ SP + 20 ]
 0000004A	     2820	CMP R0 #32
 0000004C	     BF28	IT CS
 0000004E	 EC00F2E1	TrapCS 1 at pos 1966
 00000052	     9903	LDR R1 [ SP + 12 ]
 00000054	     1808	ADDS R0 R1 R0
 00000056	 F89D1018	LDRB R1 [ SP + 24 ]
 0000005A	     7001	STRB R1 [ R0 + 0 ]
 0000005C	     9805	LDR R0 [ SP + 20 ]
 0000005E	     1C40	ADDS R0 R0 #1
 00000060	     9005	STR R0 [ SP + 20 ]
 00000062	     9805	LDR R0 [ SP + 20 ]
 00000064	     9902	LDR R1 [ SP + 8 ]
 00000066	     4288	CMP R0 R1
 00000068	     BF28	IT CS
 0000006A	 EC00F481	TrapCS 1 at pos 1992
 0000006E	     9901	LDR R1 [ SP + 4 ]
 00000070	     1808	ADDS R0 R1 R0
 00000072	     7800	LDRB R0 [ R0 + 0 ]
 00000074	 F88D0018	STRB R0 [  SP + 24 ]
 00000078	 F89D0018	LDRB R0 [ SP + 24 ]
 0000007C	     2830	CMP R0 #48
 0000007E	 F2C08005	BLT #10, goes to  0000008C
 00000082	 F89D0018	LDRB R0 [ SP + 24 ]
 00000086	     2839	CMP R0 #57
 00000088	 F3408019	BLE #50, goes to  000000BE
 0000008C	 F89D0018	LDRB R0 [ SP + 24 ]
 00000090	     2841	CMP R0 #65
 00000092	 F2C08005	BLT #10, goes to  000000A0
 00000096	 F89D0018	LDRB R0 [ SP + 24 ]
 0000009A	     285A	CMP R0 #90
 0000009C	 F340800F	BLE #30, goes to  000000BE
 000000A0	 F89D0018	LDRB R0 [ SP + 24 ]
 000000A4	     2861	CMP R0 #97
 000000A6	 F2C08005	BLT #10, goes to  000000B4
 000000AA	 F89D0018	LDRB R0 [ SP + 24 ]
 000000AE	     287A	CMP R0 #122
 000000B0	 F3408005	BLE #10, goes to  000000BE
 000000B4	 F89D0018	LDRB R0 [ SP + 24 ]
 000000B8	     282E	CMP R0 #46
 000000BA	 F0408003	BNE #6, goes to  000000C4
 000000BE	     9805	LDR R0 [ SP + 20 ]
 000000C0	     2820	CMP R0 #32
 000000C2	     D1C1	BNE #-126, goes to  00000048
 000000C4	     9805	LDR R0 [ SP + 20 ]
 000000C6	     2820	CMP R0 #32
 000000C8	 F0408005	BNE #10, goes to  000000D6
 000000CC	     2004	MOVS R0 #4
 000000CE	     9904	LDR R1 [ SP + 16 ]
 000000D0	     6008	STR R0 [  R1 + 0 ]
 000000D2	 F000B81E	B #60, goes to  00000112
 000000D6	 F89D0018	LDRB R0 [ SP + 24 ]
 000000DA	     2800	CMP R0 #0
 000000DC	 F0408016	BNE #44, goes to  0000010C
 000000E0	     2000	MOVS R0 #0
 000000E2	     9904	LDR R1 [ SP + 16 ]
 000000E4	     6008	STR R0 [  R1 + 0 ]
 000000E6	     9805	LDR R0 [ SP + 20 ]
 000000E8	     2820	CMP R0 #32
 000000EA	 F280800D	BGE #26, goes to  00000108
 000000EE	     9805	LDR R0 [ SP + 20 ]
 000000F0	     2820	CMP R0 #32
 000000F2	     BF28	IT CS
 000000F4	 EC011591	TrapCS 1 at pos 2265
 000000F8	     9903	LDR R1 [ SP + 12 ]
 000000FA	     1808	ADDS R0 R1 R0
 000000FC	     2100	MOVS R1 #0
 000000FE	     7001	STRB R1 [ R0 + 0 ]
 00000100	     9805	LDR R0 [ SP + 20 ]
 00000102	     1C40	ADDS R0 R0 #1
 00000104	     9005	STR R0 [ SP + 20 ]
 00000106	     E7EE	B #-36, goes to  000000E6
 00000108	 F000B803	B #6, goes to  00000112
 0000010C	     2005	MOVS R0 #5
 0000010E	     9904	LDR R1 [ SP + 16 ]
 00000110	     6008	STR R0 [  R1 + 0 ]
 00000112	 F000B811	B #34, goes to  00000138
 00000116	 F89D0018	LDRB R0 [ SP + 24 ]
 0000011A	     2800	CMP R0 #0
 0000011C	 F0408009	BNE #18, goes to  00000132
 00000120	     2000	MOVS R0 #0
 00000122	     9903	LDR R1 [ SP + 12 ]
 00000124	     7008	STRB R0 [ R1 + 0 ]
 00000126	 F05F30FF	MOVS R0 #-1
 0000012A	     9904	LDR R1 [ SP + 16 ]
 0000012C	     6008	STR R0 [  R1 + 0 ]
 0000012E	 F000B803	B #6, goes to  00000138
 00000132	     2003	MOVS R0 #3
 00000134	     9904	LDR R1 [ SP + 16 ]
 00000136	     6008	STR R0 [  R1 + 0 ]
 00000138	 F85DEB04	LDR LR [ SP ] + 4
 0000013C	     B006	ADD SP SP #24
 0000013E	     4770	BX LR
 00000140	     B090	SUB SP SP #64
 00000142	     B403	PUSH R0 R1
 00000144	     B500	PUSH LR
 00000146	     2000	MOVS R0 #0
 00000148	     9006	STR R0 [ SP + 24 ]
 0000014A	     9801	LDR R0 [ SP + 4 ]
 0000014C	     9902	LDR R1 [ SP + 8 ]
 0000014E	     AA0A	ADD R2 SP #40
 00000150	     AB05	ADD R3 SP #20
 00000152	 F7FFFF55	BL #-342, goes to  00000000
 00000156	     9805	LDR R0 [ SP + 20 ]
 00000158	     2800	CMP R0 #0
 0000015A	 F0408165	BNE #714, goes to  00000428
 0000015E	     A80A	ADD R0 SP #40
 00000160	     A907	ADD R1 SP #28
 00000162	 204000B1	BL Mod(  2) proc(4)
 00000166	     9807	LDR R0 [ SP + 28 ]
 00000168	     2800	CMP R0 #0
 0000016A	 F000815D	BEQ #698, goes to  00000428
 0000016E	 000000B7	MOV R0 lower 16-bits base(0), next at  00000000
 00000172	 00000000	MOVT R0 higher 16-bits var + 0
 00000176	     6800	LDR R0 [ R0 + 0 ]
 00000178	     9006	STR R0 [ SP + 24 ]
 0000017A	     9806	LDR R0 [ SP + 24 ]
 0000017C	     2800	CMP R0 #0
 0000017E	 F0008012	BEQ #36, goes to  000001A6
 00000182	     9806	LDR R0 [ SP + 24 ]
 00000184	     2800	CMP R0 #0
 00000186	     BF08	IT EQ
 00000188	 EC0157C4	TrapEQ 4 at pos 2812
 0000018C	     6F00	LDR R0 [ R0 + 112 ]
 0000018E	     9907	LDR R1 [ SP + 28 ]
 00000190	     4288	CMP R0 R1
 00000192	 F0008008	BEQ #16, goes to  000001A6
 00000196	     9806	LDR R0 [ SP + 24 ]
 00000198	     2800	CMP R0 #0
 0000019A	     BF08	IT EQ
 0000019C	 EC016294	TrapEQ 4 at pos 2857
 000001A0	     6800	LDR R0 [ R0 + 0 ]
 000001A2	     9006	STR R0 [ SP + 24 ]
 000001A4	     E7E9	B #-46, goes to  0000017A
 000001A6	     9806	LDR R0 [ SP + 24 ]
 000001A8	     2800	CMP R0 #0
 000001AA	 F040813D	BNE #634, goes to  00000428
 000001AE	     A808	ADD R0 SP #32
 000001B0	 100000D8	MOV R1 lower 16-bits base(0), next at  00000000
 000001B4	 00000064	MOVT R1 higher 16-bits const + 100
 000001B8	     DF00	SVC #0
 000001BA	     9808	LDR R0 [ SP + 32 ]
 000001BC	     2800	CMP R0 #0
 000001BE	     BF08	IT EQ
 000001C0	 EC0167E4	TrapEQ 4 at pos 2942
 000001C4	     2100	MOVS R1 #0
 000001C6	     6001	STR R1 [  R0 + 0 ]
 000001C8	     9808	LDR R0 [ SP + 32 ]
 000001CA	     2800	CMP R0 #0
 000001CC	     BF08	IT EQ
 000001CE	 EC0170D4	TrapEQ 4 at pos 2957
 000001D2	     9908	LDR R1 [ SP + 32 ]
 000001D4	     60C1	STR R1 [  R0 + 12 ]
 000001D6	     9808	LDR R0 [ SP + 32 ]
 000001D8	     2800	CMP R0 #0
 000001DA	     BF08	IT EQ
 000001DC	 EC0171D4	TrapEQ 4 at pos 2973
 000001E0	     2100	MOVS R1 #0
 000001E2	     7201	STRB R1 [ R0 + 8 ]
 000001E4	     9808	LDR R0 [ SP + 32 ]
 000001E6	     2800	CMP R0 #0
 000001E8	     BF08	IT EQ
 000001EA	 EC017654	TrapEQ 4 at pos 3045
 000001EE	     3010	ADDS R0 R0 #16
 000001F0	     9009	STR R0 [ SP + 36 ]
 000001F2	     9807	LDR R0 [ SP + 28 ]
 000001F4	     9908	LDR R1 [ SP + 32 ]
 000001F6	     2900	CMP R1 #0
 000001F8	     BF08	IT EQ
 000001FA	 EC018144	TrapEQ 4 at pos 3092
 000001FE	     3110	ADDS R1 R1 #16
 00000200	 1150004F	BL Mod(  1) proc(21)
 00000204	     9809	LDR R0 [ SP + 36 ]
 00000206	     2800	CMP R0 #0
 00000208	     BF08	IT EQ
 0000020A	 EC018244	TrapEQ 4 at pos 3108
 0000020E	     6800	LDR R0 [ R0 + 0 ]
 00000210	 F6415186	MOV R1 #7558
 00000214	 F6C931A7	MOVT R1 #39847
 00000218	     4288	CMP R0 R1
 0000021A	     BF18	IT NE
 0000021C	 EC0183B7	TrapNE 7 at pos 3131
 00000220	     A806	ADD R0 SP #24
 00000222	 10000039	MOV R1 lower 16-bits base(0), next at  000001B0
 00000226	 0000001C	MOVT R1 higher 16-bits const + 28
 0000022A	     DF00	SVC #0
 0000022C	     9806	LDR R0 [ SP + 24 ]
 0000022E	     2800	CMP R0 #0
 00000230	     BF08	IT EQ
 00000232	 EC018554	TrapEQ 4 at pos 3157
 00000236	     9909	LDR R1 [ SP + 36 ]
 00000238	     2900	CMP R1 #0
 0000023A	     BF08	IT EQ
 0000023C	 EC018604	TrapEQ 4 at pos 3168
 00000240	     6A49	LDR R1 [ R1 + 36 ]
 00000242	     6081	STR R1 [  R0 + 8 ]
 00000244	     9806	LDR R0 [ SP + 24 ]
 00000246	     2800	CMP R0 #0
 00000248	     BF08	IT EQ
 0000024A	 EC018694	TrapEQ 4 at pos 3177
 0000024E	     9909	LDR R1 [ SP + 36 ]
 00000250	     2900	CMP R1 #0
 00000252	     BF08	IT EQ
 00000254	 EC018744	TrapEQ 4 at pos 3188
 00000258	     6A89	LDR R1 [ R1 + 40 ]
 0000025A	     60C1	STR R1 [  R0 + 12 ]
 0000025C	     9806	LDR R0 [ SP + 24 ]
 0000025E	     2800	CMP R0 #0
 00000260	     BF08	IT EQ
 00000262	 EC0187C4	TrapEQ 4 at pos 3196
 00000266	     9909	LDR R1 [ SP + 36 ]
 00000268	     2900	CMP R1 #0
 0000026A	     BF08	IT EQ
 0000026C	 EC019064	TrapEQ 4 at pos 3206
 00000270	     6AC9	LDR R1 [ R1 + 44 ]
 00000272	     63C1	STR R1 [  R0 + 60 ]
 00000274	     9806	LDR R0 [ SP + 24 ]
 00000276	     2800	CMP R0 #0
 00000278	     BF08	IT EQ
 0000027A	 EC0191C4	TrapEQ 4 at pos 3228
 0000027E	     6880	LDR R0 [ R0 + 8 ]
 00000280	     2800	CMP R0 #0
 00000282	 F040800E	BNE #28, goes to  000002A2
 00000286	     9808	LDR R0 [ SP + 32 ]
 00000288	     2800	CMP R0 #0
 0000028A	     BF08	IT EQ
 0000028C	 EC0192D4	TrapEQ 4 at pos 3245
 00000290	     9906	LDR R1 [ SP + 24 ]
 00000292	     2900	CMP R1 #0
 00000294	     BF08	IT EQ
 00000296	 EC019384	TrapEQ 4 at pos 3256
 0000029A	     68C9	LDR R1 [ R1 + 12 ]
 0000029C	     6041	STR R1 [  R0 + 4 ]
 0000029E	 F000B808	B #16, goes to  000002B2
 000002A2	     9808	LDR R0 [ SP + 32 ]
 000002A4	     2800	CMP R0 #0
 000002A6	     BF08	IT EQ
 000002A8	 EC019454	TrapEQ 4 at pos 3269
 000002AC	 F45F6180	MOVS R1 #1024
 000002B0	     6041	STR R1 [  R0 + 4 ]
 000002B2	     9806	LDR R0 [ SP + 24 ]
 000002B4	     2800	CMP R0 #0
 000002B6	     BF08	IT EQ
 000002B8	 EC019664	TrapEQ 4 at pos 3302
 000002BC	     9908	LDR R1 [ SP + 32 ]
 000002BE	     6141	STR R1 [  R0 + 20 ]
 000002C0	     9806	LDR R0 [ SP + 24 ]
 000002C2	     2800	CMP R0 #0
 000002C4	     BF08	IT EQ
 000002C6	 EC019784	TrapEQ 4 at pos 3320
 000002CA	     2101	MOVS R1 #1
 000002CC	     6041	STR R1 [  R0 + 4 ]
 000002CE	     9806	LDR R0 [ SP + 24 ]
 000002D0	     2800	CMP R0 #0
 000002D2	     BF08	IT EQ
 000002D4	 EC01A054	TrapEQ 4 at pos 3333
 000002D8	     301C	ADDS R0 R0 #28
 000002DA	     A90A	ADD R1 SP #40
 000002DC	     2208	MOVS R2 #8
 000002DE	 F8513B04	LDR R3 [ R1 ] + 4
 000002E2	 F8403B04	STR R3 [  R0 ] + 4
 000002E6	     1E52	SUBS R2 R2 #1
 000002E8	     D1F9	BNE #-14, goes to  000002DE
 000002EA	     9806	LDR R0 [ SP + 24 ]
 000002EC	     2800	CMP R0 #0
 000002EE	     BF08	IT EQ
 000002F0	 EC01A1E4	TrapEQ 4 at pos 3358
 000002F4	     2101	MOVS R1 #1
 000002F6	     7441	STRB R1 [ R0 + 17 ]
 000002F8	     9806	LDR R0 [ SP + 24 ]
 000002FA	     2800	CMP R0 #0
 000002FC	     BF08	IT EQ
 000002FE	 EC01A374	TrapEQ 4 at pos 3383
 00000302	     9909	LDR R1 [ SP + 36 ]
 00000304	     2900	CMP R1 #0
 00000306	     BF08	IT EQ
 00000308	 EC01A404	TrapEQ 4 at pos 3392
 0000030C	     3070	ADDS R0 R0 #112
 0000030E	     3160	ADDS R1 R1 #96
 00000310	     2240	MOVS R2 #64
 00000312	 F8513B04	LDR R3 [ R1 ] + 4
 00000316	 F8403B04	STR R3 [  R0 ] + 4
 0000031A	     1E52	SUBS R2 R2 #1
 0000031C	     D1F9	BNE #-14, goes to  00000312
 0000031E	     9806	LDR R0 [ SP + 24 ]
 00000320	     2800	CMP R0 #0
 00000322	     BF08	IT EQ
 00000324	 EC01A594	TrapEQ 4 at pos 3417
 00000328	     6880	LDR R0 [ R0 + 8 ]
 0000032A	     30C0	ADDS R0 R0 #192
 0000032C	     1200	ASRS R0 R0 #8
 0000032E	     9004	STR R0 [ SP + 16 ]
 00000330	     2000	MOVS R0 #0
 00000332	     9003	STR R0 [ SP + 12 ]
 00000334	     9803	LDR R0 [ SP + 12 ]
 00000336	     9904	LDR R1 [ SP + 16 ]
 00000338	     4288	CMP R0 R1
 0000033A	 F2808040	BGE #128, goes to  000003BE
 0000033E	     A812	ADD R0 SP #72
 00000340	 1000008F	MOV R1 lower 16-bits base(0), next at  00000222
 00000344	 0000007C	MOVT R1 higher 16-bits const + 124
 00000348	     DF00	SVC #0
 0000034A	     9812	LDR R0 [ SP + 72 ]
 0000034C	     2800	CMP R0 #0
 0000034E	     BF08	IT EQ
 00000350	 EC01B304	TrapEQ 4 at pos 3504
 00000354	     9909	LDR R1 [ SP + 36 ]
 00000356	     2900	CMP R1 #0
 00000358	     BF08	IT EQ
 0000035A	 EC01B394	TrapEQ 4 at pos 3513
 0000035E	     9A03	LDR R2 [ SP + 12 ]
 00000360	     2A0C	CMP R2 #12
 00000362	     BF28	IT CS
 00000364	 EC01B3C1	TrapCS 1 at pos 3516
 00000368	 EB110182	ADDS R1 R1 R2 LSL #2
 0000036C	     6B09	LDR R1 [ R1 + 48 ]
 0000036E	     6001	STR R1 [  R0 + 0 ]
 00000370	     9812	LDR R0 [ SP + 72 ]
 00000372	     2800	CMP R0 #0
 00000374	     BF08	IT EQ
 00000376	 EC01B474	TrapEQ 4 at pos 3527
 0000037A	     2100	MOVS R1 #0
 0000037C	     7101	STRB R1 [ R0 + 4 ]
 0000037E	     9812	LDR R0 [ SP + 72 ]
 00000380	     2800	CMP R0 #0
 00000382	     BF08	IT EQ
 00000384	 EC01B784	TrapEQ 4 at pos 3576
 00000388	     6800	LDR R0 [ R0 + 0 ]
 0000038A	     9912	LDR R1 [ SP + 72 ]
 0000038C	     2900	CMP R1 #0
 0000038E	     BF08	IT EQ
 00000390	 EC01C034	TrapEQ 4 at pos 3587
 00000394	     3108	ADDS R1 R1 #8
 00000396	 115000CB	BL Mod(  1) proc(21)
 0000039A	     9806	LDR R0 [ SP + 24 ]
 0000039C	     2800	CMP R0 #0
 0000039E	     BF08	IT EQ
 000003A0	 EC01C0B4	TrapEQ 4 at pos 3595
 000003A4	     9903	LDR R1 [ SP + 12 ]
 000003A6	     290C	CMP R1 #12
 000003A8	     BF28	IT CS
 000003AA	 EC01C0E1	TrapCS 1 at pos 3598
 000003AE	 EB100081	ADDS R0 R0 R1 LSL #2
 000003B2	     9912	LDR R1 [ SP + 72 ]
 000003B4	     6401	STR R1 [  R0 + 64 ]
 000003B6	     9803	LDR R0 [ SP + 12 ]
 000003B8	     1C40	ADDS R0 R0 #1
 000003BA	     9003	STR R0 [ SP + 12 ]
 000003BC	     E7BA	B #-140, goes to  00000334
 000003BE	     9803	LDR R0 [ SP + 12 ]
 000003C0	     280C	CMP R0 #12
 000003C2	 F2808012	BGE #36, goes to  000003EA
 000003C6	     9806	LDR R0 [ SP + 24 ]
 000003C8	     2800	CMP R0 #0
 000003CA	     BF08	IT EQ
 000003CC	 EC01C5E4	TrapEQ 4 at pos 3678
 000003D0	     9903	LDR R1 [ SP + 12 ]
 000003D2	     290C	CMP R1 #12
 000003D4	     BF28	IT CS
 000003D6	 EC01C611	TrapCS 1 at pos 3681
 000003DA	 EB100081	ADDS R0 R0 R1 LSL #2
 000003DE	     2100	MOVS R1 #0
 000003E0	     6401	STR R1 [  R0 + 64 ]
 000003E2	     9803	LDR R0 [ SP + 12 ]
 000003E4	     1C40	ADDS R0 R0 #1
 000003E6	     9003	STR R0 [ SP + 12 ]
 000003E8	     E7E9	B #-46, goes to  000003BE
 000003EA	     9806	LDR R0 [ SP + 24 ]
 000003EC	     2800	CMP R0 #0
 000003EE	     BF08	IT EQ
 000003F0	 EC01D0A4	TrapEQ 4 at pos 3722
 000003F4	     9907	LDR R1 [ SP + 28 ]
 000003F6	     6181	STR R1 [  R0 + 24 ]
 000003F8	     9806	LDR R0 [ SP + 24 ]
 000003FA	     2800	CMP R0 #0
 000003FC	     BF08	IT EQ
 000003FE	 EC01D1C4	TrapEQ 4 at pos 3740
 00000402	     2100	MOVS R1 #0
 00000404	     7401	STRB R1 [ R0 + 16 ]
 00000406	     9806	LDR R0 [ SP + 24 ]
 00000408	     2800	CMP R0 #0
 0000040A	     BF08	IT EQ
 0000040C	 EC01D2D4	TrapEQ 4 at pos 3757
 00000410	 10000151	MOV R1 lower 16-bits base(0), next at  0000016E
 00000414	 00000000	MOVT R1 higher 16-bits var + 0
 00000418	     6809	LDR R1 [ R1 + 0 ]
 0000041A	     6001	STR R1 [  R0 + 0 ]
 0000041C	     9806	LDR R0 [ SP + 24 ]
 0000041E	 10000007	MOV R1 lower 16-bits base(0), next at  00000410
 00000422	 00000000	MOVT R1 higher 16-bits var + 0
 00000426	     6008	STR R0 [  R1 + 0 ]
 00000428	     9806	LDR R0 [ SP + 24 ]
 0000042A	 F85DEB04	LDR LR [ SP ] + 4
 0000042E	     B012	ADD SP SP #72
 00000430	     4770	BX LR
 00000432	     B08D	SUB SP SP #52
 00000434	     B403	PUSH R0 R1
 00000436	     B500	PUSH LR
 00000438	     2000	MOVS R0 #0
 0000043A	     9005	STR R0 [ SP + 20 ]
 0000043C	     9801	LDR R0 [ SP + 4 ]
 0000043E	     9902	LDR R1 [ SP + 8 ]
 00000440	     AA08	ADD R2 SP #32
 00000442	     AB04	ADD R3 SP #16
 00000444	 F7FFFDDC	BL #-1096, goes to  00000000
 00000448	     9804	LDR R0 [ SP + 16 ]
 0000044A	     2800	CMP R0 #0
 0000044C	 F30080F6	BGT #492, goes to  0000063C
 00000450	     A806	ADD R0 SP #24
 00000452	 10000089	MOV R1 lower 16-bits base(0), next at  00000340
 00000456	 00000064	MOVT R1 higher 16-bits const + 100
 0000045A	     DF00	SVC #0
 0000045C	     9806	LDR R0 [ SP + 24 ]
 0000045E	     2800	CMP R0 #0
 00000460	     BF08	IT EQ
 00000462	 EC0200E4	TrapEQ 4 at pos 4110
 00000466	     2100	MOVS R1 #0
 00000468	     6001	STR R1 [  R0 + 0 ]
 0000046A	     9806	LDR R0 [ SP + 24 ]
 0000046C	     2800	CMP R0 #0
 0000046E	     BF08	IT EQ
 00000470	 EC0201C4	TrapEQ 4 at pos 4124
 00000474	     2101	MOVS R1 #1
 00000476	     7201	STRB R1 [ R0 + 8 ]
 00000478	     9806	LDR R0 [ SP + 24 ]
 0000047A	     2800	CMP R0 #0
 0000047C	     BF08	IT EQ
 0000047E	 EC0202D4	TrapEQ 4 at pos 4141
 00000482	 F45F71B0	MOVS R1 #352
 00000486	     6041	STR R1 [  R0 + 4 ]
 00000488	     9806	LDR R0 [ SP + 24 ]
 0000048A	     2800	CMP R0 #0
 0000048C	     BF08	IT EQ
 0000048E	 EC0203D4	TrapEQ 4 at pos 4157
 00000492	     9906	LDR R1 [ SP + 24 ]
 00000494	     60C1	STR R1 [  R0 + 12 ]
 00000496	     9806	LDR R0 [ SP + 24 ]
 00000498	     2800	CMP R0 #0
 0000049A	     BF08	IT EQ
 0000049C	 EC0207F4	TrapEQ 4 at pos 4223
 000004A0	     3010	ADDS R0 R0 #16
 000004A2	     9007	STR R0 [ SP + 28 ]
 000004A4	     9807	LDR R0 [ SP + 28 ]
 000004A6	     2800	CMP R0 #0
 000004A8	     BF08	IT EQ
 000004AA	 EC0210F4	TrapEQ 4 at pos 4239
 000004AE	 F6415186	MOV R1 #7558
 000004B2	 F6C931A7	MOVT R1 #39847
 000004B6	     6001	STR R1 [  R0 + 0 ]
 000004B8	     9807	LDR R0 [ SP + 28 ]
 000004BA	     2800	CMP R0 #0
 000004BC	     BF08	IT EQ
 000004BE	 EC021344	TrapEQ 4 at pos 4276
 000004C2	     2100	MOVS R1 #0
 000004C4	     6241	STR R1 [  R0 + 36 ]
 000004C6	     9807	LDR R0 [ SP + 28 ]
 000004C8	     2800	CMP R0 #0
 000004CA	     BF08	IT EQ
 000004CC	 EC021424	TrapEQ 4 at pos 4290
 000004D0	 F45F71B0	MOVS R1 #352
 000004D4	     6281	STR R1 [  R0 + 40 ]
 000004D6	     9807	LDR R0 [ SP + 28 ]
 000004D8	     2800	CMP R0 #0
 000004DA	     BF08	IT EQ
 000004DC	 EC021504	TrapEQ 4 at pos 4304
 000004E0	     1D00	ADDS R0 R0 #4
 000004E2	     A908	ADD R1 SP #32
 000004E4	     2208	MOVS R2 #8
 000004E6	 F8513B04	LDR R3 [ R1 ] + 4
 000004EA	 F8403B04	STR R3 [  R0 ] + 4
 000004EE	     1E52	SUBS R2 R2 #1
 000004F0	     D1F9	BNE #-14, goes to  000004E6
 000004F2	     9807	LDR R0 [ SP + 28 ]
 000004F4	     2800	CMP R0 #0
 000004F6	     BF08	IT EQ
 000004F8	 EC021694	TrapEQ 4 at pos 4329
 000004FC	     B401	PUSH R0
 000004FE	 118000B4	BL Mod(  1) proc(24)
 00000502	     4601	MOV R1 R0
 00000504	     BC01	POP R0
 00000506	     62C1	STR R1 [  R0 + 44 ]
 00000508	     A805	ADD R0 SP #20
 0000050A	 1000005C	MOV R1 lower 16-bits base(0), next at  00000452
 0000050E	 0000001C	MOVT R1 higher 16-bits const + 28
 00000512	     DF00	SVC #0
 00000514	     9805	LDR R0 [ SP + 20 ]
 00000516	     2800	CMP R0 #0
 00000518	     BF08	IT EQ
 0000051A	 EC022124	TrapEQ 4 at pos 4370
 0000051E	     2100	MOVS R1 #0
 00000520	     6081	STR R1 [  R0 + 8 ]
 00000522	     9805	LDR R0 [ SP + 20 ]
 00000524	     2800	CMP R0 #0
 00000526	     BF08	IT EQ
 00000528	 EC022204	TrapEQ 4 at pos 4384
 0000052C	 F45F71B0	MOVS R1 #352
 00000530	     60C1	STR R1 [  R0 + 12 ]
 00000532	     9805	LDR R0 [ SP + 20 ]
 00000534	     2800	CMP R0 #0
 00000536	     BF08	IT EQ
 00000538	 EC0222E4	TrapEQ 4 at pos 4398
 0000053C	     2101	MOVS R1 #1
 0000053E	     7401	STRB R1 [ R0 + 16 ]
 00000540	     9805	LDR R0 [ SP + 20 ]
 00000542	     2800	CMP R0 #0
 00000544	     BF08	IT EQ
 00000546	 EC0224A4	TrapEQ 4 at pos 4426
 0000054A	     2100	MOVS R1 #0
 0000054C	     7441	STRB R1 [ R0 + 17 ]
 0000054E	     9805	LDR R0 [ SP + 20 ]
 00000550	     2800	CMP R0 #0
 00000552	     BF08	IT EQ
 00000554	 EC0225B4	TrapEQ 4 at pos 4443
 00000558	     9907	LDR R1 [ SP + 28 ]
 0000055A	     2900	CMP R1 #0
 0000055C	     BF08	IT EQ
 0000055E	 EC022654	TrapEQ 4 at pos 4453
 00000562	     6AC9	LDR R1 [ R1 + 44 ]
 00000564	     63C1	STR R1 [  R0 + 60 ]
 00000566	     9805	LDR R0 [ SP + 20 ]
 00000568	     2800	CMP R0 #0
 0000056A	     BF08	IT EQ
 0000056C	 EC022774	TrapEQ 4 at pos 4471
 00000570	     9906	LDR R1 [ SP + 24 ]
 00000572	     6141	STR R1 [  R0 + 20 ]
 00000574	     9805	LDR R0 [ SP + 20 ]
 00000576	     2800	CMP R0 #0
 00000578	     BF08	IT EQ
 0000057A	 EC023094	TrapEQ 4 at pos 4489
 0000057E	     2101	MOVS R1 #1
 00000580	     6041	STR R1 [  R0 + 4 ]
 00000582	     9805	LDR R0 [ SP + 20 ]
 00000584	     2800	CMP R0 #0
 00000586	     BF08	IT EQ
 00000588	 EC023164	TrapEQ 4 at pos 4502
 0000058C	     301C	ADDS R0 R0 #28
 0000058E	     A908	ADD R1 SP #32
 00000590	     2208	MOVS R2 #8
 00000592	 F8513B04	LDR R3 [ R1 ] + 4
 00000596	 F8403B04	STR R3 [  R0 ] + 4
 0000059A	     1E52	SUBS R2 R2 #1
 0000059C	     D1F9	BNE #-14, goes to  00000592
 0000059E	     9805	LDR R0 [ SP + 20 ]
 000005A0	     2800	CMP R0 #0
 000005A2	     BF08	IT EQ
 000005A4	 EC0232C4	TrapEQ 4 at pos 4524
 000005A8	     2100	MOVS R1 #0
 000005AA	     6181	STR R1 [  R0 + 24 ]
 000005AC	     2000	MOVS R0 #0
 000005AE	     9003	STR R0 [ SP + 12 ]
 000005B0	     9805	LDR R0 [ SP + 20 ]
 000005B2	     2800	CMP R0 #0
 000005B4	     BF08	IT EQ
 000005B6	 EC023534	TrapEQ 4 at pos 4563
 000005BA	     9903	LDR R1 [ SP + 12 ]
 000005BC	     290C	CMP R1 #12
 000005BE	     BF28	IT CS
 000005C0	 EC023561	TrapCS 1 at pos 4566
 000005C4	 EB100081	ADDS R0 R0 R1 LSL #2
 000005C8	     2100	MOVS R1 #0
 000005CA	     6401	STR R1 [  R0 + 64 ]
 000005CC	     9807	LDR R0 [ SP + 28 ]
 000005CE	     2800	CMP R0 #0
 000005D0	     BF08	IT EQ
 000005D2	 EC023644	TrapEQ 4 at pos 4580
 000005D6	     9903	LDR R1 [ SP + 12 ]
 000005D8	     290C	CMP R1 #12
 000005DA	     BF28	IT CS
 000005DC	 EC023671	TrapCS 1 at pos 4583
 000005E0	 EB100081	ADDS R0 R0 R1 LSL #2
 000005E4	     2100	MOVS R1 #0
 000005E6	     6301	STR R1 [  R0 + 48 ]
 000005E8	     9803	LDR R0 [ SP + 12 ]
 000005EA	     1C40	ADDS R0 R0 #1
 000005EC	     9003	STR R0 [ SP + 12 ]
 000005EE	     9803	LDR R0 [ SP + 12 ]
 000005F0	     280C	CMP R0 #12
 000005F2	     D1DD	BNE #-70, goes to  000005B0
 000005F4	     2000	MOVS R0 #0
 000005F6	     9003	STR R0 [ SP + 12 ]
 000005F8	     9805	LDR R0 [ SP + 20 ]
 000005FA	     2800	CMP R0 #0
 000005FC	     BF08	IT EQ
 000005FE	 EC024324	TrapEQ 4 at pos 4658
 00000602	     9903	LDR R1 [ SP + 12 ]
 00000604	     2940	CMP R1 #64
 00000606	     BF28	IT CS
 00000608	 EC024351	TrapCS 1 at pos 4661
 0000060C	 EB100081	ADDS R0 R0 R1 LSL #2
 00000610	     2100	MOVS R1 #0
 00000612	     6701	STR R1 [  R0 + 112 ]
 00000614	     9807	LDR R0 [ SP + 28 ]
 00000616	     2800	CMP R0 #0
 00000618	     BF08	IT EQ
 0000061A	 EC024414	TrapEQ 4 at pos 4673
 0000061E	     9903	LDR R1 [ SP + 12 ]
 00000620	     2940	CMP R1 #64
 00000622	     BF28	IT CS
 00000624	 EC024441	TrapCS 1 at pos 4676
 00000628	 EB100081	ADDS R0 R0 R1 LSL #2
 0000062C	     2100	MOVS R1 #0
 0000062E	     6601	STR R1 [  R0 + 96 ]
 00000630	     9803	LDR R0 [ SP + 12 ]
 00000632	     1C40	ADDS R0 R0 #1
 00000634	     9003	STR R0 [ SP + 12 ]
 00000636	     9803	LDR R0 [ SP + 12 ]
 00000638	     2840	CMP R0 #64
 0000063A	     D1DD	BNE #-70, goes to  000005F8
 0000063C	     9805	LDR R0 [ SP + 20 ]
 0000063E	 F85DEB04	LDR LR [ SP ] + 4
 00000642	     B00F	ADD SP SP #60
 00000644	     4770	BX LR
 00000646	     B081	SUB SP SP #4
 00000648	     B407	PUSH R0 R1 R2
 0000064A	     B500	PUSH LR
 0000064C	     9801	LDR R0 [ SP + 4 ]
 0000064E	     2800	CMP R0 #0
 00000650	     BF08	IT EQ
 00000652	 EC0256F4	TrapEQ 4 at pos 4847
 00000656	     6880	LDR R0 [ R0 + 8 ]
 00000658	     9902	LDR R1 [ SP + 8 ]
 0000065A	     6248	STR R0 [  R1 + 36 ]
 0000065C	     9801	LDR R0 [ SP + 4 ]
 0000065E	     2800	CMP R0 #0
 00000660	     BF08	IT EQ
 00000662	 EC026034	TrapEQ 4 at pos 4867
 00000666	     68C0	LDR R0 [ R0 + 12 ]
 00000668	     9902	LDR R1 [ SP + 8 ]
 0000066A	     6288	STR R0 [  R1 + 40 ]
 0000066C	     9801	LDR R0 [ SP + 4 ]
 0000066E	     2800	CMP R0 #0
 00000670	     BF08	IT EQ
 00000672	 EC026174	TrapEQ 4 at pos 4887
 00000676	     9902	LDR R1 [ SP + 8 ]
 00000678	     3160	ADDS R1 R1 #96
 0000067A	     3070	ADDS R0 R0 #112
 0000067C	     2240	MOVS R2 #64
 0000067E	 F8503B04	LDR R3 [ R0 ] + 4
 00000682	 F8413B04	STR R3 [  R1 ] + 4
 00000686	     1E52	SUBS R2 R2 #1
 00000688	     D1F9	BNE #-14, goes to  0000067E
 0000068A	     9801	LDR R0 [ SP + 4 ]
 0000068C	     2800	CMP R0 #0
 0000068E	     BF08	IT EQ
 00000690	 EC026264	TrapEQ 4 at pos 4902
 00000694	     6880	LDR R0 [ R0 + 8 ]
 00000696	     30C0	ADDS R0 R0 #192
 00000698	     1200	ASRS R0 R0 #8
 0000069A	     9004	STR R0 [ SP + 16 ]
 0000069C	     9804	LDR R0 [ SP + 16 ]
 0000069E	     2800	CMP R0 #0
 000006A0	 F340801F	BLE #62, goes to  000006E2
 000006A4	     9804	LDR R0 [ SP + 16 ]
 000006A6	     1E40	SUBS R0 R0 #1
 000006A8	     9004	STR R0 [ SP + 16 ]
 000006AA	     9804	LDR R0 [ SP + 16 ]
 000006AC	     280C	CMP R0 #12
 000006AE	     BF28	IT CS
 000006B0	 EC0265E1	TrapCS 1 at pos 4958
 000006B4	     9902	LDR R1 [ SP + 8 ]
 000006B6	 EB110080	ADDS R0 R1 R0 LSL #2
 000006BA	     9901	LDR R1 [ SP + 4 ]
 000006BC	     2900	CMP R1 #0
 000006BE	     BF08	IT EQ
 000006C0	 EC026674	TrapEQ 4 at pos 4967
 000006C4	     9A04	LDR R2 [ SP + 16 ]
 000006C6	     2A0C	CMP R2 #12
 000006C8	     BF28	IT CS
 000006CA	 EC0266A1	TrapCS 1 at pos 4970
 000006CE	 EB110182	ADDS R1 R1 R2 LSL #2
 000006D2	     6C09	LDR R1 [ R1 + 64 ]
 000006D4	     2900	CMP R1 #0
 000006D6	     BF08	IT EQ
 000006D8	 EC0266E4	TrapEQ 4 at pos 4974
 000006DC	     6809	LDR R1 [ R1 + 0 ]
 000006DE	     6301	STR R1 [  R0 + 48 ]
 000006E0	     E7DC	B #-72, goes to  0000069C
 000006E2	 F85DEB04	LDR LR [ SP ] + 4
 000006E6	     B004	ADD SP SP #16
 000006E8	     4770	BX LR
 000006EA	     B081	SUB SP SP #4
 000006EC	     B407	PUSH R0 R1 R2
 000006EE	     B500	PUSH LR
 000006F0	     9803	LDR R0 [ SP + 12 ]
 000006F2	     2840	CMP R0 #64
 000006F4	 F2808010	BGE #32, goes to  00000718
 000006F8	     9801	LDR R0 [ SP + 4 ]
 000006FA	     2800	CMP R0 #0
 000006FC	     BF08	IT EQ
 000006FE	 EC028014	TrapEQ 4 at pos 5121
 00000702	     9903	LDR R1 [ SP + 12 ]
 00000704	     2940	CMP R1 #64
 00000706	     BF28	IT CS
 00000708	 EC028061	TrapCS 1 at pos 5126
 0000070C	 EB100081	ADDS R0 R0 R1 LSL #2
 00000710	     6F00	LDR R0 [ R0 + 112 ]
 00000712	     9004	STR R0 [ SP + 16 ]
 00000714	 F000B820	B #64, goes to  00000758
 00000718	     9801	LDR R0 [ SP + 4 ]
 0000071A	     2800	CMP R0 #0
 0000071C	     BF08	IT EQ
 0000071E	 EC0281C4	TrapEQ 4 at pos 5148
 00000722	     9903	LDR R1 [ SP + 12 ]
 00000724	     3940	SUBS R1 R1 #64
 00000726	     1209	ASRS R1 R1 #8
 00000728	     290C	CMP R1 #12
 0000072A	     BF28	IT CS
 0000072C	 EC0282E1	TrapCS 1 at pos 5166
 00000730	 EB100081	ADDS R0 R0 R1 LSL #2
 00000734	     6C00	LDR R0 [ R0 + 64 ]
 00000736	     2800	CMP R0 #0
 00000738	     BF08	IT EQ
 0000073A	 EC028324	TrapEQ 4 at pos 5170
 0000073E	     9903	LDR R1 [ SP + 12 ]
 00000740	     3940	SUBS R1 R1 #64
 00000742	 F36F211F	BFC R1 #8 #24
 00000746	 F5B17F80	CMP R1 #256
 0000074A	     BF28	IT CS
 0000074C	 EC028441	TrapCS 1 at pos 5188
 00000750	 EB100081	ADDS R0 R0 R1 LSL #2
 00000754	     6880	LDR R0 [ R0 + 8 ]
 00000756	     9004	STR R0 [ SP + 16 ]
 00000758	     9804	LDR R0 [ SP + 16 ]
 0000075A	     9902	LDR R1 [ SP + 8 ]
 0000075C	     2900	CMP R1 #0
 0000075E	     BF08	IT EQ
 00000760	 EC028714	TrapEQ 4 at pos 5233
 00000764	     3110	ADDS R1 R1 #16
 00000766	 11500134	BL Mod(  1) proc(21)
 0000076A	     9801	LDR R0 [ SP + 4 ]
 0000076C	     2800	CMP R0 #0
 0000076E	     BF08	IT EQ
 00000770	 EC029084	TrapEQ 4 at pos 5256
 00000774	     9903	LDR R1 [ SP + 12 ]
 00000776	     6880	LDR R0 [ R0 + 8 ]
 00000778	     4281	CMP R1 R0
 0000077A	 F280800A	BGE #20, goes to  00000792
 0000077E	     9802	LDR R0 [ SP + 8 ]
 00000780	     2800	CMP R0 #0
 00000782	     BF08	IT EQ
 00000784	 EC029154	TrapEQ 4 at pos 5269
 00000788	 F45F6180	MOVS R1 #1024
 0000078C	     6041	STR R1 [  R0 + 4 ]
 0000078E	 F000B80C	B #24, goes to  000007AA
 00000792	     9802	LDR R0 [ SP + 8 ]
 00000794	     2800	CMP R0 #0
 00000796	     BF08	IT EQ
 00000798	 EC029284	TrapEQ 4 at pos 5288
 0000079C	     9901	LDR R1 [ SP + 4 ]
 0000079E	     2900	CMP R1 #0
 000007A0	     BF08	IT EQ
 000007A2	 EC029334	TrapEQ 4 at pos 5299
 000007A6	     68C9	LDR R1 [ R1 + 12 ]
 000007A8	     6041	STR R1 [  R0 + 4 ]
 000007AA	     9802	LDR R0 [ SP + 8 ]
 000007AC	     2800	CMP R0 #0
 000007AE	     BF08	IT EQ
 000007B0	 EC029464	TrapEQ 4 at pos 5318
 000007B4	     9903	LDR R1 [ SP + 12 ]
 000007B6	     6001	STR R1 [  R0 + 0 ]
 000007B8	     9802	LDR R0 [ SP + 8 ]
 000007BA	     2800	CMP R0 #0
 000007BC	     BF08	IT EQ
 000007BE	 EC029564	TrapEQ 4 at pos 5334
 000007C2	     2100	MOVS R1 #0
 000007C4	     7201	STRB R1 [ R0 + 8 ]
 000007C6	 F85DEB04	LDR LR [ SP ] + 4
 000007CA	     B004	ADD SP SP #16
 000007CC	     4770	BX LR
 000007CE	     B084	SUB SP SP #16
 000007D0	     B403	PUSH R0 R1
 000007D2	     B500	PUSH LR
 000007D4	     9802	LDR R0 [ SP + 8 ]
 000007D6	     2800	CMP R0 #0
 000007D8	     BF08	IT EQ
 000007DA	 EC02A6F4	TrapEQ 4 at pos 5487
 000007DE	     6800	LDR R0 [ R0 + 0 ]
 000007E0	     2840	CMP R0 #64
 000007E2	 F2808060	BGE #192, goes to  000008A6
 000007E6	     9801	LDR R0 [ SP + 4 ]
 000007E8	     2800	CMP R0 #0
 000007EA	     BF08	IT EQ
 000007EC	 EC02B104	TrapEQ 4 at pos 5520
 000007F0	     9902	LDR R1 [ SP + 8 ]
 000007F2	     2900	CMP R1 #0
 000007F4	     BF08	IT EQ
 000007F6	 EC02B194	TrapEQ 4 at pos 5529
 000007FA	     6809	LDR R1 [ R1 + 0 ]
 000007FC	     2940	CMP R1 #64
 000007FE	     BF28	IT CS
 00000800	 EC02B1A1	TrapCS 1 at pos 5530
 00000804	 EB100081	ADDS R0 R0 R1 LSL #2
 00000808	     6F00	LDR R0 [ R0 + 112 ]
 0000080A	     9005	STR R0 [ SP + 20 ]
 0000080C	     9805	LDR R0 [ SP + 20 ]
 0000080E	     2800	CMP R0 #0
 00000810	 F040802A	BNE #84, goes to  00000868
 00000814	     9801	LDR R0 [ SP + 4 ]
 00000816	     2800	CMP R0 #0
 00000818	     BF08	IT EQ
 0000081A	 EC02B594	TrapEQ 4 at pos 5593
 0000081E	     6980	LDR R0 [ R0 + 24 ]
 00000820	     A905	ADD R1 SP #20
 00000822	 1140005E	BL Mod(  1) proc(20)
 00000826	     9801	LDR R0 [ SP + 4 ]
 00000828	     2800	CMP R0 #0
 0000082A	     BF08	IT EQ
 0000082C	 EC02B724	TrapEQ 4 at pos 5618
 00000830	     2101	MOVS R1 #1
 00000832	     7401	STRB R1 [ R0 + 16 ]
 00000834	     9801	LDR R0 [ SP + 4 ]
 00000836	     2800	CMP R0 #0
 00000838	     BF08	IT EQ
 0000083A	 EC02C014	TrapEQ 4 at pos 5633
 0000083E	     9902	LDR R1 [ SP + 8 ]
 00000840	     2900	CMP R1 #0
 00000842	     BF08	IT EQ
 00000844	 EC02C0A4	TrapEQ 4 at pos 5642
 00000848	     6809	LDR R1 [ R1 + 0 ]
 0000084A	     2940	CMP R1 #64
 0000084C	     BF28	IT CS
 0000084E	 EC02C0B1	TrapCS 1 at pos 5643
 00000852	 EB100081	ADDS R0 R0 R1 LSL #2
 00000856	     9905	LDR R1 [ SP + 20 ]
 00000858	     6701	STR R1 [  R0 + 112 ]
 0000085A	     9801	LDR R0 [ SP + 4 ]
 0000085C	     2800	CMP R0 #0
 0000085E	     BF08	IT EQ
 00000860	 EC02C204	TrapEQ 4 at pos 5664
 00000864	     9905	LDR R1 [ SP + 20 ]
 00000866	     6181	STR R1 [  R0 + 24 ]
 00000868	     9802	LDR R0 [ SP + 8 ]
 0000086A	     2800	CMP R0 #0
 0000086C	     BF08	IT EQ
 0000086E	 EC02C484	TrapEQ 4 at pos 5704
 00000872	     6800	LDR R0 [ R0 + 0 ]
 00000874	     2800	CMP R0 #0
 00000876	 F0408014	BNE #40, goes to  000008A2
 0000087A	     9801	LDR R0 [ SP + 4 ]
 0000087C	     9902	LDR R1 [ SP + 8 ]
 0000087E	     2900	CMP R1 #0
 00000880	     BF08	IT EQ
 00000882	 EC02D114	TrapEQ 4 at pos 5777
 00000886	     3110	ADDS R1 R1 #16
 00000888	 220001BF	MOV R2 lower 16-bits base(2), next at  0000050A
 0000088C	 00000001	MOVT R2 higher 16-bits const(1)
 00000890	 F7FFFED9	BL #-590, goes to  00000646
 00000894	     9801	LDR R0 [ SP + 4 ]
 00000896	     2800	CMP R0 #0
 00000898	     BF08	IT EQ
 0000089A	 EC02D1B4	TrapEQ 4 at pos 5787
 0000089E	     2100	MOVS R1 #0
 000008A0	     7401	STRB R1 [ R0 + 16 ]
 000008A2	 F000B88E	B #284, goes to  000009C2
 000008A6	     9802	LDR R0 [ SP + 8 ]
 000008A8	     2800	CMP R0 #0
 000008AA	     BF08	IT EQ
 000008AC	 EC02D464	TrapEQ 4 at pos 5830
 000008B0	     6800	LDR R0 [ R0 + 0 ]
 000008B2	     3840	SUBS R0 R0 #64
 000008B4	     1200	ASRS R0 R0 #8
 000008B6	     9003	STR R0 [ SP + 12 ]
 000008B8	     9801	LDR R0 [ SP + 4 ]
 000008BA	     2800	CMP R0 #0
 000008BC	     BF08	IT EQ
 000008BE	 EC02D624	TrapEQ 4 at pos 5858
 000008C2	     9903	LDR R1 [ SP + 12 ]
 000008C4	     290C	CMP R1 #12
 000008C6	     BF28	IT CS
 000008C8	 EC02D651	TrapCS 1 at pos 5861
 000008CC	 EB100081	ADDS R0 R0 R1 LSL #2
 000008D0	     6C00	LDR R0 [ R0 + 64 ]
 000008D2	     9006	STR R0 [ SP + 24 ]
 000008D4	     9806	LDR R0 [ SP + 24 ]
 000008D6	     2800	CMP R0 #0
 000008D8	 F0408029	BNE #82, goes to  0000092E
 000008DC	     A806	ADD R0 SP #24
 000008DE	 1000002B	MOV R1 lower 16-bits base(0), next at  00000888
 000008E2	 0000007C	MOVT R1 higher 16-bits const + 124
 000008E6	     DF00	SVC #0
 000008E8	     9806	LDR R0 [ SP + 24 ]
 000008EA	     2800	CMP R0 #0
 000008EC	     BF08	IT EQ
 000008EE	 EC02E184	TrapEQ 4 at pos 5912
 000008F2	     2100	MOVS R1 #0
 000008F4	     6001	STR R1 [  R0 + 0 ]
 000008F6	     9806	LDR R0 [ SP + 24 ]
 000008F8	     2800	CMP R0 #0
 000008FA	     BF08	IT EQ
 000008FC	 EC02E264	TrapEQ 4 at pos 5926
 00000900	     2100	MOVS R1 #0
 00000902	     6081	STR R1 [  R0 + 8 ]
 00000904	     9801	LDR R0 [ SP + 4 ]
 00000906	     2800	CMP R0 #0
 00000908	     BF08	IT EQ
 0000090A	 EC02E354	TrapEQ 4 at pos 5941
 0000090E	     9903	LDR R1 [ SP + 12 ]
 00000910	     290C	CMP R1 #12
 00000912	     BF28	IT CS
 00000914	 EC02E381	TrapCS 1 at pos 5944
 00000918	 EB100081	ADDS R0 R0 R1 LSL #2
 0000091C	     9906	LDR R1 [ SP + 24 ]
 0000091E	     6401	STR R1 [  R0 + 64 ]
 00000920	     9801	LDR R0 [ SP + 4 ]
 00000922	     2800	CMP R0 #0
 00000924	     BF08	IT EQ
 00000926	 EC02E474	TrapEQ 4 at pos 5959
 0000092A	     2101	MOVS R1 #1
 0000092C	     7401	STRB R1 [ R0 + 16 ]
 0000092E	     9802	LDR R0 [ SP + 8 ]
 00000930	     2800	CMP R0 #0
 00000932	     BF08	IT EQ
 00000934	 EC02E704	TrapEQ 4 at pos 6000
 00000938	     6800	LDR R0 [ R0 + 0 ]
 0000093A	     3840	SUBS R0 R0 #64
 0000093C	 F36F201F	BFC R0 #8 #24
 00000940	     9004	STR R0 [ SP + 16 ]
 00000942	     9806	LDR R0 [ SP + 24 ]
 00000944	     2800	CMP R0 #0
 00000946	     BF08	IT EQ
 00000948	 EC02F114	TrapEQ 4 at pos 6033
 0000094C	     9904	LDR R1 [ SP + 16 ]
 0000094E	 F5B17F80	CMP R1 #256
 00000952	     BF28	IT CS
 00000954	 EC02F141	TrapCS 1 at pos 6036
 00000958	 EB100081	ADDS R0 R0 R1 LSL #2
 0000095C	     6880	LDR R0 [ R0 + 8 ]
 0000095E	     9005	STR R0 [ SP + 20 ]
 00000960	     9805	LDR R0 [ SP + 20 ]
 00000962	     2800	CMP R0 #0
 00000964	 F040802D	BNE #90, goes to  000009C2
 00000968	     9801	LDR R0 [ SP + 4 ]
 0000096A	     2800	CMP R0 #0
 0000096C	     BF08	IT EQ
 0000096E	 EC02F534	TrapEQ 4 at pos 6099
 00000972	     6980	LDR R0 [ R0 + 24 ]
 00000974	     A905	ADD R1 SP #20
 00000976	 114000AA	BL Mod(  1) proc(20)
 0000097A	     9801	LDR R0 [ SP + 4 ]
 0000097C	     2800	CMP R0 #0
 0000097E	     BF08	IT EQ
 00000980	 EC02F6C4	TrapEQ 4 at pos 6124
 00000984	     2101	MOVS R1 #1
 00000986	     7401	STRB R1 [ R0 + 16 ]
 00000988	     9806	LDR R0 [ SP + 24 ]
 0000098A	     2800	CMP R0 #0
 0000098C	     BF08	IT EQ
 0000098E	 EC02F7D4	TrapEQ 4 at pos 6141
 00000992	     2101	MOVS R1 #1
 00000994	     7101	STRB R1 [ R0 + 4 ]
 00000996	     9806	LDR R0 [ SP + 24 ]
 00000998	     2800	CMP R0 #0
 0000099A	     BF08	IT EQ
 0000099C	 EC0300E4	TrapEQ 4 at pos 6158
 000009A0	     9904	LDR R1 [ SP + 16 ]
 000009A2	 F5B17F80	CMP R1 #256
 000009A6	     BF28	IT CS
 000009A8	 EC030111	TrapCS 1 at pos 6161
 000009AC	 EB100081	ADDS R0 R0 R1 LSL #2
 000009B0	     9905	LDR R1 [ SP + 20 ]
 000009B2	     6081	STR R1 [  R0 + 8 ]
 000009B4	     9801	LDR R0 [ SP + 4 ]
 000009B6	     2800	CMP R0 #0
 000009B8	     BF08	IT EQ
 000009BA	 EC030264	TrapEQ 4 at pos 6182
 000009BE	     9905	LDR R1 [ SP + 20 ]
 000009C0	     6181	STR R1 [  R0 + 24 ]
 000009C2	     9805	LDR R0 [ SP + 20 ]
 000009C4	     9902	LDR R1 [ SP + 8 ]
 000009C6	     2900	CMP R1 #0
 000009C8	     BF08	IT EQ
 000009CA	 EC0306A4	TrapEQ 4 at pos 6250
 000009CE	     3110	ADDS R1 R1 #16
 000009D0	 1160002D	BL Mod(  1) proc(22)
 000009D4	     9802	LDR R0 [ SP + 8 ]
 000009D6	     2800	CMP R0 #0
 000009D8	     BF08	IT EQ
 000009DA	 EC030744	TrapEQ 4 at pos 6260
 000009DE	     2100	MOVS R1 #0
 000009E0	     7201	STRB R1 [ R0 + 8 ]
 000009E2	 F85DEB04	LDR LR [ SP ] + 4
 000009E6	     B006	ADD SP SP #24
 000009E8	     4770	BX LR
 000009EA	     B081	SUB SP SP #4
 000009EC	     B403	PUSH R0 R1
 000009EE	     B500	PUSH LR
 000009F0	     9801	LDR R0 [ SP + 4 ]
 000009F2	     2800	CMP R0 #0
 000009F4	     BF08	IT EQ
 000009F6	 EC0316E4	TrapEQ 4 at pos 6382
 000009FA	     6940	LDR R0 [ R0 + 20 ]
 000009FC	     9003	STR R0 [ SP + 12 ]
 000009FE	     9803	LDR R0 [ SP + 12 ]
 00000A00	     2800	CMP R0 #0
 00000A02	     BF08	IT EQ
 00000A04	 EC032034	TrapEQ 4 at pos 6403
 00000A08	     6800	LDR R0 [ R0 + 0 ]
 00000A0A	     9902	LDR R1 [ SP + 8 ]
 00000A0C	     4288	CMP R0 R1
 00000A0E	 F0008017	BEQ #46, goes to  00000A40
 00000A12	     9803	LDR R0 [ SP + 12 ]
 00000A14	     2800	CMP R0 #0
 00000A16	     BF08	IT EQ
 00000A18	 EC032164	TrapEQ 4 at pos 6422
 00000A1C	     9901	LDR R1 [ SP + 4 ]
 00000A1E	     2900	CMP R1 #0
 00000A20	     BF08	IT EQ
 00000A22	 EC032234	TrapEQ 4 at pos 6435
 00000A26	     68C0	LDR R0 [ R0 + 12 ]
 00000A28	     6949	LDR R1 [ R1 + 20 ]
 00000A2A	     4288	CMP R0 R1
 00000A2C	 F0008008	BEQ #16, goes to  00000A40
 00000A30	     9803	LDR R0 [ SP + 12 ]
 00000A32	     2800	CMP R0 #0
 00000A34	     BF08	IT EQ
 00000A36	 EC032374	TrapEQ 4 at pos 6455
 00000A3A	     68C0	LDR R0 [ R0 + 12 ]
 00000A3C	     9003	STR R0 [ SP + 12 ]
 00000A3E	     E7DE	B #-68, goes to  000009FE
 00000A40	     9803	LDR R0 [ SP + 12 ]
 00000A42	     2800	CMP R0 #0
 00000A44	     BF08	IT EQ
 00000A46	 EC0324D4	TrapEQ 4 at pos 6477
 00000A4A	     6800	LDR R0 [ R0 + 0 ]
 00000A4C	     9902	LDR R1 [ SP + 8 ]
 00000A4E	     4288	CMP R0 R1
 00000A50	 F0008002	BEQ #4, goes to  00000A58
 00000A54	     2000	MOVS R0 #0
 00000A56	     9003	STR R0 [ SP + 12 ]
 00000A58	     9803	LDR R0 [ SP + 12 ]
 00000A5A	 F85DEB04	LDR LR [ SP ] + 4
 00000A5E	     B003	ADD SP SP #12
 00000A60	     4770	BX LR
 00000A62	     B081	SUB SP SP #4
 00000A64	     B403	PUSH R0 R1
 00000A66	     B500	PUSH LR
 00000A68	     9801	LDR R0 [ SP + 4 ]
 00000A6A	     2800	CMP R0 #0
 00000A6C	     BF08	IT EQ
 00000A6E	 EC033674	TrapEQ 4 at pos 6631
 00000A72	     6940	LDR R0 [ R0 + 20 ]
 00000A74	     9003	STR R0 [ SP + 12 ]
 00000A76	     9803	LDR R0 [ SP + 12 ]
 00000A78	     2800	CMP R0 #0
 00000A7A	     BF08	IT EQ
 00000A7C	 EC0337C4	TrapEQ 4 at pos 6652
 00000A80	     6800	LDR R0 [ R0 + 0 ]
 00000A82	     9902	LDR R1 [ SP + 8 ]
 00000A84	     4288	CMP R0 R1
 00000A86	 F0008017	BEQ #46, goes to  00000AB8
 00000A8A	     9803	LDR R0 [ SP + 12 ]
 00000A8C	     2800	CMP R0 #0
 00000A8E	     BF08	IT EQ
 00000A90	 EC0340F4	TrapEQ 4 at pos 6671
 00000A94	     9901	LDR R1 [ SP + 4 ]
 00000A96	     2900	CMP R1 #0
 00000A98	     BF08	IT EQ
 00000A9A	 EC0341C4	TrapEQ 4 at pos 6684
 00000A9E	     68C0	LDR R0 [ R0 + 12 ]
 00000AA0	     6949	LDR R1 [ R1 + 20 ]
 00000AA2	     4288	CMP R0 R1
 00000AA4	 F0008008	BEQ #16, goes to  00000AB8
 00000AA8	     9803	LDR R0 [ SP + 12 ]
 00000AAA	     2800	CMP R0 #0
 00000AAC	     BF08	IT EQ
 00000AAE	 EC034304	TrapEQ 4 at pos 6704
 00000AB2	     68C0	LDR R0 [ R0 + 12 ]
 00000AB4	     9003	STR R0 [ SP + 12 ]
 00000AB6	     E7DE	B #-68, goes to  00000A76
 00000AB8	     9803	LDR R0 [ SP + 12 ]
 00000ABA	     2800	CMP R0 #0
 00000ABC	     BF08	IT EQ
 00000ABE	 EC034464	TrapEQ 4 at pos 6726
 00000AC2	     6800	LDR R0 [ R0 + 0 ]
 00000AC4	     9902	LDR R1 [ SP + 8 ]
 00000AC6	     4288	CMP R0 R1
 00000AC8	 F0008070	BEQ #224, goes to  00000BAC
 00000ACC	     9801	LDR R0 [ SP + 4 ]
 00000ACE	     2800	CMP R0 #0
 00000AD0	     BF08	IT EQ
 00000AD2	 EC034654	TrapEQ 4 at pos 6757
 00000AD6	     6840	LDR R0 [ R0 + 4 ]
 00000AD8	     2804	CMP R0 #4
 00000ADA	 F280802D	BGE #90, goes to  00000B38
 00000ADE	     A803	ADD R0 SP #12
 00000AE0	 10000101	MOV R1 lower 16-bits base(0), next at  000008DE
 00000AE4	 00000064	MOVT R1 higher 16-bits const + 100
 00000AE8	     DF00	SVC #0
 00000AEA	     9803	LDR R0 [ SP + 12 ]
 00000AEC	     2800	CMP R0 #0
 00000AEE	     BF08	IT EQ
 00000AF0	 EC035284	TrapEQ 4 at pos 6824
 00000AF4	     9901	LDR R1 [ SP + 4 ]
 00000AF6	     2900	CMP R1 #0
 00000AF8	     BF08	IT EQ
 00000AFA	 EC035364	TrapEQ 4 at pos 6838
 00000AFE	     6949	LDR R1 [ R1 + 20 ]
 00000B00	     2900	CMP R1 #0
 00000B02	     BF08	IT EQ
 00000B04	 EC0353B4	TrapEQ 4 at pos 6843
 00000B08	     68C9	LDR R1 [ R1 + 12 ]
 00000B0A	     60C1	STR R1 [  R0 + 12 ]
 00000B0C	     9801	LDR R0 [ SP + 4 ]
 00000B0E	     2800	CMP R0 #0
 00000B10	     BF08	IT EQ
 00000B12	 EC035474	TrapEQ 4 at pos 6855
 00000B16	     6940	LDR R0 [ R0 + 20 ]
 00000B18	     2800	CMP R0 #0
 00000B1A	     BF08	IT EQ
 00000B1C	 EC0354C4	TrapEQ 4 at pos 6860
 00000B20	     9903	LDR R1 [ SP + 12 ]
 00000B22	     60C1	STR R1 [  R0 + 12 ]
 00000B24	     9801	LDR R0 [ SP + 4 ]
 00000B26	     2800	CMP R0 #0
 00000B28	     BF08	IT EQ
 00000B2A	 EC035624	TrapEQ 4 at pos 6882
 00000B2E	     6841	LDR R1 [ R0 + 4 ]
 00000B30	     1C49	ADDS R1 R1 #1
 00000B32	     6041	STR R1 [  R0 + 4 ]
 00000B34	 F000B814	B #40, goes to  00000B60
 00000B38	     9801	LDR R0 [ SP + 4 ]
 00000B3A	     2800	CMP R0 #0
 00000B3C	     BF08	IT EQ
 00000B3E	 EC0360C4	TrapEQ 4 at pos 6924
 00000B42	     9903	LDR R1 [ SP + 12 ]
 00000B44	     6141	STR R1 [  R0 + 20 ]
 00000B46	     9803	LDR R0 [ SP + 12 ]
 00000B48	     2800	CMP R0 #0
 00000B4A	     BF08	IT EQ
 00000B4C	 EC036274	TrapEQ 4 at pos 6951
 00000B50	     7A00	LDRB R0 [ R0 + 8 ]
 00000B52	     2800	CMP R0 #0
 00000B54	 F0008004	BEQ #8, goes to  00000B60
 00000B58	     9801	LDR R0 [ SP + 4 ]
 00000B5A	     9903	LDR R1 [ SP + 12 ]
 00000B5C	 F7FFFE37	BL #-914, goes to  000007CE
 00000B60	     9801	LDR R0 [ SP + 4 ]
 00000B62	     2800	CMP R0 #0
 00000B64	     BF08	IT EQ
 00000B66	 EC036654	TrapEQ 4 at pos 7013
 00000B6A	     9902	LDR R1 [ SP + 8 ]
 00000B6C	     6880	LDR R0 [ R0 + 8 ]
 00000B6E	     4281	CMP R1 R0
 00000B70	 F3008007	BGT #14, goes to  00000B82
 00000B74	     9801	LDR R0 [ SP + 4 ]
 00000B76	     9903	LDR R1 [ SP + 12 ]
 00000B78	     9A02	LDR R2 [ SP + 8 ]
 00000B7A	 F7FFFDB6	BL #-1172, goes to  000006EA
 00000B7E	 F000B815	B #42, goes to  00000BAC
 00000B82	     9803	LDR R0 [ SP + 12 ]
 00000B84	     2800	CMP R0 #0
 00000B86	     BF08	IT EQ
 00000B88	 EC0370D4	TrapEQ 4 at pos 7053
 00000B8C	     9902	LDR R1 [ SP + 8 ]
 00000B8E	     6001	STR R1 [  R0 + 0 ]
 00000B90	     9803	LDR R0 [ SP + 12 ]
 00000B92	     2800	CMP R0 #0
 00000B94	     BF08	IT EQ
 00000B96	 EC0371D4	TrapEQ 4 at pos 7069
 00000B9A	     2100	MOVS R1 #0
 00000B9C	     6041	STR R1 [  R0 + 4 ]
 00000B9E	     9803	LDR R0 [ SP + 12 ]
 00000BA0	     2800	CMP R0 #0
 00000BA2	     BF08	IT EQ
 00000BA4	 EC0372B4	TrapEQ 4 at pos 7083
 00000BA8	     2100	MOVS R1 #0
 00000BAA	     7201	STRB R1 [ R0 + 8 ]
 00000BAC	     9803	LDR R0 [ SP + 12 ]
 00000BAE	 F85DEB04	LDR LR [ SP ] + 4
 00000BB2	     B003	ADD SP SP #12
 00000BB4	     4770	BX LR
 00000BB6	     B085	SUB SP SP #20
 00000BB8	     B401	PUSH R0
 00000BBA	     B500	PUSH LR
 00000BBC	     A806	ADD R0 SP #24
 00000BBE	 1200006F	MOV R1 lower 16-bits base(2), next at  00000AE0
 00000BC2	 00000001	MOVT R1 higher 16-bits const(1)
 00000BC6	     DF00	SVC #0
 00000BC8	     9801	LDR R0 [ SP + 4 ]
 00000BCA	     2800	CMP R0 #0
 00000BCC	     BF08	IT EQ
 00000BCE	 EC0387F4	TrapEQ 4 at pos 7295
 00000BD2	     6940	LDR R0 [ R0 + 20 ]
 00000BD4	     9004	STR R0 [ SP + 16 ]
 00000BD6	     9804	LDR R0 [ SP + 16 ]
 00000BD8	     2800	CMP R0 #0
 00000BDA	     BF08	IT EQ
 00000BDC	 EC0391C4	TrapEQ 4 at pos 7324
 00000BE0	     7A00	LDRB R0 [ R0 + 8 ]
 00000BE2	     2800	CMP R0 #0
 00000BE4	 F0008004	BEQ #8, goes to  00000BF0
 00000BE8	     9801	LDR R0 [ SP + 4 ]
 00000BEA	     9904	LDR R1 [ SP + 16 ]
 00000BEC	 F7FFFDEF	BL #-1058, goes to  000007CE
 00000BF0	     9804	LDR R0 [ SP + 16 ]
 00000BF2	     2800	CMP R0 #0
 00000BF4	     BF08	IT EQ
 00000BF6	 EC0394E4	TrapEQ 4 at pos 7374
 00000BFA	     68C0	LDR R0 [ R0 + 12 ]
 00000BFC	     9004	STR R0 [ SP + 16 ]
 00000BFE	     9801	LDR R0 [ SP + 4 ]
 00000C00	     2800	CMP R0 #0
 00000C02	     BF08	IT EQ
 00000C04	 EC039694	TrapEQ 4 at pos 7401
 00000C08	     9904	LDR R1 [ SP + 16 ]
 00000C0A	     6940	LDR R0 [ R0 + 20 ]
 00000C0C	     4281	CMP R1 R0
 00000C0E	     D1E2	BNE #-60, goes to  00000BD6
 00000C10	     9801	LDR R0 [ SP + 4 ]
 00000C12	     2800	CMP R0 #0
 00000C14	     BF08	IT EQ
 00000C16	 EC0397C4	TrapEQ 4 at pos 7420
 00000C1A	     6880	LDR R0 [ R0 + 8 ]
 00000C1C	     30C0	ADDS R0 R0 #192
 00000C1E	     1200	ASRS R0 R0 #8
 00000C20	     9003	STR R0 [ SP + 12 ]
 00000C22	     2000	MOVS R0 #0
 00000C24	     9002	STR R0 [ SP + 8 ]
 00000C26	     9802	LDR R0 [ SP + 8 ]
 00000C28	     9903	LDR R1 [ SP + 12 ]
 00000C2A	     4288	CMP R0 R1
 00000C2C	 F2808059	BGE #178, goes to  00000CE2
 00000C30	     9801	LDR R0 [ SP + 4 ]
 00000C32	     2800	CMP R0 #0
 00000C34	     BF08	IT EQ
 00000C36	 EC03A3E4	TrapEQ 4 at pos 7486
 00000C3A	     9902	LDR R1 [ SP + 8 ]
 00000C3C	     290C	CMP R1 #12
 00000C3E	     BF28	IT CS
 00000C40	 EC03A411	TrapCS 1 at pos 7489
 00000C44	 EB100081	ADDS R0 R0 R1 LSL #2
 00000C48	     6C00	LDR R0 [ R0 + 64 ]
 00000C4A	     9005	STR R0 [ SP + 20 ]
 00000C4C	     9802	LDR R0 [ SP + 8 ]
 00000C4E	     1C40	ADDS R0 R0 #1
 00000C50	     9002	STR R0 [ SP + 8 ]
 00000C52	     9805	LDR R0 [ SP + 20 ]
 00000C54	     2800	CMP R0 #0
 00000C56	     BF08	IT EQ
 00000C58	 EC03A5B4	TrapEQ 4 at pos 7515
 00000C5C	     7900	LDRB R0 [ R0 + 4 ]
 00000C5E	     2800	CMP R0 #0
 00000C60	 F000803E	BEQ #124, goes to  00000CE0
 00000C64	     9805	LDR R0 [ SP + 20 ]
 00000C66	     2800	CMP R0 #0
 00000C68	     BF08	IT EQ
 00000C6A	 EC03A734	TrapEQ 4 at pos 7539
 00000C6E	     6800	LDR R0 [ R0 + 0 ]
 00000C70	     2800	CMP R0 #0
 00000C72	 F0408020	BNE #64, goes to  00000CB6
 00000C76	     9801	LDR R0 [ SP + 4 ]
 00000C78	     2800	CMP R0 #0
 00000C7A	     BF08	IT EQ
 00000C7C	 EC03B234	TrapEQ 4 at pos 7587
 00000C80	     6980	LDR R0 [ R0 + 24 ]
 00000C82	     9905	LDR R1 [ SP + 20 ]
 00000C84	     2900	CMP R1 #0
 00000C86	     BF08	IT EQ
 00000C88	 EC03B2C4	TrapEQ 4 at pos 7596
 00000C8C	 1140015E	BL Mod(  1) proc(20)
 00000C90	     9801	LDR R0 [ SP + 4 ]
 00000C92	     2800	CMP R0 #0
 00000C94	     BF08	IT EQ
 00000C96	 EC03B384	TrapEQ 4 at pos 7608
 00000C9A	     9905	LDR R1 [ SP + 20 ]
 00000C9C	     2900	CMP R1 #0
 00000C9E	     BF08	IT EQ
 00000CA0	 EC03B434	TrapEQ 4 at pos 7619
 00000CA4	     6809	LDR R1 [ R1 + 0 ]
 00000CA6	     6181	STR R1 [  R0 + 24 ]
 00000CA8	     9801	LDR R0 [ SP + 4 ]
 00000CAA	     2800	CMP R0 #0
 00000CAC	     BF08	IT EQ
 00000CAE	 EC03B4B4	TrapEQ 4 at pos 7627
 00000CB2	     2101	MOVS R1 #1
 00000CB4	     7401	STRB R1 [ R0 + 16 ]
 00000CB6	     9805	LDR R0 [ SP + 20 ]
 00000CB8	     2800	CMP R0 #0
 00000CBA	     BF08	IT EQ
 00000CBC	 EC03C024	TrapEQ 4 at pos 7682
 00000CC0	     6800	LDR R0 [ R0 + 0 ]
 00000CC2	     9905	LDR R1 [ SP + 20 ]
 00000CC4	     2900	CMP R1 #0
 00000CC6	     BF08	IT EQ
 00000CC8	 EC03C0B4	TrapEQ 4 at pos 7691
 00000CCC	     3108	ADDS R1 R1 #8
 00000CCE	 11600021	BL Mod(  1) proc(22)
 00000CD2	     9805	LDR R0 [ SP + 20 ]
 00000CD4	     2800	CMP R0 #0
 00000CD6	     BF08	IT EQ
 00000CD8	 EC03C154	TrapEQ 4 at pos 7701
 00000CDC	     2100	MOVS R1 #0
 00000CDE	     7101	STRB R1 [ R0 + 4 ]
 00000CE0	     E7A1	B #-190, goes to  00000C26
 00000CE2	     9801	LDR R0 [ SP + 4 ]
 00000CE4	     2800	CMP R0 #0
 00000CE6	     BF08	IT EQ
 00000CE8	 EC03C404	TrapEQ 4 at pos 7744
 00000CEC	     7C00	LDRB R0 [ R0 + 16 ]
 00000CEE	     2800	CMP R0 #0
 00000CF0	 F000802D	BEQ #90, goes to  00000D4E
 00000CF4	     9801	LDR R0 [ SP + 4 ]
 00000CF6	     2800	CMP R0 #0
 00000CF8	     BF08	IT EQ
 00000CFA	 EC03C624	TrapEQ 4 at pos 7778
 00000CFE	     6F00	LDR R0 [ R0 + 112 ]
 00000D00	     9906	LDR R1 [ SP + 24 ]
 00000D02	     2900	CMP R1 #0
 00000D04	     BF08	IT EQ
 00000D06	 EC03C6D4	TrapEQ 4 at pos 7789
 00000D0A	 1150001E	BL Mod(  1) proc(21)
 00000D0E	     9801	LDR R0 [ SP + 4 ]
 00000D10	     9906	LDR R1 [ SP + 24 ]
 00000D12	     2900	CMP R1 #0
 00000D14	     BF08	IT EQ
 00000D16	 EC03D054	TrapEQ 4 at pos 7813
 00000D1A	 220000AE	MOV R2 lower 16-bits base(2), next at  00000BBE
 00000D1E	 00000001	MOVT R2 higher 16-bits const(1)
 00000D22	 F7FFFC90	BL #-1760, goes to  00000646
 00000D26	     9801	LDR R0 [ SP + 4 ]
 00000D28	     2800	CMP R0 #0
 00000D2A	     BF08	IT EQ
 00000D2C	 EC03D234	TrapEQ 4 at pos 7843
 00000D30	     6F00	LDR R0 [ R0 + 112 ]
 00000D32	     9906	LDR R1 [ SP + 24 ]
 00000D34	     2900	CMP R1 #0
 00000D36	     BF08	IT EQ
 00000D38	 EC03D2E4	TrapEQ 4 at pos 7854
 00000D3C	 11600019	BL Mod(  1) proc(22)
 00000D40	     9801	LDR R0 [ SP + 4 ]
 00000D42	     2800	CMP R0 #0
 00000D44	     BF08	IT EQ
 00000D46	 EC03D364	TrapEQ 4 at pos 7862
 00000D4A	     2100	MOVS R1 #0
 00000D4C	     7401	STRB R1 [ R0 + 16 ]
 00000D4E	 F85DEB04	LDR LR [ SP ] + 4
 00000D52	     B006	ADD SP SP #24
 00000D54	     4770	BX LR
 00000D56	     B401	PUSH R0
 00000D58	     B500	PUSH LR
 00000D5A	     9801	LDR R0 [ SP + 4 ]
 00000D5C	     2800	CMP R0 #0
 00000D5E	 F000803B	BEQ #118, goes to  00000DD8
 00000D62	     9801	LDR R0 [ SP + 4 ]
 00000D64	     2800	CMP R0 #0
 00000D66	     BF08	IT EQ
 00000D68	 EC03E1B4	TrapEQ 4 at pos 7963
 00000D6C	     7F00	LDRB R0 [ R0 + 28 ]
 00000D6E	     2800	CMP R0 #0
 00000D70	 F0008032	BEQ #100, goes to  00000DD8
 00000D74	     9801	LDR R0 [ SP + 4 ]
 00000D76	 F7FFFF1E	BL #-452, goes to  00000BB6
 00000D7A	     9801	LDR R0 [ SP + 4 ]
 00000D7C	     2800	CMP R0 #0
 00000D7E	     BF08	IT EQ
 00000D80	 EC03E534	TrapEQ 4 at pos 8019
 00000D84	     7C40	LDRB R0 [ R0 + 17 ]
 00000D86	     2800	CMP R0 #0
 00000D88	 F0408026	BNE #76, goes to  00000DD8
 00000D8C	     9801	LDR R0 [ SP + 4 ]
 00000D8E	     2800	CMP R0 #0
 00000D90	     BF08	IT EQ
 00000D92	 EC03E764	TrapEQ 4 at pos 8054
 00000D96	     301C	ADDS R0 R0 #28
 00000D98	     9901	LDR R1 [ SP + 4 ]
 00000D9A	     2900	CMP R1 #0
 00000D9C	     BF08	IT EQ
 00000D9E	 EC03E7D4	TrapEQ 4 at pos 8061
 00000DA2	     6F09	LDR R1 [ R1 + 112 ]
 00000DA4	 20500034	BL Mod(  2) proc(5)
 00000DA8	     9801	LDR R0 [ SP + 4 ]
 00000DAA	     2800	CMP R0 #0
 00000DAC	     BF08	IT EQ
 00000DAE	 EC03F0F4	TrapEQ 4 at pos 8079
 00000DB2	     2101	MOVS R1 #1
 00000DB4	     7441	STRB R1 [ R0 + 17 ]
 00000DB6	     9801	LDR R0 [ SP + 4 ]
 00000DB8	     2800	CMP R0 #0
 00000DBA	     BF08	IT EQ
 00000DBC	 EC03F1F4	TrapEQ 4 at pos 8095
 00000DC0	 100004D1	MOV R1 lower 16-bits base(0), next at  0000041E
 00000DC4	 00000000	MOVT R1 higher 16-bits var + 0
 00000DC8	     6809	LDR R1 [ R1 + 0 ]
 00000DCA	     6001	STR R1 [  R0 + 0 ]
 00000DCC	     9801	LDR R0 [ SP + 4 ]
 00000DCE	 10000007	MOV R1 lower 16-bits base(0), next at  00000DC0
 00000DD2	 00000000	MOVT R1 higher 16-bits var + 0
 00000DD6	     6008	STR R0 [  R1 + 0 ]
 00000DD8	 F85DEB04	LDR LR [ SP ] + 4
 00000DDC	     B001	ADD SP SP #4
 00000DDE	     4770	BX LR
 00000DE0	     B401	PUSH R0
 00000DE2	     B500	PUSH LR
 00000DE4	     9801	LDR R0 [ SP + 4 ]
 00000DE6	     2800	CMP R0 #0
 00000DE8	 F0008003	BEQ #6, goes to  00000DF2
 00000DEC	     9801	LDR R0 [ SP + 4 ]
 00000DEE	 F7FFFEE2	BL #-572, goes to  00000BB6
 00000DF2	 F85DEB04	LDR LR [ SP ] + 4
 00000DF6	     B001	ADD SP SP #4
 00000DF8	     4770	BX LR
 00000DFA	 F5AD6D82	SUB SP SP #1040
 00000DFE	     B401	PUSH R0
 00000E00	     B500	PUSH LR
 00000E02	     9801	LDR R0 [ SP + 4 ]
 00000E04	     2800	CMP R0 #0
 00000E06	 F0008088	BEQ #272, goes to  00000F1A
 00000E0A	     9801	LDR R0 [ SP + 4 ]
 00000E0C	     2800	CMP R0 #0
 00000E0E	     BF08	IT EQ
 00000E10	 EC041444	TrapEQ 4 at pos 8388
 00000E14	     6880	LDR R0 [ R0 + 8 ]
 00000E16	     1C40	ADDS R0 R0 #1
 00000E18	     9002	STR R0 [ SP + 8 ]
 00000E1A	     9801	LDR R0 [ SP + 4 ]
 00000E1C	     2800	CMP R0 #0
 00000E1E	     BF08	IT EQ
 00000E20	 EC041514	TrapEQ 4 at pos 8401
 00000E24	     2100	MOVS R1 #0
 00000E26	     6081	STR R1 [  R0 + 8 ]
 00000E28	     9801	LDR R0 [ SP + 4 ]
 00000E2A	     2800	CMP R0 #0
 00000E2C	     BF08	IT EQ
 00000E2E	 EC0415F4	TrapEQ 4 at pos 8415
 00000E32	 F45F71B0	MOVS R1 #352
 00000E36	     60C1	STR R1 [  R0 + 12 ]
 00000E38	     9802	LDR R0 [ SP + 8 ]
 00000E3A	     2840	CMP R0 #64
 00000E3C	 F3008004	BGT #8, goes to  00000E48
 00000E40	     9802	LDR R0 [ SP + 8 ]
 00000E42	     9003	STR R0 [ SP + 12 ]
 00000E44	 F000B854	B #168, goes to  00000EF0
 00000E48	     2040	MOVS R0 #64
 00000E4A	     9003	STR R0 [ SP + 12 ]
 00000E4C	     9802	LDR R0 [ SP + 8 ]
 00000E4E	     9903	LDR R1 [ SP + 12 ]
 00000E50	     1A40	SUBS R0 R0 R1
 00000E52	     9002	STR R0 [ SP + 8 ]
 00000E54	     9802	LDR R0 [ SP + 8 ]
 00000E56	     1E40	SUBS R0 R0 #1
 00000E58	 F36F201F	BFC R0 #8 #24
 00000E5C	     9004	STR R0 [ SP + 16 ]
 00000E5E	     9802	LDR R0 [ SP + 8 ]
 00000E60	     1E40	SUBS R0 R0 #1
 00000E62	     1200	ASRS R0 R0 #8
 00000E64	     9005	STR R0 [ SP + 20 ]
 00000E66	     9805	LDR R0 [ SP + 20 ]
 00000E68	     2800	CMP R0 #0
 00000E6A	 F2C08041	BLT #130, goes to  00000EF0
 00000E6E	     9801	LDR R0 [ SP + 4 ]
 00000E70	     2800	CMP R0 #0
 00000E72	     BF08	IT EQ
 00000E74	 EC043044	TrapEQ 4 at pos 8580
 00000E78	     9905	LDR R1 [ SP + 20 ]
 00000E7A	     290C	CMP R1 #12
 00000E7C	     BF28	IT CS
 00000E7E	 EC043071	TrapCS 1 at pos 8583
 00000E82	 EB100081	ADDS R0 R0 R1 LSL #2
 00000E86	     6C00	LDR R0 [ R0 + 64 ]
 00000E88	     2800	CMP R0 #0
 00000E8A	     BF08	IT EQ
 00000E8C	 EC0430B4	TrapEQ 4 at pos 8587
 00000E90	     6800	LDR R0 [ R0 + 0 ]
 00000E92	     A906	ADD R1 SP #24
 00000E94	 11500078	BL Mod(  1) proc(21)
 00000E98	     9804	LDR R0 [ SP + 16 ]
 00000E9A	     1E40	SUBS R0 R0 #1
 00000E9C	     9004	STR R0 [ SP + 16 ]
 00000E9E	     9804	LDR R0 [ SP + 16 ]
 00000EA0	 F5B07F80	CMP R0 #256
 00000EA4	     BF28	IT CS
 00000EA6	 EC043441	TrapCS 1 at pos 8644
 00000EAA	 EB0D0080	ADD R0 SP R0 LSL #2
 00000EAE	     6980	LDR R0 [ R0 + 24 ]
 00000EB0	 1130000E	BL Mod(  1) proc(19)
 00000EB4	     9804	LDR R0 [ SP + 16 ]
 00000EB6	     2800	CMP R0 #0
 00000EB8	     D1EE	BNE #-36, goes to  00000E98
 00000EBA	     9801	LDR R0 [ SP + 4 ]
 00000EBC	     2800	CMP R0 #0
 00000EBE	     BF08	IT EQ
 00000EC0	 EC043744	TrapEQ 4 at pos 8692
 00000EC4	     9905	LDR R1 [ SP + 20 ]
 00000EC6	     290C	CMP R1 #12
 00000EC8	     BF28	IT CS
 00000ECA	 EC043771	TrapCS 1 at pos 8695
 00000ECE	 EB100081	ADDS R0 R0 R1 LSL #2
 00000ED2	     6C00	LDR R0 [ R0 + 64 ]
 00000ED4	     2800	CMP R0 #0
 00000ED6	     BF08	IT EQ
 00000ED8	 EC0437B4	TrapEQ 4 at pos 8699
 00000EDC	     6800	LDR R0 [ R0 + 0 ]
 00000EDE	 11300017	BL Mod(  1) proc(19)
 00000EE2	 F45F7080	MOVS R0 #256
 00000EE6	     9004	STR R0 [ SP + 16 ]
 00000EE8	     9805	LDR R0 [ SP + 20 ]
 00000EEA	     1E40	SUBS R0 R0 #1
 00000EEC	     9005	STR R0 [ SP + 20 ]
 00000EEE	     E7BA	B #-140, goes to  00000E66
 00000EF0	     9803	LDR R0 [ SP + 12 ]
 00000EF2	     1E40	SUBS R0 R0 #1
 00000EF4	     9003	STR R0 [ SP + 12 ]
 00000EF6	     9801	LDR R0 [ SP + 4 ]
 00000EF8	     2800	CMP R0 #0
 00000EFA	     BF08	IT EQ
 00000EFC	 EC044524	TrapEQ 4 at pos 8786
 00000F00	     9903	LDR R1 [ SP + 12 ]
 00000F02	     2940	CMP R1 #64
 00000F04	     BF28	IT CS
 00000F06	 EC044551	TrapCS 1 at pos 8789
 00000F0A	 EB100081	ADDS R0 R0 R1 LSL #2
 00000F0E	     6F00	LDR R0 [ R0 + 112 ]
 00000F10	 11300019	BL Mod(  1) proc(19)
 00000F14	     9803	LDR R0 [ SP + 12 ]
 00000F16	     2800	CMP R0 #0
 00000F18	     D1EA	BNE #-44, goes to  00000EF0
 00000F1A	 F85DEB04	LDR LR [ SP ] + 4
 00000F1E	 F20D4D14	ADD SP SP #1044
 00000F22	     4770	BX LR
 00000F24	     B089	SUB SP SP #36
 00000F26	     B407	PUSH R0 R1 R2
 00000F28	     B500	PUSH LR
 00000F2A	     9801	LDR R0 [ SP + 4 ]
 00000F2C	     9902	LDR R1 [ SP + 8 ]
 00000F2E	     AA05	ADD R2 SP #20
 00000F30	     9B03	LDR R3 [ SP + 12 ]
 00000F32	 F7FFF865	BL #-3894, goes to  00000000
 00000F36	     9803	LDR R0 [ SP + 12 ]
 00000F38	     6800	LDR R0 [ R0 + 0 ]
 00000F3A	     2800	CMP R0 #0
 00000F3C	 F040800B	BNE #22, goes to  00000F56
 00000F40	     A805	ADD R0 SP #20
 00000F42	     A904	ADD R1 SP #16
 00000F44	 2060001A	BL Mod(  2) proc(6)
 00000F48	     9804	LDR R0 [ SP + 16 ]
 00000F4A	     2800	CMP R0 #0
 00000F4C	 F0408003	BNE #6, goes to  00000F56
 00000F50	     2002	MOVS R0 #2
 00000F52	     9903	LDR R1 [ SP + 12 ]
 00000F54	     6008	STR R0 [  R1 + 0 ]
 00000F56	 F85DEB04	LDR LR [ SP ] + 4
 00000F5A	     B00C	ADD SP SP #48
 00000F5C	     4770	BX LR
 00000F5E	     B092	SUB SP SP #72
 00000F60	     B41F	PUSH R0 R1 R2 R3 R4
 00000F62	     B500	PUSH LR
 00000F64	     A817	ADD R0 SP #92
 00000F66	 12000126	MOV R1 lower 16-bits base(2), next at  00000D1A
 00000F6A	 00000001	MOVT R1 higher 16-bits const(1)
 00000F6E	     DF00	SVC #0
 00000F70	     9801	LDR R0 [ SP + 4 ]
 00000F72	     9902	LDR R1 [ SP + 8 ]
 00000F74	     AA07	ADD R2 SP #28
 00000F76	     9B05	LDR R3 [ SP + 20 ]
 00000F78	 F7FFF842	BL #-3964, goes to  00000000
 00000F7C	     9805	LDR R0 [ SP + 20 ]
 00000F7E	     6800	LDR R0 [ R0 + 0 ]
 00000F80	     2800	CMP R0 #0
 00000F82	 F040803A	BNE #116, goes to  00000FFA
 00000F86	     9803	LDR R0 [ SP + 12 ]
 00000F88	     9904	LDR R1 [ SP + 16 ]
 00000F8A	     AA0F	ADD R2 SP #60
 00000F8C	     9B05	LDR R3 [ SP + 20 ]
 00000F8E	 F7FFF837	BL #-3986, goes to  00000000
 00000F92	     9805	LDR R0 [ SP + 20 ]
 00000F94	     6800	LDR R0 [ R0 + 0 ]
 00000F96	     2800	CMP R0 #0
 00000F98	 F040802F	BNE #94, goes to  00000FFA
 00000F9C	     A807	ADD R0 SP #28
 00000F9E	     A906	ADD R1 SP #24
 00000FA0	 2060002E	BL Mod(  2) proc(6)
 00000FA4	     9806	LDR R0 [ SP + 24 ]
 00000FA6	     2800	CMP R0 #0
 00000FA8	 F0008024	BEQ #72, goes to  00000FF4
 00000FAC	     A80F	ADD R0 SP #60
 00000FAE	     9906	LDR R1 [ SP + 24 ]
 00000FB0	 20500008	BL Mod(  2) proc(5)
 00000FB4	     9806	LDR R0 [ SP + 24 ]
 00000FB6	     9917	LDR R1 [ SP + 92 ]
 00000FB8	     2900	CMP R1 #0
 00000FBA	     BF08	IT EQ
 00000FBC	 EC04A214	TrapEQ 4 at pos 9505
 00000FC0	 11500008	BL Mod(  1) proc(21)
 00000FC4	     9817	LDR R0 [ SP + 92 ]
 00000FC6	     2800	CMP R0 #0
 00000FC8	     BF08	IT EQ
 00000FCA	 EC04A2C4	TrapEQ 4 at pos 9516
 00000FCE	     1D00	ADDS R0 R0 #4
 00000FD0	     A90F	ADD R1 SP #60
 00000FD2	     2208	MOVS R2 #8
 00000FD4	 F8513B04	LDR R3 [ R1 ] + 4
 00000FD8	 F8403B04	STR R3 [  R0 ] + 4
 00000FDC	     1E52	SUBS R2 R2 #1
 00000FDE	     D1F9	BNE #-14, goes to  00000FD4
 00000FE0	     9806	LDR R0 [ SP + 24 ]
 00000FE2	     9917	LDR R1 [ SP + 92 ]
 00000FE4	     2900	CMP R1 #0
 00000FE6	     BF08	IT EQ
 00000FE8	 EC04A544	TrapEQ 4 at pos 9556
 00000FEC	 11600016	BL Mod(  1) proc(22)
 00000FF0	 F000B803	B #6, goes to  00000FFA
 00000FF4	     2002	MOVS R0 #2
 00000FF6	     9905	LDR R1 [ SP + 20 ]
 00000FF8	     6008	STR R0 [  R1 + 0 ]
 00000FFA	 F85DEB04	LDR LR [ SP ] + 4
 00000FFE	     B017	ADD SP SP #92
 00001000	     4770	BX LR
 00001002	     B401	PUSH R0
 00001004	     B500	PUSH LR
 00001006	     9801	LDR R0 [ SP + 4 ]
 00001008	     2800	CMP R0 #0
 0000100A	     BF08	IT EQ
 0000100C	 EC04B554	TrapEQ 4 at pos 9685
 00001010	     6880	LDR R0 [ R0 + 8 ]
 00001012	     0280	LSLS R0 R0 #10
 00001014	     9901	LDR R1 [ SP + 4 ]
 00001016	     2900	CMP R1 #0
 00001018	     BF08	IT EQ
 0000101A	 EC04B644	TrapEQ 4 at pos 9700
 0000101E	     68C9	LDR R1 [ R1 + 12 ]
 00001020	     1840	ADDS R0 R0 R1
 00001022	 F5B070B0	SUBS R0 R0 #352
 00001026	 F85DEB04	LDR LR [ SP ] + 4
 0000102A	     B001	ADD SP SP #4
 0000102C	     4770	BX LR
 0000102E	     B401	PUSH R0
 00001030	     B500	PUSH LR
 00001032	     9801	LDR R0 [ SP + 4 ]
 00001034	     2800	CMP R0 #0
 00001036	     BF08	IT EQ
 00001038	 EC04C334	TrapEQ 4 at pos 9779
 0000103C	     6BC0	LDR R0 [ R0 + 60 ]
 0000103E	 F85DEB04	LDR LR [ SP ] + 4
 00001042	     B001	ADD SP SP #4
 00001044	     4770	BX LR
 00001046	     B082	SUB SP SP #8
 00001048	     B40F	PUSH R0 R1 R2 R3
 0000104A	     B500	PUSH LR
 0000104C	     2000	MOVS R0 #0
 0000104E	     9901	LDR R1 [ SP + 4 ]
 00001050	     7008	STRB R0 [ R1 + 0 ]
 00001052	     2000	MOVS R0 #0
 00001054	     9901	LDR R1 [ SP + 4 ]
 00001056	     6048	STR R0 [  R1 + 4 ]
 00001058	     9803	LDR R0 [ SP + 12 ]
 0000105A	     2800	CMP R0 #0
 0000105C	 F000804D	BEQ #154, goes to  000010FA
 00001060	     9804	LDR R0 [ SP + 16 ]
 00001062	     2800	CMP R0 #0
 00001064	 F2808007	BGE #14, goes to  00001076
 00001068	     2000	MOVS R0 #0
 0000106A	     9005	STR R0 [ SP + 20 ]
 0000106C	 F45F70B0	MOVS R0 #352
 00001070	     9006	STR R0 [ SP + 24 ]
 00001072	 F000B82F	B #94, goes to  000010D4
 00001076	     9803	LDR R0 [ SP + 12 ]
 00001078	     2800	CMP R0 #0
 0000107A	     BF08	IT EQ
 0000107C	 EC04E494	TrapEQ 4 at pos 10057
 00001080	     6880	LDR R0 [ R0 + 8 ]
 00001082	     0280	LSLS R0 R0 #10
 00001084	     9903	LDR R1 [ SP + 12 ]
 00001086	     2900	CMP R1 #0
 00001088	     BF08	IT EQ
 0000108A	 EC04E584	TrapEQ 4 at pos 10072
 0000108E	     68C9	LDR R1 [ R1 + 12 ]
 00001090	     1840	ADDS R0 R0 R1
 00001092	 F5B070B0	SUBS R0 R0 #352
 00001096	     9904	LDR R1 [ SP + 16 ]
 00001098	     4281	CMP R1 R0
 0000109A	 F280800D	BGE #26, goes to  000010B8
 0000109E	     9804	LDR R0 [ SP + 16 ]
 000010A0	 F51070B0	ADDS R0 R0 #352
 000010A4	     1280	ASRS R0 R0 #10
 000010A6	     9005	STR R0 [ SP + 20 ]
 000010A8	     9804	LDR R0 [ SP + 16 ]
 000010AA	 F51070B0	ADDS R0 R0 #352
 000010AE	 F36F209F	BFC R0 #10 #22
 000010B2	     9006	STR R0 [ SP + 24 ]
 000010B4	 F000B80E	B #28, goes to  000010D4
 000010B8	     9803	LDR R0 [ SP + 12 ]
 000010BA	     2800	CMP R0 #0
 000010BC	     BF08	IT EQ
 000010BE	 EC04F324	TrapEQ 4 at pos 10162
 000010C2	     6880	LDR R0 [ R0 + 8 ]
 000010C4	     9005	STR R0 [ SP + 20 ]
 000010C6	     9803	LDR R0 [ SP + 12 ]
 000010C8	     2800	CMP R0 #0
 000010CA	     BF08	IT EQ
 000010CC	 EC04F404	TrapEQ 4 at pos 10176
 000010D0	     68C0	LDR R0 [ R0 + 12 ]
 000010D2	     9006	STR R0 [ SP + 24 ]
 000010D4	     9803	LDR R0 [ SP + 12 ]
 000010D6	     9901	LDR R1 [ SP + 4 ]
 000010D8	     6088	STR R0 [  R1 + 8 ]
 000010DA	     9805	LDR R0 [ SP + 20 ]
 000010DC	     9901	LDR R1 [ SP + 4 ]
 000010DE	     60C8	STR R0 [  R1 + 12 ]
 000010E0	     9806	LDR R0 [ SP + 24 ]
 000010E2	     9901	LDR R1 [ SP + 4 ]
 000010E4	     6108	STR R0 [  R1 + 16 ]
 000010E6	     9803	LDR R0 [ SP + 12 ]
 000010E8	     2800	CMP R0 #0
 000010EA	     BF08	IT EQ
 000010EC	 EC0500D4	TrapEQ 4 at pos 10253
 000010F0	     6940	LDR R0 [ R0 + 20 ]
 000010F2	     9901	LDR R1 [ SP + 4 ]
 000010F4	     6148	STR R0 [  R1 + 20 ]
 000010F6	 F000B803	B #6, goes to  00001100
 000010FA	     2000	MOVS R0 #0
 000010FC	     9901	LDR R1 [ SP + 4 ]
 000010FE	     6088	STR R0 [  R1 + 8 ]
 00001100	 F85DEB04	LDR LR [ SP ] + 4
 00001104	     B006	ADD SP SP #24
 00001106	     4770	BX LR
 00001108	     B403	PUSH R0 R1
 0000110A	     B500	PUSH LR
 0000110C	     9801	LDR R0 [ SP + 4 ]
 0000110E	     68C0	LDR R0 [ R0 + 12 ]
 00001110	     0280	LSLS R0 R0 #10
 00001112	     9901	LDR R1 [ SP + 4 ]
 00001114	     6909	LDR R1 [ R1 + 16 ]
 00001116	     1840	ADDS R0 R0 R1
 00001118	 F5B070B0	SUBS R0 R0 #352
 0000111C	 F85DEB04	LDR LR [ SP ] + 4
 00001120	     B002	ADD SP SP #8
 00001122	     4770	BX LR
 00001124	     B403	PUSH R0 R1
 00001126	     B500	PUSH LR
 00001128	     9801	LDR R0 [ SP + 4 ]
 0000112A	     6880	LDR R0 [ R0 + 8 ]
 0000112C	 F85DEB04	LDR LR [ SP ] + 4
 00001130	     B002	ADD SP SP #8
 00001132	     4770	BX LR
 00001134	     B081	SUB SP SP #4
 00001136	     B407	PUSH R0 R1 R2
 00001138	     B500	PUSH LR
 0000113A	     9801	LDR R0 [ SP + 4 ]
 0000113C	     6940	LDR R0 [ R0 + 20 ]
 0000113E	     2800	CMP R0 #0
 00001140	     BF08	IT EQ
 00001142	 EC0524A4	TrapEQ 4 at pos 10570
 00001146	     9901	LDR R1 [ SP + 4 ]
 00001148	     68C9	LDR R1 [ R1 + 12 ]
 0000114A	     6800	LDR R0 [ R0 + 0 ]
 0000114C	     4281	CMP R1 R0
 0000114E	 F0008008	BEQ #16, goes to  00001162
 00001152	     9801	LDR R0 [ SP + 4 ]
 00001154	     6880	LDR R0 [ R0 + 8 ]
 00001156	     9901	LDR R1 [ SP + 4 ]
 00001158	     68C9	LDR R1 [ R1 + 12 ]
 0000115A	 F7FFFC82	BL #-1788, goes to  00000A62
 0000115E	     9901	LDR R1 [ SP + 4 ]
 00001160	     6148	STR R0 [  R1 + 20 ]
 00001162	     9801	LDR R0 [ SP + 4 ]
 00001164	     6940	LDR R0 [ R0 + 20 ]
 00001166	     2800	CMP R0 #0
 00001168	     BF08	IT EQ
 0000116A	 EC0530F4	TrapEQ 4 at pos 10639
 0000116E	     9901	LDR R1 [ SP + 4 ]
 00001170	     6909	LDR R1 [ R1 + 16 ]
 00001172	     6840	LDR R0 [ R0 + 4 ]
 00001174	     4281	CMP R1 R0
 00001176	 F2808018	BGE #48, goes to  000011AA
 0000117A	     9801	LDR R0 [ SP + 4 ]
 0000117C	     6940	LDR R0 [ R0 + 20 ]
 0000117E	     2800	CMP R0 #0
 00001180	     BF08	IT EQ
 00001182	 EC053244	TrapEQ 4 at pos 10660
 00001186	     9901	LDR R1 [ SP + 4 ]
 00001188	     6909	LDR R1 [ R1 + 16 ]
 0000118A	 F5B16F80	CMP R1 #1024
 0000118E	     BF28	IT CS
 00001190	 EC0532C1	TrapCS 1 at pos 10668
 00001194	     1840	ADDS R0 R0 R1
 00001196	     7C00	LDRB R0 [ R0 + 16 ]
 00001198	     9903	LDR R1 [ SP + 12 ]
 0000119A	     7008	STRB R0 [ R1 + 0 ]
 0000119C	     9801	LDR R0 [ SP + 4 ]
 0000119E	     3010	ADDS R0 R0 #16
 000011A0	     6801	LDR R1 [ R0 + 0 ]
 000011A2	     1C49	ADDS R1 R1 #1
 000011A4	     6001	STR R1 [  R0 + 0 ]
 000011A6	 F000B84D	B #154, goes to  00001244
 000011AA	     9801	LDR R0 [ SP + 4 ]
 000011AC	     6880	LDR R0 [ R0 + 8 ]
 000011AE	     2800	CMP R0 #0
 000011B0	     BF08	IT EQ
 000011B2	 EC053594	TrapEQ 4 at pos 10713
 000011B6	     9901	LDR R1 [ SP + 4 ]
 000011B8	     68C9	LDR R1 [ R1 + 12 ]
 000011BA	     6880	LDR R0 [ R0 + 8 ]
 000011BC	     4281	CMP R1 R0
 000011BE	 F280803B	BGE #118, goes to  00001238
 000011C2	     9801	LDR R0 [ SP + 4 ]
 000011C4	     300C	ADDS R0 R0 #12
 000011C6	     6801	LDR R1 [ R0 + 0 ]
 000011C8	     1C49	ADDS R1 R1 #1
 000011CA	     6001	STR R1 [  R0 + 0 ]
 000011CC	     9801	LDR R0 [ SP + 4 ]
 000011CE	     6880	LDR R0 [ R0 + 8 ]
 000011D0	     9901	LDR R1 [ SP + 4 ]
 000011D2	     68C9	LDR R1 [ R1 + 12 ]
 000011D4	 F7FFFC09	BL #-2030, goes to  000009EA
 000011D8	     9004	STR R0 [ SP + 16 ]
 000011DA	     9804	LDR R0 [ SP + 16 ]
 000011DC	     2800	CMP R0 #0
 000011DE	 F040801A	BNE #52, goes to  00001216
 000011E2	     9801	LDR R0 [ SP + 4 ]
 000011E4	     6940	LDR R0 [ R0 + 20 ]
 000011E6	     2800	CMP R0 #0
 000011E8	     BF08	IT EQ
 000011EA	 EC0543A4	TrapEQ 4 at pos 10810
 000011EE	     7A00	LDRB R0 [ R0 + 8 ]
 000011F0	     2800	CMP R0 #0
 000011F2	 F0008006	BEQ #12, goes to  00001202
 000011F6	     9801	LDR R0 [ SP + 4 ]
 000011F8	     6880	LDR R0 [ R0 + 8 ]
 000011FA	     9901	LDR R1 [ SP + 4 ]
 000011FC	     6949	LDR R1 [ R1 + 20 ]
 000011FE	 F7FFFAE6	BL #-2612, goes to  000007CE
 00001202	     9801	LDR R0 [ SP + 4 ]
 00001204	     6880	LDR R0 [ R0 + 8 ]
 00001206	     9901	LDR R1 [ SP + 4 ]
 00001208	     6949	LDR R1 [ R1 + 20 ]
 0000120A	     9A01	LDR R2 [ SP + 4 ]
 0000120C	     68D2	LDR R2 [ R2 + 12 ]
 0000120E	 F7FFFA6C	BL #-2856, goes to  000006EA
 00001212	 F000B803	B #6, goes to  0000121C
 00001216	     9804	LDR R0 [ SP + 16 ]
 00001218	     9901	LDR R1 [ SP + 4 ]
 0000121A	     6148	STR R0 [  R1 + 20 ]
 0000121C	     9801	LDR R0 [ SP + 4 ]
 0000121E	     6940	LDR R0 [ R0 + 20 ]
 00001220	     2800	CMP R0 #0
 00001222	     BF08	IT EQ
 00001224	 EC0553E4	TrapEQ 4 at pos 10942
 00001228	     7C00	LDRB R0 [ R0 + 16 ]
 0000122A	     9903	LDR R1 [ SP + 12 ]
 0000122C	     7008	STRB R0 [ R1 + 0 ]
 0000122E	     2001	MOVS R0 #1
 00001230	     9901	LDR R1 [ SP + 4 ]
 00001232	     6108	STR R0 [  R1 + 16 ]
 00001234	 F000B806	B #12, goes to  00001244
 00001238	     2000	MOVS R0 #0
 0000123A	     9903	LDR R1 [ SP + 12 ]
 0000123C	     7008	STRB R0 [ R1 + 0 ]
 0000123E	     2001	MOVS R0 #1
 00001240	     9901	LDR R1 [ SP + 4 ]
 00001242	     7008	STRB R0 [ R1 + 0 ]
 00001244	 F85DEB04	LDR LR [ SP ] + 4
 00001248	     B004	ADD SP SP #16
 0000124A	     4770	BX LR
 0000124C	     B081	SUB SP SP #4
 0000124E	     B41F	PUSH R0 R1 R2 R3 R4
 00001250	     B500	PUSH LR
 00001252	     2000	MOVS R0 #0
 00001254	     9006	STR R0 [ SP + 24 ]
 00001256	     9806	LDR R0 [ SP + 24 ]
 00001258	     9905	LDR R1 [ SP + 20 ]
 0000125A	     4288	CMP R0 R1
 0000125C	 F2808010	BGE #32, goes to  00001280
 00001260	     9801	LDR R0 [ SP + 4 ]
 00001262	     9902	LDR R1 [ SP + 8 ]
 00001264	     9A06	LDR R2 [ SP + 24 ]
 00001266	     9B04	LDR R3 [ SP + 16 ]
 00001268	     429A	CMP R2 R3
 0000126A	     BF28	IT CS
 0000126C	 EC057411	TrapCS 1 at pos 11201
 00001270	     9B03	LDR R3 [ SP + 12 ]
 00001272	     189A	ADDS R2 R3 R2
 00001274	 F7FFFF5E	BL #-324, goes to  00001134
 00001278	     9806	LDR R0 [ SP + 24 ]
 0000127A	     1C40	ADDS R0 R0 #1
 0000127C	     9006	STR R0 [ SP + 24 ]
 0000127E	     E7EA	B #-44, goes to  00001256
 00001280	 F85DEB04	LDR LR [ SP ] + 4
 00001284	     B006	ADD SP SP #24
 00001286	     4770	BX LR
 00001288	     B081	SUB SP SP #4
 0000128A	     B407	PUSH R0 R1 R2
 0000128C	     B500	PUSH LR
 0000128E	     9801	LDR R0 [ SP + 4 ]
 00001290	     6940	LDR R0 [ R0 + 20 ]
 00001292	     2800	CMP R0 #0
 00001294	     BF08	IT EQ
 00001296	 EC0585E4	TrapEQ 4 at pos 11358
 0000129A	     9901	LDR R1 [ SP + 4 ]
 0000129C	     68C9	LDR R1 [ R1 + 12 ]
 0000129E	     6800	LDR R0 [ R0 + 0 ]
 000012A0	     4281	CMP R1 R0
 000012A2	 F0008008	BEQ #16, goes to  000012B6
 000012A6	     9801	LDR R0 [ SP + 4 ]
 000012A8	     6880	LDR R0 [ R0 + 8 ]
 000012AA	     9901	LDR R1 [ SP + 4 ]
 000012AC	     68C9	LDR R1 [ R1 + 12 ]
 000012AE	 F7FFFBD8	BL #-2128, goes to  00000A62
 000012B2	     9901	LDR R1 [ SP + 4 ]
 000012B4	     6148	STR R0 [  R1 + 20 ]
 000012B6	     9801	LDR R0 [ SP + 4 ]
 000012B8	     6940	LDR R0 [ R0 + 20 ]
 000012BA	     2800	CMP R0 #0
 000012BC	     BF08	IT EQ
 000012BE	 EC059234	TrapEQ 4 at pos 11427
 000012C2	     9901	LDR R1 [ SP + 4 ]
 000012C4	     6909	LDR R1 [ R1 + 16 ]
 000012C6	     6840	LDR R0 [ R0 + 4 ]
 000012C8	     4281	CMP R1 R0
 000012CA	 F2808018	BGE #48, goes to  000012FE
 000012CE	     9801	LDR R0 [ SP + 4 ]
 000012D0	     6940	LDR R0 [ R0 + 20 ]
 000012D2	     2800	CMP R0 #0
 000012D4	     BF08	IT EQ
 000012D6	 EC0593D4	TrapEQ 4 at pos 11453
 000012DA	     9901	LDR R1 [ SP + 4 ]
 000012DC	     6909	LDR R1 [ R1 + 16 ]
 000012DE	 F5B16F80	CMP R1 #1024
 000012E2	     BF28	IT CS
 000012E4	 EC059451	TrapCS 1 at pos 11461
 000012E8	     1840	ADDS R0 R0 R1
 000012EA	     7C00	LDRB R0 [ R0 + 16 ]
 000012EC	     9903	LDR R1 [ SP + 12 ]
 000012EE	     7008	STRB R0 [ R1 + 0 ]
 000012F0	     9801	LDR R0 [ SP + 4 ]
 000012F2	     3010	ADDS R0 R0 #16
 000012F4	     6801	LDR R1 [ R0 + 0 ]
 000012F6	     1C49	ADDS R1 R1 #1
 000012F8	     6001	STR R1 [  R0 + 0 ]
 000012FA	 F000B84D	B #154, goes to  00001398
 000012FE	     9801	LDR R0 [ SP + 4 ]
 00001300	     6880	LDR R0 [ R0 + 8 ]
 00001302	     2800	CMP R0 #0
 00001304	     BF08	IT EQ
 00001306	 EC059734	TrapEQ 4 at pos 11507
 0000130A	     9901	LDR R1 [ SP + 4 ]
 0000130C	     68C9	LDR R1 [ R1 + 12 ]
 0000130E	     6880	LDR R0 [ R0 + 8 ]
 00001310	     4281	CMP R1 R0
 00001312	 F280803B	BGE #118, goes to  0000138C
 00001316	     9801	LDR R0 [ SP + 4 ]
 00001318	     300C	ADDS R0 R0 #12
 0000131A	     6801	LDR R1 [ R0 + 0 ]
 0000131C	     1C49	ADDS R1 R1 #1
 0000131E	     6001	STR R1 [  R0 + 0 ]
 00001320	     9801	LDR R0 [ SP + 4 ]
 00001322	     6880	LDR R0 [ R0 + 8 ]
 00001324	     9901	LDR R1 [ SP + 4 ]
 00001326	     68C9	LDR R1 [ R1 + 12 ]
 00001328	 F7FFFB5F	BL #-2370, goes to  000009EA
 0000132C	     9004	STR R0 [ SP + 16 ]
 0000132E	     9804	LDR R0 [ SP + 16 ]
 00001330	     2800	CMP R0 #0
 00001332	 F040801A	BNE #52, goes to  0000136A
 00001336	     9801	LDR R0 [ SP + 4 ]
 00001338	     6940	LDR R0 [ R0 + 20 ]
 0000133A	     2800	CMP R0 #0
 0000133C	     BF08	IT EQ
 0000133E	 EC05A544	TrapEQ 4 at pos 11604
 00001342	     7A00	LDRB R0 [ R0 + 8 ]
 00001344	     2800	CMP R0 #0
 00001346	 F0008006	BEQ #12, goes to  00001356
 0000134A	     9801	LDR R0 [ SP + 4 ]
 0000134C	     6880	LDR R0 [ R0 + 8 ]
 0000134E	     9901	LDR R1 [ SP + 4 ]
 00001350	     6949	LDR R1 [ R1 + 20 ]
 00001352	 F7FFFA3C	BL #-2952, goes to  000007CE
 00001356	     9801	LDR R0 [ SP + 4 ]
 00001358	     6880	LDR R0 [ R0 + 8 ]
 0000135A	     9901	LDR R1 [ SP + 4 ]
 0000135C	     6949	LDR R1 [ R1 + 20 ]
 0000135E	     9A01	LDR R2 [ SP + 4 ]
 00001360	     68D2	LDR R2 [ R2 + 12 ]
 00001362	 F7FFF9C2	BL #-3196, goes to  000006EA
 00001366	 F000B803	B #6, goes to  00001370
 0000136A	     9804	LDR R0 [ SP + 16 ]
 0000136C	     9901	LDR R1 [ SP + 4 ]
 0000136E	     6148	STR R0 [  R1 + 20 ]
 00001370	     9801	LDR R0 [ SP + 4 ]
 00001372	     6940	LDR R0 [ R0 + 20 ]
 00001374	     2800	CMP R0 #0
 00001376	     BF08	IT EQ
 00001378	 EC05B5D4	TrapEQ 4 at pos 11741
 0000137C	     7C00	LDRB R0 [ R0 + 16 ]
 0000137E	     9903	LDR R1 [ SP + 12 ]
 00001380	     7008	STRB R0 [ R1 + 0 ]
 00001382	     2001	MOVS R0 #1
 00001384	     9901	LDR R1 [ SP + 4 ]
 00001386	     6108	STR R0 [  R1 + 16 ]
 00001388	 F000B806	B #12, goes to  00001398
 0000138C	     2000	MOVS R0 #0
 0000138E	     9903	LDR R1 [ SP + 12 ]
 00001390	     7008	STRB R0 [ R1 + 0 ]
 00001392	     2001	MOVS R0 #1
 00001394	     9901	LDR R1 [ SP + 4 ]
 00001396	     7008	STRB R0 [ R1 + 0 ]
 00001398	 F85DEB04	LDR LR [ SP ] + 4
 0000139C	     B004	ADD SP SP #16
 0000139E	     4770	BX LR
 000013A0	     B081	SUB SP SP #4
 000013A2	     B407	PUSH R0 R1 R2
 000013A4	     B500	PUSH LR
 000013A6	     9801	LDR R0 [ SP + 4 ]
 000013A8	     9902	LDR R1 [ SP + 8 ]
 000013AA	     AA04	ADD R2 SP #16
 000013AC	 F7FFFEC2	BL #-636, goes to  00001134
 000013B0	     9801	LDR R0 [ SP + 4 ]
 000013B2	     9902	LDR R1 [ SP + 8 ]
 000013B4	 F10D0211	ADD R2 SP #17
 000013B8	 F7FFFEBC	BL #-648, goes to  00001134
 000013BC	     9801	LDR R0 [ SP + 4 ]
 000013BE	     9902	LDR R1 [ SP + 8 ]
 000013C0	 F10D0212	ADD R2 SP #18
 000013C4	 F7FFFEB6	BL #-660, goes to  00001134
 000013C8	     9801	LDR R0 [ SP + 4 ]
 000013CA	     9902	LDR R1 [ SP + 8 ]
 000013CC	 F10D0213	ADD R2 SP #19
 000013D0	 F7FFFEB0	BL #-672, goes to  00001134
 000013D4	 F89D0013	LDRB R0 [ SP + 19 ]
 000013D8	     0200	LSLS R0 R0 #8
 000013DA	 F89D1012	LDRB R1 [ SP + 18 ]
 000013DE	     1840	ADDS R0 R0 R1
 000013E0	     0200	LSLS R0 R0 #8
 000013E2	 F89D1011	LDRB R1 [ SP + 17 ]
 000013E6	     1840	ADDS R0 R0 R1
 000013E8	     0200	LSLS R0 R0 #8
 000013EA	 F89D1010	LDRB R1 [ SP + 16 ]
 000013EE	     1840	ADDS R0 R0 R1
 000013F0	     9903	LDR R1 [ SP + 12 ]
 000013F2	     6008	STR R0 [  R1 + 0 ]
 000013F4	 F85DEB04	LDR LR [ SP ] + 4
 000013F8	     B004	ADD SP SP #16
 000013FA	     4770	BX LR
 000013FC	     B407	PUSH R0 R1 R2
 000013FE	     B500	PUSH LR
 00001400	     9801	LDR R0 [ SP + 4 ]
 00001402	     9902	LDR R1 [ SP + 8 ]
 00001404	     9A03	LDR R2 [ SP + 12 ]
 00001406	 F7FFFFCB	BL #-106, goes to  000013A0
 0000140A	 F85DEB04	LDR LR [ SP ] + 4
 0000140E	     B003	ADD SP SP #12
 00001410	     4770	BX LR
 00001412	     B081	SUB SP SP #4
 00001414	     B407	PUSH R0 R1 R2
 00001416	     B500	PUSH LR
 00001418	     9801	LDR R0 [ SP + 4 ]
 0000141A	     9902	LDR R1 [ SP + 8 ]
 0000141C	     9A03	LDR R2 [ SP + 12 ]
 0000141E	 F7FFFFBF	BL #-130, goes to  000013A0
 00001422	 F85DEB04	LDR LR [ SP ] + 4
 00001426	     B004	ADD SP SP #16
 00001428	     4770	BX LR
 0000142A	     B082	SUB SP SP #8
 0000142C	     B40F	PUSH R0 R1 R2 R3
 0000142E	     B500	PUSH LR
 00001430	     2000	MOVS R0 #0
 00001432	     9005	STR R0 [ SP + 20 ]
 00001434	     9801	LDR R0 [ SP + 4 ]
 00001436	     9902	LDR R1 [ SP + 8 ]
 00001438	     AA06	ADD R2 SP #24
 0000143A	 F7FFFF25	BL #-438, goes to  00001288
 0000143E	 F89D0018	LDRB R0 [ SP + 24 ]
 00001442	     2800	CMP R0 #0
 00001444	 F000801A	BEQ #52, goes to  0000147C
 00001448	     9804	LDR R0 [ SP + 16 ]
 0000144A	     1E40	SUBS R0 R0 #1
 0000144C	     9905	LDR R1 [ SP + 20 ]
 0000144E	     4281	CMP R1 R0
 00001450	 F280800E	BGE #28, goes to  00001470
 00001454	     9805	LDR R0 [ SP + 20 ]
 00001456	     9904	LDR R1 [ SP + 16 ]
 00001458	     4288	CMP R0 R1
 0000145A	     BF28	IT CS
 0000145C	 EC061201	TrapCS 1 at pos 12448
 00001460	     9903	LDR R1 [ SP + 12 ]
 00001462	     1808	ADDS R0 R1 R0
 00001464	 F89D1018	LDRB R1 [ SP + 24 ]
 00001468	     7001	STRB R1 [ R0 + 0 ]
 0000146A	     9805	LDR R0 [ SP + 20 ]
 0000146C	     1C40	ADDS R0 R0 #1
 0000146E	     9005	STR R0 [ SP + 20 ]
 00001470	     9801	LDR R0 [ SP + 4 ]
 00001472	     9902	LDR R1 [ SP + 8 ]
 00001474	     AA06	ADD R2 SP #24
 00001476	 F7FFFF07	BL #-498, goes to  00001288
 0000147A	     E7E0	B #-64, goes to  0000143E
 0000147C	     9805	LDR R0 [ SP + 20 ]
 0000147E	     9904	LDR R1 [ SP + 16 ]
 00001480	     4288	CMP R0 R1
 00001482	     BF28	IT CS
 00001484	 EC061591	TrapCS 1 at pos 12505
 00001488	     9903	LDR R1 [ SP + 12 ]
 0000148A	     1808	ADDS R0 R1 R0
 0000148C	     2100	MOVS R1 #0
 0000148E	     7001	STRB R1 [ R0 + 0 ]
 00001490	 F85DEB04	LDR LR [ SP ] + 4
 00001494	     B006	ADD SP SP #24
 00001496	     4770	BX LR
 00001498	     B083	SUB SP SP #12
 0000149A	     B407	PUSH R0 R1 R2
 0000149C	     B500	PUSH LR
 0000149E	     2020	MOVS R0 #32
 000014A0	     9004	STR R0 [ SP + 16 ]
 000014A2	     2000	MOVS R0 #0
 000014A4	     9005	STR R0 [ SP + 20 ]
 000014A6	     9801	LDR R0 [ SP + 4 ]
 000014A8	     9902	LDR R1 [ SP + 8 ]
 000014AA	     AA06	ADD R2 SP #24
 000014AC	 F7FFFE42	BL #-892, goes to  00001134
 000014B0	 F89D0018	LDRB R0 [ SP + 24 ]
 000014B4	     2880	CMP R0 #128
 000014B6	 F2C08011	BLT #34, goes to  000014DC
 000014BA	     9805	LDR R0 [ SP + 20 ]
 000014BC	 F89D1018	LDRB R1 [ SP + 24 ]
 000014C0	     1840	ADDS R0 R0 R1
 000014C2	     3880	SUBS R0 R0 #128
 000014C4	 EA5F10F0	RORS R0 R0 #7
 000014C8	     9005	STR R0 [ SP + 20 ]
 000014CA	     9804	LDR R0 [ SP + 16 ]
 000014CC	     1FC0	SUBS R0 R0 #7
 000014CE	     9004	STR R0 [ SP + 16 ]
 000014D0	     9801	LDR R0 [ SP + 4 ]
 000014D2	     9902	LDR R1 [ SP + 8 ]
 000014D4	     AA06	ADD R2 SP #24
 000014D6	 F7FFFE2D	BL #-934, goes to  00001134
 000014DA	     E7E9	B #-46, goes to  000014B0
 000014DC	     9804	LDR R0 [ SP + 16 ]
 000014DE	     2804	CMP R0 #4
 000014E0	 F300800C	BGT #24, goes to  000014FC
 000014E4	 F89D0018	LDRB R0 [ SP + 24 ]
 000014E8	 F36F101F	BFC R0 #4 #28
 000014EC	     9905	LDR R1 [ SP + 20 ]
 000014EE	     1808	ADDS R0 R1 R0
 000014F0	 EA5F1030	RORS R0 R0 #4
 000014F4	     9903	LDR R1 [ SP + 12 ]
 000014F6	     6008	STR R0 [  R1 + 0 ]
 000014F8	 F000B80B	B #22, goes to  00001512
 000014FC	     9805	LDR R0 [ SP + 20 ]
 000014FE	 F89D1018	LDRB R1 [ SP + 24 ]
 00001502	     1840	ADDS R0 R0 R1
 00001504	 EA5F10F0	RORS R0 R0 #7
 00001508	     9904	LDR R1 [ SP + 16 ]
 0000150A	     1FC9	SUBS R1 R1 #7
 0000150C	     4108	ASRS R0 R0 R1
 0000150E	     9903	LDR R1 [ SP + 12 ]
 00001510	     6008	STR R0 [  R1 + 0 ]
 00001512	 F85DEB04	LDR LR [ SP ] + 4
 00001516	     B006	ADD SP SP #24
 00001518	     4770	BX LR
 0000151A	     B083	SUB SP SP #12
 0000151C	     B401	PUSH R0
 0000151E	     B500	PUSH LR
 00001520	     9801	LDR R0 [ SP + 4 ]
 00001522	     2800	CMP R0 #0
 00001524	     BF08	IT EQ
 00001526	 EC065434	TrapEQ 4 at pos 12995
 0000152A	     6880	LDR R0 [ R0 + 8 ]
 0000152C	     3840	SUBS R0 R0 #64
 0000152E	     1200	ASRS R0 R0 #8
 00001530	     9003	STR R0 [ SP + 12 ]
 00001532	     A804	ADD R0 SP #16
 00001534	 100002E7	MOV R1 lower 16-bits base(0), next at  00000F66
 00001538	 0000007C	MOVT R1 higher 16-bits const + 124
 0000153C	     DF00	SVC #0
 0000153E	     9804	LDR R0 [ SP + 16 ]
 00001540	     2800	CMP R0 #0
 00001542	     BF08	IT EQ
 00001544	 EC065684	TrapEQ 4 at pos 13032
 00001548	     2100	MOVS R1 #0
 0000154A	     6001	STR R1 [  R0 + 0 ]
 0000154C	     9804	LDR R0 [ SP + 16 ]
 0000154E	     2800	CMP R0 #0
 00001550	     BF08	IT EQ
 00001552	 EC065764	TrapEQ 4 at pos 13046
 00001556	     2101	MOVS R1 #1
 00001558	     7101	STRB R1 [ R0 + 4 ]
 0000155A	     9801	LDR R0 [ SP + 4 ]
 0000155C	     2800	CMP R0 #0
 0000155E	     BF08	IT EQ
 00001560	 EC066054	TrapEQ 4 at pos 13061
 00001564	     9903	LDR R1 [ SP + 12 ]
 00001566	     290C	CMP R1 #12
 00001568	     BF28	IT CS
 0000156A	 EC066081	TrapCS 1 at pos 13064
 0000156E	 EB100081	ADDS R0 R0 R1 LSL #2
 00001572	     9904	LDR R1 [ SP + 16 ]
 00001574	     6401	STR R1 [  R0 + 64 ]
 00001576	 F45F7080	MOVS R0 #256
 0000157A	     9002	STR R0 [ SP + 8 ]
 0000157C	     9802	LDR R0 [ SP + 8 ]
 0000157E	     1E40	SUBS R0 R0 #1
 00001580	     9002	STR R0 [ SP + 8 ]
 00001582	     9804	LDR R0 [ SP + 16 ]
 00001584	     2800	CMP R0 #0
 00001586	     BF08	IT EQ
 00001588	 EC066344	TrapEQ 4 at pos 13108
 0000158C	     9902	LDR R1 [ SP + 8 ]
 0000158E	 F5B17F80	CMP R1 #256
 00001592	     BF28	IT CS
 00001594	 EC066371	TrapCS 1 at pos 13111
 00001598	 EB100081	ADDS R0 R0 R1 LSL #2
 0000159C	     2100	MOVS R1 #0
 0000159E	     6081	STR R1 [  R0 + 8 ]
 000015A0	     9802	LDR R0 [ SP + 8 ]
 000015A2	     2800	CMP R0 #0
 000015A4	     D1EA	BNE #-44, goes to  0000157C
 000015A6	 F85DEB04	LDR LR [ SP ] + 4
 000015AA	     B004	ADD SP SP #16
 000015AC	     4770	BX LR
 000015AE	     B082	SUB SP SP #8
 000015B0	     B407	PUSH R0 R1 R2
 000015B2	     B500	PUSH LR
 000015B4	     9801	LDR R0 [ SP + 4 ]
 000015B6	     6940	LDR R0 [ R0 + 20 ]
 000015B8	     2800	CMP R0 #0
 000015BA	     BF08	IT EQ
 000015BC	 EC067494	TrapEQ 4 at pos 13257
 000015C0	     9901	LDR R1 [ SP + 4 ]
 000015C2	     68C9	LDR R1 [ R1 + 12 ]
 000015C4	     6800	LDR R0 [ R0 + 0 ]
 000015C6	     4281	CMP R1 R0
 000015C8	 F0008008	BEQ #16, goes to  000015DC
 000015CC	     9801	LDR R0 [ SP + 4 ]
 000015CE	     6880	LDR R0 [ R0 + 8 ]
 000015D0	     9901	LDR R1 [ SP + 4 ]
 000015D2	     68C9	LDR R1 [ R1 + 12 ]
 000015D4	 F7FFFA45	BL #-2934, goes to  00000A62
 000015D8	     9901	LDR R1 [ SP + 4 ]
 000015DA	     6148	STR R0 [  R1 + 20 ]
 000015DC	     9801	LDR R0 [ SP + 4 ]
 000015DE	     6940	LDR R0 [ R0 + 20 ]
 000015E0	     2800	CMP R0 #0
 000015E2	     BF08	IT EQ
 000015E4	 EC068104	TrapEQ 4 at pos 13328
 000015E8	     9901	LDR R1 [ SP + 4 ]
 000015EA	     6909	LDR R1 [ R1 + 16 ]
 000015EC	     6840	LDR R0 [ R0 + 4 ]
 000015EE	     4281	CMP R1 R0
 000015F0	 F2C08091	BLT #290, goes to  00001716
 000015F4	     9801	LDR R0 [ SP + 4 ]
 000015F6	     6900	LDR R0 [ R0 + 16 ]
 000015F8	 F5B06F80	CMP R0 #1024
 000015FC	 F280801C	BGE #56, goes to  00001638
 00001600	     9801	LDR R0 [ SP + 4 ]
 00001602	     6940	LDR R0 [ R0 + 20 ]
 00001604	     2800	CMP R0 #0
 00001606	     BF08	IT EQ
 00001608	 EC068454	TrapEQ 4 at pos 13381
 0000160C	     6841	LDR R1 [ R0 + 4 ]
 0000160E	     1C49	ADDS R1 R1 #1
 00001610	     6041	STR R1 [  R0 + 4 ]
 00001612	     9801	LDR R0 [ SP + 4 ]
 00001614	     6880	LDR R0 [ R0 + 8 ]
 00001616	     2800	CMP R0 #0
 00001618	     BF08	IT EQ
 0000161A	 EC068584	TrapEQ 4 at pos 13400
 0000161E	     68C1	LDR R1 [ R0 + 12 ]
 00001620	     1C49	ADDS R1 R1 #1
 00001622	     60C1	STR R1 [  R0 + 12 ]
 00001624	     9801	LDR R0 [ SP + 4 ]
 00001626	     6880	LDR R0 [ R0 + 8 ]
 00001628	     2800	CMP R0 #0
 0000162A	     BF08	IT EQ
 0000162C	 EC068664	TrapEQ 4 at pos 13414
 00001630	     2101	MOVS R1 #1
 00001632	     7401	STRB R1 [ R0 + 16 ]
 00001634	 F000B86F	B #222, goes to  00001716
 00001638	     9801	LDR R0 [ SP + 4 ]
 0000163A	     6880	LDR R0 [ R0 + 8 ]
 0000163C	     9004	STR R0 [ SP + 16 ]
 0000163E	     9804	LDR R0 [ SP + 16 ]
 00001640	     9901	LDR R1 [ SP + 4 ]
 00001642	     6949	LDR R1 [ R1 + 20 ]
 00001644	 F7FFF8C3	BL #-3706, goes to  000007CE
 00001648	     9801	LDR R0 [ SP + 4 ]
 0000164A	     300C	ADDS R0 R0 #12
 0000164C	     6801	LDR R1 [ R0 + 0 ]
 0000164E	     1C49	ADDS R1 R1 #1
 00001650	     6001	STR R1 [  R0 + 0 ]
 00001652	     9801	LDR R0 [ SP + 4 ]
 00001654	     6880	LDR R0 [ R0 + 8 ]
 00001656	     9901	LDR R1 [ SP + 4 ]
 00001658	     68C9	LDR R1 [ R1 + 12 ]
 0000165A	 F7FFF9C6	BL #-3188, goes to  000009EA
 0000165E	     9005	STR R0 [ SP + 20 ]
 00001660	     9805	LDR R0 [ SP + 20 ]
 00001662	     2800	CMP R0 #0
 00001664	 F0408051	BNE #162, goes to  0000170A
 00001668	     9804	LDR R0 [ SP + 16 ]
 0000166A	     2800	CMP R0 #0
 0000166C	     BF08	IT EQ
 0000166E	 EC0697C4	TrapEQ 4 at pos 13564
 00001672	     9901	LDR R1 [ SP + 4 ]
 00001674	     68C9	LDR R1 [ R1 + 12 ]
 00001676	     6880	LDR R0 [ R0 + 8 ]
 00001678	     4281	CMP R1 R0
 0000167A	 F3008009	BGT #18, goes to  00001690
 0000167E	     9804	LDR R0 [ SP + 16 ]
 00001680	     9901	LDR R1 [ SP + 4 ]
 00001682	     6949	LDR R1 [ R1 + 20 ]
 00001684	     9A01	LDR R2 [ SP + 4 ]
 00001686	     68D2	LDR R2 [ R2 + 12 ]
 00001688	 F7FFF82F	BL #-4002, goes to  000006EA
 0000168C	 F000B83B	B #118, goes to  00001706
 00001690	     9801	LDR R0 [ SP + 4 ]
 00001692	     6940	LDR R0 [ R0 + 20 ]
 00001694	     2800	CMP R0 #0
 00001696	     BF08	IT EQ
 00001698	 EC06A354	TrapEQ 4 at pos 13621
 0000169C	     9901	LDR R1 [ SP + 4 ]
 0000169E	     68C9	LDR R1 [ R1 + 12 ]
 000016A0	     6001	STR R1 [  R0 + 0 ]
 000016A2	     9801	LDR R0 [ SP + 4 ]
 000016A4	     6940	LDR R0 [ R0 + 20 ]
 000016A6	     2800	CMP R0 #0
 000016A8	     BF08	IT EQ
 000016AA	 EC06A4A4	TrapEQ 4 at pos 13642
 000016AE	     2101	MOVS R1 #1
 000016B0	     6041	STR R1 [  R0 + 4 ]
 000016B2	     9804	LDR R0 [ SP + 16 ]
 000016B4	     2800	CMP R0 #0
 000016B6	     BF08	IT EQ
 000016B8	 EC06A584	TrapEQ 4 at pos 13656
 000016BC	     9904	LDR R1 [ SP + 16 ]
 000016BE	     2900	CMP R1 #0
 000016C0	     BF08	IT EQ
 000016C2	 EC06A634	TrapEQ 4 at pos 13667
 000016C6	     6889	LDR R1 [ R1 + 8 ]
 000016C8	     1C49	ADDS R1 R1 #1
 000016CA	     6081	STR R1 [  R0 + 8 ]
 000016CC	     9804	LDR R0 [ SP + 16 ]
 000016CE	     2800	CMP R0 #0
 000016D0	     BF08	IT EQ
 000016D2	 EC06A704	TrapEQ 4 at pos 13680
 000016D6	     2101	MOVS R1 #1
 000016D8	     60C1	STR R1 [  R0 + 12 ]
 000016DA	     9804	LDR R0 [ SP + 16 ]
 000016DC	     2800	CMP R0 #0
 000016DE	     BF08	IT EQ
 000016E0	 EC06A7D4	TrapEQ 4 at pos 13693
 000016E4	     2101	MOVS R1 #1
 000016E6	     7401	STRB R1 [ R0 + 16 ]
 000016E8	     9804	LDR R0 [ SP + 16 ]
 000016EA	     2800	CMP R0 #0
 000016EC	     BF08	IT EQ
 000016EE	 EC06B1E4	TrapEQ 4 at pos 13726
 000016F2	     6880	LDR R0 [ R0 + 8 ]
 000016F4	     3840	SUBS R0 R0 #64
 000016F6	 F36F201F	BFC R0 #8 #24
 000016FA	     2800	CMP R0 #0
 000016FC	 F0408003	BNE #6, goes to  00001706
 00001700	     9804	LDR R0 [ SP + 16 ]
 00001702	 F7FFFF0A	BL #-492, goes to  0000151A
 00001706	 F000B803	B #6, goes to  00001710
 0000170A	     9805	LDR R0 [ SP + 20 ]
 0000170C	     9901	LDR R1 [ SP + 4 ]
 0000170E	     6148	STR R0 [  R1 + 20 ]
 00001710	     2000	MOVS R0 #0
 00001712	     9901	LDR R1 [ SP + 4 ]
 00001714	     6108	STR R0 [  R1 + 16 ]
 00001716	     9801	LDR R0 [ SP + 4 ]
 00001718	     6940	LDR R0 [ R0 + 20 ]
 0000171A	     2800	CMP R0 #0
 0000171C	     BF08	IT EQ
 0000171E	 EC06C304	TrapEQ 4 at pos 13872
 00001722	     9901	LDR R1 [ SP + 4 ]
 00001724	     6909	LDR R1 [ R1 + 16 ]
 00001726	 F5B16F80	CMP R1 #1024
 0000172A	     BF28	IT CS
 0000172C	 EC06C381	TrapCS 1 at pos 13880
 00001730	     1840	ADDS R0 R0 R1
 00001732	 F89D100C	LDRB R1 [ SP + 12 ]
 00001736	     7401	STRB R1 [ R0 + 16 ]
 00001738	     9801	LDR R0 [ SP + 4 ]
 0000173A	     3010	ADDS R0 R0 #16
 0000173C	     6801	LDR R1 [ R0 + 0 ]
 0000173E	     1C49	ADDS R1 R1 #1
 00001740	     6001	STR R1 [  R0 + 0 ]
 00001742	     9801	LDR R0 [ SP + 4 ]
 00001744	     6940	LDR R0 [ R0 + 20 ]
 00001746	     2800	CMP R0 #0
 00001748	     BF08	IT EQ
 0000174A	 EC06C554	TrapEQ 4 at pos 13909
 0000174E	     2101	MOVS R1 #1
 00001750	     7201	STRB R1 [ R0 + 8 ]
 00001752	 F85DEB04	LDR LR [ SP ] + 4
 00001756	     B005	ADD SP SP #20
 00001758	     4770	BX LR
 0000175A	     B081	SUB SP SP #4
 0000175C	     B41F	PUSH R0 R1 R2 R3 R4
 0000175E	     B500	PUSH LR
 00001760	     2000	MOVS R0 #0
 00001762	     9006	STR R0 [ SP + 24 ]
 00001764	     9806	LDR R0 [ SP + 24 ]
 00001766	     9905	LDR R1 [ SP + 20 ]
 00001768	     4288	CMP R0 R1
 0000176A	 F2808011	BGE #34, goes to  00001790
 0000176E	     9801	LDR R0 [ SP + 4 ]
 00001770	     9902	LDR R1 [ SP + 8 ]
 00001772	     9A06	LDR R2 [ SP + 24 ]
 00001774	     9B04	LDR R3 [ SP + 16 ]
 00001776	     429A	CMP R2 R3
 00001778	     BF28	IT CS
 0000177A	 EC06E261	TrapCS 1 at pos 14118
 0000177E	     9B03	LDR R3 [ SP + 12 ]
 00001780	     189A	ADDS R2 R3 R2
 00001782	     7812	LDRB R2 [ R2 + 0 ]
 00001784	 F7FFFF13	BL #-474, goes to  000015AE
 00001788	     9806	LDR R0 [ SP + 24 ]
 0000178A	     1C40	ADDS R0 R0 #1
 0000178C	     9006	STR R0 [ SP + 24 ]
 0000178E	     E7E9	B #-46, goes to  00001764
 00001790	 F85DEB04	LDR LR [ SP ] + 4
 00001794	     B006	ADD SP SP #24
 00001796	     4770	BX LR
 00001798	     B082	SUB SP SP #8
 0000179A	     B407	PUSH R0 R1 R2
 0000179C	     B500	PUSH LR
 0000179E	     9801	LDR R0 [ SP + 4 ]
 000017A0	     6940	LDR R0 [ R0 + 20 ]
 000017A2	     2800	CMP R0 #0
 000017A4	     BF08	IT EQ
 000017A6	 EC06F4B4	TrapEQ 4 at pos 14283
 000017AA	     9901	LDR R1 [ SP + 4 ]
 000017AC	     68C9	LDR R1 [ R1 + 12 ]
 000017AE	     6800	LDR R0 [ R0 + 0 ]
 000017B0	     4281	CMP R1 R0
 000017B2	 F0008008	BEQ #16, goes to  000017C6
 000017B6	     9801	LDR R0 [ SP + 4 ]
 000017B8	     6880	LDR R0 [ R0 + 8 ]
 000017BA	     9901	LDR R1 [ SP + 4 ]
 000017BC	     68C9	LDR R1 [ R1 + 12 ]
 000017BE	 F7FFF950	BL #-3424, goes to  00000A62
 000017C2	     9901	LDR R1 [ SP + 4 ]
 000017C4	     6148	STR R0 [  R1 + 20 ]
 000017C6	     9801	LDR R0 [ SP + 4 ]
 000017C8	     6940	LDR R0 [ R0 + 20 ]
 000017CA	     2800	CMP R0 #0
 000017CC	     BF08	IT EQ
 000017CE	 EC070124	TrapEQ 4 at pos 14354
 000017D2	     9901	LDR R1 [ SP + 4 ]
 000017D4	     6909	LDR R1 [ R1 + 16 ]
 000017D6	     6840	LDR R0 [ R0 + 4 ]
 000017D8	     4281	CMP R1 R0
 000017DA	 F2C08091	BLT #290, goes to  00001900
 000017DE	     9801	LDR R0 [ SP + 4 ]
 000017E0	     6900	LDR R0 [ R0 + 16 ]
 000017E2	 F5B06F80	CMP R0 #1024
 000017E6	 F280801C	BGE #56, goes to  00001822
 000017EA	     9801	LDR R0 [ SP + 4 ]
 000017EC	     6940	LDR R0 [ R0 + 20 ]
 000017EE	     2800	CMP R0 #0
 000017F0	     BF08	IT EQ
 000017F2	 EC070474	TrapEQ 4 at pos 14407
 000017F6	     6841	LDR R1 [ R0 + 4 ]
 000017F8	     1C49	ADDS R1 R1 #1
 000017FA	     6041	STR R1 [  R0 + 4 ]
 000017FC	     9801	LDR R0 [ SP + 4 ]
 000017FE	     6880	LDR R0 [ R0 + 8 ]
 00001800	     2800	CMP R0 #0
 00001802	     BF08	IT EQ
 00001804	 EC0705A4	TrapEQ 4 at pos 14426
 00001808	     68C1	LDR R1 [ R0 + 12 ]
 0000180A	     1C49	ADDS R1 R1 #1
 0000180C	     60C1	STR R1 [  R0 + 12 ]
 0000180E	     9801	LDR R0 [ SP + 4 ]
 00001810	     6880	LDR R0 [ R0 + 8 ]
 00001812	     2800	CMP R0 #0
 00001814	     BF08	IT EQ
 00001816	 EC070684	TrapEQ 4 at pos 14440
 0000181A	     2101	MOVS R1 #1
 0000181C	     7401	STRB R1 [ R0 + 16 ]
 0000181E	 F000B86F	B #222, goes to  00001900
 00001822	     9801	LDR R0 [ SP + 4 ]
 00001824	     6880	LDR R0 [ R0 + 8 ]
 00001826	     9004	STR R0 [ SP + 16 ]
 00001828	     9804	LDR R0 [ SP + 16 ]
 0000182A	     9901	LDR R1 [ SP + 4 ]
 0000182C	     6949	LDR R1 [ R1 + 20 ]
 0000182E	 F7FEFFCE	BL #-4196, goes to  000007CE
 00001832	     9801	LDR R0 [ SP + 4 ]
 00001834	     300C	ADDS R0 R0 #12
 00001836	     6801	LDR R1 [ R0 + 0 ]
 00001838	     1C49	ADDS R1 R1 #1
 0000183A	     6001	STR R1 [  R0 + 0 ]
 0000183C	     9801	LDR R0 [ SP + 4 ]
 0000183E	     6880	LDR R0 [ R0 + 8 ]
 00001840	     9901	LDR R1 [ SP + 4 ]
 00001842	     68C9	LDR R1 [ R1 + 12 ]
 00001844	 F7FFF8D1	BL #-3678, goes to  000009EA
 00001848	     9005	STR R0 [ SP + 20 ]
 0000184A	     9805	LDR R0 [ SP + 20 ]
 0000184C	     2800	CMP R0 #0
 0000184E	 F0408051	BNE #162, goes to  000018F4
 00001852	     9804	LDR R0 [ SP + 16 ]
 00001854	     2800	CMP R0 #0
 00001856	     BF08	IT EQ
 00001858	 EC0717E4	TrapEQ 4 at pos 14590
 0000185C	     9901	LDR R1 [ SP + 4 ]
 0000185E	     68C9	LDR R1 [ R1 + 12 ]
 00001860	     6880	LDR R0 [ R0 + 8 ]
 00001862	     4281	CMP R1 R0
 00001864	 F3008009	BGT #18, goes to  0000187A
 00001868	     9804	LDR R0 [ SP + 16 ]
 0000186A	     9901	LDR R1 [ SP + 4 ]
 0000186C	     6949	LDR R1 [ R1 + 20 ]
 0000186E	     9A01	LDR R2 [ SP + 4 ]
 00001870	     68D2	LDR R2 [ R2 + 12 ]
 00001872	 F7FEFF3A	BL #-4492, goes to  000006EA
 00001876	 F000B83B	B #118, goes to  000018F0
 0000187A	     9801	LDR R0 [ SP + 4 ]
 0000187C	     6940	LDR R0 [ R0 + 20 ]
 0000187E	     2800	CMP R0 #0
 00001880	     BF08	IT EQ
 00001882	 EC072374	TrapEQ 4 at pos 14647
 00001886	     9901	LDR R1 [ SP + 4 ]
 00001888	     68C9	LDR R1 [ R1 + 12 ]
 0000188A	     6001	STR R1 [  R0 + 0 ]
 0000188C	     9801	LDR R0 [ SP + 4 ]
 0000188E	     6940	LDR R0 [ R0 + 20 ]
 00001890	     2800	CMP R0 #0
 00001892	     BF08	IT EQ
 00001894	 EC0724C4	TrapEQ 4 at pos 14668
 00001898	     2101	MOVS R1 #1
 0000189A	     6041	STR R1 [  R0 + 4 ]
 0000189C	     9804	LDR R0 [ SP + 16 ]
 0000189E	     2800	CMP R0 #0
 000018A0	     BF08	IT EQ
 000018A2	 EC0725A4	TrapEQ 4 at pos 14682
 000018A6	     9904	LDR R1 [ SP + 16 ]
 000018A8	     2900	CMP R1 #0
 000018AA	     BF08	IT EQ
 000018AC	 EC072654	TrapEQ 4 at pos 14693
 000018B0	     6889	LDR R1 [ R1 + 8 ]
 000018B2	     1C49	ADDS R1 R1 #1
 000018B4	     6081	STR R1 [  R0 + 8 ]
 000018B6	     9804	LDR R0 [ SP + 16 ]
 000018B8	     2800	CMP R0 #0
 000018BA	     BF08	IT EQ
 000018BC	 EC072724	TrapEQ 4 at pos 14706
 000018C0	     2101	MOVS R1 #1
 000018C2	     60C1	STR R1 [  R0 + 12 ]
 000018C4	     9804	LDR R0 [ SP + 16 ]
 000018C6	     2800	CMP R0 #0
 000018C8	     BF08	IT EQ
 000018CA	 EC0727F4	TrapEQ 4 at pos 14719
 000018CE	     2101	MOVS R1 #1
 000018D0	     7401	STRB R1 [ R0 + 16 ]
 000018D2	     9804	LDR R0 [ SP + 16 ]
 000018D4	     2800	CMP R0 #0
 000018D6	     BF08	IT EQ
 000018D8	 EC073204	TrapEQ 4 at pos 14752
 000018DC	     6880	LDR R0 [ R0 + 8 ]
 000018DE	     3840	SUBS R0 R0 #64
 000018E0	 F36F201F	BFC R0 #8 #24
 000018E4	     2800	CMP R0 #0
 000018E6	 F0408003	BNE #6, goes to  000018F0
 000018EA	     9804	LDR R0 [ SP + 16 ]
 000018EC	 F7FFFE15	BL #-982, goes to  0000151A
 000018F0	 F000B803	B #6, goes to  000018FA
 000018F4	     9805	LDR R0 [ SP + 20 ]
 000018F6	     9901	LDR R1 [ SP + 4 ]
 000018F8	     6148	STR R0 [  R1 + 20 ]
 000018FA	     2000	MOVS R0 #0
 000018FC	     9901	LDR R1 [ SP + 4 ]
 000018FE	     6108	STR R0 [  R1 + 16 ]
 00001900	     9801	LDR R0 [ SP + 4 ]
 00001902	     6940	LDR R0 [ R0 + 20 ]
 00001904	     2800	CMP R0 #0
 00001906	     BF08	IT EQ
 00001908	 EC074324	TrapEQ 4 at pos 14898
 0000190C	     9901	LDR R1 [ SP + 4 ]
 0000190E	     6909	LDR R1 [ R1 + 16 ]
 00001910	 F5B16F80	CMP R1 #1024
 00001914	     BF28	IT CS
 00001916	 EC0743A1	TrapCS 1 at pos 14906
 0000191A	     1840	ADDS R0 R0 R1
 0000191C	 F89D100C	LDRB R1 [ SP + 12 ]
 00001920	     7401	STRB R1 [ R0 + 16 ]
 00001922	     9801	LDR R0 [ SP + 4 ]
 00001924	     3010	ADDS R0 R0 #16
 00001926	     6801	LDR R1 [ R0 + 0 ]
 00001928	     1C49	ADDS R1 R1 #1
 0000192A	     6001	STR R1 [  R0 + 0 ]
 0000192C	     9801	LDR R0 [ SP + 4 ]
 0000192E	     6940	LDR R0 [ R0 + 20 ]
 00001930	     2800	CMP R0 #0
 00001932	     BF08	IT EQ
 00001934	 EC0745D4	TrapEQ 4 at pos 14941
 00001938	     2101	MOVS R1 #1
 0000193A	     7201	STRB R1 [ R0 + 8 ]
 0000193C	 F85DEB04	LDR LR [ SP ] + 4
 00001940	     B005	ADD SP SP #20
 00001942	     4770	BX LR
 00001944	     B407	PUSH R0 R1 R2
 00001946	     B500	PUSH LR
 00001948	     9801	LDR R0 [ SP + 4 ]
 0000194A	     9902	LDR R1 [ SP + 8 ]
 0000194C	     9A03	LDR R2 [ SP + 12 ]
 0000194E	 F36F221F	BFC R2 #8 #24
 00001952	 F7FFFE2C	BL #-936, goes to  000015AE
 00001956	     9801	LDR R0 [ SP + 4 ]
 00001958	     9902	LDR R1 [ SP + 8 ]
 0000195A	     9A03	LDR R2 [ SP + 12 ]
 0000195C	     1212	ASRS R2 R2 #8
 0000195E	 F36F221F	BFC R2 #8 #24
 00001962	 F7FFFE24	BL #-952, goes to  000015AE
 00001966	     9801	LDR R0 [ SP + 4 ]
 00001968	     9902	LDR R1 [ SP + 8 ]
 0000196A	     9A03	LDR R2 [ SP + 12 ]
 0000196C	     1412	ASRS R2 R2 #16
 0000196E	 F36F221F	BFC R2 #8 #24
 00001972	 F7FFFE1C	BL #-968, goes to  000015AE
 00001976	     9801	LDR R0 [ SP + 4 ]
 00001978	     9902	LDR R1 [ SP + 8 ]
 0000197A	     9A03	LDR R2 [ SP + 12 ]
 0000197C	     1612	ASRS R2 R2 #24
 0000197E	 F36F221F	BFC R2 #8 #24
 00001982	 F7FFFE14	BL #-984, goes to  000015AE
 00001986	 F85DEB04	LDR LR [ SP ] + 4
 0000198A	     B003	ADD SP SP #12
 0000198C	     4770	BX LR
 0000198E	     B407	PUSH R0 R1 R2
 00001990	     B500	PUSH LR
 00001992	     9801	LDR R0 [ SP + 4 ]
 00001994	     9902	LDR R1 [ SP + 8 ]
 00001996	     9A03	LDR R2 [ SP + 12 ]
 00001998	 F7FFFFD4	BL #-88, goes to  00001944
 0000199C	 F85DEB04	LDR LR [ SP ] + 4
 000019A0	     B003	ADD SP SP #12
 000019A2	     4770	BX LR
 000019A4	     B407	PUSH R0 R1 R2
 000019A6	     B500	PUSH LR
 000019A8	     9801	LDR R0 [ SP + 4 ]
 000019AA	     9902	LDR R1 [ SP + 8 ]
 000019AC	     9A03	LDR R2 [ SP + 12 ]
 000019AE	 F7FFFFC9	BL #-110, goes to  00001944
 000019B2	 F85DEB04	LDR LR [ SP ] + 4
 000019B6	     B003	ADD SP SP #12
 000019B8	     4770	BX LR
 000019BA	     B082	SUB SP SP #8
 000019BC	     B40F	PUSH R0 R1 R2 R3
 000019BE	     B500	PUSH LR
 000019C0	     2000	MOVS R0 #0
 000019C2	     9005	STR R0 [ SP + 20 ]
 000019C4	     9805	LDR R0 [ SP + 20 ]
 000019C6	     9904	LDR R1 [ SP + 16 ]
 000019C8	     4288	CMP R0 R1
 000019CA	     BF28	IT CS
 000019CC	 EC079071	TrapCS 1 at pos 15495
 000019D0	     9903	LDR R1 [ SP + 12 ]
 000019D2	     1808	ADDS R0 R1 R0
 000019D4	     7800	LDRB R0 [ R0 + 0 ]
 000019D6	 F88D0018	STRB R0 [  SP + 24 ]
 000019DA	     9801	LDR R0 [ SP + 4 ]
 000019DC	     9902	LDR R1 [ SP + 8 ]
 000019DE	 F89D2018	LDRB R2 [ SP + 24 ]
 000019E2	 F7FFFED9	BL #-590, goes to  00001798
 000019E6	     9805	LDR R0 [ SP + 20 ]
 000019E8	     1C40	ADDS R0 R0 #1
 000019EA	     9005	STR R0 [ SP + 20 ]
 000019EC	 F89D0018	LDRB R0 [ SP + 24 ]
 000019F0	     2800	CMP R0 #0
 000019F2	     D1E7	BNE #-50, goes to  000019C4
 000019F4	 F85DEB04	LDR LR [ SP ] + 4
 000019F8	     B006	ADD SP SP #24
 000019FA	     4770	BX LR
 000019FC	     B407	PUSH R0 R1 R2
 000019FE	     B500	PUSH LR
 00001A00	     9803	LDR R0 [ SP + 12 ]
 00001A02	 F1100F40	CMN R0 #64
 00001A06	 F2C08004	BLT #8, goes to  00001A12
 00001A0A	     9803	LDR R0 [ SP + 12 ]
 00001A0C	     2840	CMP R0 #64
 00001A0E	 F2C0800C	BLT #24, goes to  00001A2A
 00001A12	     9801	LDR R0 [ SP + 4 ]
 00001A14	     9902	LDR R1 [ SP + 8 ]
 00001A16	     9A03	LDR R2 [ SP + 12 ]
 00001A18	 F36F12DF	BFC R2 #7 #25
 00001A1C	     3280	ADDS R2 R2 #128
 00001A1E	 F7FFFDC6	BL #-1140, goes to  000015AE
 00001A22	     9803	LDR R0 [ SP + 12 ]
 00001A24	     11C0	ASRS R0 R0 #7
 00001A26	     9003	STR R0 [ SP + 12 ]
 00001A28	     E7EA	B #-44, goes to  00001A00
 00001A2A	     9801	LDR R0 [ SP + 4 ]
 00001A2C	     9902	LDR R1 [ SP + 8 ]
 00001A2E	     9A03	LDR R2 [ SP + 12 ]
 00001A30	 F36F12DF	BFC R2 #7 #25
 00001A34	 F7FFFDBB	BL #-1162, goes to  000015AE
 00001A38	 F85DEB04	LDR LR [ SP ] + 4
 00001A3C	     B003	ADD SP SP #12
 00001A3E	     4770	BX LR
 00001A40	 F000B815	B #42, goes to  00001A6E
 00001A44	     B081	SUB SP SP #4
 00001A46	     B401	PUSH R0
 00001A48	     B500	PUSH LR
 00001A4A	     9801	LDR R0 [ SP + 4 ]
 00001A4C	     2800	CMP R0 #0
 00001A4E	 F0408005	BNE #10, goes to  00001A5C
 00001A52	 F05F30FF	MOVS R0 #-1
 00001A56	     9002	STR R0 [ SP + 8 ]
 00001A58	 F000B804	B #8, goes to  00001A64
 00001A5C	     9801	LDR R0 [ SP + 4 ]
 00001A5E	     1F00	SUBS R0 R0 #4
 00001A60	     6800	LDR R0 [ R0 + 0 ]
 00001A62	     9002	STR R0 [ SP + 8 ]
 00001A64	     9802	LDR R0 [ SP + 8 ]
 00001A66	 F85DEB04	LDR LR [ SP ] + 4
 00001A6A	     B002	ADD SP SP #8
 00001A6C	     4770	BX LR
 00001A6E	     B082	SUB SP SP #8
 00001A70	     B500	PUSH LR
 00001A72	 00000652	MOV R0 lower 16-bits base(0), next at  00000DCE
 00001A76	 00000000	MOVT R0 higher 16-bits var + 0
 00001A7A	     6800	LDR R0 [ R0 + 0 ]
 00001A7C	 F7FFFFE2	BL #-60, goes to  00001A44
 00001A80	     2800	CMP R0 #0
 00001A82	 F040800C	BNE #24, goes to  00001A9E
 00001A86	 0000000A	MOV R0 lower 16-bits base(0), next at  00001A72
 00001A8A	 00000000	MOVT R0 higher 16-bits var + 0
 00001A8E	     6800	LDR R0 [ R0 + 0 ]
 00001A90	     6800	LDR R0 [ R0 + 0 ]
 00001A92	 10000006	MOV R1 lower 16-bits base(0), next at  00001A86
 00001A96	 00000000	MOVT R1 higher 16-bits var + 0
 00001A9A	     6008	STR R0 [  R1 + 0 ]
 00001A9C	     E7E9	B #-46, goes to  00001A72
 00001A9E	 00000006	MOV R0 lower 16-bits base(0), next at  00001A92
 00001AA2	 00000000	MOVT R0 higher 16-bits var + 0
 00001AA6	     6800	LDR R0 [ R0 + 0 ]
 00001AA8	     9001	STR R0 [ SP + 4 ]
 00001AAA	     9801	LDR R0 [ SP + 4 ]
 00001AAC	     2800	CMP R0 #0
 00001AAE	 F0008010	BEQ #32, goes to  00001AD2
 00001AB2	     9801	LDR R0 [ SP + 4 ]
 00001AB4	     9002	STR R0 [ SP + 8 ]
 00001AB6	     9802	LDR R0 [ SP + 8 ]
 00001AB8	     6800	LDR R0 [ R0 + 0 ]
 00001ABA	     9002	STR R0 [ SP + 8 ]
 00001ABC	     9802	LDR R0 [ SP + 8 ]
 00001ABE	 F7FFFFC1	BL #-126, goes to  00001A44
 00001AC2	     2800	CMP R0 #0
 00001AC4	     D0F7	BEQ #-18, goes to  00001AB6
 00001AC6	     9801	LDR R0 [ SP + 4 ]
 00001AC8	     9902	LDR R1 [ SP + 8 ]
 00001ACA	     6001	STR R1 [  R0 + 0 ]
 00001ACC	     9802	LDR R0 [ SP + 8 ]
 00001ACE	     9001	STR R0 [ SP + 4 ]
 00001AD0	     E7EB	B #-42, goes to  00001AAA
 00001AD2	 F85DEB04	LDR LR [ SP ] + 4
 00001AD6	     B002	ADD SP SP #8
 00001AD8	     4770	BX LR
 00001ADA	     B500	PUSH LR
 00001ADC	     2000	MOVS R0 #0
 00001ADE	 10000020	MOV R1 lower 16-bits base(0), next at  00001A9E
 00001AE2	 00000000	MOVT R1 higher 16-bits var + 0
 00001AE6	     6008	STR R0 [  R1 + 0 ]
 00001AE8	 F85DEB04	LDR LR [ SP ] + 4
 00001AEC	     4770	BX LR
