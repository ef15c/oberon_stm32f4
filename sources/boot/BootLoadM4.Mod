(*
OM4P.Compile @  
OM4X.WriteASM BootLoadM4.m4c BootLoadM4.s ~
OM4X.WriteFile BootLoadM4.m4c BootLoadM4.hex 0F000000H ~
*)

MODULE* BootLoadM4;  (*NW 20.10.2013 / PR 4.2.2014 / CS 09/12/2023; boot from SDHC disk only*)
  IMPORT SYSTEM;
  CONST SP = 13; LR = 14; PC = 15; (*dedicated registers*)
    VarORG0 = 0D0201000H; MemLim = 0D0800000H; stackOrg = 10010000H;

    (*Peripherals*)
    PeriphBase* = 40000000H; PeriphBBAlias* = 42000000H;

    (*LEDs*)
    GPIOC* = 40020800H; GPIOG* = 40021800H; IDR = 10H; ODR = 14H; BSRR = 18H;
    LED2Pin* = 3; LED2Port* = GPIOC;
    LED2Out* = PeriphBBAlias + (LED2Port + ODR - PeriphBase + LED2Pin DIV 8)*32 + LED2Pin MOD 8*4;
    LED7Pin* = 3; LED7Port* = GPIOG;
    LED7Out* = PeriphBBAlias + (LED7Port + ODR - PeriphBase + LED7Pin DIV 8)*32 + LED7Pin MOD 8*4;

    (*Push buttons*)
    PB2Pin* = 15; PB2Port* = GPIOC;
    PB2In* = PeriphBBAlias + (PB2Port + IDR - PeriphBase + PB2Pin DIV 8)*32 + PB2Pin MOD 8*4;

    FSoffset = 80000H;   (*block offset*)
    SectorSize = 1024;

(* ---------- disk ------------*)

  PROCEDURE LoadFromDisk;
    VAR bb, r, lim, ss, bps: INTEGER;
     pb2up: BOOLEAN;
  BEGIN SYSTEM.GET(PB2In, pb2up);
    IF ~pb2up THEN bb := FSoffset; ss := SectorSize (*Fixed address boot*)
    ELSE (*find boot block position*)
      SYSTEM.LDREG(0, FSoffset); SYSTEM.LDREG(1, VarORG0); SYSTEM.LDREG(2, 1); r := SYSTEM.SVC(2);
      SYSTEM.GET(VarORG0 + 12, bb); IF bb = 0 THEN bb := FSoffset; ss := SectorSize ELSE SYSTEM.GET(VarORG0 + 16, ss); END
    END;
    bps := ss DIV 512;
    (*start at boot block*)
    SYSTEM.LDREG(0, bb + 2*bps); SYSTEM.LDREG(1, VarORG0); SYSTEM.LDREG(2, bps); r := SYSTEM.SVC(2);
    SYSTEM.GET(VarORG0 + 16, lim);
    (*read remaining blocks*)
    r := (lim + (511- VarORG0)) DIV 512 - bps;
    IF r > 0 THEN SYSTEM.LDREG(0, bb + 2*(bps+1)); SYSTEM.LDREG(1, VarORG0+ss); SYSTEM.LDREG(2, r); r := SYSTEM.SVC(2) END
  END LoadFromDisk;

BEGIN
  SYSTEM.PUT(LED2Out, TRUE); SYSTEM.PUT(LED7Out, TRUE); LoadFromDisk;
  SYSTEM.PUT(VarORG0+12, MemLim); SYSTEM.PUT(VarORG0+24, stackOrg); LED(44H)
END BootLoadM4.
