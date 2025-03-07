MODULE Kernel;  (*NW/PR  11.4.86 / 27.12.95 / 4.2.2014 / CS 13/12/2023*)
  IMPORT SYSTEM, BSP, SDCard, LongDiv;
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
    SPHWM*: INTEGER;
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

  PROCEDURE Init;
    VAR i: INTEGER;
  BEGIN (*relocate vector table at beginning of SRAM*)
    SYSTEM.GET(08000000H, i); SYSTEM.PUT(20000000H, i); SYSTEM.GET(08000004H, i); SYSTEM.PUT(20000004H, i); 
    FOR i := 20000008H TO 200001A8H BY 4 DO SYSTEM.PUT(i, SYSTEM.ADR(defaultHandler)) END; (*initialize vectors to default trap*)
    SYSTEM.PUT(BSP.SCB_BASE + BSP.VTOR, 20000000H);
    SYSTEM.PUT(BSP.SCB_BASE + BSP.CPACR, (BSP.CP10m + BSP.CP11m)); (*set CP10 and CP11 full access to activate FPU*)
    BSP.InitRTC;
    Install(SYSTEM.ADR(Trap), BSP.VecTabBase+BSP.UsageFaultExcNum*4);  (*install temporary trap*)
    Install(SYSTEM.ADR(IncTick), BSP.VecTabBase+BSP.SysTickExcNum*4);
    SYSTEM.PUT(BSP.SYST_CVR, 0); SYSTEM.PUT(BSP.SYST_CSR, {BSP.CLKSOURCE, BSP.TICKINT, BSP.SYST_ENABLE});
    Install(SYSTEM.ADR(SVCallHandler), BSP.VecTabBase+BSP.SVCallExcNum*4);
    SYSTEM.GET(VarORG0+12, MemLim); SYSTEM.GET(VarORG0+24, stackOrg);
    SYSTEM.GET(VarORG0+28, heapOrg); stackSize := 10000H; heapLim := MemLim;
    list1 := 0; list2 := 0; list3 := 0; list0 := heapOrg;
    SYSTEM.PUT(list0, heapLim - heapOrg); SYSTEM.PUT(list0+4, -1); SYSTEM.PUT(list0+8, 0);
    allocated := 0; SPHWM := LSL(1, 31) - 1; InitSecMap
  END Init;

BEGIN Init
END Kernel.

OM4Tool.DecSym Kernel.sm4
decode Kernel.sm4
Kernel D685882E  1
   1 SectorLength [^4]    1024
   1 VarORG0 [^4]-803205120
   5 Sector [15  form = 12 [^1]  len = 1024  size = 1024]()
   5 ExceptionFrame [16  form = 7 [17  form = 13 [^9]  exno = 1  extlev = 0  size = 32 { xpsr [^4]  28 returnAddress [^4]  24 lr [^4]  20 r12 [^4]  16 r3 [^4]  12 r2 [^4]   8 r1 [^4]   4 r0 [^4]   0}]]()
   5 ExceptionFrameDesc [^17]( ->  16)
   2 allocated [^4]     2
   2 NofSectors [^4]     3
   2 heapOrg [^4]     4
   2 heapLim [^4]     5
   2 stackOrg [^4]     6
   2 stackSize [^4]     7
   2 MemLim [^4]     8
   2 SPHWM [^4]     9
   2 list0 [^4]    10
   2 list1 [^4]    11
   2 list2 [^4]    12
   2 list3 [^4]    13
   1 Mark [0  form = 10 [^9]( class = 2 [^4])]      14
   1 Scan [0  form = 10 [^9]()]      15
   1 Coalesce [0  form = 10 [^9]()]      16
   1 MarkSector [0  form = 10 [^9]( class = 2 [^4])]      17
   1 FreeSector [0  form = 10 [^9]( class = 2 [^4])]      18
   1 AllocSector [0  form = 10 [^9]( class = 3 [^4] class = 2 [^4])]      19
   1 GetSector [0  form = 10 [^9]( class = 3 [^15] class = 2 [^4])]      20
   1 PutSector [0  form = 10 [^9]( class = 3 [^15] class = 2 [^4])]      21
   1 Time [0  form = 10 [^4]()]      22
   1 Clock [0  form = 10 [^4]()]      23
   1 SetClock [0  form = 10 [^9]( class = 2 [^4])]      24
   1 Install [0  form = 10 [^9]( class = 2 [^4] class = 2 [^4])]      25
   1 setSPHWM [0  form = 10 [^9]()]      26
   1 DisableAbortHandler [0  form = 10 [^9]()]      27
   1 EnableAbortHandler [0  form = 10 [^9]()]      28

OM4Tool.DecObj Kernel.m4c
decode Kernel.m4c
Kernel D685882E   2  12764
imports:
	BSP 17BE1E3B
	SDCard 4A193F90
	LongDiv F96D031F
type descriptors
 00000040 FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF
strings

data  8244
code
commands:
	Scan 00000452
	Coalesce 00000642
	setSPHWM 00000D5C
	DisableAbortHandler 00000E68
	EnableAbortHandler 00000E96
entries
 00001072 00000000 00000000 00000004 00000008 0000000C 00000010 00000014 00000018 0000001C 00000024 00000028 0000002C 00000030 00000334 00000452 00000642 000008EC 0000094E 000009B0 00000A92 00000ACE 00000B0A 00000B1C 00000C00 00000D4A 00000D5C 00000E68 00000E96
pointer refs

