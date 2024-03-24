MODULE Kernel;  (*NW/PR  11.4.86 / 27.12.95 / 4.2.2014 / CS 13/12/2023*)
  IMPORT SYSTEM, BSP;
  CONST SectorLength* = 1024; SDBlockSize = 512;
    FS_OFFSET = 80000H; (*256MB in 512-byte blocks*)
    mapsize = 10000H; (*64K sectors, 64*1024*SectorLength bytes*)
    BootReservedSize = 63488;
    VarORG0* = 0D0201000H;
    CS = 2; (*Carry set Greater than, equal, or unordered*)
    CC = 3; (* Carry clear Less than*)

    (*To improve readability*)
    SSR = BSP.RTC_BASE + BSP.RTC_SSR; TR = BSP.RTC_BASE + BSP.RTC_TR;
    DR = BSP.RTC_BASE + BSP.RTC_DR; WPR = BSP.RTC_BASE + BSP.RTC_WPR;
    ISR = BSP.RTC_BASE + BSP.RTC_ISR;
    INITF = BSP.RTC_ISR_INITF;

  TYPE Sector* = ARRAY SectorLength OF BYTE;
  
    ExceptionFrame* = POINTER TO ExceptionFrameDesc;
    ExceptionFrameDesc* = RECORD
      r0*, r1*, r2*, r3*, r12*, lr*: LONGINT;
      returnAddress*, xpsr*: LONGINT
    END;

  VAR FSoffset, allocated*, NofSectors*: INTEGER;
    heapOrg*, heapLim*: INTEGER; 
    stackOrg* ,  stackSize*, MemLim*: INTEGER;
    readErrors*, writeErrors*, unrecoverableErrors*: INTEGER;
    tick: INTEGER;

    list0, list1, list2, list3: INTEGER;  (*lists of free blocks of size n*256, 128, 64, 32 bytes*)
    sectorMap: ARRAY mapsize DIV 32 OF SET;

    OldSVCallHandler: PROCEDURE(VAR f: ExceptionFrameDesc);
    
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
    (*called by NEW via Trap 0; ptr and tag are pointers*)
    VAR p, size, lim: LONGINT;
  BEGIN SYSTEM.GET(tag, size);
    IF size = 32 THEN GetBlock32(p)
    ELSIF size = 64 THEN GetBlock64(p)
    ELSIF size = 128 THEN GetBlock128(p)
    ELSE GetBlock(p, (size+255) DIV 256 * 256)
    END ;
    IF p = 0 THEN ptr := 0
    ELSE ptr := p+8; SYSTEM.PUT(p, tag); lim := p + size; INC(p, 4); INC(allocated, size);
    (*Perform unsigned comparison*) 
      WHILE (*p < lim*) SYSTEM.CMP(p, lim, CC) DO SYSTEM.PUT(p, 0); INC(p, 4) END
    END
  END New;

