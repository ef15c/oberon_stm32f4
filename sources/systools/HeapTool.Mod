MODULE HeapTool;
  IMPORT SYSTEM, Kernel, Files, Texts, Oberon;

  TYPE Block = RECORD n, size: INTEGER END;
    Blocks = RECORD len, total: INTEGER; blks: ARRAY 100 OF Block END;

  VAR W: Texts.Writer;

  PROCEDURE add(size: INTEGER; VAR bl: Blocks);
    VAR i, j: INTEGER;
  BEGIN i := 0;
    WHILE (i < bl.len) & (bl.blks[i].size < size) DO INC(i) END;
    IF i = bl.len THEN (*open new line*) INC(bl.len); bl.blks[i].size := size; bl.blks[i].n := 1
    ELSIF size = bl.blks[i].size THEN (*count block*) INC(bl.blks[i].n)
    ELSE (*make room*) FOR j := bl.len TO i+1 BY -1 DO bl.blks[j] := bl.blks[j-1] END; INC(bl.len); bl.blks[i].size := size; bl.blks[i].n := 1
    END
  END add;

  PROCEDURE buildBlockList(VAR b: Blocks);
    VAR list, size: INTEGER;
  BEGIN b.len := 0; b.total := 0;
    (*Scan list3 for 32 bytes blocks*) list := Kernel.list3;
    WHILE list # 0 DO add(32, b); SYSTEM.GET(list+8, list); INC(b.total, 32) END;

    (*Scan list2 for 64 bytes blocks*) list := Kernel.list2;
    WHILE list # 0 DO add(64, b); SYSTEM.GET(list+8, list); INC(b.total, 64) END;

    (*Scan list1 for 128 bytes blocks*) list := Kernel.list1;
    WHILE list # 0 DO add(128, b); SYSTEM.GET(list+8, list); INC(b.total, 128) END;

    (*Scan list0 for n*256 bytes blocks*) list := Kernel.list0;
    WHILE list # 0 DO SYSTEM.GET(list, size); add(size, b); SYSTEM.GET(list+8, list); INC(b.total, size) END;
  END buildBlockList;

  PROCEDURE ShowFree*;
    VAR B: Blocks; i: INTEGER;
  BEGIN Texts.WriteString(W, "Free blocks"); Texts.WriteLn(W);
    buildBlockList(B);
    Texts.WriteString(W,"       size: count"); Texts.WriteLn(W);
    FOR i := 0 TO B.len - 1 DO Texts.WriteInt(W, B.blks[i].size, 10); Texts.WriteString(W, ": ");
      Texts.WriteInt(W, B.blks[i].n, 1); Texts.WriteLn(W)
    END; Texts.WriteString(W, "Total: "); Texts.WriteInt(W, B.total, 1); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END ShowFree;

BEGIN Texts.OpenWriter(W)
END HeapTool.