fixP =  00000F2C
fixV =  0000105C
fixC =  00000000
fixT =  00000000
entry =  00001072
 00000000	     B085	SUB SP SP #20
 00000002	     B403	PUSH R0 R1
 00000004	     B500	PUSH LR
 00000006	     2000	MOVS R0 #0
 00000008	     9003	STR R0 [ SP + 12 ]
 0000000A	 00000005	MOV R0 lower 16-bits base(0), next at  00000000
 0000000E	 00000024	MOVT R0 higher 16-bits var + 36
 00000012	     6800	LDR R0 [ R0 + 0 ]
 00000014	     9004	STR R0 [ SP + 16 ]
 00000016	     2000	MOVS R0 #0
 00000018	 F88D001C	STRB R0 [  SP + 28 ]
 0000001C	 F89D001C	LDRB R0 [ SP + 28 ]
 00000020	     2800	CMP R0 #0
 00000022	 F040805C	BNE #184, goes to  000000DE
 00000026	     9804	LDR R0 [ SP + 16 ]
 00000028	     2800	CMP R0 #0
 0000002A	 F0008058	BEQ #176, goes to  000000DE
 0000002E	     9804	LDR R0 [ SP + 16 ]
 00000030	     6800	LDR R0 [ R0 + 0 ]
 00000032	     9006	STR R0 [ SP + 24 ]
 00000034	     9804	LDR R0 [ SP + 16 ]
 00000036	     3008	ADDS R0 R0 #8
 00000038	     6800	LDR R0 [ R0 + 0 ]
 0000003A	     9005	STR R0 [ SP + 20 ]
 0000003C	     9806	LDR R0 [ SP + 24 ]
 0000003E	     9902	LDR R1 [ SP + 8 ]
 00000040	     4288	CMP R0 R1
 00000042	 F2808006	BGE #12, goes to  00000052
 00000046	     9804	LDR R0 [ SP + 16 ]
 00000048	     9003	STR R0 [ SP + 12 ]
 0000004A	     9805	LDR R0 [ SP + 20 ]
 0000004C	     9004	STR R0 [ SP + 16 ]
 0000004E	 F000B845	B #138, goes to  000000DC
 00000052	     9806	LDR R0 [ SP + 24 ]
 00000054	     9902	LDR R1 [ SP + 8 ]
 00000056	     4288	CMP R0 R1
 00000058	 F0408018	BNE #48, goes to  0000008C
 0000005C	     2001	MOVS R0 #1
 0000005E	 F88D001C	STRB R0 [  SP + 28 ]
 00000062	     9804	LDR R0 [ SP + 16 ]
 00000064	     9901	LDR R1 [ SP + 4 ]
 00000066	     6008	STR R0 [  R1 + 0 ]
 00000068	     9803	LDR R0 [ SP + 12 ]
 0000006A	     2800	CMP R0 #0
 0000006C	 F0008006	BEQ #12, goes to  0000007C
 00000070	     9803	LDR R0 [ SP + 12 ]
 00000072	     3008	ADDS R0 R0 #8
 00000074	     9905	LDR R1 [ SP + 20 ]
 00000076	     6001	STR R1 [  R0 + 0 ]
 00000078	 F000B806	B #12, goes to  00000088
 0000007C	     9805	LDR R0 [ SP + 20 ]
 0000007E	 1000003A	MOV R1 lower 16-bits base(0), next at  0000000A
 00000082	 00000024	MOVT R1 higher 16-bits var + 36
 00000086	     6008	STR R0 [  R1 + 0 ]
 00000088	 F000B828	B #80, goes to  000000DC
 0000008C	     2001	MOVS R0 #1
 0000008E	 F88D001C	STRB R0 [  SP + 28 ]
 00000092	     9804	LDR R0 [ SP + 16 ]
 00000094	     9901	LDR R1 [ SP + 4 ]
 00000096	     6008	STR R0 [  R1 + 0 ]
 00000098	     9804	LDR R0 [ SP + 16 ]
 0000009A	     9902	LDR R1 [ SP + 8 ]
 0000009C	     1840	ADDS R0 R0 R1
 0000009E	     9004	STR R0 [ SP + 16 ]
 000000A0	     9806	LDR R0 [ SP + 24 ]
 000000A2	     9902	LDR R1 [ SP + 8 ]
 000000A4	     1A40	SUBS R0 R0 R1
 000000A6	     9904	LDR R1 [ SP + 16 ]
 000000A8	     6008	STR R0 [  R1 + 0 ]
 000000AA	     9804	LDR R0 [ SP + 16 ]
 000000AC	     1D00	ADDS R0 R0 #4
 000000AE	 F05F31FF	MOVS R1 #-1
 000000B2	     6001	STR R1 [  R0 + 0 ]
 000000B4	     9804	LDR R0 [ SP + 16 ]
 000000B6	     3008	ADDS R0 R0 #8
 000000B8	     9905	LDR R1 [ SP + 20 ]
 000000BA	     6001	STR R1 [  R0 + 0 ]
 000000BC	     9803	LDR R0 [ SP + 12 ]
 000000BE	     2800	CMP R0 #0
 000000C0	 F0008006	BEQ #12, goes to  000000D0
 000000C4	     9803	LDR R0 [ SP + 12 ]
 000000C6	     3008	ADDS R0 R0 #8
 000000C8	     9904	LDR R1 [ SP + 16 ]
 000000CA	     6001	STR R1 [  R0 + 0 ]
 000000CC	 F000B806	B #12, goes to  000000DC
 000000D0	     9804	LDR R0 [ SP + 16 ]
 000000D2	 1000002A	MOV R1 lower 16-bits base(0), next at  0000007E
 000000D6	 00000024	MOVT R1 higher 16-bits var + 36
 000000DA	     6008	STR R0 [  R1 + 0 ]
 000000DC	     E79E	B #-196, goes to  0000001C
 000000DE	 F89D001C	LDRB R0 [ SP + 28 ]
 000000E2	     2800	CMP R0 #0
 000000E4	 F0408003	BNE #6, goes to  000000EE
 000000E8	     2000	MOVS R0 #0
 000000EA	     9901	LDR R1 [ SP + 4 ]
 000000EC	     6008	STR R0 [  R1 + 0 ]
 000000EE	 F85DEB04	LDR LR [ SP ] + 4
 000000F2	     B007	ADD SP SP #28
 000000F4	     4770	BX LR
 000000F6	     B081	SUB SP SP #4
 000000F8	     B401	PUSH R0
 000000FA	     B500	PUSH LR
 000000FC	 00000015	MOV R0 lower 16-bits base(0), next at  000000D2
 00000100	 00000028	MOVT R0 higher 16-bits var + 40
 00000104	     6800	LDR R0 [ R0 + 0 ]
 00000106	     2800	CMP R0 #0
 00000108	 F0008015	BEQ #42, goes to  00000136
 0000010C	 00000008	MOV R0 lower 16-bits base(0), next at  000000FC
 00000110	 00000028	MOVT R0 higher 16-bits var + 40
 00000114	     6800	LDR R0 [ R0 + 0 ]
 00000116	     9901	LDR R1 [ SP + 4 ]
 00000118	     6008	STR R0 [  R1 + 0 ]
 0000011A	 00000007	MOV R0 lower 16-bits base(0), next at  0000010C
 0000011E	 00000028	MOVT R0 higher 16-bits var + 40
 00000122	     6800	LDR R0 [ R0 + 0 ]
 00000124	     3008	ADDS R0 R0 #8
 00000126	     6800	LDR R0 [ R0 + 0 ]
 00000128	 10000007	MOV R1 lower 16-bits base(0), next at  0000011A
 0000012C	 00000028	MOVT R1 higher 16-bits var + 40
 00000130	     6008	STR R0 [  R1 + 0 ]
 00000132	 F000B820	B #64, goes to  00000176
 00000136	     A802	ADD R0 SP #8
 00000138	 F45F7180	MOVS R1 #256
 0000013C	 F7FFFF60	BL #-320, goes to  00000000
 00000140	     9802	LDR R0 [ SP + 8 ]
 00000142	     3080	ADDS R0 R0 #128
 00000144	     2180	MOVS R1 #128
 00000146	     6001	STR R1 [  R0 + 0 ]
 00000148	     9802	LDR R0 [ SP + 8 ]
 0000014A	     3084	ADDS R0 R0 #132
 0000014C	 F05F31FF	MOVS R1 #-1
 00000150	     6001	STR R1 [  R0 + 0 ]
 00000152	     9802	LDR R0 [ SP + 8 ]
 00000154	     3088	ADDS R0 R0 #136
 00000156	 10000017	MOV R1 lower 16-bits base(0), next at  00000128
 0000015A	 00000028	MOVT R1 higher 16-bits var + 40
 0000015E	     6809	LDR R1 [ R1 + 0 ]
 00000160	     6001	STR R1 [  R0 + 0 ]
 00000162	     9802	LDR R0 [ SP + 8 ]
 00000164	     3080	ADDS R0 R0 #128
 00000166	 10000008	MOV R1 lower 16-bits base(0), next at  00000156
 0000016A	 00000028	MOVT R1 higher 16-bits var + 40
 0000016E	     6008	STR R0 [  R1 + 0 ]
 00000170	     9802	LDR R0 [ SP + 8 ]
 00000172	     9901	LDR R1 [ SP + 4 ]
 00000174	     6008	STR R0 [  R1 + 0 ]
 00000176	 F85DEB04	LDR LR [ SP ] + 4
 0000017A	     B002	ADD SP SP #8
 0000017C	     4770	BX LR
 0000017E	     B081	SUB SP SP #4
 00000180	     B401	PUSH R0
 00000182	     B500	PUSH LR
 00000184	 0000000F	MOV R0 lower 16-bits base(0), next at  00000166
 00000188	 0000002C	MOVT R0 higher 16-bits var + 44
 0000018C	     6800	LDR R0 [ R0 + 0 ]
 0000018E	     2800	CMP R0 #0
 00000190	 F0008015	BEQ #42, goes to  000001BE
 00000194	 00000008	MOV R0 lower 16-bits base(0), next at  00000184
 00000198	 0000002C	MOVT R0 higher 16-bits var + 44
 0000019C	     6800	LDR R0 [ R0 + 0 ]
 0000019E	     9901	LDR R1 [ SP + 4 ]
 000001A0	     6008	STR R0 [  R1 + 0 ]
 000001A2	 00000007	MOV R0 lower 16-bits base(0), next at  00000194
 000001A6	 0000002C	MOVT R0 higher 16-bits var + 44
 000001AA	     6800	LDR R0 [ R0 + 0 ]
 000001AC	     3008	ADDS R0 R0 #8
 000001AE	     6800	LDR R0 [ R0 + 0 ]
 000001B0	 10000007	MOV R1 lower 16-bits base(0), next at  000001A2
 000001B4	 0000002C	MOVT R1 higher 16-bits var + 44
 000001B8	     6008	STR R0 [  R1 + 0 ]
 000001BA	 F000B81E	B #60, goes to  000001FA
 000001BE	     A802	ADD R0 SP #8
 000001C0	 F7FFFF99	BL #-206, goes to  000000F6
 000001C4	     9802	LDR R0 [ SP + 8 ]
 000001C6	     3040	ADDS R0 R0 #64
 000001C8	     2140	MOVS R1 #64
 000001CA	     6001	STR R1 [  R0 + 0 ]
 000001CC	     9802	LDR R0 [ SP + 8 ]
 000001CE	     3044	ADDS R0 R0 #68
 000001D0	 F05F31FF	MOVS R1 #-1
 000001D4	     6001	STR R1 [  R0 + 0 ]
 000001D6	     9802	LDR R0 [ SP + 8 ]
 000001D8	     3048	ADDS R0 R0 #72
 000001DA	 10000015	MOV R1 lower 16-bits base(0), next at  000001B0
 000001DE	 0000002C	MOVT R1 higher 16-bits var + 44
 000001E2	     6809	LDR R1 [ R1 + 0 ]
 000001E4	     6001	STR R1 [  R0 + 0 ]
 000001E6	     9802	LDR R0 [ SP + 8 ]
 000001E8	     3040	ADDS R0 R0 #64
 000001EA	 10000008	MOV R1 lower 16-bits base(0), next at  000001DA
 000001EE	 0000002C	MOVT R1 higher 16-bits var + 44
 000001F2	     6008	STR R0 [  R1 + 0 ]
 000001F4	     9802	LDR R0 [ SP + 8 ]
 000001F6	     9901	LDR R1 [ SP + 4 ]
 000001F8	     6008	STR R0 [  R1 + 0 ]
 000001FA	 F85DEB04	LDR LR [ SP ] + 4
 000001FE	     B002	ADD SP SP #8
 00000200	     4770	BX LR
 00000202	     B081	SUB SP SP #4
 00000204	     B401	PUSH R0
 00000206	     B500	PUSH LR
 00000208	 0000000F	MOV R0 lower 16-bits base(0), next at  000001EA
 0000020C	 00000030	MOVT R0 higher 16-bits var + 48
 00000210	     6800	LDR R0 [ R0 + 0 ]
 00000212	     2800	CMP R0 #0
 00000214	 F0008015	BEQ #42, goes to  00000242
 00000218	 00000008	MOV R0 lower 16-bits base(0), next at  00000208
 0000021C	 00000030	MOVT R0 higher 16-bits var + 48
 00000220	     6800	LDR R0 [ R0 + 0 ]
 00000222	     9901	LDR R1 [ SP + 4 ]
 00000224	     6008	STR R0 [  R1 + 0 ]
 00000226	 00000007	MOV R0 lower 16-bits base(0), next at  00000218
 0000022A	 00000030	MOVT R0 higher 16-bits var + 48
 0000022E	     6800	LDR R0 [ R0 + 0 ]
 00000230	     3008	ADDS R0 R0 #8
 00000232	     6800	LDR R0 [ R0 + 0 ]
 00000234	 10000007	MOV R1 lower 16-bits base(0), next at  00000226
 00000238	 00000030	MOVT R1 higher 16-bits var + 48
 0000023C	     6008	STR R0 [  R1 + 0 ]
 0000023E	 F000B81E	B #60, goes to  0000027E
 00000242	     A802	ADD R0 SP #8
 00000244	 F7FFFF9B	BL #-202, goes to  0000017E
 00000248	     9802	LDR R0 [ SP + 8 ]
 0000024A	     3020	ADDS R0 R0 #32
 0000024C	     2120	MOVS R1 #32
 0000024E	     6001	STR R1 [  R0 + 0 ]
 00000250	     9802	LDR R0 [ SP + 8 ]
 00000252	     3024	ADDS R0 R0 #36
 00000254	 F05F31FF	MOVS R1 #-1
 00000258	     6001	STR R1 [  R0 + 0 ]
 0000025A	     9802	LDR R0 [ SP + 8 ]
 0000025C	     3028	ADDS R0 R0 #40
 0000025E	 10000015	MOV R1 lower 16-bits base(0), next at  00000234
 00000262	 00000030	MOVT R1 higher 16-bits var + 48
 00000266	     6809	LDR R1 [ R1 + 0 ]
 00000268	     6001	STR R1 [  R0 + 0 ]
 0000026A	     9802	LDR R0 [ SP + 8 ]
 0000026C	     3020	ADDS R0 R0 #32
 0000026E	 10000008	MOV R1 lower 16-bits base(0), next at  0000025E
 00000272	 00000030	MOVT R1 higher 16-bits var + 48
 00000276	     6008	STR R0 [  R1 + 0 ]
 00000278	     9802	LDR R0 [ SP + 8 ]
 0000027A	     9901	LDR R1 [ SP + 4 ]
 0000027C	     6008	STR R0 [  R1 + 0 ]
 0000027E	 F85DEB04	LDR LR [ SP ] + 4
 00000282	     B002	ADD SP SP #8
 00000284	     4770	BX LR
 00000286	     B083	SUB SP SP #12
 00000288	     B403	PUSH R0 R1
 0000028A	     B500	PUSH LR
 0000028C	     9802	LDR R0 [ SP + 8 ]
 0000028E	     6800	LDR R0 [ R0 + 0 ]
 00000290	     9004	STR R0 [ SP + 16 ]
 00000292	     9804	LDR R0 [ SP + 16 ]
 00000294	     2820	CMP R0 #32
 00000296	 F0408005	BNE #10, goes to  000002A4
 0000029A	     A803	ADD R0 SP #12
 0000029C	 F7FFFFB1	BL #-158, goes to  00000202
 000002A0	 F000B819	B #50, goes to  000002D6
 000002A4	     9804	LDR R0 [ SP + 16 ]
 000002A6	     2840	CMP R0 #64
 000002A8	 F0408005	BNE #10, goes to  000002B6
 000002AC	     A803	ADD R0 SP #12
 000002AE	 F7FFFF66	BL #-308, goes to  0000017E
 000002B2	 F000B810	B #32, goes to  000002D6
 000002B6	     9804	LDR R0 [ SP + 16 ]
 000002B8	     2880	CMP R0 #128
 000002BA	 F0408005	BNE #10, goes to  000002C8
 000002BE	     A803	ADD R0 SP #12
 000002C0	 F7FFFF19	BL #-462, goes to  000000F6
 000002C4	 F000B807	B #14, goes to  000002D6
 000002C8	     A803	ADD R0 SP #12
 000002CA	     9904	LDR R1 [ SP + 16 ]
 000002CC	     31FF	ADDS R1 R1 #255
 000002CE	     1209	ASRS R1 R1 #8
 000002D0	     0209	LSLS R1 R1 #8
 000002D2	 F7FFFE95	BL #-726, goes to  00000000
 000002D6	     9803	LDR R0 [ SP + 12 ]
 000002D8	     2800	CMP R0 #0
 000002DA	 F0408005	BNE #10, goes to  000002E8
 000002DE	     9801	LDR R0 [ SP + 4 ]
 000002E0	     2100	MOVS R1 #0
 000002E2	     6001	STR R1 [  R0 + 0 ]
 000002E4	 F000B822	B #68, goes to  0000032C
 000002E8	     9803	LDR R0 [ SP + 12 ]
 000002EA	     3008	ADDS R0 R0 #8
 000002EC	     9901	LDR R1 [ SP + 4 ]
 000002EE	     6008	STR R0 [  R1 + 0 ]
 000002F0	     9803	LDR R0 [ SP + 12 ]
 000002F2	     9902	LDR R1 [ SP + 8 ]
 000002F4	     6001	STR R1 [  R0 + 0 ]
 000002F6	     9803	LDR R0 [ SP + 12 ]
 000002F8	     9904	LDR R1 [ SP + 16 ]
 000002FA	     1840	ADDS R0 R0 R1
 000002FC	     9005	STR R0 [ SP + 20 ]
 000002FE	     9803	LDR R0 [ SP + 12 ]
 00000300	     1D00	ADDS R0 R0 #4
 00000302	     9003	STR R0 [ SP + 12 ]
 00000304	 0000004B	MOV R0 lower 16-bits base(0), next at  0000026E
 00000308	 00000000	MOVT R0 higher 16-bits var + 0
 0000030C	     6801	LDR R1 [ R0 + 0 ]
 0000030E	     9A04	LDR R2 [ SP + 16 ]
 00000310	     1889	ADDS R1 R1 R2
 00000312	     6001	STR R1 [  R0 + 0 ]
 00000314	     9803	LDR R0 [ SP + 12 ]
 00000316	     9905	LDR R1 [ SP + 20 ]
 00000318	     4288	CMP R0 R1
 0000031A	 F0808007	BCS #14, goes to  0000032C
 0000031E	     9803	LDR R0 [ SP + 12 ]
 00000320	     2100	MOVS R1 #0
 00000322	     6001	STR R1 [  R0 + 0 ]
 00000324	     9803	LDR R0 [ SP + 12 ]
 00000326	     1D00	ADDS R0 R0 #4
 00000328	     9003	STR R0 [ SP + 12 ]
 0000032A	     E7F3	B #-26, goes to  00000314
 0000032C	 F85DEB04	LDR LR [ SP ] + 4
 00000330	     B005	ADD SP SP #20
 00000332	     4770	BX LR
 00000334	     B087	SUB SP SP #28
 00000336	     B401	PUSH R0
 00000338	     B500	PUSH LR
 0000033A	     9801	LDR R0 [ SP + 4 ]
 0000033C	     6800	LDR R0 [ R0 + 0 ]
 0000033E	     9002	STR R0 [ SP + 8 ]
 00000340	     9802	LDR R0 [ SP + 8 ]
 00000342	     2800	CMP R0 #0
 00000344	 F0008081	BEQ #258, goes to  0000044A
 00000348	     9802	LDR R0 [ SP + 8 ]
 0000034A	     6800	LDR R0 [ R0 + 0 ]
 0000034C	     9006	STR R0 [ SP + 24 ]
 0000034E	     9806	LDR R0 [ SP + 24 ]
 00000350	     1F00	SUBS R0 R0 #4
 00000352	     6800	LDR R0 [ R0 + 0 ]
 00000354	     9003	STR R0 [ SP + 12 ]
 00000356	     9806	LDR R0 [ SP + 24 ]
 00000358	 1000002A	MOV R1 lower 16-bits base(0), next at  00000304
 0000035C	 00000008	MOVT R1 higher 16-bits var + 8
 00000360	     6809	LDR R1 [ R1 + 0 ]
 00000362	     4288	CMP R0 R1
 00000364	 F0C0806A	BCC #212, goes to  0000043C
 00000368	     9803	LDR R0 [ SP + 12 ]
 0000036A	     2800	CMP R0 #0
 0000036C	 F0408066	BNE #204, goes to  0000043C
 00000370	     9806	LDR R0 [ SP + 24 ]
 00000372	     9007	STR R0 [ SP + 28 ]
 00000374	     9806	LDR R0 [ SP + 24 ]
 00000376	     1F00	SUBS R0 R0 #4
 00000378	     6800	LDR R0 [ R0 + 0 ]
 0000037A	     9003	STR R0 [ SP + 12 ]
 0000037C	     9803	LDR R0 [ SP + 12 ]
 0000037E	     2800	CMP R0 #0
 00000380	 F0408009	BNE #18, goes to  00000396
 00000384	     9806	LDR R0 [ SP + 24 ]
 00000386	     3808	SUBS R0 R0 #8
 00000388	     6800	LDR R0 [ R0 + 0 ]
 0000038A	     9005	STR R0 [ SP + 20 ]
 0000038C	     9805	LDR R0 [ SP + 20 ]
 0000038E	     3010	ADDS R0 R0 #16
 00000390	     9003	STR R0 [ SP + 12 ]
 00000392	 F000B803	B #6, goes to  0000039C
 00000396	     9803	LDR R0 [ SP + 12 ]
 00000398	     1D00	ADDS R0 R0 #4
 0000039A	     9003	STR R0 [ SP + 12 ]
 0000039C	     9806	LDR R0 [ SP + 24 ]
 0000039E	     1F00	SUBS R0 R0 #4
 000003A0	     9903	LDR R1 [ SP + 12 ]
 000003A2	     6001	STR R1 [  R0 + 0 ]
 000003A4	     9803	LDR R0 [ SP + 12 ]
 000003A6	     6800	LDR R0 [ R0 + 0 ]
 000003A8	     9004	STR R0 [ SP + 16 ]
 000003AA	     9804	LDR R0 [ SP + 16 ]
 000003AC	 F1B03FFF	CMP R0 #-1
 000003B0	 F0008021	BEQ #66, goes to  000003F6
 000003B4	     9806	LDR R0 [ SP + 24 ]
 000003B6	     9904	LDR R1 [ SP + 16 ]
 000003B8	     1840	ADDS R0 R0 R1
 000003BA	     6800	LDR R0 [ R0 + 0 ]
 000003BC	     9008	STR R0 [ SP + 32 ]
 000003BE	     9808	LDR R0 [ SP + 32 ]
 000003C0	     1F00	SUBS R0 R0 #4
 000003C2	     6800	LDR R0 [ R0 + 0 ]
 000003C4	     9003	STR R0 [ SP + 12 ]
 000003C6	     9808	LDR R0 [ SP + 32 ]
 000003C8	 10000038	MOV R1 lower 16-bits base(0), next at  00000358
 000003CC	 00000008	MOVT R1 higher 16-bits var + 8
 000003D0	     6809	LDR R1 [ R1 + 0 ]
 000003D2	     4288	CMP R0 R1
 000003D4	 F0C0800D	BCC #26, goes to  000003F2
 000003D8	     9803	LDR R0 [ SP + 12 ]
 000003DA	     2800	CMP R0 #0
 000003DC	 F0408009	BNE #18, goes to  000003F2
 000003E0	     9806	LDR R0 [ SP + 24 ]
 000003E2	     9904	LDR R1 [ SP + 16 ]
 000003E4	     1840	ADDS R0 R0 R1
 000003E6	     9907	LDR R1 [ SP + 28 ]
 000003E8	     6001	STR R1 [  R0 + 0 ]
 000003EA	     9806	LDR R0 [ SP + 24 ]
 000003EC	     9007	STR R0 [ SP + 28 ]
 000003EE	     9808	LDR R0 [ SP + 32 ]
 000003F0	     9006	STR R0 [ SP + 24 ]
 000003F2	 F000B81A	B #52, goes to  0000042A
 000003F6	     9807	LDR R0 [ SP + 28 ]
 000003F8	     1F00	SUBS R0 R0 #4
 000003FA	     6800	LDR R0 [ R0 + 0 ]
 000003FC	     9003	STR R0 [ SP + 12 ]
 000003FE	     9803	LDR R0 [ SP + 12 ]
 00000400	     6800	LDR R0 [ R0 + 0 ]
 00000402	     9004	STR R0 [ SP + 16 ]
 00000404	     9806	LDR R0 [ SP + 24 ]
 00000406	     9907	LDR R1 [ SP + 28 ]
 00000408	     4288	CMP R0 R1
 0000040A	 F000800E	BEQ #28, goes to  0000042A
 0000040E	     9807	LDR R0 [ SP + 28 ]
 00000410	     9904	LDR R1 [ SP + 16 ]
 00000412	     1840	ADDS R0 R0 R1
 00000414	     6800	LDR R0 [ R0 + 0 ]
 00000416	     9008	STR R0 [ SP + 32 ]
 00000418	     9807	LDR R0 [ SP + 28 ]
 0000041A	     9904	LDR R1 [ SP + 16 ]
 0000041C	     1840	ADDS R0 R0 R1
 0000041E	     9906	LDR R1 [ SP + 24 ]
 00000420	     6001	STR R1 [  R0 + 0 ]
 00000422	     9807	LDR R0 [ SP + 28 ]
 00000424	     9006	STR R0 [ SP + 24 ]
 00000426	     9808	LDR R0 [ SP + 32 ]
 00000428	     9007	STR R0 [ SP + 28 ]
 0000042A	     9806	LDR R0 [ SP + 24 ]
 0000042C	     9907	LDR R1 [ SP + 28 ]
 0000042E	     4288	CMP R0 R1
 00000430	 F47FAFA0	BNE #-192, goes to  00000374
 00000434	     9804	LDR R0 [ SP + 16 ]
 00000436	 F1B03FFF	CMP R0 #-1
 0000043A	     D19B	BNE #-202, goes to  00000374
 0000043C	     9801	LDR R0 [ SP + 4 ]
 0000043E	     1D00	ADDS R0 R0 #4
 00000440	     9001	STR R0 [ SP + 4 ]
 00000442	     9801	LDR R0 [ SP + 4 ]
 00000444	     6800	LDR R0 [ R0 + 0 ]
 00000446	     9002	STR R0 [ SP + 8 ]
 00000448	     E77A	B #-268, goes to  00000340
 0000044A	 F85DEB04	LDR LR [ SP ] + 4
 0000044E	     B008	ADD SP SP #32
 00000450	     4770	BX LR
 00000452	     B086	SUB SP SP #24
 00000454	     B500	PUSH LR
 00000456	 00000047	MOV R0 lower 16-bits base(0), next at  000003C8
 0000045A	 00000008	MOVT R0 higher 16-bits var + 8
 0000045E	     6800	LDR R0 [ R0 + 0 ]
 00000460	     9001	STR R0 [ SP + 4 ]
 00000462	     2000	MOVS R0 #0
 00000464	 F88D0018	STRB R0 [  SP + 24 ]
 00000468	     9801	LDR R0 [ SP + 4 ]
 0000046A	     1D00	ADDS R0 R0 #4
 0000046C	     6800	LDR R0 [ R0 + 0 ]
 0000046E	     9003	STR R0 [ SP + 12 ]
 00000470	     9801	LDR R0 [ SP + 4 ]
 00000472	     9002	STR R0 [ SP + 8 ]
 00000474	 F89D0018	LDRB R0 [ SP + 24 ]
 00000478	     2800	CMP R0 #0
 0000047A	 F0408021	BNE #66, goes to  000004C0
 0000047E	     9803	LDR R0 [ SP + 12 ]
 00000480	     2800	CMP R0 #0
 00000482	 F040801D	BNE #58, goes to  000004C0
 00000486	     9801	LDR R0 [ SP + 4 ]
 00000488	     6800	LDR R0 [ R0 + 0 ]
 0000048A	     9004	STR R0 [ SP + 16 ]
 0000048C	     9804	LDR R0 [ SP + 16 ]
 0000048E	     6800	LDR R0 [ R0 + 0 ]
 00000490	     9005	STR R0 [ SP + 20 ]
 00000492	     9801	LDR R0 [ SP + 4 ]
 00000494	     9905	LDR R1 [ SP + 20 ]
 00000496	     1840	ADDS R0 R0 R1
 00000498	     9001	STR R0 [ SP + 4 ]
 0000049A	     9801	LDR R0 [ SP + 4 ]
 0000049C	 10000023	MOV R1 lower 16-bits base(0), next at  00000456
 000004A0	 0000000C	MOVT R1 higher 16-bits var + 12
 000004A4	     6809	LDR R1 [ R1 + 0 ]
 000004A6	     4288	CMP R0 R1
 000004A8	 F0C08005	BCC #10, goes to  000004B6
 000004AC	     2001	MOVS R0 #1
 000004AE	 F88D0018	STRB R0 [  SP + 24 ]
 000004B2	 F000B804	B #8, goes to  000004BE
 000004B6	     9801	LDR R0 [ SP + 4 ]
 000004B8	     1D00	ADDS R0 R0 #4
 000004BA	     6800	LDR R0 [ R0 + 0 ]
 000004BC	     9003	STR R0 [ SP + 12 ]
 000004BE	     E7D9	B #-78, goes to  00000474
 000004C0	     9801	LDR R0 [ SP + 4 ]
 000004C2	     9902	LDR R1 [ SP + 8 ]
 000004C4	     1A40	SUBS R0 R0 R1
 000004C6	     9005	STR R0 [ SP + 20 ]
 000004C8	 00000016	MOV R0 lower 16-bits base(0), next at  0000049C
 000004CC	 00000000	MOVT R0 higher 16-bits var + 0
 000004D0	     6801	LDR R1 [ R0 + 0 ]
 000004D2	     9A05	LDR R2 [ SP + 20 ]
 000004D4	     1A89	SUBS R1 R1 R2
 000004D6	     6001	STR R1 [  R0 + 0 ]
 000004D8	     9805	LDR R0 [ SP + 20 ]
 000004DA	     2800	CMP R0 #0
 000004DC	 F3408084	BLE #264, goes to  000005E8
 000004E0	     9805	LDR R0 [ SP + 20 ]
 000004E2	 F36F109F	BFC R0 #6 #26
 000004E6	     2800	CMP R0 #0
 000004E8	 F000801C	BEQ #56, goes to  00000524
 000004EC	     9802	LDR R0 [ SP + 8 ]
 000004EE	     2120	MOVS R1 #32
 000004F0	     6001	STR R1 [  R0 + 0 ]
 000004F2	     9802	LDR R0 [ SP + 8 ]
 000004F4	     1D00	ADDS R0 R0 #4
 000004F6	 F05F31FF	MOVS R1 #-1
 000004FA	     6001	STR R1 [  R0 + 0 ]
 000004FC	     9802	LDR R0 [ SP + 8 ]
 000004FE	     3008	ADDS R0 R0 #8
 00000500	 1000001C	MOV R1 lower 16-bits base(0), next at  000004C8
 00000504	 00000030	MOVT R1 higher 16-bits var + 48
 00000508	     6809	LDR R1 [ R1 + 0 ]
 0000050A	     6001	STR R1 [  R0 + 0 ]
 0000050C	     9802	LDR R0 [ SP + 8 ]
 0000050E	 10000007	MOV R1 lower 16-bits base(0), next at  00000500
 00000512	 00000030	MOVT R1 higher 16-bits var + 48
 00000516	     6008	STR R0 [  R1 + 0 ]
 00000518	     9802	LDR R0 [ SP + 8 ]
 0000051A	     3020	ADDS R0 R0 #32
 0000051C	     9002	STR R0 [ SP + 8 ]
 0000051E	     9805	LDR R0 [ SP + 20 ]
 00000520	     3820	SUBS R0 R0 #32
 00000522	     9005	STR R0 [ SP + 20 ]
 00000524	     9805	LDR R0 [ SP + 20 ]
 00000526	 F36F10DF	BFC R0 #7 #25
 0000052A	     2800	CMP R0 #0
 0000052C	 F000801C	BEQ #56, goes to  00000568
 00000530	     9802	LDR R0 [ SP + 8 ]
 00000532	     2140	MOVS R1 #64
 00000534	     6001	STR R1 [  R0 + 0 ]
 00000536	     9802	LDR R0 [ SP + 8 ]
 00000538	     1D00	ADDS R0 R0 #4
 0000053A	 F05F31FF	MOVS R1 #-1
 0000053E	     6001	STR R1 [  R0 + 0 ]
 00000540	     9802	LDR R0 [ SP + 8 ]
 00000542	     3008	ADDS R0 R0 #8
 00000544	 1000001B	MOV R1 lower 16-bits base(0), next at  0000050E
 00000548	 0000002C	MOVT R1 higher 16-bits var + 44
 0000054C	     6809	LDR R1 [ R1 + 0 ]
 0000054E	     6001	STR R1 [  R0 + 0 ]
 00000550	     9802	LDR R0 [ SP + 8 ]
 00000552	 10000007	MOV R1 lower 16-bits base(0), next at  00000544
 00000556	 0000002C	MOVT R1 higher 16-bits var + 44
 0000055A	     6008	STR R0 [  R1 + 0 ]
 0000055C	     9802	LDR R0 [ SP + 8 ]
 0000055E	     3040	ADDS R0 R0 #64
 00000560	     9002	STR R0 [ SP + 8 ]
 00000562	     9805	LDR R0 [ SP + 20 ]
 00000564	     3840	SUBS R0 R0 #64
 00000566	     9005	STR R0 [ SP + 20 ]
 00000568	     9805	LDR R0 [ SP + 20 ]
 0000056A	 F36F201F	BFC R0 #8 #24
 0000056E	     2800	CMP R0 #0
 00000570	 F000801C	BEQ #56, goes to  000005AC
 00000574	     9802	LDR R0 [ SP + 8 ]
 00000576	     2180	MOVS R1 #128
 00000578	     6001	STR R1 [  R0 + 0 ]
 0000057A	     9802	LDR R0 [ SP + 8 ]
 0000057C	     1D00	ADDS R0 R0 #4
 0000057E	 F05F31FF	MOVS R1 #-1
 00000582	     6001	STR R1 [  R0 + 0 ]
 00000584	     9802	LDR R0 [ SP + 8 ]
 00000586	     3008	ADDS R0 R0 #8
 00000588	 1000001B	MOV R1 lower 16-bits base(0), next at  00000552
 0000058C	 00000028	MOVT R1 higher 16-bits var + 40
 00000590	     6809	LDR R1 [ R1 + 0 ]
 00000592	     6001	STR R1 [  R0 + 0 ]
 00000594	     9802	LDR R0 [ SP + 8 ]
 00000596	 10000007	MOV R1 lower 16-bits base(0), next at  00000588
 0000059A	 00000028	MOVT R1 higher 16-bits var + 40
 0000059E	     6008	STR R0 [  R1 + 0 ]
 000005A0	     9802	LDR R0 [ SP + 8 ]
 000005A2	     3080	ADDS R0 R0 #128
 000005A4	     9002	STR R0 [ SP + 8 ]
 000005A6	     9805	LDR R0 [ SP + 20 ]
 000005A8	     3880	SUBS R0 R0 #128
 000005AA	     9005	STR R0 [ SP + 20 ]
 000005AC	     9805	LDR R0 [ SP + 20 ]
 000005AE	     2800	CMP R0 #0
 000005B0	 F340801A	BLE #52, goes to  000005E8
 000005B4	     9802	LDR R0 [ SP + 8 ]
 000005B6	     9905	LDR R1 [ SP + 20 ]
 000005B8	     6001	STR R1 [  R0 + 0 ]
 000005BA	     9802	LDR R0 [ SP + 8 ]
 000005BC	     1D00	ADDS R0 R0 #4
 000005BE	 F05F31FF	MOVS R1 #-1
 000005C2	     6001	STR R1 [  R0 + 0 ]
 000005C4	     9802	LDR R0 [ SP + 8 ]
 000005C6	     3008	ADDS R0 R0 #8
 000005C8	 10000019	MOV R1 lower 16-bits base(0), next at  00000596
 000005CC	 00000024	MOVT R1 higher 16-bits var + 36
 000005D0	     6809	LDR R1 [ R1 + 0 ]
 000005D2	     6001	STR R1 [  R0 + 0 ]
 000005D4	     9802	LDR R0 [ SP + 8 ]
 000005D6	 10000007	MOV R1 lower 16-bits base(0), next at  000005C8
 000005DA	 00000024	MOVT R1 higher 16-bits var + 36
 000005DE	     6008	STR R0 [  R1 + 0 ]
 000005E0	     9802	LDR R0 [ SP + 8 ]
 000005E2	     9905	LDR R1 [ SP + 20 ]
 000005E4	     1840	ADDS R0 R0 R1
 000005E6	     9002	STR R0 [ SP + 8 ]
 000005E8	     9803	LDR R0 [ SP + 12 ]
 000005EA	 F1B03FFF	CMP R0 #-1
 000005EE	 F0408009	BNE #18, goes to  00000604
 000005F2	     9801	LDR R0 [ SP + 4 ]
 000005F4	     6800	LDR R0 [ R0 + 0 ]
 000005F6	     9005	STR R0 [ SP + 20 ]
 000005F8	     9801	LDR R0 [ SP + 4 ]
 000005FA	     9905	LDR R1 [ SP + 20 ]
 000005FC	     1840	ADDS R0 R0 R1
 000005FE	     9001	STR R0 [ SP + 4 ]
 00000600	 F000B812	B #36, goes to  00000628
 00000604	     9803	LDR R0 [ SP + 12 ]
 00000606	     2800	CMP R0 #0
 00000608	 F000800E	BEQ #28, goes to  00000628
 0000060C	     9801	LDR R0 [ SP + 4 ]
 0000060E	     6800	LDR R0 [ R0 + 0 ]
 00000610	     9004	STR R0 [ SP + 16 ]
 00000612	     9804	LDR R0 [ SP + 16 ]
 00000614	     6800	LDR R0 [ R0 + 0 ]
 00000616	     9005	STR R0 [ SP + 20 ]
 00000618	     9801	LDR R0 [ SP + 4 ]
 0000061A	     1D00	ADDS R0 R0 #4
 0000061C	     2100	MOVS R1 #0
 0000061E	     6001	STR R1 [  R0 + 0 ]
 00000620	     9801	LDR R0 [ SP + 4 ]
 00000622	     9905	LDR R1 [ SP + 20 ]
 00000624	     1840	ADDS R0 R0 R1
 00000626	     9001	STR R0 [ SP + 4 ]
 00000628	     9801	LDR R0 [ SP + 4 ]
 0000062A	 1000002A	MOV R1 lower 16-bits base(0), next at  000005D6
 0000062E	 0000000C	MOVT R1 higher 16-bits var + 12
 00000632	     6809	LDR R1 [ R1 + 0 ]
 00000634	     4288	CMP R0 R1
 00000636	 F4FFAF17	BCC #-466, goes to  00000468
 0000063A	 F85DEB04	LDR LR [ SP ] + 4
 0000063E	     B006	ADD SP SP #24
 00000640	     4770	BX LR
 00000642	     B086	SUB SP SP #24
 00000644	     B500	PUSH LR
 00000646	 0000000E	MOV R0 lower 16-bits base(0), next at  0000062A
 0000064A	 00000008	MOVT R0 higher 16-bits var + 8
 0000064E	     6800	LDR R0 [ R0 + 0 ]
 00000650	     9001	STR R0 [ SP + 4 ]
 00000652	     2000	MOVS R0 #0
 00000654	 10000007	MOV R1 lower 16-bits base(0), next at  00000646
 00000658	 00000024	MOVT R1 higher 16-bits var + 36
 0000065C	     6008	STR R0 [  R1 + 0 ]
 0000065E	     2000	MOVS R0 #0
 00000660	 10000006	MOV R1 lower 16-bits base(0), next at  00000654
 00000664	 00000028	MOVT R1 higher 16-bits var + 40
 00000668	     6008	STR R0 [  R1 + 0 ]
 0000066A	     2000	MOVS R0 #0
 0000066C	 10000006	MOV R1 lower 16-bits base(0), next at  00000660
 00000670	 0000002C	MOVT R1 higher 16-bits var + 44
 00000674	     6008	STR R0 [  R1 + 0 ]
 00000676	     2000	MOVS R0 #0
 00000678	 10000006	MOV R1 lower 16-bits base(0), next at  0000066C
 0000067C	 00000030	MOVT R1 higher 16-bits var + 48
 00000680	     6008	STR R0 [  R1 + 0 ]
 00000682	     2000	MOVS R0 #0
 00000684	 F88D0018	STRB R0 [  SP + 24 ]
 00000688	     9801	LDR R0 [ SP + 4 ]
 0000068A	     1D00	ADDS R0 R0 #4
 0000068C	     6800	LDR R0 [ R0 + 0 ]
 0000068E	     9003	STR R0 [ SP + 12 ]
 00000690	     9801	LDR R0 [ SP + 4 ]
 00000692	     9002	STR R0 [ SP + 8 ]
 00000694	 F89D0018	LDRB R0 [ SP + 24 ]
 00000698	     2800	CMP R0 #0
 0000069A	 F040801F	BNE #62, goes to  000006DC
 0000069E	     9803	LDR R0 [ SP + 12 ]
 000006A0	 F1B03FFF	CMP R0 #-1
 000006A4	 F040801A	BNE #52, goes to  000006DC
 000006A8	     9801	LDR R0 [ SP + 4 ]
 000006AA	     6800	LDR R0 [ R0 + 0 ]
 000006AC	     9005	STR R0 [ SP + 20 ]
 000006AE	     9801	LDR R0 [ SP + 4 ]
 000006B0	     9905	LDR R1 [ SP + 20 ]
 000006B2	     1840	ADDS R0 R0 R1
 000006B4	     9001	STR R0 [ SP + 4 ]
 000006B6	     9801	LDR R0 [ SP + 4 ]
 000006B8	 10000020	MOV R1 lower 16-bits base(0), next at  00000678
 000006BC	 0000000C	MOVT R1 higher 16-bits var + 12
 000006C0	     6809	LDR R1 [ R1 + 0 ]
 000006C2	     4288	CMP R0 R1
 000006C4	 F0C08005	BCC #10, goes to  000006D2
 000006C8	     2001	MOVS R0 #1
 000006CA	 F88D0018	STRB R0 [  SP + 24 ]
 000006CE	 F000B804	B #8, goes to  000006DA
 000006D2	     9801	LDR R0 [ SP + 4 ]
 000006D4	     1D00	ADDS R0 R0 #4
 000006D6	     6800	LDR R0 [ R0 + 0 ]
 000006D8	     9003	STR R0 [ SP + 12 ]
 000006DA	     E7DB	B #-74, goes to  00000694
 000006DC	     9801	LDR R0 [ SP + 4 ]
 000006DE	     9902	LDR R1 [ SP + 8 ]
 000006E0	     1A40	SUBS R0 R0 R1
 000006E2	     9005	STR R0 [ SP + 20 ]
 000006E4	     9805	LDR R0 [ SP + 20 ]
 000006E6	     2800	CMP R0 #0
 000006E8	 F3408084	BLE #264, goes to  000007F4
 000006EC	     9805	LDR R0 [ SP + 20 ]
 000006EE	 F36F109F	BFC R0 #6 #26
 000006F2	     2800	CMP R0 #0
 000006F4	 F000801C	BEQ #56, goes to  00000730
 000006F8	     9802	LDR R0 [ SP + 8 ]
 000006FA	     2120	MOVS R1 #32
 000006FC	     6001	STR R1 [  R0 + 0 ]
 000006FE	     9802	LDR R0 [ SP + 8 ]
 00000700	     1D00	ADDS R0 R0 #4
 00000702	 F05F31FF	MOVS R1 #-1
 00000706	     6001	STR R1 [  R0 + 0 ]
 00000708	     9802	LDR R0 [ SP + 8 ]
 0000070A	     3008	ADDS R0 R0 #8
 0000070C	 1000002A	MOV R1 lower 16-bits base(0), next at  000006B8
 00000710	 00000030	MOVT R1 higher 16-bits var + 48
 00000714	     6809	LDR R1 [ R1 + 0 ]
 00000716	     6001	STR R1 [  R0 + 0 ]
 00000718	     9802	LDR R0 [ SP + 8 ]
 0000071A	 10000007	MOV R1 lower 16-bits base(0), next at  0000070C
 0000071E	 00000030	MOVT R1 higher 16-bits var + 48
 00000722	     6008	STR R0 [  R1 + 0 ]
 00000724	     9802	LDR R0 [ SP + 8 ]
 00000726	     3020	ADDS R0 R0 #32
 00000728	     9002	STR R0 [ SP + 8 ]
 0000072A	     9805	LDR R0 [ SP + 20 ]
 0000072C	     3820	SUBS R0 R0 #32
 0000072E	     9005	STR R0 [ SP + 20 ]
 00000730	     9805	LDR R0 [ SP + 20 ]
 00000732	 F36F10DF	BFC R0 #7 #25
 00000736	     2800	CMP R0 #0
 00000738	 F000801C	BEQ #56, goes to  00000774
 0000073C	     9802	LDR R0 [ SP + 8 ]
 0000073E	     2140	MOVS R1 #64
 00000740	     6001	STR R1 [  R0 + 0 ]
 00000742	     9802	LDR R0 [ SP + 8 ]
 00000744	     1D00	ADDS R0 R0 #4
 00000746	 F05F31FF	MOVS R1 #-1
 0000074A	     6001	STR R1 [  R0 + 0 ]
 0000074C	     9802	LDR R0 [ SP + 8 ]
 0000074E	     3008	ADDS R0 R0 #8
 00000750	 1000001B	MOV R1 lower 16-bits base(0), next at  0000071A
 00000754	 0000002C	MOVT R1 higher 16-bits var + 44
 00000758	     6809	LDR R1 [ R1 + 0 ]
 0000075A	     6001	STR R1 [  R0 + 0 ]
 0000075C	     9802	LDR R0 [ SP + 8 ]
 0000075E	 10000007	MOV R1 lower 16-bits base(0), next at  00000750
 00000762	 0000002C	MOVT R1 higher 16-bits var + 44
 00000766	     6008	STR R0 [  R1 + 0 ]
 00000768	     9802	LDR R0 [ SP + 8 ]
 0000076A	     3040	ADDS R0 R0 #64
 0000076C	     9002	STR R0 [ SP + 8 ]
 0000076E	     9805	LDR R0 [ SP + 20 ]
 00000770	     3840	SUBS R0 R0 #64
 00000772	     9005	STR R0 [ SP + 20 ]
 00000774	     9805	LDR R0 [ SP + 20 ]
 00000776	 F36F201F	BFC R0 #8 #24
 0000077A	     2800	CMP R0 #0
 0000077C	 F000801C	BEQ #56, goes to  000007B8
 00000780	     9802	LDR R0 [ SP + 8 ]
 00000782	     2180	MOVS R1 #128
 00000784	     6001	STR R1 [  R0 + 0 ]
 00000786	     9802	LDR R0 [ SP + 8 ]
 00000788	     1D00	ADDS R0 R0 #4
 0000078A	 F05F31FF	MOVS R1 #-1
 0000078E	     6001	STR R1 [  R0 + 0 ]
 00000790	     9802	LDR R0 [ SP + 8 ]
 00000792	     3008	ADDS R0 R0 #8
 00000794	 1000001B	MOV R1 lower 16-bits base(0), next at  0000075E
 00000798	 00000028	MOVT R1 higher 16-bits var + 40
 0000079C	     6809	LDR R1 [ R1 + 0 ]
 0000079E	     6001	STR R1 [  R0 + 0 ]
 000007A0	     9802	LDR R0 [ SP + 8 ]
 000007A2	 10000007	MOV R1 lower 16-bits base(0), next at  00000794
 000007A6	 00000028	MOVT R1 higher 16-bits var + 40
 000007AA	     6008	STR R0 [  R1 + 0 ]
 000007AC	     9802	LDR R0 [ SP + 8 ]
 000007AE	     3080	ADDS R0 R0 #128
 000007B0	     9002	STR R0 [ SP + 8 ]
 000007B2	     9805	LDR R0 [ SP + 20 ]
 000007B4	     3880	SUBS R0 R0 #128
 000007B6	     9005	STR R0 [ SP + 20 ]
 000007B8	     9805	LDR R0 [ SP + 20 ]
 000007BA	     2800	CMP R0 #0
 000007BC	 F340801A	BLE #52, goes to  000007F4
 000007C0	     9802	LDR R0 [ SP + 8 ]
 000007C2	     9905	LDR R1 [ SP + 20 ]
 000007C4	     6001	STR R1 [  R0 + 0 ]
 000007C6	     9802	LDR R0 [ SP + 8 ]
 000007C8	     1D00	ADDS R0 R0 #4
 000007CA	 F05F31FF	MOVS R1 #-1
 000007CE	     6001	STR R1 [  R0 + 0 ]
 000007D0	     9802	LDR R0 [ SP + 8 ]
 000007D2	     3008	ADDS R0 R0 #8
 000007D4	 10000019	MOV R1 lower 16-bits base(0), next at  000007A2
 000007D8	 00000024	MOVT R1 higher 16-bits var + 36
 000007DC	     6809	LDR R1 [ R1 + 0 ]
 000007DE	     6001	STR R1 [  R0 + 0 ]
 000007E0	     9802	LDR R0 [ SP + 8 ]
 000007E2	 10000007	MOV R1 lower 16-bits base(0), next at  000007D4
 000007E6	 00000024	MOVT R1 higher 16-bits var + 36
 000007EA	     6008	STR R0 [  R1 + 0 ]
 000007EC	     9802	LDR R0 [ SP + 8 ]
 000007EE	     9905	LDR R1 [ SP + 20 ]
 000007F0	     1840	ADDS R0 R0 R1
 000007F2	     9002	STR R0 [ SP + 8 ]
 000007F4	 F89D0018	LDRB R0 [ SP + 24 ]
 000007F8	     2800	CMP R0 #0
 000007FA	 F040800F	BNE #30, goes to  0000081C
 000007FE	     9803	LDR R0 [ SP + 12 ]
 00000800	 F1B03FFF	CMP R0 #-1
 00000804	 F000800A	BEQ #20, goes to  0000081C
 00000808	     9801	LDR R0 [ SP + 4 ]
 0000080A	     6800	LDR R0 [ R0 + 0 ]
 0000080C	     9004	STR R0 [ SP + 16 ]
 0000080E	     9804	LDR R0 [ SP + 16 ]
 00000810	     6800	LDR R0 [ R0 + 0 ]
 00000812	     9005	STR R0 [ SP + 20 ]
 00000814	     9801	LDR R0 [ SP + 4 ]
 00000816	     9905	LDR R1 [ SP + 20 ]
 00000818	     1840	ADDS R0 R0 R1
 0000081A	     9001	STR R0 [ SP + 4 ]
 0000081C	     9801	LDR R0 [ SP + 4 ]
 0000081E	 1000001E	MOV R1 lower 16-bits base(0), next at  000007E2
 00000822	 0000000C	MOVT R1 higher 16-bits var + 12
 00000826	     6809	LDR R1 [ R1 + 0 ]
 00000828	     4288	CMP R0 R1
 0000082A	 F4FFAF2D	BCC #-422, goes to  00000688
 0000082E	 F85DEB04	LDR LR [ SP ] + 4
 00000832	     B006	ADD SP SP #24
 00000834	     4770	BX LR
 00000836	     B082	SUB SP SP #8
 00000838	     B500	PUSH LR
 0000083A	     2000	MOVS R0 #0
 0000083C	 1000000F	MOV R1 lower 16-bits base(0), next at  0000081E
 00000840	 00000004	MOVT R1 higher 16-bits var + 4
 00000844	     6008	STR R0 [  R1 + 0 ]
 00000846	     2000	MOVS R0 #0
 00000848	     9001	STR R0 [ SP + 4 ]
 0000084A	     9801	LDR R0 [ SP + 4 ]
 0000084C	     2802	CMP R0 #2
 0000084E	 F2808013	BGE #38, goes to  00000878
 00000852	     9801	LDR R0 [ SP + 4 ]
 00000854	 F5B06F00	CMP R0 #2048
 00000858	     BF28	IT CS
 0000085A	 EC03A541	TrapCS 1 at pos 7508
 0000085E	 10000011	MOV R1 lower 16-bits base(0), next at  0000083C
 00000862	 00000034	MOVT R1 higher 16-bits var + 52
 00000866	 EB110080	ADDS R0 R1 R0 LSL #2
 0000086A	 F05F31FF	MOVS R1 #-1
 0000086E	     6001	STR R1 [  R0 + 0 ]
 00000870	     9801	LDR R0 [ SP + 4 ]
 00000872	     1C40	ADDS R0 R0 #1
 00000874	     9001	STR R0 [ SP + 4 ]
 00000876	     E7E8	B #-48, goes to  0000084A
 00000878	     2000	MOVS R0 #0
 0000087A	     9002	STR R0 [ SP + 8 ]
 0000087C	     9802	LDR R0 [ SP + 8 ]
 0000087E	     2800	CMP R0 #0
 00000880	 F3408019	BLE #50, goes to  000008B6
 00000884	     9801	LDR R0 [ SP + 4 ]
 00000886	 F5B06F00	CMP R0 #2048
 0000088A	     BF28	IT CS
 0000088C	 EC03B2D1	TrapCS 1 at pos 7597
 00000890	 10000019	MOV R1 lower 16-bits base(0), next at  0000085E
 00000894	 00000034	MOVT R1 higher 16-bits var + 52
 00000898	 EB110080	ADDS R0 R1 R0 LSL #2
 0000089C	     9902	LDR R1 [ SP + 8 ]
 0000089E	 F07F0201	MVNS R2 #1
 000008A2	 FA12F101	LSLS R1 R2 R1
 000008A6	 F09131FF	EORS R1 R1 #-1
 000008AA	 F01131FF	ANDS R1 R1 #-1
 000008AE	     6001	STR R1 [  R0 + 0 ]
 000008B0	     9801	LDR R0 [ SP + 4 ]
 000008B2	     1C40	ADDS R0 R0 #1
 000008B4	     9001	STR R0 [ SP + 4 ]
 000008B6	     9801	LDR R0 [ SP + 4 ]
 000008B8	 F5B06F00	CMP R0 #2048
 000008BC	 F2808012	BGE #36, goes to  000008E4
 000008C0	     9801	LDR R0 [ SP + 4 ]
 000008C2	 F5B06F00	CMP R0 #2048
 000008C6	     BF28	IT CS
 000008C8	 EC03B731	TrapCS 1 at pos 7667
 000008CC	 1000001E	MOV R1 lower 16-bits base(0), next at  00000890
 000008D0	 00000034	MOVT R1 higher 16-bits var + 52
 000008D4	 EB110080	ADDS R0 R1 R0 LSL #2
 000008D8	     2100	MOVS R1 #0
 000008DA	     6001	STR R1 [  R0 + 0 ]
 000008DC	     9801	LDR R0 [ SP + 4 ]
 000008DE	     1C40	ADDS R0 R0 #1
 000008E0	     9001	STR R0 [ SP + 4 ]
 000008E2	     E7E8	B #-48, goes to  000008B6
 000008E4	 F85DEB04	LDR LR [ SP ] + 4
 000008E8	     B002	ADD SP SP #8
 000008EA	     4770	BX LR
 000008EC	     B081	SUB SP SP #4
 000008EE	     B401	PUSH R0
 000008F0	     B500	PUSH LR
 000008F2	     9801	LDR R0 [ SP + 4 ]
 000008F4	     211D	MOVS R1 #29
 000008F6	 FBB0F0F1	UDIV R0 R0 R1
 000008FA	     9002	STR R0 [ SP + 8 ]
 000008FC	     9802	LDR R0 [ SP + 8 ]
 000008FE	     211D	MOVS R1 #29
 00000900	     4348	MULS R0 R1 R0
 00000902	     9901	LDR R1 [ SP + 4 ]
 00000904	     4281	CMP R1 R0
 00000906	     BF18	IT NE
 00000908	 EC03D0C7	TrapNE 7 at pos 7820
 0000090C	     9802	LDR R0 [ SP + 8 ]
 0000090E	     1140	ASRS R0 R0 #5
 00000910	 F5B06F00	CMP R0 #2048
 00000914	     BF28	IT CS
 00000916	 EC03D2B1	TrapCS 1 at pos 7851
 0000091A	 10000027	MOV R1 lower 16-bits base(0), next at  000008CC
 0000091E	 00000034	MOVT R1 higher 16-bits var + 52
 00000922	 EB110080	ADDS R0 R1 R0 LSL #2
 00000926	     9902	LDR R1 [ SP + 8 ]
 00000928	 F36F115F	BFC R1 #5 #27
 0000092C	     6802	LDR R2 [ R0 + 0 ]
 0000092E	     2301	MOVS R3 #1
 00000930	 FA13F101	LSLS R1 R3 R1
 00000934	     430A	ORRS R2 R2 R1
 00000936	     6002	STR R2 [  R0 + 0 ]
 00000938	 0000000F	MOV R0 lower 16-bits base(0), next at  0000091A
 0000093C	 00000004	MOVT R0 higher 16-bits var + 4
 00000940	     6801	LDR R1 [ R0 + 0 ]
 00000942	     1C49	ADDS R1 R1 #1
 00000944	     6001	STR R1 [  R0 + 0 ]
 00000946	 F85DEB04	LDR LR [ SP ] + 4
 0000094A	     B002	ADD SP SP #8
 0000094C	     4770	BX LR
 0000094E	     B081	SUB SP SP #4
 00000950	     B401	PUSH R0
 00000952	     B500	PUSH LR
 00000954	     9801	LDR R0 [ SP + 4 ]
 00000956	     211D	MOVS R1 #29
 00000958	 FBB0F0F1	UDIV R0 R0 R1
 0000095C	     9002	STR R0 [ SP + 8 ]
 0000095E	     9802	LDR R0 [ SP + 8 ]
 00000960	     211D	MOVS R1 #29
 00000962	     4348	MULS R0 R1 R0
 00000964	     9901	LDR R1 [ SP + 4 ]
 00000966	     4281	CMP R1 R0
 00000968	     BF18	IT NE
 0000096A	 EC03E517	TrapNE 7 at pos 8017
 0000096E	     9802	LDR R0 [ SP + 8 ]
 00000970	     1140	ASRS R0 R0 #5
 00000972	 F5B06F00	CMP R0 #2048
 00000976	     BF28	IT CS
 00000978	 EC03E701	TrapCS 1 at pos 8048
 0000097C	 10000022	MOV R1 lower 16-bits base(0), next at  00000938
 00000980	 00000034	MOVT R1 higher 16-bits var + 52
 00000984	 EB110080	ADDS R0 R1 R0 LSL #2
 00000988	     9902	LDR R1 [ SP + 8 ]
 0000098A	 F36F115F	BFC R1 #5 #27
 0000098E	     6802	LDR R2 [ R0 + 0 ]
 00000990	     2301	MOVS R3 #1
 00000992	 FA13F101	LSLS R1 R3 R1
 00000996	     438A	BICS R2 R2 R1
 00000998	     6002	STR R2 [  R0 + 0 ]
 0000099A	 0000000F	MOV R0 lower 16-bits base(0), next at  0000097C
 0000099E	 00000004	MOVT R0 higher 16-bits var + 4
 000009A2	     6801	LDR R1 [ R0 + 0 ]
 000009A4	     1E49	SUBS R1 R1 #1
 000009A6	     6001	STR R1 [  R0 + 0 ]
 000009A8	 F85DEB04	LDR LR [ SP ] + 4
 000009AC	     B002	ADD SP SP #8
 000009AE	     4770	BX LR
 000009B0	     B082	SUB SP SP #8
 000009B2	     B403	PUSH R0 R1
 000009B4	     B500	PUSH LR
 000009B6	     9801	LDR R0 [ SP + 4 ]
 000009B8	     211D	MOVS R1 #29
 000009BA	 FBB0F0F1	UDIV R0 R0 R1
 000009BE	     9003	STR R0 [ SP + 12 ]
 000009C0	     9803	LDR R0 [ SP + 12 ]
 000009C2	     211D	MOVS R1 #29
 000009C4	     4348	MULS R0 R1 R0
 000009C6	     9901	LDR R1 [ SP + 4 ]
 000009C8	     4281	CMP R1 R0
 000009CA	     BF18	IT NE
 000009CC	 EC040617	TrapNE 7 at pos 8289
 000009D0	     9803	LDR R0 [ SP + 12 ]
 000009D2	     9004	STR R0 [ SP + 16 ]
 000009D4	     9804	LDR R0 [ SP + 16 ]
 000009D6	     1C40	ADDS R0 R0 #1
 000009D8	     9004	STR R0 [ SP + 16 ]
 000009DA	     9804	LDR R0 [ SP + 16 ]
 000009DC	 F5B03F80	CMP R0 #65536
 000009E0	 F2C08002	BLT #4, goes to  000009E8
 000009E4	     2001	MOVS R0 #1
 000009E6	     9004	STR R0 [ SP + 16 ]
 000009E8	     9804	LDR R0 [ SP + 16 ]
 000009EA	 F36F105F	BFC R0 #5 #27
 000009EE	     9904	LDR R1 [ SP + 16 ]
 000009F0	     1149	ASRS R1 R1 #5
 000009F2	 F5B16F00	CMP R1 #2048
 000009F6	     BF28	IT CS
 000009F8	 EC041531	TrapCS 1 at pos 8403
 000009FC	 20000031	MOV R2 lower 16-bits base(0), next at  0000099A
 00000A00	 00000034	MOVT R2 higher 16-bits var + 52
 00000A04	 EB120181	ADDS R1 R2 R1 LSL #2
 00000A08	     6809	LDR R1 [ R1 + 0 ]
 00000A0A	     1C40	ADDS R0 R0 #1
 00000A0C	     41C1	RORS R1 R1 R0
 00000A0E	 F1408004	BPL #8, goes to  00000A1A
 00000A12	     9804	LDR R0 [ SP + 16 ]
 00000A14	     9903	LDR R1 [ SP + 12 ]
 00000A16	     4288	CMP R0 R1
 00000A18	     D1DC	BNE #-72, goes to  000009D4
 00000A1A	     9804	LDR R0 [ SP + 16 ]
 00000A1C	 F36F105F	BFC R0 #5 #27
 00000A20	     9904	LDR R1 [ SP + 16 ]
 00000A22	     1149	ASRS R1 R1 #5
 00000A24	 F5B16F00	CMP R1 #2048
 00000A28	     BF28	IT CS
 00000A2A	 EC042111	TrapCS 1 at pos 8465
 00000A2E	 20000019	MOV R2 lower 16-bits base(0), next at  000009FC
 00000A32	 00000034	MOVT R2 higher 16-bits var + 52
 00000A36	 EB120181	ADDS R1 R2 R1 LSL #2
 00000A3A	     6809	LDR R1 [ R1 + 0 ]
 00000A3C	     1C40	ADDS R0 R0 #1
 00000A3E	     41C1	RORS R1 R1 R0
 00000A40	     BF48	IT MI
 00000A42	 EC042147	TrapMI 7 at pos 8468
 00000A46	     9804	LDR R0 [ SP + 16 ]
 00000A48	     1140	ASRS R0 R0 #5
 00000A4A	 F5B06F00	CMP R0 #2048
 00000A4E	     BF28	IT CS
 00000A50	 EC042311	TrapCS 1 at pos 8497
 00000A54	 10000013	MOV R1 lower 16-bits base(0), next at  00000A2E
 00000A58	 00000034	MOVT R1 higher 16-bits var + 52
 00000A5C	 EB110080	ADDS R0 R1 R0 LSL #2
 00000A60	     9904	LDR R1 [ SP + 16 ]
 00000A62	 F36F115F	BFC R1 #5 #27
 00000A66	     6802	LDR R2 [ R0 + 0 ]
 00000A68	     2301	MOVS R3 #1
 00000A6A	 FA13F101	LSLS R1 R3 R1
 00000A6E	     430A	ORRS R2 R2 R1
 00000A70	     6002	STR R2 [  R0 + 0 ]
 00000A72	 0000000F	MOV R0 lower 16-bits base(0), next at  00000A54
 00000A76	 00000004	MOVT R0 higher 16-bits var + 4
 00000A7A	     6801	LDR R1 [ R0 + 0 ]
 00000A7C	     1C49	ADDS R1 R1 #1
 00000A7E	     6001	STR R1 [  R0 + 0 ]
 00000A80	     9804	LDR R0 [ SP + 16 ]
 00000A82	     211D	MOVS R1 #29
 00000A84	     4348	MULS R0 R1 R0
 00000A86	     9902	LDR R1 [ SP + 8 ]
 00000A88	     6008	STR R0 [  R1 + 0 ]
 00000A8A	 F85DEB04	LDR LR [ SP ] + 4
 00000A8E	     B004	ADD SP SP #16
 00000A90	     4770	BX LR
 00000A92	     B081	SUB SP SP #4
 00000A94	     B403	PUSH R0 R1
 00000A96	     B500	PUSH LR
 00000A98	     9801	LDR R0 [ SP + 4 ]
 00000A9A	     211D	MOVS R1 #29
 00000A9C	 FBB0F0F1	UDIV R0 R0 R1
 00000AA0	     9003	STR R0 [ SP + 12 ]
 00000AA2	     9803	LDR R0 [ SP + 12 ]
 00000AA4	     211D	MOVS R1 #29
 00000AA6	     4348	MULS R0 R1 R0
 00000AA8	     9901	LDR R1 [ SP + 4 ]
 00000AAA	     4281	CMP R1 R0
 00000AAC	     BF18	IT NE
 00000AAE	 EC043767	TrapNE 7 at pos 8694
 00000AB2	     9803	LDR R0 [ SP + 12 ]
 00000AB4	     0040	LSLS R0 R0 #1
 00000AB6	 F5102000	ADDS R0 R0 #524288
 00000ABA	     9003	STR R0 [ SP + 12 ]
 00000ABC	     9803	LDR R0 [ SP + 12 ]
 00000ABE	     9902	LDR R1 [ SP + 8 ]
 00000AC0	     2202	MOVS R2 #2
 00000AC2	 20400561	BL Mod(  2) proc(4)
 00000AC6	 F85DEB04	LDR LR [ SP ] + 4
 00000ACA	     B003	ADD SP SP #12
 00000ACC	     4770	BX LR
 00000ACE	     B081	SUB SP SP #4
 00000AD0	     B403	PUSH R0 R1
 00000AD2	     B500	PUSH LR
 00000AD4	     9801	LDR R0 [ SP + 4 ]
 00000AD6	     211D	MOVS R1 #29
 00000AD8	 FBB0F0F1	UDIV R0 R0 R1
 00000ADC	     9003	STR R0 [ SP + 12 ]
 00000ADE	     9803	LDR R0 [ SP + 12 ]
 00000AE0	     211D	MOVS R1 #29
 00000AE2	     4348	MULS R0 R1 R0
 00000AE4	     9901	LDR R1 [ SP + 4 ]
 00000AE6	     4281	CMP R1 R0
 00000AE8	     BF18	IT NE
 00000AEA	 EC0460D7	TrapNE 7 at pos 8973
 00000AEE	     9803	LDR R0 [ SP + 12 ]
 00000AF0	     0040	LSLS R0 R0 #1
 00000AF2	 F5102000	ADDS R0 R0 #524288
 00000AF6	     9003	STR R0 [ SP + 12 ]
 00000AF8	     9803	LDR R0 [ SP + 12 ]
 00000AFA	     9902	LDR R1 [ SP + 8 ]
 00000AFC	     2202	MOVS R2 #2
 00000AFE	 2050001E	BL Mod(  2) proc(5)
 00000B02	 F85DEB04	LDR LR [ SP ] + 4
 00000B06	     B003	ADD SP SP #12
 00000B08	     4770	BX LR
 00000B0A	     B500	PUSH LR
 00000B0C	 0000004D	MOV R0 lower 16-bits base(0), next at  00000A72
 00000B10	 00000020	MOVT R0 higher 16-bits var + 32
 00000B14	     6800	LDR R0 [ R0 + 0 ]
 00000B16	 F85DEB04	LDR LR [ SP ] + 4
 00000B1A	     4770	BX LR
 00000B1C	     B084	SUB SP SP #16
 00000B1E	     B500	PUSH LR
 00000B20	 F6420028	MOV R0 #10280
 00000B24	 F2C40000	MOVT R0 #16384
 00000B28	     6800	LDR R0 [ R0 + 0 ]
 00000B2A	     9004	STR R0 [ SP + 16 ]
 00000B2C	 F6420000	MOV R0 #10240
 00000B30	 F2C40000	MOVT R0 #16384
 00000B34	     6800	LDR R0 [ R0 + 0 ]
 00000B36	     9002	STR R0 [ SP + 8 ]
 00000B38	 F6420004	MOV R0 #10244
 00000B3C	 F2C40000	MOVT R0 #16384
 00000B40	     6800	LDR R0 [ R0 + 0 ]
 00000B42	     9001	STR R0 [ SP + 4 ]
 00000B44	 F6420028	MOV R0 #10280
 00000B48	 F2C40000	MOVT R0 #16384
 00000B4C	     6800	LDR R0 [ R0 + 0 ]
 00000B4E	     9003	STR R0 [ SP + 12 ]
 00000B50	     9804	LDR R0 [ SP + 16 ]
 00000B52	     9903	LDR R1 [ SP + 12 ]
 00000B54	     4288	CMP R0 R1
 00000B56	     D1E3	BNE #-58, goes to  00000B20
 00000B58	 F6420004	MOV R0 #10244
 00000B5C	 F2C40000	MOVT R0 #16384
 00000B60	     6800	LDR R0 [ R0 + 0 ]
 00000B62	     9003	STR R0 [ SP + 12 ]
 00000B64	     9801	LDR R0 [ SP + 4 ]
 00000B66	     0D00	LSRS R0 R0 #20
 00000B68	 F36F101F	BFC R0 #4 #28
 00000B6C	     210A	MOVS R1 #10
 00000B6E	     4348	MULS R0 R1 R0
 00000B70	     9901	LDR R1 [ SP + 4 ]
 00000B72	     0C09	LSRS R1 R1 #16
 00000B74	 F36F111F	BFC R1 #4 #28
 00000B78	     1840	ADDS R0 R0 R1
 00000B7A	     0100	LSLS R0 R0 #4
 00000B7C	     9901	LDR R1 [ SP + 4 ]
 00000B7E	     0B09	LSRS R1 R1 #12
 00000B80	 F36F015F	BFC R1 #1 #31
 00000B84	     220A	MOVS R2 #10
 00000B86	     4351	MULS R1 R2 R1
 00000B88	     1840	ADDS R0 R0 R1
 00000B8A	     9901	LDR R1 [ SP + 4 ]
 00000B8C	     0A09	LSRS R1 R1 #8
 00000B8E	 F36F111F	BFC R1 #4 #28
 00000B92	     1840	ADDS R0 R0 R1
 00000B94	     0140	LSLS R0 R0 #5
 00000B96	     9901	LDR R1 [ SP + 4 ]
 00000B98	     0909	LSRS R1 R1 #4
 00000B9A	 F36F019F	BFC R1 #2 #30
 00000B9E	     220A	MOVS R2 #10
 00000BA0	     4351	MULS R1 R2 R1
 00000BA2	     1840	ADDS R0 R0 R1
 00000BA4	     9901	LDR R1 [ SP + 4 ]
 00000BA6	 F36F111F	BFC R1 #4 #28
 00000BAA	     1840	ADDS R0 R0 R1
 00000BAC	     0140	LSLS R0 R0 #5
 00000BAE	     9902	LDR R1 [ SP + 8 ]
 00000BB0	     0D09	LSRS R1 R1 #20
 00000BB2	 F36F019F	BFC R1 #2 #30
 00000BB6	     220A	MOVS R2 #10
 00000BB8	     4351	MULS R1 R2 R1
 00000BBA	     1840	ADDS R0 R0 R1
 00000BBC	     9902	LDR R1 [ SP + 8 ]
 00000BBE	     0C09	LSRS R1 R1 #16
 00000BC0	 F36F111F	BFC R1 #4 #28
 00000BC4	     1840	ADDS R0 R0 R1
 00000BC6	     0180	LSLS R0 R0 #6
 00000BC8	     9902	LDR R1 [ SP + 8 ]
 00000BCA	     0B09	LSRS R1 R1 #12
 00000BCC	 F36F01DF	BFC R1 #3 #29
 00000BD0	     220A	MOVS R2 #10
 00000BD2	     4351	MULS R1 R2 R1
 00000BD4	     1840	ADDS R0 R0 R1
 00000BD6	     9902	LDR R1 [ SP + 8 ]
 00000BD8	     0A09	LSRS R1 R1 #8
 00000BDA	 F36F111F	BFC R1 #4 #28
 00000BDE	     1840	ADDS R0 R0 R1
 00000BE0	     0180	LSLS R0 R0 #6
 00000BE2	     9902	LDR R1 [ SP + 8 ]
 00000BE4	     0909	LSRS R1 R1 #4
 00000BE6	 F36F01DF	BFC R1 #3 #29
 00000BEA	     220A	MOVS R2 #10
 00000BEC	     4351	MULS R1 R2 R1
 00000BEE	     1840	ADDS R0 R0 R1
 00000BF0	     9902	LDR R1 [ SP + 8 ]
 00000BF2	 F36F111F	BFC R1 #4 #28
 00000BF6	     1840	ADDS R0 R0 R1
 00000BF8	 F85DEB04	LDR LR [ SP ] + 4
 00000BFC	     B004	ADD SP SP #16
 00000BFE	     4770	BX LR
 00000C00	     B088	SUB SP SP #32
 00000C02	     B401	PUSH R0
 00000C04	     B500	PUSH LR
 00000C06	     9801	LDR R0 [ SP + 4 ]
 00000C08	     0E80	LSRS R0 R0 #26
 00000C0A	     9007	STR R0 [ SP + 28 ]
 00000C0C	     9801	LDR R0 [ SP + 4 ]
 00000C0E	     0D80	LSRS R0 R0 #22
 00000C10	 F36F101F	BFC R0 #4 #28
 00000C14	     9008	STR R0 [ SP + 32 ]
 00000C16	     9801	LDR R0 [ SP + 4 ]
 00000C18	     0C40	LSRS R0 R0 #17
 00000C1A	 F36F105F	BFC R0 #5 #27
 00000C1E	     9009	STR R0 [ SP + 36 ]
 00000C20	     9807	LDR R0 [ SP + 28 ]
 00000C22	     210A	MOVS R1 #10
 00000C24	 FBB0F0F1	UDIV R0 R0 R1
 00000C28	     0500	LSLS R0 R0 #20
 00000C2A	     9907	LDR R1 [ SP + 28 ]
 00000C2C	     220A	MOVS R2 #10
 00000C2E	 FBB1F3F2	UDIV R3 R1 R2
 00000C32	     4353	MULS R3 R2 R3
 00000C34	     1AC9	SUBS R1 R1 R3
 00000C36	     0409	LSLS R1 R1 #16
 00000C38	     1840	ADDS R0 R0 R1
 00000C3A	     9908	LDR R1 [ SP + 32 ]
 00000C3C	     220A	MOVS R2 #10
 00000C3E	 FBB1F1F2	UDIV R1 R1 R2
 00000C42	     0309	LSLS R1 R1 #12
 00000C44	     1840	ADDS R0 R0 R1
 00000C46	     9908	LDR R1 [ SP + 32 ]
 00000C48	     220A	MOVS R2 #10
 00000C4A	 FBB1F3F2	UDIV R3 R1 R2
 00000C4E	     4353	MULS R3 R2 R3
 00000C50	     1AC9	SUBS R1 R1 R3
 00000C52	     0209	LSLS R1 R1 #8
 00000C54	     1840	ADDS R0 R0 R1
 00000C56	     9909	LDR R1 [ SP + 36 ]
 00000C58	     220A	MOVS R2 #10
 00000C5A	 FBB1F1F2	UDIV R1 R1 R2
 00000C5E	     0109	LSLS R1 R1 #4
 00000C60	     1840	ADDS R0 R0 R1
 00000C62	     9909	LDR R1 [ SP + 36 ]
 00000C64	     220A	MOVS R2 #10
 00000C66	 FBB1F3F2	UDIV R3 R1 R2
 00000C6A	     4353	MULS R3 R2 R3
 00000C6C	     1AC9	SUBS R1 R1 R3
 00000C6E	     1840	ADDS R0 R0 R1
 00000C70	     9002	STR R0 [ SP + 8 ]
 00000C72	     9801	LDR R0 [ SP + 4 ]
 00000C74	     0B00	LSRS R0 R0 #12
 00000C76	 F36F105F	BFC R0 #5 #27
 00000C7A	     9004	STR R0 [ SP + 16 ]
 00000C7C	     9801	LDR R0 [ SP + 4 ]
 00000C7E	     0980	LSRS R0 R0 #6
 00000C80	 F36F109F	BFC R0 #6 #26
 00000C84	     9005	STR R0 [ SP + 20 ]
 00000C86	     9801	LDR R0 [ SP + 4 ]
 00000C88	 F36F109F	BFC R0 #6 #26
 00000C8C	     9006	STR R0 [ SP + 24 ]
 00000C8E	     9804	LDR R0 [ SP + 16 ]
 00000C90	     210A	MOVS R1 #10
 00000C92	 FBB0F0F1	UDIV R0 R0 R1
 00000C96	     0500	LSLS R0 R0 #20
 00000C98	     9904	LDR R1 [ SP + 16 ]
 00000C9A	     220A	MOVS R2 #10
 00000C9C	 FBB1F3F2	UDIV R3 R1 R2
 00000CA0	     4353	MULS R3 R2 R3
 00000CA2	     1AC9	SUBS R1 R1 R3
 00000CA4	     0409	LSLS R1 R1 #16
 00000CA6	     1840	ADDS R0 R0 R1
 00000CA8	     9905	LDR R1 [ SP + 20 ]
 00000CAA	     220A	MOVS R2 #10
 00000CAC	 FBB1F1F2	UDIV R1 R1 R2
 00000CB0	     0309	LSLS R1 R1 #12
 00000CB2	     1840	ADDS R0 R0 R1
 00000CB4	     9905	LDR R1 [ SP + 20 ]
 00000CB6	     220A	MOVS R2 #10
 00000CB8	 FBB1F3F2	UDIV R3 R1 R2
 00000CBC	     4353	MULS R3 R2 R3
 00000CBE	     1AC9	SUBS R1 R1 R3
 00000CC0	     0209	LSLS R1 R1 #8
 00000CC2	     1840	ADDS R0 R0 R1
 00000CC4	     9906	LDR R1 [ SP + 24 ]
 00000CC6	     220A	MOVS R2 #10
 00000CC8	 FBB1F1F2	UDIV R1 R1 R2
 00000CCC	     0109	LSLS R1 R1 #4
 00000CCE	     1840	ADDS R0 R0 R1
 00000CD0	     9906	LDR R1 [ SP + 24 ]
 00000CD2	     220A	MOVS R2 #10
 00000CD4	 FBB1F3F2	UDIV R3 R1 R2
 00000CD8	     4353	MULS R3 R2 R3
 00000CDA	     1AC9	SUBS R1 R1 R3
 00000CDC	     1840	ADDS R0 R0 R1
 00000CDE	     9003	STR R0 [ SP + 12 ]
 00000CE0	 F6420024	MOV R0 #10276
 00000CE4	 F2C40000	MOVT R0 #16384
 00000CE8	     21CA	MOVS R1 #202
 00000CEA	     6001	STR R1 [  R0 + 0 ]
 00000CEC	 F6420024	MOV R0 #10276
 00000CF0	 F2C40000	MOVT R0 #16384
 00000CF4	     2153	MOVS R1 #83
 00000CF6	     6001	STR R1 [  R0 + 0 ]
 00000CF8	 F240109C	MOV R0 #412
 00000CFC	 F2C42005	MOVT R0 #16901
 00000D00	     2101	MOVS R1 #1
 00000D02	     7001	STRB R1 [ R0 + 0 ]
 00000D04	 F2401098	MOV R0 #408
 00000D08	 F2C42005	MOVT R0 #16901
 00000D0C	     6800	LDR R0 [ R0 + 0 ]
 00000D0E	     2800	CMP R0 #0
 00000D10	     D0F8	BEQ #-16, goes to  00000D04
 00000D12	 F6420000	MOV R0 #10240
 00000D16	 F2C40000	MOVT R0 #16384
 00000D1A	     9903	LDR R1 [ SP + 12 ]
 00000D1C	     6001	STR R1 [  R0 + 0 ]
 00000D1E	 F6420004	MOV R0 #10244
 00000D22	 F2C40000	MOVT R0 #16384
 00000D26	     9902	LDR R1 [ SP + 8 ]
 00000D28	     6001	STR R1 [  R0 + 0 ]
 00000D2A	 F240109C	MOV R0 #412
 00000D2E	 F2C42005	MOVT R0 #16901
 00000D32	     2100	MOVS R1 #0
 00000D34	     7001	STRB R1 [ R0 + 0 ]
 00000D36	 F6420024	MOV R0 #10276
 00000D3A	 F2C40000	MOVT R0 #16384
 00000D3E	     21FF	MOVS R1 #255
 00000D40	     6001	STR R1 [  R0 + 0 ]
 00000D42	 F85DEB04	LDR LR [ SP ] + 4
 00000D46	     B009	ADD SP SP #36
 00000D48	     4770	BX LR
 00000D4A	     B403	PUSH R0 R1
 00000D4C	     B500	PUSH LR
 00000D4E	     9802	LDR R0 [ SP + 8 ]
 00000D50	     9901	LDR R1 [ SP + 4 ]
 00000D52	     6001	STR R1 [  R0 + 0 ]
 00000D54	 F85DEB04	LDR LR [ SP ] + 4
 00000D58	     B002	ADD SP SP #8
 00000D5A	     4770	BX LR
 00000D5C	     B500	PUSH LR
 00000D5E	     4668	MOV R0 SP
 00000D60	 1000012A	MOV R1 lower 16-bits base(0), next at  00000B0C
 00000D64	 0000001C	MOVT R1 higher 16-bits var + 28
 00000D68	     6809	LDR R1 [ R1 + 0 ]
 00000D6A	     4288	CMP R0 R1
 00000D6C	 F2808006	BGE #12, goes to  00000D7C
 00000D70	     4668	MOV R0 SP
 00000D72	 10000009	MOV R1 lower 16-bits base(0), next at  00000D60
 00000D76	 0000001C	MOVT R1 higher 16-bits var + 28
 00000D7A	     6008	STR R0 [  R1 + 0 ]
 00000D7C	 F85DEB04	LDR LR [ SP ] + 4
 00000D80	     4770	BX LR
 00000D82	 F01E0F04	TST LR #4
 00000D86	     BF0C	ITE EQ
 00000D88	 F3EF8008	MRSEQ R0 MSP
 00000D8C	 F3EF8009	MRSNE R0 PSP
 00000D90	     B082	SUB SP SP #8
 00000D92	     B403	PUSH R0 R1
 00000D94	     B500	PUSH LR
 00000D96	     9801	LDR R0 [ SP + 4 ]
 00000D98	     6980	LDR R0 [ R0 + 24 ]
 00000D9A	     6800	LDR R0 [ R0 + 0 ]
 00000D9C	     9003	STR R0 [ SP + 12 ]
 00000D9E	     9803	LDR R0 [ SP + 12 ]
 00000DA0	     1400	ASRS R0 R0 #16
 00000DA2	 F36F101F	BFC R0 #4 #28
 00000DA6	     9004	STR R0 [ SP + 16 ]
 00000DA8	     9804	LDR R0 [ SP + 16 ]
 00000DAA	     3040	ADDS R0 R0 #64
 00000DAC	 10300157	BL Mod(  1) proc(3)
 00000DB0	     E7FE	B #-4, goes to  00000DB0
 00000DB2	 F85DEB04	LDR LR [ SP ] + 4
 00000DB6	     B004	ADD SP SP #16
 00000DB8	     4770	BX LR
 00000DBA	     B500	PUSH LR
 00000DBC	 00000025	MOV R0 lower 16-bits base(0), next at  00000D72
 00000DC0	 00000020	MOVT R0 higher 16-bits var + 32
 00000DC4	     6801	LDR R1 [ R0 + 0 ]
 00000DC6	     1C49	ADDS R1 R1 #1
 00000DC8	     6001	STR R1 [  R0 + 0 ]
 00000DCA	 F7FFFFC7	BL #-114, goes to  00000D5C
 00000DCE	 F85DEB04	LDR LR [ SP ] + 4
 00000DD2	     4770	BX LR
 00000DD4	 F01E0F04	TST LR #4
 00000DD8	     BF0C	ITE EQ
 00000DDA	 F3EF8008	MRSEQ R0 MSP
 00000DDE	 F3EF8009	MRSNE R0 PSP
 00000DE2	     B081	SUB SP SP #4
 00000DE4	     B403	PUSH R0 R1
 00000DE6	     B500	PUSH LR
 00000DE8	     9801	LDR R0 [ SP + 4 ]
 00000DEA	     6980	LDR R0 [ R0 + 24 ]
 00000DEC	     1E80	SUBS R0 R0 #2
 00000DEE	     7800	LDRB R0 [ R0 + 0 ]
 00000DF0	 F88D000C	STRB R0 [  SP + 12 ]
 00000DF4	 F89D000C	LDRB R0 [ SP + 12 ]
 00000DF8	     2800	CMP R0 #0
 00000DFA	 F0408008	BNE #16, goes to  00000E0E
 00000DFE	     9801	LDR R0 [ SP + 4 ]
 00000E00	     6800	LDR R0 [ R0 + 0 ]
 00000E02	     9901	LDR R1 [ SP + 4 ]
 00000E04	     6849	LDR R1 [ R1 + 4 ]
 00000E06	 F7FFFA3E	BL #-2948, goes to  00000286
 00000E0A	 F000B814	B #40, goes to  00000E36
 00000E0E	 F89D000C	LDRB R0 [ SP + 12 ]
 00000E12	     2801	CMP R0 #1
 00000E14	 F0408006	BNE #12, goes to  00000E24
 00000E18	     9801	LDR R0 [ SP + 4 ]
 00000E1A	     6800	LDR R0 [ R0 + 0 ]
 00000E1C	 10300038	BL Mod(  1) proc(3)
 00000E20	 F000B809	B #18, goes to  00000E36
 00000E24	 F89D000C	LDRB R0 [ SP + 12 ]
 00000E28	     2802	CMP R0 #2
 00000E2A	 F0408004	BNE #8, goes to  00000E36
 00000E2E	     9801	LDR R0 [ SP + 4 ]
 00000E30	     9902	LDR R1 [ SP + 8 ]
 00000E32	 3020000B	BL Mod(  3) proc(2)
 00000E36	 F7FFFF91	BL #-222, goes to  00000D5C
 00000E3A	 F85DEB04	LDR LR [ SP ] + 4
 00000E3E	     B003	ADD SP SP #12
 00000E40	     4770	BX LR
 00000E42	     B500	PUSH LR
 00000E44	     2080	MOVS R0 #128
 00000E46	 1030000A	BL Mod(  1) proc(3)
 00000E4A	 F2427010	MOV R0 #10000
 00000E4E	 10200004	BL Mod(  1) proc(2)
 00000E52	     2000	MOVS R0 #0
 00000E54	 10300003	BL Mod(  1) proc(3)
 00000E58	 F2427010	MOV R0 #10000
 00000E5C	 10200004	BL Mod(  1) proc(2)
 00000E60	     E7F0	B #-32, goes to  00000E44
 00000E62	 F85DEB04	LDR LR [ SP ] + 4
 00000E66	     4770	BX LR
 00000E68	     B081	SUB SP SP #4
 00000E6A	     B500	PUSH LR
 00000E6C	     2006	MOVS R0 #6
 00000E6E	     9001	STR R0 [ SP + 4 ]
 00000E70	     9801	LDR R0 [ SP + 4 ]
 00000E72	     1140	ASRS R0 R0 #5
 00000E74	     0080	LSLS R0 R0 #2
 00000E76	 F24E1180	MOV R1 #57728
 00000E7A	 F2CE0100	MOVT R1 #57344
 00000E7E	     1808	ADDS R0 R1 R0
 00000E80	     9901	LDR R1 [ SP + 4 ]
 00000E82	 F36F115F	BFC R1 #5 #27
 00000E86	     2201	MOVS R2 #1
 00000E88	 FA12F101	LSLS R1 R2 R1
 00000E8C	     6001	STR R1 [  R0 + 0 ]
 00000E8E	 F85DEB04	LDR LR [ SP ] + 4
 00000E92	     B001	ADD SP SP #4
 00000E94	     4770	BX LR
 00000E96	     B081	SUB SP SP #4
 00000E98	     B500	PUSH LR
 00000E9A	     2006	MOVS R0 #6
 00000E9C	     9001	STR R0 [ SP + 4 ]
 00000E9E	     9801	LDR R0 [ SP + 4 ]
 00000EA0	     1140	ASRS R0 R0 #5
 00000EA2	     0080	LSLS R0 R0 #2
 00000EA4	 F24E1100	MOV R1 #57600
 00000EA8	 F2CE0100	MOVT R1 #57344
 00000EAC	     1808	ADDS R0 R1 R0
 00000EAE	     9901	LDR R1 [ SP + 4 ]
 00000EB0	 F36F115F	BFC R1 #5 #27
 00000EB4	     2201	MOVS R2 #1
 00000EB6	 FA12F101	LSLS R1 R2 R1
 00000EBA	     6001	STR R1 [  R0 + 0 ]
 00000EBC	 F85DEB04	LDR LR [ SP ] + 4
 00000EC0	     B001	ADD SP SP #4
 00000EC2	     4770	BX LR
 00000EC4	     B081	SUB SP SP #4
 00000EC6	     B500	PUSH LR
 00000EC8	 F05F6000	MOVS R0 #134217728
 00000ECC	     6800	LDR R0 [ R0 + 0 ]
 00000ECE	     9001	STR R0 [ SP + 4 ]
 00000ED0	 F05F5000	MOVS R0 #536870912
 00000ED4	     9901	LDR R1 [ SP + 4 ]
 00000ED6	     6001	STR R1 [  R0 + 0 ]
 00000ED8	     2004	MOVS R0 #4
 00000EDA	 F6C00000	MOVT R0 #2048
 00000EDE	     6800	LDR R0 [ R0 + 0 ]
 00000EE0	     9001	STR R0 [ SP + 4 ]
 00000EE2	     2004	MOVS R0 #4
 00000EE4	 F2C20000	MOVT R0 #8192
 00000EE8	     9901	LDR R1 [ SP + 4 ]
 00000EEA	     6001	STR R1 [  R0 + 0 ]
 00000EEC	     2008	MOVS R0 #8
 00000EEE	 F2C20000	MOVT R0 #8192
 00000EF2	 F24011A8	MOV R1 #424
 00000EF6	 F2C20100	MOVT R1 #8192
 00000EFA	     4281	CMP R1 R0
 00000EFC	 F2C08008	BLT #16, goes to  00000F10
 00000F00	     9001	STR R0 [ SP + 4 ]
 00000F02	 F2AF00C1	ADR R0 L 00000E43
 00000F06	     9901	LDR R1 [ SP + 4 ]
 00000F08	     6008	STR R0 [  R1 + 0 ]
 00000F0A	     9801	LDR R0 [ SP + 4 ]
 00000F0C	     1D00	ADDS R0 R0 #4
 00000F0E	     E7F0	B #-32, goes to  00000EF2
 00000F10	 F64E5008	MOV R0 #60680
 00000F14	 F2CE0000	MOVT R0 #57344
 00000F18	 F05F5100	MOVS R1 #536870912
 00000F1C	     6001	STR R1 [  R0 + 0 ]
 00000F1E	 F64E5088	MOV R0 #60808
 00000F22	 F2CE0000	MOVT R0 #57344
 00000F26	 F45F0170	MOVS R1 #15728640
 00000F2A	     6001	STR R1 [  R0 + 0 ]
 00000F2C	 10900068	BL Mod(  1) proc(9)
 00000F30	 F2AF10B1	ADR R0 L 00000D83
 00000F34	     2118	MOVS R1 #24
 00000F36	 F2C20100	MOVT R1 #8192
 00000F3A	 F7FFFF06	BL #-500, goes to  00000D4A
 00000F3E	 F2AF1085	ADR R0 L 00000DBB
 00000F42	     213C	MOVS R1 #60
 00000F44	 F2C20100	MOVT R1 #8192
 00000F48	 F7FFFEFF	BL #-514, goes to  00000D4A
 00000F4C	 F24E0018	MOV R0 #57368
 00000F50	 F2CE0000	MOVT R0 #57344
 00000F54	     2100	MOVS R1 #0
 00000F56	     6001	STR R1 [  R0 + 0 ]
 00000F58	 F24E0010	MOV R0 #57360
 00000F5C	 F2CE0000	MOVT R0 #57344
 00000F60	     2107	MOVS R1 #7
 00000F62	     6001	STR R1 [  R0 + 0 ]
 00000F64	 F2AF1093	ADR R0 L 00000DD5
 00000F68	     212C	MOVS R1 #44
 00000F6A	 F2C20100	MOVT R1 #8192
 00000F6E	 F7FFFEEC	BL #-552, goes to  00000D4A
 00000F72	 F241000C	MOV R0 #4108
 00000F76	 F2CD0020	MOVT R0 #53280
 00000F7A	     6800	LDR R0 [ R0 + 0 ]
 00000F7C	 100000E0	MOV R1 lower 16-bits base(0), next at  00000DBC
 00000F80	 00000018	MOVT R1 higher 16-bits var + 24
 00000F84	     6008	STR R0 [  R1 + 0 ]
 00000F86	 F2410018	MOV R0 #4120
 00000F8A	 F2CD0020	MOVT R0 #53280
 00000F8E	     6800	LDR R0 [ R0 + 0 ]
 00000F90	 1000000A	MOV R1 lower 16-bits base(0), next at  00000F7C
 00000F94	 00000010	MOVT R1 higher 16-bits var + 16
 00000F98	     6008	STR R0 [  R1 + 0 ]
 00000F9A	 F241001C	MOV R0 #4124
 00000F9E	 F2CD0020	MOVT R0 #53280
 00000FA2	     6800	LDR R0 [ R0 + 0 ]
 00000FA4	 1000000A	MOV R1 lower 16-bits base(0), next at  00000F90
 00000FA8	 00000008	MOVT R1 higher 16-bits var + 8
 00000FAC	     6008	STR R0 [  R1 + 0 ]
 00000FAE	 F45F3080	MOVS R0 #65536
 00000FB2	 10000007	MOV R1 lower 16-bits base(0), next at  00000FA4
 00000FB6	 00000014	MOVT R1 higher 16-bits var + 20
 00000FBA	     6008	STR R0 [  R1 + 0 ]
 00000FBC	 00000005	MOV R0 lower 16-bits base(0), next at  00000FB2
 00000FC0	 00000018	MOVT R0 higher 16-bits var + 24
 00000FC4	     6800	LDR R0 [ R0 + 0 ]
 00000FC6	 10000005	MOV R1 lower 16-bits base(0), next at  00000FBC
 00000FCA	 0000000C	MOVT R1 higher 16-bits var + 12
 00000FCE	     6008	STR R0 [  R1 + 0 ]
 00000FD0	     2000	MOVS R0 #0
 00000FD2	 10000006	MOV R1 lower 16-bits base(0), next at  00000FC6
 00000FD6	 00000028	MOVT R1 higher 16-bits var + 40
 00000FDA	     6008	STR R0 [  R1 + 0 ]
 00000FDC	     2000	MOVS R0 #0
 00000FDE	 10000006	MOV R1 lower 16-bits base(0), next at  00000FD2
 00000FE2	 0000002C	MOVT R1 higher 16-bits var + 44
 00000FE6	     6008	STR R0 [  R1 + 0 ]
 00000FE8	     2000	MOVS R0 #0
 00000FEA	 10000006	MOV R1 lower 16-bits base(0), next at  00000FDE
 00000FEE	 00000030	MOVT R1 higher 16-bits var + 48
 00000FF2	     6008	STR R0 [  R1 + 0 ]
 00000FF4	 00000005	MOV R0 lower 16-bits base(0), next at  00000FEA
 00000FF8	 00000008	MOVT R0 higher 16-bits var + 8
 00000FFC	     6800	LDR R0 [ R0 + 0 ]
 00000FFE	 10000005	MOV R1 lower 16-bits base(0), next at  00000FF4
 00001002	 00000024	MOVT R1 higher 16-bits var + 36
 00001006	     6008	STR R0 [  R1 + 0 ]
 00001008	 00000005	MOV R0 lower 16-bits base(0), next at  00000FFE
 0000100C	 0000000C	MOVT R0 higher 16-bits var + 12
 00001010	     6800	LDR R0 [ R0 + 0 ]
 00001012	 10000005	MOV R1 lower 16-bits base(0), next at  00001008
 00001016	 00000008	MOVT R1 higher 16-bits var + 8
 0000101A	     6809	LDR R1 [ R1 + 0 ]
 0000101C	     1A40	SUBS R0 R0 R1
 0000101E	 10000006	MOV R1 lower 16-bits base(0), next at  00001012
 00001022	 00000024	MOVT R1 higher 16-bits var + 36
 00001026	     6809	LDR R1 [ R1 + 0 ]
 00001028	     6008	STR R0 [  R1 + 0 ]
 0000102A	 00000006	MOV R0 lower 16-bits base(0), next at  0000101E
 0000102E	 00000024	MOVT R0 higher 16-bits var + 36
 00001032	     6800	LDR R0 [ R0 + 0 ]
 00001034	     1D00	ADDS R0 R0 #4
 00001036	 F05F31FF	MOVS R1 #-1
 0000103A	     6001	STR R1 [  R0 + 0 ]
 0000103C	 00000009	MOV R0 lower 16-bits base(0), next at  0000102A
 00001040	 00000024	MOVT R0 higher 16-bits var + 36
 00001044	     6800	LDR R0 [ R0 + 0 ]
 00001046	     3008	ADDS R0 R0 #8
 00001048	     2100	MOVS R1 #0
 0000104A	     6001	STR R1 [  R0 + 0 ]
 0000104C	     2000	MOVS R0 #0
 0000104E	 10000009	MOV R1 lower 16-bits base(0), next at  0000103C
 00001052	 00000000	MOVT R1 higher 16-bits var + 0
 00001056	     6008	STR R0 [  R1 + 0 ]
 00001058	 F07F4000	MVNS R0 # -2147483648
 0000105C	 10000007	MOV R1 lower 16-bits base(0), next at  0000104E
 00001060	 0000001C	MOVT R1 higher 16-bits var + 28
 00001064	     6008	STR R0 [  R1 + 0 ]
 00001066	 F7FFFBE6	BL #-2100, goes to  00000836
 0000106A	 F85DEB04	LDR LR [ SP ] + 4
 0000106E	     B001	ADD SP SP #4
 00001070	     4770	BX LR
 00001072	     B500	PUSH LR
 00001074	 F7FFFF26	BL #-436, goes to  00000EC4
 00001078	 F85DEB04	LDR LR [ SP ] + 4
 0000107C	     4770	BX LR
