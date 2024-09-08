MODULE CRC32;
  IMPORT SYSTEM, BSP;

  PROCEDURE reset*;
  BEGIN SYSTEM.PUT(BSP.crcReset, 1); (*Reset STM32 CRC Unit*)
  END reset;

  PROCEDURE write*(data: INTEGER);
  BEGIN SYSTEM.PUT(BSP.CRC_BASE + BSP.CRC_DR, data)
  END write;

  PROCEDURE read*(): INTEGER;
    VAR result: INTEGER;
  BEGIN SYSTEM.GET(BSP.CRC_BASE + BSP.CRC_DR, result)
    RETURN result
  END read;

BEGIN BSP.InitCRC (*Activate STM32 CRC Unit*)
END CRC32.
