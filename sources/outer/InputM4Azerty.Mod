MODULE Input; (*NW 5.10.86 / 15.11.90 Ceres-2; PDR 21.4.12 / NW 15.5.2013 Ceres-4*)
(* C. Schoffit: adapted to french keyboard layout *)
  IMPORT SYSTEM, Kernel, PS2;
    
  VAR kbdCode: BYTE; (*last keyboard code read*)
    Recd, Up, Shift, Ctrl, Ext, AltGr, CapsLock, Extended, Circumflex, Dieresis: BOOLEAN;
    KTabAdr, KTabAdrAlt, KTabAdrExt, KTabAdrCircumflex, KTabAdrDieresis: INTEGER;  (*keyboard code translation tables*)
    mkb: PS2.MKB; (*mouse and keyboard data block*)

(*FIFO implemented in interrupt handler, because every read must be handled,
  including tracking the state of the Shift and Ctrl keys*)

  PROCEDURE Peek();
  BEGIN
    IF mkb.KB.tail # mkb.KB.head THEN
      kbdCode := mkb.KB.buffer[mkb.KB.tail]; mkb.KB.tail := (mkb.KB.tail + 1) MOD PS2.BUFFERSIZE;
      IF kbdCode = 0F0H THEN Up := TRUE
      ELSIF kbdCode = 0E0H THEN Ext := TRUE
      ELSE
        IF Ext & (kbdCode = 11H) THEN AltGr := ~Up
        ELSIF (kbdCode = 12H) OR (kbdCode = 59H) THEN (*shift*) Shift := ~Up
        ELSIF kbdCode = 14H THEN (*ctrl*) Ctrl := ~Up
        ELSIF (kbdCode = 54H) & ~Up THEN (*circumflex or dieresis*) IF Shift THEN Dieresis := TRUE ELSE Circumflex := TRUE END
        ELSIF (kbdCode = 58H) & ~Up THEN (*capslock*)
          CapsLock := ~CapsLock; PS2.SetCapsLock(CapsLock)
        ELSIF ~Up THEN Extended := Ext; Recd := TRUE (*real key going down*)
        END ;
        Up := FALSE; Ext := FALSE
      END
    END;
  END Peek;

  PROCEDURE Available*(): INTEGER;
  BEGIN Peek();
    RETURN ORD(Recd)
  END Available;

  PROCEDURE Read*(VAR ch: CHAR);
  VAR tmp, tab: INTEGER;
  BEGIN
    IF Circumflex THEN tab := KTabAdrCircumflex ELSIF Dieresis THEN tab := KTabAdrDieresis ELSE tab := KTabAdr END;
    WHILE ~Recd DO Peek() END;
    IF AltGr THEN SYSTEM.GET(KTabAdrAlt + kbdCode, ch)
    ELSIF Extended THEN SYSTEM.GET(KTabAdrExt + kbdCode, ch)
    ELSE
      IF Shift OR Ctrl THEN INC(kbdCode, 80H) END; (*ctrl implies shift*)
      SYSTEM.GET(tab + kbdCode, ch);
      IF Ctrl THEN ch := CHR(ORD(ch) MOD 20H) 
      ELSIF CapsLock THEN
        IF (ch >= "a") & (ch <= "z") THEN ch := CHR(ORD(ch)-ORD("a")+ORD("A"))
        ELSIF (ch >= "A") & (ch <= "Z") THEN ch := CHR(ORD(ch)-ORD("A")+ORD("a"))
        END
      END
    END;
    Circumflex := FALSE; Dieresis := FALSE; Recd := FALSE
  END Read;

  PROCEDURE Mouse*(VAR keys: SET; VAR x, y: INTEGER);
  BEGIN keys := SYSTEM.VAL(SET, mkb.MD DIV 1000000H MOD 8);
    x := mkb.MD MOD 1000H; y := (mkb.MD DIV 1000H) MOD 1000H;
  END Mouse;

  PROCEDURE SetMouseLimits*(w, h: INTEGER);
  BEGIN mkb.MW := w; mkb.MH := h
  END SetMouseLimits;

  PROCEDURE Init*;
  BEGIN Up := FALSE; Shift := FALSE; Ctrl := FALSE; Recd := FALSE;
    AltGr := FALSE; CapsLock := FALSE; Circumflex := FALSE; Dieresis := FALSE;
    mkb := PS2.mkb;
    KTabAdr := SYSTEM.ADR(
    (* French key map
       q -> a  w -> z  a -> q  z -> w  ] -> $
              
       ; -> m  ' -> ù  \ -> *
       
       m -> ,  , -> ;  . -> :  / -> !
        
       1 -> &  2 -> é  3 -> "  4 -> '  5 -> (
       6 -> -  7 -> è  8 -> _  9 -> ç  0 -> à
       - -> )
       
       ! -> 1  @ -> 2  # -> 3  $ -> 4  % -> 5
       ^ -> 6  & -> 7  * -> 8  ( -> 9  ) -> 0
       - -> °

       Q -> A  A -> Q  } -> £
       : -> M  " -> %
        
       M -> ?  < -> .  > -> /  ? -> §
       *)$
      00 00 00 00 00 1A 00 00  00 00 00 00 00 09 B2 00
      00 00 00 00 00 61 26 00  00 00 77 73 71 7A E9 00
      00 63 78 64 65 27 22 00  00 20 76 66 74 72 28 00
      00 6E 62 68 67 79 2D 00  00 00 2C 6A 75 E8 5F 00
      00 3B 6B 69 6F E0 E7 00  00 3A 21 6C 6D 70 29 00
      00 00 F9 00 5B 3D 00 00  00 00 0D 24 00 2A 00 00
      00 3C 00 00 00 00 08 00  00 31 00 34 37 00 00 00
      30 2E 32 35 36 38 1B 00  00 2B 33 2D 2A 39 00 00

      00 00 00 00 00 00 00 00  00 00 00 00 00 09 7E 00
      00 00 00 00 00 41 31 00  00 00 57 53 51 5A 32 00
      00 43 58 44 45 34 33 00  00 20 56 46 54 52 35 00
      00 4E 42 48 47 59 36 00  00 00 3F 4A 55 37 38 00
      00 2E 4B 49 4F 30 39 00  00 2F A7 4C 4D 50 B0 00
      00 00 25 00 7B 2B 00 00  00 00 0D A3 00 B5 00 00
      00 3E 00 00 00 00 08 00  00 00 00 00 00 00 00 00
      00 7F 00 00 00 00 1B 00  00 00 00 00 00 00 00 00$);
      
  (*
    AltGr controlled keys
    
    AltGr+é -> ~  AltGr+" -> #  AltGr+' -> {  AltGr+( -> [  
    AltGr+- -> |  AltGr+è -> `  AltGr+_ -> \  AltGr+ç -> ^  
    AltGr+à -> @  AltGr+) -> ]  AltGr+= -> }
    
    AltGr+e -> €
  *)
    KTabAdrAlt := SYSTEM.ADR($
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 7E 00
      00 00 00 00 80 7B 23 00  00 00 00 00 00 00 5B 00
      00 00 00 00 00 00 7C 00  00 00 00 00 00 60 5C 00
      00 00 00 00 00 40 5E 00  00 00 00 00 00 00 5D 00
      00 00 00 00 00 7D 00 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00$);

    KTabAdrExt := SYSTEM.ADR($
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 2F 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 0D 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 31 00 81 34 37 00 00
      00 7F 00 00 8D 00 00 00  00 00 00 00 00 00 00 00$);

    KTabAdrCircumflex := SYSTEM.ADR(
    (* French key map
      a -> â  A -> Â  e -> ê  E -> Ê  i -> î  I -> Ï  o -> ô  O -> Ô
      u -> û  U -> Û
      *)$
      00 00 00 00 00 1A 00 00  00 00 00 00 00 09 B2 00
      00 00 00 00 00 E2 26 00  00 00 77 73 71 7A E9 00
      00 63 78 64 EA 27 22 00  00 20 76 66 74 72 28 00
      00 6E 62 68 67 79 2D 00  00 00 2C 6A FB E8 5F 00
      00 3B 6B EE F4 E0 E7 00  00 3A 21 6C 6D 70 29 00
      00 00 F9 00 5B 3D 00 00  00 00 0D 24 00 2A 00 00
      00 3C 00 00 00 00 08 00  00 31 00 34 37 00 00 00
      30 2E 32 35 36 38 1B 00  00 2B 33 2D 2A 39 00 00

      00 00 00 00 00 00 00 00  00 00 00 00 00 09 7E 00
      00 00 00 00 00 C2 31 00  00 00 57 53 51 5A 32 00
      00 43 58 44 CA 34 33 00  00 20 56 46 54 52 35 00
      00 4E 42 48 47 59 36 00  00 00 3F 4A DB 37 38 00
      00 2E 4B CE D4 30 39 00  00 2F A7 4C 4D 50 B0 00
      00 00 25 00 7B 2B 00 00  00 00 0D A3 00 B5 00 00
      00 3E 00 00 00 00 08 00  00 00 00 00 00 00 00 00
      00 7F 00 00 00 00 1B 00  00 00 00 00 00 00 00 00$);

    KTabAdrDieresis := SYSTEM.ADR(
    (* French key map
      a -> ä  A -> Ä  e -> ë  E -> Ë  i -> ï  I -> Ï  o -> ö  O -> Ö
      u -> ü  U -> Ü y -> ÿ  Y -> Ÿ
      *)$
      00 00 00 00 00 1A 00 00  00 00 00 00 00 09 B2 00
      00 00 00 00 00 E4 26 00  00 00 77 73 71 7A E9 00
      00 63 78 64 EB 27 22 00  00 20 76 66 74 72 28 00
      00 6E 62 68 67 FF 2D 00  00 00 2C 6A FC E8 5F 00
      00 3B 6B EF F6 E0 E7 00  00 3A 21 6C 6D 70 29 00
      00 00 F9 00 5B 3D 00 00  00 00 0D 24 00 2A 00 00
      00 3C 00 00 00 00 08 00  00 31 00 34 37 00 00 00
      30 2E 32 35 36 38 1B 00  00 2B 33 2D 2A 39 00 00

      00 00 00 00 00 00 00 00  00 00 00 00 00 09 7E 00
      00 00 00 00 00 C4 31 00  00 00 57 53 51 5A 32 00
      00 43 58 44 CB 34 33 00  00 20 56 46 54 52 35 00
      00 4E 42 48 47 9F 36 00  00 00 3F 4A DC 37 38 00
      00 2E 4B CF D6 30 39 00  00 2F A7 4C 4D 50 B0 00
      00 00 25 00 7B 2B 00 00  00 00 0D A3 00 B5 00 00
      00 3E 00 00 00 00 08 00  00 00 00 00 00 00 00 00
      00 7F 00 00 00 00 1B 00  00 00 00 00 00 00 00 00$);

  END Init;

BEGIN Init
END Input.
