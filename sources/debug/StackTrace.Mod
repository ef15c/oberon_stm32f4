MODULE StackTrace;
  IMPORT Files, Modules, Texts, Oberon, System;

  VAR W: Texts.Writer;

  PROCEDURE addExt(VAR FName: ARRAY OF CHAR; ext: ARRAY OF CHAR);
    VAR i,j : INTEGER;
  BEGIN i := 0; WHILE FName[i] # 0X DO INC(i) END; j := 0; FName[i] := "."; INC(i);
    WHILE ext[j] # 0X DO FName[i] := ext[j]; INC(i); INC(j) END;
    FName[i] := 0X
  END addExt;

  PROCEDURE posModFromAdr(adr: INTEGER; VAR pos: INTEGER; VAR mod: Modules.Module);
    VAR base: INTEGER;
      F!: Files.File; Rf!: Files.Rider; name: ARRAY 32 OF CHAR;
      i, end: INTEGER;
      nb: BYTE;
  BEGIN pos := -1; base := 0; mod := Modules.root; (*Find the module owning the address*)
    WHILE (mod # NIL) & ((mod.name[0] = 0X) OR (adr < mod.code) OR (adr >= mod.imp)) DO mod := mod.next END;
    IF mod # NIL THEN base := mod.code; DEC(adr, base); name := mod.name; addExt(name, "osm"); F := Files.Old(name);
      IF F # NIL THEN Files.Set(Rf, F, 0); Files.ReadInt(Rf, end); i := 0;
        IF adr < end*2 THEN REPEAT Files.ReadByte(Rf, nb); Files.ReadInt(Rf, pos); INC(i, nb*2) UNTIL i > adr END
      ELSE Texts.WriteString(W, "Unable to open "); Texts.WriteString(W, name); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
      END
    END
  END posModFromAdr;

  PROCEDURE unwind(VAR pc, sp: INTEGER; mod: Modules.Module);
    VAR F!: Files.File; Rf!: Files.Rider; name: ARRAY 32 OF CHAR;
      rpc, nbs, end, ofs, rofs: INTEGER;
  BEGIN rpc := pc - mod.code; name := mod.name; addExt(name, "rao"); F := Files.Old(name);
      IF F # NIL THEN Files.Set(Rf, F, 0); Files.ReadInt(Rf, nbs);
        REPEAT Files.ReadInt(Rf, end); Files.ReadInt(Rf, ofs); DEC(nbs) UNTIL (end > rpc) OR (nbs = 0);
        IF end > rpc THEN rofs := ofs DIV 10000H; ofs := ofs MOD 10000H;
          IF (rofs = -1) & (sp = 0) THEN (*LR not yet pushed*) pc := System.stack.LR 
          ELSE IF sp >= System.stack.len THEN Texts.WriteString(W, "stack underflow"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf) END;
            pc := System.stack.stack[sp + rofs]; INC(sp, ofs)
          END; DEC(pc, ORD(ODD(pc)))
        END
      ELSE Texts.WriteString(W, "Unable to open "); Texts.WriteString(W, name); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
      END
  END unwind;

  PROCEDURE ShowDump*;
  BEGIN 
   Texts.WriteString(W, "cause: "); Texts.WriteInt(W, System.stack.cause, 1); Texts.WriteLn(W);
   Texts.WriteString(W, "cfsr: "); Texts.WriteHex(W, ORD(System.stack.cfsr)); Texts.WriteLn(W);
   Texts.WriteString(W, "bfar : "); Texts.WriteHex(W, System.stack.far); Texts.WriteLn(W);
   Texts.WriteString(W, "eos : "); Texts.WriteHex(W, System.stack.eos); Texts.WriteLn(W);
   Texts.WriteString(W, "PC : "); Texts.WriteHex(W, System.stack.PC); Texts.WriteLn(W);
   Texts.WriteString(W, "LR : "); Texts.WriteHex(W, System.stack.LR); Texts.WriteLn(W);
   Texts.WriteString(W, "stack size: "); Texts.WriteInt(W, System.stack.len, 1); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf)
  END ShowDump;

  PROCEDURE Calls*;
    VAR mod!: Modules.Module; pos, pc, sp, td: INTEGER;
  BEGIN pc :=  System.stack.PC; sp := 0; td := 10;
    IF pc # 0 THEN
(*      FOR pos := 0 TO 7 DO Texts.WriteHex(W, System.stack.stack[pos]) END;
      Texts.WriteLn(W);*)
      WHILE (pc # 0FFFFFFFEH) & (td > 0) DO mod := NIL;
        posModFromAdr(pc, pos, mod);
        IF mod # NIL THEN
          Texts.WriteString(W, "  pos "); Texts.WriteInt(W, pos, 5);
          Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name); Texts.WriteString(W, " at ");
          Texts.WriteHex(W, pc); Texts.WriteLn(W);
          Texts.Append(Oberon.Log, W.buf);
          unwind(pc, sp, mod); DEC(td)
        ELSE Texts.WriteString(W, "  unknown PC: "); Texts.WriteHex(W, pc); Texts.WriteLn(W);
          Texts.Append(Oberon.Log, W.buf); pc := 0FFFFFFFEH
        END
      END
    END
  END Calls;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "Stack trace utility CS 16.05.24"); Texts.WriteLn(W);
  Texts.Append(Oberon.Log, W.buf)
END StackTrace.

OM4Tool.DecObj StackTrace.m4c

