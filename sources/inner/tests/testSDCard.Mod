MODULE testSDCard;
  IMPORT SYSTEM, BSP, SDCard, Texts, Oberon, System;

  VAR W: Texts.Writer;

  PROCEDURE showInfos*;
  BEGIN Texts.WriteString(W, "CardType "); Texts.WriteHex(W, SDCard.hsd.SdCard.CardType); Texts.WriteLn(W);
    Texts.WriteString(W, "CardVersion "); Texts.WriteHex(W, SDCard.hsd.SdCard.CardVersion); Texts.WriteLn(W);
    Texts.WriteString(W, "Class "); Texts.WriteHex(W, SDCard.hsd.SdCard.Class); Texts.WriteLn(W);
    Texts.WriteString(W, "RelCardAddr "); Texts.WriteHex(W, SDCard.hsd.SdCard.RelCardAdd); Texts.WriteLn(W);
    Texts.WriteString(W, "BlockNbr "); Texts.WriteHex(W, SDCard.hsd.SdCard.BlockNbr); Texts.WriteLn(W);
    Texts.WriteString(W, "BlockSize "); Texts.WriteHex(W, SDCard.hsd.SdCard.BlockSize); Texts.WriteLn(W);
    Texts.WriteString(W, "LogBlockNbr "); Texts.WriteHex(W, SDCard.hsd.SdCard.LogBlockNbr); Texts.WriteLn(W);
    Texts.WriteString(W, "LogBlockSize "); Texts.WriteHex(W, SDCard.hsd.SdCard.LogBlockSize); Texts.WriteLn(W);

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
      SYSTEM.LDREG(0, src); SYSTEM.LDREG(1, SYSTEM.ADR(a)); SYSTEM.LDREG(2, NBS); r := SYSTEM.SVC(2); (*read SD via C firmware*)
      SDCard.Read(src, SYSTEM.ADR(b), NBS); (*read SD via Oberon driver*)
      (*compare*) same := TRUE; i := 0; WHILE same & (i < SS DIV 4) DO same := a[i] = b[i]; INC(i) END;
      IF same THEN BSP.ledsOnOff({2}, {}) ELSE BSP.ledsOnOff({1}, {}) END
    END;
    System.Date;
  END test;

  PROCEDURE perf*;
    CONST BS = 10240; NBS = BS DIV 512;
    VAR b: ARRAY BS OF BYTE; src, r, i: INTEGER; same: BOOLEAN;
  BEGIN LED(0); System.Date;
    FOR src := 5000000 TO 5000000 + NBS*10000 BY NBS DO
      IF src MOD (NBS*1000) = NBS*999 THEN Texts.Write(W,".");
        IF src MOD (NBS*40000) = NBS*39999 THEN Texts.WriteLn(W) END; Texts.Append(Oberon.Log, W.buf) 
      END;
      SDCard.Read(src, SYSTEM.ADR(b), NBS) (*read SD via Oberon driver*)
    END;
    System.Date;
  END perf;

BEGIN Texts.OpenWriter(W)
END testSDCard.