(* ---------- Garbage collector ----------*)

  PROCEDURE Mark*(pref: LONGINT);
    VAR pvadr, offadr, offset, tag, p, q, r: LONGINT;
  BEGIN SYSTEM.GET(pref, pvadr); (*pointers < heapOrg considered NIL*)
    WHILE pvadr # 0 DO
      SYSTEM.GET(pvadr, p); SYSTEM.GET(p-4, offadr);
      (*WARNING heapOrg is negative, so signed comparison p >= heapOrg won't work*)
      IF (*p >= heapOrg*) SYSTEM.CMP(p, heapOrg, CS) & (offadr = 0) THEN q := p;   (*mark elements in data structure with root p*)
        REPEAT SYSTEM.GET(p-4, offadr);
          IF offadr = 0 THEN SYSTEM.GET(p-8, tag); offadr := tag + 16 ELSE INC(offadr, 4) END ;
          SYSTEM.PUT(p-4, offadr); SYSTEM.GET(offadr, offset);
          IF offset # -1 THEN (*down*)
            SYSTEM.GET(p+offset, r); SYSTEM.GET(r-4, offadr);
            IF (*r >= heapOrg*) SYSTEM.CMP(r, heapOrg, CS) & (offadr = 0) THEN SYSTEM.PUT(p+offset, q); q := p; p := r END
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
      IF (*mark > 0*) (mark # 0) & (mark # -1) THEN SYSTEM.GET(p, tag); SYSTEM.GET(tag, size); SYSTEM.PUT(p+4, 0); INC(p, size)
      ELSE (*free*) SYSTEM.GET(p, size); INC(p, size)
      END;
    UNTIL (*p >= heapLim*) SYSTEM.CMP(p, heapLim, CS)
  END Scan;

(* ---------- Disk storage management ----------*)

  PROCEDURE ReadSD(src, dst, nofblocks: INTEGER);
    VAR r: INTEGER;
  BEGIN SYSTEM.LDREG(0, src); SYSTEM.LDREG(1, dst); 
    SYSTEM.LDREG(2, nofblocks); r := SYSTEM.SVC(2);
    INC(readErrors, r)
  END ReadSD;

  PROCEDURE WriteSD(dst, src, nofblocks: INTEGER);
    VAR r, retry, t: INTEGER;
  BEGIN retry := 5;
    REPEAT SYSTEM.LDREG(0, dst); SYSTEM.LDREG(1, src);
    SYSTEM.LDREG(2, nofblocks); r := SYSTEM.SVC(3); DEC(retry); INC(writeErrors, r);
     IF (r # 0) THEN t := tick; REPEAT UNTIL tick - t >= 100 END (*wait 100ms*)
    UNTIL (r = 0) OR (retry = 0);
    INC(unrecoverableErrors, r)
  END WriteSD;

  PROCEDURE InitSecMap*;
    CONST NofReservedSectors = (BootReservedSize + SectorLength - 1) DIV SectorLength + 2;
    VAR i, r: INTEGER;
  BEGIN NofSectors := 0; i := 0;
    WHILE i < NofReservedSectors DIV 32 DO sectorMap[i] := {0 .. 31}; INC(i) END;
    r := NofReservedSectors MOD 32; IF r > 0 THEN sectorMap[i] := {0 .. r}; INC(i) END;
    WHILE i < mapsize DIV 32 DO sectorMap[i] := {}; INC(i) END
  END InitSecMap;

  PROCEDURE MarkSector*(sec29: INTEGER);
    VAR sec: INTEGER;
  BEGIN sec := sec29 DIV 29; ASSERT(sec29 = sec*29);
    INCL(sectorMap[sec DIV 32], sec MOD 32); INC(NofSectors);
  END MarkSector;

  PROCEDURE FreeSector*(sec29: INTEGER);
    VAR sec: INTEGER;
  BEGIN sec := sec29 DIV 29; ASSERT(sec29 = sec*29);
    EXCL(sectorMap[sec DIV 32], sec MOD 32); DEC(NofSectors)
  END FreeSector;

  PROCEDURE AllocSector*(hint29: INTEGER; VAR sec29: INTEGER);
    VAR hint, s: INTEGER;
  BEGIN (*find free sector, starting after hint*)
    hint := hint29 DIV 29; ASSERT(hint29 = hint*29); s := hint;
    REPEAT INC(s);
      IF s >= mapsize THEN s := 1 END ;
    UNTIL ~(s MOD 32 IN sectorMap[s DIV 32]) OR (s = hint);
    ASSERT (~(s MOD 32 IN sectorMap[s DIV 32]));
    INCL(sectorMap[s DIV 32], s MOD 32); INC(NofSectors); sec29 := s * 29
  END AllocSector;

  PROCEDURE GetSector*(src29: INTEGER; VAR dst: Sector);
    VAR src: INTEGER;
  BEGIN src := src29 DIV 29; ASSERT(src29 = src*29);
    src := src * (SectorLength DIV SDBlockSize) + FSoffset;
    ReadSD(src, SYSTEM.ADR(dst), SectorLength DIV SDBlockSize)
  END GetSector;

  PROCEDURE PutSector*(dst29: INTEGER; VAR src: Sector);
    VAR dst: INTEGER;
  BEGIN dst := dst29 DIV 29; ASSERT(dst29 = dst*29);
    dst := dst * (SectorLength DIV SDBlockSize) + FSoffset;
    WriteSD(dst, SYSTEM.ADR(src), SectorLength DIV SDBlockSize);
(*    WriteSD(dst+(mapsize*(SectorLength DIV SDBlockSize)), SYSTEM.ADR(src), SectorLength DIV SDBlockSize) (*backup*)*)
  END PutSector;

(*-------- Miscellaneous procedures----------*)

  PROCEDURE Time*(): INTEGER;
  BEGIN RETURN tick
  END Time;

  PROCEDURE Delayus*(d: INTEGER);
    VAR beg, now: INTEGER;
  BEGIN SYSTEM.GET(BSP.DWTBase + BSP.CYCCNT, beg);
    REPEAT SYSTEM.GET(BSP.DWTBase + BSP.CYCCNT, now) UNTIL now - beg >= BSP.HCLCFREQ*d
  END  Delayus;

  PROCEDURE Clock*(): INTEGER;
    VAR d,  h, newss, ss: INTEGER;
  BEGIN
      REPEAT SYSTEM.GET(SSR, ss); SYSTEM.GET(TR, h);
        SYSTEM.GET(DR, d); SYSTEM.GET(SSR, newss)
      UNTIL ss = newss;
      SYSTEM.GET(DR, newss); (*dummy date read to unlock registers*)
      RETURN (((((LSR(d, 20) MOD 16*10 + LSR(d, 16) MOD 16)*16 +
        LSR(d, 12) MOD 2*10 + LSR(d, 8) MOD 16)*32 +
          LSR(d, 4) MOD 4*10 + d MOD 16)*32 +
            LSR(h, 20) MOD 4*10 + LSR(h, 16) MOD 16)*64 +
              LSR(h, 12) MOD 8*10 + LSR(h, 8) MOD 16)*64 +
                LSR(h, 4) MOD 8*10 + h MOD 16
  END Clock;

  PROCEDURE SetClock*(dt: INTEGER);
    VAR d,  h, hr, min, sec, yr, mo, day: INTEGER;
  BEGIN yr := LSR(dt, 26); mo := LSR(dt, 22) MOD 16; day := LSR(dt, 17) MOD 32;
    d := LSL(yr DIV 10, 20) + LSL(yr MOD 10, 16) +
      LSL(mo DIV 10, 12) + LSL(mo MOD 10, 8) +
      LSL(day DIV 10, 4) + day MOD 10;

    hr := LSR(dt, 12) MOD 32; min := LSR(dt, 6) MOD 64; sec := dt MOD 64;
    h := LSL(hr DIV 10, 20) + LSL(hr MOD 10, 16) +
      LSL(min DIV 10, 12) + LSL(min MOD 10, 8) +
      LSL(sec DIV 10, 4) + sec MOD 10;

    SYSTEM.PUT(WPR, 0CAH); SYSTEM.PUT(WPR, 53H); (*disable write protection on RTC registers*)
    SYSTEM.PUT(BSP.rtcInit, TRUE); (*put RTC in init mode*)
    REPEAT UNTIL SYSTEM.BIT(ISR, INITF); (*RTC is now in init mode*)
    SYSTEM.PUT(TR, h); SYSTEM.PUT(DR, d); (*set time and date*)
    SYSTEM.PUT(BSP.rtcInit, FALSE); (*exit RTC from init mode*)
    SYSTEM.PUT(WPR, 0FFH); (*enable write protection on RTC registers*)
  END SetClock;

  PROCEDURE Install*(Padr, at: INTEGER);
  BEGIN SYSTEM.PUT(at, Padr)
  END Install;

  PROCEDURE* Trap(VAR f: ExceptionFrameDesc);
    VAR u, v, w: INTEGER;
  BEGIN 
    SYSTEM.GET(f.returnAddress, u);
    w := u DIV 10000H MOD 10H; (*trap number*)
    IF w = 0 THEN New(v, f.r1); SYSTEM.PUT(f.r0, v); INC(f.returnAddress, 4); (*move to next instruction*)
    ELSE (*stop*) BSP.led(w + 64); REPEAT UNTIL FALSE
    END
  END Trap;

  PROCEDURE^3 IncTick;
  BEGIN
    INC(tick)
  END IncTick;

  PROCEDURE* SVCallHandler(VAR f: ExceptionFrameDesc);
    VAR param: BYTE;
  BEGIN SYSTEM.GET(f.returnAddress - 2, param);
    IF param = 1 THEN BSP.led(f.r0)
    ELSE OldSVCallHandler(f) END
  END SVCallHandler;

  PROCEDURE Init*;
    VAR currentSVCHandlerAddr, r: INTEGER;
      pb2up: BOOLEAN; param: ARRAY 128 OF INTEGER;
  BEGIN BSP.Init; SYSTEM.GET(BSP.PB2In, pb2up);
    IF ~pb2up THEN FSoffset := FS_OFFSET
    ELSE (*Get and verify Oberon file system configuration*)
      SYSTEM.LDREG(0, FS_OFFSET); SYSTEM.LDREG(1, SYSTEM.ADR(param)); SYSTEM.LDREG(2, 1); r := SYSTEM.SVC(2);
      ASSERT ((param[4] = 0)  OR (param[4] = SectorLength));
      IF param[3] = 0 THEN FSoffset := FS_OFFSET ELSE FSoffset := param[3] END
    END;
    Install(SYSTEM.ADR(Trap), BSP.VecTabBase+BSP.UsageFaultExcNum*4);  (*install temporary trap*)
    Install(SYSTEM.ADR(IncTick), BSP.VecTabBase+BSP.SysTickExcNum*4);
    (*tail chain old SVC handler*)
    SYSTEM.GET(BSP.VecTabBase+BSP.SVCallExcNum*4, currentSVCHandlerAddr);
    SYSTEM.PUT(SYSTEM.ADR(OldSVCallHandler), currentSVCHandlerAddr + 14); (*Skip stack determination code*)
    Install(SYSTEM.ADR(SVCallHandler), BSP.VecTabBase+BSP.SVCallExcNum*4);
    SYSTEM.GET(VarORG0+12, MemLim); SYSTEM.GET(VarORG0+24, stackOrg);
    SYSTEM.GET(VarORG0+28, heapOrg); stackSize := 10000H; heapLim := MemLim;
    list1 := 0; list2 := 0; list3 := 0; list0 := heapOrg;
    SYSTEM.PUT(list0, heapLim - heapOrg); SYSTEM.PUT(list0+4, -1); SYSTEM.PUT(list0+8, 0);
    allocated := 0; InitSecMap
  END Init;

END Kernel.
