MODULE Kernel;  (*NW/PR  11.4.86 / 27.12.95 / 4.2.2014 / CS 13/12/2023*)
  IMPORT SYSTEM, BSP, SDCard;
  CONST SectorLength* = 1024; SDBlockSize = 512;
    FS_OFFSET = 80000H; (*256MB in 512-byte blocks*)
    mapsize = 10000H; (*64K sectors, 64*1024*SectorLength bytes*)
    BootReservedSize = 63488;
    VarORG0* = 0D0201000H;
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

  PROCEDURE* Trap(VAR f: ExceptionFrameDesc);
    VAR u, w: INTEGER;
  BEGIN SYSTEM.GET(f.returnAddress, u); w := u DIV 10000H MOD 10H; (*trap number*)
    (*stop*) BSP.led(w + 64); REPEAT UNTIL FALSE
  END Trap;

  PROCEDURE^3 IncTick;
  BEGIN
    INC(tick)
  END IncTick;

  PROCEDURE* SVCallHandler(VAR f: ExceptionFrameDesc);
    VAR param: BYTE;
  BEGIN SYSTEM.GET(f.returnAddress - 2, param);
    IF param = 0 THEN (*Allocate dynamic memory*) New(f.r0, f.r1)
    ELSIF param = 1 THEN BSP.led(f.r0)
    END
  END SVCallHandler;

  PROCEDURE defaultHandler; (*infinite loop*)
  BEGIN REPEAT BSP.led(128); BSP.Delayus(10000); BSP.led(0); BSP.Delayus(10000) UNTIL FALSE
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

  PROCEDURE Init*;
    VAR i: INTEGER;
  BEGIN (*relocate vector table at beginning of SRAM*)
    SYSTEM.GET(08000000H, i); SYSTEM.PUT(20000000H, i); SYSTEM.GET(08000004H, i); SYSTEM.PUT(20000004H, i); 
    FOR i := 20000008H TO 200001A8H BY 4 DO SYSTEM.PUT(i, SYSTEM.ADR(defaultHandler)) END; (*initialize vectors to default trap*)
    SYSTEM.PUT(BSP.SCB_BASE + BSP.VTOR, 20000000H);
    SYSTEM.PUT(BSP.SCB_BASE + BSP.CPACR, (BSP.CP10m + BSP.CP11m)); (*set CP10 and CP11 full access to activate FPU*)
    BSP.Init; BSP.InitRTC; SDCard.Init;
    Install(SYSTEM.ADR(Trap), BSP.VecTabBase+BSP.UsageFaultExcNum*4);  (*install temporary trap*)
    Install(SYSTEM.ADR(IncTick), BSP.VecTabBase+BSP.SysTickExcNum*4);
    SYSTEM.PUT(BSP.SYST_CVR, 0); SYSTEM.PUT(BSP.SYST_CSR, {BSP.CLKSOURCE, BSP.TICKINT, BSP.SYST_ENABLE});
    Install(SYSTEM.ADR(SVCallHandler), BSP.VecTabBase+BSP.SVCallExcNum*4);
    SYSTEM.GET(VarORG0+12, MemLim); SYSTEM.GET(VarORG0+24, stackOrg);
    SYSTEM.GET(VarORG0+28, heapOrg); stackSize := 10000H; heapLim := MemLim;
    list1 := 0; list2 := 0; list3 := 0; list0 := heapOrg;
    SYSTEM.PUT(list0, heapLim - heapOrg); SYSTEM.PUT(list0+4, -1); SYSTEM.PUT(list0+8, 0);
    allocated := 0; InitSecMap
  END Init;

END Kernel.

OM4Tool.DecObj Kernel.m4c
decode Kernel.m4c
Kernel DD3241D3   1 12812
imports:
	BSP 2088FE58
	SDCard E683A858
type descriptors
 00000040 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
data  8240
strings

code
commands:
	Scan 1144
	Coalesce 1644
	InitSecMap 2148
	DisableAbortHandler 3708
	EnableAbortHandler 3758
	Init 3808
entries
 0000109C 00000000 00000014 00000018 0000001C 00000020 00000024 00000028 0000002C 00000034 00000038 0000003C 00000040 00000356 00000478 0000066C 00000864 0000091E 00000984 000009EA 00000AD0 00000B10 00000B50 00000B62 00000C4A 00000D98 00000E7C 00000EAE 00000EE0
pointer refs

