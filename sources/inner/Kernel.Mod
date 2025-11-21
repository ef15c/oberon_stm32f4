MODULE Kernel;  (*NW/PR  11.4.86 / 27.12.95 / 4.2.2014 / CS 13/12/2023*)
  IMPORT SYSTEM, BSP, SDCard, LongDiv;
  CONST SectorLength* = 1024; SDBlockSize = 512;
    FS_OFFSET = 80000H; (*256MB in 512-byte blocks*)
    mapsize = 10000H; (*64K sectors, 64*1024*SectorLength bytes*)
    BootReservedSize = 63488;
    CS = 2; (*Carry set Greater than, equal, or unordered*)
    CC = 3; (* Carry clear Less than*)

    (*To improve readability*)
    SSR = BSP.RTC_BASE + BSP.SSR; TR = BSP.RTC_BASE + BSP.TR;
    DR = BSP.RTC_BASE + BSP.RTC_DR; WPR = BSP.RTC_BASE + BSP.WPR;
    ISR = BSP.RTC_BASE + BSP.ISR;
    INITF = BSP.INITF;

  TYPE Sector* = ARRAY SectorLength OF BYTE;
  
    ExceptionFrame* = POINTER TO ExceptionFrameDesc;
    ExceptionFrameDesc* = RECORD
      r0*, r1*, r2*, r3*, r12*, lr*: INTEGER;
      returnAddress*, xpsr*: INTEGER
    END;

  VAR allocated*, NofSectors*: INTEGER;
    heapOrg*, heapLim*: INTEGER;
    stackOrg* ,  stackSize*, MemLim*: INTEGER;
    SPHWM*: INTEGER; bootParams*: INTEGER;
    tick: INTEGER;

    list0*, list1*, list2*, list3*: INTEGER;  (*lists of free blocks of size n*256, 128, 64, 32 bytes*)
    sectorMap: ARRAY mapsize DIV 32 OF SET;

    
(* ---------- New: heap allocation ----------*)

  PROCEDURE GetBlock(VAR p: INTEGER; len: INTEGER);
    (*len is multiple of 256*)
    VAR q0, q1, q2, size: INTEGER; done: BOOLEAN;
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

  PROCEDURE GetBlock128(VAR p: INTEGER);
    VAR q: INTEGER;
  BEGIN
    IF list1 # 0 THEN p := list1; SYSTEM.GET(list1+8, list1)
    ELSE GetBlock(q, 256); SYSTEM.PUT(q+128, 128); SYSTEM.PUT(q+132, -1); SYSTEM.PUT(q+136, list1);
      list1 := q + 128; p := q
    END
  END GetBlock128;

  PROCEDURE GetBlock64(VAR p: INTEGER);
    VAR q: INTEGER;
  BEGIN
    IF list2 # 0 THEN p := list2; SYSTEM.GET(list2+8, list2)
    ELSE GetBlock128(q); SYSTEM.PUT(q+64, 64); SYSTEM.PUT(q+68, -1); SYSTEM.PUT(q+72, list2);
      list2 := q + 64; p := q
    END
  END GetBlock64;

  PROCEDURE GetBlock32(VAR p: INTEGER);
    VAR q: INTEGER;
  BEGIN
    IF list3 # 0 THEN p := list3; SYSTEM.GET(list3+8, list3)
    ELSE GetBlock64(q); SYSTEM.PUT(q+32, 32); SYSTEM.PUT(q+36, -1); SYSTEM.PUT(q+40, list3);
      list3 := q + 32; p := q
    END
  END GetBlock32;

   PROCEDURE New(ptr: INTEGER; tag: INTEGER);
    (*called by NEW via Trap 0; ptr and tag are pointers*)
    VAR p, size, lim: INTEGER;
  BEGIN SYSTEM.GET(tag, size);
    IF size = 32 THEN GetBlock32(p)
    ELSIF size = 64 THEN GetBlock64(p)
    ELSIF size = 128 THEN GetBlock128(p)
    ELSE GetBlock(p, (size+255) DIV 256 * 256)
    END ;
    IF p = 0 THEN SYSTEM.PUT(ptr, 0)
    ELSE SYSTEM.PUT(ptr, p+8); SYSTEM.PUT(p, tag); lim := p + size; INC(p, 4); INC(allocated, size);
    (*Perform unsigned comparison*) 
      WHILE (*p < lim*) SYSTEM.CMP(p, lim, CC) DO SYSTEM.PUT(p, 0); INC(p, 4) END
    END
  END New;

