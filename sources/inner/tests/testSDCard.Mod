MODULE testSDCard;
  IMPORT SYSTEM, BSP, SDCard, SDCard2, Texts, Oberon, System;

  VAR W: Texts.Writer;

  PROCEDURE showInfos*;
  BEGIN Texts.WriteString(W, "CardType "); Texts.WriteHex(W, SDCard2.hsd.SdCard.CardType); Texts.WriteLn(W);
    Texts.WriteString(W, "CardVersion "); Texts.WriteHex(W, SDCard2.hsd.SdCard.CardVersion); Texts.WriteLn(W);
    Texts.WriteString(W, "Class "); Texts.WriteHex(W, SDCard2.hsd.SdCard.Class); Texts.WriteLn(W);
    Texts.WriteString(W, "RelCardAddr "); Texts.WriteHex(W, SDCard2.hsd.SdCard.RelCardAdd); Texts.WriteLn(W);
    Texts.WriteString(W, "BlockNbr "); Texts.WriteHex(W, SDCard2.hsd.SdCard.BlockNbr); Texts.WriteLn(W);
    Texts.WriteString(W, "BlockSize "); Texts.WriteHex(W, SDCard2.hsd.SdCard.BlockSize); Texts.WriteLn(W);
    Texts.WriteString(W, "LogBlockNbr "); Texts.WriteHex(W, SDCard2.hsd.SdCard.LogBlockNbr); Texts.WriteLn(W);
    Texts.WriteString(W, "LogBlockSize "); Texts.WriteHex(W, SDCard2.hsd.SdCard.LogBlockSize); Texts.WriteLn(W);
    Texts.WriteString(W, "Errors: "); Texts.WriteInt(W, SDCard2.hsd.readErrors, 1); Texts.WriteString(W, ", ");
    Texts.WriteInt(W, SDCard2.hsd.writeErrors, 1); Texts.WriteString(W, ", ");
    Texts.WriteInt(W, SDCard2.hsd.unrecoverableErrors, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END showInfos;

  PROCEDURE test*;
    CONST SS = 1024; NBS = SS DIV 512;
    VAR a,b: ARRAY SS OF BYTE; src, r, i: INTEGER; same: BOOLEAN;
  BEGIN LED(0); System.Date;
    FOR src :=  8000H TO 8000H + NBS*1000 BY NBS DO
      IF src MOD (NBS*1000) = NBS*999 THEN Texts.Write(W,".");
        IF src MOD (NBS*40000) = NBS*39999 THEN Texts.WriteLn(W) END; Texts.Append(Oberon.Log, W.buf) 
      END;
      SDCard.Read(src, SYSTEM.ADR(a), NBS); (*read SD via Oberon stable driver*)
      SDCard2.Read(src, SYSTEM.ADR(b), NBS); (*read SD via Oberon new driver*)
      (*compare*) same := TRUE; i := 0; WHILE same & (i < SS DIV 4) DO same := a[i] = b[i]; INC(i) END;
      IF same THEN BSP.ledsOnOff({6}, {}) ELSE BSP.ledsOnOff({3}, {}) END
    END;
    System.Date;
  END test;

  PROCEDURE testWrite*;
    CONST SS = 1024; NBS = SS DIV 512; FS_OFFSET = 80000H;
    VAR a,b: ARRAY SS OF BYTE; src, r, i: INTEGER; same: BOOLEAN;
  BEGIN LED(0); System.Date;
    same := TRUE; src :=  FS_OFFSET;
    WHILE same & (src <= FS_OFFSET + NBS*1000) DO
      IF src MOD (NBS*1000) = NBS*999 THEN Texts.Write(W,".");
        IF src MOD (NBS*40000) = NBS*39999 THEN Texts.WriteLn(W) END; Texts.Append(Oberon.Log, W.buf) 
      END;
      SDCard.Read(src, SYSTEM.ADR(a), NBS); (*read SD via Oberon stable driver*)
      SDCard2.Write(src + 400000H, SYSTEM.ADR(a), NBS); (*write via Oberon new driver*)
      SDCard2.Read(src + 400000H, SYSTEM.ADR(b), NBS); (*read SD via Oberon new driver*)
      (*compare*) same := TRUE; i := 0; WHILE same & (i < SS DIV 4) DO same := a[i] = b[i]; INC(i) END;
      IF same THEN BSP.ledsOnOff({6}, {}) ELSE BSP.ledsOnOff({3}, {}) END;
      INC(src, NBS);
    END;
    System.Date;
  END testWrite;

  PROCEDURE perf*;
    CONST BS = 10240; NBS = BS DIV 512;
    VAR b: ARRAY BS OF BYTE; src, r, i: INTEGER; same: BOOLEAN;
  BEGIN LED(0); System.Date;
    FOR src := 5000000 TO 5000000 + NBS*10000 BY NBS DO
      IF src MOD (NBS*1000) = NBS*999 THEN Texts.Write(W,".");
        IF src MOD (NBS*40000) = NBS*39999 THEN Texts.WriteLn(W) END; Texts.Append(Oberon.Log, W.buf) 
      END;
      SDCard2.Read(src, SYSTEM.ADR(b), NBS) (*read SD via Oberon driver*)
    END;
    System.Date;
  END perf;

BEGIN SDCard2.Init; Texts.OpenWriter(W)
END testSDCard.