fixP =     3926
fixD =     4228
fixT =        0
entry =     4252
 00000000	 F1BD0D14	SUBS SP SP #20
 00000004	     B403	PUSH R0 R1
 00000006	     B500	PUSH LR
 00000008	     2000	MOVS R0 #0
 0000000A	     9003	STR R0 [SP + 12]
 0000000C	 00000006	MOV R0 lower 16-bits base(0)
 00000010	 00000034	MOVT R0 higher 16-bits base + 52
 00000014	     6800	LDR R0 [ R0 + 0]
 00000016	     9004	STR R0 [SP + 16]
 00000018	     2000	MOVS R0 #0
 0000001A	 F88D001C	STRB R0 [ SP + 28 ]
 0000001E	 F89D001C	LDRB R0 [ SP + 28 ]
 00000022	     2800	CMP R0 #0
 00000024	 F040805C	BNE #184, goes to  000000E0
 00000028	     9804	LDR R0 [SP + 16]
 0000002A	     2800	CMP R0 #0
 0000002C	 F0008058	BEQ #176, goes to  000000E0
 00000030	     9804	LDR R0 [SP + 16]
 00000032	     6800	LDR R0 [ R0 + 0]
 00000034	     9006	STR R0 [SP + 24]
 00000036	     9804	LDR R0 [SP + 16]
 00000038	     3008	ADDS R0 #8
 0000003A	     6800	LDR R0 [ R0 + 0]
 0000003C	     9005	STR R0 [SP + 20]
 0000003E	     9806	LDR R0 [SP + 24]
 00000040	     9902	LDR R1 [SP + 8]
 00000042	     4288	CMP R0 R1
 00000044	 F2808006	BGE #12, goes to  00000054
 00000048	     9804	LDR R0 [SP + 16]
 0000004A	     9003	STR R0 [SP + 12]
 0000004C	     9805	LDR R0 [SP + 20]
 0000004E	     9004	STR R0 [SP + 16]
 00000050	 F000B845	B #138, goes to  000000DE
 00000054	     9806	LDR R0 [SP + 24]
 00000056	     9902	LDR R1 [SP + 8]
 00000058	     4288	CMP R0 R1
 0000005A	 F0408018	BNE #48, goes to  0000008E
 0000005E	     2001	MOVS R0 #1
 00000060	 F88D001C	STRB R0 [ SP + 28 ]
 00000064	     9804	LDR R0 [SP + 16]
 00000066	     9901	LDR R1 [SP + 4]
 00000068	     6008	STR R0 [ R1 + 0]
 0000006A	     9803	LDR R0 [SP + 12]
 0000006C	     2800	CMP R0 #0
 0000006E	 F0008006	BEQ #12, goes to  0000007E
 00000072	     9803	LDR R0 [SP + 12]
 00000074	     3008	ADDS R0 #8
 00000076	     9905	LDR R1 [SP + 20]
 00000078	     6001	STR R1 [ R0 + 0]
 0000007A	 F000B806	B #12, goes to  0000008A
 0000007E	     9805	LDR R0 [SP + 20]
 00000080	 1000003A	MOV R1 lower 16-bits base(0)
 00000084	 00000034	MOVT R1 higher 16-bits base + 52
 00000088	     6008	STR R0 [ R1 + 0]
 0000008A	 F000B828	B #80, goes to  000000DE
 0000008E	     2001	MOVS R0 #1
 00000090	 F88D001C	STRB R0 [ SP + 28 ]
 00000094	     9804	LDR R0 [SP + 16]
 00000096	     9901	LDR R1 [SP + 4]
 00000098	     6008	STR R0 [ R1 + 0]
 0000009A	     9804	LDR R0 [SP + 16]
 0000009C	     9902	LDR R1 [SP + 8]
 0000009E	     1840	ADDS R0 R0 R1
 000000A0	     9004	STR R0 [SP + 16]
 000000A2	     9806	LDR R0 [SP + 24]
 000000A4	     9902	LDR R1 [SP + 8]
 000000A6	     1A40	SUBS R0 R0 R1
 000000A8	     9904	LDR R1 [SP + 16]
 000000AA	     6008	STR R0 [ R1 + 0]
 000000AC	     9804	LDR R0 [SP + 16]
 000000AE	     1D00	ADDS R0 R0 #4
 000000B0	 F05F31FF	MOVS R1 #-1
 000000B4	     6001	STR R1 [ R0 + 0]
 000000B6	     9804	LDR R0 [SP + 16]
 000000B8	     3008	ADDS R0 #8
 000000BA	     9905	LDR R1 [SP + 20]
 000000BC	     6001	STR R1 [ R0 + 0]
 000000BE	     9803	LDR R0 [SP + 12]
 000000C0	     2800	CMP R0 #0
 000000C2	 F0008006	BEQ #12, goes to  000000D2
 000000C6	     9803	LDR R0 [SP + 12]
 000000C8	     3008	ADDS R0 #8
 000000CA	     9904	LDR R1 [SP + 16]
 000000CC	     6001	STR R1 [ R0 + 0]
 000000CE	 F000B806	B #12, goes to  000000DE
 000000D2	     9804	LDR R0 [SP + 16]
 000000D4	 1000002A	MOV R1 lower 16-bits base(0)
 000000D8	 00000034	MOVT R1 higher 16-bits base + 52
 000000DC	     6008	STR R0 [ R1 + 0]
 000000DE	     E79E	B #-196, goes to  0000001E
 000000E0	 F89D001C	LDRB R0 [ SP + 28 ]
 000000E4	     2800	CMP R0 #0
 000000E6	 F0408003	BNE #6, goes to  000000F0
 000000EA	     2000	MOVS R0 #0
 000000EC	     9901	LDR R1 [SP + 4]
 000000EE	     6008	STR R0 [ R1 + 0]
 000000F0	 F85DEB04	LDR LR [ SP ] + 4
 000000F4	 F11D0D1C	ADDS SP SP #28
 000000F8	     4770	BX LR
 000000FA	 F1BD0D04	SUBS SP SP #4
 000000FE	     B401	PUSH R0
 00000100	     B500	PUSH LR
 00000102	 00000017	MOV R0 lower 16-bits base(0)
 00000106	 00000038	MOVT R0 higher 16-bits base + 56
 0000010A	     6800	LDR R0 [ R0 + 0]
 0000010C	     2800	CMP R0 #0
 0000010E	 F0008015	BEQ #42, goes to  0000013C
 00000112	 00000008	MOV R0 lower 16-bits base(0)
 00000116	 00000038	MOVT R0 higher 16-bits base + 56
 0000011A	     6800	LDR R0 [ R0 + 0]
 0000011C	     9901	LDR R1 [SP + 4]
 0000011E	     6008	STR R0 [ R1 + 0]
 00000120	 00000007	MOV R0 lower 16-bits base(0)
 00000124	 00000038	MOVT R0 higher 16-bits base + 56
 00000128	     6800	LDR R0 [ R0 + 0]
 0000012A	     3008	ADDS R0 #8
 0000012C	     6800	LDR R0 [ R0 + 0]
 0000012E	 10000007	MOV R1 lower 16-bits base(0)
 00000132	 00000038	MOVT R1 higher 16-bits base + 56
 00000136	     6008	STR R0 [ R1 + 0]
 00000138	 F000B821	B #66, goes to  0000017E
 0000013C	 F11D0008	ADDS R0 SP #8
 00000140	 F45F7180	MOVS R1 #256
 00000144	 F7FFFF5C	BL #-328, goes to  00000000
 00000148	     9802	LDR R0 [SP + 8]
 0000014A	     3080	ADDS R0 #128
 0000014C	     2180	MOVS R1 #128
 0000014E	     6001	STR R1 [ R0 + 0]
 00000150	     9802	LDR R0 [SP + 8]
 00000152	     3084	ADDS R0 #132
 00000154	 F05F31FF	MOVS R1 #-1
 00000158	     6001	STR R1 [ R0 + 0]
 0000015A	     9802	LDR R0 [SP + 8]
 0000015C	     3088	ADDS R0 #136
 0000015E	 10000018	MOV R1 lower 16-bits base(0)
 00000162	 00000038	MOVT R1 higher 16-bits base + 56
 00000166	     6809	LDR R1 [ R1 + 0]
 00000168	     6001	STR R1 [ R0 + 0]
 0000016A	     9802	LDR R0 [SP + 8]
 0000016C	     3080	ADDS R0 #128
 0000016E	 10000008	MOV R1 lower 16-bits base(0)
 00000172	 00000038	MOVT R1 higher 16-bits base + 56
 00000176	     6008	STR R0 [ R1 + 0]
 00000178	     9802	LDR R0 [SP + 8]
 0000017A	     9901	LDR R1 [SP + 4]
 0000017C	     6008	STR R0 [ R1 + 0]
 0000017E	 F85DEB04	LDR LR [ SP ] + 4
 00000182	 F11D0D08	ADDS SP SP #8
 00000186	     4770	BX LR
 00000188	 F1BD0D04	SUBS SP SP #4
 0000018C	     B401	PUSH R0
 0000018E	     B500	PUSH LR
 00000190	 00000011	MOV R0 lower 16-bits base(0)
 00000194	 0000003C	MOVT R0 higher 16-bits base + 60
 00000198	     6800	LDR R0 [ R0 + 0]
 0000019A	     2800	CMP R0 #0
 0000019C	 F0008015	BEQ #42, goes to  000001CA
 000001A0	 00000008	MOV R0 lower 16-bits base(0)
 000001A4	 0000003C	MOVT R0 higher 16-bits base + 60
 000001A8	     6800	LDR R0 [ R0 + 0]
 000001AA	     9901	LDR R1 [SP + 4]
 000001AC	     6008	STR R0 [ R1 + 0]
 000001AE	 00000007	MOV R0 lower 16-bits base(0)
 000001B2	 0000003C	MOVT R0 higher 16-bits base + 60
 000001B6	     6800	LDR R0 [ R0 + 0]
 000001B8	     3008	ADDS R0 #8
 000001BA	     6800	LDR R0 [ R0 + 0]
 000001BC	 10000007	MOV R1 lower 16-bits base(0)
 000001C0	 0000003C	MOVT R1 higher 16-bits base + 60
 000001C4	     6008	STR R0 [ R1 + 0]
 000001C6	 F000B81F	B #62, goes to  00000208
 000001CA	 F11D0008	ADDS R0 SP #8
 000001CE	 F7FFFF94	BL #-216, goes to  000000FA
 000001D2	     9802	LDR R0 [SP + 8]
 000001D4	     3040	ADDS R0 #64
 000001D6	     2140	MOVS R1 #64
 000001D8	     6001	STR R1 [ R0 + 0]
 000001DA	     9802	LDR R0 [SP + 8]
 000001DC	     3044	ADDS R0 #68
 000001DE	 F05F31FF	MOVS R1 #-1
 000001E2	     6001	STR R1 [ R0 + 0]
 000001E4	     9802	LDR R0 [SP + 8]
 000001E6	     3048	ADDS R0 #72
 000001E8	 10000016	MOV R1 lower 16-bits base(0)
 000001EC	 0000003C	MOVT R1 higher 16-bits base + 60
 000001F0	     6809	LDR R1 [ R1 + 0]
 000001F2	     6001	STR R1 [ R0 + 0]
 000001F4	     9802	LDR R0 [SP + 8]
 000001F6	     3040	ADDS R0 #64
 000001F8	 10000008	MOV R1 lower 16-bits base(0)
 000001FC	 0000003C	MOVT R1 higher 16-bits base + 60
 00000200	     6008	STR R0 [ R1 + 0]
 00000202	     9802	LDR R0 [SP + 8]
 00000204	     9901	LDR R1 [SP + 4]
 00000206	     6008	STR R0 [ R1 + 0]
 00000208	 F85DEB04	LDR LR [ SP ] + 4
 0000020C	 F11D0D08	ADDS SP SP #8
 00000210	     4770	BX LR
 00000212	 F1BD0D04	SUBS SP SP #4
 00000216	     B401	PUSH R0
 00000218	     B500	PUSH LR
 0000021A	 00000011	MOV R0 lower 16-bits base(0)
 0000021E	 00000040	MOVT R0 higher 16-bits base + 64
 00000222	     6800	LDR R0 [ R0 + 0]
 00000224	     2800	CMP R0 #0
 00000226	 F0008015	BEQ #42, goes to  00000254
 0000022A	 00000008	MOV R0 lower 16-bits base(0)
 0000022E	 00000040	MOVT R0 higher 16-bits base + 64
 00000232	     6800	LDR R0 [ R0 + 0]
 00000234	     9901	LDR R1 [SP + 4]
 00000236	     6008	STR R0 [ R1 + 0]
 00000238	 00000007	MOV R0 lower 16-bits base(0)
 0000023C	 00000040	MOVT R0 higher 16-bits base + 64
 00000240	     6800	LDR R0 [ R0 + 0]
 00000242	     3008	ADDS R0 #8
 00000244	     6800	LDR R0 [ R0 + 0]
 00000246	 10000007	MOV R1 lower 16-bits base(0)
 0000024A	 00000040	MOVT R1 higher 16-bits base + 64
 0000024E	     6008	STR R0 [ R1 + 0]
 00000250	 F000B81F	B #62, goes to  00000292
 00000254	 F11D0008	ADDS R0 SP #8
 00000258	 F7FFFF96	BL #-212, goes to  00000188
 0000025C	     9802	LDR R0 [SP + 8]
 0000025E	     3020	ADDS R0 #32
 00000260	     2120	MOVS R1 #32
 00000262	     6001	STR R1 [ R0 + 0]
 00000264	     9802	LDR R0 [SP + 8]
 00000266	     3024	ADDS R0 #36
 00000268	 F05F31FF	MOVS R1 #-1
 0000026C	     6001	STR R1 [ R0 + 0]
 0000026E	     9802	LDR R0 [SP + 8]
 00000270	     3028	ADDS R0 #40
 00000272	 10000016	MOV R1 lower 16-bits base(0)
 00000276	 00000040	MOVT R1 higher 16-bits base + 64
 0000027A	     6809	LDR R1 [ R1 + 0]
 0000027C	     6001	STR R1 [ R0 + 0]
 0000027E	     9802	LDR R0 [SP + 8]
 00000280	     3020	ADDS R0 #32
 00000282	 10000008	MOV R1 lower 16-bits base(0)
 00000286	 00000040	MOVT R1 higher 16-bits base + 64
 0000028A	     6008	STR R0 [ R1 + 0]
 0000028C	     9802	LDR R0 [SP + 8]
 0000028E	     9901	LDR R1 [SP + 4]
 00000290	     6008	STR R0 [ R1 + 0]
 00000292	 F85DEB04	LDR LR [ SP ] + 4
 00000296	 F11D0D08	ADDS SP SP #8
 0000029A	     4770	BX LR
 0000029C	 F1BD0D0C	SUBS SP SP #12
 000002A0	     B403	PUSH R0 R1
 000002A2	     B500	PUSH LR
 000002A4	     9802	LDR R0 [SP + 8]
 000002A6	     6800	LDR R0 [ R0 + 0]
 000002A8	     9004	STR R0 [SP + 16]
 000002AA	     9804	LDR R0 [SP + 16]
 000002AC	     2820	CMP R0 #32
 000002AE	 F0408006	BNE #12, goes to  000002BE
 000002B2	 F11D000C	ADDS R0 SP #12
 000002B6	 F7FFFFAC	BL #-168, goes to  00000212
 000002BA	 F000B81C	B #56, goes to  000002F6
 000002BE	     9804	LDR R0 [SP + 16]
 000002C0	     2840	CMP R0 #64
 000002C2	 F0408006	BNE #12, goes to  000002D2
 000002C6	 F11D000C	ADDS R0 SP #12
 000002CA	 F7FFFF5D	BL #-326, goes to  00000188
 000002CE	 F000B812	B #36, goes to  000002F6
 000002D2	     9804	LDR R0 [SP + 16]
 000002D4	     2880	CMP R0 #128
 000002D6	 F0408006	BNE #12, goes to  000002E6
 000002DA	 F11D000C	ADDS R0 SP #12
 000002DE	 F7FFFF0C	BL #-488, goes to  000000FA
 000002E2	 F000B808	B #16, goes to  000002F6
 000002E6	 F11D000C	ADDS R0 SP #12
 000002EA	     9904	LDR R1 [SP + 16]
 000002EC	     31FF	ADDS R1 #255
 000002EE	     1209	ASRS R1 R1 #8
 000002F0	     0209	LSLS R1 R1 #8
 000002F2	 F7FFFE85	BL #-758, goes to  00000000
 000002F6	     9803	LDR R0 [SP + 12]
 000002F8	     2800	CMP R0 #0
 000002FA	 F0408005	BNE #10, goes to  00000308
 000002FE	     9801	LDR R0 [SP + 4]
 00000300	     2100	MOVS R1 #0
 00000302	     6001	STR R1 [ R0 + 0]
 00000304	 F000B822	B #68, goes to  0000034C
 00000308	     9803	LDR R0 [SP + 12]
 0000030A	     3008	ADDS R0 #8
 0000030C	     9901	LDR R1 [SP + 4]
 0000030E	     6008	STR R0 [ R1 + 0]
 00000310	     9803	LDR R0 [SP + 12]
 00000312	     9902	LDR R1 [SP + 8]
 00000314	     6001	STR R1 [ R0 + 0]
 00000316	     9803	LDR R0 [SP + 12]
 00000318	     9904	LDR R1 [SP + 16]
 0000031A	     1840	ADDS R0 R0 R1
 0000031C	     9005	STR R0 [SP + 20]
 0000031E	     9803	LDR R0 [SP + 12]
 00000320	     1D00	ADDS R0 R0 #4
 00000322	     9003	STR R0 [SP + 12]
 00000324	 00000051	MOV R0 lower 16-bits base(0)
 00000328	 00000014	MOVT R0 higher 16-bits base + 20
 0000032C	     6801	LDR R1 [ R0 + 0]
 0000032E	     9A04	LDR R2 [SP + 16]
 00000330	     1889	ADDS R1 R1 R2
 00000332	     6001	STR R1 [ R0 + 0]
 00000334	     9803	LDR R0 [SP + 12]
 00000336	     9905	LDR R1 [SP + 20]
 00000338	     4288	CMP R0 R1
 0000033A	 F0808007	BCS #14, goes to  0000034C
 0000033E	     9803	LDR R0 [SP + 12]
 00000340	     2100	MOVS R1 #0
 00000342	     6001	STR R1 [ R0 + 0]
 00000344	     9803	LDR R0 [SP + 12]
 00000346	     1D00	ADDS R0 R0 #4
 00000348	     9003	STR R0 [SP + 12]
 0000034A	     E7F3	B #-26, goes to  00000334
 0000034C	 F85DEB04	LDR LR [ SP ] + 4
 00000350	 F11D0D14	ADDS SP SP #20
 00000354	     4770	BX LR
 00000356	 F1BD0D1C	SUBS SP SP #28
 0000035A	     B401	PUSH R0
 0000035C	     B500	PUSH LR
 0000035E	     9801	LDR R0 [SP + 4]
 00000360	     6800	LDR R0 [ R0 + 0]
 00000362	     9002	STR R0 [SP + 8]
 00000364	     9802	LDR R0 [SP + 8]
 00000366	     2800	CMP R0 #0
 00000368	 F0008081	BEQ #258, goes to  0000046E
 0000036C	     9802	LDR R0 [SP + 8]
 0000036E	     6800	LDR R0 [ R0 + 0]
 00000370	     9006	STR R0 [SP + 24]
 00000372	     9806	LDR R0 [SP + 24]
 00000374	     1F00	SUBS R0 R0 #4
 00000376	     6800	LDR R0 [ R0 + 0]
 00000378	     9003	STR R0 [SP + 12]
 0000037A	     9806	LDR R0 [SP + 24]
 0000037C	 1000002C	MOV R1 lower 16-bits base(0)
 00000380	 0000001C	MOVT R1 higher 16-bits base + 28
 00000384	     6809	LDR R1 [ R1 + 0]
 00000386	     4288	CMP R0 R1
 00000388	 F0C0806A	BCC #212, goes to  00000460
 0000038C	     9803	LDR R0 [SP + 12]
 0000038E	     2800	CMP R0 #0
 00000390	 F0408066	BNE #204, goes to  00000460
 00000394	     9806	LDR R0 [SP + 24]
 00000396	     9007	STR R0 [SP + 28]
 00000398	     9806	LDR R0 [SP + 24]
 0000039A	     1F00	SUBS R0 R0 #4
 0000039C	     6800	LDR R0 [ R0 + 0]
 0000039E	     9003	STR R0 [SP + 12]
 000003A0	     9803	LDR R0 [SP + 12]
 000003A2	     2800	CMP R0 #0
 000003A4	 F0408009	BNE #18, goes to  000003BA
 000003A8	     9806	LDR R0 [SP + 24]
 000003AA	     3808	SUBS R0 #8
 000003AC	     6800	LDR R0 [ R0 + 0]
 000003AE	     9005	STR R0 [SP + 20]
 000003B0	     9805	LDR R0 [SP + 20]
 000003B2	     3010	ADDS R0 #16
 000003B4	     9003	STR R0 [SP + 12]
 000003B6	 F000B803	B #6, goes to  000003C0
 000003BA	     9803	LDR R0 [SP + 12]
 000003BC	     1D00	ADDS R0 R0 #4
 000003BE	     9003	STR R0 [SP + 12]
 000003C0	     9806	LDR R0 [SP + 24]
 000003C2	     1F00	SUBS R0 R0 #4
 000003C4	     9903	LDR R1 [SP + 12]
 000003C6	     6001	STR R1 [ R0 + 0]
 000003C8	     9803	LDR R0 [SP + 12]
 000003CA	     6800	LDR R0 [ R0 + 0]
 000003CC	     9004	STR R0 [SP + 16]
 000003CE	     9804	LDR R0 [SP + 16]
 000003D0	 F1B03FFF	CMP R0 #-1
 000003D4	 F0008021	BEQ #66, goes to  0000041A
 000003D8	     9806	LDR R0 [SP + 24]
 000003DA	     9904	LDR R1 [SP + 16]
 000003DC	     1840	ADDS R0 R0 R1
 000003DE	     6800	LDR R0 [ R0 + 0]
 000003E0	     9008	STR R0 [SP + 32]
 000003E2	     9808	LDR R0 [SP + 32]
 000003E4	     1F00	SUBS R0 R0 #4
 000003E6	     6800	LDR R0 [ R0 + 0]
 000003E8	     9003	STR R0 [SP + 12]
 000003EA	     9808	LDR R0 [SP + 32]
 000003EC	 10000038	MOV R1 lower 16-bits base(0)
 000003F0	 0000001C	MOVT R1 higher 16-bits base + 28
 000003F4	     6809	LDR R1 [ R1 + 0]
 000003F6	     4288	CMP R0 R1
 000003F8	 F0C0800D	BCC #26, goes to  00000416
 000003FC	     9803	LDR R0 [SP + 12]
 000003FE	     2800	CMP R0 #0
 00000400	 F0408009	BNE #18, goes to  00000416
 00000404	     9806	LDR R0 [SP + 24]
 00000406	     9904	LDR R1 [SP + 16]
 00000408	     1840	ADDS R0 R0 R1
 0000040A	     9907	LDR R1 [SP + 28]
 0000040C	     6001	STR R1 [ R0 + 0]
 0000040E	     9806	LDR R0 [SP + 24]
 00000410	     9007	STR R0 [SP + 28]
 00000412	     9808	LDR R0 [SP + 32]
 00000414	     9006	STR R0 [SP + 24]
 00000416	 F000B81A	B #52, goes to  0000044E
 0000041A	     9807	LDR R0 [SP + 28]
 0000041C	     1F00	SUBS R0 R0 #4
 0000041E	     6800	LDR R0 [ R0 + 0]
 00000420	     9003	STR R0 [SP + 12]
 00000422	     9803	LDR R0 [SP + 12]
 00000424	     6800	LDR R0 [ R0 + 0]
 00000426	     9004	STR R0 [SP + 16]
 00000428	     9806	LDR R0 [SP + 24]
 0000042A	     9907	LDR R1 [SP + 28]
 0000042C	     4288	CMP R0 R1
 0000042E	 F000800E	BEQ #28, goes to  0000044E
 00000432	     9807	LDR R0 [SP + 28]
 00000434	     9904	LDR R1 [SP + 16]
 00000436	     1840	ADDS R0 R0 R1
 00000438	     6800	LDR R0 [ R0 + 0]
 0000043A	     9008	STR R0 [SP + 32]
 0000043C	     9807	LDR R0 [SP + 28]
 0000043E	     9904	LDR R1 [SP + 16]
 00000440	     1840	ADDS R0 R0 R1
 00000442	     9906	LDR R1 [SP + 24]
 00000444	     6001	STR R1 [ R0 + 0]
 00000446	     9807	LDR R0 [SP + 28]
 00000448	     9006	STR R0 [SP + 24]
 0000044A	     9808	LDR R0 [SP + 32]
 0000044C	     9007	STR R0 [SP + 28]
 0000044E	     9806	LDR R0 [SP + 24]
 00000450	     9907	LDR R1 [SP + 28]
 00000452	     4288	CMP R0 R1
 00000454	 F47FAFA0	BNE #-192, goes to  00000398
 00000458	     9804	LDR R0 [SP + 16]
 0000045A	 F1B03FFF	CMP R0 #-1
 0000045E	     D19B	BNE #-202, goes to  00000398
 00000460	     9801	LDR R0 [SP + 4]
 00000462	     1D00	ADDS R0 R0 #4
 00000464	     9001	STR R0 [SP + 4]
 00000466	     9801	LDR R0 [SP + 4]
 00000468	     6800	LDR R0 [ R0 + 0]
 0000046A	     9002	STR R0 [SP + 8]
 0000046C	     E77A	B #-268, goes to  00000364
 0000046E	 F85DEB04	LDR LR [ SP ] + 4
 00000472	 F11D0D20	ADDS SP SP #32
 00000476	     4770	BX LR
 00000478	 F1BD0D18	SUBS SP SP #24
 0000047C	     B500	PUSH LR
 0000047E	 00000049	MOV R0 lower 16-bits base(0)
 00000482	 0000001C	MOVT R0 higher 16-bits base + 28
 00000486	     6800	LDR R0 [ R0 + 0]
 00000488	     9001	STR R0 [SP + 4]
 0000048A	     2000	MOVS R0 #0
 0000048C	 F88D0018	STRB R0 [ SP + 24 ]
 00000490	     9801	LDR R0 [SP + 4]
 00000492	     1D00	ADDS R0 R0 #4
 00000494	     6800	LDR R0 [ R0 + 0]
 00000496	     9003	STR R0 [SP + 12]
 00000498	     9801	LDR R0 [SP + 4]
 0000049A	     9002	STR R0 [SP + 8]
 0000049C	 F89D0018	LDRB R0 [ SP + 24 ]
 000004A0	     2800	CMP R0 #0
 000004A2	 F0408021	BNE #66, goes to  000004E8
 000004A6	     9803	LDR R0 [SP + 12]
 000004A8	     2800	CMP R0 #0
 000004AA	 F040801D	BNE #58, goes to  000004E8
 000004AE	     9801	LDR R0 [SP + 4]
 000004B0	     6800	LDR R0 [ R0 + 0]
 000004B2	     9004	STR R0 [SP + 16]
 000004B4	     9804	LDR R0 [SP + 16]
 000004B6	     6800	LDR R0 [ R0 + 0]
 000004B8	     9005	STR R0 [SP + 20]
 000004BA	     9801	LDR R0 [SP + 4]
 000004BC	     9905	LDR R1 [SP + 20]
 000004BE	     1840	ADDS R0 R0 R1
 000004C0	     9001	STR R0 [SP + 4]
 000004C2	     9801	LDR R0 [SP + 4]
 000004C4	 10000023	MOV R1 lower 16-bits base(0)
 000004C8	 00000020	MOVT R1 higher 16-bits base + 32
 000004CC	     6809	LDR R1 [ R1 + 0]
 000004CE	     4288	CMP R0 R1
 000004D0	 F0C08005	BCC #10, goes to  000004DE
 000004D4	     2001	MOVS R0 #1
 000004D6	 F88D0018	STRB R0 [ SP + 24 ]
 000004DA	 F000B804	B #8, goes to  000004E6
 000004DE	     9801	LDR R0 [SP + 4]
 000004E0	     1D00	ADDS R0 R0 #4
 000004E2	     6800	LDR R0 [ R0 + 0]
 000004E4	     9003	STR R0 [SP + 12]
 000004E6	     E7D9	B #-78, goes to  0000049C
 000004E8	     9801	LDR R0 [SP + 4]
 000004EA	     9902	LDR R1 [SP + 8]
 000004EC	     1A40	SUBS R0 R0 R1
 000004EE	     9005	STR R0 [SP + 20]
 000004F0	 00000016	MOV R0 lower 16-bits base(0)
 000004F4	 00000014	MOVT R0 higher 16-bits base + 20
 000004F8	     6801	LDR R1 [ R0 + 0]
 000004FA	     9A05	LDR R2 [SP + 20]
 000004FC	     1A89	SUBS R1 R1 R2
 000004FE	     6001	STR R1 [ R0 + 0]
 00000500	     9805	LDR R0 [SP + 20]
 00000502	     2800	CMP R0 #0
 00000504	 F3408084	BLE #264, goes to  00000610
 00000508	     9805	LDR R0 [SP + 20]
 0000050A	 F36F109F	BFC R0 #6 #26
 0000050E	     2800	CMP R0 #0
 00000510	 F000801C	BEQ #56, goes to  0000054C
 00000514	     9802	LDR R0 [SP + 8]
 00000516	     2120	MOVS R1 #32
 00000518	     6001	STR R1 [ R0 + 0]
 0000051A	     9802	LDR R0 [SP + 8]
 0000051C	     1D00	ADDS R0 R0 #4
 0000051E	 F05F31FF	MOVS R1 #-1
 00000522	     6001	STR R1 [ R0 + 0]
 00000524	     9802	LDR R0 [SP + 8]
 00000526	     3008	ADDS R0 #8
 00000528	 1000001C	MOV R1 lower 16-bits base(0)
 0000052C	 00000040	MOVT R1 higher 16-bits base + 64
 00000530	     6809	LDR R1 [ R1 + 0]
 00000532	     6001	STR R1 [ R0 + 0]
 00000534	     9802	LDR R0 [SP + 8]
 00000536	 10000007	MOV R1 lower 16-bits base(0)
 0000053A	 00000040	MOVT R1 higher 16-bits base + 64
 0000053E	     6008	STR R0 [ R1 + 0]
 00000540	     9802	LDR R0 [SP + 8]
 00000542	     3020	ADDS R0 #32
 00000544	     9002	STR R0 [SP + 8]
 00000546	     9805	LDR R0 [SP + 20]
 00000548	     3820	SUBS R0 #32
 0000054A	     9005	STR R0 [SP + 20]
 0000054C	     9805	LDR R0 [SP + 20]
 0000054E	 F36F10DF	BFC R0 #7 #25
 00000552	     2800	CMP R0 #0
 00000554	 F000801C	BEQ #56, goes to  00000590
 00000558	     9802	LDR R0 [SP + 8]
 0000055A	     2140	MOVS R1 #64
 0000055C	     6001	STR R1 [ R0 + 0]
 0000055E	     9802	LDR R0 [SP + 8]
 00000560	     1D00	ADDS R0 R0 #4
 00000562	 F05F31FF	MOVS R1 #-1
 00000566	     6001	STR R1 [ R0 + 0]
 00000568	     9802	LDR R0 [SP + 8]
 0000056A	     3008	ADDS R0 #8
 0000056C	 1000001B	MOV R1 lower 16-bits base(0)
 00000570	 0000003C	MOVT R1 higher 16-bits base + 60
 00000574	     6809	LDR R1 [ R1 + 0]
 00000576	     6001	STR R1 [ R0 + 0]
 00000578	     9802	LDR R0 [SP + 8]
 0000057A	 10000007	MOV R1 lower 16-bits base(0)
 0000057E	 0000003C	MOVT R1 higher 16-bits base + 60
 00000582	     6008	STR R0 [ R1 + 0]
 00000584	     9802	LDR R0 [SP + 8]
 00000586	     3040	ADDS R0 #64
 00000588	     9002	STR R0 [SP + 8]
 0000058A	     9805	LDR R0 [SP + 20]
 0000058C	     3840	SUBS R0 #64
 0000058E	     9005	STR R0 [SP + 20]
 00000590	     9805	LDR R0 [SP + 20]
 00000592	 F36F201F	BFC R0 #8 #24
 00000596	     2800	CMP R0 #0
 00000598	 F000801C	BEQ #56, goes to  000005D4
 0000059C	     9802	LDR R0 [SP + 8]
 0000059E	     2180	MOVS R1 #128
 000005A0	     6001	STR R1 [ R0 + 0]
 000005A2	     9802	LDR R0 [SP + 8]
 000005A4	     1D00	ADDS R0 R0 #4
 000005A6	 F05F31FF	MOVS R1 #-1
 000005AA	     6001	STR R1 [ R0 + 0]
 000005AC	     9802	LDR R0 [SP + 8]
 000005AE	     3008	ADDS R0 #8
 000005B0	 1000001B	MOV R1 lower 16-bits base(0)
 000005B4	 00000038	MOVT R1 higher 16-bits base + 56
 000005B8	     6809	LDR R1 [ R1 + 0]
 000005BA	     6001	STR R1 [ R0 + 0]
 000005BC	     9802	LDR R0 [SP + 8]
 000005BE	 10000007	MOV R1 lower 16-bits base(0)
 000005C2	 00000038	MOVT R1 higher 16-bits base + 56
 000005C6	     6008	STR R0 [ R1 + 0]
 000005C8	     9802	LDR R0 [SP + 8]
 000005CA	     3080	ADDS R0 #128
 000005CC	     9002	STR R0 [SP + 8]
 000005CE	     9805	LDR R0 [SP + 20]
 000005D0	     3880	SUBS R0 #128
 000005D2	     9005	STR R0 [SP + 20]
 000005D4	     9805	LDR R0 [SP + 20]
 000005D6	     2800	CMP R0 #0
 000005D8	 F340801A	BLE #52, goes to  00000610
 000005DC	     9802	LDR R0 [SP + 8]
 000005DE	     9905	LDR R1 [SP + 20]
 000005E0	     6001	STR R1 [ R0 + 0]
 000005E2	     9802	LDR R0 [SP + 8]
 000005E4	     1D00	ADDS R0 R0 #4
 000005E6	 F05F31FF	MOVS R1 #-1
 000005EA	     6001	STR R1 [ R0 + 0]
 000005EC	     9802	LDR R0 [SP + 8]
 000005EE	     3008	ADDS R0 #8
 000005F0	 10000019	MOV R1 lower 16-bits base(0)
 000005F4	 00000034	MOVT R1 higher 16-bits base + 52
 000005F8	     6809	LDR R1 [ R1 + 0]
 000005FA	     6001	STR R1 [ R0 + 0]
 000005FC	     9802	LDR R0 [SP + 8]
 000005FE	 10000007	MOV R1 lower 16-bits base(0)
 00000602	 00000034	MOVT R1 higher 16-bits base + 52
 00000606	     6008	STR R0 [ R1 + 0]
 00000608	     9802	LDR R0 [SP + 8]
 0000060A	     9905	LDR R1 [SP + 20]
 0000060C	     1840	ADDS R0 R0 R1
 0000060E	     9002	STR R0 [SP + 8]
 00000610	     9803	LDR R0 [SP + 12]
 00000612	 F1B03FFF	CMP R0 #-1
 00000616	 F0408009	BNE #18, goes to  0000062C
 0000061A	     9801	LDR R0 [SP + 4]
 0000061C	     6800	LDR R0 [ R0 + 0]
 0000061E	     9005	STR R0 [SP + 20]
 00000620	     9801	LDR R0 [SP + 4]
 00000622	     9905	LDR R1 [SP + 20]
 00000624	     1840	ADDS R0 R0 R1
 00000626	     9001	STR R0 [SP + 4]
 00000628	 F000B812	B #36, goes to  00000650
 0000062C	     9803	LDR R0 [SP + 12]
 0000062E	     2800	CMP R0 #0
 00000630	 F000800E	BEQ #28, goes to  00000650
 00000634	     9801	LDR R0 [SP + 4]
 00000636	     6800	LDR R0 [ R0 + 0]
 00000638	     9004	STR R0 [SP + 16]
 0000063A	     9804	LDR R0 [SP + 16]
 0000063C	     6800	LDR R0 [ R0 + 0]
 0000063E	     9005	STR R0 [SP + 20]
 00000640	     9801	LDR R0 [SP + 4]
 00000642	     1D00	ADDS R0 R0 #4
 00000644	     2100	MOVS R1 #0
 00000646	     6001	STR R1 [ R0 + 0]
 00000648	     9801	LDR R0 [SP + 4]
 0000064A	     9905	LDR R1 [SP + 20]
 0000064C	     1840	ADDS R0 R0 R1
 0000064E	     9001	STR R0 [SP + 4]
 00000650	     9801	LDR R0 [SP + 4]
 00000652	 1000002A	MOV R1 lower 16-bits base(0)
 00000656	 00000020	MOVT R1 higher 16-bits base + 32
 0000065A	     6809	LDR R1 [ R1 + 0]
 0000065C	     4288	CMP R0 R1
 0000065E	 F4FFAF17	BCC #-466, goes to  00000490
 00000662	 F85DEB04	LDR LR [ SP ] + 4
 00000666	 F11D0D18	ADDS SP SP #24
 0000066A	     4770	BX LR
 0000066C	 F1BD0D18	SUBS SP SP #24
 00000670	     B500	PUSH LR
 00000672	 00000010	MOV R0 lower 16-bits base(0)
 00000676	 0000001C	MOVT R0 higher 16-bits base + 28
 0000067A	     6800	LDR R0 [ R0 + 0]
 0000067C	     9001	STR R0 [SP + 4]
 0000067E	     2000	MOVS R0 #0
 00000680	 10000007	MOV R1 lower 16-bits base(0)
 00000684	 00000034	MOVT R1 higher 16-bits base + 52
 00000688	     6008	STR R0 [ R1 + 0]
 0000068A	     2000	MOVS R0 #0
 0000068C	 10000006	MOV R1 lower 16-bits base(0)
 00000690	 00000038	MOVT R1 higher 16-bits base + 56
 00000694	     6008	STR R0 [ R1 + 0]
 00000696	     2000	MOVS R0 #0
 00000698	 10000006	MOV R1 lower 16-bits base(0)
 0000069C	 0000003C	MOVT R1 higher 16-bits base + 60
 000006A0	     6008	STR R0 [ R1 + 0]
 000006A2	     2000	MOVS R0 #0
 000006A4	 10000006	MOV R1 lower 16-bits base(0)
 000006A8	 00000040	MOVT R1 higher 16-bits base + 64
 000006AC	     6008	STR R0 [ R1 + 0]
 000006AE	     2000	MOVS R0 #0
 000006B0	 F88D0018	STRB R0 [ SP + 24 ]
 000006B4	     9801	LDR R0 [SP + 4]
 000006B6	     1D00	ADDS R0 R0 #4
 000006B8	     6800	LDR R0 [ R0 + 0]
 000006BA	     9003	STR R0 [SP + 12]
 000006BC	     9801	LDR R0 [SP + 4]
 000006BE	     9002	STR R0 [SP + 8]
 000006C0	 F89D0018	LDRB R0 [ SP + 24 ]
 000006C4	     2800	CMP R0 #0
 000006C6	 F040801F	BNE #62, goes to  00000708
 000006CA	     9803	LDR R0 [SP + 12]
 000006CC	 F1B03FFF	CMP R0 #-1
 000006D0	 F040801A	BNE #52, goes to  00000708
 000006D4	     9801	LDR R0 [SP + 4]
 000006D6	     6800	LDR R0 [ R0 + 0]
 000006D8	     9005	STR R0 [SP + 20]
 000006DA	     9801	LDR R0 [SP + 4]
 000006DC	     9905	LDR R1 [SP + 20]
 000006DE	     1840	ADDS R0 R0 R1
 000006E0	     9001	STR R0 [SP + 4]
 000006E2	     9801	LDR R0 [SP + 4]
 000006E4	 10000020	MOV R1 lower 16-bits base(0)
 000006E8	 00000020	MOVT R1 higher 16-bits base + 32
 000006EC	     6809	LDR R1 [ R1 + 0]
 000006EE	     4288	CMP R0 R1
 000006F0	 F0C08005	BCC #10, goes to  000006FE
 000006F4	     2001	MOVS R0 #1
 000006F6	 F88D0018	STRB R0 [ SP + 24 ]
 000006FA	 F000B804	B #8, goes to  00000706
 000006FE	     9801	LDR R0 [SP + 4]
 00000700	     1D00	ADDS R0 R0 #4
 00000702	     6800	LDR R0 [ R0 + 0]
 00000704	     9003	STR R0 [SP + 12]
 00000706	     E7DB	B #-74, goes to  000006C0
 00000708	     9801	LDR R0 [SP + 4]
 0000070A	     9902	LDR R1 [SP + 8]
 0000070C	     1A40	SUBS R0 R0 R1
 0000070E	     9005	STR R0 [SP + 20]
 00000710	     9805	LDR R0 [SP + 20]
 00000712	     2800	CMP R0 #0
 00000714	 F3408084	BLE #264, goes to  00000820
 00000718	     9805	LDR R0 [SP + 20]
 0000071A	 F36F109F	BFC R0 #6 #26
 0000071E	     2800	CMP R0 #0
 00000720	 F000801C	BEQ #56, goes to  0000075C
 00000724	     9802	LDR R0 [SP + 8]
 00000726	     2120	MOVS R1 #32
 00000728	     6001	STR R1 [ R0 + 0]
 0000072A	     9802	LDR R0 [SP + 8]
 0000072C	     1D00	ADDS R0 R0 #4
 0000072E	 F05F31FF	MOVS R1 #-1
 00000732	     6001	STR R1 [ R0 + 0]
 00000734	     9802	LDR R0 [SP + 8]
 00000736	     3008	ADDS R0 #8
 00000738	 1000002A	MOV R1 lower 16-bits base(0)
 0000073C	 00000040	MOVT R1 higher 16-bits base + 64
 00000740	     6809	LDR R1 [ R1 + 0]
 00000742	     6001	STR R1 [ R0 + 0]
 00000744	     9802	LDR R0 [SP + 8]
 00000746	 10000007	MOV R1 lower 16-bits base(0)
 0000074A	 00000040	MOVT R1 higher 16-bits base + 64
 0000074E	     6008	STR R0 [ R1 + 0]
 00000750	     9802	LDR R0 [SP + 8]
 00000752	     3020	ADDS R0 #32
 00000754	     9002	STR R0 [SP + 8]
 00000756	     9805	LDR R0 [SP + 20]
 00000758	     3820	SUBS R0 #32
 0000075A	     9005	STR R0 [SP + 20]
 0000075C	     9805	LDR R0 [SP + 20]
 0000075E	 F36F10DF	BFC R0 #7 #25
 00000762	     2800	CMP R0 #0
 00000764	 F000801C	BEQ #56, goes to  000007A0
 00000768	     9802	LDR R0 [SP + 8]
 0000076A	     2140	MOVS R1 #64
 0000076C	     6001	STR R1 [ R0 + 0]
 0000076E	     9802	LDR R0 [SP + 8]
 00000770	     1D00	ADDS R0 R0 #4
 00000772	 F05F31FF	MOVS R1 #-1
 00000776	     6001	STR R1 [ R0 + 0]
 00000778	     9802	LDR R0 [SP + 8]
 0000077A	     3008	ADDS R0 #8
 0000077C	 1000001B	MOV R1 lower 16-bits base(0)
 00000780	 0000003C	MOVT R1 higher 16-bits base + 60
 00000784	     6809	LDR R1 [ R1 + 0]
 00000786	     6001	STR R1 [ R0 + 0]
 00000788	     9802	LDR R0 [SP + 8]
 0000078A	 10000007	MOV R1 lower 16-bits base(0)
 0000078E	 0000003C	MOVT R1 higher 16-bits base + 60
 00000792	     6008	STR R0 [ R1 + 0]
 00000794	     9802	LDR R0 [SP + 8]
 00000796	     3040	ADDS R0 #64
 00000798	     9002	STR R0 [SP + 8]
 0000079A	     9805	LDR R0 [SP + 20]
 0000079C	     3840	SUBS R0 #64
 0000079E	     9005	STR R0 [SP + 20]
 000007A0	     9805	LDR R0 [SP + 20]
 000007A2	 F36F201F	BFC R0 #8 #24
 000007A6	     2800	CMP R0 #0
 000007A8	 F000801C	BEQ #56, goes to  000007E4
 000007AC	     9802	LDR R0 [SP + 8]
 000007AE	     2180	MOVS R1 #128
 000007B0	     6001	STR R1 [ R0 + 0]
 000007B2	     9802	LDR R0 [SP + 8]
 000007B4	     1D00	ADDS R0 R0 #4
 000007B6	 F05F31FF	MOVS R1 #-1
 000007BA	     6001	STR R1 [ R0 + 0]
 000007BC	     9802	LDR R0 [SP + 8]
 000007BE	     3008	ADDS R0 #8
 000007C0	 1000001B	MOV R1 lower 16-bits base(0)
 000007C4	 00000038	MOVT R1 higher 16-bits base + 56
 000007C8	     6809	LDR R1 [ R1 + 0]
 000007CA	     6001	STR R1 [ R0 + 0]
 000007CC	     9802	LDR R0 [SP + 8]
 000007CE	 10000007	MOV R1 lower 16-bits base(0)
 000007D2	 00000038	MOVT R1 higher 16-bits base + 56
 000007D6	     6008	STR R0 [ R1 + 0]
 000007D8	     9802	LDR R0 [SP + 8]
 000007DA	     3080	ADDS R0 #128
 000007DC	     9002	STR R0 [SP + 8]
 000007DE	     9805	LDR R0 [SP + 20]
 000007E0	     3880	SUBS R0 #128
 000007E2	     9005	STR R0 [SP + 20]
 000007E4	     9805	LDR R0 [SP + 20]
 000007E6	     2800	CMP R0 #0
 000007E8	 F340801A	BLE #52, goes to  00000820
 000007EC	     9802	LDR R0 [SP + 8]
 000007EE	     9905	LDR R1 [SP + 20]
 000007F0	     6001	STR R1 [ R0 + 0]
 000007F2	     9802	LDR R0 [SP + 8]
 000007F4	     1D00	ADDS R0 R0 #4
 000007F6	 F05F31FF	MOVS R1 #-1
 000007FA	     6001	STR R1 [ R0 + 0]
 000007FC	     9802	LDR R0 [SP + 8]
 000007FE	     3008	ADDS R0 #8
 00000800	 10000019	MOV R1 lower 16-bits base(0)
 00000804	 00000034	MOVT R1 higher 16-bits base + 52
 00000808	     6809	LDR R1 [ R1 + 0]
 0000080A	     6001	STR R1 [ R0 + 0]
 0000080C	     9802	LDR R0 [SP + 8]
 0000080E	 10000007	MOV R1 lower 16-bits base(0)
 00000812	 00000034	MOVT R1 higher 16-bits base + 52
 00000816	     6008	STR R0 [ R1 + 0]
 00000818	     9802	LDR R0 [SP + 8]
 0000081A	     9905	LDR R1 [SP + 20]
 0000081C	     1840	ADDS R0 R0 R1
 0000081E	     9002	STR R0 [SP + 8]
 00000820	 F89D0018	LDRB R0 [ SP + 24 ]
 00000824	     2800	CMP R0 #0
 00000826	 F040800F	BNE #30, goes to  00000848
 0000082A	     9803	LDR R0 [SP + 12]
 0000082C	 F1B03FFF	CMP R0 #-1
 00000830	 F000800A	BEQ #20, goes to  00000848
 00000834	     9801	LDR R0 [SP + 4]
 00000836	     6800	LDR R0 [ R0 + 0]
 00000838	     9004	STR R0 [SP + 16]
 0000083A	     9804	LDR R0 [SP + 16]
 0000083C	     6800	LDR R0 [ R0 + 0]
 0000083E	     9005	STR R0 [SP + 20]
 00000840	     9801	LDR R0 [SP + 4]
 00000842	     9905	LDR R1 [SP + 20]
 00000844	     1840	ADDS R0 R0 R1
 00000846	     9001	STR R0 [SP + 4]
 00000848	     9801	LDR R0 [SP + 4]
 0000084A	 1000001E	MOV R1 lower 16-bits base(0)
 0000084E	 00000020	MOVT R1 higher 16-bits base + 32
 00000852	     6809	LDR R1 [ R1 + 0]
 00000854	     4288	CMP R0 R1
 00000856	 F4FFAF2D	BCC #-422, goes to  000006B4
 0000085A	 F85DEB04	LDR LR [ SP ] + 4
 0000085E	 F11D0D18	ADDS SP SP #24
 00000862	     4770	BX LR
 00000864	 F1BD0D08	SUBS SP SP #8
 00000868	     B500	PUSH LR
 0000086A	     2000	MOVS R0 #0
 0000086C	 10000011	MOV R1 lower 16-bits base(0)
 00000870	 00000018	MOVT R1 higher 16-bits base + 24
 00000874	     6008	STR R0 [ R1 + 0]
 00000876	     2000	MOVS R0 #0
 00000878	     9001	STR R0 [SP + 4]
 0000087A	     9801	LDR R0 [SP + 4]
 0000087C	     2802	CMP R0 #2
 0000087E	 F2808013	BGE #38, goes to  000008A8
 00000882	     9801	LDR R0 [SP + 4]
 00000884	 F5B06F00	CMP R0 #2048
 00000888	     BF28	IT CS
 0000088A	 EC03C751	TrapCS 1 at pos 7797
 0000088E	 10000011	MOV R1 lower 16-bits base(0)
 00000892	 00000044	MOVT R1 higher 16-bits base + 68
 00000896	 EB110080	ADDS R0 R1 R0 LSL #2
 0000089A	 F05F31FF	MOVS R1 #-1
 0000089E	     6001	STR R1 [ R0 + 0]
 000008A0	     9801	LDR R0 [SP + 4]
 000008A2	     1C40	ADDS R0 R0 #1
 000008A4	     9001	STR R0 [SP + 4]
 000008A6	     E7E8	B #-48, goes to  0000087A
 000008A8	     2000	MOVS R0 #0
 000008AA	     9002	STR R0 [SP + 8]
 000008AC	     9802	LDR R0 [SP + 8]
 000008AE	     2800	CMP R0 #0
 000008B0	 F3408019	BLE #50, goes to  000008E6
 000008B4	     9801	LDR R0 [SP + 4]
 000008B6	 F5B06F00	CMP R0 #2048
 000008BA	     BF28	IT CS
 000008BC	 EC03D4F1	TrapCS 1 at pos 7887
 000008C0	 10000019	MOV R1 lower 16-bits base(0)
 000008C4	 00000044	MOVT R1 higher 16-bits base + 68
 000008C8	 EB110080	ADDS R0 R1 R0 LSL #2
 000008CC	     9902	LDR R1 [SP + 8]
 000008CE	 F07F0201	MVNS R2 #1
 000008D2	 FA12F101	LSLS R1 R2 R1
 000008D6	 F09131FF	EORS R1 R1 #-1
 000008DA	 F01131FF	ANDS R1 R1 #-1
 000008DE	     6001	STR R1 [ R0 + 0]
 000008E0	     9801	LDR R0 [SP + 4]
 000008E2	     1C40	ADDS R0 R0 #1
 000008E4	     9001	STR R0 [SP + 4]
 000008E6	     9801	LDR R0 [SP + 4]
 000008E8	 F5B06F00	CMP R0 #2048
 000008EC	 F2808012	BGE #36, goes to  00000914
 000008F0	     9801	LDR R0 [SP + 4]
 000008F2	 F5B06F00	CMP R0 #2048
 000008F6	     BF28	IT CS
 000008F8	 EC03E161	TrapCS 1 at pos 7958
 000008FC	 1000001E	MOV R1 lower 16-bits base(0)
 00000900	 00000044	MOVT R1 higher 16-bits base + 68
 00000904	 EB110080	ADDS R0 R1 R0 LSL #2
 00000908	     2100	MOVS R1 #0
 0000090A	     6001	STR R1 [ R0 + 0]
 0000090C	     9801	LDR R0 [SP + 4]
 0000090E	     1C40	ADDS R0 R0 #1
 00000910	     9001	STR R0 [SP + 4]
 00000912	     E7E8	B #-48, goes to  000008E6
 00000914	 F85DEB04	LDR LR [ SP ] + 4
 00000918	 F11D0D08	ADDS SP SP #8
 0000091C	     4770	BX LR
 0000091E	 F1BD0D04	SUBS SP SP #4
 00000922	     B401	PUSH R0
 00000924	     B500	PUSH LR
 00000926	     9801	LDR R0 [SP + 4]
 00000928	     211D	MOVS R1 #29
 0000092A	 FBB0F0F1	UDIV R0 R0 R1
 0000092E	     9002	STR R0 [SP + 8]
 00000930	     9802	LDR R0 [SP + 8]
 00000932	     211D	MOVS R1 #29
 00000934	     4348	MULS R0 R1 R0
 00000936	     9901	LDR R1 [SP + 4]
 00000938	     4281	CMP R1 R0
 0000093A	     BF18	IT NE
 0000093C	 EC03F347	TrapNE 7 at pos 8116
 00000940	     9802	LDR R0 [SP + 8]
 00000942	     1140	ASRS R0 R0 #5
 00000944	 F5B06F00	CMP R0 #2048
 00000948	     BF28	IT CS
 0000094A	 EC03F541	TrapCS 1 at pos 8148
 0000094E	 10000029	MOV R1 lower 16-bits base(0)
 00000952	 00000044	MOVT R1 higher 16-bits base + 68
 00000956	 EB110080	ADDS R0 R1 R0 LSL #2
 0000095A	     9902	LDR R1 [SP + 8]
 0000095C	 F36F115F	BFC R1 #5 #27
 00000960	     6802	LDR R2 [ R0 + 0]
 00000962	     2301	MOVS R3 #1
 00000964	 FA13F101	LSLS R1 R3 R1
 00000968	     430A	ORRS R2 R1
 0000096A	     6002	STR R2 [ R0 + 0]
 0000096C	 0000000F	MOV R0 lower 16-bits base(0)
 00000970	 00000018	MOVT R0 higher 16-bits base + 24
 00000974	     6801	LDR R1 [ R0 + 0]
 00000976	     1C49	ADDS R1 R1 #1
 00000978	     6001	STR R1 [ R0 + 0]
 0000097A	 F85DEB04	LDR LR [ SP ] + 4
 0000097E	 F11D0D08	ADDS SP SP #8
 00000982	     4770	BX LR
 00000984	 F1BD0D04	SUBS SP SP #4
 00000988	     B401	PUSH R0
 0000098A	     B500	PUSH LR
 0000098C	     9801	LDR R0 [SP + 4]
 0000098E	     211D	MOVS R1 #29
 00000990	 FBB0F0F1	UDIV R0 R0 R1
 00000994	     9002	STR R0 [SP + 8]
 00000996	     9802	LDR R0 [SP + 8]
 00000998	     211D	MOVS R1 #29
 0000099A	     4348	MULS R0 R1 R0
 0000099C	     9901	LDR R1 [SP + 4]
 0000099E	     4281	CMP R1 R0
 000009A0	     BF18	IT NE
 000009A2	 EC0407F7	TrapNE 7 at pos 8319
 000009A6	     9802	LDR R0 [SP + 8]
 000009A8	     1140	ASRS R0 R0 #5
 000009AA	 F5B06F00	CMP R0 #2048
 000009AE	     BF28	IT CS
 000009B0	 EC0411F1	TrapCS 1 at pos 8351
 000009B4	 10000024	MOV R1 lower 16-bits base(0)
 000009B8	 00000044	MOVT R1 higher 16-bits base + 68
 000009BC	 EB110080	ADDS R0 R1 R0 LSL #2
 000009C0	     9902	LDR R1 [SP + 8]
 000009C2	 F36F115F	BFC R1 #5 #27
 000009C6	     6802	LDR R2 [ R0 + 0]
 000009C8	     2301	MOVS R3 #1
 000009CA	 FA13F101	LSLS R1 R3 R1
 000009CE	     438A	BICS R2 R1
 000009D0	     6002	STR R2 [ R0 + 0]
 000009D2	 0000000F	MOV R0 lower 16-bits base(0)
 000009D6	 00000018	MOVT R0 higher 16-bits base + 24
 000009DA	     6801	LDR R1 [ R0 + 0]
 000009DC	     1E49	SUBS R1 R1 #1
 000009DE	     6001	STR R1 [ R0 + 0]
 000009E0	 F85DEB04	LDR LR [ SP ] + 4
 000009E4	 F11D0D08	ADDS SP SP #8
 000009E8	     4770	BX LR
 000009EA	 F1BD0D08	SUBS SP SP #8
 000009EE	     B403	PUSH R0 R1
 000009F0	     B500	PUSH LR
 000009F2	     9801	LDR R0 [SP + 4]
 000009F4	     211D	MOVS R1 #29
 000009F6	 FBB0F0F1	UDIV R0 R0 R1
 000009FA	     9003	STR R0 [SP + 12]
 000009FC	     9803	LDR R0 [SP + 12]
 000009FE	     211D	MOVS R1 #29
 00000A00	     4348	MULS R0 R1 R0
 00000A02	     9901	LDR R1 [SP + 4]
 00000A04	     4281	CMP R1 R0
 00000A06	     BF18	IT NE
 00000A08	 EC043167	TrapNE 7 at pos 8598
 00000A0C	     9803	LDR R0 [SP + 12]
 00000A0E	     9004	STR R0 [SP + 16]
 00000A10	     9804	LDR R0 [SP + 16]
 00000A12	     1C40	ADDS R0 R0 #1
 00000A14	     9004	STR R0 [SP + 16]
 00000A16	     9804	LDR R0 [SP + 16]
 00000A18	 F5B03F80	CMP R0 #65536
 00000A1C	 F2C08002	BLT #4, goes to  00000A24
 00000A20	     2001	MOVS R0 #1
 00000A22	     9004	STR R0 [SP + 16]
 00000A24	     9804	LDR R0 [SP + 16]
 00000A26	 F36F105F	BFC R0 #5 #27
 00000A2A	     9904	LDR R1 [SP + 16]
 00000A2C	     1149	ASRS R1 R1 #5
 00000A2E	 F5B16F00	CMP R1 #2048
 00000A32	     BF28	IT CS
 00000A34	 EC0440B1	TrapCS 1 at pos 8715
 00000A38	 20000033	MOV R2 lower 16-bits base(0)
 00000A3C	 00000044	MOVT R2 higher 16-bits base + 68
 00000A40	 EB120181	ADDS R1 R2 R1 LSL #2
 00000A44	     6809	LDR R1 [ R1 + 0]
 00000A46	     1C40	ADDS R0 R0 #1
 00000A48	     41C1	RORS R1 R0
 00000A4A	 F1408004	BPL #8, goes to  00000A56
 00000A4E	     9804	LDR R0 [SP + 16]
 00000A50	     9903	LDR R1 [SP + 12]
 00000A52	     4288	CMP R0 R1
 00000A54	     D1DC	BNE #-72, goes to  00000A10
 00000A56	     9804	LDR R0 [SP + 16]
 00000A58	 F36F105F	BFC R0 #5 #27
 00000A5C	     9904	LDR R1 [SP + 16]
 00000A5E	     1149	ASRS R1 R1 #5
 00000A60	 F5B16F00	CMP R1 #2048
 00000A64	     BF28	IT CS
 00000A66	 EC0444A1	TrapCS 1 at pos 8778
 00000A6A	 20000019	MOV R2 lower 16-bits base(0)
 00000A6E	 00000044	MOVT R2 higher 16-bits base + 68
 00000A72	 EB120181	ADDS R1 R2 R1 LSL #2
 00000A76	     6809	LDR R1 [ R1 + 0]
 00000A78	     1C40	ADDS R0 R0 #1
 00000A7A	     41C1	RORS R1 R0
 00000A7C	     BF48	IT MI
 00000A7E	 EC0444D7	TrapMI 7 at pos 8781
 00000A82	     9804	LDR R0 [SP + 16]
 00000A84	     1140	ASRS R0 R0 #5
 00000A86	 F5B06F00	CMP R0 #2048
 00000A8A	     BF28	IT CS
 00000A8C	 EC0446B1	TrapCS 1 at pos 8811
 00000A90	 10000013	MOV R1 lower 16-bits base(0)
 00000A94	 00000044	MOVT R1 higher 16-bits base + 68
 00000A98	 EB110080	ADDS R0 R1 R0 LSL #2
 00000A9C	     9904	LDR R1 [SP + 16]
 00000A9E	 F36F115F	BFC R1 #5 #27
 00000AA2	     6802	LDR R2 [ R0 + 0]
 00000AA4	     2301	MOVS R3 #1
 00000AA6	 FA13F101	LSLS R1 R3 R1
 00000AAA	     430A	ORRS R2 R1
 00000AAC	     6002	STR R2 [ R0 + 0]
 00000AAE	 0000000F	MOV R0 lower 16-bits base(0)
 00000AB2	 00000018	MOVT R0 higher 16-bits base + 24
 00000AB6	     6801	LDR R1 [ R0 + 0]
 00000AB8	     1C49	ADDS R1 R1 #1
 00000ABA	     6001	STR R1 [ R0 + 0]
 00000ABC	     9804	LDR R0 [SP + 16]
 00000ABE	     211D	MOVS R1 #29
 00000AC0	     4348	MULS R0 R1 R0
 00000AC2	     9902	LDR R1 [SP + 8]
 00000AC4	     6008	STR R0 [ R1 + 0]
 00000AC6	 F85DEB04	LDR LR [ SP ] + 4
 00000ACA	 F11D0D10	ADDS SP SP #16
 00000ACE	     4770	BX LR
 00000AD0	 F1BD0D04	SUBS SP SP #4
 00000AD4	     B403	PUSH R0 R1
 00000AD6	     B500	PUSH LR
 00000AD8	     9801	LDR R0 [SP + 4]
 00000ADA	     211D	MOVS R1 #29
 00000ADC	 FBB0F0F1	UDIV R0 R0 R1
 00000AE0	     9003	STR R0 [SP + 12]
 00000AE2	     9803	LDR R0 [SP + 12]
 00000AE4	     211D	MOVS R1 #29
 00000AE6	     4348	MULS R0 R1 R0
 00000AE8	     9901	LDR R1 [SP + 4]
 00000AEA	     4281	CMP R1 R0
 00000AEC	     BF18	IT NE
 00000AEE	 EC046357	TrapNE 7 at pos 9013
 00000AF2	     9803	LDR R0 [SP + 12]
 00000AF4	     0040	LSLS R0 R0 #1
 00000AF6	 F5102000	ADDS R0 R0 #524288
 00000AFA	     9003	STR R0 [SP + 12]
 00000AFC	     9803	LDR R0 [SP + 12]
 00000AFE	     9902	LDR R1 [SP + 8]
 00000B00	     2202	MOVS R2 #2
 00000B02	 20400581	BL Mod(  2) proc(4)
 00000B06	 F85DEB04	LDR LR [ SP ] + 4
 00000B0A	 F11D0D0C	ADDS SP SP #12
 00000B0E	     4770	BX LR
 00000B10	 F1BD0D04	SUBS SP SP #4
 00000B14	     B403	PUSH R0 R1
 00000B16	     B500	PUSH LR
 00000B18	     9801	LDR R0 [SP + 4]
 00000B1A	     211D	MOVS R1 #29
 00000B1C	 FBB0F0F1	UDIV R0 R0 R1
 00000B20	     9003	STR R0 [SP + 12]
 00000B22	     9803	LDR R0 [SP + 12]
 00000B24	     211D	MOVS R1 #29
 00000B26	     4348	MULS R0 R1 R0
 00000B28	     9901	LDR R1 [SP + 4]
 00000B2A	     4281	CMP R1 R0
 00000B2C	     BF18	IT NE
 00000B2E	 EC048537	TrapNE 7 at pos 9299
 00000B32	     9803	LDR R0 [SP + 12]
 00000B34	     0040	LSLS R0 R0 #1
 00000B36	 F5102000	ADDS R0 R0 #524288
 00000B3A	     9003	STR R0 [SP + 12]
 00000B3C	     9803	LDR R0 [SP + 12]
 00000B3E	     9902	LDR R1 [SP + 8]
 00000B40	     2202	MOVS R2 #2
 00000B42	 20500020	BL Mod(  2) proc(5)
 00000B46	 F85DEB04	LDR LR [ SP ] + 4
 00000B4A	 F11D0D0C	ADDS SP SP #12
 00000B4E	     4770	BX LR
 00000B50	     B500	PUSH LR
 00000B52	 00000052	MOV R0 lower 16-bits base(0)
 00000B56	 00000030	MOVT R0 higher 16-bits base + 48
 00000B5A	     6800	LDR R0 [ R0 + 0]
 00000B5C	 F85DEB04	LDR LR [ SP ] + 4
 00000B60	     4770	BX LR
 00000B62	 F1BD0D10	SUBS SP SP #16
 00000B66	     B500	PUSH LR
 00000B68	 F6420028	MOV R0 #10280
 00000B6C	 F2C40000	MOVT R0 #16384
 00000B70	     6800	LDR R0 [ R0 + 0]
 00000B72	     9004	STR R0 [SP + 16]
 00000B74	 F6420000	MOV R0 #10240
 00000B78	 F2C40000	MOVT R0 #16384
 00000B7C	     6800	LDR R0 [ R0 + 0]
 00000B7E	     9002	STR R0 [SP + 8]
 00000B80	 F6420004	MOV R0 #10244
 00000B84	 F2C40000	MOVT R0 #16384
 00000B88	     6800	LDR R0 [ R0 + 0]
 00000B8A	     9001	STR R0 [SP + 4]
 00000B8C	 F6420028	MOV R0 #10280
 00000B90	 F2C40000	MOVT R0 #16384
 00000B94	     6800	LDR R0 [ R0 + 0]
 00000B96	     9003	STR R0 [SP + 12]
 00000B98	     9804	LDR R0 [SP + 16]
 00000B9A	     9903	LDR R1 [SP + 12]
 00000B9C	     4288	CMP R0 R1
 00000B9E	     D1E3	BNE #-58, goes to  00000B68
 00000BA0	 F6420004	MOV R0 #10244
 00000BA4	 F2C40000	MOVT R0 #16384
 00000BA8	     6800	LDR R0 [ R0 + 0]
 00000BAA	     9003	STR R0 [SP + 12]
 00000BAC	     9801	LDR R0 [SP + 4]
 00000BAE	     0D00	LSRS R0 R0 #20
 00000BB0	 F36F101F	BFC R0 #4 #28
 00000BB4	     210A	MOVS R1 #10
 00000BB6	     4348	MULS R0 R1 R0
 00000BB8	     9901	LDR R1 [SP + 4]
 00000BBA	     0C09	LSRS R1 R1 #16
 00000BBC	 F36F111F	BFC R1 #4 #28
 00000BC0	     1840	ADDS R0 R0 R1
 00000BC2	     0100	LSLS R0 R0 #4
 00000BC4	     9901	LDR R1 [SP + 4]
 00000BC6	     0B09	LSRS R1 R1 #12
 00000BC8	 F36F015F	BFC R1 #1 #31
 00000BCC	     220A	MOVS R2 #10
 00000BCE	     4351	MULS R1 R2 R1
 00000BD0	     1840	ADDS R0 R0 R1
 00000BD2	     9901	LDR R1 [SP + 4]
 00000BD4	     0A09	LSRS R1 R1 #8
 00000BD6	 F36F111F	BFC R1 #4 #28
 00000BDA	     1840	ADDS R0 R0 R1
 00000BDC	     0140	LSLS R0 R0 #5
 00000BDE	     9901	LDR R1 [SP + 4]
 00000BE0	     0909	LSRS R1 R1 #4
 00000BE2	 F36F019F	BFC R1 #2 #30
 00000BE6	     220A	MOVS R2 #10
 00000BE8	     4351	MULS R1 R2 R1
 00000BEA	     1840	ADDS R0 R0 R1
 00000BEC	     9901	LDR R1 [SP + 4]
 00000BEE	 F36F111F	BFC R1 #4 #28
 00000BF2	     1840	ADDS R0 R0 R1
 00000BF4	     0140	LSLS R0 R0 #5
 00000BF6	     9902	LDR R1 [SP + 8]
 00000BF8	     0D09	LSRS R1 R1 #20
 00000BFA	 F36F019F	BFC R1 #2 #30
 00000BFE	     220A	MOVS R2 #10
 00000C00	     4351	MULS R1 R2 R1
 00000C02	     1840	ADDS R0 R0 R1
 00000C04	     9902	LDR R1 [SP + 8]
 00000C06	     0C09	LSRS R1 R1 #16
 00000C08	 F36F111F	BFC R1 #4 #28
 00000C0C	     1840	ADDS R0 R0 R1
 00000C0E	     0180	LSLS R0 R0 #6
 00000C10	     9902	LDR R1 [SP + 8]
 00000C12	     0B09	LSRS R1 R1 #12
 00000C14	 F36F01DF	BFC R1 #3 #29
 00000C18	     220A	MOVS R2 #10
 00000C1A	     4351	MULS R1 R2 R1
 00000C1C	     1840	ADDS R0 R0 R1
 00000C1E	     9902	LDR R1 [SP + 8]
 00000C20	     0A09	LSRS R1 R1 #8
 00000C22	 F36F111F	BFC R1 #4 #28
 00000C26	     1840	ADDS R0 R0 R1
 00000C28	     0180	LSLS R0 R0 #6
 00000C2A	     9902	LDR R1 [SP + 8]
 00000C2C	     0909	LSRS R1 R1 #4
 00000C2E	 F36F01DF	BFC R1 #3 #29
 00000C32	     220A	MOVS R2 #10
 00000C34	     4351	MULS R1 R2 R1
 00000C36	     1840	ADDS R0 R0 R1
 00000C38	     9902	LDR R1 [SP + 8]
 00000C3A	 F36F111F	BFC R1 #4 #28
 00000C3E	     1840	ADDS R0 R0 R1
 00000C40	 F85DEB04	LDR LR [ SP ] + 4
 00000C44	 F11D0D10	ADDS SP SP #16
 00000C48	     4770	BX LR
 00000C4A	 F1BD0D20	SUBS SP SP #32
 00000C4E	     B401	PUSH R0
 00000C50	     B500	PUSH LR
 00000C52	     9801	LDR R0 [SP + 4]
 00000C54	     0E80	LSRS R0 R0 #26
 00000C56	     9007	STR R0 [SP + 28]
 00000C58	     9801	LDR R0 [SP + 4]
 00000C5A	     0D80	LSRS R0 R0 #22
 00000C5C	 F36F101F	BFC R0 #4 #28
 00000C60	     9008	STR R0 [SP + 32]
 00000C62	     9801	LDR R0 [SP + 4]
 00000C64	     0C40	LSRS R0 R0 #17
 00000C66	 F36F105F	BFC R0 #5 #27
 00000C6A	     9009	STR R0 [SP + 36]
 00000C6C	     9807	LDR R0 [SP + 28]
 00000C6E	     210A	MOVS R1 #10
 00000C70	 FBB0F0F1	UDIV R0 R0 R1
 00000C74	     0500	LSLS R0 R0 #20
 00000C76	     9907	LDR R1 [SP + 28]
 00000C78	     220A	MOVS R2 #10
 00000C7A	 FBB1F3F2	UDIV R3 R1 R2
 00000C7E	     4353	MULS R3 R2 R3
 00000C80	     1AC9	SUBS R1 R1 R3
 00000C82	     0409	LSLS R1 R1 #16
 00000C84	     1840	ADDS R0 R0 R1
 00000C86	     9908	LDR R1 [SP + 32]
 00000C88	     220A	MOVS R2 #10
 00000C8A	 FBB1F1F2	UDIV R1 R1 R2
 00000C8E	     0309	LSLS R1 R1 #12
 00000C90	     1840	ADDS R0 R0 R1
 00000C92	     9908	LDR R1 [SP + 32]
 00000C94	     220A	MOVS R2 #10
 00000C96	 FBB1F3F2	UDIV R3 R1 R2
 00000C9A	     4353	MULS R3 R2 R3
 00000C9C	     1AC9	SUBS R1 R1 R3
 00000C9E	     0209	LSLS R1 R1 #8
 00000CA0	     1840	ADDS R0 R0 R1
 00000CA2	     9909	LDR R1 [SP + 36]
 00000CA4	     220A	MOVS R2 #10
 00000CA6	 FBB1F1F2	UDIV R1 R1 R2
 00000CAA	     0109	LSLS R1 R1 #4
 00000CAC	     1840	ADDS R0 R0 R1
 00000CAE	     9909	LDR R1 [SP + 36]
 00000CB0	     220A	MOVS R2 #10
 00000CB2	 FBB1F3F2	UDIV R3 R1 R2
 00000CB6	     4353	MULS R3 R2 R3
 00000CB8	     1AC9	SUBS R1 R1 R3
 00000CBA	     1840	ADDS R0 R0 R1
 00000CBC	     9002	STR R0 [SP + 8]
 00000CBE	     9801	LDR R0 [SP + 4]
 00000CC0	     0B00	LSRS R0 R0 #12
 00000CC2	 F36F105F	BFC R0 #5 #27
 00000CC6	     9004	STR R0 [SP + 16]
 00000CC8	     9801	LDR R0 [SP + 4]
 00000CCA	     0980	LSRS R0 R0 #6
 00000CCC	 F36F109F	BFC R0 #6 #26
 00000CD0	     9005	STR R0 [SP + 20]
 00000CD2	     9801	LDR R0 [SP + 4]
 00000CD4	 F36F109F	BFC R0 #6 #26
 00000CD8	     9006	STR R0 [SP + 24]
 00000CDA	     9804	LDR R0 [SP + 16]
 00000CDC	     210A	MOVS R1 #10
 00000CDE	 FBB0F0F1	UDIV R0 R0 R1
 00000CE2	     0500	LSLS R0 R0 #20
 00000CE4	     9904	LDR R1 [SP + 16]
 00000CE6	     220A	MOVS R2 #10
 00000CE8	 FBB1F3F2	UDIV R3 R1 R2
 00000CEC	     4353	MULS R3 R2 R3
 00000CEE	     1AC9	SUBS R1 R1 R3
 00000CF0	     0409	LSLS R1 R1 #16
 00000CF2	     1840	ADDS R0 R0 R1
 00000CF4	     9905	LDR R1 [SP + 20]
 00000CF6	     220A	MOVS R2 #10
 00000CF8	 FBB1F1F2	UDIV R1 R1 R2
 00000CFC	     0309	LSLS R1 R1 #12
 00000CFE	     1840	ADDS R0 R0 R1
 00000D00	     9905	LDR R1 [SP + 20]
 00000D02	     220A	MOVS R2 #10
 00000D04	 FBB1F3F2	UDIV R3 R1 R2
 00000D08	     4353	MULS R3 R2 R3
 00000D0A	     1AC9	SUBS R1 R1 R3
 00000D0C	     0209	LSLS R1 R1 #8
 00000D0E	     1840	ADDS R0 R0 R1
 00000D10	     9906	LDR R1 [SP + 24]
 00000D12	     220A	MOVS R2 #10
 00000D14	 FBB1F1F2	UDIV R1 R1 R2
 00000D18	     0109	LSLS R1 R1 #4
 00000D1A	     1840	ADDS R0 R0 R1
 00000D1C	     9906	LDR R1 [SP + 24]
 00000D1E	     220A	MOVS R2 #10
 00000D20	 FBB1F3F2	UDIV R3 R1 R2
 00000D24	     4353	MULS R3 R2 R3
 00000D26	     1AC9	SUBS R1 R1 R3
 00000D28	     1840	ADDS R0 R0 R1
 00000D2A	     9003	STR R0 [SP + 12]
 00000D2C	 F6420024	MOV R0 #10276
 00000D30	 F2C40000	MOVT R0 #16384
 00000D34	     21CA	MOVS R1 #202
 00000D36	     6001	STR R1 [ R0 + 0]
 00000D38	 F6420024	MOV R0 #10276
 00000D3C	 F2C40000	MOVT R0 #16384
 00000D40	     2153	MOVS R1 #83
 00000D42	     6001	STR R1 [ R0 + 0]
 00000D44	 F240109C	MOV R0 #412
 00000D48	 F2C42005	MOVT R0 #16901
 00000D4C	     2101	MOVS R1 #1
 00000D4E	     7001	STRB R1 [ R0 + 0]
 00000D50	 F2401098	MOV R0 #408
 00000D54	 F2C42005	MOVT R0 #16901
 00000D58	     6800	LDR R0 [ R0 + 0]
 00000D5A	     2800	CMP R0 #0
 00000D5C	     D0F8	BEQ #-16, goes to  00000D50
 00000D5E	 F6420000	MOV R0 #10240
 00000D62	 F2C40000	MOVT R0 #16384
 00000D66	     9903	LDR R1 [SP + 12]
 00000D68	     6001	STR R1 [ R0 + 0]
 00000D6A	 F6420004	MOV R0 #10244
 00000D6E	 F2C40000	MOVT R0 #16384
 00000D72	     9902	LDR R1 [SP + 8]
 00000D74	     6001	STR R1 [ R0 + 0]
 00000D76	 F240109C	MOV R0 #412
 00000D7A	 F2C42005	MOVT R0 #16901
 00000D7E	     2100	MOVS R1 #0
 00000D80	     7001	STRB R1 [ R0 + 0]
 00000D82	 F6420024	MOV R0 #10276
 00000D86	 F2C40000	MOVT R0 #16384
 00000D8A	     21FF	MOVS R1 #255
 00000D8C	     6001	STR R1 [ R0 + 0]
 00000D8E	 F85DEB04	LDR LR [ SP ] + 4
 00000D92	 F11D0D24	ADDS SP SP #36
 00000D96	     4770	BX LR
 00000D98	     B403	PUSH R0 R1
 00000D9A	     B500	PUSH LR
 00000D9C	     9802	LDR R0 [SP + 8]
 00000D9E	     9901	LDR R1 [SP + 4]
 00000DA0	     6001	STR R1 [ R0 + 0]
 00000DA2	 F85DEB04	LDR LR [ SP ] + 4
 00000DA6	 F11D0D08	ADDS SP SP #8
 00000DAA	     4770	BX LR
 00000DAC	 F01E0F04	TST LR #4
 00000DB0	     BF0C	ITE EQ
 00000DB2	 F3EF8008	MRSEQ R0 MSP
 00000DB6	 F3EF8009	MRSNE R0 PSP
 00000DBA	 F1BD0D08	SUBS SP SP #8
 00000DBE	     B403	PUSH R0 R1
 00000DC0	     B500	PUSH LR
 00000DC2	     9801	LDR R0 [SP + 4]
 00000DC4	     6980	LDR R0 [ R0 + 24]
 00000DC6	     6800	LDR R0 [ R0 + 0]
 00000DC8	     9003	STR R0 [SP + 12]
 00000DCA	     9803	LDR R0 [SP + 12]
 00000DCC	     1400	ASRS R0 R0 #16
 00000DCE	 F36F101F	BFC R0 #4 #28
 00000DD2	     9004	STR R0 [SP + 16]
 00000DD4	     9804	LDR R0 [SP + 16]
 00000DD6	     3040	ADDS R0 #64
 00000DD8	 1030014B	BL Mod(  1) proc(3)
 00000DDC	     E7FE	B #-4, goes to  00000DDC
 00000DDE	 F85DEB04	LDR LR [ SP ] + 4
 00000DE2	 F11D0D10	ADDS SP SP #16
 00000DE6	     4770	BX LR
 00000DE8	     B500	PUSH LR
 00000DEA	 0000014C	MOV R0 lower 16-bits base(0)
 00000DEE	 00000030	MOVT R0 higher 16-bits base + 48
 00000DF2	     6801	LDR R1 [ R0 + 0]
 00000DF4	     1C49	ADDS R1 R1 #1
 00000DF6	     6001	STR R1 [ R0 + 0]
 00000DF8	 F85DEB04	LDR LR [ SP ] + 4
 00000DFC	     4770	BX LR
 00000DFE	 F01E0F04	TST LR #4
 00000E02	     BF0C	ITE EQ
 00000E04	 F3EF8008	MRSEQ R0 MSP
 00000E08	 F3EF8009	MRSNE R0 PSP
 00000E0C	 F1BD0D04	SUBS SP SP #4
 00000E10	     B403	PUSH R0 R1
 00000E12	     B500	PUSH LR
 00000E14	     9801	LDR R0 [SP + 4]
 00000E16	     6980	LDR R0 [ R0 + 24]
 00000E18	     1E80	SUBS R0 R0 #2
 00000E1A	     7800	LDRB R0 [ R0 + 0]
 00000E1C	 F88D000C	STRB R0 [ SP + 12 ]
 00000E20	 F89D000C	LDRB R0 [ SP + 12 ]
 00000E24	     2800	CMP R0 #0
 00000E26	 F0408008	BNE #16, goes to  00000E3A
 00000E2A	     9801	LDR R0 [SP + 4]
 00000E2C	     6800	LDR R0 [ R0 + 0]
 00000E2E	     9901	LDR R1 [SP + 4]
 00000E30	     6849	LDR R1 [ R1 + 4]
 00000E32	 F7FFFA33	BL #-2970, goes to  0000029C
 00000E36	 F000B809	B #18, goes to  00000E4C
 00000E3A	 F89D000C	LDRB R0 [ SP + 12 ]
 00000E3E	     2801	CMP R0 #1
 00000E40	 F0408004	BNE #8, goes to  00000E4C
 00000E44	     9801	LDR R0 [SP + 4]
 00000E46	     6800	LDR R0 [ R0 + 0]
 00000E48	 10300038	BL Mod(  1) proc(3)
 00000E4C	 F85DEB04	LDR LR [ SP ] + 4
 00000E50	 F11D0D0C	ADDS SP SP #12
 00000E54	     4770	BX LR
 00000E56	     B500	PUSH LR
 00000E58	     2080	MOVS R0 #128
 00000E5A	 10300009	BL Mod(  1) proc(3)
 00000E5E	 F2427010	MOV R0 #10000
 00000E62	 10200004	BL Mod(  1) proc(2)
 00000E66	     2000	MOVS R0 #0
 00000E68	 10300003	BL Mod(  1) proc(3)
 00000E6C	 F2427010	MOV R0 #10000
 00000E70	 10200004	BL Mod(  1) proc(2)
 00000E74	     E7F0	B #-32, goes to  00000E58
 00000E76	 F85DEB04	LDR LR [ SP ] + 4
 00000E7A	     4770	BX LR
 00000E7C	 F1BD0D04	SUBS SP SP #4
 00000E80	     B500	PUSH LR
 00000E82	     2006	MOVS R0 #6
 00000E84	     9001	STR R0 [SP + 4]
 00000E86	     9801	LDR R0 [SP + 4]
 00000E88	     1140	ASRS R0 R0 #5
 00000E8A	     0080	LSLS R0 R0 #2
 00000E8C	 F24E1180	MOV R1 #57728
 00000E90	 F2CE0100	MOVT R1 #57344
 00000E94	     1808	ADDS R0 R1 R0
 00000E96	     9901	LDR R1 [SP + 4]
 00000E98	 F36F115F	BFC R1 #5 #27
 00000E9C	     2201	MOVS R2 #1
 00000E9E	 FA12F101	LSLS R1 R2 R1
 00000EA2	     6001	STR R1 [ R0 + 0]
 00000EA4	 F85DEB04	LDR LR [ SP ] + 4
 00000EA8	 F11D0D04	ADDS SP SP #4
 00000EAC	     4770	BX LR
 00000EAE	 F1BD0D04	SUBS SP SP #4
 00000EB2	     B500	PUSH LR
 00000EB4	     2006	MOVS R0 #6
 00000EB6	     9001	STR R0 [SP + 4]
 00000EB8	     9801	LDR R0 [SP + 4]
 00000EBA	     1140	ASRS R0 R0 #5
 00000EBC	     0080	LSLS R0 R0 #2
 00000EBE	 F24E1100	MOV R1 #57600
 00000EC2	 F2CE0100	MOVT R1 #57344
 00000EC6	     1808	ADDS R0 R1 R0
 00000EC8	     9901	LDR R1 [SP + 4]
 00000ECA	 F36F115F	BFC R1 #5 #27
 00000ECE	     2201	MOVS R2 #1
 00000ED0	 FA12F101	LSLS R1 R2 R1
 00000ED4	     6001	STR R1 [ R0 + 0]
 00000ED6	 F85DEB04	LDR LR [ SP ] + 4
 00000EDA	 F11D0D04	ADDS SP SP #4
 00000EDE	     4770	BX LR
 00000EE0	 F1BD0D04	SUBS SP SP #4
 00000EE4	     B500	PUSH LR
 00000EE6	 F05F6000	MOVS R0 #134217728
 00000EEA	     6800	LDR R0 [ R0 + 0]
 00000EEC	     9001	STR R0 [SP + 4]
 00000EEE	 F05F5000	MOVS R0 #536870912
 00000EF2	     9901	LDR R1 [SP + 4]
 00000EF4	     6001	STR R1 [ R0 + 0]
 00000EF6	     2004	MOVS R0 #4
 00000EF8	 F6C00000	MOVT R0 #2048
 00000EFC	     6800	LDR R0 [ R0 + 0]
 00000EFE	     9001	STR R0 [SP + 4]
 00000F00	     2004	MOVS R0 #4
 00000F02	 F2C20000	MOVT R0 #8192
 00000F06	     9901	LDR R1 [SP + 4]
 00000F08	     6001	STR R1 [ R0 + 0]
 00000F0A	     2008	MOVS R0 #8
 00000F0C	 F2C20000	MOVT R0 #8192
 00000F10	 F24011A8	MOV R1 #424
 00000F14	 F2C20100	MOVT R1 #8192
 00000F18	     4288	CMP R0 R1
 00000F1A	 F300800A	BGT #20, goes to  00000F32
 00000F1E	     9001	STR R0 [SP + 4]
 00000F20	 F000F800	BL #0, goes to  00000F24
 00000F24	 F1BE00CE	SUBS R0 LR #206
 00000F28	     9901	LDR R1 [SP + 4]
 00000F2A	     6008	STR R0 [ R1 + 0]
 00000F2C	     9801	LDR R0 [SP + 4]
 00000F2E	     1D00	ADDS R0 R0 #4
 00000F30	     E7EE	B #-36, goes to  00000F10
 00000F32	 F64E5008	MOV R0 #60680
 00000F36	 F2CE0000	MOVT R0 #57344
 00000F3A	 F05F5100	MOVS R1 #536870912
 00000F3E	     6001	STR R1 [ R0 + 0]
 00000F40	 F64E5088	MOV R0 #60808
 00000F44	 F2CE0000	MOVT R0 #57344
 00000F48	 F45F0170	MOVS R1 #15728640
 00000F4C	     6001	STR R1 [ R0 + 0]
 00000F4E	 10B0006F	BL Mod(  1) proc(11)
 00000F52	 10900002	BL Mod(  1) proc(9)
 00000F56	 20600002	BL Mod(  2) proc(6)
 00000F5A	 F000F800	BL #0, goes to  00000F5E
 00000F5E	 F5BE70D9	SUBS R0 LR #434
 00000F62	     2118	MOVS R1 #24
 00000F64	 F2C20100	MOVT R1 #8192
 00000F68	 F7FFFF16	BL #-468, goes to  00000D98
 00000F6C	 F000F800	BL #0, goes to  00000F70
 00000F70	 F5BE70C4	SUBS R0 LR #392
 00000F74	     213C	MOVS R1 #60
 00000F76	 F2C20100	MOVT R1 #8192
 00000F7A	 F7FFFF0D	BL #-486, goes to  00000D98
 00000F7E	 F24E0018	MOV R0 #57368
 00000F82	 F2CE0000	MOVT R0 #57344
 00000F86	     2100	MOVS R1 #0
 00000F88	     6001	STR R1 [ R0 + 0]
 00000F8A	 F24E0010	MOV R0 #57360
 00000F8E	 F2CE0000	MOVT R0 #57344
 00000F92	     2107	MOVS R1 #7
 00000F94	     6001	STR R1 [ R0 + 0]
 00000F96	 F000F800	BL #0, goes to  00000F9A
 00000F9A	 F5BE70CE	SUBS R0 LR #412
 00000F9E	     212C	MOVS R1 #44
 00000FA0	 F2C20100	MOVT R1 #8192
 00000FA4	 F7FFFEF8	BL #-528, goes to  00000D98
 00000FA8	 F241000C	MOV R0 #4108
 00000FAC	 F2CD0020	MOVT R0 #53280
 00000FB0	     6800	LDR R0 [ R0 + 0]
 00000FB2	 100000E4	MOV R1 lower 16-bits base(0)
 00000FB6	 0000002C	MOVT R1 higher 16-bits base + 44
 00000FBA	     6008	STR R0 [ R1 + 0]
 00000FBC	 F2410018	MOV R0 #4120
 00000FC0	 F2CD0020	MOVT R0 #53280
 00000FC4	     6800	LDR R0 [ R0 + 0]
 00000FC6	 1000000A	MOV R1 lower 16-bits base(0)
 00000FCA	 00000024	MOVT R1 higher 16-bits base + 36
 00000FCE	     6008	STR R0 [ R1 + 0]
 00000FD0	 F241001C	MOV R0 #4124
 00000FD4	 F2CD0020	MOVT R0 #53280
 00000FD8	     6800	LDR R0 [ R0 + 0]
 00000FDA	 1000000A	MOV R1 lower 16-bits base(0)
 00000FDE	 0000001C	MOVT R1 higher 16-bits base + 28
 00000FE2	     6008	STR R0 [ R1 + 0]
 00000FE4	 F45F3080	MOVS R0 #65536
 00000FE8	 10000007	MOV R1 lower 16-bits base(0)
 00000FEC	 00000028	MOVT R1 higher 16-bits base + 40
 00000FF0	     6008	STR R0 [ R1 + 0]
 00000FF2	 00000005	MOV R0 lower 16-bits base(0)
 00000FF6	 0000002C	MOVT R0 higher 16-bits base + 44
 00000FFA	     6800	LDR R0 [ R0 + 0]
 00000FFC	 10000005	MOV R1 lower 16-bits base(0)
 00001000	 00000020	MOVT R1 higher 16-bits base + 32
 00001004	     6008	STR R0 [ R1 + 0]
 00001006	     2000	MOVS R0 #0
 00001008	 10000006	MOV R1 lower 16-bits base(0)
 0000100C	 00000038	MOVT R1 higher 16-bits base + 56
 00001010	     6008	STR R0 [ R1 + 0]
 00001012	     2000	MOVS R0 #0
 00001014	 10000006	MOV R1 lower 16-bits base(0)
 00001018	 0000003C	MOVT R1 higher 16-bits base + 60
 0000101C	     6008	STR R0 [ R1 + 0]
 0000101E	     2000	MOVS R0 #0
 00001020	 10000006	MOV R1 lower 16-bits base(0)
 00001024	 00000040	MOVT R1 higher 16-bits base + 64
 00001028	     6008	STR R0 [ R1 + 0]
 0000102A	 00000005	MOV R0 lower 16-bits base(0)
 0000102E	 0000001C	MOVT R0 higher 16-bits base + 28
 00001032	     6800	LDR R0 [ R0 + 0]
 00001034	 10000005	MOV R1 lower 16-bits base(0)
 00001038	 00000034	MOVT R1 higher 16-bits base + 52
 0000103C	     6008	STR R0 [ R1 + 0]
 0000103E	 00000005	MOV R0 lower 16-bits base(0)
 00001042	 00000020	MOVT R0 higher 16-bits base + 32
 00001046	     6800	LDR R0 [ R0 + 0]
 00001048	 10000005	MOV R1 lower 16-bits base(0)
 0000104C	 0000001C	MOVT R1 higher 16-bits base + 28
 00001050	     6809	LDR R1 [ R1 + 0]
 00001052	     1A40	SUBS R0 R0 R1
 00001054	 10000006	MOV R1 lower 16-bits base(0)
 00001058	 00000034	MOVT R1 higher 16-bits base + 52
 0000105C	     6809	LDR R1 [ R1 + 0]
 0000105E	     6008	STR R0 [ R1 + 0]
 00001060	 00000006	MOV R0 lower 16-bits base(0)
 00001064	 00000034	MOVT R0 higher 16-bits base + 52
 00001068	     6800	LDR R0 [ R0 + 0]
 0000106A	     1D00	ADDS R0 R0 #4
 0000106C	 F05F31FF	MOVS R1 #-1
 00001070	     6001	STR R1 [ R0 + 0]
 00001072	 00000009	MOV R0 lower 16-bits base(0)
 00001076	 00000034	MOVT R0 higher 16-bits base + 52
 0000107A	     6800	LDR R0 [ R0 + 0]
 0000107C	     3008	ADDS R0 #8
 0000107E	     2100	MOVS R1 #0
 00001080	     6001	STR R1 [ R0 + 0]
 00001082	     2000	MOVS R0 #0
 00001084	 10000009	MOV R1 lower 16-bits base(0)
 00001088	 00000014	MOVT R1 higher 16-bits base + 20
 0000108C	     6008	STR R0 [ R1 + 0]
 0000108E	 F7FFFBE9	BL #-2094, goes to  00000864
 00001092	 F85DEB04	LDR LR [ SP ] + 4
 00001096	 F11D0D04	ADDS SP SP #4
 0000109A	     4770	BX LR
 0000109C	     B500	PUSH LR
 0000109E	 F85DEB04	LDR LR [ SP ] + 4
 000010A2	     4770	BX LR