(* ---------- Garbage collector ----------*)

  PROCEDURE Mark*(pref: INTEGER);
    VAR pvadr, offadr, offset, tag, p, q, r: INTEGER;
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
    VAR p, q, mark, tag, size: INTEGER; done: BOOLEAN;
  BEGIN p := heapOrg; done := FALSE;
    REPEAT SYSTEM.GET(p+4, mark); q := p;
      WHILE ~done & (mark = 0) DO
        SYSTEM.GET(p, tag); SYSTEM.GET(tag, size); INC(p, size); 
        IF SYSTEM.CMP(p, heapLim, CS) THEN done := TRUE ELSE SYSTEM.GET(p+4, mark) END
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
      IF mark = -1 THEN (*already free*) SYSTEM.GET(p, size); INC(p, size)
      ELSIF mark # 0 THEN (*in use*) SYSTEM.GET(p, tag); SYSTEM.GET(tag, size); SYSTEM.PUT(p+4, 0); INC(p, size)
      END
    UNTIL (*p >= heapLim*) SYSTEM.CMP(p, heapLim, CS)
  END Scan;

  PROCEDURE Coalesce*;
    VAR p, q, mark, tag, size: INTEGER; done: BOOLEAN;
  BEGIN p := heapOrg; list0 := 0; list1 := 0; list2 := 0; list3 := 0; (*empty free lists*) done := FALSE;
    REPEAT SYSTEM.GET(p+4, mark); q := p;
      WHILE ~done & (mark = -1) DO
        SYSTEM.GET(p, size); INC(p, size); IF SYSTEM.CMP(p, heapLim, CS) THEN done := TRUE ELSE SYSTEM.GET(p+4, mark) END
      END ;
      size := p - q;
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
      IF ~done & (mark # -1) THEN (*in use*) SYSTEM.GET(p, tag); SYSTEM.GET(tag, size); INC(p, size) END
    UNTIL SYSTEM.CMP(p, heapLim, CS)
  END Coalesce;

(* ---------- Disk storage management ----------*)

  PROCEDURE InitSecMap;
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
    src := src * (SectorLength DIV SDBlockSize) + FS_OFFSET;
    SDCard.Read(src, SYSTEM.ADR(dst), SectorLength DIV SDBlockSize)
  END GetSector;

  PROCEDURE PutSector*(dst29: INTEGER; VAR src: Sector);
    VAR dst: INTEGER;
  BEGIN dst := dst29 DIV 29; ASSERT(dst29 = dst*29);
    dst := dst * (SectorLength DIV SDBlockSize) + FS_OFFSET;
    SDCard.Write(dst, SYSTEM.ADR(src), SectorLength DIV SDBlockSize);
(*    WriteSD(dst+(mapsize*(SectorLength DIV SDBlockSize)), SYSTEM.ADR(src), SectorLength DIV SDBlockSize) (*backup*)*)
  END PutSector;

(*-------- Miscellaneous procedures----------*)

  PROCEDURE Time*(): INTEGER;
  BEGIN RETURN tick
  END Time;

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

  PROCEDURE setSPHWM*;
  BEGIN IF SYSTEM.REG(13) < SPHWM THEN SPHWM := SYSTEM.REG(13) END
  END setSPHWM;

  PROCEDURE* Trap(VAR f: ExceptionFrameDesc);
    VAR u, w: INTEGER;
  BEGIN SYSTEM.GET(f.returnAddress, u); w := u DIV 10000H MOD 10H; (*trap number*)
    (*stop*) BSP.led(w + 64); REPEAT UNTIL FALSE
  END Trap;

  PROCEDURE^3 IncTick;
  BEGIN INC(tick); setSPHWM
  END IncTick;

  PROCEDURE* SVCallHandler(VAR f: ExceptionFrameDesc);
    VAR param: BYTE;
  BEGIN SYSTEM.GET(f.returnAddress - 2, param);
    IF param = 0 THEN (*Allocate dynamic memory*) New(f.r0, f.r1)
    ELSIF param = 1 THEN BSP.led(f.r0)
    ELSIF param = 2 THEN LongDiv.DivL(SYSTEM.VAL(LongDiv.DivParam, f))
    END; setSPHWM
  END SVCallHandler;

  PROCEDURE defaultHandler; (*infinite loop*)
  BEGIN REPEAT BSP.led(127); BSP.Delayus(100000); BSP.led(0); BSP.Delayus(100000) UNTIL FALSE
  END defaultHandler;

  PROCEDURE DisableAbortHandler*;
    VAR irqNum: INTEGER;
  BEGIN
    irqNum := BSP.B1ExtiIrqNum - 16;
    SYSTEM.PUT(BSP.NVIC_ICER + irqNum DIV 32*4, {irqNum MOD 32})
  END DisableAbortHandler;

  PROCEDURE EnableAbortHandler*;
    VAR irqNum: INTEGER;
  BEGIN
    irqNum := BSP.B1ExtiIrqNum - 16;
    SYSTEM.PUT(BSP.NVIC_ISER + irqNum DIV 32*4, {irqNum MOD 32})
  END EnableAbortHandler;

  PROCEDURE Init;
    VAR i: INTEGER;
  BEGIN SYSTEM.GET(40002850H, bootParams);
    (*relocate vector table at beginning of SRAM*)
    SYSTEM.GET(08000000H, i); SYSTEM.PUT(20000000H, i); SYSTEM.GET(08000004H, i); SYSTEM.PUT(20000004H, i); 
    FOR i := 20000008H TO 200001A8H BY 4 DO SYSTEM.PUT(i, SYSTEM.ADR(defaultHandler)) END; (*initialize vectors to default trap*)
    SYSTEM.PUT(BSP.SCB_BASE + BSP.VTOR, 20000000H);

    (*create a region 1 from 000000H to 1FFFFFH not accessible for detection
        by hardware of NIL dereference and illegal procedure call*)
    SYSTEM.PUT(BSP.MPU_BASE + BSP.RNR, 1);
    SYSTEM.PUT(BSP.MPU_BASE + BSP.RASR, 20*2); (*disable region 1*)
    SYSTEM.PUT(BSP.MPU_BASE + BSP.RBAR, 0);
    SYSTEM.PUT(BSP.MPU_BASE + BSP.RASR, {BSP.XN} + BSP.AP_NO_ACCESS + BSP.TEX_LEVEL0 + {BSP.C, BSP.S} + 
      TOSET(20*2) + {BSP.RASR_ENABLE});

    SYSTEM.PUT(BSP.SCB_BASE + BSP.CPACR, (BSP.CP10m + BSP.CP11m)); (*set CP10 and CP11 full access to activate FPU*)
    BSP.InitRTC;
    Install(SYSTEM.ADR(Trap), BSP.VecTabBase+BSP.UsageFaultExcNum*4);  (*install temporary trap*)
    Install(SYSTEM.ADR(IncTick), BSP.VecTabBase+BSP.SysTickExcNum*4);
    SYSTEM.PUT(BSP.SYST_CVR, 0); SYSTEM.PUT(BSP.SYST_CSR, {BSP.CLKSOURCE, BSP.TICKINT, BSP.SYST_ENABLE});
    Install(SYSTEM.ADR(SVCallHandler), BSP.VecTabBase+BSP.SVCallExcNum*4);
    SYSTEM.GET(bootParams+12, MemLim); SYSTEM.GET(bootParams+24, stackOrg);
    SYSTEM.GET(bootParams+28, heapOrg); stackSize := 10000H; heapLim := MemLim;
    list1 := 0; list2 := 0; list3 := 0; list0 := heapOrg;
    SYSTEM.PUT(list0, heapLim - heapOrg); SYSTEM.PUT(list0+4, -1); SYSTEM.PUT(list0+8, 0);
    allocated := 0; SPHWM := LSL(1, 31) - 1; InitSecMap; BSP.InitDisplay
  END Init;

BEGIN Init
END Kernel.

OM4Tool.DecSym Kernel.sm4
OM4Tool.DecObj Kernel.m4c
