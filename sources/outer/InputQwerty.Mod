MODULE Input; (*NW 5.10.86 / 15.11.90 Ceres-2; PDR 21.4.12 / NW 15.5.2013 Ceres-4*)
(* C. Schoffit: adapted to french keyboard layout *)
  IMPORT SYSTEM, Kernel, PS2;
    
  VAR kbdCode: BYTE; (*last keyboard code read*)
    Recd, Up, Shift, Ctrl, Ext, AltGr, CapsLock, Extended: BOOLEAN;
    KTabAdr, KTabAdrAlt, KTabAdrExt: INTEGER;  (*keyboard code translation tables*)
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
  VAR tmp: INTEGER;
  BEGIN
    WHILE ~Recd DO Peek() END;
    IF AltGr THEN SYSTEM.GET(KTabAdrAlt + kbdCode, ch)
    ELSIF Extended THEN SYSTEM.GET(KTabAdrExt + kbdCode, ch)
    ELSE
      IF Shift OR Ctrl THEN INC(kbdCode, 80H) END; (*ctrl implies shift*)
    (* ch := kbdTab[kbdCode]; *)
      SYSTEM.GET(KTabAdr + kbdCode, ch);
      IF Ctrl THEN ch := CHR(ORD(ch) MOD 20H) 
      ELSIF CapsLock THEN
        IF (ch >= "a") & (ch <= "z") THEN ch := CHR(ORD(ch)-ORD("a")+ORD("A"))
        ELSIF (ch >= "A") & (ch <= "Z") THEN ch := CHR(ORD(ch)-ORD("A")+ORD("a"))
        END
      END
    END;
    Recd := FALSE
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
    AltGr := FALSE; CapsLock := FALSE;
    mkb := PS2.mkb;
    KTabAdr := SYSTEM.ADR(
    (* US key map*) $
      00 00 00 00 00 1A 00 00  00 00 00 00 00 09 60 00
      00 00 00 00 00 71 31 00  00 00 7A 73 61 77 32 00
      00 63 78 64 65 34 33 00  00 20 76 66 74 72 35 00
      00 6E 62 68 67 79 36 00  00 00 6D 6A 75 37 38 00
      00 2C 6B 69 6F 30 39 00  00 2E 2F 6C 3B 70 2D 00
      00 00 27 00 5B 3D 00 00  00 00 0D 5D 00 5C 00 00
      00 00 00 00 00 00 08 00  00 00 00 00 00 00 00 00
      00 7F 00 00 00 00 1B 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 00 00 00 09 7E 00
      00 00 00 00 00 51 21 00  00 00 5A 53 41 57 40 00
      00 43 58 44 45 24 23 00  00 20 56 46 54 52 25 00
      00 4E 42 48 47 59 5E 00  00 00 4D 4A 55 26 2A 00
      00 3C 4B 49 4F 29 28 00  00 3E 3F 4C 3A 50 5F 00
      00 00 22 00 7B 2B 00 00  00 00 0D 7D 00 7C 00 00
      00 00 00 00 00 00 08 00  00 00 00 00 00 00 00 00
      00 7F 00 00 00 00 1B 00  00 00 00 00 00 00 00 00$);
    (* French key map
       q -> a  w -> z  a -> q  z -> w  ] -> $
              
       ; -> m  ' -> �  \ -> *
       
       m -> ,  , -> ;  . -> :  / -> !
        
       1 -> &  2 -> �  3 -> "  4 -> '  5 -> (
       6 -> -  7 -> �  8 -> _  9 -> �  0 -> �
       - -> )
       
       ! -> 1  @ -> 2  # -> 3  $ -> 4  % -> 5
       ^ -> 6  & -> 7  * -> 8  ( -> 9  ) -> 0
       - -> �

       Q -> A  A -> Q  } -> �
       : -> M  " -> %
        
       M -> ?  < -> .  > -> /  ? -> �
      $
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
      00 7F 00 00 00 00 1B 00  00 00 00 00 00 00 00 00$);*)
      
  (*
    AltGr controlled keys
    
    AltGr+� -> ~  AltGr+" -> #  AltGr+' -> {  AltGr+( -> [  
    AltGr+- -> |  AltGr+� -> `  AltGr+_ -> \  AltGr+� -> ^  
    AltGr+� -> @  AltGr+) -> ]  AltGr+= -> }
    
    AltGr+e -> �
  *)
    KTabAdrAlt := SYSTEM.ADR($
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00  00 00 00 00 00 00 7E 00
      00 00 00 00 A4 7B 23 00  00 00 00 00 00 00 5B 00
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
      00 7F 90 00 8D 8F 00 00  00 00 00 00 00 00 00 00$)

  END Init;

BEGIN Init
END Input.
