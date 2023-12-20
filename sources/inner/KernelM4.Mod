MODULE Kernel;  (*NW/PR  11.4.86 / 27.12.95 / 4.2.2014 / CS 13/12/2023*)
  IMPORT SYSTEM;
  CONST SectorLength* = 1024;
    FSoffset = 80000H; (*256MB in 512-byte blocks*)
    mapsize = 10000H; (*1K sectors, 64MB*)
    SRAMBase* = 20000000H; VecTabBase* = SRAMBase; UsageFaultExcNum* = 6;
    VarORG0* = 0D0201000H;
    CS = 2; (*Carry set Greater than, equal, or unordered*)

  TYPE Sector* = ARRAY SectorLength OF BYTE;
  
    ExceptionFrame* = POINTER TO ExceptionFrameContent;
    ExceptionFrameContent* = RECORD
      r0*, r1*, r2*, r3*, r12*, lr*: LONGINT;
      returnAddress*, xpsr*: LONGINT
    END;

  VAR allocated*, NofSectors*: INTEGER;
    heapOrg*, heapLim*: INTEGER; 
    stackOrg* ,  stackSize*, MemLim*: INTEGER;
    clock: INTEGER;
    list0, list1, list2, list3: INTEGER;  (*lists of free blocks of size n*256, 128, 64, 32 bytes*)
    sectorMap: ARRAY mapsize DIV 32 OF SET;
    hint: INTEGER; (*helps to reduce the allocation frequency of a sector, to reduces SD card wear*)
    
