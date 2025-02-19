MODULE FLASH;
  IMPORT SYSTEM, BSP;

  CONST FLASH_START* = 08000000H; FLASH_END* = 081FFFFFH; NB_SECTORS = 24;

  VAR buffer*: ARRAY 128*(1024 DIV 4) OF INTEGER;
    mapLoaded, mapUpdated: SET; buffer16kbMap: ARRAY NB_SECTORS OF SET;
    offset, bufOffset: ARRAY NB_SECTORS OF INTEGER;

  PROCEDURE SectorSize(idx: BYTE): INTEGER;
    VAR size: INTEGER;
  BEGIN ASSERT(idx < NB_SECTORS);
    IF idx >= NB_SECTORS DIV 2 THEN DEC(idx, NB_SECTORS DIV 2) END;
    IF idx < 4 THEN size := 16*1024
    ELSIF idx = 4 THEN size := 64*1024
    ELSE size := 128*1024
    END

    RETURN size
  END SectorSize;

  PROCEDURE SectorToSNB(idx: BYTE): BYTE;
  BEGIN ASSERT(idx < NB_SECTORS);
    IF idx >= NB_SECTORS DIV 2 THEN INC(idx, 4) END

    RETURN idx
  END SectorToSNB;

  PROCEDURE unlock;
  BEGIN SYSTEM.PUT(BSP.FLASH_BASE + BSP.KEYR, 45670123H);
    SYSTEM.PUT(BSP.FLASH_BASE + BSP.KEYR, 0CDEF89ABH)
  END unlock;

  PROCEDURE unlockOpt;
  BEGIN SYSTEM.PUT(BSP.FLASH_BASE + BSP.OPT_KEYR, 08192A3BH);
    SYSTEM.PUT(BSP.FLASH_BASE + BSP.KEYR, 4C5D6E7FH)
  END unlockOpt;

  PROCEDURE isLocked*(): BOOLEAN;
    VAR cr: SET;
  BEGIN SYSTEM.GET(BSP.FLASH_BASE + BSP.FLASH_CR, cr)

    RETURN BSP.LOCK IN cr
  END isLocked;

  PROCEDURE Open*;
    VAR cr: SET;
  BEGIN SYSTEM.GET(BSP.FLASH_BASE + BSP.FLASH_CR, cr);
    IF BSP.LOCK IN cr THEN unlock; cr := cr - {BSP.LOCK} + BSP.PSIZE_X32;
      SYSTEM.PUT(BSP.FLASH_BASE + BSP.FLASH_CR, cr);
    END
  END Open;

  PROCEDURE flush(is: BYTE);
  BEGIN (*TODO*)
    EXCL(mapUpdated, is)
  END flush;

  PROCEDURE flushAllSectors;
    VAR is: BYTE;
  BEGIN FOR is := 0 TO NB_SECTORS - 1 DO flush(is) END
  END flushAllSectors;

  PROCEDURE Close*;
    VAR cr: SET;
  BEGIN flushAllSectors; SYSTEM.GET(BSP.FLASH_BASE + BSP.FLASH_CR, cr); INCL(cr, BSP.LOCK);
    SYSTEM.PUT(BSP.FLASH_BASE + BSP.FLASH_CR, cr);
    ASSERT(isLocked()) 
  END Close;

  PROCEDURE GetSectorAt(adr: INTEGER): BYTE;
    VAR is: BYTE; 
  BEGIN ASSERT(adr >= FLASH_START); DEC(adr, FLASH_START); is := 0;
    WHILE adr >= offset[is] + SectorSize(is) DO INC(is) END

    RETURN is
  END GetSectorAt;

  PROCEDURE flushIfOverlap(isn: BYTE);
    VAR is: BYTE;
  BEGIN
    FOR is := 0 TO NB_SECTORS - 1 DO
      IF (is IN mapUpdated) & (buffer16kbMap[is]*buffer16kbMap[isn] # {}) THEN flush(is); EXCL(mapUpdated, is) END;
      EXCL(mapLoaded, is);
    END
  END flushIfOverlap;

  PROCEDURE load(is: BYTE);
    VAR a, begin, end, i: INTEGER;
  BEGIN ASSERT(is < NB_SECTORS);
    IF ~(is IN mapLoaded) THEN flushIfOverlap(is);
      begin := FLASH_START + offset[is]; end := begin + (SectorSize(is) DIV 4) - 1; i := bufOffset[is];
      FOR a := begin TO end BY 4 DO SYSTEM.GET(a, buffer[i]); INC(i) END;
      INCL(mapLoaded, is);
    END
  END load;

  PROCEDURE Write*(adr: INTEGER; data: ARRAY OF INTEGER; len: INTEGER);
    VAR is: BYTE; i: INTEGER;
  BEGIN is := GetSectorAt(adr); load(is); DEC(adr, FLASH_START + offset[is] - bufOffset[is]); 
    FOR i := 0 TO len - 1 DO
      IF buffer[adr + i] # data[i] THEN buffer[adr + i] := data[i]; INCL(mapUpdated, is) END
    END
  END Write;

  PROCEDURE init;
    VAR  is: BYTE; sb: INTEGER; 
  BEGIN sb := 0;
    FOR is := 0 TO NB_SECTORS - 1 DO offset[is] := sb; INC(sb, SectorSize(is)) END;
    FOR is := 0 TO 3 DO (*4 16kb sectors*) bufOffset[is] := is*16*1024; buffer16kbMap[is] := {is};
      bufOffset[is + NB_SECTORS DIV 2] := is*16*1024; buffer16kbMap[is + NB_SECTORS DIV 2] := {is}
    END;
    (*one 64kb sector*) bufOffset[4] := 64*1024; buffer16kbMap[4] := {4..7};
    bufOffset[4 + NB_SECTORS DIV 2] := 64*1024; buffer16kbMap[4 + NB_SECTORS DIV 2] := {4..7};
    FOR is := 5 TO NB_SECTORS DIV 2 - 1 DO (*7 128kb sectors*) bufOffset[is] := 0; buffer16kbMap[is] := {0..7};
      bufOffset[is + NB_SECTORS DIV 2] := 0; buffer16kbMap[is + NB_SECTORS DIV 2] := {0..7}
    END
  END init;

BEGIN init;
END FLASH.

OM4Tool.DecObj FLASH.m4c

Tests:
  System.Free FLASH ~
  FLASH.Open FLASH.Close