(* ---------- New: heap allocation ----------*)

  PROCEDURE GetBlock(VAR p: LONGINT; len: LONGINT);
    (*len is multiple of 256*)
    VAR q0, q1, q2, size: LONGINT; done: BOOLEAN;
  BEGIN q0 := 0; q1 := list0; done := FALSE;
    WHILE ~done & (q1 # 0) DO
      SYSTEM.GET(q1, size); SYSTEM.GET(q1+8, q2);
      IF size < len THEN (*no fit*) q0 := q1; q1 := q2
      ELSIF size = len THEN (*extract -> p*)
        done := TRUE; p := q1;
        IF q0 # 0 THEN SYSTEM.PUT(q0+8, q2) ELSE list0 := q2 END
      ELSE (*reduce size*)
        done := TRUE; p := q1; q1 := q1 + len;
        SYSTEM.PUT(q1, size-len); SYSTEM.PUT(q1+4, -1); SYSTEM.PUT(q1+8, q2);
        IF q0 # 0 THEN SYSTEM.PUT(q0+8, q1) ELSE list0 := q1 END
      END
    END ;
    IF ~done THEN p := 0 END
  END GetBlock;

  PROCEDURE GetBlock128(VAR p: LONGINT);
    VAR q: LONGINT;
  BEGIN
    IF list1 # 0 THEN p := list1; SYSTEM.GET(list1+8, list1)
    ELSE GetBlock(q, 256); SYSTEM.PUT(q+128, 128); SYSTEM.PUT(q+132, -1); SYSTEM.PUT(q+136, list1);
      list1 := q + 128; p := q
    END
  END GetBlock128;

  PROCEDURE GetBlock64(VAR p: LONGINT);
    VAR q: LONGINT;
  BEGIN
    IF list2 # 0 THEN p := list2; SYSTEM.GET(list2+8, list2)
    ELSE GetBlock128(q); SYSTEM.PUT(q+64, 64); SYSTEM.PUT(q+68, -1); SYSTEM.PUT(q+72, list2);
      list2 := q + 64; p := q
    END
  END GetBlock64;

  PROCEDURE GetBlock32(VAR p: LONGINT);
    VAR q: LONGINT;
  BEGIN
    IF list3 # 0 THEN p := list3; SYSTEM.GET(list3+8, list3)
    ELSE GetBlock64(q); SYSTEM.PUT(q+32, 32); SYSTEM.PUT(q+36, -1); SYSTEM.PUT(q+40, list3);
      list3 := q + 32; p := q
    END
  END GetBlock32;

   PROCEDURE New*(VAR ptr: LONGINT; tag: LONGINT);
    (*called by NEW via MT[0]; ptr and tag are pointers*)
    VAR p, size, lim: LONGINT;
  BEGIN SYSTEM.GET(tag, size);
    IF size = 32 THEN GetBlock32(p)
    ELSIF size = 64 THEN GetBlock64(p)
    ELSIF size = 128 THEN GetBlock128(p)
    ELSE GetBlock(p, (size+255) DIV 256 * 256)
    END ;
    IF p = 0 THEN ptr := 0
    ELSE ptr := p+8; SYSTEM.PUT(p, tag); lim := p + size; INC(p, 4); INC(allocated, size);
      WHILE p < lim DO SYSTEM.PUT(p, 0); INC(p, 4) END
    END
  END New;

(* ---------- Garbage collector ----------*)

  PROCEDURE Mark*(pref: LONGINT);
    VAR pvadr, offadr, offset, tag, p, q, r: LONGINT;
  BEGIN SYSTEM.GET(pref, pvadr); (*pointers < heapOrg considered NIL*)
    WHILE pvadr # 0 DO
      SYSTEM.GET(pvadr, p); SYSTEM.GET(p-4, offadr);
      (*WARNING heapOrg is negative, so signed comparison p >= heapOrg won't work*)
      SYSTEM.CMP(p, heapOrg);
      IF SYSTEM.COND(CS) & (offadr = 0) THEN q := p;   (*mark elements in data structure with root p*)
        REPEAT SYSTEM.GET(p-4, offadr);
          IF offadr = 0 THEN SYSTEM.GET(p-8, tag); offadr := tag + 16 ELSE INC(offadr, 4) END ;
          SYSTEM.PUT(p-4, offadr); SYSTEM.GET(offadr, offset);
          IF offset # -1 THEN (*down*)
            SYSTEM.GET(p+offset, r); SYSTEM.GET(r-4, offadr);
            IF (r >= heapOrg) & (offadr = 0) THEN SYSTEM.PUT(p+offset, q); q := p; p := r END
          ELSE (*up*) SYSTEM.GET(q-4, offadr); SYSTEM.GET(offadr, offset);
            IF p # q THEN SYSTEM.GET(q+offset, r); SYSTEM.PUT(q+offset, p); p := q; q := r END
          END
        UNTIL (p = q) & (offset = -1)
      END ;
      INC(pref, 4); SYSTEM.GET(pref, pvadr)
    END
  END Mark;

  PROCEDURE Scan*;
    VAR p, q, mark, tag, size: LONGINT;
  BEGIN p := heapOrg;
    REPEAT SYSTEM.GET(p+4, mark); q := p;
      WHILE mark = 0 DO
        SYSTEM.GET(p, tag); SYSTEM.GET(tag, size); INC(p, size); SYSTEM.GET(p+4, mark)
      END ;
      size := p - q; DEC(allocated, size);  (*size of free block*)
      IF size > 0 THEN
        IF size MOD 64 # 0 THEN
          SYSTEM.PUT(q, 32); SYSTEM.PUT(q+4, -1); SYSTEM.PUT(q+8, list3); list3 := q; INC(q, 32); DEC(size, 32)
        END ;
        IF size MOD 128 # 0 THEN
          SYSTEM.PUT(q, 64); SYSTEM.PUT(q+4, -1); SYSTEM.PUT(q+8, list2); list2 := q; INC(q, 64); DEC(size, 64)
        END ;
        IF size MOD 256 # 0 THEN
          SYSTEM.PUT(q, 128); SYSTEM.PUT(q+4, -1); SYSTEM.PUT(q+8,  list1); list1 := q; INC(q, 128); DEC(size, 128)
        END ;
        IF size > 0 THEN
          SYSTEM.PUT(q, size); SYSTEM.PUT(q+4, -1); SYSTEM.PUT(q+8, list0); list0 := q; INC(q, size)
        END
      END ;
      IF mark > 0 THEN SYSTEM.GET(p, tag); SYSTEM.GET(tag, size); SYSTEM.PUT(p+4, 0); INC(p, size)
      ELSE (*free*) SYSTEM.GET(p, size); INC(p, size)
      END
    UNTIL p >= heapLim
  END Scan;

(* ---------- Disk storage management ----------*)

  PROCEDURE ReadSD(src, dst, nofblocks: INTEGER);
    VAR r: INTEGER;
  BEGIN SYSTEM.LDREG(0, src); SYSTEM.LDREG(1, dst); 
    SYSTEM.LDREG(2, nofblocks); r := SYSTEM.SVC(2);
  END ReadSD;

  PROCEDURE WriteSD(dst, src, nofblocks: INTEGER);
    VAR r: INTEGER;
  BEGIN SYSTEM.LDREG(0, src); SYSTEM.LDREG(1, dst);
    SYSTEM.LDREG(2, nofblocks); r := SYSTEM.SVC(3);
  END WriteSD;

  PROCEDURE InitSecMap*;
    VAR i: INTEGER;
  BEGIN NofSectors := 0; sectorMap[0] := {0 .. 31}; sectorMap[1] := {0 .. 31};
    FOR i := 2 TO mapsize DIV 32 - 1 DO sectorMap[i] := {} END
  END InitSecMap;

  PROCEDURE MarkSector*(sec29: INTEGER);
    VAR sec: INTEGER;
  BEGIN sec := sec29 DIV 29; ASSERT(sec29 = sec*29);
    INCL(sectorMap[sec DIV 32], sec MOD 32); INC(NofSectors);
    IF sec > hint THEN hint := sec END
  END MarkSector;

  PROCEDURE FreeSector*(sec29: INTEGER);
    VAR sec: INTEGER;
  BEGIN sec := sec29 DIV 29; ASSERT(sec29 = sec*29);
    EXCL(sectorMap[sec DIV 32], sec MOD 32); DEC(NofSectors)
  END FreeSector;

  PROCEDURE AllocSector*(hint29: INTEGER; VAR sec29: INTEGER);
    VAR hint, s: INTEGER;
  BEGIN (*find free sector, starting after hint*)
    (*hint := hint29 DIV 29; ASSERT(hint29 = hint*29);*) s := hint;
    REPEAT INC(s);
      IF s = mapsize THEN s := 1 END ;
    UNTIL ~(s MOD 32 IN sectorMap[s DIV 32]) OR (s = hint);
    ASSERT (~(s MOD 32 IN sectorMap[s DIV 32]));
    INCL(sectorMap[s DIV 32], s MOD 32); INC(NofSectors); sec29 := s * 29;
    hint := s
  END AllocSector;

  PROCEDURE GetSector*(src29: INTEGER; VAR dst: Sector);
    VAR src: INTEGER;
  BEGIN src := src29 DIV 29; ASSERT(src29 = src*29);
    src := src * 2 + FSoffset;
    ReadSD(src, SYSTEM.ADR(dst), 2)
  END GetSector;

  PROCEDURE PutSector*(dst29: INTEGER; VAR src: Sector);
    VAR dst: INTEGER;
  BEGIN dst := dst29 DIV 29; ASSERT(dst29 = dst*29);
    dst := dst * 2 + FSoffset;
    WriteSD(dst, SYSTEM.ADR(src), 2)
  END PutSector;

(*-------- Miscellaneous procedures----------*)

  PROCEDURE Time*(): INTEGER;
  BEGIN RETURN SYSTEM.SVC(4)
  END Time;

  PROCEDURE Clock*(): INTEGER;
  BEGIN RETURN clock
  END Clock;

  PROCEDURE SetClock*(dt: INTEGER);
  BEGIN clock := dt
  END SetClock;

  PROCEDURE Install*(Padr, at: INTEGER);
  BEGIN SYSTEM.PUT(at, Padr)
  END Install;

  PROCEDURE* Trap(VAR f: ExceptionFrame);
    VAR u, v, w: INTEGER;
  BEGIN 
    SYSTEM.GET(f.returnAddress, u);
    w := u MOD 10H; (*trap number*)
    IF w = 0 THEN New(f.r0, f.r1); INC(f.returnAddress, 4); (*move to next instruction*)
    ELSE (*stop*) LED(w + 192); REPEAT UNTIL FALSE
    END
  END Trap;

  PROCEDURE Init*;
  BEGIN Install(SYSTEM.ADR(Trap), VecTabBase+UsageFaultExcNum*4);  (*install temporary trap*)
    SYSTEM.GET(VarORG0+12, MemLim); SYSTEM.GET(VarORG0+24, stackOrg);
    SYSTEM.GET(VarORG0+28, heapOrg); stackSize := 10000H; heapLim := MemLim;
    list1 := 0; list2 := 0; list3 := 0; list0 := heapOrg;
    SYSTEM.PUT(list0, heapLim - heapOrg); SYSTEM.PUT(list0+4, -1); SYSTEM.PUT(list0+8, 0);
    allocated := 0; clock := 0; hint := 32; InitSecMap
  END Init;

END Kernel.
